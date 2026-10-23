import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  PROMPT4_NATIVE_SKILLS,
  comparePrompt4NativeSkillTraces,
  parsePrompt4NativeSkillTrace,
} from './smart-ai-prompt4-native-skill-trace';

const revision = '0520e447ab756137f710ef6cd6c886e5a60cde23';

function nativeLog(options: { invalid?: number; miss?: number; seed?: number; quality?: boolean } = {}): string {
  const invalid = options.invalid ?? 0;
  const miss = options.miss ?? 0;
  const accepted = 18 - Math.max(invalid, miss);
  const acted = accepted;
  const misses = invalid + miss;
  const fallback = invalid + miss;
  const reasons = fallback === 0 ? 'accepted:18' : `accepted:${accepted},${invalid ? 'illegal_reply' : 'no_decision'}:${fallback}`;
  const decisions = PROMPT4_NATIVE_SKILLS.map((skill, index) => {
    const seq = index + 1;
    const isInvalid = invalid > 0 && seq === 3;
    const isMiss = miss > 0 && seq === 7;
    const acceptedFlag = isInvalid || isMiss ? 0 : 1;
    const actedFlag = acceptedFlag;
    const reason = isInvalid ? 'illegal_reply' : isMiss ? 'no_decision' : 'accepted';
    const detail = isInvalid ? 'feasibility_rejected' : 'none';
    const input = (seq + 10000000).toString(16).padStart(8, '0');
    const offer = (seq + 20000000).toString(16).padStart(8, '0');
    const command = skill === 'kanpo' ? 'AskForUseCard' : skill === 'aocai' ? 'AskForResponseCard' : 'AskForUseActiveSkill';
    const snapshot = options.quality
      ? ` selected_cards=${acceptedFlag ? 1 : 0} selected_targets=${acceptedFlag ? 1 : 0} target_quality=${acceptedFlag ? 'expected' : 'no_action'} resource_value=${acceptedFlag ? 'medium' : 'none'}`
      : '';
    return `[tqs_prompt4_trace] decision scenario=ai-trace seed=${options.seed ?? 1780420130} revision=${revision} seq=${seq} skill=${skill} command=${command} input=${input} offer=${offer} opportunity=1 offered_cards=${seq % 4} offered_targets=${(seq + 1) % 4} accepted=${acceptedFlag} acted=${actedFlag} invalid=${isInvalid ? 1 : 0} output=${acceptedFlag ? 'table/card=skill/targets=1/special=0/interaction=0' : 'cancel'} reason=${reason} detail=${detail} target_profile=${seq % 3 === 0 ? 'enemy' : 'none'} card_profile=${acceptedFlag ? 'skill' : 'none'} resource_shape=${acceptedFlag ? 'one_card' : 'none'}${snapshot}`;
  });
  return [
    `[tqs_prompt4_trace] summary scenario=ai-trace seed=${options.seed ?? 1780420130} revision=${revision} decisions=18 opportunities=18 accepted=${accepted} acted=${acted} misses=${misses} fallback=${fallback} invalid=${invalid} errors=0 pair=verified state=verified fixture=semantic_v1 skills=18 metadata=shape_v1`,
    ...decisions,
    '',
  ].join('\n');
}

test('parses the eighteen native Prompt 4 skills with bounded opportunity metadata', () => {
  const trace = parsePrompt4NativeSkillTrace(nativeLog());
  assert.equal(trace.decisions.length, 18);
  assert.deepEqual(trace.decisions.map((entry) => entry.skill), PROMPT4_NATIVE_SKILLS);
  assert.equal(trace.opportunities, 18);
  assert.equal(trace.invalid, 0);
  assert.equal(trace.fixtureVerified, true);
  assert.equal(trace.shapeMetadataVerified, true);
  assert.equal(trace.decisions[0].targetProfile, 'none');
  assert.equal(trace.decisions[2].targetProfile, 'enemy');
  assert.equal(trace.decisions[0].resourceShape, 'one_card');
  assert.equal(trace.decisions[0].resourceValue, 'unknown');
});

