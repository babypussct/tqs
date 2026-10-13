/** Two distinct private test accounts, one frozen candidate, real C++ server.
 * Only command/request metadata is persisted; credentials and game payloads stay in memory. */
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { existsSync, readFileSync, writeFileSync, statSync, mkdirSync, cpSync, mkdtempSync, rmSync } from 'node:fs';
import { randomBytes, createHash } from 'node:crypto';
import { loadEnvFile } from 'node:process';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import { fileURLToPath } from 'node:url';
import { preview } from 'vite';
import { chromium, type Page } from 'playwright-core';
import { PacketStream, CLIENT_REPLY } from '../../src/engine/packet';
import { verifyCandidateIdentity, verifyQaPackageManifest } from './identity';

type LiveScenario = '' | 'draw-sequence' | 'card-chosen' | 'cards-and-choice' | 'poxi' | 'rescue-normal' | 'rescue-battle' | 'founding';
const testScenario = (process.env.TQS_LIVE_SCENARIO ?? (process.argv.includes('--card-chosen') ? 'card-chosen' : '')) as LiveScenario;
assert.ok(testScenario === '' || testScenario === 'draw-sequence' || testScenario === 'card-chosen' || testScenario === 'cards-and-choice' || testScenario === 'poxi' ||
  testScenario === 'rescue-normal' || testScenario === 'rescue-battle' || testScenario === 'founding',
  'TQS_LIVE_SCENARIO must be empty, draw-sequence, card-chosen, cards-and-choice, poxi, rescue-normal, rescue-battle or founding');
// These scenarios deliberately require an explicit opt-in: an interrupted
// active room can create a server-side runner and trigger the upstream IP
// temporary-ban policy. Local fixtures remain enabled independently.
const experimentalScenariosEnabled = process.env.TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS === '1';
assert.ok(!testScenario || experimentalScenariosEnabled,
  'Experimental live scenarios are temporarily locked; set TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 only after broad deployment');
const nativeQa = process.env.TQS_LIVE_NATIVE_QA === '1';
assert.ok(!nativeQa || !!testScenario, 'TQS_LIVE_NATIVE_QA=1 requires TQS_LIVE_SCENARIO');

const web = fileURLToPath(new URL('../../',import.meta.url));
const repo = path.resolve(web,'../..');
const config = process.env.TQS_LIVE_CONFIG ?? path.join(os.homedir(),'.codex/secrets/tqs-live-test.env');
assert.equal(statSync(config).mode & 0o077,0,'Private test configuration required');
loadEnvFile(config);
const host=process.env.TQS_LIVE_HOST; assert.ok(host && /^[a-zA-Z0-9.:-]+$/.test(host),'TQS_LIVE_HOST required');
const runtime=process.env.TQS_LIVE_ROOT; assert.ok(runtime && existsSync(path.join(runtime,'flist.txt')));
const first={username:process.env.FK_TEST_USERNAME!,password:process.env.FK_TEST_PASSWORD!};assert.ok(first.username && first.password);
const secondFile=path.join(os.homedir(),'.codex/secrets/tqs-multiplayer-second.json');
if(!existsSync(secondFile)) writeFileSync(secondFile,JSON.stringify({username:`tqsqa${randomBytes(6).toString('hex')}`,
  password:randomBytes(24).toString('hex')}),{mode:0o600,flag:'wx'});
assert.equal(statSync(secondFile).mode & 0o077,0);
const second=JSON.parse(readFileSync(secondFile,'utf8')) as typeof first;
assert.notEqual(first.username,second.username);
const frozenDist = mkdtempSync(path.join(os.tmpdir(),'tqs-frozen-multiplayer-'));
cpSync(path.join(web,'dist'),frozenDist,{recursive:true});
const distIndexSha256 = createHash('sha256').update(readFileSync(path.join(frozenDist,'index.html'))).digest('hex');
const chrome=process.env.TQS_CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
async function freePort(){const s=net.createServer();s.listen(0,'127.0.0.1');await once(s,'listening');const p=(s.address() as net.AddressInfo).port;await new Promise<void>(r=>s.close(()=>r()));return p;}
const [gatewayPort,peerGatewayPort,webPort]=await Promise.all([freePort(),freePort(),freePort()]);
const deploymentUrl = process.env.TQS_LIVE_URL;
const testGatewayRestart = process.argv.includes('--restart-gateway');
assert.ok(!testGatewayRestart || !deploymentUrl,'Gateway restart test requires an isolated local gateway; never restart shared hosting');
if (deploymentUrl) assert.equal(new URL(deploymentUrl).protocol,'https:');
const base=deploymentUrl?.replace(/\/$/,'') ?? `http://127.0.0.1:${webPort}`;
const qaPackageIdentity = nativeQa ? verifyQaPackageManifest({
  manifestPath: process.env.TQS_QA_PACKAGE_MANIFEST ?? path.join(runtime, 'packages/tqs_qa/package.manifest.json'),
  expectedRevision: process.env.TQS_QA_EXPECTED_REVISION,
}) : null;
const candidateIdentity = await verifyCandidateIdentity({
  runtime,
  dist: path.join(web, 'dist'),
  deploymentUrl,
  releaseManifestPath: process.env.TQS_RELEASE_MANIFEST,
  allowUnpinned: process.env.TQS_LIVE_ALLOW_UNPINNED === '1',
});
console.log(`PASS candidate identity: runtimeMD5=${candidateIdentity.runtimeMD5}, packages=${candidateIdentity.localPackages.length}, ` +
  `dist=${candidateIdentity.distIndexSha256}${deploymentUrl ? ', hosted gateway/index matched' : ', local runtime pinned'}`);
if (qaPackageIdentity) console.log(`PASS native QA package identity: revision=${qaPackageIdentity.sourceRevision}, packageSha256=${qaPackageIdentity.packageSha256}`);
const startGateway=(port=gatewayPort)=>spawn(process.execPath,[path.join(repo,'game/gateway/src/server.mjs')],{
  env:{...process.env,FK_TEST_USERNAME:undefined,FK_TEST_PASSWORD:undefined,FK_ROOT:runtime,FK_HOST:host,
    FK_PORT:process.env.TQS_LIVE_PORT ?? '9527',PORT:String(port),BIND_HOST:'127.0.0.1',ALLOW_ORIGIN:base,TRUSTED_PROXIES:''},stdio:'ignore'});
let gateway=deploymentUrl ? null : startGateway();
const peerGateway=testGatewayRestart ? startGateway(peerGatewayPort) : null;
let server:Awaited<ReturnType<typeof preview>>|undefined;
let browser:Awaited<ReturnType<typeof chromium.launch>>|undefined;
const traces:[{direction:string;command:string;requestId:number;type:number}[],{direction:string;command:string;requestId:number;type:number}[]]=[[],[]];
const errors:string[]=[];let gameStarted=false;let finished=false;
const testRecovery = process.argv.includes('--reconnect') || testGatewayRestart;
const testManual = process.argv.includes('--manual');
const testBotAudit = process.argv.includes('--audit-bots');
let manualCardReply = false;
const manualDeadlineMs = Number(process.env.TQS_LIVE_DEADLINE_MS ?? '180000');
assert.ok(Number.isSafeInteger(manualDeadlineMs) && manualDeadlineMs >= 30000 && manualDeadlineMs <= 900000,
  'TQS_LIVE_DEADLINE_MS must be a bounded integer between 30000 and 900000');
