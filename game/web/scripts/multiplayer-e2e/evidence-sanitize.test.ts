import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { sanitizeQaEvidence } from './evidence-sanitize';
import {
  PRIVACY_CATEGORIES, SUPPLEMENTAL_CHANNELS, parsePrivacyAudit, parsePrivacyCoverage,
  parseSupplementalCoverage,
} from './native-privacy';

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

test('native privacy audit accepts only bounded salted hidden-reference fingerprints', () => {
  const valid = 'PASS;' + PRIVACY_CATEGORIES.map((name) => `${name}=0`).join(';') +
    ';hiddenFingerprints=0011223344556677;'
  assert.deepEqual(parsePrivacyAudit(valid.slice(0, -1)), {
    coverage: Object.fromEntries(PRIVACY_CATEGORIES.map((name) => [name, 0])),
    hiddenFingerprints: ['0011223344556677'],
  });
  for (const bad of [
    valid.replace('0011223344556677', '0011223344556677,0011223344556677'),
    valid.replace('0011223344556677', 'not-a-fingerprint'),
    valid.replace('0011223344556677', '001122334455667'),
    valid.replace('hiddenFingerprints=', 'hiddenFingerprints_extra='),
  ]) assert.equal(parsePrivacyAudit(bad.slice(0, -1)), null);
});

