import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/641e5d07-037e-4305-8b79-9b3ac0fe3343';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1440, height: 1020 },
    deviceScaleFactor: 2,
  });

  console.log('Navigating to boot-login-mockup.html...');
  await page.goto('http://localhost:5174/boot-login-mockup.html', { waitUntil: 'networkidle' });

  // 1. Capture Loading View (iPhone 390px)
  await page.click('#btnModeLoading');
  await page.click('#btnDev390');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_mobile_loading_390.png'), fullPage: false });
  console.log('Saved sanguosha_mobile_loading_390.png');

  // 2. Capture Login View (iPhone 390px)
  await page.click('#btnModeLogin');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_mobile_login_390.png'), fullPage: false });
  console.log('Saved sanguosha_mobile_login_390.png');

  // 3. Switch to God Zhou Yu & Desktop
  await page.click('#btnGenZhouYu');
  await page.click('#btnDevDesktop');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_mobile_login_desktop.png'), fullPage: false });
  console.log('Saved sanguosha_mobile_login_desktop.png');

  await browser.close();
  console.log('All Sanguosha Mobile screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
