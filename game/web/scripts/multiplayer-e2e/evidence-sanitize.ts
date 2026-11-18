import { PRIVACY_CATEGORIES, SUPPLEMENTAL_CHANNELS } from './native-privacy';

/** The two-client runner retains raw UI state in memory for assertions.
 * Evidence exported to disk must be limited to known public QA markers and
 * bounded diagnostic metadata. Treat the browser as an untrusted text source. */

const SAFE_DETAIL = new Set([
  'delta-wenji-target-gives-slash', 'delta-wenji-use-transferred-slash',
  'delta-chujue-control-faction-slash', 'delta-chujue-dead-faction-slash',
  'delta-chujue-control-faction-slash-card', 'delta-chujue-dead-faction-slash-card',
  'delta-bawei-control-slash', 'delta-bawei-damaged-slash',
  'delta-bawei-control-slash-card', 'delta-bawei-damaged-slash-card',
  'delta-fengshi-first-slash', 'delta-fengshi-first-slash-card',
  'delta-zhente-readiness-gate', 'delta-zhente-black-slash-semantic-active-skill',
  'delta-zhente-black-slash-semantic-card-target', 'delta-zhente-negate-choice',
  'delta-halberd-readiness-gate', 'delta-halberd-first-slash-semantic-active-skill',
  'delta-halberd-extra-target-semantic-active-skill', 'delta-halberd-close-unrelated-active-skill',
  'delta-sijian-readiness-gate', 'delta-sijian-choose-target',
  'delta-sijian-select-target-card', 'delta-sijian-close-pre-gate-active-skill',
  'delta-jianchu-slash-semantic-active-skill', 'delta-jianchu-slash-semantic-card-target',
  'delta-qiance-duel-semantic-active-skill', 'delta-qiance-duel-semantic-card-target',
  'delta-qiance-duel', 'delta-qiance-duel-play-card', 'delta-qiance-close-stale-play-card',
  'delta-jianchu-select-equipment', 'delta-xishe-weapon-discard',
]);
// Runtime package names are public, pinned release components. A regex-only
// filter could mistakenly persist a private value shaped like a package name.
const SAFE_PACKAGES = new Set([
  'freekill-core', 'gamemode', 'hegemony', 'jsrg', 'maneuvering', 'mobile',
  'mougong', 'ol', 'overseas', 'shzl', 'sp', 'standard_cards', 'standard_ex',
  'tenyear', 'utility', 'yj',
]);
const SAFE_COMMAND = /^[A-Za-z][A-Za-z0-9_]{0,79}$/u;
// Enumerate fields from the server-issued Lua sendLog templates. A previous
// permissive marker regex could include untrusted text in the skill label.
const UPSTREAM_FIELDS: Record<string, readonly string[]> = {
  '铁骑': ['judge_discard_cancelled', 'response_blocked', 'target_jink_retained', 'damage'],
  '凶算': ['ActiveSkillOnUse', 'chọn bài', 'gây sát thương', 'rút ba', 'reset limited'],
  '问计': ['phase_handoff', 'slash_used', 'target_response_blocked', 'target_jink_retained'],
  'lord_ex 问计': ['phase_handoff', 'slash_disresponsive', 'target_jink_retained', 'different_card_returned'],
  '谦策': ['card_using', 'skill_effect', 'target_big_kingdom', 'response_blocked', 'target_slash_retained'],
  '鞬出': ['target_equipment_discarded', 'response_blocked', 'target_jink_retained', 'damage'],
  '袭射': ['lower_hp_blocked', 'target_jink_retained', 'equal_hp_allowed', 'control_responded', 'equip_discarded', 'damage'],
  '霸威': ['round_damage_recorded', 'damaged_response_blocked', 'damaged_jink_retained', 'control_responded', 'damage'],
  '锋矢': ['first_use', 'siege_relation', 'response_blocked', 'target_jink_retained', 'target_responded'],
  '除绝': ['dead_kingdom_response_blocked', 'target_jink_retained', 'control_response_allowed', 'control_responded', 'damage'],
  '贞特': ['target_confirmed', 'target_response_blocked', 'choice_negate', 'damage'],
  '方天画戟': ['first_target_confirmed', 'extra_target_confirmed', 'targets_added', 'damage'],
  '死谏': ['owner_empty_after_hand_loss', 'target_confirmed', 'target_card_discarded'],
};
function safeUpstreamMarker(log: string): boolean {
  const match = /^\[TQS QA\] Upstream ([^:\n]{1,32}): (.+)$/u.exec(log);
  if (!match || log.length > 700) return false;
  const fields = UPSTREAM_FIELDS[match[1]];
  if (!fields) return false;
  const entries = match[2].split('; ');
  return entries.length === fields.length && entries.every((entry, index) => {
    const separator = entry.indexOf('=');
    return separator > 0 && entry.slice(0, separator) === fields[index]
      && /^(?:true|false|[0-9]{1,12})$/u.test(entry.slice(separator + 1));
  });
}
// General-pair telemetry comes from a bounded server-only fixture. Validate
// its complete emitted schema before exporting it. In particular, do not
// persist arbitrary `reason`, `detail`, player, card or general text.
const PAIR_FIELDS: Record<string, readonly string[]> = {
  PairOfferSummary: ['scenario', 'roster_set', 'seat_swap', 'offer_count', 'seat_count', 'seats'],
  PairDecisionSummary: ['scenario', 'seed', 'roster_set', 'seat_swap', 'decisions', 'accepted', 'fallback', 'invalid', 'overflow'],
  PairDecisionStats: ['scenario', 'seed', 'roster_set', 'seat_swap', 'latency_n', 'latency_sum_ms', 'latency_min_ms', 'latency_p50_ms', 'latency_p95_ms'],
  PairDecisionTrace: ['scenario', 'seed', 'roster_set', 'seat_swap', 'latency_max_ms', 'trace_hash', 'reasons'],
  PairDecision: ['scenario', 'seed', 'roster_set', 'seat_swap', 'seq', 'seat', 'input', 'output_hash', 'valid'],
  PairDecisionMeta: ['scenario', 'seed', 'roster_set', 'seat_swap', 'seq', 'reason', 'detail', 'elapsed_ms'],
  PairMatchResult: ['scenario', 'seed', 'roster_set', 'seat_swap', 'winner_seats', 'winner_kingdoms', 'winner_count', 'outcome'],
};
const PAIR_INTEGER_FIELDS = new Set(['seed', 'offer_count', 'seat_count', 'decisions', 'accepted',
  'fallback', 'invalid', 'latency_n', 'seq', 'seat', 'winner_count']);
