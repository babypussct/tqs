import assert from 'node:assert/strict';
import { test } from 'node:test';
import { GameConnection, type SocketHandlers, type RequestInfo } from '../src/engine/connection';
import { CLIENT_NOTIFY, CLIENT_REPLY, PacketStream, PacketType, encodePacket, type Packet } from '../src/engine/packet';

const SERVER_NOTIFY = PacketType.NOTIFICATION | PacketType.SRC_SERVER | PacketType.DEST_CLIENT;
const SERVER_REQUEST = PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT;

function harness() {
  const sockets: { handlers: SocketHandlers; closed: boolean; sent: Uint8Array[] }[] = [];
  const statuses: string[] = [];
  const requests: (string | null)[] = [];
  const received: string[] = [];
  const conn = new GameConnection({
    files: new Map(), username: 'test', password: 'local-only', md5: 'local-md5', uuid: 'local-uuid',
    openSocket: (handlers) => {
      const socket = { handlers, closed: false, sent: [] as Uint8Array[] };
      sockets.push(socket);
      return {
        send: (bytes) => socket.sent.push(bytes),
        close: () => { socket.closed = true; },
      };
    },
    onUi: () => {},
    onStatus: (status) => statuses.push(status.kind),
    onRequest: (request) => requests.push(request?.command ?? null),
  });
  // Transport unit tests replace only the Lua receiver; the full Wasmoon
  // handshake and Lua callback are exercised by smoke.ts.
  conn.lua.receive = (command) => { received.push(command); };
  const packet = (command: string, type = SERVER_NOTIFY, requestId = -2): Packet => ({
    requestId, type, command, data: new Uint8Array(),
  });
  return { conn, sockets, statuses, requests, received, packet };
}

test('EnterLobby is online only after Lua accepts the packet', () => {
  const h = harness();
  h.conn.connect();
  h.conn.lua.receive = (command) => {
    if (command === 'EnterLobby') {
      assert.equal(h.conn.getStatus().kind, 'authenticating');
      throw new Error('broken Lua callback');
    }
  };
  // Simulate Setup handler advancing the authentication state through its
  // host callback, without creating an account or contacting a server.
  h.conn['setStatus']({ kind: 'authenticating' });
  h.sockets[0].handlers.onData(encodePacket(h.packet('EnterLobby')));
  assert.deepEqual(h.statuses, ['connecting', 'authenticating', 'closed']);
  assert.deepEqual(h.conn.getStatus(), { kind: 'closed', reason: 'Lua runtime error' });
  assert.equal(h.sockets[0].closed, true);
});

test('successful Lua EnterLobby transitions to online after callback', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'authenticating' });
  h.conn.lua.receive = (command) => {
    assert.equal(command, 'EnterLobby');
    assert.equal(h.conn.getStatus().kind, 'authenticating');
  };
  h.sockets[0].handlers.onData(encodePacket(h.packet('EnterLobby')));
  assert.equal(h.conn.getStatus().kind, 'online');
});

test('heartbeat replies immediately without Lua dispatch or altering a pending request', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 1001);
  h.conn.lua.receive = () => { throw new Error('Heartbeat must not enter Lua'); };
  for (let i = 0; i < 8; i++) h.sockets[0].handlers.onData(encodePacket(h.packet('Heartbeat')));
  assert.equal(h.conn['pendingRequest']?.requestId, 1001);
  assert.equal(h.sockets[0].sent.length, 8);
  for (const bytes of h.sockets[0].sent) {
    const [packet] = new PacketStream().push(bytes);
    assert.equal(packet.command, 'Heartbeat');
    assert.equal(packet.type, CLIENT_NOTIFY);
    assert.equal(packet.requestId, -2);
  }
  h.conn.close();
  h.sockets[0].handlers.onData(encodePacket(h.packet('Heartbeat')));
  assert.equal(h.sockets[0].sent.length, 8);
});

test('malformed EnterLobby payload closes session without reporting online', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'authenticating' });
  h.conn.lua.receive = (_, hex) => {
    if (hex !== 'f6') throw new Error('CBOR input too short');
  };
  h.sockets[0].handlers.onData(encodePacket(h.packet('EnterLobby')));
  assert.deepEqual(h.statuses, ['connecting', 'authenticating', 'closed']);
  assert.equal(h.conn.getStatus().kind, 'closed');
  assert.equal(h.sockets[0].closed, true);
});

