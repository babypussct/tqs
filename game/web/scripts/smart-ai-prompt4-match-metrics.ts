/**
 * Parse the opt-in native [AI_MATCH_METRICS] line and compare two sanitized
 * match summaries. The native emitter never writes cards, targets, prompts,
 * hand contents, general identities or account names; this parser rejects
 * anything outside the bounded token grammar as well.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export type MatchBucket = {
  requests: number;
  accepted: number;
  fallback: number;
  invalid: number;
  no_decision: number;
};

export type CommandBucket = {
  total: number;
  fallback: number;
  invalid: number;
  no_decision: number;
};

export type NativeAiMatchMetrics = {
  schemaVersion: 1;
  matchCount: number;
  roomId: number;
  mode: string;
  total: number;
  fallback: number;
  invalid: number;
  no_decision: number;
  accepted: number;
  skills: Record<string, MatchBucket>;
  commands: Record<string, CommandBucket>;
};

export type NativeAiMatchDiagnosticRoom = {
  metrics: NativeAiMatchMetrics;
  fallbackReasons: Record<string, number>;
  invalidDetails: Record<string, number>;
  commands: Record<string, {
    total: number;
    fallback: number;
    invalid: number;
    fallbackReasons: Record<string, number>;
    invalidDetails: Record<string, number>;
  }>;
};

export type Prompt4NativeDiagnosticsReview = {
  kind: 'prompt4_native_fallback_diagnostics_review';
  matchedRequestState: false;
  causalAttributionAvailable: false;
  baselineRooms: number;
  candidateRooms: number;
  fallbackReasonDelta: Record<string, number>;
  invalidDetailDelta: Record<string, number>;
  commandDeltas: Record<string, { total: number; fallback: number; invalid: number }>;
};

export type PairBucket = {
  candidate: MatchBucket | null;
  baseline: MatchBucket | null;
  delta: MatchBucket;
};

export type Prompt4MatchPairReport = {
  schemaVersion: 1;
  kind: 'prompt4_native_match_pair';
  mode: string;
  sameMode: boolean;
  candidate: NativeAiMatchMetrics;
  baseline: NativeAiMatchMetrics;
  aggregateDelta: {
    total: number;
    accepted: number;
    fallback: number;
    invalid: number;
    no_decision: number;
  };
  skills: Record<string, PairBucket>;
  diagnosticReview?: Prompt4NativeDiagnosticsReview;
  winRateAvailable: false;
  limitations: string[];
};

const ANSI_ESCAPE = /\u001b\[[0-?]*[ -/]*[@-~]/gu;
const TOKEN = /^[A-Za-z0-9_-]+$/u;
export const SAFE_FALLBACK_REASONS = new Set([
  'ai_exception', 'ai_no_reply', 'handler_error', 'invalid_reply',
  'invalid_strategy_reply', 'illegal_reply', 'malformed_data', 'malformed_prompt',
  'missing_command', 'no_decision', 'no_strategy', 'unsupported_command',
  'unexpected_notready', 'validator_error', 'other',
]);
export const SAFE_INVALID_DETAILS = new Set([
  'missing_handler', 'card_lookup_failed', 'skill_missing', 'special_skill_missing',
  'feasibility_exception', 'feasibility_rejected', 'unclassified', 'other',
]);
// These categories mirror Base.AI:recordMetric() in lua/server/ai.lua.
// An unrecognized native reason is emitted as `other`, so its contribution
// to invalid/no_decision cannot be assigned to a subtype from the log alone.
const INVALID_REASONS = ['invalid_reply', 'illegal_reply', 'validator_error', 'invalid_strategy_reply'] as const;
const NO_DECISION_REASONS = ['no_decision', 'no_strategy', 'malformed_data', 'malformed_prompt', 'ai_no_reply'] as const;
const DETAIL_LINE = /^\[AI_MATCH_METRICS_DETAIL\] schema=(\d+) room=(\d+) mode=([A-Za-z0-9_-]+) fallback=(\d+) invalid=(\d+) reasons=(\S+) invalid_details=(\S+)$/u;
const COMMAND_LINE = /^\[AI_MATCH_METRICS_COMMAND\] schema=(\d+) room=(\d+) mode=([A-Za-z0-9_-]+) command=([A-Za-z0-9_-]+) total=(\d+) fallback=(\d+) invalid=(\d+) reasons=(\S+) invalid_details=(\S+)$/u;

function nonNegativeInteger(value: string, label: string): number {
  if (!/^\d+$/u.test(value)) throw new Error(`${label} is not a non-negative integer`);
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) throw new Error(`${label} exceeds safe integer range`);
  return parsed;
}

function checkedSum(values: Iterable<number>, label: string): number {
  let sum = 0;
  for (const value of values) {
    sum += value;
    if (!Number.isSafeInteger(sum)) throw new Error(`${label} exceeds safe integer range`);
  }
  return sum;
}

function checkParts(total: number, fallback: number, invalid: number, noDecision: number, label: string): void {
  if (invalid > fallback || noDecision > fallback ||
    checkedSum([invalid, noDecision], label) > fallback || fallback > total) {
    throw new Error(`${label} invalid/no_decision must be disjoint subsets of fallback`);
  }
}

function checkBucketCoverage(metrics: NativeAiMatchMetrics): void {
  checkParts(metrics.total, metrics.fallback, metrics.invalid, metrics.no_decision, 'aggregate');
  const skillTotals: number[] = [];
  for (const [skill, bucket] of Object.entries(metrics.skills)) {
    if (checkedSum([bucket.accepted, bucket.fallback], `skill ${skill}`) !== bucket.requests) {
      throw new Error(`skill ${skill} accepted + fallback must equal requests`);
    }
    checkParts(bucket.requests, bucket.fallback, bucket.invalid, bucket.no_decision, `skill ${skill}`);
    skillTotals.push(bucket.requests);
  }
  if (checkedSum(skillTotals, 'skill requests') > metrics.total) {
    throw new Error('skill requests exceed native total');
  }
  const sums = { total: 0, fallback: 0, invalid: 0, no_decision: 0 };
  for (const [command, bucket] of Object.entries(metrics.commands)) {
    checkParts(bucket.total, bucket.fallback, bucket.invalid, bucket.no_decision, `command ${command}`);
    for (const field of ['total', 'fallback', 'invalid', 'no_decision'] as const) {
      sums[field] = checkedSum([sums[field], bucket[field]], `command ${field}`);
    }
  }
  for (const field of ['total', 'fallback', 'invalid', 'no_decision'] as const) {
    if (sums[field] !== metrics[field]) throw new Error(`native command ${field} sum does not match aggregate`);
  }
}

function parseBuckets<T extends readonly string[]>(
  encoded: string,
  fields: T,
  label: string,
): Record<string, Record<T[number], number>> {
  if (encoded === '-') return Object.create(null);
  // A null-prototype dictionary preserves native labels such as __proto__ as
  // data, so they cannot change the object prototype or evade coverage sums.
  const result: Record<string, Record<T[number], number>> = Object.create(null);
  for (const entry of encoded.split(',')) {
    const parts = entry.split(':');
    if (parts.length !== fields.length + 1 || !TOKEN.test(parts[0]) || parts[0].length > 64 ||
      !/[A-Za-z_]/u.test(parts[0]) || Object.hasOwn(result, parts[0])) {
      throw new Error(`${label} contains an invalid bucket`);
    }
    const bucket = {} as Record<T[number], number>;
    fields.forEach((field, index) => {
      bucket[field as T[number]] = nonNegativeInteger(parts[index + 1], `${label}.${parts[0]}.${field}`);
    });
    result[parts[0]] = bucket;
  }
  return result;
}

export function parseAiMatchMetricsLine(line: string): NativeAiMatchMetrics | null {
  const clean = line.replace(ANSI_ESCAPE, '');
  const match = clean.match(
    /\[AI_MATCH_METRICS\]\s+schema=(\d+)\s+room=(\d+)\s+mode=([A-Za-z0-9_-]+)\s+total=(\d+)\s+fallback=(\d+)\s+invalid=(\d+)\s+no_decision=(\d+)\s+accepted=(\d+)\s+skills=(\S+)\s+commands=(\S+)\s*$/u,
  );
  if (!match) return null;
  const schemaVersion = nonNegativeInteger(match[1], 'schema');
  if (schemaVersion !== 1) throw new Error(`unsupported AI metrics schema ${schemaVersion}`);
  const total = nonNegativeInteger(match[4], 'total');
  const fallback = nonNegativeInteger(match[5], 'fallback');
  const invalid = nonNegativeInteger(match[6], 'invalid');
  const no_decision = nonNegativeInteger(match[7], 'no_decision');
  const accepted = nonNegativeInteger(match[8], 'accepted');
  if (checkedSum([accepted, fallback], 'aggregate') !== total) throw new Error('accepted + fallback must equal total');
  const skills = parseBuckets(match[9], ['requests', 'accepted', 'fallback', 'invalid', 'no_decision'] as const, 'skills') as Record<string, MatchBucket>;
  const commands = parseBuckets(match[10], ['total', 'fallback', 'invalid', 'no_decision'] as const, 'commands') as Record<string, CommandBucket>;
  const metrics: NativeAiMatchMetrics = {
    schemaVersion,
    matchCount: 1,
    roomId: nonNegativeInteger(match[2], 'room'),
    mode: match[3],
    total,
    fallback,
    invalid,
    no_decision,
    accepted,
    skills,
    commands,
  };
  checkBucketCoverage(metrics);
  return metrics;
}

export function parseAiMatchMetricsLines(text: string): NativeAiMatchMetrics[] {
  const parsed: NativeAiMatchMetrics[] = [];
  for (const line of text.split(/\r?\n/u)) {
    const candidate = parseAiMatchMetricsLine(line);
    if (candidate) parsed.push(candidate);
  }
  return parsed;
}

function addBucket<T extends Record<string, number>>(target: T, source: T): void {
  for (const [key, value] of Object.entries(source)) {
    target[key as keyof T] = checkedSum(
      [(target[key as keyof T] as number | undefined) ?? 0, value], `bucket ${key}`,
    ) as T[keyof T];
  }
}

export function aggregateAiMatchMetrics(records: readonly NativeAiMatchMetrics[]): NativeAiMatchMetrics {
  if (records.length === 0) throw new Error('native log has no valid [AI_MATCH_METRICS] line');
  const mode = records[0].mode;
  if (records.some((record) => record.mode !== mode)) throw new Error('native metrics contain multiple modes');
  const aggregate: NativeAiMatchMetrics = {
    schemaVersion: 1,
    matchCount: 0,
    roomId: records.length === 1 ? records[0].roomId : 0,
    mode,
    total: 0,
    fallback: 0,
    invalid: 0,
    no_decision: 0,
    accepted: 0,
    skills: Object.create(null),
    commands: Object.create(null),
  };
  for (const record of records) {
    aggregate.matchCount = checkedSum([aggregate.matchCount, record.matchCount], 'match count');
    aggregate.total = checkedSum([aggregate.total, record.total], 'total');
    aggregate.fallback = checkedSum([aggregate.fallback, record.fallback], 'fallback');
    aggregate.invalid = checkedSum([aggregate.invalid, record.invalid], 'invalid');
    aggregate.no_decision = checkedSum([aggregate.no_decision, record.no_decision], 'no_decision');
    aggregate.accepted = checkedSum([aggregate.accepted, record.accepted], 'accepted');
    for (const [skill, bucket] of Object.entries(record.skills)) {
      const target = aggregate.skills[skill] ?? (aggregate.skills[skill] = {
        requests: 0, accepted: 0, fallback: 0, invalid: 0, no_decision: 0,
      });
      addBucket(target, bucket);
    }
    for (const [command, bucket] of Object.entries(record.commands)) {
      const target = aggregate.commands[command] ?? (aggregate.commands[command] = {
        total: 0, fallback: 0, invalid: 0, no_decision: 0,
      });
      addBucket(target, bucket);
    }
  }
  return aggregate;
}

export function parseAiMatchMetricsLog(text: string): NativeAiMatchMetrics {
  return aggregateAiMatchMetrics(parseAiMatchMetricsLines(text));
}

function parseSafeCounts(encoded: string, allowed: Set<string>, label: string): Record<string, number> {
  if (encoded === '-') return {};
  const counts: Record<string, number> = Object.create(null);
  for (const entry of encoded.split(',')) {
    const pieces = entry.split(':');
    if (pieces.length !== 2 || !allowed.has(pieces[0]) || Object.hasOwn(counts, pieces[0])) {
      throw new Error(`${label} has unrecognized, duplicate or payload-like category`);
    }
    const count = nonNegativeInteger(pieces[1], `${label}.${pieces[0]}`);
    if (count === 0) throw new Error(`${label} includes zero-count category`);
    counts[pieces[0]] = count;
  }
  return counts;
}

function sumCounts(counts: Record<string, number>): number {
  return checkedSum(Object.values(counts), 'diagnostic counts');
}

function checkReasonClasses(
  reasons: Record<string, number>, invalid: number, noDecision: number, label: string,
): void {
  const knownInvalid = checkedSum(INVALID_REASONS.map((reason) => reasons[reason] ?? 0), `${label}.invalid`);
  const knownNoDecision = checkedSum(NO_DECISION_REASONS.map((reason) => reasons[reason] ?? 0), `${label}.no_decision`);
  const other = reasons.other ?? 0;
  if (invalid < knownInvalid || invalid > checkedSum([knownInvalid, other], label) ||
    noDecision < knownNoDecision || noDecision > checkedSum([knownNoDecision, other], label) ||
    checkedSum([invalid, noDecision], label) > checkedSum([knownInvalid, knownNoDecision, other], label)) {
    throw new Error(`${label} invalid/no_decision reason classes do not reconcile`);
  }
}

function sameCounts(left: Record<string, number>, right: Record<string, number>): boolean {
  const keys = new Set([...Object.keys(left), ...Object.keys(right)]);
  return [...keys].every((key) => (left[key] ?? 0) === (right[key] ?? 0));
}

/**
 * Strictly join the opt-in diagnostic lines to each aggregate match summary.
 * The legacy parser above remains compatible with old logs without details.
 * Diagnostics never contain a hand, target, general or raw request payload.
 */
