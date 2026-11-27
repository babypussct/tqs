-- Exercise the actual Hegemony view-as and Fire Attack callbacks with a bounded
-- room/event fixture. The native event dispatcher and UI are outside this probe.
local skillPath, firePath = ...
assert(skillPath and firePath, "expected Thành Lược and Fire Attack Lua paths")
local effects = {}
local tables = setmetatable({}, { __index = table })
function tables.contains(items, value)
  for _, item in ipairs(items) do if item == value then return true end end
  return false
end
function tables.filter(items, predicate)
  local result = {}
  for _, item in ipairs(items) do if predicate(item) then result[#result + 1] = item end end
  return result
end
local env = setmetatable({
  table = tables, GameEvent = { CardEffect = "card_effect" }, Util = { CardTargetFilter = function() end },
  fk = { Damage = "damage", FireDamage = "fire", CreateSkill = function(def)
    effects[def.name] = {}
    function def:addEffect(event, effect) effects[self.name][event] = effect end
    function def:addAI() end
    return def
  end },
  Fk = { loadTranslationTable = function() end,
    cloneCard = function(_, name)
      return { name = name, addSubcard = function(self, id) self.subcard = id end }
    end,
    getCardById = function(_, id)
      assert(id == 42); return { getSuitString = function() return "heart" end }
    end,
    Ltk = { AI = { newCardSkillStrategy = function() end, newDiscardStrategy = function() end } },
  },
}, { __index = _G })
local skill = assert(loadfile(skillPath, "t", env))()
local fire = assert(loadfile(firePath, "t", env))()
assert(skill.name == "ld__chenglue" and fire.name == "fire_attack_skill")
local view, trigger = effects[skill.name].viewas, effects[skill.name].damage
local attack = effects[fire.name].cardskill
assert(view.pattern == "fire_attack" and view.filter_pattern.pattern == ".|.|.|.|.|basic")
assert(view.filter_pattern.min_num == 1 and view.filter_pattern.max_num == 1)
assert(view.enabled_at_response(view, {}, false) and not view.enabled_at_response(view, {}, true))
assert(view.view_as(view, {}, {}) == nil and view.view_as(view, {}, {1, 2}) == nil)
for _, id in ipairs({ 11, 12, 13 }) do
  local card = view.view_as(view, {}, {id})
  assert(card.name == "fire_attack" and card.skillName == skill.name and card.subcard == id)
end
local checks = 0
local function scenario(name, options, expected)
  local actor = { id = 1 }
  local target = { id = 2, dead = false }
  local chained = { id = 3 }
  local shown, thrown, damageCalls, cost = nil, {}, 0, nil
  local room = {}
  target.room, chained.room = room, room
  function target:isKongcheng() return false end
  function target:showCards(id) shown = id end
  function target:getCardIds(area) assert(area == "he"); return options.gone and {43} or {42, 43} end
  function target:prohibitDiscard(id) assert(id == 42); return options.prohibited end
  local card = { skillNames = options.otherSkill and {"other"} or {skill.name} }
  local effect = { from = actor, to = target, card = card }
  local event = { setCostData = function(_, _, value) cost = value end, getCostData = function() return cost end }
  room.logic = { getCurrentEvent = function()
    return { findParent = function(_, kind)
      assert(kind == env.GameEvent.CardEffect)
      if options.noParent then return nil end
      return { data = { to = options.wrongEffectTarget and actor or target, extra_data = effect.extra_data } }
    end }
  end }
  function room:askToCards(player, params)
    assert(player == target and params.pattern == ".|.|.|hand" and not params.cancelable)
    return {42}
  end
  function room:askToDiscard(player, params)
    assert(player == actor and params.pattern == ".|.|heart" and params.cancelable)
    return options.cancel and {} or {11}
  end
  function room:throwCard(cards, reason, owner, proposer)
    assert(reason == skill.name and owner == target and proposer == target)
    for _, id in ipairs(cards) do thrown[#thrown + 1] = id end
  end
  function room:damage(data)
    damageCalls = damageCalls + 1
    assert(data.to == target and data.from == actor and data.damage == 1 and data.damageType == env.fk.FireDamage)
    assert(shown == 42 and effect.extra_data.fire_attack_show[1] == 42)
    if options.prevented then return end
    data.chain = options.chain
    if options.otherTarget then data.to = chained end
    if trigger.can_trigger(trigger, event, actor, target, data) then
      trigger.on_use(trigger, event, actor, target, data)
    end
  end
  attack.on_effect(attack, room, effect)
  assert(shown == 42, name)
  assert(damageCalls == (options.cancel and 0 or 1), name .. " damage count")
  assert(#thrown == expected and (expected == 0 or thrown[1] == 42), name .. " exact discard")
  checks = checks + 1
end
scenario("direct damage", {}, 1)
scenario("repeated use", {}, 1)
scenario("cancel payment", {cancel = true}, 0)
scenario("prevented damage", {prevented = true}, 0)
scenario("chain damage", {chain = true}, 0)
scenario("wrong damaged player", {otherTarget = true}, 0)
scenario("wrong CardEffect target", {wrongEffectTarget = true}, 0)
scenario("unrelated Fire Attack", {otherSkill = true}, 0)
scenario("no CardEffect parent", {noParent = true}, 0)
scenario("shown card removed", {gone = true}, 0)
scenario("shown card protected", {prohibited = true}, 0)
print("PASS Thành Lược source probe: 11 damage scenarios and view-as contract")
