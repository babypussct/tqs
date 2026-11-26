-- Execute the actual candidate projector with transactional card handles.
-- Synthetic-only: native CBOR, client numeric aliases and live QA are separate.
local projector = dofile(assert(arg[1], "projector module path required"))
local protocol = dofile(assert(arg[2], "card-handle protocol path required"))

Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3,
  PlayerSpecial = 4, Processing = 5, DiscardPile = 6, DrawPile = 7, Void = 8,
}

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[copy(key)] = copy(item) end
  return result
end

local encoded = {}
local encodeSequence = 0
cbor = {
  encode = function(value)
    encodeSequence = encodeSequence + 1
    local key = "cbor:" .. tostring(encodeSequence)
    encoded[key] = copy(value)
    return key
  end,
  decode = function(value)
    assert(type(value) == "string" and encoded[value], "fixture CBOR value missing")
    return copy(encoded[value])
  end,
}

local sequence = 0
local handles = protocol.new(function()
  sequence = sequence + 1
  return string.format("h:%032d", sequence)
end)
local owner = { key = "owner" }
local opponent = { key = "opponent" }
local spectator = { key = "spectator" }
local controller = { key = "second_controller" }
local seat = { id = 11, _splayer = owner, role_shown = false,
  role = "wei", general = "anjiang", deputyGeneral = "anjiang",
  gender = 1, kingdom = "wei" }
local otherSeat = { id = 12, _splayer = opponent, role_shown = false,
  role = "shu", general = "anjiang", deputyGeneral = "anjiang",
  gender = 2, kingdom = "shu" }
local seats = { [11] = seat, [12] = otherSeat }
function seat:getMaxCards() return 4 end
function otherSeat:getMaxCards() return 5 end
local room = { card_wire_version = 1 }
function room:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
end
function room:cardWireAudience(physical) return physical.key end
function room:getPlayerById(id) return seats[id] end
local cardLocations = {
  [100] = {area = Card.PlayerHand, owner = 11},
  [101] = {area = Card.PlayerSpecial, owner = 11, pile = "$concealed"},
  [102] = {area = Card.PlayerSpecial, owner = 11, pile = "public"},
  [103] = {area = Card.PlayerEquip, owner = 11},
  [104] = {area = Card.DrawPile},
  [105] = {area = Card.DiscardPile},
  [106] = {area = Card.Void},
}
function room:getCardArea(id) return cardLocations[id] and cardLocations[id].area end
function room:getCardOwner(id)
  local ownerId = cardLocations[id] and cardLocations[id].owner
  return ownerId and seats[ownerId]
end
function seat:getPileNameOfId(id) return cardLocations[id] and cardLocations[id].pile end

local function cardObject(values)
  local result = values or {}
  function result:isInstanceOf(class) return class == Card end
  function result:isVirtual() return self.id == 0 end
  return result
end

local function emit(watchedSeat, physical, command, data)
  local batch = handles:beginBatch()
  local ok, result = pcall(projector.project, room, watchedSeat, physical,
    command, data, batch)
  if not ok then batch:abort(); error(result, 2) end
  batch:commit()
  return result
end

local function fails(watchedSeat, physical, command, data, pattern)
  local ok, problem = pcall(emit, watchedSeat, physical, command, data)
  assert(not ok and tostring(problem):find(pattern, 1, true),
    "projection must fail closed: " .. tostring(problem))
  assert(handles.activeBatch == nil, "failed projection must abort the batch")
end

local function hidden(ref)
  assert(type(ref) == "string" and ref:sub(1, 2) == "h:",
    "concealed card must use an opaque token")
end

local function packet(changes)
  local move = {
    toArea = Card.PlayerHand, to = seat.id,
    moveInfo = { { cardId = 100, fromArea = Card.DrawPile } },
    moveVisible = false,
  }
  for key, value in pairs(changes or {}) do move[key] = value end
  return { { move }, 42 }
end

local count = 0
local function check(name, fn)
  fn()
  count = count + 1
end

check("owner, opponent, spectator physical separation", function()
  local msg = packet()
  assert(emit(seat, owner, "MoveCards", msg)[1][1].moveInfo[1].cardId == 100)
  local enemy = emit(otherSeat, opponent, "MoveCards", msg)[1][1].moveInfo[1].cardId
  local observer = emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId
  hidden(enemy); hidden(observer)
  assert(enemy ~= observer and enemy ~= 100)
  assert(emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId ~= observer,
    "every draw from hidden deck must retire an earlier reference")
end)

check("unchanged concealed hand retains physical reference", function()
  local msg = packet({moveInfo = {{cardId = 105, fromArea = Card.PlayerHand}}})
  local first = emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId
  hidden(first)
  assert(emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId == first)
end)

check("numeric visiblePlayers does not elevate attached spectator", function()
  local msg = packet({to = 12, visiblePlayers = seat.id})
  local spectatorRef = emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId
  hidden(spectatorRef)
  assert(emit(seat, owner, "MoveCards", msg)[1][1].moveInfo[1].cardId == 100)
end)

check("array visiblePlayers grants only the physical owner", function()
  local msg = packet({to = 12, visiblePlayers = {seat.id}})
  hidden(emit(seat, controller, "MoveCards", msg)[1][1].moveInfo[1].cardId)
  hidden(emit(seat, spectator, "MoveCards", msg)[1][1].moveInfo[1].cardId)
  assert(emit(seat, owner, "MoveCards", msg)[1][1].moveInfo[1].cardId == 100)
end)

check("public reveal and private rehide retire the old public identity", function()
  local shown = packet({toArea = Card.DiscardPile, moveVisible = true, to = nil})
  local publicOutput = emit(otherSeat, opponent, "MoveCards", shown)[1][1]
  assert(publicOutput.moveInfo[1].cardId == 100)
  assert(type(publicOutput.moveInfo[1].cardWireRetiredRefs) == "table")
  hidden(publicOutput.moveInfo[1].cardWireRetiredRefs[1])
  local rehiddenOutput = emit(otherSeat, opponent, "MoveCards", packet())[1][1]
  local rehidden = rehiddenOutput.moveInfo[1].cardId
  hidden(rehidden)
  assert(rehiddenOutput.moveInfo[1].cardWireRetiredRefs[1] == 100)
  assert(rehidden ~= 100)
end)

check("private/public MoveCards transitions carry the audience's old ref", function()
  local private = {
    { { from = 11, to = 11, toArea = Card.PlayerHand, moveVisible = false,
        moveInfo = {{cardId = 100, fromArea = Card.PlayerHand}} } },
    44,
  }
  local hiddenOutput = emit(seat, spectator, "MoveCards", private)[1][1]
  local oldRef = hiddenOutput.moveInfo[1].cardId
  hidden(oldRef)
  local public = {
    { { from = 11, toArea = Card.DiscardPile, moveVisible = true,
        moveInfo = {{cardId = 100, fromArea = Card.PlayerHand}} } },
    45,
  }
  local publicOutput = emit(seat, spectator, "MoveCards", public)[1][1]
  assert(publicOutput.moveInfo[1].cardId == 100)
  assert(publicOutput.moveInfo[1].cardWireRetiredRefs[1] == oldRef)
end)

