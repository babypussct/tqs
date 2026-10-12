/** Public Lua events plus a restricted snapshot of the local player's generals. */
export interface BoardEquipment { name: string; suit: number; number: number }
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
  phase: string | number | null;
  general: string | null;
  deputyGeneral: string | null;
  kingdom: string | null;
  visibleKingdom: string | null;
  roleShown: boolean;
  selfGeneral: string | null;
  selfDeputyGeneral: string | null;
  chained: boolean | null;
  faceup: boolean | null;
  equipment: BoardEquipment[];
  marks: Record<string, string | number | boolean>;
}

export interface BoardState {
  seats: number[];
  player: Record<number, BoardPlayer>;
  banners: Record<string, string | number | boolean>;
  logs: string[];
  moments: BoardMoment[];
}

export function emptyBoard(): BoardState {
  return { seats: [], player: {}, banners: {}, logs: [], moments: [] };
}

function recordMoment(board: BoardState, moment: MomentInput): BoardMoment[] {
  const id = (board.moments.at(-1)?.id ?? 0) + 1;
  return [...board.moments, { ...moment, id } as BoardMoment].slice(-12);
}

function newPlayer(): BoardPlayer {
  return {
    hp: null, maxHp: null, shield: null, handcardNum: null,
    died: false, phase: null, general: null, deputyGeneral: null,
    kingdom: null, visibleKingdom: null, roleShown: false, selfGeneral: null, selfDeputyGeneral: null,
    chained: null, faceup: null, equipment: [], marks: {},
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

/** Ignore unknown fields: server state can contain private Lua properties. */
export function updateBoard(board: BoardState, command: string, data: unknown, knownIds: number[], ownId: number | null = null): BoardState {
  if (command === 'ArrangeSeats') {
    if (!Array.isArray(data) || data.length < 1 || data.length > 20 ||
        !data.every(validId) || new Set(data).size !== data.length) return board;
    return { ...board, seats: [...data] };
  }
  if (command === 'GameLog') {
    if (typeof data !== 'string' || !data || data.length > 10000) return board;
    return { ...board, logs: [...board.logs, data].slice(-100),
      moments: recordMoment(board, { kind: 'log', text: data }) };
  }
  if (!Array.isArray(data)) return board;
  if (command === 'SelfGenerals') {
    const [id, main, deputy] = data;
    if (!validId(id) || id !== ownId || !knownIds.includes(id) ||
        typeof main !== 'string' || typeof deputy !== 'string' || main.length > 120 || deputy.length > 120) return board;
    return { ...board, player: { ...board.player, [id]: { ...(board.player[id] ?? newPlayer()),
      selfGeneral: publicGeneral(main), selfDeputyGeneral: publicGeneral(deputy) } } };
  }
  if (command === 'VisibleKingdom') {
    const [id, name] = data;
    if (!validId(id) || !knownIds.includes(id) || typeof name !== 'string' || name.length > 120) return board;
    const prior = board.player[id] ?? newPlayer();
    if (id !== ownId && !prior.roleShown && name !== '') return board;
    return { ...board, player: { ...board.player, [id]: { ...prior, visibleKingdom: name || null } } };
  }
  if (command === 'EquipmentUpdate') {
    const [id, cards] = data;
    if (!validId(id) || !knownIds.includes(id) || !Array.isArray(cards) || cards.length > 40 ||
        !cards.every((c) => c && typeof c.name === 'string' && c.name.length <= 120 &&
          Number.isInteger(c.suit) && c.suit >= 0 && c.suit <= 4 &&
          Number.isInteger(c.number) && c.number >= 0 && c.number <= 13)) return board;
    return { ...board, player: { ...board.player, [id]: { ...(board.player[id] ?? newPlayer()),
      equipment: cards.map(({ name, suit, number }) => ({ name, suit, number })) } } };
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
    case 'phase':
      if (typeof value !== 'string' && !(typeof value === 'number' && Number.isFinite(value))) return board;
      next = { ...prior, phase: value }; break;
    case 'general':
    case 'deputyGeneral':
      if (typeof value !== 'string') return board;
      next = { ...prior, [name]: publicGeneral(value) }; break;
    case 'kingdom':
      if (typeof value !== 'string' || value.length > 120) return board;
      next = { ...prior, kingdom: value }; break;
    case 'role_shown':
      if (typeof value !== 'boolean') return board;
      next = { ...prior, roleShown: value,
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
