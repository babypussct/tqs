import { parseNativeDialog, movedRows, type NativeDialog, type NativeDialogPrompt } from './nativeDialogs';
// SPDX-License-Identifier: GPL-3.0-or-later
//
// GameConnection = socket transport + packet framing + login handshake +
// the Lua client runtime. UI code only sees `onUi(command, data)` events
// (the same events the original QML received) and calls back into Lua via
// `lua.call(...)` / `lua.eval(...)`.

import { parseCardsAndChoice, cardsAndChoiceIds, type CardsAndChoicePrompt, type CardsAndChoiceSelection } from './cardsAndChoice';
import { parseCardSelection, selectionIds, type CardSelection, type CardSelectionPrompt, type PoxiView } from './cardSelection';
import forge from 'node-forge';
import { LuaRuntime } from './luaRuntime';
import { parseInitialGeneralPrompt, type InitialGeneralPrompt } from './generalSelection';
import { emptyGameplay, getGameplayItem, reduceGameplay, GAMEPLAY_REQUESTS,
  type GameplayItemType, type GameplayScene } from '../store/gameplayState';
import { validInteractionAction } from './gameplayInteraction';
import { parseChoicePrompt, validChoiceReply, type ChoicePrompt } from './choiceSelection';
import { parseSkillInvokePrompt, type SkillInvokePrompt } from './skillInvoke';
import {
  CLIENT_NOTIFY,
  CLIENT_REPLY,
  PacketStream,
  PacketType,
  encodePacket,
  encodeTextArray,
  fromHex,
  toHex,
  type Packet,
} from './packet';

/** Client version reported to freekill-asio (accepted range: >=0.5.22 <0.6.0). */
export const CLIENT_VERSION = '0.5.25';

export interface SocketHandlers {
  onData(b: Uint8Array): void;
  onClose(reason: string): void;
}
export interface SocketLike {
  send(b: Uint8Array): void;
  close(): void;
}

export interface RequestInfo {
  requestId: number;
  command: string;
  timeout: number;
  receivedAt: number;
  expiresAt: number | null;
  nativeDialogPrompt?: NativeDialogPrompt | null;
  choicePrompt?: ChoicePrompt | null;
  cardSelectionPrompt?: CardSelectionPrompt | null;
  cardsAndChoicePrompt?: CardsAndChoicePrompt | null;
  skillInvokePrompt?: SkillInvokePrompt | null;
}

export interface GameConnectionOptions {
  files: Map<string, Uint8Array>;
  username: string;
  password: string;
  md5: string;
  uuid: string;
  language?: string;
  wasmUrl?: string;
  openSocket(h: SocketHandlers): SocketLike;
  onUi(command: string, data: unknown): void;
  onStatus?(s: ConnectionStatus): void;
  onRequest?(r: RequestInfo | null): void;
  log?(level: string, msg: string): void;
}

export type ConnectionStatus =
  | { kind: 'booting' }
  | { kind: 'connecting' }
  | { kind: 'authenticating' }
  | { kind: 'online' }
  | { kind: 'closed'; reason: string };

const textDecoder = new TextDecoder();

function jsonWithin(value: unknown, max: number): boolean {
  try {
    const encoded = JSON.stringify(value);
    return encoded !== undefined && encoded.length <= max;
  } catch {
    return false;
  }
}

export class GameConnection {
  readonly lua: LuaRuntime;
  private socket: SocketLike | null = null;
  private stream = new PacketStream();
  private pendingRequest: RequestInfo | null = null;
  private authorizedRequest: RequestInfo | null = null;
  private capturedReply: unknown = null;
  private gameplayScene: GameplayScene = emptyGameplay();
  private gameplaySceneRevision = 0;
  private receivingRequestCommand: string | null = null;
  private initialGeneralPrompt: InitialGeneralPrompt | null = null;
  private choicePrompt: ChoicePrompt | null = null;
  private cardSelection: CardSelection | null = null;
  private nativeDialog: NativeDialog | null = null;
  private nativeDialogPayload: { command: string; data: unknown } | null = null;
  private cardsAndChoice: CardsAndChoiceSelection | null = null;
  private cardSelectionPayload: { command: string; data: unknown } | null = null;
  private skillInvokePrompt: SkillInvokePrompt | null = null;
  private expectedReplyHex: string | null = null;
  private completedAuthorizedReply: RequestInfo | null = null;
  private sendingAuthorizedReply = false;
  private status: ConnectionStatus = { kind: 'booting' };
  private luaReady = false;
  private socketGeneration = 0;
  // Synchronous Lua callbacks can re-enter the connection. Keep the socket
  // generation that started the current server dispatch so a stale callback
  // cannot notify a socket opened by a reentrant reconnect.
  private luaDispatchGeneration: number | null = null;
  private requestGeneration = 0;
  private requestExpiryTimer: ReturnType<typeof setTimeout> | null = null;
  private stopped = false;

  constructor(private opts: GameConnectionOptions) {
    this.lua = new LuaRuntime({
      files: opts.files,
      language: opts.language,
      wasmUrl: opts.wasmUrl,
      callbacks: {
        send: (kind, command, hex) => this.sendFromLua(kind, command, hex),
        ui: (command, data) => this.handleLuaUi(command, data),
        setup: (pubkey) => this.sendSetup(pubkey),
        log: opts.log,
      },
    });
  }

  private setStatus(s: ConnectionStatus) {
    this.status = s;
    this.opts.onStatus?.(s);
  }

  getStatus() {
    return this.status;
  }

  toggleTrust() {
    if (this.status.kind !== 'online' || !this.socket) throw new Error('Chưa xác thực với máy chủ');
    this.lua.call('__web_notify', 'Trust', '');
  }

  /** Match the native dashboard's PushRequest("prelight,...") contract. */
  prelightSkill(skillName: string, prelight: boolean) {
    if (this.status.kind !== 'online' || !this.socket) throw new Error('Chưa xác thực với máy chủ');
    if (typeof skillName !== 'string' || skillName.length === 0 || skillName.length > 150 ||
        /[\u0000-\u001F\u007F,]/.test(skillName) || typeof prelight !== 'boolean') {
      throw new Error('Tên kỹ năng prelight không hợp lệ');
    }
    this.lua.call('__web_notify', 'PushRequest', `prelight,${skillName},${prelight ? 'true' : 'false'}`);
  }

