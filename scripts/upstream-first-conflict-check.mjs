#!/usr/bin/env node

// Sanity checks for the manually merged conflict hunks in an isolated
// candidate runtime. This is intentionally structural evidence, not a native
// gameplay acceptance test.

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const separator = arg.indexOf('=');
  if (!arg.startsWith('--') || separator < 3) throw new Error(`Expected --key=value, got ${arg}`);
  return [arg.slice(2, separator), arg.slice(separator + 1)];
}));
for (const key of ['runtime', 'out']) if (!args[key]) throw new Error(`Missing --${key}=...`);
const runtime = path.resolve(args.runtime);
const out = path.resolve(args.out);

function read(relative) {
  const file = path.join(runtime, relative);
  if (!existsSync(file)) throw new Error(`Missing candidate file: ${file}`);
  return readFileSync(file, 'utf8');
}

function check(name, file, predicates) {
  const source = read(file);
  const failures = predicates.filter(({ label, test }) => !test(source)).map(({ label }) => label);
  return {
    name,
    file,
    sha256: createHash('sha256').update(source).digest('hex'),
    pass: failures.length === 0,
    failures,
  };
}

const checks = [
  check('core room', 'freekill-core/ltk/server/room.lua', [
    { label: 'locked-pack guard', test: (s) => s.includes('fk.GetTqsLockedPacks()') },
    { label: 'prelight validation', test: (s) => s.includes('local isPrelight = data[4] == "true"') && s.includes('p:isFakeSkill(skill)') },
    { label: 'request skill-name field', test: (s) => s.includes('local data = {target, flag, prompt, skill_name}') },
    { label: 'upstream filterUseCard', test: (s) => s.includes('function Room:filterUseCard(id)') && s.includes('self:filterUseCard(card)') },
  ]),
  check('core serverplayer', 'freekill-core/ltk/server/serverplayer.lua', [
    { label: 'reconnect status pairs', test: (s) => s.includes('for _, skills in pairs(self.room.status_skills) do') },
    { label: 'prelight dedupe', test: (s) => s.includes('table.insertIfNeed(self.prelighted_skills, skill)') },
    { label: 'fake-skill prelight notify', test: (s) => s.includes('self:doNotify("PrelightSkill", { skill.name, true })') || s.includes('self:notifyConcealedSkillOwner("PrelightSkill", { skill.name, true })') },
  ]),
  check('core roombase', 'freekill-core/lua/server/roombase.lua', [
    { label: 'played_time serialization', test: (s) => s.includes('o.played_time = self.start_time') },
    { label: 'opt-in AI metrics', test: (s) => s.includes('ServerConfig.tqsAiMatchTelemetry') && s.includes('emitAiMatchMetrics(self)') },
    { label: 'metric allowlist', test: (s) => s.includes('SAFE_AI_FALLBACK_REASONS') && s.includes('SAFE_AI_INVALID_DETAILS') },
  ]),
  check('Hegemony overseas init', 'hegemony/pkg/overseas_heg/init.lua', [
    { label: 'dormant Ty Langmie repair', test: (s) => s.includes('addSkills { "ty__langmie" }') },
    { label: 'no unresolved merge marker', test: (s) => !s.includes('<<<<<<<') && !s.includes('>>>>>>>') },
  ]),
  check('Hegemony utility', 'hegemony/util.lua', [
    { label: 'removeGeneral retained', test: (s) => s.includes('function HegUtil.removeGeneral(player, isDeputy)') },
    { label: 'event removeGeneral loaded after legacy method', test: (s) => s.indexOf("dofile 'packages/hegemony/utilevent/init.lua'") > s.indexOf('function HegUtil.removeGeneral(player, isDeputy)') },
    { label: 'hidden-slot owner lookup', test: (s) => s.includes('local main = HegUtil.getActualGeneral(player, false)') },
    { label: 'target YiGui interaction', test: (s) => s.includes('packages/hegemony/qml/YiGuiInteraction.qml') && s.includes('packages/hegemony/qml/YiGuiModel.qml') },
  ]),
  check('Hegemony event removal loader', 'hegemony/utilevent/init.lua', [
    { label: 'real RemoveGeneral event loaded', test: (s) => s.includes('dofile "packages/hegemony/utilevent/core/remove_general.lua"') },
  ]),
  check('Hegemony event removal override', 'hegemony/utilevent/core/remove_general.lua', [
    { label: 'event override calls exec', test: (s) => s.includes('function HegUtil.removeGeneral(player, isDeputy)') && s.includes('local _, ret = event:exec()') },
    { label: 'event class registered', test: (s) => s.includes('HegUtil.GameEvent.RemoveGeneral = RemoveGeneral') },
  ]),
];

function activeGeneralCount(source) {
  let inComment = false;
  let count = 0;
  for (const line of source.split('\n')) {
    if (!inComment && line.includes('--[[')) { inComment = true; continue; }
    if (inComment) {
      if (line.includes(']]')) inComment = false;
      continue;
    }
    if (/\bGeneral:new\s*\(/u.test(line) || /generals\.[\w]+\s*=\s*General:new/u.test(line)) count++;
  }
  return count;
}

const overseas = read('hegemony/pkg/overseas_heg/init.lua');
const activeGenerals = activeGeneralCount(overseas);
const activeGeneralCheck = { name: 'overseas active-general policy', activeGenerals, expected: 5, pass: activeGenerals === 5 };
checks.push(activeGeneralCheck);

const manifest = {
  schemaVersion: 1,
  runtime,
  checks,
  pass: checks.every((check) => check.pass),
  gate: checks.every((check) => check.pass)
    ? 'HUNK_MERGE_STRUCTURAL_PASS; NATIVE_EFFECT_AND_GAMEPLAY_OPEN'
    : 'HUNK_MERGE_STRUCTURAL_FAIL',
};
mkdirSync(out, { recursive: true });
writeFileSync(path.join(out, 'candidate-conflict-check.json'), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(JSON.stringify({
  out,
  pass: manifest.pass,
  activeGenerals,
  failedChecks: checks.filter((check) => !check.pass).map((check) => check.name),
  gate: manifest.gate,
}));
