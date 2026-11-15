-- Exercise the candidate server dispatcher and client callback across the
-- candidate's actual Lua CBOR codec. This is still a source probe: the
-- protocol contract is QA-only, and native C++/browser/two-account runtime
-- acceptance remain separate.
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

-- Use the exact candidate codec used by the server/client runtime. The
-- projector reads these as globals, matching freekill.lua's initialization.
cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))

Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3,
  PlayerSpecial = 4, Processing = 5, DiscardPile = 6,
  DrawPile = 7, Void = 8,
}

local Protocol = assert(loadfile(protocolPath))()
local Mint = assert(dofile(coreRoot .. "/lua/server/card_wire_secure_mint.lua"))
local protocol = Protocol.new(Mint.next)
local Projection = assert(dofile(coreRoot .. "/lua/server/card_wire_projection.lua"))

local function cardObject(values)
  local card = values or {}
  card.class = true
  function card:isInstanceOf(class) return class == Card end
  return card
end

local real = cardObject({ id = 101, name = "slash" })
function real:isVirtual() return false end

local virtual = cardObject({
  id = 0, name = "slash", suit = 1, number = 7, color = 1,
  subcards = { 101 }, skillNames = { "integrated_probe" },
  virt_id = 7001, mark = { ["@integrated"] = 1 },
})
function virtual:isVirtual() return true end

local settings = { gameMode = "new_heg_mode" }
local owner = { audience = "integrated-owner", packets = {}, state = "online" }
local observer = { audience = "integrated-observer", packets = {}, state = "online" }
for _, physical in ipairs({ owner, observer }) do
  function physical:getState() return self.state end
  function physical:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, payload = payload }
  end
end

local room = {
  card_wire_version = 1,
  settings = settings,
  _cardWireProtocol = protocol,
  notify_count = 0,
  notify_max = 100,
  main_co = coroutine.create(function() end),
  observers = {},
  room = { hasObserver = function() return true end },
}
function room:getSettings(key) return self.settings[key] end
function room:cardWireAudience(physical) return physical.audience end
function room:beginCardWireBatch() return protocol:beginBatch() end
function room:getCardArea(id)
  if id == 101 then return Card.PlayerHand end
end
function room:getCardOwner(id)
  if id == 101 and self.players then return self.players[1] end
end
function room:projectCardWire(seat, physical, command, data, batch)
  return Projection.project(self, seat, physical, command, data, batch)
end

-- Load the exact candidate ServerPlayerBase:doNotify body. The only native
-- seam replaced here is the physical socket, so each payload is still encoded
-- by the candidate CBOR implementation before it is captured.
local serverMethods = {}
local nativeTable = setmetatable({
  contains = function(values, wanted)
    for _, value in ipairs(values) do
      if value == wanted then return true end
    end
    return false
  end,
}, { __index = table })
local serverEnv = setmetatable({
  ServerPlayerBase = serverMethods,
  cbor = cbor,
  fk = { Player_Robot = "robot" },
  table = nativeTable,
}, { __index = _G })
local serverSource = read(coreRoot .. "/lua/server/serverplayer_base.lua")
local serverStart = assert(serverSource:find(
  "function ServerPlayerBase:doNotify(command, data)", 1, true))
local serverEnd = assert(serverSource:find("\nend\n", serverStart, true))
assert(load(serverSource:sub(serverStart, serverEnd + 4),
  "=candidate/integrated/server-dispatch", "t", serverEnv))()

local seat = setmetatable({
  id = 11, _splayer = owner, room = room,
}, { __index = serverMethods })
room.players = { seat }

local function notify(command, data)
  serverMethods.doNotify(seat, command, data)
end

local move = {
  from = 11, to = 11, toArea = Card.PlayerHand, moveVisible = false,
  moveInfo = { { cardId = 101, fromArea = Card.PlayerHand } },
}

