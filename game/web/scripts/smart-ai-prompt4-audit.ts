/**
 * Prompt 4 inventory and priority audit for SmartAI in new_heg_mode.
 *
 * This deliberately measures the mode's registered general pool instead of
 * counting addAI() declarations in source files.  The output separates the
 * pool estimate from observed-match evidence: metadata-only match evidence
 * currently does not expose per-skill activation frequencies.
 */
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles, packageSpec, UPSTREAM_PACKAGE_NAMES, type UpstreamPackageSpec } from './upstream-packages';
import { buildPrompt4Backlog, buildPrompt4Priority, type Prompt4BacklogRecord, type Prompt4PriorityRecord } from './smart-ai-prompt4-priority';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');
const LOCAL_CORE_ROOT = path.join(REPO_ROOT, 'runtime/packages/freekill-core');
const LOCAL_PACKAGE_ROOT = path.join(REPO_ROOT, 'runtime/packages');
const RUNTIME_EXTENSIONS = /\.(lua|json|md|qml|js)$/iu;
// Keep the inventory aligned with the local runtime tree for skills whose
// source owner is an extension package rather than hegemony/shzl.  Prompt 4
// may overlay only the bounded package files it changes; all other packages
// still come from their pinned scratch/upstream snapshots.
const LOCAL_SKILL_PACKAGES = ['hegemony', 'shzl', 'mobile', 'ol', 'tenyear'] as const;

export type Prompt4SkillRecord = {
  id: string;
  occurrenceCount: number;
  generalCount: number;
  generals: string[];
  packages: string[];
  classes: string[];
  surfaces: string[];
  strategyTypes: string[];
  strategyCount: number;
  handlerKind: 'ai_handler' | 'default_handler' | 'no_decision_required' | 'missing';
  poolFrequencyEstimate: number;
};

export type Prompt4AuditReport = {
  generatedAt: string;
  mode: 'new_heg_mode';
  packages: UpstreamPackageSpec[];
  disabledPackages: string[];
  activePackageCounts: Record<string, number>;
  activeGeneralCount: number;
  activeVisibleGeneralCount: number;
  eligibleGeneralCount: number;
  poolGeneralNames: string[];
  poolSkillReferenceCount: number;
  poolUniqueSkillCount: number;
  decisionSkillCount: number;
  aiHandlerSkillCount: number;
  defaultHandlerSkillCount: number;
  noDecisionSkillCount: number;
  missingSkillCount: number;
  frequencyEvidence: {
    poolEstimate: {
      denominator: string;
      activeEligibleGenerals: number;
      note: string;
    };
    observedMatches: {
      samples: number;
      skillActivationCountsAvailable: boolean;
      note: string;
    };
  };
  skills: Prompt4SkillRecord[];
  priority: Prompt4PriorityRecord[];
  backlog: Prompt4BacklogRecord[];
  pass: boolean;
  failures: string[];
};

type LuaPrompt4Report = Omit<Prompt4AuditReport, 'generatedAt' | 'mode' | 'packages' | 'frequencyEvidence' | 'pass' | 'failures'> & {
  frequencyEvidence: Prompt4AuditReport['frequencyEvidence'];
};

function overlayLocalTree(files: Map<string, Uint8Array>, root: string, packageName: string): void {
  function visit(directory: string): void {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(absolute);
      else if (entry.isFile() && RUNTIME_EXTENSIONS.test(entry.name)) {
        const relative = path.relative(root, absolute).split(path.sep).join('/');
        files.set(`packages/${packageName}/${relative}`, readFileSync(absolute));
      }
    }
  }
  visit(root);
}

export function candidateFiles(): Map<string, Uint8Array> {
  const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES);
  overlayLocalTree(files, LOCAL_CORE_ROOT, 'freekill-core');
  for (const packageName of LOCAL_SKILL_PACKAGES) {
    overlayLocalTree(files, path.join(LOCAL_PACKAGE_ROOT, packageName), packageName);
  }
  return files;
}

