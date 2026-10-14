import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';
const baseUrl = process.env.TQS_CAPTURE_BASE_URL ?? 'http://localhost:5174';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
  });

  console.log(`Navigating to ${baseUrl}/real-lua-e2e.html...`);
  await page.goto(`${baseUrl}/real-lua-e2e.html`, { waitUntil: 'networkidle' });

  await page.waitForFunction(() => (window as any).__tqsRealLuaE2e?.ready, undefined, { timeout: 60000 });
  console.log('Lua runtime ready in harness. Beginning play...');

  // Start play with generals and cards
  await page.evaluate(() => (window as any).__tqsRealLuaE2e.beginPlay());
  await page.waitForTimeout(1000);

  // Set generals: Self = Bianfuren + Dianwei, Bot = Caocao + Liubei (hidden)
  await page.evaluate(async () => {
    const notify = (window as any).__tqsRealLuaE2e.boardNotify;
    notify('SetPlayerMark', "{17, '__heg_general', 'ld__bianfuren'}");
    notify('SetPlayerMark', "{17, '__heg_deputy', 'm_heg__dianwei'}");
    notify('PropertyUpdate', "{17, 'general', 'ld__bianfuren'}");
    notify('PropertyUpdate', "{17, 'deputyGeneral', 'm_heg__dianwei'}");
    notify('VisibleKingdom', "{17, 'wei'}");
    notify('SetPlayerMark', "{-1, '__heg_general', 'caocao'}");
    notify('SetPlayerMark', "{-1, '__heg_deputy', 'liubei'}");
    notify('PropertyUpdate', "{-1, 'general', 'anjiang'}");
    notify('PropertyUpdate', "{-1, 'deputyGeneral', 'anjiang'}");
  });

  await page.waitForTimeout(800);

  // 1. Capture 390px Mobile Real Board (Viewport and FullPage)
  await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_mobile.png'), fullPage: false });
  await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_fullpage.png'), fullPage: true });
  console.log('Saved real_gameplay_390_mobile.png & fullpage');

  // Scroll to bottom dashboard and capture
  const dashboard = page.locator('.board-local-dashboard');
  if (await dashboard.count() > 0) {
    await dashboard.scrollIntoViewIfNeeded();
    await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_bottom_dashboard.png'), fullPage: false });
    console.log('Saved real_gameplay_390_bottom_dashboard.png');
  }

  // 2. Capture 360px Small Mobile
  await page.setViewportSize({ width: 360, height: 800 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'real_gameplay_360_mobile.png'), fullPage: true });
  console.log('Saved real_gameplay_360_mobile.png');

  // 3. Capture 1280px Desktop Board
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'real_gameplay_1280_desktop.png'), fullPage: true });
  console.log('Saved real_gameplay_1280_desktop.png');

  await browser.close();
  console.log('Done capturing real gameplay screens!');
}

capture().catch((e) => {
  console.error(e);
  process.exit(1);
});
