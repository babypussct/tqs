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
  function physical:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, payload = payload }
  end
end

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

ServerConfig = { tqsQa = { enabled = true, cardWireVersion = 1 } }
fk = { Player_Robot = "robot" }

local serverMethods = {}
local serverEnv = setmetatable({
  ServerRoomBase = serverMethods,
  ServerConfig = ServerConfig,
  cbor = cbor,
  fk = fk,
}, { __index = _G })
local serverSource = read(coreRoot .. "/lua/server/roombase.lua")
local serverStart = assert(serverSource:find(
  "function ServerRoomBase:negotiateCardWireV1(players)", 1, true))
local serverEnd = assert(serverSource:find(
  "\nend\n\nfunction ServerRoomBase:handleChat", serverStart, true))
assert(load(serverSource:sub(serverStart, serverEnd + 4),
  "=candidate/negotiation/server", "t", serverEnv))()

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
  callbacks = {},
  recording = false,
  replaying = false,
  notifications = {},
}
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
ServerConfig.tqsQa.cardWireVersion = oldVersion

print("PASS candidate card-wire negotiation: actual QA room helper, legacy CBOR " ..
  "envelope, per-physical dedupe, actual ClientCallback activation and " ..
  "malformed/legacy fail-closed; 4 cases; native C++/browser/two-account NOT RUN")