const LUA_PROMPT4_AUDIT = String.raw`
local result = {
  disabledPackages = {}, activePackageCounts = {}, activeGeneralCount = 0,
  activeVisibleGeneralCount = 0, eligibleGeneralCount = 0, poolGeneralNames = {},
  poolSkillReferenceCount = 0, poolUniqueSkillCount = 0, decisionSkillCount = 0,
  aiHandlerSkillCount = 0, defaultHandlerSkillCount = 0, noDecisionSkillCount = 0,
  missingSkillCount = 0, frequencyEvidence = {
    poolEstimate = {
      denominator = "eligible active visible generals with numeric maxHp",
      activeEligibleGenerals = 0,
      note = "Estimated from the registered new_heg_mode general pool; not an observed match rate.",
    },
    observedMatches = {
      samples = 0,
      skillActivationCountsAvailable = false,
      note = "Current sanitized evidence records decisions and shapes, not per-skill activation counts.",
    },
  },
  skills = {},
}

local disabled = Fk.game_mode_disabled["new_heg_mode"] or Util.DummyTable
for _, packageName in ipairs(disabled) do result.disabledPackages[#result.disabledPackages + 1] = packageName end
table.sort(result.disabledPackages)

local function isDisabled(packageName)
  return packageName and table.contains(disabled, packageName)
end

local function skillName(value)
  if type(value) == "string" then return value end
  if type(value) == "table" and type(value.name) == "string" then return value.name end
  return nil
end

local function className(value)
  if type(value) ~= "table" then return nil end
  if type(value.name) == "string" then return value.name end
  return nil
end

local function addUnique(list, seen, value)
  if type(value) ~= "string" or value == "" or seen[value] then return end
  seen[value] = true
  list[#list + 1] = value
end

local function sortedKeys(map)
  local keys = {}
  for key in pairs(map) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

local function isEligibleGeneral(general)
  local package = general and general.package
  return package and not isDisabled(package.name) and
    not general.hidden and not general.total_hidden and
    type(general.maxHp) == "number"
end

local function effectClasses(skill)
  local classes, seen = {}, {}
  local function addEffect(effect)
    if not effect then return end
    addUnique(classes, seen, className(effect.class))
  end
  addEffect(skill)
  for _, related in ipairs(skill.related_skills or Util.DummyTable) do addEffect(related) end
  return classes
end

local decisionStrategyNames = {
  ["AI.ActiveStrategy"] = true,
  ["AI.CardSkillStrategy"] = true,
  ["AI.InvokeStrategy"] = true,
  ["AI.ChoiceStrategy"] = true,
  ["AI.ChoicesStrategy"] = true,
  ["AI.ChoosePlayersStrategy"] = true,
  ["AI.ChoosePlayerStrategy"] = true,
  ["AI.ChooseCardsStrategy"] = true,
  ["AI.ChooseCardStrategy"] = true,
  ["AI.ChooseCardsAndPlayersStrategy"] = true,
  ["AI.ChooseCardsAndChoiceStrategy"] = true,
  ["AI.CardsStrategy"] = true,
  ["AI.CardChosenStrategy"] = true,
  ["AI.AGStrategy"] = true,
  ["AI.MoveBoardStrategy"] = true,
  ["AI.PoxiStrategy"] = true,
  ["AI.ArrangeCardsStrategy"] = true,
  ["AI.ExchangeStrategy"] = true,
  ["AI.YijiStrategy"] = true,
  ["AI.NumberStrategy"] = true,
  ["AI.JointChoiceStrategy"] = true,
  ["AI.JointCardsStrategy"] = true,
  ["AI.ViewCardsStrategy"] = true,
  ["AI.ViewCardsAndChoiceStrategy"] = true,
}

local records, recordBySkill = {}, {}
local function recordSkill(skillId, generalName, packageName)
  local record = recordBySkill[skillId]
  if not record then
    record = {
      id = skillId, occurrenceCount = 0, generalCount = 0, generals = {}, packages = {},
      classes = {}, surfaces = {}, strategyTypes = {}, strategyCount = 0,
      handlerKind = "missing", poolFrequencyEstimate = 0,
    }
    recordBySkill[skillId] = record
    records[#records + 1] = record
  end
  record.occurrenceCount = record.occurrenceCount + 1
  local generalSeen = record._generalSeen or {}
  record._generalSeen = generalSeen
  if not generalSeen[generalName] then
    generalSeen[generalName] = true
    record.generalCount = record.generalCount + 1
    record.generals[#record.generals + 1] = generalName
  end
  local packageSeen = record._packageSeen or {}
  record._packageSeen = packageSeen
  if not packageSeen[packageName] then
    packageSeen[packageName] = true
    record.packages[#record.packages + 1] = packageName
  end
end

local function inspectSkill(record)
  local skill = Fk.skills[record.id]
  if not skill then
    record.handlerKind = "missing"
    result.missingSkillCount = result.missingSkillCount + 1
    return
  end
  local classSeen, surfaceSeen, strategySeen = {}, {}, {}
  for _, class in ipairs(effectClasses(skill)) do
    addUnique(record.classes, classSeen, class)
    if class == "ActiveSkill" or class == "ViewAsSkill" or class == "CardSkill" then
      addUnique(record.surfaces, surfaceSeen, "decision")
    elseif class == "TriggerSkill" then
      addUnique(record.surfaces, surfaceSeen, "trigger")
    else
      addUnique(record.surfaces, surfaceSeen, "status")
    end
  end
  local skeleton = type(skill.getSkeleton) == "function" and skill:getSkeleton() or nil
  local hasDecisionStrategy, strategyCount = false, 0
  if skeleton and type(skeleton.ai_strategies) == "table" then
    for klass, list in pairs(skeleton.ai_strategies) do
      local name = className(klass) or tostring(klass)
      if type(list) == "table" then strategyCount = strategyCount + #list end
      if decisionStrategyNames[name] then hasDecisionStrategy = true end
      addUnique(record.strategyTypes, strategySeen, name)
    end
  end
  record.strategyCount = strategyCount
  local hasDecisionSurface = table.contains(record.surfaces, "decision") or hasDecisionStrategy
  if hasDecisionStrategy then
    record.handlerKind = "ai_handler"
    result.aiHandlerSkillCount = result.aiHandlerSkillCount + 1
  elseif hasDecisionSurface then
    record.handlerKind = "default_handler"
    result.defaultHandlerSkillCount = result.defaultHandlerSkillCount + 1
  else
    record.handlerKind = "no_decision_required"
    result.noDecisionSkillCount = result.noDecisionSkillCount + 1
  end
  if hasDecisionSurface then result.decisionSkillCount = result.decisionSkillCount + 1 end
end

for name, general in pairs(Fk.generals) do
  local package = general.package
  local packageName = package and package.name or ""
  if package and not isDisabled(packageName) then
    result.activeGeneralCount = result.activeGeneralCount + 1
    result.activePackageCounts[packageName] = (result.activePackageCounts[packageName] or 0) + 1
    if not general.hidden and not general.total_hidden then result.activeVisibleGeneralCount = result.activeVisibleGeneralCount + 1 end
  end
  if isEligibleGeneral(general) then
    result.eligibleGeneralCount = result.eligibleGeneralCount + 1
    result.poolGeneralNames[#result.poolGeneralNames + 1] = name
    local names, seen = general:getSkillNameList(true), {}
    for _, rawSkill in ipairs(names) do
      local skillId = skillName(rawSkill)
      if skillId and not seen[skillId] then
        seen[skillId] = true
        result.poolSkillReferenceCount = result.poolSkillReferenceCount + 1
        recordSkill(skillId, name, packageName)
      end
    end
  end
end

result.frequencyEvidence.poolEstimate.activeEligibleGenerals = result.eligibleGeneralCount
table.sort(result.poolGeneralNames)
for _, record in ipairs(records) do inspectSkill(record) end
for _, record in ipairs(records) do
  table.sort(record.generals)
  table.sort(record.packages)
  table.sort(record.classes)
  table.sort(record.surfaces)
  table.sort(record.strategyTypes)
  record.poolFrequencyEstimate = record.generalCount / math.max(1, result.eligibleGeneralCount)
  record._generalSeen = nil
  record._packageSeen = nil
end
table.sort(records, function(a, b)
  if a.occurrenceCount ~= b.occurrenceCount then return a.occurrenceCount > b.occurrenceCount end
  return a.id < b.id
end)
result.poolUniqueSkillCount = #records
result.skills = records
return result
`;

