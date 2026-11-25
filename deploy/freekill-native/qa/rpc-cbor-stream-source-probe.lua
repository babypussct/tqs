-- Run against the promoted, isolated runtime's actual CBOR and stdio modules.
local root = assert((...), "promoted core root required")
local cbor = dofile(root .. "/lua/server/rpc/cbor.lua")
local function stream(bytes)
  local file = assert(io.tmpfile())
  assert(file:write(bytes))
  assert(file:seek("set"))
  return file
end

local file = stream("")
assert(cbor.decode_file(file) == nil)
file:close()

file = stream(cbor.encode({1, "probe"}) .. cbor.encode(42) .. cbor.encode(""))
local first = cbor.decode_file(file)
assert(first[1] == 1 and first[2] == "probe")
assert(cbor.decode_file(file) == 42)
assert(cbor.decode_file(file) == "")
assert(cbor.decode_file(file) == nil)
file:close()

for _, bytes in ipairs({"\x18", "\x82\x01", "\x63ab", "\x63", "\xa1\x01", "\x9f\x01"}) do
  file = stream(bytes)
  assert(not pcall(cbor.decode_file, file), "truncated CBOR must raise")
  file:close()
end
assert(not pcall(cbor.decode_file, {read = function() return nil, "probe failure" end}))

fk = {_rpc_finished = true}
local stdio = dofile(root .. "/lua/server/rpc/stdio.lua")
assert(stdio.stdin:read(0) == "")
assert(cbor.decode_file(stdio.stdin) == nil)
print("PASS RPC CBOR clean EOF, sequential objects, six truncated inputs, read failure and finished stdio")
