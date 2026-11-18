-- Candidate-only, opt-in v1 wire projection. Server card IDs stay canonical.
-- Only explicitly audited commands are accepted. The full v1 protocol must
-- remain disabled until the client alias/choice and snapshot paths exist.
local Projection = {}

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do
    assert(type(key) == "number" or type(key) == "string",
      "snapshot contains an unsupported key type")
    result[copy(key)] = copy(item)
  end
  return result
end

local function denseCount(array, label)
  assert(type(array) == "table", label .. " must be an array")
  local count, max = 0, 0
  for index in pairs(array) do
    assert(type(index) == "number" and index % 1 == 0 and index >= 1,
      label .. " has an invalid index")
    count = count + 1
    if index > max then max = index end
  end
  assert(count == max, label .. " must not be sparse")
  return count
end

local function fields(record, allow, label)
  assert(type(record) == "table", label .. " must be a table")
  for key in pairs(record) do
    assert(allow[key] == true, label .. " contains an unaudited field")
  end
end

local function cardId(id)
  assert(type(id) == "number" and id % 1 == 0 and (id >= 1 or id <= -2),
    "invalid canonical card ID")
end

local function isOwner(seat, physical, id)
  return type(id) == "number" and id == seat.id and
    seat._splayer == physical
end

local function isNamedViewer(seat, physical, players)
  if type(players) == "number" then
    return seat.id == players and seat._splayer == physical
  end
  if players == nil then return false end
  denseCount(players, "visiblePlayers")
  local listed = false
  for _, playerId in ipairs(players) do
    assert(type(playerId) == "number", "visiblePlayers must contain player IDs")
    if playerId == seat.id then listed = true end
  end
  return listed and seat._splayer == physical
end

local moveKeys = {
  moveInfo = true, from = true, to = true, toArea = true,
  moveReason = true, proposer = true, skillName = true,
  moveVisible = true, specialName = true, specialVisible = true,
  drawPilePosition = true, visiblePlayers = true,
  moveMark = true, extra_data = true,
}
local infoKeys = {
  cardId = true, fromArea = true, fromSpecialName = true,
  beforeCard = true, virtualEquip = true,
}
local publicAreaKeys = {
  "PlayerEquip", "PlayerJudge", "Processing", "DiscardPile", "Void",
}

local function isPublicArea(area)
  for _, key in ipairs(publicAreaKeys) do
    if Card[key] ~= nil and area == Card[key] then return true end
  end
  return false
end

local function isPrivateSource(area, specialName)
  if area == Card.PlayerHand then return true end
  if area == Card.PlayerSpecial then
    return type(specialName) == "string" and specialName:sub(1, 1) == "$"
  end
  return false
end

local function isOwnerId(room, seat, physical, id)
  local owner = room:getPlayerById(id)
  return owner ~= nil and isOwner(seat, physical, id)
end

local function cardPrivateAt(room, id)
  local area = room:getCardArea(id)
  if area == Card.PlayerHand then return true end
  if area == Card.PlayerSpecial then
    local owner = room:getCardOwner(id)
    assert(owner and type(owner.getPileNameOfId) == "function",
      "snapshot private-pile owner lookup required")
    local name = owner:getPileNameOfId(id)
    assert(type(name) == "string", "snapshot private-pile name required")
    return name:sub(1, 1) == "$"
  end
  return false
end

local function snapshotList(room, seat, physical, batch, audience, ids, visible, label)
  denseCount(ids, label)
  for _, id in ipairs(ids) do cardId(id) end
  return batch:project(audience, ids, function()
    return visible
  end)
end

local function snapshotPlayer(room, seat, physical, batch, audience, id, record)
  assert(type(record) == "table", "snapshot player record must be a table")
  local result = copy(record)
  assert(type(record.player_cards) == "table", "snapshot player cards missing")
  result.player_cards = {}
  for area, ids in pairs(record.player_cards) do
    assert(type(area) == "number" and
      (area == Card.PlayerHand or area == Card.PlayerEquip or
        area == Card.PlayerJudge), "snapshot player card area is not audited")
    local visible = area ~= Card.PlayerHand or isOwnerId(room, seat, physical, id)
    result.player_cards[area] = snapshotList(room, seat, physical, batch,
      audience, ids, visible, "snapshot player cards")
  end

  assert(type(record.special_cards) == "table", "snapshot special cards missing")
  result.special_cards = {}
  for pile, ids in pairs(record.special_cards) do
    assert(type(pile) == "string" and pile ~= "",
      "snapshot special pile name is required")
    local visible = pile:sub(1, 1) ~= "$" or
      isOwnerId(room, seat, physical, id)
    result.special_cards[pile] = snapshotList(room, seat, physical, batch,
      audience, ids, visible, "snapshot special cards")
  end

  -- A Card object in virtual_equips is CBOR-tagged with its canonical ID.
  -- Keep this candidate path fail-closed until its subcard visibility schema
  -- is audited; sending the raw object would defeat the snapshot projector.
  if result.virtual_equips and #result.virtual_equips > 0 then
    error("snapshot virtual equipment is not audited")
  end
  return result
end

local function scalar(value, label)
  local kind = type(value)
  assert(kind == "boolean" or kind == "string" or
    (kind == "number" and value == value and
      value ~= math.huge and value ~= -math.huge),
    label .. " must be a finite scalar")
  return value
end

-- CardManager:serialize stores card marks as cardId -> { markName -> value }.
-- The outer cardId is projected below; audit the inner map separately so a
-- reconnect/observe snapshot preserves the upstream shape without allowing a
-- table-valued mark to smuggle card IDs or other unaudited data across CBOR.
local function cardMarkMap(value, label)
  assert(type(value) == "table", label .. " must be a mark map")
  local result = {}
  for mark, markValue in pairs(value) do
    assert(type(mark) == "string" and mark ~= "",
      label .. " names must be non-empty strings")
    result[mark] = scalar(markValue, label .. " value")
  end
  return result
end

local cardManagerKeys = {
  draw_pile = true, discard_pile = true, processing_area = true,
  void = true, printed_cards = true, card_marks = true,
}

