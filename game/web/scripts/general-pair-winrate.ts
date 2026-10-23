import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const Z95 = 1.959963984540054;
const DEFAULT_SEEDS_PER_SEAT_SWAP = 8;
const MATRIX_FAMILY = 'general-pair-winrate-v1';

export type MatrixCatalog = {
  generalPairMatrix?: {
    initialGeneralCount?: number;
    seedRange?: { min: number; max: number };
    rosterSets?: Record<string, unknown>;
    seatPermutations?: Record<string, number[]>;
  };
  scenarios?: Array<{
    id: string;
    seed: number;
    matrixFamily?: string;
    matrixRosterSets?: string[];
    matrixSeatPermutation?: string;
    seedRange?: { min: number; max: number };
  }>;
};

export type MatrixPlanRow = {
  key: string;
  scenario: string;
  seed: number;
  rosterSet: string;
  seatSwap: string;
};

export type PairMatchResult = {
  scenario: string;
  seed: number;
  rosterSet: string;
  seatSwap: string;
  winnerSeats: number[];
  winnerKingdoms: string[];
  winnerCount: number;
  outcome: 'win' | 'draw';
};

export type GeneralPairTelemetry = {
  matchResult: PairMatchResult | null;
  decisionSummary: Record<string, string> | null;
  decisions: Array<Record<string, string>>;
  offerSummary: Record<string, string> | null;
};

export type WinrateEvidence = {
  scenario?: unknown;
  nativeQaSeed?: unknown;
  initialGeneralCount?: unknown;
  generalChoiceCounts?: unknown;
  winrateBranch?: unknown;
  winrateRunId?: unknown;
  matrixInputHash?: unknown;
  result?: unknown;
  generalPairTelemetry?: unknown;
  [key: string]: unknown;
};

type ParsedRun = {
  sourceFile: string;
  branch: string;
  scenario: string;
  seed: number;
  key: string;
  matrixInputHash: string;
  initialGeneralCount: number | null;
  generalChoiceCounts: number[] | null;
  offerSummary: Record<string, string> | null;
  rosterSet: string;
  seatSwap: string;
  matchResult: PairMatchResult;
  decisionSummary: Record<string, string>;
  decisions: Array<Record<string, string>>;
  evidence: WinrateEvidence;
};

type ParseResult = {
  run: ParsedRun | null;
  issues: string[];
};

export type LoadedEvidence = {
  evidence: WinrateEvidence[];
  sourceFiles: string[];
  invalidFiles: Array<{ file: string; issues: string[] }>;
};

export type WilsonInterval = { low: number; high: number } | null;