  private clearRequest() {
    if (this.requestExpiryTimer !== null) {
      clearTimeout(this.requestExpiryTimer);
      this.requestExpiryTimer = null;
    }
    this.pendingRequest = null;
    this.authorizedRequest = null;
    this.capturedReply = null;
    this.initialGeneralPrompt = null;
    this.choicePrompt = null;
    this.cardSelection = null;
    this.cardsAndChoice = null;
    this.nativeDialog = null;
    this.nativeDialogPayload = null;
    this.cardSelectionPayload = null;
    this.skillInvokePrompt = null;
    this.expectedReplyHex = null;
    this.completedAuthorizedReply = null;
    this.sendingAuthorizedReply = false;
    this.gameplayScene = emptyGameplay();
    this.opts.onRequest?.(null);
  }

  /** Expiry is transport state, not just a disabled-button hint. This keeps a
   * request from surviving indefinitely when the server never sends the next
   * callback and makes request-id reuse safe after a timeout. */
  private scheduleRequestExpiry(request: RequestInfo) {
    if (this.requestExpiryTimer !== null) {
      clearTimeout(this.requestExpiryTimer);
      this.requestExpiryTimer = null;
    }
    // A packet can arrive after its server timestamp has already elapsed.
    // Keep that request visible as an expired/disabled prompt so the UI can
    // explain the state; the next user action or server lifecycle event clears
    // it. Requests that expire while waiting are cleared by the timer below.
    if (request.expiresAt === null || request.expiresAt <= Date.now() || this.pendingRequest !== request) return;
    const expire = () => {
      if (this.pendingRequest !== request || request.expiresAt === null) return;
      const remaining = request.expiresAt - Date.now();
      if (remaining > 0) {
        this.requestExpiryTimer = setTimeout(expire, Math.min(remaining, 2_147_483_647));
        (this.requestExpiryTimer as unknown as { unref?: () => void }).unref?.();
        return;
      }
      this.requestExpiryTimer = null;
      this.opts.log?.('info', `Request expired: ${request.command}`);
      this.clearRequest();
    };
    this.requestExpiryTimer = setTimeout(expire, Math.max(0,
      Math.min(request.expiresAt - Date.now(), 2_147_483_647)));
    (this.requestExpiryTimer as unknown as { unref?: () => void }).unref?.();
  }

  /** A UI click changes Lua's scene; only Lua may decide when to reply. */
  updateRequestUI(requestId: number, type: GameplayItemType, id: string | number,
    action: 'click' | 'update' | 'finish', data: unknown) {
    const pending = this.pendingRequest;
    if (this.status.kind !== 'online' || !this.socket || !pending ||
        pending.requestId !== requestId || !GAMEPLAY_REQUESTS.has(pending.command)) {
      throw new Error('Yêu cầu gameplay không còn hiệu lực');
    }
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      this.clearRequest();
      throw new Error('Yêu cầu gameplay đã hết thời gian');
    }
    if (this.authorizedRequest !== null) throw new Error('Đang xử lý câu trả lời');
    const item = getGameplayItem(this.gameplayScene, type, id);
    if (!item?.enabled || item.id !== id) throw new Error('Lựa chọn không được Lua cho phép');
    if (type === 'CardItem' || type === 'Photo' || type === 'SkillButton') {
      if (action !== 'click' || !data || typeof data !== 'object' ||
          (data as { selected?: unknown }).selected !== !item.selected) {
        throw new Error('Trạng thái lựa chọn không hợp lệ');
      }
      data = type === 'SkillButton'
        ? { selected: !item.selected, autoTarget: false }
        : { selected: !item.selected };
    } else if (type === 'Button') {
      if (action !== 'click' || !['OK', 'Cancel', 'End'].includes(String(id)))
        throw new Error('Nút gameplay không hợp lệ');
      data = {};
    } else if (type === 'SpecialSkills') {
      if (action !== 'click' || typeof data !== 'string' || !item.skills?.includes(data))
        throw new Error('Kỹ năng đặc biệt không hợp lệ');
    } else if (type === 'Interaction') {
      if (!validInteractionAction(item, action, data))
        throw new Error('Tương tác không được Lua cho phép');
    }

