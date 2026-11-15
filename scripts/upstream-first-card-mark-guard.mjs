// Protect concealed physical-card marks on the isolated Hegemony candidate.
// Other card identity channels require coordinated server/client work.
// Usage: node scripts/upstream-first-card-mark-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'card mark patch restricted to scratch evidence candidate core');

const patches = [
  {
    file: 'ltk/server/room.lua',
    before: `function Room:setCardMark(card, mark, value)
  card:setMark(mark, value)
  if not card:isVirtual() then
    self:doBroadcastNotify("SetCardMark", {
      card.id,
      mark,
      value
    })
  end
end`,
    after: `function Room:setCardMark(card, mark, value)
  card:setMark(mark, value)
  if not card:isVirtual() then
    -- TQS_HEG_CARD_MARK_WIRE: physical hand card marks are owner-only;
    -- draw pile marks stay on the server. A player:doNotify call would
    -- forward owner-only data to attached observers, so use the physical
    -- connection (CBOR-framed) for Hegemony hidden card marks.
    if self:getSettings("gameMode") == "new_heg_mode" then
      local area = self:getCardArea(card.id)
      if area == Card.DrawPile then return end
      if area == Card.PlayerHand then
        local ownerId = self:getCardOwner(card.id)
        local owner = ownerId and self:getPlayerById(ownerId)
        local physical = owner and owner._splayer
        if physical and physical:getState() ~= fk.Player_Robot then
          physical:doNotify("SetCardMark", cbor.encode({ card.id, mark, value }))
        end
        return
      end
    end
    self:doBroadcastNotify("SetCardMark", {
      card.id,
      mark,
      value
    })
  end
end`,
  },
  {
    file: 'lua/server/roombase.lua',
    before: `  local o = klass.serialize(self)
  -- TQS_HEG_PRIVATE_WIRE: project mark/hidden-skill snapshots per audience.`,
    after: `  local o = klass.serialize(self)
  -- TQS_HEG_CARD_MARK_WIRE: card marks can identify a hand/deck card even
  -- when the move log or UI only displays its back. Project a snapshot
  -- copy per physical recipient, never change the server card manager.
  if self:getSettings("gameMode") == "new_heg_mode"
      and o.card_manager and o.card_manager.card_marks then
    local projected = cbor.decode(o.card_manager.card_marks)
    for id in pairs(projected) do
      local area = self:getCardArea(id)
      if area == Card.DrawPile or
          (area == Card.PlayerHand and
            (observer or not player or self:getCardOwner(id) ~= player.id)) then
        projected[id] = nil
      end
    end
    o.card_manager.card_marks = next(projected) and cbor.encode(projected) or nil
  end
  -- TQS_HEG_PRIVATE_WIRE: project mark/hidden-skill snapshots per audience.`,
  },
  {
    file: 'ltk/server/room.lua',
    before: `      if area == Card.PlayerHand then
        local ownerId = self:getCardOwner(card.id)
        local owner = ownerId and self:getPlayerById(ownerId)
        local physical = owner and owner._splayer`,
    after: `      local owner = self:getCardOwner(card.id)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(card.id)
      local privatePile = type(pileName) == "string" and pileName:sub(1, 1) == "$"
      if area == Card.PlayerHand or privatePile then
        local physical = owner and owner._splayer`,
  },
  {
    file: 'lua/server/roombase.lua',
    before: `      if area == Card.DrawPile or
          (area == Card.PlayerHand and
            (observer or not player or self:getCardOwner(id) ~= player.id)) then
        projected[id] = nil
      end`,
    after: `      local owner = self:getCardOwner(id)
      local pileName = area == Card.PlayerSpecial and owner and owner:getPileNameOfId(id)
      local privatePile = type(pileName) == "string" and pileName:sub(1, 1) == "$"
      if area == Card.DrawPile or
          ((area == Card.PlayerHand or privatePile) and
            (observer or not player or not owner or owner.id ~= player.id)) then
        projected[id] = nil
      end`,
  },
];

// The v1 physical-card-mark guard is applied later to the already composed
// candidate. Account for that reviewed downstream hunk during --check without
// reverting the owner-only projection to a raw physical send.
const v1DirectSend = '          physical:doNotify("SetCardMark", cbor.encode({ card.id, mark, value }))';
const v1ProjectedSend = `          -- TQS_HEG_CARD_MARK_V1_PHYSICAL: the inherited helper projects
          -- owner-only card IDs and preflights CBOR before delivery in v1.
          -- Its opt-out path preserves the legacy physical notification.
          self:notifyPrivatePhysical(owner, physical, "SetCardMark", { card.id, mark, value })`;

// Multiple hunks may touch the same file. Compose them against the latest
// projected text so a later write cannot undo an earlier hunk.
const output = new Map();
for (const [index, patch] of patches.entries()) {
  const file = path.join(root, patch.file);
  assert.equal(fs.realpathSync(file), file, 'candidate target must not be a symlink');
  const source = output.has(file) ? output.get(file) : fs.readFileSync(file, 'utf8');
  // A later hunk can replace a segment inside an earlier hunk's after-text.
  // Recognize that fully composed form for idempotent --check and --apply.
  const composedAfter = patches.slice(index + 1).reduce((body, later) =>
    later.file === patch.file && body.includes(later.before)
      ? body.replace(later.before, later.after) : body, patch.after);
  const composedWithV1 = patch.file === 'ltk/server/room.lua'
    ? composedAfter.replace(v1DirectSend, v1ProjectedSend) : composedAfter;
  if (source.includes(patch.after) || source.includes(composedAfter) ||
      source.includes(composedWithV1)) {
    output.set(file, source);
    continue;
  }
  assert.ok(source.includes(patch.before), `source divergence: ${patch.file}`);
  assert.equal(source.split(patch.before).length, 2, `ambiguous patch: ${patch.file}`);
  assert.equal(mode, '--apply', `missing card mark guard: ${patch.file}`);
  output.set(file, source.replace(patch.before, patch.after));
}
if (mode === '--apply') {
  for (const [file, source] of output) fs.writeFileSync(file, source);
}
console.log(`PASS isolated Hegemony card mark guard ${mode}: ${patches.length} source hunks`);
