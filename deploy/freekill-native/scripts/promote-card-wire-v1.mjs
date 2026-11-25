#!/usr/bin/env node

// Promote the reviewed card-wire runtime from the isolated candidate into an
// immutable native release root. This is deliberately an artifact transform:
// it never writes the repository runtime and refuses QA-only packages or
// symlinked package trees.

import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { updatePublicGeneralSource } from './hegemony-public-general.mjs';
import { updateRequestVisibility } from './card-wire-request-runtime.mjs';
import { editOnce, updateRpcStreamSource } from './native-runtime-source.mjs';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const separator = arg.indexOf('=');
  if (!arg.startsWith('--') || separator < 3) throw new Error(`Expected --key=value, got ${arg}`);
  return [arg.slice(2, separator), arg.slice(separator + 1)];
}));
assert.ok(args.root, 'Usage: promote-card-wire-v1.mjs --root=/isolated/native-release-root');

const root = path.resolve(args.root);
const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const repositoryRuntime = path.join(repositoryRoot, 'runtime');
assert.notEqual(root, repositoryRuntime, 'Refusing to promote directly into repository runtime');
assert.ok(fs.existsSync(path.join(root, 'packages')), `Missing native release packages: ${root}`);

const packages = path.join(root, 'packages');
const core = path.join(packages, 'freekill-core');
const hegemony = path.join(packages, 'hegemony');
for (const target of [core, hegemony]) {
  assert.ok(fs.existsSync(target), `Missing package: ${target}`);
  assert.equal(fs.lstatSync(target).isSymbolicLink(), false, `Symlinked package is not promotable: ${target}`);
}
assert.equal(fs.existsSync(path.join(packages, 'tqs_qa')), false,
  'QA-only tqs_qa package cannot enter the production release');
assert.equal(fs.existsSync(path.join(core, 'qa_packages')), false,
  'QA-only qa_packages tree cannot enter the production release');

updateRpcStreamSource(core);

const roomFile = path.join(core, 'lua/server/roombase.lua');
const qaOnlyGate = [
  '  assert(type(ServerConfig) == "table" and type(ServerConfig.tqsQa) == "table" and',
  '    ServerConfig.tqsQa.enabled == true and ServerConfig.tqsQa.cardWireVersion == 1,',
  '    "card wire negotiation is QA opt-in only")',
].join('\n');
const productionGate = [
  '  local qaConfig = type(ServerConfig) == "table" and ServerConfig.tqsQa or nil',
  '  local productionConfig = type(ServerConfig) == "table" and ServerConfig.tqsCardWire or nil',
  '  local qaEnabled = type(qaConfig) == "table" and qaConfig.enabled == true and',
  '    qaConfig.cardWireVersion == 1',
  '  local productionEnabled = type(productionConfig) == "table" and',
  '    productionConfig.enabled == true and productionConfig.version == 1 and',
  '    productionConfig.admission ~= "legacy"',
  '  assert(qaEnabled or productionEnabled,',
  '    "card wire negotiation is not enabled for this release")',
].join('\n');
let roomSource = editOnce(roomFile, qaOnlyGate, productionGate,
  'production card-wire negotiation gate');
roomSource = roomSource.replace(
  '-- TQS_HEG_CARD_WIRE_NEGOTIATION: QA-only ordered opt-in. The capability\n',
  '-- TQS_HEG_CARD_WIRE_NEGOTIATION: ordered production/QA opt-in. The capability\n',
);
roomSource = roomSource.replace(
  '-- is inert unless the isolated QA config explicitly sets cardWireVersion=1;\n' +
  '-- production/current configs do not contain that field.\n',
  '-- is inert unless the exact release config explicitly enables version 1.\n',
);
fs.writeFileSync(roomFile, roomSource);

editOnce(roomFile, 'function ServerRoomBase:resume(reason)\n', [
  'function ServerRoomBase:resume(reason)',
  '  if self.game_finished then return true end',
  '',
].join('\n'), 'ignore timer wakes after GameOver');

editOnce(roomFile, [
  '  if self:checkNoHuman() then',
  '    goto GAME_OVER',
  '  end',
].join('\n'), [
  '  local noHuman, waitingForReconnect = self:checkNoHuman()',
  '  if waitingForReconnect then return false end',
  '  if noHuman then goto GAME_OVER end',
].join('\n'), 'pause an offline Hegemony room');

