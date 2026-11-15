-- Exercise the candidate Reconnect/Observe snapshot projector and client
-- decoder with the actual candidate Lua CBOR codec. This remains a source
-- probe with QA card-handle state; native C++/browser acceptance is separate.
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

local Protocol = assert(loadfile(protocolPath))()
local Mint = assert(dofile(coreRoot .. "/lua/server/card_wire_secure_mint.lua"))
local protocol = Protocol.new(Mint.next)
local Projection = assert(dofile(coreRoot .. "/lua/server/card_wire_projection.lua"))
local Refs = assert(dofile(coreRoot .. "/ltk/client/card_wire_refs.lua"))
local Snapshots = assert(dofile(coreRoot .. "/ltk/client/card_wire_snapshots.lua"))

local ownerSocket = { audience = "integrated-snapshot-owner" }
local observerSocket = { audience = "integrated-snapshot-observer" }
local owner = {
  id = 11, _splayer = ownerSocket,
  player_cards = { [Card.PlayerHand] = { 101, 102 },
    [Card.PlayerEquip] = { 103 }, [Card.PlayerJudge] = {} },
  special_cards = { ["$secret"] = { 109 }, public = { 110 } },
}
local target = {
  id = 12, _splayer = { audience = "integrated-target" },
  player_cards = { [Card.PlayerHand] = {}, [Card.PlayerEquip] = {},
    [Card.PlayerJudge] = {} }, special_cards = {},
}
function owner:getPileNameOfId(id)
  if id == 109 then return "$secret" end
  if id == 110 then return "public" end
end
function target:getPileNameOfId() return nil end

local locations = {
  [101] = { area = Card.PlayerHand, owner = owner },
  [102] = { area = Card.PlayerHand, owner = owner },
  [103] = { area = Card.PlayerEquip, owner = owner },
  [104] = { area = Card.DrawPile },
  [105] = { area = Card.DrawPile },
  [106] = { area = Card.DiscardPile },
  [107] = { area = Card.Processing },
  [108] = { area = Card.Void },
  [109] = { area = Card.PlayerSpecial, owner = owner, pile = "$secret" },
  [110] = { area = Card.PlayerSpecial, owner = owner, pile = "public" },
}

local room = {
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  _cardWireProtocol = protocol,
}
function room:getSettings(key) return self.settings[key] end
function room:cardWireAudience(physical) return physical.audience end
function room:getPlayerById(id)
  if id == owner.id then return owner end
  if id == target.id then return target end
end
function room:getCardArea(id)
  return locations[id] and locations[id].area
end
function room:getCardOwner(id)
  return locations[id] and locations[id].owner
end

local snapshot = {
  settings = { gameMode = "new_heg_mode" },
  card_manager = {
    draw_pile = { 104, 105 },
    discard_pile = { 106 },
    processing_area = { 107 },
    void = { 108 },
    printed_cards = {},
    card_marks = cbor.encode({
      [101] = { ["@owner"] = "owner-mark" },
      [106] = { ["@public"] = "public-mark" },
      [109] = { ["@secret"] = "secret-mark" },
    }),
  },
  players = {
    [11] = {
      player_cards = {
        [Card.PlayerHand] = { 101, 102 },
        [Card.PlayerEquip] = { 103 },
        [Card.PlayerJudge] = {},
      },
      special_cards = { ["$secret"] = { 109 }, public = { 110 } },
      virtual_equips = {},
    },
    [12] = {
      player_cards = {
        [Card.PlayerHand] = {}, [Card.PlayerEquip] = {},
        [Card.PlayerJudge] = {},
      },
      special_cards = {}, virtual_equips = {},
    },
  },
}

local function project(command, physical)
  local batch = protocol:beginBatch()
  local ok, result = pcall(Projection.project, room, owner, physical,
    command, snapshot, batch)
  if not ok then
    batch:abort()
    error(result, 2)
  end
  batch:commit()
  -- Force an actual candidate CBOR encode/decode boundary before the client.
  return cbor.decode(cbor.encode(result))
end

local reconnectWire = project("Reconnect", ownerSocket)
local observeWire = project("Observe", observerSocket)
assert(reconnectWire.cardWireVersion == 1 and observeWire.cardWireVersion == 1)
assert(reconnectWire.payload.card_manager.draw_pile.count == 2 and
  reconnectWire.payload.card_manager.draw_pile[1] == nil and
  observeWire.payload.card_manager.draw_pile.count == 2 and
  observeWire.payload.card_manager.draw_pile[1] == nil,
  "snapshot draw order must be replaced by count-only payload")

local ownerHand = reconnectWire.payload.players[11].player_cards[Card.PlayerHand]
local observerHand = observeWire.payload.players[11].player_cards[Card.PlayerHand]
assert(ownerHand[1] == 101 and ownerHand[2] == 102,
  "returning owner may receive canonical hand identities")
assert(type(observerHand[1]) == "string" and observerHand[1]:sub(1, 2) == "h:" and
  type(observerHand[2]) == "string" and observerHand[2]:sub(1, 2) == "h:" and
  observerHand[1] ~= observerHand[2],
  "observer snapshot must receive distinct opaque hand identities")
local observerMarks = cbor.decode(observeWire.payload.card_manager.card_marks)
for reference in pairs(observerMarks) do
  assert(type(reference) == "number" or
    (type(reference) == "string" and reference:sub(1, 2) == "h:"),
    "observer card-mark key must be canonical public or opaque private reference")
end

local ownerRoom = {
  card_wire_version = 1,
  card_wire_refs = Refs.new(),
  draw_pile = {},
}
function ownerRoom:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
end
local ownerLocalized = Snapshots.receive(ownerRoom, reconnectWire)
assert(#ownerLocalized.card_manager.draw_pile == 2 and
  ownerRoom.card_wire_refs:isAnonymous(ownerLocalized.card_manager.draw_pile[1]) and
  ownerLocalized.players[11].player_cards[Card.PlayerHand][1] == 101 and
  ownerLocalized.players[11].special_cards["$secret"][1] == 109,
  "owner snapshot decoder must preserve authorized local/card-manager state")

local observerRoom = {
  card_wire_version = 1,
  card_wire_refs = Refs.new(),
  draw_pile = {},
}
function observerRoom:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
end
local observerLocalized = Snapshots.receive(observerRoom, observeWire)
local observerLocal = observerLocalized.players[11].player_cards[Card.PlayerHand][1]
assert(type(observerLocal) == "number" and
  observerRoom.card_wire_refs:isHiddenLocal(observerLocal) and
  observerLocalized.players[11].special_cards["$secret"][1] ~= 109 and
  observerRoom.card_wire_refs:isHiddenLocal(observerLocalized.players[11].special_cards["$secret"][1]),
  "observer snapshot decoder must localize private hand/special refs")
assert(observerLocalized.card_manager.card_marks ~= nil and
  observerRoom.card_wire_refs.byLocal[observerLocal] ~= nil,
  "observer snapshot decoder must localize card-mark/session references")

print("PASS integrated candidate snapshot Lua CBOR wire: actual Reconnect/Observe " ..
  "projection/decode, count-only deck, owner/observer private refs and card-mark " ..
  "localization; 4 cases; native C++/browser/two-account NOT RUN")
