import type { GameplayItem } from '../store/gameplayState';

export type InteractionAction = 'update' | 'finish';

export function objectValue(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown> : null;
}

export function choices(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((s): s is string => typeof s === 'string').slice(0, 256) : [];
}

function included(value: unknown, allowed: unknown): boolean {
  return typeof value === 'string' && choices(allowed).includes(value);
}

function subset(value: unknown, allowed: unknown, min = 0, max = 256): boolean {
  return Array.isArray(value) && value.length >= min && value.length <= max &&
    value.every((s) => included(s, allowed)) && new Set(value).size === value.length;
}

function boundedJson(value: unknown, max: number): boolean {
  try {
    const encoded = JSON.stringify(value);
    return encoded !== undefined && encoded.length <= max;
  } catch {
    return false;
  }
}

/** Prevent React from forwarding arbitrary interaction data to a live Lua request.
 * Lua still owns every rule and generates the authoritative response. */
export function validInteractionAction(item: GameplayItem, action: string, data: unknown): boolean {
  if (action !== 'update' && action !== 'finish') return false;
  if (data === undefined || !boundedJson(data, 4096)) return false;
  const spec = objectValue(item.spec);
  if (!spec) return false;
  if (spec.type === 'combo' || spec.type === 'cardname')
    return action === 'update' && included(data, spec.choices);
  if (spec.type === 'checkbox')
    return action === 'update' && subset(data, spec.choices);
  if (spec.type === 'spin')
    return action === 'update' && typeof data === 'number' && Number.isInteger(data) &&
      typeof spec.from === 'number' && typeof spec.to === 'number' &&
      data >= spec.from && data <= spec.to;
  if (spec.type === 'optionbox') {
    const direct = spec.direct_send === true;
    if (action === 'finish' && !direct) return false;
    if (action === 'finish') return included(data, spec.options);
    if (spec.single !== false || direct) return included(data, spec.options);
    return subset(data, spec.options, 0, typeof spec.max_num === 'number' ? spec.max_num : 256);
  }
  if (spec.type === 'expandItems') {
    if (action !== 'update') return false;
    return (typeof data === 'number' && Array.isArray(spec.ids) && spec.ids.includes(data)) ||
      included(data, spec.card_names);
  }
  if (spec.type !== 'ToBeDecided') return false; // Never execute custom QML.
  const refresh = objectValue(item.refresh_data);
  if (!refresh) return false;
  const structured = objectValue(data);
  if (!structured || structured.autoTarget !== false) return false;
  const optionBox = objectValue(refresh.optionBox);
  if (action === 'finish')
    return !!optionBox && optionBox.direct_send === true && included(structured.option, optionBox.options);
  if (structured.elemType === 'OptionBox')
    return !!optionBox && (included(structured.option, optionBox.options) ||
      (structured.option === 'Cancel' && optionBox.cancelable === true));
  if (structured.elemType === 'ExpandItem' && Array.isArray(refresh.expandItems)) {
    const found = refresh.expandItems.some((entry: unknown) => {
      const row = objectValue(entry);
      return row && row.cid === structured.cid && row.name === structured.name;
    });
    const enabled = refresh.enabled_ids;
    return found && (!Array.isArray(enabled) || enabled.includes(structured.cid));
  }
  return false;
}
