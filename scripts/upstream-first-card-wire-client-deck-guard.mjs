// Candidate-only count-based client deck callbacks. V1 stays disabled until
// the remaining card identity and request/reconnect paths are implemented.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'expected --apply|--check <isolated-candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'client deck guard restricted to isolated candidate');
const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const expected = fs.readFileSync(path.join(repo,
  'deploy/freekill-native/qa/card-wire-client-deck.lua'), 'utf8');
const moduleDir = path.join(root, 'ltk/client');
assert.equal(fs.realpathSync(moduleDir), moduleDir, 'client directory must not be a symlink');
const modulePath = path.join(moduleDir, 'card_wire_deck.lua');
if (fs.existsSync(modulePath)) {
  assert.equal(fs.realpathSync(modulePath), modulePath, 'deck module must not be a symlink');
  assert.equal(fs.readFileSync(modulePath, 'utf8'), expected,
    'installed deck module differs from reviewed source');
} else {
  assert.equal(mode, '--apply', 'candidate deck module missing');
  fs.writeFileSync(modulePath, expected);
}

const clientPath = path.join(moduleDir, 'client.lua');
assert.equal(fs.realpathSync(clientPath), clientPath, 'client must not be a symlink');
let client = fs.readFileSync(clientPath, 'utf8');
function insert(anchor, replacement) {
  if (client.includes(replacement)) return;
  assert.equal(mode, '--apply', `candidate is missing ${anchor}`);
  assert.equal(client.split(anchor).length, 2, `source anchor drifted: ${anchor}`);
  client = client.replace(anchor, replacement);
}
insert('  self:addCallback("PrepareDrawPile", self.prepareDrawPile)',
  '  self:addCallback("PrepareDrawPile", self.prepareWireDrawPile)');
insert('function Client:handleShuffleDrawPile(data)\n',
  'function Client:prepareWireDrawPile(data)\n' +
  '  if self.card_wire_version == 1 or (type(data) == "table" and data.count ~= nil) then\n' +
  '    return require("ltk.client.card_wire_deck").receive(self, "PrepareDrawPile", data)\n' +
  '  end\n' +
  '  return self:prepareDrawPile(data)\n' +
  'end\n\nfunction Client:handleShuffleDrawPile(data)\n' +
  '  if self.card_wire_version == 1 or (type(data) == "table" and data.count ~= nil) then\n' +
  '    require("ltk.client.card_wire_deck").receive(self, "ShuffleDrawPile", data)\n' +
  '    self:appendLog { type = "$ShuffleDrawPile", arg = #self.draw_pile }\n' +
  '    return\n' +
  '  end\n');
insert('function Client:syncDrawPile(data)\n',
  'function Client:syncDrawPile(data)\n' +
  '  if self.card_wire_version == 1 or (type(data) == "table" and data.count ~= nil) then\n' +
  '    return require("ltk.client.card_wire_deck").receive(self, "SyncDrawPile", data)\n' +
  '  end\n');
if (mode === '--apply') fs.writeFileSync(clientPath, client);
assert.match(client, /self:addCallback\("PrepareDrawPile", self\.prepareWireDrawPile\)/u);
assert.match(client, /function Client:prepareWireDrawPile\(data\)/u);
assert.match(client, /receive\(self, "ShuffleDrawPile", data\)/u);
assert.match(client, /receive\(self, "SyncDrawPile", data\)/u);
console.log(`PASS isolated count-only client deck ${mode}; v1 remains disabled`);
