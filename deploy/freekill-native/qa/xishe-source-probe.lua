-- Exercise the unchanged upstream ld__xishe callbacks with the actual core
-- setDisresponsive helper. This is a bounded Lua source harness, not native QA.
-- Usage: lua xishe-source-probe.lua <freekill-core-root> <xishe.lua>
local coreRoot, skillPath = ...
assert(coreRoot and skillPath, "usage: xishe-source-probe.lua <core-root> <xishe.lua>")

local function read(path)
  local f = assert(io.open(path, "rb"))
  local data = assert(f:read("*a"))
  f:close()
  return data
end

local tableLib = {}
for key, value in pairs(table) do tableLib[key] = value end
function tableLib.find(items, predicate)
  for _, item in ipairs(items) do if predicate(item) then return item end end
end

local activeRoom, transformed = nil, 0
local effects = {}
local env = {
  table = tableLib,
  UseCardData = {},
  Player = { Start = "start" },
  GameEvent = { UseCard = "use_card" },
  Util = { TrueFunc = function() return true end },
  fk = {
    EventPhaseStart = "phase_start", Death = "death", CardUsing = "card_using", TurnEnd = "turn_end",
    CreateSkill = function(def)
      def.addEffect = function(self, event, effect)
        assert(self == def and not effects[event], "duplicate skill event")
        effects[event] = effect
      end
      return def
    end,
  },
  Fk = {
    loadTranslationTable = function() end,
    currentRoom = function() return activeRoom end,
    getCardById = function(_, id) return { id = id } end,
    cloneCard = function(_, name) assert(name == "slash"); return { name = name } end,
  },
}
setmetatable(env, { __index = _G })
env.require = function(name)
  assert(name == "packages.hegemony.util")
  return { transformGeneral = function(room, player, main, hidden)
    assert(room == activeRoom and player == activeRoom.actor and main == false and hidden == true)
    transformed = transformed + 1
  end }
end

