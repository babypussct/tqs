/** Isolated browser E2E: actual Wasmoon + FreeKill Lua and production skill
 * controls; server packets use a deterministic local socket fixture. */
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { zipSync } from 'fflate';
import { chromium, type Page } from 'playwright-core';
import { createServer } from 'vite';
import { CLIENT_NOTIFY } from '../../src/engine/packet';
import { loadUpstreamFiles } from '../upstream-packages';
import { QA_SCENARIOS, type QaScenarioId } from './qa-scenarios';

const root = fileURLToPath(new URL('../../', import.meta.url));
const upstream = fileURLToPath(new URL('../../../../scratch/upstream/', import.meta.url));
const executablePath = [process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
].find((p): p is string => !!p && existsSync(p));
if (!executablePath) throw new Error('Chrome missing: set TQS_CHROME_PATH');

const files = Object.fromEntries(loadUpstreamFiles(upstream));
const zipped = Buffer.from(zipSync(files, { level: 1 }));
const { publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 1024, publicExponent: 0x10001,
  publicKeyEncoding: { type: 'pkcs1', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs1', format: 'pem' },
});
console.log(`Real Lua fixture: ${Object.keys(files).length} files, ${zipped.byteLength} compressed bytes`);

type Snapshot = {
  status: string;
  requestId: number | null;
  skill: { skill: string; prompt: string } | null;
  fakeSkills: { name: string; prelighted: boolean; enabled: boolean }[];
  regularSkills: { name: string }[];
  error: string | null;
  luaErrors: string[];
  uiEvents: string[];
  sent: { socket: number; requestId: number; command: string; type: number; hex: string }[];
  replies: { socket: number; requestId: number; command: string; type: number; hex: string }[];
};
const snapshot = (page: Page): Promise<Snapshot> => page.evaluate(() => window.__tqsRealLuaE2e.snapshot());
async function start(page: Page, expired = false) {
  const id = await page.evaluate((value) => window.__tqsRealLuaE2e.begin(value), expired);
  const snap = await snapshot(page);
  assert.equal(snap.requestId, id);
  assert.equal(snap.status, 'online');
  assert.deepEqual(snap.luaErrors, []);
  assert.equal(snap.skill?.skill, 'web_test_skill');
  assert.equal(snap.skill?.prompt, 'Kích hoạt kỹ năng thử?');
  assert.equal(snap.replies.length, 0);
  assert.ok(snap.uiEvents.includes('AskForSkillInvoke'), 'Real Lua must produce the prompt event');
  return id;
}
async function reply(page: Page, count = 1) {
  await page.waitForFunction((n) => window.__tqsRealLuaE2e.snapshot().replies.length >= n, count);
  return snapshot(page);
}

