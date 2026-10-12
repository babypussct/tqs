/**
 * Live integration: Chrome -> Wasmoon/real Lua -> local WebSocket
 * gateway -> real FreeKill C++ TCP server (and back).
 *
 * Default: intercept WebSocket.send, verify pre-auth only with fixture MD5.
 * --login: use a matching snapshot and dedicated test account, send Setup,
 * verify real EnterLobby in Lua and React, then disconnect from the lobby.
 *
 * TQS_LIVE_HOST=168.110.36.224 npm run test:e2e:live
 */
import assert from 'node:assert/strict';
import { spawn, type ChildProcess } from 'node:child_process';
import { createPublicKey } from 'node:crypto';
import { once } from 'node:events';
import { cpSync, existsSync, mkdtempSync, mkdirSync, rmSync, writeFileSync, statSync, readdirSync, readFileSync } from 'node:fs';
import { loadEnvFile } from 'node:process';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, type Page } from 'playwright-core';
import { createServer, type ViteDevServer } from 'vite';
import { CLIENT_NOTIFY, PacketStream, PacketType, toHex, type Packet } from '../../src/engine/packet';
import { LuaRuntime } from '../../src/engine/luaRuntime';
import { packageSpec } from '../upstream-packages';
import { PACKAGES } from './snapshot';

const roomPools = process.argv.includes('--room-pools');
const uiTranslations = process.argv.includes('--ui-translations');
const login = process.argv.includes('--login') || roomPools || uiTranslations;
function vietnamDate(): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(new Date());
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}
const evidenceDate = process.env.TQS_LIVE_EVIDENCE_DATE ?? vietnamDate();
assert.match(evidenceDate, /^\d{4}-\d{2}-\d{2}$/,
  'TQS_LIVE_EVIDENCE_DATE must be YYYY-MM-DD');
// Every run gets a unique default tag so a later probe cannot overwrite an
// older sanitized evidence file. A caller may supply a stable tag when it is
// intentionally writing into a fresh evidence directory.
const evidenceTag = process.env.TQS_LIVE_EVIDENCE_TAG ?? `${evidenceDate}-${Date.now()}`;
assert.match(evidenceTag, /^[A-Za-z0-9._-]{1,100}$/,
  'TQS_LIVE_EVIDENCE_TAG contains unsupported filename characters');
// Verify the actual frozen deployment through HTTPS/WSS, without starting a
// second gateway or serving source through Vite.
const deploymentUrl = process.env.TQS_LIVE_URL;
if (deploymentUrl) {
  const url = new URL(deploymentUrl);
  assert.ok(url.protocol === 'https:' ||
    (url.protocol === 'http:' && ['127.0.0.1', 'localhost'].includes(url.hostname)),
  'TQS_LIVE_URL must use HTTPS or local HTTP');
  assert.ok(login, 'Deployment verification requires an explicit login mode');
}
const idleSeconds = Number(process.env.TQS_LIVE_IDLE_SECONDS ?? 0);
assert.ok(Number.isInteger(idleSeconds) && idleSeconds >= 0 && idleSeconds <= 300,
  'TQS_LIVE_IDLE_SECONDS must be an integer from 0 to 300');
assert.ok(login || idleSeconds === 0, 'Heartbeat verification requires --login');
if (login) {
  const config = process.env.TQS_LIVE_CONFIG ?? path.join(os.homedir(), '.codex/secrets/tqs-live-test.env');
  assert.ok(existsSync(config), 'Missing test config; run npm run configure:live first');
  assert.equal(statSync(config).mode & 0o077, 0, 'Test config must have private permissions (chmod 600)');
  loadEnvFile(config);
}
const username = login ? process.env.FK_TEST_USERNAME : 'tqs-preauth-e2e';
const password = login ? process.env.FK_TEST_PASSWORD : 'unused-local-preauth-only';
assert.ok(username && password, 'Login requires FK_TEST_USERNAME and FK_TEST_PASSWORD');
const snapshotRoot = login ? process.env.TQS_LIVE_ROOT : undefined;
if (login) assert.ok(snapshotRoot && existsSync(path.join(snapshotRoot, 'flist.txt')),
  'Login requires TQS_LIVE_ROOT with matching packages/ and flist.txt');
const host = process.env.TQS_LIVE_HOST;
if (!host || !/^[a-zA-Z0-9.:-]+$/.test(host)) {
  throw new Error('Set TQS_LIVE_HOST to the test FreeKill server hostname/IP');
}
const tcpPort = Number(process.env.TQS_LIVE_PORT ?? 9527);
assert.ok(Number.isInteger(tcpPort) && tcpPort > 0 && tcpPort <= 65535, 'Invalid TCP port');
const webRoot = fileURLToPath(new URL('../../', import.meta.url));
const repoRoot = fileURLToPath(new URL('../../../../', import.meta.url));
const upstream = path.join(repoRoot, 'scratch/upstream');
const executablePath = [process.env.TQS_CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
].find((p): p is string => !!p && existsSync(p));
if (!executablePath) throw new Error('Chrome missing: set TQS_CHROME_PATH');

