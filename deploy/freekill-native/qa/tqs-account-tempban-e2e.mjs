#!/usr/bin/env node
/*
 * Focused IPBAN-03 acceptance harness.
 *
 * This is deliberately opt-in and is intended for an isolated native QA
 * candidate only. It uses two independently signed TQS tickets through the
 * same local gateway, abandons account A after StartGame, then verifies that
 * A is rejected while account B can authenticate/reconnect. Credentials,
 * tickets, CBOR payloads and private game state never enter the evidence.
 */
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { execFileSync, spawn } from 'node:child_process';
import { existsSync, mkdtempSync, cpSync, readFileSync, rmSync, statSync } from 'node:fs';
import { loadEnvFile } from 'node:process';
import { once } from 'node:events';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import playwright from '../../../game/web/node_modules/playwright-core/index.js';
import { preview } from 'vite';

const { chromium } = playwright;

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const web = path.join(repo, 'game/web');

assert.equal(process.env.TQS_ACCOUNT_TEMPBAN_E2E, '1',
  'Set TQS_ACCOUNT_TEMPBAN_E2E=1 to opt into the isolated temp-ban E2E');

const configPath = process.env.TQS_LIVE_CONFIG ?? path.join(os.homedir(), '.codex/secrets/tqs-live-test.env');
assert.ok(existsSync(configPath), `Missing private QA config: ${configPath}`);
assert.equal(statSync(configPath).mode & 0o077, 0, 'Private QA config must not be group/world readable');
loadEnvFile(configPath);

const runtime = path.resolve(process.env.TQS_LIVE_ROOT ?? '');
const host = process.env.TQS_LIVE_HOST ?? '';
const nativePort = Number(process.env.TQS_LIVE_PORT ?? '0');
const alias = process.env.TQS_LIVE_QA_SSH_ALIAS ?? '';
const ticketHelper = process.env.TQS_LIVE_TICKET_HELPER ?? '';
const ticketSecret = process.env.TQS_LIVE_TICKET_SECRET ?? '';
const remoteLog = process.env.TQS_LIVE_REMOTE_LOG ?? '';
const localLog = process.env.TQS_LIVE_LOCAL_LOG ?? '';
const remoteSession = process.env.TQS_LIVE_QA_SESSION ?? '';
const tempBanMinutes = Number(process.env.TQS_LIVE_TEMP_BAN_MINUTES ?? '5');
const expectTempBan = process.env.TQS_ACCOUNT_TEMPBAN_EXPECT_LOCK !== '0';
const testExpiry = process.env.TQS_ACCOUNT_TEMPBAN_TEST_EXPIRY === '1';
const testRenewal = process.env.TQS_ACCOUNT_TEMPBAN_TEST_RENEWAL === '1';
const expiryWaitMs = Number(process.env.TQS_ACCOUNT_TEMPBAN_EXPIRY_WAIT_MS ?? '65000');
// Room cleanup may wait for the native offline grace period before emitting
// Temp banned; keep this separate from the ordinary explicit-leave timeout.
const tempBanEventWaitMs = Number(process.env.TQS_ACCOUNT_TEMPBAN_EVENT_WAIT_MS ?? '180000');
const externalGatewayPort = Number(process.env.TQS_LIVE_EXTERNAL_GATEWAY_PORT ?? '0');
const first = { username: process.env.FK_TEST_USERNAME ?? '' };
const secondFile = process.env.TQS_LIVE_SECOND_ACCOUNT_FILE ?? path.join(os.homedir(), '.codex/secrets/tqs-multiplayer-second.json');
assert.ok(runtime && existsSync(path.join(runtime, 'flist.txt')), 'TQS_LIVE_ROOT must contain flist.txt');
assert.match(host, /^[A-Za-z0-9.:-]+$/, 'TQS_LIVE_HOST must be metadata-safe');
assert.ok(Number.isInteger(nativePort) && nativePort > 0 && nativePort <= 65535, 'TQS_LIVE_PORT is invalid');
assert.match(alias, /^[A-Za-z0-9_.@-]{1,128}$/, 'TQS_LIVE_QA_SSH_ALIAS is invalid');
assert.ok(first.username && /^[A-Za-z0-9_-]{1,128}$/.test(first.username), 'First QA account is missing');
assert.ok(existsSync(secondFile), `Missing second QA account file: ${secondFile}`);
assert.equal(statSync(secondFile).mode & 0o077, 0, 'Second QA account file must not be group/world readable');
const second = JSON.parse(readFileSync(secondFile, 'utf8'));
assert.ok(typeof second.username === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(second.username));
assert.notEqual(first.username, second.username);
assert.ok(ticketSecret.length >= 32 || ticketHelper, 'Configure TQS_LIVE_TICKET_SECRET or TQS_LIVE_TICKET_HELPER');
assert.ok(!remoteLog || /^\/[A-Za-z0-9_./-]+$/.test(remoteLog), 'TQS_LIVE_REMOTE_LOG must be an absolute safe path');
assert.ok(!localLog || /^\/[A-Za-z0-9_./-]+$/.test(localLog), 'TQS_LIVE_LOCAL_LOG must be an absolute safe path');
assert.ok(!remoteSession || /^[A-Za-z0-9_.-]{1,80}$/.test(remoteSession), 'TQS_LIVE_QA_SESSION is invalid');
assert.ok(Number.isInteger(tempBanMinutes) && tempBanMinutes >= 0, 'TQS_LIVE_TEMP_BAN_MINUTES is invalid');
assert.ok(Number.isInteger(expiryWaitMs) && expiryWaitMs >= 0, 'TQS_ACCOUNT_TEMPBAN_EXPIRY_WAIT_MS is invalid');
assert.ok(Number.isInteger(tempBanEventWaitMs) && tempBanEventWaitMs >= 0,
  'TQS_ACCOUNT_TEMPBAN_EVENT_WAIT_MS is invalid');
