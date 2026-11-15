-- Execute the actual candidate Client MoveCards/SetPlayerPile callbacks and
-- the real CardManager state transitions. Synthetic-only: native CBOR,
-- browser UI and live multi-account QA remain separate gates.
local root = assert(..., "isolated candidate core root required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3,
  PlayerSpecial = 4, Processing = 5, DiscardPile = 6,
  DrawPile = 7, Void = 8,
}
function Card.getIdList(first, second)
  local value = second == nil and first or second
  if type(value) == "table" then return value end
  return { value }
end
Player = { Hand = 1, Equip = 2, Judge = 3, Special = 4 }

table.removeOne = function(list, value)
  for index, current in ipairs(list) do
    if current == value then
      table.remove(list, index)
      return true
    end
  end
  return false
end
table.contains = function(list, value)
  for _, current in ipairs(list) do if current == value then return true end end
  return false
end
table.insertIfNeed = function(list, value)
  if not table.contains(list, value) then table.insert(list, value) end
end

local Manager = dofile(root .. "/ltk/core/room/card_manager.lua")
local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local sourceFile = assert(io.open(root .. "/ltk/client/client.lua", "rb"))
local source = assert(sourceFile:read("*a"))
sourceFile:close()
assert(source:find('self:addCallback("MoveCards", self.moveCards)', 1, true),
  "candidate MoveCards callback is not registered")
assert(source:find('self:addCallback("SetPlayerPile", self.setPlayerPile)', 1, true),
  "candidate SetPlayerPile callback is not registered")
assert(source:find("function Client:moveCardsLegacy(data)", 1, true),
  "candidate MoveCards legacy callback is not isolated")
assert(source:find("function Client:setPlayerPileLegacy(data)", 1, true),
  "candidate SetPlayerPile legacy callback is not isolated")

local currentRoom
Fk = {
  cards = {},
}
function Fk:currentRoom() return currentRoom end
function Fk:getCardById(id) return self.cards[id] end
function Fk:filterCard() end

local function tracker()
  local result = {
    calls = 0,
    player_cards = {},
    draw_pile = { known_cards = {}, uncertain_cards = {} },
    discard_pile = { known_cards = {}, uncertain_cards = {} },
    processing_area = { known_cards = {}, uncertain_cards = {} },
    void = { known_cards = {}, uncertain_cards = {} },
    draw_pile_order = {},
  }
  function result:applyMoveDatas(moves)
    self.calls = self.calls + 1
    self.lastMoves = moves
  end
  return result
end

local function player(id)
  return {
    id = id,
    player_cards = { [Player.Hand] = {}, [Player.Equip] = {}, [Player.Judge] = {} },
    special_cards = {},
    card_tracker = tracker(),
  }
end

local function separateMoves(moves)
  local result = {}
  for _, move in ipairs(moves) do
    for _, info in ipairs(move.moveInfo) do
      table.insert(result, {
        ids = { info.cardId }, from = move.from, to = move.to,
        toArea = move.toArea, fromArea = info.fromArea,
        moveReason = move.moveReason, specialName = move.specialName,
        fromSpecialName = info.fromSpecialName, skillName = move.skillName,
        proposer = move.proposer, drawPilePosition = move.drawPilePosition,
      })
    end
  end
  return result
end

local Client = {}
for key, value in pairs(Manager) do Client[key] = value end
local env = {
  Client = Client,
  Fk = Fk,
  Card = Card,
  Player = Player,
  Self = {},
  ClientInstance = nil,
  separateMoves = separateMoves,
  mergeMoves = function(moves) return moves end,
  sendMoveCardLog = function() end,
}
setmetatable(env, { __index = _G })