export type RateSummary = {
  matches: number;
  eligibleMatches: number;
  wins: number;
  rate: number | null;
  ci95: WilsonInterval;
};

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function text(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function numberValue(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function integerValue(value: unknown): number | null {
  const parsed = numberValue(value);
  return parsed !== null && Number.isSafeInteger(parsed) ? parsed : null;
}

function requiredText(value: unknown, label: string, issues: string[]): string | null {
  const parsed = text(value);
  if (!parsed) issues.push(`${label} is missing`);
  return parsed;
}

function requiredInteger(value: unknown, label: string, issues: string[]): number | null {
  const parsed = integerValue(value);
  if (parsed === null) issues.push(`${label} is not a finite integer`);
  return parsed;
}

function finiteNonNegative(value: unknown): number | null {
  const parsed = numberValue(value);
  return parsed !== null && parsed >= 0 ? parsed : null;
}

function parseSeatList(value: unknown, issues: string[], label: string): number[] {
  if (!Array.isArray(value)) {
    issues.push(`${label} is not an array`);
    return [];
  }
  const seats = value.map((seat) => integerValue(seat));
  if (seats.some((seat) => seat === null)) issues.push(`${label} contains a non-integer seat`);
  const normalized = seats.filter((seat): seat is number => seat !== null);
  if (normalized.some((seat) => seat < 1 || seat > 4)) issues.push(`${label} contains a seat outside 1..4`);
  if (new Set(normalized).size !== normalized.length) issues.push(`${label} contains a duplicate seat`);
  return normalized;
}

function parseWinnerKingdoms(value: unknown, issues: string[]): string[] {
  if (!Array.isArray(value)) {
    issues.push('winnerKingdoms is not an array');
    return [];
  }
  const kingdoms = value.map((entry) => text(entry));
  if (kingdoms.some((kingdom) => kingdom === null || !/^\d+:[a-z][a-z0-9_-]*$/u.test(kingdom))) {
    issues.push('winnerKingdoms contains an invalid seat:kingdom token');
  }
  return kingdoms.filter((kingdom): kingdom is string => kingdom !== null);
}

function parseMatchResult(value: unknown, issues: string[]): PairMatchResult | null {
  const raw = record(value);
  if (!raw) {
    issues.push('generalPairTelemetry.matchResult is missing');
    return null;
  }
  const scenario = requiredText(raw.scenario, 'matchResult.scenario', issues);
  const seed = requiredInteger(raw.seed, 'matchResult.seed', issues);
  const rosterSet = requiredText(raw.rosterSet, 'matchResult.rosterSet', issues);
  const seatSwap = requiredText(raw.seatSwap, 'matchResult.seatSwap', issues);
  const winnerSeats = parseSeatList(raw.winnerSeats, issues, 'winnerSeats');
  const winnerKingdoms = parseWinnerKingdoms(raw.winnerKingdoms, issues);
  const winnerCount = requiredInteger(raw.winnerCount, 'matchResult.winnerCount', issues);
  const outcome = raw.outcome === 'win' || raw.outcome === 'draw' ? raw.outcome : null;
  if (!outcome) issues.push('matchResult.outcome must be win or draw');
  if (winnerCount !== null && winnerCount !== winnerSeats.length) {
    issues.push('winnerCount does not match winnerSeats length');
  }
  if (winnerKingdoms.length !== winnerSeats.length) {
    issues.push('winnerKingdoms does not match winnerSeats length');
  }
  if (outcome === 'draw' && winnerSeats.length !== 0) issues.push('draw result has a winner seat');
  if (outcome === 'win' && winnerSeats.length === 0) issues.push('win result has no winner seat');
  if (scenario === null || seed === null || rosterSet === null || seatSwap === null ||
      winnerCount === null || !outcome) return null;
  return { scenario, seed, rosterSet, seatSwap, winnerSeats, winnerKingdoms,
    winnerCount, outcome };
}

function parseTelemetry(value: unknown, issues: string[]): GeneralPairTelemetry | null {
  const raw = record(value);
  if (!raw) {
    issues.push('generalPairTelemetry is missing');
    return null;
  }
  const matchResult = parseMatchResult(raw.matchResult, issues);
  const decisionSummary = record(raw.decisionSummary) as Record<string, string> | null;
  if (!decisionSummary) issues.push('generalPairTelemetry.decisionSummary is missing');
  const decisionsValue = raw.decisions;
  if (!Array.isArray(decisionsValue)) issues.push('generalPairTelemetry.decisions is not an array');
  const decisions = Array.isArray(decisionsValue)
    ? decisionsValue.map((entry) => record(entry)).filter((entry): entry is Record<string, string> => entry !== null)
    : [];
  if (Array.isArray(decisionsValue) && decisions.length !== decisionsValue.length) {
    issues.push('generalPairTelemetry.decisions contains a non-object entry');
  }
  const offerValue = raw.offerSummary;
  const offerSummary = offerValue === undefined || offerValue === null
    ? null
    : record(offerValue) as Record<string, string> | null;
  if (offerValue !== undefined && offerValue !== null && !offerSummary) {
    issues.push('generalPairTelemetry.offerSummary is not an object');
  }
  return matchResult && decisionSummary ? { matchResult, decisionSummary, decisions, offerSummary } : null;
}

function parseGeneralChoiceCounts(value: unknown, issues: string[]): number[] | null {
  if (value === undefined || value === null) return null;
  if (!Array.isArray(value)) {
    issues.push('generalChoiceCounts is not an array');
    return null;
  }
  const counts = value.map((entry) => integerValue(entry));
  if (counts.some((count) => count === null)) issues.push('generalChoiceCounts contains a non-integer');
  return counts.filter((count): count is number => count !== null);
}

function parseRun(evidence: WinrateEvidence, sourceFile: string): ParseResult {
  const issues: string[] = [];
  const telemetry = parseTelemetry(evidence.generalPairTelemetry, issues);
  const match = telemetry?.matchResult;
  const summary = telemetry?.decisionSummary;
  const branch = requiredText(evidence.winrateBranch, 'winrateBranch', issues);
  const initialGeneralCount = integerValue(evidence.initialGeneralCount);
  const scenario = text(evidence.scenario) ?? match?.scenario ?? null;
  if (!scenario) issues.push('scenario is missing');
  const seed = integerValue(evidence.nativeQaSeed) ?? match?.seed ?? null;
  if (seed === null) issues.push('nativeQaSeed is missing');
  const matrixInputHash = requiredText(evidence.matrixInputHash, 'matrixInputHash', issues);
  const generalChoiceCounts = parseGeneralChoiceCounts(evidence.generalChoiceCounts, issues);
  if (matrixInputHash && !/^[a-f0-9]{64}$/iu.test(matrixInputHash)) {
    issues.push('matrixInputHash is not a SHA-256 hex digest');
  }
  if (match && scenario && match.scenario !== scenario) issues.push('matchResult.scenario differs from scenario');
  if (match && seed !== null && match.seed !== seed) issues.push('matchResult.seed differs from nativeQaSeed');
  if (summary && match && summary.decisions !== undefined) {
    const declared = integerValue(summary.decisions);
    if (declared === null) issues.push('decisionSummary.decisions is not an integer');
    else if (declared !== telemetry?.decisions.length) issues.push('decisionSummary.decisions differs from decision records');
  }
  if (summary) {
    for (const field of ['accepted', 'fallback', 'invalid', 'latency_n'] as const) {
      if (summary[field] !== undefined && integerValue(summary[field]) === null) {
        issues.push(`decisionSummary.${field} is not an integer`);
      }
    }
  }
  if (issues.length || !telemetry || !match || !summary || !branch || !scenario || seed === null || !matrixInputHash) {
    return { run: null, issues };
  }
  const rosterSet = match.rosterSet;
  const seatSwap = match.seatSwap;
  return {
    run: {
      sourceFile,
      branch,
      scenario,
      seed,
      key: `${scenario}:${seed}`,
      matrixInputHash,
      initialGeneralCount,
      generalChoiceCounts,
      offerSummary: telemetry.offerSummary,
      rosterSet,
      seatSwap,
      matchResult: match,
      decisionSummary: summary,
      decisions: telemetry.decisions,
      evidence,
    },
    issues,
  };
}

export function loadEvidenceDirectory(directory: string, prefix = '', runId?: string): LoadedEvidence {
  const root = path.resolve(directory);
  if (!existsSync(root)) throw new Error(`Evidence directory is missing: ${root}`);
  const names = readdirSync(root)
    .filter((name) => name.endsWith('.json') && (!prefix || name.includes(prefix)))
    .sort();
  const evidence: WinrateEvidence[] = [];
  const sourceFiles: string[] = [];
  const invalidFiles: Array<{ file: string; issues: string[] }> = [];
  for (const name of names) {
    const file = path.join(root, name);
    let parsed: unknown;
    try {
      parsed = JSON.parse(readFileSync(file, 'utf8'));
    } catch (error) {
      invalidFiles.push({ file: name, issues: [`invalid JSON: ${(error as Error).message}`] });
      continue;
    }
    const value = record(parsed);
    if (!value) {
      invalidFiles.push({ file: name, issues: ['evidence root is not an object'] });
      continue;
    }
    if (runId && value.winrateRunId !== runId) continue;
    evidence.push(value as WinrateEvidence);
    sourceFiles.push(name);
  }
  return { evidence, sourceFiles, invalidFiles };
}

function readJson<T>(file: string): T {
  return JSON.parse(readFileSync(file, 'utf8')) as T;
}

export function buildMatrixPlan(catalog: MatrixCatalog, options: {
  seedsPerSeatSwap?: number;
  seedStart?: number;
  scenarioIds?: string[];
} = {}): MatrixPlanRow[] {
  const scenarios = (catalog.scenarios ?? [])
    .filter((scenario) => scenario.matrixFamily === MATRIX_FAMILY)
    .filter((scenario) => !options.scenarioIds || options.scenarioIds.includes(scenario.id))
    .sort((left, right) => (left.matrixSeatPermutation ?? '').localeCompare(right.matrixSeatPermutation ?? ''));
  if (scenarios.length === 0) throw new Error(`catalog has no ${MATRIX_FAMILY} scenarios`);
  const range = catalog.generalPairMatrix?.seedRange;
  if (!range || !Number.isSafeInteger(range.min) || !Number.isSafeInteger(range.max) || range.min > range.max) {
    throw new Error('catalog has no valid generalPairMatrix.seedRange');
  }
  const count = options.seedsPerSeatSwap ?? DEFAULT_SEEDS_PER_SEAT_SWAP;
  if (!Number.isSafeInteger(count) || count < 1) throw new Error('seedsPerSeatSwap must be a positive integer');
  const start = options.seedStart ?? range.min;
  if (!Number.isSafeInteger(start) || start < range.min || start + count - 1 > range.max) {
    throw new Error('seedStart/seedsPerSeatSwap exceed the declared matrix seed range');
  }
  const rows: MatrixPlanRow[] = [];
  for (const scenario of scenarios) {
    const rosterNames = scenario.matrixRosterSets ?? [];
    if (!scenario.matrixSeatPermutation || rosterNames.length === 0) {
      throw new Error(`scenario ${scenario.id} has incomplete matrix metadata`);
    }
    for (let seed = start; seed < start + count; seed += 1) {
      const rosterSet = rosterNames[(seed - (scenario.seedRange?.min ?? range.min)) % rosterNames.length];
      const key = `${scenario.id}:${seed}`;
      rows.push({ key, scenario: scenario.id, seed, rosterSet, seatSwap: scenario.matrixSeatPermutation });
    }
  }
  return rows;
}

export function wilson95(successes: number, trials: number): WilsonInterval {
  if (!Number.isFinite(successes) || !Number.isFinite(trials) || trials <= 0) return null;
  if (successes < 0 || successes > trials) throw new Error('successes must be between zero and trials');
  const p = successes / trials;
  const denominator = 1 + (Z95 ** 2) / trials;
  const centre = (p + (Z95 ** 2) / (2 * trials)) / denominator;
  const margin = Z95 * Math.sqrt((p * (1 - p) + (Z95 ** 2) / (4 * trials)) / trials) / denominator;
  return { low: Math.max(0, centre - margin), high: Math.min(1, centre + margin) };
}

function rateSummary(matches: number, eligibleMatches: number, wins: number): RateSummary {
  const ci95 = wilson95(wins, eligibleMatches);
  return {
    matches,
    eligibleMatches,
    wins,
    rate: eligibleMatches > 0 ? wins / eligibleMatches : null,
    ci95,
  };
}

function winnerKingdomMap(result: PairMatchResult): Map<number, string> {
  const map = new Map<number, string>();
  for (const token of result.winnerKingdoms) {
    const separator = token.indexOf(':');
    const seat = Number(token.slice(0, separator));
    const kingdom = token.slice(separator + 1);
    if (Number.isInteger(seat) && kingdom) map.set(seat, kingdom);
  }
  return map;
}

function summarizeWinners(runs: ParsedRun[]) {
  const singleWinners = runs.filter((run) => run.matchResult.outcome === 'win' && run.matchResult.winnerCount === 1);
  const draws = runs.filter((run) => run.matchResult.outcome === 'draw').length;
  const multiWinner = runs.filter((run) => run.matchResult.winnerCount > 1).length;
  const seats: Record<string, RateSummary> = {};
  for (let seat = 1; seat <= 4; seat += 1) {
    const wins = singleWinners.filter((run) => run.matchResult.winnerSeats.includes(seat)).length;
    seats[String(seat)] = rateSummary(runs.length, singleWinners.length, wins);
  }
  const kingdoms = new Set<string>();
  for (const run of runs) for (const token of run.matchResult.winnerKingdoms) kingdoms.add(token.slice(token.indexOf(':') + 1));
  const byKingdom: Record<string, RateSummary> = {};
  for (const kingdom of [...kingdoms].sort()) {
    const wins = singleWinners.filter((run) => [...winnerKingdomMap(run.matchResult).values()].includes(kingdom)).length;
    byKingdom[kingdom] = rateSummary(runs.length, singleWinners.length, wins);
  }
  return {
    overall: rateSummary(runs.length, singleWinners.length, singleWinners.length),
    draws,
    multiWinner,
    bySeat: seats,
    byKingdom,
  };
}

function parseReasonCounts(summary: Record<string, string>): Record<string, number> {
  const result: Record<string, number> = {};
  for (const token of (summary.reasons ?? '').split(',').filter(Boolean)) {
    const separator = token.lastIndexOf(':');
    const reason = separator > 0 ? token.slice(0, separator) : token;
    const count = separator > 0 ? integerValue(token.slice(separator + 1)) : 1;
    if (reason && count !== null && count >= 0) result[reason] = (result[reason] ?? 0) + count;
  }
  return result;
}

function fallbackClass(reason: string): string {
  if (reason === 'accepted') return 'accepted';
  if (/invalid|malformed/u.test(reason)) return 'invalid_reply';
  if (/feasibility/u.test(reason)) return 'feasibility';
  if (/exception|error/u.test(reason)) return 'exception';
  if (/no_decision|fallback/u.test(reason)) return 'no_decision';
  return 'other_fallback';
}

function isMissingChoicePoolToken(value: unknown): boolean {
  const token = text(value)?.toLowerCase() ?? '';
  return /(?:pool|offer|choice|selection|select|general|pair|no[_-]?legal|missing[_-]?choice)/u.test(token);
}

function summarizeFallback(runs: ParsedRun[]) {
  let decisions = 0;
  let accepted = 0;
  let fallback = 0;
  let invalid = 0;
  let overflowRuns = 0;
  let missingChoicePool = 0;
  let otherFallback = 0;
  const reasons: Record<string, number> = {};
  const classes: Record<string, number> = {};
  for (const run of runs) {
    const summary = run.decisionSummary;
    decisions += integerValue(summary.decisions) ?? run.decisions.length;
    accepted += integerValue(summary.accepted) ?? 0;
    fallback += integerValue(summary.fallback) ?? 0;
    invalid += integerValue(summary.invalid) ?? 0;
    if (summary.overflow === 'true') overflowRuns += 1;
    const runReasons = parseReasonCounts(summary);
    for (const [reason, count] of Object.entries(runReasons)) {
      reasons[reason] = (reasons[reason] ?? 0) + count;
      const category = isMissingChoicePoolToken(reason) ? 'missing_choice_pool' : fallbackClass(reason);
      classes[category] = (classes[category] ?? 0) + count;
    }
    const runFallback = integerValue(summary.fallback) ?? 0;
    let runPoolFallback = Object.entries(runReasons)
      .filter(([reason]) => reason !== 'accepted' && isMissingChoicePoolToken(reason))
      .reduce((sum, [, count]) => sum + count, 0);
    const detailedPoolFallback = run.decisions
      .filter((decision) => decision.reason !== 'accepted')
      .filter((decision) => isMissingChoicePoolToken(decision.reason) || isMissingChoicePoolToken(decision.detail))
      .length;
    runPoolFallback = Math.max(runPoolFallback, detailedPoolFallback);
    runPoolFallback = Math.min(runFallback, runPoolFallback);
    missingChoicePool += runPoolFallback;
    otherFallback += Math.max(0, runFallback - runPoolFallback);
  }
  return {
    matches: runs.length,
    decisions,
    accepted,
    fallback,
    invalid,
    overflowRuns,
    missingChoicePool,
    otherFallback,
    fallbackRate: { rate: decisions > 0 ? fallback / decisions : null, ci95: wilson95(fallback, decisions) },
    reasons,
    classes,
  };
}

function percentile(values: number[], fraction: number): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((left, right) => left - right);
  const index = Math.max(0, Math.min(sorted.length - 1, Math.ceil(sorted.length * fraction) - 1));
  return sorted[index];
}

function meanCi95(values: number[]): WilsonInterval | { low: number; high: number } {
  if (values.length === 0) return null;
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  if (values.length < 2) return { low: mean, high: mean };
  const variance = values.reduce((sum, value) => sum + ((value - mean) ** 2), 0) / (values.length - 1);
  const half = Z95 * Math.sqrt(variance / values.length);
  return { low: Math.max(0, mean - half), high: mean + half };
}

function summarizeLatency(runs: ParsedRun[]) {
  const samples = runs.flatMap((run) => run.decisions
    .map((decision) => finiteNonNegative(decision.elapsed_ms))
    .filter((value): value is number => value !== null));
  const sum = samples.reduce((total, value) => total + value, 0);
  const meanMs = samples.length > 0 ? sum / samples.length : null;
  return {
    matches: runs.length,
    samples: samples.length,
    meanMs,
    ci95MeanMs: meanCi95(samples),
    minMs: samples.length > 0 ? Math.min(...samples) : null,
    p50Ms: percentile(samples, 0.50),
    p95Ms: percentile(samples, 0.95),
    maxMs: samples.length > 0 ? Math.max(...samples) : null,
  };
}

function summarizeMeanDelta(values: number[]) {
  if (values.length === 0) return { n: 0, mean: null, ci95: null };
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  if (values.length === 1) return { n: 1, mean, ci95: { low: mean, high: mean } };
  const variance = values.reduce((sum, value) => sum + ((value - mean) ** 2), 0) / (values.length - 1);
  const half = Z95 * Math.sqrt(variance / values.length);
  return { n: values.length, mean, ci95: { low: mean - half, high: mean + half } };
}

function summarizeDecisionDivergence(pairs: Array<{ baseline: ParsedRun; candidate: ParsedRun }>) {
  let decisionRecordsCompared = 0;
  let pairsCompared = 0;
  let pairsWithDivergence = 0;
  let inputMismatchRecords = 0;
  let outputHashChanges = 0;
  let validChanges = 0;
  let reasonChanges = 0;
  let detailChanges = 0;
  let traceHashChanges = 0;
  let decisionCountMismatches = 0;
  for (const pair of pairs) {
    pairsCompared += 1;
    const bySeq = (runs: ParsedRun) => new Map(runs.decisions
      .map((decision) => [integerValue(decision.seq) ?? -1, decision] as const));
    const baseline = bySeq(pair.baseline);
    const candidate = bySeq(pair.candidate);
    if (baseline.size !== candidate.size) decisionCountMismatches += 1;
    const sequence = new Set([...baseline.keys(), ...candidate.keys()]);
    let pairDiverged = false;
    for (const seq of sequence) {
      const left = baseline.get(seq);
      const right = candidate.get(seq);
      if (!left || !right) {
        pairDiverged = true;
        continue;
      }
      decisionRecordsCompared += 1;
      const inputChanged = left.input !== right.input;
      const outputChanged = left.output_hash !== right.output_hash;
      const validChanged = left.valid !== right.valid;
      const reasonChanged = left.reason !== right.reason;
      const detailChanged = left.detail !== right.detail;
      if (inputChanged) inputMismatchRecords += 1;
      if (outputChanged) outputHashChanges += 1;
      if (validChanged) validChanges += 1;
      if (reasonChanged) reasonChanges += 1;
      if (detailChanged) detailChanges += 1;
      if (inputChanged || outputChanged || validChanged || reasonChanged || detailChanged) pairDiverged = true;
    }
    if (pair.baseline.decisionSummary.trace_hash !== pair.candidate.decisionSummary.trace_hash) {
      traceHashChanges += 1;
    }
    if (pairDiverged) pairsWithDivergence += 1;
  }
  return {
    pairsCompared,
    pairsWithDivergence,
    decisionRecordsCompared,
    decisionCountMismatches,
    inputMismatchRecords,
    outputHashChanges,
    validChanges,
    reasonChanges,
    detailChanges,
    traceHashChanges,
  };
}

function branchIdentity(runs: ParsedRun[]) {
  const runtimeMD5 = new Set<string>();
  const packageSha256 = new Set<string>();
  for (const run of runs) {
    const identity = record(run.evidence.candidateIdentity);
    const runtime = text(identity?.runtimeMD5);
    const qa = record(run.evidence.qaPackageIdentity);
    const packageSha = text(qa?.packageSha256);
    if (runtime) runtimeMD5.add(runtime);
    if (packageSha) packageSha256.add(packageSha);
  }
  return { runtimeMD5: [...runtimeMD5].sort(), qaPackageSha256: [...packageSha256].sort() };
}

export type WinrateAnalysis = {
  schemaVersion: 1;
  generatedAt: string;
  matrix: {
    family: string;
    initialGeneralCount?: number;
    expectedPairs: number;
    expectedKeys: string[];
    seedsPerSeatSwap: number;
  };
  sources: {
    files: string[];
    invalidEvidence: Array<{ file: string; issues: string[] }>;
    parsedRuns: number;
    ignoredUnexpectedRuns: string[];
  };
  pairing: {
    baselineBranch: string;
    candidateBranch: string;
    pairs: number;
    baselineRuns: number;
    candidateRuns: number;
    missingBaseline: string[];
    missingCandidate: string[];
    duplicateKeys: string[];
    inputMismatchKeys: string[];
    rosterOrSeatMismatchKeys: string[];
    coverage: {
      bySeatSwap: Record<string, number>;
      byRosterSet: Record<string, number>;
    };
  };
  winner: Record<string, ReturnType<typeof summarizeWinners> & { identity: ReturnType<typeof branchIdentity> }>;
  paired: {
    overall: ReturnType<typeof summarizeMeanDelta>;
    bySeat: Record<string, ReturnType<typeof summarizeMeanDelta>>;
    byKingdom: Record<string, ReturnType<typeof summarizeMeanDelta>>;
  };
  fallback: Record<string, ReturnType<typeof summarizeFallback>>;
  latency: Record<string, ReturnType<typeof summarizeLatency>>;
  decisionDivergence: ReturnType<typeof summarizeDecisionDivergence>;
  gate: {
    status: 'OPEN' | 'READY_FOR_TUNING_REVIEW';
    sampleSufficient: boolean;
    integrityPass: boolean;
    reasons: string[];
  };
};

export function analyzeEvidence(evidence: WinrateEvidence[], options: {
  plan: MatrixPlanRow[];
  baselineBranch?: string;
  candidateBranch?: string;
  invalidEvidence?: Array<{ file: string; issues: string[] }>;
  sourceFiles?: string[];
  minPairs?: number;
  expectedInitialGeneralCount?: number;
}): WinrateAnalysis {
  const baselineBranch = options.baselineBranch ?? 'baseline';
  const candidateBranch = options.candidateBranch ?? 'candidate';
  const invalidEvidence = options.invalidEvidence ?? [];
  const sourceFiles = options.sourceFiles ?? [];
  const expected = new Map(options.plan.map((row) => [row.key, row]));
  const parsed: ParsedRun[] = [];
  const parsedIssues: Array<{ file: string; issues: string[] }> = [];
  for (let index = 0; index < evidence.length; index += 1) {
    const result = parseRun(evidence[index], sourceFiles[index] ?? `evidence-${index}.json`);
    if (result.run) parsed.push(result.run);
    else parsedIssues.push({ file: sourceFiles[index] ?? `evidence-${index}.json`, issues: result.issues });
  }
  const allInvalid = [...invalidEvidence, ...parsedIssues];
  const unexpected = parsed.filter((run) => !expected.has(run.key));
  const inPlan = parsed.filter((run) => expected.has(run.key));
  const byBranchKey = new Map<string, ParsedRun[]>();
  for (const run of inPlan) {
    const key = `${run.branch}\0${run.key}`;
    byBranchKey.set(key, [...(byBranchKey.get(key) ?? []), run]);
  }
  const duplicateKeys = [...byBranchKey.entries()]
    .filter(([, runs]) => runs.length > 1)
    .map(([key]) => key.replace('\0', ':'))
    .sort();
  const missingBaseline = options.plan.filter((row) => !byBranchKey.has(`${baselineBranch}\0${row.key}`)).map((row) => row.key);
  const missingCandidate = options.plan.filter((row) => !byBranchKey.has(`${candidateBranch}\0${row.key}`)).map((row) => row.key);
  const pairs: Array<{ baseline: ParsedRun; candidate: ParsedRun }> = [];
  const inputMismatchKeys: string[] = [];
  const rosterOrSeatMismatchKeys: string[] = [];
  for (const row of options.plan) {
    const baseline = byBranchKey.get(`${baselineBranch}\0${row.key}`) ?? [];
    const candidate = byBranchKey.get(`${candidateBranch}\0${row.key}`) ?? [];
    if (baseline.length !== 1 || candidate.length !== 1) continue;
    const left = baseline[0];
    const right = candidate[0];
    if (left.matrixInputHash !== right.matrixInputHash) inputMismatchKeys.push(row.key);
    if (left.rosterSet !== right.rosterSet || left.seatSwap !== right.seatSwap) rosterOrSeatMismatchKeys.push(row.key);
    pairs.push({ baseline: left, candidate: right });
  }
  const completeRuns = [...new Set(pairs.flatMap((pair) => [pair.baseline, pair.candidate]))];
  const coverageRows = pairs.map((pair) => pair.baseline);
  const bySeatSwap: Record<string, number> = {};
  const byRosterSet: Record<string, number> = {};
  for (const row of coverageRows) {
    bySeatSwap[row.seatSwap] = (bySeatSwap[row.seatSwap] ?? 0) + 1;
    byRosterSet[row.rosterSet] = (byRosterSet[row.rosterSet] ?? 0) + 1;
  }
  const baselineRuns = inPlan.filter((run) => run.branch === baselineBranch);
  const candidateRuns = inPlan.filter((run) => run.branch === candidateBranch);
  const winner = {
    [baselineBranch]: { ...summarizeWinners(baselineRuns), identity: branchIdentity(baselineRuns) },
    [candidateBranch]: { ...summarizeWinners(candidateRuns), identity: branchIdentity(candidateRuns) },
  };
  const delta = (selector: (run: ParsedRun) => boolean) => pairs.map((pair) =>
    Number(selector(pair.candidate)) - Number(selector(pair.baseline)));
  const baselineKingdoms = new Set<string>();
  const candidateKingdoms = new Set<string>();
  for (const pair of pairs) {
    for (const token of [...pair.baseline.matchResult.winnerKingdoms, ...pair.candidate.matchResult.winnerKingdoms]) {
      baselineKingdoms.add(token.slice(token.indexOf(':') + 1));
      candidateKingdoms.add(token.slice(token.indexOf(':') + 1));
    }
  }
  const bySeat: Record<string, ReturnType<typeof summarizeMeanDelta>> = {};
  for (let seat = 1; seat <= 4; seat += 1) {
    bySeat[String(seat)] = summarizeMeanDelta(delta((run) => run.matchResult.winnerSeats.includes(seat)));
  }
  const byKingdom: Record<string, ReturnType<typeof summarizeMeanDelta>> = {};
  for (const kingdom of [...new Set([...baselineKingdoms, ...candidateKingdoms])].sort()) {
    byKingdom[kingdom] = summarizeMeanDelta(delta((run) => [...winnerKingdomMap(run.matchResult).values()].includes(kingdom)));
  }
  const reasons: string[] = [];
  const minPairs = options.minPairs ?? options.plan.length;
  if (options.expectedInitialGeneralCount !== undefined) {
    for (const run of inPlan) {
      if (run.initialGeneralCount !== options.expectedInitialGeneralCount) {
        reasons.push(`initial general count mismatch: ${run.sourceFile}`);
      }
      if (run.generalChoiceCounts === null || run.generalChoiceCounts.length === 0 ||
          run.generalChoiceCounts.some((count) => count !== options.expectedInitialGeneralCount)) {
        reasons.push(`UI general choice count mismatch: ${run.sourceFile}`);
      }
      const offer = run.offerSummary;
      if (!offer || integerValue(offer.offer_count) !== options.expectedInitialGeneralCount) {
        reasons.push(`native offer count mismatch: ${run.sourceFile}`);
      }
      if (!offer || integerValue(offer.seat_count) !== 4 || offer.seats !== '1,2,3,4') {
        reasons.push(`native offer seat coverage mismatch: ${run.sourceFile}`);
      }
    }
  }
  if (pairs.length < minPairs) reasons.push(`paired sample is ${pairs.length}, below minimum ${minPairs}`);
  if (missingBaseline.length) reasons.push(`missing baseline pairs: ${missingBaseline.length}`);
  if (missingCandidate.length) reasons.push(`missing candidate pairs: ${missingCandidate.length}`);
  if (duplicateKeys.length) reasons.push(`duplicate branch/pair keys: ${duplicateKeys.length}`);
  if (allInvalid.length) reasons.push(`invalid evidence files: ${allInvalid.length}`);
  if (inputMismatchKeys.length) reasons.push(`paired input hash mismatches: ${inputMismatchKeys.length}`);
  if (rosterOrSeatMismatchKeys.length) reasons.push(`paired roster/seat mismatches: ${rosterOrSeatMismatchKeys.length}`);
  const requiredSeatSwaps = new Set(options.plan.map((row) => row.seatSwap));
  const requiredRosters = new Set(options.plan.map((row) => row.rosterSet));
  for (const seatSwap of requiredSeatSwaps) {
    if ((bySeatSwap[seatSwap] ?? 0) === 0) reasons.push(`missing seat-swap coverage: ${seatSwap}`);
  }
  for (const rosterSet of requiredRosters) {
    if ((byRosterSet[rosterSet] ?? 0) === 0) reasons.push(`missing roster coverage: ${rosterSet}`);
  }
  for (const run of completeRuns) {
    if (run.decisionSummary.overflow === 'true') reasons.push(`decision trace overflow: ${run.sourceFile}`);
    if (run.matchResult.outcome !== 'win' || run.matchResult.winnerCount !== 1) {
      reasons.push(`non-single-winner result: ${run.sourceFile}`);
    }
  }
  const missingChoicePool = [baselineBranch, candidateBranch]
    .map((branch) => ({ branch, count: summarizeFallback(branch === baselineBranch ? baselineRuns : candidateRuns).missingChoicePool }))
    .filter((entry) => entry.count > 0);
  for (const entry of missingChoicePool) {
    reasons.push(`fallback due to missing general-choice pool: ${entry.branch}=${entry.count}`);
  }
  const integrityPass = reasons.length === 0;
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    matrix: {
      family: MATRIX_FAMILY,
      ...(options.expectedInitialGeneralCount === undefined
        ? {}
        : { initialGeneralCount: options.expectedInitialGeneralCount }),
      expectedPairs: options.plan.length,
      expectedKeys: options.plan.map((row) => row.key),
      seedsPerSeatSwap: options.plan.length > 0
        ? options.plan.filter((row) => row.seatSwap === options.plan[0].seatSwap).length
        : 0,
    },
    sources: {
      files: sourceFiles,
      invalidEvidence: allInvalid,
      parsedRuns: parsed.length,
      ignoredUnexpectedRuns: unexpected.map((run) => `${run.branch}:${run.key}`).sort(),
    },
    pairing: {
      baselineBranch,
      candidateBranch,
      pairs: pairs.length,
      baselineRuns: baselineRuns.length,
      candidateRuns: candidateRuns.length,
      missingBaseline,
      missingCandidate,
      duplicateKeys,
      inputMismatchKeys,
      rosterOrSeatMismatchKeys,
      coverage: { bySeatSwap, byRosterSet },
    },
    winner,
    paired: {
      overall: summarizeMeanDelta(delta((run) => run.matchResult.outcome === 'win' && run.matchResult.winnerCount === 1)),
      bySeat,
      byKingdom,
    },
    fallback: {
      [baselineBranch]: summarizeFallback(baselineRuns),
      [candidateBranch]: summarizeFallback(candidateRuns),
    },
    latency: {
      [baselineBranch]: summarizeLatency(baselineRuns),
      [candidateBranch]: summarizeLatency(candidateRuns),
    },
    decisionDivergence: summarizeDecisionDivergence(pairs),
    gate: {
      status: integrityPass ? 'READY_FOR_TUNING_REVIEW' : 'OPEN',
      sampleSufficient: pairs.length >= minPairs,
      integrityPass,
      reasons,
    },
  };
}

