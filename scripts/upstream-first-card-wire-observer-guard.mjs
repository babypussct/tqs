// Route v1 Observe snapshots through the physical-socket card-wire projector.
// Changes only the isolated candidate runtime; v1 remains disabled by default.
// Usage: node scripts/upstream-first-card-wire-observer-guard.mjs --apply|--check <candidate-core>
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

const before = `  player:doNotify("Observe", cbor.encode(summary))`;
const previousAfter = `  -- TQS_HEG_CARD_WIRE_OBSERVE: snapshots are sent directly to a physical
  -- observer, bypassing seat doNotify and its per-physical dispatcher.
  -- Project for the observer socket itself, never for the watched seat.
  assert(self.card_wire_version == nil or self.card_wire_version == 1,
    "unsupported card wire protocol version")
  if self.card_wire_version == 1 then
    assert(self:getSettings("gameMode") == "new_heg_mode" and
      type(self.projectCardWire) == "function" and
      type(self.beginCardWireBatch) == "function" and
      player:getState() ~= fk.Player_Robot,
      "card wire v1 Observe requires a physical observer projector")
    local batch = self:beginCardWireBatch()
    assert(type(batch) == "table" and type(batch.commit) == "function" and
      type(batch.abort) == "function", "card wire v1 requires commit/abort")
    local ok, payload = pcall(function()
      local projected = self:projectCardWire(observee, player, "Observe", summary, batch)
      assert(projected ~= nil, "card wire v1 Observe requires a projected snapshot")
      return cbor.encode(projected)
    end)
    if not ok then
      batch:abort()
      error(payload)
    end
    batch:commit()
    player:doNotify("Observe", payload)
  else
    player:doNotify("Observe", cbor.encode(summary))
  end`;

const after = previousAfter
  .replace('local ok, payload = pcall(function()', 'local ok, payload, negotiation = pcall(function()')
  .replace('return cbor.encode(projected)', `return cbor.encode(projected), cbor.encode {
        protocol = "TQS_HEG_CARD_WIRE", cardWireVersion = 1, mode = "new_heg_mode",
      }`)
  .replace('    player:doNotify("Observe", payload)', `    -- A newly attached observer has no room negotiation state yet.
    player:doNotify("CardWireNegotiated", negotiation)
    player:doNotify("Observe", payload)`);

let source = fs.readFileSync(target, 'utf8');
// The capability guard adds an exact observer rejection before the existing
// projection assertion. Normalize only that reviewed block for composition.
const capabilityGate = [
  '  if self.card_wire_version == 1 then',
  '    if not self:hasCardWireCapability(player) then',
  '      player:doNotify("ErrorMsg", "card wire capability required")',
  '      if self.room and type(self.room.removeObserver) == "function" then',
  '        self.room:removeObserver(player)',
  '      end',
  '      return false',
  '    end',
].join('\n') + '\n';
const normalizedSource = source.includes(capabilityGate)
  ? source.replace(capabilityGate, '  if self.card_wire_version == 1 then\n')
  : source;
if (!source.includes(after) && !normalizedSource.includes(after)) {
  assert.equal(mode, '--apply', 'candidate observer physical projection missing');
  if (source.includes(previousAfter)) source = source.replace(previousAfter, before);
  assert.equal(source.split(before).length, 2, 'Observe callsite changed; review before patch');
  assert.equal(source.split('function ServerRoomBase:tellRoomToObserver(player)').length, 2,
    'unexpected observer method structure');
  source = source.replace(before, after);
  fs.writeFileSync(target, source);
}
assert.ok(source.includes(after) || normalizedSource.includes(after),
  'reviewed Observe guard must be installed');
console.log(`PASS isolated Hegemony observer --${mode.slice(2)}: transactional physical-only Observe projection; legacy preserved`);
