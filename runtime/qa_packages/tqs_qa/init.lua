-- SPDX-License-Identifier: GPL-3.0-or-later
-- Server-only deterministic scenario director for TQS QA.

local config = ServerConfig and ServerConfig.tqsQa
if not config or config.enabled ~= true then
  return nil
end

-- Optional QA-only downstream replay.  The default is disabled, and every
-- enabled skill has an explicit state profile.  Profiles with nested player
-- requests must declare exact per-command deltas; a SkillEffect observation
-- alone is never enough to enter the clean gate. Never enable an arbitrary
-- skill here from a production configuration; an undeclared request could
-- block the deterministic probe or consume unrelated match state.
local prompt4EffectReplaySkill = type(config.prompt4EffectReplaySkill) == "string" and
  config.prompt4EffectReplaySkill or nil
local prompt4EffectReplayProfiles = {
  hs__kurou = {
    reason = "active discard, one HP loss and bounded draw; no nested QA request",
    expectedHpDelta = -1,
    expectedHandDelta = 2,
  },
  hs__zhiheng = {
    reason = "active discard/draw exchange; no nested QA request",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    promoteFakeSkill = true,
  },
  hs__qiangxi = {
    reason = "active weapon-or-HP cost plus direct damage; no nested QA request",
    expectedHpDeltas = { [-1] = true, [0] = true },
    expectedTargetHpDelta = -1,
    expectedTargetCount = 1,
  },
  cunsi = {
    reason = "active target grant and draw; no nested QA request",
    expectedHpDelta = 0,
    expectedTargetHandDelta = 2,
    expectedTargetSkill = "yongjue",
    expectedTargetCount = 1,
  },
  dimeng = {
    reason = "active discard and hand swap; no nested QA request",
    expectedHpDelta = 0,
    expectedTargetHandTotalDelta = 0,
    expectedTargetCount = 2,
  },
  duanfa = {
    reason = "active black-card discard/draw exchange; no nested QA request",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    minimumMark = { name = "duanfa-phase", value = 1 },
  },
  jijiu = {
    reason = "view-as Peach direct recovery; execute returned useResult without nested QA request",
    expectedHpDelta = 0,
    expectedTargetHpDelta = 1,
    expectedTargetCount = 1,
    targetFromExtraData = true,
    executeUseResult = true,
  },
  hs__wusheng = {
    reason = "view-as Slash; QA drives the nested Jink request through a native BOT target",
    expectedHpDelta = 0,
    expectedHandDelta = -1,
    -- The native BOT answers the generated Slash with Jink in this fixed
    -- semantic fixture: the target spends one card and takes no damage.
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    expectedReplayCardCount = 1,
    targetPolicy = "native_bot",
    executeUseResult = true,
  },
  hs__longdan = {
    reason = "view-as Slash from Jink reaches the native direct-damage path",
    expectedHpDelta = 0,
    expectedHandDelta = -1,
    expectedTargetHpDelta = -1,
    expectedTargetHandDelta = 0,
    expectedTargetHandTotalDelta = 0,
    expectedTargetCount = 1,
    promoteFakeSkill = true,
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
    executeUseResult = true,
  },
  hs__luanji = {
    reason = "view-as Archery Attack from two distinct suits with native Jink response",
    expectedHpDelta = 0,
    -- The two browser-seat resources are remapped to the native actor only
    -- in the QA execution copy. Keep the downstream gate on the real
    -- Archery Attack effect and native Jink response; the engine's virtual
    -- card hand counter is not a stable portability contract for this copy.
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    promoteFakeSkill = true,
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
    executeUseResult = true,
    -- Luanji's material law is two hand cards of distinct suits; the
    -- browser reply may choose any legal pair from the seven-card fixture.
    -- Match that law-level predicate when remapping to the native actor.
    resourceMatchMode = "distinct_suits",
    nestedMetrics = {
      { command = "AskForResponseCard", total = 1, fallback = 0, invalid = 0 },
    },
  },
  huoji = {
    reason = "view-as Fire Attack with same-suit discard and native target reveal",
    expectedHpDelta = 0,
    expectedHandDelta = -2,
    expectedTargetHpDelta = -1,
    expectedTargetHandDelta = 0,
    expectedTargetHandTotalDelta = 0,
    expectedTargetCount = 1,
    promoteFakeSkill = true,
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
    executeUseResult = true,
    -- Huoji's ViewAs filter constrains the source to a red non-equipment
    -- card; it does not constrain the source trueName.  The browser-seat
    -- reply may therefore choose Slash while the native replay actor owns
    -- Peach of the same suit (or vice versa).  Remap by the actual ViewAs
    -- law instead of imposing an unrelated trueName equality.
    resourceMatchMode = "huoji_red",
    nestedMetrics = {
      { command = "AskForUseActiveSkill", total = 2, fallback = 0, invalid = 0 },
    },
  },
  kanpo = {
    reason = "contextual black-card Nullification response against a harmful public effect",
    expectedHpDelta = 0,
    expectedHandDelta = -1,
    expectedTargetCount = 0,
    expectedReplayCardCount = 1,
    promoteFakeSkill = true,
    executeUseResult = true,
  },
  beizhu = {
    reason = "active hostile hand inspection followed by native visible-card discard",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    promoteFakeSkill = true,
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
    nestedMetrics = {
      { command = "AskForCardChosen", total = 1, fallback = 0, invalid = 0 },
      { command = "AskForSkillInvoke", total = 1, fallback = 1, invalid = 0 },
    },
  },
  tianyi = {
    reason = "active pindian and bounded turn mark through native nested card requests",
    expectedHpDelta = 0,
    expectedHandDelta = -1,
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    -- The replay uses one native BOT as the pindian actor and a separate BOT
    -- as the target.  Either result is legal for the downstream proof; the
    -- source skill must set exactly one of these turn marks.
    markAny = { "tianyi_win-turn", "tianyi_lose-turn" },
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
  },
  tiaoxin = {
    reason = "active provocation followed by native Slash and Jink response",
    expectedHpDelta = 0,
    expectedHandDelta = -1,
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    -- The target BOT spends a real Slash and the replay actor answers with
    -- the reserved Jink.  This keeps the branch away from tiaoxin's
    -- AskForCardChosen fallback and proves both nested card paths are native.
    -- FreeKill routes both the forced Slash and the Slash-offset Jink through
    -- AskForUseCard; retain an explicit zero AskForResponseCard expectation
    -- so a future command split cannot silently change this proof.
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_tiaoxin",
    nestedMetrics = {
      { command = "AskForUseCard", total = 2, fallback = 0, invalid = 0 },
      { command = "AskForResponseCard", total = 0, fallback = 0, invalid = 0 },
    },
  },
  choufa = {
    reason = "active friendly target followed by native visible-card choice",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = 0,
    expectedTargetHandTotalDelta = 0,
    expectedTargetCount = 1,
    -- Choufa's onUse asks the real actor to choose one visible card from the
    -- target hand, then applies temporary card marks.  The target is a
    -- distinct native BOT so the AskForCardChosen request is not aliased with
    -- the replay actor's own hand.
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
    nestedMetrics = {
      { command = "AskForCardChosen", total = 1, fallback = 0, invalid = 0 },
    },
  },
  aocai = {
    reason = "response ViewAs basic card from the two-card draw-pile offer",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    expectedTargetCount = 0,
    expectedReplayCardCount = 1,
    promoteFakeSkill = true,
    -- AskForResponseCard must execute the returned card through the native
    -- RespondCard event, not through an ordinary UseCard event.  The source
    -- card remains a real draw-pile card selected by the live ViewAs handler.
    executeResponseResult = true,
  },
  shangyi = {
    reason = "active target view followed by a choice and visible-card discard",
    expectedHpDelta = 0,
    expectedHandDelta = 0,
    expectedTargetHpDelta = 0,
    expectedTargetHandDelta = -1,
    expectedTargetHandTotalDelta = -1,
    expectedTargetCount = 1,
    -- The accepted active reply is captured from the browser-seat AI, but the
    -- downstream skill opens AskForChoices and AskForCardsAndChoice.  Use an
    -- isolated native BOT only as the replay actor so both nested requests
    -- are answered through the real Request/SmartAI path without waiting for
    -- a browser client.  The target is a separate native BOT so every nested
    -- request remains deterministic and does not make the actor target itself.
    actorPolicy = "native_bot",
    targetPolicy = "native_bot_other",
  },
}
-- ViewAs skills that can open a second response/choice request (for example
-- Slash/Jink or Fire Attack) stay out of this table unless the profile declares
-- an explicit nested-request policy. A server-side SkillEffect observation
-- alone is not enough to call such a replay a clean PASS.
local prompt4EffectReplayProfile = prompt4EffectReplaySkill and
  prompt4EffectReplayProfiles[prompt4EffectReplaySkill] or nil

-- The verified package carries the general-pair module. The QA launcher
-- exposes it through a symlink at the native require path; the symlink is
-- ignored by the public flist walk, so the browser/native identity stays
-- paired with the public gateway.

local function fail(message)
  error("[tqs_qa] " .. message)
end

local function readJson(path)
  local file, err = io.open(path, "r")
  if not file then
    fail("cannot read " .. path .. ": " .. tostring(err))
  end
  local raw = file:read("*a")
  file:close()
  local ok, value = pcall(json.decode, raw)
  if not ok or type(value) ~= "table" then
    fail("invalid JSON: " .. path)
  end
  return value
end

local manifest = readJson("qa_packages/tqs_qa/package.manifest.json")
if manifest.schemaVersion ~= 1 or manifest.package ~= "tqs_qa" or
    manifest.status ~= "verified" or type(manifest.sourceRevision) ~= "string" or
    manifest.sourceRevision == "" or manifest.sourceRevision == "UNRELEASED" or
    type(manifest.catalogSha256) ~= "string" or manifest.catalogSha256 == "" or
    type(manifest.packageSha256) ~= "string" or manifest.packageSha256 == "" then
  fail("refusing to load an unverified package manifest")
end

local catalog = readJson("qa_packages/tqs_qa/catalog.json")
if catalog.schemaVersion ~= 1 or catalog.package ~= "tqs_qa" or
    type(catalog.scenarios) ~= "table" or #catalog.scenarios == 0 then
  fail("invalid scenario catalog")
end

local scenarioById = {}

local function cloneList(values)
  local copy = {}
  for index, value in ipairs(values or {}) do copy[index] = value end
  return copy
end

local function cloneScenario(scenario)
  local copy = {}
  for key, value in pairs(scenario) do copy[key] = value end
  return copy
end

-- Prompt 4 uses one scenario id with a small, explicit seed/roster matrix.
-- Keeping the matrix behind the existing ai-trace room contract means the
-- browser runner and paired parser still have one stable protocol, while the
-- native director refuses arbitrary seed/roster combinations.
local function resolveAiTraceScenario(scenario, seed)
  if scenario.trigger ~= "ai-trace" or type(scenario.seedVariants) ~= "table" then
    return nil
  end
  local range = scenario.seedRange
  if type(range) ~= "table" or type(range.min) ~= "number" or type(range.max) ~= "number" or
      seed < range.min or seed > range.max then
    return nil
  end
  for _, variant in ipairs(scenario.seedVariants) do
    if variant.seed == seed then
      local resolved = cloneScenario(scenario)
      resolved.seatRosters = variant.seatRosters
      resolved.fixedHands = variant.fixedHands
      return resolved
    end
  end
  return nil
end

-- The win-rate matrix keeps its public roster definitions in catalog.json but
-- uses the four existing mixed-match scenario ids as seat-swap templates. A
-- seed in the declared range selects one roster set; the scenario's A/B/C/D
-- permutation then maps kingdom groups onto seats. This makes baseline and
-- candidate runs pairable by (scenario, seed) without copying 16 large offer
-- arrays into the catalog or allowing an arbitrary room to select a roster.
local generalPairMatrix = catalog.generalPairMatrix
local function matrixGeneralCount()
  local count = type(generalPairMatrix) == "table" and generalPairMatrix.initialGeneralCount or nil
  if type(count) ~= "number" or count % 1 ~= 0 or count < 5 or count > 10 then
    fail("general-pair matrix initialGeneralCount must be an integer from five through ten")
  end
  return count
end

local function resolveGeneralPairScenario(scenario, seed)
  local aiTraceResolved = resolveAiTraceScenario(scenario, seed)
  if aiTraceResolved then return aiTraceResolved end
  if type(scenario.matrixFamily) ~= "string" then
    return seed == scenario.seed and scenario or nil
  end
  if type(generalPairMatrix) ~= "table" or generalPairMatrix.schemaVersion ~= 1 or
      type(generalPairMatrix.rosterSets) ~= "table" or
      type(generalPairMatrix.seatPermutations) ~= "table" then
    fail("general-pair matrix metadata is missing or invalid")
  end
  local range = scenario.seedRange
  if type(range) ~= "table" or type(range.min) ~= "number" or type(range.max) ~= "number" or
      seed < range.min or seed > range.max then
    if seed == scenario.seed then
      local fixed = cloneScenario(scenario)
      fixed.matrixRosterSet = "fixed"
      fixed.matrixSeatPermutation = scenario.matrixSeatPermutation or "fixed"
      return fixed
    end
    return nil
  end
  local rosterNames = scenario.matrixRosterSets
  local permutation = generalPairMatrix.seatPermutations[scenario.matrixSeatPermutation]
  if type(rosterNames) ~= "table" or #rosterNames == 0 or
      type(permutation) ~= "table" or #permutation ~= 4 then
    fail("general-pair matrix scenario has invalid roster/permutation metadata")
  end
  local ordinal = ((seed - range.min) % #rosterNames) + 1
  local rosterName = rosterNames[ordinal]
  local rosterSet = generalPairMatrix.rosterSets[rosterName]
  local expectedCount = matrixGeneralCount()
  if type(rosterSet) ~= "table" or type(rosterSet.offeredGroups) ~= "table" or
      #rosterSet.offeredGroups ~= 4 then
    fail("general-pair matrix roster set is missing four offered groups: " .. tostring(rosterName))
  end
  local resolved = cloneScenario(scenario)
  resolved.offeredGroups = {}
  for seat, sourceSeat in ipairs(permutation) do
    if type(sourceSeat) ~= "number" or type(rosterSet.offeredGroups[sourceSeat]) ~= "table" then
      fail("general-pair matrix permutation points outside roster set " .. tostring(rosterName))
    end
    if #rosterSet.offeredGroups[sourceSeat] ~= expectedCount then
      fail("general-pair matrix roster set " .. tostring(rosterName) .. " source seat " ..
        tostring(sourceSeat) .. " must offer exactly " .. tostring(expectedCount) .. " generals")
    end
    resolved.offeredGroups[seat] = cloneList(rosterSet.offeredGroups[sourceSeat])
  end
  resolved.enabledKingdoms = cloneList(rosterSet.enabledKingdoms or scenario.enabledKingdoms)
  resolved.matrixRosterSet = tostring(rosterName)
  resolved.matrixSeatPermutation = tostring(scenario.matrixSeatPermutation)
  return resolved
end

local function validateDamageExchangeScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("damage-exchange scenarios must define exactly two players")
  end
  for _, role in ipairs({ "actor", "target" }) do
    local player = scenario.players[role]
    if type(player) ~= "table" or type(player.general) ~= "string" or
        type(player.deputy) ~= "string" or type(player.kingdom) ~= "string" then
      fail("damage-exchange scenario has an invalid " .. role .. " roster entry")
    end
  end
  if type(scenario.attackSteps) ~= "table" or #scenario.attackSteps ~= 4 then
    fail("damage-exchange scenario must define four Slash steps")
  end
  for index, step in ipairs(scenario.attackSteps) do
    if type(step.from) ~= "string" or type(step.to) ~= "string" or
        type(step.amount) ~= "number" or step.amount ~= (index == 1 and 0 or 1) or
        type(step.mandatorySkills) ~= "table" or type(step.optionalSkills) ~= "table" or
        type(step.expectedEffect) ~= "string" then
      fail("damage-exchange scenario has an invalid Slash step " .. tostring(index))
    end
    if step.from ~= (index <= 3 and "actor" or "target") or
      step.to ~= (index <= 3 and "target" or "actor") then
      fail("damage-exchange scenario has an invalid attack direction")
    end
    for _, skillName in ipairs(step.mandatorySkills) do
      if skillName == "hs__yiji" or skillName == "fankui" then
        fail("Yiji and Fankui must remain optional")
      end
    end
    for _, skillName in ipairs(step.expectedInvokedSkills or {}) do
      if not table.contains(step.optionalSkills, skillName) then
        fail("selected optional reaction is not declared optional")
      end
    end
  end
end

local function validateHiddenYijiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-yiji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-yiji-deputy" and "hs__simayi" or "hs__guojia"
  local expectedDeputy = scenario.id == "hidden-yiji-deputy" and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-yiji actor must use the catalogued Quách Gia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-yiji target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-yiji must expose AskForSkillInvoke as its positive/skip proof")
  end
end

local function validateHiddenRehideYijiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-rehide-yiji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-rehide-yiji-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__guojia"
  local expectedDeputy = deputy and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-rehide-yiji actor must use the catalogued Quách Gia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-rehide-yiji target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-rehide-yiji must expose AskForSkillInvoke before the native damage interaction")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-rehide-yiji must not reserve cards; native Di Kế owns the draw/move path")
  end
end

local function validateHiddenJianxiongScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jianxiong scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jianxiong-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__caocao"
  local expectedDeputy = deputy and "hs__caocao" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-jianxiong actor must use the catalogued Cao Cao main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-jianxiong target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForChoices" then
    fail("hidden-jianxiong must expose AskForChoices after the optional invoke")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "jianxiong-card" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-jianxiong must reserve exactly one target Slash")
  end
end

local function validateHiddenFankuiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fankui scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fankui-deputy"
  local expectedMain = deputy and "hs__guojia" or "hs__simayi"
  local expectedDeputy = deputy and "hs__simayi" or "hs__guojia"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-fankui actor must use the catalogued Tư Mã Ý main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-fankui target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForCardChosen" then
    fail("hidden-fankui must expose AskForCardChosen after the Damaged trigger")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-fankui must reserve one target Slash and one target Peach")
  end
  local damageCard, lootCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "fankui-damage" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      damageCard = card
    elseif card.key == "fankui-loot" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      lootCard = card
    end
  end
  if not damageCard or not lootCard then
    fail("hidden-fankui must reserve a target Slash and a target Peach")
  end
end

local function validateHiddenKuangguScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-kuanggu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-kuanggu-deputy"
  local expectedMain = deputy and "hs__huangzhong" or "hs__weiyan"
  local expectedDeputy = deputy and "hs__weiyan" or "hs__huangzhong"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-kuanggu actor must use the catalogued Wei Yan main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-kuanggu target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-kuanggu must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-kuanggu must reserve one actor Slash and one target Peach")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "kuanggu-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    elseif card.key == "kuanggu-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-kuanggu must reserve an actor Slash and a target Peach")
  end
end

local function validateHiddenLiegongScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-liegong scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-liegong-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__huangzhong"
  local expectedDeputy = deputy and "hs__huangzhong" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-liegong actor must use the catalogued Huang Zhong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-liegong target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-liegong must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-liegong must reserve one actor Slash and one target Peach")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "liegong-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    elseif card.key == "liegong-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-liegong must reserve an actor Slash and a target Peach")
  end
end

local function validateHiddenJueqingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jueqing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jueqing-deputy"
  local expectedMain = deputy and "hs__simayi" or "zhangchunhua"
  local expectedDeputy = deputy and "zhangchunhua" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-jueqing actor must use the catalogued Zhang Chunhua main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-jueqing target must be Zhao Yun + Fa Zheng in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-jueqing must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 then
    fail("hidden-jueqing must reserve one actor Slash")
  end
  local actorCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "jueqing-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    end
  end
  if not actorCard then
    fail("hidden-jueqing must reserve an actor Slash")
  end
end

local function validateHiddenEjueScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-ejue scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-ejue-deputy"
  local expectedMain = deputy and "heg__simayi" or "heg__zhangchunhua"
  local expectedDeputy = deputy and "heg__zhangchunhua" or "heg__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "jin" then
    fail("hidden-ejue actor must use the catalogued Zhang Chunhua main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "hs__zhangfei" or target.kingdom ~= "shu" then
    fail("hidden-ejue source must be Zhao Yun + Zhang Fei in Shu before QA marks it unknown")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-ejue must expose AskForSkillInvoke before the DamageCaused Slash")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "ejue-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-ejue must reserve exactly one actor Slash")
  end
end

local function validateHiddenDufuScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-dufu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-dufu-deputy"
  local expectedMain = deputy and "heg__simayi" or "heg__simajiong"
  local expectedDeputy = deputy and "heg__simajiong" or "heg__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "jin" then
    fail("hidden-dufu actor must use the catalogued Sima Jiong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "hs__zhangfei" or target.kingdom ~= "shu" then
    fail("hidden-dufu target must be Zhao Yun + Zhang Fei in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-dufu must expose AskForSkillInvoke before the DamageCaused Slash")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "dufu-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-dufu must reserve exactly one actor Slash")
  end
end

local function validateHiddenJianzhiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jianzhi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jianzhi-deputy"
  local expectedMain = deputy and "heg__simayi" or "heg__jiachong"
  local expectedDeputy = deputy and "heg__jiachong" or "heg__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "jin" then
    fail("hidden-jianzhi actor must use the catalogued Jia Chong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "hs__zhangfei" or target.kingdom ~= "shu" then
    fail("hidden-jianzhi target must be Zhao Yun + Zhang Fei in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-jianzhi must expose AskForSkillInvoke before the lethal DamageCaused Slash")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-jianzhi must reserve an actor Slash and one filler card")
  end
  local actorSlash, actorFiller
  for _, card in ipairs(scenario.cards) do
    if card.owner == "actor" and card.area == "hand" and type(card.match) == "table" then
      if card.key == "jianzhi-card" and card.match.trueName == "slash" then
        actorSlash = card
      elseif card.key == "jianzhi-filler" and card.match.trueName == "jink" then
        actorFiller = card
      end
    end
  end
  if not actorSlash or not actorFiller then
    fail("hidden-jianzhi must reserve one actor Slash and one actor Jink filler")
  end
end

local function validateHiddenZhimanScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-zhiman scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-zhiman-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "ld__masu"
  local expectedDeputy = deputy and "ld__masu" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-zhiman actor must use the catalogued Ma Su main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-zhiman target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-zhiman must expose AskForSkillInvoke before the DamageCaused Slash")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-zhiman must reserve one actor Slash and one target equipment")
  end
  local actorSlash, targetEquip
  for _, card in ipairs(scenario.cards) do
    if card.key == "zhiman-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorSlash = card
    elseif card.key == "zhiman-equip" and card.owner == "target" and card.area == "equip" and
        type(card.match) == "table" and card.match.type == "equip" then
      targetEquip = card
    end
  end
  if not actorSlash or not targetEquip then
    fail("hidden-zhiman must reserve one actor Slash and one target equipment")
  end
end

local function validateHiddenJilixScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jilix scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jilix-deputy"
  local expectedMain = deputy and "ld__huangzu" or "ld__yanbaihu"
  local expectedDeputy = deputy and "ld__yanbaihu" or "ld__huangzu"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-jilix actor must use the catalogued Yan Baihu main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-jilix source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-jilix must expose the native PlayCard red Slash request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "jilix-slash" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" or scenario.cards[1].match.color ~= "red" then
    fail("hidden-jilix must reserve exactly one red source Slash")
  end
end

local function validateHiddenRevealScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-reveal scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-reveal-deputy" and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = scenario.id == "hidden-reveal-deputy" and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-reveal actor must use the catalogued Lục Tốn main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-reveal target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-reveal must expose AskForUseActiveSkill as its active reveal proof")
  end
end

local function validateHiddenActiveScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-active scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-active-main" and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = scenario.id == "hidden-active-main" and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-active actor must use the catalogued Tôn Quyền main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-active target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-active must expose a native PlayCard request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "zhiheng-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-active must reserve exactly one actor Slash for Chế Hành")
  end
end

local function validateHiddenFanjianScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fanjian scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fanjian-deputy"
  local expectedMain = deputy and "hs__daqiao" or "hs__zhouyu"
  local expectedDeputy = deputy and "hs__zhouyu" or "hs__daqiao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-fanjian actor must use the catalogued Chu Du main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-fanjian target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-fanjian must expose the native PlayCard request")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-fanjian must reserve one actor Peach and one hidden target Jink")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "fanjian-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      actorCard = card
    elseif card.key == "fanjian-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "jink" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-fanjian must reserve an actor Peach and a target Jink")
  end
end

local function validateHiddenViewAsScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-view-as scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local mainIsZhaoyun = scenario.id == "hidden-view-as-main"
  local expectedMain = mainIsZhaoyun and "hs__zhaoyun" or "hs__guanyu"
  local expectedDeputy = mainIsZhaoyun and "hs__guanyu" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-view-as actor must use the catalogued Triệu Vân main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__guojia" or
      target.deputy ~= "hs__simayi" or target.kingdom ~= "wei" then
    fail("hidden-view-as target must be Quách Gia + Tư Mã Ý in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-view-as must expose a native PlayCard request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "longdan-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "jink" then
    fail("hidden-view-as must reserve exactly one actor Jink for Longdan")
  end
end

local function validateHiddenDualScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-dual scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  if type(actor) ~= "table" or actor.general ~= "hs__yanliangwenchou" or
      actor.deputy ~= "hs__yuanshao" or actor.kingdom ~= "qun" then
    fail("hidden-dual actor must use the catalogued Yan Liang/Wen Chou + Yuan Shao pair")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-dual target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-dual must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-dual must reserve exactly one actor Slash and one target Jink")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "shuangxiong-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" and card.match.color == "black" then
      actorCard = card
    elseif card.key == "shuangxiong-discard" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "jink" and card.match.color == "red" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-dual must reserve a black actor Slash and red target Jink")
  end
end

local function validateHiddenLuoshenScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-luoshen scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-luoshen-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__zhenji"
  local expectedDeputy = deputy and "hs__zhenji" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-luoshen actor must use the catalogued Zhen Ji main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-luoshen target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-luoshen must expose AskForSkillInvoke as its phase-start proof")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-luoshen must not reserve hand cards; judgment cards come from the native pile")
  end
end

local function validateHiddenTianduScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-tiandu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-tiandu-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__guojia"
  local expectedDeputy = deputy and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-tiandu actor must use the catalogued Guo Jia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-tiandu target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-tiandu must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-tiandu must not reserve hand cards; the judged card comes from the native pile")
  end
end

local function validateHiddenJizhiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jizhi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jizhi-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__huangyueying"
  local expectedDeputy = deputy and "hs__huangyueying" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-jizhi actor must use the catalogued Huang Yueying main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-jizhi target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-jizhi must expose AskForSkillInvoke for the optional CardUsing effect")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "jizhi-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "duel" then
    fail("hidden-jizhi must reserve exactly one actor Duel")
  end
end

local function validateHiddenMingshiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-mingshi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-mingshi-deputy"
  local expectedMain = deputy and "hs__jiling" or "hs__kongrong"
  local expectedDeputy = deputy and "hs__kongrong" or "hs__jiling"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-mingshi actor must use the catalogued Kong Rong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-mingshi target must be Zhao Yun + Fazheng in Shu")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-mingshi must expose the native PlayCard damage source request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "mingshi-damage" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-mingshi must reserve exactly one hidden-source Slash")
  end
end

local function validateHiddenGongqingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-gongqing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-gongqing-deputy"
  local expectedMain = deputy and "hs__sunquan" or "panjun"
  local expectedDeputy = deputy and "panjun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-gongqing actor must use the catalogued Pan Jun main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-gongqing source must be Zhao Yun + Fazheng in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-gongqing must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "gongqing-bow" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.name ~= "kylin_bow" then
    fail("hidden-gongqing must reserve exactly one source Kylin Bow in hand")
  end
end

local function validateHiddenEnyuanScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-enyuan scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-enyuan-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "ld__fazheng"
  local expectedDeputy = deputy and "ld__fazheng" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-enyuan actor must use the catalogued Fa Zheng main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-enyuan source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-enyuan must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "enyuan-peach" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "peach" then
    fail("hidden-enyuan must reserve exactly one source Peach")
  end
end

local function validateHiddenFuyinScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fuyin scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fuyin-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "zhugezhan"
  local expectedDeputy = deputy and "zhugezhan" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-fuyin actor must use the catalogued Zhuge Zhan main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-fuyin source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-fuyin must expose the native PlayCard Slash request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "fuyin-slash" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-fuyin must reserve exactly one source Slash")
  end
end

local function validateHiddenQianxunScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-qianxun scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-qianxun-deputy" or
    scenario.id == "hidden-qianxun-indulgence-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = deputy and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-qianxun actor must use the catalogued Lục Tốn main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-qianxun source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-qianxun must expose AskForUseActiveSkill for the real Snatch request")
  end
  local indulgenceScenario = scenario.id == "hidden-qianxun-indulgence" or
    scenario.id == "hidden-qianxun-indulgence-deputy"
  if indulgenceScenario then
    if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
        scenario.cards[1].key ~= "qianxun-indulgence" or
        scenario.cards[1].owner ~= "target" or scenario.cards[1].area ~= "hand" or
        type(scenario.cards[1].match) ~= "table" or
        scenario.cards[1].match.trueName ~= "indulgence" then
      fail("hidden-qianxun indulgence scenarios must reserve one source Indulgence")
    end
  else
    if #scenario.cards ~= 2 then
      fail("hidden-qianxun must reserve one source Snatch and one actor Peach")
    end
    local snatchCard, victimCard
    for _, card in ipairs(scenario.cards) do
      if card.key == "qianxun-snatch" and card.owner == "target" and card.area == "hand" and
          type(card.match) == "table" and card.match.trueName == "snatch" then
        snatchCard = card
      elseif card.key == "qianxun-victim" and card.owner == "actor" and card.area == "hand" and
          type(card.match) == "table" and card.match.trueName == "peach" then
        victimCard = card
      end
    end
    if not snatchCard or not victimCard then
      fail("hidden-qianxun must reserve a target Snatch and actor Peach")
    end
  end
end

local function validateHiddenKongchengScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-kongcheng scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-kongcheng-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__zhugeliang"
  local expectedDeputy = deputy and "hs__zhugeliang" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-kongcheng actor must use the catalogued Zhuge Liang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-kongcheng source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-kongcheng must expose AskForUseActiveSkill for the real Duel request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "kongcheng-duel" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "duel" then
    fail("hidden-kongcheng must reserve one source Duel")
  end
end

local function validateHiddenWeimuScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-weimu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-weimu-deputy" or
    scenario.id == "hidden-weimu-indulgence-deputy"
  local indulgenceScenario = scenario.id == "hidden-weimu-indulgence" or
    scenario.id == "hidden-weimu-indulgence-deputy"
  local expectedMain = deputy and "hs__pangde" or "hs__jiaxu"
  local expectedDeputy = deputy and "hs__jiaxu" or "hs__pangde"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-weimu actor must use the catalogued Jia Xu main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-weimu source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-weimu must expose AskForUseActiveSkill for the real black Trick request")
  end
  local expectedKey = indulgenceScenario and "weimu-indulgence" or "weimu-duel"
  local expectedTrueName = indulgenceScenario and "indulgence" or "duel"
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= expectedKey or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= expectedTrueName or scenario.cards[1].match.color ~= "black" then
    fail(indulgenceScenario and
      "hidden-weimu indulgence scenarios must reserve one black source Indulgence" or
      "hidden-weimu must reserve one black source Duel")
  end
end

local function validateHiddenXiaojiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-xiaoji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-xiaoji-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__sunshangxiang"
  local expectedDeputy = deputy and "hs__sunshangxiang" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-xiaoji actor must use the catalogued Sun Shangxiang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-xiaoji source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-xiaoji must expose AskForSkillInvoke for the prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "xiaoji-equip" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "equip" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.type ~= "equip" then
    fail("hidden-xiaoji must reserve exactly one actor equipment")
  end
end

local function validateHiddenGuanxingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-guanxing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-guanxing-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__zhugeliang"
  local expectedDeputy = deputy and "hs__zhugeliang" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-guanxing actor must use the catalogued Zhuge Liang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-guanxing source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-guanxing must expose AskForSkillInvoke before the native arrange request")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-guanxing must let native Guanxing own the top-card selection")
  end
end

local function validateHiddenYingziScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-yingzi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-yingzi-deputy"
  local expectedMain = deputy and "hs__daqiao" or "hs__zhouyu"
  local expectedDeputy = deputy and "hs__zhouyu" or "hs__daqiao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-yingzi actor must use the catalogued Zhou Yu main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-yingzi source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-yingzi must expose AskForSkillInvoke only for the prelight readiness gate")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-yingzi must let the native DrawNCards event own the draw")
  end
end

local function validateHiddenTianxiangScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-tianxiang scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-tianxiang-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__xiaoqiao"
  local expectedDeputy = deputy and "hs__xiaoqiao" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-tianxiang actor must use the catalogued Xiao Qiao main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-tianxiang source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-tianxiang must expose AskForSkillInvoke before its native damage interaction")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "tianxiang-heart" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.suit ~= "heart" then
    fail("hidden-tianxiang must reserve exactly one actor heart hand card")
  end
end

local function validateHiddenDuanchangScenario(scenario)
  if scenario.playerCount ~= 4 or type(scenario.players) ~= "table" then
    fail("hidden-duanchang scenarios must define exactly four players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-duanchang-deputy"
  local expectedMain = deputy and "hs__yuanshao" or "hs__caiwenji"
  local expectedDeputy = deputy and "hs__caiwenji" or "hs__yuanshao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-duanchang actor must use the catalogued Cai Wenji main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__caocao" or
      target.deputy ~= "hs__simayi" or target.kingdom ~= "wei" then
    fail("hidden-duanchang killer must be Cao Cao + Sima Yi in Wei")
  end
  if scenario.expectedCommand ~= "AskForChoices" then
    fail("hidden-duanchang must expose AskForChoices for the killer slot choice")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-duanchang must not reserve cards")
  end
end

local function validateAiTraceScenario(scenario)
  if scenario.playerCount ~= 4 or type(scenario.seatRosters) ~= "table" or
      #scenario.seatRosters ~= 4 then
    fail("ai-trace must define exactly four fixed seat rosters")
  end
  if type(scenario.fixedHands) ~= "table" or #scenario.fixedHands ~= 4 then
    fail("ai-trace must define exactly four semantic fixed hands")
  end
  if scenario.expectedCommand ~= "PlayCard" or #scenario.cards ~= 0 then
    fail("ai-trace must use PlayCard as its command anchor and reserve no cards")
  end
  if scenario.trigger == "ai-trace" then
    local expectedPrompt4Skills = {
      "tianyi", "shangyi", "tiaoxin", "hs__zhiheng", "hs__kurou", "hs__qiangxi",
      "hs__longdan", "hs__luanji", "hs__wusheng", "huoji", "jijiu", "kanpo",
      "aocai", "beizhu", "dimeng", "choufa", "cunsi", "duanfa",
    }
    if type(scenario.prompt4Skills) ~= "table" or #scenario.prompt4Skills ~= #expectedPrompt4Skills then
      fail("ai-trace must pin the eighteen Prompt 4 native skills")
    end
    for index, skillName in ipairs(expectedPrompt4Skills) do
      local missingNativeSkill = type(Fk) == "table" and type(Fk.skills) == "table" and not Fk.skills[skillName]
      if scenario.prompt4Skills[index] ~= skillName or missingNativeSkill then
        fail("ai-trace Prompt 4 skill order or installation drift at " .. tostring(index))
      end
    end

    if scenario.seedRange ~= nil or scenario.seedVariants ~= nil then
      local range = scenario.seedRange
      if type(range) ~= "table" or type(range.min) ~= "number" or type(range.max) ~= "number" or
          range.min > range.max or type(scenario.seedVariants) ~= "table" or #scenario.seedVariants < 2 then
        fail("ai-trace seed matrix metadata is invalid")
      end
      local seenSeeds = {}
      for _, variant in ipairs(scenario.seedVariants) do
        if type(variant) ~= "table" or type(variant.seed) ~= "number" or seenSeeds[variant.seed] or
            variant.seed < range.min or variant.seed > range.max then
          fail("ai-trace seed matrix contains an invalid or duplicate seed")
        end
        seenSeeds[variant.seed] = true
        validateAiTraceScenario({
          id = scenario.id .. "/" .. tostring(variant.seed),
          trigger = scenario.trigger,
          playerCount = scenario.playerCount,
          seatRosters = variant.seatRosters,
          fixedHands = variant.fixedHands,
          expectedCommand = scenario.expectedCommand,
          cards = scenario.cards,
          prompt4Skills = scenario.prompt4Skills,
        })
      end
      if not seenSeeds[scenario.seed] then
        fail("ai-trace seed matrix must include the default seed")
      end
    end
  end
  for seat, roster in ipairs(scenario.seatRosters) do
    if type(roster) ~= "table" or type(roster.general) ~= "string" or
        type(roster.deputy) ~= "string" or type(roster.kingdom) ~= "string" then
      fail("ai-trace has an invalid roster at seat " .. tostring(seat))
    end
    local matcher = scenario.fixedHands[seat]
    if type(matcher) ~= "table" or type(matcher.trueName) ~= "string" or
        matcher.trueName == "" or
        (matcher.suit ~= "heart" and matcher.suit ~= "diamond" and
         matcher.suit ~= "spade" and matcher.suit ~= "club") or
        (matcher.color ~= "red" and matcher.color ~= "black") or
        ((matcher.suit == "heart" or matcher.suit == "diamond") ~= (matcher.color == "red")) then
      fail("ai-trace has an invalid semantic fixed hand at seat " .. tostring(seat))
    end
  end
end

local function validateChooserTraceScenario(scenario)
  -- Reuse the proven semantic hand/roster contract but keep the five-decision
  -- ai-trace protocol completely independent.
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("chooser-trace must anchor AskForUseActiveSkill")
  end
  local shadow = { playerCount = scenario.playerCount, seatRosters = scenario.seatRosters,
    fixedHands = scenario.fixedHands, expectedCommand = "PlayCard", cards = scenario.cards }
  validateAiTraceScenario(shadow)
  local expected = { "choose_players_skill", "choose_cards_skill", "ex__choose_skill" }
  if type(scenario.cases) ~= "table" or #scenario.cases ~= 6 then
    fail("chooser-trace must declare six bounded cases")
  end
  for index, spec in ipairs(scenario.cases) do
    if type(spec) ~= "table" or spec.skill ~= expected[(index - 1) % 3 + 1] or
        spec.variant ~= (index <= 3 and "mandatory" or "optional") then
      fail("chooser-trace case order, skill or variant drift")
    end
  end
end

local function validateGeneralPairTraceScenario(scenario)
  local label = scenario.id or "general-pair-trace"
  if scenario.playerCount ~= 4 or type(scenario.offeredGroups) ~= "table" or
      #scenario.offeredGroups ~= 4 then
    fail(label .. " must define exactly four offered general groups")
  end
  if scenario.expectedCommand ~= "CustomDialog" or #scenario.cards ~= 0 then
    fail(label .. " must use CustomDialog as its command anchor and reserve no cards")
  end
  if type(scenario.enabledKingdoms) ~= "table" or #scenario.enabledKingdoms == 0 then
    fail(label .. " must define at least one enabled kingdom")
  end
  local enabled = {}
  for _, kingdom in ipairs(scenario.enabledKingdoms) do
    if type(kingdom) ~= "string" or kingdom == "" then
      fail(label .. " has an invalid enabled kingdom")
    end
    enabled[kingdom] = true
  end
  for seat, offered in ipairs(scenario.offeredGroups) do
    if type(offered) ~= "table" or #offered ~= 5 then
      fail(label .. " seat " .. tostring(seat) .. " must offer exactly five generals")
    end
    local seen = {}
    for _, name in ipairs(offered) do
      local general = type(Fk) == "table" and type(Fk.generals) == "table" and
        type(name) == "string" and Fk.generals[name] or nil
      -- The standalone catalog loader intentionally supplies no engine. The
      -- native package performs the stronger Fk.generals/kingdom check once
      -- the pinned packages have loaded.
      local invalidDefinition = type(Fk) == "table" and type(Fk.generals) == "table" and
        (not general or not enabled[general.kingdom])
      if type(name) ~= "string" or seen[name] or invalidDefinition then
        fail(label .. " has an invalid or duplicate general at seat " .. tostring(seat))
      end
      seen[name] = true
    end
  end
  if scenario.matrixFamily ~= nil then
    if scenario.matrixFamily ~= "general-pair-winrate-v1" or
        type(scenario.matrixRosterSets) ~= "table" or #scenario.matrixRosterSets == 0 or
        type(scenario.matrixSeatPermutation) ~= "string" or
        type(scenario.seedRange) ~= "table" or
        type(scenario.seedRange.min) ~= "number" or type(scenario.seedRange.max) ~= "number" or
        scenario.seedRange.min > scenario.seedRange.max or
        type(generalPairMatrix) ~= "table" then
      fail(label .. " has invalid win-rate matrix metadata")
    end
    local permutation = generalPairMatrix.seatPermutations and
      generalPairMatrix.seatPermutations[scenario.matrixSeatPermutation]
    if type(permutation) ~= "table" or #permutation ~= 4 then
      fail(label .. " has no four-seat permutation in the win-rate matrix")
    end
    for _, rosterName in ipairs(scenario.matrixRosterSets) do
      local rosterSet = generalPairMatrix.rosterSets and generalPairMatrix.rosterSets[rosterName]
      local expectedCount = matrixGeneralCount()
      if type(rosterSet) ~= "table" or type(rosterSet.offeredGroups) ~= "table" or
          #rosterSet.offeredGroups ~= 4 then
        fail(label .. " references an invalid roster set " .. tostring(rosterName))
      end
      local rosterKingdoms = rosterSet.enabledKingdoms
      if type(rosterKingdoms) ~= "table" or #rosterKingdoms ~= 4 then
        fail(label .. " roster set " .. tostring(rosterName) .. " must define four kingdoms")
      end
      for sourceSeat, offered in ipairs(rosterSet.offeredGroups) do
        if type(offered) ~= "table" or #offered ~= expectedCount then
          fail(label .. " roster set " .. tostring(rosterName) .. " seat " .. tostring(sourceSeat) ..
            " must offer exactly " .. tostring(expectedCount) .. " generals")
        end
        local seen = {}
        for _, name in ipairs(offered) do
          local general = type(Fk) == "table" and type(Fk.generals) == "table" and
            type(name) == "string" and Fk.generals[name] or nil
          local invalidDefinition = type(Fk) == "table" and type(Fk.generals) == "table" and
            (not general or not table.contains(rosterKingdoms, general.kingdom))
          if type(name) ~= "string" or seen[name] or invalidDefinition then
            fail(label .. " roster set " .. tostring(rosterName) ..
              " has an invalid or duplicate general at source seat " .. tostring(sourceSeat))
          end
          seen[name] = true
        end
      end
    end
  end
end

for _, scenario in ipairs(catalog.scenarios) do
  if type(scenario.id) ~= "string" or scenario.id == "" or scenarioById[scenario.id] or
      type(scenario.seed) ~= "number" or type(scenario.expectedCommand) ~= "string" or
      type(scenario.trigger) ~= "string" or type(scenario.cards) ~= "table" then
    fail("invalid or duplicate scenario catalog entry")
  end
  if scenario.trigger == "damage-exchange" then
    validateDamageExchangeScenario(scenario)
  elseif scenario.trigger == "hidden-yiji" then
    validateHiddenYijiScenario(scenario)
  elseif scenario.trigger == "hidden-rehide-yiji" then
    validateHiddenRehideYijiScenario(scenario)
  elseif scenario.trigger == "hidden-jianxiong" then
    validateHiddenJianxiongScenario(scenario)
  elseif scenario.trigger == "hidden-fankui" then
    validateHiddenFankuiScenario(scenario)
  elseif scenario.trigger == "hidden-kuanggu" then
    validateHiddenKuangguScenario(scenario)
  elseif scenario.trigger == "hidden-liegong" then
    validateHiddenLiegongScenario(scenario)
  elseif scenario.trigger == "hidden-jueqing" then
    validateHiddenJueqingScenario(scenario)
  elseif scenario.trigger == "hidden-ejue" then
    validateHiddenEjueScenario(scenario)
  elseif scenario.trigger == "hidden-dufu" then
    validateHiddenDufuScenario(scenario)
  elseif scenario.trigger == "hidden-jianzhi" then
    validateHiddenJianzhiScenario(scenario)
  elseif scenario.trigger == "hidden-zhiman" then
    validateHiddenZhimanScenario(scenario)
  elseif scenario.trigger == "hidden-jilix" then
    validateHiddenJilixScenario(scenario)
  elseif scenario.trigger == "hidden-reveal" then
    validateHiddenRevealScenario(scenario)
  elseif scenario.trigger == "hidden-active" then
    validateHiddenActiveScenario(scenario)
  elseif scenario.trigger == "hidden-fanjian" then
    validateHiddenFanjianScenario(scenario)
  elseif scenario.trigger == "hidden-view-as" then
    validateHiddenViewAsScenario(scenario)
  elseif scenario.trigger == "hidden-dual" then
    validateHiddenDualScenario(scenario)
  elseif scenario.trigger == "hidden-luoshen" then
    validateHiddenLuoshenScenario(scenario)
  elseif scenario.trigger == "hidden-tiandu" then
    validateHiddenTianduScenario(scenario)
  elseif scenario.trigger == "hidden-jizhi" then
    validateHiddenJizhiScenario(scenario)
  elseif scenario.trigger == "hidden-mingshi" then
    validateHiddenMingshiScenario(scenario)
  elseif scenario.trigger == "hidden-gongqing" then
    validateHiddenGongqingScenario(scenario)
  elseif scenario.trigger == "hidden-enyuan" then
    validateHiddenEnyuanScenario(scenario)
  elseif scenario.trigger == "hidden-fuyin" then
    validateHiddenFuyinScenario(scenario)
  elseif scenario.trigger == "hidden-qianxun" then
    validateHiddenQianxunScenario(scenario)
  elseif scenario.trigger == "hidden-kongcheng" then
    validateHiddenKongchengScenario(scenario)
  elseif scenario.trigger == "hidden-weimu" then
    validateHiddenWeimuScenario(scenario)
  elseif scenario.trigger == "hidden-xiaoji" then
    validateHiddenXiaojiScenario(scenario)
  elseif scenario.trigger == "hidden-guanxing" then
    validateHiddenGuanxingScenario(scenario)
  elseif scenario.trigger == "hidden-yingzi" then
    validateHiddenYingziScenario(scenario)
  elseif scenario.trigger == "hidden-tianxiang" then
    validateHiddenTianxiangScenario(scenario)
  elseif scenario.trigger == "hidden-duanchang" then
    validateHiddenDuanchangScenario(scenario)
  elseif scenario.trigger == "ai-trace" then
    validateAiTraceScenario(scenario)
  elseif scenario.trigger == "chooser-trace" then
    validateChooserTraceScenario(scenario)
  elseif scenario.trigger == "general-pair-trace" or scenario.trigger == "general-pair-match" then
    validateGeneralPairTraceScenario(scenario)
  end
  scenarioById[scenario.id] = scenario
end

local allowedUsers = config.allowedUsers
if type(allowedUsers) ~= "table" or #allowedUsers == 0 then
  fail("tqsQa.allowedUsers must contain at least one QA account")
end

local roomPrefix = type(config.roomPrefix) == "string" and config.roomPrefix or "TQSQA/"
local maxPlayers = tonumber(config.maxPlayers) or 4
local maxActiveRooms = tonumber(config.maxActiveRooms) or 1
local maxDurationSeconds = tonumber(config.maxDurationSeconds) or 900
local maxRunsPerProcess = tonumber(config.maxRunsPerProcess) or 50

local extension = Package:new("tqs_qa", Package.SpecialPack)
extension.extensionName = "tqs_qa"

local activeRooms = {}
local totalRuns = 0

local function now()
  return os.time()
end

local function activeRoomCount()
  local count = 0
  for _, state in pairs(activeRooms) do
    if now() - state.startedAt <= maxDurationSeconds then
      count = count + 1
    end
  end
  return count
end

local function parseSeed(value)
  if type(value) ~= "string" or not value:match("^0[xX][0-9a-fA-F]+$") then
    return nil
  end
  return tonumber(value:sub(3), 16)
end

local function parseRequest(room)
  local roomName = room:getSettings("roomName") or ""
  if roomName:sub(1, #roomPrefix) ~= roomPrefix then
    return nil
  end

  local id, seedText = roomName:sub(#roomPrefix + 1):match("^([%w%-]+)/(0[xX][0-9a-fA-F]+)$")
  if not id or not seedText then
    fail("QA room name must be " .. roomPrefix .. "<scenario-id>/<0xseed>")
  end
  local scenario = scenarioById[id]
  if not scenario then
    fail("unknown scenario: " .. id)
  end
  local seed = parseSeed(seedText)
  local resolved = seed and resolveGeneralPairScenario(scenario, seed) or nil
  if not resolved then
    fail("seed does not match catalog for scenario " .. id)
  end
  return resolved, seed
end

-- General-pair selection happens inside HegLogic:chooseGenerals, before
-- fk.GamePrepared and therefore before the ordinary scenario state exists.
-- Resolve only this validated QA room from its room name so the
-- package-level hooks below cannot affect public or non-QA rooms.
local function generalPairTraceScenarioForRoom(room)
  local roomName = room:getSettings("roomName") or ""
  if roomName:sub(1, #roomPrefix) ~= roomPrefix then return nil end
  local id, seedText = roomName:sub(#roomPrefix + 1):match("^([%w%-]+)/(0[xX][0-9a-fA-F]+)$")
  local scenario = id and scenarioById[id] or nil
  if not scenario or (scenario.trigger ~= "general-pair-trace" and scenario.trigger ~= "general-pair-match") then
    return nil
  end
  local seed = parseSeed(seedText)
  return seed and resolveGeneralPairScenario(scenario, seed) or nil
end

local function isAllowedUser(name)
  return type(name) == "string" and table.contains(allowedUsers, name)
end

local function assertRoomAllowed(room, scenario)
  if #room.players < 2 then
    fail("scenario " .. scenario.id .. " requires at least two players")
  end
  if scenario.playerCount and #room.players ~= scenario.playerCount then
    fail(string.format("scenario %s requires exactly %d players", scenario.id, scenario.playerCount))
  end
  if #room.players > maxPlayers then
    fail("QA room exceeds maxPlayers")
  end
  for _, player in ipairs(room.players) do
    -- Negative ids are native bots. They inherit the room's QA authorization.
    if player.id > 0 then
      local screenName = player._splayer:getScreenName()
      if not isAllowedUser(screenName) then
        fail("non-allowlisted player attempted to enter a QA room")
      end
    end
  end
  if totalRuns >= maxRunsPerProcess then
    fail("process QA run quota exhausted")
  end
  if activeRoomCount() >= maxActiveRooms then
    fail("active QA room quota exhausted")
  end
end

local function cardMatches(card, matcher)
  if matcher.trueName and card.trueName ~= matcher.trueName then
    return false
  end
  if matcher.name and card.name ~= matcher.name then
    return false
  end
  if matcher.type == "equip" and card.type ~= Card.TypeEquip then
    return false
  end
  if matcher.color and card:getColorString() ~= matcher.color then
    return false
  end
  if matcher.suit and card:getSuitString() ~= matcher.suit then
    return false
  end
  return true
end

local function takeCard(room, matcher, reserved)
  for _, id in ipairs(room.draw_pile) do
    if not reserved[id] and cardMatches(Fk:getCardById(id), matcher) then
      reserved[id] = true
      return id
    end
  end
  fail("catalog card is unavailable in the native draw pile")
end

local function playerForRole(state, owner)
  if owner == "actor" then return state.actor end
  if owner == "target" then return state.target end
  fail("unknown card owner: " .. tostring(owner))
end

local function getGeneral(generalName)
  local general = Fk.generals[generalName]
  if not general then
    fail("catalog general is not installed: " .. generalName)
  end
  return general
end

local function clearInitialFakeSkills(player)
  local seen = {}
  for _, mark in ipairs({ "__heg_general", "__heg_deputy" }) do
    local generalName = player:getMark(mark)
    local general = type(generalName) == "string" and Fk.generals[generalName] or nil
    if general then
      for _, skillName in ipairs(general:getSkillNameList(true)) do
        if not seen[skillName] then
          seen[skillName] = true
          local skill = Fk.skills[skillName]
          if skill and player:isFakeSkill(skill) then
            player:loseFakeSkill(skill)
          end
        end
      end
    end
  end
  local revealSkill = Fk.skills["reveal_skill&"]
  if revealSkill and player:isFakeSkill(revealSkill) then
    player:loseFakeSkill(revealSkill)
  end
end

local function attachGeneralPair(room, player, roster)
  if room:getSettings("gameMode") ~= "new_heg_mode" then
    fail("catalog general injection currently requires new_heg_mode")
  end
  local general = getGeneral(roster.general)
  local deputy = getGeneral(roster.deputy)
  if general.kingdom ~= roster.kingdom then
    fail(string.format("%s is not in the catalog kingdom %s", roster.general, roster.kingdom))
  end
  if deputy.kingdom ~= roster.kingdom then
    fail(string.format("%s is not in the catalog kingdom %s", roster.deputy, roster.kingdom))
  end

  -- Hegemony has already attached the randomly selected pair as fake skills
  -- when GamePrepared fires. Remove those first, otherwise an unrelated
  -- random trigger could make this scenario look like a false positive.
  clearInitialFakeSkills(player)
  room:setPlayerMark(player, "__heg_general", roster.general)
  room:setPlayerMark(player, "__heg_deputy", roster.deputy)
  room:setPlayerMark(player, "__heg_wild", 0)
  room:setPlayerMark(player, "__heg_kingdom", roster.kingdom)
  room:setPlayerMark(player, "__heg_init_kingdom", roster.kingdom)
  -- GamePrepared runs after the ordinary general draft but before the first
  -- draw. Replace the public pair as well as the private marks; leaving the
  -- draft pair in player.general/deputyGeneral makes the browser show a
  -- random roster and lets later ChangeProperty handling index a stale slot.
  room:setPlayerProperty(player, "general", roster.general)
  room:setPlayerProperty(player, "deputyGeneral", roster.deputy)
  room:setPlayerProperty(player, "kingdom", roster.kingdom)
  player.role = roster.kingdom

  local maxHp = (general.maxHp + general.mainMaxHpAdjustedValue +
    deputy.maxHp + deputy.deputyMaxHpAdjustedValue) // 2
  room:setPlayerProperty(player, "maxHp", maxHp)
  room:setPlayerProperty(player, "hp", maxHp)

  local hasCompulsory = false
  local function attachSelectedGeneralSkills(selectedGeneral, isDeputy)
    -- Keep the QA injection identical to HegLogic: a main general cannot
    -- contribute a DeputyPlace-only skill, and vice versa. Without this
    -- filter a deterministic scenario could test a skill that the native
    -- Hegemony setup would never attach to the selected slot.
    local excludedPlace = isDeputy and Skill.MainPlace or Skill.DeputyPlace
    for _, skillName in ipairs(selectedGeneral:getSkillNameList(true)) do
      local skill = Fk.skills[skillName]
      if skill and not skill:hasTag(excludedPlace) then
        room:addFakeSkill(player, skillName)
        if skill:hasTag(Skill.Compulsory) then
          hasCompulsory = true
        end
      end
    end
  end
  attachSelectedGeneralSkills(general, false)
  attachSelectedGeneralSkills(deputy, true)
  if hasCompulsory then
    room:addFakeSkill(player, "reveal_skill&")
  end
end

local function attachGeneral(room, player, generalName)
  local general = getGeneral(generalName)
  if room:getSettings("gameMode") ~= "new_heg_mode" then
    fail("catalog general injection currently requires new_heg_mode")
  end
  room:setPlayerMark(player, "__heg_general", generalName)
  -- Keep the deputy marker selected by the real Hegemony setup. Several
  -- downstream rules read it after GamePrepared; replacing it with numeric 0
  -- would make those rules index a non-existent general.
  room:setPlayerMark(player, "__heg_wild", general.kingdom == "wild" and 1 or 0)
  if general.kingdom == "wild" then
    room:setPlayerMark(player, "__heg_kingdom", "wild")
    room:setPlayerMark(player, "__heg_init_kingdom", "wild")
  end
  for _, skillName in ipairs(general:getSkillNameList(true)) do
    local skill = Fk.skills[skillName]
    if skill and not skill:hasTag(Skill.DeputyPlace) then
      room:addFakeSkill(player, skillName)
    end
  end
end

local function nextRandom(value)
  -- xorshift32, kept in the native Lua layer so the same seed produces the
  -- same deterministic tail order without touching the engine RNG globally.
  value = value ~ ((value << 13) & 0xffffffff)
  value = value ~ (value >> 17)
  value = value ~ ((value << 5) & 0xffffffff)
  return value & 0xffffffff
end

local function shuffleTail(room, seed)
  local value = seed & 0xffffffff
  for index = #room.draw_pile, 2, -1 do
    value = nextRandom(value)
    local swap = (value % index) + 1
    room.draw_pile[index], room.draw_pile[swap] = room.draw_pile[swap], room.draw_pile[index]
  end
  for _, id in ipairs(room.draw_pile) do
    room:setCardArea(id, Card.DrawPile, nil)
  end
  room:syncDrawPile()
end

-- Prompt 4 native replay uses a private, metadata-only card fixture.  The
-- cards are selected by semantic shape from the pinned draw pile and moved to
-- Void until GameStart, so ordinary initial draws cannot consume them.  Card
-- ids never leave this function or enter the trace; the later fingerprints
-- retain only trueName/color/suit/type shapes.
local function reservePrompt4Card(room, reserved, label, predicate)
  for _, id in ipairs(room.draw_pile or {}) do
    if not reserved[id] then
      local ok, card = pcall(Fk.getCardById, Fk, id)
      if ok and card and predicate(card) then
        reserved[id] = true
        room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, "tqs_qa", nil, false)
        return id
      end
    end
  end
  fail("ai-trace Prompt 4 fixture card is unavailable: " .. tostring(label))
end

local function prompt4CardSuit(card)
  if not card or type(card.getSuitString) ~= "function" then return "" end
  local ok, suit = pcall(card.getSuitString, card)
  return ok and suit or ""
end

local function reservePrompt4Fixture(room, reserved)
  local cards = {}
  cards.high = reservePrompt4Card(room, reserved, "high", function(card)
    return card.trueName == "savage_assault" and prompt4CardSuit(card) == "spade"
  end)
  cards.weapon = reservePrompt4Card(room, reserved, "weapon", function(card)
    return card.sub_type == Card.SubtypeWeapon and
      (card.trueName == "kylin_bow" or card.name == "kylin_bow")
  end)
  cards.red_heart_a = reservePrompt4Card(room, reserved, "red_pair_a", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "heart"
  end)
  cards.red_heart_b = reservePrompt4Card(room, reserved, "red_pair_b", function(card)
    return card.trueName == "peach" and prompt4CardSuit(card) == "heart"
  end)
  cards.black_spade = reservePrompt4Card(room, reserved, "black_pair_a", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "spade"
  end)
  cards.black_club = reservePrompt4Card(room, reserved, "black_pair_b", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "club"
  end)
  cards.jink = reservePrompt4Card(room, reserved, "jink", function(card)
    return card.trueName == "jink" and prompt4CardSuit(card) == "diamond"
  end)
  local target_extra = reservePrompt4Card(room, reserved, "target_extra", function(card)
    return card.trueName == "jink" and prompt4CardSuit(card) == "diamond"
  end)
  local native_bot_jink = reservePrompt4Card(room, reserved, "native_bot_jink", function(card)
    return card.trueName == "jink" and prompt4CardSuit(card) == "diamond"
  end)
  local native_bot_longdan_jink = reservePrompt4Card(room, reserved, "native_bot_longdan_jink", function(card)
    return card.trueName == "jink" and prompt4CardSuit(card) == "diamond"
  end)
  local native_bot_huoji_red_a = reservePrompt4Card(room, reserved, "native_bot_huoji_red_a", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "heart"
  end)
  local native_bot_huoji_red_b = reservePrompt4Card(room, reserved, "native_bot_huoji_red_b", function(card)
    return card.trueName == "peach" and prompt4CardSuit(card) == "heart"
  end)
  local native_bot_luanji_black_a = reservePrompt4Card(room, reserved, "native_bot_luanji_black_a", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "spade"
  end)
  local native_bot_luanji_black_b = reservePrompt4Card(room, reserved, "native_bot_luanji_black_b", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "club"
  end)
  local native_bot_tianyi_high = reservePrompt4Card(room, reserved, "native_bot_tianyi_high", function(card)
    return type(card.number) == "number" and card.number >= 10
  end)
  local native_bot_tianyi_low = reservePrompt4Card(room, reserved, "native_bot_tianyi_low", function(card)
    return type(card.number) == "number" and card.number <= 3
  end)
  local native_bot_tiaoxin_slash = reservePrompt4Card(room, reserved, "native_bot_tiaoxin_slash", function(card)
    return card.trueName == "slash"
  end)
  cards.shangyi_black = reservePrompt4Card(room, reserved, "shangyi_black", function(card)
    return card.trueName == "slash" and prompt4CardSuit(card) == "spade"
  end)
  return cards, {
    target_extra, native_bot_jink, native_bot_tianyi_high, native_bot_tianyi_low,
    native_bot_tiaoxin_slash, native_bot_longdan_jink, native_bot_huoji_red_a,
    native_bot_huoji_red_b, native_bot_luanji_black_a, native_bot_luanji_black_b,
  }
end

local function setupCards(room, state, scenario)
  local reserved = {}
  state.fixedHands = {}
  state.deferredHands = {}
  state.slotCards = {}
  for _, spec in ipairs(scenario.cards) do
    local owner = playerForRole(state, spec.owner)
    local id = takeCard(room, spec.match, reserved)
    state.slotCards[spec.key] = id
    if spec.area == "equip" then
      room:moveCardTo(id, Card.PlayerEquip, owner, fk.ReasonJustMove, "tqs_qa", nil, true, owner)
    elseif spec.area == "hand" then
      -- The core's DrawInitialCards fixture path can notify a private hand
      -- card with from=nil/fromArea=Player.Hand.  That is invalid input for
      -- the client known-card tracker (and is especially easy to hit when
      -- the reserved hand belongs to the opponent).  Keep this Jianxiong
      -- card out of the initial draw entirely, then move it into the target
      -- hand through the normal MoveCards path immediately before the real
      -- Slash request.  The gameplay assertion remains the same while the
      -- QA setup no longer fabricates a malformed private-hand move.
      if scenario.trigger == "hidden-jianxiong" and spec.owner == "target" then
        -- Use the normal move path here as well.  Mutating draw_pile/void
        -- directly would leave each client believing this ID is still in
        -- DrawPile, so the later Void -> target-hand move would be ignored
        -- by CardManager:applyMoveInfo on the browser client.
        room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, "tqs_qa", nil, false)
        state.deferredHands[spec.key] = id
      else
        state.fixedHands[owner.id] = state.fixedHands[owner.id] or {}
        table.insert(state.fixedHands[owner.id], id)
      end
    else
      fail("unsupported catalog card area: " .. tostring(spec.area))
    end
  end
  if scenario.trigger == "ai-trace" or scenario.trigger == "chooser-trace" then
    -- Initial draws happen before the scenario seed is applied to the tail.
    -- Give every fixed seat one deterministic semantic card so the real
    -- SmartAI probe receives the same hand shape in baseline and candidate.
    -- These IDs stay in the private fixture state and never enter metadata
    -- logs; only the hashed card shape is retained by aiTraceInputFingerprint.
    for seat, player in ipairs(room.players or {}) do
      state.fixedHands[player.id] = { takeCard(room, scenario.fixedHands[seat], reserved) }
    end
  end
  if scenario.trigger == "ai-trace" and type(scenario.prompt4Skills) == "table" then
    state.prompt4Cards, state.prompt4TargetCards = reservePrompt4Fixture(room, reserved)
  end
  if scenario.trigger == "hidden-fuyin" then
    -- 父荫 only nullifies the first Slash when the user's hand is no larger
    -- than the Slash user. The catalogued source Slash is the only card that
    -- must be selected by the browser; add four non-Slash filler cards so the
    -- native source has five cards against the actor's normal four-card hand.
    -- This preserves the real hand-size predicate instead of making the QA
    -- fixture pass by bypassing it.
    local source = playerForRole(state, "target")
    state.fixedHands[source.id] = state.fixedHands[source.id] or {}
    for _ = 1, 4 do
      table.insert(state.fixedHands[source.id], takeCard(room, { trueName = "jink" }, reserved))
    end
  end
end

local function preparePrompt4Fixture(room, state)
  if type(state.prompt4Cards) ~= "table" or state.prompt4FixturePrepared then return end
  local ordered = {
    "high", "weapon", "red_heart_a", "red_heart_b", "black_spade", "black_club", "jink",
  }
  for _, key in ipairs(ordered) do
    local id = state.prompt4Cards[key]
    if not id then fail("ai-trace Prompt 4 fixture is missing " .. key) end
    room:moveCardTo(id, Card.PlayerHand, state.actor, fk.ReasonJustMove,
      "tqs_qa", nil, false, state.actor)
  end
  local extra = state.prompt4TargetCards and state.prompt4TargetCards[1]
  if not extra then fail("ai-trace Prompt 4 target fixture is missing") end
  room:moveCardTo(extra, Card.PlayerHand, room.players[2], fk.ReasonJustMove,
    "tqs_qa", nil, false, room.players[2])
  local nativeBot = table.find(room.players, function(player)
    return player.id < 0 and player:isAlive()
  end)
  local nativeBotTarget = table.find(room.players, function(player)
    return player.id < 0 and player ~= nativeBot and player:isAlive()
  end)
  local nativeBotJink = state.prompt4TargetCards and state.prompt4TargetCards[2]
  if not nativeBot or not nativeBotTarget or not nativeBotJink then
    fail("ai-trace Prompt 4 native BOT response fixture is missing")
  end
  -- Keep the exact native seats selected while the fixture is installed. A
  -- later replay must not rediscover them by seat/id ordering: the browser
  -- actor and native BOT ids are assigned by the live server and can differ
  -- between room constructions.
  state.prompt4NativeActor = nativeBot
  state.prompt4NativeTarget = nativeBotTarget
  -- The fourth seat is the actor's fixed Wu ally.  Keep it wounded so the
  -- native Jijiu strategy has a legal recovery opportunity without exposing
  -- any private card or general state in the trace.
  local ally = room.players[4]
  room:setPlayerProperty(ally, "hp", math.max(1, (ally.maxHp or 2) - 1))

  -- Aocai's real ViewAsSkill reads the first two draw-pile cards.  Put two
  -- semantic Basic cards on top after the normal deterministic tail shuffle;
  -- the selected identities remain outside all logs.
  local top = {}
  for _, id in ipairs(room.draw_pile or {}) do
    local ok, card = pcall(Fk.getCardById, Fk, id)
    if ok and card and card.type == Card.TypeBasic then
      table.insert(top, id)
      if #top == 2 then break end
    end
  end
  if #top ~= 2 then fail("ai-trace Prompt 4 fixture needs two Basic draw-pile cards") end
  for index, id in ipairs(top) do
    local position
    for candidate, current in ipairs(room.draw_pile) do
      if current == id then position = candidate; break end
    end
    if not position then fail("ai-trace Prompt 4 draw-pile fixture drift") end
    room.draw_pile[position], room.draw_pile[index] = room.draw_pile[index], room.draw_pile[position]
  end
  for _, id in ipairs(room.draw_pile) do room:setCardArea(id, Card.DrawPile, nil) end
  room:syncDrawPile()
  state.prompt4AocaiTop = { room.draw_pile[1], room.draw_pile[2] }
  state.prompt4FixturePrepared = true
end

-- Profile-specific native BOT resources are installed only after the full
-- eighteen-request legality/privacy matrix has been captured.  Adding them
-- before that point changes public hand counts and can make an unrelated
-- request (notably Dimeng) lose its deterministic opportunity.  The replay
-- itself still uses the same real native participants and cards.
local function preparePrompt4ReplayResources(room, state)
  if not prompt4EffectReplaySkill then return end
  local nativeBot = state.prompt4NativeActor
  local nativeBotTarget = state.prompt4NativeTarget
  if not nativeBot or not nativeBotTarget then
    fail("ai-trace Prompt 4 replay resources require two native BOTs")
  end
  local nativeBotJink = state.prompt4TargetCards and state.prompt4TargetCards[2]
  if not nativeBotJink then fail("ai-trace Prompt 4 native BOT Jink fixture is missing") end
  if prompt4EffectReplaySkill == "hs__wusheng" or
      prompt4EffectReplaySkill == "hs__luanji" then
    room:moveCardTo(nativeBotJink, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
  end
  local nativeBotLongdanJink = state.prompt4TargetCards and state.prompt4TargetCards[6]
  if prompt4EffectReplaySkill == "hs__wusheng" then
    if not nativeBotLongdanJink then fail("ai-trace Prompt 4 Wusheng Jink fixture is missing") end
    room:moveCardTo(nativeBotLongdanJink, Card.PlayerHand, nativeBotTarget,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBotTarget)
  elseif prompt4EffectReplaySkill == "hs__longdan" then
    if not nativeBotLongdanJink then fail("ai-trace Prompt 4 Longdan Jink fixture is missing") end
    room:moveCardTo(nativeBotLongdanJink, Card.PlayerHand, nativeBot,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBot)
    local targetFillerCards = nativeBotTarget:getCardIds(Player.Hand) or {}
    for _, id in ipairs(targetFillerCards) do
      room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, "tqs_qa", nil, false)
    end
  end
  if prompt4EffectReplaySkill == "hs__luanji" then
    if not nativeBotLongdanJink then fail("ai-trace Prompt 4 Luanji Jink fixture is missing") end
    local targetFillerCards = nativeBotTarget:getCardIds(Player.Hand) or {}
    for _, id in ipairs(targetFillerCards) do
      room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, "tqs_qa", nil, false)
    end
    room:moveCardTo(nativeBotLongdanJink, Card.PlayerHand, nativeBotTarget,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBotTarget)
  end
  local nativeBotTianyiHigh = state.prompt4TargetCards and state.prompt4TargetCards[3]
  local nativeBotTianyiLow = state.prompt4TargetCards and state.prompt4TargetCards[4]
  if not nativeBotTianyiHigh or not nativeBotTianyiLow then
    fail("ai-trace Prompt 4 Tianyi pindian fixture is missing")
  end
  if prompt4EffectReplaySkill == "tianyi" then
    room:moveCardTo(nativeBotTianyiHigh, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
    room:moveCardTo(nativeBotTianyiLow, Card.PlayerHand, nativeBotTarget,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBotTarget)
  end
  local nativeBotTiaoxinSlash = state.prompt4TargetCards and state.prompt4TargetCards[5]
  if not nativeBotTiaoxinSlash then
    fail("ai-trace Prompt 4 Tiaoxin Slash fixture is missing")
  end
  if prompt4EffectReplaySkill == "tiaoxin" then
    room:moveCardTo(nativeBotTiaoxinSlash, Card.PlayerHand, nativeBotTarget,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBotTarget)
  end
  local shangyiBlack = state.prompt4Cards.shangyi_black
  if not shangyiBlack then fail("ai-trace Prompt 4 Shangyi card fixture is missing") end
  if prompt4EffectReplaySkill == "shangyi" or prompt4EffectReplaySkill == "choufa" then
    room:moveCardTo(shangyiBlack, Card.PlayerHand, nativeBotTarget,
      fk.ReasonJustMove, "tqs_qa", nil, false, nativeBotTarget)
  end
  local nativeBotHuojiRedA = state.prompt4TargetCards and state.prompt4TargetCards[7]
  local nativeBotHuojiRedB = state.prompt4TargetCards and state.prompt4TargetCards[8]
  if prompt4EffectReplaySkill == "huoji" then
    if not nativeBotHuojiRedA or not nativeBotHuojiRedB then
      fail("ai-trace Prompt 4 Huoji same-suit fixture is missing")
    end
    room:moveCardTo(nativeBotHuojiRedA, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
    room:moveCardTo(nativeBotHuojiRedB, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
  end
  local nativeBotLuanjiBlackA = state.prompt4TargetCards and state.prompt4TargetCards[9]
  local nativeBotLuanjiBlackB = state.prompt4TargetCards and state.prompt4TargetCards[10]
  if prompt4EffectReplaySkill == "hs__luanji" then
    if not nativeBotLuanjiBlackA or not nativeBotLuanjiBlackB then
      fail("ai-trace Prompt 4 Luanji distinct-suit fixture is missing")
    end
    room:moveCardTo(nativeBotLuanjiBlackA, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
    room:moveCardTo(nativeBotLuanjiBlackB, Card.PlayerHand, nativeBot, fk.ReasonJustMove,
      "tqs_qa", nil, false, nativeBot)
  end
end

local installAiTrace

local function setupState(room, scenario, seed)
  assertRoomAllowed(room, scenario)
  local actor = table.find(room.players, function(player)
    return player.id > 0 and player._splayer:getScreenName() == allowedUsers[1]
  end) or table.find(room.players, function(player) return player.id > 0 end) or room.players[1]
  local target = table.find(room.players, function(player) return player.id ~= actor.id end) or room.players[2]
  if scenario.seatRosters then
    actor = room.players[1]
    target = room.players[2]
  end
  local state = {
    scenario = scenario.id,
    seed = seed,
    revision = manifest.sourceRevision,
    matrixRosterSet = scenario.matrixRosterSet or "fixed",
    matrixSeatPermutation = scenario.matrixSeatPermutation or "fixed",
    startedAt = now(),
    actor = actor,
    target = target,
    skillEffects = {},
    damageResults = {},
    cardEvents = {},
    skillMoves = {},
    damageEvents = {},
    drawEvents = {},
    kuangguBeforeHpChanged = false,
    kuangguDamage = false,
    liegongTargetSpecified = false,
    liegongDamage = false,
    jueqingPreDamage = false,
    hiddenEnyuanTargetConfirmed = false,
    hiddenEnyuanDrawCount = 0,
    hiddenEnyuanDrawCards = {},
    hiddenFuyinTargetConfirmed = false,
    hiddenFuyinNullified = false,
    hiddenJilixPending = false,
    hiddenEjueDamageCaused = false,
    hiddenDufuDamageCaused = false,
    hiddenJianzhiDamageCaused = false,
    hiddenZhimanDamageCaused = false,
    hiddenJilixTargetConfirmed = false,
    hiddenJilixDamageInflicted = 0,
    prompt4EffectReplay = nil,
  }
  if scenario.trigger == "ai-trace" then
    -- Keep the seed-resolved fixture with the room state. The public scenario
    -- id remains stable for the existing parser, while all native pair and
    -- semantic-hand checks use the exact catalog variant selected by seed.
    state.aiTraceScenario = scenario
  end
  if scenario.trigger == "general-pair-trace" or scenario.trigger == "general-pair-match" then
    state.generalPairTrace = room:getTag("__tqs_general_pair_trace")
    if type(state.generalPairTrace) ~= "table" then
      fail(scenario.id .. " did not capture an initial CustomDialog decision")
    end
  end
  if scenario.seatRosters then
    for seat, roster in ipairs(scenario.seatRosters) do
      attachGeneralPair(room, room.players[seat], roster)
    end
  elseif scenario.players then
    attachGeneralPair(room, state.actor, scenario.players.actor)
    attachGeneralPair(room, state.target, scenario.players.target)
  elseif scenario.general then
    attachGeneral(room, state.actor, scenario.general)
    if scenario.trigger == "founding" then
      room:setPlayerProperty(state.actor, "kingdom", "wild")
      state.actor.role = "wild"
      room:broadcastProperty(state.actor, "kingdom")
      room:broadcastProperty(state.actor, "role")
    end
  end
  setupCards(room, state, scenario)
  totalRuns = totalRuns + 1
  activeRooms[tostring(room)] = state
  room:setTag("tqs_qa", state)
  installAiTrace(room, state)
  fk.qInfo(string.format("[tqs_qa] scenario=%s seed=%u revision=%s players=%d",
    state.scenario, state.seed, state.revision, #room.players))
  return state
end

local function stateFor(room)
  return room:getTag("tqs_qa")
end

-- The ai-trace scenario is deliberately QA-only.  It records only bounded
-- fingerprints and reply shapes so baseline/candidate runs can be compared
-- without putting prompts, card ids, target ids, or private payloads in the
-- native log.  The production AI metrics remain the source of truth for the
-- fallback category; this wrapper only correlates each request with the
-- deterministic input snapshot that reached it.
local function aiTraceHash(value)
  local hash = 2166136261
  local text = tostring(value or "")
  for index = 1, #text do
    hash = ((hash ~ string.byte(text, index)) * 16777619) & 0xffffffff
  end
  return string.format("%08x", hash)
end

local function aiTraceStable(value, depth, seen)
  depth = depth or 0
  seen = seen or {}
  local kind = type(value)
  if kind == "nil" then return "nil" end
  if kind == "string" then return "s:" .. aiTraceHash(value) end
  if kind == "number" then return "n:" .. string.format("%.17g", value) end
  if kind == "boolean" then return value and "b:1" or "b:0" end
  if kind ~= "table" then return kind end
  if depth >= 4 then return "table:depth" end
  if seen[value] then return "table:cycle" end
  seen[value] = true
  local parts = {}
  for key, item in pairs(value) do
    local keyText = type(key) == "string" and ("s:" .. aiTraceHash(key)) or tostring(key)
    table.insert(parts, keyText .. "=" .. aiTraceStable(item, depth + 1, seen))
  end
  table.sort(parts)
  seen[value] = nil
  return "table{" .. table.concat(parts, ",") .. "}"
end

local function aiTraceCardShape(ids)
  local shapes = {}
  for _, id in ipairs(ids or {}) do
    local ok, card = pcall(Fk.getCardById, Fk, id)
    if ok and card then
      local colorOk, color = pcall(card.getColorString, card)
      local suitOk, suit = pcall(card.getSuitString, card)
      table.insert(shapes, table.concat({
        tostring(card.trueName or ""),
        colorOk and tostring(color or "") or "",
        suitOk and tostring(suit or "") or "",
        tostring(card.type or ""),
      }, ":"))
    end
  end
  table.sort(shapes)
  return aiTraceHash(table.concat(shapes, "|"))
end

local function aiTraceSeat(room, player)
  for seat, candidate in ipairs(room.players or {}) do
    if candidate == player then return seat end
  end
  return 0
end

local function aiTraceInputFingerprint(ai, normalizedData)
  local room = ai.room
  local player = ai.player
  local parts = {
    "command=" .. tostring(ai.command or ""),
    "data=" .. aiTraceHash(aiTraceStable(normalizedData or ai.data)),
  }
  for seat, candidate in ipairs(room and room.players or {}) do
    local hand = candidate:getCardIds(Player.Hand) or {}
    local equip = candidate:getCardIds(Player.Equip) or {}
    local generalOk, general = pcall(candidate.getMark, candidate, "__heg_general")
    local deputyOk, deputy = pcall(candidate.getMark, candidate, "__heg_deputy")
    local kingdomOk, kingdom = pcall(candidate.getMark, candidate, "__heg_kingdom")
    local privateHand = candidate == player and aiTraceCardShape(hand) or tostring(#hand)
    local slotShape = aiTraceHash(table.concat({
      generalOk and tostring(general or "") or "",
      deputyOk and tostring(deputy or "") or "",
      kingdomOk and tostring(kingdom or "") or "",
    }, ":"))
    table.insert(parts, table.concat({
      tostring(seat), tostring(candidate.hp or 0), tostring(candidate.maxHp or 0),
      tostring(candidate.dead and 1 or 0), tostring(candidate.role or ""),
      privateHand, tostring(#equip), aiTraceCardShape(equip), slotShape,
    }, ":"))
  end
  local events = room and room.logic and room.logic.all_game_events
  table.insert(parts, "events=" .. tostring(type(events) == "table" and #events or 0))
  return aiTraceHash(table.concat(parts, "|"))
end

local function aiTraceReplyShape(reply)
  if reply == nil then return "nil" end
  if type(reply) == "string" then
    if reply == "" or reply == "__cancel" then return "cancel" end
    return "string"
  end
  if type(reply) ~= "table" then return type(reply) end
  local card = reply.card
  local cardShape = type(card)
  if type(card) == "table" then
    cardShape = type(card.skill) == "string" and "skill" or "table"
  end
  return string.format("table/card=%s/targets=%d/special=%s/interaction=%s",
    cardShape, type(reply.targets) == "table" and #reply.targets or 0,
    reply.special_skill ~= nil and "1" or "0",
    reply.interaction_data ~= nil and "1" or "0")
end

-- Keep the next layer of native request evidence semantic-only.  Target IDs
-- and card IDs are runtime-private and differ between paired processes, so
-- expose only the bounded role class and resource shape of the reply.  These
-- fields are request-shape metadata, not a tactical quality score.
local function aiTraceReplyTargetProfile(room, actor, reply)
  if type(reply) ~= "table" or type(reply.targets) ~= "table" or #reply.targets == 0 then
    return "none"
  end
  local selfTarget, allyTarget, enemyTarget = false, false, false
  local ally = room and room.players and room.players[4]
  for _, value in ipairs(reply.targets) do
    local target
    if type(value) == "table" then
      for _, candidate in ipairs(room.players or {}) do
        if candidate == value then target = candidate break end
      end
    elseif type(value) == "number" then
      for _, candidate in ipairs(room.players or {}) do
        if candidate.id == value then target = candidate break end
      end
    end
    if not target then return "unknown" end
    if target == actor then
      selfTarget = true
    elseif target == ally then
      allyTarget = true
    else
      enemyTarget = true
    end
  end
  local classes = 0
  if selfTarget then classes = classes + 1 end
  if allyTarget then classes = classes + 1 end
  if enemyTarget then classes = classes + 1 end
  if classes > 1 then return "mixed" end
  if selfTarget then return "self" end
  if allyTarget then return "ally" end
  if enemyTarget then return "enemy" end
  return "unknown"
end

local function aiTraceReplyCardProfile(reply)
  local card = type(reply) == "table" and reply.card or nil
  if card == nil then return "none" end
  if type(card) == "number" then return "physical" end
  if type(card) ~= "table" then return "unknown" end
  if type(card.skill) == "string" then return "skill" end
  return "table"
end

local function aiTraceReplyResourceShape(reply)
  local card = type(reply) == "table" and reply.card or nil
  if card == nil then return "none" end
  local count
  if type(card) == "number" then
    count = 1
  elseif type(card) == "table" and type(card.subcards) == "table" then
    count = #card.subcards
  else
    return "unknown"
  end
  if count == 0 then return "none" end
  if count == 1 then return "one_card" end
  if count == 2 then return "two_cards" end
  return "many_cards"
end

-- Expose only a coarse AI keep-value bucket for the resources actually chosen
-- by the reply.  This is a valuation snapshot, not a tactical score or a
-- downstream effect assertion; exact card ids and numeric values stay private.
local function aiTraceReplyResourceValue(actor, reply)
  local card = type(reply) == "table" and reply.card or nil
  local ids = {}
  if type(card) == "number" then
    table.insert(ids, card)
  elseif type(card) == "table" and type(card.subcards) == "table" then
    for _, id in ipairs(card.subcards) do
      if type(id) ~= "number" then return "unknown" end
      table.insert(ids, id)
    end
  elseif card ~= nil then
    return "unknown"
  end
  if #ids == 0 then return "none" end

  local total = 0
  for _, id in ipairs(ids) do
    local ok, value = pcall(actor.ai.getCardValue, actor.ai, id, "keep_value")
    if not ok or type(value) ~= "number" or value ~= value or
        value == math.huge or value == -math.huge then
      return "unknown"
    end
    total = total + value
  end
  -- The existing skill policies use 45 as their keep-value cutoff. Reuse
  -- that bounded semantic scale without serializing the underlying score.
  if total <= 30 then return "low" end
  if total <= 45 then return "medium" end
  return "high"
end

local function aiTraceReplyCardCount(reply)
  local card = type(reply) == "table" and reply.card or nil
  if type(card) == "number" then return 1 end
  if type(card) == "table" and type(card.subcards) == "table" then
    return #card.subcards
  end
  return 0
end

local function aiTraceReplyTargetCount(reply)
  return type(reply) == "table" and type(reply.targets) == "table" and #reply.targets or 0
end

-- The expected target role is part of the bounded QA fixture, not a claim
-- about every legal native state.  It lets the parser distinguish a strategy
-- that acted on the intended role from a merely legal reply, while keeping
-- target IDs and private player state out of the log.
local function aiTraceTargetQuality(targetProfile, expectedProfile, acted)
  if expectedProfile == nil then return "not_applicable" end
  if not acted then return "no_action" end
  return targetProfile == expectedProfile and "expected" or "unexpected"
end

local function aiTraceToken(value)
  local token = tostring(value or "unknown"):gsub("[^%w_%-]", "_")
  return token == "" and "unknown" or token:sub(1, 64)
end

local function recordAiTrace(state, ai, input, reply, reason, detail, skill)
  local trace = state.aiTrace
  if not trace or trace.capture == false or trace.overflow then return end
  trace.total = trace.total + 1
  local safeReason = aiTraceToken(reason or "accepted")
  local entry = {
    seq = trace.total,
    seat = aiTraceSeat(ai.room, ai.player),
    command = aiTraceToken(ai.command),
    skill = aiTraceToken(skill or "unknown"),
    input = input,
    output = aiTraceReplyShape(reply),
    reason = safeReason,
    detail = aiTraceToken(detail or "none"),
  }
  if #trace.decisions >= trace.maxDecisions then
    trace.overflow = true
    return
  end
  table.insert(trace.decisions, entry)
  trace.reasons[safeReason] = (trace.reasons[safeReason] or 0) + 1
  if safeReason ~= "accepted" then trace.fallback = trace.fallback + 1 end
end

local function aiTraceFallbackCount(ai, command)
  local room = ai.room
  local metrics = room and room:getTag("__ai_response_metrics")
  local commandMetrics = metrics and metrics.by_command and metrics.by_command[command]
  return commandMetrics and tonumber(commandMetrics.fallback or 0) or 0
end

-- The native request counter joins skill/reason only in QA. Emit the joined
-- categories and recovered strategy-shape failures before room cleanup, with
-- no raw hands, prompts, card/target IDs or unallowlisted skill names.
local function emitPrompt4Provenance(room, state)
  if state.prompt4ProvenanceEmitted then return end
  state.prompt4ProvenanceEmitted = true
  local requestReasons = room:getTag("__tqs_prompt4_request_reasons") or {}
  local strategyIssues = room:getTag("__tqs_prompt4_strategy_issues") or {}
  local entries = {}
  for skill, bucket in pairs(requestReasons) do
    for reason, count in pairs(bucket) do
      entries[#entries + 1] = string.format("request skill=%s category=%s count=%d",
        skill, reason, count)
    end
  end
  for skill, bucket in pairs(strategyIssues) do
    entries[#entries + 1] = string.format("strategy skill=%s total=%d recovered=%d unrecovered=%d",
      skill, bucket.total, bucket.recovered, bucket.unrecovered)
  end
  table.sort(entries)
  local limit = math.min(#entries, 256)
  fk.qInfo(string.format("[tqs_prompt4_provenance] summary scenario=%s seed=%u entries=%d overflow=%d",
    state.scenario, state.seed, limit, #entries > limit and 1 or 0))
  for index = 1, limit do
    fk.qInfo(string.format("[tqs_prompt4_provenance] %s", entries[index]))
  end
end

installAiTrace = function(room, state)
  local scenario = scenarioById[state.scenario]
  if not scenario or scenario.trigger ~= "ai-trace" then return end
  state.aiTrace = {
    decisions = {},
    maxDecisions = 4096,
    total = 0,
    fallback = 0,
    probeErrors = 0,
    overflow = false,
    emitted = false,
    reasons = {},
  }
  for _, player in ipairs(room.players or {}) do
    local ai = player.ai
    if ai and type(ai.makeReply) == "function" and not ai.__tqs_qa_ai_trace then
      local originalMakeReply = ai.makeReply
      ai.__tqs_qa_ai_trace = true
      ai.makeReply = function(self)
        local input = "unavailable"
        local beforeFallback = 0
        pcall(function()
          input = aiTraceInputFingerprint(self)
          beforeFallback = aiTraceFallbackCount(self, aiTraceToken(self.command))
        end)
        local ok, value = xpcall(function()
          return originalMakeReply(self)
        end, function(err)
          return err
        end)
        if not ok then
          pcall(recordAiTrace, state, self, input, nil, "ai_exception", "none", "unknown")
          error(value, 0)
        end
        local reason = "accepted"
        local detail = "none"
        local skill = "unknown"
        pcall(function()
          local command = aiTraceToken(self.command)
          local metrics = self.room:getTag("__ai_response_metrics")
          local commandMetrics = metrics and metrics.by_command and metrics.by_command[command]
          if aiTraceFallbackCount(self, command) > beforeFallback then
            reason = self._ai_last_metric_reason or
              (commandMetrics and commandMetrics.last_reason) or self._ai_fallback_reason or "fallback"
            detail = self._ai_last_metric_detail or self._ai_validation_detail or "none"
          end
          skill = self._ai_last_metric_skill or self._ai_metric_skill or "unknown"
        end)
        pcall(recordAiTrace, state, self, input, value, reason, detail, skill)
        return value
      end
    end
  end
end

local function emitAiTrace(state)
  local trace = state.aiTrace
  if not trace or trace.emitted then return end
  trace.emitted = true
  local reasons = {}
  for reason, count in pairs(trace.reasons) do
    table.insert(reasons, reason .. ":" .. tostring(count))
  end
  table.sort(reasons)
  fk.qInfo(string.format("[tqs_ai_trace] summary scenario=%s seed=%u revision=%s decisions=%d fallback=%d probe_errors=%d overflow=%s reasons=%s pair=%s hands=%s fixture=semantic_v3",
    state.scenario, state.seed, state.revision, trace.total, trace.fallback,
    trace.probeErrors or 0, tostring(trace.overflow), table.concat(reasons, ","),
    trace.pairVerified and "verified" or "unverified",
    trace.fixedHandsVerified and "verified" or "unverified"))
  for _, entry in ipairs(trace.decisions) do
    fk.qInfo(string.format("[tqs_ai_trace] decision scenario=%s seed=%u revision=%s seq=%d seat=%d command=%s skill=%s input=%s output=%s reason=%s detail=%s",
      state.scenario, state.seed, state.revision, entry.seq, entry.seat, entry.command,
      entry.skill, entry.input, entry.output, entry.reason, entry.detail))
  end
end

-- Six independent QA requests. The server's actual AI request handler does
-- the feasibility/legality check inside player.ai:makeReply(); the count of
-- enabled cards/targets below is an additional observed opportunity measure.
-- No raw request, hand, general, card ID or target ID enters the trace.
local function runChooserTraceProbe(room, state)
  local scenario = state.aiTraceScenario or scenarioById[state.scenario]
  if not scenario or #room.players ~= 4 or #scenario.cases ~= 6 then
    fail("chooser-trace fixture count drift")
  end
  local seen = {}
  for seat, player in ipairs(room.players) do
    local expected = scenario.seatRosters[seat]
    if player.general ~= expected.general or player.deputyGeneral ~= expected.deputy or
        player:getMark("__heg_general") ~= expected.general or
        player:getMark("__heg_deputy") ~= expected.deputy or
        player:getMark("__heg_kingdom") ~= expected.kingdom then
      fail("chooser-trace native seat pair drift")
    end
    local fixed = state.fixedHands and state.fixedHands[player.id]
    local actual = player:getCardIds(Player.Hand) or {}
    if type(fixed) ~= "table" or #fixed ~= 1 or #actual ~= 1 or
        fixed[1] ~= actual[1] or seen[actual[1]] then
      fail("chooser-trace fixed native hand drift")
    end
    seen[actual[1]] = true
    local card = Fk:getCardById(actual[1])
    if not card or not cardMatches(card, scenario.fixedHands[seat]) then
      fail("chooser-trace fixed native hand semantic drift")
    end
  end
  local actor = room.players[1]
  local ai = actor.ai
  if not ai or type(ai.makeReply) ~= "function" then
    fail("chooser-trace native actor AI missing")
  end
  local targets = {}
  for seat = 2, 4 do table.insert(targets, room.players[seat].id) end
  local originalCommand, originalData = ai.command, ai.data
  local decisions, missed, accepted, invalid, fallback, errors = {}, 0, 0, 0, 0, 0
  for index, spec in ipairs(scenario.cases) do
    local skill = Fk.skills[spec.skill]
    if not skill then fail("chooser-trace pinned skill missing") end
    local mandatory = spec.variant == "mandatory"
    local min = mandatory and 1 or 0
    local extra = { skillName = spec.skill, pattern = spec.skill == "choose_players_skill" and "" or "." }
    if spec.skill == "choose_players_skill" then
      extra.targets, extra.num, extra.min_num = targets, 1, min
    elseif spec.skill == "choose_cards_skill" then
      extra.num, extra.min_num, extra.include_equip = 1, min, false
    else
      extra.targets, extra.max_t_num, extra.min_t_num = targets, 1, min
      extra.max_c_num, extra.min_c_num = 1, min
      extra.equal, extra.will_throw = true, false
    end
    local data = { spec.skill, "TQS QA generic chooser", not mandatory, extra }
    ai.command, ai.data = "AskForUseActiveSkill", data
    -- Native player IDs are assigned independently per runtime. They are
    -- request targets, but must be represented as fixed room seats in the
    -- cross-runtime fingerprint; otherwise equal offers falsely mismatch.
    -- Keep all other active skill flags/limits and the actual room snapshot.
    local comparableExtra = {}
    for key, value in pairs(extra) do comparableExtra[key] = value end
    if extra.targets then
      comparableExtra.targets = {}
      for _, targetId in ipairs(extra.targets) do
        local targetSeat
        for seat, player in ipairs(room.players) do
          if player.id == targetId then targetSeat = seat; break end
        end
        if not targetSeat then fail("chooser-trace unknown native target seat") end
        table.insert(comparableExtra.targets, targetSeat)
      end
    end
    local input = aiTraceInputFingerprint(ai,
      { spec.skill, "TQS QA generic chooser", not mandatory, comparableExtra })
    local opportunityHash = aiTraceHash(table.concat({
      spec.skill, spec.variant, tostring(#targets),
      aiTraceCardShape(actor:getCardIds(Player.Hand)),
      aiTraceHash(aiTraceStable(scenario.seatRosters)),
    }, "|"))
    -- Same generic-skill dynamic _extra_data used by the native AI wrapper.
    -- Probe the real skill filters with empty selections before makeReply.
    local previousExtra = skill._extra_data
    skill._extra_data = extra
    local legalOk, cardOffers, targetOffers = pcall(function()
      local c, t = 0, 0
      if spec.skill ~= "choose_players_skill" then
        for _, cid in ipairs(actor:getCardIds(Player.Hand) or {}) do
          if skill:cardFilter(actor, cid, {}, {}) then c = c + 1 end
        end
      end
      if spec.skill ~= "choose_cards_skill" then
        for seat = 2, 4 do
          if skill:targetFilter(actor, room.players[seat], {}, {}) then t = t + 1 end
        end
      end
      return c, t
    end)
    skill._extra_data = previousExtra or Util.DummyTable
    if not legalOk then fail("chooser-trace native offer filter error") end
    local opportunity = (spec.skill == "choose_players_skill" and targetOffers > 0)
      or (spec.skill == "choose_cards_skill" and cardOffers > 0)
      or (cardOffers > 0 and targetOffers > 0)
    if not opportunity then fail("chooser-trace has no actionable legal offers") end

    local metrics = room:getTag("__ai_response_metrics")
    local bucket = metrics and metrics.by_command and metrics.by_command.AskForUseActiveSkill
    local beforeTotal = bucket and bucket.total or 0
    local beforeFallback = bucket and bucket.fallback or 0
    local beforeInvalid = bucket and bucket.invalid or 0
    local ok, reply = xpcall(function() return ai:makeReply() end, function() return true end)
    metrics = room:getTag("__ai_response_metrics")
    bucket = metrics and metrics.by_command and metrics.by_command.AskForUseActiveSkill
    local totalDelta = (bucket and bucket.total or 0) - beforeTotal
    local fallbackDelta = (bucket and bucket.fallback or 0) - beforeFallback
    local invalidDelta = (bucket and bucket.invalid or 0) - beforeInvalid
    if not ok or totalDelta ~= 1 or fallbackDelta < 0 or fallbackDelta > 1 or
        invalidDelta < 0 or invalidDelta > 1 then
      errors = errors + 1
      ai.command, ai.data = originalCommand, originalData
      fail("chooser-trace native makeReply/metrics integrity failure")
    end
    local isAccepted = fallbackDelta == 0 and type(reply) == "table"
    if fallbackDelta == 0 and not isAccepted then
      errors = errors + 1
      fail("chooser-trace missing accepted native reply")
    end
    local chosenCards = isAccepted and type(reply.card) == "table" and
      type(reply.card.subcards) == "table" and #reply.card.subcards or 0
    local chosenTargets = isAccepted and type(reply.targets) == "table" and #reply.targets or 0
    -- Native feasibility can accept an optional empty selection.  Count that
    -- as accepted but an unexercised opportunity, never as a request fallback.
    local acted = isAccepted and ((spec.skill == "choose_players_skill" and chosenTargets > 0)
      or (spec.skill == "choose_cards_skill" and chosenCards > 0)
      or (chosenCards > 0 and chosenTargets > 0)) or false
    local reason = fallbackDelta == 1 and
      aiTraceToken(bucket.last_reason or ai._ai_fallback_reason or "fallback") or "accepted"
    local detail = fallbackDelta == 1 and aiTraceToken(ai._ai_validation_detail or "none") or "none"
    if invalidDelta > 0 then invalid = invalid + 1 end
    if fallbackDelta > 0 then fallback = fallback + 1 end
    if isAccepted then accepted = accepted + 1 end
    if not acted then missed = missed + 1 end
    decisions[#decisions + 1] = {
      skill = spec.skill, variant = spec.variant, input = input, offer = opportunityHash,
      cards = cardOffers, targets = targetOffers, chosenCards = chosenCards,
      chosenTargets = chosenTargets, accepted = isAccepted, acted = acted, reason = reason,
      detail = detail, invalid = invalidDelta,
    }
  end
  ai.command, ai.data = originalCommand, originalData
  fk.qInfo(string.format("[tqs_chooser_trace] summary scenario=%s seed=%u revision=%s decisions=6 opportunities=6 accepted=%d missed=%d fallback=%d invalid=%d errors=%d pair=verified hands=verified fixture=semantic_v1",
    state.scenario, state.seed, state.revision, accepted, missed, fallback, invalid, errors))
  for index, entry in ipairs(decisions) do
    fk.qInfo(string.format("[tqs_chooser_trace] decision scenario=%s seed=%u revision=%s seq=%d skill=%s variant=%s input=%s offer=%s opportunity=1 offered_cards=%d offered_targets=%d accepted=%d acted=%d chosen_cards=%d chosen_targets=%d invalid=%d reason=%s detail=%s",
      state.scenario, state.seed, state.revision, index, entry.skill, entry.variant,
      entry.input, entry.offer, entry.cards, entry.targets, entry.accepted and 1 or 0,
      entry.acted and 1 or 0, entry.chosenCards, entry.chosenTargets, entry.invalid, entry.reason, entry.detail))
  end
end

-- Initial general selection happens before GamePrepared, so the ordinary
-- per-room ai-trace wrapper cannot observe it. Keep a second, package-level
-- wrapper narrowly gated by the validated general-pair QA room name.
local function generalPairTraceReplyShape(reply)
  if reply == nil then return "nil" end
  if reply == "__cancel" then return "cancel" end
  if type(reply) == "table" and #reply == 2 then return "pair" end
  return type(reply)
end

local function generalPairTraceFallbackCount(room)
  local metrics = room and room:getTag("__ai_response_metrics")
  local commandMetrics = metrics and metrics.by_command and metrics.by_command.CustomDialog
  return commandMetrics and tonumber(commandMetrics.fallback or 0) or 0
end

local function recordGeneralPairTrace(room, ai, data, reply, reason, detail, elapsedMs, valid)
  local trace = room:getTag("__tqs_general_pair_trace")
  if type(trace) ~= "table" then
    trace = {
      decisions = {},
      total = 0,
      accepted = 0,
      fallback = 0,
      invalid = 0,
      overflow = false,
      emitted = false,
      reasons = {},
      outputs = {},
      maxDecisions = 64,
    }
    room:setTag("__tqs_general_pair_trace", trace)
  end
  trace.total = trace.total + 1
  local safeReason = aiTraceToken(reason or "accepted")
  local outputShape = generalPairTraceReplyShape(reply)
  local outputHash = aiTraceHash(aiTraceStable(reply))
  local entry = {
    seq = trace.total,
    seat = aiTraceSeat(room, ai.player),
    input = aiTraceHash(aiTraceStable(data)),
    output = outputShape,
    outputHash = outputHash,
    valid = valid == true,
    reason = safeReason,
    detail = aiTraceToken(detail or "none"),
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0),
  }
  if trace.total > trace.maxDecisions then
    trace.overflow = true
    return
  end
  table.insert(trace.decisions, entry)
  if entry.valid then trace.accepted = trace.accepted + 1 end
  if safeReason ~= "accepted" then trace.fallback = trace.fallback + 1 end
  if not entry.valid then trace.invalid = trace.invalid + 1 end
  trace.reasons[safeReason] = (trace.reasons[safeReason] or 0) + 1
  trace.outputs[outputHash] = (trace.outputs[outputHash] or 0) + 1
end

local function installGeneralPairTraceHooks()
  -- freekill.lua loads this server-only package before the native scheduler
  -- executes ltk/server/ai/init.lua. Load that same pinned module now so the
  -- SmartAI class is available before the first Hegemony CustomDialog.
  if not SmartAI and type(dofile) == "function" then
    pcall(dofile, "ltk/server/ai/init.lua")
  end
  local RoomClass = Room
  if not RoomClass then
    local roomOk, loadedRoom = pcall(require, "ltk.server.room")
    if roomOk then RoomClass = loadedRoom end
  end
  -- The catalog contract test loads this file with a deliberately minimal
  -- Lua harness and no engine modules. Native startup has Room/SmartAI
  -- already loaded; the standalone harness must remain loadable as well.
  if not RoomClass or type(RoomClass.askToChooseIniticalGeneral) ~= "function" then
    return
  end
  if not RoomClass.__tqs_qa_general_pair_trace_hook then
    local originalChoose = RoomClass.askToChooseIniticalGeneral
    RoomClass.__tqs_qa_general_pair_trace_hook = true
    RoomClass.askToChooseIniticalGeneral = function(self, player, params)
      local scenario = generalPairTraceScenarioForRoom(self)
      if scenario and type(params) == "table" and params.isHeg then
        local targets = params.targets
        local targetCount = type(targets) == "table" and targets.id and 1 or #targets
        if targetCount ~= scenario.playerCount then
          fail("general-pair-trace received an unexpected target count")
        end
        local offered = {}
        for seat = 1, targetCount do
          for _, name in ipairs(scenario.offeredGroups[seat]) do
            table.insert(offered, name)
          end
        end
        params.generals = offered
        params.enabledKingdoms = table.simpleClone(scenario.enabledKingdoms)
        local offerCount = #scenario.offeredGroups[1]
        local seatTokens = {}
        for seat = 1, targetCount do table.insert(seatTokens, tostring(seat)) end
        self:sendLog{
          type = "[TQS QA] PairOfferSummary scenario=%arg roster_set=%arg2 seat_swap=%arg3 offer_count=%arg4 seat_count=%arg5 seats=%arg6",
          arg = scenario.id,
          arg2 = aiTraceToken(scenario.matrixRosterSet or "fixed"),
          arg3 = aiTraceToken(scenario.matrixSeatPermutation or "fixed"),
          arg4 = tostring(offerCount),
          arg5 = tostring(targetCount),
          arg6 = table.concat(seatTokens, ","),
        }
      end
      return originalChoose(self, player, params)
    end
  end

  local SmartAIClass = SmartAI
  if not SmartAIClass then
    local aiOk, loadedAi = pcall(require, "ltk.server.ai.smart_ai")
    if aiOk then SmartAIClass = loadedAi end
  end
  if not SmartAIClass or type(SmartAIClass.makeReply) ~= "function" then
    fail("native SmartAI class is unavailable for general-pair QA")
  end
  local GeneralPair = dofile "qa_packages/tqs_qa/ltk/server/ai/general_pair.lua"
  -- The release runtime may carry an older public SmartAI without the
  -- initial Hegemony CustomDialog handler. Install only this QA handler on
  -- that already-loaded class; reloading the complete SmartAI class would
  -- duplicate its strategy registrations and can fail during startup.
  SmartAIClass.handleCustomDialog = function(self, data)
    local reply = GeneralPair.choose(data)
    if not reply then
      if self.markFallback then self:markFallback("no_decision") end
      return nil
    end
    return reply
  end
  if not SmartAIClass.__tqs_qa_general_pair_trace_hook then
    local originalMakeReply = SmartAIClass.makeReply
    -- The A/B general-pair implementation is part of the isolated QA tree,
    -- not the public flist. Loading it by its QA-relative path keeps the
    -- runtime-only module out of the client MD5 while still letting baseline
    -- and candidate use different implementations.
    SmartAIClass.__tqs_qa_general_pair_trace_hook = true
    SmartAIClass.makeReply = function(self)
      local scenario = self.room and generalPairTraceScenarioForRoom(self.room)
      if not scenario or self.command ~= "CustomDialog" then
        return originalMakeReply(self)
      end

      local room = self.room
      local data = self.data
      local beforeFallback = generalPairTraceFallbackCount(room)
      local started = os.getms()
      local ok, reply = xpcall(function()
        -- Older pinned public Base.AI builds validate unknown commands as a
        -- string and therefore reject the legal two-item table used by the
        -- initial Hegemony CustomDialog. The QA handler validates against the
        -- same native offer first, then returns it directly; every other
        -- command continues through the pinned public makeReply path.
        if self.command == "CustomDialog" then
          local directReply = self:handleCustomDialog(data)
          local directValid = false
          pcall(function()
            directValid = GeneralPair.validate(data, directReply) == true
          end)
          if directValid then return directReply end
        end
        return originalMakeReply(self)
      end, function(err)
        return err
      end)
      local elapsedMs = (os.getms() - started) / 1000
      if not ok then
        recordGeneralPairTrace(room, self, data, nil, "ai_exception", "none", elapsedMs, false)
        error(reply, 0)
      end

      local reason = self._ai_fallback_reason
      local detail = self._ai_validation_detail
      local metrics = room:getTag("__ai_response_metrics")
      local commandMetrics = metrics and metrics.by_command and metrics.by_command.CustomDialog
      if generalPairTraceFallbackCount(room) > beforeFallback then
        reason = (commandMetrics and commandMetrics.last_reason) or reason or "fallback"
        detail = detail or "none"
      end
      reason = reason or "accepted"
      local valid = false
      pcall(function()
        valid = GeneralPair.validate(data, reply) == true
      end)
      recordGeneralPairTrace(room, self, data, reply, reason, detail, elapsedMs, valid)
      return reply
    end
  end
end

local function emitGeneralPairTrace(state)
  local trace = state.generalPairTrace
  if not trace or trace.emitted then return end
  trace.emitted = true
  local reasons = {}
  for reason, count in pairs(trace.reasons or {}) do
    table.insert(reasons, reason .. ":" .. tostring(count))
  end
  table.sort(reasons)
  local latency = {}
  local latencySum = 0
  for _, entry in ipairs(trace.decisions or {}) do
    local value = math.max(0, tonumber(entry.elapsedMs) or 0)
    table.insert(latency, value)
    latencySum = latencySum + value
  end
  table.sort(latency)
  local function percentile(p)
    if #latency == 0 then return 0 end
    local index = math.max(1, math.min(#latency, math.ceil(#latency * p)))
    return latency[index]
  end
  local traceParts = {}
  for _, entry in ipairs(trace.decisions or {}) do
    table.insert(traceParts, table.concat({
      tostring(entry.seq), tostring(entry.seat), tostring(entry.input),
      tostring(entry.outputHash), tostring(entry.valid), tostring(entry.reason),
      tostring(entry.detail), string.format("%.6f", tonumber(entry.elapsedMs) or 0),
    }, ":"))
  end
  local traceHash = aiTraceHash(table.concat(traceParts, "|"))
  fk.qInfo(string.format(
    "[tqs_general_pair_trace] summary scenario=%s seed=%u revision=%s decisions=%d accepted=%d fallback=%d invalid=%d overflow=%s reasons=%s",
    state.scenario, state.seed, state.revision, trace.total or 0, trace.accepted or 0,
    trace.fallback or 0, trace.invalid or 0, tostring(trace.overflow), table.concat(reasons, ",")))
  -- This is deliberately a public, metadata-only QA log. It contains no
  -- prompt, card id, general name, account name or private hand data, so the
  -- browser can persist the same bounded telemetry that is otherwise only in
  -- the native process log. The batch analyzer uses it to pair baseline and
  -- candidate runs without scraping raw server output.
  local matrixRosterSet = state.matrixRosterSet or "fixed"
  local matrixSeatPermutation = state.matrixSeatPermutation or "fixed"
  state.actor.room:sendLog{
    type = "[TQS QA] PairDecisionSummary scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 decisions=%arg5 accepted=%arg6 fallback=%arg7 invalid=%arg8 overflow=%arg9",
    arg = state.scenario,
    arg2 = tostring(state.seed),
    arg3 = aiTraceToken(matrixRosterSet),
    arg4 = aiTraceToken(matrixSeatPermutation),
    arg5 = tostring(trace.total or 0),
    arg6 = tostring(trace.accepted or 0),
    arg7 = tostring(trace.fallback or 0),
    arg8 = tostring(trace.invalid or 0),
    arg9 = tostring(trace.overflow),
  }
  state.actor.room:sendLog{
    type = "[TQS QA] PairDecisionStats scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 latency_n=%arg5 latency_sum_ms=%arg6 latency_min_ms=%arg7 latency_p50_ms=%arg8 latency_p95_ms=%arg9",
    arg = state.scenario,
    arg2 = tostring(state.seed),
    arg3 = aiTraceToken(matrixRosterSet),
    arg4 = aiTraceToken(matrixSeatPermutation),
    arg5 = tostring(#latency),
    arg6 = string.format("%.6f", latencySum),
    arg7 = string.format("%.6f", #latency > 0 and latency[1] or 0),
    arg8 = string.format("%.6f", percentile(0.50)),
    arg9 = string.format("%.6f", percentile(0.95)),
  }
  state.actor.room:sendLog{
    type = "[TQS QA] PairDecisionTrace scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 latency_max_ms=%arg5 trace_hash=%arg6 reasons=%arg7",
    arg = state.scenario,
    arg2 = tostring(state.seed),
    arg3 = aiTraceToken(matrixRosterSet),
    arg4 = aiTraceToken(matrixSeatPermutation),
    arg5 = string.format("%.6f", #latency > 0 and latency[#latency] or 0),
    arg6 = traceHash,
    arg7 = table.concat(reasons, ","),
  }
  for _, entry in ipairs(trace.decisions or {}) do
    fk.qInfo(string.format(
      "[tqs_general_pair_trace] decision scenario=%s seed=%u revision=%s seq=%d seat=%d input=%s output=%s output_hash=%s valid=%s reason=%s detail=%s elapsed_ms=%.3f",
      state.scenario, state.seed, state.revision, entry.seq, entry.seat, entry.input,
      entry.output, entry.outputHash, tostring(entry.valid), entry.reason, entry.detail,
      entry.elapsedMs))
    state.actor.room:sendLog{
      type = "[TQS QA] PairDecision scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 seq=%arg5 seat=%arg6 input=%arg7 output_hash=%arg8 valid=%arg9",
      arg = state.scenario,
      arg2 = tostring(state.seed),
      arg3 = aiTraceToken(matrixRosterSet),
      arg4 = aiTraceToken(matrixSeatPermutation),
      arg5 = tostring(entry.seq),
      arg6 = tostring(entry.seat),
      arg7 = aiTraceToken(entry.input),
      arg8 = aiTraceToken(entry.outputHash),
      arg9 = tostring(entry.valid),
    }
    state.actor.room:sendLog{
      type = "[TQS QA] PairDecisionMeta scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 seq=%arg5 reason=%arg6 detail=%arg7 elapsed_ms=%arg8",
      arg = state.scenario,
      arg2 = tostring(state.seed),
      arg3 = aiTraceToken(matrixRosterSet),
      arg4 = aiTraceToken(matrixSeatPermutation),
      arg5 = tostring(entry.seq),
      arg6 = aiTraceToken(entry.reason),
      arg7 = aiTraceToken(entry.detail),
      arg8 = string.format("%.6f", tonumber(entry.elapsedMs) or 0),
    }
  end
end

-- Full-match runs need a result that can be joined to the fixed seat roster,
-- but must not publish names, roles, generals or any other private payload.
-- GameFinished receives the native winner player objects before the room is
-- torn down, so convert them to one-based seat numbers only.
local function emitGeneralPairMatchResult(state, data)
  if not state or not state.scenario:match("^general%-pair%-match%-") or
      state.generalPairMatchResultEmitted then
    return
  end
  local room = state.actor and state.actor.room
  if not room then return end
  local winners = type(data) == "table" and data.players or nil
  local winnerIds = {}
  if type(winners) == "table" then
    for _, winner in ipairs(winners) do
      if winner and winner.id then winnerIds[winner.id] = true end
    end
  end
  local winnerSeats = {}
  for seat, player in ipairs(room.players) do
    if winnerIds[player.id] then table.insert(winnerSeats, seat) end
  end
  table.sort(winnerSeats)
  local winnerKingdoms = {}
  for _, seat in ipairs(winnerSeats) do
    local winner = room.players[seat]
    local kingdom = winner and (winner.role or winner.kingdom) or "unknown"
    table.insert(winnerKingdoms, tostring(seat) .. ":" .. aiTraceToken(kingdom))
  end
  state.generalPairMatchResultEmitted = true
  room:sendLog{
    type = "[TQS QA] PairMatchResult scenario=%arg seed=%arg2 roster_set=%arg3 seat_swap=%arg4 winner_seats=%arg5 winner_kingdoms=%arg6 winner_count=%arg7 outcome=%arg8",
    arg = state.scenario,
    arg2 = tostring(state.seed),
    arg3 = aiTraceToken(state.matrixRosterSet or "fixed"),
    arg4 = aiTraceToken(state.matrixSeatPermutation or "fixed"),
    arg5 = #winnerSeats > 0 and table.concat(winnerSeats, ",") or "draw",
    arg6 = #winnerKingdoms > 0 and table.concat(winnerKingdoms, ",") or "draw",
    arg7 = tostring(#winnerSeats),
    arg8 = #winnerSeats > 0 and "win" or "draw",
  }
  fk.qInfo(string.format(
    "[tqs_general_pair_match] result scenario=%s seed=%u revision=%s winner_seats=%s winner_count=%d outcome=%s",
    state.scenario, state.seed, state.revision,
    #winnerSeats > 0 and table.concat(winnerSeats, ",") or "draw",
    #winnerSeats, #winnerSeats > 0 and "win" or "draw"))
end

installGeneralPairTraceHooks()

local function triggerRescue(room, state)
  local scenario = scenarioById[state.scenario]
  if scenario.trigger == "rescue-battle" then
    local hegUtil = require "packages.hegemony.util"
    hegUtil.enterBattleRoyalMode(room)
  end
  -- This is the native Dying -> AskForPeaches path. The actor's fixed peach
  -- is offered by game_rule to the same client/bot as in a normal match.
  if state.target.hp > 0 then
    room:changeHp(state.target, -state.target.hp, "loseHp", "tqs_qa")
  end
end

local function triggerFounding(room, state)
  -- The Hegemony GeneralShown rule owns the actual AskForChoice request.
  if state.actor:getMark("__heg_wild") == 1 then
    state.actor:revealGeneral(false)
  end
end

local function actualSkillName(skill)
  local skeleton = skill:getSkeleton()
  return skeleton and skeleton.name or skill.name
end

local function isPrelighted(player, skillName)
  return table.find(player.prelighted_skills, function(skill)
    return actualSkillName(skill) == skillName
  end) ~= nil
end

-- A deferred hidden-skill gate can run while the browser is still finishing
-- the preceding phase transition.  Keep the native request type and reply
-- semantics, but give this QA-only synchronization gate a bounded 60-second
-- window so the request is not cancelled before the real client can answer.
local function askQaSkillInvoke(room, player, params)
  local req = Request:new(player, "AskForSkillInvoke")
  req.timeout = math.max(tonumber(room.timeout) or 0, 60)
  req.focus_text = params.skill_name
  req.receive_decode = false
  req:setData(player, { params.skill_name, params.prompt })
  req:ask()
  return req:getResult(player) ~= ""
end

local function recordSkillEffect(state, player, data)
  local triggerEvent = data.skill_data and data.skill_data.trigger_event
  local damage = triggerEvent and triggerEvent.data
  table.insert(state.skillEffects, {
    step = state.currentDamageStep,
    skill = actualSkillName(data.skill),
    player = player.id,
    from = damage and damage.from and damage.from.id or nil,
    to = damage and damage.to and damage.to.id or nil,
    general = player.general,
    deputyGeneral = player.deputyGeneral,
    fake = player:isFakeSkill(data.skill),
  })
end

local function observedSkill(state, step, skillName)
  return table.find(state.skillEffects, function(effect)
    return effect.step == step and effect.skill == skillName
  end) ~= nil
end

local function observedSkills(state, step)
  local names = {}
  for _, effect in ipairs(state.skillEffects) do
    if effect.step == step then
      table.insertIfNeed(names, effect.skill)
    end
  end
  table.sort(names)
  return names
end

local function sendDamageStepLog(room, step, from, to, result, skills)
  room:sendLog{
    type = "[TQS QA] Bước %arg: %from dùng Sát lên %to; SkillEffect: %arg2; kết quả: %arg3",
    from = from.id,
    to = {to.id},
    arg = tostring(step),
    arg2 = table.concat(skills, ", "),
    arg3 = result,
  }
end

local function movedCount(state, step, skillName, from, to)
  local count = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == step and move.skill == skillName and move.to == to.id and
      (not from or move.from == from.id) then
      count = count + move.count
    end
  end
  return count
end

local function movedFromArea(state, step, skillName, to, area)
  local count = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == step and move.skill == skillName and move.to == to.id and
        move.fromArea == area then
      count = count + move.count
    end
  end
  return count
end

local function convertedCard(state, step, player, name, material)
  return table.find(state.cardEvents, function(card)
    return card.step == step and card.player == player.id and card.name == name and
      card.longdan and #card.subcards == 1 and card.subcards[1] == material
  end) ~= nil
end

local function runAttackStep(room, state, step)
  local spec = scenarioById[state.scenario].attackSteps[step]
  local from = playerForRole(state, spec.from)
  local to = playerForRole(state, spec.to)
  local fromHp, toHp = from.hp, to.hp
  local fromHand, toHand = #from:getCardIds(Player.Hand), #to:getCardIds(Player.Hand)
  state.currentDamageStep = step

  local extra = { bypass_times = true, bypass_distances = true,
    extraUse = true, exclusive_targets = {to.id}, must_targets = {to.id} }
  local use
  if step <= 3 then
    -- Each attack uses a real hand card and the normal Slash/Jink resolution.
    -- Extra uses belong only to this QA setup; no equipment/hero rule changes.
    use = room:askToUseRealCard(from, {
      pattern = {state.slotCards["actor-slash-" .. step]},
      skill_name = "tqs_qa", prompt = "[TQS QA] Sát lần " .. step .. ": chọn Sát và đối thủ",
      extra_data = extra, cancelable = true, skip = true,
    })
  else
    use = room:askToUseCard(from, {
      skill_name = "tqs_qa", pattern = "slash",
      prompt = "[TQS QA] Long Đảm: dùng Thiểm như Sát để phản công",
      extra_data = extra, cancelable = true,
    })
  end
  if not use or use.card.trueName ~= "slash" or #use.tos ~= 1 or use.tos[1] ~= to then
    fail(string.format("attack step %d requires a Slash to the catalog target", step))
  end
  if step <= 3 and use.card.id ~= state.slotCards["actor-slash-" .. step] then
    fail("Wei must use the reserved real Slash for this step")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local dealt = 0
  for _, damage in ipairs(state.damageEvents) do
    if damage.step == step and damage.from == from.id and damage.to == to.id then
      dealt = dealt + damage.amount
    end
  end
  if dealt ~= spec.amount or toHp - to.hp ~= spec.amount then
    fail(string.format("attack step %d expected exactly %d damage", step, spec.amount))
  end
  for _, skillName in ipairs(spec.mandatorySkills) do
    if not observedSkill(state, step, skillName) then
      fail(string.format("attack step %d missing mandatory SkillEffect %s", step, skillName))
    end
  end
  -- These skills remain optional in upstream. This positive test explicitly
  -- selects Invoke; a skipped choice fails this selected branch, not the rule.
  for _, skillName in ipairs(spec.expectedInvokedSkills or {}) do
    if not observedSkill(state, step, skillName) then
      fail(string.format("attack step %d did not select optional skill %s", step, skillName))
    end
  end

  if step == 1 then
    if not convertedCard(state, step, to, "jink", state.slotCards["target-dodge"]) or
      observedSkill(state, step, "ld__enyuan") or from.hp ~= fromHp then
      fail("attack 1 must be dodged by Longdan Slash-as-Jink without Enyuan")
    end
  elseif step == 2 then
    if movedCount(state, step, "ld__enyuan", from, to) ~= 1 or
      #from:getCardIds(Player.Hand) ~= fromHand - 2 or
      #to:getCardIds(Player.Hand) ~= toHand + 1 or from.hp ~= fromHp or
      room:getCardOwner(state.slotCards["actor-gift"]) ~= to then
      fail("attack 2 must consume one Slash and give the reserved hand card via Enyuan")
    end
  elseif step == 3 then
    if fromHand ~= 1 or #from:getCardIds(Player.Hand) ~= 0 or
      fromHp - from.hp ~= 1 or #to:getCardIds(Player.Hand) ~= toHand or
      movedCount(state, step, "ld__enyuan", from, to) ~= 0 then
      fail("attack 3 must leave Wei empty-handed and lose exactly one HP via Enyuan")
    end
    if observedSkill(state, step, "hs__yiji") or observedSkill(state, step, "fankui") then
      fail("Enyuan HP loss must not trigger Damaged skills")
    end
  else
    if not convertedCard(state, step, from, "slash", state.slotCards["target-counter"]) or
      movedCount(state, step, "hs__yiji", nil, to) ~= 2 or
      movedCount(state, step, "fankui", from, to) ~= 1 or
      #to:getCardIds(Player.Hand) ~= toHand + 3 or
      #from:getCardIds(Player.Hand) ~= fromHand - 2 or from.hp ~= fromHp then
      fail("counterattack must use Longdan Jink-as-Slash, Yiji two to self and Fankui one from Shu")
    end
  end
  local skills = observedSkills(state, step)
  state.damageResults[step] = { from = spec.from, to = spec.to, amount = dealt,
    result = spec.expectedEffect, skills = skills }
  sendDamageStepLog(room, step, from, to, spec.expectedEffect, skills)
end

local function triggerDamageExchange(room, state)
  state.actor:revealGenerals()
  state.target:revealGenerals()
  for _, pair in ipairs({{state.target, "ld__enyuan"}, {state.target, "hs__longdan"},
    {state.actor, "hs__yiji"}, {state.actor, "fankui"}}) do
    if not pair[1]:hasSkill(pair[2]) then fail("fixed pair did not attach " .. pair[2]) end
  end
  for step = 1, #scenarioById[state.scenario].attackSteps do
    runAttackStep(room, state, step)
  end
  state.damageExchangeComplete = true
  room:sendLog{ type = "[TQS QA] Hoàn tất bốn bước Sát; ba đòn Ngụy: %arg; phản công Thục: %arg2", from = state.actor.id,
    arg = "longdan-slash-as-jink-dodge; source-gives-one-hand-card; empty-source-loses-one-hp",
    arg2 = "longdan-jink-as-slash; yiji-two-to-self; fankui-one-from-source" }
  fk.qInfo("[tqs_qa] four Slash steps complete scenario=" .. state.scenario)
  -- GameStart runs inside Round:main; a Round exit callback would allow
  -- unrelated normal turns before finishing this four-step acceptance path.
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenYiji(room, state)
  -- The target is revealed only to make the source of the deterministic
  -- damage public. The actor remains fully hidden; the fake Yiji skill is
  -- visible only in the actor's private dashboard.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-yiji actor must start with both generals hidden")
  end
  if state.actor:hasSkill("hs__yiji") then
    fail("hidden-yiji must not be active before the client prelights it")
  end

  -- This is a normal server request, used only as a bounded QA pause. It
  -- gives the real client time to send PushRequest("prelight,...") while the
  -- actor is still hidden; the damage below is still handled by native rules.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_yiji_gate",
    prompt = "TQS QA: prelight Di Kế nếu muốn, rồi bấm Kích hoạt để gây sát thương.",
  })
  if not gate then
    fail("hidden-yiji QA gate was cancelled")
  end

  local prelighted = isPrelighted(state.actor, "hs__yiji")
  state.hiddenPrelighted = prelighted
  state.currentDamageStep = 1
  local beforeHp = state.actor.hp
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_yiji_damage",
  })
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "hs__yiji")
  local revealed = state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang"
  local yijiIsDeputy = state.scenario == "hidden-yiji-deputy" or state.scenario == "hidden-rehide-yiji-deputy"
  local moved = movedCount(state, 1, "hs__yiji", nil, state.actor)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end
  if damage ~= 1 or beforeHp - state.actor.hp ~= 1 then
    fail("hidden-yiji must receive exactly one native damage")
  end

  if not prelighted then
    if invoked or revealed or moved ~= 0 then
      fail("unprelighted hidden Yiji must not ask, reveal or move cards")
    end
    state.hiddenYijiBranch = "negative-no-prelight"
  elseif invoked then
    local revealedCorrectSlot = yijiIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__guojia"
      or not yijiIsDeputy and state.actor.general == "hs__guojia" and state.actor.deputyGeneral == "anjiang"
    if not revealed or not revealedCorrectSlot or moved ~= 2 then
      fail("prelighted and invoked hidden Yiji must reveal Quách Gia in its catalogued slot and give two cards")
    end
    state.hiddenYijiBranch = state.rehideAfterYiji and "positive-prelight-invoke-rehide" or "positive-prelight-invoke"

    if state.rehideAfterYiji then
      -- Source-law regression: a revealed slot may be hidden again by another
      -- rule.  FreeKill must reattach the skill as fake while retaining the
      -- player's prelight choice, so the next legal trigger can still invoke
      -- it.  Do not accept a regular duplicate in the private skill list.
      state.actor:hideGeneral(yijiIsDeputy)
      local hiddenCorrectSlot = yijiIsDeputy
        and state.actor.general == "anjiang" and state.actor.deputyGeneral == "anjiang"
        or not yijiIsDeputy and state.actor.general == "anjiang" and state.actor.deputyGeneral == "anjiang"
      local fake = state.actor:isFakeSkill("hs__yiji")
      local retainedPrelight = isPrelighted(state.actor, "hs__yiji")
      local activeAgain = state.actor:hasSkill("hs__yiji")
      local regularDuplicate = table.contains(state.actor.player_skills, Fk.skills.hs__yiji)
      if not hiddenCorrectSlot or not fake or not retainedPrelight or not activeAgain or regularDuplicate then
        fail(string.format("hidden-rehide-yiji must reattach fake prelighted Di Kế without a regular duplicate (slot=%s fake=%s prelight=%s active=%s regular=%s)",
          yijiIsDeputy and "deputy" or "main", tostring(fake), tostring(retainedPrelight),
          tostring(activeAgain), tostring(regularDuplicate)))
      end
      state.rehideVerified = true
    end
  else
    if revealed or moved ~= 0 then
      fail("skipped hidden Yiji must remain hidden and move no cards")
    end
    state.hiddenYijiBranch = "skip-prelight"
  end

  room:sendLog{
    type = "[TQS QA] Hidden Di Kế: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; chuyển bài=%arg5; úp lại=%arg7",
    from = state.actor.id,
    arg = state.hiddenYijiBranch,
    arg2 = tostring(prelighted),
    arg3 = tostring(invoked),
    arg4 = tostring(revealed),
    arg5 = tostring(moved),
    arg6 = yijiIsDeputy and "phó tướng" or "chủ tướng",
    arg7 = tostring(state.rehideVerified == true),
  }
  fk.qInfo(string.format("[tqs_qa] hidden-yiji branch=%s slot=%s prelight=%s invoked=%s revealed=%s moved=%d rehide=%s revision=%s",
    state.hiddenYijiBranch, yijiIsDeputy and "deputy" or "main", tostring(prelighted), tostring(invoked), tostring(revealed), moved,
    tostring(state.rehideVerified == true), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJianxiong(room, state)
  -- Cao Cao remains fully hidden while the other player uses a real Slash.
  -- The card must stay in Processing during Damaged so the browser can prove
  -- the Jianxiong choice branch that obtains the damage card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jianxiong actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__jianxiong") then
    fail("hidden-jianxiong must attach the hidden Jianxiong skill")
  end
  if state.actor:hasSkill("hs__jianxiong") then
    fail("hidden-jianxiong must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jianxiong_gate",
    prompt = "TQS QA: prelight Gian Hùng, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-jianxiong QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__jianxiong") then
    fail("hidden-jianxiong must be prelighted before the damage branch")
  end

  local cardId = state.slotCards["jianxiong-card"]
  local deferredCardId = state.deferredHands["jianxiong-card"]
  if deferredCardId ~= cardId then
    fail("hidden-jianxiong must retain its catalogued Slash as a deferred target-hand card")
  end
  room:moveCardTo(cardId, Card.PlayerHand, state.target, fk.ReasonJustMove,
    "tqs_qa", nil, false, state.target)
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-jianxiong must put its reserved Slash in the target hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jianxiong_damage",
    prompt = "TQS QA: dùng Sát lên Cao Cao để kiểm tra Gian Hùng.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-jianxiong must receive the reserved target Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "hs__jianxiong")
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__jianxiong" and entry.player == state.actor.id
  end)
  local jianxiongIsDeputy = state.scenario == "hidden-jianxiong-deputy"
  local revealedCorrectSlot = jianxiongIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__caocao"
    or not jianxiongIsDeputy and state.actor.general == "hs__caocao" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "hs__jianxiong", state.actor, Card.Processing)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end

  if damage ~= 1 or not invoked or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Jianxiong must invoke, reveal Cao Cao in its catalogued slot and run a real SkillEffect")
  end
  if obtained ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden Jianxiong obtain choice must move the damaging Slash from Processing to Cao Cao")
  end

  state.hiddenJianxiongBranch = "positive-prelight-invoke-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden Gian Hùng: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài=%arg5",
    from = state.actor.id,
    arg = state.hiddenJianxiongBranch,
    arg2 = "true",
    arg3 = tostring(invoked),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = jianxiongIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jianxiong branch=%s slot=%s prelight=true invoked=%s revealed=%s obtained=%d revision=%s",
    state.hiddenJianxiongBranch, jianxiongIsDeputy and "deputy" or "main", tostring(invoked),
    tostring(revealedCorrectSlot), obtained, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenFankui(room, state)
  -- Tư Mã Ý stays face-down while the public target uses a real Slash. The
  -- catalog keeps a second target hand card so the Slash moves to Processing
  -- and Phản Quỹ must choose the remaining hidden hand card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fankui actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("fankui") then
    fail("hidden-fankui must attach the hidden Fankui skill")
  end
  if state.actor:hasSkill("fankui") then
    fail("hidden-fankui must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_fankui_gate",
    prompt = "TQS QA: prelight Phản Quỹ, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-fankui QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "fankui") then
    fail("hidden-fankui must be prelighted before the damage branch")
  end

  local damageCardId = state.slotCards["fankui-damage"]
  local lootCardId = state.slotCards["fankui-loot"]
  if #state.target:getCardIds(Player.Hand) ~= 2 or
      not table.contains(state.target:getCardIds(Player.Hand), damageCardId) or
      not table.contains(state.target:getCardIds(Player.Hand), lootCardId) then
    fail("hidden-fankui must start with the catalogued target Slash and Peach")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { damageCardId },
    skill_name = "tqs_qa_hidden_fankui_damage",
    prompt = "TQS QA: dùng Sát lên Tư Mã Ý để kiểm tra Phản Quỹ.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= damageCardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-fankui must receive the reserved target Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "fankui")
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "fankui" and entry.player == state.actor.id
  end)
  local fankuiIsDeputy = state.scenario == "hidden-fankui-deputy"
  local revealedCorrectSlot = fankuiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__simayi"
    or not fankuiIsDeputy and state.actor.general == "hs__simayi" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedCount(state, 1, "fankui", state.target, state.actor)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end

  if damage ~= 1 or not invoked or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Fankui must invoke, reveal Tư Mã Ý in its catalogued slot and run a real SkillEffect")
  end
  if obtained ~= 1 or room:getCardOwner(lootCardId) ~= state.actor or
      not table.contains(state.actor:getCardIds(Player.Hand), lootCardId) then
    fail("hidden Fankui must choose and obtain the remaining target hand card")
  end

  state.hiddenFankuiBranch = "positive-prelight-trigger-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden Phản Quỹ: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài=%arg5",
    from = state.actor.id,
    arg = state.hiddenFankuiBranch,
    arg2 = "true",
    arg3 = tostring(invoked),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = fankuiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fankui branch=%s slot=%s prelight=true invoked=%s revealed=%s obtained=%d revision=%s",
    state.hiddenFankuiBranch, fankuiIsDeputy and "deputy" or "main", tostring(invoked),
    tostring(revealedCorrectSlot), obtained, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenEnyuan(room, state)
  -- 法正 remains face-down while the other player uses a real Peach on the
  -- wounded actor.  This covers TargetConfirmed rather than the separate
  -- Damaged branch already exercised by fazheng-enyuan.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-enyuan actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ld__enyuan") then
    fail("hidden-enyuan must attach the hidden Enyuan skill")
  end
  if state.actor:hasSkill("ld__enyuan") then
    fail("hidden-enyuan must not be active before the prelighted Peach target branch")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_enyuan_gate",
    prompt = "TQS QA: prelight Ân Oán, rồi xác nhận để đối thủ dùng Đào lên Pháp Chính.",
  })
  if not gate then
    fail("hidden-enyuan QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "ld__enyuan") then
    fail("hidden-enyuan must be prelighted before the Peach target branch")
  end

  local peachId = state.slotCards["enyuan-peach"]
  if not peachId or not table.contains(state.target:getCardIds(Player.Hand), peachId) then
    fail("hidden-enyuan must put the reserved Peach in the native source hand")
  end
  if state.actor.hp >= state.actor.maxHp then
    room:setPlayerProperty(state.actor, "hp", math.max(1, state.actor.hp - 1))
  end
  if state.actor.hp >= state.actor.maxHp then
    fail("hidden-enyuan must make the actor wounded so the Peach target is legal")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { peachId },
    skill_name = "tqs_qa_hidden_enyuan_peach",
    prompt = "TQS QA: dùng Đào lên Pháp Chính để kiểm tra Ân Oán.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      -- Peach defaults to its user as a fixed target.  The standard dying
      -- rule supplies fix_targets for an external rescuer; mirror that
      -- contract here so the reserved Peach remains selectable against the
      -- wounded hidden actor.
      fix_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= peachId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-enyuan must receive the reserved source Peach against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "ld__enyuan" and entry.player == state.actor.id
  end)
  state.currentDamageStep = nil

  local enyuanIsDeputy = state.scenario == "hidden-enyuan-deputy"
  local revealedCorrectSlot = enyuanIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "ld__fazheng"
    or not enyuanIsDeputy and state.actor.general == "ld__fazheng" and state.actor.deputyGeneral == "anjiang"
  if not state.hiddenEnyuanTargetConfirmed or not effect or effect.fake or not revealedCorrectSlot or
      state.hiddenEnyuanDrawCount ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail(string.format("prelighted hidden Enyuan must reveal Fa Zheng before TargetConfirmed and draw one card (target_confirmed=%s effect=%s fake=%s revealed=%s draw=%d target_hand=%d)",
      tostring(state.hiddenEnyuanTargetConfirmed), tostring(effect ~= nil), tostring(effect and effect.fake),
      tostring(revealedCorrectSlot), state.hiddenEnyuanDrawCount, #state.target:getCardIds(Player.Hand)))
  end

  state.gameOverRequested = true
  room:sendLog{
    type = "[TQS QA] Hidden Ân Oán: TargetConfirmed=%arg; SkillEffect=%arg2; mở Pháp Chính=%arg3; rút bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenEnyuanTargetConfirmed),
    arg2 = tostring(effect ~= nil and not effect.fake),
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(state.hiddenEnyuanDrawCount),
    arg5 = enyuanIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-enyuan target_confirmed=%s skill_effect=%s revealed=%s drawn=%d slot=%s revision=%s",
    tostring(state.hiddenEnyuanTargetConfirmed), tostring(effect ~= nil and not effect.fake),
    tostring(revealedCorrectSlot), state.hiddenEnyuanDrawCount,
    enyuanIsDeputy and "deputy" or "main", manifest.sourceRevision))
  room:gameOver("")
end

local function triggerHiddenFuyin(room, state)
  -- 父荫 is a compulsory TargetConfirmed effect. Keep Zhuge Zhan face-down
  -- until the real Slash reaches the native target-confirmation stage, then
  -- prove that the source reveals the owning slot before nullifying the card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fuyin actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("fuyin") then
    fail("hidden-fuyin must attach the hidden Fuyin skill")
  end
  if state.actor:hasSkill("fuyin") then
    fail("hidden-fuyin must not be active before the prelighted Slash branch")
  end

  local gate = askQaSkillInvoke(room, state.actor, {
    skill_name = "tqs_qa_hidden_fuyin_gate",
    prompt = "TQS QA: prelight Phụ Âm, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-fuyin QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "fuyin") then
    fail("hidden-fuyin must be prelighted before the TargetConfirmed branch")
  end

  local cardId = state.slotCards["fuyin-slash"]
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-fuyin must put the reserved Slash in the native source hand")
  end

  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_fuyin_damage",
    prompt = "TQS QA: dùng Sát lên Phụ Ấm để kiểm tra TargetConfirmed.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-fuyin must receive the reserved source Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "fuyin" and entry.player == state.actor.id
  end)
  local fuyinIsDeputy = state.scenario == "hidden-fuyin-deputy"
  local revealedCorrectSlot = fuyinIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "zhugezhan"
    or not fuyinIsDeputy and state.actor.general == "zhugezhan" and state.actor.deputyGeneral == "anjiang"
  if not state.hiddenFuyinTargetConfirmed or not state.hiddenFuyinNullified or
      state.actor.hp ~= actorHpBefore or not effect or effect.fake or not revealedCorrectSlot then
    fail(string.format("prelighted hidden Fuyin must reveal Zhuge Zhan before nullifying TargetConfirmed Slash (target_confirmed=%s nullified=%s hp_before=%d hp_after=%d effect=%s fake=%s revealed=%s has_skill=%s fake_skill=%s actor_hand=%d source_hand=%d)",
      tostring(state.hiddenFuyinTargetConfirmed), tostring(state.hiddenFuyinNullified), actorHpBefore,
      state.actor.hp, tostring(effect ~= nil), tostring(effect and effect.fake), tostring(revealedCorrectSlot),
      tostring(state.actor:hasSkill("fuyin")), tostring(state.actor:isFakeSkill("fuyin")),
      state.actor:getHandcardNum(), state.target:getHandcardNum()))
  end

  room:sendLog{
    type = "[TQS QA] Hidden Phụ Âm: TargetConfirmed=%arg; SkillEffect=%arg2; vô hiệu Sát=%arg3; mở Gia Cát Chiêm=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenFuyinTargetConfirmed),
    arg2 = tostring(effect ~= nil and not effect.fake),
    arg3 = tostring(state.hiddenFuyinNullified),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = fuyinIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fuyin target_confirmed=%s skill_effect=%s nullified=%s revealed=%s slot=%s revision=%s",
    tostring(state.hiddenFuyinTargetConfirmed), tostring(effect ~= nil and not effect.fake),
    tostring(state.hiddenFuyinNullified), tostring(revealedCorrectSlot),
    fuyinIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenKuanggu(room, state)
  -- 狂骨 has two linked source effects: BeforeHpChanged marks a close-range
  -- damage event, then Damage asks the hidden owner whether to draw or heal.
  -- Keep Wei Yan face-down until the real SkillEffect path resolves so this
  -- scenario proves both the prelight gate and reveal-before-effect ordering.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-kuanggu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__kuanggu") then
    fail("hidden-kuanggu must attach the hidden Kuanggu skill")
  end
  if state.actor:hasSkill("hs__kuanggu") then
    fail("hidden-kuanggu must not be active before the prelighted damage effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_kuanggu_gate",
    prompt = "TQS QA: prelight Cuồng Cốt, rồi xác nhận để đối thủ nhận sát thương.",
  })
  if not gate then
    fail("hidden-kuanggu QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__kuanggu") then
    fail("hidden-kuanggu must be prelighted before the damage branch")
  end

  local cardId = state.slotCards["kuanggu-card"]
  local targetCardId = state.slotCards["kuanggu-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-kuanggu must put the reserved Slash and target Peach in the native hands")
  end
  if #state.actor:getCardIds(Player.Hand) ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail("hidden-kuanggu must keep the actor and target hands deterministic")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_kuanggu_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Cuồng Cốt.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-kuanggu must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__kuanggu" and entry.player == state.actor.id
  end)
  local kuangguIsDeputy = state.scenario == "hidden-kuanggu-deputy"
  local revealedCorrectSlot = kuangguIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__weiyan"
    or not kuangguIsDeputy and state.actor.general == "hs__weiyan" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end
  local moved = movedCount(state, 1, "hs__kuanggu", nil, state.actor)

  if not state.kuangguBeforeHpChanged or not state.kuangguDamage or damage ~= 1 or
      not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Kuanggu must mark close-range damage, reveal Wei Yan and run a real SkillEffect")
  end
  if moved ~= 1 then
    fail("hidden Kuanggu must execute the native draw1 choice and move one card to the actor hand")
  end

  state.hiddenKuangguBranch = "positive-prelight-damage-draw"
  room:sendLog{
    type = "[TQS QA] Hidden Cuồng Cốt: BeforeHpChanged=%arg; Damage=%arg2; SkillEffect=%arg3; mở tướng=%arg4; bốc bài=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(moved == 1),
    arg6 = kuangguIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-kuanggu before_hp_changed=true damage=true skill_effect=true moved=%d slot=%s main=%s deputy=%s revision=%s",
    moved, kuangguIsDeputy and "deputy" or "main", state.actor.general, state.actor.deputyGeneral,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenLiegong(room, state)
  -- 烈弓 is a TargetSpecified trigger.  Keep Huang Zhong face-down until the
  -- real Slash reaches the native choice, then prove that the damage branch
  -- adds one point and reveals only the slot owning the prelighted skill.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-liegong actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__liegong") then
    fail("hidden-liegong must attach the hidden Liegong skill")
  end
  if state.actor:hasSkill("hs__liegong") then
    fail("hidden-liegong must not be active before the prelighted target branch")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_liegong_gate",
    prompt = "TQS QA: prelight Liệt Cung, rồi xác nhận để dùng Sát.",
  })
  if not gate then
    fail("hidden-liegong QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__liegong") then
    fail("hidden-liegong must be prelighted before the TargetSpecified branch")
  end

  local cardId = state.slotCards["liegong-card"]
  local targetCardId = state.slotCards["liegong-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-liegong must put the reserved Slash and target Peach in the native hands")
  end
  if #state.actor:getCardIds(Player.Hand) ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail("hidden-liegong must keep the actor and target hands deterministic")
  end
  if state.actor.hp ~= state.target.hp then
    fail("hidden-liegong must start with equal full HP so its source predicate is true")
  end

  local targetHpBefore = state.target.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_liegong_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Liệt Cung.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-liegong must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__liegong" and entry.player == state.actor.id
  end)
  local liegongIsDeputy = state.scenario == "hidden-liegong-deputy"
  local revealedCorrectSlot = liegongIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__huangzhong"
    or not liegongIsDeputy and state.actor.general == "hs__huangzhong" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end

  if not state.liegongTargetSpecified or not state.liegongDamage or damage ~= 2 or
      targetHpBefore - state.target.hp ~= 2 or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Liegong must mark TargetSpecified/Damage, reveal Huang Zhong and add one damage")
  end

  state.hiddenLiegongBranch = "positive-prelight-target-specified-damage-plus-one"
  room:sendLog{
    type = "[TQS QA] Hidden Liệt Cung: TargetSpecified=%arg; Damage=%arg2; SkillEffect=%arg3; sát thương=2; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = liegongIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-liegong target_specified=true damage=2 skill_effect=true revealed=%s slot=%s main=%s deputy=%s revision=%s",
    tostring(revealedCorrectSlot), liegongIsDeputy and "deputy" or "main", state.actor.general,
    state.actor.deputyGeneral, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJueqing(room, state)
  -- 绝情 is a compulsory fk.PreDamage effect. Keep Zhang Chunhua hidden until
  -- the real Slash reaches PreDamage, then prove that the source converts the
  -- damage into HP loss and prevents the ordinary Damage/Damaged path.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jueqing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("jueqing") then
    fail("hidden-jueqing must attach the hidden Jueqing skill")
  end
  if state.actor:hasSkill("jueqing") then
    fail("hidden-jueqing must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jueqing_gate",
    prompt = "TQS QA: prelight Tuyệt Tình, rồi xác nhận để đối thủ nhận Sát.",
  })
  if not gate then
    fail("hidden-jueqing QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "jueqing") then
    fail("hidden-jueqing must be prelighted before the PreDamage branch")
  end

  local cardId = state.slotCards["jueqing-card"]
  if not cardId or #state.actor:getCardIds(Player.Hand) ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-jueqing must put exactly the reserved Slash in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jueqing_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Tuyệt Tình.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-jueqing must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "jueqing" and entry.player == state.actor.id
  end)
  local jueqingIsDeputy = state.scenario == "hidden-jueqing-deputy"
  local revealedCorrectSlot = jueqingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "zhangchunhua"
    or not jueqingIsDeputy and state.actor.general == "zhangchunhua" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end
  local targetHpLoss = targetHpBefore - state.target.hp

  if not state.jueqingPreDamage or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 1 or damage ~= 0 or actorHpBefore ~= state.actor.hp then
    fail("prelighted hidden Jueqing must reveal Zhang Chunhua, convert one damage to HP loss and prevent Damaged")
  end
  if state.actor:isFakeSkill("jueqing") or not state.actor:hasSkill("jueqing") then
    fail("hidden Jueqing must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Tuyệt Tình: PreDamage=%arg; Damage=%arg2; SkillEffect=%arg3; mất máu=%arg4; mở tướng=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = tostring(damage == 0),
    arg3 = "true",
    arg4 = tostring(targetHpLoss == 1),
    arg5 = tostring(revealedCorrectSlot),
    arg6 = jueqingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jueqing pre_damage=true damage_event=false skill_effect=true hp_loss=%d revealed=%s slot=%s main=%s deputy=%s revision=%s",
    targetHpLoss, tostring(revealedCorrectSlot), jueqingIsDeputy and "deputy" or "main",
    state.actor.general, state.actor.deputyGeneral, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenEjue(room, state)
  -- 扼绝 is a compulsory fk.DamageCaused effect. Keep Zhang Chunhua hidden
  -- until the real Slash reaches the source-side damage hook, then prove the
  -- native predicate (Slash + unknown kingdom) and the +1 damage mutation.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-ejue actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("heg__ejue") then
    fail("hidden-ejue must attach the hidden Ejue skill")
  end
  if state.actor:hasSkill("heg__ejue") then
    fail("hidden-ejue must not be active before the prelighted effect")
  end

  -- The source skill itself requires data.to.kingdom == unknown. This is a
  -- test fixture for that native state, not a production rule change.
  room:setPlayerProperty(state.target, "kingdom", "unknown")
  room:broadcastProperty(state.target, "kingdom")

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_ejue_gate",
    prompt = "TQS QA: prelight Ách Tuyệt, rồi xác nhận để dùng Sát lên người chưa rõ thế lực.",
  })
  if not gate then
    fail("hidden-ejue QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "heg__ejue") then
    fail("hidden-ejue must be prelighted before the DamageCaused branch")
  end

  local cardId = state.slotCards["ejue-card"]
  if not cardId or #state.actor:getCardIds(Player.Hand) ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-ejue must put exactly the reserved Slash in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_ejue_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Ách Tuyệt.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-ejue must receive the reserved actor Slash against the unknown target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "heg__ejue" and entry.player == state.actor.id
  end)
  local ejueIsDeputy = state.scenario == "hidden-ejue-deputy"
  local revealedCorrectSlot = ejueIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "heg__zhangchunhua"
    or not ejueIsDeputy and state.actor.general == "heg__zhangchunhua" and state.actor.deputyGeneral == "anjiang"
  local targetHpLoss = targetHpBefore - state.target.hp
  if not state.hiddenEjueDamageCaused or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 2 or actorHpBefore ~= state.actor.hp then
    fail("prelighted hidden Ejue must enter DamageCaused, reveal Zhang Chunhua and add one damage")
  end
  if state.actor:isFakeSkill("heg__ejue") or not state.actor:hasSkill("heg__ejue") then
    fail("hidden Ejue must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Ách Tuyệt: DamageCaused=%arg; sát thương=%arg2; SkillEffect=%arg3; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenEjueDamageCaused),
    arg2 = tostring(targetHpLoss),
    arg3 = tostring(effect ~= nil and not effect.fake),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = ejueIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-ejue damage_caused=true damage=%d skill_effect=true revealed=%s slot=%s revision=%s",
    targetHpLoss, tostring(revealedCorrectSlot), ejueIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenDufu(room, state)
  -- 独夫 is a compulsory fk.DamageCaused effect. Keep Sima Jiong hidden
  -- until a real Slash reaches the native source hook, then prove the
  -- same-kingdom predicate and the +1 damage mutation with a Jin actor and
  -- a Shu target.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-dufu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("heg__dufu") then
    fail("hidden-dufu must attach the hidden Dufu skill")
  end
  if state.actor:hasSkill("heg__dufu") then
    fail("hidden-dufu must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_dufu_gate",
    prompt = "TQS QA: prelight Độc Phu, rồi xác nhận để dùng Sát lên thế lực khác.",
  })
  if not gate then
    fail("hidden-dufu QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "heg__dufu") then
    fail("hidden-dufu must be prelighted before the DamageCaused branch")
  end

  local cardId = state.slotCards["dufu-card"]
  if not cardId or #state.actor:getCardIds(Player.Hand) ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-dufu must put exactly the reserved Slash in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_dufu_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Độc Phu.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-dufu must receive the reserved actor Slash against the other kingdom")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "heg__dufu" and entry.player == state.actor.id
  end)
  local dufuIsDeputy = state.scenario == "hidden-dufu-deputy"
  local revealedCorrectSlot = dufuIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "heg__simajiong"
    or not dufuIsDeputy and state.actor.general == "heg__simajiong" and state.actor.deputyGeneral == "anjiang"
  local targetHpLoss = targetHpBefore - state.target.hp
  if not state.hiddenDufuDamageCaused or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 2 or actorHpBefore ~= state.actor.hp then
    fail("prelighted hidden Dufu must enter DamageCaused, reveal Sima Jiong and add one damage")
  end
  if state.actor:isFakeSkill("heg__dufu") or not state.actor:hasSkill("heg__dufu") then
    fail("hidden Dufu must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Độc Phu: DamageCaused=%arg; sát thương=%arg2; SkillEffect=%arg3; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenDufuDamageCaused),
    arg2 = tostring(targetHpLoss),
    arg3 = tostring(effect ~= nil and not effect.fake),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = dufuIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-dufu damage_caused=true damage=%d skill_effect=true revealed=%s slot=%s revision=%s",
    targetHpLoss, tostring(revealedCorrectSlot), dufuIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJianzhi(room, state)
  -- 奸志 is an optional fk.DamageCaused effect. Keep Jia Chong hidden until
  -- a real lethal Slash reaches the native damage hook, then accept the
  -- source-defined invoke, discard the remaining hand and verify the reward
  -- banner mutation. The second hand card is intentional: the Slash leaves
  -- processing before the predicate checks isKongcheng().
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jianzhi actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("heg__jianzhi") then
    fail("hidden-jianzhi must attach the hidden Jianzhi skill")
  end
  if state.actor:hasSkill("heg__jianzhi") then
    fail("hidden-jianzhi must not be active before the prelighted effect")
  end

  -- The real lethal Slash must resolve to Death. Remove the target's normal
  -- initial hand so a Peach rescue cannot turn this DamageCaused proof into a
  -- separate Dying/AskForPeaches branch.
  state.target:throwAllCards("h", "tqs_qa")
  room:setPlayerProperty(state.target, "hp", 1)
  room:broadcastProperty(state.target, "hp")

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jianzhi_gate",
    prompt = "TQS QA: prelight Gian Chí, rồi xác nhận để dùng Sát chí mạng.",
  })
  if not gate then
    fail("hidden-jianzhi QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "heg__jianzhi") then
    fail("hidden-jianzhi must be prelighted before the DamageCaused branch")
  end

  local cardId = state.slotCards["jianzhi-card"]
  local fillerId = state.slotCards["jianzhi-filler"]
  local hand = state.actor:getCardIds(Player.Hand)
  if not cardId or not fillerId or #hand ~= 2 or
      not table.contains(hand, cardId) or not table.contains(hand, fillerId) then
    fail("hidden-jianzhi must put the reserved Slash and one filler card in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jianzhi_damage",
    prompt = "TQS QA: dùng Sát chí mạng để kiểm tra Gian Chí.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-jianzhi must receive the reserved Slash against the one-hp target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "heg__jianzhi" and entry.player == state.actor.id
  end)
  local jianzhiIsDeputy = state.scenario == "hidden-jianzhi-deputy"
  local revealedCorrectSlot = jianzhiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "heg__jiachong"
    or not jianzhiIsDeputy and state.actor.general == "heg__jiachong" and state.actor.deputyGeneral == "anjiang"
  local targetHpLoss = targetHpBefore - state.target.hp
  local rewardBanner = room:getBanner("additional_reward") or 0
  local jianzhiBanner = room:getBanner("heg__jianzhi") or 0
  if not state.hiddenJianzhiDamageCaused or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 1 or not state.target.dead or actorHpBefore ~= state.actor.hp or
      not state.actor:isKongcheng() or jianzhiBanner < 1 or rewardBanner < 2 then
    fail("prelighted hidden Jianzhi must invoke on lethal DamageCaused, reveal Jia Chong, discard the hand and set the triple-reward banner")
  end
  if state.actor:isFakeSkill("heg__jianzhi") or not state.actor:hasSkill("heg__jianzhi") then
    fail("hidden Jianzhi must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Gian Chí: DamageCaused=%arg; chí mạng=%arg2; bỏ bài=%arg3; thưởng=3x; SkillEffect=%arg4; mở tướng=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = tostring(state.hiddenJianzhiDamageCaused),
    arg2 = tostring(targetHpLoss == 1),
    arg3 = tostring(state.actor:isKongcheng()),
    arg4 = tostring(effect ~= nil and not effect.fake),
    arg5 = tostring(revealedCorrectSlot),
    arg6 = jianzhiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jianzhi damage_caused=true lethal=true discarded=true reward=3x skill_effect=true revealed=%s slot=%s revision=%s",
    tostring(revealedCorrectSlot), jianzhiIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenZhiman(room, state)
  -- 制蛮 is an optional fk.DamageCaused effect. Keep Ma Su face-down until
  -- the real Slash reaches DamageCaused, then verify the source-defined invoke
  -- prevents damage and obtains the target's reserved equipment card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-zhiman actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ld__zhiman") then
    fail("hidden-zhiman must attach the hidden Zhiman skill")
  end
  if state.actor:hasSkill("ld__zhiman") then
    fail("hidden-zhiman must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_zhiman_gate",
    prompt = "TQS QA: prelight Chế Man, rồi xác nhận để dùng Sát lên đối thủ.",
  })
  if not gate then
    fail("hidden-zhiman QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "ld__zhiman") then
    fail("hidden-zhiman must be prelighted before the DamageCaused branch")
  end

  local cardId = state.slotCards["zhiman-card"]
  local equipId = state.slotCards["zhiman-equip"]
  local hand = state.actor:getCardIds(Player.Hand)
  local targetEquip = state.target:getCardIds(Player.Equip)
  if not cardId or not equipId or not table.contains(hand, cardId) or
      not table.contains(targetEquip, equipId) then
    fail("hidden-zhiman must put the reserved Slash in the actor hand and equipment on the target")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_zhiman_damage",
    prompt = "TQS QA: dùng Sát để kiểm tra Chế Man.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-zhiman must receive the reserved Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "ld__zhiman" and entry.player == state.actor.id
  end)
  local zhimanIsDeputy = state.scenario == "hidden-zhiman-deputy"
  local revealedCorrectSlot = zhimanIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "ld__masu"
    or not zhimanIsDeputy and state.actor.general == "ld__masu" and state.actor.deputyGeneral == "anjiang"
  local equipmentMoved = table.contains(state.actor:getCardIds(Player.Hand), equipId) or
    table.contains(state.actor:getCardIds(Player.Equip), equipId)
  local targetHpSame = targetHpBefore == state.target.hp and not state.target.dead
  if not state.hiddenZhimanDamageCaused or not effect or effect.fake or not revealedCorrectSlot or
      not targetHpSame or not equipmentMoved or actorHpBefore ~= state.actor.hp then
    fail(string.format("prelighted hidden Zhiman must invoke on DamageCaused, reveal Ma Su, prevent damage and obtain the equipment; " ..
      "DamageCaused=%s effect=%s fake=%s reveal=%s hpSame=%s equipment=%s actorHpSame=%s general=%s deputy=%s has=%s fakeNow=%s prelight=%s",
      tostring(state.hiddenZhimanDamageCaused), tostring(effect ~= nil), tostring(effect and effect.fake or false),
      tostring(revealedCorrectSlot), tostring(targetHpSame), tostring(equipmentMoved),
      tostring(actorHpBefore == state.actor.hp), tostring(state.actor.general), tostring(state.actor.deputyGeneral),
      tostring(state.actor:hasSkill("ld__zhiman")), tostring(state.actor:isFakeSkill("ld__zhiman")),
      tostring(isPrelighted(state.actor, "ld__zhiman"))))
  end
  if state.actor:isFakeSkill("ld__zhiman") or not state.actor:hasSkill("ld__zhiman") then
    fail("hidden Zhiman must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Chế Man: DamageCaused=%arg; ngăn sát thương=%arg2; lấy trang bị=%arg3; SkillEffect=%arg4; mở tướng=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = tostring(state.hiddenZhimanDamageCaused),
    arg2 = tostring(targetHpSame),
    arg3 = tostring(equipmentMoved),
    arg4 = tostring(effect ~= nil and not effect.fake),
    arg5 = tostring(revealedCorrectSlot),
    arg6 = zhimanIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-zhiman damage_caused=true prevented=true obtained_equipment=true skill_effect=true revealed=%s slot=%s revision=%s",
    tostring(revealedCorrectSlot), zhimanIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJilix(room, state)
  -- 寄篱 has two linked source effects. A red Slash is repeated at
  -- TargetConfirmed, then the second DamageInflicted in the phase is
  -- prevented and removes the general that owns the hidden skill.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jilix actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ld__jilix") then
    fail("hidden-jilix must attach the hidden Jilix skill")
  end
  if state.actor:hasSkill("ld__jilix") then
    fail("hidden-jilix must not be active before the TargetConfirmed branch")
  end

  local gate = askQaSkillInvoke(room, state.actor, {
    skill_name = "tqs_qa_hidden_jilix_gate",
    prompt = "TQS QA: prelight Ký Ly, rồi xác nhận để nguồn dùng Sát đỏ.",
  })
  if not gate then
    fail("hidden-jilix QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "ld__jilix") then
    fail("hidden-jilix must be prelighted before the TargetConfirmed branch")
  end

  local cardId = state.slotCards["jilix-slash"]
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-jilix must put the reserved red Slash in the native source hand")
  end

  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jilix_damage",
    prompt = "TQS QA: dùng Sát đỏ lên đối thủ để kiểm tra Ký Ly.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or use.card.trueName ~= "slash" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-jilix must receive the reserved red Slash against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effectCount = 0
  for _, entry in ipairs(state.skillEffects) do
    if entry.step == 1 and entry.skill == "ld__jilix" and entry.player == state.actor.id then
      effectCount = effectCount + 1
    end
  end
  local jilixIsDeputy = state.scenario == "hidden-jilix-deputy"
  local removedCorrectSlot = jilixIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "blank_shibing" and
      state.actor:getMark("__heg_general") == "ld__huangzu" and
      state.actor:getMark("__heg_deputy") == "blank_shibing"
    or not jilixIsDeputy and state.actor.general == "blank_shibing" and state.actor.deputyGeneral == "anjiang" and
      state.actor:getMark("__heg_general") == "blank_shibing" and
      state.actor:getMark("__heg_deputy") == "ld__huangzu"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end
  local hpLoss = actorHpBefore - state.actor.hp
  -- DamageInflicted is a nested engine event and may be observed more than
  -- once for each actual damage resolution. The authoritative assertions are
  -- the source effect count, one actual damage, one HP loss, and removal of
  -- the owning slot; require at least two callbacks only as a lower bound.
  if not state.hiddenJilixTargetConfirmed or state.hiddenJilixDamageInflicted < 2 or
      effectCount < 2 or damage ~= 1 or hpLoss ~= 1 or not removedCorrectSlot then
    fail(string.format("prelighted hidden Jilix must repeat the red Slash, prevent the second damage and remove the owning slot; " ..
      "target_confirmed=%s damage_inflicted=%d effects=%d damage=%d hp_loss=%d removed_slot=%s general=%s deputy=%s",
      tostring(state.hiddenJilixTargetConfirmed), state.hiddenJilixDamageInflicted, effectCount, damage, hpLoss,
      tostring(removedCorrectSlot), state.actor.general, state.actor.deputyGeneral))
  end

  room:sendLog{
    type = "[TQS QA] Hidden Ký Ly: TargetConfirmed=%arg; DamageInflicted lần hai=%arg2; sát thương thực=%arg3; xoá đúng ô=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenJilixTargetConfirmed),
    arg2 = tostring(state.hiddenJilixDamageInflicted >= 2),
    arg3 = tostring(damage),
    arg4 = tostring(removedCorrectSlot),
    arg5 = jilixIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jilix target_confirmed=true damage_inflicted=2 repeated=true prevented_second=true damage=%d removed_slot=%s slot=%s main=%s deputy=%s revision=%s",
    damage, tostring(removedCorrectSlot), jilixIsDeputy and "deputy" or "main", state.actor.general,
    state.actor.deputyGeneral, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenReveal(room, state)
  -- The target is revealed to keep the public board deterministic. The actor
  -- remains face-down and must use the same active helper that the native
  -- dashboard exposes for a hidden general with a compulsory skill.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-reveal actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-reveal must attach the hidden compulsory Qianxun skill")
  end
  if not state.actor:isFakeSkill("reveal_skill&") then
    fail("hidden-reveal must attach the native reveal_skill& helper")
  end

  -- Keep the active request behind the same real-client readiness gate used
  -- by hidden-yiji. GameStart can finish before the browser has projected the
  -- fake/regular skill split; the active helper itself must still be the
  -- native AskForUseActiveSkill request below.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_reveal_gate",
    prompt = "TQS QA: xác nhận dock Mở tướng đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-reveal readiness gate was cancelled")
  end

  local success = room:askToUseActiveSkill(state.actor, {
    skill_name = "reveal_skill&",
    prompt = "TQS QA: mở Lục Tốn bằng kỹ năng Tỏa định.",
    cancelable = true,
  })
  if not success then
    fail("hidden-reveal active helper was cancelled or rejected")
  end
  local revealIsDeputy = state.scenario == "hidden-reveal-deputy"
  local revealedCorrectSlot = revealIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
    or not revealIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
  if not revealedCorrectSlot then
    fail("hidden-reveal must reveal Lục Tốn in its catalogued slot and leave the other slot hidden")
  end
  if not state.actor:hasSkill("hs__qianxun") or state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-reveal must convert Qianxun from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Mở tướng: %arg; vị trí=%arg4; Lục Tốn đã mở=%arg2; Tỏa định đã hoạt động=%arg3",
    from = state.actor.id,
    arg = "reveal_skill&",
    arg2 = "true",
    arg3 = "true",
    arg4 = revealIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-reveal helper=reveal_skill& slot=%s revealed=hs__luxun qianxun_active=true revision=%s",
    revealIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

-- Run a metadata-only native probe before the hidden-active gameplay proof.
-- The same synthetic replies and public-event fixture run on baseline and
-- candidate QA runtimes.  It deliberately does not inspect private cards,
-- hidden generals, prompts, targets, or raw validator errors.
-- Intentionally malformed *non-nil* native replies are exercised against the
-- real SmartAI -> Base.AI shape validator -> dashboard feasibility pipeline.
-- Metrics live in a detached room: negative cases must never contaminate the
-- real game's zero-invalid denominator or the matched Prompt 4 trace.
local aiTraceReplyMetricSnapshot, aiTraceReplyMetricDelta, aiTraceEngineState
local function runAiMalformedReplyProbe(room, state)
  if not (SmartAI and type(SmartAI.new) == "function" and Fk.skills.hs__zhiheng) then
    fail("malformed reply native probe prerequisites are unavailable")
  end
  local tags, rejectFeasibility = {}, false
  local isolated = { request_handlers = {} }
  function isolated:getTag(key) return tags[key] end
  function isolated:setTag(key, value) tags[key] = value end
  function isolated:getPlayerById(id) return room:getPlayerById(id) end
  -- General-pair QA hooks inspect room settings during SmartAI validation.
  -- A detached probe room has no configured scenario or visible roster.
  function isolated:getSettings() return nil end
  local fakeHandler = {}
  function fakeHandler:new()
    return {
      setup = function() end,
      feasible = function() return not rejectFeasibility end,
    }
  end
  local dashboardCommands = {
    "AskForUseActiveSkill", "AskForUseCard", "AskForResponseCard", "PlayCard",
  }
  for _, command in ipairs(dashboardCommands) do
    isolated.request_handlers[command] = fakeHandler
  end

  local probe = SmartAI:new(room.players[1])
  probe.room = isolated
  local reply, fallbackReason
  local function injectedReply(self)
    if fallbackReason then self:markFallback(fallbackReason) end
    return reply
  end
  -- Test each public entry point through the native makeReply() dispatcher;
  -- override only the strategy's candidate result, never the validators.
  for _, command in ipairs(dashboardCommands) do
    probe["handle" .. command] = injectedReply
  end
  probe.handleCustomDialog = injectedReply
  local valid = function()
    return { card = { skill = "hs__zhiheng", subcards = {} }, targets = {} }
  end
  local observed, observedByCommand = {}, {}
  local failed = 0
  local function check(command, label, expectedReply, expectedReason, expectedDetail)
    probe.command = command
    if command == "PlayCard" then
      probe.data = nil -- native PlayCard has no request payload
    elseif command == "CustomDialog" then
      probe.data = { component = { name = "TqsQaUnknownDialog" } }
    else
      probe.data = { "hs__zhiheng", "QA", true, {} }
    end
    local beforeState = aiTraceEngineState(room)
    local beforeMetric = aiTraceReplyMetricSnapshot(probe, command)
    local value = probe:makeReply()
    local actualReply = value == "__cancel" and "cancel" or type(value)
    local reason, detail = aiTraceReplyMetricDelta(probe, command, beforeMetric)
    local unchanged = aiTraceEngineState(room) == beforeState
    local classificationOk = actualReply == expectedReply and reason == expectedReason and
      detail == (expectedDetail or "none")
    if not classificationOk or not unchanged then
      fk.qInfo(string.format(
        "[tqs_qa_malformed_diagnostic] command=%s case=%s actual=%s reason=%s detail=%s state_unchanged=%d",
        aiTraceToken(command), aiTraceToken(label), aiTraceToken(actualReply),
        aiTraceToken(reason), aiTraceToken(detail), unchanged and 1 or 0))
      failed = failed + 1
    end
    fk.qInfo(string.format(
      "[tqs_qa_malformed_case] schema=3 snapshot=synthetic command=%s error=%s expected_reply=%s observed_reply=%s expected_reason=%s observed_reason=%s expected_detail=%s observed_detail=%s classification=%s state_unchanged=%d",
      aiTraceToken(command), aiTraceToken(label), aiTraceToken(expectedReply),
      aiTraceToken(actualReply), aiTraceToken(expectedReason),
      aiTraceToken(reason), aiTraceToken(expectedDetail or "none"),
      aiTraceToken(detail), classificationOk and "pass" or "fail", unchanged and 1 or 0))
    observed[#observed + 1] = command .. "/" .. label
    observedByCommand[command] = (observedByCommand[command] or 0) + 1
  end

  for _, command in ipairs(dashboardCommands) do
    reply = valid()
    check(command, "valid", "table", "accepted")
    reply = { card = "forged", targets = {} }
    check(command, "card_type", "cancel", "invalid_reply")
    reply = { card = { skill = "hs__zhiheng", subcards = "forged" }, targets = {} }
    check(command, "subcards_type", "cancel", "invalid_reply")
    reply = { card = { skill = "hs__zhiheng", subcards = {} }, targets = "forged" }
    check(command, "targets_type", "cancel", "invalid_reply")
    reply = valid()
    reply.targets = { 999999 }
    check(command, "target_missing", "cancel", "invalid_reply")
    reply = valid()
    reply.targets = { 0.5 }
    check(command, "target_non_integer", "cancel", "invalid_reply")
    reply = valid()
    rejectFeasibility = true
    check(command, "feasibility", "cancel", "illegal_reply", "feasibility_rejected")
    rejectFeasibility = false
    reply = valid()
    reply.special_skill = "tqs_qa_missing_skill"
    check(command, "special_skill", "cancel", "illegal_reply", "special_skill_missing")
    reply, fallbackReason = nil, "no_strategy"
    check(command, "no_strategy", "cancel", "no_strategy")
    fallbackReason = nil
    check(command, "no_decision", "cancel", "no_decision")
  end

  -- An unsupported CustomDialog must reject arbitrary non-nil payloads,
  -- while a nil strategy result remains a separate no_decision fallback.
  reply = { "forged" }
  check("CustomDialog", "unknown_table", "cancel", "invalid_reply")
  reply = "forged"
  check("CustomDialog", "unknown_string", "cancel", "invalid_reply")
  reply = nil
  check("CustomDialog", "no_decision", "cancel", "no_decision")
  check("TqsQaUnsupported", "unsupported", "cancel", "unsupported_command")

  if failed > 0 then fail("native malformed reply classification mismatches: " .. tostring(failed)) end
  local metrics = probe:getResponseMetrics()
  local reasons = metrics.fallback_reasons or {}
  local details = metrics.invalid_details or {}
  if #observed ~= 44 or metrics.total ~= 44 or metrics.fallback ~= 40 or
      metrics.invalid ~= 30 or metrics.no_decision ~= 9 or metrics.unsupported ~= 1 or
      reasons.invalid_reply ~= 22 or reasons.illegal_reply ~= 8 or
      reasons.no_strategy ~= 4 or reasons.no_decision ~= 5 or
      reasons.unsupported_command ~= 1 or
      details.feasibility_rejected ~= 4 or details.special_skill_missing ~= 4 then
    fail("native malformed reply probe counter reconciliation failed")
  end
  for _, command in ipairs(dashboardCommands) do
    local bucket = metrics.by_command and metrics.by_command[command] or {}
    if observedByCommand[command] ~= 10 or bucket.total ~= 10 or
        bucket.fallback ~= 9 or bucket.invalid ~= 7 or
        bucket.no_decision ~= 2 or bucket.unsupported ~= 0 then
      fail("native malformed reply probe dashboard counter drift: " .. command)
    end
  end
  local dialog = metrics.by_command and metrics.by_command.CustomDialog or {}
  local unsupported = metrics.by_command and metrics.by_command.TqsQaUnsupported or {}
  if observedByCommand.CustomDialog ~= 3 or dialog.total ~= 3 or
      dialog.invalid ~= 2 or dialog.no_decision ~= 1 or
      unsupported.total ~= 1 or unsupported.unsupported ~= 1 then
    fail("native malformed reply probe non-dashboard counter drift")
  end
  -- All labels and counts are fixed, non-sensitive QA metadata.
  fk.qInfo(string.format(
    "[tqs_qa_malformed_reply] schema=2 scenario=%s seed=%u cases=%d accepted=4 fallback=%d invalid=%d no_decision=%d unsupported=%d invalid_reply=%d illegal_reply=%d no_strategy=%d no_decision_reason=%d unsupported_command=%d feasibility_rejected=%d special_skill_missing=%d",
    state.scenario, state.seed, #observed, metrics.fallback, metrics.invalid,
    metrics.no_decision, metrics.unsupported, reasons.invalid_reply, reasons.illegal_reply,
    reasons.no_strategy, reasons.no_decision, reasons.unsupported_command,
    details.feasibility_rejected, details.special_skill_missing))
  for _, command in ipairs(dashboardCommands) do
    fk.qInfo(string.format(
      "[tqs_qa_malformed_reply] command=%s total=10 accepted=1 fallback=9 invalid=7 no_decision=2 unsupported=0",
      command))
  end
  fk.qInfo("[tqs_qa_malformed_reply] command=CustomDialog total=3 accepted=0 fallback=3 invalid=2 no_decision=1 unsupported=0")
  fk.qInfo("[tqs_qa_malformed_reply] command=TqsQaUnsupported total=1 accepted=0 fallback=1 invalid=0 no_decision=0 unsupported=1")
end

-- The synthetic 44-case test above proves the dispatcher classification but
-- controls feasible() itself. Exercise the four actual request-handler classes
-- here with the native room, real scene setup and real skill feasibility.
-- Keep the negative metrics detached from gameplay and restore the ambient
-- handler after each case. Never log payloads, card ids or player ids.
aiTraceEngineState = function(room)
  local parts = {
    aiTraceStable(room.draw_pile), aiTraceStable(room.discard_pile),
    aiTraceStable(room.processing_area), aiTraceStable(room.owner_map),
    aiTraceStable(room.card_place),
    tostring(room.current and aiTraceSeat(room, room.current) or 0),
    tostring(room.logic and room.logic.all_game_events and #room.logic.all_game_events or 0),
  }
  for _, player in ipairs(room.players) do
    parts[#parts + 1] = aiTraceStable({
      hp = player.hp, maxHp = player.maxHp, dead = player.dead,
      phase = player.phase, role = player.role,
      general = player.general, deputy = player.deputyGeneral,
      marks = player.mark, cards = player.player_cards,
      special = player.special_cards,
      skillHistory = player.skillUsedHistory,
      cardHistory = player.cardUsedHistory,
    })
  end
  return table.concat(parts, "|")
end

-- Read the native dispatcher's per-command counters before and after a single
-- reply. Older pinned Base.AI revisions do not expose _ai_last_metric_reason,
-- so those optional instance fields cannot be the sole classification proof.
-- A missing legality-detail counter remains unverified; never infer its value
-- from the test label or from a rejected response alone.
aiTraceReplyMetricSnapshot = function(probe, command)
  local metrics = probe:getResponseMetrics()
  local bucket = metrics.by_command and metrics.by_command[command] or {}
  local function counts(source)
    local result = {}
    for key, value in pairs(source or {}) do
      if type(key) == "string" and type(value) == "number" then
        result[key] = value
      end
    end
    return result
  end
  return {
    total = bucket.total or 0,
    fallback = bucket.fallback or 0,
    reasons = counts(bucket.fallback_reasons),
    details = counts(bucket.invalid_details),
  }
end

aiTraceReplyMetricDelta = function(probe, command, before)
  local after = aiTraceReplyMetricSnapshot(probe, command)
  if after.total ~= before.total + 1 then return "metric_drift", "none" end
  -- Check both maps in both directions. Missing or reset counters, multiple
  -- increments and stale detail attribution must never produce a false PASS.
  local function soleIncrement(earlier, later)
    local added
    for key, count in pairs(earlier) do
      if (later[key] or 0) < count then return nil, false end
    end
    for key, count in pairs(later) do
      local delta = count - (earlier[key] or 0)
      if delta ~= 0 then
        if delta ~= 1 or added then return nil, false end
        added = key
      end
    end
    return added, true
  end
  local reason, reasonOk = soleIncrement(before.reasons, after.reasons)
  local detail, detailOk = soleIncrement(before.details, after.details)
  if not reasonOk or not detailOk then return "metric_drift", "none" end
  if after.fallback == before.fallback then
    if reason or detail then return "metric_drift", "none" end
    return "accepted", "none"
  end
  if after.fallback ~= before.fallback + 1 or not reason then
    return "metric_drift", "none"
  end
  if reason ~= "illegal_reply" and detail then return "metric_drift", "none" end
  return reason, detail or "none"
end

local function runAiRealHandlerReplyProbe(room, state)
  local requestSnapshots = state.prompt4RequestSnapshots or {}
  local commands = {
    { name = "AskForUseActiveSkill", snapshot = "tianyi" },
    { name = "AskForUseCard", snapshot = "kanpo" },
    { name = "AskForResponseCard", snapshot = "aocai" },
    { name = "PlayCard", snapshot = "play_card" },
  }
  -- This equality compares internal engine state, never logs its contents.
  -- In particular card ownership, private hand ids, marks and event history
  -- must survive a rejected reply without a transition or an emitted event.
  local tags = {}
  local isolated = { request_handlers = {} }
  function isolated:getTag(key) return tags[key] end
  function isolated:setTag(key, value) tags[key] = value end
  function isolated:getPlayerById(id) return room:getPlayerById(id) end
  function isolated:getSettings() return room:getSettings() end
  local probe = SmartAI:new(state.actor)
  probe.room = isolated
  local reply, fallbackReason
  local lastHandler
  local function injectedReply(self)
    lastHandler = self.handler
    if fallbackReason then self:markFallback(fallbackReason) end
    return reply
  end
  local originalCurrentHandler = room.current_request_handler
  local observed = 0
  local rejected = 0
  local failed = 0
  local ok, probeError = xpcall(function()
    for _, spec in ipairs(commands) do
      local command = spec.name
      local snapshot = requestSnapshots[spec.snapshot]
      if command ~= "PlayCard" and (not snapshot or snapshot.command ~= command or
          type(snapshot.data) ~= "table") then
        fail("real handler request snapshot missing: " .. spec.snapshot)
      end
      local handlerClass = room.request_handlers and room.request_handlers[command]
      if not (handlerClass and type(handlerClass.new) == "function" and
          type(handlerClass.feasible) == "function") then
        fail("real handler missing for " .. command)
      end
      isolated.request_handlers[command] = handlerClass
      probe["handle" .. command] = injectedReply
      local function check(label, value, reason, detail)
        probe.command, probe.data = command, snapshot and snapshot.data or nil
        reply, fallbackReason = value, label == "no_strategy" and "no_strategy" or nil
        lastHandler = nil
        local previousPattern = Fk.currentResponsePattern
        local previousCurrent = room.current
        if snapshot and snapshot.outOfTurn and room.current == state.actor then
          room:setCurrent(room.players[2])
        end
        Fk.currentResponsePattern = snapshot and snapshot.pattern or nil
        local before = aiTraceEngineState(room)
        local beforeMetric = aiTraceReplyMetricSnapshot(probe, command)
        local makeOk, actual = pcall(probe.makeReply, probe)
        local after = aiTraceEngineState(room)
        local actualReason, actualDetail = aiTraceReplyMetricDelta(probe, command, beforeMetric)
        Fk.currentResponsePattern = previousPattern
        if room.current ~= previousCurrent then room:setCurrent(previousCurrent) end
        room.current_request_handler = originalCurrentHandler
        if not makeOk then fail("real handler makeReply raised an exception: " .. command) end
        if not lastHandler or type(lastHandler.feasible) ~= "function" then
          fail("real handler was not initialized for " .. command)
        end
        local result = actual == "__cancel" and "cancel" or type(actual)
        local classificationOk = result == "cancel" and actualReason == reason and
          actualDetail == (detail or "none")
        local unchanged = before == after
        if not classificationOk then
          fk.qInfo(string.format(
            "[tqs_qa_real_handler_diagnostic] snapshot=%s command=%s error=%s actual=%s reason=%s detail=%s",
            aiTraceToken(spec.snapshot), aiTraceToken(command), aiTraceToken(label),
            aiTraceToken(result), aiTraceToken(actualReason), aiTraceToken(actualDetail)))
          failed = failed + 1
        end
        if not unchanged then
          fail("real handler changed engine state " .. command .. "/" .. label)
        end
        rejected = rejected + 1
        fk.qInfo(string.format(
          "[tqs_qa_real_handler_case] schema=3 scenario=%s seed=%u snapshot=%s command=%s error=%s expected_reply=cancel observed_reply=%s expected_reason=%s observed_reason=%s expected_detail=%s observed_detail=%s classification=%s rejected=1 state_unchanged=1",
          state.scenario, state.seed, spec.snapshot, command, label, aiTraceToken(result), reason,
          aiTraceToken(actualReason), detail or "none", aiTraceToken(actualDetail),
          classificationOk and "pass" or "fail"))
        observed = observed + 1
      end
      check("malformed_non_nil", { card = "forged", targets = {} }, "invalid_reply")
      -- This card lacks the required selected subcard. Each concrete handler
      -- must reject the otherwise structurally well-formed non-nil reply.
      check("infeasible_non_nil", {
        card = { skill = "hs__kurou", subcards = {} }, targets = {},
      }, "illegal_reply", "feasibility_rejected")
      check("no_strategy", nil, "no_strategy")
      check("no_decision", nil, "no_decision")
    end
    -- Unsupported handlers are classified by the same native dispatcher;
    -- they cannot initialize a request handler or mutate the game state.
    local before = aiTraceEngineState(room)
    local beforeMetric = aiTraceReplyMetricSnapshot(probe, "TqsQaUnsupported")
    probe.command, probe.data = "TqsQaUnsupported", {}
    local unsupported = probe:makeReply()
    local reason, detail = aiTraceReplyMetricDelta(probe, "TqsQaUnsupported", beforeMetric)
    if aiTraceEngineState(room) ~= before then
      fail("real handler unsupported command classification/state drift")
    end
    local unsupportedOk = unsupported == "__cancel" and reason == "unsupported_command" and detail == "none"
    if not unsupportedOk then
      failed = failed + 1
    end
    observed = observed + 1
    rejected = rejected + 1
    fk.qInfo(string.format(
      "[tqs_qa_real_handler_case] schema=3 scenario=%s seed=%u snapshot=unsupported command=TqsQaUnsupported error=unsupported expected_reply=cancel observed_reply=%s expected_reason=unsupported_command observed_reason=%s expected_detail=none observed_detail=%s classification=%s rejected=1 state_unchanged=1",
      state.scenario, state.seed, unsupported == "__cancel" and "cancel" or type(unsupported),
      aiTraceToken(reason), aiTraceToken(detail), unsupportedOk and "pass" or "fail"))
  end, function() return "real_handler_probe_failed" end)
  room.current_request_handler = originalCurrentHandler
  if not ok then fail("real handler native probe failed: " .. tostring(probeError)) end
  local metrics = probe:getResponseMetrics()
  local reasons = metrics.fallback_reasons or {}
  local details = metrics.invalid_details or {}
  if failed > 0 then fail("real native handler classification mismatches: " .. tostring(failed)) end
  if observed ~= 17 or rejected ~= observed or metrics.total ~= 17 or metrics.fallback ~= 17 or
      metrics.invalid ~= 8 or metrics.no_decision ~= 8 or
      metrics.unsupported ~= 1 or reasons.unsupported_command ~= 1 or
      reasons.invalid_reply ~= 4 or reasons.illegal_reply ~= 4 or
      reasons.no_strategy ~= 4 or reasons.no_decision ~= 4 or
      details.feasibility_rejected ~= 4 then
    fail("real native handler counters drift")
  end
  for _, spec in ipairs(commands) do
    local bucket = metrics.by_command and metrics.by_command[spec.name] or {}
    if bucket.total ~= 4 or bucket.invalid ~= 2 or bucket.no_decision ~= 2 then
      fail("real handler per-command counters drift: " .. spec.name)
    end
  end
  fk.qInfo(string.format(
    "[tqs_qa_real_handler_reply] schema=2 scenario=%s seed=%u native_handlers=4 snapshots=5 cases=%d accepted=0 fallback=17 invalid=8 invalid_reply=4 illegal_reply=4 feasibility_rejected=4 no_strategy=4 no_decision=4 unsupported_command=1 rejected=%d state_unchanged=1",
    state.scenario, state.seed, observed, rejected))
end

-- Exercise the supported initial Hegemony CustomDialog, including the real
-- SmartAI choice for an offered pair and deliberate non-nil malformed replies.
-- This has independent detached-room counters so the established 44-case
-- cross-command probe and the live game denominator retain their identities.
local function runAiSupportedGeneralPairProbe(room, state)
  local Pair = require "ltk.server.ai.general_pair"
  local scenario = state.aiTraceScenario or scenarioById[state.scenario]
  local roster = scenario and scenario.seatRosters and scenario.seatRosters[1]
  if not (SmartAI and roster and Fk.generals[roster.general] and
      Fk.generals[roster.deputy]) then
    fail("supported-dialog native probe prerequisites are unavailable")
  end

  local offer = { component = {
    name = "ChooseInitialGeneralBox",
    model = { name = "ChooseInitialGeneralModel", prop = {
      hegemony = true, choiceNum = 2,
      generals = { roster.general, roster.deputy },
      enabledKingdoms = { "wei", "shu", "wu", "qun" },
    } },
  } }
  local legal = Pair.choose(offer)
  if not legal or Pair.validate(offer, legal) ~= true then
    fail("supported-dialog native probe has no lawful offered general pair")
  end

  local tags = {}
  local isolated = { request_handlers = {} }
  function isolated:getTag(key) return tags[key] end
  function isolated:setTag(key, value) tags[key] = value end
  function isolated:getPlayerById(id) return room:getPlayerById(id) end
  function isolated:getSettings() return nil end

  local probe = SmartAI:new(room.players[1])
  probe.room = isolated
  probe.command = "CustomDialog"
  probe.data = offer
  local cases = 0
  local function check(label, expectedReply, expectedReason)
    local value = probe:makeReply()
    local actualReply = value == "__cancel" and "cancel" or type(value)
    if actualReply ~= expectedReply or
        probe._ai_last_metric_reason ~= expectedReason or
        probe._ai_last_metric_detail ~= "none" then
      fail("supported-dialog native probe classification drift: " .. label)
    end
    if expectedReply == "table" and Pair.validate(probe.data, value) ~= true then
      fail("supported-dialog native probe accepted an illegal general pair")
    end
    cases = cases + 1
  end

  -- Resolve the actual SmartAI CustomDialog strategy on two separate calls.
  check("strategy_legal", "table", "accepted")
  check("strategy_repeat", "table", "accepted")

  local injected, fallbackReason
  probe.handleCustomDialog = function(self)
    if fallbackReason then self:markFallback(fallbackReason) end
    return injected
  end
  local main = legal[1]:match("^([^,]+),")
  injected = { main .. "," .. main, legal[2] }
  check("duplicate_general", "cancel", "invalid_reply")
  injected = { main .. ",tqs_qa_unoffered", legal[2] }
  check("unoffered_general", "cancel", "invalid_reply")
  injected = { legal[1], "kingdom,tqs_qa_disabled" }
  check("disabled_kingdom", "cancel", "invalid_reply")
  injected = "forged"
  check("wrong_reply_type", "cancel", "invalid_reply")
  injected = { legal[1] }
  check("missing_kingdom", "cancel", "invalid_reply")
  injected = legal
  probe.data = { component = { name = "ChooseInitialGeneralBox",
    model = { name = "ChooseInitialGeneralModel", prop = {
      hegemony = true, choiceNum = 2,
      generals = { "tqs_qa_unoffered", roster.deputy },
      enabledKingdoms = { "wei", "shu", "wu", "qun" },
    } } } }
  check("invalid_offer", "cancel", "invalid_reply")
  probe.data = offer
  injected, fallbackReason = nil, "no_strategy"
  check("nil_no_strategy", "cancel", "no_strategy")
  fallbackReason = nil
  check("nil_no_decision", "cancel", "no_decision")

  local metrics = probe:getResponseMetrics()
  local bucket = metrics.by_command and metrics.by_command.CustomDialog or {}
  local reasons = metrics.fallback_reasons or {}
  if cases ~= 10 or metrics.total ~= 10 or metrics.total - metrics.fallback ~= 2 or
      metrics.fallback ~= 8 or metrics.invalid ~= 6 or
      metrics.no_decision ~= 2 or metrics.unsupported ~= 0 or
      bucket.total ~= 10 or bucket.invalid ~= 6 or
      reasons.invalid_reply ~= 6 or reasons.no_strategy ~= 1 or
      reasons.no_decision ~= 1 then
    fail("supported-dialog native probe counter reconciliation failed")
  end
  fk.qInfo(string.format(
    "[tqs_qa_supported_dialog] schema=1 scenario=%s seed=%u cases=%d accepted=2 fallback=8 invalid=6 no_decision=2 unsupported=0 invalid_reply=6 no_strategy=1 no_decision_reason=1 strategy_legal=2",
    state.scenario, state.seed, cases))
end

local function runAiDecisionProbe(room, state)
  if type(SmartAI) ~= "table" or type(SmartAI.new) ~= "function" then
    fail("AI decision probe requires the native SmartAI class")
  end
  if type(AI) ~= "table" then
    fail("AI decision probe requires the native Base.AI class")
  end

  local request_handlers = room.request_handlers
  if type(request_handlers) ~= "table" then
    fail("AI decision probe requires room request handlers")
  end
  local saved_handler = request_handlers.AskForUseActiveSkill
  local saved_get_card_by_id = Fk.getCardById
  local skill_name = next(Fk.skills)
  if type(skill_name) ~= "string" then
    fail("AI decision probe could not find a registered skill")
  end

  local behavior = "accept"
  local dynamic_lookup = false
  local lookup_count = 0
  local handler_class = {}
  function handler_class:new()
    return {
      setup = function() end,
      feasible = function()
        if behavior == "reject" then return false end
        if behavior == "throw" then error("private validator fixture text") end
        return true
      end,
    }
  end

  local probe = SmartAI:new(state.actor)
  probe.room = room
  local response = { card = { skill = skill_name, subcards = {} }, targets = {} }
  function probe:handleAskForUseActiveSkill()
    return response
  end

  local function ask()
    probe.command = "AskForUseActiveSkill"
    probe.data = { "diagnostic_skill", "redacted", true, {} }
    return probe:makeReply()
  end

  local ok, probe_error = xpcall(function()
    Fk.getCardById = function(_, id)
      if id == 765432 then
        lookup_count = lookup_count + 1
        return (not dynamic_lookup or lookup_count == 1) and { id = id } or nil
      end
      return saved_get_card_by_id(Fk, id)
    end

    request_handlers.AskForUseActiveSkill = handler_class
    local replies = {}
    replies[1] = type(ask())
    behavior = "reject"
    replies[2] = ask()
    behavior = "throw"
    replies[3] = ask()
    behavior = "accept"
    response = { card = { skill = skill_name, subcards = {} }, targets = {},
      special_skill = "definitely_missing_skill" }
    replies[4] = ask()
    request_handlers.AskForUseActiveSkill = nil
    response = { card = { skill = skill_name, subcards = {} }, targets = {} }
    replies[5] = ask()
    request_handlers.AskForUseActiveSkill = handler_class
    dynamic_lookup, lookup_count = true, 0
    response = { card = 765432, targets = {} }
    replies[6] = ask()
    dynamic_lookup = false
    response = { card = { skill = skill_name, subcards = {} }, targets = {} }
    local saved_validator = probe.validateReply
    probe.validateReply = function() return false, "illegal_reply" end
    replies[7] = ask()
    probe.validateReply = saved_validator

    local metrics = probe:getResponseMetrics()
    local active = metrics.by_command and metrics.by_command.AskForUseActiveSkill
    if type(active) ~= "table" then
      fail("AI decision probe did not record active-skill metrics")
    end
    local details = active.invalid_details or {}
    if active.total ~= 7 or active.fallback ~= 6 or
        details.feasibility_rejected ~= 1 or details.feasibility_exception ~= 1 or
        details.special_skill_missing ~= 1 or details.missing_handler ~= 1 or
        details.card_lookup_failed ~= 1 or details.unclassified ~= 1 then
      fail("AI decision probe received an unexpected validator classification")
    end
    if replies[1] ~= "table" or replies[2] ~= "__cancel" or
        replies[3] ~= "__cancel" or replies[4] ~= "__cancel" or
        replies[5] ~= "__cancel" or replies[6] ~= "__cancel" or
        replies[7] ~= "__cancel" then
      fail("AI decision probe changed the canonical reply contract")
    end

    local model = "legacy"
    local initial_attitude, attack_attitude, attack_confidence = 0, -1, 1
    local attack_state, attack_benefit = "legacy", 200
    local support_attitude, support_wei, support_protection = 0, 0, false
    if type(probe.getFactionRelation) == "function" then
      model = "candidate"
      local inference_room = { players = {}, logic = { event_recorder = {} } }
      function inference_room:getSettings(key)
        return key == "gameMode" and "new_heg_mode"
      end
      function inference_room:getBanner(key)
        if key == "all_kingdoms" then return { "wei", "shu", "wu", "qun" } end
      end
      function inference_room:getPlayerById(id)
        for _, player in ipairs(self.players) do
          if player.id == id then return player end
        end
      end
      local self_seat = { id = 1, kingdom = "unknown" }
      function self_seat:getMark(key)
        if key == "__heg_kingdom" then return "wei" end
      end
      function self_seat:isFriend(target)
        return target == self_seat or target.kingdom == "wei"
      end
      local revealed_ally = { id = 2, kingdom = "wei", hp = 3 }
      local hidden_enemy = { id = 3, kingdom = "unknown", hp = 3 }
      local hidden_helper = { id = 4, kingdom = "unknown" }
      inference_room.players = { self_seat, revealed_ally, hidden_enemy, hidden_helper }
      local faction_ai = SmartAI:new(self_seat)
      faction_ai.room = inference_room
      local initial = faction_ai:getFactionRelation(hidden_enemy)
      initial_attitude = initial.attitude

      if not GameEvent or not GameEvent.UseCard then
        fail("AI decision probe requires GameEvent.UseCard")
      end
      local events = {}
      inference_room.logic.event_recorder[GameEvent.UseCard] = events
      local function observe(actor, target, true_name)
        table.insert(events, { status = "dead", data = {
          from = actor, tos = { target }, card = { trueName = true_name },
        } })
      end
      for _ = 1, 3 do observe(hidden_enemy, revealed_ally, "slash") end
      local attack = faction_ai:getFactionRelation(hidden_enemy)
      attack_state, attack_attitude, attack_confidence = attack.state, attack.attitude, attack.confidence
      local Logic = require("ltk.server.ai.logic")
      local calculation = Logic:new(faction_ai)
      calculation:setPlayerProperty(hidden_enemy, "hp", 2)
      attack_benefit = calculation.benefit

      for _ = 1, 4 do observe(hidden_helper, revealed_ally, "peach") end
      local support = faction_ai:getFactionRelation(hidden_helper)
      support_attitude = support.attitude
      support_wei = support.probabilities.wei or 0
      support_protection = faction_ai:shouldProtect(hidden_helper)
    end

    fk.qInfo(string.format(
      "[tqs_qa_ai_probe] scenario=%s active_total=%d active_fallback=%d " ..
      "illegal_details=feasibility_rejected:%d,feasibility_exception:%d," ..
      "special_skill_missing:%d,missing_handler:%d,card_lookup_failed:%d," ..
      "unclassified:%d model=%s initial_attitude=%.3f attack_state=%s " ..
      "attack_attitude=%.3f attack_confidence=%.3f attack_benefit=%.3f " ..
      "legacy_damage=200 support_attitude=%.3f support_wei=%.3f protect=%s",
      state.scenario, 7, 6, details.feasibility_rejected or 0,
      details.feasibility_exception or 0, details.special_skill_missing or 0,
      details.missing_handler or 0, details.card_lookup_failed or 0,
      details.unclassified or 0, model, initial_attitude, attack_state,
      attack_attitude, attack_confidence, attack_benefit, support_attitude,
      support_wei, tostring(support_protection)))
  end, function(message)
    return tostring(message)
  end)

  request_handlers.AskForUseActiveSkill = saved_handler
  Fk.getCardById = saved_get_card_by_id
  if not ok then fail("AI decision probe failed: " .. tostring(probe_error)) end
end

-- Exercise the actual SmartAI instances that belong to the four native
-- ServerPlayers.  This is intentionally a direct, bounded makeReply probe:
-- the normal PlayCard Request would enter the full turn loop and make the
-- result depend on unrelated card/phase effects.  The command/data pair is
-- still the same pair assigned by Request before it calls player.ai:makeReply
-- (PlayCard has nil data; the active-skill request has the native four-field
-- payload).  The trace wrapper around each player.ai therefore sees the real
-- faction-aware decision path and the real validator/fallback metrics without
-- exposing private prompt/card/target payloads or starting a random match.
local function runAiTraceProbe(room, state)
  local trace = state.aiTrace
  if not trace then fail("ai-trace was not installed before the native probe") end

  -- Reject a stale or partially installed QA roster before recording any
  -- matched-replay evidence. Never emit the selected generals or card ids.
  local scenario = state.aiTraceScenario or scenarioById[state.scenario]
  if not scenario or type(scenario.seatRosters) ~= "table" then
    fail("ai-trace has no pinned seat roster")
  end
  if #room.players ~= 4 or #scenario.seatRosters ~= 4 or
      type(scenario.fixedHands) ~= "table" or #scenario.fixedHands ~= 4 then
    fail("ai-trace fixture seat count mismatch")
  end
  local seenFixedIds = {}
  for seat, player in ipairs(room.players or {}) do
    local expected = scenario.seatRosters[seat]
    if not expected or player.general ~= expected.general or
        player.deputyGeneral ~= expected.deputy or
        player:getMark("__heg_general") ~= expected.general or
        player:getMark("__heg_deputy") ~= expected.deputy or
        player:getMark("__heg_kingdom") ~= expected.kingdom then
      fail("ai-trace actual seat pair does not match catalog")
    end
    local fixed = state.fixedHands and state.fixedHands[player.id]
    local actual = player:getCardIds(Player.Hand) or {}
    if type(fixed) ~= "table" or #fixed ~= 1 or #actual ~= 1 or
        fixed[1] ~= actual[1] or seenFixedIds[actual[1]] then
      fail("ai-trace fixed hand did not reach the native seat")
    end
    seenFixedIds[actual[1]] = true
    local ok, card = pcall(Fk.getCardById, Fk, actual[1])
    if not ok or not card or not cardMatches(card, scenario.fixedHands[seat]) then
      fail("ai-trace native fixed hand does not match catalog semantics")
    end
  end
  trace.pairVerified = true
  trace.fixedHandsVerified = true

  local function invoke(player, command, data)
    local ai = player.ai
    if not ai or type(ai.makeReply) ~= "function" then
      trace.probeErrors = (trace.probeErrors or 0) + 1
      fk.qWarning(string.format("[tqs_ai_trace] probe_error scenario=%s seat=%d command=%s kind=missing_ai",
        state.scenario, aiTraceSeat(room, player), aiTraceToken(command)))
      return
    end
    local oldCommand, oldData = ai.command, ai.data
    ai.command, ai.data = command, data
    local ok = xpcall(function()
      return ai:makeReply()
    end, function()
      return true
    end)
    ai.command, ai.data = oldCommand, oldData
    if not ok then
      trace.probeErrors = (trace.probeErrors or 0) + 1
      fk.qWarning(string.format("[tqs_ai_trace] probe_error scenario=%s seat=%d command=%s kind=make_reply_exception",
        state.scenario, aiTraceSeat(room, player), aiTraceToken(command)))
    end
  end

  for _, player in ipairs(room.players or {}) do
    invoke(player, "PlayCard", nil)
  end

  -- Lục Tốn + Tôn Quyền is fixed at seat 1 by the catalog.  The request is
  -- intentionally cancelable and has no card payload; it exercises the same
  -- active-skill validator path used by the 42.7% live active-request sample.
  -- A missing strategy or an unavailable card is a recorded, bounded
  -- fallback, not a reason to run an uncontrolled full match.
  local activeSkill = "hs__zhiheng"
  if not Fk.skills[activeSkill] then
    fail("ai-trace active probe skill is not installed: " .. activeSkill)
  end
  invoke(room.players[1], "AskForUseActiveSkill", {
    activeSkill,
    "TQS QA active decision trace",
    true,
    {},
  })

  local commandCounts = {}
  for _, decision in ipairs(trace.decisions) do
    commandCounts[decision.command] = (commandCounts[decision.command] or 0) + 1
  end
  if trace.total ~= #room.players + 1 or #trace.decisions ~= trace.total or
      (commandCounts.PlayCard or 0) ~= #room.players or
      (commandCounts.AskForUseActiveSkill or 0) ~= 1 then
    fail("ai-trace did not capture every fixed-seat PlayCard and active-skill decision")
  end
  for seat = 1, #room.players do
    local decision = trace.decisions[seat]
    if decision.seat ~= seat or decision.command ~= "PlayCard" or
        not string.match(decision.input, "^[0-9a-f]+$") then
      fail("ai-trace PlayCard seat order or input fingerprint mismatch")
    end
  end
  if trace.decisions[5].seat ~= 1 or trace.decisions[5].command ~= "AskForUseActiveSkill" or
      not string.match(trace.decisions[5].input, "^[0-9a-f]+$") then
    fail("ai-trace active-skill seat or input fingerprint mismatch")
  end
  fk.qInfo(string.format("[tqs_ai_trace] probe_complete scenario=%s seed=%u revision=%s decisions=%d probe_errors=%d",
    state.scenario, state.seed, state.revision, trace.total, trace.probeErrors or 0))
end

-- Run the selected Prompt 4 skills through the native request handlers after
-- the legacy five-decision ai-trace has completed.  This is intentionally a
-- separate trace: the old parser remains a strict five-request contract,
-- while this probe records one deterministic request per selected skill.
-- Every request below reaches the real player.ai:makeReply(), real LTK
-- strategy lookup and real handler feasibility validation.  Only hashes,
-- reply shapes, allowlisted skill names and bounded counters are emitted.
local function runPrompt4NativeProbe(room, state)
  local scenario = state.aiTraceScenario or scenarioById[state.scenario]
  if not scenario or type(scenario.prompt4Skills) ~= "table" or #scenario.prompt4Skills ~= 18 then
    fail("ai-trace Prompt 4 skill fixture drift")
  end
  if not state.aiTrace then fail("ai-trace Prompt 4 probe has no base trace") end
  if prompt4EffectReplaySkill then
    if not prompt4EffectReplayProfile then
      fail("ai-trace Prompt 4 effect replay skill is not allowlisted")
    end
    if not table.contains(scenario.prompt4Skills, prompt4EffectReplaySkill) then
      fail("ai-trace Prompt 4 effect replay skill is not in the catalog")
    end
  end
  preparePrompt4Fixture(room, state)
  state.aiTrace.capture = false

  local trace = {
    decisions = {}, total = 0, opportunities = 0, accepted = 0, acted = 0,
    misses = 0, fallback = 0, invalid = 0, errors = 0,
    pairVerified = true, stateVerified = true, fixtureVerified = true,
    emitted = false,
    effectReplay = {
      requestedSkill = prompt4EffectReplaySkill or "disabled",
      attempted = false,
      accepted = false,
      handled = false,
      skillEffects = 0,
      observedSkillEffects = 0,
      observedSkillNames = {},
      fake = false,
      errors = 0,
      beforeHp = 0,
      afterHp = 0,
      hpDelta = 0,
      beforeHand = 0,
      afterHand = 0,
      handDelta = 0,
      beforeTargetHp = 0,
      afterTargetHp = 0,
      targetHpDelta = 0,
      beforeTargetHand = 0,
      afterTargetHand = 0,
      targetHandDelta = 0,
      beforeTargetHandTotal = 0,
      afterTargetHandTotal = 0,
      targetHandTotalDelta = 0,
      targetSkill = false,
      targetCount = 0,
      targetPolicy = prompt4EffectReplayProfile and
        prompt4EffectReplayProfile.targetPolicy or "reply",
      actorPolicy = prompt4EffectReplayProfile and
        prompt4EffectReplayProfile.actorPolicy or "reply",
      targetRetargeted = false,
      resourceRetargeted = false,
      resourceRetargetError = false,
      replyCardCount = 0,
      nestedRequests = 0,
      nestedFallback = 0,
      nestedInvalid = 0,
      nestedMetricErrors = 0,
      nestedMetricSummary = "",
      profileReason = prompt4EffectReplayProfile and prompt4EffectReplayProfile.reason or "disabled",
    },
  }
  state.prompt4Trace = trace
  state.prompt4EffectReplay = trace.effectReplay
  state.prompt4RequestSnapshots = {
    play_card = { command = "PlayCard" },
  }

  local actor = state.actor
  local enemy = room.players[2]
  local ally = room.players[4]
  local activePrompt = "TQS QA Prompt4 native skill trace"

  -- Response/nullification requests expose skill buttons from the actor's
  -- actual skill set. The fixed roster intentionally covers the common
  -- active-skill path and does not own these two response skills, so attach
  -- only the missing skills as QA-only fake skills before constructing the
  -- real native handlers. This room ends immediately after the bounded
  -- probe; production gameplay and the public package are unaffected.
  for _, skillName in ipairs({ "kanpo", "aocai" }) do
    if not actor:hasSkill(skillName, true) then
      room:addFakeSkill(actor, skillName)
    end
  end

  local function activeData(skill, extra)
    return { skill, activePrompt, true, extra or {} }
  end

  local function responseData(pattern, extra)
    return { nil, pattern, activePrompt, true, extra or {} }
  end

  local cases = {
    { skill = "tianyi", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("tianyi") },
    { skill = "shangyi", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("shangyi") },
    { skill = "tiaoxin", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("tiaoxin") },
    { skill = "hs__zhiheng", command = "AskForUseActiveSkill", expectedTargetProfile = "none", data = activeData("hs__zhiheng") },
    { skill = "hs__kurou", command = "AskForUseActiveSkill", expectedTargetProfile = "none", data = activeData("hs__kurou") },
    { skill = "hs__qiangxi", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("hs__qiangxi") },
    { skill = "hs__longdan", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", responsePattern = "slash", data = activeData("hs__longdan") },
    { skill = "hs__luanji", command = "AskForUseActiveSkill", expectedTargetProfile = "mixed", data = activeData("hs__luanji") },
    { skill = "hs__wusheng", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("hs__wusheng") },
    { skill = "huoji", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("huoji") },
    { skill = "jijiu", command = "AskForUseActiveSkill", expectedTargetProfile = "none", data = activeData("jijiu", { must_targets = { ally.id } }) },
    { skill = "kanpo", command = "AskForUseCard", expectedTargetProfile = "none", responsePattern = "nullification", data = responseData("nullification", {
      effectFrom = enemy.id, effectTo = ally.id, effectCardId = state.prompt4Cards.high,
    }) },
    { skill = "aocai", command = "AskForResponseCard", expectedTargetProfile = "none", responsePattern = ".|.|.|.|.|basic", requiresOutOfTurn = true, data = responseData(".|.|.|.|.|basic") },
    { skill = "beizhu", command = "AskForUseActiveSkill", expectedTargetProfile = "enemy", data = activeData("beizhu") },
    { skill = "dimeng", command = "AskForUseActiveSkill", expectedTargetProfile = "mixed", data = activeData("dimeng") },
    { skill = "choufa", command = "AskForUseActiveSkill", expectedTargetProfile = "ally", data = activeData("choufa") },
    { skill = "cunsi", command = "AskForUseActiveSkill", expectedTargetProfile = "ally", data = activeData("cunsi") },
    { skill = "duanfa", command = "AskForUseActiveSkill", expectedTargetProfile = "none", data = activeData("duanfa") },
  }
  for index, item in ipairs(cases) do
    if item.skill ~= scenario.prompt4Skills[index] then
      fail("ai-trace Prompt 4 case order drift at " .. tostring(index))
    end
  end

  local function enabledOffers(handler)
    local cards, targets = 0, 0
    local exactOffers = {}
    if handler and handler.scene and type(handler.scene.getAllItems) == "function" then
      for _, item in pairs(handler.scene:getAllItems("CardItem") or {}) do
        if item.enabled then cards = cards + 1 end
      end
      for _, item in pairs(handler.scene:getAllItems("Photo") or {}) do
        if item.enabled then targets = targets + 1 end
      end
      for _, kind in ipairs({ "CardItem", "Photo", "SkillButton" }) do
        for key, item in pairs(handler.scene:getAllItems(kind) or {}) do
          if item.enabled then exactOffers[#exactOffers + 1] = kind .. ":" .. tostring(key) end
        end
      end
    end
    table.sort(exactOffers)
    return cards, targets, table.concat(exactOffers, "|")
  end

  local function requestOffers(command, data, skillName)
    local handlerClass = room.request_handlers and room.request_handlers[command]
    if not handlerClass then return 0, 0, false, nil end
    local ok, handler = xpcall(function()
      local value = handlerClass:new(actor, data)
      value:setup()
      if (command == "AskForUseCard" or command == "AskForResponseCard") and skillName then
        value:update("SkillButton", skillName, "click", { selected = true })
      end
      return value
    end, function() return nil end)
    if not ok or not handler then return 0, 0, false, nil end
    local cards, targets, exactOffers = enabledOffers(handler)
    pcall(function() handler:finish() end)
    return cards, targets, true, exactOffers
  end

  local function traceRequestData(item)
    local normalized = { skill = item.skill, active = true }
    if item.skill == "jijiu" then
      normalized.target = "ally"
    elseif item.skill == "kanpo" then
      normalized.from = "enemy"
      normalized.to = "ally"
      normalized.effect = "high-card"
    end
    return normalized
  end

  local function metricBucket(command)
    local metrics = room:getTag("__ai_response_metrics")
    return metrics and metrics.by_command and metrics.by_command[command] or nil
  end

  local function metricCount(bucket, key)
    return bucket and tonumber(bucket[key] or 0) or 0
  end

  local function actedReply(reply)
    if type(reply) ~= "table" then return false end
    if type(reply.targets) == "table" and #reply.targets > 0 then return true end
    if type(reply.card) == "number" then return true end
    if type(reply.card) == "table" and type(reply.card.subcards) == "table" and #reply.card.subcards > 0 then
      return true
    end
    return reply.interaction_data ~= nil
  end

  local effectReplayItem
  local effectReplayReply
  local nativeLegalityChecked = 0

  -- A native handler may return a reply via doOKButton with an identity-based
  -- fast path. Rebuild its handler and independently revalidate a fresh reply
  -- object, including the real selected targets and material-card ownership.
  local function verifyNativeLegality(item, reply, reportCoverage)
    local handlerClass = room.request_handlers and room.request_handlers[item.command]
    if not handlerClass then fail("tactical native handler unavailable") end
    local before = aiTraceEngineState(room)
    local oldHandler, oldReply = actor.ai.handler, actor.ai._last_ai_reply
    local oldValidationDetail = actor.ai._ai_validation_detail
    local copy = {}
    for key, value in pairs(reply) do copy[key] = value end
    local handler
    local ok, valid = pcall(function()
      handler = handlerClass:new(actor, item.data)
      handler:setup()
      actor.ai.handler, actor.ai._last_ai_reply = handler, nil
      return actor.ai:validateReply(item.command, item.data, copy)
    end)
    actor.ai.handler, actor.ai._last_ai_reply = oldHandler, oldReply
    actor.ai._ai_validation_detail = oldValidationDetail
    if handler then pcall(function() handler:finish() end) end
    if aiTraceEngineState(room) ~= before then
      fail("tactical legality revalidation mutated native engine state: " .. item.skill)
    end
    if not ok or valid ~= true then fail("tactical native feasibility rejected accepted reply: " .. item.skill) end
    local card = reply.card
    local selected = type(card) == "number" and { card } or
      type(card) == "table" and card.subcards or {}
    local seen = {}
    for _, id in ipairs(selected) do
      if type(id) ~= "number" or seen[id] then
        fail("tactical reply selected duplicate/invalid resource: " .. item.skill)
      end
      seen[id] = true
      local owner, area = room:getCardOwner(id), room:getCardArea(id)
      local actorOwns = owner == actor and
        (area == Card.PlayerHand or area == Card.PlayerEquip)
      -- Ao Cai's native view-as exposes only the two top draw-pile cards;
      -- its selected resource is not owned by the responding player.  Check
      -- the exact source-law offer, not an assumed card_area bookkeeping enum.
      local aocaiPile = false
      if item.skill == "aocai" then
        local top = room.draw_pile or {}
        local resource = Fk:getCardById(id)
        aocaiPile = (top[1] == id or top[2] == id) and
          resource ~= nil and resource.type == Card.TypeBasic
      end
      if not actorOwns and not aocaiPile then
        if item.skill == "aocai" then
          local inPile = table.contains(room.draw_pile or {}, id)
          local physical = Fk:getCardById(id)
          fk.qInfo(string.format("[tqs_prompt4_legality_diagnostic] skill=aocai top_two=%s in_draw_pile=%s basic=%s area_draw=%s area_processing=%s area_void=%s area_discard=%s area_hand=%s area_equip=%s original_top=%s owner_actor=%s owner_other=%s actor_owns=%s",
            tostring((room.draw_pile or {})[1] == id or (room.draw_pile or {})[2] == id),
            tostring(inPile), tostring(physical ~= nil and physical.type == Card.TypeBasic),
            tostring(area == Card.DrawPile), tostring(area == Card.Processing),
            tostring(area == Card.Void), tostring(area == Card.DiscardPile),
            tostring(area == Card.PlayerHand), tostring(area == Card.PlayerEquip),
            tostring(table.contains(state.prompt4AocaiTop or {}, id)),
            tostring(owner == actor), tostring(owner ~= nil and owner ~= actor), tostring(actorOwns)))
        end
        fail("tactical reply selected a resource outside legal native zones: " .. item.skill)
      end
    end
    for _, id in ipairs(reply.targets or {}) do
      local target = room:getPlayerById(id)
      if not target or not target:isAlive() then
        fail("tactical reply selected invalid/dead native target: " .. item.skill)
      end
    end
    local targetProfile = aiTraceReplyTargetProfile(room, actor, reply)
    if targetProfile ~= item.expectedTargetProfile then
      fail("tactical native reply targeted a different faction profile: " .. item.skill)
    end
    if reportCoverage ~= false then
      nativeLegalityChecked = nativeLegalityChecked + 1
      fk.qInfo(string.format(
        "[tqs_prompt4_legality] schema=1 scenario=%s seed=%u skill=%s command=%s handler_feasible=1 resources_legal=1 targets_legal=1 target_faction_expected=1 state_unchanged=1 target_profile=%s selected_cards=%d selected_targets=%d",
        state.scenario, state.seed, aiTraceToken(item.skill),
        aiTraceToken(item.command), targetProfile,
        #selected, #(reply.targets or {})))
    end
  end

  local function invoke(item, index)
    local oldCommand, oldData = actor.ai.command, actor.ai.data
    local previousPattern = Fk.currentResponsePattern
    local previousCurrent
    if item.requiresOutOfTurn and room.current == actor then
      -- Ao Cai is legally a response-only skill: the real source law rejects
      -- it while its owner is the current player.  The bounded synthetic
      -- request must therefore model the out-of-turn context that exists
      -- when an opponent's card asks this player to respond.
      previousCurrent = room.current
      room:setCurrent(enemy)
    end
    actor.ai.command, actor.ai.data = item.command, item.data
    Fk.currentResponsePattern = item.responsePattern
    local cards, targets, offerOk = requestOffers(item.command, item.data, item.skill)
    if item.skill == "tianyi" or item.skill == "kanpo" or item.skill == "aocai" then
      state.prompt4RequestSnapshots[item.skill] = {
        command = item.command, data = item.data, pattern = item.responsePattern,
        outOfTurn = item.requiresOutOfTurn == true,
      }
    end
    local input = aiTraceInputFingerprint(actor.ai, traceRequestData(item))
    local opportunity = cards > 0 or targets > 0
    if opportunity then trace.opportunities = trace.opportunities + 1 end
    if not offerOk then trace.errors = trace.errors + 1 end

    local beforeMetric = aiTraceReplyMetricSnapshot(actor.ai, item.command)
    local before = metricBucket(item.command)
    local beforeTotal = metricCount(before, "total")
    local beforeFallback = metricCount(before, "fallback")
    local beforeInvalid = metricCount(before, "invalid")
    local ok, reply = xpcall(function() return actor.ai:makeReply() end, function() return nil end)
    local measuredReason, measuredDetail = aiTraceReplyMetricDelta(actor.ai, item.command, beforeMetric)
    Fk.currentResponsePattern = previousPattern
    local after = metricBucket(item.command)
    local totalDelta = metricCount(after, "total") - beforeTotal
    local fallbackDelta = metricCount(after, "fallback") - beforeFallback
    local invalidDelta = metricCount(after, "invalid") - beforeInvalid
    if not ok or totalDelta ~= 1 or measuredReason == "metric_drift" or
        fallbackDelta < 0 or fallbackDelta > 1 or
        invalidDelta < 0 or invalidDelta > 1 then
      trace.errors = trace.errors + 1
    end
    local accepted = ok and measuredReason == "accepted" and type(reply) == "table"
    if accepted then verifyNativeLegality(item, reply) end
    local acted = accepted and actedReply(reply) or false
    local reason = aiTraceToken(measuredReason)
    local detail = aiTraceToken(measuredDetail)
    if accepted then trace.accepted = trace.accepted + 1 end
    if acted then trace.acted = trace.acted + 1 end
    if opportunity and not acted then trace.misses = trace.misses + 1 end
    if fallbackDelta > 0 then trace.fallback = trace.fallback + 1 end
    if invalidDelta > 0 then trace.invalid = trace.invalid + 1 end
    trace.total = trace.total + 1
    local targetProfile = aiTraceReplyTargetProfile(room, actor, reply)
    trace.decisions[#trace.decisions + 1] = {
      seq = index, skill = item.skill, command = aiTraceToken(item.command), input = input,
      offer = aiTraceHash(table.concat({ item.skill, tostring(cards), tostring(targets), aiTraceCardShape(actor:getCardIds(Player.Hand)) }, "|")),
      opportunity = opportunity, offeredCards = cards, offeredTargets = targets,
      accepted = accepted, acted = acted, invalid = invalidDelta > 0,
      output = aiTraceReplyShape(reply), reason = reason, detail = detail,
      targetProfile = targetProfile,
      cardProfile = aiTraceReplyCardProfile(reply),
      resourceShape = aiTraceReplyResourceShape(reply),
      resourceValue = aiTraceReplyResourceValue(actor, reply),
      selectedCards = aiTraceReplyCardCount(reply),
      selectedTargets = aiTraceReplyTargetCount(reply),
      targetQuality = aiTraceTargetQuality(targetProfile, item.expectedTargetProfile, acted),
    }
    if item.skill == prompt4EffectReplaySkill then
      effectReplayItem = item
      effectReplayReply = reply
      trace.effectReplay.accepted = accepted
    end
    actor.ai.command, actor.ai.data = oldCommand, oldData
    if previousCurrent then room:setCurrent(previousCurrent) end
  end

  for index, item in ipairs(cases) do invoke(item, index) end
  if trace.total ~= #scenario.prompt4Skills or #trace.decisions ~= trace.total then
    fail("ai-trace Prompt 4 did not capture all eighteen native requests")
  end
  for _, decision in ipairs(trace.decisions) do
    fk.qInfo(string.format(
      "[tqs_prompt4_legality_coverage] schema=1 scenario=%s seed=%u skill=%s command=%s accepted=%d acted=%d reason=%s detail=%s offered_cards=%d offered_targets=%d",
      state.scenario, state.seed, aiTraceToken(decision.skill),
      aiTraceToken(decision.command), decision.accepted and 1 or 0,
      decision.acted and 1 or 0, aiTraceToken(decision.reason),
      aiTraceToken(decision.detail), decision.offeredCards, decision.offeredTargets))
  end
  -- Both request-safety probes require the fully prepared Prompt4 fixture and
  -- its real request snapshots. Run them before the independent P2 gate.
  runAiRealHandlerReplyProbe(room, state)
  runAiMalformedReplyProbe(room, state)
  if nativeLegalityChecked ~= 18 then fail("native tactical legality coverage drift") end
  fk.qInfo(string.format(
    "[tqs_prompt4_legality] summary schema=1 scenario=%s seed=%u decisions=18 handler_feasible=18 resources_legal=18 targets_legal=18 target_faction_expected=18 state_unchanged=18",
    state.scenario, state.seed))

  -- Run each live Prompt4 request again against matched private-hand variants.
  -- Both opponents retain the exact same hand count and every public object,
  -- request payload and selectable native CardItem/Photo/SkillButton. The
  -- internal ownership map changes with the two concealed cards and is then
  -- restored exactly. Never serialize the cards, identities or raw replies.
  local function nativePrivacyDifferential()
    local left, right = room.players[2], room.players[3]
    local leftHand, rightHand = left and left.player_cards[Player.Hand],
      right and right.player_cards[Player.Hand]
    if not leftHand or not rightHand or #leftHand == 0 or #rightHand == 0 then
      fail("privacy differential needs two distinct opponent private hands")
    end
    local leftIndex, rightIndex
    for i, leftId in ipairs(leftHand) do
      for j, rightId in ipairs(rightHand) do
        if aiTraceCardShape({ leftId }) ~= aiTraceCardShape({ rightId }) then
          leftIndex, rightIndex = i, j
          break
        end
      end
      if leftIndex then break end
    end
    if not leftIndex then fail("privacy differential has no semantically distinct hidden cards") end
    local leftCard, rightCard = leftHand[leftIndex], rightHand[rightIndex]
    local originalMetrics = room:getTag("__ai_response_metrics")
    local originalReasons = room:getTag("__tqs_prompt4_request_reasons")
    local originalCommand, originalData = actor.ai.command, actor.ai.data
    local originalPattern, originalCurrent = Fk.currentResponsePattern, room.current
    local swapped = false

    local function swapHands()
      leftHand[leftIndex], rightHand[rightIndex] = rightHand[rightIndex], leftHand[leftIndex]
      if swapped then
        room:setCardArea(leftCard, Card.PlayerHand, left.id)
        room:setCardArea(rightCard, Card.PlayerHand, right.id)
      else
        room:setCardArea(leftCard, Card.PlayerHand, right.id)
        room:setCardArea(rightCard, Card.PlayerHand, left.id)
      end
      swapped = not swapped
    end
    local function publicState(item)
      -- Construct the *observable* projection. The generic AI input
      -- fingerprint intentionally contains __heg_general/__heg_deputy private
      -- marks and therefore must not stand in for a public-state fingerprint.
      local public = {
        aiTraceHash(aiTraceStable({ command = item.command, data = item.data,
          responsePattern = item.responsePattern })),
        tostring(aiTraceSeat(room, room.current)),
      }
      for _, candidate in ipairs(room.players) do
        local shownMarks, specialCounts = {}, {}
        for mark, value in pairs(candidate.mark or {}) do
          -- Visible '@' counters are included; private __heg_* identities
          -- and internal marks never enter this projection.
          if type(mark) == "string" and mark:sub(1, 1) == "@" then
            shownMarks[mark] = value
          end
        end
        for pile, ids in pairs(candidate.special_cards or {}) do
          if type(ids) == "table" then specialCounts[pile] = #ids end
        end
        public[#public + 1] = aiTraceStable({
          hp = candidate.hp, maxHp = candidate.maxHp, dead = candidate.dead,
          phase = candidate.phase,
          role = candidate.role_shown and candidate.role or "hidden",
          general = candidate.general, deputy = candidate.deputyGeneral,
          marks = shownMarks,
          handCount = #(candidate:getCardIds(Player.Hand) or {}),
          equip = candidate.player_cards[Player.Equip],
          judge = candidate.player_cards[Player.Judge],
          specialCounts = specialCounts,
        })
      end
      return table.concat(public, "|")
    end
    local privacyFail
    local function trial(item)
      local previousCurrent = room.current
      actor.ai.command, actor.ai.data = item.command, item.data
      Fk.currentResponsePattern = item.responsePattern
      if item.requiresOutOfTurn and room.current == actor then room:setCurrent(enemy) end
      -- Allocate detached metrics, then restore the original live accumulator.
      -- Do not let 90 negative-control decisions inflate the 25 live requests.
      room:setTag("__ai_response_metrics", nil)
      room:setTag("__tqs_prompt4_request_reasons", nil)
      local before = aiTraceEngineState(room)
      local _, _, offerOk, exactOffers = requestOffers(item.command, item.data, item.skill)
      if not offerOk then
        privacyFail(item, "offer_unavailable", "privacy differential real handler offer unavailable")
      end
      if aiTraceEngineState(room) ~= before then
        privacyFail(item, "offer_mutated_state", "privacy differential handler offer construction mutated engine state")
      end
      local beforeMetric = aiTraceReplyMetricSnapshot(actor.ai, item.command)
      local reply = actor.ai:makeReply()
      local reason = aiTraceReplyMetricDelta(actor.ai, item.command, beforeMetric)
      if reason ~= "accepted" or type(reply) ~= "table" then
        privacyFail(item, "decision_rejected", "privacy differential native decision was rejected")
      end
      -- A privacy-invariant but illegal action would still be a P2 failure.
      -- Revalidate every A1/A2/B1/B2/A3 candidate on its own native state.
      verifyNativeLegality(item, reply, false)
      if aiTraceEngineState(room) ~= before then
        privacyFail(item, "decision_mutated_state", "privacy differential decision mutated engine state")
      end
      local result = { public = publicState(item), offers = exactOffers,
        reply = aiTraceStable(reply) }
      if previousCurrent and room.current ~= previousCurrent then room:setCurrent(previousCurrent) end
      room:setTag("__ai_response_metrics", originalMetrics)
      room:setTag("__tqs_prompt4_request_reasons", originalReasons)
      return result
    end
    local function privacyDiagnostic(item, stage)
      fk.qInfo(string.format(
        "[tqs_prompt4_privacy_diagnostic] schema=1 scenario=%s seed=%u skill=%s command=%s stage=%s",
        state.scenario, state.seed, aiTraceToken(item.skill), aiTraceToken(item.command), aiTraceToken(stage)))
    end
    privacyFail = function(item, stage, message)
      privacyDiagnostic(item, stage)
      fail(message)
    end
    local casesChecked = 0
    local ok = xpcall(function()
      for _, item in ipairs(cases) do
        local baselineState = aiTraceEngineState(room)
        local a1, a2 = trial(item), trial(item)
        if a1.reply ~= a2.reply or a1.offers ~= a2.offers or
            a1.public ~= a2.public then
          privacyFail(item, "baseline_nondeterministic", "privacy differential baseline is nondeterministic: " .. item.skill)
        end
        swapHands()
        local changedState = aiTraceEngineState(room)
        if changedState == baselineState then
          privacyFail(item, "hidden_state_unchanged", "privacy differential hidden state was not changed")
        end
        local b1, b2 = trial(item), trial(item)
        swapHands()
        local a3 = trial(item)
        if aiTraceEngineState(room) ~= baselineState then
          privacyFail(item, "restore_state_mismatch", "privacy differential failed to restore engine state")
        end
        if a1.public ~= b1.public or a1.public ~= b2.public or
            a1.public ~= a3.public or a1.offers ~= b1.offers or
            a1.offers ~= b2.offers or a1.offers ~= a3.offers then
          privacyFail(item, "public_or_offers_mismatch", "privacy differential public state/legal offers mismatch: " .. item.skill)
        end
        if a1.reply ~= a3.reply then
          privacyFail(item, "restored_baseline_drift", "privacy differential restored baseline drift: " .. item.skill)
        end
        if b1.reply ~= b2.reply or a1.reply ~= b1.reply then
          privacyFail(item, "hidden_data_changed_decision", "privacy differential hidden data affected decision: " .. item.skill)
        end
        for _, trialName in ipairs({ "A1", "A2", "B1", "B2", "A3" }) do
          fk.qInfo(string.format(
            "[tqs_prompt4_privacy_trial] schema=2 scenario=%s seed=%u skill=%s command=%s snapshot=%s public_equal=1 offers_equal=1 decision_equal=1 native_legal=1 state_unchanged=1",
            state.scenario, state.seed, aiTraceToken(item.skill),
            aiTraceToken(item.command), trialName))
        end
        casesChecked = casesChecked + 1
        fk.qInfo(string.format(
          "[tqs_prompt4_privacy] schema=1 scenario=%s seed=%u skill=%s command=%s private_variants=2 trials=5 public_equal=1 offers_equal=1 decisions_equal=1 state_restored=1",
          state.scenario, state.seed, aiTraceToken(item.skill), aiTraceToken(item.command)))
      end
    end, function() return "privacy_differential_failed" end)
    -- These restores run even when a strategy throws or a differential fails.
    if swapped then swapHands() end
    room:setTag("__ai_response_metrics", originalMetrics)
    room:setTag("__tqs_prompt4_request_reasons", originalReasons)
    actor.ai.command, actor.ai.data = originalCommand, originalData
    Fk.currentResponsePattern = originalPattern
    if room.current ~= originalCurrent then room:setCurrent(originalCurrent) end
    if not ok then fail("native private-hand differential failed") end
    if casesChecked ~= 18 then fail("native private-hand differential coverage drift") end
    fk.qInfo(string.format(
      "[tqs_prompt4_privacy] summary schema=1 scenario=%s seed=%u decisions=%d variants=2 trials=%d public_equal=1 offers_equal=1 decisions_equal=1 state_restored=1",
      state.scenario, state.seed, casesChecked, casesChecked * 5))
  end
  nativePrivacyDifferential()
  preparePrompt4ReplayResources(room, state)

  -- Apply one explicitly selected, already-accepted AI reply through the
  -- native Room -> useSkill -> SkillEffect path only after all eighteen
  -- request fingerprints have been captured.  This keeps the matched request
  -- matrix unchanged while adding a real downstream assertion for the safe
  -- QA skill selected by the temporary config.
  if prompt4EffectReplaySkill then
    local replay = trace.effectReplay
    replay.attempted = true
    if not effectReplayItem or type(effectReplayReply) ~= "table" or not replay.accepted then
      replay.errors = replay.errors + 1
      fail("ai-trace Prompt 4 effect replay did not receive an accepted reply")
    end
    replay.replyCardCount = aiTraceReplyCardCount(effectReplayReply)
    local function handCount(player)
      if not player or type(player.getCardIds) ~= "function" then return 0 end
      local ids = player:getCardIds(Player.Hand) or {}
      return type(ids) == "table" and #ids or 0
    end
    local replayTargetIds = effectReplayReply.targets or {}
    local effectReplayData = effectReplayItem.data
    local cardRequest = effectReplayItem.command ~= "AskForUseActiveSkill"
    local responseRequest = effectReplayItem.command == "AskForResponseCard"
    local effectReplayExtra = type(effectReplayData[4]) == "table" and effectReplayData[4] or {}
    if cardRequest then
      effectReplayExtra = type(effectReplayData[5]) == "table" and effectReplayData[5] or {}
    end
    if #replayTargetIds == 0 and prompt4EffectReplayProfile.targetFromExtraData then
      replayTargetIds = effectReplayExtra.must_targets or {}
    end
    local replayTargets = {}
    for _, targetId in ipairs(replayTargetIds) do
      local target = type(targetId) == "number" and room:getPlayerById(targetId) or nil
      if target then table.insert(replayTargets, target) end
    end
    if prompt4EffectReplayProfile.targetPolicy == "native_bot" then
      -- The accepted Wusheng reply normally targets the second browser
      -- client. Executing the returned Slash would therefore open a nested
      -- Jink Request that needs a browser driver. Retarget only this
      -- QA-only replay to the first native BOT, so the nested Request still
      -- travels through the real Request -> SmartAI -> feasibility path.
      -- Keep the original accepted target requirement above; this is a
      -- deterministic nested-request policy, not a fabricated reply.
      if #replayTargetIds == 0 then
        fail("ai-trace nested replay received an accepted reply without a target")
      end
      local nativeBotTarget = state.prompt4NativeTarget or table.find(room.players, function(player)
        return player ~= actor and player.id < 0 and player:isAlive()
      end)
      if not nativeBotTarget then
        fail("ai-trace nested replay requires an alive native BOT target")
      end
      replayTargets = { nativeBotTarget }
      replay.targetRetargeted = true
    elseif prompt4EffectReplayProfile.targetPolicy == "native_bot_other" then
      -- Nested active profiles keep both participants native and choose the
      -- second BOT explicitly, so actor/target hand deltas cannot alias one
      -- another.  Shangyi uses this for choice/card selection; Tianyi uses it
      -- for the two sides of a Pindian request.
      if #replayTargetIds == 0 then
        fail("ai-trace Shangyi replay received an accepted reply without a target")
      end
      local firstNativeBot = state.prompt4NativeActor or table.find(room.players, function(player)
        return player.id < 0 and player:isAlive()
      end)
      local nativeBotTarget = state.prompt4NativeTarget or table.find(room.players, function(player)
        return player.id < 0 and player ~= firstNativeBot and player:isAlive()
      end)
      if not firstNativeBot or not nativeBotTarget then
        fail("ai-trace Shangyi replay requires two alive native BOTs")
      end
      replayTargets = { nativeBotTarget }
      replay.targetRetargeted = true
    elseif prompt4EffectReplayProfile.targetPolicy == "native_bot_tiaoxin" then
      -- Tiaoxin's source target filter requires the provoked player to be in
      -- attack range of the replay actor.  Select a distinct native BOT only
      -- when the native server proves that both the source target filter and
      -- the physical Slash can legally reach the actor; never bypass distance
      -- merely to make this downstream proof pass.
      if #replayTargetIds == 0 then
        fail("ai-trace Tiaoxin replay received an accepted reply without a target")
      end
      local firstNativeBot = state.prompt4NativeActor or table.find(room.players, function(player)
        return player.id < 0 and player:isAlive()
      end)
      if not firstNativeBot then
        fail("ai-trace Tiaoxin replay requires an alive native BOT actor")
      end
      local slash = Fk:cloneCard("slash")
      local nativeBotTarget = table.find(room.players, function(player)
        return player.id < 0 and player ~= firstNativeBot and player:isAlive() and
          player:inMyAttackRange(firstNativeBot) and
          player:canUseTo(slash, firstNativeBot, { bypass_times = true })
      end)
      if not nativeBotTarget then
        fail("ai-trace Tiaoxin replay requires a distinct native BOT in Slash range")
      end
      replayTargets = { nativeBotTarget }
      replay.targetRetargeted = true
    end
    local replayActor = actor
    if prompt4EffectReplayProfile.actorPolicy == "native_bot" then
      replayActor = state.prompt4NativeActor or table.find(room.players, function(player)
        return player ~= actor and player.id < 0 and player:isAlive()
      end)
      if not replayActor then
        fail("ai-trace downstream replay requires an alive native BOT actor")
      end
    end
    local targetHandTotal = 0
    for _, target in ipairs(replayTargets) do
      targetHandTotal = targetHandTotal + handCount(target)
    end
    if prompt4EffectReplayProfile.promoteFakeSkill then
      -- The ai-trace roster exposes selected general skills as fake skills so
      -- the request matrix can probe them while the browser pair remains
      -- hidden. Promote only the selected replay skill into a real skill for
      -- this QA-only downstream assertion; hidden-general reveal semantics
      -- are covered by the dedicated hidden-active scenarios.
      local replaySkill = Fk.skills[prompt4EffectReplaySkill]
      if replaySkill and replayActor:isFakeSkill(replaySkill) then
        replayActor:loseFakeSkill(replaySkill)
        room:handleAddLoseSkills(replayActor, prompt4EffectReplaySkill, nil, false, true)
      end
    end
    replay.beforeHp = replayActor.hp
    replay.beforeHand = handCount(replayActor)
    replay.targetCount = #replayTargets
    replay.beforeTargetHandTotal = targetHandTotal
    local replayTarget = replayTargets[1]
    if replayTarget then
      replay.beforeTargetHp = replayTarget.hp
      replay.beforeTargetHand = handCount(replayTarget)
    end
    local nestedMetricBefore = {}
    for _, spec in ipairs(prompt4EffectReplayProfile.nestedMetrics or {}) do
      local bucket = metricBucket(spec.command)
      nestedMetricBefore[spec.command] = {
        total = metricCount(bucket, "total"),
        fallback = metricCount(bucket, "fallback"),
        invalid = metricCount(bucket, "invalid"),
      }
    end
    replay.active = true
    local data = effectReplayData
    local effectReplayReplyForExecution = effectReplayReply
    if prompt4EffectReplayProfile.targetPolicy == "native_bot_other" or
        prompt4EffectReplayProfile.targetPolicy == "native_bot_tiaoxin" or
        prompt4EffectReplayProfile.actorPolicy == "native_bot" then
      -- ActiveSkill replies consume `data.targets` directly in
      -- handleUseCardReply; unlike ViewAsSkill there is no later useResult
      -- object whose `tos` can be replaced. Keep the accepted trace intact
      -- and clone only the QA execution payload for the explicit target
      -- policy above.
      effectReplayReplyForExecution = {}
      for key, value in pairs(effectReplayReply) do
        effectReplayReplyForExecution[key] = value
      end
      effectReplayReplyForExecution.targets = table.map(replayTargets, function(target)
        return target.id
      end)
    end
    if prompt4EffectReplayProfile.actorPolicy == "native_bot" and
        type(effectReplayReplyForExecution.card) == "table" and
        type(effectReplayReplyForExecution.card.subcards) == "table" and
        #effectReplayReplyForExecution.card.subcards > 0 then
      -- The accepted browser-seat reply carries card ids owned by that
      -- browser seat.  A nested native-BOT replay needs semantically equal
      -- resources owned by its native actor; remap only the QA execution
      -- copy and retain the accepted request trace unchanged.  Matching
      -- trueName/suit/color keeps the ViewAs skill law intact and never
      -- exposes a private card id in evidence.
      local sourceCard = effectReplayReplyForExecution.card
      local executionCard = {}
      for key, value in pairs(sourceCard) do executionCard[key] = value end
      local available = replayActor:getCardIds("he") or {}
      local used = {}
      local usedSuits = {}
      local mapped = {}
      local function sameResourceShape(left, right)
        if not left or not right or left.trueName ~= right.trueName then return false end
        if prompt4CardSuit(left) ~= prompt4CardSuit(right) then return false end
        local leftColor = pcall(left.getColorString, left) and left:getColorString() or ""
        local rightColor = pcall(right.getColorString, right) and right:getColorString() or ""
        return leftColor == rightColor
      end
      for _, sourceId in ipairs(sourceCard.subcards) do
        local candidate = sourceId
        local owner = room:getCardOwner(sourceId)
        if owner ~= replayActor then
          if prompt4EffectReplayProfile.resourceMatchMode == "distinct_suits" then
            candidate = table.find(available, function(id)
              local card = Fk:getCardById(id)
              local suit = prompt4CardSuit(card)
              return not used[id] and suit ~= "" and not usedSuits[suit]
            end)
          elseif prompt4EffectReplayProfile.resourceMatchMode == "huoji_red" then
            candidate = table.find(available, function(id)
              local card = Fk:getCardById(id)
              return not used[id] and card and card.type ~= Card.TypeEquip and
                card:getColorString() == "red"
            end)
          else
            local source = Fk:getCardById(sourceId)
            candidate = table.find(available, function(id)
              return not used[id] and sameResourceShape(source, Fk:getCardById(id))
            end)
          end
          if candidate then replay.resourceRetargeted = true end
        end
        if candidate then
          used[candidate] = true
          if prompt4EffectReplayProfile.resourceMatchMode == "distinct_suits" then
            usedSuits[prompt4CardSuit(Fk:getCardById(candidate))] = true
          end
          table.insert(mapped, candidate)
        else
          replay.resourceRetargetError = true
          table.insert(mapped, sourceId)
        end
      end
      executionCard.subcards = mapped
      effectReplayReplyForExecution.card = executionCard
    end
    local handled, useResult = xpcall(function()
      return room:handleUseCardReply(replayActor, effectReplayReplyForExecution, {
        skill_name = effectReplayItem.skill,
        prompt = activePrompt,
        pattern = cardRequest and effectReplayData[2] or nil,
        cancelable = cardRequest and effectReplayData[4] or effectReplayData[3],
        extra_data = cardRequest and effectReplayData[5] or effectReplayData[4],
        is_response = responseRequest,
      })
    end, function()
      -- Do not expose native exception text or private state in QA output.
      return nil
    end)
    replay.executedUseResult = false
    if handled and (prompt4EffectReplayProfile.executeUseResult or
        prompt4EffectReplayProfile.executeResponseResult) then
      local executed = xpcall(function()
        if type(useResult) ~= "table" then return false end
        if prompt4EffectReplayProfile.targetFromExtraData and
            type(useResult.tos) == "table" and #useResult.tos == 0 then
          -- Response-style ViewAs replies intentionally omit the rescue
          -- target; the native request already supplied it as must_targets.
          -- Reattach only that server-provided target before executing the
          -- returned useResult. No target identity is emitted.
          useResult.tos = replayTargets
        end
        if prompt4EffectReplayProfile.targetPolicy == "native_bot" then
          -- Replace only the useResult target list after the real skill
          -- onUse/useSkill path has built it. The subsequent room:useCard
          -- call, including any nested response request, remains native.
          useResult.tos = replayTargets
        end
        if prompt4EffectReplayProfile.executeResponseResult then
          -- Response-style ViewAs skills return a card-use-shaped result from
          -- handleUseCardReply, but the native event must be RespondCard so
          -- CardResponding/CardRespondFinished and afterResponse run on the
          -- real engine path.
          room:responseCard(useResult)
        else
          room:useCard(useResult)
        end
        return true
      end, function()
        -- Do not expose native exception text or private state in QA output.
        return false
      end)
      replay.executedUseResult = executed
      if not executed then replay.errors = replay.errors + 1 end
    end
    local nestedMetricDetails = {}
    for _, spec in ipairs(prompt4EffectReplayProfile.nestedMetrics or {}) do
      local before = nestedMetricBefore[spec.command] or {}
      local after = metricBucket(spec.command)
      local totalDelta = metricCount(after, "total") - (before.total or 0)
      local fallbackDelta = metricCount(after, "fallback") - (before.fallback or 0)
      local invalidDelta = metricCount(after, "invalid") - (before.invalid or 0)
      table.insert(nestedMetricDetails, string.format("%s:%d/%d/%d", aiTraceToken(spec.command),
        totalDelta, fallbackDelta, invalidDelta))
      replay.nestedRequests = replay.nestedRequests + totalDelta
      replay.nestedFallback = replay.nestedFallback + fallbackDelta
      replay.nestedInvalid = replay.nestedInvalid + invalidDelta
      if (spec.total ~= nil and totalDelta ~= spec.total) or
          (spec.fallback ~= nil and fallbackDelta ~= spec.fallback) or
          (spec.invalid ~= nil and invalidDelta ~= spec.invalid) then
        replay.nestedMetricErrors = replay.nestedMetricErrors + 1
      end
    end
    replay.nestedMetricSummary = table.concat(nestedMetricDetails, ",")
    if replay.nestedMetricErrors > 0 then
      replay.errors = replay.errors + 1
    end
    replay.active = false
    replay.handled = handled
    replay.afterHp = replayActor.hp
    replay.hpDelta = replay.afterHp - replay.beforeHp
    replay.afterHand = handCount(replayActor)
    replay.handDelta = replay.afterHand - replay.beforeHand
    targetHandTotal = 0
    for _, target in ipairs(replayTargets) do
      targetHandTotal = targetHandTotal + handCount(target)
    end
    replay.afterTargetHandTotal = targetHandTotal
    replay.targetHandTotalDelta = replay.afterTargetHandTotal - replay.beforeTargetHandTotal
    if replayTarget then
      replay.afterTargetHp = replayTarget.hp
      replay.targetHpDelta = replay.afterTargetHp - replay.beforeTargetHp
      replay.afterTargetHand = handCount(replayTarget)
      replay.targetHandDelta = replay.afterTargetHand - replay.beforeTargetHand
      replay.targetSkill = prompt4EffectReplayProfile.expectedTargetSkill ~= nil and
        replayTarget:hasSkill(prompt4EffectReplayProfile.expectedTargetSkill) or false
    end
    if not handled or ((prompt4EffectReplayProfile.executeUseResult or
        prompt4EffectReplayProfile.executeResponseResult) and not replay.executedUseResult) then
      replay.errors = replay.errors + 1
    end
    -- The global QA director is visited once per room player by the native
    -- trigger dispatcher, so one real SkillEffect can produce several
    -- bounded observations. Require at least one observation, not an
    -- implementation-specific fan-out count.
    local expectedHp = prompt4EffectReplayProfile.expectedHpDelta
    local hpMatches = expectedHp == nil or replay.hpDelta == expectedHp or
      (prompt4EffectReplayProfile.expectedHpDeltas and
        prompt4EffectReplayProfile.expectedHpDeltas[replay.hpDelta] == true)
    local handMatches = prompt4EffectReplayProfile.expectedHandDelta == nil or
      replay.handDelta == prompt4EffectReplayProfile.expectedHandDelta
    local targetHpMatches = prompt4EffectReplayProfile.expectedTargetHpDelta == nil or
      replay.targetHpDelta == prompt4EffectReplayProfile.expectedTargetHpDelta or
      (prompt4EffectReplayProfile.expectedTargetHpDeltas and
        prompt4EffectReplayProfile.expectedTargetHpDeltas[replay.targetHpDelta] == true)
    local targetHandMatches = prompt4EffectReplayProfile.expectedTargetHandDelta == nil or
      replay.targetHandDelta == prompt4EffectReplayProfile.expectedTargetHandDelta
    local targetHandTotalMatches = prompt4EffectReplayProfile.expectedTargetHandTotalDelta == nil or
      replay.targetHandTotalDelta == prompt4EffectReplayProfile.expectedTargetHandTotalDelta
    local targetCountMatches = prompt4EffectReplayProfile.expectedTargetCount == nil or
      replay.targetCount == prompt4EffectReplayProfile.expectedTargetCount
    local targetSkillMatches = prompt4EffectReplayProfile.expectedTargetSkill == nil or replay.targetSkill
    local markMatches = true
    local minimumMark = prompt4EffectReplayProfile.minimumMark
    if minimumMark then
      markMatches = replayActor:getMark(minimumMark.name) >= minimumMark.value
    end
    local markAny = prompt4EffectReplayProfile.markAny
    if markAny then
      markMatches = false
      for _, markName in ipairs(markAny) do
        if replayActor:getMark(markName) >= 1 then
          markMatches = true
          break
        end
      end
    end
    local replayCardMatches = prompt4EffectReplayProfile.expectedReplayCardCount == nil or
      replay.replyCardCount == prompt4EffectReplayProfile.expectedReplayCardCount
    if not handled or replay.skillEffects < 1 or replay.fake or replay.resourceRetargetError or not hpMatches or
        not handMatches or not targetHpMatches or not targetHandMatches or
        not targetHandTotalMatches or not targetCountMatches or
        not targetSkillMatches or not markMatches or not replayCardMatches or
        replay.nestedMetricErrors > 0 then
      fail(string.format(
        "ai-trace Prompt 4 effect replay failed skill=%s handled=%d executed=%d skill_effects=%d observed_skill_effects=%d observed_skill_names=%s fake=%d reply_cards=%d hp_delta=%d hand_delta=%d target_hp_delta=%d target_hand_delta=%d target_hand_total_delta=%d target_count=%d target_skill=%d mark_ok=%d resource_retargeted=%d resource_retarget_error=%d nested_requests=%d nested_fallback=%d nested_invalid=%d nested_metric_errors=%d nested_metrics=%s errors=%d",
        aiTraceToken(prompt4EffectReplaySkill), handled and 1 or 0,
        replay.executedUseResult and 1 or 0, replay.skillEffects, replay.observedSkillEffects,
        aiTraceToken(table.concat(replay.observedSkillNames, ",")),
        replay.fake and 1 or 0, replay.replyCardCount, replay.hpDelta, replay.handDelta, replay.targetHpDelta,
        replay.targetHandDelta, replay.targetHandTotalDelta, replay.targetCount,
        replay.targetSkill and 1 or 0, markMatches and 1 or 0, replay.resourceRetargeted and 1 or 0,
        replay.resourceRetargetError and 1 or 0, replay.nestedRequests,
        replay.nestedFallback, replay.nestedInvalid, replay.nestedMetricErrors,
        replay.nestedMetricSummary, replay.errors))
    end
  end
end

local function emitPrompt4NativeTrace(state)
  local trace = state.prompt4Trace
  if not trace or trace.emitted then return end
  trace.emitted = true
  fk.qInfo(string.format("[tqs_prompt4_trace] summary scenario=%s seed=%u revision=%s decisions=%d opportunities=%d accepted=%d acted=%d misses=%d fallback=%d invalid=%d errors=%d pair=%s state=%s fixture=semantic_v1 skills=%d metadata=shape_v1",
    state.scenario, state.seed, state.revision, trace.total, trace.opportunities, trace.accepted,
    trace.acted, trace.misses, trace.fallback, trace.invalid, trace.errors,
    trace.pairVerified and "verified" or "unverified", trace.stateVerified and "verified" or "unverified",
    #trace.decisions))
  for _, entry in ipairs(trace.decisions) do
  fk.qInfo(string.format("[tqs_prompt4_trace] decision scenario=%s seed=%u revision=%s seq=%d skill=%s command=%s input=%s offer=%s opportunity=%d offered_cards=%d offered_targets=%d accepted=%d acted=%d invalid=%d output=%s reason=%s detail=%s target_profile=%s card_profile=%s resource_shape=%s selected_cards=%d selected_targets=%d target_quality=%s resource_value=%s",
      state.scenario, state.seed, state.revision, entry.seq, entry.skill, entry.command, entry.input,
      entry.offer, entry.opportunity and 1 or 0, entry.offeredCards, entry.offeredTargets,
      entry.accepted and 1 or 0, entry.acted and 1 or 0, entry.invalid and 1 or 0,
      entry.output, entry.reason, entry.detail, entry.targetProfile, entry.cardProfile,
      entry.resourceShape, entry.selectedCards, entry.selectedTargets, entry.targetQuality, entry.resourceValue))
  end
  local replay = trace.effectReplay
  if replay and replay.requestedSkill ~= "disabled" then
      fk.qInfo(string.format("[tqs_prompt4_effect] summary scenario=%s seed=%u revision=%s skill=%s attempted=%d accepted=%d handled=%d skill_effects=%d fake=%d hp_delta=%d hand_delta=%d target_hp_delta=%d target_hand_delta=%d target_hand_total_delta=%d target_count=%d target_skill=%d target_policy=%s actor_policy=%s target_retargeted=%d resource_retargeted=%d resource_retarget_error=%d nested_requests=%d nested_fallback=%d nested_invalid=%d nested_metric_errors=%d nested_metrics=%s errors=%d",
      state.scenario, state.seed, state.revision, aiTraceToken(replay.requestedSkill),
      replay.attempted and 1 or 0, replay.accepted and 1 or 0, replay.handled and 1 or 0,
      replay.skillEffects, replay.fake and 1 or 0, replay.hpDelta, replay.handDelta,
      replay.targetHpDelta, replay.targetHandDelta, replay.targetHandTotalDelta,
      replay.targetCount, replay.targetSkill and 1 or 0, aiTraceToken(replay.targetPolicy),
      aiTraceToken(replay.actorPolicy),
      replay.targetRetargeted and 1 or 0, replay.resourceRetargeted and 1 or 0,
      replay.resourceRetargetError and 1 or 0, replay.nestedRequests, replay.nestedFallback,
      replay.nestedInvalid, replay.nestedMetricErrors, replay.nestedMetricSummary, replay.errors))
  end
end

local function triggerHiddenActive(room, state)
  -- Sun Quan's active skill is a direct PlayCard action, not a trigger that
  -- must be prelighted. The actor starts with both generals hidden and the
  -- real client receives hs__zhiheng through the native fake-skill callback's
  -- active-skill projection.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-active actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__zhiheng") then
    fail("hidden-active must attach the hidden active Chế Hành skill")
  end
  if state.actor:hasSkill("hs__zhiheng") then
    fail("hidden-active Chế Hành must not be active before PlayCard")
  end

  -- PlayCard is a normal turn request, but the native client needs one
  -- completed request round after GameStart to finish projecting the hidden
  -- pair and its fake active skill. Keep this bounded QA synchronization
  -- request separate from the rule under test; the actual assertion below is
  -- still the real PlayCard -> handleUseCardReply -> SkillEffect path.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_active_gate",
    prompt = "TQS QA: xác nhận dock Chế Hành đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-active readiness gate was cancelled")
  end

  local cardId = state.slotCards["zhiheng-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-active must put its reserved Slash in the actor hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-active must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "hs__zhiheng" then
    fail("hidden-active PlayCard must select hs__zhiheng")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId then
    fail("hidden-active Chế Hành must select exactly the reserved Slash")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  local useResult = room:handleUseCardReply(state.actor, result)
  if type(useResult) == "table" then
    room:useCard(useResult)
  end

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__zhiheng" and entry.player == state.actor.id
  end)
  if not effect then
    fail("hidden-active must execute Chế Hành through the native SkillEffect")
  end
  local activeIsMain = state.scenario == "hidden-active-main"
  local revealedCorrectSlot = activeIsMain
    and state.actor.general == "hs__sunquan" and state.actor.deputyGeneral == "anjiang"
    or not activeIsMain and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__sunquan"
  if not revealedCorrectSlot then
    fail("hidden-active must reveal Tôn Quyền in its catalogued slot and keep Lục Tốn hidden")
  end
  if state.actor:isFakeSkill("hs__zhiheng") or not state.actor:hasSkill("hs__zhiheng") then
    fail("hidden-active must convert Chế Hành from fake to active after reveal")
  end
  if (activeIsMain and (effect.general ~= "hs__sunquan" or effect.deputyGeneral ~= "anjiang")) or
      (not activeIsMain and (effect.general ~= "anjiang" or effect.deputyGeneral ~= "hs__sunquan")) or effect.fake then
    fail("hidden-active must reveal Sun Quan before Chế Hành SkillEffect")
  end
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if beforeHand ~= 1 or afterHand ~= beforeHand or
      table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-active Chế Hành must discard one card and draw one card")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Chế Hành: SkillEffect=%arg; Tôn Quyền đã mở=%arg2; Lục Tốn còn úp=%arg3; vị trí=%arg6; bài trước=%arg4; sau=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(beforeHand),
    arg5 = tostring(afterHand),
    arg6 = activeIsMain and "chủ tướng" or "phó tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-active skill=hs__zhiheng effect=true slot=%s main=%s deputy=%s hand=%d->%d revision=%s",
    activeIsMain and "main" or "deputy", state.actor.general, state.actor.deputyGeneral, beforeHand, afterHand,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenFanjian(room, state)
  -- Chu Du's active skill is a real PlayCard action.  Keep both Wu generals
  -- hidden until the native SkillEffect runs; the SkillEffect itself must
  -- reveal only the slot that owns ex__fanjian before on_use gives the Peach
  -- and asks the target for the source-defined choice.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fanjian actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ex__fanjian") then
    fail("hidden-fanjian must attach the hidden active Phản Gián skill")
  end
  if state.actor:hasSkill("ex__fanjian") then
    fail("hidden-fanjian Phản Gián must not be active before PlayCard")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_fanjian_gate",
    prompt = "TQS QA: xác nhận dock Phản Gián đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-fanjian readiness gate was cancelled")
  end

  local cardId = state.slotCards["fanjian-card"]
  local targetCardId = state.slotCards["fanjian-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-fanjian must put its reserved Peach in the actor hand")
  end
  if not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-fanjian must put its reserved Jink in the target hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-fanjian must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "ex__fanjian" then
    fail("hidden-fanjian PlayCard must select ex__fanjian")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId or type(result.targets) ~= "table" or
      #result.targets ~= 1 or result.targets[1] ~= state.target.id then
    fail("hidden-fanjian must select exactly the reserved Peach and the native target")
  end

  local beforeActorHand = #state.actor:getCardIds(Player.Hand)
  local beforeTargetHp = state.target.hp
  local useResult = room:handleUseCardReply(state.actor, result)
  if type(useResult) == "table" then
    room:useCard(useResult)
  end

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "ex__fanjian" and entry.player == state.actor.id
  end)
  local fanjianIsDeputy = state.scenario == "hidden-fanjian-deputy"
  local revealedCorrectSlot = fanjianIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhouyu"
    or not fanjianIsDeputy and state.actor.general == "hs__zhouyu" and state.actor.deputyGeneral == "anjiang"
  local targetKeptGift = room:getCardOwner(cardId) == state.target and
    table.contains(state.target:getCardIds(Player.Hand), cardId)
  local targetKeptOriginal = table.contains(state.target:getCardIds(Player.Hand), targetCardId)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("hidden-fanjian must reveal Chu Du in its catalogued slot before a real SkillEffect")
  end
  if state.actor:isFakeSkill("ex__fanjian") or not state.actor:hasSkill("ex__fanjian") then
    fail("hidden-fanjian must convert Phản Gián from fake to active after reveal")
  end
  if beforeActorHand ~= 1 or table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetKeptGift or not targetKeptOriginal then
    fail("hidden-fanjian must give the selected Peach to the target and preserve the target Jink")
  end
  if state.target.hp ~= beforeTargetHp - 1 then
    fail("hidden-fanjian QA must select the native loseHp branch after the gift")
  end

  state.hiddenFanjianBranch = "positive-active-reveal-lose-hp"
  room:sendLog{
    type = "[TQS QA] Hidden Phản Gián: SkillEffect=%arg; vị trí=%arg6; mở Chu Du=%arg2; fake=%arg3; tặng bài=%arg4; mất HP=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(effect.fake),
    arg4 = tostring(targetKeptGift),
    arg5 = tostring(state.target.hp == beforeTargetHp - 1),
    arg6 = fanjianIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fanjian skill=ex__fanjian effect=true slot=%s main=%s deputy=%s target_hp=%d->%d revision=%s",
    fanjianIsDeputy and "deputy" or "main", state.actor.general, state.actor.deputyGeneral,
    beforeTargetHp, state.target.hp, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenViewAs(room, state)
  -- Longdan is a ViewAsSkill rather than an ordinary ActiveSkill. The actor
  -- remains fully hidden until the native PlayCard path uses the fake skill.
  -- Clear the target's initial hand so the converted Slash cannot branch into
  -- an unrelated private Jink request during this bounded acceptance case.
  state.target:revealGenerals()
  state.target:throwAllCards("h", "tqs_qa")
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-view-as actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__longdan") then
    fail("hidden-view-as must attach the hidden ViewAsSkill Longdan")
  end
  if state.actor:hasSkill("hs__longdan") then
    fail("hidden-view-as Longdan must not be active before PlayCard")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_view_as_gate",
    prompt = "TQS QA: xác nhận dock Long Đảm đã sẵn sàng, rồi chọn Thiểm như Sát.",
  })
  if not gate then
    fail("hidden-view-as readiness gate was cancelled")
  end

  local cardId = state.slotCards["longdan-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-view-as must put its reserved Jink in the actor hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-view-as must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "hs__longdan" then
    fail("hidden-view-as PlayCard must select hs__longdan")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId then
    fail("hidden-view-as Longdan must select exactly the reserved Jink")
  end
  local useResult = room:handleUseCardReply(state.actor, result, {
    extra_data = { bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id } },
  })
  if type(useResult) ~= "table" or not useResult.card or useResult.card.trueName ~= "slash" or
      not table.contains(useResult.card.skillNames or {}, "hs__longdan") then
    fail("hidden-view-as must convert the reserved Jink into a Longdan Slash")
  end
  room:useCard(useResult)

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__longdan" and entry.player == state.actor.id
  end)
  if not effect then
    fail("hidden-view-as must execute Longdan through native SkillEffect")
  end
  local mainIsZhaoyun = state.scenario == "hidden-view-as-main"
  local revealedCorrectSlot = mainIsZhaoyun
    and state.actor.general == "hs__zhaoyun" and state.actor.deputyGeneral == "anjiang"
    or not mainIsZhaoyun and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhaoyun"
  if not revealedCorrectSlot then
    fail("hidden-view-as must reveal Triệu Vân in its catalogued slot")
  end
  if state.actor:isFakeSkill("hs__longdan") or not state.actor:hasSkill("hs__longdan") then
    fail("hidden-view-as must convert Longdan from fake to active after reveal")
  end
  if (mainIsZhaoyun and (effect.general ~= "hs__zhaoyun" or effect.deputyGeneral ~= "anjiang")) or
      (not mainIsZhaoyun and (effect.general ~= "anjiang" or effect.deputyGeneral ~= "hs__zhaoyun")) or effect.fake then
    fail("hidden-view-as must reveal Triệu Vân before Longdan SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Long Đảm: SkillEffect=%arg; Triệu Vân đã mở=%arg2; vị trí=%arg3; Thiểm→Sát=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = mainIsZhaoyun and "chủ tướng" or "phó tướng",
    arg4 = "true",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-view-as skill=hs__longdan effect=true slot=%s main=%s deputy=%s converted=true revision=%s",
    mainIsZhaoyun and "main" or "deputy", state.actor.general, state.actor.deputyGeneral,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenDual(room, state)
  -- The actor remains face-down while the real trigger is prelighted. The
  -- target is public and owns exactly one red Jink so the source color and the
  -- later opposite-color ViewAs card are deterministic.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-dual actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__shuangxiong") then
    fail("hidden-dual must attach the hidden dual trigger/ViewAs skill")
  end
  if state.actor:hasSkill("hs__shuangxiong") then
    fail("hidden-dual must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_dual_gate",
    prompt = "TQS QA: xác nhận dock Song Hùng đã sẵn sàng, rồi kích hoạt trigger úp.",
  })
  if not gate then
    fail("hidden-dual readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__shuangxiong") then
    fail("hidden-dual must be prelighted before the EventPhaseStart branch")
  end

  local actorCardId = state.slotCards["shuangxiong-card"]
  local discardCardId = state.slotCards["shuangxiong-discard"]
  local targetInitialHand = #state.target:getCardIds(Player.Hand)
  if targetInitialHand ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), actorCardId) or
      not table.contains(state.target:getCardIds(Player.Hand), discardCardId) then
    fail("hidden-dual must start with exactly the catalogued actor Slash and target Jink")
  end

  -- Reproduce the engine's phase-start contract without running a full random
  -- turn. The source skill itself still owns the real cost/effect chain below.
  room:setPlayerProperty(state.actor, "phase", Player.Play)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Play,
  })

  local triggerEffects = table.filter(state.skillEffects, function(entry)
    return entry.skill == "hs__shuangxiong" and entry.player == state.actor.id
  end)
  if #triggerEffects < 1 then
    fail("hidden-dual prelighted EventPhaseStart must execute a native SkillEffect")
  end
  local triggerEffect = triggerEffects[1]
  if triggerEffect.fake then
    fail("hidden-dual must reveal before the native trigger SkillEffect")
  end
  if state.actor.general ~= "hs__yanliangwenchou" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-dual must reveal Yan Liang/Wen Chou in the catalogued main slot")
  end
  if state.actor:isFakeSkill("hs__shuangxiong") or not state.actor:hasSkill("hs__shuangxiong") then
    fail("hidden-dual must convert the dual skill from fake to active before its cost chain")
  end

  local mark = state.actor:getMark("@hs__shuangxiong-turn")
  if mark ~= Fk:getCardById(discardCardId):getColorString() or mark ~= "red" then
    fail("hidden-dual must record the discarded red card color before ViewAs")
  end
  if #state.target:getCardIds(Player.Hand) ~= 0 then
    fail("hidden-dual target must discard the catalogued Jink")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-dual must receive a native PlayCard ViewAs reply")
  end
  if result.card.skill ~= "hs__shuangxiong" then
    fail("hidden-dual PlayCard must select hs__shuangxiong")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= actorCardId then
    fail("hidden-dual PlayCard must select exactly the catalogued opposite-color Slash")
  end

  local useResult = room:handleUseCardReply(state.actor, result, {
    extra_data = { bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id } },
  })
  if type(useResult) ~= "table" or not useResult.card or useResult.card.trueName ~= "duel" or
      not table.contains(useResult.card.skillNames or {}, "hs__shuangxiong") or
      not table.contains(useResult.card.subcards or {}, actorCardId) then
    fail("hidden-dual must convert the opposite-color Slash into a native Duel")
  end
  room:useCard(useResult)

  local effectsAfter = table.filter(state.skillEffects, function(entry)
    return entry.skill == "hs__shuangxiong" and entry.player == state.actor.id
  end)
  if #effectsAfter < 2 or table.contains(state.actor:getCardIds(Player.Hand), actorCardId) then
    fail("hidden-dual must execute the ViewAs Duel and consume the catalogued Slash")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Song Hùng: trigger SkillEffect=%arg; mở chủ=%arg2; bỏ bài đỏ=%arg3; Duel khác màu=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = "true",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-dual skill=hs__shuangxiong trigger=true view_as_duel=true slot=main revision=%s",
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function moveJudgmentColorsToTop(room)
  local blackId, redId
  for index = #room.draw_pile, 1, -1 do
    local id = room.draw_pile[index]
    local color = Fk:getCardById(id):getColorString()
    if not blackId and color == "black" then
      blackId = table.remove(room.draw_pile, index)
    elseif not redId and color == "red" then
      redId = table.remove(room.draw_pile, index)
    end
    if blackId and redId then break end
  end
  if not blackId or not redId then
    fail("hidden-luoshen needs one black and one red native judgment card")
  end
  -- Luoshen sees the black card first, then the red card ends the loop. The
  -- QA fixture only fixes the pile order; the source skill still owns judge,
  -- reveal-before-effect, optional continuation and obtaining the black card.
  table.insert(room.draw_pile, 1, redId)
  table.insert(room.draw_pile, 1, blackId)
  room:syncDrawPile()
  return blackId, redId
end

local function triggerHiddenTiandu(room, state)
  -- Thiên Đố is a mandatory FinishJudge effect. The only client-controlled
  -- gate here is the native prelight request; the actual judge and obtain
  -- path must remain the source skill's real SkillEffect flow.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-tiandu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("tiandu") then
    fail("hidden-tiandu must attach the hidden Tiandu skill")
  end
  if state.actor:hasSkill("tiandu") then
    fail("hidden-tiandu must not be active before the prelighted FinishJudge")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_tiandu_gate",
    prompt = "TQS QA: prelight Thiên Đố, rồi xác nhận để bắt đầu phán xét.",
  })
  if not gate then
    fail("hidden-tiandu readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "tiandu") then
    fail("hidden-tiandu must be prelighted before the FinishJudge branch")
  end

  local judgedId = moveJudgmentColorsToTop(room)
  state.currentDamageStep = 1
  local judge = {
    who = state.actor,
    reason = "tiandu",
    pattern = ".",
  }
  room:judge(judge)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "tiandu" and entry.player == state.actor.id
  end)
  local tianduIsDeputy = state.scenario == "hidden-tiandu-deputy"
  local revealedCorrectSlot = tianduIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__guojia"
    or not tianduIsDeputy and state.actor.general == "hs__guojia" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "tiandu", state.actor, Card.Processing)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Tiandu must run a real SkillEffect and reveal Guo Jia in its catalogued slot")
  end
  if not judge.card or judge.card:getEffectiveId() ~= judgedId or obtained ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), judgedId) then
    fail("hidden Tiandu must obtain the judged card from Card.Processing")
  end
  if state.actor:isFakeSkill("tiandu") or not state.actor:hasSkill("tiandu") then
    fail("hidden Tiandu must convert from fake to active after reveal")
  end

  local position = tianduIsDeputy and "phó tướng" or "chủ tướng"
  room:sendLog{
    type = "[TQS QA] Hidden Thiên Đố: FinishJudge=%arg; SkillEffect=%arg2; lấy lá phán xét=%arg3; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(obtained == 1),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = position,
  }
  fk.qInfo(string.format("[tqs_qa] hidden-tiandu finish_judge=true skill_effect=true obtained=%d revealed=%s slot=%s revision=%s",
    obtained, tostring(revealedCorrectSlot), tianduIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenLuoshen(room, state)
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-luoshen actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__luoshen") then
    fail("hidden-luoshen must attach the hidden Luoshen skill")
  end
  if state.actor:hasSkill("hs__luoshen") then
    fail("hidden-luoshen must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_luoshen_gate",
    prompt = "TQS QA: prelight 洛神, rồi xác nhận để bắt đầu pha chuẩn bị.",
  })
  if not gate then
    fail("hidden-luoshen readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__luoshen") then
    fail("hidden-luoshen must be prelighted before the EventPhaseStart branch")
  end

  local blackId = moveJudgmentColorsToTop(room)
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Start)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Start,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__luoshen" and entry.player == state.actor.id
  end)
  local luoshenIsDeputy = state.scenario == "hidden-luoshen-deputy"
  local revealedCorrectSlot = luoshenIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhenji"
    or not luoshenIsDeputy and state.actor.general == "hs__zhenji" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "hs__luoshen", state.actor, Card.Processing)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Luoshen must run a real SkillEffect and reveal Zhen Ji in its catalogued slot")
  end
  if obtained ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), blackId) then
    fail("hidden Luoshen must obtain the black judgment card after the red stop card")
  end
  if state.actor:isFakeSkill("hs__luoshen") or not state.actor:hasSkill("hs__luoshen") then
    fail("hidden Luoshen must convert from fake to active after reveal")
  end

  state.hiddenLuoshenBranch = "positive-prelight-phase-start-judge-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden 洛神: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài đen=%arg5",
    from = state.actor.id,
    arg = state.hiddenLuoshenBranch,
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = luoshenIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-luoshen branch=%s slot=%s prelight=true invoked=true revealed=%s obtained=%d revision=%s",
    state.hiddenLuoshenBranch, luoshenIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), obtained,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJizhi(room, state)
  -- 集智 is an optional CardUsing effect. The actor stays face-down while a
  -- real common Trick is used; the source SkillEffect must reveal only the
  -- Huang Yueying slot before asking whether to draw.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jizhi actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__jizhi") then
    fail("hidden-jizhi must attach the hidden Jizhi skill")
  end
  if state.actor:hasSkill("hs__jizhi") then
    fail("hidden-jizhi must not be active before CardUsing")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jizhi_gate",
    prompt = "TQS QA: prelight Tập Trí, rồi xác nhận để dùng Lạc Hồn.",
  })
  if not gate then
    fail("hidden-jizhi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__jizhi") then
    fail("hidden-jizhi must be prelighted before the CardUsing branch")
  end

  local cardId = state.slotCards["jizhi-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-jizhi must put its reserved Duel in the actor hand")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jizhi_card",
    prompt = "TQS QA: dùng Lạc Hồn lên đối thủ để kiểm tra Tập Trí.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or use.card.trueName ~= "duel" or
      #use.tos ~= 1 or use.tos[1] ~= state.target then
    fail("hidden-jizhi must receive the reserved Duel against the catalog target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__jizhi" and entry.player == state.actor.id
  end)
  local jizhiIsDeputy = state.scenario == "hidden-jizhi-deputy"
  local revealedCorrectSlot = jizhiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__huangyueying"
    or not jizhiIsDeputy and state.actor.general == "hs__huangyueying" and state.actor.deputyGeneral == "anjiang"
  local afterHand = #state.actor:getCardIds(Player.Hand)
  local drawn = movedFromArea(state, 1, "hs__jizhi", state.actor, Card.DrawPile)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Jizhi must run a real SkillEffect and reveal Huang Yueying in its catalogued slot")
  end
  if afterHand ~= beforeHand or table.contains(state.actor:getCardIds(Player.Hand), cardId) or drawn ~= 1 then
    fail("hidden Jizhi must consume the Duel and draw exactly one card through its native effect")
  end
  if state.actor:isFakeSkill("hs__jizhi") or not state.actor:hasSkill("hs__jizhi") then
    fail("hidden Jizhi must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Tập Trí: CardUsing Duel=%arg; SkillEffect=%arg2; mở tướng=%arg3; rút bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(drawn),
    arg5 = jizhiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jizhi card_using=duel effect=true slot=%s revealed=%s drawn=%d revision=%s",
    jizhiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawn, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenMingshi(room, state)
  -- 名士 is compulsory and only checks whether the damage source still has an
  -- unrevealed slot. Keep both players hidden until the real Slash reaches
  -- DamageInflicted; the target must remain hidden after the effect as well.
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-mingshi actor must start with both generals hidden")
  end
  if state.target.general ~= "anjiang" or state.target.deputyGeneral ~= "anjiang" then
    fail("hidden-mingshi source must remain hidden so DamageInflicted can see anjiang")
  end
  if not state.actor:isFakeSkill("mingshi") then
    fail("hidden-mingshi must attach the hidden Mingshi skill")
  end
  if state.actor:hasSkill("mingshi") then
    fail("hidden-mingshi must not be active before DamageInflicted")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_mingshi_gate",
    prompt = "TQS QA: prelight Danh Sĩ, rồi xác nhận để nguồn úp dùng Sát.",
  })
  if not gate then
    fail("hidden-mingshi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "mingshi") then
    fail("hidden-mingshi must be prelighted before the DamageInflicted branch")
  end

  local cardId = state.slotCards["mingshi-damage"]
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-mingshi must put its reserved hidden-source Slash in the target hand")
  end
  local beforeHp = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_mingshi_damage",
    prompt = "TQS QA: dùng Sát lên Khổng Dung để kiểm tra Danh Sĩ.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or use.card.trueName ~= "slash" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-mingshi must receive the reserved hidden-source Slash against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "mingshi" and entry.player == state.actor.id
  end)
  local mingshiIsDeputy = state.scenario == "hidden-mingshi-deputy"
  local revealedCorrectSlot = mingshiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__kongrong"
    or not mingshiIsDeputy and state.actor.general == "hs__kongrong" and state.actor.deputyGeneral == "anjiang"
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Mingshi must run a real SkillEffect and reveal Kong Rong in its catalogued slot")
  end
  if state.actor.hp ~= beforeHp then
    fail("hidden Mingshi must reduce the one Slash damage to zero")
  end
  if state.target.general ~= "anjiang" or state.target.deputyGeneral ~= "anjiang" then
    fail("hidden Mingshi must not reveal the hidden damage source")
  end
  if state.actor:isFakeSkill("mingshi") or not state.actor:hasSkill("mingshi") then
    fail("hidden Mingshi must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Danh Sĩ: DamageInflicted=%arg; SkillEffect=%arg2; mở tướng=%arg3; sát thương=0; vị trí=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = mingshiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-mingshi damage_inflicted=zero effect=true slot=%s revealed=%s source_hidden=true revision=%s",
    mingshiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenGongqing(room, state)
  -- 公清 has two independent DamageInflicted paths in the source package:
  -- low attack range collapses damage to 1 through DetermineDamageInflicted,
  -- while high attack range adds one through DamageInflicted.  Keep 潘濬
  -- hidden until the first native effect so this also proves slot ownership
  -- and fake-skill conversion on both main/deputy placements.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-gongqing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("gongqing") then
    fail("hidden-gongqing must attach the hidden Gongqing skill")
  end
  if state.actor:hasSkill("gongqing") then
    fail("hidden-gongqing must not be active before the first damage branch")
  end

  -- The paired roster can otherwise start at three HP, while the two source
  -- branches intentionally deal 1 + 2 damage. Increase only the QA actor's
  -- life total so the second native branch completes without entering Dying.
  room:setPlayerProperty(state.actor, "maxHp", 5)
  room:setPlayerProperty(state.actor, "hp", 5)

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_gongqing_gate",
    prompt = "TQS QA: prelight Công Thanh, rồi xác nhận để kiểm tra hai nhánh tầm đánh.",
  })
  if not gate then
    fail("hidden-gongqing readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "gongqing") then
    fail("hidden-gongqing must be prelighted before the damage branches")
  end

  local bowId = state.slotCards["gongqing-bow"]
  if not bowId or not table.contains(state.target:getCardIds(Player.Hand), bowId) then
    fail("hidden-gongqing must put the reserved Kylin Bow in the source hand")
  end
  local lowRange = state.target:getAttackRange() < 3
  local beforeLowHp = state.actor.hp
  state.currentDamageStep = 1
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 2,
    skillName = "tqs_qa_hidden_gongqing_low_range",
  })
  state.currentDamageStep = nil

  if not lowRange or not state.actor:hasSkill("gongqing") or state.actor:isFakeSkill("gongqing") then
    fail("hidden-gongqing must reveal and activate before the low-range damage effect")
  end
  if not table.contains(state.target:getCardIds(Player.Hand), bowId) then
    fail("hidden-gongqing source Kylin Bow must remain available for the high-range branch")
  end

  room:moveCardTo(bowId, Card.PlayerEquip, state.target, fk.ReasonJustMove, "tqs_qa", nil, true, state.target)
  local highRange = state.target:getAttackRange() > 3
  if not highRange then
    fail("hidden-gongqing Kylin Bow must raise the source attack range above 3")
  end

  local beforeHighHp = state.actor.hp
  state.currentDamageStep = 2
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_gongqing_high_range",
  })
  state.currentDamageStep = nil

  local lowDamage = 0
  local highDamage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.to == state.actor.id and entry.step == 1 then
      lowDamage = lowDamage + entry.amount
    elseif entry.to == state.actor.id and entry.step == 2 then
      highDamage = highDamage + entry.amount
    end
  end
  local lowEffect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "gongqing" and entry.player == state.actor.id
  end)
  local highEffect = table.find(state.skillEffects, function(entry)
    return entry.step == 2 and entry.skill == "gongqing" and entry.player == state.actor.id
  end)
  local gongqingIsDeputy = state.scenario == "hidden-gongqing-deputy"
  local revealedCorrectSlot = gongqingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "panjun"
    or not gongqingIsDeputy and state.actor.general == "panjun" and state.actor.deputyGeneral == "anjiang"
  if not lowEffect or lowEffect.fake or not highEffect or highEffect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Gongqing must run both real SkillEffects and reveal Pan Jun in its catalogued slot")
  end
  if lowDamage ~= 1 or highDamage ~= 2 or beforeLowHp - state.actor.hp ~= 3 or
      beforeLowHp - beforeHighHp ~= 1 or beforeHighHp - state.actor.hp ~= 2 then
    fail(string.format("hidden Gongqing must resolve low/high damage as 1/2, observed %d/%d", lowDamage, highDamage))
  end
  if state.actor:isFakeSkill("gongqing") or not state.actor:hasSkill("gongqing") then
    fail("hidden Gongqing must remain active after both native damage branches")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Công Thanh: DetermineDamageInflicted=%arg; DamageInflicted=%arg2; SkillEffect=%arg3; mở tướng=%arg4; sát thương thấp=%arg5; sát thương xa=%arg6; vị trí=%arg7",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(not lowEffect.fake and not highEffect.fake),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(lowDamage),
    arg6 = tostring(highDamage),
    arg7 = gongqingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-gongqing determine_damage_inflicted=true damage_inflicted=true effects=2 damage_low=%d damage_high=%d slot=%s revealed=%s revision=%s",
    lowDamage, highDamage, gongqingIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenQianxun(room, state)
  -- 谦逊 is compulsory on TargetConfirming. The actor remains face-down while
  -- a real Snatch has a legal Peach target; the native effect must reveal only
  -- the Lục Tốn slot and cancel that target before Snatch can obtain anything.
  local indulgenceScenario = state.scenario == "hidden-qianxun-indulgence" or
    state.scenario == "hidden-qianxun-indulgence-deputy"
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-qianxun actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-qianxun must attach the hidden Qianxun skill")
  end
  if state.actor:hasSkill("hs__qianxun") then
    fail("hidden-qianxun must not be active before TargetConfirming")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_qianxun_gate",
    prompt = indulgenceScenario
      and "TQS QA: prelight Khiêm Tốn, rồi xác nhận để đối thủ dùng Lạc Bất Tư Thục."
      or "TQS QA: prelight Khiêm Tốn, rồi xác nhận để đối thủ dùng Thuận Thủ.",
  })
  if not gate then
    fail("hidden-qianxun readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__qianxun") then
    fail("hidden-qianxun must be prelighted before TargetConfirming")
  end

  if indulgenceScenario then
    local indulgenceId = state.slotCards["qianxun-indulgence"]
    if not indulgenceId or not table.contains(state.target:getCardIds(Player.Hand), indulgenceId) then
      fail("hidden-qianxun indulgence must put its reserved Indulgence in the source hand")
    end

    state.currentDamageStep = 1
    local use = room:askToUseRealCard(state.target, {
      pattern = { indulgenceId },
      skill_name = "tqs_qa_hidden_qianxun_indulgence",
      prompt = "TQS QA: dùng Lạc Bất Tư Thục lên Lục Tốn để kiểm tra Khiêm Tốn.",
      extra_data = {
        bypass_times = true, bypass_distances = true, extraUse = true,
        exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      },
      cancelable = true,
      skip = true,
    })
    if not use or not use.card or use.card.id ~= indulgenceId or
        use.card.trueName ~= "indulgence" or #use.tos ~= 1 or use.tos[1] ~= state.actor then
      fail("hidden-qianxun indulgence must receive the reserved card against the actor")
    end
    use.extraUse = true
    room:useCard(use)
    state.currentDamageStep = nil

    local effect = table.find(state.skillEffects, function(entry)
      return entry.step == 1 and entry.skill == "hs__qianxun" and entry.player == state.actor.id
    end)
    local qianxunIsDeputy = state.scenario == "hidden-qianxun-indulgence-deputy"
    local revealedCorrectSlot = qianxunIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
      or not qianxunIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
    local cancelledJudgeMove = room:getCardArea(indulgenceId) == Card.DiscardPile and
      #state.actor:getCardIds(Player.Judge) == 0
    if not effect or effect.fake or not revealedCorrectSlot then
      fail("prelighted hidden Qianxun must run a real SkillEffect and reveal Lục Tốn in its catalogued slot")
    end
    if not cancelledJudgeMove then
      fail("hidden Qianxun must cancel the Indulgence judge move and discard the card")
    end
    if state.actor:isFakeSkill("hs__qianxun") or not state.actor:hasSkill("hs__qianxun") then
      fail("hidden Qianxun must convert from fake to active after reveal")
    end

    room:sendLog{
      type = "[TQS QA] Hidden Khiêm Tốn: BeforeCardsMove Lạc Bất Tư Thục=%arg; SkillEffect=%arg2; mở tướng=%arg3; vào phán xét=%arg4; chuyển bỏ=%arg5; vị trí=%arg6",
      from = state.actor.id,
      arg = "true",
      arg2 = "true",
      arg3 = tostring(revealedCorrectSlot),
      arg4 = "false",
      arg5 = tostring(cancelledJudgeMove),
      arg6 = qianxunIsDeputy and "phó tướng" or "chủ tướng",
    }
    fk.qInfo(string.format("[tqs_qa] hidden-qianxun before_cards_move=indulgence effect=true slot=%s revealed=%s judge_move_cancelled=%s discarded=true revision=%s",
      qianxunIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(cancelledJudgeMove), manifest.sourceRevision))
    state.gameOverRequested = true
    room:gameOver("")
    return
  end

  local snatchId = state.slotCards["qianxun-snatch"]
  local victimId = state.slotCards["qianxun-victim"]
  if not snatchId or not table.contains(state.target:getCardIds(Player.Hand), snatchId) then
    fail("hidden-qianxun must put its reserved Snatch in the source hand")
  end
  if not victimId or not table.contains(state.actor:getCardIds(Player.Hand), victimId) then
    fail("hidden-qianxun must put a legal actor Peach target in hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { snatchId },
    skill_name = "tqs_qa_hidden_qianxun_snatch",
    prompt = "TQS QA: dùng Thuận Thủ lên Lục Tốn để kiểm tra Khiêm Tốn.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= snatchId or use.card.trueName ~= "snatch" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-qianxun must receive the reserved Snatch against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__qianxun" and entry.player == state.actor.id
  end)
  local qianxunIsDeputy = state.scenario == "hidden-qianxun-deputy"
  local revealedCorrectSlot = qianxunIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
    or not qianxunIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(snatchId) == Card.DiscardPile and
    room:getCardOwner(victimId) == state.actor and
    table.contains(state.actor:getCardIds(Player.Hand), victimId)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Qianxun must run a real SkillEffect and reveal Lục Tốn in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Qianxun must cancel the valid Snatch target before any card is obtained")
  end
  if state.actor:isFakeSkill("hs__qianxun") or not state.actor:hasSkill("hs__qianxun") then
    fail("hidden Qianxun must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Khiêm Tốn: TargetConfirming Thuận Thủ=%arg; SkillEffect=%arg2; mở tướng=%arg3; hủy mục tiêu=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(targetCancelled),
    arg5 = qianxunIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-qianxun target_confirming=snatch effect=true slot=%s revealed=%s cancelled=%s victim_retained=true revision=%s",
    qianxunIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenKongcheng(room, state)
  -- 空城's TargetConfirming branch is conditional on a genuinely empty hand.
  -- Empty the actor through the native move path before the real Duel so the
  -- scenario proves the source predicate instead of merely proving reveal.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-kongcheng actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__kongcheng") then
    fail("hidden-kongcheng must attach the hidden Kongcheng skill")
  end
  if state.actor:hasSkill("hs__kongcheng") then
    fail("hidden-kongcheng must not be active before TargetConfirming")
  end
  state.actor:throwAllCards("h", "tqs_qa")
  if not state.actor:isKongcheng() then
    fail("hidden-kongcheng actor must be empty-handed before the Duel gate")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_kongcheng_gate",
    prompt = "TQS QA: prelight Không Thành, rồi xác nhận để đối thủ dùng Quyết Đấu.",
  })
  if not gate then
    fail("hidden-kongcheng readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__kongcheng") then
    fail("hidden-kongcheng must be prelighted before TargetConfirming")
  end

  local duelId = state.slotCards["kongcheng-duel"]
  if not duelId or not table.contains(state.target:getCardIds(Player.Hand), duelId) then
    fail("hidden-kongcheng must put its reserved Duel in the source hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { duelId },
    skill_name = "tqs_qa_hidden_kongcheng_duel",
    prompt = "TQS QA: dùng Quyết Đấu lên Gia Cát Lượng để kiểm tra Không Thành.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= duelId or use.card.trueName ~= "duel" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-kongcheng must receive the reserved Duel against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__kongcheng" and entry.player == state.actor.id
  end)
  local kongchengIsDeputy = state.scenario == "hidden-kongcheng-deputy"
  local revealedCorrectSlot = kongchengIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhugeliang"
    or not kongchengIsDeputy and state.actor.general == "hs__zhugeliang" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(duelId) == Card.DiscardPile and
    state.actor:isKongcheng()
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Kongcheng must run a real SkillEffect and reveal Zhuge Liang in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Kongcheng must cancel the valid Duel target while empty-handed")
  end
  if state.actor:isFakeSkill("hs__kongcheng") or not state.actor:hasSkill("hs__kongcheng") then
    fail("hidden Kongcheng must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Không Thành: TargetConfirming Quyết Đấu=%arg; SkillEffect=%arg2; hết bài=%arg3; mở tướng=%arg4; hủy mục tiêu=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(state.actor:isKongcheng()),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(targetCancelled),
    arg6 = kongchengIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-kongcheng target_confirming=duel effect=true empty_hand=true slot=%s revealed=%s cancelled=%s revision=%s",
    kongchengIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenWeimu(room, state)
  -- 帷幕 has two separate native branches: TargetConfirming cancels a black
  -- Trick target, while BeforeCardsMove mirrors a black delayed Trick away
  -- from the actor's Judge area. Keep both branches in one scenario family so
  -- hidden main/deputy reveal and fake-to-active conversion are checked the
  -- same way for each source predicate.
  local indulgenceScenario = state.scenario == "hidden-weimu-indulgence" or
    state.scenario == "hidden-weimu-indulgence-deputy"
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-weimu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__weimu") then
    fail("hidden-weimu must attach the hidden Weimu skill")
  end
  if state.actor:hasSkill("hs__weimu") then
    fail("hidden-weimu must not be active before its source event")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_weimu_gate",
    prompt = indulgenceScenario
      and "TQS QA: prelight 帷幕, rồi xác nhận để đối thủ dùng Lạc Bất Tư Thục đen."
      or "TQS QA: prelight 帷幕, rồi xác nhận để đối thủ dùng Quyết Đấu đen.",
  })
  if not gate then
    fail("hidden-weimu readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__weimu") then
    fail("hidden-weimu must be prelighted before its source event")
  end

  if indulgenceScenario then
    local indulgenceId = state.slotCards["weimu-indulgence"]
    if not indulgenceId or not table.contains(state.target:getCardIds(Player.Hand), indulgenceId) then
      fail("hidden-weimu indulgence must put its reserved black Indulgence in the source hand")
    end

    state.currentDamageStep = 1
    local use = room:askToUseRealCard(state.target, {
      pattern = { indulgenceId },
      skill_name = "tqs_qa_hidden_weimu_indulgence",
      prompt = "TQS QA: dùng Lạc Bất Tư Thục đen lên Giả Hủ để kiểm tra 帷幕.",
      extra_data = {
        bypass_times = true, bypass_distances = true, extraUse = true,
        exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      },
      cancelable = true,
      skip = true,
    })
    if not use or not use.card or use.card.id ~= indulgenceId or
        use.card.trueName ~= "indulgence" or use.card:getColorString() ~= "black" or
        #use.tos ~= 1 or use.tos[1] ~= state.actor then
      fail("hidden-weimu indulgence must receive the reserved black Indulgence against the actor")
    end
    use.extraUse = true
    room:useCard(use)
    state.currentDamageStep = nil

    local effect = table.find(state.skillEffects, function(entry)
      return entry.step == 1 and entry.skill == "hs__weimu" and entry.player == state.actor.id
    end)
    local weimuIsDeputy = state.scenario == "hidden-weimu-indulgence-deputy"
    local revealedCorrectSlot = weimuIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__jiaxu"
      or not weimuIsDeputy and state.actor.general == "hs__jiaxu" and state.actor.deputyGeneral == "anjiang"
    local cancelledJudgeMove = room:getCardArea(indulgenceId) == Card.DiscardPile and
      #state.actor:getCardIds(Player.Judge) == 0
    if not effect or effect.fake or not revealedCorrectSlot then
      fail("prelighted hidden Weimu must run a real SkillEffect and reveal Jia Xu in its catalogued slot")
    end
    if not cancelledJudgeMove then
      fail("hidden Weimu must cancel the black Indulgence judge move and discard the card")
    end
    if state.actor:isFakeSkill("hs__weimu") or not state.actor:hasSkill("hs__weimu") then
      fail("hidden Weimu must convert from fake to active after reveal")
    end

    room:sendLog{
      type = "[TQS QA] Hidden 帷幕: BeforeCardsMove Lạc Bất Tư Thục đen=%arg; SkillEffect=%arg2; mở tướng=%arg3; vào phán xét=%arg4; chuyển bỏ=%arg5; vị trí=%arg6",
      from = state.actor.id,
      arg = "true",
      arg2 = "true",
      arg3 = tostring(revealedCorrectSlot),
      arg4 = "false",
      arg5 = tostring(cancelledJudgeMove),
      arg6 = weimuIsDeputy and "phó tướng" or "chủ tướng",
    }
    fk.qInfo(string.format("[tqs_qa] hidden-weimu before_cards_move=black_indulgence effect=true slot=%s revealed=%s judge_move_cancelled=%s discarded=true revision=%s",
      weimuIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(cancelledJudgeMove), manifest.sourceRevision))
    state.gameOverRequested = true
    room:gameOver("")
    return
  end

  local duelId = state.slotCards["weimu-duel"]
  if not duelId or not table.contains(state.target:getCardIds(Player.Hand), duelId) then
    fail("hidden-weimu must put its reserved black Duel in the source hand")
  end

  local beforeHp = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { duelId },
    skill_name = "tqs_qa_hidden_weimu_duel",
    prompt = "TQS QA: dùng Quyết Đấu đen lên Giả Hủ để kiểm tra 帷幕.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= duelId or use.card.trueName ~= "duel" or
      use.card:getColorString() ~= "black" or #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-weimu must receive the reserved black Duel against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__weimu" and entry.player == state.actor.id
  end)
  local weimuIsDeputy = state.scenario == "hidden-weimu-deputy"
  local revealedCorrectSlot = weimuIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__jiaxu"
    or not weimuIsDeputy and state.actor.general == "hs__jiaxu" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(duelId) == Card.DiscardPile and state.actor.hp == beforeHp
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Weimu must run a real SkillEffect and reveal Jia Xu in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Weimu must cancel the valid black Duel target before damage")
  end
  if state.actor:isFakeSkill("hs__weimu") or not state.actor:hasSkill("hs__weimu") then
    fail("hidden Weimu must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 帷幕: TargetConfirming Quyết Đấu đen=%arg; SkillEffect=%arg2; mở tướng=%arg3; hủy mục tiêu=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(targetCancelled),
    arg5 = weimuIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-weimu target_confirming=black_duel effect=true slot=%s revealed=%s cancelled=%s damage=0 revision=%s",
    weimuIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenXiaoji(room, state)
  -- 枭姬 is an AfterCardsMove trigger. The actor remains face-down while a
  -- real equipment card is moved out of PlayerEquip; the native effect must
  -- reveal Sun Shangxiang in the owning slot before drawing.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-xiaoji actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__xiaoji") then
    fail("hidden-xiaoji must attach the hidden Xiaoji skill")
  end
  if state.actor:hasSkill("hs__xiaoji") then
    fail("hidden-xiaoji must not be active before AfterCardsMove")
  end

  local equipId = state.slotCards["xiaoji-equip"]
  if not equipId or room:getCardArea(equipId) ~= Card.PlayerEquip or
      not table.contains(state.actor:getCardIds(Player.Equip), equipId) then
    fail("hidden-xiaoji must put its reserved equipment in the actor equipment area")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_xiaoji_gate",
    prompt = "TQS QA: prelight 枭姬, rồi xác nhận để mất trang bị thật.",
  })
  if not gate then
    fail("hidden-xiaoji QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__xiaoji") then
    fail("hidden-xiaoji must be prelighted before the equipment-loss branch")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  local expectedDraw = room.current == state.actor and 1 or 3
  state.currentDamageStep = 1
  room:throwCard(equipId, "tqs_qa_hidden_xiaoji", state.actor, state.actor)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__xiaoji" and entry.player == state.actor.id
  end)
  local xiaojiIsDeputy = state.scenario == "hidden-xiaoji-deputy"
  local revealedCorrectSlot = xiaojiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__sunshangxiang"
    or not xiaojiIsDeputy and state.actor.general == "hs__sunshangxiang" and state.actor.deputyGeneral == "anjiang"
  local drawn = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == 1 and move.skill == "hs__xiaoji" and move.to == state.actor.id and
        move.fromArea == Card.DrawPile then
      drawn = drawn + move.count
    end
  end
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Xiaoji must run a real SkillEffect and reveal Sun Shangxiang in its catalogued slot")
  end
  if room:getCardArea(equipId) ~= Card.DiscardPile or drawn ~= expectedDraw or
      afterHand ~= beforeHand + expectedDraw then
    fail(string.format("hidden Xiaoji must discard the equipment and draw %d card(s)", expectedDraw))
  end
  if state.actor:isFakeSkill("hs__xiaoji") or not state.actor:hasSkill("hs__xiaoji") then
    fail("hidden Xiaoji must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 枭姬: AfterCardsMove mất trang bị=%arg; SkillEffect=%arg2; mở tướng=%arg3; bốc bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(drawn),
    arg5 = xiaojiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-xiaoji after_cards_move=equipment effect=true slot=%s revealed=%s drawn=%d expected=%d revision=%s",
    xiaojiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawn, expectedDraw,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenGuanxing(room, state)
  -- 观星 is an optional EventPhaseStart trigger. The QA pause is separate
  -- from the source trigger: it gives the browser a real opportunity to
  -- prelight the hidden skill before the native event is raised.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-guanxing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__guanxing") then
    fail("hidden-guanxing must attach the hidden Guanxing skill")
  end
  if state.actor:hasSkill("hs__guanxing") then
    fail("hidden-guanxing must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_guanxing_gate",
    prompt = "TQS QA: prelight 观星, rồi xác nhận để bắt đầu pha chuẩn bị.",
  })
  if not gate then
    fail("hidden-guanxing readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__guanxing") then
    fail("hidden-guanxing must be prelighted before the EventPhaseStart branch")
  end

  -- With two live players the source skill must ask the native arrange dialog
  -- for exactly two top cards. The skill itself calls getNCards/askToGuanxing;
  -- this director only records the expected native cards so completion can be
  -- checked after the real AskForArrangeCards reply returns.
  state.guanxingCards = table.simpleClone(room:getNCards(math.min(5, #room.alive_players)))
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Start)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Start,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__guanxing" and entry.player == state.actor.id
  end)
  local guanxingIsDeputy = state.scenario == "hidden-guanxing-deputy"
  local revealedCorrectSlot = guanxingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhugeliang"
    or not guanxingIsDeputy and state.actor.general == "hs__zhugeliang" and state.actor.deputyGeneral == "anjiang"
  local arranged = #state.guanxingCards == 2
  for _, id in ipairs(state.guanxingCards) do
    if room:getCardArea(id) ~= Card.DrawPile then
      arranged = false
      break
    end
  end
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Guanxing must run a real SkillEffect and reveal Zhuge Liang in its catalogued slot")
  end
  if not arranged then
    fail("hidden Guanxing must return both native top cards to the draw pile after AskForArrangeCards")
  end
  if state.actor:isFakeSkill("hs__guanxing") or not state.actor:hasSkill("hs__guanxing") then
    fail("hidden Guanxing must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 观星: EventPhaseStart=%arg; AskForArrangeCards=%arg2; SkillEffect=%arg3; mở tướng=%arg4; đã xếp=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(arranged),
    arg6 = guanxingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-guanxing event_phase_start=guanxing arrange=true effect=true slot=%s revealed=%s cards=%d revision=%s",
    guanxingIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), #state.guanxingCards,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenYingzi(room, state)
  -- 英姿 is compulsory on fk.DrawNCards. The QA pause is deliberately
  -- separate from that source event: it gives the browser a real chance to
  -- prelight the hidden skill while both general slots are still anjiang.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-yingzi actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ex__yingzi") then
    fail("hidden-yingzi must attach the hidden ex__yingzi skill")
  end
  if state.actor:hasSkill("ex__yingzi") then
    fail("hidden-yingzi must not be active before the prelighted draw trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_yingzi_gate",
    prompt = "TQS QA: prelight 英姿, rồi xác nhận để bắt đầu pha rút bài.",
  })
  if not gate then
    fail("hidden-yingzi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "ex__yingzi") then
    fail("hidden-yingzi must be prelighted before the DrawNCards branch")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Draw)
  room:broadcastProperty(state.actor, "phase")
  local phaseData = {
    who = state.actor,
    reason = "game_rule",
    phase = Player.Draw,
  }
  room.logic:trigger(fk.EventPhaseStart, state.actor, phaseData)
  room.logic:trigger(fk.EventPhaseProceeding, state.actor, phaseData)

  -- This is the same draw-phase sequence used by the native Phase event:
  -- base count 2 -> fk.DrawNCards modifiers -> actual draw -> AfterDrawNCards.
  local drawData = {
    who = state.actor,
    reason = "game_rule",
    phase = Player.Draw,
    n = 2,
  }
  room.logic:trigger(fk.DrawNCards, state.actor, drawData)
  if drawData.n > 0 then
    room:drawCards(state.actor, drawData.n, "phase_draw")
  end
  room.logic:trigger(fk.AfterDrawNCards, state.actor, drawData)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "ex__yingzi" and entry.player == state.actor.id
  end)
  local drawEvent = table.find(state.drawEvents, function(entry)
    return entry.step == 1 and entry.player == state.actor.id and entry.stage == "after"
  end)
  local yingziIsDeputy = state.scenario == "hidden-yingzi-deputy"
  local revealedCorrectSlot = yingziIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhouyu"
    or not yingziIsDeputy and state.actor.general == "hs__zhouyu" and state.actor.deputyGeneral == "anjiang"
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Yingzi must run a real SkillEffect and reveal Zhou Yu in its catalogued slot")
  end
  if not drawEvent or drawEvent.n ~= 3 then
    fail(string.format("hidden Yingzi must raise DrawNCards from 2 to 3, observed %s", drawEvent and drawEvent.n or "none"))
  end
  if afterHand ~= beforeHand + 3 then
    fail(string.format("hidden Yingzi must draw three cards, hand changed from %d to %d", beforeHand, afterHand))
  end
  if state.actor:isFakeSkill("ex__yingzi") or not state.actor:hasSkill("ex__yingzi") then
    fail("hidden Yingzi must convert from fake to active after the native DrawNCards effect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 英姿: DrawNCards=%arg; AfterDrawNCards=%arg2; SkillEffect=%arg3; mở tướng=%arg4; bốc bài=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = tostring(drawEvent ~= nil),
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(drawEvent and drawEvent.n or 0),
    arg6 = yingziIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-yingzi draw_n_cards=true after_draw_n=%d effect=true slot=%s revealed=%s drawn=%d revision=%s",
    drawEvent.n, yingziIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawEvent.n,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenTianxiang(room, state)
  -- 天香 is a real DetermineDamageInflicted interaction: the hidden owner
  -- must remain fake until the player has selected a heart card and a target.
  -- SkillEffect then reveals Xiao Qiao before the source effect prevents the
  -- incoming damage and asks for the native lose-HP/damage branch.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-tianxiang actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__tianxiang") then
    fail("hidden-tianxiang must attach the hidden Tianxiang skill")
  end
  if state.actor:hasSkill("hs__tianxiang") then
    fail("hidden-tianxiang must not be active before the damage trigger")
  end

  local cardId = state.slotCards["tianxiang-heart"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      Fk:getCardById(cardId):getSuitString() ~= "heart" then
    fail("hidden-tianxiang must put the reserved heart card in the actor hand")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_tianxiang_gate",
    prompt = "TQS QA: prelight Thiên Hương, rồi xác nhận để nhận sát thương.",
  })
  if not gate then
    fail("hidden-tianxiang QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__tianxiang") then
    fail("hidden-tianxiang must be prelighted before DetermineDamageInflicted")
  end

  local actorHp = state.actor.hp
  local targetHp = state.target.hp
  state.currentDamageStep = 1
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_tianxiang_damage",
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__tianxiang" and entry.player == state.actor.id
  end)
  local tianxiangIsDeputy = state.scenario == "hidden-tianxiang-deputy"
  local revealedCorrectSlot = tianxiangIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__xiaoqiao"
    or not tianxiangIsDeputy and state.actor.general == "hs__xiaoqiao" and state.actor.deputyGeneral == "anjiang"
  local cardObtained = table.contains(state.target:getCardIds(Player.Hand), cardId) and
    not table.contains(state.actor:getCardIds(Player.Hand), cardId)
  local damagePrevented = state.actor.hp == actorHp
  local targetLostHp = state.target.hp == targetHp - 1

  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Tianxiang must run a real SkillEffect and reveal Xiao Qiao in its catalogued slot")
  end
  if not damagePrevented or not targetLostHp or not cardObtained then
    fail("hidden Tianxiang must prevent the incoming damage, make the target lose 1 HP and return the heart card")
  end
  if state.actor:isFakeSkill("hs__tianxiang") or not state.actor:hasSkill("hs__tianxiang") then
    fail("hidden Tianxiang must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Thiên Hương: DetermineDamageInflicted=%arg; AskForUseActiveSkill=%arg2; AskForChoices=%arg3; SkillEffect=%arg4; sát thương bị chặn=%arg5; mục tiêu mất HP=%arg6; trả bài=%arg7; mở tướng=%arg8; vị trí=%arg9",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = "true",
    arg5 = tostring(damagePrevented),
    arg6 = tostring(targetLostHp),
    arg7 = tostring(cardObtained),
    arg8 = tostring(revealedCorrectSlot),
    arg9 = tianxiangIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-tianxiang determine_damage_inflicted=true choose_card_target=true choice=lose_hp effect=true prevented=%s target_lost_hp=%s card_returned=%s slot=%s revealed=%s revision=%s",
    tostring(damagePrevented), tostring(targetLostHp), tostring(cardObtained),
    tianxiangIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenDuanchang(room, state)
  -- 断肠 is a compulsory fk.Death trigger.  Keep 蔡文姬 hidden and
  -- prelighted until the real death event; the native GameOverJudge may
  -- reveal a dead player before fk.Death, but it must not skip the trigger.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-duanchang actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__duanchang") then
    fail("hidden-duanchang must attach the hidden Duanchang skill")
  end
  if state.actor:hasSkill("hs__duanchang") then
    fail("hidden-duanchang must not be active before the death trigger")
  end
  if not state.target:hasSkill("hs__jianxiong") or not state.target:hasSkill("fankui") then
    fail("hidden-duanchang killer must expose Cao Cao Jianxiong and Sima Yi Fankui")
  end

  -- With four seats, GameOverJudge must not decide the match before fk.Death.
  -- Pin an additional living bot to Shu so the Wei killer cannot be the only
  -- surviving kingdom by accident.
  for _, player in ipairs(room.alive_players) do
    if player ~= state.actor and player ~= state.target then
      room:setPlayerProperty(player, "kingdom", "shu")
      player.role = "shu"
      room:setPlayerMark(player, "__heg_kingdom", "shu")
      room:broadcastProperty(player, "kingdom")
      room:broadcastProperty(player, "role")
    end
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_duanchang_gate",
    prompt = "TQS QA: prelight Đoạn Trường, rồi xác nhận để xử lý khi chết.",
  })
  if not gate then
    fail("hidden-duanchang QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__duanchang") then
    fail("hidden-duanchang must be prelighted before fk.Death")
  end

  state.currentDamageStep = 1
  room:killPlayer({
    who = state.actor,
    killer = state.target,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__duanchang" and entry.player == state.actor.id
  end)
  local duanchangIsDeputy = state.scenario == "hidden-duanchang-deputy"
  local expectedMain = duanchangIsDeputy and "hs__yuanshao" or "hs__caiwenji"
  local expectedDeputy = duanchangIsDeputy and "hs__caiwenji" or "hs__yuanshao"
  local actorRevealed = state.actor.dead and state.actor.general == expectedMain and
    state.actor.deputyGeneral == expectedDeputy
  local mark = state.target:getMark("@hs__duanchang")
  local killerMainChosen = type(mark) == "table" and table.contains(mark, "hs__caocao")
  local killerMainSkillsLost = not state.target:hasSkill("hs__jianxiong")
  local killerDeputySkillsRetained = state.target:hasSkill("fankui")

  if not effect or effect.fake then
    fail("prelighted hidden Duanchang must run a real SkillEffect on fk.Death")
  end
  if not actorRevealed then
    fail("hidden Duanchang death must reveal the catalogued Cai Wenji slot pair")
  end
  if not killerMainChosen or not killerMainSkillsLost or not killerDeputySkillsRetained then
    fail("hidden Duanchang must remove only the killer's chosen Cao Cao skills")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Đoạn Trường: Death=%arg; SkillEffect=%arg2; người chết mở tướng=%arg3; killer chọn chủ tướng=%arg4; killer mất kỹ năng chủ=%arg5; kỹ năng phó còn lại=%arg6; vị trí=%arg7",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(actorRevealed),
    arg4 = tostring(killerMainChosen),
    arg5 = tostring(killerMainSkillsLost),
    arg6 = tostring(killerDeputySkillsRetained),
    arg7 = duanchangIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-duanchang death=true skill_effect=true choice=main_general killer_main_skills_lost=%s killer_deputy_skills_retained=%s actor_revealed=%s slot=%s revision=%s",
    tostring(killerMainSkillsLost), tostring(killerDeputySkillsRetained), tostring(actorRevealed),
    duanchangIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local director = fk.CreateSkill {
  name = "tqs_qa_director&",
}

director:addEffect(fk.SkillEffect, {
  global = true,
  priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "fazheng-enyuan" or state.scenario == "hidden-enyuan" or
      state.scenario == "hidden-enyuan-deputy" or state.scenario == "hidden-yiji" or
      state.scenario == "hidden-fuyin" or state.scenario == "hidden-fuyin-deputy" or
      state.scenario == "hidden-yiji-deputy" or state.scenario == "hidden-jianxiong" or
      state.scenario == "hidden-rehide-yiji" or state.scenario == "hidden-rehide-yiji-deputy" or
      state.scenario == "hidden-jianxiong-deputy" or state.scenario == "hidden-fankui" or
      state.scenario == "hidden-fankui-deputy" or state.scenario == "hidden-reveal" or
      state.scenario == "hidden-reveal-deputy" or state.scenario == "hidden-active" or
      state.scenario == "hidden-active-main" or state.scenario == "hidden-fanjian" or
      state.scenario == "hidden-fanjian-deputy" or state.scenario == "hidden-view-as" or
      state.scenario == "hidden-view-as-main" or state.scenario == "hidden-dual" or
      state.scenario == "hidden-luoshen" or state.scenario == "hidden-luoshen-deputy" or
      state.scenario == "hidden-tiandu" or state.scenario == "hidden-tiandu-deputy" or
      state.scenario == "hidden-jizhi" or state.scenario == "hidden-jizhi-deputy" or
      state.scenario == "hidden-mingshi" or state.scenario == "hidden-mingshi-deputy" or
      state.scenario == "hidden-gongqing" or state.scenario == "hidden-gongqing-deputy" or
      state.scenario == "hidden-qianxun" or state.scenario == "hidden-qianxun-deputy" or
      state.scenario == "hidden-qianxun-indulgence" or
      state.scenario == "hidden-qianxun-indulgence-deputy" or
      state.scenario == "hidden-kongcheng" or
      state.scenario == "hidden-kongcheng-deputy" or
      state.scenario == "hidden-weimu" or
      state.scenario == "hidden-weimu-deputy" or
      state.scenario == "hidden-weimu-indulgence" or
      state.scenario == "hidden-weimu-indulgence-deputy" or
      state.scenario == "hidden-xiaoji" or
      state.scenario == "hidden-xiaoji-deputy" or
      state.scenario == "hidden-guanxing" or
      state.scenario == "hidden-guanxing-deputy" or
      state.scenario == "hidden-yingzi" or
      state.scenario == "hidden-yingzi-deputy" or
      state.scenario == "hidden-tianxiang" or
      state.scenario == "hidden-tianxiang-deputy" or
      state.scenario == "hidden-duanchang" or
      state.scenario == "hidden-duanchang-deputy" or
      state.scenario == "hidden-kuanggu" or
      state.scenario == "hidden-kuanggu-deputy" or
      state.scenario == "hidden-liegong" or
      state.scenario == "hidden-liegong-deputy" or
      state.scenario == "hidden-jueqing" or
      state.scenario == "hidden-jueqing-deputy" or
      state.scenario == "hidden-ejue" or
      state.scenario == "hidden-ejue-deputy" or
      state.scenario == "hidden-dufu" or
      state.scenario == "hidden-dufu-deputy" or
      state.scenario == "hidden-jianzhi" or
      state.scenario == "hidden-jianzhi-deputy" or
      state.scenario == "hidden-zhiman" or
      state.scenario == "hidden-zhiman-deputy" or
      state.scenario == "hidden-jilix" or
      state.scenario == "hidden-jilix-deputy") and
      data and data.skill
  end,
  on_trigger = function(self, event, target, player, data)
    recordSkillEffect(stateFor(player.room), player, data)
  end,
})

director:addEffect(fk.SkillEffect, {
  global = true,
  priority = -999,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    local replay = state and state.prompt4EffectReplay
    return replay and replay.active == true and data and data.skill
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    local replay = state and state.prompt4EffectReplay
    if replay then
      replay.observedSkillEffects = replay.observedSkillEffects + 1
      local skillName = actualSkillName(data.skill)
      if not table.contains(replay.observedSkillNames, skillName) then
        table.insert(replay.observedSkillNames, skillName)
      end
      if skillName == replay.requestedSkill then
        replay.skillEffects = replay.skillEffects + 1
        -- SkillEffect is global and the trigger dispatcher visits every
        -- room player.  The skill owner lives on SkillEffectData; checking
        -- the dispatcher participant would incorrectly inherit a hidden
        -- browser seat's fake skill state into this native replay result.
        local owner = data.who or target or player
        replay.fake = replay.fake or owner:isFakeSkill(data.skill)
      end
    end
  end,
})

director:addEffect(fk.PreDamage, {
  global = true,
  -- DamageEvent:breakCheck() stops lower-priority PreDamage observers after
  -- a prevention skill such as Jueqing calls data:preventDamage(). Observe
  -- before the real skill so the QA marker proves that the native
  -- PreDamage branch was entered, without changing the source-law ordering
  -- of any production skill.
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-jueqing" or state.scenario == "hidden-jueqing-deputy") and
      state.currentDamageStep and data and data.from == state.actor
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).jueqingPreDamage = true
  end,
})

-- Chế Man calls data:preventDamage(). DamageEvent:breakCheck() stops lower
-- priority observers after that prevention, so record entry into the native
-- DamageCaused event before production effects rather than after them.
director:addEffect(fk.DamageCaused, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-zhiman" or state.scenario == "hidden-zhiman-deputy") and
      state.currentDamageStep and data and data.from == state.actor and data.to == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).hiddenZhimanDamageCaused = true
  end,
})

director:addEffect(fk.DamageCaused, {
  global = true,
  priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-ejue" or state.scenario == "hidden-ejue-deputy" or
      state.scenario == "hidden-dufu" or state.scenario == "hidden-dufu-deputy" or
      state.scenario == "hidden-jianzhi" or state.scenario == "hidden-jianzhi-deputy" or
      state.scenario == "hidden-zhiman" or state.scenario == "hidden-zhiman-deputy") and
      state.currentDamageStep and data and data.from == state.actor and data.to == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    if state.scenario == "hidden-dufu" or state.scenario == "hidden-dufu-deputy" then
      state.hiddenDufuDamageCaused = true
    elseif state.scenario == "hidden-jianzhi" or state.scenario == "hidden-jianzhi-deputy" then
      state.hiddenJianzhiDamageCaused = true
    elseif state.scenario == "hidden-zhiman" or state.scenario == "hidden-zhiman-deputy" then
      state.hiddenZhimanDamageCaused = true
    else
      state.hiddenEjueDamageCaused = true
    end
  end,
})

for _, eventName in ipairs({fk.BeforeHpChanged, fk.Damage}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      if not state or (state.scenario ~= "hidden-kuanggu" and state.scenario ~= "hidden-kuanggu-deputy" and
          state.scenario ~= "hidden-liegong" and state.scenario ~= "hidden-liegong-deputy") or
          not state.currentDamageStep or player ~= player.room.players[1] or not data then
        return false
      end
      if eventName == fk.BeforeHpChanged then
        return data.damageEvent and data.damageEvent.from == state.actor
      end
      return data.from == state.actor
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      if eventName == fk.BeforeHpChanged then
        if state.scenario == "hidden-kuanggu" or state.scenario == "hidden-kuanggu-deputy" then
          state.kuangguBeforeHpChanged = true
        end
      else
        if state.scenario == "hidden-kuanggu" or state.scenario == "hidden-kuanggu-deputy" then
          state.kuangguDamage = true
        elseif state.scenario == "hidden-liegong" or state.scenario == "hidden-liegong-deputy" then
          state.liegongDamage = true
        end
      end
    end,
  })
end

director:addEffect(fk.TargetSpecified, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-liegong" or state.scenario == "hidden-liegong-deputy") and
      state.currentDamageStep and player == player.room.players[1] and data and data.from == state.actor and
      data.card and data.card.trueName == "slash"
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).liegongTargetSpecified = true
  end,
})

-- Observe engine events once per room; no card ids are published in QA logs.
for _, eventName in ipairs({fk.CardUsing, fk.CardResponding}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      return state and state.currentDamageStep and player == player.room.players[1]
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      table.insert(state.cardEvents, { step = state.currentDamageStep, player = data.from.id,
        name = data.card.trueName, subcards = table.simpleClone(data.card.subcards),
        longdan = table.contains(data.card.skillNames, "hs__longdan") })
    end,
  })
end

director:addEffect(fk.Damaged, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.currentDamageStep and target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    table.insert(state.damageEvents, { step = state.currentDamageStep,
      from = data.from and data.from.id, to = data.to.id, amount = data.damage })
  end,
})

director:addEffect(fk.TargetConfirmed, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-enyuan" or state.scenario == "hidden-enyuan-deputy") and
      state.currentDamageStep and target == state.actor and data and data.card and
      data.card.trueName == "peach" and data.from == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).hiddenEnyuanTargetConfirmed = true
  end,
})

director:addEffect(fk.TargetConfirmed, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-fuyin" or state.scenario == "hidden-fuyin-deputy") and
      state.currentDamageStep and target == state.actor and data and data.card and
      data.card.trueName == "slash" and data.from == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenFuyinTargetConfirmed = true
    state.hiddenFuyinNullified = data.nullified == true or
      (data.use and data.use.nullifiedTargets and table.contains(data.use.nullifiedTargets, state.actor))
  end,
})

director:addEffect(fk.TargetConfirmed, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-jilix" or state.scenario == "hidden-jilix-deputy") and
      state.currentDamageStep and target == state.actor and data and data.card and
      data.card.trueName == "slash" and data.card.color == Card.Red and data.from == state.target and
      data:isOnlyTarget(state.actor)
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).hiddenJilixTargetConfirmed = true
  end,
})

director:addEffect(fk.DamageInflicted, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-jilix" or state.scenario == "hidden-jilix-deputy") and
      state.currentDamageStep and target == state.actor and data and data.from == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenJilixDamageInflicted = state.hiddenJilixDamageInflicted + 1
  end,
})

director:addEffect(fk.AfterCardsMove, {
  global = true, priority = -999,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-enyuan" or state.scenario == "hidden-enyuan-deputy") and
      state.currentDamageStep and type(data) == "table"
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    for _, move in ipairs(data) do
      if move.skillName == "ld__enyuan" and move.to == state.target and
          move.toArea == Card.PlayerHand then
        -- A single native draw can be represented by more than one
        -- moveInfo entry while the move is normalized.  Count card ids,
        -- not raw entries, so the QA assertion measures the actual card
        -- movement rather than an intermediate duplicate.
        for _, info in ipairs(move.moveInfo or {}) do
          if info.cardId then
            table.insertIfNeed(state.hiddenEnyuanDrawCards, info.cardId)
          end
        end
        state.hiddenEnyuanDrawCount = #state.hiddenEnyuanDrawCards
      end
    end
  end,
})

director:addEffect(fk.AfterCardsMove, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.currentDamageStep and player == player.room.players[1]
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand then
        local firstInfo = move.moveInfo and move.moveInfo[1]
        table.insert(state.skillMoves, { step = state.currentDamageStep, skill = move.skillName,
          from = move.from and move.from.id, to = move.to and move.to.id, count = #move.moveInfo,
          fromArea = firstInfo and firstInfo.fromArea })
      end
    end
  end,
})

for _, eventName in ipairs({fk.DrawNCards, fk.AfterDrawNCards}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      return state and state.currentDamageStep and target == state.actor and player == player.room.players[1]
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      table.insert(state.drawEvents, {
        step = state.currentDamageStep,
        stage = eventName == fk.DrawNCards and "before" or "after",
        player = target.id,
        n = data.n,
      })
    end,
  })
end

director:addEffect(fk.GamePrepared, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return player == player.room.players[1] and not stateFor(player.room)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local scenario, seed = parseRequest(room)
    if not scenario then return false end
    setupState(room, scenario, seed)
  end,
})

director:addEffect(fk.DrawInitialCards, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and target == player and state.fixedHands[player.id] ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    local ids = stateFor(player.room).fixedHands[player.id]
    data.num = #ids
    data.fix_ids = table.simpleClone(ids)
  end,
})

director:addEffect(fk.GameStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and not state.gameStartDone
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local state = stateFor(room)
    state.gameStartDone = true
    shuffleTail(room, state.seed)
    local scenario = scenarioById[state.scenario]
    if scenario.trigger == "rescue" or scenario.trigger == "rescue-battle" then
      triggerRescue(room, state)
    elseif scenario.trigger == "founding" then
      triggerFounding(room, state)
    elseif scenario.trigger == "damage-exchange" then
      triggerDamageExchange(room, state)
    elseif scenario.trigger == "hidden-yiji" then
      triggerHiddenYiji(room, state)
    elseif scenario.trigger == "hidden-rehide-yiji" then
      state.rehideAfterYiji = true
      triggerHiddenYiji(room, state)
    elseif scenario.trigger == "hidden-jianxiong" then
      triggerHiddenJianxiong(room, state)
    elseif scenario.trigger == "hidden-fankui" then
      triggerHiddenFankui(room, state)
    elseif scenario.trigger == "hidden-enyuan" then
      triggerHiddenEnyuan(room, state)
    elseif scenario.trigger == "hidden-fuyin" then
      -- 父荫's official predicate searches the current turn history. Defer
      -- the real Slash until the actor's Start phase so the QA director
      -- exercises the same TargetConfirmed context as a live turn.
      state.hiddenFuyinPending = true
    elseif scenario.trigger == "hidden-kuanggu" then
      triggerHiddenKuanggu(room, state)
    elseif scenario.trigger == "hidden-liegong" then
      triggerHiddenLiegong(room, state)
    elseif scenario.trigger == "hidden-reveal" then
      triggerHiddenReveal(room, state)
    elseif scenario.trigger == "hidden-active" then
      runAiDecisionProbe(room, state)
      triggerHiddenActive(room, state)
    elseif scenario.trigger == "ai-trace" then
      runAiTraceProbe(room, state)
      runPrompt4NativeProbe(room, state)
      emitPrompt4NativeTrace(state)
      emitPrompt4Provenance(room, state)
      runAiSupportedGeneralPairProbe(room, state)
      state.gameOverRequested = true
      room:gameOver("")
    elseif scenario.trigger == "chooser-trace" then
      -- Persist bounded native metadata before the GameOver event; some
      -- builds do not dispatch a second room-targeted GameFinished callback.
      runChooserTraceProbe(room, state)
      emitPrompt4Provenance(room, state)
      state.gameOverRequested = true
      room:gameOver("")
    elseif scenario.trigger == "general-pair-trace" then
      local trace = state.generalPairTrace
      if not trace or (trace.total or 0) < 1 then
        fail("general-pair-trace did not observe a native AI CustomDialog decision")
      end
      -- The bounded probe ends from GameStart, where some native builds do
      -- not dispatch a second room-targeted GameFinished callback before the
      -- worker returns. Emit while the state is unquestionably attached so
      -- the sanitized decision evidence is durable in either event model.
      emitGeneralPairTrace(state)
      state.gameOverRequested = true
      room:gameOver("")
    elseif scenario.trigger == "hidden-fanjian" then
      triggerHiddenFanjian(room, state)
    elseif scenario.trigger == "hidden-view-as" then
      triggerHiddenViewAs(room, state)
    elseif scenario.trigger == "hidden-dual" then
      triggerHiddenDual(room, state)
    elseif scenario.trigger == "hidden-luoshen" then
      triggerHiddenLuoshen(room, state)
    elseif scenario.trigger == "hidden-tiandu" then
      triggerHiddenTiandu(room, state)
    elseif scenario.trigger == "hidden-jizhi" then
      triggerHiddenJizhi(room, state)
    elseif scenario.trigger == "hidden-mingshi" then
      triggerHiddenMingshi(room, state)
    elseif scenario.trigger == "hidden-gongqing" then
      triggerHiddenGongqing(room, state)
    elseif scenario.trigger == "hidden-qianxun" then
      triggerHiddenQianxun(room, state)
    elseif scenario.trigger == "hidden-kongcheng" then
      triggerHiddenKongcheng(room, state)
    elseif scenario.trigger == "hidden-weimu" then
      triggerHiddenWeimu(room, state)
    elseif scenario.trigger == "hidden-xiaoji" then
      triggerHiddenXiaoji(room, state)
    elseif scenario.trigger == "hidden-guanxing" then
      triggerHiddenGuanxing(room, state)
    elseif scenario.trigger == "hidden-yingzi" then
      triggerHiddenYingzi(room, state)
    elseif scenario.trigger == "hidden-tianxiang" then
      triggerHiddenTianxiang(room, state)
    elseif scenario.trigger == "hidden-duanchang" then
      triggerHiddenDuanchang(room, state)
    elseif scenario.trigger == "hidden-jueqing" then
      triggerHiddenJueqing(room, state)
    elseif scenario.trigger == "hidden-ejue" then
      triggerHiddenEjue(room, state)
    elseif scenario.trigger == "hidden-dufu" then
      triggerHiddenDufu(room, state)
    elseif scenario.trigger == "hidden-jianzhi" then
      triggerHiddenJianzhi(room, state)
    elseif scenario.trigger == "hidden-zhiman" then
      triggerHiddenZhiman(room, state)
    elseif scenario.trigger == "hidden-jilix" then
      -- 寄篱's second-damage predicate is scoped to Player.HistoryPhase.
      -- Wait for a real phase before using the red Slash; running this from
      -- GameStart has no Phase parent and cannot reproduce the source law.
      state.hiddenJilixPending = true
    end
  end,
})

director:addEffect(fk.EventPhaseStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.hiddenFuyinPending and target == state.actor and
      player == state.actor and data.phase == Player.Start
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenFuyinPending = false
    -- Let the real clients finish applying the initial hand/draw-pile move
    -- notifications before the deferred synchronization request is sent.
    player.room:delay(1500)
    -- Hegemony reveals the first player's pair before EventPhaseStart. Re-hide
    -- the catalogued slots here so the actual TargetConfirmed test begins in
    -- the same hidden-general state as a player who kept both generals down.
    if state.actor.general ~= "anjiang" then state.actor:hideGeneral(false) end
    if state.actor.deputyGeneral ~= "anjiang" then state.actor:hideGeneral(true) end
    triggerHiddenFuyin(player.room, state)
  end,
})

director:addEffect(fk.EventPhaseStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.hiddenJilixPending and target == state.actor and
      player == state.actor and data.phase == Player.Start
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenJilixPending = false
    player.room:delay(1500)
    -- Hegemony reveals the first player's pair before EventPhaseStart. Re-hide
    -- both slots so the test reaches the source TargetConfirmed branch with
    -- the same hidden state as a real player who kept both generals down.
    if state.actor.general ~= "anjiang" then state.actor:hideGeneral(false) end
    if state.actor.deputyGeneral ~= "anjiang" then state.actor:hideGeneral(true) end
    triggerHiddenJilix(player.room, state)
  end,
})

director:addEffect(fk.RoundStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and now() - state.startedAt > maxDurationSeconds
  end,
  on_trigger = function(self, event, target, player, data)
    fk.qWarning(string.format("[tqs_qa] timeout scenario=%s seed=%u revision=%s",
      stateFor(player.room).scenario, stateFor(player.room).seed, manifest.sourceRevision))
    player.room:gameOver("")
  end,
})

director:addEffect(fk.GameFinished, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    -- GameFinished is a nil-target event. TriggerEvent:exec supplies the
    -- room's current player, which is not guaranteed to be seat 1 when the
    -- room ends. The old seat-1 guard silently skipped cleanup and the
    -- bounded ai-trace emission for ordinary GameOver paths.
    return player ~= nil and stateFor(player.room) ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local state = stateFor(room)
    emitPrompt4Provenance(room, state)
    emitAiTrace(state)
    emitGeneralPairTrace(state)
    emitGeneralPairMatchResult(state, data)
    activeRooms[tostring(room)] = nil
    room:removeTag("tqs_qa")
  end,
})

-- fk.CreateSkill returns a SkillSkeleton. Register it through the package's
-- skeleton loader so Package:install creates a real Skill before Engine:addSkill
-- receives it. Inserting the skeleton directly into related_skills crashes the
-- native Lua worker at Engine:addSkill's type assertion.
extension:loadSkillSkels({ director })

return extension
