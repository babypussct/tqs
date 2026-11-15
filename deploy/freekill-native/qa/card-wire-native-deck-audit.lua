-- Audit decoded bytes captured at the native WebSocket boundary. Never print
-- the payload, identifiers, decoder errors, or arbitrary fields on failure.
local core, command, audience, physicalSeat = ...
local categoryNames = {
  "prepare_order", "shuffle_order", "sync_order", "change_area_order",
  "hidden_move_id", "observe_hidden_move_id", "special_pile_id",
  "reconnect_deck", "reconnect_hand", "reconnect_special", "observe_deck", "observe_hand",
}
-- freekill-core/ltk/core/card.lua. Keep the wire audit aligned with the
-- actual native Card enum, especially draw (6) versus discard (7).
local PlayerSpecial = 4
local DrawPile = 6
local DiscardPile = 7
local Void = 8
local publicDestinations = { [2] = true, [3] = true, [5] = true,
  [DiscardPile] = true, [Void] = true }
local function fields(value, allowed)
  assert(type(value) == "table")
  for key in pairs(value) do assert(allowed[key]) end
end
local function count(value)
  assert(type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 8192)
end
local function dense(value)
  assert(type(value) == "table")
  local size = 0
  for key in pairs(value) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1)
    size = size + 1
  end
  assert(size == #value and size <= 8192)
end
local function deck(value)
  fields(value, { count = true }); count(value.count)
end
local function refs(value)
  assert(type(value) == "table")
  local size = 0
  for key, ref in pairs(value) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1)
    assert((type(ref) == "number" and ref % 1 == 0 and (ref >= 1 or ref <= -2)) or
      (type(ref) == "string" and #ref >= 18 and #ref <= 128 and ref:match("^h:[%w_-]+$")))
    size = size + 1
  end
  assert(size == #value and size <= 8192)
end
local function hiddenRefs(value)
  refs(value)
  for _, ref in ipairs(value) do assert(type(ref) == "string") end
end
local function validSeat(id)
  return type(id) == "number" and id % 1 == 0 and id >= 1 and id <= 2147483647
end
local function audit(name, value, viewer)
  assert(viewer == "observer" or validSeat(viewer))
  local observer = viewer == "observer"
  local coverage = {}
  local function credit(category, size)
    if size > 0 then coverage[category] = (coverage[category] or 0) + 1 end
  end
  if name == "PrepareDrawPile" or name == "ShuffleDrawPile" or name == "SyncDrawPile" then
    deck(value)
    credit(({ PrepareDrawPile = "prepare_order", ShuffleDrawPile = "shuffle_order",
      SyncDrawPile = "sync_order" })[name], value.count)
  elseif name == "ChangeCardArea" then
    fields(value, { count = true, area = true, areaCount = true, retiredRefs = true, areaRefs = true })
    count(value.count); count(value.areaCount)
    if value.area == DrawPile then
      assert(value.areaRefs == nil); refs(value.retiredRefs)
      credit("change_area_order", value.areaCount)
    else
      assert(value.area == DiscardPile or value.area == Void)
      assert(value.retiredRefs == nil); refs(value.areaRefs)
      assert(#value.areaRefs == value.areaCount)
    end
  elseif name == "Reconnect" or name == "Observe" then
    assert((name == "Observe") == observer)
    fields(value, { cardWireVersion = true, payload = true })
    assert(value.cardWireVersion == 1 and type(value.payload) == "table")
    assert(type(value.payload.card_manager) == "table")
    fields(value.payload.card_manager, {draw_pile = true, discard_pile = true,
      processing_area = true, void = true, printed_cards = true, card_marks = true})
    deck(value.payload.card_manager.draw_pile)
    credit(name == "Observe" and "observe_deck" or "reconnect_deck",
      value.payload.card_manager.draw_pile.count)
    do
      -- A standalone physical observer owns none of the seated hands or
      -- private piles. Public equip/judge/piles may remain canonical.
      assert(type(value.payload.players) == "table")
      if name == "Reconnect" then
        assert(value.payload.you == viewer and value.payload.players[viewer])
      end
      for id, player in pairs(value.payload.players) do
        assert(type(id) == "number" and id % 1 == 0)
        assert(type(player.player_cards) == "table" and type(player.special_cards) == "table")
        local owned = not observer and id == viewer
        if owned then refs(player.player_cards[1])
        else
          hiddenRefs(player.player_cards[1])
          credit(name == "Observe" and "observe_hand" or "reconnect_hand", #player.player_cards[1])
        end
        for pile, ids in pairs(player.special_cards) do
          assert(type(pile) == "string")
          if pile:sub(1, 1) == "$" and not owned then
            hiddenRefs(ids)
            if name == "Reconnect" then credit("reconnect_special", #ids) end
          end
        end
      end
    end
  elseif name == "SetPlayerPile" then
    assert(type(value) == "table" and #value == 3)
    fields(value, {[1] = true, [2] = true, [3] = true})
    assert(validSeat(value[1]))
    assert(type(value[2]) == "string" and #value[2] > 0)
    refs(value[3])
    if value[2]:sub(1, 1) == "$" then
      if viewer ~= value[1] then
        hiddenRefs(value[3]); credit("special_pile_id", #value[3])
      end
    end
  elseif name == "MoveCards" then
    assert(type(value) == "table" and #value == 2)
    fields(value, {[1] = true, [2] = true})
    assert(type(value[2]) == "number" and value[2] % 1 == 0)
    dense(value[1])
    for _, move in ipairs(value[1]) do
      fields(move, { moveInfo = true, from = true, to = true, toArea = true,
        moveReason = true, proposer = true, skillName = true, moveVisible = true,
        specialName = true, specialVisible = true, drawPilePosition = true, visiblePlayers = true })
      assert(type(move.toArea) == "number" and move.toArea % 1 == 0)
      for _, key in ipairs({"from", "to", "proposer", "moveReason", "drawPilePosition"}) do
        local id = move[key]
        assert(id == nil or (type(id) == "number" and id % 1 == 0))
      end
      assert(move.moveVisible == nil or type(move.moveVisible) == "boolean")
      assert(move.specialVisible == nil or type(move.specialVisible) == "boolean")
      assert(move.specialName == nil or type(move.specialName) == "string")
      assert(move.skillName == nil or type(move.skillName) == "string")
      local named = false
      if move.visiblePlayers ~= nil then
        if type(move.visiblePlayers) == "number" then
          assert(move.visiblePlayers % 1 == 0)
          named = move.visiblePlayers == viewer
        else
          dense(move.visiblePlayers)
          for _, seat in ipairs(move.visiblePlayers) do
            assert(type(seat) == "number" and seat % 1 == 0)
            if seat == viewer then named = true end
          end
        end
      end
      local public = publicDestinations[move.toArea]
      local shown = move.moveVisible == true or (move.moveVisible == nil and public) or
        (move.specialVisible == true and public)
      if move.toArea == DrawPile or (move.toArea == PlayerSpecial and type(move.specialName) == "string" and
          move.specialName:sub(1, 1) == "$") then shown = false end
      local authorized = not observer and (move.from == viewer or move.to == viewer or named)
      if move.toArea == DrawPile then authorized = false end
      dense(move.moveInfo)
      for _, info in ipairs(move.moveInfo) do
        fields(info, {cardId = true, fromArea = true, fromSpecialName = true, cardWireRetiredRefs = true})
        assert(info.cardId ~= nil and type(info.fromArea) == "number" and
          info.fromArea % 1 == 0)
        assert(info.fromSpecialName == nil or type(info.fromSpecialName) == "string")
        refs({info.cardId})
        if not (shown or authorized) then
          hiddenRefs({info.cardId})
          credit(observer and "observe_hidden_move_id" or "hidden_move_id", 1)
        end
        if info.cardWireRetiredRefs then refs(info.cardWireRetiredRefs) end
      end
    end
  else error("unsupported") end
  return coverage
end

if core == "--self-test" then return audit end
local ok, coverage = pcall(function()
  assert(core and command)
  local cbor = assert(dofile(core .. "/lua/server/rpc/cbor.lua"))
  local hex = io.read("*a")
  assert(#hex <= 16 * 1024 * 1024 and #hex % 2 == 0 and not hex:find("[^a-f0-9]"))
  local raw = hex:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end)
  local decoded = cbor.decode(raw)
  if command == "Setup" and audience == "identity" then
    assert(type(decoded) == "table" and (#decoded == 3 or #decoded == 4))
    fields(decoded, {[1] = true, [2] = true, [3] = true, [4] = true})
    assert(validSeat(decoded[1]) and type(decoded[2]) == "string" and
      decoded[2] == os.getenv("TQS_PRIVACY_EXPECTED_ACCOUNT") and
      type(decoded[3]) == "string")
    if decoded[4] ~= nil then assert(type(decoded[4]) == "number") end
    return { identity = decoded[1] }
  end
  local viewer = audience == "observer" and "observer" or tonumber(physicalSeat)
  return audit(command, decoded, viewer)
end)
if not ok then io.stderr:write("native deck privacy audit rejected packet\n"); os.exit(2) end
if coverage.identity then print("IDENTITY=" .. coverage.identity); return end
local metadata = { "PASS" }
for _, name in ipairs(categoryNames) do metadata[#metadata + 1] = name .. "=" .. (coverage[name] or 0) end
print(table.concat(metadata, ";"))
