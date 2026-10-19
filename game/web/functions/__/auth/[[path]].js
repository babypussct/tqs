// Cloudflare Pages same-origin Firebase auth helper for installed iOS PWAs.
// Google's OAuth client must explicitly allow
// https://tqsvn.pages.dev/__/auth/handler before the client enables redirect.
const FIREBASE_HELPER_ORIGIN = 'https://gen-lang-client-0845413094.firebaseapp.com';

export async function onRequest({ request }) {
  const incoming = new URL(request.url);
  if (!incoming.pathname.startsWith('/__/auth/')) return new Response('Not found', { status: 404 });
  if (request.method !== 'GET' && request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const target = new URL(incoming.pathname + incoming.search, FIREBASE_HELPER_ORIGIN);
  const headers = new Headers();
  for (const name of ['Accept', 'Content-Type', 'User-Agent']) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  try {
    const upstream = await fetch(target, {
      method: request.method,
      headers,
      body: request.method === 'POST' ? request.body : undefined,
      redirect: 'manual',
    });
    const responseHeaders = new Headers(upstream.headers);
    // Helper responses must never be cached, especially the OAuth callback.
    responseHeaders.set('Cache-Control', 'no-store');
    responseHeaders.delete('Set-Cookie');
    const location = responseHeaders.get('Location');
    if (location) {
      const resolved = new URL(location, FIREBASE_HELPER_ORIGIN);
      if (resolved.origin === FIREBASE_HELPER_ORIGIN) {
        responseHeaders.set('Location', `${incoming.origin}${resolved.pathname}${resolved.search}${resolved.hash}`);
      }
    }
    return new Response(upstream.body, { status: upstream.status, headers: responseHeaders });
  } catch {
    return new Response('Firebase sign-in helper unavailable', {
      status: 502,
      headers: { 'Cache-Control': 'no-store' },
    });
  }
}
