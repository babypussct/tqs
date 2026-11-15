-- Exercise the candidate Request projector/resolver and client request bridge
-- with the actual candidate Lua CBOR codec. Native C++ sockets/QML and live
-- two-account acceptance remain separate gates.
local coreRoot, protocolPath = ...
assert(coreRoot and protocolPath, "candidate core and protocol paths required")

package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" ..
  coreRoot .. "/lua/?.lua;" .. coreRoot .. "/lua/?/init.lua;" .. package.path

local function read(path)
  local file = assert(io.open(path, "rb"))
  local source = assert(file:read("*a"))
  file:close()
  return source
end

cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))
Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3, PlayerSpecial = 4,
  Processing = 5, DiscardPile = 6, DrawPile = 7, Void = 8,
}
Player = { Hand = 1, Equip = 2, Judge = 3, Special = 4 }

-- The request projector uses these helpers for its scalar-choice paths. The
-- AskForAG path below does not depend on any fixture-only fallback.
table.contains = function(values, wanted)
  for _, value in ipairs(values) do
    if value == wanted then return true end
  end
  return false
end

local Protocol = assert(loadfile(protocolPath))()
local Mint = assert(dofile(coreRoot .. "/lua/server/card_wire_secure_mint.lua"))
local protocol = Protocol.new(Mint.next)
local RequestWire = assert(dofile(coreRoot .. "/lua/server/card_wire_request.lua"))

local controller = {
  state = "online", currentThinking = false, requests = {}, reply = "__notready",
}
function controller:thinking() return self.currentThinking end
function controller:getState() return self.state end
function controller:setThinking(value) self.currentThinking = value end
function controller:doRequest(command, payload, timeout, timestamp)
  self.requests[#self.requests + 1] = {
    command = command, payload = payload, timeout = timeout, timestamp = timestamp,
  }
end
function controller:waitForReply()
  local reply = self.reply
  self.reply = "__notready"
  return reply
end

local target = {
  id = 2, player = {}, serverplayer = {}, _splayer = {},
  player_cards = { [Player.Hand] = { 101, 102 }, [Player.Equip] = {},
    [Player.Judge] = {} }, special_cards = {},
}
local player = {
  id = 1, player = {}, serverplayer = controller, _splayer = controller,
  _observers = { controller }, room = nil,
  player_cards = { [Player.Hand] = {}, [Player.Equip] = {},
    [Player.Judge] = {} }, special_cards = {},
}

local robotController = {
  state = "robot", currentThinking = false, requests = {},
}
function robotController:thinking() return self.currentThinking end
function robotController:getState() return self.state end
function robotController:setThinking(value) self.currentThinking = value end
function robotController:doRequest(command, payload, timeout, timestamp)
  self.requests[#self.requests + 1] = {
    command = command, payload = payload, timeout = timeout, timestamp = timestamp,
  }
end

local robotPlayer = {
  id = 3, player = {}, serverplayer = robotController, _splayer = robotController,
  _observers = { robotController }, room = nil, player_cards = {}, special_cards = {},
}
function robotPlayer:getCardIds() return {} end
robotPlayer.ai = {
  makeReply = function()
    -- Native AI replies are not wire tokens. The Request bridge must leave
    -- them for the upstream resolver instead of passing them through the
    -- human socket reverse-map.
    return { card = false, targets = {} }
  end,
}

local room = {
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  _cardWireProtocol = protocol,
  players = { player, target, robotPlayer },
  current_request = nil,
  resolveCalls = 0,
}
player.room = room
robotPlayer.room = room
function room:getSettings(key) return self.settings[key] end
function room:getTag() return nil end
function room:getPlayerById(id)
  for _, item in ipairs(self.players) do
    if item.id == id then return item end
  end
end
function room:cardWireAudience(physical)
  if physical == controller then return "integrated-request-owner" end
  if physical == robotController then return "integrated-request-robot" end
  error("unexpected request physical connection")
end
function room:beginCardWireBatch() return protocol:beginBatch() end
function room:getCardArea(id)
  if id == 101 or id == 102 then return Card.PlayerHand end
end
function room:getCardOwner(id)
  if id == 101 or id == 102 then return target end
end
function room:projectCardWireRequest(seat, physical, command, data, batch, requestKey)
  return RequestWire.project(self, seat, physical, command, data, batch, requestKey)
end
function room:resolveCardWireRequestReply(seat, physical, command, reply, requestKey, originalData)
  self.resolveCalls = self.resolveCalls + 1
  return RequestWire.resolve(self, seat, physical, command, reply, requestKey, originalData)
end
function room:checkNoHuman() end

