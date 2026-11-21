-- Execute the candidate client snapshot decoder with real card-wire alias
-- module code. This is synthetic source/client evidence, not native CBOR or
-- browser acceptance.
local root = assert(arg[1], "candidate core root required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

Card = { PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3 }
local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local Snapshots = dofile(root .. "/ltk/client/card_wire_snapshots.lua")

local function clone(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[clone(key)] = clone(item) end
  return result
end

local encoded = {}
local encodeSequence = 0
cbor = {
  encode = function(value)
    encodeSequence = encodeSequence + 1
    local key = "cbor:" .. tostring(encodeSequence)
    encoded[key] = clone(value)
    return key
  end,
  decode = function(value)
    assert(type(value) == "string" and encoded[value], "fixture CBOR value missing")
    return clone(encoded[value])
  end,
}

local sequence = 0
local refs = Refs.new(function() return false end)
local room = {
  card_wire_version = 1,
  card_wire_refs = refs,
  draw_pile = {},
  card_place = {},
  settings = { gameMode = "new_heg_mode" },
}
function room:getSettings(key) return self.settings[key] end

local function opaque(name)
  sequence = sequence + 1
  return "h:snapshot_" .. name .. "_" .. string.format("%08d", sequence)
end

local hiddenHand = opaque("hand")
local hiddenPile = opaque("pile")
local marked = opaque("mark")
local envelope = {
  cardWireVersion = 1,
  payload = {
    settings = { gameMode = "new_heg_mode" },
    card_manager = {
      draw_pile = { count = 3 },
      discard_pile = { 101, 102 },
      processing_area = { 103 },
      void = { -2 },
      printed_cards = {},
      card_marks = cbor.encode({ [marked] = { visible = true }, [102] = { public = 1 } }),
    },
    players = {
      [1] = {
        player_cards = { [Card.PlayerHand] = { hiddenHand },
          [Card.PlayerEquip] = { 101 }, [Card.PlayerJudge] = {} },
        special_cards = { ["$secret"] = { hiddenPile }, public = { 102 } },
        virtual_equips = {},
      },
    },
  },
}

local result = Snapshots.receive(room, envelope)
room.draw_pile = result.card_manager.draw_pile
assert(#result.card_manager.draw_pile == 3)
assert(refs:isAnonymous(result.card_manager.draw_pile[1]))
assert(result.card_manager.discard_pile[1] == 101)
assert(result.players[1].player_cards[Card.PlayerHand][1] ~= hiddenHand)
assert(refs:isHiddenLocal(result.players[1].player_cards[Card.PlayerHand][1]))
assert(result.players[1].player_cards[Card.PlayerEquip][1] == 101)
assert(result.players[1].special_cards["$secret"][1] ~= hiddenPile)
assert(result.players[1].special_cards.public[1] == 102)
local marks = cbor.decode(result.card_manager.card_marks)
assert(marks[102] ~= nil)
assert(next(marks) ~= marked and next(marks) ~= hiddenHand)

local oldDraw = result.card_manager.draw_pile[1]
local oldHand = result.players[1].player_cards[Card.PlayerHand][1]
local malformed = clone(envelope)
malformed.payload.card_manager.draw_pile = { count = 1, extra = true }
assert(not pcall(function() Snapshots.receive(room, malformed) end),
  "snapshot decoder must reject extra count fields")
assert(refs:isAnonymous(oldDraw) and refs:isHiddenLocal(oldHand),
  "malformed snapshot must not mutate the installed local state")

local activeRequest = {}
room.card_wire_request = activeRequest
local previousNextLocal = refs.nextLocal
-- The preceding snapshot's references cannot be reused in a new session.
-- Rejection during localization must preserve the installed request and aliases.
assert(not pcall(Snapshots.receive, room, envelope))
assert(room.card_wire_request == activeRequest and refs.nextLocal == previousNextLocal)
assert(refs:isAnonymous(oldDraw) and refs:toWire(oldHand) == envelope.payload.players[1].player_cards[1][1])

local refreshed = clone(envelope)
refreshed.payload.card_manager.draw_pile = { count = 1 }
local refreshedHand = opaque("hand_refresh")
local refreshedPile = opaque("pile_refresh")
local refreshedMark = opaque("mark_refresh")
refreshed.payload.players[1].player_cards[Card.PlayerHand] = { refreshedHand }
refreshed.payload.players[1].special_cards["$secret"] = { refreshedPile }
refreshed.payload.card_manager.card_marks = cbor.encode({
  [refreshedMark] = { visible = true }, [102] = { public = 1 },
})
local nextSnapshot = Snapshots.receive(room, refreshed)
assert(nextSnapshot.card_manager.draw_pile[1] ~= oldDraw,
  "reconnect snapshot must not recycle local deck aliases")
assert(not pcall(function() refs:toWire(oldHand) end),
  "reconnect snapshot must retire old hidden aliases")

local cold = { card_wire_version = 1, draw_pile = {} }
function cold:getSettings() return nil end
local coldSnapshot = Snapshots.receive(cold, envelope)
assert(cold.card_wire_refs:isHiddenLocal(coldSnapshot.players[1].player_cards[1][1]),
  "fresh observer must localize before enterRoom has selected its game mode")
local wrongMode = clone(envelope)
wrongMode.payload.settings.gameMode = "identity"
assert(not pcall(Snapshots.receive, cold, wrongMode),
  "cold snapshot must validate its authoritative mode before mutation")
Snapshots.dispatch(cold, function(client)
  assert(client._card_wire_snapshot.refs == client.card_wire_refs)
end, coldSnapshot)
assert(cold._card_wire_snapshot == nil, "snapshot capability must expire after dispatch")
assert(not pcall(Snapshots.dispatch, cold, function() error("synthetic callback failure") end, coldSnapshot))
assert(cold._card_wire_snapshot == nil, "failed callback must not leave a room-transfer capability")

room.card_wire_version = nil
assert(not pcall(function() Snapshots.receive(room, envelope) end),
  "legacy mode must not accept projected snapshot envelopes")
print("PASS candidate client snapshots: count-only deck, public/opaque player " ..
  "refs, card-mark localization, session reset, malformed/legacy fail-close; " ..
  "synthetic-only; native/browser NOT RUN")
