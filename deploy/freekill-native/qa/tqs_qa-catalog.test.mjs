import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import os from 'node:os';

const here = path.dirname(fileURLToPath(import.meta.url));
const packageDir = path.join(here, 'tqs_qa');
const nativeCatalog = JSON.parse(fs.readFileSync(path.join(packageDir, 'catalog.json'), 'utf8'));
const browserCatalogPath = path.resolve(here, '../../../game/web/scripts/real-lua-e2e/qa-scenarios.ts');
const browserCatalog = fs.readFileSync(browserCatalogPath, 'utf8');
const hegemonyModePath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua');
const battleRoyalPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/gamemodes/skills/new_battle_royal.lua');
const gameRulePath = path.resolve(here, '../../../runtime/packages/freekill-core/standard/aux_skills_dir/game_rule.lua');
const yijiSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/yiji.lua');
const luoshenSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/luoshen.lua');
const tianduSkillPath = path.resolve(here, '../../../runtime/packages/freekill-core/standard/pkg/skills/tiandu.lua');
const jizhiSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/jizhi.lua');
const mingshiSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/mingshi.lua');
const gongqingSkillPath = path.resolve(here, '../../../runtime/packages/tenyear/pkg/tenyear_xinghuo/skills/gongqing.lua');
const enyuanSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/power/skills/enyuan.lua');
const fuyinSkillPath = path.resolve(here, '../../../runtime/packages/shzl/pkg/thunder/skills/fuyin.lua');
const qianxunSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/qianxun.lua');
const weimuSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/weimu.lua');
const xiaojiSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/xiaoji.lua');
const guanxingSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/guanxing.lua');
const yingziSkillPath = path.resolve(here, '../../../runtime/packages/standard_ex/pkg/general/skills/yingzi.lua');
const fanjianSkillPath = path.resolve(here, '../../../runtime/packages/standard_ex/pkg/general/skills/fanjian.lua');
const tianxiangSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/tianxiang.lua');
const duanchangSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/duanchang.lua');
const fankuiSkillPath = path.resolve(here, '../../../runtime/packages/freekill-core/standard/pkg/skills/fankui.lua');
const kuangguSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/kuanggu.lua');
const liegongSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/liegong.lua');
const jueqingSkillPath = path.resolve(here, '../../../runtime/packages/yj/pkg/yj2011/skills/jueqing.lua');
const ejueSkillPath = path.resolve(here, '../../../runtime/packages/hegemony/pkg/jin_zqdl/skills/ejue.lua');
const triggerSkillPath = path.resolve(here, '../../../runtime/packages/freekill-core/ltk/core/skill_type/trigger.lua');
const playerPath = path.resolve(here, '../../../runtime/packages/freekill-core/ltk/core/player.lua');
const skillEventPath = path.resolve(here, '../../../runtime/packages/freekill-core/ltk/server/events/skill.lua');
const serverPlayerPath = path.resolve(here, '../../../runtime/packages/freekill-core/ltk/server/serverplayer.lua');
const roomPath = path.resolve(here, '../../../runtime/packages/freekill-core/ltk/server/room.lua');
const nativePackageInstallerPath = path.resolve(here, '../scripts/install-packages.sh');
const nativeInstallVerifierPath = path.resolve(here, '../scripts/verify-install.sh');
const nativeRunServerPath = path.resolve(here, '../scripts/run-server.sh');
const nativeAmd64BootstrapPath = path.resolve(here, '../scripts/bootstrap-amd64.sh');
const nativeLuaRuntimePath = path.resolve(here, '../scripts/lua-runtime.sh');
const nativeFreekillPath = path.resolve(here, '../../../runtime/packages/freekill-core/lua/freekill.lua');

test('native tqs_qa catalog keeps the browser scenario ids, seeds and commands in lockstep', () => {
  for (const scenario of nativeCatalog.scenarios) {
    const key = scenario.id.includes('-') ? `'${scenario.id}'` : scenario.id;
    const match = browserCatalog.match(new RegExp(`${key.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\$&')}: \\{([\\s\\S]*?)\\n  \\},`));
    assert.ok(match, `browser QA catalog is missing ${scenario.id}`);
    const seed = match[1].match(/seed: (0x[0-9a-f]+)/u)?.[1];
    const expectedCommand = match[1].match(/expectedCommand: '([^']+)'/u)?.[1];
    assert.equal(Number(seed), scenario.seed, `${scenario.id} seed drift`);
    assert.equal(expectedCommand, scenario.expectedCommand, `${scenario.id} expected command drift`);
  }
});

test('rescue and founding fixtures stay aligned with native source law', () => {
  const normal = nativeCatalog.scenarios.find(({ id }) => id === 'rescue-normal');
  const battle = nativeCatalog.scenarios.find(({ id }) => id === 'rescue-battle');
  const founding = nativeCatalog.scenarios.find(({ id }) => id === 'founding');
  assert.ok(normal && battle && founding, 'rescue-normal, rescue-battle and founding catalog entries are required');
  assert.equal(normal.cards[0].owner, 'actor', 'ordinary Peach must belong to the external rescuer');
  assert.equal(battle.cards[0].owner, 'target', 'Battle Royal Peach must belong to the dying self-rescuer');
  assert.equal(founding.general, 'heg__jiananfeng');

  const battleRoyal = fs.readFileSync(battleRoyalPath, 'utf8');
  const gameRule = fs.readFileSync(gameRulePath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(battleRoyal, /pattern = "analeptic"/u);
  assert.match(battleRoyal, /trueName == "peach"/u);
  assert.match(battleRoyal, /trueName ~= "peach"/u);
  assert.match(gameRule, /local cardNames = \{"peach"\}/u);
  assert.match(gameRule, /if player == dyingPlayer then[\s\S]*table\.insert\(cardNames, "analeptic"\)/u);
  assert.match(qaInit, /scenario\.trigger == "rescue-battle"[\s\S]*enterBattleRoyalMode\(room\)/u);
  assert.match(qaInit, /scenario\.trigger == "founding"[\s\S]*triggerFounding\(room, state\)/u);
});

test('fazheng-enyuan locks three real Slashes, Longdan conversions and optional reactions', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'fazheng-enyuan');
  assert.ok(scenario, 'fazheng-enyuan catalog entry is required');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.attackSteps.map(({ from, to, amount, mandatorySkills, optionalSkills }) => ({
    from, to, amount, mandatorySkills, optionalSkills,
  })), [
    { from: 'actor', to: 'target', amount: 0, mandatorySkills: [], optionalSkills: [] },
    { from: 'actor', to: 'target', amount: 1, mandatorySkills: ['ld__enyuan'], optionalSkills: [] },
    { from: 'actor', to: 'target', amount: 1, mandatorySkills: ['ld__enyuan'], optionalSkills: [] },
    { from: 'target', to: 'actor', amount: 1, mandatorySkills: [], optionalSkills: ['hs__yiji', 'fankui'] },
  ]);
  assert.deepEqual(scenario.attackSteps[3].expectedInvokedSkills, ['hs__yiji', 'fankui']);
  assert.equal(scenario.cards.filter((card) => card.owner === 'actor' && card.match.trueName === 'slash').length, 3);
  assert.deepEqual(scenario.cards.filter((card) => card.owner === 'target').map((card) => card.match.trueName),
    ['slash', 'jink', 'peach']);
});

