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

test('hidden slot mirrors lock main/deputy placement instead of relying on one roster order', () => {
  const expected = {
    'hidden-yiji-deputy': {
      trigger: 'hidden-yiji',
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
    const dir = path.join(root, 'packages/tqs_qa');
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
