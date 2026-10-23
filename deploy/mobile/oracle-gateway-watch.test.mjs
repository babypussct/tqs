import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { inspect, updateState, runWatch } from './oracle-gateway-watch.mjs';

const manifest = { md5: 'a'.repeat(32), bundleHash: 'b'.repeat(16), fileCount: 5281 };
const invocation = 'c'.repeat(32);
const systemctl = (...args) => args[0] === 'show' ? invocation : 'active';
const fetchOk = async url => new Response(url.endsWith('manifest.json') ? JSON.stringify(manifest) : 'ok');

test('inspects local and public gateway health and identical manifest', async () => {
  const result = await inspect({ fetchImpl: fetchOk, runSystemctl: systemctl });
  assert.equal(result.manifestMd5, manifest.md5);
  assert.equal(result.invocation, invocation);
  await assert.rejects(() => inspect({ fetchImpl: async url =>
    new Response(url.startsWith('https:') && url.endsWith('manifest.json')
      ? JSON.stringify({ ...manifest, fileCount: 1 })
      : url.endsWith('manifest.json') ? JSON.stringify(manifest) : 'ok'),
  runSystemctl: systemctl }), /manifest mismatch/);
  await assert.rejects(() => inspect({ fetchImpl: fetchOk,
    runSystemctl: (...args) => args[0] === 'is-active' && args[1] === 'tqs-gateway.service' ? 'inactive' : systemctl(...args) }),
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
  let out = updateState(state, { ok: true, meta: { invocation, service: 'tqs-named-tunnel.service' } }, start + 240_000);
  assert.equal(out.alert, 'recovered');
  state = out.next;
  assert.equal(state.status, 'up');
  const since = state.healthySince;
  out = updateState(state, { ok: true, meta: { invocation, service: 'tqs-named-tunnel.service' } }, start + 300_000);
  assert.equal(out.next.healthySince, since);
  out = updateState(out.next, { ok: true, meta: { invocation: 'd'.repeat(32), service: 'tqs-named-tunnel.service' } }, start + 360_000);
  assert.notEqual(out.next.healthySince, since);
  assert.equal(out.next.tunnelRestartedAt, out.next.lastCheckedAt);
  const afterGap = updateState(out.next,
    { ok: true, meta: { invocation: 'd'.repeat(32), service: 'tqs-named-tunnel.service' } },
    start + 900_000);
  assert.equal(afterGap.next.healthySince, afterGap.next.lastCheckedAt);
  assert.equal(afterGap.next.consecutiveSuccesses, 1);
});

test('24h acceptance requires named tunnel, 1440 samples, no gap or restart', () => {
  const start = Date.parse('2026-10-23T00:00:00Z');
  const named = { ok: true, meta: { invocation, service: 'tqs-named-tunnel.service' } };
  const quick = { ok: true, meta: { invocation, service: 'tqs-quick-tunnel.service' } };
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
});

test('watch writes private bounded status without storing webhooks, survives failure', async () => {
  const temp = mkdtempSync(join(tmpdir(), 'tqs-watch-'));
  try {
    const file = join(temp, 'status.json');
    let out = await runWatch({ file, fetchImpl: fetchOk, runSystemctl: systemctl, now: 100_000 });
    assert.equal(out.next.status, 'up');
    out = await runWatch({ file, fetchImpl: async () => { throw Error('Sensitive-token-DO-NOT-LOG'); },
      runSystemctl: systemctl, now: 160_000, webhook: 'https://example.org/no-requests-before-threshold' });
    assert.equal(out.next.status, 'down');
    const stored = readFileSync(file, 'utf8');
    assert.doesNotMatch(stored, /Sensitive-token|example.org/);
    assert.equal(JSON.parse(stored).consecutiveFailures, 1);
  } finally { rmSync(temp, { recursive: true, force: true }); }
});