const candidateId = process.env.TQS_CANDIDATE_ID ?? 'cp08';
assert.match(candidateId,/^cp[0-9]{2}$/);
const errorContexts: unknown[] = [];
let recovered = false;
const pages:Page[]=[];
const currentSockets: unknown[] = [];
const transportOpen = [false,false];
let scenarioClient = 0;
const progressTimer = setInterval(() => console.log(JSON.stringify({stage:finished?'finished':gameStarted?'playing':'login',recovered,
  packets:traces.map(t=>t.length),lastIncoming:traces.map(t=>t.filter(p=>p.direction==='incoming').at(-1)?.command ?? null),errors:errors.length})),60000);
progressTimer.unref();
const scenarioConfig: Record<Exclude<LiveScenario, ''>, {
  general: RegExp; generalId: string; skill: RegExp | null; pack: RegExp; packId: string; requiredCommand: string;
  qaMode?: 'battle-royal-new' | 'battle-royal-old'; sameKingdom?: boolean; capacity?: 2 | 4; requiresGeneral?: boolean;
}> = {
  'draw-sequence': { general: /$^/, generalId: '', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'card-chosen': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: /jianchu|鞬出|Kiền xuất/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForCardChosen' },
  'cards-and-choice': { general: /Tưởng Khâm|蒋钦|Jiang\s*Qin/i, generalId: 'ld__jiangqin', skill: /shangyi|尚义|Thượng nghĩa/i, pack: /^formation$/i, packId: 'formation', requiredCommand: 'AskForCardsAndChoice' },
  'poxi': { general: /Đặng Chi|邓芝|Deng\s*Zhi/i, generalId: 'ty_heg__dengzhi', skill: /weimeng|危盟|Nguy minh/i, pack: /^tenyear_heg$/i, packId: 'tenyear_heg', requiredCommand: 'AskForPoxi' },
  'rescue-normal': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseCard', sameKingdom: true, capacity: 4, requiresGeneral: false },
  'rescue-battle': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: /new_battle_royal|Quyết chiến|鏖战|Rượu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseCard', qaMode: 'battle-royal-new', requiresGeneral: true },
  // Jianan Feng is an unmapped wild caller. Keep this as an explicit probe of
  // the server's real reveal/founding path; it is not evidence until the
  // native rule actually emits and accepts the expected kingdom choice.
  'founding': { general: /Giả Nam Phong|Gia Nam Phong|贾南风|Jianan\s*Feng|Jianan/i, generalId: 'heg__jiananfeng', skill: null, pack: /^zfxp$/i, packId: 'zfxp', requiredCommand: 'AskForChoices', sameKingdom: true },
};
const selectedScenario = testScenario ? scenarioConfig[testScenario] : null;
const nativeQaCatalog = nativeQa
  ? JSON.parse(readFileSync(path.join(repo, 'deploy/freekill-native/qa/tqs_qa/catalog.json'), 'utf8')) as {
      scenarios: { id: string; seed: number; expectedCommand: string }[];
    }
  : null;
const nativeQaPlan = nativeQaCatalog?.scenarios.find((scenario) => scenario.id === testScenario);
if (nativeQa) {
  assert.ok(nativeQaPlan, `Native QA catalog has no scenario ${testScenario}`);
  assert.equal(nativeQaPlan?.expectedCommand, selectedScenario?.requiredCommand,
    `Native/browser expected command drift for ${testScenario}`);
}
const nativeQaRoomName = nativeQa && nativeQaPlan
  ? `TQSQA/${testScenario}/0x${nativeQaPlan.seed.toString(16).padStart(8, '0')}`
  : null;
const pageUrl = selectedScenario && !nativeQa ? (() => {
  const url = new URL(base);
  url.searchParams.set('tqs-qa-general', selectedScenario.generalId);
  url.searchParams.set('tqs-qa-pack', selectedScenario.packId);
  if (selectedScenario.qaMode) url.searchParams.set('tqs-qa-mode', selectedScenario.qaMode);
  if (selectedScenario.sameKingdom) url.searchParams.set('tqs-qa-kingdom', 'same');
  if (selectedScenario.capacity && selectedScenario.capacity !== 2) url.searchParams.set('tqs-qa-capacity', String(selectedScenario.capacity));
  return url.href;
})() : base;
let scenarioCardChosenReply = false;
let scenarioCardChosenHidden = false;
let scenarioPoxiReply = false;
let scenarioPoxiMultiple = false;
let scenarioCardsAndChoiceReply = false;
let scenarioActiveSkillReply = false;
let scenarioRescueReply = false;
let scenarioRescuePeach = false;
let scenarioRescueBlocked = false;
let scenarioViewAsReply = false;
let scenarioBattleRoyalObserved = false;
let scenarioFoundingReply = false;
const scenarioObservations: { command: string; requestId: number; reply: boolean; detail?: string }[] = [];

type PublicBotAudit = {
  logs: string[];
  boardPlayers: string[];
};

const publicSkillLog = /(?:phát động kỹ năng|đã phát động|sử dụng kỹ năng|used skill|发动了|发动技能|发动了技能|발동)/iu;

async function installPublicBotAudit(page: Page) {
  await page.evaluate(String.raw`(() => {
    const audit = { logs: [], boardPlayers: [] };
    const add = (list, value) => {
      const normalized = String(value || '').replace(/\s+/gu, ' ').trim();
      if (!normalized || normalized.length > 1000 || list.includes(normalized)) return;
      if (list.length < 500) list.push(normalized);
    };
    const record = () => {
      document.querySelectorAll('.board-logs li').forEach((node) => add(audit.logs, node.textContent));
      document.querySelectorAll('.board-player-name').forEach((node) => add(audit.boardPlayers, node.textContent));
    };
    record();
    new MutationObserver(record).observe(document.body, { childList: true, characterData: true, subtree: true });
    window.__tqsPublicBotAudit = audit;
  })()`);
}

async function readPublicBotAudit(page: Page): Promise<PublicBotAudit> {
  return page.evaluate(String.raw`(() => window.__tqsPublicBotAudit || { logs: [], boardPlayers: [] })()`) as Promise<PublicBotAudit>;
}

function sanitizePublicAudit(audit: PublicBotAudit, accountNames: string[]) {
  const mask = (value: string) => accountNames.reduce((text, account) => text.split(account).join('[test-account]'), value);
  const logs = audit.logs.map(mask);
  const boardPlayers = [...new Set(audit.boardPlayers.map(mask))];
  const botNames = boardPlayers.filter((name) => /bot|robot|máy|人机|机器人/iu.test(name));
  const skillLogs = logs.filter((log) => publicSkillLog.test(log));
  return { logs, boardPlayers, botNames, skillLogs, botSkillLogs: [] as string[] };
}

function skillActor(log: string) {
  return (log.split(/\s+(?:đã phát động kỹ năng|used skill|发动了(?:技能)?)/iu)[0] ?? '')
    .replace(/\s*\(bạn\)/gu, '').trim();
}

function hasReply(client: number, requestId: number) {
  return traces[client].some((packet) => packet.direction === 'outgoing' &&
    packet.type === CLIENT_REPLY && packet.requestId === requestId);
}

function pendingRequest(client: number) {
  return [...traces[client]]
    .reverse()
    .find((packet) => packet.direction === 'incoming' && (packet.type & 0x100) !== 0 &&
      !hasReply(client, packet.requestId));
}

async function waitForReply(client: number, requestId: number, timeout = 5000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline && !hasReply(client, requestId)) await new Promise((resolve) => setTimeout(resolve, 100));
  return hasReply(client, requestId);
}

