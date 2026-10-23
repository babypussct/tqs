/** Strict metadata-only matched six-case native generic chooser replay.
 * FNV32 request hashes guard observable equality only, not full native-state
 * identity; a matched six-case replay is not a causal full-match win-rate test.
 */
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const SKILLS = ['choose_players_skill', 'choose_cards_skill', 'ex__choose_skill'] as const;
const TOKEN = /^[a-zA-Z0-9_-]{1,64}$/u;
const HEX = /^[0-9a-f]{8}$/u;
const SUMMARY = /\[tqs_chooser_trace\] summary scenario=(\S+) seed=(\d+) revision=(\S+) decisions=(\d+) opportunities=(\d+) accepted=(\d+) missed=(\d+) fallback=(\d+) invalid=(\d+) errors=(\d+) pair=(\S+) hands=(\S+) fixture=(\S+)\s*$/u;
const DECISION = /\[tqs_chooser_trace\] decision scenario=(\S+) seed=(\d+) revision=(\S+) seq=(\d+) skill=(\S+) variant=(\S+) input=(\S+) offer=(\S+) opportunity=(\d+) offered_cards=(\d+) offered_targets=(\d+) accepted=(\d+) acted=(\d+) chosen_cards=(\d+) chosen_targets=(\d+) invalid=(\d+) reason=(\S+) detail=(\S+)\s*$/u;

export type ChooserDecision = {
  seq: number; skill: string; variant: 'mandatory' | 'optional';
  input: string; offer: string; opportunity: number;
  offeredCards: number; offeredTargets: number;
  accepted: number; acted: number; chosenCards: number; chosenTargets: number;
  invalid: number; reason: string; detail: string;
};
export type ChooserRun = {
  scenario: 'chooser-trace'; seed: number; revision: string;
  decisions: ChooserDecision[]; opportunities: number;
  accepted: number; missed: number; fallback: number; invalid: number;
};
export type ChooserReview = {
  schemaVersion: 2;
  kind: 'prompt4_native_generic_chooser_matched_request_replay';
  status: 'MATCHED_BOUNDED_REQUESTS' | 'INCONCLUSIVE';
  scenario: string; seed: number;
  comparedCases: number; mismatchedCases: number[];
  bySkill: Record<string, {
    baseline: { opportunities: number; misses: number; accepted: number; acted: number; fallback: number; invalid: number; acceptedNoAction: number; voluntaryOptionalCancel: number; optionalNoDecisionFallback: number };
    candidate: { opportunities: number; misses: number; accepted: number; acted: number; fallback: number; invalid: number; acceptedNoAction: number; voluntaryOptionalCancel: number; optionalNoDecisionFallback: number };
  }>;
  nativeFeasibilityValidatedForAccepted: true;
  nativeLegalOfferCountsAvailable: true;
  nativeStrategicTargetQualityAvailable: false;
  nativeResourceValueAvailable: false;
  observedMatchFrequencyAvailable: false;
  winRateAvailable: false;
  limitations: string[];
};

function num(value: string, max = 10000): number {
  if (!/^\d{1,10}$/u.test(value) || !Number.isSafeInteger(Number(value)) || Number(value) > max) {
    throw new Error('invalid bounded chooser metric');
  }
  return Number(value);
}
function token(value: string): string {
  if (!TOKEN.test(value)) throw new Error('invalid bounded chooser token');
  return value;
}

