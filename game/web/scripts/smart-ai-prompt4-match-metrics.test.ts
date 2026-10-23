import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  aggregateAiMatchMetrics,
  buildPrompt4MatchPairReport,
  buildPrompt4NativeDiagnosticsReview,
  parseAiMatchDiagnosticsLog,
  parseAiMatchMetricsLine,
  parseAiMatchMetricsLog,
} from './smart-ai-prompt4-match-metrics';

function detailedNativeLog(room = 12): string {
  return [
    `2026 [AI_MATCH_METRICS] schema=1 room=${room} mode=new_heg_mode total=7 fallback=3 invalid=2 no_decision=1 accepted=4 skills=hs__wusheng:2:1:1:1:0 commands=AskForUseActiveSkill:3:1:0:1,PlayCard:4:2:2:0`,
    `2026 [AI_MATCH_METRICS_DETAIL] schema=1 room=${room} mode=new_heg_mode fallback=3 invalid=2 reasons=illegal_reply:2,no_decision:1 invalid_details=feasibility_rejected:1,unclassified:1`,
    `2026 [AI_MATCH_METRICS_COMMAND] schema=1 room=${room} mode=new_heg_mode command=AskForUseActiveSkill total=3 fallback=1 invalid=0 reasons=no_decision:1 invalid_details=-`,
    `2026 [AI_MATCH_METRICS_COMMAND] schema=1 room=${room} mode=new_heg_mode command=PlayCard total=4 fallback=2 invalid=2 reasons=illegal_reply:2 invalid_details=feasibility_rejected:1,unclassified:1`,
  ].join('\n');
}

test('parses only bounded metadata from a native metrics line', () => {
  const line = '\u001b[33m[AI_MATCH_METRICS] schema=1 room=7 mode=new_heg_mode total=9 fallback=2 invalid=1 no_decision=1 accepted=7 skills=hs__kurou:2:2:0:0:0,hs__wusheng:1:0:1:1:0 commands=AskForUseActiveSkill:3:1:0:1,PlayCard:6:1:1:0';
  const parsed = parseAiMatchMetricsLine(line);
  assert.deepEqual(parsed?.skills.hs__kurou, { requests: 2, accepted: 2, fallback: 0, invalid: 0, no_decision: 0 });
  assert.deepEqual(parsed?.skills.hs__wusheng, { requests: 1, accepted: 0, fallback: 1, invalid: 1, no_decision: 0 });
  assert.equal(parsed?.accepted, 7);
  assert.equal(parsed?.commands.PlayCard.total, 6);
});

test('rejects malformed or payload-like metric buckets', () => {
  assert.throws(() => parseAiMatchMetricsLog(
    '[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=hs__x:1:1:0:0:0:secret commands=PlayCard:1:0:0:0',
  ));
  assert.throws(() => parseAiMatchMetricsLine(
    '[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=2 fallback=0 invalid=0 no_decision=0 accepted=1 skills=- commands=PlayCard:1:0:0:0',
  ));
  assert.throws(() => parseAiMatchMetricsLine(
    '[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=123:1:1:0:0:0 commands=PlayCard:1:0:0:0',
  ));
  assert.equal(parseAiMatchMetricsLine('ordinary native log line'), null);
});

test('retains special dictionary labels without prototype pollution or lost counts', () => {
  const metrics = parseAiMatchMetricsLine(
    '[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=__proto__:1:1:0:0:0 commands=PlayCard:1:0:0:0',
  );
  assert.ok(metrics);
  assert.deepEqual(Object.keys(metrics.skills), ['__proto__']);
  assert.equal(metrics.skills.__proto__.requests, 1);
  assert.equal(Object.getPrototypeOf(metrics.skills), null);
  assert.throws(() => parseAiMatchMetricsLine(
    '[AI_MATCH_METRICS] schema=1 room=1 mode=new_heg_mode total=1 fallback=0 invalid=0 no_decision=0 accepted=1 skills=__proto__:1:1:0:0:0,__proto__:1:1:0:0:0 commands=PlayCard:1:0:0:0',
  ), /invalid bucket/u);
});

