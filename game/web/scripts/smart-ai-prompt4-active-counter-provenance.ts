/**
 * Reconcile the historical Prompt 4 active-command counters against their
 * original native [AI_MATCH_METRICS] lines. Never export source logs or IDs.
 *
 * The native command tuple is (total, fallback, invalid, no_decision), while
 * the saved exploratory artifact incorrectly labeled the second item
 * `accepted`, and shifted the next two labels as well.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseAiMatchMetricsLine } from './smart-ai-prompt4-match-metrics';

type Counts = { total: number; accepted: number; fallback: number; invalid: number; noDecision: number };
type HistoricalEvidence = { runtimeVariants: Record<'preFix' | 'fixed', {
  match: Counts & { askForUseActiveSkill: Counts };
}> };

function reconcileBranch(saved: Counts & { askForUseActiveSkill: Counts }, nativeLog: string) {
  // Legacy skill names are not necessarily valid under the current parser.
  // This audit only needs the command and aggregate fields, so redact the
  // historical skill field before strict parsing. Never export source logs.
  const records = nativeLog.split(/\r?\n/u)
    .filter((line) => line.includes('[AI_MATCH_METRICS]'))
    .map((line) => parseAiMatchMetricsLine(line.replace(/skills=\S+(?=\s+commands=)/u, 'skills=-')))
    .filter((record) => record !== null);
  const matching = records.filter((record) =>
    record.mode === 'new_heg_mode' && record.total === saved.total &&
    record.accepted === saved.accepted && record.fallback === saved.fallback &&
    record.invalid === saved.invalid && record.no_decision === saved.noDecision);
  if (matching.length !== 1) throw new Error('native aggregate identity missing or ambiguous');

  const active = matching[0].commands.AskForUseActiveSkill;
  if (!active) throw new Error('native active command bucket missing');
  if (active.invalid + active.no_decision > active.fallback || active.fallback > active.total) {
    throw new Error('native active command counters inconsistent');
  }
  const legacy = saved.askForUseActiveSkill;
  if (legacy.total !== active.total || legacy.accepted !== active.fallback ||
      legacy.fallback !== active.invalid || legacy.invalid !== active.no_decision ||
      legacy.noDecision !== active.no_decision) {
    throw new Error('historical active fields do not match native positional mapping');
  }
  return {
    originalArtifact: { total: legacy.total, accepted: legacy.accepted,
      fallback: legacy.fallback, invalid: legacy.invalid, noDecision: legacy.noDecision },
    nativeCommand: { total: active.total, acceptedDerived: active.total - active.fallback,
      fallback: active.fallback, invalid: active.invalid, noDecision: active.no_decision },
    sourceAggregateMatched: true,
    historicalLabelShiftVerified: true,
  };
}

export function reconcilePrompt4ActiveCounters(saved: HistoricalEvidence, preFixLog: string, fixedLog: string) {
  return {
    schemaVersion: 1,
    kind: 'prompt4_native_active_counter_provenance',
    scope: 'read-only native match-metric line reconciliation; no native QA executed',
    nativeCommandSchema: ['total', 'fallback', 'invalid', 'no_decision'],
    historicalArtifactStatus: 'preserved_unmodified_with_mislabeled_command_fields',
    preFix: reconcileBranch(saved.runtimeVariants.preFix.match, preFixLog),
    fixed: reconcileBranch(saved.runtimeVariants.fixed.match, fixedLog),
    nativeMatchedRequestState: false,
    nativeSkillOpportunityDenominatorAvailable: false,
    nativeTargetResourceQualityAvailable: false,
    gate: 'REQUEST_SAFETY_OPEN',
    limitations: [
      'Accepted by command is derived as total minus fallback; there is no native command-level accepted field.',
      'Reconciliation establishes historical field provenance, not a new game run or equivalent input state.',
      'The pre-fix and fixed runs used different general pairs and gameplay trajectories; no causal delta is established.',
    ],
  } as const;
}

function main(args: string[]) {
  const [preFixPath, fixedPath, outputPath] = args;
  if (!preFixPath || !fixedPath) {
    throw new Error('usage: smart-ai-prompt4-active-counter-provenance.ts <pre-fix-native-log> <fixed-native-log> [sanitized-output.json]');
  }
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
  const evidence = JSON.parse(fs.readFileSync(path.join(root, 'docs/web-client',
    'SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json'), 'utf8')) as HistoricalEvidence;
  const result = reconcilePrompt4ActiveCounters(evidence, fs.readFileSync(preFixPath, 'utf8'),
    fs.readFileSync(fixedPath, 'utf8'));
  const output = `${JSON.stringify(result, null, 2)}\n`;
  if (outputPath) fs.writeFileSync(outputPath, output, { mode: 0o600 });
  else process.stdout.write(output);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main(process.argv.slice(2));
