-- Isolated Hegemony v1 client handling for projected MoveCards and
-- SetPlayerPile packets. The server keeps canonical IDs; this module maps
-- opaque references to client-local numeric aliases before CardManager sees
-- them. It is candidate-only and does not negotiate or enable v1.
local Moves = {}

local MAX_ENTRIES = 8192
local MIN_LOCAL, MAX_LOCAL = 1000000000, 1999999999

local function integer(value, name)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    name .. " must be an integer")
  return value
end

local function denseCount(list, name)
  assert(type(list) == "table", name .. " must be an array")
  local count, maximum = 0, 0
  for index in pairs(list) do
    integer(index, name .. " index")
    assert(index >= 1, name .. " index must be positive")
    count = count + 1
    if index > maximum then maximum = index end
  end
  assert(count == maximum and count <= MAX_ENTRIES, name .. " must be dense and bounded")
  return count
end

local function canonical(value, name)
  integer(value, name)
  assert((value >= 1 or value <= -2) and
    (value < MIN_LOCAL or value > MAX_LOCAL),
    name .. " cannot be a local alias")
end

local function opaque(value, name)
  assert(type(value) == "string" and #value >= 18 and #value <= 128 and
    value:sub(1, 2) == "h:" and value:sub(3):match("^[%w_-]+$") ~= nil,
    name .. " must be an opaque card reference")
end

local function wireReference(value, name)
  if type(value) == "string" then
    opaque(value, name)
  else
    canonical(value, name)
  end
end

local function copyArray(value)
  local result = {}
  for i, entry in ipairs(value) do result[i] = entry end
  return result
end

local moveKeys = {
  moveInfo = true, from = true, to = true, toArea = true,
  moveReason = true, proposer = true, skillName = true,
  moveVisible = true, specialName = true, specialVisible = true,
  drawPilePosition = true, visiblePlayers = true,
}

local infoKeys = {
  cardId = true, fromArea = true, fromSpecialName = true,
  cardWireRetiredRefs = true,
}

local function negotiated(room, label)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    label .. " requires negotiated Hegemony v1")
end

local function playerFor(room, id, label)
  assert(type(id) == "number", label .. " owner is required")
  integer(id, label .. " owner")
  local player = room:getPlayerById(id)
  assert(player, label .. " player is missing")
  return player
end

local function listFor(room, area, ownerId, specialName)
  if area == Card.DrawPile then return room.draw_pile end
  if area == Card.DiscardPile then return room.discard_pile end
  if area == Card.Processing then return room.processing_area end
  if area == Card.Void then return room.void end

  if area == Card.PlayerHand or area == Card.PlayerEquip or area == Card.PlayerJudge then
    local player = playerFor(room, ownerId, "MoveCards source")
    player.player_cards[area] = player.player_cards[area] or {}
    return player.player_cards[area]
  end

  if area == Card.PlayerSpecial then
    assert(type(specialName) == "string" and specialName ~= "",
      "MoveCards special source name is required")
    local player = playerFor(room, ownerId, "MoveCards special source")
    player.special_cards[specialName] = player.special_cards[specialName] or {}
    return player.special_cards[specialName]
  end
  error("MoveCards source area is not audited")
end

local function indexOf(list, value)
  for index, current in ipairs(list or {}) do
    if current == value then return index end
  end
  return nil
end

local function clearCardArea(room, id)
  if room.card_place[id] ~= nil then
    room.card_place[id] = nil
    room.owner_map[id] = nil
  end
end

local function retireLocal(room, id)
  if room.card_wire_refs:isHiddenLocal(id) then
    room.card_wire_refs:retire(id)
  elseif room.card_wire_refs:isAnonymous(id) then
    room.card_wire_refs:retire(id)
  end
end

local function replaceSource(room, area, ownerId, specialName, oldId, newId)
  local list = listFor(room, area, ownerId, specialName)
  local index = indexOf(list, oldId)
  assert(index, "MoveCards retired reference is absent from its source area")
  if oldId ~= newId then
    assert(not indexOf(list, newId), "MoveCards incoming reference is duplicated in its source")
    list[index] = newId
    clearCardArea(room, oldId)
    retireLocal(room, oldId)
    room:setCardArea(newId, area, ownerId)
  end
end

