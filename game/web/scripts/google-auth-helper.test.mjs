import assert from 'node:assert/strict';
import { test } from 'node:test';
import { onRequest } from '../functions/__/auth/[[path]].js';

test('same-origin handler forwards OAuth state without redirecting to firebaseapp.com', async () => {
  const originalFetch = globalThis.fetch;
  let outgoing;
  globalThis.fetch = async (url, options) => {
    outgoing = { url: String(url), options };
    return new Response('handler', { headers: { 'Content-Type': 'text/html', 'Set-Cookie': 'unsafe=1' } });
  };
  try {
    const response = await onRequest({ request: new Request('https://tqsvn.pages.dev/__/auth/handler?state=abc&code=xyz', {
      headers: { Cookie: 'private=secret', Authorization: 'Bearer never-forward', Accept: 'text/html' },
    }) });
    assert.equal(response.status, 200);
    assert.equal(await response.text(), 'handler');
    assert.equal(response.headers.get('Cache-Control'), 'no-store');
    assert.equal(response.headers.get('Set-Cookie'), null);
    assert.equal(outgoing.url, 'https://gen-lang-client-0845413094.firebaseapp.com/__/auth/handler?state=abc&code=xyz');
    assert.equal(outgoing.options.headers.has('Authorization'), false);
    assert.equal(outgoing.options.headers.has('Cookie'), false);
    assert.equal(outgoing.options.redirect, 'manual');
  } finally { globalThis.fetch = originalFetch; }
});

test('auth helper serves JS and preserves the original domain on internal location redirects', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(null, {
    status: 302, headers: { Location: 'https://gen-lang-client-0845413094.firebaseapp.com/__/auth/handler?state=a' },
  });
  try {
    const response = await onRequest({ request: new Request('https://tqsvn.pages.dev/__/auth/iframe') });
    assert.equal(response.headers.get('Location'), 'https://tqsvn.pages.dev/__/auth/handler?state=a');
  } finally { globalThis.fetch = originalFetch; }
});

test('the Pages auth helper disallows unrelated paths and unsupported methods', async () => {
  const disallowed = await onRequest({ request: new Request('https://tqsvn.pages.dev/gateway/healthz') });
  const method = await onRequest({ request: new Request('https://tqsvn.pages.dev/__/auth/handler', { method: 'PUT' }) });
  assert.equal(disallowed.status, 404);
  assert.equal(method.status, 405);
});
