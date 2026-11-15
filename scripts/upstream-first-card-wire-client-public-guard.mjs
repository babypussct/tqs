// Install the candidate-only client decoder for audited public card
// notifications. Legacy payloads remain untouched and v1 stays disabled.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'client public guard is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const modulePath = path.join(root, 'ltk/client/card_wire_public.lua');
const expected = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-client-public.lua'), 'utf8');
if (mode === '--apply' && (!fs.existsSync(modulePath) ||
    fs.readFileSync(modulePath, 'utf8') !== expected)) {
  fs.writeFileSync(modulePath, expected);
}
assert.equal(fs.readFileSync(modulePath, 'utf8'), expected,
  'candidate public client module drifted from reviewed source');

const target = path.join(root, 'lua/client/client.lua');
assert.equal(fs.realpathSync(target), target, 'candidate client callback must not be a symlink');
const snapshotBlock = [
  '  -- TQS_HEG_CARD_WIRE_CLIENT_SNAPSHOT: localize a complete physical',
  '  -- Reconnect/Observe snapshot before legacy Client/CardManager deserialize.',
  '  if self.card_wire_version == 1 and',
  '      (command == "Reconnect" or command == "Observe") and',
  '      type(data) == "table" and data.cardWireVersion == 1 then',
  '    data = require("ltk.client.card_wire_snapshots").receive(self, data)',
  '  end',
  '',
].join('\n');
const requestBlock = [
  '  -- TQS_HEG_CARD_WIRE_CLIENT_REQUEST: unwrap only an explicit v1 request',
  '  -- envelope. A missing/legacy payload is never silently interpreted as v1.',
  '  if self.card_wire_version == 1 and type(data) == "table" and',
  '      data.cardWireVersion == 1 then',
  '    data = require("ltk.client.card_wire_requests").receive(self, command, data)',
  '  end',
  '',
].join('\n');
const publicBlock = [
  '  -- TQS_HEG_CARD_WIRE_CLIENT_PUBLIC: reconstruct only audited public',
  '  -- card descriptors before the legacy ShowVirtualCard/GameLog callbacks.',
  '  if self.card_wire_version == 1 and',
  '      (command == "ShowVirtualCard" or command == "GameLog") and',
  '      type(data) == "table" and data.cardWireVersion == 1 then',
  '    data = require("ltk.client.card_wire_public").receive(self, command, data)',
  '  end',
  '',
].join('\n');
let source = fs.readFileSync(target, 'utf8');
if (!source.includes(publicBlock)) {
  assert.equal(mode, '--apply', 'candidate public callback bridge missing');
  assert.equal(source.split(snapshotBlock).length, 2,
    'snapshot callback bridge must be installed before public bridge');
  assert.equal(source.split(requestBlock).length, 2,
    'request callback bridge must be installed after public bridge');
  source = source.replace(requestBlock, publicBlock + requestBlock);
  fs.writeFileSync(target, source);
}
assert.equal(source.split(publicBlock).length, 2,
  'candidate public callback bridge must occur once');
console.log(`PASS isolated Hegemony client public bridge ${mode.slice(2)}: ` +
  'ShowVirtualCard/GameLog descriptor localization and legacy preservation; v1 disabled');
