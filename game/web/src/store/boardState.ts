/** Public Lua events plus a restricted snapshot of the local player's generals. */
export type BoardCardSubtype =
  | 'weapon'
  | 'armor'
  | 'defensive_ride'
  | 'offensive_ride'
  | 'treasure'
  | 'delayed_trick'
  | 'normal_trick'
  | 'basic'
  | 'unknown';

export interface BoardEquipment {
  name: string;
  suit: number;
  number: number;
  /** Public native subtype; never contains a private card id. */
  subtype?: BoardCardSubtype;
  /** Native weapon range, when this public card is a weapon. */
  range?: number;
  /** Package/art hints copied from the public native card model. */
  extension?: string;
  picName?: string;
}
/** Public server/Lua updates only; never store raw MoveCards or hidden cards. */
type MomentInput =
  | { kind: 'log'; text: string }
  | { kind: 'hp'; playerId: number; before: number; after: number }
  | { kind: 'chain'; playerId: number; chained: boolean };
export type BoardMoment = MomentInput & { id: number };
export interface BoardPlayer {
  hp: number | null;
  maxHp: number | null;
  shield: number | null;
  handcardNum: number | null;
  died: boolean;
  surrendered: boolean;
  drank: number | null;
  phase: string | number | null;
  general: string | null;
  deputyGeneral: string | null;
  generalExtension: string | null;
  deputyGeneralExtension: string | null;
  kingdom: string | null;
  visibleKingdom: string | null;
  roleShown: boolean;
  selfGeneral: string | null;
  selfDeputyGeneral: string | null;
  selfGeneralExtension: string | null;
  selfDeputyGeneralExtension: string | null;
  chained: boolean | null;
  faceup: boolean | null;
  equipment: BoardEquipment[];
  delayedTricks: BoardEquipment[];
  marks: Record<string, string | number | boolean>;
}

export interface BoardState {
  seats: number[];
  player: Record<number, BoardPlayer>;
  banners: Record<string, string | number | boolean>;
  logs: string[];
  moments: BoardMoment[];
  drawPileCount: number | null;
  discardPileCount: number | null;
  topDiscardCard: BoardEquipment | null;
  processingCards: BoardEquipment[];
  selfHandCards: (BoardEquipment & { id: number })[];
}

/**
 * A complete Quốc Chiến round can produce considerably more than one
 * hundred public GameLog notifications.  Keep a generous safety bound for
 * an untrusted server while retaining enough history for a full match.
 */
export const MAX_BOARD_LOGS = 2000;

/** Absolute seat labels from ArrangeSeats; visual rotation is separate. */
export function serverSeatNumbers(seats: number[], knownIds: number[] = []): Map<number, number> {
  const known = new Set(knownIds);
  const filterKnown = known.size > 0;
  const result = new Map<number, number>();
  for (const id of seats) {
    if (!validId(id) || (filterKnown && !known.has(id)) || result.has(id)) continue;
    result.set(id, result.size + 1);
  }
  return result;
}

export function emptyBoard(): BoardState {
  return {
    seats: [],
    player: {},
    banners: {},
    logs: [],
    moments: [],
    drawPileCount: null,
    discardPileCount: null,
    topDiscardCard: null,
    processingCards: [],
    selfHandCards: [],
  };
}

function recordMoment(board: BoardState, moment: MomentInput): BoardMoment[] {
  const id = (board.moments.at(-1)?.id ?? 0) + 1;
  return [...board.moments, { ...moment, id } as BoardMoment].slice(-12);
}

function newPlayer(): BoardPlayer {
  return {
    hp: null, maxHp: null, shield: null, handcardNum: null,
    died: false, surrendered: false, drank: null, phase: null,
    general: null, deputyGeneral: null, generalExtension: null, deputyGeneralExtension: null,
    kingdom: null, visibleKingdom: null, roleShown: false, selfGeneral: null, selfDeputyGeneral: null,
    selfGeneralExtension: null, selfDeputyGeneralExtension: null,
    chained: null, faceup: null, equipment: [], delayedTricks: [], marks: {},
  };
}

