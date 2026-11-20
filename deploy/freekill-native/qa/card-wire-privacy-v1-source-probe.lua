-- Exercise the actual candidate v1 physical dispatcher for every category
-- reproduced by card-wire-exposure-source-probe.lua.  The legacy diagnostic
-- remains intentionally open while v1 is disabled; this probe proves that
-- the negotiated candidate path projects the same channels before CBOR.
-- Synthetic card IDs only. Native C++/browser/two-account acceptance remains
-- a separate gate.
local coreRoot, protocolPath, mode = ...
assert(coreRoot and protocolPath, "candidate core and protocol paths required")
assert(mode == nil or mode == "--strict", "unknown privacy probe mode")

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
  contains = function(values, wanted)
    for _, value in ipairs(values) do
      if value == wanted then return true end
    end
    return false
  end,
  map = function(values, mapper)
    local result = {}
    for index, value in ipairs(values) do result[index] = mapper(value) end
    return result
  end,
}, { __index = table })

-- Copy fixture values before a later assertion can observe a live source table.
nativeTable.clone = function(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do
    result[nativeTable.clone(key)] = nativeTable.clone(item)
  end
  return result
end

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
  Fk = {
    filterChatMessage = function(message) return message end,
    generals = { anjiang = { gender = 4, kingdom = "unknown" } },
  },
  fk = {
    Player_Robot = "robot",
    AfterDrawPileShuffle = "after-shuffle",
    qInfo = function() end,
  },
  os = setmetatable({ getms = function() return 1 end }, { __index = os }),
}, { __index = _G })

-- Load the exact candidate bodies used by the physical v1 path.  Only the
-- synthetic socket replaces the native boundary.
loadMethod("lua/server/roombase.lua",
  "function ServerRoomBase:doBroadcastNotify(command, jsonData, players)",
  baseMethods, "doBroadcastNotify", env)
if read("lua/server/roombase.lua"):find("function ServerRoomBase:publicHegemonyRole(role, shown)", 1, true) then
  loadMethod("lua/server/roombase.lua", "function ServerRoomBase:publicHegemonyRole(role, shown)",
    baseMethods, "publicHegemonyRole", env)
end
loadMethod("lua/server/roombase.lua",
  "function ServerRoomBase:serialize(player, observer)",
  baseMethods, "serialize", env)
loadMethod("lua/server/roombase.lua",
  "function ServerRoomBase:tellRoomToObserver(player)",
  baseMethods, "tellRoomToObserver", env)
loadMethod("lua/server/serverplayer_base.lua",
  "function ServerPlayerBase:doNotify(command, data)",
  serverMethods, "doNotify", env)
loadMethod("lua/server/serverplayer_base.lua",
  "function ServerPlayerBase:doNotifyToPhysical(command, data, physical)",
  serverMethods, "doNotifyToPhysical", env)
loadMethod("ltk/server/gamelogic.lua",
  "function GameLogic:prepareDrawPile()", logicMethods, "prepareDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:shuffleDrawPile()", roomMethods, "shuffleDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:syncDrawPile()", roomMethods, "syncDrawPile", env)
loadMethod("ltk/server/room.lua",
  "function Room:changeCardArea (cards, area, areaCards)", roomMethods,
  "changeCardArea", env)
loadMethod("ltk/server/room.lua",
  "function Room:setPlayerPile(player, pile, ids)", roomMethods,
  "setPlayerPile", env)
loadMethod("ltk/server/events/movecard.lua",
  "function MoveEventWrappers:notifyMoveCards(players, moveDatas, event_id)",
  moveMethods, "notifyMoveCards", env)

setmetatable(roomMethods, { __index = baseMethods })
setmetatable(serverMethods, { __index = baseMethods })

