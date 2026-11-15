-- Source-level candidate Hegemony 方天画戟 probe using unmodified skill Lua
-- and real freekill-core helpers. No native event/registry/browser proof.
-- Usage: lua halberd-source-probe.lua <core-root> <halberd.lua>

local coreRoot, skillPath = ...
assert(type(coreRoot) == "string" and type(skillPath) == "string",
  "usage: halberd-source-probe.lua <core-root> <halberd.lua>")

local function read(path)
  local handle = assert(io.open(path, "rb"))
  local source = assert(handle:read("*a"))
  handle:close()
  return source
end

local isolatedTable = {}
for key, value in pairs(table) do isolatedTable[key] = value end
local room, skill, auxName, auxSkill
local env = {
  table = isolatedTable,
  UseCardData = {},
  Util = { FalseFunc = function() return false end, IdMapper = function(p) return p.id end },
  GameEvent = { UseCard = "use_card" },
  RoomInstance = { sendLog = function() end },
  fk = {
    AfterCardTargetDeclared = "after_target_declared",
    CardEffectCancelledOut = "effect_cancelled",
    CreateSkill = function(def)
      assert(not skill, "duplicate equip skill")
      skill = def
      def.effects = {}
      function def:addAuxActiveSkill(name, active)
        assert(not auxSkill, "duplicate auxiliary skill")
        auxName, auxSkill = name, active
      end
      function def:addEffect(event, effect)
        assert(not self.effects[event], "duplicate effect")
        self.effects[event] = effect
      end
      return def
    end,
  },
  Fk = { currentRoom = function() return room end, loadTranslationTable = function() end },
}
setmetatable(env, { __index = _G })