check("pre-move public metadata preserves the standing ref for MoveCards rekey", function()
  local card = 107
  cardLocations[card] = {area = Card.PlayerHand, owner = 11}
  local transitionPhysical = { key = "transition" }
  local hiddenMove = {
    { { from = 11, to = 11, toArea = Card.PlayerHand, moveVisible = false,
        moveInfo = {{cardId = card, fromArea = Card.DrawPile}} } },
    46,
  }
  local hiddenRef = emit(seat, transitionPhysical, "MoveCards", hiddenMove)[1][1]
    .moveInfo[1].cardId
  hidden(hiddenRef)

  -- MoveCards applies the server-side area change before upstream clears or
  -- applies card marks. Public metadata keeps the legacy numeric callback
  -- compatible while the protocol retains the old opaque handle until the
  -- explicit movement packet carries its retiredRefs.
  cardLocations[card].area = Card.DiscardPile
  local metadata = emit(seat, transitionPhysical, "SetCardMark",
    { card, "@transition", 1 })
  assert(metadata[1] == card,
    "public metadata must use the canonical card ID")

  local publicMove = {
    { { from = 11, toArea = Card.DiscardPile, moveVisible = true,
        moveInfo = {{cardId = card, fromArea = Card.PlayerHand}} } },
    47,
  }
  local output = emit(seat, transitionPhysical, "MoveCards", publicMove)[1][1]
  assert(output.moveInfo[1].cardId == card and
    output.moveInfo[1].cardWireRetiredRefs[1] == hiddenRef,
    "MoveCards must retire the old opaque source ref after metadata")
end)

check("public card descriptors and logs preserve pending source-area handles", function()
  local card = 107
  local real = cardObject({ id = card })
  local virtual = cardObject({ id = 0, name = "slash", suit = 1, number = 7,
    color = 1, subcards = {card}, skillNames = {}, virt_id = 0, mark = {} })
  for index, metadata in ipairs({
    { "ShowCard", {{card}, 11, 50} },
    { "ShowVirtualCard", {real, 11} },
    { "ShowVirtualCard", {virtual, 11} },
    { "GameLog", { type = "#UseCard", card = {card}, arg2 = real } },
    { "SetCardFootnote", {{card}, {type = "#UseCard", from = 11}, false} },
    { "SetCardVirtName", {{card}, "slash", false} },
    { "FilterCard", {card, 11, false} },
    { "RemoveVirtualEquip", {player = 11, id = card} },
  }) do
    local physical = { key = "descriptor-transition-" .. index }
    cardLocations[card] = {area = Card.PlayerHand, owner = 11}
    local hiddenRef = emit(seat, physical, "MoveCards", {
      {{from = 11, to = 11, toArea = Card.PlayerHand, moveVisible = false,
        moveInfo = {{cardId = card, fromArea = Card.DrawPile}}}}, 48,
    })[1][1].moveInfo[1].cardId
    hidden(hiddenRef)
    cardLocations[card].area = Card.Processing
    emit(seat, physical, metadata[1], metadata[2])
    local output = emit(seat, physical, "MoveCards", {
      {{from = 11, toArea = Card.Processing, moveVisible = true,
        moveInfo = {{cardId = card, fromArea = Card.PlayerHand}}}}, 49,
    })[1][1].moveInfo[1]
    assert(output.cardId == card and output.cardWireRetiredRefs[1] == hiddenRef,
      "public metadata retired the client source handle before MoveCards")
  end
end)

check("a gaining owner receives the retired hidden source reference", function()
  local card = 107
  local physical = { key = "gaining-owner" }
  -- This physical connection controls seat 12; seat 11 owns the source hand.
  local originalPhysical = otherSeat._splayer
  otherSeat._splayer = physical
  cardLocations[card] = {area = Card.PlayerHand, owner = 11}
  local hiddenRef = emit(otherSeat, physical, "MoveCards", {
    {{from = 11, to = 11, toArea = Card.PlayerHand, moveVisible = false,
      moveInfo = {{cardId = card, fromArea = Card.DrawPile}}}}, 51,
  })[1][1].moveInfo[1].cardId
  hidden(hiddenRef)
  cardLocations[card].owner = 12
  local moved = emit(otherSeat, physical, "MoveCards", {
    {{from = 11, to = 12, toArea = Card.PlayerHand, moveVisible = false,
      moveInfo = {{cardId = card, fromArea = Card.PlayerHand}}}}, 52,
  })[1][1].moveInfo[1]
  otherSeat._splayer = originalPhysical
  assert(moved.cardId == card and moved.cardWireRetiredRefs and
    moved.cardWireRetiredRefs[1] == hiddenRef,
    "a new owner still needs the old opaque alias to remove the source hand card")
end)

check("private metadata before rehide preserves the public source without leaking it", function()
  local card = 107
  local physical = {key = "private-metadata-rehide"}
  cardLocations[card] = {area = Card.DiscardPile}
  emit(seat, physical, "MoveCards", {{{toArea = Card.DiscardPile, moveVisible = true,
    moveInfo = {{cardId = card, fromArea = Card.DrawPile}}}}, 53})
  cardLocations[card] = {area = Card.PlayerHand, owner = 11}
  local metadata = emit(seat, physical, "FilterCard", {card, 11, false})
  hidden(metadata.payload[1])
  local repeatMetadata = emit(seat, physical, "FilterCard", {card, 11, false})
  assert(repeatMetadata.payload[1] == metadata.payload[1], "pending metadata must not mint repeatedly")
  assert(handles.audiences[physical.key].public[card] == true and
    handles.audiences[physical.key].byToken[metadata.payload[1]] == nil,
    "private metadata must neither replace the public source nor grant a reply capability")
  local moved = emit(seat, physical, "MoveCards", {{{to = 11, toArea = Card.PlayerHand,
    moveVisible = false, moveInfo = {{cardId = card, fromArea = Card.DiscardPile}}}}, 54})[1][1].moveInfo[1]
  hidden(moved.cardId)
  assert(moved.cardWireRetiredRefs[1] == card and moved.cardId ~= metadata.payload[1],
    "rehide must retire the public source and mint its actual hidden area reference")
end)

check("explicit face-up movement into draw pile conceals and rekeys", function()
  local published = packet({toArea = Card.DiscardPile, moveVisible = true, to = nil})
  assert(emit(seat, spectator, "MoveCards", published)[1][1].moveInfo[1].cardId == 100)
  local returnToDeck = packet({
    toArea = Card.DrawPile, to = nil, moveVisible = true,
    moveInfo = {{cardId = 100, fromArea = Card.DiscardPile}},
  })
  local first = emit(seat, spectator, "MoveCards", returnToDeck)[1][1].moveInfo[1].cardId
  hidden(first)
  local nextRef = emit(seat, spectator, "MoveCards", returnToDeck)[1][1].moveInfo[1].cardId
  hidden(nextRef)
  assert(first ~= nextRef, "deck transition cannot expose a stable trackable ID")
  hidden(emit(seat, owner, "MoveCards", returnToDeck)[1][1].moveInfo[1].cardId)
end)