function integerOption(args: string[], name: string, fallback: number): number {
  const index = args.indexOf(name);
  if (index < 0) return fallback;
  const value = Number(args[index + 1]);
  if (!Number.isSafeInteger(value)) throw new Error(`${name} requires a safe integer`);
  return value;
}

function stringOption(args: string[], name: string): string | undefined {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}

function resolveRepoPath(repo: string, value: string): string {
  return path.isAbsolute(value) ? value : path.resolve(repo, value);
}

function runMatrix(plan: MatrixPlanRow[], repo: string, args: string[]) {
  const branch = stringOption(args, '--branch') ?? process.env.TQS_WINRATE_BRANCH;
  if (!branch || !/^[A-Za-z0-9_-]{1,40}$/u.test(branch)) {
    throw new Error('--branch or metadata-safe TQS_WINRATE_BRANCH is required for --run');
  }
  const runId = stringOption(args, '--run-id') ?? process.env.TQS_WINRATE_RUN_ID ?? `winrate-${Date.now()}`;
  if (!/^[A-Za-z0-9_.-]{1,100}$/u.test(runId)) throw new Error('--run-id is not metadata-safe');
  const limit = integerOption(args, '--limit', plan.length);
  const offset = integerOption(args, '--offset', 0);
  if (offset < 0 || offset >= plan.length) throw new Error('--offset must point inside the matrix plan');
  if (limit < 1 || offset + limit > plan.length) throw new Error('--limit/--offset must stay within the matrix plan');
  const candidateId = stringOption(args, '--candidate-id') ?? process.env.TQS_CANDIDATE_ID ?? 'cp08';
  if (!/^cp\d{2}$/u.test(candidateId)) throw new Error('--candidate-id must match cpNN');
  const command = ['--prefix', path.join(repo, 'game/web'), 'run', 'test:e2e:multiplayer', '--', '--audit-bots'];
  for (const row of plan.slice(offset, offset + limit)) {
    console.log(JSON.stringify({ stage: 'run', branch, runId, scenario: row.scenario, seed: row.seed, rosterSet: row.rosterSet, seatSwap: row.seatSwap }));
    const result = spawnSync('npm', command, {
      cwd: repo,
      stdio: 'inherit',
      env: {
        ...process.env,
        TQS_LIVE_NATIVE_QA: '1',
        TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS: '1',
        TQS_LIVE_SCENARIO: row.scenario,
        TQS_LIVE_SEED: String(row.seed),
        TQS_CANDIDATE_ID: candidateId,
        TQS_WINRATE_BRANCH: branch,
        TQS_WINRATE_RUN_ID: runId,
      },
    });
    if (result.status !== 0) {
      throw new Error(`matrix run failed for ${row.scenario}:${row.seed} with status ${String(result.status)}`);
    }
  }
}

