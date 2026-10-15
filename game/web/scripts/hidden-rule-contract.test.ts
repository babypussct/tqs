import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles, UPSTREAM_PACKAGE_NAMES } from './upstream-packages';

/**
 * Source-law regression gate for New Hegemony hidden generals.
 *
 * This is deliberately separate from hidden-skill-audit.ts.  That audit
 * enumerates the complete projection/lifecycle surface; this test locks the
 * ordering and ownership invariants which make the native hidden-general rule
 * true.  It is not effect-level gameplay evidence and must not be reported as
 * a substitute for a native C++ scenario.
 */
const repoRoot = fileURLToPath(new URL('../../../', import.meta.url));
const runtimeRoot = path.resolve(process.env.TQS_NATIVE_RUNTIME_ROOT ?? path.join(repoRoot, 'runtime'));
const upstreamRoot = path.join(repoRoot, 'scratch/upstream');

const readRuntime = (relative: string) => readFileSync(path.join(runtimeRoot, 'packages', 'freekill-core', relative), 'utf8');

type TriggerGateRow = {
  skill: string;
  event: string;
  triggerSource: string;
  triggerLine: number;
  custom: boolean;
  global: boolean;
};

/**
 * These effects are intentional post-activation continuations.  Their
 * predicates do not repeat hasSkill because the original effect has already
 * recorded durable state before the general is removed, invalidated or dies.
 * Keep the marker in the allowlist so a future source change cannot silently
 * turn a new ungated trigger into an accepted exception.
 */
const STATEFUL_FOLLOW_UP_MARKERS: Readonly<Record<string, string>> = {
  'm_heg__yaowu|fk.Deathed': 'm_heg__yaowu-noclear',
  'guixiu|HegUtil.GeneralRemoved': 'data.origName',
  'os__chuhai|fk.TurnEnd': 'getQuestSkillState',
  'fangquan|fk.TurnEnd': 'usedSkillTimes',
};

const EXPECTED_NON_DELAY_TRIGGER_PAIRS = 607;

const LUA_HIDDEN_TRIGGER_GATE_AUDIT = String.raw`
local result = { rows = {}, seen = {} }
local disabled = Fk.game_mode_disabled["new_heg_mode"] or Util.DummyTable

local function add(skillName, effect)
  if not effect:isInstanceOf(TriggerSkill) or effect.is_delay_effect then return end
  local eventName = tostring(effect.event and effect.event.name or "<none>")
  local key = skillName .. "|" .. eventName
  if result.seen[key] then return end
  result.seen[key] = true

  local custom, source, line = false, "", 0
  for index = 1, 16 do
    local upName, upValue = debug.getupvalue(effect.triggerable, index)
    if not upName then break end
    if upName == "tmp_func" then
      custom = true
      -- Wake skills wrap spec.can_trigger in a second closure. Resolve that
      -- wrapper so the source audit checks the actual package predicate.
      local candidate = upValue
      for nested = 1, 8 do
        local nestedName, nestedValue = debug.getupvalue(candidate, nested)
        if nestedName == "spec" and type(nestedValue) == "table" and
            type(nestedValue.can_trigger) == "function" then
          candidate = nestedValue.can_trigger
          break
        end
      end
      local info = debug.getinfo(candidate, "Sln")
      source = tostring(info and info.source or "")
      line = info and info.linedefined or 0
      break
    end
  end
  result.rows[#result.rows + 1] = {
    skill = skillName,
    event = eventName,
    triggerSource = source,
    triggerLine = line,
    custom = custom,
    global = effect.global == true,
  }
end

for _, general in pairs(Fk.generals) do
  local package = general.package
  if package and not table.contains(disabled, package.name) and
      not general.hidden and not general.total_hidden then
    for _, skillName in ipairs(general:getSkillNameList(true)) do
      local skill = Fk.skills[skillName]
      if skill then
        local effects = { skill }
        for _, related in ipairs(skill.related_skills or Util.DummyTable) do
          effects[#effects + 1] = related
        end
        for _, effect in ipairs(effects) do add(skillName, effect) end
      end
    end
  end
end

return result
`;

function section(source: string, start: string, end: string, label: string): string {
  const startAt = source.indexOf(start);
  assert.notEqual(startAt, -1, `${label}: missing start marker ${start}`);
  const endAt = source.indexOf(end, startAt + start.length);
  assert.notEqual(endAt, -1, `${label}: missing end marker ${end}`);
  return source.slice(startAt, endAt);
}

function assertOrder(source: string, markers: readonly string[], label: string): void {
  let previous = -1;
  for (const marker of markers) {
    const current = source.indexOf(marker);
    assert.notEqual(current, -1, `${label}: missing ${marker}`);
    assert.ok(current > previous, `${label}: ${marker} must come after the previous rule step`);
    previous = current;
  }
}