assert.ok(!testRenewal,
  'Live renewal probe is disabled: explicit abandonment produces state=Run and cannot reconnect while banned; use the native temp-ban unit for renewal/stale-timer coverage');
assert.ok(Number.isInteger(externalGatewayPort) && externalGatewayPort >= 0 && externalGatewayPort <= 65535,
  'TQS_LIVE_EXTERNAL_GATEWAY_PORT is invalid');

function ticketFor(nativeName) {
  const expiresAt = Math.floor(Date.now() / 1000) + 600;
  if (ticketSecret.length >= 32) {
    const payload = `TQS1|${nativeName}|${expiresAt}`;
    return `TQS1|${expiresAt}|${createHmac('sha256', ticketSecret).update(payload).digest('hex')}`;
  }
  const ticket = execFileSync(process.execPath, [path.resolve(ticketHelper), nativeName, String(expiresAt)], {
    encoding: 'utf8', timeout: 20_000, maxBuffer: 1024,
    env: { ...process.env, TQS_LIVE_QA_SSH_ALIAS: alias },
  }).trim();
  assert.match(ticket, new RegExp(`^TQS1\\|${expiresAt}\\|[a-f0-9]{64}$`));
  return ticket;
}

async function freePort() {
  const server = net.createServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const port = server.address().port;
  await new Promise((resolve) => server.close(resolve));
  return port;
}

function remoteTempBanCount() {
  if (localLog) {
    try {
      return readFileSync(localLog, 'utf8').split('\n').filter((line) => line.includes('Temp banned')).length;
    } catch {
      return 0;
    }
  }
  if (!remoteLog) return 0;
  try {
    return Number(execFileSync('ssh', ['-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', alias,
      'grep', '-Fc', 'Temp', remoteLog], {
      encoding: 'utf8', timeout: 15_000, maxBuffer: 1024,
    }).trim()) || 0;
  } catch {
    return 0;
  }
}

