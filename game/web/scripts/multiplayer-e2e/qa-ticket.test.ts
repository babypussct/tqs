import assert from 'node:assert/strict';
import { test } from 'node:test';
import { assertQaNativeName, assertTqs1Ticket, createTqs1Ticket } from './qa-ticket';

test('TQS1 ticket signing is deterministic and keeps the account name out of the ticket body', () => {
  const ticket = createTqs1Ticket('tqsqa-account', 1_800_000_000, 'x'.repeat(64));
  assert.match(ticket, /^TQS1\|1800000000\|[a-f0-9]{64}$/);
  assertTqs1Ticket(ticket, 1_800_000_000);
  assert.doesNotMatch(ticket, /tqsqa-account/);
});

test('TQS1 ticket helpers reject unsafe names, short secrets, and altered expiries', () => {
  assert.throws(() => assertQaNativeName('account with spaces'), /metadata-safe/);
  assert.throws(() => createTqs1Ticket('safe-account', 1_800_000_000, 'short'), /at least 32/);
  const ticket = createTqs1Ticket('safe-account', 1_800_000_000, 'x'.repeat(64));
  assert.throws(() => assertTqs1Ticket(ticket, 1_800_000_001), /invalid/);
});
