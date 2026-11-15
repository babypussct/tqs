-- Execute the actual candidate Client callbacks and core CardManager methods.
-- Synthetic client-only identities; this is not a native CBOR/browser test.
local root = assert(..., "isolated candidate core root required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

Card = { DrawPile = 1, DiscardPile = 2, Void = 3 }
Player = { Hand = 4, Equip = 5, Judge = 6, Special = 7 }
Fk = { game_modes = {
  new_heg_mode = { buildDrawPile = function() return { 501 }, { 601 } end },
  other_mode = { buildDrawPile = function() return { 502 }, { 602 } end },
} }

local Manager = dofile(root .. "/ltk/core/room/card_manager.lua")
local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local sourceFile = assert(io.open(root .. "/ltk/client/client.lua", "rb"))
local source = assert(sourceFile:read("*a"))
sourceFile:close()
assert(source:find('self:addCallback("PrepareDrawPile", self.prepareWireDrawPile)',
  1, true), "candidate callback registration not patched")

local Client = {}
for key, value in pairs(Manager) do Client[key] = value end
local env = setmetatable({ Client = Client }, { __index = _G })
local function loadClientMethod(name)
  local marker = "function Client:" .. name .. "(data)"
  local first = assert(source:find(marker, 1, true), "missing candidate " .. name)
  local nextMethod = source:find("\nfunction Client:", first + #marker, true)
  local chunk = source:sub(first, nextMethod and nextMethod - 1 or #source)
  assert(load(chunk, "=client/" .. name, "t", env))()
end
loadClientMethod("prepareWireDrawPile")
loadClientMethod("handleShuffleDrawPile")
loadClientMethod("syncDrawPile")

local function rejects(fn, expected)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(expected, 1, true),
    "expected " .. expected .. ", got " .. tostring(err))
end
local function tracker()
  return {
    draw_pile = { known_cards = { 11 }, uncertain_cards = { 12 } },
    draw_pile_order = { 11 },
    discard_pile = { known_cards = { 71 }, uncertain_cards = { 72 } },
  }
end
local function newRoom(version, mode)
  local room = setmetatable({
    card_wire_version = version, mode = mode or "new_heg_mode",
    players = { { card_tracker = tracker() }, { card_tracker = tracker() } },
    logs = {},
  }, { __index = Client })
  room:initCardManager()
  room.card_wire_refs = Refs.new(function(id)
    return room.card_place[id] ~= nil
  end)
  function room:getSettings(key)
    assert(key == "gameMode")
    return self.mode
  end
  function room:appendLog(entry)
    table.insert(self.logs, entry)
  end
  return room
end
local function assertDeck(room, size, old)
  assert(#room.draw_pile == size, "wrong anonymous deck size")
  local seen = {}
  for _, id in ipairs(room.draw_pile) do
    assert(not seen[id] and not (old and old[id]), "position identity reused")
    seen[id] = true
    assert(room.card_wire_refs:isAnonymous(id), "slot must be anonymous")
    assert(room.card_place[id] == Card.DrawPile and room.owner_map[id] == nil,
      "slot is missing its actual CardManager area")
    rejects(function() return room.card_wire_refs:toWire(id) end, "anonymous deck")
  end
  for _, player in ipairs(room.players) do
    local t = player.card_tracker
    assert(#t.draw_pile.known_cards == 0 and #t.draw_pile.uncertain_cards == 0,
      "old draw knowledge survived a count sync")
    assert(#t.draw_pile_order == size, "unknown deck order length must match count")
    for _, id in ipairs(t.draw_pile_order) do
      assert(id == -1, "draw order cannot disclose a known position")
    end
  end
  return seen
end
local function assertRetired(room, old)
  for id in pairs(old) do
    assert(room.card_place[id] == nil and room.owner_map[id] == nil,
      "expired deck position still owns a CardManager area")
    assert(not room.card_wire_refs:isAnonymous(id), "expired slot retained anonymous status")
    rejects(function() return room.card_wire_refs:toWire(id) end,
      "expired or unrecognized local card identity")
  end
end

local room = newRoom(1)
room.discard_pile = { 71 }
room:setCardArea(71, Card.DiscardPile, nil)
room:prepareWireDrawPile({ count = 3 })
local first = assertDeck(room, 3)
assert(room.card_place[601] == Card.Void and #room.void == 1)
assert(#room.discard_pile == 1 and room.card_place[71] == Card.DiscardPile,
  "prepare must not wipe other public zones")

room:syncDrawPile({ count = 2 })
local second = assertDeck(room, 2, first)
assertRetired(room, first)
assert(room.card_place[71] == Card.DiscardPile,
  "sync must preserve discard membership")

room:handleShuffleDrawPile({ count = 4 })
local third = assertDeck(room, 4, second)
assertRetired(room, second)
assert(#room.discard_pile == 0 and room.card_place[71] == nil,
  "shuffled discard must lose its obsolete public area")
assert(#room.logs == 1 and room.logs[1].type == "$ShuffleDrawPile" and
  room.logs[1].arg == 4, "native shuffle log contract changed")
for _, player in ipairs(room.players) do
  assert(#player.card_tracker.discard_pile.known_cards == 0 and
    #player.card_tracker.discard_pile.uncertain_cards == 0,
    "discard tracker must reset after shuffle")
end

room:syncDrawPile({ count = 0 })
assertDeck(room, 0, third)
assertRetired(room, third)

-- All malformed packets must be rejected before changing the reference
-- allocator or the CardManager state, including after a valid count sync.
room:syncDrawPile({ count = 2 })
local active = room.draw_pile
local allocator = room.card_wire_refs.nextLocal
local current = { room.draw_pile[1], room.draw_pile[2] }
local malformed = {
  { {}, "count" }, { { count = -1 }, "count" },
  { { count = 8193 }, "count" }, { { count = 1.5 }, "count" },
  { { count = "2" }, "count" }, { { count = math.huge }, "count" },
  { { count = 0 / 0 }, "count" },
  { { count = 2, orderedIds = { 55 } }, "unaudited field" },
  { { count = 2, [1] = 55 }, "unaudited field" },
}
for _, entry in ipairs(malformed) do
  rejects(function() room:syncDrawPile(entry[1]) end, entry[2])
  assert(room.draw_pile == active and room.card_wire_refs.nextLocal == allocator)
  assert(room.card_place[current[1]] == Card.DrawPile and
    room.card_place[current[2]] == Card.DrawPile)
end
rejects(function() room:handleShuffleDrawPile({ count = 1, id = 88 }) end,
  "unaudited field")
assert(room.draw_pile == active and room.card_wire_refs.nextLocal == allocator)

room.card_wire_version = nil
rejects(function() room:syncDrawPile({ count = 1 }) end, "requires negotiated")
room.card_wire_version = 1
room.mode = "other_mode"
rejects(function() room:prepareWireDrawPile({ count = 1 }) end, "requires negotiated")
room.mode = "new_heg_mode"
assert(room.draw_pile == active and room.card_wire_refs.nextLocal == allocator)

local legacy = newRoom(nil, "other_mode")
legacy:prepareWireDrawPile({ 15, 16 })
assert(#legacy.draw_pile == 2 and legacy.draw_pile[1] == 15 and
  legacy.card_place[16] == Card.DrawPile, "legacy prepare changed")
legacy:handleShuffleDrawPile({ 18, 19 })
assert(legacy.draw_pile[1] == 18 and #legacy.logs == 1,
  "legacy shuffle changed")
legacy:syncDrawPile({ 20, 21 })
assert(legacy.draw_pile[1] == 20 and legacy.draw_pile[2] == 21,
  "legacy sync changed")

print("PASS candidate count-only client deck: real Client/CardManager callbacks, " ..
  "anonymous aliases, tracker and area retirement, shuffle discard reset, " ..
  "count/schema/mode fail-close, zero count and legacy; synthetic-only; native/browser NOT RUN")