export function parseChooserTraceLog(raw: string): ChooserRun {
  let summary: RegExpMatchArray | undefined;
  const decisions: ChooserDecision[] = [];
  for (const line of raw.split(/\r?\n/u)) {
    if (!line.includes('[tqs_chooser_trace]')) continue;
    if (line.includes('[tqs_chooser_trace] summary ')) {
      if (summary) throw new Error('duplicate chooser summary');
      summary = line.match(SUMMARY) ?? undefined;
      if (!summary) throw new Error('invalid chooser summary');
      continue;
    }
    if (!line.includes('[tqs_chooser_trace] decision ')) continue;
    const match = line.match(DECISION);
    if (!match) throw new Error('invalid chooser decision');
    const seq = num(match[4], 6);
    const skill = token(match[5]);
    const variant = token(match[6]);
    if (seq !== decisions.length + 1 || skill !== SKILLS[(seq - 1) % 3] ||
        variant !== (seq <= 3 ? 'mandatory' : 'optional') ||
        !HEX.test(match[7]) || !HEX.test(match[8])) {
      throw new Error('chooser case order, skill, variant or fingerprint drift');
    }
    const entry: ChooserDecision = {
      seq, skill, variant: variant as 'mandatory' | 'optional',
      input: match[7], offer: match[8], opportunity: num(match[9], 1),
      offeredCards: num(match[10], 4), offeredTargets: num(match[11], 3),
      accepted: num(match[12], 1), acted: num(match[13], 1),
      chosenCards: num(match[14], 4), chosenTargets: num(match[15], 4),
      invalid: num(match[16], 1), reason: token(match[17]), detail: token(match[18]),
    };
    const actedFromSelection = skill === 'choose_players_skill' ? entry.chosenTargets > 0 :
      skill === 'choose_cards_skill' ? entry.chosenCards > 0 :
      entry.chosenCards > 0 && entry.chosenTargets > 0;
    if (entry.opportunity !== 1 || (skill === 'choose_cards_skill' && entry.offeredCards === 0) ||
        (skill === 'choose_players_skill' && entry.offeredTargets === 0) ||
        (skill === 'ex__choose_skill' && (entry.offeredCards === 0 || entry.offeredTargets === 0)) ||
        entry.acted !== Number(entry.accepted === 1 && actedFromSelection) ||
        entry.chosenCards > entry.offeredCards || entry.chosenTargets > entry.offeredTargets ||
        (skill === 'choose_players_skill' && entry.chosenCards !== 0) ||
        (skill === 'choose_cards_skill' && entry.chosenTargets !== 0) ||
        (entry.accepted === 0 && (entry.chosenCards > 0 || entry.chosenTargets > 0)) ||
        (entry.accepted === 1 && (entry.reason !== 'accepted' || entry.invalid > 0)) ||
        (entry.accepted === 0 && entry.reason === 'accepted') ||
        (variant === 'mandatory' && entry.accepted === 1 && entry.acted === 0) ||
        (skill === 'ex__choose_skill' && entry.accepted === 1 &&
          entry.chosenCards !== entry.chosenTargets)) {
      throw new Error('impossible chooser decision metrics');
    }
    decisions.push(entry);
  }
  if (!summary || summary[1] !== 'chooser-trace' || summary[11] !== 'verified' ||
      summary[12] !== 'verified' || summary[13] !== 'semantic_v1' ||
      num(summary[4], 6) !== 6 || decisions.length !== 6 ||
      num(summary[5], 6) !== 6 || num(summary[10]) !== 0) {
    throw new Error('incomplete or unverified native chooser trace');
  }
  const run: ChooserRun = {
    scenario: 'chooser-trace', seed: num(summary[2], 4294967295), revision: token(summary[3]),
    decisions, opportunities: num(summary[5], 6), accepted: num(summary[6], 6),
    missed: num(summary[7], 6), fallback: num(summary[8], 6), invalid: num(summary[9], 6),
  };
  if (run.accepted !== decisions.filter((decision) => decision.accepted === 1).length ||
      run.missed !== decisions.filter((decision) => decision.acted === 0).length ||
      run.fallback !== 6 - run.accepted ||
      run.fallback !== decisions.filter((decision) => decision.reason !== 'accepted').length ||
      run.invalid !== decisions.reduce((count, decision) => count + decision.invalid, 0)) {
    throw new Error('chooser summary and per-case counts disagree');
  }
  for (const line of raw.split(/\r?\n/u)) {
    if (!line.includes('[tqs_chooser_trace] decision ')) continue;
    const match = line.match(DECISION);
    if (!match || match[1] !== run.scenario || num(match[2], 4294967295) !== run.seed ||
        match[3] !== run.revision) throw new Error('chooser decision identity mismatch');
  }
  return run;
}