-- A concealed hand card is public to the owning physical connection but is
-- an opaque reference for the observer. Both values below are decoded from
-- bytes emitted by the actual candidate ServerPlayerBase method.
seat._observers = { owner, observer }
notify("MoveCards", { { move }, 9001 })
assert(#owner.packets == 1 and #observer.packets == 1)
local ownerMove = cbor.decode(owner.packets[1].payload)
local observerMove = cbor.decode(observer.packets[1].payload)
local ownerCard = ownerMove[1][1].moveInfo[1].cardId
local observerCard = observerMove[1][1].moveInfo[1].cardId
assert(ownerCard == 101, "owner CBOR payload must keep its authorized canonical ID")
assert(type(observerCard) == "string" and observerCard:sub(1, 2) == "h:",
  "observer CBOR payload must carry an opaque reference")
assert(move.moveInfo[1].cardId == 101,
  "per-physical projection must not mutate the native source event")

-- A second notification exercises stable per-audience state through another
-- real encode/decode cycle; it must not mint a new handle for the same view.
notify("MoveCards", { { move }, 9002 })
local observerMoveAgain = cbor.decode(observer.packets[2].payload)
assert(observerMoveAgain[1][1].moveInfo[1].cardId == observerCard,
  "same physical audience must retain its opaque reference")

-- Now send an audited public GameLog containing both a real Card object and a
-- virtual Card. The server descriptor is plain CBOR data; the client callback
-- reconstructs native cards only after decoding the explicit v1 envelope.
notify("GameLog", {
  type = "#UseCard", from = 11, to = { 12 },
  card = { real, virtual }, arg = "integrated", arg2 = real, toast = true,
})
local ownerLogWire = owner.packets[3].payload
local ownerLogEnvelope = cbor.decode(ownerLogWire)
assert(ownerLogEnvelope.cardWireVersion == 1 and
  type(ownerLogEnvelope.payload) == "table")
assert(ownerLogEnvelope.payload.card[1].kind == "real" and
  ownerLogEnvelope.payload.card[1].ref == 101 and
  ownerLogEnvelope.payload.card[2].kind == "virtual" and
  ownerLogEnvelope.payload.card[2].subcards[1] == 101,
  "public GameLog must decode to audited descriptors, not Card userdata")

-- Minimal ClientCallback environment: this is the actual candidate callback
-- body, with the real public decoder loaded from the candidate package. No
-- legacy callback is installed so the resulting UI payload is observable.
local nativeCards = {}
local function nativeCard(id, name)
  local card = { id = id, name = name or "slash", class = true }
  function card:isInstanceOf(class) return class == Card end
  return card
end
nativeCards[101] = nativeCard(101, "slash")
Fk = {
  cards = nativeCards,
  currentResponsePattern = "stale",
  currentResponseReason = "stale",
}
function Fk:getCardById(id) return self.cards[id] end
function Fk:cloneCard(name, suit, number)
  local card = nativeCard(0, name)
  card.suit, card.number, card.color = suit, number, Card.NoColor
  card.subcards, card.skillNames, card.mark = {}, {}, {}
  return card
end

local Refs = assert(dofile(coreRoot .. "/ltk/client/card_wire_refs.lua"))
local client = {
  card_wire_version = 1,
  card_wire_refs = Refs.new(),
  callbacks = {},
  recording = false,
  replaying = false,
  notifications = {},
}
function client:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
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
  "=candidate/integrated/client-callback", "t", clientEnv))()
clientEnv.ClientCallback(nil, "GameLog", ownerLogWire, false)

assert(#client.notifications == 1 and client.notifications[1][1] == "GameLog")
local decodedLog = client.notifications[1][2]
assert(decodedLog.card[1] == nativeCards[101] and decodedLog.card[2].id == 0 and
  decodedLog.card[2].subcards[1] == 101 and decodedLog.arg2 == nativeCards[101] and
  decodedLog.toast == true, "client callback must reconstruct audited public cards")
assert(Fk.currentResponsePattern == "stale" and Fk.currentResponseReason == "stale",
  "unrelated GameLog must not mutate response-pattern state")

print("PASS integrated candidate Lua CBOR wire: actual ServerPlayerBase physical " ..
  "CBOR isolation/stability, audited public GameLog decode through ClientCallback; " ..
  "3 cases; native C++/browser/two-account NOT RUN")
