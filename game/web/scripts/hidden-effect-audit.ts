/**
 * Source/evidence coverage audit for hidden-general trigger effects.
 *
 * `audit:hidden-skills` proves projection, lifecycle and slot routing.  This
 * audit answers a different question: which concrete source `skill × event`
 * pairs have a native QA scenario that actually exercised the effect.  It is
 * intentionally a report, not a completeness gate: an uncovered pair is an
 * open acceptance item, not a browser failure.
 *
 * The evidence map is explicit so a future review cannot accidentally count a
 * generic prelight or activation smoke test as effect-level proof.  The map
 * only records NATIVE-LOCAL staged scenarios already listed in
 * QUOC_CHIEN_RULE_AUDIT.md; it does not claim hosted/Render/Oracle parity.
 */
import path from 'node:path';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadUpstreamFiles, packageSpec, UPSTREAM_PACKAGE_NAMES } from './upstream-packages';
import { LuaRuntime } from '../src/engine/luaRuntime';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');

type SourcePair = { skill: string; event: string; delay?: boolean };
type LuaReport = { activeGenerals: number; rows: SourcePair[] };
type EvidenceMap = { scenario: string; skill: string; events: readonly string[] };

/**
 * Only effects whose native C++/Lua scenario has been run are listed here.
 * Main/deputy variants are represented by the same source skill and are
 * covered only when both variants were exercised by that scenario family.
 */
const NATIVE_LOCAL_EFFECT_EVIDENCE: readonly EvidenceMap[] = [
  { scenario: 'hidden-yiji (+ deputy)', skill: 'hs__yiji', events: ['fk.Damaged'] },
  { scenario: 'hidden-jianxiong (+ deputy)', skill: 'hs__jianxiong', events: ['fk.Damaged'] },
  { scenario: 'hidden-fankui (+ deputy)', skill: 'fankui', events: ['fk.Damaged'] },
  { scenario: 'hidden-dual', skill: 'hs__shuangxiong', events: ['fk.EventPhaseStart'] },
  { scenario: 'hidden-luoshen (+ deputy)', skill: 'hs__luoshen', events: ['fk.EventPhaseStart'] },
  { scenario: 'hidden-jizhi (+ deputy)', skill: 'hs__jizhi', events: ['fk.CardUsing'] },
  { scenario: 'hidden-mingshi (+ deputy)', skill: 'mingshi', events: ['fk.DamageInflicted'] },
  { scenario: 'hidden-qianxun (+ deputy)', skill: 'hs__qianxun', events: ['fk.TargetConfirming', 'fk.BeforeCardsMove'] },
  { scenario: 'hidden-kongcheng (+ deputy)', skill: 'hs__kongcheng', events: ['fk.TargetConfirming', 'fk.BeforeCardsMove'] },
  { scenario: 'hidden-weimu (+ deputy)', skill: 'hs__weimu', events: ['fk.TargetConfirming', 'fk.BeforeCardsMove'] },
  { scenario: 'hidden-xiaoji (+ deputy)', skill: 'hs__xiaoji', events: ['fk.AfterCardsMove'] },
  { scenario: 'hidden-guanxing (+ deputy)', skill: 'hs__guanxing', events: ['fk.EventPhaseStart'] },
  { scenario: 'hidden-yingzi (+ deputy)', skill: 'ex__yingzi', events: ['fk.DrawNCards'] },
  { scenario: 'hidden-tianxiang (+ deputy)', skill: 'hs__tianxiang', events: ['fk.DetermineDamageInflicted'] },
  { scenario: 'hidden-duanchang (+ deputy)', skill: 'hs__duanchang', events: ['fk.Death'] },
];

const LUA_EFFECT_AUDIT = String.raw`
local result = { activeGenerals = 0, rows = {}, seen = {} }
local disabled = Fk.game_mode_disabled["new_heg_mode"] or Util.DummyTable

local function addPair(skillName, eventName, isDelay)
  local key = skillName .. "|" .. eventName .. "|" .. tostring(isDelay)
  if result.seen[key] then return end
  result.seen[key] = true
  table.insert(result.rows, { skill = skillName, event = eventName, delay = isDelay })
end

local function inspectSkill(skillName, skill)
  local effects = { skill }
  for _, related in ipairs(skill.related_skills or Util.DummyTable) do
    table.insert(effects, related)
  end
  for _, effect in ipairs(effects) do
    if effect:isInstanceOf(TriggerSkill) then
      addPair(skillName, tostring(effect.event and effect.event.name or "<none>"), effect.is_delay_effect == true)
    end
  end
end

for _, general in pairs(Fk.generals) do
  if general.package and not table.contains(disabled, general.package.name) and
      not general.hidden and not general.total_hidden then
    result.activeGenerals = result.activeGenerals + 1
    for _, skillName in ipairs(general:getSkillNameList(true)) do
      local skill = Fk.skills[skillName]
      if skill then
        if not (skill:hasTag(Skill.DeputyPlace) and skill:hasTag(Skill.MainPlace)) then
          inspectSkill(skillName, skill)
        end
      end
    end
  end
end

table.sort(result.rows, function(a, b)
  return a.skill < b.skill or (a.skill == b.skill and a.event < b.event)
end)
return result
`;

