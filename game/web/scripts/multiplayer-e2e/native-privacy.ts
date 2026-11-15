// Metadata-only contract between the native CBOR auditor and evidence export.
export const PRIVACY_CATEGORIES = [
  'prepare_order', 'shuffle_order', 'sync_order', 'change_area_order',
  'hidden_move_id', 'observe_hidden_move_id', 'special_pile_id',
  'reconnect_deck', 'reconnect_hand', 'reconnect_special', 'observe_deck', 'observe_hand',
] as const;

export function parsePrivacyCoverage(output: string): Record<string, number> | null {
  const fields = output.trim().split(';');
  if (fields.length !== PRIVACY_CATEGORIES.length + 1 || fields[0] !== 'PASS') return null;
  const counts: Record<string, number> = {};
  for (const [index, name] of PRIVACY_CATEGORIES.entries()) {
    const prefix = `${name}=`;
    const field = fields[index + 1];
    if (!field.startsWith(prefix) || !/^\d{1,8}$/u.test(field.slice(prefix.length))) return null;
    const count = Number(field.slice(prefix.length));
    if (!Number.isSafeInteger(count) || count > 8192) return null;
    counts[name] = count;
  }
  return counts;
}
