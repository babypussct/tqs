/**
 * Source-level audit for the New Hegemony hidden-general skill surface.
 *
 * The native client receives one fake skill at a time and decides whether the
 * browser/native dashboard needs a prelight control, a regular skill entry, or
 * both.  This audit walks every active general in the pinned runtime in both
 * main and deputy placement, applies the same MainPlace/DeputyPlace filters as
 * HegLogic, and exercises the unmodified client.lua classifier.  It does not
 * claim that every skill effect has been played live; it proves that the
 * hidden-skill projection has no unclassified or dropped activation surface.
 */
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { initialSnapshot, reduceUiEvent } from '../src/store/gameStore';
import { loadUpstreamFiles, packageSpec, UPSTREAM_PACKAGE_NAMES, type UpstreamPackageSpec } from './upstream-packages';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');

type HiddenSkillReport = {
  generatedAt: string;
  packages: UpstreamPackageSpec[];
  activeGenerals: number;
  mainSlots: number;
  deputySlots: number;
  eligibleSkillReferences: number;
  uniqueEligibleSkills: number;
  excludedMainPlace: number;
  excludedDeputyPlace: number;
  compulsoryHiddenSkills: number;
  fakeTriggerSkills: number;
  regularSkills: number;
  dualProjectionSkills: number;
  nativeLossFakeOnlyFallbacks: number;
  silentSkills: number;
  revealHelperCandidates: number;
  revealHelperAddChecks: number;
  revealHelperLossChecks: number;
  revealCanUseChecks: number;
  revealRouteChecks: number;
  revealRouteDeputyFallbacks: number;
  revealRouteBothEligible: number;
  revealRouteExcludedMainConflicts: number;
  revealRouteSameTrueNameConflicts: number;
  prelightSyncChecks: number;
  eventChecks: number;
  lossEventChecks: number;
  reactLifecycleChecks: number;
  reactLifecyclePasses: number;
  reactPrivacyChecks: number;
  reactPrivacyPasses: number;
  reactPrelightChecks: number;
  reactPrelightPasses: number;
  reconnectProjectionChecks: number;
  reconnectProjectionPasses: number;
  reconnectActualStateChecks: number;
  reconnectActualStatePasses: number;
  reconnectActualLossChecks: number;
  reconnectActualLossPasses: number;
  surfaceKinds: Record<string, number>;
  triggerEventCounts: Record<string, number>;
  hardFailures: string[];
  pass: boolean;
};

type NativeUiEvent = [string, unknown];
type NativeSkillContract = { name: string; add: NativeUiEvent[]; loss: NativeUiEvent[] };
type LuaHiddenSkillReport = Omit<HiddenSkillReport,
  'generatedAt' | 'packages' | 'pass' | 'reactLifecycleChecks' | 'reactLifecyclePasses' |
  'reactPrivacyChecks' | 'reactPrivacyPasses' | 'reactPrelightChecks' | 'reactPrelightPasses' |
  'reconnectProjectionChecks' | 'reconnectProjectionPasses' |
  'reconnectActualStateChecks' | 'reconnectActualStatePasses' |
  'reconnectActualLossChecks' | 'reconnectActualLossPasses'> & {
  reactContracts: NativeSkillContract[];
  reconnectProjectionNames: { trigger: string | null; active: string | null; dual: string | null };
  reconnectProjectionContracts: {
    name: string;
    fake: boolean;
    regular: boolean;
    lossFake: boolean;
    lossRegular: boolean;
  }[];
};

