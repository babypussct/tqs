/** Real Chrome UI integration tests, with a local Vite server and mocked
 * FreeKill socket/Lua callback. No external server or account is contacted. */
import assert from 'node:assert/strict';
import { existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, type Locator, type Page } from 'playwright-core';
import { createServer } from 'vite';

const root = fileURLToPath(new URL('../../', import.meta.url));
const chromeCandidates = [process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'];
const executablePath = chromeCandidates.find((p): p is string => !!p && existsSync(p));
if (!executablePath) throw new Error('Không tìm thấy Chrome: đặt biến TQS_CHROME_PATH');

type Scenario = 'choices' | 'widgets' | 'direct-step' | 'direct-complete' |
  'direct-pending' | 'dynamic' | 'lua-error';
type Snapshot = {
  requestId: number | null; prompt: string; error: string | null;
  status: string; socketCount: number;
  fakeSkills: { name: string; prelighted: boolean; enabled: boolean }[];
  regularSkills: { name: string }[];
  actions: unknown[][];
  replyCount: number;
  sent: { requestId: number; type: number; hex: string }[];
};

async function start(page: Page, mode: Scenario, expired = false): Promise<number> {
  const id = await page.evaluate(([scenario, isExpired]) =>
    window.__tqsE2e.begin(scenario, isExpired), [mode, expired] as const);
  await page.getByRole('heading', { name: 'E2E cục bộ', exact: true }).waitFor();
  return id;
}
function snapshot(page: Page): Promise<Snapshot> {
  return page.evaluate(() => window.__tqsE2e.snapshot());
}
async function waitActions(page: Page, count: number) {
  await page.waitForFunction((n) => window.__tqsE2e.snapshot().actions.length >= n, count);
}
async function waitReplies(page: Page, count: number) {
  await page.waitForFunction((n) => window.__tqsE2e.snapshot().replyCount >= n, count);
}

async function assertCrowdedSkillRail(page: Page, selector: string, viewport: { width: number; height: number }) {
  const check = await page.evaluate((source) => {
    const rail = document.querySelector<HTMLElement>('.board-local-skill-rail')!;
    const sourceButton = rail.querySelector<HTMLElement>(source)!;
    const entry = sourceButton.closest<HTMLElement>('.sg-skill-info-entry')!;
    const dock = entry.parentElement!;
    // Only clone existing DOM for the crowding check. Never mutate Lua skill
    // permissions, game state, or the native protocol.
    const clones: HTMLElement[] = [];
    for (let i = 0; i < 12; i++) {
      const clone = entry.cloneNode(true) as HTMLElement;
      clone.querySelector<HTMLElement>('.sg-skill-button')!.textContent = `Kỹ năng ${i + 1}`;
      dock.appendChild(clone);
      clones.push(clone);
    }
    const railRect = rail.getBoundingClientRect();
    const geometry = [...rail.querySelectorAll<HTMLElement>('.sg-skill-button')].map((el) => {
      const r = el.getBoundingClientRect();
      return { left: r.left, right: r.right, top: r.top, bottom: r.bottom, width: r.width };
    });
    const state = { display: getComputedStyle(rail).display,
      direction: getComputedStyle(rail).flexDirection,
      overflowX: getComputedStyle(rail).overflowX,
      scrollWidth: rail.scrollWidth, clientWidth: rail.clientWidth,
      railTop: railRect.top, railBottom: railRect.bottom, geometry };
    rail.scrollLeft = rail.scrollWidth;
    const last = clones.at(-1)!.getBoundingClientRect();
    const lastVisible = last.right <= railRect.right + 1 && last.left >= railRect.left - 1;
    clones.forEach((el) => el.remove());
    return { ...state, lastVisible };
  }, selector);
  assert.equal(check.display, 'flex');
  assert.equal(check.direction, 'row');
  assert.equal(check.overflowX, 'auto');
  assert.ok(check.geometry.length >= 14, `dense skill fixture absent: ${JSON.stringify(check)}`);
  assert.ok(check.geometry.every((button) => button.width > 0 &&
    button.top >= check.railTop - 2 && button.bottom <= check.railBottom + 2),
  `skills escape their rail at ${viewport.width}x${viewport.height}: ${JSON.stringify(check)}`);
  for (let i = 1; i < check.geometry.length; i++) {
    assert.ok(check.geometry[i].left >= check.geometry[i - 1].right - 1,
      `skills overlap at ${viewport.width}x${viewport.height}: ${JSON.stringify(check)}`);
  }
  assert.ok(check.scrollWidth > check.clientWidth + 100 && check.lastVisible,
    `crowded skills must scroll to the end at ${viewport.width}x${viewport.height}: ${JSON.stringify(check)}`);
}

async function runSuite(page: Page) {
  const tests: [string, (page: Page) => Promise<void>][] = [
    ['In-match utility dock frees the board and log drawer overlays without layout shift', async (p) => {
      for (const viewport of [
        { width: 320, height: 568 }, { width: 390, height: 844 },
        { width: 844, height: 390 }, { width: 1280, height: 800 },
      ]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        const tools = p.getByRole('button', { name: 'Tùy chọn trận đấu' });
        const history = p.getByRole('button', { name: 'Lịch sử', exact: true });
        const geometry = () => p.evaluate(() => {
          const toolbar = document.querySelector<HTMLElement>('.board-toolbar')!;
          const board = document.querySelector<HTMLElement>('.sg-board-table')!;
          const stage = document.querySelector<HTMLElement>('.board-layout')!;
          const log = document.querySelector<HTMLElement>('.sg-board-log-panel')!;
          const rect = board.getBoundingClientRect();
          return {
            toolbarPosition: getComputedStyle(toolbar).position,
            toolbarRight: toolbar.getBoundingClientRect().right,
            board: { top: rect.top, left: rect.left, width: rect.width, height: rect.height },
            columns: getComputedStyle(stage).gridTemplateColumns,
            logDisplay: getComputedStyle(log).display,
            logPosition: getComputedStyle(log).position,
            scrollWidth: document.documentElement.scrollWidth,
          };
        });
        const closed = await geometry();
        assert.equal(closed.toolbarPosition, 'absolute');
        assert.equal(closed.logDisplay, 'none');
        assert.ok(closed.toolbarRight <= viewport.width + 1);
        assert.ok(closed.scrollWidth <= viewport.width + 1);

        await tools.click();
        await p.getByRole('button', { name: 'Cài đặt nhạc nền' }).waitFor({ state: 'visible' });
        // The minimal fixture omits BOT control; the real App passes it.
        if (await p.getByRole('button', { name: 'BOT chơi hộ' }).count()) {
          await p.getByRole('button', { name: 'BOT chơi hộ' }).waitFor({ state: 'visible' });
        }
        await p.getByRole('button', { name: 'Rời trận' }).waitFor({ state: 'visible' });
        await p.keyboard.press('Escape');
        assert.equal(await tools.getAttribute('aria-expanded'), 'false');

        await history.click();
        const opened = await geometry();
        assert.equal(opened.logPosition, 'absolute');
        assert.notEqual(opened.logDisplay, 'none');
        assert.deepEqual(opened.board, closed.board, `log changed felt geometry at ${viewport.width}x${viewport.height}`);
        assert.equal(opened.columns, closed.columns);
        assert.ok(opened.scrollWidth <= viewport.width + 1);
        await p.getByRole('button', { name: 'Ẩn lịch sử' }).click();
        assert.equal((await geometry()).logDisplay, 'none');
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Upstream HP colors progress from green to yellow and red in the actual portrait', async (p) => {
      for (const viewport of [{ width: 390, height: 844 }, { width: 844, height: 390 }, { width: 1280, height: 800 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        for (const [hp, maxHp, shield, expected, fractionColor] of [
          [4, 4, 0, ['3-heg', '3-heg', '3-heg', '3-heg'], ''],
          [3, 4, 0, ['0-heg', '3-heg', '3-heg', '3-heg'], ''],
          [2, 4, 0, ['0-heg', '0-heg', '2-heg', '2-heg'], ''],
          [1, 4, 0, ['0-heg', '0-heg', '0-heg', '1-heg'], ''],
          [0, 4, 0, ['0-heg', '0-heg', '0-heg', '0-heg'], ''],
          [1, 2, 0, ['0-heg', '1-heg'], ''],
          [2, 2, 0, ['3-heg', '3-heg'], ''],
          [1, 8, 0, ['1-heg'], 'rgb(244, 24, 14)'],
          [2, 8, 0, ['2-heg'], 'rgb(227, 176, 6)'],
          [3, 8, 0, ['3-heg'], 'rgb(37, 236, 39)'],
          [2, 4, 1, ['2-heg'], 'rgb(227, 176, 6)'],
        ] as const) {
          await p.evaluate(([value, maximum, protection]) =>
            window.__tqsE2e.setHealth(value, maximum, protection), [hp, maxHp, shield] as const);
          const hpPanel = p.locator('.board-local-seat .sg-hp-vertical-column');
          await hpPanel.locator('.native-heg-hp-disc-v').first().waitFor();
          const result = await hpPanel.evaluate((el) => {
            const images = [...el.querySelectorAll<HTMLImageElement>('.native-heg-hp-disc-v')];
            const rects = images.map((img) => img.getBoundingClientRect());
            const fraction = el.querySelector<HTMLElement>('.sg-hp-vertical-fraction');
            return {
              assets: images.map((img) => img.src.split('/').at(-1)?.replace('.png', '')),
              emptyOpacity: [...el.querySelectorAll<HTMLElement>('.sg-magatama-empty')].map((img) => getComputedStyle(img).opacity),
              vertical: rects.every((rect, index) => index === 0 || rect.top >= rects[index - 1].bottom - 1),
              fractionColor: fraction ? getComputedStyle(fraction).color : '',
            };
          });
          assert.deepEqual(result.assets, expected, `${hp}/${maxHp} at ${viewport.width}x${viewport.height}`);
          assert.ok(result.vertical, `magatama must stack vertically: ${JSON.stringify(result)}`);
          assert.ok(result.emptyOpacity.every((opacity) => opacity === '0'), `empty HP slots visible: ${JSON.stringify(result)}`);
          assert.equal(result.fractionColor, fractionColor, `${hp}/${maxHp} at ${viewport.width}x${viewport.height}`);
        }
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Upstream battlefield and music settings work across viewports', async (p) => {
      // Audio playback is simulated here so autoplay policy and hardware sound
      // cannot make Chrome UI regression tests environment-dependent.
      const browser = p.context().browser();
      assert.ok(browser);
      const context = await browser.newContext({ viewport: { width: 320, height: 568 } });
      try {
        const preview = await context.newPage();
        preview.setDefaultTimeout(8_000);
        await preview.addInitScript({ content: `(() => {
          const probe = { starts: 0, pauses: 0, src: '', loop: false, volume: 1 };
          class MockAudio extends EventTarget {
            constructor(src) {
              super(); this.paused = true; this.loop = false;
              this.preload = ''; this.error = null; this.currentVolume = 1;
              probe.src = src;
            }
            get volume() { return this.currentVolume; }
            set volume(value) { this.currentVolume = value; probe.volume = value; }
            play() {
              probe.starts++;
              probe.loop = this.loop;
              if (probe.starts === 1) return Promise.reject(new DOMException('Gesture required', 'NotAllowedError'));
              this.paused = false;
              return Promise.resolve();
            }
            pause() { probe.pauses++; this.paused = true; }
          }
          Object.defineProperty(window, 'Audio', { value: MockAudio, configurable: true });
          Object.defineProperty(window, '__bgmProbe', { value: probe, configurable: true });
        })();` });
        await preview.goto(new URL('/e2e.html', p.url()).href);
        await start(preview, 'choices');
        const settings = preview.getByRole('button', { name: 'Cài đặt nhạc nền' });
        await preview.waitForFunction(() =>
          document.querySelector('.battle-music-settings button')?.getAttribute('data-playback') === 'blocked');
        const initial = await preview.evaluate(() =>
          (window as unknown as { __bgmProbe: { src: string; volume: number; loop: boolean; starts: number } }).__bgmProbe);
        assert.ok(initial.src.endsWith('/audio/system/bgm.mp3'));
        assert.equal(initial.volume, 0.5);
        assert.equal(initial.starts, 1);

        for (const viewport of [
          { width: 320, height: 568 }, { width: 390, height: 844 },
          { width: 844, height: 390 }, { width: 1280, height: 800 },
        ]) {
          await preview.setViewportSize(viewport);
          const stage = await preview.locator('.sg-board-table').evaluate((node) => ({
            image: getComputedStyle(node).backgroundImage,
            sizing: getComputedStyle(node).backgroundSize,
          }));
          assert.ok(stage.image.includes('gamebg-upstream.jpg'), `upstream scenery missing at ${viewport.width}x${viewport.height}`);
          assert.ok(stage.sizing.includes('cover'), `scenery must crop like FreeKill at ${viewport.width}x${viewport.height}`);
          await preview.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
          await settings.click();
          const popover = preview.getByRole('group', { name: 'Điều khiển nhạc nền trận đấu' });
          await popover.waitFor({ state: 'visible' });
          const rect = await popover.boundingBox();
          assert.ok(rect && rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= viewport.width + 1 &&
            rect.y + rect.height <= viewport.height + 1,
          `popover escapes the viewport ${viewport.width}x${viewport.height}: ${JSON.stringify(rect)}`);
          const blockedActions = await preview.evaluate(() => {
            const popup = document.querySelector('.battle-music-popover')!.getBoundingClientRect();
            return [...document.querySelectorAll<HTMLElement>('.sg-btn-ok, .sg-btn-cancel')]
              .filter((button) => {
                const action = button.getBoundingClientRect();
                return action.width > 0 && action.height > 0 &&
                  Math.min(popup.right, action.right) - Math.max(popup.left, action.left) > 1 &&
                  Math.min(popup.bottom, action.bottom) - Math.max(popup.top, action.top) > 1;
              }).map((button) => button.textContent);
          });
          assert.deepEqual(blockedActions, [], `music settings block gameplay at ${viewport.width}x${viewport.height}`);
          if (process.env.TQS_EVIDENCE_DIR) {
            const evidenceDir = path.resolve(process.env.TQS_EVIDENCE_DIR);
            mkdirSync(evidenceDir, { recursive: true });
            await preview.screenshot({ path: path.join(evidenceDir,
              `upstream-battlefield-music-${viewport.width}x${viewport.height}.png`) });
          }
          await preview.keyboard.press('Escape');
          assert.equal(await popover.count(), 0);
        }

        await preview.setViewportSize({ width: 390, height: 844 });
        await preview.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
        await settings.click();
        await preview.getByRole('button', { name: 'Phát nhạc nền' }).click();
        await preview.waitForFunction(() =>
          document.querySelector('.battle-music-settings button')?.getAttribute('data-playback') === 'playing');
        const state = await preview.evaluate(() =>
          (window as unknown as { __bgmProbe: { starts: number; loop: boolean } }).__bgmProbe);
        assert.equal(state.starts, 2);
        assert.equal(state.loop, true);
        const slider = preview.getByRole('slider', { name: /Âm lượng nhạc nền/ });
        await slider.focus();
        await slider.press('Home');
        for (let i = 0; i < 6; i++) await slider.press('ArrowRight');
        await preview.getByText('Âm lượng nhạc nền: 30%').waitFor();
        assert.equal(await preview.evaluate(() =>
          (window as unknown as { __bgmProbe: { volume: number } }).__bgmProbe.volume), 0.3);
        await preview.getByRole('button', { name: 'Tắt nhạc nền' }).click();
        assert.equal(await settings.getAttribute('data-enabled'), 'false');
        const stored = await preview.evaluate(() => JSON.parse(localStorage.getItem('tqs.battleMusic.v1') ?? '{}'));
        assert.deepEqual(stored, { enabled: false, volume: 30 });
        await preview.reload();
        await start(preview, 'choices');
        await preview.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
        assert.equal(await preview.getByRole('button', { name: 'Cài đặt nhạc nền' }).getAttribute('data-enabled'), 'false');
        await preview.getByRole('button', { name: 'Cài đặt nhạc nền' }).click();
        await preview.getByText('Âm lượng nhạc nền: 30%').waitFor();
      } finally {
        await context.close();
      }
    }],
    ['Main app renders in actual Chrome', async (p) => {
      // Startup is intentionally offline. Exercise the visible error state
      // without forwarding a request to a missing or external Gateway.
      await p.route('**/gateway/manifest.json', (route) => route.fulfill({
        status: 503, contentType: 'application/json', body: '{"error":"Offline E2E fixture"}',
      }));
      await p.goto('/');
      await p.getByRole('heading', { name: /Tam Quốc Sát/ }).waitFor();
      await p.getByRole('alert').getByText('Máy chủ đang tạm thời không khả dụng. Vui lòng thử tải lại trò chơi sau ít phút.').waitFor();
      await p.goto('/e2e.html');
      await p.unroute('**/gateway/manifest.json');
      await p.locator('.sg-game-board').waitFor();
    }],
    ['Game errors remain visible in the active match and hide native protocol details', async (p) => {
      await p.goto('/e2e.html?app=1');
      await p.evaluate(() => window.__tqsE2e.begin('choices'));
      await p.getByRole('heading', { name: 'E2E cục bộ', exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.emitUiError('backend error'));
      await p.getByRole('alert').getByText('Không thể liên lạc với máy chủ trò chơi. Hãy kiểm tra mạng và thử lại sau ít phút.').waitFor();
      await p.evaluate(() => window.__tqsE2e.emitUiError('internal socket diagnostics'));
      await p.getByRole('alert').getByText('Kết nối đến máy chủ bị gián đoạn. Hãy kiểm tra mạng và đăng nhập lại.').waitFor();
      assert.equal(await p.getByText('internal socket diagnostics').count(), 0);
      await p.goto('/e2e.html');
    }],
    ['Card, target and skill clicks update the Lua scene without sending', async (p) => {
      const id = await start(p, 'choices');
      await p.getByRole('button', { name: 'Sát', exact: true }).click();
      await p.getByRole('button', { name: 'Chọn mục tiêu' }).click();
      const choiceGeometry = await p.evaluate(() => {
        const dock = document.querySelector<HTMLElement>('.sg-inline-choice-dock')!;
        const skill = document.querySelector<HTMLElement>('.board-local-skill-rail')!;
        const hand = document.querySelector<HTMLElement>('.sg-hand-fan')!;
        const choice = dock.getBoundingClientRect();
        const rail = skill.getBoundingClientRect();
        const cards = hand.getBoundingClientRect();
        return { choice: { top: choice.top, bottom: choice.bottom },
          skill: { top: rail.top, bottom: rail.bottom },
          hand: { top: cards.top, bottom: cards.bottom } };
      });
      assert.ok(choiceGeometry.choice.bottom <= choiceGeometry.skill.top,
        `Special usage choices must clear the skill rail: ${JSON.stringify(choiceGeometry)}`);
      assert.ok(choiceGeometry.choice.bottom <= choiceGeometry.hand.top,
        `Special usage choices must clear card selection: ${JSON.stringify(choiceGeometry)}`);
      await p.getByRole('button', { name: 'longdan', exact: true }).click();
      await p.getByRole('button', { name: 'convert' }).click();
      await waitActions(p, 4);
      const s = await snapshot(p);
      assert.equal(s.requestId, id);
      assert.equal(s.replyCount, 0);
      assert.deepEqual(s.actions.map((a) => a[0]), ['CardItem', 'Photo', 'SkillButton', 'SpecialSkills']);
      assert.deepEqual(s.actions[0].slice(1), [7, 'click', { selected: true }]);
      assert.deepEqual(s.actions[1].slice(1), [2, 'click', { selected: true }]);
      assert.deepEqual(s.actions[2].slice(1), ['longdan', 'click', { selected: true, autoTarget: false }]);
      assert.equal(await p.getByRole('button', { name: 'Sát', exact: true }).getAttribute('aria-pressed'), 'true');
      assert.equal(await p.getByRole('button', { name: 'Đã chọn mục tiêu' }).getAttribute('aria-pressed'), 'true');
    }],
    ['Public suit and rank use matching red or black ink with a thin outline', async (p) => {
      await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.seedHorseEquipment(true));
      const styles = await p.evaluate(() => {
        // Test the full four-suit palette in the live stylesheet, even when the
        // current game fixture deals fewer than four suits.
        const swatches: HTMLElement[] = [];
        for (const suit of [1, 2, 3, 4]) {
          const mark = document.createElement('span');
          mark.className = `card-suit-ink ${suit <= 2 ? 'suit-black' : 'suit-red'}`;
          mark.textContent = ['♠A', '♣10', '♥Q', '♦K'][suit - 1];
          document.body.appendChild(mark);
          swatches.push(mark);
        }
        const marks = [...document.querySelectorAll<HTMLElement>('.sg-card-top-left, .native-eq-suit'), ...swatches];
        const result = marks.map((mark) => {
          const rank = mark.querySelector('.sg-card-rank');
          const suit = mark.querySelector('.sg-card-suit');
          return {
            className: mark.className,
            color: getComputedStyle(mark).color,
            background: getComputedStyle(mark).backgroundColor,
            border: getComputedStyle(mark).borderStyle,
            outlineWidth: getComputedStyle(mark).webkitTextStrokeWidth,
            outlineColor: getComputedStyle(mark).webkitTextStrokeColor,
            paintOrder: getComputedStyle(mark).paintOrder,
            expected: mark.classList.contains('suit-red') ? 'rgb(173, 24, 38)'
              : mark.classList.contains('suit-black') ? 'rgb(23, 23, 23)' : 'rgb(85, 81, 77)',
            rankColor: rank ? getComputedStyle(rank).color : null,
            suitColor: suit ? getComputedStyle(suit).color : null,
            rankOutline: rank ? getComputedStyle(rank).webkitTextStrokeWidth : null,
            suitOutline: suit ? getComputedStyle(suit).webkitTextStrokeWidth : null,
          };
        });
        swatches.forEach((mark) => mark.remove());
        return result;
      });
      assert.ok(styles.some((mark) => String(mark.className).includes('sg-card-top-left')),
        'hand cards must expose suit and rank');
      assert.ok(styles.some((mark) => String(mark.className).includes('native-eq-suit')),
        'equipped cards must expose suit and rank');
      for (const mark of styles) {
        if (mark.rankColor) assert.equal(mark.rankColor, mark.color, `rank ink differs from suit ink: ${JSON.stringify(mark)}`);
        if (mark.suitColor) assert.equal(mark.suitColor, mark.color, `suit ink differs from rank ink: ${JSON.stringify(mark)}`);
        assert.equal(mark.color, mark.expected, `wrong suit color: ${JSON.stringify(mark)}`);
        assert.equal(mark.background, 'rgba(0, 0, 0, 0)', `unexpected badge backing: ${JSON.stringify(mark)}`);
        assert.equal(mark.border, 'none', `unexpected badge border: ${JSON.stringify(mark)}`);
        assert.equal(mark.outlineWidth, '0.8px', `missing thin outline: ${JSON.stringify(mark)}`);
        assert.equal(mark.outlineColor, 'rgba(255, 245, 229, 0.96)', `wrong outline: ${JSON.stringify(mark)}`);
        assert.equal(mark.paintOrder, 'stroke', `outline must sit behind ink: ${JSON.stringify(mark)}`);
        if (mark.rankOutline) assert.equal(mark.rankOutline, mark.outlineWidth);
        if (mark.suitOutline) assert.equal(mark.suitOutline, mark.outlineWidth);
      }
    }],
    ['Idle-hand tooltips preserve each suit color on both symbol and rank', async (p) => {
      // The mobile layout deliberately hides hover tooltips; verify the real
      // desktop popover in an isolated tab, leaving other game scenes intact.
      const browser = p.context().browser();
      assert.ok(browser);
      const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
      try {
        const preview = await context.newPage();
        preview.setDefaultTimeout(8_000);
        await preview.goto(new URL('/e2e.html?idle-suit-preview=1', p.url()).href);
        const cards = preview.locator('.sg-idle-suit-preview .sg-card-idle');
        assert.equal(await cards.count(), 4);
        for (const [index, symbol, rank, expectedColor] of [
          [0, '♠', 'A', 'rgb(23, 23, 23)'],
          [1, '♣', '10', 'rgb(23, 23, 23)'],
          [2, '♥', 'Q', 'rgb(173, 24, 38)'],
          [3, '♦', 'K', 'rgb(173, 24, 38)'],
        ] as const) {
          await cards.nth(index).hover();
          const mark = preview.locator('.sg-card-popover-portal .card-suit-inline');
          await mark.waitFor();
          assert.equal(await mark.textContent(), `${symbol}${rank}`);
          assert.equal(await mark.evaluate((node) => getComputedStyle(node).color), expectedColor);
          assert.equal(await mark.evaluate((node) => getComputedStyle(node).backgroundColor), 'rgba(0, 0, 0, 0)');
          assert.equal(await mark.evaluate((node) => getComputedStyle(node).borderStyle), 'none');
          assert.equal(await mark.evaluate((node) => getComputedStyle(node).webkitTextStrokeWidth), '0.8px');
          if (index === 2 && process.env.TQS_EVIDENCE_DIR) {
            const evidenceDir = path.resolve(process.env.TQS_EVIDENCE_DIR);
            mkdirSync(evidenceDir, { recursive: true });
            await preview.screenshot({ path: path.join(evidenceDir, 'ui-idle-tooltip-1280x800-20261019.png') });
          }
          await preview.mouse.move(0, 0);
          await mark.waitFor({ state: 'detached' });
        }
      } finally {
        await context.close();
      }
    }],
    ['Long press opens card details without changing the Lua selection', async (p) => {
      const id = await start(p, 'choices');
      const card = p.getByRole('button', { name: 'Sát', exact: true });
      await card.dispatchEvent('pointerdown', { pointerType: 'touch', button: 0 });
      await p.waitForTimeout(650);
      await card.dispatchEvent('pointerup', { pointerType: 'touch', button: 0 });
      const dialog = p.getByRole('dialog', { name: 'Sát' });
      await dialog.waitFor();
      assert.equal((await snapshot(p)).actions.length, 0);
      assert.equal((await snapshot(p)).requestId, id);
      assert.match(await dialog.innerText(), /Trong giai đoạn ra bài/);
      const detailSuit = dialog.locator('.sg-sheet-suit');
      assert.equal(await detailSuit.evaluate((node) => getComputedStyle(node).backgroundColor), 'rgba(0, 0, 0, 0)');
      assert.equal(await detailSuit.evaluate((node) => getComputedStyle(node).webkitTextStrokeWidth), '0.8px');
      await p.keyboard.press('Escape');
      await p.waitForTimeout(20);
      assert.equal(await p.getByRole('dialog', { name: 'Sát' }).count(), 0);
      assert.equal((await snapshot(p)).actions.length, 0);
    }],
    ['Hidden-trigger dock prelights locally and stays through damage', async (p) => {
      await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.addFakeSkill());
      const skill = p.getByRole('button', { name: /hs__yiji: chưa prelight/ });
      await skill.waitFor();
      await skill.click();
      await p.waitForFunction(() => window.__tqsE2e.snapshot().fakeSkills.some((entry) =>
        entry.name === 'hs__yiji' && entry.prelighted));
      await p.evaluate(() => window.__tqsE2e.damageSelf());
      const s = await snapshot(p);
      assert.deepEqual(s.fakeSkills, [{ name: 'hs__yiji', prelighted: true, enabled: true }]);
      assert.deepEqual(s.actions.at(-1), ['PushRequest', 'prelight,hs__yiji,true']);
      assert.equal(await p.getByRole('button', { name: /hs__yiji: đang prelight/ }).getAttribute('aria-pressed'), 'true');
    }],
    ['Regular skills remain visible but cannot activate without a Lua SkillButton', async (p) => {
      const id = await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.addRegularSkill());
      const skill = p.getByRole('button', { name: 'hs__active', exact: true });
      await skill.waitFor();
      assert.equal(await skill.isDisabled(), true);
      assert.match(await p.evaluate((n) => window.__tqsE2e.attemptSkill(n), id) ?? '', /không được Lua cho phép|không hợp lệ|không còn hiệu lực/);
      assert.deepEqual((await snapshot(p)).regularSkills, [{ name: 'hs__active' }]);
    }],
    ['Skill information is inspectable without dispatching gameplay or prelight', async (p) => {
      await p.setViewportSize({ width: 390, height: 844 });
      await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.addFakeSkill());
      await p.evaluate(() => window.__tqsE2e.addRegularSkill());
      const previous = await snapshot(p);
      const info = p.locator('.board-local-skill-rail .fake-skill-dock .sg-skill-info-trigger');
      await info.click();
      const dialog = p.getByRole('dialog', { name: 'Thông tin kỹ năng' });
      await dialog.waitFor();
      assert.match(await dialog.innerText(), /Di Kế|hs__yiji|Mô tả kỹ năng chưa được nạp/);
      assert.deepEqual((await snapshot(p)).actions, previous.actions);
      assert.deepEqual((await snapshot(p)).sent, previous.sent);
      assert.deepEqual((await snapshot(p)).fakeSkills, previous.fakeSkills);
      await p.keyboard.press('Escape');
      await dialog.waitFor({ state: 'hidden' });
      assert.equal(await info.evaluate((button) => document.activeElement === button), true,
        'inspector must restore focus to its trigger');

      // The touch-style long press must inspect the skill without invoking
      // its gameplay/prelight action when the browser synthesizes a click.
      const fakeSkill = p.locator('.board-local-skill-rail .fake-skill-dock .fake-skill-button');
      const box = await fakeSkill.boundingBox();
      assert.ok(box, 'fake skill button must be visible for long-press test');
      await p.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await p.mouse.down();
      await p.waitForTimeout(430);
      await dialog.waitFor();
      await p.mouse.up();
      assert.deepEqual((await snapshot(p)).actions, previous.actions);
      assert.deepEqual((await snapshot(p)).sent, previous.sent);
      assert.deepEqual((await snapshot(p)).fakeSkills, previous.fakeSkills);
      await p.getByRole('button', { name: 'Đóng thông tin kỹ năng' }).click();
      await dialog.waitFor({ state: 'hidden' });

      await p.evaluate(() => window.__tqsE2e.cancel());
      const regular = p.locator('.board-local-skill-rail .regular-skill-dock .sg-skill-info-trigger');
      await regular.click();
      await dialog.waitFor();
      assert.match(await dialog.innerText(), /hs__active|Mô tả kỹ năng chưa được nạp/);
      assert.deepEqual((await snapshot(p)).actions, previous.actions);
      assert.deepEqual((await snapshot(p)).sent, previous.sent);
      await p.getByRole('button', { name: 'Đóng thông tin kỹ năng' }).click();
      await dialog.waitFor({ state: 'hidden' });
    }],
    ['Skills from fake, regular and Lua docks remain horizontal and scroll when crowded', async (p) => {
      for (const viewport of [{ width: 320, height: 568 }, { width: 390, height: 844 },
        { width: 844, height: 390 }, { width: 1280, height: 800 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        await p.evaluate(() => window.__tqsE2e.addFakeSkill());
        await p.locator('.board-local-skill-rail .fake-skill-button').waitFor();
        await p.evaluate(() => window.__tqsE2e.addRegularSkill());
        // Request-in-progress uses GameplaySkillDock, including disabled
        // regular skills; idle uses RegularSkillDock. Test both real states.
        await p.locator('.board-local-skill-rail .gameplay-skill-dock .sg-skill-button').first().waitFor();
        await assertCrowdedSkillRail(p, '.gameplay-skill-dock .sg-skill-button', viewport);
        await p.evaluate(() => window.__tqsE2e.cancel());
        await p.locator('.board-local-skill-rail .regular-skill-button').waitFor();
        assert.equal(await p.locator('.board-local-skill-rail .fake-skill-button').count(), 1);
        await assertCrowdedSkillRail(p, '.regular-skill-dock .regular-skill-button', viewport);
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Waiting message occupies the table corner; desktop equipment has its own column', async (p) => {
      const evidenceDir = process.env.TQS_EVIDENCE_DIR ? path.resolve(process.env.TQS_EVIDENCE_DIR) : null;
      if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });
      for (const viewport of [{ width: 1280, height: 800 }, { width: 844, height: 390 },
        { width: 390, height: 844 }, { width: 320, height: 568 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        if (viewport.width === 1280) {
          await p.locator('.board-local-self-equipment .native-equip-plate').waitFor({ state: 'attached' });
          assert.equal(await p.locator('.board-local-self-equipment .native-equip-row, .board-local-self-equipment .native-equip-half').count(), 5);
          assert.equal(await p.locator('.board-local-seat .native-equip-plate').count(), 0);
          const equipment = await p.evaluate(() => {
            const seat = document.querySelector('.board-local-seat')!.getBoundingClientRect();
            const plate = document.querySelector('.board-local-self-equipment .native-equip-plate')!.getBoundingClientRect();
            return { seatRight: seat.right, plateLeft: plate.left, plateRight: plate.right,
              seatTop: seat.top, seatBottom: seat.bottom, plateTop: plate.top, plateBottom: plate.bottom,
              width: plate.width, height: plate.height };
          });
          assert.ok(equipment.plateLeft >= equipment.seatRight - 1 && equipment.width >= 110 &&
            equipment.height >= 80, `desktop equipment must clear the avatar: ${JSON.stringify(equipment)}`);
          assert.ok(Math.abs(equipment.plateTop - equipment.seatTop) <= 1 &&
            Math.abs(equipment.plateBottom - equipment.seatBottom) <= 1,
          `desktop equipment must align with the avatar: ${JSON.stringify(equipment)}`);
        } else {
          await p.locator('.board-local-seat .native-equip-plate').waitFor();
          assert.equal(await p.locator('.board-local-self-equipment .native-equip-plate').count(), 0);
        }
        const actionHit = await p.evaluate(() => {
          const button = document.querySelector<HTMLElement>('.sg-btn-ok')!;
          const choice = document.querySelector<HTMLElement>('.sg-inline-choice-dock')!;
          const hud = document.querySelector<HTMLElement>('.sg-floating-controls-hud')!;
          const r = button.getBoundingClientRect();
          const point = { x: r.left + r.width / 2, y: r.top + r.height / 2 };
          const hit = document.elementFromPoint(point.x, point.y);
          return { point, button: r.toJSON(), choice: choice.getBoundingClientRect().toJSON(),
            hud: hud.getBoundingClientRect().toJSON(), hit: hit?.className ?? '' };
        });
        assert.ok(/sg-btn-ok/.test(String(actionHit.hit)),
          `OK button is obstructed at ${viewport.width}x${viewport.height}: ${JSON.stringify(actionHit)}`);
        await p.getByRole('button', { name: 'Xác nhận' }).click();
        await waitReplies(p, 1);
        const placement = await p.evaluate(() => {
          const table = document.querySelector('.sg-board-table')!.getBoundingClientRect();
          const status = document.querySelector<HTMLElement>('.board-table-status')!;
          const r = status.getBoundingClientRect();
          const opponentRects = [...document.querySelectorAll<HTMLElement>('.board-opponents .sg-photo-panel')]
            .map((el) => el.getBoundingClientRect());
          const opponentsCovered = opponentRects.some((op) =>
            Math.max(0, Math.min(r.right, op.right) - Math.max(r.left, op.left)) > 0.5 &&
            Math.max(0, Math.min(r.bottom, op.bottom) - Math.max(r.top, op.top)) > 0.5);
          return { tableLeft: table.left, tableTop: table.top, tableRight: table.right,
            statusLeft: r.left, statusTop: r.top, statusRight: r.right,
            statusBottom: r.bottom, opponentsCovered,
            pointerEvents: getComputedStyle(status).pointerEvents,
            parent: status.parentElement?.className ?? '' };
        });
        assert.match(placement.parent, /sg-board-table/);
        assert.equal(placement.pointerEvents, 'none');
        assert.ok(placement.statusLeft >= placement.tableLeft - 1 &&
          placement.statusRight <= placement.tableRight + 1 &&
          placement.statusTop >= placement.tableTop - 1 &&
          placement.statusTop <= placement.tableTop + 20,
        `waiting notice must stay at table's upper-left corner: ${JSON.stringify(placement)}`);
        assert.equal(placement.opponentsCovered, false,
          `waiting notice must not cover an opponent at ${viewport.width}x${viewport.height}: ${JSON.stringify(placement)}`);
        if (evidenceDir) await p.screenshot({ path: path.join(evidenceDir,
          `ui-rail-equipment-idle-${viewport.width}x${viewport.height}-20261019.png`) });
      }
    }],
    ['Horse +1/-1 slots stay inside their equipment plate on portrait, landscape and desktop', async (p) => {
      const evidenceDir = process.env.TQS_EVIDENCE_DIR ? path.resolve(process.env.TQS_EVIDENCE_DIR) : null;
      if (evidenceDir) mkdirSync(evidenceDir, { recursive: true });
      try {
        for (const viewport of [{ width: 320, height: 568 }, { width: 390, height: 844 },
          { width: 844, height: 390 }, { width: 1280, height: 800 }]) {
          await p.setViewportSize(viewport);
          for (const equipped of [false, true]) {
            await start(p, 'choices');
            await p.evaluate((filled) => window.__tqsE2e.seedHorseEquipment(filled), equipped);
            const desktop = viewport.width >= 900 && viewport.height >= 521;
            // The desktop equipment column is populated by a React portal after
            // the media query updates. Wait for that move to finish before
            // comparing geometry, including when rotating back to mobile.
            await p.waitForFunction((expectDesktop) => {
              const inSeat = document.querySelector('.board-local-seat .native-equip-plate');
              const inColumn = document.querySelector('.board-local-self-equipment .native-equip-plate');
              return expectDesktop ? !!inColumn && !inSeat : !!inSeat && !inColumn;
            }, desktop);
            const metrics = await p.evaluate(() => {
            const plates = [...document.querySelectorAll<HTMLElement>(
              '.board-local-seat .native-equip-plate, .board-local-self-equipment .native-equip-plate, .board-opponents .native-equip-plate',
            )];
            return plates.map((plate) => {
              const rect = plate.getBoundingClientRect();
              const halves = [...plate.querySelectorAll<HTMLElement>('.native-equip-half')];
              const cells = [...plate.querySelectorAll<HTMLElement>('.native-equip-row, .native-equip-half')];
              const cellBoxes = cells.map((cell) => cell.getBoundingClientRect());
              const rideBoxes = halves.map((half) => half.getBoundingClientRect());
              return {
                compact: plate.classList.contains('native-equip-plate-compact'),
                desktop: !!plate.closest('.board-local-self-equipment'),
                plate: rect.toJSON(),
                scrollWidth: plate.scrollWidth, clientWidth: plate.clientWidth,
                cells: cells.length,
                rideBoxes: rideBoxes.map((r) => r.toJSON()),
                ridesContained: rideBoxes.every((r) => r.width > 5 && r.height > 5 &&
                  r.left >= rect.left - 1 && r.right <= rect.right + 1 &&
                  r.top >= rect.top - 1 && r.bottom <= rect.bottom + 1),
                ridesDisjoint: rideBoxes.length === 2 &&
                  !(rideBoxes[0].left < rideBoxes[1].right - 1 && rideBoxes[1].left < rideBoxes[0].right - 1 &&
                    rideBoxes[0].top < rideBoxes[1].bottom - 1 && rideBoxes[1].top < rideBoxes[0].bottom - 1),
                compactCellsAligned: cellBoxes.every((r) => r.width > 5 &&
                  r.left >= rect.left - 1 && r.right <= rect.right + 1 &&
                  Math.abs(r.top - cellBoxes[0].top) <= 1 && Math.abs(r.height - cellBoxes[0].height) <= 1),
                desktopRowsAligned: cellBoxes.every((r, i) =>
                  r.width > 0 && r.height > 0 && r.left >= rect.left - 1 && r.right <= rect.right + 1 &&
                  r.top >= rect.top - 1 && r.bottom <= rect.bottom + 1 &&
                  (i === 0 || r.top >= cellBoxes[i - 1].bottom - 1)),
                horseNames: halves.map((half) => half.querySelector('.native-eq-name')?.textContent?.trim()),
                horseSuits: halves.map((half) => !!half.querySelector('.native-eq-suit')),
                horseParts: halves.map((half) => ({
                  slot: half.getBoundingClientRect().toJSON(),
                  children: [...half.querySelectorAll<HTMLElement>('.native-eq-icon, .native-eq-name, .native-eq-suit')]
                    .map((part) => ({ className: part.className, text: part.textContent?.trim(),
                      rect: part.getBoundingClientRect().toJSON() })),
                })),
                visibleHorsePartsContained: halves.every((half) => {
                  const slot = half.getBoundingClientRect();
                  return [...half.querySelectorAll<HTMLElement>('.native-eq-icon, .native-eq-name, .native-eq-suit')]
                    .every((part) => {
                      const r = part.getBoundingClientRect();
                      return r.width > 0 && r.height > 0 && r.left >= slot.left - 1 &&
                        r.right <= slot.right + 1 && r.top >= slot.top - 1 && r.bottom <= slot.bottom + 1;
                    });
                }),
              };
            });
          });
            assert.ok(metrics.length >= 2, `horse equipment fixture missing: ${JSON.stringify(metrics)}`);
            for (const plate of metrics) {
              const info = `${viewport.width}x${viewport.height} (equipped=${equipped}): ${JSON.stringify(plate)}`;
              assert.equal(plate.cells, 5, `five equipment slots should mount at ${info}`);
              assert.ok(plate.ridesContained && plate.ridesDisjoint, `+1/-1 horses overlap or escape at ${info}`);
              assert.ok(plate.scrollWidth <= plate.clientWidth + 1, `equipment content overflows at ${info}`);
              if (plate.compact && !plate.desktop) {
                assert.ok(plate.compactCellsAligned, `+1/-1 horses must share the mobile five-cell row at ${info}`);
              }
              if (plate.desktop) {
                assert.ok(plate.desktopRowsAligned, `desktop equipment slots must form five distinct rows at ${info}`);
              }
              assert.ok(plate.horseNames.every(Boolean), `horse labels missing at ${info}`);
              assert.deepEqual(plate.horseSuits, [equipped, equipped], `horse suit/rank missing at ${info}`);
              assert.ok(plate.visibleHorsePartsContained, `horse icon, name or suit/rank escapes slot at ${info}`);
              if (equipped) {
                assert.deepEqual(plate.horseNames, ['Trảo Hoàng Phi Điện', 'Xích Thố'],
                  `equipped horses must show their translated names at ${info}`);
              } else {
                assert.deepEqual(plate.horseNames, ['+1', '-1'], `empty horse labels changed at ${info}`);
              }
            }
            if (evidenceDir && equipped) {
              await p.screenshot({ path: path.join(evidenceDir,
                `ui-horses-equipped-${viewport.width}x${viewport.height}-20261019.png`) });
            }
          }
        }
      } finally {
        await p.setViewportSize({ width: 390, height: 844 });
      }
    }],
    ['Desktop board columns, self seat and skill rail stay fixed across requests and log toggles', async (p) => {
      await p.setViewportSize({ width: 1280, height: 800 });
      await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.addRegularSkill());
      const geometry = () => p.evaluate(() => {
        const board = document.querySelector<HTMLElement>('.board-layout')!.getBoundingClientRect();
        const main = document.querySelector<HTMLElement>('.board-main')!.getBoundingClientRect();
        const seat = document.querySelector<HTMLElement>('.board-local-seat')!.getBoundingClientRect();
        const rail = document.querySelector<HTMLElement>('.board-local-skill-rail')!.getBoundingClientRect();
        const dashboard = document.querySelector<HTMLElement>('.board-local-dashboard')!.getBoundingClientRect();
        return {
          board: { left: board.left, top: board.top, width: board.width, height: board.height },
          main: { left: main.left, top: main.top, width: main.width, height: main.height },
          seat: { left: seat.left, top: seat.top, width: seat.width, height: seat.height },
          rail: { left: rail.left, top: rail.top, width: rail.width, height: rail.height },
          dashboard: { left: dashboard.left, top: dashboard.top, width: dashboard.width, height: dashboard.height },
          columns: getComputedStyle(document.querySelector('.board-layout')!).gridTemplateColumns,
        };
      });
      const baseline = await geometry();
      assert.equal(await p.locator('.board-local-seat .sg-photo-panel-compact').count(), 1,
        'desktop self seat must use the compact landscape equipment layout');
      assert.ok(baseline.rail.height > 0 && baseline.rail.height <= 29);
      await p.getByRole('button', { name: 'Lịch sử', exact: true }).click();
      const expanded = await geometry();
      await p.getByRole('button', { name: 'Ẩn lịch sử', exact: true }).click();
      const collapsed = await geometry();
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      await p.getByRole('status').getByText('Đang cập nhật diễn biến ván đấu…').waitFor();
      const idle = await geometry();
      for (const [stage, current] of [['logs open', expanded], ['logs closed', collapsed],
        ['waiting for server', idle]] as const) {
        assert.equal(current.columns, baseline.columns, `${stage}: desktop column tracks shifted`);
        for (const key of ['main', 'seat', 'rail', 'dashboard'] as const) {
          for (const dimension of ['left', 'top', 'width', 'height'] as const) {
            assert.ok(Math.abs(current[key][dimension] - baseline[key][dimension]) <= 1.5,
              `${stage}: ${key}.${dimension} changed: ${JSON.stringify({ baseline, current })}`);
          }
        }
      }
      assert.equal(await p.locator('.board-local-skill-rail .regular-skill-button').count(), 1,
        'regular skills must remain in the same rail while the server is updating');
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Choice dock stays bounded and hand selection never opens a tooltip', async (p) => {
      for (const viewport of [
        { width: 390, height: 844 }, { width: 844, height: 390 }, { width: 1280, height: 800 },
      ]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        const card = p.getByRole('button', { name: 'Sát', exact: true });
        await card.hover();
        assert.equal(await p.locator('.sg-card-popover-portal').count(), 0,
          'hovering a playable card should not show its description over the controls');
        await card.focus();
        assert.equal(await p.locator('.sg-card-popover-portal').count(), 0,
          'keyboard focus on a playable card should not open its tooltip');
        const geometry = await p.evaluate(() => {
          const dock = document.querySelector<HTMLElement>('.sg-inline-choice-dock')!.getBoundingClientRect();
          const skill = document.querySelector<HTMLElement>('.board-local-skill-rail')!.getBoundingClientRect();
          const hand = document.querySelector<HTMLElement>('.sg-hand-fan')!.getBoundingClientRect();
          return { dock: { left: dock.left, right: dock.right, top: dock.top, bottom: dock.bottom },
            skillTop: skill.top, handTop: hand.top, handBottom: hand.bottom,
            documentWidth: document.documentElement.scrollWidth };
        });
        assert.ok(geometry.dock.left >= -1 && geometry.dock.right <= viewport.width + 1 &&
          geometry.dock.top >= -1 && geometry.dock.bottom <= viewport.height + 1,
        `choice dock escapes ${viewport.width}x${viewport.height}: ${JSON.stringify(geometry)}`);
        assert.ok(geometry.dock.bottom <= geometry.skillTop + 1 &&
          geometry.dock.bottom <= geometry.handTop + 1,
        `choice dock overlaps cards/skills at ${viewport.width}x${viewport.height}: ${JSON.stringify(geometry)}`);
        assert.ok(geometry.documentWidth <= viewport.width + 1);
        await card.click();
        assert.equal(await card.getAttribute('aria-pressed'), 'true');
        assert.equal(await p.locator('.sg-card-popover-portal').count(), 0,
          'selecting a card should not leave a popup requiring dismissal');
        await p.getByRole('button', { name: 'Xem chi tiết Sát' }).click();
        await p.getByRole('dialog', { name: 'Sát' }).waitFor();
        await p.keyboard.press('Escape');
        assert.equal(await p.getByRole('dialog', { name: 'Sát' }).count(), 0);
        assert.equal(await card.getAttribute('aria-pressed'), 'true',
          'inspection should not change the Lua card selection');
        await card.click();
        assert.equal(await card.getAttribute('aria-pressed'), 'false', 'a second click should deselect');
        await card.click();
        await p.getByRole('button', { name: 'Xác nhận' }).click();
        await waitReplies(p, 1);
        assert.equal((await snapshot(p)).actions.filter((action) => action[0] === 'CardItem').length, 3);
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Touch taps select and confirm cards without sticky tooltip or modal', async (p) => {
      const browser = p.context().browser();
      assert.ok(browser);
      const context = await browser.newContext({
        viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true,
      });
      try {
        const touchPage = await context.newPage();
        touchPage.setDefaultTimeout(8_000);
        await touchPage.goto(p.url());
        const tap = async (locator: Locator) => {
          await locator.scrollIntoViewIfNeeded();
          const bounds = await locator.boundingBox();
          assert.ok(bounds);
          await touchPage.touchscreen.tap(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
        };
        for (const { viewport, action, nativeId } of [
          { viewport: { width: 390, height: 844 }, action: 'Xác nhận', nativeId: 'OK' },
          { viewport: { width: 844, height: 390 }, action: 'Hủy', nativeId: 'Cancel' },
        ]) {
          await touchPage.setViewportSize(viewport);
          await start(touchPage, 'choices');
          const card = touchPage.getByRole('button', { name: 'Sát', exact: true });
          await tap(card);
          assert.equal(await card.getAttribute('aria-pressed'), 'true');
          assert.equal(await touchPage.locator('.sg-card-popover-portal, .sg-card-modal-backdrop').count(), 0);
          await tap(touchPage.getByRole('button', { name: action, exact: true }));
          await waitReplies(touchPage, 1);
          assert.deepEqual((await snapshot(touchPage)).actions.slice(0, 2), [
            ['CardItem', 7, 'click', { selected: true }],
            ['Button', nativeId, 'click', {}],
          ]);
        }
      } finally {
        await context.close();
      }
    }],
    ['Keyboard selection and confirmation do not raise a card tooltip', async (p) => {
      await start(p, 'choices');
      const card = p.getByRole('button', { name: 'Sát', exact: true });
      await card.focus();
      await p.keyboard.press('Enter');
      assert.equal(await card.getAttribute('aria-pressed'), 'true');
      await p.keyboard.press('Space');
      assert.equal(await card.getAttribute('aria-pressed'), 'false');
      await p.keyboard.press('Enter');
      assert.equal(await card.getAttribute('aria-pressed'), 'true');
      assert.equal(await p.locator('.sg-card-popover-portal').count(), 0);
      const ok = p.getByRole('button', { name: 'Xác nhận' });
      await ok.focus();
      await p.keyboard.press('Enter');
      await waitReplies(p, 1);
      assert.equal((await snapshot(p)).actions.filter((action) => action[0] === 'CardItem').length, 3);
    }],
    ['OK replies with exactly one CBOR packet generated by Lua', async (p) => {
      const id = await start(p, 'choices');
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      const s = await snapshot(p);
      assert.equal(s.requestId, null);
      assert.equal(s.sent.length, 1);
      assert.deepEqual(s.sent[0], { requestId: id, type: 0x212, hex: '44646f6e65' });
      assert.match(await p.getByRole('status').last().innerText(), /Đang cập nhật diễn biến ván đấu/);
      await p.waitForTimeout(80);
      assert.equal((await snapshot(p)).replyCount, 1);
    }],
    ['Cancel and End each dispatch the correct Lua Button', async (p) => {
      for (const [label, buttonId] of [['Hủy', 'Cancel'], ['Kết thúc lượt', 'End']]) {
        await start(p, 'choices');
        await p.getByRole('button', { name: label, exact: true }).click();
        await waitReplies(p, 1);
        const s = await snapshot(p);
        assert.deepEqual(s.actions[0], ['Button', buttonId, 'click', {}]);
        assert.equal(s.replyCount, 1);
      }
    }],
    ['Combo, spin, checkbox, expand and optionbox render and dispatch', async (p) => {
      await start(p, 'widgets');
      await p.getByRole('combobox', { name: 'Chọn phương án' }).selectOption('b');
      await p.getByRole('spinbutton', { name: 'Giá trị' }).fill('3');
      await p.getByRole('button', { name: 'x', exact: true }).click();
      await p.locator('button[data-option-id="9"]').click();
      await p.getByRole('button', { name: 'right', exact: true }).click();
      await waitActions(p, 5);
      const s = await snapshot(p);
      assert.deepEqual(s.actions, [
        ['Interaction', 'combo', 'update', 'b'],
        ['Interaction', 'spin', 'update', 3],
        ['Interaction', 'checkbox', 'update', ['x']],
        ['Interaction', 'expand', 'update', 9],
        ['Interaction', 'option', 'update', 'right'],
      ]);
      assert.equal(s.replyCount, 0);
    }],
    ['Direct finish keeps request when Lua advances with same interaction spec', async (p) => {
      const id = await start(p, 'direct-step');
      await p.getByRole('button', { name: 'first' }).click();
      await p.getByText('Bước 2').waitFor();
      const halfway = await snapshot(p);
      assert.equal(halfway.requestId, id);
      assert.equal(halfway.replyCount, 0);
      assert.deepEqual(halfway.actions, [['Interaction', 'dialog', 'finish', 'first']]);
      assert.equal(await p.getByRole('button', { name: 'first' }).isEnabled(), true);
      await p.getByRole('button', { name: 'first' }).click();
      await waitReplies(p, 1);
      const done = await snapshot(p);
      assert.equal(done.requestId, null);
      assert.deepEqual(done.actions.map((a) => a[0]), ['Interaction', 'Interaction', 'Button']);
      assert.equal(done.sent.length, 1);
      assert.deepEqual(done.sent[0], { requestId: id, type: 0x212, hex: '44646f6e65' });
    }],
    ['Direct complete auto-clicks only Lua-enabled OK', async (p) => {
      await start(p, 'direct-complete');
      await p.getByRole('button', { name: 'first' }).click();
      await waitReplies(p, 1);
      const s = await snapshot(p);
      assert.deepEqual(s.actions.map((a) => a[0]), ['Interaction', 'Button']);
      assert.equal(s.requestId, null);
    }],
    ['Without ReplyToServer, finish plus OK keeps the request', async (p) => {
      const id = await start(p, 'direct-pending');
      await p.getByRole('button', { name: 'first' }).click();
      await waitActions(p, 2);
      const halfway = await snapshot(p);
      assert.equal(halfway.requestId, id);
      assert.equal(halfway.replyCount, 0);
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      assert.equal((await snapshot(p)).requestId, null);
    }],
    ['Dynamic ToBeDecided widget uses valid expand and direct payload', async (p) => {
      await start(p, 'dynamic');
      await p.getByRole('button', { name: 'Ảo' }).click();
      await waitActions(p, 1);
      assert.deepEqual((await snapshot(p)).actions[0], ['Interaction', 'dialog', 'update',
        { elemType: 'ExpandItem', cid: -7, name: 'virtual', autoTarget: false }]);
      await p.getByRole('button', { name: 'use' }).click();
      await waitReplies(p, 1);
      assert.deepEqual((await snapshot(p)).actions[1], ['Interaction', 'dialog', 'finish',
        { option: 'use', autoTarget: false }]);
    }],
    ['Lua CancelRequest invalidates UI and old actions', async (p) => {
      const id = await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.cancel());
      await p.getByText('Đang cập nhật diễn biến ván đấu…').waitFor();
      assert.equal((await snapshot(p)).requestId, null);
      const error = await p.evaluate((n) => window.__tqsE2e.attempt(n), id);
      assert.match(error ?? '', /không còn hiệu lực/);
      assert.equal((await snapshot(p)).replyCount, 0);
    }],
    ['Replacement request rejects stale ID and only replies to current ID', async (p) => {
      const old = await start(p, 'choices');
      const current = await p.evaluate(() => window.__tqsE2e.replace());
      assert.equal(current, undefined);
      const next = (await snapshot(p)).requestId;
      assert.ok(next && next !== old);
      assert.match(await p.evaluate((n) => window.__tqsE2e.attempt(n), old) ?? '', /không còn hiệu lực/);
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      assert.equal((await snapshot(p)).sent[0].requestId, next);
    }],
    ['Expired request disables both choices and player targets', async (p) => {
      const id = await start(p, 'choices', true);
      assert.equal(await p.getByRole('button', { name: 'Sát', exact: true }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Chọn mục tiêu' }).isDisabled(), true);
      assert.equal(await p.getByRole('button', { name: 'Xác nhận' }).isDisabled(), true);
      assert.match(await p.getByText('Yêu cầu đã hết thời gian.').innerText(), /hết thời gian/);
      assert.match(await p.evaluate((n) => window.__tqsE2e.attempt(n), id) ?? '', /hết thời gian/);
      assert.equal((await snapshot(p)).replyCount, 0);
    }],
    ['Reconnect ignores old socket even when request IDs are reused', async (p) => {
      const id = await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.reconnectSameId());
      await p.evaluate(() => window.__tqsE2e.oldSocketRequest());
      assert.equal((await snapshot(p)).requestId, id);
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      assert.equal((await snapshot(p)).sent[0].requestId, id);
      assert.equal((await snapshot(p)).replyCount, 1);
    }],
    ['Disconnect clears request and blocks any reply', async (p) => {
      const id = await start(p, 'choices');
      await p.evaluate(() => window.__tqsE2e.disconnect());
      assert.equal((await snapshot(p)).status, 'closed');
      assert.equal((await snapshot(p)).requestId, null);
      assert.match(await p.evaluate((n) => window.__tqsE2e.attempt(n), id) ?? '', /không còn hiệu lực/);
      assert.equal((await snapshot(p)).replyCount, 0);
    }],
    ['Lua error appears in UI, clears request and sends no packet', async (p) => {
      await start(p, 'lua-error');
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await p.getByRole('alert').getByText('Lỗi Lua mô phỏng').waitFor();
      const s = await snapshot(p);
      assert.equal(s.requestId, null);
      assert.equal(s.replyCount, 0);
    }],
    ['Repeated OK cannot emit a duplicate CBOR reply', async (p) => {
      const id = await start(p, 'choices');
      await p.getByRole('button', { name: 'Xác nhận' }).click();
      await waitReplies(p, 1);
      assert.match(await p.evaluate((n) => window.__tqsE2e.attempt(n), id) ?? '', /không còn hiệu lực/);
      assert.equal((await snapshot(p)).replyCount, 1);
    }],
    ['App protects a running match from leaving and reload, with BOT alternative', async (p) => {
      await p.goto('/e2e.html?app=1');
      await p.getByRole('heading', { name: 'Cổng Doanh Trại', exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.begin('choices'));
      await p.getByRole('heading', { name: 'E2E cục bộ', exact: true }).waitFor();
      const baseline = await p.evaluate(() => window.__tqsE2e.appActions());
      await p.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
      await p.getByRole('button', { name: 'Rời trận', exact: true }).click();
      await p.getByRole('alertdialog').waitFor();
      if (process.env.TQS_E2E_EVIDENCE_DIR) {
        const evidence = path.resolve(process.env.TQS_E2E_EVIDENCE_DIR);
        mkdirSync(evidence, { recursive: true });
        await p.screenshot({ path: path.join(evidence, 'temp-ban-exit-guard-2026-10-11.png') });
      }
      assert.deepEqual(await p.evaluate(() => window.__tqsE2e.appActions()), baseline);
      await p.getByRole('button', { name: 'Tiếp tục ván', exact: true }).click();
      assert.equal(await p.getByRole('alertdialog').count(), 0);
      await p.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
      await p.getByRole('button', { name: 'Rời trận', exact: true }).click();
      await p.getByRole('alertdialog').waitFor();
      assert.deepEqual(await p.evaluate(() => window.__tqsE2e.appActions()), baseline);
      await p.getByRole('alertdialog').getByRole('button', { name: 'BOT chơi hộ', exact: true }).click();
      await p.waitForFunction(() => window.__tqsE2e.appActions().at(-1) === 'Trust');
      assert.equal(await p.getByRole('alertdialog').count(), 0);
      assert.equal(await p.evaluate(() => {
        const event = new Event('beforeunload', { cancelable: true });
        window.dispatchEvent(event);
        return event.defaultPrevented;
      }), true);
      await p.getByRole('timer', { name: /Còn \d+ giây/ }).waitFor();
      await p.getByRole('button', { name: 'Tùy chọn trận đấu' }).click();
      await p.getByRole('button', { name: 'Rời trận', exact: true }).click();
      await p.getByRole('button', { name: 'Vẫn rời trận', exact: true }).click();
      await p.waitForFunction(() => window.__tqsE2e.appActions().at(-1) === 'QuitRoom');
      await p.evaluate(() => window.__tqsE2e.finishGame());
      await p.getByRole('heading', { name: 'Bạn đã thắng!', exact: true }).waitFor();
      assert.equal(await p.evaluate(() => {
        const event = new Event('beforeunload', { cancelable: true });
        window.dispatchEvent(event);
        return event.defaultPrevented;
      }), false);
      await p.evaluate(() => window.__tqsE2e.returnLobby());
      await p.getByRole('button', { name: 'Chi tiết kết nối', exact: true }).click();
      await p.getByRole('button', { name: 'Ngắt kết nối', exact: true }).click();
      await p.getByRole('heading', { name: 'Cổng Doanh Trại', exact: true }).waitFor();
      assert.equal(await p.getByRole('alertdialog').count(), 0);
      assert.equal((await p.evaluate(() => window.__tqsE2e.appActions())).at(-1), 'disconnect');
      await p.goto('/e2e.html');
    }],
    ['Shared status footer fits phones and update guard defers until GameOver', async (p) => {
      await p.route('**/gateway/healthz?*', route => route.fulfill({ status: 200, body: 'ok' }));
      await p.goto('/e2e.html?app=1');
      await p.getByRole('button', { name: 'Chi tiết kết nối', exact: true }).waitFor();
      for (const viewport of [{width:320,height:568},{width:390,height:844},{width:844,height:390},{width:1280,height:800}]) {
        await p.setViewportSize(viewport);
        assert.equal(await p.locator('.tqs-status-footer').count(), 1);
        const boxes = await p.locator('.tqs-status-footer button').evaluateAll(buttons => buttons.map(button => {
          const r=button.getBoundingClientRect(); return {left:r.left,right:r.right,bottom:r.bottom};
        }));
        assert.ok(boxes[0].left >= 0 && boxes[0].right <= boxes[1].left && boxes[1].right <= viewport.width);
        assert.ok(boxes.every(b => b.bottom <= viewport.height));
      }
      await p.setViewportSize({width:390,height:844});
      const systemEvidence = path.resolve(root, '../../scratch/evidence/status-updates');
      mkdirSync(systemEvidence, {recursive:true});
      await p.screenshot({path:path.join(systemEvidence,'login-footer.png')});
      await p.getByRole('button', {name:'Chi tiết kết nối',exact:true}).click();
      await p.getByRole('dialog',{name:'Chi tiết kết nối',exact:true}).waitFor();
      await p.getByRole('button',{name:'Đo lại tín hiệu',exact:true}).waitFor();
      await p.screenshot({path:path.join(systemEvidence,'connection-dialog.png')});
      await p.keyboard.press('Escape');
      await p.getByRole('button',{name:'Thông tin phiên bản',exact:true}).click();
      await p.getByRole('dialog',{name:'Thông tin Phiên bản & Đồng bộ Hệ thống',exact:true}).waitFor();
      await p.keyboard.press('Escape');
      await p.evaluate(() => window.__tqsE2e.begin('choices'));
      const baseline = await p.evaluate(() => window.__tqsE2e.appActions());
      await p.evaluate(() => window.__tqsE2e.systemPending(true));
      await p.getByText('● Có bản mới · Cập nhật sau khi kết thúc ván',{exact:true}).waitFor();
      assert.equal(await p.getByRole('dialog').count(),0);
      assert.deepEqual(await p.evaluate(() => window.__tqsE2e.appActions()), baseline);
      await p.evaluate(() => window.__tqsE2e.finishGame());
      await p.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true}).waitFor();
      await p.screenshot({path:path.join(systemEvidence,'force-update-after-gameover.png')});
      await p.keyboard.press('Escape');
      assert.equal(await p.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true}).count(),1);
      await p.evaluate(() => window.__tqsE2e.systemPending(false));
      await p.unroute('**/gateway/healthz?*');
      await p.goto('/e2e.html');
    }],
    ['A second game in the same session starts without the previous game projection', async (p) => {
      await p.goto('/e2e.html?app=1');
      await p.getByRole('heading', { name: 'Cổng Doanh Trại', exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.begin('choices'));
      await p.getByRole('heading', { name: 'E2E cục bộ', exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.seedRoundData());
      await p.getByRole('button', { name: 'Lịch sử', exact: true }).click();
      await p.getByRole('region', { name: 'Nhật ký trận đấu' })
        .getByText('Thông báo ván trước', { exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.finishGame());
      await p.getByRole('heading', { name: 'Bạn đã thắng!', exact: true }).waitFor();
      await p.evaluate(() => window.__tqsE2e.startNextGame());
      await p.getByRole('heading', { name: 'E2E cục bộ', exact: true }).waitFor();
      assert.equal(await p.getByText('Thông báo ván trước', { exact: true }).count(), 0);
      assert.deepEqual(await p.evaluate(() => window.__tqsE2e.roundState()), {
        phase: 'playing', boardLogs: [], nativeVfxEvents: [],
      });
      await p.goto('/e2e.html');
    }],
    ['Responsive layout stays within the viewport on phone and desktop widths', async (p) => {
      for (const viewport of [
        { width: 320, height: 844 }, { width: 390, height: 844 },
        { width: 844, height: 390 }, { width: 1280, height: 800 },
      ]) {
        await p.setViewportSize(viewport);
        await p.goto('/e2e.html');
        await p.locator('.sg-game-board').waitFor();
        const metrics = await p.evaluate(() => ({
          width: document.documentElement.clientWidth,
          scrollWidth: document.documentElement.scrollWidth,
          bodyScrollWidth: document.body.scrollWidth,
        }));
        assert.ok(metrics.scrollWidth <= metrics.width + 1,
          `document overflows ${viewport.width}px: ${JSON.stringify(metrics)}`);
        assert.ok(metrics.bodyScrollWidth <= metrics.width + 1,
          `body overflows ${viewport.width}px: ${JSON.stringify(metrics)}`);
      }
      await p.setViewportSize({ width: 390, height: 844 });
    }],
    ['Full App fills the viewport across 24 sizes with active and idle 2/6/8/10-seat boards', async (p) => {
      await p.goto('/e2e.html?app=1');
      await p.getByRole('heading', { name: 'Cổng Doanh Trại', exact: true }).waitFor();
      for (const [width, height] of [
        [320, 568], [360, 640], [390, 844], [412, 915], [540, 720], [600, 960],
        [601, 960], [768, 1024], [820, 1180], [899, 1200], [900, 1200], [1024, 1366],
        [568, 320], [640, 360], [740, 360], [844, 390], [932, 430], [1024, 520],
        [1024, 521], [900, 600], [1280, 720], [1440, 900], [1920, 1080], [2560, 1440],
      ]) {
        await p.setViewportSize({ width, height });
        for (const count of [2, 6, 8, 10]) {
          await start(p, 'choices');
          await p.evaluate(n => window.__tqsE2e.layoutSeats(n), count);
          await p.waitForTimeout(300); // Finish the real seat scale/position transition.
          for (const idle of [false, true]) {
            if (idle) await p.evaluate(() => window.__tqsE2e.cancel());
            await p.locator(idle ? '.sg-hand-idle' : '.sg-hand-fan').waitFor();
            const geometry = await p.evaluate(() => {
              const [shell, table, dashboard, hand, card] = ['.shell', '.sg-board-table', '.board-local-dashboard',
                '.sg-hand-fan, .sg-hand-idle', '.sg-hand-fan .sg-card-button, .sg-hand-idle .sg-card-button']
                .map(s => document.querySelector(s)!.getBoundingClientRect().toJSON());
              return { shell, table, dashboard, hand, card,
                seats: [...document.querySelectorAll('.board-opponents .sg-photo-panel')].map(el => el.getBoundingClientRect().toJSON()),
                scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight };
            });
            const info = `${width}x${height}, seats=${count}, idle=${idle}: ${JSON.stringify(geometry)}`;
            assert.ok(geometry.shell.width >= width - 1 && geometry.table.width >= width - 44, `unused screen width: ${info}`);
            assert.ok(geometry.scrollWidth <= width + 1 && geometry.scrollHeight <= height + 1, `page overflow: ${info}`);
            assert.ok(geometry.dashboard.bottom <= height && height - geometry.dashboard.bottom <= 28, `unused bottom space: ${info}`);
            assert.ok(geometry.table.height > 150 && geometry.table.bottom <= geometry.dashboard.top + 1, `table/dashboard overlap: ${info}`);
            assert.ok(geometry.card.top >= geometry.hand.top - 1 && geometry.card.bottom <= geometry.hand.bottom + 1, `clipped hand: ${info}`);
            assert.ok(geometry.seats.length === count - 1 && geometry.seats.every(r =>
              r.left >= geometry.table.left - 1 && r.right <= geometry.table.right + 1 &&
              r.top >= geometry.table.top - 1 && r.bottom <= geometry.table.bottom + 1), `clipped seat: ${info}`);
          }
        }
      }
      await p.setViewportSize({ width: 390, height: 844 });
      await p.goto('/e2e.html');
    }],
    ['Boot, login, lobby and waiting room use full width and retain reachable controls on short screens', async (p) => {
      await p.goto('/e2e.html?app=1');
      await p.getByRole('heading', { name: 'Cổng Doanh Trại', exact: true }).waitFor();
      for (const [width, height] of [[320, 568], [390, 844], [568, 320], [844, 390], [601, 960],
        [768, 1024], [1024, 521], [1280, 720], [1920, 1080]]) {
        await p.setViewportSize({ width, height });
        for (const phase of ['boot', 'login', 'lobby', 'room'] as const) {
          await p.evaluate(value => window.__tqsE2e.layoutPhase(value), phase);
          await p.locator('.sg-game-canvas').waitFor();
          const geometry = await p.locator('.sg-game-canvas').evaluate(el => el.getBoundingClientRect().toJSON());
          assert.ok(geometry.width >= width - 1 && geometry.height >= height - 1,
            `${phase} leaves unused space at ${width}x${height}: ${JSON.stringify(geometry)}`);
          const controls = p.locator('.sg-game-canvas button:not(.sg-hero-switch-btn):visible:enabled');
          for (const button of [controls.first(), controls.last()]) {
            if (!await button.count()) continue;
            await button.evaluate(el => el.scrollIntoView({ block: 'center' }));
            await button.click({ trial: true });
          }
          const footer = await p.locator('.tqs-status-footer').boundingBox();
          assert.ok(footer && footer.y + footer.height <= height + 1);
          assert.ok(await p.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1));
          // Native dialogs must fit even when the screen cannot fit the page content.
          await p.getByRole('button', { name: 'Thông tin phiên bản', exact: true }).click();
          const dialog = p.getByRole('dialog', { name: 'Thông tin Phiên bản & Đồng bộ Hệ thống', exact: true });
          const rect = await dialog.boundingBox();
          assert.ok(rect && rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= width + 1 && rect.y + rect.height <= height + 1);
          await p.keyboard.press('Escape');
        }
      }
      await p.setViewportSize({ width: 390, height: 844 });
      await p.goto('/e2e.html');
    }],
    ['Portrait table centre clears side seats in six, eight and ten player rooms', async (p) => {
      for (const viewport of [{ width: 320, height: 568 }, { width: 390, height: 844 }, { width: 600, height: 960 }]) {
        await p.setViewportSize(viewport);
        for (const count of [6, 8, 10]) {
          await start(p, 'choices');
          await p.evaluate((value) => window.__tqsE2e.layoutSeats(value), count);
          await p.waitForFunction((value) => document.querySelectorAll('.board-opponents .sg-photo-panel').length === value - 1, count);
          await p.waitForTimeout(300); // Seat position/scale transitions must settle before measuring.
          const geometry = await p.evaluate(() => {
            const center = document.querySelector('.board-center')!.getBoundingClientRect();
            return { center: center.toJSON(), card: document.querySelector('.native-resolving-card')!.getBoundingClientRect().toJSON(),
              pile: document.querySelector('.native-table-pile')!.getBoundingClientRect().toJSON(),
              covered: [...document.querySelectorAll('.board-opponents .sg-photo-panel')]
              .map(el => el.getBoundingClientRect().toJSON()).filter(r =>
                Math.min(r.right, center.right) - Math.max(r.left, center.left) > 1 &&
                Math.min(r.bottom, center.bottom) - Math.max(r.top, center.top) > 1) };
          });
          assert.deepEqual(geometry.covered, [], `${count} seats at ${viewport.width}x${viewport.height}: ${JSON.stringify(geometry)}`);
          assert.ok(geometry.card.left >= geometry.pile.left && geometry.card.right <= geometry.pile.right,
            `processing card is clipped at ${count} seats, ${viewport.width}x${viewport.height}: ${JSON.stringify(geometry)}`);
        }
      }
    }],
    ['Phone trust controls remain reachable during a request and while idle', async (p) => {
      await p.goto('/e2e.html?app=1');
      for (const viewport of [{ width: 320, height: 568 }, { width: 390, height: 844 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        for (const idle of [false, true]) {
          if (idle) await p.evaluate(() => window.__tqsE2e.cancel());
          const trust = p.locator('.sg-dashboard-left-tools .sg-tool-btn').filter({ hasText: 'Ủy thác' });
          const before = await p.evaluate(() => window.__tqsE2e.appActions().length);
          await trust.click();
          const actions = await p.evaluate(() => window.__tqsE2e.appActions());
          assert.equal(actions.length, before + 1);
          assert.equal(actions.at(-1), 'Trust');
        }
      }
      await p.goto('/e2e.html');
    }],
    ['Tablet hand cards keep their size and stay below the skill rail', async (p) => {
      for (const viewport of [{ width: 601, height: 960 }, { width: 768, height: 1024 },
        { width: 899, height: 1200 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        const card = p.getByRole('button', { name: 'Sát', exact: true });
        await card.hover();
        const geometry = await p.evaluate(() => {
          return { card: document.querySelector('.sg-hand-fan .sg-card-button')!.getBoundingClientRect().toJSON(),
            hand: document.querySelector('.sg-hand-fan')!.getBoundingClientRect().toJSON(),
            rail: document.querySelector('.board-local-skill-rail')!.getBoundingClientRect().toJSON(),
            seat: document.querySelector('.board-local-seat')!.getBoundingClientRect().toJSON(),
            actions: document.querySelector('.sg-action-bar')!.getBoundingClientRect().toJSON(),
            choice: document.querySelector('.sg-inline-choice-dock')!.getBoundingClientRect().toJSON() };
        });
        const info = `${viewport.width}x${viewport.height}: ${JSON.stringify(geometry)}`;
        assert.equal(geometry.card.width, 74, info);
        assert.equal(geometry.card.height, 104, info);
        assert.ok(geometry.card.top >= geometry.hand.top && geometry.card.bottom <= geometry.hand.bottom, info);
        assert.ok(geometry.hand.top >= geometry.rail.bottom && geometry.hand.right <= geometry.seat.left, info);
        assert.ok(geometry.actions.bottom <= geometry.rail.top, `actions cover tablet skills: ${info}`);
        assert.ok(geometry.choice.bottom <= geometry.actions.top, `choice drawer covers tablet actions: ${info}`);
        await p.getByRole('button', { name: 'Xác nhận' }).click();
        await waitReplies(p, 1);
      }
    }],
    ['Desktop hover and selection leave the entire card inside the scroll viewport', async (p) => {
      for (const viewport of [{ width: 900, height: 600 }, { width: 1280, height: 800 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        const card = p.getByRole('button', { name: 'Sát', exact: true });
        await p.mouse.move(0, 0);
        for (const state of ['rest', 'hover', 'selected'] as const) {
          if (state === 'hover') await card.hover();
          if (state === 'selected') await card.click();
          await p.waitForTimeout(200); // Wait for the actual card transform to finish.
          const geometry = await card.evaluate((el) => {
            const r = el.getBoundingClientRect();
            const hand = el.closest('.sg-hand-fan')!.getBoundingClientRect();
            const hit = document.elementFromPoint(r.left + r.width / 2, r.top + 2);
            return { card: r.toJSON(), hand: hand.toJSON(), lift: getComputedStyle(el).getPropertyValue('--card-lift').trim(),
              topReachable: el.contains(hit) };
          });
          const info = `${viewport.width}x${viewport.height} ${state}: ${JSON.stringify(geometry)}`;
          assert.equal(geometry.card.width, 84, info);
          assert.equal(geometry.card.height, 114, info);
          assert.equal(geometry.lift, state === 'selected' ? '-20px' : state === 'hover' ? '-12px' : '0px', info);
          assert.ok(geometry.card.top >= geometry.hand.top && geometry.card.bottom <= geometry.hand.bottom, info);
          assert.equal(geometry.topReachable, true, info);
        }
      }
    }],
    ['Hand sort button cycles 4 native modes and toolbar toggles are mutually exclusive', async (p) => {
      for (const viewport of [{ width: 320, height: 568 }, { width: 390, height: 844 },
        { width: 768, height: 1024 }, { width: 844, height: 390 }, { width: 1280, height: 800 }]) {
        await p.setViewportSize(viewport);
        await start(p, 'choices');
        const sortBtn = p.locator('.sg-sort-btn');
        await sortBtn.waitFor({ state: 'visible' });
        for (const label of ['Sắp xếp: Loại', 'Sắp xếp: Chất', 'Sắp xếp: Điểm', 'Sắp xếp']) {
          await sortBtn.click();
          assert.equal(await sortBtn.textContent(), label, `${viewport.width}x${viewport.height}`);
        }
      }
      await p.setViewportSize({ width: 844, height: 390 });
      try {
        await start(p, 'choices');
        const sortBtn = p.locator('.sg-sort-btn');
        await sortBtn.waitFor();
        assert.equal(await sortBtn.textContent(), 'Sắp xếp');
        await sortBtn.click();
        assert.equal(await sortBtn.textContent(), 'Sắp xếp: Loại');
        await sortBtn.click();
        assert.equal(await sortBtn.textContent(), 'Sắp xếp: Chất');
        await sortBtn.click();
        assert.equal(await sortBtn.textContent(), 'Sắp xếp: Điểm');
        await sortBtn.click();
        assert.equal(await sortBtn.textContent(), 'Sắp xếp');

        const toolsBtn = p.getByRole('button', { name: 'Tùy chọn trận đấu' });
        const logBtn = p.locator('.sg-toolbar-log-toggle');
        await toolsBtn.click();
        assert.equal(await toolsBtn.getAttribute('aria-expanded'), 'true');
        assert.equal(await logBtn.getAttribute('aria-expanded'), 'false');
        await logBtn.click();
        assert.equal(await toolsBtn.getAttribute('aria-expanded'), 'false');
        assert.equal(await logBtn.getAttribute('aria-expanded'), 'true');
        await toolsBtn.click();
        assert.equal(await toolsBtn.getAttribute('aria-expanded'), 'true');
        assert.equal(await logBtn.getAttribute('aria-expanded'), 'false');
        await toolsBtn.click();
      } finally {
        await p.setViewportSize({ width: 390, height: 844 });
      }
    }],
  ];

  let passed = 0;
  const failures: string[] = [];
  for (const [name, execute] of tests) {
    try {
      await execute(page);
      ++passed;
      console.log(`PASS ${name}`);
    } catch (error) {
      failures.push(name);
      console.error(`FAIL ${name}:`, error);
      // A failing flow must not leave the next test on the wrong screen.
      await page.goto('/e2e.html');
    }
  }
  console.log(`Browser E2E: ${passed}/${tests.length} PASS`);
  assert.equal(failures.length, 0, `Failed browser scenarios: ${failures.join(', ')}`);
}

const vite = await createServer({ root, configFile: fileURLToPath(new URL('../../vite.config.ts', import.meta.url)),
  server: { host: '127.0.0.1', port: 0, strictPort: false } });
let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
try {
  await vite.listen();
  const baseURL = vite.resolvedUrls?.local[0];
  if (!baseURL) throw new Error('Vite did not report a local address');
  browser = await chromium.launch({ executablePath, headless: true });
  const page = await browser.newPage({ baseURL, viewport: { width: 390, height: 844 } });
  page.setDefaultTimeout(8_000);
  const errors: Error[] = [];
  page.on('pageerror', (e) => errors.push(e));
  await page.goto('/e2e.html');
  await runSuite(page);
  assert.deepEqual(errors.map((e) => e.message), [], 'Browser runtime errors');
} finally {
  await browser?.close();
  await vite.close();
}