test('reconnecting isolates delayed close/data from the previous socket', () => {
  const h = harness();
  h.conn.connect();
  const old = h.sockets[0];
  h.conn.connect();
  assert.equal(old.closed, true);
  old.handlers.onClose('late close');
  old.handlers.onData(encodePacket(h.packet('OldEvent')));
  assert.deepEqual(h.received, []);
  assert.equal(h.conn.getStatus().kind, 'connecting');
  h.sockets[1].handlers.onData(encodePacket(h.packet('NewEvent')));
  assert.deepEqual(h.received, ['NewEvent']);
  h.sockets[1].handlers.onClose('server disconnected');
  assert.deepEqual(h.conn.getStatus(), { kind: 'closed', reason: 'server disconnected' });
  h.conn.connect();
  h.sockets[1].handlers.onClose('late close again');
  assert.equal(h.conn.getStatus().kind, 'connecting');
});

test('a stale Lua notification cannot cross a reentrant reconnect into the new socket', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  h.conn['opts'].onUi = (command: string) => {
    if (command !== 'Reenter') return;
    h.conn.connect();
    // Keep the assertion about generation isolation independent from the
    // normal connecting/online status transition.
    h.conn['setStatus']({ kind: 'online' });
  };
  h.conn.lua.receive = (command) => {
    if (command !== 'OldEvent') return;
    h.conn['handleLuaUi']('Reenter', null);
    h.conn['sendFromLua']('notify', 'StaleNotify', '00');
  };

  const old = h.sockets[0];
  old.handlers.onData(encodePacket(h.packet('OldEvent')));
  assert.equal(old.closed, true);
  assert.equal(h.sockets.length, 2);
  assert.equal(h.sockets[1].sent.length, 0);
  assert.equal(h.conn.getStatus().kind, 'online');
});

test('explicit close invalidates handlers and clears request state', () => {
  const h = harness();
  h.conn.connect();
  h.sockets[0].handlers.onData(encodePacket({
    ...h.packet('ChooseGeneral', SERVER_REQUEST, 42), timeout: 4000, timestamp: 0,
  }));
  assert.equal(h.requests.at(-1), 'ChooseGeneral');
  h.conn.close();
  assert.equal(h.conn.getStatus().kind, 'closed');
  assert.equal(h.requests.at(-1), null);
  h.sockets[0].handlers.onData(encodePacket(h.packet('StalePacket')));
  assert.deepEqual(h.received, ['ChooseGeneral']);
});

test('truncated and malformed packets do not produce successful dispatch', () => {
  const h = harness();
  h.conn.connect();
  const wire = encodePacket(h.packet('ValidPacket'));
  h.sockets[0].handlers.onData(wire.subarray(0, 2));
  assert.deepEqual(h.received, []);
  h.sockets[0].handlers.onData(wire.subarray(2));
  assert.deepEqual(h.received, ['ValidPacket']);
  h.sockets[0].handlers.onData(Uint8Array.of(0x01)); // CBOR int, not a packet array
  assert.deepEqual(h.conn.getStatus(), { kind: 'closed', reason: 'invalid packet stream' });
  assert.equal(h.sockets[0].closed, true);
});

function prepareSkillRequest(h: ReturnType<typeof harness>, id: number, timestamp = Date.now(), timeout = 30) {
  h.conn.lua.receive = (command) => {
    if (command !== 'AskForSkillInvoke') return;
    // This is the synchronous event ordering of the real upstream ClientCallback.
    h.conn['handleLuaUi']('CancelRequest', null);
    h.conn['handleLuaUi']('AskForSkillInvoke', ['test_skill', 'Kích hoạt?']);
  };
  h.sockets.at(-1)!.handlers.onData(encodePacket({
    ...h.packet('AskForSkillInvoke', SERVER_REQUEST, id), timeout, timestamp,
  }));
}