local function resolveRetired(room, reference)
  if type(reference) == "string" then
    local id = room.card_wire_refs.byToken[reference]
    if id == nil then
      -- Keep the rejection fail-closed, but distinguish a token which was
      -- already retired locally from one which never crossed this physical
      -- connection.  The distinction is bounded diagnostic metadata only;
      -- never include the opaque token or its card identity in an exception.
      local state = room.card_wire_refs.retiredTokens[reference] and
        "already-retired" or "unseen"
      error("MoveCards retired opaque reference is unknown or stale (" .. state .. ")", 0)
    end
    return id
  end
  return reference
end

local function drawPosition(room, move)
  local position = move.drawPilePosition
  if position == nil then position = 1 end
  integer(position, "MoveCards drawPilePosition")
  if position == -1 then position = #(room.draw_pile or {}) end
  assert(position >= 1 and position <= #(room.draw_pile or {}),
    "MoveCards draw source position is out of range")
  return position
end

local function replaceAnonymousDrawSlot(room, move, newId, reservedPositions)
  local function drawStage(label, fn)
    local ok, first = pcall(fn)
    if not ok and type(first) == "string" and
        first:match("^TQS_QA_CARD_WIRE_APPLY_DRAW_OLD_") then
      error(first, 0)
    end
    if not ok then error("TQS_QA_CARD_WIRE_APPLY_DRAW_" .. label, 0) end
    return first
  end

  local position = drawStage("POSITION", function()
    local requested = drawPosition(room, move)
    local step = move.drawPilePosition == -1 and -1 or 1
    local candidate = requested
    while reservedPositions[candidate] do candidate = candidate + step end
    assert(candidate >= 1 and candidate <= #(room.draw_pile or {}),
      "MoveCards draw source position is out of range")
    reservedPositions[candidate] = true
    return candidate
  end)
  local oldId = room.draw_pile[position]
  drawStage("ANONYMOUS", function()
    if not room.card_wire_refs:isAnonymous(oldId) then
      local kind
      if oldId == nil then
        kind = "MISSING"
      elseif type(oldId) ~= "number" then
        kind = "NON_NUMERIC"
      elseif room.card_wire_refs.byLocal[oldId] ~= nil then
        kind = "KNOWN_LOCAL"
      elseif room.card_wire_refs:isHiddenLocal(oldId) then
        kind = "RETIRED_LOCAL"
      else
        kind = "CANONICAL_OR_OTHER"
      end
      error("TQS_QA_CARD_WIRE_APPLY_DRAW_OLD_" .. kind, 0)
    end
  end)
  drawStage("NEW_AREA", function()
    assert(room.card_place[newId] == nil,
      "MoveCards incoming draw reference already belongs to an area")
  end)
  room.draw_pile[position] = newId
  clearCardArea(room, oldId)
  retireLocal(room, oldId)
  room:setCardArea(newId, Card.DrawPile, nil)
end

local function validateVisiblePlayers(value)
  if value == nil then return end
  if type(value) == "number" then
    integer(value, "MoveCards visible player")
    return
  end
  local count = denseCount(value, "MoveCards visiblePlayers")
  for i = 1, count do integer(value[i], "MoveCards visible player") end
end

local function validateMove(move)
  assert(type(move) == "table", "MoveCards entry must be a table")
  for key in pairs(move) do
    assert(moveKeys[key] == true, "MoveCards entry contains an unaudited field")
  end
  assert(type(move.toArea) == "number", "MoveCards destination area is required")
  integer(move.toArea, "MoveCards destination area")
  denseCount(move.moveInfo, "MoveCards moveInfo")
  for _, key in ipairs({ "from", "to", "proposer", "moveReason", "drawPilePosition" }) do
    assert(move[key] == nil or type(move[key]) == "number",
      "MoveCards " .. key .. " must be numeric")
    if move[key] ~= nil then integer(move[key], "MoveCards " .. key) end
  end
  for _, key in ipairs({ "skillName", "specialName" }) do
    assert(move[key] == nil or type(move[key]) == "string",
      "MoveCards " .. key .. " must be a string")
  end
  assert(move.moveVisible == nil or type(move.moveVisible) == "boolean",
    "MoveCards moveVisible must be boolean")
  assert(move.specialVisible == nil or type(move.specialVisible) == "boolean",
    "MoveCards specialVisible must be boolean")
  validateVisiblePlayers(move.visiblePlayers)
  for _, info in ipairs(move.moveInfo) do
    assert(type(info) == "table", "MoveCards moveInfo entry must be a table")
    for key in pairs(info) do
      assert(infoKeys[key] == true, "MoveCards info contains an unaudited field")
    end
    wireReference(info.cardId, "MoveCards card reference")
    integer(info.fromArea, "MoveCards source area")
    assert(info.fromSpecialName == nil or type(info.fromSpecialName) == "string",
      "MoveCards source pile name must be a string")
    if info.cardWireRetiredRefs ~= nil then
      local count = denseCount(info.cardWireRetiredRefs,
        "MoveCards retired references")
      for i = 1, count do
        wireReference(info.cardWireRetiredRefs[i], "MoveCards retired reference")
      end
    end
  end
