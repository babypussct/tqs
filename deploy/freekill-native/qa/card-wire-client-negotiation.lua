-- Candidate-only client capability advertisement and v1 envelope validation.
--
-- The capability is a card-free PushRequest sent after ArrangeSeats and before
-- gameplay starts.  It is deliberately a fixed, auditable string: no card,
-- player, room or request identity crosses this boundary.  The server may
-- enable v1 only after every physical connection has advertised the same
-- capability.
local Negotiation = {}

local capability = "card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode"

local function encodeCapability()
  -- Native Room::handlePacket decodes PushRequest with its CBOR text-string
  -- callback. The default Lua encoder emits byte strings, so scope the same
  -- utf8string encoder used by the browser bridge to this card-free packet.
  local encoders = cbor.type_encoders
  assert(type(encoders) == "table" and type(encoders.string) == "function" and
    type(encoders.utf8string) == "function",
    "card wire capability requires the native CBOR text-string encoder")
  local previous = encoders.string
  encoders.string = encoders.utf8string
  local ok, payload = pcall(cbor.encode, capability)
  encoders.string = previous
  if not ok then error(payload) end
  return payload
end

local allowedFields = {
  protocol = true,
  cardWireVersion = true,
  mode = true,
}

function Negotiation.advertise(client, mode)
  assert(type(client) == "table", "card wire capability requires a client")
  if mode ~= "new_heg_mode" then return false end
  if client.card_wire_capability_sent then return true end
  assert(client.client and type(client.client.notifyServer) == "function",
    "card wire capability transport is missing")
  client.client:notifyServer("PushRequest", encodeCapability())
  client.card_wire_capability_sent = true
  return true
end

function Negotiation.receive(client, data)
  assert(type(data) == "table", "card wire negotiation must be a map")
  for key in pairs(data) do
    assert(allowedFields[key] == true,
      "card wire negotiation contains an unaudited field")
  end
  assert(data.protocol == "TQS_HEG_CARD_WIRE",
    "unsupported card wire negotiation protocol")
  assert(data.cardWireVersion == 1,
    "unsupported card wire negotiation version")
  assert(data.mode == "new_heg_mode",
    "card wire negotiation is restricted to Hegemony")
  assert(client.card_wire_version == nil or client.card_wire_version == 1,
    "card wire client cannot downgrade its negotiated version")

  client.card_wire_version = 1
  client.card_wire_protocol = data.protocol
  client.card_wire_negotiated = true
  return true
end

return Negotiation
