/** Post-deploy public E2E: Google OAuth + approved Firebase account + real game.
 * Stores a dedicated Chrome profile outside the repository. Never log headers,
 * browser errors, screenshot, frames, token, Google account or Google HTML. */
import { existsSync, mkdirSync, chmodSync, realpathSync } from 'node:fs';
import { open, mkdir } from 'node:fs/promises';
import { homedir } from 'node:os';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { chromium, type BrowserContext, type Page } from 'playwright-core';
import { isGameSocket, matchesQaBearer, publicProbeUrl, PublicProbeError,
  safeFailure, type PublicStage } from './contract';

const root = fileURLToPath(new URL('../../../../', import.meta.url));
const args = process.argv.slice(2);
if (args.includes('--help')) {
  console.log('Usage: TQS_PUBLIC_QA_EMAIL=<approved-email> npm run test:e2e:public [-- --enroll]');
  process.exit(0);
}
const enroll = args.length === 1 && args[0] === '--enroll';
const steps: Partial<Record<PublicStage, boolean>> = {};
const websocket = { opened: 0, sent: 0, received: 0, closed: 0, errors: 0 };
let stage: PublicStage = 'preflight';
let pageErrors = 0;
let verifiedSessions = 0;
let wrongQaIdentity = false;
let context: BrowserContext | null = null;
let page: Page | null = null;
let matchStarted = false;
let finished = false;

