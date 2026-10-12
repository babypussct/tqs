import { boundedPrivateRecord, visibleCardFace, type CardChoice } from './cardSelection';

/** This native dialog explicitly reveals its cards to the addressed player.
 * IDs, disabled IDs and filter arguments remain private to GameConnection. */
export interface CardsAndChoicePrompt {
  title: string;
  cards: CardChoice[];
  choices: string[];
  cancelChoices: string[];
  min: number;
  max: number;
}
export interface CardsAndChoiceSelection {
  publicPrompt: CardsAndChoicePrompt;
  ids: Map<string, number>;
  disabled: Set<number>;
  filter: string;
  extra: Record<string, unknown>;
}

const record = (v: unknown): v is Record<string, unknown> =>
  !!v && typeof v === 'object' && !Array.isArray(v);
const cardIds = (v: unknown): v is number[] => Array.isArray(v) && v.length <= 512 &&
  v.every((id) => Number.isSafeInteger(id) && id >= 0 && id <= 2147483647) && new Set(v).size === v.length;
const choices = (v: unknown): v is string[] => Array.isArray(v) && v.length <= 256 &&
  v.every((s) => typeof s === 'string' && s.length > 0 && s.length <= 1000) && new Set(v).size === v.length;

export function parseCardsAndChoice(payload: unknown,
  face: (id: number) => { name?: string; suit?: string | number; number?: number } | null,
  tokenFactory: () => string = () => crypto.randomUUID()): CardsAndChoiceSelection | null {
  if (!record(payload)) return null;
  const { cards, choices: options } = payload;
  const cancel = payload.cancel_choices ?? [];
  const disabled = payload.disabled ?? [];
  const min = payload.min ?? 1;
  const max = payload.max ?? 1;
  const filter = payload.filter_skel ?? '';
  // Lua's empty table has no array/map distinction in the upstream CBOR
  // encoder. Native callers such as shangyi therefore arrive with
  // `extra_data = []` even though the native model treats it as an empty
  // property map. Accept only that unambiguous empty form; non-empty arrays
  // remain invalid private metadata.
  const rawExtra = payload.extra_data;
  const extra = Array.isArray(rawExtra) && rawExtra.length === 0
    ? {} : boundedPrivateRecord(rawExtra ?? {});
  const title = payload.prompt ?? '';
  if (!cardIds(cards) || !cardIds(disabled) || !disabled.every((id) => cards.includes(id)) ||
      !choices(options) || !choices(cancel) || (!options.length && !cancel.length) ||
      options.some((s) => cancel.includes(s)) ||
      !Number.isInteger(min) || !Number.isInteger(max) || (min as number) < 0 ||
      (max as number) < (min as number) || (max as number) > 512 ||
      ((min as number) > cards.length - disabled.length && !cancel.length) ||
      typeof filter !== 'string' || filter.length > 128 || !extra ||
      typeof title !== 'string' || title.length > 10000) return null;
  const ids = new Map<string, number>();
  const publicCards = cards.map((id) => {
    const token = tokenFactory();
    if (typeof token !== 'string' || !token || token.length > 160 || ids.has(token)) throw new Error('Invalid card token');
    ids.set(token, id);
    return { token, hidden: false, ...visibleCardFace(face(id)) };
  });
  return { publicPrompt: { title, cards: publicCards, choices: [...options], cancelChoices: [...cancel],
    min: min as number, max: max as number }, ids, disabled: new Set(disabled), filter, extra };
}

export function cardsAndChoiceIds(selection: CardsAndChoiceSelection, tokens: unknown): number[] | null {
  if (!Array.isArray(tokens) || tokens.length > selection.publicPrompt.max ||
      new Set(tokens).size !== tokens.length) return null;
  const ids: number[] = [];
  for (const token of tokens) {
    const id = typeof token === 'string' && token.length <= 160 ? selection.ids.get(token) : undefined;
    if (id === undefined || selection.disabled.has(id)) return null;
    ids.push(id);
  }
  return ids;
}