test('builds deterministic candidate-baseline skill deltas', () => {
  const candidate = parseAiMatchMetricsLog(
    '[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=4 fallback=1 invalid=0 no_decision=1 accepted=3 skills=hs__kurou:2:2:0:0:0,hs__wusheng:1:0:1:0:1 commands=PlayCard:4:1:0:1',
  );
  const baseline = parseAiMatchMetricsLog(
    '[AI_MATCH_METRICS] schema=1 room=3 mode=new_heg_mode total=3 fallback=2 invalid=1 no_decision=1 accepted=1 skills=hs__kurou:1:0:1:1:0,hs__zhiheng:1:1:0:0:0 commands=PlayCard:3:2:1:1',
  );
  const report = buildPrompt4MatchPairReport(candidate, baseline);
  assert.equal(report.sameMode, true);
  assert.deepEqual(Object.keys(report.skills), ['hs__kurou', 'hs__wusheng', 'hs__zhiheng']);
  assert.deepEqual(report.skills.hs__kurou.delta, { requests: 1, accepted: 2, fallback: -1, invalid: -1, no_decision: 0 });
  assert.deepEqual(report.aggregateDelta, { total: 1, accepted: 2, fallback: -1, invalid: -1, no_decision: 0 });
  assert.equal(report.winRateAvailable, false);
});

test('aggregates multiple native rooms without retaining raw logs', () => {
  const line = '[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=2 fallback=1 invalid=0 no_decision=1 accepted=1 skills=hs__kurou:1:1:0:0:0 commands=PlayCard:2:1:0:1';
  const records = [parseAiMatchMetricsLine(line), parseAiMatchMetricsLine(line)].filter((value) => value !== null);
  const aggregate = aggregateAiMatchMetrics(records);
  assert.equal(aggregate.matchCount, 2);
  assert.equal(aggregate.roomId, 0, 'aggregated rooms use a synthetic room id');
  assert.deepEqual(aggregate.skills.hs__kurou, { requests: 2, accepted: 2, fallback: 0, invalid: 0, no_decision: 0 });
  assert.equal(aggregate.total, 4);
  assert.equal(aggregate.accepted + aggregate.fallback, aggregate.total);
});

test('joins native detailed counters by room and checks reason, command and invalid sums', () => {
  const runs = parseAiMatchDiagnosticsLog(`${detailedNativeLog()}\n${detailedNativeLog(13)}`);
  assert.equal(runs.length, 2);
  assert.equal(runs[0].fallbackReasons.illegal_reply, 2);
  assert.equal(runs[1].commands.PlayCard.invalidDetails.feasibility_rejected, 1);
  const review = buildPrompt4NativeDiagnosticsReview(runs, parseAiMatchDiagnosticsLog(detailedNativeLog(14)));
  assert.equal(review.fallbackReasonDelta.illegal_reply, 2);
  assert.deepEqual(review.commandDeltas.PlayCard, { total: 4, fallback: 2, invalid: 2 });
  assert.equal(review.matchedRequestState, false);
  assert.equal(review.causalAttributionAvailable, false);
  assert.ok(!JSON.stringify(review).includes('hs__wusheng'), 'review emits only aggregate diagnostics');
});

test('rejects diagnostics missing, duplicated, out of order, with mixed room or unknown labels', () => {
  const log = detailedNativeLog();
  assert.throws(() => parseAiMatchDiagnosticsLog(log.split('\n')[0]), /missing diagnostic/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('[AI_MATCH_METRICS_DETAIL]', '[AI_MATCH_METRICS_COMMAND]')), /out-of-order/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(`${log}\n${log.split('\n')[1]}`), /duplicate/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('command=PlayCard total=4', 'command=Unknown total=4')), /identity or counters mismatch/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('room=12 mode=new_heg_mode fallback=3 invalid=2', 'room=13 mode=new_heg_mode fallback=3 invalid=2')), /identity or counters mismatch/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('illegal_reply:2,no_decision:1', 'private_card:2,no_decision:1')), /payload-like/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('feasibility_rejected:1,unclassified:1', 'card_id:1,unclassified:1')), /payload-like/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('invalid_details=-', 'invalid_details=user_secret:1')), /payload-like/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('reasons=illegal_reply:2 invalid_details=', 'reasons=illegal_reply:2,illegal_reply:1 invalid_details=')), /duplicate/u);
});