function validId(id: unknown): id is number {
  return typeof id === 'number' && Number.isSafeInteger(id);
}

function numberOrNull(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : null;
}

function publicGeneral(value: unknown): string | null {
  return typeof value === 'string' && value.length <= 120 &&
    value !== '' && value !== 'anjiang' && value !== 'hidden' ? value : null;
}

function publicMark(value: unknown): string | number | boolean | null {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value === 'boolean') return value;
  return typeof value === 'string' && value.length <= 160 ? value : null;
}

const BOARD_CARD_SUBTYPES = new Set<BoardCardSubtype>([
  'weapon', 'armor', 'defensive_ride', 'offensive_ride', 'treasure',
  'delayed_trick', 'normal_trick', 'basic', 'unknown',
]);

function publicCard(value: unknown): BoardEquipment | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const card = value as Record<string, unknown>;
  if (typeof card.name !== 'string' || card.name.length > 120 ||
      !Number.isInteger(card.suit) || (card.suit as number) < 0 || (card.suit as number) > 5 ||
      !Number.isInteger(card.number) || (card.number as number) < 0 || (card.number as number) > 13) return null;
  const result: BoardEquipment = {
    name: card.name,
    suit: card.suit as number,
    number: card.number as number,
  };
  if (typeof card.subtype === 'string' && BOARD_CARD_SUBTYPES.has(card.subtype as BoardCardSubtype))
    result.subtype = card.subtype as BoardCardSubtype;
  if (typeof card.range === 'number' && Number.isInteger(card.range) && card.range >= 0 && card.range <= 99)
    result.range = card.range;
  if (typeof card.extension === 'string' && card.extension.length <= 120 && /^[A-Za-z0-9_-]+$/.test(card.extension))
    result.extension = card.extension;
  if (typeof card.picName === 'string' && card.picName.length <= 120 && /^[A-Za-z0-9_-]+$/.test(card.picName))
    result.picName = card.picName;
  return result;
}

function optionalExtension(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 && value.length <= 120 &&
    /^[A-Za-z0-9_-]+$/.test(value) ? value : null;
}

