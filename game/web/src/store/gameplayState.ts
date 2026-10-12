/** Incremental, request-scoped scene sent by the FreeKill Lua UI emulator. */
export const GAMEPLAY_REQUESTS = new Set([
  'AskForUseActiveSkill', 'AskForUseCard', 'AskForResponseCard', 'PlayCard',
]);

export const GAMEPLAY_ITEMS = [
  'CardItem', 'Photo', 'Button', 'SkillButton', 'SpecialSkills', 'Interaction',
] as const;
export type GameplayItemType = typeof GAMEPLAY_ITEMS[number];

export interface GameplayItem {
  id: string | number;
  enabled: boolean;
  selected: boolean;
  card?: unknown;
  skills?: string[];
  spec?: unknown;
  skill_name?: string;
  refresh_data?: unknown;
  disabledReason?: string;
}

export interface GameplayScene {
  sceneType: string;
  prompt: string;
  items: Record<GameplayItemType, Record<string, GameplayItem>>;
}

export function emptyGameplay(): GameplayScene {
  return {
    sceneType: '', prompt: '',
    items: {
      CardItem: {}, Photo: {}, Button: {}, SkillButton: {},
      SpecialSkills: {}, Interaction: {},
    },
  };
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown> : null;
}

function itemType(value: unknown): value is GameplayItemType {
  return typeof value === 'string' && GAMEPLAY_ITEMS.some((t) => t === value);
}

function itemId(value: unknown): value is string | number {
  return (typeof value === 'string' && value.length > 0 && value.length <= 150 &&
    !['__proto__', 'prototype', 'constructor'].includes(value)) ||
    (typeof value === 'number' && Number.isSafeInteger(value));
}

const dangerousKeys = new Set(['__proto__', 'prototype', 'constructor']);

const MAX_PUBLIC_VALUE_NODES = 4096;
const MAX_PUBLIC_VALUE_BYTES = 64 * 1024;
const MAX_PUBLIC_VALUE_DEPTH = 8;
const MAX_PUBLIC_VALUE_KEYS = 128;
const MAX_PUBLIC_VALUE_ARRAY = 256;
const MAX_PUBLIC_VALUE_STRING = 4096;

interface ValueBudget { nodes: number; bytes: number }

/** Keep gameplay metadata useful without retaining arbitrary Lua object graphs. */
function boundedValue(value: unknown, depth = 0, seen = new Set<object>(), budget: ValueBudget = { nodes: 0, bytes: 0 }): unknown {
  if (budget.nodes++ >= MAX_PUBLIC_VALUE_NODES || depth > MAX_PUBLIC_VALUE_DEPTH) return undefined;
  if (value === null || typeof value === 'boolean') {
    budget.bytes += 5;
    return budget.bytes <= MAX_PUBLIC_VALUE_BYTES ? value : undefined;
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) return undefined;
    budget.bytes += 24;
    return budget.bytes <= MAX_PUBLIC_VALUE_BYTES ? value : undefined;
  }
  if (typeof value === 'string') {
    if (value.length > MAX_PUBLIC_VALUE_STRING) return undefined;
    budget.bytes += value.length;
    return budget.bytes <= MAX_PUBLIC_VALUE_BYTES ? value : undefined;
  }
  if (typeof value !== 'object' || seen.has(value)) return undefined;
  seen.add(value);
  let result: unknown;
  if (Array.isArray(value)) {
    const output: unknown[] = [];
    for (const entry of value.slice(0, MAX_PUBLIC_VALUE_ARRAY)) {
      const next = boundedValue(entry, depth + 1, seen, budget);
      if (next !== undefined) output.push(next);
    }
    result = output;
  } else {
    const output: Record<string, unknown> = {};
    const entries = Object.entries(value).slice(0, MAX_PUBLIC_VALUE_KEYS);
    for (const [key, entry] of entries) {
      if (key.length > 160 || dangerousKeys.has(key)) continue;
      const next = boundedValue(entry, depth + 1, seen, budget);
      if (next !== undefined) output[key] = next;
    }
    // An empty source object is meaningful, but an object whose every field
    // was rejected should disappear from its parent rather than become a
    // misleading empty placeholder.
    result = entries.length > 0 && Object.keys(output).length === 0 ? undefined : output;
  }
  seen.delete(value);
  return result;
}

