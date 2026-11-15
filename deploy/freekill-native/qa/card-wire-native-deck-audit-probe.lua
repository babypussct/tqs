local path = ...
local audit = assert(loadfile(path))("--self-test")
local cases = 0
local token = "h:abcdefghijklmnop"
local token2 = "h:ponmlkjihgfedcba"

local function check(command, value, expected, viewer, category)
  local ok, result = pcall(audit, command, value, viewer)
  assert(ok == expected, "unexpected audit decision for " .. command ..
    " at case " .. (cases + 1))
  if category then
    assert(ok and (result[category] or 0) > 0,
      "missing synthetic coverage for " .. category)
  end
  cases = cases + 1
end

local function move(toArea, cardId, overrides)
  local data = { toArea = toArea, moveVisible = false,
    moveInfo = { { cardId = cardId, fromArea = 6 } } }
  for key, value in pairs(overrides or {}) do
    if key == "moveVisible" and value == "default" then data.moveVisible = nil
    else data[key] = value end
  end
  return { { data }, 1 }
end

local function player(hand, special)
  return { player_cards = { [1] = hand }, special_cards = special or {} }
end

local function snapshot(viewer, observer)
  local payload = {
    card_manager = { draw_pile = { count = 3 } },
    players = {
      [1] = player((observer or viewer ~= 1) and { token } or { 811 },
        { ["$hidden"] = (observer or viewer ~= 1) and { token2 } or { 827 } }),
      [2] = player((observer or viewer ~= 2) and { token2 } or { 839 }),
    },
  }
  if not observer then payload.you = viewer end
  return { cardWireVersion = 1, payload = payload }
end

for _, command in ipairs({ "PrepareDrawPile", "ShuffleDrawPile", "SyncDrawPile" }) do
  local category = ({ PrepareDrawPile = "prepare_order", ShuffleDrawPile = "shuffle_order",
    SyncDrawPile = "sync_order" })[command]
  check(command, { count = 3 }, true, 1, category)
  check(command, { count = 3 }, true, "observer", category)
  check(command, { 811, 827, 803 }, false, 1)
  check(command, { count = 3, extra = { 811 } }, false, 1)
end
check("PrepareDrawPile", { count = -1 }, false, 1)
check("PrepareDrawPile", { count = 1 }, false, true)
check("PrepareDrawPile", { count = 1 }, false, nil)

-- DrawPile=6 contains only count and retired handles. DiscardPile=7 is public.
check("ChangeCardArea", { count = 1, area = 6, areaCount = 3,
  retiredRefs = {} }, true, 1, "change_area_order")
check("ChangeCardArea", { count = 1, area = 6, areaCount = 3,
  areaRefs = { 811 } }, false, 1)
check("ChangeCardArea", { count = 1, area = 7, areaCount = 1,
  areaRefs = { 811 } }, true, 1)
check("ChangeCardArea", { count = 1, area = 7, areaCount = 2,
  areaRefs = { 811 } }, false, 1)
check("ChangeCardArea", { count = 1, area = 7, areaCount = 1,
  retiredRefs = { token } }, false, 1)
check("ChangeCardArea", { count = 1, area = 8, areaCount = 1,
  areaRefs = { 811 } }, true, "observer")

check("Reconnect", snapshot(1, false), true, 1, "reconnect_deck")
check("Reconnect", snapshot(2, false), true, 2, "reconnect_hand")
check("Reconnect", snapshot(2, false), true, 2, "reconnect_special")
check("Observe", snapshot(nil, true), true, "observer", "observe_deck")
check("Observe", snapshot(nil, true), true, "observer", "observe_hand")
check("Reconnect", snapshot(1, false), false, 2)
check("Observe", snapshot(nil, true), false, 1)
check("Reconnect", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { count = 3 } },
  players = { [1] = player({ token }) }, you = 1 } }, true, 1)
check("Reconnect", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { count = 3 } },
  players = { [1] = player({ token }) }, you = 1 } }, false, 2)
check("Reconnect", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { count = 3 } },
  players = { [1] = player({ 811 }) }, you = 2 } }, false, 2)
check("Observe", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { count = 3 } },
  players = { [1] = player({ 811 }) } } }, false, "observer")
check("Observe", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { count = 3 } },
  players = { [1] = player({}, { ["$hidden"] = { 811 } }) } } },
  false, "observer")
check("Observe", { cardWireVersion = 1, payload = {
  card_manager = { draw_pile = { 811 } }, players = {} } }, false, "observer")
check("Observe", { cardWireVersion = 0, payload = {
  card_manager = { draw_pile = { count = 3 } }, players = {} } }, false, "observer")

check("SetPlayerPile", { 1, "$hidden", { token } }, true, "observer", "special_pile_id")
check("SetPlayerPile", { 1, "$hidden", { 811 } }, false, "observer")
check("SetPlayerPile", { 1, "$hidden", { 811 } }, false, 2)
check("SetPlayerPile", { 1, "$hidden", { 811 } }, true, 1)
check("SetPlayerPile", { 1, "public", { 811 } }, true, "observer")

check("MoveCards", move(1, token), true, 2, "hidden_move_id")
check("MoveCards", move(1, token), true, "observer", "observe_hidden_move_id")
check("MoveCards", move(1, 811), false, 2)
check("MoveCards", move(1, 811), false, "observer")
check("MoveCards", move(1, 811, { to = 1 }), true, 1)
check("MoveCards", move(1, 811, { visiblePlayers = { 2 } }), true, 2)
check("MoveCards", move(1, 811, { visiblePlayers = 2 }), true, 2)
check("MoveCards", move(1, 811, { visiblePlayers = { 2 } }), false, "observer")
check("MoveCards", move(6, token, { to = 1, moveVisible = true }), true, 1, "hidden_move_id")
check("MoveCards", move(6, 811, { to = 1, moveVisible = true }), false, 1)
check("MoveCards", move(6, 811, { moveVisible = true }), false, "observer")
check("MoveCards", move(7, 811, { moveVisible = "default" }), true, "observer")
check("MoveCards", move(7, token, { moveVisible = "default" }), true, "observer")
check("MoveCards", move(4, token, { specialName = "$hidden" }), true, 2)
check("MoveCards", move(4, 811, { specialName = "$hidden" }), false, 2)
check("MoveCards", move(1, token, { from = "1" }), false, 2)
check("MoveCards", move(1, token, { proposer = "1" }), false, 2)
check("MoveCards", move(1, token, { moveReason = "1" }), false, 2)
check("MoveCards", move(1, token, { drawPilePosition = "1" }), false, 2)
check("MoveCards", move(1, token, { skillName = 42 }), false, 2)
check("MoveCards", move(1, token, { moveInfo = {
  { cardId = token, fromArea = 6, fromSpecialName = 42 } } }), false, 2)
check("MoveCards", move(1, token, { moveInfo = {
  { cardId = token, fromArea = 6.5 } } }), false, 2)
check("MoveCards", move(1, token, { moveInfo = {
  { cardId = token, fromArea = 6, beforeCard = 811 } } }), false, 2)

print("PASS native deck audit regression: " .. cases .. " cases; synthetic-only")
