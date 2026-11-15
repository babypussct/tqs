// Install the candidate-only client decoder for projected Reconnect/Observe
// snapshots. Legacy payloads remain untouched and card_wire_version is never
// negotiated by this guard.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'client snapshot guard is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const modulePath = path.join(root, 'ltk/client/card_wire_snapshots.lua');
assert.equal(fs.realpathSync(path.dirname(modulePath)), path.dirname(modulePath));
if (fs.existsSync(modulePath)) assert.equal(fs.realpathSync(modulePath), modulePath,
  'snapshot module must not be a symlink');
const expected = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-client-snapshots.lua'), 'utf8');
if (mode === '--apply' && (!fs.existsSync(modulePath) ||
    fs.readFileSync(modulePath, 'utf8') !== expected)) {
  fs.writeFileSync(modulePath, expected);
}
assert.equal(fs.readFileSync(modulePath, 'utf8'), expected,
  'candidate snapshot module drifted from reviewed source');

const target = path.join(root, 'lua/client/client.lua');
assert.equal(fs.realpathSync(target), target, 'candidate client callback must not be a symlink');
const requestBlock = [
  '  -- TQS_HEG_CARD_WIRE_CLIENT_REQUEST: unwrap only an explicit v1 request',
  '  -- envelope. A missing/legacy payload is never silently interpreted as v1.',
  '  if self.card_wire_version == 1 and type(data) == "table" and',
  '      data.cardWireVersion == 1 then',
  '    data = require("ltk.client.card_wire_requests").receive(self, command, data)',
  '  end',
  '',
].join('\n');
const previousSnapshotBlock = [
  '  -- TQS_HEG_CARD_WIRE_CLIENT_SNAPSHOT: localize a complete physical',
  '  -- Reconnect/Observe snapshot before legacy Client/CardManager deserialize.',
  '  if self.card_wire_version == 1 and',
  '      (command == "Reconnect" or command == "Observe") and',
  '      type(data) == "table" and data.cardWireVersion == 1 then',
  '    data = require("ltk.client.card_wire_snapshots").receive(self, data)',
  '  end',
  '',
].join('\n');
const snapshotBlock = previousSnapshotBlock
  .replace('  if self.card_wire_version == 1 and', '  local cardWireSnapshot = false\n  if self.card_wire_version == 1 and')
  .replace('    data = require("ltk.client.card_wire_snapshots").receive(self, data)',
    '    data = require("ltk.client.card_wire_snapshots").receive(self, data)\n    cardWireSnapshot = true');
let source = fs.readFileSync(target, 'utf8');
if (!source.includes(snapshotBlock) && source.includes(previousSnapshotBlock)) {
  assert.equal(mode, '--apply', 'candidate lacks cold snapshot dispatch');
  source = source.replace(previousSnapshotBlock, snapshotBlock);
}
if (!source.includes(snapshotBlock)) {
  assert.equal(mode, '--apply', 'candidate snapshot callback bridge missing');
  assert.equal(source.split(requestBlock).length, 2,
    'request callback bridge must be installed before snapshot bridge');
  source = source.replace(requestBlock, snapshotBlock + requestBlock);
}
const callbackBefore = '    cb(self, data)';
const callbackAfter = `    if cardWireSnapshot then
      require("ltk.client.card_wire_snapshots").dispatch(self, cb, data)
    else
      cb(self, data)
    end`;
if (!source.includes(callbackAfter)) {
  assert.equal(mode, '--apply', 'snapshot callback must preserve rebuilt identity state');
  assert.equal(source.split(callbackBefore).length, 2, 'snapshot callback anchor drifted');
  source = source.replace(callbackBefore, callbackAfter);
}
if (mode === '--apply') fs.writeFileSync(target, source);
assert.equal(source.split(snapshotBlock).length, 2,
  'candidate snapshot callback bridge must occur once');

const basePath = path.join(root, 'lua/client/clientbase.lua');
assert.equal(fs.realpathSync(basePath), basePath, 'client base must not be a symlink');
let base = fs.readFileSync(basePath, 'utf8');
const methodStart = base.indexOf('function ClientBase:enterRoom(_data)\n');
assert.ok(methodStart >= 0, 'enterRoom anchor missing');
const methodEnd = base.indexOf('\nend\n', methodStart) + 5;
assert.ok(methodEnd > methodStart, 'enterRoom end missing');
let method = base.slice(methodStart, methodEnd);
const capture = `  local cardWireSnapshot = self._card_wire_snapshot
  self._card_wire_snapshot = nil
`;
const transfer = `  if cardWireSnapshot then
    assert(data.gameMode == "new_heg_mode" and cardWireSnapshot.refs,
      "snapshot state requires the validated Hegemony room")
    self.card_wire_version = 1
    self.card_wire_protocol = cardWireSnapshot.protocol
    self.card_wire_negotiated = true
    self.card_wire_refs = cardWireSnapshot.refs
  end
`;
if (!method.includes(capture) || !method.includes(transfer)) {
  assert.equal(mode, '--apply', 'enterRoom must retain only validated snapshot identity state');
  assert.ok(!method.includes(capture) && !method.includes(transfer), 'partial snapshot state transfer');
  method = method.replace('  local data = _data[3]\n', capture + '  local data = _data[3]\n');
  assert.equal(method.split('  self = ClientInstance\n').length, 2);
  method = method.replace('  self = ClientInstance\n', '  self = ClientInstance\n' + transfer);
  base = base.slice(0, methodStart) + method + base.slice(methodEnd);
  fs.writeFileSync(basePath, base);
}
// An older candidate hand-off in the LTK override preserved v1 on every room
// entry. Restrict it to the explicit snapshot callback capability too.
const ltkPath = path.join(root, 'ltk/client/client.lua');
assert.equal(fs.realpathSync(ltkPath), ltkPath);
let ltk = fs.readFileSync(ltkPath, 'utf8');
const oldCapture = 'function Client:enterRoom(data)\n  local cardWireVersion = self.card_wire_version';
const newCapture = 'function Client:enterRoom(data)\n  local cardWireVersion = self._card_wire_snapshot and self.card_wire_version';
if (!ltk.includes(newCapture) && ltk.includes('function Client:enterRoom(data)')) {
  assert.equal(mode, '--apply', 'LTK room hand-off must be scoped to snapshot restoration');
  assert.equal(ltk.split(oldCapture).length, 2, 'LTK snapshot hand-off drifted');
  ltk = ltk.replace(oldCapture, newCapture);
  fs.writeFileSync(ltkPath, ltk);
}
console.log(`PASS isolated Hegemony client snapshot bridge ${mode.slice(2)}: ` +
  'Reconnect/Observe envelope localization, count-only deck and legacy preservation; v1 disabled');