/** CardItem.card may be a native Card object; only its public face is useful. */
function publicCard(value: unknown): unknown {
  if (value === null) return null;
  const data = record(value);
  if (!data) return undefined;
  const card: Record<string, unknown> = {};
  for (const key of ['name', 'trueName'] as const) {
    if (typeof data[key] === 'string' && data[key].length <= 120 &&
        !/[\u0000-\u001F\u007F]/.test(data[key])) card[key] = data[key];
  }
  if (typeof data.suit === 'number' && Number.isInteger(data.suit) && data.suit >= 0 && data.suit <= 4)
    card.suit = data.suit;
  if (typeof data.number === 'number' && Number.isInteger(data.number) && data.number >= 0 && data.number <= 13)
    card.number = data.number;
  return card;
}

function boundedMetadata(value: unknown): unknown {
  return boundedValue(value);
}

function mergeItem(prior: GameplayItem | undefined, raw: unknown): GameplayItem | null {
  const data = record(raw);
  if (!data || !itemId(data.id)) return null;
  const next: GameplayItem = {
    id: data.id,
    enabled: typeof data.enabled === 'boolean' ? data.enabled : (prior?.enabled ?? false),
    selected: typeof data.selected === 'boolean' ? data.selected : (prior?.selected ?? false),
  };
  if ('card' in data) {
    const card = publicCard(data.card);
    if (card !== undefined) next.card = card;
    else if (prior && 'card' in prior) next.card = prior.card;
  } else if (prior && 'card' in prior) next.card = prior.card;
  const skills = Array.isArray(data.skills) ? data.skills.slice(0, 128) : null;
  if (skills && skills.every((s) => typeof s === 'string' && s.length <= 150))
    next.skills = skills;
  else if (prior?.skills) next.skills = prior.skills;
  if ('spec' in data) {
    const spec = boundedMetadata(data.spec);
    if (spec !== undefined) next.spec = spec;
    else if (prior && 'spec' in prior) next.spec = prior.spec;
  } else if (prior && 'spec' in prior) next.spec = prior.spec;
  if (typeof data.skill_name === 'string' && data.skill_name.length <= 150) next.skill_name = data.skill_name;
  else if (prior?.skill_name) next.skill_name = prior.skill_name;
  if ('refresh_data' in data) {
    const refresh = boundedMetadata(data.refresh_data);
    if (refresh !== undefined) next.refresh_data = refresh;
    else if (prior && 'refresh_data' in prior) next.refresh_data = prior.refresh_data;
  } else if (prior && 'refresh_data' in prior) next.refresh_data = prior.refresh_data;
  if (typeof data.disabledReason === 'string') next.disabledReason = data.disabledReason.slice(0, 300);
  else if (prior?.disabledReason) next.disabledReason = prior.disabledReason;
  return next;
}

/** Lua's _new/_delete and typed arrays are deltas, never full snapshots. */
export function reduceGameplay(scene: GameplayScene, raw: unknown): GameplayScene {
  const delta = record(raw);
  if (!delta || typeof delta._type !== 'string' || delta._type.length > 80) return scene;
  const base = scene.sceneType === delta._type ? scene : emptyGameplay();
  const items = { ...base.items };
  for (const type of GAMEPLAY_ITEMS) items[type] = { ...base.items[type] };

  if (Array.isArray(delta._delete)) {
    for (const entry of delta._delete.slice(0, 2000)) {
      const value = record(entry);
      if (value && itemType(value.type) && itemId(value.id)) delete items[value.type][String(value.id)];
    }
  }
  if (Array.isArray(delta._new)) {
    for (const entry of delta._new.slice(0, 2000)) {
      const value = record(entry);
      if (!value || !itemType(value.type)) continue;
      const item = mergeItem(undefined, value.data);
      if (item) items[value.type][String(item.id)] = item;
    }
  }
  for (const type of GAMEPLAY_ITEMS) {
    if (!Array.isArray(delta[type])) continue;
    for (const rawItem of delta[type].slice(0, 2000)) {
      const value = record(rawItem);
      if (!value || !itemId(value.id)) continue;
      const prior = items[type][String(value.id)];
      // Only Lua-created scene elements can be updated or interacted with.
      if (!prior) continue;
      const next = mergeItem(prior, value);
      if (next) items[type][String(next.id)] = next;
    }
  }
  for (const type of GAMEPLAY_ITEMS) {
    const entries = Object.entries(items[type]);
    if (entries.length > 512) items[type] = Object.fromEntries(entries.slice(-512));
  }
  return {
    sceneType: delta._type,
    prompt: typeof delta._prompt === 'string' ? delta._prompt.slice(0, 5000) : base.prompt,
    items,
  };
}

export function getGameplayItem(scene: GameplayScene, type: GameplayItemType, id: string | number) {
  return scene.items[type][String(id)];
}