export function parseAiMatchDiagnosticsLog(log: string): NativeAiMatchDiagnosticRoom[] {
  type Pending = NativeAiMatchDiagnosticRoom & { detailSeen: boolean };
  const runs: Pending[] = [];
  let current: Pending | null = null;
  for (const raw of log.split(/\r?\n/u)) {
    const clean = raw.replace(ANSI_ESCAPE, '');
    const index = clean.indexOf('[AI_MATCH_METRICS');
    if (index < 0) continue;
    const line = clean.slice(index).trim();
    if (line.startsWith('[AI_MATCH_METRICS]')) {
      if (current && !current.detailSeen) throw new Error('previous room is missing diagnostics');
      const metrics = parseAiMatchMetricsLine(line);
      if (!metrics) throw new Error('malformed aggregate metrics');
      current = {
        metrics, fallbackReasons: Object.create(null), invalidDetails: Object.create(null),
        commands: Object.create(null), detailSeen: false,
      };
      runs.push(current);
      continue;
    }
    if (!current) throw new Error('native diagnostic without aggregate metrics');
    const { roomId, mode } = current.metrics;
    if (line.startsWith('[AI_MATCH_METRICS_DETAIL]')) {
      const match = line.match(DETAIL_LINE);
      if (!match || current.detailSeen) throw new Error('duplicate or malformed native diagnostic detail');
      if (nonNegativeInteger(match[1], 'schema') !== 1 ||
        nonNegativeInteger(match[2], 'room') !== roomId || match[3] !== mode ||
        nonNegativeInteger(match[4], 'fallback') !== current.metrics.fallback ||
        nonNegativeInteger(match[5], 'invalid') !== current.metrics.invalid) {
        throw new Error('native diagnostic aggregate identity or counters mismatch');
      }
      current.fallbackReasons = parseSafeCounts(match[6], SAFE_FALLBACK_REASONS, 'reasons');
      current.invalidDetails = parseSafeCounts(match[7], SAFE_INVALID_DETAILS, 'invalid_details');
      current.detailSeen = true;
    } else if (line.startsWith('[AI_MATCH_METRICS_COMMAND]')) {
      const match = line.match(COMMAND_LINE);
      if (!match || !current.detailSeen) throw new Error('malformed or out-of-order command diagnostic');
      const command = match[4];
      const expected = current.metrics.commands[command];
      if (nonNegativeInteger(match[1], 'schema') !== 1 ||
        nonNegativeInteger(match[2], 'room') !== roomId || match[3] !== mode ||
        !expected || Object.hasOwn(current.commands, command) ||
        nonNegativeInteger(match[5], 'command.total') !== expected.total ||
        nonNegativeInteger(match[6], 'command.fallback') !== expected.fallback ||
        nonNegativeInteger(match[7], 'command.invalid') !== expected.invalid) {
        throw new Error('native command diagnostic identity or counters mismatch');
      }
      current.commands[command] = {
        total: expected.total, fallback: expected.fallback, invalid: expected.invalid,
        fallbackReasons: parseSafeCounts(match[8], SAFE_FALLBACK_REASONS, 'command.reasons'),
        invalidDetails: parseSafeCounts(match[9], SAFE_INVALID_DETAILS, 'command.invalid_details'),
      };
    } else {
      throw new Error('unrecognized native metrics diagnostic');
    }
  }
  if (runs.length === 0) throw new Error('native log has no match metrics');
  for (const room of runs) {
    if (!room.detailSeen) throw new Error('native room is missing diagnostic detail');
    const { metrics, commands } = room;
    if (sumCounts(room.fallbackReasons) !== metrics.fallback ||
      sumCounts(room.invalidDetails) !== (room.fallbackReasons.illegal_reply ?? 0)) {
      throw new Error('native detail reasons do not reconcile with fallback or illegal replies');
    }
    checkReasonClasses(room.fallbackReasons, metrics.invalid, metrics.no_decision, 'native detail');
    const expectedCommands = Object.keys(metrics.commands);
    if (expectedCommands.length !== Object.keys(commands).length) {
      throw new Error('native command diagnostics are incomplete');
    }
    const reasonTotals: Record<string, number> = Object.create(null);
    const detailTotals: Record<string, number> = Object.create(null);
    let total = 0; let fallback = 0; let invalid = 0; let noDecision = 0;
    for (const [command, bucket] of Object.entries(commands)) {
      total = checkedSum([total, bucket.total], 'native command diagnostic total');
      fallback = checkedSum([fallback, bucket.fallback], 'native command diagnostic fallback');
      invalid = checkedSum([invalid, bucket.invalid], 'native command diagnostic invalid');
      noDecision = checkedSum([noDecision, metrics.commands[command].no_decision], 'native command diagnostic no_decision');
      if (sumCounts(bucket.fallbackReasons) !== bucket.fallback ||
        sumCounts(bucket.invalidDetails) !== (bucket.fallbackReasons.illegal_reply ?? 0)) {
        throw new Error('native per-command reasons do not reconcile');
      }
      checkReasonClasses(bucket.fallbackReasons, bucket.invalid, metrics.commands[command].no_decision,
        `native command ${command}`);
      for (const [reason, count] of Object.entries(bucket.fallbackReasons)) {
        reasonTotals[reason] = checkedSum([reasonTotals[reason] ?? 0, count], `native reason ${reason}`);
      }
      for (const [detail, count] of Object.entries(bucket.invalidDetails)) {
        detailTotals[detail] = checkedSum([detailTotals[detail] ?? 0, count], `native invalid detail ${detail}`);
      }
    }
    if (total !== metrics.total || fallback !== metrics.fallback ||
      invalid !== metrics.invalid || noDecision !== metrics.no_decision ||
      !sameCounts(reasonTotals, room.fallbackReasons) || !sameCounts(detailTotals, room.invalidDetails)) {
      throw new Error('native command sums do not reconcile with aggregate');
    }
  }
  return runs.map(({ detailSeen: _detailSeen, ...room }) => room);
}

