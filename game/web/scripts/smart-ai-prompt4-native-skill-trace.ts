/**
 * Metadata-only parser and paired comparison for the native Prompt 4 skill
 * trace emitted by the QA-only `ai-trace` room.
 *
 * The trace is deliberately separate from the historical five-request
 * `tqs_ai_trace` contract.  It proves that the same native SmartAI request
 * handler was exercised once for each selected skill and that the bounded
 * request state can be paired between runs.  It is not gameplay telemetry and
 * captures only semantic target/card/resource shape plus bounded fixture-role
 * alignment and an opt-in coarse AI card-value bucket; it does not infer
 * tactical target quality, downstream effect, win rate, or legal outcomes beyond the native handler's own
 * accepted/fallback/invalid classification.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const PROMPT4_NATIVE_SKILLS = [
  'tianyi', 'shangyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi',
  'hs__longdan', 'hs__luanji', 'hs__wusheng', 'huoji', 'jijiu', 'kanpo',
  'aocai', 'beizhu', 'dimeng', 'choufa', 'cunsi', 'duanfa',
] as const;

export type Prompt4NativeSkill = typeof PROMPT4_NATIVE_SKILLS[number];
export type Prompt4NativeCommand = 'AskForUseActiveSkill' | 'AskForUseCard' | 'AskForResponseCard';
export type Prompt4NativeTargetProfile = 'none' | 'self' | 'ally' | 'enemy' | 'mixed' | 'unknown';
export type Prompt4NativeCardProfile = 'none' | 'physical' | 'skill' | 'table' | 'unknown';
export type Prompt4NativeResourceShape = 'none' | 'one_card' | 'two_cards' | 'many_cards' | 'unknown';
export type Prompt4NativeResourceValue = 'none' | 'low' | 'medium' | 'high' | 'unknown';
export type Prompt4NativeTargetQuality = 'expected' | 'unexpected' | 'no_action' | 'not_applicable' | 'unknown';

export type Prompt4NativeDecision = {
  seq: number;
  skill: Prompt4NativeSkill;
  command: Prompt4NativeCommand;
  input: string;
  offer: string;
  opportunity: boolean;
  offeredCards: number;
  offeredTargets: number;
  accepted: boolean;
  acted: boolean;
  invalid: boolean;
  output: string;
  reason: string;
  detail: string;
  targetProfile: Prompt4NativeTargetProfile;
  cardProfile: Prompt4NativeCardProfile;
  resourceShape: Prompt4NativeResourceShape;
  resourceValue: Prompt4NativeResourceValue;
  selectedCards: number | null;
  selectedTargets: number | null;
  targetQuality: Prompt4NativeTargetQuality;
};

export type Prompt4NativeTrace = {
  scenario: string;
  seed: number;
  revision: string;
  decisions: Prompt4NativeDecision[];
  opportunities: number;
  accepted: number;
  acted: number;
  misses: number;
  fallback: number;
  invalid: number;
  errors: number;
  pairVerified: boolean;
  stateVerified: boolean;
  fixtureVerified: boolean;
  shapeMetadataVerified: boolean;
};

export type Prompt4NativeComparison = {
  schemaVersion: 1;
  kind: 'prompt4_native_skill_trace_pair';
  scenario: string | null;
  seed: number | null;
  pairVerified: boolean;
  stateVerified: boolean;
  fixtureVerified: boolean;
  shapeMetadataVerified: boolean;
  baselineDecisions: number;
  candidateDecisions: number;
  matchedRequests: number;
  changedOpportunities: number;
  changedAccepted: number;
  changedActed: number;
  changedOutputShapes: number;
  changedFallbackReasons: number;
  changedTargetProfiles: number;
  changedCardProfiles: number;
  changedResourceShapes: number;
  changedResourceValues: number;
  changedSelectedCardCounts: number;
  changedSelectedTargetCounts: number;
  changedTargetQualities: number;
  changedInvalid: number;
  baselineOpportunities: number;
  candidateOpportunities: number;
  baselineInvalid: number;
  candidateInvalid: number;
  mismatches: Array<{
    seq: number;
    skill: string | null;
    category: 'request_state' | 'missing_decision' | 'skill_order' | 'opportunity' | 'reply';
  }>;
  issues: string[];
  status: 'MATCHED_NATIVE_SKILLS' | 'INCONCLUSIVE';
  safetyStatus: 'NO_INVALID_NATIVE_REPLIES' | 'INVALID_NATIVE_REPLIES' | 'INCONCLUSIVE';
  nativeOpportunityDenominatorAvailable: true;
  nativeTargetQualityAvailable: boolean;
  nativeReplySnapshotAvailable: boolean;
  nativeResourceValueAvailable: boolean;
  observedMatchFrequencyAvailable: false;
  winRateAvailable: false;
  limitations: string[];
};

const TOKEN = /^[a-zA-Z0-9_-]{1,64}$/u;
const HEX = /^[0-9a-f]{8}$/u;
const SUMMARY = /\[tqs_prompt4_trace\] summary scenario=(\S+) seed=(\d+) revision=(\S+) decisions=(\d+) opportunities=(\d+) accepted=(\d+) acted=(\d+) misses=(\d+) fallback=(\d+) invalid=(\d+) errors=(\d+) pair=(verified|unverified) state=(verified|unverified) fixture=(semantic_v1) skills=(\d+)(?: metadata=(shape_v1))?\s*$/u;
const DECISION = /\[tqs_prompt4_trace\] decision scenario=(\S+) seed=(\d+) revision=(\S+) seq=(\d+) skill=(\S+) command=(\S+) input=(\S+) offer=(\S+) opportunity=(0|1) offered_cards=(\d+) offered_targets=(\d+) accepted=(0|1) acted=(0|1) invalid=(0|1) output=(\S+) reason=(\S+) detail=(\S+)(?: target_profile=(none|self|ally|enemy|mixed|unknown) card_profile=(none|physical|skill|table|unknown) resource_shape=(none|one_card|two_cards|many_cards|unknown)(?: selected_cards=(\d+) selected_targets=(\d+) target_quality=(expected|unexpected|no_action|not_applicable|unknown)(?: resource_value=(none|low|medium|high|unknown))?)?)?\s*$/u;

function boundedInteger(value: string): number {
  if (!/^\d{1,15}$/u.test(value) || !Number.isSafeInteger(Number(value))) {
    throw new Error('invalid bounded native Prompt 4 counter');
  }
  return Number(value);
}

function token(value: string): string {
  if (!TOKEN.test(value)) throw new Error('invalid native Prompt 4 metadata token');
  return value;
}

function hex(value: string): string {
  if (!HEX.test(value)) throw new Error('invalid native Prompt 4 fingerprint');
  return value;
}

function isOutputShape(value: string): boolean {
  return value === 'nil' || value === 'cancel' || value === 'string' || value === 'boolean' ||
    value === 'number' || value === 'table' ||
    /^(?:table\/card=(?:number|nil|table|skill|boolean|string)\/targets=\d{1,3}\/special=[01]\/interaction=[01])$/u.test(value);
}

function skill(value: string): Prompt4NativeSkill {
  if (!PROMPT4_NATIVE_SKILLS.includes(value as Prompt4NativeSkill)) {
    throw new Error('unexpected Prompt 4 native skill');
  }
  return value as Prompt4NativeSkill;
}

export function parsePrompt4NativeSkillTrace(log: string): Prompt4NativeTrace {
  let summary: Prompt4NativeTrace | null = null;
  let expectedDecisions: number | null = null;
  const decisions: Prompt4NativeDecision[] = [];
  for (const line of log.split(/\r?\n/u)) {
    if (!line.includes('[tqs_prompt4_trace]')) continue;
    if (line.includes('[tqs_prompt4_trace] summary ')) {
      const fields = line.match(SUMMARY);
      if (!fields || summary) throw new Error('missing, duplicate or malformed Prompt 4 native summary');
      summary = {
        scenario: token(fields[1]), seed: boundedInteger(fields[2]), revision: token(fields[3]),
        decisions: [], opportunities: boundedInteger(fields[5]), accepted: boundedInteger(fields[6]),
        acted: boundedInteger(fields[7]), misses: boundedInteger(fields[8]),
        fallback: boundedInteger(fields[9]), invalid: boundedInteger(fields[10]),
        errors: boundedInteger(fields[11]), pairVerified: fields[12] === 'verified',
        stateVerified: fields[13] === 'verified', fixtureVerified: fields[14] === 'semantic_v1',
        shapeMetadataVerified: fields[16] === 'shape_v1',
      };
      expectedDecisions = boundedInteger(fields[4]);
      if (boundedInteger(fields[15]) !== PROMPT4_NATIVE_SKILLS.length ||
          expectedDecisions !== PROMPT4_NATIVE_SKILLS.length) {
        throw new Error('Prompt 4 native skill count mismatch');
      }
      continue;
    }
    if (!line.includes('[tqs_prompt4_trace] decision ')) continue;
    const fields = line.match(DECISION);
    if (!fields) throw new Error('malformed Prompt 4 native decision');
    const decision: Prompt4NativeDecision = {
      seq: boundedInteger(fields[4]), skill: skill(fields[5]),
      command: fields[6] === 'AskForUseActiveSkill' || fields[6] === 'AskForUseCard' ||
        fields[6] === 'AskForResponseCard' ? fields[6] : (() => {
          throw new Error('Prompt 4 native trace contains an unsupported request command');
        })(),
      input: hex(fields[7]), offer: hex(fields[8]), opportunity: fields[9] === '1',
      offeredCards: boundedInteger(fields[10]), offeredTargets: boundedInteger(fields[11]),
      accepted: fields[12] === '1', acted: fields[13] === '1', invalid: fields[14] === '1',
      output: fields[15], reason: token(fields[16]), detail: token(fields[17]),
      targetProfile: (fields[18] ?? 'unknown') as Prompt4NativeTargetProfile,
      cardProfile: (fields[19] ?? 'unknown') as Prompt4NativeCardProfile,
      resourceShape: (fields[20] ?? 'unknown') as Prompt4NativeResourceShape,
      selectedCards: fields[21] ? boundedInteger(fields[21]) : null,
      selectedTargets: fields[22] ? boundedInteger(fields[22]) : null,
      targetQuality: (fields[23] ?? 'unknown') as Prompt4NativeTargetQuality,
      resourceValue: (fields[24] ?? 'unknown') as Prompt4NativeResourceValue,
    };
    if (!isOutputShape(decision.output)) throw new Error('unexpected Prompt 4 native output shape');
    decisions.push(decision);
    if (decisions.length > PROMPT4_NATIVE_SKILLS.length) {
      throw new Error('Prompt 4 native trace capacity exceeded');
    }
  }
  if (!summary) throw new Error('Prompt 4 native summary is missing');
  if (summary.scenario !== 'ai-trace') throw new Error('unexpected Prompt 4 native trace scenario');
  if (!summary.pairVerified || !summary.stateVerified || !summary.fixtureVerified) {
    throw new Error('Prompt 4 native fixture is not verified');
  }
  if (summary.shapeMetadataVerified && decisions.some((decision) => decision.targetProfile === 'unknown' ||
      decision.cardProfile === 'unknown' || decision.resourceShape === 'unknown')) {
    throw new Error('Prompt 4 native shape metadata is incomplete');
  }
  if (summary.errors > 0) throw new Error('Prompt 4 native trace has probe errors');
  if (decisions.length !== expectedDecisions || decisions.length !== PROMPT4_NATIVE_SKILLS.length) {
    throw new Error('Prompt 4 native decision count mismatch');
  }
  decisions.forEach((decision, index) => {
    if (decision.seq !== index + 1 || decision.skill !== PROMPT4_NATIVE_SKILLS[index] ||
        decision.offeredCards < 0 || decision.offeredTargets < 0) {
      throw new Error('Prompt 4 native skill order or counter mismatch');
    }
    if (!decision.opportunity && decision.acted) {
      throw new Error('Prompt 4 native acted without an opportunity');
    }
  });
  const opportunities = decisions.filter((decision) => decision.opportunity).length;
  const accepted = decisions.filter((decision) => decision.accepted).length;
  const acted = decisions.filter((decision) => decision.acted).length;
  const misses = decisions.filter((decision) => decision.opportunity && !decision.acted).length;
  const fallback = decisions.filter((decision) => decision.reason !== 'accepted').length;
  const invalid = decisions.filter((decision) => decision.invalid).length;
  if (opportunities !== summary.opportunities || accepted !== summary.accepted || acted !== summary.acted ||
      misses !== summary.misses || fallback !== summary.fallback || invalid !== summary.invalid) {
    throw new Error('Prompt 4 native summary counters mismatch');
  }
  for (const line of log.split(/\r?\n/u)) {
    if (!line.includes('[tqs_prompt4_trace] decision ')) continue;
    const fields = line.match(DECISION)!;
    if (fields[1] !== summary.scenario || Number(fields[2]) !== summary.seed || fields[3] !== summary.revision) {
      throw new Error('Prompt 4 native trace contains mixed run identities');
    }
  }
  summary.decisions = decisions;
  return summary;
}

export function comparePrompt4NativeSkillTraces(
  baseline: Prompt4NativeTrace,
  candidate: Prompt4NativeTrace,
): Prompt4NativeComparison {
  const issues: string[] = [];
  if (baseline.scenario !== candidate.scenario) issues.push('scenario_mismatch');
  if (baseline.seed !== candidate.seed) issues.push('seed_mismatch');
  if (baseline.revision !== candidate.revision) issues.push('revision_mismatch');
  if (!baseline.pairVerified || !candidate.pairVerified) issues.push('pair_not_verified');
  if (!baseline.stateVerified || !candidate.stateVerified) issues.push('state_not_verified');
  if (!baseline.fixtureVerified || !candidate.fixtureVerified) issues.push('fixture_not_verified');
  if (baseline.shapeMetadataVerified !== candidate.shapeMetadataVerified) issues.push('shape_metadata_mismatch');
  if (baseline.errors > 0 || candidate.errors > 0) issues.push('probe_errors');
  const mismatches: Prompt4NativeComparison['mismatches'] = [];
  let matchedRequests = 0;
  let changedOpportunities = 0;
  let changedAccepted = 0;
  let changedActed = 0;
  let changedOutputShapes = 0;
  let changedFallbackReasons = 0;
  let changedTargetProfiles = 0;
  let changedCardProfiles = 0;
  let changedResourceShapes = 0;
  let changedResourceValues = 0;
  let changedSelectedCardCounts = 0;
  let changedSelectedTargetCounts = 0;
  let changedTargetQualities = 0;
  let changedInvalid = 0;
  const max = Math.max(baseline.decisions.length, candidate.decisions.length);
  for (let index = 0; index < max; index++) {
    const left = baseline.decisions[index];
    const right = candidate.decisions[index];
    if (!left || !right) {
      mismatches.push({ seq: index + 1, skill: left?.skill ?? right?.skill ?? null, category: 'missing_decision' });
      continue;
    }
    if (left.seq !== right.seq || left.skill !== right.skill || left.command !== right.command ||
        left.input !== right.input || left.offer !== right.offer) {
      mismatches.push({ seq: index + 1, skill: left.skill, category: left.skill !== right.skill ? 'skill_order' : 'request_state' });
      continue;
    }
    matchedRequests++;
    if (left.opportunity !== right.opportunity || left.offeredCards !== right.offeredCards ||
        left.offeredTargets !== right.offeredTargets) changedOpportunities++;
    if (left.accepted !== right.accepted) changedAccepted++;
    if (left.acted !== right.acted) changedActed++;
    if (left.output !== right.output) changedOutputShapes++;
    if (left.reason !== right.reason || left.detail !== right.detail) changedFallbackReasons++;
    if (left.targetProfile !== right.targetProfile) changedTargetProfiles++;
    if (left.cardProfile !== right.cardProfile) changedCardProfiles++;
    if (left.resourceShape !== right.resourceShape) changedResourceShapes++;
    if (left.resourceValue !== right.resourceValue) changedResourceValues++;
    if (left.selectedCards !== right.selectedCards) changedSelectedCardCounts++;
    if (left.selectedTargets !== right.selectedTargets) changedSelectedTargetCounts++;
    if (left.targetQuality !== right.targetQuality) changedTargetQualities++;
    if (left.invalid !== right.invalid) changedInvalid++;
    if (left.opportunity !== right.opportunity) mismatches.push({ seq: left.seq, skill: left.skill, category: 'opportunity' });
    if (left.accepted !== right.accepted || left.acted !== right.acted || left.output !== right.output ||
        left.reason !== right.reason || left.detail !== right.detail || left.invalid !== right.invalid ||
        left.targetProfile !== right.targetProfile || left.cardProfile !== right.cardProfile ||
        left.resourceShape !== right.resourceShape || left.resourceValue !== right.resourceValue ||
        left.selectedCards !== right.selectedCards ||
        left.selectedTargets !== right.selectedTargets || left.targetQuality !== right.targetQuality) {
      mismatches.push({ seq: left.seq, skill: left.skill, category: 'reply' });
    }
  }
  if (baseline.decisions.length === 0 || candidate.decisions.length === 0) issues.push('empty_trace');
  // Baseline and candidate are expected to differ in reply behavior when the
  // candidate adds Prompt 4 strategies.  The pair gate therefore requires all
  // bounded request fingerprints to match, while retaining reply deltas for
  // the safety/regression review below.
  const requestMismatches = mismatches.some((entry) => entry.category !== 'reply');
  const status = issues.length === 0 && !requestMismatches ? 'MATCHED_NATIVE_SKILLS' : 'INCONCLUSIVE';
  const nativeTargetQualityAvailable = [baseline, candidate].every((trace) =>
    trace.decisions.every((decision) => decision.targetQuality !== 'unknown'));
  const nativeReplySnapshotAvailable = [baseline, candidate].every((trace) =>
    trace.decisions.every((decision) => decision.selectedCards !== null && decision.selectedTargets !== null));
  const nativeResourceValueAvailable = [baseline, candidate].every((trace) =>
    trace.decisions.every((decision) => decision.resourceValue !== 'unknown'));
  return {
    schemaVersion: 1, kind: 'prompt4_native_skill_trace_pair',
    scenario: baseline.scenario === candidate.scenario ? baseline.scenario : null,
    seed: baseline.seed === candidate.seed ? baseline.seed : null,
    pairVerified: baseline.pairVerified && candidate.pairVerified,
    stateVerified: baseline.stateVerified && candidate.stateVerified,
    fixtureVerified: baseline.fixtureVerified && candidate.fixtureVerified,
    shapeMetadataVerified: baseline.shapeMetadataVerified && candidate.shapeMetadataVerified,
    baselineDecisions: baseline.decisions.length, candidateDecisions: candidate.decisions.length,
    matchedRequests, changedOpportunities, changedAccepted, changedActed, changedOutputShapes,
    changedFallbackReasons, changedTargetProfiles, changedCardProfiles, changedResourceShapes,
    changedResourceValues,
    changedSelectedCardCounts, changedSelectedTargetCounts, changedTargetQualities, changedInvalid,
    baselineOpportunities: baseline.opportunities, candidateOpportunities: candidate.opportunities,
    baselineInvalid: baseline.invalid, candidateInvalid: candidate.invalid,
    mismatches, issues, status,
    safetyStatus: status === 'INCONCLUSIVE' ? 'INCONCLUSIVE' :
      (baseline.invalid === 0 && candidate.invalid === 0 ? 'NO_INVALID_NATIVE_REPLIES' : 'INVALID_NATIVE_REPLIES'),
    nativeOpportunityDenominatorAvailable: true,
    nativeTargetQualityAvailable,
    nativeReplySnapshotAvailable,
    nativeResourceValueAvailable,
    observedMatchFrequencyAvailable: false,
    winRateAvailable: false,
    limitations: [
      'The request fingerprint is a bounded QA snapshot, not an exhaustive native-state serialization.',
      'Opportunity counts cover enabled cards/targets in the real request handler, not every latent rule branch.',
      'Accepted/acted is a reply-shape and selection signal; it does not prove target quality or downstream effect success.',
      'Target profile, card profile, and resource shape are sanitized reply-shape metadata; the optional resource-value bucket is a coarse AI keep-value class, not a tactical value or downstream effect score.',
      'Baseline/candidate reply differences are retained as bounded behavior deltas; MATCHED_NATIVE_SKILLS means the eighteen request states paired, not that replies are identical.',
      'Invalid replies are reported separately and keep the safety status failed even when the paired state matches.',
      'This paired trace is not a win-rate sample and must not update observedMatchFrequency.',
    ],
  };
}

function main(args: string[]): void {
  const [baselinePath, candidatePath, outputPath] = args;
  if (!baselinePath || !candidatePath) {
    throw new Error('usage: smart-ai-prompt4-native-skill-trace.ts <baseline-log> <candidate-log> [output-json]');
  }
  const result = comparePrompt4NativeSkillTraces(
    parsePrompt4NativeSkillTrace(fs.readFileSync(baselinePath, 'utf8')),
    parsePrompt4NativeSkillTrace(fs.readFileSync(candidatePath, 'utf8')),
  );
  const serialized = `${JSON.stringify(result, null, 2)}\n`;
  if (outputPath) fs.writeFileSync(outputPath, serialized, { mode: 0o600 });
  else process.stdout.write(serialized);
  if (result.status !== 'MATCHED_NATIVE_SKILLS') process.exitCode = 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main(process.argv.slice(2));
