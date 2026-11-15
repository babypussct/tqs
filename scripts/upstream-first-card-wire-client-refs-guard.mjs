// Install the reviewed client-local card-wire identity primitive in the
// isolated candidate only. No v1 negotiation or production enablement here.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const sourceRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const candidate = process.argv[3];
const mode = process.argv[2];
assert.ok(mode === '--check' || mode === '--apply', 'expected --check or --apply');
assert.ok(candidate && candidate.includes('/candidate-runtime/packages/freekill-core'),
  'explicit isolated candidate core path required');

const moduleRel = 'ltk/client/card_wire_refs.lua';
const expectedModule = fs.readFileSync(path.join(sourceRoot,
  'deploy/freekill-native/qa/card-wire-client-refs.lua'), 'utf8');
const modulePath = path.join(candidate, moduleRel);
if (mode === '--apply' && !fs.existsSync(modulePath)) {
  fs.writeFileSync(modulePath, expectedModule);
}
assert.equal(fs.readFileSync(modulePath, 'utf8'), expectedModule,
  'client alias module drifted from reviewed source');

function ensure(rel, anchor, inserted) {
  const target = path.join(candidate, rel);
  const src = fs.readFileSync(target, 'utf8');
  if (src.includes(inserted)) return;
  assert.ok(mode === '--apply', `${rel} missing guarded client v1 source`);
  assert.ok(src.includes(anchor), `${rel} source anchor drifted`);
  assert.equal(src.split(anchor).length, 2, `${rel} source anchor ambiguous`);
  fs.writeFileSync(target, src.replace(anchor, inserted + anchor));
}

ensure('ltk/client/client.lua', '  self.clientplayer_klass = ClientPlayer',
  '  self.card_wire_refs = require("ltk.client.card_wire_refs").new(function(id)\n' +
  '    return Fk:getCardById(id) ~= nil or self.card_place[id] ~= nil\n' +
  '  end)\n\n');
const preload = '-- Load candidate card-wire modules while the client package root is still the\n' +
  '-- current directory. client.lua later returns to the game root before\n' +
  '-- CreateLuaClient runs, so deferred require() calls would otherwise miss\n' +
  '-- ltk/client/*.lua in Wasmoon even though the files are bundled.\n' +
  'require "ltk.client.card_wire_refs"\n' +
  'require "ltk.client.card_wire_negotiation"\n' +
  'require "ltk.client.card_wire_snapshots"\n' +
  'require "ltk.client.card_wire_public"\n' +
  'require "ltk.client.card_wire_requests"\n' +
  'require "ltk.client.card_wire_moves"\n' +
  'require "ltk.client.card_wire_area"\n' +
  'require "ltk.client.card_wire_deck"\n\n';
const preloadWithMetadata = preload.replace(
  'require "ltk.client.card_wire_deck"\n\n',
  'require "ltk.client.card_wire_deck"\nrequire "ltk.client.card_wire_metadata"\n\n');
const clientModulePath = path.join(candidate, 'ltk/client/client.lua');
const clientModuleSource = fs.readFileSync(clientModulePath, 'utf8');
if (!clientModuleSource.includes(preload) && !clientModuleSource.includes(preloadWithMetadata)) {
  assert.ok(mode === '--apply', 'ltk/client/client.lua missing guarded client v1 source');
  assert.ok(clientModuleSource.includes('local ClientBase = Fk.Base.ClientBase\n'),
    'ltk/client/client.lua source anchor drifted');
  assert.equal(clientModuleSource.split('local ClientBase = Fk.Base.ClientBase\n').length, 2,
    'ltk/client/client.lua source anchor ambiguous');
  fs.writeFileSync(clientModulePath, clientModuleSource.replace(
    'local ClientBase = Fk.Base.ClientBase\n', `${preload}local ClientBase = Fk.Base.ClientBase\n`));
}
ensure('ltk/core/player.lua', '  if not Fk:getCardById(cardId) then return true end',
  '  -- An opaque local alias has no Engine Card object. Treating missing cards\n' +
  '  -- as public would reveal concealed opponent cards on the UI.\n' +
  '  local wireRoom = Fk:currentRoom()\n' +
  '  if wireRoom and wireRoom.card_wire_refs and\n' +
  '      wireRoom.card_wire_refs:isHiddenLocal(cardId) then return false end\n');
console.log(`PASS isolated client alias source ${mode}`);