const offlineGraceBefore = [
  '  for _, p in ipairs(self.players) do',
  '    local state = p.serverplayer:getState()',
  '    if state == fk.Player_Online or state == fk.Player_Trust then',
  '      return',
  '    end',
  '  end',
  '',
  '  if not chkOnly then',
].join('\n');
const offlineGracePrevious = [
  '  local hasOfflinePlayer = false',
  '  for _, p in ipairs(self.players) do',
  '    local state = p.serverplayer:getState()',
  '    if state == fk.Player_Online or state == fk.Player_Trust then',
  '      self._tqsReconnectUntil = nil',
  '      return',
  '    end',
  '    hasOfflinePlayer = hasOfflinePlayer or state == fk.Player_Offline',
  '  end',
  '',
  '  if hasOfflinePlayer and self.game_started and not self.game_finished and',
  '      self:getSettings("gameMode") == "new_heg_mode" then',
  '    local now = os.getms()',
  '    if not self._tqsReconnectUntil then',
  '      local graceMs = 30000',
  '      self._tqsReconnectUntil = now + graceMs',
  '      self.room:delay(graceMs)',
  '    end',
  '    if now < self._tqsReconnectUntil then return false, true end',
  '  end',
  '',
  '  if not chkOnly then',
].join('\n');
// The pinned runtime exposes microseconds through os.getms; native delay takes milliseconds.
const offlineGrace = offlineGracePrevious.replace('local now = os.getms()', 'local now = os.getms() / 1000');
editOnce(roomFile, offlineGraceBefore, offlineGrace,
  'bounded reconnect for offline seats', offlineGracePrevious);

const roomDelayBefore = [
  '  self.room:delay(math.ceil(ms))',
  '  if self._test_disable_delay then return end',
  '  self:yield(function(r) return r == "delay_done" end, ms)',
].join('\n');
const roomDelayPrevious = [
  '  local duration = math.ceil(ms)',
  '  local untilMs = os.getms() + duration',
  '  self.room:delay(duration)',
  '  if self._test_disable_delay then return end',
  '  if self:getSettings("gameMode") ~= "new_heg_mode" then',
  '    self:yield(function(reason) return reason == "delay_done" end, ms)',
  '    return',
  '  end',
  '  self:yield(function(reason)',
  '    -- The reconnect timer also wakes the room with delay_done.',
  '    if reason ~= "delay_done" and reason ~= "player_reconnect" then return false end',
  '    local remaining = untilMs - os.getms()',
  '    if remaining <= 0 then return true end',
  '    if reason == "delay_done" then self.room:delay(remaining) end',
  '    return false',
  '  end, ms)',
].join('\n');
const roomDelay = roomDelayPrevious
  .replace('os.getms() + duration', 'os.getms() / 1000 + duration')
  .replace('untilMs - os.getms()', 'untilMs - os.getms() / 1000')
  .replace('self.room:delay(remaining)', 'self.room:delay(math.ceil(remaining))');
editOnce(roomFile, roomDelayBefore, roomDelay,
  'preserve the game delay when a reconnect timer fires', roomDelayPrevious);

editOnce(roomFile, [
  'function ServerRoomBase:playerReconnect(id)',
  '  local p = self:getPlayerById(id)',
  '  if p then',
  '    p:reconnect()',
  '  end',
  'end',
].join('\n'), [
  'function ServerRoomBase:playerReconnect(id)',
  '  local p = self:getPlayerById(id)',
  '  if p then',
  '    p:reconnect()',
  '    if self._tqsReconnectUntil then ResumeRoom(self.id, "player_reconnect") end',
  '  end',
  'end',
].join('\n'), 'resume the paused room after the reconnect snapshot');

const modeFile = path.join(hegemony, 'pkg/gamemodes/new_hegemony_mode.lua');
const qaHook = [
  '  local preDrawHook = self.room.__tqs_qa_beforePrepareDrawPile',
  '  if type(preDrawHook) == "function" then',
  '    preDrawHook(self.room)',
  '  end',
].join('\n');
const productionHook = [
  '  -- The negotiation marker must precede PrepareDrawPile and every card-bearing',
  '  -- notification. A capability mismatch selects one whole-room legacy',
  '  -- session; it never creates a mixed v1/legacy room.',
  '  local productionConfig = type(ServerConfig) == "table" and ServerConfig.tqsCardWire or nil',
  '  if type(productionConfig) == "table" and productionConfig.enabled == true and',
  '      productionConfig.version == 1 and productionConfig.admission ~= "legacy" then',
  '    assert(type(self.room.negotiateCardWireV1) == "function" and',
  '      type(self.room.hasAllCardWireCapabilities) == "function",',
  '      "card wire v1 production seam is missing")',
  '    if self.room:hasAllCardWireCapabilities() then',
  '      self.room:negotiateCardWireV1()',
  '      self.room.card_wire_negotiation_state = "v1"',
  '    else',
  '      self.room.card_wire_negotiation_state = "legacy"',
  '      self.room.card_wire_protocol = "legacy"',
  '    end',
  '  end',
  '',
  ...qaHook.split('\n'),
].join('\n');
editOnce(modeFile, qaHook, productionHook, 'production pre-draw negotiation boundary');