async function waitForTempBan(before, timeoutMs = 30_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (remoteTempBanCount() > before) return true;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return false;
}

async function waitUntil(timestamp) {
  const delay = timestamp - Date.now();
  if (delay > 0) await new Promise((resolve) => setTimeout(resolve, delay));
}

async function abandonExplicitly(page) {
  const leave = page.getByRole('button', { name: 'Rời trận', exact: true });
  await leave.waitFor({ state: 'visible', timeout: 60_000 });
  await page.waitForFunction(() => {
    const button = Array.from(document.querySelectorAll('button'))
      .find((candidate) => candidate.getAttribute('aria-label') === 'Rời trận');
    return Boolean(button && !button.disabled);
  }, undefined, { timeout: 120_000 });
  await leave.click({ force: true });
  const confirm = page.getByRole('button', { name: 'Vẫn rời trận', exact: true });
  await confirm.waitFor({ state: 'visible', timeout: 30_000 });
  await page.waitForFunction(() => {
    const button = Array.from(document.querySelectorAll('button'))
      .find((candidate) => candidate.textContent?.trim() === 'Vẫn rời trận');
    return Boolean(button && !button.disabled);
  }, undefined, { timeout: 30_000 });
  await confirm.click({ force: true });
}

async function loginPage(browser, account, { expectLobby = true } = {}) {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await context.newPage();
  await page.addInitScript((session) => {
    window.__tqsE2eGameSession = session;
  }, {
    uid: `qa-${account.username}`,
    displayName: account.username,
    nativeName: account.username,
    ticket: ticketFor(account.username),
    expiresAt: Math.floor(Date.now() / 1000) + 600,
    poolPolicy: { schemaVersion: 1, mode: 'new_heg_mode', revision: 0, generalNum: 5,
      disabledPacks: { generals: [], cards: [] }, appliesTo: 'new_rooms' },
  });
  await page.addInitScript(() => {
    let active;
    window.WebSocket = new Proxy(window.WebSocket, {
      construct(Target, args) {
        active = Reflect.construct(Target, args);
        return active;
      },
    });
    window.__tqsTempBanDisconnect = () => {
      if (!active) throw new Error('No active game WebSocket to disconnect');
      active.close();
    };
  });
  await page.goto(`${base}/?tqs-e2e-preauth=1`);
  const preauth = page.getByRole('button', { name: /^(Tiếp tục với Google|Vào Chiến Trường)$/ });
  await preauth.waitFor({ timeout: 90_000 });
  await preauth.click();
  const lobby = page.getByRole('heading', { name: 'Danh sách phòng', exact: true });
  const alert = page.getByRole('alert').first();
  const board = page.locator('.game-board');
  const outcome = await Promise.race([
    lobby.waitFor({ timeout: 90_000 }).then(() => 'lobby'),
    alert.waitFor({ timeout: 90_000 }).then(() => 'alert'),
    board.waitFor({ timeout: 90_000 }).then(() => 'board'),
  ]);
  if (expectLobby) assert.equal(outcome, 'lobby', `Account ${expectLobby ? 'login' : 'reconnect'} did not reach lobby`);
  return { context, page, outcome };
}

