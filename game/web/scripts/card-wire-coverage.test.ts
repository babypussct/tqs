import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { PRIVACY_CATEGORIES } from './multiplayer-e2e/native-privacy';

const repo = path.resolve(import.meta.dirname, '../../..');
const matrixPath = path.join(repo, 'docs/web-client/CARD_WIRE_COVERAGE_MATRIX_2026-11-15.json');
const matrix = JSON.parse(readFileSync(matrixPath, 'utf8')) as {
  schemaVersion: number;
  protocol: string;
  mode: string;
  productionPolicy: {
    legacyWire: string;
    cardWireVersion1: string;
    candidateOptIn: string;
    releaseDecision: string;
    upstreamPinsChangedForThisMatrix: boolean;
  };
  baseline: {
    strictDiagnosticCommand: string;
    strictDiagnosticExpectedCurrentResult: string;
    strictDiagnosticEvidence: string;
    negotiatedV1StrictSource: {
      command: string;
      result: string;
      exitCode: number;
      auditedCategories: number;
      nestedCardMarksAudited: boolean;
      evidence: string;
      nativeBrowser: string;
    };
    privacyInterpretation: string;
    handoffProtocolEvidence: string;
    candidateSourceEvidence: string;
    nativeEvidence: string;
    verificationNote: string;
  };
  latestNativeEvidence: {
    runtimeMD5: string;
    qaPackageSha256: string;
    productionMutation: boolean;
  };
  currentDrawReconnectEvidence: {
    aggregate: string;
    artifact: string;
    result: string;
    strictPrivacyCategoriesObserved: number;
    nativeAndSupplementalFailures: number;
    recovered: boolean;
    gameOverAudiences: number;
    releaseStatus: string;
    productionMutation: boolean;
  };
  currentRollbackEvidence: {
    aggregate: string;
    v1Artifact: string;
    legacyArtifact: string;
    sameRuntimeIdentity: boolean;
    v1RunResult: string;
    legacyRunResult: string;
    legacyQaOverlayAbsent: boolean;
    legacyCardWireNegotiatedInTrace: boolean;
    candidateRollbackObserved: boolean;
    productionCanaryRollback: string;
    productionMutation: boolean;
  };
  packetSizeComparison: {
    artifact: string;
    status: string;
    legacyRunResult: string;
    v1RunResult: string;
    legacyCardWireVersion: number;
    v1CardWireVersion: number;
    legacyAudiences: number;
    v1Audiences: number;
    v1StrictPrivacyCategories: number;
    legacyCaptureFailures: number;
    v1CaptureFailures: number;
    legacyRecovered: boolean;
    v1Recovered: boolean;
    thresholdStatus: string;
    productionMutation: boolean;
    releaseDecision: string;
  };
  strictPrivacyCategories: CoverageRow[];
  supplementalChannels: CoverageRow[];
  repeatedProcessEvidence: {
    artifact: string;
    runCount: number;
    scenario: string;
    allRunsPass: boolean;
    totalProcessSamples: number;
    observedMaximumRssKb: number;
    nativeWireRecords: number;
    nativeCborSerializationTimingRecords: number;
    serverTimingRecords: number;
    logicalMappingSourceObservation: {
      maxActiveReferences: number;
      cleanupActiveReferences: number;
      retiredTombstones: number;
      foreignRejections: number;
      replayRejections: number;
      staleRejections: number;
      syntheticOnly: boolean;
      nativeBrowserRun: boolean;
    };
    thresholdStatus: string;
    mappingMemoryStatus: string;
    releaseApproval: string;
    productionMutation: boolean;
  };
  rollbackEvidence: {
    artifact: string;
    qaPackageSha256: string;
    runtimeMD5: string;
    v1RunResult: string;
    legacyRunResult: string;
    sameRuntimeIdentity: boolean;
    v1NegotiationPackets: number;
    legacyNegotiationPackets: number;
    legacyQaOverlayAbsent: boolean;
    candidateRollbackObserved: boolean;
    productionCanaryRollback: string;
    productionMutation: boolean;
  };
  choiceEvidence: {
    artifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    hiddenAskForCardChosenObserved: boolean;
    opaqueCardChosenReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  cardsAndChoiceEvidence: {
    artifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    cardsAndChoiceReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  fankuiEvidence: {
    artifact: string;
    deputyScenario: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    mainAndDeputyRunsPass: boolean;
    fankuiDamageReplyObserved: boolean;
    fankuiCardChosenReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    showCardObserved: boolean;
    showVirtualCardObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
  fanjianEvidence: {
    artifact: string;
    deputyScenario: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    mainAndDeputyRunsPass: boolean;
    showCardObserved: boolean;
    showVirtualCardObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  virtualCardEvidence: {
    artifact: string;
    deputyScenario: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    mainAndDeputyRunsPass: boolean;
    hiddenDuoshiInvoked: boolean;
    showVirtualCardObserved: boolean;
    showVirtualCardCount: number;
    nativeSupplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  poxiEvidence: {
    artifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    multiCardPoxiReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  arrangeEvidence: {
    artifact: string;
    deputyArtifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    arrangeCardsReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    deputyResult: string;
    deputySlotObserved: boolean;
    deputyArrangeCardsReplyObserved: boolean;
    deputyCleanupObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
  rehideEvidence: {
    artifact: string;
    deputyArtifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    hiddenYijiInvoked: boolean;
    retainedPrelightObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    deputyResult: string;
    deputySlotObserved: boolean;
    deputyCleanupObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
  luoshenEvidence: {
    artifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    hiddenLuoshenInvoked: boolean;
    hiddenLuoshenAgReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    productionMutation: boolean;
    releaseStatus: string;
  };
  luoshenDeputyEvidence: {
    artifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    hiddenLuoshenInvoked: boolean;
    hiddenLuoshenAgReplyObserved: boolean;
    deputySlotObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    cleanupObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
  revealEvidence: {
    artifact: string;
    deputyArtifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    activeRevealRequestOwnerOnly: boolean;
    activeRevealReplyObserved: boolean;
    nativeWireFailures: number;
    supplementalFailures: number;
    deputyResult: string;
    deputySlotObserved: boolean;
    deputyOwnerOnlyActiveRequestObserved: boolean;
    deputyCleanupObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
  mappingEvidence: {
    artifact: string;
    repeatedArtifact: string;
    scenario: string;
    result: string;
    qaPackageSha256: string;
    audiences: number;
    strictPrivacyCategoriesObserved: number;
    nativeWireFailures: number;
    supplementalFailures: number;
    maxActiveReferences: number;
    finalActiveReferences: number;
    finalAudiences: number;
    cleanupObserved: boolean;
    repeatedRunCount: number;
    repeatedAllRunsPass: boolean;
    repeatedAllRunsCleanupObserved: boolean;
    productionMutation: boolean;
    releaseStatus: string;
  };
};

type CoverageRow = {
  id: string;
  component: string;
  emitter: string;
  directPaths: string[];
  projector: string;
  audiences: string[];
  clientHandler: string;
  tests: string[];
  evidence: string[];
  status: string;
};

function assertRow(row: CoverageRow, label: string) {
  for (const field of ['id', 'component', 'emitter', 'projector', 'clientHandler', 'status'] as const) {
    assert.equal(typeof row[field], 'string', `${label}.${field} must be a string`);
    assert.ok(row[field].trim(), `${label}.${field} must not be empty`);
  }
  assert.ok(row.directPaths.length > 0, `${label}.directPaths must not be empty`);
  assert.ok(row.audiences.length > 0, `${label}.audiences must not be empty`);
  assert.ok(row.tests.length > 0, `${label}.tests must not be empty`);
  assert.ok(row.evidence.length > 0, `${label}.evidence must not be empty`);
  for (const relative of [...row.tests, ...row.evidence]) {
    assert.ok(existsSync(path.join(repo, relative)), `${label} references missing path ${relative}`);
  }
}

test('card-wire P0 matrix is a complete, fail-closed coverage contract', () => {
  assert.equal(matrix.schemaVersion, 1);
  assert.equal(matrix.protocol, 'TQS_HEG_CARD_WIRE');
  assert.equal(matrix.mode, 'new_heg_mode');
  assert.deepEqual(matrix.productionPolicy, {
    legacyWire: 'enabled',
    cardWireVersion1: 'disabled-by-default',
    candidateOptIn: 'isolated-QA-only',
    releaseDecision: 'OPEN-HOLD',
    upstreamPinsChangedForThisMatrix: false,
  });
  assert.match(matrix.baseline.strictDiagnosticCommand, /^lua5\.4 /u);
  assert.equal(matrix.baseline.strictDiagnosticExpectedCurrentResult, 'exit-2-with-12-exposure-groups');
  assert.equal(matrix.baseline.negotiatedV1StrictSource.result, 'PASS');
  assert.equal(matrix.baseline.negotiatedV1StrictSource.exitCode, 0);
  assert.equal(matrix.baseline.negotiatedV1StrictSource.auditedCategories, 12);
  assert.equal(matrix.baseline.negotiatedV1StrictSource.nestedCardMarksAudited, true);
  assert.match(matrix.baseline.privacyInterpretation,
    /legacy diagnostic remains an intentionally red baseline/u);
  for (const relative of [matrix.baseline.strictDiagnosticEvidence,
    matrix.baseline.handoffProtocolEvidence, matrix.baseline.candidateSourceEvidence,
    matrix.baseline.nativeEvidence]) {
    assert.ok(existsSync(path.join(repo, relative)), `baseline references missing path ${relative}`);
  }
  assert.ok(matrix.baseline.verificationNote.includes('does not convert'));

  const nativeEvidencePath = path.join(repo, matrix.baseline.nativeEvidence);
  const nativeEvidence = JSON.parse(readFileSync(nativeEvidencePath, 'utf8')) as {
    productionPolicy: { cardWireVersion1: string; productionMutation: boolean };
    result: {
      runnerResult: string;
      errors: unknown[];
      nativePrivacyFailures: number;
      negotiatedForAllAudiences: boolean;
      rawWireCapture: {
        packets: number;
        frames: number;
        failures: number;
        packetBytes: { total: number; min: number; max: number };
      };
    };
    rawSanitizedEvidence: string;
    strictPrivacyCategoryCounts: Record<string, number>;
    performanceEvidence: {
      result: string;
      nativeBoundary: string;
      nativeTransportBoundary: {
        sourcePatch: string;
        runEvidence: string;
        records: number;
        outboundRecords: number;
        outboundOuterDecodedRecords: number;
        outboundCardWireRecords: number;
        inboundPredecodeRecords: number;
        inboundPostDecodeRecords: number;
        forbiddenMetadataKeysObserved: boolean;
        scope: string;
      };
      rawDeckPackets: number;
      rawDeckBytes: number;
      supplementalPackets: number;
      nativeCborSerializationTiming: {
        artifact: string;
        records: number;
        sampleCap: number;
        scopes: Record<string, number>;
        channels: Record<string, number>;
        keys: string[];
        elapsedNs: { min: number; p50: number; p95: number; max: number; average: number };
        wireBytes: { min: number; max: number; total: number };
        forbiddenMetadataKeysObserved: boolean;
        productionMutation: boolean;
      };
      nativeProcessMetrics: {
        source: string;
        sampling: string;
        sampleCount: number;
        firstRssKb: number;
        minRssKb: number;
        maxRssKb: number;
        lastRssKb: number;
        maxCpuSeconds: number;
        elapsedSeconds: number;
      };
      nativeRepeatedProcessMetrics: {
        artifact: string;
        scenario: string;
        runCount: number;
        allRunsPass: boolean;
        allRunsRecovered: boolean;
        totalProcessSamples: number;
        observedMinimumRssKb: number;
        observedMaximumRssKb: number;
        maximumRunCpuSeconds: number;
        totalObservedElapsedSeconds: number;
        nativeWireRecords: number;
        nativeCborSerializationTimingRecords: number;
        serverTimingRecords: number;
        serverTimingScopes: Record<string, number>;
        logicalMappingSourceObservation: {
          maxActiveReferences: number;
          cleanupActiveReferences: number;
          retiredTombstones: number;
          foreignRejections: number;
          replayRejections: number;
          staleRejections: number;
          syntheticOnly: boolean;
          nativeBrowserRun: boolean;
        };
        allRunsProcessesClosed: boolean;
        allRunsListenersClosed: boolean;
        mappingMemoryStatus: string;
        thresholdStatus: string;
        releaseApproval: string;
        productionMutation: boolean;
        cleanup: string;
      };
      serverProjectTiming: {
        records: number;
        scopes: Record<string, number>;
        channels: Record<string, number>;
        elapsedMs: { min: number; max: number; average: number };
        keys: string[];
        forbiddenMetadataKeysObserved: boolean;
        cborSerializationIncluded: boolean;
        productionMutation: boolean;
      };
    };
  };
  assert.equal(nativeEvidence.productionPolicy.cardWireVersion1, 'disabled-by-default');
  assert.equal(nativeEvidence.productionPolicy.productionMutation, false);
  assert.equal(nativeEvidence.result.runnerResult, 'PASS');
  assert.deepEqual(nativeEvidence.result.errors, []);
  assert.equal(nativeEvidence.result.nativePrivacyFailures, 0);
  assert.equal(nativeEvidence.result.negotiatedForAllAudiences, true);
  assert.ok(existsSync(path.join(repo, nativeEvidence.rawSanitizedEvidence)),
    'native evidence must point at an existing sanitized trace');
  assert.equal(nativeEvidence.result.rawWireCapture.failures, 0);
  assert.ok(nativeEvidence.result.rawWireCapture.packets > 0 &&
    nativeEvidence.result.rawWireCapture.frames > 0 &&
    nativeEvidence.result.rawWireCapture.packetBytes.total > 0 &&
    nativeEvidence.result.rawWireCapture.packetBytes.max >=
      nativeEvidence.result.rawWireCapture.packetBytes.min);
  assert.equal(nativeEvidence.performanceEvidence.result,
    'PASS-bounded-native-boundaries-server-project-inner-and-outer-CBOR-timing-with-post-ready-process-observation; repeated/release-grade memory and native-performance release gates remain open');
  assert.match(nativeEvidence.performanceEvidence.nativeBoundary,
    /outer CBOR before PacketStream data decode/u);
  const nativeTransportBoundary = nativeEvidence.performanceEvidence.nativeTransportBoundary;
  assert.ok(existsSync(path.join(repo, nativeTransportBoundary.sourcePatch)),
    'native transport evidence must reference the QA patch');
  assert.ok(existsSync(path.join(repo, nativeTransportBoundary.runEvidence)),
    'native transport evidence must reference an existing sanitized run');
  assert.equal(nativeTransportBoundary.outboundRecords +
    nativeTransportBoundary.inboundPredecodeRecords +
    nativeTransportBoundary.inboundPostDecodeRecords, nativeTransportBoundary.records);
  assert.equal(nativeTransportBoundary.outboundOuterDecodedRecords,
    nativeTransportBoundary.outboundRecords);
  assert.equal(nativeTransportBoundary.inboundPredecodeRecords,
    nativeTransportBoundary.inboundPostDecodeRecords);
  assert.ok(nativeTransportBoundary.outboundRecords > 0 &&
    nativeTransportBoundary.outboundCardWireRecords > 0 &&
    nativeTransportBoundary.inboundPredecodeRecords > 0);
  assert.equal(nativeTransportBoundary.forbiddenMetadataKeysObserved, false);
  assert.match(nativeTransportBoundary.scope, /native C\+\+ outbound/u);
  assert.ok(nativeEvidence.performanceEvidence.rawDeckPackets > 0 &&
    nativeEvidence.performanceEvidence.rawDeckBytes > 0 &&
    nativeEvidence.performanceEvidence.supplementalPackets > 0);
  const nativeProcessMetrics = nativeEvidence.performanceEvidence.nativeProcessMetrics;
  assert.equal(nativeProcessMetrics.sampling, 'ps-rss-cputime');
  assert.ok(nativeProcessMetrics.sampleCount > 0 && nativeProcessMetrics.maxRssKb > 0 &&
    nativeProcessMetrics.firstRssKb > 0 && nativeProcessMetrics.minRssKb > 0 &&
    nativeProcessMetrics.lastRssKb > 0 &&
    nativeProcessMetrics.maxCpuSeconds >= 0 && nativeProcessMetrics.elapsedSeconds > 0);
  assert.ok(existsSync(path.join(repo, nativeProcessMetrics.source)),
    'native process metrics must point at an existing sanitized trace');
  const nativeRepeatedProcessMetrics = nativeEvidence.performanceEvidence.nativeRepeatedProcessMetrics;
  assert.ok(existsSync(path.join(repo, nativeRepeatedProcessMetrics.artifact)),
    'repeated native process metrics must reference a checked-in aggregate');
  assert.equal(nativeRepeatedProcessMetrics.scenario, 'draw-sequence');
  assert.equal(nativeRepeatedProcessMetrics.runCount, 3);
  assert.equal(nativeRepeatedProcessMetrics.allRunsPass, true);
  assert.equal(nativeRepeatedProcessMetrics.allRunsRecovered, true);
  assert.ok(nativeRepeatedProcessMetrics.totalProcessSamples > 0 &&
    nativeRepeatedProcessMetrics.observedMinimumRssKb > 0 &&
    nativeRepeatedProcessMetrics.observedMaximumRssKb >=
      nativeRepeatedProcessMetrics.observedMinimumRssKb &&
    nativeRepeatedProcessMetrics.maximumRunCpuSeconds >= 0 &&
    nativeRepeatedProcessMetrics.totalObservedElapsedSeconds > 0);
  assert.ok(nativeRepeatedProcessMetrics.nativeWireRecords > 0 &&
    nativeRepeatedProcessMetrics.nativeCborSerializationTimingRecords > 0 &&
    nativeRepeatedProcessMetrics.serverTimingRecords > 0);
  assert.equal(nativeRepeatedProcessMetrics.allRunsProcessesClosed, true);
  assert.equal(nativeRepeatedProcessMetrics.allRunsListenersClosed, true);
  assert.equal(nativeRepeatedProcessMetrics.mappingMemoryStatus, 'OPEN');
  assert.equal(nativeRepeatedProcessMetrics.thresholdStatus, 'OPEN');
  assert.equal(nativeRepeatedProcessMetrics.releaseApproval, 'not-granted');
  assert.equal(nativeRepeatedProcessMetrics.productionMutation, false);
  assert.ok(nativeRepeatedProcessMetrics.logicalMappingSourceObservation.maxActiveReferences > 0 &&
    nativeRepeatedProcessMetrics.logicalMappingSourceObservation.cleanupActiveReferences === 0 &&
    nativeRepeatedProcessMetrics.logicalMappingSourceObservation.retiredTombstones > 0 &&
    nativeRepeatedProcessMetrics.logicalMappingSourceObservation.foreignRejections > 0 &&
    nativeRepeatedProcessMetrics.logicalMappingSourceObservation.replayRejections > 0 &&
    nativeRepeatedProcessMetrics.logicalMappingSourceObservation.staleRejections > 0);
  assert.equal(nativeRepeatedProcessMetrics.logicalMappingSourceObservation.syntheticOnly, true);
  assert.equal(nativeRepeatedProcessMetrics.logicalMappingSourceObservation.nativeBrowserRun, false);
  const serverProjectTiming = nativeEvidence.performanceEvidence.serverProjectTiming;
  assert.ok(serverProjectTiming.records > 0 &&
    Object.values(serverProjectTiming.scopes).some((count) => count > 0) &&
    Object.values(serverProjectTiming.channels).some((count) => count > 0));
  assert.ok(serverProjectTiming.elapsedMs.min >= 0 &&
    serverProjectTiming.elapsedMs.max >= serverProjectTiming.elapsedMs.min &&
    serverProjectTiming.elapsedMs.average >= serverProjectTiming.elapsedMs.min &&
    serverProjectTiming.elapsedMs.average <= serverProjectTiming.elapsedMs.max);
  assert.deepEqual(serverProjectTiming.keys.sort(),
    ['channel', 'elapsedMs', 'schemaVersion', 'scope']);
  assert.equal(serverProjectTiming.forbiddenMetadataKeysObserved, false);
  assert.equal(serverProjectTiming.cborSerializationIncluded, true);
  assert.equal(serverProjectTiming.scopes.serialize, 4);
  assert.equal(serverProjectTiming.productionMutation, false);
  const nativeCborSerializationTiming = nativeEvidence.performanceEvidence.nativeCborSerializationTiming;
  assert.ok(existsSync(path.join(repo, nativeCborSerializationTiming.artifact)),
    'native CBOR timing must reference a checked-in sanitized aggregate');
  assert.ok(nativeCborSerializationTiming.records > 0 &&
    nativeCborSerializationTiming.records <= nativeCborSerializationTiming.sampleCap &&
    Object.values(nativeCborSerializationTiming.scopes).some((count) => count > 0) &&
    Object.values(nativeCborSerializationTiming.channels).some((count) => count > 0));
  assert.ok(nativeCborSerializationTiming.elapsedNs.min >= 0 &&
    nativeCborSerializationTiming.elapsedNs.p50 >= nativeCborSerializationTiming.elapsedNs.min &&
    nativeCborSerializationTiming.elapsedNs.p95 >= nativeCborSerializationTiming.elapsedNs.p50 &&
    nativeCborSerializationTiming.elapsedNs.max >= nativeCborSerializationTiming.elapsedNs.p95 &&
    nativeCborSerializationTiming.elapsedNs.average >= nativeCborSerializationTiming.elapsedNs.min &&
    nativeCborSerializationTiming.elapsedNs.average <= nativeCborSerializationTiming.elapsedNs.max);
  assert.deepEqual(nativeCborSerializationTiming.keys.sort(),
    ['channel', 'elapsedNs', 'schemaVersion', 'scope', 'wireBytes']);
  assert.equal(nativeCborSerializationTiming.forbiddenMetadataKeysObserved, false);
  assert.equal(nativeCborSerializationTiming.productionMutation, false);

  assert.equal(matrix.latestNativeEvidence.runtimeMD5,
    'e0f37effc5a5d72d850b0ece7f29c4ef');
  assert.equal(matrix.latestNativeEvidence.qaPackageSha256,
    'dd64ca6c5031d32dd287b8f2a638541abe061569d75edd5770e20f591ba357d7');
  assert.equal(matrix.latestNativeEvidence.productionMutation, false);
  assert.ok(existsSync(path.join(repo, matrix.currentDrawReconnectEvidence.aggregate)),
    'coverage matrix must reference the current draw/reconnect aggregate');
  assert.ok(existsSync(path.join(repo, matrix.currentDrawReconnectEvidence.artifact)),
    'coverage matrix must reference the current draw/reconnect trace');
  assert.equal(matrix.currentDrawReconnectEvidence.result, 'PASS');
  assert.equal(matrix.currentDrawReconnectEvidence.strictPrivacyCategoriesObserved, 12);
  assert.equal(matrix.currentDrawReconnectEvidence.nativeAndSupplementalFailures, 0);
  assert.equal(matrix.currentDrawReconnectEvidence.recovered, true);
  assert.equal(matrix.currentDrawReconnectEvidence.gameOverAudiences, 3);
  assert.equal(matrix.currentDrawReconnectEvidence.releaseStatus, 'OPEN-HOLD');
  assert.equal(matrix.currentDrawReconnectEvidence.productionMutation, false);
  const currentDrawReconnect = JSON.parse(readFileSync(
    path.join(repo, matrix.currentDrawReconnectEvidence.aggregate), 'utf8')) as {
    result: string;
    recovered: boolean;
    identity: { runtimeMD5: string; qaPackageSha256: string };
  };
  assert.equal(currentDrawReconnect.result, 'PASS');
  assert.equal(currentDrawReconnect.recovered, true);
  assert.equal(currentDrawReconnect.identity.runtimeMD5, matrix.latestNativeEvidence.runtimeMD5);
  assert.equal(currentDrawReconnect.identity.qaPackageSha256,
    matrix.latestNativeEvidence.qaPackageSha256);

  assert.ok(existsSync(path.join(repo, matrix.currentRollbackEvidence.aggregate)),
    'coverage matrix must reference the current rollback aggregate');
  assert.equal(matrix.currentRollbackEvidence.sameRuntimeIdentity, true);
  assert.equal(matrix.currentRollbackEvidence.v1RunResult, 'PASS');
  assert.equal(matrix.currentRollbackEvidence.legacyRunResult, 'PASS');
  assert.equal(matrix.currentRollbackEvidence.legacyQaOverlayAbsent, true);
  assert.equal(matrix.currentRollbackEvidence.legacyCardWireNegotiatedInTrace, false);
  assert.equal(matrix.currentRollbackEvidence.candidateRollbackObserved, true);
  assert.equal(matrix.currentRollbackEvidence.productionCanaryRollback, 'OPEN');
  assert.equal(matrix.currentRollbackEvidence.productionMutation, false);
  const currentRollback = JSON.parse(readFileSync(
    path.join(repo, matrix.currentRollbackEvidence.aggregate), 'utf8')) as {
    identity: { runtimeMD5: string; qaPackageSha256: string };
    sameRuntimeIdentity: boolean;
    rollbackObserved: boolean;
    productionPolicy: { productionMutation: boolean };
  };
  assert.equal(currentRollback.identity.runtimeMD5, matrix.latestNativeEvidence.runtimeMD5);
  assert.equal(currentRollback.identity.qaPackageSha256, matrix.latestNativeEvidence.qaPackageSha256);
  assert.equal(currentRollback.sameRuntimeIdentity, true);
  assert.equal(currentRollback.rollbackObserved, true);
  assert.equal(currentRollback.productionPolicy.productionMutation, false);

  assert.ok(existsSync(path.join(repo, matrix.packetSizeComparison.artifact)),
    'coverage matrix must reference the current packet-size comparison');
  assert.equal(matrix.packetSizeComparison.status, 'OBSERVED_COMPARISON_PASS');
  assert.equal(matrix.packetSizeComparison.legacyRunResult, 'PASS');
  assert.equal(matrix.packetSizeComparison.v1RunResult, 'PASS');
  assert.equal(matrix.packetSizeComparison.legacyCardWireVersion, 0);
  assert.equal(matrix.packetSizeComparison.v1CardWireVersion, 1);
  assert.equal(matrix.packetSizeComparison.legacyAudiences, 2);
  assert.equal(matrix.packetSizeComparison.v1Audiences, 3);
  assert.equal(matrix.packetSizeComparison.v1StrictPrivacyCategories, 12);
  assert.equal(matrix.packetSizeComparison.legacyCaptureFailures, 0);
  assert.equal(matrix.packetSizeComparison.v1CaptureFailures, 0);
  assert.equal(matrix.packetSizeComparison.legacyRecovered, true);
  assert.equal(matrix.packetSizeComparison.v1Recovered, true);
  assert.equal(matrix.packetSizeComparison.thresholdStatus, 'OPEN');
  assert.equal(matrix.packetSizeComparison.productionMutation, false);
  assert.equal(matrix.packetSizeComparison.releaseDecision, 'OPEN-HOLD');
  const packetSizeComparison = JSON.parse(readFileSync(
    path.join(repo, matrix.packetSizeComparison.artifact), 'utf8')) as {
    status: string;
    identity: { runtimeMD5: string; qaPackageSha256: string };
    legacyRun: { result: string; recovered: boolean; cardWireVersion: number };
    v1Run: {
      result: string;
      recovered: boolean;
      cardWireVersion: number;
      strictPrivacyCategories: number;
      audiences: Array<{ failures: number }>;
    };
    interpretation: { thresholdStatus: string; productionPromotion: boolean };
  };
  assert.equal(packetSizeComparison.status, matrix.packetSizeComparison.status);
  assert.equal(packetSizeComparison.identity.runtimeMD5, matrix.latestNativeEvidence.runtimeMD5);
  assert.equal(packetSizeComparison.identity.qaPackageSha256,
    matrix.latestNativeEvidence.qaPackageSha256);
  assert.equal(packetSizeComparison.legacyRun.result, 'PASS');
  assert.equal(packetSizeComparison.legacyRun.recovered, true);
  assert.equal(packetSizeComparison.legacyRun.cardWireVersion, 0);
  assert.equal(packetSizeComparison.v1Run.result, 'PASS');
  assert.equal(packetSizeComparison.v1Run.recovered, true);
  assert.equal(packetSizeComparison.v1Run.cardWireVersion, 1);
  assert.equal(packetSizeComparison.v1Run.strictPrivacyCategories, 12);
  assert.equal(packetSizeComparison.v1Run.audiences.length, 3);
  assert.deepEqual(packetSizeComparison.v1Run.audiences.map(({ failures }) => failures), [0, 0, 0]);
  assert.equal(packetSizeComparison.interpretation.thresholdStatus, 'OPEN');
  assert.equal(packetSizeComparison.interpretation.productionPromotion, false);

  assert.ok(existsSync(path.join(repo, matrix.repeatedProcessEvidence.artifact)),
    'coverage matrix must reference the repeated process aggregate');
  assert.equal(matrix.repeatedProcessEvidence.runCount, 3);
  assert.equal(matrix.repeatedProcessEvidence.scenario, 'draw-sequence');
  assert.equal(matrix.repeatedProcessEvidence.allRunsPass, true);
  assert.ok(matrix.repeatedProcessEvidence.totalProcessSamples > 0 &&
    matrix.repeatedProcessEvidence.observedMaximumRssKb > 0 &&
    matrix.repeatedProcessEvidence.nativeWireRecords > 0 &&
    matrix.repeatedProcessEvidence.nativeCborSerializationTimingRecords > 0 &&
    matrix.repeatedProcessEvidence.serverTimingRecords > 0);
  assert.equal(matrix.repeatedProcessEvidence.logicalMappingSourceObservation.cleanupActiveReferences, 0);
  assert.equal(matrix.repeatedProcessEvidence.logicalMappingSourceObservation.syntheticOnly, true);
  assert.equal(matrix.repeatedProcessEvidence.logicalMappingSourceObservation.nativeBrowserRun, false);
  assert.equal(matrix.repeatedProcessEvidence.thresholdStatus, 'OPEN');
  assert.equal(matrix.repeatedProcessEvidence.mappingMemoryStatus, 'OPEN');
  assert.equal(matrix.repeatedProcessEvidence.releaseApproval, 'not-granted');
  assert.equal(matrix.repeatedProcessEvidence.productionMutation, false);
  assert.ok(existsSync(path.join(repo, matrix.rollbackEvidence.artifact)),
    'coverage matrix must reference the rollback aggregate');
  assert.equal(matrix.rollbackEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.rollbackEvidence.runtimeMD5, 'e40c8df7631c4907459ebb8321a7a921');
  assert.equal(matrix.rollbackEvidence.v1RunResult, 'PASS');
  assert.equal(matrix.rollbackEvidence.legacyRunResult, 'PASS');
  assert.equal(matrix.rollbackEvidence.sameRuntimeIdentity, true);
  assert.ok(matrix.rollbackEvidence.v1NegotiationPackets > 0);
  assert.equal(matrix.rollbackEvidence.legacyNegotiationPackets, 0);
  assert.equal(matrix.rollbackEvidence.legacyQaOverlayAbsent, true);
  assert.equal(matrix.rollbackEvidence.candidateRollbackObserved, true);
  assert.equal(matrix.rollbackEvidence.productionCanaryRollback, 'OPEN');
  assert.equal(matrix.rollbackEvidence.productionMutation, false);
  assert.ok(existsSync(path.join(repo, matrix.choiceEvidence.artifact)),
    'coverage matrix must reference the current choice aggregate');
  assert.equal(matrix.choiceEvidence.scenario, 'card-chosen');
  assert.equal(matrix.choiceEvidence.result, 'PASS');
  assert.equal(matrix.choiceEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.choiceEvidence.audiences, 3);
  assert.equal(matrix.choiceEvidence.hiddenAskForCardChosenObserved, true);
  assert.equal(matrix.choiceEvidence.opaqueCardChosenReplyObserved, true);
  assert.equal(matrix.choiceEvidence.nativeWireFailures, 0);
  assert.equal(matrix.choiceEvidence.supplementalFailures, 0);
  assert.equal(matrix.choiceEvidence.productionMutation, false);
  assert.equal(matrix.choiceEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.cardsAndChoiceEvidence.artifact)),
    'coverage matrix must reference the current cards-and-choice aggregate');
  assert.equal(matrix.cardsAndChoiceEvidence.scenario, 'cards-and-choice');
  assert.equal(matrix.cardsAndChoiceEvidence.result, 'PASS');
  assert.equal(matrix.cardsAndChoiceEvidence.qaPackageSha256,
    '1fb4741116440ef9629e02c8c0505aeb599448cff5b93e8af686407e06403258');
  assert.equal(matrix.cardsAndChoiceEvidence.audiences, 3);
  assert.equal(matrix.cardsAndChoiceEvidence.cardsAndChoiceReplyObserved, true);
  assert.equal(matrix.cardsAndChoiceEvidence.nativeWireFailures, 0);
  assert.equal(matrix.cardsAndChoiceEvidence.supplementalFailures, 0);
  assert.equal(matrix.cardsAndChoiceEvidence.productionMutation, false);
  assert.equal(matrix.cardsAndChoiceEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.fankuiEvidence.artifact)),
    'coverage matrix must reference the current Fankui aggregate');
  assert.equal(matrix.fankuiEvidence.scenario, 'hidden-fankui');
  assert.equal(matrix.fankuiEvidence.deputyScenario, 'hidden-fankui-deputy');
  assert.equal(matrix.fankuiEvidence.result, 'PASS');
  assert.equal(matrix.fankuiEvidence.qaPackageSha256,
    'ddc9da1dd8870260da852ac192b76f3fcebe0d6c83a8b3fdc23a1f2a41f34769');
  assert.equal(matrix.fankuiEvidence.audiences, 3);
  assert.equal(matrix.fankuiEvidence.mainAndDeputyRunsPass, true);
  assert.equal(matrix.fankuiEvidence.fankuiDamageReplyObserved, true);
  assert.equal(matrix.fankuiEvidence.fankuiCardChosenReplyObserved, true);
  assert.equal(matrix.fankuiEvidence.nativeWireFailures, 0);
  assert.equal(matrix.fankuiEvidence.supplementalFailures, 0);
  assert.equal(matrix.fankuiEvidence.showCardObserved, false);
  assert.equal(matrix.fankuiEvidence.showVirtualCardObserved, false);
  assert.equal(matrix.fankuiEvidence.productionMutation, false);
  assert.equal(matrix.fankuiEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.fanjianEvidence.artifact)),
    'coverage matrix must reference the current Fanjian aggregate');
  assert.equal(matrix.fanjianEvidence.scenario, 'hidden-fanjian');
  assert.equal(matrix.fanjianEvidence.deputyScenario, 'hidden-fanjian-deputy');
  assert.equal(matrix.fanjianEvidence.result, 'PASS');
  assert.equal(matrix.fanjianEvidence.qaPackageSha256,
    'a7934505b01c73c7ef2c67f974f7c89bda67ee19a352026e39b46c14dd59db80');
  assert.equal(matrix.fanjianEvidence.audiences, 3);
  assert.equal(matrix.fanjianEvidence.mainAndDeputyRunsPass, true);
  assert.equal(matrix.fanjianEvidence.showCardObserved, true);
  assert.equal(matrix.fanjianEvidence.showVirtualCardObserved, false);
  assert.equal(matrix.fanjianEvidence.nativeWireFailures, 0);
  assert.equal(matrix.fanjianEvidence.supplementalFailures, 0);
  assert.equal(matrix.fanjianEvidence.productionMutation, false);
  assert.equal(matrix.fanjianEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.virtualCardEvidence.artifact)),
    'coverage matrix must reference the current ShowVirtualCard aggregate');
  assert.equal(matrix.virtualCardEvidence.scenario, 'hidden-reveal');
  assert.equal(matrix.virtualCardEvidence.deputyScenario, 'hidden-reveal-deputy');
  assert.equal(matrix.virtualCardEvidence.result, 'PASS');
  assert.equal(matrix.virtualCardEvidence.qaPackageSha256,
    'dd64ca6c5031d32dd287b8f2a638541abe061569d75edd5770e20f591ba357d7');
  assert.equal(matrix.virtualCardEvidence.audiences, 3);
  assert.equal(matrix.virtualCardEvidence.mainAndDeputyRunsPass, true);
  assert.equal(matrix.virtualCardEvidence.hiddenDuoshiInvoked, true);
  assert.equal(matrix.virtualCardEvidence.showVirtualCardObserved, true);
  assert.equal(matrix.virtualCardEvidence.showVirtualCardCount, 6);
  assert.equal(matrix.virtualCardEvidence.nativeSupplementalFailures, 0);
  assert.equal(matrix.virtualCardEvidence.productionMutation, false);
  assert.equal(matrix.virtualCardEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.poxiEvidence.artifact)),
    'coverage matrix must reference the current Poxi aggregate');
  assert.equal(matrix.poxiEvidence.scenario, 'poxi');
  assert.equal(matrix.poxiEvidence.result, 'PASS');
  assert.equal(matrix.poxiEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.poxiEvidence.audiences, 3);
  assert.equal(matrix.poxiEvidence.multiCardPoxiReplyObserved, true);
  assert.equal(matrix.poxiEvidence.nativeWireFailures, 0);
  assert.equal(matrix.poxiEvidence.supplementalFailures, 0);
  assert.equal(matrix.poxiEvidence.productionMutation, false);
  assert.equal(matrix.poxiEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.arrangeEvidence.artifact)),
    'coverage matrix must reference the current ArrangeCards aggregate');
  assert.ok(existsSync(path.join(repo, matrix.arrangeEvidence.deputyArtifact)),
    'coverage matrix must reference current ArrangeCards deputy evidence');
  assert.equal(matrix.arrangeEvidence.scenario, 'hidden-guanxing');
  assert.equal(matrix.arrangeEvidence.result, 'PASS');
  assert.equal(matrix.arrangeEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.arrangeEvidence.audiences, 3);
  assert.equal(matrix.arrangeEvidence.arrangeCardsReplyObserved, true);
  assert.equal(matrix.arrangeEvidence.nativeWireFailures, 0);
  assert.equal(matrix.arrangeEvidence.supplementalFailures, 0);
  assert.equal(matrix.arrangeEvidence.deputyResult, 'PASS');
  assert.equal(matrix.arrangeEvidence.deputySlotObserved, true);
  assert.equal(matrix.arrangeEvidence.deputyArrangeCardsReplyObserved, true);
  assert.equal(matrix.arrangeEvidence.deputyCleanupObserved, true);
  assert.equal(matrix.arrangeEvidence.productionMutation, false);
  assert.equal(matrix.arrangeEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.rehideEvidence.artifact)),
    'coverage matrix must reference the current hidden-rehide aggregate');
  assert.ok(existsSync(path.join(repo, matrix.rehideEvidence.deputyArtifact)),
    'coverage matrix must reference current hidden-rehide deputy evidence');
  assert.equal(matrix.rehideEvidence.scenario, 'hidden-rehide-yiji');
  assert.equal(matrix.rehideEvidence.result, 'PASS');
  assert.equal(matrix.rehideEvidence.qaPackageSha256,
    'dd64ca6c5031d32dd287b8f2a638541abe061569d75edd5770e20f591ba357d7');
  assert.equal(matrix.rehideEvidence.audiences, 3);
  assert.equal(matrix.rehideEvidence.hiddenYijiInvoked, true);
  assert.equal(matrix.rehideEvidence.retainedPrelightObserved, true);
  assert.equal(matrix.rehideEvidence.nativeWireFailures, 0);
  assert.equal(matrix.rehideEvidence.supplementalFailures, 0);
  assert.equal(matrix.rehideEvidence.deputyResult, 'PASS');
  assert.equal(matrix.rehideEvidence.deputySlotObserved, true);
  assert.equal(matrix.rehideEvidence.deputyCleanupObserved, true);
  assert.equal(matrix.rehideEvidence.productionMutation, false);
  assert.equal(matrix.rehideEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.luoshenEvidence.artifact)),
    'coverage matrix must reference the current hidden-luoshen aggregate');
  assert.equal(matrix.luoshenEvidence.scenario, 'hidden-luoshen');
  assert.equal(matrix.luoshenEvidence.result, 'PASS');
  assert.equal(matrix.luoshenEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.luoshenEvidence.audiences, 3);
  assert.equal(matrix.luoshenEvidence.hiddenLuoshenInvoked, true);
  assert.equal(matrix.luoshenEvidence.hiddenLuoshenAgReplyObserved, true);
  assert.equal(matrix.luoshenEvidence.nativeWireFailures, 0);
  assert.equal(matrix.luoshenEvidence.supplementalFailures, 0);
  assert.equal(matrix.luoshenEvidence.productionMutation, false);
  assert.equal(matrix.luoshenEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.luoshenDeputyEvidence.artifact)),
    'coverage matrix must reference current hidden-luoshen deputy evidence');
  assert.equal(matrix.luoshenDeputyEvidence.scenario, 'hidden-luoshen-deputy');
  assert.equal(matrix.luoshenDeputyEvidence.result, 'PASS');
  assert.equal(matrix.luoshenDeputyEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.luoshenDeputyEvidence.audiences, 3);
  assert.equal(matrix.luoshenDeputyEvidence.hiddenLuoshenInvoked, true);
  assert.equal(matrix.luoshenDeputyEvidence.hiddenLuoshenAgReplyObserved, true);
  assert.equal(matrix.luoshenDeputyEvidence.deputySlotObserved, true);
  assert.equal(matrix.luoshenDeputyEvidence.nativeWireFailures, 0);
  assert.equal(matrix.luoshenDeputyEvidence.supplementalFailures, 0);
  assert.equal(matrix.luoshenDeputyEvidence.cleanupObserved, true);
  assert.equal(matrix.luoshenDeputyEvidence.productionMutation, false);
  assert.equal(matrix.luoshenDeputyEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.revealEvidence.artifact)),
    'coverage matrix must reference the current hidden-reveal aggregate');
  assert.ok(existsSync(path.join(repo, matrix.revealEvidence.deputyArtifact)),
    'coverage matrix must reference current hidden-reveal deputy evidence');
  assert.equal(matrix.revealEvidence.scenario, 'hidden-reveal');
  assert.equal(matrix.revealEvidence.result, 'PASS');
  assert.equal(matrix.revealEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.revealEvidence.audiences, 3);
  assert.equal(matrix.revealEvidence.activeRevealRequestOwnerOnly, true);
  assert.equal(matrix.revealEvidence.activeRevealReplyObserved, true);
  assert.equal(matrix.revealEvidence.nativeWireFailures, 0);
  assert.equal(matrix.revealEvidence.supplementalFailures, 0);
  assert.equal(matrix.revealEvidence.deputyResult, 'PASS');
  assert.equal(matrix.revealEvidence.deputySlotObserved, true);
  assert.equal(matrix.revealEvidence.deputyOwnerOnlyActiveRequestObserved, true);
  assert.equal(matrix.revealEvidence.deputyCleanupObserved, true);
  assert.equal(matrix.revealEvidence.productionMutation, false);
  assert.equal(matrix.revealEvidence.releaseStatus, 'OPEN-HOLD');
  assert.ok(existsSync(path.join(repo, matrix.mappingEvidence.artifact)),
    'coverage matrix must reference the native mapping aggregate');
  assert.ok(existsSync(path.join(repo, matrix.mappingEvidence.repeatedArtifact)),
    'coverage matrix must reference repeated native mapping evidence');
  assert.equal(matrix.mappingEvidence.scenario, 'draw-sequence');
  assert.equal(matrix.mappingEvidence.result, 'PASS');
  assert.equal(matrix.mappingEvidence.qaPackageSha256,
    '63a4b426bf1ed6e0e724be0ca361d093251a7ac61373b4a9880f34735447e3f9');
  assert.equal(matrix.mappingEvidence.audiences, 3);
  assert.equal(matrix.mappingEvidence.strictPrivacyCategoriesObserved, 12);
  assert.equal(matrix.mappingEvidence.nativeWireFailures, 0);
  assert.equal(matrix.mappingEvidence.supplementalFailures, 0);
  assert.ok(matrix.mappingEvidence.maxActiveReferences > 0);
  assert.equal(matrix.mappingEvidence.finalActiveReferences, 0);
  assert.equal(matrix.mappingEvidence.finalAudiences, 0);
  assert.equal(matrix.mappingEvidence.cleanupObserved, true);
  assert.equal(matrix.mappingEvidence.repeatedRunCount, 2);
  assert.equal(matrix.mappingEvidence.repeatedAllRunsPass, true);
  assert.equal(matrix.mappingEvidence.repeatedAllRunsCleanupObserved, true);
  assert.equal(matrix.mappingEvidence.productionMutation, false);
  assert.equal(matrix.mappingEvidence.releaseStatus, 'OPEN-HOLD');
  assert.deepEqual(Object.keys(nativeEvidence.strictPrivacyCategoryCounts).sort(),
    [...PRIVACY_CATEGORIES].sort());
  for (const category of PRIVACY_CATEGORIES) {
    assert.ok(nativeEvidence.strictPrivacyCategoryCounts[category] > 0,
      `native evidence must observe a positive count for ${category}`);
  }

  assert.equal(matrix.strictPrivacyCategories.length, PRIVACY_CATEGORIES.length);
  assert.deepEqual(matrix.strictPrivacyCategories.map(({ id }) => id), [...PRIVACY_CATEGORIES]);
  assert.equal(new Set(matrix.strictPrivacyCategories.map(({ id }) => id)).size,
    matrix.strictPrivacyCategories.length, 'strict category IDs must be unique');
  const strictAudiences = new Set<string>();
  for (const [index, row] of matrix.strictPrivacyCategories.entries()) {
    assertRow(row, `strictPrivacyCategories[${index}]`);
    for (const audience of row.audiences) strictAudiences.add(audience);
    assert.match(row.status, /release-open/u);
  }
  assert.deepEqual([...strictAudiences].sort(), ['observer', 'opponent', 'owner']);

  assert.ok(matrix.supplementalChannels.length >= 5);
  assert.equal(new Set(matrix.supplementalChannels.map(({ id }) => id)).size,
    matrix.supplementalChannels.length, 'supplemental channel IDs must be unique');
  for (const [index, row] of matrix.supplementalChannels.entries()) {
    assertRow(row, `supplementalChannels[${index}]`);
    assert.match(row.status, /open/u);
  }
});

