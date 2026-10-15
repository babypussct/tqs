import { generateKeyPairSync } from 'node:crypto';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { zipSync } from 'fflate';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';
import { loadUpstreamFiles } from './upstream-packages';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';
const root = fileURLToPath(new URL('../', import.meta.url));
const upstream = fileURLToPath(new URL('../../../scratch/upstream/', import.meta.url));

const executablePath = [
  process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
].find((p): p is string => !!p && existsSync(p));

if (!executablePath) throw new Error('Chrome missing: set TQS_CHROME_PATH');

async function capture() {
  const files = Object.fromEntries(loadUpstreamFiles(upstream));
  const zipped = Buffer.from(zipSync(files, { level: 1 }));
  const { publicKey } = generateKeyPairSync('rsa', {
    modulusLength: 1024,
    publicExponent: 0x10001,
    publicKeyEncoding: { type: 'pkcs1', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs1', format: 'pem' },
  });

  const vite = await createServer({
    root,
    configFile: fileURLToPath(new URL('../vite.config.ts', import.meta.url)),
    server: { host: '127.0.0.1', port: 0, strictPort: false },
  });

  await vite.listen();
  const baseURL = vite.resolvedUrls?.local[0];
  if (!baseURL) throw new Error('Vite did not expose a local URL');

  console.log(`Vite started at ${baseURL}`);

  const browser = await chromium.launch({
    executablePath,
    headless: true,
  });

  try {
    const page = await browser.newPage({
      baseURL,
      viewport: { width: 1280, height: 900 },
      deviceScaleFactor: 2,
    });
    page.on('console', (msg) => console.log('PAGE LOG:', msg.text()));
    page.on('pageerror', (err) => console.error('PAGE ERROR:', err));
    page.setDefaultTimeout(30_000);

    await page.route('**/__tqs_fixture_lua.zip', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'application/zip',
        body: zipped,
      })
    );
    await page.route('**/__tqs_fixture_key.txt', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'text/plain',
        body: publicKey,
      })
    );

    console.log('Navigating to /real-lua-e2e.html...');
    await page.goto('/real-lua-e2e.html');

    await page.waitForFunction(
      () => (window as any).__tqsRealLuaE2e?.ready || !!(window as any).__tqsRealLuaE2e?.bootError,
      undefined,
      { timeout: 90_000 }
    );

    const bootError = await page.evaluate(() => (window as any).__tqsRealLuaE2e?.bootError);
    if (bootError) throw new Error(`Boot error: ${bootError}`);

    console.log('Lua runtime ready in harness. Beginning play with active request...');

    // Begin play with skills and PlayCard active request
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.beginPlay(true);
    });
    await page.waitForTimeout(1000);

    // Populate extra hand cards and table state
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      const notify = api.boardNotify;

      // Draw 3 more cards to give a rich 5-card hand
      const cardIds = [15, 26, 42];
      const moves = cardIds.map((id) => `{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
        moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}`).join(',');
      notify('MoveCards', `{{${moves}}, 1}`);

      // Set generals on bot and self: Self has revealed main (Biện Phu Nhân) and unrevealed deputy (Điển Vi)
      notify('SetPlayerMark', "{17, '__heg_general', 'ld__bianfuren'}");
      notify('SetPlayerMark', "{17, '__heg_deputy', 'm_heg__dianwei'}");
      notify('PropertyUpdate', "{17, 'general', 'ld__bianfuren'}");
      notify('PropertyUpdate', "{17, 'deputyGeneral', 'anjiang'}");
      notify('PropertyUpdate', "{17, 'role_shown', true}");
      notify('VisibleKingdom', "{17, 'wei'}");
      notify('PropertyUpdate', "{-1, 'general', 'caocao'}");
      notify('PropertyUpdate', "{-1, 'deputyGeneral', 'liubei'}");
      notify('PropertyUpdate', "{-1, 'role_shown', true}");
      notify('VisibleKingdom', "{-1, 'wei'}");

      // Table pile and player state
      const store = api.store;
      const currentBoard = store.getState().board;
      const p17 = currentBoard.player[17] || {};
      store.getState().update({
        board: {
          ...currentBoard,
          drawPileCount: 98,
          discardPileCount: 12,
          player: {
            ...currentBoard.player,
            [17]: {
              ...p17,
              general: 'ld__bianfuren',
              deputyGeneral: null,
              selfGeneral: 'ld__bianfuren',
              selfDeputyGeneral: 'm_heg__dianwei',
              roleShown: true,
              visibleKingdom: 'wei',
            }
          },
          processingCards: [
            { id: 999, name: 'slash', suit: 1, number: 7 }
          ],
        }
      });
    });

    await page.waitForTimeout(1000);

    // Click the first card in hand to select it and show card lift + action buttons
    const firstCard = page.locator('.gameplay-hand button.gameplay-choice').first();
    if (await firstCard.count() > 0) {
      await firstCard.click();
      console.log('Selected first hand card');
    }
    await page.waitForTimeout(600);

    // 1. Capture 1280px Desktop Board (Viewport)
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'real_gameplay_1280_desktop.png'), fullPage: false });
    console.log('Saved real_gameplay_1280_desktop.png');

    // 2. Capture Bottom Dashboard Zoom in Desktop
    const dashboard = page.locator('.board-local-dashboard');
    if (await dashboard.count() > 0) {
      await dashboard.scrollIntoViewIfNeeded();
      await page.screenshot({ path: path.join(outDir, 'real_gameplay_bottom_dashboard_reformed.png'), fullPage: false });
      console.log('Saved real_gameplay_bottom_dashboard_reformed.png');
    }

    // 3. Capture 390px Mobile Viewport
    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_mobile.png'), fullPage: false });
    await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_fullpage.png'), fullPage: true });

    const mobileDashboard = page.locator('.board-local-dashboard');
    if (await mobileDashboard.count() > 0) {
      await mobileDashboard.scrollIntoViewIfNeeded();
      await page.screenshot({ path: path.join(outDir, 'real_gameplay_390_bottom_dashboard.png'), fullPage: false });
    }
    console.log('Saved real_gameplay_390_mobile.png, fullpage & bottom dashboard');

    // 4. Capture 360px Mobile Viewport
    await page.setViewportSize({ width: 360, height: 800 });
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'real_gameplay_360_mobile.png'), fullPage: true });
    console.log('Saved real_gameplay_360_mobile.png');

  } finally {
    await browser.close();
    await vite.close();
  }

  console.log('Done capturing real gameplay screens!');
}

capture().catch((e) => {
  console.error(e);
  process.exit(1);
});
