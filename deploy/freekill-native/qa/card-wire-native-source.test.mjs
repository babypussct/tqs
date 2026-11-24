import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const upstream = path.join(repo, 'scratch/upstream/freekill-asio');
const candidatePatch = path.join(
  repo, 'deploy/freekill-native/patches/freekill-asio/tqs-card-wire-candidate-native-bridge.patch',
);
const nativeBoundaryPatch = path.join(
  repo, 'deploy/freekill-native/patches/upstream-runtime/tqs-card-wire-native-boundary-qa.patch',
);
const productionPatches = [
  'reconnect-safe-tempban.patch',
  'tqs-compiler-compat.patch',
  'tqs-game-access.patch',
].map((name) => path.join(repo, 'deploy/freekill-native/patches/freekill-asio', name));

function applyPatch(source, patchFile, dryRun = false) {
  execFileSync('patch', [
    ...(dryRun ? ['--dry-run'] : []), '--batch', '--forward', '-p1', '-d', source,
    '-i', patchFile,
  ], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function extractPinnedNativeSource(destination) {
  // QA users may have local patches in scratch/upstream. Verify the pinned
  // committed source rather than copying their modified working tree.
  const archive = execFileSync('git', ['-C', upstream, 'archive', 'b8a2ad48305aea7b55ccca325fcbeb100cb8a01a'], {
    maxBuffer: 64 * 1024 * 1024,
  });
  mkdirSync(destination, { recursive: true });
  execFileSync('tar', ['-xf', '-', '-C', destination], { input: archive });
}

test('production native bridge patch is pinned and applies after the other native patches', (t) => {
  const patchText = readFileSync(candidatePatch, 'utf8');
  assert.match(patchText, /#if defined\(__linux__\)/u);
  assert.match(patchText, /::kill\(child_pid, 0\)/u);
  assert.match(patchText, /cardWireCapability/u);
  assert.match(patchText, /Dispatch the marker before observe/u);

  const bootstrap = readFileSync(
    path.join(repo, 'deploy/freekill-native/scripts/bootstrap-source.sh'), 'utf8');
  const baseline = readFileSync(path.join(repo, 'deploy/freekill-native/upstream-baseline.env'), 'utf8');
  assert.match(bootstrap, /tqs-card-wire-candidate-native-bridge/u,
    'production bootstrap must apply the card-wire bridge');
  assert.match(baseline, /TQS_UPSTREAM_PATCH_CARD_WIRE_PATH/u,
    'production baseline must pin the card-wire bridge');

  if (!existsSync(path.join(upstream, '.git'))) {
    t.skip('pinned native source checkout is not prepared');
    return;
  }

  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-card-wire-native-source-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'freekill-asio');
  extractPinnedNativeSource(source);
  for (const patchFile of productionPatches) applyPatch(source, patchFile);
  assert.doesNotThrow(() => applyPatch(source, candidatePatch, true),
    'candidate bridge must apply cleanly after production source patches');
  applyPatch(source, candidatePatch);

  const rpcLua = readFileSync(path.join(source, 'src/server/rpc-lua/rpc-lua.cpp'), 'utf8');
  const lobby = readFileSync(path.join(source, 'src/server/room/lobby.cpp'), 'utf8');
  const room = readFileSync(path.join(source, 'src/server/room/room.cpp'), 'utf8');
  const roomHeader = readFileSync(path.join(source, 'src/server/room/room.h'), 'utf8');
  assert.match(rpcLua, /return ::kill\(child_pid, 0\) == 0 \|\| errno == EPERM/u);
  assert.match(lobby, /observe && \(sz < 2 \|\| sz > 3\)/u);
  assert.match(lobby, /room->addObserver\(sender, cardWireCapability\)/u);
  assert.ok(room.includes('pushRequest(fmt::format("{},{}", player.getId(), cardWireCapability))'));
  assert.ok(room.includes('pushRequest(fmt::format("{},observe", player.getId()))'));
  assert.ok(roomHeader.includes('addObserver(ServerPlayer &player, std::string_view cardWireCapability = {})'));
});

test('QA native boundary patch parses semantic CBOR with bounded metadata only', (t) => {
  const patchText = readFileSync(nativeBoundaryPatch, 'utf8');
  assert.match(patchText, /TQS_NATIVE_WIRE_METRICS_FILE/u);
  assert.match(patchText, /TQS_NATIVE_WIRE_SERIALIZATION_FILE/u);
  assert.match(patchText, /TQS_NATIVE_WIRE_SEMANTIC_FILE/u);
  assert.match(patchText, /appendNativeWireSemanticRecord/u);
  assert.match(patchText, /nativeWireSemanticAudience/u);
  assert.match(patchText, /cbor_load/u);
  assert.match(patchText, /inbound-reply/u);
  assert.match(patchText, /safeCommand = scope == "inbound-reply" \? "Reply"/u);
  assert.doesNotMatch(patchText, /cbor_describe|stdout|stderr/u,
    'semantic native QA hook must not retain or print payloads');

  if (!existsSync(path.join(upstream, '.git'))) {
    t.skip('pinned native source checkout is not prepared');
    return;
  }
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-card-wire-native-boundary-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'freekill-asio');
  extractPinnedNativeSource(source);
  for (const patchFile of productionPatches) {
    try { applyPatch(source, patchFile); } catch { /* source may already carry the production patch */ }
  }
  assert.doesNotThrow(() => applyPatch(source, nativeBoundaryPatch, true),
    'QA native boundary patch must apply cleanly to the prepared upstream source');
});


test('native socket patches apply after the complete production patch sequence', (t) => {
  if (!existsSync(path.join(upstream, '.git'))) {
    t.skip('pinned native source checkout is not prepared');
    return;
  }
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-native-stream-source-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'freekill-asio');
  extractPinnedNativeSource(source);
  const patchDir = path.dirname(candidatePatch);
  for (const patchFile of [...productionPatches, candidatePatch,
    path.join(patchDir, 'tqs-card-wire-snapshot-compression.patch'),
    path.join(patchDir, 'tqs-client-socket-stream.patch'),
    path.join(patchDir, 'tqs-native-socket-lifecycle.patch')]) {
    applyPatch(source, patchFile, true);
    applyPatch(source, patchFile);
  }
  const socket = readFileSync(path.join(source, 'src/network/client_socket.cpp'), 'utf8');
  assert.ok(socket.includes('handled = builder.handled;'));
  assert.ok(socket.includes('cborBuffer.erase(cborBuffer.begin(), cborBuffer.begin() + real_consumed);'));
  assert.ok(!socket.includes('real_consumed < len'));
  for (const name of ['tqs-client-socket-stream.patch', 'tqs-native-socket-lifecycle.patch']) {
    execFileSync('patch', ['--dry-run', '--force', '--reverse', '-p1', '-d', source,
      '-i', path.join(patchDir, name)], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  }
});
