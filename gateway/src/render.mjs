// Render supplies the canonical external URL. Refuse wildcard origins for a public deployment.
const origin = process.env.RENDER_EXTERNAL_URL || process.env.PUBLIC_ORIGIN;
if (!origin || new URL(origin).origin !== origin || !origin.startsWith('https://'))
  throw new Error('Canonical HTTPS PUBLIC_ORIGIN or RENDER_EXTERNAL_URL required');
process.env.ALLOW_ORIGIN = origin;
// Forwarded headers stay untrusted until the hosting proxy contract is verified.
process.env.TRUSTED_PROXIES = '';
process.env.BIND_HOST = '0.0.0.0';
await import('./server.mjs');