async function freePort(): Promise<number> {
  const server = net.createServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('No local TCP address');
  await new Promise<void>((resolve) => server.close(() => resolve()));
  return address.port;
}

/** The packet's nested payload consists only of CBOR text/byte strings. */
function cborStrings(data: Uint8Array): { major: number; bytes: Uint8Array }[] {
  let offset = 0;
  const head = () => {
    if (offset >= data.length) throw new Error('Incomplete CBOR');
    const b = data[offset++];
    const major = b >> 5;
    const extra = b & 31;
    let length = extra;
    if (extra === 24) length = data[offset++];
    else if (extra === 25) { length = new DataView(data.buffer, data.byteOffset + offset, 2).getUint16(0); offset += 2; }
    else if (extra === 26) { length = new DataView(data.buffer, data.byteOffset + offset, 4).getUint32(0); offset += 4; }
    else if (extra > 26) throw new Error('Unsupported CBOR string length');
    return { major, length };
  };
  const arr = head();
  assert.equal(arr.major, 4, 'Setup must be a CBOR array');
  const values = [];
  for (let i = 0; i < arr.length; i++) {
    const { major, length } = head();
    assert.ok(major === 2 || major === 3, 'Setup items must be CBOR bytes/text');
    assert.ok(offset + length <= data.length, 'Truncated nested Setup CBOR');
    values.push({ major, bytes: data.slice(offset, offset + length) });
    offset += length;
  }
  assert.equal(offset, data.length, 'No trailing Setup bytes');
  return values;
}

function packetFrames(frames: number[][]) {
  const stream = new PacketStream();
  return frames.flatMap((frame) => stream.push(Uint8Array.from(frame)));
}

/** Actual C++ room + draw pile acceptance. All artifacts omit credentials,
 * hand contents and raw packets. The pinned Lua engine only decodes metadata. */
