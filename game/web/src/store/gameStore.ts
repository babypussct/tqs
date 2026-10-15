import { create } from 'zustand';
import type { ConnectionStatus, RequestInfo } from '../engine/connection';
import type { GatewayManifest } from '../engine/bundle';
import { parseInitialGeneralPrompt, type InitialGeneralPrompt } from '../engine/generalSelection';
import { emptyBoard, updateBoard, type BoardState } from './boardState';
import { emptyGameplay, reduceGameplay, type GameplayScene } from './gameplayState';
import { connectionError } from '../engine/connectionMessages';
import { parseSkillInvokePrompt, type SkillInvokePrompt } from '../engine/skillInvoke';
export type { SkillInvokePrompt } from '../engine/skillInvoke';

export interface LobbyRoom {
  id: number;
  name: string;
  mode: string;
  players: number;
  capacity: number;
  hasPassword: boolean;
  outdated: boolean;
}

export interface RoomPlayer {
  id: number;
  name: string;
  avatar: string;
  ready: boolean;
  owner: boolean;
  netState?: 'online' | 'trust' | 'run' | 'robot' | 'offline';
}

export type GamePhase = 'boot' | 'login' | 'lobby' | 'room' | 'playing';

export interface GameResult {
  outcome: 'win' | 'loss' | 'draw' | 'unknown';
  winners: { id: number; name: string }[];
  summary?: {
    players: { id: number; name: string; general: string | null; deputyGeneral: string | null;
      hp: number | null; maxHp: number | null; handcardNum: number | null }[];
    logs: string[];
  };
}

/**
 * A fake skill is the client-side representation of a skill attached to a
 * still-hidden general. It is intentionally scoped to the local player: the
 * native client only adds/loses these dashboard entries when the event's id
 * equals Cpp.self.id.
 */
export interface FakeSkill {
  name: string;
  prelighted: boolean;
  enabled: boolean;
}

/** A regular skill visible on the local native dashboard. Actionability is
 * owned by the current Lua request scene, not by this projection list. */
export interface RegularSkill {
  name: string;
}

function gameResult(state: GameSnapshot, data: unknown): GameResult {
  if (data === '') return { outcome: 'draw', winners: [] };
  const ids = typeof data === 'string' ? data.split('+') : [];
  if (!ids.length || ids.some((id) => !/^-?\d+$/.test(id) || !Number.isSafeInteger(Number(id)) || Number(id) === 0))
    return { outcome: 'unknown', winners: [] };
  const winners = [...new Set(ids.map(Number))].map((id) => ({ id,
    name: state.players.find((p) => p.id === id)?.name || (id < 0 ? `Bot ${id}` : `Người chơi ${id}`) }));
  return { outcome: state.ownId === null ? 'unknown' : winners.some((p) => p.id === state.ownId) ? 'win' : 'loss', winners };
}

function completedResult(state: GameSnapshot, data: unknown): GameResult {
  const result = gameResult(state, data);
  if (!state.board.logs.length && !Object.keys(state.board.player).length) return result;
  // Keep only the public projection. Hidden/self-only generals, card ids,
  // marks, equipment and pending request data are not retained here.
  const players = state.players.flatMap((player) => {
    const board = state.board.player[player.id];
    return board ? [{ id: player.id, name: player.name, general: board.general,
      deputyGeneral: board.deputyGeneral, hp: board.hp, maxHp: board.maxHp,
      handcardNum: board.handcardNum }] : [];
  });
  return { ...result, summary: { players, logs: [...state.board.logs] } };
}

