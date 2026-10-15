import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { verifyCandidateIdentity, verifyQaPackageManifest } from './identity';

function sha256(value: string) {
  return createHash('sha256').update(value).digest('hex');
}

function md5(value: string) {
  return createHash('md5').update(value).digest('hex');
}

function fixture() {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-live-identity-'));
  const runtime = path.join(root, 'runtime');
  const dist = path.join(root, 'dist');
  mkdirSync(path.join(runtime, 'packages', 'freekill-core'), { recursive: true });
  mkdirSync(path.join(runtime, 'qa_packages', 'tqs_qa'), { recursive: true });
  mkdirSync(dist, { recursive: true });
  const flist = 'fixture-flist\n';
  const index = '<!doctype html><title>candidate</title>\n';
  writeFileSync(path.join(runtime, 'flist.txt'), flist);
  writeFileSync(path.join(dist, 'index.html'), index);
  const manifestPath = path.join(root, 'RELEASE.json');
  writeFileSync(manifestPath, JSON.stringify({ schemaVersion: 2, runtimeMD5: md5(flist),
    packages: ['freekill-core'], files: { 'dist/index.html': sha256(index) } }));
  return { root, runtime, dist, releaseManifestPath: manifestPath, flist, index };
}

test('candidate identity pins local release and ignores server-only tqs_qa', async () => {
  const value = fixture();
  try {
    const identity = await verifyCandidateIdentity(value);
    assert.deepEqual(identity.localPackages, ['freekill-core']);
    assert.deepEqual(identity.localServerOnlyPackages, ['tqs_qa']);
    assert.equal(identity.runtimeMD5, md5(value.flist));
    assert.equal(identity.distIndexSha256, sha256(value.index));
  } finally {
    rmSync(value.root, { recursive: true, force: true });
  }
});

test('candidate identity rejects an unpinned run and a stale hosted candidate', async () => {
  const value = fixture();
  const server = createServer((request, response) => {
    if (request.url === '/gateway/manifest.json') {
      response.setHeader('content-type', 'application/json');
      response.end(JSON.stringify({ md5: '00000000000000000000000000000000', packages: ['freekill-core'] }));
    } else response.end(value.index);
  });
  try {
    await assert.rejects(() => verifyCandidateIdentity({ runtime: value.runtime, dist: value.dist }), /TQS_RELEASE_MANIFEST/);
    server.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const address = server.address();
    assert.ok(address && typeof address === 'object');
    await assert.rejects(() => verifyCandidateIdentity({ ...value, releaseManifestPath: undefined,
      deploymentUrl: `http://127.0.0.1:${address.port}`, allowUnpinned: true, fetchImpl: fetch }), /runtime MD5 is stale/);
  } finally {
    server.close();
    rmSync(value.root, { recursive: true, force: true });
  }
});

test('candidate identity accepts a matching hosted candidate', async () => {
  const value = fixture();
  const server = createServer((request, response) => {
    if (request.url === '/gateway/manifest.json') {
      response.setHeader('content-type', 'application/json');
      response.end(JSON.stringify({ md5: md5(value.flist), packages: ['freekill-core'], bundleHash: 'bundle-test', fileCount: 1 }));
    } else response.end(value.index);
  });
  try {
    server.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const address = server.address();
    assert.ok(address && typeof address === 'object');
    const identity = await verifyCandidateIdentity({ ...value, deploymentUrl: `http://127.0.0.1:${address.port}` });
    assert.equal(identity.remoteIndexSha256, sha256(value.index));
    assert.equal(identity.remoteGatewayManifest?.bundleHash, 'bundle-test');
  } finally {
    server.close();
    rmSync(value.root, { recursive: true, force: true });
  }
});

test('native QA identity requires a verified package revision', () => {
  const value = fixture();
  const qaManifestPath = path.join(value.root, 'tqs_qa.package.manifest.json');
  try {
    writeFileSync(qaManifestPath, JSON.stringify({ schemaVersion: 1, package: 'tqs_qa', status: 'verified',
      sourceRevision: 'a'.repeat(40), catalogSha256: 'b'.repeat(64), packageSha256: 'c'.repeat(64) }));
    const identity = verifyQaPackageManifest({ manifestPath: qaManifestPath, expectedRevision: 'a'.repeat(40) });
    assert.equal(identity.sourceRevision, 'a'.repeat(40));
    assert.throws(() => verifyQaPackageManifest({ manifestPath: qaManifestPath, expectedRevision: 'd'.repeat(40) }), /does not match/);
  } finally {
    rmSync(value.root, { recursive: true, force: true });
  }
});