function deltaCounts(
  candidate: readonly NativeAiMatchDiagnosticRoom[],
  baseline: readonly NativeAiMatchDiagnosticRoom[],
  select: (room: NativeAiMatchDiagnosticRoom) => Record<string, number>,
): Record<string, number> {
  const aggregate = (rooms: readonly NativeAiMatchDiagnosticRoom[]): Record<string, number> => {
    const totals: Record<string, number> = Object.create(null);
    for (const room of rooms) for (const [key, count] of Object.entries(select(room))) {
      totals[key] = checkedSum([totals[key] ?? 0, count], `review category ${key}`);
    }
    return totals;
  };
  const left = aggregate(candidate);
  const right = aggregate(baseline);
  return Object.fromEntries([...new Set([...Object.keys(left), ...Object.keys(right)])].sort()
    .map((key) => [key, (left[key] ?? 0) - (right[key] ?? 0)]));
}

export function buildPrompt4NativeDiagnosticsReview(
  candidate: readonly NativeAiMatchDiagnosticRoom[],
  baseline: readonly NativeAiMatchDiagnosticRoom[],
): Prompt4NativeDiagnosticsReview {
  const commandNames = new Set([...candidate, ...baseline].flatMap((room) => Object.keys(room.commands)));
  const commandDeltas: Prompt4NativeDiagnosticsReview['commandDeltas'] = Object.create(null);
  for (const command of [...commandNames].sort()) {
    const sum = (rooms: readonly NativeAiMatchDiagnosticRoom[], field: 'total' | 'fallback' | 'invalid') =>
      rooms.reduce((count, room) => checkedSum([count, room.commands[command]?.[field] ?? 0],
        `review command ${command}.${field}`), 0);
    commandDeltas[command] = {
      total: sum(candidate, 'total') - sum(baseline, 'total'),
      fallback: sum(candidate, 'fallback') - sum(baseline, 'fallback'),
      invalid: sum(candidate, 'invalid') - sum(baseline, 'invalid'),
    };
  }
  return {
    kind: 'prompt4_native_fallback_diagnostics_review',
    matchedRequestState: false, causalAttributionAvailable: false,
    baselineRooms: baseline.length, candidateRooms: candidate.length,
    fallbackReasonDelta: deltaCounts(candidate, baseline, (room) => room.fallbackReasons),
    invalidDetailDelta: deltaCounts(candidate, baseline, (room) => room.invalidDetails),
    commandDeltas,
  };
}

