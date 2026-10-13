/**
 * Activation-surface audit for every skill referenced by every pinned general.
 *
 * This is deliberately stronger than skill-audit.ts' no-side-effect contract
 * check: it creates the same client-room/request-handler objects used by the
 * browser, gives them two deterministic players and a real card hand, then
 * walks the activation predicates for every ActiveSkill, ViewAsSkill,
 * CardSkill, TriggerSkill and status-skill effect.  It never calls a server
 * effect that would mutate a real game or send a network reply.  Effect-level
 * semantic rules still require a native server fixture (or an upstream
 * skeleton test); the report keeps that boundary explicit.
 */
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles, packageSpec, UPSTREAM_PACKAGE_NAMES, type UpstreamPackageSpec } from './upstream-packages';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');

type ProbeBucket = {
  attempted: number;
  passed: number;
  contextRequired: number;
  failed: number;
};

type ActivationReport = {
  generatedAt: string;
  packages: UpstreamPackageSpec[];
  generals: number;
  visibleGenerals: number;
  activeGenerals: number;
  generalSkillReferences: number;
  visibleGeneralSkillReferences: number;
  uniqueGeneralSkills: number;
  missingGeneralSkills: string[];
  activeMissingGeneralSkills: string[];
  classCounts: Record<string, number>;
  surfaces: Record<string, ProbeBucket>;
  upstreamSkeletonTests: number;
  skillsWithSkeletonTests: number;
  uiActivation: ProbeBucket;
  hardFailures: string[];
  contextRequiredSamples: string[];
  pass: boolean;
};

