-- Exercise the actual isolated candidate ServerRoomBase wire methods. This
-- confirms Lua routing/projection only, not an authenticated native session.
-- Output stays metadata-only: never print concealed marks or card identifiers.
local root = assert(..., "candidate core root required")
local function source(relative)
  local file = assert(io.open(root .. "/" .. relative, "rb"))
  local value = assert(file:read("*a"))
  file:close()
  return value
end
local lua = source("lua/server/roombase.lua")
local function deepCopy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, nested in pairs(value) do result[key] = deepCopy(nested) end
  return result
end
local events = {}
local function recipient(name)
  local object = { events = {} }
  function object:getState() return "connected" end
  function object:doNotify(command, payload)
    table.insert(self.events, { command = command, payload = deepCopy(payload) })
  end
  return object
end
local ownerPhysical = recipient("owner")
local opposingPhysical = recipient("opponent")
local watcherPhysical = recipient("spectator")
local owner = { id = 11, mark = { __heg_general = "private_main", __heg_deputy = "private_deputy",
  __heg_kingdom = "private_faction", HalfMaxHpLeft = 1, CompanionEffect = 1,
  ["@public"] = 2 }, _splayer = ownerPhysical,
  role = "private_faction", role_shown = false, general = "private_main",
  deputyGeneral = "private_deputy", gender = 1, kingdom = "private_faction" }
local opponent = { id = 12, mark = { __heg_general = "other_private",
  HalfMaxHpLeft = 1, CompanionEffect = 1, ["@public"] = 3 },
  _splayer = opposingPhysical, role = "other_faction", role_shown = false,
  general = "other_private", deputyGeneral = "anjiang", gender = 2,
  kingdom = "other_faction" }
for _, seat in ipairs({ owner, opponent }) do
  function seat:setMark(name, value) self.mark[name] = value end
  function seat:serialize()
    return { mark = deepCopy(self.mark), properties = {
      role = self.role, general = self.general, deputyGeneral = self.deputyGeneral,
      gender = self.gender, kingdom = self.kingdom, role_shown = self.role_shown,
    }, fake_skills = { "private_fake" },
      prelighted_skills = { "private_prelight" } }
  end
end
local server = {}
local realRoom = setmetatable({}, { __index = server })
local env = setmetatable({
  fk = { Player_Robot = "robot", qInfo = function() end },
  Fk = { generals = { anjiang = { gender = 4, kingdom = "unknown" } } },
  cbor = { encode = deepCopy, decode = deepCopy },
  ServerRoomBase = server,
  Room = realRoom,
  os = { getms = function() return 1000 end, time = function() return 100 end },
  table = setmetatable({ clone = deepCopy }, { __index = table }),
}, { __index = _G })

local function executeDefinition(signature)
  local begin = assert(lua:find(signature, 1, true), "missing upstream definition")
  local finish = assert(lua:find("\nend\n", begin, true), "missing function boundary")
  assert(load(lua:sub(begin, finish + 4), "=candidate/source", "t", env))()
end
executeDefinition("function ServerRoomBase:doBroadcastNotify(command, jsonData, players)")
-- The existing legacy probe extracts individual real methods. Once owner-only
-- sends use a helper, load that helper too to keep exercising the same source.
executeDefinition("function ServerRoomBase:notifyPrivatePhysical(seat, physical, command, data)")
executeDefinition("function ServerRoomBase:publicHegemonyRole(role, shown)")
executeDefinition("function ServerRoomBase:notifyProperty(p, player, property)")
executeDefinition("function ServerRoomBase:setPlayerMark(player, mark, value)")
executeDefinition(lua:find("function ServerRoomBase:serialize(player, observer)", 1, true)
  and "function ServerRoomBase:serialize(player, observer)"
  or "function ServerRoomBase:serialize(player)")
executeDefinition("function ServerRoomBase:tellRoomToObserver(player)")
local roomLua = source("ltk/server/room.lua")
local function executeRoomDefinition(signature)
  local begin = assert(roomLua:find(signature, 1, true), "missing core room method")
  local finish = assert(roomLua:find("\nend\n", begin, true), "missing room method boundary")
  assert(load(roomLua:sub(begin, finish + 4), "=candidate/room", "t", env))()
