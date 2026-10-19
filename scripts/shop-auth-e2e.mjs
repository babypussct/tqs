/** Browser regression: Google login navigates in the same tab on Chrome and
 * simulated iOS Safari/PWA. Firebase's handler is stubbed; Google is never contacted. */
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { createServer } from 'vite';

const requireFromGame = createRequire(new URL('../game/web/package.json', import.meta.url));
const { chromium } = requireFromGame('playwright-core');
const root = fileURLToPath(new URL('../', import.meta.url));
const chrome = [process.env.TQS_CHROME_PATH, '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser']
  .find((candidate) => candidate && existsSync(candidate));
if (!chrome) throw new Error('Chrome missing: set TQS_CHROME_PATH');

const vite = await createServer({ root, server: { host: '127.0.0.1', port: 0 } });
try {
  await vite.listen();
  const baseURL = vite.resolvedUrls?.local[0];
  if (!baseURL) throw new Error('Missing Vite URL');
  const browser = await chromium.launch({ executablePath: chrome, headless: true });
  try {
    for (const device of [
      { name: 'Chrome mobile', options: { viewport: { width: 390, height: 844 } } },
      { name: 'iOS Safari tab emulation', options: {
        viewport: { width: 390, height: 844 }, hasTouch: true,
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1',
      } },
      { name: 'iOS standalone emulation', options: {
        viewport: { width: 390, height: 844 }, hasTouch: true,
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1',
      } },
    ]) {
      const page = await browser.newPage({ baseURL, ...device.options });
      let popupAttempts = 0;
      const browserErrors = [];
      page.on('console', (message) => { if (message.type() === 'error') browserErrors.push(message.text()); });
      await page.exposeFunction('reportPopupAttempt', () => { popupAttempts++; });
      await page.addInitScript((standalone) => {
        window.open = () => { window.reportPopupAttempt(); return null; };
        if (standalone) Object.defineProperty(navigator, 'standalone', { configurable: true, value: true });
      }, device.name === 'iOS standalone emulation');
      page.on('popup', () => { popupAttempts++; });
      // Localhost is intentionally absent from production's OAuth allowlist.
      // Mock only that SDK preflight so this test stays offline and read-only.
      await page.route('https://identitytoolkit.googleapis.com/v1/projects?**', (route) => route.fulfill({
        status: 200, contentType: 'application/json',
        body: JSON.stringify({ authorizedDomains: ['127.0.0.1', 'localhost'] }),
      }));
      await page.route(/\/__\/auth\/handler\?/, (route) => route.fulfill({
        status: 200, contentType: 'text/html', body: '<!doctype html><title>Google redirect captured</title>',
      }));
      await page.goto('/', { waitUntil: 'domcontentloaded' });
      const button = page.getByRole('button', { name: 'Tài khoản' });
      await button.waitFor({ timeout: 30_000 });
      await button.click();
      try {
        await page.waitForURL(/\/__\/auth\/handler\?/, { timeout: 20_000 });
      } catch (error) {
        console.error(`${device.name} redirect stayed at ${page.url()}; errors=${JSON.stringify(browserErrors)}; messages=${(await page.locator('body').innerText()).slice(-1000)}`);
        throw error;
      }
      const url = new URL(page.url());
      assert.equal(url.searchParams.get('authType'), 'signInViaRedirect');
      assert.equal(new URL(url.searchParams.get('redirectUrl')).origin, new URL(baseURL).origin);
      assert.equal(popupAttempts, 0, 'Firebase must never use a popup');
      console.log(`PASS TQSShop ${device.name}: same-tab Firebase redirect; no popup`);
      await page.close();
    }
  } finally {
    await browser.close();
  }
} finally {
  await vite.close();
}
