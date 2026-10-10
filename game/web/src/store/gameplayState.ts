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
  return (typeof value === 'string' && value.length > 0 && value.length <= 150) ||
    (typeof value === 'number' && Number.isSafeInteger(value));
}

function mergeItem(prior: GameplayItem | undefined, raw: unknown): GameplayItem | null {
  const data = record(raw);
  if (!data || !itemId(data.id)) return null;
  const next: GameplayItem = {
    id: data.id,
    enabled: typeof data.enabled === 'boolean' ? data.enabled : (prior?.enabled ?? false),
    selected: typeof data.selected === 'boolean' ? data.selected : (prior?.selected ?? false),
  };
  if ('card' in data) next.card = data.card;
  else if (prior && 'card' in prior) next.card = prior.card;
  if (Array.isArray(data.skills) && data.skills.every((s) => typeof s === 'string' && s.length <= 150))
    next.skills = data.skills.slice(0, 128);
  else if (prior?.skills) next.skills = prior.skills;
  if ('spec' in data) next.spec = data.spec;
  else if (prior && 'spec' in prior) next.spec = prior.spec;
  if (typeof data.skill_name === 'string') next.skill_name = data.skill_name;
  else if (prior?.skill_name) next.skill_name = prior.skill_name;
  if ('refresh_data' in data) next.refresh_data = data.refresh_data;
  else if (prior && 'refresh_data' in prior) next.refresh_data = prior.refresh_data;
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
  return {
    sceneType: delta._type,
    prompt: typeof delta._prompt === 'string' ? delta._prompt.slice(0, 5000) : base.prompt,
    items,
  };
}

export function getGameplayItem(scene: GameplayScene, type: GameplayItemType, id: string | number) {
  return scene.items[type][String(id)];
}