local function loadHelper(path, first, nextOne)
  local source = read(path)
  local startAt = assert(source:find(first, 1, true), first)
  local endAt = assert(source:find(nextOne, startAt + #first, true), nextOne)
  assert(load(source:sub(startAt, endAt - 1), "@" .. path, "t", env))()
end

local utils = coreRoot .. "/lua/core/util.lua"
loadHelper(utils, "function table.every(self, func)", "function table.find(self, func)")
loadHelper(utils, "function table.map(self, func)", "function table.reduce(self, init, func)")
loadHelper(utils, "function table.contains(self, element)", "function table.shuffle(self)")
loadHelper(utils, "function table.insertIfNeed(self, element)", "function table.insertTableIfNeed(self, list)")
local usecardPath = coreRoot .. "/ltk/core/events/usecard.lua"
loadHelper(usecardPath, "function UseCardData:setNullified()", "function RespondCardData:setNullified()")
loadHelper(usecardPath, "function UseCardData:addTarget(player, sub)", "function UseCardData:getSubTos(player)")
loadHelper(usecardPath, "function UseCardData:getSubTos(player)", "function UseCardData:changeCard(name, suit, number, skill_name)")

env.require = function(name)
  assert(name == "packages.hegemony.util")
  return { compareKingdomWith = function(a, b) return a.kingdom == b.kingdom end }
end

local actual = assert(loadfile(skillPath, "t", env))()
assert(actual == skill and skill.name == "#sa__halberd_skill")
assert(skill.attached_equip == "sa__halberd")
assert(auxName == "#sa__halberd_active" and auxSkill)
assert(auxSkill.can_use == env.Util.FalseFunc and auxSkill.card_filter == env.Util.FalseFunc)
assert(auxSkill.min_target_num == 1 and auxSkill.card_num == 0)

local function player(id, kingdom, enabled)
  return { class = "ServerPlayer", id = id, kingdom = kingdom, active = enabled,
    hasSkill = function(self, name) return self.active and name == skill.name end }
end
local actor = player(1, "shu", true)
local original = player(2, "wei")
local extra = player(3, "wu")
local sameFaction = player(4, "wei")
local selectedFaction = player(5, "wu")
local unknown = player(6, "unknown")

local events, asked, choice, playback = {}, 0, nil, 0
local costData = nil
local activeEvent = { setCostData = function(_, _, data) costData = data end,
  getCostData = function() return costData end }
local useEvent = { data = nil }
room = {
  players = {actor, original, extra, sameFaction, selectedFaction, unknown},
  getPlayerById = function(self, id)
    for _, p in ipairs(self.players) do if p.id == id then return p end end
  end,
  logic = { getCurrentEvent = function()
    return { findParent = function(_, typeName)
      assert(typeName == env.GameEvent.UseCard)
      return useEvent
    end }
  end },
  askToUseActiveSkill = function(self, who, params)
    asked = asked + 1
    assert(who == actor and params.skill_name == auxName)
    assert(params.prompt == "#sa__halberd-ask")
    assert(#params.extra_data.orig_tos == 1 and params.extra_data.orig_tos[1] == original.id)
    assert(#params.extra_data.targets == 1 and params.extra_data.targets[1] == extra.id)
    return nil, choice
  end,
  broadcastPlaySound = function() playback = playback + 1 end,
  setEmotion = function() end,
}
for _, p in ipairs(room.players) do p.room = room end

local function newUse(name)
  return setmetatable({from = actor, tos = {original}, card = {trueName = name or "slash"},
    getExtraTargets = function() return {extra} end}, {__index = env.UseCardData})
end
local function same(actual, expected)
  assert(#actual == #expected, "target count mismatch")
  for i, item in ipairs(expected) do assert(actual[i] == item, "target mismatch at " .. i) end
end

local checked = 0
local function check(label, run)
  local ok, message = pcall(run)
  assert(ok, label .. ": " .. tostring(message))
  checked = checked + 1
end

check("embedded auxiliary registry and faction/unknown target legality", function()
  auxSkill.orig_tos, auxSkill.targets = {original.id}, {extra.id, sameFaction.id, selectedFaction.id, unknown.id}
  assert(auxSkill.target_filter(auxSkill, actor, extra, {}))
  assert(not auxSkill.target_filter(auxSkill, actor, sameFaction, {}))
  assert(not auxSkill.target_filter(auxSkill, actor, actor, {}))
  assert(auxSkill.target_filter(auxSkill, actor, unknown, {extra}))
  assert(not auxSkill.target_filter(auxSkill, actor, selectedFaction, {extra}))
  auxSkill.targets = {extra.id}
  assert(not auxSkill.target_filter(auxSkill, actor, unknown, {}))
end)

local declared = assert(skill.effects.after_target_declared)
check("declared trigger checks actor, equipment, Slash and extra targets", function()
  local use = newUse()
  assert(declared.can_trigger(declared, nil, actor, actor, use))
  assert(not declared.can_trigger(declared, nil, original, actor, use))
  assert(not declared.can_trigger(declared, nil, actor, actor, newUse("duel")))
  actor.active = false
  assert(not declared.can_trigger(declared, nil, actor, actor, use))
  actor.active = true
  use.getExtraTargets = function() return {} end
  assert(not declared.can_trigger(declared, nil, actor, actor, use))
end)

check("active selection cancellation does not register targets", function()
  local use = newUse()
  choice, costData = nil, nil
  assert(not declared.on_cost(declared, activeEvent, actor, actor, use))
  assert(costData == nil and asked == 1)
end)

check("active cost selects targets and addTarget updates real core use data", function()
  local use = newUse()
  choice, costData = { targets = {extra} }, nil
  assert(declared.on_cost(declared, activeEvent, actor, actor, use))
  same(costData.tos, {extra})
  declared.on_use(declared, activeEvent, actor, actor, use)
  same(use.tos, {original, extra})
  assert(use.extra_data.saHalberd and playback == 1)
  same(use:getSubTos(extra), {})
end)

local cancelled = assert(skill.effects.effect_cancelled)
check("cancelled Slash nullifies whole use via real UseCardData helper", function()
  local use = newUse()
  use:addTarget(extra)
  use.extra_data = {saHalberd = true}
  useEvent.data = use
  local data = {card = {trueName = "slash"}, tos = {extra}}
  assert(cancelled.can_trigger(cancelled, nil, actor, actor, data))
  cancelled.on_use(cancelled, nil, actor, actor, data)
  assert(use.nullified == true)
end)

check("cancellation guard requires equipped flag/owner/Slash", function()
  local use = newUse()
  useEvent.data = use
  local data = {card = {trueName = "slash"}, tos = {extra}}
  assert(not cancelled.can_trigger(cancelled, nil, actor, actor, data))
  use.extra_data = {saHalberd = true}
  assert(not cancelled.can_trigger(cancelled, nil, original, actor, data))
  data.card.trueName = "duel"
  assert(not cancelled.can_trigger(cancelled, nil, actor, actor, data))
end)

check("no remaining targets means cancellation does not nullify use", function()
  local use = newUse()
  use.tos, use.extra_data = {}, {saHalberd = true}
  useEvent.data = use
  cancelled.on_use(cancelled, nil, actor, actor, {card={trueName="slash"}, tos={extra}})
  assert(use.nullified == nil)
end)

print(string.format("PASS halberd real upstream callbacks: %d cases; native/browser NOT RUN", checked))
