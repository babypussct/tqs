import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { sanitizeQaEvidence } from './evidence-sanitize';
import { PRIVACY_CATEGORIES, parsePrivacyCoverage } from './native-privacy';

const secret = 'private-hand-general-card-9999';

test('native coverage parser rejects vacuous PASS, partial, forged and malformed counters', () => {
  const valid = 'PASS;' + PRIVACY_CATEGORIES.map((name) => `${name}=0`).join(';');
  assert.equal(parsePrivacyCoverage(valid)?.observe_hand, 0);
  for (const bad of ['PASS', valid.replace('observe_hand=0', 'observe_hand=secret'),
    valid + ';private=999', valid.replace('prepare_order=0', 'prepare_order=-1'),
    valid.replace('prepare_order=0', 'prepare_order=8193'),
    valid.replace('prepare_order', 'prepare_order_extra')]) {
    assert.equal(parsePrivacyCoverage(bad), null);
  }
});

test('native deck audit exports only bounded command counts and negotiation status', () => {
  const safe = sanitizeQaEvidence({ nativeDeckPrivacy: [{ negotiated: true,
    failures: 0, payload: secret, commands: { PrepareDrawPile: 1,
      SyncDrawPile: secret, [secret]: 2 } as Record<string, unknown> }] });
  assert.equal(safe.nativeDeckPrivacy[0].commands.PrepareDrawPile, 1);
  assert.equal(safe.nativeDeckPrivacy[0].commands.SyncDrawPile, null);
  assert.equal(safe.nativeDeckPrivacy[0].commands.Observe, null);
  assert.equal(safe.nativeDeckPrivacy[0].negotiated, true);
  assert.ok(!JSON.stringify(safe).includes(secret));
});

test('evidence export never serializes uncontrolled client strings, even nested or in arrays', () => {
  const evidence = {
    errors: [secret], feedback: [secret],
    errorContexts: [{ client: 1, lastIncoming: secret, location: secret }],
    memoryStacks: [[secret, secret]],
    scenarioBoardStates: [[secret]],
    scenarioObservations: [{ command: 'PlayCard', requestId: 7, reply: true, detail: secret }],
    traces: [[{ direction: 'incoming', command: 'GameOver', requestId: 42, type: 3,
      nested: [secret], payload: secret }]],
    botAudit: { public: [{ logs: [secret], skillLogs: [secret], boardPlayers: [secret],
      botNames: [secret] }], trace: [{ gameOver: 1 }] },
    candidateIdentity: { sourceRevision: secret, arbitrary: secret },
    debug: { extra: { someArray: [secret], arbitrary: secret } },
    [secret]: { scenario: 'delta-fengshi-siege' },
    luaTelemetry: [{ callbacksTotal: 9, samples: [{ elapsedMs: 10, dump: secret }],
      callbackCounts: { [secret]: 10 } }],
  };
  const serialized = JSON.stringify(sanitizeQaEvidence(evidence));
  assert.ok(!serialized.includes(secret));
  assert.equal(Object.prototype.hasOwnProperty.call(JSON.parse(serialized), secret), false);
  const safe = JSON.parse(serialized);
  assert.deepEqual(safe.errors, ['browser-or-runner-error']);
  assert.deepEqual(safe.feedback, ['application-error-notice']);
  assert.deepEqual(safe.memoryAllocationDiagnosticCounts, [2]);
  assert.deepEqual(safe.scenarioBoardStates, []);
  assert.equal(safe.traces[0][0].command, 'GameOver');
  assert.equal(safe.scenarioObservations[0].detail, undefined);
  assert.equal(safe.luaTelemetry[0].samples[0].dump, undefined);
});