test('rejects native aggregate/detail inconsistencies and partial command coverage', () => {
  const log = detailedNativeLog();
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('reasons=illegal_reply:2,no_decision:1', 'reasons=illegal_reply:2')), /reconcile/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('invalid_details=feasibility_rejected:1,unclassified:1', 'invalid_details=unclassified:1')), /reconcile/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.split('\n').slice(0, 3).join('\n')), /incomplete/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('reasons=no_decision:1 invalid_details=-', 'reasons=illegal_reply:1 invalid_details=unclassified:1')), /do not reconcile/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('total=4 fallback=2 invalid=2 reasons=', 'total=5 fallback=2 invalid=2 reasons=')), /identity or counters mismatch/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(log.replace('invalid=2 reasons=illegal_reply:2,no_decision:1', 'invalid=1 reasons=illegal_reply:2,no_decision:1')), /identity or counters mismatch/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(`${log}\n${log.split('\n')[0]}`), /missing diagnostic/u);
  // The old aggregate-only emitter remains supported by its legacy parser.
  assert.equal(parseAiMatchMetricsLog(log.split('\n')[0]).total, 7);
});

test('real Lua emitter is QA opt-in, emits bounded labels and reconciles with parser', (t) => {
  const sourcePath = path.resolve(path.dirname(fileURLToPath(import.meta.url)),
    '../../../runtime/packages/freekill-core/lua/server/roombase.lua');
  const source = readFileSync(sourcePath, 'utf8');
  const begin = source.indexOf('local function metricToken(value)');
  const end = source.indexOf('---@param winners string', begin);
  assert.ok(begin >= 0 && end > begin, 'locate actual production emitter, without executing gameOver');
  const script = `${source.slice(begin, end)}
fk = { qInfo = function(message) print(message) end }
ServerConfig = { tqsAiMatchTelemetry = false }
local metrics = {
  total = 7, fallback = 3, invalid = 2, no_decision = 1,
  fallback_reasons = { illegal_reply = 2, no_decision = 1 },
  invalid_details = { feasibility_rejected = 1, unclassified = 1 },
  by_command = {
    AskForUseActiveSkill = { total = 3, fallback = 1, invalid = 0, no_decision = 1,
      fallback_reasons = { no_decision = 1 } },
    PlayCard = { total = 4, fallback = 2, invalid = 2, no_decision = 0,
      fallback_reasons = { illegal_reply = 2 },
      invalid_details = { feasibility_rejected = 1, unclassified = 1 } },
  },
  by_skill = { hs__wusheng = { requests = 2, accepted = 1, fallback = 1, invalid = 1, no_decision = 0 } },
}
local room = { id = 12,
  getTag = function(_, name) return name == '__ai_response_metrics' and metrics or nil end,
  getSettings = function(_, name) return name == 'gameMode' and 'new_heg_mode' or nil end,
}
emitAiMatchMetrics(room) -- off: zero lines
ServerConfig.tqsAiMatchTelemetry = true
emitAiMatchMetrics(room)
emitAiMatchMetrics(room) -- once only
`;
  const result = spawnSync('lua', ['-'], { input: script, encoding: 'utf8', maxBuffer: 65536 });
  if ((result.error as NodeJS.ErrnoException | undefined)?.code === 'ENOENT') {
    t.skip('Lua interpreter not installed on this runner');
    return;
  }
  assert.equal(result.status, 0, result.stderr);
  const rooms = parseAiMatchDiagnosticsLog(result.stdout);
  assert.equal(rooms.length, 1);
  assert.equal(rooms[0].metrics.accepted, 4);
  assert.equal(rooms[0].fallbackReasons.illegal_reply, 2);
  assert.equal(rooms[0].commands.PlayCard.invalidDetails.feasibility_rejected, 1);
  assert.equal(result.stdout.split('\n').filter((line) => line.startsWith('[AI_MATCH_METRICS_COMMAND]')).length, 2);
});

test('rejects inconsistent aggregate and per-skill/command counters before analysis', () => {
  const original = detailedNativeLog().split('\n')[0];
  assert.throws(() => parseAiMatchMetricsLine(original.replace('invalid=2 no_decision=1', 'invalid=4 no_decision=1')), /subsets of fallback/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('invalid=2 no_decision=1', 'invalid=3 no_decision=2')), /subsets of fallback/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('commands=AskForUseActiveSkill:3', 'commands=AskForUseActiveSkill:2')), /command total sum/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('PlayCard:4:2:2:0', 'PlayCard:4:2:1:0')), /command invalid sum/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('hs__wusheng:2:1:1:1:0', 'hs__wusheng:2:1:0:1:0')), /accepted \+ fallback/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('skills=hs__wusheng:2:1:1:1:0', 'skills=hs__wusheng:8:7:1:1:0')), /skill requests exceed/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('skills=hs__wusheng:2:1:1:1:0', 'skills=hs__wusheng:2:1:1:1:1')), /subsets of fallback/u);
  assert.throws(() => parseAiMatchMetricsLine(original.replace('commands=AskForUseActiveSkill:3:1:0:1', 'commands=AskForUseActiveSkill:3:1:0:1,AskForUseActiveSkill:3:1:0:1')), /invalid bucket/u);
});

