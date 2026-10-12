import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync } from 'node:fs';
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
  const secret = path.join(root, 'outside.png');
  writeFileSync(secret, 'NOT_PUBLIC');
  symlinkSync(secret, path.join(root, 'packages', 'hegemony', 'escape.png'));
  symlinkSync(secret, path.join(root, 'packages', 'hegemony', 'escape.lua'));

  const webDist = path.join(root, 'web');
  mkdirSync(path.join(webDist, 'assets'), { recursive: true });
  writeFileSync(path.join(webDist, 'index.html'), '<h1>Frozen build</h1>');
  writeFileSync(path.join(webDist, 'assets/app-123.js'), 'console.log(1)');
  symlinkSync(secret, path.join(webDist, 'escape.svg'));
  symlinkSync(secret, path.join(webDist, 'escape.png'));
  const iconBytes = readFileSync(path.resolve(here,'../../web/public/icon-192.png'));
  writeFileSync(path.join(webDist,'icon-192.png'),iconBytes);

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
      env: { ...process.env, WEB_DIST: webDist, FK_ROOT: root, FK_HOST: '127.0.0.1', FK_PORT: String(tcpPort), PORT: String(httpPort), ALLOW_ORIGIN: 'https://game.example.com', MAX_WS_PER_IP: '1', TRUSTED_PROXIES: '' },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let logs = '';
    child.stdout.on('data', (data) => { logs += String(data); });
    child.stderr.on('data', (data) => { logs += String(data); });
    await waitForHealth(baseUrl, child).catch((error) => { throw new Error(`${error.message}\n${logs}`); });

    assert.equal(await (await fetch(baseUrl)).text(), '<h1>Frozen build</h1>');
    assert.equal((await fetch(`${baseUrl}/gateway/healthz`)).status,200);
    assert.equal((await fetch(`${baseUrl}/assets/app-123.js`)).headers.get('content-type'),'text/javascript; charset=utf-8');
    const icon = await fetch(`${baseUrl}/icon-192.png`);
    assert.equal(icon.headers.get('content-type'),'image/png');
    assert.deepEqual(Buffer.from(await icon.arrayBuffer()),iconBytes);
    assert.equal((await fetch(`${baseUrl}/escape.png`)).status,404);
    assert.equal((await fetch(`${baseUrl}/escape.svg`)).status,404);
    assert.equal((await fetch(`${baseUrl}/.env`)).status,404);
    assert.equal((await fetch(`${baseUrl}/assets/hegemony/escape.png`)).status,404);
    assert.equal((await fetch(`${baseUrl}/healthz`,{headers:{Origin:'https://evil.example'}})).status,403);
    const allowed = await fetch(`${baseUrl}/healthz`,{headers:{Origin:'https://game.example.com'}});
    assert.equal(allowed.headers.get('access-control-allow-origin'),'https://game.example.com');
    assert.equal(allowed.headers.get('x-content-type-options'),'nosniff');
    const rejected = new WebSocket(`ws://127.0.0.1:${httpPort}/ws`, {origin:'https://evil.example'});
    const rejectedError = once(rejected,'error');
    const [error] = await rejectedError;
    assert.match(error.message,/403/);
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

    const ws = new WebSocket(`ws://127.0.0.1:${httpPort}/gateway/ws`, {origin:'https://game.example.com',headers:{'x-forwarded-for':'198.51.100.1'}});
    try {
      await once(ws, 'open');
      const second = new WebSocket(`ws://127.0.0.1:${httpPort}/ws`, {origin:'https://game.example.com',headers:{'x-forwarded-for':'198.51.100.2'}});
      await once(second,'open');
      const [code] = await once(second,'close');
      assert.equal(code,1008,'spoofed IP must not evade the shared peer limit');
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

test('global websocket cap rejects excess clients and flood closes only its connection', { timeout: 10000 }, async () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-gateway-cap-'));
  const backend = net.createServer(socket => socket.on('data', () => {}));
  const peers = [];let child;
  try {
    backend.listen(0,'127.0.0.1');await once(backend,'listening');
    const port = await reservePort();
    child=spawn(process.execPath,[path.resolve(here,'../src/server.mjs')],{env:{...process.env,WEB_DIST:'',
      FK_ROOT:root,FK_HOST:'127.0.0.1',FK_PORT:String(backend.address().port),PORT:String(port),BIND_HOST:'127.0.0.1',
      ALLOW_ORIGIN:'https://game.example.com',TRUSTED_PROXIES:'',MAX_CONNECTIONS:'3',MAX_WS_PER_IP:'3'},stdio:'ignore'});
    await waitForHealth(`http://127.0.0.1:${port}`,child);
    for(let i=0;i<3;i++) {const ws=new WebSocket(`ws://127.0.0.1:${port}/ws`,{origin:'https://game.example.com'});
      peers.push(ws);await once(ws,'open');}
    const extra = new WebSocket(`ws://127.0.0.1:${port}/ws`,{origin:'https://game.example.com'});
    const [error] = await once(extra,'error');assert.match(error.message,/503/);
    const closed = once(peers[0],'close');
    // 200 small messages in one event-loop burst exceeds the configured default 120-message bucket.
    for(let i=0;i<200;i++) peers[0].send(Buffer.from([0x80]));
    const [code, reason] = await closed;assert.equal(code,1000);assert.equal(reason.toString(),'traffic limit exceeded');
    assert.equal(peers[1].readyState,WebSocket.OPEN);assert.equal(peers[2].readyState,WebSocket.OPEN);
  } finally {
    for(const peer of peers) peer.terminate();
    if(child && child.exitCode===null){child.kill('SIGTERM');await once(child,'exit');}
    await new Promise(resolve=>backend.close(resolve));rmSync(root,{recursive:true,force:true});
  }
});
