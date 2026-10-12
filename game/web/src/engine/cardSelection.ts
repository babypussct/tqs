/** Card IDs and Poxi rules stay in GameConnection. React only receives opaque
 * per-request tokens and the metadata of cards which FreeKill marks visible. */
export interface CardChoice {
  token: string;
  hidden: boolean;
  name?: string;
  suit?: string | number;
  number?: number;
}
export interface CardGroup { name: string; cards: CardChoice[] }
export interface CardSelectionPrompt {
  mode: 'single' | 'poxi';
  title: string;
  groups: CardGroup[];
  cancelable: boolean;
}
export interface PoxiView {
  prompt: string;
  selectable: string[];
  feasible: boolean;
}
export interface CardSelection {
  publicPrompt: CardSelectionPrompt;
  ids: Map<string, number>;
  poxi?: { type: string; data: [string, number[]][]; extra: Record<string, unknown> };
}

/** Explicit public-card projection for dialogs. Native face providers may
 * return extra internal fields; those fields must never reach React/store.
 * Call this only after the Lua visibility check for the addressed viewer. */
export function visibleCardFace(face: { name?: string; suit?: string | number; number?: number } | null) {
  if (!face) return {};
  const result: { name?: string; suit?: string | number; number?: number } = {};
  if (typeof face.name === 'string' && face.name.length <= 120) result.name = face.name;
  if ((typeof face.suit === 'string' && face.suit.length <= 32) ||
      (typeof face.suit === 'number' && Number.isFinite(face.suit))) result.suit = face.suit;
  if (typeof face.number === 'number' && Number.isFinite(face.number)) result.number = face.number;
  return result;
}

const validId = (id: unknown): id is number => Number.isSafeInteger(id) &&
  (id as number) >= 0 && (id as number) <= 2147483647;
const record = (x: unknown): x is Record<string, unknown> =>
  !!x && typeof x === 'object' && !Array.isArray(x);

const PRIVATE_NODES = 8192;
const PRIVATE_BYTES = 64 * 1024;
const PRIVATE_DEPTH = 8;
const PRIVATE_KEYS = 1024;
const PRIVATE_ARRAY = 1024;
const PRIVATE_STRING = 4096;
const INVALID_PRIVATE = Symbol('invalid-private-payload');

/** Clone Lua rule metadata before keeping it in GameConnection. */
function clonePrivate(value: unknown, depth: number, seen: Set<object>, state: { nodes: number; bytes: number }): unknown {
  if (state.nodes++ >= PRIVATE_NODES || depth > PRIVATE_DEPTH) return INVALID_PRIVATE;
  if (value === null || typeof value === 'boolean') { state.bytes += 5; return state.bytes <= PRIVATE_BYTES ? value : INVALID_PRIVATE; }
  if (typeof value === 'number') {
    state.bytes += 24;
    return Number.isFinite(value) && state.bytes <= PRIVATE_BYTES ? value : INVALID_PRIVATE;
  }
  if (typeof value === 'string') {
    state.bytes += value.length;
    return value.length <= PRIVATE_STRING && state.bytes <= PRIVATE_BYTES ? value : INVALID_PRIVATE;
  }
  if (typeof value !== 'object' || seen.has(value)) return INVALID_PRIVATE;
  seen.add(value);
  let result: unknown = INVALID_PRIVATE;
  if (Array.isArray(value)) {
    if (value.length > PRIVATE_ARRAY) { seen.delete(value); return INVALID_PRIVATE; }
    const output: unknown[] = [];
    for (const entry of value) {
      const next = clonePrivate(entry, depth + 1, seen, state);
      if (next === INVALID_PRIVATE) { seen.delete(value); return INVALID_PRIVATE; }
      output.push(next);
    }
    result = output;
  } else {
    const entries = Object.entries(value);
    if (entries.length > PRIVATE_KEYS) { seen.delete(value); return INVALID_PRIVATE; }
    const output: Record<string, unknown> = {};
    for (const [key, entry] of entries) {
      if (key.length > 160) { seen.delete(value); return INVALID_PRIVATE; }
      const next = clonePrivate(entry, depth + 1, seen, state);
      if (next === INVALID_PRIVATE) { seen.delete(value); return INVALID_PRIVATE; }
      output[key] = next;
    }
    result = output;
  }
  seen.delete(value);
  return result;
}

