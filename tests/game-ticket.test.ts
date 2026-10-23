import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { nativeNameFor, signGameTicket, signGatewayAdmission, signedGameDisplayName } from '../api/_lib/gameTicket';

const secret = 'unit-test-secret-with-at-least-32-characters';
const nativeName = 'tqs_FirebaseUserId';
const expiresAt = 1792440000;

test('native account names do not collide when Firebase UIDs need normalization', () => {
  assert.equal(nativeNameFor('FirebaseUserId_123'), 'tqs_FirebaseUserId_123');
  const reservedHashShape = 'h_' + 'a'.repeat(62);
  assert.match(nativeNameFor(reservedHashShape), /^tqs_h_[a-f0-9]{62}$/);
  assert.notEqual(nativeNameFor(reservedHashShape), `tqs_${reservedHashShape}`);
  const punctuation = nativeNameFor('google|123.456');
  const truncated = nativeNameFor(`${'a'.repeat(64)}-different-suffix`);
  assert.match(punctuation, /^tqs_h_[a-f0-9]{62}$/);
  assert.match(truncated, /^tqs_h_[a-f0-9]{62}$/);
  assert.notEqual(punctuation, nativeNameFor('google123456'));
  assert.notEqual(truncated, nativeNameFor('a'.repeat(64)));
});

test('legacy ticket is unchanged while native TQS2 rollout is disabled', () => {
  const ticket = signGameTicket(nativeName, expiresAt, secret, 'Gia Cát Lượng');
  const signature = createHmac('sha256', secret).update(`TQS1|${nativeName}|${expiresAt}`).digest('hex');
  assert.equal(ticket, `TQS1|${expiresAt}|${signature}`);
});

test('TQS2 binds the UTF-8 player name and native login identity to the HMAC', () => {
  const ticket = signGameTicket(nativeName, expiresAt, secret, 'Gia Cát Lượng', true);
  const [version, expiry, base64, signature] = ticket.split('|');
  assert.equal(version, 'TQS2');
  assert.equal(expiry, String(expiresAt));
  assert.equal(Buffer.from(base64, 'base64url').toString('utf8'), 'Gia Cát Lượng');
  assert.equal(signature, createHmac('sha256', secret)
    .update(`TQS2|${nativeName}|${expiry}|${base64}`).digest('hex'));
  assert.notEqual(signature, createHmac('sha256', secret)
    .update(`TQS2|tqs_otherUser|${expiry}|${base64}`).digest('hex'));
});

test('UTF-8 display name respects native RSA setup size and removes controls', () => {
  const raw = `  ${'Đặng '.repeat(50)}\n`;
  const name = signedGameDisplayName(raw);
  assert.ok(Buffer.byteLength(name, 'utf8') <= 96);
  assert.ok(!name.includes('\n'));
  const ticket = signGameTicket(nativeName, expiresAt, secret, raw, true);
  assert.ok(Buffer.byteLength(ticket, 'utf8') + 32 <= 245);
  assert.equal(Buffer.from(ticket.split('|')[2], 'base64url').toString('utf8'), name);
  assert.equal(signedGameDisplayName('\r\n\u0000'), 'Chúa Công');
  assert.equal(signedGameDisplayName('\u0000  Võ Tòng  \u007f'), 'Võ Tòng');
  assert.equal(signedGameDisplayName('Tào\ud800Tháo'), 'Tào�Tháo');
});

test('gateway admission assertion binds the native account and expiry without exposing it in a URL', () => {
  const token = signGatewayAdmission(nativeName, expiresAt, secret);
  assert.match(token, /^[A-Za-z0-9_-]+$/);
  const wire = Buffer.from(token, 'base64url').toString('utf8');
  const [version, expiry, encodedIdentity, signature] = wire.split('|');
  assert.equal(version, 'TQSA1');
  assert.equal(expiry, String(expiresAt));
  assert.equal(Buffer.from(encodedIdentity, 'base64url').toString('utf8'), nativeName);
  assert.equal(signature, createHmac('sha256', secret)
    .update(`TQSA1|${nativeName}|${expiresAt}`).digest('hex'));
  assert.doesNotMatch(token, /https?:|[/?#]/);
  assert.throws(() => signGatewayAdmission('not-native', expiresAt, secret), /Invalid native/);

  const normalizedUidName = nativeNameFor('google|uid-with-a-long-normalization-input');
  assert.match(normalizedUidName, /^tqs_[A-Za-z0-9_-]{1,64}$/);
  assert.match(signGatewayAdmission(normalizedUidName, expiresAt, secret), /^[A-Za-z0-9_-]+$/);
});
