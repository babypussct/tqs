-- Run the actual isolated candidate Observe snapshot body with physical sockets.
-- Synthetic IDs only; this is a dispatcher seam test, not native wire privacy.
local root, protocolFile = ...
assert(root and protocolFile, "candidate core and QA protocol module required")
local Protocol = assert(loadfile(protocolFile))()
local nextToken = 0
local opaque = Protocol.new(function()
  nextToken = nextToken + 1
  return string.format("h:observe_fixture_%016x", nextToken)
end)

local function copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do out[k] = copy(v) end
  return out
end

local file = assert(io.open(root .. "/lua/server/roombase.lua", "rb"))
local source = assert(file:read("*a"))
file:close()
local signature = "function ServerRoomBase:tellRoomToObserver(player)"
local first = assert(source:find(signature, 1, true))
local last = assert(source:find("\nend\n", first, true))

local failEncoding = false
local failNegotiationEncoding = false
local env = setmetatable({
  ServerRoomBase = {},
  fk = { Player_Robot = "robot", qInfo = function() end },
  table = setmetatable({clone = copy}, { __index = table }),
  os = setmetatable({getms = function() return 42 end}, { __index = os }),
  cbor = {encode = function(data)
    if failEncoding then error("fixture CBOR encoder failed") end
    if failNegotiationEncoding and data.protocol == "TQS_HEG_CARD_WIRE" then
      error("fixture negotiation encoder failed")
    end
    return copy(data)
  end},
}, { __index = _G })
assert(load(source:sub(first, last + 4), "=candidate/observe", "t", env))()

local function socket(audience, state)
  local physical = { audience = audience, state = state or "online", packets = {} }
  function physical:getState() return self.state end
  function physical:doNotify(command, data)
    self.packets[#self.packets + 1] = { command = command, payload = copy(data) }
  end
  function physical:getScreenName() return self.audience end
  function physical:getId() return self.audience end
  return physical
end

local sourceSeat = { id = 1 }
local observerA = socket("observer/a")
local observerB = socket("observer/b")
local room = setmetatable({
  id = 42,
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  players = { sourceSeat }, observers = {},
  room = { getOwner = function() return { getId = function() return 1 end } end },
}, { __index = env.ServerRoomBase })
function room:getSettings(key) return self.settings[key] end
function room:serialize(_, observer)
  assert(observer == true, "Observe must use observer privilege when serializing")
  return { settings = { gameMode = "new_heg_mode" },
    card_manager = { draw_pile = { 811, 827 } },
    players = { { player_cards = { [1] = { 829 } } } } }
end

local function denied(fn)
  assert(not pcall(fn), "unsafe Observe path must fail closed")
end
local function noDelivery()
  assert(#room.observers == 0 and #observerA.packets == 0 and
    #observerB.packets == 0, "failed Observe cannot notify or register audience")
end

-- A v1 opt-in cannot fall back to serializing a raw observer snapshot.
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
room.projectCardWire = function() return {} end
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
function room:beginCardWireBatch() return opaque:beginBatch() end
room.card_wire_version = 2
denied(function() room:tellRoomToObserver(observerA) end)
room.card_wire_version = 1
room.settings.gameMode = "wrong_mode"
denied(function() room:tellRoomToObserver(observerA) end)
room.settings.gameMode = "new_heg_mode"
noDelivery()

local failProjection = false
local originalProjector = function(_, seat, physical, command, data, batch)
  assert(seat == sourceSeat and (physical == observerA or physical == observerB),
    "Observe must identify its actual physical socket and initial viewpoint")
  assert(command == "Observe" and data.settings.isObserver == true,
    "observer permissions must be set before projection")
  batch:resetAudience(physical.audience)
  local projected = copy(data)
  for i, id in ipairs(projected.card_manager.draw_pile) do
    projected.card_manager.draw_pile[i] = batch:reference(physical.audience, id, false)
  end
  projected.players[1].player_cards[1][1] =
    batch:reference(physical.audience, data.players[1].player_cards[1][1], false)
  if failProjection then error("fixture projector failed after mint") end
  return projected
end
room.projectCardWire = originalProjector

failProjection = true
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
assert(opaque.audiences[observerA.audience] == nil,
  "projection failure must roll back minted audience state")
failProjection = false
failEncoding = true
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
assert(opaque.audiences[observerA.audience] == nil,
  "CBOR encoding failure must roll back the observer transaction")
failEncoding = false
failNegotiationEncoding = true
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
assert(opaque.audiences[observerA.audience] == nil,
  "negotiation encoding failure must roll back the snapshot before any delivery")
failNegotiationEncoding = false

observerA.state = "robot"
denied(function() room:tellRoomToObserver(observerA) end)
noDelivery()
observerA.state = "online"

room:tellRoomToObserver(observerA)
room:tellRoomToObserver(observerB)
assert(#room.observers == 2 and #observerA.packets == 3 and
  #observerB.packets == 3 and
  observerA.packets[1].command == "CardWireNegotiated" and
  observerB.packets[1].command == "CardWireNegotiated" and
  observerA.packets[2].command == "Observe" and
  observerB.packets[2].command == "Observe" and
  observerA.packets[3].command == "RoomOwner", "cold observers must negotiate before their private snapshot")
assert(observerA.packets[1].payload.cardWireVersion == 1 and
  observerA.packets[1].payload.protocol == "TQS_HEG_CARD_WIRE")
local firstA = observerA.packets[2].payload
local firstB = observerB.packets[2].payload
local cardA = firstA.players[1].player_cards[1][1]
local cardB = firstB.players[1].player_cards[1][1]
assert(type(cardA) == "string" and type(cardB) == "string" and cardA ~= cardB and
  firstA.card_manager.draw_pile[1] ~= firstB.card_manager.draw_pile[1] and
  cardA ~= "829" and cardB ~= "829", "physical observers need independent private identifiers")
assert(opaque.audiences[observerA.audience].byId[829] == cardA and
  opaque.audiences[observerB.audience].byId[829] == cardB,
  "committed opaque handles must match the actual recipient")

local oldChoice = opaque:issueChoice(observerA.audience, "old/choice", {
  { id = 829, public = false },
})[1]
room:tellRoomToObserver(observerA)
assert(observerA.packets[4].command == "CardWireNegotiated" and
  observerA.packets[5].command == "Observe")
local newCardA = observerA.packets[5].payload.players[1].player_cards[1][1]
assert(newCardA ~= cardA and
  opaque:resolveChoice(observerA.audience, "old/choice", { oldChoice },
    function() return true end) == nil and
  opaque.audiences[observerB.audience].byId[829] == cardB,
  "new observer snapshot must reset only the returning observer's handles")

-- Legacy route must retain byte-compatible raw IDs until v1 is negotiated.
room.card_wire_version = nil
room:tellRoomToObserver(socket("observer/legacy"))
assert(room.observers[#room.observers][2].packets[1].payload.players[1].player_cards[1][1] == 829,
  "legacy Observe must preserve previous serialized payload")
print("PASS candidate direct Observe: physical-only snapshot projection, " ..
  "mode/version fail-closed, projector/CBOR rollback, independent observer " ..
  "handles, refresh reset, robot/legacy; synthetic-only; native/browser NOT RUN")
