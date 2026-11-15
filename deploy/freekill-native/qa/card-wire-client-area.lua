-- Isolated Hegemony v1 client handling for projected ChangeCardArea packets.
-- Draw-pile transitions carry counts and retired opaque refs only. Public
-- discard/void transitions carry canonical public refs, never concealed IDs.
local Area = {}
local MAX_ZONE = 8192
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
  assert(count == maximum, name .. " must be dense")
  return count
end

local function exactFields(packet, allowed)
  for key in pairs(packet) do
    assert(allowed[key] == true, "ChangeCardArea contains an unaudited field")
  end
end

local function copy(list)
  local result = {}
  for i, value in ipairs(list) do result[i] = value end
  return result
end

local function removeOne(list, value)
  for index, current in ipairs(list) do
    if current == value then
      table.remove(list, index)
      return true
    end
  end
  return false
end

local function token(value)
  assert(type(value) == "string" and #value >= 18 and #value <= 128 and
    value:sub(1, 2) == "h:" and value:sub(3):match("^[%w_-]+$") ~= nil,
    "invalid retired opaque reference")
end

local function canonical(value)
  integer(value, "public area reference")
  assert((value >= 1 or value <= -2) and
    (value < MIN_LOCAL or value > MAX_LOCAL),
    "public area reference cannot be a local alias")
end

local function trackerFor(tracker, area)
  if area == Card.DiscardPile then return tracker.discard_pile end
  if area == Card.Void then return tracker.void end
  return nil
end

local function removeFromPublicZone(room, id, area)
  local field = area == Card.DiscardPile and "discard_pile" or "void"
  local list = room[field] or {}
  if removeOne(list, id) then
    if room.card_place[id] == area then
      room.card_place[id] = nil
      room.owner_map[id] = nil
    end
    for _, player in ipairs(room.players or {}) do
      local tracker = player.card_tracker
      local known = tracker and trackerFor(tracker, area)
      if known then
        removeOne(known.known_cards, id)
        removeOne(known.uncertain_cards, id)
      end
    end
  end
end

local function retireReference(room, reference)
  local refs = room.card_wire_refs
  local id
  if type(reference) == "number" then
    canonical(reference)
    id = reference
  else
    token(reference)
    id = refs.byToken[reference]
    if not id then return end
  end
  removeFromPublicZone(room, id, Card.DiscardPile)
  removeFromPublicZone(room, id, Card.Void)
  if refs:isHiddenLocal(id) then refs:retire(id) end
end

local function clearZone(room, area)
  local field = area == Card.DiscardPile and "discard_pile" or "void"
  local previous = room[field] or {}
  for _, id in ipairs(previous) do
    if room.card_place[id] == area then
      room.card_place[id] = nil
      room.owner_map[id] = nil
    end
    if room.card_wire_refs:isHiddenLocal(id) then
      room.card_wire_refs:retire(id)
    end
  end
  return previous
end

local function replacePublicArea(room, area, areaRefs, areaCount)
  assert(denseCount(areaRefs, "ChangeCardArea public refs") == areaCount,
    "ChangeCardArea public ref count mismatch")
  local ids = {}
  for i, reference in ipairs(areaRefs) do
    canonical(reference)
    ids[i] = room.card_wire_refs:toLocal(reference)
  end
  clearZone(room, area)
  local field = area == Card.DiscardPile and "discard_pile" or "void"
  room[field] = ids
  for _, id in ipairs(ids) do room:setCardArea(id, area, nil) end
  for _, player in ipairs(room.players or {}) do
    local tracker = player.card_tracker
    local known = tracker and trackerFor(tracker, area)
    if known then
      known.known_cards = copy(ids)
      known.uncertain_cards = {}
    end
  end
end

local function replaceDrawPile(room, count)
  local previous = room.draw_pile or {}
  for _, id in ipairs(previous) do
    if room.card_place[id] == Card.DrawPile then
      room.card_place[id] = nil
      room.owner_map[id] = nil
    end
  end
  local replacement = room.card_wire_refs:replaceAnonymousDeck(count, previous)
  room.draw_pile = replacement
  for _, id in ipairs(replacement) do room:setCardArea(id, Card.DrawPile, nil) end
  for _, player in ipairs(room.players or {}) do
    local tracker = player.card_tracker
    if tracker then
      tracker.draw_pile = { known_cards = {}, uncertain_cards = {} }
      tracker.draw_pile_order = {}
      for i = 1, count do tracker.draw_pile_order[i] = -1 end
    end
  end
end

function Area.receive(room, packet)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "count-only ChangeCardArea requires negotiated Hegemony v1")
  assert(type(packet) == "table", "ChangeCardArea must contain a projected packet")
  assert(room.card_wire_refs and room.card_wire_refs.replaceAnonymousDeck,
    "v1 client-local card references are unavailable")
  exactFields(packet, {
    count = true, area = true, areaCount = true,
    areaRefs = true, retiredRefs = true,
  })
  local count = integer(packet.count, "ChangeCardArea count")
  local area = integer(packet.area, "ChangeCardArea area")
  local areaCount = integer(packet.areaCount, "ChangeCardArea areaCount")
  assert(count >= 0 and count <= MAX_ZONE and
    areaCount >= 0 and areaCount <= MAX_ZONE,
    "ChangeCardArea count is out of range")
  assert(area == Card.DrawPile or area == Card.DiscardPile or area == Card.Void,
    "ChangeCardArea area is not audited")

  if area == Card.DrawPile then
    assert(packet.areaRefs == nil and type(packet.retiredRefs) == "table",
      "draw-pile ChangeCardArea must carry retired refs only")
    denseCount(packet.retiredRefs, "ChangeCardArea retired refs")
    for _, reference in ipairs(packet.retiredRefs) do
      if type(reference) == "string" then token(reference) else canonical(reference) end
    end
    -- Validate every ref before mutating any area, then retire old public
    -- identities and replace the entire hidden deck without ordered IDs.
    for _, reference in ipairs(packet.retiredRefs) do
      retireReference(room, reference)
    end
    replaceDrawPile(room, areaCount)
  else
    assert(packet.retiredRefs == nil and type(packet.areaRefs) == "table",
      "public ChangeCardArea must carry canonical area refs")
    denseCount(packet.areaRefs, "ChangeCardArea public refs")
    for _, reference in ipairs(packet.areaRefs) do canonical(reference) end
    replacePublicArea(room, area, packet.areaRefs, areaCount)
  end
  return count
end

return Area
