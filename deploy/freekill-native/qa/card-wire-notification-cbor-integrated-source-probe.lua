-- Exercise the candidate's actual broadcast/notification bodies for the
-- count-only deck, area, private-pile and hidden-move channels. This probe
-- deliberately keeps the legacy source diagnostic separate: it enables the
-- negotiated candidate v1 seam, encodes every captured packet with the real
-- candidate CBOR codec, and then inspects the decoded physical payloads.
-- Native C++/browser/two-account acceptance remains a separate gate.
local coreRoot, protocolPath = ...
assert(coreRoot and protocolPath, "candidate core and protocol paths required")

package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" ..
  coreRoot .. "/lua/?.lua;" .. coreRoot .. "/lua/?/init.lua;" .. package.path

local function read(relative)
  local file = assert(io.open(coreRoot .. "/" .. relative, "rb"))
  local source = assert(file:read("*a"))
  file:close()
  return source
end

local function loadMethod(relative, signature, target, label, env)
  local source = read(relative)
  local start = assert(source:find(signature, 1, true),
    "missing Lua definition: " .. label)
  local finish = assert(source:find("\nend\n", start, true),
    "missing Lua end: " .. label)
  assert(load(source:sub(start, finish + 4), "=candidate/" .. label, "t", env))()
  assert(type(target[label]) == "function", "method did not load: " .. label)
end

cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))
Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3, PlayerSpecial = 4,
  Processing = 5, DiscardPile = 6, DrawPile = 7, Void = 8,
}

local Protocol = assert(loadfile(protocolPath))()
local Mint = assert(dofile(coreRoot .. "/lua/server/card_wire_secure_mint.lua"))
local protocol = Protocol.new(Mint.next)
local Projection = assert(dofile(coreRoot .. "/lua/server/card_wire_projection.lua"))

local baseMethods, serverMethods, roomMethods = {}, {}, {}
local logicMethods, moveMethods = {}, {}
local nativeTable = setmetatable({
  insertTable = function(destination, source)
    for _, value in ipairs(source) do table.insert(destination, value) end
  end,
  simpleClone = function(value)
    local result = {}
    for key, item in pairs(value) do result[key] = item end
    return result
  end,
  map = function(value, mapper)
    local result = {}
    for index, item in ipairs(value) do result[index] = mapper(item) end
    return result
  end,
}, { __index = table })

local env = setmetatable({
  Card = Card,
  ServerRoomBase = baseMethods,
  ServerPlayerBase = serverMethods,
  Room = roomMethods,
  GameLogic = logicMethods,
  MoveEventWrappers = moveMethods,
  AbstractRoom = {
    shuffleDrawPile = function(room, ids)
      room.draw_pile = ids
      room.discard_pile = {}
    end,
    changeCardArea = function(_, _, _, areaCards) return areaCards end,
  },
  Util = { IdMapper = function(player) return player.id end },
  cbor = cbor,
  table = nativeTable,
  Fk = { filterChatMessage = function(message) return message end },
  fk = { Player_Robot = "robot" },
}, { __index = _G })

-- Load the exact candidate methods used on the live Lua path. The synthetic
-- socket is the only native boundary replaced by this source probe.
loadMethod("lua/server/roombase.lua",
  "function ServerRoomBase:doBroadcastNotify(command, jsonData, players)",
  baseMethods, "doBroadcastNotify", env)
loadMethod("lua/server/serverplayer_base.lua",
  "function ServerPlayerBase:doNotify(command, data)",
  serverMethods, "doNotify", env)
serverMethods.filterChatMessage = function(message) return message end
loadMethod("ltk/server/gamelogic.lua",
  "function GameLogic:prepareDrawPile()",
  logicMethods, "prepareDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:shuffleDrawPile()",
  roomMethods, "shuffleDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:syncDrawPile()",
  roomMethods, "syncDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:changeCardArea (cards, area, areaCards)",
  roomMethods, "changeCardArea", env)
loadMethod("ltk/server/room.lua",
  "function Room:setPlayerPile(player, pile, ids)",
  roomMethods, "setPlayerPile", env)
loadMethod("ltk/server/events/movecard.lua",
  "function MoveEventWrappers:notifyMoveCards(players, moveDatas, event_id)",
  moveMethods, "notifyMoveCards", env)

-- The LTK Room class inherits the base room notification methods. Preserve
-- that relationship in the source fixture so the loaded bodies exercise the
-- same `room:doBroadcastNotify` path as the candidate runtime.
setmetatable(roomMethods, { __index = baseMethods })

local function socket(name)
  local result = { name = name, audience = "notification-" .. name, packets = {} }
  function result:getState() return "online" end
  function result:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, payload = payload }
  end
  return result