async function selectPair(page) {
  const group = page.getByRole('group', { name: 'Danh sách võ tướng' });
  await group.waitFor({ timeout: 60_000 });
  const buttons = group.locator('button.general-choice');
  const count = await buttons.count();
  assert.ok(count >= 2);
  for (let a = 0; a < count; a += 1) {
    for (let b = a + 1; b < count; b += 1) {
      const reset = page.getByRole('button', { name: 'Chọn lại' });
      if (await reset.isEnabled()) await reset.click();
      await buttons.nth(a).click();
      // The web client evaluates every possible deputy through the native
      // Lua registry after the main-general click.  During that bounded
      // synchronous pass the remaining cards are intentionally marked
      // busy; wait for the evaluator once, then skip pairs the native rules
      // permanently mark invalid instead of waiting for those buttons.
      await page.waitForFunction((root) => Array.from(
        root.querySelectorAll('.sg-general-choice-entry'))
        .every((entry) => entry.getAttribute('data-general-status') !== 'busy'),
      await group.elementHandle(), { timeout: 90_000 });
      if (!await buttons.nth(b).isEnabled()) continue;
      await buttons.nth(b).click();
      const confirm = page.getByRole('button', { name: 'Xác nhận tướng' });
      if (await confirm.isEnabled()) {
        await confirm.click();
        return;
      }
    }
  }
  throw new Error('No legal native general pair in account-tempban QA');
}

const frozenDist = mkdtempSync(path.join(os.tmpdir(), 'tqs-account-tempban-dist-'));
cpSync(path.join(web, 'dist'), frozenDist, { recursive: true });
const [gatewayPort, webPort] = await Promise.all([
  externalGatewayPort || freePort(),
  freePort(),
]);
const base = `http://127.0.0.1:${webPort}`;
const gateway = externalGatewayPort ? null : spawn(process.execPath, [path.join(repo, 'game/gateway/src/server.mjs')], {
  env: { ...process.env, FK_ROOT: runtime, FK_HOST: host, FK_PORT: String(nativePort),
    PORT: String(gatewayPort), BIND_HOST: '127.0.0.1', ALLOW_ORIGIN: base, TRUSTED_PROXIES: '' },
  stdio: 'ignore',
});
let server;
let browser;
const sessions = [];
const evidence = {
  schemaVersion: 1,
  result: 'FAIL',
  scenario: 'account-tempban-same-gateway',
  policy: { tempBanMinutes, key: 'authenticated-userinfo.id', connectionAddressUsedAsKey: false,
    renewalTest: testRenewal },
  transport: { gateway: externalGatewayPort ? 'ssh-forwarded-qa-gateway' : 'local-loopback',
    nativeHost: 'metadata-only', sameTcpPeer: true },
  observations: { gameStarted: false, abandonmentTriggerObserved: false,
    accountARejectedAfterNewTicket: false, accountAAllowedAfterZeroDuration: false,
    accountAAllowedAfterExpiry: false, accountARenewalObserved: false,
    accountAStillBlockedAfterStaleTimer: false, accountAAllowedAfterRenewal: false,
    accountBReconnectedAfterNewTicket: false },
  cleanup: { candidateProcessRequested: Boolean(remoteSession), browserClosed: false },
};