test('explicit server-issued numeric and boolean markers remain verifiable', () => {
  const fengshi = '[TQS QA] Upstream 锋矢: first_use=true; siege_relation=true; response_blocked=true; target_jink_retained=true; target_responded=false';
  const bawei = '[TQS QA] Upstream 霸威: round_damage_recorded=true; damaged_response_blocked=false; damaged_jink_retained=true; control_responded=true; damage=1';
  const evidence = {
    scenario: 'delta-fengshi-siege',
    scenarioObservations: [{ command: 'PlayCard', requestId: 9, reply: true,
      detail: 'delta-fengshi-first-slash' }],
    scenarioFengshi: { public: [{ logs: [fengshi, bawei, 'unexpected name/card id'] }] },
    traces: [[{ direction: 'incoming', command: 'GameOver', requestId: 0, type: 1 }]],
    luaTelemetry: [{ callbacksTotal: 5, callbacksPeak: 3, samples: [{ elapsedMs: 100,
      luaHeapKiB: 1024.5, wasmBytes: 12 }] }],
  };
  const sanitized = sanitizeQaEvidence(evidence);
  assert.equal(sanitized.scenario, evidence.scenario);
  assert.deepEqual(sanitized.scenarioFengshi.public[0].logs, [fengshi, bawei]);
  assert.equal(sanitized.scenarioObservations[0].detail, 'delta-fengshi-first-slash');
  assert.equal(sanitized.traces[0][0].command, 'GameOver');
  assert.equal(sanitized.luaTelemetry[0].callbacksTotal, 5);
});

test('Upstream server log schemas preserve all known skills and exclude forged labels or fields', () => {
  const known = [
    '[TQS QA] Upstream 铁骑: judge_discard_cancelled=true; response_blocked=true; target_jink_retained=true; damage=1',
    '[TQS QA] Upstream 凶算: ActiveSkillOnUse=true; chọn bài=true; gây sát thương=1; rút ba=3; reset limited=true',
    '[TQS QA] Upstream 问计: phase_handoff=true; slash_used=true; target_response_blocked=true; target_jink_retained=true',
    '[TQS QA] Upstream lord_ex 问计: phase_handoff=true; slash_disresponsive=true; target_jink_retained=true; different_card_returned=true',
    '[TQS QA] Upstream 谦策: card_using=true; skill_effect=true; target_big_kingdom=true; response_blocked=true; target_slash_retained=true',
    '[TQS QA] Upstream 鞬出: target_equipment_discarded=true; response_blocked=true; target_jink_retained=true; damage=1',
    '[TQS QA] Upstream 袭射: lower_hp_blocked=true; target_jink_retained=true; equal_hp_allowed=true; control_responded=true; equip_discarded=2; damage=1',
    '[TQS QA] Upstream 霸威: round_damage_recorded=true; damaged_response_blocked=true; damaged_jink_retained=true; control_responded=true; damage=1',
    '[TQS QA] Upstream 锋矢: first_use=true; siege_relation=true; response_blocked=true; target_jink_retained=true; target_responded=false',
    '[TQS QA] Upstream 除绝: dead_kingdom_response_blocked=true; target_jink_retained=true; control_response_allowed=true; control_responded=true; damage=1',
    '[TQS QA] Upstream 贞特: target_confirmed=true; target_response_blocked=true; choice_negate=true; damage=0',
    '[TQS QA] Upstream 方天画戟: first_target_confirmed=true; extra_target_confirmed=true; targets_added=true; damage=2',
    '[TQS QA] Upstream 死谏: owner_empty_after_hand_loss=true; target_confirmed=true; target_card_discarded=true',
  ];
  const unsafe = [
    `[TQS QA] Upstream ${secret}: damage=1`,
    `[TQS QA] Upstream 锋矢: first_use=true; siege_relation=true; response_blocked=${secret}; target_jink_retained=true; target_responded=false`,
    `[TQS QA] Upstream 锋矢: first_use=true; siege_relation=true; response_blocked=true; target_jink_retained=true; target_responded=false; private=${secret}`,
  ];
  const safe = sanitizeQaEvidence({ logs: [...known, ...unsafe] });
  assert.deepEqual(safe.logs, known);
  assert.equal(JSON.stringify(safe).includes(secret), false);
});

