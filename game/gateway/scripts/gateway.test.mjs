import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { once } from 'node:events';
import { test } from 'node:test';
import { unzipSync } from 'fflate';
import WebSocket from 'ws';

const here = path.dirname(fileURLToPath(import.meta.url));

async function reservePort() {
  const socket = net.createServer();
  socket.listen(0, '127.0.0.1');
  await once(socket, 'listening');
  const port = socket.address().port;
  await new Promise((resolve) => socket.close(resolve));
  return port;
}

async function waitForHealth(url, child) {
  for (let i = 0; i < 50; i++) {
    if (child.exitCode !== null) throw new Error(`gateway exited with ${child.exitCode}`);
    try {
      const response = await fetch(`${url}/healthz`);
      if (response.ok && await response.text() === 'ok') return;
    } catch { /* startup may not have reached listen yet */ }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error('local gateway did not start within the test timeout');
}

test('local gateway serves verified versioned bundle and bridges binary WebSocket to TCP', { timeout: 10000 }, async () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-gateway-test-'));
  const fixture = {
    'freekill-core': '-- FreeKill',
    utility: '-- Utility',
    hegemony: '-- Hegemony',
  };
  for (const [name, content] of Object.entries(fixture)) {
    const dir = path.join(root, 'packages', name);
    mkdirSync(dir, { recursive: true });
    writeFileSync(path.join(dir, 'init.lua'), content);
  }
  writeFileSync(path.join(root, 'flist.txt'), 'test-only flist\n');

  const tcpServer = net.createServer((socket) => socket.on('data', (data) => socket.write(data)));
  let child;
  try {
    tcpServer.listen(0, '127.0.0.1');
    await once(tcpServer, 'listening');
    const tcpPort = tcpServer.address().port;
    const httpPort = await reservePort();
    const baseUrl = `http://127.0.0.1:${httpPort}`;
    child = spawn(process.execPath, [path.resolve(here, '../src/server.mjs')], {
      cwd: path.resolve(here, '..'),
      env: { ...process.env, FK_ROOT: root, FK_HOST: '127.0.0.1', FK_PORT: String(tcpPort), PORT: String(httpPort) },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let logs = '';
    child.stdout.on('data', (data) => { logs += String(data); });
    child.stderr.on('data', (data) => { logs += String(data); });
    await waitForHealth(baseUrl, child).catch((error) => { throw new Error(`${error.message}\n${logs}`); });

    const manifestResponse = await fetch(`${baseUrl}/manifest.json`);
    assert.equal(manifestResponse.status, 200);
    assert.equal(manifestResponse.headers.get('cache-control'), 'no-cache');
    const manifest = await manifestResponse.json();
    assert.equal(manifest.md5, createHash('md5').update('test-only flist\n').digest('hex'));
    assert.equal(manifest.fileCount, 3);
    assert.deepEqual(manifest.packages, ['freekill-core', 'hegemony', 'utility']);

    const versioned = await fetch(new URL(manifest.bundle, `${baseUrl}/`));
    assert.equal(versioned.status, 200);
    assert.match(versioned.headers.get('cache-control'), /immutable/);
    const zip = Buffer.from(await versioned.arrayBuffer());
    assert.equal(createHash('sha1').update(zip).digest('hex').slice(0, 16), manifest.bundleHash);
    const unpacked = unzipSync(zip);
    assert.equal(Object.keys(unpacked).length, 3);
    assert.ok(unpacked['packages/hegemony/init.lua']);

    const oldVersion = await fetch(`${baseUrl}/bundle.zip?v=0000000000000000`);
    assert.equal(oldVersion.status, 404);
    const unversioned = await fetch(`${baseUrl}/bundle.zip`);
    assert.equal(unversioned.status, 200);
    assert.equal(unversioned.headers.get('cache-control'), 'no-cache');
    const malformedPath = await fetch(`${baseUrl}/%E0%A4%A`);
    assert.equal(malformedPath.status, 400);
    assert.equal((await fetch(`${baseUrl}/assets/../../flist.txt`)).status, 404);

    const ws = new WebSocket(`ws://127.0.0.1:${httpPort}/ws`);
    try {
      await once(ws, 'open');
      const payload = Buffer.from([0, 0xf6, 0x80, 0xff, 0x01]);
      ws.send(payload);
      const [reply, binary] = await once(ws, 'message');
      assert.equal(binary, true);
      assert.deepEqual(reply, payload);
    } finally {
      ws.terminate();
    }
  } finally {
    if (child && child.exitCode === null) {
      child.kill('SIGTERM');
      await once(child, 'exit');
    }
    await new Promise((resolve) => tcpServer.close(resolve));
    rmSync(root, { recursive: true, force: true });
  }
});