const LUA_HIDDEN_SKILL_AUDIT = String.raw`
local result = {
  activeGenerals = 0, mainSlots = 0, deputySlots = 0,
  eligibleSkillReferences = 0, uniqueEligibleSkills = 0,
  excludedMainPlace = 0, excludedDeputyPlace = 0,
  compulsoryHiddenSkills = 0, fakeTriggerSkills = 0, regularSkills = 0,
  dualProjectionSkills = 0, nativeLossFakeOnlyFallbacks = 0, silentSkills = 0,
  revealHelperCandidates = 0, revealHelperAddChecks = 0, revealHelperLossChecks = 0,
  revealCanUseChecks = 0,
  revealRouteChecks = 0, revealRouteDeputyFallbacks = 0,
  revealRouteBothEligible = 0, revealRouteExcludedMainConflicts = 0,
  revealRouteSameTrueNameConflicts = 0,
  prelightSyncChecks = 0,
  eventChecks = 0, lossEventChecks = 0,
  reconnectProjectionNames = { trigger = nil, active = nil, dual = nil },
  reconnectProjectionContracts = {},
  surfaceKinds = {}, triggerEventCounts = {},
  reactContracts = {},
  hardFailures = {},
}

local function fail(message)
  if #result.hardFailures < 100 then result.hardFailures[#result.hardFailures + 1] = tostring(message) end
end

local clientClass = Fk:getBoardGame("new_heg_mode").client_klass
ClientInstance = clientClass:new(__host_client)
ClientInstance.settings = {
  gameMode = "new_heg_mode", disabledPack = {}, disabledGenerals = {},
  _game = {}, _mode = {},
}
ClientInstance.capacity = 2
ClientInstance.timeout = 30
ClientInstance.observing = false
local meNative = __host_client:addPlayer(101, "hidden-skill-audit", "avatar")
Self = ClientInstance.clientplayer_klass:new(meNative)
Self.id = 101
Self.general, Self.deputyGeneral = "anjiang", "anjiang"
Self.hp, Self.maxHp, Self.shield = 3, 4, 0
Self.phase, Self.dead, Self.dying, Self.role_shown = Player.Play, false, false, true
Self.kingdom, Self.seat = "wei", 1
Self.role, Self.room = "lord", ClientInstance
ClientInstance.players = { Self }
ClientInstance.alive_players = { Self }
ClientInstance.current = Self
ClientInstance.logic = { current_trigger_event_id = 0 }

local uiEvents = {}
ClientInstance.notifyUI = function(_, command, data)
  uiEvents[#uiEvents + 1] = { command, data }
end

local function resetPlayer()
  Self.player_skills, Self.derivative_skills = {}, {}
  Self._fake_skills, Self._manually_fake_skills = {}, {}
  Self.prelighted_skills = {}
  Self.skillUsedHistory, Self.skillBranchUsedHistory = {}, {}
  uiEvents = {}
end

local function eventMatches(event, command, name, fake)
  return event and event[1] == command and type(event[2]) == "table" and
    event[2][1] == 101 and event[2][2] == name and (event[2][3] or false) == fake
end

local function prelightEventMatches(event, name)
  return event and event[1] == "PrelightSkill" and type(event[2]) == "table" and
    event[2][1] == name and event[2][2] == true
end

local function expectedProjection(skill)
  local hasTrigger, hasActive = false, false
  local hasAnyTrigger = false
  local all = { table.unpack(skill.related_skills or Util.DummyTable) }
  table.insert(all, skill)
  for _, s in ipairs(all) do
    if s:isInstanceOf(TriggerSkill) then
      hasAnyTrigger = true
      if not s.is_delay_effect then hasTrigger = true end
    end
    if s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then hasActive = true end
  end
  -- client.lua emits a fake entry for a usable trigger, and a regular entry
  -- for an active/view-as companion.  A skill with neither class gets the
  -- native fallback regular entry so the dashboard can identify it.  A
  -- trigger-only skill does not also get a regular entry.
  local regular = hasActive or not hasTrigger
  -- client.lua's LoseSkill branch currently checks any TriggerSkill, including
  -- delay effects. A delay-trigger-only skill therefore loses through the
  -- fake channel even though AddSkill used the regular fallback.
  local lossFake = hasAnyTrigger
  local lossRegular = hasActive or not hasAnyTrigger
  return hasTrigger, regular, hasTrigger and hasActive, lossFake, lossRegular,
    lossFake and not hasTrigger and regular
end

local seen = {}
local countedSurfaces = {}
local countedTriggerEvents = {}

local function recordEffectSurfaces(skillName, skill)
  local effects = { skill }
  for _, related in ipairs(skill.related_skills or Util.DummyTable) do
    table.insert(effects, related)
  end
  for _, effect in ipairs(effects) do
    local className = effect.class and tostring(effect.class.name or "") or "<unknown>"
    local surface = nil
    if className == "TriggerSkill" then
      surface = "trigger"
      local eventName = effect.event and tostring(effect.event.name or "") or "<unknown>"
      local eventKey = skillName .. "|" .. eventName
      if not countedTriggerEvents[eventKey] then
        countedTriggerEvents[eventKey] = true
        result.triggerEventCounts[eventName] = (result.triggerEventCounts[eventName] or 0) + 1
      end
    elseif className == "ActiveSkill" then
      surface = "active"
    elseif className == "ViewAsSkill" then
      surface = "view-as"
    elseif className == "CardSkill" then
      surface = "card-skill"
    elseif className:sub(-5) == "Skill" then
      surface = "status"
    end
    if surface then
      local surfaceKey = skillName .. "|" .. surface
      if not countedSurfaces[surfaceKey] then
        countedSurfaces[surfaceKey] = true
        result.surfaceKinds[surface] = (result.surfaceKinds[surface] or 0) + 1
      end
    end
  end
end

local function auditSkill(generalName, placement, skillName)
  if type(skillName) ~= "string" or skillName == "" then return end
  result.eligibleSkillReferences = result.eligibleSkillReferences + 1
  if seen[skillName] then return end
  seen[skillName] = true
  result.uniqueEligibleSkills = result.uniqueEligibleSkills + 1

  local skill = Fk.skills[skillName]
  if not skill then
    fail(generalName .. "/" .. placement .. ": missing skill " .. skillName)
    return
  end
  recordEffectSurfaces(skillName, skill)
  local expectFake, expectRegular, expectDual, expectLossFake, expectLossRegular, lossFallback = expectedProjection(skill)
  if expectFake then result.fakeTriggerSkills = result.fakeTriggerSkills + 1 end
  if expectRegular then result.regularSkills = result.regularSkills + 1 end
  if expectDual then result.dualProjectionSkills = result.dualProjectionSkills + 1 end
  if lossFallback then result.nativeLossFakeOnlyFallbacks = result.nativeLossFakeOnlyFallbacks + 1 end
  if not skill.visible then
    result.silentSkills = result.silentSkills + 1
    return
  end

  resetPlayer()
  local ok, err = pcall(function() ClientInstance:addSkill({ 101, skillName, true }) end)
  if not ok then
    fail(generalName .. "/" .. placement .. "/" .. skillName .. ": client addFakeSkill failed: " .. tostring(err))
    return
  end
  local fakeEvents, regularEvents = 0, 0
  for _, event in ipairs(uiEvents) do
    if eventMatches(event, "AddSkill", skillName, true) then fakeEvents = fakeEvents + 1 end
    if eventMatches(event, "AddSkill", skillName, false) then regularEvents = regularEvents + 1 end
  end
  local expectedFake = expectFake and 1 or 0
  local expectedRegular = expectRegular and 1 or 0
  result.eventChecks = result.eventChecks + 1
  if fakeEvents ~= expectedFake or regularEvents ~= expectedRegular then
    fail(string.format("%s/%s/%s: expected AddSkill fake=%d regular=%d, got fake=%d regular=%d",
      generalName, placement, skillName, expectedFake, expectedRegular, fakeEvents, regularEvents))
  end
  local addEvents = uiEvents

  if expectFake then
    -- Reconnect uses ClientPlayer:sendDataToUI(), not the live notification
    -- path.  A prelighted fake trigger must be restored through that exact
    -- source callback so React can reconstruct its toggle state.
    local prelightOk, prelightErr = pcall(function()
      ClientInstance:prelightSkill({ skillName, true })
    end)
    if not prelightOk then
      fail(generalName .. "/" .. placement .. "/" .. skillName .. ": prelight setup failed: " .. tostring(prelightErr))
    else
      uiEvents = {}
      local syncOk, syncErr = pcall(function() Self:sendDataToUI() end)
      if not syncOk then
        fail(generalName .. "/" .. placement .. "/" .. skillName .. ": prelight sync failed: " .. tostring(syncErr))
      else
        local synced = 0
        for _, event in ipairs(uiEvents) do
          if prelightEventMatches(event, skillName) then synced = synced + 1 end
        end
        result.prelightSyncChecks = result.prelightSyncChecks + 1
        if synced ~= 1 then
          fail(string.format("%s/%s/%s: expected one synced PrelightSkill, got %d",
            generalName, placement, skillName, synced))
        end
      end
    end
  end

  resetPlayer()
  local addOk, addErr = pcall(function() ClientInstance:addSkill({ 101, skillName, true }) end)
  if not addOk then
    fail(generalName .. "/" .. placement .. "/" .. skillName .. ": client addFakeSkill before loss failed: " .. tostring(addErr))
    return
  end
  uiEvents = {}
  local loseOk, loseErr = pcall(function() ClientInstance:loseSkill({ 101, skillName, true }) end)
  if not loseOk then
    fail(generalName .. "/" .. placement .. "/" .. skillName .. ": client loseFakeSkill failed: " .. tostring(loseErr))
    return
  end
  local lossFakeEvents, lossRegularEvents = 0, 0
  for _, event in ipairs(uiEvents) do
    if eventMatches(event, "LoseSkill", skillName, true) then lossFakeEvents = lossFakeEvents + 1 end
    if eventMatches(event, "LoseSkill", skillName, false) then lossRegularEvents = lossRegularEvents + 1 end
  end
  result.lossEventChecks = result.lossEventChecks + 1
  local expectedLossFake = expectLossFake and 1 or 0
  local expectedLossRegular = expectLossRegular and 1 or 0
  if lossFakeEvents ~= expectedLossFake or lossRegularEvents ~= expectedLossRegular then
    local eventSummary = {}
    for _, event in ipairs(uiEvents) do
      table.insert(eventSummary, tostring(event[1]) .. ":" ..
        (type(event[2]) == "table" and tostring(event[2][2]) or tostring(event[2])))
    end
    fail(string.format("%s/%s/%s: expected LoseSkill fake=%d regular=%d, got fake=%d regular=%d",
      generalName, placement, skillName, expectedLossFake, expectedLossRegular,
      lossFakeEvents, lossRegularEvents) .. " events=" .. table.concat(eventSummary, ","))
  end
  table.insert(result.reactContracts, { name = skillName, add = addEvents, loss = uiEvents })
end

-- revealBySkillName() is intentionally checked against the complete source
-- skill list, while HegLogic:attachSkillToPlayers() filters MainPlace and
-- DeputyPlace at attachment time.  Audit every distinct main/deputy general
-- pair so a deputy-only skill cannot be routed to a hidden main general that
-- merely mentions the same skill name in its unfiltered list.  This is a
-- source-route contract check; it does not claim to execute ServerPlayer in
-- the client VM.
local generalMeta = {}
local revealHelperReactContractAdded = false

local function auditRevealHelper(generalName)
  result.revealHelperCandidates = result.revealHelperCandidates + 1
  local helper = Fk.skills["reveal_skill&"]
  if not helper then
    fail(generalName .. ": missing native reveal_skill& helper")
    return
  end

  -- new_hegemony_mode.lua adds this as a fake skill when either hidden slot
  -- has a compulsory skill.  client.lua must project it as a regular active
  -- entry, never as a prelight trigger: the player actively chooses which
  -- slot to reveal from its interaction.
  resetPlayer()
  local addOk, addErr = pcall(function() ClientInstance:addSkill({ 101, "reveal_skill&", true }) end)
  if not addOk then
    fail(generalName .. ": reveal_skill& AddSkill failed: " .. tostring(addErr))
    return
  end
  local addFake, addRegular = 0, 0
  for _, event in ipairs(uiEvents) do
    if eventMatches(event, "AddSkill", "reveal_skill&", true) then addFake = addFake + 1 end
    if eventMatches(event, "AddSkill", "reveal_skill&", false) then addRegular = addRegular + 1 end
  end
  result.revealHelperAddChecks = result.revealHelperAddChecks + 1
  if addFake ~= 0 or addRegular ~= 1 then
    fail(string.format("%s: reveal_skill& AddSkill expected fake=0 regular=1, got fake=%d regular=%d",
      generalName, addFake, addRegular))
  end
  local addEvents = uiEvents

  uiEvents = {}
  local loseOk, loseErr = pcall(function() ClientInstance:loseSkill({ 101, "reveal_skill&", true }) end)
  if not loseOk then
    fail(generalName .. ": reveal_skill& LoseSkill failed: " .. tostring(loseErr))
    return
  end
  local lossFake, lossRegular = 0, 0
  for _, event in ipairs(uiEvents) do
    if eventMatches(event, "LoseSkill", "reveal_skill&", true) then lossFake = lossFake + 1 end
    if eventMatches(event, "LoseSkill", "reveal_skill&", false) then lossRegular = lossRegular + 1 end
  end
  result.revealHelperLossChecks = result.revealHelperLossChecks + 1
  if lossFake ~= 0 or lossRegular ~= 1 then
    fail(string.format("%s: reveal_skill& LoseSkill expected fake=0 regular=1, got fake=%d regular=%d",
      generalName, lossFake, lossRegular))
  end
  if not revealHelperReactContractAdded then
    table.insert(result.reactContracts, { name = "reveal_skill&", add = addEvents, loss = uiEvents })
    revealHelperReactContractAdded = true
  end
end

local function auditRevealCanUse(generalName, placement, skillName)
  result.revealCanUseChecks = result.revealCanUseChecks + 1
  local helper = Fk.skills["reveal_skill&"]
  local skill = Fk.skills[skillName]
  if not helper or not skill then
    fail(string.format("%s/%s: missing reveal helper or compulsory skill %s", generalName, placement, tostring(skillName)))
    return
  end

  resetPlayer()
  -- Keep the non-target slot revealed so canUse reaches the slot under test
  -- without looking up a missing hidden-general mark first.
  Self.general = placement == "main" and "anjiang" or "hs__guojia"
  Self.deputyGeneral = placement == "deputy" and "anjiang" or "hs__guojia"
  Self.mark["__heg_general"] = placement == "main" and generalName or nil
  Self.mark["__heg_deputy"] = placement == "deputy" and generalName or nil
  local addOk, addErr = pcall(function() ClientInstance:addSkill({ 101, skillName, true }) end)
  if not addOk then
    fail(string.format("%s/%s/%s: compulsory fake skill setup failed: %s",
      generalName, placement, skillName, tostring(addErr)))
    return
  end
  local canOk, can, canErr = pcall(function() return helper:canUse(Self) end)
  if not canOk or can ~= true then
    fail(string.format("%s/%s/%s: reveal_skill& canUse expected true, got %s (%s)",
      generalName, placement, skillName, tostring(can), tostring(canErr)))
  end
end

local disabledPackages = Fk.game_mode_disabled["new_heg_mode"] or Util.DummyTable
for generalName, general in pairs(Fk.generals) do
  local package = general.package
  if package and not table.contains(disabledPackages, package.name) and
      not general.hidden and not general.total_hidden then
    result.activeGenerals = result.activeGenerals + 1
    local names = general:getSkillNameList(true)
    local rawSkills, mainEligible, deputyEligible = {}, {}, {}
    for _, skillName in ipairs(names) do
      rawSkills[skillName] = true
      local skill = Fk.skills[skillName]
      if skill and not skill:hasTag(Skill.DeputyPlace) then mainEligible[skillName] = true end
      if skill and not skill:hasTag(Skill.MainPlace) then deputyEligible[skillName] = true end
    end
    generalMeta[generalName] = {
      raw = rawSkills, main = mainEligible, deputy = deputyEligible,
      trueName = general.trueName,
    }
    result.mainSlots = result.mainSlots + 1
    result.deputySlots = result.deputySlots + 1
    local mainSeen, deputySeen = {}, {}
    local hasCompulsory = false
    local mainCompulsorySkill, deputyCompulsorySkill = nil, nil
    for _, skillName in ipairs(names) do
      local skill = Fk.skills[skillName]
      if skill and skill:hasTag(Skill.DeputyPlace) then
        result.excludedMainPlace = result.excludedMainPlace + 1
      elseif not mainSeen[skillName] then
        mainSeen[skillName] = true
        if skill and skill:hasTag(Skill.Compulsory) then
          result.compulsoryHiddenSkills = result.compulsoryHiddenSkills + 1
          hasCompulsory = true
          mainCompulsorySkill = mainCompulsorySkill or skillName
        end
        auditSkill(generalName, "main", skillName)
      end
      if skill and skill:hasTag(Skill.MainPlace) then
        result.excludedDeputyPlace = result.excludedDeputyPlace + 1
      elseif not deputySeen[skillName] then
        deputySeen[skillName] = true
        if skill and skill:hasTag(Skill.Compulsory) then
          result.compulsoryHiddenSkills = result.compulsoryHiddenSkills + 1
          hasCompulsory = true
          deputyCompulsorySkill = deputyCompulsorySkill or skillName
        end
        auditSkill(generalName, "deputy", skillName)
      end
    end
    if hasCompulsory then auditRevealHelper(generalName) end
    if mainCompulsorySkill then auditRevealCanUse(generalName, "main", mainCompulsorySkill) end
    if deputyCompulsorySkill then auditRevealCanUse(generalName, "deputy", deputyCompulsorySkill) end
  end
end

for mainName, main in pairs(generalMeta) do
  for deputyName, deputy in pairs(generalMeta) do
    if mainName ~= deputyName then
      for skillName in pairs(deputy.deputy) do
        if main.trueName == deputy.trueName then
          -- Room:makeGeneralPile() removes same-trueName alternatives when
          -- disableSameConvert is false, which is the pinned New Hegemony
          -- default. Keep the source anomaly visible, but do not count an
          -- impossible initial pair as a legal route failure.
          if main.raw[skillName] and not main.main[skillName] then
            result.revealRouteSameTrueNameConflicts = result.revealRouteSameTrueNameConflicts + 1
          end
        else
          result.revealRouteChecks = result.revealRouteChecks + 1
          if main.raw[skillName] then
            if main.main[skillName] then
              -- Both legal slots carry the same skill name. The native source
              -- checks the hidden main slot first; record that precedence
              -- rather than treating it as a React projection failure.
              result.revealRouteBothEligible = result.revealRouteBothEligible + 1
            else
              -- The deputy owns the usable projection, but native
              -- revealBySkillName() would see the raw main-list name first.
              result.revealRouteExcludedMainConflicts = result.revealRouteExcludedMainConflicts + 1
              fail(string.format("%s/%s/%s: deputy-eligible skill is present only as an excluded raw main entry",
                mainName, deputyName, skillName))
            end
          else
            result.revealRouteDeputyFallbacks = result.revealRouteDeputyFallbacks + 1
          end
        end
      end
    end
  end
end

-- Reconnect does not pass through Client:addSkill().  The native
-- ClientPlayer:sendDataToUI() path emits every manually attached fake skill
-- with the third field set to true, and the browser host must normalize that
-- snapshot to the same trigger/active/dual projection as the live callback.
local function projectionFlags(skill)
  local all = { table.unpack(skill.related_skills or Util.DummyTable) }
  table.insert(all, skill)
  local has_trigger, has_usable_trigger, has_active = false, false, false
  for _, related in ipairs(all) do
    if related:isInstanceOf(TriggerSkill) then
      has_trigger = true
      if not related.is_delay_effect then has_usable_trigger = true end
    end
    if related:isInstanceOf(ActiveSkill) or related:isInstanceOf(ViewAsSkill) then
      has_active = true
    end
  end
  return has_trigger, has_usable_trigger, has_active
end

for name, skill in pairs(Fk.skills) do
  if type(name) == "string" and skill.visible then
    local has_trigger, has_usable_trigger, has_active = projectionFlags(skill)
    if has_usable_trigger and not has_active and not result.reconnectProjectionNames.trigger then
      result.reconnectProjectionNames.trigger = name
    elseif has_active and not has_trigger and not result.reconnectProjectionNames.active then
      result.reconnectProjectionNames.active = name
    elseif has_usable_trigger and has_active and not result.reconnectProjectionNames.dual then
      result.reconnectProjectionNames.dual = name
    end
  end
end

-- The representative names above make failures readable, but the reconnect
-- boundary must be checked for every eligible hidden skill ID.  The native
-- snapshot sends all of them as fake=true; hostLua must reproduce client.lua's
-- exact AddSkill projection for each one, including delay-only fallbacks.
for name in pairs(seen) do
  local skill = Fk.skills[name]
  if skill and skill.visible then
    local has_trigger, has_usable_trigger, has_active = projectionFlags(skill)
    table.insert(result.reconnectProjectionContracts, {
      name = name,
      fake = has_usable_trigger,
      regular = has_active or not has_usable_trigger,
      -- client.lua's loss branch deliberately checks any TriggerSkill,
      -- including delay effects, while its add branch suppresses delay-only
      -- fake entries. Keep the two native projections separate here.
      lossFake = has_trigger,
      lossRegular = has_active or not has_trigger,
    })
  end
end
table.sort(result.reconnectProjectionContracts, function(a, b) return a.name < b.name end)

if result.reconnectProjectionNames.trigger and result.reconnectProjectionNames.active then
  -- Return the events through the real host FClient.notifyUI boundary.  The
  -- JavaScript side records only AddSkill events from this final probe and
  -- checks their exact fake/regular payloads.
  ClientInstance.notifyUI = function(_, command, data)
    __host_client:notifyUI(command, data)
  end
  __host_client:notifyUI("EnterRoom", {})
  Self.player_skills, Self._fake_skills, Self._manually_fake_skills = {}, {}, {}
  Self.prelighted_skills = {}
  for _, contract in ipairs(result.reconnectProjectionContracts) do
    local skill = Fk.skills[contract.name]
    table.insert(Self._fake_skills, skill)
    table.insert(Self._manually_fake_skills, skill)
  end
  Self:sendDataToUI()
end

return result
`;