local function loadClientMethod(name, signature)
  local marker = signature or ("function Client:" .. name .. "(data)")
  local first = assert(source:find(marker, 1, true), "missing candidate " .. name)
  local nextMethod = source:find("\nfunction Client:", first + #marker, true)
  local chunk = source:sub(first, nextMethod and nextMethod - 1 or #source)
  assert(load(chunk, "=client/" .. name, "t", env))()
end

loadClientMethod("moveCardsLegacy")
loadClientMethod("moveCards")
loadClientMethod("setPlayerPileLegacy")
loadClientMethod("setPlayerPile")

local function rejects(fn, expected)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(expected, 1, true),
    "expected " .. expected .. ", got " .. tostring(err))
end

local function newRoom(version, mode)
  local room = setmetatable({
    card_wire_version = version,
    mode = mode or "new_heg_mode",
    players = { player(1), player(2) },
    uiCalls = 0,
  }, { __index = Client })
  room:initCardManager()
  room.card_wire_refs = Refs.new(function(id)
    return room.card_place[id] ~= nil
  end)
  function room:getSettings(key)
    assert(key == "gameMode")
    return self.mode
  end
  function room:getPlayerById(id)
    for _, p in ipairs(self.players) do if p.id == id then return p end end
  end
  function room:notifyUI() self.uiCalls = self.uiCalls + 1 end
  function room:appendLog() end
  currentRoom = room
  env.ClientInstance = room
  env.Self = {
    cardVisible = function(_, id)
      return not room.card_wire_refs:isHiddenLocal(id)
    end,
  }
  return room
end

local function seedDraw(room, count)
  local ids = room.card_wire_refs:replaceAnonymousDeck(count, {})
  room.draw_pile = ids
  for _, id in ipairs(ids) do room:setCardArea(id, Card.DrawPile, nil) end
  return ids
end

local function contains(list, value)
  for _, id in ipairs(list or {}) do if id == value then return true end end
  return false
end

local function token(n)
  return "h:" .. string.rep(string.char(96 + n), 16)
end

local cases = 0
local function check(name, fn)
  fn()
  cases = cases + 1
end

check("hidden draw consumes anonymous deck slot and localizes opaque card", function()
  local room = newRoom(1)
  local old = seedDraw(room, 2)
  local consumed, remaining = old[1], old[2]
  local ref = token(1)
  room:moveCards({ {
    { to = 2, toArea = Card.PlayerHand, moveInfo = {
      { cardId = ref, fromArea = Card.DrawPile },
    } },
  }, 17 })
  local localId = room.card_wire_refs.byToken[ref]
  assert(localId and not room.card_wire_refs:isAnonymous(localId))
  assert(room.players[2].player_cards[Player.Hand][1] == localId)
  assert(room.card_place[localId] == Card.PlayerHand and room.owner_map[localId] == 2)
  assert(room.draw_pile[1] == remaining and room.card_place[consumed] == nil)
  assert(room.card_wire_refs.byToken[ref] == localId)
  assert(room.players[1].card_tracker.calls == 1 and room.players[2].card_tracker.calls == 1)
end)

check("public-to-private move replaces canonical source with a fresh local alias", function()
  local room = newRoom(1)
  room.discard_pile = { 101 }
  room:setCardArea(101, Card.DiscardPile, nil)
  local ref = token(2)
  room:moveCards({ {
    { to = 2, toArea = Card.PlayerHand, moveVisible = false, moveInfo = {
      { cardId = ref, fromArea = Card.DiscardPile,
        cardWireRetiredRefs = { 101 } },
    } },
  }, 18 })
  local localId = room.card_wire_refs.byToken[ref]
  assert(localId and room.players[2].player_cards[Player.Hand][1] == localId)
  assert(#room.discard_pile == 0 and room.card_place[101] == nil)
  assert(room.card_place[localId] == Card.PlayerHand and room.owner_map[localId] == 2)
end)

check("private-to-public move retires opaque source and publishes canonical ID", function()
  local room = newRoom(1)
  local ref = token(3)
  local localId = room.card_wire_refs:toLocal(ref)
  room.players[2].player_cards[Player.Hand] = { localId }
  room:setCardArea(localId, Card.PlayerHand, 2)
  room:moveCards({ {
    { from = 2, toArea = Card.DiscardPile, moveVisible = true, moveInfo = {
      { cardId = 102, fromArea = Card.PlayerHand,
        cardWireRetiredRefs = { ref } },
    } },
  }, 19 })
  assert(room.players[2].player_cards[Player.Hand][1] == nil)
  assert(room.discard_pile[1] == 102 and room.card_place[102] == Card.DiscardPile)
  assert(room.card_wire_refs.byToken[ref] == nil)
  rejects(function() room.card_wire_refs:toWire(localId) end, "expired or unrecognized")
end)

check("public rekey must retire the standing opaque source reference", function()
  local room = newRoom(1)
  local ref = token(11)
  local localId = room.card_wire_refs:toLocal(ref)
  room.players[2].player_cards[Player.Hand] = { localId }
  room:setCardArea(localId, Card.PlayerHand, 2)

  -- A public metadata packet emitted before MoveCards must not cause the
  -- server to put the new canonical ID in cardWireRetiredRefs. If it does,
  -- the client cannot infer which of several hidden hand aliases to replace.
  rejects(function()
    room:moveCards({ {
      { from = 2, toArea = Card.DiscardPile, moveVisible = true, moveInfo = {
        { cardId = 104, fromArea = Card.PlayerHand,
          cardWireRetiredRefs = { 104 } },
      } },
    }, 26 })
  end, "MoveCards retired reference is absent from its source area")
  assert(room.players[2].player_cards[Player.Hand][1] == localId,
    "failed canonical rekey must not mutate the hidden source area")

  room:moveCards({ {
    { from = 2, toArea = Card.DiscardPile, moveVisible = true, moveInfo = {
      { cardId = 104, fromArea = Card.PlayerHand,
        cardWireRetiredRefs = { ref } },
    } },
  }, 27 })
  assert(room.players[2].player_cards[Player.Hand][1] == nil and
    room.discard_pile[1] == 104 and room.card_place[104] == Card.DiscardPile,
    "standing opaque source ref must drive the public replacement")
end)

check("stable hidden move keeps its local identity", function()
  local room = newRoom(1)
  local ref = token(4)
  local localId = room.card_wire_refs:toLocal(ref)
  room.players[2].player_cards[Player.Hand] = { localId }
  room:setCardArea(localId, Card.PlayerHand, 2)
  room:moveCards({ {
    { from = 2, to = 2, toArea = Card.PlayerSpecial, specialName = "$secret",
      moveInfo = { { cardId = ref, fromArea = Card.PlayerHand } } },
  }, 20 })
  assert(room.players[2].special_cards["$secret"][1] == localId)
  assert(room.card_place[localId] == Card.PlayerSpecial and room.owner_map[localId] == 2)
end)

check("SetPlayerPile localizes private refs and classifies tracker knowledge", function()
  local room = newRoom(1)
  local refA, refB = token(5), token(6)
  room:setPlayerPile({ 2, "$secret", { refA, refB } })
  local a = room.card_wire_refs.byToken[refA]
  local b = room.card_wire_refs.byToken[refB]
  assert(room.players[2].special_cards["$secret"][1] == a)
  assert(room.players[2].special_cards["$secret"][2] == b)
  assert(room.card_place[a] == Card.PlayerSpecial and room.owner_map[a] == 2)
  local tracked = room.players[1].card_tracker.player_cards[2][Card.PlayerSpecial]["$secret"]
  assert(#tracked.known_cards == 0 and #tracked.uncertain_cards == 2)

  room:setPlayerPile({ 2, "$secret", { 103 } })
  assert(room.players[2].special_cards["$secret"][1] == 103)
  assert(room.card_place[103] == Card.PlayerSpecial and room.owner_map[103] == 2)
  assert(room.card_place[a] == nil and room.card_place[b] == nil)
  rejects(function() room.card_wire_refs:toWire(a) end, "expired or unrecognized")
  tracked = room.players[1].card_tracker.player_cards[2][Card.PlayerSpecial]["$secret"]
  assert(#tracked.known_cards == 1 and tracked.known_cards[1] == 103 and
    #tracked.uncertain_cards == 0)
end)

check("malformed projected packets fail before client mutation", function()
  local room = newRoom(1)
  local old = seedDraw(room, 1)
  local allocator = room.card_wire_refs.nextLocal
  local badPackets = {
    { { { toArea = Card.PlayerHand, moveInfo = {
      { cardId = token(7), fromArea = Card.DrawPile, extra = true },
    } } }, 21 },
    { { { toArea = Card.PlayerHand, moveInfo = {
      { cardId = token(8), fromArea = Card.DrawPile,
        cardWireRetiredRefs = { {[2] = 101} } },
    } } }, 22 },
    { { { toArea = Card.PlayerHand, moveInfo = {
      { cardId = token(9), fromArea = Card.DrawPile,
        cardWireRetiredRefs = { "h:unknown_retired_ref" } },
    } } }, 23 },
  }
  for _, packet in ipairs(badPackets) do
    rejects(function() room:moveCards(packet) end, "MoveCards")
    assert(room.draw_pile[1] == old[1] and room.card_place[old[1]] == Card.DrawPile)
    assert(room.card_wire_refs.nextLocal == allocator)
  end
end)

check("version, mode and legacy compatibility remain explicit", function()
  local room = newRoom(nil, "other_mode")
  local ref = token(10)
  rejects(function()
    room:moveCards({ { { to = 2, toArea = Card.PlayerHand, moveInfo = {
      { cardId = ref, fromArea = Card.DrawPile },
    } } }, 24 })
  end, "requires negotiated Hegemony v1")
  rejects(function()
    room:setPlayerPile({ 2, "$secret", { ref } })
  end, "requires negotiated Hegemony v1")

  room.card_wire_version = 1
  rejects(function()
    room:moveCards({ { { to = 2, toArea = Card.PlayerHand, moveInfo = {
      { cardId = ref, fromArea = Card.DrawPile },
    } } }, 25 })
  end, "requires negotiated Hegemony v1")

  local legacy = newRoom(nil, "other_mode")
  legacy:setPlayerPile({ 2, "legacy", { 301, 302 } })
  assert(legacy.players[2].special_cards.legacy[1] == 301)
  assert(legacy.card_place[301] == nil, "legacy callback must not adopt v1 CardManager semantics")
end)

print(string.format("PASS candidate MoveCards/SetPlayerPile client: local alias transitions, " ..
  "anonymous draw consumption, public reveal/rehide, private pile trackers, " ..
  "standing-ref/source-area rekey, schema/mode/legacy fail-close; %d cases; " ..
  "synthetic-only; native/browser NOT RUN", cases))
