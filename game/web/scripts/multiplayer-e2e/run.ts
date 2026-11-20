/** Two distinct private test accounts, one frozen candidate, real C++ server.
 * Only command/request metadata is persisted; credentials and game payloads stay in memory. */
import assert from 'node:assert/strict';
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { once } from 'node:events';
import { existsSync, readFileSync, writeFileSync, statSync, mkdirSync, cpSync, mkdtempSync, rmSync, readdirSync } from 'node:fs';
import { randomBytes, createHash } from 'node:crypto';
import { loadEnvFile } from 'node:process';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import { fileURLToPath } from 'node:url';
import { preview } from 'vite';
import { chromium, type Page, type WebSocketRoute } from 'playwright-core';
import { PacketStream, RawPacketStream, CLIENT_REPLY, PacketType } from '../../src/engine/packet';
import { P1_QA_SOURCE_BASELINE, verifyCandidateIdentity, verifyQaPackageManifest, verifyQaSourceIdentity } from './identity';
import { assertTqs1Ticket, createTqs1Ticket } from './qa-ticket';
import { sanitizeQaEvidence } from './evidence-sanitize';
import {
  PRIVACY_CATEGORIES, SUPPLEMENTAL_CHANNELS, parsePrivacyCoverage,
  parsePrivacyAudit, parseSupplementalCoverage,
} from './native-privacy';

type LiveScenario =
  | ''
  | 'draw-sequence'
  | 'card-chosen'
  | 'cards-and-choice'
  | 'poxi'
  | 'rescue-normal'
  | 'rescue-battle'
  | 'founding'
  | 'fazheng-enyuan'
  | 'hidden-yiji'
  | 'hidden-yiji-deputy'
  | 'hidden-rehide-yiji'
  | 'hidden-rehide-yiji-deputy'
  | 'hidden-jianxiong'
  | 'hidden-jianxiong-deputy'
  | 'hidden-fankui'
  | 'hidden-fankui-deputy'
  | 'hidden-reveal'
  | 'hidden-reveal-deputy'
  | 'hidden-active'
  | 'hidden-active-main'
  | 'delta-xiongsuan'
  | 'delta-wenji'
  | 'delta-lord-wenji'
  | 'delta-qiance'
  | 'delta-jianchu'
  | 'delta-tieqi'
  | 'delta-xishe'
  | 'delta-chujue'
  | 'delta-zhente'
  | 'delta-halberd'
  | 'delta-sijian'
  | 'delta-bawei'
  | 'delta-fengshi-siege'
  | 'delta-fengshi-no-siege'
  | 'ai-trace'
  | 'chooser-trace'
  | 'general-pair-trace'
  | 'general-pair-match-a'
  | 'general-pair-match-b'
  | 'general-pair-match-c'
  | 'general-pair-match-d'
  | 'general-pair-match-mixed-a'
  | 'general-pair-match-mixed-b'
  | 'general-pair-match-mixed-c'
  | 'general-pair-match-mixed-d'
  | 'hidden-fanjian'
  | 'hidden-fanjian-deputy'
  | 'hidden-view-as'
  | 'hidden-view-as-main'
  | 'hidden-dual'
  | 'hidden-luoshen'
  | 'hidden-luoshen-deputy'
  | 'hidden-tiandu'
  | 'hidden-tiandu-deputy'
  | 'hidden-jizhi'
  | 'hidden-jizhi-deputy'
  | 'hidden-mingshi'
  | 'hidden-mingshi-deputy'
  | 'hidden-gongqing'
  | 'hidden-gongqing-deputy'
  | 'hidden-enyuan'
  | 'hidden-enyuan-deputy'
  | 'hidden-fuyin'
  | 'hidden-fuyin-deputy'
  | 'hidden-qianxun'
  | 'hidden-qianxun-deputy'
  | 'hidden-qianxun-indulgence'
  | 'hidden-qianxun-indulgence-deputy'
  | 'hidden-kongcheng'
  | 'hidden-kongcheng-deputy'
  | 'hidden-weimu'
  | 'hidden-weimu-deputy'
  | 'hidden-weimu-indulgence'
  | 'hidden-weimu-indulgence-deputy'
  | 'hidden-xiaoji'
  | 'hidden-xiaoji-deputy'
  | 'hidden-guanxing'
  | 'hidden-guanxing-deputy'
  | 'hidden-yingzi'
  | 'hidden-yingzi-deputy'
  | 'hidden-tianxiang'
  | 'hidden-tianxiang-deputy'
  | 'hidden-duanchang'
  | 'hidden-duanchang-deputy'
  | 'hidden-liegong'
  | 'hidden-liegong-deputy'
  | 'hidden-kuanggu'
  | 'hidden-kuanggu-deputy'
  | 'hidden-jueqing'
  | 'hidden-jueqing-deputy'
  | 'hidden-ejue'
  | 'hidden-ejue-deputy'
  | 'hidden-dufu'
  | 'hidden-dufu-deputy'
  | 'hidden-jianzhi'
  | 'hidden-jianzhi-deputy'
  | 'hidden-zhiman'
  | 'hidden-zhiman-deputy'
  | 'hidden-jilix'
  | 'hidden-jilix-deputy';
const testScenario = (process.env.TQS_LIVE_SCENARIO ?? (process.argv.includes('--card-chosen') ? 'card-chosen' : '')) as LiveScenario;
assert.ok(testScenario === '' || testScenario === 'draw-sequence' || testScenario === 'card-chosen' || testScenario === 'cards-and-choice' || testScenario === 'poxi' ||
  testScenario === 'rescue-normal' || testScenario === 'rescue-battle' || testScenario === 'founding' || testScenario === 'fazheng-enyuan' ||
  testScenario === 'hidden-yiji' || testScenario === 'hidden-yiji-deputy' || testScenario === 'hidden-rehide-yiji' || testScenario === 'hidden-rehide-yiji-deputy' || testScenario === 'hidden-reveal' ||
  testScenario === 'hidden-jianxiong' || testScenario === 'hidden-jianxiong-deputy' || testScenario === 'hidden-fankui' || testScenario === 'hidden-fankui-deputy' || testScenario === 'hidden-reveal-deputy' || testScenario === 'hidden-active' || testScenario === 'hidden-active-main' || testScenario === 'delta-xiongsuan' || testScenario === 'delta-wenji' || testScenario === 'delta-lord-wenji' || testScenario === 'delta-qiance' || testScenario === 'delta-jianchu' || testScenario === 'delta-tieqi' || testScenario === 'delta-xishe' || testScenario === 'delta-chujue' || testScenario === 'delta-zhente' || testScenario === 'delta-halberd' || testScenario === 'delta-sijian' || testScenario === 'delta-bawei' || testScenario === 'delta-fengshi-siege' || testScenario === 'delta-fengshi-no-siege' || testScenario === 'ai-trace' || testScenario === 'chooser-trace' || testScenario === 'general-pair-trace' || testScenario === 'general-pair-match-a' || testScenario === 'general-pair-match-b' || testScenario === 'general-pair-match-c' || testScenario === 'general-pair-match-d' || testScenario === 'general-pair-match-mixed-a' || testScenario === 'general-pair-match-mixed-b' || testScenario === 'general-pair-match-mixed-c' || testScenario === 'general-pair-match-mixed-d' || testScenario === 'hidden-fanjian' || testScenario === 'hidden-fanjian-deputy' ||
  testScenario === 'hidden-view-as' || testScenario === 'hidden-view-as-main' || testScenario === 'hidden-dual' ||
  testScenario === 'hidden-luoshen' || testScenario === 'hidden-luoshen-deputy' ||
  testScenario === 'hidden-tiandu' || testScenario === 'hidden-tiandu-deputy' ||
  testScenario === 'hidden-jizhi' || testScenario === 'hidden-jizhi-deputy' ||
  testScenario === 'hidden-mingshi' || testScenario === 'hidden-mingshi-deputy' ||
  testScenario === 'hidden-gongqing' || testScenario === 'hidden-gongqing-deputy' ||
  testScenario === 'hidden-enyuan' || testScenario === 'hidden-enyuan-deputy' ||
  testScenario === 'hidden-fuyin' || testScenario === 'hidden-fuyin-deputy' ||
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
  testScenario === 'hidden-jueqing' || testScenario === 'hidden-jueqing-deputy' ||
  testScenario === 'hidden-ejue' || testScenario === 'hidden-ejue-deputy' ||
  testScenario === 'hidden-dufu' || testScenario === 'hidden-dufu-deputy' ||
  testScenario === 'hidden-jianzhi' || testScenario === 'hidden-jianzhi-deputy' || testScenario === 'hidden-zhiman' || testScenario === 'hidden-zhiman-deputy' || testScenario === 'hidden-jilix' || testScenario === 'hidden-jilix-deputy',
  'TQS_LIVE_SCENARIO must be empty, draw-sequence, card-chosen, cards-and-choice, poxi, rescue-normal, rescue-battle, founding, fazheng-enyuan, hidden-yiji, hidden-yiji-deputy, hidden-rehide-yiji, hidden-rehide-yiji-deputy, hidden-jianxiong, hidden-jianxiong-deputy, hidden-fankui, hidden-fankui-deputy, hidden-reveal, hidden-reveal-deputy, hidden-active, hidden-active-main, delta-xiongsuan, delta-wenji, delta-lord-wenji, delta-qiance, delta-jianchu, delta-tieqi, delta-xishe, delta-chujue, delta-zhente, delta-halberd, delta-sijian, delta-bawei, delta-fengshi-siege, delta-fengshi-no-siege, ai-trace, chooser-trace, general-pair-trace, general-pair-match-a, general-pair-match-b, general-pair-match-c, general-pair-match-d, general-pair-match-mixed-a, general-pair-match-mixed-b, general-pair-match-mixed-c, general-pair-match-mixed-d, hidden-fanjian, hidden-fanjian-deputy, hidden-view-as, hidden-view-as-main, hidden-dual, hidden-luoshen, hidden-luoshen-deputy, hidden-tiandu, hidden-tiandu-deputy, hidden-jizhi, hidden-jizhi-deputy, hidden-mingshi, hidden-mingshi-deputy, hidden-gongqing, hidden-gongqing-deputy, hidden-enyuan, hidden-enyuan-deputy, hidden-fuyin, hidden-fuyin-deputy, hidden-qianxun, hidden-qianxun-deputy, hidden-qianxun-indulgence, hidden-qianxun-indulgence-deputy, hidden-kongcheng, hidden-kongcheng-deputy, hidden-weimu, hidden-weimu-deputy, hidden-weimu-indulgence, hidden-weimu-indulgence-deputy, hidden-xiaoji, hidden-xiaoji-deputy, hidden-guanxing, hidden-guanxing-deputy, hidden-yingzi, hidden-yingzi-deputy, hidden-tianxiang, hidden-tianxiang-deputy, hidden-duanchang, hidden-duanchang-deputy, hidden-liegong, hidden-liegong-deputy, hidden-kuanggu, hidden-kuanggu-deputy, hidden-jueqing, hidden-jueqing-deputy, hidden-ejue, hidden-ejue-deputy, hidden-dufu, hidden-dufu-deputy, hidden-jianzhi, hidden-jianzhi-deputy, hidden-zhiman, hidden-zhiman-deputy, hidden-jilix, hidden-jilix-deputy');
// These scenarios deliberately require an explicit opt-in. An interrupted
// active room exercises reconnect/cleanup and therefore must run only against
// the isolated QA runtime, whose installer sets tempBanTime=0. Local fixtures
// remain enabled independently.
const experimentalScenariosEnabled = process.env.TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS === '1';
assert.ok(!testScenario || experimentalScenariosEnabled,
  'Experimental live scenarios are temporarily locked; set TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1 only after broad deployment');
const nativeQa = process.env.TQS_LIVE_NATIVE_QA === '1';
assert.ok(!nativeQa || !!testScenario, 'TQS_LIVE_NATIVE_QA=1 requires TQS_LIVE_SCENARIO');
const cardWireRollbackDrainRequested = process.env.TQS_LIVE_CARD_WIRE_ROLLBACK_DRAIN === '1';
assert.ok(!cardWireRollbackDrainRequested ||
  (nativeQa && testScenario === 'draw-sequence' && process.argv.includes('--reconnect') &&
    !process.argv.includes('--restart-gateway') && process.env.TQS_LIVE_CARD_WIRE_PRIVACY === '1'),
  'TQS_LIVE_CARD_WIRE_ROLLBACK_DRAIN=1 requires isolated v1 draw-sequence privacy QA with controlled reconnect');
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
assert.ok(testScenario !== 'delta-xiongsuan' || (nativeQa && process.argv.includes('--manual')),
  'delta-xiongsuan requires native QA and --manual to control the card/target active-skill path');
assert.ok(testScenario !== 'delta-wenji' || (nativeQa && process.argv.includes('--manual')),
  'delta-wenji requires native QA and --manual to control the choose-player/card and Slash paths');
assert.ok(testScenario !== 'delta-lord-wenji' || (nativeQa && process.argv.includes('--manual')),
  'delta-lord-wenji requires native QA and --manual for both handoffs and the transferred Slash');
assert.ok(testScenario !== 'delta-qiance' || (nativeQa && process.argv.includes('--manual')),
  'delta-qiance requires native QA and --manual to control the Duel and 谦策 invoke paths');
assert.ok(testScenario !== 'delta-jianchu' || (nativeQa && process.argv.includes('--manual')),
  'delta-jianchu requires native QA and --manual to control the equipment selection and 鞬出 invoke paths');
assert.ok(testScenario !== 'delta-tieqi' || (nativeQa && process.argv.includes('--manual')),
  'delta-tieqi requires native QA and --manual to control general choice, discard cancel and Slash paths');
assert.ok(testScenario !== 'delta-chujue' || (nativeQa && process.argv.includes('--manual')),
  'delta-chujue requires native QA and --manual to control both dead-kingdom and control-kingdom Slash paths');
assert.ok(testScenario !== 'delta-zhente' || (nativeQa && process.argv.includes('--manual')),
  'delta-zhente requires native QA and --manual to control the target invoke, negate choice and black Slash path');
assert.ok(testScenario !== 'delta-halberd' || (nativeQa && process.argv.includes('--manual')),
  'delta-halberd requires native QA and --manual to control the attached weapon and extra-target path');
assert.ok(testScenario !== 'delta-sijian' || (nativeQa && process.argv.includes('--manual')),
  'delta-sijian requires native QA and --manual to control the empty-hand trigger and target-card path');
assert.ok(testScenario !== 'delta-bawei' || (nativeQa && process.argv.includes('--manual')),
  'delta-bawei requires native QA and --manual for both damaged-target and untouched-control Slash paths');
