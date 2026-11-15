-- Run the actual patched ServerPlayerBase:doNotify with synthetic physical
-- sockets and stub CBOR. This tests only the transport dispatch seam.
local root, protocolFile = ...
assert(root and protocolFile, "candidate root and contract module required")
local Protocol = assert(loadfile(protocolFile))()
local nextToken = 0
local opaque = Protocol.new(function()
  nextToken = nextToken + 1
  return string.format("h:wire_fixture_%016x", nextToken)
end)

local function copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do out[copy(k)] = copy(v) end
  return out
end

local sourceFile = assert(io.open(root .. "/lua/server/serverplayer_base.lua", "rb"))
local source = assert(sourceFile:read("*a"))
sourceFile:close()
local start = assert(source:find("function ServerPlayerBase:doNotify(command, data)", 1, true))
local finish = assert(source:find("\nend\n", start, true))
local playerMethods = {}
local nativeTable = setmetatable({
  contains = function(t, value)
    for _, current in ipairs(t) do if current == value then return true end end
    return false
  end,
  find = function(t, predicate)
    for _, item in ipairs(t) do if predicate(item) then return item end end
    return nil
  end,
  removeOne = function(t, value)
    for i, item in ipairs(t) do
      if item == value then return table.remove(t, i) end
    end
  end,
}, { __index = table })
local failNegotiationEncoding = false
local env = setmetatable({
  ServerPlayerBase = playerMethods,
  fk = { Player_Robot = "robot" },
  cbor = { encode = function(data)
    if failNegotiationEncoding and type(data) == "table" and
        data.protocol == "TQS_HEG_CARD_WIRE" then
      error("fixture: negotiation encoding rejected")
    end
    if type(data) == "table" and data.fixtureEncodeFail then
      error("fixture: CBOR encoding rejected last recipient")
    end
    return copy(data)
  end },
  table = nativeTable,
}, { __index = _G })
assert(load(source:sub(start, finish + 4), "=candidate/wire/dispatch", "t", env))()
local function loadMethod(signature)
  local head = assert(source:find(signature, 1, true), "candidate method missing: " .. signature)
  local tail = assert(source:find("\nend\n", head, true))
  assert(load(source:sub(head, tail + 4), "=candidate/wire/reconnect", "t", env))()
end
loadMethod("function ServerPlayerBase:doNotifyToPhysical(command, data, physical)")
loadMethod("function ServerPlayerBase:reconnect()")
assert(source:find('self:doNotifyToPhysical("Reconnect", summary, sp)', 1, true),
  "reconnect callsite must use the targeted physical socket")

local function physical(audience, state)
  local socket = { audience = audience, state = state or "online", packets = {} }
  function socket:getState() return self.state end
  function socket:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, data = copy(payload) }
  end
  return socket
end
local seat = physical("owner/socket-1")
local watcher = physical("observer/socket-2")
local robot = physical("robot/socket-3", "robot")
local secondController = physical("controller/socket-5")
local room = {
  settings = { gameMode = "new_heg_mode" },
  notify_count = 0, notify_max = 100,
  main_co = coroutine.create(function() end),
  observers = { { 1, watcher }, { 2, physical("unrelated/socket-4") } },
  room = { hasObserver = function() return true end },
}
function room:getSettings(name) return self.settings[name] end
function room:delay() error("unexpected delay") end
local host = setmetatable({ id = 1, _observers = { seat, secondController, robot }, room = room },
  { __index = playerMethods })
local function notify(command, data) playerMethods.doNotify(host, command, data) end
local function rejected(fn)
  local ok = pcall(fn)
  assert(not ok, "expected candidate dispatcher to fail closed")
end
local original = { { { moveInfo = { { cardId = 829 } }, moveVisible = false } }, 7 }