test('preserves strictly validated candidate, QA and remote identity without local paths', () => {
  const sha256 = 'a'.repeat(64);
  const md5 = 'f'.repeat(32);
  const input = {
    candidateIdentity: {
      releaseManifestSha256: sha256, releaseManifestPath: '/private/path-to-manifest',
      runtimeMD5: md5, localPackages: ['freekill-core', 'hegemony', secret, 'unknown-package'],
      localServerOnlyPackages: ['tqs_qa', secret], distIndexSha256: sha256,
      deploymentUrl: 'https://user:private@server.example.com/',
      remoteGatewayManifest: {
        md5, packages: ['freekill-core', 'hegemony', secret], bundleHash: sha256,
        fileCount: 217, privateHand: secret,
      },
      remoteIndexSha256: sha256,
    },
    qaPackageIdentity: {
      manifestPath: '/private/qa-manifest', manifestSha256: sha256,
      sourceRevision: 'b'.repeat(40), catalogSha256: sha256, packageSha256: sha256,
    },
    qaSourceIdentity: {
      runtimeMD5: md5, smartAiSha256: sha256, roomLuaSha256: sha256,
      qaSmartAiOverlaySha256: sha256, unsafe: secret,
    },
  };
  const safe = sanitizeQaEvidence(input);
  assert.equal(safe.candidateIdentity.releaseManifestSha256, sha256);
  assert.equal(safe.candidateIdentity.releaseManifestPath, null);
  assert.equal(safe.candidateIdentity.deploymentUrl, null);
  assert.deepEqual(safe.candidateIdentity.localPackages, ['freekill-core', 'hegemony']);
  assert.deepEqual(safe.candidateIdentity.localServerOnlyPackages, ['tqs_qa']);
  assert.deepEqual(safe.candidateIdentity.remoteGatewayManifest.packages, ['freekill-core', 'hegemony']);
  assert.equal(safe.candidateIdentity.remoteGatewayManifest.bundleHash, sha256);
  assert.equal(safe.candidateIdentity.remoteGatewayManifest.fileCount, 217);
  assert.equal(safe.candidateIdentity.remoteIndexSha256, sha256);
  assert.equal(safe.qaPackageIdentity.manifestSha256, sha256);
  assert.equal(safe.qaPackageIdentity.manifestPath, null);
  assert.equal(safe.qaSourceIdentity.smartAiSha256, sha256);
  assert.equal(safe.qaSourceIdentity.roomLuaSha256, sha256);
  assert.equal(safe.qaSourceIdentity.qaSmartAiOverlaySha256, sha256);
  assert.equal(JSON.stringify(safe).includes(secret), false);
});

test('keeps canonical runner UTC timestamps while rejecting invalid and sensitive values', () => {
  const at = '2026-11-01T03:01:02.123Z';
  assert.equal(sanitizeQaEvidence({ at }).at, at);
  for (const unsafe of [secret, '2026-02-30T03:01:02.123Z',
    '2026-11-01T03:01:02Z', '2026-11-01T03:01:02.123+07:00',
    '2026-11-01T03:01:02.123Z ']) {
    assert.equal(sanitizeQaEvidence({ at: unsafe }).at, null);
  }
});

test('keeps boolean card-reply markers without exporting raw card identifiers or payloads', () => {
  const evidence = {
    hiddenJizhi: { card: true },
    traces: [[{ card: 547, requestId: 8 }, { card: [547, 548] },
      { card: { card: 549, type: 1 } }]],
  };
  const safe = sanitizeQaEvidence(evidence);
  assert.equal(safe.hiddenJizhi.card, true);
  assert.equal(safe.traces[0][0].card, null);
  assert.equal(safe.traces[0][0].requestId, 8);
  assert.equal(safe.traces[0][1].card, null);
  assert.equal(safe.traces[0][2].card, null);
  assert.ok(!JSON.stringify(safe).includes('547'));
  assert.ok(!JSON.stringify(safe).includes('548'));
  assert.ok(!JSON.stringify(safe).includes('549'));
});

