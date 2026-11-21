-- Candidate-only decoder for projected Reconnect/Observe snapshots.
-- The server sends count-only draw state and opaque refs for concealed cards;
-- this module converts them to the local numeric identity expected by the
-- existing Client/CardManager deserializers before any legacy mutation.
local Snapshots = {}

local MIN_LOCAL, MAX_LOCAL = 1000000000, 1999999999
local MAX_ENTRIES = 8192

local function integer(value, label)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    label .. " must be an integer")
  return value
end

local function denseCount(value, label)
  assert(type(value) == "table", label .. " must be an array")
  local count, maximum = 0, 0
  for index in pairs(value) do
    integer(index, label .. " index")
    assert(index >= 1, label .. " index must be positive")
    count = count + 1
    if index > maximum then maximum = index end
  end
  assert(count == maximum and count <= MAX_ENTRIES,
    label .. " must be dense and bounded")
  return count
end

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

local function canonical(value, label)
  integer(value, label)
  assert((value >= 1 or value <= -2) and
    (value < MIN_LOCAL or value > MAX_LOCAL),
    label .. " cannot be a local alias or sentinel")
end

local function token(value, label)
  assert(type(value) == "string" and #value >= 18 and #value <= 128 and
    value:sub(1, 2) == "h:" and value:sub(3):match("^[%w_-]+$") ~= nil,
    label .. " must be an opaque card reference")
end

local function wireRef(value, label)
  if type(value) == "string" then token(value, label)
  else canonical(value, label) end
end

local function fields(record, allow, label)
  assert(type(record) == "table", label .. " must be a table")
  for key in pairs(record) do
    assert(allow[key] == true, label .. " contains an unaudited field")
  end
end

local function validateList(value, label, allowCount)
  if type(value) == "table" and value.count ~= nil then
    assert(allowCount == true, label .. " must carry explicit references")
    fields(value, { count = true }, label)
    integer(value.count, label .. " count")
    assert(value.count >= 0 and value.count <= MAX_ENTRIES,
      label .. " count is out of range")
    return
  end
  local count = denseCount(value, label)
  for i = 1, count do wireRef(value[i], label .. " reference") end
end

local function validateMarks(encoded)
  if encoded == nil then return end
  assert(type(encoded) == "string", "snapshot card marks must be CBOR")
  local marks = cbor.decode(encoded)
  assert(type(marks) == "table", "snapshot card marks must decode to a table")
  for id, value in pairs(marks) do
    wireRef(id, "snapshot card mark key")
    assert(type(value) ~= "function" and type(value) ~= "userdata",
      "snapshot card mark value is not serializable")
  end
end

local function validateSnapshot(payload)
  assert(type(payload) == "table" and type(payload.card_manager) == "table" and
    type(payload.players) == "table", "snapshot payload shape is invalid")
  local manager = payload.card_manager
  fields(manager, {
    draw_pile = true, discard_pile = true, processing_area = true,
    void = true, printed_cards = true, card_marks = true,
  }, "snapshot card manager")
  validateList(manager.draw_pile, "snapshot draw pile", true)
  for _, name in ipairs({ "discard_pile", "processing_area", "void" }) do
    validateList(manager[name], "snapshot " .. name)
  end
  validateMarks(manager.card_marks)
  for id, record in pairs(payload.players) do
    integer(id, "snapshot player map key")
    assert(type(record) == "table" and type(record.player_cards) == "table" and
      type(record.special_cards) == "table", "snapshot player record is invalid")
    for area, ids in pairs(record.player_cards) do
      integer(area, "snapshot player card area")
      assert(area == Card.PlayerHand or area == Card.PlayerEquip or
        area == Card.PlayerJudge, "snapshot player card area is not audited")
      validateList(ids, "snapshot player cards", false)
    end
    for pile, ids in pairs(record.special_cards) do
      assert(type(pile) == "string" and pile ~= "",
        "snapshot special pile name is required")
      validateList(ids, "snapshot special cards", false)
    end
    if record.virtual_equips ~= nil then
      assert(type(record.virtual_equips) == "table" and
        #record.virtual_equips == 0,
        "snapshot virtual equipment is not audited")
    end
  end
end

local function localizeList(room, value, label, allowCount)
  if type(value) == "table" and value.count ~= nil then
    assert(allowCount == true, label .. " must carry explicit references")
    local previous = room.draw_pile
    return room.card_wire_refs:replaceAnonymousDeck(value.count, previous)
  end
  local count = denseCount(value, label)
  local result = {}
  for i = 1, count do
    result[i] = room.card_wire_refs:toLocal(value[i])
  end
  return result
end

local function localizeMarks(room, encoded)
  if encoded == nil then return nil end
  local marks = cbor.decode(encoded)
  local result = {}
  for reference, value in pairs(marks) do
    result[room.card_wire_refs:toLocal(reference)] = copy(value)
  end
  return cbor.encode(result)
end

function Snapshots.receive(room, envelope)
  assert(room.card_wire_version == 1,
    "projected snapshot requires negotiated Hegemony v1")
  assert(type(envelope) == "table" and envelope.cardWireVersion == 1 and
    type(envelope.payload) == "table", "invalid card-wire snapshot envelope")
  -- Cold observers/reconnects are still lobby clients. Their old settings
  -- cannot identify the incoming room; validate the snapshot's mode instead.
  assert(type(envelope.payload.settings) == "table" and
    envelope.payload.settings.gameMode == "new_heg_mode",
    "projected snapshot requires Hegemony settings")
  validateSnapshot(envelope.payload)
  local refs = room.card_wire_refs or require("ltk.client.card_wire_refs").new()

  -- Stage the new physical session until every reference has localized.
  local staged = { card_wire_refs = refs:fork() }
  staged.card_wire_refs:resetSession()
  local result = copy(envelope.payload)
  local manager = result.card_manager
  manager.draw_pile = localizeList(staged, manager.draw_pile, "snapshot draw pile", true)
  for _, name in ipairs({ "discard_pile", "processing_area", "void" }) do
    manager[name] = localizeList(staged, manager[name], "snapshot " .. name, false)
  end
  manager.card_marks = localizeMarks(staged, manager.card_marks)

  for _, record in pairs(result.players) do
    for area, ids in pairs(record.player_cards) do
      record.player_cards[area] = localizeList(staged, ids, "snapshot player cards", false)
    end
    for pile, ids in pairs(record.special_cards) do
      record.special_cards[pile] = localizeList(staged, ids, "snapshot special cards", false)
    end
  end
  refs:commitDraft(staged.card_wire_refs)
  room.card_wire_refs = refs
  room.card_wire_request = nil
  return result
end

-- The legacy summary callback rebuilds ClientInstance via enterRoom. Carry
-- only the validated snapshot state through that one reconstruction, and
-- clear the temporary capability on both success and exception paths.
function Snapshots.dispatch(room, callback, data)
  assert(room.card_wire_version == 1 and room.card_wire_refs)
  assert(room._card_wire_snapshot == nil, "snapshot dispatch cannot be nested")
  room._card_wire_snapshot = {
    refs = room.card_wire_refs,
    protocol = "TQS_HEG_CARD_WIRE",
  }
  local ok, result = pcall(callback, room, data)
  room._card_wire_snapshot = nil
  if not ok then error(result, 0) end
  return result
end

return Snapshots
