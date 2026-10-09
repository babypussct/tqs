// SPDX-License-Identifier: GPL-3.0-or-later
//
// GameConnection = socket transport + packet framing + login handshake +
// the Lua client runtime. UI code only sees `onUi(command, data)` events
// (the same events the original QML received) and calls back into Lua via
// `lua.call(...)` / `lua.eval(...)`.

import forge from 'node-forge';
import { LuaRuntime } from './luaRuntime';
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
  command: string;
  timeout: number;
  receivedAt: number;
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
  private lastRequestId = 0;
  private status: ConnectionStatus = { kind: 'booting' };
  private luaReady = false;
  private queue: Packet[] = [];

  constructor(private opts: GameConnectionOptions) {
    this.lua = new LuaRuntime({
      files: opts.files,
      language: opts.language,
      wasmUrl: opts.wasmUrl,
      callbacks: {
        send: (kind, command, hex) => this.sendFromLua(kind, command, hex),
        ui: (command, data) => this.opts.onUi(command, data),
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

  /** Boot Lua (once) then open the socket and log in. */
  async start() {
    if (!this.luaReady) {
      this.setStatus({ kind: 'booting' });
      await this.lua.start();
      this.luaReady = true;
    }
    this.connect();
  }

  connect() {
    this.stream = new PacketStream();
    this.setStatus({ kind: 'connecting' });
    this.socket = this.opts.openSocket({
      onData: (b) => this.onData(b),
      onClose: (reason) => {
        this.socket = null;
        this.setStatus({ kind: 'closed', reason });
      },
    });
  }

  close() {
    this.socket?.close();
    this.socket = null;
  }

  private onData(b: Uint8Array) {
    let packets: Packet[];
    try {
      packets = this.stream.push(b);
    } catch (e) {
      this.opts.log?.('error', `bad stream: ${(e as Error).message}`);
      this.close();
      return;
    }
    for (const p of packets) this.dispatch(p);
  }

  private dispatch(p: Packet) {
    // Heartbeats are answered here so they keep working while Lua is busy.
    if (p.command === 'Heartbeat') {
      this.rawNotify('Heartbeat', new Uint8Array());
      return;
    }
    if (p.command === 'Setup' && this.status.kind === 'authenticating') {
      this.setStatus({ kind: 'online' });
    }
    if (p.command === 'ErrorDlg' || p.command === 'ErrorMsg') {
      this.opts.log?.('warn', `${p.command}: ${textDecoder.decode(p.data)}`);
    }

    const isRequest = (p.type & PacketType.REQUEST) !== 0;
    if (isRequest) {
      this.lastRequestId = p.requestId;
      this.opts.onRequest?.({ command: p.command, timeout: p.timeout ?? 0, receivedAt: Date.now() });
    }
    this.lua.receive(p.command, toHex(p.data), isRequest);
  }

  private rawNotify(command: string, data: Uint8Array) {
    this.socket?.send(encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command, data }));
  }

  private sendFromLua(kind: 'notify' | 'reply', command: string, hex: string) {
    const data = fromHex(hex);
    if (kind === 'reply') {
      this.opts.onRequest?.(null);
      this.socket?.send(
        encodePacket({ requestId: this.lastRequestId, type: CLIENT_REPLY, command, data }),
      );
    } else {
      this.rawNotify(command, data);
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
