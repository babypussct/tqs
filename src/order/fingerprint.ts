/**
 * Deterministic Request Fingerprinting for Idempotency using Web Crypto API.
 * Ensures that two requests with the same idempotency key but different payloads are rejected.
 */

function normalizeValue(val: unknown): unknown {
  if (val === null || val === undefined) {
    return null;
  }
  if (typeof val === 'string') {
    return val.trim();
  }
  if (typeof val === 'number') {
    return Number.isFinite(val) ? val : 0;
  }
  if (typeof val === 'boolean') {
    return val;
  }
  if (Array.isArray(val)) {
    return val.map(normalizeValue);
  }
  if (typeof val === 'object') {
    const sortedObj: Record<string, unknown> = {};
    const keys = Object.keys(val as Record<string, unknown>).sort();
    for (const key of keys) {
      // Ignore client-calculated prices, timestamps, and transient UI fields
      if (['finalAmount', 'totalAmount', 'discountAmount', 'riskScore', 'timestamp', '_ui'].includes(key)) {
        continue;
      }
      sortedObj[key] = normalizeValue((val as Record<string, unknown>)[key]);
    }
    return sortedObj;
  }
  return String(val);
}

/**
 * Generate a deterministic SHA-256 hex string from any request payload.
 */
export async function generateRequestFingerprint(payload: unknown): Promise<string> {
  const normalized = normalizeValue(payload);
  const jsonString = JSON.stringify(normalized);
  const data = new TextEncoder().encode(jsonString);

  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
