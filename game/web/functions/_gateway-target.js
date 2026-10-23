// Cloudflare Pages gateway target validation, shared by proxy and registration.
export const TARGET_KEY = 'quick-tunnel-url';

// Named Tunnel hostname is set by the Pages operator, not by a public request
// or the old Quick Tunnel registrar. A subdomain on an owned Cloudflare zone is
// required; fail closed if the operator accidentally sets an unsafe target.
export function parseNamedTunnelHostname(value) {
  if (typeof value !== 'string' || value.length > 253) return null;
  const labels = value.split('.');
  if (labels.length < 3 || labels.some(label =>
    label.length < 1 || label.length > 63 || !/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(label))) return null;
  if (labels.at(-1).length < 2 || /^\d+$/.test(labels.at(-1))) return null;
  if (/(?:^|\.)(?:trycloudflare\.com|cfargotunnel\.com|pages\.dev|workers\.dev|localhost|local|internal|test|invalid|example)$/.test(value)) return null;
  return value;
}

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
