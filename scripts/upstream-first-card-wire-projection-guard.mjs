// Install the audited, fail-closed projector exclusively in the isolated core.
// It does not turn on card_wire_version. Usage: --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'expected --apply|--check <candidate-core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /(?:\/scratch\/evidence\/[^/]+\/candidate-runtime|\/private\/tmp\/tqs-cardwire-qa-20261103-[^/]+)\/packages\/freekill-core$/u,
  'card-wire projector restricted to isolated candidate');
const serverRoot = path.join(root, 'lua/server');
assert.equal(fs.realpathSync(serverRoot), serverRoot, 'lua/server must not be a symlink');
const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const expected = fs.readFileSync(path.join(repository,
  'deploy/freekill-native/qa/card-wire-projection.lua'), 'utf8');
const target = path.join(serverRoot, 'card_wire_projection.lua');
if (fs.existsSync(target)) {
  assert.equal(fs.realpathSync(target), target, 'target projector must not be a symlink');
  const installed = fs.readFileSync(target, 'utf8');
  if (installed !== expected) {
    assert.equal(mode, '--apply', 'candidate projector drifted');
    const reviewedPriorRevisions = new Set([
      // The pinned package installer stages this earlier projector before
      // the reviewed native QA overlay updates are applied.
      '25e37d27d00038cb509ded1125632fee43ca8a21b7526d92f07b3703cfa37118',
      '4aab403222c7f3d3a1de4ad31fe1f390028f9cf490726c96da653719d9aa62c3',
      'd9119a2b63fdc9f9f8d706373131d50a7c58e45bf8cef90b75bc1ce0214c1af5',
      // Public descriptors/logs must preserve the source handle until MoveCards.
      'b3697a3c9f727cb1e71bc2a63aae77ad65c1d02ca2768e4567859371fbdb29bc',
      '3d0d628cb2eff7b2256204e8ed0116100d079311d113b1ec8949dfd5258f8b8b',
      '5172c810aec80078e48c4bb423b8ab5546f0cb4c28e1311d9e43abd90b2aa907',
      '4890b6e4c69c3822761e5d6db023acc775ac9611d7f1e690b71a667ee8335175',
      '23b506a75c8eb8afc32b213920463a4836935f9e25846aa0d00a7749385e8934',
      'f8ad20a4ae6f132b38f1fb63e1f46533f24406faf198c95d36111b63350c9835',
      'b5dd2715289d2fee18184ef105edc3d7b7b744806de6857860f909e7f37b8bbd',
      '69ec39d9b9b57567ae728dc7929bf651c0fabe56ec7b8f6ee9d904a0390c7888',
      '3375f4eb76a507b369f36192668c91218c1b6ea3f78c2acbf6ca4fc4dbee8e30',
      '3214cd2da9082839d9b9733897a05e34493a72a8eb84e2bf139ccfb7767b72b2',
      '2561b1666c354ae93d34ca14ee154cae94bdf055ea991f9af72330b06f12e727',
      '0efa1c6f2a5fa59827544b21ef7cddf2ea4fe9a80c12259e9e56ef335c8cba84',
      '1fc0de0e3e15772b6f9fa4a75dc7df2b410c82c8dd9d4c540248f73aafc562b8',
      '2e164f8b135ab5b77778e5064d61661c37e54e708b90164968ed664a7eeb1350',
      '90fbe3d016e24af8b4af82a5dad8980d19c11a08d335f81c975b41b12ced4c7f',
      '751b1b86f384648aeb400c37edd300041310d3d94a57c9208944e365a7a7ad94',
      'b41f786311df2b750d494abf859b08ffb795c77df24b1960e472ed68540813e4',
      '3c946677942c6934f188f9f32f6f82a91d0500f01ce3d7038e189a548034f1d3',
      '4dafa6cebdf5b51e24ec71b8d6ea0314a77e27818c1cd0792f89e73ae776f65c',
      '3f497a2ea5c004f7484b357e98b7a2eb99331629b624c0f0d94abc3c8f428d85',
      '744632b01d0d428c368f464e04d69a3846a05ac53e03d733aebc6c8e4e44258d',
      // Candidate baseline from the last native/source checkpoint; the only
      // delta against the audited projector is the public card-mark standing
      // reference transition applied by this guard.
      'd4a7bbc9ce03da64dda6ad5f1cd9908bddbdf99ae30fb872ebdae6ddf600a338',
      // Candidate baseline after the standing-reference transition; this
      // delta admits the real string-only Luanji turn mark explicitly.
      '5160279749fa14c9c1ec8ae5dfc1bcbcd7338c13d4f1d627a5587e02dd5e1dd1',
      // Candidate baseline after the Yigui/lifecycle source merge; it is
      // replaced by the exact reviewed projector below.
      '061ed5c4ec16840048e299bf4fd5b8effdfdf7488fcdf9df5bee666d03699350',
      // Projector shipped in the native v1 candidate dd390ea8.
      'ae7b4de425c34d50e5cafa233e33eec5d58ffa24ff40270a0040559122efe1d3',
      'ec4410704892385bb151bfc5781ea0f24a798c00f606ea0e2a3890ece1392dfe',
    ]);
    assert.ok(reviewedPriorRevisions.has(createHash('sha256').update(installed).digest('hex')),
      'candidate projector differs from reviewed previous revisions');
    fs.writeFileSync(target, expected);
  }
} else {
  assert.equal(mode, '--apply', 'candidate projector missing');
  fs.writeFileSync(target, expected);
}

const roomPath = path.join(serverRoot, 'roombase.lua');
assert.equal(fs.realpathSync(roomPath), roomPath, 'room target must not be a symlink');
const anchor = '\nfunction ServerRoomBase:handleChat(id, reqlist)\n';
const body = `
-- TQS_HEG_CARD_WIRE_PROJECTION: candidate-only, audited command subset.
-- V1 remains OFF until all client/server paths are implemented.
function ServerRoomBase:projectCardWire(seat, physical, command, data, batch)
  return require("server.card_wire_projection").project(
    self, seat, physical, command, data, batch)
end
`;
let source = fs.readFileSync(roomPath, 'utf8');
if (!source.includes(body)) {
  assert.equal(mode, '--apply', 'candidate room projector not installed');
  assert.equal(source.split(anchor).length, 2, 'candidate room anchor drifted');
  source = source.replace(anchor, `${body}${anchor}`);
  fs.writeFileSync(roomPath, source);
}
assert.equal(source.split(body).length, 2, 'candidate room projector must occur once');
console.log(`PASS isolated card-wire projector ${mode}; audited subset, v1 remains disabled`);
