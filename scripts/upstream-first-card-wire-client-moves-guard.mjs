// Install the reviewed v1 MoveCards/SetPlayerPile client bridge in the
// isolated candidate only. Legacy callbacks remain byte-compatible and v1
// negotiation stays disabled.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, candidate] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && candidate,
  'expected --apply|--check <isolated candidate core>');
const root = fs.realpathSync(candidate);
assert.match(root, /(?:\/scratch\/evidence\/[^/]+|\/private\/tmp\/tqs-cardwire-qa-20261103-[^/]+)\/candidate-runtime\/packages\/freekill-core$/u,
  'client MoveCards bridge restricted to isolated candidate');
const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const moduleRel = 'ltk/client/card_wire_moves.lua';
const expectedModule = fs.readFileSync(path.join(repository,
  'deploy/freekill-native/qa/card-wire-client-moves.lua'), 'utf8');
const modulePath = path.join(root, moduleRel);
if (!fs.existsSync(modulePath)) {
  assert.equal(mode, '--apply', 'candidate client MoveCards module missing');
  fs.writeFileSync(modulePath, expectedModule);
} else if (fs.readFileSync(modulePath, 'utf8') !== expectedModule) {
  assert.equal(mode, '--apply', 'candidate client MoveCards module drifted');
  const reviewedPriorRevisions = new Set([
    '87c85425074c010d1bd15c4ab31f55a0f317034e082a9050763a7413e0cdf7d7',
    '729b3f6bdebcbacca84001529bb38836dcfeb3ee5dbaa4cf2e923d73320a82a8',
    '84c89355558b2c8b834696f5d1628f46a122509f78570a888fe803ba9164c08e',
    'a99cf54a376dd6a3f9d8bf98d1ae906226d8effb9958d32dba860a4c94f36d6a',
  ]);
  const installed = fs.readFileSync(modulePath);
  assert.ok(reviewedPriorRevisions.has(createHash('sha256').update(installed).digest('hex')),
    'candidate client MoveCards module differs from reviewed previous revisions');
  fs.writeFileSync(modulePath, expectedModule);
}
assert.equal(fs.readFileSync(modulePath, 'utf8'), expectedModule,
  'candidate client MoveCards module drifted from reviewed source');

const target = path.join(root, 'ltk/client/client.lua');
assert.equal(fs.realpathSync(target), target, 'candidate client target must not be a symlink');
let source = fs.readFileSync(target, 'utf8');

const originalMove = 'function Client:moveCards(data)\n';
const legacyMove = 'function Client:moveCardsLegacy(data)\n';
if (!source.includes(legacyMove)) {
  assert.equal(mode, '--apply', 'candidate MoveCards legacy callback has not been isolated');
  assert.equal(source.split(originalMove).length, 2,
    'candidate MoveCards callback source drifted or is ambiguous');
  source = source.replace(originalMove, legacyMove);
}

const originalPile = 'function Client:setPlayerPile(data)\n';
const legacyPile = 'function Client:setPlayerPileLegacy(data)\n';
if (!source.includes(legacyPile)) {
  assert.equal(mode, '--apply', 'candidate SetPlayerPile legacy callback has not been isolated');
  assert.equal(source.split(originalPile).length, 2,
    'candidate SetPlayerPile callback source drifted or is ambiguous');
  source = source.replace(originalPile, legacyPile);
}

const moveWrapper = `function Client:moveCards(data)
  if self.card_wire_version == 1 then
    return require("ltk.client.card_wire_moves").receive(self, data)
  end
  if type(data) == "table" and type(data[1]) == "table" then
    for _, move in ipairs(data[1]) do
      for _, info in ipairs(move.moveInfo or {}) do
        if type(info.cardId) == "string" or info.cardWireRetiredRefs ~= nil then
          error("projected MoveCards requires negotiated Hegemony v1")
        end
      end
    end
  end
  return self:moveCardsLegacy(data)
end

`;
const pileWrapper = `function Client:setPlayerPile(data)
  if self.card_wire_version == 1 then
    return require("ltk.client.card_wire_moves").receivePile(self, data)
  end
  if type(data) == "table" and type(data[3]) == "table" then
    for _, reference in ipairs(data[3]) do
      if type(reference) == "string" then
        error("projected SetPlayerPile requires negotiated Hegemony v1")
      end
    end
  end
  return self:setPlayerPileLegacy(data)
end

`;

if (!source.includes(moveWrapper)) {
  assert.equal(mode, '--apply', 'candidate MoveCards v1 wrapper missing');
  assert.equal(source.split(legacyMove).length, 2,
    'candidate MoveCards legacy anchor drifted');
  source = source.replace(legacyMove, `${moveWrapper}${legacyMove}`);
}
if (!source.includes(pileWrapper)) {
  assert.equal(mode, '--apply', 'candidate SetPlayerPile v1 wrapper missing');
  assert.equal(source.split(legacyPile).length, 2,
    'candidate SetPlayerPile legacy anchor drifted');
  source = source.replace(legacyPile, `${pileWrapper}${legacyPile}`);
}

assert.equal(source.split(moveWrapper).length, 2,
  'candidate MoveCards v1 wrapper must occur exactly once');
assert.equal(source.split(pileWrapper).length, 2,
  'candidate SetPlayerPile v1 wrapper must occur exactly once');
assert.equal(source.split(legacyMove).length, 2,
  'candidate MoveCards legacy callback must occur exactly once');
assert.equal(source.split(legacyPile).length, 2,
  'candidate SetPlayerPile legacy callback must occur exactly once');

if (mode === '--apply') fs.writeFileSync(target, source);
console.log(`PASS isolated Hegemony v1 MoveCards/SetPlayerPile client bridge ${mode}; v1 remains disabled`);
