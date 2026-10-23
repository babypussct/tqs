import assert from 'node:assert/strict';
import { test } from 'node:test';
import { compareAiTraceRuns, parseAiTraceLog } from './smart-ai-prompt4-native-replay';

const revision = '0520e447ab756137f710ef6cd6c886e5a60cde23';

function nativeLog(
  input2 = 'd57170fe', reason2 = 'no_decision', seed = 1780420130, skill2 = 'hs__wusheng',
): string {
  const fallback = reason2 === 'accepted' ? 0 : 1;
  return [
    `2026 [tqs_ai_trace] summary scenario=ai-trace seed=${seed} revision=${revision} decisions=5 fallback=${fallback} probe_errors=0 overflow=false reasons=accepted:${5 - fallback}${fallback ? `,${reason2}:1` : ''} pair=verified hands=verified fixture=semantic_v3`,
    `2026 [tqs_ai_trace] decision scenario=ai-trace seed=${seed} revision=${revision} seq=1 seat=1 command=PlayCard skill=hs__zhiheng input=50ee2720 output=table/card=number/targets=1/special=0/interaction=0 reason=accepted detail=none`,
    `2026 [tqs_ai_trace] decision scenario=ai-trace seed=${seed} revision=${revision} seq=2 seat=2 command=PlayCard skill=${skill2} input=${input2} output=${fallback ? 'cancel' : 'string'} reason=${reason2} detail=none`,
    `2026 [tqs_ai_trace] decision scenario=ai-trace seed=${seed} revision=${revision} seq=3 seat=3 command=PlayCard skill=hs__kurou input=abcd0003 output=nil reason=accepted detail=none`,
    `2026 [tqs_ai_trace] decision scenario=ai-trace seed=${seed} revision=${revision} seq=4 seat=4 command=PlayCard skill=hs__qiangxi input=abcd0004 output=string reason=accepted detail=none`,
    `2026 [tqs_ai_trace] decision scenario=ai-trace seed=${seed} revision=${revision} seq=5 seat=1 command=AskForUseActiveSkill skill=hs__wusheng input=abcd0005 output=cancel reason=accepted detail=none`,
    '',
  ].join('\n');
}

test('compares real native makeReply request hashes with bounded metadata only', () => {
  const baseline = parseAiTraceLog(nativeLog());
  const candidate = parseAiTraceLog(nativeLog('d57170fe', 'accepted'));
  const result = compareAiTraceRuns(baseline, candidate);
  assert.equal(result.status, 'MATCHED_BOUNDED_REQUESTS');
  assert.equal(result.pairVerified, true);
  assert.equal(result.fixedHandsVerified, true);
  assert.equal(result.semanticFixtureVerified, true);
  assert.equal(result.matchedRequests, 5);
  assert.equal(result.changedOutputShapes, 1);
  assert.equal(result.changedFallbackReasons, 1);
  assert.equal(result.winRateAvailable, false);
  assert.equal(result.nativeOpportunityDenominatorAvailable, false);
  assert.equal(result.skillProvenanceVerified, true);
  assert.equal(result.changedSkillAttributions, 0);
  assert.ok(!JSON.stringify(result).includes('50ee2720'), 'output must not expose even input hashes');
});

