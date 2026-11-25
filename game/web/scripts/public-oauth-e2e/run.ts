/** Post-deploy public E2E: Google OAuth + approved Firebase account + real game.
 * Stores a dedicated Chrome profile outside the repository. Never log headers,
 * browser errors, screenshot, frames, token, Google account or Google HTML. */
import { existsSync, mkdirSync, chmodSync, realpathSync } from 'node:fs';
import { open, mkdir } from 'node:fs/promises';
import { homedir } from 'node:os';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { chromium, type Browser, type BrowserContext, type Page, type Route } from 'playwright-core';
import { isGameSocket, matchesQaBearer, publicProbeUrl, PublicProbeError,
  safeFailure, type PublicStage } from './contract';

const root = fileURLToPath(new URL('../../../../', import.meta.url));
const args = process.argv.slice(2);
if (args.includes('--help')) {
  console.log('Usage: TQS_PUBLIC_QA_EMAIL=<approved-email> npm run test:e2e:public [-- --enroll | --headed [--auth-only] | --existing-chrome [--auth-only]]');
  process.exit(0);
}
const enroll = args.length === 1 && args[0] === '--enroll';
const headed = args.includes('--headed');
const existingChrome = args.includes('--existing-chrome');
const authOnly = args.includes('--auth-only');
const mode = enroll ? 'enroll' : authOnly ? 'auth-only' : 'postdeploy';
const steps: Partial<Record<PublicStage, boolean>> = {};
const websocket = { opened: 0, sent: 0, received: 0, closed: 0, errors: 0 };
const socketTraffic = new Map<number, { sent: boolean; received: boolean }>();
const googlePopup = { opened: 0, googleOrigin: 0, approvedAccountClicked: 0,
  signInRequired: false, challenge: false, browserRejected: false, chooserVisible: false, approvedAccountVisible: false,
  consentVisible: false, closed: 0, returnedToFirebase: 0, googleErrorPage: false, interruptedReads: 0, googleRoute: null as string | null,
  documentLoaded: false, bodyHasText: false, googleSignInError: false };
let stage: PublicStage = 'preflight';
let pageErrors = 0;
let verifiedSessions = 0;
let wrongQaIdentity = false;
let context: BrowserContext | null = null;
let attachedBrowser: Browser | null = null;
let sessionRoute: ((route: Route) => Promise<void>) | null = null;
const sessionRoutePattern = '**/api/game/session';
let page: Page | null = null;
let matchStarted = false;
let finished = false;
let closingContext = false;

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
    const traffic = { sent: false, received: false };
    socketTraffic.set(websocket.opened, traffic);
    socket.on('framesent', () => {
      websocket.sent++;
      traffic.sent = true;
    });
    socket.on('framereceived', () => {
      websocket.received++;
      traffic.received = true;
    });
    socket.on('close', () => { websocket.closed++; });
    socket.on('socketerror', () => { websocket.errors++; });
  });
}

