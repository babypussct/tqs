import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from 'node:net';
import { generateKeyPairSync } from 'node:crypto';
import { inspect, updateState, runWatch, probeNativeChallenge } from './oracle-gateway-watch.mjs';

const manifest = { md5: 'a'.repeat(32), bundleHash: 'b'.repeat(16), fileCount: 5281 };
const invocation = 'c'.repeat(32);
const systemctl = (...args) => args[0] === 'show' ? invocation : 'active';
const fetchOk = async url => new Response(url.endsWith('manifest.json') ? JSON.stringify(manifest) : 'ok');
const nativeOk = async () => {};
const nativeMeta = { nativeChallenge: true, nativeInvocation: 'e'.repeat(32) };

function cborBytes(bytes) {
  const header = Buffer.alloc(3);
  header[0] = 0x59;
  header.writeUInt16BE(bytes.length, 1);
  return Buffer.concat([header, bytes]);
}

const { publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048,
  publicKeyEncoding: { type: 'pkcs1', format: 'pem' } });
const challenge = Buffer.concat([Buffer.from([0x84, 0x21, 0x19, 0x04, 0x21, 0x50]),
  Buffer.from('NetworkDelayTest'), cborBytes(cborBytes(Buffer.from(publicKey)))]);

async function withNativeServer(onConnection, check) {
  const sockets = new Set();
  const server = createServer(socket => {
    sockets.add(socket);
    socket.on('close', () => sockets.delete(socket));
    socket.on('error', () => {});
    onConnection(socket);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    await check({ port: server.address().port, timeoutMs: 300 });
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => server.close(resolve));
  }
}

test('native probe accepts a complete challenge fragmented across TCP reads', async () => {
  await withNativeServer(socket => {
    socket.write(challenge.subarray(0, 25));
    setTimeout(() => socket.write(challenge.subarray(25)), 10);
  }, options => probeNativeChallenge(options));
});

test('native probe rejects stalled accept, incomplete, wrong command and invalid RSA challenge', async () => {
  await withNativeServer(() => {}, options => assert.rejects(probeNativeChallenge(options), /timed out/));
  await withNativeServer(socket => socket.end(challenge.subarray(0, 25)),
    options => assert.rejects(probeNativeChallenge(options), /incomplete/));
  await withNativeServer(socket => socket.end(Buffer.from('ok')),
    options => assert.rejects(probeNativeChallenge(options), /Invalid native challenge/));
  const bad = Buffer.from(challenge);
  bad.fill(0, 30);
  await withNativeServer(socket => socket.end(bad),
    options => assert.rejects(probeNativeChallenge(options), /Invalid native challenge/));
});

test('inspects local and public gateway health and identical manifest', async () => {
  const result = await inspect({ fetchImpl: fetchOk, runSystemctl: systemctl, nativeProbe: nativeOk });
  assert.equal(result.manifestMd5, manifest.md5);
  assert.equal(result.invocation, invocation);
  assert.equal(result.nativeChallenge, true);
  await assert.rejects(() => inspect({ fetchImpl: async url =>
    new Response(url.startsWith('https:') && url.endsWith('manifest.json')
      ? JSON.stringify({ ...manifest, fileCount: 1 })
      : url.endsWith('manifest.json') ? JSON.stringify(manifest) : 'ok'),
  runSystemctl: systemctl, nativeProbe: nativeOk }), /manifest mismatch/);
  await assert.rejects(() => inspect({ fetchImpl: fetchOk,
    nativeProbe: nativeOk, runSystemctl: (...args) => args[0] === 'is-active' && args[1] === 'tqs-gateway.service' ? 'inactive' : systemctl(...args) }),
  /not active/);
});

test('3 consecutive failures trigger one alert, recovery resets alarm, restart updates time', () => {
  let state = {};
  const start = Date.parse('2026-10-23T00:00:00Z');
  for (let i = 0; i < 3; i++) {
    const out = updateState(state, { ok: false, code: 'unreachable' }, start + i * 60_000);
    state = out.next;
    assert.equal(out.alert, i === 2 ? 'down' : null);
  }
  assert.equal(state.alertedDown, true);
  assert.equal(updateState(state, { ok: false, code: 'unreachable' }, start + 180_000).alert, null);
  let out = updateState(state, { ok: true, meta: { ...nativeMeta, invocation, service: 'tqs-named-tunnel.service' } }, start + 240_000);
  assert.equal(out.alert, 'recovered');
  state = out.next;
  assert.equal(state.status, 'up');
  const since = state.healthySince;
  out = updateState(state, { ok: true, meta: { ...nativeMeta, invocation, service: 'tqs-named-tunnel.service' } }, start + 300_000);
  assert.equal(out.next.healthySince, since);
  out = updateState(out.next, { ok: true, meta: { ...nativeMeta, invocation: 'd'.repeat(32), service: 'tqs-named-tunnel.service' } }, start + 360_000);
  assert.notEqual(out.next.healthySince, since);
  assert.equal(out.next.tunnelRestartedAt, out.next.lastCheckedAt);
  const afterGap = updateState(out.next,
    { ok: true, meta: { ...nativeMeta, invocation: 'd'.repeat(32), service: 'tqs-named-tunnel.service' } },
    start + 900_000);
  assert.equal(afterGap.next.healthySince, afterGap.next.lastCheckedAt);
  assert.equal(afterGap.next.consecutiveSuccesses, 1);
});

