import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { buildPrompt4RequestSafetyFollowup } from './smart-ai-prompt4-request-safety-followup';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const read = (name: string) => JSON.parse(fs.readFileSync(path.join(root, 'docs/web-client', name), 'utf8'));
const inputs = () => [
  read('SMARTAI_PROMPT4_CHOOSER_NATIVE_MATCHED_2026-10-21.json'),
  read('SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json'),
  read('SMARTAI_PROMPT4_NATIVE_AB_2026-10-21.json'),
  read('SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json'),
  read('SMARTAI_PROMPT4_ACTIVE_COUNTER_RECONCILIATION_2026-10-21.json'),
] as const;

test('reconciles the six real matched chooser cases and the independent observed aggregate', () => {
  const result = buildPrompt4RequestSafetyFollowup(...inputs());
  assert.equal(result.boundedMatchedChooser.status, 'PASS');
  assert.equal(result.boundedMatchedChooser.comparedCases, 6);
  assert.deepEqual(result.boundedMatchedChooser.mismatchedCases, []);
  assert.deepEqual(result.boundedMatchedChooser.baseline, result.boundedMatchedChooser.candidate);
  assert.deepEqual(result.boundedMatchedChooser.baseline, {
    opportunities: 6, accepted: 6, acted: 3, optionalAcceptedNoAction: 3,
    fallback: 0, invalid: 0, errors: 0,
  });
  assert.deepEqual(result.observedCandidateMatch.aggregate, {
    total: 247, accepted: 142, fallback: 105, invalid: 7, noDecision: 95, otherFallback: 3,
  });
  assert.deepEqual(result.observedCandidateMatch.invalidByCommand,
    { AskForUseActiveSkill: 2, PlayCard: 5 });
  assert.deepEqual(result.observedCandidateMatch.otherFallbackByCommand, { EmptyRequest: 3 });
  assert.equal(result.earlierUnmatchedNativeAb.causalAttributionAvailable, false);
  assert.equal(result.gate.fullPrompt4, 'REQUEST_SAFETY_OPEN');
  assert.ok(!JSON.stringify(result).includes('inputFingerprint'));
});

test('cannot claim equivalence when actual paired case hash or identity differs', () => {
  const data = structuredClone(inputs());
  data[0].variants.candidate.cases[0].inputFingerprint = 'eeeeeeee';
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...data), /paired hash\/case 1/u);
  const identity = structuredClone(inputs());
  identity[0].variants.candidate.packageSha256 = 'different-package';
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...identity), /package identity/u);
  const coverage = structuredClone(inputs());
  coverage[0].comparison.bySkill.choose_cards_skill.candidate.acted = 2;
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...coverage), /candidate choose_cards_skill/u);
});

test('rejects tainted request counters or incomplete observed command coverage', () => {
  const counters = structuredClone(inputs());
  counters[0].variants.baseline.chooser.invalid = 1;
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...counters), /baseline chooser partition/u);
  const observed = structuredClone(inputs());
  observed[3].commands.PlayCard.fallback -= 1;
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...observed), /historical metrics consistency/u);
  const provenance = structuredClone(inputs());
  provenance[4].fixed.nativeCommand.fallback = 0;
  assert.throws(() => buildPrompt4RequestSafetyFollowup(...provenance), /historical metrics consistency/u);
});