end

local function normalize(data)
  assert(type(data) == "table" and denseCount(data, "MoveCards packet") == 2,
    "MoveCards expects [moves,eventId]")
  integer(data[2], "MoveCards event ID")
  denseCount(data[1], "MoveCards moves")

  local moves = {}
  for i, move in ipairs(data[1]) do
    validateMove(move)
    local out = {}
    for key, value in pairs(move) do
      if key ~= "moveInfo" then
        out[key] = type(value) == "table" and copyArray(value) or value
      end
    end
    out.moveInfo = {}
    local entries = {}
    for j, info in ipairs(move.moveInfo) do
      local outInfo = {
        fromArea = info.fromArea,
      }
      if info.fromSpecialName ~= nil then
        outInfo.fromSpecialName = info.fromSpecialName
      end
      entries[j] = {
        move = move,
        info = info,
        output = outInfo,
        wireId = info.cardId,
        retired = info.cardWireRetiredRefs or {},
      }
      table.insert(out.moveInfo, outInfo)
    end
    moves[i] = { input = move, output = out, entries = entries }
  end
  return moves, data[2]
end

local function copyMap(value)
  local result = {}
  for key, item in pairs(value or {}) do result[key] = item end
  return result
end

local function copyList(value)
  local result = {}
  for index, item in ipairs(value or {}) do result[index] = item end
  return result
end

local function clonePlayer(player)
  local result = {}
  for key, value in pairs(player or {}) do
    if key == "player_cards" or key == "special_cards" then
      result[key] = {}
      for area, cards in pairs(value or {}) do
        result[key][area] = copyList(cards)
      end
    else
      result[key] = value
    end
  end
  return result
end

-- A MoveCards packet may contain a chain in which a later entry retires the
-- opaque reference minted by an earlier entry in the same packet.  Validate
-- that chain against a private state clone first, then apply it sequentially
-- to the real room.  This preserves the old all-or-nothing behavior for
-- malformed packets without rejecting valid intra-packet dependencies.
local function cloneForPreflight(room)
  local shadow = {
    card_place = copyMap(room.card_place),
    owner_map = copyMap(room.owner_map),
    draw_pile = copyList(room.draw_pile),
    discard_pile = copyList(room.discard_pile),
    processing_area = copyList(room.processing_area),
    void = copyList(room.void),
    players = {},
  }
  for index, player in ipairs(room.players or {}) do
    shadow.players[index] = clonePlayer(player)
  end

  shadow.card_wire_refs = room.card_wire_refs:fork(function(id)
    return shadow.card_place[id] ~= nil
  end)

  setmetatable(shadow, { __index = function(_, key) return room[key] end })
  return shadow
end

local function preflightEntry(room, entry)
  local move, info = entry.move, entry.info
  local oldIds = {}
  for _, reference in ipairs(entry.retired) do
    table.insert(oldIds, resolveRetired(room, reference))
  end
  if #oldIds > 1 then
    error("MoveCards supports one retired reference per card transition")
  end

  if info.fromArea == Card.DrawPile then
    local position = drawPosition(room, move)
    assert(room.card_wire_refs:isAnonymous(room.draw_pile[position]),
      "MoveCards draw source is not anonymous")
  else
    local expected = type(entry.wireId) == "string" and
      room.card_wire_refs.byToken[entry.wireId] or entry.wireId
    if expected == nil then
      assert(#oldIds == 1,
        "MoveCards hidden reference is unknown without a transition ref")
    else
      local source = listFor(room, info.fromArea, move.from, info.fromSpecialName)
      if #oldIds == 1 then
        assert(indexOf(source, oldIds[1]),
          "MoveCards retired reference is absent from its source area")
      else
        assert(indexOf(source, expected),
          "MoveCards stable reference is absent from its source area")
      end
    end
  end
