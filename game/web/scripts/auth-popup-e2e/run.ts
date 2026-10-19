/** A real browser verifies a blocked OAuth popup is attempted from the click
 * event and produces a visible retry path. No Google account is used. */
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';

const root = fileURLToPath(new URL('../../', import.meta.url));
const chrome = [process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
].find((candidate): candidate is string => !!candidate && existsSync(candidate));
if (!chrome) throw new Error('Chrome missing: set TQS_CHROME_PATH');

const vite = await createServer({ root, configFile: fileURLToPath(new URL('../../vite.config.ts', import.meta.url)),
  server: { host: '127.0.0.1', port: 0 } });
try {
  await vite.listen();
  const baseURL = vite.resolvedUrls?.local[0];
  if (!baseURL) throw new Error('Missing Vite URL');
  const browser = await chromium.launch({ executablePath: chrome, headless: true });
  try {
    const page = await browser.newPage({ baseURL, viewport: { width: 390, height: 844 } });
    await page.addInitScript(() => {
      const state = window as Window & {
        __authPopupProbe?: { active: boolean; url: string };
      };
      window.open = (url) => {
        state.__authPopupProbe = {
          active: navigator.userActivation.isActive,
          url: String(url),
        };
        return null; // Simulate popup blocking without contacting a Google account.
      };
    });
    const errors: string[] = [];
    page.on('pageerror', (error) => errors.push(error.message));
    await page.goto('/auth-e2e.html');
    const button = page.getByRole('button', { name: 'Tiếp tục với Google' });
    await button.waitFor({ timeout: 15_000 });
    await assert.doesNotReject(() => button.waitFor({ state: 'visible' }));
    await page.waitForFunction(() => !(document.querySelector('.sg-btn-hero') as HTMLButtonElement)?.disabled);
    await button.click();
    await page.waitForFunction(() => !!(window as any).__authPopupProbe, null, { timeout: 15_000 });
    const probe = await page.evaluate(() => (window as any).__authPopupProbe as {
      active: boolean; url: string;
    });
    assert.equal(probe.active, true, 'Google popup must retain user activation');
    assert.match(probe.url, /\/__\/auth\/handler/);
    await page.getByRole('alert').getByText('Không mở được cửa sổ đăng nhập Google.', { exact: false })
      .waitFor({ timeout: 15_000 });
    assert.deepEqual(errors, []);
    console.log('PASS Google OAuth popup: synchronous user activation, blocked-popup guidance, no real account');

    // Until the Google OAuth callback is allowlisted, an installed iOS PWA
    // must offer a working Safari path without opening an unfinishable popup.
    const iosPage = await browser.newPage({
      baseURL, viewport: { width: 390, height: 844 }, hasTouch: true,
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1',
    });
    await iosPage.addInitScript(() => {
      Object.defineProperty(navigator, 'standalone', { configurable: true, value: true });
    });
    await iosPage.goto('/auth-e2e.html');
    const iosLogin = iosPage.getByRole('button', { name: 'Tiếp tục với Google' });
    await iosLogin.waitFor();
    assert.equal(await iosLogin.isDisabled(), true);
    const safariLink = iosPage.getByRole('link', { name: 'mở trò chơi bằng Safari' });
    assert.equal(await safariLink.getAttribute('href'), 'https://tqsvn.pages.dev/');
    console.log('PASS iOS standalone PWA: blocked broken popup and displayed Safari recovery link');
  } finally {
    await browser.close();
  }
} finally {
  await vite.close();
}
