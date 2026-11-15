// Keep the browser gameplay reply bridge on the reviewed Lua card-wire path.
// The bridge must preview the translated CBOR without consuming the one-shot
// request context, then send through ReplyToServer exactly once.
import assert from 'node:assert/strict';
import fs from 'node:fs';

const [mode, input] = process.argv.slice(2);
assert.equal(mode, '--check', 'usage: --check <hostLua.ts>');
assert.ok(input, 'hostLua.ts is required');

const source = fs.readFileSync(input, 'utf8');
assert.match(source, /function __web_reply\(data\)[\s\S]*?\n\s*ReplyToServer\(data\)/u,
  'browser replies must use ReplyToServer');
assert.doesNotMatch(source,
  /function __web_reply\(data\)[\s\S]*?__host_client:replyToServer\('',\s*cbor\.encode\(data\)\)/u,
  'browser replies must not bypass card-wire translation');
assert.match(source,
  /function __web_reply_hex\(data\)[\s\S]*?encodeReply\(ClientInstance,\s*data,\s*false\)/u,
  'browser reply preview must translate without consuming the request context');

console.log('PASS browser card-wire reply bridge: translated send, non-consuming CBOR preview and no direct bypass --check');
