import net from 'node:net';
import { createHmac, timingSafeEqual } from 'node:crypto';

export const WS_ADMISSION_PROTOCOL_PREFIX = 'tqs-admission-v1.';
const MAX_ADMISSION_LIFETIME_SECONDS = 15 * 60;
const NATIVE_NAME_RE = /^tqs_[A-Za-z0-9_-]{1,64}$/;

export function positiveInteger(name, fallback, maximum) {
  const value = Number(process.env[name] ?? fallback);
  if (!Number.isSafeInteger(value) || value <= 0 || value > maximum) throw new Error(`Invalid ${name}`);
  return value;
}
export function normalizedIp(value = '') {
  return value.startsWith('::ffff:') ? value.slice(7) : value;
}

function decodeBase64Url(value, maxBytes) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]+$/.test(value)) return null;
  let bytes;
  try { bytes = Buffer.from(value, 'base64url'); } catch { return null; }
  if (!bytes.length || bytes.toString('base64url') !== value || bytes.length > maxBytes) return null;
  return bytes;
}

/**
 * Verify the short-lived identity assertion carried in Sec-WebSocket-Protocol.
 * It is deliberately separate from the native ticket: the gateway only uses
 * the signed nativeName as a quota key, while the native server remains the
 * authority that authenticates the encrypted Setup packet.
 */
export function parseWsAdmission(header, secret, now = Math.floor(Date.now() / 1000)) {
  if (typeof secret !== 'string' || secret.length < 32) return null;
  const values = Array.isArray(header) ? header : typeof header === 'string' ? header.split(',') : [];
  const protocols = values.map(value => value.trim()).filter(Boolean);
  const matches = protocols.filter(value => value.startsWith(WS_ADMISSION_PROTOCOL_PREFIX));
  if (protocols.length !== 1 || matches.length !== 1) return null;

  const encoded = matches[0].slice(WS_ADMISSION_PROTOCOL_PREFIX.length);
  const wire = decodeBase64Url(encoded, 512)?.toString('utf8');
  if (!wire) return null;
  const parts = wire.split('|');
  if (parts.length !== 4 || parts[0] !== 'TQSA1') return null;
  const expiresAt = Number(parts[1]);
  const identityBytes = decodeBase64Url(parts[2], 96);
  const signature = parts[3];
  if (!Number.isSafeInteger(expiresAt) || !/^\d{1,12}$/.test(parts[1]) ||
      expiresAt <= now || expiresAt > now + MAX_ADMISSION_LIFETIME_SECONDS ||
      !identityBytes || !/^[a-f0-9]{64}$/.test(signature)) return null;
  const identity = identityBytes.toString('utf8');
  if (Buffer.from(identity, 'utf8').compare(identityBytes) !== 0 || !NATIVE_NAME_RE.test(identity)) return null;

  const expected = createHmac('sha256', secret)
    .update(`TQSA1|${identity}|${expiresAt}`)
    .digest();
  const actual = Buffer.from(signature, 'hex');
  if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) return null;
  return { identity, expiresAt, protocol: matches[0] };
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