function assertShape(report: LuaPrompt4Report): string[] {
  const failures: string[] = [];
  if (report.eligibleGeneralCount < 200) failures.push(`eligible general pool too small: ${report.eligibleGeneralCount}`);
  if (report.poolSkillReferenceCount < 400) failures.push(`pool skill reference count too small: ${report.poolSkillReferenceCount}`);
  if (report.poolUniqueSkillCount < 100) failures.push(`pool unique skill count too small: ${report.poolUniqueSkillCount}`);
  if (report.decisionSkillCount !== report.aiHandlerSkillCount + report.defaultHandlerSkillCount) {
    failures.push('decision skill buckets do not partition handler counts');
  }
  if (report.missingSkillCount !== 0) failures.push(`missing pool skills: ${report.missingSkillCount}`);
  if (report.frequencyEvidence.observedMatches.skillActivationCountsAvailable) {
    failures.push('observed match evidence must remain false until per-skill counts are available');
  }
  return failures;
}

export async function runPrompt4Audit(files: Map<string, Uint8Array> = candidateFiles()): Promise<Prompt4AuditReport> {
  assert.ok(existsSync(UPSTREAM_ROOT), `Missing pinned upstream root: ${UPSTREAM_ROOT}`);
  assert.ok(existsSync(LOCAL_CORE_ROOT), `Missing local core overlay: ${LOCAL_CORE_ROOT}`);
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {}, setup: () => {}, ui: () => {},
    log: (level, message) => { if (level === 'error') throw new Error(message); },
  }});
  try {
    await runtime.start();
    const luaReport = await runtime.eval<LuaPrompt4Report>(LUA_PROMPT4_AUDIT);
    const failures = assertShape(luaReport);
    const skills = luaReport.skills.map(({ _generalSeen, _packageSeen, ...record }: Prompt4SkillRecord & {
      _generalSeen?: unknown;
      _packageSeen?: unknown;
    }) => record);
    return {
      ...luaReport,
      generatedAt: new Date().toISOString(),
      mode: 'new_heg_mode',
      packages: UPSTREAM_PACKAGE_NAMES.map(packageSpec),
      skills,
      priority: buildPrompt4Priority({ eligibleGeneralCount: luaReport.eligibleGeneralCount, skills }),
      backlog: buildPrompt4Backlog(skills),
      failures,
      pass: failures.length === 0,
    };
  } finally {
    runtime.close();
  }
}

