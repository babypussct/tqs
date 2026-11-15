-- Checks the actual candidate Hegemony utility function bodies and the
-- event-based removeGeneral override without booting a native room.
-- Usage: lua hegemony-util-source-probe.lua <candidate/packages/hegemony>
-- This is isolated Lua callback evidence, not native/game/browser acceptance.

local root = assert(..., "expected isolated candidate Hegemony package directory")
local function source(relative)
  local f = assert(io.open(root .. "/" .. relative, "rb"))
  local content = assert(f:read("*a"))
  f:close()
  return content
end

local util = source("util.lua")
local dispatcher = source("utilevent/core/remove_general.lua")
local loader = source("utilevent/init.lua")
local event = source("utilevent/events/remove_general.lua")

local function position(haystack, needle)
  return assert(haystack:find(needle, 1, true), "missing source fragment: " .. needle)
end

-- The legacy method in util.lua is deliberately replaced when the actual
-- utility module loads the event implementation. A definition check alone
-- would incorrectly approve the legacy path.
assert(position(util, "function HegUtil.removeGeneral(player, isDeputy)")
  < position(util, "dofile 'packages/hegemony/utilevent/init.lua'"))
assert(position(loader, 'dofile "packages/hegemony/utilevent/core/remove_general.lua"') > 0)
assert(position(dispatcher, "function HegUtil.removeGeneral(player, isDeputy)") > 0)
assert(position(dispatcher, 'HegUtil.GameEvent.RemoveGeneral = RemoveGeneral') > 0)
assert(position(event, "function RemoveGeneral:main()") > 0)

local function contains(values, wanted)
  for _, value in ipairs(values) do if value == wanted then return true end end
  return false
end
local fixtureTable = setmetatable({
  contains = contains,
  map = function(values, fn)
    local mapped = {}
    for i, value in ipairs(values) do mapped[i] = fn(value) end
    return mapped
  end,
}, { __index = table })

local generals = {
  main_male = { gender = 1, getSkillNameList = function() return { "main_skill", "shared_skill" } end },
  deputy_female = { gender = 2, getSkillNameList = function() return { "deputy_skill", "shared_skill" } end },
}
local HegUtil = { GeneralRemoving = {}, GeneralRemoved = {}, GameEvent = {} }
local RemoveGeneral = {}
local env = setmetatable({
  HegUtil = HegUtil,
  RemoveGeneral = RemoveGeneral,
  Fk = { generals = generals },
  General = { Male = 1 },
  Skill = {},
  table = fixtureTable,
}, { __index = _G })

-- Extract top-level definitions verbatim from the selected candidate files.
-- Nested Lua end tokens are indented; the first unindented end closes the
-- desired top-level function. Fail if source layout changes.
local function executeDefinition(content, signature)
  local start = position(content, signature)
  local finish = assert(content:find("\nend\n", start, true), "no top-level end for " .. signature)
  local chunk = content:sub(start, finish + 4)
  assert(load(chunk, signature, "t", env))()
end

executeDefinition(util, "function HegUtil.getActualGeneral(player, isDeputy)")
executeDefinition(util, "function HegUtil.inGeneralSkills(player, skill)")

local function player(main, deputy)
  return {
    general = main,
    deputyGeneral = deputy,
    getMark = function(_, mark)
      if mark == "__heg_general" then return "main_male" end
      if mark == "__heg_deputy" then return "deputy_female" end
      error("unexpected mark " .. mark)
    end,
  }
end

local ownership = {
  { "both hidden main", player("anjiang", "anjiang"), "main_skill", "m" },
  { "both hidden deputy", player("anjiang", "anjiang"), "deputy_skill", "d" },
  { "both hidden precedence", player("anjiang", "anjiang"), "shared_skill", "m" },
  { "visible main hidden deputy", player("main_male", "anjiang"), "deputy_skill", "d" },
  { "hidden main visible deputy", player("anjiang", "deputy_female"), "main_skill", "m" },
  { "not owned", player("anjiang", "anjiang"), "unowned_skill", nil },
  { "no deputy", player("main_male", ""), "deputy_skill", nil },
}
for _, case in ipairs(ownership) do
  local actual = HegUtil.inGeneralSkills(case[2], case[3])
  assert(actual == case[4], case[1] .. ": wrong slot for concealed skill")
end