const requestAttempts = new Map<number, { count: number; lastAt: number }>();
function shouldAttempt(requestId: number) {
  const now = Date.now();
  const previous = requestAttempts.get(requestId);
  if (previous && (previous.count >= 3 || now - previous.lastAt < 500)) return false;
  requestAttempts.set(requestId, { count: (previous?.count ?? 0) + 1, lastAt: now });
  return true;
}

async function chooseTargetIfNeeded(page: Page) {
  const target = page.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
  if (await target.count() && await target.getAttribute('aria-pressed') !== 'true') await target.click();
}

async function observeBattleRoyal(page: Page) {
  const banner = await page.locator('.board-banners').innerText().catch(() => '');
  if (/Quyết chiến|BattleRoyal|鏖战/i.test(banner)) scenarioBattleRoyalObserved = true;
}

/** Complete the real Lua active-skill scene without inspecting private payloads. */
async function completeActiveSkill(page: Page, client: number, requestId: number, prefer: RegExp | null) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  const skillHeading = controls.locator('h3').filter({ hasText: 'Kỹ năng' });
  const skillButtons = skillHeading.locator('..').getByRole('button');
  const count = await skillButtons.count();
  let clicked = false;
  for (let i = 0; i < count; i++) {
    const button = skillButtons.nth(i);
    if (!await button.isEnabled()) continue;
    const label = await button.innerText();
    if (prefer?.test(label)) { await button.click(); clicked = true; break; }
  }
  // A non-scenario active request must still be completed so that later
  // caller requests are not starved by an unrelated skill scene. Cancel it;
  // selecting an arbitrary SkillButton would change the caller under test.
  if (clicked) {
    // New Battle Royal exposes Peach -> Wine as a view-as skill inside the
    // same AskForUseActiveSkill scene. Selecting the skill alone is not a
    // complete native reply: the scene then enables the eligible Peach card
    // and expects the normal card/target/OK flow.
    if (testScenario === 'rescue-battle' && prefer) {
      const hand = controls.locator('.gameplay-hand button:enabled');
      let selected = false;
      for (let i = 0; i < await hand.count(); i++) {
        if (/Đào|Peach|桃/i.test(await hand.nth(i).innerText())) {
          await hand.nth(i).click();
          selected = true;
          break;
        }
      }
      if (!selected && await hand.count()) await hand.first().click();
    }
    await chooseTargetIfNeeded(page);
    const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
    if (await ok.count() && await ok.isEnabled()) await ok.click();
  } else {
    const cancel = controls.getByRole('button', { name: 'Hủy', exact: true });
    if (await cancel.count() && await cancel.isEnabled()) await cancel.click();
    else {
      const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
      if (await end.count() && await end.isEnabled()) await end.click();
    }
  }
  const replied = await waitForReply(client, requestId);
  if (replied && prefer) scenarioActiveSkillReply = true;
  return replied;
}

async function completeUseCard(page: Page, client: number, requestId: number) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  const sceneText = await controls.innerText().catch(() => '');
  const rescue = /hấp hối|cần hồi|#AskForPeaches|peach|đào/i.test(sceneText);
  let peach = false;
  let viewAs = false;
  let blocked = false;
  if (rescue && testScenario === 'rescue-battle') {
    const skills = controls.locator('h3').filter({ hasText: 'Kỹ năng' }).locator('..').getByRole('button');
    for (let i = 0; i < await skills.count(); i++) {
      const button = skills.nth(i);
      if (await button.isEnabled() && /Quyết chiến|new_battle_royal|鏖战/i.test(await button.innerText())) {
        await button.click();
        viewAs = true;
        await new Promise((resolve) => setTimeout(resolve, 150));
        break;
      }
    }
  }
  const hand = controls.locator('.gameplay-hand button');
  const candidates: number[] = [];
  for (let i = 0; i < await hand.count(); i++) {
    const label = await hand.nth(i).innerText();
    if (/Đào|Peach|桃/i.test(label)) candidates.push(i);
  }
  if (rescue) {
    // Playwright's Locator.isEnabled() is async; keep the selection loop
    // explicit so a battle-royal Peach remains observable while disabled.
    let selected = -1;
    for (const index of candidates) {
      if (await hand.nth(index).isEnabled()) { selected = index; break; }
    }
    if (selected >= 0) {
      await hand.nth(selected).click();
      peach = true;
    } else {
      blocked = candidates.length > 0;
    }
  } else if (await hand.locator(':enabled').count()) {
    await hand.locator(':enabled').first().click();
  }
  if (rescue && !peach && !blocked) blocked = candidates.length === 0;
  if (!rescue) await chooseTargetIfNeeded(page);
  const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
  if (await ok.count() && await ok.isEnabled()) await ok.click();
  else {
    const cancel = controls.getByRole('button', { name: 'Hủy', exact: true });
    if (await cancel.count() && await cancel.isEnabled()) await cancel.click();
  }
  const replied = await waitForReply(client, requestId);
  return { replied, rescue, peach, viewAs, blocked };
}

