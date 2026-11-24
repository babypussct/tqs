package.path = package.path .. ';./lua/?.lua;./lua/lib/?.lua;./lua/?/init.lua'
local rpc = require 'server.rpc.jsonrpc'
local cbor = require 'server.rpc.cbor'
local out = io.stdout
out:write(cbor.encode(rpc.notification('hello', {'world'})))
out:write(cbor.encode({[100]='2.0',[104]=11,[105]={}}))
out:write(cbor.encode({[100]='2.0',[104]=12}))
out:write(cbor.encode({[100]='2.0',[104]=13,[103]={[200]=-32603,[201]='Internal error',[202]={nested={1,2,3}, empty={}}}}))
out:write(cbor.encode(rpc.request('print', {'one','two','three','four','five','six'}, 14)))