function chooseApprovedGoogleAccount(target: Page, qaEmail: string, uiTimeout: number): void {
  target.on('popup', (popup) => {
    googlePopup.opened++;
    let reachedGoogle = false;
    let returnedToFirebase = false;
    popup.on('framenavigated', (frame) => {
      if (frame !== popup.mainFrame()) return;
      const url = new URL(frame.url());
      if (url.origin === 'https://accounts.google.com') {
        reachedGoogle = true;
        googlePopup.googleErrorPage ||= /\/(?:rejected|oautherror)(?:\/|$)/i.test(url.pathname);
      } else if (reachedGoogle && !returnedToFirebase && url.pathname === '/__/auth/handler' &&
          (url.hostname.endsWith('.firebaseapp.com') || url.origin === new URL(target.url()).origin)) {
        googlePopup.returnedToFirebase++;
        returnedToFirebase = true;
      }
    });
    popup.once('close', () => { if (!closingContext) googlePopup.closed++; });
    void (async () => {
      await popup.waitForURL((url) => url.origin === 'https://accounts.google.com', { timeout: uiTimeout });
      reachedGoogle = true;
      googlePopup.googleOrigin++;
      const deadline = Date.now() + uiTimeout;
      while (!popup.isClosed() && Date.now() < deadline) {
        try {
          const url = new URL(popup.url());
          if (url.origin !== 'https://accounts.google.com') break;
          const route = url.pathname.match(/\/(accountchooser|identifier|challenge|rejected|oautherror|consent)(?:\/|$)/i);
          googlePopup.googleRoute = route?.[1].toLowerCase() ?? 'other';
          const documentState = await popup.evaluate(() => ({
            loaded: document.readyState !== 'loading',
            bodyHasText: Boolean(document.body?.innerText.trim()),
          }));
          googlePopup.documentLoaded ||= documentState.loaded;
          googlePopup.bodyHasText ||= documentState.bodyHasText;
          const visible = (selector: string) => popup.locator(selector).first().isVisible();
          const [signIn, rejected, chooser, consent, signInError] = await Promise.all([
            visible('input[type=email]:visible, input[type=password]:visible'),
            popup.getByText(/this browser or app may not be secure|trình duyệt hoặc ứng dụng này có thể không an toàn/i).first().isVisible(),
            popup.getByText(/choose an account|chọn tài khoản/i).first().isVisible(),
            popup.getByText(/wants to access your Google Account|muốn truy cập vào Tài khoản Google/i).first().isVisible(),
            popup.getByText(/couldn.t sign you in|không thể đăng nhập cho bạn/i).first().isVisible(),
          ]);
          googlePopup.googleErrorPage ||= /\/(?:rejected|oautherror)(?:\/|$)/i.test(url.pathname);
          googlePopup.signInRequired ||= signIn;
          googlePopup.googleSignInError ||= signInError;
          const challenge = /\/challenge(?:\/|$)/.test(url.pathname);
          googlePopup.challenge ||= challenge;
          googlePopup.browserRejected ||= rejected;
          googlePopup.chooserVisible ||= chooser;
          googlePopup.consentVisible ||= consent;
          const email = popup.getByText(qaEmail, { exact: true }).filter({ visible: true });
          // Google renders the email inside the account link on the Chrome chooser.
          const link = popup.getByRole('link').filter({ has: email, visible: true });
          const account = await link.count() ? link : email;
          if (await account.count() === 1 && !signIn && !challenge && !rejected && !consent &&
              new URL(popup.url()).origin === 'https://accounts.google.com') {
            googlePopup.approvedAccountVisible = true;
            const clicked = await account.click({ timeout: 1000 }).then(() => true, () => false);
            if (clicked) {
              googlePopup.approvedAccountClicked++;
              break;
            }
          }
        } catch {
          // Google can replace the document during a selector read. Recheck the
          // origin and visible chooser on the next iteration.
          googlePopup.interruptedReads++;
        }
        await new Promise((resolve) => setTimeout(resolve, 250));
      }
    })().catch(() => { /* Only sanitized observations are included in evidence. */ });
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
    if (googlePopup.browserRejected) fail('google_browser_rejected');
    if (googlePopup.challenge) fail('google_challenge_observed');
    // Only report fixed application error categories. Alert contents may contain private data.
    const alert = target.locator('.sg-error-notice[role=alert]');
    if (await alert.getByText(/cửa sổ Google đã đóng trước khi đăng nhập hoàn tất/i).isVisible()) {
      fail('firebase_popup_closed');
    }
    if (await alert.getByText(/không kết nối được với dịch vụ đăng nhập Google/i).isVisible()) {
      fail('firebase_google_network_error');
    }
    if (await alert.isVisible()) fail('oauth_application_error');
    fail('oauth_lobby_timeout');
  }
  checkIdentity();
  if (verifiedSessions <= before) fail('verified_firebase_session_missing');
}

async function disconnectLobby(target: Page, uiTimeout: number): Promise<void> {
  await target.getByRole('button', { name: 'Chi tiết kết nối', exact: true }).click({ timeout: uiTimeout });
  await target.getByRole('button', { name: 'Ngắt kết nối', exact: true }).click({ timeout: uiTimeout });
  await target.getByRole('button', { name: 'Vào Chiến Trường', exact: true }).waitFor({ timeout: uiTimeout });
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
      await options.nth(a).click({ timeout: uiTimeout });
      await target.waitForFunction(() => Array.from(document.querySelectorAll('.sg-general-choice-entry'))
        .every((entry) => entry.getAttribute('data-general-status') !== 'busy'), undefined,
      { timeout: uiTimeout });
      if (!await options.nth(b).isEnabled()) continue;
      await options.nth(b).click({ timeout: uiTimeout });
      const kingdom = target.locator('.kingdom-picker button.sg-kingdom-option');
      if (await kingdom.count()) await kingdom.first().click({ timeout: uiTimeout });
      if (await confirm.isEnabled()) {
        await confirm.click();
        await confirm.waitFor({ state: 'hidden', timeout: uiTimeout });
        return;
      }
    }
  }
  fail('no_compatible_general_pair');
}