const vite = await createServer({ root,
  configFile: fileURLToPath(new URL('../../vite.config.ts', import.meta.url)),
  server: { host: '127.0.0.1', port: 0, strictPort: false },
});
let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
try {
  await vite.listen();
  const baseURL = vite.resolvedUrls?.local[0];
  if (!baseURL) throw new Error('Vite did not expose a local URL');
  browser = await chromium.launch({ executablePath, headless: true });
  const page = await browser.newPage({ baseURL, viewport: { width: 390, height: 844 } });
  page.setDefaultTimeout(12_000);
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.route('**/__tqs_fixture_lua.zip', (route) => route.fulfill({
    status: 200, contentType: 'application/zip', body: zipped,
  }));
  await page.route('**/__tqs_fixture_key.txt', (route) => route.fulfill({
    status: 200, contentType: 'text/plain', body: publicKey,
  }));
  await page.goto('/real-lua-e2e.html');
  await page.waitForFunction(() => window.__tqsRealLuaE2e.ready || !!window.__tqsRealLuaE2e.bootError,
    undefined, { timeout: 90_000 });
  const bootError = await page.evaluate(() => window.__tqsRealLuaE2e.bootError);
  assert.equal(bootError, null, `Real Lua WASM boot failed: ${bootError}`);

  const tests: [string, (page: Page) => Promise<void>][] = [
    ['FreeKill Lua VM boots and produces actual skill prompt in React', async (p) => {
      await start(p);
      await p.getByRole('heading', { name: 'Kích hoạt kỹ năng?' }).waitFor();
      await p.getByText('Kích hoạt kỹ năng thử?').waitFor();
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
    ['Real Lua gameplay hand renders catalogue art and remains horizontally scrollable', async (p) => {
      const controls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
      const hand = controls.locator('.gameplay-hand');
      await p.setViewportSize({ width: 360, height: 844 });
      const { id: compactId, cardIds: compactCardIds } = await p.evaluate(() => window.__tqsRealLuaE2e.beginVisualHand(10));
      await hand.waitFor();
      await p.waitForFunction(() => {
        const images = [...document.querySelectorAll<HTMLImageElement>('.gameplay-hand .sg-card-native-art')];
        return images.length > 0 && images.every((image) => image.complete && image.naturalWidth > 0);
      });
      const compactMetrics = await hand.evaluate((element) => ({
        buttonCount: element.querySelectorAll('button.gameplay-choice').length,
        artCount: element.querySelectorAll('img.sg-card-native-art').length,
        clientWidth: element.clientWidth,
        scrollWidth: element.scrollWidth,
        overflowX: getComputedStyle(element).overflowX,
      }));
      assert.equal(compactMetrics.buttonCount, compactCardIds.length);
      assert.equal(compactMetrics.artCount, compactCardIds.length, 'every compact hand card needs catalogue art');
      assert.equal(compactMetrics.overflowX, 'auto');
      assert.ok(compactMetrics.scrollWidth <= compactMetrics.clientWidth,
        `ten cards should fit the mobile hand (${compactMetrics.scrollWidth} > ${compactMetrics.clientWidth})`);
      await hand.locator('button.gameplay-choice:enabled').last().click();
      assert.equal((await snapshot(p)).requestId, compactId);
      await p.evaluate(() => window.__tqsRealLuaE2e.finishGame());

      await p.setViewportSize({ width: 390, height: 844 });
      const { id, cardIds } = await p.evaluate(() => window.__tqsRealLuaE2e.beginVisualHand(12));
      await hand.waitFor();
      await p.waitForFunction(() => {
        const images = [...document.querySelectorAll<HTMLImageElement>('.gameplay-hand .sg-card-native-art')];
        return images.length > 0 && images.every((image) => image.complete && image.naturalWidth > 0);
      });
      const metrics = await hand.evaluate((element) => ({
        buttonCount: element.querySelectorAll('button.gameplay-choice').length,
        artCount: element.querySelectorAll('img.sg-card-native-art').length,
        artSources: [...element.querySelectorAll<HTMLImageElement>('img.sg-card-native-art')]
          .map((image) => image.getAttribute('src')),
        clientWidth: element.clientWidth,
        scrollWidth: element.scrollWidth,
        overflowX: getComputedStyle(element).overflowX,
      }));
      assert.equal(metrics.buttonCount, cardIds.length);
      assert.equal(metrics.artCount, cardIds.length, 'every real CardItem needs a catalogue/native art image');
      assert.ok(metrics.artSources.every((source) => source?.startsWith('/card-catalog-art/')),
        `unexpected gameplay card art sources: ${metrics.artSources.join(', ')}`);
      assert.equal(metrics.overflowX, 'auto');
      assert.ok(metrics.scrollWidth > metrics.clientWidth,
        `hand must expose horizontal scrolling (${metrics.scrollWidth} <= ${metrics.clientWidth})`);
      await hand.locator('button.gameplay-choice:enabled').last().click();
      assert.equal((await snapshot(p)).requestId, id);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
      await p.evaluate(() => window.__tqsRealLuaE2e.finishGame());
    }],
    ['Unsolicited Lua ReplyToServer does not send a packet', async (p) => {
      const id = await start(p);
      await p.evaluate(() => window.__tqsRealLuaE2e.unsolicited('1'));
      const s = await snapshot(p);
      assert.equal(s.requestId, id);
      assert.equal(s.replies.length, 0);
    }],
    ['Real Lua OK emits one exact 4131 CBOR CLIENT_REPLY', async (p) => {
      const id = await start(p);
      await p.getByRole('button', { name: 'Kích hoạt' }).click();
      const s = await reply(p);
      assert.deepEqual(s.replies.map(({ requestId, command, type, hex }) => ({ requestId, command, type, hex })),
        [{ requestId: id, command: '', type: 0x212, hex: '4131' }]);
      assert.equal(s.requestId, null);
      await p.waitForTimeout(75);
      assert.equal((await snapshot(p)).replies.length, 1);
    }],
    ['ex__fankui optional invoke prompt stays actionable and reaches card choice', async (p) => {
      const { id, cardId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginFankui());
      const first = await snapshot(p);
      assert.equal(first.requestId, id);
      assert.deepEqual(first.skill, { skill: 'ex__fankui', prompt: '' });
      assert.equal(await p.getByRole('heading', { name: 'Kích hoạt kỹ năng?' }).count(), 1);
      assert.equal(await p.getByRole('button', { name: 'Kích hoạt', exact: true }).isEnabled(), true);
      await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
      const invoked = await reply(p);
      assert.equal(invoked.replies.at(-1)?.requestId, id);
      assert.equal(invoked.replies.at(-1)?.hex, '4131');

      const cardRequestId = await p.evaluate(() => window.__tqsRealLuaE2e.continueFankui());
      const panel = p.getByRole('region', { name: 'Chọn bài đối thủ' });
      await panel.waitFor();
      const prompt = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt());
      assert.ok(prompt);
      assert.equal(prompt.mode, 'single');
      assert.equal(prompt.groups.flatMap((group) => group.cards).filter((card) => card.hidden).length, 1);
      await panel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      const chosen = await reply(p, 2);
      assert.equal(chosen.replies.at(-1)?.requestId, cardRequestId);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), cardId);
      assert.deepEqual(chosen.luaErrors, []);
    }],
    ['real Lua fake-trigger dock sends prelight and survives damage', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginFakePrelight());
      const skill = p.locator('button.fake-skill-button').first();
      await skill.waitFor();
      assert.equal(await skill.getAttribute('aria-pressed'), 'false');
      await skill.click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((packet) =>
        packet.command === 'PushRequest'));
      const beforeAck = await snapshot(p);
      const push = beforeAck.sent.find((packet) => packet.command === 'PushRequest');
      assert.ok(push);
      const expectedHex = await p.evaluate(() => window.__tqsRealLuaE2e.prelightWireHex());
      assert.equal(push.hex, expectedHex);
      await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgePrelight(true));
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
        skill.name === 'hs__yiji' && skill.prelighted));
      await p.evaluate(() => window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', "{17, 'hp', 3}"));
      const afterDamage = await snapshot(p);
      assert.equal(afterDamage.fakeSkills.find((skill) => skill.name === 'hs__yiji')?.prelighted, true);
      assert.deepEqual(afterDamage.luaErrors, []);
    }],
    ['hidden Quách Gia does not invoke Di Kế after damage without prelight', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginHiddenYijiDamage());
      const requestId = await p.evaluate(() => window.__tqsRealLuaE2e.triggerHiddenYijiDamage());
      assert.equal(requestId, null);
      const state = await snapshot(p);
      assert.equal(state.requestId, null);
      assert.equal(state.skill, null);
      assert.equal(state.fakeSkills.find((skill) => skill.name === 'hs__yiji')?.prelighted, false);
      const board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[17].hp, 3);
      assert.equal(board.player[17].general, null);
      assert.deepEqual(state.luaErrors, []);
    }],
    ['hidden Quách Gia keeps prelight through damage and invokes Di Kế before reveal', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginHiddenYijiDamage());
      const fakeYiji = p.locator('button.fake-skill-button').first();
      await fakeYiji.waitFor();
      assert.equal(await fakeYiji.getAttribute('aria-pressed'), 'false');

      await fakeYiji.click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((packet) =>
        packet.command === 'PushRequest'));
      await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgePrelight(true));
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
        skill.name === 'hs__yiji' && skill.prelighted));

      const id = await p.evaluate(() => window.__tqsRealLuaE2e.triggerHiddenYijiDamage());
      await p.getByRole('heading', { name: 'Kích hoạt kỹ năng?' }).waitFor();
      const damaged = await snapshot(p);
      assert.equal(damaged.requestId, id);
      assert.deepEqual(damaged.skill, {
        skill: 'hs__yiji', prompt: 'Quách Gia bị thương: có muốn kích hoạt Di Kế không?',
      });
      assert.equal(damaged.fakeSkills.find((skill) => skill.name === 'hs__yiji')?.prelighted, true,
        'damage must not clear the prelight decision before the invoke reply');
      assert.equal((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[17].hp, 3);

      await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
      const invoked = await reply(p);
      assert.equal(invoked.replies.at(-1)?.requestId, id);
      assert.equal(invoked.replies.at(-1)?.hex, '4131');

      await p.evaluate(() => window.__tqsRealLuaE2e.revealHiddenYiji());
      await p.waitForFunction(() => {
        const state = window.__tqsRealLuaE2e.snapshot();
        const board = window.__tqsRealLuaE2e.boardState();
        return !state.fakeSkills.some((skill) => skill.name === 'hs__yiji') &&
          state.regularSkills.some((skill) => skill.name === 'hs__yiji') &&
          board.player[17]?.general === 'hs__guojia';
      });
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['real Lua separates hidden trigger and active reveal skills, then gates reveal through SkillButton', async (p) => {
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.beginHiddenReveal());
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().regularSkills.some((skill) =>
        skill.name === 'reveal_skill&'));
      const projected = await snapshot(p);
      assert.deepEqual(projected.fakeSkills.map((skill) => skill.name), ['hs__yiji', 'hs__qianxun']);
      assert.deepEqual(projected.regularSkills.map((skill) => skill.name), ['reveal_skill&']);

      const reveal = p.locator('button.sg-skill-button').filter({ hasText: /Mở tướng|reveal_skill&/ }).first();
      const revealCount = await reveal.count();
      assert.equal(revealCount, 1, `reveal button missing: ${JSON.stringify({
        scene: (await snapshot(p)).scene,
        buttons: await p.locator('button.sg-skill-button').allTextContents(),
      })}`);
      await reveal.waitFor();
      assert.equal(await reveal.isEnabled(), true,
        'native active reveal must become actionable only after Lua publishes SkillButton.enabled');
      await reveal.click();
      const choices = p.getByRole('combobox', { name: 'Chọn phương án' });
      await choices.waitFor();
      const optionValues = await choices.locator('option').evaluateAll((options) =>
        options.map((option) => (option as HTMLOptionElement).value));
      assert.deepEqual(optionValues, ['revealMain:::hs__luxun']);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const result = await reply(p);
      assert.equal(result.replies.at(-1)?.requestId, id);
      assert.deepEqual(result.luaErrors, []);
    }],
    ['Real Lua Cancel emits exact 485f5f63616e63656c reply', async (p) => {
      const id = await start(p);
      await p.getByRole('button', { name: 'Bỏ qua' }).click();
      const s = await reply(p);
      assert.deepEqual(s.replies.map(({ requestId, command, type, hex }) => ({ requestId, command, type, hex })),
        [{ requestId: id, command: '', type: 0x212, hex: '485f5f63616e63656c' }]);
      assert.equal(s.requestId, null);
    }],
    ['Duplicate OK is blocked after Lua reply', async (p) => {
      const id = await start(p);
      await p.getByRole('button', { name: 'Kích hoạt' }).click();
      await reply(p);
      const err = await p.evaluate((requestId) => window.__tqsRealLuaE2e.attempt(requestId), id);
      assert.match(err ?? '', /không còn hiệu lực/);
      assert.equal((await snapshot(p)).replies.length, 1);
    }],
    ['Replaced request rejects old reply and accepts current one', async (p) => {
      const oldId = await start(p);
      const newId = await p.evaluate(() => window.__tqsRealLuaE2e.replace());
      assert.equal((await snapshot(p)).requestId, newId);
      assert.match(await p.evaluate((id) => window.__tqsRealLuaE2e.attempt(id), oldId) ?? '', /không còn hiệu lực/);
      await p.getByRole('button', { name: 'Kích hoạt' }).click();
      const s = await reply(p);
      assert.equal(s.replies.length, 1);
      assert.equal(s.replies[0].requestId, newId);
    }],
    ['Expired Lua request blocks React buttons and transport reply', async (p) => {
      const id = await start(p, true);
      assert.equal(await p.getByRole('button', { name: 'Kích hoạt' }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Bỏ qua' }).isDisabled(), true);
      assert.match(await p.evaluate((n) => window.__tqsRealLuaE2e.attempt(n), id) ?? '', /hết thời gian/);
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
    ['Disconnect invalidates request without sending', async (p) => {
      const id = await start(p);
      await p.evaluate(() => window.__tqsRealLuaE2e.disconnect());
      assert.equal((await snapshot(p)).status, 'closed');
      assert.match(await p.evaluate((n) => window.__tqsRealLuaE2e.attempt(n), id) ?? '', /không còn hiệu lực/);
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
    ['Reused request ID does not accept events from previous socket', async (p) => {
      const id = await start(p);
      const oldSocketIndex = await p.evaluate(() => window.__tqsRealLuaE2e.reconnectSameId());
      await p.evaluate((index) => window.__tqsRealLuaE2e.oldSocketRequest(index), oldSocketIndex);
      assert.equal((await snapshot(p)).requestId, id);
      await p.getByRole('button', { name: 'Kích hoạt' }).click();
      const s = await reply(p);
      assert.equal(s.replies.length, 1);
      assert.equal(s.replies[0].requestId, id);
      assert.notEqual(s.replies[0].socket, oldSocketIndex);
    }],
    ['ChoicePanel multi-select only replies after confirmation with a Lua CBOR array', async (p) => {
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices());
      assert.equal(await p.getByRole('button', { name: 'disabled', exact: true }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Xác nhận lựa chọn', exact: true }).isDisabled(), true);
      await p.getByRole('button', { name: 'main', exact: true }).click();
      await p.getByRole('button', { name: 'deputy', exact: true }).click();
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.getByRole('button', { name: 'Xác nhận lựa chọn', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.requestId, null);
      assert.deepEqual(s.replies.map(({ requestId, hex }) => ({ requestId, hex })),
        [{ requestId: id, hex: '82446d61696e46646570757479' }]);
      assert.deepEqual(s.luaErrors, []);
    }],
    ['ChoicePanel single-select immediately sends one choice and cancel sends an empty array', async (p) => {
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices(true));
      await p.getByRole('button', { name: 'deputy', exact: true }).click();
      const s = await reply(p);
      assert.deepEqual(s.replies.map(({ requestId, hex }) => ({ requestId, hex })),
        [{ requestId: id, hex: '8146646570757479' }]);
      const canceledId = await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices());
      await p.getByRole('button', { name: 'Bỏ qua lựa chọn', exact: true }).click();
      const canceled = await reply(p);
      assert.deepEqual(canceled.replies.map(({ requestId, hex }) => ({ requestId, hex })),
        [{ requestId: canceledId, hex: '80' }]);
    }],
    ['ChoicePanel resets selections on a replacement request and disables expired controls', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices());
      await p.getByRole('button', { name: 'main', exact: true }).click();
      await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices());
      assert.equal(await p.getByRole('button', { name: 'main', exact: true }).getAttribute('aria-pressed'), 'false');
      assert.equal(await p.getByRole('button', { name: 'Xác nhận lựa chọn', exact: true }).isDisabled(), true);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices(false, true));
      assert.equal(await p.getByRole('button', { name: 'main', exact: true }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Bỏ qua lựa chọn', exact: true }).isDisabled(), true);
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
    ['BOT control sends native Trust and waits for server state without a gameplay reply', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      await p.getByRole('button', { name: 'BOT chơi hộ', exact: true }).click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((packet) => packet.command === 'Trust'));
      assert.equal(await p.getByRole('button', { name: 'BOT chơi hộ', exact: true }).getAttribute('aria-pressed'), 'false');
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.netState('trust')), 2);
      await p.getByRole('button', { name: 'Tự chơi lại', exact: true }).waitFor();
      assert.equal(await p.getByRole('button', { name: 'Tự chơi lại', exact: true }).getAttribute('aria-pressed'), 'true');
      assert.equal(await p.getByRole('button', { name: 'Sát', exact: true }).count(), 0);
      await p.getByRole('button', { name: 'Tự chơi lại', exact: true }).click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.filter((packet) => packet.command === 'Trust').length === 2);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.netState('online')), 1);
      await p.getByRole('button', { name: 'Sát', exact: true }).waitFor();
      const snap = await snapshot(p);
      const sent = await p.evaluate(() => window.__tqsRealLuaE2e.snapshot().sent);
      assert.ok(sent.filter((packet) => packet.command === 'Trust').every((packet) =>
        packet.type === CLIENT_NOTIFY && packet.requestId === -2 && packet.hex === '60'));
      assert.equal(snap.replies.length, 0);
      assert.deepEqual(snap.luaErrors, []);
    }],
    ['Real Lua PlayCard seeds React hand/targets and only card plus target plus OK replies', async (p) => {
      const { id, cardId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      assert.equal(await p.getByText('Đang lượt', { exact: true }).count(), 1);
      await p.getByText('Giai đoạn: Ngoài lượt', { exact: true }).waitFor();
      await p.getByText('1 lá trên tay', { exact: true }).waitFor();
      const card = p.locator(`button[data-card-id="${cardId}"]`);
      await card.waitFor();
      assert.equal(await card.isEnabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Xác nhận', exact: true }).isDisabled(), true);
      await card.click();
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.getByRole('article', { name: 'Bot fixture', exact: true })
        .getByRole('button', { name: 'Chọn mục tiêu', exact: true }).click();
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.replies.length, 1);
      assert.equal(s.replies[0].requestId, id);
      assert.equal(s.requestId, null);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { card: cardId, targets: [-1] });
      assert.deepEqual(s.luaErrors, []);
      assert.equal(s.error, null);
    }],
    ['Real Lua AskForResponseCard renders a legal Jink and replies once', async (p) => {
      const { id, cardId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginResponseCard());
      await p.getByText('Hãy đánh ra lá Thiểm', { exact: false }).waitFor();
      const card = p.locator(`button[data-card-id="${cardId}"]`);
      await card.waitFor();
      assert.equal(await card.isEnabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Xác nhận', exact: true }).isDisabled(), true);
      await card.click();
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.replies.length, 1);
      assert.equal(s.replies[0].requestId, id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { card: cardId, targets: [] });
      assert.equal(s.requestId, null);
      assert.deepEqual(s.luaErrors, []);
    }],
    ['Native Lua GameOver shows the winner, sends QuitRoom and clears result in lobby', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      await p.evaluate(() => window.__tqsRealLuaE2e.finishGame(true));
      await p.getByRole('heading', { name: 'Bạn đã thắng!', exact: true }).waitFor();
      await p.getByRole('heading', { name: 'Nhật ký cuối trận', exact: true }).waitFor();
      await p.getByText('Thông báo cuối trận thử nghiệm', { exact: true }).waitFor();
      assert.equal(await p.locator('[aria-labelledby="result-title"] .board-player').count(), 2);
      await p.getByText('Người thắng: browser-test', { exact: true }).waitFor();
      assert.equal((await snapshot(p)).requestId, null);
      await p.getByRole('button', { name: 'Về sảnh', exact: true }).click();
      const quit = await p.evaluate(() => window.__tqsRealLuaE2e.snapshot().sent.filter((packet) => packet.command === 'QuitRoom'));
      assert.equal(quit.length, 1);
      await p.evaluate(() => window.__tqsRealLuaE2e.enterLobby());
      assert.equal(await p.getByRole('heading', { name: 'Bạn đã thắng!', exact: true }).count(), 0);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Vietnamese display translates generals/cards/skills while preserving hidden generals and wire IDs', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay(true));
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.displayLabels()),
        ['Biện Phu Nhân', 'Điển Vi', 'Cường Tập', 'Vô Giải (Quốc Chiến)', 'Sát', 'Lôi Sát']);
      await p.getByText('Biện Phu Nhân', { exact: true }).waitFor();
      await p.getByText('Điển Vi', { exact: true }).waitFor();
      await p.getByRole('button', { name: 'Sát', exact: true }).waitFor();
      await p.getByRole('button', { name: 'Cường Tập', exact: true }).waitFor();
      await p.getByRole('button', { name: 'Vô Giải (Quốc Chiến)', exact: true }).waitFor();
      await p.getByText('Thế lực: Ngụy', { exact: true }).waitFor();
      await p.getByText('Chủ tướng ẩn', { exact: true }).waitFor();
      assert.equal(await p.getByText('ld__bianfuren', { exact: true }).count(), 0);
      if (process.env.TQS_EVIDENCE_DIR) await p.screenshot({
        path: path.join(process.env.TQS_EVIDENCE_DIR, 'vietnamese-board-lua-fixture-2026-10-11.png'), fullPage: true,
      });
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.beginChoices());
      await p.getByRole('heading', { name: 'Cường Tập', exact: true }).waitFor();
      await p.getByRole('button', { name: 'main', exact: true }).click();
      await p.getByRole('button', { name: 'Xác nhận lựa chọn', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.replies[0].requestId, id);
      assert.equal(s.replies[0].hex, '81446d61696e');
      assert.deepEqual(s.luaErrors, []);
    }],
    ['UI-01 upstream Lua translates Hegemony names, marks, variant rules, prompts and game logs', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const keys = [
        'vanguard_skill&', '#vanguard_skill&', '@!!vanguard',
        'liulongcanjia', 'mobile__liulongcanjia', ':liulongcanjia', ':mobile__liulongcanjia',
        'part_ways', '#part_ways-give', 'hs__shuangxiong', '#hs__shuangxiong',
        'burning_camps', '#burning_camps_skill', '#ChooseHegInitialKingdom',
        '#HegPrepareConvertLord', '#EnterBattleRoyalMode', '#EnterNewBattleRoyalMode',
        'turban_shell_cup', 'overbearing', 'analeptic', 'triblade',
        '#new_battle_royal_event&', '@[:]new_battle_royal_event',
        'battle_royal_fuli', 'battle_royal_shengzheweiwang', 'battle_royal_huoqi',
        'battle_royal_luoshi', 'battle_royal_bujinzetui', 'battle_royal_jili',
      ];
      const labels = await p.evaluate((lookups) => window.__tqsRealLuaE2e.localizedLabels(lookups), keys);
      assert.deepEqual(labels.slice(0, 3), ['Tiên phong',
        'Bạn có thể bỏ 1 dấu Tiên phong, rút bài trên tay đến đủ 4 lá, sau đó xem 1 tướng chưa lật của người chơi khác.',
        'Tiên phong']);
      assert.deepEqual(labels.slice(3, 5), ['Lục Long Tham Giá', 'Lục Long Tham Giá']);
      assert.match(labels[5], /\+1/);
      assert.match(labels[6], /−3/);
      assert.deepEqual(labels.slice(7, 9), ['Phân Đạo Dương Tiêu', 'Hãy giao cho %dest 3 lá bài.']);
      assert.equal(labels[9], 'Song Hùng');
      assert.match(labels[10], /%arg/);
      assert.equal(labels[11], 'Hỏa Thiêu Liên Doanh');
      for (let i = 12; i < labels.length; i++) {
        assert.match(labels[i], /[À-ỹ]/u, `Lua did not receive Vietnamese key ${keys[i]}`);
      }
      assert.deepEqual(labels.slice(17), ['Anh Vũ Bôi', 'Đốt Đốt Bức Nhân', 'Tửu',
        'Tam Tiêm Lưỡng Nhận Đao', 'Quyết chiến', 'Sự kiện vòng này',
        'Phú Lễ', 'Thắng Giả Vi Vương', 'Họa Khởi', 'Lạc Thạch', 'Bất Tiến Tắc Thoái', 'Kích Lệ']);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.localizedLabels(['#TargetCancelled'])),
        ['Mục tiêu %to đã bị hủy khỏi lá %arg do %from sử dụng.']);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.localizedLabels(['ofl_heg__jugu', 'ofl_heg__ziyuan'])),
        ['Cự Cổ', 'Tư Viện']);

      await p.evaluate(() => {
        window.__tqsRealLuaE2e.boardNotify('SetPlayerMark', "{17, '@!!vanguard', 2}");
        window.__tqsRealLuaE2e.boardNotify('SetPlayerMark', "{17, '@hs__shuangxiong-turn', 'red'}");
        window.__tqsRealLuaE2e.boardNotify('SetPlayerMark', "{-1, '__heg_general', 'caocao'}");
        window.__tqsRealLuaE2e.emitLocalizedLogs();
      });
      const own = p.getByRole('article', { name: 'browser-test (bạn)' });
      await own.getByText('Tiên phong: 2', { exact: true }).waitFor();
      await own.getByText('Song Hùng: Đỏ', { exact: true }).waitFor();
      const logs = p.getByRole('region', { name: 'Nhật ký trận đấu' });
      await logs.getByText('Song Hùng: bạn có thể dùng 1 lá trên tay màu Đỏ như Quyết Đấu.', { exact: true }).waitFor();
      await logs.getByText('Một Dã tâm gia đã chọn quốc hiệu Tần.', { exact: true }).waitFor();
      await logs.getByText('Trận đấu bước vào giai đoạn Quyết chiến.', { exact: true }).waitFor();
      await logs.getByText('Sự kiện vòng này: Họa Khởi. Trong vòng này, sát thương mọi nhân vật phải chịu tăng thêm 1.', { exact: true }).waitFor();
      await logs.getByText('Sự kiện vòng này: Lạc Thạch. Khi lật lá sự kiện này, tất cả nhân vật đã xác định thế lực lần lượt đổi phó tướng.', { exact: true }).waitFor();
      await logs.getByText('Quyết chiến', { exact: true }).waitFor();
      await logs.getByText('Mục tiêu Tướng ẩn/Mã Đại (bạn) đã bị hủy khỏi lá Hỏa Sát[♥4] do Vương Duyệt/Tướng ẩn sử dụng.', { exact: true }).waitFor();
      await logs.getByText('Mục tiêu Phùng Tập/Mã Đại (bạn) đã bị hủy khỏi lá Hỏa Sát[♦4] do Vương Duyệt/Lưu Phu Nhân sử dụng.', { exact: true }).waitFor();
      await logs.getByText('Tướng ẩn/Mi Trúc (bạn) đã phát động kỹ năng〖Cự Cổ〗', { exact: true }).waitFor();
      await logs.getByText('Nhật ký "<img src=x onerror=alert(1)> 中', { exact: true }).waitFor();
      assert.equal(await logs.locator('img, script, font, b').count(), 0);
      assert.equal(await p.locator('.board-center-symbol').innerText(), 'Quốc Chiến');
      assert.deepEqual((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[-1].marks, {});
      const snap = await snapshot(p);
      assert.equal(snap.replies.length, 0, 'translating logs or marks cannot emit gameplay replies');
      assert.deepEqual(snap.luaErrors, []);
    }],
  ];
  tests.push(
    ['Native rescue targets the dying opponent and synchronizes HP and hand after server updates', async (p) => {
      const { id, peachId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginRescue());
      const peach = p.locator(`button[data-card-id="${peachId}"]`);
      await peach.waitFor();
      assert.equal(await peach.isEnabled(), true);
      const bot = p.getByRole('article', { name: 'Bot fixture', exact: true });
      await bot.getByText('Hấp hối', { exact: true }).waitFor();
      await p.getByText('Bot fixture đang hấp hối, cần hồi 1 máu.', { exact: false }).waitFor();
      await peach.click();
      await p.getByText('Dùng Đào cứu Bot fixture.', { exact: false }).waitFor();
      if (process.env.TQS_EVIDENCE_DIR) await p.screenshot({
        path: path.join(process.env.TQS_EVIDENCE_DIR, 'peach-rescue-lua-fixture-2026-10-11.png'), fullPage: true,
      });
      const scene = await p.evaluate(() => window.__tqsRealLuaE2e.gameplay());
      assert.equal(scene.items.Photo['17'].enabled, false, 'Fixed target excludes healthy self');
      assert.equal(scene.items.Photo['-1'].enabled, false, 'Lua fixes the target without manual selection');
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.rescueTargets()), [-1]);
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.replies[0].requestId, id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { card: peachId, targets: [] });
      await p.evaluate((cardId) => window.__tqsRealLuaE2e.applyRescue(cardId, -1, 1), peachId);
      const board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[-1].hp, 1);
      assert.equal(board.player[17].handcardNum, 1);
      await bot.getByText('♥ 1 / 4', { exact: true }).waitFor();
      assert.equal(await bot.getByText('Hấp hối', { exact: true }).count(), 0);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Native battle royal disables ordinary Peach for another player but respects the ignore mark', async (p) => {
      for (const mode of ['new', 'old', 'ignore'] as const) {
        const { peachId } = await p.evaluate((value) => window.__tqsRealLuaE2e.beginRescue(value), mode);
        const peach = p.locator(`button[data-card-id="${peachId}"]`);
        await peach.waitFor();
        assert.equal(await peach.isDisabled(), mode !== 'ignore');
        const reason = (await p.evaluate(() => window.__tqsRealLuaE2e.gameplay())).items.CardItem[peachId].disabledReason;
        assert.equal(reason, mode === 'ignore' ? '' : `#web-peach-battle-${mode}`);
        if (mode !== 'ignore') await p.getByText(mode === 'new' ? 'Quyết chiến mới: Đào thường' : 'Quyết chiến cũ: Đào thường', { exact: false }).waitFor();
        else assert.equal(await p.getByText('Đào thường không thể', { exact: false }).count(), 0);
        if (mode === 'new' && process.env.TQS_EVIDENCE_DIR) await p.screenshot({
          path: path.join(process.env.TQS_EVIDENCE_DIR, 'battle-royal-peach-lua-fixture-2026-10-11.png'), fullPage: true,
        });
        assert.deepEqual((await snapshot(p)).luaErrors, []);
        assert.equal((await snapshot(p)).replies.length, 0);
      }
    }],
    ['Blocked native rescue can be declined once without consuming a card or changing HP', async (p) => {
      const { id } = await p.evaluate(() => window.__tqsRealLuaE2e.beginRescue('new'));
      assert.equal(await p.getByRole('button', { name: 'Xác nhận', exact: true }).isDisabled(), true);
      await p.getByRole('button', { name: 'Hủy', exact: true }).click();
      const s = await reply(p);
      assert.equal(s.replies.length, 1);
      assert.equal(s.replies[0].requestId, id);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), '__cancel');
      const board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[-1].hp, 0);
      assert.equal(board.player[17].handcardNum, 2);
      assert.deepEqual(s.luaErrors, []);
    }],
    ['Negative HP requires successive native rescue requests and only server recovery clears dying', async (p) => {
      const { peachId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginRescue('normal', -1));
      await p.getByText('cần hồi 2 máu.', { exact: false }).waitFor();
      await p.locator(`button[data-card-id="${peachId}"]`).click();
      assert.equal((await p.evaluate(() => window.__tqsRealLuaE2e.gameplay())).items.CardItem[peachId].disabledReason, '');
      assert.equal(await p.getByText('Đào thường không thể', { exact: false }).count(), 0);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      await reply(p);
      assert.equal((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[-1].hp, -1);
      await p.evaluate((id) => window.__tqsRealLuaE2e.applyRescue(id, -1, 0), peachId);
      await p.getByText('Hấp hối', { exact: true }).waitFor();
      const second = await p.evaluate(() => {
        const cardId = window.__tqsRealLuaE2e.drawPeach();
        const id = window.__tqsRealLuaE2e.requestRescue(-1, 0);
        return { id, cardId };
      });
      await p.locator(`button[data-card-id="${second.cardId}"]`).click();
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const s = await reply(p, 2);
      assert.equal(s.replies[1].requestId, second.id);
      await p.evaluate((id) => window.__tqsRealLuaE2e.applyRescue(id, -1, 1), second.cardId);
      assert.equal(await p.getByText('Hấp hối', { exact: true }).count(), 0);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['New battle royal converts Peach into Wine for self rescue through native view-as skill', async (p) => {
      const { id, peachId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginRescue('self'));
      await p.getByRole('button', { name: 'Quyết chiến', exact: true }).click();
      await p.locator(`button[data-card-id="${peachId}"]`).click();
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.rescueTargets()), [17]);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      assert.equal((await reply(p)).replies[0].requestId, id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()),
        { card: { skill: 'new_battle_royal&', subcards: [peachId] }, targets: [] });
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Companion virtual Peach remains usable to rescue another player in battle royal', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginRescue('companion'));
      await p.getByRole('button', { name: 'Châu Liên Bích Hợp', exact: true }).click();
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.rescueTargets()), [-1]);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()),
        { card: { skill: 'companion_skill&', subcards: [] }, targets: [] });
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Founding kingdom uses pinned options with Vietnamese labels and unchanged native reply', async (p) => {
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.beginWildChoice());
      await p.getByText('Dã tâm gia lập quốc: chọn quốc hiệu của bạn.', { exact: true }).waitFor();
      const labels = ['Tần', 'Tề', 'Sở', 'Yên', 'Triệu', 'Hàn', 'Tấn', 'Hán', 'Hạ', 'Thương', 'Chu', 'Lương'];
      for (const name of labels) await p.getByRole('button', { name, exact: true }).waitFor();
      assert.equal(await p.getByRole('button', { name: 'Hán', exact: true }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Bỏ qua lựa chọn', exact: true }).count(), 0);
      if (process.env.TQS_EVIDENCE_DIR) await p.screenshot({
        path: path.join(process.env.TQS_EVIDENCE_DIR, 'wild-kingdom-lua-fixture-2026-10-11.png'), fullPage: true,
      });
      await p.getByRole('button', { name: 'Tần', exact: true }).click();
      assert.equal((await reply(p)).replies[0].requestId, id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['heg_qin']);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Founding kingdom display follows native HegUtil only for Self or a revealed opponent', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const notify = (source: string) => p.evaluate((value) =>
        window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', value), source);
      await notify("{17, 'kingdom', 'wild'}");
      await notify("{17, 'role', 'heg_qin'}");
      const self = p.getByRole('article', { name: 'browser-test (bạn)', exact: true });
      await self.getByText('Thế lực: Tần', { exact: true }).waitFor();
      const bot = p.getByRole('article', { name: 'Bot fixture', exact: true });
      await notify("{-1, 'kingdom', 'wild'}");
      await notify("{-1, 'role', 'heg_chu'}");
      await bot.getByText('Thế lực: Chưa công khai', { exact: true }).waitFor();
      assert.equal((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[-1].visibleKingdom, null);
      await notify("{-1, 'role_shown', true}");
      await bot.getByText('Thế lực: Sở', { exact: true }).waitFor();
      await notify("{-1, 'role_shown', false}");
      await bot.getByText('Thế lực: Chưa công khai', { exact: true }).waitFor();
      assert.equal((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).player[-1].visibleKingdom, null);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Self hidden pair and board states follow Lua without exposing opponent marks', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const notify = (command: string, source: string) => p.evaluate(({ command, source }) =>
        window.__tqsRealLuaE2e.boardNotify(command, source), { command, source });
      for (const source of ["{17, '__heg_general', 'ld__bianfuren'}", "{17, '__heg_deputy', 'm_heg__dianwei'}",
        "{-1, '__heg_general', 'caocao'}", "{-1, '__heg_deputy', 'liubei'}"]) await notify('SetPlayerMark', source);
      for (const source of ["{17, 'general', 'anjiang'}", "{17, 'deputyGeneral', 'anjiang'}",
        "{-1, 'deputyGeneral', 'anjiang'}"]) await notify('PropertyUpdate', source);
      const self = p.getByRole('article', { name: 'browser-test (bạn)', exact: true });
      const bot = p.getByRole('article', { name: 'Bot fixture', exact: true });
      await self.getByText('Biện Phu Nhân · Chưa lật', { exact: true }).waitFor();
      await self.getByText('Điển Vi · Chưa lật', { exact: true }).waitFor();
      await bot.getByText('Chủ tướng ẩn', { exact: true }).waitFor();
      await bot.getByText('Phó tướng ẩn', { exact: true }).waitFor();
      let board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[-1].selfGeneral, null);
      assert.equal(board.player[-1].selfDeputyGeneral, null);
      assert.deepEqual(board.player[-1].marks, {});
      assert.ok(!JSON.stringify(board).includes('caocao') && !JSON.stringify(board).includes('liubei'));
      await notify('PropertyUpdate', "{-1, 'general', 'ld__bianfuren'}");
      await bot.getByText('Biện Phu Nhân', { exact: true }).waitFor();
      await bot.getByText('Phó tướng ẩn', { exact: true }).waitFor();
      for (const source of ["{17, 'chained', true}", "{17, 'faceup', false}", "{17, 'hp', -1}"])
        await notify('PropertyUpdate', source);
      await self.getByText('Đang bị xích', { exact: true }).waitFor();
      await self.getByText('Úp mặt', { exact: true }).waitFor();
      await self.getByText('Hấp hối', { exact: true }).waitFor();
      await self.getByText('♥ -1 / 4', { exact: true }).waitFor();
      if (process.env.TQS_EVIDENCE_DIR) await p.screenshot({ path: path.join(process.env.TQS_EVIDENCE_DIR,
        'board-self-state-lua-fixture-2026-10-11.png'), fullPage: true });
      for (const source of ["{17, 'general', 'ld__bianfuren'}", "{17, 'chained', false}",
        "{17, 'faceup', true}", "{17, 'hp', 1}"]) await notify('PropertyUpdate', source);
      await self.getByText('Biện Phu Nhân', { exact: true }).waitFor();
      for (const label of ['Biện Phu Nhân · Chưa lật', 'Hấp hối', 'Đang bị xích', 'Úp mặt'])
        assert.equal(await self.getByText(label, { exact: true }).count(), 0);
      board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[17].hp, 1);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['Public equipment follows MoveCards and removal without hand IDs', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const equipId = await p.evaluate(() => window.__tqsRealLuaE2e.equipBot());
      const bot = p.getByRole('article', { name: 'Bot fixture', exact: true });
      await bot.getByLabel('Trang bị công khai').waitFor();
      let board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.equal(board.player[-1].equipment.length, 1);
      assert.ok(board.player[-1].equipment.every((c) => !('id' in c)));
      await p.evaluate((id) => window.__tqsRealLuaE2e.boardNotify('MoveCards',
        `{{{from=-1, toArea=Card.DiscardPile, moveReason=fk.ReasonDiscard, moveInfo={{cardId=${id}, fromArea=Card.PlayerEquip}}, moveVisible=true}}, 1}`), equipId);
      board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.deepEqual(board.player[-1].equipment, []);
      assert.equal(await bot.getByLabel('Trang bị công khai').count(), 0);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['native card-chosen hides opponent hand and sends one integer reply', async (p) => {
      const { id, handId, equipId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection());
      const panel = p.getByRole('region', { name: 'Chọn bài đối thủ' });
      await panel.waitFor();
      const prompt = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt());
      assert.ok(prompt);
      const hidden = prompt.groups.flatMap((g) => g.cards).filter((c) => c.hidden);
      assert.equal(hidden.length, 1);
      assert.deepEqual(Object.keys(hidden[0]).sort(), ['hidden', 'token']);
      assert.ok(!JSON.stringify(prompt).includes(`"id":${handId}`));
      assert.equal(await panel.getByRole('button', { name: 'Bài úp', exact: true }).count(), 1);
      assert.ok(!(await panel.innerText()).includes('Đào'));
      await panel.screenshot({ path: path.join(root, '../../scratch/evidence/card-selection-lua-fixture-2026-10-11.png') });
      await panel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      const snap = await reply(p);
      assert.equal(snap.replies[0].requestId, id);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), handId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.applyChosenMove()),
        { selfHand: 2, otherHand: 0, otherEquip: 1 });
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardAttempt(id, [token]), { id, token: hidden[0].token }));
      assert.equal((await snapshot(p)).replies.length, 1);
      const next = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection());
      const publicCard = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt()!.groups.flatMap((g) => g.cards).find((c) => !c.hidden)!);
      assert.ok(publicCard.name);
      assert.equal(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardAttempt(id, [token]), { id: next.id, token: publicCard.token }), null);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), equipId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.applyChosenMove(true)),
        { selfHand: 1, otherHand: 1, otherEquip: 0 });
    }],
    ['native multi-card Poxi obeys Lua limits, pattern and cancellation', async (p) => {
      const { id, handId, equipId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection(true));
      const panel = p.getByRole('region', { name: 'Chọn bài đối thủ' });
      const ok = panel.getByRole('button', { name: 'Xác nhận chọn bài', exact: true });
      assert.equal(await ok.isDisabled(), true);
      const tokens = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt()!.groups.flatMap((g) => g.cards).map((c) => c.token));
      assert.ok(await p.evaluate(({ id, tokens }) => window.__tqsRealLuaE2e.cardAttempt(id, [tokens[0], tokens[0]]), { id, tokens }));
      await panel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      assert.equal(await ok.isEnabled(), true);
      const equip = panel.getByRole('group').nth(1).getByRole('button');
      await equip.click();
      await ok.click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), [handId, equipId]);
      const limited = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection(true, false, false, 1));
      const limitedTokens = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt()!.groups.flatMap((g) => g.cards).map((c) => c.token));
      assert.ok(await p.evaluate(({ id, tokens }) => window.__tqsRealLuaE2e.cardAttempt(id, tokens), { id: limited.id, tokens: limitedTokens }));
      assert.equal((await snapshot(p)).replies.length, 0);
      await panel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      assert.equal(await panel.getByRole('group').nth(1).getByRole('button').isDisabled(), true);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection(true, false, true));
      assert.equal(await panel.getByRole('button', { name: 'Bài úp', exact: true }).isDisabled(), true);
      await panel.getByRole('button', { name: 'Bỏ qua chọn bài' }).click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), []);
    }],
    ['card tokens reject replacement, expiry and disconnect', async (p) => {
      const first = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection());
      const token = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt()!.groups[0].cards[0].token);
      const next = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection());
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardAttempt(id, [token]), { id: first.id, token }));
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardAttempt(id, [token]), { id: next.id, token }));
      const expired = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardSelection(false, true));
      const expiredToken = await p.evaluate(() => window.__tqsRealLuaE2e.cardPrompt()!.groups[0].cards[0].token);
      const hidden = p.getByRole('region', { name: 'Chọn bài đối thủ' }).getByRole('button', { name: 'Bài úp', exact: true });
      assert.equal(await hidden.isDisabled(), true);
      assert.match((await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardAttempt(id, [token]), { id: expired.id, token: expiredToken }))!, /hết thời gian/);
      assert.equal((await snapshot(p)).replies.length, 0);
      await p.evaluate(() => window.__tqsRealLuaE2e.disconnect());
      assert.equal(await p.getByRole('region', { name: 'Chọn bài đối thủ' }).count(), 0);
    }],
  );
  tests.push(
    ['CardsAndChoice view-only reveals authorized faces and confirms with empty cards', async (p) => {
      const { id } = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice());
      const panel = p.getByRole('region', { name: 'Xem bài và chọn phương án' });
      await panel.waitFor();
      await panel.getByRole('heading', { name: 'Xem các lá bài', exact: true }).waitFor();
      assert.equal(await panel.getByRole('group').getByRole('button').count(), 0);
      assert.ok((await panel.innerText()).includes('Sát'));
      assert.ok((await panel.innerText()).includes('Đào'));
      const prompt = await p.evaluate(() => window.__tqsRealLuaE2e.cardsAndChoicePrompt());
      assert.ok(prompt);
      assert.ok(prompt.cards.every((card) => !('id' in card)));
      assert.equal((await snapshot(p)).replies.length, 0, 'opening a view must not auto-reply');
      await panel.screenshot({ path: path.join(root, '../../scratch/evidence/cards-and-choice-view-lua-fixture-2026-10-11.png') });
      await panel.getByRole('button').click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { cards: [], choice: 'OK' });
      assert.ok(await p.evaluate((id) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [], 'OK'), id));
      assert.equal((await snapshot(p)).replies.length, 1);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('empty'));
      await panel.getByText('Không có lá bài để xem.').waitFor();
      await panel.getByRole('button').click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { cards: [], choice: 'OK' });
    }],
    ['CardsAndChoice validates count, disabled cards and actual Lua choiceFilter', async (p) => {
      const { id, cardId } = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('select'));
      const panel = p.getByRole('region', { name: 'Xem bài và chọn phương án' });
      const cards = panel.getByRole('group').getByRole('button');
      const use = panel.getByRole('button', { name: 'Dùng Sát', exact: true });
      const first = panel.getByRole('button', { name: 'Giữ bài', exact: true });
      assert.equal(await first.isDisabled(), true);
      assert.equal(await use.isDisabled(), true);
      assert.equal(await cards.nth(2).isDisabled(), true);
      const tokens = await p.evaluate(() => window.__tqsRealLuaE2e.cardsAndChoicePrompt()!.cards.map((c) => c.token));
      for (const args of [{ tokens: [], choice: 'default' }, { tokens: [tokens[2]], choice: 'default' },
        { tokens: [tokens[0], tokens[1]], choice: 'default' }, { tokens: [tokens[0], tokens[0]], choice: 'default' },
        { tokens: [tokens[1]], choice: 'use' }, { tokens: [tokens[0]], choice: 'forged' }]) {
        assert.ok(await p.evaluate(({ id, tokens, choice }) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, tokens, choice), { id, ...args }));
      }
      assert.equal((await snapshot(p)).replies.length, 0);
      await cards.nth(1).click();
      assert.equal(await first.isEnabled(), true, 'first option bypasses filter after count is valid');
      assert.equal(await use.isDisabled(), true, 'non-slash fails installed Lua filter');
      await cards.nth(1).click();
      await cards.nth(0).click();
      assert.equal(await use.isEnabled(), true);
      assert.equal(await cards.nth(1).isDisabled(), true, 'cannot exceed max');
      await use.click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { cards: [cardId], choice: 'use' });
      await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('missing-filter'));
      await cards.nth(1).click();
      assert.equal(await use.isDisabled(), true);
      assert.equal(await first.isEnabled(), true);
      await first.click();
      await reply(p);
    }],
    ['CardsAndChoice cancel option ignores selection and permits cancel-only dialogs', async (p) => {
      const { id } = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('select'));
      const panel = p.getByRole('region', { name: 'Xem bài và chọn phương án' });
      const token = await p.evaluate(() => window.__tqsRealLuaE2e.cardsAndChoicePrompt()!.cards[0].token);
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [token], 'cancel', true), { id, token }));
      assert.ok(await p.evaluate((id) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [], 'default', true), id));
      await panel.getByRole('group').getByRole('button').nth(0).click();
      await panel.getByRole('button', { name: 'Bỏ qua', exact: true }).click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { cards: [], choice: 'cancel' });
      await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('cancel-only'));
      assert.equal(await panel.getByRole('button', { name: 'Giữ bài', exact: true }).count(), 0);
      await panel.getByRole('button', { name: 'Bỏ qua', exact: true }).click();
      await reply(p);
    }],
    ['CardsAndChoice replacement, expiry, disconnect and unsolicited replies stay blocked', async (p) => {
      const first = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('select'));
      const token = await p.evaluate(() => window.__tqsRealLuaE2e.cardsAndChoicePrompt()!.cards[0].token);
      const next = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('select'));
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [token], 'default'), { id: first.id, token }));
      assert.ok(await p.evaluate(({ id, token }) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [token], 'default'), { id: next.id, token }));
      await p.evaluate(() => window.__tqsRealLuaE2e.unsolicited('1'));
      assert.equal((await snapshot(p)).replies.length, 0);
      const expired = await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice('view', true));
      assert.equal(await p.getByRole('region', { name: 'Xem bài và chọn phương án' }).getByRole('button').isDisabled(), true);
      assert.match((await p.evaluate((id) => window.__tqsRealLuaE2e.cardsAndChoiceAttempt(id, [], 'OK'), expired.id))!, /hết thời gian/);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginCardsAndChoice());
      await p.evaluate(() => window.__tqsRealLuaE2e.disconnect());
      assert.equal(await p.getByRole('region', { name: 'Xem bài và chọn phương án' }).count(), 0);
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
    ['UI-02 Lua packages toggle in Chrome mobile and reach CreateRoom / EnterRoom', async (p) => {
      const { general, card, baseline } = await p.evaluate(() => window.__tqsRealLuaE2e.beginRoomPacks());
      await p.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
      const packageInputs = p.locator('input[data-pack-id]');
      assert.ok(await packageInputs.count() >= 2);
      const generals = p.locator(`input[data-pack-id="${general}"]`);
      const cards = p.locator(`input[data-pack-id="${card}"]`);
      assert.equal(await generals.isChecked(), true);
      assert.equal(await cards.isChecked(), true);
      assert.match(await p.locator('.pool-summary').innerText(), new RegExp(`${baseline.generals} tướng`));
      await generals.uncheck();
      await cards.uncheck();
      assert.equal(await generals.isChecked(), false);
      assert.equal(await cards.isChecked(), false);
      const reduced = await p.evaluate(([g, c]) => window.__tqsRealLuaE2e.roomPool([g, c]), [general, card]);
      assert.ok(reduced.generals < baseline.generals && reduced.cards < baseline.cards);
      assert.match(await p.locator('.pool-summary').innerText(), new RegExp(`${reduced.generals} tướng.*${reduced.cards} lá`));
      assert.equal(await p.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).isEnabled(), true);
      const evidenceDir = path.resolve(root, '../../scratch/evidence');
      mkdirSync(evidenceDir, { recursive: true });
      await p.screenshot({ path: path.join(evidenceDir, 'ui-02-mobile-lobby-lua-fixture-2026-10-11.png'), fullPage: true });
      await p.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((item) => item.command === 'CreateRoom'));
      const created = await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeCreatedRoom());
      assert.equal(created.mode, 'new_heg_mode');
      assert.deepEqual(created.disabledPack, [general, card]);
      await p.locator('.waiting-pools > summary').click();
      assert.match(await p.locator('.waiting-pools').innerText(), /máy chủ xác nhận/);
      const waiting = await p.locator('.waiting-pools').innerText();
      assert.ok(!waiting.includes(general) && !waiting.includes(card), 'disabled packs cannot appear as enabled');
      await p.screenshot({ path: path.join(evidenceDir, 'ui-02-mobile-waiting-lua-fixture-2026-10-11.png'), fullPage: true });
      for (const width of [390, 320]) {
        await p.setViewportSize({ width, height: 844 });
        const metrics = await p.evaluate(() => ({ scroll: document.documentElement.scrollWidth, viewport: window.innerWidth }));
        assert.ok(metrics.scroll <= metrics.viewport, `mobile viewport ${width}px overflows: ${JSON.stringify(metrics)}`);
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['QA caller pool uses native disabledGenerals without exposing internal IDs', async (p) => {
      await p.evaluate(() => history.replaceState(null, '', '/?tqs-qa-general=hs__pangde&tqs-qa-pack=hegemony_standard'));
      await p.evaluate(() => window.__tqsRealLuaE2e.beginRoomPacks());
      await p.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
      await p.getByLabel('Số người', { exact: true }).selectOption('2');
      assert.match(await p.locator('.pool-summary').innerText(), /10 tướng khác tên/);
      await p.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((item) => item.command === 'CreateRoom'));
      const created = await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeCreatedRoom());
      assert.equal(created.disabledGenerals.includes('hs__pangde'), false);
      assert.ok(created.disabledGenerals.length > 0);
      await p.evaluate(() => history.replaceState(null, '', '/'));
    }],
    ['QA founding pool keeps the unmapped wild caller and a compatible native pair', async (p) => {
      await p.evaluate(() => history.replaceState(null, '', '/?tqs-qa-general=heg__jiananfeng&tqs-qa-pack=zfxp&tqs-qa-kingdom=same'));
      await p.evaluate(() => window.__tqsRealLuaE2e.beginRoomPacks());
      await p.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
      await p.getByLabel('Số người', { exact: true }).selectOption('2');
      assert.equal(await p.locator('.pool-warning').count(), 0);
      assert.match(await p.locator('.pool-summary').innerText(), /10 tướng khác tên/);
      assert.doesNotMatch(await p.locator('body').innerText(), /heg__jiananfeng/);
      await p.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().sent.some((item) => item.command === 'CreateRoom'));
      const created = await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeCreatedRoom());
      assert.equal(created.disabledGenerals.includes('heg__jiananfeng'), false);
      await p.evaluate(() => history.replaceState(null, '', '/'));
    }],
    ['UI-02 disables room creation when all native GeneralPacks are off', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginRoomPacks());
      const all = p.locator('input[data-pack-type="generals"]');
      const count = await all.count();
      assert.ok(count > 0);
      for (let index = 0; index < count; index++) await all.nth(index).uncheck();
      assert.match(await p.locator('.pool-summary').innerText(), /0 tướng khác tên/);
      assert.equal(await p.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).isDisabled(), true);
      assert.equal((await snapshot(p)).sent.some((item) => item.command === 'CreateRoom'), false);
    }],
    ['UI-03 Lua public logs, HP and chain changes appear in the board and reset safely', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const logs = p.getByRole('region', { name: 'Nhật ký trận đấu' });
      assert.equal(await logs.getByRole('button', { name: 'Thu gọn' }).getAttribute('aria-expanded'), 'true');
      await logs.getByRole('list', { name: 'Các diễn biến trận đấu' }).waitFor();
      await p.evaluate(() => {
        window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', "{-1, 'hp', 2}");
        window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', "{-1, 'chained', false}");
        window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', "{-1, 'chained', true}");
        window.__tqsRealLuaE2e.boardNotify('GameLog', "{type='Sử dụng %arg', arg='slash'}");
      });
      const moments = p.locator('.board-moments');
      await moments.getByText('Bot fixture mất 2 HP (4 → 2)', { exact: true }).waitFor();
      await moments.getByText('Bot fixture bị xích', { exact: true }).waitFor();
      // Moments are intentionally presented at a readable interval; wait for
      // the queued log item instead of assuming the two earlier items imply
      // that the third one has already reached the DOM.
      await p.waitForFunction(() => document.querySelector('.board-moments')?.textContent?.includes('Sử dụng'));
      assert.match(await moments.innerText(), /Sử dụng/);
      assert.match(await logs.innerText(), /Sử dụng/);
      assert.equal((await moments.locator('.board-moment').count()), 3);
      assert.equal(await moments.locator('font, b, script').count(), 0, 'server HTML is rendered only as text');
      const board = await p.evaluate(() => window.__tqsRealLuaE2e.boardState());
      assert.deepEqual(board.moments.slice(-3).map((event) => event.kind), ['hp', 'chain', 'log']);
      assert.equal((await snapshot(p)).replies.length, 0);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
      await p.evaluate(() => window.__tqsRealLuaE2e.finishGame());
      assert.deepEqual((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).moments, []);
      await p.evaluate(() => window.__tqsRealLuaE2e.enterLobby());
      assert.deepEqual((await p.evaluate(() => window.__tqsRealLuaE2e.boardState())).logs, []);
    }],
    ['UI-03 responsive log layout and scroll following work with actual Lua notifications', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      const logList = p.getByRole('list', { name: 'Các diễn biến trận đấu' });
      const addLogs = async (from: number, to: number) => p.evaluate(([start, end]) => {
        for (let i = start; i < end; i++) {
          window.__tqsRealLuaE2e.boardNotify('GameLog', `{type='Diễn biến ${i}: lá Sát nhắm vào Bot fixture'}`);
        }
      }, [from, to]);
      await addLogs(0, 45);
      const nearBottom = () => p.evaluate(() => {
        const el = document.querySelector('.board-logs')!;
        return el.scrollHeight - el.scrollTop - el.clientHeight < 3;
      });
      await p.waitForFunction(() => {
        const el = document.querySelector('.board-logs')!;
        return el.scrollHeight > el.clientHeight && el.scrollHeight - el.scrollTop - el.clientHeight < 3;
      });
      assert.equal(await nearBottom(), true, 'new logs should be followed by default');
      await logList.hover();
      await p.mouse.wheel(0, -2400);
      await p.getByRole('button', { name: 'Theo dõi dòng mới' }).waitFor();
      const savedScroll = await logList.evaluate((el) => el.scrollTop);
      await addLogs(45, 49);
      assert.equal(await logList.evaluate((el) => el.scrollTop), savedScroll, 'reading history must not jump to newest');
      assert.equal(await p.getByRole('button', { name: 'Theo dõi dòng mới' }).count(), 1);
      await p.getByRole('button', { name: 'Theo dõi dòng mới' }).click();
      await p.waitForFunction(() => {
        const el = document.querySelector('.board-logs')!;
        return el.scrollHeight - el.scrollTop - el.clientHeight < 3;
      });
      assert.equal(await p.getByRole('button', { name: 'Theo dõi dòng mới' }).count(), 0);
      const evidenceDir = path.resolve(root, '../../scratch/evidence');
      mkdirSync(evidenceDir, { recursive: true });
      for (const width of [360, 390, 1280]) {
        await p.setViewportSize({ width, height: 844 });
        await p.waitForFunction(() => {
          const el = document.querySelector('.board-logs')!;
          return el.scrollHeight - el.scrollTop - el.clientHeight < 3;
        });
        const metrics = await p.evaluate(() => {
          const log = document.querySelector('.board-log-panel')!.getBoundingClientRect();
          const main = document.querySelector('.board-main')!.getBoundingClientRect();
          return { scroll: document.documentElement.scrollWidth, width: window.innerWidth,
            logLeft: log.left, logRight: log.right, mainLeft: main.left, mainRight: main.right, mainTop: main.top, logTop: log.top };
        });
        assert.ok(metrics.scroll <= metrics.width, `UI-03 viewport ${width}px overflows: ${JSON.stringify(metrics)}`);
        assert.equal(await p.getByRole('button', { name: 'Theo dõi dòng mới' }).count(), 0,
          `viewport ${width}px must not disable automatic following`);
        assert.equal(await nearBottom(), true, `viewport ${width}px must keep latest log visible`);
        if (width >= 940) {
          assert.ok(metrics.mainRight <= metrics.logLeft, `desktop log must sit on the right: ${JSON.stringify(metrics)}`);
          assert.ok(Math.abs(metrics.logTop - metrics.mainTop) <= 2, 'desktop log and board must share the top row');
        } else {
          assert.ok(metrics.logTop < metrics.mainTop, `mobile log must appear above board: ${JSON.stringify(metrics)}`);
        }
        await p.screenshot({ path: path.join(evidenceDir, `ui-03-${width}px-target-overlay-lua-fixture-2026-10-14.png`), fullPage: true });
      }
      await p.setViewportSize({ width: 390, height: 844 });
      await logList.focus();
      await p.keyboard.press('Home');
      await p.getByRole('button', { name: 'Theo dõi dòng mới' }).waitFor();
      await p.waitForFunction(() => document.querySelector('.board-logs')!.scrollTop < 1);
      assert.equal(await logList.evaluate((el) => el.scrollTop), 0, 'Home shows oldest log entries');
      await p.setViewportSize({ width: 320, height: 844 });
      await addLogs(49, 52);
      assert.equal(await logList.evaluate((el) => el.scrollTop), 0, 'resize and new logs preserve history position');
      assert.equal(await p.getByRole('button', { name: 'Theo dõi dòng mới' }).count(), 1);
      await p.keyboard.press('End');
      await p.waitForFunction(() => {
        const el = document.querySelector('.board-logs')!;
        return el.scrollHeight - el.scrollTop - el.clientHeight < 3;
      });
      assert.equal(await p.getByRole('button', { name: 'Theo dõi dòng mới' }).count(), 0,
        'End resumes automatic following');
      await addLogs(52, 54);
      assert.equal(await nearBottom(), true, 'follow remains active after keyboard navigation');
      await p.waitForFunction(() =>
        document.querySelector('.board-moments')?.textContent?.includes('lá Sát nhắm vào Bot fixture') ?? false,
        undefined,
        { timeout: 3000 });
      assert.match(await p.locator('.board-moments').innerText(), /lá Sát nhắm vào Bot fixture/,
        'recent public card and target details appear in the center');
      await p.setViewportSize({ width: 390, height: 844 });
      await p.getByRole('button', { name: 'Thu gọn' }).click();
      assert.equal(await logList.count(), 0);
      await p.getByRole('button', { name: 'Xem nhật ký' }).click();
      await logList.waitFor();
      assert.equal(await nearBottom(), true, 'reopening logs resumes at latest when following');
      assert.deepEqual((await snapshot(p)).luaErrors, []);
      assert.equal((await snapshot(p)).replies.length, 0, 'UI-03 rendering must never reply to gameplay requests');
    }],
    ['UI-03 photo panels keep target actions clear of the table centre and recent-action surfaces', async (p) => {
      const intersects = (a: { left: number; right: number; top: number; bottom: number },
        b: { left: number; right: number; top: number; bottom: number }) =>
        a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
      await p.setViewportSize({ width: 1280, height: 900 });
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      await p.evaluate(() => {
        for (let id = 18; id <= 24; id++) {
          window.__tqsRealLuaE2e.boardNotify('AddPlayer', `{${id}, 'Bot ${id}', 'avatar', true, 0}`);
        }
        window.__tqsRealLuaE2e.boardNotify('ArrangeSeats', '{17, -1, 18, 19, 20, 21, 22, 23, 24}');
      });
      await p.evaluate(() => {
        window.__tqsRealLuaE2e.boardNotify('GameLog', "{type='Hành động gần nhất: Bot fixture bị nhắm mục tiêu'}");
        window.__tqsRealLuaE2e.boardNotify('GameLog', "{type='Bảng diễn biến mới nhất vẫn còn hiển thị'}");
      });
      await p.locator('.sg-gameplay-controls button[data-card-id]:enabled').first().click();
      const target = p.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
      await target.waitFor({ state: 'attached' });
      await target.scrollIntoViewIfNeeded();
      const desktop = await p.evaluate(() => {
        const target = document.querySelector<HTMLButtonElement>('.board-player:not(.board-self) .gameplay-target:enabled');
        const center = document.querySelector<HTMLElement>('.board-center');
        const local = document.querySelector<HTMLElement>('.board-local-seat');
        const controls = document.querySelector<HTMLElement>('.sg-gameplay-controls');
        if (!target || !center || !local || !controls) throw new Error('board interaction surfaces missing');
        const targetBox = target.getBoundingClientRect();
        const portrait = target.closest<HTMLElement>('.sg-portrait-frame');
        const centerBox = center.getBoundingClientRect();
        const localBox = local.getBoundingClientRect();
        const controlsBox = controls.getBoundingClientRect();
        if (!portrait) throw new Error('target portrait frame missing');
        const portraitBox = portrait.getBoundingClientRect();
        const targetRect = { left: targetBox.left, right: targetBox.right, top: targetBox.top, bottom: targetBox.bottom,
          width: targetBox.width, height: targetBox.height };
        const portraitRect = { left: portraitBox.left, right: portraitBox.right, top: portraitBox.top, bottom: portraitBox.bottom,
          width: portraitBox.width, height: portraitBox.height };
        const point = document.elementFromPoint(targetRect.left + targetRect.width / 2,
          targetRect.top + targetRect.height / 2);
        const panels = [...document.querySelectorAll<HTMLElement>('.board-opponents .sg-photo-panel')].map((panel) => {
          const box = panel.getBoundingClientRect();
          return { left: box.left, right: box.right, top: box.top, bottom: box.bottom,
            width: box.width, height: box.height };
        });
        return { target: targetRect,
          center: { left: centerBox.left, right: centerBox.right, top: centerBox.top, bottom: centerBox.bottom,
            width: centerBox.width, height: centerBox.height },
          local: { left: localBox.left, right: localBox.right, top: localBox.top, bottom: localBox.bottom,
            width: localBox.width, height: localBox.height },
          controls: { left: controlsBox.left, right: controlsBox.right, top: controlsBox.top, bottom: controlsBox.bottom,
            width: controlsBox.width, height: controlsBox.height }, panels,
          targetClass: target.className,
          targetId: target.getAttribute('data-target-id'),
          targetInsidePortrait: targetRect.left >= portraitRect.left && targetRect.right <= portraitRect.right &&
            targetRect.top >= portraitRect.top && targetRect.bottom <= portraitRect.bottom,
          centerPointerEvents: getComputedStyle(center).pointerEvents,
          hitTarget: point?.closest('.gameplay-target') === target,
          viewport: { width: window.innerWidth, height: window.innerHeight } };
      });
      assert.equal(desktop.centerPointerEvents, 'none');
      assert.equal(desktop.hitTarget, true, `desktop target is not the hit-test surface: ${JSON.stringify(desktop)}`);
      assert.match(desktop.targetClass, /sg-portrait-target-overlay/);
      assert.equal(desktop.targetInsidePortrait, true, `desktop target must cover only the portrait: ${JSON.stringify(desktop)}`);
      assert.ok(desktop.targetId, 'desktop target must expose the public player id');
      assert.equal(intersects(desktop.target, desktop.center), false,
        `desktop centre content overlaps target: ${JSON.stringify(desktop)}`);
      assert.equal(intersects(desktop.target, desktop.local), false,
        `desktop local dashboard overlaps opponent target: ${JSON.stringify(desktop)}`);
      assert.equal(intersects(desktop.local, desktop.controls), false,
        `desktop action panel overlaps local photo: ${JSON.stringify(desktop)}`);
      for (let first = 0; first < desktop.panels.length; first++) {
        for (let second = first + 1; second < desktop.panels.length; second++) {
          assert.equal(intersects(desktop.panels[first], desktop.panels[second]), false,
            `desktop seat panels overlap at 8-player layout: ${JSON.stringify(desktop.panels)}`);
        }
      }
      await target.click();
      assert.equal(await target.getAttribute('aria-pressed'), 'true');

      await p.setViewportSize({ width: 390, height: 844 });
      await p.evaluate(() => window.__tqsRealLuaE2e.beginPlay());
      await p.locator('.sg-gameplay-controls button[data-card-id]:enabled').first().click();
      const mobileTarget = p.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
      await mobileTarget.waitFor({ state: 'attached' });
      await mobileTarget.scrollIntoViewIfNeeded();
      const mobile = await p.evaluate(() => {
        const target = document.querySelector<HTMLElement>('.board-player:not(.board-self) .gameplay-target:enabled');
        const center = document.querySelector<HTMLElement>('.board-center');
        const controls = document.querySelector<HTMLElement>('.sg-gameplay-controls');
        const portrait = target?.closest<HTMLElement>('.sg-portrait-frame');
        if (!target || !portrait || !center || !controls) throw new Error('mobile interaction surfaces missing');
        const targetBox = target.getBoundingClientRect();
        const portraitBox = portrait.getBoundingClientRect();
        const centerBox = center.getBoundingClientRect();
        const controlsBox = controls.getBoundingClientRect();
        const targetRect = { left: targetBox.left, right: targetBox.right, top: targetBox.top, bottom: targetBox.bottom,
          width: targetBox.width, height: targetBox.height };
        const portraitRect = { left: portraitBox.left, right: portraitBox.right, top: portraitBox.top, bottom: portraitBox.bottom,
          width: portraitBox.width, height: portraitBox.height };
        const point = document.elementFromPoint(targetRect.left + targetRect.width / 2,
          targetRect.top + targetRect.height / 2);
        return { target: targetRect,
          center: { left: centerBox.left, right: centerBox.right, top: centerBox.top, bottom: centerBox.bottom,
            width: centerBox.width, height: centerBox.height },
          controls: { left: controlsBox.left, right: controlsBox.right, top: controlsBox.top, bottom: controlsBox.bottom,
            width: controlsBox.width, height: controlsBox.height },
          targetClass: target.className,
          targetId: target.getAttribute('data-target-id'),
          targetInsidePortrait: targetRect.left >= portraitRect.left && targetRect.right <= portraitRect.right &&
            targetRect.top >= portraitRect.top && targetRect.bottom <= portraitRect.bottom,
          centerPointerEvents: getComputedStyle(center).pointerEvents,
          controlsPosition: getComputedStyle(controls).position,
          hitTarget: point?.closest('.gameplay-target') === target,
          viewport: { width: window.innerWidth, height: window.innerHeight },
          documentWidth: document.documentElement.scrollWidth };
      });
      assert.equal(mobile.centerPointerEvents, 'none');
      assert.equal(mobile.controlsPosition, 'relative', 'mobile actions must not cover a lower seat');
      assert.equal(mobile.hitTarget, true, `mobile target is not the hit-test surface: ${JSON.stringify(mobile)}`);
      assert.match(mobile.targetClass, /sg-portrait-target-overlay/);
      assert.equal(mobile.targetInsidePortrait, true, `mobile target must cover only the portrait: ${JSON.stringify(mobile)}`);
      assert.ok(mobile.targetId, 'mobile target must expose the public player id');
      assert.equal(intersects(mobile.target, mobile.center), false,
        `mobile centre content overlaps target: ${JSON.stringify(mobile)}`);
      assert.equal(intersects(mobile.target, mobile.controls), false,
        `mobile action panel overlaps opponent target: ${JSON.stringify(mobile)}`);
      assert.ok(mobile.documentWidth <= mobile.viewport.width,
        `mobile layout overflows horizontally: ${JSON.stringify(mobile)}`);
      await p.evaluate(() => window.__tqsRealLuaE2e.finishGame());
    }],
  );
  tests.push(
    ['AG shows native faces and sends exactly one selected integer, cancellation is empty bytes', async (p) => {
      const data = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('ag'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      await panel.locator('.gameplay-choice').first().click();
      await reply(p);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), data.cardIds[0]);
      assert.match(await p.evaluate((id) => window.__tqsRealLuaE2e.attemptNative(id), data.id) ?? '', /thay đổi/);
      assert.equal((await snapshot(p)).replies.length, 1);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('ag'));
      await panel.getByRole('button', { name: 'Bỏ qua' }).click();
      await reply(p); assert.equal((await snapshot(p)).replies[0].hex, '40');
    }],
    ['ArrangeCards enforces native row limits, ordered moves and Lua nested CBOR arrays', async (p) => {
      const data = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('arrange'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', { name: 'Xác nhận' }).isDisabled(), true);
      await panel.locator('.gameplay-choice').first().click();
      await panel.getByRole('button', { name: 'Đặt cuối nhóm 2' }).click();
      await panel.getByRole('button', { name: 'Xác nhận' }).click();
      await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()),
        [[data.cardIds[1], data.cardIds[2]], [data.cardIds[0]]]);
      assert.deepEqual((await snapshot(p)).luaErrors, []);
    }],
    ['KnownBoth custom dialog reveals only the addressed generals and replies with native cards/choice', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('generals'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      await panel.getByText('Trâu Thị', { exact: true }).waitFor();
      await panel.getByText('Sĩ Nhiếp', { exact: true }).waitFor();
      await panel.getByRole('button', { name: 'Xác nhận' }).click(); await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), { cards: [], choice: 'OK' });
    }],
    ['Native dialog stale tokens, replacement, expiry and disconnect never emit replies', async (p) => {
      const old = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('ag'));
      const active = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('ag'));
      assert.match(await p.evaluate(({id,token}) => window.__tqsRealLuaE2e.attemptNative(id,token),
        {id:active.id,token:old.tokens![0]}) ?? '', /không hợp lệ/);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('arrange', true));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', { name: 'Xác nhận' }).isDisabled(), true);
      assert.equal((await snapshot(p)).replies.length, 0);
      const exp = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('ag', true));
      assert.match(await p.evaluate(({id,token}) => window.__tqsRealLuaE2e.attemptNative(id,token),
        {id:exp.id,token:exp.tokens![0]}) ?? '', /hết thời gian/);
      assert.equal((await snapshot(p)).replies.length, 0);
    }],
  );
  tests.push(
    ['Native Reconnect rebuilds the room in Lua, restores online status and discards the old request', async (p) => {
      const result = await p.evaluate(() => window.__tqsRealLuaE2e.reconnectSummary());
      assert.equal(result.status, 'online'); assert.equal(result.phase, 'playing');
      assert.deepEqual(result.seats, [17,-1]); assert.equal(result.request, null);
      assert.equal(result.ownId, 17);
      assert.equal(result.players[17].selfGeneral, 'ld__bianfuren');
      assert.equal(result.players[17].selfDeputyGeneral, 'm_heg__dianwei');
      assert.equal(result.players[-1].selfGeneral, null);
      assert.equal(result.players[-1].general, null);
      assert.equal(result.players[17].handcardNum, 1);
      assert.deepEqual(result.fakeSkills, [{ name: 'hs__yiji', prelighted: true, enabled: true }]);
      assert.deepEqual(result.regularSkills, [{ name: 'hs__zhiheng' }]);
      assert.ok(result.reconnectUiPayloadBytes <= 64,
        `Reconnect UI projection must stay bounded, got ${result.reconnectUiPayloadBytes} bytes`);
      assert.deepEqual(result.errors, []);
    }],
    ['AskForOptions uses the native seven-field payload and sends one unchanged option', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('options'));
      const panel = p.getByRole('region', { name: 'Lựa chọn trong trận' });
      // The seventh native field is FreeKill's `single` flag. AskForOptions
      // therefore confirms by clicking the offered option itself; it is not
      // the eight-field AskForChoices contract with a separate OK button.
      await panel.getByRole('button', { name: 'OK', exact: true }).click();
      await reply(p); assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['OK']);
    }],
  );
  tests.push(
    ['ChooseCardNames returns only offered names and native single-choice auto-confirm', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('cardNames'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', {name:'Thiểm',exact:true}).count(),0);
      await panel.getByRole('button', {name:'Sát',exact:true}).click();
      await reply(p);assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['slash']);
    }],
    ['ChooseGeneralsAndChoice obeys disabled generals and returns native cards/choice or cancel', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('generalOptions'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', {name:'Xác nhận',exact:true}).isEnabled(),false);
      assert.equal(await panel.getByRole('button', {name:'Sĩ Nhiếp',exact:true}).isEnabled(),false);
      await panel.getByRole('button', {name:'Trâu Thị',exact:true}).click();
      await panel.getByRole('button', {name:'Xác nhận',exact:true}).click();
      await reply(p);assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {cards:['hs__zoushi'],choice:'OK'});
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('generalOptions'));
      await panel.getByRole('button', {name:'Hủy',exact:true}).click();
      await reply(p);assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {cards:[],choice:'Cancel'});
    }],
    ['ChooseSkill custom component uses native min/max, selectable skills and empty-byte cancellation', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('skills'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', {name:'Xác nhận',exact:true}).isEnabled(),false);
      await panel.getByRole('button', {name:'Họa Thủy',exact:true}).click();
      assert.equal(await panel.getByRole('button', {name:'Khuynh Thành',exact:true}).isEnabled(),false);
      await panel.getByRole('button', {name:'Xác nhận',exact:true}).click();
      await reply(p);assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['huoshui']);
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('skills'));
      await panel.getByRole('button', {name:'Bỏ qua',exact:true}).click();
      await reply(p);assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), '');
    }],
    ['AskForGeneral validates native selection and sends only the chosen wire name', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('generalChoice'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      assert.equal(await panel.getByRole('button', { name: 'Xác nhận', exact: true }).isDisabled(), true);
      await panel.getByRole('button', { name: 'Trâu Thị', exact: true }).click();
      await panel.getByRole('button', { name: 'Xác nhận', exact: true }).click(); await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['hs__zoushi']);
    }],
    ['MoveCardInBoard sends the native cardId/pos pair without exposing raw IDs to the panel', async (p) => {
      const data = await p.evaluate(() => window.__tqsRealLuaE2e.beginNative('boardMove'));
      const panel = p.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
      await panel.locator('.gameplay-choice').nth(1).click(); await reply(p);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {cardId:data.cardIds[1],pos:1});
    }],
  );
  tests.push(
    ['QA Scenario Mode resolves deterministic draws and reaches every required native caller', async (p) => {
      const startScenario = async (scenario: QaScenarioId) => {
        const result = await p.evaluate((id) => window.__tqsRealLuaE2e.beginQaScenario(id), scenario);
        assert.equal(result.expectedCommand, QA_SCENARIOS[scenario].expectedCommand);
        assert.equal((await snapshot(p)).requestId, result.requestId);
        return result;
      };

      const draw = await startScenario('draw-sequence');
      assert.deepEqual(draw.drawPile.slice(0, 3), [
        draw.slotCards.slash, draw.slotCards.peach, draw.slotCards.nullification,
      ]);
      assert.equal(await p.locator(`button[data-card-id="${draw.slotCards.slash}"]`).count(), 1);

      const chosen = await startScenario('card-chosen');
      const chosenPanel = p.getByRole('region', { name: 'Chọn bài đối thủ' });
      await chosenPanel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, chosen.requestId);
      assert.equal(typeof await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), 'number');

      const poxi = await startScenario('poxi');
      const poxiPanel = p.getByRole('region', { name: 'Chọn bài đối thủ' });
      await poxiPanel.getByRole('button', { name: 'Bài úp', exact: true }).click();
      await poxiPanel.getByRole('group').nth(1).getByRole('button').click();
      await poxiPanel.getByRole('button', { name: 'Xác nhận chọn bài', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, poxi.requestId);
      const poxiReply = await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply());
      assert.ok(Array.isArray(poxiReply));
      assert.equal(poxiReply.length, 2);

      const cardsAndChoice = await startScenario('cards-and-choice');
      const cardsPanel = p.getByRole('region', { name: 'Xem bài và chọn phương án' });
      await cardsPanel.getByRole('group').getByRole('button').nth(0).click();
      await cardsPanel.getByRole('button', { name: 'Dùng Sát', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, cardsAndChoice.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        cards: [cardsAndChoice.slotCards.slash], choice: 'use',
      });

      const normalRescue = await startScenario('rescue-normal');
      await p.locator(`button[data-card-id="${normalRescue.slotCards.peach}"]`).click();
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, normalRescue.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        card: normalRescue.slotCards.peach, targets: [],
      });

      const battleRescue = await startScenario('rescue-battle');
      await p.getByRole('button', { name: 'Quyết chiến', exact: true }).click();
      await p.locator(`button[data-card-id="${battleRescue.slotCards.peach}"]`).click();
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, battleRescue.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        card: { skill: 'new_battle_royal&', subcards: [battleRescue.slotCards.peach] }, targets: [],
      });

      const founding = await startScenario('founding');
      await p.getByText('Dã tâm gia lập quốc: chọn quốc hiệu của bạn.', { exact: true }).waitFor();
      await p.getByRole('button', { name: 'Tần', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, founding.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['heg_qin']);

      const damageExchange = await startScenario('fazheng-enyuan');
      const damageControls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
      const damageCard = damageControls.locator('.gameplay-hand button.gameplay-choice:enabled').first();
      if (await damageCard.count()) await damageCard.click();
      await p.locator('.board-player:not(.board-self) .gameplay-target:enabled').click();
      await damageControls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      await reply(p);
      assert.equal((await snapshot(p)).replies[0].requestId, damageExchange.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        card: { skill: 'userealcard_skill', subcards: [damageExchange.slotCards['actor-slash-1']] }, targets: [-1],
      });

      const hiddenYiji = await startScenario('hidden-yiji');
      // This fixture deliberately adds only hs__yiji; the translated label is
      // package-dependent, so select the sole fake-skill button by role.
      const fakeYiji = p.locator('button.fake-skill-button').first();
      await fakeYiji.waitFor();
      await fakeYiji.click();
      await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgePrelight(true));
      await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
        skill.name === 'hs__yiji' && skill.prelighted));
      await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
      const hiddenReply = await reply(p);
      assert.equal(hiddenReply.replies[0].requestId, hiddenYiji.requestId);
      assert.equal(hiddenReply.replies[0].hex, '4131');
      await p.evaluate(() => window.__tqsRealLuaE2e.boardNotify('PropertyUpdate', "{17, 'hp', 3}"));
      assert.equal((await snapshot(p)).fakeSkills.find((skill) => skill.name === 'hs__yiji')?.prelighted, true);

      for (const scenarioId of ['hidden-jianxiong', 'hidden-jianxiong-deputy'] as const) {
        const hiddenJianxiong = await startScenario(scenarioId);
        const fakeJianxiong = p.locator('button.fake-skill-button').first();
        await fakeJianxiong.waitFor();
        await fakeJianxiong.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeJianxiongPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'hs__jianxiong' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const invokeReply = await reply(p);
        assert.equal(invokeReply.replies.at(-1)?.requestId, hiddenJianxiong.requestId);
        const choiceRequestId = await p.evaluate(() => window.__tqsRealLuaE2e.continueHiddenJianxiong());
        const jianxiongChoices = p.getByRole('region', { name: 'Lựa chọn trong trận' });
        await jianxiongChoices.waitFor();
        const obtain = jianxiongChoices.locator('button.gameplay-choice:enabled')
          .filter({ hasText: /hs__jianxiong-obtain|obtain|获得|lá Sát|gây sát thương/i }).first();
        assert.ok(await obtain.count(), `${scenarioId} must render the native obtain-damage-card choice`);
        // Native room:askToChoice() emits AskForChoices with single=true.
        // ChoicePanel therefore replies on option click and intentionally does
        // not render the multi-select confirmation button.
        await obtain.click();
        const choiceReply = await reply(p, 2);
        assert.equal(choiceReply.replies.at(-1)?.requestId, choiceRequestId);
        assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), ['hs__jianxiong-obtain']);
        assert.deepEqual(choiceReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-fankui', 'hidden-fankui-deputy'] as const) {
        const hiddenFankui = await startScenario(scenarioId);
        const fakeFankui = p.locator('button.fake-skill-button').filter({ hasText: /Phản Quỹ|反馈|fankui/i }).first();
        await fakeFankui.waitFor();
        await fakeFankui.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeFankuiPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'fankui' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenFankui.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-luoshen', 'hidden-luoshen-deputy'] as const) {
        const hiddenLuoshen = await startScenario(scenarioId);
        const fakeLuoshen = p.locator('button.fake-skill-button').filter({ hasText: /洛神|Lạc Thần|luoshen/i }).first();
        await fakeLuoshen.waitFor();
        await fakeLuoshen.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeLuoshenPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'hs__luoshen' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenLuoshen.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-jizhi', 'hidden-jizhi-deputy'] as const) {
        const hiddenJizhi = await startScenario(scenarioId);
        const fakeJizhi = p.locator('button.fake-skill-button').filter({ hasText: /集智|Tập Trí|jizhi/i }).first();
        await fakeJizhi.waitFor();
        await fakeJizhi.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeJizhiPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'hs__jizhi' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenJizhi.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-mingshi', 'hidden-mingshi-deputy'] as const) {
        const hiddenMingshi = await startScenario(scenarioId);
        const fakeMingshi = p.locator('button.fake-skill-button').filter({ hasText: /名士|Danh Sĩ|mingshi/i }).first();
        await fakeMingshi.waitFor();
        await fakeMingshi.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeMingshiPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'mingshi' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenMingshi.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-qianxun', 'hidden-qianxun-deputy'] as const) {
        const hiddenQianxun = await startScenario(scenarioId);
        const fakeQianxun = p.locator('button.fake-skill-button').filter({ hasText: /谦逊|Khiêm Tốn|qianxun/i }).first();
        await fakeQianxun.waitFor();
        await fakeQianxun.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeQianxunPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'hs__qianxun' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenQianxun.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      for (const scenarioId of ['hidden-qianxun-indulgence', 'hidden-qianxun-indulgence-deputy'] as const) {
        const hiddenQianxun = await startScenario(scenarioId);
        const fakeQianxun = p.locator('button.fake-skill-button').filter({ hasText: /谦逊|Khiêm Tốn|qianxun/i }).first();
        await fakeQianxun.waitFor();
        await fakeQianxun.click();
        await p.evaluate(() => window.__tqsRealLuaE2e.acknowledgeQianxunPrelight(true));
        await p.waitForFunction(() => window.__tqsRealLuaE2e.snapshot().fakeSkills.some((skill) =>
          skill.name === 'hs__qianxun' && skill.prelighted));
        await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
        const gateReply = await reply(p);
        assert.equal(gateReply.replies.at(-1)?.requestId, hiddenQianxun.requestId);
        assert.equal(gateReply.replies.at(-1)?.hex, '4131');
        assert.deepEqual(gateReply.luaErrors, []);
      }

      const hiddenReveal = await startScenario('hidden-reveal');
      const reveal = p.locator('button.sg-skill-button').filter({ hasText: /Mở tướng|reveal_skill&/ }).first();
      await reveal.waitFor();
      // AskForUseActiveSkill already selects reveal_skill& on the native
      // request.  Its SkillButton remains visible but disabled; the legal
      // action is the Lua-owned interaction choice below, not a second skill
      // switch inside the active-skill scene.
      assert.equal(await reveal.isDisabled(), true,
        'hidden compulsory active reveal must not allow a second SkillButton switch');
      const revealChoices = p.getByRole('combobox', { name: 'Chọn phương án' });
      await revealChoices.waitFor();
      assert.deepEqual(await revealChoices.locator('option').evaluateAll((options) =>
        options.map((option) => (option as HTMLOptionElement).value)), ['revealMain:::hs__luxun']);
      await p.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const revealReply = await reply(p);
      assert.equal(revealReply.replies.at(-1)?.requestId, hiddenReveal.requestId);

      const hiddenActive = await startScenario('hidden-active');
      const activeControls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
      const zhiheng = activeControls.locator('button.sg-skill-button')
        .filter({ hasText: /Chế Hành|制衡|zhiheng/i }).first();
      await zhiheng.waitFor();
      assert.equal(await zhiheng.isEnabled(), true,
        'hidden active skill must be a Lua-enabled PlayCard SkillButton');
      await zhiheng.click();
      await p.locator(`button[data-card-id="${hiddenActive.slotCards['zhiheng-card']}"]:enabled`).click();
      await activeControls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const hiddenActiveReply = await reply(p);
      assert.equal(hiddenActiveReply.replies.at(-1)?.requestId, hiddenActive.requestId);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        card: { skill: 'hs__zhiheng', subcards: [hiddenActive.slotCards['zhiheng-card']] }, targets: [],
      });

      for (const scenarioId of ['hidden-view-as', 'hidden-view-as-main'] as const) {
        const hiddenViewAs = await startScenario(scenarioId);
        const viewAsControls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
        const longdan = viewAsControls.locator('button.sg-skill-button')
          .filter({ hasText: /Long Đảm|龙胆|longdan/i }).first();
        await longdan.waitFor();
        assert.equal(await longdan.isEnabled(), true,
          `${scenarioId} must expose hidden Long Đảm as a Lua-enabled PlayCard SkillButton`);
        await longdan.click();
        await p.locator(`button[data-card-id="${hiddenViewAs.slotCards['longdan-card']}"]:enabled`).click();
        const target = p.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
        await target.click();
        await viewAsControls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
        const hiddenViewAsReply = await reply(p);
        assert.equal(hiddenViewAsReply.replies.at(-1)?.requestId, hiddenViewAs.requestId);
        assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
          card: { skill: 'hs__longdan', subcards: [hiddenViewAs.slotCards['longdan-card']] }, targets: [-1],
        });
        assert.deepEqual(hiddenViewAsReply.luaErrors, []);
      }
    }],
  );
  tests.push(
    ['QA Scenario Mode Longdan converts Slash to Jink and Jink to Slash through actual Lua', async (p) => {
      for (const direction of ['defend', 'attack'] as const) {
        const { id, cardId } = await p.evaluate((value) => window.__tqsRealLuaE2e.beginLongdan(value), direction);
        const controls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
        await controls.getByRole('button', { name: 'Long Đảm', exact: true }).click();
        await controls.locator(`button[data-card-id="${cardId}"]:enabled`).click();
        if (direction === 'attack') await p.locator('.board-player:not(.board-self) .gameplay-target:enabled').click();
        await controls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
        const s = await reply(p);
        assert.equal(s.replies.length, 1);
        assert.equal(s.replies[0].requestId, id);
        assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
          card: { skill: 'hs__longdan', subcards: [cardId] }, targets: direction === 'attack' ? [-1] : [],
        });
        assert.deepEqual(s.luaErrors, []);
      }
    }],
    ['QA Scenario Mode Yiji and Fankui each allow Invoke and Skip', async (p) => {
      for (const skill of ['hs__yiji', 'fankui'] as const) {
        for (const invoke of [true, false]) {
          const { id } = await p.evaluate((value) => window.__tqsRealLuaE2e.beginFankui(value), skill);
          assert.equal((await snapshot(p)).skill?.skill, skill);
          assert.equal(await p.getByRole('button', { name: 'Kích hoạt', exact: true }).isEnabled(), true);
          assert.equal(await p.getByRole('button', { name: 'Bỏ qua', exact: true }).isEnabled(), true);
          await p.getByRole('button', { name: invoke ? 'Kích hoạt' : 'Bỏ qua', exact: true }).click();
          const s = await reply(p);
          assert.equal(s.replies.length, 1);
          assert.equal(s.replies[0].requestId, id);
          assert.equal(s.replies[0].hex, invoke ? '4131' : '485f5f63616e63656c');
          assert.deepEqual(s.luaErrors, []);
        }
      }
    }],
    ['QA Scenario Mode invoked Yiji gives both expanded cards to self; Fankui chooses one source card', async (p) => {
      await p.evaluate(() => window.__tqsRealLuaE2e.beginFankui('hs__yiji'));
      await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
      await reply(p);
      const yiji = await p.evaluate(() => window.__tqsRealLuaE2e.continueYiji());
      const controls = p.getByRole('region', { name: 'Điều khiển lượt chơi' });
      for (const cardId of yiji.cards) await controls.locator(`button[data-card-id="${cardId}"]:enabled`).click();
      await p.locator('.board-self .gameplay-target:enabled').click();
      await controls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
      const distributed = await reply(p, 2);
      assert.equal(distributed.replies[1].requestId, yiji.id);
      assert.deepEqual(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), {
        card: { skill: 'ex__choose_skill', subcards: yiji.cards }, targets: [17],
      });
      assert.deepEqual(distributed.luaErrors, []);

      const fankui = await p.evaluate(() => window.__tqsRealLuaE2e.beginFankui('fankui'));
      await p.getByRole('button', { name: 'Kích hoạt', exact: true }).click();
      await reply(p);
      const id = await p.evaluate(() => window.__tqsRealLuaE2e.continueFankui());
      await p.getByRole('region', { name: 'Chọn bài đối thủ' }).getByRole('button', { name: 'Bài úp', exact: true }).click();
      const chosen = await reply(p, 2);
      assert.equal(chosen.replies[1].requestId, id);
      assert.equal(await p.evaluate(() => window.__tqsRealLuaE2e.decodedReply()), fankui.cardId);
      assert.deepEqual(chosen.luaErrors, []);
    }],
  );
  const testsToRun = process.argv.includes('--qa-scenarios')
    ? tests.filter(([name]) => name.startsWith('QA Scenario Mode'))
    : tests;
  let passed = 0;
  const failures: string[] = [];
  for (const [name, test] of testsToRun) {
    try {
      await test(page);
      console.log(`PASS ${name}`);
      passed++;
    } catch (err) {
      failures.push(name);
      console.error(`FAIL ${name}:`, err);
      console.error('Snapshot:', JSON.stringify(await snapshot(page)).slice(0, 1300));
    }
  }
  console.log(`Real Lua Browser E2E${testsToRun.length === 1 ? ' QA Scenario Mode' : ''}: ${passed}/${testsToRun.length} PASS`);
  assert.equal(failures.length, 0, `Failed scenarios: ${failures.join(', ')}`);
  assert.deepEqual(errors, [], 'Browser runtime errors');
} finally {
  await browser?.close();
  await vite.close();
}
