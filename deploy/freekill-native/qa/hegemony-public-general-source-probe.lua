-- Exercise the shipped reveal, property change, per-recipient dispatch and
-- snapshot methods with synthetic identities and physical socket fixtures.
local root = assert(arg[1])
local function read(relative)
  local file = assert(io.open(root .. "/" .. relative, "rb"))
  local data = file:read("a")
  file:close()
  return data
end
local function definition(source, signature)
  local first = assert(source:find(signature, 1, true), signature)
  local last = assert(source:find("\nend\n", first, true), signature)
  return source:sub(first, last + 4)
end

local roomSource = read("freekill-core/lua/server/roombase.lua")
local heroSource = read("freekill-core/ltk/server/events/misc.lua")
local playerSource = read("freekill-core/ltk/server/serverplayer.lua")
local ruleSource = read("hegemony/pkg/gamemodes/skills/hegemony_rule.lua")
local emptyMarkCbor = "fixture:empty-marks"
local function encode(value)
  if type(value) == "table" and next(value) == nil then return emptyMarkCbor end
  return value
end
local function decode(value)
  if value == emptyMarkCbor then return {} end
  return value
end
local projection = assert(load(read("freekill-core/lua/server/card_wire_projection.lua"),
  "projection", "t", setmetatable({cbor = {encode = encode, decode = decode}}, {__index = _G})))()
local empty = function() return {} end
local function contains(list, wanted)
  for _, value in ipairs(list) do if value == wanted then return true end end
  return false
end
local generals = {
  anjiang = {gender = 4, kingdom = "unknown", getSkillNameList = empty},
  fixture_main = {gender = 1, kingdom = "wei", getSkillNameList = empty},
  fixture_deputy = {gender = 1, kingdom = "wei", getSkillNameList = empty},
}
Fk = {generals = generals}

