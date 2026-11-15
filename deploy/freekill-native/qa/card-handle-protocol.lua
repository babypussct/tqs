-- Contract prototype for concealed physical-card references in new_heg_mode.
-- QA-only, transport-free: do not deploy this module as a native wire patch.
-- Callers must use a cryptographically secure, unpredictable token generator;
-- this module cannot supply or establish cryptographic token entropy.
local Protocol = {}
Protocol.__index = Protocol
local Batch = {}
Batch.__index = Batch

local function checkId(id)
  -- Core CardManager allocates printed cards at -2, -3, ... and virtual
  -- cards from 65536. Zero and -1 are reserved/unknown-card sentinels.
  assert(type(id) == "number" and id % 1 == 0
    and (id >= 1 or id <= -2),
    "expected a concrete physical, printed, or virtual card ID")
end

local function denseLength(entries, name)
  assert(type(entries) == "table", name .. " must be an array")
  local count, maximum = 0, 0
  for key in pairs(entries) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1,
      name .. " must use positive integer array indexes only")
    count = count + 1
    if key > maximum then maximum = key end
  end
  assert(count == maximum, name .. " must not have holes")
  return count
end

local function checkAudience(audience)
  assert(type(audience) == "string" and audience ~= "",
    "physical connection audience required")
end

local function checkRequest(key)
  assert(type(key) == "string" and key ~= "", "request key required")
end

local function validateChoices(requestKey, choices, minCount, maxCount)
  checkRequest(requestKey)
  local count = denseLength(choices, "choice entries")
  minCount = minCount or 1
  maxCount = maxCount or count
  assert(type(minCount) == "number" and minCount % 1 == 0 and minCount >= 0
    and type(maxCount) == "number" and maxCount % 1 == 0
    and minCount <= maxCount and maxCount <= count,
    "valid choice cardinality required")
  local uniqueIds = {}
  for i = 1, count do
    local choice = choices[i]
    assert(type(choice) == "table", "invalid choice entry")
    checkId(choice.id)
    assert(type(choice.public) == "boolean", "choice visibility required")
    assert(not uniqueIds[choice.id], "duplicate physical card choice")
    uniqueIds[choice.id] = true
  end
  return count, minCount, maxCount
end

local function cloneMap(source)
  local result = {}
  for key, value in pairs(source) do result[key] = value end
  return result
end

local function cloneAudience(state)
  -- Request values are immutable; _forget only removes their top-level keys.
  return { byId = cloneMap(state.byId), byToken = cloneMap(state.byToken),
    public = cloneMap(state.public), requests = cloneMap(state.requests),
    metadata = cloneMap(state.metadata or {}) }
end

function Protocol.new(mint)
  assert(type(mint) == "function", "inject a secure opaque-token generator")
  return setmetatable({ mint = mint, issued = {}, audiences = {} }, Protocol)
end

-- Stage every physical recipient of one native notification together.
-- Aborted batches never expose partially minted audience mappings. Minted
-- tokens remain global tombstones and cannot be reused after an abort.
function Protocol:beginBatch()
  assert(self.activeBatch == nil, "one card-wire batch may be active at a time")
  local batch = setmetatable({ protocol = self, staged = {}, failed = false,
    closed = false }, Batch)
  self.activeBatch = batch
  return batch
end

function Batch:_apply(audience, fn)
  assert(not self.closed and not self.failed and
    self.protocol.activeBatch == self, "card-wire batch no longer usable")
  local ok, result = pcall(function()
    checkAudience(audience)
    local draft = self.staged[audience]
    if not draft then
      local current = self.protocol.audiences[audience]
      draft = current and cloneAudience(current) or
        { byId = {}, byToken = {}, public = {}, requests = {} }
      self.staged[audience] = draft
    end
    return fn(draft)
  end)
  if not ok then
    self.failed = true
    error(result, 2)
  end
  return result
end

function Batch:reference(audience, id, isPublic)
  return self:_apply(audience, function(draft)
    checkId(id)
    assert(type(isPublic) == "boolean", "explicit audience visibility required")
    return self.protocol:_reference(draft, id, isPublic)
  end)
end

-- Inspect the client's standing source identity without minting, publishing
-- or retiring anything. Movement authorization may differ from source
-- visibility when a card is gained from another player's concealed hand.
function Batch:currentReference(audience, id)
  return self:_apply(audience, function(draft)
    checkId(id)
    return draft.byId[id] or (draft.public[id] and id or nil)
  end)
end

-- Metadata can be emitted after the server has already applied a physical
-- movement but before the corresponding MoveCards notification reaches the
-- client. Return the audience's current standing reference without changing
-- its visibility or retiring its old handle; MoveCards is the explicit
-- transition packet that carries cardWireRetiredRefs.
function Batch:standing(audience, id, isPublic)
  return self:_apply(audience, function(draft)
    checkId(id)
    assert(type(isPublic) == "boolean", "explicit audience visibility required")
    -- Public metadata still uses the canonical numeric ID because the
    -- legacy SetCardMark client callback cannot consume an opaque token. Keep
    -- the hidden standing handle staged until MoveCards explicitly rekeys it.
    if draft.byId[id] ~= nil then
      return isPublic and id or draft.byId[id]
    end
    if draft.public[id] then
      if isPublic then return id end
      -- A private metadata packet can precede a public-to-hidden MoveCards.
      -- Never expose the old public ID or replace its standing source state.
      -- This detached metadata token is not a gameplay reply capability.
      draft.metadata = draft.metadata or {}
      if not draft.metadata[id] then draft.metadata[id] = self.protocol:_mint() end
      return draft.metadata[id]
    end
    if isPublic then
      draft.public[id] = true
      return id
    end
    return self.protocol:_reference(draft, id, false)
  end)