test('supplemental native coverage parser accepts only one known channel marker', () => {
  for (const channel of SUPPLEMENTAL_CHANNELS) {
    assert.deepEqual(parseSupplementalCoverage(`PASS;channel=${channel};observed=1`), { channel });
  }
  for (const bad of ['PASS', 'PASS;channel=metadata', 'PASS;channel=secret;observed=1',
    'PASS;channel=metadata;observed=2', 'PASS;channel=metadata;observed=1;extra=1']) {
    assert.equal(parseSupplementalCoverage(bad), null);
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

test('card-wire mismatch evidence keeps only bounded admission metadata', () => {
  const safe = sanitizeQaEvidence({
    cardWireObserverMode: 'wrong-protocol', cardWireObserverRejected: true,
    cardWireObserverObservePackets: 0, cardWirePlayerMode: 'missing',
    cardWirePlayerIndex: 1, cardWirePlayerRejected: true, cardWirePlayerCapabilityDrops: 1,
    cardWirePlayerErrorPackets: 2,
    cardWirePlayerNegotiatedPackets: 0, payload: secret,
  });
  assert.equal(safe.cardWireObserverMode, 'wrong-protocol');
  assert.equal(safe.cardWireObserverRejected, true);
  assert.equal(safe.cardWireObserverObservePackets, 0);
  assert.equal(safe.cardWirePlayerMode, 'missing');
  assert.equal(safe.cardWirePlayerIndex, 1);
  assert.equal(safe.cardWirePlayerRejected, true);
  assert.equal(safe.cardWirePlayerCapabilityDrops, 1);
  assert.equal(safe.cardWirePlayerErrorPackets, 2);
  assert.equal(safe.cardWirePlayerNegotiatedPackets, 0);
  assert.ok(!JSON.stringify(safe).includes(secret));
  const forged = sanitizeQaEvidence({
    cardWirePlayerMode: secret, cardWirePlayerIndex: 2, cardWirePlayerCapabilityDrops: 101,
    cardWirePlayerErrorPackets: 101,
    cardWirePlayerNegotiatedPackets: -1,
  });
  assert.deepEqual(forged, {
    cardWirePlayerMode: null, cardWirePlayerCapabilityDrops: null,
    cardWirePlayerIndex: null, cardWirePlayerErrorPackets: null,
    cardWirePlayerNegotiatedPackets: null,
  });
});

test('observer leave evidence keeps only bounded lifecycle booleans', () => {
  const secret = 'observer-private-payload';
  const safe = sanitizeQaEvidence({
    cardWireObserverLeaveRequested: true,
    cardWireObserverLeaveObserved: true,
    cardWireObserverLeaveNativeDisconnect: true,
    payload: secret,
  });
  assert.equal(safe.cardWireObserverLeaveRequested, true);
  assert.equal(safe.cardWireObserverLeaveObserved, true);
  assert.equal(safe.cardWireObserverLeaveNativeDisconnect, true);
  assert.ok(!JSON.stringify(safe).includes(secret));
  const forged = sanitizeQaEvidence({
    cardWireObserverLeaveRequested: secret,
    cardWireObserverLeaveObserved: 1,
    cardWireObserverLeaveNativeDisconnect: secret,
  });
  assert.deepEqual(forged, {
    cardWireObserverLeaveRequested: null,
    cardWireObserverLeaveObserved: 1,
    cardWireObserverLeaveNativeDisconnect: null,
  });
});

test('card-wire replay evidence keeps only bounded QA counters', () => {
  const secret = 'opaque-card-reference-or-payload';
  const safe = sanitizeQaEvidence({
    cardWireReplayRequested: true,
    cardWireReplayInjected: true,
    cardWireReplaySent: true,
    cardWireReplayRejectObserved: true,
    cardWireReplayRejectCount: 1,
    payload: secret,
  });
  assert.equal(safe.cardWireReplayRequested, true);
  assert.equal(safe.cardWireReplayInjected, true);
  assert.equal(safe.cardWireReplaySent, true);
  assert.equal(safe.cardWireReplayRejectObserved, true);
  assert.equal(safe.cardWireReplayRejectCount, 1);
  assert.equal(JSON.stringify(safe).includes(secret), false);
  const forged = sanitizeQaEvidence({
    cardWireReplayRequested: secret,
    cardWireReplayInjected: 1,
    cardWireReplaySent: secret,
    cardWireReplayRejectObserved: secret,
    cardWireReplayRejectCount: 101,
  });
  assert.deepEqual(forged, {
    cardWireReplayRequested: null,
    cardWireReplayInjected: 1,
    cardWireReplaySent: null,
    cardWireReplayRejectObserved: null,
    cardWireReplayRejectCount: null,
  });
});

test('card-wire rollback drain evidence keeps only bounded lifecycle booleans', () => {
  const secret = 'private-card-wire-rollback-marker';
  const safe = sanitizeQaEvidence({
    cardWireRollbackDrainRequested: true,
    cardWireRollbackDrainObserved: true,
    payload: secret,
  });
  assert.equal(safe.cardWireRollbackDrainRequested, true);
  assert.equal(safe.cardWireRollbackDrainObserved, true);
  assert.equal(JSON.stringify(safe).includes(secret), false);
  const forged = sanitizeQaEvidence({
    cardWireRollbackDrainRequested: secret,
    cardWireRollbackDrainObserved: 1,
  });
  assert.deepEqual(forged, {
    cardWireRollbackDrainRequested: null,
    cardWireRollbackDrainObserved: 1,
  });
});

test('raw wire capture exports only pre-decode counters and category coverage', () => {
  const safe = sanitizeQaEvidence({ nativeWireCapture: [{
    beforePacketDecode: true, frames: 12, packets: 34, failures: 0,
    packetBytes: { total: 3456, min: 64, max: 1024, le256: 12,
      le1024: 22, le4096: 0, gt4096: 0, raw: secret },
    rawBytes: secret,
    commands: { MoveCards: 7, [secret]: 999 },
    categoryCounts: { hidden_move_id: 5, [secret]: 999 },
    hiddenReferenceAudited: true,
    hiddenReferenceCollisions: 0,
  }] });
  const capture = safe.nativeWireCapture[0] as {
    beforePacketDecode: boolean; frames: number; packets: number;
    commands: Record<string, number | null>;
    categoryCounts: Record<string, number | null>;
    packetBytes: Record<string, unknown>;
    hiddenReferenceAudited: boolean;
    hiddenReferenceCollisions: number | null;
  };
  assert.equal(capture.beforePacketDecode, true);
  assert.equal(capture.frames, 12);
  assert.equal(capture.packets, 34);
  assert.equal(capture.commands.MoveCards, 7);
  assert.equal(capture.commands.PrepareDrawPile, null);
  assert.equal(capture.categoryCounts.hidden_move_id, 5);
  assert.equal(capture.categoryCounts.prepare_order, null);
  assert.equal(capture.packetBytes.total, 3456);
  assert.equal(capture.packetBytes.max, 1024);
  assert.equal(capture.packetBytes.raw, undefined);
  assert.ok(!JSON.stringify(safe).includes(secret));
  assert.equal(capture.hiddenReferenceAudited, true);
  assert.equal(capture.hiddenReferenceCollisions, 0);
});

test('supplemental wire capture exports only bounded command/channel counters', () => {
  const safe = sanitizeQaEvidence({ nativeSupplementalCapture: [{
    beforePacketDecode: true, frames: 17, packets: 8, incomingPackets: 6,
    replyPackets: 2, failures: 0, payload: secret,
    commands: { CardWireNegotiated: 1, GameLog: 2, [secret]: 9 },
    replies: { AskForCardChosen: 1, [secret]: 9 },
    channels: { negotiation: 1, public: 2, [secret]: 9 },
  }] });
  const capture = safe.nativeSupplementalCapture[0] as {
    beforePacketDecode: boolean; frames: number; packets: number;
    incomingPackets: number; replyPackets: number;
    commands: Record<string, number | null>; replies: Record<string, number | null>;
    channels: Record<string, number | null>;
  };
  assert.equal(capture.beforePacketDecode, true);
  assert.equal(capture.frames, 17);
  assert.equal(capture.packets, 8);
  assert.equal(capture.incomingPackets, 6);
  assert.equal(capture.replyPackets, 2);
  assert.equal(capture.commands.CardWireNegotiated, 1);
  assert.equal(capture.commands.GameLog, 2);
  assert.equal(capture.replies.AskForCardChosen, 1);
  assert.equal(capture.channels.negotiation, 1);
  assert.equal(capture.channels.public, 2);
  assert.ok(!JSON.stringify(safe).includes(secret));
});

test('packet-size capture exports only direction counters and bounded size buckets', () => {
  const safe = sanitizeQaEvidence({ nativePacketSizeCapture: [{
    beforePacketDecode: true, frames: 19, packets: 31, incomingPackets: 17,
    outgoingPackets: 14, failures: 0,
    packetBytes: { total: 4096, min: 17, max: 568, le256: 20,
      le1024: 11, le4096: 0, gt4096: 0, raw: secret },
    payload: secret,
  }] });
  const capture = safe.nativePacketSizeCapture[0] as {
    beforePacketDecode: boolean; frames: number; packets: number;
    incomingPackets: number; outgoingPackets: number; failures: number | null;
    packetBytes: Record<string, unknown>;
  };
  assert.equal(capture.beforePacketDecode, true);
  assert.equal(capture.frames, 19);
  assert.equal(capture.packets, 31);
  assert.equal(capture.incomingPackets, 17);
  assert.equal(capture.outgoingPackets, 14);
  assert.equal(capture.failures, 0);
  assert.equal(capture.packetBytes.total, 4096);
  assert.equal(capture.packetBytes.raw, undefined);
  assert.ok(!JSON.stringify(safe).includes(secret));
});

test('native process telemetry exports bounded metrics without PID, path or command data', () => {
  const safe = sanitizeQaEvidence({ nativeProcessMetrics: {
    schemaVersion: 1, sampleCount: 12, firstRssKb: 3072, minRssKb: 3072,
    maxRssKb: 4096, lastRssKb: 3584,
    maxCpuSeconds: 1.23456, elapsedSeconds: 2.34567,
    sampling: 'ps-rss-cputime', pid: 12345, path: secret, command: secret,
  } });
  assert.deepEqual(safe.nativeProcessMetrics, {
    schemaVersion: 1, sampleCount: 12, firstRssKb: 3072, minRssKb: 3072,
    maxRssKb: 4096, lastRssKb: 3584,
    maxCpuSeconds: 1.235, elapsedSeconds: 2.346, sampling: 'ps-rss-cputime',
  });
  const unsafe = sanitizeQaEvidence({ nativeProcessMetrics: {
    schemaVersion: 2, sampleCount: 1_000_001, firstRssKb: 4 * 1024 * 1024 + 1,
    minRssKb: 4 * 1024 * 1024 + 1, maxRssKb: 4 * 1024 * 1024 + 1,
    lastRssKb: 4 * 1024 * 1024 + 1,
    maxCpuSeconds: Number.POSITIVE_INFINITY, elapsedSeconds: -1,
    sampling: secret, pid: 67890, path: secret,
  } });
  assert.deepEqual(unsafe.nativeProcessMetrics, {
    schemaVersion: null, sampleCount: null, firstRssKb: null, minRssKb: null,
    maxRssKb: null, lastRssKb: null,
    maxCpuSeconds: null, elapsedSeconds: null, sampling: null,
  });
  assert.equal(JSON.stringify(safe).includes(secret), false);
  assert.equal(JSON.stringify(unsafe).includes(secret), false);
  assert.equal(Object.prototype.hasOwnProperty.call(safe.nativeProcessMetrics, 'pid'), false);
});

test('native semantic CBOR capture exports only bounded parser counters', () => {
  const secret = 'opaque-card-reference-or-native-payload';
  const safe = sanitizeQaEvidence({ nativeSemanticCapture: {
    schemaVersion: 1, requested: true, records: 18, semanticPassRecords: 18,
    semanticFailures: 0, outerDecodedRecords: 18, innerDecodedRecords: 18,
    inboundRecords: 6, outboundRecords: 12, opaqueReferences: 9,
    numericReferences: 2, invalidReferences: 0, forbiddenFields: 0,
    nestedDecoded: 1, maxDepth: 7, payload: secret,
    audiences: { owner: 5, opponent: 5, observer: 2, unknown: 6, [secret]: 99 },
    channels: { metadata: 3, public: 4, request: 5, deck: 5, negotiation: 1, reply: 2, [secret]: 99 },
    scopes: { outbound: 12, 'inbound-reply': 4, 'inbound-notify': 2,
      'inbound-request': 0, [secret]: 99 },
    command: secret,
  } });
  assert.equal(safe.nativeSemanticCapture.records, 18);
  assert.equal(safe.nativeSemanticCapture.semanticFailures, 0);
  assert.equal(safe.nativeSemanticCapture.audiences.owner, 5);
  assert.equal(safe.nativeSemanticCapture.channels.request, 5);
  assert.equal(safe.nativeSemanticCapture.channels.reply, 2);
  assert.equal(safe.nativeSemanticCapture.scopes['inbound-reply'], 4);
  assert.equal(safe.nativeSemanticCapture.payload, undefined);
  assert.ok(!JSON.stringify(safe).includes(secret));
  const forged = sanitizeQaEvidence({ nativeSemanticCapture: {
    schemaVersion: 2, records: 1_000_001, semanticFailures: -1,
    maxDepth: 65, audiences: secret, channels: [], scopes: { owner: secret },
  } });
  assert.equal(forged.nativeSemanticCapture.schemaVersion, null);
  assert.equal(forged.nativeSemanticCapture.records, null);
  assert.equal(forged.nativeSemanticCapture.semanticFailures, null);
  assert.equal(forged.nativeSemanticCapture.maxDepth, null);
  assert.equal((forged.nativeSemanticCapture.audiences as unknown as Record<string, unknown>).owner, null);
  assert.equal(JSON.stringify(forged).includes(secret), false);
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

test('keeps bounded native CSPRNG failure metadata without exporting runtime payloads', () => {
  const safe = sanitizeQaEvidence({
    cardWireEntropyFailure: true,
    cardWireEntropyFailureObserved: true,
    cardWireEntropyFailureKind: 'short-read',
    cardWireEntropyNegotiatedPackets: 2,
    cardWireEntropyCardBearingPackets: 0,
    cardWireEntropyBatchAborts: 1,
    cardWireEntropyBatchCommits: 0,
    cardWireEntropyLastAbortActiveReferences: 0,
    cardWireEntropyLastAbortActiveRequests: 0,
    cardWireEntropyFailureKindForged: secret,
    privateToken: secret,
  });
  assert.equal(safe.cardWireEntropyFailure, true);
  assert.equal(safe.cardWireEntropyFailureObserved, true);
  assert.equal(safe.cardWireEntropyFailureKind, 'short-read');
  assert.equal(safe.cardWireEntropyNegotiatedPackets, 2);
  assert.equal(safe.cardWireEntropyCardBearingPackets, 0);
  assert.equal(safe.cardWireEntropyBatchAborts, 1);
  assert.equal(safe.cardWireEntropyLastAbortActiveReferences, 0);
  assert.equal(safe.cardWireEntropyLastAbortActiveRequests, 0);
  assert.equal(JSON.stringify(safe).includes(secret), false);
});
