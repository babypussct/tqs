import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { reviewPrompt4NativeSafety } from './smart-ai-prompt4-request-safety-review';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const read = (name: string) => JSON.parse(fs.readFileSync(
  path.join(root, 'docs/web-client', name), 'utf8'));
const evidence = () => ({
  probe: read('SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json'),
  ab: read('SMARTAI_PROMPT4_NATIVE_AB_2026-10-21.json'),
  observed: read('SMARTAI_PROMPT4_OBSERVED_MATCH_METRICS_2026-10-21.json'),
  reconciled: read('SMARTAI_PROMPT4_ACTIVE_COUNTER_RECONCILIATION_2026-10-21.json'),
});

test('legacy active accepted inconsistency remains visible rather than claimed as a successful patch', () => {
  const { probe, ab, observed, reconciled } = evidence();
  const review = reviewPrompt4NativeSafety(probe, ab, observed, reconciled);
  assert.equal(review.gate.status, 'REQUEST_SAFETY_OPEN');
  assert.equal(review.gate.savedAggregateCountersConsistent, true);
  assert.equal(review.gate.activeSkillAcceptedCounterConsistent, false);
  assert.equal(review.gate.legacyActiveAcceptedUsable, false);
  assert.deepEqual(review.exploratoryProbe.activeSkillRequest.preFix.issues, ['accepted_plus_fallback_mismatch']);
  assert.deepEqual(review.exploratoryProbe.activeSkillRequest.fixed.issues, ['accepted_plus_fallback_mismatch']);
  assert.equal(review.exploratoryProbe.activeSkillRequest.preFix.acceptedImpliedByFallback, null);
  assert.equal(review.exploratoryProbe.activeSkillRequest.fixed.acceptedImpliedByFallback, null);
  assert.equal(review.gate.nativeActiveCountersReconciled, true);
  assert.deepEqual(review.exploratoryProbe.activeSkillRequest.correctedNative?.preFix,
    { total: 31, acceptedDerived: 8, fallback: 23, invalid: 16, noDecision: 7 });
  assert.equal(review.earlierNativeAb.delta.invalid, 69);
  assert.equal(review.observedCandidateMatch.commandCoverageConsistent, true);
  assert.deepEqual(review.observedCandidateMatch.invalidContributionsByCommand,
    { AskForUseActiveSkill: 2, PlayCard: 5 });
  assert.ok(!JSON.stringify(review).includes('cardId'));
});

test('rejects malformed counters, privacy-unsafe command labels, and incomplete command coverage', () => {
  const { probe, ab, observed } = evidence();
  assert.throws(() => reviewPrompt4NativeSafety(probe, ab, {
    ...observed, commands: { ...observed.commands, 'target:123': observed.commands.PlayCard },
  }), /unsafe command label/u);
  assert.equal(reviewPrompt4NativeSafety(probe, ab, {
    ...observed, commands: { ...observed.commands, PlayCard: {
      ...observed.commands.PlayCard, total: observed.commands.PlayCard.total - 1,
    } },
  }).gate.savedAggregateCountersConsistent, false);
  assert.throws(() => reviewPrompt4NativeSafety(probe, ab, {
    ...observed, commands: { ...observed.commands, PlayCard: {
      ...observed.commands.PlayCard, invalid: -1,
    } },
  }), /invalid counter/u);
});

test('does not accept tampered or absent native counter provenance', () => {
  const { probe, ab, observed, reconciled } = evidence();
  const without = reviewPrompt4NativeSafety(probe, ab, observed);
  assert.equal(without.gate.nativeActiveCountersReconciled, false);
  assert.equal(without.exploratoryProbe.activeSkillRequest.correctedNative, null);
  const tampered = structuredClone(reconciled);
  tampered.preFix.nativeCommand.acceptedDerived = 15;
  const review = reviewPrompt4NativeSafety(probe, ab, observed, tampered);
  assert.equal(review.gate.nativeActiveCountersReconciled, false);
  assert.equal(review.gate.status, 'REQUEST_SAFETY_OPEN');
});