export function main(argv = process.argv.slice(2)) {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const repo = path.resolve(scriptDir, '../../..');
  const catalogOption = stringOption(argv, '--catalog');
  const catalogPath = catalogOption
    ? resolveRepoPath(repo, catalogOption)
    : path.join(repo, 'deploy/freekill-native/qa/tqs_qa/catalog.json');
  const catalog = readJson<MatrixCatalog>(catalogPath);
  const scenarioOption = stringOption(argv, '--scenario');
  const plan = buildMatrixPlan(catalog, {
    seedsPerSeatSwap: integerOption(argv, '--seeds-per-seat', DEFAULT_SEEDS_PER_SEAT_SWAP),
    seedStart: integerOption(argv, '--seed-start', catalog.generalPairMatrix?.seedRange?.min ?? 0),
    scenarioIds: scenarioOption ? [scenarioOption] : undefined,
  });
  if (argv.includes('--plan')) {
    console.log(JSON.stringify({ family: MATRIX_FAMILY, pairsPerBranch: plan.length, plan }, null, 2));
    return 0;
  }
  if (argv.includes('--run')) {
    runMatrix(plan, repo, argv);
    return 0;
  }
  const evidenceOption = stringOption(argv, '--evidence-dir');
  const evidenceDir = evidenceOption
    ? resolveRepoPath(repo, evidenceOption)
    : path.join(repo, 'scratch/evidence');
  const runId = stringOption(argv, '--run-id');
  if (runId && !/^[A-Za-z0-9_.-]{1,100}$/u.test(runId)) throw new Error('--run-id is not metadata-safe');
  const loaded = loadEvidenceDirectory(
    evidenceDir,
    stringOption(argv, '--prefix') ?? 'general-pair-match-mixed-',
    runId,
  );
  const expectedInitialGeneralCount = argv.includes('--initial-general-count')
    ? integerOption(argv, '--initial-general-count', 0)
    : undefined;
  if (expectedInitialGeneralCount !== undefined &&
      (expectedInitialGeneralCount < 5 || expectedInitialGeneralCount > 10)) {
    throw new Error('--initial-general-count must be an integer from five through ten');
  }
  const analysis = analyzeEvidence(loaded.evidence, {
    plan,
    baselineBranch: stringOption(argv, '--baseline-branch') ?? 'baseline',
    candidateBranch: stringOption(argv, '--candidate-branch') ?? 'candidate',
    invalidEvidence: loaded.invalidFiles,
    sourceFiles: loaded.sourceFiles,
    minPairs: integerOption(argv, '--min-pairs', plan.length),
    expectedInitialGeneralCount,
  });
  const outputPath = stringOption(argv, '--output');
  if (outputPath) writeFileSync(resolveRepoPath(repo, outputPath), JSON.stringify(analysis, null, 2));
  console.log(JSON.stringify(analysis, null, 2));
  return argv.includes('--strict') && analysis.gate.status !== 'READY_FOR_TUNING_REVIEW' ? 2 : 0;
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(fileURLToPath(import.meta.url));
if (isMain) {
  try {
    process.exitCode = main();
  } catch (error) {
    console.error(`FAIL general-pair-winrate: ${(error as Error).message}`);
    process.exitCode = 1;
  }
}
