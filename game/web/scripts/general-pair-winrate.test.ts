import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  analyzeEvidence,
  buildMatrixPlan,
  type MatrixCatalog,
  type WinrateEvidence,
  wilson95,
} from './general-pair-winrate';

function catalog(): MatrixCatalog {
  return {
    generalPairMatrix: { seedRange: { min: 100, max: 103 } },
    scenarios: [
      {
        id: 'general-pair-match-mixed-a', seed: 1, matrixFamily: 'general-pair-winrate-v1',
        matrixRosterSets: ['r1', 'r2', 'r3', 'r4'], matrixSeatPermutation: 'A',
        seedRange: { min: 100, max: 103 },
      },
      {
        id: 'general-pair-match-mixed-b', seed: 2, matrixFamily: 'general-pair-winrate-v1',
        matrixRosterSets: ['r1', 'r2', 'r3', 'r4'], matrixSeatPermutation: 'B',
        seedRange: { min: 100, max: 103 },
      },
    ],
  };
}

function evidence(options: {
  branch: string;
  scenario: string;
  seed: number;
  rosterSet: string;
  seatSwap: string;
  winnerSeat: number;
  winnerKingdom: string;
  initialGeneralCount?: number;
  hash?: string;
  outputHash?: string;
  fallback?: boolean;
}): WinrateEvidence {
  const fallback = options.fallback ?? false;
  const reason = fallback ? 'no_decision' : 'accepted';
  return {
    scenario: options.scenario,
    nativeQaSeed: options.seed,
    initialGeneralCount: options.initialGeneralCount ?? 10,
    winrateBranch: options.branch,
    matrixInputHash: options.hash ?? 'a'.repeat(64),
    result: 'PASS',
    generalPairTelemetry: {
      matchResult: {
        scenario: options.scenario,
        seed: options.seed,
        rosterSet: options.rosterSet,
        seatSwap: options.seatSwap,
        winnerSeats: [options.winnerSeat],
        winnerKingdoms: [`${options.winnerSeat}:${options.winnerKingdom}`],
        winnerCount: 1,
        outcome: 'win',
      },
      decisionSummary: {
        decisions: '1', accepted: fallback ? '0' : '1', fallback: fallback ? '1' : '0', invalid: '0',
        overflow: 'false', reasons: `${reason}:1`, latency_n: '1', trace_hash: options.outputHash ?? 'trace',
      },
      decisions: [{
        seq: '1', seat: '1', input: 'same-input', output_hash: options.outputHash ?? 'output', valid: String(!fallback),
        reason, detail: fallback ? 'feasibility_rejected' : 'none', elapsed_ms: '2.5',
      }],
      offerSummary: { offer_count: '10', seat_count: '4', seats: '1,2,3,4' },
    },
    generalChoiceCounts: [10, 10],
  };
}

test('wilson confidence interval is bounded and conservative at the extremes', () => {
  const interval = wilson95(8, 10);
  assert.ok(interval);
  assert.ok(interval.low >= 0 && interval.low < 0.8);
  assert.ok(interval.high > 0.8 && interval.high <= 1);
  assert.deepEqual(wilson95(0, 0), null);
});

test('matrix plan preserves four scenario seat swaps and deterministic roster selection', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 2, seedStart: 100 });
  assert.equal(plan.length, 4);
  assert.deepEqual(plan.map((row) => row.seatSwap), ['A', 'A', 'B', 'B']);
  assert.deepEqual(plan.map((row) => row.rosterSet), ['r1', 'r2', 'r1', 'r2']);
  assert.deepEqual(plan.map((row) => row.key), [
    'general-pair-match-mixed-a:100', 'general-pair-match-mixed-a:101',
    'general-pair-match-mixed-b:100', 'general-pair-match-mixed-b:101',
  ]);
});

