import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { reconcilePrompt4ActiveCounters } from './smart-ai-prompt4-active-counter-provenance';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const evidence = JSON.parse(fs.readFileSync(path.join(root, 'docs/web-client',
  'SMARTAI_PROMPT4_NATIVE_REQUEST_SAFETY_2026-10-21.json'), 'utf8'));

function line(total: number, fallback: number, invalid: number, noDecision: number,
  active: [number, number, number, number]) {
  const [requests, failed, illegal, undecided] = active;
  return `[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=${total} fallback=${fallback} invalid=${invalid} no_decision=${noDecision} accepted=${total - fallback} skills=- commands=AskForUseActiveSkill:${active.join(':')},PlayCard:${total - requests}:${fallback - failed}:${invalid - illegal}:${noDecision - undecided}`;
}

const pre = line(156, 88, 41, 47, [31, 23, 16, 7]);
const fixed = line(95, 49, 12, 35, [6, 1, 1, 0]);

test('reconciles misaligned legacy fields to actual native command tuple', () => {
  const review = reconcilePrompt4ActiveCounters(evidence, pre, fixed);
  assert.deepEqual(review.preFix.nativeCommand,
    { total: 31, acceptedDerived: 8, fallback: 23, invalid: 16, noDecision: 7 });
  assert.deepEqual(review.fixed.nativeCommand,
    { total: 6, acceptedDerived: 5, fallback: 1, invalid: 1, noDecision: 0 });
  assert.equal(review.preFix.originalArtifact.accepted, 23);
  assert.equal(review.fixed.historicalLabelShiftVerified, true);
  assert.equal(review.nativeMatchedRequestState, false);
  assert.equal(review.gate, 'REQUEST_SAFETY_OPEN');
  assert.ok(!JSON.stringify(review).includes('AskForUseActiveSkill:31:23:16:7'));
});

test('rejects aggregate mismatch, duplicate matches and wrong positional history', () => {
  assert.throws(() => reconcilePrompt4ActiveCounters(evidence, fixed, fixed), /identity/u);
  assert.throws(() => reconcilePrompt4ActiveCounters(evidence, `${pre}\n${pre}`, fixed), /ambiguous/u);
  const edited = structuredClone(evidence);
  edited.runtimeVariants.preFix.match.askForUseActiveSkill.accepted = 8;
  assert.throws(() => reconcilePrompt4ActiveCounters(edited, pre, fixed), /positional mapping/u);
  assert.throws(() => reconcilePrompt4ActiveCounters(evidence,
    pre.replace('AskForUseActiveSkill:31:23:16:7', 'AskForUseActiveSkill:31:23:17:7'), fixed),
  /counters|positional mapping|disjoint/u);
});
