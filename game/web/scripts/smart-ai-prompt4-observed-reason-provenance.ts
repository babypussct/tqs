/**
 * Forensic reconciliation of an isolated, completed native match against its
 * previously saved metadata-only metrics. Never emit raw native log content.
 * Log fallback lines have no room identifier, so match isolation is bounded
 * by the preceding and selected [AI_MATCH_METRICS] summaries.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  parseAiMatchMetricsLine, SAFE_FALLBACK_REASONS, SAFE_INVALID_DETAILS,
  type NativeAiMatchMetrics,
} from './smart-ai-prompt4-match-metrics';

type Counts = Record<string, number>;
type Observed = {
  schemaVersion: number;
  mode: string;
  matchCount: number;
  aggregate: { total: number; accepted: number; fallback: number; invalid: number; no_decision: number };
  commands: NativeAiMatchMetrics['commands'];
  skills: NativeAiMatchMetrics['skills'];
};

const FALLBACK = /\[AI\] fallback command=([A-Za-z0-9_-]{1,64}) reason=([A-Za-z0-9_-]{1,64})(?: detail=([A-Za-z0-9_-]{1,64}))? elapsed=\d+(?:\.\d+)?ms\s*$/u;
const INVALID = new Set(['invalid_reply', 'illegal_reply', 'validator_error', 'invalid_strategy_reply']);
const NO_DECISION = new Set(['no_decision', 'no_strategy', 'malformed_data', 'malformed_prompt', 'ai_no_reply']);

function requireCounter(value: number, label: string): number {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(`invalid ${label} counter`);
  return value;
}

function plus(a: number, b: number): number {
  const sum = a + b;
  if (!Number.isSafeInteger(sum)) throw new Error('counter overflow');
  return sum;
}

function increment(counts: Counts, key: string): void {
  counts[key] = plus(counts[key] ?? 0, 1);
}

function sorted(counts: Counts): Counts {
  return Object.fromEntries(Object.entries(counts).sort(([a], [b]) => a.localeCompare(b)));
}

function sameBuckets(left: Record<string, Record<string, number>>, right: Record<string, Record<string, number>>): boolean {
  const lkeys = Object.keys(left).sort();
  if (JSON.stringify(lkeys) !== JSON.stringify(Object.keys(right).sort())) return false;
  return lkeys.every((key) => Object.keys(left[key]).length === Object.keys(right[key]).length &&
    Object.entries(left[key]).every(([name, count]) =>
      Number.isSafeInteger(count) && count >= 0 && right[key][name] === count));
}

function matchesSaved(metrics: NativeAiMatchMetrics, expected: Observed): boolean {
  if (metrics.schemaVersion !== expected.schemaVersion || metrics.mode !== expected.mode ||
    expected.matchCount !== 1) return false;
  for (const field of ['total', 'fallback', 'invalid', 'no_decision', 'accepted'] as const) {
    if (metrics[field] !== expected.aggregate[field]) return false;
  }
  return sameBuckets(metrics.commands, expected.commands) && sameBuckets(metrics.skills, expected.skills);
}

function checkExpected(expected: Observed): void {
  if (!expected || !expected.aggregate || !expected.commands || !expected.skills ||
    !Number.isSafeInteger(expected.aggregate.total) || expected.aggregate.total < 0 ||
    expected.aggregate.accepted + expected.aggregate.fallback !== expected.aggregate.total) {
    throw new Error('saved observed metadata is incomplete');
  }
}

export function reconcileObservedReasonProvenance(nativeLog: string, expected: Observed) {
  checkExpected(expected);
  const lines = nativeLog.split(/\r?\n/u);
  const summaries: { line: number; metrics: NativeAiMatchMetrics | null; possibleTarget: boolean }[] = [];
  for (let i = 0; i < lines.length; i++) {
    const index = lines[i].indexOf('[AI_MATCH_METRICS]');
    if (index < 0) continue;
    // Historical unrelated rooms can contain old, numeric-only skill labels.
    // Count every summary as a boundary, and apply the strict bounded parser
    // only to summaries matching the saved match's independent counters.
    const line = lines[i].slice(index);
    const header = line.match(/^\[AI_MATCH_METRICS\] schema=(\d+) room=(\d+) mode=([A-Za-z0-9_-]+) total=(\d+) fallback=(\d+) invalid=(\d+) no_decision=(\d+) accepted=(\d+)\s/u);
    const possibleTarget = !!header && header[3] === expected.mode &&
      (['total', 'fallback', 'invalid', 'no_decision', 'accepted'] as const)
        .every((field, n) => Number(header[n + 4]) === expected.aggregate[field]);
    const metrics = possibleTarget ? parseAiMatchMetricsLine(line) : null;
    if (possibleTarget && !metrics) throw new Error('malformed selected native aggregate summary');
    summaries.push({ line: i, metrics, possibleTarget });
  }
  const matching = summaries.filter(({ possibleTarget }) => possibleTarget);
  if (matching.length !== 1) throw new Error('saved observed match must have exactly one matching native summary');
  const selected = matching[0];
  if (!selected.metrics || !matchesSaved(selected.metrics, expected)) {
    throw new Error('selected native summary disagrees with saved per-command or per-skill metadata');
  }
  const selectedIndex = summaries.indexOf(selected);
  const from = selectedIndex > 0 ? summaries[selectedIndex - 1].line + 1 : 0;
  const commandCounts: Record<string, { reasons: Counts; invalidDetails: Counts }> = Object.create(null);
  for (const command of Object.keys(expected.commands)) {
    commandCounts[command] = { reasons: Object.create(null), invalidDetails: Object.create(null) };
  }
  const reasonTotals: Counts = Object.create(null);
  const invalidDetailTotals: Counts = Object.create(null);
  let fallbacks = 0;
  for (let i = from; i < selected.line; i++) {
    const raw = lines[i];
    const marker = raw.indexOf('[AI] fallback');
    if (marker < 0) continue;
    // Intentionally never include the rejected line or any of its fields in errors.
    const match = raw.slice(marker).match(FALLBACK);
    if (!match) throw new Error('unparseable native fallback metadata');
    const [, command, reason, detail] = match;
    if (!Object.hasOwn(commandCounts, command) || !SAFE_FALLBACK_REASONS.has(reason) ||
      (reason === 'illegal_reply' ? !detail || !SAFE_INVALID_DETAILS.has(detail) : detail !== undefined) ||
      reason === 'other') {
      throw new Error('unknown or ambiguous native fallback category');
    }
    increment(commandCounts[command].reasons, reason);
    increment(reasonTotals, reason);
    if (detail) {
      increment(commandCounts[command].invalidDetails, detail);
      increment(invalidDetailTotals, detail);
    }
    fallbacks = plus(fallbacks, 1);
  }
  if (fallbacks !== expected.aggregate.fallback) throw new Error('native fallback lines do not reconcile with saved aggregate');

  let invalid = 0; let noDecision = 0;
  const byCommand: Record<string, {
    total: number; fallback: number; invalid: number; no_decision: number;
    reasons: Counts; invalidDetails: Counts;
  }> = Object.create(null);
  for (const command of Object.keys(expected.commands).sort()) {
    const bucket = expected.commands[command];
    const { reasons, invalidDetails } = commandCounts[command];
    const sum = (values: number[]) => values.reduce(plus, 0);
    const observedFallback = sum(Object.values(reasons));
    const observedInvalid = sum([...INVALID].map((reason) => reasons[reason] ?? 0));
    const observedNoDecision = sum([...NO_DECISION].map((reason) => reasons[reason] ?? 0));
    if (observedFallback !== requireCounter(bucket.fallback, 'command fallback') ||
      observedInvalid !== requireCounter(bucket.invalid, 'command invalid') ||
      observedNoDecision !== requireCounter(bucket.no_decision, 'command no_decision') ||
      sum(Object.values(invalidDetails)) !== (reasons.illegal_reply ?? 0)) {
      throw new Error('native per-command fallback reason classes do not reconcile');
    }
    invalid = plus(invalid, observedInvalid);
    noDecision = plus(noDecision, observedNoDecision);
    byCommand[command] = {
      total: requireCounter(bucket.total, 'command total'), fallback: observedFallback,
      invalid: observedInvalid, no_decision: observedNoDecision,
      reasons: sorted(reasons), invalidDetails: sorted(invalidDetails),
    };
  }
  if (invalid !== expected.aggregate.invalid || noDecision !== expected.aggregate.no_decision ||
    Object.values(byCommand).reduce((sum, bucket) => plus(sum, bucket.total), 0) !== expected.aggregate.total ||
    expected.aggregate.fallback - invalid - noDecision !==
      (reasonTotals.unsupported_command ?? 0) + (reasonTotals.handler_error ?? 0) +
      (reasonTotals.ai_exception ?? 0) + (reasonTotals.unexpected_notready ?? 0)) {
    throw new Error('native fallback classes do not reconcile with saved match');
  }
  return {
    schemaVersion: 1, kind: 'prompt4_observed_native_reason_provenance',
    source: 'isolated original native QA log; metadata-only, no new native execution',
    sourceMatchWindow: { startLine: from + 1, endLine: selected.line + 1,
      matchingSummaryIndex: selectedIndex, summariesInLog: summaries.length },
    aggregate: { ...expected.aggregate, otherFallback: expected.aggregate.fallback - invalid - noDecision },
    reasons: sorted(reasonTotals), invalidDetails: sorted(invalidDetailTotals),
    commands: byCommand,
    reconciliation: { uniqueMatchedSummary: true, fallbackLines: fallbacks,
      perCommandFallbackInvalidNoDecision: true, aggregateCounters: true },
    causalAttributionAvailable: false, matchedRequestState: false,
    semanticStrategyRootCauseEstablished: false,
    limitations: [
      'Legacy [AI] fallback lines contain command/reason/detail but no room ID; isolation assumes sequential rooms between native match summaries.',
      'feasibility_rejected is a validator outcome; it does not identify the originating strategy or semantic legality defect.',
      'PlayCard invalid_strategy_reply is a reply-shape category and does not identify a specific skill or card.',
      'One observed candidate match cannot establish 18-skill opportunity coverage, paired attribution, target/resource value or win-rate.',
    ],
  };
}

function main(): void {
  const [, , nativeLogPath, savedMetricsPath, outputPath] = process.argv;
  if (!nativeLogPath || !savedMetricsPath) {
    throw new Error('usage: observed-reason-provenance.ts <native-log> <observed-metrics-json> [output-json]');
  }
  const expected = JSON.parse(fs.readFileSync(savedMetricsPath, 'utf8')) as Observed;
  const report = reconcileObservedReasonProvenance(fs.readFileSync(nativeLogPath, 'utf8'), expected);
  const serialized = `${JSON.stringify(report, null, 2)}\n`;
  if (outputPath) fs.writeFileSync(outputPath, serialized, { mode: 0o600 });
  else process.stdout.write(serialized);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
