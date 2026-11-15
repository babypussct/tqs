// Isolated candidate: all native requests need a physical-recipient projection
// and all human replies need a request-scoped, validated reverse translation.
// Usage: node scripts/upstream-first-card-wire-request-guard.mjs --apply|--check <candidate-core>
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'usage: --apply|--check <isolated candidate core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u);
const target = path.join(root, 'lua/server/request.lua');
assert.equal(fs.realpathSync(target), target, 'candidate target must not be a symlink');

const changes = [
  [
    `  local jsonData = self.data[player.id]
  if self.send_encode then jsonData = cbor.encode(jsonData) end`,
    `  -- TQS_HEG_CARD_WIRE_REQUEST: requests bypass ServerPlayerBase:doNotify.
  -- A v1 request must be projected for its *physical* controller before
  -- encoding. Stage its reply allowlist with the projected payload.
  local jsonData = self.data[player.id]
  assert(self.room.card_wire_version == nil or self.room.card_wire_version == 1,
    "unsupported card wire protocol version")
  if self.room.card_wire_version == 1 then
    local room = self.room
    assert(room:getSettings("gameMode") == "new_heg_mode" and
      type(room.projectCardWireRequest) == "function" and
      type(room.resolveCardWireRequestReply) == "function" and
      type(room.beginCardWireBatch) == "function",
      "card wire v1 requests require physical projection and validated replies")
    -- Snapshot the prior request before staging the replacement. Both
    -- cancellation and minting must commit together or neither takes effect.
    local previous = self._cardWireRequests and self._cardWireRequests[player.id]
    if previous then
      assert(room._cardWireProtocol and type(room.cardWireAudience) == "function",
        "card wire v1 request replacement requires audience cleanup")
    end
    local requestKey = require("server.card_wire_secure_mint").next()
    local batch = room:beginCardWireBatch()
    assert(type(batch) == "table" and type(batch.commit) == "function" and
      type(batch.abort) == "function", "card wire v1 requires atomic requests")
    local ok, payload = pcall(function()
      local projected = room:projectCardWireRequest(player, controller,
        self.command, jsonData, batch, requestKey)
      assert(projected ~= nil, "card wire v1 request projection missing")
      local payload = self.send_encode and cbor.encode(projected) or projected
      if previous then
        batch:cancelChoice(room:cardWireAudience(previous.physical), previous.key)
      end
      return payload
    end)
    if not ok then batch:abort(); error(payload) end
    batch:commit()
    self._cardWireRequests = self._cardWireRequests or {}
    self._cardWireRequests[player.id] = {
      physical = controller,
      key = requestKey,
      command = self.command,
      data = self.data[player.id],
    }
    jsonData = payload
  elseif self.send_encode then
    jsonData = cbor.encode(jsonData)
  end`,
  ],
  [
    `        local ok, ret = pcall(cbor.decode, reply)
        if ok then
          reply = ret
        end`,
    `        local ok, ret = pcall(cbor.decode, reply)
        if ok then reply = ret end
        -- TQS_HEG_CARD_WIRE_REPLY: only decode/resolve actual human replies.
        -- Cancellation remains a sentinel. Never fall back to raw card IDs.
        if room.card_wire_version == 1 and humanReply and reply ~= "__notready" and
            reply ~= "__cancel" then
          assert(ok, "card wire v1 requires a decodable CBOR reply")
          local tracked = self._cardWireRequests and self._cardWireRequests[player.id]
          assert(tracked and tracked.physical == controller,
            "card wire v1 reply came from an unexpected physical controller")
          local resolved = room:resolveCardWireRequestReply(player, controller,
            self.command, reply, tracked.key, tracked.data)
          assert(resolved ~= nil,
            "card wire v1 rejected an invalid or expired card reference")
          reply = resolved
        end`,
  ],
  [
    `  room.current_request = nil
  room.last_request = self`,
    `  -- TQS_HEG_CARD_WIRE_REQUEST_CLEANUP: cancel unconsumed allowlists on
  -- timeout, cancellation, room suspension or race. Retire only this physical
  -- controller's request; another socket may observe the same logical seat.
  if self._cardWireRequests then
    assert(room.card_wire_version == 1 and room._cardWireProtocol,
      "card wire request context missing its room protocol")
    for _, tracked in pairs(self._cardWireRequests) do
      room._cardWireProtocol:cancelChoice(room:cardWireAudience(tracked.physical),
        tracked.key)
    end
    self._cardWireRequests = nil
  end
  room.current_request = nil
  room.last_request = self`,
  ],
];

