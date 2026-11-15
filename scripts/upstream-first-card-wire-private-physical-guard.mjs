// Candidate-only guard for owner-exclusive physical socket notifications.
// Opt-in card-wire v1 must project these notifications before CBOR encoding.
// Usage: node scripts/upstream-first-card-wire-private-physical-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u);
const target = path.join(root, 'lua/server/roombase.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const anchor = 'function ServerRoomBase:notifyProperty(p, player, property)';
const helper = `-- TQS_HEG_CARD_WIRE_PRIVATE_PHYSICAL: owner-only role/general/mark data
-- bypass seat doNotify and must be projected for the real physical socket.
-- Preserve byte-compatible legacy CBOR while v1 is disabled.
function ServerRoomBase:notifyPrivatePhysical(seat, physical, command, data)
  assert(self.card_wire_version == nil or self.card_wire_version == 1,
    "unsupported card wire protocol version")
  if self.card_wire_version ~= 1 then
    physical:doNotify(command, cbor.encode(data))
    return
  end
  assert(self:getSettings("gameMode") == "new_heg_mode" and
    physical == seat._splayer and physical:getState() ~= fk.Player_Robot and
    type(self.projectCardWire) == "function" and
    type(self.beginCardWireBatch) == "function",
    "card wire v1 private notification requires real owner and projector")
  local batch = self:beginCardWireBatch()
  assert(type(batch) == "table" and type(batch.commit) == "function" and
    type(batch.abort) == "function", "card wire v1 requires commit/abort")
  local ok, payload = pcall(function()
    local projected = self:projectCardWire(seat, physical, command, data, batch)
    assert(projected ~= nil, "card wire v1 requires projected owner notification")
    return cbor.encode(projected)
  end)
  if not ok then
    batch:abort()
    error(payload)
  end
  batch:commit()
  physical:doNotify(command, payload)
end

`;

const patches = [
  [
    'realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player.role }))',
    'self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player.role })',
  ],
  [
    'realOwner:doNotify("PropertyUpdate", cbor.encode({ player.id, property, player[property] }))',
    'self:notifyPrivatePhysical(p, realOwner, "PropertyUpdate", { player.id, property, player[property] })',
  ],
  [
    'realOwner:doNotify("SetPlayerMark", cbor.encode({ player.id, mark, value }))',
    'self:notifyPrivatePhysical(player, realOwner, "SetPlayerMark", { player.id, mark, value })',
  ],
];

let source = fs.readFileSync(target, 'utf8');
if (!source.includes(helper)) {
  assert.equal(mode, '--apply', 'physical-private helper missing');
  assert.equal(source.split(anchor).length, 2, 'unexpected notifyProperty definition');
  assert.ok(!source.includes('TQS_HEG_CARD_WIRE_PRIVATE_PHYSICAL'),
    'unexpected partial physical-private patch');
  source = source.replace(anchor, helper + anchor);
}
for (const [before, after] of patches) {
  if (source.includes(after)) continue;
  assert.equal(mode, '--apply', `physical-private callsite missing: ${after}`);
  assert.equal(source.split(before).length, 2, 'unrecognized private notification callsite');
  source = source.replace(before, after);
}
assert.equal(source.split(helper).length, 2, 'physical-private helper must occur once');
for (const [, after] of patches) {
  assert.equal(source.split(after).length, 2, 'physical-private callsites must occur once');
}
if (mode === '--apply') fs.writeFileSync(target, source);
console.log(`PASS isolated Hegemony owner-only physical --${mode.slice(2)}: 3 projected callsites and transactional helper; legacy preserved`);
