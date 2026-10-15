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

  // 1. Capture Loading View with Hero Spotlight in Center (iPhone 390px)
  await page.click('#btnModeLoading');
  await page.click('#btnDev390');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_hero_loading_390.png'), fullPage: false });
  console.log('Saved sanguosha_hero_loading_390.png');

  // 2. Capture Title View: Tap to enter / Chạm để xuất chinh (iPhone 390px)
  await page.click('#btnModeTitle');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_hero_title_390.png'), fullPage: false });
  console.log('Saved sanguosha_hero_title_390.png');

  // 3. Capture Auth Form (iPhone 390px)
  await page.click('#btnModeAuth');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_hero_auth_390.png'), fullPage: false });
  console.log('Saved sanguosha_hero_auth_390.png');

  // 4. Capture Mobile Landscape (844px) - Split Screen AAA
  await page.click('#btnDevLandscape');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_hero_landscape.png'), fullPage: false });
  console.log('Saved sanguosha_hero_landscape.png');

  // 5. Capture Desktop View (1040px) - Split Screen AAA with Hero Lv Bu
  await page.click('#btnDevDesktop');
  await page.click('#btnHeroLvbu');
  await page.click('#btnThemePalace');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_hero_desktop.png'), fullPage: false });
  console.log('Saved sanguosha_hero_desktop.png');

  await browser.close();
  console.log('All screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
