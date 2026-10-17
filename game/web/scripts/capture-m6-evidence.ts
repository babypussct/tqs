import { generateKeyPairSync } from 'node:crypto';
import { existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { zipSync } from 'fflate';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';
import { loadUpstreamFiles } from './upstream-packages';

const outDir = process.env.TQS_CAPTURE_OUT_DIR || '/Users/otada/.gemini/antigravity/brain/0c526d04-3873-40d7-8f73-d4599c2f79a6';
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

async function run() {
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

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
      viewport: { width: 390, height: 844 },
      deviceScaleFactor: 2,
    });
    page.setDefaultTimeout(30_000);

    await page.route('**/__tqs_fixture_lua.zip', (route) =>
      route.fulfill({ status: 200, contentType: 'application/zip', body: zipped })
    );
    await page.route('**/__tqs_fixture_key.txt', (route) =>
      route.fulfill({ status: 200, contentType: 'text/plain', body: publicKey })
    );

    // Use the visual-only harness mode: it mounts the production lobby/room/
    // board components but omits the test control panel and keeps the shell
    // composition aligned with App.tsx for screenshot review.
    await page.goto('/real-lua-e2e.html?visual=1');
    await page.waitForFunction(
      () => (window as any).__tqsRealLuaE2e?.ready || !!(window as any).__tqsRealLuaE2e?.bootError,
      undefined,
      { timeout: 90_000 }
    );

    const bootError = await page.evaluate(() => (window as any).__tqsRealLuaE2e?.bootError);
    if (bootError) throw new Error(`Boot error: ${bootError}`);

    console.log('1. Capturing 390x844 portrait lobby...');
    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() => (window as any).__tqsRealLuaE2e.beginRoomPacks());
    await page.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, '390_portrait_lobby.png') });
    console.log('Saved 390_portrait_lobby.png');

    console.log('2. Capturing 390x844 portrait waiting room...');
    await page.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
    await page.evaluate(() => (window as any).__tqsRealLuaE2e.acknowledgeCreatedRoom());
    await page.getByRole('heading', { name: 'Danh sách người chơi' }).waitFor();
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, '390_portrait_waiting_room.png') });
    console.log('Saved 390_portrait_waiting_room.png');

    console.log('3. Capturing 390x844 portrait board with prompt...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.beginPlay(true);
      const equipId = api.getConn().lua.eval(`return table.find(ClientInstance.draw_pile, function(id)
        return Fk:getCardById(id).type == Card.TypeEquip end)`);
      api.boardNotify('MoveCards', `{{{to=17, toArea=Card.PlayerEquip, moveReason=fk.ReasonPut,
        moveInfo={{cardId=${equipId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`);
    });
    await page.waitForTimeout(800);
    await page.screenshot({ path: path.join(outDir, '390_portrait_board_prompt.png') });
    console.log('Saved 390_portrait_board_prompt.png');

    console.log('4. Capturing 390x844 portrait board with target overlay...');
    // Select card to activate target mode
    const firstCard = page.locator('.gameplay-hand button.gameplay-choice:enabled').first();
    if (await firstCard.count() > 0) {
      await firstCard.click();
      await page.waitForTimeout(500);
    }
    await page.screenshot({ path: path.join(outDir, '390_portrait_board_target.png') });
    console.log('Saved 390_portrait_board_target.png');

    console.log('4b. Capturing 390x844 portrait board with ten-card hand...');
    await page.evaluate(() => (window as any).__tqsRealLuaE2e.beginVisualHand(10));
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, '390_portrait_board_many_hand.png') });
    console.log('Saved 390_portrait_board_many_hand.png');

    console.log('4c. Capturing mobile long-press card detail sheet...');
    const inspectCard = page.locator('.gameplay-hand button.gameplay-choice:enabled').first();
    await inspectCard.dispatchEvent('pointerdown', { pointerType: 'touch', button: 0 });
    await page.waitForTimeout(650);
    await inspectCard.dispatchEvent('pointerup', { pointerType: 'touch', button: 0 });
    await page.getByRole('dialog').waitFor();
    await page.screenshot({ path: path.join(outDir, 'dialog_card_detail_long_press.png') });
    console.log('Saved dialog_card_detail_long_press.png');
    await page.keyboard.press('Escape');

    console.log('5. Capturing 1280x720 landscape board...');
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, '1280x720_landscape_board.png') });
    console.log('Saved 1280x720_landscape_board.png');

    console.log('6. Capturing 2 players layout...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.boardNotify('ArrangeSeats', '{17, -1}');
    });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'board_2_players.png') });
    console.log('Saved board_2_players.png');

    console.log('7. Capturing 4 players layout...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.boardNotify('AddPlayer', "{18, 'Gia Cát Lượng', 'avatar', true, 0}");
      api.boardNotify('AddPlayer', "{19, 'Tư Mã Ý', 'avatar', true, 0}");
      api.boardNotify('ArrangeSeats', '{17, -1, 18, 19}');
    });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'board_4_players.png') });
    console.log('Saved board_4_players.png');

    console.log('7b. Capturing 4 players layout in 844x390 mobile landscape...');
    await page.setViewportSize({ width: 844, height: 390 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, '844x390_landscape_mobile_4_players.png') });
    console.log('Saved 844x390_landscape_mobile_4_players.png');

    console.log('8. Capturing 8 players layout...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      for (let id = 20; id <= 23; id++) {
        api.boardNotify('AddPlayer', `{${id}, 'Tướng ${id}', 'avatar', true, 0}`);
      }
      api.boardNotify('ArrangeSeats', '{17, -1, 18, 19, 20, 21, 22, 23}');
    });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'board_8_players.png') });
    console.log('Saved board_8_players.png');

    console.log('8b. Capturing 8 players layout in 390x844 portrait...');
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, '390_portrait_board_8_players.png') });
    console.log('Saved 390_portrait_board_8_players.png');
    await page.setViewportSize({ width: 1280, height: 720 });

    console.log('9. Capturing hidden main/deputy presentation...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.boardNotify('SetPlayerMark', "{17, '__heg_general', 'caocao'}");
      api.boardNotify('SetPlayerMark', "{17, '__heg_deputy', 'guojia'}");
      api.boardNotify('PropertyUpdate', "{17, 'general', 'anjiang'}");
      api.boardNotify('PropertyUpdate', "{17, 'deputyGeneral', 'anjiang'}");
      api.boardNotify('PropertyUpdate', "{17, 'role_shown', false}");
      const store = api.store;
      const b = store.getState().board;
      const p17 = b.player[17] || {};
      store.getState().update({
        board: {
          ...b,
          player: {
            ...b.player,
            [17]: {
              ...p17,
              general: null,
              deputyGeneral: null,
              selfGeneral: 'caocao',
              selfDeputyGeneral: 'guojia',
              roleShown: false,
              visibleKingdom: null,
            }
          }
        }
      });
    });
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(outDir, 'board_hidden_generals.png') });
    console.log('Saved board_hidden_generals.png');

    console.log('10. Capturing card selection dialog...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.beginQaScenario('card-chosen');
    });
    await page.getByRole('region', { name: 'Chọn bài đối thủ' }).waitFor();
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'dialog_card_selection.png') });
    console.log('Saved dialog_card_selection.png');

    console.log('11. Capturing skill invoke prompt dialog...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.begin();
    });
    await page.getByRole('heading', { name: 'Kích hoạt kỹ năng?' }).waitFor();
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'dialog_skill_invoke.png') });
    console.log('Saved dialog_skill_invoke.png');

    console.log('12. Capturing expired dialog...');
    await page.evaluate(() => {
      const api = (window as any).__tqsRealLuaE2e;
      api.begin(true); // begin with expired=true
    });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, 'dialog_expired.png') });
    console.log('Saved dialog_expired.png');

    console.log('All M6 evidence screenshots captured successfully!');
  } finally {
    await browser.close();
    await vite.close();
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