end

function Batch:project(audience, ids, visible)
  return self:_apply(audience, function(draft)
    assert(type(visible) == "function", "visibility callback required")
    local count = denseLength(ids, "projected card IDs")
    local flags = {}
    for i = 1, count do
      checkId(ids[i])
      flags[i] = visible(ids[i])
      assert(type(flags[i]) == "boolean", "explicit visibility required per card")
    end
    local refs = {}
    for i = 1, count do
      refs[i] = self.protocol:_reference(draft, ids[i], flags[i])
    end
    return refs
  end)
end

function Batch:rekey(audience, ids)
  return self:_apply(audience, function(draft)
    local count = denseLength(ids, "rekey card IDs")
    for i = 1, count do checkId(ids[i]) end
    local retired = {}
    for i = 1, count do
      local id = ids[i]
      local reference = draft.byId[id]
      if reference == nil and draft.public[id] then reference = id end
      if reference ~= nil then table.insert(retired, reference) end
      self.protocol:_forget(draft, id)
    end
    return retired
  end)
end

-- Request handles belong to the same per-physical transaction as the
-- notification that advertises them. A failed spectator projection or CBOR
-- encode must not leave an active choice the client never received.
function Batch:issueChoice(audience, requestKey, choices, minCount, maxCount)
  return self:_apply(audience, function(draft)
    local count, minimum, maximum = validateChoices(requestKey, choices, minCount, maxCount)
    assert(draft.requests[requestKey] == nil, "request key already active")
    return self.protocol:_issueChoice(draft, requestKey, choices, count, minimum, maximum)
  end)
end

function Batch:cancelChoice(audience, requestKey)
  return self:_apply(audience, function(draft)
    checkRequest(requestKey)
    draft.requests[requestKey] = nil
  end)
end

-- A reconnect reclaims one physical socket. Retire its old handles and
-- pending requests atomically with the new snapshot, without changing the
-- state belonging to another controller or spectator of the same seat.
function Batch:resetAudience(audience)
  return self:_apply(audience, function(draft)
    draft.byId = {}
    draft.byToken = {}
    draft.public = {}
    draft.requests = {}
  end)
end

function Batch:commit()
  assert(not self.closed and not self.failed and
    self.protocol.activeBatch == self, "cannot commit failed or inactive card-wire batch")
  for audience, state in pairs(self.staged) do
    self.protocol.audiences[audience] = state
  end
  self.protocol.activeBatch = nil
  self.closed = true
end

function Batch:abort()
  assert(not self.closed and self.protocol.activeBatch == self,
    "cannot abort inactive card-wire batch")
  self.protocol.activeBatch = nil
  self.closed = true
  self.staged = {}
end

function Protocol:_audience(audience)
  assert(self.activeBatch == nil,
    "direct audience mutation forbidden while a card-wire batch is active")
  checkAudience(audience)
  local state = self.audiences[audience]
  if not state then
    state = { byId = {}, byToken = {}, public = {}, requests = {} }
    self.audiences[audience] = state
  end
  return state
end

function Protocol:_mint()
  local token = self.mint()
  assert(type(token) == "string" and #token >= 18 and #token <= 128
    and token:sub(1, 2) == "h:"
    and token:sub(3):match("^[%w_-]+$") ~= nil,
    "secure generator must return a long opaque h: token")
  assert(not self.issued[token], "duplicate opaque token: refusing reuse")
  self.issued[token] = true
  return token
end

function Protocol:_forget(state, id)
  local old = state.byId[id]
  if old then
    state.byId[id] = nil
    state.byToken[old] = nil
  end
  state.public[id] = nil
  if state.metadata then state.metadata[id] = nil end
  -- Changes in visibility, ownership, or identity invalidate outstanding
  -- choices that were issued against the previous game state.
  for key, request in pairs(state.requests) do
    if request.ids[id] then state.requests[key] = nil end
  end
end

function Protocol:forget(audience, id)
  checkId(id)
  self:_forget(self:_audience(audience), id)
end

function Protocol:_reference(state, id, isPublic)
  if isPublic then
    -- Public identity may be sent as canonical ID. All prior concealed
    -- handles are retired on the *transition* to public. Re-notifying the
    -- same public card must preserve any pending valid public choices.
    if not state.public[id] then self:_forget(state, id) end
    state.public[id] = true
    return id
  end
  -- A card becoming hidden again must invalidate previously issued public
  -- choices, even though no opaque handle existed in the public state.
  if state.public[id] then self:_forget(state, id) end
  local token = state.byId[id]
  if not token then
    token = self:_mint()
    state.byId[id] = token
    state.byToken[token] = id
  end
  return token
