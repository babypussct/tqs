import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

const readRuntime = (relative: string) => readFileSync(path.join(runtimeRoot, 'packages', 'freekill-core', relative), 'utf8');

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
