/** Two distinct private test accounts, one frozen candidate, real C++ server.
 * Only command/request metadata is persisted; credentials and game payloads stay in memory. */
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { existsSync, readFileSync, writeFileSync, statSync, mkdirSync, cpSync, mkdtempSync, rmSync, readdirSync } from 'node:fs';
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

type LiveScenario = '' | 'draw-sequence' | 'card-chosen' | 'cards-and-choice' | 'poxi' | 'rescue-normal' | 'rescue-battle' | 'founding' | 'fazheng-enyuan' | 'hidden-yiji' | 'hidden-yiji-deputy' | 'hidden-rehide-yiji' | 'hidden-rehide-yiji-deputy' | 'hidden-jianxiong' | 'hidden-jianxiong-deputy' | 'hidden-fankui' | 'hidden-fankui-deputy' | 'hidden-reveal' | 'hidden-reveal-deputy' | 'hidden-active' | 'hidden-active-main' | 'hidden-fanjian' | 'hidden-fanjian-deputy' | 'hidden-view-as' | 'hidden-view-as-main' | 'hidden-dual' | 'hidden-luoshen' | 'hidden-luoshen-deputy' | 'hidden-tiandu' | 'hidden-tiandu-deputy' | 'hidden-jizhi' | 'hidden-jizhi-deputy' | 'hidden-mingshi' | 'hidden-mingshi-deputy' | 'hidden-gongqing' | 'hidden-gongqing-deputy' | 'hidden-qianxun' | 'hidden-qianxun-deputy' | 'hidden-qianxun-indulgence' | 'hidden-qianxun-indulgence-deputy' | 'hidden-kongcheng' | 'hidden-kongcheng-deputy' | 'hidden-weimu' | 'hidden-weimu-deputy' | 'hidden-weimu-indulgence' | 'hidden-weimu-indulgence-deputy' | 'hidden-xiaoji' | 'hidden-xiaoji-deputy' | 'hidden-guanxing' | 'hidden-guanxing-deputy' | 'hidden-yingzi' | 'hidden-yingzi-deputy' | 'hidden-tianxiang' | 'hidden-tianxiang-deputy' | 'hidden-duanchang' | 'hidden-duanchang-deputy' | 'hidden-liegong' | 'hidden-liegong-deputy' | 'hidden-kuanggu' | 'hidden-kuanggu-deputy' | 'hidden-jueqing' | 'hidden-jueqing-deputy';
const testScenario = (process.env.TQS_LIVE_SCENARIO ?? (process.argv.includes('--card-chosen') ? 'card-chosen' : '')) as LiveScenario;
assert.ok(testScenario === '' || testScenario === 'draw-sequence' || testScenario === 'card-chosen' || testScenario === 'cards-and-choice' || testScenario === 'poxi' ||
  testScenario === 'rescue-normal' || testScenario === 'rescue-battle' || testScenario === 'founding' || testScenario === 'fazheng-enyuan' ||
  testScenario === 'hidden-yiji' || testScenario === 'hidden-yiji-deputy' || testScenario === 'hidden-rehide-yiji' || testScenario === 'hidden-rehide-yiji-deputy' || testScenario === 'hidden-reveal' ||
  testScenario === 'hidden-jianxiong' || testScenario === 'hidden-jianxiong-deputy' || testScenario === 'hidden-fankui' || testScenario === 'hidden-fankui-deputy' || testScenario === 'hidden-reveal-deputy' || testScenario === 'hidden-active' || testScenario === 'hidden-active-main' || testScenario === 'hidden-fanjian' || testScenario === 'hidden-fanjian-deputy' ||
  testScenario === 'hidden-view-as' || testScenario === 'hidden-view-as-main' || testScenario === 'hidden-dual' ||
  testScenario === 'hidden-luoshen' || testScenario === 'hidden-luoshen-deputy' ||
  testScenario === 'hidden-tiandu' || testScenario === 'hidden-tiandu-deputy' ||
  testScenario === 'hidden-jizhi' || testScenario === 'hidden-jizhi-deputy' ||
  testScenario === 'hidden-mingshi' || testScenario === 'hidden-mingshi-deputy' ||
  testScenario === 'hidden-gongqing' || testScenario === 'hidden-gongqing-deputy' ||
  testScenario === 'hidden-qianxun' || testScenario === 'hidden-qianxun-deputy' ||
  testScenario === 'hidden-qianxun-indulgence' || testScenario === 'hidden-qianxun-indulgence-deputy' ||
  testScenario === 'hidden-kongcheng' || testScenario === 'hidden-kongcheng-deputy' ||
  testScenario === 'hidden-weimu' || testScenario === 'hidden-weimu-deputy' ||
  testScenario === 'hidden-weimu-indulgence' || testScenario === 'hidden-weimu-indulgence-deputy' ||
  testScenario === 'hidden-xiaoji' || testScenario === 'hidden-xiaoji-deputy' ||
  testScenario === 'hidden-guanxing' || testScenario === 'hidden-guanxing-deputy' ||
  testScenario === 'hidden-yingzi' || testScenario === 'hidden-yingzi-deputy' ||
  testScenario === 'hidden-tianxiang' || testScenario === 'hidden-tianxiang-deputy' ||
  testScenario === 'hidden-duanchang' || testScenario === 'hidden-duanchang-deputy' ||
  testScenario === 'hidden-liegong' || testScenario === 'hidden-liegong-deputy' ||
  testScenario === 'hidden-kuanggu' || testScenario === 'hidden-kuanggu-deputy' ||
  testScenario === 'hidden-jueqing' || testScenario === 'hidden-jueqing-deputy',
  'TQS_LIVE_SCENARIO must be empty, draw-sequence, card-chosen, cards-and-choice, poxi, rescue-normal, rescue-battle, founding, fazheng-enyuan, hidden-yiji, hidden-yiji-deputy, hidden-rehide-yiji, hidden-rehide-yiji-deputy, hidden-jianxiong, hidden-jianxiong-deputy, hidden-fankui, hidden-fankui-deputy, hidden-reveal, hidden-reveal-deputy, hidden-active, hidden-active-main, hidden-fanjian, hidden-fanjian-deputy, hidden-view-as, hidden-view-as-main, hidden-dual, hidden-luoshen, hidden-luoshen-deputy, hidden-tiandu, hidden-tiandu-deputy, hidden-jizhi, hidden-jizhi-deputy, hidden-mingshi, hidden-mingshi-deputy, hidden-gongqing, hidden-gongqing-deputy, hidden-qianxun, hidden-qianxun-deputy, hidden-qianxun-indulgence, hidden-qianxun-indulgence-deputy, hidden-kongcheng, hidden-kongcheng-deputy, hidden-weimu, hidden-weimu-deputy, hidden-weimu-indulgence, hidden-weimu-indulgence-deputy, hidden-xiaoji, hidden-xiaoji-deputy, hidden-guanxing, hidden-guanxing-deputy, hidden-yingzi, hidden-yingzi-deputy, hidden-tianxiang, hidden-tianxiang-deputy, hidden-duanchang, hidden-duanchang-deputy, hidden-liegong, hidden-liegong-deputy, hidden-kuanggu, hidden-kuanggu-deputy, hidden-jueqing or hidden-jueqing-deputy');
// These scenarios deliberately require an explicit opt-in: an interrupted
// active room can create a server-side runner and trigger the upstream IP
// temporary-ban policy. Local fixtures remain enabled independently.
const experimentalScenariosEnabled = process.env.TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS === '1';
assert.ok(!testScenario || experimentalScenariosEnabled,
  'Experimental live scenarios are temporarily locked; set TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 only after broad deployment');
const nativeQa = process.env.TQS_LIVE_NATIVE_QA === '1';
assert.ok(!nativeQa || !!testScenario, 'TQS_LIVE_NATIVE_QA=1 requires TQS_LIVE_SCENARIO');
assert.ok(testScenario !== 'fazheng-enyuan' || (nativeQa && process.argv.includes('--manual')),
  'fazheng-enyuan requires native QA and --manual to select both optional reactions');
