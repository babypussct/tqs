// Same-origin bridge for the separately hosted game client. The Firebase ID
// token remains a bearer token and is forwarded only to the trusted TQSShop
// API; this Pages Function never stores it or turns it into a native password.
export async function onRequest({ request, env }) {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
    });
  }
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  const origin = typeof env.TQS_GAME_AUTH_ORIGIN === 'string' ? env.TQS_GAME_AUTH_ORIGIN.replace(/\/$/, '') : '';
  if (!origin) return new Response('Game auth API is not configured', { status: 503 });

  const upstream = `${origin}/api/game/session`;
  const headers = new Headers();
  for (const name of ['Authorization', 'Content-Type']) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }
  headers.set('Accept', 'application/json');

  try {
    const response = await fetch(upstream, {
      method: 'POST',
      headers,
      body: request.body,
      redirect: 'manual',
    });
    const resultHeaders = new Headers(response.headers);
    resultHeaders.delete('Set-Cookie');
    resultHeaders.set('Cache-Control', 'no-store');
    return new Response(response.body, { status: response.status, headers: resultHeaders });
  } catch {
    return new Response('Game auth API is unreachable', { status: 502, headers: { 'Cache-Control': 'no-store' } });
  }
}
