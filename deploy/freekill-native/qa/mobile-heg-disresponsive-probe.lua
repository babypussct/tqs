-- Execute selected real freekill-core functions and optionally real upstream
-- mobile_heg skills in a bounded Lua mock. This is source-level evidence only:
-- no native room, protocol, browser, or real skill registry is exercised.
-- Usage: lua mobile-heg-disresponsive-probe.lua <core-package-root> [mobile-heg-skills-dir]

local coreRoot, skillsRoot = ...
assert(type(coreRoot) == "string", "usage: probe.lua <core-package-root> [mobile-heg-skills-dir]")

local function read(path)
  local handle = assert(io.open(path, "rb"))
  local result = assert(handle:read("*a"))
  handle:close()
  return result
end

local tableLib = {}
for name, value in pairs(table) do tableLib[name] = value end
function tableLib.find(list, predicate)
  for _, item in ipairs(list) do
    if predicate(item) then return item end
  end
end

local currentRoom
local registered = {}
local env = {
  table = tableLib,
  GameLogic = {},
  UseCardData = {},
  Util = { DummyTable = {} },
  GameEvent = { Damage = "damage", Round = "round", UseCard = "use_card" },
  Player = { HistoryRound = "history_round", HistoryTurn = "history_turn" },
  Skill = { Compulsory = "compulsory" },
  fk = {
    CardUsing = "card_using",
    PreCardUse = "pre_card_use",
    CreateSkill = function(def)
      def.effects = {}
      def.addEffect = function(self, event, effect)
        assert(self == def and not self.effects[event])
        self.effects[event] = effect
      end
      def.addAcquireEffect = function(self, callback)
        assert(self == def)
        self.acquire = callback
      end
      registered[def.name] = def
      return def
    end,
  },
  Fk = {
    currentRoom = function() return currentRoom end,
    loadTranslationTable = function() end,
  },
}
setmetatable(env, { __index = _G })

