// Stage a native card-handle protocol and OS CSPRNG in the isolated candidate.
// The projector and client alias negotiation are still release gates; this
// intentionally NEVER enables card_wire_version.
// Usage: node scripts/upstream-first-card-wire-runtime-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput, 'expected --apply|--check <candidate-core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'native card-wire runtime is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const server = path.join(root, 'lua/server');
assert.equal(fs.realpathSync(server), server, 'candidate lua/server must not be a symlink');
const modules = [
  // The previous candidate used one-shot tokens for concealed answers but
  // canonical numeric IDs for public answers, allowing delayed public replay.
  // Only upgrade that byte-exact reviewed candidate; refuse unrelated edits.
  ['card_handle_protocol.lua', 'card-handle-protocol.lua', [
    '8d8b325c6b3955382192f6f84b312c90a2cee47637f196b5bca6c3a41946bec6',
    'aab9a68d266725fb3bbf85b712a24564f028c5e04a4e1e8b6ae5490b55787db2',
    // The first source-level fix was already staged in this isolated
    // candidate; allow that reviewed intermediate so the callback-compatible
    // public-metadata refinement can be applied atomically.
    'd5b2759843d812be70ec628d1025203f0fd9e3781ab5435397f956b720a22084',
  ]],
  ['card_wire_secure_mint.lua', 'card-wire-secure-mint.lua', null],
];
for (const [dest, source, previousSha256] of modules) {
  const target = path.join(server, dest);
  const expected = fs.readFileSync(path.join(repoRoot, 'deploy/freekill-native/qa', source), 'utf8');
  if (fs.existsSync(target)) {
    assert.equal(fs.realpathSync(target), target, 'candidate module must not be a symlink');
    const current = fs.readFileSync(target, 'utf8');
    if (current !== expected) {
      const currentHash = createHash('sha256').update(current).digest('hex');
    assert.ok(mode === '--apply' && previousSha256?.includes(currentHash),
        `candidate module differs from the reviewed version: ${dest}`);
      fs.writeFileSync(target, expected);
    }
  } else {
    assert.equal(mode, '--apply', `missing candidate module: ${dest}`);
    fs.writeFileSync(target, expected);
  }
}

const target = path.join(server, 'roombase.lua');
assert.equal(fs.realpathSync(target), target, 'candidate roombase must not be a symlink');
const marker = '\nfunction ServerRoomBase:handleChat(id, reqlist)\n';
const insertion = `
-- TQS_HEG_CARD_WIRE_MODULES: preload candidate modules while the core package
-- is still the current directory. The server scheduler later returns to the
-- runtime root, so deferred require() calls would otherwise miss lua/server
-- even though the files are present in the isolated package.
require "server.card_wire_secure_mint"
require "server.card_handle_protocol"
require "server.card_wire_projection"
require "server.card_wire_request"

-- TQS_HEG_CARD_WIRE_RUNTIME: CSPRNG-backed per-physical-audience state.
-- This seam is inert until explicit negotiated card_wire_version == 1.
-- A client-local card alias projector and request mapping are still required.
function ServerRoomBase:cardWireAudience(physical)
  assert(self.card_wire_version == 1 and
    self:getSettings("gameMode") == "new_heg_mode" and
    (type(physical) == "table" or type(physical) == "userdata"),
    "card wire audience requires a negotiated Hegemony physical connection")
  if not self._cardWireAudiences then
    self._cardWireAudiences = setmetatable({}, { __mode = "k" })
  end
  local id = self._cardWireAudiences[physical]
  if not id then
    id = require("server.card_wire_secure_mint").next()
    self._cardWireAudiences[physical] = id
  end
  return id
end

function ServerRoomBase:beginCardWireBatch()
  assert(self.card_wire_version == 1 and
    self:getSettings("gameMode") == "new_heg_mode",
    "card wire batch requires a negotiated Hegemony room")
  if not self._cardWireProtocol then
    local mint = require("server.card_wire_secure_mint")
    local protocol = require("server.card_handle_protocol")
    self._cardWireProtocol = protocol.new(mint.next)
  end
  return self._cardWireProtocol:beginBatch()
end
`;
let source = fs.readFileSync(target, 'utf8');
if (!source.includes(insertion)) {
  assert.equal(mode, '--apply', 'candidate room is missing the secure runtime methods');
  assert.equal(source.split(marker).length, 2, 'candidate room insertion anchor changed');
  source = source.replace(marker, `${insertion}${marker}`);
  fs.writeFileSync(target, source);
}
assert.equal(source.split(insertion).length, 2, 'card-wire runtime methods must appear once');

const freekill = path.join(root, 'lua/freekill.lua');
assert.equal(fs.realpathSync(freekill), freekill, 'candidate freekill.lua must not be a symlink');
const sandboxBefore = `    assert(not f:startsWith("/"), errmsg)
    assert(not f:startsWith(".."), errmsg)
    assert(not f:find(":"), errmsg)
`;
const sandboxInsertion = `    -- The candidate card-wire mint may read exactly the kernel CSPRNG stream.
    -- Keep every other absolute/parent/drive path rejected and require rb mode.
    local isCardWireEntropy = f == "/dev/urandom" and mode == "rb"
    if not isCardWireEntropy then
      assert(not f:startsWith("/"), errmsg)
      assert(not f:startsWith(".."), errmsg)
      assert(not f:find(":"), errmsg)
    end
`;
let freekillSource = fs.readFileSync(freekill, 'utf8');
if (!freekillSource.includes(sandboxInsertion)) {
  assert.equal(mode, '--apply', 'candidate freekill.lua is missing the guarded CSPRNG path');
  assert.equal(freekillSource.split(sandboxBefore).length, 2, 'candidate freekill.lua sandbox anchor changed');
  freekillSource = freekillSource.replace(sandboxBefore, sandboxInsertion);
  fs.writeFileSync(freekill, freekillSource);
}
assert.equal(freekillSource.split(sandboxInsertion).length, 2,
  'candidate freekill.lua must allow only the exact card-wire CSPRNG path');
console.log(`PASS isolated Hegemony secure card-wire runtime ${mode}: OS entropy + atomic batch; v1 disabled`);