test('hidden-yiji locks the hidden Quách Gia prelight branch contract', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'hidden-yiji');
  assert.ok(scenario, 'hidden-yiji catalog entry is required');
  assert.equal(scenario.seed, 0x74d1c0de);
  assert.equal(scenario.trigger, 'hidden-yiji');
  assert.equal(scenario.expectedCommand, 'AskForSkillInvoke');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.cards, []);

  // Keep the catalog assertion tied to the actual source law. The browser
  // fixture may prove the React request/reply path, but it must not be able
  // to make this case pass if the upstream hidden-trigger gate or reveal
  // ordering has drifted.
  const mode = fs.readFileSync(hegemonyModePath, 'utf8');
  const yiji = fs.readFileSync(yijiSkillPath, 'utf8');
  const trigger = fs.readFileSync(triggerSkillPath, 'utf8');
  const player = fs.readFileSync(playerPath, 'utf8');
  const skillEvent = fs.readFileSync(skillEventPath, 'utf8');
  const serverPlayer = fs.readFileSync(serverPlayerPath, 'utf8');

  assert.match(mode, /暗置武将牌没有技能/u);
  assert.match(mode, /不“预亮”的技能不会询问/u);
  assert.match(yiji, /name = "hs__yiji"[\s\S]*yiji:addEffect\(fk\.Damaged/u);
  assert.match(trigger, /target:hasSkill\(self:getSkeleton\(\)\.name\)/u);
  assert.match(player, /self:isFakeSkill\(skill\)[\s\S]*table\.contains\(self\.prelighted_skills, skill\)/u);

  const revealIndex = skillEvent.indexOf('player:revealBySkillName(main_skill.name)');
  const effectCallbackIndex = skillEvent.indexOf('effect_cb()');
  assert.ok(revealIndex >= 0, 'SkillEffect must reveal the hidden general by skill name');
  assert.ok(effectCallbackIndex > revealIndex,
    'SkillEffect must reveal the matching slot before running Yiji effect');

  const revealBySkillName = serverPlayer.slice(serverPlayer.indexOf('function ServerPlayer:revealBySkillName'));
  assert.match(revealBySkillName, /getMark\("__heg_general"\)[\s\S]*revealGeneral\(false\)/u);
  assert.match(revealBySkillName, /getMark\("__heg_deputy"\)[\s\S]*revealGeneral\(true\)/u);
});

