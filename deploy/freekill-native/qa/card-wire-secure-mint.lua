-- Candidate native card-wire entropy source. The production Linux runtime
-- exposes the kernel CSPRNG through /dev/urandom. There is deliberately no
-- math.random, time seed, or deterministic fallback.
local Mint = {}
local bytesPerToken = 24 -- 192 unpredictable bits per opaque reference

-- This hook exists only for the isolated native QA runtime. It is configured
-- by the QA launcher, never by the production/current config, and deliberately
-- leaves the normal /dev/urandom read in the call path before changing the
-- result to one of the bounded failure shapes. That lets native QA exercise
-- the same fail-closed assertions without weakening the production entropy
-- source or adding a fallback.
local qaConfig = type(ServerConfig) == "table" and ServerConfig.tqsQa or nil
local failureAfter = qaConfig and qaConfig.cardWireEntropyFailureAfter or nil
local failureKind = qaConfig and qaConfig.cardWireEntropyFailureKind or "open"
if failureAfter ~= nil then
  assert(qaConfig.enabled == true and qaConfig.cardWireVersion == 1 and
    type(failureAfter) == "number" and failureAfter % 1 == 0 and
    failureAfter >= 0 and failureAfter <= 16,
    "invalid isolated card-wire entropy failure configuration")
  assert(failureKind == "open" or failureKind == "short-read" or failureKind == "close",
    "invalid isolated card-wire entropy failure kind")
end
local nextCalls = 0
local failureReported = false

local function rejectEntropy()
  if not failureReported and type(fk) == "table" and type(fk.qInfo) == "function" then
    fk.qInfo(string.format("[tqs_qa] card_wire_entropy_rejected mode=controlled kind=%s", failureKind))
    failureReported = true
  end
  error("card wire v1 requires OS CSPRNG: controlled QA failure", 2)
end

function Mint.next()
  nextCalls = nextCalls + 1
  local controlledFailure = failureAfter ~= nil and nextCalls > failureAfter
  local reader, err = io.open("/dev/urandom", "rb")
  if controlledFailure and failureKind == "open" then
    if reader then pcall(reader.close, reader) end
    reader, err = nil, "controlled QA failure"
  end
  if not reader then
    rejectEntropy()
  end
  local ok, bytes = pcall(reader.read, reader, bytesPerToken)
  local closed = reader:close()
  if controlledFailure and failureKind == "short-read" then
    bytes = "short"
  elseif controlledFailure and failureKind == "close" then
    closed = false
  end
  if not ok or not closed or type(bytes) ~= "string" or #bytes ~= bytesPerToken then
    rejectEntropy()
  end
  return "h:" .. bytes:gsub(".", function(byte)
    return string.format("%02x", string.byte(byte))
  end)
end

return Mint
