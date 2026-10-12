// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wire format of freekill-asio (see freekill-asio/src/network/*.cpp):
//
//   notification: [ -2,        type, bytes command, bytes data ]
//   request:      [ requestId, type, bytes command, bytes data, timeout, timestamp ]
//   reply:        [ requestId, type, bytes command, bytes data ]
//
// Packets are CBOR arrays written back-to-back on the stream with no extra
// framing. `data` is itself a CBOR document (or a plain string for a few
// commands) and is passed to the Lua client untouched. When `type & 0x1000`
// the data is Qt-compressed: 4-byte big-endian length followed by zlib.

import { unzlibSync } from 'fflate';

export const PacketType = {
  COMPRESSED: 0x1000,
  REQUEST: 0x100,
  REPLY: 0x200,
  NOTIFICATION: 0x400,
  SRC_CLIENT: 0x010,
  SRC_SERVER: 0x020,
  SRC_LOBBY: 0x040,
  DEST_CLIENT: 0x001,
  DEST_SERVER: 0x002,
  DEST_LOBBY: 0x004,
} as const;

export const CLIENT_NOTIFY = PacketType.NOTIFICATION | PacketType.SRC_CLIENT | PacketType.DEST_SERVER;
export const CLIENT_REPLY = PacketType.REPLY | PacketType.SRC_CLIENT | PacketType.DEST_SERVER;

export interface Packet {
  requestId: number;
  type: number;
  command: string;
  data: Uint8Array;
  timeout?: number;
  timestamp?: number;
}

const enc = new TextEncoder();
const dec = new TextDecoder();
const MAX_PACKET_BYTES = 4 * 1024 * 1024;
const MAX_DECOMPRESSED_BYTES = 8 * 1024 * 1024;
const MAX_COMMAND_BYTES = 256;

// ------------------------------------------------------------ encoding --

class Writer {
  private buf = new Uint8Array(256);
  private len = 0;

  private ensure(n: number) {
    if (this.len + n <= this.buf.length) return;
    let cap = this.buf.length * 2;
    while (cap < this.len + n) cap *= 2;
    const nb = new Uint8Array(cap);
    nb.set(this.buf.subarray(0, this.len));
    this.buf = nb;
  }

  head(major: number, value: number | bigint) {
    const v = typeof value === 'bigint' ? value : BigInt(value);
    const m = major << 5;
    if (v < 24n) {
      this.ensure(1);
      this.buf[this.len++] = m | Number(v);
    } else if (v < 0x100n) {
      this.ensure(2);
      this.buf[this.len++] = m | 24;
      this.buf[this.len++] = Number(v);
    } else if (v < 0x10000n) {
      this.ensure(3);
      this.buf[this.len++] = m | 25;
      this.buf[this.len++] = Number(v >> 8n) & 0xff;
      this.buf[this.len++] = Number(v) & 0xff;
    } else if (v < 0x100000000n) {
      this.ensure(5);
      this.buf[this.len++] = m | 26;
      for (let s = 24n; s >= 0n; s -= 8n) this.buf[this.len++] = Number((v >> s) & 0xffn);
    } else {
      this.ensure(9);
      this.buf[this.len++] = m | 27;
      for (let s = 56n; s >= 0n; s -= 8n) this.buf[this.len++] = Number((v >> s) & 0xffn);
    }
  }

  int(n: number) {
    if (n >= 0) this.head(0, n);
    else this.head(1, BigInt(-1 - n));
  }

  bytes(b: Uint8Array, major = 2) {
    this.head(major, b.length);
    this.ensure(b.length);
    this.buf.set(b, this.len);
    this.len += b.length;
  }

  /** CBOR text string. `raw` lets callers put non-UTF-8 bytes in a text item. */
  text(s: string | Uint8Array) {
    this.bytes(typeof s === 'string' ? enc.encode(s) : s, 3);
  }

  result() {
    return this.buf.slice(0, this.len);
  }
}

export function encodePacket(p: Packet): Uint8Array {
  const w = new Writer();
  const hasExtra = p.timeout !== undefined;
  w.head(4, hasExtra ? 6 : 4);
  w.int(p.requestId);
  w.int(p.type);
  w.bytes(enc.encode(p.command));
  w.bytes(p.data);
  if (hasExtra) {
    w.int(p.timeout ?? 0);
    w.int(p.timestamp ?? Date.now());
  }
  return w.result();
}