test('legacy fingerprints, unverified seat pairs or missing fixed hands cannot pass', () => {
  const verified = parseAiTraceLog(nativeLog());
  const legacy = parseAiTraceLog(nativeLog().replace(' pair=verified hands=verified', ''));
  assert.equal(legacy.pairVerified, false);
  assert.equal(legacy.fixedHandsVerified, false);
  const legacyResult = compareAiTraceRuns(legacy, verified);
  assert.equal(legacyResult.status, 'INCONCLUSIVE');
  assert.ok(legacyResult.issues.includes('pair_not_verified'));
  assert.ok(legacyResult.issues.includes('fixed_hands_not_verified'));
  assert.ok(legacyResult.issues.includes('semantic_fixture_not_verified'));
  const oldFixture = parseAiTraceLog(nativeLog().replace(' fixture=semantic_v3', ' fixture=semantic_v2'));
  assert.equal(oldFixture.semanticFixtureVerified, false);
  assert.equal(oldFixture.skillProvenanceVerified, false);
  assert.ok(compareAiTraceRuns(verified, oldFixture).issues.includes('semantic_fixture_not_verified'));
  assert.ok(compareAiTraceRuns(verified, oldFixture).issues.includes('skill_provenance_not_verified'));
  const wrongPair = parseAiTraceLog(nativeLog().replace('pair=verified', 'pair=unverified'));
  assert.ok(compareAiTraceRuns(verified, wrongPair).issues.includes('pair_not_verified'));
  const wrongHands = parseAiTraceLog(nativeLog().replace('hands=verified', 'hands=unverified'));
  assert.ok(compareAiTraceRuns(verified, wrongHands).issues.includes('fixed_hands_not_verified'));
  assert.throws(() => parseAiTraceLog(nativeLog().replace('pair=verified', 'pair=private_general')),
    /malformed ai-trace summary/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('fixture=semantic_v3', 'fixture=semantic_v4')),
    /malformed ai-trace summary/u);
});

test('equal seed without equal bounded request state remains inconclusive', () => {
  const result = compareAiTraceRuns(parseAiTraceLog(nativeLog()), parseAiTraceLog(nativeLog('87654321')));
  assert.equal(result.status, 'INCONCLUSIVE');
  assert.deepEqual(result.mismatches, [{ seq: 2, category: 'request_state' }]);
  assert.equal(result.matchedRequests, 4);
  assert.equal(result.changedFallbackReasons, 0);
});

test('skill attribution is retained as bounded Prompt 4 provenance', () => {
  const baseline = parseAiTraceLog(nativeLog());
  const candidate = parseAiTraceLog(nativeLog('d57170fe', 'no_decision', 1780420130, 'hs__longdan'));
  const result = compareAiTraceRuns(baseline, candidate);
  assert.equal(result.status, 'MATCHED_BOUNDED_REQUESTS');
  assert.equal(result.changedSkillAttributions, 1);
  assert.equal(result.changedFallbackReasons, 0);
});

test('different seed or missing decisions cannot pass the strict pair gate', () => {
  const baseline = parseAiTraceLog(nativeLog());
  const candidate = parseAiTraceLog(nativeLog('d57170fe', 'no_decision', 1780420131));
  const result = compareAiTraceRuns(baseline, candidate);
  assert.equal(result.status, 'INCONCLUSIVE');
  assert.ok(result.issues.includes('seed_mismatch'));
  const missing = { ...candidate, seed: baseline.seed, decisions: candidate.decisions.slice(0, 4) };
  assert.deepEqual(compareAiTraceRuns(baseline, missing).mismatches, [
    { seq: 5, category: 'missing_decision' },
  ]);
});

test('native trace requires exactly four ordered PlayCard seats and one active-skill decision', () => {
  assert.throws(() => parseAiTraceLog(nativeLog().replace('seat=3 command=PlayCard', 'seat=2 command=PlayCard')),
    /command coverage/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('seat=1 command=AskForUseActiveSkill', 'seat=1 command=PlayCard')),
    /command coverage/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('decisions=5', 'decisions=4')),
    /decision count/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('scenario=ai-trace', 'scenario=hidden-active')),
    /unexpected native trace scenario/u);
});

test('rejects missing, overflowing, mixed identity, malformed or inconsistent native traces', () => {
  assert.throws(() => parseAiTraceLog('unrelated native text'), /summary is missing/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('probe_errors=0', 'probe_errors=1')), /incomplete/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('overflow=false', 'overflow=true')), /incomplete/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('decisions=5', 'decisions=6')), /decision count/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('input=d57170fe', 'input=secret-content')), /fingerprint/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('seed=1780420130 revision=', 'seed=1780420132 revision=')), /mixed run/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('fallback=1', 'fallback=0')), /counters mismatch/u);
  assert.throws(() => parseAiTraceLog(nativeLog().replace('reason=no_decision detail=', 'reason=accepted detail=')), /counters mismatch/u);
});