export function boundedPrivateRecord(value: unknown): Record<string, unknown> | null {
  if (!record(value)) return null;
  const cloned = clonePrivate(value, 0, new Set<object>(), { nodes: 0, bytes: 0 });
  return record(cloned) ? cloned : null;
}

export function parseCardSelection(command: string, payload: unknown,
  visibleCard: (id: number) => { name?: string; suit?: string | number; number?: number } | null,
  tokenFactory: () => string = () => crypto.randomUUID()): CardSelection | null {
  const single = command === 'AskForCardChosen';
  if (!single && command !== 'AskForPoxi') return null;
  if (!record(payload)) return null;
  const data = single ? payload.card_data : payload.data;
  const extra = boundedPrivateRecord(single ? {} : (payload.extra_data ?? {}));
  if (!Array.isArray(data) || data.length > 32 || !extra) return null;
  const type = payload.type;
  if (!single && (typeof type !== 'string' || !type || type.length > 128 ||
      typeof payload.cancelable !== 'boolean')) return null;
  const visibility = single
    ? (payload.visible_data === undefined || payload.visible_data === null ? undefined : boundedPrivateRecord(payload.visible_data))
    : (extra.visible_data === undefined || extra.visible_data === null ? undefined : boundedPrivateRecord(extra.visible_data));
  if (visibility === null) return null;
  const rawGroups: [string, number[]][] = [];
  const ids = new Map<string, number>();
  const seen = new Set<number>();
  let total = 0;
  for (const group of data) {
    if (!Array.isArray(group) || group.length !== 2 || typeof group[0] !== 'string' ||
        group[0].length > 256 || !Array.isArray(group[1]) || group[1].length > 256 ||
        !group[1].every(validId)) return null;
    total += group[1].length;
    if (total > 512) return null;
    for (const id of group[1] as number[]) {
      if (seen.has(id)) return null;
      seen.add(id);
    }
    rawGroups.push([group[0], [...group[1]]]);
  }
  if (!total) return null;
  const hiddenId = (id: number) => {
    const value = (visibility as Record<string, unknown> | undefined)?.[String(id)];
    return value === false || (!single && value === 0);
  };
  const groups: CardGroup[] = rawGroups.map(([name, cards]) => {
    // Native PlayerCardModel shuffles invisible cards per pile. The token is
    // unrelated to card ID or its position in the server-provided array.
    const visible = cards.filter((id) => !hiddenId(id));
    const hidden = cards.filter((id) => hiddenId(id));
    for (let i = hidden.length - 1; i > 0; i--) {
      const random = new Uint32Array(1);
      crypto.getRandomValues(random);
      const j = random[0] % (i + 1);
      [hidden[i], hidden[j]] = [hidden[j], hidden[i]];
    }
    return { name, cards: [...visible, ...hidden].map((id) => {
      const token = tokenFactory();
      if (typeof token !== 'string' || !token || token.length > 160 || ids.has(token)) throw new Error('Invalid card token');
      ids.set(token, id);
      const isHidden = hidden.includes(id);
      // Do not call visibleCard for an invisible card, even transiently.
      const descriptor = isHidden ? {} : visibleCardFace(visibleCard(id));
      return { token, hidden: isHidden, ...descriptor };
    }) };
  });
  const title = single ? (typeof payload.prompt === 'string' && payload.prompt.length <= 10000 ? payload.prompt : '') : '';
  return { publicPrompt: { mode: single ? 'single' : 'poxi', title, groups,
    cancelable: !single && payload.cancelable === true }, ids,
    ...(!single ? { poxi: { type: type as string, data: rawGroups, extra: extra as Record<string, unknown> } } : {}) };
}

export function selectionIds(selection: CardSelection, tokens: unknown): number[] | null {
  if (!Array.isArray(tokens) || tokens.length > selection.ids.size ||
      new Set(tokens).size !== tokens.length) return null;
  const result: number[] = [];
  for (const token of tokens) {
    if (typeof token !== 'string' || token.length > 160) return null;
    const id = selection.ids.get(token);
    if (id === undefined) return null;
    result.push(id);
  }
  return result;
}
