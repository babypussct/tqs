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

/** A packet boundary captured before the normal data decoder runs. */
export interface RawWirePacket {
  requestId: number;
  type: number;
  command: string;
  bytes: Uint8Array;
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

// ------------------------------------------------------- raw boundary audit --

class RawNeedMore extends Error {}

type RawHead = { major: number; value: number; next: number };

function rawHead(bytes: Uint8Array, start: number): RawHead {
  if (start >= bytes.length) throw new RawNeedMore();
  const initial = bytes[start];
  const major = initial >> 5;
  const additional = initial & 31;
  if (additional < 24) return { major, value: additional, next: start + 1 };
  const width = additional === 24 ? 1 : additional === 25 ? 2 :
    additional === 26 ? 4 : additional === 27 ? 8 : 0;
  if (width === 0) throw new Error('unsupported raw CBOR additional info');
  if (start + 1 + width > bytes.length) throw new RawNeedMore();
  let value = 0;
  for (let index = 0; index < width; index++) {
    value = value * 256 + bytes[start + 1 + index];
    if (!Number.isSafeInteger(value)) throw new Error('raw CBOR integer exceeds JS safe range');
  }
  return { major, value, next: start + 1 + width };
}

function rawInteger(bytes: Uint8Array, start: number): number {
  const head = rawHead(bytes, start);
  if (head.major === 0) return head.value;
  if (head.major === 1) return -1 - head.value;
  throw new Error('raw packet field is not an integer');
}

function rawBytes(bytes: Uint8Array, start: number): { value: Uint8Array; next: number } {
  const head = rawHead(bytes, start);
  if (head.major !== 2 && head.major !== 3) throw new Error('raw packet field is not a byte/text string');
  if (head.value > MAX_PACKET_BYTES) throw new Error('raw packet byte string exceeds size limit');
  const end = head.next + head.value;
  if (end > bytes.length) throw new RawNeedMore();
  return { value: bytes.subarray(head.next, end), next: end };
}

function readRawWirePacket(bytes: Uint8Array): {
  requestId: number; type: number; command: string; end: number;
} {
  const array = rawHead(bytes, 0);
  if (array.major !== 4 || (array.value !== 4 && array.value !== 6)) {
    throw new Error('raw packet header is not a four/six-element CBOR array');
  }
  let cursor = array.next;
  const requestIdHead = rawHead(bytes, cursor);
  if (requestIdHead.major !== 0 && requestIdHead.major !== 1) {
    throw new Error('raw packet request id is not an integer');
  }
  cursor = requestIdHead.next;
  const requestId = requestIdHead.major === 0 ? requestIdHead.value : -1 - requestIdHead.value;
  const typeHead = rawHead(bytes, cursor);
  if (typeHead.major !== 0 && typeHead.major !== 1) {
    throw new Error('raw packet type is not an integer');
  }
  const type = typeHead.major === 0 ? typeHead.value : -1 - typeHead.value;
  cursor = typeHead.next;
  const command = rawBytes(bytes, cursor);
  cursor = command.next;
  if ((command.value.length === 0 && (type & PacketType.REPLY) === 0) ||
      command.value.length > MAX_COMMAND_BYTES) {
    throw new Error('raw packet command exceeds size limit');
  }
  const data = rawBytes(bytes, cursor);
  cursor = data.next;
  if (array.value === 6) {
    rawInteger(bytes, cursor); cursor = rawHead(bytes, cursor).next;
    rawInteger(bytes, cursor); cursor = rawHead(bytes, cursor).next;
  }
  return { requestId, type, command: dec.decode(command.value), end: cursor };
}

/**
 * Incrementally extracts complete outer CBOR packets without decoding their
 * data field. QA can hand the returned bytes to an independent native/Lua
 * auditor before PacketStream or the browser Lua client sees the payload.
 */
export class RawPacketStream {
  private pending = new Uint8Array(0);

  push(chunk: Uint8Array): RawWirePacket[] {
    if (chunk.length + this.pending.length > MAX_PACKET_BYTES) {
      throw new Error('raw CBOR stream exceeds size limit');
    }
    if (this.pending.length === 0) {
      this.pending = chunk;
    } else {
      const merged = new Uint8Array(this.pending.length + chunk.length);
      merged.set(this.pending);
      merged.set(chunk, this.pending.length);
      this.pending = merged;
    }

    const out: RawWirePacket[] = [];
    let consumed = 0;
    for (;;) {
      try {
        const parsed = readRawWirePacket(this.pending.subarray(consumed));
        out.push({
          requestId: parsed.requestId,
          type: parsed.type,
          command: parsed.command,
          bytes: this.pending.subarray(consumed, consumed + parsed.end).slice(),
        });
        consumed += parsed.end;
      } catch (error) {
        if (error instanceof RawNeedMore) break;
        throw error;
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