    this.authorizedRequest = pending;
    this.capturedReply = null;
    try {
      this.lua.call('UpdateRequestUI', type, id, action, data);
      if (this.pendingRequest !== pending || this.status.kind !== 'online') {
        throw new Error('Yêu cầu gameplay đã thay đổi trong lúc xử lý');
      }
      if (this.capturedReply !== null) {
        const response = this.capturedReply;
        this.expectedReplyHex = this.lua.call<string>('__web_reply_hex', response).toLowerCase();
        this.sendingAuthorizedReply = true;
        try { this.lua.call('__web_reply', response); }
        finally { this.sendingAuthorizedReply = false; }
        if (this.completedAuthorizedReply !== pending) {
          throw new Error('Phản hồi gameplay chưa đến máy chủ');
        }
      }
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.capturedReply = null;
      this.expectedReplyHex = null;
      this.completedAuthorizedReply = null;
    }
  }

  /** A direct option finishes its Lua interaction before confirming, as QML does.
   * Lua may reply, replace the request, or advance to another interaction in
   * the first call; only confirm an OK that is still valid afterward. */
  finishDirectInteraction(requestId: number, id: string | number, data: unknown) {
    const original = this.pendingRequest;
    const sceneRevision = this.gameplaySceneRevision;
    try {
      this.updateRequestUI(requestId, 'Interaction', id, 'finish', data);
    } catch (error) {
      // Lua may synchronously cancel/replace the request while handling finish.
      if (original && this.pendingRequest !== original && error instanceof Error &&
          error.message === 'Yêu cầu gameplay đã thay đổi trong lúc xử lý') return;
      throw error;
    }
    if (!original || this.pendingRequest !== original) return;
    // An UpdateRequestUI callback may advance Lua to the next step while
    // reusing the same interaction ID, spec and refresh_data. Whenever Lua
    // publishes a scene during finish and leaves any interaction enabled,
    // require the player to decide what to do next. A finished/disabled
    // interaction with an enabled OK may still be confirmed automatically.
    if (this.gameplaySceneRevision !== sceneRevision &&
        Object.values(this.gameplayScene.items.Interaction).some((item) => item.enabled)) return;
    if (!getGameplayItem(this.gameplayScene, 'Button', 'OK')?.enabled) return;
    this.updateRequestUI(requestId, 'Button', 'OK', 'click', null);
  }

  /** Only a deliberate button click may send a reply to the active Lua request. */
  respondToSkillInvoke(requestId: number, choice: 'OK' | 'Cancel') {
    const pending = this.pendingRequest;
    if (this.status.kind !== 'online' || !this.socket || !pending ||
        pending.command !== 'AskForSkillInvoke' || pending.requestId !== requestId) {
      throw new Error('Yêu cầu kỹ năng không còn hiệu lực');
    }
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      this.clearRequest();
      throw new Error('Yêu cầu kỹ năng đã hết thời gian trả lời');
    }
    if (this.authorizedRequest !== null) throw new Error('Đang xử lý câu trả lời');
    this.authorizedRequest = pending;
    this.capturedReply = null;
    try {
      this.lua.call('UpdateRequestUI', 'Button', choice);
      const expected = choice === 'OK' ? '1' : '__cancel';
      if (this.pendingRequest !== pending || this.capturedReply !== expected) {
        throw new Error('Lua chưa tạo phản hồi cho lựa chọn kỹ năng');
      }
      // Lua -> JS notifyUI occurs while UpdateRequestUI is running. Defer the
      // JS -> Lua CBOR call until that invocation finishes to avoid reentry.
      this.sendingAuthorizedReply = true;
      try {
        this.lua.call('__web_reply', expected);
      } finally {
        this.sendingAuthorizedReply = false;
      }
      if (this.completedAuthorizedReply !== pending) {
        throw new Error('Phản hồi Lua chưa được chuyển tới máy chủ');
      }
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.capturedReply = null;
      this.completedAuthorizedReply = null;
    }
  }

  /** Read-only Lua engine validation for the active Hegemony CustomDialog. */
  getInitialGeneralKingdoms(requestId: number, main: string, deputy: string): string[] {
    const pending = this.pendingRequest;
    const prompt = this.initialGeneralPrompt;
    if (this.status.kind !== 'online' || !pending || !prompt ||
        pending.command !== 'CustomDialog' || pending.requestId !== requestId ||
        (pending.expiresAt !== null && Date.now() >= pending.expiresAt) ||
        !prompt.generals.includes(main) || !prompt.generals.includes(deputy) || main === deputy) return [];
    const result = this.lua.call<unknown>('__web_general_kingdoms', main, deputy, prompt.enabledKingdoms);
    return Array.isArray(result) && result.every((k) => typeof k === 'string' && prompt.enabledKingdoms.includes(k))
      ? result as string[] : [];
  }

  /** A user-confirmed initial-general selection is the sole path to CLIENT_REPLY. */
  respondToInitialGeneral(requestId: number, main: string, deputy: string, kingdom: string) {
    const pending = this.pendingRequest;
    const prompt = this.initialGeneralPrompt;
    if (this.status.kind !== 'online' || !this.socket || !pending || !prompt ||
        pending.command !== 'CustomDialog' || pending.requestId !== requestId) {
      throw new Error('Yêu cầu chọn tướng không còn hiệu lực');
    }
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      this.clearRequest();
      throw new Error('Yêu cầu chọn tướng đã hết thời gian');
    }
    if (this.authorizedRequest) throw new Error('Đang xử lý câu trả lời');
    if (!this.getInitialGeneralKingdoms(requestId, main, deputy).includes(kingdom)) {
      throw new Error('Cặp chủ/phó tướng hoặc thế lực không hợp lệ');
    }

    this.authorizedRequest = pending;
    try {
      const args = [main, deputy, kingdom, prompt.enabledKingdoms] as const;
      // Prepare and compare exact bytes with Lua's CBOR encoder; the transport
      // cannot send unsolicited Lua responses even during request callbacks.
      this.expectedReplyHex = this.lua.call<string>('__web_general_reply_hex', ...args).toLowerCase();
      this.sendingAuthorizedReply = true;
      try {
        this.lua.call('__web_general_reply', ...args);
      } finally {
        this.sendingAuthorizedReply = false;
      }
      if (this.completedAuthorizedReply !== pending) throw new Error('Phản hồi chọn tướng chưa tới máy chủ');
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.expectedReplyHex = null;
      this.completedAuthorizedReply = null;
    }
  }

  /** Validate the native choice dialog against the active request before Lua encodes it. */
  respondToChoices(requestId: number, selected: string[]) {
    const pending = this.pendingRequest;
    const prompt = this.choicePrompt;
    if (this.status.kind !== 'online' || !this.socket || !pending || !prompt ||
        !['AskForChoices', 'AskForOptions'].includes(pending.command) || pending.requestId !== requestId)
      throw new Error('Yêu cầu lựa chọn không còn hiệu lực');
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      this.clearRequest();
      throw new Error('Yêu cầu lựa chọn đã hết thời gian');
    }
    if (this.authorizedRequest) throw new Error('Đang xử lý câu trả lời');
    if (!validChoiceReply(prompt, selected)) throw new Error('Lựa chọn không được máy chủ cho phép');
    this.authorizedRequest = pending;
    try {
      this.expectedReplyHex = this.lua.call<string>('__web_reply_hex', selected).toLowerCase();
      this.sendingAuthorizedReply = true;
      try { this.lua.call('__web_reply', selected); }
      finally { this.sendingAuthorizedReply = false; }
      if (this.completedAuthorizedReply !== pending) throw new Error('Phản hồi lựa chọn chưa đến máy chủ');
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.expectedReplyHex = null;
      this.completedAuthorizedReply = null;
    }
  }

  private requireCardSelection(requestId: number, clearExpired = true) {
    const pending = this.pendingRequest;
    if (this.status.kind !== 'online' || !this.socket || !pending ||
        pending.requestId !== requestId || !this.cardSelection ||
        !['AskForCardChosen', 'AskForPoxi'].includes(pending.command))
      throw new Error('Yêu cầu chọn bài không còn hiệu lực');
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      if (clearExpired) this.clearRequest();
      throw new Error('Yêu cầu chọn bài đã hết thời gian');
    }
    return { pending, selection: this.cardSelection };
  }

  /** Only public tokens and eligibility leave the connection; Lua owns Poxi rules. */
  getCardSelectionView(requestId: number, tokens: string[]): PoxiView {
    const { selection } = this.requireCardSelection(requestId, false);
    const selected = selectionIds(selection, tokens);
    if (!selected) throw new Error('Lựa chọn bài không hợp lệ');
    if (!selection.poxi) return { prompt: selection.publicPrompt.title,
      selectable: [...selection.ids.keys()], feasible: selected.length === 1 };
    const { type, data, extra } = selection.poxi;
    const candidates = [...selection.ids.values()];
    const view = this.lua.call<{ allowed: boolean[]; feasible: boolean; prompt: string }>(
      '__web_poxi_view', type, data, extra, selected, candidates);
    if (!view || !Array.isArray(view.allowed) || view.allowed.length !== candidates.length ||
        !view.allowed.every((v) => typeof v === 'boolean') ||
        typeof view.feasible !== 'boolean' || typeof view.prompt !== 'string')
      throw new Error('Luật chọn bài chưa sẵn sàng');
    return { prompt: view.prompt, feasible: view.feasible,
      selectable: [...selection.ids.keys()].filter((_, i) => view.allowed[i]) };
  }

  respondToCardSelection(requestId: number, tokens: string[], cancel = false) {
    const { pending, selection } = this.requireCardSelection(requestId);
    if (this.authorizedRequest) throw new Error('Đang xử lý câu trả lời');
    const ids = selectionIds(selection, tokens);
    if (!ids || (cancel && (!selection.publicPrompt.cancelable || tokens.length)))
      throw new Error('Lựa chọn bài không hợp lệ');
    if (!cancel) {
      // Validate every addition with the installed filter, then final feasibility.
      for (let i = 0; i < tokens.length; i++) {
        if (!this.getCardSelectionView(requestId, tokens.slice(0, i)).selectable.includes(tokens[i]))
          throw new Error('Lá bài không được Lua cho phép');
      }
      if (!this.getCardSelectionView(requestId, tokens).feasible)
        throw new Error('Chưa đủ điều kiện chọn bài');
    }
    const response = selection.publicPrompt.mode === 'single' ? ids[0] : ids;
    this.authorizedRequest = pending;
    try {
      this.expectedReplyHex = this.lua.call<string>('__web_reply_hex', response).toLowerCase();
      this.sendingAuthorizedReply = true;
      try { this.lua.call('__web_reply', response); }
      finally { this.sendingAuthorizedReply = false; }
      if (this.completedAuthorizedReply !== pending) throw new Error('Phản hồi chọn bài chưa đến máy chủ');
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.expectedReplyHex = null;
      this.completedAuthorizedReply = null;
    }
  }

  private requireCardsAndChoice(requestId: number, clearExpired = true) {
    const pending = this.pendingRequest;
    if (this.status.kind !== 'online' || !this.socket || !pending ||
        pending.requestId !== requestId || pending.command !== 'AskForCardsAndChoice' || !this.cardsAndChoice)
      throw new Error('Yêu cầu xem và chọn bài không còn hiệu lực');
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      if (clearExpired) this.clearRequest();
      throw new Error('Yêu cầu xem và chọn bài đã hết thời gian');
    }
    return { pending, selection: this.cardsAndChoice };
  }

  getCardsAndChoiceView(requestId: number, tokens: string[]) {
    const { selection } = this.requireCardsAndChoice(requestId, false);
    const ids = cardsAndChoiceIds(selection, tokens);
    if (!ids) throw new Error('Lựa chọn bài không hợp lệ');
    const prompt = selection.publicPrompt;
    const allowed = this.lua.call<boolean[]>('__web_cards_and_choice_view',
      selection.filter, ids, prompt.choices, prompt.min, prompt.max, selection.extra);
    if (!Array.isArray(allowed) || allowed.length !== prompt.choices.length ||
        !allowed.every((value) => typeof value === 'boolean')) throw new Error('Luật chọn phương án chưa sẵn sàng');
    return { selectable: [...selection.ids].filter(([, id]) => !selection.disabled.has(id)).map(([token]) => token),
      choices: prompt.choices.filter((_, i) => allowed[i]) };
  }

  respondToCardsAndChoice(requestId: number, tokens: string[], choice: string, cancel = false) {
    const { pending, selection } = this.requireCardsAndChoice(requestId);
    if (this.authorizedRequest) throw new Error('Đang xử lý câu trả lời');
    const ids = cardsAndChoiceIds(selection, tokens);
    if (!ids || (cancel ? tokens.length !== 0 || !selection.publicPrompt.cancelChoices.includes(choice) :
        !this.getCardsAndChoiceView(requestId, tokens).choices.includes(choice)))
      throw new Error('Phương án không được Lua cho phép');
    const response = { cards: ids, choice };
    this.authorizedRequest = pending;
    try {
      this.expectedReplyHex = this.lua.call<string>('__web_reply_hex', response).toLowerCase();
      this.sendingAuthorizedReply = true;
      try { this.lua.call('__web_reply', response); }
      finally { this.sendingAuthorizedReply = false; }
      if (this.completedAuthorizedReply !== pending) throw new Error('Phản hồi xem và chọn bài chưa đến máy chủ');
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null;
      this.expectedReplyHex = null;
      this.completedAuthorizedReply = null;
    }
  }

  private requireNativeDialog(requestId: number) {
    const pending = this.pendingRequest;
    if (!pending || pending.requestId !== requestId || !this.nativeDialog ||
      this.status.kind !== 'online' || !this.socket) throw new Error('Yêu cầu đã thay đổi');
    if (pending.expiresAt !== null && Date.now() >= pending.expiresAt) {
      // Card/gameplay/choice paths clear expired state before throwing. Native
      // dialogs must do the same so an expired AG/arrange/skill request cannot
      // remain rendered and later collide with a reused request ID.
      this.clearRequest();
      throw new Error('Yêu cầu đã hết thời gian');
    }
    return { pending, dialog: this.nativeDialog };
  }

  getNativeDialogView(requestId: number) {
    const { dialog } = this.requireNativeDialog(requestId);
    if (dialog.skills) {
      const skills = dialog.skills;
      return { rows: dialog.prompt.rows, feasible: skills.selected.length >= skills.min && skills.selected.length <= skills.max,
        selectedTokens: dialog.prompt.cards.filter(c => skills.selected.includes(c.name!)).map(c => c.token),
        selectableTokens: dialog.prompt.cards.filter(c => !skills.disabled?.includes(c.name!) && (dialog.prompt.kind !== 'generalsAndChoice' || !!dialog.prompt.okOptions?.length) && (skills.selected.includes(c.name!) || skills.selected.length < skills.max)).map(c => c.token) };
    }
    if (dialog.general) {
      const general = dialog.general;
      const state = this.lua.call<{allowed:boolean[];feasible:boolean}>('__web_choose_general_view',
        general.rule, general.selected, general.names, general.extra, general.count);
      return {rows:dialog.prompt.rows,feasible:state.feasible,
        selectedTokens:dialog.prompt.cards.filter(c=>general.selected.includes(c.name!)).map(c=>c.token),
        selectableTokens:dialog.prompt.cards.filter((_,i)=>state.allowed[i]).map(c=>c.token)};
    }
    const tokens = new Map([...dialog.ids].map(([token, id]) => [id, token]));
    const feasible = dialog.prompt.kind !== 'arrange' || this.lua.call<boolean>('__web_arrange_feasible',
      dialog.rows, dialog.original, dialog.limits, dialog.capacities, dialog.poxi);
    return { rows: dialog.rows.map(row => row.map(id => tokens.get(id)!)), feasible };
  }

  selectNativeGeneral(requestId: number, token: string) {
    const { dialog } = this.requireNativeDialog(requestId);
    const card = dialog.prompt.cards.find(c=>c.token===token);
    if (dialog.skills) {
      if (!card?.name || !dialog.skills.names.includes(card.name)) throw new Error('Kỹ năng không hợp lệ');
      if (dialog.skills.selected.includes(card.name)) dialog.skills.selected = dialog.skills.selected.filter(n => n !== card.name);
      else if (this.getNativeDialogView(requestId).selectableTokens?.includes(token)) dialog.skills.selected.push(card.name);
      else throw new Error('Đã chọn đủ số kỹ năng');
      return;
    }
    if (!dialog.general || !card?.name) throw new Error('Tướng không hợp lệ');
    if (dialog.general.selected.includes(card.name)) dialog.general.selected = dialog.general.selected.filter(n=>n!==card.name);
    else if (this.getNativeDialogView(requestId).selectableTokens?.includes(token)) dialog.general.selected.push(card.name);
    else throw new Error('Tướng không được Lua cho phép');
  }

  moveNativeDialogCard(requestId: number, token: string, area: number, index: number) {
    const { dialog } = this.requireNativeDialog(requestId);
    const id = dialog.ids.get(token);
    const rows = movedRows(dialog, token, area, index);
    const fromArea = dialog.rows.findIndex(row => row.includes(id!));
    if (!rows || (fromArea !== area && !this.lua.call<boolean>('__web_arrange_allowed', id,
      dialog.rows, dialog.original, dialog.pattern, dialog.poxi))) throw new Error('Không thể di chuyển lá bài này');
    dialog.rows = rows;
  }

  respondToNativeDialog(requestId: number, token?: string, cancel = false) {
    const { pending, dialog } = this.requireNativeDialog(requestId);
    if (this.authorizedRequest) throw new Error('Đang xử lý câu trả lời');
    if (cancel && !dialog.prompt.cancelable) throw new Error('Không thể bỏ qua yêu cầu này');
    let response: unknown;
    if (dialog.prompt.kind === 'generalsAndChoice') {
      const options = cancel ? dialog.prompt.cancelOptions : dialog.prompt.okOptions;
      if (!token || !options?.includes(token) || (!cancel && !this.getNativeDialogView(requestId).feasible))
        throw new Error('Phương án chọn tướng không hợp lệ');
      response = { cards: cancel ? [] : [...dialog.skills!.selected], choice: token };
    }
    else if (cancel) response = ['ag', 'skills', 'cardNames'].includes(dialog.prompt.kind) ? '' : [];
    else if (dialog.prompt.kind === 'ag' || dialog.prompt.kind === 'boardMove') {
      response = token === undefined ? undefined : dialog.ids.get(token);
      if (response === undefined) throw new Error('Lá bài không hợp lệ');
      if (dialog.boardPositions) response = {cardId:response,pos:dialog.boardPositions.get(response as number)};
    } else if (dialog.prompt.kind === 'generals') response = { cards: [], choice: 'OK' };
    else if (dialog.skills) {
      if (!this.getNativeDialogView(requestId).feasible) throw new Error('Số kỹ năng chưa hợp lệ');
      response = [...dialog.skills.selected];
    }
    else if (dialog.general) {
      if (!this.getNativeDialogView(requestId).feasible) throw new Error('Chọn tướng chưa hợp lệ');
      response = [...dialog.general.selected];
    }
    else {
      if (!this.getNativeDialogView(requestId).feasible) throw new Error('Cách sắp xếp chưa hợp lệ');
      response = dialog.rows.map(row => [...row]);
    }
    this.authorizedRequest = pending;
    try {
      this.expectedReplyHex = this.lua.call<string>('__web_reply_hex', response).toLowerCase();
      this.sendingAuthorizedReply = true;
      try { this.lua.call('__web_reply', response); }
      finally { this.sendingAuthorizedReply = false; }
      if (this.completedAuthorizedReply !== pending) throw new Error('Phản hồi chưa đến máy chủ');
    } catch (error) {
      if (this.pendingRequest === pending) this.clearRequest();
      throw error;
    } finally {
      this.authorizedRequest = null; this.expectedReplyHex = null; this.completedAuthorizedReply = null;
    }
  }

  private handleLuaUi(command: string, data: unknown) {
    if (['AskForArrangeCards', 'AskForAG', 'CustomDialog', 'AskForGeneral', 'AskForMoveCardInBoard'].includes(command)) {
      if (this.receivingRequestCommand === command) this.nativeDialogPayload = { command, data };
      if (command !== 'CustomDialog') return;
    }

    if (command === 'AskForCardChosen' || command === 'AskForPoxi' || command === 'AskForCardsAndChoice') {
      if (this.receivingRequestCommand === command) this.cardSelectionPayload = { command, data };
      return; // Raw card IDs/visibility never reach the React store or onUi.
    }
    if (command === 'AskForSkillInvoke' && this.receivingRequestCommand === command) {
      this.skillInvokePrompt = parseSkillInvokePrompt(data);
      if (!this.skillInvokePrompt) {
        throw new Error('AskForSkillInvoke payload không hợp lệ hoặc thiếu tên kỹ năng');
      }
    }
    if (command === 'ReplyToServer') {
      const pending = this.pendingRequest;
      if (pending?.command === 'AskForSkillInvoke' &&
          this.authorizedRequest === pending && this.capturedReply === null &&
          (data === '1' || data === '__cancel')) {
        this.capturedReply = data;
      } else if (pending && GAMEPLAY_REQUESTS.has(pending.command) &&
          this.authorizedRequest === pending && this.capturedReply === null &&
          (typeof data === 'string' || (data !== null && typeof data === 'object' &&
            jsonWithin(data, 16384)))) {
        this.capturedReply = data;
      } else {
        this.opts.log?.('warn', 'Ignored gameplay reply without a matching user action');
      }
      return;
    }
    if (command === 'CancelRequest' || command === 'StartGame' ||
        command === 'GameOver' || command === 'EnterLobby') this.clearRequest();
    if (command === 'UpdateRequestUI') {
      const current = this.pendingRequest?.command ?? this.receivingRequestCommand;
      if (!current || !GAMEPLAY_REQUESTS.has(current)) return;
      const nextScene = reduceGameplay(this.gameplayScene, data);
      if (nextScene !== this.gameplayScene) {
        this.gameplayScene = nextScene;
        ++this.gameplaySceneRevision;
      }
    }
    if (command === 'CustomDialog') {
      this.initialGeneralPrompt = parseInitialGeneralPrompt(data);
    }
    if (['AskForChoices', 'AskForOptions'].includes(command) && this.receivingRequestCommand === command)
      this.choicePrompt = parseChoicePrompt(command === 'AskForOptions' && Array.isArray(data)
        ? [...data.slice(0, 6), false, data[6] ?? false] : data);
    // The native client can publish the initial private skill snapshot before
    // its later ChangeSelf marker (the marker is also reused at GameOver).
    // Refresh only from Lua's current Self and only when the event owner is
    // that same numeric identity.  Never infer ownership from the first
    // AddSkill event: an observer or a future native projection may receive
    // another player's skill name, and that must remain outside React's
    // private skill state.
    if ((command === 'AddSkill' || command === 'LoseSkill') && Array.isArray(data) &&
        Number.isSafeInteger(data[0]) && (data[0] as number) > 0) {
      try {
        const nativeSelfId = this.lua.eval<unknown>('return Self and Self.id or nil');
        if (nativeSelfId === data[0]) this.opts.onUi('SelfIdentity', nativeSelfId);
      } catch {
        // A skill notification during a partially initialized/reconnecting
        // Lua state must not turn a valid server packet into a dead session.
      }
    }
    // C++ broadcasts AddPlayer before inserting the joining player, so the
    // new socket never receives its own AddPlayer. Lua creates Self during
    // EnterRoom; publish that occupant to the web UI as native QML does.
    if (command === 'EnterRoom' && Array.isArray(data)) {
      const self = this.lua.eval<unknown[]>(`return {
        Self.id, Self.player:getScreenName(), Self.player:getAvatar(), Self.ready or false
      }`);
      const generation = this.socketGeneration;
      this.opts.onUi('SelfIdentity', self[0]);
      if (generation !== this.socketGeneration) return;
      if (!(data[2] as { isObserver?: boolean } | undefined)?.isObserver) {
        this.opts.onUi('AddPlayer', self);
        if (generation !== this.socketGeneration) return;
      }
    }
    this.opts.onUi(command, data);
  }

  /** Boot Lua (once) then open the socket and log in. */
  async start() {
    if (this.stopped) return;
    if (!this.luaReady) {
      this.setStatus({ kind: 'booting' });
      await this.lua.start();
      this.luaReady = true;
    }
    if (this.stopped) {
      this.lua.close();
      return;
    }
    this.connect();
  }

  connect() {
    if (this.stopped) return;
    // Invalidate handlers before closing the previous transport. A late close
    // or data callback from that socket must never alter a new connection.
    const generation = ++this.socketGeneration;
    const previous = this.socket;
    this.socket = null;
    previous?.close();
    this.stream = new PacketStream();
    this.clearRequest();
    this.setStatus({ kind: 'connecting' });
    this.socket = this.opts.openSocket({
      onData: (b) => {
        if (generation === this.socketGeneration) this.onData(b);
      },
      onClose: (reason) => {
        if (generation !== this.socketGeneration) return;
        ++this.socketGeneration;
        this.socket = null;
        this.clearRequest();
        this.setStatus({ kind: 'closed', reason });
      },
    });
  }

  abortTransport(reason: string) { this.disconnect(reason); }

  close() {
    this.stopped = true;
    this.disconnect('closed by client');
  }

  private disconnect(reason: string) {
    ++this.socketGeneration;
    const socket = this.socket;
    this.socket = null;
    try {
      socket?.close();
    } finally {
      this.clearRequest();
      this.setStatus({ kind: 'closed', reason });
    }
  }

  private onData(b: Uint8Array) {
    let packets: Packet[];
    try {
      packets = this.stream.push(b);
    } catch (e) {
      this.opts.log?.('error', `bad stream: ${(e as Error).message}`);
      this.disconnect('invalid packet stream');
      return;
    }
    for (const p of packets) {
      const generation = this.socketGeneration;
      try {
        this.dispatch(p);
      } catch (e) {
        this.opts.log?.('error', `Lua dispatch failed (${p.command}): ${(e as Error).message}`);
        this.disconnect('Lua runtime error');
        break;
      }
      if (generation !== this.socketGeneration) break;
    }
  }

  private dispatch(p: Packet) {
    // Heartbeats are answered here so they keep working while Lua is busy.
    if (p.command === 'Heartbeat') {
      this.rawNotify('Heartbeat', new Uint8Array());
      return;
    }
    if (p.command === 'ErrorDlg' || p.command === 'ErrorMsg') {
      this.opts.log?.('warn', `${p.command}: ${textDecoder.decode(p.data)}`);
    }

    const isRequest = (p.type & PacketType.REQUEST) !== 0;
    const socketGeneration = this.socketGeneration;
    const requestGeneration = isRequest ? ++this.requestGeneration : this.requestGeneration;
    // ClientCallback first emits CancelRequest for the *previous* handler,
    // then opens the new Lua request. Publish the new request only afterward.
    // Otherwise CancelRequest immediately erases the one we just received.
    if (isRequest) {
      this.clearRequest();
      // onRequest(null) is an application callback and may synchronously
      // disconnect or deliver a replacement request.
      if (socketGeneration !== this.socketGeneration ||
          requestGeneration !== this.requestGeneration) return;
    }
    this.receivingRequestCommand = isRequest ? p.command : null;
    const previousLuaGeneration = this.luaDispatchGeneration;
    this.luaDispatchGeneration = socketGeneration;
    try { this.lua.receive(p.command, toHex(p.data), isRequest); }
    finally {
      this.luaDispatchGeneration = previousLuaGeneration;
      this.receivingRequestCommand = null;
    }
    // UI callbacks can synchronously close the connection or dispatch another
    // request. Never republish a request from an invalidated socket/handler.
    if (socketGeneration !== this.socketGeneration ||
        (isRequest && requestGeneration !== this.requestGeneration)) return;
    // EmptyRequest is the native animation delay; no user reply is expected.
    if (isRequest && p.command === 'EmptyRequest') return;
    if (isRequest) {
      const payload = this.cardSelectionPayload;
      if (payload) {
        // The Lua callback has finished; avoid reentering Wasmoon from notifyUI.
        if (payload.command === 'AskForCardsAndChoice')
          this.cardsAndChoice = parseCardsAndChoice(payload.data, (id) => this.lua.call('__web_visible_card', id));
        else this.cardSelection = parseCardSelection(payload.command, payload.data,
          (id) => this.lua.call('__web_visible_card', id));
        this.cardSelectionPayload = null;
      }
      if (p.command === 'AskForCardsAndChoice' && !this.cardsAndChoice) {
        const data = payloadShape(payload?.data);
        this.opts.log?.('warn', `AskForCardsAndChoice prompt rejected (${data})`);
      }
      if (p.command === 'AskForCardsAndChoice' && !this.cardsAndChoice)
        throw new Error('AskForCardsAndChoice không tạo được bộ điều khiển chọn bài');
      if (['AskForCardChosen', 'AskForPoxi'].includes(p.command) && !this.cardSelection)
        throw new Error(`${p.command} không tạo được bộ điều khiển chọn bài`);
      if (p.command === 'AskForSkillInvoke' && !this.skillInvokePrompt)
        throw new Error('AskForSkillInvoke không nhận được dữ liệu hiển thị từ Lua');
      if (['AskForChoices', 'AskForOptions'].includes(p.command) && !this.choicePrompt)
        throw new Error(`${p.command} không tạo được bộ điều khiển lựa chọn`);
      if (this.nativeDialogPayload) {
        const payload = this.nativeDialogPayload;
        this.nativeDialog = parseNativeDialog(payload.command, payload.data,
          (id) => this.lua.call('__web_visible_card', id));
        this.nativeDialogPayload = null;
      }
      const nativeDialogRequired = ['AskForArrangeCards', 'AskForAG', 'AskForGeneral', 'AskForMoveCardInBoard'].includes(p.command) ||
        (p.command === 'CustomDialog' && !this.initialGeneralPrompt);
      if (nativeDialogRequired && !this.nativeDialog)
        throw new Error(`${p.command} không tạo được hộp thoại native`);
      const receivedAt = Date.now();
      const rawTimeout = typeof p.timeout === 'number' && Number.isFinite(p.timeout) ? p.timeout : 0;
      // A malformed peer must not create an effectively immortal timer or an
      // overflowing setTimeout handle. FreeKill request timeouts are seconds;
      // one day is already far beyond any interactive request in the client.
      const timeout = Math.max(0, Math.min(rawTimeout, 86_400));
      const rawTimestamp = typeof p.timestamp === 'number' && Number.isFinite(p.timestamp) && p.timestamp > 0
        ? p.timestamp : receivedAt;
      const startedAt = Math.min(rawTimestamp, receivedAt + 86_400_000);
      this.pendingRequest = {
        requestId: p.requestId, command: p.command, timeout, receivedAt,
        expiresAt: timeout > 0 ? startedAt + timeout * 1000 : null,
        ...(this.nativeDialog ? { nativeDialogPrompt: this.nativeDialog.prompt } : {}),
        ...(p.command === 'AskForCardsAndChoice' ? { cardsAndChoicePrompt: this.cardsAndChoice?.publicPrompt ?? null } : {}),
        ...(['AskForChoices', 'AskForOptions'].includes(p.command) ? { choicePrompt: this.choicePrompt } : {}),
        ...(['AskForCardChosen', 'AskForPoxi'].includes(p.command) ?
          { cardSelectionPrompt: this.cardSelection?.publicPrompt ?? null } : {}),
        ...(p.command === 'AskForSkillInvoke' ? { skillInvokePrompt: this.skillInvokePrompt } : {}),
      };
      this.scheduleRequestExpiry(this.pendingRequest);
      this.opts.onRequest?.(this.pendingRequest);
    }
    // Only report success after upstream Lua has accepted the lobby packet.
    if ((p.command === 'EnterLobby' || p.command === 'Reconnect') && this.status.kind === 'authenticating') {
      this.setStatus({ kind: 'online' });
    }
  }

  private rawNotify(command: string, data: Uint8Array) {
    this.socket?.send(encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command, data }));
  }

  private sendFromLua(kind: 'notify' | 'reply', command: string, hex: string) {
    if (kind === 'reply') {
      const pending = this.pendingRequest;
      // Lua can emit arbitrary callbacks during UpdateRequestUI. Permit the
      // reply only during our explicit __web_reply call, with the exact CBOR
      // representation validated by Lua and an empty command.
      // FreeKill's Lua cbor.encode(string) emits CBOR *byte strings* (major
      // type 2), unlike a JavaScript CBOR encoder's text strings (type 3).
      const expectedHex = this.expectedReplyHex ?? (this.capturedReply === '1' ? '4131' :
        this.capturedReply === '__cancel' ? '485f5f63616e63656c' : null);
      if (!pending || pending !== this.authorizedRequest ||
          !this.sendingAuthorizedReply || command !== '' ||
          !expectedHex || !/^(?:[0-9a-f]{2})+$/i.test(hex) ||
          hex.toLowerCase() !== expectedHex ||
          this.status.kind !== 'online' || !this.socket ||
          (pending.expiresAt !== null && Date.now() >= pending.expiresAt)) {
        this.opts.log?.('warn', 'Dropped unsolicited, expired or mismatched Lua reply');
        return;
      }
      const data = fromHex(hex);
      const requestId = pending.requestId;
      const socket = this.socket;
      const generation = this.socketGeneration;
      const requestGeneration = this.requestGeneration;
      this.clearRequest();
      // Clearing the UI publishes onRequest(null), which may synchronously
      // replace the request or connection. Never send a stale reply afterward.
      if (generation === this.socketGeneration && this.socket === socket &&
          requestGeneration === this.requestGeneration && this.status.kind === 'online') {
        try {
          socket.send(encodePacket({ requestId, type: CLIENT_REPLY, command, data }));
        } catch (error) {
          this.disconnect('reply transport error');
          throw error;
        }
        if (generation === this.socketGeneration && this.socket === socket) {
          this.completedAuthorizedReply = pending;
        }
      }
    } else {
      if (this.luaDispatchGeneration !== null &&
          this.luaDispatchGeneration !== this.socketGeneration) {
        this.opts.log?.('warn', 'Dropped Lua notification from a stale socket callback');
        return;
      }
      this.rawNotify(command, fromHex(hex));
    }
  }

  /** Server sent NetworkDelayTest(pubkey): answer with the Setup packet. */
  private sendSetup(pubkeyPem: string) {
    this.setStatus({ kind: 'authenticating' });
    // The server decrypts into a C string and drops the first 32 bytes (future
    // AES key), so the prefix must not contain NUL bytes.
    const bytes = forge.random.getBytesSync(16);
    const aesPrefix = forge.util.bytesToHex(bytes); // 32 printable chars
    const plain = aesPrefix + forge.util.encodeUtf8(this.opts.password);
    const key = forge.pki.publicKeyFromPem(pubkeyPem) as forge.pki.rsa.PublicKey;
    const encrypted = key.encrypt(plain, 'RSAES-PKCS1-V1_5');
    const encBytes = Uint8Array.from(encrypted, (c) => c.charCodeAt(0));

    const payload = encodeTextArray([
      this.opts.username,
      encBytes,
      this.opts.md5,
      CLIENT_VERSION,
      this.opts.uuid,
    ]);
    this.rawNotify('Setup', payload);
  }
}