test('every native QA server-issued Upstream and Pair log template survives evidence export', () => {
  const source = readFileSync(new URL('../../../../deploy/freekill-native/qa/tqs_qa/init.lua', import.meta.url), 'utf8');
  const templates = Array.from(source.matchAll(/type = "(\[TQS QA\] (?:Upstream |Pair)[^"]+)"/gu),
    (match) => match[1]);
  // Fail when the native fixture adds/removes a marker without an evidence
  // schema review. These 13 Upstream + 7 Pair templates are public metadata.
  assert.equal(templates.length, 20);
  const values: Record<string, string> = {
    scenario: 'general-pair-match-a', roster_set: 'r1', seat_swap: 'A',
    seats: '1,2', winner_seats: '1', winner_kingdoms: '1:wei', outcome: 'win',
    input: 'abcdef01', output_hash: 'abcdef01', trace_hash: 'abcdef01',
    valid: 'true', overflow: 'false', reason: 'accepted', detail: 'none',
    reasons: 'accepted:1',
  };
  const logs = templates.map((template) => template.replace(/%arg\d*/gu, (_token, at: number) => {
    const field = template.slice(0, at).split(/[ ;]/u).at(-1)?.replace(/=$/u, '') ?? '';
    return values[field] ?? '1';
  }));
  assert.deepEqual(sanitizeQaEvidence({ logs }).logs, logs);
});

test('keeps complete, typed general-pair native telemetry and rejects mutated private tokens', () => {
  const prefix = '[TQS QA] ';
  const scope = 'scenario=general-pair-match-a seed=17 roster_set=r1 seat_swap=A';
  const sha8 = 'abcdef01';
  const expected = [
    `${prefix}PairOfferSummary scenario=general-pair-match-a roster_set=r1 seat_swap=A offer_count=10 seat_count=4 seats=1,2,3,4`,
    `${prefix}PairDecisionSummary ${scope} decisions=2 accepted=2 fallback=0 invalid=0 overflow=false`,
    `${prefix}PairDecisionStats ${scope} latency_n=2 latency_sum_ms=8.125000 latency_min_ms=2.125000 latency_p50_ms=2.125000 latency_p95_ms=6.000000`,
    `${prefix}PairDecisionTrace ${scope} latency_max_ms=6.000000 trace_hash=${sha8} reasons=accepted:2`,
    `${prefix}PairDecision ${scope} seq=1 seat=1 input=${sha8} output_hash=001100aa valid=true`,
    `${prefix}PairDecisionMeta ${scope} seq=1 reason=accepted detail=none elapsed_ms=2.125000`,
    `${prefix}PairDecisionMeta ${scope} seq=2 reason=feasibility_rejected detail=invalid_details elapsed_ms=6.000000`,
    `${prefix}PairMatchResult ${scope} winner_seats=1,3 winner_kingdoms=1:wei,3:shu winner_count=2 outcome=win`,
    `${prefix}PairMatchResult ${scope} winner_seats=draw winner_kingdoms=draw winner_count=0 outcome=draw`,
  ];
  const poisoned = [
    `${prefix}PairDecisionMeta ${scope} seq=1 reason=${secret} detail=none elapsed_ms=2.125000`,
    `${prefix}PairDecisionMeta ${scope} seq=1 reason=accepted detail=${secret} elapsed_ms=2.125000`,
    `${prefix}PairMatchResult ${scope} winner_seats=1,3 winner_kingdoms=1:wei,3:${secret} winner_count=2 outcome=win`,
    `${prefix}PairDecision ${scope} seq=1 seat=1 input=${secret} output_hash=001100aa valid=true`,
    `${prefix}PairDecision ${scope} seq=1 seat=1 input=${sha8} output_hash=001100aa valid=true extra=${secret}`,
    `${prefix}Hidden QA skill=${secret}`,
    `${prefix}Bước QA detail=${secret}`,
  ];
  const safe = sanitizeQaEvidence({
    scenarioObservations: [{ command: 'CustomDialog', requestId: 5, reply: true, extra: secret }],
    skillLogs: [...expected, ...poisoned],
    botSkillLogs: [...expected, ...poisoned],
    logs: [...expected, ...poisoned],
  });
  assert.deepEqual(safe.skillLogs, expected);
  assert.deepEqual(safe.botSkillLogs, expected);
  assert.deepEqual(safe.logs, expected);
  assert.equal(JSON.stringify(safe).includes(secret), false);
  assert.equal(safe.scenarioObservations[0].extra, undefined);
});
