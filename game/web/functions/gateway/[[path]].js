import { TARGET_KEY, parseNamedTunnelHostname, parseTunnelHostname, noStore } from '../_gateway-target.js';

// Only the gateway's public GET endpoints and WebSocket upgrade may cross this proxy.
function allowedPath(path) {
  return path === '/healthz' || path === '/manifest.json' || path === '/bundle.zip' ||
    (path.startsWith('/assets/') && path.length > '/assets/'.length) || path === '/ws';
}

export async function onRequest({ request, env }) {
  const incoming = new URL(request.url);
  const path = incoming.pathname.slice('/gateway'.length);
  if (!allowedPath(path)) return new Response('Not found', { status: 404 });
  if (request.method !== 'GET') return new Response('Method not allowed', { status: 405 });

  const upgrade = request.headers.get('Upgrade')?.toLowerCase() === 'websocket';
  if (path === '/ws' && !upgrade) return new Response('WebSocket required', { status: 426 });
  if (path !== '/ws' && upgrade) return new Response('Unexpected upgrade', { status: 400 });

  let hostname;
  try {
    // Named mode takes precedence and does not read KV. A malformed configured
    // value must never silently fall back to the rotating Quick Tunnel.
    hostname = env.TQS_NAMED_TUNNEL_HOSTNAME !== undefined
      ? parseNamedTunnelHostname(env.TQS_NAMED_TUNNEL_HOSTNAME)
      : parseTunnelHostname(await env.TQS_GATEWAY_CONFIG?.get(TARGET_KEY));
  } catch {
    return noStore(new Response('Gateway configuration unavailable', { status: 503 }));
  }
  if (!hostname) return noStore(new Response('Gateway unavailable', { status: 503 }));

  const upstream = new URL(`https://${hostname}${path}`);
  upstream.search = incoming.search;
  const headers = new Headers(request.headers);
  for (const key of ['Host', 'CF-Connecting-IP', 'X-Forwarded-For', 'X-Forwarded-Host',
    'X-Forwarded-Proto', 'Forwarded', 'Cookie', 'Authorization']) headers.delete(key);
  // Keep the signed account-admission subprotocol on WebSocket upgrades. It
  // is the only identity hint the origin gateway may use for quota; native
  // still authenticates the encrypted Setup ticket independently.
  if (upgrade) {
    const admissionProtocol = request.headers.get('Sec-WebSocket-Protocol');
    if (admissionProtocol) headers.set('Sec-WebSocket-Protocol', admissionProtocol);
  }

  try {
    // A 101 Response has a live WebSocket and must be returned as-is: never buffer frames.
    const response = await fetch(upstream, { method: 'GET', headers, redirect: 'manual' });
    if (upgrade) return response.status === 101 ? response : new Response('Gateway websocket unavailable', { status: 502 });
    const resultHeaders = new Headers(response.headers);
    resultHeaders.delete('Set-Cookie');
    resultHeaders.delete('Location');
    resultHeaders.delete('Access-Control-Allow-Origin');
    resultHeaders.delete('Access-Control-Allow-Credentials');
    return noStore(new Response(response.body, { status: response.status, headers: resultHeaders }));
  } catch {
    return noStore(new Response('Gateway unreachable', { status: 502 }));
  }
}
