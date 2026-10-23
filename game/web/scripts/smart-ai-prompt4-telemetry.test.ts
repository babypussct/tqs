import assert from 'node:assert/strict';
import test from 'node:test';
import { runPrompt4Telemetry } from './smart-ai-prompt4-telemetry';

const SKILLS = [
  'tianyi', 'shangyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi',
  'hs__longdan', 'hs__luanji', 'hs__wusheng', 'huoji', 'jijiu', 'kanpo',
  'aocai', 'beizhu', 'dimeng', 'choufa', 'cunsi', 'duanfa',
] as const;

test('Prompt 4 deterministic telemetry covers every selected skill with legal replies', async () => {
  const report = await runPrompt4Telemetry();

  assert.deepEqual(report.skills, SKILLS);
  assert.equal(report.mode, 'new_heg_mode');
  assert.equal(report.summary.scenarioCount, 20);
  assert.equal(report.summary.opportunityCount, 20);
  assert.equal(report.summary.candidateActivationCount, 20);
  assert.equal(report.summary.candidateMissCount, 0);
  assert.equal(report.summary.candidateLegalCount, 20);
  assert.equal(report.summary.baselineLegalCount, 20);
  assert.equal(report.summary.candidateTargetQualityRate, 1);
  assert.ok(report.summary.candidateResourceCost < report.summary.baselineResourceCost);
  assert.equal(report.summary.winRateAvailable, false);

  for (const skill of SKILLS) {
    const records = report.records.filter((record) => record.skill === skill);
    assert.ok(records.length >= 1, `missing deterministic record for ${skill}`);
    for (const record of records) {
      assert.equal(record.candidate.strategyRegistered, true, `${skill} strategy missing`);
      assert.equal(record.candidate.activated, true, `${skill} missed its fixture opportunity`);
      assert.equal(record.candidate.legal, true, `${skill} returned an illegal fixture reply`);
      assert.equal(record.candidate.error ?? null, null, `${skill} raised a strategy error`);
      assert.equal(record.baseline.legal, true, `${skill} baseline fixture is not legal`);
    }
  }
});