function emptyMatchBucket(): MatchBucket {
  return { requests: 0, accepted: 0, fallback: 0, invalid: 0, no_decision: 0 };
}

function diffBucket(candidate: MatchBucket | null, baseline: MatchBucket | null): MatchBucket {
  const left = candidate ?? emptyMatchBucket();
  const right = baseline ?? emptyMatchBucket();
  return {
    requests: left.requests - right.requests,
    accepted: left.accepted - right.accepted,
    fallback: left.fallback - right.fallback,
    invalid: left.invalid - right.invalid,
    no_decision: left.no_decision - right.no_decision,
  };
}

export function buildPrompt4MatchPairReport(
  candidate: NativeAiMatchMetrics,
  baseline: NativeAiMatchMetrics,
): Prompt4MatchPairReport {
  const skillNames = [...new Set([...Object.keys(candidate.skills), ...Object.keys(baseline.skills)])].sort();
  const skills: Record<string, PairBucket> = Object.create(null);
  for (const skill of skillNames) {
    const candidateBucket = candidate.skills[skill] ?? null;
    const baselineBucket = baseline.skills[skill] ?? null;
    skills[skill] = {
      candidate: candidateBucket,
      baseline: baselineBucket,
      delta: diffBucket(candidateBucket, baselineBucket),
    };
  }
  return {
    schemaVersion: 1,
    kind: 'prompt4_native_match_pair',
    mode: candidate.mode,
    sameMode: candidate.mode === baseline.mode,
    candidate,
    baseline,
    aggregateDelta: {
      total: candidate.total - baseline.total,
      accepted: candidate.accepted - baseline.accepted,
      fallback: candidate.fallback - baseline.fallback,
      invalid: candidate.invalid - baseline.invalid,
      no_decision: candidate.no_decision - baseline.no_decision,
    },
    skills,
    winRateAvailable: false,
    limitations: [
      'One pair of match summaries does not establish win-rate or causal skill value.',
      'Skill buckets count observed AI requests and accepted replies; they do not prove every legal opportunity was presented.',
      'The native emitter is opt-in and metadata-only; raw logs and request payloads are outside this report.',
    ],
  };
}