check("Quan Tinh deck return leaves no standing destination ref for redraw", function()
  for _, physical in ipairs({owner, opponent, spectator, controller}) do
    local card = 104
    local take = {{{toArea = Card.Processing, moveVisible = false, visiblePlayers = {11},
      moveInfo = {{cardId = card, fromArea = Card.DrawPile}}}}, 71}
    local returned = {{{toArea = Card.DrawPile, moveVisible = false, drawPilePosition = -1,
      moveInfo = {{cardId = card, fromArea = Card.Processing}}}}, 72}
    local redraw = {{{to = 11, toArea = Card.PlayerHand, moveVisible = false,
      moveInfo = {{cardId = card, fromArea = Card.DrawPile}}}}, 73}
    -- Start with no standing reference from other synthetic scenarios.
    handles:forget(physical.key, card)
    local seen = emit(seat, physical, "MoveCards", take)[1][1].moveInfo[1]
    if physical == owner then assert(seen.cardId == card) else hidden(seen.cardId) end
    local back = emit(seat, physical, "MoveCards", returned)[1][1].moveInfo[1]
    hidden(back.cardId)
    assert(back.cardWireRetiredRefs[1] == seen.cardId)
    local nextCard = emit(seat, physical, "MoveCards", redraw)[1][1].moveInfo[1]
    assert(nextCard.cardWireRetiredRefs == nil, "redraw must not retire an unseen deck destination token")
    if physical == owner then assert(nextCard.cardId == card) else hidden(nextCard.cardId) end
    assert(nextCard.cardId ~= back.cardId)
    handles:forget(physical.key, card)
  end
end)

check("private dollar piles are physical owner-only", function()
  local private = {11, "$secret", {101, 102}}
  local ownerOut = emit(seat, owner, "SetPlayerPile", private)
  assert(ownerOut[3][1] == 101 and ownerOut[3][2] == 102)
  local otherOut = emit(seat, spectator, "SetPlayerPile", private)
  hidden(otherOut[3][1]); hidden(otherOut[3][2])
  assert(otherOut[3][1] ~= otherOut[3][2])
  hidden(emit(seat, controller, "SetPlayerPile", private)[3][1])
end)

check("non-dollar pile is public and orders are checked", function()
  local result = emit(seat, spectator, "SetPlayerPile", {11, "public", {101, 102}})
  assert(result[3][1] == 101 and result[3][2] == 102)
  fails(seat, spectator, "SetPlayerPile", {11, "$private", {[2] = 102}}, "sparse")
  fails(seat, spectator, "SetPlayerPile", {11, "$private", {[-1] = 101}}, "invalid index")
end)

check("deck order never travels with count summaries", function()
  for _, command in ipairs({"PrepareDrawPile", "ShuffleDrawPile", "SyncDrawPile"}) do
    local result = emit(seat, spectator, command, {102, 101, 103})
    assert(result.count == 3 and result[1] == nil and result[2] == nil)
    fails(seat, spectator, command, {100, bad = 101}, "invalid index")
  end
end)

check("ChangeCardArea keeps public refs and retires old deck refs", function()
  local shown = packet({toArea = Card.DiscardPile, moveVisible = true, to = nil})
  assert(emit(seat, spectator, "MoveCards", shown)[1][1].moveInfo[1].cardId == 100)
  local out = emit(seat, spectator, "ChangeCardArea", {{100}, Card.DrawPile, {102, 100}})
  assert(out.count == 1 and out.area == Card.DrawPile and out.areaCount == 2)
  assert(out.areaRefs == nil and type(out.retiredRefs) == "table" and out.retiredRefs[1] == 100)
  local public = emit(seat, spectator, "ChangeCardArea", {{105}, Card.DiscardPile, {105, 102}})
  assert(public.count == 1 and public.area == Card.DiscardPile and public.areaCount == 2)
  assert(public.retiredRefs == nil and public.areaRefs[1] == 105 and public.areaRefs[2] == 102)
  fails(seat, spectator, "ChangeCardArea", {{100}, "hand", {}}, "not audited")
end)

check("real upstream beforeCard and virtualEquip are redacted, not CBOR-tagged", function()
  local msg = packet({moveInfo = {{
    cardId = 104, fromArea = Card.DrawPile,
    beforeCard = {id = 104, name = "slash", __tocbor = function() error("leak") end},
    virtualEquip = { subcards = {104}, extra_data = {cardId = 104} },
  }}, moveMark = {"secret", {cardId = 104}},
    extra_data = {cardId = 104}})
  local output = emit(seat, spectator, "MoveCards", msg)[1][1]
  assert(output.moveMark == nil and output.extra_data == nil)
  assert(output.moveInfo[1].beforeCard == nil and output.moveInfo[1].virtualEquip == nil)
  assert(output.moveInfo[1].fromArea == Card.DrawPile)
  hidden(output.moveInfo[1].cardId)
  assert(msg[1][1].moveInfo[1].beforeCard.id == 104,
    "server event retains its original beforeCard object")
end)

check("extra nested fields are rejected instead of silently forwarded", function()
  fails(seat, spectator, "MoveCards", packet({
    moveInfo = {{cardId = 104, fromArea = Card.DrawPile, arbitrary = {subcards = {104}}}},
  }), "unaudited field")
  fails(seat, spectator, "MoveCards", packet({secretPayload = {cardId = 104}}),
    "unaudited field")
end)

check("unaudited move metadata cannot smuggle nested canonical IDs", function()
  for _, key in ipairs({"from", "to", "proposer", "moveReason", "drawPilePosition"}) do
    fails(seat, spectator, "MoveCards", packet({[key] = {cardId = 104}}), "numeric scalar")
  end
  fails(seat, spectator, "MoveCards", packet({specialName = {104}}), "must be a string")
  fails(seat, spectator, "MoveCards", packet({
    moveInfo = {{cardId = 104, fromArea = Card.DrawPile, fromSpecialName = {104}}},
  }), "must be a string")
end)

check("malformed visiblePlayers arrays fail atomically", function()
  fails(seat, spectator, "MoveCards", packet({visiblePlayers = {[2] = 11}}), "sparse")
  fails(seat, spectator, "MoveCards", packet({visiblePlayers = {11, ["cardId"] = 100}}),
    "invalid index")
  fails(seat, spectator, "MoveCards", packet({visiblePlayers = {"11"}}),
    "player IDs")
  fails(seat, spectator, "MoveCards", packet({visiblePlayers = {id = 11}, moveInfo = {}}),
    "invalid index")
  fails(seat, spectator, "MoveCards", packet({visiblePlayers = {"11"}, moveInfo = {}}),
    "player IDs")
end)

