-- Candidate-only client decoder for audited card metadata/AG notifications.
-- The server envelope is explicit so a legacy numeric payload cannot be
-- mistaken for a negotiated v1 packet. Physical references become client
-- local aliases before legacy callbacks or the UI see them.
local Metadata = {}

local MIN_LOCAL, MAX_LOCAL = 1000000000, 1999999999

local function integer(value, label)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    label .. " must be a finite integer")
  return value
end

local function dense(value, label)
  assert(type(value) == "table", label .. " must be a table")
  local count, maximum = 0, 0
  for key in pairs(value) do
    integer(key, label .. " index")
    assert(key >= 1, label .. " index must be positive")
    count = count + 1
    if key > maximum then maximum = key end
  end
  assert(count == maximum, label .. " must be dense")
  return count
end

local function fields(value, allowed, label)
  assert(type(value) == "table", label .. " must be a table")
  for key in pairs(value) do
    assert(allowed[key] == true, label .. " contains an unaudited field")
  end
end

local function canonical(value, label)
  integer(value, label)
  assert((value >= 1 or value <= -2) and
    (value < MIN_LOCAL or value > MAX_LOCAL),
    label .. " cannot be a local alias or reserved ID")
  return value
end

local function opaque(value, label)
  assert(type(value) == "string" and #value >= 18 and #value <= 128 and
    value:sub(1, 2) == "h:" and value:sub(3):match("^[%w_-]+$") ~= nil,
    label .. " must be an opaque card reference")
end

local function wireReference(value, label)
  if type(value) == "string" then
    opaque(value, label)
  else
    canonical(value, label)
  end
end

local function negotiated(room, label)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    label .. " requires negotiated Hegemony v1")
  assert(room.card_wire_refs and type(room.card_wire_refs.toLocal) == "function",
    "client card-wire aliases are unavailable")
end

local function localizeIds(room, refs, virtual, label)
  local count = dense(refs, label)
  local result = {}
  for i = 1, count do
    if virtual then
      result[i] = canonical(refs[i], label .. " virtual ID")
    else
      wireReference(refs[i], label .. " reference")
      result[i] = room.card_wire_refs:toLocal(refs[i])
    end
  end
  return result
end

local logKeys = {
  type = true, from = true, to = true, toast = true,
  arg = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true,
  arg6 = true, arg7 = true, arg8 = true, arg9 = true,
}

local function localizeFootnoteLog(value)
  fields(value, logKeys, "SetCardFootnote log")
  assert(type(value.type) == "string" and value.type ~= "",
    "SetCardFootnote log type is required")
  assert(value.card == nil, "SetCardFootnote log cards are not supported")
  local result = { type = value.type }
  if value.from ~= nil then result.from = canonical(value.from, "SetCardFootnote from") end
  if value.to ~= nil then
    local count = dense(value.to, "SetCardFootnote targets")
    result.to = {}
    for i = 1, count do
      result.to[i] = canonical(value.to[i], "SetCardFootnote target")
    end
  end
  if value.toast ~= nil then
    assert(type(value.toast) == "boolean", "SetCardFootnote toast must be boolean")
    result.toast = value.toast
  end
  for _, key in ipairs({ "arg", "arg2", "arg3", "arg4", "arg5",
      "arg6", "arg7", "arg8", "arg9" }) do
    if value[key] ~= nil then
      assert(type(value[key]) == "string",
        "SetCardFootnote " .. key .. " must be a string")
      result[key] = value[key]
    end
  end
  return result
end

local function player(room, value, label)
  if value == nil then return nil end
  local id = canonical(value, label .. " player ID")
  assert(type(room.getPlayerById) == "function",
    label .. " player lookup is unavailable")
  local result = room:getPlayerById(id)
  assert(result, label .. " player is missing")
  return result
end

local function envelope(envelopeValue, label)
  fields(envelopeValue, { cardWireVersion = true, payload = true }, label)
  assert(envelopeValue.cardWireVersion == 1,
    label .. " version is invalid")
  return envelopeValue.payload
