import { loadGatewayBundle, type LoadedBundle } from './bundle';
import { GameConnection, webSocketOpener } from './connection';
import { useGameStore } from '../store/gameStore';
import { emptyBoard } from '../store/boardState';
import { emptyGameplay, type GameplayItemType } from '../store/gameplayState';

export interface GameModeInfo {
  name: string;
  orig_name: string;
  minPlayer: number;
  maxPlayer: number;
}

export class GameAdapter {
  private loaded: LoadedBundle | null = null;
  private connection: GameConnection | null = null;
  private generation = 0;
  private readonly gateway: string;

  constructor(gateway: string) {
    this.gateway = gateway.replace(/\/$/, '');
  }

  async boot(signal?: AbortSignal): Promise<void> {
    const generation = ++this.generation;
    useGameStore.getState().update({ phase: 'boot', error: null, progress: 'Đang kết nối Gateway…' });
    try {
      const loaded = await loadGatewayBundle(this.gateway, signal, (progress) => {
        if (this.generation === generation) useGameStore.getState().update({ progress });
      });
      if (generation !== this.generation || signal?.aborted) return;
      this.loaded = loaded;
      useGameStore.getState().update({ phase: 'login', manifest: loaded.manifest, progress: 'Package đã được xác minh' });
    } catch (error) {
      if (generation !== this.generation || signal?.aborted) return;
      useGameStore.getState().update({ progress: '', error: String((error as Error).message) });
    }
  }

  async login(username: string, password: string): Promise<void> {
    if (!this.loaded) throw new Error('Chưa tải và xác minh package Lua');
    const name = username.trim();
    if (!name || !password) throw new Error('Nhập tài khoản và mật khẩu hợp lệ');
    this.disconnect();
    const generation = ++this.generation;
    const store = useGameStore.getState();
    store.update({ progress: 'Đang khởi tạo Lua WASM…', error: null,
      phase: 'login', connection: { kind: 'booting' }, rooms: [], players: [], ownId: null, board: emptyBoard() });
    useGameStore.getState().update({ gameplay: emptyGameplay() });

    // Keep credentials in the connection only. Neither Zustand nor browser
    // storage receives them; this server auto-registers unknown usernames.
    const connection = new GameConnection({
      files: this.loaded.files, username: name, password,
      md5: this.loaded.manifest.md5,
      uuid: crypto.randomUUID(),
      wasmUrl: `${import.meta.env.BASE_URL}glue.wasm`,
      openSocket: webSocketOpener((() => {
        const url = new URL(`${this.gateway}/ws`, location.href);
        url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
        return url.href;
      })()),
      onUi: (command, data) => {
        if (generation !== this.generation) return;
        useGameStore.getState().dispatch(command, data);
      },
      onStatus: (status) => {
        if (generation !== this.generation) return;
        useGameStore.getState().update({ connection: status, progress: status.kind === 'online' ? '' : status.kind });
        if (status.kind === 'online') {
          // EnterLobby fires before GameConnection commits its online status.
          // The upstream Setup callback has already populated Self by now.
          const ownId = connection.lua.eval<number | null>('return Self and Self.id or nil');
          useGameStore.getState().update({ ownId });
          this.refreshRooms();
        }
        if (status.kind === 'closed') useGameStore.getState().update({ phase: 'login', pendingRequest: null, skillInvoke: null, initialGeneral: null,
          board: emptyBoard(), gameplay: emptyGameplay(), error: status.reason });
      },
      onRequest: (request) => {
        if (generation === this.generation) useGameStore.getState().update({ pendingRequest: request,
          ...(!request ? { skillInvoke: null, initialGeneral: null, gameplay: emptyGameplay() } : {}) });
      },
      log: (level, msg) => {
        if (level === 'error') console.error(`[FreeKill Lua] ${msg}`);
      },
    });
    this.connection = connection;
    try {
      await connection.start();
      if (generation !== this.generation) return;
    } catch (error) {
      if (generation !== this.generation) return;
      this.disconnect();
      useGameStore.getState().update({ phase: 'login', progress: '', error: String((error as Error).message) });
    }
  }

  private requireConnection(): GameConnection {
    if (!this.connection || this.connection.getStatus().kind !== 'online') {
      throw new Error('Chưa xác thực với máy chủ');
    }
    return this.connection;
  }

  private notify(command: string, data: unknown) {
    this.requireConnection().lua.call('__web_notify', command, data);
  }

  refreshRooms() { this.notify('RefreshRoomList', ''); }

  createRoom(name: string, capacity: number, timeout = 30) {
    const roomName = name.trim();
    if (!roomName || roomName.length > 80) throw new Error('Tên phòng phải dài từ 1 đến 80 ký tự');
    const conn = this.requireConnection();
    const feasible = conn.lua.call<boolean>('__web_room_feasible', 'new_heg_mode', capacity, timeout);
    if (!feasible) throw new Error('Số người chơi không hợp lệ theo luật Quốc Chiến');
    const settings = { gameMode: 'new_heg_mode', roomName, password: '',
      _game: {}, _mode: {}, disabledPack: [], disabledGenerals: [] };
    this.notify('CreateRoom', [roomName, capacity, timeout, settings]);
  }

  joinRoom(roomId: number, password = '') {
    if (!Number.isInteger(roomId) || roomId <= 0) throw new Error('ID phòng không hợp lệ');
    this.notify('EnterRoom', [roomId, password]);
  }

  ready() { this.notify('Ready', ''); }
  start() { this.notify('StartGame', ''); }
  addBot() { this.notify('AddRobot', ''); }
  leaveRoom() { this.notify('QuitRoom', ''); }

  getModes(): GameModeInfo[] {
    return this.requireConnection().lua.call<GameModeInfo[]>('GetGameModes');
  }

  /** Forward only a user's explicit decision to the current Lua request. */
  sendUiAction(requestId: number, choice: 'OK' | 'Cancel') {
    this.requireConnection().respondToSkillInvoke(requestId, choice);
  }

  updateRequestUI(requestId: number, type: GameplayItemType, id: string | number,
    action: 'click' | 'finish', data: unknown) {
    this.requireConnection().updateRequestUI(requestId, type, id, action, data);
  }

  getInitialGeneralKingdoms(requestId: number, main: string, deputy: string) {
    return this.requireConnection().getInitialGeneralKingdoms(requestId, main, deputy);
  }

  getGeneralLabels(generals: string[]): string[] {
    return this.requireConnection().lua.call<string[]>('__web_general_labels', generals);
  }

  chooseInitialGenerals(requestId: number, main: string, deputy: string, kingdom: string) {
    this.requireConnection().respondToInitialGeneral(requestId, main, deputy, kingdom);
  }

  disconnect() {
    ++this.generation;
    const old = this.connection;
    this.connection = null;
    if (old) {
      old.close();
      old.lua.close();
    }
  }
}
