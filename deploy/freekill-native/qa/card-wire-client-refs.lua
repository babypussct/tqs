-- Candidate-only client-local identities for Hegemony card-wire v1.
-- Local aliases are never canonical server card IDs and must never be sent
-- without converting through toWire. The legacy client does not use this.
local Refs = {}
Refs.__index = Refs

local MIN_LOCAL, MAX_LOCAL = 1000000000, 1999999999
local MAX_DECK = 8192

local function integer(value, name)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0,
    name .. " must be an integer")
  return value
end

local function canonical(id)
  integer(id, "canonical ID")
  assert((id >= 1 or id <= -2) and
    (id < MIN_LOCAL or id > MAX_LOCAL),
    "canonical ID is reserved, unknown or collides with the local namespace")
end

local function tokenValid(token)
  return type(token) == "string" and #token >= 18 and #token <= 128 and
    token:sub(1, 2) == "h:" and token:sub(3):match("^[%w_-]+$") ~= nil
end

local function denseCount(list, name)
  assert(type(list) == "table", name .. " must be an array")
  local count, max = 0, 0
  for index in pairs(list) do
    integer(index, name .. " index")
    assert(index >= 1, name .. " index must be positive")
    count = count + 1
    if index > max then max = index end
  end
  assert(count == max, name .. " must be dense")
  return count
end

function Refs.new(isOccupied)
  assert(isOccupied == nil or type(isOccupied) == "function",
    "isOccupied must be a function")
  return setmetatable({
    nextLocal = MIN_LOCAL,
    isOccupied = isOccupied or function() return false end,
    byToken = {}, byLocal = {}, anonymous = {},
    usedLocal = {}, retiredTokens = {},
  }, Refs)
end

function Refs:_allocate()
  while self.nextLocal <= MAX_LOCAL do
    local id = self.nextLocal
    self.nextLocal = id + 1
    -- Never recycle an alias even after a reconnect or rekey. Another
    -- subsystem may still be holding the earlier ID in a UI queue.
    if not self.usedLocal[id] and not self.isOccupied(id) then
      self.usedLocal[id] = true
      return id
    end
  end
  error("local card-wire identity namespace exhausted")
end

function Refs:toLocal(reference)
  if type(reference) == "number" then
    canonical(reference)
    return reference
  end
  assert(tokenValid(reference), "invalid opaque card reference")
  assert(not self.retiredTokens[reference], "replayed or expired card reference")
  local id = self.byToken[reference]
  if id then return id end
  id = self:_allocate()
  self.byToken[reference] = id
  self.byLocal[id] = reference
  return id
end

-- A card entering the concealed draw pile must receive a fresh positional
-- alias, never an opaque card handle.  The server-side projector may still
-- carry a rekeyed opaque reference in the MoveCards transition so the
-- source area can be replaced atomically, but that reference must not become
-- addressable from the anonymous deck.
function Refs:mintAnonymous()
  local id = self:_allocate()
  self.anonymous[id] = true
  return id
end

function Refs:toWire(id)
  integer(id, "local card ID")
  assert(not self.anonymous[id], "anonymous deck position is not a card choice")
  local token = self.byLocal[id]
  if token then return token end
  assert(not self.usedLocal[id], "expired or unrecognized local card identity")
  canonical(id)
  return id
end

function Refs:isHiddenLocal(id)
  return type(id) == "number" and self.usedLocal[id] == true
end

function Refs:isAnonymous(id)
  return type(id) == "number" and self.anonymous[id] == true
end

function Refs:retire(id)
  integer(id, "local card ID")
  local token = self.byLocal[id]
  if token then
    self.retiredTokens[token] = true
    self.byToken[token] = nil
    self.byLocal[id] = nil
  end
  self.anonymous[id] = nil
end

-- A shuffle, reconnect or deck-count sync replaces every anonymous
-- position. No positional identity survives the operation.
function Refs:replaceAnonymousDeck(count, previous)
  integer(count, "anonymous deck size")
  assert(count >= 0 and count <= MAX_DECK, "invalid anonymous deck size")
  if previous ~= nil then
    denseCount(previous, "prior deck")
    for _, id in ipairs(previous) do
      integer(id, "prior deck identity")
      -- A real card returned to the hidden deck is no longer addressable
      -- through a previously issued opaque token.
      if self.usedLocal[id] then self:retire(id) end
    end
  end
  local result = {}
  for i = 1, count do
    result[i] = self:mintAnonymous()
  end
  return result
end

function Refs:consumeAnonymous(deck, position)
  local size = denseCount(deck, "anonymous deck")
  integer(position, "deck position")
  assert(position >= 1 and position <= size, "deck position is out of range")
  local id = deck[position]
  assert(self.anonymous[id], "deck position does not contain an anonymous slot")
  table.remove(deck, position)
  self:retire(id)
  return id
end

function Refs:resetSession()
  for token, id in pairs(self.byToken) do
    self.retiredTokens[token] = true
    self.byLocal[id] = nil
  end
  self.byToken = {}
  self.byLocal = {}
  self.anonymous = {}
  -- Keep issued IDs and token tombstones; stale UI IDs must never become
  -- valid choices in a later session on the same client object.
end

return Refs