async function completeNativeDialog(page: Page, client: number, requestId: number) {
  const panel = page.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
  if (!await panel.count()) return false;
  const heading = await panel.locator('h2').innerText().catch(() => '');
  if (heading === 'Sắp xếp bài') {
    // ArrangeCards normally starts with one full group and a required top
    // group. Move the first two cards to the last group until OK is feasible.
    for (let n = 0; n < 2; n++) {
      const source = panel.locator('[role="group"]').first().locator('button.gameplay-choice:enabled').first();
      if (!await source.count()) break;
      await source.click();
      const destination = panel.getByRole('button', { name: /Đặt cuối nhóm 3/ });
      if (await destination.count() && await destination.isEnabled()) await destination.click();
    }
  } else if (heading === 'Xem tướng') {
    // KnownBoth is view-only and has only the OK action.
  } else {
    const choices = panel.locator('button.gameplay-choice:enabled');
    if (await choices.count()) await choices.first().click();
  }
  const ok = panel.getByRole('button', { name: 'Xác nhận', exact: true });
  if (await ok.count() && await ok.isEnabled()) await ok.click();
  else {
    const cancel = panel.getByRole('button', { name: /Bỏ qua|Hủy/ }).first();
    if (await cancel.count() && await cancel.isEnabled()) await cancel.click();
  }
  const replied = await waitForReply(client, requestId);
  if (replied) scenarioObservations.push({ command: 'native-dialog', requestId, reply: true, detail: heading });
  return replied;
}
async function selectPair(page:Page, preferredLabel?:RegExp){
  const group=page.getByRole('group',{name:'Danh sách võ tướng'});await group.waitFor({timeout:60000});
  const buttons=group.getByRole('button');const n=await buttons.count();
  const order:number[]=[];
  let preferredCount=0;
  for(let i=0;i<n;i++) {
    const label=await buttons.nth(i).innerText();
    if (preferredLabel?.test(label)) { preferredCount++; order.unshift(i); } else order.push(i);
  }
  if (preferredLabel && preferredCount === 0) {
    throw new Error('Scenario caller general was not offered by the real server');
  }
  for(const a of order){
    const reset=page.getByRole('button',{name:'Chọn lại'});
    if(await reset.isEnabled())await reset.click();
    await buttons.nth(a).click();
    for(const b of order){
      if(a===b)continue;
      await buttons.nth(b).click();
      if(await page.getByRole('button',{name:'Xác nhận tướng'}).isEnabled()){
        console.log(`Native pair candidate: ${await buttons.nth(a).innerText()} + ${await buttons.nth(b).innerText()}`);
        await page.getByRole('button',{name:'Xác nhận tướng'}).click();return;
      }
    }
  }
  throw new Error('No valid native general pair');
}

async function offersGeneral(page: Page, preferredLabel: RegExp) {
  const group = page.getByRole('group', { name: 'Danh sách võ tướng' });
  await group.waitFor({ timeout: 60000 });
  const labels = await group.getByRole('button').allTextContents();
  return labels.some((label) => preferredLabel.test(label));
}

/** The URL QA plan leaves exactly ten distinct native generals. Both clients
 * still receive the server's normal random five-card offer; the target caller
 * is guaranteed to be offered by one of the two clients, so the runner can
 * drive the actual caller instead of falling back to a random general. */