const PAIR_DECIMAL_FIELDS = new Set(['latency_sum_ms', 'latency_min_ms', 'latency_p50_ms',
  'latency_p95_ms', 'latency_max_ms', 'elapsed_ms']);
const PAIR_HASH_FIELDS = new Set(['input', 'output_hash', 'trace_hash']);
// Known source-level SmartAI and Base.AI fallback/validation categories.
const PAIR_REASON = /^(?:accepted|fallback|no_decision|no_strategy|ai_exception|none|invalid|validation_failed|no_reply|unknown|invalid_strategy_reply|malformed_data|malformed_prompt|illegal_reply|feasibility_rejected|invalid_details)$/u;
function safePairField(key: string, value: string): boolean {
  if (key === 'scenario') return /^general-pair-[a-z0-9-]{1,64}$/u.test(value);
  if (key === 'roster_set') return /^(?:fixed|r[1-4])$/u.test(value);
  if (key === 'seat_swap') return /^(?:fixed|[A-D])$/u.test(value);
  if (PAIR_INTEGER_FIELDS.has(key)) return /^(?:0|[1-9][0-9]{0,11})$/u.test(value);
  if (PAIR_DECIMAL_FIELDS.has(key)) return /^(?:0|[1-9][0-9]{0,8})(?:\.[0-9]{1,6})?$/u.test(value);
  if (PAIR_HASH_FIELDS.has(key)) return /^[a-f0-9]{8}$/u.test(value);
  if (key === 'overflow' || key === 'valid') return /^(?:true|false)$/u.test(value);
  if (key === 'seats' || key === 'winner_seats') return value === 'draw' || /^(?:[1-9][0-9]?,){0,9}[1-9][0-9]?$/u.test(value);
  if (key === 'winner_kingdoms') return value === 'draw' ||
    /^(?:[1-9][0-9]?:)(?:wei|shu|wu|qun|jin|wild|ye|careerist|unknown)(?:,[1-9][0-9]?:(?:wei|shu|wu|qun|jin|wild|ye|careerist|unknown)){0,9}$/u.test(value);
  if (key === 'outcome') return /^(?:win|draw)$/u.test(value);
  if (key === 'reason' || key === 'detail') return PAIR_REASON.test(value);
  if (key === 'reasons') return value === '' || value.split(',').every((part) => {
    const [reason, number, ...extra] = part.split(':');
    return extra.length === 0 && PAIR_REASON.test(reason) && /^(?:0|[1-9][0-9]{0,5})$/u.test(number);
  });
  return false;
}
function safePairMarker(log: string): boolean {
  const match = /^\[TQS QA\] (Pair[A-Za-z]+) (.+)$/u.exec(log);
  if (!match || log.length > 1500) return false;
  const fields = PAIR_FIELDS[match[1]];
  if (!fields) return false;
  const pieces = match[2].split(' ');
  if (pieces.length !== fields.length) return false;
  return pieces.every((piece, index) => {
    const separator = piece.indexOf('=');
    return separator > 0 && piece.slice(0, separator) === fields[index]
      && safePairField(fields[index], piece.slice(separator + 1));
  });
}
// Exported object keys are an explicit snapshot of the runner's evidence schema.
// Unknown keys (including untrusted dynamic object keys) are never persisted.
const SAFE_EVIDENCE_KEYS = new Set(`
  armorReply arrange askForChoices askForResponseCard askForUseActiveSkill askForUseCard at
  boardPlayers botAudit botNames botSkillLogs callbacksActive callbacksPeak callbacksTotal
  bundleHash cancelReply candidateId candidateIdentity card cardChosen cardReply cardUsing cardWireObserverMode
  cardWireObserverRejected cardWireObserverObservePackets cardWireObserverLeaveRequested
  cardWireObserverLeaveObserved cardWireObserverLeaveNativeDisconnect
  cardWireReplayRequested cardWireReplayInjected cardWireReplaySent cardWireReplayRejectObserved cardWireReplayRejectCount
  cardWireRollbackDrainRequested cardWireRollbackDrainObserved
  cardWirePlayerMode cardWirePlayerRejected
  cardWirePlayerCapabilityDrops cardWirePlayerErrorPackets cardWirePlayerIndex
  cardWirePlayerNegotiatedPackets catalogSha256
  cardWireEntropyFailure cardWireEntropyFailureObserved cardWireEntropyFailureKind
  cardWireEntropyNegotiatedPackets cardWireEntropyCardBearingPackets
  cardWireEntropyBatchAborts cardWireEntropyBatchCommits
  cardWireEntropyLastAbortActiveReferences cardWireEntropyLastAbortActiveRequests
  choice choiceReply choose command controlFactionUseReply controlUseReply damage damageExchange
  damagedUseReply deadFactionUseReply decisionSummary decisions deploymentUrl deputy direction
  discard discardAuto distIndexSha256 elapsedMs errorContexts errors feedback gameOver gate
  gateReply gatewayRestart hiddenActive hiddenActiveGateReply hiddenActiveReply hiddenDual
  hiddenDualChooseReply hiddenDualDiscardAuto hiddenDualDiscardReply hiddenDualGateReply
  hiddenDualUseReply hiddenDuanchang hiddenDuanchangChoiceReply hiddenDuanchangGateReply
  hiddenEnyuan hiddenEnyuanCardReply hiddenEnyuanGateReply hiddenFanjian hiddenFanjianChoiceReply
  hiddenFanjianGateReply hiddenFanjianReply hiddenFankui hiddenFankuiChoiceReply
  hiddenFankuiDamageReply hiddenFankuiGateReply hiddenFuyin hiddenFuyinCardReply
  hiddenFuyinGateReply hiddenGateReply hiddenGongqing hiddenGongqingGateReply hiddenGuanxing
  hiddenGuanxingArrangeReply hiddenGuanxingGateReply hiddenGuanxingInvoked hiddenJianxiong
  hiddenJianxiongChoiceReply hiddenJianxiongDamageReply hiddenJianxiongGateReply
  hiddenJianxiongInvoked hiddenJianzhiDamageReply hiddenJianzhiGateReply hiddenJianzhiInvoked
  hiddenJilix hiddenJilixCardReply hiddenJilixGateReply hiddenJizhi hiddenJizhiCardReply
  hiddenJizhiGateReply hiddenJizhiInvoked hiddenKongcheng hiddenKongchengCardReply
  hiddenKongchengGateReply hiddenLuoshen hiddenLuoshenAgReply hiddenLuoshenGateReply hiddenLuoshenInvokeCount
  hiddenLuoshenInvoked hiddenMingshi hiddenMingshiCardReply hiddenMingshiGateReply hiddenQianxun
  hiddenQianxunCardReply hiddenQianxunGateReply hiddenReveal hiddenRevealGateReply
  hiddenRevealReply hiddenDuoshiInvoked hiddenTiandu hiddenTianduGateReply hiddenTianxiang hiddenTianxiangCardReply
  hiddenTianxiangChoiceReply hiddenTianxiangGateReply hiddenTianxiangInvoked hiddenWeimu
  hiddenWeimuCardReply hiddenWeimuGateReply hiddenXiaoji hiddenXiaojiCardReply
  hiddenXiaojiGateReply hiddenYiji hiddenYijiAsked hiddenYijiInvoked hiddenYijiMode hiddenYijiReply
  hiddenZhimanCardReply hiddenZhimanDamageReply hiddenZhimanGateReply hiddenZhimanInvoked
  fileCount indulgence invokeCount invokeReply invoked localPackages localServerOnlyPackages logs luaHeapKiB
  luaTelemetry manifestPath manifestSha256 manualCardReply matchResult
  md5 memoryAllocationDiagnosticCounts mode nativeBotSeats nativeQaGateCommand
  nativeQaGateFailureObserved nativeQaGateSeen nativeQaGateTimeoutMs observations offerSummary
  outcome packageSha256 playCard playerReply public qaPackageIdentity qaSmartAiOverlaySha256
  qaSourceIdentity realClientSeats recovered releaseManifestPath releaseManifestSha256 reply
  replyCount requestId responseRequests result returnReply roomLuaSha256 rosterSet runtimeMD5
  sampleCount sampleErrors samples scenario scenarioActiveSkillReply scenarioBattleRoyalObserved
  scenarioBawei scenarioBaweiScope scenarioBoardStates scenarioCardChosenHidden
  scenarioCardChosenReply scenarioCardsAndChoiceReply scenarioChujue scenarioChujueScope
  scenarioZhente scenarioZhenteScope scenarioHalberd scenarioHalberdScope scenarioSijian scenarioSijianScope
  scenarioClient scenarioEnyuanReply scenarioFankuiInvoked scenarioFankuiReply scenarioFengshi
  scenarioFengshiScope scenarioFoundingReply scenarioJianchu scenarioJianchuScope
  scenarioLongdanAttackReply scenarioLongdanDefenseReply scenarioLordWenji scenarioLordWenjiScope
  scenarioObservations scenarioPoxiMultiple scenarioPoxiReply scenarioQiance scenarioQianceScope
  scenarioRescueBlocked scenarioRescuePeach scenarioRescueReply scenarioSlashReplies
  scenarioViewAsReply scenarioWenji scenarioWenjiScope scenarioXishe scenarioXisheScope
  scenarioYijiInvoked scenarioYijiReply targetReply scope seatCapacity seatSwap seed skillEffect skillLogs
  slashReply smartAiSha256 sourceRevision status trace traces turn type useReply variant viewAs
  wasmBytes weaponReply winnerCount winnerKingdoms winnerSeats winningKingdoms
  remoteGatewayManifest remoteIndexSha256 packages nativeDeckPrivacy nativeWireCapture nativeSupplementalCapture
  nativePacketSizeCapture
  nativeSemanticCapture
  nativeProcessMetrics
`.trim().split(/\s+/u).concat(['memoryStacks']));
const SAFE_HEX = /^(?:[a-fA-F0-9]{32}|[a-fA-F0-9]{40}|[a-fA-F0-9]{64})$/u;
const SAFE_SCENARIO = /^(?:draw-sequence|card-chosen|cards-and-choice|poxi|rescue-normal|rescue-battle|delta|hidden|cp|pair|gateway|reconnect|damage|native|bot|founding)[-a-z0-9]{0,80}$/u;
const SAFE_STRING_VALUES = new Set(['PASS', 'FAIL', 'incoming', 'outgoing', 'win', 'draw',
  'manual', 'main', 'deputy', 'normal', 'abort', 'allowed', 'blocked']);