export interface GameSnapshot {
  phase: GamePhase;
  connection: ConnectionStatus;
  manifest: GatewayManifest | null;
  progress: string;
  error: string | null;
  rooms: LobbyRoom[];
  roomName: string;
  roomMode: string;
  roomDisabledPacks: string[];
  roomDisabledGenerals: string[];
  capacity: number;
  players: RoomPlayer[];
  ownId: number | null;
  pendingRequest: RequestInfo | null;
  skillInvoke: SkillInvokePrompt | null;
  fakeSkills: FakeSkill[];
  regularSkills: RegularSkill[];
  initialGeneral: InitialGeneralPrompt | null;
  board: BoardState;
  gameplay: GameplayScene;
  result: GameResult | null;
  translations: Record<string, string>;
}

export const initialSnapshot: GameSnapshot = {
  phase: 'boot', connection: { kind: 'booting' }, manifest: null,
  progress: '', error: null, rooms: [], roomName: '', roomMode: '',
  roomDisabledPacks: [], roomDisabledGenerals: [],
  capacity: 0, players: [], ownId: null, pendingRequest: null, skillInvoke: null,
  fakeSkills: [],
  regularSkills: [],
  initialGeneral: null,
  board: emptyBoard(),
  gameplay: emptyGameplay(),
  result: null,
  translations: {},
};

function entries(data: unknown): unknown[] {
  return Array.isArray(data) ? data : [];
}

function parseRooms(data: unknown): LobbyRoom[] {
  return entries(data).flatMap((entry) => {
    if (!Array.isArray(entry) || entry.length < 7) return [];
    const [id, name, mode, players, capacity, hasPassword, outdated] = entry;
    if (!Number.isInteger(id) || typeof name !== 'string' || typeof mode !== 'string' ||
        !Number.isInteger(players) || !Number.isInteger(capacity)) return [];
    return [{ id, name, mode, players, capacity, hasPassword: !!hasPassword, outdated: !!outdated }];
  });
}

function validSkillName(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && value.length <= 150 &&
    !/[\u0000-\u001F\u007F]/.test(value);
}

function clearSkillState(state: GameSnapshot): GameSnapshot {
  return state.fakeSkills.length || state.regularSkills.length
    ? { ...state, fakeSkills: [], regularSkills: [] } : state;
}