async function verifyRoomPools(page: Page, snapshot: string) {
  const generalPack = 'hegemony_standard';
  const cardPack = 'hegemony_cards';
  const disabled = [generalPack, cardPack];
  const files = new Map<string, Uint8Array>();
  function collect(dir: string, relative: string) {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) collect(full, `${relative}/${entry.name}`);
      else if (entry.isFile() && /\.(lua|json)$/i.test(entry.name)) files.set(`${relative}/${entry.name}`, readFileSync(full));
    }
  }
  collect(path.join(snapshot, 'packages'), 'packages');
  const lua = new LuaRuntime({ files, callbacks: { send() {}, ui() {}, setup() {} } });
  await lua.start();
  const evidenceDir = path.join(repoRoot, 'scratch/evidence');
  mkdirSync(evidenceDir, { recursive: true });
  const evidencePath = path.join(evidenceDir, `ui-02-live-cpp-${evidenceTag}.json`);
  const capture = async () => {
    const frames = await page.evaluate(() => (window as unknown as { __tqsLiveCapture: {
      incoming: number[][]; outgoing: number[][];
    } }).__tqsLiveCapture);
    return { incoming: packetFrames(frames.incoming), outgoing: packetFrames(frames.outgoing) };
  };
  const decode = <T>(packet: Packet): T => lua.eval<T>(`return cbor.decode(__host_hex2bin('${toHex(packet.data)}'))`);
  let gameStarted = false;
  let completed = false;
  try {
    const original = lua.call<{generals: number; cards: number}>('__web_room_pool_summary', 'new_heg_mode', []);
    const filtered = lua.call<{generals: number; cards: number}>('__web_room_pool_summary', 'new_heg_mode', disabled);
    assert.ok(filtered.generals < original.generals && filtered.cards < original.cards);
    const generalCheckbox = page.locator(`input[data-pack-id="${generalPack}"]`);
    const cardCheckbox = page.locator(`input[data-pack-id="${cardPack}"]`);
    assert.ok(await generalCheckbox.isChecked() && await cardCheckbox.isChecked());
    await page.locator('#capacity').selectOption('2');
    await page.locator('#timeout').selectOption('30');
    await page.locator('#room-name').fill('UI02 FreeKill CPP pack acceptance');
    await generalCheckbox.uncheck();
    await cardCheckbox.uncheck();
    assert.match(await page.locator('.pool-summary').innerText(), new RegExp(`${filtered.generals} tướng.*${filtered.cards} lá`));
    await page.screenshot({ path: path.join(evidenceDir, `ui-02-live-lobby-${evidenceTag}.png`), fullPage: true });
    await page.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
    await page.getByRole('heading', { name: 'UI02 FreeKill CPP pack acceptance' }).waitFor({ timeout: 30_000 });
    await page.locator('.waiting-pools > summary').click();
    const waiting = await page.locator('.waiting-pools').innerText();
    assert.ok(!waiting.includes(generalPack) && !waiting.includes(cardPack), 'Disabled packs displayed as enabled');
    const firstTrace = await capture();
    const create = firstTrace.outgoing.find((p) => p.command === 'CreateRoom');
    const enter = firstTrace.incoming.find((p) => p.command === 'EnterRoom');
    assert.ok(create && enter, 'C++ CreateRoom / EnterRoom roundtrip required');
    const created = decode<[string, number, number, { disabledPack: string[]; disabledGenerals: string[] }]>(create);
    const entered = decode<[number, number, { disabledPack: string[]; disabledGenerals: string[]; gameMode: string }]>(enter);
    assert.deepEqual(created[3].disabledPack, disabled);
    assert.deepEqual(created[3].disabledGenerals, []);
    assert.equal(entered[2].gameMode, 'new_heg_mode');
    assert.ok(disabled.every((id) => entered[2].disabledPack.includes(id)), 'Server settings omitted disabled packages');
    assert.deepEqual(entered[2].disabledGenerals, []);
    await page.screenshot({ path: path.join(evidenceDir, `ui-02-live-room-${evidenceTag}.png`), fullPage: true });
    console.log(`PASS C++ EnterRoom echoed disabledPack ${disabled.join(' + ')}; pool preview ${original.generals}/${original.cards} -> ${filtered.generals}/${filtered.cards}`);

    await page.getByRole('button', { name: '+ Thêm bot' }).click();
    await page.getByText('2/2 người chơi').waitFor({ timeout: 15_000 });
    await page.getByRole('button', { name: 'Bắt đầu' }).click();
    gameStarted = true;
    await page.getByRole('heading', { name: 'Chọn chủ tướng và phó tướng' }).waitFor({ timeout: 60_000 });
    const offered = await page.evaluate(async () => {
      const storeModule = await (new Function('return import("/src/store/gameStore.ts")')() as Promise<{
        useGameStore: { getState(): { initialGeneral: { generals: string[] } | null } };
      }>);
      return storeModule.useGameStore.getState().initialGeneral?.generals ?? [];
    });
    assert.ok(offered.length >= 5, 'Server should offer at least five generals');
    const offeredLua = `{${offered.map((id) => JSON.stringify(id)).join(',')}}`;
    const offeredPacks = lua.eval<string[]>(`local packs = {}; for _, name in ipairs(${offeredLua}) do
      local general = Fk.generals[name]
      packs[#packs + 1] = general and general.package.name or 'MISSING'
    end; return packs`);
    assert.equal(offeredPacks.length, offered.length);
    assert.ok(offeredPacks.every((pack) => pack !== generalPack && pack !== 'MISSING'), 'C++ offered a general from disabled pack');
    console.log(`PASS C++ general offer: ${offered.length} generals, 0 from disabled ${generalPack}`);

    const choices = page.getByRole('group', { name: 'Danh sách võ tướng' }).getByRole('button');
    let pairChosen = false;
    const generalCount = await choices.count();
    // Five random live generals need not match the first offered main.
    // Invalid deputies are ignored by React; restart with a different main.
    for (let main = 0; main < generalCount && !pairChosen; main++) {
      await page.getByRole('button', { name: 'Chọn lại' }).click().catch(() => {});
      await choices.nth(main).click();
      for (let deputy = 0; deputy < generalCount; deputy++) {
        if (deputy === main) continue;
        await choices.nth(deputy).click();
        if (await page.getByRole('button', { name: 'Xác nhận tướng' }).isEnabled()) {
          pairChosen = true;
          break;
        }
      }
    }
    assert.ok(pairChosen, 'No compatible pair in C++ general offer');
    await page.getByRole('button', { name: 'Xác nhận tướng' }).click();
    await page.waitForFunction(() => {
      const c = (window as unknown as { __tqsLiveCapture: { incoming: number[][] } }).__tqsLiveCapture;
      return c.incoming.length > 0 && !!document.querySelector('.game-board');
    }, undefined, { timeout: 75_000 });
    let traced = await capture();
    let drawPacket = traced.incoming.find((packet) => packet.command === 'PrepareDrawPile');
    if (!drawPacket) {
      await page.waitForTimeout(2500);
      traced = await capture();
      drawPacket = traced.incoming.find((packet) => packet.command === 'PrepareDrawPile');
    }
    assert.ok(drawPacket, 'Missing C++ PrepareDrawPile after general selection');
    const cards = decode<number[]>(drawPacket);
    assert.equal(cards.length, filtered.cards, 'C++ initial draw pile differs from native filtered pool count');
    assert.equal(new Set(cards).size, cards.length, 'Duplicate initial draw pile IDs');
    const cardPacks = lua.eval<string[]>(`local packs = {}; for _, id in ipairs({${cards.join(',')}}) do
      local card = Fk:getCardById(id)
      packs[#packs + 1] = card and card.package.name or 'MISSING'
    end; return packs`);
    assert.equal(cardPacks.length, cards.length);
    assert.ok(cardPacks.every((pack) => pack !== cardPack && pack !== 'MISSING'), 'C++ draw pile includes disabled CardPack');
    await page.screenshot({ path: path.join(evidenceDir, `ui-02-live-board-${evidenceTag}.png`), fullPage: true });
    console.log(`PASS C++ PrepareDrawPile: ${cards.length} unique card IDs, 0 from disabled ${cardPack}`);
    const evidence = {
      date: evidenceDate, observedAt: new Date().toISOString(), server: `${host}:${tcpPort}`, mode: entered[2].gameMode,
      disabledPacks: disabled, disabledGenerals: entered[2].disabledGenerals,
      preview: { original, filtered }, actual: {
        serverEnterRoom: true, serverEnterRoomDisabledPacks: entered[2].disabledPack,
        offeredGeneralCount: offered.length, excludedGeneralCount: offeredPacks.filter((p) => p === generalPack).length,
        drawPileCount: cards.length, uniqueDrawCardIds: new Set(cards).size,
        excludedCardCount: cardPacks.filter((p) => p === cardPack).length,
        serverCommandsObserved: ['EnterRoom', 'StartGame', 'CustomDialog', 'PrepareDrawPile'].filter((cmd) => traced.incoming.some((p) => p.command === cmd)),
      }, status: 'pool-verification-pass', gameOver: false,
    };
    writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
    await page.getByRole('button', { name: 'BOT chơi hộ' }).click();
    await page.getByRole('button', { name: 'Tự chơi lại' }).waitFor({ timeout: 15_000 });
    console.log('PASS native Trust enabled; waiting for real server GameOver before leaving');
    await page.getByRole('button', { name: 'Về sảnh' }).waitFor({ timeout: 480_000 });
    const finished = await capture();
    assert.ok(finished.incoming.some((packet) => packet.command === 'GameOver'), 'Missing C++ GameOver');
    evidence.actual.serverCommandsObserved = [...new Set(finished.incoming.map((p) => p.command))]
      .filter((cmd) => ['EnterRoom', 'StartGame', 'CustomDialog', 'PrepareDrawPile', 'GameOver', 'NetStateChanged'].includes(cmd));
    evidence.gameOver = true;
    evidence.status = 'full-live-game-pass';
    writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
    completed = true;
    await page.screenshot({ path: path.join(evidenceDir, `ui-02-live-finished-${evidenceTag}.png`), fullPage: true });
    await page.getByRole('button', { name: 'Về sảnh' }).click();
    await page.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    console.log('PASS full C++ bot game / GameOver / return to lobby; sanitized evidence saved');
  } finally {
    lua.close();
    if (gameStarted && !completed) {
      console.error('WARNING live game might still be active; premature exit may cause temporary server IP ban');
    }
  }
}

