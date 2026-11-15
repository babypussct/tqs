-- Execute the actual candidate Client callback and CardManager state updates.
-- Synthetic-only: native CBOR and live two-account QA remain separate gates.
local root = assert(..., "isolated candidate core root required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

Card = { DrawPile = 1, DiscardPile = 2, Void = 3 }
Player = { Hand = 4, Equip = 5, Judge = 6, Special = 7 }

local Manager = dofile(root .. "/ltk/core/room/card_manager.lua")
local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local Area = dofile(root .. "/ltk/client/card_wire_area.lua")
local sourceFile = assert(io.open(root .. "/ltk/client/client.lua", "rb"))
local source = assert(sourceFile:read("*a"))
sourceFile:close()
assert(source:find('self:addCallback("ChangeCardArea", self.handleChangeCardArea)', 1, true),
  "candidate ChangeCardArea callback is not registered")

local Client = {}
for key, value in pairs(Manager) do Client[key] = value end
local env = setmetatable({ Client = Client }, { __index = _G })
local marker = "function Client:handleChangeCardArea(data)"
local first = assert(source:find(marker, 1, true), "missing candidate handleChangeCardArea")
local nextMethod = source:find("\nfunction Client:", first + #marker, true)
local chunk = source:sub(first, nextMethod and nextMethod - 1 or #source)
assert(load(chunk, "=client/handleChangeCardArea", "t", env))()

local function rejects(fn, expected)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(expected, 1, true),
    "expected " .. expected .. ", got " .. tostring(err))
end

local function tracker()
  return {
    draw_pile = { known_cards = { 1 }, uncertain_cards = { 2 } },
    draw_pile_order = { 1 },
    discard_pile = { known_cards = { 101 }, uncertain_cards = { 102 } },
    void = { known_cards = { 201 }, uncertain_cards = {} },
  }
end

local function newRoom(version, mode)
  local room = setmetatable({
    card_wire_version = version, mode = mode or "new_heg_mode",
    players = { { card_tracker = tracker() }, { card_tracker = tracker() } },
  }, { __index = Client })
  room:initCardManager()
  room.card_wire_refs = Refs.new(function(id)
    return room.card_place[id] ~= nil
  end)
  function room:getSettings(key)
    assert(key == "gameMode")
    return self.mode
  end
  return room
end

local function assertPublicTracker(room, area, expected)
  for _, player in ipairs(room.players) do
    local known = area == Card.DiscardPile and player.card_tracker.discard_pile
      or player.card_tracker.void
    assert(#known.known_cards == #expected and #known.uncertain_cards == 0)
    for i, id in ipairs(expected) do assert(known.known_cards[i] == id) end
  end
end

local function assertAnonymousDeck(room, count, old)
  assert(#room.draw_pile == count)
  local seen = {}
  for _, id in ipairs(room.draw_pile) do
    assert(not seen[id] and not (old and old[id]))
    seen[id] = true
    assert(room.card_wire_refs:isAnonymous(id))
    assert(room.card_place[id] == Card.DrawPile and room.owner_map[id] == nil)
  end
  for _, player in ipairs(room.players) do
    assert(#player.card_tracker.draw_pile.known_cards == 0)
    assert(#player.card_tracker.draw_pile.uncertain_cards == 0)
    assert(#player.card_tracker.draw_pile_order == count)
    for _, id in ipairs(player.card_tracker.draw_pile_order) do assert(id == -1) end
  end
  return seen
end

local function setupPublic(room)
  room.discard_pile = { 101 }
  room.void = { 201 }
  room:setCardArea(101, Card.DiscardPile, nil)
  room:setCardArea(201, Card.Void, nil)
end

local count = 0
local function check(name, fn)
  fn()
  count = count + 1
end

check("public discard identity and tracker survive projected replacement", function()
  local room = newRoom(1)
  setupPublic(room)
  room:handleChangeCardArea({ count = 1, area = Card.DiscardPile,
    areaCount = 2, areaRefs = { 101, 102 } })
  assert(room.discard_pile[1] == 101 and room.discard_pile[2] == 102)
  assert(room.card_place[101] == Card.DiscardPile and room.card_place[102] == Card.DiscardPile)
  assertPublicTracker(room, Card.DiscardPile, { 101, 102 })
end)

check("void identity is public and local aliases cannot masquerade as it", function()
  local room = newRoom(1)
  setupPublic(room)
  room:handleChangeCardArea({ count = 1, area = Card.Void,
    areaCount = 2, areaRefs = { 201, 202 } })
  assert(room.void[1] == 201 and room.void[2] == 202)
  assertPublicTracker(room, Card.Void, { 201, 202 })
  rejects(function()
    room:handleChangeCardArea({ count = 1, area = Card.Void,
      areaCount = 1, areaRefs = { 1000000000 } })
  end, "local alias")
  assert(room.void[1] == 201 and room.void[2] == 202)
end)

check("draw transition retires public refs and creates anonymous positions", function()
  local room = newRoom(1)
  setupPublic(room)
  local oldDeck = room.card_wire_refs:replaceAnonymousDeck(3, {})
  room.draw_pile = oldDeck
  for _, id in ipairs(oldDeck) do room:setCardArea(id, Card.DrawPile, nil) end
  room:handleChangeCardArea({ count = 1, area = Card.DrawPile,
    areaCount = 4, retiredRefs = { 101 } })
  assert(#room.discard_pile == 0 and room.card_place[101] == nil)
  assert(room.card_place[201] == Card.Void)
  assertAnonymousDeck(room, 4, oldDeck)
end)

check("malformed projected packets fail before any state or allocator change", function()
  local room = newRoom(1)
  setupPublic(room)
  local before = room.discard_pile
  local allocator = room.card_wire_refs.nextLocal
  local malformed = {
    { count = 1, area = Card.DiscardPile, areaCount = 1, areaRefs = {[2] = 101},
      message = "dense" },
    { count = 1, area = Card.DiscardPile, areaCount = 1, areaRefs = {"h:forged_reference_123"},
      message = "public area reference" },
    { count = 1, area = Card.DrawPile, areaCount = 1, retiredRefs = {101}, extra = true,
      message = "unaudited field" },
    { count = 1, area = Card.DrawPile, areaCount = 1, retiredRefs = {"bad"},
      message = "invalid retired opaque reference" },
  }
  for _, packet in ipairs(malformed) do
    local expected = packet.message
    packet.message = nil
    packet.extra = packet.extra and true or nil
    rejects(function() room:handleChangeCardArea(packet) end, expected)
    assert(room.discard_pile == before and room.card_wire_refs.nextLocal == allocator)
    assert(room.card_place[101] == Card.DiscardPile)
  end
end)

check("version, mode and legacy callback compatibility remain explicit", function()
  local room = newRoom(nil)
  local called
  function room:changeCardArea(cards, area, areaCards)
    called = { cards, area, areaCards }
  end
  room:handleChangeCardArea({ { 7 }, Card.DrawPile, { 7 } })
  assert(called and called[1][1] == 7 and called[2] == Card.DrawPile)
  room.card_wire_version = nil
  rejects(function()
    room:handleChangeCardArea({ count = 1, area = Card.DrawPile, areaCount = 1,
      retiredRefs = {} })
  end, "requires negotiated")
  room.card_wire_version = 1
  room.mode = "other_mode"
  rejects(function()
    room:handleChangeCardArea({ count = 1, area = Card.DrawPile, areaCount = 1,
      retiredRefs = {} })
  end, "requires negotiated")
end)

print(string.format("PASS candidate ChangeCardArea client: public discard/void refs, draw rekey, " ..
  "anonymous count state, schema/mode/legacy fail-close; %d cases; synthetic-only; native/browser NOT RUN", count))
