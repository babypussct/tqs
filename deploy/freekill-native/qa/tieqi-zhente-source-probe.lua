-- Deterministic source-level callback probe for real candidate Hegemony Lua.
-- This does not exercise the native event dispatcher, network or browser.
-- Usage: lua tieqi-zhente-source-probe.lua <freekill-core-root> <hegemony-pkg-root>

local coreRoot, pkgRoot = ...
assert(type(coreRoot) == "string" and type(pkgRoot) == "string",
  "usage: tieqi-zhente-source-probe.lua <core-root> <hegemony-pkg-root>")

local function read(path)
  local file = assert(io.open(path, "rb"))
  local value = assert(file:read("*a"))
  file:close()
  return value
end

local libs = {}
for key, value in pairs(table) do libs[key] = value end
local currentRoom, localChoice, lordSkill
local registered = {}
local env = {
  table = libs,
  UseCardData = {},
  AimData = {},
  Skill = { Compulsory = "compulsory" },
  Card = { NoSuit = "no_suit", Black = "black", Red = "red", TypeBasic = "basic" },
  Util = { IdMapper = function(p) return p.id end },
  RoomInstance = { sendLog = function() end },
  fk = {
    TargetSpecified = "target_specified", TargetConfirmed = "target_confirmed",
    CreateSkill = function(def)
      def.effects = {}
      function def:addEffect(event, effect)
        assert(not self.effects[event], "duplicate skill effect: " .. tostring(event))
        self.effects[event] = effect
      end
      function def:addTest() end
      assert(not registered[def.name], "duplicate skill registration: " .. def.name)
      registered[def.name] = def
      return def
    end,
  },
  Fk = {
    generals = {}, skills = {},
    currentRoom = function() return currentRoom end,
    loadTranslationTable = function() end,
  },
}
setmetatable(env, { __index = _G })

