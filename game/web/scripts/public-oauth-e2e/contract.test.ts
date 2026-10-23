import test from 'node:test';
import assert from 'node:assert/strict';
import { isGameSocket, matchesQaBearer, publicProbeUrl, PublicProbeError, safeFailure, verifyQaEmail } from './contract';

test('only clean HTTPS origin is accepted', () => {
  assert.equal(publicProbeUrl('https://tqsvn.pages.dev/').origin, 'https://tqsvn.pages.dev');
  for (const input of ['http://tqsvn.pages.dev/', 'https://user:pass@tqsvn.pages.dev/',
    'https://tqsvn.pages.dev/?token=secret', 'https://tqsvn.pages.dev/#token',
    'https://tqsvn.pages.dev/secret', 'not-a-url']) {
    assert.throws(() => publicProbeUrl(input), /invalid_public_url/);
  }
});

test('only same-origin public gateway websocket is counted', () => {
  const site = publicProbeUrl('https://tqsvn.pages.dev/');
  assert.equal(isGameSocket('wss://tqsvn.pages.dev/gateway/ws?ticket=private', site), true);
  for (const value of ['ws://tqsvn.pages.dev/gateway/ws', 'wss://evil.test/gateway/ws',
    'wss://tqsvn.pages.dev/gateway/other', 'not a websocket']) {
    assert.equal(isGameSocket(value, site), false);
  }
});

test('QA email is checked without exporting it to evidence', () => {
  assert.equal(verifyQaEmail(' QA@example.test ', 'qa@EXAMPLE.test'), true);
  assert.equal(verifyQaEmail('other@example.test', 'qa@example.test'), false);
  assert.equal(verifyQaEmail(null, 'qa@example.test'), false);
});

test('Firebase bearer QA identity is checked in memory without token output', () => {
  const payload = Buffer.from(JSON.stringify({ email: 'qa@example.test', email_verified: true })).toString('base64url');
  assert.equal(matchesQaBearer(`Bearer header.${payload}.sig`, 'QA@example.test'), true);
  assert.equal(matchesQaBearer(`Bearer header.${payload}.sig`, 'other@example.test'), false);
  assert.equal(matchesQaBearer('Bearer secret', 'qa@example.test'), false);
  assert.equal(matchesQaBearer(undefined, 'qa@example.test'), false);
  const unverified = Buffer.from(JSON.stringify({ email: 'qa@example.test', email_verified: false })).toString('base64url');
  assert.equal(matchesQaBearer(`Bearer header.${unverified}.sig`, 'qa@example.test'), false);
});

test('unexpected errors and secrets cannot be serialized into evidence', () => {
  const secret = 'Bearer GOOGLE_PRIVATE_TOKEN';
  assert.deepEqual(safeFailure(new Error(secret), 'oauth'), { stage: 'oauth', reason: 'unexpected_failure' });
  assert.deepEqual(safeFailure(new PublicProbeError('room', 'room_unavailable'), 'oauth'),
    { stage: 'room', reason: 'room_unavailable' });
  assert.equal(JSON.stringify(safeFailure(new Error(secret), 'oauth')).includes(secret), false);
  assert.deepEqual(safeFailure(new PublicProbeError('oauth', secret), 'oauth'),
    { stage: 'oauth', reason: 'unexpected_failure' });
});
