import test from 'node:test';
import assert from 'node:assert/strict';
import { isRecoverableTransportLoss, isRetryableSessionRefresh, isSessionRejection, SessionRecovery } from '../src/engine/recovery';
function harness() {
  let next = 0; const jobs = new Map<number, { run(): void; delay: number }>();
  const calls: string[] = [];
  const attempts: (() => boolean)[] = [];
  const recovery = new SessionRecovery({ waiting: n => calls.push(`wait:${n}`), connect: (isCurrent) => {
    calls.push('connect');
    attempts.push(isCurrent);
  },
    timeout: () => { calls.push('timeout'); recovery.lost(); }, exhausted: () => calls.push('exhausted') },
  { set: (run, delay) => { jobs.set(++next,{run,delay});return next; }, clear: h => { jobs.delete(h as number); }, random: () => 0.5 });
  function advance() { const [id,job] = jobs.entries().next().value!; jobs.delete(id);job.run();return job.delay; }
  return { recovery, jobs, calls, advance, attempts };
}
test('recovery performs bounded backoff and times out stalled handshakes', () => {
  const h = harness();h.recovery.lost();
  for (const delay of [500,1000,2000,4000,8000]) { assert.equal(h.advance(),delay);assert.equal(h.advance(),90000); }
  assert.equal(h.calls.filter(c=>c==='connect').length,5);assert.equal(h.calls.at(-1),'exhausted');assert.equal(h.jobs.size,0);
});
test('restored session cancels the watchdog and a new loss starts at attempt one', () => {
  const h=harness();h.recovery.lost();h.advance();h.recovery.restored();assert.equal(h.jobs.size,0);
  h.recovery.lost();assert.equal(h.calls.at(-1),'wait:1');h.recovery.stop();assert.equal(h.jobs.size,0);
});
test('stop invalidates callbacks already queued by the browser event loop', () => {
  const h=harness();h.recovery.lost();const old=h.jobs.values().next().value!.run;
  h.recovery.stop();old();assert.deepEqual(h.calls,['wait:1']);assert.equal(h.jobs.size,0);
});
test('room failures preserve transport recovery while admission and account takeover stop it', () => {
  for (const [command, message] of [
    ['ErrorDlg', 'Server Internal Error'],
    ['ErrorMsg', 'room password error'],
    ['ErrorMsg', 'Room is full or already started!'],
  ]) {
    assert.equal(isSessionRejection({ kind: 'online' }, command, message), false);
  }
  assert.equal(isSessionRejection({ kind: 'online' }, 'ErrorDlg', 'others logged in again with this name'), true);
  assert.equal(isSessionRejection({ kind: 'authenticating' }, 'ErrorDlg', 'you have been temporarily banned!'), true);
  assert.equal(isSessionRejection({ kind: 'authenticating' }, 'ErrorMsg', 'MD5 check failed!'), true);
  assert.equal(isSessionRejection({ kind: 'connecting' }, 'ErrorDlg', 'server is full!'), true);
  assert.equal(isSessionRejection({ kind: 'online' }, 'EnterLobby', null), false);
});

test('an expired reconnect cannot use a late credential refresh to replace the current socket', () => {
  const h = harness();
  h.recovery.lost();
  h.advance();
  const first = h.attempts[0];
  assert.equal(first(), true);
  h.advance(); // watchdog fires while credentials are still pending
  assert.equal(first(), false);
  h.advance();
  const second = h.attempts[1];
  assert.equal(second(), true);
  h.recovery.restored();
  assert.equal(second(), false);
  assert.equal(h.jobs.size, 0);
});

test('gateway transport failures remain recoverable without retrying policy or Lua failures', () => {
  for (const reason of ['client transport error', 'backend connection timeout', 'backend closed',
    'backend error: ECONNRESET', 'closed (1006)', 'connect timeout', 'recovery timeout']) {
    assert.equal(isRecoverableTransportLoss(reason), true, reason);
  }
  for (const reason of ['closed by client', 'too many connections', 'traffic limit exceeded',
    'Lua runtime error', 'invalid packet stream']) {
    assert.equal(isRecoverableTransportLoss(reason), false, reason);
  }
});

test('a temporary credential refresh failure can retry but an authorization failure terminates', () => {
  for (const error of [new TypeError('Failed to fetch'), new DOMException('', 'TimeoutError'),
    { code: 'auth/network-request-failed' }, { code: 'GAME_AUTH_UNAVAILABLE' }]) {
    assert.equal(isRetryableSessionRefresh(error), true);
  }
  for (const code of ['LOGIN_REQUIRED', 'GAME_AUTH_INVALID_RESPONSE', 'GAME_AUTH_NOT_CONFIGURED',
    'GAME_AUTH_FAILED', 'auth/user-disabled', 'auth/user-token-expired']) {
    assert.equal(isRetryableSessionRefresh({ code }), false, code);
  }
});
