import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';

const root = fileURLToPath(new URL('../../', import.meta.url));
const gateway = 'http://127.0.0.1:19682';
const secret = process.env.TQS_GAME_TICKET_SECRET ?? '';
const expectedMd5 = process.env.TQS_QA_MANIFEST_MD5 ?? '';
assert.match(secret, /^[a-f0-9]{64}$/);
assert.match(expectedMd5, /^[a-f0-9]{32}$/);
const username = 'tqs_cup_qa_39';
const expiry = Math.floor(Date.now() / 1000) + 120;
const mac = createHmac('sha256', secret).update(`TQS1|${username}|${expiry}`).digest('hex');
const executablePath = [process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium',
].find((path): path is string => !!path && existsSync(path));
assert.ok(executablePath, 'Chrome executable missing');

const vite = await createServer({
  root,
  configFile: false,
  server: { host: '127.0.0.1', port: 19683, strictPort: true },
  plugins: [{
    name: 'skill-parity-preflight',
    configureServer(server) {
      server.middlewares.use('/__skill_parity_preflight', (_request, response) => {
        response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        response.end('<!doctype html><title>Skill parity QA</title>');
      });
    },
  }],
});
let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
let stage = 'launch';
try {
  await vite.listen();
  const base = vite.resolvedUrls?.local[0];
  assert.ok(base);
  browser = await chromium.launch({ executablePath });
  const page = await browser.newPage();
  page.on('websocket', (socket) => {
    socket.on('socketerror', (error) => {
      const category = error.match(/\bERR_[A-Z_]+\b/)?.[0] ?? ['403', '404', '401', 'ECONNREFUSED', 'Unexpected response']
        .find((reason) => error.includes(reason)) ?? 'unclassified';
      console.log(JSON.stringify({ status: 'DIAGNOSTIC', lane: 'browser-preflight', socketError: category }));
    });
  });
  // tsx inserts this helper into callbacks serialized by Playwright.
  await page.addInitScript({ content: 'globalThis.__name ??= (value) => value;' });
  await page.goto(new URL('__skill_parity_preflight', base).href);
  stage = 'browser bundle and Lua login';
  const result = await page.evaluate(async ({ username, ticket, expectedMd5, gateway }) => {
    const [{ loadGatewayBundle }, { GameConnection, webSocketOpener }] = await Promise.all([
      import('../../src/engine/bundle.ts'),
      import('../../src/engine/connection.ts'),
    ]);
    const { files, manifest } = await loadGatewayBundle(gateway, AbortSignal.timeout(15000));
    if (manifest.md5 !== expectedMd5 || manifest.cardWireVersion !== 1 ||
        [...files.keys()].some((path) => path.includes('/tqs_qa/'))) {
      throw new Error('Gateway bundle identity mismatch');
    }
    const ws = new URL('/ws', gateway);
    ws.protocol = 'ws:';
    const uiEvents = new Set<string>();
    let luaErrors = 0;
    const connection = new GameConnection({
      files, username, password: ticket, md5: manifest.md5, uuid: crypto.randomUUID(),
      wasmUrl: '/glue.wasm', openSocket: webSocketOpener(ws.href),
      onUi: (command) => { uiEvents.add(command); },
      log: (level) => { if (level === 'error') luaErrors++; },
    });
    try {
      await connection.start();
      const deadline = performance.now() + 15000;
      while (connection.getStatus().kind !== 'online' && performance.now() < deadline) {
        if (connection.getStatus().kind === 'closed') break;
        await new Promise((resolve) => setTimeout(resolve, 50));
      }
      const status = connection.getStatus();
      const closeReason = status.kind === 'closed'
        ? ['closed (1006)', 'backend closed', 'invalid packet stream', 'Lua runtime error', 'connect timeout']
          .find((reason) => status.reason === reason) ?? 'unclassified'
        : null;
      return {
        online: status.kind === 'online',
        connection: status.kind,
        closeReason,
        errorDialog: uiEvents.has('ErrorDlg'),
        lobby: uiEvents.has('EnterLobby'),
        luaErrors,
        files: files.size,
        bundleHash: manifest.bundleHash,
        expectedOrigin: location.origin === 'http://127.0.0.1:19683',
      };
    } finally {
      connection.close();
    }
  }, { username, ticket: `TQS1|${expiry}|${mac}`, expectedMd5, gateway });
  if (!result.online || !result.lobby || result.luaErrors) {
    console.log(JSON.stringify({ status: 'DIAGNOSTIC', lane: 'browser-preflight', ...result }));
    throw new Error('Native lobby unavailable');
  }
  console.log(JSON.stringify({ status: 'PASS', lane: 'browser-preflight', ...result }));
} catch (error) {
  const message = error instanceof Error ? error.message : '';
  const category = [
    'Failed to fetch dynamically imported module', 'Failed to resolve module specifier',
    'Execution context was destroyed', 'Manifest HTTP', 'Bundle HTTP', 'Gateway bundle identity mismatch',
    'LuaError', 'module not found', 'Native lobby unavailable', 'timeout', '__name is not defined',
    'Unexpected token', '404', 'does not provide an export', 'attempt to', 'cannot open', 'Failed to fetch',
  ].find((reason) => message.includes(reason)) ?? 'other';
  console.log(JSON.stringify({ status: 'DIAGNOSTIC', lane: 'browser-preflight', stage, category }));
  process.exitCode = 1;
} finally {
  await browser?.close();
  await vite.close();
}
