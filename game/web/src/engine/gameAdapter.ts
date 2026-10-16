import { SessionRecovery } from './recovery';
import { loadGatewayBundle, type LoadedBundle } from './bundle';
import { GameConnection, webSocketOpener } from './connection';
import { useGameStore } from '../store/gameStore';
import { emptyBoard } from '../store/boardState';
import { emptyGameplay, type GameplayItemType } from '../store/gameplayState';
import { connectionProgress, connectionError } from './connectionMessages';

export interface GameModeInfo {
  name: string;
  orig_name: string;
  minPlayer: number;
  maxPlayer: number;
}

export interface RoomPack { id: string; label: string; count: number }
export interface RoomPacks { generals: RoomPack[]; cards: RoomPack[] }
export interface RoomGeneral {
  id: string;
  trueName: string;
  kingdom?: string;
  subkingdom?: string;
  package: string;
  label: string;
}
export interface PoolSummary { generals: number; cards: number }

export class GameAdapter {
  private loaded: LoadedBundle | null = null;
  private connection: GameConnection | null = null;
  private generation = 0;
  private recovery: SessionRecovery | null = null;
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
      phase: 'login', connection: { kind: 'booting' }, rooms: [], players: [], observers: [], ownId: null, roomIsObserver: false, fakeSkills: [], regularSkills: [], result: null, board: emptyBoard() });
    useGameStore.getState().update({ gameplay: emptyGameplay() });

    // Keep credentials in the connection only. Neither Zustand nor browser
    // storage receives them; this server auto-registers unknown usernames.
    let hadOnline = false;
    let serverRejected = false;
    let recovery: SessionRecovery;
    const endSession = (reason: string) => {
      recovery.stop();
      useGameStore.getState().update({ phase: 'login', pendingRequest: null, skillInvoke: null, fakeSkills: [], regularSkills: [], initialGeneral: null, observers: [], roomIsObserver: false,
        board: emptyBoard(), gameplay: emptyGameplay(), result: null,
        progress: '', error: useGameStore.getState().error || connectionError(reason) });
    };
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
        if (command === 'ErrorDlg' || command === 'ErrorMsg') { serverRejected = true; recovery.stop(); }
        useGameStore.getState().dispatch(command, data);
      },
      onStatus: (status) => {
        if (generation !== this.generation) return;
        useGameStore.getState().update({ connection: status, progress: connectionProgress(status) });
        if (status.kind === 'online') {
          hadOnline = true;
          recovery.restored();
          // EnterLobby fires before GameConnection commits its online status.
          // The upstream Setup callback has already populated Self by now.
          const ownId = connection.lua.eval<number | null>('return Self and Self.id or nil');
          useGameStore.getState().update({ ownId });
          if (useGameStore.getState().phase === 'lobby') this.refreshRooms();
        }
        if (status.kind === 'closed') {
          const transportLoss = /^(closed \(\d+\)|backend closed|backend error|connect timeout|recovery timeout)/.test(status.reason);
          if (hadOnline && !serverRejected && transportLoss) recovery.lost();
          else endSession(status.reason);
        }
      },
      onRequest: (request) => {
        if (generation === this.generation) useGameStore.getState().update({ pendingRequest: request,
          ...(request?.command === 'AskForSkillInvoke' ? { skillInvoke: request.skillInvokePrompt ?? null } : {}),
          ...(!request ? { skillInvoke: null, initialGeneral: null, gameplay: emptyGameplay() } : {}) });
      },
      log: (level, msg) => {
        if (level === 'error') console.error(`[FreeKill Lua] ${msg}`);
        else if (level === 'warn' && msg.startsWith('AskForCardsAndChoice prompt rejected'))
          console.warn(`[FreeKill Lua] ${msg}`);
      },
    });
    recovery = new SessionRecovery({
      waiting: (attempt) => {
        if (generation !== this.generation) return;
        useGameStore.getState().update({ progress: `Mất kết nối. Đang thử khôi phục phiên (${attempt}/5)…`,
          pendingRequest: null, skillInvoke: null, fakeSkills: [], regularSkills: [], initialGeneral: null, gameplay: emptyGameplay(), board: emptyBoard() });
      },
      connect: () => { if (generation === this.generation) connection.connect(); },
      timeout: () => { if (generation === this.generation) connection.abortTransport('recovery timeout'); },
      exhausted: () => { if (generation === this.generation) endSession('Không thể khôi phục sau 5 lần thử. Hãy kiểm tra mạng và đăng nhập lại.'); },
    });
    this.recovery = recovery;
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

  getRoomPacks(): RoomPacks {
    return this.requireConnection().lua.call<RoomPacks>('__web_room_packs', 'new_heg_mode');
  }

  getRoomGenerals(disabledPacks: string[] = []): RoomGeneral[] {
    return this.requireConnection().lua.call<RoomGeneral[]>('__web_room_generals', 'new_heg_mode', disabledPacks);
  }

  getRoomPoolSummary(disabledPacks: string[], disabledGenerals: string[] = []): PoolSummary {
    return this.requireConnection().lua.call<PoolSummary>('__web_room_pool_summary', 'new_heg_mode', disabledPacks, disabledGenerals);
  }

  createRoom(name: string, capacity: number, timeout = 30, disabledPacks: string[] = [], disabledGenerals: string[] = [], modeSettings: Record<string, boolean> = {}) {
    const roomName = name.trim();
    if (!roomName || roomName.length > 80) throw new Error('Tên phòng phải dài từ 1 đến 80 ký tự');
    const conn = this.requireConnection();
    const feasible = conn.lua.call<boolean>('__web_room_feasible', 'new_heg_mode', capacity, timeout);
    if (!feasible) throw new Error('Số người chơi không hợp lệ theo luật Quốc Chiến');
    const pool = this.getRoomPoolSummary(disabledPacks, disabledGenerals);
    if (pool.generals < capacity * 5) {
      throw new Error(`Bể tướng còn ${pool.generals} tướng khác tên, cần ít nhất ${capacity * 5} cho ${capacity} người.`);
    }
    if (pool.cards < capacity * 4) {
      throw new Error(`Bể bài còn ${pool.cards} lá, cần ít nhất ${capacity * 4} lá chia ban đầu.`);
    }
    // Match native _game settings: choosing generals and creating requests
    // require generalNum/generalTimeout; luckTime controls the opening redraw.
    const settings = { gameMode: 'new_heg_mode', roomName, password: '',
      _game: { generalNum: 5, generalTimeout: timeout, timeoutAsGeneralTimeout: true,
        luckTime: 0, enableFreeAssign: false, enableDeputy: true,
        disableSameConvert: false, enableObserverViewCard: false, enableObserverViewFakeSkills: false },
      _mode: Object.fromEntries(Object.entries(modeSettings).filter(([key, value]) =>
        ['old_battle_royal', 'enterBattleRoyalOnFirstShuffle', 'revealAllOnStart'].includes(key) && typeof value === 'boolean')),
      disabledPack: [...disabledPacks], disabledGenerals: [...disabledGenerals] };
    this.notify('CreateRoom', [roomName, capacity, timeout, settings]);
  }

  joinRoom(roomId: number, password = '') {
    if (!Number.isInteger(roomId) || roomId <= 0) throw new Error('ID phòng không hợp lệ');
    this.notify('EnterRoom', [roomId, password]);
  }

  observeRoom(roomId: number, password = '') {
    if (!Number.isInteger(roomId) || roomId <= 0) throw new Error('ID phòng không hợp lệ');
    this.notify('ObserveRoom', [roomId, password]);
  }

  ready() { this.notify('Ready', ''); }
  start() { this.notify('StartGame', ''); }
  addBot() { this.notify('AddRobot', ''); }
  switchToObserver() { this.notify('SwitchToObserver', ''); }
  switchToPlayer() { this.notify('SwitchToPlayer', ''); }
  leaveRoom() { this.notify('QuitRoom', ''); }
  toggleTrust() {
    if (useGameStore.getState().phase !== 'playing') throw new Error('BOT chơi hộ chỉ dùng trong ván đang chạy');
    this.requireConnection().toggleTrust();
  }

  prelightSkill(skillName: string, prelight: boolean) {
    if (useGameStore.getState().phase !== 'playing') throw new Error('Prelight chỉ dùng trong ván đang chạy');
    this.requireConnection().prelightSkill(skillName, prelight);
  }

  getModes(): GameModeInfo[] {
    return this.requireConnection().lua.call<GameModeInfo[]>('GetGameModes');
  }

  /** Forward only a user's explicit decision to the current Lua request. */
  sendUiAction(requestId: number, choice: 'OK' | 'Cancel') {
    this.requireConnection().respondToSkillInvoke(requestId, choice);
  }

  respondToChoices(requestId: number, selected: string[]) {
    this.requireConnection().respondToChoices(requestId, selected);
  }

  getCardSelectionView(requestId: number, selected: string[]) {
    return this.requireConnection().getCardSelectionView(requestId, selected);
  }

  respondToCardSelection(requestId: number, selected: string[], cancel = false) {
    this.requireConnection().respondToCardSelection(requestId, selected, cancel);
  }

  getCardsAndChoiceView(requestId: number, selected: string[]) {
    return this.requireConnection().getCardsAndChoiceView(requestId, selected);
  }

  respondToCardsAndChoice(requestId: number, selected: string[], choice: string, cancel = false) {
    this.requireConnection().respondToCardsAndChoice(requestId, selected, choice, cancel);
  }

  getNativeDialogView(requestId: number) { return this.requireConnection().getNativeDialogView(requestId); }
  selectNativeGeneral(requestId: number, token: string) { this.requireConnection().selectNativeGeneral(requestId, token); }
  moveNativeDialogCard(requestId: number, token: string, area: number, index: number) {
    this.requireConnection().moveNativeDialogCard(requestId, token, area, index);
  }
  respondToNativeDialog(requestId: number, token?: string, cancel = false) {
    this.requireConnection().respondToNativeDialog(requestId, token, cancel);
  }

  updateRequestUI(requestId: number, type: GameplayItemType, id: string | number,
    action: 'click' | 'update' | 'finish', data: unknown) {
    this.requireConnection().updateRequestUI(requestId, type, id, action, data);
  }

  finishDirectInteraction(requestId: number, id: string | number, data: unknown) {
    this.requireConnection().finishDirectInteraction(requestId, id, data);
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
    this.recovery?.stop();
    this.recovery = null;
    ++this.generation;
    const old = this.connection;
    this.connection = null;
    if (old) {
      old.close();
      old.lua.close();
    }
  }
}