test('native hidden-skill activation requires prelight and uses the trigger cost path', () => {
  const player = readRuntime('ltk/core/player.lua');
  const trigger = readRuntime('ltk/core/skill_type/trigger.lua');
  const hasSkill = section(player, 'function Player:hasSkill', 'function Player:hasShownSkill', 'Player:hasSkill');
  const triggerable = section(trigger, 'function TriggerSkill:triggerable', 'function TriggerSkill:trigger', 'TriggerSkill:triggerable');
  const doCost = section(trigger, 'function TriggerSkill:doCost', 'function TriggerSkill:cost', 'TriggerSkill:doCost');

  assertOrder(hasSkill, [
    'self:isFakeSkill(skill)',
    'table.contains(self.prelighted_skills, skill)',
    'return not effect:isInstanceOf(StatusSkill)',
  ], 'fake skill activation');
  assert.match(triggerable, /target:hasSkill\(self:getSkeleton\(\)\.name\)/u,
    'the default trigger gate must consult Player:hasSkill');
  assertOrder(doCost, [
    'if ret and player:isFakeSkill(self)',
    'ret = room:askToSkillInvoke(player, { skill_name = self.name })',
    'if ret then',
    'room:useSkill(player, self, function()',
  ], 'hidden trigger cost/effect path');
});

test('native SkillEffect reveals the owning hidden slot before running any effect callback', () => {
  const skillEvents = readRuntime('ltk/server/events/skill.lua');
  const main = section(skillEvents, 'function SkillEffect:main', 'function SkillEffect:clear', 'SkillEffect:main');

  assertOrder(main, [
    'if player and not skill.cardSkill then',
    'if not skill.is_delay_effect then',
    'player:revealBySkillName(main_skill.name)',
    'logic:trigger(fk.SkillEffect, player, data)',
    'effect_cb()',
    'logic:trigger(fk.AfterSkillEffect, player, data)',
  ], 'reveal-before-effect');
  assert.match(main, /local main_skill = skill\.main_skill and skill\.main_skill or skill/u,
    'related trigger effects must route through their owning skeleton skill');
});

test('native reveal routing is main-first with an explicit deputy fallback', () => {
  const serverPlayer = readRuntime('ltk/server/serverplayer.lua');
  const reveal = section(serverPlayer, 'function ServerPlayer:revealBySkillName', 'function ServerPlayer:hideGeneral', 'ServerPlayer:revealBySkillName');

  assertOrder(reveal, [
    'local main = self.general == "anjiang"',
    'self:getMark("__heg_general")',
    'self:revealGeneral(false)',
    'if deputy then',
    'self:getMark("__heg_deputy")',
    'self:revealGeneral(true)',
  ], 'hidden slot routing');
  assert.match(reveal, /local deputy = self\.deputyGeneral == "anjiang"/u,
    'deputy route must be limited to an unrevealed deputy slot');
  assert.match(reveal, /table\.contains\(Fk\.generals\[self:getMark\("__heg_general"\)\]\s*\n?\s*:getSkillNameList\(true\), skill_name\)/u,
    'main route must match the hidden general skill list');
  assert.match(reveal, /table\.contains\(Fk\.generals\[self:getMark\("__heg_deputy"\)\]\s*\n?\s*:getSkillNameList\(true\), skill_name\)/u,
    'deputy route must match the hidden deputy skill list');
});

test('native prelight requests are owned, fake-skill-only and stale-disable safe', () => {
  const room = readRuntime('ltk/server/room.lua');
  const handlePrelight = section(room, 'function Room:handlePrelight', 'function Room:handleUpdateMini', 'Room:handlePrelight');

  assertOrder(handlePrelight, [
    'local isPrelight = data[4] == "true"',
    'if isPrelight then',
    'if not p:isFakeSkill(skill) then return end',
    'elseif not table.contains(p.prelighted_skills, skill) then',
    'p:prelightSkill(skill, isPrelight)',
  ], 'prelight ownership gate');
});

test('native re-hide reattaches retained prelight state after fake-skill projection', () => {
  const serverPlayer = readRuntime('ltk/server/serverplayer.lua');
  const addFake = section(serverPlayer, 'function ServerPlayer:addFakeSkill', 'function ServerPlayer:loseFakeSkill', 'ServerPlayer:addFakeSkill');
  const hideGeneral = section(serverPlayer, 'function ServerPlayer:hideGeneral', 'function ServerPlayer:getNextAlive', 'ServerPlayer:hideGeneral');

  assertOrder(addFake, [
    'self:doNotify("AddSkill", { self.id, skill.name, true })',
    'table.contains(self.prelighted_skills, skill)',
    'self:doNotify("PrelightSkill", { skill.name, true })',
  ], 'prelight reattach');
  assertOrder(hideGeneral, [
    'room:handleAddLoseSkills(self, "-" .. sname, nil, false, false)',
    'self:addFakeSkill(s)',
  ], 'hide-general fake projection');
});