end
executeRoomDefinition("function Room:serialize(player, observer)")

local room = setmetatable({
  settings = { gameMode = "new_heg_mode" }, players = { owner, opponent },
  observers = {}, start_time = nil, id = 900,
  room = { getOwner = function() return { getId = function() return 11 end } end },
  class = { super = {
    serialize = function(self)
      return { players = { [11] = owner:serialize(), [12] = opponent:serialize() },
        settings = self.settings, circle = { 11, 12 } }
    end,
  } },
}, { __index = realRoom })
function room:getSettings(key) return self.settings[key] end
function room:getBanner() return nil end
function owner:doNotify(command, payload)
  ownerPhysical:doNotify(command, payload)
  watcherPhysical:doNotify(command, payload)
end
function opponent:doNotify(command, payload)
  opposingPhysical:doNotify(command, payload)
  watcherPhysical:doNotify(command, payload)
end

-- Private incremental marks must reach the real owner only, avoiding both
-- other seats and followers of the owner's observer route.
room:setPlayerMark(owner, "__heg_general", "private_updated")
room:setPlayerMark(owner, "__heg_kingdom", "private_updated")
room:setPlayerMark(owner, "InitialGeneral", { "private_updated", "private_deputy" })
room:setPlayerMark(owner, "ExtraAttachedSkills", { "private_skill" })
room:setPlayerMark(owner, "HalfMaxHpLeft", 1)
room:setPlayerMark(owner, "CompanionEffect", 1)
room:setPlayerMark(opponent, "HalfMaxHpLeft", 1)
room:setPlayerMark(opponent, "CompanionEffect", 1)
assert(#ownerPhysical.events == 6 and #opposingPhysical.events == 2
  and #watcherPhysical.events == 0, "private mark leaked via broadcast or observer")
room:setPlayerMark(owner, "@public", 9)
assert(#ownerPhysical.events == 7 and #opposingPhysical.events == 3
  and #watcherPhysical.events == 2, "public marks must still broadcast")
assert(owner.mark.__heg_general == "private_updated", "server mark mutated unexpectedly")

-- The real Hegemony role is private, including after role_shown changes.
-- Owner-only property delivery must not enter its spectator forwarding path.
local function countRecipientCommands(peer, cmd)
  local count = 0
  for _, packet in ipairs(peer.events) do
    if packet.command == cmd then count = count + 1 end
  end
  return count
end
local ownerPropertyStart = countRecipientCommands(ownerPhysical, "PropertyUpdate")
local otherPropertyStart = countRecipientCommands(opposingPhysical, "PropertyUpdate")
local watcherPropertyStart = countRecipientCommands(watcherPhysical, "PropertyUpdate")
for _, key in ipairs({ "role", "general", "deputyGeneral", "kingdom", "gender" }) do
  room:notifyProperty(owner, owner, key)
end
assert(countRecipientCommands(ownerPhysical, "PropertyUpdate") == ownerPropertyStart + 5,
  "concealed owner properties were not delivered")
assert(countRecipientCommands(watcherPhysical, "PropertyUpdate") == watcherPropertyStart,
  "concealed owner property forwarded to spectator")
room:notifyProperty(opponent, owner, "role")
assert(countRecipientCommands(opposingPhysical, "PropertyUpdate") == otherPropertyStart + 1,
  "nonowner did not receive public role")
assert(opposingPhysical.events[#opposingPhysical.events].payload[3] == "hidden",
  "nonowner received real role")
assert(watcherPhysical.events[#watcherPhysical.events].payload[3] == "hidden",
  "spectator received real role")

-- A broadcastProperty call can target a concealed owner while the source
-- still holds the real pair/gender/faction. Nonowners must receive the same
-- placeholders as reconnect snapshots, never the server-side values.
local concealedPublic = {
  general = "anjiang", deputyGeneral = "anjiang",
  kingdom = "unknown", gender = 4,
}
for _, key in ipairs({ "general", "deputyGeneral", "kingdom", "gender" }) do
  room:notifyProperty(opponent, owner, key)
  local opposing = opposingPhysical.events[#opposingPhysical.events]
  local watcher = watcherPhysical.events[#watcherPhysical.events]
  assert(opposing.command == "PropertyUpdate" and opposing.payload[3] == concealedPublic[key],
    "nonowner received concealed property")
  assert(watcher.command == "PropertyUpdate" and watcher.payload[3] == concealedPublic[key],
    "spectator received concealed property")
end

-- A reconnect/observer can coincide with the real-choice intermediate state,
-- before the mode swaps the chosen pair back to anjiang.
local duringChoice = room:serialize(opponent)
assert(duringChoice.players[11].properties.general == "anjiang"
  and duringChoice.players[11].properties.deputyGeneral == "anjiang"
  and duringChoice.players[11].properties.kingdom == "unknown"
  and duringChoice.players[11].properties.gender == 4,
  "reconnect revealed a concealed pair's interim identity or gender")

owner.general, owner.role_shown = "public_main", true
room:notifyProperty(owner, owner, "general")
assert(countRecipientCommands(watcherPhysical, "PropertyUpdate") == watcherPropertyStart + 6,
  "publicly revealed identity did not reach spectator")
local revealed = room:serialize(opponent)
assert(revealed.players[11].properties.general == "public_main"
  and revealed.players[11].properties.role == "hidden",
  "public general reveal or private faction snapshot was changed")
assert(revealed.players[11].mark.HalfMaxHpLeft == nil
  and revealed.players[11].mark.CompanionEffect == nil,
  "public general reveal exposed unrevealed paired-general effects")
owner.role = "private_faction"
room:notifyProperty(owner, owner, "role")
assert(countRecipientCommands(watcherPhysical, "PropertyUpdate") == watcherPropertyStart + 6,
  "private faction role forwarded after public general reveal")
owner.general, owner.deputyGeneral, owner.role_shown = "anjiang", "anjiang", false
owner.gender, owner.kingdom = 4, "unknown"
for _, field in ipairs({ "general", "gender", "kingdom" }) do
  room:notifyProperty(owner, owner, field)
end
assert(countRecipientCommands(watcherPhysical, "PropertyUpdate") == watcherPropertyStart + 9,
  "public concealed-slot properties must reach attached spectator")

-- Reconnect gets owner's own marks but no other player's private identity,
-- fake or prelighted skills. A public mark survives for both seats.
local ownSummary = room:serialize(owner)
assert(ownSummary.you == owner.id, "owner reconnect identity missing")
assert(ownSummary.players[11].mark.__heg_general == "private_updated", "owner mark lost")
assert(ownSummary.players[12].mark.__heg_general == nil, "other hidden mark in reconnect")
assert(ownSummary.players[11].mark.HalfMaxHpLeft == 1
  and ownSummary.players[11].mark.CompanionEffect == 1,
  "owner reconnect lost paired-general effect metadata")
assert(ownSummary.players[12].mark.HalfMaxHpLeft == nil
  and ownSummary.players[12].mark.CompanionEffect == nil,
  "opponent paired-general metadata leaked on reconnect")
assert(ownSummary.players[12].properties.role == "hidden", "other real role leaked on reconnect")
assert(ownSummary.players[11].properties.role == "private_faction", "owner lost real role")
assert(ownSummary.players[12].mark["@public"] == 3, "public mark missing")
assert(#ownSummary.players[12].fake_skills == 0
  and #ownSummary.players[12].prelighted_skills == 0, "other concealed skills leaked")

local observer = recipient("observer")
function observer:getScreenName() return "observer" end
function observer:getAvatar() return "avatar" end
function observer:getTotalGameTime() return 0 end
function observer:getId() return 13 end
room:tellRoomToObserver(observer)
local summary
for _, entry in ipairs(observer.events) do
  if entry.command == "Observe" then summary = entry.payload end
end
assert(summary and summary.you == owner.id and summary.settings.isObserver,
  "observer must retain viewpoint and observer mode")
assert(summary.players[11].mark.__heg_general == nil
  and summary.players[12].mark.__heg_general == nil, "observer received concealed general")
assert(summary.players[11].mark.__heg_kingdom == nil
  and #summary.players[11].fake_skills == 0, "observer received concealed metadata")
assert(summary.players[11].mark.HalfMaxHpLeft == nil
  and summary.players[11].mark.CompanionEffect == nil
  and summary.players[12].mark.HalfMaxHpLeft == nil
  and summary.players[12].mark.CompanionEffect == nil,
  "observer received paired-general effects")
assert(summary.players[11].properties.role == "hidden"
  and summary.players[12].properties.role == "hidden", "observer received real faction role")
assert(summary.players[12].properties.general == "anjiang"
  and summary.players[12].properties.kingdom == "unknown",
  "observer received opposing pair metadata")
assert(owner.mark.__heg_general == "private_updated", "snapshot projected into live state")
room.game_finished = true
local ended = room:serialize(nil, true)
assert(ended.players[12].properties.role == "other_faction",
  "game over snapshot lost final role")
room.game_finished = nil

room.settings.gameMode = "other_mode"
room:setPlayerMark(owner, "__heg_general", "other_mode_value")
room:setPlayerMark(owner, "CompanionEffect", 1)
assert(#opposingPhysical.events == 10, "non-hegemony behavior was altered")
room:notifyProperty(owner, owner, "role")
assert(countRecipientCommands(watcherPhysical, "PropertyUpdate") == watcherPropertyStart + 10,
  "non-hegemony property update was altered")

-- Execute the actual core Room:setPlayerGeneral with source-level mock.
-- The target Hegemony chooseGenerals must opt into the noBroadcast branch.
local fakeGeneralEnv = setmetatable({
  Room = realRoom,
  Fk = { generals = { private_main = { gender = 2, kingdom = "secret" },
    anjiang = { gender = 4, kingdom = "unknown" } } },
}, { __index = _G })
local begin = assert(roomLua:find("function Room:setPlayerGeneral(player, general, changeKingdom, noBroadcast)", 1, true))
local finish = assert(roomLua:find("\nend\n", begin, true))
assert(load(roomLua:sub(begin, finish + 4), "=candidate/room", "t", fakeGeneralEnv))()
local notifications = {}
local sampleRoom = setmetatable({}, { __index = realRoom })
function sampleRoom:notifyProperty(_, _, field)
  notifications[#notifications + 1] = { audience = "owner", field = field }
end
function sampleRoom:broadcastProperty(_, field)
  notifications[#notifications + 1] = { audience = "all", field = field }
end
local testSeat = {}
sampleRoom:setPlayerGeneral(testSeat, "private_main", true, true)
assert(#notifications == 3, "concealed general should send three owner properties")
for _, entry in ipairs(notifications) do
  assert(entry.audience == "owner", "concealed general gender/kingdom broadcast")
end
notifications = {}
sampleRoom:setPlayerGeneral(testSeat, "anjiang", true)
assert(#notifications == 3 and notifications[2].audience == "all"
  and notifications[3].audience == "all", "public anjiang properties must broadcast")
local hegemonyFile = assert(io.open(root .. "/../hegemony/pkg/gamemodes/new_hegemony_mode.lua", "rb"))
local hegemonyMode = assert(hegemonyFile:read("*a"))
hegemonyFile:close()
assert(hegemonyMode:find("room:setPlayerGeneral(player, general, true, true)", 1, true),
  "Hegemony initial choice must explicitly request concealed setup")
for _, relative in ipairs({ "pkg/gamemodes/new_hegemony_mode.lua", "util.lua",
    "utilevent/events/remove_general.lua" }) do
  local file = assert(io.open(root .. "/../hegemony/" .. relative, "rb"))
  local content = assert(file:read("*a"))
  file:close()
  for _, mark in ipairs({ "HalfMaxHpLeft", "CompanionEffect" }) do
    assert(not content:find(':doNotify("SetPlayerMark", { player.id, "' .. mark .. '"', 1, true)
      and not content:find(':doNotify("SetPlayerMark", { p.id, "' .. mark .. '"', 1, true),
      "Hegemony writer bypassed canonical private mark route")
  end
end

-- Exercise real ServerPlayer fake-skill methods. This models both the attached
-- watcher forwarding path and the physical owner wire. Hidden skill names must
-- reach the owner at setup and reconnect, including prelight and removal.
local playerLua = source("ltk/server/serverplayer.lua")
local skillClass = {}
local privateSkill = { name = "private_fake", related_skills = {} }
function privateSkill:isInstanceOf(class) return class == skillClass end
local fakeTable = setmetatable({
  contains = function(values, expected)
    for _, value in ipairs(values) do if value == expected then return true end end
    return false
  end,
  insertIfNeed = function(values, value)
    for _, current in ipairs(values) do if current == value then return end end
    table.insert(values, value)
  end,
  removeOne = function(values, value)
    for i, current in ipairs(values) do
      if current == value then table.remove(values, i); return end
    end
  end,
}, { __index = table })
local playerMethods = {}
local skillEnv = setmetatable({
  ServerPlayer = playerMethods,
  Player = {
    addFakeSkill = function(_, skill) return skill end,
    loseFakeSkill = function(_, skill) return skill end,
  },
  Skill = skillClass,
  Fk = { skills = { private_fake = privateSkill } },
  fk = { Player_Robot = "robot" },
  cbor = { encode = deepCopy },
  table = fakeTable,
}, { __index = _G })
local function executePlayerDefinition(signature)
  local first = assert(playerLua:find(signature, 1, true), "missing real player skill method")
  local last = assert(playerLua:find("\nend\n", first, true), "missing player method boundary")
  assert(load(playerLua:sub(first, last + 4), "=candidate/serverplayer", "t", skillEnv))()
end
for _, signature in ipairs({
  "function ServerPlayer:notifyConcealedSkillOwner(command, data)",
  "function ServerPlayer:syncFakeSkills()",
  "function ServerPlayer:syncFakeSkillsTo(observer)",
  "function ServerPlayer:addFakeSkill(skill)",
  "function ServerPlayer:loseFakeSkill(skill)",
  "function ServerPlayer:prelightSkill(skill, isPrelight)",
}) do executePlayerDefinition(signature) end

local skillRoom = { gameMode = "new_heg_mode", added = 0 }
function skillRoom:getSettings(key) return key == "gameMode" and self.gameMode end
function skillRoom:addSkill() self.added = self.added + 1 end
local seat = setmetatable({ id = owner.id, _splayer = ownerPhysical,
  room = skillRoom, _manually_fake_skills = {}, prelighted_skills = {},
  _prelighted_skills = {} }, { __index = playerMethods })
function seat:doNotify(command, payload)
  ownerPhysical:doNotify(command, payload)
  watcherPhysical:doNotify(command, payload)
end
function seat:hasSkill() return false end
local ownerStart, watcherStart = #ownerPhysical.events, #watcherPhysical.events
local opposingStart = #opposingPhysical.events
seat:addFakeSkill(privateSkill)
seat:prelightSkill(privateSkill, true)
seat:syncFakeSkills() -- same owner skill refresh used after reconnect
seat:syncFakeSkillsTo(watcherPhysical) -- setting may enable observer fake view
seat:loseFakeSkill(privateSkill)
seat:prelightSkill(privateSkill, false)
assert(#ownerPhysical.events == ownerStart + 6, "owner lost concealed fake/prelight notifications")
assert(#watcherPhysical.events == watcherStart and #opposingPhysical.events == opposingStart,
  "hidden fake/prelight skill leaked to watcher or opponent")
assert(skillRoom.added == 1, "prelight source did not attach the skill once")

-- Other modes retain their existing fake skill incremental and observer sync.
skillRoom.gameMode = "other_mode"
seat:addFakeSkill(privateSkill)
seat:prelightSkill(privateSkill, true)
seat:syncFakeSkillsTo(watcherPhysical)
seat:loseFakeSkill(privateSkill)
assert(#watcherPhysical.events == watcherStart + 5,
  "non-Hegemony fake skill observer delivery was changed")
assert(#ownerPhysical.events == ownerStart + 9,
  "non-Hegemony owner fake/prelight notifications were changed")
print("PASS actual Lua private-wire incremental: 9; property projection: 11; reconnect projection: 10; observe: 8; other-mode: 3; initial setup: 4; fake-skill route: 11; native/browser NOT RUN")
