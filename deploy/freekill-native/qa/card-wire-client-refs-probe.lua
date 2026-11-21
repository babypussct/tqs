-- Exercise real candidate module and the actual Player:cardVisible Lua body.
-- Synthetic-only: a future end-to-end native client still needs full wiring.
local root = assert(..., "isolated candidate core root required")
local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local function rejects(callback, needle)
  local ok, reason = pcall(callback)
  assert(not ok and tostring(reason):find(needle, 1, true),
    "expected failure containing " .. needle .. ": " .. tostring(reason))
end
local function token(seed)
  return "h:" .. string.rep(seed, 24)
end

local reserved = { [1000000000] = true }
local a = Refs.new(function(id) return reserved[id] end)
local b = Refs.new()
local ta, tb = token("a"), token("b")
local alias = a:toLocal(ta)
assert(alias == 1000000001 and a:toLocal(ta) == alias)
assert(a:isHiddenLocal(alias) and not a:isAnonymous(alias))
assert(a:toWire(alias) == ta)
assert(a:toLocal(31) == 31 and a:toLocal(-5) == -5)
assert(a:toWire(31) == 31 and a:toWire(-5) == -5)
assert(b:toLocal(tb) == 1000000000 and b:toWire(b:toLocal(tb)) == tb)
assert(a:toLocal(tb) ~= alias)
rejects(function() a:toLocal("h:a") end, "invalid opaque")
rejects(function() a:toLocal("h:" .. string.rep("#", 25)) end, "invalid opaque")
rejects(function() a:toLocal(0) end, "canonical ID")
rejects(function() a:toLocal(-1) end, "canonical ID")
rejects(function() a:toLocal(alias) end, "canonical ID")
rejects(function() a:toWire(1000000099) end, "canonical ID")
rejects(function() a:toWire({ id = 31 }) end, "local card ID")

-- Demonstrate the legacy nil-card visibility hazard is closed for aliases.
local input = assert(io.open(root .. "/ltk/core/player.lua", "rb"))
local source = assert(input:read("*a")); input:close()
local first = assert(source:find("function Player:cardVisible(cardId, move, toChoose)", 1, true))
local last = assert(source:find("\nend\n", first, true))
local currentRoom = { card_wire_refs = a }
local environment = setmetatable({
  Player = {}, Fk = {
    getCardById = function() return nil end,
    currentRoom = function() return currentRoom end,
  },
}, { __index = _G })
assert(load(source:sub(first, last + 4), "=candidate/cardVisible", "t", environment))()
assert(environment.Player.cardVisible({}, alias) == false)
assert(environment.Player.cardVisible({}, a:toLocal(tb)) == false)
assert(environment.Player.cardVisible({}, 31) == true)
currentRoom.card_wire_refs = nil
assert(environment.Player.cardVisible({}, alias) == true,
  "no local namespace in legacy client")

local deck = a:replaceAnonymousDeck(4)
assert(#deck == 4 and deck[1] ~= deck[2] and a:isHiddenLocal(deck[1]))
rejects(function() a:toWire(deck[1]) end, "anonymous deck")
local removed = a:consumeAnonymous(deck, 1)
assert(#deck == 3 and not a:isAnonymous(removed))
rejects(function() a:toWire(removed) end, "expired or unrecognized")
rejects(function() a:consumeAnonymous(deck, 0) end, "out of range")
rejects(function() a:consumeAnonymous(deck, 9) end, "out of range")
rejects(function() a:replaceAnonymousDeck(8193) end, "invalid anonymous")
rejects(function() a:replaceAnonymousDeck(2, { [1] = 31, [3] = 32 }) end,
  "must be dense")

local rotated = a:replaceAnonymousDeck(2, deck)
assert(#rotated == 2 and not a:isAnonymous(deck[1]) and a:isAnonymous(rotated[2]))
-- A previously issued opaque token returning to deck must be retired.
a:replaceAnonymousDeck(1, { alias })
rejects(function() a:toLocal(ta) end, "replayed or expired")
rejects(function() a:toWire(alias) end, "expired or unrecognized")
local renewed = token("c")
local renewedId = a:toLocal(renewed)
assert(renewedId ~= alias and renewedId ~= removed)
a:resetSession()
rejects(function() a:toLocal(renewed) end, "replayed or expired")
rejects(function() a:toWire(renewedId) end, "expired or unrecognized")
assert(a:isHiddenLocal(renewedId), "stale IDs must remain UI-hidden")
assert(a:toLocal(token("d")) > renewedId)

local repeated = Refs.new()
local firstSlot
for _ = 1, 10 do
  local current = {}
  for _ = 1, 20 do
    current = repeated:replaceAnonymousDeck(211, current)
    firstSlot = firstSlot or current[1]
  end
  repeated:resetSession()
end
assert(next(repeated.anonymous) == nil and next(repeated.occupiedLocal) == nil)
assert(next(repeated.retiredTokens) == nil, "anonymous slots cannot create token history")
assert(repeated:isHiddenLocal(firstSlot))
rejects(function() repeated:toWire(firstSlot) end, "expired or unrecognized")
local draft = repeated:fork()
local draftId = draft:toLocal(token("e"))
draft:retire(draftId)
assert(not repeated:isHiddenLocal(draftId), "preflight cannot install a draft alias")
assert(repeated.retiredTokens[token("e")] == nil)
repeated:commitDraft(draft)
assert(repeated:isHiddenLocal(draftId))
rejects(function() repeated:toLocal(token("e")) end, "replayed or expired")

print("PASS candidate client-local references: opaque/local/reverse, collision, visible fallback, " ..
  "unknown deck, stale/rekey/reconnect, no alias recycling; synthetic-only; native/browser NOT RUN")