test('native client projection distinguishes usable triggers, active companions and delay-only fallbacks', () => {
  const client = readRuntime('ltk/client/client.lua');
  const addSkill = section(client, 'function Client:addSkill', 'function Client:prelightSkill', 'Client:addSkill');
  const loseSkill = section(client, 'function Client:loseSkill', 'function Client:addSkill', 'Client:loseSkill');

  assert.match(addSkill, /isInstanceOf\(TriggerSkill\) and not s\.is_delay_effect/u,
    'fake AddSkill must not expose a delay-only trigger as a prelight control');
  assert.match(addSkill, /isInstanceOf\(ActiveSkill\) or s:isInstanceOf\(ViewAsSkill\)/u,
    'fake AddSkill must preserve active/view-as companions');
  assert.match(loseSkill, /isInstanceOf\(TriggerSkill\)/u,
    'fake LoseSkill must remove the native trigger projection');
});

test('every custom hidden trigger predicate keeps a skill-visibility gate or a recorded follow-up state', async () => {
  assert.ok(existsSync(upstreamRoot), `Missing pinned upstream checkout: ${upstreamRoot}`);
  const files = loadUpstreamFiles(upstreamRoot, UPSTREAM_PACKAGE_NAMES);
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {}, setup: () => {}, ui: () => {}, log: () => {},
  }});
  try {
    await runtime.start();
    const report = await runtime.eval<{ rows: TriggerGateRow[] }>(LUA_HIDDEN_TRIGGER_GATE_AUDIT);
    const globalCustomRows = report.rows.filter((row) => row.custom && row.global);
    assert.deepEqual(globalCustomRows, [],
      'hidden trigger inventory must not introduce a global custom predicate outside the owner visibility audit');
    const customRows = report.rows.filter((row) => row.custom && !row.global);
    const missingGate: string[] = [];
    const decoder = new TextDecoder();
    for (const row of customRows) {
      let relative = row.triggerSource.replace(/^@\.?\//u, '');
      if (relative.startsWith('ltk/')) relative = `packages/freekill-core/${relative}`;
      const raw = files.get(relative);
      if (!raw) {
        missingGate.push(`${row.skill}/${row.event}: missing source ${relative}`);
        continue;
      }
      const source = typeof raw === 'string' ? raw : decoder.decode(raw);
      const lines = source.split(/\r?\n/u);
      const lineIndex = Math.min(Math.max(0, row.triggerLine - 1), Math.max(0, lines.length - 1));
      let start = lineIndex;
      while (start >= 0 && !lines[start].includes('can_trigger')) start -= 1;
      const boundaryNames = ['on_cost', 'on_use', 'on_trigger', 'can_refresh', 'can_wake', 'trigger_times'];
      let end = lines.length;
      for (let index = lineIndex + 1; index < lines.length; index += 1) {
        const trimmed = lines[index].trim();
        if (boundaryNames.some((name) => trimmed.startsWith(`${name} =`) || trimmed.startsWith(`${name}=`))) {
          end = index;
          break;
        }
      }
      const predicate = lines.slice(start >= 0 ? start : lineIndex, end).join('\n');
      const key = `${row.skill}|${row.event}`;
      const hasVisibilityGate = /\bhas(?:Shown)?Skill\s*\(/u.test(predicate);
      if (!hasVisibilityGate && !STATEFUL_FOLLOW_UP_MARKERS[key]) {
        missingGate.push(`${row.skill}/${row.event}: ${relative}:${row.triggerLine}`);
      } else if (!hasVisibilityGate && !predicate.includes(STATEFUL_FOLLOW_UP_MARKERS[key])) {
        missingGate.push(`${row.skill}/${row.event}: allowlisted follow-up marker disappeared at ${relative}:${row.triggerLine}`);
      }
    }
    for (const key of Object.keys(STATEFUL_FOLLOW_UP_MARKERS)) {
      assert.ok(report.rows.some((row) => `${row.skill}|${row.event}` === key),
        `stateful follow-up allowlist entry is absent from the pinned trigger inventory: ${key}`);
    }
    assert.equal(report.rows.length, EXPECTED_NON_DELAY_TRIGGER_PAIRS,
      'hidden trigger inventory changed; refresh the source-law audit and acceptance count before accepting a new package pin');
    assert.deepEqual(missingGate, [], `custom hidden trigger predicates without hasSkill/hasShownSkill gate: ${missingGate.join('; ')}`);
  } finally {
    runtime.close();
  }
});