test('hidden-rehide-yiji locks prelight retention across reveal and hideGeneral for both slots', () => {
  const expected = {
    'hidden-rehide-yiji': {
      seed: 0x5d6e7fb0,
      actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    },
    'hidden-rehide-yiji-deputy': {
      seed: 0x5d6e7fb1,
      actor: { general: 'hs__simayi', deputy: 'hs__guojia', kingdom: 'wei' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-rehide-yiji', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} command drift`);
    assert.equal(scenario.playerCount, 2, `${id} player count drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu',
    }, `${id} target roster drift`);
    assert.deepEqual(scenario.cards, []);
  }

  const serverPlayer = fs.readFileSync(serverPlayerPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  const hideStart = serverPlayer.indexOf('function ServerPlayer:hideGeneral');
  const hideEnd = serverPlayer.indexOf('\n\n--- 获取下家', hideStart);
  assert.ok(hideStart >= 0 && hideEnd > hideStart, 'ServerPlayer:hideGeneral source not found');
  const hideSource = serverPlayer.slice(hideStart, hideEnd);
  assert.match(hideSource, /handleAddLoseSkills\(self, "-" \.\. sname/u);
  assert.match(hideSource, /self:addFakeSkill\(s\)/u);
  assert.match(serverPlayer, /if table\.contains\(self\.prelighted_skills, skill\) then[\s\S]*doNotify\("PrelightSkill", \{ skill\.name, true \}\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-rehide-yiji"[\s\S]*validateHiddenRehideYijiScenario/u);
  assert.match(qaInit, /state\.rehideAfterYiji = true[\s\S]*triggerHiddenYiji\(room, state\)/u);
  assert.match(qaInit, /state\.actor:hideGeneral\(yijiIsDeputy\)[\s\S]*isFakeSkill\("hs__yiji"\)[\s\S]*isPrelighted\(state\.actor, "hs__yiji"\)/u);
  assert.match(qaInit, /regularDuplicate = table\.contains\(state\.actor\.player_skills, Fk\.skills\.hs__yiji\)/u);
});

test('hidden-jianxiong locks the hidden Cao Cao choice/effect contract', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'hidden-jianxiong');
  assert.ok(scenario, 'hidden-jianxiong catalog entry is required');
  assert.equal(scenario.seed, 0x5d6e7f87);
  assert.equal(scenario.trigger, 'hidden-jianxiong');
  assert.equal(scenario.expectedCommand, 'AskForChoices');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__caocao', deputy: 'hs__simayi', kingdom: 'wei' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.cards, [
    { key: 'jianxiong-card', match: { trueName: 'slash' }, owner: 'target', area: 'hand' },
  ]);
});

test('hidden-fankui locks compulsory Damaged reveal and source-card obtain for both slots', () => {
  const expected = {
    'hidden-fankui': {
      seed: 0x5d6e7f96,
      actor: { general: 'hs__simayi', deputy: 'hs__guojia', kingdom: 'wei' },
    },
    'hidden-fankui-deputy': {
      seed: 0x5d6e7f97,
      actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-fankui', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForCardChosen', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'fankui-damage', match: { trueName: 'slash' }, owner: 'target', area: 'hand' },
      { key: 'fankui-loot', match: { trueName: 'peach' }, owner: 'target', area: 'hand' },
    ]);
  }

  // Fankui is compulsory on fk.Damaged; its only user choice is the source
  // card to obtain. The QA gate is deliberately outside the source-law path
  // and exists only to let the browser prelight the hidden skill first.
  const fankui = fs.readFileSync(fankuiSkillPath, 'utf8');
  assert.match(fankui, /fankui:addEffect\(fk\.Damaged/u);
  assert.match(fankui, /room:askToChooseCard\(player/u);
  assert.match(fankui, /room:obtainCard\(player, card/u);
  assert.doesNotMatch(fankui, /askToSkillInvoke\(player, fankui/u,
    'fankui must not add a second optional invoke gate to the native Damaged trigger');
});

test('hidden-jizhi locks optional CardUsing reveal, invoke and draw for both slots', () => {
  const expected = {
    'hidden-jizhi': {
      seed: 0x5d6e7f9a,
      actor: { general: 'hs__huangyueying', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-jizhi-deputy': {
      seed: 0x5d6e7f9b,
      actor: { general: 'hs__zhaoyun', deputy: 'hs__huangyueying', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-jizhi', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} target roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'jizhi-card', match: { trueName: 'duel' }, owner: 'actor', area: 'hand' },
    ]);
  }

  const jizhi = fs.readFileSync(jizhiSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(jizhi, /name = "hs__jizhi"/u);
  assert.match(jizhi, /jizhi:addEffect\(fk\.CardUsing/u);
  assert.match(jizhi, /data\.card:isCommonTrick\(\)/u);
  assert.match(jizhi, /player:drawCards\(1, jizhi\.name\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-jizhi"[\s\S]*triggerHiddenJizhi\(room, state\)/u);
});

test('hidden-mingshi locks compulsory DamageInflicted reduction from a hidden source', () => {
  const expected = {
    'hidden-mingshi': {
      seed: 0x5d6e7f9c,
      actor: { general: 'hs__kongrong', deputy: 'hs__jiling', kingdom: 'qun' },
    },
    'hidden-mingshi-deputy': {
      seed: 0x5d6e7f9d,
      actor: { general: 'hs__jiling', deputy: 'hs__kongrong', kingdom: 'qun' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-mingshi', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'PlayCard', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu',
    }, `${id} hidden source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'mingshi-damage', match: { trueName: 'slash' }, owner: 'target', area: 'hand' },
    ]);
  }

  const mingshi = fs.readFileSync(mingshiSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(mingshi, /name = "mingshi"/u);
  assert.match(mingshi, /tags = \{ Skill\.Compulsory \}/u);
  assert.match(mingshi, /mingshi:addEffect\(fk\.DamageInflicted/u);
  assert.match(mingshi, /data\.from\.general == "anjiang"/u);
  assert.match(mingshi, /data:changeDamage\(-1\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-mingshi"[\s\S]*triggerHiddenMingshi\(room, state\)/u);
});

test('hidden-gongqing locks both native attack-range damage branches for both slots', () => {
  const expected = {
    'hidden-gongqing': {
      seed: 0x5d6e7fba,
      actor: { general: 'panjun', deputy: 'hs__sunquan', kingdom: 'wu' },
    },
    'hidden-gongqing-deputy': {
      seed: 0x5d6e7fbb,
      actor: { general: 'hs__sunquan', deputy: 'panjun', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-gongqing', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'gongqing-bow', match: { name: 'kylin_bow' }, owner: 'target', area: 'hand' },
    ]);
  }

  const gongqing = fs.readFileSync(gongqingSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(gongqing, /name = "gongqing"/u);
  assert.match(gongqing, /gongqing:addEffect\(fk\.DamageInflicted/u);
  assert.match(gongqing, /data\.from:getAttackRange\(\) > 3/u);
  assert.match(gongqing, /gongqing:addEffect\(fk\.DetermineDamageInflicted/u);
  assert.match(gongqing, /data\.from:getAttackRange\(\) < 3[\s\S]*data\.damage > 1/u);
  assert.match(gongqing, /data:changeDamage\(1\)/u);
  assert.match(gongqing, /data:changeDamage\(1 - data\.damage\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-gongqing"[\s\S]*triggerHiddenGongqing\(room, state\)/u);
  assert.match(qaInit, /hidden-gongqing[\s\S]*Kylin Bow[\s\S]*DamageInflicted/u);
});

test('hidden-enyuan locks TargetConfirmed Peach draw and hidden main/deputy reveal', () => {
  const expected = {
    'hidden-enyuan': {
      seed: 0x5d6e7fc0,
      actor: { general: 'ld__fazheng', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-enyuan-deputy': {
      seed: 0x5d6e7fc1,
      actor: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-enyuan', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'enyuan-peach', match: { trueName: 'peach' }, owner: 'target', area: 'hand' },
    ]);
  }

  const enyuan = fs.readFileSync(enyuanSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(enyuan, /name = "ld__enyuan"/u);
  assert.match(enyuan, /tags = \{ Skill\.Compulsory \}/u);
  assert.match(enyuan, /enyuan:addEffect\(fk\.TargetConfirmed/u);
  assert.match(enyuan, /data\.card\.trueName == "peach"/u);
  assert.match(enyuan, /data\.from ~= player/u);
  assert.match(enyuan, /data\.from:drawCards\(1, enyuan\.name\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-enyuan"[\s\S]*triggerHiddenEnyuan\(room, state\)/u);
  assert.match(qaInit, /skill_name = "tqs_qa_hidden_enyuan_peach"[\s\S]*fix_targets = \{ state\.actor\.id \}/u);
  assert.match(qaInit, /director:addEffect\(fk\.TargetConfirmed[\s\S]*hiddenEnyuanTargetConfirmed = true/u);
  assert.match(qaInit, /move\.skillName == "ld__enyuan"[\s\S]*hiddenEnyuanDrawCount/u);
});

test('hidden-fuyin locks TargetConfirmed Slash nullification and hidden main/deputy reveal', () => {
  const expected = {
    'hidden-fuyin': {
      seed: 0x5d6e7fc2,
      actor: { general: 'zhugezhan', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-fuyin-deputy': {
      seed: 0x5d6e7fc3,
      actor: { general: 'hs__zhaoyun', deputy: 'zhugezhan', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-fuyin', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'PlayCard', `${id} source-card command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'fuyin-slash', match: { trueName: 'slash' }, owner: 'target', area: 'hand' },
    ]);
  }

  const fuyin = fs.readFileSync(fuyinSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(fuyin, /name = "fuyin"/u);
  assert.match(fuyin, /tags = \{Skill\.Compulsory\}/u);
  assert.match(fuyin, /fuyin:addEffect\(fk\.TargetConfirmed/u);
  assert.match(fuyin, /data\.card\.trueName\)/u);
  assert.match(fuyin, /data\.from:getHandcardNum\(\) < player:getHandcardNum\(\)/u);
  assert.match(fuyin, /data\.nullified = true/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-fuyin"[\s\S]*state\.hiddenFuyinPending = true/u);
  assert.match(qaInit, /director:addEffect\(fk\.EventPhaseStart[\s\S]*state\.hiddenFuyinPending[\s\S]*data\.phase == Player\.Start[\s\S]*triggerHiddenFuyin\(player\.room, state\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-fuyin"[\s\S]*for _ = 1, 4 do[\s\S]*trueName = "jink"/u);
  assert.match(qaInit, /skill_name = "tqs_qa_hidden_fuyin_damage"[\s\S]*exclusive_targets = \{ state\.actor\.id \}/u);
  assert.match(qaInit, /director:addEffect\(fk\.TargetConfirmed[\s\S]*hiddenFuyinTargetConfirmed = true/u);
  assert.match(qaInit, /hiddenFuyinNullified = data\.nullified == true/u);
});

test('hidden-qianxun locks TargetConfirming cancellation for both slots', () => {
  const expected = {
    'hidden-qianxun': {
      seed: 0x5d6e7f9e,
      actor: { general: 'hs__luxun', deputy: 'hs__sunquan', kingdom: 'wu' },
    },
    'hidden-qianxun-deputy': {
      seed: 0x5d6e7f9f,
      actor: { general: 'hs__sunquan', deputy: 'hs__luxun', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-qianxun', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} Snatch source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'qianxun-snatch', match: { trueName: 'snatch' }, owner: 'target', area: 'hand' },
      { key: 'qianxun-victim', match: { trueName: 'peach' }, owner: 'actor', area: 'hand' },
    ]);
  }

  const qianxun = fs.readFileSync(qianxunSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(qianxun, /name = "hs__qianxun"/u);
  assert.match(qianxun, /tags = \{Skill\.Compulsory\}/u);
  assert.match(qianxun, /qianxun:addEffect\(fk\.TargetConfirming/u);
  assert.match(qianxun, /data\.card\.trueName == "snatch"/u);
  assert.match(qianxun, /data:cancelTarget\(player\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-qianxun"[\s\S]*triggerHiddenQianxun\(room, state\)/u);
});

test('hidden-qianxun locks BeforeCardsMove cancellation of Indulgence for both slots', () => {
  const expected = {
    'hidden-qianxun-indulgence': {
      seed: 0x5d6e7fa0,
      actor: { general: 'hs__luxun', deputy: 'hs__sunquan', kingdom: 'wu' },
    },
    'hidden-qianxun-indulgence-deputy': {
      seed: 0x5d6e7fa1,
      actor: { general: 'hs__sunquan', deputy: 'hs__luxun', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-qianxun', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} Indulgence source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'qianxun-indulgence', match: { trueName: 'indulgence' }, owner: 'target', area: 'hand' },
    ]);
  }

  const qianxun = fs.readFileSync(qianxunSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(qianxun, /qianxun:addEffect\(fk\.BeforeCardsMove/u);
  assert.match(qianxun, /move\.toArea == Card\.PlayerJudge/u);
  assert.match(qianxun, /c\.trueName == "indulgence"/u);
  assert.match(qianxun, /player\.room:cancelMove\(data/u);
  assert.match(qianxun, /mirror_move\.toArea = Card\.DiscardPile/u);
  assert.match(qaInit, /hidden-qianxun-indulgence[\s\S]*qianxun-indulgence/u);
});

test('hidden-kongcheng locks empty-hand TargetConfirming cancellation for both slots', () => {
  const expected = {
    'hidden-kongcheng': {
      seed: 0x5d6e7fa2,
      actor: { general: 'hs__zhugeliang', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-kongcheng-deputy': {
      seed: 0x5d6e7fa3,
      actor: { general: 'hs__zhaoyun', deputy: 'hs__zhugeliang', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-kongcheng', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} Duel source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'kongcheng-duel', match: { trueName: 'duel' }, owner: 'target', area: 'hand' },
    ]);
  }

  const kongcheng = fs.readFileSync(path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/skills/kongcheng.lua'), 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(kongcheng, /name = "hs__kongcheng"/u);
  assert.match(kongcheng, /player:isKongcheng()/u);
  assert.match(kongcheng, /kongcheng:addEffect\(fk\.TargetConfirming/u);
  assert.match(kongcheng, /data\.card\.trueName == "slash" or data\.card\.name == "duel"/u);
  assert.match(kongcheng, /data:cancelTarget\(player\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-kongcheng"[\s\S]*triggerHiddenKongcheng\(room, state\)/u);
});

test('hidden-weimu locks black Trick TargetConfirming cancellation for both slots', () => {
  const expected = {
    'hidden-weimu': {
      seed: 0x5d6e7fa4,
      actor: { general: 'hs__jiaxu', deputy: 'hs__pangde', kingdom: 'qun' },
    },
    'hidden-weimu-deputy': {
      seed: 0x5d6e7fa5,
      actor: { general: 'hs__pangde', deputy: 'hs__jiaxu', kingdom: 'qun' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-weimu', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} black Duel source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'weimu-duel', match: { trueName: 'duel', color: 'black' }, owner: 'target', area: 'hand' },
    ]);
  }

  const weimu = fs.readFileSync(weimuSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(weimu, /name = "hs__weimu"/u);
  assert.match(weimu, /tags = \{Skill\.Compulsory\}/u);
  assert.match(weimu, /weimu:addEffect\(fk\.TargetConfirming/u);
  assert.match(weimu, /data\.card\.color == Card\.Black/u);
  assert.match(weimu, /data\.card\.type == Card\.TypeTrick/u);
  assert.match(weimu, /data:cancelTarget\(player\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-weimu"[\s\S]*triggerHiddenWeimu\(room, state\)/u);
});

test('hidden-weimu locks black delayed Trick BeforeCardsMove cancellation for both slots', () => {
  const expected = {
    'hidden-weimu-indulgence': {
      seed: 0x5d6e7fa6,
      actor: { general: 'hs__jiaxu', deputy: 'hs__pangde', kingdom: 'qun' },
    },
    'hidden-weimu-indulgence-deputy': {
      seed: 0x5d6e7fa7,
      actor: { general: 'hs__pangde', deputy: 'hs__jiaxu', kingdom: 'qun' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-weimu', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} black Indulgence source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'weimu-indulgence', match: { trueName: 'indulgence', color: 'black' }, owner: 'target', area: 'hand' },
    ]);
  }

  const weimu = fs.readFileSync(weimuSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(weimu, /weimu:addEffect\(fk\.BeforeCardsMove/u);
  assert.match(weimu, /move\.toArea == Card\.PlayerJudge/u);
  assert.match(weimu, /c\.sub_type == Card\.SubtypeDelayedTrick/u);
  assert.match(weimu, /c\.color == Card\.Black/u);
  assert.match(weimu, /player\.room:cancelMove/u);
  assert.match(weimu, /mirror_move\.toArea = Card\.DiscardPile/u);
  assert.match(qaInit, /hidden-weimu-indulgence[\s\S]*weimu-indulgence/u);
  assert.match(qaInit, /before_cards_move=black_indulgence/u);
});

test('hidden-xiaoji locks equipment-loss AfterCardsMove draw for both slots', () => {
  const expected = {
    'hidden-xiaoji': {
      seed: 0x5d6e7fa8,
      actor: { general: 'hs__sunshangxiang', deputy: 'hs__sunquan', kingdom: 'wu' },
    },
    'hidden-xiaoji-deputy': {
      seed: 0x5d6e7fa9,
      actor: { general: 'hs__sunquan', deputy: 'hs__sunshangxiang', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-xiaoji', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'xiaoji-equip', match: { type: 'equip' }, owner: 'actor', area: 'equip' },
    ]);
  }

  const xiaoji = fs.readFileSync(xiaojiSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(xiaoji, /name = "hs__xiaoji"/u);
  assert.match(xiaoji, /xiaoji:addEffect\(fk\.AfterCardsMove/u);
  assert.match(xiaoji, /info\.fromArea == Card\.PlayerEquip/u);
  assert.match(xiaoji, /player:drawCards\(player\.room\.current == player and 1 or 3, xiaoji\.name\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-xiaoji"[\s\S]*triggerHiddenXiaoji\(room, state\)/u);
  assert.match(qaInit, /after_cards_move=equipment/u);
});

test('hidden-guanxing locks EventPhaseStart reveal and native arrange for both slots', () => {
  const expected = {
    'hidden-guanxing': {
      seed: 0x5d6e7faa,
      actor: { general: 'hs__zhugeliang', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-guanxing-deputy': {
      seed: 0x5d6e7fab,
      actor: { general: 'hs__zhaoyun', deputy: 'hs__zhugeliang', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-guanxing', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} source roster drift`);
    assert.deepEqual(scenario.cards, []);
  }

  const guanxing = fs.readFileSync(guanxingSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(guanxing, /name = "hs__guanxing"/u);
  assert.match(guanxing, /guanxing:addEffect\(fk\.EventPhaseStart/u);
  assert.match(guanxing, /player\.phase == Player\.Start/u);
  assert.match(guanxing, /room:askToGuanxing\(player/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-guanxing"[\s\S]*triggerHiddenGuanxing\(room, state\)/u);
  assert.match(qaInit, /hidden-guanxing[\s\S]*AskForArrangeCards/iu);
});

test('hidden-yingzi locks compulsory DrawNCards reveal and extra draw for both slots', () => {
  const expected = {
    'hidden-yingzi': {
      seed: 0x5d6e7fb2,
      actor: { general: 'hs__zhouyu', deputy: 'hs__daqiao', kingdom: 'wu' },
    },
    'hidden-yingzi-deputy': {
      seed: 0x5d6e7fb3,
      actor: { general: 'hs__daqiao', deputy: 'hs__zhouyu', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-yingzi', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} readiness command drift`);
    assert.equal(scenario.playerCount, 2, `${id} player count drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} source roster drift`);
    assert.deepEqual(scenario.cards, []);
  }

  const yingzi = fs.readFileSync(yingziSkillPath, 'utf8');
  const hegemonyStandard = fs.readFileSync(
    path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/init.lua'), 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(yingzi, /name = "ex__yingzi"/u);
  assert.match(yingzi, /tags = \{ Skill\.Compulsory \}/u);
  assert.match(yingzi, /yingzi:addEffect\(fk\.DrawNCards/u);
  assert.match(yingzi, /data\.n = data\.n \+ 1/u);
  assert.match(hegemonyStandard, /hs__zhouyu[\s\S]*addSkills\{ "ex__yingzi", "ex__fanjian" \}/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-yingzi"[\s\S]*triggerHiddenYingzi\(room, state\)/u);
  assert.match(qaInit, /hidden-yingzi[\s\S]*fk\.AfterDrawNCards[\s\S]*after_draw_n/u);
});

test('hidden-tianxiang locks damage redirect, card/target selection and reveal for both slots', () => {
  const expected = {
    'hidden-tianxiang': {
      seed: 0x5d6e7fac,
      actor: { general: 'hs__xiaoqiao', deputy: 'hs__sunquan', kingdom: 'wu' },
    },
    'hidden-tianxiang-deputy': {
      seed: 0x5d6e7fad,
      actor: { general: 'hs__sunquan', deputy: 'hs__xiaoqiao', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-tianxiang', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'tianxiang-heart', match: { suit: 'heart' }, owner: 'actor', area: 'hand' },
    ]);
  }

  const tianxiang = fs.readFileSync(tianxiangSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(tianxiang, /name = "hs__tianxiang"/u);
  assert.match(tianxiang, /tianxiang:addEffect\(fk\.DetermineDamageInflicted/u);
  assert.match(tianxiang, /pattern = ".\|\.\|heart\|hand"/u);
  assert.match(tianxiang, /room:askToChooseCardsAndPlayers/u);
  assert.match(tianxiang, /room:throwCard/u);
  assert.match(tianxiang, /room:loseHp/u);
  assert.match(tianxiang, /room:obtainCard/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-tianxiang"[\s\S]*triggerHiddenTianxiang\(room, state\)/u);
  assert.match(qaInit, /determine_damage_inflicted=true[\s\S]*choice=lose_hp/iu);
});

test('hidden-duanchang locks compulsory Death choice and chosen-slot skill loss for both slots', () => {
  const expected = {
    'hidden-duanchang': {
      seed: 0x5d6e7fae,
      actor: { general: 'hs__caiwenji', deputy: 'hs__yuanshao', kingdom: 'qun' },
    },
    'hidden-duanchang-deputy': {
      seed: 0x5d6e7faf,
      actor: { general: 'hs__yuanshao', deputy: 'hs__caiwenji', kingdom: 'qun' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-duanchang', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForChoices', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 4, `${id} must reserve four seats before fk.Death`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__caocao', deputy: 'hs__simayi', kingdom: 'wei',
    }, `${id} killer roster drift`);
    assert.deepEqual(scenario.cards, []);
  }

  const duanchang = fs.readFileSync(duanchangSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(duanchang, /name = "hs__duanchang"/u);
  assert.match(duanchang, /duanchang:addEffect\(fk\.Death/u);
  assert.match(duanchang, /player:hasSkill\(duanchang\.name, false, true\)/u);
  assert.match(duanchang, /room:askToChoice/u);
  assert.match(duanchang, /room:handleAddLoseSkills/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-duanchang"[\s\S]*triggerHiddenDuanchang\(room, state\)/u);
  assert.match(qaInit, /hidden-duanchang[\s\S]*AskForChoices/iu);
});

test('hidden-reveal locks the hidden compulsory active reveal contract', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'hidden-reveal');
  assert.ok(scenario, 'hidden-reveal catalog entry is required');
  assert.equal(scenario.seed, 0x5d6e7f81);
  assert.equal(scenario.trigger, 'hidden-reveal');
  assert.equal(scenario.expectedCommand, 'AskForUseActiveSkill');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__luxun', deputy: 'hs__sunquan', kingdom: 'wu' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.cards, []);
});

test('hidden-active locks native PlayCard reveal-before-SkillEffect contract', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'hidden-active');
  assert.ok(scenario, 'hidden-active catalog entry is required');
  assert.equal(scenario.seed, 0x5d6e7f82);
  assert.equal(scenario.trigger, 'hidden-active');
  assert.equal(scenario.expectedCommand, 'PlayCard');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__luxun', deputy: 'hs__sunquan', kingdom: 'wu' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.cards, [
    { key: 'zhiheng-card', match: { trueName: 'slash' }, owner: 'actor', area: 'hand' },
  ]);
});

test('hidden-fanjian locks active PlayCard reveal, gift and target-choice contract for both slots', () => {
  const expected = {
    'hidden-fanjian': {
      seed: 0x5d6e7fb4,
      actor: { general: 'hs__zhouyu', deputy: 'hs__daqiao', kingdom: 'wu' },
    },
    'hidden-fanjian-deputy': {
      seed: 0x5d6e7fb5,
      actor: { general: 'hs__daqiao', deputy: 'hs__zhouyu', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-fanjian', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'PlayCard', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2, `${id} player-count drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.players.target, {
      general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei',
    }, `${id} source roster drift`);
    assert.deepEqual(scenario.cards, [
      { key: 'fanjian-card', match: { trueName: 'peach' }, owner: 'actor', area: 'hand' },
      { key: 'fanjian-target-card', match: { trueName: 'jink' }, owner: 'target', area: 'hand' },
    ]);
  }

  const fanjian = fs.readFileSync(fanjianSkillPath, 'utf8');
  const hegemonyStandard = fs.readFileSync(
    path.resolve(here, '../../../runtime/packages/hegemony/pkg/standard/init.lua'), 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(fanjian, /name = "ex__fanjian"/u);
  assert.match(fanjian, /fanjian:addEffect\("active"/u);
  assert.match(fanjian, /usedSkillTimes\(fanjian\.name, Player\.HistoryPhase\)/u);
  assert.match(fanjian, /room:obtainCard\(target, cid/u);
  assert.match(fanjian, /room:askToChoice\(target/u);
  assert.match(fanjian, /room:loseHp\(target, 1, fanjian\.name\)/u);
  assert.match(hegemonyStandard, /hs__zhouyu[\s\S]*addSkills\{ "ex__yingzi", "ex__fanjian" \}/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-fanjian"[\s\S]*triggerHiddenFanjian\(room, state\)/u);
  assert.match(qaInit, /hidden-fanjian[\s\S]*SkillEffect[\s\S]*ex__fanjian/iu);
});

test('hidden slot mirrors lock main/deputy placement instead of relying on one roster order', () => {
  const expected = {
    'hidden-yiji-deputy': {
      trigger: 'hidden-yiji',
      actor: { general: 'hs__simayi', deputy: 'hs__guojia', kingdom: 'wei' },
    },
    'hidden-rehide-yiji': {
      trigger: 'hidden-rehide-yiji',
      actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    },
    'hidden-rehide-yiji-deputy': {
      trigger: 'hidden-rehide-yiji',
      actor: { general: 'hs__simayi', deputy: 'hs__guojia', kingdom: 'wei' },
    },
    'hidden-jianxiong-deputy': {
      trigger: 'hidden-jianxiong',
      actor: { general: 'hs__simayi', deputy: 'hs__caocao', kingdom: 'wei' },
    },
    'hidden-reveal-deputy': {
      trigger: 'hidden-reveal',
      actor: { general: 'hs__sunquan', deputy: 'hs__luxun', kingdom: 'wu' },
    },
    'hidden-active-main': {
      trigger: 'hidden-active',
      actor: { general: 'hs__sunquan', deputy: 'hs__luxun', kingdom: 'wu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.trigger, contract.trigger, `${id} trigger drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
  }
});

test('hidden ViewAsSkill mirrors locked Longdan conversion and reveal slot', () => {
  const expected = {
    'hidden-view-as': {
      actor: { general: 'hs__guanyu', deputy: 'hs__zhaoyun', kingdom: 'shu' },
      card: { key: 'longdan-card', match: { trueName: 'jink' }, owner: 'actor', area: 'hand' },
    },
    'hidden-view-as-main': {
      actor: { general: 'hs__zhaoyun', deputy: 'hs__guanyu', kingdom: 'shu' },
      card: { key: 'longdan-card', match: { trueName: 'jink' }, owner: 'actor', area: 'hand' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.trigger, 'hidden-view-as', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'PlayCard', `${id} command drift`);
    assert.deepEqual(scenario.players.actor, contract.actor, `${id} actor slot drift`);
    assert.deepEqual(scenario.cards, [contract.card], `${id} card contract drift`);
  }
});

test('hidden dual skill locks trigger prelight, color source and ViewAs Duel contract', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'hidden-dual');
  assert.ok(scenario, 'hidden-dual catalog entry is required');
  assert.equal(scenario.seed, 0x5d6e7f95);
  assert.equal(scenario.trigger, 'hidden-dual');
  assert.equal(scenario.expectedCommand, 'AskForSkillInvoke');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__yanliangwenchou', deputy: 'hs__yuanshao', kingdom: 'qun' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.cards, [
    { key: 'shuangxiong-card', match: { trueName: 'slash', color: 'black' }, owner: 'actor', area: 'hand' },
    { key: 'shuangxiong-discard', match: { trueName: 'jink', color: 'red' }, owner: 'target', area: 'hand' },
  ]);
});

test('hidden-luoshen locks phase-start prelight, reveal and judgment obtain for both slots', () => {
  const expected = {
    'hidden-luoshen': {
      seed: 0x5d6e7f98,
      actor: { general: 'hs__zhenji', deputy: 'hs__simayi', kingdom: 'wei' },
    },
    'hidden-luoshen-deputy': {
      seed: 0x5d6e7f99,
      actor: { general: 'hs__simayi', deputy: 'hs__zhenji', kingdom: 'wei' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-luoshen', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, []);
  }

  const luoshen = fs.readFileSync(luoshenSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(luoshen, /luoshen:addEffect\(fk\.EventPhaseStart/u);
  assert.match(luoshen, /room:judge\(judge\)/u);
  assert.match(luoshen, /room:askToSkillInvoke\(player/u);
  assert.match(luoshen, /room:moveCardTo\(cards, Card\.PlayerHand/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-luoshen"[\s\S]*triggerHiddenLuoshen\(room, state\)/u);
});

test('hidden-tiandu locks FinishJudge obtain and reveal-before-effect for both slots', () => {
  const expected = {
    'hidden-tiandu': {
      seed: 0x5d6e7fb6,
      actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    },
    'hidden-tiandu-deputy': {
      seed: 0x5d6e7fb7,
      actor: { general: 'hs__simayi', deputy: 'hs__guojia', kingdom: 'wei' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-tiandu', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, []);
  }

  const tiandu = fs.readFileSync(tianduSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(tiandu, /tiandu:addEffect\(fk\.FinishJudge/u);
  assert.match(tiandu, /target == player and player:hasSkill\(tiandu\.name\)/u);
  assert.match(tiandu, /getCardArea\(data\.card\) == Card\.Processing/u);
  assert.match(tiandu, /obtainCard\(player, data\.card, true, fk\.ReasonJustMove, player, tiandu\.name\)/u);
  const skillEvent = fs.readFileSync(skillEventPath, 'utf8');
  const revealIndex = skillEvent.indexOf('player:revealBySkillName(main_skill.name)');
  const effectCallbackIndex = skillEvent.indexOf('effect_cb()');
  assert.ok(revealIndex >= 0, 'SkillEffect must reveal the hidden general by skill name before Tiandu');
  assert.ok(effectCallbackIndex > revealIndex,
    'SkillEffect must reveal the matching slot before running the FinishJudge effect');
  assert.match(qaInit, /scenario\.trigger == "hidden-tiandu"[\s\S]*triggerHiddenTiandu\(room, state\)/u);
});

test('hidden-kuanggu locks close-range Damage marker, choice and reveal-before-effect for both slots', () => {
  const expected = {
    'hidden-kuanggu': {
      seed: 0x5d6e7fb8,
      actor: { general: 'hs__weiyan', deputy: 'hs__huangzhong', kingdom: 'shu' },
    },
    'hidden-kuanggu-deputy': {
      seed: 0x5d6e7fb9,
      actor: { general: 'hs__huangzhong', deputy: 'hs__weiyan', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-kuanggu', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'kuanggu-card', match: { trueName: 'slash' }, owner: 'actor', area: 'hand' },
      { key: 'kuanggu-target-card', match: { trueName: 'peach' }, owner: 'target', area: 'hand' },
    ]);
  }

  const kuanggu = fs.readFileSync(kuangguSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(kuanggu, /name = "hs__kuanggu"/u);
  assert.match(kuanggu, /kuanggu:addEffect\(fk\.Damage/u);
  assert.match(kuanggu, /data\.extra_data.*kuanggucheck/u);
  assert.match(kuanggu, /room:askToChoice/u);
  assert.match(kuanggu, /player:drawCards\(1, kuanggu\.name\)/u);
  assert.match(kuanggu, /kuanggu:addEffect\(fk\.BeforeHpChanged/u);
  assert.match(kuanggu, /data\.damageEvent\.extra_data.*kuanggucheck/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-kuanggu"[\s\S]*triggerHiddenKuanggu\(room, state\)/u);
  assert.match(qaInit, /hidden-kuanggu[\s\S]*BeforeHpChanged[\s\S]*fk\.Damage/u);
});

test('hidden-liegong locks TargetSpecified damage-plus-one and reveal-before-effect for both slots', () => {
  const expected = {
    'hidden-liegong': {
      seed: 0x5d6e7fb4,
      actor: { general: 'hs__huangzhong', deputy: 'hs__zhaoyun', kingdom: 'shu' },
    },
    'hidden-liegong-deputy': {
      seed: 0x5d6e7fb5,
      actor: { general: 'hs__zhaoyun', deputy: 'hs__huangzhong', kingdom: 'shu' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-liegong', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhangliao', deputy: 'hs__xuchu', kingdom: 'wei' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'liegong-card', match: { trueName: 'slash' }, owner: 'actor', area: 'hand' },
      { key: 'liegong-target-card', match: { trueName: 'peach' }, owner: 'target', area: 'hand' },
    ]);
  }

  const liegong = fs.readFileSync(liegongSkillPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(liegong, /name = "hs__liegong"/u);
  assert.match(liegong, /liegong:addEffect\(fk\.TargetSpecified/u);
  assert.match(liegong, /data\.additionalDamage = \(data\.additionalDamage or 0\) \+ 1/u);
  assert.match(liegong, /hs__liegong_damage/u);
  assert.match(liegong, /room:askToChoice/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-liegong"[\s\S]*triggerHiddenLiegong\(room, state\)/u);
  assert.match(qaInit, /hidden-liegong[\s\S]*fk\.TargetSpecified[\s\S]*liegongTargetSpecified/u);
});

test('hidden-jueqing locks PreDamage HP-loss conversion and reveal-before-effect for both slots', () => {
  const expected = {
    'hidden-jueqing': {
      seed: 0x5d6e7fbe,
      actor: { general: 'zhangchunhua', deputy: 'hs__simayi', kingdom: 'wei' },
    },
    'hidden-jueqing-deputy': {
      seed: 0x5d6e7fbf,
      actor: { general: 'hs__simayi', deputy: 'zhangchunhua', kingdom: 'wei' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-jueqing', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'jueqing-card', match: { trueName: 'slash' }, owner: 'actor', area: 'hand' },
    ]);
  }

  const jueqing = fs.readFileSync(jueqingSkillPath, 'utf8');
  const skillEvent = fs.readFileSync(skillEventPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(jueqing, /name = "jueqing"/u);
  assert.match(jueqing, /jueqing:addEffect\(fk\.PreDamage/u);
  assert.match(jueqing, /loseHp\(data\.to, data\.damage, jueqing\.name\)/u);
  assert.match(jueqing, /data:preventDamage\(\)/u);
  assert.match(skillEvent, /player:revealBySkillName\(main_skill\.name\)/u);
  assert.match(qaInit, /scenario\.trigger == "hidden-jueqing"[\s\S]*triggerHiddenJueqing\(room, state\)/u);
  assert.match(qaInit, /hidden-jueqing[\s\S]*fk\.PreDamage[\s\S]*jueqingPreDamage/u);
});

test('hidden-ejue locks DamageCaused damage+1 and reveal-before-effect for both slots', () => {
  const expected = {
    'hidden-ejue': {
      seed: 0x5d6e7fc0,
      actor: { general: 'heg__zhangchunhua', deputy: 'heg__simayi', kingdom: 'jin' },
    },
    'hidden-ejue-deputy': {
      seed: 0x5d6e7fc1,
      actor: { general: 'heg__simayi', deputy: 'heg__zhangchunhua', kingdom: 'jin' },
    },
  };
  for (const [id, contract] of Object.entries(expected)) {
    const scenario = nativeCatalog.scenarios.find(({ id: scenarioId }) => scenarioId === id);
    assert.ok(scenario, `${id} catalog entry is required`);
    assert.equal(scenario.seed, contract.seed, `${id} seed drift`);
    assert.equal(scenario.trigger, 'hidden-ejue', `${id} trigger drift`);
    assert.equal(scenario.expectedCommand, 'AskForSkillInvoke', `${id} acceptance command drift`);
    assert.equal(scenario.playerCount, 2);
    assert.deepEqual(scenario.players, {
      actor: contract.actor,
      target: { general: 'hs__zhaoyun', deputy: 'hs__zhangfei', kingdom: 'shu' },
    });
    assert.deepEqual(scenario.cards, [
      { key: 'ejue-card', match: { trueName: 'slash' }, owner: 'actor', area: 'hand' },
    ]);
  }

  const ejue = fs.readFileSync(ejueSkillPath, 'utf8');
  const skillEvent = fs.readFileSync(skillEventPath, 'utf8');
  const qaInit = fs.readFileSync(path.join(packageDir, 'init.lua'), 'utf8');
  assert.match(ejue, /name = "heg__ejue"/u);
  assert.match(ejue, /ejue:addEffect\(fk\.DamageCaused/u);
  assert.match(ejue, /data:changeDamage\(1\)/u);
  assert.match(ejue, /data\.card\.trueName == "slash"/u);
  assert.match(ejue, /data\.to\.kingdom == "unknown"/u);
  const revealIndex = skillEvent.indexOf('player:revealBySkillName(main_skill.name)');
  const effectCallbackIndex = skillEvent.indexOf('effect_cb()');
  assert.ok(revealIndex >= 0, 'SkillEffect must reveal the hidden general by skill name');
  assert.ok(effectCallbackIndex > revealIndex,
    'SkillEffect must reveal the matching slot before running Ejue effect');
  assert.match(qaInit, /scenario\.trigger == "hidden-ejue"[\s\S]*triggerHiddenEjue\(room, state\)/u);
  assert.match(qaInit, /hidden-ejue[\s\S]*fk\.DamageCaused[\s\S]*hiddenEjueDamageCaused/u);
});

test('server prelight projection is idempotent, ownership-safe and stale-cleanup-safe', () => {
  const source = fs.readFileSync(serverPlayerPath, 'utf8');
  const start = source.indexOf('function ServerPlayer:prelightSkill(skill, isPrelight)');
  const end = source.indexOf('\n\n---@param isDeputy?', start);
  assert.ok(start >= 0 && end > start, 'ServerPlayer:prelightSkill source not found');
  const functionSource = source.slice(start, end);
  assert.match(functionSource, /table\.insertIfNeed\(self\.prelighted_skills, skill\)/u);
  assert.match(functionSource, /table\.insertIfNeed\(self\.prelighted_skills, s\)/u);
  assert.doesNotMatch(functionSource, /table\.insert\(self\.prelighted_skills/u);

  const addFakeSourceStart = source.indexOf('function ServerPlayer:addFakeSkill(skill)');
  const addFakeSourceEnd = source.indexOf('\n\n---@param skill string | Skill', addFakeSourceStart);
  assert.ok(addFakeSourceStart >= 0 && addFakeSourceEnd > addFakeSourceStart,
    'ServerPlayer:addFakeSkill source not found');
  const addFakeSource = source.slice(addFakeSourceStart, addFakeSourceEnd);
  assert.match(addFakeSource, /self:doNotify\("PrelightSkill", \{ skill\.name, true \}\)/u);

  // Execute the exact function body with the smallest native-like fixture.
  // This catches the real failure mode: duplicate true requests followed by
  // one false request must not leave a fake skill prelighted.
  const fixture = `
    function table.contains(items, value)
      for _, item in ipairs(items) do if item == value then return true end end
      return false
    end
    function table.removeOne(items, value)
      for index, item in ipairs(items) do
        if item == value then table.remove(items, index); return true end
      end
      return false
    end
    function table.insertIfNeed(items, value)
      if not table.contains(items, value) then table.insert(items, value); return true end
      return false
    end
    Fk = {skills = {}}
    Skill = {}
    local ServerPlayer = {}
    ${functionSource}
    local related = {name = 'related'}
    local skill = {name = 'hs__yiji', related_skills = {related}}
    function skill:isInstanceOf(_) return true end
    Fk.skills[skill.name] = skill
    local added = 0
    local notifications = 0
    local player = {
      _prelighted_skills = {}, prelighted_skills = {},
      room = {addSkill = function() added = added + 1 end},
    }
    function player:hasSkill(_) return false end
    function player:doNotify(_, _) notifications = notifications + 1 end
    setmetatable(player, {__index = ServerPlayer})
    player:prelightSkill(skill, true)
    player:prelightSkill(skill, true)
    assert(#player.prelighted_skills == 2, 'repeated prelight must not duplicate skill projection')
    assert(added == 1, 'room skill registration must remain one-time')
    player:prelightSkill(skill, false)
    assert(#player.prelighted_skills == 0, 'one un-prelight must fully clear an idempotent projection')
    assert(not table.contains(player.prelighted_skills, skill))
    assert(not table.contains(player.prelighted_skills, related))
    assert(notifications == 3)
    print('server prelight idempotency fixture PASS')
  `;
  assert.match(execFileSync('lua', ['-'], { input: fixture, encoding: 'utf8' }), /fixture PASS/u);

  const fakeFixture = `
    function table.contains(items, value)
      for _, item in ipairs(items) do if item == value then return true end end
      return false
    end
    function table.insertIfNeed(items, value)
      if not table.contains(items, value) then table.insert(items, value); return true end
      return false
    end
    Player = {}
    function Player.addFakeSkill(_, skill) return skill end
    local ServerPlayer = {}
    ${addFakeSource}
    local skill = {name = 'hs__yiji', related_skills = {}}
    local events = {}
    local player = {
      _manually_fake_skills = {}, prelighted_skills = {skill},
      doNotify = function(_, command, data) events[#events + 1] = {command, data} end,
    }
    setmetatable(player, {__index = ServerPlayer})
    player:addFakeSkill(skill)
    assert(#events == 2, 'reattaching a retained prelighted skill must send AddSkill and PrelightSkill')
    assert(events[1][1] == 'AddSkill' and events[2][1] == 'PrelightSkill',
      'retained prelight notification must follow AddSkill')
    assert(events[2][2][1] == 'hs__yiji' and events[2][2][2] == true)
    print('server fake-skill retained prelight fixture PASS')
  `;
  assert.match(execFileSync('lua', ['-'], { input: fakeFixture, encoding: 'utf8' }), /fixture PASS/u);

  const roomSource = fs.readFileSync(roomPath, 'utf8');
  const roomStart = roomSource.indexOf('function Room:handlePrelight(id, data)');
  const roomEnd = roomSource.indexOf('\n\nfunction Room:handleUpdateMini', roomStart);
  assert.ok(roomStart >= 0 && roomEnd > roomStart, 'Room:handlePrelight source not found');
  const handlerSource = roomSource.slice(roomStart, roomEnd);
  assert.match(handlerSource, /type\(data\) ~= "table"/u);
  assert.match(handlerSource, /Fk\.skills\[data\[3\]\]/u);
  assert.match(handlerSource, /if not p:isFakeSkill\(skill\) then return end/u);
  assert.match(handlerSource, /elseif not table\.contains\(p\.prelighted_skills, skill\) then/u);

  const handlerFixture = `
    function table.find(items, predicate)
      for _, item in ipairs(items) do if predicate(item) then return item end end
    end
    function table.contains(items, value)
      for _, item in ipairs(items) do if item == value then return true end end
      return false
    end
    Fk = {skills = {hs__yiji = {name = 'hs__yiji'}}}
    local Room = {}
    ${handlerSource}
    local controller = {_splayer = {}}
    local fake = false
    local calls = 0
    local lastEnabled = nil
    local player = {_observers = {controller._splayer}, prelighted_skills = {}}
    function player:isFakeSkill(skill) return fake and skill.name == 'hs__yiji' end
    function player:prelightSkill(skill, enabled)
      calls = calls + 1
      lastEnabled = enabled
      assert(skill.name == 'hs__yiji')
    end
    local room = {players = {player}}
    function room:getPlayerById(_) return controller end
    setmetatable(room, {__index = Room})

    room:handlePrelight(1, {'prelight', 'hs__yiji', 'hs__yiji', 'true'})
    assert(calls == 0, 'unattached skills must not be prelighted by the network handler')
    fake = true
    room:handlePrelight(1, {'prelight', 'hs__yiji', 'hs__yiji', 'true'})
    assert(calls == 1, 'currently attached fake skills must remain prelightable')
    table.insert(player.prelighted_skills, Fk.skills.hs__yiji)
    room:handlePrelight(1, {'prelight', 'hs__yiji', 'hs__yiji', 'false'})
    assert(calls == 2 and lastEnabled == false, 'retained prelight choices must remain clearable')
    table.remove(player.prelighted_skills, 1)
    room:handlePrelight(1, {'prelight', 'hs__yiji', 'hs__yiji', 'false'})
    assert(calls == 2, 'unknown false cleanup must not reach ServerPlayer')
    room:handlePrelight(1, {'prelight', 'unknown', 'missing', 'true'})
    room:handlePrelight(1, {'prelight', 'hs__yiji', 'hs__yiji', 'invalid'})
    assert(calls == 2, 'unknown and malformed prelight payloads must be ignored')
    print('room prelight ownership fixture PASS')
  `;
  assert.match(execFileSync('lua', ['-'], { input: handlerFixture, encoding: 'utf8' }), /fixture PASS/u);
});

test('native package install and verification keep prelight hardening in the deployed runtime', () => {
  const installer = fs.readFileSync(nativePackageInstallerPath, 'utf8');
  const verifier = fs.readFileSync(nativeInstallVerifierPath, 'utf8');
  assert.match(installer, /CORE_SERVERPLAYER=.*freekill-core\/ltk\/server\/serverplayer\.lua/u);
  assert.match(installer, /table\.insertIfNeed\(self\.prelighted_skills, skill\)/u);
  assert.match(installer, /table\.insertIfNeed\(self\.prelighted_skills, s\)/u);
  assert.match(installer, /Native ServerPlayer prelight projection hardening did not apply/u);
  assert.match(installer, /Native ServerPlayer retained prelight notification hardening did not apply/u);
  assert.match(installer, /CORE_ROOM=.*freekill-core\/ltk\/server\/room\.lua/u);
  assert.match(installer, /Native Room fake-skill ownership hardening did not apply/u);
  assert.match(installer, /Native Room stale-prelight cleanup hardening did not apply/u);
  assert.match(verifier, /ServerPlayer prelight projection: idempotent source hardening verified/u);
  assert.match(verifier, /ServerPlayer prelight function still contains duplicate-unsafe append/u);
  assert.match(verifier, /ServerPlayer fake-skill reattach: retained prelight state verified/u);
  assert.match(verifier, /Room prelight ownership: fake-skill and stale-cleanup checks verified/u);
});

test('native launcher fails closed on Lua 5.5 and prepares Lua 5.4 modules', () => {
  const launcher = fs.readFileSync(nativeRunServerPath, 'utf8');
  const luaRuntime = fs.readFileSync(nativeLuaRuntimePath, 'utf8');
  const amd64Bootstrap = fs.readFileSync(nativeAmd64BootstrapPath, 'utf8');
  const verifier = fs.readFileSync(nativeInstallVerifierPath, 'utf8');
  assert.match(launcher, /source "\$SCRIPT_DIR\/lua-runtime\.sh"/u);
  assert.match(launcher, /lua54_prepare "\$RUNTIME_DIR"/u);
  assert.match(luaRuntime, /lua5\.4/u);
  assert.match(luaRuntime, /version=.*io\.write\(_VERSION\)/u);
  assert.match(luaRuntime, /version.*Lua 5\.4/u);
  assert.match(luaRuntime, /rocks54\/share\/lua\/5\.4/u);
  assert.match(luaRuntime, /rocks54\/lib\/lua\/5\.4/u);
  assert.match(luaRuntime, /require\("socket"\)/u);
  assert.match(luaRuntime, /require\("lfs"\)/u);
  assert.match(amd64Bootstrap, /lua5\.4 lua-socket lua-filesystem/u);
  assert.match(verifier, /lua54_prepare "\$RUNTIME_DIR"/u);
});

test('native launcher preserves the native MD5 and loads QA outside public packages', () => {
  const launcher = fs.readFileSync(nativeRunServerPath, 'utf8');
  const freekill = fs.readFileSync(nativeFreekillPath, 'utf8');
  assert.doesNotMatch(launcher, /publicize_flist|wait_for_public_flist/u);
  assert.match(launcher, /exec "\$RUNTIME_DIR\/freekill-asio" --port "\$FREEKILL_PORT"/u);
  assert.match(freekill, /dofile "qa_packages\/tqs_qa\/init\.lua"/u);
  assert.doesNotMatch(freekill, /dofile "packages\/tqs_qa\/init\.lua"/u);
});

// Execute the package's actual startup validation/registration in Lua. JSON
// decoding and engine registration are stubs; this is not C++ gameplay proof.
function luaValue(value) {
  if (Array.isArray(value)) return `{${value.map(luaValue).join(',')}}`;
  if (value && typeof value === 'object') return `{${Object.entries(value)
    .map(([key, item]) => `[${JSON.stringify(key)}]=${luaValue(item)}`).join(',')}}`;
  if (value === null) return 'nil';
  return JSON.stringify(value);
}

function loadNativeCatalog(catalog) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-qa-load-'));
  try {
    const manifest = { schemaVersion: 1, package: 'tqs_qa', status: 'verified',
      sourceRevision: 'fixture', catalogSha256: 'fixture', packageSha256: 'fixture' };
    const dir = path.join(root, 'qa_packages/tqs_qa');
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'package.manifest.json'), JSON.stringify(manifest));
    fs.writeFileSync(path.join(dir, 'catalog.json'), JSON.stringify(catalog));
    fs.writeFileSync(path.join(root, 'load.lua'), `
      ServerConfig = {tqsQa={enabled=true,allowedUsers={'qa-fixture'}}}
      function table.contains(items, value)
        for _, item in ipairs(items) do if item == value then return true end end
        return false
      end
      local decoded = {${luaValue(manifest)}, ${luaValue(catalog)}}
      local index = 0
      json = {decode=function() index = index + 1; return decoded[index] end}
      local registered
      Package = {SpecialPack=1, new=function() return {
        loadSkillSkels=function(self, skills)
          assert(#skills == 1 and #skills[1].effects >= 8, 'missing director effects')
          registered = skills[1]
        end
      } end}
      fk = setmetatable({CreateSkill=function(spec)
        spec.effects = {}
        function spec:addEffect(event, effect) table.insert(self.effects, {event, effect}) end
        return spec
      end}, {__index=function(_, key) return key end})
      local extension = dofile(arg[1])
      assert(extension and extension.extensionName == 'tqs_qa')
      for _, event in ipairs({fk.DrawInitialCards, fk.GameStart, fk.RoundStart, fk.GameFinished}) do
        local automatic
        for _, entry in ipairs(registered.effects) do if entry[1] == event then automatic = entry[2] end end
        assert(automatic and type(automatic.on_trigger) == 'function' and automatic.on_use == nil,
          'QA lifecycle must execute directly without asking to invoke the director')
      end
      local room = {players={}}
      function room:getSettings(key) return key == 'roomName' and 'TQSQA/fazheng-enyuan/0x6e9a2026' end
      function room:getTag() return nil end
      local p = {id=1, room=room, _splayer={getScreenName=function() return 'not-allowlisted' end}}
      room.players = {p, {id=2, room=room}}
      local prepared
      for _, entry in ipairs(registered.effects) do if entry[1] == fk.GamePrepared then prepared = entry[2] end end
      local ok, err = pcall(function() prepared.on_trigger(nil, nil, nil, p, {}) end)
      assert(not ok and tostring(err):find('non%-allowlisted player'),
        'GamePrepared must read the native _splayer name and enforce the allowlist')
      print('native catalog startup fixture PASS')
    `);
    return execFileSync('lua', [path.join(root, 'load.lua'), path.join(packageDir, 'init.lua')],
      { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

test('actual Lua startup accepts four Slash steps and rejects the old two-damage or compulsory-Yiji contract', () => {
  assert.match(loadNativeCatalog(nativeCatalog), /startup fixture PASS/);
  const old = structuredClone(nativeCatalog);
  old.scenarios.find(({ id }) => id === 'fazheng-enyuan').attackSteps.length = 2;
  assert.throws(() => loadNativeCatalog(old), /four Slash steps/);
  const compulsory = structuredClone(nativeCatalog);
  compulsory.scenarios.find(({ id }) => id === 'fazheng-enyuan').attackSteps[3].mandatorySkills = ['hs__yiji'];
  assert.throws(() => loadNativeCatalog(compulsory), /must remain optional/);
});