local function loadFunction(path, first, after)
  local data = read(path)
  local start = assert(data:find(first, 1, true), "missing function " .. first)
  local finish = assert(data:find(after, start + #first, true), "missing delimiter " .. after)
  local chunk = assert(load(data:sub(start, finish - 1), "@" .. path, "t", env))
  chunk()
end

local utilPath = coreRoot .. "/lua/core/util.lua"
loadFunction(utilPath, "function table.contains(self, element)", "function table.shuffle(self)")
loadFunction(utilPath, "function table.insertIfNeed(self, element)", "function table.insertTableIfNeed(self, list)")
loadFunction(utilPath, "function table.insertTableIfNeed(self, list)", "function table.connect(...)")
loadFunction(coreRoot .. "/ltk/core/events/usecard.lua",
  "function UseCardData:setDisresponsive(target)", "function UseCardData:setUnoffsetable(target)")

local skill = assert(loadfile(skillPath, "t", env))()
assert(skill.name == "ld__xishe")
local phase, death, using, turn = effects.phase_start, effects.death, effects.card_using, effects.turn_end
assert(phase and death and using and turn)

local checks = 0
local function check(name, callback)
  local ok, err = pcall(callback)
  assert(ok, name .. ": " .. tostring(err))
  checks = checks + 1
end

local function fixture()
  transformed = 0
  local actor = { class = "ServerPlayer", id = 1, hp = 3, equipment = { 101, 102 }, dead = false,
    marks = {}, skillEnabled = true, blocked = {},
    hasSkill = function(self, name) return self.skillEnabled and name == skill.name end,
    getCardIds = function(self, area) assert(area == "e"); return self.equipment end,
    prohibitDiscard = function(self, card) return self.blocked[card.id] or false end,
    getMark = function(self, name) return self.marks[name] or 0 end,
  }
  local low = { class = "ServerPlayer", id = 2, hp = 2, phase = env.Player.Start }
  local equal = { class = "ServerPlayer", id = 3, hp = 3, phase = env.Player.Start }
  local high = { class = "ServerPlayer", id = 4, hp = 4, phase = env.Player.Start }
  local room = { actor = actor, players = { actor, low, equal, high }, steps = {}, uses = {}, queue = {} }
  room.logic = { getMostRecentEvent = function(_, event)
    assert(event == env.GameEvent.UseCard)
    return { data = { extra_data = { ld__xisheUser = actor } } }
  end }
  function room:askToDiscard(player, opts)
    assert(player == actor and opts.min_num == 1 and opts.max_num == 1)
    assert(opts.include_equip and opts.cancelable and opts.skill_name == skill.name)
    assert(opts.pattern == ".|.|.|equip" and opts.prompt == "#ld__xishe::" .. low.id)
    local nextCard = table.remove(self.queue, 1)
    self.steps[#self.steps + 1] = nextCard or "cancel"
    if not nextCard then return {} end
    for index, card in ipairs(actor.equipment) do
      if card == nextCard then table.remove(actor.equipment, index); return { card } end
    end
    error("discard attempted on absent equipment")
  end
  function room:useCard(use)
    assert(use.from == actor and use.card.skillName == skill.name and use.extraUse)
    assert(use.extra_data.ld__xisheUser == actor and #use.tos == 1 and use.tos[1] == low)
    local real = setmetatable(use, { __index = env.UseCardData })
    assert(using.can_trigger(using, nil, actor, actor, real))
    using.on_use(using, nil, actor, actor, real)
    self.uses[#self.uses + 1] = real
  end
  function room:setPlayerMark(who, mark, value)
    who.marks[mark] = value
  end
  function room:askToChoice(who, opts)
    assert(who == actor and opts.skill_name == skill.name)
    assert(opts.choices[1] == "transformDeputy" and opts.choices[2] == "Cancel")
    return self.choice
  end
  actor.room, low.room, equal.room, high.room = room, room, room, room
  activeRoom = room
  return room, actor, low, equal, high
end

check("phase eligible with two equipment", function()
  local _, actor, low = fixture()
  assert(phase.can_trigger(phase, nil, low, actor, {}))
end)
check("phase rejects missing owner skill", function()
  local _, actor, low = fixture()
  actor.skillEnabled = false
  assert(not phase.can_trigger(phase, nil, low, actor, {}))
end)
check("phase rejects self", function()
  local _, actor = fixture()
  actor.phase = env.Player.Start
  assert(not phase.can_trigger(phase, nil, actor, actor, {}))
end)
check("phase rejects wrong phase", function()
  local _, actor, low = fixture()
  low.phase = "play"
  assert(not phase.can_trigger(phase, nil, low, actor, {}))
end)
check("phase rejects empty or prohibited equipment", function()
  local _, actor, low = fixture()
  actor.equipment = {}
  assert(not phase.can_trigger(phase, nil, low, actor, {}))
  actor.equipment = { 101, 102 }
  actor.blocked[101], actor.blocked[102] = true, true
  assert(not phase.can_trigger(phase, nil, low, actor, {}))
end)
check("two equipment discards generate two real callback Slashes", function()
  local room, actor, low = fixture()
  room.queue = { 101, 102 }
  phase.on_use(phase, nil, low, actor, {})
  assert(#room.uses == 2 and #actor.equipment == 0 and #room.steps == 2)
  for _, use in ipairs(room.uses) do
    assert(#use.disresponsiveList == 1 and use.disresponsiveList[1] == low)
  end
end)
check("initial cancellation keeps both equipment", function()
  local room, actor, low = fixture()
  phase.on_use(phase, nil, low, actor, {})
  assert(#room.uses == 0 and #room.steps == 1 and #actor.equipment == 2)
end)
check("repeat cancellation keeps armor after first Slash", function()
  local room, actor, low = fixture()
  room.queue = { 101 }
  phase.on_use(phase, nil, low, actor, {})
  assert(#room.uses == 1 and #room.steps == 2 and actor.equipment[1] == 102)
end)
check("dead actor stops repeated offers", function()
  local room, actor, low = fixture()
  room.queue = { 101, 102 }
  local original = room.useCard
  function room:useCard(use) original(self, use); actor.dead = true end
  phase.on_use(phase, nil, low, actor, {})
  assert(#room.uses == 1 and #room.steps == 1)
end)
check("death refresh requires damage by xishe", function()
  local _, actor = fixture()
  local data = { damage = { card = { skillNames = { skill.name } } } }
  assert(death.can_refresh(death, nil, actor, actor, data))
  death.on_refresh(death, nil, actor, actor, data)
  assert(actor:getMark("ld__xishe_change-turn") == 1)
end)
check("death refresh ignores unrelated causes and seats", function()
  local _, actor, low = fixture()
  assert(not death.can_refresh(death, nil, actor, actor, {}))
  assert(not death.can_refresh(death, nil, actor, actor, { damage = { card = { skillNames = { "other" } } } }))
  assert(not death.can_refresh(death, nil, low, actor, { damage = { card = { skillNames = { skill.name } } } }))
end)
check("CardUsing owner marker determines callback eligibility", function()
  local _, actor, low = fixture()
  assert(using.can_trigger(using, nil, actor, actor, { extra_data = { ld__xisheUser = actor } }))
  assert(not using.can_trigger(using, nil, low, actor, { extra_data = { ld__xisheUser = actor } }))
  assert(not using.can_trigger(using, nil, actor, actor, {}))
end)
check("CardUsing lower HP only; no duplication or suppression at equal/higher HP", function()
  local _, actor, low, equal, high = fixture()
  local use = setmetatable({ tos = { low, equal, high, low } }, { __index = env.UseCardData })
  using.on_use(using, nil, actor, actor, use)
  assert(#use.disresponsiveList == 1 and use.disresponsiveList[1] == low)
end)
check("TurnEnd transform only when marked and selected", function()
  local room, actor = fixture()
  assert(not turn.can_trigger(turn, nil, actor, actor, {}))
  actor.marks["ld__xishe_change-turn"] = 1
  assert(turn.can_trigger(turn, nil, actor, actor, {}))
  room.choice = "transformDeputy"
  turn.on_use(turn, nil, actor, actor, {})
  assert(transformed == 1)
end)
check("TurnEnd cancellation does not transform", function()
  local room, actor = fixture()
  room.choice = "Cancel"
  turn.on_use(turn, nil, actor, actor, {})
  assert(transformed == 0)
end)

print(string.format("PASS xishe real upstream callbacks and core helper: %d cases; native/browser NOT RUN", checks))