let source = fs.readFileSync(target, 'utf8');
const humanReplyBefore = '  local reply\n';
const humanReplyAfter = '  local reply\n  local humanReply = false';
if (!source.includes(humanReplyAfter)) {
  assert.equal(mode, '--apply', 'candidate human-reply discriminator missing');
  assert.equal(source.split(humanReplyBefore).length, 2,
    'unexpected Request:_checkReply reply declaration layout');
  source = source.replace(humanReplyBefore, humanReplyAfter);
}
assert.equal(source.split(humanReplyAfter).length, 2,
  'human-reply discriminator must occur once');
const humanReplyBranchBefore = '      if reply ~= "__notready" then\n        controller:setThinking(false)';
const humanReplyBranchAfter = '      if reply ~= "__notready" then\n        humanReply = true\n        controller:setThinking(false)';
if (!source.includes(humanReplyBranchAfter)) {
  assert.equal(mode, '--apply', 'candidate human-reply branch marker missing');
  assert.equal(source.split(humanReplyBranchBefore).length, 2,
    'unexpected human reply branch layout');
  source = source.replace(humanReplyBranchBefore, humanReplyBranchAfter);
}
assert.equal(source.split(humanReplyBranchAfter).length, 2,
  'human-reply branch marker must occur once');
// The request-send region can be upgraded from either the upstream source or
// the earlier candidate-only replacement.  Replace the whole guarded region
// so a previous partial apply cannot leave two reply resolvers in sequence.
const projectionBefore = changes[0][0];
const projectionAfter = changes[0][1];
if (!source.includes(projectionAfter)) {
  assert.equal(mode, '--apply', 'candidate request/reply patch missing');
  if (source.includes(projectionBefore)) {
    source = source.replace(projectionBefore, projectionAfter);
  } else {
    const start = source.indexOf('  -- TQS_HEG_CARD_WIRE_REQUEST:');
    const end = source.indexOf('  -- FIXME: 这里确认数据是否发送的环节一定要写在C++代码中', start);
    assert.ok(start >= 0 && end > start, 'unexpected request/reply source layout');
    source = source.slice(0, start) + projectionAfter + '\n' + source.slice(end);
  }
}
assert.equal(source.split(projectionAfter).length, 2,
  'request projection patch must occur once');

const replyAfter = changes[1][1];
const replyStart = source.indexOf('        local ok, ret = pcall(cbor.decode, reply)');
const replyEnd = source.indexOf('      end\n    end\n  else', replyStart);
assert.ok(replyStart >= 0 && replyEnd > replyStart,
  'unexpected request/reply decode layout');
const replyRegion = source.slice(replyStart, replyEnd);
if (replyRegion !== `${replyAfter}\n`) {
  assert.equal(mode, '--apply', 'candidate reply resolver patch missing');
  source = source.slice(0, replyStart) + replyAfter + '\n' + source.slice(replyEnd);
}
assert.equal(source.split(replyAfter).length, 2,
  'request reply patch must occur once');

const cleanupBefore = changes[2][0];
const cleanupAfter = changes[2][1];
if (!source.includes(cleanupAfter)) {
  assert.equal(mode, '--apply', 'candidate request cleanup patch missing');
  assert.equal(source.split(cleanupBefore).length, 2,
    'unexpected request cleanup source layout');
  source = source.replace(cleanupBefore, cleanupAfter);
}
assert.equal(source.split(cleanupAfter).length, 2,
  'request cleanup patch must occur once');
if (mode === '--apply') fs.writeFileSync(target, source);
console.log(`PASS isolated Hegemony physical request/reply --${mode.slice(2)}: atomic request preflight, per-controller reverse guard and timeout cleanup; legacy preserved`);