test('analysis pairs baseline/candidate and separates winner, fallback, latency and divergence metrics', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 2, seedStart: 100 });
  const evidenceRows = [
    evidence({ branch: 'baseline', scenario: plan[0].scenario, seed: plan[0].seed, rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1, winnerKingdom: 'wei' }),
    evidence({ branch: 'candidate', scenario: plan[0].scenario, seed: plan[0].seed, rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 2, winnerKingdom: 'shu', outputHash: 'changed' }),
    evidence({ branch: 'baseline', scenario: plan[1].scenario, seed: plan[1].seed, rosterSet: plan[1].rosterSet, seatSwap: plan[1].seatSwap, winnerSeat: 3, winnerKingdom: 'wu', fallback: true }),
    evidence({ branch: 'candidate', scenario: plan[1].scenario, seed: plan[1].seed, rosterSet: plan[1].rosterSet, seatSwap: plan[1].seatSwap, winnerSeat: 3, winnerKingdom: 'wu', fallback: true }),
    evidence({ branch: 'baseline', scenario: plan[2].scenario, seed: plan[2].seed, rosterSet: plan[2].rosterSet, seatSwap: plan[2].seatSwap, winnerSeat: 4, winnerKingdom: 'qun' }),
    evidence({ branch: 'candidate', scenario: plan[2].scenario, seed: plan[2].seed, rosterSet: plan[2].rosterSet, seatSwap: plan[2].seatSwap, winnerSeat: 4, winnerKingdom: 'qun' }),
    evidence({ branch: 'baseline', scenario: plan[3].scenario, seed: plan[3].seed, rosterSet: plan[3].rosterSet, seatSwap: plan[3].seatSwap, winnerSeat: 1, winnerKingdom: 'wei' }),
    evidence({ branch: 'candidate', scenario: plan[3].scenario, seed: plan[3].seed, rosterSet: plan[3].rosterSet, seatSwap: plan[3].seatSwap, winnerSeat: 1, winnerKingdom: 'wei' }),
  ];
  const report = analyzeEvidence(evidenceRows, {
    plan,
    baselineBranch: 'baseline',
    candidateBranch: 'candidate',
    sourceFiles: evidenceRows.map((_, index) => `evidence-${index}.json`),
    minPairs: 4,
  });
  assert.equal(report.gate.status, 'READY_FOR_TUNING_REVIEW');
  assert.equal(report.pairing.pairs, 4);
  assert.equal(report.pairing.coverage.bySeatSwap.A, 2);
  assert.equal(report.pairing.coverage.bySeatSwap.B, 2);
  assert.equal(report.winner.baseline.bySeat['1'].wins, 2);
  assert.equal(report.winner.candidate.bySeat['2'].wins, 1);
  assert.equal(report.fallback.baseline.reasons.no_decision, 1);
  assert.equal(report.fallback.baseline.classes.no_decision, 1);
  assert.equal(report.latency.candidate.samples, 4);
  assert.equal(report.decisionDivergence.pairsWithDivergence, 1);
  assert.equal(report.decisionDivergence.outputHashChanges, 1);
  assert.equal(report.decisionDivergence.inputMismatchRecords, 0);
  assert.equal(report.paired.bySeat['2'].mean, 0.25);
});

test('analysis keeps the gate open for missing or non-equivalent pairs', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 1, seedStart: 100 });
  const rows = [
    evidence({ branch: 'baseline', scenario: plan[0].scenario, seed: plan[0].seed, rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1, winnerKingdom: 'wei' }),
    evidence({ branch: 'candidate', scenario: plan[0].scenario, seed: plan[0].seed, rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1, winnerKingdom: 'wei', hash: 'b'.repeat(64) }),
  ];
  const report = analyzeEvidence(rows, {
    plan,
    baselineBranch: 'baseline',
    candidateBranch: 'candidate',
    sourceFiles: ['baseline.json', 'candidate.json'],
    minPairs: 2,
  });
  assert.equal(report.gate.status, 'OPEN');
  assert.ok(report.gate.reasons.some((reason) => reason.includes('missing baseline pairs')));
  assert.ok(report.gate.reasons.some((reason) => reason.includes('paired input hash mismatches')));
});

test('analysis can require the ten-general opening policy', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 1, seedStart: 100 });
  const row = evidence({
    branch: 'baseline', scenario: plan[0].scenario, seed: plan[0].seed,
    rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1,
    winnerKingdom: 'wei', initialGeneralCount: 5,
  });
  const report = analyzeEvidence([row], {
    plan: [plan[0]], minPairs: 0, expectedInitialGeneralCount: 10,
  });
  assert.ok(report.gate.reasons.some((reason) => reason.includes('initial general count mismatch')));
});

test('analysis classifies pool fallback separately and gates it for the ten-general matrix', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 1, seedStart: 100 });
  const row = evidence({
    branch: 'baseline', scenario: plan[0].scenario, seed: plan[0].seed,
    rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1,
    winnerKingdom: 'wei', fallback: true,
  });
  const telemetry = row.generalPairTelemetry as Record<string, unknown>;
  const decisions = (telemetry.decisions as Array<Record<string, string>>);
  decisions[0].detail = 'missing_choice_pool';
  const report = analyzeEvidence([row], {
    plan: [plan[0]], minPairs: 0, expectedInitialGeneralCount: 10,
  });
  assert.equal(report.fallback.baseline.missingChoicePool, 1);
  assert.equal(report.fallback.baseline.otherFallback, 0);
  assert.ok(report.gate.reasons.some((reason) => reason.includes('missing general-choice pool')));
});

test('analysis keeps non-pool fallback in taxonomy without blocking the ten-general gate', () => {
  const plan = buildMatrixPlan(catalog(), { seedsPerSeatSwap: 1, seedStart: 100 });
  const row = evidence({
    branch: 'baseline', scenario: plan[0].scenario, seed: plan[0].seed,
    rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1,
    winnerKingdom: 'wei', fallback: true,
  });
  const candidate = evidence({
    branch: 'candidate', scenario: plan[0].scenario, seed: plan[0].seed,
    rosterSet: plan[0].rosterSet, seatSwap: plan[0].seatSwap, winnerSeat: 1,
    winnerKingdom: 'wei',
  });
  const report = analyzeEvidence([row, candidate], {
    plan: [plan[0]], minPairs: 0, expectedInitialGeneralCount: 10,
    baselineBranch: 'baseline', candidateBranch: 'candidate', sourceFiles: ['baseline.json', 'candidate.json'],
  });
  assert.equal(report.fallback.baseline.missingChoicePool, 0);
  assert.equal(report.fallback.baseline.otherFallback, 1);
  assert.equal(report.gate.status, 'READY_FOR_TUNING_REVIEW');
});
