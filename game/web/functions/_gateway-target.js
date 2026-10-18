// Cloudflare Pages gateway target validation, shared by proxy and registration.
export const TARGET_KEY = 'quick-tunnel-url';

export function parseTunnelHostname(value) {
  if (typeof value !== 'string') return null;
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*\.trycloudflare\.com$/.test(value)) return null;
  return value.length <= 110 ? value : null;
}

export function noStore(response) {
  response.headers.set('Cache-Control', 'no-store');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  return response;
}