const STRING_FIELDS = new Set(['direction', 'command', 'lastIncoming', 'result', 'outcome',
  'scenario', 'mode', 'hiddenYijiMode', 'candidateId', 'nativeQaGateCommand', 'at',
  'cardWireObserverMode', 'cardWirePlayerMode',
  'cardWireEntropyFailureKind',
  'runtimeMD5', 'sourceRevision', 'packageSha256', 'sha256', 'hash',
  'distIndexSha256', 'catalogSha256', 'upstreamSha', 'commitSha',
  'smartAiSha256', 'roomLuaSha256', 'qaSmartAiOverlaySha256', 'manifestSha256',
  'releaseManifestSha256', 'remoteIndexSha256', 'bundleHash', 'md5']);
const sanitizeString = (key: string, value: string): string | null => {
  if (!STRING_FIELDS.has(key)) return null;
  if (key === 'at') {
    // This is generated by the runner (Date#toISOString), and is useful for
    // comparing bounded QA evidence. Reject all non-canonical/invalid dates.
    if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/u.test(value)) return null;
    const date = new Date(value);
    return Number.isFinite(date.getTime()) && date.toISOString() === value ? value : null;
  }
  if (SAFE_STRING_VALUES.has(value)) return value;
  if (SAFE_HEX.test(value)) return value;
  if ((key === 'command' || key === 'lastIncoming' || key === 'nativeQaGateCommand')
    && SAFE_COMMAND.test(value)) return value;
  if (key === 'scenario' && SAFE_SCENARIO.test(value)) return value;
  if (key === 'cardWireObserverMode' &&
      /^(?:valid|missing|wrong-version|wrong-protocol|wrong-mode)$/u.test(value)) return value;
  if (key === 'cardWirePlayerMode' && /^(?:valid|missing)$/u.test(value)) return value;
  if (key === 'cardWireEntropyFailureKind' && /^(?:open|short-read|close)$/u.test(value)) return value;
  return null;
};
const count = (value: unknown): number | null =>
  typeof value === 'number' && Number.isSafeInteger(value) && value >= 0 ? value : null;