async function enableTrust(target: Page, uiTimeout: number): Promise<void> {
  const status = target.locator('.board-trust-status');
  if (await status.isVisible()) return;
  const trust = target.getByRole('button', { name: 'BOT chơi hộ', exact: true });
  if (!(await trust.isVisible())) {
    await target.getByRole('button', { name: 'Tùy chọn trận đấu', exact: true }).click({ timeout: uiTimeout });
  }
  await trust.click({ timeout: uiTimeout });
  await status.waitFor({ state: 'visible', timeout: uiTimeout });
}

async function run(): Promise<void> {
  if (!enroll && (args.some((arg) => arg !== '--headed' && arg !== '--auth-only' && arg !== '--existing-chrome') ||
    new Set(args).size !== args.length || (authOnly && !headed && !existingChrome) || (headed && existingChrome))) fail('invalid_arguments');
  const site = publicProbeUrl(process.env.TQS_PUBLIC_URL || 'https://tqsvn.pages.dev/');
  const qaEmail = process.env.TQS_PUBLIC_QA_EMAIL?.trim();
  if (!qaEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(qaEmail)) fail('qa_email_required');
  const uiTimeout = timeoutEnv('TQS_PUBLIC_UI_TIMEOUT_MS', enroll ? 240_000 : 75_000,
    10_000, 300_000);
  const matchTimeout = timeoutEnv('TQS_PUBLIC_MATCH_TIMEOUT_MS', 900_000, 60_000, 1_800_000);
  if (existingChrome) {
    const port = process.env.TQS_PUBLIC_CHROME_CDP_PORT;
    if (!port || !/^\d{1,5}$/.test(port) || Number(port) < 1 || Number(port) > 65535) {
      fail('invalid_local_cdp_port');
    }
    attachedBrowser = await chromium.connectOverCDP(`http://127.0.0.1:${Number(port)}`, {
      timeout: 10_000,
    }).catch(() => fail('existing_chrome_unreachable'));
    const pages = attachedBrowser.contexts().flatMap((browserContext) => browserContext.pages())
      .filter((candidate) => candidate.url() === site.href);
    if (pages.length !== 1) fail('existing_game_tab_not_unique');
    page = pages[0];
    if (await page.locator('.game-board').isVisible() ||
        !(await page.getByRole('heading', { name: /^(Cổng Doanh Trại|Danh sách phòng)$/ }).isVisible())) {
      fail('existing_game_tab_not_idle');
    }
  } else {
    const profile = profileLocation();
    if (!enroll && !existsSync(profile)) fail('qa_profile_missing_run_enroll');
    mkdirSync(profile, { recursive: true, mode: 0o700 });
    chmodSync(profile, 0o700);
    const realProfile = realpathSync(profile);
    const realRepo = realpathSync(root);
    if (realProfile === realRepo || realProfile.startsWith(realRepo + path.sep)) fail('unsafe_profile_path');
    const chrome = chromePath();
    context = await chromium.launchPersistentContext(profile, {
      executablePath: chrome, headless: !(enroll || headed), viewport: { width: 1280, height: 900 },
      // The QA browser targets the public network path; a cached PWA worker
      // could swallow the session request before the identity gate sees it.
      acceptDownloads: false, serviceWorkers: 'block',
    });
    page = context.pages()[0] || await context.newPage();
  }
  const target = page;
  attachSocketProbe(target, site);
  if (!enroll) chooseApprovedGoogleAccount(target, qaEmail, uiTimeout);
  // Verify account from Firebase ID token claim only in memory; actual approval
  // is established by the server admitting the player to the native lobby.
  sessionRoute = async (route) => {
    if (!matchesQaBearer(route.request().headers()['authorization'], qaEmail)) {
      wrongQaIdentity = true;
      await route.abort('blockedbyclient').catch(() => undefined);
      return;
    }
    verifiedSessions++;
    await route.continue().catch(() => undefined);
  };
  await target.route(sessionRoutePattern, sessionRoute);
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
      await disconnectLobby(target, uiTimeout);
    });
    return;
  }
  if (!authOnly) {
    const roomName = `TQS-PUBLIC-QA-${Date.now()}`;
    const beforeRoom = { sent: websocket.sent, received: websocket.received };
    await step('room', async () => {
      await target.locator('#room-name').fill(roomName);
      await target.locator('#capacity').selectOption('2');
      await target.locator('#timeout').selectOption('60');
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
      await enableTrust(target, uiTimeout);
    });
    await step('gameover', async () => {
      await target.locator('section[role="status"] #result-title').waitFor({ timeout: matchTimeout });
    });
    finished = true;
    await step('cleanup', async () => {
      await target.getByRole('button', { name: 'Về sảnh' }).click({ timeout: uiTimeout });
      await target.getByRole('heading', { name: 'Danh sách phòng' }).waitFor({ timeout: uiTimeout });
    });
  }
  await step('logout', async () => {
    await disconnectLobby(target, uiTimeout);
    await target.getByRole('button', { name: 'Đổi tài khoản khác' }).click({ timeout: uiTimeout });
    await target.getByRole('button', { name: 'Tiếp tục với Google' }).waitFor({ timeout: uiTimeout });
  });
  await step('relogin', async () => {
    const previous = verifiedSessions;
    const previousSockets = websocket.opened;
    await login(target, uiTimeout, previous);
    if (websocket.opened <= previousSockets) fail('relogin_socket_missing');
    if (![...socketTraffic].some(([id, traffic]) =>
      id > previousSockets && traffic.sent && traffic.received)) fail('relogin_frames_missing');
    if (websocket.errors) fail('socket_error');
    if (pageErrors) fail('browser_page_error');
    // Leave a clean native lobby session before closing the browser.
    await disconnectLobby(target, uiTimeout);
  });
}

