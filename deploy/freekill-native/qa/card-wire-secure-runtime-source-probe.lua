-- Execute actual candidate ServerRoomBase methods and its real OS entropy
-- module with invented IDs. Never print tokens or internal audience keys.
local root = assert((...), "isolated candidate core required")
package.path = root .. "/lua/?.lua;" .. package.path
local Mint = require("server.card_wire_secure_mint")
local Protocol = require("server.card_handle_protocol")
local expectedLength = 2 + 24 * 2

local tokens = {}
for _ = 1, 96 do
  local token = Mint.next()
  assert(type(token) == "string" and #token == expectedLength
    and token:match("^h:%x+$") and not tokens[token],
    "CSPRNG tokens must be long, hex, and unique")
  tokens[token] = true
end

local open = io.open
local function expectEntropyFailure(replacement)
  io.open = replacement
  local ok = pcall(Mint.next)
  io.open = open
  assert(not ok, "OS CSPRNG must fail closed on a broken input source")
end
expectEntropyFailure(function() return nil, "permission denied" end)
expectEntropyFailure(function()
  return { read = function() return "short" end, close = function() return true end }
end)
expectEntropyFailure(function()
  return { read = function() return string.rep("a", 24) end,
    close = function() return nil end }
end)

local file = assert(io.open(root .. "/lua/server/roombase.lua", "rb"))
local source = assert(file:read("*a"))
file:close()
local methods = {}
local env = setmetatable({ ServerRoomBase = methods }, { __index = _G })
for _, signature in ipairs({
  "function ServerRoomBase:cardWireAudience(physical)",
  "function ServerRoomBase:beginCardWireBatch()",
}) do
  local start = assert(source:find(signature, 1, true), "missing candidate runtime method")
  local finish = assert(source:find("\nend\n", start, true), "unclosed candidate runtime method")
  assert(load(source:sub(start, finish + 4), "=candidate/native-card-wire", "t", env))()
end

local room = setmetatable({ card_wire_version = 1, mode = "new_heg_mode" },
  { __index = methods })
function room:getSettings(k) assert(k == "gameMode"); return self.mode end

local ownerSocket, peerSocket, spectatorSocket, controllerSocket = {}, {}, {}, {}
local owner = room:cardWireAudience(ownerSocket)
local peer = room:cardWireAudience(peerSocket)
local spectator = room:cardWireAudience(spectatorSocket)
local controller = room:cardWireAudience(controllerSocket)
assert(owner == room:cardWireAudience(ownerSocket) and
  owner ~= peer and owner ~= spectator and peer ~= spectator and
  controller ~= owner and controller ~= spectator,
  "physical sockets must have independent non-reused audience identities")
assert(room._cardWireProtocol == nil, "audience minting must not start a card mapping")

local batch = room:beginCardWireBatch()
assert(getmetatable(room._cardWireProtocol) == Protocol)
local seatRef = batch:reference(owner, 771, false)
local peerRef = batch:reference(peer, 771, false)
local spectatorRef = batch:reference(spectator, 771, false)
assert(seatRef ~= peerRef and seatRef ~= spectatorRef and peerRef ~= spectatorRef,
  "same canonical concealed card must project independently to each socket")
local request = batch:issueChoice(owner, "physical-choice/1", {
  { id = 771, public = false }, { id = -2, public = false },
}, 1, 2)
assert(request[1] ~= seatRef,
  "a concealed request must mint a unique answer token, not reuse its zone handle")
batch:commit()
local store = room._cardWireProtocol
local eligible = function() return true end
assert(store:resolveChoice(peer, "physical-choice/1", { request[1] }, eligible) == nil,
  "peer cannot resolve another physical audience's request")
assert(store:resolveChoice(owner, "physical-choice/1", { request[1] }, eligible)[1] == 771)
assert(store:resolveChoice(owner, "physical-choice/1", { request[1] }, eligible) == nil,
  "a consumed request cannot be replayed")

-- A public physical card has a canonical zone ID, but its answer must still
-- be scoped to a single prompt. An old public reply cannot satisfy a redraw.
local publicFirst = store:issueChoice(owner, "public-choice/old", {
  { id = 771, public = true },
})
local publicNext = store:issueChoice(owner, "public-choice/new", {
  { id = 771, public = true },
})
assert(type(publicFirst[1]) == "string" and publicFirst[1] ~= publicNext[1]
  and publicFirst[1] ~= 771 and publicNext[1] ~= 771,
  "public answer refs must be distinct from canonical IDs and previous prompts")
assert(store:resolveChoice(owner, "public-choice/new", publicFirst, eligible) == nil,
  "delayed public answer must not satisfy a new prompt")
assert(store:resolveChoice(owner, "public-choice/old", publicFirst, eligible)[1] == 771,
  "an original public answer token remains valid for its original pending request")
local publicValid = store:issueChoice(owner, "public-choice/valid", {
  { id = 771, public = true },
})
assert(store:resolveChoice(owner, "public-choice/valid", publicValid, eligible)[1] == 771)
store:issueChoice(owner, "public-choice/raw", { { id = 771, public = true } })
assert(store:resolveChoice(owner, "public-choice/raw", { 771 }, eligible) == nil,
  "canonical public ID alone is not a valid request answer")

local pending = store:issueChoice(owner, "physical-choice/2", { { id = 771, public = false } })
local state = store.audiences[owner]
local aborted = room:beginCardWireBatch()
local abortedRef = aborted:reference(owner, 801, false)
aborted:reference(spectator, 801, false)
aborted:abort()
assert(state == store.audiences[owner] and store.audiences[owner].byId[801] == nil
  and store.issued[abortedRef], "abort must not publish partial audience state")
assert(store:resolveChoice(owner, "physical-choice/2", pending, eligible)[1] == 771,
  "aborted send must preserve previously issued valid request")
local renewed = room:beginCardWireBatch()
renewed:resetAudience(owner)
local freshRef = renewed:reference(owner, 771, false)
renewed:commit()
assert(freshRef ~= seatRef and store:reference(owner, 771, false) == freshRef,
  "reconnect must retire the old handle and keep the next session stable")
assert(store:reference(peer, 771, false) == peerRef,
  "one physical reconnect must not affect the peer audience")

-- A mid-batch entropy outage must roll back all physical audiences. Avoid
-- assertions on token strings in the output; inspect only the staged state.
local existing = store:reference(owner, 771, false)
local original = io.open
local staged = room:beginCardWireBatch()
staged:reference(owner, 901, false)
io.open = function() return nil, "entropy unavailable" end
local ok = pcall(function() staged:reference(spectator, 902, false) end)
io.open = original
assert(not ok, "entropy failure must terminate the transaction")
local canCommit = pcall(function() staged:commit() end)
assert(not canCommit, "failed transaction must not commit")
staged:abort()
assert(store.audiences[owner].byId[901] == nil and
  store.audiences[spectator].byId[902] == nil and
  store:reference(owner, 771, false) == existing,
  "entropy failure must preserve all committed physical audiences")

room.mode = "identity"
assert(not pcall(function() room:beginCardWireBatch() end))
assert(not pcall(function() room:cardWireAudience({}) end))
room.mode = "new_heg_mode"
room.card_wire_version = nil
assert(not pcall(function() room:beginCardWireBatch() end))
assert(not pcall(function() room:cardWireAudience({}) end))

print("PASS candidate native card-wire entropy: OS CSPRNG, per-physical audience, replay, reconnect, abort, entropy failure, guarded opt-in; synthetic IDs; native/browser NOT RUN")
