import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pkg from '../game/web/node_modules/playwright-core/index.js';
const { chromium } = pkg;

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const chromeCandidates = [
  process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];
const executablePath = chromeCandidates.find((p) => p && existsSync(p));
if (!executablePath) throw new Error('Chrome executable not found');

const artifactDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';

async function capture() {
  const browser = await chromium.launch({ executablePath, headless: true });

  // 1. Desktop 1280px Viewport (8 cards default with 1 selected)
  {
    const page = await browser.newPage({ viewport: { width: 1200, height: 900 } });
    await page.goto('http://localhost:5174/handcard-mockup.html', { waitUntil: 'networkidle' });

    // Click card 3 (ex_crossbow) to show selected state with golden halo
    await page.evaluate(() => {
      selectCard('ex_crossbow');
    });
    await page.waitForTimeout(300);

    // Capture main felt board
    const board = page.locator('.felt-board');
    await board.screenshot({ path: path.join(artifactDir, 'mockup_hand_fan_8cards.png') });
    console.log('Captured mockup_hand_fan_8cards.png');

    // 2. 10 Cards Fan (Maximum Hand)
    await page.evaluate(() => {
      setCount(10);
      selectCard('thunder_blade');
    });
    await page.waitForTimeout(300);
    await board.screenshot({ path: path.join(artifactDir, 'mockup_hand_fan_10cards.png') });
    console.log('Captured mockup_hand_fan_10cards.png');

    // 3. Dark Veil Disabled State Test
    await page.evaluate(() => {
      toggleDisabled();
    });
    await page.waitForTimeout(300);
    await board.screenshot({ path: path.join(artifactDir, 'mockup_hand_fan_disabled_veil.png') });
    console.log('Captured mockup_hand_fan_disabled_veil.png');

    await page.close();
  }

  // 5. Mobile Matrix & Individual Mobile Cases (3, 5, 8, 10 Cards)
  {
    const page = await browser.newPage({ viewport: { width: 1200, height: 1100 } });
    await page.goto('http://localhost:5174/handcard-mockup.html', { waitUntil: 'networkidle' });
    await page.waitForTimeout(300);

    // Capture the entire 4-case mobile matrix
    const matrixSec = page.locator('.mobile-matrix-grid');
    await matrixSec.screenshot({ path: path.join(artifactDir, 'mockup_mobile_matrix.png') });
    console.log('Captured mockup_mobile_matrix.png');

    // Capture individual cases
    const caseWrappers = page.locator('.mobile-case-wrapper');
    await caseWrappers.nth(0).screenshot({ path: path.join(artifactDir, 'mockup_mobile_3cards.png') });
    console.log('Captured mockup_mobile_3cards.png (3 Lá - Đứng thoáng)');

    await caseWrappers.nth(1).screenshot({ path: path.join(artifactDir, 'mockup_mobile_5cards.png') });
    console.log('Captured mockup_mobile_5cards.png (5 Lá - Chuẩn)');

    await caseWrappers.nth(2).screenshot({ path: path.join(artifactDir, 'mockup_mobile_8cards.png') });
    console.log('Captured mockup_mobile_8cards.png (8 Lá - Gối lớp)');

    await caseWrappers.nth(3).screenshot({ path: path.join(artifactDir, 'mockup_mobile_10cards.png') });
    console.log('Captured mockup_mobile_10cards.png (10 Lá - Cực đại)');

    await page.close();
  }

  await browser.close();
  console.log('All screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
