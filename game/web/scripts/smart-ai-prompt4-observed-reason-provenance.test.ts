import assert from 'node:assert/strict';
import { test } from 'node:test';
import { reconcileObservedReasonProvenance } from './smart-ai-prompt4-observed-reason-provenance';

const observed = {
  schemaVersion: 1, mode: 'new_heg_mode', matchCount: 1,
  aggregate: { total: 5, accepted: 1, fallback: 4, invalid: 2, no_decision: 1 },
  skills: {},
  commands: {
    PlayCard: { total: 2, fallback: 2, invalid: 1, no_decision: 1 },
    AskForUseActiveSkill: { total: 1, fallback: 1, invalid: 1, no_decision: 0 },
    EmptyRequest: { total: 1, fallback: 1, invalid: 0, no_decision: 0 },
    CustomDialog: { total: 1, fallback: 0, invalid: 0, no_decision: 0 },
  },
};
const summary = '[AI_MATCH_METRICS] schema=1 room=3 mode=new_heg_mode total=5 fallback=4 invalid=2 no_decision=1 accepted=1 skills=- commands=AskForUseActiveSkill:1:1:1:0,CustomDialog:1:0:0:0,EmptyRequest:1:1:0:0,PlayCard:2:2:1:1';
const native = [
  'sensitive fake prior log entry',
  '[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=- commands=PlayCard:1:0:0:0',
  '[AI] fallback command=PlayCard reason=invalid_strategy_reply elapsed=0.001ms',
  '[AI] fallback command=PlayCard reason=no_decision elapsed=0.002ms',
  '[AI] fallback command=AskForUseActiveSkill reason=illegal_reply detail=feasibility_rejected elapsed=0.003ms',
  '[AI] fallback command=EmptyRequest reason=unsupported_command elapsed=0.004ms',
  summary,
  'sensitive fake post-summary log entry',
].join('\n');

test('reconciles selected old native room with exact command, reason and invalid-detail counts', () => {
  const result = reconcileObservedReasonProvenance(native, observed);
  assert.equal(result.reconciliation.fallbackLines, 4);
  assert.deepEqual(result.sourceMatchWindow, { startLine: 3, endLine: 7, matchingSummaryIndex: 1, summariesInLog: 2 });
  assert.equal(result.commands.PlayCard.invalid, 1);
  assert.equal(result.commands.AskForUseActiveSkill.invalidDetails.feasibility_rejected, 1);
  assert.equal(result.aggregate.otherFallback, 1);
  assert.equal(result.commands.EmptyRequest.reasons.unsupported_command, 1);
  assert.equal(result.causalAttributionAvailable, false);
  assert.ok(!JSON.stringify(result).includes('sensitive'));
});

test('rejects missing, malformed, duplicate and ambiguous native log evidence', () => {
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('reason=no_decision', 'reason=unknown'), observed), /unknown or ambiguous/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('reason=no_decision', 'reason=other'), observed), /unknown or ambiguous/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('elapsed=0.004ms', 'secret=abc elapsed=0.004ms'), observed), /unparseable/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('detail=feasibility_rejected ', ''), observed), /unknown or ambiguous/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('detail=feasibility_rejected', 'detail=private_hand'), observed), /unknown or ambiguous/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('reason=no_decision', 'reason=invalid_strategy_reply'), observed), /reason classes/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('reason=unsupported_command', 'reason=no_strategy'), observed), /reason classes/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('[AI] fallback command=EmptyRequest reason=unsupported_command elapsed=0.004ms', ''), observed), /fallback lines/u);
  assert.throws(() => reconcileObservedReasonProvenance(`${native}\n${summary}`, observed), /exactly one/u);
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('total=5 fallback=4 invalid=2', 'total=5 fallback=3 invalid=2'), observed), /exactly one|accepted \+ fallback/u);
});

test('rejects metadata mismatch and never returns raw log material in errors', () => {
  const mismatch = { ...observed, commands: { ...observed.commands, PlayCard: { ...observed.commands.PlayCard, invalid: 0 } } };
  assert.throws(() => reconcileObservedReasonProvenance(native, mismatch), /disagrees with saved/u);
  const secret = 'private_card_identifier_in_native_log';
  assert.throws(() => reconcileObservedReasonProvenance(native.replace('reason=no_decision', `reason=${secret}`), observed),
    (error: Error) => !error.message.includes(secret));
  assert.throws(() => reconcileObservedReasonProvenance(native, { ...observed, matchCount: 2 }), /disagrees with saved/u);
});

test('uses legacy aggregate records as boundaries without interpreting older invalid skill labels', () => {
  const legacy = '[AI_MATCH_METRICS] schema=1 room=8 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=123:1:1:0:0:0 commands=PlayCard:1:0:0:0';
  const withLegacy = native.replace('skills=- commands=PlayCard:1:0:0:0', 'skills=123:1:1:0:0:0 commands=PlayCard:1:0:0:0');
  assert.equal(reconcileObservedReasonProvenance(withLegacy, observed).reconciliation.fallbackLines, 4);
  const injected = native.replace(summary, `${legacy}\n${summary}`);
  assert.throws(() => reconcileObservedReasonProvenance(injected, observed), /fallback lines/u,
    'a boundary immediately before the target cannot absorb earlier fallbacks');
});