assert.ok(!['hidden-yiji', 'hidden-yiji-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-yiji scenarios require native QA and --manual to control the prelight gate');
assert.ok(!['hidden-rehide-yiji', 'hidden-rehide-yiji-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-rehide-yiji scenarios require native QA and --manual to control the prelight and re-hide path');
assert.ok(!['hidden-jianxiong', 'hidden-jianxiong-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-jianxiong scenarios require native QA and --manual to control the prelight and choice path');
assert.ok(!['hidden-fankui', 'hidden-fankui-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-fankui scenarios require native QA and --manual to control the prelight, damage and card-choice path');
assert.ok(!['hidden-reveal', 'hidden-reveal-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-reveal scenarios require native QA and --manual to control the active reveal helper');
assert.ok(!['hidden-active', 'hidden-active-main'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-active scenarios require native QA and --manual to control the native PlayCard skill selection');
assert.ok(!['hidden-fanjian', 'hidden-fanjian-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-fanjian scenarios require native QA and --manual to control the native PlayCard and target-choice path');
assert.ok(!['hidden-view-as', 'hidden-view-as-main'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-view-as scenarios require native QA and --manual to control the native PlayCard skill selection');
assert.ok(testScenario !== 'hidden-dual' || (nativeQa && process.argv.includes('--manual')),
  'hidden-dual requires native QA and --manual to control the prelight, target, discard and PlayCard path');
assert.ok(!['hidden-luoshen', 'hidden-luoshen-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-luoshen scenarios require native QA and --manual to control the prelight and phase-start judgment path');
assert.ok(!['hidden-tiandu', 'hidden-tiandu-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-tiandu scenarios require native QA and --manual to control the prelight and FinishJudge path');
assert.ok(!['hidden-jizhi', 'hidden-jizhi-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-jizhi scenarios require native QA and --manual to control the prelight, Duel and optional draw path');
assert.ok(!['hidden-mingshi', 'hidden-mingshi-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-mingshi scenarios require native QA and --manual to control the prelight and hidden-source Slash path');
assert.ok(!['hidden-gongqing', 'hidden-gongqing-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-gongqing scenarios require native QA and --manual to control the prelight and both attack-range branches');
assert.ok(!['hidden-qianxun', 'hidden-qianxun-deputy', 'hidden-qianxun-indulgence', 'hidden-qianxun-indulgence-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-qianxun scenarios require native QA and --manual to control the prelight and Snatch/Indulgence cancellation path');
assert.ok(!['hidden-kongcheng', 'hidden-kongcheng-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-kongcheng scenarios require native QA and --manual to control the prelight and Duel cancellation path');
assert.ok(!['hidden-weimu', 'hidden-weimu-deputy', 'hidden-weimu-indulgence', 'hidden-weimu-indulgence-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-weimu scenarios require native QA and --manual to control the prelight and black Trick cancellation path');
assert.ok(!['hidden-xiaoji', 'hidden-xiaoji-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-xiaoji scenarios require native QA and --manual to control the prelight and equipment-loss path');
assert.ok(!['hidden-guanxing', 'hidden-guanxing-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-guanxing scenarios require native QA and --manual to control the prelight and arrange path');
assert.ok(!['hidden-yingzi', 'hidden-yingzi-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-yingzi scenarios require native QA and --manual to control the prelight and DrawNCards path');
assert.ok(!['hidden-tianxiang', 'hidden-tianxiang-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-tianxiang scenarios require native QA and --manual to control the prelight, card/target and choice path');
assert.ok(!['hidden-duanchang', 'hidden-duanchang-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-duanchang scenarios require native QA and --manual to control the prelight and death-choice path');
assert.ok(!['hidden-liegong', 'hidden-liegong-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-liegong scenarios require native QA and --manual to control the prelight, Slash and damage-choice path');
assert.ok(!['hidden-kuanggu', 'hidden-kuanggu-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-kuanggu scenarios require native QA and --manual to control the prelight, damage and choice path');
assert.ok(!['hidden-jueqing', 'hidden-jueqing-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-jueqing scenarios require native QA and --manual to control the prelight and damage path');
const hiddenYijiMode = process.env.TQS_LIVE_HIDDEN_YIJI_MODE ?? 'positive';
assert.ok(hiddenYijiMode === 'negative' || hiddenYijiMode === 'positive' || hiddenYijiMode === 'skip',
  'TQS_LIVE_HIDDEN_YIJI_MODE must be negative, positive or skip');
assert.ok(!['hidden-yiji', 'hidden-yiji-deputy'].includes(testScenario) || process.env.TQS_LIVE_HIDDEN_YIJI_MODE,
  'hidden-yiji scenarios require an explicit TQS_LIVE_HIDDEN_YIJI_MODE so the evidence names its branch');

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
if (qaPackageIdentity) {
  const catalogHash = createHash('sha256')
    .update(readFileSync(path.join(repo, 'deploy/freekill-native/qa/tqs_qa/catalog.json'))).digest('hex');
  assert.equal(qaPackageIdentity.catalogSha256, catalogHash,
    'Installed native QA catalog is stale; install and verify this source before running the scenario');
}
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
  packets:traces.map(t=>t.length),lastIncoming:traces.map(t=>t.filter(p=>p.direction==='incoming').at(-1)?.command ?? null),
  nativeQaGateSeen,errors:errors.length})),60000);
progressTimer.unref();
const scenarioConfig: Record<Exclude<LiveScenario, ''>, {
  general: RegExp; generalId: string; skill: RegExp | null; pack: RegExp; packId: string; requiredCommand: string;
  qaMode?: 'battle-royal-new' | 'battle-royal-old'; sameKingdom?: boolean; capacity?: 2 | 4; requiresGeneral?: boolean;
}> = {
  'draw-sequence': { general: /$^/, generalId: '', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'card-chosen': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: /jianchu|鞬出|Kiền xuất/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForCardChosen' },
  'cards-and-choice': { general: /Tưởng Khâm|蒋钦|Jiang\s*Qin/i, generalId: 'ld__jiangqin', skill: /shangyi|尚义|Thượng nghĩa/i, pack: /^formation$/i, packId: 'formation', requiredCommand: 'AskForCardsAndChoice' },
  'poxi': { general: /Đặng Chi|邓芝|Deng\s*Zhi/i, generalId: 'ty_heg__dengzhi', skill: /weimeng|危盟|Nguy minh/i, pack: /^tenyear_heg$/i, packId: 'tenyear_heg', requiredCommand: 'AskForPoxi' },
  'rescue-normal': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseCard', sameKingdom: true, capacity: 2, requiresGeneral: false },
  'rescue-battle': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: /new_battle_royal|Quyết chiến|鏖战|Rượu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseCard', qaMode: 'battle-royal-new', requiresGeneral: true },
  // Jianan Feng is an unmapped wild caller. Keep this as an explicit probe of
  // the server's real reveal/founding path; it is not evidence until the
  // native rule actually emits and accepts the expected kingdom choice.
  'founding': { general: /Giả Nam Phong|Gia Nam Phong|贾南风|Jianan\s*Feng|Jianan/i, generalId: 'heg__jiananfeng', skill: null, pack: /^zfxp$/i, packId: 'zfxp', requiredCommand: 'AskForChoices', sameKingdom: true },
  // Native QA fixes both players' pairs at GamePrepared. The URL-side pool
  // is intentionally unused for this scenario; the regexes document the
  // roster expected on the real board after the director reveals it.
  'fazheng-enyuan': { general: /Pháp Chính|法正|Fa\s*Zheng/i, generalId: 'ld__fazheng', skill: /Ân Oán|恩怨|enyuan|Di Kế|遗计|yiji|Phản Quỹ|反馈|fankui/i, pack: /^(?:power|hegemony_standard)$/i, packId: 'power', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Native QA keeps the actor hidden. The browser selects the branch by
  // prelighting Yiji before the QA gate and then invoking or skipping it.
  'hidden-yiji': { general: /Quách Gia|郭嘉|Guo\s*Jia/i, generalId: 'hs__guojia', skill: /Di Kế|遗计|yiji|hs__yiji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-yiji-deputy': { general: /Quách Gia|郭嘉|Guo\s*Jia/i, generalId: 'hs__guojia', skill: /Di Kế|遗计|yiji|hs__yiji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // The re-hide regression runs the same native Yiji trigger, then calls
  // ServerPlayer:hideGeneral() and checks fake/prelight reattachment before
  // ending the room.
  'hidden-rehide-yiji': { general: /Quách Gia|郭嘉|Guo\s*Jia/i, generalId: 'hs__guojia', skill: /Di Kế|遗计|yiji|hs__yiji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-rehide-yiji-deputy': { general: /Quách Gia|郭嘉|Guo\s*Jia/i, generalId: 'hs__guojia', skill: /Di Kế|遗计|yiji|hs__yiji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Jianxiong adds a second native request after the optional trigger invoke:
  // AskForChoices must select the Processing damage card and the effect must
  // reveal Cao Cao in the slot that owns the hidden skill.
  'hidden-jianxiong': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForChoices', requiresGeneral: false },
  'hidden-jianxiong-deputy': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForChoices', requiresGeneral: false },
  // Fankui is a compulsory fk.Damaged trigger. The native QA gate only
  // pauses long enough for the owner to prelight the hidden skill; the
  // acceptance request is the later AskForCardChosen source-card selection.
  'hidden-fankui': { general: /Tư Mã Ý|司马懿|Sima\s*Yi/i, generalId: 'hs__simayi', skill: /Phản Quỹ|反馈|fankui/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForCardChosen', requiresGeneral: false },
  'hidden-fankui-deputy': { general: /Tư Mã Ý|司马懿|Sima\s*Yi/i, generalId: 'hs__simayi', skill: /Phản Quỹ|反馈|fankui/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForCardChosen', requiresGeneral: false },
  // Native QA keeps Lục Tốn hidden and asks the real active reveal helper;
  // the compulsory Qianxun trigger must remain a fake skill until reveal.
  'hidden-reveal': { general: /Lục Tốn|陆逊|Lu\s*Xun/i, generalId: 'hs__luxun', skill: /Mở tướng|亮将|reveal_skill&/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-reveal-deputy': { general: /Lục Tốn|陆逊|Lu\s*Xun/i, generalId: 'hs__luxun', skill: /Mở tướng|亮将|reveal_skill&/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Native QA keeps both generals hidden and sends a real PlayCard request.
  // The server must reveal Tôn Quyền before running the active Chế Hành effect.
  'hidden-active': { general: /Lục Tốn|陆逊|Lu\s*Xun/i, generalId: 'hs__luxun', skill: /Chế Hành|制衡|zhiheng|hs__zhiheng/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-active-main': { general: /Tôn Quyền|孙权|Sun\s*Quan/i, generalId: 'hs__sunquan', skill: /Chế Hành|制衡|zhiheng|hs__zhiheng/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  // Fanjian is an active skill on Zhou Yu.  The native server must reveal
  // only the owning slot, then run the source-defined gift and target choice.
  'hidden-fanjian': { general: /周瑜|Chu\s*Du|Zhou\s*Yu|反间|Phản Gián|fanjian/i, generalId: 'hs__zhouyu', skill: /反间|Phản Gián|fanjian|ex__fanjian/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-fanjian-deputy': { general: /周瑜|Chu\s*Du|Zhou\s*Yu|反间|Phản Gián|fanjian/i, generalId: 'hs__zhouyu', skill: /反间|Phản Gián|fanjian|ex__fanjian/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-view-as': { general: /Triệu Vân|赵云|Zhao\s*Yun/i, generalId: 'hs__zhaoyun', skill: /Long Đảm|龙胆|longdan|hs__longdan/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-view-as-main': { general: /Triệu Vân|赵云|Zhao\s*Yun/i, generalId: 'hs__zhaoyun', skill: /Long Đảm|龙胆|longdan|hs__longdan/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  // The dual projection is exercised through the real trigger -> choose-player
  // -> discard -> ViewAs chain, not by clicking a regular skill in isolation.
  'hidden-dual': { general: /Nhan Lương|颜良文丑|Yan\s*Liang|Shuangxiong|Song Hùng/i, generalId: 'hs__yanliangwenchou', skill: /Song Hùng|双雄|shuangxiong|hs__shuangxiong/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Luoshen covers a non-damage EventPhaseStart trigger with the same hidden
  // prelight/reveal boundary, followed by the native judge/obtain chain.
  'hidden-luoshen': { general: /甄姬|Zhen\s*Ji|Lạc Thần|luoshen/i, generalId: 'hs__zhenji', skill: /洛神|Lạc Thần|luoshen|hs__luoshen/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-luoshen-deputy': { general: /甄姬|Zhen\s*Ji|Lạc Thần|luoshen/i, generalId: 'hs__zhenji', skill: /洛神|Lạc Thần|luoshen|hs__luoshen/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Tiandu is compulsory on FinishJudge. The native QA gate only pauses for
  // prelight; the judged card must be obtained by the real source effect.
  'hidden-tiandu': { general: /郭嘉|Quách Gia|Guo\s*Jia|Thiên Đố|天妒|tiandu/i, generalId: 'hs__guojia', skill: /Thiên Đố|天妒|tiandu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-tiandu-deputy': { general: /郭嘉|Quách Gia|Guo\s*Jia|Thiên Đố|天妒|tiandu/i, generalId: 'hs__guojia', skill: /Thiên Đố|天妒|tiandu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Jizhi covers an optional CardUsing trigger on a common Trick and must
  // reveal Huang Yueying before its native draw effect runs.
  'hidden-jizhi': { general: /黄月英|Hoàng Nguyệt Anh|Huang\s*Yueying|Tập Trí|集智|jizhi/i, generalId: 'hs__huangyueying', skill: /Tập Trí|集智|jizhi|hs__jizhi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-jizhi-deputy': { general: /黄月英|Hoàng Nguyệt Anh|Huang\s*Yueying|Tập Trí|集智|jizhi/i, generalId: 'hs__huangyueying', skill: /Tập Trí|集智|jizhi|hs__jizhi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Mingshi is compulsory on DamageInflicted; the important source predicate
  // is that the attacking player's general slot remains anjiang.
  'hidden-mingshi': { general: /孔融|Khổng Dung|Kong\s*Rong|Danh Sĩ|名士|mingshi/i, generalId: 'hs__kongrong', skill: /Danh Sĩ|名士|mingshi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-mingshi-deputy': { general: /孔融|Khổng Dung|Kong\s*Rong|Danh Sĩ|名士|mingshi/i, generalId: 'hs__kongrong', skill: /Danh Sĩ|名士|mingshi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  // Gongqing has two native damage modifiers selected solely by the source
  // attack range. The reserved Kylin Bow is moved from hand to equipment by
  // the server director between the two damage events.
  'hidden-gongqing': { general: /潘濬|潘浚|Pan\s*Jun|Công Thanh|公清|gongqing/i, generalId: 'panjun', skill: /Công Thanh|公清|gongqing/i, pack: /^tenyear_xinghuo$/i, packId: 'tenyear_xinghuo', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-gongqing-deputy': { general: /潘濬|潘浚|Pan\s*Jun|Công Thanh|公清|gongqing/i, generalId: 'panjun', skill: /Công Thanh|公清|gongqing/i, pack: /^tenyear_xinghuo$/i, packId: 'tenyear_xinghuo', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Qianxun is compulsory on TargetConfirming. The source client must send a
  // real Snatch to a legal target; native Lua then reveals the correct slot
  // and cancels the target before any obtain effect can run.
  'hidden-qianxun': { general: /陆逊|Lục Tốn|Lu\s*Xun|Khiêm Tốn|谦逊|qianxun/i, generalId: 'hs__luxun', skill: /Khiêm Tốn|谦逊|qianxun|hs__qianxun/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-qianxun-deputy': { general: /陆逊|Lục Tốn|Lu\s*Xun|Khiêm Tốn|谦逊|qianxun/i, generalId: 'hs__luxun', skill: /Khiêm Tốn|谦逊|qianxun|hs__qianxun/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Qianxun's second source branch is BeforeCardsMove: a real Indulgence
  // must not enter the actor's Judge area and must be mirrored to discard.
  'hidden-qianxun-indulgence': { general: /陆逊|Lục Tốn|Lu\s*Xun|Khiêm Tốn|谦逊|qianxun/i, generalId: 'hs__luxun', skill: /Khiêm Tốn|谦逊|qianxun|hs__qianxun/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-qianxun-indulgence-deputy': { general: /陆逊|Lục Tốn|Lu\s*Xun|Khiêm Tốn|谦逊|qianxun/i, generalId: 'hs__luxun', skill: /Khiêm Tốn|谦逊|qianxun|hs__qianxun/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Kongcheng is compulsory on TargetConfirming only when the actor is truly
  // empty-handed. Native QA empties the actor through the real move path,
  // then uses a real Duel to prove target cancellation and slot reveal.
  'hidden-kongcheng': { general: /诸葛亮|Gia Cát Lượng|Zhuge\s*Liang|Không Thành|空城|kongcheng/i, generalId: 'hs__zhugeliang', skill: /Không Thành|空城|kongcheng|hs__kongcheng/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-kongcheng-deputy': { general: /诸葛亮|Gia Cát Lượng|Zhuge\s*Liang|Không Thành|空城|kongcheng/i, generalId: 'hs__zhugeliang', skill: /Không Thành|空城|kongcheng|hs__kongcheng/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Weimu is compulsory on TargetConfirming for black Trick cards. The native
  // QA room reserves a black Duel to prove the color/type predicate, reveal
  // slot and cancellation ordering on both main and deputy placements.
  'hidden-weimu': { general: /贾诩|Giả Hủ|Jia\s*Xu|帷幕|tấm màn|Vi Mộ|weimu/i, generalId: 'hs__jiaxu', skill: /帷幕|tấm màn|Vi Mộ|weimu|hs__weimu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-weimu-deputy': { general: /贾诩|Giả Hủ|Jia\s*Xu|帷幕|tấm màn|Vi Mộ|weimu/i, generalId: 'hs__jiaxu', skill: /帷幕|tấm màn|Vi Mộ|weimu|hs__weimu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Weimu's second source branch is BeforeCardsMove: a black Indulgence
  // must be discarded instead of entering the actor's Judge area.
  'hidden-weimu-indulgence': { general: /贾诩|Giả Hủ|Jia\s*Xu|帷幕|tấm màn|Vi Mộ|weimu/i, generalId: 'hs__jiaxu', skill: /帷幕|tấm màn|Vi Mộ|weimu|hs__weimu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'hidden-weimu-indulgence-deputy': { general: /贾诩|Giả Hủ|Jia\s*Xu|帷幕|tấm màn|Vi Mộ|weimu/i, generalId: 'hs__jiaxu', skill: /帷幕|tấm màn|Vi Mộ|weimu|hs__weimu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Xiaoji covers an equipment-loss AfterCardsMove trigger. The QA director
  // discards a real equipment card after the owner prelights the hidden skill,
  // then checks native reveal ordering and the 1/3-card draw rule.
  'hidden-xiaoji': { general: /孙尚香|Tôn Thượng Hương|Sun\s*Shangxiang|枭姬|Kiêu Cơ|xiaoji/i, generalId: 'hs__sunshangxiang', skill: /枭姬|Kiêu Cơ|xiaoji|hs__xiaoji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-xiaoji-deputy': { general: /孙尚香|Tôn Thượng Hương|Sun\s*Shangxiang|枭姬|Kiêu Cơ|xiaoji/i, generalId: 'hs__sunshangxiang', skill: /枭姬|Kiêu Cơ|xiaoji|hs__xiaoji/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Guanxing covers an optional EventPhaseStart trigger followed by the
  // native AskForArrangeCards request. The server director fixes Zhuge
  // Liang in the main or deputy slot and leaves the top cards native-owned.
  'hidden-guanxing': { general: /诸葛亮|Gia Cát Lượng|Zhuge\s*Liang|观星|Quan Tinh|guanxing/i, generalId: 'hs__zhugeliang', skill: /观星|Quan Tinh|guanxing|hs__guanxing/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-guanxing-deputy': { general: /诸葛亮|Gia Cát Lượng|Zhuge\s*Liang|观星|Quan Tinh|guanxing/i, generalId: 'hs__zhugeliang', skill: /观星|Quan Tinh|guanxing|hs__guanxing/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Yingzi is compulsory on fk.DrawNCards. The browser only answers the
  // server-side prelight gate; the native event must prove the extra card.
  'hidden-yingzi': { general: /周瑜|Chu\s*Du|Zhou\s*Yu|英姿|Anh Tư|yingzi/i, generalId: 'hs__zhouyu', skill: /英姿|Anh Tư|yingzi|ex__yingzi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-yingzi-deputy': { general: /周瑜|Chu\s*Du|Zhou\s*Yu|英姿|Anh Tư|yingzi/i, generalId: 'hs__zhouyu', skill: /英姿|Anh Tư|yingzi|ex__yingzi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Tianxiang covers DetermineDamageInflicted with the full native
  // choose-card/target -> invoke -> lose-HP/return-card chain.
  'hidden-tianxiang': { general: /小乔|Tiểu Kiều|Xiao\s*Qiao|天香|Thiên Hương|tianxiang/i, generalId: 'hs__xiaoqiao', skill: /天香|Thiên Hương|tianxiang|hs__tianxiang/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-tianxiang-deputy': { general: /小乔|Tiểu Kiều|Xiao\s*Qiao|天香|Thiên Hương|tianxiang/i, generalId: 'hs__xiaoqiao', skill: /天香|Thiên Hương|tianxiang|hs__tianxiang/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Duanchang is compulsory on fk.Death. The native request that proves the
  // source path is the killer's AskForChoices; the runner still uses a
  // separate AskForSkillInvoke readiness gate to synchronize prelight.
  'hidden-duanchang': { general: /蔡文姬|Thái Văn Cơ|Cai\s*Wenji|Đoạn Trường|断肠|duanchang/i, generalId: 'hs__caiwenji', skill: /断肠|Đoạn Trường|duanchang|hs__duanchang/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForChoices', capacity: 4, requiresGeneral: false },
  'hidden-duanchang-deputy': { general: /蔡文姬|Thái Văn Cơ|Cai\s*Wenji|Đoạn Trường|断肠|duanchang/i, generalId: 'hs__caiwenji', skill: /断肠|Đoạn Trường|duanchang|hs__duanchang/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForChoices', capacity: 4, requiresGeneral: false },
  // Kuanggu has a compulsory BeforeHpChanged marker followed by an optional
  // Damage choice. The native QA gate owns only prelight; the real Slash and
  // the source-defined draw choice must still travel through production UI.
  'hidden-kuanggu': { general: /魏延|Ngụy Diên|Wei\s*Yan/i, generalId: 'hs__weiyan', skill: /狂骨|Cuồng Cốt|kuanggu|hs__kuanggu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-kuanggu-deputy': { general: /魏延|Ngụy Diên|Wei\s*Yan/i, generalId: 'hs__weiyan', skill: /狂骨|Cuồng Cốt|kuanggu|hs__kuanggu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Liegong is a TargetSpecified trigger. The native scenario keeps Huang
  // Zhong hidden until the real choice selects damage +1 and the target loses
  // two HP, proving both the slot reveal and source-defined extra damage.
  'hidden-liegong': { general: /黄忠|Hoàng Trung|Huang\s*Zhong|Liệt Cung|烈弓|liegong/i, generalId: 'hs__huangzhong', skill: /Liệt Cung|烈弓|liegong|hs__liegong/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-liegong-deputy': { general: /黄忠|Hoàng Trung|Huang\s*Zhong|Liệt Cung|烈弓|liegong/i, generalId: 'hs__huangzhong', skill: /Liệt Cung|烈弓|liegong|hs__liegong/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-jueqing': { general: /张春华|Trương Xuân Hoa|Zhang\s*Chunhua/i, generalId: 'zhangchunhua', skill: /绝情|Tuyệt Tình|jueqing/i, pack: /^yj2011$/i, packId: 'yj2011', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-jueqing-deputy': { general: /张春华|Trương Xuân Hoa|Zhang\s*Chunhua/i, generalId: 'zhangchunhua', skill: /绝情|Tuyệt Tình|jueqing/i, pack: /^yj2011$/i, packId: 'yj2011', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
};
const selectedScenario = testScenario ? scenarioConfig[testScenario] : null;
const damageExchangeScenario = testScenario === 'fazheng-enyuan';
const hiddenYijiScenario = testScenario === 'hidden-yiji' || testScenario === 'hidden-yiji-deputy';
const hiddenYijiDeputyScenario = testScenario === 'hidden-yiji-deputy';
const hiddenRehideYijiScenario = testScenario === 'hidden-rehide-yiji' || testScenario === 'hidden-rehide-yiji-deputy';
const hiddenRehideYijiDeputyScenario = testScenario === 'hidden-rehide-yiji-deputy';
const hiddenJianxiongScenario = testScenario === 'hidden-jianxiong' || testScenario === 'hidden-jianxiong-deputy';
const hiddenJianxiongDeputyScenario = testScenario === 'hidden-jianxiong-deputy';
const hiddenFankuiScenario = testScenario === 'hidden-fankui' || testScenario === 'hidden-fankui-deputy';
const hiddenFankuiDeputyScenario = testScenario === 'hidden-fankui-deputy';
const hiddenRevealScenario = testScenario === 'hidden-reveal' || testScenario === 'hidden-reveal-deputy';
const hiddenRevealDeputyScenario = testScenario === 'hidden-reveal-deputy';
const hiddenActiveScenario = testScenario === 'hidden-active' || testScenario === 'hidden-active-main';
const hiddenActiveMainScenario = testScenario === 'hidden-active-main';
const hiddenFanjianScenario = testScenario === 'hidden-fanjian' || testScenario === 'hidden-fanjian-deputy';
const hiddenFanjianDeputyScenario = testScenario === 'hidden-fanjian-deputy';
const hiddenViewAsScenario = testScenario === 'hidden-view-as' || testScenario === 'hidden-view-as-main';
const hiddenViewAsMainScenario = testScenario === 'hidden-view-as-main';
const hiddenDualScenario = testScenario === 'hidden-dual';
const hiddenLuoshenScenario = testScenario === 'hidden-luoshen' || testScenario === 'hidden-luoshen-deputy';
const hiddenLuoshenDeputyScenario = testScenario === 'hidden-luoshen-deputy';
const hiddenTianduScenario = testScenario === 'hidden-tiandu' || testScenario === 'hidden-tiandu-deputy';
const hiddenTianduDeputyScenario = testScenario === 'hidden-tiandu-deputy';
const hiddenJizhiScenario = testScenario === 'hidden-jizhi' || testScenario === 'hidden-jizhi-deputy';
const hiddenJizhiDeputyScenario = testScenario === 'hidden-jizhi-deputy';
const hiddenMingshiScenario = testScenario === 'hidden-mingshi' || testScenario === 'hidden-mingshi-deputy';
const hiddenMingshiDeputyScenario = testScenario === 'hidden-mingshi-deputy';
const hiddenGongqingScenario = testScenario === 'hidden-gongqing' || testScenario === 'hidden-gongqing-deputy';
const hiddenGongqingDeputyScenario = testScenario === 'hidden-gongqing-deputy';
const hiddenQianxunScenario = testScenario === 'hidden-qianxun' || testScenario === 'hidden-qianxun-deputy' ||
  testScenario === 'hidden-qianxun-indulgence' || testScenario === 'hidden-qianxun-indulgence-deputy';
const hiddenQianxunDeputyScenario = testScenario === 'hidden-qianxun-deputy' || testScenario === 'hidden-qianxun-indulgence-deputy';
const hiddenQianxunIndulgenceScenario = testScenario === 'hidden-qianxun-indulgence' || testScenario === 'hidden-qianxun-indulgence-deputy';
const hiddenKongchengScenario = testScenario === 'hidden-kongcheng' || testScenario === 'hidden-kongcheng-deputy';
const hiddenKongchengDeputyScenario = testScenario === 'hidden-kongcheng-deputy';
const hiddenWeimuScenario = testScenario === 'hidden-weimu' || testScenario === 'hidden-weimu-deputy' ||
  testScenario === 'hidden-weimu-indulgence' || testScenario === 'hidden-weimu-indulgence-deputy';
const hiddenWeimuDeputyScenario = testScenario === 'hidden-weimu-deputy' || testScenario === 'hidden-weimu-indulgence-deputy';
const hiddenWeimuIndulgenceScenario = testScenario === 'hidden-weimu-indulgence' || testScenario === 'hidden-weimu-indulgence-deputy';
const hiddenXiaojiScenario = testScenario === 'hidden-xiaoji' || testScenario === 'hidden-xiaoji-deputy';
const hiddenXiaojiDeputyScenario = testScenario === 'hidden-xiaoji-deputy';
const hiddenGuanxingScenario = testScenario === 'hidden-guanxing' || testScenario === 'hidden-guanxing-deputy';
const hiddenGuanxingDeputyScenario = testScenario === 'hidden-guanxing-deputy';
const hiddenYingziScenario = testScenario === 'hidden-yingzi' || testScenario === 'hidden-yingzi-deputy';
const hiddenYingziDeputyScenario = testScenario === 'hidden-yingzi-deputy';
const hiddenTianxiangScenario = testScenario === 'hidden-tianxiang' || testScenario === 'hidden-tianxiang-deputy';
const hiddenTianxiangDeputyScenario = testScenario === 'hidden-tianxiang-deputy';
const hiddenDuanchangScenario = testScenario === 'hidden-duanchang' || testScenario === 'hidden-duanchang-deputy';
const hiddenDuanchangDeputyScenario = testScenario === 'hidden-duanchang-deputy';
const hiddenKuangguScenario = testScenario === 'hidden-kuanggu' || testScenario === 'hidden-kuanggu-deputy';
const hiddenKuangguDeputyScenario = testScenario === 'hidden-kuanggu-deputy';
const hiddenLiegongScenario = testScenario === 'hidden-liegong' || testScenario === 'hidden-liegong-deputy';
const hiddenLiegongDeputyScenario = testScenario === 'hidden-liegong-deputy';
const hiddenJueqingScenario = testScenario === 'hidden-jueqing' || testScenario === 'hidden-jueqing-deputy';
const hiddenJueqingDeputyScenario = testScenario === 'hidden-jueqing-deputy';
const hiddenScenario = hiddenYijiScenario || hiddenRehideYijiScenario || hiddenJianxiongScenario || hiddenFankuiScenario || hiddenRevealScenario || hiddenActiveScenario || hiddenFanjianScenario || hiddenViewAsScenario || hiddenDualScenario || hiddenLuoshenScenario || hiddenTianduScenario || hiddenJizhiScenario || hiddenMingshiScenario || hiddenGongqingScenario || hiddenQianxunScenario || hiddenKongchengScenario || hiddenWeimuScenario || hiddenXiaojiScenario || hiddenGuanxingScenario || hiddenYingziScenario || hiddenTianxiangScenario || hiddenDuanchangScenario || hiddenLiegongScenario || hiddenKuangguScenario || hiddenJueqingScenario;
const nativeQaGateTimeoutMs = Number(process.env.TQS_LIVE_NATIVE_QA_GATE_TIMEOUT_MS ?? '45000');
assert.ok(Number.isSafeInteger(nativeQaGateTimeoutMs) && nativeQaGateTimeoutMs >= 10000 && nativeQaGateTimeoutMs <= 180000,
  'TQS_LIVE_NATIVE_QA_GATE_TIMEOUT_MS must be a bounded integer between 10000 and 180000');
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
let scenarioEnyuanReply = false;
let scenarioYijiReply = false;
let scenarioFankuiReply = false;
let scenarioFankuiInvoked = false;
let scenarioYijiInvoked = false;
let scenarioSlashReplies = 0;
let scenarioLongdanDefenseReply = false;
let scenarioLongdanAttackReply = false;
let hiddenGateReply = false;
let nativeQaGateSeen = false;
let nativeQaGateCommand: string | null = null;
let nativeQaGateFailureObserved = false;
let hiddenYijiAsked = false;
let hiddenYijiInvoked = false;
let hiddenYijiReply = false;
let hiddenJianxiongGateReply = false;
let hiddenJianxiongDamageReply = false;
let hiddenJianxiongInvoked = false;
let hiddenJianxiongChoiceReply = false;
let hiddenFankuiGateReply = false;
let hiddenFankuiDamageReply = false;
let hiddenFankuiChoiceReply = false;
let hiddenRevealGateReply = false;
let hiddenRevealReply = false;
let hiddenActiveGateReply = false;
let hiddenActiveReply = false;
let hiddenFanjianGateReply = false;
let hiddenFanjianReply = false;
let hiddenFanjianChoiceReply = false;
let hiddenViewAsGateReply = false;
let hiddenViewAsReply = false;
let hiddenDualGateReply = false;
let hiddenDualChooseReply = false;
let hiddenDualDiscardReply = false;
let hiddenDualDiscardAuto = false;
let hiddenDualUseReply = false;
let hiddenLuoshenGateReply = false;
let hiddenLuoshenInvoked = false;
let hiddenLuoshenInvokeCount = 0;
let hiddenTianduGateReply = false;
let hiddenJizhiGateReply = false;
let hiddenJizhiCardReply = false;
let hiddenJizhiInvoked = false;
let hiddenMingshiGateReply = false;
let hiddenMingshiCardReply = false;
let hiddenGongqingGateReply = false;
let hiddenQianxunGateReply = false;
let hiddenQianxunCardReply = false;
let hiddenKongchengGateReply = false;
let hiddenKongchengCardReply = false;
let hiddenWeimuGateReply = false;
let hiddenWeimuCardReply = false;
let hiddenXiaojiGateReply = false;
let hiddenGuanxingGateReply = false;
let hiddenGuanxingInvoked = false;
let hiddenGuanxingArrangeReply = false;
let hiddenYingziGateReply = false;
let hiddenTianxiangGateReply = false;
let hiddenTianxiangCardReply = false;
let hiddenTianxiangInvoked = false;
let hiddenTianxiangChoiceReply = false;
let hiddenDuanchangGateReply = false;
let hiddenDuanchangChoiceReply = false;
let hiddenKuangguGateReply = false;
let hiddenKuangguDamageReply = false;
let hiddenKuangguChoiceReply = false;
let hiddenLiegongGateReply = false;
let hiddenLiegongDamageReply = false;
let hiddenLiegongChoiceReply = false;
let hiddenJueqingGateReply = false;
let hiddenJueqingDamageReply = false;
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
  if (testScenario !== 'rescue-battle') return;
  const banner = await page.locator('.board-banners').innerText().catch(() => '');
  const skillText = await page.locator('.regular-skill-button, .sg-skill-button').allTextContents().catch(() => []);
  const disabledReasons = await page.locator('.gameplay-controls .notice').allTextContents().catch(() => []);
  if (/Quyết chiến|BattleRoyal|new_battle_royal|鏖战/i.test(`${banner}\n${skillText.join('\n')}\n${disabledReasons.join('\n')}`)) {
    scenarioBattleRoyalObserved = true;
  }
}

/** Complete the real Lua active-skill scene without inspecting private payloads. */
async function completeActiveSkill(page: Page, client: number, requestId: number, prefer: RegExp | null) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  const skillHeading = controls.locator('h3').filter({ hasText: 'Kỹ năng' });
  const skillButtons = skillHeading.locator('..').locator('..').getByRole('button');
  const count = await skillButtons.count();

  // The native reveal helper is an InteractionPicker rather than a plain
  // SkillButton: Lua publishes a combo containing revealMain/revealDeputy,
  // then the normal OK button submits the selected branch.  Exercise that
  // production path so the live QA does not confuse an active request with a
  // regular skill-dock click.
  if (hiddenRevealScenario && prefer) {
    const picker = controls.getByRole('combobox', { name: 'Chọn phương án', exact: true });
    if (await picker.count()) {
      const option = hiddenRevealDeputyScenario
        ? picker.locator('option').filter({ hasText: /Lật phó tướng|revealDeputy|副将/i }).first()
        : picker.locator('option').filter({ hasText: /Lật chủ tướng|revealMain|主将/i }).first();
      assert.ok(await option.count(), `hidden-reveal must expose the ${hiddenRevealDeputyScenario ? 'deputy' : 'main'} Lục Tốn option`);
      await picker.selectOption(await option.getAttribute('value') as string);
      const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
      assert.ok(await ok.isEnabled(), 'hidden-reveal must enable confirmation after choosing revealMain');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) scenarioActiveSkillReply = true;
      return replied;
    }
  }
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

/** Complete the selected branch using only the production UI. */
async function completeDamageExchangeActiveSkill(page: Page, client: number, requestId: number) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  const prompt = await controls.innerText();
  const yiji = /Di Kế|遗计|yiji|hs__yiji/i.test(prompt);
  const enyuan = /Ân Oán|恩怨|enyuan|ld__enyuan/i.test(prompt);
  if (enyuan) {
    // Preserve Slash 3. Giving an arbitrary first card would invalidate the
    // empty-hand branch; the reserved Peach must be given after attack 2.
    const gift = controls.locator('.gameplay-hand button:enabled').filter({ hasText: /Đào|Peach|桃/i }).first();
    if (scenarioSlashReplies === 3 && !await controls.locator('.gameplay-hand button:enabled').count()) {
      // askToCards can still request a cancelable reply for an empty hand.
      // Decline so native Enyuan performs the required one-HP fallback.
      await controls.getByRole('button', { name: 'Hủy', exact: true }).click();
      return waitForReply(client, requestId);
    }
    assert.ok(await gift.count(), 'Enyuan give branch requires the reserved Peach');
    await gift.click();
  } else if (yiji) {
    for (let n = 0; n < 2; n++) {
      const card = controls.locator('.gameplay-hand button:enabled:not([aria-pressed="true"])').first();
      assert.ok(await card.count(), 'Yiji must offer both expanded cards');
      await card.click();
    }
    await page.locator('.board-self .gameplay-target:enabled').click();
  } else {
    await controls.locator('.gameplay-hand button:enabled').first().click();
    await chooseTargetIfNeeded(page);
  }
  const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
  assert.ok(await ok.isEnabled(), 'Selected damage-exchange branch must allow confirmation');
  await ok.click();
  return waitForReply(client, requestId);
}

async function completeDamageExchangeUseCard(page: Page, client: number, requestId: number) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  // Only the first defense converts Slash to Jink. Later defenses deliberately
  // decline even though a Jink is retained for the Longdan counterattack.
  const prompt = await controls.innerText();
  const counter = client === 1 && /dùng Thiểm như Sát để phản công|tqs_qa-counter/i.test(prompt);
  const defend = !scenarioLongdanDefenseReply && client === 1;
  if (counter || defend) {
    await controls.getByRole('button', { name: 'Long Đảm', exact: true }).click();
    const material = controls.locator('.gameplay-hand button:enabled').filter({
      hasText: counter ? /Thiểm|Jink|闪/i : /Sát|Slash|杀/i,
    }).first();
    assert.ok(await material.count(), 'Longdan must expose the requested material card');
    await material.click();
    if (counter) await chooseTargetIfNeeded(page);
    await controls.getByRole('button', { name: 'Xác nhận', exact: true }).click();
  } else {
    await controls.getByRole('button', { name: 'Hủy', exact: true }).click();
  }
  const replied = await waitForReply(client, requestId);
  if (defend && replied) scenarioLongdanDefenseReply = true;
  if (counter && replied) scenarioLongdanAttackReply = true;
  return { replied, detail: counter ? 'longdan-jink-as-slash' : defend ? 'longdan-slash-as-jink' : 'decline-jink' };
}

async function completeUseCard(page: Page, client: number, requestId: number) {
  const controls = page.getByRole('region', { name: 'Điều khiển lượt chơi' });
  const sceneText = await controls.innerText().catch(() => '');
  // The native server can publish AskForUseCard before the translated prompt
  // delta reaches React.  The battle-royal QA room has exactly one expected
  // AskForUseCard path, so keep that request classified as rescue even during
  // the short prompt-rendering window.
  const rescue = testScenario === 'rescue-battle' || /hấp hối|cần hồi|#AskForPeaches|peach|đào/i.test(sceneText);
  let peach = false;
  let viewAs = false;
  let blocked = false;
  const hand = controls.locator('.gameplay-hand button[data-card-id]');
  if (rescue && testScenario === 'rescue-battle') {
    await page.waitForTimeout(100);
    const skills = controls.locator('button.sg-skill-button');
    if (/Quyết chiến|BattleRoyal|new_battle_royal|鏖战/i.test(sceneText)) scenarioBattleRoyalObserved = true;
    // In the native AskForUseCard scene, Peach -> Wine is exposed as a
    // SpecialSkills action attached to the card, not as a SkillButton.  The
    // former is rendered as a plain gameplay-choice button labelled
    // “Quyết chiến”.
    const battleRoyalAction = controls.locator('button.gameplay-choice:not(.sg-skill-button)')
      .filter({ hasText: /^Quyết chiến$/i }).first();
    let specialViewAsSelected = false;
    if (await battleRoyalAction.count() && await battleRoyalAction.isEnabled()) {
      scenarioBattleRoyalObserved = true;
      await battleRoyalAction.click();
      viewAs = true;
      specialViewAsSelected = true;
      await new Promise((resolve) => setTimeout(resolve, 150));
    }
    for (let i = 0; i < await skills.count() && !specialViewAsSelected; i++) {
      const button = skills.nth(i);
      if (await button.isEnabled() && /Quyết chiến|new_battle_royal|鏖战/i.test(await button.innerText())) {
        scenarioBattleRoyalObserved = true;
        await button.click();
        viewAs = true;
        await new Promise((resolve) => setTimeout(resolve, 150));
        break;
      }
    }
  }
  // The native request can update the hand while this helper is selecting a
  // card.  Filter the live locator by face text instead of caching numeric
  // indexes, otherwise a removed/re-rendered card makes nth(i) stale.
  const peachCards = hand.filter({ hasText: /Đào|Peach|桃/i });
  const candidateCount = await peachCards.count();
  const candidates = candidateCount > 0;
  if (rescue) {
    // Playwright's Locator.isEnabled() is async; keep the selection loop
    // explicit so a battle-royal Peach remains observable while disabled.
    let selected = false;
    for (let index = 0; index < await peachCards.count(); index++) {
      if (await peachCards.nth(index).isEnabled()) {
        await peachCards.nth(index).click();
        selected = true;
        break;
      }
    }
    peach = selected;
    blocked = !selected && candidates;
  } else if (await hand.locator(':enabled').count()) {
    await hand.locator(':enabled').first().click();
  }
  if (rescue && !peach && !blocked) blocked = !candidates;
  if (!rescue) await chooseTargetIfNeeded(page);
  const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
  if (await ok.count() && await ok.isEnabled()) await ok.click();
  else {
    const cancel = controls.getByRole('button', { name: 'Hủy', exact: true });
    if (await cancel.count() && await cancel.isEnabled()) {
      try {
        await cancel.click({ timeout: 3000 });
      } catch (error) {
        // Native Lua may resolve/replace the request synchronously while the
        // React button is being clicked.  Accept that only when the exact
        // native request has actually produced its reply; otherwise retain the
        // original failure instead of hiding a lost response.
        if (!await waitForReply(client, requestId, 3000)) throw error;
      }
    }
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
      const destination = panel.getByRole('button', { name: /Đặt cuối nhóm \d+/ }).last();
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
      await a.waitForFunction((expected) => document.querySelectorAll('.player-item:not(.sg-seat-empty)').length === expected, n + 1, { timeout: 30000 });
    }
  }
  await Promise.all(pages.map(p=>p.waitForFunction((expected)=>document.querySelectorAll('.player-item:not(.sg-seat-empty)').length===expected, playerCapacity,{timeout:30000})));
  assert.equal(await a.locator('.player-item:not(.sg-seat-empty)').count(),playerCapacity);assert.equal(await b.locator('.player-item:not(.sg-seat-empty)').count(),playerCapacity);
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
  for (const p of pages) {
    await p.locator('.game-board').waitFor({ timeout: 90000 });
    await p.waitForFunction((expected) => document.querySelectorAll('.board-player').length === expected,
      playerCapacity, { timeout: 30000 });
    await p.locator('.board-self').waitFor({ state: 'attached', timeout: 30000 });
    if (!hiddenScenario) {
      const opponent = p.locator('.board-player:not(.board-self)');
      assert.equal(await opponent.count(), playerCapacity - 1);
      assert.equal(await opponent.locator('[data-card-id], .gameplay-card').count(), 0,
        'opponent hand IDs must not render');
    }
  }
  if (damageExchangeScenario) {
    // The QA director binds the actor by allowlisted screen name, while room
    // seat assignment is not stable. Discover the two private owners from the
    // actual roster instead of assuming browser tab order.
    const rosterDeadline = Date.now() + 30000;
    let weiOwner = -1;
    let shuOwner = -1;
    while (Date.now() < rosterDeadline && (weiOwner < 0 || shuOwner < 0)) {
      for (let client = 0; client < pages.length; client++) {
        const text = await pages[client].locator('.board-self .board-generals').innerText().catch(() => '');
        if (/Quách Gia/u.test(text) && /Tư Mã Ý/u.test(text)) weiOwner = client;
        if (/Triệu Vân/u.test(text) && /Pháp Chính/u.test(text)) shuOwner = client;
      }
      if (weiOwner < 0 || shuOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    const observedRosters = await Promise.all(pages.map((page) =>
      page.locator('.board-self .board-generals').innerText().catch(() => '[unavailable]')));
    assert.ok(weiOwner >= 0,
      `Native damage scenario must reveal Quách Gia + Tư Mã Ý on one private client; observed=${JSON.stringify(observedRosters)}`);
    assert.ok(shuOwner >= 0,
      `Native damage scenario must reveal Triệu Vân + Pháp Chính on one private client; observed=${JSON.stringify(observedRosters)}`);
    scenarioClient = weiOwner;
    assert.match(await pages[weiOwner].locator('.board-self .board-generals').innerText(), /Quách Gia.*Tư Mã Ý/s,
      'Native damage scenario must reveal Quách Gia + Tư Mã Ý on the Wei client');
    assert.match(await pages[shuOwner].locator('.board-self .board-generals').innerText(), /Triệu Vân.*Pháp Chính/s,
      'Native damage scenario must reveal Triệu Vân + Pháp Chính on the Shu client');
    console.log('PASS fazheng-enyuan roster: Wei Quách Gia/Tư Mã Ý versus Shu Triệu Vân/Pháp Chính');
  }
  if (hiddenYijiScenario || hiddenRehideYijiScenario || hiddenYingziScenario) {
    await pages[0].waitForFunction(() => document.querySelectorAll('button.fake-skill-button').length > 0, null, { timeout: 30000 });
    console.log(`PASS ${hiddenRehideYijiScenario ? 'hidden-rehide-yiji' : hiddenYingziScenario ? 'hidden-yingzi' : 'hidden-yiji'} pre-gate: native fake-skill dock is visible before the QA gate`);
  }
  if (hiddenYingziScenario) {
    const label = /英姿|Anh Tư|yingzi|ex__yingzi/i;
    const deadline = Date.now() + 12000;
    let owner = -1;
    let fallback = -1;
    while (Date.now() < deadline && owner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (fallback < 0) fallback = client;
          if (await fake.filter({ hasText: label }).count()) {
            owner = client;
            break;
          }
        }
      }
      if (owner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (owner < 0) owner = fallback;
    assert.ok(owner >= 0, 'hidden-yingzi must expose a fake trigger before the native DrawNCards gate');
    scenarioClient = owner;
    assert.ok(await pages[scenarioClient].locator('button.fake-skill-button').filter({ hasText: label }).count(),
      'hidden-yingzi must expose the fake Yingzi trigger before the native DrawNCards gate');
    console.log(`PASS hidden-yingzi pre-gate: native fake Yingzi is visible in the ${hiddenYingziDeputyScenario ? 'deputy' : 'main'} slot`);
  }
  if (hiddenJianxiongScenario) {
    // The native QA director binds the actor by the allowlisted screen name,
    // not by browser-tab order. Discover the private owner from the actual
    // fake-skill projection so the test remains valid if the two authenticated
    // accounts are assigned to room seats in the opposite order.
    const hiddenJianxiongDeadline = Date.now() + 12000;
    let hiddenJianxiongOwner = -1;
    let hiddenJianxiongFallbackOwner = -1;
    while (Date.now() < hiddenJianxiongDeadline && hiddenJianxiongOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenJianxiongFallbackOwner < 0) hiddenJianxiongFallbackOwner = client;
          if (await fake.filter({ hasText: /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i }).count()) {
            hiddenJianxiongOwner = client;
            break;
          }
        }
      }
      if (hiddenJianxiongOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenJianxiongOwner < 0) hiddenJianxiongOwner = hiddenJianxiongFallbackOwner;
    assert.ok(hiddenJianxiongOwner >= 0, 'hidden-jianxiong must expose a fake trigger before the damage gate');
    scenarioClient = hiddenJianxiongOwner;
    const hiddenJianxiongFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i }).first();
    assert.ok(await hiddenJianxiongFake.count(),
      'hidden-jianxiong must expose the fake Jianxiong trigger before the damage gate');
    console.log('PASS hidden-jianxiong pre-gate: native fake-skill dock is visible before the QA damage gate');
  }
  if (hiddenFankuiScenario) {
    const hiddenFankuiDeadline = Date.now() + 12000;
    let hiddenFankuiOwner = -1;
    let hiddenFankuiFallbackOwner = -1;
    while (Date.now() < hiddenFankuiDeadline && hiddenFankuiOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenFankuiFallbackOwner < 0) hiddenFankuiFallbackOwner = client;
          if (await fake.filter({ hasText: /Phản Quỹ|反馈|fankui/i }).count()) {
            hiddenFankuiOwner = client;
            break;
          }
        }
      }
      if (hiddenFankuiOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenFankuiOwner < 0) hiddenFankuiOwner = hiddenFankuiFallbackOwner;
    assert.ok(hiddenFankuiOwner >= 0, 'hidden-fankui must expose a fake trigger before the damage gate');
    scenarioClient = hiddenFankuiOwner;
    const hiddenFankuiFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Phản Quỹ|反馈|fankui/i }).first();
    assert.ok(await hiddenFankuiFake.count(),
      'hidden-fankui must expose the fake Fankui trigger before the damage gate');
    console.log('PASS hidden-fankui pre-gate: native fake-skill dock is visible before the QA damage gate');
  }
  if (hiddenKuangguScenario) {
    const hiddenKuangguDeadline = Date.now() + 12000;
    let hiddenKuangguOwner = -1;
    let hiddenKuangguFallbackOwner = -1;
    while (Date.now() < hiddenKuangguDeadline && hiddenKuangguOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenKuangguFallbackOwner < 0) hiddenKuangguFallbackOwner = client;
          if (await fake.filter({ hasText: /狂骨|Cuồng Cốt|kuanggu/i }).count()) {
            hiddenKuangguOwner = client;
            break;
          }
        }
      }
      if (hiddenKuangguOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenKuangguOwner < 0) hiddenKuangguOwner = hiddenKuangguFallbackOwner;
    assert.ok(hiddenKuangguOwner >= 0, 'hidden-kuanggu must expose a fake trigger before the damage gate');
    scenarioClient = hiddenKuangguOwner;
    const hiddenKuangguFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /狂骨|Cuồng Cốt|kuanggu/i }).first();
    assert.ok(await hiddenKuangguFake.count(),
      'hidden-kuanggu must expose the fake Kuanggu trigger before the damage gate');
    console.log('PASS hidden-kuanggu pre-gate: native fake-skill dock is visible before the QA damage gate');
  }
  if (hiddenLiegongScenario) {
    const hiddenLiegongDeadline = Date.now() + 12000;
    let hiddenLiegongOwner = -1;
    let hiddenLiegongFallbackOwner = -1;
    while (Date.now() < hiddenLiegongDeadline && hiddenLiegongOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenLiegongFallbackOwner < 0) hiddenLiegongFallbackOwner = client;
          if (await fake.filter({ hasText: /烈弓|Liệt Cung|liegong/i }).count()) {
            hiddenLiegongOwner = client;
            break;
          }
        }
      }
      if (hiddenLiegongOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenLiegongOwner < 0) hiddenLiegongOwner = hiddenLiegongFallbackOwner;
    assert.ok(hiddenLiegongOwner >= 0, 'hidden-liegong must expose a fake trigger before the damage gate');
    scenarioClient = hiddenLiegongOwner;
    const hiddenLiegongFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /烈弓|Liệt Cung|liegong/i }).first();
    assert.ok(await hiddenLiegongFake.count(),
      'hidden-liegong must expose the fake Liegong trigger before the damage gate');
    console.log('PASS hidden-liegong pre-gate: native fake-skill dock is visible before the TargetSpecified gate');
  }
  if (hiddenJueqingScenario) {
    const hiddenJueqingDeadline = Date.now() + 12000;
    let hiddenJueqingOwner = -1;
    let hiddenJueqingFallbackOwner = -1;
    while (Date.now() < hiddenJueqingDeadline && hiddenJueqingOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenJueqingFallbackOwner < 0) hiddenJueqingFallbackOwner = client;
          if (await fake.filter({ hasText: /绝情|Tuyệt Tình|jueqing/i }).count()) {
            hiddenJueqingOwner = client;
            break;
          }
        }
      }
      if (hiddenJueqingOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenJueqingOwner < 0) hiddenJueqingOwner = hiddenJueqingFallbackOwner;
    assert.ok(hiddenJueqingOwner >= 0, 'hidden-jueqing must expose a fake trigger before the PreDamage gate');
    scenarioClient = hiddenJueqingOwner;
    const hiddenJueqingFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /绝情|Tuyệt Tình|jueqing/i }).first();
    assert.ok(await hiddenJueqingFake.count(),
      'hidden-jueqing must expose the fake Jueqing trigger before the PreDamage gate');
    console.log('PASS hidden-jueqing pre-gate: native fake-skill dock is visible before the PreDamage gate');
  }
  if (hiddenLuoshenScenario) {
    const hiddenLuoshenDeadline = Date.now() + 12000;
    let hiddenLuoshenOwner = -1;
    let hiddenLuoshenFallbackOwner = -1;
    while (Date.now() < hiddenLuoshenDeadline && hiddenLuoshenOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenLuoshenFallbackOwner < 0) hiddenLuoshenFallbackOwner = client;
          if (await fake.filter({ hasText: /洛神|Lạc Thần|luoshen/i }).count()) {
            hiddenLuoshenOwner = client;
            break;
          }
        }
      }
      if (hiddenLuoshenOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenLuoshenOwner < 0) hiddenLuoshenOwner = hiddenLuoshenFallbackOwner;
    assert.ok(hiddenLuoshenOwner >= 0, 'hidden-luoshen must expose a fake trigger before the phase gate');
    scenarioClient = hiddenLuoshenOwner;
    const hiddenLuoshenFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /洛神|Lạc Thần|luoshen/i }).first();
    assert.ok(await hiddenLuoshenFake.count(),
      'hidden-luoshen must expose the fake Luoshen trigger before the phase gate');
    console.log('PASS hidden-luoshen pre-gate: native fake-skill dock is visible before the EventPhaseStart gate');
  }
  if (hiddenTianduScenario) {
    const hiddenTianduDeadline = Date.now() + 12000;
    let hiddenTianduOwner = -1;
    let hiddenTianduFallbackOwner = -1;
    while (Date.now() < hiddenTianduDeadline && hiddenTianduOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenTianduFallbackOwner < 0) hiddenTianduFallbackOwner = client;
          if (await fake.filter({ hasText: /Thiên Đố|天妒|tiandu/i }).count()) {
            hiddenTianduOwner = client;
            break;
          }
        }
      }
      if (hiddenTianduOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenTianduOwner < 0) hiddenTianduOwner = hiddenTianduFallbackOwner;
    assert.ok(hiddenTianduOwner >= 0, 'hidden-tiandu must expose a fake trigger before the FinishJudge gate');
    scenarioClient = hiddenTianduOwner;
    const hiddenTianduFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Thiên Đố|天妒|tiandu/i }).first();
    assert.ok(await hiddenTianduFake.count(),
      'hidden-tiandu must expose the fake Tiandu trigger before the FinishJudge gate');
    console.log('PASS hidden-tiandu pre-gate: native fake-skill dock is visible before the FinishJudge gate');
  }
  if (hiddenGongqingScenario) {
    const hiddenGongqingDeadline = Date.now() + 12000;
    let hiddenGongqingOwner = -1;
    let hiddenGongqingFallbackOwner = -1;
    while (Date.now() < hiddenGongqingDeadline && hiddenGongqingOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenGongqingFallbackOwner < 0) hiddenGongqingFallbackOwner = client;
          if (await fake.filter({ hasText: /公清|Công Thanh|gongqing/i }).count()) {
            hiddenGongqingOwner = client;
            break;
          }
        }
      }
      if (hiddenGongqingOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenGongqingOwner < 0) hiddenGongqingOwner = hiddenGongqingFallbackOwner;
    assert.ok(hiddenGongqingOwner >= 0, 'hidden-gongqing must expose a fake trigger before the damage gate');
    scenarioClient = hiddenGongqingOwner;
    const hiddenGongqingFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /公清|Công Thanh|gongqing/i }).first();
    assert.ok(await hiddenGongqingFake.count(),
      'hidden-gongqing must expose the fake Gongqing trigger before the damage gate');
    console.log('PASS hidden-gongqing pre-gate: native fake Gongqing is visible before both damage-range branches');
  }
  if (hiddenJizhiScenario || hiddenMingshiScenario || hiddenQianxunScenario || hiddenKongchengScenario || hiddenWeimuScenario || hiddenXiaojiScenario || hiddenDuanchangScenario) {
    const label = hiddenJizhiScenario ? /Tập Trí|集智|jizhi/i :
      hiddenMingshiScenario ? /Danh Sĩ|名士|mingshi/i :
      hiddenQianxunScenario ? /Khiêm Tốn|谦逊|qianxun/i :
      hiddenKongchengScenario ? /Không Thành|空城|kongcheng/i :
      hiddenWeimuScenario ? /帷幕|tấm màn|Vi Mộ|weimu/i :
      hiddenXiaojiScenario ? /枭姬|Kiêu Cơ|xiaoji/i : /断肠|Đoạn Trường|duanchang/i;
    const name = hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' :
      hiddenQianxunScenario ? 'hidden-qianxun' : hiddenKongchengScenario ? 'hidden-kongcheng' :
      hiddenWeimuScenario ? 'hidden-weimu' : hiddenXiaojiScenario ? 'hidden-xiaoji' : 'hidden-duanchang';
    const deadline = Date.now() + 12000;
    let owner = -1;
    let fallback = -1;
    while (Date.now() < deadline && owner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (fallback < 0) fallback = client;
          if (await fake.filter({ hasText: label }).count()) {
            owner = client;
            break;
          }
        }
      }
      if (owner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (owner < 0) owner = fallback;
    assert.ok(owner >= 0, `${name} must expose a fake trigger before its native gate`);
    scenarioClient = owner;
    assert.ok(await pages[scenarioClient].locator('button.fake-skill-button').filter({ hasText: label }).count(),
      `${name} must expose its fake skill before the native gate`);
    console.log(`PASS ${name} pre-gate: native fake-skill dock is visible while the actor remains hidden`);
  }
  if (hiddenRevealScenario) {
    // Native QA assigns the allowlisted actor to a room seat, so the private
    // fake/regular skill projection is not guaranteed to be on browser tab 1.
    // Discover the owner from the actual reveal helper before entering the
    // request loop; otherwise a valid deputy run can be mistaken for a server
    // readiness failure when the actor lands on client 2.
    const label = /Mở tướng|reveal_skill&/i;
    const deadline = Date.now() + 30000;
    let owner = -1;
    while (Date.now() < deadline && owner < 0) {
      for (let client = 0; client < pages.length; client++) {
        if (await pages[client].locator('button.regular-skill-button').filter({ hasText: label }).count()) {
          owner = client;
          break;
        }
      }
      if (owner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    assert.ok(owner >= 0,
      'hidden-reveal must expose the native active reveal helper in the private regular skill dock');
    scenarioClient = owner;
    console.log(`PASS hidden-reveal pre-request: native fake Qianxun and active reveal dock are visible on client ${owner + 1}`);
  }
  if (hiddenActiveScenario) {
    await pages[0].waitForFunction(() => document.querySelectorAll('button.regular-skill-button').length > 0, null, { timeout: 30000 });
    assert.ok(await pages[0].locator('button.regular-skill-button').filter({ hasText: /Chế Hành|制衡|zhiheng/i }).count(),
      'hidden-active must project native fake active Chế Hành as a regular skill before PlayCard');
    console.log('PASS hidden-active pre-request: native active Chế Hành is projected while both generals remain hidden');
  }
  if (hiddenViewAsScenario) {
    await pages[0].waitForFunction(() => document.querySelectorAll('button.regular-skill-button').length > 0, null, { timeout: 30000 });
    assert.ok(await pages[0].locator('button.regular-skill-button').filter({ hasText: /Long Đảm|龙胆|longdan/i }).count(),
      'hidden-view-as must project native fake Longdan as a regular skill before PlayCard');
    console.log('PASS hidden-view-as pre-request: native Longdan is projected while Triệu Vân remains hidden');
  }
  if (hiddenDualScenario) {
    await pages[0].waitForFunction(() => document.querySelectorAll('button.regular-skill-button').length > 0, null, { timeout: 30000 });
    assert.ok(await pages[0].locator('button.regular-skill-button').filter({ hasText: /Song Hùng|双雄|shuangxiong/i }).count(),
      'hidden-dual must project native fake dual skill as a regular skill before the trigger gate');
    assert.ok(await pages[0].locator('button.fake-skill-button').filter({ hasText: /Song Hùng|双雄|shuangxiong/i }).count(),
      'hidden-dual must retain the native fake dual skill in the private dock before reveal');
    console.log('PASS hidden-dual pre-request: dual trigger/ViewAs skill is projected while both actor generals remain hidden');
  }
  if (testBotAudit || damageExchangeScenario || hiddenScenario) await Promise.all(pages.map(installPublicBotAudit));
  if (selectedScenario && !hiddenScenario) {
    const selfGenerals = await pages[scenarioClient].locator('.board-self .board-generals').innerText().catch(() => '');
    console.log(`Scenario ${testScenario}: ${nativeQa ? 'native QA package injected the server-side precondition; ' : ''}selected self general slots are ${selfGenerals.replace(/\s+/g, ' ').slice(0, 220)}`);
  }
  console.log('PASS both clients: room/join/ready/StartGame/native general pairs; no opponent card IDs in board DOM');
  if (testManual) {
    let actor = pages[scenarioClient];
    let actorTrace = traces[scenarioClient];
    const botPage = pages[1 - scenarioClient];
    const rescueScenario = testScenario === 'rescue-normal' || testScenario === 'rescue-battle';
    if (!damageExchangeScenario && !hiddenScenario && !rescueScenario) {
      await botPage.getByRole('button',{name:'BOT chơi hộ',exact:true}).click();
    }
    const deadline=Date.now()+manualDeadlineMs;
    let printedScenarioSkills = false;
    const selectActiveClient = async () => {
      if (nativeQa) {
        const nativeCommands = new Set(['PlayCard', 'AskForChoices', 'AskForSkillInvoke', 'AskForUseActiveSkill',
          'AskForUseCard', 'AskForResponseCard', 'AskForCardChosen', 'AskForPoxi', 'AskForCardsAndChoice',
          'AskForArrangeCards']);
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
      (testScenario === 'founding' && scenarioFoundingReply) ||
      (damageExchangeScenario && scenarioSlashReplies === 3 && scenarioLongdanDefenseReply &&
        scenarioLongdanAttackReply && scenarioEnyuanReply && scenarioYijiInvoked && scenarioYijiReply && scenarioFankuiReply) ||
      (hiddenRehideYijiScenario && hiddenGateReply && hiddenYijiAsked && hiddenYijiInvoked && hiddenYijiReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenYijiScenario && hiddenGateReply &&
        (hiddenYijiMode === 'negative'
          ? !hiddenYijiAsked
          : hiddenYijiAsked && (hiddenYijiMode === 'positive' ? hiddenYijiInvoked && hiddenYijiReply : !hiddenYijiInvoked)) &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJianxiongScenario && hiddenJianxiongGateReply && hiddenJianxiongDamageReply &&
        hiddenJianxiongInvoked && hiddenJianxiongChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenFankuiScenario && hiddenFankuiGateReply && hiddenFankuiDamageReply && hiddenFankuiChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenKuangguScenario && hiddenKuangguGateReply && hiddenKuangguDamageReply && hiddenKuangguChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenLiegongScenario && hiddenLiegongGateReply && hiddenLiegongDamageReply && hiddenLiegongChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJueqingScenario && hiddenJueqingGateReply && hiddenJueqingDamageReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenRevealScenario && hiddenRevealReply &&
        hiddenRevealGateReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenActiveScenario && hiddenActiveGateReply && hiddenActiveReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenFanjianScenario && hiddenFanjianGateReply && hiddenFanjianReply && hiddenFanjianChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenViewAsScenario && hiddenViewAsGateReply && hiddenViewAsReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenDualScenario && hiddenDualGateReply && hiddenDualChooseReply &&
        (hiddenDualDiscardReply || hiddenDualDiscardAuto) && hiddenDualUseReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenLuoshenScenario && hiddenLuoshenGateReply && hiddenLuoshenInvoked &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenTianduScenario && hiddenTianduGateReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJizhiScenario && hiddenJizhiGateReply && hiddenJizhiCardReply && hiddenJizhiInvoked &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenMingshiScenario && hiddenMingshiGateReply && hiddenMingshiCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenGongqingScenario && hiddenGongqingGateReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenQianxunScenario && hiddenQianxunGateReply && hiddenQianxunCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenKongchengScenario && hiddenKongchengGateReply && hiddenKongchengCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenWeimuScenario && hiddenWeimuGateReply && hiddenWeimuCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenXiaojiScenario && hiddenXiaojiGateReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenGuanxingScenario && hiddenGuanxingGateReply && hiddenGuanxingInvoked && hiddenGuanxingArrangeReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenYingziScenario && hiddenYingziGateReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenTianxiangScenario && hiddenTianxiangGateReply && hiddenTianxiangCardReply &&
        hiddenTianxiangInvoked && hiddenTianxiangChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenDuanchangScenario && hiddenDuanchangGateReply && hiddenDuanchangChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver')));
    const rescueOrFoundingScenario = testScenario === 'rescue-normal' ||
      testScenario === 'rescue-battle' || testScenario === 'founding';
    const nativeQaGateDeadline = Date.now() + nativeQaGateTimeoutMs;
    const failIfNativeQaGateMissing = () => {
      if (!nativeQa || !hiddenScenario || nativeQaGateSeen) return;
      const gameOverObserved = traces.some((trace) => trace.some((packet) =>
        packet.direction === 'incoming' && packet.command === 'GameOver'));
      if (!gameOverObserved && Date.now() < nativeQaGateDeadline) return;
      nativeQaGateFailureObserved = true;
      const reason = gameOverObserved
        ? 'GameOver arrived before the readiness gate'
        : `no readiness gate arrived within ${nativeQaGateTimeoutMs}ms after StartGame`;
      throw new Error(`Native QA ${testScenario} did not emit its server-only readiness AskForSkillInvoke gate: ${reason}; ` +
        'verify the installed tqs_qa package and tqsQa server config before treating this as gameplay evidence');
    };
    while(Date.now()<deadline && (damageExchangeScenario || hiddenScenario
      ? !scenarioDone()
      : rescueOrFoundingScenario ? !scenarioDone() : (!manualCardReply || !scenarioDone()))) {
      failIfNativeQaGateMissing();
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
          const hiddenJianxiongChoice = hiddenJianxiongScenario &&
            /jianxiong|奸雄|Gian Hùng|obtain|获得|damage card|lá Sát|gây sát thương/i.test(choiceText);
          const hiddenFanjianChoice = hiddenFanjianScenario &&
            /fanjian|反间|Phản Gián|loseHp|失去1点体力|mất 1 điểm|mất 1 máu|mất máu/i.test(choiceText);
          const hiddenTianxiangChoice = hiddenTianxiangScenario &&
            /tianxiang|天香|Thiên Hương|loseHp|失去1点体力|mất 1 điểm|nhận.*bài/i.test(choiceText);
          const hiddenDuanchangChoice = hiddenDuanchangScenario &&
            /duanchang|断肠|Đoạn Trường|hs__caocao|Cao Cao|Tào Tháo|曹操/i.test(choiceText);
          const hiddenKuangguChoice = hiddenKuangguScenario &&
            /kuanggu|狂骨|Cuồng Cốt|draw1|rút|bốc|draw card/i.test(choiceText);
          const hiddenLiegongChoice = hiddenLiegongScenario &&
            /liegong|烈弓|Liệt Cung|damage|sát thương|伤害/i.test(choiceText);
          const preferred = hiddenJianxiongChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /hs__jianxiong-obtain|jianxiong-obtain|obtain|获得|damage.*card|lá Sát|gây sát thương/i }).first()
            : hiddenFanjianChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /loseHp|失去1点体力|mất 1 điểm|mất 1 máu|mất máu/i }).first()
            : hiddenTianxiangChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /hs__tianxiang_loseHp|loseHp|失去1点体力|mất 1 điểm|nhận.*bài/i }).first()
            : hiddenDuanchangChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /hs__caocao|Cao Cao|Tào Tháo|曹操|mainGeneral|chủ tướng/i }).first()
            : hiddenKuangguChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /draw1|rút|bốc|draw card|摸一张|Bốc 1/i }).first()
            : hiddenLiegongChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /hs__liegong_damage|liegong_damage|damage|sát thương|伤害|\+1/i }).first()
            : (selectedScenario && !(testScenario === 'cards-and-choice' && scenarioActiveSkillReply))
            ? choices.locator('button.gameplay-choice:enabled').filter({ hasText: /revealMain|Lật chủ tướng|主将|main/i }).first()
            : testScenario === 'cards-and-choice'
            ? choices.locator('button.gameplay-choice:enabled').filter({ hasText: /shangyi_card|观看手牌|Xem bài.*tay|bài trên tay/i }).first()
            : choices.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          const option = await preferred.count() ? preferred : choices.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          if (hiddenJianxiongChoice) assert.ok(await preferred.count(),
            'hidden-jianxiong must expose the native obtain-damage-card choice');
          if (hiddenFanjianChoice) assert.ok(await preferred.count(),
            'hidden-fanjian must expose the native lose-HP choice');
          if (hiddenTianxiangChoice) assert.ok(await preferred.count(),
            'hidden-tianxiang must expose the native lose-HP-and-return-card choice');
          if (hiddenDuanchangChoice) assert.ok(await preferred.count(),
            'hidden-duanchang must expose the native Cao Cao/main-general choice');
          if (hiddenKuangguChoice) assert.ok(await preferred.count(),
            'hidden-kuanggu must expose the native draw1 choice');
          if (hiddenLiegongChoice) assert.ok(await preferred.count(),
            'hidden-liegong must expose the native damage-plus-one choice');
          let submitted = false;
          const confirm=choices.getByRole('button',{name:'Xác nhận lựa chọn',exact:true});
          if(await option.count()) {
            await option.click();
            if (await confirm.count() && await confirm.isEnabled()) {
              await confirm.click();
              submitted = true;
            } else if (!(await confirm.count())) {
              // ChoicePanel's single=true path removes itself after sending.
              submitted = true;
            }
          }
          // AskForChoices with single=true is auto-confirmed by ChoicePanel
          // when the option is clicked, so it has no separate confirm button.
          // Multi-select keeps the explicit confirm path above. In both cases
          // the runner must wait for the exact native reply before recording
          // the scenario assertion.
          if (submitted) {
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied && (testScenario === 'founding' ||
              /lập quốc|quốc hiệu|founding|wild-choose|建国|Dã tâm/i.test(choiceText))) scenarioFoundingReply = true;
            if (hiddenJianxiongChoice && replied) hiddenJianxiongChoiceReply = true;
            if (hiddenFanjianChoice && replied) hiddenFanjianChoiceReply = true;
            if (hiddenTianxiangChoice && replied) hiddenTianxiangChoiceReply = true;
            if (hiddenDuanchangChoice && replied) hiddenDuanchangChoiceReply = true;
            if (hiddenKuangguChoice && replied) hiddenKuangguChoiceReply = true;
            if (hiddenLiegongChoice && replied) hiddenLiegongChoiceReply = true;
            if (replied) scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
            detail: testScenario === 'founding' || /lập quốc|quốc hiệu|founding|wild-choose|建国|Dã tâm/i.test(choiceText) ? 'founding-kingdom' :
                hiddenJianxiongChoice ? 'hidden-jianxiong-obtain' :
                hiddenFanjianChoice ? 'hidden-fanjian-lose-hp' :
                hiddenTianxiangChoice ? 'hidden-tianxiang-lose-hp-return-card' :
                hiddenDuanchangChoice ? 'hidden-duanchang-lose-main-skills' :
                hiddenKuangguChoice ? 'hidden-kuanggu-draw1' :
                hiddenLiegongChoice ? 'hidden-liegong-damage-plus-one' :
                testScenario === 'cards-and-choice' ? 'shangyi_card choice' : 'choice'});
          }
        }
      } else if(latest?.command==='AskForSkillInvoke') {
        const invokeText = await actor.locator('.request-panel').innerText().catch(() => '');
        const isCardChosenInvoke = /jianchu|鞬出|Kiền xuất/i.test(invokeText);
        const isScenarioSkillInvoke = !!selectedScenario?.skill && selectedScenario.skill.test(invokeText);
        const isHiddenGate = (hiddenYijiScenario || hiddenRehideYijiScenario) && /TQS QA|prelight|tqs_qa_hidden_(?:re)?yiji_gate/i.test(invokeText);
        const isHiddenJianxiongGate = hiddenJianxiongScenario && /TQS QA|prelight|tqs_qa_hidden_jianxiong_gate/i.test(invokeText);
        const isHiddenFankuiGate = hiddenFankuiScenario && /TQS QA|prelight|tqs_qa_hidden_fankui_gate/i.test(invokeText);
        const isHiddenRevealGate = hiddenRevealScenario && /TQS QA|Mở tướng|reveal_skill&|hidden_reveal_gate/i.test(invokeText);
        const isHiddenActiveGate = hiddenActiveScenario && /TQS QA|Chế Hành|zhiheng|hidden_active_gate/i.test(invokeText);
        const isHiddenFanjianGate = hiddenFanjianScenario && /TQS QA|Phản Gián|反间|fanjian|hidden_fanjian_gate/i.test(invokeText);
        const isHiddenViewAsGate = hiddenViewAsScenario && /TQS QA|Long Đảm|longdan|hidden_view_as_gate/i.test(invokeText);
        const isHiddenDualGate = hiddenDualScenario && /TQS QA|Song Hùng|双雄|shuangxiong|hidden_dual_gate/i.test(invokeText);
        const isHiddenLuoshenGate = hiddenLuoshenScenario && /TQS QA|prelight|tqs_qa_hidden_luoshen_gate/i.test(invokeText);
        const isHiddenTianduGate = hiddenTianduScenario && /TQS QA|prelight|tqs_qa_hidden_tiandu_gate/i.test(invokeText);
        // Keep the readiness gate separate from the actual Jizhi invoke. The
        // native CardUsing prompt contains the skill label but must not be
        // mistaken for the server-only prelight synchronization request.
        const isHiddenJizhiGate = hiddenJizhiScenario && /TQS QA|prelight|tqs_qa_hidden_jizhi_gate/i.test(invokeText);
        const isHiddenMingshiGate = hiddenMingshiScenario && /TQS QA|prelight|tqs_qa_hidden_mingshi_gate/i.test(invokeText);
        const isHiddenGongqingGate = hiddenGongqingScenario && /TQS QA|prelight|tqs_qa_hidden_gongqing_gate/i.test(invokeText);
        const isHiddenQianxunGate = hiddenQianxunScenario && /TQS QA|prelight|tqs_qa_hidden_qianxun_gate/i.test(invokeText);
        const isHiddenKongchengGate = hiddenKongchengScenario && /TQS QA|prelight|tqs_qa_hidden_kongcheng_gate/i.test(invokeText);
        const isHiddenWeimuGate = hiddenWeimuScenario && /TQS QA|prelight|tqs_qa_hidden_weimu_gate/i.test(invokeText);
        const isHiddenXiaojiGate = hiddenXiaojiScenario && /TQS QA|prelight|tqs_qa_hidden_xiaoji_gate/i.test(invokeText);
        const isHiddenGuanxingGate = hiddenGuanxingScenario && /TQS QA|prelight|tqs_qa_hidden_guanxing_gate/i.test(invokeText);
        const isHiddenYingziGate = hiddenYingziScenario && /TQS QA|prelight|tqs_qa_hidden_yingzi_gate/i.test(invokeText);
        const isHiddenTianxiangGate = hiddenTianxiangScenario && /TQS QA|prelight|tqs_qa_hidden_tianxiang_gate/i.test(invokeText);
        const isHiddenDuanchangGate = hiddenDuanchangScenario && /TQS QA|prelight|tqs_qa_hidden_duanchang_gate/i.test(invokeText);
        const isHiddenLiegongGate = hiddenLiegongScenario && /TQS QA|prelight|tqs_qa_hidden_liegong_gate/i.test(invokeText);
        const isHiddenKuangguGate = hiddenKuangguScenario && /TQS QA|prelight|tqs_qa_hidden_kuanggu_gate/i.test(invokeText);
        const isHiddenJueqingGate = hiddenJueqingScenario && /TQS QA|prelight|tqs_qa_hidden_jueqing_gate/i.test(invokeText);
        const isHiddenYijiInvoke = (hiddenYijiScenario || hiddenRehideYijiScenario) && !isHiddenGate && /Di Kế|遗计|yiji|hs__yiji/i.test(invokeText);
        const isHiddenJianxiongInvoke = hiddenJianxiongScenario && !isHiddenJianxiongGate && /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i.test(invokeText);
        const isHiddenLuoshenInvoke = hiddenLuoshenScenario && !isHiddenLuoshenGate && /洛神|Lạc Thần|luoshen|hs__luoshen/i.test(invokeText);
        const isHiddenJizhiInvoke = hiddenJizhiScenario && !isHiddenJizhiGate && /Tập Trí|集智|jizhi|hs__jizhi/i.test(invokeText);
        const isHiddenGuanxingInvoke = hiddenGuanxingScenario && !isHiddenGuanxingGate && /Quan Tinh|观星|guanxing|hs__guanxing/i.test(invokeText);
        const isHiddenTianxiangInvoke = hiddenTianxiangScenario && !isHiddenTianxiangGate && /Thiên Hương|天香|tianxiang|hs__tianxiang/i.test(invokeText);
        if (isHiddenGate || isHiddenJianxiongGate || isHiddenFankuiGate || isHiddenRevealGate || isHiddenActiveGate || isHiddenFanjianGate || isHiddenViewAsGate || isHiddenDualGate || isHiddenLuoshenGate || isHiddenTianduGate || isHiddenJizhiGate || isHiddenMingshiGate || isHiddenGongqingGate || isHiddenQianxunGate || isHiddenKongchengGate || isHiddenWeimuGate || isHiddenXiaojiGate || isHiddenGuanxingGate || isHiddenYingziGate || isHiddenTianxiangGate || isHiddenDuanchangGate || isHiddenLiegongGate || isHiddenKuangguGate || isHiddenJueqingGate) {
          nativeQaGateSeen = true;
          nativeQaGateCommand = latest.command;
        }
        if (isHiddenGate && (hiddenRehideYijiScenario || hiddenYijiMode !== 'negative')) {
          const fakeYiji = actor.locator('button.fake-skill-button').filter({ hasText: /Di Kế|遗计|yiji/i }).first();
          await fakeYiji.waitFor({ timeout: 10000 });
          if (await fakeYiji.getAttribute('aria-pressed') !== 'true') await fakeYiji.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenJianxiongGate) {
          const fakeJianxiong = actor.locator('button.fake-skill-button').filter({ hasText: /Gian Hùng|奸雄|jianxiong/i }).first();
          await fakeJianxiong.waitFor({ timeout: 10000 });
          if (await fakeJianxiong.getAttribute('aria-pressed') !== 'true') await fakeJianxiong.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenFankuiGate) {
          const fakeFankui = actor.locator('button.fake-skill-button').filter({ hasText: /Phản Quỹ|反馈|fankui/i }).first();
          await fakeFankui.waitFor({ timeout: 10000 });
          if (await fakeFankui.getAttribute('aria-pressed') !== 'true') await fakeFankui.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenDualGate) {
          const fakeDual = actor.locator('button.fake-skill-button').filter({ hasText: /Song Hùng|双雄|shuangxiong/i }).first();
          await fakeDual.waitFor({ timeout: 10000 });
          if (await fakeDual.getAttribute('aria-pressed') !== 'true') await fakeDual.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenLuoshenGate) {
          const fakeLuoshen = actor.locator('button.fake-skill-button')
            .filter({ hasText: /洛神|Lạc Thần|luoshen/i }).first();
          await fakeLuoshen.waitFor({ timeout: 10000 });
          if (await fakeLuoshen.getAttribute('aria-pressed') !== 'true') await fakeLuoshen.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenTianduGate) {
          const fakeTiandu = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Thiên Đố|天妒|tiandu/i }).first();
          await fakeTiandu.waitFor({ timeout: 10000 });
          if (await fakeTiandu.getAttribute('aria-pressed') !== 'true') await fakeTiandu.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenJizhiGate) {
          const fakeJizhi = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Tập Trí|集智|jizhi/i }).first();
          await fakeJizhi.waitFor({ timeout: 10000 });
          if (await fakeJizhi.getAttribute('aria-pressed') !== 'true') await fakeJizhi.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenMingshiGate) {
          const fakeMingshi = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Danh Sĩ|名士|mingshi/i }).first();
          await fakeMingshi.waitFor({ timeout: 10000 });
          if (await fakeMingshi.getAttribute('aria-pressed') !== 'true') await fakeMingshi.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenGongqingGate) {
          const fakeGongqing = actor.locator('button.fake-skill-button')
            .filter({ hasText: /公清|Công Thanh|gongqing/i }).first();
          await fakeGongqing.waitFor({ timeout: 10000 });
          if (await fakeGongqing.getAttribute('aria-pressed') !== 'true') await fakeGongqing.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenQianxunGate) {
          const fakeQianxun = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Khiêm Tốn|谦逊|qianxun/i }).first();
          await fakeQianxun.waitFor({ timeout: 10000 });
          if (await fakeQianxun.getAttribute('aria-pressed') !== 'true') await fakeQianxun.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenKongchengGate) {
          const fakeKongcheng = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Không Thành|空城|kongcheng/i }).first();
          await fakeKongcheng.waitFor({ timeout: 10000 });
          if (await fakeKongcheng.getAttribute('aria-pressed') !== 'true') await fakeKongcheng.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenWeimuGate) {
          const fakeWeimu = actor.locator('button.fake-skill-button')
            .filter({ hasText: /帷幕|tấm màn|Vi Mộ|weimu/i }).first();
          await fakeWeimu.waitFor({ timeout: 10000 });
          if (await fakeWeimu.getAttribute('aria-pressed') !== 'true') await fakeWeimu.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenXiaojiGate) {
          const fakeXiaoji = actor.locator('button.fake-skill-button')
            .filter({ hasText: /枭姬|Kiêu Cơ|xiaoji/i }).first();
          await fakeXiaoji.waitFor({ timeout: 10000 });
          if (await fakeXiaoji.getAttribute('aria-pressed') !== 'true') await fakeXiaoji.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenGuanxingGate) {
          const fakeGuanxing = actor.locator('button.fake-skill-button')
            .filter({ hasText: /观星|Quan Tinh|guanxing/i }).first();
          await fakeGuanxing.waitFor({ timeout: 10000 });
          if (await fakeGuanxing.getAttribute('aria-pressed') !== 'true') await fakeGuanxing.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenYingziGate) {
          const fakeYingzi = actor.locator('button.fake-skill-button')
            .filter({ hasText: /英姿|Anh Tư|yingzi|ex__yingzi/i }).first();
          await fakeYingzi.waitFor({ timeout: 10000 });
          if (await fakeYingzi.getAttribute('aria-pressed') !== 'true') await fakeYingzi.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenTianxiangGate) {
          const fakeTianxiang = actor.locator('button.fake-skill-button')
            .filter({ hasText: /天香|Thiên Hương|tianxiang/i }).first();
          await fakeTianxiang.waitFor({ timeout: 10000 });
          if (await fakeTianxiang.getAttribute('aria-pressed') !== 'true') await fakeTianxiang.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenDuanchangGate) {
          const fakeDuanchang = actor.locator('button.fake-skill-button')
            .filter({ hasText: /断肠|Đoạn Trường|duanchang/i }).first();
          await fakeDuanchang.waitFor({ timeout: 10000 });
          if (await fakeDuanchang.getAttribute('aria-pressed') !== 'true') await fakeDuanchang.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenLiegongGate) {
          const fakeLiegong = actor.locator('button.fake-skill-button')
            .filter({ hasText: /烈弓|Liệt Cung|liegong/i }).first();
          await fakeLiegong.waitFor({ timeout: 10000 });
          if (await fakeLiegong.getAttribute('aria-pressed') !== 'true') await fakeLiegong.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenKuangguGate) {
          const fakeKuanggu = actor.locator('button.fake-skill-button')
            .filter({ hasText: /狂骨|Cuồng Cốt|kuanggu/i }).first();
          await fakeKuanggu.waitFor({ timeout: 10000 });
          if (await fakeKuanggu.getAttribute('aria-pressed') !== 'true') await fakeKuanggu.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenJueqingGate) {
          const fakeJueqing = actor.locator('button.fake-skill-button')
            .filter({ hasText: /绝情|Tuyệt Tình|jueqing/i }).first();
          await fakeJueqing.waitFor({ timeout: 10000 });
          if (await fakeJueqing.getAttribute('aria-pressed') !== 'true') await fakeJueqing.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        // A manual run may encounter unrelated optional skills while the
        // target prompt is still pending. Only invoke the requested caller
        // skill; cancel everything else so it cannot starve a native choice.
        const shouldInvoke = isHiddenGate || isHiddenJianxiongGate || isHiddenFankuiGate || isHiddenRevealGate || isHiddenActiveGate || isHiddenFanjianGate || isHiddenViewAsGate || isHiddenDualGate || isHiddenLuoshenGate || isHiddenTianduGate || isHiddenJizhiGate || isHiddenMingshiGate || isHiddenGongqingGate || isHiddenQianxunGate || isHiddenKongchengGate || isHiddenWeimuGate || isHiddenXiaojiGate || isHiddenGuanxingGate || isHiddenYingziGate || isHiddenTianxiangGate || isHiddenDuanchangGate || isHiddenLiegongGate || isHiddenKuangguGate || isHiddenJueqingGate
          ? true
          : isHiddenYijiInvoke
          ? hiddenRehideYijiScenario || hiddenYijiMode === 'positive'
          : isHiddenJianxiongInvoke
          ? true
          : isHiddenLuoshenInvoke
          ? true
          : isHiddenJizhiInvoke
          ? true
          : isHiddenGuanxingInvoke
          ? true
          : isHiddenTianxiangInvoke
          ? true
          : testScenario === 'card-chosen'
          ? isCardChosenInvoke
          : isScenarioSkillInvoke;
        const choice = shouldInvoke
          ? actor.locator('.request-panel').getByRole('button', { name: 'Kích hoạt', exact: true })
          : actor.locator('.request-panel').getByRole('button', { name: /^(Bỏ qua|Hủy)$/ });
        if(await choice.count() && await choice.isEnabled())await choice.click();
        const replied = await waitForReply(activeClient, latest.requestId);
        if ((hiddenYijiScenario || hiddenRehideYijiScenario) && isHiddenGate && replied) hiddenGateReply = true;
        if (hiddenJianxiongScenario && isHiddenJianxiongGate && replied) hiddenJianxiongGateReply = true;
        if (hiddenFankuiScenario && isHiddenFankuiGate && replied) hiddenFankuiGateReply = true;
        if (hiddenRevealScenario && isHiddenRevealGate && replied) hiddenRevealGateReply = true;
        if (hiddenActiveScenario && isHiddenActiveGate && replied) hiddenActiveGateReply = true;
        if (hiddenFanjianScenario && isHiddenFanjianGate && replied) hiddenFanjianGateReply = true;
        if (hiddenViewAsScenario && isHiddenViewAsGate && replied) hiddenViewAsGateReply = true;
        if (hiddenDualScenario && isHiddenDualGate && replied) hiddenDualGateReply = true;
        if (hiddenLuoshenScenario && isHiddenLuoshenGate && replied) hiddenLuoshenGateReply = true;
        if (hiddenTianduScenario && isHiddenTianduGate && replied) hiddenTianduGateReply = true;
        if (hiddenJizhiScenario && isHiddenJizhiGate && replied) hiddenJizhiGateReply = true;
        if (hiddenMingshiScenario && isHiddenMingshiGate && replied) hiddenMingshiGateReply = true;
        if (hiddenGongqingScenario && isHiddenGongqingGate && replied) hiddenGongqingGateReply = true;
        if (hiddenQianxunScenario && isHiddenQianxunGate && replied) hiddenQianxunGateReply = true;
        if (hiddenKongchengScenario && isHiddenKongchengGate && replied) hiddenKongchengGateReply = true;
        if (hiddenWeimuScenario && isHiddenWeimuGate && replied) hiddenWeimuGateReply = true;
        if (hiddenXiaojiScenario && isHiddenXiaojiGate && replied) hiddenXiaojiGateReply = true;
        if (hiddenGuanxingScenario && isHiddenGuanxingGate && replied) hiddenGuanxingGateReply = true;
        if (hiddenYingziScenario && isHiddenYingziGate && replied) hiddenYingziGateReply = true;
        if (hiddenTianxiangScenario && isHiddenTianxiangGate && replied) hiddenTianxiangGateReply = true;
        if (hiddenDuanchangScenario && isHiddenDuanchangGate && replied) hiddenDuanchangGateReply = true;
        if (hiddenLiegongScenario && isHiddenLiegongGate && replied) hiddenLiegongGateReply = true;
        if (hiddenKuangguScenario && isHiddenKuangguGate && replied) hiddenKuangguGateReply = true;
        if (hiddenJueqingScenario && isHiddenJueqingGate && replied) hiddenJueqingGateReply = true;
        if ((hiddenYijiScenario || hiddenRehideYijiScenario) && isHiddenYijiInvoke && replied) {
          hiddenYijiAsked = true;
          hiddenYijiInvoked = shouldInvoke;
        }
        if (hiddenJianxiongScenario && isHiddenJianxiongInvoke && replied) hiddenJianxiongInvoked = shouldInvoke;
        if (hiddenLuoshenScenario && isHiddenLuoshenInvoke && replied) {
          hiddenLuoshenInvoked = shouldInvoke;
          hiddenLuoshenInvokeCount += 1;
        }
        if (hiddenJizhiScenario && isHiddenJizhiInvoke && replied) hiddenJizhiInvoked = shouldInvoke;
        if (hiddenGuanxingScenario && isHiddenGuanxingInvoke && replied) hiddenGuanxingInvoked = shouldInvoke;
        if (hiddenTianxiangScenario && isHiddenTianxiangInvoke && replied) hiddenTianxiangInvoked = shouldInvoke;
        if (damageExchangeScenario && isScenarioSkillInvoke && replied) {
          if (/Phản Quỹ|反馈|fankui/i.test(invokeText)) scenarioFankuiInvoked = shouldInvoke;
          if (/Di Kế|遗计|yiji/i.test(invokeText)) scenarioYijiInvoked = shouldInvoke;
        }
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: isHiddenRevealGate ? 'hidden-reveal-readiness-gate' :
            isHiddenActiveGate ? 'hidden-active-readiness-gate' :
            isHiddenFanjianGate ? 'hidden-fanjian-readiness-gate' :
            isHiddenViewAsGate ? 'hidden-view-as-readiness-gate' :
            isHiddenDualGate ? 'hidden-dual-readiness-gate' :
            isHiddenFankuiGate ? 'hidden-fankui-readiness-gate' :
            isHiddenLuoshenGate ? 'hidden-luoshen-readiness-gate' :
            isHiddenTianduGate ? 'hidden-tiandu-readiness-gate' :
            isHiddenJizhiGate ? 'hidden-jizhi-readiness-gate' :
            isHiddenMingshiGate ? 'hidden-mingshi-readiness-gate' :
            isHiddenGongqingGate ? 'hidden-gongqing-readiness-gate' :
            isHiddenQianxunGate ? 'hidden-qianxun-readiness-gate' :
            isHiddenKongchengGate ? 'hidden-kongcheng-readiness-gate' :
            isHiddenWeimuGate ? 'hidden-weimu-readiness-gate' :
            isHiddenXiaojiGate ? 'hidden-xiaoji-readiness-gate' :
            isHiddenYingziGate ? 'hidden-yingzi-readiness-gate' :
            isHiddenTianxiangGate ? 'hidden-tianxiang-readiness-gate' :
            isHiddenLiegongGate ? 'hidden-liegong-readiness-gate' :
            isHiddenKuangguGate ? 'hidden-kuanggu-readiness-gate' :
            isHiddenJueqingGate ? 'hidden-jueqing-readiness-gate' :
            isHiddenJianxiongGate ? 'hidden-jianxiong-readiness-gate' :
            isHiddenJizhiInvoke ? 'invoke-hidden-jizhi' :
            isHiddenJianxiongInvoke ? 'invoke-hidden-jianxiong' :
            isHiddenLuoshenInvoke ? 'invoke-hidden-luoshen' :
            isHiddenTianxiangInvoke ? 'invoke-hidden-tianxiang' :
            shouldInvoke ? (isCardChosenInvoke ? 'invoke-jianchu' : 'invoke-scenario-skill') : 'cancel-other-skill'});
      } else if(latest?.command==='AskForUseActiveSkill') {
        const activePrompt = await actor.getByRole('region', { name: 'Điều khiển lượt chơi' }).innerText().catch(() => '');
        const hiddenYijiActive = (hiddenYijiScenario || hiddenRehideYijiScenario) && /Di Kế|遗计|yiji|hs__yiji/i.test(activePrompt);
        const hiddenJianxiongDamage = hiddenJianxiongScenario &&
          /hidden_jianxiong_damage|dùng Sát lên Cao Cao|kiểm tra Gian Hùng/i.test(activePrompt);
        const hiddenFankuiDamage = hiddenFankuiScenario &&
          /hidden_fankui_damage|dùng Sát lên Tư Mã Ý|kiểm tra Phản Quỹ/i.test(activePrompt);
        const hiddenKuangguDamage = hiddenKuangguScenario &&
          /hidden_kuanggu_damage|kiểm tra Cuồng Cốt|狂骨|kuanggu/i.test(activePrompt);
        const hiddenLiegongDamage = hiddenLiegongScenario &&
          /hidden_liegong_damage|kiểm tra Liệt Cung|烈弓|liegong/i.test(activePrompt);
        const hiddenJueqingDamage = hiddenJueqingScenario &&
          /hidden_jueqing_damage|kiểm tra Tuyệt Tình|绝情|jueqing/i.test(activePrompt);
        const hiddenRevealActive = hiddenRevealScenario && /Mở tướng|亮将|reveal_skill&/i.test(activePrompt);
        const hiddenDualChoose = hiddenDualScenario &&
          /hs__shuangxiong-choose|Song Hùng.*chọn một người|双雄.*令一名|chọn.*Song Hùng/i.test(activePrompt);
        const hiddenDualDiscard = hiddenDualScenario &&
          /hs__shuangxiong-discard|Song Hùng.*hãy bỏ|双雄.*请弃置|hãy bỏ.*Song Hùng/i.test(activePrompt);
        const hiddenJizhiCard = hiddenJizhiScenario &&
          /hidden_jizhi_card|Lạc Hồn|Duel|Tập Trí|集智|jizhi/i.test(activePrompt);
        const hiddenMingshiCard = hiddenMingshiScenario &&
          /hidden_mingshi_damage|dùng Sát lên Khổng Dung|Danh Sĩ|名士|mingshi/i.test(activePrompt);
        const hiddenQianxunCard = hiddenQianxunScenario &&
          /hidden_qianxun_(?:snatch|indulgence)|dùng (?:Thuận Thủ|Lạc Bất Tư Thục)|顺手牵羊|乐不思蜀|(?:Khiêm Tốn|谦逊|qianxun)/i.test(activePrompt);
        const hiddenKongchengCard = hiddenKongchengScenario &&
          /hidden_kongcheng_duel|dùng Quyết Đấu|决斗|Không Thành|空城|kongcheng/i.test(activePrompt);
        const hiddenWeimuCard = hiddenWeimuScenario &&
          /hidden_weimu_(?:duel|indulgence)|Quyết Đấu đen|Lạc Bất Tư Thục đen|黑色.*(?:决斗|乐不思蜀)|帷幕|tấm màn|Vi Mộ|weimu/i.test(activePrompt);
        const hiddenTianxiangChoose = hiddenTianxiangScenario &&
          /hs__tianxiang-choose|Thiên Hương|天香|tianxiang|heart|tim|红桃/i.test(activePrompt);
        if (hiddenJizhiCard || hiddenMingshiCard || hiddenQianxunCard || hiddenKongchengCard || hiddenWeimuCard || hiddenTianxiangChoose) {
          const hand = actor.locator('.gameplay-hand button:enabled');
          const preferredCard = hiddenTianxiangChoose
            ? hand.first()
            : hiddenKongchengCard
            ? hand.filter({ hasText: /Quyết Đấu|决斗|Duel/i }).first()
            : hiddenWeimuCard
            ? hand.filter({ hasText: hiddenWeimuIndulgenceScenario
              ? /Lạc Bất Tư Thục|乐不思蜀|Indulgence/i
              : /Quyết Đấu|决斗|Duel/i }).first()
            : hiddenQianxunCard
            ? hand.filter({ hasText: hiddenQianxunIndulgenceScenario
              ? /Lạc Bất Tư Thục|乐不思蜀|Indulgence/i
              : /Thuận Thủ|顺手牵羊|Snatch|顺手/i }).first()
            : hand.first();
          const card = await preferredCard.count() ? preferredCard : hand.first();
          assert.ok(await card.count(), `${hiddenTianxiangChoose ? 'hidden-tianxiang' : hiddenJizhiCard ? 'hidden-jizhi' : hiddenMingshiCard ? 'hidden-mingshi' : hiddenQianxunCard ? 'hidden-qianxun' : hiddenKongchengCard ? 'hidden-kongcheng' : 'hidden-weimu'} must expose its reserved real card`);
          await card.click();
          await chooseTargetIfNeeded(actor);
          const ok = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.count() && await ok.isEnabled(),
            `${hiddenTianxiangChoose ? 'hidden-tianxiang' : hiddenJizhiCard ? 'hidden-jizhi' : hiddenMingshiCard ? 'hidden-mingshi' : hiddenQianxunCard ? 'hidden-qianxun' : hiddenKongchengCard ? 'hidden-kongcheng' : 'hidden-weimu'} must enable confirmation after selecting its real card`);
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (hiddenJizhiCard && replied) hiddenJizhiCardReply = true;
          if (hiddenMingshiCard && replied) hiddenMingshiCardReply = true;
          if (hiddenQianxunCard && replied) hiddenQianxunCardReply = true;
          if (hiddenKongchengCard && replied) hiddenKongchengCardReply = true;
          if (hiddenWeimuCard && replied) hiddenWeimuCardReply = true;
          if (hiddenTianxiangChoose && replied) {
            hiddenTianxiangCardReply = true;
            // Tianxiang's on_cost is askToChooseCardsAndPlayers.  The native
            // TriggerSkill:doCost path does not emit a second
            // AskForSkillInvoke after that request; the successful
            // AskForUseActiveSkill reply is the actual invocation.
            hiddenTianxiangInvoked = true;
          }
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: hiddenTianxiangChoose ? 'hidden-tianxiang-heart-card-and-target' : hiddenJizhiCard ? 'hidden-jizhi-duel' : hiddenMingshiCard ? 'hidden-mingshi-hidden-source-slash' :
              hiddenKongchengCard ? 'hidden-kongcheng-duel' : hiddenWeimuCard
                ? (hiddenWeimuIndulgenceScenario ? 'hidden-weimu-black-indulgence' : 'hidden-weimu-black-duel') :
              hiddenQianxunIndulgenceScenario ? 'hidden-qianxun-indulgence' : 'hidden-qianxun-snatch' });
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (hiddenDualChoose) {
          await chooseTargetIfNeeded(actor);
          const ok = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.count() && await ok.isEnabled(),
            'hidden-dual must enable target confirmation after choosing the discard target');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) hiddenDualChooseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'hidden-dual-choose-discard-target' });
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenDualDiscard) {
          const card = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Thiểm|Jink|闪/i }).first();
          assert.ok(await card.count(), 'hidden-dual must expose the reserved target Jink for discard');
          await card.click();
          const ok = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.count() && await ok.isEnabled(),
            'hidden-dual must enable confirmation after selecting the reserved target Jink');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) hiddenDualDiscardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'hidden-dual-discard-red-card' });
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenJianxiongDamage) {
          // Room:askToUseRealCard() is implemented by the native server as an
          // AskForUseActiveSkill request for userealcard_skill. The native
          // handler owns that skill selection implicitly; the production
          // scene exposes only the eligible real card and target controls.
          const slash = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await slash.count(), 'hidden-jianxiong must expose the reserved target Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jianxiong must expose the hidden Cao Cao target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-jianxiong must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJianxiongDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jianxiong-damage-slash' });
          }
        } else if (hiddenFankuiDamage) {
          // Room:askToUseRealCard() may be exposed as either PlayCard or
          // AskForUseActiveSkill by the native adapter. In both cases the
          // production UI must select the reserved real Slash and the hidden
          // Tư Mã Ý target before the native Damaged trigger runs.
          const slash = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await slash.count(), 'hidden-fankui must expose the reserved target Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-fankui must expose the hidden Tư Mã Ý target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-fankui must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenFankuiDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-fankui-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenKuangguDamage) {
          const slash = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await slash.count(), 'hidden-kuanggu must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-kuanggu must expose the native target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-kuanggu must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenKuangguDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-kuanggu-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenLiegongDamage) {
          const slash = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await slash.count(), 'hidden-liegong must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-liegong must expose the native target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-liegong must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenLiegongDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-liegong-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenJueqingDamage) {
          const slash = actor.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await slash.count(), 'hidden-jueqing must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jueqing must expose the native target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-jueqing must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJueqingDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jueqing-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (damageExchangeScenario || hiddenYijiActive || hiddenRevealActive) {
          const prompt = await actor.getByRole('region', { name: 'Điều khiển lượt chơi' }).innerText().catch(() => '');
          const replied = hiddenRevealActive
            ? await completeActiveSkill(actor, activeClient, latest.requestId, /Mở tướng|亮将|reveal_skill&/i)
            : await completeDamageExchangeActiveSkill(actor, activeClient, latest.requestId);
          // The engine's prompts are translated from the real skill names; the
          // exact card/target payload remains inside the client and is not
          // persisted by this runner.
          if (/Ân Oán|恩怨|enyuan|ld__enyuan/i.test(prompt)) scenarioEnyuanReply = replied;
          else if (/Di Kế|遗计|yiji|hs__yiji/i.test(prompt)) scenarioYijiReply = replied;
          else if (/Sát lần|tqs_qa-slash/i.test(prompt) && replied) scenarioSlashReplies++;
          if (hiddenYijiActive && replied) hiddenYijiReply = true;
          if (hiddenRevealActive && replied) hiddenRevealReply = true;
          scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
            detail: /Ân Oán|恩怨|enyuan|ld__enyuan/i.test(prompt) ? 'enyuan-give-card' :
              /Di Kế|遗计|yiji|hs__yiji/i.test(prompt) ? hiddenYijiActive ? 'hidden-yiji-distribute' : 'yiji-distribute' :
              hiddenRevealActive ? 'hidden-reveal-active' : 'damage-exchange-active'});
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        const activeSkill = testScenario === 'rescue-battle'
          ? selectedScenario?.skill ?? null
          : testScenario === 'cards-and-choice' || testScenario === 'poxi'
            ? selectedScenario?.skill ?? null : null;
        const replied = await completeActiveSkill(actor, activeClient, latest.requestId, activeSkill);
        if (replied && testScenario === 'rescue-battle' && activeSkill) scenarioViewAsReply = true;
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: activeSkill?.source ?? 'cancel'});
      } else if(latest?.command==='AskForUseCard' || latest?.command==='AskForResponseCard') {
        if (damageExchangeScenario) {
          const result = await completeDamageExchangeUseCard(actor, activeClient, latest.requestId);
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: result.replied, detail: result.detail });
          continue;
        }
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
          if (damageExchangeScenario && scenarioFankuiInvoked) scenarioFankuiReply = true;
          if (hiddenFankuiScenario) hiddenFankuiChoiceReply = true;
          scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
            detail: hiddenFankuiScenario ? 'hidden-fankui-obtain' : hiddenIndex >= 0 ? 'hidden-card' : 'public-card'});
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
      } else if(latest && ['AskForArrangeCards','AskForAG','CustomDialog','AskForGeneral','AskForMoveCardInBoard'].includes(latest.command)) {
        const replied = await completeNativeDialog(actor, activeClient, latest.requestId);
        if (hiddenGuanxingScenario && latest.command === 'AskForArrangeCards' && replied) {
          hiddenGuanxingArrangeReply = true;
        }
      } else if(latest?.command==='PlayCard') {
        const controls=actor.getByRole('region',{name:'Điều khiển lượt chơi'});
        const skillButtons=controls.locator('button.sg-skill-button');
        if (selectedScenario && !printedScenarioSkills) {
          printedScenarioSkills = true;
          console.log(`Scenario ${testScenario} first PlayCard skills: ${(await skillButtons.allTextContents()).join(' | ') || '(none)'}`);
        }
        if (hiddenJizhiScenario || hiddenMingshiScenario || hiddenQianxunScenario || hiddenKongchengScenario) {
          const hand = controls.locator('.gameplay-hand button:enabled');
          const preferredCard = hiddenKongchengScenario
            ? hand.filter({ hasText: /Quyết Đấu|决斗|Duel/i }).first()
            : hiddenQianxunScenario
            ? hand.filter({ hasText: hiddenQianxunIndulgenceScenario
              ? /Lạc Bất Tư Thục|乐不思蜀|Indulgence/i
              : /Thuận Thủ|顺手牵羊|Snatch|顺手/i }).first()
            : hand.first();
          const card = await preferredCard.count() ? preferredCard : hand.first();
          assert.ok(await card.count(), `${hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' : hiddenQianxunScenario ? 'hidden-qianxun' : 'hidden-kongcheng'} must expose its reserved real card`);
          await card.click();
          await chooseTargetIfNeeded(actor);
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.count() && await confirm.isEnabled(),
            `${hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' : hiddenQianxunScenario ? 'hidden-qianxun' : 'hidden-kongcheng'} must enable PlayCard confirmation after selecting its real card`);
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (hiddenJizhiScenario && replied) hiddenJizhiCardReply = true;
          if (hiddenMingshiScenario && replied) hiddenMingshiCardReply = true;
          if (hiddenQianxunScenario && replied) hiddenQianxunCardReply = true;
          if (hiddenKongchengScenario && replied) hiddenKongchengCardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: hiddenJizhiScenario ? 'hidden-jizhi-duel' : hiddenMingshiScenario ? 'hidden-mingshi-hidden-source-slash' :
              hiddenKongchengScenario ? 'hidden-kongcheng-duel' :
              hiddenQianxunIndulgenceScenario ? 'hidden-qianxun-indulgence' : 'hidden-qianxun-snatch' });
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (hiddenJianxiongScenario) {
          const card = controls.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await card.count(), 'hidden-jianxiong must expose the reserved target Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jianxiong must expose the hidden Cao Cao target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-jianxiong must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJianxiongDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jianxiong-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenFankuiScenario) {
          const card = controls.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await card.count(), 'hidden-fankui must expose the reserved target Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-fankui must expose the hidden Tư Mã Ý target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-fankui must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenFankuiDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-fankui-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenKuangguScenario) {
          const card = controls.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await card.count(), 'hidden-kuanggu must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-kuanggu must expose the native target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-kuanggu must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenKuangguDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-kuanggu-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenLiegongScenario) {
          const card = controls.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await card.count(), 'hidden-liegong must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-liegong must expose the native target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-liegong must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenLiegongDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-liegong-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenJueqingScenario) {
          // askToUseRealCard normally arrives as AskForUseActiveSkill. If the
          // native adapter also publishes a regular PlayCard request while
          // the QA director is finishing, it belongs to the other seat's
          // normal play phase, not to the reserved actor Slash. Do not let
          // that request consume the hidden-Jueqing branch or assert for a
          // target that is not present on the opponent's board.
          if (activeClient !== scenarioClient) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise(r => setTimeout(r, 250));
            continue;
          }
          const card = controls.locator('.gameplay-hand button:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          assert.ok(await card.count(), 'hidden-jueqing must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jueqing must expose the native target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-jueqing must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJueqingDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jueqing-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        const activeScenario = testScenario === 'card-chosen' ? null : selectedScenario;
        const desiredSkill=activeScenario?.skill ? skillButtons.filter({hasText:activeScenario.skill}).first() : null;
        if(desiredSkill && await desiredSkill.count() && await desiredSkill.isEnabled()) {
          await desiredSkill.click();
          if (hiddenActiveScenario) {
            const card = controls.locator('.gameplay-hand button:enabled').first();
            assert.ok(await card.count(), 'hidden-active must expose the reserved actor Slash after selecting Chế Hành');
            await card.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.isEnabled(), 'hidden-active must enable PlayCard confirmation after selecting Chế Hành and one card');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              hiddenActiveReply = true;
              scenarioActiveSkillReply = true;
              scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
                detail: 'hidden-active-zhiheng' });
            }
            await new Promise(r=>setTimeout(r,250));
            continue;
          }
          if (hiddenFanjianScenario) {
            const card = controls.locator('.gameplay-hand button:enabled')
              .filter({ hasText: /Đào|Peach|桃/i }).first();
            assert.ok(await card.count(), 'hidden-fanjian must expose the reserved actor Peach after selecting Phản Gián');
            await card.click();
            const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
            assert.ok(await target.count(), 'hidden-fanjian must expose the native target after selecting Phản Gián and Peach');
            await target.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.isEnabled(), 'hidden-fanjian must enable PlayCard confirmation after selecting Phản Gián, Peach and a target');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              hiddenFanjianReply = true;
              scenarioActiveSkillReply = true;
              scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
                detail: 'hidden-fanjian-gift-peach' });
            }
            await new Promise(r=>setTimeout(r,250));
            continue;
          }
          if (hiddenViewAsScenario) {
            const card = controls.locator('.gameplay-hand button:enabled')
              .filter({ hasText: /Thiểm|Jink|闪/i }).first();
            assert.ok(await card.count(), 'hidden-view-as must expose the reserved actor Jink after selecting Long Đảm');
            await card.click();
            const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
            assert.ok(await target.count(), 'hidden-view-as must expose an opponent target after converting Jink to Slash');
            await target.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.isEnabled(), 'hidden-view-as must enable PlayCard confirmation after selecting Long Đảm, Jink and a target');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              hiddenViewAsReply = true;
              scenarioActiveSkillReply = true;
              scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
                detail: 'hidden-view-as-longdan' });
            }
            await new Promise(r=>setTimeout(r,250));
            continue;
          }
          if (hiddenDualScenario) {
            // With exactly one legal card and a non-cancelable native
            // askToDiscard, FreeKill auto-discards before sending the next
            // PlayCard request. There is therefore no second browser request
            // to click; the native QA log/effect assertion is the authority
            // for the discard and color mark.
            if (hiddenDualChooseReply && !hiddenDualDiscardReply) hiddenDualDiscardAuto = true;
            const card = controls.locator('.gameplay-hand button:enabled')
              .filter({ hasText: /Sát|Slash|杀/i }).first();
            assert.ok(await card.count(), 'hidden-dual must expose the reserved opposite-color Slash after Song Hùng');
            await card.click();
            await chooseTargetIfNeeded(actor);
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.isEnabled(), 'hidden-dual must enable PlayCard confirmation after selecting Song Hùng, Slash and target');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              hiddenDualUseReply = true;
              scenarioActiveSkillReply = true;
              scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
                detail: 'hidden-dual-shuangxiong-duel' });
            }
            await new Promise(r=>setTimeout(r,250));
            continue;
          }
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
    if (damageExchangeScenario) {
      assert.equal(scenarioSlashReplies, 3, 'Wei must answer three real Slash requests');
      assert.ok(scenarioLongdanDefenseReply && scenarioLongdanAttackReply, 'Longdan must convert both directions');
      assert.ok(scenarioYijiInvoked, 'Positive branch must explicitly invoke optional Yiji');
      assert.ok(scenarioEnyuanReply, 'fazheng-enyuan must answer the native Ân Oán card request');
      assert.ok(scenarioYijiReply, 'fazheng-enyuan must answer the native Di Kế distribution request');
      assert.ok(scenarioFankuiInvoked && scenarioFankuiReply,
        'fazheng-enyuan manual mode must invoke Phản Quỹ and answer its source-card request');
      console.log('PASS fazheng-enyuan requests: three Wei Slashes, both Longdan conversions, Enyuan gift, optional Yiji/Fankui invoked');
    } else if (hiddenRehideYijiScenario) {
      assert.ok(hiddenGateReply, 'hidden-rehide-yiji must complete the native prelight gate');
      assert.ok(hiddenYijiAsked && hiddenYijiInvoked && hiddenYijiReply,
        'hidden-rehide-yiji must invoke native Di Kế and complete its card distribution before re-hide');
      console.log(`PASS hidden-rehide-yiji ${hiddenRehideYijiDeputyScenario ? 'deputy' : 'main'}: native Di Kế invoked from a hidden slot and completed the re-hide path`);
    } else if (hiddenYijiScenario) {
      assert.ok(hiddenGateReply, 'hidden-yiji must complete the native prelight gate');
      assert.equal(hiddenYijiInvoked, hiddenYijiMode === 'positive',
        `hidden-yiji ${hiddenYijiMode} branch invoked mismatch`);
      if (hiddenYijiMode === 'positive') {
        assert.ok(hiddenYijiAsked && hiddenYijiReply,
          'positive hidden-yiji branch must receive AskForSkillInvoke and complete native Yiji distribution');
      } else if (hiddenYijiMode === 'skip') {
        assert.ok(hiddenYijiAsked, 'skip hidden-yiji branch must still receive AskForSkillInvoke');
        assert.equal(hiddenYijiReply, false, 'skip hidden-yiji branch must not enter Yiji distribution');
      } else {
        assert.equal(hiddenYijiAsked, false, 'negative hidden-yiji branch must not ask an unprelighted Yiji');
      }
      console.log(`PASS hidden-yiji ${hiddenYijiMode}: native hidden-trigger branch completed with ` +
        `${hiddenYijiAsked ? 'AskForSkillInvoke' : 'no Yiji request'}, ` +
        `${hiddenYijiInvoked ? 'Invoke' : 'Skip/no-prelight'}`);
    } else if (hiddenJianxiongScenario) {
      assert.ok(hiddenJianxiongGateReply, 'hidden-jianxiong must complete the native prelight gate');
      assert.ok(hiddenJianxiongDamageReply, 'hidden-jianxiong must complete the target Slash request');
      assert.ok(hiddenJianxiongInvoked, 'hidden-jianxiong must invoke the prelighted trigger');
      assert.ok(hiddenJianxiongChoiceReply, 'hidden-jianxiong must answer the native obtain-card choice');
      console.log('PASS hidden-jianxiong: native hidden-trigger branch invoked and answered the obtain-damage-card choice');
    } else if (hiddenFankuiScenario) {
      assert.ok(hiddenFankuiGateReply, 'hidden-fankui must complete the native prelight gate');
      assert.ok(hiddenFankuiDamageReply, 'hidden-fankui must complete the target Slash request');
      assert.ok(hiddenFankuiChoiceReply, 'hidden-fankui must answer the native source-card choice');
      console.log('PASS hidden-fankui: native hidden Damaged trigger revealed Tư Mã Ý and answered the source-card choice');
    } else if (hiddenKuangguScenario) {
      assert.ok(hiddenKuangguGateReply, 'hidden-kuanggu must complete the native prelight gate');
      assert.ok(hiddenKuangguDamageReply, 'hidden-kuanggu must complete the actor Slash request');
      assert.ok(hiddenKuangguChoiceReply, 'hidden-kuanggu must answer the native draw1 choice');
      console.log(`PASS hidden-kuanggu: native hidden BeforeHpChanged/Damage branch revealed Wei Yan and completed draw1 in the ${hiddenKuangguDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenLiegongScenario) {
      assert.ok(hiddenLiegongGateReply, 'hidden-liegong must complete the native prelight gate');
      assert.ok(hiddenLiegongDamageReply, 'hidden-liegong must complete the actor Slash request');
      assert.ok(hiddenLiegongChoiceReply, 'hidden-liegong must answer the native damage-plus-one choice');
      console.log(`PASS hidden-liegong: native hidden TargetSpecified branch revealed Huang Zhong and completed damage+1 in the ${hiddenLiegongDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenJueqingScenario) {
      assert.ok(hiddenJueqingGateReply, 'hidden-jueqing must complete the native prelight gate');
      assert.ok(hiddenJueqingDamageReply, 'hidden-jueqing must complete the actor Slash request');
      console.log(`PASS hidden-jueqing: native hidden PreDamage branch revealed Zhang Chunhua and converted damage to HP loss in the ${hiddenJueqingDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenLuoshenScenario) {
      assert.ok(hiddenLuoshenGateReply, 'hidden-luoshen must complete the native prelight gate');
      assert.ok(hiddenLuoshenInvoked, 'hidden-luoshen must invoke the prelighted phase-start trigger');
      assert.ok(hiddenLuoshenInvokeCount >= 2,
        'hidden-luoshen must expose the readiness gate and the real trigger/continuation invoke');
      console.log('PASS hidden-luoshen: native hidden EventPhaseStart trigger revealed Zhen Ji and completed judgment continuation');
    } else if (hiddenJizhiScenario) {
      assert.ok(hiddenJizhiGateReply, 'hidden-jizhi must complete the native prelight gate');
      assert.ok(hiddenJizhiCardReply, 'hidden-jizhi must complete the native Duel/CardUsing request');
      assert.ok(hiddenJizhiInvoked, 'hidden-jizhi must invoke the optional prelighted CardUsing effect');
      console.log('PASS hidden-jizhi: native hidden CardUsing branch accepted Duel, invoked Tập Trí and completed its draw effect');
    } else if (hiddenMingshiScenario) {
      assert.ok(hiddenMingshiGateReply, 'hidden-mingshi must complete the native prelight gate');
      assert.ok(hiddenMingshiCardReply, 'hidden-mingshi must complete the hidden-source Slash request');
      console.log('PASS hidden-mingshi: native hidden DamageInflicted branch accepted the hidden-source Slash and reduced damage to zero');
    } else if (hiddenGongqingScenario) {
      assert.ok(hiddenGongqingGateReply, 'hidden-gongqing must complete the native prelight gate');
      console.log(`PASS hidden-gongqing: native hidden actor completed both low/high attack-range damage branches in the ${hiddenGongqingDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenQianxunScenario) {
      assert.ok(hiddenQianxunGateReply, 'hidden-qianxun must complete the native prelight gate');
      assert.ok(hiddenQianxunCardReply, hiddenQianxunIndulgenceScenario
        ? 'hidden-qianxun-indulgence must complete the source Indulgence request'
        : 'hidden-qianxun must complete the source Snatch request');
      console.log(hiddenQianxunIndulgenceScenario
        ? 'PASS hidden-qianxun-indulgence: native hidden BeforeCardsMove branch accepted Indulgence and mirrored it to discard'
        : 'PASS hidden-qianxun: native hidden TargetConfirming branch accepted a legal Snatch and cancelled the actor target');
    } else if (hiddenKongchengScenario) {
      assert.ok(hiddenKongchengGateReply, 'hidden-kongcheng must complete the native prelight gate');
      assert.ok(hiddenKongchengCardReply, 'hidden-kongcheng must complete the source Duel request');
      console.log('PASS hidden-kongcheng: native hidden TargetConfirming branch accepted Duel while empty-handed and cancelled the actor target');
    } else if (hiddenWeimuScenario) {
      assert.ok(hiddenWeimuGateReply, 'hidden-weimu must complete the native prelight gate');
      assert.ok(hiddenWeimuCardReply, hiddenWeimuIndulgenceScenario
        ? 'hidden-weimu-indulgence must complete the source black Indulgence request'
        : 'hidden-weimu must complete the source black Duel request');
      console.log(hiddenWeimuIndulgenceScenario
        ? 'PASS hidden-weimu-indulgence: native hidden BeforeCardsMove branch accepted black Indulgence and mirrored it to discard'
        : 'PASS hidden-weimu: native hidden TargetConfirming branch accepted black Duel and cancelled the actor target');
    } else if (hiddenXiaojiScenario) {
      assert.ok(hiddenXiaojiGateReply, 'hidden-xiaoji must complete the native prelight gate');
      console.log('PASS hidden-xiaoji: native hidden AfterCardsMove branch discarded equipment and completed Xiaoji draw');
    } else if (hiddenGuanxingScenario) {
      assert.ok(hiddenGuanxingGateReply, 'hidden-guanxing must complete the native prelight gate');
      assert.ok(hiddenGuanxingInvoked, 'hidden-guanxing must invoke the prelighted EventPhaseStart trigger');
      assert.ok(hiddenGuanxingArrangeReply, 'hidden-guanxing must complete the native AskForArrangeCards request');
      console.log('PASS hidden-guanxing: native hidden EventPhaseStart branch revealed Zhuge Liang and completed AskForArrangeCards');
    } else if (hiddenYingziScenario) {
      assert.ok(hiddenYingziGateReply, 'hidden-yingzi must complete the native prelight gate');
      console.log(`PASS hidden-yingzi: native hidden DrawNCards branch revealed Zhou Yu and added one card in the ${hiddenYingziDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenTianxiangScenario) {
      assert.ok(hiddenTianxiangGateReply, 'hidden-tianxiang must complete the native prelight gate');
      assert.ok(hiddenTianxiangCardReply, 'hidden-tianxiang must complete the native heart-card and target request');
      assert.ok(hiddenTianxiangInvoked, 'hidden-tianxiang must invoke the prelighted DetermineDamageInflicted trigger');
      assert.ok(hiddenTianxiangChoiceReply, 'hidden-tianxiang must choose the native lose-HP-and-return-card branch');
      console.log('PASS hidden-tianxiang: native hidden DetermineDamageInflicted branch selected a heart card/target, revealed Xiao Qiao and returned the card');
    } else if (hiddenDuanchangScenario) {
      assert.ok(hiddenDuanchangGateReply, 'hidden-duanchang must complete the native prelight gate');
      assert.ok(hiddenDuanchangChoiceReply, 'hidden-duanchang must answer the native killer main/deputy choice');
      console.log('PASS hidden-duanchang: native hidden Death branch revealed Cai Wenji and answered the killer skill-loss choice');
    } else if (hiddenRevealScenario) {
      assert.ok(hiddenRevealReply,
        'hidden-reveal must complete the native reveal_skill& active request and reveal Lục Tốn');
      console.log('PASS hidden-reveal: native reveal_skill& request opened Lục Tốn and activated hidden Qianxun');
    } else if (hiddenActiveScenario) {
      assert.ok(hiddenActiveGateReply,
        'hidden-active must complete the native readiness gate before PlayCard');
      assert.ok(hiddenActiveReply,
        'hidden-active must complete the native PlayCard request with Chế Hành and one card');
      console.log('PASS hidden-active: native PlayCard selected Chế Hành while hidden and completed the skill path');
    } else if (hiddenFanjianScenario) {
      assert.ok(hiddenFanjianGateReply,
        'hidden-fanjian must complete the native readiness gate before PlayCard');
      assert.ok(hiddenFanjianReply,
        'hidden-fanjian must complete the native PlayCard request with Phản Gián, Peach and one target');
      assert.ok(hiddenFanjianChoiceReply,
        'hidden-fanjian must answer the native lose-HP choice after gifting Peach');
      console.log('PASS hidden-fanjian: native PlayCard revealed the hidden owner, gifted Peach and completed the target lose-HP choice');
    } else if (hiddenViewAsScenario) {
      assert.ok(hiddenViewAsGateReply,
        'hidden-view-as must complete the native readiness gate before PlayCard');
      assert.ok(hiddenViewAsReply,
        'hidden-view-as must complete the native PlayCard request with Long Đảm and one Jink');
      console.log('PASS hidden-view-as: native PlayCard selected Long Đảm while Triệu Vân was hidden and converted Jink to Slash');
    } else if (hiddenDualScenario) {
      assert.ok(hiddenDualGateReply, 'hidden-dual must complete the native prelight gate');
      assert.ok(hiddenDualChooseReply, 'hidden-dual must choose the native discard target');
      assert.ok(hiddenDualDiscardReply || hiddenDualDiscardAuto,
        'hidden-dual must discard the target card, either through the native request or the non-cancelable auto path');
      assert.ok(hiddenDualUseReply, 'hidden-dual must complete the native PlayCard Duel request');
      console.log(`PASS hidden-dual: native hidden trigger revealed Song Hùng, discarded the color source ` +
        `(${hiddenDualDiscardAuto ? 'auto' : 'interactive'}) and converted Slash to Duel`);
    } else if (!hiddenTianduScenario && testScenario !== 'rescue-normal' && testScenario !== 'rescue-battle' && testScenario !== 'founding') {
      assert.ok(manualCardReply,'A native PlayCard must receive one user-selected card/target/OK reply');
      console.log('PASS manual native PlayCard: offered card, Lua-enabled target/OK and one exact client reply');
    }
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
    if (!damageExchangeScenario && !hiddenScenario) {
      const cleanupPages = rescueScenario ? pages : [actor];
      for (const page of cleanupPages) {
        const trust = page.getByRole('button', { name: 'BOT chơi hộ', exact: true });
        if (await trust.isVisible()) await trust.click();
      }
    }
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
  // Founding acceptance ends when the native GeneralShown kingdom choice is
  // answered; that source path intentionally does not end the whole match.
  // Waiting for a result screen here would leave the QA runner playing an
  // unrelated full game after the rule under test has already passed.
  let publicBotAudit = (testBotAudit || damageExchangeScenario || hiddenScenario)
    ? (await Promise.all(pages.map(readPublicBotAudit))).map((audit) => sanitizePublicAudit(audit, [first.username, second.username]))
    : [];
  if (testScenario === 'founding') {
    finished = true;
  } else {
    await Promise.all(pages.map(p=>p.getByRole('button',{name:'Về sảnh',exact:true}).waitFor({timeout:900000})));
    finished = true;
    publicBotAudit = (testBotAudit || damageExchangeScenario || hiddenScenario)
      ? (await Promise.all(pages.map(readPublicBotAudit))).map((audit) => sanitizePublicAudit(audit, [first.username, second.username]))
      : [];
  }
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
      playCard: incoming.filter((packet) => packet.command === 'PlayCard').length,
      addSkillUseHistory: incoming.filter((packet) => packet.command === 'AddSkillUseHistory').length,
      setSkillUseHistory: incoming.filter((packet) => packet.command === 'SetSkillUseHistory').length,
      setSkillBranchUseHistory: incoming.filter((packet) => packet.command === 'SetSkillBranchUseHistory').length,
      askForSkillInvoke: incoming.filter((packet) => packet.command === 'AskForSkillInvoke').length,
      askForArrangeCards: incoming.filter((packet) => packet.command === 'AskForArrangeCards').length,
      askForUseActiveSkill: incoming.filter((packet) => packet.command === 'AskForUseActiveSkill').length,
      askForChoices: incoming.filter((packet) => packet.command === 'AskForChoices').length,
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
  if (damageExchangeScenario) {
    const publicLogs = publicBotAudit.flatMap((audit) => audit.logs);
    assert.ok(publicLogs.some((log) => /Ân Oán|恩怨|enyuan/iu.test(log)),
      'fazheng-enyuan must expose a public Ân Oán/恩怨 skill log');
    assert.ok(publicLogs.some((log) => /Di Kế|遗计|yiji/iu.test(log)),
      'fazheng-enyuan must expose a public Di Kế/遗计 skill log');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'fazheng-enyuan must finish after all four Slash steps');
    for (const result of ['longdan-slash-as-jink-dodge', 'source-gives-one-hand-card',
      'empty-source-loses-one-hp', 'yiji-two-to-self', 'fankui-one-from-source']) {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) => log.includes(result))),
        `Each native client must observe verified outcome ${result}`);
    }
    console.log('PASS fazheng-enyuan public audit: all four native HP/card-transfer outcomes verified and visible to both clients');
  } else if (hiddenRehideYijiScenario) {
    const expectedPosition = hiddenRehideYijiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.includes('Hidden Di Kế') && log.includes('positive-prelight-invoke-rehide') &&
      /prelight=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && /chuyển bài=2/iu.test(log) &&
      /úp lại=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Di Kế reveal/effect and retained prelight after re-hide in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-rehide-yiji must finish after the native reveal/distribution/re-hide branch');
    assert.equal(botAuditTrace.reduce((total, trace) => total + trace.askForSkillInvoke, 0), 2,
      'hidden-rehide-yiji must expose exactly the readiness gate and native Di Kế invoke');
    console.log(`PASS hidden-rehide-yiji public audit: both native clients observed reveal, Di Kế distribution and retained prelight after re-hide in the ${expectedPosition} slot`);
  } else if (hiddenYijiScenario) {
    const expectedBranch = hiddenYijiMode === 'positive' ? 'positive-prelight-invoke'
      : hiddenYijiMode === 'skip' ? 'skip-prelight' : 'negative-no-prelight';
    const expectedPosition = hiddenYijiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) => log.includes(`Hidden Di Kế`) && log.includes(expectedBranch))),
      `Both native clients must observe the ${expectedBranch} QA outcome`);
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) => log.includes(`Hidden Di Kế`) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Di Kế in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-yiji must finish after its one native damage branch');
    const expectedInvokes = hiddenYijiMode === 'negative' ? 1 : 2;
    const observedInvokes = botAuditTrace.reduce((total, trace) => total + trace.askForSkillInvoke, 0);
    assert.equal(observedInvokes, expectedInvokes,
      `hidden-yiji ${hiddenYijiMode} must expose exactly ${expectedInvokes} AskForSkillInvoke request(s)`);
    if (hiddenYijiMode === 'positive') {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) => log.includes('Hidden Di Kế') &&
        !log.includes('mở tướng=false') && log.includes('chuyển bài=2'))),
        'positive hidden-yiji must reveal the skill owner and move two Yiji cards');
    } else {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) => log.includes('Hidden Di Kế') &&
        (hiddenYijiMode === 'skip' ? log.includes('mở tướng=false') : log.includes('prelight=false')) &&
        log.includes('chuyển bài=0'))),
        `${hiddenYijiMode} hidden-yiji must retain the hidden owner without Yiji movement`);
    }
    console.log(`PASS hidden-yiji public audit: both native clients observed ${expectedBranch}, ` +
      `one damage and the expected AskForSkillInvoke count`);
  } else if (hiddenJianxiongScenario) {
    const expectedPosition = hiddenJianxiongDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Gian Hùng/iu.test(log) && /positive-prelight-invoke-obtain/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) && /lấy bài=1/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Jianxiong obtaining the damage card after revealing Cao Cao as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-jianxiong must finish after its native choice/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-jianxiong owner must receive the readiness gate and the real trigger invoke');
    console.log('PASS hidden-jianxiong public audit: both native clients observed Cao Cao reveal, choice and card obtain');
  } else if (hiddenFankuiScenario) {
    const expectedPosition = hiddenFankuiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Phản Quỹ/iu.test(log) && /positive-prelight-trigger-obtain/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) && /lấy bài=1/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Fankui obtaining the damage card after revealing Tư Mã Ý as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-fankui must finish after its native damage/effect/card-choice branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-fankui owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      'hidden-fankui source player must receive the native real-Slash request');
    console.log('PASS hidden-fankui public audit: both native clients observed Tư Mã Ý reveal, SkillEffect and one card obtain');
  } else if (hiddenKuangguScenario) {
    const expectedPosition = hiddenKuangguDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Cuồng Cốt|Hidden 狂骨/iu.test(log) && /BeforeHpChanged=true/iu.test(log) &&
      /Damage=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && /bốc bài=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Kuanggu BeforeHpChanged/Damage, reveal and draw in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-kuanggu must finish after its native damage/effect/choice branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-kuanggu owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-kuanggu source player must receive the private real-Slash request');
    console.log(`PASS hidden-kuanggu public audit: both native clients observed close-range damage, reveal and draw1 in the ${expectedPosition} slot`);
  } else if (hiddenLiegongScenario) {
    const expectedPosition = hiddenLiegongDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Liệt Cung|Hidden 烈弓/iu.test(log) && /TargetSpecified=true/iu.test(log) &&
      /Damage=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /sát thương=2/iu.test(log) && /mở tướng=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Liegong TargetSpecified, damage=2, reveal and slot ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-liegong must finish after its native TargetSpecified/damage-choice branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-liegong owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-liegong source player must receive the private real-Slash request');
    console.log(`PASS hidden-liegong public audit: both native clients observed TargetSpecified, reveal and damage+1 in the ${expectedPosition} slot`);
  } else if (hiddenJueqingScenario) {
    const expectedPosition = hiddenJueqingDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Tuyệt Tình|Hidden 绝情/iu.test(log) && /PreDamage=true/iu.test(log) &&
      /Damage=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mất máu=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Jueqing PreDamage, HP loss and reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-jueqing must finish after its native PreDamage/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-jueqing owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-jueqing source player must receive the private real-Slash request');
    console.log(`PASS hidden-jueqing public audit: both native clients observed PreDamage conversion and reveal in the ${expectedPosition} slot`);
  } else if (hiddenLuoshenScenario) {
    const expectedPosition = hiddenLuoshenDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden 洛神/iu.test(log) && /positive-prelight-phase-start-judge-obtain/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) && /lấy bài đen=1/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Luoshen after Zhen Ji revealed as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-luoshen must finish after its native phase-start/judgment branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-luoshen owner must receive the readiness gate and at least one real trigger/continuation invoke');
    console.log('PASS hidden-luoshen public audit: both native clients observed phase-start reveal, judgment and black-card obtain');
  } else if (hiddenTianduScenario) {
    const expectedPosition = hiddenTianduDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Thiên Đố|Hidden 天妒/iu.test(log) && /FinishJudge=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /lấy lá phán xét=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Tiandu FinishJudge, reveal and judged-card obtain in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-tiandu must finish after its native FinishJudge obtain branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-tiandu owner must receive the native prelight readiness gate');
    console.log('PASS hidden-tiandu public audit: both native clients observed FinishJudge, Guo Jia reveal and judged-card obtain');
  } else if (hiddenJizhiScenario) {
    const expectedPosition = hiddenJizhiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Tập Trí/iu.test(log) && /CardUsing Duel=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
      /rút bài=1/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Jizhi CardUsing, reveal and one-card draw in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-jizhi must finish after its native Duel/CardUsing branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-jizhi owner must receive the readiness gate and the real optional CardUsing invoke');
    console.log('PASS hidden-jizhi public audit: both native clients observed Duel, Huang Yueying reveal and native draw');
  } else if (hiddenMingshiScenario) {
    const expectedPosition = hiddenMingshiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Danh Sĩ/iu.test(log) && /DamageInflicted=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
      /sát thương=0/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Mingshi DamageInflicted reduction and reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-mingshi must finish after its native hidden-source Slash branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-mingshi owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      'hidden-mingshi hidden source must receive the private real-Slash request');
    console.log('PASS hidden-mingshi public audit: both native clients observed hidden-source damage reduction and Kong Rong reveal');
  } else if (hiddenGongqingScenario) {
    const expectedPosition = hiddenGongqingDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Công Thanh|Hidden 公清/iu.test(log) && /DetermineDamageInflicted=true/iu.test(log) &&
      /DamageInflicted=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /sát thương thấp=1/iu.test(log) && /sát thương xa=2/iu.test(log) &&
      /mở tướng=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Gongqing low/high damage branches and reveal Pan Jun in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-gongqing must finish after its two native damage/effect branches');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-gongqing owner must receive the native prelight readiness gate');
    console.log(`PASS hidden-gongqing public audit: both native clients observed low-range damage=1, high-range damage=2 and Pan Jun reveal in the ${expectedPosition} slot`);
  } else if (hiddenQianxunScenario) {
    const expectedPosition = hiddenQianxunDeputyScenario ? 'phó tướng' : 'chủ tướng';
    if (hiddenQianxunIndulgenceScenario) {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
        /Hidden Khiêm Tốn/iu.test(log) && /BeforeCardsMove Lạc Bất Tư Thục=true/iu.test(log) &&
        /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
        /vào phán xét=false/iu.test(log) && /chuyển bỏ=true/iu.test(log) &&
        log.includes(`vị trí=${expectedPosition}`))),
        `Both native clients must observe Qianxun cancelling Indulgence's Judge move after revealing Lục Tốn in the ${expectedPosition} slot`);
    } else {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
        /Hidden Khiêm Tốn/iu.test(log) && /TargetConfirming Thuận Thủ=true/iu.test(log) &&
        /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
        /hủy mục tiêu=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
        `Both native clients must observe Qianxun cancelling Snatch after revealing Lục Tốn in the ${expectedPosition} slot`);
    }
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      hiddenQianxunIndulgenceScenario
        ? 'hidden-qianxun-indulgence must finish after its native BeforeCardsMove cancellation branch'
        : 'hidden-qianxun must finish after its native TargetConfirming cancellation branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-qianxun owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      hiddenQianxunIndulgenceScenario
        ? 'hidden-qianxun-indulgence source player must receive the private real-Indulgence request'
        : 'hidden-qianxun source player must receive the private real-Snatch request');
    console.log(hiddenQianxunIndulgenceScenario
      ? 'PASS hidden-qianxun public audit: both native clients observed Indulgence judge cancellation, discard mirror and Lục Tốn reveal'
      : 'PASS hidden-qianxun public audit: both native clients observed valid Snatch cancellation and Lục Tốn reveal');
  } else if (hiddenKongchengScenario) {
    const expectedPosition = hiddenKongchengDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Không Thành/iu.test(log) && /TargetConfirming Quyết Đấu=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /hết bài=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && /hủy mục tiêu=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Kongcheng cancelling Duel after revealing Zhuge Liang in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-kongcheng must finish after its native TargetConfirming cancellation branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-kongcheng owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      'hidden-kongcheng source player must receive the private real-Duel request');
    console.log('PASS hidden-kongcheng public audit: both native clients observed empty-hand Duel cancellation and Zhuge Liang reveal');
  } else if (hiddenWeimuScenario) {
    const expectedPosition = hiddenWeimuDeputyScenario ? 'phó tướng' : 'chủ tướng';
    if (hiddenWeimuIndulgenceScenario) {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
        /Hidden 帷幕/iu.test(log) && /BeforeCardsMove Lạc Bất Tư Thục đen=true/iu.test(log) &&
        /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
        /vào phán xét=false/iu.test(log) && /chuyển bỏ=true/iu.test(log) &&
        log.includes(`vị trí=${expectedPosition}`))),
        `Both native clients must observe Weimu discarding black Indulgence before Judge after revealing Jia Xu in the ${expectedPosition} slot`);
    } else {
      assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
        /Hidden 帷幕/iu.test(log) && /TargetConfirming Quyết Đấu đen=true/iu.test(log) &&
        /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
        /hủy mục tiêu=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
        `Both native clients must observe Weimu cancelling a black Duel after revealing Jia Xu in the ${expectedPosition} slot`);
    }
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      hiddenWeimuIndulgenceScenario
        ? 'hidden-weimu-indulgence must finish after its native BeforeCardsMove cancellation branch'
        : 'hidden-weimu must finish after its native TargetConfirming cancellation branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-weimu owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      hiddenWeimuIndulgenceScenario
        ? 'hidden-weimu-indulgence source player must receive the private real black Indulgence request'
        : 'hidden-weimu source player must receive the private real black Duel request');
    console.log(hiddenWeimuIndulgenceScenario
      ? 'PASS hidden-weimu public audit: both native clients observed black Indulgence judge cancellation, discard mirror and Jia Xu reveal'
      : 'PASS hidden-weimu public audit: both native clients observed black Trick cancellation and Jia Xu reveal');
  } else if (hiddenXiaojiScenario) {
    const expectedPosition = hiddenXiaojiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden 枭姬/iu.test(log) && /AfterCardsMove mất trang bị=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
      /bốc bài=[13]/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Xiaoji after equipment loss and Sun Shangxiang reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-xiaoji must finish after its native AfterCardsMove branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-xiaoji owner must receive the private prelight readiness gate');
    console.log('PASS hidden-xiaoji public audit: both native clients observed equipment loss, Xiaoji draw and Sun Shangxiang reveal');
  } else if (hiddenGuanxingScenario) {
    const expectedPosition = hiddenGuanxingDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden 观星|Hidden Quan Tinh/iu.test(log) && /EventPhaseStart=true/iu.test(log) &&
      /AskForArrangeCards=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && /đã xếp=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Guanxing EventPhaseStart, native arrange and Zhuge Liang reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-guanxing must finish after its native phase-start/arrange branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-guanxing owner must receive the readiness gate and the real trigger invoke');
    assert.ok(botAuditTrace[scenarioClient].askForArrangeCards >= 1,
      'hidden-guanxing owner must receive the private AskForArrangeCards request');
    console.log('PASS hidden-guanxing public audit: both native clients observed Zhuge Liang reveal and AskForArrangeCards completion');
  } else if (hiddenYingziScenario) {
    const expectedPosition = hiddenYingziDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden 英姿|Hidden Anh Tư/iu.test(log) && /DrawNCards=true/iu.test(log) &&
      /AfterDrawNCards=true/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && /bốc bài=3/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Yingzi DrawNCards=3 and Zhou Yu reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-yingzi must finish after its native DrawNCards branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-yingzi owner must receive the private prelight readiness gate');
    assert.equal(botAuditTrace[scenarioClient].askForArrangeCards, 0,
      'hidden-yingzi must not open an arrange dialog for its DrawNCards trigger');
    console.log(`PASS hidden-yingzi public audit: both native clients observed DrawNCards=3, Zhou Yu reveal and fake-to-active transition in the ${expectedPosition} slot`);
  } else if (hiddenTianxiangScenario) {
    const expectedPosition = hiddenTianxiangDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Thiên Hương/iu.test(log) && /DetermineDamageInflicted=true/iu.test(log) &&
      /AskForUseActiveSkill=true/iu.test(log) && /AskForChoices=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /sát thương bị chặn=true/iu.test(log) &&
      /mục tiêu mất HP=true/iu.test(log) && /trả bài=true/iu.test(log) &&
      /mở tướng=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Tianxiang card/target choice, damage prevention and Xiao Qiao reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-tianxiang must finish after its native damage-redirect branch');
    // The readiness gate is the only AskForSkillInvoke in this path.  Native
    // Tianxiang performs its trigger cost through AskForUseActiveSkill, so a
    // second AskForSkillInvoke would not be source-faithful.
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-tianxiang owner must receive the readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill >= 1,
      'hidden-tianxiang owner must receive the private heart-card/target request');
    assert.ok(botAuditTrace[scenarioClient].askForChoices >= 1,
      'hidden-tianxiang owner must receive the private lose-HP/damage choice');
    console.log('PASS hidden-tianxiang public audit: both native clients observed heart-card/target selection, Xiao Qiao reveal, prevented damage and returned card');
  } else if (hiddenDuanchangScenario) {
    const expectedPosition = hiddenDuanchangDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Đoạn Trường/iu.test(log) && /Death=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /người chết mở tướng=true/iu.test(log) &&
      /killer chọn chủ tướng=true/iu.test(log) && /killer mất kỹ năng chủ=true/iu.test(log) &&
      /kỹ năng phó còn lại=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Duanchang Death, main-general choice and skill loss in the ${expectedPosition} placement`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-duanchang must finish after its native Death/skill-loss branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-duanchang owner must receive the prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForChoices >= 1,
      'hidden-duanchang owner must receive the native killer slot choice');
    console.log('PASS hidden-duanchang public audit: both native clients observed Death, Cai Wenji reveal and chosen Cao Cao skill loss');
  } else if (hiddenRevealScenario) {
    const expectedPosition = hiddenRevealDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Mở tướng|reveal_skill&/iu.test(log) && /Lục Tốn đã mở=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe the hidden reveal helper opening Lục Tốn as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-reveal must finish after its native active reveal branch');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill >= 1,
      'hidden-reveal owner must receive the private AskForUseActiveSkill request');
    assert.equal(botAuditTrace[1 - scenarioClient].askForUseActiveSkill, 0,
      'hidden-reveal must keep the private active-skill request away from the opponent client');
    console.log('PASS hidden-reveal public audit: both native clients observed reveal_skill& and active Qianxun; ' +
      'only the hidden owner received the private active request');
  } else if (hiddenActiveScenario) {
    const expectedPosition = hiddenActiveMainScenario ? 'chủ tướng' : 'phó tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Chế Hành/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /Tôn Quyền đã mở=true/iu.test(log) && /Lục Tốn còn úp=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Chế Hành after Sun Quan revealed as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-active must finish after its native PlayCard skill branch');
    assert.ok(botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-active owner must receive the private native PlayCard request');
    assert.equal(botAuditTrace[1 - scenarioClient].playCard, 0,
      'hidden-active must keep the private PlayCard request away from the opponent client');
    console.log('PASS hidden-active public audit: both native clients observed Chế Hành, ' +
      'Sun Quan reveal and Lục Tốn remaining hidden; only the owner received PlayCard');
  } else if (hiddenFanjianScenario) {
    const expectedPosition = hiddenFanjianDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Phản Gián/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /mở Chu Du=true/iu.test(log) && /fake=false/iu.test(log) &&
      /tặng bài=true/iu.test(log) && /mất HP=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Phản Gián SkillEffect, gift and lose-HP branch in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-fanjian must finish after its native PlayCard, gift and target-choice branch');
    assert.ok(botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-fanjian owner must receive the private native PlayCard request');
    assert.equal(botAuditTrace[1 - scenarioClient].playCard, 0,
      'hidden-fanjian must keep the private PlayCard request away from the target client');
    assert.ok(botAuditTrace[1 - scenarioClient].askForChoices >= 1,
      'hidden-fanjian target must receive the native lose-HP choice');
    console.log(`PASS hidden-fanjian public audit: both native clients observed SkillEffect, Peach gift and target lose-HP choice in the ${expectedPosition} slot`);
  } else if (hiddenViewAsScenario) {
    const expectedPosition = hiddenViewAsMainScenario ? 'chủ tướng' : 'phó tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Long Đảm/iu.test(log) && /SkillEffect=true/iu.test(log) &&
      /Triệu Vân đã mở=true/iu.test(log) && /Thiểm→Sát=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Long Đảm after Triệu Vân revealed as ${expectedPosition}`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-view-as must finish after its native PlayCard skill branch');
    assert.ok(botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-view-as owner must receive the private native PlayCard request');
    assert.equal(botAuditTrace[1 - scenarioClient].playCard, 0,
      'hidden-view-as must keep the private PlayCard request away from the opponent client');
    console.log('PASS hidden-view-as public audit: both native clients observed Long Đảm, ' +
      'Triệu Vân reveal and Jink→Slash conversion; only the owner received PlayCard');
  }
  const scenarioBoardStates = damageExchangeScenario
    ? await Promise.all(pages.map(async (page) => {
        const states = await page.locator('.board-player').allTextContents();
        return states.map((value) => [first.username, second.username, first.password, second.password]
          .reduce((safe, secret) => safe.split(secret).join('[test-account]'), value).replace(/\s+/gu, ' ').trim());
      }))
    : [];
  if (damageExchangeScenario) {
    for (const states of scenarioBoardStates) {
      assert.ok(states.some((text) => /Quách Gia/.test(text) && /Tư Mã Ý/.test(text) &&
        /♥\s*1\s*\/\s*3/.test(text) && /3 lá trên tay/.test(text)), 'Both UIs must retain Wei final HP 1/3 and three hand cards');
      assert.ok(states.some((text) => /Triệu Vân/.test(text) && /Pháp Chính/.test(text) &&
        /♥\s*1\s*\/\s*3/.test(text) && /1 lá trên tay/.test(text)), 'Both UIs must retain Shu final HP 1/3 and one hand card');
    }
    const evidenceDir = path.join(repo, 'scratch/evidence/cp65-native');
    mkdirSync(evidenceDir, { recursive: true });
    for (let i = 0; i < pages.length; i++) {
      await pages[i].screenshot({ path: path.join(evidenceDir, `scenario-board-client-${i + 1}.png`),
        fullPage: true, mask: [pages[i].locator('.board-player-name'), pages[i].locator('.player-item'),
          pages[i].locator('.board-logs li').filter({ hasText: first.username }),
          pages[i].locator('.board-logs li').filter({ hasText: second.username })] });
    }
  }
  for(let i=0;i<2;i++){
    if (testScenario !== 'founding') {
      assert.ok(traces[i].some(t=>t.direction==='incoming' && t.command==='GameOver'));
    }
    const replies=traces[i].filter(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY);
    assert.equal(new Set(replies.map(t=>t.requestId)).size,replies.length,'one reply per request');
    if (testScenario !== 'founding') {
      await pages[i].getByRole('button',{name:'Về sảnh',exact:true}).click();
      await pages[i].getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor();
      await pages[i].getByRole('button',{name:'Ngắt kết nối',exact:true}).click();
    }
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`${candidateId}-${testScenario ? `${testScenario}-` : ''}${testGatewayRestart?'gateway-restart':testRecovery?'reconnect':'multiplayer'}-live-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),manualCardReply,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,hiddenYijiMode:hiddenYijiScenario ? hiddenYijiMode : null,hiddenGateReply,nativeQaGateSeen,nativeQaGateCommand,nativeQaGateTimeoutMs,nativeQaGateFailureObserved,hiddenYijiAsked,hiddenYijiInvoked,hiddenYijiReply,hiddenJianxiongGateReply,hiddenJianxiongDamageReply,hiddenJianxiongInvoked,hiddenJianxiongChoiceReply,hiddenFankuiGateReply,hiddenFankuiDamageReply,hiddenFankuiChoiceReply,hiddenLuoshenGateReply,hiddenLuoshenInvoked,hiddenLuoshenInvokeCount,hiddenTianduGateReply,hiddenJizhiGateReply,hiddenJizhiCardReply,hiddenJizhiInvoked,hiddenMingshiGateReply,hiddenMingshiCardReply,hiddenGongqingGateReply,hiddenQianxunGateReply,hiddenQianxunCardReply,hiddenKongchengGateReply,hiddenKongchengCardReply,hiddenWeimuGateReply,hiddenWeimuCardReply,hiddenXiaojiGateReply,hiddenGuanxingGateReply,hiddenGuanxingInvoked,hiddenGuanxingArrangeReply,hiddenTianxiangGateReply,hiddenTianxiangCardReply,hiddenTianxiangInvoked,hiddenTianxiangChoiceReply,hiddenDuanchangGateReply,hiddenDuanchangChoiceReply,hiddenRevealGateReply,hiddenRevealReply,hiddenActiveGateReply,hiddenActiveReply,hiddenFanjianGateReply,hiddenFanjianReply,hiddenFanjianChoiceReply,hiddenDualGateReply,hiddenDualChooseReply,hiddenDualDiscardReply,hiddenDualDiscardAuto,hiddenDualUseReply,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioBattleRoyalObserved,scenarioFoundingReply,scenarioBoardStates,scenarioSlashReplies,scenarioLongdanDefenseReply,scenarioLongdanAttackReply,scenarioEnyuanReply,scenarioYijiInvoked,scenarioYijiReply,scenarioFankuiInvoked,scenarioFankuiReply,scenarioObservations,damageExchange:damageExchangeScenario ? {public:publicBotAudit,trace:botAuditTrace} : null,hiddenYiji:hiddenYijiScenario ? {mode:hiddenYijiMode,public:publicBotAudit,trace:botAuditTrace} : null,hiddenJianxiong:hiddenJianxiongScenario ? {deputy:hiddenJianxiongDeputyScenario,public:publicBotAudit,trace:botAuditTrace} : null,hiddenFankui:hiddenFankuiScenario ? {deputy:hiddenFankuiDeputyScenario,gate:hiddenFankuiGateReply,damage:hiddenFankuiDamageReply,cardChosen:hiddenFankuiChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenLuoshen:hiddenLuoshenScenario ? {deputy:hiddenLuoshenDeputyScenario,gate:hiddenLuoshenGateReply,invoked:hiddenLuoshenInvoked,invokeCount:hiddenLuoshenInvokeCount,public:publicBotAudit,trace:botAuditTrace} : null,hiddenTiandu:hiddenTianduScenario ? {deputy:hiddenTianduDeputyScenario,gate:hiddenTianduGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenJizhi:hiddenJizhiScenario ? {deputy:hiddenJizhiDeputyScenario,gate:hiddenJizhiGateReply,card:hiddenJizhiCardReply,invoked:hiddenJizhiInvoked,public:publicBotAudit,trace:botAuditTrace} : null,hiddenMingshi:hiddenMingshiScenario ? {deputy:hiddenMingshiDeputyScenario,gate:hiddenMingshiGateReply,card:hiddenMingshiCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenGongqing:hiddenGongqingScenario ? {deputy:hiddenGongqingDeputyScenario,gate:hiddenGongqingGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenQianxun:hiddenQianxunScenario ? {indulgence:hiddenQianxunIndulgenceScenario,deputy:hiddenQianxunDeputyScenario,gate:hiddenQianxunGateReply,card:hiddenQianxunCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenKongcheng:hiddenKongchengScenario ? {deputy:hiddenKongchengDeputyScenario,gate:hiddenKongchengGateReply,card:hiddenKongchengCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenWeimu:hiddenWeimuScenario ? {deputy:hiddenWeimuDeputyScenario,gate:hiddenWeimuGateReply,card:hiddenWeimuCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenXiaoji:hiddenXiaojiScenario ? {deputy:hiddenXiaojiDeputyScenario,gate:hiddenXiaojiGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenGuanxing:hiddenGuanxingScenario ? {deputy:hiddenGuanxingDeputyScenario,gate:hiddenGuanxingGateReply,invoked:hiddenGuanxingInvoked,arrange:hiddenGuanxingArrangeReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenTianxiang:hiddenTianxiangScenario ? {deputy:hiddenTianxiangDeputyScenario,gate:hiddenTianxiangGateReply,card:hiddenTianxiangCardReply,invoked:hiddenTianxiangInvoked,choice:hiddenTianxiangChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenDuanchang:hiddenDuanchangScenario ? {deputy:hiddenDuanchangDeputyScenario,gate:hiddenDuanchangGateReply,choice:hiddenDuanchangChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenReveal:hiddenRevealScenario ? {gate: hiddenRevealGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenActive:hiddenActiveScenario ? {gate:hiddenActiveGateReply,reply:hiddenActiveReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenFanjian:hiddenFanjianScenario ? {deputy:hiddenFanjianDeputyScenario,gate:hiddenFanjianGateReply,reply:hiddenFanjianReply,choice:hiddenFanjianChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenDual:hiddenDualScenario ? {gate:hiddenDualGateReply,choose:hiddenDualChooseReply,discard:hiddenDualDiscardReply || hiddenDualDiscardAuto,discardAuto:hiddenDualDiscardAuto,viewAs:hiddenDualUseReply,public:publicBotAudit,trace:botAuditTrace} : null,botAudit:testBotAudit ? {seatCapacity:playerCapacity,realClientSeats:pages.length,nativeBotSeats:playerCapacity-pages.length,trace:botAuditTrace,public:publicBotAudit} : null,scope:testGatewayRestart ? 'two real accounts / first client isolated gateway process restart / independent second gateway peer / Chrome mobile viewports / Trust; no physical device or hosted restart' : testRecovery ? 'two real accounts / controlled WebSocket close / native server Reconnect / Chrome mobile viewports / Trust; no physical network or device' : testBotAudit ? 'four seats / two real accounts / two native bots / public GameLog and skill-history audit / no physical device' : damageExchangeScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / manual replies for both seats; no Trust or physical device' : hiddenYijiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-yiji ${hiddenYijiMode} branch / manual prelight gate; no physical device` : hiddenJianxiongScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden-jianxiong prelight, invoke and obtain-card choice / no physical device' : hiddenFankuiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-fankui ${hiddenFankuiDeputyScenario ? 'deputy' : 'main'} prelight, real damage and source-card choice / no physical device` : hiddenFanjianScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-fanjian ${hiddenFanjianDeputyScenario ? 'deputy' : 'main'} active reveal, Peach gift and target lose-HP choice / no physical device` : hiddenLuoshenScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-luoshen ${hiddenLuoshenDeputyScenario ? 'deputy' : 'main'} prelight, EventPhaseStart and judgment obtain / no physical device` : hiddenTianduScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-tiandu ${hiddenTianduDeputyScenario ? 'deputy' : 'main'} prelight, FinishJudge and judged-card obtain / no physical device` : hiddenJizhiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-jizhi ${hiddenJizhiDeputyScenario ? 'deputy' : 'main'} prelight, Duel CardUsing and draw / no physical device` : hiddenMingshiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-mingshi ${hiddenMingshiDeputyScenario ? 'deputy' : 'main'} prelight, hidden-source Slash and zero damage / no physical device` : hiddenGongqingScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-gongqing ${hiddenGongqingDeputyScenario ? 'deputy' : 'main'} prelight, low/high attack-range damage branches and Pan Jun reveal / no physical device` : hiddenQianxunScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-qianxun ${hiddenQianxunIndulgenceScenario ? 'BeforeCardsMove Indulgence discard mirror' : 'TargetConfirming Snatch cancellation'} ${hiddenQianxunDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenWeimuScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-weimu TargetConfirming black Duel cancellation ${hiddenWeimuDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenXiaojiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-xiaoji AfterCardsMove equipment loss and draw ${hiddenXiaojiDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenGuanxingScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-guanxing EventPhaseStart reveal and AskForArrangeCards ${hiddenGuanxingDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenTianxiangScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-tianxiang DetermineDamageInflicted heart-card/target choice, lose-HP branch and reveal ${hiddenTianxiangDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenDuanchangScenario ? `two real accounts + two native bots / four-seat C++ / hidden-duanchang fk.Death, killer main-general choice and slot skill loss ${hiddenDuanchangDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenRevealScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden reveal_skill& active helper; no physical device' : hiddenActiveScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden active Chế Hành PlayCard / no physical device' : hiddenDualScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden Song Hùng trigger, auto-discard color source and Duel ViewAs; no physical device' : 'two real accounts / two Chrome mobile viewports / native Trust; no physical device', recovered,gatewayRestart:testGatewayRestart,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks:string[]}).__tqsMemoryStacks))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null))),
    distIndexSha256,candidateIdentity,qaPackageIdentity,result:errors.length ? 'FAIL' : 'PASS',deploymentUrl:deploymentUrl ?? null,traces,errors,errorContexts},null,2));
  if (hiddenKongchengScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-kongcheng evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenKongchengGateReply = hiddenKongchengGateReply;
    evidence.hiddenKongchengCardReply = hiddenKongchengCardReply;
    evidence.hiddenKongcheng = {
      deputy: hiddenKongchengDeputyScenario,
      gate: hiddenKongchengGateReply,
      card: hiddenKongchengCardReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-kongcheng TargetConfirming Duel cancellation ${hiddenKongchengDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenKuangguScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-kuanggu evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenKuangguGateReply = hiddenKuangguGateReply;
    evidence.hiddenKuangguDamageReply = hiddenKuangguDamageReply;
    evidence.hiddenKuangguChoiceReply = hiddenKuangguChoiceReply;
    evidence.hiddenKuanggu = {
      deputy: hiddenKuangguDeputyScenario,
      gate: hiddenKuangguGateReply,
      damage: hiddenKuangguDamageReply,
      choice: hiddenKuangguChoiceReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-kuanggu BeforeHpChanged→Damage close-range Slash and draw1 choice ${hiddenKuangguDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenLiegongScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-liegong evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenLiegongGateReply = hiddenLiegongGateReply;
    evidence.hiddenLiegongDamageReply = hiddenLiegongDamageReply;
    evidence.hiddenLiegongChoiceReply = hiddenLiegongChoiceReply;
    evidence.hiddenLiegong = {
      deputy: hiddenLiegongDeputyScenario,
      gate: hiddenLiegongGateReply,
      damage: hiddenLiegongDamageReply,
      choice: hiddenLiegongChoiceReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-liegong TargetSpecified Slash, reveal and damage+1 choice ${hiddenLiegongDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenJueqingScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-jueqing evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenJueqingGateReply = hiddenJueqingGateReply;
    evidence.hiddenJueqingDamageReply = hiddenJueqingDamageReply;
    evidence.hiddenJueqing = {
      deputy: hiddenJueqingDeputyScenario,
      gate: hiddenJueqingGateReply,
      damage: hiddenJueqingDamageReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-jueqing PreDamage Slash, reveal and HP-loss conversion ${hiddenJueqingDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenWeimuScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-weimu evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenWeimuGateReply = hiddenWeimuGateReply;
    evidence.hiddenWeimuCardReply = hiddenWeimuCardReply;
    evidence.hiddenWeimu = {
      indulgence: hiddenWeimuIndulgenceScenario,
      deputy: hiddenWeimuDeputyScenario,
      gate: hiddenWeimuGateReply,
      card: hiddenWeimuCardReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-weimu ${hiddenWeimuIndulgenceScenario ? 'BeforeCardsMove black Indulgence discard mirror' : 'TargetConfirming black Duel cancellation'} ${hiddenWeimuDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenXiaojiScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-xiaoji evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenXiaojiGateReply = hiddenXiaojiGateReply;
    evidence.hiddenXiaoji = {
      deputy: hiddenXiaojiDeputyScenario,
      gate: hiddenXiaojiGateReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-xiaoji AfterCardsMove equipment loss and draw ${hiddenXiaojiDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenYingziScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-yingzi evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenYingziGateReply = hiddenYingziGateReply;
    evidence.hiddenYingzi = {
      deputy: hiddenYingziDeputyScenario,
      gate: hiddenYingziGateReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-yingzi DrawNCards extra-card reveal ${hiddenYingziDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenTianxiangScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-tianxiang evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenTianxiangGateReply = hiddenTianxiangGateReply;
    evidence.hiddenTianxiangCardReply = hiddenTianxiangCardReply;
    evidence.hiddenTianxiangInvoked = hiddenTianxiangInvoked;
    evidence.hiddenTianxiangChoiceReply = hiddenTianxiangChoiceReply;
    evidence.hiddenTianxiang = {
      deputy: hiddenTianxiangDeputyScenario,
      gate: hiddenTianxiangGateReply,
      card: hiddenTianxiangCardReply,
      invoked: hiddenTianxiangInvoked,
      choice: hiddenTianxiangChoiceReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-tianxiang DetermineDamageInflicted heart-card/target choice, lose-HP branch and reveal ${hiddenTianxiangDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (hiddenRehideYijiScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-rehide-yiji evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenRehideYiji = {
      deputy: hiddenRehideYijiDeputyScenario,
      gate: hiddenGateReply,
      yijiAsked: hiddenYijiAsked,
      yijiInvoked: hiddenYijiInvoked,
      yijiReply: hiddenYijiReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-rehide-yiji reveal, Di Kế distribution and hideGeneral fake/prelight reattachment ${hiddenRehideYijiDeputyScenario ? 'deputy' : 'main'} / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(evidence, null, 2));
  }
  if (testScenario === 'founding') {
    await Promise.all(pages.map((page) => page.close()));
  }
  assert.deepEqual(errors,[]);
  console.log(testScenario === 'founding'
    ? 'PASS both clients: founding choice evidence saved; browser sessions closed after the source choice (no GameOver required by this scenario)'
    : 'PASS both clients: real GameOver / result / lobby / clean disconnect; sanitized trace saved');
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
  writeFileSync(path.join(out,`reconnect-failure-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),result:'FAIL',candidateId,deploymentUrl:deploymentUrl ?? null,feedback,distIndexSha256,candidateIdentity,qaPackageIdentity,recovered,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,nativeQaGateSeen,nativeQaGateCommand,nativeQaGateTimeoutMs,nativeQaGateFailureObserved,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioFoundingReply,scenarioObservations,traces,errors,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks?:string[]}).__tqsMemoryStacks ?? []).catch(()=>[]))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null).catch(()=>null))),
    errorContexts,scope:'metadata and numeric heap/callback telemetry only; pending safe GameOver cleanup'},null,2));
  if(gameStarted && !finished && !nativeQaGateFailureObserved){
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
  } else if (nativeQaGateFailureObserved) {
    console.error('Native QA readiness gate was not observed; skipping GameOver wait because server/package setup is already the failing boundary');
  }
  process.exitCode=1;
}finally{
  clearInterval(progressTimer);
  await browser?.close();await new Promise<void>(resolve=>server?server.httpServer.close(()=>resolve()):resolve());
  gateway?.kill('SIGTERM');peerGateway?.kill('SIGTERM');
  rmSync(frozenDist,{recursive:true,force:true});
}