test('CancelRequest emitted by Lua cannot erase a newly arrived request', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 101);
  assert.equal(h.requests.at(-1), 'AskForSkillInvoke');
  assert.equal(h.sockets[0].sent.length, 0, 'no reply before player choice');

  h.conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      h.conn['handleLuaUi']('ReplyToServer', args[1] === 'OK' ? '1' : '__cancel');
    } else if (name === '__web_reply') {
      // Test transport state with the CBOR bytes from the actual Lua bridge.
      h.conn['sendFromLua']('reply', '', args[0] === '1' ? '4131' : '485f5f63616e63656c');
    }
    return true as T;
  };
  h.conn['handleLuaUi']('ReplyToServer', '1');
  assert.equal(h.sockets[0].sent.length, 0, 'unauthorized Lua callback is dropped');
  h.conn.respondToSkillInvoke(101, 'Cancel');
  assert.equal(h.requests.at(-1), null);
  assert.equal(h.sockets[0].sent.length, 1);
  const packet = new PacketStream().push(h.sockets[0].sent[0])[0];
  assert.equal(packet.requestId, 101);
  assert.equal(packet.command, '');
  assert.equal(packet.type, CLIENT_REPLY);
  assert.deepEqual([...packet.data], [...Uint8Array.of(0x48, ...new TextEncoder().encode('__cancel'))]);
  assert.throws(() => h.conn.respondToSkillInvoke(101, 'OK'), /không còn hiệu lực/);
  assert.equal(h.sockets[0].sent.length, 1, 'duplicate button click does not reply');
});

test('replaced, canceled, expired, and disconnected requests cannot send replies', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 201);
  prepareSkillRequest(h, 202);
  assert.throws(() => h.conn.respondToSkillInvoke(201, 'OK'), /không còn hiệu lực/);
  h.conn['handleLuaUi']('CancelRequest', null);
  assert.throws(() => h.conn.respondToSkillInvoke(202, 'OK'), /không còn hiệu lực/);
  prepareSkillRequest(h, 203, Date.now() - 5000, 1);
  assert.throws(() => h.conn.respondToSkillInvoke(203, 'OK'), /hết thời gian/);
  prepareSkillRequest(h, 204);
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  assert.throws(() => h.conn.respondToSkillInvoke(204, 'OK'), /không còn hiệu lực/);
  prepareSkillRequest(h, 205);
  h.conn.close();
  assert.throws(() => h.conn.respondToSkillInvoke(205, 'OK'), /không còn hiệu lực/);
  assert.equal(h.sockets.flatMap((socket) => socket.sent).length, 0);
});

test('Lua handler failure and missing ReplyToServer do not leave an actionable request', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 301);
  h.conn.lua.call = <T>(): T => { throw new Error('Lua update failed'); };
  assert.throws(() => h.conn.respondToSkillInvoke(301, 'OK'), /Lua update failed/);
  assert.equal(h.requests.at(-1), null);
  assert.equal(h.sockets[0].sent.length, 0);
  prepareSkillRequest(h, 302);
  h.conn.lua.call = <T>(): T => true as T;
  assert.throws(() => h.conn.respondToSkillInvoke(302, 'OK'), /Lua chưa tạo phản hồi/);
  assert.equal(h.requests.at(-1), null);
  assert.equal(h.sockets[0].sent.length, 0);
});

test('Lua cannot send a reply during UpdateRequestUI before the explicit __web_reply call', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 401);
  h.conn.lua.call = <T>(name: string): T => {
    if (name === 'UpdateRequestUI') {
      h.conn['sendFromLua']('reply', '', '4131');
      assert.equal(h.sockets[0].sent.length, 0, 'premature Lua reply was blocked');
      h.conn['handleLuaUi']('ReplyToServer', '1');
    } else if (name === '__web_reply') {
      h.conn['sendFromLua']('reply', '', '4131');
    }
    return true as T;
  };
  h.conn.respondToSkillInvoke(401, 'OK');
  assert.equal(h.sockets[0].sent.length, 1);
  assert.equal(new PacketStream().push(h.sockets[0].sent[0])[0].requestId, 401);
});