end

local function applyEntry(room, entry, reservedDrawPositions)
  local move, info = entry.move, entry.info
  local refs = room.card_wire_refs
  local function applyStage(label, fn)
    local ok, first = pcall(fn)
    if not ok then
      if type(first) == "string" and
          first:match("^TQS_QA_CARD_WIRE_APPLY_DRAW_") then
        error(first, 0)
      end
      error("TQS_QA_CARD_WIRE_APPLY_" .. label, 0)
    end
    return first
  end

  local newId = applyStage("TO_LOCAL", function()
    -- A card entering the concealed draw pile has no stable client-visible
    -- identity.  The server may send a fresh opaque reference for the
    -- source-to-draw rekey, but retaining that alias in draw_pile would let
    -- later MoveCards link the card to its prior hand/equipment location.
    -- Mint a positional anonymous slot instead; the legacy CardManager can
    -- still move that local ID through the source and destination atomically.
    if move.toArea == Card.DrawPile then
      assert(type(refs.mintAnonymous) == "function",
        "anonymous draw slot allocator is unavailable")
      return refs:mintAnonymous()
    end
    return refs:toLocal(entry.wireId)
  end)
  local oldIds = {}
  for _, reference in ipairs(entry.retired) do
    table.insert(oldIds, applyStage("RESOLVE_RETIRED", function()
      return resolveRetired(room, reference)
    end))
  end

  if info.fromArea == Card.DrawPile then
    applyStage("DRAW_SLOT", function()
      replaceAnonymousDrawSlot(room, move, newId, reservedDrawPositions)
    end)
    for _, oldId in ipairs(oldIds) do
      applyStage("RETIRE_DRAW", function() retireLocal(room, oldId) end)
    end
  elseif #oldIds == 1 then
    applyStage("SOURCE_REPLACE", function()
      replaceSource(room, info.fromArea, move.from, info.fromSpecialName,
        oldIds[1], newId)
    end)
  else
    local source = listFor(room, info.fromArea, move.from, info.fromSpecialName)
    applyStage("STABLE_SOURCE", function()
      assert(indexOf(source, newId),
        "MoveCards stable reference disappeared before application")
    end)
  end
  entry.output.cardId = newId
end

local function applyLegacyMoveInfo(room, move, info)
  local id = info.cardId
  local fromArea = room.card_place[id]
  local fromOwner = room.owner_map[id]
  local source = fromArea and listFor(room, fromArea, fromOwner,
    info.fromSpecialName) or nil
  if not source then return false end
  local sourceIndex = indexOf(source, id)
  if not sourceIndex then return false end
  table.remove(source, sourceIndex)

  local destination = listFor(room, move.toArea, move.to, move.specialName)
  if move.toArea == Card.DrawPile then
    local position = move.drawPilePosition or 1
    if position == -1 then
      position = #destination + 1
    elseif position < 1 or position > #destination + 1 then
      position = 1
    end
    table.insert(destination, position, id)
  else
    table.insert(destination, id)
  end
  room:setCardArea(id, move.toArea, move.to)
  return true
end

local function localizedMove(move, entry)
  local result = {}
  for key, value in pairs(move.output) do
    if key ~= "moveInfo" then
      result[key] = type(value) == "table" and copyArray(value) or value
    end
  end
  result.moveInfo = { entry.output }
  return result
end

local function trackerPile(tracker, owner, pile)
  if type(tracker.getKnownCardsByArea) == "function" then
    return tracker:getKnownCardsByArea(Card.PlayerSpecial, owner, pile)
  end
  tracker.player_cards = tracker.player_cards or {}
  tracker.player_cards[owner.id] = tracker.player_cards[owner.id] or {}
  tracker.player_cards[owner.id][Card.PlayerSpecial] =
    tracker.player_cards[owner.id][Card.PlayerSpecial] or {}
  tracker.player_cards[owner.id][Card.PlayerSpecial][pile] =
    tracker.player_cards[owner.id][Card.PlayerSpecial][pile] or {
      known_cards = {}, uncertain_cards = {},
    }
  return tracker.player_cards[owner.id][Card.PlayerSpecial][pile]
