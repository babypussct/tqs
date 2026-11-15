-- Candidate-only client decoder for public ShowVirtualCard and GameLog.
-- The server uses plain descriptors so the upstream Card CBOR tags never see
-- a concealed physical ID. This module reconstructs native Card objects only
-- after the explicit v1 envelope has passed strict schema validation.
local Public = {}

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

local function fields(value, allowed, label)
  assert(type(value) == "table", label .. " must be a table")
  for key in pairs(value) do
    assert(allowed[key] == true, label .. " contains an unaudited field")
  end
end

local function integer(value, label)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    label .. " must be a finite integer")
  return value
end

local function scalar(value, label)
  local kind = type(value)
  assert(kind == "boolean" or kind == "string" or
    (kind == "number" and value == value and
      value ~= math.huge and value ~= -math.huge),
    label .. " must be a finite scalar")
  return value
end

local function publicReference(room, reference, label)
  -- Public descriptors are deliberately numeric. An opaque token here would
  -- mean a server-side visibility mistake, not a normal client alias.
  integer(reference, label)
  assert(reference ~= -1, label .. " cannot be the unknown sentinel")
  assert(room.card_wire_refs and type(room.card_wire_refs.toLocal) == "function",
    "client card-wire aliases are unavailable")
  return room.card_wire_refs:toLocal(reference)
end

local function nativeCard(room, localId, label)
  assert(Fk and type(Fk.getCardById) == "function",
    "client card catalog is unavailable")
  local card = Fk:getCardById(localId, true)
  return card or -1
end

local function decodeCard(room, descriptor, label)
  fields(descriptor, { cardWireCard = true, kind = true, ref = true,
    name = true, suit = true, number = true, color = true,
    subcards = true, skillNames = true, virt_id = true, mark = true }, label)
  assert(descriptor.cardWireCard == 1, label .. " marker is invalid")
  assert(descriptor.kind == "real" or descriptor.kind == "virtual",
    label .. " kind is invalid")
  if descriptor.kind == "real" then
    fields(descriptor, { cardWireCard = true, kind = true, ref = true }, label)
    local localId = publicReference(room, descriptor.ref, label .. " ref")
    return nativeCard(room, localId, label)
  end

  fields(descriptor, { cardWireCard = true, kind = true, name = true,
    suit = true, number = true, color = true, subcards = true,
    skillNames = true, virt_id = true, mark = true }, label)
  assert(type(descriptor.name) == "string" and descriptor.name ~= "",
    label .. " name is required")
  local suit = integer(descriptor.suit, label .. " suit")
  local number = integer(descriptor.number, label .. " number")
  local color = integer(descriptor.color, label .. " color")
  local virtId = integer(descriptor.virt_id, label .. " virt_id")
  local subcards = descriptor.subcards or {}
  local subcardCount = dense(subcards, label .. " subcards")
  local localSubcards = {}
  for i = 1, subcardCount do
    localSubcards[i] = publicReference(room, subcards[i],
      label .. " subcard reference")
  end
  local skillNames = descriptor.skillNames or {}
  local skillCount = dense(skillNames, label .. " skill names")
  for i = 1, skillCount do
    assert(type(skillNames[i]) == "string", label .. " skill name is invalid")
  end
  assert(Fk and type(Fk.cloneCard) == "function", "card clone API is unavailable")
  local card = Fk:cloneCard(descriptor.name, suit, number)
  assert(card, label .. " could not be reconstructed")
  card.color = color
  card.subcards = localSubcards
  card.skillNames = skillNames
  card._skillName = skillCount > 0 and skillNames[skillCount] or ""
  card.virt_id = virtId
  local marks = descriptor.mark
  if marks ~= nil then
    assert(type(marks) == "table", label .. " marks must be a table")
    card.mark = {}
    for mark, value in pairs(marks) do
      assert(type(mark) == "string" and mark:sub(1, 1) == "@",
        label .. " mark is not UI-safe")
      card.mark[mark] = scalar(value, label .. " mark")
    end
  else
    card.mark = {}
  end
  return card
end

local function decodeCardValue(room, value, label)
  if type(value) == "table" then
    return decodeCard(room, value, label)
  end
  assert(type(value) == "number", label .. " must be a card descriptor")
  if value == -1 then return value end
  local localId = publicReference(room, value, label .. " ref")
  return nativeCard(room, localId, label)
end

local logKeys = {
  type = true, from = true, to = true, card = true, toast = true,
  arg = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true,
  arg6 = true, arg7 = true, arg8 = true, arg9 = true,
}

local function decodeGameLog(room, value)
  fields(value, logKeys, "GameLog")
  assert(type(value.type) == "string" and value.type ~= "", "GameLog type required")
  local result = { type = value.type }
  if value.from ~= nil then result.from = integer(value.from, "GameLog from") end
  if value.to ~= nil then
    local count = dense(value.to, "GameLog targets")
    result.to = {}
    for i = 1, count do result.to[i] = integer(value.to[i], "GameLog target") end
  end
  if value.card ~= nil then
    local count = dense(value.card, "GameLog cards")
    result.card = {}
    for i = 1, count do
      result.card[i] = decodeCardValue(room, value.card[i], "GameLog card")
    end
  end
  if value.toast ~= nil then
    assert(type(value.toast) == "boolean", "GameLog toast must be boolean")
    result.toast = value.toast
  end
  for _, key in ipairs({ "arg", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9" }) do
    if value[key] ~= nil then
      if type(value[key]) == "table" then
        result[key] = decodeCard(room, value[key], "GameLog " .. key)
      else
        result[key] = scalar(value[key], "GameLog " .. key)
      end
    end
  end
  return result
end

local function decodeShowVirtualCard(room, value)
  assert(type(value) == "table", "ShowVirtualCard payload must be a table")
  for key in pairs(value) do
    assert(key == 1 or key == 2 or key == 3 or key == 4,
      "ShowVirtualCard contains an unsupported field")
  end
  local cards = value[1]
  local count = dense(cards, "ShowVirtualCard cards")
  local resultCards = {}
  for i = 1, count do
    resultCards[i] = decodeCard(room, cards[i], "ShowVirtualCard card")
  end
  if value[2] ~= nil then integer(value[2], "ShowVirtualCard player") end
  assert(type(value[4]) == "number", "ShowVirtualCard event ID is required")
  integer(value[4], "ShowVirtualCard event ID")
  local footnote
  if value[3] ~= nil then footnote = decodeGameLog(room, value[3]) end
  return { resultCards, value[2], footnote, value[4] }
end

function Public.receive(room, command, envelope)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "public card-wire payload requires negotiated Hegemony v1")
  fields(envelope, { cardWireVersion = true, payload = true },
    "public card-wire envelope")
  assert(envelope.cardWireVersion == 1, "invalid public card-wire version")
  if command == "ShowVirtualCard" then
    return decodeShowVirtualCard(room, envelope.payload)
  elseif command == "GameLog" then
    return decodeGameLog(room, envelope.payload)
  end
  error("unaudited public card-wire command: " .. tostring(command))
end

return Public
