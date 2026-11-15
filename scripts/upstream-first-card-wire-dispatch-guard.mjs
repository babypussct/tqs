// Candidate-only first step towards private card IDs on the native wire.
// Introduces a disabled-by-default, per-physical-recipient projection hook.
// Full card projection + client-side aliases still have to be implemented.
// Usage: node scripts/upstream-first-card-wire-dispatch-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'wire-dispatch patch restricted to scratch evidence candidate core');
const target = path.join(root, 'lua/server/serverplayer_base.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const before = `function ServerPlayerBase:doNotify(command, data)
  if command == "Chat" and type(data) == "table" and data.msg then
    local filtered = ServerPlayerBase.filterChatMessage(data.msg)
    if not filtered then return end
    data.msg = filtered
  end

  local cbordata = cbor.encode(data)

  local room = self.room
  for _, p in ipairs(self._observers) do
    if p:getState() ~= fk.Player_Robot then
      room.notify_count = room.notify_count + 1
      p:doNotify(command, cbordata)
    end
  end

  for _, t in ipairs(room.observers) do
    local id, p = table.unpack(t)
    -- Reconnect 是整房序列化摘要，只应发给重连者本人做全量重建；
    -- 绑定它的旁观者若收到会把自己当重连者重建一遍（room 被刷新、观察视角被打断）。
    -- 被旁观者回来后，旁观者靠 broadcastProperty(state) 等增量消息同步即可。
    if id == self.id and command ~= "Reconnect" and room.room:hasObserver(p)
        and p:getState() ~= fk.Player_Robot then
      p:doNotify(command, cbordata)
    end
  end

  if room.notify_count >= room.notify_max and
      coroutine.status(room.main_co) == "normal" then
    room:delay(100)
  end
end`;

const after = `function ServerPlayerBase:doNotify(command, data)
  if command == "Chat" and type(data) == "table" and data.msg then
    local filtered = ServerPlayerBase.filterChatMessage(data.msg)
    if not filtered then return end
    data.msg = filtered
  end

  local room = self.room
  -- TQS_HEG_CARD_WIRE_DISPATCH: the next protocol is opt-in until both the
  -- native projector and Lua client implement stable per-socket aliases.
  -- If enabled, never silently fall back to one shared unprojected CBOR.
  assert(room.card_wire_version == nil or room.card_wire_version == 1,
    "unsupported card wire protocol version")
  local privateWire = room.card_wire_version == 1
  if privateWire then
    assert(room:getSettings("gameMode") == "new_heg_mode" and
      type(room.projectCardWire) == "function",
      "card wire v1 requires a new_heg_mode per-socket projector")
    assert(command ~= "Reconnect",
      "card wire v1 Reconnect must target the actual physical socket")
  end
  local cbordata = not privateWire and cbor.encode(data) or nil

  -- Preflight every physical payload before sending the first packet. A
  -- projector/CBOR failure for a late spectator must not half-deliver an event.
  local pending = {}
  local function stagePhysical(physical, counted)
    if physical:getState() == fk.Player_Robot then return end
    local payload = cbordata
    if privateWire then
      local projected = room:projectCardWire(self, physical, command, data)
      assert(projected ~= nil,
        "card wire v1 projector must return a physical-recipient payload")
      payload = cbor.encode(projected)
    end
    pending[#pending + 1] = { physical = physical, payload = payload, counted = counted }
  end

  for _, p in ipairs(self._observers) do stagePhysical(p, true) end

  for _, t in ipairs(room.observers) do
    local id, p = table.unpack(t)
    -- Reconnect must go exclusively to its returning physical connection.
    if id == self.id and command ~= "Reconnect" and room.room:hasObserver(p) then
      stagePhysical(p, false)
    end
  end

  for _, item in ipairs(pending) do
    if item.counted then room.notify_count = room.notify_count + 1 end
    item.physical:doNotify(command, item.payload)
  end

  if room.notify_count >= room.notify_max and
      coroutine.status(room.main_co) == "normal" then
    room:delay(100)
  end
end`;

// A full notification is one transaction across seat sockets and observers.
// The room is responsible for returning a transaction backed by its physical
// audience handle store. The protocol remains disabled until that exists.
const transactedAfter = after
  .replace(`  local pending = {}
  local function stagePhysical`, `  local pending = {}
  local batch
  if privateWire then
    assert(type(room.beginCardWireBatch) == "function",
      "card wire v1 requires transaction support")
    batch = room:beginCardWireBatch()
    assert(type(batch) == "table" and type(batch.commit) == "function" and
      type(batch.abort) == "function",
      "card wire v1 requires a commit/abort batch")
  end
  local function stagePhysical`)
  .replace(`room:projectCardWire(self, physical, command, data)`,
    `room:projectCardWire(self, physical, command, data, batch)`)
  .replace(`  for _, p in ipairs(self._observers) do stagePhysical(p, true) end

  for _, t in ipairs(room.observers) do
    local id, p = table.unpack(t)
    -- Reconnect must go exclusively to its returning physical connection.
    if id == self.id and command ~= "Reconnect" and room.room:hasObserver(p) then
      stagePhysical(p, false)
    end
  end

  for _, item in ipairs(pending) do`,
    `  local ok, failure = pcall(function()
    for _, p in ipairs(self._observers) do stagePhysical(p, true) end

    for _, t in ipairs(room.observers) do
      local id, p = table.unpack(t)
      -- Spectator handles are independent of the watched seat's handles.
      if id == self.id and command ~= "Reconnect" and room.room:hasObserver(p) then
        stagePhysical(p, false)
      end
    end
  end)
  if not ok then
    if batch then batch:abort() end
    error(failure)
  end
  if batch then batch:commit() end

  for _, item in ipairs(pending) do`);
assert.notEqual(transactedAfter, after, 'transaction hunk must change candidate source');

const source = fs.readFileSync(target, 'utf8');
const stagedBeforeReconnectGuard = after.replace(`    assert(command ~= "Reconnect",
      "card wire v1 Reconnect must target the actual physical socket")
`, '');
const previous = stagedBeforeReconnectGuard.replace(`  -- Preflight every physical payload before sending the first packet. A
  -- projector/CBOR failure for a late spectator must not half-deliver an event.
  local pending = {}
  local function stagePhysical(physical, counted)`, `  local function sendPhysical(physical, counted)`)
  .replace(`    pending[#pending + 1] = { physical = physical, payload = payload, counted = counted }`,
    `    if counted then room.notify_count = room.notify_count + 1 end
    physical:doNotify(command, payload)`)
  .replace(`for _, p in ipairs(self._observers) do stagePhysical(p, true) end`,
    `for _, p in ipairs(self._observers) do sendPhysical(p, true) end`)
  .replace(`      stagePhysical(p, false)`, `      sendPhysical(p, false)`)
  .replace(`
  for _, item in ipairs(pending) do
    if item.counted then room.notify_count = room.notify_count + 1 end
    item.physical:doNotify(command, item.payload)
  end
`, '');

if (source.includes(transactedAfter)) {
  console.log(`PASS isolated Hegemony wire dispatch ${mode}: already projected`);
} else {
  const baseline = [after, stagedBeforeReconnectGuard, previous, before]
    .find((candidate) => source.includes(candidate));
  assert.ok(baseline, 'expected reviewed candidate source baseline');
  assert.equal(source.split(baseline).length, 2,
    'source divergence: existing doNotify must match the reviewed candidate or previous guard');
  assert.equal(mode, '--apply', 'missing physical-recipient dispatch on candidate');
  fs.writeFileSync(target, source.replace(baseline, transactedAfter));
  console.log('PASS isolated Hegemony wire dispatch --apply: atomic per-physical transaction');
}