const boundedMetric = (value: unknown, maximum = 64 * 1024 * 1024): number | null => {
  const result = count(value);
  return result !== null && result <= maximum ? result : null;
};
function sanitizePacketBytes(value: unknown): Record<string, number | null> {
  const source = value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown> : {};
  return {
    total: boundedMetric(source.total),
    min: boundedMetric(source.min, 4 * 1024 * 1024),
    max: boundedMetric(source.max, 4 * 1024 * 1024),
    le256: boundedMetric(source.le256, 100_000),
    le1024: boundedMetric(source.le1024, 100_000),
    le4096: boundedMetric(source.le4096, 100_000),
    gt4096: boundedMetric(source.gt4096, 100_000),
  };
}
function boundedDuration(value: unknown): number | null {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value > 86_400) {
    return null;
  }
  return Math.round(value * 1000) / 1000;
}
function sanitizeNativeProcessMetrics(value: unknown): Record<string, number | string | null> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const source = value as Record<string, unknown>;
  return {
    schemaVersion: source.schemaVersion === 1 ? 1 : null,
    sampleCount: boundedMetric(source.sampleCount, 1_000_000),
    firstRssKb: boundedMetric(source.firstRssKb, 4 * 1024 * 1024),
    minRssKb: boundedMetric(source.minRssKb, 4 * 1024 * 1024),
    maxRssKb: boundedMetric(source.maxRssKb, 4 * 1024 * 1024),
    lastRssKb: boundedMetric(source.lastRssKb, 4 * 1024 * 1024),
    maxCpuSeconds: boundedDuration(source.maxCpuSeconds),
    elapsedSeconds: boundedDuration(source.elapsedSeconds),
    sampling: source.sampling === 'ps-rss-cputime' ? 'ps-rss-cputime' : null,
  };
}
function sanitizeNativeSemanticCapture(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const source = value as Record<string, unknown>;
  const bounded = (key: string, maximum = 1_000_000) => boundedMetric(source[key], maximum);
  const counters = (key: 'audiences' | 'channels' | 'scopes', names: readonly string[]) => {
    const item = source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])
      ? source[key] as Record<string, unknown> : {};
    return Object.fromEntries(names.map((name) => [name, boundedMetric(item[name], 1_000_000)]));
  };
  return {
    schemaVersion: source.schemaVersion === 1 ? 1 : null,
    requested: source.requested === true,
    records: bounded('records'),
    semanticPassRecords: bounded('semanticPassRecords'),
    semanticFailures: bounded('semanticFailures'),
    outerDecodedRecords: bounded('outerDecodedRecords'),
    innerDecodedRecords: bounded('innerDecodedRecords'),
    inboundRecords: bounded('inboundRecords'),
    outboundRecords: bounded('outboundRecords'),
    opaqueReferences: bounded('opaqueReferences'),
    numericReferences: bounded('numericReferences'),
    invalidReferences: bounded('invalidReferences'),
    forbiddenFields: bounded('forbiddenFields'),
    nestedDecoded: bounded('nestedDecoded'),
    maxDepth: bounded('maxDepth', 64),
    audiences: counters('audiences', ['owner', 'opponent', 'observer', 'unknown']),
    channels: counters('channels', ['metadata', 'public', 'request', 'deck', 'negotiation', 'reply']),
    scopes: counters('scopes', ['outbound', 'inbound-reply', 'inbound-notify', 'inbound-request']),
  };
}