test('Lua reply with wrong CBOR payload or changed request expiry is rejected', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 402);
  h.conn.lua.call = <T>(name: string): T => {
    if (name === 'UpdateRequestUI') h.conn['handleLuaUi']('ReplyToServer', '1');
    if (name === '__web_reply') h.conn['sendFromLua']('reply', '', '485f5f63616e63656c');
    return true as T;
  };
  assert.throws(() => h.conn.respondToSkillInvoke(402, 'OK'), /chưa được chuyển/);
  assert.equal(h.sockets[0].sent.length, 0);
  assert.equal(h.requests.at(-1), null);

  prepareSkillRequest(h, 403);
  h.conn.lua.call = <T>(name: string): T => {
    if (name === 'UpdateRequestUI') h.conn['handleLuaUi']('ReplyToServer', '1');
    if (name === '__web_reply') {
      h.conn['pendingRequest']!.expiresAt = Date.now() - 1;
      h.conn['sendFromLua']('reply', '', '4131');
    }
    return true as T;
  };
  assert.throws(() => h.conn.respondToSkillInvoke(403, 'OK'), /chưa được chuyển/);
  assert.equal(h.sockets[0].sent.length, 0);
  assert.equal(h.requests.at(-1), null);
});

test('request published after Lua callback cannot resurrect a closed or superseded request', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  h.conn.lua.receive = (command) => {
    if (command === 'First') h.sockets[0].handlers.onClose('closed during Lua callback');
  };
  h.sockets[0].handlers.onData(encodePacket(h.packet('First', SERVER_REQUEST, 501)));
  assert.equal(h.conn.getStatus().kind, 'closed');
  assert.equal(h.conn['pendingRequest'], null);
  assert.equal(h.requests.at(-1), null);

  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  h.conn.lua.receive = (command) => {
    if (command === 'Second') {
      h.sockets[1].handlers.onData(encodePacket(h.packet('Third', SERVER_REQUEST, 503)));
    }
  };
  h.sockets[1].handlers.onData(encodePacket(h.packet('Second', SERVER_REQUEST, 502)));
  assert.equal((h.conn['pendingRequest'] as RequestInfo | null)?.requestId, 503);
  assert.equal(h.requests.at(-1), 'Third');
});

const GENERAL_REPLY_HEX = '825063616f63616f2c786961686f7564756e4b6b696e67646f6d2c776569';

function prepareGeneralRequest(h: ReturnType<typeof harness>, id: number,
    opts: { timestamp?: number; timeout?: number; component?: string } = {}) {
  h.conn.lua.receive = (command) => {
    if (command !== 'CustomDialog') return;
    h.conn['handleLuaUi']('CancelRequest', null);
    h.conn['handleLuaUi']('CustomDialog', { component: {
      name: opts.component ?? 'ChooseInitialGeneralBox', model: {
        name: 'ChooseInitialGeneralModel', prop: {
          hegemony: true, choiceNum: 2,
          generals: ['caocao', 'xiahoudun', 'liubei'], enabledKingdoms: ['wei', 'shu'],
        },
      },
    } });
  };
  h.sockets.at(-1)!.handlers.onData(encodePacket({
    ...h.packet('CustomDialog', SERVER_REQUEST, id),
    timestamp: opts.timestamp ?? Date.now(), timeout: opts.timeout ?? 30,
  }));
}

function mockGeneralLua(h: ReturnType<typeof harness>, replyHex = GENERAL_REPLY_HEX) {
  h.conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === '__web_general_kingdoms') {
      return (args[0] === 'caocao' && args[1] === 'xiahoudun' ? ['wei'] : []) as T;
    }
    if (name === '__web_general_reply_hex') return GENERAL_REPLY_HEX as T;
    if (name === '__web_general_reply') h.conn['sendFromLua']('reply', '', replyHex);
    return true as T;
  };
}

