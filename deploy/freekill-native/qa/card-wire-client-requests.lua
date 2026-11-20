-- Candidate-only client side of the Hegemony v1 request bridge.
-- The server envelope contains one-shot choice tokens and the corresponding
-- standing per-physical reference.  UI sees only the standing local alias;
-- the reply path turns that alias back into the one-shot token.
local Requests = {}
local Visibility = require "ltk.core.card_wire_request_visibility"

local function dense(value, label)
  assert(type(value) == "table", label .. " must be a table")
  local count, maximum = 0, 0
  for key in pairs(value) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1,
      label .. " must be a dense array")
    count = count + 1
    if key > maximum then maximum = key end
  end
  assert(count == maximum, label .. " must be a dense array")
  return count
end

local function copy(value, seen)
  if type(value) ~= "table" then return value end
  -- Do not turn ClientPlayer objects into plain tables.  Their metatables and
  -- methods are part of the normal upstream request callback contract.
  if value.id ~= nil and (value.player ~= nil or value.class ~= nil) then
    return value
  end
  seen = seen or {}
  assert(not seen[value], "cyclic card-wire request payload")
  seen[value] = true
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item, seen) end
  seen[value] = nil
  return result
end

local function isToken(value)
  return type(value) == "string" and value:sub(1, 2) == "h:" and
    value:sub(3):match("^[%w_-]+$") ~= nil
end

local function mapToken(maps, value, label)
  if not isToken(value) then return value end
  local localId = maps.byToken[value]
  assert(localId, label .. " contains an unknown request token")
  return localId
end