end

function Protocol:reference(audience, id, isPublic)
  checkId(id)
  assert(type(isPublic) == "boolean", "explicit audience visibility required")
  return self:_reference(self:_audience(audience), id, isPublic)
end

function Protocol:project(audience, ids, visible)
  assert(type(visible) == "function",
    "project expects physical IDs and per-audience visibility callback")
  local count = denseLength(ids, "projected card IDs")
  -- Visibility can consult live server state and can fail. Preflight all
  -- entries before issuing even the first opaque reference.
  local flags = {}
  for i = 1, count do
    checkId(ids[i])
    flags[i] = visible(ids[i])
    assert(type(flags[i]) == "boolean", "explicit visibility required per card")
  end
  local draft = cloneAudience(self:_audience(audience))
  local result = {}
  for i = 1, count do
    local id = ids[i]
    result[i] = self:_reference(draft, id, flags[i])
  end
  -- Commit only after all card references are constructed successfully.
  self.audiences[audience] = draft
  return result
end

function Protocol:rekey(audience, ids)
  local count = denseLength(ids, "rekey card IDs")
  for i = 1, count do checkId(ids[i]) end
  local state = self:_audience(audience)
  local retired = {}
  for i = 1, count do
    local id = ids[i]
    local reference = state.byId[id]
    if reference == nil and state.public[id] then reference = id end
    if reference ~= nil then table.insert(retired, reference) end
    self:_forget(state, id)
  end
  return retired
end

function Protocol:_issueChoice(draft, requestKey, choices, count, minCount, maxCount)
  -- A choice is a one-shot, request-scoped allowlist, not arbitrary token
  -- decoding. Each entry is {id = serverCardId, public = bool}.
  local request = { refs = {}, ids = {}, hiddenRefs = {}, publicRefs = {},
    minCount = minCount, maxCount = maxCount }
  local result = {}
  for i = 1, count do
    local choice = choices[i]
    local id = choice.id
    local standingRef = self:_reference(draft, id, choice.public)
    -- Neither persistent concealed handles nor canonical public card IDs are
    -- safe as answers: a delayed reply to an earlier prompt could otherwise
    -- satisfy a later prompt offering the same card. Mint for every prompt.
    local ref = self:_mint()
    if choice.public then
      request.publicRefs[ref] = true
    else
      request.hiddenRefs[ref] = standingRef
    end
    request.refs[ref] = id
    request.ids[id] = true
    result[i] = ref
  end
  draft.requests[requestKey] = request
  return result
end

function Protocol:issueChoice(audience, requestKey, choices, minCount, maxCount)
  local state = self:_audience(audience)
  local count, minimum, maximum = validateChoices(requestKey, choices, minCount, maxCount)
  assert(state.requests[requestKey] == nil, "request key already active")
  -- Preflight and stage all refs; a mid-mint failure cannot partially publish.
  local draft = cloneAudience(state)
  local result = self:_issueChoice(draft, requestKey, choices, count, minimum, maximum)
  self.audiences[audience] = draft
  return result
end

function Protocol:resolveChoice(audience, requestKey, references, stillEligible)
  checkRequest(requestKey)
  assert(type(references) == "table" and type(stillEligible) == "function",
    "choice resolution requires references and current-state eligibility")
  local state = self:_audience(audience)
  local request = state.requests[requestKey]
  if not request then return nil, "unknown_or_expired_request" end
  -- Consume before validation so replay and partially valid responses fail.
  state.requests[requestKey] = nil
  -- The wire can contain sparse or keyed tables. Lua's #/ipairs would ignore
  -- trailing untrusted entries, so validate the full shape fail closed.
  local ok, count = pcall(denseLength, references, "choice references")
  if not ok then return nil, "invalid_reference_array" end
  if count < request.minCount or count > request.maxCount then
    return nil, "invalid_cardinality"
  end
  local result, seen = {}, {}
  for i = 1, count do
    local ref = references[i]
    local id = request.refs[ref]
    if not id or seen[id] then return nil, "unknown_or_duplicate_reference" end
    if request.publicRefs[ref] then
      if not state.public[id] then return nil, "expired_reference" end
    else
      local standingRef = request.hiddenRefs[ref]
      if standingRef == nil or state.byId[id] ~= standingRef
          or state.byToken[standingRef] ~= id then
        return nil, "expired_reference"
      end
    end
    if not stillEligible(id) then return nil, "no_longer_eligible" end
    seen[id] = true
    result[i] = id
  end
  return result
end

function Protocol:cancelChoice(audience, requestKey)
  checkRequest(requestKey)
  self:_audience(audience).requests[requestKey] = nil
end

function Protocol:disconnect(audience)
  assert(self.activeBatch == nil,
    "disconnect forbidden while a card-wire batch is active")
  checkAudience(audience)
  -- Keep issued-token tombstones for the lifetime of this room; a reconnect
  -- must never accidentally reactivate an older opaque identifier.
  self.audiences[audience] = nil
end

return Protocol
