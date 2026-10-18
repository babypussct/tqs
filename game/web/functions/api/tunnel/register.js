import { parseTunnelHostname, TARGET_KEY, noStore } from '../../_gateway-target.js';

export async function onRequest({ request, env }) {
  if (request.method !== 'POST') return noStore(new Response('Method not allowed', { status: 405 }));
  const expected = env.TQS_TUNNEL_REGISTRATION_TOKEN;
  const supplied = request.headers.get('Authorization');
  if (typeof expected !== 'string' || expected.length < 32 || supplied !== `Bearer ${expected}`)
    return noStore(new Response('Unauthorized', { status: 401 }));

  if (!request.headers.get('Content-Type')?.startsWith('application/json') ||
      Number(request.headers.get('Content-Length') || 0) > 256)
    return noStore(new Response('Invalid payload', { status: 400 }));

  let body;
  try {
    const payload = await request.text();
    if (payload.length > 256) throw new Error('oversized');
    body = JSON.parse(payload);
  } catch {
    return noStore(new Response('Invalid payload', { status: 400 }));
  }
  const hostname = parseTunnelHostname(body?.hostname);
  if (!hostname || Object.keys(body).length !== 1)
    return noStore(new Response('Invalid hostname', { status: 400 }));

  if (!env.TQS_GATEWAY_CONFIG) return noStore(new Response('Binding unavailable', { status: 503 }));
  try {
    // Verify the target is the actual FreeKill gateway before changing routing.
    const check = await fetch(`https://${hostname}/healthz`, { redirect: 'manual', signal: AbortSignal.timeout(7000) });
    if (check.status !== 200 || (await check.text()).trim() !== 'ok')
      return noStore(new Response('Gateway health check failed', { status: 422 }));
    await env.TQS_GATEWAY_CONFIG.put(TARGET_KEY, hostname);
    return noStore(new Response(JSON.stringify({ registered: true }), {
      status: 200, headers: { 'Content-Type': 'application/json; charset=utf-8' },
    }));
  } catch {
    return noStore(new Response('Registration failed', { status: 503 }));
  }
}
