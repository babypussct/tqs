import assert from 'node:assert/strict';
import { test } from 'node:test';
import { clientIp, originAllowed, consume } from '../src/security.mjs';

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
