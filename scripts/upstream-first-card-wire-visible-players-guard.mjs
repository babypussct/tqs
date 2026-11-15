// Preserve both legacy player-object and numeric-ID viewer lists in the
// isolated Hegemony candidate's MoveCards transport. V1 remains disabled.
// Usage: --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, candidate] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && candidate,
  'expected --apply|--check <isolated candidate core>');
const root = fs.realpathSync(candidate);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'viewer-list patch restricted to isolated candidate');
const target = path.join(root, 'ltk/server/events/movecard.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const before = `      if type(v.visiblePlayers) == "table" then
        if type(v.visiblePlayers[1]) == "table" then
          v.visiblePlayers = table.map(v.visiblePlayers, Util.IdMapper)
        else
          ---@diagnostic disable-next-line: undefined-field
          v.visiblePlayers = v.visiblePlayers.id
        end
      end`;
const after = `      if type(v.visiblePlayers) == "table" then
        if type(v.visiblePlayers[1]) == "table" then
          v.visiblePlayers = table.map(v.visiblePlayers, Util.IdMapper)
        elseif type(v.visiblePlayers[1]) == "number" then
          -- TQS_HEG_VIEWER_IDS: already-idlized lists must not become nil.
          -- Keep the list intact for physical-audience visibility checks.
          v.visiblePlayers = table.simpleClone(v.visiblePlayers)
        else
          ---@diagnostic disable-next-line: undefined-field
          v.visiblePlayers = v.visiblePlayers.id
        end
      end`;
let source = fs.readFileSync(target, 'utf8');
assert.ok(source.includes('function MoveEventWrappers:notifyMoveCards(players, moveDatas, event_id)'),
  'candidate MoveCards notifier is missing');
if (!source.includes(after)) {
  assert.equal(mode, '--apply', 'candidate MoveCards viewer ID guard missing');
  assert.equal(source.split(before).length, 2, 'candidate viewer-list source drift or ambiguous hunk');
  source = source.replace(before, after);
}
assert.equal(source.split(after).length, 2, 'viewer-list fix must occur exactly once');
assert.ok(!source.includes(before), 'old numeric viewer-list path must be absent');
if (mode === '--apply') fs.writeFileSync(target, source);
console.log(`PASS isolated Hegemony MoveCards viewer IDs ${mode}: numeric arrays and player objects`);
