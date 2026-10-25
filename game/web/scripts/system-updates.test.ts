import assert from 'node:assert/strict';
import { test } from 'node:test';
import { UpdateCoordinator, useUpdateStore } from '../src/system/updates';
import { parseBuild, buildLabel, buildComparisonLabels, type BuildInfo } from '../src/system/buildInfo';
import { signalView } from '../src/system/Signal';
import { GameAdapter } from '../src/engine/gameAdapter';
const build: BuildInfo = { version: '0.5.25', buildId: 'a'.repeat(64), swVersion: 'a'.repeat(64), builtAt: '2026-10-24T12:00:00.000Z' };
const manifest = { md5: 'b'.repeat(32), bundleHash: 'c'.repeat(16), bundle: `bundle.zip?v=${'c'.repeat(16)}`, packages: ['freekill-core', 'hegemony', 'utility'], fileCount: 3 };
function setup(changes: { build?: BuildInfo; md5?: string; bundleHash?: string; fail?: boolean } = {}) {
  useUpdateStore.setState({ pending: false, latest: null, reason: '', checking: false, applying: false, error: null, checkedAt: null });
  let playing = false, reloads = 0, calls = 0;
  const coordinator = new UpdateCoordinator({ gateway: '/gateway', build, webChecks: true,
    manifest: () => manifest, playing: () => playing, reload: () => { reloads++; },
    fetch: async (url) => {
      calls++;
      if (changes.fail) throw new Error('unavailable');
      const updated = { ...manifest, ...(changes.md5 ? { md5: changes.md5 } : {}), ...(changes.bundleHash ? { bundleHash: changes.bundleHash, bundle: `bundle.zip?v=${changes.bundleHash}` } : {}) };
      return new Response(JSON.stringify(url.startsWith('/version') ? changes.build ?? build : updated));
    },
  });
  return { coordinator, playing: (value: boolean) => { playing = value; }, reloads: () => reloads, calls: () => calls };
}
test('signal thresholds, offline and native recovery have truthful precedence', () => {
  for (const [rtt, tone, bars] of [[99, 'good', 3], [100, 'fair', 2], [250, 'fair', 2], [251, 'weak', 1]] as const) {
    const result = signalView({ online: true, rtt, failed: false }, { kind: 'online' }, 'lobby');
    assert.equal(result.tone, tone); assert.equal(result.bars, bars);
  }
  assert.equal(signalView({ online: false, rtt: 1, failed: false }, { kind: 'online' }, 'lobby').bars, 0);
  assert.equal(signalView({ online: true, rtt: 1, failed: true }, { kind: 'online' }, 'lobby').label, 'Mất kết nối');
  assert.equal(signalView({ online: true, rtt: 1, failed: false }, { kind: 'closed', reason: '' }, 'playing').label, 'Đang khôi phục…');
});
test('version parser rejects fallback HTML or malformed releases; date uses Vietnam time', () => {
  assert.deepEqual(parseBuild(build), build);
  assert.throws(() => parseBuild('<html>fallback</html>'));
  assert.throws(() => parseBuild({ ...build, swVersion: 'wrong' }));
  assert.equal(buildLabel(build), 'v0.5.25 · 2410.aaaa');
});
test('matching build and bundle allow entry; checks coalesce', async () => {
  const s = setup(); await Promise.all([s.coordinator.beforeEntry(), s.coordinator.beforeEntry()]);
  assert.equal(s.calls(), 2); assert.equal(useUpdateStore.getState().pending, false);
});
test('new web build, bundle hash and native MD5 independently block entry', async () => {
  for (const changes of [{ build: { ...build, buildId: 'd'.repeat(64), swVersion: 'd'.repeat(64) } }, { md5: 'e'.repeat(32) }, { bundleHash: 'f'.repeat(16) }]) {
    const s = setup(changes); await assert.rejects(s.coordinator.beforeEntry(), /Có bản mới/);
    assert.equal(useUpdateStore.getState().pending, true); assert.equal(s.reloads(), 0);
  }
});
test('failed checks block entry without inventing a release or purging storage', async () => {
  const s = setup({ fail: true }); await assert.rejects(s.coordinator.beforeEntry(), /Chưa kiểm tra/);
  await s.coordinator.apply(true);
  assert.equal(useUpdateStore.getState().pending, false); assert.equal(s.reloads(), 0);
});
test('playing defers manual and forced updates; after GameOver only shell caches are purged', async () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, 'caches');
  const deleted: string[] = [];
  Object.defineProperty(globalThis, 'caches', { configurable: true, value: {
    keys: async () => ['tqs-shell-old', 'shop-cache', 'firebase-auth'],
    delete: async (key: string) => { deleted.push(key); return true; },
  } });
  try {
    const s = setup({ md5: 'e'.repeat(32) }); s.playing(true);
    await s.coordinator.check(); await s.coordinator.apply(true); await s.coordinator.apply();
    assert.equal(useUpdateStore.getState().pending, true); assert.deepEqual(deleted, []); assert.equal(s.reloads(), 0);
    s.playing(false); await s.coordinator.apply();
    assert.deepEqual(deleted, ['tqs-shell-old']); assert.equal(s.reloads(), 1);
  } finally { if (previous) Object.defineProperty(globalThis, 'caches', previous); else Reflect.deleteProperty(globalThis, 'caches'); }
});
test('entry guard prevents native login/create/join/observe before sending packets', async () => {
  let calls = 0;
  const adapter = new GameAdapter('/gateway', async () => { calls++; throw new Error('update-required'); });
  await assert.rejects(adapter.login({} as never), /update-required/);
  await assert.rejects(adapter.createRoom('Test', 2), /update-required/);
  await assert.rejects(adapter.joinRoom(1), /update-required/);
  await assert.rejects(adapter.observeRoom(1), /update-required/);
  assert.equal(calls, 4);
});
test('a coalesced boot request cannot bypass the newly loaded Lua identity', async () => {
  useUpdateStore.setState({ pending: false, error: null });
  let loaded: typeof manifest | null = null;
  let release!: () => void;
  const gate = new Promise<void>((resolve) => { release = resolve; });
  const coordinator = new UpdateCoordinator({ gateway: '/gateway', build, webChecks: true,
    manifest: () => loaded, playing: () => false,
    fetch: async (url) => {
      await gate;
      return new Response(JSON.stringify(url.startsWith('/version') ? build : { ...manifest, md5: 'e'.repeat(32) }));
    },
  });
  const boot = coordinator.check();
  loaded = manifest;
  const entry = coordinator.beforeEntry();
  release(); await boot;
  await assert.rejects(entry, /Có bản mới/);
});
test('waiting worker with matching release metadata does not invent an update', async () => {
  const s = setup();
  const registration = Object.assign(new EventTarget(), { active: {}, waiting: {}, installing: null, update: async () => {} }) as unknown as ServiceWorkerRegistration;
  const remove = s.coordinator.watchRegistration(registration);
  await s.coordinator.beforeEntry();
  assert.equal(useUpdateStore.getState().pending, false);
  assert.equal(useUpdateStore.getState().reason, ''); remove();
});
test('a match that starts while manual check is in flight prevents reload', async () => {
  useUpdateStore.setState({ pending: false, applying: false, error: null });
  let playing = false, reloads = 0;
  let release!: () => void;
  const gate = new Promise<void>((resolve) => { release = resolve; });
  const coordinator = new UpdateCoordinator({ gateway: '/gateway', build, webChecks: true,
    manifest: () => null, playing: () => playing, reload: () => { reloads++; },
    fetch: async () => { await gate; return new Response(JSON.stringify(build)); },
  });
  const applying = coordinator.apply(true); playing = true; release(); await applying;
  assert.equal(reloads, 0); assert.equal(useUpdateStore.getState().applying, false);
});

