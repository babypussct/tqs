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

  console.log('Navigating to lobby-room-mockup.html...');
  await page.goto('http://localhost:5174/lobby-room-mockup.html', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(500);

  // 1. Capture Lobby View (Mobile Dọc 390px) - Default
  await page.click('#btnModeLobby');
  await page.click('#btnDev390');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_lobby_390.png') });
  console.log('Saved sanguosha_lobby_390.png');

  // 1b. Capture Lobby View with Pack Toggled (Demonstrating host toggle ability)
  const togglePackInput = page.locator('input[data-pack-id="transformation_generals"]');
  await togglePackInput.uncheck();
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_lobby_pool_toggled_390.png') });
  console.log('Saved sanguosha_lobby_pool_toggled_390.png');

  // 1c. Capture Lobby View with Pool Warning (When host unchecks too many packs)
  await page.locator('input[data-pack-id="standard_generals"]').uncheck();
  await page.locator('input[data-pack-id="formation_generals"]').uncheck();
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_lobby_pool_warning_390.png') });
  console.log('Saved sanguosha_lobby_pool_warning_390.png');

  // Re-check all
  await page.locator('input[data-pack-id="standard_generals"]').check();
  await page.locator('input[data-pack-id="formation_generals"]').check();
  await togglePackInput.check();
  await page.waitForTimeout(200);

  // 2. Capture Waiting Room View (Mobile Dọc 390px)
  await page.click('#btnModeWaitingRoom');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_waiting_room_390.png') });
  console.log('Saved sanguosha_waiting_room_390.png');

  // 3. Capture Lobby View (Mobile Ngang 844px)
  await page.click('#btnModeLobby');
  await page.click('#btnDevLandscape');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_lobby_landscape.png') });
  console.log('Saved sanguosha_lobby_landscape.png');

  // 4. Capture Waiting Room View (Desktop 1040px)
  await page.click('#btnModeWaitingRoom');
  await page.click('#btnDevDesktop');
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outDir, 'sanguosha_waiting_room_desktop.png') });
  console.log('Saved sanguosha_waiting_room_desktop.png');

  await browser.close();
  console.log('All Lobby & Waiting Room screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