const LUA_ACTIVATION_AUDIT = String.raw`
local result = {
  generals = 0, visibleGenerals = 0, activeGenerals = 0,
  generalSkillReferences = 0, visibleGeneralSkillReferences = 0,
  uniqueGeneralSkills = 0, missingGeneralSkills = {}, activeMissingGeneralSkills = {}, classCounts = {},
  surfaces = {}, upstreamSkeletonTests = 0, skillsWithSkeletonTests = 0,
  uiActivation = { attempted = 0, passed = 0, contextRequired = 0, failed = 0 },
  hardFailures = {}, contextRequiredSamples = {},
}

local function sample(list, value)
  if #list < 64 then list[#list + 1] = tostring(value) end
end

local function bucket(name)
  local b = result.surfaces[name]
  if not b then
    b = { attempted = 0, passed = 0, contextRequired = 0, failed = 0 }
    result.surfaces[name] = b
  end
  return b
end

local function classifyError(b, label, err, context)
  b.failed = b.failed + 1
  sample(result.hardFailures, label .. " :: " .. tostring(err))
end

local function probe(name, label, fn, valid, context)
  local b = bucket(name)
  b.attempted = b.attempted + 1
  local ok, value = pcall(fn)
  if not ok then
    if context then
      b.contextRequired = b.contextRequired + 1
      sample(result.contextRequiredSamples, label .. " :: " .. tostring(value))
    else
      classifyError(b, label, value, context)
    end
    return nil, false
  end
  if valid and not valid(value) then
    if context then
      b.contextRequired = b.contextRequired + 1
      sample(result.contextRequiredSamples, label .. " :: invalid return type " .. type(value))
    else
      classifyError(b, label, "invalid return type " .. type(value), context)
    end
    return value, false
  end
  b.passed = b.passed + 1
  return value, true
end

local function finite(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
local function booleanOrNil(value)
  return value == nil or type(value) == "boolean"
end
-- Lua predicates may intentionally return any truthy value through and/or.
-- Keep those results valid while still rejecting callable/coroutine values.
local function predicateReturn(value)
  local t = type(value)
  return value == nil or t == "boolean" or t == "number" or t == "string" or t == "table"
end
local function tableOrNil(value)
  return value == nil or type(value) == "table"
end
local function numberOrNil(value)
  return value == nil or finite(value)
end
local function skillName(value)
  if type(value) == "string" then return value end
  if type(value) == "table" and type(value.name) == "string" then return value.name end
  return nil
end

-- Build a real client room, not a plain table.  Request handlers, Player
-- predicates and Fk:currentRoom() therefore follow the production browser
-- code path while remaining entirely local.
local clientClass = Fk:getBoardGame("new_heg_mode").client_klass
ClientInstance = clientClass:new(__host_client)
ClientInstance.settings = {
  gameMode = "new_heg_mode", disabledPack = {}, disabledGenerals = {},
  _game = {}, _mode = {},
}
ClientInstance.capacity = 2
ClientInstance.timeout = 30
local meNative = __host_client:addPlayer(101, "skill-audit", "avatar")
local targetNative = __host_client:addPlayer(-101, "skill-target", "avatar")
Self = ClientInstance.clientplayer_klass:new(meNative)
local target = ClientInstance.clientplayer_klass:new(targetNative)
Self.id = 101
target.id = -101
ClientInstance.players = { Self, target }
ClientInstance.alive_players = { Self, target }
Self.next = target
target.next = Self
ClientInstance.current = Self
Self.general = ""
Self.deputyGeneral = ""
Self.hp, Self.maxHp, Self.shield = 3, 4, 0
Self.phase, Self.dead, Self.dying, Self.role_shown = Player.Play, false, false, true
Self.kingdom, Self.seat = "wei", 1
Self.role = "lord"
Self.room = ClientInstance
target.general = ""
target.deputyGeneral = ""
target.hp, target.maxHp, target.shield = 3, 4, 0
target.phase, target.dead, target.dying, target.role_shown = Player.NotActive, false, false, true
target.kingdom, target.seat = "shu", 2
target.role = "rebel"
target.room = ClientInstance
ClientInstance.logic = { current_trigger_event_id = 0 }
ClientInstance:setBanner("RoundCount", 1)
RoomInstance = nil

local function resetRoomState()
  local statuses = {}
  for class, skills in pairs(Fk.global_status_skill or {}) do statuses[class] = { table.unpack(skills) } end
  ClientInstance.status_skills = statuses
  ClientInstance.skill_costs = {}
  ClientInstance.filtered_cards = {}
  ClientInstance.current_request_handler = nil
  Self.player_skills, Self.derivative_skills, Self._fake_skills = {}, {}, {}
  Self.mark, Self.flag, Self.tag = {}, {}, {}
  Self.cardUsedHistory, Self.skillUsedHistory, Self.skillBranchUsedHistory = {}, {}, {}
  Self.player_cards = { [Player.Hand] = {}, [Player.Equip] = {}, [Player.Judge] = {} }
  target.player_skills, target.derivative_skills, target._fake_skills = {}, {}, {}
  target.mark, target.flag, target.tag = {}, {}, {}
  target.cardUsedHistory, target.skillUsedHistory, target.skillBranchUsedHistory = {}, {}, {}
  target.player_cards = { [Player.Hand] = {}, [Player.Equip] = {}, [Player.Judge] = {} }
  Self.phase = Player.Play
  target.phase = Player.NotActive
  Self.dead, Self.dying, target.dead, target.dying = false, false, false, false
  Self.hp, Self.maxHp, target.hp, target.maxHp = 3, 4, 3, 4
end

local probeIds = {}
for _, id in ipairs(Fk:getAllCardIds()) do
  local card = Fk:getCardById(id, true)
  if card and #probeIds < 4 then
    probeIds[#probeIds + 1] = id
  end
end
if #probeIds == 0 then error("No card ids available for skill activation audit") end
for _, id in ipairs(probeIds) do
  table.insert(Self.player_cards[Player.Hand], id)
  ClientInstance:setCardArea(id, Card.PlayerHand, Self.id)
end
local probeCardId = probeIds[1]
local probeCard = Fk:getCardById(probeCardId, true)
local slash = Fk:cloneCard("slash")
local probeExtra = { skillName = "__web_skill_activation_audit__", prompt = "" }

local function attachSkill(name)
  local skill = Fk.skills[name]
  if not skill then return nil end
  local ok, err = pcall(function() Self:addSkill(skill) end)
  if not ok then
    sample(result.hardFailures, name .. ".addSkill :: " .. tostring(err))
    return nil
  end
  return skill
end

local function eventFor(skill)
  local eventClass = skill.event
  if type(eventClass) ~= "table" or type(eventClass.new) ~= "function" then return nil end
  local eventName = tostring(eventClass.name or "")
  local data = {
    from = Self, to = target, who = Self, target = target,
    card = slash, cards = { probeCardId }, tos = { target },
    damage = 1, num = 1, reason = "skill_activation_audit",
    damageEvent = { from = Self, to = target, damage = 1, card = slash },
    extra_data = { kuanggucheck = true },
  }
  if string.find(eventName, "CardsMove", 1, true) or string.find(eventName, "MoveCards", 1, true) then
    data = {
      {
        from = Self, to = target, toArea = Card.PlayerHand,
        moveReason = fk.ReasonUse,
        moveInfo = {{ cardId = probeCardId, fromArea = Card.PlayerHand }},
        extra_data = { kuanggucheck = true },
      }
    }
  end
  local ok, event = pcall(function() return eventClass:new(ClientInstance, Self, data) end)
  return ok and event or nil
end

local function cardForSkill(skill)
  for _, card in ipairs(Fk.cards or {}) do
    if card and card.skill and skillName(card.skill) == skill.name then return card end
  end
  return probeCard
end

local function invokeStatus(skill, name)
  local card = probeCard
  if name == "FilterSkill" then
    probe(name, skill.name .. ".cardFilter", function() return skill:cardFilter(card, Self, false) end, booleanOrNil, false)
    probe(name, skill.name .. ".viewAs", function() return skill:viewAs(Self, card) end, tableOrNil, true)
    probe(name, skill.name .. ".equipSkillFilter", function() return skill:equipSkillFilter(skill, Self) end, booleanOrNil, true)
    probe(name, skill.name .. ".handlyCardsFilter", function() return skill:handlyCardsFilter(Self) end, tableOrNil, true)
    probe(name, skill.name .. ".cardSkillFilter", function() return skill:cardSkillFilter(card, Self) end, booleanOrNil, true)
    probe(name, skill.name .. ".skillFilter", function() return skill:skillFilter(Self) end, tableOrNil, true)
    probe(name, skill.name .. ".cardPicFilter", function() return skill:cardPicFilter(card, Self) end, booleanOrNil, true)
  elseif name == "AttackRangeSkill" then
    probe(name, skill.name .. ".getCorrect", function() return skill:getCorrect(Self, target, card) end, numberOrNil, true)
    probe(name, skill.name .. ".getFixed", function() return skill:getFixed(Self) end, numberOrNil, true)
    probe(name, skill.name .. ".getFinal", function() return skill:getFinal(Self) end, numberOrNil, true)
    probe(name, skill.name .. ".withinAttackRange", function() return skill:withinAttackRange(Self, target) end, booleanOrNil, true)
    probe(name, skill.name .. ".withoutAttackRange", function() return skill:withoutAttackRange(Self, target) end, booleanOrNil, true)
    probe(name, skill.name .. ".getVirtualWeaponAttackRange", function() return skill:getVirtualWeaponAttackRange(Self) end, numberOrNil, true)
  elseif name == "DistanceSkill" then
    probe(name, skill.name .. ".getCorrect", function() return skill:getCorrect(Self, target, card) end, numberOrNil, true)
    probe(name, skill.name .. ".getFixed", function() return skill:getFixed(Self, target, card) end, numberOrNil, true)
  elseif name == "InvaliditySkill" then
    probe(name, skill.name .. ".getInvalidity", function() return skill:getInvalidity(Self, skill) end, booleanOrNil, true)
    probe(name, skill.name .. ".getInvalidityAttackRange", function() return skill:getInvalidityAttackRange(Self, card) end, booleanOrNil, true)
  elseif name == "MaxCardsSkill" then
    probe(name, skill.name .. ".getFixed", function() return skill:getFixed(Self) end, numberOrNil, true)
    probe(name, skill.name .. ".getCorrect", function() return skill:getCorrect(Self) end, numberOrNil, true)
    probe(name, skill.name .. ".excludeFrom", function() return skill:excludeFrom(Self, card) end, booleanOrNil, true)
  elseif name == "ProhibitSkill" then
    probe(name, skill.name .. ".isProhibited", function() return skill:isProhibited(Self, target, card) end, booleanOrNil, true)
    probe(name, skill.name .. ".prohibitUse", function() return skill:prohibitUse(Self, card) end, booleanOrNil, true)
    probe(name, skill.name .. ".prohibitResponse", function() return skill:prohibitResponse(Self, card) end, booleanOrNil, true)
    probe(name, skill.name .. ".prohibitDiscard", function() return skill:prohibitDiscard(Self, card) end, booleanOrNil, true)
    probe(name, skill.name .. ".prohibitPindian", function() return skill:prohibitPindian(Self, target) end, booleanOrNil, true)
  elseif name == "TargetModSkill" then
    probe(name, skill.name .. ".bypassTimesCheck", function() return skill:bypassTimesCheck(Self, skill, Player.HistoryPhase, card, target) end, booleanOrNil, true)
    probe(name, skill.name .. ".getResidueNum", function() return skill:getResidueNum(Self, skill, Player.HistoryPhase, card, target) end, numberOrNil, true)
    probe(name, skill.name .. ".getFixedNum", function() return skill:getFixedNum(Self, skill, Player.HistoryPhase, card, target) end, numberOrNil, true)
    probe(name, skill.name .. ".getFixedTargets", function() return skill:getFixedTargets(Self, skill, card, {}) end, tableOrNil, true)
    probe(name, skill.name .. ".bypassDistancesCheck", function() return skill:bypassDistancesCheck(Self, skill, card, target) end, booleanOrNil, true)
    probe(name, skill.name .. ".getDistanceLimit", function() return skill:getDistanceLimit(Self, skill, card, target) end, numberOrNil, true)
    probe(name, skill.name .. ".getExtraTargetNum", function() return skill:getExtraTargetNum(Self, skill, card) end, numberOrNil, true)
    probe(name, skill.name .. ".getCardTip", function() return skill:getCardTip(Self, skill, card) end, tableOrNil, true)
    probe(name, skill.name .. ".getTargetTip", function() return skill:getTargetTip(Self, target, {}, {}, card, true, {}) end, tableOrNil, true)
    probe(name, skill.name .. ".isRemoved", function() return skill:isRemoved(Self, skill) end, booleanOrNil, true)
  elseif name == "VisibilitySkill" then
    probe(name, skill.name .. ".cardVisible", function() return skill:cardVisible(Self, card, true) end, booleanOrNil, true)
    probe(name, skill.name .. ".moveVisible", function() return skill:moveVisible(Self, {}, {}) end, booleanOrNil, true)
    probe(name, skill.name .. ".roleVisible", function() return skill:roleVisible(Self, target) end, booleanOrNil, true)
  elseif name == "HegUtil.BigKingdomSkill" then
    probe(name, skill.name .. ".getFixed", function() return skill:getFixed(Self) end, numberOrNil, true)
  elseif name == "HegUtil.ArraySummonSkill" then
    probe(name, skill.name .. ".canUse", function() return skill:canUse(Self, nil, probeExtra) end, predicateReturn, false)
    probe(name, skill.name .. ".cardFilter", function() return skill:cardFilter(Self, probeCardId, {}, {}) end, booleanOrNil, true)
    probe(name, skill.name .. ".targetFilter", function() return skill:targetFilter(Self, target, {}, {}, nil, probeExtra) end, booleanOrNil, true)
    probe(name, skill.name .. ".feasible", function() return skill:feasible(Self, {}, {}) end, booleanOrNil, true)
    probe(name, skill.name .. ".fixTargets", function() return skill:fixTargets(Self, {}, nil, probeExtra) end, tableOrNil, true)
  end
end

local function invokeUsable(skill, className)
  local selectedCards = {}
  local selectedTargets = { target }
  local card = className == "CardSkill" and cardForSkill(skill) or probeCard
  if className == "ActiveSkill" then
    probe(className, skill.name .. ".canUse", function() return skill:canUse(Self, nil, probeExtra) end, predicateReturn, false)
    probe(className, skill.name .. ".cardFilter", function() return skill:cardFilter(Self, probeCardId, {}, {}) end, booleanOrNil, true)
    probe(className, skill.name .. ".targetFilter", function() return skill:targetFilter(Self, target, {}, {}, nil, probeExtra) end, booleanOrNil, true)
    probe(className, skill.name .. ".feasible", function() return skill:feasible(Self, {}, {}) end, booleanOrNil, true)
    probe(className, skill.name .. ".fixTargets", function() return skill:fixTargets(Self, {}, nil, probeExtra) end, tableOrNil, true)
    probe(className, skill.name .. ".getMinTargetNum", function() return skill:getMinTargetNum(Self) end, finite, false)
    probe(className, skill.name .. ".getMaxTargetNum", function() return skill:getMaxTargetNum(Self) end, finite, false)
    probe(className, skill.name .. ".getDistanceLimit", function() return skill:getDistanceLimit(Self, card, target) end, numberOrNil, true)
    probe(className, skill.name .. ".withinDistanceLimit", function() return skill:withinDistanceLimit(Self, false, card, target) end, booleanOrNil, true)
    probe(className, skill.name .. ".withinTimesLimit", function() return skill:withinTimesLimit(Self, Player.HistoryPhase, card, nil, target) end, booleanOrNil, true)
    probe(className, skill.name .. ".prompt", function()
      if type(skill.prompt) == "function" then
        return skill:prompt(Self, selectedCards, selectedTargets, probeExtra)
      end
      return skill.prompt
    end, function(v) return v == nil or type(v) == "string" end, true)
  elseif className == "ViewAsSkill" then
    probe(className, skill.name .. ".enabledAtPlay", function() return skill:enabledAtPlay(Self) end, predicateReturn, false)
    probe(className, skill.name .. ".enabledAtResponse", function() return skill:enabledAtResponse(Self, true) end, predicateReturn, false)
    probe(className, skill.name .. ".enabledAtNullification", function() return skill:enabledAtNullification(Self, {}) end, booleanOrNil, true)
    probe(className, skill.name .. ".cardFilter", function() return skill:cardFilter(Self, probeCardId, {}, {}) end, booleanOrNil, true)
    probe(className, skill.name .. ".viewAs", function() return skill:viewAs(Self, { probeCardId }) end, tableOrNil, true)
    probe(className, skill.name .. ".targetFilter", function() return skill:targetFilter(Self, target, {}, {}, nil, probeExtra) end, booleanOrNil, true)
    probe(className, skill.name .. ".feasible", function() return skill:feasible(Self, {}, {}) end, booleanOrNil, true)
    probe(className, skill.name .. ".fixTargets", function() return skill:fixTargets(Self, { probeCardId }, nil, probeExtra) end, tableOrNil, true)
    probe(className, skill.name .. ".beforeUse", function() return skill:beforeUse(Self, { from = Self, tos = { target }, card = card }) end, function(v) return v == nil or type(v) == "string" or type(v) == "table" end, true)
    probe(className, skill.name .. ".afterUse", function() return skill:afterUse(Self, { from = Self, tos = { target }, card = card }) end, function(v) return v == nil end, true)
    probe(className, skill.name .. ".afterResponse", function() return skill:afterResponse(Self, { from = Self, card = card }) end, function(v) return v == nil end, true)
  elseif className == "CardSkill" then
    probe(className, skill.name .. ".canUse", function() return skill:canUse(Self, card, probeExtra) end, predicateReturn, false)
    probe(className, skill.name .. ".cardFilter", function() return skill:cardFilter(Self, target, {}, {}, card, probeExtra) end, booleanOrNil, true)
    probe(className, skill.name .. ".targetFilter", function() return skill:targetFilter(Self, target, {}, {}, card, probeExtra) end, booleanOrNil, true)
    probe(className, skill.name .. ".modTargetFilter", function() return skill:modTargetFilter(Self, target, {}, card, probeExtra) end, booleanOrNil, true)
    probe(className, skill.name .. ".feasible", function() return skill:feasible(Self, {}, {}, card) end, booleanOrNil, true)
    probe(className, skill.name .. ".fixTargets", function() return skill:fixTargets(Self, {}, card, probeExtra) end, tableOrNil, true)
    probe(className, skill.name .. ".getMinTargetNum", function() return skill:getMinTargetNum(Self) end, finite, false)
    probe(className, skill.name .. ".getMaxTargetNum", function() return skill:getMaxTargetNum(Self, card) end, finite, false)
    probe(className, skill.name .. ".getDistanceLimit", function() return skill:getDistanceLimit(Self, card, target) end, numberOrNil, true)
    probe(className, skill.name .. ".withinTimesLimit", function() return skill:withinTimesLimit(Self, Player.HistoryPhase, card, nil, target) end, booleanOrNil, true)
  end
end

local function invokeTrigger(skill)
  local event = eventFor(skill)
  if not event then
    local b = bucket("TriggerSkill")
    b.attempted = b.attempted + 2
    b.contextRequired = b.contextRequired + 2
    sample(result.contextRequiredSamples, skill.name .. ".event :: event class unavailable")
    return
  end
  local data = event.data
  probe("TriggerSkill", skill.name .. ".canRefresh", function() return skill:canRefresh(event, Self, Self, data) end, predicateReturn, true)
  probe("TriggerSkill", skill.name .. ".triggerable", function() return skill:triggerable(event, Self, Self, data) end, predicateReturn, true)
  probe("TriggerSkill", skill.name .. ".triggerableTimes", function() return skill:triggerableTimes(event, Self, Self, data) end, numberOrNil, true)
end

local seenSkills = {}
local function auditSkill(generalName, skillNameValue, visible, active)
  if type(skillNameValue) ~= "string" or skillNameValue == "" then return end
  result.generalSkillReferences = result.generalSkillReferences + 1
  if visible then result.visibleGeneralSkillReferences = result.visibleGeneralSkillReferences + 1 end
  if seenSkills[skillNameValue] then return end
  seenSkills[skillNameValue] = true
  result.uniqueGeneralSkills = result.uniqueGeneralSkills + 1
  local skill = Fk.skills[skillNameValue]
  if not skill then
    sample(result.missingGeneralSkills, generalName .. ":" .. skillNameValue)
    if active then sample(result.activeMissingGeneralSkills, generalName .. ":" .. skillNameValue) end
    return
  end
  local className = skill.class and skill.class.name or "<unknown>"
  result.classCounts[className] = (result.classCounts[className] or 0) + 1
  local skel = skill:getSkeleton()
  if skel and type(skel.tests) == "table" then
    result.upstreamSkeletonTests = result.upstreamSkeletonTests + #skel.tests
    if #skel.tests > 0 then result.skillsWithSkeletonTests = result.skillsWithSkeletonTests + 1 end
  end
  resetRoomState()
  Self.general = generalName
  local general = Fk.generals[generalName]
  if general then
    Self.kingdom = general.kingdom or Self.kingdom
    Self.gender = general.gender or Self.gender
    Self.maxHp = general.maxHp or Self.maxHp
    Self.hp = math.min(Self.hp, Self.maxHp)
  end
  local attached = attachSkill(skillNameValue)
  if not attached then return end
  if className == "ActiveSkill" or className == "ViewAsSkill" or className == "CardSkill" then
    invokeUsable(attached, className)
  elseif className == "TriggerSkill" then
    invokeTrigger(attached)
  elseif className == "AttackRangeSkill" or className == "DistanceSkill" or className == "FilterSkill" or
      className == "InvaliditySkill" or className == "MaxCardsSkill" or className == "ProhibitSkill" or
      className == "TargetModSkill" or className == "VisibilitySkill" or
      className == "HegUtil.ArraySummonSkill" or className == "HegUtil.BigKingdomSkill" then
    invokeStatus(attached, className)
  else
    local b = bucket(className)
    b.attempted = b.attempted + 1
    b.passed = b.passed + 1
  end
  if className == "ActiveSkill" or className == "ViewAsSkill" then
    result.uiActivation.attempted = result.uiActivation.attempted + 1
    local ok, err = pcall(function()
      attached._extra_data = probeExtra
      ClientInstance:setupRequestHandler(Self, "AskForUseActiveSkill", { skillNameValue, "", true, probeExtra })
    end)
    if ok then
      result.uiActivation.passed = result.uiActivation.passed + 1
    else
      local message = tostring(err)
      local lowered = string.lower(message)
      if string.find(lowered, "attempt to", 1, true) or
          string.find(message, "UI JSON exceeds byte limit", 1, true) or
          string.find(message, "assertion failed", 1, true) then
        result.uiActivation.contextRequired = result.uiActivation.contextRequired + 1
        sample(result.contextRequiredSamples, skillNameValue .. ".AskForUseActiveSkill :: " .. message)
      else
        result.uiActivation.failed = result.uiActivation.failed + 1
        sample(result.hardFailures, skillNameValue .. ".AskForUseActiveSkill :: " .. message)
      end
    end
  end
end

for generalName, general in pairs(Fk.generals) do
  result.generals = result.generals + 1
  local package = general.package
  local disabled = package and table.contains(Fk.game_mode_disabled["new_heg_mode"] or {}, package.name)
  local active = not disabled
  if active then result.activeGenerals = result.activeGenerals + 1 end
  local visible = not general.hidden and not general.total_hidden
  if visible then result.visibleGenerals = result.visibleGenerals + 1 end
  local refs, seen = {}, {}
  local function collect(value)
    local name = skillName(value)
    if name and not seen[name] then seen[name] = true; refs[#refs + 1] = name end
  end
  for _, value in ipairs(general.skills or {}) do collect(value) end
  for _, value in ipairs(general.other_skills or {}) do collect(value) end
  for _, value in ipairs(general.related_skills or {}) do collect(value) end
  for _, value in ipairs(general.related_other_skills or {}) do collect(value) end
  for _, value in ipairs(general.all_skills or {}) do collect(type(value) == "table" and value[1] or value) end
  for _, name in ipairs(refs) do auditSkill(generalName, name, visible and not disabled, active) end
end

if ClientInstance.current_request_handler then ClientInstance.current_request_handler:_finish() end
return result
`;

