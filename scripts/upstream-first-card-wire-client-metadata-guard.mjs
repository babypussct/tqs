// Install the candidate-only client bridge for audited card metadata/AG
// notifications. Legacy payloads stay byte-compatible and the v1 protocol
// remains disabled unless the isolated QA negotiation explicitly opts in.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'client metadata guard is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const modulePath = path.join(root, 'ltk/client/card_wire_metadata.lua');
const expected = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-client-metadata.lua'), 'utf8');
const reviewedPriorRevisions = new Set([
  'c930cdaf7a4144992803b48a684b8fbc6826e7b487ad802c3213d566eeba8e0b',
]);
assert.equal(fs.realpathSync(path.dirname(modulePath)), path.dirname(modulePath),
  'client metadata directory must not be a symlink');
if (!fs.existsSync(modulePath)) {
  assert.equal(mode, '--apply', 'candidate metadata module missing');
  fs.writeFileSync(modulePath, expected);
}
assert.equal(fs.realpathSync(modulePath), modulePath,
  'candidate metadata module must not be a symlink');
const installedMetadata = fs.readFileSync(modulePath, 'utf8');
if (installedMetadata !== expected) {
  assert.equal(mode, '--apply', 'candidate metadata module drifted');
  assert.ok(reviewedPriorRevisions.has(createHash('sha256').update(installedMetadata).digest('hex')),
    'candidate metadata module differs from reviewed previous revisions');
  fs.writeFileSync(modulePath, expected);
}
assert.equal(fs.readFileSync(modulePath, 'utf8'), expected,
  'candidate metadata module drifted from reviewed source');

const clientRoot = path.join(root, 'ltk/client');
const clientModule = path.join(clientRoot, 'client.lua');
assert.equal(fs.realpathSync(clientModule), clientModule,
  'candidate LTK client must not be a symlink');
const preload = 'require "ltk.client.card_wire_metadata"';
let ltkClient = fs.readFileSync(clientModule, 'utf8');
if (!ltkClient.includes(preload)) {
  assert.equal(mode, '--apply', 'candidate metadata module is not preloaded');
  const anchor = 'require "ltk.client.card_wire_deck"\n';
  assert.equal(ltkClient.split(anchor).length, 2,
    'candidate client preload anchor drifted');
  ltkClient = ltkClient.replace(anchor, `${anchor}${preload}\n`);
  fs.writeFileSync(clientModule, ltkClient);
}
assert.equal(ltkClient.split(preload).length, 2,
  'candidate metadata module preload must occur once');

const callbackPath = path.join(root, 'lua/client/client.lua');
assert.equal(fs.realpathSync(callbackPath), callbackPath,
  'candidate ClientCallback must not be a symlink');
const bridge = `  -- TQS_HEG_CARD_WIRE_CLIENT_METADATA: localize audited card metadata/AG
  -- envelopes before legacy callbacks or the UI see physical references.
  if self.card_wire_version == 1 and
      (command == "SetCardFootnote" or command == "SetCardVirtName" or
       command == "FilterCard" or command == "SetPlayerHandCards" or
       command == "AddVirtualEquip" or command == "RemoveVirtualEquip" or
       command == "FillAG" or command == "TakeAG") then
    assert(type(data) == "table" and data.cardWireVersion == 1,
      "v1 card metadata/AG requires an explicit envelope")
    local localized, deliver = require("ltk.client.card_wire_metadata").receive(
      self, command, data)
    if not deliver then return end
    data = localized
  end

`;
let callback = fs.readFileSync(callbackPath, 'utf8');
const legacyBridge = `  -- TQS_HEG_CARD_WIRE_CLIENT_METADATA: localize audited card metadata
  -- envelopes before legacy callbacks or the UI see physical references.
  if self.card_wire_version == 1 and
      (command == "SetCardFootnote" or command == "SetCardVirtName" or
       command == "FilterCard" or command == "SetPlayerHandCards" or
       command == "AddVirtualEquip" or command == "RemoveVirtualEquip") then
    assert(type(data) == "table" and data.cardWireVersion == 1,
      "v1 card metadata requires an explicit envelope")
    local localized, deliver = require("ltk.client.card_wire_metadata").receive(
      self, command, data)
    if not deliver then return end
    data = localized
  end

`;
if (callback.includes(legacyBridge)) {
  assert.equal(mode, '--apply', 'candidate metadata callback has a reviewed legacy bridge');
  callback = callback.replace(legacyBridge, '');
  fs.writeFileSync(callbackPath, callback);
}
const requestAnchor = '  -- TQS_HEG_CARD_WIRE_CLIENT_REQUEST: unwrap only an explicit v1 request\n';
const bridgeBeforeRequest = callback.indexOf(bridge) >= 0 &&
  callback.indexOf(bridge) < callback.indexOf(requestAnchor);
if (!bridgeBeforeRequest) {
  assert.equal(mode, '--apply', 'candidate metadata callback bridge missing');
  if (callback.includes(bridge)) callback = callback.replace(bridge, '');
  assert.equal(callback.split(requestAnchor).length, 2,
    'candidate ClientCallback metadata anchor drifted');
  callback = callback.replace(requestAnchor, bridge + requestAnchor);
  fs.writeFileSync(callbackPath, callback);
}
assert.equal(callback.split(bridge).length, 2,
  'candidate metadata callback bridge must occur once');
assert.equal(callback.indexOf(bridge) < callback.indexOf(requestAnchor), true,
  'candidate metadata bridge must run before the generic request envelope');

console.log(`PASS isolated Hegemony client metadata bridge ${mode.slice(2)}: ` +
  'per-physical card metadata localization and legacy preservation; v1 disabled');