-- Verify the dispatcher after the actual override takes effect: it creates
-- GeneralRemoveData and runs the RemoveGeneral event for either slot.
local dispatched = 0
HegUtil.GeneralRemoveData = {
  new = function(_, data) return data end,
}
HegUtil.GameEvent.RemoveGeneral = {
  create = function(_, data)
    return {
      exec = function()
        dispatched = dispatched + 1
        assert(data.who == ownership[1][2])
        assert(data.isDeputy == (dispatched == 2))
        return true, "event-result"
      end,
    }
  end,
}
executeDefinition(dispatcher, "function HegUtil.removeGeneral(player, isDeputy)")
assert(HegUtil.removeGeneral(ownership[1][2], false) == "event-result")
assert(HegUtil.removeGeneral(ownership[1][2], true) == "event-result")
assert(dispatched == 2, "removeGeneral did not dispatch the event")

-- Execute the real RemoveGeneral:main() body with a minimal room implementation.
-- This catches lost skill removal, wrong slot/gender, missing pile return and
-- incorrect handling of a slot that was already removed.
string.startsWith = function(self, prefix) return self:sub(1, #prefix) == prefix end
executeDefinition(event, "function RemoveGeneral:main()")
local function removal(isDeputy, alreadyBlank)
  local log = { skillLosses = {}, notifications = {}, triggers = {}, pile = {}, clearedPrivateMarks = {} }
  local p = player("anjiang", "anjiang")
  p.id = 7
  p.gender = 1
  p.revealGeneral = function(self, deputy, forced)
    assert(deputy == isDeputy and forced == true)
    if deputy then self.deputyGeneral = alreadyBlank and "blank_shibing" or "deputy_female"
    else self.general = alreadyBlank and "blank_shibing" or "main_male" end
  end
  p.setMark = function() error("RemoveGeneral must route its marks via room:setPlayerMark") end
  p.doNotify = function(_, _, payload) log.notifications[#log.notifications + 1] = payload end
  p.filterHandcards = function() log.filtered = true end
  local room = {
    logic = {
      trigger = function(_, kind, owner)
        assert(owner == p)
        log.triggers[#log.triggers + 1] = kind
        return false
      end,
    },
    setPlayerProperty = function(_, target, prop, value)
      assert(target == p)
      log.property, log.value = prop, value
      target[prop] = value
    end,
    setPlayerMark = function(_, target, mark, value)
      assert(target == p)
      if mark == "CompanionEffect" or mark == "HalfMaxHpLeft" then
        assert(value == 0)
        log.clearedPrivateMarks[#log.clearedPrivateMarks + 1] = mark
        log[mark] = value
      else
        log.mark, log.markValue = mark, value
      end
    end,
    handleAddLoseSkills = function(_, target, loss)
      assert(target == p)
      log.skillLosses[#log.skillLosses + 1] = loss
    end,
    sendLog = function(_, data) log.message = data end,
    returnToGeneralPile = function(_, cards) log.pile = cards end,
  }
  local payload = { who = p, isDeputy = isDeputy }
  local result = RemoveGeneral.main({ room = room, data = payload })
  assert(log.CompanionEffect == 0 and log.HalfMaxHpLeft == 0)
  assert(#log.clearedPrivateMarks == 2
    and log.clearedPrivateMarks[1] == "CompanionEffect"
    and log.clearedPrivateMarks[2] == "HalfMaxHpLeft")
  assert(#log.notifications == 0, "RemoveGeneral bypassed mark privacy guard")
  if alreadyBlank then
    assert(result == false and #log.skillLosses == 0 and #log.triggers == 0)
    return
  end
  local name = isDeputy and "deputy_female" or "main_male"
  local blank = isDeputy and "blank_nvshibing" or "blank_shibing"
  local property = isDeputy and "deputyGeneral" or "general"
  local mark = isDeputy and "__heg_deputy" or "__heg_general"
  assert(payload.origName == name)
  assert(log.property == property and log.value == blank)
  assert(log.mark == mark and log.markValue == blank)
  assert(log.filtered and log.message.arg2 == name and log.pile[1] == name)
  assert(#log.triggers == 2 and log.triggers[1] == HegUtil.GeneralRemoving
    and log.triggers[2] == HegUtil.GeneralRemoved)
  local skills = isDeputy and "-deputy_skill|-shared_skill" or "-main_skill|-shared_skill"
  assert(#log.skillLosses == 1 and log.skillLosses[1] == skills)
end

removal(false, false)
removal(true, false)
removal(false, true)
print("PASS Hegemony merged util source: 7 hidden-owner, 2 dispatch, 3 remove-event cases; native/browser NOT RUN")
