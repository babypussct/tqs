import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  CLIENT_REPLY,
  CLIENT_NOTIFY,
  RawPacketStream,
  encodePacket,
  type Packet,
} from '../src/engine/packet';

function join(...chunks: Uint8Array[]): Uint8Array {
  const result = new Uint8Array(chunks.reduce((size, chunk) => size + chunk.length, 0));
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

function packet(command: string, data: Uint8Array, requestId = -2): Uint8Array {
  const value: Packet = { requestId, type: CLIENT_NOTIFY, command, data };
  return encodePacket(value);
}

test('raw packet stream preserves complete outer CBOR bytes across fragmentation', () => {
  const bytes = packet('MoveCards', Uint8Array.from([0x81, 0x80]));
  const stream = new RawPacketStream();
  assert.deepEqual(stream.push(bytes.subarray(0, 3)), []);
  const result = stream.push(bytes.subarray(3));
  assert.equal(result.length, 1);
  assert.equal(result[0].requestId, -2);
  assert.equal(result[0].type, CLIENT_NOTIFY);
  assert.equal(result[0].command, 'MoveCards');
  assert.deepEqual(result[0].bytes, bytes);
});

test('raw packet stream separates multiple packets before normal data decoding', () => {
  const first = packet('PrepareDrawPile', Uint8Array.from([0xa1, 0x65, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x01]));
  const second = packet('GameOver', Uint8Array.from([0x80]), 7);
  const result = new RawPacketStream().push(join(first, second));
  assert.deepEqual(result.map(({ command }) => command), ['PrepareDrawPile', 'GameOver']);
  assert.deepEqual(result.map(({ requestId }) => requestId), [-2, 7]);
  assert.deepEqual(result.map(({ type }) => type), [CLIENT_NOTIFY, CLIENT_NOTIFY]);
  assert.deepEqual(result.map(({ bytes }) => bytes), [first, second]);
});

test('raw packet stream accepts empty command only on replies', () => {
  const reply = encodePacket({ requestId: 8, type: CLIENT_REPLY, command: '', data: Uint8Array.of(0x80) });
  const result = new RawPacketStream().push(reply);
  assert.equal(result.length, 1);
  assert.equal(result[0].requestId, 8);
  assert.equal(result[0].type, CLIENT_REPLY);
  assert.equal(result[0].command, '');
  assert.throws(() => new RawPacketStream().push(
    encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command: '', data: Uint8Array.of(0x80) })),
  /raw packet command exceeds size limit/u);
});

test('raw packet stream rejects malformed outer packet instead of guessing a boundary', () => {
  assert.throws(() => new RawPacketStream().push(Uint8Array.from([0x81, 0x00])),
    /four\/six-element CBOR array/u);
});
