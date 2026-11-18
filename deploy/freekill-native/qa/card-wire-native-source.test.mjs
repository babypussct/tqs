import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
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

test('candidate native bridge patch is isolated from production and applies after pinned production patches', (t) => {
  const patchText = readFileSync(candidatePatch, 'utf8');
  assert.match(patchText, /#if defined\(__linux__\)/u);
  assert.match(patchText, /::kill\(child_pid, 0\)/u);
  assert.match(patchText, /cardWireCapability/u);
  assert.match(patchText, /Dispatch the marker before observe/u);

  const bootstrap = readFileSync(
    path.join(repo, 'deploy/freekill-native/scripts/bootstrap-source.sh'), 'utf8');
  const baseline = readFileSync(path.join(repo, 'deploy/freekill-native/upstream-baseline.env'), 'utf8');
  assert.doesNotMatch(bootstrap, /tqs-card-wire-candidate-native-bridge/u,
    'candidate bridge must not enter the production source bootstrap');
  assert.doesNotMatch(baseline, /tqs-card-wire-candidate-native-bridge/u,
    'candidate bridge must not become a production upstream pin');

  if (!existsSync(path.join(upstream, '.git'))) {
    t.skip('pinned native source checkout is not prepared');
    return;
  }

  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-card-wire-native-source-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'freekill-asio');
  cpSync(upstream, source, { recursive: true });
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
  cpSync(upstream, source, { recursive: true });
  for (const patchFile of productionPatches) {
    try { applyPatch(source, patchFile); } catch { /* source may already carry the production patch */ }
  }
  assert.doesNotThrow(() => applyPatch(source, nativeBoundaryPatch, true),
    'QA native boundary patch must apply cleanly to the prepared upstream source');
});
