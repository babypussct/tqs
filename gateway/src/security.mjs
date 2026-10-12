import net from 'node:net';

export function positiveInteger(name, fallback, maximum) {
  const value = Number(process.env[name] ?? fallback);
  if (!Number.isSafeInteger(value) || value <= 0 || value > maximum) throw new Error(`Invalid ${name}`);
  return value;
}
export function normalizedIp(value = '') {
  return value.startsWith('::ffff:') ? value.slice(7) : value;
}
export function clientIp(req, trustedProxies = new Set()) {
  const peer = normalizedIp(req.socket.remoteAddress);
  if (!trustedProxies.has(peer)) return peer;
  const header = req.headers['cf-connecting-ip'] ?? req.headers['x-forwarded-for'];
  const candidate = typeof header === 'string' ? header.split(',')[0].trim() : '';
  return net.isIP(candidate) ? normalizedIp(candidate) : peer;
}
export function originAllowed(origin, allowedOrigins) {
  if (allowedOrigins.has('*')) return true;
  if (typeof origin !== 'string' || origin === 'null') return false;
  try { return new URL(origin).origin === origin && allowedOrigins.has(origin); }
  catch { return false; }
}
export function consume(bucket, bytes, now = Date.now()) {
  const elapsed = Math.max(0, now - bucket.updated) / 1000;
  bucket.messages = Math.min(bucket.messageCapacity, bucket.messages + elapsed * bucket.messageRate);
  bucket.bytes = Math.min(bucket.byteCapacity, bucket.bytes + elapsed * bucket.byteRate);
  bucket.updated = now;
  if (bucket.messages < 1 || bucket.bytes < bytes) return false;
  bucket.messages--; bucket.bytes -= bytes; return true;
}