function ensureUpstream(): void {
  for (const spec of UPSTREAM_PACKAGE_NAMES.map(packageSpec)) {
    assert.ok(existsSync(path.join(UPSTREAM_ROOT, spec.sourceDirectory)), `Missing pinned upstream checkout: ${spec.sourceDirectory}`);
  }
}

function skillEvents(events: NativeUiEvent[], command: 'AddSkill' | 'LoseSkill'): NativeUiEvent[] {
  return events.filter(([name, data]) => name === command && Array.isArray(data));
}

function skillEventData(event: NativeUiEvent): unknown[] {
  return event[1] as unknown[];
}

function freshReactSkillState() {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 101);
  return reduceUiEvent(state, 'StartGame', null);
}

function auditReactLifecycle(contracts: NativeSkillContract[]) {
  let reactLifecycleChecks = 0;
  let reactLifecyclePasses = 0;
  let reactPrivacyChecks = 0;
  let reactPrivacyPasses = 0;
  let reactPrelightChecks = 0;
  let reactPrelightPasses = 0;
  const failures: string[] = [];
  const fail = (message: string) => {
    if (failures.length < 100) failures.push(message);
  };

  for (const contract of contracts) {
    reactLifecycleChecks++;
    let lifecycleFailed = false;
    let state = freshReactSkillState();
    const additions = skillEvents(contract.add, 'AddSkill');
    const losses = skillEvents(contract.loss, 'LoseSkill');
    const addFake = additions.some(([, data]) => Array.isArray(data) && data[2] === true);
    const addRegular = additions.some(([, data]) => Array.isArray(data) && data[2] !== true);
    for (const event of additions) state = reduceUiEvent(state, event[0], skillEventData(event));

    const hasFake = state.fakeSkills.some((skill) => skill.name === contract.name);
    const hasRegular = state.regularSkills.some((skill) => skill.name === contract.name);
    if (hasFake !== addFake || hasRegular !== addRegular) {
      lifecycleFailed = true;
      fail(`${contract.name}: React AddSkill replay expected fake=${addFake} regular=${addRegular}, got fake=${hasFake} regular=${hasRegular}`);
    }

    if (addFake) {
      reactPrelightChecks++;
      let prelightFailed = false;
      state = reduceUiEvent(state, 'PrelightSkill', [contract.name, true]);
      if (state.fakeSkills.find((skill) => skill.name === contract.name)?.prelighted !== true) {
        prelightFailed = true;
        fail(`${contract.name}: React prelight=true replay did not mark the fake skill`);
      }
      state = reduceUiEvent(state, 'PrelightSkill', [contract.name, false]);
      if (state.fakeSkills.find((skill) => skill.name === contract.name)?.prelighted !== false) {
        prelightFailed = true;
        fail(`${contract.name}: React prelight=false replay did not clear the fake skill`);
      }
      state = reduceUiEvent(state, 'PrelightSkill', [contract.name, true]);
      if (state.fakeSkills.find((skill) => skill.name === contract.name)?.prelighted !== true) {
        prelightFailed = true;
        fail(`${contract.name}: React prelight=true replay could not be restored`);
      }
      if (!prelightFailed) reactPrelightPasses++;
    }

    for (const event of losses) state = reduceUiEvent(state, event[0], skillEventData(event));
    if (state.fakeSkills.some((skill) => skill.name === contract.name) ||
        state.regularSkills.some((skill) => skill.name === contract.name)) {
      lifecycleFailed = true;
      fail(`${contract.name}: React LoseSkill replay left a stale projection`);
    }
    if (!lifecycleFailed) reactLifecyclePasses++;

    reactPrivacyChecks += 2;
    let privacyFailed = false;
    let privateAddState = freshReactSkillState();
    for (const event of additions) {
      const data = skillEventData(event);
      privateAddState = reduceUiEvent(privateAddState, event[0], [202, ...data.slice(1)]);
    }
    if (privateAddState.fakeSkills.length || privateAddState.regularSkills.length) {
      privacyFailed = true;
      fail(`${contract.name}: React accepted another seat's AddSkill event`);
    }

    let privateLossState = freshReactSkillState();
    for (const event of additions) privateLossState = reduceUiEvent(privateLossState, event[0], skillEventData(event));
    for (const event of losses) {
      const data = skillEventData(event);
      privateLossState = reduceUiEvent(privateLossState, event[0], [202, ...data.slice(1)]);
    }
    if (!privateLossState.fakeSkills.some((skill) => skill.name === contract.name) &&
        !privateLossState.regularSkills.some((skill) => skill.name === contract.name)) {
      privacyFailed = true;
      fail(`${contract.name}: React accepted another seat's LoseSkill event`);
    }
    if (!privacyFailed) reactPrivacyPasses += 2;
  }

  return { reactLifecycleChecks, reactLifecyclePasses, reactPrivacyChecks, reactPrivacyPasses,
    reactPrelightChecks, reactPrelightPasses, failures };
}