function measures(decisions: ChooserDecision[]) {
  return {
    opportunities: decisions.length,
    misses: decisions.filter((entry) => entry.acted === 0).length,
    accepted: decisions.filter((entry) => entry.accepted === 1).length,
    acted: decisions.filter((entry) => entry.acted === 1).length,
    fallback: decisions.filter((entry) => entry.reason !== 'accepted').length,
    invalid: decisions.reduce((sum, entry) => sum + entry.invalid, 0),
    acceptedNoAction: decisions.filter((entry) => entry.accepted === 1 && entry.acted === 0).length,
    voluntaryOptionalCancel: decisions.filter((entry) => entry.variant === 'optional' &&
      entry.accepted === 1 && entry.acted === 0).length,
    optionalNoDecisionFallback: decisions.filter((entry) => entry.variant === 'optional' &&
      entry.accepted === 0 && (entry.reason === 'no_decision' || entry.reason === 'cancel')).length,
  };
}

export function compareChooserTraceLogs(baselineLog: string, candidateLog: string): ChooserReview {
  const baseline = parseChooserTraceLog(baselineLog);
  const candidate = parseChooserTraceLog(candidateLog);
  const mismatchedCases: number[] = [];
  for (let index = 0; index < 6; index++) {
    const a = baseline.decisions[index];
    const b = candidate.decisions[index];
    if (a.input !== b.input || a.offer !== b.offer ||
        a.offeredCards !== b.offeredCards || a.offeredTargets !== b.offeredTargets ||
        a.opportunity !== b.opportunity) mismatchedCases.push(index + 1);
  }
  const bySkill: ChooserReview['bySkill'] = {};
  for (const skill of SKILLS) {
    bySkill[skill] = {
      baseline: measures(baseline.decisions.filter((decision) => decision.skill === skill)),
      candidate: measures(candidate.decisions.filter((decision) => decision.skill === skill)),
    };
  }
  const comparable = baseline.seed === candidate.seed &&
    baseline.revision === candidate.revision && mismatchedCases.length === 0;
  return {
    schemaVersion: 2,
    kind: 'prompt4_native_generic_chooser_matched_request_replay',
    status: comparable ? 'MATCHED_BOUNDED_REQUESTS' : 'INCONCLUSIVE',
    scenario: baseline.scenario, seed: baseline.seed,
    comparedCases: 6, mismatchedCases,
    bySkill,
    nativeFeasibilityValidatedForAccepted: true,
    nativeLegalOfferCountsAvailable: true,
    nativeStrategicTargetQualityAvailable: false,
    nativeResourceValueAvailable: false,
    observedMatchFrequencyAvailable: false,
    winRateAvailable: false,
    limitations: [
      'FNV32 inputs and offer hashes are collision-prone bounded guards, not a complete native state snapshot.',
      'Six synthetic requests share a fixed hand and roster; no observed match frequency or population inference.',
      'Accepted replies passed native request feasibility; legality counts do not score tactical target or resource value.',
      'Accepted optional empty choices are no-action opportunities; these are kept separate from fallback and invalid counts.',
      'Optional no_decision/cancel fallbacks are reported separately; their intent cannot be inferred.',
      ...(baseline.revision !== candidate.revision ? ['Native QA revision mismatch.'] : []),
      ...(baseline.seed !== candidate.seed ? ['Native seed mismatch.'] : []),
    ],
  };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const [baselinePath, candidatePath, reportPath] = process.argv.slice(2);
  if (!baselinePath || !candidatePath || !reportPath) {
    throw new Error('usage: tsx smart-ai-prompt4-chooser-native-replay.ts BASELINE_LOG CANDIDATE_LOG OUTPUT_JSON');
  }
  const report = compareChooserTraceLogs(fs.readFileSync(baselinePath, 'utf8'),
    fs.readFileSync(candidatePath, 'utf8'));
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n', { flag: 'wx', mode: 0o600 });
  console.log(JSON.stringify({ status: report.status, comparedCases: report.comparedCases,
    mismatchedCases: report.mismatchedCases.length, nativeStrategicTargetQualityAvailable: false }));
  if (report.status !== 'MATCHED_BOUNDED_REQUESTS') process.exitCode = 1;
}
