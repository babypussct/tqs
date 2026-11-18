-- Exercise the candidate QA-only card-wire negotiation seam end-to-end at the
-- Lua layer. The notification is encoded by the real candidate CBOR codec,
-- decoded by the real ClientCallback body, and contains no card IDs. Native
-- C++/browser/two-account acceptance remains a separate gate.
local coreRoot = assert(arg[1], "candidate core root required")
package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" ..
  coreRoot .. "/lua/?.lua;" .. coreRoot .. "/lua/?/init.lua;" .. package.path

local function read(path)
  local file = assert(io.open(path, "rb"))
  local source = assert(file:read("*a"))
  file:close()
  return source
end

cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))

local ownerSocket = { packets = {}, state = "online" }
local observerSocket = { packets = {}, state = "online" }
for _, physical in ipairs({ ownerSocket, observerSocket }) do
  function physical:getState() return self.state end
  function physical:getId() return self.id end
  function physical:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, payload = payload }
  end
end
ownerSocket.id = 101
observerSocket.id = 102

local room = {
  card_wire_version = nil,
  settings = { gameMode = "new_heg_mode" },
  players = {
    { id = 11, _splayer = ownerSocket },
    { id = 12, _splayer = observerSocket },
    { id = 13, _splayer = ownerSocket }, -- one physical controller, two seats
  },
}
function room:getSettings(key) return self.settings[key] end
function room:getPlayerById(id)
  for _, player in ipairs(self.players) do
    if player.id == id then return player end
  end
end
room.room = {
  getObservers = function() return {} end,
}

ServerConfig = { tqsQa = { enabled = true, cardWireVersion = 1 } }
fk = {
  Player_Robot = "robot",
  qlist = function(values) return values end,
}

local serverMethods = {}
local serverEnv = setmetatable({
  ServerRoomBase = serverMethods,
  ServerConfig = ServerConfig,
  cbor = cbor,
  fk = fk,
}, { __index = _G })
local serverSource = read(coreRoot .. "/lua/server/roombase.lua")
local capabilityStart = assert(serverSource:find(
  "-- TQS_HEG_CARD_WIRE_CAPABILITY: a card-free", 1, true))
local capabilityEnd = assert(serverSource:find(
  "\n-- TQS_HEG_CARD_WIRE_NEGOTIATION:", capabilityStart, true))
assert(load(serverSource:sub(capabilityStart, capabilityEnd - 1),
  "=candidate/negotiation/capability", "t", serverEnv))()
local serverStart = assert(serverSource:find(
  "function ServerRoomBase:negotiateCardWireV1(players)", 1, true))
local serverEnd = assert(serverSource:find(
  "\nend\n\nfunction ServerRoomBase:handleChat", serverStart, true))
assert(load(serverSource:sub(serverStart, serverEnd + 4),
  "=candidate/negotiation/server", "t", serverEnv))()
setmetatable(room, { __index = serverMethods })

assert(not serverMethods.hasAllCardWireCapabilities(room),
  "missing capability must not pass the all-physical gate")
assert(not pcall(function() serverMethods.negotiateCardWireV1(room) end),
  "missing capability must fail closed before v1 packets")
