// Candidate-only v1 Reconnect delivery to the returning physical socket.
// The reconnect summary contains private per-seat state and must never be
// fanned out to additional controlling sockets or attached spectators.
// Usage: node scripts/upstream-first-card-wire-reconnect-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u);
const target = path.join(root, 'lua/server/serverplayer_base.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const marker = '--- 发送一句聊天';
const physicalMethod = `function ServerPlayerBase:doNotifyToPhysical(command, data, physical)
  local room = self.room
  assert(command == "Reconnect" and room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode" and
    type(room.projectCardWire) == "function" and
    physical == self._splayer and table.contains(self._observers, physical),
    "card wire v1 Reconnect requires the returning physical socket")
  if physical:getState() == fk.Player_Robot then return end
  local projected = room:projectCardWire(self, physical, command, data)
  assert(projected ~= nil, "card wire v1 Reconnect requires a physical payload")
  local payload = cbor.encode(projected)
  physical:doNotify(command, payload)
  room.notify_count = room.notify_count + 1
  if room.notify_count >= room.notify_max and
      coroutine.status(room.main_co) == "normal" then
    room:delay(100)
  end
end

`;

const previousTransactedPhysicalMethod = physicalMethod.replace(
  `  local projected = room:projectCardWire(self, physical, command, data)
  assert(projected ~= nil, "card wire v1 Reconnect requires a physical payload")
  local payload = cbor.encode(projected)
  physical:doNotify(command, payload)`,
  `  assert(type(room.beginCardWireBatch) == "function",
    "card wire v1 Reconnect requires transaction support")
  local batch = room:beginCardWireBatch()
  assert(type(batch) == "table" and type(batch.commit) == "function" and
    type(batch.abort) == "function", "card wire v1 requires commit/abort")
  local ok, payload = pcall(function()
    local projected = room:projectCardWire(self, physical, command, data, batch)
    assert(projected ~= nil, "card wire v1 Reconnect requires a physical payload")
    return cbor.encode(projected)
  end)
  if not ok then
    batch:abort()
    error(payload)
  end
  batch:commit()
  physical:doNotify(command, payload)`);
const transactedPhysicalMethod = previousTransactedPhysicalMethod
  .replace('local ok, payload = pcall(function()', 'local ok, payload, negotiation = pcall(function()')
  .replace('return cbor.encode(projected)', `return cbor.encode(projected), cbor.encode {
      protocol = "TQS_HEG_CARD_WIRE", cardWireVersion = 1, mode = "new_heg_mode",
    }`)
  .replace('  physical:doNotify(command, payload)', `  -- Reconnect must also work in a fresh browser, without prior Lua state.
  physical:doNotify("CardWireNegotiated", negotiation)
  physical:doNotify(command, payload)`);
assert.notEqual(transactedPhysicalMethod, physicalMethod);

const before = '  self:doNotify("Reconnect", summary)';
const after = `  if room.card_wire_version == 1 then
    self:doNotifyToPhysical("Reconnect", summary, sp)
  else
    self:doNotify("Reconnect", summary)
  end`;

let source = fs.readFileSync(target, 'utf8');
// The capability guard adds one exact assertion before the transaction. Keep
// this guard composable by normalizing only that reviewed assertion for the
// existing reconnect hunk comparison.
const capabilityGate = [
  '  assert(type(room.hasCardWireCapability) == "function" and',
  '    room:hasCardWireCapability(physical),',
  '    "card wire v1 Reconnect refuses an unnegotiated physical connection")',
  '',
].join('\n');
const normalizedSource = source.includes(capabilityGate)
  ? source.replace(capabilityGate, '')
  : source;
const methodInstalled = source.includes(transactedPhysicalMethod) ||
  normalizedSource.includes(transactedPhysicalMethod);
const callInstalled = source.includes(after);
if (!methodInstalled || !callInstalled) {
  assert.equal(mode, '--apply', 'candidate v1 physical reconnect routing missing');
  assert.equal(source.split(marker).length, 2, 'reconnect method anchor diverged');
  assert.ok(source.includes('card wire v1 Reconnect must target the actual physical socket'),
    'install staged wire dispatcher and reconnect fail-closed guard first');
  if (!methodInstalled) {
    if (source.includes(previousTransactedPhysicalMethod)) {
      source = source.replace(previousTransactedPhysicalMethod, transactedPhysicalMethod);
    } else if (source.includes(physicalMethod)) {
      source = source.replace(physicalMethod, transactedPhysicalMethod);
    } else {
      assert.ok(!source.includes('function ServerPlayerBase:doNotifyToPhysical('),
        'existing physical method diverged');
      source = source.replace(marker, transactedPhysicalMethod + marker);
    }
  }
  if (!callInstalled) {
    assert.equal(source.split(before).length, 2, 'reconnect callsite diverged');
    source = source.replace(before, after);
  }
  fs.writeFileSync(target, source);
}
assert.ok((source.includes(transactedPhysicalMethod) ||
  normalizedSource.includes(transactedPhysicalMethod)) && source.includes(after));
console.log(`PASS isolated Hegemony reconnect --${mode.slice(2)}: atomic physical-only v1; legacy preserved`);
