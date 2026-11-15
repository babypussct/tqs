// Route concealed per-card marks through the same per-physical-socket v1
// projector as other owner-only notifications. Never enable v1 here.
// Usage: node scripts/upstream-first-card-wire-card-mark-physical-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, candidate] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && candidate,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(candidate);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'card-mark wire patch restricted to scratch evidence candidate core');
const target = path.join(root, 'ltk/server/room.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const before = `        if physical and physical:getState() ~= fk.Player_Robot then
          physical:doNotify("SetCardMark", cbor.encode({ card.id, mark, value }))
        end`;
const after = `        if physical and physical:getState() ~= fk.Player_Robot then
          -- TQS_HEG_CARD_MARK_V1_PHYSICAL: the inherited helper projects
          -- owner-only card IDs and preflights CBOR before delivery in v1.
          -- Its opt-out path preserves the legacy physical notification.
          self:notifyPrivatePhysical(owner, physical, "SetCardMark", { card.id, mark, value })
        end`;
let source = fs.readFileSync(target, 'utf8');
assert.ok(source.includes('function Room:setCardMark(card, mark, value)') &&
  source.includes('if area == Card.PlayerHand or privatePile then'),
  'candidate missing reviewed owner-only card-mark routing');
if (!source.includes(after)) {
  assert.equal(mode, '--apply', 'concealed card mark v1 physical guard is missing');
  assert.equal(source.split(before).length, 2, 'source divergence or ambiguous direct card-mark send');
  source = source.replace(before, after);
}
assert.equal(source.split(after).length, 2, 'card-mark physical guard must occur exactly once');
assert.ok(!source.includes(before), 'concealed card mark must not bypass projector');
if (mode === '--apply') fs.writeFileSync(target, source);
console.log(`PASS isolated Hegemony physical SetCardMark ${mode}: owner-only v1 projection and legacy path`);