const cupFile = path.join(hegemony, 'pkg/nine_variations/skills/turban_shell_cup.lua');
assert.equal(fs.realpathSync(cupFile), cupFile, 'Symlinked Anh Vũ Bôi skill is not promotable');
editOnce(cupFile, '    c:addSubcard(Fk:currentRoom().draw_pile[1])', [
  '    local room = Fk:currentRoom()',
  '    local top = room.draw_pile[1]',
  '    if not top then return end',
  '    -- A v1 client previews Tửu without knowing the physical deck card.',
  '    -- Its reply contains the skill and selections; the server resolves the top card.',
  '    local refs = room.card_wire_refs',
  '    if room.card_wire_version ~= 1 or not refs or not refs:isAnonymous(top) then',
  '      c:addSubcard(top)',
  '    end',
].join('\n'), 'Anh Vũ Bôi anonymous deck preview');

updatePublicGeneralSource(core, '--apply');
updateRequestVisibility(core, '--apply');
const wireModules = [
  ['ltk/client/card_wire_refs.lua', 'card-wire-client-refs.lua',
    '924853d9f63f6dee5018a8c33d51c4d8fd474998d99895a06d95c6e46b36c709'],
  ['ltk/client/card_wire_moves.lua', 'card-wire-client-moves.lua',
    '87c85425074c010d1bd15c4ab31f55a0f317034e082a9050763a7413e0cdf7d7'],
  ['ltk/client/card_wire_snapshots.lua', 'card-wire-client-snapshots.lua',
    '9b57de0578abb488b892355c0fd33fa8b9acfd11986a248bfd31827961a1db71'],
  ['lua/server/card_wire_projection.lua', 'card-wire-projection.lua',
    ['ec4410704892385bb151bfc5781ea0f24a798c00f606ea0e2a3890ece1392dfe',
      'ef6873c75de2aa8fad321187f400fa8b7cbde1d0d632069429f49a25138d627e']],
  ['lua/server/card_wire_request.lua', 'card-wire-request.lua',
    ['779b3bc22a99e737005a89170bca3d7bb2f7acbc9828b34258edf6bce4e931e1',
      'b514217268a97b37d7aada86fca9c171f94f6b45039b47c8faedfa89c61c732e']],
  ['ltk/client/card_wire_requests.lua', 'card-wire-client-requests.lua',
    '63c412fefb35eb3d3c344543dd787375e406bc782d69da322379faab3fa04e71'],
];
for (const [relative, reviewedFile, previousHash] of wireModules) {
  const target = path.join(core, relative);
  assert.equal(fs.realpathSync(target), target, `Symlinked module is not promotable: ${relative}`);
  const installed = fs.readFileSync(target);
  const reviewed = fs.readFileSync(path.join(repositoryRoot, 'deploy/freekill-native/qa', reviewedFile));
  if (!installed.equals(reviewed)) {
    assert.ok([previousHash].flat().includes(createHash('sha256').update(installed).digest('hex')),
      `Previous production module bytes drifted: ${relative}`);
    fs.writeFileSync(target, reviewed);
  }
}

const configFile = path.join(root, 'freekill.server.config.json');
let config = {};
if (fs.existsSync(configFile)) {
  config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
} else {
  const templateFile = path.join(repositoryRoot, 'deploy/freekill-native/server/freekill.server.config.json');
  config = JSON.parse(fs.readFileSync(templateFile, 'utf8'));
}
config.tqsCardWire = { enabled: true, version: 1, admission: 'v1' };
fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');

console.log(JSON.stringify({
  root,
  production: { cardWireVersion: 1, admission: 'v1' },
  changed: [
    'packages/freekill-core/lua/server/rpc/cbor.lua',
    'packages/freekill-core/lua/server/rpc/stdio.lua',
    'packages/freekill-core/lua/server/roombase.lua',
    ...wireModules.map(([relative]) => `packages/freekill-core/${relative}`),
    'packages/freekill-core/ltk/core/card_wire_request_visibility.lua',
    'packages/freekill-core/ltk/core/engine.lua',
    'packages/freekill-core/ltk/server/serverplayer.lua',
    'packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua',
    'packages/hegemony/pkg/nine_variations/skills/turban_shell_cup.lua',
    'freekill.server.config.json',
  ],
}));
