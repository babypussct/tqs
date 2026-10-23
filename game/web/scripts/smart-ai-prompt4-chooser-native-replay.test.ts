import assert from 'node:assert/strict';
import { test } from 'node:test';
import { compareChooserTraceLogs, parseChooserTraceLog } from './smart-ai-prompt4-chooser-native-replay';

const names = ['choose_players_skill', 'choose_cards_skill', 'ex__choose_skill'];

function fixture(options: { seed?: number; mismatched?: number; optionalEmpty?: boolean; fallback?: boolean; corrupt?: boolean } = {}) {
  const seed = options.seed ?? 1780420132;
  const revisions = `scenario=chooser-trace seed=${seed} revision=qa_rev_1`;
  const entries = Array.from({ length: 6 }, (_, index) => {
    const seq = index + 1;
    const skill = names[index % 3];
    const variant = index < 3 ? 'mandatory' : 'optional';
    const optionalEmpty = !!options.optionalEmpty && seq === 6;
    const fallback = !!options.fallback && seq === 6;
    const selectedCards = skill === 'choose_players_skill' ? 0 : 1;
    const selectedTargets = skill === 'choose_cards_skill' ? 0 : 1;
    return `[tqs_chooser_trace] decision ${revisions} seq=${seq} skill=${skill} variant=${variant}` +
      ` input=${options.mismatched === seq ? 'a0000000' : '12345678'} offer=abcdef01 opportunity=1` +
      ` offered_cards=${selectedCards} offered_targets=${selectedTargets ? 3 : 0}` +
      ` accepted=${fallback ? 0 : 1} acted=${optionalEmpty || fallback ? 0 : 1}` +
      ` chosen_cards=${optionalEmpty || fallback ? 0 : selectedCards}` +
      ` chosen_targets=${optionalEmpty || fallback ? 0 : selectedTargets} invalid=0` +
      ` reason=${fallback ? 'no_decision' : 'accepted'} detail=none`;
  });
  const total = options.fallback ? 5 : 6;
  const missed = options.optionalEmpty || options.fallback ? 1 : 0;
  const summary = `[tqs_chooser_trace] summary ${revisions} decisions=6 opportunities=6` +
    ` accepted=${total} missed=${missed} fallback=${6 - total} invalid=0 errors=0` +
    ` pair=verified hands=verified fixture=${options.corrupt ? 'semantic_invalid' : 'semantic_v1'}`;
  return [summary, ...entries].join('\n');
}

test('native chooser parser accepts six fixture-verified decisions and per-skill legal opportunities', () => {
  const run = parseChooserTraceLog(fixture());
  assert.equal(run.decisions.length, 6);
  assert.equal(run.opportunities, 6);
  assert.equal(run.accepted, 6);
  const paired = compareChooserTraceLogs(fixture(), fixture());
  assert.equal(paired.status, 'MATCHED_BOUNDED_REQUESTS');
  assert.equal(paired.bySkill.ex__choose_skill.candidate.opportunities, 2);
  assert.equal(paired.nativeStrategicTargetQualityAvailable, false);
  assert.equal(paired.winRateAvailable, false);
});

test('accepted optional empty selection is a missed opportunity, not a fallback', () => {
  const comparison = compareChooserTraceLogs(fixture(), fixture({ optionalEmpty: true }));
  assert.equal(comparison.status, 'MATCHED_BOUNDED_REQUESTS');
  assert.deepEqual(comparison.bySkill.ex__choose_skill.candidate, {
    opportunities: 2, misses: 1, accepted: 2, acted: 1, fallback: 0, invalid: 0,
    acceptedNoAction: 1, voluntaryOptionalCancel: 1, optionalNoDecisionFallback: 0,
  });
});

test('optional no-decision fallback is a miss without claiming voluntary accepted cancellation', () => {
  const comparison = compareChooserTraceLogs(fixture(), fixture({ fallback: true }));
  assert.equal(comparison.status, 'MATCHED_BOUNDED_REQUESTS');
  assert.deepEqual(comparison.bySkill.ex__choose_skill.candidate, {
    opportunities: 2, misses: 1, accepted: 1, acted: 1, fallback: 1, invalid: 0,
    acceptedNoAction: 0, voluntaryOptionalCancel: 0, optionalNoDecisionFallback: 1,
  });
});

test('matched native chooser comparison is inconclusive for any observed request-state mismatch', () => {
  const comparison = compareChooserTraceLogs(fixture(), fixture({ mismatched: 4 }));
  assert.equal(comparison.status, 'INCONCLUSIVE');
  assert.deepEqual(comparison.mismatchedCases, [4]);
  assert.equal(compareChooserTraceLogs(fixture(), fixture({ seed: 1780420133 })).status, 'INCONCLUSIVE');
});

test('native chooser parser rejects incomplete, duplicated, unverified and inconsistent metadata', () => {
  assert.throws(() => parseChooserTraceLog(fixture({ corrupt: true })), /incomplete or unverified/u);
  assert.throws(() => parseChooserTraceLog(fixture().replace('invalid=0 errors=0', 'invalid=1 errors=0')),
    /counts disagree/u);
  assert.throws(() => parseChooserTraceLog(fixture().replace('seq=6 skill=', 'seq=5 skill=')),
    /case order/u);
  assert.throws(() => parseChooserTraceLog(fixture({ optionalEmpty: true }).replace('missed=1', 'missed=0')),
    /counts disagree/u);
  assert.throws(() => parseChooserTraceLog(fixture({ optionalEmpty: true }).replace('accepted=1 acted=0', 'accepted=1 acted=1')),
    /impossible chooser decision/u);
  assert.throws(() => parseChooserTraceLog(fixture().replace('accepted=1 acted=1', 'accepted=0 acted=1')),
    /impossible chooser decision/u);
  assert.throws(() => parseChooserTraceLog(fixture().replace('chosen_cards=1 chosen_targets=1', 'chosen_cards=1 chosen_targets=0')),
    /impossible chooser decision/u);
  assert.throws(() => parseChooserTraceLog(fixture().split('\n').slice(0, -1).join('\n')),
    /incomplete or unverified/u);
  assert.throws(() => parseChooserTraceLog(fixture() + '\n' + fixture()), /duplicate/u);
});