check("owner private property and concealed opponent property are separated", function()
  local private = {11, "role", "wei"}
  assert(emit(seat, owner, "PropertyUpdate", private)[3] == "wei")
  fails(seat, spectator, "PropertyUpdate", private, "concealed role")
  fails(otherSeat, opponent, "PropertyUpdate", private, "concealed role")
  assert(emit(otherSeat, opponent, "PropertyUpdate", {11, "role", "hidden"})[3] == "hidden")
  assert(emit(seat, owner, "PropertyUpdate", {11, "general", "liubei"})[3] == "liubei")
  fails(seat, spectator, "PropertyUpdate", {11, "general", "liubei"}, "concealed general")
  fails(seat, spectator, "PropertyUpdate", {11, "kingdom", "wei"}, "concealed faction")
  assert(emit(seat, spectator, "PropertyUpdate", {11, "gender", 4})[3] == 4)
  fails(seat, spectator, "PropertyUpdate", {11, "gender", 1}, "concealed gender")
  seat.role_shown = true
  seat.general = "liubei"
  assert(emit(seat, spectator, "PropertyUpdate", {11, "general", "liubei"})[3] == "liubei")
  assert(emit(seat, spectator, "PropertyUpdate", {11, "role", "wei"})[3] == "wei")
  seat.role_shown = false
  seat.general = "anjiang"
end)

check("public property scalar and numeric slot arrays have strict schemas", function()
  assert(emit(seat, spectator, "PropertyUpdate", {11, "hp", 3})[3] == 3)
  assert(emit(seat, spectator, "PropertyUpdate", {11, "dying", false})[3] == false)
  local input = {11, "sealedSlots", {1, 2}}
  local slots = emit(seat, spectator, "PropertyUpdate", input)[3]
  assert(slots[1] == 1 and slots[2] == 2 and slots ~= input[3])
  fails(seat, spectator, "PropertyUpdate", {11, "hp", {cardId = 100}}, "finite scalar")
  fails(seat, spectator, "PropertyUpdate", {11, "equipSlots", {100, ["leak"] = 104}}, "invalid index")
  fails(seat, spectator, "PropertyUpdate", {11, "handCards", {100}}, "unaudited")
  assert(emit(seat, spectator, "PropertyUpdate", {11, "MaxCards"})[3] == 4)
  fails(seat, spectator, "PropertyUpdate", {13, "hp", 1}, "player/property invalid")
end)

check("private Hegemony marks keep only owner-safe schema", function()
  assert(emit(seat, owner, "SetPlayerMark", {11, "__heg_general", "liubei"})[3] == "liubei")
  fails(seat, spectator, "SetPlayerMark", {11, "__heg_general", "liubei"}, "physical owner")
  fails(otherSeat, opponent, "SetPlayerMark", {11, "InitialGeneral", {"liubei", "guanyu"}}, "physical owner")
  local pair = {"liubei", "guanyu"}
  local pairOut = emit(seat, owner, "SetPlayerMark", {11, "InitialGeneral", pair})[3]
  assert(pairOut[1] == "liubei" and pairOut[2] == "guanyu" and pairOut ~= pair)
  local skills = {"wusheng", "longdan"}
  assert(emit(seat, owner, "SetPlayerMark", {11, "ExtraAttachedSkills", skills})[3] ~= skills)
  assert(emit(seat, owner, "SetPlayerMark", {11, "HalfMaxHpLeft", 1})[3] == 1)
  fails(seat, owner, "SetPlayerMark", {11, "InitialGeneral", {"liubei", 100}}, "must contain names")
  fails(seat, owner, "SetPlayerMark", {11, "ExtraAttachedSkills", {[2] = "wusheng"}}, "sparse")
  fails(seat, owner, "SetPlayerMark", {11, "__heg_mystery", "raw"}, "unknown private")
  fails(seat, owner, "SetPlayerMark", {11, "__heg_general", {cardId = 100}}, "finite scalar")
end)