end

local function removeEverywhere(room, id)
  local function removeFrom(list)
    if not list then return end
    for index = #list, 1, -1 do
      if list[index] == id then table.remove(list, index) end
    end
  end
  removeFrom(room.draw_pile)
  removeFrom(room.discard_pile)
  removeFrom(room.processing_area)
  removeFrom(room.void)
  for _, player in ipairs(room.players or {}) do
    for _, area in ipairs({ Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge }) do
      removeFrom(player.player_cards and player.player_cards[area])
    end
    for _, ids in pairs(player.special_cards or {}) do removeFrom(ids) end
  end
  clearCardArea(room, id)
end

function Moves.receive(room, data)
  negotiated(room, "projected MoveCards")
  assert(room.card_wire_refs and room.card_wire_refs.toLocal,
    "v1 client-local card references are unavailable")
  local moves, eventId = normalize(data)
  local shadow = cloneForPreflight(room)
  local shadowReservedDrawPositions = {}
  for _, move in ipairs(moves) do
    for _, entry in ipairs(move.entries) do
      preflightEntry(shadow, entry)
      applyEntry(shadow, entry, shadowReservedDrawPositions)
      assert(applyLegacyMoveInfo(shadow, move.output, entry.output),
        "MoveCards preflight could not apply projected legacy transition")
    end
  end
  local reservedDrawPositions = {}
  for _, move in ipairs(moves) do
    for _, entry in ipairs(move.entries) do
      -- The clone above has validated the whole packet.  Keep a per-entry
      -- preflight on the real room as a final invariant check, now that
      -- dependencies from earlier entries are present in the live mapping.
      preflightEntry(room, entry)
      applyEntry(room, entry, reservedDrawPositions)
      room:moveCardsLegacy({ { localizedMove(move, entry) }, eventId })
    end
  end
end

local function validatePile(data)
  assert(type(data) == "table" and denseCount(data, "SetPlayerPile") == 3,
    "SetPlayerPile expects [owner,pile,references]")
  integer(data[1], "SetPlayerPile owner")
  assert(type(data[2]) == "string" and data[2] ~= "",
    "SetPlayerPile pile name is required")
  local count = denseCount(data[3], "SetPlayerPile references")
  for i = 1, count do wireReference(data[3][i], "SetPlayerPile reference") end
end

function Moves.receivePile(room, data)
  negotiated(room, "projected SetPlayerPile")
  assert(room.card_wire_refs and room.card_wire_refs.toLocal,
    "v1 client-local card references are unavailable")
  validatePile(data)
  local owner = playerFor(room, data[1], "SetPlayerPile")
  local pile = data[2]
  local rawRefs = data[3]
  local ids = {}
  local seen = {}
  for i, reference in ipairs(rawRefs) do
    local id = room.card_wire_refs:toLocal(reference)
    assert(not seen[id], "SetPlayerPile contains a duplicate reference")
    seen[id] = true
    ids[i] = id
  end

  -- Keep a snapshot: removeEverywhere also removes the ID from the live
  -- special-pile array, so iterating that array in place would skip every
  -- second stale alias during a full replacement.
  local previous = copyArray(owner.special_cards[pile] or {})
  for _, id in ipairs(previous) do
    if not seen[id] then
      removeEverywhere(room, id)
      retireLocal(room, id)
    end
  end
  for _, id in ipairs(ids) do
    removeEverywhere(room, id)
    room:setCardArea(id, Card.PlayerSpecial, owner.id)
  end
  owner.special_cards[pile] = ids

  for _, observer in ipairs(room.players or {}) do
    local tracker = observer.card_tracker
    if tracker then
      local known = trackerPile(tracker, owner, pile)
      known.known_cards = {}
      known.uncertain_cards = {}
      for i, id in ipairs(ids) do
        if type(rawRefs[i]) == "number" then
          table.insert(known.known_cards, id)
        else
          table.insert(known.uncertain_cards, id)
        end
      end
    end
  end
  return #ids
end

return Moves
