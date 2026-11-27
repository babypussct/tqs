-- Execute the pinned skill callbacks with a bounded room and ownership fixture.
local skillPath = assert(..., "expected Ký Ly Lua path")
local effects = {}
local H = {}
function H.inGeneralSkills(player, name)
  assert(name == "ld__jilix")
  return player.slot
end
function H.removeGeneral(player, deputy)
  assert(player.removed == nil)
  player.removed = deputy
end
local env = setmetatable({
  fk = { TargetConfirmed = "confirmed", CreateSkill = function(def)
    function def:addEffect(event, effect) effects[event] = effect end
    return def
  end },
  Fk = { loadTranslationTable = function() end },
  Skill = { Compulsory = "compulsory" },
  Card = { Red = "red", TypeBasic = "basic" },
  require = function(name) assert(name == "packages.hegemony.util"); return H end,
}, { __index = _G })
local skill = assert(loadfile(skillPath, "t", env))()
assert(skill.name == "ld__jilix" and skill.tags[1] == "compulsory")
assert(effects.confirmed and next(effects, "confirmed") == nil)
local effect = effects.confirmed
local count = 0
local function check(options, expected)
  local player = { slot = options.slot or "m" }
  function player:hasSkill(name) assert(name == skill.name); return not options.noSkill end
  local card = { color = options.color or "red", type = options.type or "basic" }
  function card:isCommonTrick() return self.type == "common" end
  function card:toLogString() return "fixture-card" end
  local data = { card = card, use = { additionalEffect = options.initial } }
  function data:isOnlyTarget(who) assert(who == player); return not options.multiple end
  local asks = 0
  player.room = { askToChoice = function(_, who, params)
    asks = asks + 1
    assert(who == player and params.skill_name == skill.name)
    assert(params.choices[1] == "ld__jilix_effect" and params.choices[2] == "ld__jilix_remove" and #params.choices == 2)
    assert(params.prompt == "#ld__jilix-choice:::fixture-card")
    return options.choice or "ld__jilix_effect"
  end }
  local target = options.otherTarget and {} or player
  local can = effect.can_trigger(effect, {}, target, player, data)
  assert(not not can == expected.trigger)
  if can then effect.on_use(effect, {}, target, player, data) end
  assert(asks == (expected.trigger and 1 or 0))
  assert(data.use.additionalEffect == expected.additional and player.removed == expected.removed)
  count = count + 1
end
check({}, { trigger = true, additional = 1 })
check({ initial = 2, type = "common" }, { trigger = true, additional = 3 })
check({ choice = "ld__jilix_remove" }, { trigger = true, removed = false })
check({ choice = "ld__jilix_remove", slot = "d", type = "common", initial = 1 }, { trigger = true, removed = true, additional = 1 })
check({ color = "black" }, { trigger = false })
check({ type = "equip" }, { trigger = false })
check({ type = "delayed" }, { trigger = false })
check({ multiple = true }, { trigger = false })
check({ noSkill = true }, { trigger = false })
check({ otherTarget = true }, { trigger = false })
print("PASS Ký Ly source probe: " .. count .. " cases; native/browser NOT RUN")
