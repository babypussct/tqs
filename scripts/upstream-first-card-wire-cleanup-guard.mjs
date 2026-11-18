// Candidate-only card-wire mapping cleanup at GameOver.
// Production/current remains legacy-only; this guard is restricted to the
// isolated candidate runtime assembled by the native QA launcher.
// Usage: node scripts/upstream-first-card-wire-cleanup-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'expected --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /(?:\/scratch\/evidence\/[^/]+\/candidate-runtime|\/private\/tmp\/tqs-cardwire-qa-20261103-[^/]+)\/packages\/freekill-core$/u,
  'card-wire GameOver cleanup is restricted to an isolated candidate or QA copy');
const target = path.join(root, 'lua/server/roombase.lua');
assert.equal(fs.realpathSync(target), target, 'candidate roombase must not be a symlink');

const marker = '  self.room:gameOver()\n';
const insertion = `  -- TQS_HEG_CARD_WIRE_GAMEOVER_CLEANUP: retire every per-physical
  -- mapping before the room is handed back to the scheduler. The audience
  -- keys are opaque server state and are never emitted in QA telemetry.
  if self.card_wire_version == 1 and self._cardWireProtocol and
      type(self._cardWireProtocol.audiences) == "table" then
    local audiences = {}
    for audience in pairs(self._cardWireProtocol.audiences) do
      table.insert(audiences, audience)
    end
    for _, audience in ipairs(audiences) do
      self._cardWireProtocol:disconnect(audience)
    end
  end
`;

let source = fs.readFileSync(target, 'utf8');
if (!source.includes(insertion)) {
  assert.equal(mode, '--apply', 'candidate GameOver card-wire cleanup is missing');
  assert.equal(source.split(marker).length, 2,
    'candidate GameOver cleanup anchor changed or is no longer unique');
  source = source.replace(marker, insertion + marker);
  fs.writeFileSync(target, source);
}
assert.equal(source.split(insertion).length, 2,
  'candidate GameOver card-wire cleanup must appear exactly once');
console.log(`PASS isolated card-wire GameOver cleanup ${mode}: audience mappings retired before scheduler cleanup`);
