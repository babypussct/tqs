import { createHash, createHmac } from 'node:crypto';

// The native 2048-bit RSA setup encrypts a 32-byte prefix plus this ticket.
// Keep the ticket at most 213 bytes (245 PKCS#1 v1.5 bytes minus 32).
const MAX_DISPLAY_NAME_BYTES = 96;

/**
 * Map one authenticated Firebase identity to one stable native namespace.
 *
 * Keep the historical readable form for the normal Firebase UID alphabet so
 * existing accounts do not move. UID values outside that bounded alphabet
 * must not be stripped or truncated: either operation can make two distinct
 * identities share one native `userinfo.id` and therefore one temp-ban.
 */
export function nativeNameFor(uid: string): string {
  // Reserve the hash-shaped UID pattern so a readable UID cannot occupy the
  // same native name as an unsafe UID whose digest happens to be that suffix.
  const isReservedHashShape = /^h_[a-f0-9]{62}$/.test(uid);
  if (/^[A-Za-z0-9_-]{1,64}$/.test(uid) && !isReservedHashShape) return `tqs_${uid}`;
  const digest = createHash('sha256').update(uid, 'utf8').digest('hex').slice(0, 62);
  // `h_` + 62 hex characters stays within the native/gateway 64-character
  // suffix limit while retaining 248 bits of collision resistance.
  return `tqs_h_${digest}`;
}

export function signedGameDisplayName(value: string): string {
  let result = '';
  let bytes = 0;
  // A malformed surrogate must not make the web label differ from the UTF-8
  // name authenticated by native FreeKill.
  const normalized = Buffer.from(value.replace(/[\u0000-\u001f\u007f]/g, '').trim(), 'utf8').toString('utf8');
  for (const character of normalized) {
    const size = Buffer.byteLength(character, 'utf8');
    if (bytes + size > MAX_DISPLAY_NAME_BYTES) break;
    result += character;
    bytes += size;
  }
  return result.trim() || 'Chúa Công';
}

/** TQS1 remains the default until the native server supports TQS2. */
export function signGameTicket(nativeName: string, expiresAt: number, secret: string,
  displayName: string, namedTicketsEnabled = false): string {
  if (!namedTicketsEnabled) {
    const payload = `TQS1|${nativeName}|${expiresAt}`;
    return `TQS1|${expiresAt}|${createHmac('sha256', secret).update(payload).digest('hex')}`;
  }
  const encodedName = Buffer.from(signedGameDisplayName(displayName), 'utf8').toString('base64url');
  const payload = `TQS2|${nativeName}|${expiresAt}|${encodedName}`;
  const ticket = `TQS2|${expiresAt}|${encodedName}|${createHmac('sha256', secret).update(payload).digest('hex')}`;
  if (Buffer.byteLength(ticket, 'utf8') > 213) throw new Error('Game ticket exceeds RSA setup limit');
  return ticket;
}

/**
 * Sign the optional gateway admission assertion. It is carried as a
 * WebSocket subprotocol, never in a URL. The gateway uses only the signed
 * nativeName for its per-account quota; native still authenticates the actual
 * encrypted game ticket independently.
 */
export function signGatewayAdmission(nativeName: string, expiresAt: number, secret: string): string {
  if (!/^tqs_[A-Za-z0-9_-]{1,64}$/.test(nativeName)) throw new Error('Invalid native game name');
  if (!Number.isSafeInteger(expiresAt) || expiresAt <= 0) throw new Error('Invalid admission expiry');
  if (secret.length < 32) throw new Error('Gateway admission secret must contain at least 32 characters');
  const identity = Buffer.from(nativeName, 'utf8').toString('base64url');
  const payload = `TQSA1|${nativeName}|${expiresAt}`;
  const signature = createHmac('sha256', secret).update(payload).digest('hex');
  return Buffer.from(`TQSA1|${expiresAt}|${identity}|${signature}`, 'utf8').toString('base64url');
}