end

local ownerSocket = socket("owner")
local opponentSocket = socket("opponent")
local observerSocket = socket("observer")

local owner = {
  id = 1, _splayer = ownerSocket, _observers = { ownerSocket, observerSocket },
  special_cards = {}, role_shown = false,
}
local opponent = {
  id = 2, _splayer = opponentSocket, _observers = { opponentSocket },
  special_cards = {}, role_shown = false,
}

local room = {
  card_wire_version = 1,
  card_wire_negotiated = true,
  settings = { gameMode = "new_heg_mode" },
  _cardWireProtocol = protocol,
  players = { owner, opponent },
  observers = {},
  notify_count = 0,
  notify_max = 1000,
  main_co = coroutine.create(function() end),
  draw_pile = { 811, 827, 803 },
  discard_pile = {},
  void = {},
  logic = { trigger = function() end },
  room = { hasObserver = function() return true end },
}
setmetatable(owner, { __index = serverMethods })
setmetatable(opponent, { __index = serverMethods })
setmetatable(room, { __index = roomMethods })
owner.room = room
opponent.room = room

function room:getSettings(key) return self.settings[key] end
function room:hasCardWireCapability() return true end
function room:cardWireAudience(physical) return physical.audience end
function room:beginCardWireBatch() return protocol:beginBatch() end
function room:projectCardWire(seat, physical, command, data, batch)
  return Projection.project(self, seat, physical, command, data, batch)
end
function room:getPlayerById(id)
  if id == owner.id then return owner end
  if id == opponent.id then return opponent end
end
function room:prepareDrawPile()
  self.draw_pile = { 811, 827, 803 }
  self.discard_pile = {}
end
function room:shuffleTable() end
function room:random() return 1 end
function room:getCardArea(id)
  if id == 829 then return Card.PlayerHand end
  if id == 830 then return Card.PlayerEquip end
  if id == 831 then return Card.DrawPile end
  if id == 832 then return Card.DiscardPile end
end
function room:getCardOwner(id)
  if id == 829 or id == 830 then return owner end
end

local function clearPackets()
  for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
    physical.packets = {}
  end
end

local function lastPacket(physical, command)
  for index = #physical.packets, 1, -1 do
    local packet = physical.packets[index]
    if packet.command == command then
      return cbor.decode(packet.payload)
    end
  end
  error("missing packet " .. command .. " for " .. physical.name)
end

local function assertCountOnly(physical, command, count)
  local packet = lastPacket(physical, command)
  assert(type(packet) == "table" and packet.count == count,
    command .. " must carry only the card count")
  assert(packet[1] == nil and packet[2] == nil,
    command .. " must not carry an ordered card array")
end

-- The initial deck and all subsequent deck-order notifications must be
-- projected separately for every physical recipient.
clearPackets()
logicMethods.prepareDrawPile({ room = room })
for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
  assertCountOnly(physical, "PrepareDrawPile", 3)
end

clearPackets()
room.draw_pile, room.discard_pile = { 811, 827, 803 }, {}
roomMethods.shuffleDrawPile(room)
for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
  assertCountOnly(physical, "ShuffleDrawPile", 3)
end

clearPackets()
roomMethods.syncDrawPile(room)
for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
  assertCountOnly(physical, "SyncDrawPile", 3)
end

clearPackets()
roomMethods.changeCardArea(room, { 821 }, Card.DrawPile, { 811, 827, 803 })
for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
  local packet = lastPacket(physical, "ChangeCardArea")
  assert(packet.count == 1 and packet.area == Card.DrawPile and
    packet.areaCount == 3 and packet[3] == nil,
    "ChangeCardArea must not carry draw order")
end

-- A private pile is canonical only for its owner. Other physical audiences
-- get independent opaque references, including an observer attached to the
-- owner's seat.
clearPackets()
roomMethods.setPlayerPile(room, owner, "$hidden", { 829 })
local ownerPile = lastPacket(ownerSocket, "SetPlayerPile")
local opponentPile = lastPacket(opponentSocket, "SetPlayerPile")
local observerPile = lastPacket(observerSocket, "SetPlayerPile")
assert(ownerPile[3][1] == 829, "pile owner may retain the canonical card ID")
for _, packet in ipairs({ opponentPile, observerPile }) do
  assert(type(packet[3][1]) == "string" and packet[3][1]:sub(1, 2) == "h:" and
    packet[3][1] ~= "829", "private pile ID must be opaque to nonowners")
end