function printReport(report: HiddenSkillReport): void {
  console.log(`Hidden skill audit: ${report.activeGenerals} active generals; ` +
    `${report.mainSlots} main slots / ${report.deputySlots} deputy slots`);
  console.log(`Eligible skill references: ${report.eligibleSkillReferences}; unique: ${report.uniqueEligibleSkills}`);
  console.log(`Projection: fake-trigger=${report.fakeTriggerSkills}, regular=${report.regularSkills}, ` +
    `dual=${report.dualProjectionSkills}, silent=${report.silentSkills}, ` +
    `native-loss-fake-only-fallback=${report.nativeLossFakeOnlyFallbacks}`);
  console.log(`Placement filter: exclude main=${report.excludedMainPlace}, deputy=${report.excludedDeputyPlace}; ` +
    `compulsory skill references=${report.compulsoryHiddenSkills}`);
  console.log(`Native reveal_skill& helper: ${report.revealHelperCandidates} candidates; ` +
    `AddSkill ${report.revealHelperAddChecks}/${report.revealHelperCandidates}; ` +
    `LoseSkill ${report.revealHelperLossChecks}/${report.revealHelperCandidates}`);
  console.log(`Native reveal_skill& canUse checks: ${report.revealCanUseChecks}`);
  console.log(`Native revealBySkillName slot-route checks: ${report.revealRouteChecks}; ` +
    `deputy fallback=${report.revealRouteDeputyFallbacks}, both eligible/main precedence=${report.revealRouteBothEligible}, ` +
    `excluded-main conflicts=${report.revealRouteExcludedMainConflicts}, ` +
    `same-trueName conflicts excluded by native roster rule=${report.revealRouteSameTrueNameConflicts}`);
  console.log(`Native prelight reconnect sync checks: ${report.prelightSyncChecks}`);
  console.log(`Native AddSkill checks: ${report.eventChecks}; LoseSkill checks: ${report.lossEventChecks}`);
  console.log(`Effect surfaces across eligible skill IDs: ${Object.entries(report.surfaceKinds)
    .sort(([a], [b]) => a.localeCompare(b)).map(([name, count]) => `${name}=${count}`).join(', ')}`);
  console.log(`Trigger event inventory (${Object.keys(report.triggerEventCounts).length} event kinds): ${Object.entries(report.triggerEventCounts)
    .sort(([a], [b]) => a.localeCompare(b)).map(([name, count]) => `${name}=${count}`).join(', ')}`);
  console.log(`React replay of native Add/Lose lifecycle: ${report.reactLifecyclePasses}/${report.reactLifecycleChecks}; ` +
    `privacy ${report.reactPrivacyPasses}/${report.reactPrivacyChecks}; ` +
    `prelight ${report.reactPrelightPasses}/${report.reactPrelightChecks}`);
  console.log(`Reconnect snapshot projection through host boundary: ${report.reconnectProjectionPasses}/${report.reconnectProjectionChecks}`);
  console.log(`Reconnect snapshot from actual Client:addSkill state: ${report.reconnectActualStatePasses}/${report.reconnectActualStateChecks}; ` +
    `actual Client:loseSkill lifecycle: ${report.reconnectActualLossPasses}/${report.reconnectActualLossChecks}`);
  if (report.hardFailures.length) console.log(`FAIL hidden-skill samples: ${report.hardFailures.join(' | ')}`);
  console.log(report.pass
    ? 'PASS hidden-general projection: source placement and native fake/regular classification are covered'
    : 'FAIL hidden-general projection: source placement or native fake/regular classification diverged');
}

