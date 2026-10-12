import test from 'node:test';
import assert from 'node:assert/strict';
import { SessionRecovery } from '../src/engine/recovery';
function harness() {
  let next = 0; const jobs = new Map<number, { run(): void; delay: number }>();
  const calls: string[] = [];
  const recovery = new SessionRecovery({ waiting: n => calls.push(`wait:${n}`), connect: () => calls.push('connect'),
    timeout: () => { calls.push('timeout'); recovery.lost(); }, exhausted: () => calls.push('exhausted') },
  { set: (run, delay) => { jobs.set(++next,{run,delay});return next; }, clear: h => { jobs.delete(h as number); }, random: () => 0.5 });
  function advance() { const [id,job] = jobs.entries().next().value!; jobs.delete(id);job.run();return job.delay; }
  return { recovery, jobs, calls, advance };
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
