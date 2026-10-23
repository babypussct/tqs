/**
 * Strict, metadata-only comparison of native QA `ai-trace` decisions.
 *
 * An equal seed is not enough to compare two AI policies. The real native
 * `makeReply()` calls must also see identical bounded request-state hashes.
 * These hashes are useful as an equality guard, but are not a full snapshot
 * of every engine state variable or proof of equivalent gameplay trajectories.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export type AiTraceDecision = {
  seq: number;
  seat: number;
  command: string;
  skill: string;
  input: string;
  output: string;
  reason: string;
  detail: string;
};

export type AiTraceRun = {
  scenario: string;
  seed: number;
  revision: string;
  pairVerified: boolean;
  fixedHandsVerified: boolean;
  semanticFixtureVerified: boolean;
  skillProvenanceVerified: boolean;
  decisions: AiTraceDecision[];
  fallback: number;
  probeErrors: number;
  overflow: boolean;
  reasons: Record<string, number>;
};

export type AiTraceComparison = {
  schemaVersion: 1;
  kind: 'prompt4_native_bounded_request_replay';
  scenario: string | null;
  seed: number | null;
  pairVerified: boolean;
  fixedHandsVerified: boolean;
  semanticFixtureVerified: boolean;
  skillProvenanceVerified: boolean;
  baselineDecisions: number;
  candidateDecisions: number;
  matchedRequests: number;
  changedOutputShapes: number;
  changedFallbackReasons: number;
  changedSkillAttributions: number;
  baselineReasons: Record<string, number>;
  candidateReasons: Record<string, number>;
  mismatches: Array<{ seq: number; category: 'request_state' | 'missing_decision' }>;
  issues: string[];
  status: 'MATCHED_BOUNDED_REQUESTS' | 'INCONCLUSIVE';
  nativeOpportunityDenominatorAvailable: false;
  nativeTargetQualityAvailable: false;
  nativeResourceValueAvailable: false;
  observedMatchFrequencyAvailable: false;
  winRateAvailable: false;
  limitations: string[];
};

const TOKEN = /^[a-zA-Z0-9_-]{1,64}$/u;
const HEX = /^[0-9a-f]{8}$/u;
const DECISION = /\[tqs_ai_trace\] decision scenario=(\S+) seed=(\d+) revision=(\S+) seq=(\d+) seat=(\d+) command=(\S+)(?: skill=(\S+))? input=(\S+) output=(\S+) reason=(\S+) detail=(\S+)\s*$/u;
// Legacy summaries parse for historical review, but lack the explicit native
// fixture verification required for a new MATCHED_BOUNDED_REQUESTS result.
const SUMMARY = /\[tqs_ai_trace\] summary scenario=(\S+) seed=(\d+) revision=(\S+) decisions=(\d+) fallback=(\d+) probe_errors=(\d+) overflow=(true|false) reasons=(\S+?)(?: pair=(verified|unverified) hands=(verified|unverified))?(?: fixture=(semantic_v[23]))?\s*$/u;

function boundedInteger(value: string): number {
  if (!/^\d{1,15}$/u.test(value) || !Number.isSafeInteger(Number(value))) {
    throw new Error('invalid bounded native counter');
  }
  return Number(value);
}

function token(value: string): string {
  if (!TOKEN.test(value)) throw new Error('invalid native metadata token');
  return value;
}

function parseReasons(encoded: string): Record<string, number> {
  if (encoded === '-') return {};
  const result: Record<string, number> = Object.create(null);
  for (const pair of encoded.split(',')) {
    const parts = pair.split(':');
    if (parts.length !== 2) throw new Error('invalid native reason summary');
    const reason = token(parts[0]);
    if (Object.hasOwn(result, reason)) throw new Error('duplicate native reason');
    result[reason] = boundedInteger(parts[1]);
  }
  return result;
}

export function parseAiTraceLog(log: string): AiTraceRun {
  let summary: Omit<AiTraceRun, 'decisions'> | null = null;
  let expectedDecisions: number | null = null;
  const decisions: AiTraceDecision[] = [];
  for (const line of log.split(/\r?\n/u)) {
    if (!line.includes('[tqs_ai_trace]')) continue;
    if (line.includes('[tqs_ai_trace] summary ')) {
      const fields = line.match(SUMMARY);
      if (!fields || summary) throw new Error('missing, duplicate or malformed ai-trace summary');
      summary = {
        scenario: token(fields[1]), seed: boundedInteger(fields[2]), revision: token(fields[3]),
        fallback: boundedInteger(fields[5]), probeErrors: boundedInteger(fields[6]),
        overflow: fields[7] === 'true', reasons: parseReasons(fields[8]),
        pairVerified: fields[9] === 'verified', fixedHandsVerified: fields[10] === 'verified',
        semanticFixtureVerified: fields[11] === 'semantic_v3' &&
          fields[9] === 'verified' && fields[10] === 'verified',
        skillProvenanceVerified: fields[11] === 'semantic_v3',
      };
      expectedDecisions = boundedInteger(fields[4]);
      if (expectedDecisions > 4096) throw new Error('ai-trace bounded capacity exceeded');
      continue;
    }
    if (!line.includes('[tqs_ai_trace] decision ')) continue;
    const fields = line.match(DECISION);
    if (!fields) throw new Error('malformed ai-trace decision');
    const skill = fields[7] ? token(fields[7]) : 'unknown';
    if (!/[A-Za-z_]/u.test(skill)) throw new Error('invalid bounded skill attribution');
    const input = fields[8];
    if (!HEX.test(input)) throw new Error('invalid bounded request-state fingerprint');
    const output = fields[9];
    if (!(output === 'nil' || output === 'cancel' || output === 'string' ||
      /^(?:boolean|number|table|table\/card=(?:number|nil|table|skill|boolean|string)\/targets=\d{1,3}\/special=[01]\/interaction=[01])$/u.test(output))) {
      throw new Error('unexpected output shape in native trace');
    }
    decisions.push({
      seq: boundedInteger(fields[4]), seat: boundedInteger(fields[5]),
      command: token(fields[6]), skill, input, output,
      reason: token(fields[10]), detail: token(fields[11]),
    });
    if (decisions.length > 4096) throw new Error('ai-trace decision capacity exceeded');
  }
  if (!summary) throw new Error('ai-trace summary is missing');
  if (summary.scenario !== 'ai-trace') throw new Error('unexpected native trace scenario');
  if (summary.overflow || summary.probeErrors > 0) throw new Error('ai-trace is incomplete or has probe errors');
  const counts: Record<string, number> = Object.create(null);
  decisions.forEach((decision, index) => {
    if (decision.seq !== index + 1 || decision.seat < 1 || decision.seat > 4) {
      throw new Error('native ai-trace sequence or seat mismatch');
    }
    counts[decision.reason] = (counts[decision.reason] || 0) + 1;
  });
  if (decisions.length !== expectedDecisions) {
    throw new Error('ai-trace summary decision count mismatch');
  }
  if (summary.scenario === 'ai-trace' && (decisions.length !== 5 ||
      decisions.some((entry, index) => index < 4 ?
        entry.seat !== index + 1 || entry.command !== 'PlayCard' :
        entry.seat !== 1 || entry.command !== 'AskForUseActiveSkill'))) {
    throw new Error('ai-trace required four PlayCard seats and active-skill command coverage');
  }
  const actualFallback = decisions.filter((decision) => decision.reason !== 'accepted').length;
  if (actualFallback !== summary.fallback ||
      JSON.stringify(Object.entries(counts).sort()) !== JSON.stringify(Object.entries(summary.reasons).sort())) {
    throw new Error('ai-trace reason counters mismatch');
  }
  // The native emitter includes run identity on every decision. A mixed-room
  // log is never safe to treat as one deterministic matched replay.
  for (const line of log.split(/\r?\n/u)) {
    if (!line.includes('[tqs_ai_trace] decision ')) continue;
    const fields = line.match(DECISION)!;
    if (fields[1] !== summary.scenario || Number(fields[2]) !== summary.seed || fields[3] !== summary.revision) {
      throw new Error('ai-trace contains mixed run identities');
    }
  }
  return {
    ...summary,
    skillProvenanceVerified: summary.skillProvenanceVerified &&
      decisions.every((decision) => decision.skill !== 'unknown'),
    decisions,
  };
}

export function compareAiTraceRuns(baseline: AiTraceRun, candidate: AiTraceRun): AiTraceComparison {
  const issues: string[] = [];
  if (baseline.scenario !== candidate.scenario) issues.push('scenario_mismatch');
  if (baseline.seed !== candidate.seed) issues.push('seed_mismatch');
  if (baseline.revision !== candidate.revision) issues.push('revision_mismatch');
  if (!baseline.pairVerified || !candidate.pairVerified) issues.push('pair_not_verified');
  if (!baseline.fixedHandsVerified || !candidate.fixedHandsVerified) issues.push('fixed_hands_not_verified');
  if (!baseline.semanticFixtureVerified || !candidate.semanticFixtureVerified) issues.push('semantic_fixture_not_verified');
  if (!baseline.skillProvenanceVerified || !candidate.skillProvenanceVerified) {
    issues.push('skill_provenance_not_verified');
  }
  const mismatches: AiTraceComparison['mismatches'] = [];
  let matchedRequests = 0;
  let changedOutputShapes = 0;
  let changedFallbackReasons = 0;
  let changedSkillAttributions = 0;
  const max = Math.max(baseline.decisions.length, candidate.decisions.length);
  for (let index = 0; index < max; index++) {
    const left = baseline.decisions[index];
    const right = candidate.decisions[index];
    if (!left || !right) {
      mismatches.push({ seq: index + 1, category: 'missing_decision' });
    } else if (left.seq !== right.seq || left.seat !== right.seat ||
        left.command !== right.command || left.input !== right.input) {
      mismatches.push({ seq: index + 1, category: 'request_state' });
    } else {
      matchedRequests++;
      if (left.output !== right.output) changedOutputShapes++;
      if (left.reason !== right.reason || left.detail !== right.detail) changedFallbackReasons++;
      if (left.skill !== right.skill) changedSkillAttributions++;
    }
  }
  if (baseline.decisions.length === 0 || candidate.decisions.length === 0) issues.push('empty_trace');
  return {
    schemaVersion: 1, kind: 'prompt4_native_bounded_request_replay',
    scenario: baseline.scenario === candidate.scenario ? baseline.scenario : null,
    seed: baseline.seed === candidate.seed ? baseline.seed : null,
    pairVerified: baseline.pairVerified && candidate.pairVerified,
    fixedHandsVerified: baseline.fixedHandsVerified && candidate.fixedHandsVerified,
    semanticFixtureVerified: baseline.semanticFixtureVerified && candidate.semanticFixtureVerified,
    skillProvenanceVerified: baseline.skillProvenanceVerified && candidate.skillProvenanceVerified,
    baselineDecisions: baseline.decisions.length,
    candidateDecisions: candidate.decisions.length,
    matchedRequests, changedOutputShapes, changedFallbackReasons,
    changedSkillAttributions,
    baselineReasons: baseline.reasons, candidateReasons: candidate.reasons,
    mismatches, issues,
    status: issues.length === 0 && mismatches.length === 0 ? 'MATCHED_BOUNDED_REQUESTS' : 'INCONCLUSIVE',
    nativeOpportunityDenominatorAvailable: false,
    nativeTargetQualityAvailable: false,
    nativeResourceValueAvailable: false,
    observedMatchFrequencyAvailable: false,
    winRateAvailable: false,
    limitations: [
      'A fingerprint is a bounded QA snapshot, not a collision-proof or exhaustive serialization of native state.',
      'Native QA must verify the actual four seat pairs and the presence of pinned fixture hands before recording a matched request.',
      'Only semantic_v2 evidence checks exact hand cardinality, the card trueName/suit/color and five ordered native decisions.',
      'An equal request fingerprint does not establish an equal full-match trajectory.',
      'Skill attribution, reply shape and fallback reason do not measure target correctness, card resource value or every legal opportunity.',
      'This paired trace is not a win-rate sample and must not update observedMatchFrequency.',
    ],
  };
}

function main(args: string[]): void {
  const [baselinePath, candidatePath, outputPath] = args;
  if (!baselinePath || !candidatePath) {
    throw new Error('usage: smart-ai-prompt4-native-replay.ts <baseline-native-log> <candidate-native-log> [output-json]');
  }
  const result = compareAiTraceRuns(
    parseAiTraceLog(fs.readFileSync(baselinePath, 'utf8')),
    parseAiTraceLog(fs.readFileSync(candidatePath, 'utf8')),
  );
  const serialized = `${JSON.stringify(result, null, 2)}\n`;
  if (outputPath) fs.writeFileSync(outputPath, serialized, { mode: 0o600 });
  else process.stdout.write(serialized);
  if (result.status !== 'MATCHED_BOUNDED_REQUESTS') process.exitCode = 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main(process.argv.slice(2));
