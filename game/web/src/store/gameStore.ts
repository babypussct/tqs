import { create } from 'zustand';
import type { ConnectionStatus, RequestInfo } from '../engine/connection';
import type { GatewayManifest } from '../engine/bundle';
import { parseInitialGeneralPrompt, type InitialGeneralPrompt } from '../engine/generalSelection';
import { emptyBoard, updateBoard, type BoardState } from './boardState';
import { emptyGameplay, reduceGameplay, type GameplayScene } from './gameplayState';
import { connectionError } from '../engine/connectionMessages';

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

export interface SkillInvokePrompt {
  skill: string;
  prompt: string;
}

export type GamePhase = 'boot' | 'login' | 'lobby' | 'room' | 'playing';

export interface GameResult {
  outcome: 'win' | 'loss' | 'draw' | 'unknown';
  winners: { id: number; name: string }[];
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

/** Pure reducer: the Lua client has already decoded and handled this event. */
export function reduceUiEvent(state: GameSnapshot, command: string, data: unknown): GameSnapshot {
  if (command === 'SelfIdentity') return typeof data === 'number' && Number.isSafeInteger(data) && data > 0
    ? { ...state, ownId: data } : state;
  const arr = entries(data);
  switch (command) {
    case 'DisplayTranslations':
      return data && typeof data === 'object' && !Array.isArray(data)
        ? { ...state, translations: Object.fromEntries(Object.entries(data).filter(([key, value]) =>
          key.length <= 300 && typeof value === 'string' && value.length <= 30000)) }
        : state;
    case 'EnterLobby':
      return { ...state, phase: 'lobby', error: null, roomName: '', roomMode: '',
        roomDisabledPacks: [], roomDisabledGenerals: [],
        result: null,
        capacity: 0, players: [], pendingRequest: null, skillInvoke: null, initialGeneral: null,
        board: emptyBoard(), gameplay: emptyGameplay() };
    case 'CancelRequest':
      return { ...state, pendingRequest: null, skillInvoke: null, initialGeneral: null,
        gameplay: emptyGameplay() };
    case 'UpdateRequestUI':
      return { ...state, gameplay: reduceGameplay(state.gameplay, data) };
    case 'CustomDialog':
      return { ...state, initialGeneral: parseInitialGeneralPrompt(data) };
    case 'AskForSkillInvoke':
      return Array.isArray(data) && typeof data[0] === 'string' && typeof data[1] === 'string'
        ? { ...state, skillInvoke: { skill: data[0], prompt: data[1] } }
        : state;
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
        skillInvoke: null, initialGeneral: null, board: emptyBoard(), gameplay: emptyGameplay() };
    case 'GameOver':
      return { ...state, phase: 'room', pendingRequest: null, skillInvoke: null,
        result: gameResult(state, data),
        initialGeneral: null, board: emptyBoard(), gameplay: emptyGameplay() };
    case 'ArrangeSeats':
    case 'PropertyUpdate':
    case 'SelfGenerals':
    case 'VisibleKingdom':
    case 'EquipmentUpdate':
    case 'SetPlayerMark':
    case 'SetBanner':
    case 'GameLog':
      return { ...state, board: updateBoard(state.board, command, data, state.players.map((p) => p.id), state.ownId) };
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