test('24h acceptance requires named tunnel, 1440 samples, no gap or restart', () => {
  const start = Date.parse('2026-10-23T00:00:00Z');
  const named = { ok: true, meta: { ...nativeMeta, invocation, service: 'tqs-named-tunnel.service' } };
  const quick = { ok: true, meta: { ...nativeMeta, invocation, service: 'tqs-quick-tunnel.service' } };
  let state = {};
  for (let i = 0; i <= 1440; i++) {
    state = updateState(state, quick, start + i * 60_000).next;
  }
  assert.equal(state.acceptance24h, false, '24h on Quick never certifies Named Tunnel');
  state = updateState(state, named, start + 1441 * 60_000).next;
  assert.equal(state.consecutiveSuccesses, 1, 'switching tunnel resets the window');
  for (let i = 1; i <= 1440; i++) {
    state = updateState(state, named, start + (1441 + i) * 60_000).next;
    if (i < 1440) assert.equal(state.acceptance24h, false);
  }
  assert.equal(state.acceptance24h, true);
  const restart = updateState(state,
    { ok: true, meta: { ...named.meta, invocation: 'd'.repeat(32) } },
    start + 2882 * 60_000).next;
  assert.equal(restart.acceptance24h, false);
  assert.equal(restart.consecutiveSuccesses, 1);
  const gap = updateState(state, named, start + 2890 * 60_000).next;
  assert.equal(gap.acceptance24h, false);
  assert.equal(gap.consecutiveSuccesses, 1);
  const backwardsClock = updateState(state, named, start + 2880 * 60_000).next;
  assert.equal(backwardsClock.acceptance24h, false);
  const nativeRestart = updateState(state,
    { ok: true, meta: { ...named.meta, nativeInvocation: 'f'.repeat(32) } }, start + 2882 * 60_000).next;
  assert.equal(nativeRestart.acceptance24h, false);
  assert.equal(nativeRestart.consecutiveSuccesses, 1);
  assert.equal(nativeRestart.nativeRestartedAt, nativeRestart.lastCheckedAt);
  const legacyState = { ...state };
  delete legacyState.nativeChallenge;
  delete legacyState.nativeInvocation;
  const upgrade = updateState(legacyState, named, start + 2882 * 60_000).next;
  assert.equal(upgrade.acceptance24h, false);
  assert.equal(upgrade.consecutiveSuccesses, 1);
});

test('watch writes private bounded status without storing webhooks, survives failure', async () => {
  const temp = mkdtempSync(join(tmpdir(), 'tqs-watch-'));
  try {
    const file = join(temp, 'status.json');
    let out = await runWatch({ file, fetchImpl: fetchOk, runSystemctl: systemctl, nativeProbe: nativeOk, now: 100_000 });
    assert.equal(out.next.status, 'up');
    out = await runWatch({ file, fetchImpl: async () => { throw Error('Sensitive-token-DO-NOT-LOG'); },
      runSystemctl: systemctl, nativeProbe: nativeOk, now: 160_000, webhook: 'https://example.org/no-requests-before-threshold' });
    assert.equal(out.next.status, 'down');
    assert.equal(out.next.nativeChallenge, null);
    const stored = readFileSync(file, 'utf8');
    assert.doesNotMatch(stored, /Sensitive-token|example.org/);
    assert.equal(JSON.parse(stored).consecutiveFailures, 1);
  } finally { rmSync(temp, { recursive: true, force: true }); }
});

test('HTTP and systemd healthy cannot hide a native listener that never sends its challenge', async () => {
  const temp = mkdtempSync(join(tmpdir(), 'tqs-watch-'));
  try {
    const file = join(temp, 'status.json');
    await withNativeServer(() => {}, async options => {
      const out = await runWatch({ file, fetchImpl: fetchOk, runSystemctl: systemctl,
        nativeProbe: () => probeNativeChallenge(options), now: 100_000 });
      assert.equal(out.next.status, 'down');
      assert.equal(out.next.failureCode, 'native-challenge');
      assert.equal(out.next.nativeChallenge, false);
      assert.equal(out.next.acceptance24h, false);
    });
    const out = await runWatch({ file, fetchImpl: fetchOk, runSystemctl: systemctl,
      nativeProbe: nativeOk, now: 160_000 });
    assert.equal(out.next.status, 'up');
    assert.equal(out.next.nativeChallenge, true);
    assert.equal(out.next.failureCode, undefined);
  } finally { rmSync(temp, { recursive: true, force: true }); }
});
