// SPDX-License-Identifier: GPL-3.0-or-later
//
// GameConnection = socket transport + packet framing + login handshake +
// the Lua client runtime. UI code only sees `onUi(command, data)` events
// (the same events the original QML received) and calls back into Lua via
// `lua.call(...)` / `lua.eval(...)`.

import forge from 'node-forge';
import { LuaRuntime } from './luaRuntime';
import { parseInitialGeneralPrompt, type InitialGeneralPrompt } from './generalSelection';
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

export class GameConnection {
  readonly lua: LuaRuntime;
  private socket: SocketLike | null = null;
  private stream = new PacketStream();
  private pendingRequest: RequestInfo | null = null;
  private authorizedRequest: RequestInfo | null = null;
  private capturedReply: '1' | '__cancel' | null = null;
  private initialGeneralPrompt: InitialGeneralPrompt | null = null;
  private expectedReplyHex: string | null = null;
  private completedAuthorizedReply: RequestInfo | null = null;
  private sendingAuthorizedReply = false;
  private status: ConnectionStatus = { kind: 'booting' };
  private luaReady = false;
  private socketGeneration = 0;
  private requestGeneration = 0;
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

  private clearRequest() {
    this.pendingRequest = null;
    this.authorizedRequest = null;
    this.capturedReply = null;
    this.initialGeneralPrompt = null;
    this.expectedReplyHex = null;
    this.completedAuthorizedReply = null;
    this.sendingAuthorizedReply = false;
    this.opts.onRequest?.(null);
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

  private handleLuaUi(command: string, data: unknown) {
    if (command === 'ReplyToServer') {
      const pending = this.pendingRequest;
      if (pending?.command === 'AskForSkillInvoke' &&
          this.authorizedRequest === pending && this.capturedReply === null &&
          (data === '1' || data === '__cancel')) {
        this.capturedReply = data;
      } else {
        this.opts.log?.('warn', 'Ignored gameplay reply without a matching user action');
      }
      return;
    }
    if (command === 'CancelRequest' || command === 'StartGame' ||
        command === 'GameOver' || command === 'EnterLobby') this.clearRequest();
    if (command === 'CustomDialog') {
      this.initialGeneralPrompt = parseInitialGeneralPrompt(data);
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
    this.lua.receive(p.command, toHex(p.data), isRequest);
    // UI callbacks can synchronously close the connection or dispatch another
    // request. Never republish a request from an invalidated socket/handler.
    if (socketGeneration !== this.socketGeneration ||
        (isRequest && requestGeneration !== this.requestGeneration)) return;
    if (isRequest) {
      const receivedAt = Date.now();
      const timeout = p.timeout ?? 0;
      const startedAt = p.timestamp && p.timestamp > 0 ? p.timestamp : receivedAt;
      this.pendingRequest = {
        requestId: p.requestId, command: p.command, timeout, receivedAt,
        expiresAt: timeout > 0 ? startedAt + timeout * 1000 : null,
      };
      this.opts.onRequest?.(this.pendingRequest);
    }
    // Only report success after upstream Lua has accepted the lobby packet.
    if (p.command === 'EnterLobby' && this.status.kind === 'authenticating') {
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
      // representation of the user's selected button and an empty command.
      // FreeKill's Lua cbor.encode(string) emits CBOR *byte strings* (major
      // type 2), unlike a JavaScript CBOR encoder's text strings (type 3).
      const expectedHex = this.expectedReplyHex ?? (this.capturedReply === '1' ? '4131' :
        this.capturedReply === '__cancel' ? '485f5f63616e63656c' : null);
      if (!pending || pending !== this.authorizedRequest ||
          !this.sendingAuthorizedReply || command !== '' ||
          !expectedHex || hex.toLowerCase() !== expectedHex ||
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
