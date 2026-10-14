import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1440, height: 1100 },
    deviceScaleFactor: 2,
  });

  console.log('Navigating to interactive-board-comparison.html...');
  await page.goto('http://localhost:5174/interactive-board-comparison.html', { waitUntil: 'networkidle' });

  // 1. Capture Desktop Split View (Default)
  await page.screenshot({ path: path.join(outDir, 'mockup_interactive_desktop_split.png'), fullPage: false });
  console.log('Saved mockup_interactive_desktop_split.png');

  // 2. Trigger Targeting and Drunk state
  await page.click('#toggleTarget');
  await page.click('#toggleDrunk');
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'mockup_interactive_targeting_mode.png'), fullPage: false });
  console.log('Saved mockup_interactive_targeting_mode.png');

  // 3. Switch to Mobile 390px View
  await page.click('#btnDev390');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'mockup_interactive_mobile_390.png'), fullPage: false });
  console.log('Saved mockup_interactive_mobile_390.png');

  await browser.close();
  console.log('All interactive screenshots captured successfully!');
}

capture().catch(err => {
  console.error('Capture failed:', err);
  process.exit(1);
});