async function configureScenarioPool(page: Page) {
  if (!selectedScenario || nativeQa) return;
  const checkboxes = page.locator('input[type="checkbox"][data-pack-type="generals"]');
  await checkboxes.first().waitFor({ timeout: 60000 });
  await page.getByRole('button', { name: 'Tạo phòng Quốc Chiến' }).waitFor({ state: 'attached' });
  const warning = page.locator('.pool-warning');
  if (await warning.count() && await warning.isVisible()) {
    throw new Error(`Scenario ${testScenario} deterministic caller pool is invalid: ${await warning.innerText()}`);
  }
  const summary = await page.locator('.pool-summary').innerText();
  const expected = (selectedScenario?.capacity ?? 2) * 5;
  assert.match(summary, new RegExp(`${expected} tướng khác tên`), `Scenario ${testScenario} must leave exactly ${expected} distinct caller-pool generals: ${summary}`);
  console.log(`Scenario ${testScenario}: native caller pool prepared with exactly ${expected} distinct generals`);
}
try{
  const healthDeadline = Date.now() + (deploymentUrl ? 120000 : 10000);
  let healthReady = false;
  while (Date.now() < healthDeadline) {
    if (gateway) assert.equal(gateway.exitCode,null,'Candidate gateway exited');
    try {
      const ready = await fetch(deploymentUrl ? `${base}/gateway/healthz` : `http://127.0.0.1:${gatewayPort}/healthz`,
        { signal: AbortSignal.timeout(Math.min(5000, Math.max(1,healthDeadline-Date.now()))) });
      if (ready.ok && await ready.text()==='ok') { healthReady = true; break; }
    } catch {}
    await new Promise(r=>setTimeout(r, deploymentUrl ? 1000 : 100));
  }
  assert.ok(healthReady,'Candidate health endpoint did not become ready within its bounded startup window');
  if (!deploymentUrl) server=await preview({configFile:false,root:web,build:{outDir:frozenDist},preview:{host:'127.0.0.1',port:webPort,strictPort:true,
    proxy:{'/gateway':{target:`http://127.0.0.1:${gatewayPort}`,ws:true,rewrite:p=>p.replace(/^\/gateway/,'')}}}});
  browser=await chromium.launch({executablePath:chrome,headless:true});
  for(let i=0;i<2;i++){
    const context=await browser.newContext({viewport:{width:390,height:844}});const p=await context.newPage();pages.push(p);
    await p.addInitScript(() => {
      // Opt in to numeric-only WASM/Lua and callback telemetry.
      (window as unknown as { __tqsEnableLuaTelemetry: boolean }).__tqsEnableLuaTelemetry = true;
      const original=console.error;
      const stacks:string[]=[];
      (window as unknown as {__tqsMemoryStacks:string[]}).__tqsMemoryStacks=stacks;
      console.error=(...args:unknown[])=>{
        if(args.some(v=>typeof v==='string' && v.includes('Cannot enlarge memory')))stacks.push(new Error('WASM allocation diagnostic').stack ?? 'no stack');
        original(...args);
      };
    });
    if (testRecovery) await p.addInitScript((peerUrl:string|null) => {
      let active: WebSocket;
      window.WebSocket = new Proxy(window.WebSocket, { construct(Target, args) {
        active = Reflect.construct(Target, peerUrl ? [peerUrl,...args.slice(1)] : args) as WebSocket; return active;
      } });
      (window as unknown as { __tqsTestDisconnect(): void }).__tqsTestDisconnect = () => active.close();
    }, testGatewayRestart && i===1 ? `ws://127.0.0.1:${peerGatewayPort}/ws` : null);
    p.setDefaultTimeout(15000);p.on('pageerror',()=>errors.push(`client-${i+1}: JavaScript error`));
    p.on('console',m=>{if(m.type()==='error'){
      let detail=m.text();for(const value of [first.username,second.username,first.password,second.password])detail=detail.split(value).join('[redacted]');
      errors.push(`client-${i+1}: ${detail.slice(0,1200)}`);
      errorContexts.push({client:i+1,lastIncoming:traces[i].filter(t=>t.direction==='incoming').at(-1)?.command ?? null,location:m.location()});
    } else if (m.type() === 'warning' && m.text().includes('AskForCardsAndChoice')) {
      console.warn(`client-${i+1}: ${m.text().slice(0, 400)}`);
    }});
    p.on('websocket',ws=>{
      currentSockets[i] = ws; transportOpen[i] = true;
      ws.on('close', () => { if (currentSockets[i] === ws) transportOpen[i] = false; });
      const streams={incoming:new PacketStream(),outgoing:new PacketStream()};
      const record = (direction: 'incoming' | 'outgoing', payload: string | Buffer) => {
        if(typeof payload==='string')return;
        for(const packet of streams[direction].push(payload))traces[i].push({direction,command:packet.command,requestId:packet.requestId,type:packet.type});
      };
      ws.on('framereceived',({payload})=>record('incoming',payload));
      ws.on('framesent',({payload})=>record('outgoing',payload));
    });
    await p.goto(pageUrl);await p.getByLabel('Tên tài khoản',{exact:true}).waitFor({timeout:90000});
    const account=i===0?first:second;await p.getByLabel('Tên tài khoản',{exact:true}).fill(account.username);
    await p.getByLabel('Mật khẩu',{exact:true}).fill(account.password);await p.getByRole('button',{name:'Vào sảnh',exact:true}).click();
    await p.getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor({timeout:60000});
    console.log(`PASS client ${i+1}: distinct account authenticated in real lobby`);
  }
  const roomName=nativeQaRoomName ?? `${candidateId.toUpperCase()} multiplayer ${Date.now()}`;const [a,b]=pages;
  const playerCapacity = testBotAudit ? 4 : selectedScenario?.capacity ?? 2;
  await a.getByLabel('Tên phòng',{exact:true}).fill(roomName);await a.getByLabel('Số người',{exact:true}).selectOption(String(playerCapacity));
  await configureScenarioPool(a);
  await a.getByLabel('Thời gian lượt',{exact:true}).selectOption('60');await a.getByRole('button',{name:'Tạo phòng Quốc Chiến'}).click();
  await a.getByRole('heading',{name:roomName,exact:true}).waitFor();await b.getByRole('button',{name:'Làm mới',exact:true}).click();
  await b.locator('.room-item').filter({hasText:roomName}).getByRole('button',{name:'Vào phòng',exact:true}).click();
  await b.getByRole('heading',{name:roomName,exact:true}).waitFor();
  if (playerCapacity > 2) {
    for (let n = 2; n < playerCapacity; n++) {
      await a.getByRole('button',{name:'+ Thêm bot',exact:true}).click();
      await a.waitForFunction((expected) => document.querySelectorAll('.player-item').length === expected, n + 1, { timeout: 30000 });
    }
  }
  await Promise.all(pages.map(p=>p.waitForFunction((expected)=>document.querySelectorAll('.player-item').length===expected, playerCapacity,{timeout:30000})));
  assert.equal(await a.locator('.player-item').count(),playerCapacity);assert.equal(await b.locator('.player-item').count(),playerCapacity);
  await b.getByRole('button',{name:'Sẵn sàng',exact:true}).click();await a.getByRole('button',{name:'Bắt đầu',exact:true}).click();gameStarted=true;
  if (selectedScenario && !nativeQa) {
    if (selectedScenario.requiresGeneral !== false) {
      const offered = await Promise.all(pages.map((page) => offersGeneral(page, selectedScenario.general)));
      assert.ok(offered.some(Boolean), 'Scenario caller general was not offered to either real client');
      scenarioClient = offered[0] ? 0 : 1;
      console.log(`Scenario ${testScenario}: real server offered the caller to client ${scenarioClient + 1}`);
    } else {
      console.log(`Scenario ${testScenario}: no caller general is required; actor remains client 1`);
    }
  }
  await Promise.all(pages.map((page, index) => selectPair(page,
    !nativeQa && selectedScenario && selectedScenario.requiresGeneral !== false && index === scenarioClient ? selectedScenario.general : undefined)));
  for(const p of pages){await p.locator('.game-board').waitFor({timeout:90000});
    await p.waitForFunction((expected)=>document.querySelectorAll('.board-player').length===expected, playerCapacity,{timeout:30000});
    const opponent=p.locator('.board-player:not(.board-self)');assert.equal(await opponent.count(),playerCapacity - 1);
    assert.equal(await opponent.locator('[data-card-id], .gameplay-card').count(),0,'opponent hand IDs must not render');}
  if (testBotAudit) await Promise.all(pages.map(installPublicBotAudit));
  if (selectedScenario) {
    const selfGenerals = await pages[scenarioClient].locator('.board-self .board-generals').innerText().catch(() => '');
    console.log(`Scenario ${testScenario}: ${nativeQa ? 'native QA package injected the server-side precondition; ' : ''}selected self general slots are ${selfGenerals.replace(/\s+/g, ' ').slice(0, 220)}`);
  }
  console.log('PASS both clients: room/join/ready/StartGame/native general pairs; no opponent card IDs in board DOM');
  if (testManual) {
    let actor = pages[scenarioClient];
    let actorTrace = traces[scenarioClient];
    const botPage = pages[1 - scenarioClient];
    await botPage.getByRole('button',{name:'BOT chơi hộ',exact:true}).click();
    const deadline=Date.now()+manualDeadlineMs;
    let printedScenarioSkills = false;
    const rescueScenario = testScenario === 'rescue-normal' || testScenario === 'rescue-battle';
    const selectActiveClient = async () => {
      if (nativeQa) {
        const nativeCommands = new Set(['PlayCard', 'AskForChoices', 'AskForSkillInvoke', 'AskForUseActiveSkill',
          'AskForUseCard', 'AskForResponseCard', 'AskForCardChosen', 'AskForPoxi', 'AskForCardsAndChoice']);
        for (const client of [0, 1]) {
          const request = pendingRequest(client);
          if (request && nativeCommands.has(request.command ?? '')) return client;
        }
      }
      if (!rescueScenario) return scenarioClient;
      for (const client of [scenarioClient, 1 - scenarioClient]) {
        const request = pendingRequest(client);
        if (!request || !['AskForUseCard', 'AskForResponseCard'].includes(request.command ?? '')) continue;
        const controlsText = await pages[client].getByRole('region', { name: 'Điều khiển lượt chơi' }).innerText().catch(() => '');
        if (/hấp hối|cần hồi|#AskForPeaches|peach|đào/i.test(controlsText)) return client;
      }
      return scenarioClient;
    };
    const scenarioDone = () => testScenario === '' ||
      (testScenario === 'draw-sequence' && manualCardReply) ||
      (testScenario === 'card-chosen' && scenarioCardChosenHidden) ||
      (testScenario === 'cards-and-choice' && scenarioCardsAndChoiceReply) ||
      (testScenario === 'poxi' && scenarioPoxiMultiple) ||
      (testScenario === 'rescue-normal' && scenarioRescueReply && scenarioRescuePeach) ||
      (testScenario === 'rescue-battle' && scenarioRescueReply && scenarioRescuePeach && scenarioViewAsReply && scenarioBattleRoyalObserved) ||
      (testScenario === 'founding' && scenarioFoundingReply);
    while(Date.now()<deadline && (!manualCardReply || !scenarioDone())) {
      const activeClient = await selectActiveClient();
      actor = pages[activeClient];
      actorTrace = traces[activeClient];
      await observeBattleRoyal(actor);
      const latest=actorTrace.filter(t=>t.direction==='incoming' && (t.type & 0x100)!==0).at(-1);
      if(latest && actorTrace.some(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY && t.requestId===latest.requestId)) {
        await new Promise(r=>setTimeout(r,250));continue;
      }
      if (latest && !shouldAttempt(latest.requestId)) {
        await new Promise(r=>setTimeout(r,250));
        continue;
      }
      if(latest?.command==='AskForChoices') {
        const choices=actor.getByRole('region',{name:'Lựa chọn trong trận'});
        const choiceText = await choices.innerText().catch(() => '');
        if(await choices.count()) {
          const preferred = (selectedScenario && !(testScenario === 'cards-and-choice' && scenarioActiveSkillReply))
            ? choices.locator('button.gameplay-choice:enabled').filter({ hasText: /revealMain|Lật chủ tướng|主将|main/i }).first()
            : testScenario === 'cards-and-choice'
            ? choices.locator('button.gameplay-choice:enabled').filter({ hasText: /shangyi_card|观看手牌|Xem bài.*tay|bài trên tay/i }).first()
            : choices.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          const option = await preferred.count() ? preferred : choices.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          if(await option.count())await option.click();
          const confirm=choices.getByRole('button',{name:'Xác nhận lựa chọn',exact:true});
          if(await confirm.count() && await confirm.isEnabled()) {
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied && /lập quốc|quốc hiệu|founding|wild-choose|建国/i.test(choiceText)) scenarioFoundingReply = true;
            scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
              detail: /lập quốc|quốc hiệu|founding|wild-choose|建国/i.test(choiceText) ? 'founding-kingdom' :
                testScenario === 'cards-and-choice' ? 'shangyi_card choice' : 'choice'});
          }
        }
      } else if(latest?.command==='AskForSkillInvoke') {
        const invokeText = await actor.locator('.request-panel').innerText().catch(() => '');
        const isCardChosenInvoke = /jianchu|鞬出|Kiền xuất/i.test(invokeText);
        const isScenarioSkillInvoke = !!selectedScenario?.skill && selectedScenario.skill.test(invokeText);
        // A manual run may encounter unrelated optional skills while the
        // target prompt is still pending. Only invoke the requested caller
        // skill; cancel everything else so it cannot starve a native choice.
        const shouldInvoke = testScenario === 'card-chosen'
          ? isCardChosenInvoke
          : isScenarioSkillInvoke;
        const choice = shouldInvoke
          ? actor.locator('.request-panel').getByRole('button', { name: 'Kích hoạt', exact: true })
          : actor.locator('.request-panel').getByRole('button', { name: /^(Bỏ qua|Hủy)$/ });
        if(await choice.count() && await choice.isEnabled())await choice.click();
        const replied = await waitForReply(activeClient, latest.requestId);
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: shouldInvoke ? (isCardChosenInvoke ? 'invoke-jianchu' : 'invoke-scenario-skill') : 'cancel-other-skill'});
      } else if(latest?.command==='AskForUseActiveSkill') {
        const activeSkill = testScenario === 'rescue-battle'
          ? selectedScenario?.skill ?? null
          : testScenario === 'cards-and-choice' || testScenario === 'poxi'
            ? selectedScenario?.skill ?? null : null;
        const replied = await completeActiveSkill(actor, activeClient, latest.requestId, activeSkill);
        if (replied && testScenario === 'rescue-battle' && activeSkill) scenarioViewAsReply = true;
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: activeSkill?.source ?? 'cancel'});
      } else if(latest?.command==='AskForUseCard' || latest?.command==='AskForResponseCard') {
        const result = await completeUseCard(actor, activeClient, latest.requestId);
        if (result.rescue && result.replied) scenarioRescueReply = true;
        if (result.rescue && result.peach && result.replied) scenarioRescuePeach = true;
        if (result.rescue && result.blocked) scenarioRescueBlocked = true;
        if (result.viewAs && result.replied) scenarioViewAsReply = true;
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: result.replied,
          detail: result.rescue ? result.viewAs ? 'rescue-peach-view-as' : result.peach ? 'rescue-peach' : result.blocked ? 'rescue-peach-blocked' : 'rescue-no-peach' : undefined});
      } else if(latest?.command==='AskForCardChosen') {
        const panel=actor.getByRole('region',{name:'Chọn bài đối thủ'});
        const options=panel.locator('button.gameplay-choice:enabled');
        const labels=await options.allTextContents();
        const hiddenIndex=labels.findIndex((label)=>/Bài úp/i.test(label.trim()));
        const option=options.nth(hiddenIndex >= 0 ? hiddenIndex : 0);
        if(await option.count())await option.click();
        const replied = await waitForReply(activeClient, latest.requestId);
        if (replied) {
          scenarioCardChosenReply=true;
          if (hiddenIndex >= 0) scenarioCardChosenHidden=true;
          scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
            detail: hiddenIndex >= 0 ? 'hidden-card' : 'public-card'});
        }
      } else if(latest?.command==='AskForPoxi') {
        const panel=actor.getByRole('region',{name:'Chọn bài đối thủ'});
        const cards=panel.locator('[role="group"] button.gameplay-choice:enabled');
        let selectedCount=0;
        for(let n=0;n<2;n++) {
          const count=await cards.count(); let clicked=false;
          for(let i=0;i<count;i++) {
            const candidate=cards.nth(i);
            if(await candidate.getAttribute('aria-pressed') !== 'true') { await candidate.click(); clicked=true; selectedCount++; break; }
          }
          if(!clicked)break;
          await new Promise(r=>setTimeout(r,100));
        }
        if(selectedCount>0) {
          const confirm=panel.getByRole('button',{name:'Xác nhận chọn bài',exact:true});
          if(await confirm.count() && await confirm.isEnabled()) {
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              scenarioPoxiReply=true;
              if (selectedCount >= 2) scenarioPoxiMultiple=true;
              scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
                detail: `selected-${selectedCount}`});
            }
          }
        }
      } else if(latest?.command==='AskForCardsAndChoice') {
        const panel=actor.getByRole('region',{name:'Xem bài và chọn phương án'});
        let ready = true;
        try { await panel.waitFor({ state: 'visible', timeout: 3000 }); }
        catch { ready = false; }
        if (!ready) {
          scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: false,
            detail: 'panel-missing'});
        } else {
          const cards=panel.locator('[role="group"] button.gameplay-choice:enabled');
          if(await cards.count())await cards.first().click();
          const enabledChoices=panel.locator('.request-actions button.button.primary:enabled').first();
          if(await enabledChoices.count()) {
            await enabledChoices.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
              detail: replied ? `cards-${await panel.locator('[role="group"] .gameplay-choice').count()}` : 'reply-missing'});
            if (replied) scenarioCardsAndChoiceReply=true;
          } else {
            const cancel=panel.locator('.request-actions button.button.secondary:enabled').first();
            if(await cancel.count())await cancel.click();
            scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: false,
              detail: `no-enabled-choice cards-${await panel.locator('[role="group"] .gameplay-choice').count()}`});
          }
        }
      } else if(['AskForArrangeCards','AskForAG','CustomDialog','AskForGeneral','AskForMoveCardInBoard'].includes(latest?.command ?? '')) {
        await completeNativeDialog(actor, activeClient, latest.requestId);
      } else if(latest?.command==='PlayCard') {
        const controls=actor.getByRole('region',{name:'Điều khiển lượt chơi'});
        const skillHeading=controls.locator('h3').filter({hasText:'Kỹ năng'});
        if (selectedScenario && !printedScenarioSkills) {
          printedScenarioSkills = true;
          console.log(`Scenario ${testScenario} first PlayCard skills: ${(await skillHeading.locator('..').getByRole('button').allTextContents()).join(' | ') || '(none)'}`);
        }
        const activeScenario = testScenario === 'card-chosen' ? null : selectedScenario;
        const desiredSkill=activeScenario?.skill ? skillHeading.locator('..').getByRole('button').filter({hasText:activeScenario.skill}).first() : null;
        if(desiredSkill && await desiredSkill.count() && await desiredSkill.isEnabled()) {
          await desiredSkill.click();
          await chooseTargetIfNeeded(actor);
          const confirm=controls.getByRole('button',{name:'Xác nhận',exact:true});
          if(await confirm.count() && await confirm.isEnabled())await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if(replied) {
            scenarioActiveSkillReply=true;
            scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'active-skill'});
          }
          manualCardReply=manualCardReply || replied;
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        const hand=controls.locator('.gameplay-hand button:enabled');
        const preferred:number[]=[];const fallback:number[]=[];
        for(let i=0;i<await hand.count();i++) {
          const label=await hand.nth(i).innerText();
          (testScenario === 'card-chosen' && /Sát|杀|Slash/i.test(label) ? preferred : fallback).push(i);
        }
        for(const i of [...preferred,...fallback]) {
          const card=hand.nth(i);await card.click();
          const target=actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          if(await target.count() && await target.first().getAttribute('aria-pressed')!=='true')await target.first().click();
          const confirm=actor.getByRole('region',{name:'Điều khiển lượt chơi'}).getByRole('button',{name:'Xác nhận',exact:true});
          if(await confirm.count() && await confirm.isEnabled()) {
            await confirm.click();
            manualCardReply=await waitForReply(scenarioClient, latest.requestId);
            if(manualCardReply)break;
          }
          if(await card.count() && await card.getAttribute('aria-pressed')==='true')await card.click();
        }
        if(!manualCardReply) {
          const end=actor.getByRole('region',{name:'Điều khiển lượt chơi'}).getByRole('button',{name:'Kết thúc lượt',exact:true});
          if(await end.count() && await end.isEnabled())await end.click();
        }
      }
      await new Promise(r=>setTimeout(r,250));
    }
    assert.ok(manualCardReply,'A native PlayCard must receive one user-selected card/target/OK reply');
    console.log('PASS manual native PlayCard: offered card, Lua-enabled target/OK and one exact client reply');
    if (testScenario === 'card-chosen') {
      assert.ok(scenarioCardChosenHidden,'card-chosen scenario must receive and answer hidden AskForCardChosen on the real server');
      console.log('PASS card-chosen scenario: Bàng Đức/jianchu reached hidden AskForCardChosen and received one exact reply');
    } else if (testScenario === 'cards-and-choice') {
      assert.ok(scenarioCardsAndChoiceReply,'cards-and-choice scenario must receive and answer AskForCardsAndChoice on the real server');
      console.log('PASS cards-and-choice scenario: Tưởng Khâm/shangyi reached AskForCardsAndChoice and received one exact reply');
    } else if (testScenario === 'poxi') {
      assert.ok(scenarioPoxiReply && scenarioPoxiMultiple,'poxi scenario must receive and answer AskForPoxi with multiple selected cards on the real server');
      console.log('PASS Poxi scenario: Đặng Chi/weimeng reached AskForPoxi and received a multi-card reply');
    } else if (testScenario === 'rescue-normal') {
      assert.ok(scenarioRescueReply && scenarioRescuePeach,
        'normal rescue scenario must receive AskForPeaches and answer with an enabled Peach');
      assert.equal(scenarioBattleRoyalObserved, false, 'normal rescue QA room must not enter Battle Royal');
      console.log('PASS normal rescue scenario: native Peach rescued the dying player outside Battle Royal');
    } else if (testScenario === 'rescue-battle') {
      assert.ok(scenarioRescueReply && scenarioRescuePeach && scenarioViewAsReply && scenarioBattleRoyalObserved,
        'Battle Royal rescue scenario must observe the mode, convert Peach through the native view-as skill and reply');
      console.log('PASS Battle Royal rescue scenario: ordinary Peach was blocked and native Quyết chiến converted Peach to Wine for rescue');
    } else if (testScenario === 'founding') {
      assert.ok(scenarioFoundingReply, 'founding scenario must receive and answer the native kingdom choice');
      console.log('PASS founding scenario: real wild general reached the native Vietnamese kingdom choice');
    }
    const trust=actor.getByRole('button',{name:'BOT chơi hộ',exact:true});if(await trust.isVisible())await trust.click();
  } else await Promise.all(pages.map(p=>p.getByRole('button',{name:'BOT chơi hộ',exact:true}).click()));
  if (testRecovery) {
    const recovering = [a];
    if (testGatewayRestart) {
      assert.ok(gateway);
      const exited = once(gateway,'exit');gateway.kill('SIGTERM');await exited;
      gateway=startGateway();
      assert.equal(transportOpen[1],true,'Independent peer must remain connected during restart');
      console.log('Restarted first client gateway process; second peer keeps its separate gateway connection');
    } else await a.evaluate(() => (window as unknown as { __tqsTestDisconnect(): void }).__tqsTestDisconnect());
    for (const p of recovering) {
      const client=pages.indexOf(p);
      await p.waitForFunction(() => document.querySelector('.status')?.textContent === 'Đã kết nối', null, { timeout: 120000 });
      for (let n=0;n<120 && !traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect');n++)
        await new Promise(resolve=>setTimeout(resolve,500));
      assert.ok(traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'server must send native Reconnect after transport loss');
      await p.locator('.board-self').waitFor({timeout:30000});
      await p.waitForFunction((expected)=>document.querySelectorAll('.board-player').length===expected, playerCapacity,{timeout:30000});
      assert.equal(await p.locator('.board-player').count(),playerCapacity);
      assert.equal(await p.locator('.board-player:not(.board-self) [data-card-id]').count(),0);
      const trust=p.getByRole('button',{name:'BOT chơi hộ',exact:true});if(await trust.isVisible())await trust.click();
    }
    if(testGatewayRestart) {assert.equal(transportOpen[1],true);assert.ok(!traces[1].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'Independent peer must not reconnect');}
    recovered=true;
    console.log(testGatewayRestart ? 'PASS gateway restart: first account reauthenticates/native Reconnect/private board, independent peer stays connected' : 'PASS controlled transport loss: same account automatically authenticates, receives native Reconnect and restores the two-seat board');
  }
  await Promise.all(pages.map(p=>p.getByRole('button',{name:'Về sảnh',exact:true}).waitFor({timeout:900000})));finished=true;
  let publicBotAudit = testBotAudit
    ? (await Promise.all(pages.map(readPublicBotAudit))).map((audit) => sanitizePublicAudit(audit, [first.username, second.username]))
    : [];
  if (testBotAudit) {
    // A skill log rendered with “(bạn)” is the local real client. Merge that
    // actor identity across both client views; the same public log is rendered
    // without the marker for the other client. Remaining skill actors are
    // native bot/AI seats in this four-seat room.
    const humanSkillActors = new Set(publicBotAudit.flatMap((audit) => audit.skillLogs
      .filter((log) => /\(bạn\)/u.test(log)).map(skillActor).filter(Boolean)));
    publicBotAudit = publicBotAudit.map((audit) => ({
      ...audit,
      humanSkillActors: [...humanSkillActors],
      botSkillLogs: audit.skillLogs.filter((log) => !humanSkillActors.has(skillActor(log))),
    }));
  }
  const botAuditTrace = traces.map((trace) => {
    const incoming = trace.filter((packet) => packet.direction === 'incoming');
    return {
      gameOver: incoming.filter((packet) => packet.command === 'GameOver').length,
      gameLog: incoming.filter((packet) => packet.command === 'GameLog').length,
      addSkillUseHistory: incoming.filter((packet) => packet.command === 'AddSkillUseHistory').length,
      setSkillUseHistory: incoming.filter((packet) => packet.command === 'SetSkillUseHistory').length,
      setSkillBranchUseHistory: incoming.filter((packet) => packet.command === 'SetSkillBranchUseHistory').length,
      askForSkillInvoke: incoming.filter((packet) => packet.command === 'AskForSkillInvoke').length,
      askForUseActiveSkill: incoming.filter((packet) => packet.command === 'AskForUseActiveSkill').length,
    };
  });
  if (testBotAudit) {
    assert.equal(playerCapacity, 4, 'Bot audit must be a four-seat room');
    assert.ok(publicBotAudit.every((audit) => audit.logs.length > 0), 'Bot audit must observe public GameLog text');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1), 'Every live client must observe exactly one GameOver');
    assert.ok(botAuditTrace.some((trace) => trace.addSkillUseHistory + trace.setSkillUseHistory > 0),
      'Bot audit must observe native skill-history state updates');
    console.log(`PASS four-seat bot audit: ${pages.length} real clients + ${playerCapacity - pages.length} native bots; ` +
      `${publicBotAudit[0]?.skillLogs.length ?? 0} public skill log(s), ` +
      `${publicBotAudit[0]?.botSkillLogs.length ?? 0} attributed to bot name(s)`);
  }
  for(let i=0;i<2;i++){
    assert.ok(traces[i].some(t=>t.direction==='incoming' && t.command==='GameOver'));
    const replies=traces[i].filter(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY);
    assert.equal(new Set(replies.map(t=>t.requestId)).size,replies.length,'one reply per request');
    await pages[i].getByRole('button',{name:'Về sảnh',exact:true}).click();
    await pages[i].getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor();
    await pages[i].getByRole('button',{name:'Ngắt kết nối',exact:true}).click();
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`${candidateId}-${testScenario ? `${testScenario}-` : ''}${testGatewayRestart?'gateway-restart':testRecovery?'reconnect':'multiplayer'}-live-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),manualCardReply,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioBattleRoyalObserved,scenarioFoundingReply,scenarioObservations,botAudit:testBotAudit ? {seatCapacity:playerCapacity,realClientSeats:pages.length,nativeBotSeats:playerCapacity-pages.length,trace:botAuditTrace,public:publicBotAudit} : null,scope:testGatewayRestart ? 'two real accounts / first client isolated gateway process restart / native Reconnect / independent second gateway peer / Chrome mobile viewports / Trust; no physical device or hosted restart' : testRecovery ? 'two real accounts / controlled WebSocket close / native server Reconnect / Chrome mobile viewports / Trust; no physical network or device' : testBotAudit ? 'four seats / two real accounts / two native server bots / public GameLog and skill-history audit / native Trust; no physical device' : 'two real accounts / two Chrome mobile viewports / native Trust; no physical device', recovered,gatewayRestart:testGatewayRestart,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks:string[]}).__tqsMemoryStacks))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null))),
    distIndexSha256,candidateIdentity,qaPackageIdentity,result:errors.length ? 'FAIL' : 'PASS',deploymentUrl:deploymentUrl ?? null,traces,errors,errorContexts},null,2));
  assert.deepEqual(errors,[]);
  console.log('PASS both clients: real GameOver / result / lobby / clean disconnect; sanitized trace saved');
}catch(e){
  console.error('FAIL two-client candidate verification:', (e as Error).message.split(first.username).join('[account]').split(second.username).join('[account]').split(first.password).join('[redacted]').split(second.password).join('[redacted]'));
  const feedback:string[]=[];
  for (const p of pages) {
    for (let message of await p.locator('.error-notice').allTextContents().catch(()=>[])) {
      for (const value of [first.username,second.username,first.password,second.password]) message=message.split(value).join('[redacted]');
      feedback.push(message.slice(0,600));
      console.error('Visible application feedback:',message.slice(0,600));
    }
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`reconnect-failure-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),result:'FAIL',candidateId,deploymentUrl:deploymentUrl ?? null,feedback,distIndexSha256,candidateIdentity,qaPackageIdentity,recovered,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioFoundingReply,scenarioObservations,traces,errors,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks?:string[]}).__tqsMemoryStacks ?? []).catch(()=>[]))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null).catch(()=>null))),
    errorContexts,scope:'metadata and numeric heap/callback telemetry only; pending safe GameOver cleanup'},null,2));
  if(gameStarted && !finished){
    console.error('Preserving the connected test browser and candidate processes until GameOver; no forced mid-game disconnect');
    for(const p of pages)await p.getByRole('button',{name:'BOT chơi hộ',exact:true}).click({timeout:3000}).catch(()=>{});
    // GameOver belongs to the shared room. A disconnected participant may never
    // render the result panel, so do not wait forever for that DOM after a failure.
    const backInLobby = (client:number) => {
      const incoming=traces[client].filter(t=>t.direction==='incoming');
      const lastStart=incoming.reduce((last,t,i)=>t.command==='StartGame'?i:last,-1);
      const lastLobby=incoming.reduce((last,t,i)=>t.command==='EnterLobby'?i:last,-1);
      return lastStart>=0 && lastLobby>lastStart;
    };
    while (!traces.some(t=>t.some(p=>p.direction==='incoming' && p.command==='GameOver')) &&
      transportOpen.some((open,i)=>open && !backInLobby(i)))
      await new Promise(resolve=>setTimeout(resolve,1000));
  }
  process.exitCode=1;
}finally{
  clearInterval(progressTimer);
  await browser?.close();await new Promise<void>(resolve=>server?server.httpServer.close(()=>resolve()):resolve());
  gateway?.kill('SIGTERM');peerGateway?.kill('SIGTERM');
  rmSync(frozenDist,{recursive:true,force:true});
}
