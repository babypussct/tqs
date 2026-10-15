import { chromium } from 'playwright-core';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer } from 'vite';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const outDir = '/Users/otada/.gemini/antigravity/brain/641e5d07-037e-4305-8b79-9b3ac0fe3343';
const root = path.resolve(__dirname, '..');

async function capture() {
  const server = await createServer({
    root,
    server: { port: 5199 },
  });
  await server.listen();
  console.log('Vite dev server running on port 5199');

  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  try {
    // 1. Capture Real Boot Screen on Mobile (390x844)
    const mobilePage = await browser.newPage({
      viewport: { width: 390, height: 844 },
      deviceScaleFactor: 2,
    });
    await mobilePage.goto('http://localhost:5199/', { waitUntil: 'domcontentloaded' });
    await mobilePage.waitForTimeout(600);
    await mobilePage.screenshot({ path: path.join(outDir, 'react_boot_mobile390.png') });
    console.log('Saved react_boot_mobile390.png');

    // 2. Capture Real Login Screen on Mobile (390x844)
    await mobilePage.goto('http://localhost:5199/e2e.html?app=1', { waitUntil: 'domcontentloaded' });
    await mobilePage.getByRole('heading', { name: 'Đăng nhập Tam Quốc Sát', exact: true }).waitFor();
    await mobilePage.waitForTimeout(600);
    await mobilePage.screenshot({ path: path.join(outDir, 'react_login_mobile390.png') });
    console.log('Saved react_login_mobile390.png');

    // 3. Capture Real Login Screen on Landscape Mobile (844x420)
    const landscapePage = await browser.newPage({
      viewport: { width: 844, height: 420 },
      deviceScaleFactor: 2,
    });
    await landscapePage.goto('http://localhost:5199/e2e.html?app=1', { waitUntil: 'domcontentloaded' });
    await landscapePage.getByRole('heading', { name: 'Đăng nhập Tam Quốc Sát', exact: true }).waitFor();
    await landscapePage.waitForTimeout(600);
    await landscapePage.screenshot({ path: path.join(outDir, 'react_login_landscape.png') });
    console.log('Saved react_login_landscape.png');

    // 4. Capture Real Login Screen on Desktop (1040x680)
    const desktopPage = await browser.newPage({
      viewport: { width: 1040, height: 680 },
      deviceScaleFactor: 2,
    });
    await desktopPage.goto('http://localhost:5199/e2e.html?app=1', { waitUntil: 'domcontentloaded' });
    await desktopPage.getByRole('heading', { name: 'Đăng nhập Tam Quốc Sát', exact: true }).waitFor();
    await desktopPage.waitForTimeout(600);
    await desktopPage.screenshot({ path: path.join(outDir, 'react_login_desktop.png') });
    console.log('Saved react_login_desktop.png');

    // 5. Capture Real Lobby Screen on Mobile (390x844)
    await mobilePage.goto('http://localhost:5199/real-lua-e2e.html', { waitUntil: 'domcontentloaded' });
    await mobilePage.waitForFunction(() => (window as any).__tqsRealLuaE2e?.ready);
    await mobilePage.evaluate(() => (window as any).__tqsRealLuaE2e.beginRoomPacks());
    await mobilePage.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    await mobilePage.waitForTimeout(600);
    const mobileCanvas = mobilePage.locator('.sg-game-canvas').first();
    await mobileCanvas.screenshot({ path: path.join(outDir, 'react_lobby_mobile390.png') });
    console.log('Saved react_lobby_mobile390.png');

    // 6. Capture Real Lobby Screen on Landscape Mobile (844x440)
    await landscapePage.goto('http://localhost:5199/real-lua-e2e.html', { waitUntil: 'domcontentloaded' });
    await landscapePage.waitForFunction(() => (window as any).__tqsRealLuaE2e?.ready);
    await landscapePage.evaluate(() => (window as any).__tqsRealLuaE2e.beginRoomPacks());
    await landscapePage.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    await landscapePage.waitForTimeout(600);
    const landscapeCanvas = landscapePage.locator('.sg-game-canvas').first();
    await landscapeCanvas.screenshot({ path: path.join(outDir, 'react_lobby_landscape.png') });
    console.log('Saved react_lobby_landscape.png');

    // 7. Capture Real Lobby Screen on Desktop (1040x700)
    await desktopPage.goto('http://localhost:5199/real-lua-e2e.html', { waitUntil: 'domcontentloaded' });
    await desktopPage.waitForFunction(() => (window as any).__tqsRealLuaE2e?.ready);
    await desktopPage.evaluate(() => (window as any).__tqsRealLuaE2e.beginRoomPacks());
    await desktopPage.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    await desktopPage.waitForTimeout(600);
    const desktopCanvas = desktopPage.locator('.sg-game-canvas').first();
    await desktopCanvas.screenshot({ path: path.join(outDir, 'react_lobby_desktop.png') });
    console.log('Saved react_lobby_desktop.png');

    // 8. Capture Real Waiting Room on Mobile (390x844)
    await mobilePage.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
    await mobilePage.evaluate(() => (window as any).__tqsRealLuaE2e.acknowledgeCreatedRoom());
    await mobilePage.getByRole('heading', { name: 'Danh sách người chơi' }).waitFor();
    await mobilePage.waitForTimeout(600);
    const mobileWaitCanvas = mobilePage.locator('.sg-game-canvas').first();
    await mobileWaitCanvas.screenshot({ path: path.join(outDir, 'react_waiting_room_mobile390.png') });
    console.log('Saved react_waiting_room_mobile390.png');

    // 9. Capture Real Waiting Room on Desktop (1040x700)
    await desktopPage.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
    await desktopPage.evaluate(() => (window as any).__tqsRealLuaE2e.acknowledgeCreatedRoom());
    await desktopPage.getByRole('heading', { name: 'Danh sách người chơi' }).waitFor();
    await desktopPage.waitForTimeout(600);
    const desktopWaitCanvas = desktopPage.locator('.sg-game-canvas').first();
    await desktopWaitCanvas.screenshot({ path: path.join(outDir, 'react_waiting_room_desktop.png') });
    console.log('Saved react_waiting_room_desktop.png');

  } finally {
    await browser.close();
    await server.close();
  }

  console.log('All real React screenshots captured successfully!');
}

capture().catch((err) => {
  console.error('Capture failed:', err);
  process.exit(1);
});