/** Ignore unknown fields: server state can contain private Lua properties. */
export function updateBoard(board: BoardState, command: string, data: unknown, knownIds: number[], ownId: number | null = null,
  hiddenKingdomMode = false): BoardState {
  if (command === 'ArrangeSeats') {
    if (!Array.isArray(data) || data.length < 1 || data.length > 20 ||
        !data.every(validId) || new Set(data).size !== data.length) return board;
    return { ...board, seats: [...data] };
  }
  if (command === 'GameLog') {
    if (typeof data !== 'string' || !data || data.length > 10000) return board;
    return { ...board, logs: [...board.logs, data].slice(-MAX_BOARD_LOGS),
      moments: recordMoment(board, { kind: 'log', text: data }) };
  }
  if (command === 'PilesUpdate') {
    if (!data || typeof data !== 'object' || Array.isArray(data)) return board;
    const p = data as Record<string, unknown>;
    const draw = typeof p.draw === 'number' && Number.isInteger(p.draw) && p.draw >= 0 ? p.draw : board.drawPileCount;
    const discard = typeof p.discard === 'number' && Number.isInteger(p.discard) && p.discard >= 0 ? p.discard : board.discardPileCount;
    // The bridge always includes topDiscard, including an explicit null when
    // the discard pile has just been consumed. Do not fall back to the
    // previous card in that case: keeping it makes the table show a stale
    // discard after a draw, take or reshuffle.
    const hasTopDiscard = Object.prototype.hasOwnProperty.call(p, 'topDiscard');
    const topDiscard = hasTopDiscard
      ? publicCard(p.topDiscard)
      : (discard === 0 ? null : board.topDiscardCard);
    const processing = Array.isArray(p.processing)
      ? p.processing.map((c) => publicCard(c)!).filter(Boolean)
      : board.processingCards;
    return {
      ...board,
      drawPileCount: draw,
      discardPileCount: discard,
      topDiscardCard: topDiscard,
      processingCards: processing,
    };
  }
  if (!Array.isArray(data)) return board;
  if (command === 'SelfHand') {
    const cards = data.map((item) => {
      if (!item || typeof item !== 'object') return null;
      const card = publicCard(item);
      const id = (item as any).id;
      return card && typeof id === 'number' && Number.isSafeInteger(id) && id >= 0
        ? { ...card, id }
        : null;
    }).filter(Boolean) as (BoardEquipment & { id: number })[];
    return { ...board, selfHandCards: cards };
  }
  if (command === 'SelfGenerals') {
    const [id, main, deputy, mainExtension, deputyExtension] = data;
    // SelfGenerals is a private projection emitted during reconnect/changeSelf.
    // It can legitimately arrive before AddPlayer/ArrangeSeats rebuilds the
    // public roster; ownId is the stronger privacy boundary here.
    if (!validId(id) || id !== ownId ||
        typeof main !== 'string' || typeof deputy !== 'string' || main.length > 120 || deputy.length > 120) return board;
    return { ...board, player: { ...board.player, [id]: { ...(board.player[id] ?? newPlayer()),
      selfGeneral: publicGeneral(main), selfDeputyGeneral: publicGeneral(deputy),
      selfGeneralExtension: optionalExtension(mainExtension),
      selfDeputyGeneralExtension: optionalExtension(deputyExtension), } } };
  }
  if (command === 'GeneralArtUpdate') {
    const [id, slot, name, extension] = data;
    if (!validId(id) || !knownIds.includes(id) ||
        (slot !== 'general' && slot !== 'deputyGeneral') ||
        typeof name !== 'string' || name.length > 120 || !publicGeneral(name)) return board;
    const prior = board.player[id] ?? newPlayer();
    const artExtension = optionalExtension(extension);
    if (slot === 'general') {
      if (prior.general !== name && !(id === ownId && prior.selfGeneral === name)) return board;
      return { ...board, player: { ...board.player, [id]: {
        ...prior, generalExtension: prior.general === name ? artExtension : prior.generalExtension,
        selfGeneralExtension: id === ownId && prior.selfGeneral === name ? artExtension : prior.selfGeneralExtension,
      } } };
    }
    if (prior.deputyGeneral !== name && !(id === ownId && prior.selfDeputyGeneral === name)) return board;
    return { ...board, player: { ...board.player, [id]: {
      ...prior, deputyGeneralExtension: prior.deputyGeneral === name ? artExtension : prior.deputyGeneralExtension,
      selfDeputyGeneralExtension: id === ownId && prior.selfDeputyGeneral === name ? artExtension : prior.selfDeputyGeneralExtension,
    } } };
  }
  if (command === 'VisibleKingdom') {
    const [id, name] = data;
    if (!validId(id) || !knownIds.includes(id) || typeof name !== 'string' || name.length > 120) return board;
    const prior = board.player[id] ?? newPlayer();
    if (id !== ownId && !prior.roleShown && name !== '') return board;
    return { ...board, player: { ...board.player, [id]: { ...prior, visibleKingdom: name || null } } };
  }
  if (command === 'EquipmentUpdate') {
    const [id, cards, delayedTricks] = data;
    // Reconnect can deliver the private self equipment snapshot before the
    // public roster is rebuilt. Accept that one identity from ownId, while
    // continuing to require a known roster entry for every other seat.
    const isPrivateSelf = id === ownId;
    if (!validId(id) || (!knownIds.includes(id) && !isPrivateSelf) || !Array.isArray(cards) || cards.length > 40 ||
        !cards.every((card: unknown) => publicCard(card) !== null) ||
        (delayedTricks !== undefined && (!Array.isArray(delayedTricks) || delayedTricks.length > 40 ||
          !delayedTricks.every((card: unknown) => publicCard(card) !== null)))) return board;
    return { ...board, player: { ...board.player, [id]: { ...(board.player[id] ?? newPlayer()),
      equipment: cards.map((card: unknown) => publicCard(card)!).filter(Boolean),
      delayedTricks: (delayedTricks ?? []).map((card: unknown) => publicCard(card)!).filter(Boolean), } } };
  }
  if (command === 'SetBanner') {
    const [name, value] = data;
    const visibleValue = publicMark(value);
    if (typeof name !== 'string' || !name.startsWith('@') || name.length > 120 || visibleValue === null) return board;
    return { ...board, banners: { ...board.banners, [name]: visibleValue } };
  }
  const [id, name, value] = data;
  if (!validId(id) || !knownIds.includes(id) || typeof name !== 'string') return board;
  const prior = board.player[id] ?? newPlayer();
  if (command === 'SetPlayerMark') {
    const mark = publicMark(value);
    if (!name.startsWith('@') || name.length > 120 || mark === null) return board;
    return { ...board, player: { ...board.player, [id]: {
      ...prior, marks: { ...prior.marks, [name]: mark },
    } } };
  }
  if (command !== 'PropertyUpdate') return board;
  let next: BoardPlayer;
  switch (name) {
    case 'hp':
      if (typeof value !== 'number' || !Number.isFinite(value)) return board;
      next = { ...prior, hp: value }; break;
    case 'maxHp':
    case 'shield':
    case 'handcardNum': {
      const n = numberOrNull(value);
      if (n === null) return board;
      next = { ...prior, [name]: n }; break;
    }
    case 'dead':
    case 'died':
      if (typeof value !== 'boolean') return board;
      next = { ...prior, died: value }; break;
    case 'surrendered':
      if (typeof value !== 'boolean') return board;
      next = { ...prior, surrendered: value }; break;
    case 'drank': {
      const n = numberOrNull(value);
      if (n === null) return board;
      next = { ...prior, drank: n }; break;
    }
    case 'phase':
      if (typeof value !== 'string' && !(typeof value === 'number' && Number.isFinite(value))) return board;
      next = { ...prior, phase: value }; break;
    case 'general':
    case 'deputyGeneral':
      if (typeof value !== 'string') return board;
      next = { ...prior, [name]: publicGeneral(value),
        ...(name === 'general' ? { generalExtension: null } : { deputyGeneralExtension: null }) }; break;
    case 'kingdom':
      if (typeof value !== 'string' || value.length > 120) return board;
      if (hiddenKingdomMode && id !== ownId && !prior.roleShown && value !== '') return board;
      next = { ...prior, kingdom: value }; break;
    case 'role_shown':
      if (typeof value !== 'boolean') return board;
      next = { ...prior, roleShown: value,
        kingdom: hiddenKingdomMode && !value && id !== ownId ? null : prior.kingdom,
        visibleKingdom: !value && id !== ownId ? null : prior.visibleKingdom }; break;
    case 'chained':
    case 'faceup':
      if (typeof value !== 'boolean') return board;
      next = { ...prior, [name]: value }; break;
    default:
      return board;
  }
  let moments = board.moments;
  if (name === 'hp' && prior.hp !== null && next.hp !== null && prior.hp !== next.hp) {
    moments = recordMoment(board, { kind: 'hp', playerId: id, before: prior.hp, after: next.hp });
  } else if (name === 'chained' && prior.chained !== null && prior.chained !== next.chained) {
    moments = recordMoment(board, { kind: 'chain', playerId: id, chained: next.chained! });
  }
  return { ...board, moments, player: { ...board.player, [id]: next } };
}

/** Fix the local seat at the bottom and preserve the server's clockwise order. */
export function relativeSeatOrder(seats: number[], knownIds: number[], ownId: number | null): number[] {
  const valid = new Set(knownIds);
  const ordered = [...new Set([...seats, ...knownIds])].filter((id) => valid.has(id));
  const ownIndex = ownId === null ? -1 : ordered.indexOf(ownId);
  if (ownIndex < 0) return ordered;
  return [...ordered.slice(ownIndex + 1), ...ordered.slice(0, ownIndex + 1)];
}