test('card-wire P0 matrix contains no raw identity or credential material', () => {
  const serialized = readFileSync(matrixPath, 'utf8');
  assert.doesNotMatch(serialized, /(?:password|credential|token|secret|private[_ -]?key)\s*[:=]/iu);
  assert.doesNotMatch(serialized, /(?:card[_ -]?id|physical[_ -]?id|target[_ -]?id)\s*[:=]\s*\d+/iu);
  assert.doesNotMatch(serialized, /h:[A-Za-z0-9_-]{18,}/u);
});

test('card-wire identity audit separates current release evidence from historical package evidence', () => {
  const auditPath = path.join(repo, 'docs/web-client/CARD_WIRE_ARTIFACT_IDENTITY_AUDIT_2026-11-16.json');
  const audit = JSON.parse(readFileSync(auditPath, 'utf8')) as {
    runtimeIdentities: {
      historicalLocalReleasePackage: { runtimeMd5: string };
      nativeDrawReconnectCurrent: { runtimeMd5: string };
      localReleasePackageCurrent: { runtimeMd5: string };
    };
    checks: {
      releasePackageRuntimeMatchesNativeCandidateRuntime: boolean;
      historicalReleasePackageRuntimeMatchesNativeCandidateRuntime: boolean;
      freshNativeMatchesCurrentReleasePackage: boolean;
      currentBrowserE2eMatchesCurrentReleasePackage: boolean;
    };
    decision: { status: string; publishEligible: boolean };
  };
  assert.notEqual(audit.runtimeIdentities.historicalLocalReleasePackage.runtimeMd5,
    audit.runtimeIdentities.nativeDrawReconnectCurrent.runtimeMd5);
  assert.equal(audit.runtimeIdentities.localReleasePackageCurrent.runtimeMd5,
    audit.runtimeIdentities.nativeDrawReconnectCurrent.runtimeMd5);
  assert.equal(audit.checks.releasePackageRuntimeMatchesNativeCandidateRuntime, true);
  assert.equal(audit.checks.historicalReleasePackageRuntimeMatchesNativeCandidateRuntime, false);
  assert.equal(audit.checks.freshNativeMatchesCurrentReleasePackage, true);
  assert.equal(audit.checks.currentBrowserE2eMatchesCurrentReleasePackage, true);
  assert.equal(audit.decision.status, 'HOLD-RELEASE-GATES');
  assert.equal(audit.decision.publishEligible, false);
});