/** Capture only rendered, public-facing text during a real C++ bot game.
 * Never persist raw frames, credentials, hand contents or hidden marks. */
async function verifyUiTranslations(page: Page) {
  const evidenceDir = path.resolve(process.env.TQS_UI01_EVIDENCE_DIR ?? path.join(repoRoot, 'scratch/evidence'));
  mkdirSync(evidenceDir, { recursive: true });
  const observedNames: string[] = [];
  const roomName = 'UI01 Viet hoa live';
  let gameStarted = false;
  let gameOver = false;
  const screenshot = (name: string) => page.screenshot({
    path: path.join(evidenceDir, name), fullPage: true,
    mask: [page.locator('.board-player-name'),
      page.locator('.player-item strong').filter({ hasText: username! }),
      page.locator('[aria-labelledby="result-title"] p').filter({ hasText: username! }),
      page.locator('.board-logs li').filter({ hasText: username! }),
      page.locator('.board-moments .board-moment').filter({ hasText: username! })],
    maskColor: '#273c30',
  });
  try {
    await page.locator('#capacity').selectOption('2');
    await page.locator('#timeout').selectOption('30');
    await page.locator('#room-name').fill(roomName);
    await page.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).click();
    await page.getByRole('heading', { name: roomName }).waitFor({ timeout: 30_000 });
    await page.getByRole('button', { name: '+ Thêm bot' }).click();
    await page.getByText('2/2 người chơi').waitFor({ timeout: 15_000 });
    await page.getByRole('button', { name: 'Bắt đầu' }).click();
    gameStarted = true;
    await page.getByRole('heading', { name: 'Chọn chủ tướng và phó tướng' }).waitFor({ timeout: 60_000 });
    const choices = page.getByRole('group', { name: 'Danh sách võ tướng' }).getByRole('button');
    observedNames.push(...await choices.allTextContents());
    await screenshot(`ui-01-live-generals-${evidenceTag}.png`);
    let pairChosen = false;
    const generalCount = await choices.count();
    // Each server offer can include several incompatible kingdoms. An invalid
    // deputy leaves the main selected, so try every deputy before resetting.
    for (let main = 0; main < generalCount && !pairChosen; main++) {
      const reset = page.getByRole('button', { name: 'Chọn lại' });
      if (await reset.isEnabled()) await reset.click();
      await choices.nth(main).click();
      for (let deputy = 0; deputy < generalCount; deputy++) {
        if (deputy === main) continue;
        await choices.nth(deputy).click();
        // A legal pair with multiple kingdoms needs a kingdom picked first.
        const kingdomChoice = page.locator('.kingdom-picker input[type="radio"]').first();
        if (await kingdomChoice.count()) await kingdomChoice.check();
        if (await page.getByRole('button', { name: 'Xác nhận tướng' }).isEnabled()) {
          pairChosen = true;
          break;
        }
      }
    }
    assert.ok(pairChosen, 'No valid general pair in live offer');
    await page.getByRole('button', { name: 'Xác nhận tướng' }).click();
    await page.locator('.game-board').waitFor({ timeout: 75_000 });

    // The observer records DOM text only; its selector excludes card metadata,
    // internal state and network payloads. A set prevents duplicate growth.
    // Use a browser-side script string: the tsx transform injects __name()
    // into nested functions of serialized callbacks, but page lacks that helper.
    await page.evaluate(String.raw`(() => {
      const observed = new Set();
      const layout = { maxLogEntries: 0, maxMoments: 0, logVisible: false, horizontalOverflow: false };
      const record = () => {
        document.querySelectorAll('.board-logs li, .board-moments .board-moment, .board-player .board-mark, .board-banners .board-mark, .board-generals span')
          .forEach((node) => {
            const value = node.textContent?.trim();
            if (value && value.length <= 400 && observed.size < 500) observed.add(value);
          });
        const log = document.querySelector('.board-logs');
        layout.maxLogEntries = Math.max(layout.maxLogEntries, document.querySelectorAll('.board-logs li').length);
        layout.maxMoments = Math.max(layout.maxMoments, document.querySelectorAll('.board-moments .board-moment').length);
        layout.logVisible ||= !!log && log.getClientRects().length > 0;
        layout.horizontalOverflow ||= document.documentElement.scrollWidth > window.innerWidth;
      };
      record();
      new MutationObserver(record).observe(document.body, { childList: true, characterData: true, subtree: true });
      window.__tqsDisplayAudit = () => [...observed];
      window.__tqsLayoutAudit = () => layout;
    })()`);
    await screenshot(`ui-01-live-board-${evidenceTag}.png`);
    await page.getByRole('button', { name: 'BOT chơi hộ' }).click();
    await page.getByRole('button', { name: 'Tự chơi lại' }).waitFor({ timeout: 15_000 });
    console.log('UI-01: server accepted native Trust; recording live visible logs until GameOver');
    await page.getByRole('button', { name: 'Về sảnh' }).waitFor({ timeout: 480_000 });
    const frames = await page.evaluate(() => (window as unknown as { __tqsLiveCapture: { incoming: number[][] } }).__tqsLiveCapture.incoming);
    gameOver = packetFrames(frames).some((packet) => packet.command === 'GameOver');
    assert.ok(gameOver, 'A real C++ GameOver is required before ending this test');
    const visible = await page.evaluate(() => (window as unknown as { __tqsDisplayAudit: () => string[] }).__tqsDisplayAudit());
    const presentation = await page.evaluate(() => (window as unknown as { __tqsLayoutAudit: () => {
      maxLogEntries: number; maxMoments: number; logVisible: boolean; horizontalOverflow: boolean;
    } }).__tqsLayoutAudit());
    assert.ok(presentation.logVisible && presentation.maxLogEntries > 0 && presentation.maxMoments > 0,
      'Live public logs and board moments must render during the game');
    assert.equal(presentation.horizontalOverflow, false, 'Live 390px viewport must not overflow horizontally');
    const censor = (value: string) => value.replaceAll(username!, '[test-account]');
    const samples = visible.map(censor);
    const translatedNames = observedNames.map(censor);
    const unresolved = samples.filter((value) => /&#(?:x[0-9a-f]+|\d+);|(?:[a-z]+__)[a-z_]+|#[A-Za-z_]+|[\u3400-\u9fff]/iu.test(value));
    writeFileSync(path.join(evidenceDir, `ui-01-live-cpp-${evidenceTag}.json`), JSON.stringify({
      date: evidenceDate, observedAt: new Date().toISOString(), mode: 'new_heg_mode', server: `${host}:${tcpPort}`,
      context: 'Chrome 390px + React/Wasmoon/Lua + Gateway + real FreeKill C++',
      deploymentUrl: deploymentUrl ?? null,
      presentation,
      generalLabels: translatedNames, visibleText: samples, unresolved,
      gameOver, status: unresolved.length ? 'live-audit-found-untranslated' : 'live-audit-no-untranslated-in-observed-text',
      note: 'Only DOM text publicly rendered to this test player; snapshot, passwords, hand data and frames are excluded.',
    }, null, 2) + '\n');
    await screenshot(`ui-01-live-finished-${evidenceTag}.png`);
    await page.getByRole('button', { name: 'Về sảnh' }).click();
    await page.getByRole('heading', { name: 'Tạo phòng mới' }).waitFor();
    console.log(`PASS UI-01 live C++ GameOver + lobby; ${samples.length} unique visible texts, ${unresolved.length} possible untranslated strings`);
  } finally {
    if (gameStarted && !gameOver && !page.isClosed()) {
      // Do not intentionally drop an active FreeKill game: it can temp-ban IPs.
      console.error('UI-01 live test did not finish; trying native BOT Trust / GameOver before exit');
      const bot = page.getByRole('button', { name: 'BOT chơi hộ' });
      if (await bot.isVisible().catch(() => false)) await bot.click().catch(() => {});
      await page.getByRole('button', { name: 'Về sảnh' }).waitFor({ timeout: 480_000 }).catch(() => {});
      if (await page.getByRole('button', { name: 'Về sảnh' }).isVisible().catch(() => false)) {
        await page.getByRole('button', { name: 'Về sảnh' }).click().catch(() => {});
      }
    }
  }
}