function sanitizeObservations(value: unknown): unknown[] {
  if (!Array.isArray(value)) return [];
  return value.slice(0, 2000).map((observation) => {
    const item = observation && typeof observation === 'object'
      ? observation as Record<string, unknown> : {};
    const detail = typeof item.detail === 'string' && SAFE_DETAIL.has(item.detail)
      ? item.detail : undefined;
    return {
      command: typeof item.command === 'string' && SAFE_COMMAND.test(item.command)
        ? item.command : 'unknown',
      requestId: count(item.requestId),
      reply: item.reply === true,
      ...(detail ? { detail } : {}),
    };
  });
}
function sanitizeTelemetry(value: unknown): unknown {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const metric = value as Record<string, unknown>;
  const fields = ['callbacksTotal', 'callbacksActive', 'callbacksPeak', 'sampleErrors'] as const;
  const samples = Array.isArray(metric.samples) ? metric.samples.slice(0, 1800) : [];
  return {
    ...Object.fromEntries(fields.map((field) => [field, count(metric[field])])),
    sampleCount: samples.length,
    samples: samples.map((item: unknown) => {
      const sample = item && typeof item === 'object' ? item as Record<string, unknown> : {};
      return {
        elapsedMs: count(sample.elapsedMs), wasmBytes: count(sample.wasmBytes),
        luaHeapKiB: typeof sample.luaHeapKiB === 'number' && Number.isFinite(sample.luaHeapKiB)
          && sample.luaHeapKiB >= 0 ? sample.luaHeapKiB : null,
        callbacksTotal: count(sample.callbacksTotal),
        callbacksActive: count(sample.callbacksActive), callbacksPeak: count(sample.callbacksPeak),
      };
    }),
  };
}
export function sanitizeQaEvidence<T>(value: T): T {
  const visit = (node: unknown): unknown => {
    if (Array.isArray(node)) return node.map(visit);
    if (typeof node === 'string') return null;
    if (!node || typeof node !== 'object') return node;
    const safe: Record<string, unknown> = {};
    for (const [key, item] of Object.entries(node)) {
      if (!SAFE_EVIDENCE_KEYS.has(key)) continue;
      if (key === 'logs' || key === 'skillLogs' || key === 'botSkillLogs') {
        safe[key] = Array.isArray(item)
          ? item.filter((log): log is string => typeof log === 'string' &&
            (safeUpstreamMarker(log) || safePairMarker(log))).slice(0, 2000) : [];
      } else if (key === 'localPackages' || key === 'packages' || key === 'localServerOnlyPackages') {
        safe[key] = Array.isArray(item)
          ? item.filter((entry): entry is string => typeof entry === 'string' &&
            (key === 'localServerOnlyPackages' ? entry === 'tqs_qa'
              : SAFE_PACKAGES.has(entry))).slice(0, 100) : [];
      } else if (key === 'boardPlayers' || key === 'botNames' || key === 'scenarioBoardStates') {
        safe[key] = [];
      } else if (key === 'scenarioObservations' || key === 'observations') {
        safe[key] = sanitizeObservations(item);
      } else if (key === 'errors') {
        safe[key] = Array.isArray(item) ? item.map(() => 'browser-or-runner-error') : [];
      } else if (key === 'feedback') {
        safe[key] = Array.isArray(item) ? item.map(() => 'application-error-notice') : [];
      } else if (key === 'errorContexts') {
        safe[key] = Array.isArray(item) ? item.map((context) => {
          const source = context && typeof context === 'object' ? context as Record<string, unknown> : {};
          return {
            client: count(source.client),
            lastIncoming: typeof source.lastIncoming === 'string' && SAFE_COMMAND.test(source.lastIncoming)
              ? source.lastIncoming : null,
            diagnosticCode: count(source.diagnosticCode) !== null &&
              (source.diagnosticCode as number) <= 13 ? count(source.diagnosticCode) : null,
          };
        }) : [];
      } else if (key === 'memoryStacks') {
        safe.memoryAllocationDiagnosticCounts = Array.isArray(item)
          ? item.map((stacks) => Array.isArray(stacks) ? stacks.length : count(stacks) ?? 0) : [];
      } else if (key === 'nativeDeckPrivacy') {
        const commands = ['PrepareDrawPile', 'ShuffleDrawPile', 'SyncDrawPile',
          'ChangeCardArea', 'Reconnect', 'Observe', 'MoveCards', 'SetPlayerPile'];
        safe[key] = Array.isArray(item) ? item.slice(0, 3).map((raw) => {
          const entry = raw && typeof raw === 'object' ? raw : {};
          return {
            negotiated: entry.negotiated === true, failures: count(entry.failures),
            projectorSha256: typeof entry.projectorSha256 === 'string' &&
              /^[a-f0-9]{64}$/u.test(entry.projectorSha256) ? entry.projectorSha256 : null,
            commands: Object.fromEntries(commands.map((command) =>
              [command, count(entry.commands?.[command])])),
            categoryCounts: Object.fromEntries(PRIVACY_CATEGORIES.map((category) =>
              [category, count(entry.categoryCounts?.[category])])),
          };
        }) : null;
      } else if (key === 'nativeWireCapture') {
        const commands = ['PrepareDrawPile', 'ShuffleDrawPile', 'SyncDrawPile',
          'ChangeCardArea', 'Reconnect', 'Observe', 'MoveCards', 'SetPlayerPile'];
        safe[key] = Array.isArray(item) ? item.slice(0, 3).map((raw) => {
          const entry = raw && typeof raw === 'object' ? raw : {};
          return {
            beforePacketDecode: entry.beforePacketDecode === true,
            frames: count(entry.frames), packets: count(entry.packets),
            failures: count(entry.failures),
            packetBytes: sanitizePacketBytes(entry.packetBytes),
            hiddenReferenceAudited: entry.hiddenReferenceAudited === true,
            hiddenReferenceCollisions: count(entry.hiddenReferenceCollisions),
            commands: Object.fromEntries(commands.map((command) =>
              [command, count(entry.commands?.[command])])),
            categoryCounts: Object.fromEntries(PRIVACY_CATEGORIES.map((category) =>
              [category, count(entry.categoryCounts?.[category])])),
          };
        }) : null;
      } else if (key === 'nativeSupplementalCapture') {
        const commands = ['CardWireNegotiated', 'PropertyUpdate', 'SetPlayerMark',
          'SetCardMark', 'SetCardFootnote', 'SetCardVirtName', 'FilterCard', 'FillAG',
          'TakeAG', 'SetPlayerHandCards', 'AddVirtualEquip', 'RemoveVirtualEquip',
          'ShowVirtualCard', 'GameLog', 'ShowCard', 'GameOver',
          'AskForCardChosen', 'AskForPoxi', 'AskForAG', 'AskForCardsAndChoice',
          'AskForArrangeCards', 'AskForMoveCardInBoard', 'PlayCard',
          'AskForUseActiveSkill', 'AskForUseCard', 'AskForResponseCard',
          'AskForChoices', 'AskForOptions', 'AskForSkillInvoke', 'CustomDialog',
          'EmptyRequest'];
        const replies = commands.filter((command) => command.startsWith('AskFor') ||
          command === 'PlayCard' || command === 'CustomDialog' || command === 'EmptyRequest');
        safe[key] = Array.isArray(item) ? item.slice(0, 3).map((raw) => {
          const entry = raw && typeof raw === 'object' ? raw : {};
          return {
            beforePacketDecode: entry.beforePacketDecode === true,
            frames: count(entry.frames), packets: count(entry.packets),
            incomingPackets: count(entry.incomingPackets), replyPackets: count(entry.replyPackets),
            failures: count(entry.failures),
            packetBytes: sanitizePacketBytes(entry.packetBytes),
            commands: Object.fromEntries(commands.map((command) =>
              [command, count(entry.commands?.[command])])),
            replies: Object.fromEntries(replies.map((command) =>
              [command, count(entry.replies?.[command])])),
            channels: Object.fromEntries(SUPPLEMENTAL_CHANNELS.map((channel) =>
              [channel, count(entry.channels?.[channel])])),
          };
        }) : null;
      } else if (key === 'nativePacketSizeCapture') {
        safe[key] = Array.isArray(item) ? item.slice(0, 3).map((raw) => {
          const entry = raw && typeof raw === 'object' ? raw : {};
          return {
            beforePacketDecode: entry.beforePacketDecode === true,
            frames: count(entry.frames), packets: count(entry.packets),
            incomingPackets: count(entry.incomingPackets),
            outgoingPackets: count(entry.outgoingPackets),
            failures: count(entry.failures),
            packetBytes: sanitizePacketBytes(entry.packetBytes),
          };
        }) : null;
      } else if (key === 'nativeProcessMetrics') {
        safe[key] = sanitizeNativeProcessMetrics(item);
      } else if (key === 'nativeSemanticCapture') {
        safe[key] = sanitizeNativeSemanticCapture(item);
      } else if (key === 'cardWirePlayerIndex') {
        safe[key] = boundedMetric(item, 1);
      } else if (key === 'cardWirePlayerCapabilityDrops' || key === 'cardWirePlayerErrorPackets' ||
        key === 'cardWirePlayerNegotiatedPackets') {
        safe[key] = boundedMetric(item, 100);
      } else if (key === 'cardWireEntropyNegotiatedPackets' || key === 'cardWireEntropyCardBearingPackets' ||
        key === 'cardWireEntropyBatchAborts' || key === 'cardWireEntropyBatchCommits' ||
        key === 'cardWireEntropyLastAbortActiveReferences' || key === 'cardWireEntropyLastAbortActiveRequests') {
        safe[key] = boundedMetric(item, 1000000);
      } else if (key === 'cardWireReplayRejectCount') {
        safe[key] = boundedMetric(item, 100);
      } else if (key === 'luaTelemetry') {
        safe[key] = Array.isArray(item) ? item.map(sanitizeTelemetry) : null;
      } else if (key === 'card') {
        // Scenario `card` is a boolean reply flag. A numeric card ID or a
        // nested card payload can otherwise pass the generic evidence filter.
        safe[key] = typeof item === 'boolean' ? item : null;
      } else if (typeof item === 'string') {
        // Fail closed: no arbitrary DOM text, error, path, account, card or
        // general value can flow through nested diagnostics or new fields.
        safe[key] = sanitizeString(key, item);
      } else {
        safe[key] = visit(item);
      }
    }
    return safe;
  };
  return visit(value) as T;
}
// EOF
export {};