function fail(reason: string): never { throw new PublicProbeError(stage, reason); }
async function step<T>(name: PublicStage, callback: () => Promise<T>): Promise<T> {
  stage = name;
  try {
    const result = await callback();
    steps[name] = true;
    return result;
  } catch (error) {
    if (error instanceof PublicProbeError) throw error;
    fail('stage_failed');
  }
}
function timeoutEnv(name: string, fallback: number, min: number, max: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) fail('invalid_timeout');
  return value;
}
function profileLocation(): string {
  const candidate = path.resolve(process.env.TQS_PUBLIC_QA_PROFILE ||
    path.join(homedir(), '.codex/secrets/tqs-public-oauth-chrome-profile'));
  // Profile contents include OAuth refresh material. Refuse profile paths in the repo.
  const repo = realpathSync(root);
  const parent = path.dirname(candidate);
  const parentReal = existsSync(parent) ? realpathSync(parent) : parent;
  if (candidate === repo || candidate.startsWith(repo + path.sep) ||
      parentReal === repo || parentReal.startsWith(repo + path.sep)) fail('unsafe_profile_path');
  if (existsSync(candidate)) {
    const profileReal = realpathSync(candidate);
    if (profileReal === repo || profileReal.startsWith(repo + path.sep)) fail('unsafe_profile_path');
  }
  return candidate;
}
function chromePath(): string {
  const candidates = [process.env.TQS_CHROME_PATH,
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'];
  const chrome = candidates.find((candidate): candidate is string => !!candidate && existsSync(candidate));
  if (!chrome) fail('chrome_missing');
  return chrome;
}
function attachSocketProbe(target: Page, origin: URL): void {
  target.on('pageerror', () => { pageErrors++; });
  target.on('websocket', (socket) => {
    if (!isGameSocket(socket.url(), origin)) return;
    websocket.opened++;
    socket.on('framesent', () => { websocket.sent++; });
    socket.on('framereceived', () => { websocket.received++; });
    socket.on('close', () => { websocket.closed++; });
    socket.on('socketerror', () => { websocket.errors++; });
  });
}

function chooseApprovedGoogleAccount(target: Page, qaEmail: string): void {
  // Firebase Google popup may show the account chooser after Firebase signOut.
  // Only an exact email match is clicked; no passwords, recovery or 2FA bypass.
  target.context().on('page', (popup) => {
    if (popup === target) return;
    void (async () => {
      try {
        await popup.waitForURL((url) => url.origin === 'https://accounts.google.com', { timeout: 25_000 });
        await popup.getByText(qaEmail, { exact: true }).first().click({ timeout: 25_000 });
      } catch { /* User interaction may be required; login stage will report a safe failure. */ }
    })();
  });
}

function checkIdentity(): void {
  if (wrongQaIdentity) fail('qa_identity_mismatch');
}

async function login(target: Page, uiTimeout: number, before: number): Promise<void> {
  // Firebase may already be authenticated by Chrome's encrypted profile.
  const continueButton = target.getByRole('button', { name: 'Vào Chiến Trường' });
  const googleButton = target.getByRole('button', { name: 'Tiếp tục với Google' });
  const lobbyTitle = target.getByRole('heading', { name: 'Danh sách phòng' });
  if (!(await lobbyTitle.isVisible().catch(() => false))) {
    // The Google button can render before onAuthStateChanged restores an
    // existing profile. Wait for the resolved OAuth state before choosing it.
    try {
      await target.waitForFunction(() => {
        const button = document.querySelector<HTMLButtonElement>('button.sg-btn-hero');
        return !!button && !button.disabled;
      }, null, { timeout: uiTimeout });
    } catch { fail('google_entry_missing'); }
  }
  if (await continueButton.isVisible().catch(() => false)) {
    await continueButton.click({ timeout: uiTimeout });
  } else if (await googleButton.isVisible().catch(() => false)) {
    await googleButton.click({ timeout: uiTimeout });
  } else if (!(await lobbyTitle.isVisible().catch(() => false))) {
    fail('google_entry_missing');
  }
  try { await lobbyTitle.waitFor({ state: 'visible', timeout: uiTimeout }); }
  catch {
    checkIdentity();
    if (await target.getByText('Chiến Thư Đang Chờ Phê Chuẩn').isVisible().catch(() => false)) {
      fail('qa_account_not_approved');
    }
    fail('google_session_required');
  }
  checkIdentity();
  if (verifiedSessions <= before) fail('verified_firebase_session_missing');
}

async function selectGenerals(target: Page, uiTimeout: number): Promise<void> {
  const options = target.locator('.general-grid .general-choice');
  try { await options.first().waitFor({ state: 'visible', timeout: uiTimeout }); }
  catch { fail('initial_generals_missing'); }
  const count = await options.count();
  const reset = target.getByRole('button', { name: 'Chọn lại' });
  const confirm = target.getByRole('button', { name: 'Xác nhận tướng' });
  for (let a = 0; a < count; a++) {
    for (let b = 0; b < count; b++) {
      if (a === b) continue;
      if (await reset.isEnabled().catch(() => false)) await reset.click();
      await options.nth(a).click();
      await options.nth(b).click();
      const kingdom = target.locator('.kingdom-picker input[type=radio]');
      if (await kingdom.count()) await kingdom.first().check();
      if (await confirm.isEnabled()) {
        await confirm.click();
        await confirm.waitFor({ state: 'hidden', timeout: uiTimeout });
        return;
      }
    }
  }
  fail('no_compatible_general_pair');
}

async function run(): Promise<void> {
  if (args.length > 1 || (args.length === 1 && !enroll)) fail('invalid_arguments');
  const site = publicProbeUrl(process.env.TQS_PUBLIC_URL || 'https://tqsvn.pages.dev/');
  const qaEmail = process.env.TQS_PUBLIC_QA_EMAIL?.trim();
  if (!qaEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(qaEmail)) fail('qa_email_required');
  const uiTimeout = timeoutEnv('TQS_PUBLIC_UI_TIMEOUT_MS', enroll ? 240_000 : 75_000,
    10_000, 300_000);
  const matchTimeout = timeoutEnv('TQS_PUBLIC_MATCH_TIMEOUT_MS', 900_000, 60_000, 1_800_000);
  const profile = profileLocation();
  if (!enroll && !existsSync(profile)) fail('qa_profile_missing_run_enroll');
  mkdirSync(profile, { recursive: true, mode: 0o700 });
  chmodSync(profile, 0o700);
  const realProfile = realpathSync(profile);
  const realRepo = realpathSync(root);
  if (realProfile === realRepo || realProfile.startsWith(realRepo + path.sep)) fail('unsafe_profile_path');
  const chrome = chromePath();
  context = await chromium.launchPersistentContext(profile, {
    executablePath: chrome, headless: !enroll, viewport: { width: 1280, height: 900 },
    // The QA browser targets the public network path; a cached PWA worker
    // could swallow the session request before the identity gate sees it.
    acceptDownloads: false, serviceWorkers: 'block',
  });
  page = context.pages()[0] || await context.newPage();
  const target = page;
  attachSocketProbe(target, site);
  if (!enroll) chooseApprovedGoogleAccount(target, qaEmail);
  // Verify account from Firebase ID token claim only in memory; actual approval
  // is established by the server admitting the player to the native lobby.
  await target.route('**/api/game/session', async (route) => {
    if (!matchesQaBearer(route.request().headers()['authorization'], qaEmail)) {
      wrongQaIdentity = true;
      await route.abort('blockedbyclient').catch(() => undefined);
      return;
    }
    verifiedSessions++;
    await route.continue().catch(() => undefined);
  });
  await step('preflight', async () => {
    const response = await target.goto(site.href, { waitUntil: 'domcontentloaded', timeout: uiTimeout });
    if (!response || response.status() !== 200) fail('public_page_unavailable');
    await target.getByRole('heading', { name: 'Cổng Doanh Trại' }).waitFor({ timeout: uiTimeout });
  });
  await step('oauth', async () => {
    if (enroll) console.log('ENROLL: complete Google sign-in in the Chrome window using the approved QA account.');
    await login(target, uiTimeout, 0);
  });
  await step('lobby', async () => {
    if (!(await target.getByRole('heading', { name: 'Danh sách phòng' }).isVisible())) fail('lobby_missing');
  });
  await step('websocket', async () => {
    if (websocket.opened < 1) fail('gateway_socket_missing');
    if (websocket.sent < 1 || websocket.received < 1) fail('gateway_frames_missing');
  });
  if (enroll) {
    await step('cleanup', async () => {
      await target.getByRole('button', { name: 'Ngắt kết nối' }).click({ timeout: uiTimeout });
      await target.getByRole('button', { name: 'Vào Chiến Trường' }).waitFor({ timeout: uiTimeout });
    });
    return;
  }
  const roomName = `TQS-PUBLIC-QA-${Date.now()}`;
  const beforeRoom = { sent: websocket.sent, received: websocket.received };
  await step('room', async () => {
    await target.locator('#room-name').fill(roomName);
    await target.locator('#capacity').selectOption('2');
    await target.locator('#timeout').selectOption('10');
    await target.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click({ timeout: uiTimeout });
    await target.getByRole('heading', { name: roomName, exact: true }).waitFor({ timeout: uiTimeout });
    if (!(await target.locator('.sg-room-badge-mode').getByText('Quốc Chiến').count())) {
      fail('new_heg_mode_missing');
    }
    // This panel is rendered only for the actual new_heg_mode returned by server.
    await target.locator('.waiting-pools').waitFor({ state: 'attached', timeout: uiTimeout });
    await target.getByRole('button', { name: '+ Thêm bot' }).click({ timeout: uiTimeout });
    await target.getByText('2/2 tướng lĩnh').waitFor({ timeout: uiTimeout });
    if (websocket.sent <= beforeRoom.sent || websocket.received <= beforeRoom.received) {
      fail('room_socket_traffic_missing');
    }
  });
  await step('match', async () => {
    const start = target.getByRole('button', { name: 'Bắt đầu', exact: true });
    await start.waitFor({ state: 'visible', timeout: uiTimeout });
    await start.click({ timeout: uiTimeout });
    matchStarted = true;
    await target.locator('.game-board').waitFor({ timeout: uiTimeout });
    await selectGenerals(target, uiTimeout);
    const trust = target.getByRole('button', { name: 'BOT chơi hộ' }).first();
    await trust.click({ timeout: uiTimeout });
    await target.getByText('Máy chủ đã bật BOT chơi hộ.', { exact: false }).waitFor({ timeout: uiTimeout });
  });
  await step('gameover', async () => {
    await target.locator('section[role="status"] #result-title').waitFor({ timeout: matchTimeout });
  });
  finished = true;
  await step('cleanup', async () => {
    await target.getByRole('button', { name: 'Về sảnh' }).click({ timeout: uiTimeout });
    await target.getByRole('heading', { name: 'Danh sách phòng' }).waitFor({ timeout: uiTimeout });
  });
  await step('logout', async () => {
    await target.getByRole('button', { name: 'Ngắt kết nối' }).click({ timeout: uiTimeout });
    await target.getByRole('button', { name: 'Đổi tài khoản khác' }).click({ timeout: uiTimeout });
    await target.getByRole('button', { name: 'Tiếp tục với Google' }).waitFor({ timeout: uiTimeout });
  });
  await step('relogin', async () => {
    const previous = verifiedSessions;
    const previousSockets = websocket.opened;
    await login(target, uiTimeout, previous);
    if (websocket.opened <= previousSockets) fail('relogin_socket_missing');
    if (websocket.errors) fail('socket_error');
    if (pageErrors) fail('browser_page_error');
    // Leave a clean native lobby session before closing the browser.
    await target.getByRole('button', { name: 'Ngắt kết nối' }).click({ timeout: uiTimeout });
  });
}

// TypeScript does not track assignment to these session refs inside run().
const getSession = (): { page: Page | null; context: BrowserContext | null } => ({ page, context });
let failure: { stage: PublicStage; reason: string } | null = null;
try { await run(); }
catch (error) { failure = safeFailure(error, stage); }
finally {
  const session = getSession();
  if (matchStarted && !finished && session.page && !session.page.isClosed()) {
    // If the match times out, request native Trust before browser shutdown.
    await session.page.getByRole('button', { name: 'BOT chơi hộ' }).first()
      .click({ timeout: 2000 }).catch(() => undefined);
  }
  try { await session.context?.close(); }
  catch { if (!failure) failure = { stage: 'cleanup', reason: 'browser_close_failed' }; }
  if (!failure && (pageErrors || websocket.errors)) failure = { stage, reason: 'browser_or_socket_error' };
  const evidence = {
    schemaVersion: 1, kind: 'public-google-oauth-e2e',
    at: new Date().toISOString(), mode: enroll ? 'enroll' : 'postdeploy',
    passed: failure === null, completed: steps,
    websocket, pageErrors, verifiedSessionCount: verifiedSessions,
    failure,
  };
  try {
    const dest = path.join(root, 'scratch/evidence/public-oauth-e2e');
    await mkdir(dest, { recursive: true, mode: 0o700 });
    const file = await open(path.join(dest, `public-qa-${Date.now()}-${randomUUID()}.json`), 'wx', 0o600);
    try { await file.writeFile(JSON.stringify(evidence, null, 2) + '\n'); }
    finally { await file.close(); }
  } catch { if (!failure) failure = { stage: 'cleanup', reason: 'evidence_write_failed' }; }
}
if (failure) {
  console.error(`PUBLIC_OAUTH_E2E FAIL stage=${failure.stage} reason=${failure.reason}`);
  process.exitCode = 1;
} else {
  console.log(`PUBLIC_OAUTH_E2E PASS mode=${enroll ? 'enroll' : 'postdeploy'} stages=${Object.keys(steps).join(',')} websocket_opened=${websocket.opened}`);
}