-- Fail closed rather than copy a raw CBOR when an opt-in protocol lacks a
-- projector or has an unknown version/mode.
room.card_wire_version = 1
rejected(function() notify("MoveCards", original) end)
assert(#seat.packets == 0 and #secondController.packets == 0 and #watcher.packets == 0)
local encodeFailureAt
room.projectCardWire = function(_, _, socket, _, data, batch)
  assert(batch and type(batch.reference) == "function",
    "projection must receive the active handle transaction")
  local projected = copy(data)
  if type(projected) == "table" and type(projected[1]) == "table"
      and type(projected[1][1]) == "table" and projected[1][1].moveInfo then
    local id = projected[1][1].moveInfo[1].cardId
    projected[1][1].moveInfo[1].cardId = batch:reference(socket.audience, id, false)
  end
  if encodeFailureAt == socket then projected.fixtureEncodeFail = true end
  return projected
end
rejected(function() notify("MoveCards", original) end)
assert(#seat.packets == 0 and opaque.audiences[seat.audience] == nil,
  "opt-in wire without beginCardWireBatch must fail before any mint")
function room:beginCardWireBatch() return opaque:beginBatch() end
room.card_wire_version = 2
rejected(function() notify("MoveCards", original) end)
room.card_wire_version = 1
room.settings.gameMode = "other_mode"
rejected(function() notify("MoveCards", original) end)
room.settings.gameMode = "new_heg_mode"

-- If a later spectator projection fails, the earlier seat must not receive a
-- partial event. No pacing counter may be consumed before staging succeeds.
local originalProjector = room.projectCardWire
local baseProjector = originalProjector
room.projectCardWire = function(roomRef, sourceSeat, socket, command, data, batch)
  if command == "Reconnect" then
    -- The snapshot must mint a new session namespace for only this physical
    -- socket. A later encoding failure will abort this staged reset.
    batch:resetAudience(socket.audience)
  end
  return baseProjector(roomRef, sourceSeat, socket, command, data, batch)
end
originalProjector = room.projectCardWire
local stable = opaque:issueChoice(seat.audience, "pending-choice", {
  { id = 811, public = false },
})[1]
room.projectCardWire = function(roomRef, sourceSeat, socket, command, data, batch)
  if socket == watcher then error("fixture: spectator projection rejected") end
  return originalProjector(roomRef, sourceSeat, socket, command, data, batch)
end
rejected(function() notify("MoveCards", original) end)
local tombstone = string.format("h:wire_fixture_%016x", nextToken)
assert(#seat.packets == 0 and #secondController.packets == 0
    and #watcher.packets == 0 and room.notify_count == 0,
  "projector failure must abort every physical delivery before sending")
assert(opaque.audiences[seat.audience].byId[829] == nil
    and opaque.audiences[secondController.audience] == nil
    and opaque.audiences[watcher.audience] == nil
    and opaque.audiences[seat.audience].requests["pending-choice"] ~= nil
    and opaque.issued[tombstone],
  "late projector failure must rollback all recipients while tombstoning issued tokens")
room.projectCardWire = originalProjector

-- The encoder is also part of preflight; failure at the final spectator may
-- not install any mapping even though every projector returned successfully.
encodeFailureAt = watcher
local beforeCbor = nextToken
rejected(function() notify("MoveCards", original) end)
assert(nextToken > beforeCbor and opaque.issued[string.format("h:wire_fixture_%016x", nextToken)]
    and opaque.audiences[seat.audience].byId[829] == nil
    and opaque.audiences[secondController.audience] == nil
    and opaque.audiences[watcher.audience] == nil
    and #seat.packets == 0 and #secondController.packets == 0
    and #watcher.packets == 0 and room.notify_count == 0,
  "late CBOR encoder failure must abort every staged handle and packet")
encodeFailureAt = nil
assert(opaque:resolveChoice(seat.audience, "pending-choice", { stable }, function() return true end)[1] == 811,
  "failed notification transactions must preserve previously issued requests")

notify("MoveCards", original)
assert(room.notify_count == 2, "only controlling physical sockets count toward pacing")
assert(#seat.packets == 1 and #secondController.packets == 1
    and #watcher.packets == 1 and #robot.packets == 0)
local a = seat.packets[1].data[1][1].moveInfo[1].cardId
local b = watcher.packets[1].data[1][1].moveInfo[1].cardId
local c = secondController.packets[1].data[1][1].moveInfo[1].cardId
assert(type(a) == "string" and type(b) == "string" and type(c) == "string"
    and a ~= b and a ~= c and b ~= c,
  "separate physical CBOR projections must conceal original card IDs")
assert(opaque.audiences[seat.audience].byId[829] == a
    and opaque.audiences[secondController.audience].byId[829] == c
    and opaque.audiences[watcher.audience].byId[829] == b,
  "successful batch must commit every physical mapping before sending")
assert(original[1][1].moveInfo[1].cardId == 829,
  "per-recipient projection must not mutate native source state")

notify("MoveCards", original)
assert(seat.packets[2].data[1][1].moveInfo[1].cardId == a and
  watcher.packets[2].data[1][1].moveInfo[1].cardId == b and
  secondController.packets[2].data[1][1].moveInfo[1].cardId == c,
  "same audience/zone must have stable handles")

-- Default route remains unchanged until server and client can both negotiate.
room.card_wire_version = nil
notify("MoveCards", original)
assert(seat.packets[3].data[1][1].moveInfo[1].cardId == 829 and
  watcher.packets[3].data[1][1].moveInfo[1].cardId == 829 and
  secondController.packets[3].data[1][1].moveInfo[1].cardId == 829,
  "legacy wire must preserve its prior behavior before opt-in")

-- Exercise the actual reconnect method with a second controlling physical
-- connection. V1 must send the private summary only to the returning socket.
room.card_wire_version = 1
rejected(function() notify("Reconnect", original) end)
host._splayer = seat
rejected(function()
  host:doNotifyToPhysical("Reconnect", original, watcher)
end)
assert(#seat.packets == 3 and #watcher.packets == 3,
  "non-returning physical socket must fail before a Reconnect delivery")

-- A reconnect projector or encoder failure must not commit private handles
-- to the returning physical socket, and must not notify anyone.
local privateSnapshot = { { { moveInfo = { { cardId = 930 } }, moveVisible = false } }, 7 }
local reconnectOldChoice = opaque:issueChoice(seat.audience, "reconnect/pending", {
  { id = 829, public = false },
})[1]
room.projectCardWire = function(roomRef, sourceSeat, socket, command, data, batch)
  local projection = originalProjector(roomRef, sourceSeat, socket, command, data, batch)
  if command == "Reconnect" then error("fixture: reconnect projection rejected") end
  return projection
end
rejected(function() host:doNotifyToPhysical("Reconnect", privateSnapshot, seat) end)
assert(opaque.audiences[seat.audience].byId[930] == nil
    and opaque.audiences[seat.audience].requests["reconnect/pending"] ~= nil
    and #seat.packets == 3 and #secondController.packets == 3
    and #watcher.packets == 3,
  "reconnect projector failure must rollback private handle state and packets")
room.projectCardWire = originalProjector
encodeFailureAt = seat
rejected(function() host:doNotifyToPhysical("Reconnect", privateSnapshot, seat) end)
assert(opaque.audiences[seat.audience].byId[930] == nil
    and opaque.audiences[seat.audience].requests["reconnect/pending"] ~= nil
    and #seat.packets == 3 and #secondController.packets == 3
    and #watcher.packets == 3,
  "reconnect CBOR failure must rollback private handle state and packets")
encodeFailureAt = nil

room.players = { host }
failNegotiationEncoding = true
rejected(function() host:doNotifyToPhysical("Reconnect", privateSnapshot, seat) end)
assert(opaque.audiences[seat.audience].byId[930] == nil and
  opaque.audiences[seat.audience].requests["reconnect/pending"] ~= nil and
  #seat.packets == 3, "negotiation encoding failure must roll back snapshot and delivery")
failNegotiationEncoding = false
function room:serialize() return original end
function room:broadcastProperty() end
function room.room:getOwner() return { getId = function() return 1 end } end
host:reconnect()
assert(#seat.packets == 6 and seat.packets[4].command == "CardWireNegotiated"
    and seat.packets[5].command == "Reconnect" and seat.packets[6].command == "RoomOwner",
  "cold reconnect must negotiate before the seat summary reaches its physical socket")
assert(#secondController.packets == 4 and secondController.packets[4].command == "RoomOwner"
    and #watcher.packets == 4 and watcher.packets[4].command == "RoomOwner",
  "other controlling sockets and observers must not receive a reconnect summary")
local refresh = seat.packets[5].data[1][1].moveInfo[1].cardId
assert(type(refresh) == "string" and refresh ~= a
    and opaque.audiences[seat.audience].byId[829] == refresh,
  "reconnect must mint a fresh physical-session reference after the reset commits")
assert(opaque:resolveChoice(seat.audience, "reconnect/pending", { reconnectOldChoice },
  function() return true end) == nil,
  "successful reconnect must expire previous session request allowlists")
assert(opaque.audiences[secondController.audience].byId[829] == c
    and opaque.audiences[watcher.audience].byId[829] == b,
  "reconnect must preserve other physical audiences watching the same seat")

print("PASS candidate physical-recipient CBOR dispatcher: independent seat/observer " ..
  "projection, multi-recipient atomic rollback on projector/CBOR failure, fail-closed opt-in, physical reconnect, robot/legacy; " ..
  "synthetic-only; native/browser NOT RUN")