-- Exppattern carries explicit card identities in its seventh matcher field.
-- Restore the UI's standing local aliases while keeping all other matcher
-- restrictions byte-for-byte, including negative ID groups.
local function localizePattern(pattern, maps)
  assert(type(pattern) == "string", "request pattern must be a string")
  local matchers = {}
  for matcher in (pattern .. ";"):gmatch("(.-);") do
    local parts = {}
    for part in (matcher .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
    assert(#parts <= 7, "request pattern has unaudited matcher fields")
    if #parts == 7 and parts[7] ~= "." and parts[7] ~= "" then
      local mapped, groupDepth = {}, 0
      for rawPart in (parts[7] .. ","):gmatch("(.-),") do
        local part = rawPart
        local prefix, suffix = "", ""
        if part:sub(1, 2) == "^(" then
          prefix, part = "^(", part:sub(3)
          groupDepth = groupDepth + 1
        elseif part:sub(1, 1) == "^" then
          prefix, part = "^", part:sub(2)
        end
        if part:sub(-1) == ")" then
          suffix, part = ")", part:sub(1, -2)
          groupDepth = groupDepth - 1
        end
        assert(groupDepth >= 0 and isToken(part),
          "request pattern contains a non-opaque card reference")
        local id = mapToken(maps, part, "request pattern")
        assert(type(id) == "number", "request pattern card alias is invalid")
        mapped[#mapped + 1] = prefix .. tostring(id) .. suffix
      end
      assert(groupDepth == 0, "request pattern has an unterminated ID group")
      parts[7] = table.concat(mapped, ",")
    end
    matchers[#matchers + 1] = table.concat(parts, "|")
  end
  return table.concat(matchers, ";")
end

local function mapVisible(maps, value, label)
  if value == nil then return nil end
  assert(type(value) == "table", label .. " must be a map")
  local result = {}
  for key, visible in pairs(value) do
    assert(type(key) == "string" and type(visible) == "boolean",
      label .. " has an invalid entry")
    local localId = mapToken(maps, key, label .. " key")
    assert(type(localId) == "number", label .. " key is not a card")
    result[tostring(localId)] = visible
  end
  return result
end

local function mapCardArray(maps, values, label)
  local count = dense(values, label)
  local result = {}
  for i = 1, count do result[i] = mapToken(maps, values[i], label .. " reference") end
  return result
end

local function mapGroups(maps, groups, label)
  local count = dense(groups, label)
  local result = {}
  for i = 1, count do
    local group = groups[i]
    assert(type(group) == "table" and #group == 2 and type(group[1]) == "string",
      label .. " group is invalid")
    result[i] = { group[1], mapCardArray(maps, group[2], label .. " group") }
  end
  return result
end

local cardArrayKeys = {
  cards = true,
  card_ids = true,
  cardIds = true,
  subcards = true,
  visible_pile = true,
  expand_pile = true,
}

local cardScalarKeys = {
  card = true,
  cardId = true,
  card_id = true,
  effectCardId = true,
}

local function mapExtra(value, key, maps, seen)
  if value == nil or type(value) == "number" or type(value) == "boolean" then
    return value
  end
  if type(value) == "string" then
    if key == "pattern" then return localizePattern(value, maps) end
    return mapToken(maps, value, key)
  end
  if type(value) ~= "table" then return value end
  if key == "visible_data" then return mapVisible(maps, value, key) end
  if cardScalarKeys[key] then return mapToken(maps, value, key) end
  if cardArrayKeys[key] then
    if type(value) == "table" then
      local result = {}
      for i, item in ipairs(value) do result[i] = mapToken(maps, item, key) end
      return result
    end
    return value
  end
  seen = seen or {}
  assert(not seen[value], "cyclic card-wire request payload")
  seen[value] = true
  local result = {}
  for childKey, child in pairs(value) do
    local childName = type(childKey) == "string" and childKey or key
    result[childKey] = mapExtra(child, childName, maps, seen)
  end
  seen[value] = nil
  return result
end

local function localizePayload(command, payload, maps)
  if command == "AskForCardChosen" then
    local result = copy(payload)
    if type(result[2]) == "table" then
      result[2].card_data = mapGroups(maps, result[2].card_data, command)
      result[2].visible_data = mapVisible(maps, result[2].visible_data, command)
    end
    return result
  elseif command == "AskForAG" then
    local result = copy(payload)
    result[1] = mapCardArray(maps, result[1], command)
    return result
  elseif command == "AskForPoxi" then
    local result = copy(payload)
    result.data = mapGroups(maps, result.data, command)
    result.extra_data = mapExtra(result.extra_data, "extra_data", maps)
    return result
  elseif command == "AskForCardsAndChoice" then
    local result = copy(payload)
    result.cards = mapCardArray(maps, result.cards, command)
    if result.disabled then result.disabled = mapCardArray(maps, result.disabled, command) end
    result.extra_data = mapExtra(result.extra_data, "extra_data", maps)
    return result
  elseif command == "AskForArrangeCards" then
    local result = copy(payload)
    local rows = dense(result.cards, command .. " rows")
    for i = 1, rows do result.cards[i] = mapCardArray(maps, result.cards[i], command) end
    if result.pattern then result.pattern = localizePattern(result.pattern, maps) end
    return result
  elseif command == "AskForMoveCardInBoard" then
    local result = copy(payload)
    result.cards = mapCardArray(maps, result.cards, command)
    return result
  elseif command == "PlayCard" or command == "AskForUseActiveSkill" or command == "AskForUseCard" or
      command == "AskForResponseCard" then
    local result = copy(payload)
    local index = command == "AskForUseActiveSkill" and 4 or 5
    result[index] = mapExtra(result[index], "extra_data", maps)
    if index == 5 and result[2] ~= nil then result[2] = localizePattern(result[2], maps) end
    return result
  end
  return copy(payload)
end

local function mapReplyRef(room, context, value, label)
  assert(type(value) == "number" and value % 1 == 0, label .. " must be a local card ID")
  if value == -1 then return value end
  local token = context.byLocal[value]
  assert(token, label .. " is not an offered request card")
  assert(not room.card_wire_refs:isAnonymous(value), label .. " is an anonymous deck slot")
  return token
end

local function mapReplyList(room, context, values, label, allowMinusOne)
  local count = dense(values, label)
  local result = {}
  for i = 1, count do
    if allowMinusOne and values[i] == -1 then
      result[i] = -1
    else
      result[i] = mapReplyRef(room, context, values[i], label .. " reference")
    end
  end
  return result
end

local function mapUseReply(room, context, reply)
  assert(type(reply) == "table", "card-use reply must be a table")
  local result = copy(reply)
  if result.card ~= nil then
    if type(result.card) == "number" then
      result.card = mapReplyRef(room, context, result.card, "card-use reply")
    elseif type(result.card) == "table" then
      assert(result.card.id == nil and result.card.card_objs == nil,
        "card-use reply contains unaudited card metadata")
      if result.card.subcards then
        result.card.subcards = mapReplyList(room, context, result.card.subcards,
          "card-use subcards", false)
      end
    else
      error("card-use reply card is malformed")
    end
  end
  assert(result.card_objs == nil, "card-use reply card objects are not audited")
  return result
end

function Requests.receive(room, command, envelope)
  assert(type(envelope) == "table" and envelope.cardWireVersion == 1 and
    type(envelope.payload) == "table", "invalid card-wire request envelope")
  local refs = room.card_wire_refs
  assert(refs and type(refs.toLocal) == "function", "client card-wire aliases are missing")
  local entries = envelope.choices or {}
  local count = dense(entries, "request choices")
  local maps = { byToken = {}, byLocal = {} }
  local faces = {}
  local offered = Visibility.offered(command, envelope.payload)
  for i = 1, count do
    local entry = entries[i]
    assert(type(entry) == "table" and type(entry.token) == "string" and
      (type(entry.standing) == "number" or type(entry.standing) == "string"),
      "invalid card-wire request choice")
    assert(isToken(entry.token), "request choice token is not opaque")
    local localId = refs:toLocal(entry.standing)
    assert(not maps.byToken[entry.token] and not maps.byLocal[localId],
      "duplicate card-wire request choice")
    maps.byToken[entry.token] = localId
    maps.byLocal[localId] = entry.token
    local face = entry.face
    if face ~= nil then
      assert(offered[entry.token] and type(entry.standing) == "string" and type(face) == "table" and
        type(face.name) == "string" and #face.name > 0 and #face.name <= 120 and
        type(face.suit) == "number" and face.suit % 1 == 0 and face.suit >= 0 and face.suit <= 5 and
        type(face.number) == "number" and face.number % 1 == 0 and face.number >= 0 and face.number <= 13,
        "invalid request-visible card face")
      faces[localId] = { name = face.name, suit = face.suit, number = face.number }
    end
  end
  local payload = localizePayload(command, envelope.payload, maps)
  room.card_wire_request = {
    command = command,
    byToken = maps.byToken,
    byLocal = maps.byLocal,
    faces = faces,
  }
  return payload
end

-- A newly drawn, request-visible card may have a local alias without a
-- physical Card entry in Fk.cards.  For the built-in card/target chooser,
-- allow this alias only when the current one-shot request offers it and the
-- localized pattern consists exclusively of positive card IDs.  Other
-- matchers need real Card metadata and must keep using upstream validation.
function Requests.matchesOfferedIdOnlyPattern(room, skill, localId)
  local request = room and room.card_wire_request
  if not (room and room.card_wire_version == 1 and request and
      request.command == "AskForUseActiveSkill" and
      type(localId) == "number" and localId % 1 == 0 and
      request.byLocal and request.byLocal[localId] and
      room.card_wire_refs and not room.card_wire_refs:isAnonymous(localId) and
      skill and not skill.will_throw and type(skill.pattern) == "string") then
    return false
  end

  local ids = skill.pattern:match("^%.|%.|%.|%.|%.|%.|([%d,]+)$")
  if not ids or ids:sub(1, 1) == "," or ids:sub(-1) == "," or
      ids:find(",,", 1, true) then
    return false
  end
  for rawId in ids:gmatch("%d+") do
    if tonumber(rawId) == localId then return true end
  end
  return false
end

-- `consume` defaults to true for the real transport path.  The browser bridge
-- validates the exact CBOR bytes before sending, so it needs a non-consuming
-- preview of the same translated value; otherwise preview would consume the
-- one-shot request context and the subsequent send would leak the local ID.
function Requests.encodeReply(room, value, consume)
  local context = room.card_wire_request
  if room.card_wire_version ~= 1 or not context then return value end
  local command = context.command
  local result
  if value == "__cancel" or value == "" then
    result = value
  elseif command == "AskForCardChosen" then
    result = mapReplyRef(room, context, value, command)
  elseif command == "AskForPoxi" then
    result = mapReplyList(room, context, value, command, true)
  elseif command == "AskForAG" then
    result = mapReplyRef(room, context, value, command)
  elseif command == "AskForCardsAndChoice" then
    assert(type(value) == "table", "cards-and-choice reply must be a table")
    result = copy(value)
    result.cards = mapReplyList(room, context, result.cards or {}, command, false)
    assert(type(result.choice) == "string", "cards-and-choice choice is invalid")
  elseif command == "AskForArrangeCards" then
    assert(type(value) == "table", "arrange reply must be an array")
    result = {}
    for row, values in ipairs(value) do
      result[row] = mapReplyList(room, context, values, command .. " row", false)
    end
  elseif command == "AskForMoveCardInBoard" then
    assert(type(value) == "table" and type(value.cardId) == "number",
      "move-board reply is malformed")
    result = copy(value)
    result.cardId = mapReplyRef(room, context, result.cardId, command)
  elseif command == "PlayCard" or command == "AskForUseActiveSkill" or command == "AskForUseCard" or
      command == "AskForResponseCard" then
    result = mapUseReply(room, context, value)
  else
    result = copy(value)
  end
  if consume ~= false then room.card_wire_request = nil end
  return result
end

return Requests
