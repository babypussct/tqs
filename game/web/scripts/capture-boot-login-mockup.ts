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

  // 1. Capture Desktop Split View - Stage Boot
  await page.click('#btnStateBoot');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_boot_split_desktop.png'), fullPage: false });
  console.log('Saved mockup_boot_split_desktop.png');

  // 2. Capture Desktop Split View - Stage Login
  await page.click('#btnStateLogin');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_login_split_desktop.png'), fullPage: false });
  console.log('Saved mockup_login_split_desktop.png');

  // 3. Switch to New Only View - Mobile 390px - Login
  await page.click('#btnViewNewOnly');
  await page.click('#btnDev390');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_login_new_mobile390.png'), fullPage: false });
  console.log('Saved mockup_login_new_mobile390.png');

  // 4. Switch to New Only View - Mobile 390px - Boot
  await page.click('#btnStateBoot');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_boot_new_mobile390.png'), fullPage: false });
  console.log('Saved mockup_boot_new_mobile390.png');

  // 5. Switch to Mobile 360px - Login
  await page.click('#btnStateLogin');
  await page.click('#btnDev360');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_login_new_mobile360.png'), fullPage: false });
  console.log('Saved mockup_login_new_mobile360.png');

  await browser.close();
  console.log('All mockup screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