end

function Metadata.receive(room, command, envelopeValue)
  negotiated(room, command)
  local data = envelope(envelopeValue, "card-wire metadata envelope")

  if command == "SetCardFootnote" then
    assert(dense(data, "SetCardFootnote payload") == 3,
      "SetCardFootnote expects [refs,log,virtual]")
    assert(type(data[3]) == "boolean", "SetCardFootnote virtual flag is invalid")
    return { localizeIds(room, data[1], data[3], "SetCardFootnote IDs"),
      localizeFootnoteLog(data[2]), data[3] }, true
  elseif command == "SetCardVirtName" then
    assert(dense(data, "SetCardVirtName payload") == 3,
      "SetCardVirtName expects [refs,name,virtual]")
    assert(type(data[2]) == "string" and data[2] ~= "",
      "SetCardVirtName name is invalid")
    assert(type(data[3]) == "boolean", "SetCardVirtName virtual flag is invalid")
    return { localizeIds(room, data[1], data[3], "SetCardVirtName IDs"),
      data[2], data[3] }, true
  elseif command == "FilterCard" then
    assert(type(data) == "table", "FilterCard payload must be a table")
    for key in pairs(data) do
      assert(key == 1 or key == 2 or key == 3,
        "FilterCard contains an unaudited field")
    end
    assert(data[1] ~= nil, "FilterCard reference is required")
    if data[1] == -1 then
      assert(data[2] == nil or type(data[2]) == "number",
        "FilterCard player ID is invalid")
      return nil, false
    end
    wireReference(data[1], "FilterCard reference")
    local result = { room.card_wire_refs:toLocal(data[1]) }
    if data[2] ~= nil then result[2] = player(room, data[2], "FilterCard") end
    if data[3] ~= nil then
      assert(type(data[3]) == "boolean", "FilterCard judge flag is invalid")
      result[3] = data[3]
    end
    return result, true
  elseif command == "FillAG" then
    local count = dense(data, "FillAG payload")
    assert(count == 1 or count == 2,
      "FillAG expects [ids,disabledIds]")
    local result = { localizeIds(room, data[1], false, "FillAG IDs") }
    if data[2] ~= nil then
      result[2] = localizeIds(room, data[2], false, "FillAG disabled IDs")
    end
    return result, true
  elseif command == "TakeAG" then
    assert(dense(data, "TakeAG payload") == 2,
      "TakeAG expects [taker,card]")
    local taker = player(room, data[1], "TakeAG")
    wireReference(data[2], "TakeAG card reference")
    return { taker.id, room.card_wire_refs:toLocal(data[2]) }, true
  elseif command == "SetPlayerHandCards" then
    assert(dense(data, "SetPlayerHandCards payload") == 2,
      "SetPlayerHandCards expects [player,refs]")
    local owner = player(room, data[1], "SetPlayerHandCards")
    return { owner.id, localizeIds(room, data[2], false,
      "SetPlayerHandCards IDs") }, true
  elseif command == "AddVirtualEquip" then
    fields(data, { player = true, name = true, subcards = true },
      "AddVirtualEquip")
    local owner = player(room, data.player, "AddVirtualEquip")
    assert(type(data.name) == "string" and data.name ~= "",
      "AddVirtualEquip name is invalid")
    return { player = owner.id, name = data.name,
      subcards = localizeIds(room, data.subcards, false,
        "AddVirtualEquip subcards") }, true
  elseif command == "RemoveVirtualEquip" then
    fields(data, { player = true, id = true }, "RemoveVirtualEquip")
    local owner = player(room, data.player, "RemoveVirtualEquip")
    wireReference(data.id, "RemoveVirtualEquip reference")
    return { player = owner.id, id = room.card_wire_refs:toLocal(data.id) }, true
  end
  error("unaudited card-wire metadata command: " .. tostring(command))
end

return Metadata