local function projectSnapshot(room, seat, physical, command, data, batch, audience)
  assert(command == "Reconnect" or command == "Observe",
    "snapshot command is not audited")
  assert(type(data) == "table" and type(data.card_manager) == "table" and
    type(data.players) == "table", "snapshot shape is not audited")
  batch:resetAudience(audience)

  local result = copy(data)
  local cardManager = data.card_manager
  fields(cardManager, cardManagerKeys, "snapshot card manager")
  local projectedManager = copy(cardManager)
  local draw = cardManager.draw_pile
  denseCount(draw, "snapshot draw pile")
  for _, id in ipairs(draw) do cardId(id) end
  -- Snapshot deck order is intentionally not sent. The client creates fresh
  -- anonymous local slots from this count before legacy deserialization.
  projectedManager.draw_pile = { count = #draw }
  for _, area in ipairs({ "discard_pile", "processing_area", "void" }) do
    local ids = cardManager[area]
    denseCount(ids, "snapshot " .. area)
    projectedManager[area] = batch:project(audience, ids, function()
      return true
    end)
  end

  if cardManager.card_marks ~= nil then
    assert(type(cardManager.card_marks) == "string",
      "snapshot card marks must be CBOR")
    local marks = cbor.decode(cardManager.card_marks)
    assert(type(marks) == "table", "snapshot card marks must decode to a table")
    local projectedMarks = {}
    for id, value in pairs(marks) do
      cardId(id)
      local markMap = cardMarkMap(value, "snapshot card marks")
      local private = cardPrivateAt(room, id)
      local owner = room:getCardOwner(id)
      local ownerId = owner and owner.id
      if room:getCardArea(id) ~= Card.DrawPile and
          (not private or isOwnerId(room, seat, physical, ownerId)) then
        local ownerVisible = not private or isOwnerId(room, seat, physical, ownerId)
        projectedMarks[batch:reference(audience, id, ownerVisible)] = markMap
      end
    end
    projectedManager.card_marks = next(projectedMarks) and
      cbor.encode(projectedMarks) or nil
  end
  result.card_manager = projectedManager

  result.players = {}
  for id, record in pairs(data.players) do
    assert(type(id) == "number" and id % 1 == 0,
      "snapshot player map key must be numeric")
    result.players[id] = snapshotPlayer(room, seat, physical, batch,
      audience, id, record)
  end
  return { cardWireVersion = 1, payload = result }
end

local function projectMoves(seat, physical, data, batch, audience)
  assert(type(data) == "table" and denseCount(data, "MoveCards packet") == 2,
    "MoveCards expects [moves,eventId]")
  assert(type(data[2]) == "number", "MoveCards event ID required")
  denseCount(data[1], "MoveCards moves")
  local result = {}
  for i, move in ipairs(data[1]) do
    fields(move, moveKeys, "MoveCards move")
    assert(type(move.toArea) == "number" and type(move.moveInfo) == "table",
      "MoveCards area and moveInfo required")
    for _, key in ipairs({ "from", "to", "proposer", "moveReason", "drawPilePosition" }) do
      assert(move[key] == nil or
        (type(move[key]) == "number" and move[key] % 1 == 0),
        "MoveCards " .. key .. " must be a numeric scalar")
    end
    for _, key in ipairs({ "skillName", "specialName" }) do
      assert(move[key] == nil or type(move[key]) == "string",
        "MoveCards " .. key .. " must be a string")
    end
    assert(move.moveVisible == nil or type(move.moveVisible) == "boolean",
      "MoveCards moveVisible must be boolean")
    assert(move.specialVisible == nil or type(move.specialVisible) == "boolean",
      "MoveCards specialVisible must be boolean")
    -- The upstream server uses these internal fields to finish the event,
    -- but the native client moveCards/applyMoveInfo consumer does not read
    -- them. Card:__tocbor encodes beforeCard as a canonical ID (or virtual
    -- card with raw subcards); never CBOR-encode these objects on the wire.
    -- Keep rejecting every unaudited top-level/MoveInfo field.
    denseCount(move.moveInfo, "moveInfo")
    local visiblePlayers = move.visiblePlayers
    if visiblePlayers ~= nil then
      if type(visiblePlayers) == "table" then
        denseCount(visiblePlayers, "visiblePlayers")
        for _, id in ipairs(visiblePlayers) do
          assert(type(id) == "number" and id % 1 == 0,
            "visiblePlayers must contain player IDs")
        end
      else
        assert(type(visiblePlayers) == "number" and visiblePlayers % 1 == 0,
          "visiblePlayers must contain player IDs")
      end
    end
    local out = {}
    for key, value in pairs(move) do
      if key ~= "moveInfo" and key ~= "moveMark" and key ~= "extra_data" then
        out[key] = value
      end
    end
    out.moveInfo = {}
    for j, info in ipairs(move.moveInfo) do
      fields(info, infoKeys, "MoveCards info")
      cardId(info.cardId)
      assert(type(info.fromArea) == "number", "MoveCards fromArea required")
      assert(info.fromSpecialName == nil or type(info.fromSpecialName) == "string",
        "MoveCards fromSpecialName must be a string")
      local namedViewer = isNamedViewer(seat, physical, move.visiblePlayers)
      local authorized = isOwner(seat, physical, move.from)
        or isOwner(seat, physical, move.to) or namedViewer
      local shown = move.moveVisible == true or
        (move.moveVisible == nil and isPublicArea(move.toArea)) or
        (move.specialVisible == true and isPublicArea(move.toArea))
      -- A private $ pile is never a public destination, even after a
      -- previously revealed move. Retire its old public handle on rehide.
      if move.toArea == Card.PlayerSpecial and type(move.specialName) == "string"
          and move.specialName:sub(1, 1) == "$" then shown = false end
      local outInfo = {}
      for key, value in pairs(info) do
        if key ~= "cardId" and key ~= "beforeCard" and key ~= "virtualEquip" then
          outInfo[key] = value
        end
      end
      -- Deck order must not be linkable through a previously issued handle,
      -- including on explicit face-up moves back to the draw pile. A fresh
      -- local reference is minted on entering or leaving the hidden deck.
      -- For a non-owner, also publish the old audience reference when a card
      -- crosses the public/private boundary. The client needs that opaque
      -- token (or canonical public ID) to replace its old local alias before
      -- applying the new MoveCards ID; it must never infer the old ID.
      if move.toArea == Card.DrawPile then shown = false; authorized = false end
      local publicForAudience = shown or authorized
      -- Destination authorization does not describe the source alias: a
      -- gaining owner may still hold an opaque reference in the source hand.
      -- Compare the actual standing visibility; unchanged hidden/public
      -- moves retain their stable identity, while deck moves always rekey.
      local current = batch:currentReference(audience, info.cardId)
      local needsRekey = info.fromArea == Card.DrawPile or move.toArea == Card.DrawPile or
        (current ~= nil and (type(current) == "number") ~= publicForAudience)
      local retiredRefs = needsRekey and batch:rekey(audience, { info.cardId }) or {}
      outInfo.cardId = batch:reference(audience, info.cardId, publicForAudience)
      if #retiredRefs > 0 then outInfo.cardWireRetiredRefs = retiredRefs end
      out.moveInfo[j] = outInfo
    end
    result[i] = out
  end
  return { result, data[2] }
end

local function projectPile(room, seat, physical, data, batch, audience)
  assert(denseCount(data, "SetPlayerPile") == 3, "SetPlayerPile expects 3 fields")
  local ownerId, pile, ids = data[1], data[2], data[3]
  assert(type(ownerId) == "number" and type(pile) == "string" and pile ~= "",
    "invalid SetPlayerPile owner/pile")
  assert(room:getPlayerById(ownerId), "SetPlayerPile owner missing")
  denseCount(ids, "SetPlayerPile IDs")
  local owner = isOwner(seat, physical, ownerId)
  local public = pile:sub(1, 1) ~= "$"
  local refs = batch:project(audience, ids, function(id)
    cardId(id)
    return owner or public
  end)
  return { ownerId, pile, refs }
end

-- Metadata is not intrinsically safe just because its top-level command does
-- not contain a cardId field. Some marks carry arrays of physical card IDs.
-- Admit audited shapes only, and copy tables before they reach the CBOR codec.

local function stringArray(value, label, length)
  local n = denseCount(value, label)
  assert(length == nil or n == length, label .. " has invalid length")
  local copy = {}
  for i = 1, n do
    assert(type(value[i]) == "string", label .. " must contain names")
    copy[i] = value[i]
  end
  return copy
end

local function numberArray(value, label)
  local n = denseCount(value, label)
  local copy = {}
  for i = 1, n do
    assert(type(value[i]) == "number" and value[i] % 1 == 0,
      label .. " must contain slot numbers")
    copy[i] = value[i]
  end
  return copy
end

local function stringMap(value, label)
  assert(type(value) == "table", label .. " must be a map")
  local result = {}
  for key, sources in pairs(value) do
    assert(type(key) == "string" and key ~= "",
      label .. " keys must be skill names")
    result[key] = stringArray(sources, label .. " sources")
  end
  return result
end

local scalarProperties = {
  hp = true, maxHp = true, shield = true, MaxCards = true,
  dying = true, dead = true, drank = true, rest = true,
  chained = true, faceup = true, phase = true,
  state = true, surrendered = true, role_shown = true,
}
local stringIdentityProperties = {
  role = true, general = true, deputyGeneral = true,
  kingdom = true,
}
local numericIdentityProperties = { gender = true }
local hiddenGender = 4
if type(Fk) == "table" and type(Fk.generals) == "table" and
    type(Fk.generals.anjiang) == "table" and
    type(Fk.generals.anjiang.gender) == "number" then
  hiddenGender = Fk.generals.anjiang.gender
end

local function projectProperty(room, seat, physical, data)
  local count = denseCount(data, "PropertyUpdate")
  assert(count == 2 or count == 3,
    "PropertyUpdate expects [player,property,value]")
  local id, key, value = data[1], data[2], data[3]
  assert(type(id) == "number" and id % 1 == 0 and
    type(key) == "string" and room:getPlayerById(id),
    "PropertyUpdate player/property invalid")
  local target = room:getPlayerById(id)
  local owner = isOwner(seat, physical, id)
  -- ServerRoomBase:broadcastProperty(self, "state") is emitted after a
  -- reconnect, but the LTK ServerPlayer keeps the transport state on its
  -- native `serverplayer` object rather than on the Lua game-player table.
  -- The legacy path therefore supplies a nil third array item. Resolve that
  -- one audited property from the native accessor instead of forwarding nil
  -- (or accepting an arbitrary object/table as a state value).
  if key == "state" and value == nil then
    assert(target.serverplayer and type(target.serverplayer.getState) == "function",
      "PropertyUpdate state accessor is unavailable")
    value = target.serverplayer:getState()
  end
  if key == "MaxCards" and value == nil then
    assert(type(target.getMaxCards) == "function",
      "MaxCards property value is unavailable")
    value = target:getMaxCards()
  end
  if stringIdentityProperties[key] then
    assert(type(value) == "string", "identity property must be a string")
    if not owner and not room.game_finished then
      if key == "role" then
        assert(value == "hidden" or target.role_shown == true,
          "concealed role cannot be sent to a nonowner")
      elseif key == "general" or key == "deputyGeneral" then
        assert(value == "anjiang" or
          (target.role_shown == true and target[key] == value),
          "concealed general cannot be sent to a nonowner")
      elseif key == "kingdom" then
        assert(value == "unknown" or value == "hidden" or
          (target.role_shown == true and target[key] == value),
          "concealed faction metadata cannot be sent to a nonowner")
      end
    end
  elseif numericIdentityProperties[key] then
    assert(type(value) == "number" and value == value and
      value ~= math.huge and value ~= -math.huge and value % 1 == 0,
      "identity property must be an integer")
    if not owner and not room.game_finished and not target.role_shown then
      assert(value == hiddenGender, "concealed gender cannot be sent to a nonowner")
    end
  elseif scalarProperties[key] then
    scalar(value, "PropertyUpdate value")
  elseif key == "sealedSlots" or key == "equipSlots" then
    value = numberArray(value, "PropertyUpdate slots")
  else
    error("unaudited PropertyUpdate property: " .. key)
  end
  return { id, key, value }
end

local privateMarks = {
  __heg_general = true, __heg_deputy = true,
  __heg_kingdom = true, __heg_init_kingdom = true,
  __heg_join_wild = true, __heg_construct_wild = true,
  __heg_wild = true, InitialGeneral = true,
  ExtraAttachedSkills = true, HalfMaxHpLeft = true,
  CompanionEffect = true,
}

local invalidSkillMarkPrefix = "InvalidSkills"

local function isInvalidSkillMark(mark)
  return mark == invalidSkillMarkPrefix or
    mark:sub(1, #invalidSkillMarkPrefix + 1) == invalidSkillMarkPrefix .. "-"
end

local function visibleGeneralSkills(target)
  local visible = {}
  if type(Fk) ~= "table" or type(Fk.generals) ~= "table" then
    return visible
  end
  for _, key in ipairs({ "general", "deputyGeneral" }) do
    local name = target[key]
    if type(name) == "string" and name ~= "" and name ~= "anjiang" then
      local general = Fk.generals[name]
      if general and type(general.getSkillNameList) == "function" then
        for _, skillName in ipairs(general:getSkillNameList(true)) do
          if type(skillName) == "string" then visible[skillName] = true end
        end
      end
    end
  end
  return visible
end

local function projectInvalidSkillMark(room, seat, physical, id, target, value)
  -- Room:clearHistory resets scoped invalidity marks to numeric zero. That is
  -- a public removal marker, not the skill-source map used while invalidity
  -- is active.
  if value == 0 then return value end
  local sanitized = stringMap(value, "InvalidSkills mark")
  if isOwner(seat, physical, id) or room.game_finished then
    return sanitized
  end

  -- Invalidity carries skill names.  Keep names from a concealed general
  -- owner-only; after a general is revealed, expose only skills belonging to
  -- the currently public general pair.  The source list is copied and remains
  -- string-only, so it cannot carry a physical card identity.
  local visible = visibleGeneralSkills(target)
  local result = {}
  for skillName, sources in pairs(sanitized) do
    if visible[skillName] then result[skillName] = sources end
  end
  return result
end

-- Upstream table marks are not one wire type.  These explicit schemas cover
-- the Hegemony marks whose values are player references, player IDs, or
-- general-name strings.  Numeric arrays are deliberately not accepted by a
-- generic fallback: a number in a public mark can be a physical card ID.
local playerObjectMarks = {
  ["reveal_intention-turn"] = true,
  ["gouni"] = true,
  ["@@heg__fengguo"] = true,
  ["@@ld__congcha"] = true,
  ["ld__jinxian_targets-turn"] = true,
  ["ofl_heg__xionghuo-turn"] = true,
  ["ofl_heg__xionghuo_prohibit-turn"] = true,
  ["@@nos_heg__zhidao-turn"] = true,
  ["m_heg__fenxun-turn"] = true,
}
local playerIdMarks = {
  ["fenxun-turn"] = true,
  ["sanchen-turn"] = true,
  ["@@ofl_heg__dianhu"] = true,
  ["ofl_heg__dianhu"] = true,
}
local stringTableMarks = {
  -- Luanji records the suits already consumed this turn. It is public
  -- string-only state; admitting it explicitly keeps the projector fail-closed
  -- for arbitrary tables while allowing the real Hegemony skill to continue.
  ["@hs__luanji-turn"] = true,
  -- Jilei stores the declared card category as a string-only table mark.
  ["@jilei-turn"] = true,
}

local function playerReference(room, value, label)
  assert(type(value) == "table" and type(value.id) == "number" and
    value.id % 1 == 0 and room:getPlayerById(value.id) == value,
    label .. " must contain live player references")
  return value
end

local function playerObjectArray(room, value, label)
  local n = denseCount(value, label)
  local result = {}
  for i = 1, n do result[i] = playerReference(room, value[i], label) end
  return result
end

local function playerIdArray(room, value, label)
  local n = denseCount(value, label)
  local result = {}
  for i = 1, n do
    local id = value[i]
    assert(type(id) == "number" and id % 1 == 0 and room:getPlayerById(id),
      label .. " must contain player IDs")
    result[i] = id
  end
  return result
end

-- Yi Gui stores the current UseExtraData while it is asking the player for a
-- virtual card. This is public metadata, not a generic Lua table: target
-- lists contain player IDs and the remaining admitted fields are booleans.
-- Card-bearing or function-bearing extensions stay fail-closed instead of
-- being mistaken for harmless numeric metadata.
local useExtraDataPlayerArrays = {
  must_targets = true,
  include_targets = true,
  exclusive_targets = true,
  fix_targets = true,
}
local useExtraDataBooleans = {
  bypass_distances = true,
  bypass_times = true,
  extraUse = true,
  not_passive = true,
  playing = true,
}

local function projectYiguiExtraData(room, value)
  fields(value, {
    must_targets = true, include_targets = true, exclusive_targets = true,
    fix_targets = true, fix_user = true, bypass_distances = true,
    bypass_times = true, extraUse = true, not_passive = true, playing = true,
  }, "ld__yigui_extra_data")
  local result = {}
  for key, item in pairs(value) do
    if useExtraDataPlayerArrays[key] then
      result[key] = playerIdArray(room, item, key .. " player ID list")
    elseif key == "fix_user" then
      assert(type(item) == "number" and item % 1 == 0 and room:getPlayerById(item),
        "fix_user must contain a live player ID")
      result[key] = item
    else
      assert(useExtraDataBooleans[key], "ld__yigui_extra_data field is not scalar")
      result[key] = scalar(item, key)
    end
  end
  return result
end

local function projectNamedTableMark(room, mark, value)
  if playerObjectMarks[mark] then
    return playerObjectArray(room, value, mark .. " player list")
  end
  if playerIdMarks[mark] then
    return playerIdArray(room, value, mark .. " player ID list")
  end
  if stringTableMarks[mark] then
    return stringArray(value, mark .. " string list")
  end
  if mark == "ld__yigui_extra_data" then
    return projectYiguiExtraData(room, value)
  end
  if mark == "xiongsuan-turn" then
    assert(denseCount(value, "xiongsuan-turn") == 2,
      "xiongsuan-turn expects [skill,player]")
    assert(type(value[1]) == "string" and value[1] ~= "",
      "xiongsuan-turn skill name is required")
    return { value[1], playerReference(room, value[2], "xiongsuan-turn target") }
  end
  if mark:sub(1, 2) == "@&" or mark == "RevealProhibited" or
      mark:sub(1, #"RevealProhibited-") == "RevealProhibited-" then
    return stringArray(value, mark .. " string list")
  end
  error("public player mark must be a finite scalar or an audited table: " .. mark)
end

local function projectPlayerMark(room, seat, physical, data)
  assert(denseCount(data, "SetPlayerMark") == 3,
    "SetPlayerMark expects [player,mark,value]")
  local id, mark, value = data[1], data[2], data[3]
  assert(type(id) == "number" and id % 1 == 0 and
    type(mark) == "string" and mark ~= "" and room:getPlayerById(id),
    "SetPlayerMark player/mark invalid")
  if privateMarks[mark] then
    assert(isOwner(seat, physical, id), "private mark requires physical owner")
    if mark == "InitialGeneral" and type(value) == "table" then
      value = stringArray(value, "InitialGeneral", 2)
    elseif mark == "ExtraAttachedSkills" and type(value) == "table" then
      value = stringArray(value, "ExtraAttachedSkills")
    else
      scalar(value, "private player mark")
    end
  elseif isInvalidSkillMark(mark) then
    value = projectInvalidSkillMark(room, seat, physical, id,
      room:getPlayerById(id), value)
  elseif type(value) == "table" then
    value = projectNamedTableMark(room, mark, value)
  else
    assert(mark:sub(1, 6) ~= "__heg_", "unknown private Hegemony mark")
    scalar(value, "public player mark")
  end
  return { id, mark, value }
end

local function projectCardMark(room, seat, physical, data, batch, audience)
  assert(denseCount(data, "SetCardMark") == 3,
    "SetCardMark expects [card,mark,value]")
  local id, mark, value = data[1], data[2], data[3]
  cardId(id)
  assert(type(mark) == "string" and mark ~= "", "SetCardMark name required")
  scalar(value, "SetCardMark value")
  assert(type(room.getCardArea) == "function" and
    type(room.getCardOwner) == "function", "SetCardMark needs live card location")
  local area = room:getCardArea(id)
  -- AbstractRoom:getCardOwner returns the Player object, whereas the lower
  -- CardManager:getCardOwner returns its numeric ID. This projector runs on
  -- the Room/AbstractRoom interface.
  local cardOwner = room:getCardOwner(id)
  local owner = cardOwner and isOwner(seat, physical, cardOwner.id)
  local private = area == Card.PlayerHand
  if area == Card.PlayerSpecial then
    assert(type(room.getPlayerById) == "function", "pile owner lookup required")
    assert(cardOwner and type(cardOwner.getPileNameOfId) == "function",
      "pile name lookup required")
    local name = cardOwner:getPileNameOfId(id)
    assert(type(name) == "string", "pile name required")
    private = name:sub(1, 1) == "$"
  end
  assert(area ~= Card.DrawPile, "draw-pile mark must stay server-only")
  assert(not private or owner, "concealed card mark requires physical owner")
  assert(private or area == Card.PlayerSpecial or isPublicArea(area),
    "card mark area not audited")
  -- The physical owner already receives canonical hand/private-pile IDs and
  -- the legacy SetCardMark callback consumes that numeric ID directly. For
  -- an outsider, however, a public mark can be emitted just before the
  -- matching MoveCards packet; keep the outsider's standing handle until
  -- MoveCards performs the explicit rekey.
  local reference = private and owner and batch:reference(audience, id, true)
    or batch:standing(audience, id, true)
  return { reference, mark, value }
end

local function projectShowCard(data, batch, audience)
  assert(type(data) == "table" and denseCount(data, "ShowCard") == 3,
    "ShowCard expects [cards,source,eventId]")
  denseCount(data[1], "ShowCard cards")
  for _, id in ipairs(data[1]) do cardId(id) end
  assert(data[2] == nil or (type(data[2]) == "number" and data[2] % 1 == 0),
    "ShowCard source must be numeric")
  assert(type(data[3]) == "number" and data[3] % 1 == 0,
    "ShowCard event ID must be numeric")
  local refs = {}
  for i, id in ipairs(data[1]) do refs[i] = batch:standing(audience, id, true) end
  return {
    refs,
    data[2], data[3],
  }
end

local function isCardObject(value)
  if type(value) ~= "table" or type(value.isInstanceOf) ~= "function" or
      type(Card) ~= "table" then
    return false
  end
  local ok, result = pcall(value.isInstanceOf, value, Card)
  return ok and result == true
end

local function integerValue(value, label)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    label .. " must be a finite integer")
  return value
end

-- GameLog is projected before the live-area helper is defined below. Keep the
-- lookup lexical so a concealed log card cannot fall back to a public ID.
local physicalCardVisibility

local function projectCardWireCard(card, batch, audience, label)
  assert(isCardObject(card), label .. " must be a Card object")
  assert(type(card.isVirtual) == "function", label .. " virtual-card check is missing")
  if not card:isVirtual() then
    cardId(card.id)
    return {
      cardWireCard = 1,
      kind = "real",
      ref = batch:standing(audience, card.id, true),
    }
  end

  local subcards = card.subcards or {}
  denseCount(subcards, label .. " subcards")
  for _, id in ipairs(subcards) do cardId(id) end
  local publicSubcards = {}
  for i, id in ipairs(subcards) do
    publicSubcards[i] = batch:standing(audience, id, true)
  end
  local descriptor = {
    cardWireCard = 1,
    kind = "virtual",
    name = card.name,
    suit = card.suit,
    number = card.number,
    color = card.color,
    subcards = publicSubcards,
    skillNames = stringArray(card.skillNames or {}, label .. " skill names"),
    virt_id = card.virt_id or 0,
  }
  assert(type(descriptor.name) == "string" and descriptor.name ~= "",
    label .. " name is required")
  integerValue(descriptor.suit, label .. " suit")
  integerValue(descriptor.number, label .. " number")
  integerValue(descriptor.color, label .. " color")
  integerValue(descriptor.virt_id, label .. " virt_id")

  -- Only UI-facing @ marks are reconstructed by Card:__toqml. Other virtual
  -- mark namespaces are skill-defined and are not safe to serialize here.
  local marks = card.mark or {}
  assert(type(marks) == "table", label .. " marks must be a table")
  local projectedMarks = {}
  for mark, value in pairs(marks) do
    assert(type(mark) == "string" and mark:sub(1, 1) == "@",
      label .. " contains an unaudited mark")
    projectedMarks[mark] = scalar(value, label .. " mark")
  end
  if next(projectedMarks) ~= nil then descriptor.mark = projectedMarks end
  return descriptor
end

local function logCardIsVisible(room, seat, physical, id, label)
  cardId(id)
  -- A draw-pile card has no stable public identity in v1. GameLog has no
  -- retiredRefs field with which to rekey a recipient, so use the upstream
  -- unknown sentinel instead of mutating a concealed audience mapping.
  if room:getCardArea(id) == Card.DrawPile then return false end
  return physicalCardVisibility(room, seat, physical, id, label)
end

local function projectLogCardValue(value, room, seat, physical, batch, audience, label)
  if isCardObject(value) then
    if not value:isVirtual() and not logCardIsVisible(room, seat, physical,
        value.id, label .. " ID") then
      return -1
    end
    return projectCardWireCard(value, batch, audience, label)
  end
  assert(type(value) == "number", label .. " must be a card ID or Card")
  if value == -1 then return value end
  if not logCardIsVisible(room, seat, physical, value, label) then return -1 end
  return batch:standing(audience, value, true)
end

local function projectLogCards(value, room, seat, physical, batch, audience, label)
  local count = denseCount(value, label)
  local result = {}
  for i = 1, count do
    result[i] = projectLogCardValue(value[i], room, seat, physical, batch, audience,
      label .. " entry")
  end
  return result
end

local function projectLogValue(value, room, seat, physical, batch, audience, label)
  if isCardObject(value) then
    if not value:isVirtual() and not logCardIsVisible(room, seat, physical,
        value.id, label .. " ID") then
      return -1
    end
    return projectCardWireCard(value, batch, audience, label)
  end
  assert(type(value) ~= "table", label .. " contains an unaudited table")
  return scalar(value, label)
end

local logKeys = {
  type = true, from = true, to = true, card = true, toast = true,
  arg = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true,
  arg6 = true, arg7 = true, arg8 = true, arg9 = true,
}

local function projectGameLog(room, seat, physical, data, batch, audience)
  fields(data, logKeys, "GameLog")
  assert(type(data.type) == "string" and data.type ~= "", "GameLog type required")
  local result = { type = data.type }
  if data.from ~= nil then
    result.from = integerValue(data.from, "GameLog from")
  end
  if data.to ~= nil then
    local count = denseCount(data.to, "GameLog targets")
    result.to = {}
    for i = 1, count do
      result.to[i] = integerValue(data.to[i], "GameLog target")
    end
  end
  if data.card ~= nil then
    result.card = projectLogCards(data.card, room, seat, physical, batch,
      audience, "GameLog cards")
  end
  if data.toast ~= nil then
    assert(type(data.toast) == "boolean", "GameLog toast must be boolean")
    result.toast = data.toast
  end
  for _, key in ipairs({ "arg", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9" }) do
    if data[key] ~= nil then
      result[key] = projectLogValue(data[key], room, seat, physical, batch,
        audience, "GameLog " .. key)
    end
  end
  return result
end

-- Metadata notifications below still carry physical card IDs in the
-- upstream payload.  Resolve visibility from the live area at projection
-- time; an unknown/draw-pile card is never silently treated as public.
physicalCardVisibility = function(room, seat, physical, id, label)
  cardId(id)
  assert(type(room.getCardArea) == "function" and
    type(room.getCardOwner) == "function",
    label .. " needs live card location")
  local area = room:getCardArea(id)
  assert(area ~= Card.DrawPile, label .. " draw-pile card is not audited")
  if isPublicArea(area) then return true end

  local owner = room:getCardOwner(id)
  if area == Card.PlayerHand then
    assert(owner and type(owner.id) == "number",
      label .. " hand-card owner is missing")
    return isOwner(seat, physical, owner.id)
  end
  if area == Card.PlayerSpecial then
    assert(owner and type(owner.id) == "number" and
      type(owner.getPileNameOfId) == "function",
      label .. " special-pile owner is missing")
    local pile = owner:getPileNameOfId(id)
    assert(type(pile) == "string" and pile ~= "",
      label .. " special-pile name is missing")
    return pile:sub(1, 1) ~= "$" or isOwner(seat, physical, owner.id)
  end
  error(label .. " card area is not audited")
end

local function projectPhysicalCardIds(room, seat, physical, ids, batch,
    audience, label)
  local count = denseCount(ids, label)
  local visible, refs = {}, {}
  for i = 1, count do
    visible[i] = physicalCardVisibility(room, seat, physical, ids[i], label)
  end
  for i = 1, count do
    refs[i] = batch:standing(audience, ids[i], visible[i])
  end
  return refs
end

local function projectMetadataLog(data)
  fields(data, logKeys, "SetCardFootnote log")
  assert(type(data.type) == "string" and data.type ~= "",
    "SetCardFootnote log type required")
  assert(data.card == nil, "SetCardFootnote log cards are not audited")
  local result = { type = data.type }
  if data.from ~= nil then
    result.from = integerValue(data.from, "SetCardFootnote log from")
  end
  if data.to ~= nil then
    local count = denseCount(data.to, "SetCardFootnote log targets")
    result.to = {}
    for i = 1, count do
      result.to[i] = integerValue(data.to[i], "SetCardFootnote log target")
    end
  end
  if data.toast ~= nil then
    assert(type(data.toast) == "boolean",
      "SetCardFootnote log toast must be boolean")
    result.toast = data.toast
  end
  for _, key in ipairs({ "arg", "arg2", "arg3", "arg4", "arg5",
      "arg6", "arg7", "arg8", "arg9" }) do
    if data[key] ~= nil then
      assert(type(data[key]) == "string",
        "SetCardFootnote log " .. key .. " must be a string")
      result[key] = data[key]
    end
  end
  return result
end

local function metadataEnvelope(payload)
  return { cardWireVersion = 1, payload = payload }
end

-- Amazing Grace is an intentional public reveal, even when the physical
-- cards are still located in the draw pile. The display packet is metadata,
-- however: keep the audience's standing source reference unchanged until the
-- matching MoveCards packet carries the explicit retired reference.
local function projectPublicCardIds(ids, batch, audience, label)
  denseCount(ids, label)
  local refs = {}
  for i, id in ipairs(ids) do
    cardId(id)
    refs[i] = batch:standing(audience, id, true)
  end
  return refs
end

local function projectFillAG(data, batch, audience)
  local count = denseCount(data, "FillAG")
  assert(count == 1 or count == 2, "FillAG expects [ids,disabledIds]")
  local result = { projectPublicCardIds(data[1], batch, audience, "FillAG IDs") }
  if data[2] ~= nil then
    result[2] = projectPublicCardIds(data[2], batch, audience,
      "FillAG disabled IDs")
  end
  return metadataEnvelope(result)
end

local function projectTakeAG(room, data, batch, audience)
  assert(denseCount(data, "TakeAG") == 2,
    "TakeAG expects [taker,card]")
  local taker = integerValue(data[1], "TakeAG taker ID")
  assert(room:getPlayerById(taker), "TakeAG taker is missing")
  cardId(data[2])
  return metadataEnvelope({ taker, batch:standing(audience, data[2], true) })
end

local function projectGameOver(room, data)
  assert(type(data) == "string", "GameOver winners must be a string")
  if data == "" then return data end
  local ids = {}
  for token in data:gmatch("[^+]+") do
    local id = tonumber(token)
    assert(id and id % 1 == 0 and tostring(id) == token,
      "GameOver winner ID is invalid")
    assert(room:getPlayerById(id), "GameOver winner is missing")
    ids[#ids + 1] = token
  end
  assert(#ids > 0 and table.concat(ids, "+") == data,
    "GameOver winner list is malformed")
  return data
end

local function metadataPlayerId(room, value, label)
  if value == nil then return nil end
  local id = type(value) == "number" and value or value.id
  id = integerValue(id, label .. " player ID")
  assert(room:getPlayerById(id), label .. " player is missing")
  return id
end

local function projectCardFootnote(room, seat, physical, data, batch, audience)
  assert(denseCount(data, "SetCardFootnote") == 3,
    "SetCardFootnote expects [ids,log,virtual]")
  local ids, log, virtual = data[1], data[2], data[3]
  assert(type(virtual) == "boolean", "SetCardFootnote virtual flag is required")
  local refs
  if virtual then
    denseCount(ids, "SetCardFootnote virtual IDs")
    refs = {}
    for i, id in ipairs(ids) do
      cardId(id)
      refs[i] = id
    end
  else
    refs = projectPhysicalCardIds(room, seat, physical, ids, batch, audience,
      "SetCardFootnote IDs")
  end
  return metadataEnvelope({ refs, projectMetadataLog(log), virtual })
end

local function projectCardVirtName(room, seat, physical, data, batch, audience)
  assert(denseCount(data, "SetCardVirtName") == 3,
    "SetCardVirtName expects [ids,name,virtual]")
  local ids, name, virtual = data[1], data[2], data[3]
  assert(type(name) == "string" and name ~= "",
    "SetCardVirtName name is required")
  assert(type(virtual) == "boolean", "SetCardVirtName virtual flag is required")
  local refs
  if virtual then
    denseCount(ids, "SetCardVirtName virtual IDs")
    refs = {}
    for i, id in ipairs(ids) do
      cardId(id)
      refs[i] = id
    end
  else
    refs = projectPhysicalCardIds(room, seat, physical, ids, batch, audience,
      "SetCardVirtName IDs")
  end
  return metadataEnvelope({ refs, name, virtual })
end

local function projectFilterCard(room, seat, physical, data, batch, audience)
  assert(type(data) == "table", "FilterCard payload must be a table")
  for key in pairs(data) do
    assert(key == 1 or key == 2 or key == 3,
      "FilterCard contains an unaudited field")
  end
  assert(data[1] ~= nil, "FilterCard card ID is required")
  cardId(data[1])
  local playerId = metadataPlayerId(room, data[2], "FilterCard")
  if data[3] ~= nil then
    assert(type(data[3]) == "boolean", "FilterCard judge flag must be boolean")
  end

  local ref
  if room:getCardArea(data[1]) == Card.DrawPile then
    -- Filtering happens before a draw MoveCards event establishes an
    -- audience-local alias.  A no-op sentinel preserves privacy and lets the
    -- subsequent client move apply filtering once the card is addressable.
    ref = -1
  else
    ref = projectPhysicalCardIds(room, seat, physical, {data[1]}, batch,
      audience, "FilterCard")[1]
  end
  local result = { ref }
  if playerId ~= nil then result[2] = playerId end
  if data[3] ~= nil then result[3] = data[3] end
  return metadataEnvelope(result)
end

local function projectPlayerHandCards(room, seat, physical, data, batch, audience)
  assert(denseCount(data, "SetPlayerHandCards") == 2,
    "SetPlayerHandCards expects [player,ids]")
  local ownerId = integerValue(data[1], "SetPlayerHandCards player ID")
  assert(room:getPlayerById(ownerId), "SetPlayerHandCards player is missing")
  local refs = projectPhysicalCardIds(room, seat, physical, data[2], batch,
    audience, "SetPlayerHandCards IDs")
  return metadataEnvelope({ ownerId, refs })
end

local function projectAddVirtualEquip(room, seat, physical, data, batch, audience)
  fields(data, { player = true, name = true, subcards = true },
    "AddVirtualEquip")
  local playerId = integerValue(data.player, "AddVirtualEquip player ID")
  assert(room:getPlayerById(playerId), "AddVirtualEquip player is missing")
  assert(type(data.name) == "string" and data.name ~= "",
    "AddVirtualEquip name is required")
  local refs = projectPhysicalCardIds(room, seat, physical, data.subcards, batch,
    audience, "AddVirtualEquip subcards")
  return metadataEnvelope({ player = playerId, name = data.name, subcards = refs })
end

local function projectRemoveVirtualEquip(room, seat, physical, data, batch, audience)
  fields(data, { player = true, id = true }, "RemoveVirtualEquip")
  local playerId = integerValue(data.player, "RemoveVirtualEquip player ID")
  assert(room:getPlayerById(playerId), "RemoveVirtualEquip player is missing")
  cardId(data.id)
  local ref = projectPhysicalCardIds(room, seat, physical, {data.id}, batch,
    audience, "RemoveVirtualEquip")[1]
  return metadataEnvelope({ player = playerId, id = ref })
end

local function projectShowVirtualCard(room, seat, physical, data, batch, audience)
  assert(type(data) == "table", "ShowVirtualCard payload must be a table")
  for key in pairs(data) do
    assert(key == 1 or key == 2 or key == 3 or key == 4,
      "ShowVirtualCard contains an unsupported field")
  end
  assert(data[1] ~= nil, "ShowVirtualCard cards are required")
  local cards = data[1]
  if isCardObject(cards) then cards = { cards } end
  local descriptors = {}
  local count = denseCount(cards, "ShowVirtualCard cards")
  for i = 1, count do
    descriptors[i] = projectCardWireCard(cards[i], batch, audience,
      "ShowVirtualCard card")
  end
  if data[2] ~= nil then integerValue(data[2], "ShowVirtualCard player") end
  if data[4] ~= nil then integerValue(data[4], "ShowVirtualCard event ID") end
  local footnote
  if data[3] ~= nil then
    footnote = projectGameLog(room, seat, physical, data[3], batch, audience)
  end
  return { descriptors, data[2], footnote, data[4] or 0 }
end

local summaryKeys = {
  turn = true, recover = true, recoverBy = true, damage = true,
  damaged = true, kill = true, killList = true, draw = true,
  control = true, scname = true, win = true,
}

local function projectPlayerIdList(room, value, label)
  local count = denseCount(value, label)
  local result = {}
  for i = 1, count do
    local id = integerValue(value[i], label .. " player ID")
    assert(room:getPlayerById(id), label .. " player is missing")
    result[i] = id
  end
  return result
end

local function projectInitialGeneralBanner(room, value)
  local count = denseCount(value, "InitialGeneral")
  local result = {}
  for i = 1, count do
    local record = value[i]
    assert(type(record) == "table" and denseCount(record, "InitialGeneral record") == 3,
      "InitialGeneral record expects [player,main,deputy]")
    local id = integerValue(record[1], "InitialGeneral player ID")
    assert(room:getPlayerById(id), "InitialGeneral player is missing")
    assert(type(record[2]) == "string" and type(record[3]) == "string",
      "InitialGeneral names must be strings")
    result[i] = { id, record[2], record[3] }
  end
  return result
end

local function projectGameSummaryBanner(room, value)
  local count = denseCount(value, "GameSummary")
  local result = {}
  for i = 1, count do
    local record = value[i]
    fields(record, summaryKeys, "GameSummary record")
    local projected = {}
    for _, key in ipairs({
      "turn", "recover", "recoverBy", "damage", "damaged", "kill", "draw", "control",
    }) do
      projected[key] = integerValue(record[key], "GameSummary " .. key)
    end
    projected.killList = projectPlayerIdList(room, record.killList, "GameSummary killList")
    assert(type(record.scname) == "string" and type(record.win) == "string",
      "GameSummary labels must be strings")
    projected.scname = record.scname
    projected.win = record.win
    result[i] = projected
  end
  return result
end

local function projectBanner(room, data)
  local count = denseCount(data, "SetBanner")
  assert(count == 1 or count == 2, "SetBanner expects [name,value]")
  local name, value = data[1], data[2]
  assert(type(name) == "string" and name ~= "", "SetBanner name is required")
  if value == nil then return { name } end
  if name == "InitialGeneral" then
    value = projectInitialGeneralBanner(room, value)
  elseif name == "GameSummary" then
    value = projectGameSummaryBanner(room, value)
  elseif name == "all_kingdoms" or name == "new_battle_royal_event_used" or
      name == "@[:]battle_royal_used_event" then
    value = stringArray(value, "SetBanner " .. name)
  else
    -- A scalar banner is metadata-only. Any unrecognized table (including
    -- card-manager banners holding canonical IDs) remains fail-closed.
    scalar(value, "SetBanner value")
  end
  return { name, value }
end

local function projectCardUseHistory(room, data)
  local count = denseCount(data, "SetCardUseHistory")
  assert(count >= 2 and count <= 4,
    "SetCardUseHistory expects [player,card,num,scope]")
  local id = integerValue(data[1], "SetCardUseHistory player ID")
  assert(room:getPlayerById(id), "SetCardUseHistory player is missing")
  assert(type(data[2]) == "string", "SetCardUseHistory card name must be a string")
  if data[3] ~= nil then integerValue(data[3], "SetCardUseHistory count") end
  if data[4] ~= nil then integerValue(data[4], "SetCardUseHistory scope") end
  return { id, data[2], data[3], data[4] }
end

local function historyPlayer(room, value, label)
  local id = integerValue(value, label .. " player ID")
  assert(room:getPlayerById(id), label .. " player is missing")
  return id
end

local function historyName(value, label, allowNil)
  if value == nil and allowNil then return nil end
  assert(type(value) == "string", label .. " name must be a string")
  return value
end

local function optionalHistoryCount(value, label)
  if value == nil then return nil end
  return integerValue(value, label)
end

local function projectAddCardUseHistory(room, data)
  local count = denseCount(data, "AddCardUseHistory")
  assert(count >= 2 and count <= 3,
    "AddCardUseHistory expects [player,card,num]")
  return {
    historyPlayer(room, data[1], "AddCardUseHistory"),
    historyName(data[2], "AddCardUseHistory card", false),
    optionalHistoryCount(data[3], "AddCardUseHistory count"),
  }
end

local function projectAddSkillUseHistory(room, data)
  local count = denseCount(data, "AddSkillUseHistory")
  assert(count >= 2 and count <= 3,
    "AddSkillUseHistory expects [player,skill,num]")
  return {
    historyPlayer(room, data[1], "AddSkillUseHistory"),
    historyName(data[2], "AddSkillUseHistory skill", false),
    optionalHistoryCount(data[3], "AddSkillUseHistory count"),
  }
end

local function projectAddSkillBranchUseHistory(room, data)
  local count = denseCount(data, "AddSkillBranchUseHistory")
  assert(count >= 3 and count <= 4,
    "AddSkillBranchUseHistory expects [player,skill,branch,num]")
  return {
    historyPlayer(room, data[1], "AddSkillBranchUseHistory"),
    historyName(data[2], "AddSkillBranchUseHistory skill", false),
    historyName(data[3], "AddSkillBranchUseHistory branch", false),
    optionalHistoryCount(data[4], "AddSkillBranchUseHistory count"),
  }
end

local function projectSkillUseHistory(room, data)
  local count = denseCount(data, "SetSkillUseHistory")
  assert(count >= 1 and count <= 4,
    "SetSkillUseHistory expects [player,skill,num,scope]")
  return {
    historyPlayer(room, data[1], "SetSkillUseHistory"),
    historyName(data[2], "SetSkillUseHistory skill", true),
    optionalHistoryCount(data[3], "SetSkillUseHistory count"),
    optionalHistoryCount(data[4], "SetSkillUseHistory scope"),
  }
end

local function projectSkillBranchUseHistory(room, data)
  local count = denseCount(data, "SetSkillBranchUseHistory")
  assert(count >= 1 and count <= 5,
    "SetSkillBranchUseHistory expects [player,skill,branch,num,scope]")
  return {
    historyPlayer(room, data[1], "SetSkillBranchUseHistory"),
    historyName(data[2], "SetSkillBranchUseHistory skill", true),
    historyName(data[3], "SetSkillBranchUseHistory branch", true),
    optionalHistoryCount(data[4], "SetSkillBranchUseHistory count"),
    optionalHistoryCount(data[5], "SetSkillBranchUseHistory scope"),
  }
end

local function projectCurrent(room, data)
  local count = denseCount(data, "SetCurrent")
  assert(count == 0 or count == 1, "SetCurrent expects [player]")
  local id = data[1]
  if id ~= nil then
    id = integerValue(id, "SetCurrent player ID")
    assert(room:getPlayerById(id), "SetCurrent player is missing")
  end
  return { id }
end

local function projectSkillNotification(room, data, command)
  local count = denseCount(data, command)
  assert(count == 2 or count == 3, command .. " expects [player,skill,fake]")
  local id = historyPlayer(room, data[1], command)
  assert(type(data[2]) == "string" and data[2] ~= "",
    command .. " skill name must be a string")
  if data[3] ~= nil then
    assert(type(data[3]) == "boolean", command .. " fake must be boolean")
  end
  return { id, data[2], data[3] }
end

local function projectMoveFocus(room, data)
  local count = denseCount(data, "MoveFocus")
  assert(count == 2 or count == 3, "MoveFocus expects [players,command,timeout]")
  local playerCount = denseCount(data[1], "MoveFocus players")
  local players = {}
  for i = 1, playerCount do
    players[i] = historyPlayer(room, data[1][i], "MoveFocus")
  end
  assert(type(data[2]) == "string", "MoveFocus command must be a string")
  local timeout = optionalHistoryCount(data[3], "MoveFocus timeout")
  return { players, data[2], timeout }
end

local function projectStatusSkill(data)
  assert(denseCount(data, "AddStatusSkill") == 1,
    "AddStatusSkill expects [skill]")
  assert(type(data[1]) == "string" and data[1] ~= "",
    "AddStatusSkill name must be a string")
  return { data[1] }
end

local function projectObserverRecord(data, command)
  assert(denseCount(data, command) == 5,
    command .. " expects [id,name,avatar,ready,gameTime]")
  local id = integerValue(data[1], command .. " observer ID")
  assert(type(data[2]) == "string", command .. " name must be a string")
  assert(type(data[3]) == "string", command .. " avatar must be a string")
  assert(type(data[4]) == "boolean", command .. " ready must be boolean")
  integerValue(data[5], command .. " game time")
  return { id, data[2], data[3], data[4], data[5] }
end

local function projectPlayerPair(room, data, command)
  assert(denseCount(data, command) == 2,
    command .. " expects [from,to]")
  local from = historyPlayer(room, data[1], command)
  local to = historyPlayer(room, data[2], command)
  return { from, to }
end

local function projectChat(data)
  fields(data, { type = true, sender = true, msg = true }, "Chat")
  local kind = integerValue(data.type, "Chat type")
  local sender = integerValue(data.sender, "Chat sender")
  assert(type(data.msg) == "string" and data.msg ~= "", "Chat message is required")
  return { type = kind, sender = sender, msg = data.msg }
end

local function projectChangeSkin(room, data)
  assert(denseCount(data, "ChangeSkin") == 4,
    "ChangeSkin expects [player,command,main,deputy]")
  local player = historyPlayer(room, data[1], "ChangeSkin")
  assert(data[2] == "changeskin", "ChangeSkin command token is invalid")
  assert(type(data[3]) == "string" and type(data[4]) == "string",
    "ChangeSkin skin names must be strings")
  return { player, data[2], data[3], data[4] }
end

local function projectPrintCard(data)
  assert(type(data) == "table", "PrintCard payload must be a table")
  for key in pairs(data) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= 3,
      "PrintCard contains an unsupported field")
  end
  assert(data[1] ~= nil, "PrintCard expects [name,suit,number]")
  assert(type(data[1]) == "string" and data[1] ~= "",
    "PrintCard name must be a string")
  if data[2] ~= nil then integerValue(data[2], "PrintCard suit") end
  if data[3] ~= nil then integerValue(data[3], "PrintCard number") end
  return { data[1], data[2], data[3] }
end

local function projectQuestSkill(room, data)
  assert(denseCount(data, "UpdateQuestSkillUI") == 2,
    "UpdateQuestSkillUI expects [player,skill]")
  local player = historyPlayer(room, data[1], "UpdateQuestSkillUI")
  assert(type(data[2]) == "string" and data[2] ~= "",
    "UpdateQuestSkillUI skill name must be a string")
  return { player, data[2] }
end

local function projectChangeSelf(data)
  return integerValue(data, "ChangeSelf player ID")
end

local function projectRoomOwner(data)
  assert(denseCount(data, "RoomOwner") == 1, "RoomOwner expects [player]")
  return { integerValue(data[1], "RoomOwner player ID") }
end

local function projectCloseSurrender(data)
  assert(denseCount(data, "CloseSurrenderNegotiation") == 1,
    "CloseSurrenderNegotiation expects [id]")
  assert(type(data[1]) == "string" and data[1] ~= "",
    "CloseSurrenderNegotiation ID must be a string")
  return { data[1] }
end

local function projectAskSurrender(room, data)
  assert(denseCount(data, "AskForSurrenderNegotiation") == 3,
    "AskForSurrenderNegotiation expects [id,player,name]")
  assert(type(data[1]) == "string" and data[1] ~= "",
    "AskForSurrenderNegotiation ID must be a string")
  local player = historyPlayer(room, data[2], "AskForSurrenderNegotiation")
  assert(type(data[3]) == "string", "AskForSurrenderNegotiation name must be a string")
  return { data[1], player, data[3] }
end

local function projectPrelight(data)
  assert(denseCount(data, "PrelightSkill") == 2,
    "PrelightSkill expects [skill,enabled]")
  assert(type(data[1]) == "string" and data[1] ~= "",
    "PrelightSkill name must be a string")
  assert(type(data[2]) == "boolean", "PrelightSkill enabled must be boolean")
  return { data[1], data[2] }
end

local function publicAnimationData(data)
  if data == nil then return nil end
  assert(type(data) == "table", "SuperLightBox data must be a table")
  local allowed = {
    text = true, media = true, bgColor = true, contentAreaColor = true,
    contentAreaSize = true, pause = true, fade = true,
  }
  fields(data, allowed, "SuperLightBox data")
  local result = {}
  for key, value in pairs(data) do
    if key == "contentAreaSize" then
      if type(value) == "table" then
        result[key] = numberArray(value, "SuperLightBox contentAreaSize")
      else
        result[key] = integerValue(value, "SuperLightBox contentAreaSize")
      end
    elseif key == "pause" or key == "fade" then
      result[key] = integerValue(value, "SuperLightBox " .. key)
    else
      assert(type(value) == "string", "SuperLightBox " .. key .. " must be a string")
      result[key] = value
    end
  end
  return result
end

local function projectAnimate(room, seat, physical, data, batch, audience)
  assert(type(data) == "table", "Animate payload must be a table")
  assert(type(data.type) == "string" and data.type ~= "", "Animate type is required")
  if data.type == "Indicate" then
    fields(data, { type = true, from = true, to = true }, "Animate Indicate")
    local from = historyPlayer(room, data.from, "Animate Indicate")
    local count = denseCount(data.to, "Animate Indicate targets")
    local targets = {}
    for i = 1, count do
      local group = data.to[i]
      local groupCount = denseCount(group, "Animate Indicate target group")
      assert(groupCount >= 1, "Animate Indicate target group is empty")
      targets[i] = {}
      for j = 1, groupCount do
        targets[i][j] = historyPlayer(room, group[j], "Animate Indicate target")
      end
    end
    return { type = data.type, from = from, to = targets }
  elseif data.type == "Emotion" then
    fields(data, { type = true, player = true, emotion = true,
      is_card = true, permanent = true }, "Animate Emotion")
    local target = integerValue(data.player, "Animate Emotion target")
    assert(type(data.emotion) == "string" and data.emotion ~= "",
      "Animate Emotion name is required")
    local isCard = data.is_card == true
    if isCard then
      local area = room:getCardArea(target)
      assert(isPublicArea(area), "Animate Emotion card is not public")
      target = batch:reference(audience, target, true)
    else
      assert(room:getPlayerById(target), "Animate Emotion player is missing")
    end
    if data.permanent ~= nil then
      assert(type(data.permanent) == "boolean", "Animate Emotion permanent must be boolean")
    end
    local result = { type = data.type, player = target, emotion = data.emotion }
    if data.is_card ~= nil then result.is_card = data.is_card end
    if data.permanent ~= nil then result.permanent = data.permanent end
    return result
  elseif data.type == "HideEmotion" then
    fields(data, { type = true, player = true }, "Animate HideEmotion")
    return { type = data.type,
      player = historyPlayer(room, data.player, "Animate HideEmotion") }
  elseif data.type == "InvokeSkill" then
    fields(data, { type = true, name = true, player = true, skill_type = true },
      "Animate InvokeSkill")
    assert(type(data.name) == "string" and data.name ~= "",
      "Animate InvokeSkill name is required")
    local result = { type = data.type, name = data.name,
      player = historyPlayer(room, data.player, "Animate InvokeSkill") }
    if data.skill_type ~= nil then
      assert(type(data.skill_type) == "string", "Animate InvokeSkill type must be a string")
      result.skill_type = data.skill_type
    end
    return result
  elseif data.type == "InvokeUltSkill" then
    fields(data, { type = true, name = true, player = true, deputy = true },
      "Animate InvokeUltSkill")
    assert(type(data.name) == "string" and data.name ~= "",
      "Animate InvokeUltSkill name is required")
    assert(type(data.deputy) == "boolean", "Animate InvokeUltSkill deputy must be boolean")
    return { type = data.type, name = data.name,
      player = historyPlayer(room, data.player, "Animate InvokeUltSkill"),
      deputy = data.deputy }
  elseif data.type == "SuperLightBox" then
    fields(data, { type = true, path = true, data = true }, "Animate SuperLightBox")
    assert(data.path == nil or type(data.path) == "string",
      "Animate SuperLightBox path must be a string")
    return { type = data.type, path = data.path, data = publicAnimationData(data.data) }
  end
  error("unaudited Animate type: " .. data.type)
end

local logEventKeys = {
  type = true, to = true, damageType = true, damageNum = true,
  player = true, num = true, name = true, i = true,
  general = true, deputy = true,
}

local function projectLogEvent(room, data)
  fields(data, logEventKeys, "LogEvent")
  assert(type(data.type) == "string" and data.type ~= "", "LogEvent type is required")
  if data.type == "Damage" then
    assert(type(data.damageType) == "string", "LogEvent Damage type is required")
    return { type = data.type,
      to = historyPlayer(room, data.to, "LogEvent Damage"),
      damageType = data.damageType,
      damageNum = integerValue(data.damageNum, "LogEvent Damage number") }
  elseif data.type == "LoseHP" then
    return { type = data.type }
  elseif data.type == "ChangeMaxHp" then
    return { type = data.type,
      player = historyPlayer(room, data.player, "LogEvent ChangeMaxHp"),
      num = integerValue(data.num, "LogEvent ChangeMaxHp number") }
  elseif data.type == "Death" then
    return { type = data.type,
      to = historyPlayer(room, data.to, "LogEvent Death") }
  elseif data.type == "PlaySound" then
    assert(type(data.name) == "string" and data.name ~= "", "LogEvent sound name is required")
    return { type = data.type, name = data.name }
  elseif data.type == "PlaySkillSound" then
    assert(type(data.name) == "string" and data.name ~= "", "LogEvent skill name is required")
    local result = { type = data.type, name = data.name,
      i = integerValue(data.i, "LogEvent skill index") }
    -- The upstream payload includes the caller's main/deputy general names.
    -- Those names can identify concealed Hegemony generals and are not needed:
    -- the client falls back to the generic skill sound when omitted.
    return result
  end
  error("unaudited LogEvent type: " .. data.type)
end

function Projection.project(room, seat, physical, command, data, batch)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "projection requires negotiated Hegemony v1")
  assert(seat and physical and type(batch) == "table" and
    type(batch.reference) == "function" and type(batch.project) == "function" and
    type(batch.rekey) == "function" and type(batch.standing) == "function" and
    type(batch.currentReference) == "function",
    "projection requires a physical seat and transactional batch")
  local audience = room:cardWireAudience(physical)
  if command == "MoveCards" then
    return projectMoves(seat, physical, data, batch, audience)
  elseif command == "SetPlayerPile" then
    return projectPile(room, seat, physical, data, batch, audience)
  elseif command == "PropertyUpdate" then
    return projectProperty(room, seat, physical, data)
  elseif command == "SetPlayerMark" then
    return projectPlayerMark(room, seat, physical, data)
  elseif command == "FillAG" then
    return projectFillAG(data, batch, audience)
  elseif command == "TakeAG" then
    return projectTakeAG(room, data, batch, audience)
  elseif command == "GameOver" then
    return projectGameOver(room, data)
  elseif command == "SetCardFootnote" then
    return projectCardFootnote(room, seat, physical, data, batch, audience)
  elseif command == "SetCardVirtName" then
    return projectCardVirtName(room, seat, physical, data, batch, audience)
  elseif command == "FilterCard" then
    return projectFilterCard(room, seat, physical, data, batch, audience)
  elseif command == "SetPlayerHandCards" then
    return projectPlayerHandCards(room, seat, physical, data, batch, audience)
  elseif command == "AddVirtualEquip" then
    return projectAddVirtualEquip(room, seat, physical, data, batch, audience)
  elseif command == "RemoveVirtualEquip" then
    return projectRemoveVirtualEquip(room, seat, physical, data, batch, audience)
  elseif command == "SetCardMark" then
    return projectCardMark(room, seat, physical, data, batch, audience)
  elseif command == "PrepareDrawPile" or command == "ShuffleDrawPile"
      or command == "SyncDrawPile" then
    local size = denseCount(data, command .. " IDs")
    for _, id in ipairs(data) do cardId(id) end
    return { count = size } -- No identity or deck order on the wire.
  elseif command == "ChangeCardArea" then
    assert(denseCount(data, "ChangeCardArea") == 3,
      "ChangeCardArea expects 3 fields")
    local cards, area, areaCards = data[1], data[2], data[3]
    local count = denseCount(cards, "ChangeCardArea cards")
    local areaCount = denseCount(areaCards, "ChangeCardArea target area")
    assert(area == Card.DrawPile or area == Card.DiscardPile or area == Card.Void,
      "ChangeCardArea area is not audited")
    for _, id in ipairs(cards) do cardId(id) end
    for _, id in ipairs(areaCards) do cardId(id) end
    if area == Card.DrawPile then
      -- A deck transition retires any identity that this audience had for
      -- the moved cards. The refs are opaque/canonical *old* references only;
      -- no new ordered draw identity is sent across the wire.
      return {
        count = count,
        area = area,
        areaCount = areaCount,
        retiredRefs = batch:rekey(audience, cards),
      }
    end
    -- Discard and void are public zones. Preserve their canonical identity
    -- while rejecting any physical ID from a concealed source as a token.
    return {
      count = count,
      area = area,
      areaCount = areaCount,
      areaRefs = batch:project(audience, areaCards, function()
        return true
      end),
    }
  elseif command == "Reconnect" or command == "Observe" then
    return projectSnapshot(room, seat, physical, command, data, batch, audience)
  elseif command == "ShowVirtualCard" then
    return { cardWireVersion = 1,
      payload = projectShowVirtualCard(room, seat, physical, data, batch, audience) }
  elseif command == "GameLog" then
    return { cardWireVersion = 1,
      payload = projectGameLog(room, seat, physical, data, batch, audience) }
  elseif command == "ShowCard" then
    return projectShowCard(data, batch, audience)
  elseif command == "SetBanner" then
    return projectBanner(room, data)
  elseif command == "SetCardUseHistory" then
    return projectCardUseHistory(room, data)
  elseif command == "AddCardUseHistory" then
    return projectAddCardUseHistory(room, data)
  elseif command == "AddSkillUseHistory" then
    return projectAddSkillUseHistory(room, data)
  elseif command == "AddSkillBranchUseHistory" then
    return projectAddSkillBranchUseHistory(room, data)
  elseif command == "SetSkillUseHistory" then
    return projectSkillUseHistory(room, data)
  elseif command == "SetSkillBranchUseHistory" then
    return projectSkillBranchUseHistory(room, data)
  elseif command == "SetCurrent" then
    return projectCurrent(room, data)
  elseif command == "AddSkill" or command == "LoseSkill" then
    return projectSkillNotification(room, data, command)
  elseif command == "MoveFocus" then
    return projectMoveFocus(room, data)
  elseif command == "AddStatusSkill" then
    return projectStatusSkill(data)
  elseif command == "ArrangeSeats" then
    return projectPlayerIdList(room, data, "ArrangeSeats")
  elseif command == "AddObserver" then
    return projectObserverRecord(data, command)
  elseif command == "RemoveObserver" then
    assert(denseCount(data, command) == 1, "RemoveObserver expects [id]")
    return { integerValue(data[1], "RemoveObserver ID") }
  elseif command == "AddNpc" then
    return projectObserverRecord(data, command)
  elseif command == "Chat" then
    return projectChat(data)
  elseif command == "ChangeSkin" then
    return projectChangeSkin(room, data)
  elseif command == "PrintCard" then
    return projectPrintCard(data)
  elseif command == "UpdateQuestSkillUI" then
    return projectQuestSkill(room, data)
  elseif command == "AddBuddy" or command == "RmBuddy" then
    return projectPlayerPair(room, data, command)
  elseif command == "Animate" then
    return projectAnimate(room, seat, physical, data, batch, audience)
  elseif command == "LogEvent" then
    return projectLogEvent(room, data)
  elseif command == "ChangeSelf" then
    return projectChangeSelf(data)
  elseif command == "RoomOwner" then
    return projectRoomOwner(data)
  elseif command == "CloseSurrenderNegotiation" then
    return projectCloseSurrender(data)
  elseif command == "AskForSurrenderNegotiation" then
    return projectAskSurrender(room, data)
  elseif command == "PrelightSkill" then
    return projectPrelight(data)
  elseif command == "ShowToast" or command == "StartGame" or
      command == "CancelRequest" or command == "DisableAG" or
      command == "CloseAG" or command == "ServerMessage" then
    return scalar(data, command .. " payload")
  end
  error("unaudited card-wire v1 notification: " .. tostring(command))
end

return Projection