const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-live-gateway-'));
const oldEnv = process.env.VITE_GATEWAY_URL;
let gateway: ChildProcess | undefined;
let vite: ViteDevServer | undefined;
let browser: Awaited<ReturnType<typeof chromium.launch>> | undefined;
let page: Page | undefined;
let logs = '';
try {
  // Login uses the snapshot generated after checking live package revisions.
  // Pre-auth keeps its deliberately invalid, test-only file-list marker.
  for (const pkg of PACKAGES) {
    const sourceRoot = snapshotRoot ? path.join(snapshotRoot, 'packages') : upstream;
    const src = path.join(sourceRoot, snapshotRoot ? pkg : packageSpec(pkg).sourceDirectory);
    assert.ok(existsSync(path.join(src, 'init.lua')) || existsSync(path.join(src, 'lua/freekill.lua')),
      `Missing pinned package ${pkg}`);
    const dst = path.join(root, 'packages', pkg);
    mkdirSync(path.dirname(dst), { recursive: true });
    cpSync(src, dst, { recursive: true, filter: (source) => {
      if (path.basename(source) === '.git') return false;
      return statSync(source).isDirectory() || /\.(lua|json|md)$/i.test(source);
    } });
  }
  if (snapshotRoot) cpSync(path.join(snapshotRoot, 'flist.txt'), path.join(root, 'flist.txt'));
  else writeFileSync(path.join(root, 'flist.txt'), 'TQS pre-auth test only; never use this MD5 for login\n');

  let pageUrl = deploymentUrl;
  const port = deploymentUrl ? undefined : await freePort();
  const gatewayUrl = deploymentUrl
    ? new URL('gateway/', deploymentUrl).href.replace(/\/$/, '')
    : `http://127.0.0.1:${port}`;
  if (!deploymentUrl) {
    gateway = spawn(process.execPath, [path.join(repoRoot, 'game/gateway/src/server.mjs')], {
      cwd: path.join(repoRoot, 'game/gateway'),
      env: { ...process.env, FK_TEST_USERNAME: undefined, FK_TEST_PASSWORD: undefined,
        FK_ROOT: root, FK_HOST: host, FK_PORT: String(tcpPort), PORT: String(port) },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    gateway.stdout?.on('data', (bytes) => { logs += String(bytes); });
    gateway.stderr?.on('data', (bytes) => { logs += String(bytes); });
  }
  let healthy = false;
  for (let i = 0; i < 80; i++) {
    if (gateway && gateway.exitCode !== null) throw new Error(`Gateway exited early (${gateway.exitCode}): ${logs}`);
    try {
      const res = await fetch(`${gatewayUrl}/healthz`);
      if (res.ok) { healthy = true; break; }
    } catch { /* gateway still starting */ }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  assert.ok(healthy, `Gateway did not start: ${logs}`);
  const manifest = await (await fetch(`${gatewayUrl}/manifest.json`)).json() as {
    md5: string; fileCount: number; packages: string[];
  };
  assert.ok(manifest.fileCount > 100);
  // The current hosted candidate fronts the existing native server, whose
  // package database predates the optional jsrg/mougong extension packs. Keep
  // the local Lua snapshot complete for decoding, but require the hosted
  // manifest to match the server-compatible package set exactly.
  const expectedHostedPackages = deploymentUrl
    ? PACKAGES.filter((name) => name !== 'jsrg' && name !== 'mougong')
    : PACKAGES;
  assert.deepEqual(manifest.packages, expectedHostedPackages);
  if (!deploymentUrl) {
    process.env.VITE_GATEWAY_URL = gatewayUrl;
    vite = await createServer({ root: webRoot,
      configFile: path.join(webRoot, 'vite.config.ts'),
      // A live verification session must not reload if local source is edited.
      server: { host: '127.0.0.1', port: 0, strictPort: false, hmr: false },
    });
    await vite.listen();
    pageUrl = vite.resolvedUrls?.local[0];
  }
  assert.ok(pageUrl, 'Vite URL unavailable');

  browser = await chromium.launch({ executablePath, headless: true });
  page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  page.setDefaultTimeout(20_000);
  const pageErrors: string[] = [];
  page.on('pageerror', (e) => pageErrors.push(e.message));
  const luaErrors: string[] = [];
  const consoleErrors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(`${msg.text()} (${msg.location().url})`);
    if (msg.type() === 'error' && msg.text().includes('[FreeKill Lua]')) luaErrors.push(msg.text());
  });
  // Capture real network packets. Forward only in explicit --login mode.
  const gameSocketUrl = `${gatewayUrl.replace(/^http/, 'ws')}/ws`;
  await page.addInitScript({ content: `(() => {
    const NativeSocket = window.WebSocket;
    const capture = { incoming: [], outgoing: [] };
    window.__tqsLiveCapture = capture;
    window.WebSocket = class extends NativeSocket {
      constructor(...args) {
        super(...args);
        this.isGameSocket = String(args[0]) === ${JSON.stringify(gameSocketUrl)};
        if (!this.isGameSocket) return;
        this.addEventListener('message', (event) => {
          if (event.data instanceof ArrayBuffer)
            capture.incoming.push(Array.from(new Uint8Array(event.data)));
        });
      }
      send(data) {
        if (!this.isGameSocket) { super.send(data); return; }
        if (!(data instanceof Uint8Array)) throw new Error('Unexpected non-binary WebSocket send');
        capture.outgoing.push(Array.from(data));
        ${login ? 'super.send(data);' : '// Pre-auth: never forward bytes to the gateway.'}
      }
    };
  })();` });
  await page.goto(pageUrl, { waitUntil: 'domcontentloaded' });
  await page.getByRole('heading', { name: 'Đăng nhập FreeKill' }).waitFor({ timeout: 45_000 });
  await page.getByLabel('Tên tài khoản').fill(username);
  await page.getByLabel('Mật khẩu').fill(password);
  await page.getByRole('button', { name: 'Vào sảnh' }).click();
  await page.waitForFunction(() => (window as unknown as { __tqsLiveCapture: {
    outgoing: number[][];
  } }).__tqsLiveCapture.outgoing.length > 0, undefined, { timeout: 45_000 });
  if (login) {
    await page.getByRole('heading', { name: 'Tạo phòng mới', exact: true }).waitFor();
    await page.getByText('Đã kết nối', { exact: true }).waitFor();
    if (roomPools) await verifyRoomPools(page, root);
    if (uiTranslations) await verifyUiTranslations(page);
    if (idleSeconds > 0) {
      console.log(`Verifying authenticated lobby heartbeats for ${idleSeconds}s (no game started)`);
      await page.waitForTimeout(idleSeconds * 1000);
      await page.getByText('Đã kết nối', { exact: true }).waitFor();
    }
  }
  const capture = await page.evaluate(() => (window as unknown as { __tqsLiveCapture: {
    incoming: number[][]; outgoing: number[][];
  } }).__tqsLiveCapture);

  const notifications = packetFrames(capture.incoming);
  const challenge = notifications.find((packet) => packet.command === 'NetworkDelayTest');
  assert.ok(challenge, 'No real FreeKill C++ NetworkDelayTest over gateway');
  assert.equal(challenge.type & PacketType.NOTIFICATION, PacketType.NOTIFICATION);
  const challenged = cborStrings(Uint8Array.of(0x81, ...challenge.data));
  assert.equal(challenged.length, 1);
  const publicPem = new TextDecoder().decode(challenged[0].bytes);
  assert.match(publicPem, /BEGIN RSA PUBLIC KEY/);
  const key = createPublicKey(publicPem);
  const setupPackets = packetFrames(capture.outgoing);
  const setups = setupPackets.filter((packet) => packet.command === 'Setup');
  assert.equal(setups.length, 1, 'Only one Setup should be attempted');
  assert.equal(setups[0].type, CLIENT_NOTIFY);
  const fields = cborStrings(setups[0].data);
  assert.equal(fields.length, 5);
  assert.deepEqual(fields.map((f) => f.major), [3, 2, 3, 3, 3]);
  assert.ok(new TextDecoder().decode(fields[0].bytes) === username, 'Setup account matches configured test account');
  assert.equal(fields[1].bytes.length, key.asymmetricKeyDetails?.modulusLength! / 8);
  assert.equal(new TextDecoder().decode(fields[2].bytes), manifest.md5);
  assert.equal(new TextDecoder().decode(fields[3].bytes), '0.5.25');
  assert.ok(new TextDecoder().decode(fields[4].bytes).length > 10);
  assert.deepEqual(pageErrors, [], 'Browser JS errors');
  assert.deepEqual(luaErrors, [], 'Browser Lua errors');
  assert.deepEqual(consoleErrors, [], 'Browser console errors');
  console.log(`PASS Chrome/Wasmoon/FreeKill Lua -> Gateway -> real C++ ${host}:${tcpPort}`);
  if (login) {
    assert.ok(notifications.some((packet) => packet.command === 'Setup'), 'Server acknowledged account Setup');
    assert.ok(notifications.some((packet) => packet.command === 'EnterLobby'), 'Real server EnterLobby received');
    assert.ok(setupPackets.some((packet) => packet.command === 'RefreshRoomList'), 'Lua requested lobby room list');
    assert.equal(await page.getByRole('alert').count(), 0, 'No application errors after login');
    if (idleSeconds > 0) {
      const incomingHeartbeats = notifications.filter((packet) => packet.command === 'Heartbeat').length;
      const outgoingHeartbeats = setupPackets.filter((packet) => packet.command === 'Heartbeat');
      assert.ok(incomingHeartbeats >= Math.floor(idleSeconds / 30), 'Server sent expected periodic heartbeats');
      assert.equal(outgoingHeartbeats.length, incomingHeartbeats, 'Every server heartbeat was answered');
      assert.ok(outgoingHeartbeats.every((packet) => packet.type === CLIENT_NOTIFY), 'Heartbeats are native notifications');
      console.log(`PASS lobby stayed online for ${idleSeconds}s; answered ${incomingHeartbeats}/${incomingHeartbeats} real server heartbeats`);
    }
    if (process.env.TQS_LIVE_EVIDENCE_PATH) {
      assert.equal(await page.locator('#username, #password').count(), 0,
        'Never capture credential fields as evidence');
      const evidence = path.resolve(process.env.TQS_LIVE_EVIDENCE_PATH);
      assert.equal(path.extname(evidence), '.png', 'Evidence must be a PNG');
      mkdirSync(path.dirname(evidence), { recursive: true });
      await page.screenshot({ path: evidence, fullPage: true });
      console.log('PASS saved authenticated lobby screenshot without credential fields');
    }
    await page.getByRole('button', { name: 'Ngắt kết nối', exact: true }).click();
    await page.getByRole('heading', { name: 'Đăng nhập FreeKill' }).waitFor();
    console.log('PASS real server Setup + EnterLobby accepted by Lua; React lobby online; disconnected cleanly');
    console.log(`PASS gateway Lua bundle: ${manifest.fileCount} files; server accepted snapshot MD5 ${manifest.md5}`);
  } else {
    assert.equal(setupPackets.length, 1, 'Pre-auth sends only the intercepted Setup');
    console.log(`PASS real server NetworkDelayTest (${capture.incoming.length} WS frames), RSA Setup constructed in browser (intercepted before send)`);
    console.log(`PASS gateway Lua bundle: ${manifest.fileCount} files; fixture MD5 (login intentionally untested)`);
  }
} catch (error) {
  // Playwright failure details may include fill values. Never expose them.
  let message = error instanceof Error ? error.message : String(error);
  for (const value of [username, password]) if (value) message = message.split(value).join('[redacted]');
  console.error(`FAIL live integration: ${message}`);
  if (page && !page.isClosed()) {
    const capture = await page.evaluate(() => (window as unknown as { __tqsLiveCapture?: {
      incoming: number[][]; outgoing: number[][];
    } }).__tqsLiveCapture).catch(() => undefined);
    if (capture) {
      const incoming = packetFrames(capture.incoming);
      console.error(`Received commands: ${incoming.map((packet) => packet.command).join(', ')}`);
      console.error(`Sent commands: ${packetFrames(capture.outgoing).map((packet) => packet.command).join(', ')}`);
      for (const packet of incoming.filter((packet) => ['ErrorMsg', 'ErrorDlg'].includes(packet.command))) {
        let detail = new TextDecoder().decode(packet.data);
        for (const value of [username, password]) if (value) detail = detail.split(value).join('[redacted]');
        console.error(`Server ${packet.command}: ${detail.slice(0, 512)}`);
      }
    }
  }
  process.exitCode = 1;
} finally {
  if (browser) await browser.close();
  if (vite) await vite.close();
  if (gateway && gateway.exitCode === null) {
    gateway.kill('SIGTERM');
    await Promise.race([once(gateway, 'exit'), new Promise((r) => setTimeout(r, 2000))]);
    if (gateway.exitCode === null) gateway.kill('SIGKILL');
  }
  if (oldEnv === undefined) delete process.env.VITE_GATEWAY_URL;
  else process.env.VITE_GATEWAY_URL = oldEnv;
  rmSync(root, { recursive: true, force: true });
}