test('comparison labels distinguish matching short prefixes without changing the compact footer', () => {
  for (const prefix of [4, 12]) {
    const latest = { ...build, buildId: 'a'.repeat(prefix) + 'd'.repeat(64 - prefix) };
    assert.equal(buildLabel(build), buildLabel(latest));
    const labels = buildComparisonLabels(build, latest);
    assert.notEqual(labels[0], labels[1]);
  }
});
test('a confirmed matching release clears a previous web update and stale pending state', async () => {
  const changes = { build: { ...build, buildId: 'd'.repeat(64), swVersion: 'd'.repeat(64) } };
  const s = setup(changes); await s.coordinator.check();
  assert.equal(useUpdateStore.getState().pending, true);
  changes.build = build;
  await s.coordinator.beforeEntry();
  assert.equal(useUpdateStore.getState().pending, false);
  assert.equal(useUpdateStore.getState().reason, '');
});
test('a failed recheck retains a known update; a matching bundle clears only its own update', async () => {
  const changes = { md5: 'e'.repeat(32), fail: false };
  const s = setup(changes); await s.coordinator.check();
  changes.fail = true; await s.coordinator.check();
  assert.equal(useUpdateStore.getState().pending, true);
  changes.fail = false; changes.md5 = manifest.md5;
  await s.coordinator.beforeEntry();
  assert.equal(useUpdateStore.getState().pending, false);
});
test('waiting worker notification still discovers a genuine release difference', async () => {
  const s = setup({ build: { ...build, buildId: 'd'.repeat(64), swVersion: 'd'.repeat(64) } });
  const registration = Object.assign(new EventTarget(), { active: {}, waiting: {}, installing: null, update: async () => {} }) as unknown as ServiceWorkerRegistration;
  const remove = s.coordinator.watchRegistration(registration);
  await assert.rejects(s.coordinator.beforeEntry(), /Có bản mới/);
  assert.equal(useUpdateStore.getState().reason, 'Có bản giao diện mới.'); remove();
});