-- Load the actual candidate Request methods that send and resolve a human
-- packet. Only the network controller is a fixture; the candidate projector,
-- protocol, secure mint and codec are real candidate/QA modules.
local requestMethods = {}
local nativeTable = setmetatable({
  contains = table.contains,
  find = function(values, predicate)
    for _, value in ipairs(values) do
      if predicate(value) then return value end
    end
  end,
}, { __index = table })
local requestEnv = setmetatable({
  Request = requestMethods,
  cbor = cbor,
  fk = { Player_Online = "online", Player_Robot = "robot" },
  surrenderCheck = function() end,
  table = nativeTable,
  require = require,
}, { __index = _G })
local requestSource = read(coreRoot .. "/lua/server/request.lua")
local function loadMethod(signature)
  local start = assert(requestSource:find(signature, 1, true),
    "candidate Request method missing: " .. signature)
  local ending = assert(requestSource:find("\nend\n", start, true),
    "candidate Request method unterminated: " .. signature)
  assert(load(requestSource:sub(start, ending + 4),
    "=candidate/integrated/request", "t", requestEnv))()
end
loadMethod("function Request:_sendPacket(player)")
loadMethod("function Request:_checkReply(player, use_ai)")
loadMethod("function Request:_finish()")

local request = setmetatable({
  room = room, command = "AskForAG",
  data = { [player.id] = { { 101, 102 }, false, "integrated" } },
  players = { player }, send_success = {}, pending_requests = {},
  result = {}, default_reply = {}, timeout = 10, timestamp = 7001,
  send_encode = true, receive_decode = true,
}, { __index = requestMethods })

request:_sendPacket(player)
assert(#controller.requests == 1 and controller.currentThinking == true)
local wireBytes = controller.requests[1].payload
assert(type(wireBytes) == "string", "Request must send candidate CBOR bytes")
local envelope = cbor.decode(wireBytes)
assert(envelope.cardWireVersion == 1 and type(envelope.payload) == "table" and
  type(envelope.choices) == "table" and #envelope.choices == 2)
assert(type(envelope.payload[1][1]) == "string" and
  envelope.payload[1][1]:sub(1, 2) == "h:",
  "AskForAG payload must not carry a canonical hidden card ID")
assert(type(envelope.choices[1].standing) == "string" and
  envelope.choices[1].standing:sub(1, 2) == "h:",
  "AskForAG standing reference must remain opaque")

-- Decode the same envelope using the actual candidate client request module,
-- then map the displayed local numeric alias back to the one-shot wire token.
local Refs = assert(dofile(coreRoot .. "/ltk/client/card_wire_refs.lua"))
local Requests = assert(dofile(coreRoot .. "/ltk/client/card_wire_requests.lua"))
local clientRoom = { card_wire_version = 1, card_wire_refs = Refs.new() }
local localPayload = Requests.receive(clientRoom, "AskForAG", envelope)
local localCard = localPayload[1][1]
assert(type(localCard) == "number" and clientRoom.card_wire_refs:isHiddenLocal(localCard),
  "client request bridge must expose a local opaque alias")
local replyToken = Requests.encodeReply(clientRoom, localCard)
assert(type(replyToken) == "string" and replyToken:sub(1, 2) == "h:",
  "client request reply must reverse to a one-shot token")

controller.reply = cbor.encode(replyToken)
local resolved = request:_checkReply(player, false)
assert(resolved == 101, "candidate resolver must return canonical card ID to game logic")
assert(controller.currentThinking == false)

-- Completion cleanup is the actual candidate Request:_finish body; the
-- consumed one-shot choice is harmless to cancel and the context must vanish.
request:_finish()
assert(request._cardWireRequests == nil and room.current_request == nil)

-- A trusted/AI seat can receive the same logical request after a human
-- transport loss. Its native SmartAI reply is already in upstream shape and
-- must not pass through the human token resolver. Before the discriminator,
-- a non-table card field raised the same malformed card-use error seen during
-- controlled reconnect cleanup.
local resolveCallsBeforeAi = room.resolveCalls
local aiRequest = setmetatable({
  room = room, command = "PlayCard", data = { [robotPlayer.id] = nil },
  players = { robotPlayer }, send_success = {}, pending_requests = {},
  result = {}, default_reply = {}, timeout = 10, timestamp = 7002,
  send_encode = true, receive_decode = true,
}, { __index = requestMethods })
aiRequest:_sendPacket(robotPlayer)
local aiOk, aiReply = pcall(function() return aiRequest:_checkReply(robotPlayer, true) end)
assert(aiOk, "AI reply must bypass the human card-wire resolver")
assert(type(aiReply) == "table" and aiReply.card == false,
  "AI reply must remain in upstream shape")
assert(room.resolveCalls == resolveCallsBeforeAi,
  "AI reply must not consume a human request token")
aiRequest:_finish()

print("PASS integrated candidate Request Lua CBOR wire: actual Request send " ..
  "projection/decode, client local-alias/reverse-token, canonical resolver reply; " ..
  "4 cases; native C++/browser/two-account NOT RUN")
