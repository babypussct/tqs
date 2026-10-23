import test from 'node:test';
import assert from 'node:assert/strict';
import { parseTunnelHostname, parseNamedTunnelHostname } from '../functions/_gateway-target.js';
import { onRequest as proxy } from '../functions/gateway/[[path]].js';
import { onRequest as register } from '../functions/api/tunnel/register.js';

const host = 'keys-mar-evaluate-winter.trycloudflare.com';
const kv = {
  value: host,
  async get() { return this.value; },
  async put(key, value) { assert.equal(key, 'quick-tunnel-url'); this.value = value; },
};
const env = { TQS_GATEWAY_CONFIG: kv, TQS_TUNNEL_REGISTRATION_TOKEN: 'a'.repeat(64) };

test('hostname parser rejects arbitrary or disguised upstreams', () => {
  assert.equal(parseTunnelHostname(host), host);
  for (const invalid of ['foo.example.com', 'trycloudflare.com', 'a.trycloudflare.com.evil.com',
    'a..trycloudflare.com', 'a.trycloudflare.com:443', 'https://a.trycloudflare.com',
    'a.trycloudflare.com/path', 'A.trycloudflare.com', '127.0.0.1']) {
    assert.equal(parseTunnelHostname(invalid), null, invalid);
  }
});

test('named hostname only accepts a DNS subdomain, never temporary or internal targets', () => {
  assert.equal(parseNamedTunnelHostname('gateway.tqsvn.vn'), 'gateway.tqsvn.vn');
  assert.equal(parseNamedTunnelHostname('ws.game.example.co.uk'), 'ws.game.example.co.uk');
  for (const invalid of [null, 'gateway', 'example.com', 'gateway.trycloudflare.com',
    'x.cfargotunnel.com', 'x.pages.dev', 'x.workers.dev', 'gw.localhost', 'gw.host.internal',
    'gw.test', 'gw.example', 'https://gateway.tqsvn.vn', 'gateway.tqsvn.vn:443',
    'a..example.com', 'a-.example.com', 'a_example.com', '127.0.0.1',
    'gATEWAY.tqsvn.vn', 'gateway.tqsvn.vn/path']) {
    assert.equal(parseNamedTunnelHostname(invalid), null, String(invalid));
  }
});

test('named route works with no KV, never falls back and forwards HTTP and websocket', async () => {
  const original = globalThis.fetch;
  const namedEnv = { TQS_NAMED_TUNNEL_HOSTNAME: 'gateway.tqsvn.vn',
    TQS_GATEWAY_CONFIG: { get: () => { throw Error('legacy KV must not be read'); } } };
  try {
    globalThis.fetch = async (url, init) => {
      assert.equal(url.href, 'https://gateway.tqsvn.vn/healthz');
      assert.equal(init.headers.get('Authorization'), null);
      return new Response('ok');
    };
    const health = await proxy({ request: new Request('https://tqsvn.pages.dev/gateway/healthz'), env: namedEnv });
    assert.equal(health.status, 200);
    assert.equal(await health.text(), 'ok');
    // Invalid configuration fails closed despite a healthy legacy KV.
    assert.equal((await proxy({ request: new Request('https://tqsvn.pages.dev/gateway/healthz'),
      env: { ...namedEnv, TQS_NAMED_TUNNEL_HOSTNAME: 'bad.trycloudflare.com' } })).status, 503);
    globalThis.fetch = async (url, init) => {
      assert.equal(url.href, 'https://gateway.tqsvn.vn/ws');
      assert.equal(init.headers.get('Upgrade'), 'websocket');
      assert.equal(init.headers.get('Sec-WebSocket-Protocol'), 'tqs-admission-v1.signed-assertion');
      return { status: 101, webSocket: { accept() {} } };
    };
    const ws = await proxy({ request: new Request('https://tqsvn.pages.dev/gateway/ws',
      { headers: { Upgrade: 'websocket', 'Sec-WebSocket-Protocol': 'tqs-admission-v1.signed-assertion' } }), env: namedEnv });
    assert.equal(ws.status, 101);
  } finally { globalThis.fetch = original; }
});

test('named mode disables legacy registration even with a valid token', async () => {
  const fixed = { ...env, TQS_NAMED_TUNNEL_HOSTNAME: 'gateway.tqsvn.vn' };
  const response = await register({ request: new Request('https://tqsvn.pages.dev/api/tunnel/register', {
    method: 'POST', headers: { Authorization: `Bearer ${env.TQS_TUNNEL_REGISTRATION_TOKEN}` },
  }), env: fixed });
  assert.equal(response.status, 410);
});

test('proxy fails closed with missing KV, rejects unsafe paths and methods', async () => {
  const request = (path, method = 'GET') => new Request(`https://tqsvn.pages.dev${path}`, { method });
  assert.equal((await proxy({ request: request('/gateway/manifest.json'), env: {} })).status, 503);
  assert.equal((await proxy({ request: request('/gateway/manifest.json'), env: { TQS_GATEWAY_CONFIG: { get: async () => 'localhost' } } })).status, 503);
  assert.equal((await proxy({ request: request('/gateway/admin') , env })).status, 404);
  assert.equal((await proxy({ request: request('/gateway/manifest.json', 'POST'), env })).status, 405);
  assert.equal((await proxy({ request: request('/gateway/ws'), env })).status, 426);
});

test('proxy forwards only canonical target, strips sensitive request headers', async () => {
  const original = globalThis.fetch;
  try {
    globalThis.fetch = async (url, init) => {
      assert.equal(url.href, `https://${host}/manifest.json?v=1`);
      assert.equal(init.headers.get('Authorization'), null);
      assert.equal(init.headers.get('Cookie'), null);
      return new Response('{"ok":true}', { headers: { 'Set-Cookie': 'secret=oops', 'Content-Type': 'application/json' } });
    };
    const request = new Request('https://tqsvn.pages.dev/gateway/manifest.json?v=1', {
      headers: { Authorization: 'Bearer inappropriate', Cookie: 'secret=oops' },
    });
    const response = await proxy({ request, env });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('Set-Cookie'), null);
    assert.equal(response.headers.get('Cache-Control'), 'no-store');
    assert.equal((await response.json()).ok, true);
  } finally { globalThis.fetch = original; }
});

test('registration rejects unauthorized and invalid updates', async () => {
  const request = (body, token = 'wrong') => new Request('https://tqsvn.pages.dev/api/tunnel/register', {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  kv.value = host;
  assert.equal((await register({ request: request({ hostname: host }), env })).status, 401);
  assert.equal((await register({ request: request({ hostname: 'localhost' }, env.TQS_TUNNEL_REGISTRATION_TOKEN), env })).status, 400);
  assert.equal((await register({ request: request({ hostname: host, extra: 'x' }, env.TQS_TUNNEL_REGISTRATION_TOKEN), env })).status, 400);
  assert.equal(kv.value, host);
});

test('registration verifies healthy target before changing KV', async () => {
  const original = globalThis.fetch;
  const token = env.TQS_TUNNEL_REGISTRATION_TOKEN;
  const request = new Request('https://tqsvn.pages.dev/api/tunnel/register', {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ hostname: 'new-rotated-tunnel.trycloudflare.com' }),
  });
  try {
    globalThis.fetch = async url => {
      assert.equal(url, 'https://new-rotated-tunnel.trycloudflare.com/healthz');
      return new Response('ok');
    };
    const response = await register({ request, env });
    assert.equal(response.status, 200);
    assert.equal(kv.value, 'new-rotated-tunnel.trycloudflare.com');
  } finally { globalThis.fetch = original; kv.value = host; }
});
