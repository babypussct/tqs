-- Source-level probe for Hegemony's sijian callback contract.
-- Usage: lua5.4 sijian-trigger-probe.lua /absolute/path/to/sijian.lua empty|nonempty
-- This executes the original skill file in an isolated mock engine. It does not
-- exercise a real native room, player hand, protocol or browser.

local source, mode = ...
assert(type(source) == "string" and (mode == "empty" or mode == "nonempty"),
  "usage: lua5.4 sijian-trigger-probe.lua <skill.lua> empty|nonempty")

local skill, translated
local fixtureTable = {
  find = function(items, fn)
    for _, item in ipairs(items) do
      if fn(item) then return item end
    end
  end,
  filter = function(items, fn)
    local selected = {}
    for _, item in ipairs(items) do
      if fn(item) then selected[#selected + 1] = item end
    end
    return selected
  end,
}
local ai = { ChoosePlayersStrategy = {} }
function ai.reuse() return {} end

local env = {
  ipairs = ipairs,
  table = fixtureTable,
  Card = { PlayerHand = "hand" },
  fk = {
    AfterCardsMove = "after_cards_move",
    CreateSkill = function(def)
      skill = def
      function skill:addEffect(event, effect)
        assert(event == "after_cards_move")
        self.effect = effect
      end
      function skill:addAI() end
      return skill
    end,
  },
  Fk = {
    Ltk = { AI = ai },
    loadTranslationTable = function(_, strings)
      translated = strings
    end,
  },
}
local load, loadErr = loadfile(source, "t", env)
assert(load, loadErr)
assert(load() == skill and skill.name == "sijian" and skill.effect,
  "expected the real sijian source to register a trigger effect")
assert(translated[":sijian"]:find("若你没有手牌", 1, true),
  "translation's empty-hand requirement unexpectedly changed")

local checked = 0
local function scenario(label, options)
  local calls = { choosePlayers = 0, chooseCard = 0, throwCard = 0 }
  local owner, other, room, event
  other = {
    isNude = function() return options.nude == true end,
  }
  room = {
    getOtherPlayers = function(_, p, includeDead)
      assert(p == owner and includeDead == false)
      return { other }
    end,
    askToChoosePlayers = function(_, p, request)
      assert(p == owner and #request.targets == 1 and request.targets[1] == other)
      assert(request.min_num == 1 and request.max_num == 1 and request.cancelable)
      assert(request.skill_name == "sijian" and request.prompt == "#sijian-choose")
      calls.choosePlayers = calls.choosePlayers + 1
      if options.cancel then return {} end
      return { other }
    end,
    askToChooseCard = function(_, p, request)
      assert(p == owner and request.target == other and request.flag == "he")
      assert(request.skill_name == "sijian")
      calls.chooseCard = calls.chooseCard + 1
      return 12345
    end,
    throwCard = function(_, id, skillName, target, p)
      assert(id == 12345 and skillName == "sijian" and target == other and p == owner)
      calls.throwCard = calls.throwCard + 1
    end,
  }
  owner = {
    room = room,
    hasSkill = function(_, name)
      assert(name == "sijian")
      return options.hasSkill ~= false
    end,
    isKongcheng = function() return options.empty end,
  }
  local cost
  event = {
    setCostData = function(_, self, value)
      assert(self == skill.effect)
      cost = value
    end,
    getCostData = function(_, self)
      assert(self == skill.effect)
      return cost
    end,
  }

  local movedBy = options.fromOther and {} or owner
  local area = options.equipmentOnly and "equip" or "hand"
  local data = options.noMoves and {} or { { from = movedBy, moveInfo = { { fromArea = area } } } }
  local triggered = not not skill.effect.can_trigger(skill.effect, event, nil, owner, data)
  assert(triggered == options.expected,
    string.format("%s (%s): expected trigger=%s but got %s", label, mode,
      tostring(options.expected), tostring(triggered)))
  if triggered then
    local costAccepted = not not skill.effect.on_cost(skill.effect, event, nil, owner, data)
    assert(costAccepted == (not options.cancel), label .. ": unexpected cost result")
    if costAccepted then
      assert(cost and cost.tos and cost.tos[1] == other, label .. ": wrong target")
      skill.effect.on_use(skill.effect, event, nil, owner, data)
      assert(calls.chooseCard == 1 and calls.throwCard == 1,
        label .. ": expected exactly one card choice and discard")
    end
    assert(calls.choosePlayers == 1, label .. ": expected one target choice")
  else
    assert(calls.choosePlayers == 0 and calls.chooseCard == 0 and calls.throwCard == 0,
      label .. ": unexpected effect")
  end
  if options.cancel then
    assert(calls.chooseCard == 0 and calls.throwCard == 0, label .. ": cancel had side effects")
  end
  checked = checked + 1
end

scenario("lost last hand card", { empty = true, expected = mode == "empty" })
scenario("hand still occupied", { empty = false, expected = mode == "nonempty" })
scenario("equipment move only", { empty = mode == "empty", equipmentOnly = true, expected = false })
scenario("skill not owned", { empty = mode == "empty", hasSkill = false, expected = false })
scenario("no discardable opponent", { empty = mode == "empty", nude = true, expected = false })
scenario("other player lost hand", { empty = mode == "empty", fromOther = true, expected = false })
scenario("no move", { empty = mode == "empty", noMoves = true, expected = false })
scenario("owner cancels choice", { empty = mode == "empty", cancel = true, expected = true })

print(string.format("PASS sijian source-level %s: %d cases (includes callback use/cancel)", mode, checked))
