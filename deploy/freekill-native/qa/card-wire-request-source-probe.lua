-- Execute the candidate's real Request methods with synthetic sockets/CBOR.
-- A future native proof must use decoded network CBOR and a real projector.
local root, protocolFile = ...
assert(root and protocolFile, "candidate root and protocol QA module required")
local f = assert(io.open(root .. "/lua/server/request.lua", "rb"))
local source = assert(f:read("*a"))
f:close()

local function copy(v)
  if type(v) ~= "table" then return v end
  local result = {}
  for k, x in pairs(v) do result[k] = copy(x) end
  return result
end

local Protocol = dofile(protocolFile)
local nonce = 0
local function mint()
  nonce = nonce + 1
  return "h:" .. string.format("%032x", nonce)
end
local protocol = Protocol.new(mint)
local methods = {}
local encodeFail, projectFail, projectNil, projectPublic = false, false, false, false
local env = setmetatable({
  Request = methods,
  surrenderCheck = function() end,
  fk = { Player_Online = "online" },
  cbor = {
    encode = function(data)
      if encodeFail then error("synthetic CBOR failure") end
      return { packed = copy(data) }
    end,
    decode = function(data)
      assert(type(data) == "table" and data.packed ~= nil, "invalid wire CBOR")
      return copy(data.packed)
    end,
  },
  table = setmetatable({ contains = function(xs, value)
    for _, x in ipairs(xs) do if x == value then return true end end
    return false
  end }, { __index = table }),
  require = function(name)
    assert(name == "server.card_wire_secure_mint")
    return { next = mint }
  end,
}, { __index = _G })

local function loadMethod(signature)
  local start = assert(source:find(signature, 1, true), "method missing: " .. signature)
  local ending = assert(source:find("\nend\n", start, true), "unterminated: " .. signature)
  assert(load(source:sub(start, ending + 4), "=candidate/request", "t", env))()
end
loadMethod("function Request:_sendPacket(player)")
loadMethod("function Request:_checkReply(player, use_ai)")
loadMethod("function Request:_finish()")