try {
  server = await preview({ configFile: false, root: web,
    build: { outDir: frozenDist },
    preview: { host: '127.0.0.1', port: webPort, strictPort: true,
      proxy: { '/gateway': { target: `http://127.0.0.1:${gatewayPort}`, ws: true,
        rewrite: (requestPath) => requestPath.replace(/^\/gateway/, '') } } } });
  browser = await chromium.launch({
    executablePath: process.env.TQS_CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });
  const a = await loginPage(browser, first);
  const b = await loginPage(browser, second);
  sessions.push(a, b);
  const roomName = `TQSQA/account-tempban-${Date.now()}`;
  await a.page.getByLabel('Tên phòng', { exact: true }).fill(roomName);
  await a.page.getByLabel('Số người', { exact: true }).selectOption('2');
  await a.page.getByLabel('Thời gian lượt', { exact: true }).selectOption('60');
  await a.page.getByRole('button', { name: 'Tạo phòng Quốc Chiến', exact: true }).click();
  await a.page.getByRole('heading', { name: roomName, exact: true }).waitFor();
  await b.page.getByRole('button', { name: 'Làm mới', exact: true }).click();
  await b.page.locator('.room-item').filter({ hasText: roomName })
    .getByRole('button', { name: 'Vào phòng', exact: true }).click();
  await b.page.getByRole('heading', { name: roomName, exact: true }).waitFor();
  await b.page.getByRole('button', { name: 'Sẵn sàng', exact: true }).click();
  await a.page.getByRole('button', { name: 'Bắt đầu', exact: true }).click();
  evidence.observations.gameStarted = true;
  await Promise.all([a.page, b.page].map((page) => selectPair(page)));
  await Promise.all([a.page, b.page].map((page) => page.locator('.game-board').waitFor({ timeout: 90_000 })));
  await Promise.all([a.page, b.page].map((page) => page.locator('.board-self').waitFor({ timeout: 60_000 })));

  const beforeBan = remoteTempBanCount();
  await abandonExplicitly(a.page);
  evidence.observations.abandonmentTriggerObserved = await waitForTempBan(beforeBan, tempBanEventWaitMs);
  assert.equal(evidence.observations.abandonmentTriggerObserved, true,
    'Native candidate did not emit a new Temp banned event after A abandoned');
  await a.context.close();

  const aRetry = await loginPage(browser, first, { expectLobby: !expectTempBan });
  sessions.push(aRetry);
  if (!expectTempBan) {
    assert.equal(aRetry.outcome, 'lobby', 'A was blocked even though tempBanTime=0 should not retain a lock');
    evidence.observations.accountAAllowedAfterZeroDuration = true;
  } else {
    assert.equal(aRetry.outcome, 'alert', 'A received a new ticket but was not rejected');
    const aError = await aRetry.page.getByRole('alert').first().innerText();
    assert.match(aError, /tạm khóa/u, 'A rejection was not the temporary account-ban error');
    evidence.observations.accountARejectedAfterNewTicket = true;
  }

  const bRetry = await loginPage(browser, second, { expectLobby: false });
  sessions.push(bRetry);
  assert.equal(bRetry.outcome, 'board', 'B was not allowed to reconnect through the same gateway');
  await bRetry.page.locator('.board-self').waitFor({ timeout: 60_000 });
  evidence.observations.accountBReconnectedAfterNewTicket = true;

  if (testExpiry) {
    await aRetry.context.close();
    await new Promise((resolve) => setTimeout(resolve, expiryWaitMs));
    const aAfterExpiry = await loginPage(browser, first, { expectLobby: true });
    sessions.push(aAfterExpiry);
    assert.equal(aAfterExpiry.outcome, 'lobby', 'A remained blocked after the isolated temp-ban TTL elapsed');
    evidence.observations.accountAAllowedAfterExpiry = true;
  }

  evidence.result = 'PASS';
  console.log('PASS IPBAN account isolation: A rejected, B reconnected through the same gateway');
} finally {
  for (const session of sessions) await session.context.close().catch(() => {});
  if (browser) await browser.close().catch(() => {});
  if (server?.httpServer) {
    await new Promise((resolve) => server.httpServer.close(() => resolve()));
  }
  if (gateway) gateway.kill('SIGTERM');
  rmSync(frozenDist, { recursive: true, force: true });
  evidence.cleanup.browserClosed = true;
  if (remoteSession) {
    try { execFileSync('ssh', ['-T', '-o', 'BatchMode=yes', alias, 'sudo', '-n', 'tmux', 'kill-session', '-t', remoteSession], { timeout: 15_000, stdio: 'ignore' }); } catch {}
  }
  const out = path.resolve(process.env.TQS_ACCOUNT_TEMPBAN_EVIDENCE ?? path.join(repo, 'scratch/evidence', `ipban-account-tempban-${Date.now()}.json`));
  const { mkdirSync, writeFileSync } = await import('node:fs');
  mkdirSync(path.dirname(out), { recursive: true });
  writeFileSync(out, `${JSON.stringify(evidence, null, 2)}\n`, { mode: 0o600 });
  console.log(`Evidence: ${out}`);
  if (evidence.result !== 'PASS') process.exitCode = 1;
}
