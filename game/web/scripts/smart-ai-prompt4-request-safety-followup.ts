/**
 * Reconcile sanitized Prompt 4 evidence without treating unmatched gameplay
 * totals as a matched request comparison. No raw native logs are read.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { reviewPrompt4NativeSafety } from './smart-ai-prompt4-request-safety-review';

const CHOOSERS = ['choose_players_skill', 'choose_cards_skill', 'ex__choose_skill'] as const;
const SAFE_HASH = /^[a-f0-9]{8}$/u;

type Counts = { total: number; accepted: number; fallback: number; invalid: number; noDecision: number };
type ChooserCount = {
  opportunities: number; accepted: number; acted: number; optionalAcceptedNoAction: number;
  fallback: number; invalid: number; errors: number;
};
type Case = {
  seq: number; skill: string; variant: string; inputFingerprint: string; offerFingerprint: string;
  accepted: number; acted: number; invalid: number; chosenCards: number; chosenTargets: number;
};
type Branch = {
  browserRunner: string; nativeGameOver: boolean;
  fixture: { seatRosters: string; fixedHands: string };
  requestMetrics: Counts & { askForUseActiveSkill: number; customDialog: number };
  chooser: ChooserCount; cases: Case[]; binarySha256: string; packageSha256: string;
};
type Matched = {
  status: string; overallPrompt4Gate: string;
  identity: { binarySha256: string; qaPackageSha256: string; seed: number };
  matching: { comparableRequestInputs: boolean; mismatchedCases: number[]; matchedCaseCount: number;
    offeredLegalSetCountMatched: boolean; decisionCountAndShapeMatched: boolean };
  comparison: { status: string; comparedCases: number; mismatchedCases: number[]; seed: number;
    nativeFeasibilityValidatedForAccepted: boolean; bySkill: Record<string, {
      baseline: { opportunities: number; accepted: number; acted: number; fallback: number;
        invalid: number; acceptedNoAction: number; misses: number };
      candidate: { opportunities: number; accepted: number; acted: number; fallback: number;
        invalid: number; acceptedNoAction: number; misses: number };
    }> };
  variants: { baseline: Branch; candidate: Branch };
};

function checked(value: number, label: string): number {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(`invalid counter: ${label}`);
  return value;
}

function ensure(condition: boolean, label: string): void {
  if (!condition) throw new Error(`matched chooser evidence inconsistent: ${label}`);
}

function checkBranch(name: 'baseline' | 'candidate', branch: Branch, matched: Matched): void {
  const c = branch.chooser;
  const m = branch.requestMetrics;
  const { identity } = matched;
  ensure(branch.browserRunner === 'PASS' && branch.nativeGameOver &&
    branch.fixture.seatRosters === 'verified' && branch.fixture.fixedHands === 'semantic_v1_verified', `${name} runtime`);
  ensure(branch.binarySha256 === identity.binarySha256 &&
    branch.packageSha256 === identity.qaPackageSha256, `${name} package identity`);
  for (const [key, value] of Object.entries(c)) checked(value, `${name}.chooser.${key}`);
  for (const [key, value] of Object.entries(m)) checked(value, `${name}.metrics.${key}`);
  ensure(c.opportunities === 6 && c.accepted + c.fallback === c.opportunities &&
    c.acted + c.optionalAcceptedNoAction === c.accepted && c.invalid <= c.fallback && c.errors === 0,
    `${name} chooser partition`);
  ensure(m.accepted + m.fallback === m.total && m.invalid + m.noDecision <= m.fallback &&
    m.askForUseActiveSkill === c.opportunities && m.customDialog === 2 &&
    m.total === m.askForUseActiveSkill + m.customDialog, `${name} native metrics`);
  ensure(branch.cases.length === 6, `${name} case count`);
  for (let i = 0; i < branch.cases.length; i++) {
    const item = branch.cases[i];
    ensure(item.seq === i + 1 && CHOOSERS.includes(item.skill as typeof CHOOSERS[number]) &&
      (item.variant === 'mandatory' || item.variant === 'optional') &&
      SAFE_HASH.test(item.inputFingerprint) && SAFE_HASH.test(item.offerFingerprint), `${name} case shape ${i + 1}`);
    for (const key of ['accepted', 'acted', 'invalid', 'chosenCards', 'chosenTargets'] as const) {
      checked(item[key], `${name}.case.${i + 1}.${key}`);
    }
  }
  ensure(branch.cases.reduce((sum, item) => sum + item.accepted, 0) === c.accepted &&
    branch.cases.reduce((sum, item) => sum + item.acted, 0) === c.acted &&
    branch.cases.reduce((sum, item) => sum + item.invalid, 0) === c.invalid, `${name} case totals`);
}

export function buildPrompt4RequestSafetyFollowup(
  matched: Matched, probe: Parameters<typeof reviewPrompt4NativeSafety>[0],
  ab: Parameters<typeof reviewPrompt4NativeSafety>[1],
  observed: Parameters<typeof reviewPrompt4NativeSafety>[2],
  reconciled: NonNullable<Parameters<typeof reviewPrompt4NativeSafety>[3]>,
) {
  const historical = reviewPrompt4NativeSafety(probe, ab, observed, reconciled);
  const b = matched.variants.baseline;
  const c = matched.variants.candidate;
  ensure(matched.status === 'BOUNDED_MATCHED_REQUEST_SAFETY_PASS' &&
    matched.overallPrompt4Gate === 'REQUEST_SAFETY_OPEN' &&
    matched.matching.comparableRequestInputs && matched.matching.mismatchedCases.length === 0 &&
    matched.comparison.status === 'MATCHED_BOUNDED_REQUESTS' &&
    matched.comparison.mismatchedCases.length === 0 &&
    matched.comparison.nativeFeasibilityValidatedForAccepted &&
    matched.matching.offeredLegalSetCountMatched && matched.matching.decisionCountAndShapeMatched &&
    matched.comparison.comparedCases === 6 && matched.matching.matchedCaseCount === 6 &&
    matched.comparison.seed === matched.identity.seed, 'overall matched replay');
  checkBranch('baseline', b, matched);
  checkBranch('candidate', c, matched);
  ensure(Object.keys(matched.comparison.bySkill).length === CHOOSERS.length, 'chooser coverage');
  for (const skill of CHOOSERS) {
    const row = matched.comparison.bySkill[skill];
    ensure(!!row, `missing ${skill}`);
    for (const name of ['baseline', 'candidate'] as const) {
      const m = row[name];
      const cases = matched.variants[name].cases.filter((item) => item.skill === skill);
      ensure(cases.length === 2 && new Set(cases.map((item) => item.variant)).size === 2 &&
        m.opportunities === 2 && m.accepted === 2 && m.acted === 1 && m.misses === 1 &&
        m.acceptedNoAction === 1 && m.fallback === 0 && m.invalid === 0 &&
        cases.every((item) => item.accepted === 1 && item.invalid === 0) &&
        cases.reduce((sum, item) => sum + item.acted, 0) === m.acted, `${name} ${skill}`);
    }
  }
  for (let i = 0; i < 6; i++) {
    const x = b.cases[i]; const y = c.cases[i];
    ensure(x.seq === y.seq && x.skill === y.skill && x.variant === y.variant &&
      x.inputFingerprint === y.inputFingerprint && x.offerFingerprint === y.offerFingerprint,
    `paired hash/case ${i + 1}`);
  }
  ensure(historical.gate.savedAggregateCountersConsistent &&
    historical.gate.nativeActiveCountersReconciled &&
    historical.observedCandidateMatch.commandCoverageConsistent, 'historical metrics consistency');
  const commands = historical.observedCandidateMatch.commands;
  const aggregate = historical.observedCandidateMatch.aggregate;
  const otherFallbackByCommand = Object.fromEntries(Object.entries(commands)
    .filter(([, value]) => value.otherFallback > 0)
    .map(([name, value]) => [name, value.otherFallback]));
  ensure(Object.values(otherFallbackByCommand).reduce((sum, value) => sum + value, 0) ===
    aggregate.otherFallback, 'observed other fallback partition');
  return {
    schemaVersion: 1,
    kind: 'prompt4_request_safety_followup',
    source: 'saved sanitized native evidence; no new native execution',
    boundedMatchedChooser: {
      status: 'PASS', comparedCases: 6, mismatchedCases: [] as number[],
      skillCount: CHOOSERS.length, nativeInputAndOfferHashesMatch: true,
      baseline: b.chooser, candidate: c.chooser,
      acceptedOptionalNoActionIsFallback: false, nativeFeasibilityValidated: true,
      limitations: 'Six fixed scenario cases with FNV32 hashes; no full native-state snapshot or tactical quality measurement',
    },
    observedCandidateMatch: {
      aggregate: { total: aggregate.total, accepted: aggregate.recordedAccepted,
        fallback: aggregate.fallback, invalid: aggregate.invalid, noDecision: aggregate.noDecision,
        otherFallback: aggregate.otherFallback },
      allCommandsReconciled: true,
      invalidByCommand: historical.observedCandidateMatch.invalidContributionsByCommand,
      otherFallbackByCommand,
      perCommandReasonDetailAvailable: false,
      semanticRootCauseEstablished: false,
    },
    earlierUnmatchedNativeAb: {
      delta: historical.earlierNativeAb.delta, matchedRequestState: false,
      causalAttributionAvailable: false,
    },
    historicalActiveCounterLabelsReconciled: true,
    gate: {
      boundedChooserRequestSafety: 'PASS', fullPrompt4: 'REQUEST_SAFETY_OPEN',
      matchedEighteenSkillRequestsAvailable: false,
      fullSnapshotAvailable: false, nativeTargetCardResourceValueAvailable: false,
      winRateAttributionAvailable: false,
    },
  };
}

function main(): void {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
  const read = (name: string) => JSON.parse(fs.readFileSync(path.join(root, 'docs/web-client', name), 'utf8'));
  const result = buildPrompt4RequestSafetyFollowup(
    read('SMARTAI_PROMPT4_CHOOSER_NATIVE_MATCHED_2026-10-21.json'),
    read('SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json'),
    read('SMARTAI_PROMPT4_NATIVE_AB_2026-10-21.json'),
    read('SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json'),
    read('SMARTAI_PROMPT4_ACTIVE_COUNTER_RECONCILIATION_2026-10-21.json'),
  );
  const output = process.argv[2];
  const encoded = `${JSON.stringify(result, null, 2)}\n`;
  if (output) fs.writeFileSync(output, encoded, { mode: 0o600 });
  else process.stdout.write(encoded);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
