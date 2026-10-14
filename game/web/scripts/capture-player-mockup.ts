import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1280, height: 1400 },
    deviceScaleFactor: 2,
  });

  console.log('Navigating to http://localhost:5174/player-seat-mockup.html...');
  await page.goto('http://localhost:5174/player-seat-mockup.html', { waitUntil: 'networkidle' });

  // 1. Full Matrix Screenshot
  const matrixElement = await page.$('.matrix-grid');
  if (matrixElement) {
    await matrixElement.screenshot({ path: path.join(outDir, 'mockup_player_matrix.png') });
    console.log('Saved mockup_player_matrix.png');
  }

  // 2. Oval Table Screenshot
  const tableElement = await page.$('.table-preview-section');
  if (tableElement) {
    await tableElement.screenshot({ path: path.join(outDir, 'mockup_player_table.png') });
    console.log('Saved mockup_player_table.png');
  }

  // 3. Zoom Case 1 (Dual Generals)
  const caseCards = await page.$$('.seat-showcase-card');
  if (caseCards.length >= 1) {
    await caseCards[0].screenshot({ path: path.join(outDir, 'mockup_player_case1_dual.png') });
    console.log('Saved mockup_player_case1_dual.png');
  }

  // 4. Zoom Case 3 (Chained & Drunk)
  if (caseCards.length >= 3) {
    await caseCards[2].screenshot({ path: path.join(outDir, 'mockup_player_case3_chained.png') });
    console.log('Saved mockup_player_case3_chained.png');
  }

  // 5. Zoom Case 4 (Dying Save Me)
  if (caseCards.length >= 4) {
    await caseCards[3].screenshot({ path: path.join(outDir, 'mockup_player_case4_dying.png') });
    console.log('Saved mockup_player_case4_dying.png');
  }

  // 6. Mobile 390x844 Viewport
  const mobilePage = await browser.newPage({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
  });
  await mobilePage.goto('http://localhost:5174/player-seat-mockup.html', { waitUntil: 'networkidle' });
  await mobilePage.screenshot({ path: path.join(outDir, 'mockup_player_mobile_390.png'), fullPage: false });
  console.log('Saved mockup_player_mobile_390.png');


  await browser.close();
  console.log('All screenshots captured successfully!');
}

capture().catch(err => {
  console.error('Capture failed:', err);
  process.exit(1);
});