local function realFunction(path, first, nextOne)
  local source = read(path)
  local startAt = assert(source:find(first, 1, true), "missing: " .. first)
  local endAt = assert(source:find(nextOne, startAt + #first, true), "missing: " .. nextOne)
  local chunk = assert(load(source:sub(startAt, endAt - 1), "@" .. path, "t", env))
  chunk()
end

local utils = coreRoot .. "/lua/core/util.lua"
realFunction(utils, "function table.filter(self, func)", "function table.map(self, func)")
realFunction(utils, "function table.map(self, func)", "function table.reduce(self, init, func)")
realFunction(utils, "function table.contains(self, element)", "function table.shuffle(self)")
realFunction(utils, "function table.insertIfNeed(self, element)", "function table.insertTableIfNeed(self, list)")
realFunction(utils, "function table.insertTableIfNeed(self, list)", "function table.connect(...)")
realFunction(utils, "function string:startsWith(start)", "function string:endsWith(e)")
realFunction(coreRoot .. "/ltk/core/events/usecard.lua",
  "function UseCardData:setDisresponsive(target)", "function UseCardData:setUnoffsetable(target)")
realFunction(coreRoot .. "/ltk/core/events/usecard.lua",
  "function AimData:setNullified(target)", "function AimData:getResponseTimes(target)")

env.require = function(name)
  if name == "packages.hegemony.util" then
    return { hasHegLordSkill = function() return lordSkill == true end }
  end
  if name == "packages.utility.utility" then
    return { askToChooseGeneralsAndChoice = function(_, args)
      localChoice = localChoice + 1
      assert(#args.generals >= 1 and args.max_num == 1)
      return { args.generals[1] }
    end }
  end
  error("unexpected require: " .. name)
end

local function loadSkill(path)
  local chunk = assert(loadfile(pkgRoot .. "/" .. path, "t", env))
  local skill = chunk()
  assert(skill == registered[skill.name], "skill not registered: " .. path)
  return skill
end

local std = loadSkill("standard/skills/tieqi.lua")
local power = loadSkill("power/skills/tieqi.lua")
local zhente = loadSkill("tenyear_heg/skills/zhente.lua")
assert(std.name == "hs__tieqi" and power.name == "xuanhuo__hs__tieqi")
assert(zhente.name == "ty_heg__zhente")

local function mockSkill(name, compulsory)
  return { name = name,
    hasTag = function(_, tag) return tag == env.Skill.Compulsory and compulsory end,
    isPlayerSkill = function(_, target) return target ~= nil end,
  }
end
env.Fk.skills.normal_main = mockSkill("normal_main", false)
env.Fk.skills.compulsory_main = mockSkill("compulsory_main", true)
env.Fk.skills.normal_deputy = mockSkill("normal_deputy", false)
env.Fk.skills.unrelated = mockSkill("unrelated", false)
env.Fk.generals.main = { getSkillNameList = function() return { "normal_main", "compulsory_main" } end }
env.Fk.generals.deputy = { getSkillNameList = function() return { "normal_deputy" } end }

local function mockPlayer(id, activeSkill)
  local p = { id = id, class = "ServerPlayer", marks = {},
    general = "main", deputyGeneral = "deputy", skill = activeSkill,
    used = 0,
    getMark = function(self, name) return self.marks[name] or 0 end,
    getTableMark = function(self, name)
      local value = self.marks[name]
      return type(value) == "table" and value or {}
    end,
    hasSkill = function(self, name) return self.skill == name end,
    usedSkillTimes = function(self) return self.used end,
  }
  return p
end

local function setup(skill)
  local actor, target, bystander = mockPlayer(1, skill.name), mockPlayer(2), mockPlayer(3)
  local room = { players = { actor, target, bystander },
    judgeSuit = "spade", discard = {}, invoke = true, chooseNegate = true,
    judgeCalls = 0, discardCalls = 0, marksSet = 0, logs = {},
    judge = function(self, judge)
      self.judgeCalls = self.judgeCalls + 1
      judge.card = { suit = self.judgeSuit,
        getSuitString = function(card) return card.suit end }
    end,
    askToDiscard = function(self, _, options)
      self.discardCalls = self.discardCalls + 1
      assert(options.cancelable and options.include_equip)
      assert(options.pattern == ".|.|" .. self.judgeSuit)
      return self.discard
    end,
    setPlayerMark = function(self, p, key, value)
      self.marksSet = self.marksSet + 1
      p.marks[key] = value
    end,
    sendLog = function(self, log) self.logs[#self.logs + 1] = log end,
    askToSkillInvoke = function(self) return self.invoke end,
    askToChoice = function(self, p, options)
      assert(p == actor and #options.choices == 2)
      return self.chooseNegate and options.choices[1] or options.choices[2]
    end,
  }
  actor.room, target.room, bystander.room = room, room, room
  currentRoom, lordSkill, localChoice = room, false, 0
  return actor, target, bystander, room
end

local function slash(actor, target)
  return setmetatable({ from = actor, to = target,
    card = { trueName = "slash" },
  }, { __index = env.UseCardData })
end

local function same(actual, expected)
  assert(#actual == #expected, "expected " .. #expected .. " items, received " .. #actual)
  for i, target in ipairs(expected) do assert(actual[i] == target, "wrong item at " .. i) end
end

local total, tieqiCases, zhenteCases = 0, 0, 0
local function check(label, action, kind)
  local ok, message = pcall(action)
  assert(ok, label .. ": " .. tostring(message))
  total = total + 1
  if kind == "tieqi" then tieqiCases = tieqiCases + 1 else zhenteCases = zhenteCases + 1 end
end

for _, skill in ipairs({std, power}) do
  local effect = assert(skill.effects.target_specified)
  local invalidity = assert(skill.effects.invalidity).invalidity_func
  local prefix = skill.name .. ": "

  check(prefix .. "slash owner trigger and negative guards", function()
    local actor, target, _, room = setup(skill)
    local data = slash(actor, target)
    assert(effect.can_trigger(effect, nil, actor, actor, data))
    assert(not effect.can_trigger(effect, nil, target, actor, data))
    assert(not effect.can_trigger(effect, nil, actor, target, data))
    assert(not effect.can_trigger(effect, nil, actor, actor, {card={trueName="duel"}}))
    actor.skill = "none"
    assert(not effect.can_trigger(effect, nil, actor, actor, data))
  end, "tieqi")

  check(prefix .. "failed discard blocks only specified target, dedupes", function()
    local actor, target, bystander, room = setup(skill)
    local data = slash(actor, target)
    data.disresponsiveList = { bystander }
    effect.on_use(effect, nil, actor, actor, data)
    effect.on_use(effect, nil, actor, actor, data)
    same(data.disresponsiveList, { bystander, target })
    assert(room.judgeCalls == 2 and room.discardCalls == 2)
    assert(localChoice == 2)
    same(target:getTableMark("@hs__tieqi-turn"), { "main" })
    same(target:getTableMark("_hs__tieqi-turn"), { "normal_main" })
    assert(invalidity(nil, target, env.Fk.skills.normal_main))
    assert(not invalidity(nil, target, env.Fk.skills.compulsory_main))
    assert(not invalidity(nil, target, env.Fk.skills.unrelated))
  end, "tieqi")

  check(prefix .. "matched suit discard preserves response", function()
    local actor, target, _, room = setup(skill)
    room.discard = { 123 }
    local data = slash(actor, target)
    effect.on_use(effect, nil, actor, actor, data)
    assert(data.disresponsiveList == nil and room.discardCalls == 1)
    same(target:getTableMark("_hs__tieqi-turn"), { "normal_main" })
  end, "tieqi")

  check(prefix .. "NoSuit judgment skips discard/response suppression", function()
    local actor, target, _, room = setup(skill)
    room.judgeSuit = env.Card.NoSuit
    local data = slash(actor, target)
    effect.on_use(effect, nil, actor, actor, data)
    assert(room.judgeCalls == 1 and room.discardCalls == 0)
    assert(data.disresponsiveList == nil)
  end, "tieqi")

  check(prefix .. "shouyue applies both visible generals and skills", function()
    local actor, target, _, room = setup(skill)
    lordSkill = true
    local data = slash(actor, target)
    effect.on_use(effect, nil, actor, actor, data)
    assert(localChoice == 0 and room.marksSet == 2)
    same(target:getTableMark("@hs__tieqi-turn"), {"main", "deputy"})
    same(target:getTableMark("_hs__tieqi-turn"), {"normal_main", "normal_deputy"})
    assert(invalidity(nil, target, env.Fk.skills.normal_deputy))
  end, "tieqi")

  check(prefix .. "hidden generals still judge and can suppress response", function()
    local actor, target, _, room = setup(skill)
    target.general, target.deputyGeneral = "anjiang", "anjiang"
    local data = slash(actor, target)
    effect.on_use(effect, nil, actor, actor, data)
    assert(localChoice == 0 and room.marksSet == 0)
    assert(room.judgeCalls == 1)
    same(data.disresponsiveList, {target})
  end, "tieqi")

  check(prefix .. "dead owner has no side effects", function()
    local actor, target, _, room = setup(skill)
    actor.dead = true
    local data = slash(actor, target)
    effect.on_use(effect, nil, actor, actor, data)
    assert(room.judgeCalls == 0 and room.marksSet == 0 and room.discardCalls == 0)
    assert(data.disresponsiveList == nil)
  end, "tieqi")

  check(prefix .. "turn mark reset ends invalidity", function()
    local actor, target, _, room = setup(skill)
    effect.on_use(effect, nil, actor, actor, slash(actor, target))
    assert(invalidity(nil, target, env.Fk.skills.normal_main))
    target.marks["_hs__tieqi-turn"] = nil
    assert(not invalidity(nil, target, env.Fk.skills.normal_main))
  end, "tieqi")
end

local effect = assert(zhente.effects.target_confirmed)
local forbid = assert(zhente.effects.prohibit).prohibit_use

local function blackCard(cardType, common, color)
  color = color or "black"
  return {
    type = cardType or env.Card.TypeBasic, color = color,
    name = "slash",
    isCommonTrick = function() return common == true end,
    getColorString = function(self) return self.color end,
    toLogString = function() return "slash" end,
  }
end

local function zhenteState(card)
  local attacker, defender, other, room = setup(zhente)
  defender.skill = zhente.name
  local data = setmetatable({ from = attacker, to = defender, card = card or blackCard(),
    use = { nullifiedTargets = nil } }, { __index = env.AimData })
  return attacker, defender, other, room, data
end

check("zhente black basic/common trick and owner once-per-turn guards", function()
  local attacker, defender, _, room, data = zhenteState()
  assert(effect.can_trigger(effect, nil, defender, defender, data))
  assert(not effect.can_trigger(effect, nil, attacker, defender, data))
  defender.used = 1
  assert(not effect.can_trigger(effect, nil, defender, defender, data))
  defender.used = 0
  defender.skill = "none"
  assert(not effect.can_trigger(effect, nil, defender, defender, data))
  defender.skill = zhente.name
  data.from = defender
  assert(not effect.can_trigger(effect, nil, defender, defender, data))
  data.from = attacker
  data.card = blackCard("trick", true)
  assert(effect.can_trigger(effect, nil, defender, defender, data))
  data.card = blackCard("trick", false)
  assert(not effect.can_trigger(effect, nil, defender, defender, data))
  data.card = blackCard("basic", false, "red")
  assert(not effect.can_trigger(effect, nil, defender, defender, data))
end, "zhente")

check("zhente on_cost accepts/cancels invocation and records attacking target", function()
  local attacker, defender, _, room, data = zhenteState()
  local saved
  local event = { setCostData = function(_, _, value) saved = value end }
  room.invoke = false
  assert(not effect.on_cost(effect, event, defender, defender, data) and saved == nil)
  room.invoke = true
  assert(effect.on_cost(effect, event, defender, defender, data))
  same(saved.tos, {attacker})
end, "zhente")

check("zhente negate nullifies defender only using real AimData helper", function()
  local attacker, defender, other, room, data = zhenteState()
  room.chooseNegate = true
  effect.on_use(effect, nil, defender, defender, data)
  same(data.use.nullifiedTargets, {defender})
  assert(not libs.contains(data.use.nullifiedTargets, attacker))
  assert(not libs.contains(data.use.nullifiedTargets, other))
  assert(attacker:getMark("@ty_heg__zhente-turn") == 0)
end, "zhente")

check("zhente colorlimit persists as table mark and prohibits only matching color", function()
  local attacker, defender, _, room, data = zhenteState()
  room.chooseNegate = false
  effect.on_use(effect, nil, defender, defender, data)
  same(attacker:getTableMark("@ty_heg__zhente-turn"), {"black"})
  assert(data.use.nullifiedTargets == nil)
  assert(forbid(nil, attacker, blackCard("basic", false, "black")))
  assert(not forbid(nil, attacker, blackCard("basic", false, "red")))
  assert(not forbid(nil, defender, blackCard("basic", false, "black")))
  assert(not forbid(nil, attacker, nil))
end, "zhente")

check("zhente mark records matching color once across repeated helper calls", function()
  local attacker, defender, _, room, data = zhenteState()
  room.chooseNegate = false
  effect.on_use(effect, nil, defender, defender, data)
  effect.on_use(effect, nil, defender, defender, data)
  same(attacker:getTableMark("@ty_heg__zhente-turn"), {"black"})
end, "zhente")

check("zhente turn-mark expiry restores card color eligibility", function()
  local attacker, defender, _, room, data = zhenteState()
  room.chooseNegate = false
  effect.on_use(effect, nil, defender, defender, data)
  assert(forbid(nil, attacker, blackCard()))
  attacker.marks["@ty_heg__zhente-turn"] = nil
  assert(not forbid(nil, attacker, blackCard()))
end, "zhente")

print(string.format("PASS tieqi real upstream callbacks: %d cases (2 variants)", tieqiCases))
print(string.format("PASS zhente real upstream callbacks: %d cases", zhenteCases))
print(string.format("PASS total source-level probes: %d; native/browser NOT RUN", total))