test('duplicate room ids may reoccur in independent complete native runs', () => {
  const runs = parseAiMatchDiagnosticsLog(`${detailedNativeLog()}\n${detailedNativeLog()}`);
  assert.equal(runs.length, 2, 'room IDs are reusable across native process restarts');
  assert.equal(buildPrompt4NativeDiagnosticsReview(runs, runs).fallbackReasonDelta.illegal_reply, 0);
});

test('zero-command rooms and legacy aggregate-only logs remain supported', () => {
  const aggregate = '[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=0 fallback=0 invalid=0 no_decision=0 accepted=0 skills=- commands=-';
  assert.equal(parseAiMatchMetricsLog(aggregate).total, 0);
  const detail = '[AI_MATCH_METRICS_DETAIL] schema=1 room=2 mode=new_heg_mode fallback=0 invalid=0 reasons=- invalid_details=-';
  const runs = parseAiMatchDiagnosticsLog(`${aggregate}\n${detail}`);
  assert.equal(runs[0].metrics.total, 0);
  assert.deepEqual(Object.keys(runs[0].commands), []);
});

test('diagnostics validate invalid reason classes while keeping unknown other bounded', () => {
  const original = detailedNativeLog();
  assert.throws(() => parseAiMatchDiagnosticsLog(original.replace('illegal_reply:2,no_decision:1', 'illegal_reply:1,no_decision:1,invalid_reply:1')), /reconcile/u);
  assert.throws(() => parseAiMatchDiagnosticsLog(original.replace('reasons=illegal_reply:2 invalid_details=', 'reasons=other:2 invalid_details=')), /reconcile/u);
  // The `other` bucket is ambiguous; it may contribute to invalid or no_decision.
  const synthetic = original.replaceAll('illegal_reply:2', 'illegal_reply:1,other:1')
    .replaceAll('feasibility_rejected:1,unclassified:1', 'unclassified:1');
  assert.equal(parseAiMatchDiagnosticsLog(synthetic)[0].fallbackReasons.other, 1);
});

test('safely rejects overflowing counters in single rooms and aggregated runs', () => {
  const max = Number.MAX_SAFE_INTEGER;
  const line = `[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=${max} fallback=0 invalid=0 no_decision=0 accepted=${max} skills=- commands=PlayCard:${max}:0:0:0`;
  const value = parseAiMatchMetricsLine(line);
  assert.ok(value);
  assert.throws(() => aggregateAiMatchMetrics([value, value]), /safe integer range/u);
  assert.throws(() => parseAiMatchMetricsLine(line.replace(`total=${max}`, 'total=9007199254740992')), /safe integer range/u);
  assert.throws(() => parseAiMatchMetricsLine(line.replace(`fallback=0 invalid=0`, `fallback=${max} invalid=0`)), /safe integer range/u);
});

test('diagnostics review refuses overflowing cross-room reason, detail and command counts', () => {
  const max = Number.MAX_SAFE_INTEGER;
  const log = [
    `[AI_MATCH_METRICS] schema=1 room=2 mode=new_heg_mode total=${max} fallback=${max} invalid=${max} no_decision=0 accepted=0 skills=- commands=PlayCard:${max}:${max}:${max}:0`,
    `[AI_MATCH_METRICS_DETAIL] schema=1 room=2 mode=new_heg_mode fallback=${max} invalid=${max} reasons=illegal_reply:${max} invalid_details=unclassified:${max}`,
    `[AI_MATCH_METRICS_COMMAND] schema=1 room=2 mode=new_heg_mode command=PlayCard total=${max} fallback=${max} invalid=${max} reasons=illegal_reply:${max} invalid_details=unclassified:${max}`,
  ].join('\n');
  const rooms = parseAiMatchDiagnosticsLog(log);
  assert.equal(rooms.length, 1);
  assert.throws(() => buildPrompt4NativeDiagnosticsReview([...rooms, ...rooms], rooms), /safe integer range/u);
  assert.throws(() => buildPrompt4NativeDiagnosticsReview(rooms, [...rooms, ...rooms]), /safe integer range/u);
});