local function loadActualFunction(path, first, nextOne)
  local source = read(path)
  local startPos = assert(source:find(first, 1, true), path .. ": missing " .. first)
  local endPos = assert(source:find(nextOne, startPos + #first, true), path .. ": missing " .. nextOne)
  local chunk, err = load(source:sub(startPos, endPos - 1), "@" .. path .. ":" .. first, "t", env)
  assert(chunk, err)
  chunk()
end

local utilityPath = coreRoot .. "/lua/core/util.lua"
loadActualFunction(utilityPath, "function table.contains(self, element)", "function table.shuffle(self)")
loadActualFunction(utilityPath, "function table.insertIfNeed(self, element)", "function table.insertTableIfNeed(self, list)")
loadActualFunction(utilityPath, "function table.insertTableIfNeed(self, list)", "function table.connect(...)")
loadActualFunction(coreRoot .. "/ltk/core/events/usecard.lua",
  "function UseCardData:setDisresponsive(target)", "function UseCardData:setUnoffsetable(target)")
loadActualFunction(coreRoot .. "/ltk/server/gamelogic.lua",
  "function GameLogic:getActualDamageEvents(n, func, scope, end_id)",
  "function GameLogic:damageByCardEffect(is_exact)")

local checkedCore, checkedSkills = 0, 0
local function check(label, action, skillCase)
  local ok, message = pcall(action)
  assert(ok, label .. ": " .. tostring(message))
  if skillCase then checkedSkills = checkedSkills + 1 else checkedCore = checkedCore + 1 end
end

local function player(name, kingdom)
  return { class = "ServerPlayer", name = name, kingdom = kingdom, marks = {}, shown = true,
    hasSkill = function(self, skill) return self.skill == skill end,
    hasShownSkill = function(self, skill) return self.skill == skill and self.shown end,
    getMark = function(self, mark) return self.marks[mark] or 0 end,
  }
end

local owner = player("owner", "wei")
local ally = player("ally", "wei")
local enemyA = player("enemy-A", "shu")
local enemyB = player("enemy-B", "wu")
local other = player("other", "qun")
local players = { owner, ally, enemyA, enemyB, other }

local function newRoom(damageEvents)
  local round = { id = 100, end_id = 200 }
  local logic = setmetatable({
    all_game_events = {},
    event_recorder = { damage = damageEvents or {} },
    getCurrentEvent = function()
      return { findParent = function(_, event, includeSelf)
        assert(event == "round" and includeSelf == true)
        return round
      end }
    end,
    getEventsOfScope = function(self, eventType, n, predicate, scope)
      assert(eventType == "use_card" and n == 1 and scope == "history_turn")
      local result = {}
      for _, use in ipairs(self.useEvents or {}) do
        if predicate(use) then
          result[#result + 1] = use
          if #result == n then break end
        end
      end
      return result
    end,
  }, { __index = env.GameLogic })
  local room = { players = players, alive_players = { owner, ally, enemyA, enemyB, other },
    logic = logic,
    setPlayerMark = function(_, subject, name, value) subject.marks[name] = value end,
  }
  for _, p in ipairs(players) do p.room = room end
  currentRoom = room
  return room
end

local function damage(id, from, to, opts)
  opts = opts or {}
  local recorded = id
  if opts.unrecorded then recorded = nil end
  return { id = id, end_id = id, data = {
    from = from, to = to,
    dealtRecorderId = recorded,
  } }
end

local function useCard(cardName, common)
  return setmetatable({
    card = { trueName = cardName, isCommonTrick = function() return common == true end },
    from = ally,
    tos = { enemyA, enemyB },
  }, { __index = env.UseCardData })
end

local function expectTargets(actual, expected)
  assert(#actual == #expected, "wrong list size " .. #actual .. ", expected " .. #expected)
  for index, target in ipairs(expected) do
    assert(actual[index] == target, "wrong target or duplicate at " .. index)
  end
end

check("real helper preserves old list and deduplicates player/table inserts", function()
  newRoom()
  local data = useCard("slash")
  data.disresponsiveList = { ally }
  data:setDisresponsive(enemyA)
  data:setDisresponsive({ enemyA, enemyB, enemyB })
  data:setDisresponsive({})
  expectTargets(data.disresponsiveList, { ally, enemyA, enemyB })
end)

check("real no-argument helper covers all room players, retaining existing targets", function()
  newRoom()
  local data = useCard("slash")
  data.disresponsiveList = { enemyB }
  data:setDisresponsive()
  expectTargets(data.disresponsiveList, { enemyB, owner, ally, enemyA, other })
end)

check("real history helper n=1 caps truthy matches, not side-effect callback visits", function()
  local room = newRoom({ damage(99, owner, enemyB), damage(101, owner, enemyA),
    damage(102, other, enemyB), damage(103, owner, enemyB), damage(201, owner, ally) })
  local visits = 0
  local matches = room.logic:getActualDamageEvents(1, function(event)
    visits = visits + 1
    return event.data.from == owner
  end, env.Player.HistoryRound)
  assert(#matches == 1 and matches[1].data.to == enemyA and visits == 1)
  local seen = {}
  local sideEffects = room.logic:getActualDamageEvents(1, function(event)
    seen[#seen + 1] = event.data.to
    -- Real bawei on_use callback does not return a truthy value.
  end, env.Player.HistoryRound)
  assert(#sideEffects == 0)
  expectTargets(seen, { enemyA, enemyB, enemyB })
end)

print(string.format("PASS mobile-heg real core: %d cases", checkedCore))
if not skillsRoot then return end

local hegemony = {
  compareKingdomWith = function(a, b) return a.kingdom == b.kingdom end,
  inSiegeRelation = function() return currentRoom.siege == true end,
}
env.require = function(name)
  assert(name == "packages.hegemony.util")
  return hegemony
end

local function loadSkill(name)
  local chunk, err = loadfile(skillsRoot .. "/" .. name .. ".lua", "t", env)
  assert(chunk, err)
  local result = chunk()
  assert(result == registered[result.name], "skill registry failed: " .. name)
  return result
end

local bawei, fengshi = loadSkill("bawei"), loadSkill("fengshi")
assert(bawei.name == "m_heg__bawei" and fengshi.name == "m_heg__fengshi")
owner.skill = bawei.name
local baweiCard = assert(bawei.effects.card_using)
local function baweiRoom(events, opts)
  local room = newRoom(events)
  owner.skill = opts and opts.skillAbsent and "none" or bawei.name
  return room
end

check("bawei scans entire round and deduplicates several damaged targets", function()
  baweiRoom({ damage(99, owner, other), damage(101, owner, enemyA),
    damage(102, other, ally), damage(103, owner, enemyA),
    damage(104, owner, enemyB), damage(105, other, other),
    damage(201, owner, other), damage(106, owner, ally, { unrecorded = true }) })
  local data = useCard("slash")
  data.disresponsiveList = { ally }
  assert(baweiCard.can_trigger(baweiCard, nil, ally, owner, data))
  baweiCard.on_use(baweiCard, nil, ally, owner, data)
  expectTargets(data.disresponsiveList, { ally, enemyA, enemyB })
end, true)

check("bawei enables same-kingdom common trick with real round damage", function()
  baweiRoom({ damage(104, owner, enemyB) })
  local data = useCard("duel", true)
  assert(baweiCard.can_trigger(baweiCard, nil, ally, owner, data))
  baweiCard.on_use(baweiCard, nil, ally, owner, data)
  expectTargets(data.disresponsiveList, { enemyB })
end, true)

check("bawei rejects non-common trick, other kingdom and nil card user", function()
  baweiRoom({ damage(101, owner, enemyA) })
  assert(not baweiCard.can_trigger(baweiCard, nil, ally, owner, useCard("equip")))
  assert(not baweiCard.can_trigger(baweiCard, nil, enemyA, owner, useCard("slash")))
  assert(not baweiCard.can_trigger(baweiCard, nil, nil, owner, useCard("slash")))
end, true)

check("bawei rejects only older/outside/unrecorded or other-owner damage", function()
  baweiRoom({ damage(99, owner, enemyA), damage(101, other, enemyA),
    damage(102, owner, enemyB, { unrecorded = true }), damage(201, owner, enemyB) })
  assert(not baweiCard.can_trigger(baweiCard, nil, ally, owner, useCard("slash")))
end, true)

check("bawei requires skill ownership", function()
  baweiRoom({ damage(101, owner, enemyA) }, { skillAbsent = true })
  assert(not baweiCard.can_trigger(baweiCard, nil, ally, owner, useCard("slash")))
end, true)

owner.skill = fengshi.name
local fengshiCard = assert(fengshi.effects.card_using)
local fengshiRefresh = assert(fengshi.effects.pre_card_use)
local fengshiMod = assert(fengshi.effects.targetmod)
local function fengshiRoom(opts)
  opts = opts or {}
  local room = newRoom()
  room.siege = opts.siege == true
  owner.skill = opts.skillAbsent and "none" or fengshi.name
  owner.shown = opts.shown ~= false
  owner.marks = {}
  local data = useCard(opts.card or "slash")
  data.from = owner
  room.logic.useEvents = opts.earlierUse and {
    { data = { from = owner } }, { data = data },
  } or { { data = { from = other } }, { data = data } }
  return room, data
end

check("fengshi first card in siege disallows whole room, without losing old flags", function()
  local room, data = fengshiRoom({ siege = true })
  data.disresponsiveList = { enemyB }
  assert(fengshiCard.can_trigger(fengshiCard, nil, owner, owner, data))
  fengshiCard.on_use(fengshiCard, nil, owner, owner, data)
  expectTargets(data.disresponsiveList, { enemyB, owner, ally, enemyA, other })
  assert(#room.players == 5)
end, true)

check("fengshi requires siege and first owner card in turn", function()
  local _, noSiege = fengshiRoom({ siege = false })
  assert(not fengshiCard.can_trigger(fengshiCard, nil, owner, owner, noSiege))
  local _, later = fengshiRoom({ siege = true, earlierUse = true })
  assert(not fengshiCard.can_trigger(fengshiCard, nil, owner, owner, later))
end, true)

check("fengshi refuses other event owner or missing skill", function()
  local _, data = fengshiRoom({ siege = true })
  assert(not fengshiCard.can_trigger(fengshiCard, nil, ally, owner, data))
  local _, absent = fengshiRoom({ siege = true, skillAbsent = true })
  assert(not fengshiCard.can_trigger(fengshiCard, nil, owner, owner, absent))
end, true)

check("fengshi first card bypasses distance only outside siege when shown", function()
  local _, data = fengshiRoom()
  assert(fengshiMod.bypass_distances(fengshiMod, owner, nil, data.card, enemyA))
  assert(fengshiRefresh.can_refresh(fengshiRefresh, nil, owner, owner, data))
  fengshiRefresh.on_refresh(fengshiRefresh, nil, owner, owner, data)
  assert(owner.marks["m_heg__fengshi-turn"] == 1)
  assert(not fengshiMod.bypass_distances(fengshiMod, owner, nil, data.card, enemyA))
  fengshiRoom({ siege = true })
  assert(not fengshiMod.bypass_distances(fengshiMod, owner, nil, data.card, enemyA))
  fengshiRoom({ shown = false })
  assert(not fengshiMod.bypass_distances(fengshiMod, owner, nil, data.card, enemyA))
end, true)

check("fengshi late acquisition reconstructs first-use mark", function()
  local room = fengshiRoom({ earlierUse = true })
  local callback = assert(fengshi.acquire)
  callback(fengshi, owner, false)
  assert(owner.marks["m_heg__fengshi-turn"] == 1)
  room.logic.useEvents = {}
  owner.marks = {}
  callback(fengshi, owner, false)
  assert(owner.marks["m_heg__fengshi-turn"] == nil)
end, true)

print(string.format("PASS mobile-heg real upstream skill callbacks: %d cases", checkedSkills))