local function socket(name, id)
  local result = { name = name, id = id, audience = "v1-privacy-" .. name,
    packets = {} }
  function result:getState() return "online" end
  function result:getId() return self.id end
  function result:getScreenName() return self.name end
  function result:getAvatar() return "avatar" end
  function result:getTotalGameTime() return 0 end
  function result:getGameData() return {} end
  function result:doNotify(command, payload)
    self.packets[#self.packets + 1] = { command = command, payload = payload }
  end
  return result
end

local ownerSocket = socket("owner", 1)
local opponentSocket = socket("opponent", 2)
local observerSocket = socket("observer", 3)

local owner = {
  id = 1, _splayer = ownerSocket, _observers = { ownerSocket },
  role_shown = false, role = "hidden", general = "anjiang",
  deputyGeneral = "anjiang", gender = 4, kingdom = "unknown",
  player_cards = { [Card.PlayerHand] = { 829 },
    [Card.PlayerEquip] = {}, [Card.PlayerJudge] = {} },
  special_cards = { ["$hidden"] = { 830 }, public = { 831 } },
}
local opponent = {
  id = 2, _splayer = opponentSocket, _observers = { opponentSocket, observerSocket },
  role_shown = false, role = "hidden", general = "anjiang",
  deputyGeneral = "anjiang", gender = 4, kingdom = "unknown",
  player_cards = { [Card.PlayerHand] = {},
    [Card.PlayerEquip] = {}, [Card.PlayerJudge] = {} },
  special_cards = {},
}

function owner:getPileNameOfId(id)
  if id == 830 then return "$hidden" end
  if id == 831 then return "public" end
end
function opponent:getPileNameOfId() return nil end

local locations = {
  [811] = { area = Card.DrawPile }, [827] = { area = Card.DrawPile },
  [803] = { area = Card.DrawPile }, [829] = { area = Card.PlayerHand, owner = owner },
  [830] = { area = Card.PlayerSpecial, owner = owner, pile = "$hidden" },
  [831] = { area = Card.PlayerSpecial, owner = owner, pile = "public" },
  [832] = { area = Card.DiscardPile },
}

local function snapshotRecord(player)
  return {
    mark = cbor.encode({}), fake_skills = {}, prelighted_skills = {},
    properties = {
      role = player.role, role_shown = player.role_shown,
      general = player.general, deputyGeneral = player.deputyGeneral,
      gender = player.gender, kingdom = player.kingdom,
    },
    player_cards = {
      [Card.PlayerHand] = nativeTable.clone(player.player_cards[Card.PlayerHand]),
      [Card.PlayerEquip] = nativeTable.clone(player.player_cards[Card.PlayerEquip]),
      [Card.PlayerJudge] = nativeTable.clone(player.player_cards[Card.PlayerJudge]),
    },
    special_cards = nativeTable.clone(player.special_cards),
    virtual_equips = {},
  }
end

local function makeSnapshot()
  return {
    settings = { gameMode = "new_heg_mode" },
    card_manager = {
      draw_pile = { 811, 827, 803 }, discard_pile = { 832 },
      processing_area = {}, void = {}, printed_cards = {},
      card_marks = cbor.encode({
        [829] = { ["@private"] = "owner" },
        [830] = { ["@secret"] = "special" },
        [832] = { ["@public"] = "discard" },
      }),
    },
    players = { [1] = snapshotRecord(owner), [2] = snapshotRecord(opponent) },
  }
end

local room = {
  card_wire_version = 1, card_wire_negotiated = true,
  settings = { gameMode = "new_heg_mode" }, _cardWireProtocol = protocol,
  id = 1,
  players = { owner, opponent }, observers = {}, notify_count = 0,
  notify_max = 1000, main_co = coroutine.create(function() end),
  draw_pile = { 811, 827, 803 }, discard_pile = {}, void = {},
  logic = { trigger = function() end }, game_finished = false,
  class = { super = {} },
}
room.class.super.serialize = function() return makeSnapshot() end
setmetatable(room, { __index = roomMethods })
setmetatable(owner, { __index = serverMethods })
setmetatable(opponent, { __index = serverMethods })
owner.room, opponent.room = room, room
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
function room:getCardArea(id) return locations[id] and locations[id].area end
function room:getCardOwner(id) return locations[id] and locations[id].owner end
function room:prepareDrawPile() self.draw_pile = { 811, 827, 803 } end
function room:shuffleTable() end
function room:random() return 1 end
room.room = {
  hasObserver = function() return true end,
  getOwner = function() return ownerSocket end,
}

local function clearPackets()
  for _, physical in ipairs({ ownerSocket, opponentSocket, observerSocket }) do
    physical.packets = {}
  end
end

local function lastPacket(physical, command)
  for index = #physical.packets, 1, -1 do
    local packet = physical.packets[index]
    if packet.command == command then return cbor.decode(packet.payload) end
  end
  error("missing packet " .. command .. " for " .. physical.name)
end

local function assertOpaque(value, label)
  assert(type(value) == "string" and value:sub(1, 2) == "h:" and
    value ~= "829" and value ~= "830",
    label .. " must be opaque; observed " .. tostring(value))
end

-- Inspect the entire decoded physical CBOR packet, including map keys and
-- nested card-mark CBOR. A field-level assertion alone can miss a second,
-- unaudited copy of a canonical ID elsewhere in the same notification.
local forbiddenDeck = { [811] = true, [827] = true, [803] = true }
local forbiddenOutsider = {
  [811] = true, [827] = true, [803] = true, [829] = true, [830] = true,
}
local function assertNoCanonical(value, forbidden, label, seen)
  if type(value) == "number" then
    assert(not forbidden[value], label .. " contains an undisclosed canonical card ID")
    return
  end
  if type(value) ~= "table" then return end
  seen = seen or {}
  if seen[value] then return end
  seen[value] = true
  for key, item in pairs(value) do
    assertNoCanonical(key, forbidden, label, seen)
    assertNoCanonical(item, forbidden, label, seen)
  end
  if value.card_manager and type(value.card_manager.card_marks) == "string" then
    assertNoCanonical(cbor.decode(value.card_manager.card_marks), forbidden,
      label .. ".card_marks", seen)
  end
end

local function auditPhysicalPackets()
  for _, entry in ipairs({
    { physical = ownerSocket, forbidden = forbiddenDeck },
    { physical = opponentSocket, forbidden = forbiddenOutsider },
    { physical = observerSocket, forbidden = forbiddenOutsider },
  }) do
    for _, packet in ipairs(entry.physical.packets) do
      assert(type(packet.payload) == "string", "physical notification must be CBOR")
      assertNoCanonical(cbor.decode(packet.payload), entry.forbidden,
        entry.physical.name .. " " .. packet.command)
    end
  end
end

-- Prove this audit would reject a leak in a supplementary field or nested
-- snapshot card marks, even when the expected opaque field itself is correct.
assert(not pcall(assertNoCanonical, { ref = "h:opaque", extra = { cardId = 829 } },
  forbiddenOutsider, "adversarial extra field"), "nested leak detector is ineffective")
assert(not pcall(assertNoCanonical, {
  card_manager = { card_marks = cbor.encode({ [830] = { private = true } }) },
}, forbiddenOutsider, "adversarial nested mark"), "nested mark detector is ineffective")

local seen = {}
local function case(name, fn)
  fn()
  auditPhysicalPackets()
  seen[name] = true
end

local deck = { 811, 827, 803 }
local gameLogic = { room = room }
case("prepare_order", function()
  clearPackets(); logicMethods.prepareDrawPile(gameLogic)
  local packet = lastPacket(opponentSocket, "PrepareDrawPile")
  assert(packet.count == #deck and packet[1] == nil and packet[2] == nil)
end)
case("shuffle_order", function()
  clearPackets(); room.draw_pile = nativeTable.clone(deck)
  roomMethods.shuffleDrawPile(room)
  local packet = lastPacket(opponentSocket, "ShuffleDrawPile")
  assert(packet.count == #deck and packet[1] == nil and packet[2] == nil)
end)
case("sync_order", function()
  clearPackets(); roomMethods.syncDrawPile(room)
  local packet = lastPacket(opponentSocket, "SyncDrawPile")
  assert(packet.count == #deck and packet[1] == nil and packet[2] == nil)
end)
case("change_area_order", function()
  clearPackets(); roomMethods.changeCardArea(room, { 811 }, Card.DrawPile, deck)
  local packet = lastPacket(opponentSocket, "ChangeCardArea")
  assert(packet.count == 1 and packet.area == Card.DrawPile and
    packet.areaCount == #deck and packet[3] == nil and packet.areaRefs == nil)
end)

case("hidden_move_id", function()
  clearPackets()
  local move = {
    moveVisible = false, from = owner, to = owner,
    toArea = Card.PlayerHand,
    moveInfo = { { cardId = 829, fromArea = Card.PlayerHand } },
  }
  moveMethods.notifyMoveCards(room, { opponent }, { move }, 7001)
  assertOpaque(lastPacket(opponentSocket, "MoveCards")[1][1].moveInfo[1].cardId,
    "peer hidden MoveCards ID")
  assert(move.moveInfo[1].cardId == 829, "source MoveCards was mutated")
end)
case("observe_hidden_move_id", function()
  local packet = lastPacket(observerSocket, "MoveCards")
  assertOpaque(packet[1][1].moveInfo[1].cardId, "observer hidden MoveCards ID")
end)

case("special_pile_id", function()
  clearPackets(); roomMethods.setPlayerPile(room, owner, "$hidden", { 830 })
  assert(lastPacket(ownerSocket, "SetPlayerPile")[3][1] == 830)
  assertOpaque(lastPacket(opponentSocket, "SetPlayerPile")[3][1],
    "peer private special-pile ID")
  assertOpaque(lastPacket(observerSocket, "SetPlayerPile")[3][1],
    "observer private special-pile ID")
end)

case("reconnect_deck", function()
  clearPackets(); owner._observers = { ownerSocket }
  local summary = baseMethods.serialize(room, owner, false)
  serverMethods.doNotifyToPhysical(owner, "Reconnect", summary, ownerSocket)
  local packet = lastPacket(ownerSocket, "Reconnect")
  assert(packet.cardWireVersion == 1 and packet.payload.card_manager.draw_pile.count == 3 and
    packet.payload.card_manager.draw_pile[1] == nil)
end)
case("reconnect_hand", function()
  local packet = lastPacket(ownerSocket, "Reconnect")
  assert(packet.payload.players[1].player_cards[Card.PlayerHand][1] == 829)
end)
case("reconnect_special", function()
  local packet = lastPacket(ownerSocket, "Reconnect")
  assert(packet.payload.players[1].special_cards["$hidden"][1] == 830)
end)

case("observe_deck", function()
  clearPackets(); room.observers = {}
  baseMethods.tellRoomToObserver(room, observerSocket)
  local packet = lastPacket(observerSocket, "Observe")
  assert(packet.cardWireVersion == 1 and packet.payload.card_manager.draw_pile.count == 3 and
    packet.payload.card_manager.draw_pile[1] == nil)
end)
case("observe_hand", function()
  local packet = lastPacket(observerSocket, "Observe")
  local hand = packet.payload.players[1].player_cards[Card.PlayerHand]
  assertOpaque(hand[1], "observer snapshot hand ID")
end)

for _, name in ipairs({
  "prepare_order", "shuffle_order", "sync_order", "change_area_order",
  "hidden_move_id", "observe_hidden_move_id", "special_pile_id",
  "reconnect_deck", "reconnect_hand", "reconnect_special",
  "observe_deck", "observe_hand",
}) do
  assert(seen[name], "missing privacy case " .. name)
end

if mode == "--strict" then
  print("CARD_WIRE_PRIVACY_V1=PASS; audited_categories=12; " ..
    "entire decoded physical Lua CBOR and nested card marks; synthetic-only; " ..
    "native C++/browser/two-account NOT RUN")
else
  print("PASS candidate v1 physical privacy: actual dispatcher/CBOR " ..
    "prepare, shuffle, sync, ChangeCardArea, peer/observer MoveCards, " ..
    "private pile, Reconnect and Observe; 12 categories; " ..
    "legacy strict gate remains separate; native C++/browser/two-account NOT RUN")
end