test('native observer leave is opt-in, draw-sequence-only and fail-closed', () => {
  const runnerPath = path.join(repo, 'game/web/scripts/multiplayer-e2e/run.ts');
  const runner = readFileSync(runnerPath, 'utf8');
  assert.match(runner, /TQS_LIVE_CARD_WIRE_OBSERVER_LEAVE/u);
  assert.match(runner, /observerLeaveRequested/u);
  assert.match(runner, /testScenario === 'draw-sequence'/u);
  assert.match(runner, /Install the transport harness on every live QA page/u);
  assert.match(runner, /__tqsTestDisconnect/u);
  assert.match(runner, /transportOpen\[2\] !== false/u);
  assert.match(runner, /readNativeMappingDisconnectCount/u);
  assert.match(runner, /cardWireObserverLeaveObserved/u);
  assert.match(runner, /cardWireObserverLeaveNativeDisconnect/u);
  assert.match(runner, /const gameOverTraces = observerLeaveRequested \? traces\.slice\(0, 2\) : traces/u);
});

test('native replay probe is opt-in, v1 draw-sequence-only and bounded', () => {
  const runnerPath = path.join(repo, 'game/web/scripts/multiplayer-e2e/run.ts');
  const runner = readFileSync(runnerPath, 'utf8');
  assert.match(runner, /TQS_LIVE_CARD_WIRE_REPLAY/u);
  assert.match(runner, /cardWireReplayRequested/u);
  assert.match(runner, /__tqsTestReplayLastReply/u);
  assert.match(runner, /routeWebSocket/u);
  assert.match(runner, /rewriteReplayRequestId/u);
  assert.match(runner, /cardWireReplaySent/u);
  assert.match(runner, /choiceRejects/u);
  assert.match(runner, /cardWireReplayRejectObserved/u);
  assert.match(runner, /cardWireReplayRejectCount/u);
  assert.match(runner, /process\.env\.TQS_LIVE_LEGACY_ONLY !== '1'/u);
});

test('native rollback drain probe is opt-in, reconnect-only and fail-closed', () => {
  const runnerPath = path.join(repo, 'game/web/scripts/multiplayer-e2e/run.ts');
  const runner = readFileSync(runnerPath, 'utf8');
  assert.match(runner, /TQS_LIVE_CARD_WIRE_ROLLBACK_DRAIN/u);
  assert.match(runner, /TQS_LIVE_CARD_WIRE_PRIVACY === '1'/u);
  assert.match(runner, /cardWireRollbackMarkerBaseline/u);
  assert.match(runner, /readNativeCardWireRollbackSummary/u);
  assert.match(runner, /cardWireRollbackDrainObserved/u);
  assert.match(runner, /CardWireNegotiated.*length >= 2/su);
  assert.match(runner, /!process\.argv\.includes\('--restart-gateway'\)/u);
});