function ensureUpstream(): void {
  for (const spec of UPSTREAM_PACKAGE_NAMES.map(packageSpec)) {
    const root = path.join(UPSTREAM_ROOT, spec.sourceDirectory);
    if (!existsSync(root)) throw new Error(`Missing upstream package root for ${spec.name}: ${root}`);
  }
}

function pairKey(pair: SourcePair): string {
  return `${pair.skill}|${pair.event}`;
}

function buildEvidenceSet(): Set<string> {
  const evidence = new Set<string>();
  for (const item of NATIVE_LOCAL_EFFECT_EVIDENCE) {
    for (const event of item.events) evidence.add(`${item.skill}|${event}`);
  }
  return evidence;
}

function printReport(report: ReturnType<typeof summarize>): void {
  console.log(`Hidden effect audit: ${report.activeGenerals} active generals; ` +
    `${report.uniqueTriggerSkillEventPairs} unique non-delay trigger skill×event pairs; ` +
    `${report.uniqueTriggerSkills} skill IDs across ${report.eventKinds} event kinds`);
  console.log(`Source inventory including delay effects: ${report.allTriggerSkillEventPairs} pairs / ` +
    `${report.allTriggerEventKinds} event kinds; delay-only rows=${report.delayTriggerSkillEventPairs}`);
  console.log(`Native-local effect evidence map: ${report.coveredPairs}/${report.uniqueTriggerSkillEventPairs} pairs; ` +
    `${report.coveredEventKinds}/${report.eventKinds} event kinds; ` +
    `${report.coveragePercent}% pair coverage`);
  for (const row of report.events) {
    console.log(`${row.event}: source=${row.sourceSkillIds}; evidence=${row.evidenceSkillIds}; ` +
      `untested=${row.untestedSkillIds}; samples=${row.untestedSamples.join(',') || '—'}`);
  }
  if (report.invalidEvidence.length) {
    console.log(`FAIL invalid evidence map: ${report.invalidEvidence.join(' | ')}`);
  }
  console.log(report.invalidEvidence.length === 0
    ? 'PASS hidden effect inventory: evidence map matches pinned source; uncovered pairs remain explicit backlog'
    : 'FAIL hidden effect inventory: evidence map references a missing source skill/event pair');
}

function summarize(luaReport: LuaReport) {
  const allPairs = luaReport.rows.map((row) => ({
    skill: String(row.skill), event: String(row.event), delay: row.delay === true,
  }));
  const sourcePairs = allPairs.filter((pair) => !pair.delay);
  const sourceSet = new Set(sourcePairs.map(pairKey));
  const evidenceSet = buildEvidenceSet();
  const invalidEvidence = [...evidenceSet].filter((key) => !sourceSet.has(key)).sort();
  const events = [...new Set(sourcePairs.map((pair) => pair.event))].sort().map((event) => {
    const source = new Set(sourcePairs.filter((pair) => pair.event === event).map((pair) => pair.skill));
    const evidence = new Set(sourcePairs.filter((pair) => pair.event === event && evidenceSet.has(pairKey(pair))).map((pair) => pair.skill));
    const untested = [...source].filter((skill) => !evidence.has(skill)).sort();
    return {
      event,
      sourceSkillIds: source.size,
      evidenceSkillIds: evidence.size,
      untestedSkillIds: untested.length,
      untestedSamples: untested.slice(0, 12),
    };
  });
  const coveredPairs = sourcePairs.filter((pair) => evidenceSet.has(pairKey(pair))).length;
  const coveredEventKinds = events.filter((row) => row.evidenceSkillIds > 0).length;
  return {
    generatedAt: new Date().toISOString(),
    packages: UPSTREAM_PACKAGE_NAMES.map(packageSpec),
    activeGenerals: luaReport.activeGenerals,
    allTriggerSkillEventPairs: allPairs.length,
    allTriggerEventKinds: new Set(allPairs.map((pair) => pair.event)).size,
    delayTriggerSkillEventPairs: allPairs.filter((pair) => pair.delay).length,
    uniqueTriggerSkillEventPairs: sourcePairs.length,
    uniqueTriggerSkills: new Set(sourcePairs.map((pair) => pair.skill)).size,
    eventKinds: events.length,
    coveredPairs,
    coveredEventKinds,
    coveragePercent: sourcePairs.length ? Number((coveredPairs / sourcePairs.length * 100).toFixed(1)) : 0,
    events,
    invalidEvidence,
    evidenceScenarios: NATIVE_LOCAL_EFFECT_EVIDENCE,
    pass: invalidEvidence.length === 0,
  };
}

async function main() {
  ensureUpstream();
  const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES);
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {}, setup: () => {}, ui: () => {},
    log: (level, message) => { if (level === 'error') throw new Error(message); },
  }});
  try {
    await runtime.start();
    return summarize(await runtime.eval<LuaReport>(LUA_EFFECT_AUDIT));
  } finally {
    runtime.close();
  }
}

const report = await main();
if (process.argv.includes('--json')) console.log(JSON.stringify(report, null, 2));
else printReport(report);
if (!report.pass) process.exitCode = 1;