/** CBOR login fields: strings are text, RSA ciphertext is a byte string. */
export function encodeTextArray(items: (string | Uint8Array)[]): Uint8Array {
  const w = new Writer();
  w.head(4, items.length);
  for (const it of items) {
    if (typeof it === 'string') w.text(it);
    else w.bytes(it);
  }
  return w.result();
}

// ------------------------------------------------------------ decoding --

class NeedMore extends Error {}

class Reader {
  pos = 0;
  constructor(private b: Uint8Array) {}

  private need(n: number) {
    if (this.pos + n > this.b.length) throw new NeedMore();
  }

  head(): { major: number; value: number } {
    this.need(1);
    const ib = this.b[this.pos++];
    const major = ib >> 5;
    const ai = ib & 31;
    if (ai < 24) return { major, value: ai };
    const n = ai === 24 ? 1 : ai === 25 ? 2 : ai === 26 ? 4 : ai === 27 ? 8 : -1;
    if (n < 0) throw new Error(`unsupported CBOR additional info ${ai}`);
    this.need(n);
    let v = 0n;
    for (let i = 0; i < n; i++) v = v * 256n + BigInt(this.b[this.pos++]);
    if (v > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('CBOR integer exceeds JS safe range');
    return { major, value: Number(v) };
  }

  int(): number {
    const { major, value } = this.head();
    if (major === 0) return value;
    if (major === 1) return -1 - value;
    throw new Error(`expected int, got major ${major}`);
  }

  bytes(): Uint8Array {
    const { major, value } = this.head();
    if (major !== 2 && major !== 3) throw new Error(`expected bytes, got major ${major}`);
    if (value > MAX_PACKET_BYTES) throw new Error('CBOR byte string too large');
    this.need(value);
    const out = this.b.subarray(this.pos, this.pos + value);
    this.pos += value;
    return out;
  }
}

function qUncompress(data: Uint8Array): Uint8Array {
  if (data.length < 4) throw new Error('truncated compressed packet');
  const expected = new DataView(data.buffer, data.byteOffset, 4).getUint32(0);
  if (expected > MAX_DECOMPRESSED_BYTES) throw new Error('decompressed packet too large');
  const result = unzlibSync(data.subarray(4), { out: new Uint8Array(expected) });
  if (result.length !== expected) throw new Error('compressed packet length mismatch');
  return result;
}

/** Incremental decoder for the TCP/WebSocket byte stream. */
export class PacketStream {
  private pending = new Uint8Array(0);

  push(chunk: Uint8Array): Packet[] {
    if (chunk.length + this.pending.length > MAX_PACKET_BYTES) {
      throw new Error('CBOR stream exceeds size limit');
    }
    if (this.pending.length === 0) {
      this.pending = chunk;
    } else {
      const merged = new Uint8Array(this.pending.length + chunk.length);
      merged.set(this.pending);
      merged.set(chunk, this.pending.length);
      this.pending = merged;
    }

    const out: Packet[] = [];
    let consumed = 0;
    for (;;) {
      const r = new Reader(this.pending.subarray(consumed));
      try {
        const { major, value: len } = r.head();
        if (major !== 4 || (len !== 4 && len !== 6)) throw new Error('malformed packet header');
        const requestId = r.int();
        let type = r.int();
        const commandBytes = r.bytes();
        // freekill-asio replies intentionally carry an empty command; inbound
        // requests and notifications must name the Lua callback they target.
        if ((commandBytes.length === 0 && (type & PacketType.REPLY) === 0)
          || commandBytes.length > MAX_COMMAND_BYTES)
          throw new Error('packet command exceeds size limit');
        const command = dec.decode(commandBytes);
        let data = r.bytes().slice();
        let timeout: number | undefined;
        let timestamp: number | undefined;
        if (len === 6) {
          timeout = r.int();
          timestamp = r.int();
        }
        if (type & PacketType.COMPRESSED) {
          data = qUncompress(data);
          type &= ~PacketType.COMPRESSED;
        }
        out.push({ requestId, type, command, data, timeout, timestamp });
        consumed += r.pos;
      } catch (e) {
        if (e instanceof NeedMore) break;
        throw e;
      }
    }
    this.pending = this.pending.slice(consumed);
    return out;
  }
}

// ----------------------------------------------------------- helpers --

export function toHex(b: Uint8Array): string {
  let s = '';
  for (let i = 0; i < b.length; i++) s += b[i].toString(16).padStart(2, '0');
  return s;
}

export function fromHex(h: string): Uint8Array {
  const out = new Uint8Array(h.length >> 1);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(h.substr(i * 2, 2), 16);
  return out;
}
