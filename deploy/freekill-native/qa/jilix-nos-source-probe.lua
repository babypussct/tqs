-- Verify the historical deputy-only skill independently of ld__jilix.
local path = assert(..., 'expected nos_heg__jilix Lua path')
local effects = {}
local H = { removeGeneral = function(player, deputy)
  assert(deputy == true and not player.removed)
  player.removed = true
end }
local env = setmetatable({
  fk = { TargetConfirmed = 'confirmed', DamageInflicted = 'damage', CreateSkill = function(def)
    function def:addEffect(event, effect) effects[event] = effect end
    return def
  end },
  Fk = { loadTranslationTable = function() end },
  Skill = { DeputyPlace = 'deputy', Compulsory = 'compulsory' },
  Card = { Red = 'red', TypeBasic = 'basic' },
  Player = { HistoryPhase = 'phase' },
  require = function(name) assert(name == 'packages.hegemony.util'); return H end,
}, { __index = _G })
local skill = assert(loadfile(path, 't', env))()
assert(skill.name == 'nos_heg__jilix' and skill.tags[1] == 'deputy' and skill.tags[2] == 'compulsory')
assert(effects.confirmed and effects.damage)
local count = 0
local function checkTarget(color, cardType, only, hasSkill, expected)
  local player = { hasSkill = function(_, name) assert(name == skill.name); return hasSkill end }
  local card = { color = color, type = cardType, isCommonTrick = function() return cardType == 'common' end }
  local data = { card = card, use = { additionalEffect = 2 }, isOnlyTarget = function(_, who) assert(who == player); return only end }
  local trigger = effects.confirmed.can_trigger(effects.confirmed, nil, player, player, data)
  assert(not not trigger == expected)
  if trigger then effects.confirmed.on_use(effects.confirmed, nil, player, player, data) end
  assert(data.use.additionalEffect == (expected and 3 or 2) and not player.removed)
  count = count + 1
end
checkTarget('red', 'basic', true, true, true)
checkTarget('red', 'common', true, true, true)
checkTarget('black', 'basic', true, true, false)
checkTarget('red', 'delayed', true, true, false)
checkTarget('red', 'basic', false, true, false)
checkTarget('red', 'basic', true, false, false)
local function checkDamage(previousHits, hasSkill, expected)
  local player = { hasSkill = function(_, name) assert(name == skill.name); return hasSkill end }
  player.room = { logic = { getActualDamageEvents = function(_, limit, predicate, scope)
    assert(limit == 2 and scope == 'phase')
    assert(predicate({data = {to = player}}) and not predicate({data = {to = {}}}))
    local events = {}
    for i = 1, previousHits do events[i] = {data = {to = player}} end
    return events
  end } }
  local data = { preventDamage = function(self) self.prevented = true end }
  local trigger = effects.damage.can_trigger(effects.damage, nil, player, player, data)
  assert(not not trigger == expected)
  if trigger then effects.damage.on_use(effects.damage, nil, player, player, data) end
  assert(not not data.prevented == expected and not not player.removed == expected)
  count = count + 1
end
checkDamage(0, true, false)
checkDamage(1, true, true)
checkDamage(2, true, false)
checkDamage(1, false, false)
print('PASS nos_heg__jilix source probe: '..count..' cases; native/browser NOT RUN')
