-- SPDX-License-Identifier: GPL-3.0-or-later
-- Server-only deterministic scenario director for TQS QA.

local config = ServerConfig and ServerConfig.tqsQa
if not config or config.enabled ~= true then
  return nil
end

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

local manifest = readJson("packages/tqs_qa/package.manifest.json")
if manifest.schemaVersion ~= 1 or manifest.package ~= "tqs_qa" or
    manifest.status ~= "verified" or type(manifest.sourceRevision) ~= "string" or
    manifest.sourceRevision == "" or manifest.sourceRevision == "UNRELEASED" or
    type(manifest.catalogSha256) ~= "string" or manifest.catalogSha256 == "" or
    type(manifest.packageSha256) ~= "string" or manifest.packageSha256 == "" then
  fail("refusing to load an unverified package manifest")
end

local catalog = readJson("packages/tqs_qa/catalog.json")
if catalog.schemaVersion ~= 1 or catalog.package ~= "tqs_qa" or
    type(catalog.scenarios) ~= "table" or #catalog.scenarios == 0 then
  fail("invalid scenario catalog")
end

local scenarioById = {}
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
  elseif scenario.trigger == "hidden-jianxiong" then
    validateHiddenJianxiongScenario(scenario)
  elseif scenario.trigger == "hidden-reveal" then
    validateHiddenRevealScenario(scenario)
  elseif scenario.trigger == "hidden-active" then
    validateHiddenActiveScenario(scenario)
  elseif scenario.trigger == "hidden-view-as" then
    validateHiddenViewAsScenario(scenario)
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
  if not seed or seed ~= scenario.seed then
    fail("seed does not match catalog for scenario " .. id)
  end
  return scenario, seed
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

local function setupCards(room, state, scenario)
  local reserved = {}
  state.fixedHands = {}
  state.slotCards = {}
  for _, spec in ipairs(scenario.cards) do
    local owner = playerForRole(state, spec.owner)
    local id = takeCard(room, spec.match, reserved)
    state.slotCards[spec.key] = id
    if spec.area == "equip" then
      room:moveCardTo(id, Card.PlayerEquip, owner, fk.ReasonJustMove, "tqs_qa", nil, true, owner)
    elseif spec.area == "hand" then
      state.fixedHands[owner.id] = state.fixedHands[owner.id] or {}
      table.insert(state.fixedHands[owner.id], id)
    else
      fail("unsupported catalog card area: " .. tostring(spec.area))
    end
  end
end

local function setupState(room, scenario, seed)
  assertRoomAllowed(room, scenario)
  local actor = table.find(room.players, function(player)
    return player.id > 0 and player._splayer:getScreenName() == allowedUsers[1]
  end) or table.find(room.players, function(player) return player.id > 0 end) or room.players[1]
  local target = table.find(room.players, function(player) return player.id ~= actor.id end) or room.players[2]
  local state = {
    scenario = scenario.id,
    seed = seed,
    revision = manifest.sourceRevision,
    startedAt = now(),
    actor = actor,
    target = target,
    skillEffects = {},
    damageResults = {},
    cardEvents = {},
    skillMoves = {},
    damageEvents = {},
  }
  if scenario.players then
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
  fk.qInfo(string.format("[tqs_qa] scenario=%s seed=%u revision=%s players=%d",
    state.scenario, state.seed, state.revision, #room.players))
  return state
end

local function stateFor(room)
  return room:getTag("tqs_qa")
end

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
  local yijiIsDeputy = state.scenario == "hidden-yiji-deputy"
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
    state.hiddenYijiBranch = "positive-prelight-invoke"
  else
    if revealed or moved ~= 0 then
      fail("skipped hidden Yiji must remain hidden and move no cards")
    end
    state.hiddenYijiBranch = "skip-prelight"
  end

  room:sendLog{
    type = "[TQS QA] Hidden Di Kế: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; chuyển bài=%arg5",
    from = state.actor.id,
    arg = state.hiddenYijiBranch,
    arg2 = tostring(prelighted),
    arg3 = tostring(invoked),
    arg4 = tostring(revealed),
    arg5 = tostring(moved),
    arg6 = yijiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-yiji branch=%s slot=%s prelight=%s invoked=%s revealed=%s moved=%d revision=%s",
    state.hiddenYijiBranch, yijiIsDeputy and "deputy" or "main", tostring(prelighted), tostring(invoked), tostring(revealed), moved,
    manifest.sourceRevision))
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

local director = fk.CreateSkill {
  name = "tqs_qa_director&",
}

director:addEffect(fk.SkillEffect, {
  global = true,
  priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "fazheng-enyuan" or state.scenario == "hidden-yiji" or
      state.scenario == "hidden-yiji-deputy" or state.scenario == "hidden-jianxiong" or
      state.scenario == "hidden-jianxiong-deputy" or state.scenario == "hidden-reveal" or
      state.scenario == "hidden-reveal-deputy" or state.scenario == "hidden-active" or
      state.scenario == "hidden-active-main" or state.scenario == "hidden-view-as" or
      state.scenario == "hidden-view-as-main") and
      data and data.skill
  end,
  on_trigger = function(self, event, target, player, data)
    recordSkillEffect(stateFor(player.room), player, data)
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
    elseif scenario.trigger == "hidden-jianxiong" then
      triggerHiddenJianxiong(room, state)
    elseif scenario.trigger == "hidden-reveal" then
      triggerHiddenReveal(room, state)
    elseif scenario.trigger == "hidden-active" then
      triggerHiddenActive(room, state)
    elseif scenario.trigger == "hidden-view-as" then
      triggerHiddenViewAs(room, state)
    end
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
    return stateFor(player.room) ~= nil and player == player.room.players[1]
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
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