// TypeScript does not track assignment to these session refs inside run().
const getSession = (): {
  page: Page | null;
  context: BrowserContext | null;
  attachedBrowser: Browser | null;
  sessionRoute: ((route: Route) => Promise<void>) | null;
} => ({ page, context, attachedBrowser, sessionRoute });
let failure: { stage: PublicStage; reason: string } | null = null;
try { await run(); }
catch (error) { failure = safeFailure(error, stage); }
finally {
  const session = getSession();
  if (matchStarted && !finished && session.page && !session.page.isClosed()) {
    // If the match times out, request native Trust before browser shutdown.
    await enableTrust(session.page, 2000).catch(() => undefined);
  }
  closingContext = true;
  try {
    if (session.attachedBrowser) {
      try {
        if (session.page && session.sessionRoute && !session.page.isClosed()) {
          await session.page.unroute(sessionRoutePattern, session.sessionRoute);
        }
      } finally {
        await session.attachedBrowser.close();
      }
    } else {
      await session.context?.close();
    }
  }
  catch { if (!failure) failure = { stage: 'cleanup', reason: 'browser_close_failed' }; }
  if (!failure && (pageErrors || websocket.errors)) failure = { stage, reason: 'browser_or_socket_error' };
  const evidence = {
    schemaVersion: 1, kind: 'public-google-oauth-e2e',
    at: new Date().toISOString(), mode, headed: enroll || headed || existingChrome, existingChrome,
    passed: failure === null, completed: steps,
    websocket, googlePopup, pageErrors, verifiedSessionCount: verifiedSessions,
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
  console.log(`PUBLIC_OAUTH_E2E PASS mode=${mode} stages=${Object.keys(steps).join(',')} websocket_opened=${websocket.opened}`);
}