-- A hidden hand card moved to a public area is still opaque to a peer who is
-- not the source owner. The source move object must remain canonical server
-- state after per-recipient projection.
clearPackets()
local move = {
  moveVisible = false,
  from = owner,
  toArea = Card.DiscardPile,
  moveInfo = { { cardId = 829, fromArea = Card.PlayerHand } },
}
moveMethods.notifyMoveCards(room, { opponent }, { move }, 7001)
local opponentMove = lastPacket(opponentSocket, "MoveCards")
assert(type(opponentMove[1][1].moveInfo[1].cardId) == "string" and
  opponentMove[1][1].moveInfo[1].cardId:sub(1, 2) == "h:" and
  opponentMove[1][1].moveInfo[1].cardId ~= "829",
  "hidden MoveCards card ID must be opaque to the peer")
assert(move.moveInfo[1].cardId == 829,
  "per-physical MoveCards projection must not mutate source state")

-- Card metadata uses the same actual broadcast/notify bodies, but carries an
-- explicit v1 envelope so the client can localize references before legacy
-- callbacks or UI code consume them.
clearPackets()
baseMethods.doBroadcastNotify(room, "SetCardFootnote", {
  { 829, 830 }, { type = "##Probe", from = owner.id, arg = "reason" }, false,
})
local ownerFootnote = lastPacket(ownerSocket, "SetCardFootnote")
local opponentFootnote = lastPacket(opponentSocket, "SetCardFootnote")
assert(ownerFootnote.cardWireVersion == 1 and ownerFootnote.payload[1][1] == 829 and
  ownerFootnote.payload[1][2] == 830)
assert(type(opponentFootnote.payload[1][1]) == "string" and
  opponentFootnote.payload[1][2] == 830 and
  opponentFootnote.payload[2].arg == "reason")

clearPackets()
baseMethods.doBroadcastNotify(room, "SetCardVirtName", {{ 7001 }, "slash", true})
assert(lastPacket(opponentSocket, "SetCardVirtName").cardWireVersion == 1)

clearPackets()
baseMethods.doBroadcastNotify(room, "FilterCard", { 829, owner, false })
local ownerFilter = lastPacket(ownerSocket, "FilterCard")
local opponentFilter = lastPacket(opponentSocket, "FilterCard")
assert(ownerFilter.payload[1] == 829 and ownerFilter.payload[2] == 1)
assert(type(opponentFilter.payload[1]) == "string" and
  opponentFilter.payload[2] == 1)

clearPackets()
baseMethods.doBroadcastNotify(room, "FilterCard", { 831, nil, false })
assert(lastPacket(opponentSocket, "FilterCard").payload[1] == -1)

clearPackets()
baseMethods.doBroadcastNotify(room, "SetPlayerHandCards", { owner.id, { 829 } })
assert(lastPacket(ownerSocket, "SetPlayerHandCards").payload[2][1] == 829)
assert(type(lastPacket(opponentSocket, "SetPlayerHandCards").payload[2][1]) == "string")

clearPackets()
baseMethods.doBroadcastNotify(room, "AddVirtualEquip", {
  player = owner.id, name = "probe_equip", subcards = { 829, 830 },
})
local opponentEquip = lastPacket(opponentSocket, "AddVirtualEquip")
assert(type(opponentEquip.payload.subcards[1]) == "string" and
  opponentEquip.payload.subcards[2] == 830)

clearPackets()
baseMethods.doBroadcastNotify(room, "RemoveVirtualEquip", { player = owner.id, id = 830 })
assert(lastPacket(opponentSocket, "RemoveVirtualEquip").payload.id == 830)

-- AG is an explicit public reveal. Its packet still uses a v1 envelope so an
-- opaque standing reference from an earlier concealed location is retired
-- before the legacy AG model sees the local/canonical ID.
clearPackets()
baseMethods.doBroadcastNotify(room, "FillAG", { { 831, 832 }, { 832 } })
local ownerAg = lastPacket(ownerSocket, "FillAG")
local opponentAg = lastPacket(opponentSocket, "FillAG")
assert(ownerAg.cardWireVersion == 1 and opponentAg.cardWireVersion == 1 and
  ownerAg.payload[1][1] == 831 and ownerAg.payload[1][2] == 832 and
  opponentAg.payload[2][1] == 832)

clearPackets()
baseMethods.doBroadcastNotify(room, "TakeAG", { owner.id, 831 })
local ownerTaken = lastPacket(ownerSocket, "TakeAG")
local opponentTaken = lastPacket(opponentSocket, "TakeAG")
assert(ownerTaken.cardWireVersion == 1 and opponentTaken.cardWireVersion == 1 and
  ownerTaken.payload[1] == owner.id and ownerTaken.payload[2] == 831 and
  opponentTaken.payload[2] == 831)