function main(argv: string[]): void {
  const [candidatePath, baselinePath, outputPath] = argv;
  if (!candidatePath || !baselinePath) {
    throw new Error('usage: smart-ai-prompt4-match-metrics.ts <candidate-log> <baseline-log> [output-json]');
  }
  const candidateLog = fs.readFileSync(candidatePath, 'utf8');
  const baselineLog = fs.readFileSync(baselinePath, 'utf8');
  const report = buildPrompt4MatchPairReport(
    parseAiMatchMetricsLog(candidateLog), parseAiMatchMetricsLog(baselineLog),
  );
  if (candidateLog.includes('[AI_MATCH_METRICS_DETAIL]') || baselineLog.includes('[AI_MATCH_METRICS_DETAIL]')) {
    // A partial instrumentation rollout cannot pass a diagnostics comparison.
    report.diagnosticReview = buildPrompt4NativeDiagnosticsReview(
      parseAiMatchDiagnosticsLog(candidateLog), parseAiMatchDiagnosticsLog(baselineLog),
    );
  }
  const serialized = `${JSON.stringify(report, null, 2)}\n`;
  if (outputPath) fs.writeFileSync(outputPath, serialized, { mode: 0o600 });
  else process.stdout.write(serialized);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main(process.argv.slice(2));
