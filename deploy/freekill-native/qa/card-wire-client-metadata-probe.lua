-- Exercise the candidate ClientCallback and card metadata decoder with the
-- actual candidate CBOR codec. Native C++/browser/two-account acceptance is
-- still a separate gate.
local coreRoot = assert(arg[1], "candidate core root required")
package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" ..
  coreRoot .. "/lua/?.lua;" .. coreRoot .. "/lua/?/init.lua;" .. package.path
function string.startsWith(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function read(path)
  local file = assert(io.open(path, "rb"))
  local source = assert(file:read("*a"))
  file:close()
  return source
end

cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))
local Refs = assert(dofile(coreRoot .. "/ltk/client/card_wire_refs.lua"))

local owner = { id = 11, name = "owner" }
local opponent = { id = 12, name = "opponent" }
local players = { [11] = owner, [12] = opponent }
local client = {
  card_wire_version = 1,
  card_wire_protocol = "TQS_HEG_CARD_WIRE",
  card_wire_refs = Refs.new(),
  callbacks = {},
  recording = false,
  replaying = false,
  notifications = {},
  received = {},
}
function client:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
end
function client:getPlayerById(id) return players[id] end
function client:notifyUI(command, data)
  self.notifications[#self.notifications + 1] = { command, data }
end

for _, command in ipairs({ "SetCardFootnote", "FilterCard", "AddVirtualEquip",
    "RemoveVirtualEquip", "FillAG", "TakeAG" }) do
  client.callbacks[command] = function(self, data)
    self.received[command] = data
  end
end

local clientEnv
local function dispatch(command, payload)
  client.received[command] = nil
  client.notifications = {}
  local wire = cbor.encode(payload)
  clientEnv.ClientCallback(nil, command, wire, false)
  return client.received[command], client.notifications
end

local clientTable = setmetatable({
  contains = function(values, wanted)
    for _, value in ipairs(values) do
      if value == wanted then return true end
    end
    return false
  end,
}, { __index = table })

Fk = { currentResponsePattern = "stale", currentResponseReason = "stale" }
clientEnv = setmetatable({
  ClientInstance = client,
  Fk = Fk,
  cbor = cbor,
  fk = { client_callback = {} },
  table = clientTable,
  require = require,
  pattern_refresh_commands = {
    "PlayCard", "AskForUseActiveSkill", "AskForUseCard", "AskForResponseCard",
  },
  no_decode_commands = {
    "ErrorMsg", "ErrorDlg", "Heartbeat", "ServerMessage",
    "UpdateAvatar", "UpdatePassword",
  },
}, { __index = _G })
local clientSource = read(coreRoot .. "/lua/client/client.lua")
local clientStart = assert(clientSource:find("ClientCallback = function", 1, true))
local clientMarker = "\nend\n\n-- Create ClientInstance"
local clientEnd = assert(clientSource:find(clientMarker, clientStart, true))
assert(load(clientSource:sub(clientStart, clientEnd + 4),
  "=candidate/metadata/client-callback", "t", clientEnv))()

local hiddenToken = "h:" .. string.rep("a", 32)
local envelope = function(payload)
  return { cardWireVersion = 1, payload = payload }
end

local footnote = dispatch("SetCardFootnote", envelope({
  { hiddenToken, 103 }, { type = "##Probe", from = 11, arg = "reason" }, false,
}))
assert(footnote[1][1] >= 1000000000 and footnote[1][2] == 103 and
  footnote[2].from == 11 and footnote[2].arg == "reason")

local virtName, virtNotifications = dispatch("SetCardVirtName", envelope({
  { hiddenToken, 7001 }, "slash", false,
}))
assert(#virtNotifications == 1 and virtNotifications[1][1] == "SetCardVirtName")
virtName = virtNotifications[1][2]
assert(virtName[1][1] == footnote[1][1] and virtName[1][2] == 7001 and
  virtName[2] == "slash" and virtName[3] == false)

local filter = dispatch("FilterCard", envelope({ hiddenToken, 11, false }))
assert(filter[1] == footnote[1][1] and filter[2] == owner and filter[3] == false)
local skipped = dispatch("FilterCard", envelope({ -1, nil, false }))
assert(skipped == nil and #client.notifications == 0 and client.received.FilterCard == nil,
  "hidden draw FilterCard must be a client no-op")

local hand, handNotifications = dispatch("SetPlayerHandCards", envelope({
  11, { hiddenToken, 103 },
}))
assert(#handNotifications == 1 and handNotifications[1][1] == "SetPlayerHandCards")
hand = handNotifications[1][2]
assert(hand[1] == 11 and hand[2][1] == footnote[1][1] and hand[2][2] == 103)

local equip = dispatch("AddVirtualEquip", envelope({
  player = 11, name = "probe_equip", subcards = { hiddenToken, 103 },
}))
assert(equip.player == 11 and equip.name == "probe_equip" and
  equip.subcards[1] == footnote[1][1] and equip.subcards[2] == 103)
local removed = dispatch("RemoveVirtualEquip", envelope({
  player = 11, id = hiddenToken,
}))
assert(removed.player == 11 and removed.id == footnote[1][1])

local ag = dispatch("FillAG", envelope({
  { hiddenToken, 103 }, { 103 },
}))
assert(ag[1][1] == footnote[1][1] and ag[1][2] == 103 and
  ag[2][1] == 103)
local taken = dispatch("TakeAG", envelope({ 12, hiddenToken }))
assert(taken[1] == 12 and taken[2] == footnote[1][1])

local malformed = cbor.encode({ cardWireVersion = 1, payload = { {103},
  { type = "##Probe", arg = "reason" }, false, extra = 1 } })
assert(not pcall(function()
  clientEnv.ClientCallback(nil, "SetCardFootnote", malformed, false)
end), "metadata decoder must reject extra payload fields")
assert(not pcall(function()
  clientEnv.ClientCallback(nil, "SetCardVirtName", cbor.encode({ {103}, "slash", false }), false)
end), "v1 metadata must reject a legacy unwrapped payload")

client.card_wire_version = nil
local legacy = { {103}, { type = "##Probe", from = 11, arg = "reason" }, false }
local legacyReceived = dispatch("SetCardFootnote", legacy)
assert(legacyReceived[1][1] == 103 and legacyReceived[2].from == 11 and
  legacyReceived[2].arg == "reason",
  "legacy metadata callback must remain byte-compatible")

print("PASS candidate card metadata client: actual ClientCallback envelope " ..
  "localization, AG refs, owner/player mapping, virtual IDs, hidden draw no-op, " ..
  "schema/legacy fail-close; 11 cases; synthetic-only; native/browser NOT RUN")
