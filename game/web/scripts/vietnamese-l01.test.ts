/** C01/L01 regression: pinned Hegemony keys, public log text and React/Wasmoon fixture. */
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { zipSync } from 'fflate';
import { chromium } from 'playwright-core';
import { createServer } from 'vite';
import { validChoiceReply, parseChoicePrompt } from '../src/engine/choiceSelection';
import { displayText, localizedGameLog } from '../src/engine/displayText';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import { loadUpstreamFiles } from './upstream-packages';

const webRoot = fileURLToPath(new URL('../', import.meta.url));
const pinnedPackages = fileURLToPath(new URL('../../../scratch/upstream/', import.meta.url));
const readPinned = (file: string) => readFileSync(path.join(pinnedPackages, 'hegemony', file), 'utf8');

test('C01 exact package-pin skills and variants, including conditional choice rules', () => {
  const huoshui = readPinned('pkg/standard/skills/huoshui.lua');
  const lixia = readPinned('pkg/lord_ex/skills/lixia.lua');
  const qingcheng = readPinned('pkg/standard/skills/qingcheng.lua');
  const biluan = readPinned('pkg/lord_ex/skills/biluan.lua');
  const standard = readPinned('pkg/standard/init.lua');
  const lord = readPinned('pkg/lord_ex/init.lua');
  assert.match(standard, /"hs__zoushi"[^\n]*"huoshui", "qingcheng"/);
  assert.match(lord, /shixie:addSkills\{ "ld__biluan", "ld__lixia" \}/);
  assert.match(huoshui, /name = "huoshui"/);
  assert.match(huoshui, /data\.prohibitedCardNames.*or \{\}/);
  assert.match(huoshui, /"jink"/);
  assert.match(huoshui, /MarkEnum\.RevealProhibited/);
  assert.match(lixia, /name = "ld__lixia"/);
  assert.match(lixia, /target\.phase == Player\.Start/);
  assert.match(lixia, /not target:inMyAttackRange\(player\)/);
  assert.match(lixia, /#player:getCardIds\("e"\) > 0/);
  assert.match(lixia, /"ld__lixia_drawcards:" \.\. player\.id/);
  assert.match(lixia, /"ld__lixia_loseHp:" \.\. player\.id/);
  assert.match(lixia, /room:loseHp\(target, 1, lixia\.name\)/);
  assert.match(qingcheng, /Card\.Black/);
  assert.match(biluan, /#to\.player_cards\[Player\.Equip\]/);
  assert.equal(VI_ADDITIONS.huoshui, 'Họa Thủy');
  assert.match(VI_ADDITIONS[':huoshui'], /Khóa định.*lật tướng.*Thiểm/);
  assert.match(VI_ADDITIONS[':ld__lixia'], /Khóa định.*chuẩn bị.*ngoài phạm vi.*rút 1 lá.*mất 1 máu/);
  assert.match(VI_ADDITIONS[':qingcheng'], /Đen.*úp một tướng.*trang bị màu Đen/);
  assert.match(VI_ADDITIONS[':ld__biluan'], /\+X.*trang bị/);
  assert.equal(VI_ADDITIONS['hs__weimu'], 'Vi Mộ',
    'reviewed skill names must override the broad official catalog');
  assert.match(VI_ADDITIONS[':hs__weimu'], /^TOẢ ĐỊNH KỸ,/,
    'reviewed skill descriptions must override machine/baseline wording');
  for (const key of ['hs__zoushi', '#hs__zoushi', '~hs__zoushi', '$qingcheng1', '$qingcheng2',
    'ld__shixie', '#ld__shixie', '~ld__shixie']) {
    assert.ok(VI_ADDITIONS[key] && !/[\u3400-\u9fff]/.test(VI_ADDITIONS[key]), key);
  }
});

test('C01 choice labels display players; raw Lua option identifiers remain valid for replies', () => {
  const player = [{ id: 17, name: 'Sĩ Nhiếp' }];
  const choices = ['ld__lixia_drawcards:17', 'ld__lixia_loseHp:17'];
  assert.equal(displayText(choices[0], VI_ADDITIONS, player), 'Cho Sĩ Nhiếp rút 1 lá bài');
  assert.equal(displayText(choices[1], VI_ADDITIONS, player),
    'Bỏ 1 lá trong khu trang bị của Sĩ Nhiếp và mất 1 máu');
  const prompt = parseChoicePrompt([choices, choices, [1, 1], false, 'ld__lixia', '', false, true]);
  assert.ok(prompt);
  assert.equal(validChoiceReply(prompt, [choices[0]]), true);
  assert.equal(validChoiceReply(prompt, [choices[1]]), true);
  assert.equal(validChoiceReply(prompt, ['Cho Sĩ Nhiếp rút 1 lá bài']), false);
  assert.equal(displayText(':huoshui', VI_ADDITIONS), VI_ADDITIONS[':huoshui']);
  assert.equal(displayText(':ld__lixia', VI_ADDITIONS), VI_ADDITIONS[':ld__lixia']);
  assert.equal(displayText('huoshui', VI_ADDITIONS), 'Họa Thủy');
  assert.equal(displayText('ld__lixia', VI_ADDITIONS), 'Lễ Hạ');
});

test('C01 public log is localized only in exact skill markers', () => {
  const examples = [
    ['Trâu Thị/Tướng ẩn (bạn) đã phát động kỹ năng〖祸水〗',
      'Trâu Thị / Tướng ẩn (bạn) đã phát động kỹ năng〖Họa Thủy〗'],
    ['Trâu Thị/Sĩ Nhiếp (bạn) đã phát động kỹ năng〖礼下〗',
      'Trâu Thị / Sĩ Nhiếp (bạn) đã phát động kỹ năng〖Lễ Hạ〗'],
    ['Trâu Thị/Sĩ Nhiếp (bạn) đã phát động kỹ năng〖祸水〗',
      'Trâu Thị / Sĩ Nhiếp (bạn) đã phát động kỹ năng〖Họa Thủy〗'],
    ['Trâu Thị/Sĩ Nhiếp đã phát động kỹ năng〖倾城〗 và〖避乱〗',
      'Trâu Thị / Sĩ Nhiếp đã phát động kỹ năng〖Khuynh Thành〗 và〖Tị Loạn〗'],
    ['Tôn Sâm / Tướng ẩn nhận 〖野心家〗',
      'Tôn Sâm / Tướng ẩn nhận 〖Dã tâm gia〗'],
  ] as const;
  for (const [source, expected] of examples) assert.equal(localizedGameLog(source), expected);
  assert.equal(localizedGameLog('Trâu Thị đã phát động kỹ năng 礼下'), 'Trâu Thị đã phát động kỹ năng Lễ Hạ');
  assert.equal(localizedGameLog('Không đổi nguyên văn: 祸水 / 礼下'), 'Không đổi nguyên văn: 祸水 / 礼下');
  assert.equal(localizedGameLog('〖祸水-unknown〗'), '〖祸水-unknown〗');
  assert.equal(localizedGameLog('〖&lt;script&gt;祸水&lt;/script&gt;〗'),
    '〖<script>祸水</script>〗');
  assert.equal(localizedGameLog('Biện Phu Nhân/Điên Vi (bạn) rút liễu 1 lá lá bài Sát[♠5]'),
    'Biện Phu Nhân / Điển Vi (bạn) rút 1 lá bài Sát[♠5]');
  assert.equal(localizedGameLog('Điên Vi rút liêu 2 lá bài'), 'Điển Vi rút 2 lá bài');
  assert.equal(localizedGameLog('Tướng ẩn / Vương Lăng (bạn) phát động liễu 〖os__mibei〗'),
    'Tướng ẩn / Vương Lăng (bạn) phát động 〖Mật Bị〗');
  assert.equal(localizedGameLog('Tào Hồng / Vương Lăng (bạn) rút 2 lá bài 太平要术[♥3], Thiểm[♥J] (Giai đoạn rút bài)'),
    'Tào Hồng / Vương Lăng (bạn) rút 2 lá bài Thái Bình Yếu Thuật[♥3], Thiểm[♥J] (Giai đoạn rút bài)');
  assert.equal(localizedGameLog('Tào Hồng / Vương Lăng (bạn) tá zai liễu 太平要术[♥3]'),
    'Tào Hồng / Vương Lăng (bạn) được trang bị Thái Bình Yếu Thuật[♥3]');
  assert.equal(localizedGameLog('Tào Hồng / Vương Lăng (bạn) mất liễu 1 máu (太平要术)'),
    'Tào Hồng / Vương Lăng (bạn) mất 1 máu (Thái Bình Yếu Thuật)');
  assert.equal(localizedGameLog('Tào Hồng / Vương Lăng (bạn) Lượt Phục liễu 1 máu (星启)'),
    'Tào Hồng / Vương Lăng (bạn) hồi phục 1 máu (Tinh Khởi)');
  assert.equal(localizedGameLog('Tướng ẩn / Lữ Đại rút 2 lá bài bài không xác định (以逸待劳)'),
    'Tướng ẩn / Lữ Đại rút 2 lá bài bài không xác định (Dĩ Dật Đãi Lao)');
  assert.equal(VI_ADDITIONS.ol__guohuai, 'Quách Hoài');
  assert.equal(VI_ADDITIONS.ty_heg__yangwan, 'Dương Uyển');
});

test('C01 pinned Lua Fk:translate, React public DOM logs and options; no hidden data/replies',
  { timeout: 180_000 }, async () => {
    const chrome = [process.env.TQS_CHROME_PATH,
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
    ].find((item): item is string => !!item && existsSync(item));
    assert.ok(chrome, 'Chrome executable required for real React DOM check');
    const files = Object.fromEntries(loadUpstreamFiles(pinnedPackages));
    const zipped = Buffer.from(zipSync(files, { level: 1 }));
    const { publicKey } = generateKeyPairSync('rsa', { modulusLength: 1024,
      publicKeyEncoding: { type: 'pkcs1', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs1', format: 'pem' } });
    const vite = await createServer({ root: webRoot,
      configFile: path.join(webRoot, 'vite.config.ts'),
      server: { host: '127.0.0.1', port: 0, strictPort: false },
    });
    let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
    try {
      await vite.listen();
      const baseURL = vite.resolvedUrls?.local[0];
      assert.ok(baseURL);
      browser = await chromium.launch({ executablePath: chrome, headless: true });
      const page = await browser.newPage({ baseURL, viewport: { width: 390, height: 844 } });
      page.setDefaultTimeout(12_000);
      const pageErrors: string[] = [];
      page.on('pageerror', (e) => pageErrors.push(e.message));
      await page.route('**/__tqs_fixture_lua.zip', (route) => route.fulfill({
        status: 200, contentType: 'application/zip', body: zipped }));
      await page.route('**/__tqs_fixture_key.txt', (route) => route.fulfill({
        status: 200, contentType: 'text/plain', body: publicKey }));
      await page.goto('/real-lua-e2e.html');
      await page.waitForFunction(() => window.__tqsRealLuaE2e.ready || !!window.__tqsRealLuaE2e.bootError,
        undefined, { timeout: 90_000 });
      assert.equal(await page.evaluate(() => window.__tqsRealLuaE2e.bootError), null);
      const keys = ['huoshui', ':huoshui', 'qingcheng', ':qingcheng', '#qingcheng-again',
        'ld__lixia', ':ld__lixia', 'ld__lixia_drawcards', 'ld__lixia_loseHp',
        'ld__biluan', ':ld__biluan', 'hs__zoushi', '$qingcheng1',
        'ld__shixie', '~ld__shixie'];
      const values = await page.evaluate((q) => window.__tqsRealLuaE2e.localizedLabels(q), keys);
      assert.equal(values[0], 'Họa Thủy');
      assert.match(values[1], /Thiểm/);
      assert.equal(values[2], 'Khuynh Thành');
      assert.equal(values[5], 'Lễ Hạ');
      assert.match(values[6], /ngoài phạm vi/);
      assert.match(values[7], /%src/);
      assert.match(values[8], /%src/);
      assert.equal(values[9], 'Tị Loạn');
      assert.equal(values[11], 'Trâu Thị');
      assert.equal(values[12], 'Ta thật có duyên với các ngươi.');
      assert.equal(values[13], 'Sĩ Nhiếp');
      assert.match(values[14], /đã đủ rồi/);

      await page.evaluate(() => {
        window.__tqsRealLuaE2e.beginPlay();
        for (const line of [
          'Trâu Thị/Tướng ẩn (bạn) đã phát động kỹ năng〖祸水〗',
          'Trâu Thị/Sĩ Nhiếp (bạn) đã phát động kỹ năng〖礼下〗',
          'Trâu Thị/Sĩ Nhiếp (bạn) đã phát động kỹ năng〖祸水〗',
        ]) {
          window.__tqsRealLuaE2e.boardNotify('GameLog', `{type='${line}'}`);
        }
      });
      const log = page.getByRole('region', { name: 'Nhật ký trận đấu' });
      const openLog = page.getByRole('button', { name: 'Lịch sử', exact: true });
      if (await openLog.count()) await openLog.click();
      await log.getByText('Trâu Thị / Tướng ẩn (bạn) đã phát động kỹ năng〖Họa Thủy〗', { exact: true }).waitFor();
      await log.getByText('Trâu Thị / Sĩ Nhiếp (bạn) đã phát động kỹ năng〖Lễ Hạ〗', { exact: true }).waitFor();
      await log.getByText('Trâu Thị / Sĩ Nhiếp (bạn) đã phát động kỹ năng〖Họa Thủy〗', { exact: true }).waitFor();
      assert.equal(await log.getByText(/祸水|礼下/).count(), 0);
      assert.equal(await log.locator('script, img, iframe').count(), 0);
      assert.deepEqual((await page.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[-1].marks, {});
      const initial = await page.evaluate(() => window.__tqsRealLuaE2e.snapshot());
      assert.equal(initial.replies.length, 0);
      assert.deepEqual(initial.luaErrors, []);
      assert.deepEqual(pageErrors, []);
      // Same production React ChoicePanel; only the request fixture is injected.
      // No click is made because the actual server request here is PlayCard.
      await page.evaluate(async () => {
        const { useGameStore } = await import('/src/store/gameStore.ts');
        const store = useGameStore.getState();
        store.update({ players: [{ id: 17, name: 'Sĩ Nhiếp' }],
          pendingRequest: { ...store.pendingRequest!, command: 'AskForChoices', requestId: 9001,
            choicePrompt: { choices: ['ld__lixia_drawcards:17', 'ld__lixia_loseHp:17'],
              allChoices: ['ld__lixia_drawcards:17', 'ld__lixia_loseHp:17'],
              min: 1, max: 1, cancelable: false, skill: 'ld__lixia', prompt: '', single: true },
          },
        });
      });
      const panel = page.getByRole('region', { name: 'Lựa chọn trong trận' });
      await panel.getByRole('heading', { name: 'Lễ Hạ' }).waitFor();
      await panel.getByRole('button', { name: 'Cho Sĩ Nhiếp rút 1 lá bài' }).waitFor();
      await panel.getByRole('button', { name: 'Bỏ 1 lá trong khu trang bị của Sĩ Nhiếp và mất 1 máu' }).waitFor();
      assert.equal((await page.evaluate(() => window.__tqsRealLuaE2e.snapshot())).replies.length, 0);
      assert.deepEqual(pageErrors, []);
      const evidenceDir = fileURLToPath(new URL('../../../../reports/evidence/', import.meta.url));
      mkdirSync(evidenceDir, { recursive: true });
      await page.screenshot({ path: path.join(evidenceDir, 'C01-L01-react-dom-390.png'), fullPage: true });
      await page.close();
    } finally {
      await browser?.close();
      await vite.close();
    }
  });