/** Return only bounded structural metadata for a rejected native prompt. */
function payloadShape(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return 'not-object';
  const record = value as Record<string, unknown>;
  const list = (key: string, kind: 'card' | 'choice') => {
    const value = record[key];
    if (!Array.isArray(value)) return 'not-array';
    const valid = kind === 'card'
      ? value.every((item) => Number.isSafeInteger(item) && item >= 0 && item <= 2147483647)
      : value.every((item) => typeof item === 'string' && item.length > 0 && item.length <= 1000);
    const unique = new Set(value).size === value.length;
    return `${value.length}/${valid ? 'valid' : 'invalid'}/${unique ? 'unique' : 'duplicate'}`;
  };
  const scalar = (key: string) => {
    const v = record[key];
    if (typeof v === 'number') return Number.isInteger(v) ? String(v) : 'non-integer';
    return typeof v;
  };
  const disabled = record.disabled;
  const cards = record.cards;
  const disabledSubset = Array.isArray(cards) && Array.isArray(disabled) &&
    disabled.every((id) => cards.includes(id));
  return `cards=${list('cards', 'card')},choices=${list('choices', 'choice')},cancel=${list('cancel_choices', 'choice')},disabled=${list('disabled', 'card')},disabledSubset=${disabledSubset},min=${scalar('min')},max=${scalar('max')},filter=${typeof record.filter_skel},extra=${record.extra_data && typeof record.extra_data === 'object' && !Array.isArray(record.extra_data) ? 'object' : typeof record.extra_data},prompt=${typeof record.prompt}`;
}

/** Browser WebSocket transport. */
export function webSocketOpener(url: string) {
  return (h: SocketHandlers): SocketLike => {
    const ws = new WebSocket(url);
    ws.binaryType = 'arraybuffer';
    const pending: Uint8Array[] = [];
    ws.onopen = () => {
      for (const b of pending) ws.send(b);
      pending.length = 0;
    };
    ws.onmessage = (ev) => h.onData(new Uint8Array(ev.data as ArrayBuffer));
    ws.onclose = (ev) => h.onClose(ev.reason || `closed (${ev.code})`);
    ws.onerror = () => {
      /* onclose follows */
    };
    return {
      send: (b) => {
        if (ws.readyState === WebSocket.OPEN) ws.send(b);
        else if (ws.readyState === WebSocket.CONNECTING) pending.push(b);
      },
      close: () => ws.close(),
    };
  };
}
