-- Isolated Hegemony v1 client: count-only deck notifications.
-- Every local position is anonymous and is replaced at each deck sync.
-- No canonical server card ID or physical draw order is reconstructed here.
local Deck = {}
local MAX_DECK = 8192

local function deckCount(packet, command)
  assert(type(packet) == "table", command .. " must contain a count")
  for key in pairs(packet) do
    assert(key == "count", command .. " contains an unaudited field")
  end
  local count = packet.count
  assert(type(count) == "number" and count == count and
    count % 1 == 0 and count >= 0 and count <= MAX_DECK,
    command .. " has an invalid count")
  return count
end

function Deck.receive(room, command, packet)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "count-only deck requires negotiated Hegemony v1")
  assert(command == "PrepareDrawPile" or command == "ShuffleDrawPile" or
    command == "SyncDrawPile", "unaudited deck notification")
  assert(room.card_wire_refs and room.card_wire_refs.replaceAnonymousDeck,
    "v1 client-local card references are unavailable")
  local count = deckCount(packet, command)
  local previous = room.draw_pile or {}
  local replacement = room.card_wire_refs:replaceAnonymousDeck(count, previous)

  -- CardManager normally updates these maps when it receives real IDs. The
  -- anonymous deck owns only locally allocated IDs, never server identities.
  for _, id in ipairs(previous) do
    if room.card_place[id] == Card.DrawPile then
      room.card_place[id] = nil
      room.owner_map[id] = nil
    end
  end

  if command == "PrepareDrawPile" then
    room:prepareDrawPile(replacement)
  elseif command == "ShuffleDrawPile" then
    -- The core clears the public discard array when its cards are shuffled
    -- back into the anonymous deck. Retire their former area membership too.
    for _, id in ipairs(room.discard_pile or {}) do
      if room.card_place[id] == Card.DiscardPile then
        room.card_place[id] = nil
        room.owner_map[id] = nil
      end
    end
    room:shuffleDrawPile(replacement)
  else
    room.draw_pile = replacement
    for _, id in ipairs(replacement) do
      room:setCardArea(id, Card.DrawPile, nil)
    end
  end

  -- A count-only notification cannot establish card identity or deck order.
  -- Drop earlier tracking knowledge without clearing other public zones.
  for _, player in ipairs(room.players or {}) do
    local tracker = player.card_tracker
    if tracker then
      tracker.draw_pile = { known_cards = {}, uncertain_cards = {} }
      tracker.draw_pile_order = {}
      for i = 1, count do tracker.draw_pile_order[i] = -1 end
      if command == "ShuffleDrawPile" then
        tracker.discard_pile = { known_cards = {}, uncertain_cards = {} }
      end
    end
  end
  return count
end

return Deck