test('user-confirmed Hegemony selection sends exactly one authorized CBOR reply', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareGeneralRequest(h, 601);
  mockGeneralLua(h);
  assert.deepEqual(h.conn.getInitialGeneralKingdoms(601, 'caocao', 'xiahoudun'), ['wei']);
  assert.equal(h.sockets[0].sent.length, 0);
  h.conn['sendFromLua']('reply', '', GENERAL_REPLY_HEX);
  assert.equal(h.sockets[0].sent.length, 0, 'unsolicited Lua reply must be dropped');
  h.conn.respondToInitialGeneral(601, 'caocao', 'xiahoudun', 'wei');
  assert.equal(h.sockets[0].sent.length, 1);
  const reply = new PacketStream().push(h.sockets[0].sent[0])[0];
  assert.equal(reply.type, CLIENT_REPLY);
  assert.equal(reply.requestId, 601);
  assert.equal(reply.command, '');
  assert.equal(Buffer.from(reply.data).toString('hex'), GENERAL_REPLY_HEX);
  assert.equal(h.requests.at(-1), null);
  assert.throws(() => h.conn.respondToInitialGeneral(601, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
});

test('invalid, replaced, expired, canceled, and disconnected general requests never reply', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  mockGeneralLua(h);
  prepareGeneralRequest(h, 602);
  mockGeneralLua(h);
  assert.throws(() => h.conn.respondToInitialGeneral(601, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
  assert.throws(() => h.conn.respondToInitialGeneral(602, 'caocao', 'caocao', 'wei'), /không hợp lệ/);
  assert.throws(() => h.conn.respondToInitialGeneral(602, 'invalid', 'xiahoudun', 'wei'), /không hợp lệ/);
  assert.throws(() => h.conn.respondToInitialGeneral(602, 'caocao', 'xiahoudun', 'shu'), /không hợp lệ/);
  assert.equal(h.sockets[0].sent.length, 0);
  prepareGeneralRequest(h, 603);
  mockGeneralLua(h);
  assert.throws(() => h.conn.respondToInitialGeneral(602, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
  h.conn['handleLuaUi']('CancelRequest', null);
  assert.throws(() => h.conn.respondToInitialGeneral(603, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
  prepareGeneralRequest(h, 604, { timestamp: Date.now() - 5000, timeout: 1 });
  mockGeneralLua(h);
  assert.throws(() => h.conn.respondToInitialGeneral(604, 'caocao', 'xiahoudun', 'wei'), /hết thời gian/);
  prepareGeneralRequest(h, 605, { component: 'OtherDialog' });
  mockGeneralLua(h);
  assert.throws(() => h.conn.respondToInitialGeneral(605, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
  prepareGeneralRequest(h, 606);
  mockGeneralLua(h);
  h.conn.connect();
  assert.throws(() => h.conn.respondToInitialGeneral(606, 'caocao', 'xiahoudun', 'wei'), /không còn hiệu lực/);
  assert.equal(h.sockets.flatMap((socket) => socket.sent).length, 0);
});

test('Lua errors, mismatched CBOR, and canceled requests during reply fail closed', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareGeneralRequest(h, 701);
  mockGeneralLua(h, '4131');
  assert.throws(() => h.conn.respondToInitialGeneral(701, 'caocao', 'xiahoudun', 'wei'), /chưa tới/);
  assert.equal(h.requests.at(-1), null);

  prepareGeneralRequest(h, 702);
  mockGeneralLua(h);
  h.conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === '__web_general_reply_hex') throw new Error('Lua CBOR encoder failed');
    if (name === '__web_general_kingdoms') return ['wei'] as T;
    if (name === '__web_general_reply') h.conn['sendFromLua']('reply', '', GENERAL_REPLY_HEX);
    return args as T;
  };
  assert.throws(() => h.conn.respondToInitialGeneral(702, 'caocao', 'xiahoudun', 'wei'), /Lua CBOR encoder failed/);
  assert.equal(h.requests.at(-1), null);

  prepareGeneralRequest(h, 703);
  mockGeneralLua(h);
  const initialCall = h.conn.lua.call.bind(h.conn.lua);
  h.conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === '__web_general_reply') h.conn['handleLuaUi']('CancelRequest', null);
    return initialCall<T>(name, ...args);
  };
  assert.throws(() => h.conn.respondToInitialGeneral(703, 'caocao', 'xiahoudun', 'wei'), /chưa tới/);
  assert.equal(h.requests.at(-1), null);
  assert.equal(h.sockets[0].sent.length, 0);
});

test('reentrant UI callback replacing a Hegemony request cannot send its stale reply', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareGeneralRequest(h, 801);
  mockGeneralLua(h);
  let replaced = false;
  const oldOnRequest = h.conn['opts'].onRequest;
  h.conn['opts'].onRequest = (request) => {
    oldOnRequest?.(request);
    if (request === null && !replaced) {
      replaced = true;
      prepareGeneralRequest(h, 802);
      mockGeneralLua(h);
    }
  };
  assert.throws(() => h.conn.respondToInitialGeneral(801, 'caocao', 'xiahoudun', 'wei'), /chưa tới/);
  assert.equal(h.sockets[0].sent.length, 0);
  assert.equal(h.conn['pendingRequest']?.requestId, 802);
  h.conn.respondToInitialGeneral(802, 'caocao', 'xiahoudun', 'wei');
  assert.equal(h.sockets[0].sent.length, 1);
  assert.equal(new PacketStream().push(h.sockets[0].sent[0])[0].requestId, 802);
});

test('reentrant socket replacement on request cleanup never sends through old transport', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareSkillRequest(h, 803);
  h.conn.lua.call = <T>(name: string): T => {
    if (name === 'UpdateRequestUI') h.conn['handleLuaUi']('ReplyToServer', '1');
    if (name === '__web_reply') h.conn['sendFromLua']('reply', '', '4131');
    return true as T;
  };
  const oldOnRequest = h.conn['opts'].onRequest;
  let reconnected = false;
  h.conn['opts'].onRequest = (request) => {
    oldOnRequest?.(request);
    if (request === null && !reconnected) {
      reconnected = true;
      h.conn.connect();
    }
  };
  assert.throws(() => h.conn.respondToSkillInvoke(803, 'OK'), /chưa được chuyển/);
  assert.equal(h.sockets[0].sent.length, 0);
  assert.equal(h.sockets[0].closed, true);
  assert.equal(h.sockets[1].sent.length, 0);
  assert.equal(h.conn.getStatus().kind, 'connecting');
});

test('socket send failure during authorized Hegemony reply closes session and propagates error', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  prepareGeneralRequest(h, 804);
  mockGeneralLua(h);
  h.conn['socket']!.send = () => { throw new Error('socket write failed'); };
  assert.throws(() => h.conn.respondToInitialGeneral(804, 'caocao', 'xiahoudun', 'wei'),
    /socket write failed/);
  assert.equal(h.conn.getStatus().kind, 'closed');
  assert.equal(h.requests.at(-1), null);
  assert.equal(h.sockets[0].sent.length, 0);
});

