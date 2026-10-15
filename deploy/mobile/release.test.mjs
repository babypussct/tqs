import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { packageRelease, publicFlist, REQUIRED_PACKAGES } from './package-release.mjs';
import { verifyRelease } from './verify-release.mjs';
import { createReleaseEvidence } from './release-checkpoint.mjs';

const repo = path.resolve(new URL('../..', import.meta.url).pathname);

test('mobile release packaging is deterministic and tamper evident', () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-release-'));
  try {
    const runtime = path.join(temp, 'runtime');
    for (const name of REQUIRED_PACKAGES) {
      fs.mkdirSync(path.join(runtime, 'packages', name, 'lua'), { recursive: true });
      fs.writeFileSync(path.join(runtime, 'packages', name, 'lua', `${name}.lua`), `return '${name}'\n`);
    }
    fs.writeFileSync(path.join(runtime, 'flist.txt'), 'fixture-flist\n');
    const first = path.join(temp, 'release-a');
    const second = path.join(temp, 'release-b');
    const a = packageRelease(runtime, first, { createdAt: '2026-01-01T00:00:00.000Z' });
    const b = packageRelease(runtime, second, { createdAt: '2026-01-01T00:00:00.000Z' });
    assert.deepEqual(a.manifest, b.manifest);
    assert.equal(a.manifest.schemaVersion, 2);
    assert.deepEqual(verifyRelease(first).manifest, a.manifest);

    fs.appendFileSync(path.join(first, 'dist/index.html'), '\n<!-- tamper -->\n');
    assert.throws(() => verifyRelease(first), /Hash mismatch: dist\/index\.html/);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test('mobile release packaging rejects the server-only QA package', () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-release-server-only-'));
  try {
    const runtime = path.join(temp, 'runtime');
    for (const name of [...REQUIRED_PACKAGES, 'tqs_qa']) {
      fs.mkdirSync(path.join(runtime, 'packages', name), { recursive: true });
      fs.writeFileSync(path.join(runtime, 'packages', name, 'init.lua'), `return '${name}'\n`);
    }
    fs.writeFileSync(path.join(runtime, 'flist.txt'), 'fixture-flist\n');
    assert.throws(() => packageRelease(runtime, path.join(temp, 'release')), /Server-only packages/);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test('mobile release packaging strips server-only entries from the public flist identity', () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-release-public-flist-'));
  try {
    const runtime = path.join(temp, 'runtime');
    for (const name of REQUIRED_PACKAGES) {
      fs.mkdirSync(path.join(runtime, 'packages', name), { recursive: true });
      fs.writeFileSync(path.join(runtime, 'packages', name, 'init.lua'), `return '${name}'\n`);
    }
    const sourceFlist = 'packages/tqs_qa/init.lua=old;packages/hegemony/init.lua=stable;';
    fs.writeFileSync(path.join(runtime, 'flist.txt'), sourceFlist);
    const release = path.join(temp, 'release');
    const result = packageRelease(runtime, release, { createdAt: '2026-01-01T00:00:00.000Z' });
    assert.equal(publicFlist(sourceFlist), 'packages/hegemony/init.lua=stable;');
    assert.equal(fs.readFileSync(path.join(release, 'runtime/flist.txt'), 'utf8'),
      'packages/hegemony/init.lua=stable;');
    assert.deepEqual(verifyRelease(release).manifest, result.manifest);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

assert.ok(fs.existsSync(path.join(repo, 'game/web/dist/index.html')), 'release test must run after web build');

test('release checkpoint holds dirty source and never implies official release', () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-release-evidence-'));
  try {
    const releaseRoot = path.join(temp, 'release');
    fs.mkdirSync(releaseRoot, { recursive: true });
    const manifest = {
      schemaVersion: 2,
      createdAt: '2026-01-01T00:00:00.000Z',
      runtimeMD5: '00000000000000000000000000000000',
      packages: [...REQUIRED_PACKAGES].sort(),
      runtimeFileCount: 1,
      webFileCount: 1,
      gatewayFileCount: 1,
      files: { 'dist/index.html': 'a'.repeat(64) },
    };
    fs.writeFileSync(path.join(releaseRoot, 'RELEASE.json'), `${JSON.stringify(manifest)}\n`);
    const report = createReleaseEvidence({
      releaseRoot,
      manifest,
      gitState: { branch: 'main', commit: 'deadbeef', dirty: true, changedFileCount: 1 },
      generatedAt: '2026-01-01T00:00:00.000Z',
      diffCheck: 'PASS',
    });
    assert.equal(report.status, 'HOLD');
    assert.equal(report.publishEligible, false);
    assert.equal(report.safety.deployed, false);
    assert.equal(report.gates.officialRelease, 'PENDING');
    assert.equal(report.gates.physicalDeviceAndNetwork, 'WAIVED_BY_USER');
    assert.equal(report.gates.nodeForgeAdvisory, 'RISK_ACCEPTED_WITH_SCOPE');
    assert.match(report.holdReasons.join('\n'), /source checkout is dirty/);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});
