// Metadata-only contract between the native CBOR auditor and evidence export.
export const PRIVACY_CATEGORIES = [
  'prepare_order', 'shuffle_order', 'sync_order', 'change_area_order',
  'hidden_move_id', 'observe_hidden_move_id', 'special_pile_id',
  'reconnect_deck', 'reconnect_hand', 'reconnect_special', 'observe_deck', 'observe_hand',
] as const;

/** Supplemental native wire channels audited before browser Lua decoding. */
export const SUPPLEMENTAL_CHANNELS = [
  'negotiation', 'metadata', 'public', 'request', 'reply',
] as const;

export type PrivacyAudit = {
  coverage: Record<string, number>;
  hiddenFingerprints: string[];
};

export function parsePrivacyAudit(output: string): PrivacyAudit | null {
  const fields = output.trim().split(';');
  if ((fields.length !== PRIVACY_CATEGORIES.length + 1 &&
       fields.length !== PRIVACY_CATEGORIES.length + 2) || fields[0] !== 'PASS') return null;
  const counts: Record<string, number> = {};
  for (const [index, name] of PRIVACY_CATEGORIES.entries()) {
    const prefix = `${name}=`;
    const field = fields[index + 1];
    if (!field.startsWith(prefix) || !/^\d{1,8}$/u.test(field.slice(prefix.length))) return null;
    const count = Number(field.slice(prefix.length));
    if (!Number.isSafeInteger(count) || count > 8192) return null;
    counts[name] = count;
  }
  const fingerprintField = fields[PRIVACY_CATEGORIES.length + 1];
  if (fingerprintField === undefined) return { coverage: counts, hiddenFingerprints: [] };
  if (!fingerprintField.startsWith('hiddenFingerprints=')) return null;
  const encoded = fingerprintField.slice('hiddenFingerprints='.length);
  if (encoded === '') return { coverage: counts, hiddenFingerprints: [] };
  const hiddenFingerprints = encoded.split(',');
  if (hiddenFingerprints.length > 256 || hiddenFingerprints.some((value) =>
    !/^[0-9a-f]{16}$/u.test(value))) return null;
  if (new Set(hiddenFingerprints).size !== hiddenFingerprints.length) return null;
  return { coverage: counts, hiddenFingerprints };
}

export function parsePrivacyCoverage(output: string): Record<string, number> | null {
  return parsePrivacyAudit(output)?.coverage ?? null;
}

export function parseSupplementalCoverage(output: string): {
  channel: typeof SUPPLEMENTAL_CHANNELS[number];
} | null {
  const fields = output.trim().split(';');
  if (fields.length !== 3 || fields[0] !== 'PASS' || fields[1] === undefined ||
      fields[2] !== 'observed=1') return null;
  const prefix = 'channel=';
  if (!fields[1].startsWith(prefix)) return null;
  const channel = fields[1].slice(prefix.length);
  return (SUPPLEMENTAL_CHANNELS as readonly string[]).includes(channel)
    ? { channel: channel as typeof SUPPLEMENTAL_CHANNELS[number] } : null;
}