function ensureUpstream(): void {
  for (const spec of UPSTREAM_PACKAGE_NAMES.map(packageSpec)) {
    assert.ok(existsSync(path.join(UPSTREAM_ROOT, spec.sourceDirectory)), `Missing pinned upstream checkout: ${spec.sourceDirectory}`);
  }
}

function emptyBucket(): ProbeBucket {
  return { attempted: 0, passed: 0, contextRequired: 0, failed: 0 };
}

function printReport(report: ActivationReport): void {
  console.log(`Skill activation audit: ${report.generals} generals (${report.visibleGenerals} visible, ${report.activeGenerals} active), ` +
    `${report.generalSkillReferences} deduplicated general references / ${report.uniqueGeneralSkills} unique skill IDs`);
  console.log(`Classes: ${Object.entries(report.classCounts).sort(([a], [b]) => a.localeCompare(b)).map(([k, v]) => `${k || '<unknown>'}=${v}`).join(', ')}`);
  console.log(`Upstream skeleton tests: ${report.skillsWithSkeletonTests} skills / ${report.upstreamSkeletonTests} test callbacks discovered (not run in browser VM)`);
  console.log(`UI request activation: ${JSON.stringify(report.uiActivation)}`);
  for (const [name, bucket] of Object.entries(report.surfaces).sort(([a], [b]) => a.localeCompare(b))) {
    console.log(`${name}: ${JSON.stringify(bucket)}`);
  }
  if (report.missingGeneralSkills.length) console.log(`INFO missing references (including disabled packages): ${report.missingGeneralSkills.join(', ')}`);
  if (report.activeMissingGeneralSkills.length) console.log(`FAIL active general skills missing from runtime: ${report.activeMissingGeneralSkills.join(', ')}`);
  if (report.hardFailures.length) console.log(`FAIL activation samples: ${report.hardFailures.join(' | ')}`);
  if (report.contextRequiredSamples.length) console.log(`Context-required samples: ${report.contextRequiredSamples.slice(0, 12).join(' | ')}`);
  console.log(report.pass
    ? 'PASS skill activation surface: every referenced skill reached its callable local path without a hard runtime error'
    : 'FAIL skill activation surface: at least one referenced skill or browser request path raised a hard runtime error');
}

async function main(): Promise<ActivationReport> {
  ensureUpstream();
  const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES);
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {}, setup: () => {}, ui: () => {},
    log: (level, message) => { if (level === 'error') throw new Error(message); },
  }});
  try {
    await runtime.start();
    const report = await runtime.eval<Omit<ActivationReport, 'generatedAt' | 'packages' | 'pass'>>(LUA_ACTIVATION_AUDIT);
    const hardFailures = report.hardFailures;
    const missing = report.activeMissingGeneralSkills;
    const uiFailed = report.uiActivation.failed;
    const pass = hardFailures.length === 0 && missing.length === 0 && uiFailed === 0;
    return {
      ...report,
      generatedAt: new Date().toISOString(),
      packages: UPSTREAM_PACKAGE_NAMES.map(packageSpec),
      pass,
    };
  } finally {
    runtime.close();
  }
}

const report = await main();
if (process.argv.includes('--json')) console.log(JSON.stringify(report, null, 2));
else printReport(report);
if (!report.pass && !process.argv.includes('--report-only')) process.exitCode = 1;
