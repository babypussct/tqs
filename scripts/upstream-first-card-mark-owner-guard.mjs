// Correct the actual AbstractRoom:getCardOwner() contract on the isolated
// candidate. Unlike CardManager:getCardOwner(), it returns a Player object.
// Usage: node scripts/upstream-first-card-mark-owner-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'owner contract patch restricted to scratch evidence candidate core');

const patches = [
  {
    file: 'ltk/server/room.lua',
    before: `      local ownerId = self:getCardOwner(card.id)
      local owner = ownerId and self:getPlayerById(ownerId)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(card.id)`,
    after: `      local owner = self:getCardOwner(card.id)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(card.id)`,
  },
  {
    file: 'lua/server/roombase.lua',
    before: `      local ownerId = self:getCardOwner(id)
      local owner = ownerId and self:getPlayerById(ownerId)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(id)
      local privatePile = type(pileName) == "string" and pileName:sub(1, 1) == "$"
      if area == Card.DrawPile or
          ((area == Card.PlayerHand or privatePile) and
            (observer or not player or ownerId ~= player.id)) then`,
    after: `      local owner = self:getCardOwner(id)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(id)
      local privatePile = type(pileName) == "string" and pileName:sub(1, 1) == "$"
      if area == Card.DrawPile or
          ((area == Card.PlayerHand or privatePile) and
            (observer or not player or not owner or owner.id ~= player.id)) then`,
  },
];

const updated = [];
for (const patch of patches) {
  const file = path.join(root, patch.file);
  assert.equal(fs.realpathSync(file), file, 'candidate target must not be a symlink');
  const source = fs.readFileSync(file, 'utf8');
  if (source.includes(patch.after)) {
    assert.ok(!source.includes(patch.before), `conflicting owner contract: ${patch.file}`);
    continue;
  }
  assert.equal(source.split(patch.before).length, 2,
    `expected one audited owner contract hunk: ${patch.file}`);
  assert.equal(mode, '--apply', `owner contract guard missing: ${patch.file}`);
  updated.push([file, source.replace(patch.before, patch.after)]);
}

if (mode === '--apply') {
  for (const [file, source] of updated) fs.writeFileSync(file, source);
}
console.log(`PASS isolated Hegemony card mark owner guard ${mode}: ${patches.length} source hunks`);