test('paired identical native Prompt 4 traces pass without exposing fingerprints', () => {
  const baseline = parsePrompt4NativeSkillTrace(nativeLog());
  const candidate = parsePrompt4NativeSkillTrace(nativeLog());
  const result = comparePrompt4NativeSkillTraces(baseline, candidate);
  assert.equal(result.status, 'MATCHED_NATIVE_SKILLS');
  assert.equal(result.safetyStatus, 'NO_INVALID_NATIVE_REPLIES');
  assert.equal(result.matchedRequests, 18);
  assert.equal(result.nativeOpportunityDenominatorAvailable, true);
  assert.equal(result.nativeTargetQualityAvailable, false);
  assert.equal(result.shapeMetadataVerified, true);
  assert.ok(!JSON.stringify(result).includes('00989680'), 'comparison must not expose input hashes');
});

test('native target and selected-resource snapshots are opt-in and bounded', () => {
  const baseline = parsePrompt4NativeSkillTrace(nativeLog({ quality: true }));
  const candidate = parsePrompt4NativeSkillTrace(nativeLog({ quality: true, miss: 1 }));
  assert.equal(baseline.decisions[0].selectedCards, 1);
  assert.equal(baseline.decisions[0].selectedTargets, 1);
  assert.equal(baseline.decisions[0].targetQuality, 'expected');
  const result = comparePrompt4NativeSkillTraces(baseline, candidate);
  assert.equal(result.nativeTargetQualityAvailable, true);
  assert.equal(result.nativeReplySnapshotAvailable, true);
  assert.equal(result.nativeResourceValueAvailable, true);
  assert.equal(result.changedTargetQualities, 1);
  assert.equal(result.changedResourceValues, 1);
  assert.ok(result.mismatches.some((entry) => entry.seq === 7 && entry.category === 'reply'));
});

test('paired request state can pass with bounded reply deltas', () => {
  const baseline = parsePrompt4NativeSkillTrace(nativeLog());
  const candidate = parsePrompt4NativeSkillTrace(nativeLog({ miss: 1 }));
  const result = comparePrompt4NativeSkillTraces(baseline, candidate);
  assert.equal(result.status, 'MATCHED_NATIVE_SKILLS');
  assert.equal(result.safetyStatus, 'NO_INVALID_NATIVE_REPLIES');
  assert.equal(result.matchedRequests, 18);
  assert.ok(result.mismatches.some((entry) => entry.seq === 7 && entry.category === 'reply'));
  assert.equal(result.candidateOpportunities, 18);
});

test('a changed bounded request state cannot pass the pair gate', () => {
  const baseline = parsePrompt4NativeSkillTrace(nativeLog());
  const candidate = parsePrompt4NativeSkillTrace(nativeLog().replace('input=00989681', 'input=00989682'));
  const result = comparePrompt4NativeSkillTraces(baseline, candidate);
  assert.equal(result.status, 'INCONCLUSIVE');
  assert.equal(result.safetyStatus, 'INCONCLUSIVE');
  assert.ok(result.mismatches.some((entry) => entry.seq === 1 && entry.category === 'request_state'));
});

test('matched invalid native replies remain a failed safety status', () => {
  const baseline = parsePrompt4NativeSkillTrace(nativeLog({ invalid: 1 }));
  const candidate = parsePrompt4NativeSkillTrace(nativeLog({ invalid: 1 }));
  const result = comparePrompt4NativeSkillTraces(baseline, candidate);
  assert.equal(result.status, 'MATCHED_NATIVE_SKILLS');
  assert.equal(result.safetyStatus, 'INVALID_NATIVE_REPLIES');
  assert.equal(result.baselineInvalid, 1);
  assert.equal(result.candidateInvalid, 1);
});

test('rejects unverified, reordered, overflowing, or malformed native traces', () => {
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('state=verified', 'state=unverified')), /not verified/u);
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('seq=1 skill=tianyi', 'seq=1 skill=duanfa')), /order/u);
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('decisions=18', 'decisions=19')), /count mismatch/u);
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('input=00989681', 'input=secret-content')), /fingerprint/u);
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('fixture=semantic_v1', 'fixture=semantic_v2')), /malformed Prompt 4 native summary/u);
  assert.throws(() => parsePrompt4NativeSkillTrace(nativeLog().replace('command=AskForUseActiveSkill', 'command=UnsupportedRequest')), /unsupported request command/u);
});