function printReport(report: Prompt4AuditReport): void {
  console.log(`Prompt 4 pool: ${report.eligibleGeneralCount} eligible visible generals; ` +
    `${report.poolSkillReferenceCount} deduplicated references / ${report.poolUniqueSkillCount} unique skills`);
  console.log(`Active registry: ${report.activeGeneralCount} generals (${report.activeVisibleGeneralCount} visible); ` +
    `decision skills=${report.decisionSkillCount}, AI handler=${report.aiHandlerSkillCount}, ` +
    `default handler=${report.defaultHandlerSkillCount}, no decision=${report.noDecisionSkillCount}`);
  console.log(`Pool estimate denominator: ${report.frequencyEvidence.poolEstimate.denominator}; ` +
    `observed skill-frequency samples=${report.frequencyEvidence.observedMatches.samples} ` +
    `(available=${report.frequencyEvidence.observedMatches.skillActivationCountsAvailable})`);
  console.log(`Top pool skills: ${report.skills.slice(0, 20).map((skill) =>
    `${skill.id}:${skill.occurrenceCount}/${skill.handlerKind}`).join(', ')}`);
  console.log(`Priority shortlist: ${report.priority.slice(0, 10).map((skill) =>
    `${skill.id}:${skill.priority.toFixed(2)} (${skill.status})`).join(', ')}`);
  console.log(`Ordered unimplemented decision backlog: ${report.backlog.length} skills; ` +
    `${report.backlog.slice(0, 10).map((skill) => `${skill.order}.${skill.id}`).join(', ')}`);
  if (report.failures.length) console.log(`FAIL Prompt 4 audit: ${report.failures.join(' | ')}`);
  console.log(report.pass ? 'PASS Prompt 4 runtime pool inventory' : 'FAIL Prompt 4 runtime pool inventory');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = await runPrompt4Audit();
  if (process.argv.includes('--json')) console.log(JSON.stringify(report, null, 2));
  else printReport(report);
  if (!report.pass && !process.argv.includes('--report-only')) process.exitCode = 1;
}
