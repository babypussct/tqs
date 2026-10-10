import assert from 'node:assert/strict';
import { test } from 'node:test';
import { zlibSync } from 'fflate';
import { CLIENT_NOTIFY, PacketStream, PacketType, encodePacket, encodeTextArray } from '../src/engine/packet';

test('Setup uses CBOR text for account and CBOR bytes for RSA ciphertext', () => {
  // Canonical CBOR: ["u", h'00ff01', "v"]. The second element must be major type 2.
  assert.deepEqual(Array.from(encodeTextArray(['u', Uint8Array.of(0, 255, 1), 'v'])),
    [0x83, 0x61, 0x75, 0x43, 0, 255, 1, 0x61, 0x76]);
});

test('CBOR stream handles split packets and back-to-back replies', () => {
  const p = { requestId: -2, type: CLIENT_NOTIFY, command: 'Heartbeat', data: Uint8Array.of(1, 2) };
  const encoded = encodePacket(p);
  const decoded = { ...p, timeout: undefined, timestamp: undefined };
  const stream = new PacketStream();
  assert.deepEqual(stream.push(encoded.subarray(0, 2)), []);
  assert.deepEqual(stream.push(encoded.subarray(2)), [decoded]);
  const combined = new Uint8Array(encoded.length * 2);
  combined.set(encoded);
  combined.set(encoded, encoded.length);
  assert.deepEqual(new PacketStream().push(combined), [decoded, decoded]);
});

test('compressed packet honors Qt big-endian output length', () => {
  const raw = Uint8Array.of(5, 6, 7);
  const zipped = zlibSync(raw);
  const data = new Uint8Array(4 + zipped.length);
  new DataView(data.buffer).setUint32(0, raw.length);
  data.set(zipped, 4);
  const wire = encodePacket({ requestId: -2, type: CLIENT_NOTIFY | PacketType.COMPRESSED, command: 'X', data });
  assert.deepEqual(new PacketStream().push(wire)[0]?.data, raw);
});

test('rejects CBOR integers unsafe for JavaScript and oversized inflate headers', () => {
  assert.throws(() => new PacketStream().push(Uint8Array.from([0x84, 0x1b, 0x00, 0x20, 0, 0, 0, 0, 0, 0])), /safe range/);
  const data = Uint8Array.of(0x01, 0x00, 0x00, 0x00, 0x78, 0x9c);
  const wire = encodePacket({ requestId: -2, type: CLIENT_NOTIFY | PacketType.COMPRESSED, command: 'X', data });
  assert.throws(() => new PacketStream().push(wire), /decompressed packet too large/);
});
