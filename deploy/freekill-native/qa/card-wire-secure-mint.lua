-- Candidate native card-wire entropy source. The production Linux runtime
-- exposes the kernel CSPRNG through /dev/urandom. There is deliberately no
-- math.random, time seed, or deterministic fallback.
local Mint = {}
local bytesPerToken = 24 -- 192 unpredictable bits per opaque reference

function Mint.next()
  local reader, err = io.open("/dev/urandom", "rb")
  assert(reader, "card wire v1 requires OS CSPRNG: " .. (err and "unavailable" or "open failed"))
  local ok, bytes = pcall(reader.read, reader, bytesPerToken)
  local closed = reader:close()
  assert(ok and closed and type(bytes) == "string" and #bytes == bytesPerToken,
    "card wire v1 OS CSPRNG returned insufficient entropy")
  return "h:" .. bytes:gsub(".", function(byte)
    return string.format("%02x", string.byte(byte))
  end)
end

return Mint
