import assert from 'node:assert/strict';
import { test } from 'node:test';
import { runPrompt4ChooserPairedFixture } from './smart-ai-prompt4-chooser-paired';

test('replays identical bounded chooser input through archived pre-fix and fixed Lua strategies', async () => {
  const report = await runPrompt4ChooserPairedFixture();
  assert.equal(report.total, 12);
  assert.equal(report.baselineInfeasible, 11);
  assert.equal(report.fixedInfeasible, 0);
  assert.equal(report.improved, 11);
  assert.equal(report.regressions, 0);
  assert.deepEqual(report.cases, {
    cards_empty: { baseline: 'infeasible', fixed: 'fallback' },
    cards_invalid: { baseline: 'infeasible', fixed: 'fallback' },
    cards_duplicate: { baseline: 'infeasible', fixed: 'fallback' },
    cards_valid: { baseline: 'legal', fixed: 'legal' },
    combined_card_required: { baseline: 'infeasible', fixed: 'legal' },
    combined_disabled_target: { baseline: 'infeasible', fixed: 'fallback' },
    combined_duplicate_targets: { baseline: 'infeasible', fixed: 'fallback' },
    combined_empty: { baseline: 'infeasible', fixed: 'fallback' },
    combined_valid: { baseline: 'infeasible', fixed: 'legal' },
    players_card_required: { baseline: 'infeasible', fixed: 'legal' },
    players_disabled_target: { baseline: 'infeasible', fixed: 'fallback' },
    players_empty: { baseline: 'infeasible', fixed: 'fallback' },
  });
  assert.equal(report.nativeRequestStateMatched, false);
  assert.equal(report.skillOpportunityDenominatorAvailable, false);
  assert.equal(report.winRateAvailable, false);
  assert.ok(!JSON.stringify(report).includes('101'));
  assert.ok(!JSON.stringify(report).includes('999'));
});
