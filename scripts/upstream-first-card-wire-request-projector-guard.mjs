// Install the candidate-only physical request projector/reply resolver.
// This never enables card_wire_version and is restricted to the isolated
// source snapshot. Usage: --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { updateRequestVisibility } from '../deploy/freekill-native/scripts/card-wire-request-runtime.mjs';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /(?:\/scratch\/evidence\/[^/]+\/candidate-runtime|\/private\/tmp\/tqs-cardwire-qa-20261103-[^/]+)\/packages\/freekill-core$/u,
  'request projector is restricted to the isolated candidate');
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
updateRequestVisibility(root, mode);

const moduleRel = 'lua/server/card_wire_request.lua';
const moduleTarget = path.join(root, moduleRel);
const moduleExpected = fs.readFileSync(
  path.join(repoRoot, 'deploy/freekill-native/qa/card-wire-request.lua'), 'utf8');
if (mode === '--apply' && (!fs.existsSync(moduleTarget) ||
    fs.readFileSync(moduleTarget, 'utf8') !== moduleExpected)) {
  fs.writeFileSync(moduleTarget, moduleExpected);
}
assert.equal(fs.readFileSync(moduleTarget, 'utf8'), moduleExpected,
  'candidate request projector drifted from reviewed source');

const target = path.join(root, 'lua/server/roombase.lua');
assert.equal(fs.realpathSync(target), target, 'candidate roombase must not be a symlink');
const marker = '\nfunction ServerRoomBase:handleChat(id, reqlist)\n';
const insertion = `
-- TQS_HEG_CARD_WIRE_REQUEST_PROJECTOR: request-scoped opaque choices for
-- AskForCardChosen/Poxi/use-card flows.  This is candidate-only and remains
-- inert until the negotiated Hegemony v1 path calls it.
function ServerRoomBase:projectCardWireRequest(seat, physical, command, data, batch, requestKey)
  return require("server.card_wire_request").project(
    self, seat, physical, command, data, batch, requestKey)
end

function ServerRoomBase:resolveCardWireRequestReply(seat, physical, command, reply, requestKey, originalData)
  return require("server.card_wire_request").resolve(
    self, seat, physical, command, reply, requestKey, originalData)
end
`;
let source = fs.readFileSync(target, 'utf8');
if (!source.includes(insertion)) {
  assert.equal(mode, '--apply', 'candidate room is missing request projector methods');
  assert.equal(source.split(marker).length, 2, 'candidate request projector anchor changed');
  source = source.replace(marker, `${insertion}${marker}`);
  fs.writeFileSync(target, source);
}
assert.equal(source.split(insertion).length, 2,
  'candidate request projector methods must appear once');
console.log(`PASS isolated Hegemony request projector ${mode.slice(2)}: opaque choice envelope, fail-closed card reply resolver; v1 disabled`);