local function reproduce(version, firstDeputy)
  local room = {card_wire_version = version}
  local owner, opponent = {id = 1}, {id = 2}
  local watcher, ownerSocket, opponentSocket = {}, {}, {}
  local packets = { [watcher] = {}, [ownerSocket] = {}, [opponentSocket] = {} }
  local batch = {reference = empty, project = empty, rekey = empty, standing = empty,
    currentReference = empty, commit = empty, abort = empty, resetAudience = empty}
  for socket, queue in pairs(packets) do
    socket.getState = function() return "online" end
    socket.doNotify = function(_, command, payload)
      queue[#queue + 1] = {command = command, payload = payload}
    end
  end
  local env = setmetatable({
    ServerRoomBase = room, ServerPlayer = owner, MiscEventWrappers = room,
    fk = { Player_Robot = "robot", GeneralShown = "shown" },
    General = {Agender = 4}, cbor = {encode = encode, decode = decode},
    PropertyChangeData = {new = function(_, data) data.results = {}; return data end},
    Util = {DummyTable = {}}, resetPlayerHp = empty,
    require = function(name)
      assert(name == "packages.hegemony.util")
      return {wildKingdoms = {"heg_qin", "heg_chu"}}
    end,
    table = setmetatable({
      contains = contains, filter = empty, every = function() return false end,
      map = empty, insertTableIfNeed = empty,
    }, {__index = table}),
  }, {__index = _G})
  local change = {}
  env.ChangeProperty = change
  function change:create(data)
    return {exec = function() change.main({room = room, data = data}) end}
  end
  for _, method in ipairs({"broadcastProperty", "setPlayerProperty", "notifyPrivatePhysical", "publicHegemonyRole", "notifyProperty", "serialize"}) do
    assert(load(definition(roomSource, "function ServerRoomBase:" .. method .. "("), method, "t", env))()
  end
  assert(load(definition(heroSource, "function MiscEventWrappers:changeHero("), "changeHero", "t", env))()
  assert(load(definition(heroSource, "function ChangeProperty:main("), "changeProperty", "t", env))()
  assert(load(definition(playerSource, "function ServerPlayer:revealGeneral("), "revealGeneral", "t", env))()
  local setPrivateRole = assert(load(definition(ruleSource, "local setPrivateRole = function") ..
    "\nreturn setPrivateRole", "setPrivateRole", "t", env))()

  local function record(player)
    return {
      properties = {general = player.general, deputyGeneral = player.deputyGeneral,
        role_shown = player.role_shown, role = player.role, kingdom = player.kingdom, gender = player.gender},
      player_cards = {}, special_cards = {}, mark = emptyMarkCbor,
    }
  end
  room.class = {super = {serialize = function()
    return {players = {record(owner), record(opponent)},
      card_manager = {draw_pile = {}, discard_pile = {}, processing_area = {}, void = {}}}
  end}}
  room.players, room.alive_players = {owner, opponent}, {owner, opponent}
  room.getSettings = function() return "new_heg_mode" end
  room.isGameMode = function() return false end
  room.getPlayerById = function(_, id) return room.players[id] end
  room.getOtherPlayers = empty
  room.handleAddLoseSkills = empty
  room.cardWireAudience = function(_, peer) return peer end
  room.beginCardWireBatch = function() return batch end
  room.projectCardWire = projection.project
  local function deliver(seat, socket, command, payload)
    if version == 1 then payload = projection.project(room, seat, socket, command, payload, batch) end
    socket:doNotify(command, payload)
  end
  owner._splayer, opponent._splayer = ownerSocket, opponentSocket
  function owner:doNotify(command, payload)
    deliver(self, ownerSocket, command, payload)
    deliver(self, watcher, command, payload)
  end
  function opponent:doNotify(command, payload)
    deliver(self, opponentSocket, command, payload)
  end
  local function snapshot(seat, peer, observe)
    local data = room:serialize(seat, observe)
    if version == 1 then
      data = projection.project(room, seat, peer, observe and "Observe" or "Reconnect", data, batch).payload
    end
    return data.players[owner.id].properties
  end
  local function assertPublicPair(first, firstName, second)
    local opponentSnapshot = snapshot(opponent, opponentSocket, false)
    local observerSnapshot = snapshot(owner, watcher, true)
    for _, properties in ipairs({opponentSnapshot, observerSnapshot}) do
      assert(properties[first] == firstName, "public slot missing in snapshot")
      assert(properties[second] == "anjiang", "opposite concealed slot leaked in snapshot")
      assert(properties.role == "hidden", "faction role leaked in snapshot")
    end
  end
  room.logic = {trigger = function() end}
  room.sendLog = function(_, payload)
    for _, seat in ipairs(room.players) do seat:doNotify("GameLog", payload) end
  end
  owner.general, owner.deputyGeneral, owner.role_shown = "anjiang", "anjiang", false
  owner.gender, owner.kingdom = 4, "unknown"
  owner.loseFakeSkill = empty
  owner.room = room
  owner.getMark = function(_, key)
    return ({__heg_general = "fixture_main", __heg_deputy = "fixture_deputy", __heg_kingdom = "wei"})[key] or 0
  end

  local first = firstDeputy and "deputyGeneral" or "general"
  local second = firstDeputy and "general" or "deputyGeneral"
  local firstName = firstDeputy and "fixture_deputy" or "fixture_main"
  local secondName = firstDeputy and "fixture_main" or "fixture_deputy"
  local function lastProperty(peer, key)
    for i = #packets[peer], 1, -1 do
      local packet = packets[peer][i]
      if packet.command == "PropertyUpdate" and packet.payload[2] == key then
        return packet.payload[3]
      end
    end
  end
  local function sawRevealLog(peer)
    for _, packet in ipairs(packets[peer]) do
      local data = packet.payload.payload or packet.payload
      if packet.command == "GameLog" and data.type == "#RevealGeneral" and data.arg2 == firstName then return true end
    end
    return false
  end
  -- A reconnect while initial selection still holds the real choices must
  -- receive neither identity. The following reveal begins from anjiang.
  owner[first], owner[second], owner.role = firstName, secondName, "wei"
  assertPublicPair(first, "anjiang", second)
  room:notifyProperty(owner, owner, first)
  room:notifyProperty(opponent, owner, first)
  assert(lastProperty(ownerSocket, first) == firstName)
  assert(lastProperty(opponentSocket, first) == "anjiang")
  assert(lastProperty(watcher, first) == nil)
  owner[first], owner[second] = "anjiang", "anjiang"

  owner:revealGeneral(firstDeputy, true)
  assert(owner[first] == firstName and owner.role_shown == false)
  assert(lastProperty(ownerSocket, first) == firstName)
  assert(lastProperty(opponentSocket, first) == firstName)
  assert(lastProperty(watcher, first) == firstName)
  assert(lastProperty(opponentSocket, second) == nil and lastProperty(watcher, second) == nil)
  assert(sawRevealLog(opponentSocket) and sawRevealLog(watcher))
  assertPublicPair(first, firstName, second)

  setPrivateRole(room, owner, "wei")
  for _, peer in ipairs({ownerSocket, opponentSocket, watcher}) do
    assert(lastProperty(peer, "kingdom") == "wei", "published faction missing after first reveal")
  end
  owner:revealGeneral(not firstDeputy, true)
  for _, peer in ipairs({opponentSocket, watcher}) do
    assert(lastProperty(peer, first) == firstName)
    assert(lastProperty(peer, second) == secondName)
  end

  room:setPlayerProperty(owner, "role_shown", false)
  room:setPlayerProperty(owner, first, "anjiang")
  assert(lastProperty(opponentSocket, first) == "anjiang")
  assert(lastProperty(watcher, first) == "anjiang")
  assertPublicPair(second, secondName, first)
  -- Assigning a previously revealed name later without the reveal action
  -- must never reuse that slot's old publication authorization.
  room:setPlayerProperty(owner, first, firstName)
  assert(lastProperty(opponentSocket, first) == "anjiang")
  assertPublicPair(second, secondName, first)
  owner.role = "heg_qin"
  room:broadcastProperty(owner, "role")
  assert(lastProperty(opponentSocket, "role") == "hidden")
  assert(snapshot(opponent, opponentSocket, false).role == "hidden")
  room:setPlayerProperty(owner, "role_shown", true)
  room:setPlayerProperty(owner, "role", "heg_qin")
  room:setPlayerProperty(owner, "kingdom", "wild")
  assert(lastProperty(opponentSocket, "role") == "heg_qin")
  assert(lastProperty(watcher, "role") == "heg_qin")
  assert(snapshot(opponent, opponentSocket, false).role == "heg_qin")
  assert(snapshot(owner, watcher, true).role == "heg_qin")
  print(("PASS wire=%s first=%s owner/opponent/observer/reconnect; concealed pair, second reveal, rehide"):
    format(version or "legacy", first))

end
for _, version in ipairs({1, false}) do
  reproduce(version or nil, false)
  reproduce(version or nil, true)
end