clearPackets()
baseMethods.doBroadcastNotify(room, "GameOver", "1+2")
assert(lastPacket(ownerSocket, "GameOver") == "1+2" and
  lastPacket(opponentSocket, "GameOver") == "1+2")

-- Non-card notifications still use the same physical projector boundary. The
-- payloads are explicit metadata schemas; unknown fields/types remain
-- fail-closed in the projector instead of becoming an unreviewed CBOR path.
clearPackets()
baseMethods.doBroadcastNotify(room, "ArrangeSeats", { owner.id, opponent.id })
local arranged = lastPacket(opponentSocket, "ArrangeSeats")
assert(arranged[1] == owner.id and arranged[2] == opponent.id)
baseMethods.doBroadcastNotify(room, "AddObserver", { 77, "watcher", "avatar", false, 10 })
assert(lastPacket(opponentSocket, "AddObserver")[1] == 77)
baseMethods.doBroadcastNotify(room, "RemoveObserver", { 77 })
assert(lastPacket(opponentSocket, "RemoveObserver")[1] == 77)
baseMethods.doBroadcastNotify(room, "AddNpc", { -1, "bot", "avatar", true, 0 })
assert(lastPacket(opponentSocket, "AddNpc")[1] == -1)
baseMethods.doBroadcastNotify(room, "Chat", { type = 2, sender = owner.id, msg = "hello" })
assert(lastPacket(opponentSocket, "Chat").msg == "hello")
baseMethods.doBroadcastNotify(room, "ChangeSkin", { owner.id, "changeskin", "main", "deputy" })
assert(lastPacket(opponentSocket, "ChangeSkin")[4] == "deputy")
baseMethods.doBroadcastNotify(room, "PrintCard", { "slash", 1, 7 })
assert(lastPacket(opponentSocket, "PrintCard")[1] == "slash")
baseMethods.doBroadcastNotify(room, "UpdateQuestSkillUI", { owner.id, "quest_skill" })
assert(lastPacket(opponentSocket, "UpdateQuestSkillUI")[2] == "quest_skill")
baseMethods.doBroadcastNotify(room, "AddBuddy", { owner.id, opponent.id })
assert(lastPacket(opponentSocket, "AddBuddy")[2] == opponent.id)
baseMethods.doBroadcastNotify(room, "RmBuddy", { owner.id, opponent.id })
assert(lastPacket(opponentSocket, "RmBuddy")[2] == opponent.id)
baseMethods.doBroadcastNotify(room, "Animate", {
  type = "Indicate", from = owner.id, to = {{ opponent.id }},
})
assert(lastPacket(opponentSocket, "Animate").type == "Indicate")
baseMethods.doBroadcastNotify(room, "Animate", {
  type = "Emotion", player = 830, emotion = "glow", is_card = true,
})
assert(lastPacket(opponentSocket, "Animate").player == 830)
baseMethods.doBroadcastNotify(room, "Animate", {
  type = "SuperLightBox", data = { text = "probe" },
})
assert(lastPacket(opponentSocket, "Animate").data.text == "probe")
baseMethods.doBroadcastNotify(room, "LogEvent", {
  type = "PlaySkillSound", name = "wusheng", i = -1,
  general = "concealed_general", deputy = "concealed_deputy",
})
local skillSound = lastPacket(opponentSocket, "LogEvent")
assert(skillSound.general == nil and skillSound.deputy == nil and skillSound.name == "wusheng")
baseMethods.doBroadcastNotify(room, "ChangeSelf", opponent.id)
assert(lastPacket(opponentSocket, "ChangeSelf") == opponent.id)
baseMethods.doBroadcastNotify(room, "RoomOwner", { owner.id })
assert(lastPacket(opponentSocket, "RoomOwner")[1] == owner.id)
baseMethods.doBroadcastNotify(room, "CloseSurrenderNegotiation", { "n:1" })
assert(lastPacket(opponentSocket, "CloseSurrenderNegotiation")[1] == "n:1")
baseMethods.doBroadcastNotify(room, "AskForSurrenderNegotiation", { "n:1", owner.id, "Alice" })
assert(lastPacket(opponentSocket, "AskForSurrenderNegotiation")[2] == owner.id)
baseMethods.doBroadcastNotify(room, "PrelightSkill", { "fake_skill", true })
assert(lastPacket(opponentSocket, "PrelightSkill")[2] == true)

print("PASS integrated candidate notification Lua CBOR wire: actual " ..
  "broadcast/notify bodies for count-only deck, ChangeCardArea, private pile, " ..
  "hidden MoveCards, card metadata, public AG, GameOver and metadata schemas; " ..
  "16 cases; native C++/browser/two-account NOT RUN")
