import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { clientIp, originAllowed, consume, parseWsAdmission, WS_ADMISSION_PROTOCOL_PREFIX } from '../src/security.mjs';

test('untrusted forwarding headers cannot change the rate-limit identity', () => {
  const req = {socket:{remoteAddress:'::ffff:127.0.0.1'},headers:{'x-forwarded-for':'198.51.100.2'}};
  assert.equal(clientIp(req), '127.0.0.1');
  assert.equal(clientIp(req,new Set(['127.0.0.1'])), '198.51.100.2');
  req.headers['x-forwarded-for']='invented';
  assert.equal(clientIp(req,new Set(['127.0.0.1'])), '127.0.0.1');
});
test('explicit origin policy rejects missing, null, lookalike and malformed origins', () => {
  const allow = new Set(['https://game.example.com']);
  assert.equal(originAllowed('https://game.example.com',allow),true);
  for (const origin of [undefined,'null','https://game.example.com.evil','https://game.example.com/','broken'])
    assert.equal(originAllowed(origin,allow),false);
});
test('message and byte burst limits refill with time without accepting a flood', () => {
  const bucket={messages:2,messageCapacity:2,messageRate:1,bytes:10,byteCapacity:10,byteRate:5,updated:1000};
  assert.equal(consume(bucket,5,1000),true); assert.equal(consume(bucket,5,1000),true);
  assert.equal(consume(bucket,1,1000),false); assert.equal(consume(bucket,6,2000),false);
  assert.equal(consume(bucket,5,2000),true); assert.equal(consume(bucket,1,2000),false);
});

function admissionProtocol(identity, expiresAt, secret) {
  const encodedIdentity = Buffer.from(identity, 'utf8').toString('base64url');
  const signature = createHmac('sha256', secret)
    .update(`TQSA1|${identity}|${expiresAt}`).digest('hex');
  const wire = Buffer.from(`TQSA1|${expiresAt}|${encodedIdentity}|${signature}`, 'utf8').toString('base64url');
  return `${WS_ADMISSION_PROTOCOL_PREFIX}${wire}`;
}

test('signed websocket admission identifies an account without trusting a client header', () => {
  const secret = 'gateway-admission-secret-with-at-least-32-characters';
  const now = 1_800_000_000;
  const protocol = admissionProtocol('tqs_account_a', now + 300, secret);
  assert.deepEqual(parseWsAdmission(protocol, secret, now), {
    identity: 'tqs_account_a', expiresAt: now + 300, protocol,
  });
  assert.equal(parseWsAdmission(`${protocol}, forged-protocol`, secret, now), null);
  assert.equal(parseWsAdmission(protocol, 'wrong-secret-with-at-least-32-characters', now), null);
  assert.equal(parseWsAdmission(admissionProtocol('tqs_account_a', now - 1, secret), secret, now), null);
  assert.equal(parseWsAdmission(admissionProtocol('account_a', now + 300, secret), secret, now), null);
});