local owner = { packets = {}, state = "online", currentlyThinking = false }
function owner:thinking() return self.currentlyThinking end
function owner:getState() return self.state end
function owner:setThinking(b) self.currentlyThinking = b end
function owner:doRequest(command, payload, timeout, timestamp)
  self.packets[#self.packets + 1] = {command = command, payload = copy(payload)}
end
function owner:waitForReply()
  local reply = self.reply
  self.reply = "__notready"
  return reply
end

local spectator = { packets = {} }
local player = { id = 1, serverplayer = owner, _observers = {owner} }
local room = {
  card_wire_version = 1, settings = {gameMode = "new_heg_mode"},
  _cardWireProtocol = protocol, timeout = 10, players = {player},
  last_request = nil,
}
function room:getSettings(key) return self.settings[key] end
function room:getTag() return nil end
function room:cardWireAudience(physical)
  assert(physical == owner, "wrong physical socket")
  return "aud:owner"
end
function room:beginCardWireBatch() return protocol:beginBatch() end
function room:projectCardWireRequest(seat, physical, command, data, batch, requestKey)
  assert(seat == player and physical == owner and command == "AskForCardChosen")
  assert(data[1] == "target" and type(requestKey) == "string")
  if projectFail then error("projector refused request") end
  if projectNil then return nil end
  local choices = batch:issueChoice(self:cardWireAudience(physical), requestKey,
    { {id = 501, public = projectPublic} }, 1, 1)
  return { "target", choices }
end
function room:resolveCardWireRequestReply(seat, physical, command, reply, requestKey)
  assert(seat == player and physical == owner and command == "AskForCardChosen")
  local result, err = protocol:resolveChoice(self:cardWireAudience(physical),
    requestKey, {reply}, function(id) return id == 501 and not self.cardMoved end)
  if not result then return nil, err end
  return result[1]
end

local function request()
  return setmetatable({
    room = room, command = "AskForCardChosen", data = {[1] = {"target"}},
    players = {player}, send_success = {}, pending_requests = {},
    result = {}, default_reply = {}, timeout = 10, timestamp = 345,
    send_encode = true, receive_decode = true,
  }, { __index = methods })
end
local function denied(fn)
  local before = #owner.packets
  local success = pcall(fn)
  assert(not success and #owner.packets == before, "request bypassed v1 refusal")
  assert(protocol.activeBatch == nil, "failed request left active transaction")
end
local function finish(req)
  req:_finish()
  assert(req._cardWireRequests == nil, "request contexts must be destroyed")
end
local function issuedToken()
  local payload = owner.packets[#owner.packets].payload
  assert(type(payload) == "table" and type(payload.packed) == "table")
  local token = payload.packed[2][1]
  assert(type(token) == "string" and token:sub(1, 2) == "h:",
    "concealed canonical ID sent through request")
  return token
end

-- The actual Request:_sendPacket must only send a projected physical payload.
local good = request()
good:_sendPacket(player)
assert(#owner.packets == 1 and #spectator.packets == 0)
local token = issuedToken()
owner.reply = env.cbor.encode(token)
assert(good:_checkReply(player, false) == 501, "reply must resolve to canonical ID")
local sent = good._cardWireRequests[1]
local result, err = protocol:resolveChoice("aud:owner", sent.key, {token},
  function() return true end)
assert(result == nil and err == "unknown_or_expired_request", "replay accepted")
finish(good)

-- Request response translation must also bind public choices to one prompt.
-- A late reply carrying a canonical public ID or an old answer token fails.
projectPublic = true
owner.currentlyThinking = false
local publicOld = request()
publicOld:_sendPacket(player)
local publicOldToken = issuedToken()
owner.currentlyThinking = false
local publicNew = request()
publicNew:_sendPacket(player)
local publicNewToken = issuedToken()
assert(publicOldToken ~= publicNewToken,
  "two public requests for the same canonical card must have distinct answer tokens")
owner.reply = env.cbor.encode(publicOldToken)
denied(function() publicNew:_checkReply(player, false) end)
finish(publicNew)
owner.reply = env.cbor.encode(publicOldToken)
assert(publicOld:_checkReply(player, false) == 501,
  "original pending public token must resolve against its own request")
finish(publicOld)
owner.currentlyThinking = false
local publicRaw = request()
publicRaw:_sendPacket(player)
owner.reply = env.cbor.encode(501)
denied(function() publicRaw:_checkReply(player, false) end)
finish(publicRaw)
owner.currentlyThinking = false
local publicValid = request()
publicValid:_sendPacket(player)
owner.reply = env.cbor.encode(issuedToken())
assert(publicValid:_checkReply(player, false) == 501,
  "fresh public answer token must resolve to canonical ID")
finish(publicValid)
projectPublic = false

local function rejectedReply(reply)
  owner.currentlyThinking = false
  local req = request()
  req:_sendPacket(player)
  owner.reply = reply
  denied(function() req:_checkReply(player, false) end)
  finish(req)
end
rejectedReply(env.cbor.encode("h:forged-unissued-12345678"))
rejectedReply("invalid-cbor")

-- A forged physical controller cannot redeem even a valid request's token.
owner.currentlyThinking = false
local wrongController = request()
wrongController:_sendPacket(player)
local correctPhysical = wrongController._cardWireRequests[1].physical
wrongController._cardWireRequests[1].physical = spectator
owner.reply = env.cbor.encode(issuedToken())
denied(function() wrongController:_checkReply(player, false) end)
wrongController._cardWireRequests[1].physical = correctPhysical
finish(wrongController)

-- The first request may still be in flight when LuckCard requests a redraw.
-- A failed replacement must retain its allowlist; a successful one must
-- expire the old key even though _finish has not run yet.
owner.currentlyThinking = false
local redraw = request()
redraw:_sendPacket(player)
local previousToken = issuedToken()
local previousKey = redraw._cardWireRequests[1].key
owner.currentlyThinking = false
encodeFail = true
denied(function() redraw:_sendPacket(player) end)
encodeFail = false
assert(redraw._cardWireRequests[1].key == previousKey)
assert(protocol.audiences["aud:owner"].requests[previousKey],
  "failed replacement invalidated the active request")
-- A failure *after* the replacement refs were minted, during retirement of
-- the previous physical audience, must roll back BOTH changes. Historically
-- the old cleanup ran after commit and could leave a new live allowlist.
local previousPhysical = redraw._cardWireRequests[1].physical
redraw._cardWireRequests[1].physical = spectator
owner.currentlyThinking = false
denied(function() redraw:_sendPacket(player) end)
redraw._cardWireRequests[1].physical = previousPhysical
assert(redraw._cardWireRequests[1].key == previousKey,
  "failed audience cleanup replaced the existing request tracker")
local stagedRequests = protocol.audiences["aud:owner"].requests
assert(stagedRequests[previousKey], "failed cleanup retired the old reply")
for key in pairs(stagedRequests) do
  assert(key == previousKey, "failed cleanup published a partial new allowlist")
end
owner.currentlyThinking = false
redraw:_sendPacket(player)
local newToken = issuedToken()
assert(newToken ~= previousToken and redraw._cardWireRequests[1].key ~= previousKey)
local oldResult, oldError = protocol:resolveChoice("aud:owner", previousKey,
  {previousToken}, function() return true end)
assert(oldResult == nil and oldError == "unknown_or_expired_request",
  "replacement left the old request redeemable")
owner.reply = env.cbor.encode(newToken)
assert(redraw:_checkReply(player, false) == 501)
finish(redraw)

-- A selected card that has moved is no longer eligible even with its token.
owner.currentlyThinking = false
local changed = request()
changed:_sendPacket(player)
room.cardMoved = true
owner.reply = env.cbor.encode(issuedToken())
denied(function() changed:_checkReply(player, false) end)
room.cardMoved = false
finish(changed)

-- The timeout/cancel path must retire an unconsumed allowlist.
owner.currentlyThinking = false
local timeout = request()
timeout:_sendPacket(player)
local timeoutToken = issuedToken()
local timeoutKey = timeout._cardWireRequests[1].key
finish(timeout)
local forgotten = protocol:resolveChoice("aud:owner", timeoutKey,
  {timeoutToken}, function() return true end)
assert(forgotten == nil, "timed-out request was still redeemable")

-- No socket may see a packet if the projector or CBOR preflight fails.
owner.currentlyThinking = false
projectFail = true
denied(function() request():_sendPacket(player) end)
projectFail = false
projectNil = true
denied(function() request():_sendPacket(player) end)
projectNil = false
encodeFail = true
denied(function() request():_sendPacket(player) end)
encodeFail = false

-- V1 cannot downgrade: missing hooks, wrong mode/version are terminal.
local resolve = room.resolveCardWireRequestReply
room.resolveCardWireRequestReply = nil
denied(function() request():_sendPacket(player) end)
room.resolveCardWireRequestReply = resolve
local project = room.projectCardWireRequest
room.projectCardWireRequest = nil
denied(function() request():_sendPacket(player) end)
room.projectCardWireRequest = project
room.settings.gameMode = "another_mode"
denied(function() request():_sendPacket(player) end)
room.settings.gameMode = "new_heg_mode"
room.card_wire_version = 2
denied(function() request():_sendPacket(player) end)

-- Legacy wire still uses its original data and human reply semantics.
room.card_wire_version = nil
owner.currentlyThinking = false
local legacy = request()
legacy:_sendPacket(player)
local legacyPayload = owner.packets[#owner.packets].payload
assert(legacyPayload.packed[1] == "target")
owner.reply = env.cbor.encode(501)
assert(legacy:_checkReply(player, false) == 501)
finish(legacy)

print("PASS candidate Request source: per-physical projection, CBOR preflight, canonical reply, forged/replay/expired/invalid-CBOR rejection, wrong-physical rejection, atomic redraw replacement, timeout cleanup, no downgrade and legacy; synthetic-only; native/browser NOT RUN")