/** Pure reducer: the Lua client has already decoded and handled this event. */
export function reduceUiEvent(state: GameSnapshot, command: string, data: unknown): GameSnapshot {
  if (command === 'SelfIdentity') return typeof data === 'number' && Number.isSafeInteger(data) && data > 0
    ? { ...state, ownId: data, ...(state.ownId === data ? {} : { fakeSkills: [], regularSkills: [] }) } : state;
  const arr = entries(data);
  switch (command) {
    case 'DisplayTranslations':
      return data && typeof data === 'object' && !Array.isArray(data)
        ? { ...state, translations: {
          ...state.translations,
          ...Object.fromEntries(Object.entries(data).filter(([key, value]) =>
            key.length <= 300 && typeof value === 'string' && value.length <= 30000)),
        } }
        : state;
    case 'EnterLobby':
      return { ...state, phase: 'lobby', error: null, roomName: '', roomMode: '',
        roomDisabledPacks: [], roomDisabledGenerals: [],
        result: null,
        capacity: 0, players: [], pendingRequest: null, skillInvoke: null, initialGeneral: null,
        fakeSkills: [],
        regularSkills: [],
        board: emptyBoard(), gameplay: emptyGameplay() };
    case 'CancelRequest':
      return { ...state, pendingRequest: null, skillInvoke: null, initialGeneral: null,
        gameplay: emptyGameplay() };
    case 'UpdateRequestUI':
      return { ...state, gameplay: reduceGameplay(state.gameplay, data) };
    case 'CustomDialog':
      return { ...state, initialGeneral: parseInitialGeneralPrompt(data) };
    case 'AskForSkillInvoke': {
      const prompt = parseSkillInvokePrompt(data);
      return prompt ? { ...state, skillInvoke: prompt } : state;
    }
    case 'UpdateRoomList':
      return { ...state, rooms: parseRooms(data) };
    case 'EnterRoom': {
      if (arr.length < 3 || !arr[2] || typeof arr[2] !== 'object') return state;
      const settings = arr[2] as Record<string, unknown>;
      const basePlayers = Array.isArray(settings._players) ? settings._players : [];
      const players = basePlayers.flatMap((p): RoomPlayer[] => {
        if (!Array.isArray(p) || typeof p[0] !== 'number') return [];
        return [{ id: p[0], name: String(p[1] ?? ''), avatar: String(p[2] ?? ''),
          ready: p[3] === true, owner: p[5] === true }];
      });
      // The bridge publishes Lua Self before EnterRoom. For regular joins
      // _players is absent, so keep that occupant and prior AddPlayer events.
      return { ...state, phase: 'room', error: null,
        result: null,
        players: basePlayers.length ? players : state.players,
        roomName: String(settings.roomName ?? ''), roomMode: String(settings.gameMode ?? ''),
        roomDisabledPacks: Array.isArray(settings.disabledPack) ? settings.disabledPack.filter((p): p is string => typeof p === 'string') : [],
        roomDisabledGenerals: Array.isArray(settings.disabledGenerals) ? settings.disabledGenerals.filter((p): p is string => typeof p === 'string') : [],
        capacity: Number(arr[0]) || 0, pendingRequest: null, skillInvoke: null, initialGeneral: null,
        fakeSkills: [],
        regularSkills: [],
        board: emptyBoard(), gameplay: emptyGameplay() };
    }
    case 'AddPlayer':
    case 'AddNpc': {
      if (typeof arr[0] !== 'number') return state;
      const previous = state.players.find((p) => p.id === arr[0]);
      const player: RoomPlayer = { ...previous, id: arr[0], name: String(arr[1] ?? ''),
        avatar: String(arr[2] ?? ''), ready: arr[3] === true, owner: previous?.owner ?? false };
      return { ...state, players: [...state.players.filter((p) => p.id !== player.id), player] };
    }
    case 'RemovePlayer':
      return { ...state, players: state.players.filter((p) => p.id !== arr[0]),
        board: { ...state.board, seats: state.board.seats.filter((id) => id !== arr[0]),
          player: Object.fromEntries(Object.entries(state.board.player).filter(([id]) => Number(id) !== arr[0])) } };
    case 'ReadyChanged':
      return { ...state, players: state.players.map((p) => p.id === arr[0] ? { ...p, ready: arr[1] === true } : p) };
    case 'RoomOwner':
      return { ...state, players: state.players.map((p) => ({ ...p, owner: p.id === arr[0] })) };
    case 'StartGame':
      return { ...state, phase: 'playing', pendingRequest: null,
        result: null,
        skillInvoke: null, fakeSkills: [], regularSkills: [], initialGeneral: null, board: emptyBoard(), gameplay: emptyGameplay() };
    case 'GameOver':
      return { ...state, phase: 'room', pendingRequest: null, skillInvoke: null,
        result: completedResult(state, data),
        fakeSkills: [], regularSkills: [], initialGeneral: null, board: emptyBoard(), gameplay: emptyGameplay() };
    case 'Reconnect':
      // Native ClientBase:reconnect() emits EnterLobby/EnterRoom/StartGame,
      // then ClientPlayer:sendDataToUI() rebuilds the current dashboard, and
      // only after that emits the Reconnect marker.  The marker is therefore
      // a transport boundary, not a skill-state reset.  Clearing here would
      // discard the freshly restored hidden trigger/regular projection.
      return state;
    case 'ChangeSelf':
      // Native Client:changeSelf() changes Lua Self before rebuilding the
      // dashboard. Keep the privacy boundary aligned with that identity
      // switch: discard the old player's hidden/regular skills and accept
      // subsequent AddSkill events only for the new Self.
      return typeof data === 'number' && Number.isSafeInteger(data) && data > 0
        ? clearSkillState({ ...state, ownId: data })
        : state;
    case 'AddSkill': {
      const [id, skillName, prelight] = arr;
      if (id !== state.ownId || !Number.isSafeInteger(id) || !validSkillName(skillName))
        return state;
      if (prelight === true) {
        const current = state.fakeSkills.find((skill) => skill.name === skillName);
        const next: FakeSkill = current ?? { name: skillName, prelighted: false, enabled: true };
        return current ? state : { ...state, fakeSkills: [...state.fakeSkills, next] };
      }
      if (prelight !== undefined && prelight !== false) return state;
      const current = state.regularSkills.find((skill) => skill.name === skillName);
      return current ? state : { ...state,
        regularSkills: [...state.regularSkills, { name: skillName }] };
    }
    case 'LoseSkill': {
      const [id, skillName, prelight] = arr;
      if (id !== state.ownId || !Number.isSafeInteger(id) || !validSkillName(skillName))
        return state;
      if (prelight === true) {
        const hasFakeProjection = state.fakeSkills.some((skill) => skill.name === skillName);
        const fakeSkills = state.fakeSkills.filter((skill) => skill.name !== skillName);
        // Native client.lua can emit a fake LoseSkill for a delay-trigger
        // fallback even though its AddSkill projection was regular-only.
        // Remove that stale regular entry only when no fake projection was
        // present; for a true dual projection, the following regular
        // LoseSkill event owns the regular entry.
        const regularSkills = hasFakeProjection
          ? state.regularSkills
          : state.regularSkills.filter((skill) => skill.name !== skillName);
        return fakeSkills.length === state.fakeSkills.length &&
          regularSkills.length === state.regularSkills.length
          ? state : { ...state, fakeSkills, regularSkills };
      }
      if (prelight !== undefined && prelight !== false) return state;
      const regularSkills = state.regularSkills.filter((skill) => skill.name !== skillName);
      return regularSkills.length === state.regularSkills.length ? state : { ...state, regularSkills };
    }
    case 'PrelightSkill': {
      const [skillName, prelight] = arr;
      if (!validSkillName(skillName) || typeof prelight !== 'boolean') return state;
      let changed = false;
      const fakeSkills = state.fakeSkills.map((skill) => {
        if (skill.name !== skillName) return skill;
        changed = true;
        return { ...skill, prelighted: prelight, enabled: true };
      });
      return changed ? { ...state, fakeSkills } : state;
    }
    case 'ArrangeSeats':
    case 'PropertyUpdate':
    case 'SelfGenerals':
    case 'GeneralArtUpdate':
    case 'VisibleKingdom':
    case 'EquipmentUpdate':
    case 'SetPlayerMark':
    case 'SetBanner':
    case 'GameLog':
    case 'PilesUpdate':
    case 'SelfHand':
      return { ...state, board: updateBoard(state.board, command, data, state.players.map((p) => p.id), state.ownId,
        state.roomMode === 'new_heg_mode') };
    case 'NetStateChanged': {
      const [id, netState] = entries(data);
      if (!Number.isInteger(id) || typeof netState !== 'string' ||
          !['online', 'trust', 'run', 'robot', 'offline'].includes(netState)) return state;
      return { ...state, players: state.players.map((player) => player.id === id
        ? { ...player, netState: netState as RoomPlayer['netState'] } : player) };
    }
    case 'ErrorMsg':
    case 'ErrorDlg':
      return { ...state, error: connectionError(typeof data === 'string' ? data : JSON.stringify(data)) };
    default:
      return state;
  }
}

interface GameActions {
  update(patch: Partial<GameSnapshot>): void;
  dispatch(command: string, data: unknown): void;
  reset(): void;
}

export const useGameStore = create<GameSnapshot & GameActions>((set) => ({
  ...initialSnapshot,
  update: (patch) => set(patch),
  dispatch: (command, data) => set((state) => reduceUiEvent(state, command, data)),
  reset: () => set(initialSnapshot),
}));
