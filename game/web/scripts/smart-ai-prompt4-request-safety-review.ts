/**
 * Read-only review of saved, metadata-only Prompt 4 native QA evidence.
 * Never infer causal effects from two different gameplay trajectories.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

type Counts = { total: number; accepted: number; fallback: number; invalid: number; noDecision: number };
type ProbeBranch = { match: Counts & { askForUseActiveSkill: Counts }; pairDecision: { records: number; accepted: number; fallback: number } };
type ProbeEvidence = { runtimeVariants: { preFix: ProbeBranch; fixed: ProbeBranch } };
type AbEvidence = { nativeAiMetrics: {
  baseline: Omit<Counts, 'noDecision'> & { noDecision: number };
  candidate: Omit<Counts, 'noDecision'> & { noDecision: number };
} };
type ObservedEvidence = { aggregate: { total: number; accepted: number; fallback: number; invalid: number; no_decision: number };
  commands: Record<string, { total: number; fallback: number; invalid: number; no_decision: number }> };
type ReconciledCommand = { total: number; acceptedDerived: number; fallback: number; invalid: number; noDecision: number };
type ActiveCounterProvenance = {
  gate: string;
  historicalArtifactStatus: string;
  preFix: { nativeCommand: ReconciledCommand; sourceAggregateMatched: boolean; historicalLabelShiftVerified: boolean };
  fixed: { nativeCommand: ReconciledCommand; sourceAggregateMatched: boolean; historicalLabelShiftVerified: boolean };
};

function count(value: number, label: string): number {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(`${label}: invalid counter`);
  return value;
}

function checkCounts(value: Counts, label: string): string[] {
  const { total, accepted, fallback, invalid, noDecision } = value;
  for (const field of ['total', 'accepted', 'fallback', 'invalid', 'noDecision'] as const) {
    count(value[field], `${label}.${field}`);
  }
  const issues = [];
  if (accepted + fallback !== total) issues.push('accepted_plus_fallback_mismatch');
  if (invalid + noDecision > fallback) issues.push('invalid_no_decision_exceed_fallback');
  if (fallback > total) issues.push('fallback_exceeds_total');
  return issues;
}

function inspectBranch(value: Counts, label: string) {
  const issues = checkCounts(value, label);
  return {
    total: value.total,
    recordedAccepted: value.accepted,
    acceptedImpliedByFallback: value.total - value.fallback,
    fallback: value.fallback,
    invalid: value.invalid,
    noDecision: value.noDecision,
    otherFallback: value.fallback - value.invalid - value.noDecision,
    counterConsistent: issues.length === 0,
    issues,
  };
}

export function reviewPrompt4NativeSafety(probe: ProbeEvidence, ab: AbEvidence, observed: ObservedEvidence,
  provenance?: ActiveCounterProvenance) {
  const pre = inspectBranch(probe.runtimeVariants.preFix.match, 'preFix.match');
  const fixed = inspectBranch(probe.runtimeVariants.fixed.match, 'fixed.match');
  const preActive = inspectBranch(probe.runtimeVariants.preFix.match.askForUseActiveSkill, 'preFix.active');
  const fixedActive = inspectBranch(probe.runtimeVariants.fixed.match.askForUseActiveSkill, 'fixed.active');
  const base = inspectBranch(ab.nativeAiMetrics.baseline, 'ab.baseline');
  const cand = inspectBranch(ab.nativeAiMetrics.candidate, 'ab.candidate');
  const sample = inspectBranch({ ...observed.aggregate, noDecision: observed.aggregate.no_decision }, 'observed');
  const commands = Object.fromEntries(Object.entries(observed.commands).sort(([a], [b]) => a.localeCompare(b)).map(
    ([name, bucket]) => {
      if (!/^[A-Za-z_][A-Za-z0-9_]{0,63}$/u.test(name)) throw new Error('unsafe command label');
      return [name, inspectBranch({ ...bucket, accepted: bucket.total - bucket.fallback,
        noDecision: bucket.no_decision }, `command.${name}`)];
    },
  ));
  const fields = ['total', 'fallback', 'invalid', 'no_decision'] as const;
  const coverage = fields.every((field) => Object.values(observed.commands)
    .reduce((sum, value) => sum + count(value[field], `command.${field}`), 0) === observed.aggregate[field]);
  const consistent = [pre, fixed, base, cand, sample, ...Object.values(commands)].every((x) => x.counterConsistent);
  const activeConsistent = preActive.counterConsistent && fixedActive.counterConsistent;
  const checkedNative = provenance && provenance.historicalArtifactStatus ===
    'preserved_unmodified_with_mislabeled_command_fields' && provenance.gate === 'REQUEST_SAFETY_OPEN' &&
    (['preFix', 'fixed'] as const).every((branch) => {
      const record = provenance[branch];
      const native = record.nativeCommand;
      const historical = probe.runtimeVariants[branch].match.askForUseActiveSkill;
      return record.sourceAggregateMatched && record.historicalLabelShiftVerified &&
        native.total === historical.total && native.fallback === historical.accepted &&
        native.invalid === historical.fallback && native.noDecision === historical.invalid &&
        native.noDecision === historical.noDecision && native.acceptedDerived === native.total - native.fallback &&
        native.invalid + native.noDecision <= native.fallback && native.fallback <= native.total;
    });
  return {
    schemaVersion: 1,
    kind: 'prompt4_native_saved_evidence_safety_review',
    scope: 'sanitized saved evidence only; no new native execution',
    exploratoryProbe: { preFix: pre, fixed,
      activeSkillRequest: {
        preFix: { ...preActive, acceptedImpliedByFallback: null },
        fixed: { ...fixedActive, acceptedImpliedByFallback: null },
        correctedNative: checkedNative ? {
          preFix: provenance!.preFix.nativeCommand, fixed: provenance!.fixed.nativeCommand,
        } : null,
      },
      matchedRequestState: false, causalAttributionAvailable: false },
    earlierNativeAb: { baseline: base, candidate: cand, matchedRequestState: false,
      delta: { total: cand.total - base.total, fallback: cand.fallback - base.fallback,
        invalid: cand.invalid - base.invalid, noDecision: cand.noDecision - base.noDecision } },
    observedCandidateMatch: { aggregate: sample, commands, commandCoverageConsistent: coverage,
      invalidContributionsByCommand: Object.fromEntries(Object.entries(commands)
        .filter(([, value]) => value.invalid > 0).map(([name, value]) => [name, value.invalid])) },
    gate: {
      savedAggregateCountersConsistent: consistent && coverage,
      activeSkillAcceptedCounterConsistent: activeConsistent,
      legacyActiveAcceptedUsable: activeConsistent,
      nativeActiveCountersReconciled: checkedNative === true,
      matchedBaselineFixedReplayAvailable: false,
      nativeSkillOpportunityDenominatorAvailable: false,
      nativeTargetResourceQualityAvailable: false,
      status: 'REQUEST_SAFETY_OPEN',
    },
    limitations: [
      'Historical active command fields were positionally mislabeled; arithmetic using their saved fallback field is invalid. Native accepted is derived only from verified total minus native fallback.',
      'A corrected native command tuple can establish counter provenance but does not provide request-state matching or causal evidence.',
      'Pre-fix and fixed trajectories differ in pair selection and gameplay state; changes in rates or totals cannot be attributed to the chooser patch.',
      'Earlier A/B aggregate mixes many commands and lacks matched request-state and per-command reason detail in its saved artifact.',
      'An observed request is not a denominator of every legal opportunity to activate a skill.',
      'No raw private payloads, card/target identifiers or native logs were used or retained.',
    ],
  };
}

function main(): void {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
  const read = (name: string) => JSON.parse(fs.readFileSync(path.join(root, 'docs/web-client', name), 'utf8'));
  const result = reviewPrompt4NativeSafety(
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