async function main(): Promise<HiddenSkillReport> {
  ensureUpstream();
  const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES);
  const reconnectUiEvents: NativeUiEvent[] = [];
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {}, setup: () => {}, ui: (command, data) => reconnectUiEvents.push([command, data]),
    log: (level, message) => { if (level === 'error') throw new Error(message); },
  }});
  try {
    await runtime.start();
    const luaReport = await runtime.eval<LuaHiddenSkillReport>(LUA_HIDDEN_SKILL_AUDIT);
    const { reactContracts, reconnectProjectionContracts, ...sourceReport } = luaReport;
    const reactReport = auditReactLifecycle(reactContracts);
    let reconnectProjectionPasses = 0;
    let reconnectActualStateChecks = 0;
    let reconnectActualStatePasses = 0;
    let reconnectActualLossChecks = 0;
    let reconnectActualLossPasses = 0;
    const reconnectFailures: string[] = [];
    const expectedNames = new Set(reconnectProjectionContracts.map((contract) => contract.name));
    const reconnectActual = new Map<string, { fake: number; regular: number }>();
    for (const [command, data] of reconnectUiEvents) {
      if (command !== 'AddSkill' || !Array.isArray(data) || data[0] !== 101 || typeof data[1] !== 'string') continue;
      const name = data[1];
      if (!expectedNames.has(name)) {
        reconnectFailures.push(`unexpected reconnect AddSkill projection for ${name}`);
        continue;
      }
      const current = reconnectActual.get(name) ?? { fake: 0, regular: 0 };
      if (data[2] === true) current.fake++;
      else current.regular++;
      reconnectActual.set(name, current);
    }
    for (const contract of reconnectProjectionContracts) {
      const actual = reconnectActual.get(contract.name) ?? { fake: 0, regular: 0 };
      const fake = reconnectUiEvents.filter(([command, data]) => command === 'AddSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] === true).length;
      const regular = reconnectUiEvents.filter(([command, data]) => command === 'AddSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] !== true).length;
      const expectedFake = contract.fake ? 1 : 0;
      const expectedRegular = contract.regular ? 1 : 0;
      if (actual.fake !== expectedFake || actual.regular !== expectedRegular ||
          fake !== expectedFake || regular !== expectedRegular) {
        reconnectFailures.push(`${contract.name}: reconnect AddSkill expected fake=${expectedFake} regular=${expectedRegular}, got fake=${actual.fake} regular=${actual.regular}`);
      } else {
        reconnectProjectionPasses++;
      }
    }
    if (!sourceReport.reconnectProjectionNames.trigger || !sourceReport.reconnectProjectionNames.active) {
      reconnectFailures.push('runtime did not expose pure trigger and pure active projection samples');
    }

    // The broad projection probe above uses a clean serialized snapshot so it
    // can cover every hidden skill ID deterministically. This second probe is
    // deliberately different: build each state through the real
    // client.lua AddSkill(fake) path, invoke the native
    // ClientPlayer:sendDataToUI() callback, then complete the matching
    // LoseSkill(fake) lifecycle. Running this for the whole set catches a
    // duplicate regular snapshot or stale loss marker that a three-sample
    // smoke test could miss.
    for (const contract of reconnectProjectionContracts) {
      reconnectActualStateChecks++;
      reconnectUiEvents.length = 0;
      runtime.eval(`
        Self.player_skills, Self.derivative_skills = {}, {}
        Self._fake_skills, Self._manually_fake_skills = {}, {}
        Self.prelighted_skills = {}
        ClientInstance:addSkill({101, ${JSON.stringify(contract.name)}, true})
      `);
      reconnectUiEvents.length = 0;
      runtime.eval('Self:sendDataToUI(); return true');
      const fake = reconnectUiEvents.filter(([command, data]) => command === 'AddSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] === true).length;
      const regular = reconnectUiEvents.filter(([command, data]) => command === 'AddSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] !== true).length;
      const expectedFake = contract.fake ? 1 : 0;
      const expectedRegular = contract.regular ? 1 : 0;
      if (fake !== expectedFake || regular !== expectedRegular) {
        reconnectFailures.push(`${contract.name}: actual Client:addSkill reconnect expected fake=${expectedFake} regular=${expectedRegular}, got fake=${fake} regular=${regular}`);
      } else {
        reconnectActualStatePasses++;
      }

      // Complete the same real client lifecycle instead of stopping at the
      // reconnect snapshot. Native loseSkill(fake) must remove the hidden
      // dashboard projection without leaving a stale regular/fake entry.
      reconnectActualLossChecks++;
      reconnectUiEvents.length = 0;
      runtime.eval(`ClientInstance:loseSkill({101, ${JSON.stringify(contract.name)}, true})`);
      const lossFake = reconnectUiEvents.filter(([command, data]) => command === 'LoseSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] === true).length;
      const lossRegular = reconnectUiEvents.filter(([command, data]) => command === 'LoseSkill' && Array.isArray(data) &&
        data[0] === 101 && data[1] === contract.name && data[2] !== true).length;
      const expectedLossFake = contract.lossFake ? 1 : 0;
      const expectedLossRegular = contract.lossRegular ? 1 : 0;
      if (lossFake !== expectedLossFake || lossRegular !== expectedLossRegular) {
        reconnectFailures.push(`${contract.name}: actual Client:loseSkill lifecycle expected fake=${expectedLossFake} regular=${expectedLossRegular}, got fake=${lossFake} regular=${lossRegular}`);
      } else {
        reconnectActualLossPasses++;
      }
    }
    const hardFailures = [...sourceReport.hardFailures, ...reactReport.failures, ...reconnectFailures].slice(0, 100);
    return {
      ...sourceReport,
      reactLifecycleChecks: reactReport.reactLifecycleChecks,
      reactLifecyclePasses: reactReport.reactLifecyclePasses,
      reactPrivacyChecks: reactReport.reactPrivacyChecks,
      reactPrivacyPasses: reactReport.reactPrivacyPasses,
      reactPrelightChecks: reactReport.reactPrelightChecks,
      reactPrelightPasses: reactReport.reactPrelightPasses,
      reconnectProjectionChecks: reconnectProjectionContracts.length,
      reconnectProjectionPasses,
      reconnectActualStateChecks,
      reconnectActualStatePasses,
      reconnectActualLossChecks,
      reconnectActualLossPasses,
      hardFailures,
      generatedAt: new Date().toISOString(),
      packages: UPSTREAM_PACKAGE_NAMES.map(packageSpec),
      pass: hardFailures.length === 0,
    };
  } finally {
    runtime.close();
  }
}

const report = await main();
if (process.argv.includes('--json')) console.log(JSON.stringify(report, null, 2));
else printReport(report);
if (!report.pass && !process.argv.includes('--report-only')) process.exitCode = 1;