test('game phase boundaries invalidate outstanding gameplay requests', () => {
  const h = harness();
  h.conn.connect();
  h.conn['setStatus']({ kind: 'online' });
  for (const command of ['StartGame', 'GameOver', 'EnterLobby']) {
    prepareGeneralRequest(h, 805);
    mockGeneralLua(h);
    h.conn['handleLuaUi'](command, null);
    assert.equal(h.conn['pendingRequest'], null, `${command} must invalidate the server request`);
    assert.throws(() => h.conn.respondToInitialGeneral(805, 'caocao', 'xiahoudun', 'wei'),
      /không còn hiệu lực/);
  }
  assert.equal(h.sockets[0].sent.length, 0);
});


test('Reconnect becomes online only after Lua accepts the complete room snapshot', () => {
  for (const fail of [false, true]) {
    const h = harness(); h.conn.connect(); h.conn['setStatus']({kind:'authenticating'});
    h.conn.lua.receive = command => {
      assert.equal(command,'Reconnect'); assert.equal(h.conn.getStatus().kind,'authenticating');
      if (fail) throw new Error('Invalid reconnect snapshot');
    };
    h.sockets[0].handlers.onData(encodePacket(h.packet('Reconnect')));
    assert.equal(h.conn.getStatus().kind,fail ? 'closed' : 'online');
  }
});


test('EmptyRequest is the native animation delay and never exposes a reply control', () => {
  const h=harness();h.conn.connect();h.conn['setStatus']({kind:'online'});
  h.sockets[0].handlers.onData(encodePacket({...h.packet('EmptyRequest',SERVER_REQUEST,99),timeout:2,timestamp:Date.now()}));
  assert.equal(h.conn['pendingRequest'],null);assert.equal(h.sockets[0].sent.length,0);
  assert.equal(h.conn.getStatus().kind,'online');
});
