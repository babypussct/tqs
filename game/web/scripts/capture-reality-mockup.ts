import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1360, height: 2100 },
    deviceScaleFactor: 2,
  });

  console.log('Navigating to http://localhost:5174/reality-vs-ideal-mockup.html...');
  await page.goto('http://localhost:5174/reality-vs-ideal-mockup.html', { waitUntil: 'networkidle' });

  // 1. Capture Current System Reality Table
  const tables = await page.$$('.sg-board-table');
  if (tables.length >= 1) {
    await tables[0].screenshot({ path: path.join(outDir, 'mockup_board_reality_current.png') });
    console.log('Saved mockup_board_reality_current.png');
  }

  // 2. Capture Proposed Ideal Native Table
  if (tables.length >= 2) {
    await tables[1].screenshot({ path: path.join(outDir, 'mockup_board_ideal_native.png') });
    console.log('Saved mockup_board_ideal_native.png');
  }

  // 3. Full Comparison Overview Screenshot
  await page.screenshot({ path: path.join(outDir, 'mockup_board_reality_vs_ideal.png'), fullPage: false });
  console.log('Saved mockup_board_reality_vs_ideal.png');

  await browser.close();
  console.log('All comparison screenshots captured successfully!');
}

capture().catch(err => {
  console.error('Capture failed:', err);
  process.exit(1);
});