assert(room.card_wire_version == nil and #ownerSocket.packets == 0 and
  #observerSocket.packets == 0)

serverMethods.handleCardWireCapability(room, 11,
  { "11", "card_wire_capability", "2", "TQS_HEG_CARD_WIRE", "new_heg_mode" })
assert(not serverMethods.hasCardWireCapability(room, ownerSocket),
  "wrong capability version must be rejected")
serverMethods.handleCardWireCapability(room, 11,
  { "11", "card_wire_capability", "1", "OTHER_CARD_WIRE", "new_heg_mode" })
assert(not serverMethods.hasCardWireCapability(room, ownerSocket),
  "wrong capability protocol must be rejected")
serverMethods.handleCardWireCapability(room, 11,
  { "11", "card_wire_capability", "1", "TQS_HEG_CARD_WIRE", "classic_mode" })
assert(not serverMethods.hasCardWireCapability(room, ownerSocket),
  "wrong capability mode must be rejected")
serverMethods.handleCardWireCapability(room, 11,
  { "11", "card_wire_capability", "1", "TQS_HEG_CARD_WIRE", "new_heg_mode" })
serverMethods.handleCardWireCapability(room, 12,
  { "12", "card_wire_capability", "1", "TQS_HEG_CARD_WIRE", "new_heg_mode" })
assert(serverMethods.hasAllCardWireCapabilities(room),
  "all physical capabilities must be required before v1")

serverMethods.negotiateCardWireV1(room)
assert(room.card_wire_version == 1 and room.card_wire_negotiated == true and
  room.card_wire_protocol == "TQS_HEG_CARD_WIRE")
assert(#ownerSocket.packets == 1 and #observerSocket.packets == 1,
  "negotiation must be sent once per physical connection")
assert(#room.players == 3 and #ownerSocket.packets == 1,
  "multiple seats on one physical connection must not duplicate the packet")

local ownerEnvelope = cbor.decode(ownerSocket.packets[1].payload)
assert(ownerSocket.packets[1].command == "CardWireNegotiated" and
  ownerEnvelope.protocol == "TQS_HEG_CARD_WIRE" and
  ownerEnvelope.cardWireVersion == 1 and ownerEnvelope.mode == "new_heg_mode")
for key, value in pairs(ownerEnvelope) do
  assert(key == "protocol" or key == "cardWireVersion" or key == "mode")
  assert(type(value) ~= "number" or key == "cardWireVersion",
    "negotiation must not carry a card/player/order numeric value")
end

local nativeCards = {}
Fk = {
  currentResponsePattern = "stale",
  currentResponseReason = "stale",
}
local client = {
  card_wire_version = nil,
  client = { notifications = {} },
  callbacks = {},
  recording = false,
  replaying = false,
  notifications = {},
}
function client.client:notifyServer(command, payload)
  self.notifications[#self.notifications + 1] = { command = command, payload = payload }
end
function client:notifyUI(command, data)
  self.notifications[#self.notifications + 1] = { command, data }
end

local clientTable = setmetatable({
  contains = function(values, wanted)
    for _, value in ipairs(values) do
      if value == wanted then return true end
    end
    return false
  end,
}, { __index = table })
local clientEnv = setmetatable({
  ClientInstance = client,
  Fk = Fk,
  cbor = cbor,
  fk = { client_callback = {} },
  table = clientTable,
  require = require,
  pattern_refresh_commands = {
    "PlayCard", "AskForUseActiveSkill", "AskForUseCard", "AskForResponseCard",
  },
  no_decode_commands = {
    "ErrorMsg", "ErrorDlg", "Heartbeat", "ServerMessage",
    "UpdateAvatar", "UpdatePassword",
  },
}, { __index = _G })
local clientSource = read(coreRoot .. "/lua/client/client.lua")
local clientStart = assert(clientSource:find("ClientCallback = function", 1, true))
local clientMarker = "\nend\n\n-- Create ClientInstance"
local clientEnd = assert(clientSource:find(clientMarker, clientStart, true))
assert(load(clientSource:sub(clientStart, clientEnd + 4),
  "=candidate/negotiation/client", "t", clientEnv))()

local clientNegotiation = assert(dofile(coreRoot .. "/ltk/client/card_wire_negotiation.lua"))
assert(clientNegotiation.advertise(client, "new_heg_mode"))
assert(#client.client.notifications == 1 and
  client.client.notifications[1].command == "PushRequest")
assert(cbor.decode(client.client.notifications[1].payload) ==
  "card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode")
assert(clientNegotiation.advertise(client, "new_heg_mode"))
assert(#client.client.notifications == 1, "capability advertisement must be idempotent")
assert(not clientNegotiation.advertise({ client = client.client }, "classic_mode"),
  "non-Hegemony rooms must not advertise the Hegemony capability")

clientEnv.ClientCallback(nil, "CardWireNegotiated", ownerSocket.packets[1].payload, false)
assert(client.card_wire_version == 1 and client.card_wire_negotiated == true and
  client.card_wire_protocol == "TQS_HEG_CARD_WIRE" and #client.notifications == 0,
  "actual ClientCallback must consume negotiation before UI dispatch")

local malformed = cbor.encode {
  protocol = "TQS_HEG_CARD_WIRE", cardWireVersion = 1,
  mode = "new_heg_mode", cardId = 101,
}
assert(not pcall(function()
  clientEnv.ClientCallback(nil, "CardWireNegotiated", malformed, false)
end), "negotiation must reject card-shaped fields")

local legacyRoom = {
  card_wire_version = nil,
  settings = { gameMode = "new_heg_mode" },
  players = room.players,
}
function legacyRoom:getSettings(key) return self.settings[key] end
local oldVersion = ServerConfig.tqsQa.cardWireVersion
ServerConfig.tqsQa.cardWireVersion = nil
assert(not pcall(function() serverMethods.negotiateCardWireV1(legacyRoom) end),
  "missing QA opt-in must fail closed")
assert(legacyRoom.card_wire_version == nil)

-- Rollback must not silently downgrade an in-flight v1 room.  Disabling the
-- opt-in blocks a new negotiation, while the already negotiated room keeps
-- its version marker until the room is drained or ended by its owner.
local activeV1Room = {
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  players = room.players,
}
function activeV1Room:getSettings(key) return self.settings[key] end
assert(not pcall(function() serverMethods.negotiateCardWireV1(activeV1Room) end),
  "rollback must not downgrade an active v1 room")
assert(activeV1Room.card_wire_version == 1,
  "an active v1 room must retain its protocol marker during rollback")

ServerConfig.tqsQa.cardWireVersion = oldVersion

print("PASS candidate card-wire negotiation: actual QA room helper, legacy CBOR " ..
  "envelope, per-physical dedupe, client capability advertise, wrong " ..
  "version/protocol/mode rejection, actual ClientCallback activation, " ..
  "active-v1 no-downgrade and malformed/legacy fail-closed; 12 cases; " ..
  "native C++/browser/two-account NOT RUN")