check("public marks fail closed on nested physical card identities", function()
  assert(emit(seat, spectator, "SetPlayerMark", {11, "@round", 2})[3] == 2)
  local luanji = {"spade", "heart"}
  local luanjiOut = emit(seat, spectator, "SetPlayerMark", {11, "@hs__luanji-turn", luanji})[3]
  assert(luanjiOut[1] == "spade" and luanjiOut[2] == "heart" and luanjiOut ~= luanji)
  local yigui = {bypass_times = true, bypass_distances = false,
    fix_targets = {11, 12}, include_targets = {12}, fix_user = 11}
  local yiguiOut = emit(seat, spectator, "SetPlayerMark",
    {11, "ld__yigui_extra_data", yigui})[3]
  assert(yiguiOut.fix_targets[1] == 11 and yiguiOut.include_targets[1] == 12 and
    yiguiOut.fix_user == 11 and yiguiOut ~= yigui)
  local naxiangTargets = {12}
  local naxiangOut = emit(seat, spectator, "SetPlayerMark", {11, "naxiang", naxiangTargets})[3]
  assert(#naxiangOut == 1 and naxiangOut[1] == 12 and naxiangOut ~= naxiangTargets)
  assert(emit(seat, spectator, "SetPlayerMark", {11, "naxiang", 0})[3] == 0)
  fails(seat, spectator, "SetPlayerMark", {11, "naxiang", {100}}, "must contain player IDs")
  fails(seat, spectator, "SetPlayerMark", {11, "naxiang", {{id = 12}}}, "must contain player IDs")
  assert(emit(seat, spectator, "SetPlayerMark", {11, "ld__zhidao-phase", otherSeat})[3] == otherSeat)
  fails(seat, spectator, "SetPlayerMark", {11, "ld__zhidao-phase", {id = 12}}, "live player references")
  fails(seat, spectator, "SetPlayerMark",
    {11, "ld__yigui_extra_data", {cardIds = {100}}}, "unaudited field")
  fails(seat, spectator, "SetPlayerMark", {11, "@cardList", {100, 101}}, "finite scalar")
  fails(seat, spectator, "SetPlayerMark", {11, "@cardList", {id = 100}}, "finite scalar")
  fails(seat, spectator, "SetPlayerMark", {11, "mark", 0, "junk"}, "expects [player,mark,value]")
end)

check("extra-turn reason stacks preserve rules and conceal private reasons", function()
  local reasons = {"threaten_emperor_skill", "hidden_skill", "game_rule"}
  local own = emit(seat, owner, "SetPlayerMark", {11, "_extra_turn_count", reasons})[3]
  assert(own ~= reasons and table.concat(own, ",") == table.concat(reasons, ","))
  for _, audience in ipairs({{seat, spectator}, {otherSeat, opponent}, {seat, controller}}) do
    local out = emit(audience[1], audience[2], "SetPlayerMark", {11, "_extra_turn_count", reasons})[3]
    assert(table.concat(out, ",") == "threaten_emperor_skill,_tqs_extra_turn,game_rule")
    assert(reasons[2] == "hidden_skill")
    assert(#emit(audience[1], audience[2], "SetPlayerMark", {11, "_extra_turn_count", {}})[3] == 0)
    assert(emit(audience[1], audience[2], "SetPlayerMark", {11, "_extra_turn_count", 0})[3] == 0)
  end
  for _, bad in ipairs({1, "hidden_skill", {100}, {""}, {{id = 100}}, {[2] = "hidden_skill"}, {skill = "hidden_skill"}}) do
    fails(seat, owner, "SetPlayerMark", {11, "_extra_turn_count", bad}, "_extra_turn_count")
    fails(seat, spectator, "SetPlayerMark", {11, "_extra_turn_count", bad}, "_extra_turn_count")
  end
  for _, kind in ipairs({"$ExtraTurnStart", "$ExtraTurnEnd"}) do
    local log = {type = kind, from = 11, arg = "hidden_skill"}
    assert(emit(seat, owner, "GameLog", log).payload.arg == "hidden_skill")
    assert(emit(seat, spectator, "GameLog", log).payload.arg == "")
    assert(emit(otherSeat, opponent, "GameLog", log).payload.arg == "")
    assert(log.arg == "hidden_skill")
    log.arg = "threaten_emperor_skill"
    assert(emit(seat, spectator, "GameLog", log).payload.arg == log.arg)
  end
end)

check("invalid-skill maps keep concealed skill names owner-only", function()
  local invalid = { hs__secret = { "hs__controller" } }
  local ownerOut = emit(seat, owner, "SetPlayerMark", {11, "InvalidSkills", invalid})
  assert(ownerOut[3].hs__secret[1] == "hs__controller")
  local observerOut = emit(seat, spectator, "SetPlayerMark", {11, "InvalidSkills", invalid})
  assert(next(observerOut[3]) == nil)
  assert(emit(seat, spectator, "SetPlayerMark", {11, "InvalidSkills-round", 0})[3] == 0)
  fails(seat, spectator, "SetPlayerMark",
    {11, "InvalidSkills", {hs__secret = {100}}}, "must contain names")
  fails(seat, spectator, "SetPlayerMark",
    {11, "InvalidSkills", {[100] = {"hs__controller"}}}, "keys must be skill names")
end)

check("metadata notifications use explicit non-card schemas", function()
  local scalarBanner = emit(seat, spectator, "SetBanner", {"RoundCount", 2})
  assert(scalarBanner[1] == "RoundCount" and scalarBanner[2] == 2)

  local initial = emit(seat, spectator, "SetBanner", {
    "InitialGeneral", {{11, "liubei", "guanyu"}},
  })
  assert(initial[2][1][1] == 11 and initial[2][1][2] == "liubei" and
    initial[2][1][3] == "guanyu")

  local summary = emit(seat, spectator, "SetBanner", {
    "GameSummary", {{turn = 1, recover = 0, recoverBy = 0, damage = 2,
      damaged = 1, kill = 0, killList = {12}, draw = 4, control = 0,
      scname = "probe", win = "Game Win"}},
  })
  assert(summary[2][1].damage == 2 and summary[2][1].killList[1] == 12)
  local kingdoms = emit(seat, spectator, "SetBanner", {"all_kingdoms", {"wei", "shu"}})
  assert(kingdoms[2][1] == "wei" and kingdoms[2][2] == "shu")
  fails(seat, spectator, "SetBanner", {"unreviewed", {100}}, "finite scalar")
  assert(emit(seat, spectator, "SetBanner", {"RoundCount"})[2] == nil)

  local history = emit(seat, spectator, "SetCardUseHistory", {11, "slash", 1, 2})
  assert(history[1] == 11 and history[2] == "slash" and history[3] == 1 and history[4] == 2)
  local clear = emit(seat, spectator, "SetCardUseHistory", {11, "", nil, nil})
  assert(clear[1] == 11 and clear[2] == "" and clear[3] == nil and clear[4] == nil)
  fails(seat, spectator, "SetCardUseHistory", {13, "slash", 1, 2}, "player is missing")

  local addCard = emit(seat, spectator, "AddCardUseHistory", {11, "slash", 1})
  assert(addCard[1] == 11 and addCard[2] == "slash" and addCard[3] == 1)
  local addSkill = emit(seat, spectator, "AddSkillUseHistory", {11, "wusheng", 1})
  assert(addSkill[1] == 11 and addSkill[2] == "wusheng" and addSkill[3] == 1)
  local addBranch = emit(seat, spectator, "AddSkillBranchUseHistory", {11, "x", "branch", 1})
  assert(addBranch[1] == 11 and addBranch[2] == "x" and addBranch[3] == "branch" and addBranch[4] == 1)
  local skill = emit(seat, spectator, "SetSkillUseHistory", {11, "", 0, 2})
  assert(skill[1] == 11 and skill[2] == "" and skill[3] == 0 and skill[4] == 2)
  local branch = emit(seat, spectator, "SetSkillBranchUseHistory", {11, "", "", 0, 2})
  assert(branch[1] == 11 and branch[2] == "" and branch[3] == "" and branch[4] == 0 and branch[5] == 2)

  local addSkillNotification = emit(seat, spectator, "AddSkill", {11, "wusheng"})
  assert(addSkillNotification[1] == 11 and addSkillNotification[2] == "wusheng")
  local loseSkillNotification = emit(seat, spectator, "LoseSkill", {11, "wusheng", false})
  assert(loseSkillNotification[1] == 11 and loseSkillNotification[2] == "wusheng" and
    loseSkillNotification[3] == false)
  local focus = emit(seat, spectator, "MoveFocus", {{11, 12}, "AskForUseCard", 3000})
  assert(focus[1][1] == 11 and focus[1][2] == 12 and focus[2] == "AskForUseCard" and
    focus[3] == 3000)
  assert(emit(seat, spectator, "AddStatusSkill", {"game_rule"})[1] == "game_rule")
  assert(emit(seat, spectator, "ShowToast", "probe") == "probe")

  assert(emit(seat, spectator, "SetCurrent", {12})[1] == 12)
  assert(emit(seat, spectator, "SetCurrent", {})[1] == nil)
  fails(seat, spectator, "SetCurrent", {13}, "player is missing")
end)

check("physical hidden card marks require actual card owner", function()
  assert(emit(seat, owner, "SetCardMark", {100, "@mark", 2})[1] == 100)
  assert(emit(seat, owner, "SetCardMark", {101, "@mark", 2})[1] == 101)
  fails(seat, spectator, "SetCardMark", {100, "@mark", 2}, "physical owner")
  fails(otherSeat, opponent, "SetCardMark", {101, "@mark", 2}, "physical owner")
  assert(emit(seat, spectator, "SetCardMark", {102, "@mark", 2})[1] == 102)
  assert(emit(seat, spectator, "SetCardMark", {103, "@mark", 2})[1] == 103)
  assert(emit(seat, spectator, "SetCardMark", {106, "@mark", 2})[1] == 106)
  fails(seat, owner, "SetCardMark", {104, "@mark", 2}, "draw-pile")
  fails(seat, owner, "SetCardMark", {100, "@mark", {cardId = 101}}, "finite scalar")
  fails(seat, owner, "SetCardMark", {999, "@mark", 1}, "not audited")
end)

check("card metadata notifications use per-physical references and envelopes", function()
  local footnote = { {100, 103}, { type = "##Probe", from = 11, arg = "reason" }, false }
  local ownerFootnote = emit(seat, owner, "SetCardFootnote", footnote)
  local observerFootnote = emit(seat, spectator, "SetCardFootnote", footnote)
  assert(ownerFootnote.cardWireVersion == 1 and ownerFootnote.payload[1][1] == 100 and
    ownerFootnote.payload[1][2] == 103)
  hidden(observerFootnote.payload[1][1])
  assert(observerFootnote.payload[1][2] == 103 and
    observerFootnote.payload[2].arg == "reason")
  assert(emit(seat, spectator, "SetCardVirtName", {{7001}, "slash", true}).payload[1][1] == 7001)

  local ownerFilter = emit(seat, owner, "FilterCard", {100, seat, false})
  local observerFilter = emit(seat, spectator, "FilterCard", {100, seat, false})
  assert(ownerFilter.payload[1] == 100 and ownerFilter.payload[2] == 11)
  hidden(observerFilter.payload[1])
  local drawFilter = emit(seat, spectator, "FilterCard", {104, nil, false})
  assert(drawFilter.payload[1] == -1 and drawFilter.payload[2] == nil and
    drawFilter.payload[3] == false)

  local hand = {11, {100}}
  assert(emit(seat, owner, "SetPlayerHandCards", hand).payload[2][1] == 100)
  hidden(emit(seat, spectator, "SetPlayerHandCards", hand).payload[2][1])

  local equip = { player = 11, name = "probe_equip", subcards = {100, 103} }
  local observerEquip = emit(seat, spectator, "AddVirtualEquip", equip)
  hidden(observerEquip.payload.subcards[1])
  assert(observerEquip.payload.subcards[2] == 103)
  assert(emit(seat, spectator, "RemoveVirtualEquip", {player = 11, id = 103}).payload.id == 103)
  fails(seat, spectator, "SetCardVirtName", {{104}, "slash", false}, "draw-pile")
  fails(seat, spectator, "AddVirtualEquip", {
    player = 11, name = "probe_equip", subcards = {100}, extra = 1,
  }, "unaudited field")
end)

check("AG notifications explicitly reveal the same public card refs", function()
  local filled = emit(seat, spectator, "FillAG", {{104, 105}, {105}})
  assert(filled.cardWireVersion == 1 and filled.payload[1][1] == 104 and
    filled.payload[1][2] == 105 and filled.payload[2][1] == 105)
  local taken = emit(seat, spectator, "TakeAG", {11, 104})
  assert(taken.cardWireVersion == 1 and taken.payload[1] == 11 and
    taken.payload[2] == 104)
  fails(seat, spectator, "FillAG", {{104}, {[2] = 105}}, "sparse")
  fails(seat, spectator, "TakeAG", {13, 104}, "taker is missing")
end)

check("GameOver validates public winner IDs and preserves the upstream scalar", function()
  assert(emit(seat, spectator, "GameOver", "11+12") == "11+12")
  assert(emit(seat, spectator, "GameOver", "") == "")
  fails(seat, spectator, "GameOver", "11+13", "winner is missing")
  fails(seat, spectator, "GameOver", "11++12", "malformed")
  fails(seat, spectator, "GameOver", {11}, "must be a string")
end)

check("non-card notifications use explicit metadata schemas", function()
  local seatsOut = emit(seat, spectator, "ArrangeSeats", {11, 12})
  assert(seatsOut[1] == 11 and seatsOut[2] == 12)

  local observer = emit(seat, spectator, "AddObserver",
    {77, "watcher", "avatar", false, 10})
  assert(observer[1] == 77 and observer[2] == "watcher" and observer[5] == 10)
  assert(emit(seat, spectator, "RemoveObserver", {77})[1] == 77)
  assert(emit(seat, spectator, "AddNpc", {-1, "bot", "avatar", true, 0})[1] == -1)

  local chat = emit(seat, spectator, "Chat", {type = 2, sender = 11, msg = "hello"})
  assert(chat.type == 2 and chat.sender == 11 and chat.msg == "hello")
  local skin = emit(seat, spectator, "ChangeSkin", {11, "changeskin", "main", "deputy"})
  assert(skin[1] == 11 and skin[2] == "changeskin" and skin[4] == "deputy")
  local printed = emit(seat, spectator, "PrintCard", {"slash", 1, 7})
  assert(printed[1] == "slash" and printed[2] == 1 and printed[3] == 7)
  local printedNumberOnly = emit(seat, spectator, "PrintCard", {"slash", nil, 7})
  assert(printedNumberOnly[1] == "slash" and printedNumberOnly[2] == nil and
    printedNumberOnly[3] == 7)
  local quest = emit(seat, spectator, "UpdateQuestSkillUI", {11, "quest_skill"})
  assert(quest[1] == 11 and quest[2] == "quest_skill")
  assert(emit(seat, spectator, "AddBuddy", {11, 12})[2] == 12)
  assert(emit(seat, spectator, "RmBuddy", {11, 12})[2] == 12)

  local indicate = emit(seat, spectator, "Animate", {
    type = "Indicate", from = 11, to = {{12}},
  })
  assert(indicate.type == "Indicate" and indicate.from == 11 and indicate.to[1][1] == 12)
  local emotion = emit(seat, spectator, "Animate", {
    type = "Emotion", player = 11, emotion = "damage", permanent = false,
  })
  assert(emotion.player == 11 and emotion.emotion == "damage")
  local cardEmotion = emit(seat, spectator, "Animate", {
    type = "Emotion", player = 103, emotion = "glow", is_card = true,
  })
  assert(cardEmotion.player == 103 and cardEmotion.is_card == true)
  assert(emit(seat, spectator, "Animate", {type = "HideEmotion", player = 11}).player == 11)
  assert(emit(seat, spectator, "Animate", {
    type = "InvokeSkill", name = "wusheng", player = 11, skill_type = "special",
  }).player == 11)
  assert(emit(seat, spectator, "Animate", {
    type = "InvokeUltSkill", name = "wusheng", player = 11, deputy = false,
  }).deputy == false)
  local box = emit(seat, spectator, "Animate", {
    type = "SuperLightBox", data = {text = "probe", contentAreaSize = {1, 2}},
  })
  assert(box.data.text == "probe" and box.data.contentAreaSize[2] == 2)
  fails(seat, spectator, "Animate", {
    type = "Emotion", player = 100, emotion = "hidden", is_card = true,
  }, "not public")
  fails(seat, spectator, "Animate", {type = "Unknown"}, "unaudited Animate type")

  local damage = emit(seat, spectator, "LogEvent", {
    type = "Damage", to = 12, damageType = "normal_damage", damageNum = 1,
  })
  assert(damage.to == 12 and damage.damageNum == 1)
  assert(emit(seat, spectator, "LogEvent", {type = "LoseHP"}).type == "LoseHP")
  local maxHp = emit(seat, spectator, "LogEvent", {
    type = "ChangeMaxHp", player = 11, num = -1,
  })
  assert(maxHp.player == 11 and maxHp.num == -1)
  assert(emit(seat, spectator, "LogEvent", {type = "Death", to = 11}).to == 11)
  assert(emit(seat, spectator, "LogEvent", {type = "PlaySound", name = "system/test"}).name == "system/test")
  local skillSound = emit(seat, spectator, "LogEvent", {
    type = "PlaySkillSound", name = "wusheng", i = -1,
    general = "concealed_general", deputy = "concealed_deputy",
  })
  assert(skillSound.general == nil and skillSound.deputy == nil)
  fails(seat, spectator, "LogEvent", {type = "Unknown", cardId = 100}, "unaudited field")

  assert(emit(seat, spectator, "ChangeSelf", 12) == 12)
  assert(emit(seat, spectator, "RoomOwner", {12})[1] == 12)
  assert(emit(seat, spectator, "CloseSurrenderNegotiation", {"n:1"})[1] == "n:1")
  local ask = emit(seat, spectator, "AskForSurrenderNegotiation", {"n:1", 11, "Alice"})
  assert(ask[2] == 11 and ask[3] == "Alice")
  assert(emit(seat, spectator, "PrelightSkill", {"fake_skill", true})[2] == true)
  fails(seat, spectator, "Chat", {type = 2, sender = 11, msg = "ok", cardId = 100},
    "unaudited field")
end)

check("public ShowCard projection reveals only audited canonical IDs", function()
  local shown = emit(seat, spectator, "ShowCard", {{100, 101, 102}, 11, 77})
  assert(shown[1][1] == 100 and shown[1][2] == 101 and shown[1][3] == 102 and
    shown[2] == 11 and shown[3] == 77)
  fails(seat, spectator, "ShowCard", {{100}, 11}, "expects [cards,source,eventId]")
  fails(seat, spectator, "ShowVirtualCard", {{id = 100}, 11, "", 77}, "invalid index")
end)

check("ShowVirtualCard uses public card descriptors and audited footnotes", function()
  local virtual = cardObject({
    id = 0, name = "slash", suit = 1, number = 7, color = 1,
    subcards = {100}, skillNames = {"probe_skill"}, virt_id = 9001,
    mark = { ["@probe"] = 1 },
  })
  local footnote = {
    type = "#UseCard", from = 11, to = {12}, card = {virtual},
    arg = "probe", arg2 = cardObject({id = 102}), toast = false,
  }
  local shown = emit(seat, spectator, "ShowVirtualCard", {virtual, 11, footnote, 77})
  assert(shown.cardWireVersion == 1 and type(shown.payload) == "table")
  local descriptor = shown.payload[1][1]
  assert(descriptor.cardWireCard == 1 and descriptor.kind == "virtual" and
    descriptor.name == "slash" and descriptor.subcards[1] == 100 and
    descriptor.virt_id == 9001 and descriptor.mark["@probe"] == 1 and
    descriptor.id == nil and descriptor.extra_data == nil)
  local note = shown.payload[3]
  assert(note.type == "#UseCard" and note.card[1].kind == "virtual" and
    note.arg2.kind == "real" and note.arg2.ref == 102)
  fails(seat, spectator, "ShowVirtualCard", {
    cardObject({id = 0, name = "slash", suit = 1, number = 7, color = 1,
      subcards = {}, skillNames = {}, virt_id = 1, mark = { secret = 1 }}),
    11, nil, 78,
  }, "unaudited mark")
end)

check("GameLog preserves concealed mappings and projects only visible cards", function()
  local real = cardObject({id = 103})
  local spectatorState = handles.audiences[spectator.key]
  local concealedBefore = spectatorState and spectatorState.byId[100]
  local result = emit(seat, spectator, "GameLog", {
    type = "#ResponsePlayCard", from = 11, to = {12},
    card = {100, real, -1}, arg = "probe", arg2 = real, toast = true,
  })
  assert(result.cardWireVersion == 1 and result.payload.type == "#ResponsePlayCard")
  assert(result.payload.card[1] == -1 and result.payload.card[2].kind == "real" and
    result.payload.card[2].ref == 103 and result.payload.card[3] == -1 and
    result.payload.arg == "probe" and result.payload.arg2.kind == "real" and
    result.payload.arg2.ref == 103 and result.payload.toast == true)
  assert(handles.audiences[spectator.key].byId[100] == concealedBefore,
    "concealed GameLog card must not republish or mutate its standing handle")
  local ownerResult = emit(seat, owner, "GameLog", {
    type = "#ResponsePlayCard", card = {100}, arg2 = real,
  })
  assert(ownerResult.payload.card[1] == 100 and ownerResult.payload.arg2.ref == 103)
  fails(seat, spectator, "GameLog", {
    type = "#Bad", arg = { nested = { cardId = 100 } },
  }, "unaudited table")
end)

check("Reconnect and Observe snapshots use count-only deck and physical refs", function()
  local snapshot = {
    settings = { gameMode = "new_heg_mode" },
    card_manager = {
      draw_pile = {104}, discard_pile = {105}, processing_area = {}, void = {},
      printed_cards = {}, card_marks = cbor.encode({
        [100] = { ["@owner"] = 1 },
        [101] = { ["@secret"] = 2 },
        [105] = { ["@public"] = 3 },
      }),
    },
    players = {
      [11] = { player_cards = {
        [Card.PlayerHand] = {100}, [Card.PlayerEquip] = {103}, [Card.PlayerJudge] = {},
      }, special_cards = { ["$concealed"] = {101}, public = {102} }, virtual_equips = {},
        mark = cbor.encode({_extra_turn_count = {"hidden_skill", "threaten_emperor_skill"}, unrelated = 2}) },
    },
    you = 11,
  }
  local ownerOut = emit(seat, owner, "Reconnect", snapshot)
  assert(ownerOut.cardWireVersion == 1 and type(ownerOut.payload) == "table")
  local ownerPayload = ownerOut.payload
  local ownerTurnMarks = cbor.decode(ownerPayload.players[11].mark)
  assert(ownerTurnMarks._extra_turn_count[1] == "hidden_skill" and ownerTurnMarks.unrelated == 2)
  assert(ownerPayload.card_manager.draw_pile.count == 1 and
    ownerPayload.card_manager.draw_pile[1] == nil)
  local ownerHand = ownerPayload.players[11].player_cards[Card.PlayerHand][1]
  local ownerSecret = ownerPayload.players[11].special_cards["$concealed"][1]
  assert(ownerHand == 100 and ownerSecret == 101)
  assert(ownerPayload.players[11].player_cards[Card.PlayerEquip][1] == 103 and
    ownerPayload.players[11].special_cards.public[1] == 102)
  local ownerMarks = cbor.decode(ownerPayload.card_manager.card_marks)
  assert(ownerMarks[100]["@owner"] == 1 and ownerMarks[101]["@secret"] == 2 and
    ownerMarks[105]["@public"] == 3)

  local observerOut = emit(seat, spectator, "Observe", snapshot)
  local observerPayload = observerOut.payload
  local observerTurnMarks = cbor.decode(observerPayload.players[11].mark)
  assert(table.concat(observerTurnMarks._extra_turn_count, ",") == "_tqs_extra_turn,threaten_emperor_skill")
  assert(observerTurnMarks.unrelated == 2 and cbor.decode(snapshot.players[11].mark)._extra_turn_count[1] == "hidden_skill")
  local opponentPayload = emit(otherSeat, opponent, "Reconnect", snapshot).payload
  assert(cbor.decode(opponentPayload.players[11].mark)._extra_turn_count[1] == "_tqs_extra_turn")
  local observerHand = observerPayload.players[11].player_cards[Card.PlayerHand][1]
  assert(type(observerHand) == "string" and observerHand ~= ownerHand and
    observerPayload.card_manager.draw_pile.count == 1)
  local observerMarks = cbor.decode(observerPayload.card_manager.card_marks)
  assert(observerMarks[105]["@public"] == 3 and observerMarks[ownerHand] == nil)

  fails(seat, owner, "Reconnect", {
    card_manager = {
      draw_pile = {104}, discard_pile = {105}, processing_area = {}, void = {},
      printed_cards = {}, card_marks = cbor.encode({
        [105] = { ["@bad"] = { cardId = 105 } },
      }),
    },
    players = snapshot.players,
  }, "snapshot card marks value")

  local staleBatch = handles:beginBatch()
  local stale = staleBatch:reference("owner", 100, false)
  staleBatch:commit()
  local refreshed = emit(seat, owner, "Reconnect", snapshot)
  assert(refreshed.payload.players[11].player_cards[Card.PlayerHand][1] ~= stale,
    "Reconnect must reset only the returning physical audience")

  fails(seat, owner, "Reconnect", {
    card_manager = snapshot.card_manager,
    players = {[11] = { player_cards = snapshot.players[11].player_cards,
      special_cards = snapshot.players[11].special_cards, virtual_equips = {{id = 100}} }},
  }, "virtual equipment")
end)

check("projection errors after issuing a card ref abort the entire batch", function()
  local batch = handles:beginBatch()
  local first = projector.project(room, seat, spectator, "MoveCards", packet(), batch)
  hidden(first[1][1].moveInfo[1].cardId)
  local ok = pcall(projector.project, room, seat, spectator,
    "SetCardMark", {100, "@mark", {cardId = 100}}, batch)
  assert(not ok)
  batch:abort()
  assert(handles.activeBatch == nil)
end)

check("unknown notifications, bad version and wrong mode fail closed", function()
  fails(seat, spectator, "AskForCustomDialog", {}, "unaudited")
  room.card_wire_version = nil
  fails(seat, spectator, "MoveCards", packet(), "negotiated Hegemony v1")
  room.card_wire_version = 1
  local original = room.getSettings
  function room:getSettings() return "identity" end
  fails(seat, spectator, "MoveCards", packet(), "negotiated Hegemony v1")
  room.getSettings = original
end)

check("Tuc Trieu target mark allows the actual skill to complete", function()
  local effects = {}
  fk = { EventPhaseEnd = "phase_end", CreateSkill = function(skill)
    function skill:addEffect(event, effect) effects[event] = effect end
    return skill
  end }
  Fk = { loadTranslationTable = function() end }
  Util = { FalseFunc = function() return false end }
  function table.insertTable(self, list)
    for _, item in ipairs(list) do table.insert(self, item) end
  end
  local skill = dofile(assert(arg[3], "Suchao skill path required"))
  local markName = skill.name .. "-phase"
  local third = { id = 13 }
  local fourth = { id = 14 }
  seats[13], seats[14] = third, fourth
  local targets = {otherSeat, third, fourth}
  local mark, damage, recovery, slash = 0, {}, {}, {}
  seat.room = room
  function seat:getTableMark() return type(mark) == "table" and mark or {} end
  function room:setPlayerMark(player, name, value)
    assert(player == seat and name == markName)
    mark = value -- Matches ServerRoomBase:setPlayerMark: store before broadcasting.
    for _, audience in ipairs({{seat, owner}, {otherSeat, opponent}, {seat, spectator}}) do
      local out = emit(audience[1], audience[2], "SetPlayerMark", {player.id, name, value})[3]
      assert(out ~= value and #out == #value)
      for i, target in ipairs(value) do assert(out[i] == target) end
    end
  end
  function room:sortByAction() end
  function room:damage(data)
    assert(data.from == seat and data.damage == 1 and data.skillName == skill.name)
    damage[#damage + 1] = data.to
  end
  function room:recover(data)
    assert(data.num == 1 and data.who == data.recoverBy and data.skillName == skill.name)
    recovery[#recovery + 1] = data.who
  end
  function room:askToUseCard(player, data)
    assert(data.pattern == "slash" and data.extra_data.exclusive_targets[1] == seat.id)
    slash[#slash + 1] = player
    return {from = player}
  end
  function room:useCard(use) assert(use.extraUse == true) end
  for n = 1, 3 do
    mark, damage, recovery, slash = 0, {}, {}, {}
    local chosen = {table.unpack(targets, 1, n)}
    local ok, problem = pcall(effects.active.on_use, nil, room, {from = seat, tos = chosen})
    if not ok then
      assert(#mark == n and #damage == 0)
      error("Suchao mark stored but no damage executed: " .. tostring(problem))
    end
    assert(#damage == n and #recovery == 0 and #slash == 0)
    effects.phase_end.on_use(nil, nil, seat, seat)
    assert(#recovery == n and #slash == n)
    for i = 1, n do
      assert(damage[i] == chosen[i] and recovery[i] == chosen[i] and slash[i] == chosen[i])
    end
  end
  for _, audience in ipairs({{seat, owner}, {otherSeat, opponent}, {seat, spectator}}) do
    assert(emit(audience[1], audience[2], "SetPlayerMark", {11, markName, 0})[3] == 0)
    for _, bad in ipairs({{100}, {{id = 12}}, {"12"}, {[2] = otherSeat}}) do
      fails(audience[1], audience[2], "SetPlayerMark", {11, markName, bad}, markName)
    end
    fails(audience[1], audience[2], "SetPlayerMark", {11, markName, 100}, markName)
  end
  seats[13], seats[14] = nil, nil
end)

print(string.format("PASS audited card-wire projection: %d synthetic physical/privacy/schema cases; native/browser NOT RUN", count))