assert.ok(!['delta-fengshi-siege', 'delta-fengshi-no-siege'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'delta-fengshi requires native QA and --manual for its first physical Slash and native bot Jink observation');
assert.ok(testScenario !== 'delta-xishe' || (nativeQa && process.argv.includes('--manual')),
  'delta-xishe requires native QA and --manual for both equipment discards and optional cancel');
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
assert.ok(!['hidden-enyuan', 'hidden-enyuan-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-enyuan scenarios require native QA and --manual to control the prelight and Peach target path');
assert.ok(!['hidden-fuyin', 'hidden-fuyin-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-fuyin scenarios require native QA and --manual to control the prelight and Slash target path');
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
assert.ok(!['hidden-ejue', 'hidden-ejue-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-ejue scenarios require native QA and --manual to control the prelight and DamageCaused path');
assert.ok(!['hidden-dufu', 'hidden-dufu-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-dufu scenarios require native QA and --manual to control the prelight and DamageCaused path');
assert.ok(!['hidden-jianzhi', 'hidden-jianzhi-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-jianzhi scenarios require native QA and --manual to control the prelight and lethal DamageCaused path');
assert.ok(!['hidden-zhiman', 'hidden-zhiman-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-zhiman scenarios require native QA and --manual to control the prelight and DamageCaused obtain path');
assert.ok(!['hidden-jilix', 'hidden-jilix-deputy'].includes(testScenario) || (nativeQa && process.argv.includes('--manual')),
  'hidden-jilix scenarios require native QA and --manual to control the prelight and repeated red Slash path');
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
const luaExecutable = process.env.TQS_LUA_BIN ?? 'lua5.4';
assert.match(path.basename(luaExecutable), /^lua5\.4$/u,
  'TQS_LUA_BIN must point to a Lua 5.4 executable named lua5.4');
if (process.env.TQS_LIVE_CARD_WIRE_PRIVACY === '1') {
  const luaPreflight = spawnSync(luaExecutable, ['-e', 'assert(_VERSION == "Lua 5.4")'], {
    stdio: 'ignore',
    timeout: 5_000,
  });
  assert.equal(luaPreflight.status, 0,
    'TQS_LUA_BIN must resolve to an executable Lua 5.4 runtime; pass an explicit lua5.4 path when PATH has no lua5.4');
}
const nativeQaTicketSecret = process.env.TQS_LIVE_TICKET_SECRET ?? '';
const nativeQaTicketHelper = process.env.TQS_LIVE_TICKET_HELPER ?? '';
assert.ok(!nativeQa || nativeQaTicketSecret.length >= 32 || nativeQaTicketHelper,
  'TQS_LIVE_NATIVE_QA=1 requires TQS_LIVE_TICKET_SECRET or TQS_LIVE_TICKET_HELPER');
const nativeQaTicketHelperPath = nativeQaTicketHelper ? path.resolve(nativeQaTicketHelper) : null;
if (nativeQaTicketHelperPath) {
  assert.ok(existsSync(nativeQaTicketHelperPath), `QA ticket helper is missing: ${nativeQaTicketHelperPath}`);
}
function nativeQaTicket(nativeName: string): string {
  if (!nativeQa) return '';
  const expiresAt = Math.floor(Date.now() / 1000) + 600;
  if (nativeQaTicketSecret.length >= 32) return createTqs1Ticket(nativeName, expiresAt, nativeQaTicketSecret);
  assert.ok(nativeQaTicketHelperPath, 'QA ticket helper is not configured');
  let ticket: string;
  try {
    ticket = execFileSync(process.execPath, [nativeQaTicketHelperPath, nativeName, String(expiresAt)], {
      encoding: 'utf8',
      timeout: 20_000,
      maxBuffer: 1024,
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
  } catch {
    throw new Error('QA ticket helper could not mint a ticket');
  }
  assertTqs1Ticket(ticket, expiresAt);
  return ticket;
}
const host=process.env.TQS_LIVE_HOST; assert.ok(host && /^[a-zA-Z0-9.:-]+$/.test(host),'TQS_LIVE_HOST required');
const runtime=process.env.TQS_LIVE_ROOT; assert.ok(runtime && existsSync(path.join(runtime,'flist.txt')));
const nativeProcessMetricsFile = process.env.TQS_LIVE_NATIVE_PROCESS_METRICS_FILE;
function readNativeProcessMetrics(): unknown {
  if (!nativeProcessMetricsFile || !existsSync(nativeProcessMetricsFile)) return null;
  try {
    return JSON.parse(readFileSync(nativeProcessMetricsFile, 'utf8')) as unknown;
  } catch {
    return null;
  }
}
const nativeMappingMetricsFile = process.env.TQS_LIVE_NATIVE_MAPPING_METRICS_FILE;
const nativeEntropyFailureFile = process.env.TQS_LIVE_NATIVE_ENTROPY_FAILURE_FILE;
type NativeEntropyFailure = { schemaVersion: 1; event: 'entropy_rejected'; mode: 'controlled'; kind: 'open' | 'short-read' | 'close' };
function readNativeEntropyFailure(): NativeEntropyFailure | null {
  if (!nativeEntropyFailureFile || !existsSync(nativeEntropyFailureFile)) return null;
  try {
    const value = JSON.parse(readFileSync(nativeEntropyFailureFile, 'utf8')) as Record<string, unknown>;
    if (value.schemaVersion !== 1 || value.event !== 'entropy_rejected' || value.mode !== 'controlled' ||
      !['open', 'short-read', 'close'].includes(value.kind as string)) return null;
    return { schemaVersion: 1, event: 'entropy_rejected', mode: 'controlled', kind: value.kind as NativeEntropyFailure['kind'] };
  } catch {
    return null;
  }
}
type NativeMappingSummary = {
  rowCount: number; protocolCreated: number; batchAborts: number; batchCommits: number;
  choiceRejects: number;
  lastAbortActiveReferences: number | null; lastAbortActiveRequests: number | null;
};
function readNativeMappingSummary(): NativeMappingSummary {
  const summary: NativeMappingSummary = {
    rowCount: 0, protocolCreated: 0, batchAborts: 0, batchCommits: 0,
    choiceRejects: 0,
    lastAbortActiveReferences: null, lastAbortActiveRequests: null,
  };
  if (!nativeMappingMetricsFile || !existsSync(nativeMappingMetricsFile)) return summary;
  let lines: string[];
  try { lines = readFileSync(nativeMappingMetricsFile, 'utf8').split('\n').slice(-4096); } catch { return summary; }
  for (const line of lines) {
    if (!line) continue;
    try {
      // The QA package emits the allowlisted row through native qInfo.  Some
      // launchers persist one JSON object per line, while the interactive
      // freekill-asio CLI persists the same row inside a decorated log line.
      // Accept both forms, but parse only the marker's bounded JSON object.
      const encoded = line.match(/\[TQS_QA_CARD_WIRE_MAPPING\]\s+(\{[^\r\n]*\})/u)?.[1] ?? line;
      const row = JSON.parse(encoded) as Record<string, unknown>;
      const event = row.event;
      const activeReferences = row.activeReferences;
      const activeRequests = row.activeRequests;
      if (row.schemaVersion !== 1 || !['protocol_created', 'batch_abort', 'batch_commit', 'choice_reject', 'disconnect'].includes(event as string) ||
        !Number.isSafeInteger(activeReferences) || (activeReferences as number) < 0 ||
        !Number.isSafeInteger(activeRequests) || (activeRequests as number) < 0) continue;
      summary.rowCount++;
      if (event === 'protocol_created') summary.protocolCreated++;
      if (event === 'batch_abort') {
        summary.batchAborts++;
        summary.lastAbortActiveReferences = activeReferences as number;
        summary.lastAbortActiveRequests = activeRequests as number;
      }
      if (event === 'batch_commit') summary.batchCommits++;
      if (event === 'choice_reject') summary.choiceRejects++;
    } catch { /* launch.py already filters the file; ignore a partial final line */ }
  }
  return summary;
}
function readNativeMappingDisconnectCount(): number {
  if (!nativeMappingMetricsFile || !existsSync(nativeMappingMetricsFile)) return 0;
  let lines: string[];
  try { lines = readFileSync(nativeMappingMetricsFile, 'utf8').split('\n').slice(-4096); } catch { return 0; }
  let count = 0;
  for (const line of lines) {
    if (!line) continue;
    try {
      const encoded = line.match(/\[TQS_QA_CARD_WIRE_MAPPING\]\s+(\{[^\r\n]*\})/u)?.[1] ?? line;
      const row = JSON.parse(encoded) as Record<string, unknown>;
      if (row.schemaVersion === 1 && row.event === 'disconnect' &&
          Number.isSafeInteger(row.activeReferences) && (row.activeReferences as number) >= 0 &&
          Number.isSafeInteger(row.activeRequests) && (row.activeRequests as number) >= 0) count++;
    } catch { /* launch.py may leave a partial final line while flushing */ }
  }
  return count;
}
type NativeCardWireRollbackSummary = {
  schemaVersion: 1; drainApplied: number; activeRoomProtocolV1: number;
  newRoomAdmissionLegacy: number; reconnectProtocolV1: number;
};
function readNativeCardWireRollbackSummary(): NativeCardWireRollbackSummary {
  const summary: NativeCardWireRollbackSummary = {
    schemaVersion: 1, drainApplied: 0, activeRoomProtocolV1: 0,
    newRoomAdmissionLegacy: 0, reconnectProtocolV1: 0,
  };
  if (!nativeMappingMetricsFile || !existsSync(nativeMappingMetricsFile)) return summary;
  let lines: string[];
  try { lines = readFileSync(nativeMappingMetricsFile, 'utf8').split('\n').slice(-4096); } catch { return summary; }
  for (const line of lines) {
    const encoded = line.match(/\[TQS_QA_CARD_WIRE_ROLLBACK\]\s+(\{[^\r\n]*\})/u)?.[1];
    if (!encoded) continue;
    try {
      const row = JSON.parse(encoded) as Record<string, unknown>;
      if (row.schemaVersion !== 1 || row.event !== 'drain_applied' ||
          row.activeRoomProtocol !== 1 || row.newRoomAdmission !== 'legacy' ||
          row.reconnectProtocol !== 1) continue;
      summary.drainApplied++;
      summary.activeRoomProtocolV1++;
      summary.newRoomAdmissionLegacy++;
      summary.reconnectProtocolV1++;
    } catch { /* the launcher may expose a partial final qInfo line */ }
  }
  return summary;
}
const cardWireRollbackMarkerBaseline = readNativeCardWireRollbackSummary().drainApplied;
const first={username:process.env.FK_TEST_USERNAME!,password:process.env.FK_TEST_PASSWORD!};assert.ok(first.username && first.password);
const secondFile=process.env.TQS_LIVE_SECOND_ACCOUNT_FILE ?? path.join(os.homedir(),'.codex/secrets/tqs-multiplayer-second.json');
if(!existsSync(secondFile)) writeFileSync(secondFile,JSON.stringify({username:`tqsqa${randomBytes(6).toString('hex')}`,
  password:randomBytes(24).toString('hex')}),{mode:0o600,flag:'wx'});
assert.equal(statSync(secondFile).mode & 0o077,0);
const second=JSON.parse(readFileSync(secondFile,'utf8')) as typeof first;
assert.notEqual(first.username,second.username);
const observeNativePrivacy = process.env.TQS_LIVE_CARD_WIRE_OBSERVER === '1';
const cardWireObserverMode = process.env.TQS_LIVE_CARD_WIRE_OBSERVER_MODE ?? 'valid';
assert.ok(['valid', 'missing', 'wrong-version', 'wrong-protocol', 'wrong-mode'].includes(cardWireObserverMode),
  'TQS_LIVE_CARD_WIRE_OBSERVER_MODE must be valid, missing, wrong-version, wrong-protocol or wrong-mode');
const observerLeaveRequested = process.env.TQS_LIVE_CARD_WIRE_OBSERVER_LEAVE === '1';
assert.ok(!observerLeaveRequested ||
  (nativeQa && observeNativePrivacy && cardWireObserverMode === 'valid' && testScenario === 'draw-sequence'),
  'TQS_LIVE_CARD_WIRE_OBSERVER_LEAVE=1 requires valid isolated native draw-sequence observer QA');
const cardWireReplayRequested = process.env.TQS_LIVE_CARD_WIRE_REPLAY === '1';
assert.ok(!cardWireReplayRequested ||
  (nativeQa && testScenario === 'draw-sequence' && !observeNativePrivacy &&
    !observerLeaveRequested && process.env.TQS_LIVE_LEGACY_ONLY !== '1' &&
    process.env.TQS_LIVE_CARD_WIRE_PRIVACY === '1' && nativeMappingMetricsFile),
  'TQS_LIVE_CARD_WIRE_REPLAY=1 requires isolated v1 draw-sequence privacy QA with mapping telemetry and no observer/reconnect lane');
const observerFile = process.env.TQS_LIVE_OBSERVER_ACCOUNT_FILE;
const cardWireObserverNegative = cardWireObserverMode !== 'valid';
const cardWirePlayerMode = process.env.TQS_LIVE_CARD_WIRE_PLAYER_MODE ?? 'valid';
assert.ok(['valid', 'missing'].includes(cardWirePlayerMode),
  'TQS_LIVE_CARD_WIRE_PLAYER_MODE must be valid or missing');
const cardWirePlayerIndex = Number(process.env.TQS_LIVE_CARD_WIRE_PLAYER_INDEX ?? '0');
assert.ok(Number.isSafeInteger(cardWirePlayerIndex) && cardWirePlayerIndex >= 0 && cardWirePlayerIndex < 2,
  'TQS_LIVE_CARD_WIRE_PLAYER_INDEX must select one of the two real players');
const cardWirePlayerNegative = cardWirePlayerMode !== 'valid';
const cardWireEntropyFailure = process.env.TQS_LIVE_CARD_WIRE_ENTROPY_FAILURE === '1';
assert.ok(!cardWireEntropyFailure || (nativeQa && testScenario === 'draw-sequence' &&
  !cardWireObserverNegative && !cardWirePlayerNegative && !observeNativePrivacy && nativeEntropyFailureFile),
  'Native card-wire entropy failure requires the isolated two-player draw-sequence QA path');
assert.ok(!cardWirePlayerNegative || nativeQa,
  'Native card-wire player mismatch requires native QA');
assert.ok(!(cardWirePlayerNegative && cardWireObserverNegative),
  'Player and observer card-wire mismatch probes must run separately');
assert.ok(!cardWireObserverNegative || (nativeQa && observeNativePrivacy && observerFile),
  'Native card-wire observer mismatch requires native QA, a third account and observer mode');
assert.ok(!observeNativePrivacy || (nativeQa && observerFile &&
  (process.env.TQS_LIVE_CARD_WIRE_PRIVACY === '1' || cardWireObserverNegative)),
  'Observer privacy requires native QA, a private third-account file and either audited v1 or an explicit negative mode');
if (observeNativePrivacy) assert.equal(statSync(observerFile!).mode & 0o077, 0);
const observerAccount = observeNativePrivacy
  ? JSON.parse(readFileSync(observerFile!, 'utf8')) as typeof first : null;
if (observerAccount) {
  assert.ok(observerAccount.username && observerAccount.password);
  assert.ok(![first.username, second.username].includes(observerAccount.username));
}
const frozenDist = mkdtempSync(path.join(os.tmpdir(),'tqs-frozen-multiplayer-'));
cpSync(path.join(web,'dist'),frozenDist,{recursive:true});
const distIndexSha256 = createHash('sha256').update(readFileSync(path.join(frozenDist,'index.html'))).digest('hex');
const chrome=process.env.TQS_CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
async function freePort(){const s=net.createServer();s.listen(0,'127.0.0.1');await once(s,'listening');const p=(s.address() as net.AddressInfo).port;await new Promise<void>(r=>s.close(()=>r()));return p;}
const [gatewayPort,peerGatewayPort,webPort]=await Promise.all([freePort(),freePort(),freePort()]);
const deploymentUrl = process.env.TQS_LIVE_URL;
// An isolated native QA port may be reachable only through an SSH tunnel.
// In that mode point the browser proxy at a gateway already running beside
// the matching remote runtime instead of silently bundling a different local
// flist and receiving a native md5-mismatch disconnect.
const gatewayTarget = process.env.TQS_LIVE_GATEWAY_TARGET?.replace(/\/$/,'') ?? null;
const auditNativeDeck = process.env.TQS_LIVE_CARD_WIRE_PRIVACY === '1' && !cardWireObserverNegative;
const capturePacketBytes = process.env.TQS_LIVE_CARD_WIRE_PACKET_SIZE === '1';
const captureNativePackets = auditNativeDeck || capturePacketBytes;
const nativeSemanticRequested = process.env.TQS_LIVE_CARD_WIRE_NATIVE_SEMANTIC === '1';
const nativeSemanticMetricsFile = process.env.TQS_LIVE_NATIVE_SEMANTIC_METRICS_FILE;
assert.ok(!nativeSemanticRequested || (nativeQa && !deploymentUrl && !gatewayTarget &&
  nativeSemanticMetricsFile),
  'Native semantic CBOR proof requires an isolated local QA runtime and an explicit metrics file');
// Only the live isolated QA auditor receives this salt. It never enters the
// evidence object, log, browser, or production runtime.
const privacyAuditSalt = auditNativeDeck ? randomBytes(32).toString('hex') : null;
assert.ok(!auditNativeDeck || (nativeQa && !deploymentUrl && !gatewayTarget),
  'Native privacy audit requires an isolated local QA runtime');
assert.ok(!capturePacketBytes || (nativeQa && !deploymentUrl && !gatewayTarget),
  'Native packet-size capture requires an isolated local QA runtime');
const requireAllNativePrivacy = process.env.TQS_LIVE_CARD_WIRE_REQUIRE_ALL === '1';
assert.ok(!requireAllNativePrivacy || (auditNativeDeck && observeNativePrivacy),
  'Full native privacy requires raw CBOR audit and a separate observer');
// A local QA runtime must enforce the same signed-ticket contract used by the
// test-only browser session. A legacy native binary accepts its configuration
// but ignores tqsAuthRequired, then rejects the TQS1 ticket as a password.
// Fail before starting a gateway/browser or recording misleading game evidence.
if (nativeQa && !deploymentUrl && !gatewayTarget) {
  const nativeBinaryPath = path.join(runtime, 'freekill-asio');
  assert.ok(existsSync(nativeBinaryPath), 'Native QA runtime has no freekill-asio executable');
  const nativeBinary = readFileSync(nativeBinaryPath);
  assert.ok(['tqsAuthRequired', 'TQS1', 'game account is not approved'].every((marker) =>
    nativeBinary.includes(Buffer.from(marker))),
  'Native QA binary lacks the signed-ticket patch; rebuild freekill-asio with tqs-game-access.patch before TQS1 replay');
}
const testGatewayRestart = process.argv.includes('--restart-gateway');
assert.ok(!testGatewayRestart || !deploymentUrl,'Gateway restart test requires an isolated local gateway; never restart shared hosting');
if (deploymentUrl) assert.equal(new URL(deploymentUrl).protocol,'https:');
const base=deploymentUrl?.replace(/\/$/,'') ?? `http://127.0.0.1:${webPort}`;
const qaPackageIdentity = nativeQa ? verifyQaPackageManifest({
  manifestPath: process.env.TQS_QA_PACKAGE_MANIFEST ?? path.join(runtime, 'qa_packages/tqs_qa/package.manifest.json'),
  expectedRevision: process.env.TQS_QA_EXPECTED_REVISION,
}) : null;
if (qaPackageIdentity) {
  const qaSourceRoot = process.env.TQS_QA_SOURCE_ROOT ?? path.join(repo, 'deploy/freekill-native/qa/tqs_qa');
  const qaCatalogPath = path.join(qaSourceRoot, 'catalog.json');
  assert.ok(existsSync(qaCatalogPath), `QA catalog source is missing: ${qaCatalogPath}`);
  const catalogHash = createHash('sha256')
    .update(readFileSync(qaCatalogPath)).digest('hex');
  assert.equal(qaPackageIdentity.catalogSha256, catalogHash,
    'Installed native QA catalog is stale; install and verify this source before running the scenario');
}
const qaSourceIdentity = nativeQa ? verifyQaSourceIdentity({
  runtime,
  expectedRuntimeMD5: process.env.TQS_QA_EXPECTED_RUNTIME_MD5 ?? '',
  expectedSmartAiSha256: process.env.TQS_QA_EXPECTED_SMART_AI_SHA256 ?? P1_QA_SOURCE_BASELINE.smartAiSha256,
  expectedRoomLuaSha256: process.env.TQS_QA_EXPECTED_ROOM_LUA_SHA256 ?? P1_QA_SOURCE_BASELINE.roomLuaSha256,
  expectedQaSmartAiOverlaySha256: process.env.TQS_QA_EXPECTED_QA_SMART_AI_OVERLAY_SHA256 ?? P1_QA_SOURCE_BASELINE.qaSmartAiOverlaySha256,
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
if (qaSourceIdentity) console.log(`PASS native QA source provenance: runtimeMD5=${qaSourceIdentity.runtimeMD5}, ` +
  `smartAI=${qaSourceIdentity.smartAiSha256}, room=${qaSourceIdentity.roomLuaSha256}, overlay=${qaSourceIdentity.qaSmartAiOverlaySha256}`);
const startGateway=(port=gatewayPort)=>spawn(process.execPath,[path.join(repo,'game/gateway/src/server.mjs')],{
  env:{...process.env,FK_TEST_USERNAME:undefined,FK_TEST_PASSWORD:undefined,FK_ROOT:runtime,FK_HOST:host,
    FK_PORT:process.env.TQS_LIVE_PORT ?? '9527',PORT:String(port),BIND_HOST:'127.0.0.1',ALLOW_ORIGIN:base,TRUSTED_PROXIES:''},stdio:'ignore'});
let gateway=deploymentUrl || gatewayTarget ? null : startGateway();
const peerGateway=testGatewayRestart ? startGateway(peerGatewayPort) : null;
let server:Awaited<ReturnType<typeof preview>>|undefined;
let browser:Awaited<ReturnType<typeof chromium.launch>>|undefined;
const traces:{direction:string;command:string;requestId:number;type:number}[][]=
  observeNativePrivacy ? [[],[],[]] : [[],[]];
// Opt-in candidate audit of raw native bytes, before browser Lua localization.
// No payload, raw exception, card ID or token is retained in the evidence.
const nativeDeckCommands = new Set(['PrepareDrawPile', 'ShuffleDrawPile', 'SyncDrawPile',
  'ChangeCardArea', 'Reconnect', 'Observe', 'MoveCards', 'SetPlayerPile']);
const nativeSupplementalCommands = new Set([
  'CardWireNegotiated', 'PropertyUpdate', 'SetPlayerMark', 'SetCardMark',
  'SetCardFootnote', 'SetCardVirtName', 'FilterCard', 'FillAG', 'TakeAG',
  'SetPlayerHandCards', 'AddVirtualEquip', 'RemoveVirtualEquip',
  'ShowVirtualCard', 'GameLog', 'ShowCard', 'GameOver',
  'AskForCardChosen', 'AskForPoxi', 'AskForAG', 'AskForCardsAndChoice',
  'AskForArrangeCards', 'AskForMoveCardInBoard', 'PlayCard',
  'AskForUseActiveSkill', 'AskForUseCard', 'AskForResponseCard',
  'AskForChoices', 'AskForOptions', 'AskForSkillInvoke', 'AskForGeneral', 'CustomDialog',
  'EmptyRequest',
]);
const nativeSemanticCommands = new Set([...nativeSupplementalCommands, ...nativeDeckCommands]);
const nativeRequestCommands = new Set([
  'AskForCardChosen', 'AskForPoxi', 'AskForAG', 'AskForCardsAndChoice',
  'AskForArrangeCards', 'AskForMoveCardInBoard', 'PlayCard',
  'AskForUseActiveSkill', 'AskForUseCard', 'AskForResponseCard',
  'AskForChoices', 'AskForOptions', 'AskForSkillInvoke', 'AskForGeneral', 'CustomDialog',
  'EmptyRequest',
]);
const nativeSemanticChannels = ['metadata', 'public', 'request', 'deck', 'negotiation', 'reply'] as const;
const nativeSemanticAudiences = ['owner', 'opponent', 'observer', 'unknown'] as const;
const nativeSemanticScopes = ['outbound', 'inbound-reply', 'inbound-notify', 'inbound-request'] as const;
type NativeSemanticSummary = {
  schemaVersion: 1;
  requested: boolean;
  records: number;
  semanticPassRecords: number;
  semanticFailures: number;
  outerDecodedRecords: number;
  innerDecodedRecords: number;
  inboundRecords: number;
  outboundRecords: number;
  opaqueReferences: number;
  numericReferences: number;
  invalidReferences: number;
  forbiddenFields: number;
  nestedDecoded: number;
  maxDepth: number;
  audiences: Record<(typeof nativeSemanticAudiences)[number], number>;
  channels: Record<(typeof nativeSemanticChannels)[number], number>;
  scopes: Record<(typeof nativeSemanticScopes)[number], number>;
};
function readNativeSemanticSummary(): NativeSemanticSummary {
  const summary: NativeSemanticSummary = {
    schemaVersion: 1, requested: nativeSemanticRequested, records: 0,
    semanticPassRecords: 0, semanticFailures: 0, outerDecodedRecords: 0,
    innerDecodedRecords: 0, inboundRecords: 0, outboundRecords: 0,
    opaqueReferences: 0, numericReferences: 0, invalidReferences: 0,
    forbiddenFields: 0, nestedDecoded: 0, maxDepth: 0,
    audiences: Object.fromEntries(nativeSemanticAudiences.map((key) => [key, 0])) as NativeSemanticSummary['audiences'],
    channels: Object.fromEntries(nativeSemanticChannels.map((key) => [key, 0])) as NativeSemanticSummary['channels'],
    scopes: Object.fromEntries(nativeSemanticScopes.map((key) => [key, 0])) as NativeSemanticSummary['scopes'],
  };
  if (!nativeSemanticMetricsFile || !existsSync(nativeSemanticMetricsFile)) return summary;
  let lines: string[];
  try { lines = readFileSync(nativeSemanticMetricsFile, 'utf8').split('\n').slice(-8192); } catch { return summary; }
  const add = (value: unknown, maximum = 1_000_000): number =>
    typeof value === 'number' && Number.isSafeInteger(value) && value >= 0
      ? Math.min(value, maximum) : 0;
  for (const line of lines) {
    if (!line) continue;
    try {
      const row = JSON.parse(line) as Record<string, unknown>;
      const inboundReply = row.scope === 'inbound-reply' && row.command === 'Reply' && row.channel === 'reply';
      if (row.schemaVersion !== 1 || typeof row.command !== 'string' ||
          (!nativeSemanticCommands.has(row.command) && !inboundReply) ||
          typeof row.channel !== 'string' || !nativeSemanticChannels.includes(row.channel as typeof nativeSemanticChannels[number]) ||
          typeof row.scope !== 'string' || !nativeSemanticScopes.includes(row.scope as typeof nativeSemanticScopes[number]) ||
          typeof row.audience !== 'string' || !nativeSemanticAudiences.includes(row.audience as typeof nativeSemanticAudiences[number])) continue;
      summary.records++;
      if (row.semanticPass === true) summary.semanticPassRecords++;
      else summary.semanticFailures++;
      if (row.outerDecoded === true) summary.outerDecodedRecords++;
      if (row.innerDecoded === true) summary.innerDecodedRecords++;
      if (row.scope === 'outbound') summary.outboundRecords++;
      else summary.inboundRecords++;
      summary.opaqueReferences += add(row.opaqueReferences);
      summary.numericReferences += add(row.numericReferences);
      summary.invalidReferences += add(row.invalidReferences);
      summary.forbiddenFields += add(row.forbiddenFields);
      summary.nestedDecoded += add(row.nestedDecoded);
      summary.maxDepth = Math.max(summary.maxDepth, add(row.maxDepth, 64));
      summary.audiences[row.audience as typeof nativeSemanticAudiences[number]]++;
      summary.channels[row.channel as typeof nativeSemanticChannels[number]]++;
      summary.scopes[row.scope as typeof nativeSemanticScopes[number]]++;
    } catch { /* ignore a partial final line or an untrusted malformed row */ }
  }
  return summary;
}
const nativeDeckPrivacy = traces.map(() => ({
  negotiated: false, failures: 0,
  projectorSha256: auditNativeDeck ? createHash('sha256').update(readFileSync(
    path.join(runtime, 'packages/freekill-core/lua/server/card_wire_projection.lua'))).digest('hex') : null,
  commands: Object.fromEntries([...nativeDeckCommands].map((command) => [command, 0])),
  categoryCounts: Object.fromEntries(PRIVACY_CATEGORIES.map((category) => [category, 0])),
}));
const nativeWireCapture = traces.map(() => ({
  beforePacketDecode: true,
  frames: 0,
  packets: 0,
  failures: 0,
  packetBytes: { total: 0, min: 0, max: 0, le256: 0, le1024: 0, le4096: 0, gt4096: 0 },
  commands: Object.fromEntries([...nativeDeckCommands].map((command) => [command, 0])),
  categoryCounts: Object.fromEntries(PRIVACY_CATEGORIES.map((category) => [category, 0])),
  hiddenReferenceAudited: auditNativeDeck,
  hiddenReferenceCollisions: 0,
}));
const hiddenReferenceFingerprints = traces.map(() => new Set<string>());
const nativeSupplementalCapture = traces.map(() => ({
  beforePacketDecode: true,
  frames: 0,
  packets: 0,
  incomingPackets: 0,
  replyPackets: 0,
  failures: 0,
  packetBytes: { total: 0, min: 0, max: 0, le256: 0, le1024: 0, le4096: 0, gt4096: 0 },
  commands: Object.fromEntries([...nativeSupplementalCommands].map((command) => [command, 0])),
  replies: Object.fromEntries([...nativeRequestCommands].map((command) => [command, 0])),
  channels: Object.fromEntries(SUPPLEMENTAL_CHANNELS.map((channel) => [channel, 0])),
}));
// This lane intentionally captures only bounded packet counters and size
// buckets. Raw outer-CBOR bytes are parsed in memory and discarded before any
// evidence object is built, so it can compare legacy and v1 without exporting
// physical card identities, opaque references, or request payloads.
const nativePacketSizeCapture = traces.map(() => ({
  beforePacketDecode: true,
  frames: 0,
  packets: 0,
  incomingPackets: 0,
  outgoingPackets: 0,
  failures: 0,
  packetBytes: { total: 0, min: 0, max: 0, le256: 0, le1024: 0, le4096: 0, gt4096: 0 },
}));
const errors:string[]=[];let gameStarted=false;let finished=false;
let cardWireObserverRejected = false;
let cardWireObserverObservePackets = 0;
let cardWireObserverLeaveObserved = false;
let cardWireObserverLeaveNativeDisconnect = false;
let cardWireObserverEvidenceWritten = false;
let cardWireReplayInjected = false;
let cardWireReplaySent = false;
let cardWireReplayRejectObserved = false;
let cardWireReplayRejectsBefore = 0;
let cardWireReplayRejectsAfter = 0;
type CardWireReplayRouteState = {
  page: Page;
  server: WebSocketRoute | null;
  lastReply: Buffer | null;
  pendingReplay: Buffer | null;
  replaySent: boolean;
  replayRequestIdRewritten: boolean;
  sendCalls: number;
  binaryFrames: number;
  replyCandidates: number;
};
const cardWireReplayRoutes: CardWireReplayRouteState[] = [];
let cardWirePlayerRejected = false;
let cardWirePlayerCapabilityDrops = 0;
let cardWirePlayerErrorPackets = 0;
let cardWirePlayerEvidenceWritten = false;
let cardWireEntropyFailureObserved = false;
let cardWireEntropyFailureKind: NativeEntropyFailure['kind'] | null = null;
let cardWireEntropyNegotiatedPackets = 0;
let cardWireEntropyCardBearingPackets = 0;
let cardWireEntropyBatchAborts = 0;
let cardWireEntropyBatchCommits = 0;
let cardWireEntropyLastAbortActiveReferences: number | null = null;
let cardWireEntropyLastAbortActiveRequests: number | null = null;
let cardWireEntropyEvidenceWritten = false;
const writeCardWireObserverEvidence = () => {
  if (!cardWireObserverNegative || cardWireObserverEvidenceWritten) return;
  const evidenceDir = path.join(repo, 'scratch/evidence');
  mkdirSync(evidenceDir, { recursive: true });
  writeFileSync(path.join(evidenceDir,
    `${candidateId}-card-wire-observer-${cardWireObserverMode}-live-${Date.now()}.json`),
  JSON.stringify(sanitizeQaEvidence({
    at: new Date().toISOString(), candidateId, scenario: testScenario || null,
    cardWireObserverMode, cardWireObserverRejected, cardWireObserverObservePackets,
    result: 'PASS', scope: 'native C++ observer mismatch; no Observe snapshot or private card payload',
  }), null, 2));
  cardWireObserverEvidenceWritten = true;
};
const writeCardWirePlayerEvidence = () => {
  if (!cardWirePlayerNegative || cardWirePlayerEvidenceWritten) return;
  const evidenceDir = path.join(repo, 'scratch/evidence');
  mkdirSync(evidenceDir, { recursive: true });
  writeFileSync(path.join(evidenceDir,
    `${candidateId}-card-wire-player-${cardWirePlayerMode}-live-${Date.now()}.json`),
  JSON.stringify(sanitizeQaEvidence({
    at: new Date().toISOString(), candidateId, scenario: testScenario || null,
    cardWirePlayerMode, cardWirePlayerIndex, cardWirePlayerRejected,
    cardWirePlayerCapabilityDrops,
    cardWirePlayerErrorPackets,
    cardWirePlayerNegotiatedPackets: traces.flat().filter((packet) =>
      packet.direction === 'incoming' && packet.command === 'CardWireNegotiated').length,
    result: 'PASS', scope: 'native C++ v1 room with one non-negotiating player; explicit legacy session; no mixed protocol',
  }), null, 2));
  cardWirePlayerEvidenceWritten = true;
};
const writeCardWireEntropyEvidence = () => {
  if (!cardWireEntropyFailure || cardWireEntropyEvidenceWritten) return;
  const evidenceDir = path.join(repo, 'scratch/evidence');
  mkdirSync(evidenceDir, { recursive: true });
  const evidencePath = path.join(evidenceDir,
    `${candidateId}-card-wire-entropy-failure-live-${Date.now()}.json`);
  writeFileSync(evidencePath, JSON.stringify(sanitizeQaEvidence({
    at: new Date().toISOString(), candidateId, scenario: testScenario,
    cardWireEntropyFailure: true, cardWireEntropyFailureObserved,
    cardWireEntropyFailureKind: cardWireEntropyFailureKind ?? null,
    cardWireEntropyNegotiatedPackets, cardWireEntropyCardBearingPackets,
    cardWireEntropyBatchAborts, cardWireEntropyBatchCommits,
    cardWireEntropyLastAbortActiveReferences,
    cardWireEntropyLastAbortActiveRequests,
    nativeProcessMetrics: readNativeProcessMetrics(), result: 'PASS',
  }), null, 2));
  cardWireEntropyEvidenceWritten = true;
  console.log(`PASS native card-wire entropy failure: kind=${cardWireEntropyFailureKind}, negotiatedPackets=${cardWireEntropyNegotiatedPackets}, cardBearingPackets=0, batchAborts=${cardWireEntropyBatchAborts}, batchCommits=${cardWireEntropyBatchCommits}`);
};
const testRecovery = process.argv.includes('--reconnect') || testGatewayRestart;
const testManual = process.argv.includes('--manual');
const testBotAudit = process.argv.includes('--audit-bots');
const aiTraceScenario = testScenario === 'ai-trace';
const chooserTraceScenario = testScenario === 'chooser-trace';
const generalPairTraceScenario = testScenario === 'general-pair-trace';
const generalPairMatchScenario = testScenario.startsWith('general-pair-match-');
const boundedAiTraceScenario = aiTraceScenario || chooserTraceScenario || generalPairTraceScenario;
assert.ok(!(boundedAiTraceScenario || generalPairMatchScenario) || (nativeQa && testBotAudit),
  'ai-trace/chooser-trace/general-pair-trace/general-pair-match require the isolated native QA package and --audit-bots');
class CardWirePlayerProbeComplete extends Error {
  constructor() {
    super('card-wire player mismatch probe completed');
    this.name = 'CardWirePlayerProbeComplete';
  }
}
class CardWireEntropyProbeComplete extends Error {
  constructor() {
    super('card-wire entropy failure probe completed');
    this.name = 'CardWireEntropyProbeComplete';
  }
}
async function waitForNativeEntropyFailure(timeoutMs: number): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (readNativeEntropyFailure()) return true;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  return readNativeEntropyFailure() !== null;
}
async function waitForNativeEntropyNegotiation(timeoutMs: number): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const negotiatedPackets = traces.flat().filter((packet) =>
      packet.direction === 'incoming' && packet.command === 'CardWireNegotiated').length;
    if (negotiatedPackets >= 2) return true;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  return traces.flat().filter((packet) =>
    packet.direction === 'incoming' && packet.command === 'CardWireNegotiated').length >= 2;
}
function completeCardWireEntropyProbe(): never {
  const failure = readNativeEntropyFailure();
  assert.ok(failure, 'native candidate did not emit the bounded CSPRNG rejection marker');
  const mapping = readNativeMappingSummary();
  const incoming = traces.flat().filter((packet) => packet.direction === 'incoming');
  const cardBearingCommands = new Set([
    'PrepareDrawPile', 'ShuffleDrawPile', 'SyncDrawPile', 'ChangeCardArea',
    'MoveCards', 'SetPlayerPile', 'SetPlayerHandCards', 'AddVirtualEquip',
    'RemoveVirtualEquip', 'ShowCard', 'ShowVirtualCard', 'GameLog',
    'AskForCardChosen', 'AskForPoxi', 'AskForAG', 'AskForCardsAndChoice',
    'AskForArrangeCards', 'AskForMoveCardInBoard', 'PlayCard', 'AskForUseCard',
    'AskForResponseCard', 'AskForUseActiveSkill',
  ]);
  cardWireEntropyFailureObserved = true;
  cardWireEntropyFailureKind = failure.kind;
  cardWireEntropyNegotiatedPackets = incoming.filter((packet) => packet.command === 'CardWireNegotiated').length;
  cardWireEntropyCardBearingPackets = incoming.filter((packet) => cardBearingCommands.has(packet.command)).length;
  cardWireEntropyBatchAborts = mapping.batchAborts;
  cardWireEntropyBatchCommits = mapping.batchCommits;
  cardWireEntropyLastAbortActiveReferences = mapping.lastAbortActiveReferences;
  cardWireEntropyLastAbortActiveRequests = mapping.lastAbortActiveRequests;
  assert.ok(cardWireEntropyNegotiatedPackets >= 2,
    'native entropy probe must fail after both real clients receive v1 negotiation');
  assert.equal(cardWireEntropyCardBearingPackets, 0,
    'CSPRNG failure must prevent every card-bearing packet from leaving the native room');
  assert.ok(cardWireEntropyBatchAborts > 0,
    'CSPRNG failure must abort the staged native card-wire batch');
  assert.equal(cardWireEntropyLastAbortActiveReferences, 0,
    'aborted native card-wire batch must publish no partial audience references');
  assert.equal(cardWireEntropyLastAbortActiveRequests, 0,
    'aborted native card-wire batch must publish no partial request state');
  gameStarted = false;
  finished = true;
  writeCardWireEntropyEvidence();
  throw new CardWireEntropyProbeComplete();
}
let manualCardReply = false;
const manualDeadlineMs = Number(process.env.TQS_LIVE_DEADLINE_MS ?? '180000');
assert.ok(Number.isSafeInteger(manualDeadlineMs) && manualDeadlineMs >= 30000 && manualDeadlineMs <= 900000,
  'TQS_LIVE_DEADLINE_MS must be a bounded integer between 30000 and 900000');
const candidateId = process.env.TQS_CANDIDATE_ID ?? 'cp08';
assert.match(candidateId,/^cp[0-9]{2}$/);
const winrateBranch = process.env.TQS_WINRATE_BRANCH ?? candidateId;
assert.match(winrateBranch, /^[A-Za-z0-9_-]{1,40}$/,
  'TQS_WINRATE_BRANCH may contain only short metadata-safe characters');
const winrateRunId = process.env.TQS_WINRATE_RUN_ID ?? null;
if (winrateRunId) assert.match(winrateRunId, /^[A-Za-z0-9_.-]{1,100}$/, 'TQS_WINRATE_RUN_ID is not metadata-safe');
const errorContexts: unknown[] = [];
let recovered = false;
let cardWireRollbackDrainObserved = false;
const pages:Page[]=[];
let observerPage: Page | undefined;
const currentSockets: unknown[] = [];
const transportOpen = [false,false];
async function performObserverLeaveProbe(): Promise<void> {
  if (!observerLeaveRequested) return;
  const observer = observerPage;
  if (!observer) throw new Error('observer leave probe has no live observer page');
  assert.ok(currentSockets[2], 'observer leave probe must have an active observer WebSocket');
  const observerLeaveDisconnectBaseline = readNativeMappingDisconnectCount();
  // Close the application WebSocket itself so the native transport boundary
  // is exercised. Context close remains a safety net because Chromium/macOS
  // does not always surface the close event to Playwright.
  await observer.evaluate(() =>
    (window as unknown as { __tqsTestDisconnect?: () => void }).__tqsTestDisconnect?.());
  await observer.context().close();
  const observerLeaveDeadline = Date.now() + 10000;
  while (transportOpen[2] !== false &&
      readNativeMappingDisconnectCount() <= observerLeaveDisconnectBaseline &&
      Date.now() < observerLeaveDeadline) {
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  cardWireObserverLeaveNativeDisconnect = readNativeMappingDisconnectCount() > observerLeaveDisconnectBaseline;
  assert.ok(transportOpen[2] === false || cardWireObserverLeaveNativeDisconnect,
    'observer leave probe must observe a native observer transport close or bounded mapping disconnect');
  cardWireObserverLeaveObserved = transportOpen[2] === false || cardWireObserverLeaveNativeDisconnect;
  observerPage = undefined;
  console.log(`PASS native observer leave: transportClosed=${transportOpen[2] === false}, ` +
    `nativeDisconnect=${cardWireObserverLeaveNativeDisconnect}; player room remained active`);
}
// The native QA director binds its actor to the first allowlisted user
// (`allowedUsers[1]` in Lua). The runner logs that account into page 0, so keep
// page 0 as the default until a later roster/prelight probe discovers a more
// specific owner. Without this, the actor can be delegated to Trust while the
// runner waits for a request that will never be emitted on the manually
// controlled page.
let scenarioClient = 0;
const progressTimer = setInterval(() => console.log(JSON.stringify({stage:finished?'finished':gameStarted?'playing':'login',recovered,
  packets:traces.map(t=>t.length),lastIncoming:traces.map(t=>t.filter(p=>p.direction==='incoming').at(-1)?.command ?? null),
  nativeQaGateSeen,errors:errors.length})),60000);
progressTimer.unref();
const scenarioConfig: Record<Exclude<LiveScenario, ''>, {
  general: RegExp; generalId: string; skill: RegExp | null; pack: RegExp; packId: string; requiredCommand: string;
  qaMode?: 'battle-royal-new' | 'battle-royal-old'; sameKingdom?: boolean; capacity?: 2 | 3 | 4; requiresGeneral?: boolean;
}> = {
  'draw-sequence': { general: /$^/, generalId: '', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', requiresGeneral: false },
  'card-chosen': { general: /Bàng Đức|庞德|Pang\s*De/i, generalId: 'hs__pangde', skill: /jianchu|鞬出|Kiền xuất|Kiên xuất|Lấy ra/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForCardChosen' },
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
  // The upstream P0 regression is a normal active-skill request. The QA
  // director pre-uses the target's limited skill so the source xiongsuan
  // choice must be reached and reset at TurnEnd.
  'delta-xiongsuan': { general: /李傕郭汜|Lý Giác|Lý Quách|xiongsuan|凶算/i, generalId: 'ld__lijueguosi', skill: /凶算|Hung\s*Toán|xiongsuan/i, pack: /^transformation$/i, packId: 'transformation', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Wenji's old Hegemony branch uses choose_players_skill and
  // choose_cards_skill before the transferred Slash reaches CardUsing.
  'delta-wenji': { general: /刘琦|Liu\s*Qi|问计|Vấn\s*Kế|wenji/i, generalId: 'nos_heg__liuqi', skill: /问计|Vấn\s*Kế|wenji|nos_heg__wenji/i, pack: /^hegemony_nos$/i, packId: 'hegemony_nos', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  'delta-lord-wenji': { general: /刘琦|Liu\s*Qi|问计|Vấn\s*Kế|wenji/i, generalId: 'ld__liuqi', skill: /问计|Vấn\s*Kế|wenji|ld__wenji/i, pack: /^lord_ex$/i, packId: 'lord_ex', requiredCommand: 'AskForUseActiveSkill', requiresGeneral: false },
  // Qiance is the upstream CardUsing trigger. Both fixed seats are Shu so
  // the target is a big-kingdom player in the two-seat fixture; the target's
  // Slash must remain in hand when the Duel response is suppressed.
  'delta-qiance': { general: /徐庶|Xu\s*Shu|谦策|Khiêm\s*Sách|qiance/i, generalId: 'ld__xushu', skill: /谦策|Khiêm\s*Sách|qiance|ld__qiance/i, pack: /^lord_ex$/i, packId: 'lord_ex', requiredCommand: 'AskForUseCard', requiresGeneral: false },
  // Jianchu's upstream delta is the equipment branch: the selected target
  // equipment is discarded and the target must not receive a response
  // request for the source Slash.  Native QA fixes the Pang De/Cao Cao
  // roster and card areas; the browser only drives the real requests.
  'delta-jianchu': { general: /庞德|Bàng Đức|Pang\s*De|鞬出|jianchu/i, generalId: 'hs__pangde', skill: /鞬出|Kiền\s*Xuất|jianchu/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'delta-tieqi': { general: /马超|Mã\s*Siêu|Ma\s*Chao|铁骑|tieqi/i, generalId: 'hs__machao', skill: /铁骑|Thiết\s*Kỵ|tieqi|hs__tieqi/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForSkillInvoke', capacity: 2, requiresGeneral: false },
  // Chujue compares a living target against a dead seat's kingdom. The
  // native QA catalog fixes four seats so the browser can drive both the
  // suppressed-response and ordinary-response branches.
  'delta-chujue': { general: /贾充|Giả\s*Sung|Jia\s*Chong|除绝|chujue/i, generalId: 'heg__jiachong', skill: /除绝|Trừ\s*Tuyệt|chujue|heg__chujue/i, pack: /^zqdl$/i, packId: 'zqdl', requiredCommand: 'AskForSkillInvoke', capacity: 4, requiresGeneral: false },
  'delta-zhente': { general: /陆玉生|Lục\s*Ngọc\s*Sinh|Luyusheng|贞特|zhente/i, generalId: 'ty_heg__luyusheng', skill: /贞特|Trinh\s*Đặc|zhente|ty_heg__zhente/i, pack: /^tenyear_heg$/i, packId: 'tenyear_heg', requiredCommand: 'AskForSkillInvoke', capacity: 2, requiresGeneral: false },
  'delta-halberd': { general: /马超|Mã\s*Siêu|Ma\s*Chao|方天画戟|halberd/i, generalId: 'hs__machao', skill: /方天画戟|Fang\s*Tian|halberd|sa__halberd/i, pack: /^strategic_advantage$/i, packId: 'strategic_advantage', requiredCommand: 'AskForUseActiveSkill', capacity: 3, requiresGeneral: false },
  'delta-sijian': { general: /田丰|Tian\s*Feng|死谏|sijian/i, generalId: 'hs__tianfeng', skill: /死谏|Tu\s*Gian|sijian/i, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', capacity: 2, requiresGeneral: false },
  'delta-bawei': { general: /孙策|Tôn\s*Sách|Sun\s*Ce|霸威|bawei/i, generalId: 'm_heg__lordsunce', skill: /霸威|bawei|m_heg__bawei/i, pack: /^mobile_heg$/i, packId: 'mobile_heg', requiredCommand: 'AskForSkillInvoke', capacity: 3, requiresGeneral: false },
  'delta-fengshi-siege': { general: /张任|Trương\s*Nhậm|Zhang\s*Ren|锋矢|fengshi/i, generalId: 'm_heg__zhangren', skill: /锋矢|fengshi|m_heg__fengshi/i, pack: /^mobile_heg$/i, packId: 'mobile_heg', requiredCommand: 'AskForSkillInvoke', capacity: 3, requiresGeneral: false },
  'delta-fengshi-no-siege': { general: /张任|Trương\s*Nhậm|Zhang\s*Ren|锋矢|fengshi/i, generalId: 'm_heg__zhangren', skill: /锋矢|fengshi|m_heg__fengshi/i, pack: /^mobile_heg$/i, packId: 'mobile_heg', requiredCommand: 'AskForSkillInvoke', capacity: 3, requiresGeneral: false },
  'delta-xishe': { general: /黄祖|Hoàng\s*Tổ|Huang\s*Zu|袭射|xishe/i, generalId: 'ld__huangzu', skill: /袭射|Tập\s*Xạ|xishe|ld__xishe/i, pack: /^lord_ex$/i, packId: 'lord_ex', requiredCommand: 'AskForSkillInvoke', capacity: 3, requiresGeneral: false },
  // ai-trace is a native-only four-seat run.  Its fixed seat roster lives in
  // the server QA catalog; this entry only keeps the browser/native command
  // contract in lockstep and prevents accidental use without the QA package.
  'chooser-trace': { general: /Lục Tốn|陆逊|Lu\s*Xun/i, generalId: 'hs__luxun', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'AskForUseActiveSkill', capacity: 4, requiresGeneral: false },
  'ai-trace': { general: /Lục Tốn|陆逊|Lu\s*Xun/i, generalId: 'hs__luxun', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'PlayCard', capacity: 4, requiresGeneral: false },
  // general-pair-trace fixes the offered groups in the server-only catalog;
  // the browser still completes the real CustomDialog for its two accounts,
  // while native bots exercise the candidate/base SmartAI implementation.
  'general-pair-trace': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  // These four full-match scenarios use the same fixed Wei roster with a
  // different seat permutation, so baseline/candidate runs can be paired by
  // seed while reducing seat-order confounding across the matrix.
  'general-pair-match-a': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-b': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-c': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-d': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-mixed-a': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-mixed-b': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-mixed-c': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
  'general-pair-match-mixed-d': { general: /Tào Tháo|曹操|Cao\s*Cao/i, generalId: 'hs__caocao', skill: null, pack: /^hegemony_standard$/i, packId: 'hegemony_standard', requiredCommand: 'CustomDialog', capacity: 4, requiresGeneral: false },
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
  // Enyuan covers the other source branch on Fazheng: TargetConfirmed for a
  // Peach must reveal the hidden owner before the compulsory draw effect.
  'hidden-enyuan': { general: /Pháp Chính|法正|Fa\s*Zheng/i, generalId: 'ld__fazheng', skill: /Ân Oán|恩怨|enyuan|ld__enyuan/i, pack: /^power$/i, packId: 'power', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-enyuan-deputy': { general: /Pháp Chính|法正|Fa\s*Zheng/i, generalId: 'ld__fazheng', skill: /Ân Oán|恩怨|enyuan|ld__enyuan/i, pack: /^power$/i, packId: 'power', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Fuyin is a compulsory TargetConfirmed trigger. The QA gate only
  // prelights the hidden skill; the real source Slash and native nullification
  // must still travel through the production PlayCard path.
  'hidden-fuyin': { general: /诸葛瞻|Gia Cát Chiêm|Zhuge\s*Zhan|父荫|Phụ Âm|bóng mát của cha|fuyin/i, generalId: 'zhugezhan', skill: /父荫|Phụ Âm|bóng mát của cha|fuyin/i, pack: /^shzl$/i, packId: 'shzl', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-fuyin-deputy': { general: /诸葛瞻|Gia Cát Chiêm|Zhuge\s*Zhan|父荫|Phụ Âm|bóng mát của cha|fuyin/i, generalId: 'zhugezhan', skill: /父荫|Phụ Âm|bóng mát của cha|fuyin/i, pack: /^shzl$/i, packId: 'shzl', requiredCommand: 'PlayCard', requiresGeneral: false },
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
  'hidden-ejue': { general: /张春华|Trương Xuân Hoa|Zhang\s*Chunhua/i, generalId: 'heg__zhangchunhua', skill: /扼绝|Ách Tuyệt|heg__ejue|ejue/i, pack: /^zqdl$/i, packId: 'zqdl', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-ejue-deputy': { general: /张春华|Trương Xuân Hoa|Zhang\s*Chunhua/i, generalId: 'heg__zhangchunhua', skill: /扼绝|Ách Tuyệt|heg__ejue|ejue/i, pack: /^zqdl$/i, packId: 'zqdl', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-dufu': { general: /司马冏|Tư Mã Quýnh|Sima\s*Jiong|独夫|Độc Phu|dufu/i, generalId: 'heg__simajiong', skill: /独夫|Độc Phu|dufu|heg__dufu/i, pack: /^zfxp$/i, packId: 'zfxp', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-dufu-deputy': { general: /司马冏|Tư Mã Quýnh|Sima\s*Jiong|独夫|Độc Phu|dufu/i, generalId: 'heg__simajiong', skill: /独夫|Độc Phu|dufu|heg__dufu/i, pack: /^zfxp$/i, packId: 'zfxp', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-jianzhi': { general: /贾充|Jia\s*Chong|Gian Chí|奸志|jianzhi/i, generalId: 'heg__jiachong', skill: /奸志|Gian Chí|jianzhi|heg__jianzhi/i, pack: /^zqdl$/i, packId: 'zqdl', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-jianzhi-deputy': { general: /贾充|Jia\s*Chong|Gian Chí|奸志|jianzhi/i, generalId: 'heg__jiachong', skill: /奸志|Gian Chí|jianzhi|heg__jianzhi/i, pack: /^zqdl$/i, packId: 'zqdl', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Zhiman is an optional DamageCaused effect. The native QA room keeps Ma Su
  // hidden until a real Slash reaches the source trigger, then checks damage
  // prevention and obtaining the target equipment card.
  'hidden-zhiman': { general: /马谡|Ma\s*Su|Chế Man|制蛮|zhiman/i, generalId: 'ld__masu', skill: /制蛮|Chế Man|zhiman|ld__zhiman/i, pack: /^transformation$/i, packId: 'transformation', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  'hidden-zhiman-deputy': { general: /马谡|Ma\s*Su|Chế Man|制蛮|zhiman/i, generalId: 'ld__masu', skill: /制蛮|Chế Man|zhiman|ld__zhiman/i, pack: /^transformation$/i, packId: 'transformation', requiredCommand: 'AskForSkillInvoke', requiresGeneral: false },
  // Jilix has a compulsory TargetConfirmed repeat followed by a second-hit
  // DamageInflicted prevention/removal. The QA package drives a single red
  // Slash so both source-defined effects are observed in one turn.
  'hidden-jilix': { general: /严白虎|Nghiêm Bạch Hổ|Yan\s*Baihu|寄篱|Ký Ly|jilix/i, generalId: 'ld__yanbaihu', skill: /寄篱|Ký Ly|jilix|ld__jilix/i, pack: /^lord_ex$/i, packId: 'lord_ex', requiredCommand: 'PlayCard', requiresGeneral: false },
  'hidden-jilix-deputy': { general: /严白虎|Nghiêm Bạch Hổ|Yan\s*Baihu|寄篱|Ký Ly|jilix/i, generalId: 'ld__yanbaihu', skill: /寄篱|Ký Ly|jilix|ld__jilix/i, pack: /^lord_ex$/i, packId: 'lord_ex', requiredCommand: 'PlayCard', requiresGeneral: false },
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
const deltaXiongsuanScenario = testScenario === 'delta-xiongsuan';
const deltaWenjiScenario = testScenario === 'delta-wenji';
const deltaLordWenjiScenario = testScenario === 'delta-lord-wenji';
const deltaQianceScenario = testScenario === 'delta-qiance';
const deltaJianchuScenario = testScenario === 'delta-jianchu';
const deltaTieqiScenario = testScenario === 'delta-tieqi';
const deltaChujueScenario = testScenario === 'delta-chujue';
const deltaZhenteScenario = testScenario === 'delta-zhente';
const deltaHalberdScenario = testScenario === 'delta-halberd';
const deltaSijianScenario = testScenario === 'delta-sijian';
const deltaBaweiScenario = testScenario === 'delta-bawei';
const deltaFengshiScenario = testScenario === 'delta-fengshi-siege' || testScenario === 'delta-fengshi-no-siege';
const deltaXisheScenario = testScenario === 'delta-xishe';
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
const hiddenEnyuanScenario = testScenario === 'hidden-enyuan' || testScenario === 'hidden-enyuan-deputy';
const hiddenEnyuanDeputyScenario = testScenario === 'hidden-enyuan-deputy';
const hiddenFuyinScenario = testScenario === 'hidden-fuyin' || testScenario === 'hidden-fuyin-deputy';
const hiddenFuyinDeputyScenario = testScenario === 'hidden-fuyin-deputy';
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
const hiddenEjueScenario = testScenario === 'hidden-ejue' || testScenario === 'hidden-ejue-deputy';
const hiddenEjueDeputyScenario = testScenario === 'hidden-ejue-deputy';
const hiddenDufuScenario = testScenario === 'hidden-dufu' || testScenario === 'hidden-dufu-deputy';
const hiddenDufuDeputyScenario = testScenario === 'hidden-dufu-deputy';
const hiddenJianzhiScenario = testScenario === 'hidden-jianzhi' || testScenario === 'hidden-jianzhi-deputy';
const hiddenJianzhiDeputyScenario = testScenario === 'hidden-jianzhi-deputy';
const hiddenZhimanScenario = testScenario === 'hidden-zhiman' || testScenario === 'hidden-zhiman-deputy';
const hiddenZhimanDeputyScenario = testScenario === 'hidden-zhiman-deputy';
const hiddenJilixScenario = testScenario === 'hidden-jilix' || testScenario === 'hidden-jilix-deputy';
const hiddenJilixDeputyScenario = testScenario === 'hidden-jilix-deputy';
const hiddenScenario = hiddenYijiScenario || hiddenRehideYijiScenario || hiddenJianxiongScenario || hiddenFankuiScenario || hiddenRevealScenario || hiddenActiveScenario || hiddenFanjianScenario || hiddenViewAsScenario || hiddenDualScenario || hiddenLuoshenScenario || hiddenTianduScenario || hiddenJizhiScenario || hiddenMingshiScenario || hiddenGongqingScenario || hiddenEnyuanScenario || hiddenFuyinScenario || hiddenQianxunScenario || hiddenKongchengScenario || hiddenWeimuScenario || hiddenXiaojiScenario || hiddenGuanxingScenario || hiddenYingziScenario || hiddenTianxiangScenario || hiddenDuanchangScenario || hiddenLiegongScenario || hiddenKuangguScenario || hiddenJueqingScenario || hiddenEjueScenario || hiddenDufuScenario || hiddenJianzhiScenario || hiddenZhimanScenario || hiddenJilixScenario;
// Bounded native QA probes end at the server-issued GameOver boundary and do
// not promise the ordinary result-screen/lobby/disconnect DOM transition. All
// hidden-skill probes are deliberately bounded this way: the QA package emits
// GameOver after the skill branch, so routing them through the ordinary lobby
// cleanup would turn a completed native assertion into a false failure.
const nativeQaGameOverCompletion = nativeQa &&
  (testScenario === 'draw-sequence' || testScenario === 'card-chosen' || testScenario === 'cards-and-choice' || testScenario === 'poxi' || deltaXiongsuanScenario || deltaWenjiScenario || deltaLordWenjiScenario || deltaQianceScenario || deltaJianchuScenario || deltaTieqiScenario || deltaChujueScenario || deltaZhenteScenario || deltaHalberdScenario || deltaSijianScenario || deltaBaweiScenario || deltaFengshiScenario || deltaXisheScenario || hiddenScenario);
const nativeQaGateTimeoutMs = Number(process.env.TQS_LIVE_NATIVE_QA_GATE_TIMEOUT_MS ?? '45000');
assert.ok(Number.isSafeInteger(nativeQaGateTimeoutMs) && nativeQaGateTimeoutMs >= 10000 && nativeQaGateTimeoutMs <= 180000,
  'TQS_LIVE_NATIVE_QA_GATE_TIMEOUT_MS must be a bounded integer between 10000 and 180000');
// A native bounded match may continue through a few AI turns after the
// browser has recovered from transport loss.  Keep this bounded at the
// contract maximum by default so a normal 57-second QA match cannot be
// mistaken for a missing GameOver; callers may still lower it explicitly for
// a deliberately short diagnostic.
const qaCleanupTimeoutMs = Number(process.env.TQS_LIVE_QA_CLEANUP_TIMEOUT_MS ?? '120000');
assert.ok(Number.isSafeInteger(qaCleanupTimeoutMs) && qaCleanupTimeoutMs >= 5000 && qaCleanupTimeoutMs <= 120000,
  'TQS_LIVE_QA_CLEANUP_TIMEOUT_MS must be a bounded integer between 5000 and 120000');
const nativeQaCatalog = nativeQa
  ? JSON.parse(readFileSync(path.join(process.env.TQS_QA_SOURCE_ROOT ?? path.join(repo, 'deploy/freekill-native/qa/tqs_qa'), 'catalog.json'), 'utf8')) as {
      generalPairMatrix?: {
        initialGeneralCount?: number;
        rosterSets?: Record<string, { enabledKingdoms?: string[]; offeredGroups?: string[][] }>;
        seatPermutations?: Record<string, number[]>;
      };
      scenarios: {
        id: string;
        seed: number;
        expectedCommand: string;
        enabledKingdoms?: string[];
        offeredGroups?: string[][];
        seedRange?: { min: number; max: number };
        matrixFamily?: string;
        matrixRosterSets?: string[];
        matrixSeatPermutation?: string;
      }[];
    }
  : null;
const nativeQaPlan = nativeQaCatalog?.scenarios.find((scenario) => scenario.id === testScenario);
if (nativeQa) {
  assert.ok(nativeQaPlan, `Native QA catalog has no scenario ${testScenario}`);
  assert.equal(nativeQaPlan?.expectedCommand, selectedScenario?.requiredCommand,
    `Native/browser expected command drift for ${testScenario}`);
}

function parseQaSeed(value: string | undefined): number | null {
  if (value === undefined || value === '') return null;
  const parsed = /^0x[0-9a-f]+$/iu.test(value) ? Number.parseInt(value.slice(2), 16) : Number(value);
  assert.ok(Number.isSafeInteger(parsed) && parsed >= 0 && parsed <= 0xffffffff,
    'TQS_LIVE_SEED must be a safe unsigned decimal or 0x-prefixed hexadecimal integer');
  return parsed;
}

function resolveMatrixInput(plan: NonNullable<typeof nativeQaPlan>, seed: number) {
  let enabledKingdoms = [...(plan.enabledKingdoms ?? [])];
  let offeredGroups = plan.offeredGroups?.map((group) => [...group]) ?? [];
  let rosterSet = 'fixed';
  const seatSwap = plan.matrixSeatPermutation ?? 'fixed';
  const range = plan.seedRange;
  if (plan.matrixFamily && range && seed >= range.min && seed <= range.max) {
    const rosterNames = plan.matrixRosterSets ?? [];
    const matrix = nativeQaCatalog?.generalPairMatrix;
    const permutation = matrix?.seatPermutations?.[seatSwap];
    assert.ok(rosterNames.length > 0 && permutation?.length === 4,
      `Invalid win-rate matrix metadata for ${plan.id}`);
    const rosterIndex = (seed - range.min) % rosterNames.length;
    rosterSet = rosterNames[rosterIndex];
    const selected = matrix?.rosterSets?.[rosterSet];
    assert.ok(selected?.offeredGroups?.length === 4 && selected.enabledKingdoms?.length === 4,
      `Missing win-rate roster set ${rosterSet}`);
    enabledKingdoms = [...selected.enabledKingdoms];
    offeredGroups = permutation.map((sourceSeat) => {
      const group = selected.offeredGroups?.[sourceSeat - 1];
      assert.ok(group?.length === (matrix?.initialGeneralCount ?? 5),
        `Invalid ${rosterSet} source seat ${sourceSeat}`);
      return [...group];
    });
  }
  return { enabledKingdoms, offeredGroups, rosterSet, seatSwap };
}

const requestedQaSeed = nativeQa ? parseQaSeed(process.env.TQS_LIVE_SEED) : null;
const nativeQaSeed = nativeQaPlan ? (requestedQaSeed ?? nativeQaPlan.seed) : null;
if (nativeQa && requestedQaSeed !== null) {
  const range = nativeQaPlan?.seedRange;
  assert.ok(range && requestedQaSeed >= range.min && requestedQaSeed <= range.max,
    `TQS_LIVE_SEED is outside the declared matrix range for ${testScenario}`);
}
const matrixInput = nativeQa && nativeQaPlan && nativeQaSeed !== null
  ? resolveMatrixInput(nativeQaPlan, nativeQaSeed)
  : null;
const initialGeneralCount = matrixInput?.offeredGroups[0]?.length ?? 5;
assert.ok(Number.isSafeInteger(initialGeneralCount) && initialGeneralCount >= 5 && initialGeneralCount <= 10,
  'QA initial general count must be an integer from five through ten');
if (matrixInput?.offeredGroups.length) {
  assert.ok(matrixInput.offeredGroups.length === 4 &&
    matrixInput.offeredGroups.every((group) => group.length === initialGeneralCount),
  'All QA seats must receive the same initial general count');
}
const matrixInputHash = matrixInput
  ? createHash('sha256').update(JSON.stringify({
      scenario: testScenario,
      seed: nativeQaSeed,
      enabledKingdoms: matrixInput.enabledKingdoms,
      offeredGroups: matrixInput.offeredGroups,
      rosterSet: matrixInput.rosterSet,
      seatSwap: matrixInput.seatSwap,
    })).digest('hex')
  : null;
const nativeQaRoomName = nativeQa && nativeQaPlan
  ? `TQSQA/${testScenario}/0x${nativeQaSeed!.toString(16).padStart(8, '0')}`
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
let scenarioXiongsuanChoiceReply = false;
let scenarioWenjiPlayerReply = false;
let scenarioWenjiCardReply = false;
let scenarioWenjiUseReply = false;
let scenarioLordWenjiGateReply = false;
let scenarioLordWenjiPlayerReply = false;
let scenarioLordWenjiCardReply = false;
let scenarioLordWenjiUseReply = false;
let scenarioLordWenjiReturnReply = false;
let scenarioQianceCardReply = false;
let scenarioQianceInvokeReply = false;
let scenarioJianchuGateReply = false;
let scenarioJianchuUseReply = false;
let scenarioJianchuInvokeReply = false;
let scenarioJianchuCardReply = false;
let scenarioTieqiGateReply = false;
let scenarioTieqiUseReply = false;
let scenarioTieqiGeneralReply = false;
let scenarioTieqiDiscardReply = false;
let scenarioChujueGateReply = false;
let scenarioChujueDeadFactionUseReply = false;
let scenarioChujueControlFactionUseReply = false;
let scenarioZhenteGateReply = false;
let scenarioZhenteUseReply = false;
let scenarioZhenteInvokeReply = false;
let scenarioZhenteChoiceReply = false;
let scenarioHalberdGateReply = false;
let scenarioHalberdUseReply = false;
let scenarioHalberdExtraTargetReply = false;
let scenarioSijianGateReply = false;
let scenarioSijianTargetReply = false;
let scenarioSijianCardReply = false;
let scenarioBaweiGateReply = false;
let scenarioBaweiDamagedUseReply = false;
let scenarioBaweiControlUseReply = false;
let scenarioFengshiGateReply = false;
let scenarioFengshiSlashReply = false;
let scenarioXisheGateReply = false;
let scenarioXisheWeaponReply = false;
let scenarioXisheCancelReply = false;
let scenarioXisheArmorReply = false;
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
let hiddenDuoshiInvoked: boolean = false;
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
let hiddenLuoshenAgReply = false;
let hiddenTianduGateReply = false;
let hiddenJizhiGateReply = false;
let hiddenJizhiCardReply = false;
let hiddenJizhiInvoked = false;
let hiddenMingshiGateReply = false;
let hiddenMingshiCardReply = false;
let hiddenGongqingGateReply = false;
let hiddenEnyuanGateReply = false;
let hiddenEnyuanCardReply = false;
let hiddenFuyinGateReply = false;
let hiddenFuyinCardReply = false;
let hiddenQianxunGateReply = false;
let hiddenQianxunCardReply = false;
let hiddenKongchengGateReply = false;
let hiddenKongchengCardReply = false;
let hiddenWeimuGateReply = false;
let hiddenWeimuCardReply = false;
let hiddenXiaojiGateReply = false;
let hiddenXiaojiCardReply = false;
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
let hiddenEjueGateReply = false;
let hiddenEjueDamageReply = false;
let hiddenDufuGateReply = false;
let hiddenDufuDamageReply = false;
let hiddenJianzhiGateReply = false;
let hiddenJianzhiDamageReply = false;
let hiddenJianzhiInvoked = false;
let hiddenZhimanGateReply = false;
let hiddenZhimanDamageReply = false;
let hiddenZhimanInvoked = false;
let hiddenZhimanCardReply = false;
let hiddenJilixGateReply = false;
let hiddenJilixCardReply = false;
let hiddenJilixChoiceReply = false;
const scenarioObservations: { command: string; requestId: number; reply: boolean; detail?: string }[] = [];

type PublicBotAudit = {
  logs: string[];
  boardPlayers: string[];
};

type GeneralPairTelemetry = {
  matchResult: {
    scenario: string;
    seed: number;
    rosterSet: string;
    seatSwap: string;
    winnerSeats: number[];
    winnerKingdoms: string[];
    winnerCount: number;
    outcome: 'win' | 'draw';
  } | null;
  decisionSummary: Record<string, string> | null;
  decisions: Record<string, string>[];
  offerSummary: Record<string, string> | null;
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

function metadataOnlyPublicAudit() {
  return { logs: [], boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [] as string[] };
}

function parseGeneralPairTelemetry(audits: { logs: string[] }[]): GeneralPairTelemetry {
  const logs = [...new Set(audits.flatMap((audit) => audit.logs))]
    .filter((log) => log.startsWith('[TQS QA] Pair'));
  const resultLog = logs.find((log) => log.startsWith('[TQS QA] PairMatchResult '));
  const resultMatch = resultLog?.match(/^\[TQS QA\] PairMatchResult scenario=([^ ]+) seed=(\d+) roster_set=([^ ]+) seat_swap=([^ ]+) winner_seats=([^ ]+) winner_kingdoms=([^ ]+) winner_count=(\d+) outcome=(win|draw)$/u);
  const parseSeatList = (value: string) => value === 'draw' ? [] : value.split(',').map((part) => Number(part));
  const parseKingdomList = (value: string) => value === 'draw' ? [] : value.split(',');
  const matchResult = resultMatch ? {
    scenario: resultMatch[1],
    seed: Number(resultMatch[2]),
    rosterSet: resultMatch[3],
    seatSwap: resultMatch[4],
    winnerSeats: parseSeatList(resultMatch[5]),
    winnerKingdoms: parseKingdomList(resultMatch[6]),
    winnerCount: Number(resultMatch[7]),
    outcome: resultMatch[8] as 'win' | 'draw',
  } : null;
  const summaryLog = logs.find((log) => log.startsWith('[TQS QA] PairDecisionSummary '));
  const summaryMatch = summaryLog?.match(/^\[TQS QA\] PairDecisionSummary (.+)$/u);
  const statsLog = logs.find((log) => log.startsWith('[TQS QA] PairDecisionStats '));
  const statsMatch = statsLog?.match(/^\[TQS QA\] PairDecisionStats (.+)$/u);
  const traceLog = logs.find((log) => log.startsWith('[TQS QA] PairDecisionTrace '));
  const traceMatch = traceLog?.match(/^\[TQS QA\] PairDecisionTrace (.+)$/u);
  const parseFields = (value: string) => Object.fromEntries(
    value.split(' ').map((field) => {
      const separator = field.indexOf('=');
      return separator > 0 ? [field.slice(0, separator), field.slice(separator + 1)] : [field, ''];
    }),
  );
  const decisionSummary = summaryMatch ? {
    ...parseFields(summaryMatch[1]),
    ...(statsMatch ? parseFields(statsMatch[1]) : {}),
    ...(traceMatch ? parseFields(traceMatch[1]) : {}),
  } : null;
  const decisions = logs
    .filter((log) => log.startsWith('[TQS QA] PairDecision '))
    .map((log) => {
      const match = log.match(/^\[TQS QA\] PairDecision (.+)$/u);
      return match ? parseFields(match[1]) : {};
    })
    .filter((entry) => Object.keys(entry).length > 0)
    .sort((left, right) => Number(left.seq ?? 0) - Number(right.seq ?? 0));
  const decisionMeta = logs
    .filter((log) => log.startsWith('[TQS QA] PairDecisionMeta '))
    .map((log) => {
      const match = log.match(/^\[TQS QA\] PairDecisionMeta (.+)$/u);
      return match ? parseFields(match[1]) : {};
    })
    .filter((entry) => Object.keys(entry).length > 0);
  const metaBySeq = new Map(decisionMeta.map((entry) => [String(entry.seq ?? ''), entry]));
  for (const decision of decisions) {
    const meta = metaBySeq.get(String(decision.seq ?? ''));
    if (meta) Object.assign(decision, meta);
  }
  const offerLog = logs.find((log) => log.startsWith('[TQS QA] PairOfferSummary '));
  const offerMatch = offerLog?.match(/^\[TQS QA\] PairOfferSummary (.+)$/u);
  const offerSummary = offerMatch ? parseFields(offerMatch[1]) : null;
  return { matchResult, decisionSummary, decisions, offerSummary };
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
  if (await target.count() && await target.getAttribute('aria-pressed') !== 'true') {
    await target.click();
  }
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
  // GameplayControls also contains the skill rail, hand, disabled-reason
  // details and stale turn affordances. Read only the current prompt node so
  // a previous Wenji choose-player string cannot classify the following
  // target-card request as another choose-player step.
  const promptNode = controls.locator('.gameplay-prompt:visible').first();
  const activePrompt = await promptNode.count()
    ? await promptNode.innerText().catch(() => '')
    : await controls.innerText().catch(() => '');
  const hiddenDuoshiDiscard = hiddenRevealScenario && hiddenDuoshiInvoked &&
    !/Mở tướng|亮将|reveal_skill&/i.test(activePrompt);

  // Lục Tốn's standard Duoshi source skill calls the real
  // Room:useVirtualCard("await_exhausted", {}, ...) path. Its card effect
  // then asks the actor to discard two cards through this same production
  // AskForUseActiveSkill/discard_skill scene. This branch is candidate-QA
  // only: it is scoped to hidden-reveal and never changes the production
  // default runner behavior.
  if (hiddenRevealScenario &&
      (/#AskForDiscard|Hãy bỏ|弃置|bỏ.*lá|discard/i.test(activePrompt) || hiddenDuoshiDiscard)) {
    console.log(`hidden-reveal duoshi discard request client=${client + 1} request=${requestId} ` +
      `hand=${await controls.locator('.gameplay-hand button').count()} ` +
      `enabled=${await controls.locator('.gameplay-hand button:enabled').count()} ` +
      `cardItems=${await controls.locator('[data-card-id]').count()} ` +
      `confirm=${await controls.getByRole('button', { name: 'Xác nhận', exact: true }).count()}`);
    const hand = controls.locator('.gameplay-hand button:enabled:not([aria-pressed="true"])');
    for (let n = 0; n < 2; n++) {
      const card = hand.first();
      assert.ok(await card.count(), 'hidden-reveal Duoshi must expose two discardable hand cards');
      await card.click();
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
    assert.ok(await ok.count() && await ok.isEnabled(),
      'hidden-reveal Duoshi discard must enable confirmation after two cards');
    await ok.click();
    const replied = await waitForReply(client, requestId);
    scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
      detail: 'hidden-reveal-duoshi-discard' });
    return replied;
  }

  if (deltaLordWenjiScenario) {
    // The two #ld__wenji-give prompts have the same translation, but
    // originate from different seats. The first gives the target Slash;
    // CardUseFinished requests the actor's different Peach afterwards.
    const choosePlayers = /#ld__wenji-choose|问计.*(?:令一名|choose_players_skill)|Vấn\s*Kế.*(?:khiến một người|chọn một người)/i.test(activePrompt);
    const giveCard = /#ld__wenji-give|问计.*(?:请交给|give)|Vấn\s*Kế.*(?:phải giao|hãy giao)|choose_cards_skill/i.test(activePrompt);
    const useTransferredSlash = /delta-lord-wenji|dùng Sát được hỏi kế/i.test(activePrompt);
    const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
    if (choosePlayers) {
      await chooseTargetIfNeeded(page);
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-lord-wenji must enable native target selection');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) scenarioLordWenjiPlayerReply = true;
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: 'delta-lord-wenji-choose-giver' });
      return replied;
    }
    if (giveCard) {
      const returnDifferentCard = scenarioLordWenjiCardReply;
      const card = controls.locator('.gameplay-hand')
        .getByRole('button', { name: returnDifferentCard ? /Đào|Peach|桃/i : /Sát|Slash|杀/i }).first();
      assert.ok(await card.count(), returnDifferentCard
        ? 'delta-lord-wenji must expose the distinct actor Peach for the return'
        : 'delta-lord-wenji must expose the target Slash for the initial handoff');
      await card.click();
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-lord-wenji must enable confirmation for the card handoff');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) {
        if (returnDifferentCard) scenarioLordWenjiReturnReply = true;
        else scenarioLordWenjiCardReply = true;
      }
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: returnDifferentCard ? 'delta-lord-wenji-return-different-peach' : 'delta-lord-wenji-target-gives-slash' });
      return replied;
    }
    if (useTransferredSlash) {
      const slash = controls.locator('.gameplay-hand button:enabled').filter({ hasText: /Sát|Slash|杀/i }).first();
      assert.ok(await slash.count(), 'delta-lord-wenji must expose the transferred Slash');
      await slash.click();
      await chooseTargetIfNeeded(page);
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-lord-wenji must confirm the transferred Slash against its giver');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) scenarioLordWenjiUseReply = true;
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: 'delta-lord-wenji-use-transferred-slash' });
      return replied;
    }
    throw new Error('delta-lord-wenji received an unclassified native active-skill prompt');
  }
  if (deltaWenjiScenario) {
    // Room:askToChoosePlayers() and Room:askToCards() both arrive as the
    // production AskForUseActiveSkill scene. Keep the three Wenji steps
    // explicit so the runner never guesses between the actor and target hand.
    const choosePlayers = /问计.*(?:令一名|choose_players_skill)|Vấn\s*Kế.*(?:có thể khiến|khiến một người|chọn một người)|#(?:nos_heg__)?wenji-choose/i.test(activePrompt);
    const giveCard = !choosePlayers && /问计.*(?:请交给|give)|Vấn\s*Kế.*(?:phải giao|hãy giao)|#(?:nos_heg__)?wenji-give|choose_cards_skill/i.test(activePrompt);
    const useTransferredSlash = /delta-wenji|dùng Sát được hỏi kế/i.test(activePrompt);
    if (choosePlayers) {
      await chooseTargetIfNeeded(page);
      const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-wenji must enable target confirmation for the Wenji recipient');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) scenarioWenjiPlayerReply = true;
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: 'delta-wenji-choose-recipient' });
      return replied;
    }
    if (giveCard) {
      const card = controls.locator('.gameplay-hand')
        .getByRole('button', { name: /Sát|Slash|杀/i }).first();
      assert.ok(await card.count(), 'delta-wenji must expose the reserved target Slash by its accessible card name');
      await card.click();
      const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-wenji must enable confirmation after the target selects the Slash');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) scenarioWenjiCardReply = true;
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: 'delta-wenji-target-gives-slash' });
      return replied;
    }
    if (useTransferredSlash) {
      const hand = controls.locator('.gameplay-hand button:enabled');
      const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
      const card = await labelledSlash.count() ? labelledSlash : hand.first();
      assert.ok(await card.count(), 'delta-wenji must expose the transferred actor Slash');
      await card.click();
      await chooseTargetIfNeeded(page);
      const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
      assert.ok(await ok.count() && await ok.isEnabled(),
        'delta-wenji must enable confirmation after using the transferred Slash');
      await ok.click();
      const replied = await waitForReply(client, requestId);
      if (replied) {
        scenarioWenjiUseReply = true;
        scenarioActiveSkillReply = true;
      }
      scenarioObservations.push({ command: 'AskForUseActiveSkill', requestId, reply: replied,
        detail: 'delta-wenji-use-transferred-slash' });
      return replied;
    }
  }
  // The production skill rail is a sibling of GameplayControls, not a child
  // of its request region.  Scope to the rail directly so active skills are
  // found on the same DOM path used by the real UI and the local Lua tests.
  const skillButtons = page.locator('button.sg-skill-button');
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
  const xiongsuanActiveRequest = /xiongsuan|凶算|Hung\s*Toán/i.test(activePrompt);
  if (deltaXiongsuanScenario && prefer && xiongsuanActiveRequest) {
    // AskForUseActiveSkill already identifies xiongsuan in the native request.
    // Some web projections render its skill button as informational/disabled;
    // the card/target reply remains the production-valid path in that case.
    const hand = controls.locator('.gameplay-hand button:enabled');
    const jink = hand.filter({ hasText: /Thiểm|Jink|闪/i }).first();
    const card = await jink.count() ? jink : hand.first();
    assert.ok(await card.count(), 'delta-xiongsuan must expose the reserved actor Jink');
    await chooseTargetIfNeeded(page);
    await card.click();
    const ok = controls.getByRole('button', { name: 'Xác nhận', exact: true });
    assert.ok(await ok.count() && await ok.isEnabled(),
      'delta-xiongsuan must enable confirmation after selecting one card and one target');
    await ok.click();
    const replied = await waitForReply(client, requestId);
    if (replied) scenarioActiveSkillReply = true;
    return replied;
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
  if (hiddenRehideYijiScenario) {
    console.log('hidden-rehide-yiji UI metadata', JSON.stringify({
      yiji, enyuan,
      hand: await controls.locator('.gameplay-hand button').count(),
      selectable: await controls.locator('.gameplay-hand button:enabled:not([aria-pressed="true"])').count(),
      selfTargets: await page.locator('.board-self .gameplay-target:enabled').count(),
    }));
  }
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
async function selectPair(page:Page, preferredLabel?:RegExp): Promise<number>{
  const group=page.getByRole('group',{name:'Danh sách võ tướng'});await group.waitFor({timeout:60000});
  // Each choice now has a separate “view skills” button.  Restrict the
  // deterministic pair search to actual choice buttons so an info sheet
  // cannot intercept the next selection click.
  const buttons=group.locator('button.general-choice');const n=await buttons.count();
  if (nativeQa && generalPairMatchScenario) {
    assert.equal(n, initialGeneralCount,
      `Native ${testScenario} UI must render exactly ${initialGeneralCount} general choices; observed ${n}`);
  }
  const order:number[]=[];
  let preferredCount=0;
  for(let i=0;i<n;i++) {
    const label=await buttons.nth(i).innerText();
    if (preferredLabel?.test(label)) { preferredCount++; order.unshift(i); } else order.push(i);
  }
  if (preferredLabel && preferredCount === 0) {
    throw new Error('Scenario caller general was not offered by the real server');
  }
  // Upstream's larger general/skill snapshot makes the deputy-compatibility
  // Lua probe noticeably slower on a cold Wasmoon page.  The UI deliberately
  // disables every other choice while that probe is running, so keep the
  // bounded wait local to this step instead of masking unrelated failures with
  // a longer global Playwright timeout.
  const pairChoiceTimeout = 60000;
  for(const a of order){
    for(const b of order){
      if(a===b)continue;
      const reset=page.getByRole('button',{name:'Chọn lại'});
      // A rejected pair leaves the first selection active.  Reset before
      // every candidate pair; otherwise the next b click toggles/overflows
      // the previous selection and the exhaustive search can falsely report
      // that no legal pair exists.
      if(await reset.isEnabled())await reset.click();
      await buttons.nth(a).click({ timeout: pairChoiceTimeout });
      // InitialGeneralPanel evaluates every deputy synchronously after the
      // main selection.  A syntactically offered card can therefore become a
      // disabled, rule-invalid deputy; do not ask Playwright to click it and
      // wait out the whole request timeout.  Wait for the panel to leave its
      // bounded evaluation state, then skip only the cards the UI rejected.
      await page.waitForFunction(() => Array.from(document.querySelectorAll('.sg-general-choice-entry'))
        .every((entry) => entry.getAttribute('data-general-status') !== 'busy'), undefined,
      { timeout: pairChoiceTimeout });
      if (!await buttons.nth(b).isEnabled()) continue;
      await buttons.nth(b).click({ timeout: pairChoiceTimeout });
      if(await page.getByRole('button',{name:'Xác nhận tướng'}).isEnabled()){
        console.log('Native pair candidate: legally selectable two-slot pair');
        await page.getByRole('button',{name:'Xác nhận tướng'}).click();return n;
      }
    }
  }
  throw new Error('No valid native general pair');
}

async function clickTrustAction(page: Page, timeout = 15000): Promise<void> {
  if (await page.locator('.board-trust-status').isVisible().catch(() => false)) return;
  const trust = page.getByRole('button', { name: 'BOT chơi hộ', exact: true });
  if (await trust.isVisible().catch(() => false)) {
    await trust.click({ timeout });
    return;
  }
  // The production board keeps the trust action inside a collapsed toolbar;
  // open that toolbar before querying the action so the harness follows the
  // same accessible path a user sees on mobile and desktop.
  await page.getByRole('button', { name: 'Tùy chọn trận đấu', exact: true }).click({ timeout });
  if (await page.getByRole('button', { name: 'Tự chơi lại', exact: true }).isVisible().catch(() => false)) return;
  await page.getByRole('button', { name: 'BOT chơi hộ', exact: true }).click({ timeout });
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
      const gatewayHealth = deploymentUrl ? `${base}/gateway/healthz` :
        `${gatewayTarget ?? `http://127.0.0.1:${gatewayPort}`}/healthz`;
      const ready = await fetch(gatewayHealth,
        { signal: AbortSignal.timeout(Math.min(5000, Math.max(1,healthDeadline-Date.now()))) });
      if (ready.ok && await ready.text()==='ok') { healthReady = true; break; }
    } catch {}
    await new Promise(r=>setTimeout(r, deploymentUrl ? 1000 : 100));
  }
  assert.ok(healthReady,'Candidate health endpoint did not become ready within its bounded startup window');
  if (!deploymentUrl) server=await preview({configFile:false,root:web,build:{outDir:frozenDist},preview:{host:'127.0.0.1',port:webPort,strictPort:true,
    proxy:{'/gateway':{target:gatewayTarget ?? `http://127.0.0.1:${gatewayPort}`,ws:true,rewrite:p=>p.replace(/^\/gateway/,'')}}}});
  browser=await chromium.launch({executablePath:chrome,headless:true});
  for(let i=0;i<(observeNativePrivacy ? 3 : 2);i++){
    const account=i===0?first:i===1?second:observerAccount!;
    const context=await browser.newContext({viewport:{width:390,height:844}});const p=await context.newPage();
    if (i < 2) pages.push(p); else observerPage = p;
    // tsx keeps function names when it serializes this runner. Playwright
    // evaluates addInitScript callbacks in the browser, but that transform's
    // __name helper is otherwise only present in the Node runner. Define the
    // identity helper in the test page before any callback is evaluated; this
    // is test-only and never enters the frozen production bundle.
    await p.addInitScript({content: 'globalThis.__name ??= (value) => value;'});
    await p.addInitScript(() => {
      // Opt in to numeric-only WASM/Lua and callback telemetry.
      (window as unknown as { __tqsEnableLuaTelemetry: boolean }).__tqsEnableLuaTelemetry = true;
      const original=console.error;
      (window as unknown as {__tqsMemoryFaultCount:number}).__tqsMemoryFaultCount=0;
      console.error=(...args:unknown[])=>{
        if(args.some(v=>typeof v==='string' && v.includes('Cannot enlarge memory')))
          (window as unknown as {__tqsMemoryFaultCount:number}).__tqsMemoryFaultCount++;
        original(...args);
      };
    });
    // Install the transport harness on every live QA page. It is test-only,
    // does not enter the frozen production bundle, and keeping installation
    // unconditional avoids browser init-script ordering differences between
    // the reconnect, observer-leave and replay lanes.
    await p.addInitScript((rawOptions: {
      peerUrl: string | null; replayEnabled: boolean;
    } | undefined) => {
      // Playwright normally supplies the second argument, but keep the
      // test-only harness fail-closed if a browser-side init-script bridge
      // drops it: replay stays disabled and the normal gateway remains the
      // only transport target.
      const options = rawOptions ?? { peerUrl: null, replayEnabled: false };
      if (!options.replayEnabled) {
        // Reconnect and observer-leave lanes need only a transparent socket
        // tracker. Keeping this path deliberately small avoids touching
        // send() or parsing frames when no replay probe was requested.
        let active: WebSocket | undefined;
        const sockets: WebSocket[] = [];
        (window as unknown as { __tqsTestDisconnect(): {
          socketCount: number; openSocketCount: number; activeReadyState: number;
          candidateReadyState: number; candidateAfterReadyState: number; closed: boolean;
        } }).__tqsTestDisconnect = () => {
          const candidates = active ? [
            active,
            ...[...sockets].reverse().filter((socket) => socket !== active),
          ] : [...sockets].reverse();
          const candidate = candidates.find((socket) =>
            socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING);
          const result = {
            socketCount: sockets.length,
            openSocketCount: sockets.filter((socket) => socket.readyState === WebSocket.OPEN).length,
            activeReadyState: active?.readyState ?? -1,
            candidateReadyState: candidate?.readyState ?? -1,
            candidateAfterReadyState: -1,
            closed: false,
          };
          if (candidate) {
            candidate.close();
            result.candidateAfterReadyState = candidate.readyState;
            result.closed = true;
          }
          return result;
        };
        window.WebSocket = new Proxy(window.WebSocket, { construct(Target, args) {
          const socket = Reflect.construct(Target,
            options.peerUrl ? [options.peerUrl, ...args.slice(1)] : args) as WebSocket;
          sockets.push(socket);
          active = socket;
          return socket;
        } });
        return;
      }
      let active: WebSocket | undefined;
      const sockets: Array<{ socket: WebSocket; lastReply: ArrayBuffer | null }> = [];
      let replaying = false;
      let sendCalls = 0;
      let binarySendCalls = 0;
      let replyCandidateFrames = 0;
      let lastBinaryLength = 0;
      let lastReplyLength = 0;
      const readHead = (bytes: Uint8Array, start: number) => {
        if (start >= bytes.length) return null;
        const initial = bytes[start];
        const major = initial >> 5;
        const additional = initial & 31;
        if (additional < 24) return { major, value: additional, next: start + 1 };
        const width = additional === 24 ? 1 : additional === 25 ? 2 :
          additional === 26 ? 4 : additional === 27 ? 8 : 0;
        if (!width || start + 1 + width > bytes.length) return null;
        let value = 0;
        for (let index = 0; index < width; index++) {
          value = value * 256 + bytes[start + 1 + index];
          if (!Number.isSafeInteger(value)) return null;
        }
        return { major, value, next: start + 1 + width };
      };
      const isReplyFrame = (bytes: Uint8Array) => {
        try {
          const array = readHead(bytes, 0);
          if (!array || array.major !== 4 || (array.value !== 4 && array.value !== 6)) return false;
          const request = readHead(bytes, array.next);
          const type = request && readHead(bytes, request.next);
          if (!request || !type || (type.major !== 0 && type.major !== 1)) return false;
          const command = readHead(bytes, type.next);
          return !!command && (command.major === 2 || command.major === 3) &&
            command.value === 0 && type.major === 0 && (type.value & 0x200) !== 0;
        } catch {
          return false;
        }
      };
      const toBytes = (data: unknown): Uint8Array | null => {
        if (data instanceof ArrayBuffer) return new Uint8Array(data);
        if (ArrayBuffer.isView(data)) {
          return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
        }
        return null;
      };
      window.WebSocket = new Proxy(window.WebSocket, { construct(Target, args) {
        const socket = Reflect.construct(Target, options.peerUrl ? [options.peerUrl,...args.slice(1)] : args) as WebSocket;
        const record = { socket, lastReply: null as ArrayBuffer | null };
        sockets.push(record);
        active = socket;
        if (options.replayEnabled) {
          const originalSend = socket.send.bind(socket);
          Object.defineProperty(socket, 'send', {
            configurable: true,
            writable: true,
            value: (data: unknown) => {
              sendCalls++;
              const bytes = toBytes(data);
              if (bytes) {
                binarySendCalls++;
                lastBinaryLength = bytes.byteLength;
              }
              if (!replaying && bytes && isReplyFrame(bytes)) {
                replyCandidateFrames++;
                record.lastReply = bytes.slice().buffer;
                lastReplyLength = bytes.byteLength;
              }
              return originalSend(data as string | ArrayBufferLike | ArrayBufferView);
            },
          });
        }
        return socket;
      } });
      if (options.replayEnabled) {
        (window as unknown as { __tqsTestReplayLastReply(): boolean }).__tqsTestReplayLastReply = () => {
          for (const candidate of [...sockets].reverse()) {
            if (candidate.socket.readyState !== WebSocket.OPEN || !candidate.lastReply) continue;
            const replay = candidate.lastReply.slice(0);
            candidate.lastReply = null;
            replaying = true;
            try {
              candidate.socket.send(replay);
            } finally {
              replaying = false;
            }
            return true;
          }
          return false;
        };
      }
      (window as unknown as { __tqsTestReplayDebug(): unknown }).__tqsTestReplayDebug = () => ({
        enabled: options.replayEnabled,
        sendCalls, binarySendCalls, replyCandidateFrames, lastBinaryLength, lastReplyLength,
        socketCount: sockets.length,
        openSocketCount: sockets.filter((candidate) => candidate.socket.readyState === WebSocket.OPEN).length,
      });
    }, {
      peerUrl: testGatewayRestart && i===1 ? `ws://127.0.0.1:${peerGatewayPort}/ws` : null,
      replayEnabled: cardWireReplayRequested,
    });
    p.setDefaultTimeout(15000);p.on('pageerror',(error)=>{
      errors.push(`client-${i+1}: JavaScript error`);
      // Keep page-error evidence as bounded categories only.  A replayed
      // native reply can surface a browser exception without a console row;
      // retain enough signal to classify that lane without persisting raw
      // exception text, stack paths, cards or request payloads.
      const message = String(error?.message ?? error);
      const categories = [
        'Lua dispatch failed', 'Lua callback failed', 'Error invoking Lua',
        'TypeError', 'ReferenceError', 'SyntaxError', 'Error: ',
        'AskForUseActiveSkill', 'CardItem', 'MoveCards', 'SetCardMark',
        'Cannot enlarge memory', 'invalid', 'unknown', 'stale', 'area',
        'assert', 'card', 'CBOR', 'throw', 'WebSocket',
      ].filter((token) => message.includes(token));
      const context = {client:i+1,
        lastIncoming:traces[i].filter(t=>t.direction==='incoming').at(-1)?.command ?? null,
        diagnosticCode:categories.length ? 2 : 1};
      errorContexts.push(context);
      if (auditNativeDeck) {
        const stackLine = String(error?.stack ?? '').split('\n')
          .find((line) => /(?:assets|index)[^\s]*\.js(?::\d+:\d+)?/u.test(line));
        const location = stackLine?.match(/((?:assets|index)[^\s]*\.js(?::\d+:\d+)?)/u)?.[1] ?? 'unknown';
        const fingerprint = createHash('sha256').update(message).digest('hex').slice(0, 12);
        console.warn(`client-${i+1}: page diagnostic name=${error?.name ?? 'Error'} length=${message.length} ` +
          `fingerprint=${fingerprint} location=${location} categories=${categories.join(',') || 'unmatched'}`);
      }
    });
    p.on('console',m=>{if(m.type()==='error'){
      // The console message and source URL may contain private cards, generals,
      // credentials or filesystem paths. Persist only a bounded error signal.
      errors.push(`client-${i+1}: browser-console-error`);
      const context = {client:i+1,
        lastIncoming:traces[i].filter(t=>t.direction==='incoming').at(-1)?.command ?? null,
        diagnosticCode:0};
      errorContexts.push(context);
      if (auditNativeDeck) {
        const message = m.text();
        const categories = [
          'Lua dispatch failed', 'Lua callback failed', 'Error invoking Lua',
          'TypeError', 'ReferenceError', 'SyntaxError', 'Error: ',
          'AskForUseActiveSkill', 'CardItem', 'MoveCards', 'SetCardMark',
          'Cannot enlarge memory', 'invalid', 'unknown', 'stale', 'area',
          'assert', 'card', 'CBOR', 'throw', 'WebSocket',
        ].filter((token) => message.includes(token));
        const luaSource = message.match(/(?:ltk\/client|packages\/freekill-core|packages\/hegemony)\/[a-zA-Z0-9_/.\-]+\.lua:\d+/u);
        console.warn(`client-${i+1}: browser diagnostic categories=${categories.join(',') || 'unmatched'}` +
          (luaSource ? ` lua=${luaSource[0]}` : ''));
      }
      if (auditNativeDeck) {
        // A finite diagnostic vocabulary helps investigate native failures
        // without exporting the console text or exception payload.
        for (const [code, label] of [
          'MoveCards retired reference is absent from its source area',
          'MoveCards retired opaque reference is unknown or stale',
          'MoveCards incoming reference is duplicated in its source',
          'MoveCards incoming draw reference already belongs to an area',
          'MoveCards draw source position is out of range',
          'MoveCards incoming reference is absent from its source area',
          'projected snapshot requires negotiated Hegemony v1',
          'projected snapshot requires Hegemony settings',
          'client card-wire aliases are unavailable',
          'snapshot state requires the validated Hegemony room',
          'MoveCards stable reference is absent from its source area',
          'MoveCards hidden reference is unknown without a transition ref',
          'MoveCards draw source is not anonymous',
        ].entries()) if (m.text().includes(label)) {
          context.diagnosticCode = code + 1;
          console.warn(`client-${i+1}: ${label}`);
        }
      }
    } else if (m.type() === 'warning' && m.text().includes('AskForCardsAndChoice')) {
      console.warn(`client-${i+1}: AskForCardsAndChoice warning`);
    }});
    p.on('websocket',ws=>{
      currentSockets[i] = ws; transportOpen[i] = true;
      // A new transport must prove its physical identity independently. In
      // particular, an observed player's Lua Self is not the observer socket.
      let boundSeat: number | null = null;
      let socketNegotiated = false;
      ws.on('close', () => { if (currentSockets[i] === ws) transportOpen[i] = false; });
      const streams={incoming:new PacketStream(),outgoing:new PacketStream()};
      const rawStreams={incoming:new RawPacketStream(),outgoing:new RawPacketStream()};
      const requestCommands = new Map<number, string>();
      const nativeDeckAuditPath = path.join(repo, 'deploy/freekill-native/qa/card-wire-native-deck-audit.lua');
      const nativeSupplementalAuditPath = path.join(repo,
        'deploy/freekill-native/qa/card-wire-native-supplemental-audit.lua');
      const recordPacketBytes = (capture: {
        packetBytes: { total: number; min: number; max: number; le256: number;
          le1024: number; le4096: number; gt4096: number };
      }, bytes: Uint8Array) => {
        const size = bytes.byteLength;
        const metrics = capture.packetBytes;
        metrics.total += size;
        metrics.min = metrics.min === 0 ? size : Math.min(metrics.min, size);
        metrics.max = Math.max(metrics.max, size);
        if (size <= 256) metrics.le256++;
        else if (size <= 1024) metrics.le1024++;
        else if (size <= 4096) metrics.le4096++;
        else metrics.gt4096++;
      };
      const captureRawPacket = (direction: 'incoming' | 'outgoing', rawPacket: {
        bytes: Uint8Array;
      }) => {
        nativePacketSizeCapture[i].packets++;
        if (direction === 'incoming') nativePacketSizeCapture[i].incomingPackets++;
        else nativePacketSizeCapture[i].outgoingPackets++;
        recordPacketBytes(nativePacketSizeCapture[i], rawPacket.bytes);
      };
      const auditRawPacket = (rawPacket: { command: string; bytes: Uint8Array }) => {
        nativeWireCapture[i].packets++;
        recordPacketBytes(nativeWireCapture[i], rawPacket.bytes);
        const isSetup = rawPacket.command === 'Setup';
        const audit = spawnSync(luaExecutable, [nativeDeckAuditPath,
          path.join(runtime, 'packages/freekill-core'), '--raw-packet',
          isSetup ? 'identity' : i === 2 ? 'observer' : 'player', String(boundSeat ?? '')], {
          input: Buffer.from(rawPacket.bytes).toString('hex'), encoding: 'utf8',
          timeout: 10_000, maxBuffer: 64 * 1024,
          env: {
            ...process.env,
            ...(privacyAuditSalt ? { TQS_PRIVACY_AUDIT_SALT: privacyAuditSalt } : {}),
            ...(isSetup ? { TQS_PRIVACY_EXPECTED_ACCOUNT: account.username } : {}),
          },
        });
        if (isSetup) {
          const match = audit.status === 0 && !audit.error
            ? /^IDENTITY=([1-9]\d*)\s*$/u.exec(audit.stdout) : null;
          const seat = match ? Number(match[1]) : null;
          if (seat === null || !Number.isSafeInteger(seat)) {
            nativeWireCapture[i].failures++;
            errors.push(`client-${i+1}: native-raw-identity-rejected`);
          } else {
            boundSeat = seat;
          }
          return;
        }
        const privacyAudit = audit.status === 0 ? parsePrivacyAudit(audit.stdout) : null;
        if (audit.error || !privacyAudit) {
          nativeWireCapture[i].failures++;
          console.warn(`client-${i+1}: native-raw-wire-rejected command=${rawPacket.command} reason=${audit.error ? 'audit-process-error' : 'coverage-parse'}`);
          errors.push(`client-${i+1}: native-raw-wire-rejected`);
          return;
        }
        nativeWireCapture[i].commands[rawPacket.command]++;
        for (const category of PRIVACY_CATEGORIES) {
          nativeWireCapture[i].categoryCounts[category] += privacyAudit.coverage[category];
        }
        for (const fingerprint of privacyAudit.hiddenFingerprints) {
          for (let audience = 0; audience < hiddenReferenceFingerprints.length; audience++) {
            if (audience !== i && hiddenReferenceFingerprints[audience].has(fingerprint)) {
              nativeWireCapture[i].hiddenReferenceCollisions++;
              nativeWireCapture[audience].hiddenReferenceCollisions++;
              errors.push(`client-${i + 1}: native-hidden-reference-audience-collision`);
            }
          }
          hiddenReferenceFingerprints[i].add(fingerprint);
        }
      };
      const auditSupplementalPacket = (rawPacket: {
        command: string; requestId: number; type: number; bytes: Uint8Array;
      }, packetDirection: 'incoming' | 'outgoing', replyCommand?: string) => {
        const command = packetDirection === 'incoming' ? rawPacket.command : replyCommand;
        if (!command || !nativeSupplementalCommands.has(command)) return;
        nativeSupplementalCapture[i].packets++;
        recordPacketBytes(nativeSupplementalCapture[i], rawPacket.bytes);
        if (packetDirection === 'incoming') nativeSupplementalCapture[i].incomingPackets++;
        else nativeSupplementalCapture[i].replyPackets++;
        const audit = spawnSync(luaExecutable, [nativeSupplementalAuditPath,
          path.join(runtime, 'packages/freekill-core'), '--raw-packet',
          i === 2 ? 'observer' : 'player', String(boundSeat ?? ''), packetDirection, command], {
          input: Buffer.from(rawPacket.bytes).toString('hex'), encoding: 'utf8',
          timeout: 10_000, maxBuffer: 1024,
        });
        const coverage = audit.status === 0 && !audit.error
          ? parseSupplementalCoverage(audit.stdout) : null;
        if (!coverage) {
          nativeSupplementalCapture[i].failures++;
          // The Lua auditor intentionally emits only a numeric source line on
          // rejection. Preserve that bounded diagnostic without exporting the
          // packet, decoded payload, or raw exception text.
          const failureLine = /failureLine=(\d+)/u.exec(audit.stderr ?? '')?.[1] ?? 'unknown';
          console.warn(`client-${i+1}: native-supplemental-wire-rejected command=${command} direction=${packetDirection} failureLine=${failureLine}`);
          errors.push(`client-${i+1}: native-supplemental-wire-rejected`);
          return;
        }
        nativeSupplementalCapture[i].channels[coverage.channel]++;
        if (packetDirection === 'incoming') nativeSupplementalCapture[i].commands[command]++;
        else nativeSupplementalCapture[i].replies[command]++;
      };
      const record = (direction: 'incoming' | 'outgoing', payload: string | Buffer) => {
        if(typeof payload==='string')return;
        if (captureNativePackets) {
          if (auditNativeDeck) nativeSupplementalCapture[i].frames++;
          nativePacketSizeCapture[i].frames++;
          for (const rawPacket of rawStreams[direction].push(payload)) {
            captureRawPacket(direction, rawPacket);
            if (auditNativeDeck && direction === 'incoming') {
              nativeWireCapture[i].frames++;
              if (rawPacket.command === 'Setup' || nativeDeckCommands.has(rawPacket.command)) {
                auditRawPacket(rawPacket);
              }
              if (nativeSupplementalCommands.has(rawPacket.command)) {
                auditSupplementalPacket(rawPacket, 'incoming');
              }
            } else if (auditNativeDeck && rawPacket.command === '' &&
                (rawPacket.type & PacketType.REPLY) !== 0) {
              const command = requestCommands.get(rawPacket.requestId);
              auditSupplementalPacket(rawPacket, 'outgoing', command);
              if (command) requestCommands.delete(rawPacket.requestId);
            }
          }
        }
        for(const packet of streams[direction].push(payload)) {
          traces[i].push({direction,command:packet.command,requestId:packet.requestId,type:packet.type});
          if (auditNativeDeck && direction === 'incoming') {
            if (packet.requestId >= 0 && nativeRequestCommands.has(packet.command)) {
              requestCommands.set(packet.requestId, packet.command);
            }
            if (packet.command === 'Setup') {
              const identity = spawnSync(luaExecutable, [path.join(repo,
                'deploy/freekill-native/qa/card-wire-native-deck-audit.lua'),
              path.join(runtime, 'packages/freekill-core'), 'Setup', 'identity'], {
                input: Buffer.from(packet.data).toString('hex'), encoding: 'utf8',
                timeout: 10_000, maxBuffer: 1024,
                env: { ...process.env, TQS_PRIVACY_EXPECTED_ACCOUNT: account.username },
              });
              const match = identity.status === 0 && !identity.error
                ? /^IDENTITY=([1-9]\d*)\s*$/u.exec(identity.stdout) : null;
              const seat = match ? Number(match[1]) : null;
              if (seat === null || !Number.isSafeInteger(seat) ||
                  (boundSeat !== null && boundSeat !== seat)) {
                nativeDeckPrivacy[i].failures++;
                errors.push(`client-${i+1}: native-identity-rejected`);
              } else {
                boundSeat = seat;
              }
            }
            if (packet.command === 'CardWireNegotiated') {
              socketNegotiated = true;
              nativeDeckPrivacy[i].negotiated = true;
            }
            if (nativeDeckCommands.has(packet.command)) {
              const audit = spawnSync(luaExecutable, [path.join(repo,
                'deploy/freekill-native/qa/card-wire-native-deck-audit.lua'),
              path.join(runtime, 'packages/freekill-core'), packet.command,
              i === 2 ? 'observer' : 'player', String(boundSeat ?? '')], {
                input: Buffer.from(packet.data).toString('hex'), encoding: 'utf8',
                timeout: 10_000, maxBuffer: 1024,
              });
              const coverage = audit.status === 0 ? parsePrivacyCoverage(audit.stdout) : null;
              if (!socketNegotiated || boundSeat === null || audit.error || !coverage) {
                nativeDeckPrivacy[i].failures++;
                const reason = !socketNegotiated ? 'not-negotiated' : boundSeat === null ? 'unbound-seat' :
                  audit.error ? 'audit-process-error' : !coverage ? 'coverage-parse' : 'unknown';
                console.warn(`client-${i+1}: native-deck-privacy-rejected command=${packet.command} reason=${reason}`);
                errors.push(`client-${i+1}: native-deck-privacy-rejected`);
              } else {
                nativeDeckPrivacy[i].commands[packet.command]++;
                for (const category of PRIVACY_CATEGORIES) {
                  nativeDeckPrivacy[i].categoryCounts[category] += coverage[category];
                }
              }
            }
          }
        }
      };
      ws.on('framereceived',({payload})=>record('incoming',payload));
      ws.on('framesent',({payload})=>record('outgoing',payload));
    });
    await p.addInitScript((session) => {
      (window as Window & { __tqsE2eGameSession?: unknown }).__tqsE2eGameSession = session;
    }, {
      uid: `qa-${account.username}`,
      displayName: account.username,
      nativeName: account.username,
      // The isolated native QA runtime still enforces the production HMAC
      // ticket contract. Keep the short-lived TQS1 ticket in memory; the
      // secret is supplied only by the caller's isolated QA environment.
      ticket: nativeQa ? nativeQaTicket(account.username) : account.password,
      expiresAt: Math.floor(Date.now() / 1000) + 3600,
      poolPolicy: { schemaVersion: 1, mode: 'new_heg_mode', revision: 0, generalNum: initialGeneralCount,
        disabledPacks: { generals: [], cards: [] }, appliesTo: 'new_rooms' },
    });
    await p.addInitScript((args: {
      version: number; observerMode: string; playerMode: string; playerIndex: number; index: number;
    }) => {
      const target = window as Window & {
        __tqsCardWireVersion?: number;
        __tqsCardWireObserverMode?: string;
        __tqsCardWireCapabilityDrops?: number;
        __tqsCardWireDropperInstalled?: boolean;
      };
      target.__tqsCardWireVersion = args.version === 1 ? 1 : 0;
      if (args.observerMode !== 'valid') target.__tqsCardWireObserverMode = args.observerMode;
      if (args.playerMode === 'missing' && args.playerIndex === args.index &&
          !target.__tqsCardWireDropperInstalled) {
        target.__tqsCardWireDropperInstalled = true;
        target.__tqsCardWireCapabilityDrops = 0;
        const capability = 'card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode';
        const originalSend = WebSocket.prototype.send;
        WebSocket.prototype.send = function(data: Parameters<WebSocket['send']>[0]) {
          let encoded = typeof data === 'string' ? data : '';
          if (!encoded && data instanceof ArrayBuffer) encoded = new TextDecoder().decode(new Uint8Array(data));
          if (!encoded && ArrayBuffer.isView(data)) {
            encoded = new TextDecoder().decode(new Uint8Array(
              data.buffer as ArrayBuffer, data.byteOffset, data.byteLength));
          }
          if (encoded.includes(capability)) {
            target.__tqsCardWireCapabilityDrops = (target.__tqsCardWireCapabilityDrops ?? 0) + 1;
            return;
          }
          return originalSend.call(this, data);
        };
      }
    }, {
      version: nativeQa && process.env.TQS_LIVE_LEGACY_ONLY !== '1' ? 1 : 0,
      observerMode: i === 2 ? cardWireObserverMode : 'valid',
      playerMode: i < 2 ? cardWirePlayerMode : 'valid',
      playerIndex: cardWirePlayerIndex,
      index: i,
    });
    if (cardWireReplayRequested && i < 2) {
      const replayRouteState: CardWireReplayRouteState = {
        page: p, server: null, lastReply: null, pendingReplay: null, replaySent: false,
        replayRequestIdRewritten: false,
        sendCalls: 0, binaryFrames: 0, replyCandidates: 0,
      };
      cardWireReplayRoutes.push(replayRouteState);
      const readFrameHead = (bytes: Buffer, start: number) => {
        if (start >= bytes.length) return null;
        const initial = bytes[start];
        const major = initial >> 5;
        const additional = initial & 31;
        if (additional < 24) return { major, value: additional, next: start + 1 };
        const width = additional === 24 ? 1 : additional === 25 ? 2 :
          additional === 26 ? 4 : additional === 27 ? 8 : 0;
        if (!width || start + 1 + width > bytes.length) return null;
        let value = 0;
        for (let index = 0; index < width; index++) {
          value = value * 256 + bytes[start + 1 + index];
          if (!Number.isSafeInteger(value)) return null;
        }
        return { major, value, next: start + 1 + width };
      };
      const encodeFrameUnsigned = (value: number) => {
        if (!Number.isSafeInteger(value) || value < 0) return null;
        if (value < 24) return Buffer.from([value]);
        if (value < 0x100) return Buffer.from([0x18, value]);
        if (value < 0x10000) return Buffer.from([0x19, value >> 8, value & 0xff]);
        if (value < 0x100000000) return Buffer.from([0x1a,
          (value >>> 24) & 0xff, (value >>> 16) & 0xff, (value >>> 8) & 0xff, value & 0xff]);
        return null;
      };
      const rewriteReplayRequestId = (frame: Buffer, requestId: number) => {
        const array = readFrameHead(frame, 0);
        const oldId = array && array.major === 4 && (array.value === 4 || array.value === 6)
          ? readFrameHead(frame, array.next) : null;
        const encoded = encodeFrameUnsigned(requestId);
        if (!array || !oldId || !encoded || oldId.major !== 0) return null;
        return Buffer.concat([frame.subarray(0, array.next), encoded, frame.subarray(oldId.next)]);
      };
      await p.routeWebSocket((url) => url.pathname.endsWith('/ws'), (route) => {
        const server = route.connectToServer();
        replayRouteState.server = server;
        route.onMessage((message) => {
          replayRouteState.sendCalls++;
          if (typeof message !== 'string') {
            replayRouteState.binaryFrames++;
            const bytes = Buffer.from(message);
            try {
              const packet = new RawPacketStream().push(bytes).at(0);
              if (packet && packet.command === '' && (packet.type & PacketType.REPLY) !== 0) {
                replayRouteState.replyCandidates++;
                replayRouteState.lastReply = Buffer.from(bytes);
              }
            } catch { /* keep forwarding; the normal browser/native audits own decode errors */ }
          }
          server.send(message);
        });
        server.onMessage((message) => {
          route.send(message);
          if (!replayRouteState.pendingReplay) return;
          let nextRequestId: number | null = null;
          if (typeof message !== 'string') {
            try {
              nextRequestId = new RawPacketStream().push(Buffer.from(message))
                .find((packet) => packet.requestId >= 0 && (packet.type & PacketType.REQUEST) !== 0)?.requestId ?? null;
            } catch { /* leave the pending replay until a complete request frame arrives */ }
          }
          if (nextRequestId === null) return;
          const replay = rewriteReplayRequestId(Buffer.from(replayRouteState.pendingReplay), nextRequestId);
          if (!replay) {
            replayRouteState.pendingReplay = null;
            return;
          }
          replayRouteState.pendingReplay = null;
          replayRouteState.replayRequestIdRewritten = true;
          setTimeout(() => {
            if (!replayRouteState.server) return;
            replayRouteState.server.send(replay);
            replayRouteState.replaySent = true;
          }, 50);
        });
      });
    }
    const loginUrl = new URL(pageUrl);
    loginUrl.searchParams.set('tqs-e2e-preauth', '1');
    await p.goto(loginUrl.toString());
    const legacyUsername = p.getByLabel('Tên tài khoản',{exact:true});
    if (await legacyUsername.count()) {
      await legacyUsername.waitFor({timeout:90000});
      await legacyUsername.fill(account.username);
      await p.getByLabel('Mật khẩu',{exact:true}).fill(account.password);
      await p.getByRole('button',{name:'Vào sảnh',exact:true}).click();
    } else {
      const preauthButton = p.getByRole('button',{name:/^(Tiếp tục với Google|Vào Chiến Trường)$/});
      await preauthButton.waitFor({timeout:90000});
      await preauthButton.click();
    }
    await p.getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor({timeout:60000});
    console.log(`PASS client ${i+1}: distinct account authenticated in real lobby`);
  }
  const roomName=nativeQaRoomName ?? `${candidateId.toUpperCase()} multiplayer ${Date.now()}`;const [a,b]=pages;
  const playerCapacity = testBotAudit ? 4 : selectedScenario?.capacity ?? 2;
  await a.getByLabel('Tên phòng',{exact:true}).fill(roomName);await a.getByLabel('Số người',{exact:true}).selectOption(String(playerCapacity));
  await configureScenarioPool(a);
  await a.getByLabel('Thời gian lượt',{exact:true}).selectOption('60');await a.getByRole('button',{name:'Tạo phòng Quốc Chiến'}).click();
  // A cold native process loads all Lua extensions after the first authenticated
  // lobby connection.  The browser can already show EnterLobby while that
  // bounded startup phase is still running, so allow the room transition to
  // wait for the actual server readiness rather than treating it as a lobby
  // or package failure.
  const roomTransitionTimeout = 90000;
  await a.getByRole('heading',{name:roomName,exact:true}).waitFor({ timeout: roomTransitionTimeout });
  await b.getByRole('button',{name:'Làm mới',exact:true}).click();
  await b.locator('.room-item').filter({hasText:roomName}).getByRole('button',{name:'Vào phòng',exact:true}).click();
  await b.getByRole('heading',{name:roomName,exact:true}).waitFor({ timeout: roomTransitionTimeout });
  if (playerCapacity > 2) {
    for (let n = 2; n < playerCapacity; n++) {
      const expectedPlayers = n + 1;
      const addBot = a.getByRole('button',{name:'+ Thêm bot',exact:true});
      const botDeadline = Date.now() + 90000;
      let nextBotRequest = 0;
      while (Date.now() < botDeadline) {
        const currentPlayers = await a.locator('.player-item:not(.sg-seat-empty)').count();
        if (currentPlayers >= expectedPlayers) break;
        const now = Date.now();
        if (now >= nextBotRequest && await addBot.isEnabled().catch(() => false)) {
          await addBot.click();
          // A cold native process can accept login before its Lua extension
          // load completes. Retry the idempotent seat request only while the
          // expected seat is still absent, with enough spacing to avoid a
          // burst if the first request is merely waiting in native startup.
          nextBotRequest = now + 15000;
        }
        await a.waitForFunction((expected) => document.querySelectorAll('.player-item:not(.sg-seat-empty)').length >= expected,
          expectedPlayers, { timeout: 1000 }).catch(() => undefined);
      }
      assert.ok(await a.locator('.player-item:not(.sg-seat-empty)').count() >= expectedPlayers,
        `Native room did not add bot seat ${expectedPlayers} within the bounded retry window`);
      console.log(`room bot seat reached: ${expectedPlayers}`);
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
  const generalChoiceCounts = await Promise.all(pages.map((page, index) => selectPair(page,
    !nativeQa && selectedScenario && selectedScenario.requiresGeneral !== false && index === scenarioClient ? selectedScenario.general : undefined)));
  for (const p of pages) {
    try {
      await p.locator('.game-board').waitFor({ timeout: cardWireEntropyFailure ? 30000 : 90000 });
    } catch (error) {
      if (!cardWireEntropyFailure || !readNativeEntropyFailure()) throw error;
      break;
    }
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
  if (cardWireEntropyFailure) {
    if (await waitForNativeEntropyFailure(15000)) {
      // The native rejection marker can arrive before the second browser's
      // notification callback has appended its trace. Give both real clients
      // a bounded drain window before evaluating the two-client contract.
      await waitForNativeEntropyNegotiation(5000);
      completeCardWireEntropyProbe();
    }
    throw new Error('native card-wire entropy failure marker did not arrive within the bounded probe window');
  }
  if (cardWirePlayerNegative) {
    cardWirePlayerCapabilityDrops = await pages[cardWirePlayerIndex].evaluate(() =>
      (window as Window & { __tqsCardWireCapabilityDrops?: number }).__tqsCardWireCapabilityDrops ?? 0);
    const negotiatedPackets = traces.flat().filter((packet) =>
      packet.direction === 'incoming' && packet.command === 'CardWireNegotiated').length;
    assert.ok(cardWirePlayerCapabilityDrops > 0,
      'non-negotiating player probe must suppress one capability packet');
    assert.equal(negotiatedPackets, 0,
      'a v1 room with one non-negotiating player must not emit CardWireNegotiated');
    cardWirePlayerRejected = true;
    cardWirePlayerErrorPackets = traces[cardWirePlayerIndex].filter((packet) =>
      packet.direction === 'incoming' && (packet.command === 'ErrorMsg' || packet.command === 'ErrorDlg')).length;
    gameStarted = false;
    finished = true;
    console.log(`PASS native player mismatch: index=${cardWirePlayerIndex}, mode=${cardWirePlayerMode}, capabilityDrops=${cardWirePlayerCapabilityDrops}, negotiatedPackets=0`);
    writeCardWirePlayerEvidence();
    throw new CardWirePlayerProbeComplete();
  }
  if (observerPage) {
    await observerPage.getByRole('button', { name: 'Làm mới', exact: true }).click();
    await observerPage.locator('.room-item').filter({ hasText: roomName })
      .getByRole('button', { name: 'Quan sát', exact: true }).click();
    if (cardWireObserverNegative) {
      // A v1 room must not leak an Observe snapshot to an observer that did
      // not negotiate or presented an invalid marker.  Missing capability is
      // rejected by the Lua v1 audience gate; malformed/wrong-version
      // admission is rejected by native Lobby::joinRoom before room attach.
      const observerDeadline = Date.now() + 15000;
      while (Date.now() < observerDeadline &&
        !traces[2].some((packet) => packet.direction === 'incoming' &&
          (packet.command === 'ErrorMsg' || packet.command === 'Observe'))) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
      cardWireObserverObservePackets = traces[2].filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'Observe').length;
      const errorPackets = traces[2].filter((packet) =>
        packet.direction === 'incoming' && (packet.command === 'ErrorMsg' || packet.command === 'ErrorDlg')).length;
      assert.equal(cardWireObserverObservePackets, 0,
        `observer mismatch mode ${cardWireObserverMode} must not receive an Observe snapshot`);
      assert.equal(await observerPage.locator('.game-board').count(), 0,
        `observer mismatch mode ${cardWireObserverMode} must remain outside the game board`);
      // `missing` is attached by native first and therefore must produce the
      // Lua audience error. Invalid three-element markers are rejected by the
      // native CBOR admission parser before a room error is sent.
      if (cardWireObserverMode === 'missing') assert.ok(errorPackets > 0,
        'missing observer capability must produce a bounded native/Lua rejection');
      cardWireObserverRejected = true;
      console.log(`PASS native observer mismatch: mode=${cardWireObserverMode}, observePackets=0, errorPackets=${errorPackets}`);
      writeCardWireObserverEvidence();
    } else {
      await observerPage.locator('.game-board').waitFor({ timeout: 30000 });
      await observerPage.waitForFunction((expected) =>
        document.querySelectorAll('.board-player').length === expected,
      playerCapacity, { timeout: 30000 });
      assert.ok(nativeDeckPrivacy[2].negotiated && nativeDeckPrivacy[2].commands.Observe > 0,
        'A fresh observer must negotiate and receive an audited native snapshot');
      console.log('PASS fresh native observer: separate account, negotiation and audited Observe snapshot');
      if (observerLeaveRequested) {
        // Keep the observer attached through the draw and controlled reconnect
        // so the native privacy audit can observe the full post-Observe move
        // sequence, including the hidden move-id exposure group. The actual
        // leave probe runs immediately after player recovery, before GameOver.
        console.log('PASS native observer join: observer leave deferred until post-draw/reconnect privacy coverage');
      }
    }
  }
  if (nativeQa && selectedScenario?.skill && !hiddenScenario &&
    !deltaBaweiScenario && !deltaFengshiScenario && !deltaXisheScenario && !deltaZhenteScenario && !deltaHalberdScenario && !deltaSijianScenario) {
    // The QA director binds the actor by allowlist order, while room seats and
    // browser tabs are independent.  Resolve the private owner from the
    // production skill rail before delegating the other seat to Trust.
    const ownerDeadline = Date.now() + 15000;
    let owner = -1;
    const observedSkillCounts: number[] = pages.map(() => 0);
    while (Date.now() < ownerDeadline && owner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const labels = await pages[client].locator('button.sg-skill-button').allTextContents();
        observedSkillCounts[client] = labels.length;
        if (labels.some((label) => selectedScenario.skill!.test(label))) {
          owner = client;
          break;
        }
      }
      if (owner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    assert.ok(owner >= 0,
      `Native QA ${testScenario} did not expose its actor skill on either private skill rail; ` +
      `skillCounts=${JSON.stringify(observedSkillCounts)}`);
    scenarioClient = owner;
    console.log(`Scenario ${testScenario}: native caller skill is on client ${scenarioClient + 1}`);
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
    assert.ok(weiOwner >= 0,
      `Native damage scenario must reveal Quách Gia + Tư Mã Ý on one private client; weiOwnerFound=${weiOwner >= 0}, shuOwnerFound=${shuOwner >= 0}`);
    assert.ok(shuOwner >= 0,
      `Native damage scenario must reveal Triệu Vân + Pháp Chính on one private client; weiOwnerFound=${weiOwner >= 0}, shuOwnerFound=${shuOwner >= 0}`);
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
  if (hiddenEnyuanScenario) {
    const hiddenEnyuanDeadline = Date.now() + 12000;
    let hiddenEnyuanOwner = -1;
    let hiddenEnyuanFallbackOwner = -1;
    while (Date.now() < hiddenEnyuanDeadline && hiddenEnyuanOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenEnyuanFallbackOwner < 0) hiddenEnyuanFallbackOwner = client;
          if (await fake.filter({ hasText: /Ân Oán|恩怨|enyuan|ld__enyuan/i }).count()) {
            hiddenEnyuanOwner = client;
            break;
          }
        }
      }
      if (hiddenEnyuanOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenEnyuanOwner < 0) hiddenEnyuanOwner = hiddenEnyuanFallbackOwner;
    assert.ok(hiddenEnyuanOwner >= 0, 'hidden-enyuan must expose a fake trigger before the TargetConfirmed gate');
    scenarioClient = hiddenEnyuanOwner;
    const hiddenEnyuanFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Ân Oán|恩怨|enyuan|ld__enyuan/i }).first();
    assert.ok(await hiddenEnyuanFake.count(),
      'hidden-enyuan must expose the fake Enyuan trigger before the TargetConfirmed gate');
    console.log('PASS hidden-enyuan pre-gate: native fake Enyuan is visible before the TargetConfirmed gate');
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
  if (hiddenEjueScenario) {
    const hiddenEjueDeadline = Date.now() + 12000;
    let hiddenEjueOwner = -1;
    let hiddenEjueFallbackOwner = -1;
    while (Date.now() < hiddenEjueDeadline && hiddenEjueOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenEjueFallbackOwner < 0) hiddenEjueFallbackOwner = client;
          if (await fake.filter({ hasText: /Ách Tuyệt|扼绝|heg__ejue|ejue/i }).count()) {
            hiddenEjueOwner = client;
            break;
          }
        }
      }
      if (hiddenEjueOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenEjueOwner < 0) hiddenEjueOwner = hiddenEjueFallbackOwner;
    assert.ok(hiddenEjueOwner >= 0, 'hidden-ejue must expose a fake trigger before the DamageCaused gate');
    scenarioClient = hiddenEjueOwner;
    const hiddenEjueFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Ách Tuyệt|扼绝|heg__ejue|ejue/i }).first();
    assert.ok(await hiddenEjueFake.count(),
      'hidden-ejue must expose the fake Ejue trigger before the DamageCaused gate');
    console.log('PASS hidden-ejue pre-gate: native fake-skill dock is visible before the DamageCaused gate');
  }
  if (hiddenDufuScenario) {
    const hiddenDufuDeadline = Date.now() + 12000;
    let hiddenDufuOwner = -1;
    let hiddenDufuFallbackOwner = -1;
    while (Date.now() < hiddenDufuDeadline && hiddenDufuOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenDufuFallbackOwner < 0) hiddenDufuFallbackOwner = client;
          if (await fake.filter({ hasText: /Độc Phu|独夫|heg__dufu|dufu/i }).count()) {
            hiddenDufuOwner = client;
            break;
          }
        }
      }
      if (hiddenDufuOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenDufuOwner < 0) hiddenDufuOwner = hiddenDufuFallbackOwner;
    assert.ok(hiddenDufuOwner >= 0, 'hidden-dufu must expose a fake trigger before the DamageCaused gate');
    scenarioClient = hiddenDufuOwner;
    const hiddenDufuFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Độc Phu|独夫|heg__dufu|dufu/i }).first();
    assert.ok(await hiddenDufuFake.count(),
      'hidden-dufu must expose the fake Dufu trigger before the DamageCaused gate');
    console.log('PASS hidden-dufu pre-gate: native fake-skill dock is visible before the DamageCaused gate');
  }
  if (hiddenJianzhiScenario) {
    const hiddenJianzhiDeadline = Date.now() + 12000;
    let hiddenJianzhiOwner = -1;
    let hiddenJianzhiFallbackOwner = -1;
    while (Date.now() < hiddenJianzhiDeadline && hiddenJianzhiOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenJianzhiFallbackOwner < 0) hiddenJianzhiFallbackOwner = client;
          if (await fake.filter({ hasText: /Gian Chí|奸志|heg__jianzhi|jianzhi/i }).count()) {
            hiddenJianzhiOwner = client;
            break;
          }
        }
      }
      if (hiddenJianzhiOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenJianzhiOwner < 0) hiddenJianzhiOwner = hiddenJianzhiFallbackOwner;
    assert.ok(hiddenJianzhiOwner >= 0, 'hidden-jianzhi must expose a fake trigger before the DamageCaused gate');
    scenarioClient = hiddenJianzhiOwner;
    const hiddenJianzhiFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /Gian Chí|奸志|heg__jianzhi|jianzhi/i }).first();
    assert.ok(await hiddenJianzhiFake.count(),
      'hidden-jianzhi must expose the fake Jianzhi trigger before the DamageCaused gate');
    console.log('PASS hidden-jianzhi pre-gate: native fake-skill dock is visible before the DamageCaused gate');
  }
  if (hiddenZhimanScenario) {
    const hiddenZhimanDeadline = Date.now() + 12000;
    let hiddenZhimanOwner = -1;
    let hiddenZhimanFallbackOwner = -1;
    while (Date.now() < hiddenZhimanDeadline && hiddenZhimanOwner < 0) {
      for (let client = 0; client < pages.length; client++) {
        const fake = pages[client].locator('button.fake-skill-button');
        if (await fake.count()) {
          if (hiddenZhimanFallbackOwner < 0) hiddenZhimanFallbackOwner = client;
          if (await fake.filter({ hasText: /制蛮|Chế Man|zhiman|ld__zhiman/i }).count()) {
            hiddenZhimanOwner = client;
            break;
          }
        }
      }
      if (hiddenZhimanOwner < 0) await new Promise((resolve) => setTimeout(resolve, 100));
    }
    if (hiddenZhimanOwner < 0) hiddenZhimanOwner = hiddenZhimanFallbackOwner;
    assert.ok(hiddenZhimanOwner >= 0, 'hidden-zhiman must expose a fake trigger before the DamageCaused gate');
    scenarioClient = hiddenZhimanOwner;
    const hiddenZhimanFake = pages[scenarioClient].locator('button.fake-skill-button')
      .filter({ hasText: /制蛮|Chế Man|zhiman|ld__zhiman/i }).first();
    assert.ok(await hiddenZhimanFake.count(),
      'hidden-zhiman must expose the fake Zhiman trigger before the DamageCaused gate');
    console.log('PASS hidden-zhiman pre-gate: native fake-skill dock is visible before the DamageCaused gate');
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
  if (hiddenJizhiScenario || hiddenMingshiScenario || hiddenQianxunScenario || hiddenKongchengScenario || hiddenWeimuScenario || hiddenXiaojiScenario || hiddenDuanchangScenario || hiddenJilixScenario) {
    const label = hiddenJizhiScenario ? /Tập Trí|集智|jizhi/i :
      hiddenMingshiScenario ? /Danh Sĩ|名士|mingshi/i :
      hiddenQianxunScenario ? /Khiêm Tốn|谦逊|qianxun/i :
      hiddenKongchengScenario ? /Không Thành|空城|kongcheng/i :
      hiddenWeimuScenario ? /帷幕|tấm màn|Vi Mộ|weimu/i :
      hiddenXiaojiScenario ? /枭姬|Kiêu Cơ|xiaoji/i :
      hiddenDuanchangScenario ? /断肠|Đoạn Trường|duanchang/i : /寄篱|Ký Ly|jilix/i;
    const name = hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' :
      hiddenQianxunScenario ? 'hidden-qianxun' : hiddenKongchengScenario ? 'hidden-kongcheng' :
      hiddenWeimuScenario ? 'hidden-weimu' : hiddenXiaojiScenario ? 'hidden-xiaoji' :
      hiddenDuanchangScenario ? 'hidden-duanchang' : 'hidden-jilix';
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
    // Native QA binds the actor to the first allowlisted account, but room
    // seat/order assignment can place that account on either browser tab.
    // Discover the private regular projection instead of assuming page 0.
    const label = /Chế Hành|制衡|zhiheng/i;
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
      'hidden-active must project native fake active Chế Hành as a regular skill before PlayCard');
    scenarioClient = owner;
    console.log(`PASS hidden-active pre-request: native active Chế Hành is projected while both generals remain hidden on client ${owner + 1}`);
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
  if ((testBotAudit || damageExchangeScenario || hiddenScenario || deltaChujueScenario || deltaZhenteScenario || deltaHalberdScenario || deltaSijianScenario || deltaBaweiScenario || deltaFengshiScenario || deltaXisheScenario || deltaLordWenjiScenario || deltaTieqiScenario) && !boundedAiTraceScenario)
    await Promise.all(pages.map(installPublicBotAudit));
  if (selectedScenario && !hiddenScenario)
    console.log(`Scenario ${testScenario}: general-slot selection completed`);
  console.log('PASS both clients: room/join/ready/StartGame/native general pairs; no opponent card IDs in board DOM');
  if (testManual) {
    let actor = pages[scenarioClient];
    let actorTrace = traces[scenarioClient];
    const botPage = pages[1 - scenarioClient];
    const rescueScenario = testScenario === 'rescue-normal' || testScenario === 'rescue-battle';
    if (!damageExchangeScenario && !hiddenScenario && !rescueScenario && !deltaXiongsuanScenario && !deltaWenjiScenario && !deltaLordWenjiScenario && !deltaQianceScenario && !deltaJianchuScenario && !deltaTieqiScenario && !deltaChujueScenario && !deltaZhenteScenario && !deltaHalberdScenario && !deltaSijianScenario && !deltaBaweiScenario && !deltaFengshiScenario && !deltaXisheScenario) {
      await clickTrustAction(botPage);
    }
    const deadline=Date.now()+manualDeadlineMs;
    let printedScenarioSkills = false;
    let lastQianceRequestLog = '';
    const selectActiveClient = async () => {
      if (nativeQa) {
        const nativeCommands = new Set(['PlayCard', 'AskForChoices', 'AskForSkillInvoke', 'AskForUseActiveSkill',
          'AskForUseCard', 'AskForResponseCard', 'AskForCardChosen', 'AskForPoxi', 'AskForCardsAndChoice',
          'AskForArrangeCards', 'CustomDialog']);
        if (testScenario === 'card-chosen') {
          const scenarioRequest = pendingRequest(scenarioClient);
          if (scenarioRequest && nativeCommands.has(scenarioRequest.command ?? '')) return scenarioClient;
        }
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
      (deltaXiongsuanScenario && scenarioActiveSkillReply && scenarioXiongsuanChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaWenjiScenario && scenarioWenjiPlayerReply && scenarioWenjiCardReply && scenarioWenjiUseReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaLordWenjiScenario && scenarioLordWenjiGateReply && scenarioLordWenjiPlayerReply &&
        scenarioLordWenjiCardReply && scenarioLordWenjiUseReply && scenarioLordWenjiReturnReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaQianceScenario && scenarioQianceCardReply && scenarioQianceInvokeReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaJianchuScenario && scenarioJianchuGateReply && scenarioJianchuUseReply &&
        scenarioJianchuInvokeReply && scenarioJianchuCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaTieqiScenario && scenarioTieqiGateReply && scenarioTieqiGeneralReply &&
        scenarioTieqiUseReply && scenarioTieqiDiscardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaChujueScenario && scenarioChujueGateReply && scenarioChujueDeadFactionUseReply &&
        scenarioChujueControlFactionUseReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaZhenteScenario && scenarioZhenteGateReply && scenarioZhenteUseReply &&
        scenarioZhenteInvokeReply && scenarioZhenteChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaHalberdScenario && scenarioHalberdGateReply && scenarioHalberdUseReply &&
        scenarioHalberdExtraTargetReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaSijianScenario && scenarioSijianGateReply && scenarioSijianTargetReply && scenarioSijianCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaBaweiScenario && scenarioBaweiGateReply && scenarioBaweiDamagedUseReply &&
        scenarioBaweiControlUseReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaFengshiScenario && scenarioFengshiGateReply && scenarioFengshiSlashReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (deltaXisheScenario && scenarioXisheGateReply && scenarioXisheWeaponReply &&
        scenarioXisheCancelReply && scenarioXisheArmorReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
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
      (hiddenEnyuanScenario && hiddenEnyuanGateReply && hiddenEnyuanCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenKuangguScenario && hiddenKuangguGateReply && hiddenKuangguDamageReply && hiddenKuangguChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenLiegongScenario && hiddenLiegongGateReply && hiddenLiegongDamageReply && hiddenLiegongChoiceReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJueqingScenario && hiddenJueqingGateReply && hiddenJueqingDamageReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenEjueScenario && hiddenEjueGateReply && hiddenEjueDamageReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenDufuScenario && hiddenDufuGateReply && hiddenDufuDamageReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJianzhiScenario && hiddenJianzhiGateReply && hiddenJianzhiDamageReply && hiddenJianzhiInvoked &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenZhimanScenario && hiddenZhimanGateReply && hiddenZhimanDamageReply && hiddenZhimanInvoked && hiddenZhimanCardReply &&
        traces.some((trace) => trace.some((packet) => packet.direction === 'incoming' && packet.command === 'GameOver'))) ||
      (hiddenJilixScenario && hiddenJilixGateReply && hiddenJilixCardReply && hiddenJilixChoiceReply &&
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
      if (!nativeQa || (!hiddenScenario && !deltaLordWenjiScenario && !deltaQianceScenario && !deltaJianchuScenario && !deltaTieqiScenario && !deltaChujueScenario && !deltaZhenteScenario && !deltaHalberdScenario && !deltaSijianScenario && !deltaBaweiScenario && !deltaFengshiScenario && !deltaXisheScenario) || nativeQaGateSeen) return;
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
    while(Date.now()<deadline && (damageExchangeScenario || hiddenScenario || deltaXiongsuanScenario || deltaWenjiScenario || deltaLordWenjiScenario || deltaQianceScenario || deltaJianchuScenario || deltaTieqiScenario || deltaChujueScenario || deltaZhenteScenario || deltaHalberdScenario || deltaSijianScenario || deltaBaweiScenario || deltaFengshiScenario || deltaXisheScenario
      ? !scenarioDone()
      : rescueOrFoundingScenario ? !scenarioDone() : (!manualCardReply || !scenarioDone()))) {
      failIfNativeQaGateMissing();
      const activeClient = await selectActiveClient();
      actor = pages[activeClient];
      actorTrace = traces[activeClient];
      await observeBattleRoyal(actor);
      const latest=actorTrace.filter(t=>t.direction==='incoming' && (t.type & 0x100)!==0).at(-1);
      if (deltaQianceScenario && latest) {
        const requestLogKey = `${activeClient}:${latest.command}:${latest.requestId}`;
        if (requestLogKey !== lastQianceRequestLog) {
          lastQianceRequestLog = requestLogKey;
          console.log(`Scenario delta-qiance request: client=${activeClient} command=${latest.command} requestId=${latest.requestId}`);
        }
      }
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
          const hiddenJilixChoice = hiddenJilixScenario &&
            /jilix|寄篱|Ký Ly|ld__jilix|移除此武将牌|loại bỏ.*tướng|xóa.*tướng|remove.*(?:general|this)/i.test(choiceText);
          const deltaZhenteChoice = deltaZhenteScenario &&
            /ty_heg__zhente_negate|贞特|zhente|vô hiệu|无效|negate/i.test(choiceText);
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
            : hiddenJilixChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /ld__jilix_remove|移除此武将牌|loại bỏ.*tướng|xóa.*tướng|remove.*(?:general|this)/i }).first()
            : deltaZhenteChoice
            ? choices.locator('button.gameplay-choice:enabled')
              .filter({ hasText: /ty_heg__zhente_negate|vô hiệu|无效|negate|对.*无效/i }).first()
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
          if (hiddenJilixChoice) assert.ok(await preferred.count(),
            'hidden-jilix must expose the native remove-general choice');
          if (deltaZhenteChoice) assert.ok(await preferred.count(),
            'delta-zhente must expose the native target-negate choice');
          let submitted = false;
          const confirm=choices.getByRole('button',{name:'Xác nhận lựa chọn',exact:true});
          if(await option.count()) {
            // ChoicePanel refreshes its countdown every 250ms.  Playwright's
            // visibility/stability gate can therefore observe the button,
            // lose the portal node during the timer render, and wait until
            // the native request expires without ever dispatching the click.
            // Keep the enabled check, then dispatch the normal DOM click on
            // the current React node so the production handler still owns
            // validation and the exact reply bytes.
            const clicked = await option.evaluate((element) => {
              if (!(element instanceof HTMLButtonElement) || element.disabled) return false;
              element.click();
              return true;
            }, undefined, { timeout: 900 }).catch((error: unknown) => {
              // The countdown can replace the portal node between count() and
              // evaluate(). Retry the live locator on the next runner tick.
              if (error instanceof Error && /detached|not attached|resolved to|timeout/i.test(error.message)) return false;
              throw error;
            });
            if (!clicked) {
              await new Promise((resolve) => setTimeout(resolve, 100));
              continue;
            }
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
            if (hiddenJilixChoice && replied) hiddenJilixChoiceReply = true;
            if (deltaZhenteChoice && replied) scenarioZhenteChoiceReply = true;
            if (deltaXiongsuanScenario && replied) scenarioXiongsuanChoiceReply = true;
            if (replied) scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
            detail: testScenario === 'founding' || /lập quốc|quốc hiệu|founding|wild-choose|建国|Dã tâm/i.test(choiceText) ? 'founding-kingdom' :
                hiddenJianxiongChoice ? 'hidden-jianxiong-obtain' :
                hiddenFanjianChoice ? 'hidden-fanjian-lose-hp' :
                hiddenTianxiangChoice ? 'hidden-tianxiang-lose-hp-return-card' :
                hiddenDuanchangChoice ? 'hidden-duanchang-lose-main-skills' :
                hiddenKuangguChoice ? 'hidden-kuanggu-draw1' :
                hiddenLiegongChoice ? 'hidden-liegong-damage-plus-one' :
                hiddenJilixChoice ? 'hidden-jilix-remove-general' :
                deltaZhenteChoice ? 'delta-zhente-negate-choice' :
                deltaXiongsuanScenario ? 'delta-xiongsuan-reset-choice' :
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
        const isHiddenRevealGate = hiddenRevealScenario && !hiddenRevealReply &&
          /TQS QA|Mở tướng|reveal_skill&|hidden_reveal_gate/i.test(invokeText);
        const isHiddenDuoshiInvoke: boolean = hiddenRevealScenario && !isHiddenRevealGate &&
          (/Độ Thế|度势|duoshi|đo tiềm năng/i.test(invokeText) ||
            // The native source skill uses the production AskForSkillInvoke
            // path, but this build's localized prompt can omit the skill
            // label. Once the hidden reveal active request has completed,
            // the only optional trigger in this candidate scenario is the
            // real Lục Tốn Duoshi cost; keep the fallback scoped to that
            // state instead of matching arbitrary optional skills.
            (hiddenRevealGateReply && hiddenRevealReply && !hiddenDuoshiInvoked));
        if (hiddenRevealScenario) {
          console.log(`hidden-reveal invoke request client=${activeClient + 1} request=${latest.requestId} ` +
            `gateReply=${hiddenRevealGateReply} revealReply=${hiddenRevealReply} duoshiInvoked=${hiddenDuoshiInvoked} ` +
            `gateMatch=${isHiddenRevealGate} duoshiMatch=${isHiddenDuoshiInvoke}`);
        }
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
        const isHiddenEnyuanGate = hiddenEnyuanScenario && /TQS QA|prelight|tqs_qa_hidden_enyuan_gate/i.test(invokeText);
        const isHiddenFuyinGate = hiddenFuyinScenario && /TQS QA|prelight|tqs_qa_hidden_fuyin_gate/i.test(invokeText);
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
        const isHiddenEjueGate = hiddenEjueScenario && /TQS QA|prelight|tqs_qa_hidden_ejue_gate/i.test(invokeText);
        const isHiddenDufuGate = hiddenDufuScenario && /TQS QA|prelight|tqs_qa_hidden_dufu_gate/i.test(invokeText);
        const isHiddenJianzhiGate = hiddenJianzhiScenario && /TQS QA|prelight|tqs_qa_hidden_jianzhi_gate/i.test(invokeText);
        const isHiddenZhimanGate = hiddenZhimanScenario && /TQS QA|prelight|tqs_qa_hidden_zhiman_gate/i.test(invokeText);
        const isHiddenJilixGate = hiddenJilixScenario && /TQS QA|prelight|tqs_qa_hidden_jilix_gate/i.test(invokeText);
        const isDeltaXiongsuanGate = deltaXiongsuanScenario && /TQS QA|xiongsuan|凶算|Hung\s*Toán/i.test(invokeText);
        const isDeltaWenjiGate = deltaWenjiScenario && /TQS QA|wenji|问计|Vấn\s*Kế/i.test(invokeText);
        const isDeltaLordWenjiGate = deltaLordWenjiScenario && /tqs_qa_delta_lord_wenji_gate|TQS QA/i.test(invokeText);
        const isDeltaQianceGate = deltaQianceScenario && /TQS QA|tqs_qa_delta_qiance_gate/i.test(invokeText);
        const isDeltaJianchuGate = deltaJianchuScenario && /TQS QA|tqs_qa_delta_jianchu_gate/i.test(invokeText);
        const isDeltaTieqiGate = deltaTieqiScenario && /TQS QA|tqs_qa_delta_tieqi_gate/i.test(invokeText);
        const isDeltaChujueGate = deltaChujueScenario && /TQS QA|tqs_qa_delta_chujue_gate/i.test(invokeText);
        const isDeltaZhenteGate = deltaZhenteScenario && /TQS QA|tqs_qa_delta_zhente_gate/i.test(invokeText);
        const isDeltaHalberdGate = deltaHalberdScenario && /TQS QA|tqs_qa_delta_halberd_gate/i.test(invokeText);
        const isDeltaSijianGate = deltaSijianScenario && /TQS QA|tqs_qa_delta_sijian_gate/i.test(invokeText);
        const isDeltaBaweiGate = deltaBaweiScenario && /tqs_qa_delta_bawei_gate|TQS QA/i.test(invokeText);
        const isDeltaFengshiGate = deltaFengshiScenario && /tqs_qa_delta_fengshi_gate|TQS QA/i.test(invokeText);
        const isDeltaXisheGate = deltaXisheScenario && /tqs_qa_delta_xishe_gate|TQS QA/i.test(invokeText);
        if (isDeltaBaweiGate || isDeltaFengshiGate || isDeltaXisheGate || isDeltaTieqiGate) {
          // The native director reveals these real skills only after the
          // readiness reply. Resolve the actor from that server request.
          scenarioClient = activeClient;
        }
        const isHiddenYijiInvoke = (hiddenYijiScenario || hiddenRehideYijiScenario) && !isHiddenGate && /Di Kế|遗计|yiji|hs__yiji/i.test(invokeText);
        const isHiddenJianxiongInvoke = hiddenJianxiongScenario && !isHiddenJianxiongGate && /Gian Hùng|奸雄|jianxiong|hs__jianxiong/i.test(invokeText);
        const isHiddenJianzhiInvoke = hiddenJianzhiScenario && !isHiddenJianzhiGate && /Gian Chí|奸志|jianzhi|heg__jianzhi/i.test(invokeText);
        const isHiddenZhimanInvoke = hiddenZhimanScenario && !isHiddenZhimanGate && /Chế Man|制蛮|zhiman|ld__zhiman/i.test(invokeText);
        const isHiddenLuoshenInvoke = hiddenLuoshenScenario && !isHiddenLuoshenGate && /洛神|Lạc Thần|luoshen|hs__luoshen/i.test(invokeText);
        const isHiddenJizhiInvoke = hiddenJizhiScenario && !isHiddenJizhiGate && /Tập Trí|集智|jizhi|hs__jizhi/i.test(invokeText);
        const isHiddenGuanxingInvoke = hiddenGuanxingScenario && !isHiddenGuanxingGate && /Quan Tinh|观星|guanxing|hs__guanxing/i.test(invokeText);
        const isHiddenTianxiangInvoke = hiddenTianxiangScenario && !isHiddenTianxiangGate && /Thiên Hương|天香|tianxiang|hs__tianxiang/i.test(invokeText);
        const isDeltaQianceInvoke = deltaQianceScenario && !isDeltaQianceGate && /谦策|Khiêm\s*Sách|qiance|ld__qiance/i.test(invokeText);
        const isDeltaJianchuInvoke = deltaJianchuScenario && !isDeltaJianchuGate && isCardChosenInvoke;
        const isDeltaHalberdInvoke = deltaHalberdScenario && /方天画戟|halberd|sa__halberd/i.test(invokeText);
        const isDeltaZhenteInvoke = deltaZhenteScenario && !isDeltaZhenteGate && /贞特|Trinh\s*Đặc|zhente|ty_heg__zhente/i.test(invokeText);
        if (isHiddenGate || isHiddenJianxiongGate || isHiddenFankuiGate || isHiddenRevealGate || isHiddenActiveGate || isHiddenFanjianGate || isHiddenViewAsGate || isHiddenDualGate || isHiddenLuoshenGate || isHiddenTianduGate || isHiddenJizhiGate || isHiddenMingshiGate || isHiddenGongqingGate || isHiddenEnyuanGate || isHiddenFuyinGate || isHiddenQianxunGate || isHiddenKongchengGate || isHiddenWeimuGate || isHiddenXiaojiGate || isHiddenGuanxingGate || isHiddenYingziGate || isHiddenTianxiangGate || isHiddenDuanchangGate || isHiddenLiegongGate || isHiddenKuangguGate || isHiddenJueqingGate || isHiddenEjueGate || isHiddenDufuGate || isHiddenJianzhiGate || isHiddenZhimanGate || isHiddenJilixGate || isDeltaXiongsuanGate || isDeltaWenjiGate || isDeltaLordWenjiGate || isDeltaQianceGate || isDeltaJianchuGate || isDeltaTieqiGate || isDeltaChujueGate || isDeltaZhenteGate || isDeltaHalberdGate || isDeltaSijianGate || isDeltaBaweiGate || isDeltaFengshiGate || isDeltaXisheGate) {
          nativeQaGateSeen = true;
          nativeQaGateCommand = latest.command;
        }
        if (isDeltaZhenteGate || isDeltaHalberdGate) {
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
        if (isHiddenEnyuanGate) {
          const fakeEnyuan = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Ân Oán|恩怨|enyuan|ld__enyuan/i }).first();
          await fakeEnyuan.waitFor({ timeout: 10000 });
          if (await fakeEnyuan.getAttribute('aria-pressed') !== 'true') await fakeEnyuan.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenFuyinGate) {
          const fakeFuyin = actor.locator('button.fake-skill-button')
            .filter({ hasText: /父荫|Phụ Âm|bóng mát của cha|fuyin/i }).first();
          await fakeFuyin.waitFor({ timeout: 10000 });
          if (await fakeFuyin.getAttribute('aria-pressed') !== 'true') await fakeFuyin.click();
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
        if (isHiddenEjueGate) {
          const fakeEjue = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Ách Tuyệt|扼绝|heg__ejue|ejue/i }).first();
          await fakeEjue.waitFor({ timeout: 10000 });
          if (await fakeEjue.getAttribute('aria-pressed') !== 'true') await fakeEjue.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenDufuGate) {
          const fakeDufu = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Độc Phu|独夫|heg__dufu|dufu/i }).first();
          await fakeDufu.waitFor({ timeout: 10000 });
          if (await fakeDufu.getAttribute('aria-pressed') !== 'true') await fakeDufu.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenJianzhiGate) {
          const fakeJianzhi = actor.locator('button.fake-skill-button')
            .filter({ hasText: /Gian Chí|奸志|heg__jianzhi|jianzhi/i }).first();
          await fakeJianzhi.waitFor({ timeout: 10000 });
          if (await fakeJianzhi.getAttribute('aria-pressed') !== 'true') await fakeJianzhi.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenZhimanGate) {
          const fakeZhiman = actor.locator('button.fake-skill-button')
            .filter({ hasText: /制蛮|Chế Man|zhiman|ld__zhiman/i }).first();
          await fakeZhiman.waitFor({ timeout: 10000 });
          if (await fakeZhiman.getAttribute('aria-pressed') !== 'true') await fakeZhiman.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        if (isHiddenJilixGate) {
          const fakeJilix = actor.locator('button.fake-skill-button')
            .filter({ hasText: /寄篱|Ký Ly|jilix|ld__jilix/i }).first();
          await fakeJilix.waitFor({ timeout: 10000 });
          if (await fakeJilix.getAttribute('aria-pressed') !== 'true') await fakeJilix.click();
          await actor.waitForFunction(() => document.querySelector('button.fake-skill-button[aria-pressed="true"]') !== null,
            null, { timeout: 10000 });
        }
        // A manual run may encounter unrelated optional skills while the
        // target prompt is still pending. Only invoke the requested caller
        // skill; cancel everything else so it cannot starve a native choice.
        const shouldInvoke: boolean = isHiddenGate || isHiddenJianxiongGate || isHiddenFankuiGate || isHiddenRevealGate || isHiddenDuoshiInvoke || isHiddenActiveGate || isHiddenFanjianGate || isHiddenViewAsGate || isHiddenDualGate || isHiddenLuoshenGate || isHiddenTianduGate || isHiddenJizhiGate || isHiddenMingshiGate || isHiddenGongqingGate || isHiddenEnyuanGate || isHiddenFuyinGate || isHiddenQianxunGate || isHiddenKongchengGate || isHiddenWeimuGate || isHiddenXiaojiGate || isHiddenGuanxingGate || isHiddenYingziGate || isHiddenTianxiangGate || isHiddenDuanchangGate || isHiddenLiegongGate || isHiddenKuangguGate || isHiddenJueqingGate || isHiddenEjueGate || isHiddenDufuGate || isHiddenJianzhiGate || isHiddenZhimanGate || isHiddenJilixGate || isDeltaXiongsuanGate || isDeltaWenjiGate || isDeltaLordWenjiGate || isDeltaQianceGate || isDeltaJianchuGate || isDeltaChujueGate || isDeltaZhenteGate || isDeltaBaweiGate || isDeltaFengshiGate || isDeltaXisheGate
          ? true
          : isHiddenYijiInvoke
          ? hiddenRehideYijiScenario || hiddenYijiMode === 'positive'
          : isHiddenJianxiongInvoke
          ? true
          : isHiddenJianzhiInvoke
          ? true
          : isHiddenZhimanInvoke
          ? true
          : isHiddenLuoshenInvoke
          ? true
          : isHiddenJizhiInvoke
          ? true
          : isHiddenGuanxingInvoke
          ? true
          : isHiddenTianxiangInvoke
          ? true
          : isDeltaJianchuInvoke
          ? true
          : isDeltaZhenteInvoke
          ? true
          : isDeltaTieqiGate
          ? true
          : testScenario === 'card-chosen'
          ? isCardChosenInvoke
          : isScenarioSkillInvoke;
        if (deltaXisheScenario) {
          console.log(`delta-xishe invoke request gate=${isDeltaXisheGate} skill=${isScenarioSkillInvoke} invoke=${shouldInvoke}`);
        }
        const choice = shouldInvoke
          ? actor.locator('.request-panel').getByRole('button', { name: 'Kích hoạt', exact: true })
          : actor.locator('.request-panel').getByRole('button', { name: /^(Bỏ qua|Hủy)$/ });
        if(await choice.count() && await choice.isEnabled())await choice.click();
        const replied = await waitForReply(activeClient, latest.requestId);
        if ((hiddenYijiScenario || hiddenRehideYijiScenario) && isHiddenGate && replied) hiddenGateReply = true;
        if (hiddenJianxiongScenario && isHiddenJianxiongGate && replied) hiddenJianxiongGateReply = true;
        if (hiddenFankuiScenario && isHiddenFankuiGate && replied) hiddenFankuiGateReply = true;
        if (hiddenRevealScenario && isHiddenRevealGate && replied) hiddenRevealGateReply = true;
        if (hiddenRevealScenario && isHiddenDuoshiInvoke && replied) hiddenDuoshiInvoked = shouldInvoke;
        if (hiddenActiveScenario && isHiddenActiveGate && replied) hiddenActiveGateReply = true;
        if (hiddenFanjianScenario && isHiddenFanjianGate && replied) hiddenFanjianGateReply = true;
        if (hiddenViewAsScenario && isHiddenViewAsGate && replied) hiddenViewAsGateReply = true;
        if (hiddenDualScenario && isHiddenDualGate && replied) hiddenDualGateReply = true;
        if (hiddenLuoshenScenario && isHiddenLuoshenGate && replied) hiddenLuoshenGateReply = true;
        if (hiddenTianduScenario && isHiddenTianduGate && replied) hiddenTianduGateReply = true;
        if (hiddenJizhiScenario && isHiddenJizhiGate && replied) hiddenJizhiGateReply = true;
        if (hiddenMingshiScenario && isHiddenMingshiGate && replied) hiddenMingshiGateReply = true;
        if (hiddenGongqingScenario && isHiddenGongqingGate && replied) hiddenGongqingGateReply = true;
        if (hiddenEnyuanScenario && isHiddenEnyuanGate && replied) hiddenEnyuanGateReply = true;
        if (hiddenFuyinScenario && isHiddenFuyinGate && replied) hiddenFuyinGateReply = true;
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
        if (hiddenEjueScenario && isHiddenEjueGate && replied) hiddenEjueGateReply = true;
        if (hiddenDufuScenario && isHiddenDufuGate && replied) hiddenDufuGateReply = true;
        if (hiddenJianzhiScenario && isHiddenJianzhiGate && replied) hiddenJianzhiGateReply = true;
        if (hiddenZhimanScenario && isHiddenZhimanGate && replied) hiddenZhimanGateReply = true;
        if (hiddenJilixScenario && isHiddenJilixGate && replied) hiddenJilixGateReply = true;
        if (deltaJianchuScenario && isDeltaJianchuGate && replied) scenarioJianchuGateReply = true;
        if (deltaTieqiScenario && isDeltaTieqiGate && replied) scenarioTieqiGateReply = true;
        if (deltaChujueScenario && isDeltaChujueGate && replied) scenarioChujueGateReply = true;
        if (deltaZhenteScenario && isDeltaZhenteGate && replied) scenarioZhenteGateReply = true;
        if (deltaHalberdScenario && isDeltaHalberdGate && replied) scenarioHalberdGateReply = true;
        if (deltaSijianScenario && isDeltaSijianGate && replied) scenarioSijianGateReply = true;
        if (deltaBaweiScenario && isDeltaBaweiGate && replied) scenarioBaweiGateReply = true;
        if (deltaFengshiScenario && isDeltaFengshiGate && replied) scenarioFengshiGateReply = true;
        if (deltaXisheScenario && isDeltaXisheGate && replied) scenarioXisheGateReply = true;
        if (deltaLordWenjiScenario && isDeltaLordWenjiGate && replied) scenarioLordWenjiGateReply = true;
        if ((hiddenYijiScenario || hiddenRehideYijiScenario) && isHiddenYijiInvoke && replied) {
          hiddenYijiAsked = true;
          hiddenYijiInvoked = shouldInvoke;
        }
        if (hiddenJianxiongScenario && isHiddenJianxiongInvoke && replied) hiddenJianxiongInvoked = shouldInvoke;
        if (hiddenJianzhiScenario && isHiddenJianzhiInvoke && replied) hiddenJianzhiInvoked = shouldInvoke;
        if (hiddenZhimanScenario && isHiddenZhimanInvoke && replied) hiddenZhimanInvoked = shouldInvoke;
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
        if (deltaQianceScenario && isDeltaQianceInvoke && replied) scenarioQianceInvokeReply = shouldInvoke;
        if (deltaJianchuScenario && isDeltaJianchuInvoke && replied) scenarioJianchuInvokeReply = shouldInvoke;
        if (deltaZhenteScenario && isDeltaZhenteInvoke && replied) scenarioZhenteInvokeReply = shouldInvoke;
        if (deltaHalberdScenario && isDeltaHalberdInvoke && replied) scenarioHalberdExtraTargetReply = shouldInvoke;
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: isHiddenRevealGate ? 'hidden-reveal-readiness-gate' :
            isHiddenDuoshiInvoke ? 'invoke-hidden-duoshi' :
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
            isHiddenEnyuanGate ? 'hidden-enyuan-readiness-gate' :
            isHiddenQianxunGate ? 'hidden-qianxun-readiness-gate' :
            isHiddenKongchengGate ? 'hidden-kongcheng-readiness-gate' :
            isHiddenWeimuGate ? 'hidden-weimu-readiness-gate' :
            isHiddenXiaojiGate ? 'hidden-xiaoji-readiness-gate' :
            isHiddenYingziGate ? 'hidden-yingzi-readiness-gate' :
            isHiddenTianxiangGate ? 'hidden-tianxiang-readiness-gate' :
            isHiddenLiegongGate ? 'hidden-liegong-readiness-gate' :
            isHiddenKuangguGate ? 'hidden-kuanggu-readiness-gate' :
            isHiddenJueqingGate ? 'hidden-jueqing-readiness-gate' :
            isHiddenDufuGate ? 'hidden-dufu-readiness-gate' :
            isHiddenJianzhiGate ? 'hidden-jianzhi-readiness-gate' :
            isHiddenZhimanGate ? 'hidden-zhiman-readiness-gate' :
            isDeltaWenjiGate ? 'delta-wenji-readiness-gate' :
            isDeltaLordWenjiGate ? 'delta-lord-wenji-readiness-gate' :
            isDeltaQianceGate ? 'delta-qiance-readiness-gate' :
            isDeltaQianceInvoke ? 'invoke-delta-qiance' :
            isDeltaJianchuGate ? 'delta-jianchu-readiness-gate' :
            isDeltaTieqiGate ? 'delta-tieqi-readiness-gate' :
            isDeltaChujueGate ? 'delta-chujue-readiness-gate' :
            isDeltaZhenteGate ? 'delta-zhente-readiness-gate' :
            isDeltaHalberdGate ? 'delta-halberd-readiness-gate' :
            isDeltaSijianGate ? 'delta-sijian-readiness-gate' :
            isDeltaBaweiGate ? 'delta-bawei-readiness-gate' :
            isDeltaFengshiGate ? 'delta-fengshi-readiness-gate' :
            isDeltaXisheGate ? 'delta-xishe-readiness-gate' :
            isDeltaJianchuInvoke ? 'invoke-delta-jianchu' :
            isHiddenJianxiongGate ? 'hidden-jianxiong-readiness-gate' :
            isHiddenJizhiInvoke ? 'invoke-hidden-jizhi' :
            isHiddenJianxiongInvoke ? 'invoke-hidden-jianxiong' :
            isHiddenJianzhiInvoke ? 'invoke-hidden-jianzhi' :
            isHiddenZhimanInvoke ? 'invoke-hidden-zhiman' :
            isHiddenLuoshenInvoke ? 'invoke-hidden-luoshen' :
            isHiddenTianxiangInvoke ? 'invoke-hidden-tianxiang' :
            shouldInvoke ? (isCardChosenInvoke ? 'invoke-jianchu' : 'invoke-scenario-skill') : 'cancel-other-skill'});
      } else if(latest?.command==='AskForUseActiveSkill') {
        const activePrompt = await actor.getByRole('region', { name: 'Điều khiển lượt chơi' }).innerText().catch(() => '');
        if (testScenario === 'card-chosen' && activeClient === scenarioClient && !scenarioCardChosenHidden) {
          // The native adapter can expose Jianchu's askToUseRealCard path as
          // AskForUseActiveSkill instead of AskForSkillInvoke.  It is still
          // the real production hand/target request; cancelling it here
          // prevents the server from reaching the hidden AskForCardChosen
          // source-card request that this scenario is meant to verify.
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          if (await slash.count()) {
            await slash.click();
            await chooseTargetIfNeeded(actor);
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            await confirm.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await confirm.isEnabled(),
              'card-chosen AskForUseActiveSkill must enable Slash/target confirmation');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'card-chosen-jianchu-slash-active-skill' });
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
        }
        if (deltaSijianScenario) {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          if (!scenarioSijianGateReply) {
            const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
            if (await cancel.count() && await cancel.isEnabled()) await cancel.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-sijian-close-pre-gate-active-skill' });
            continue;
          }
          if (!scenarioSijianTargetReply) {
            await chooseTargetIfNeeded(actor);
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            await confirm.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await confirm.isEnabled(), 'delta-sijian target confirmation must be enabled');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) scenarioSijianTargetReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-sijian-choose-target' });
            continue;
          }
          const replied = await completeActiveSkill(actor, activeClient, latest.requestId, null);
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: replied, detail: 'delta-sijian-close-unrelated-active-skill' });
          continue;
        }
        if (deltaHalberdScenario) {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          if (!scenarioHalberdGateReply) {
            const replied = await completeActiveSkill(actor, activeClient, latest.requestId, null);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-halberd-close-unrelated-active-skill' });
            continue;
          }
          if (!scenarioHalberdUseReply) {
            const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
              .filter({ hasText: /Sát|Slash|杀/i }).first();
            await slash.waitFor({ state: 'visible', timeout: 10000 });
            await slash.click();
            const firstTarget = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
            await firstTarget.waitFor({ state: 'visible', timeout: 10000 });
            if (await firstTarget.getAttribute('aria-pressed') !== 'true') await firstTarget.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            await confirm.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await confirm.isEnabled(), 'delta-halberd first Slash target confirmation must be enabled');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) scenarioHalberdUseReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-halberd-first-slash-semantic-active-skill' });
            continue;
          }
          const extraTargets = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          assert.equal(await extraTargets.count(), 1,
            'delta-halberd must expose exactly one legal extra target from a distinct kingdom');
          if (await extraTargets.first().getAttribute('aria-pressed') !== 'true') await extraTargets.first().click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-halberd extra-target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioHalberdExtraTargetReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: replied, detail: 'delta-halberd-extra-target-semantic-active-skill' });
          continue;
        }
        if (deltaZhenteScenario) {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          if (!scenarioZhenteGateReply || scenarioZhenteUseReply ||
              !/delta-zhente|dùng Sát đen|kiểm tra 贞特|ty_heg__zhente/i.test(activePrompt)) {
            const replied = await completeActiveSkill(actor, activeClient, latest.requestId, null);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-zhente-close-unrelated-active-skill' });
            continue;
          }
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-zhente black Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioZhenteUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: replied, detail: 'delta-zhente-black-slash-semantic-active-skill' });
          continue;
        }
        if (deltaTieqiScenario) {
          const isTieqiDiscard = /hs__tieqi|铁骑|Thiết\s*Kỵ|tieqi|bỏ\s*chọn|弃置|discard/i.test(activePrompt);
          const isTieqiUse = /delta-tieqi|dùng\s*Sát|use.*Slash|tqs_qa_delta_tieqi_use/i.test(activePrompt);
          if (!scenarioTieqiGateReply) {
            const cancel = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
              .getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
            if (await cancel.count() && await cancel.isEnabled()) {
              await cancel.click();
              await waitForReply(activeClient, latest.requestId);
            }
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: true, detail: 'delta-tieqi-pre-gate-active-skill' });
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          if (isTieqiDiscard && scenarioTieqiUseReply) {
            const cancel = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
              .getByRole('button', { name: 'Hủy', exact: true });
            await cancel.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await cancel.isEnabled(), 'delta-tieqi must expose a cancellable target discard request');
            await cancel.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) scenarioTieqiDiscardReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-tieqi-discard-cancel' });
            continue;
          }
          if (isTieqiUse && !scenarioTieqiUseReply) {
            const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
            const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
              .filter({ hasText: /Sát|Slash|杀/i }).first();
            await slash.waitFor({ state: 'visible', timeout: 10000 });
            await slash.click();
            const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
            await target.waitFor({ state: 'visible', timeout: 10000 });
            if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            await confirm.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await confirm.isEnabled(), 'delta-tieqi must enable the reserved Slash target confirmation');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) scenarioTieqiUseReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-tieqi-slash-semantic-active-skill' });
            continue;
          }
        }
        if (deltaXisheScenario) {
          assert.ok(scenarioXisheGateReply, 'delta-xishe must pass the readiness gate before discarding equipment');
          assert.match(activePrompt, /袭射|Tập\s*Xạ|ld__xishe|xishe/i,
            'delta-xishe received an unrelated active-skill request while expecting equipment discard');
          assert.ok(!scenarioXisheArmorReply, 'delta-xishe must not receive an extra equipment request after the final armor discard');
          // Upstream room:askToDiscard(include_equip=true) expands equipped
          // cards into real CardItem entries. Click the projected weapon/armor
          // in the human client's native request, without using card IDs.
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const cancelBranch = scenarioXisheWeaponReply && !scenarioXisheCancelReply;
          const cardType = !scenarioXisheWeaponReply ? 'Vũ Khí' : 'Phòng Cụ';
          const detail = !scenarioXisheWeaponReply ? 'delta-xishe-weapon-discard'
            : cancelBranch ? 'delta-xishe-optional-cancel' : 'delta-xishe-armor-discard';
          if (cancelBranch) {
            const cancel = controls.getByRole('button', { name: 'Hủy', exact: true });
            await cancel.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await cancel.isEnabled(), 'delta-xishe must expose a cancellable repeated discard offer');
            await cancel.click();
          } else {
            const equipment = controls.locator('.gameplay-hand button[data-card-id].type-equip:enabled')
              .filter({ hasText: cardType }).first();
            await equipment.waitFor({ state: 'visible', timeout: 10000 });
            await equipment.click();
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            await confirm.waitFor({ state: 'visible', timeout: 10000 });
            assert.ok(await confirm.isEnabled(), `delta-xishe must allow selecting the ${cardType} equipment`);
            await confirm.click();
          }
          const replied = await waitForReply(activeClient, latest.requestId);
          if (!scenarioXisheWeaponReply && replied) scenarioXisheWeaponReply = true;
          else if (cancelBranch && replied) scenarioXisheCancelReply = true;
          else if (replied) scenarioXisheArmorReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied, detail });
          continue;
        }
        if (deltaXiongsuanScenario) {
          const skillCount = await actor.locator('button.sg-skill-button').count().catch(() => 0);
          console.log(`delta-xiongsuan active request client=${activeClient + 1} request=${latest.requestId} ` +
            `panel=${activePrompt.length > 0} skillCount=${skillCount}`);
        }
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
        const hiddenEjueDamage = hiddenEjueScenario &&
          /hidden_ejue_damage|kiểm tra Ách Tuyệt|扼绝|Ách Tuyệt|heg__ejue|ejue/i.test(activePrompt);
        const hiddenDufuDamage = hiddenDufuScenario &&
          /hidden_dufu_damage|kiểm tra Độc Phu|独夫|Độc Phu|heg__dufu|dufu/i.test(activePrompt);
        const hiddenJianzhiDamage = hiddenJianzhiScenario &&
          /hidden_jianzhi_damage|kiểm tra Gian Chí|奸志|Gian Chí|heg__jianzhi|jianzhi/i.test(activePrompt);
        const hiddenZhimanDamage = hiddenZhimanScenario &&
          /hidden_zhiman_damage|kiểm tra Chế Man|制蛮|Chế Man|ld__zhiman|zhiman/i.test(activePrompt);
        const hiddenJilixDamage = hiddenJilixScenario && nativeQaGateSeen &&
          /hidden_jilix_damage|kiểm tra Ký Ly|寄篱|Ký Ly|ld__jilix|jilix/i.test(activePrompt);
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
        const hiddenEnyuanPeach = hiddenEnyuanScenario &&
          /hidden_enyuan_peach|dùng Đào|恩怨|Ân Oán|enyuan/i.test(activePrompt);
        const hiddenFuyinSlash = hiddenFuyinScenario &&
          nativeQaGateSeen &&
          /hidden_fuyin_damage|dùng Sát|父荫|Phụ Âm|bóng mát của cha|fuyin/i.test(activePrompt);
        const chujueControlFactionSlash = deltaChujueScenario &&
          /chưa có người chết|control.?kingdom|control.?faction|chujue-control|kiểm tra đáp lại/i.test(activePrompt);
        const deferredHiddenScenario = hiddenFuyinScenario || hiddenJilixScenario;
        const deferredGateAccepted = hiddenFuyinScenario ? hiddenFuyinGateReply : hiddenJilixGateReply;
        if (deferredHiddenScenario && !deferredGateAccepted) {
          // EventPhaseStart is intentionally deferred for these source
          // predicates. Do not consume an unrelated active request while the
          // native readiness AskForSkillInvoke is still pending.
          const cancel = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
          if (await cancel.count() && await cancel.isEnabled()) {
            await cancel.click();
            await waitForReply(activeClient, latest.requestId);
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (hiddenJizhiCard || hiddenMingshiCard || hiddenQianxunCard || hiddenKongchengCard || hiddenWeimuCard || hiddenTianxiangChoose || hiddenEnyuanPeach || hiddenFuyinSlash || hiddenJilixDamage) {
          // The hidden Enyuan actor is the Peach target, but the real card is
          // owned by the other seat.  Keep the request page explicit so a
          // future selector/seat change cannot accidentally inspect the
          // hidden actor's hand instead of the source player's hand.
          const requestPage = hiddenEnyuanPeach ? pages[activeClient] : actor;
          const hand = requestPage.locator('.gameplay-hand button:enabled');
          const preferredCard = hiddenTianxiangChoose
            ? hand.first()
            : hiddenEnyuanPeach
            ? hand.filter({ hasText: /Đào|Peach|桃/i }).first()
            : hiddenFuyinSlash
            ? hand.filter({ hasText: /Sát|Slash|杀/i }).first()
            : hiddenJilixDamage
            ? hand.filter({ hasText: /Sát|Slash|杀/i }).first()
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
          assert.ok(await card.count(), `${hiddenEnyuanPeach ? 'hidden-enyuan' : hiddenFuyinSlash ? 'hidden-fuyin' : hiddenJilixDamage ? 'hidden-jilix' : hiddenTianxiangChoose ? 'hidden-tianxiang' : hiddenJizhiCard ? 'hidden-jizhi' : hiddenMingshiCard ? 'hidden-mingshi' : hiddenQianxunCard ? 'hidden-qianxun' : hiddenKongchengCard ? 'hidden-kongcheng' : 'hidden-weimu'} must expose its reserved real card`);
          await card.click();
          await chooseTargetIfNeeded(requestPage);
          const ok = requestPage.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.count() && await ok.isEnabled(),
            `${hiddenEnyuanPeach ? 'hidden-enyuan' : hiddenFuyinSlash ? 'hidden-fuyin' : hiddenJilixDamage ? 'hidden-jilix' : hiddenTianxiangChoose ? 'hidden-tianxiang' : hiddenJizhiCard ? 'hidden-jizhi' : hiddenMingshiCard ? 'hidden-mingshi' : hiddenQianxunCard ? 'hidden-qianxun' : hiddenKongchengCard ? 'hidden-kongcheng' : 'hidden-weimu'} must enable confirmation after selecting its real card`);
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
          if (hiddenEnyuanPeach && replied) hiddenEnyuanCardReply = true;
          if (hiddenFuyinSlash && replied) hiddenFuyinCardReply = true;
          if (hiddenJilixDamage && replied) hiddenJilixCardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: hiddenEnyuanPeach ? 'hidden-enyuan-peach-target' : hiddenFuyinSlash ? 'hidden-fuyin-source-slash' : hiddenJilixDamage ? 'hidden-jilix-red-slash' : hiddenTianxiangChoose ? 'hidden-tianxiang-heart-card-and-target' : hiddenJizhiCard ? 'hidden-jizhi-duel' : hiddenMingshiCard ? 'hidden-mingshi-hidden-source-slash' :
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
        } else if (hiddenEjueDamage) {
          if (activeClient !== scenarioClient) {
            const end = actor.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          const hand = actor.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          // The native QA fixture gives the actor exactly one hand card. Some
          // mobile card renderers expose its label only through the card art
          // (so hasText() is empty), while others include the translated name.
          // Keep the semantic label as the first choice, but accept the sole
          // enabled hand card as the same deterministic reserved Slash.
          const slash = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await slash.count(), 'hidden-ejue must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-ejue must expose the unknown-kingdom target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-ejue must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenEjueDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-ejue-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenDufuDamage) {
          if (activeClient !== scenarioClient) {
            const end = actor.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          const hand = actor.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          const slash = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await slash.count(), 'hidden-dufu must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-dufu must expose the different-kingdom target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-dufu must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenDufuDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-dufu-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenZhimanDamage) {
          if (activeClient !== scenarioClient) {
            const end = actor.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          const hand = actor.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          const slash = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await slash.count(), 'hidden-zhiman must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-zhiman must expose the target with reserved equipment');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-zhiman must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenZhimanDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-zhiman-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenJianzhiDamage) {
          if (activeClient !== scenarioClient) {
            const end = actor.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          const hand = actor.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          // The fixture deliberately keeps a Jink beside the Slash. Prefer the
          // semantic label so the filler cannot be spent, while retaining the
          // deterministic first-card fallback for art-only mobile renderers.
          const slash = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await slash.count(), 'hidden-jianzhi must expose the reserved actor Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jianzhi must expose the one-hp target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-jianzhi must enable confirmation after selecting the reserved Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJianzhiDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jianzhi-lethal-damage-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (hiddenJilixDamage) {
          const hand = actor.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          const slash = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await slash.count(), 'hidden-jilix must expose the reserved red source Slash');
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-jilix must expose the hidden Yan Baihu target');
          await target.click();
          const ok = actor.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await ok.isEnabled(), 'hidden-jilix must enable confirmation after selecting the red Slash');
          await ok.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenJilixCardReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-jilix-red-slash' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        } else if (deltaChujueScenario) {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const controlBranch = chujueControlFactionSlash || scenarioChujueDeadFactionUseReply;
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i })
            .first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const targets = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          // Native askToUseRealCard() supplies exclusive_targets for each
          // branch, so the browser intentionally receives one target only.
          const target = targets.first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await target.count() > 0,
            `delta-chujue must expose the ${controlBranch ? 'control-kingdom' : 'dead-kingdom'} target`);
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-chujue Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (!controlBranch && replied) scenarioChujueDeadFactionUseReply = true;
          if (controlBranch && replied) scenarioChujueControlFactionUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: controlBranch ? 'delta-chujue-control-faction-slash' : 'delta-chujue-dead-faction-slash' });
          continue;
        } else if (deltaFengshiScenario) {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const prompt = `${await actor.locator('.request-panel').innerText().catch(() => '')} ${await controls.locator('.gameplay-prompt:visible').innerText().catch(() => '')}`;
          if (!scenarioFengshiGateReply || !/delta-fengshi|dùng lá Sát đầu lượt/i.test(prompt)) {
            // Start phase is deferred until after ordinary active-skill
            // requests. Resolve these without spending the reserved Slash.
            const replied = await completeActiveSkill(actor, activeClient, latest.requestId, null);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-fengshi-pre-gate-active-skill' });
            continue;
          }
          // The native fixture restricts the first physical Slash to one
          // bot target. Both variants follow the same client request path.
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const targets = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          await targets.first().waitFor({ state: 'visible', timeout: 10000 });
          assert.equal(await targets.count(), 1, 'delta-fengshi must restrict Slash to the native bot target');
          if (await targets.first().getAttribute('aria-pressed') !== 'true') await targets.first().click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-fengshi first physical Slash must be legal');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioFengshiSlashReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-fengshi-first-slash' });
          continue;
        } else if (deltaBaweiScenario) {
          // The director first asks for the Slash against the previously
          // damaged Wei bot, then the Slash against the untouched Shu bot.
          // Each request restricts the legal target to its own branch.
          if (!scenarioBaweiGateReply) {
            // A normal active-card request can arrive while the native
            // readiness gate is still pending (the bot may start its phase
            // before the QA director reaches the actor). Do not consume it
            // as one of the two reserved Bawei Slashes; this mirrors the
            // Fengshi pre-gate handling and keeps the gate authoritative.
            const replied = await completeActiveSkill(actor, activeClient, latest.requestId, null);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: replied, detail: 'delta-bawei-pre-gate-active-skill' });
            continue;
          }
          const controlBranch = scenarioBaweiDamagedUseReply;
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-bawei must enable the reserved Slash target');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied && controlBranch) scenarioBaweiControlUseReply = true;
          if (replied && !controlBranch) scenarioBaweiDamagedUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: controlBranch ? 'delta-bawei-control-slash' : 'delta-bawei-damaged-slash' });
          continue;
        } else if (deltaJianchuScenario) {
          // The native adapter exposes askToUseRealCard() as
          // AskForUseActiveSkill for this QA helper. Select the fixed Slash
          // and the only opponent target; Jianchu itself will then emit the
          // source-card AskForCardChosen request.
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i })
            .first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-jianchu active-skill Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioJianchuUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-jianchu-slash-semantic-active-skill' });
          continue;
        } else if (deltaQianceScenario) {
          // askToUseRealCard() is exposed by this native build as
          // AskForUseActiveSkill when a QA skill_name is supplied.  It still
          // renders the real hand-card/target controls, so drive the reserved
          // Duel through those controls instead of letting completeActiveSkill
          // cancel the request as an unrelated skill.
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const duel = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Quyết Đấu|Duel|决斗/i })
            .first();
          await duel.waitFor({ state: 'visible', timeout: 10000 });
          await duel.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-qiance active-skill Duel target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioQianceCardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-qiance-duel-semantic-active-skill' });
          continue;
        } else if (damageExchangeScenario || hiddenYijiActive || hiddenRevealActive) {
          const prompt = await actor.getByRole('region', { name: 'Điều khiển lượt chơi' }).innerText().catch(() => '');
          if (hiddenRevealActive) {
            console.log(`hidden-reveal active request client=${activeClient + 1} request=${latest.requestId} matched=true`);
          }
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
          : testScenario === 'cards-and-choice' || testScenario === 'poxi' || deltaXiongsuanScenario || deltaWenjiScenario || deltaLordWenjiScenario
            ? selectedScenario?.skill ?? null : null;
        const replied = await completeActiveSkill(actor, activeClient, latest.requestId, activeSkill);
        if (replied && testScenario === 'rescue-battle' && activeSkill) scenarioViewAsReply = true;
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: replied,
          detail: activeSkill?.source ?? 'cancel'});
      } else if(latest?.command==='AskForUseCard' || latest?.command==='AskForResponseCard') {
        if ((deltaWenjiScenario || deltaLordWenjiScenario) && latest.command === 'AskForResponseCard') {
          throw new Error(`${testScenario} must suppress the target response request after UseCardData:setDisresponsive()`);
        }
        if (deltaQianceScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-qiance must suppress the target Slash response request after qiance setDisresponsive()');
        }
        if (deltaJianchuScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-jianchu must suppress the target Jink response request after Jianchu setDisresponsive()');
        }
        if (deltaTieqiScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-tieqi must suppress the target Jink response request after Tieqi setDisresponsive()');
        }
        if (deltaChujueScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-chujue must suppress only the dead-kingdom target response request; control response is native-bot evidence');
        }
        if (deltaBaweiScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-bawei real clients must not receive a Jink request; the control response belongs to the native bot');
        }
        if (deltaFengshiScenario && latest.command === 'AskForResponseCard') {
          throw new Error('delta-fengshi real clients must not receive a Jink request; the response belongs to the native bot');
        }
        if (damageExchangeScenario) {
          const result = await completeDamageExchangeUseCard(actor, activeClient, latest.requestId);
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: result.replied, detail: result.detail });
          continue;
        }
        if (deltaZhenteScenario && latest.command === 'AskForUseCard') {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const prompt = `${await actor.locator('.request-panel').innerText().catch(() => '')} ${await controls.innerText().catch(() => '')}`;
          if (!scenarioZhenteGateReply || scenarioZhenteUseReply ||
              !/delta-zhente|dùng Sát đen|kiểm tra 贞特|ty_heg__zhente/i.test(prompt)) {
            const result = await completeUseCard(actor, activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: result.replied, detail: 'delta-zhente-close-unrelated-use-card' });
            continue;
          }
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-zhente black Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioZhenteUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: replied, detail: 'delta-zhente-black-slash-semantic-card-target' });
          continue;
        }
        if (deltaChujueScenario && latest.command === 'AskForUseCard') {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const prompt = `${await actor.locator('.request-panel').innerText().catch(() => '')} ${await controls.innerText().catch(() => '')}`;
          const controlBranch = /chưa có người chết|control.?kingdom|control.?faction|chujue-control|kiểm tra đáp lại/i.test(prompt) ||
            scenarioChujueDeadFactionUseReply;
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i })
            .first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const targets = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          // Native askToUseRealCard() supplies exclusive_targets for each
          // branch, so the browser intentionally receives one target only.
          const target = targets.first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await target.count() > 0,
            `delta-chujue must expose the ${controlBranch ? 'control-kingdom' : 'dead-kingdom'} target`);
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-chujue Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (controlBranch && replied) scenarioChujueControlFactionUseReply = true;
          if (!controlBranch && replied) scenarioChujueDeadFactionUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: controlBranch ? 'delta-chujue-control-faction-slash-card' : 'delta-chujue-dead-faction-slash-card' });
          continue;
        }
        if (deltaFengshiScenario && latest.command === 'AskForUseCard') {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const prompt = `${await actor.locator('.request-panel').innerText().catch(() => '')} ${await controls.innerText().catch(() => '')}`;
          if (!scenarioFengshiGateReply || !/delta-fengshi|dùng lá Sát đầu lượt/i.test(prompt)) {
            // The actor's Start phase is deferred. Earlier ordinary use-card
            // requests must resolve without consuming the reserved first Slash.
            const result = await completeUseCard(actor, activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: result.replied, detail: 'delta-fengshi-pre-gate-use-card' });
            continue;
          }
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const targets = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          await targets.first().waitFor({ state: 'visible', timeout: 10000 });
          assert.equal(await targets.count(), 1, 'delta-fengshi must restrict Slash to the native bot target');
          if (await targets.first().getAttribute('aria-pressed') !== 'true') await targets.first().click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-fengshi first physical Slash must be legal');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioFengshiSlashReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-fengshi-first-slash-card' });
          continue;
        }
        if (deltaBaweiScenario && latest.command === 'AskForUseCard') {
          if (!scenarioBaweiGateReply) {
            // The actor can expose an ordinary turn PlayCard request while
            // the deferred EventPhaseStart gate is still crossing the real
            // client. Resolve that request without spending either reserved
            // Slash; the native director cannot enter its bounded fixture
            // until the readiness AskForSkillInvoke has been answered.
            const result = await completeUseCard(actor, activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: result.replied, detail: 'delta-bawei-pre-gate-use-card' });
            continue;
          }
          const controlBranch = scenarioBaweiDamagedUseReply;
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-bawei must enable the reserved Slash target');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied && controlBranch) scenarioBaweiControlUseReply = true;
          if (replied && !controlBranch) scenarioBaweiDamagedUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: controlBranch ? 'delta-bawei-control-slash-card' : 'delta-bawei-damaged-slash-card' });
          continue;
        }
        if (deltaJianchuScenario && latest.command === 'AskForUseCard') {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i })
            .first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-jianchu Slash target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioJianchuUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-jianchu-slash-semantic-card-target' });
          continue;
        }
        if (deltaTieqiScenario && latest.command === 'AskForUseCard') {
          const controls = actor.getByRole('region', { name: 'Điều khiển lượt chơi' });
          const prompt = `${await actor.locator('.request-panel').innerText().catch(() => '')} ${await controls.innerText().catch(() => '')}`;
          if (!scenarioTieqiGateReply) {
            const result = await completeUseCard(actor, activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: result.replied, detail: 'delta-tieqi-pre-gate-use-card' });
            continue;
          }
          if (scenarioTieqiUseReply || !/delta-tieqi|dùng\s*Sát|use.*Slash|铁骑|tieqi/i.test(prompt)) {
            const result = await completeUseCard(actor, activeClient, latest.requestId);
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: result.replied, detail: 'delta-tieqi-close-unrelated-use-card' });
            continue;
          }
          const slash = controls.locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          await slash.waitFor({ state: 'visible', timeout: 10000 });
          await slash.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-tieqi must enable the reserved Slash target confirmation');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioTieqiUseReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-tieqi-slash-semantic-card-target' });
          continue;
        }
        if (deltaQianceScenario && latest.command === 'AskForUseCard') {
          // Qiance's fixture has a reserved Duel and a fixed non-self target.
          // Do not let the generic first-enabled-card helper consume a stale
          // hand button or submit the card before the target control has
          // rendered; the native fixture deliberately asserts both values.
          const duel = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .locator('.gameplay-hand button[data-card-id]:enabled')
            .filter({ hasText: /Quyết Đấu|Duel|决斗/i })
            .first();
          await duel.waitFor({ state: 'visible', timeout: 10000 });
          await duel.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          console.log(`Scenario delta-qiance controls: client=${activeClient} duelCount=${await duel.count()} targetCount=${await target.count()}`);
          await target.waitFor({ state: 'visible', timeout: 10000 });
          if (await target.getAttribute('aria-pressed') !== 'true') await target.click();
          const confirm = actor.getByRole('region', { name: 'Điều khiển lượt chơi' })
            .getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-qiance Duel target confirmation must be enabled');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioQianceCardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: 'delta-qiance-duel-semantic-card-target' });
          continue;
        }
        const result = await completeUseCard(actor, activeClient, latest.requestId);
        if (result.rescue && result.replied) scenarioRescueReply = true;
        if (result.rescue && result.peach && result.replied) scenarioRescuePeach = true;
        if (result.rescue && result.blocked) scenarioRescueBlocked = true;
        if (result.viewAs && result.replied) scenarioViewAsReply = true;
        if (deltaQianceScenario && latest.command === 'AskForUseCard' && result.replied) {
          scenarioQianceCardReply = true;
        }
        scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: result.replied,
          detail: deltaQianceScenario ? 'delta-qiance-duel' : result.rescue ? result.viewAs ? 'rescue-peach-view-as' : result.peach ? 'rescue-peach' : result.blocked ? 'rescue-peach-blocked' : 'rescue-no-peach' : undefined});
      } else if(latest?.command==='AskForCardChosen') {
        const panel=actor.getByRole('region',{name:'Chọn bài đối thủ'});
        const options=panel.locator('button.gameplay-choice:enabled');
        const labels=await options.allTextContents();
        const hiddenIndex=labels.findIndex((label)=>/Bài úp/i.test(label.trim()));
        const visibleIndex=labels.findIndex((label)=>!/Bài úp/i.test(label.trim()));
        const option=options.nth(deltaJianchuScenario
          ? (visibleIndex >= 0 ? visibleIndex : 0)
          : (hiddenIndex >= 0 ? hiddenIndex : 0));
        if(await option.count())await option.click();
        const replied = await waitForReply(activeClient, latest.requestId);
        if (replied) {
          scenarioCardChosenReply=true;
          if (hiddenIndex >= 0) scenarioCardChosenHidden=true;
          if (deltaJianchuScenario) scenarioJianchuCardReply = true;
          if (damageExchangeScenario && scenarioFankuiInvoked) scenarioFankuiReply = true;
          if (hiddenFankuiScenario) hiddenFankuiChoiceReply = true;
          if (hiddenZhimanScenario) hiddenZhimanCardReply = true;
          if (deltaSijianScenario) scenarioSijianCardReply = true;
          scenarioObservations.push({command: latest.command, requestId: latest.requestId, reply: true,
            detail: deltaSijianScenario ? 'delta-sijian-select-target-card' : deltaJianchuScenario ? 'delta-jianchu-select-equipment' : hiddenZhimanScenario ? 'hidden-zhiman-obtain-equipment' : hiddenFankuiScenario ? 'hidden-fankui-obtain' : hiddenIndex >= 0 ? 'hidden-card' : 'public-card'});
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
        if (deltaTieqiScenario && latest.command === 'CustomDialog') {
          const panel = actor.getByRole('region', { name: 'Lựa chọn bài và sắp xếp' });
          const choices = panel.locator('button.sg-general-choice-token:enabled');
          await choices.first().waitFor({ state: 'visible', timeout: 10000 });
          await choices.first().click();
          const confirm = panel.getByRole('button', { name: 'Xác nhận', exact: true });
          await confirm.waitFor({ state: 'visible', timeout: 10000 });
          assert.ok(await confirm.isEnabled(), 'delta-tieqi must enable the real general-choice confirmation');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) scenarioTieqiGeneralReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: replied, detail: 'delta-tieqi-general-choice' });
        } else {
          const replied = await completeNativeDialog(actor, activeClient, latest.requestId);
          if (hiddenGuanxingScenario && latest.command === 'AskForArrangeCards' && replied) {
            hiddenGuanxingArrangeReply = true;
          }
          if (hiddenLuoshenScenario && latest.command === 'AskForAG' && replied) {
            hiddenLuoshenAgReply = true;
          }
        }
      } else if(latest?.command==='PlayCard') {
        const controls=actor.getByRole('region',{name:'Điều khiển lượt chơi'});
        // SkillDock is rendered beside, rather than inside, the gameplay
        // request region.  Keep the live runner on the production DOM path.
        const skillButtons=actor.locator('button.sg-skill-button');
        if (selectedScenario && !printedScenarioSkills) {
          printedScenarioSkills = true;
          console.log(`Scenario ${testScenario} first PlayCard skill-control count: ${await skillButtons.count()}`);
        }
        if (testScenario === 'card-chosen' && activeClient !== scenarioClient) {
          // The other real client can have a normal-turn PlayCard request in
          // flight while the native director is preparing Jianchu.  Do not
          // assert that this unrelated seat has the caller's SkillButton or
          // consume its card as the scenario input.
          const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
          const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
          const endReady = (await end.count().catch(() => 0)) > 0 &&
            await end.first().isEnabled().catch(() => false);
          const cancelReady = (await cancel.count().catch(() => 0)) > 0 &&
            await cancel.first().isEnabled().catch(() => false);
          if (endReady) await end.first().click().catch(() => undefined);
          else if (cancelReady) await cancel.first().click().catch(() => undefined);
          await waitForReply(activeClient, latest.requestId);
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
            reply: true, detail: 'card-chosen-close-other-seat-play-card' });
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (testScenario === 'card-chosen' && activeClient === scenarioClient && !scenarioCardChosenHidden) {
          // Jianchu is selected inside the same native PlayCard scene before
          // the source Slash is confirmed.  Counting the rail proves only
          // that the skill was projected; without this state update the
          // server quite correctly resolves an ordinary Slash and never
          // emits the hidden AskForCardChosen follow-up.
          const jianchu = skillButtons.filter({ hasText: /jianchu|鞬出|Kiền Xuất|Kiên Xuất|Lấy ra/i }).first();
          assert.ok(await jianchu.count(), 'card-chosen must expose the native Jianchu SkillButton in PlayCard');
          if (await jianchu.isEnabled() && await jianchu.getAttribute('aria-pressed') !== 'true') {
            await jianchu.click();
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: false, detail: 'select-jianchu-before-slash' });
            await new Promise((resolve) => setTimeout(resolve, 100));
          }
        }
        if (deltaFengshiScenario) {
          const prompt = await controls.innerText().catch(() => '');
          if (!scenarioFengshiGateReply || !/delta-fengshi|dùng lá Sát đầu lượt/i.test(prompt)) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
            const action = await end.count() && await end.isEnabled() ? end : cancel;
            if (await action.count() && await action.isEnabled()) {
              await action.click();
              await waitForReply(activeClient, latest.requestId);
            }
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId,
              reply: true, detail: 'delta-fengshi-close-unrelated-play-card' });
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
        }
        if (deltaXiongsuanScenario) {
          // The native delta fixture completes the real xiongsuan action and
          // then emits GameOver from the QA director.  A stale PlayCard
          // request from the other seat can still be visible for one polling
          // turn while that packet propagates.  Do not let the generic card
          // loop consume (or re-index) the deterministic hand; close the
          // stale request and let the GameOver packet terminate the scenario.
          const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
          const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
          const action = await end.count() && await end.isEnabled() ? end : cancel;
          if (await action.count() && await action.isEnabled()) {
            await action.click();
            await waitForReply(activeClient, latest.requestId);
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (deltaWenjiScenario || deltaLordWenjiScenario) {
          // Room:askToUseRealCard() is normally represented by the native
          // userealcard active-skill request, but some adapters publish the
          // same request as a regular PlayCard. Accept only the explicit QA
          // prompt here; any stale normal-turn request must not consume the
          // deterministic transferred Slash.
          const prompt = await controls.innerText().catch(() => '');
          if (/delta-(?:lord-)?wenji|dùng Sát được hỏi kế/i.test(prompt)) {
            const slash = controls.locator('.gameplay-hand button:enabled')
              .filter({ hasText: /Sát|Slash|杀/i }).first();
            assert.ok(await slash.count(), `${testScenario} PlayCard must expose the transferred Slash`);
            await slash.click();
            await chooseTargetIfNeeded(actor);
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.count() && await confirm.isEnabled(),
              `${testScenario} PlayCard must enable confirmation after selecting the transferred Slash`);
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) {
              if (deltaLordWenjiScenario) scenarioLordWenjiUseReply = true;
              else scenarioWenjiUseReply = true;
              scenarioActiveSkillReply = true;
            }
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
              detail: `${testScenario}-use-transferred-slash-play-card` });
          } else {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
            const action = await end.count() && await end.isEnabled() ? end : cancel;
            if (await action.count() && await action.isEnabled()) {
              await action.click();
              await waitForReply(activeClient, latest.requestId);
            }
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: `${testScenario}-close-stale-play-card` });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (deltaQianceScenario) {
          // Room:askToUseRealCard() is normally published as AskForUseCard,
          // but a compatible adapter may expose the same explicit QA prompt
          // as PlayCard. Consume only that prompt; never spend the reserved
          // Duel on an unrelated stale turn request.
          const prompt = await controls.innerText().catch(() => '');
          if (/delta-qiance|dùng Quyết Đấu|Duel|谦策/i.test(prompt)) {
            const duel = controls.locator('.gameplay-hand button:enabled')
              .filter({ hasText: /Quyết Đấu|Duel|决斗/i }).first();
            assert.ok(await duel.count(), 'delta-qiance PlayCard must expose the reserved Duel');
            await duel.click();
            await chooseTargetIfNeeded(actor);
            const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
            assert.ok(await confirm.count() && await confirm.isEnabled(),
              'delta-qiance PlayCard must enable confirmation after selecting the Duel');
            await confirm.click();
            const replied = await waitForReply(activeClient, latest.requestId);
            if (replied) scenarioQianceCardReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
              detail: 'delta-qiance-duel-play-card' });
          } else {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            const cancel = controls.getByRole('button', { name: /^(Hủy|Bỏ qua)$/ });
            const action = await end.count() && await end.isEnabled() ? end : cancel;
            if (await action.count() && await action.isEnabled()) {
              await action.click();
              await waitForReply(activeClient, latest.requestId);
            }
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'delta-qiance-close-stale-play-card' });
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
          continue;
        }
        if (hiddenJizhiScenario || hiddenMingshiScenario || hiddenQianxunScenario || hiddenKongchengScenario || hiddenEnyuanScenario || hiddenFuyinScenario || hiddenJilixScenario) {
          // Fuyin and Jilix are deliberately deferred to the actor's native
          // Start phase because their source predicates inspect turn history.
          // A normal PlayCard request can therefore arrive before the QA
          // prelight gate. Never consume the reserved source Slash from that
          // unrelated turn; finish it and wait for the gate to establish the
          // real askToUseRealCard request.
          const deferredHiddenScenario = hiddenFuyinScenario || hiddenJilixScenario;
          const deferredGateAccepted = hiddenFuyinScenario
            ? hiddenFuyinGateReply
            : hiddenJilixGateReply;
          if (deferredHiddenScenario && !deferredGateAccepted) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise((resolve) => setTimeout(resolve, 250));
            continue;
          }
          const hand = controls.locator('.gameplay-hand button:enabled');
          const preferredCard = hiddenFuyinScenario
            ? hand.filter({ hasText: /Sát|Slash|杀/i }).first()
            : hiddenJilixScenario
            ? hand.filter({ hasText: /Sát|Slash|杀/i }).first()
            : hiddenEnyuanScenario
            ? hand.filter({ hasText: /Đào|Peach|桃/i }).first()
            : hiddenKongchengScenario
            ? hand.filter({ hasText: /Quyết Đấu|决斗|Duel/i }).first()
            : hiddenQianxunScenario
            ? hand.filter({ hasText: hiddenQianxunIndulgenceScenario
              ? /Lạc Bất Tư Thục|乐不思蜀|Indulgence/i
              : /Thuận Thủ|顺手牵羊|Snatch|顺手/i }).first()
            : hand.first();
          const card = await preferredCard.count() ? preferredCard : hand.first();
          assert.ok(await card.count(), `${hiddenFuyinScenario ? 'hidden-fuyin' : hiddenJilixScenario ? 'hidden-jilix' : hiddenEnyuanScenario ? 'hidden-enyuan' : hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' : hiddenQianxunScenario ? 'hidden-qianxun' : 'hidden-kongcheng'} must expose its reserved real card`);
          await card.click();
          await chooseTargetIfNeeded(actor);
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.count() && await confirm.isEnabled(),
            `${hiddenFuyinScenario ? 'hidden-fuyin' : hiddenJilixScenario ? 'hidden-jilix' : hiddenEnyuanScenario ? 'hidden-enyuan' : hiddenJizhiScenario ? 'hidden-jizhi' : hiddenMingshiScenario ? 'hidden-mingshi' : hiddenQianxunScenario ? 'hidden-qianxun' : 'hidden-kongcheng'} must enable PlayCard confirmation after selecting its real card`);
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (hiddenJizhiScenario && replied) hiddenJizhiCardReply = true;
          if (hiddenMingshiScenario && replied) hiddenMingshiCardReply = true;
          if (hiddenQianxunScenario && replied) hiddenQianxunCardReply = true;
          if (hiddenKongchengScenario && replied) hiddenKongchengCardReply = true;
          if (hiddenEnyuanScenario && replied) hiddenEnyuanCardReply = true;
          if (hiddenFuyinScenario && replied) hiddenFuyinCardReply = true;
          if (hiddenJilixScenario && replied) hiddenJilixCardReply = true;
          scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: replied,
            detail: hiddenFuyinScenario ? 'hidden-fuyin-source-slash' : hiddenJilixScenario ? 'hidden-jilix-red-slash' : hiddenEnyuanScenario ? 'hidden-enyuan-peach-target' : hiddenJizhiScenario ? 'hidden-jizhi-duel' : hiddenMingshiScenario ? 'hidden-mingshi-hidden-source-slash' :
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
        if (hiddenEjueScenario) {
          if (activeClient !== scenarioClient) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise(r => setTimeout(r, 250));
            continue;
          }
          const hand = controls.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand
            .filter({ hasText: /Sát|Slash|杀/i }).first();
          const card = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await card.count(), 'hidden-ejue must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-ejue must expose the unknown-kingdom target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-ejue must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenEjueDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-ejue-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenDufuScenario) {
          if (activeClient !== scenarioClient) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise(r => setTimeout(r, 250));
            continue;
          }
          const hand = controls.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          const card = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await card.count(), 'hidden-dufu must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-dufu must expose the different-kingdom target');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-dufu must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenDufuDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-dufu-damage-slash' });
          }
          await new Promise(r=>setTimeout(r,250));
          continue;
        }
        if (hiddenZhimanScenario && !hiddenZhimanDamageReply) {
          // Room:askToUseRealCard() may be published as a regular PlayCard
          // request by the native adapter. Keep this reserved Slash path in
          // lockstep with the AskForUseActiveSkill transport branch above.
          if (activeClient !== scenarioClient) {
            const end = controls.getByRole('button', { name: 'Kết thúc lượt', exact: true });
            if (await end.count() && await end.isEnabled()) await end.click();
            await waitForReply(activeClient, latest.requestId);
            await new Promise(r => setTimeout(r, 250));
            continue;
          }
          const hand = controls.locator('.gameplay-hand button:enabled');
          const labelledSlash = hand.filter({ hasText: /Sát|Slash|杀/i }).first();
          const card = await labelledSlash.count() ? labelledSlash : hand.first();
          assert.ok(await card.count(), 'hidden-zhiman must expose the reserved actor Slash');
          await card.click();
          const target = actor.locator('.board-player:not(.board-self) .gameplay-target:enabled').first();
          assert.ok(await target.count(), 'hidden-zhiman must expose the target with reserved equipment');
          await target.click();
          const confirm = controls.getByRole('button', { name: 'Xác nhận', exact: true });
          assert.ok(await confirm.isEnabled(), 'hidden-zhiman must enable PlayCard confirmation after selecting the reserved Slash');
          await confirm.click();
          const replied = await waitForReply(activeClient, latest.requestId);
          if (replied) {
            hiddenZhimanDamageReply = true;
            scenarioObservations.push({ command: latest.command, requestId: latest.requestId, reply: true,
              detail: 'hidden-zhiman-damage-slash' });
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
        const initialHandCount = await hand.count();
        for(let i=0;i<initialHandCount;i++) {
          const label=await hand.nth(i).innerText();
          (testScenario === 'card-chosen' && /Sát|杀|Slash/i.test(label) ? preferred : fallback).push(i);
        }
        for(const i of [...preferred,...fallback]) {
          // Selecting/submitting a card can remove it while React re-renders
          // the hand.  Re-check the live count before reusing a numeric
          // locator so a one-card fixture cannot produce a stale nth(1)
          // timeout.
          if (i >= await hand.count()) continue;
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
        if (manualCardReply && cardWireReplayRequested && !cardWireReplayInjected) {
          cardWireReplayRejectsBefore = readNativeMappingSummary().choiceRejects;
          const replayRoute = cardWireReplayRoutes.find((candidate) => candidate.page === actor);
          let injected = false;
          if (replayRoute?.server && replayRoute.lastReply) {
            const replay = Buffer.from(replayRoute.lastReply);
            replayRoute.lastReply = null;
            replayRoute.pendingReplay = replay;
            injected = true;
          }
          const replayDebug = replayRoute ? {
            sendCalls: replayRoute.sendCalls,
            binaryFrames: replayRoute.binaryFrames,
            replyCandidates: replayRoute.replyCandidates,
            serverConnected: replayRoute.server !== null,
            replaySent: replayRoute.replaySent,
          } : null;
          if (!injected) {
            // This diagnostic is deliberately numeric-only and exists only to
            // distinguish a closed socket, a non-binary send, or a header
            // classifier miss in the isolated QA lane.
            console.error(`FAIL native replay capture diagnostics: ${JSON.stringify(replayDebug)}`);
          }
          assert.ok(injected,
            `native replay probe must capture the completed client reply in memory; debug=${JSON.stringify(replayDebug)}`);
          cardWireReplayInjected = true;
          const rejectDeadline = Date.now() + 5000;
          while (Date.now() < rejectDeadline) {
            cardWireReplaySent = replayRoute?.replaySent === true;
            cardWireReplayRejectsAfter = readNativeMappingSummary().choiceRejects;
            if (cardWireReplaySent && cardWireReplayRejectsAfter > cardWireReplayRejectsBefore) break;
            await new Promise((resolve) => setTimeout(resolve, 100));
          }
          cardWireReplaySent = replayRoute?.replaySent === true;
          cardWireReplayRejectsAfter = readNativeMappingSummary().choiceRejects;
          cardWireReplayRejectObserved = cardWireReplayRejectsAfter > cardWireReplayRejectsBefore;
          assert.ok(cardWireReplaySent && cardWireReplayRejectObserved,
            'native replay probe must send the deferred duplicate after a subsequent native request and observe its rejection');
          console.log(`PASS native card-wire replay rejection: choiceRejects=${cardWireReplayRejectsAfter - cardWireReplayRejectsBefore}; original gameplay remained active`);
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
    } else if (deltaXiongsuanScenario) {
      assert.ok(scenarioActiveSkillReply,
        'delta-xiongsuan must complete the native active-skill card/target request');
      assert.ok(scenarioXiongsuanChoiceReply,
        'delta-xiongsuan must answer the native limited-skill reset choice');
      console.log('PASS delta-xiongsuan: native card-filter selection, damage/draw and limited reset reached GameOver');
    } else if (deltaWenjiScenario) {
      assert.ok(scenarioWenjiPlayerReply,
        'delta-wenji must choose the recipient through the native AskForUseActiveSkill request');
      assert.ok(scenarioWenjiCardReply,
        'delta-wenji must give the reserved Slash through the native card-selection request');
      assert.ok(scenarioWenjiUseReply,
        'delta-wenji must use the transferred Slash through the native real-card request');
      const responseRequests = traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard');
      assert.equal(responseRequests.length, 0,
        'delta-wenji must not expose AskForResponseCard after setDisresponsive()');
      console.log('PASS delta-wenji: native recipient/card handoff, transferred Slash use and response suppression reached GameOver');
    } else if (deltaLordWenjiScenario) {
      assert.ok(scenarioLordWenjiGateReply, 'delta-lord-wenji must complete the readiness gate');
      assert.ok(scenarioLordWenjiPlayerReply, 'delta-lord-wenji must choose the upstream gift source');
      assert.ok(scenarioLordWenjiCardReply, 'delta-lord-wenji must receive the native Slash gift');
      assert.ok(scenarioLordWenjiUseReply, 'delta-lord-wenji must use the transferred Slash');
      assert.ok(scenarioLordWenjiReturnReply, 'delta-lord-wenji must return the distinct Peach');
      const responseRequests = traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard');
      assert.equal(responseRequests.length, 0,
        'delta-lord-wenji must not expose AskForResponseCard after setDisresponsive()');
      console.log('PASS delta-lord-wenji: upstream source/gift, disresponsive Slash and distinct-card return reached GameOver');
    } else if (deltaQianceScenario) {
      assert.ok(scenarioQianceCardReply,
        'delta-qiance must use the reserved Duel through the native real-card request');
      assert.ok(scenarioQianceInvokeReply,
        'delta-qiance must invoke the upstream 谦策 CardUsing trigger');
      const responseRequests = traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard');
      assert.equal(responseRequests.length, 0,
        'delta-qiance must not expose AskForResponseCard after qiance setDisresponsive()');
      console.log('PASS delta-qiance: native Duel CardUsing, upstream 谦策 invoke and big-kingdom response suppression reached GameOver');
    } else if (deltaJianchuScenario) {
      assert.ok(scenarioJianchuGateReply,
        'delta-jianchu must complete the native readiness AskForSkillInvoke gate');
      assert.ok(scenarioJianchuUseReply,
        'delta-jianchu must use the reserved Slash through the native real-card request');
      assert.ok(scenarioJianchuInvokeReply,
        'delta-jianchu must invoke the upstream 鞬出 trigger');
      assert.ok(scenarioJianchuCardReply,
        'delta-jianchu must choose the visible target equipment through AskForCardChosen');
      const responseRequests = traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard');
      assert.equal(responseRequests.length, 0,
        'delta-jianchu must not expose AskForResponseCard after Jianchu setDisresponsive()');
      console.log('PASS delta-jianchu: native Slash, equipment discard, 鞬出 invoke and Jink response suppression reached GameOver');
    } else if (deltaTieqiScenario) {
      assert.ok(scenarioTieqiGateReply, 'delta-tieqi must complete the native readiness AskForSkillInvoke gate');
      assert.ok(scenarioTieqiGeneralReply, 'delta-tieqi must choose a real target general through CustomDialog');
      assert.ok(scenarioTieqiUseReply, 'delta-tieqi must use the reserved Slash through the native real-card request');
      assert.ok(scenarioTieqiDiscardReply, 'delta-tieqi must cancel the target suit-discard request');
      assert.equal(traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length, 0,
      'delta-tieqi must not expose AskForResponseCard after the upstream trigger blocks response');
      console.log('PASS delta-tieqi: native general choice, failed-suit discard cancel, Slash damage and response suppression reached GameOver');
    } else if (deltaChujueScenario) {
      assert.ok(scenarioChujueGateReply,
        'delta-chujue must complete the native readiness AskForSkillInvoke gate');
      assert.ok(scenarioChujueDeadFactionUseReply,
        'delta-chujue must use the reserved Slash against the dead-kingdom target');
      assert.ok(scenarioChujueControlFactionUseReply,
        'delta-chujue must use the reserved Slash against the control-kingdom target');
      const responseRequests = traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard');
      assert.equal(responseRequests.length, 0,
        'delta-chujue real clients must not receive a response request for the dead-kingdom branch; the control response is native-bot evidence');
      console.log('PASS delta-chujue: native dead-kingdom response suppression and control-kingdom Jink response reached GameOver');
    } else if (deltaZhenteScenario) {
      assert.ok(scenarioZhenteGateReply, 'delta-zhente must complete the native readiness AskForSkillInvoke gate');
      assert.ok(scenarioZhenteUseReply, 'delta-zhente must use the reserved black Slash through the native real-card request');
      assert.ok(scenarioZhenteInvokeReply, 'delta-zhente must invoke the upstream target skill');
      assert.ok(scenarioZhenteChoiceReply, 'delta-zhente must choose the native target-negate option');
      assert.equal(traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length, 0,
      'delta-zhente must nullify the target before a response request is emitted');
      console.log('PASS delta-zhente: native target invoke, negate choice and black-Slash nullification reached GameOver');
    } else if (deltaHalberdScenario) {
      assert.ok(scenarioHalberdGateReply, 'delta-halberd must complete the native readiness gate');
      assert.ok(scenarioHalberdUseReply, 'delta-halberd must use the reserved Slash against the first target');
      assert.ok(scenarioHalberdExtraTargetReply, 'delta-halberd must select the legal distinct-kingdom extra target');
      assert.equal(traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length, 0,
      'delta-halberd bounded proof must not require a private human response-card request');
      console.log('PASS delta-halberd: native attached weapon, extra-target selection and multi-target Slash reached GameOver');
    } else if (deltaSijianScenario) {
      assert.ok(scenarioSijianGateReply, 'delta-sijian must complete the native readiness gate');
      assert.ok(scenarioSijianTargetReply, 'delta-sijian must choose a real other-player target');
      assert.ok(scenarioSijianCardReply, 'delta-sijian must choose the target hand card through AskForCardChosen');
      console.log('PASS delta-sijian: native empty-hand AfterCardsMove trigger, target selection and discard reached GameOver');
    } else if (deltaFengshiScenario) {
      assert.ok(scenarioFengshiGateReply, 'delta-fengshi must complete the native readiness gate');
      assert.ok(scenarioFengshiSlashReply, 'delta-fengshi must use the reserved first physical Slash');
      assert.equal(traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length, 0,
      'delta-fengshi real clients must not receive a native bot Jink request');
      console.log('PASS delta-fengshi manual requests: first physical Slash reached its exclusive native bot target');
    } else if (deltaBaweiScenario) {
      assert.ok(scenarioBaweiGateReply,
        'delta-bawei must complete the native readiness AskForSkillInvoke gate');
      assert.ok(scenarioBaweiDamagedUseReply && scenarioBaweiControlUseReply,
        'delta-bawei must use both physical Slashes against their respective exclusive targets');
      assert.equal(traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length, 0,
      'delta-bawei real clients must not receive a native bot Jink request');
      console.log('PASS delta-bawei manual requests: damaged and untouched targets were each attacked with a reserved Slash');
    } else if (deltaXisheScenario) {
      assert.ok(scenarioXisheGateReply, 'delta-xishe must complete its native readiness AskForSkillInvoke gate');
      assert.ok(scenarioXisheWeaponReply && scenarioXisheCancelReply && scenarioXisheArmorReply,
        'delta-xishe must discard weapon, cancel the repeated offer and discard armor through three native requests');
      assert.equal(traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length, 0,
      'delta-xishe Jink response must come from the native control bot, not either real client');
      console.log('PASS delta-xishe manual requests: weapon discarded, optional repeat cancelled and armor discarded');
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
    } else if (hiddenEnyuanScenario) {
      assert.ok(hiddenEnyuanGateReply, 'hidden-enyuan must complete the native prelight gate');
      assert.ok(hiddenEnyuanCardReply, 'hidden-enyuan must complete the source Peach target request');
      console.log(`PASS hidden-enyuan: native hidden TargetConfirmed Peach branch revealed Fa Zheng and completed the draw in the ${hiddenEnyuanDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenFuyinScenario) {
      assert.ok(hiddenFuyinGateReply, 'hidden-fuyin must complete the native prelight gate');
      assert.ok(hiddenFuyinCardReply, 'hidden-fuyin must complete the source Slash target request');
      console.log(`PASS hidden-fuyin: native hidden TargetConfirmed Slash branch revealed Zhuge Zhan and nullified the card in the ${hiddenFuyinDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenJilixScenario) {
      assert.ok(hiddenJilixGateReply, 'hidden-jilix must complete the native prelight gate');
      assert.ok(hiddenJilixCardReply, 'hidden-jilix must complete the native red Slash request');
      assert.ok(hiddenJilixChoiceReply, 'hidden-jilix must choose the native remove-general branch');
      console.log(`PASS hidden-jilix: native hidden TargetConfirmed repeated the red Slash, second DamageInflicted was prevented and the owning ${hiddenJilixDeputyScenario ? 'deputy' : 'main'} slot was removed`);
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
    } else if (hiddenEjueScenario) {
      assert.ok(hiddenEjueGateReply, 'hidden-ejue must complete the native prelight gate');
      assert.ok(hiddenEjueDamageReply, 'hidden-ejue must complete the actor Slash request');
      console.log(`PASS hidden-ejue: native hidden DamageCaused branch revealed Zhang Chunhua and added damage against unknown kingdom in the ${hiddenEjueDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenDufuScenario) {
      assert.ok(hiddenDufuGateReply, 'hidden-dufu must complete the native prelight gate');
      assert.ok(hiddenDufuDamageReply, 'hidden-dufu must complete the actor Slash request');
      console.log(`PASS hidden-dufu: native hidden DamageCaused branch revealed Sima Jiong and added damage against a different kingdom in the ${hiddenDufuDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenZhimanScenario) {
      assert.ok(hiddenZhimanGateReply, 'hidden-zhiman must complete the native prelight gate');
      assert.ok(hiddenZhimanDamageReply, 'hidden-zhiman must complete the actor Slash request');
      assert.ok(hiddenZhimanInvoked, 'hidden-zhiman must invoke the prelighted trigger');
      assert.ok(hiddenZhimanCardReply, 'hidden-zhiman must answer the native equipment choice');
      console.log(`PASS hidden-zhiman: native hidden DamageCaused branch revealed Ma Su, prevented damage and obtained equipment in the ${hiddenZhimanDeputyScenario ? 'deputy' : 'main'} slot`);
    } else if (hiddenLuoshenScenario) {
      assert.ok(hiddenLuoshenGateReply, 'hidden-luoshen must complete the native prelight gate');
      assert.ok(hiddenLuoshenInvoked, 'hidden-luoshen must invoke the prelighted phase-start trigger');
      assert.ok(hiddenLuoshenInvokeCount >= 2,
        'hidden-luoshen must expose the readiness gate and the real trigger/continuation invoke');
      assert.ok(hiddenLuoshenAgReply,
        'hidden-luoshen must complete a real AskForAG request after the native AG display path');
      console.log('PASS hidden-luoshen: native hidden EventPhaseStart trigger revealed Zhen Ji, completed judgment continuation and resolved AskForAG');
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
      assert.ok(hiddenDuoshiInvoked,
        'hidden-reveal must invoke the optional native Độ Thế trigger after reveal');
      console.log('PASS hidden-reveal: native reveal_skill& request opened Lục Tốn, activated hidden Qianxun and invoked Độ Thế');
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
    } else if (!hiddenTianduScenario && !hiddenJianzhiScenario && testScenario !== 'rescue-normal' && testScenario !== 'rescue-battle' && testScenario !== 'founding') {
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
    if (boundedAiTraceScenario) {
      // The bounded native probe already requested GameOver; there is no live
      // turn/Trust control to delegate and no result-screen cleanup to drive.
    } else if (!damageExchangeScenario && !hiddenScenario) {
      const cleanupPages = rescueScenario ? pages : [actor];
      for (const page of cleanupPages) {
        await clickTrustAction(page).catch(() => undefined);
      }
    }
  } else if (!boundedAiTraceScenario) {
    await Promise.all(pages.map((page) => clickTrustAction(page)));
  }
  if (testRecovery) {
    const recovering = [a];
    if (testGatewayRestart) {
      assert.ok(gateway);
      const exited = once(gateway,'exit');gateway.kill('SIGTERM');await exited;
      gateway=startGateway();
      assert.equal(transportOpen[1],true,'Independent peer must remain connected during restart');
      console.log('Restarted first client gateway process; second peer keeps its separate gateway connection');
    } else {
      const disconnectState = await a.evaluate(() => {
        const target = window as unknown as {
          __tqsTestDisconnect?: () => {
            socketCount: number; openSocketCount: number; activeReadyState: number;
            candidateReadyState: number; candidateAfterReadyState: number; closed: boolean;
          };
        };
        const hook = target.__tqsTestDisconnect;
        return hook ? { available: true, ...hook() } : {
          available: false,
          socketCount: -1,
          openSocketCount: -1,
          activeReadyState: -1,
          candidateReadyState: -1,
          candidateAfterReadyState: -1,
          closed: false,
        };
      });
      console.log(`Disconnect probe: available=${disconnectState.available}, sockets=${disconnectState.socketCount}, ` +
        `open=${disconnectState.openSocketCount}, activeState=${disconnectState.activeReadyState}, ` +
        `candidateState=${disconnectState.candidateReadyState}, afterState=${disconnectState.candidateAfterReadyState}, ` +
        `closed=${disconnectState.closed}`);
      assert.ok(disconnectState.available,
        'test-only transport disconnect hook must be installed before reconnect verification');
    }
    for (const p of recovering) {
      const client=pages.indexOf(p);
      await p.waitForFunction(() => document.querySelector('.status')?.textContent === 'Đã kết nối', null, { timeout: 120000 });
      for (let n=0;n<120 && !traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect');n++)
        await new Promise(resolve=>setTimeout(resolve,500));
      assert.ok(traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'server must send native Reconnect after transport loss');
      if (cardWireRollbackDrainRequested) {
        const rollbackDeadline = Date.now() + 10000;
        let rollbackSummary = readNativeCardWireRollbackSummary();
        while (rollbackSummary.drainApplied <= cardWireRollbackMarkerBaseline && Date.now() < rollbackDeadline) {
          await new Promise(resolve=>setTimeout(resolve,100));
          rollbackSummary = readNativeCardWireRollbackSummary();
        }
        assert.ok(rollbackSummary.drainApplied > cardWireRollbackMarkerBaseline,
          'QA rollback drain must emit a bounded drain marker after negotiation');
        assert.ok(rollbackSummary.activeRoomProtocolV1 > cardWireRollbackMarkerBaseline &&
          rollbackSummary.newRoomAdmissionLegacy > cardWireRollbackMarkerBaseline &&
          rollbackSummary.reconnectProtocolV1 > cardWireRollbackMarkerBaseline,
        'QA rollback drain marker must retain v1 for the active/reconnect room and legacy for new admission');
        assert.ok(traces[client].filter((packet) =>
          packet.direction === 'incoming' && packet.command === 'CardWireNegotiated').length >= 2,
        'QA rollback drain reconnect must receive a fresh v1 negotiation marker');
        cardWireRollbackDrainObserved = true;
      }
      await p.locator('.board-self').waitFor({timeout:30000});
      await p.waitForFunction((expected)=>document.querySelectorAll('.board-player').length===expected, playerCapacity,{timeout:30000});
      assert.equal(await p.locator('.board-player').count(),playerCapacity);
      assert.equal(await p.locator('.board-player:not(.board-self) [data-card-id]').count(),0);
      await clickTrustAction(p).catch(() => undefined);
    }
    if(testGatewayRestart) {assert.equal(transportOpen[1],true);assert.ok(!traces[1].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'Independent peer must not reconnect');}
    recovered=true;
    console.log(testGatewayRestart ? 'PASS gateway restart: first account reauthenticates/native Reconnect/private board, independent peer stays connected' : 'PASS controlled transport loss: same account automatically authenticates, receives native Reconnect and restores the two-seat board');
  }
  if (observerLeaveRequested) await performObserverLeaveProbe();
  // Founding acceptance ends when the native GeneralShown kingdom choice is
  // answered; that source path intentionally does not end the whole match.
  // Waiting for a result screen here would leave the QA runner playing an
  // unrelated full game after the rule under test has already passed.
  let publicBotAudit = (testBotAudit || damageExchangeScenario || hiddenScenario || deltaChujueScenario || deltaZhenteScenario || deltaHalberdScenario || deltaSijianScenario || deltaBaweiScenario || deltaFengshiScenario || deltaXisheScenario || deltaLordWenjiScenario || deltaTieqiScenario)
    ? boundedAiTraceScenario
      ? pages.map(() => metadataOnlyPublicAudit())
      : (await Promise.all(pages.map(readPublicBotAudit))).map((audit) => sanitizePublicAudit(audit, [first.username, second.username]))
    : [];
  let generalPairTelemetry: GeneralPairTelemetry | null = null;
  if (testScenario === 'founding') {
    finished = true;
  } else if (boundedAiTraceScenario || nativeQaGameOverCompletion) {
    // These are bounded native AI probes, not full matches. The QA director
    // calls GameOver after the fixed-seat makeReply calls, so the runner must
    // not wait for the ordinary result/lobby DOM.
    // An explicit observer-leave probe closes that audience before GameOver;
    // only the two still-live player transports can satisfy the post-leave
    // GameOver boundary.
    const gameOverTraces = observerLeaveRequested ? traces.slice(0, 2) : traces;
    const gameOverDeadline = Date.now() + qaCleanupTimeoutMs;
    while (!gameOverTraces.every((trace) => trace.some((packet) =>
      packet.direction === 'incoming' && packet.command === 'GameOver')) &&
      Date.now() < gameOverDeadline) {
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    assert.ok(gameOverTraces.every((trace) => trace.some((packet) =>
      packet.direction === 'incoming' && packet.command === 'GameOver')),
      'bounded native QA scenario must observe native GameOver on every still-live client');
    finished = true;
  } else {
    await Promise.all(pages.map(p=>p.getByRole('button',{name:'Về sảnh',exact:true}).waitFor({timeout:900000})));
    finished = true;
    if (generalPairMatchScenario) {
      // GameFinished sends the metadata-only QA markers immediately around
      // the native GameOver/result transition. Keep the browser alive for a
      // bounded grace window so a slow UI packet does not turn a completed
      // native match into an unusable win-rate sample.
      const telemetryDeadline = Date.now() + qaCleanupTimeoutMs;
      do {
        publicBotAudit = (await Promise.all(pages.map(readPublicBotAudit)))
          .map((audit) => sanitizePublicAudit(audit, [first.username, second.username]));
        generalPairTelemetry = parseGeneralPairTelemetry(publicBotAudit);
        if (generalPairTelemetry.matchResult && generalPairTelemetry.decisionSummary) break;
        await new Promise((resolve) => setTimeout(resolve, 250));
      } while (Date.now() < telemetryDeadline);
    } else {
      publicBotAudit = (testBotAudit || damageExchangeScenario || hiddenScenario || deltaChujueScenario || deltaZhenteScenario || deltaHalberdScenario || deltaSijianScenario || deltaBaweiScenario || deltaFengshiScenario || deltaXisheScenario || deltaLordWenjiScenario || deltaTieqiScenario)
        ? (await Promise.all(pages.map(readPublicBotAudit))).map((audit) => sanitizePublicAudit(audit, [first.username, second.username]))
        : [];
    }
  }
  if (testBotAudit && !boundedAiTraceScenario) {
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
  if (generalPairMatchScenario && !generalPairTelemetry) {
    generalPairTelemetry = parseGeneralPairTelemetry(publicBotAudit);
  }
  if (generalPairMatchScenario) {
    assert.ok(generalPairTelemetry?.matchResult,
      'general-pair-match must expose the metadata-only PairMatchResult marker');
    assert.ok(generalPairTelemetry?.decisionSummary,
      'general-pair-match must expose the metadata-only PairDecisionSummary marker');
    assert.equal(generalPairTelemetry?.matchResult?.scenario, testScenario);
    assert.equal(generalPairTelemetry?.matchResult?.seed, nativeQaSeed);
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
      askForCardChosen: incoming.filter((packet) => packet.command === 'AskForCardChosen').length,
      askForChoices: incoming.filter((packet) => packet.command === 'AskForChoices').length,
    };
  });
  if (testBotAudit && !boundedAiTraceScenario) {
    assert.equal(playerCapacity, 4, 'Bot audit must be a four-seat room');
    assert.ok(publicBotAudit.every((audit) => audit.logs.length > 0), 'Bot audit must observe public GameLog text');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1), 'Every live client must observe exactly one GameOver');
    assert.ok(botAuditTrace.some((trace) => trace.addSkillUseHistory + trace.setSkillUseHistory > 0),
      'Bot audit must observe native skill-history state updates');
    console.log(`PASS four-seat bot audit: ${pages.length} real clients + ${playerCapacity - pages.length} native bots; ` +
      `${publicBotAudit[0]?.skillLogs.length ?? 0} public skill log(s), ` +
      `${publicBotAudit[0]?.botSkillLogs.length ?? 0} attributed to bot name(s)`);
  }
  if (aiTraceScenario || chooserTraceScenario) {
    assert.equal(playerCapacity, 4, 'ai-trace must run with four fixed seats');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'ai-trace must observe exactly one GameOver per live client');
    console.log(`PASS ${testScenario} live room: fixed four-seat native roster reached GameOver; server metadata is collected from QA logs`);
  }
  if (generalPairTraceScenario) {
    assert.equal(playerCapacity, 4, 'general-pair-trace must run with four fixed seats');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'general-pair-trace must observe exactly one GameOver per live client');
    console.log('PASS general-pair-trace live room: fixed four-seat initial CustomDialog reached GameOver; server trace is collected from QA logs');
  }
  if (generalPairMatchScenario) {
    assert.equal(playerCapacity, 4, `${testScenario} must run with four fixed seats`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      `${testScenario} must observe exactly one GameOver per live client`);
    const resultTitles = await Promise.all(pages.map((page) =>
      page.locator('#result-title').innerText().catch(() => '')));
    assert.ok(resultTitles.every((title) => title.length > 0),
      `${testScenario} must render a result title for both real clients`);
    console.log(`PASS ${testScenario} full match: fixed four-seat initial CustomDialog reached native GameOver/result; ` +
      'winner seats are collected from sanitized native QA logs');
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
  } else if (deltaLordWenjiScenario) {
    assert.ok(publicBotAudit.length === 2 && publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream lord_ex 问计:') &&
      /phase_handoff=true/iu.test(log) && /slash_disresponsive=true/iu.test(log) &&
      /target_jink_retained=true/iu.test(log) && /different_card_returned=true/iu.test(log))),
    'Both real clients must observe the four server-issued lord_ex Wenji proof markers');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-lord-wenji must finish once on both real clients');
    console.log('PASS delta-lord-wenji public audit: both real clients observed phase gift, unanswerable Slash, retained Jink and distinct-card return');
  } else if (deltaChujueScenario) {
    const publicLogs = publicBotAudit.flatMap((audit) => audit.logs);
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /除绝|chujue/iu.test(log) && /dead_kingdom_response_blocked=true/iu.test(log) &&
      /control_response_allowed=true/iu.test(log) && /control_responded=true/iu.test(log))),
      'delta-chujue must expose the sanitized native proof for both response branches to both clients');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-chujue must finish after both native card-use branches');
    assert.ok(publicLogs.some((log) => /target_jink_retained=true/iu.test(log)),
      'delta-chujue public audit must retain the dead-kingdom target Jink marker');
    console.log('PASS delta-chujue public audit: both native clients observed dead-kingdom suppression and control-kingdom Jink response');
  } else if (deltaZhenteScenario) {
    assert.equal(publicBotAudit.length, 2, 'delta-zhente must audit both real clients');
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 贞特:') &&
      /target_confirmed=true/iu.test(log) && /target_response_blocked=true/iu.test(log) &&
      /choice_negate=true/iu.test(log) && /damage=0/iu.test(log))),
      'delta-zhente must expose the sanitized native target-nullification proof to both clients');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-zhente must finish with exactly one native GameOver per real client');
    console.log('PASS delta-zhente public audit: both clients observed target confirmation, negate choice and zero damage');
  } else if (deltaHalberdScenario) {
    assert.equal(publicBotAudit.length, 2, 'delta-halberd must audit both real clients');
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 方天画戟:') &&
      /first_target_confirmed=true/iu.test(log) &&
      /extra_target_confirmed=true/iu.test(log) &&
      /targets_added=true/iu.test(log) && /damage=2/iu.test(log))),
      'delta-halberd must expose the sanitized native extra-target proof to both clients');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-halberd must finish with exactly one native GameOver per real client');
    console.log('PASS delta-halberd public audit: both clients observed the attached weapon and two-target Slash');
  } else if (deltaSijianScenario) {
    assert.equal(publicBotAudit.length, 2, 'delta-sijian must audit both real clients');
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 死谏:') &&
      /owner_empty_after_hand_loss=true/iu.test(log) &&
      /target_confirmed=true/iu.test(log) &&
      /target_card_discarded=true/iu.test(log))),
      'delta-sijian must expose the sanitized empty-hand and target-card discard proof to both clients');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-sijian must finish with exactly one native GameOver per real client');
    console.log('PASS delta-sijian public audit: both real clients observed empty-hand trigger and target-card discard');
  } else if (deltaBaweiScenario) {
    assert.equal(publicBotAudit.length, 2, 'delta-bawei must audit both real clients');
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 霸威:') &&
      /round_damage_recorded=true/iu.test(log) &&
      /damaged_response_blocked=true/iu.test(log) &&
      /damaged_jink_retained=true/iu.test(log) &&
      /control_responded=true/iu.test(log) && /damage=1/iu.test(log))),
      'delta-bawei must expose all server-issued history, selective response and damage proof markers to both clients');
    assert.ok(botAuditTrace.length === 2 && botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-bawei must finish with exactly one native GameOver per real client');
    console.log('PASS delta-bawei public audit: both clients observed round damage, blocked Wei Jink and allowed Shu Jink');
  } else if (deltaFengshiScenario) {
    const expectSiege = testScenario === 'delta-fengshi-siege';
    assert.equal(publicBotAudit.length, 2, 'delta-fengshi must audit both real clients');
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 锋矢:') &&
      /first_use=true/iu.test(log) &&
      new RegExp(`siege_relation=${expectSiege}`, 'iu').test(log) &&
      new RegExp(`response_blocked=${expectSiege}`, 'iu').test(log) &&
      new RegExp(`target_jink_retained=${expectSiege}`, 'iu').test(log) &&
      new RegExp(`target_responded=${!expectSiege}`, 'iu').test(log))),
      `delta-fengshi ${expectSiege ? 'siege' : 'no-siege'} must expose both response branches through the server-issued native marker`);
    assert.ok(botAuditTrace.length === 2 && botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-fengshi must finish with exactly one native GameOver per real client');
    console.log(`PASS ${testScenario} public audit: both clients observed the first Slash and native Jink ${expectSiege ? 'blocked' : 'allowed'}`);
  } else if (deltaXisheScenario) {
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 袭射:') &&
      /lower_hp_blocked=true/iu.test(log) && /target_jink_retained=true/iu.test(log) &&
      /equal_hp_allowed=true/iu.test(log) && /control_responded=true/iu.test(log) &&
      /equip_discarded=2/iu.test(log) && /damage=1/iu.test(log))),
      'delta-xishe must expose every native response/equipment proof marker to both real clients');
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-xishe must finish with exactly one native GameOver per real client');
    console.log('PASS delta-xishe public audit: both clients observed strict lower-HP response blocking and equal-HP native Jink');
  } else if (deltaTieqiScenario) {
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      log.startsWith('[TQS QA] Upstream 铁骑:') &&
      /judge_discard_cancelled=true/iu.test(log) && /response_blocked=true/iu.test(log) &&
      /target_jink_retained=true/iu.test(log) && /damage=1/iu.test(log))),
      'delta-tieqi must expose the sanitized native judge/discard, response and damage proof marker to both clients');
    assert.ok(botAuditTrace.length === 2 && botAuditTrace.every((trace) => trace.gameOver === 1),
      'delta-tieqi must finish with exactly one native GameOver per real client');
    console.log('PASS delta-tieqi public audit: both clients observed failed-suit discard cancellation and blocked Jink response');
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
  } else if (hiddenEnyuanScenario) {
    const expectedPosition = hiddenEnyuanDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Ân Oán|Hidden 恩怨/iu.test(log) && /TargetConfirmed=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở Pháp Chính=true/iu.test(log) &&
      /rút bài=1/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Enyuan TargetConfirmed, reveal and one-card draw in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-enyuan must finish after its native TargetConfirmed/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-enyuan owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].askForUseActiveSkill + botAuditTrace[1 - scenarioClient].playCard >= 1,
      'hidden-enyuan source player must receive the private real-Peach request');
    console.log(`PASS hidden-enyuan public audit: both native clients observed TargetConfirmed, Fa Zheng reveal and one-card draw in the ${expectedPosition} slot`);
  } else if (hiddenFuyinScenario) {
    const expectedPosition = hiddenFuyinDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Phụ Âm|Hidden Phụ Ấm|Hidden 父荫/iu.test(log) && /TargetConfirmed=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /vô hiệu Sát=true/iu.test(log) &&
      /mở Gia Cát Chiêm=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Fuyin TargetConfirmed, reveal and Slash nullification in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-fuyin must finish after its native TargetConfirmed/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-fuyin owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[1 - scenarioClient].playCard + botAuditTrace[1 - scenarioClient].askForUseActiveSkill >= 1,
      'hidden-fuyin source player must receive the private real-Slash request');
    console.log(`PASS hidden-fuyin public audit: both native clients observed TargetConfirmed, Zhuge Zhan reveal and Slash nullification in the ${expectedPosition} slot`);
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
  } else if (hiddenEjueScenario) {
    const expectedPosition = hiddenEjueDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Ách Tuyệt|Hidden 扼绝/iu.test(log) && /DamageCaused=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /sát thương=2/iu.test(log) &&
      /mở tướng=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Ejue DamageCaused, damage+1 and reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-ejue must finish after its native DamageCaused/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-ejue owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-ejue source player must receive the private real-Slash request');
    console.log(`PASS hidden-ejue public audit: both native clients observed DamageCaused, damage+1 and reveal in the ${expectedPosition} slot`);
  } else if (hiddenDufuScenario) {
    const expectedPosition = hiddenDufuDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Độc Phu|Hidden 独夫/iu.test(log) && /DamageCaused=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /sát thương=2/iu.test(log) &&
      /mở tướng=true/iu.test(log) && log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Dufu DamageCaused, damage+1 and reveal in the ${expectedPosition} slot`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-dufu must finish after its native DamageCaused/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 1,
      'hidden-dufu owner must receive the native prelight readiness gate');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-dufu source player must receive the private real-Slash request');
    console.log(`PASS hidden-dufu public audit: both native clients observed DamageCaused, reveal and damage+1 in the ${expectedPosition} slot`);
  } else if (hiddenJianzhiScenario) {
    const expectedPosition = hiddenJianzhiDeputyScenario ? 'phó tướng' : 'chủ tướng';
    // The QA package asserts DamageCaused, lethal damage, discard-all-hand,
    // reward banner and slot before it calls GameOver. The browser-facing
    // audit must therefore match the native public sequence, not the internal
    // [TQS QA] diagnostic sendLog (which is not rendered by this client).
    assert.ok(publicBotAudit.every((audit) => {
      const logs = audit.logs;
      return logs.some((log) => /phát động liễu.*Gian Chí|发 动.*奸志/iu.test(log)) &&
        logs.some((log) => /bỏ liễu 1 lá.*\(Gian Chí\)|弃置.*奸志/iu.test(log)) &&
        logs.some((log) => /đối với .* tạo Thành liễu 1 điểm .*sát thương|造成.*1.*伤害/iu.test(log)) &&
        logs.some((log) => /\bchết, Hung Thủ là .*?(?:Giả Sung|Tư Mã Ý)|死亡.*(?:贾充|司马懿)/iu.test(log)) &&
        logs.some((log) => new RegExp(`Lượng Ra ${expectedPosition} .*Giả Sung|亮出${expectedPosition === 'chủ tướng' ? '主将' : '副将'}.*贾充`, 'iu').test(log));
    }),
      `Both native clients must observe Jianzhi's public trigger, discard, lethal damage, death and ${expectedPosition} reveal`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-jianzhi must finish after its native lethal DamageCaused/effect branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-jianzhi owner must receive the readiness gate and the source-defined trigger invoke');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-jianzhi source player must receive the private real-Slash request');
    console.log(`PASS hidden-jianzhi public audit: both native clients observed lethal DamageCaused, hand discard, triple reward and reveal in the ${expectedPosition} slot`);
  } else if (hiddenZhimanScenario) {
    const expectedPosition = hiddenZhimanDeputyScenario ? 'phó tướng' : 'chủ tướng';
    assert.ok(publicBotAudit.every((audit) => audit.logs.some((log) =>
      /Hidden Chế Man|Hidden 制蛮/iu.test(log) && /DamageCaused=true/iu.test(log) &&
      /ngăn sát thương=true/iu.test(log) && /lấy trang bị=true/iu.test(log) &&
      /SkillEffect=true/iu.test(log) && /mở tướng=true/iu.test(log) &&
      log.includes(`vị trí=${expectedPosition}`))),
      `Both native clients must observe Zhiman DamageCaused prevention, equipment obtain and ${expectedPosition} reveal`);
    assert.ok(botAuditTrace.every((trace) => trace.gameOver === 1),
      'hidden-zhiman must finish after its native DamageCaused/equipment branch');
    assert.ok(botAuditTrace[scenarioClient].askForSkillInvoke >= 2,
      'hidden-zhiman owner must receive the readiness gate and the source-defined trigger invoke');
    assert.ok(botAuditTrace[scenarioClient].askForUseActiveSkill + botAuditTrace[scenarioClient].playCard >= 1,
      'hidden-zhiman source player must receive the private real-Slash request');
    assert.ok(botAuditTrace[scenarioClient].askForCardChosen >= 1,
      'hidden-zhiman source player must receive the target equipment choice');
    console.log(`PASS hidden-zhiman public audit: both native clients observed DamageCaused prevention, equipment obtain and reveal in the ${expectedPosition} slot`);
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
    // Keep private hands and unrevealed generals in the live DOM for the
    // assertion. Full-board screenshots are not safe QA evidence exports.
  }
  for(let i=0;i<2;i++){
    if (testScenario !== 'founding') {
      assert.ok(traces[i].some(t=>t.direction==='incoming' && t.command==='GameOver'));
    }
    const replies=traces[i].filter(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY);
    assert.equal(new Set(replies.map(t=>t.requestId)).size,replies.length,'one reply per request');
    if (testScenario !== 'founding' && !boundedAiTraceScenario && !nativeQaGameOverCompletion) {
      await pages[i].getByRole('button',{name:'Về sảnh',exact:true}).click();
      await pages[i].getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor();
      await pages[i].getByRole('button',{name:'Ngắt kết nối',exact:true}).click();
    }
  }
  if (auditNativeDeck) {
    assert.ok(nativeDeckPrivacy.every((audit) => audit.negotiated && audit.failures === 0) &&
      nativeDeckPrivacy.slice(0, 2).every((audit) => audit.commands.PrepareDrawPile > 0),
    'Native deck privacy requires negotiation and audited PrepareDrawPile on both clients');
    assert.ok(nativeWireCapture.every((capture) => capture.beforePacketDecode &&
      capture.packets > 0 && capture.failures === 0),
    'Native raw-wire capture must audit complete packets before PacketStream decoding');
    assert.ok(nativeWireCapture.every((capture) => capture.hiddenReferenceAudited &&
      capture.hiddenReferenceCollisions === 0),
    'Native raw-wire audit must prove hidden references are not reused across physical audiences');
    assert.ok(nativeSupplementalCapture.every((capture) => capture.beforePacketDecode &&
      capture.packets > 0 && capture.failures === 0 && capture.channels.negotiation > 0),
    'Native supplemental wire capture must audit metadata/public/request channels before PacketStream decoding');
    assert.ok(!testRecovery || nativeDeckPrivacy.some((audit) => audit.commands.Reconnect > 0),
      'Native reconnect privacy requires an audited Reconnect snapshot');
    const missingNativePrivacyCategories = PRIVACY_CATEGORIES.filter((category) =>
      !nativeDeckPrivacy.some((audit) => audit.categoryCounts[category] > 0));
    if (requireAllNativePrivacy && missingNativePrivacyCategories.length > 0) {
      console.error(`Native privacy coverage missing categories=${missingNativePrivacyCategories.join(',')}`);
    }
    assert.ok(!requireAllNativePrivacy || missingNativePrivacyCategories.length === 0,
      `Strict native privacy requires nonempty actual coverage of all twelve exposure groups; missing=${missingNativePrivacyCategories.join(',')}`);
    const missingRawPrivacyCategories = PRIVACY_CATEGORIES.filter((category) =>
      !nativeWireCapture.some((capture) => capture.categoryCounts[category] > 0));
    if (requireAllNativePrivacy && missingRawPrivacyCategories.length > 0) {
      console.error(`Native raw-wire privacy coverage missing categories=${missingRawPrivacyCategories.join(',')}`);
    }
    assert.ok(!requireAllNativePrivacy || missingRawPrivacyCategories.length === 0,
      `Strict native privacy requires nonempty raw-wire coverage of all twelve exposure groups; missing=${missingRawPrivacyCategories.join(',')}`);
  }
  if (capturePacketBytes) {
    assert.ok(nativePacketSizeCapture.every((capture) => capture.beforePacketDecode &&
      capture.packets > 0 && capture.incomingPackets > 0 && capture.outgoingPackets > 0 &&
      capture.failures === 0 && capture.packetBytes.total > 0),
    'Native packet-size capture requires complete inbound and outbound outer-CBOR packets');
  }
  const nativeSemanticCapture = readNativeSemanticSummary();
  if (nativeSemanticRequested) {
    assert.ok(nativeSemanticCapture.records > 0 &&
      nativeSemanticCapture.semanticPassRecords === nativeSemanticCapture.records &&
      nativeSemanticCapture.semanticFailures === 0 &&
      nativeSemanticCapture.outerDecodedRecords === nativeSemanticCapture.records &&
      nativeSemanticCapture.innerDecodedRecords === nativeSemanticCapture.records,
    'Native semantic CBOR proof requires every retained card-wire record to decode and pass the bounded shape audit');
    assert.ok(nativeSemanticCapture.audiences.owner > 0 && nativeSemanticCapture.audiences.opponent > 0,
      'Native semantic CBOR proof requires owner and opponent audience observations');
    assert.ok(nativeSemanticCapture.inboundRecords > 0 && nativeSemanticCapture.scopes['inbound-reply'] > 0 &&
      nativeSemanticCapture.channels.reply > 0,
      'Native semantic CBOR proof requires an actual native inbound client-reply observation');
    assert.ok(nativeSemanticCapture.channels.deck > 0,
      'Native semantic CBOR proof requires an actual native deck-channel observation');
    if (observeNativePrivacy) assert.ok(nativeSemanticCapture.audiences.observer > 0,
      'Native semantic CBOR proof requires an observer audience observation when observer QA is enabled');
  }
  if (cardWireReplayRequested) {
    assert.ok(cardWireReplayInjected && cardWireReplaySent && cardWireReplayRejectObserved &&
      cardWireReplayRejectsAfter > cardWireReplayRejectsBefore,
    'Native card-wire replay probe requires a sent duplicate reply and a bounded native choice rejection');
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`${candidateId}-${testScenario ? `${testScenario}-` : ''}${testGatewayRestart?'gateway-restart':testRecovery?'reconnect':'multiplayer'}-live-${Date.now()}.json`),JSON.stringify(sanitizeQaEvidence({at:new Date().toISOString(),manualCardReply,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,hiddenYijiMode:hiddenYijiScenario ? hiddenYijiMode : null,hiddenGateReply,nativeQaGateSeen,nativeQaGateCommand,nativeQaGateTimeoutMs,nativeQaGateFailureObserved,hiddenYijiAsked,hiddenYijiInvoked,hiddenYijiReply,hiddenJianxiongGateReply,hiddenJianxiongDamageReply,hiddenJianxiongInvoked,hiddenJianxiongChoiceReply,hiddenFankuiGateReply,hiddenFankuiDamageReply,hiddenFankuiChoiceReply,hiddenLuoshenGateReply,hiddenLuoshenInvoked,hiddenLuoshenInvokeCount,hiddenTianduGateReply,hiddenJizhiGateReply,hiddenJizhiCardReply,hiddenJizhiInvoked,hiddenMingshiGateReply,hiddenMingshiCardReply,hiddenGongqingGateReply,hiddenEnyuanGateReply,hiddenEnyuanCardReply,hiddenFuyinGateReply,hiddenFuyinCardReply,hiddenQianxunGateReply,hiddenQianxunCardReply,hiddenKongchengGateReply,hiddenKongchengCardReply,hiddenWeimuGateReply,hiddenWeimuCardReply,hiddenXiaojiGateReply,hiddenXiaojiCardReply,hiddenGuanxingGateReply,hiddenGuanxingInvoked,hiddenGuanxingArrangeReply,hiddenTianxiangGateReply,hiddenTianxiangCardReply,hiddenTianxiangInvoked,hiddenTianxiangChoiceReply,hiddenDuanchangGateReply,hiddenDuanchangChoiceReply,hiddenRevealGateReply,hiddenRevealReply,hiddenActiveGateReply,hiddenActiveReply,hiddenFanjianGateReply,hiddenFanjianReply,hiddenFanjianChoiceReply,hiddenDualGateReply,hiddenDualChooseReply,hiddenDualDiscardReply,hiddenDualDiscardAuto,hiddenDualUseReply,hiddenJianzhiGateReply,hiddenJianzhiDamageReply,hiddenJianzhiInvoked,hiddenZhimanGateReply,hiddenZhimanDamageReply,hiddenZhimanInvoked,hiddenZhimanCardReply,hiddenJilixGateReply,hiddenJilixCardReply,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioBattleRoyalObserved,scenarioFoundingReply,scenarioBoardStates,scenarioSlashReplies,scenarioLongdanDefenseReply,scenarioLongdanAttackReply,scenarioEnyuanReply,scenarioYijiInvoked,scenarioYijiReply,scenarioFankuiInvoked,scenarioFankuiReply,scenarioObservations,damageExchange:damageExchangeScenario ? {public:publicBotAudit,trace:botAuditTrace} : null,hiddenYiji:hiddenYijiScenario ? {mode:hiddenYijiMode,public:publicBotAudit,trace:botAuditTrace} : null,hiddenJianxiong:hiddenJianxiongScenario ? {deputy:hiddenJianxiongDeputyScenario,public:publicBotAudit,trace:botAuditTrace} : null,hiddenFankui:hiddenFankuiScenario ? {deputy:hiddenFankuiDeputyScenario,gate:hiddenFankuiGateReply,damage:hiddenFankuiDamageReply,cardChosen:hiddenFankuiChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenLuoshen:hiddenLuoshenScenario ? {deputy:hiddenLuoshenDeputyScenario,gate:hiddenLuoshenGateReply,invoked:hiddenLuoshenInvoked,invokeCount:hiddenLuoshenInvokeCount,public:publicBotAudit,trace:botAuditTrace} : null,hiddenTiandu:hiddenTianduScenario ? {deputy:hiddenTianduDeputyScenario,gate:hiddenTianduGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenJizhi:hiddenJizhiScenario ? {deputy:hiddenJizhiDeputyScenario,gate:hiddenJizhiGateReply,card:hiddenJizhiCardReply,invoked:hiddenJizhiInvoked,public:publicBotAudit,trace:botAuditTrace} : null,hiddenMingshi:hiddenMingshiScenario ? {deputy:hiddenMingshiDeputyScenario,gate:hiddenMingshiGateReply,card:hiddenMingshiCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenGongqing:hiddenGongqingScenario ? {deputy:hiddenGongqingDeputyScenario,gate:hiddenGongqingGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenEnyuan:hiddenEnyuanScenario ? {deputy:hiddenEnyuanDeputyScenario,gate:hiddenEnyuanGateReply,card:hiddenEnyuanCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenFuyin:hiddenFuyinScenario ? {deputy:hiddenFuyinDeputyScenario,gate:hiddenFuyinGateReply,card:hiddenFuyinCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenJilix:hiddenJilixScenario ? {deputy:hiddenJilixDeputyScenario,gate:hiddenJilixGateReply,card:hiddenJilixCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenQianxun:hiddenQianxunScenario ? {indulgence:hiddenQianxunIndulgenceScenario,deputy:hiddenQianxunDeputyScenario,gate:hiddenQianxunGateReply,card:hiddenQianxunCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenKongcheng:hiddenKongchengScenario ? {deputy:hiddenKongchengDeputyScenario,gate:hiddenKongchengGateReply,card:hiddenKongchengCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenWeimu:hiddenWeimuScenario ? {deputy:hiddenWeimuDeputyScenario,gate:hiddenWeimuGateReply,card:hiddenWeimuCardReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenXiaoji:hiddenXiaojiScenario ? {deputy:hiddenXiaojiDeputyScenario,gate:hiddenXiaojiGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenGuanxing:hiddenGuanxingScenario ? {deputy:hiddenGuanxingDeputyScenario,gate:hiddenGuanxingGateReply,invoked:hiddenGuanxingInvoked,arrange:hiddenGuanxingArrangeReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenTianxiang:hiddenTianxiangScenario ? {deputy:hiddenTianxiangDeputyScenario,gate:hiddenTianxiangGateReply,card:hiddenTianxiangCardReply,invoked:hiddenTianxiangInvoked,choice:hiddenTianxiangChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenDuanchang:hiddenDuanchangScenario ? {deputy:hiddenDuanchangDeputyScenario,gate:hiddenDuanchangGateReply,choice:hiddenDuanchangChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenReveal:hiddenRevealScenario ? {gate: hiddenRevealGateReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenActive:hiddenActiveScenario ? {gate:hiddenActiveGateReply,reply:hiddenActiveReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenFanjian:hiddenFanjianScenario ? {deputy:hiddenFanjianDeputyScenario,gate:hiddenFanjianGateReply,reply:hiddenFanjianReply,choice:hiddenFanjianChoiceReply,public:publicBotAudit,trace:botAuditTrace} : null,hiddenDual:hiddenDualScenario ? {gate:hiddenDualGateReply,choose:hiddenDualChooseReply,discard:hiddenDualDiscardReply || hiddenDualDiscardAuto,discardAuto:hiddenDualDiscardAuto,viewAs:hiddenDualUseReply,public:publicBotAudit,trace:botAuditTrace} : null,botAudit:testBotAudit ? {seatCapacity:playerCapacity,realClientSeats:pages.length,nativeBotSeats:playerCapacity-pages.length,trace:botAuditTrace,public:publicBotAudit} : null,scope:testGatewayRestart ? 'two real accounts / first client isolated gateway process restart / independent second gateway peer / Chrome mobile viewports / Trust; no physical device or hosted restart' : testRecovery ? 'two real accounts / controlled WebSocket close / native server Reconnect / Chrome mobile viewports / no physical network or device' : testBotAudit ? 'four seats / two real accounts / two native bots / public GameLog and skill-history audit / no physical device' : damageExchangeScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / manual replies for both seats; no Trust or physical device' : hiddenYijiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-yiji ${hiddenYijiMode} branch / manual prelight gate; no physical device` : hiddenJianxiongScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden-jianxiong prelight, invoke and obtain-card choice / no physical device' : hiddenFankuiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-fankui ${hiddenFankuiDeputyScenario ? 'deputy' : 'main'} prelight, real damage and source-card choice / no physical device` : hiddenFanjianScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-fanjian ${hiddenFanjianDeputyScenario ? 'deputy' : 'main'} active reveal, Peach gift and target lose-HP choice / no physical device` : hiddenLuoshenScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-luoshen ${hiddenLuoshenDeputyScenario ? 'deputy' : 'main'} prelight, EventPhaseStart and judgment obtain / no physical device` : hiddenTianduScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-tiandu ${hiddenTianduDeputyScenario ? 'deputy' : 'main'} prelight, FinishJudge and judged-card obtain / no physical device` : hiddenJizhiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-jizhi ${hiddenJizhiDeputyScenario ? 'deputy' : 'main'} prelight, Duel CardUsing and draw / no physical device` : hiddenMingshiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-mingshi ${hiddenMingshiDeputyScenario ? 'deputy' : 'main'} prelight, hidden-source Slash and zero damage / no physical device` : hiddenGongqingScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-gongqing ${hiddenGongqingDeputyScenario ? 'deputy' : 'main'} prelight, low/high attack-range damage branches and Pan Jun reveal / no physical device` : hiddenEnyuanScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-enyuan TargetConfirmed Peach draw and Fa Zheng reveal ${hiddenEnyuanDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenFuyinScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-fuyin TargetConfirmed Slash nullification and Zhuge Zhan reveal ${hiddenFuyinDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenJilixScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-jilix TargetConfirmed repeat, second DamageInflicted prevention and correct-slot removal ${hiddenJilixDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenQianxunScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-qianxun ${hiddenQianxunIndulgenceScenario ? 'BeforeCardsMove Indulgence discard mirror' : 'TargetConfirming Snatch cancellation'} ${hiddenQianxunDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenWeimuScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-weimu TargetConfirming black Duel cancellation ${hiddenWeimuDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenXiaojiScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-xiaoji AfterCardsMove equipment loss and draw ${hiddenXiaojiDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenGuanxingScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-guanxing EventPhaseStart reveal and AskForArrangeCards ${hiddenGuanxingDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenTianxiangScenario ? `two real accounts / two Chrome mobile viewports / native C++ / hidden-tianxiang DetermineDamageInflicted heart-card/target choice, lose-HP branch and reveal ${hiddenTianxiangDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenDuanchangScenario ? `two real accounts + two native bots / four-seat C++ / hidden-duanchang fk.Death, killer main-general choice and slot skill loss ${hiddenDuanchangDeputyScenario ? 'deputy' : 'main'} prelight / no physical device` : hiddenRevealScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden reveal_skill& active helper; no physical device' : hiddenActiveScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden active Chế Hành PlayCard / no physical device' : hiddenDualScenario ? 'two real accounts / two Chrome mobile viewports / native C++ / hidden Song Hùng trigger, auto-discard color source and Duel ViewAs; no physical device' : 'two real accounts / two Chrome mobile viewports / native Trust; no physical device', recovered,gatewayRestart:testGatewayRestart,
    hiddenLuoshenAgReply,
    cardWireReplayRequested, cardWireReplayInjected, cardWireReplaySent, cardWireReplayRejectObserved,
    cardWireRollbackDrainRequested, cardWireRollbackDrainObserved,
    cardWireReplayRejectCount: Math.max(0, cardWireReplayRejectsAfter - cardWireReplayRejectsBefore),
    hiddenDuoshiInvoked,
    scenarioWenji: deltaWenjiScenario ? {
      playerReply: scenarioWenjiPlayerReply,
      cardReply: scenarioWenjiCardReply,
      useReply: scenarioWenjiUseReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-wenji')),
    } : null,
    scenarioWenjiScope: deltaWenjiScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream nos_heg__wenji recipient and card handoff, transferred Slash and disresponsive CardUsing / no physical device'
      : null,
    scenarioLordWenji: deltaLordWenjiScenario ? {
      gateReply: scenarioLordWenjiGateReply,
      playerReply: scenarioLordWenjiPlayerReply,
      cardReply: scenarioLordWenjiCardReply,
      useReply: scenarioLordWenjiUseReply,
      returnReply: scenarioLordWenjiReturnReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-lord-wenji')),
      // Public logs can include a viewer's private hand; persist only the
      // bounded native proof marker and count-only transport observations.
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream lord_ex 问计:')),
        boardPlayers: [],
        botNames: [],
        skillLogs: [],
        botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioLordWenjiScope: deltaLordWenjiScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream ld__wenji phase gift, disresponsive Slash, different-card return / no physical device'
      : null,
    scenarioQiance: deltaQianceScenario ? {
      cardReply: scenarioQianceCardReply,
      invokeReply: scenarioQianceInvokeReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-qiance')),
    } : null,
    scenarioQianceScope: deltaQianceScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream ld__qiance CardUsing and big-kingdom Duel response suppression / no physical device'
      : null,
    scenarioJianchu: deltaJianchuScenario ? {
      gateReply: scenarioJianchuGateReply,
      useReply: scenarioJianchuUseReply,
      invokeReply: scenarioJianchuInvokeReply,
      cardReply: scenarioJianchuCardReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-jianchu')),
    } : null,
    scenarioJianchuScope: deltaJianchuScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream hs__pangde Jianchu equipment branch, equipment discard and Jink response suppression / no physical device'
      : null,
    scenarioTieqi: deltaTieqiScenario ? {
      gateReply: scenarioTieqiGateReply,
      generalReply: scenarioTieqiGeneralReply,
      useReply: scenarioTieqiUseReply,
      discardReply: scenarioTieqiDiscardReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-tieqi')),
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 铁骑:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioTieqiScope: deltaTieqiScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream hs__tieqi failed-suit discard cancellation, damage and response suppression / no physical device'
      : null,
    scenarioChujue: deltaChujueScenario ? {
      gateReply: scenarioChujueGateReply,
      deadFactionUseReply: scenarioChujueDeadFactionUseReply,
      controlFactionUseReply: scenarioChujueControlFactionUseReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-chujue')),
      // The browser's ordinary public log also contains each viewer's own
      // initial hand/general text. Keep only the server-issued bounded proof
      // marker in evidence; private card/general details never leave memory.
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 除绝:')),
        boardPlayers: [],
        botNames: [],
        skillLogs: [],
        botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioChujueScope: deltaChujueScenario
      ? 'two real accounts + two native bots / four-seat candidate native C++ / upstream heg__chujue dead-kingdom response suppression versus control-kingdom Jink response / no physical device'
      : null,
    scenarioZhente: deltaZhenteScenario ? {
      gateReply: scenarioZhenteGateReply,
      useReply: scenarioZhenteUseReply,
      invokeReply: scenarioZhenteInvokeReply,
      choiceReply: scenarioZhenteChoiceReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-zhente')),
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 贞特:')),
        boardPlayers: [],
        botNames: [],
        skillLogs: [],
        botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioZhenteScope: deltaZhenteScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream ty_heg__zhente TargetConfirmed black-Slash target nullification / no physical device'
      : null,
    scenarioHalberd: deltaHalberdScenario ? {
      gateReply: scenarioHalberdGateReply,
      useReply: scenarioHalberdUseReply,
      extraTargetReply: scenarioHalberdExtraTargetReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-halberd')),
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 方天画戟:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioHalberdScope: deltaHalberdScenario
      ? 'two real accounts + one native bot / three-seat candidate native C++ / upstream sa__halberd attached weapon, distinct-kingdom extra target and two-target Slash / no physical device'
      : null,
    scenarioSijian: deltaSijianScenario ? {
      gateReply: scenarioSijianGateReply,
      targetReply: scenarioSijianTargetReply,
      cardReply: scenarioSijianCardReply,
      responseRequests: traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-sijian')),
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 死谏:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioSijianScope: deltaSijianScenario
      ? 'two real accounts / two Chrome mobile viewports / candidate native C++ / upstream sijian AfterCardsMove empty-hand trigger, target selection and card discard / no physical device'
      : null,
    scenarioBawei: deltaBaweiScenario ? {
      gateReply: scenarioBaweiGateReply,
      damagedUseReply: scenarioBaweiDamagedUseReply,
      controlUseReply: scenarioBaweiControlUseReply,
      responseRequests: traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-bawei')),
      // The raw public logs can include either viewer's private hand and
      // general names. Retain only the sanitized server-issued proof marker.
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 霸威:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioBaweiScope: deltaBaweiScenario
      ? 'two real accounts + one native bot / three-seat candidate native C++ / upstream m_heg__bawei HistoryRound damage and selective Jink response / no physical device'
      : null,
    scenarioFengshi: deltaFengshiScenario ? {
      variant: testScenario,
      gateReply: scenarioFengshiGateReply,
      slashReply: scenarioFengshiSlashReply,
      responseRequests: traces.flat().filter((packet) =>
        packet.direction === 'incoming' && packet.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-fengshi')),
      // Only persist server-issued public proof; the other logs can contain
      // private hand/general text from the two mobile clients.
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 锋矢:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioFengshiScope: deltaFengshiScenario
      ? 'two real accounts + one native bot / three-seat candidate native C++ / upstream m_heg__fengshi first physical Slash, native siege relation and Jink response / no physical device'
      : null,
    scenarioXishe: deltaXisheScenario ? {
      gateReply: scenarioXisheGateReply,
      weaponReply: scenarioXisheWeaponReply,
      cancelReply: scenarioXisheCancelReply,
      armorReply: scenarioXisheArmorReply,
      responseRequests: traces.flat().filter((trace) =>
        trace.direction === 'incoming' && trace.command === 'AskForResponseCard').length,
      observations: scenarioObservations.filter((observation) => observation.detail?.startsWith('delta-xishe')),
      // Preserve only the server-issued metadata proof, never private cards,
      // general names or raw browser logs in this candidate evidence.
      public: publicBotAudit.map((audit) => ({
        logs: audit.logs.filter((log) => log.startsWith('[TQS QA] Upstream 袭射:')),
        boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [],
      })),
      trace: botAuditTrace,
    } : null,
    scenarioXisheScope: deltaXisheScenario
      ? 'two real accounts + two native bots / four-seat candidate native C++ / upstream ld__xishe equipment discard loop with lower-HP blocked response and equal-HP native Jink / no physical device'
      : null,
    memoryAllocationDiagnosticCounts:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryFaultCount:number}).__tqsMemoryFaultCount))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null))),
    distIndexSha256,candidateIdentity,qaPackageIdentity,qaSourceIdentity,nativeDeckPrivacy:auditNativeDeck ? nativeDeckPrivacy : null,nativeSupplementalCapture:auditNativeDeck ? nativeSupplementalCapture : null,nativePacketSizeCapture:captureNativePackets ? nativePacketSizeCapture : null,nativeSemanticCapture:nativeSemanticCapture,nativeProcessMetrics:readNativeProcessMetrics(),result:errors.length ? 'FAIL' : 'PASS',deploymentUrl:deploymentUrl ?? null,traces,errors,errorContexts}),null,2));
  if (observerLeaveRequested) {
    const observerEvidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-`) && name.includes('-live-'))
      .sort();
    const observerEvidencePath = observerEvidenceFiles.at(-1);
    assert.ok(observerEvidencePath, 'observer leave evidence must exist before lifecycle enrichment');
    const observerEvidence = JSON.parse(readFileSync(
      path.join(out, observerEvidencePath), 'utf8')) as Record<string, unknown>;
    observerEvidence.cardWireObserverLeaveRequested = observerLeaveRequested;
    observerEvidence.cardWireObserverLeaveObserved = cardWireObserverLeaveObserved;
    observerEvidence.cardWireObserverLeaveNativeDisconnect = cardWireObserverLeaveNativeDisconnect;
    writeFileSync(path.join(out, observerEvidencePath), JSON.stringify(
      sanitizeQaEvidence(observerEvidence), null, 2));
  }
  if (cardWireObserverNegative) {
    // Keep the mismatch proof separate from the ordinary privacy artifact so
    // a negative observer never gets mistaken for an audited v1 audience.
    writeCardWireObserverEvidence();
  }
  if (cardWirePlayerNegative) writeCardWirePlayerEvidence();
  if (generalPairMatchScenario) {
    const evidenceFiles = readdirSync(out)
      // Full-match evidence can be written as multiplayer, reconnect, or
      // gateway-restart.  All three variants carry the same public audit
      // payload initially; keep the privacy scrub applied to every variant.
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-`) &&
        (name.includes('-multiplayer-live-') || name.includes('-reconnect-live-') ||
          name.includes('-gateway-restart-live-')))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'general-pair-match evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.generalChoiceCounts = generalChoiceCounts;
    evidence.winrateBranch = winrateBranch;
    evidence.winrateRunId = winrateRunId;
    evidence.nativeQaSeed = nativeQaSeed;
    evidence.initialGeneralCount = initialGeneralCount;
    evidence.matrixInputHash = matrixInputHash;
    evidence.matrixInput = matrixInput ? {
      rosterSet: matrixInput.rosterSet,
      seatSwap: matrixInput.seatSwap,
      enabledKingdoms: matrixInput.enabledKingdoms,
    } : null;
    evidence.generalPairTelemetry = generalPairTelemetry;
    // The full public audit is useful while debugging a manual match, but a
    // win-rate corpus must stay metadata-only. Keep only the QA markers used
    // by the analyzer; do not persist public GameLog/card/general text from
    // either real client in the paired evidence artifact.
    const botAudit = evidence.botAudit;
    if (botAudit && typeof botAudit === 'object' &&
        Array.isArray((botAudit as { public?: unknown }).public)) {
      (botAudit as { public: unknown[] }).public = (botAudit as { public: unknown[] }).public.map((item) => {
        const audit = item && typeof item === 'object' ? item as { logs?: unknown } : {};
        const logs = Array.isArray(audit.logs)
          ? audit.logs.filter((log): log is string => typeof log === 'string' && log.startsWith('[TQS QA] Pair'))
          : [];
        return { logs, boardPlayers: [], botNames: [], skillLogs: [], botSkillLogs: [], humanSkillActors: [] };
      });
    }
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenEnyuanScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(candidateId + '-' + testScenario + '-multiplayer-live-'))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-enyuan evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenEnyuanGateReply = hiddenEnyuanGateReply;
    evidence.hiddenEnyuanCardReply = hiddenEnyuanCardReply;
    evidence.hiddenEnyuan = {
      deputy: hiddenEnyuanDeputyScenario,
      gate: hiddenEnyuanGateReply,
      peach: hiddenEnyuanCardReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = 'two real accounts / two Chrome mobile viewports / native C++ / hidden-enyuan TargetConfirmed Peach draw and Fa Zheng reveal ' +
      (hiddenEnyuanDeputyScenario ? 'deputy' : 'main') + ' prelight / no physical device';
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenFuyinScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-fuyin evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenFuyinGateReply = hiddenFuyinGateReply;
    evidence.hiddenFuyinCardReply = hiddenFuyinCardReply;
    evidence.hiddenFuyin = {
      deputy: hiddenFuyinDeputyScenario,
      gate: hiddenFuyinGateReply,
      slash: hiddenFuyinCardReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = 'two real accounts / two Chrome mobile viewports / native C++ / hidden-fuyin TargetConfirmed Slash nullification and Zhuge Zhan reveal ' +
      (hiddenFuyinDeputyScenario ? 'deputy' : 'main') + ' prelight / no physical device';
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenEjueScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-ejue evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenEjueGateReply = hiddenEjueGateReply;
    evidence.hiddenEjueDamageReply = hiddenEjueDamageReply;
    evidence.hiddenEjue = {
      deputy: hiddenEjueDeputyScenario,
      gate: hiddenEjueGateReply,
      damage: hiddenEjueDamageReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-ejue DamageCaused Slash, unknown-kingdom damage+1 and reveal ${hiddenEjueDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenDufuScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-dufu evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenDufuGateReply = hiddenDufuGateReply;
    evidence.hiddenDufuDamageReply = hiddenDufuDamageReply;
    evidence.hiddenDufu = {
      deputy: hiddenDufuDeputyScenario,
      gate: hiddenDufuGateReply,
      damage: hiddenDufuDamageReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-dufu DamageCaused Slash, different-kingdom damage+1 and reveal ${hiddenDufuDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenJianzhiScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-jianzhi evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenJianzhiGateReply = hiddenJianzhiGateReply;
    evidence.hiddenJianzhiDamageReply = hiddenJianzhiDamageReply;
    evidence.hiddenJianzhiInvoked = hiddenJianzhiInvoked;
    evidence.hiddenJianzhi = {
      deputy: hiddenJianzhiDeputyScenario,
      gate: hiddenJianzhiGateReply,
      damage: hiddenJianzhiDamageReply,
      invoked: hiddenJianzhiInvoked,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-jianzhi lethal DamageCaused Slash, discard-all-hand and triple reward with reveal ${hiddenJianzhiDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (hiddenZhimanScenario) {
    const evidenceFiles = readdirSync(out)
      .filter((name) => name.startsWith(`${candidateId}-${testScenario}-multiplayer-live-`))
      .sort();
    const evidencePath = evidenceFiles.at(-1);
    assert.ok(evidencePath, 'hidden-zhiman evidence file must exist before enrichment');
    const evidence = JSON.parse(readFileSync(path.join(out, evidencePath), 'utf8')) as Record<string, unknown>;
    evidence.hiddenZhimanGateReply = hiddenZhimanGateReply;
    evidence.hiddenZhimanDamageReply = hiddenZhimanDamageReply;
    evidence.hiddenZhimanInvoked = hiddenZhimanInvoked;
    evidence.hiddenZhimanCardReply = hiddenZhimanCardReply;
    evidence.hiddenZhiman = {
      deputy: hiddenZhimanDeputyScenario,
      gate: hiddenZhimanGateReply,
      damage: hiddenZhimanDamageReply,
      invoked: hiddenZhimanInvoked,
      card: hiddenZhimanCardReply,
      public: publicBotAudit,
      trace: botAuditTrace,
    };
    evidence.scope = `two real accounts / two Chrome mobile viewports / native C++ / hidden-zhiman DamageCaused Slash, damage prevention, equipment obtain and reveal ${hiddenZhimanDeputyScenario ? 'deputy' : 'main'} prelight / no physical device`;
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
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
    writeFileSync(path.join(out, evidencePath), JSON.stringify(sanitizeQaEvidence(evidence), null, 2));
  }
  if (testScenario === 'founding') {
    await Promise.all(pages.map((page) => page.close()));
  }
  assert.deepEqual(errors,[]);
  console.log(testScenario === 'founding'
    ? 'PASS both clients: founding choice evidence saved; browser sessions closed after the source choice (no GameOver required by this scenario)'
    : nativeQaGameOverCompletion
      ? `PASS ${testScenario}: bounded native QA interaction reached GameOver on both clients; sanitized trace saved`
    : boundedAiTraceScenario
      ? (generalPairTraceScenario
        ? 'PASS general-pair-trace: native fixed-seat initial CustomDialog reached GameOver; sanitized browser trace saved; server metadata trace is required for the A/B comparison'
        : `PASS ${testScenario}: native fixed-seat decisions reached GameOver; sanitized browser trace saved; server metadata trace is required for the A/B comparison`)
    : generalPairMatchScenario
      ? `PASS ${testScenario}: full native match reached GameOver/result; sanitized browser trace saved; winner seats are collected from native QA logs`
    : 'PASS both clients: real GameOver / result / lobby / clean disconnect; sanitized trace saved');
}catch(e){
  if (e instanceof CardWirePlayerProbeComplete) {
    console.log('PASS native player mismatch probe completed after bounded capability proof; no gameplay/GameOver claim');
  } else if (e instanceof CardWireEntropyProbeComplete) {
    console.log('PASS native CSPRNG failure probe completed after bounded fail-closed rejection; no gameplay/GameOver claim');
  } else {
  console.error('FAIL two-client candidate verification:', (e as Error).name === 'AssertionError' ? 'assertion failed' : 'runner or browser error');
  const runnerLocation = (e as Error).stack?.match(/multiplayer-e2e\/run\.ts:(\d+):(\d+)/u);
  if (runnerLocation) console.error(`Runner source location: run.ts:${runnerLocation[1]}:${runnerLocation[2]}`);
  if (observerPage) console.error('Observer UI metadata:', JSON.stringify(await observerPage.evaluate(() => ({
    gameBoards: document.querySelectorAll('.game-board').length,
    boardPlayers: document.querySelectorAll('.board-player').length,
    roomLists: document.querySelectorAll('.room-list').length,
    errorNotices: document.querySelectorAll('.error-notice').length,
    connected: document.querySelector('.status')?.textContent === 'Đã kết nối',
    playingShell: document.querySelectorAll('.shell-playing').length,
  })).catch(() => null)));
  const feedback:string[]=[];
  for (const p of pages) {
    for (const _message of await p.locator('.error-notice').allTextContents().catch(()=>[])) {
      feedback.push('application-error-notice');
      console.error('Visible application error notice observed');
    }
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`reconnect-failure-${Date.now()}.json`),JSON.stringify(sanitizeQaEvidence({at:new Date().toISOString(),result:'FAIL',candidateId,deploymentUrl:deploymentUrl ?? null,feedback,distIndexSha256,candidateIdentity,qaPackageIdentity,qaSourceIdentity,nativeDeckPrivacy:auditNativeDeck ? nativeDeckPrivacy : null,nativeSupplementalCapture:auditNativeDeck ? nativeSupplementalCapture : null,recovered,scenario:testScenario || null,scenarioClient:testScenario ? scenarioClient : null,nativeQaGateSeen,nativeQaGateCommand,nativeQaGateTimeoutMs,nativeQaGateFailureObserved,cardWireReplayRequested,cardWireReplayInjected,cardWireReplaySent,cardWireReplayRejectObserved,cardWireReplayRejectCount:Math.max(0,cardWireReplayRejectsAfter-cardWireReplayRejectsBefore),cardWireRollbackDrainRequested,cardWireRollbackDrainObserved,scenarioCardChosenReply,scenarioCardChosenHidden,scenarioPoxiReply,scenarioPoxiMultiple,scenarioCardsAndChoiceReply,scenarioActiveSkillReply,scenarioRescueReply,scenarioRescuePeach,scenarioRescueBlocked,scenarioViewAsReply,scenarioFoundingReply,scenarioObservations,traces,errors,
    hiddenLuoshenAgReply,
    nativeWireCapture:auditNativeDeck ? nativeWireCapture : null,nativePacketSizeCapture:captureNativePackets ? nativePacketSizeCapture : null,nativeSemanticCapture:nativeSemanticRequested ? readNativeSemanticSummary() : null,nativeProcessMetrics:readNativeProcessMetrics(),
    memoryAllocationDiagnosticCounts:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryFaultCount?:number}).__tqsMemoryFaultCount ?? 0).catch(()=>0))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null).catch(()=>null))),
    errorContexts,scope:'metadata and numeric heap/callback telemetry only; pending safe GameOver cleanup'}),null,2));
  if(gameStarted && !finished){
    console.error('Preserving the connected test browser and candidate processes while attempting safe GameOver cleanup; no immediate mid-game disconnect');
    for(const p of pages)await clickTrustAction(p, 3000).catch(()=>{});
    // GameOver belongs to the shared room. A disconnected participant may never
    // render the result panel, so do not wait forever for that DOM after a failure.
    const backInLobby = (client:number) => {
      const incoming=traces[client].filter(t=>t.direction==='incoming');
      const lastStart=incoming.reduce((last,t,i)=>t.command==='StartGame'?i:last,-1);
      const lastLobby=incoming.reduce((last,t,i)=>t.command==='EnterLobby'?i:last,-1);
      return lastStart>=0 && lastLobby>lastStart;
    };
    const cleanupDeadline = nativeQa ? Date.now() + qaCleanupTimeoutMs : Number.POSITIVE_INFINITY;
    while (!traces.some(t=>t.some(p=>p.direction==='incoming' && p.command==='GameOver')) &&
      transportOpen.some((open,i)=>open && !backInLobby(i)) && Date.now() < cleanupDeadline)
      await new Promise(resolve=>setTimeout(resolve,1000));
    if (nativeQa && !traces.some(t=>t.some(p=>p.direction==='incoming' && p.command==='GameOver')) &&
      transportOpen.some((open,i)=>open && !backInLobby(i))) {
      console.error(`QA cleanup deadline ${qaCleanupTimeoutMs}ms elapsed; closing only after soft cleanup attempt. The isolated QA runtime must have tempBanTime=0.`);
    }
  }
  process.exitCode=1;
  }
}finally{
  clearInterval(progressTimer);
  await browser?.close();await new Promise<void>(resolve=>server?server.httpServer.close(()=>resolve()):resolve());
  gateway?.kill('SIGTERM');peerGateway?.kill('SIGTERM');
  rmSync(frozenDist,{recursive:true,force:true});
}
