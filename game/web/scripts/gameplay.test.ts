import assert from 'node:assert/strict';
import { test } from 'node:test';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { validInteractionAction } from '../src/engine/gameplayInteraction';
import { CLIENT_REPLY, PacketStream, PacketType, encodePacket } from '../src/engine/packet';
import { emptyGameplay, getGameplayItem, reduceGameplay, type GameplayItem } from '../src/store/gameplayState';

const item = (spec: unknown, refresh_data?: unknown): GameplayItem => ({
  id: '1', enabled: true, selected: false, spec, refresh_data,
});

test('Lua scene additions, updates, deletions, prompt changes and replacement are incremental', () => {
  let scene = reduceGameplay(emptyGameplay(), {
    _type: 'RoomScene', _prompt: 'Chọn bài',
    _new: [
      { type: 'CardItem', data: { id: 8, enabled: true, selected: false } },
      { type: 'Photo', data: { id: 2, enabled: true, selected: false } },
      { type: 'Interaction', data: { id: '1', enabled: true, spec: { type: 'combo', choices: ['a'] } } },
    ],
  });
  scene = reduceGameplay(scene, { _type: 'RoomScene', _prompt: 'Chọn mục tiêu',
    CardItem: [{ id: 8, selected: true }],
    Photo: [{ id: 2, selected: true, enabled: false }],
    Interaction: [{ id: '1', refresh_data: { options: ['b'] } }],
  });
  assert.equal(scene.prompt, 'Chọn mục tiêu');
  assert.equal(getGameplayItem(scene, 'CardItem', 8)?.selected, true);
  assert.equal(getGameplayItem(scene, 'Photo', 2)?.selected, true);
  assert.equal(getGameplayItem(scene, 'Photo', 2)?.enabled, false);
  assert.deepEqual(getGameplayItem(scene, 'Interaction', '1')?.spec, { type: 'combo', choices: ['a'] });
  assert.deepEqual(getGameplayItem(scene, 'Interaction', '1')?.refresh_data, { options: ['b'] });
  scene = reduceGameplay(scene, { _type: 'RoomScene', _delete: [
    { type: 'Interaction', id: '1' }, { type: 'CardItem', id: 8 },
  ] });
  assert.equal(getGameplayItem(scene, 'CardItem', 8), undefined);
  assert.equal(getGameplayItem(scene, 'Interaction', '1'), undefined);
  assert.ok(getGameplayItem(scene, 'Photo', 2));
  assert.deepEqual(reduceGameplay(scene, { _type: 'NewScene' }).items.Photo, {});
  // A forged typed update cannot fabricate a selectable object.
  assert.deepEqual(reduceGameplay(emptyGameplay(), {
    _type: 'RoomScene', CardItem: [{ id: 999, enabled: true }],
  }).items.CardItem, {});
});

test('gameplay metadata is public-projected and bounded before entering React state', () => {
  const huge = 'x'.repeat(100_000);
  const scene = reduceGameplay(emptyGameplay(), {
    _type: 'RoomScene',
    _new: [
      { type: 'CardItem', data: {
        id: 8, enabled: true, selected: false,
        card: { name: 'slash', trueName: 'slash', suit: 2, number: 7,
          cardId: 991, subcards: [1, 2], privateGraph: huge },
      } },
      { type: 'Interaction', data: {
        id: 'choice', enabled: true,
        spec: { type: 'combo', choices: ['a'], privateGraph: huge,
          nested: { alsoPrivate: huge } },
        refresh_data: { optionBox: { options: ['a'] }, privateGraph: huge },
      } },
    ],
  });
  const card = getGameplayItem(scene, 'CardItem', 8)?.card as Record<string, unknown>;
  assert.deepEqual(card, { name: 'slash', trueName: 'slash', suit: 2, number: 7 });
  const interaction = getGameplayItem(scene, 'Interaction', 'choice')!;
  assert.deepEqual(interaction.spec, { type: 'combo', choices: ['a'] });
  assert.deepEqual(interaction.refresh_data, { optionBox: { options: ['a'] } });
  assert.ok(JSON.stringify(scene).length < 10_000, 'private oversized metadata must not be retained');
});

test('gameplay state rejects prototype keys and caps retained public items', () => {
  const forged = reduceGameplay(emptyGameplay(), {
    _type: 'RoomScene',
    _new: [{ type: 'CardItem', data: { id: '__proto__', enabled: true, selected: false } },
      { type: 'Interaction', data: { id: 'constructor', enabled: true, selected: false } }],
  });
  assert.equal(Object.keys(forged.items.CardItem).length, 0);
  assert.equal(Object.keys(forged.items.Interaction).length, 0);
  const many = reduceGameplay(emptyGameplay(), {
    _type: 'RoomScene',
    _new: Array.from({ length: 700 }, (_, id) => ({ type: 'Button', data: {
      id: `button-${id}`, enabled: true, selected: false,
    } })),
  });
  assert.equal(Object.keys(many.items.Button).length, 512);
  assert.equal(many.items.Button['button-699']?.enabled, true);
});

test('standard Lua interactions validate action, choice, range, and direct send', () => {
  assert.equal(validInteractionAction(item({ type: 'combo', choices: ['a', 'b'] }), 'update', 'b'), true);
  assert.equal(validInteractionAction(item({ type: 'combo', choices: ['a'] }), 'update', 'wrong'), false);
  assert.equal(validInteractionAction(item({ type: 'checkbox', choices: ['a', 'b'] }), 'update', ['a', 'b']), true);
  assert.equal(validInteractionAction(item({ type: 'checkbox', choices: ['a'] }), 'update', ['a', 'a']), false);
  assert.equal(validInteractionAction(item({ type: 'spin', from: 1, to: 5 }), 'update', 3), true);
  assert.equal(validInteractionAction(item({ type: 'spin', from: 1, to: 5 }), 'update', 6), false);
  assert.equal(validInteractionAction(item({ type: 'expandItems', ids: [2], card_names: ['sha'] }), 'update', 2), true);
  assert.equal(validInteractionAction(item({ type: 'expandItems', ids: [2] }), 'update', 10), false);
  const direct = item({ type: 'optionbox', options: ['a', 'b'], direct_send: true });
  assert.equal(validInteractionAction(direct, 'finish', 'a'), true);
  assert.equal(validInteractionAction(direct, 'finish', 'not-offered'), false);
  assert.equal(validInteractionAction(item({ type: 'optionbox', options: ['a'] }), 'finish', 'a'), false);
  assert.equal(validInteractionAction(item({ type: 'custom', qml: 'malicious' }), 'update', 'foo'), false);
});

test('dynamic Lua interactions preserve identifiers, selection constraints and finish payloads', () => {
  const dynamic = item({ type: 'ToBeDecided' }, {
    optionBox: { options: ['use', 'discard'], direct_send: true, cancelable: true },
    expandItems: [{ cid: -7, name: 'virtual-card', prop: { type: 'card' } }],
    enabled_ids: [-7], pendings: [-7],
  });
  assert.equal(validInteractionAction(dynamic, 'update', {
    elemType: 'ExpandItem', cid: -7, name: 'virtual-card', autoTarget: false,
  }), true);
  assert.equal(validInteractionAction(dynamic, 'update', {
    elemType: 'ExpandItem', cid: -7, name: 'changed', autoTarget: false,
  }), false);
  assert.equal(validInteractionAction(dynamic, 'update', {
    elemType: 'OptionBox', option: 'Cancel', autoTarget: false,
  }), true);
  assert.equal(validInteractionAction(dynamic, 'finish', { option: 'use', autoTarget: false }), true);
  assert.equal(validInteractionAction(dynamic, 'finish', { option: 'use', autoTarget: true }), false);
  assert.equal(validInteractionAction(dynamic, 'click', { option: 'use', autoTarget: false }), false);
});

test('gameplay actions remain pending through choices and only Lua OK sends exact CBOR bytes', () => {
  const sent: Uint8Array[] = [];
  let socketHandlers!: SocketHandlers;
  const requests: (number | null)[] = [];
  const conn = new GameConnection({
    files: new Map(), username: 'test', password: 'hidden', md5: 'md5', uuid: 'uuid',
    openSocket: (handlers) => {
      socketHandlers = handlers;
      return { send: (packet) => sent.push(packet), close: () => {} };
    },
    onUi: () => {}, onRequest: (r) => requests.push(r?.requestId ?? null),
  });
  conn.connect();
  conn['setStatus']({ kind: 'online' });
  conn.lua.receive = () => {
    conn['handleLuaUi']('UpdateRequestUI', { _type: 'RoomScene', _new: [
      { type: 'CardItem', data: { id: 7, enabled: true, selected: false } },
      { type: 'Photo', data: { id: 3, enabled: true, selected: false } },
      { type: 'SkillButton', data: { id: 'skill', enabled: true, selected: false } },
      { type: 'Button', data: { id: 'OK', enabled: true } },
      { type: 'Button', data: { id: 'End', enabled: false } },
      { type: 'Interaction', data: { id: '1', enabled: true,
        spec: { type: 'optionbox', options: ['go'], direct_send: true } } },
    ] });
  };
  socketHandlers.onData(encodePacket({
    requestId: 77, command: 'PlayCard', type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
  }));
  assert.equal(requests.at(-1), 77);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      const [kind, id, , data] = args;
      if (kind === 'CardItem') conn['handleLuaUi']('UpdateRequestUI', {
        _type: 'RoomScene', CardItem: [{ id, selected: (data as { selected: boolean }).selected }],
      });
      if (kind === 'Button' && id === 'OK') conn['handleLuaUi']('ReplyToServer', 'done');
    } else if (name === '__web_reply_hex') {
      assert.equal(args[0], 'done');
      return '44646f6e65' as T; // Lua CBOR byte string "done".
    } else if (name === '__web_reply') {
      conn['sendFromLua']('reply', '', '44646f6e65');
    }
    return undefined as T;
  };
  conn.updateRequestUI(77, 'CardItem', 7, 'click', { selected: true });
  assert.equal(conn['gameplayScene'].items.CardItem['7'].selected, true);
  conn.updateRequestUI(77, 'SkillButton', 'skill', 'click', { selected: true });
  assert.deepEqual(actions.at(-1)?.[3], { selected: true, autoTarget: false });
  conn.updateRequestUI(77, 'Photo', 3, 'click', { selected: true });
  assert.throws(() => conn.updateRequestUI(77, 'Button', 'End', 'click', null), /Lua cho phép/);
  assert.throws(() => conn.updateRequestUI(77, 'Interaction', '1', 'finish', 'bad'), /Lua cho phép/);
  conn.updateRequestUI(77, 'Interaction', '1', 'finish', 'go');
  assert.equal(sent.length, 0);
  assert.equal(requests.at(-1), 77);
  conn.updateRequestUI(77, 'Button', 'OK', 'click', null);
  assert.equal(requests.at(-1), null);
  assert.equal(sent.length, 1);
  const reply = new PacketStream().push(sent[0])[0];
  assert.equal(reply.type, CLIENT_REPLY);
  assert.equal(reply.requestId, 77);
  assert.deepEqual([...reply.data], [0x44, 0x64, 0x6f, 0x6e, 0x65]);
  assert.throws(() => conn.updateRequestUI(77, 'Button', 'OK', 'click', null), /không còn hiệu lực/);
});

test('Interaction.finish applies Lua scene changes before Button.OK completes the same request', () => {
  const sent: Uint8Array[] = [];
  const requests: (number | null)[] = [];
  const ui: string[] = [];
  let socketHandlers!: SocketHandlers;
  const conn = new GameConnection({
    files: new Map(), username: 'test', password: 'hidden', md5: 'md5', uuid: 'uuid',
    openSocket: (handlers) => {
      socketHandlers = handlers;
      return { send: (packet) => sent.push(packet), close: () => {} };
    },
    onUi: (command) => ui.push(command),
    onRequest: (request) => requests.push(request?.requestId ?? null),
  });
  conn.connect();
  conn['setStatus']({ kind: 'online' });
  conn.lua.receive = () => conn['handleLuaUi']('UpdateRequestUI', {
    _type: 'RoomScene', _prompt: 'Chọn phương án', _new: [
      { type: 'Interaction', data: { id: 'dialog', enabled: true,
        spec: { type: 'optionbox', options: ['use'], direct_send: true } } },
      { type: 'Button', data: { id: 'OK', enabled: false } },
    ],
  });
  socketHandlers.onData(encodePacket({
    requestId: 901, command: 'AskForUseCard',
    type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
  }));
  const originalRequest = conn['pendingRequest'];
  assert.ok(originalRequest);
  assert.throws(() => conn.updateRequestUI(901, 'Button', 'OK', 'click', null), /Lua cho phép/);

  const calls: string[] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    calls.push(name);
    if (name === 'UpdateRequestUI' && args[0] === 'Interaction') {
      assert.deepEqual(args, ['Interaction', 'dialog', 'finish', 'use']);
      conn['handleLuaUi']('UpdateRequestUI', {
        _type: 'RoomScene', _prompt: 'Xác nhận sử dụng',
        Button: [{ id: 'OK', enabled: true }],
        Interaction: [{ id: 'dialog', enabled: false }],
      });
    }
    if (name === 'UpdateRequestUI' && args[0] === 'Button') {
      assert.deepEqual(args, ['Button', 'OK', 'click', {}]);
      conn['handleLuaUi']('ReplyToServer', 'accepted');
    }
    if (name === '__web_reply_hex') {
      assert.equal(args[0], 'accepted');
      return '486163636570746564' as T;
    }
    if (name === '__web_reply') {
      assert.equal(args[0], 'accepted');
      conn['sendFromLua']('reply', '', '486163636570746564');
    }
    return undefined as T;
  };
  conn.updateRequestUI(901, 'Interaction', 'dialog', 'finish', 'use');
  assert.equal(conn['pendingRequest'], originalRequest);
  assert.equal(conn['gameplayScene'].prompt, 'Xác nhận sử dụng');
  assert.equal(conn['gameplayScene'].items.Button.OK.enabled, true);
  assert.equal(conn['gameplayScene'].items.Interaction.dialog.enabled, false);
  assert.equal(requests.at(-1), 901);
  assert.equal(sent.length, 0, 'finishing an interaction must not send a reply by itself');
  assert.deepEqual(calls, ['UpdateRequestUI']);
  assert.throws(() => conn.updateRequestUI(901, 'Interaction', 'dialog', 'finish', 'use'), /Lua cho phép/);

  conn.updateRequestUI(901, 'Button', 'OK', 'click', null);
  assert.deepEqual(calls, ['UpdateRequestUI', 'UpdateRequestUI', '__web_reply_hex', '__web_reply']);
  assert.deepEqual(ui, ['UpdateRequestUI', 'UpdateRequestUI']);
  assert.equal(requests.at(-1), null);
  assert.equal(sent.length, 1);
  const packet = new PacketStream().push(sent[0])[0];
  assert.equal(packet.type, CLIENT_REPLY);
  assert.equal(packet.requestId, 901);
  assert.equal(new TextDecoder().decode(packet.data.subarray(1)), 'accepted');
  assert.equal(packet.data[0], 0x48);
  assert.throws(() => conn.updateRequestUI(901, 'Button', 'OK', 'click', null), /không còn hiệu lực/);
});

test('Lua without ReplyToServer keeps the request actionable across finish and OK steps', () => {
  const sent: Uint8Array[] = [];
  const requests: (number | null)[] = [];
  let socketHandlers!: SocketHandlers;
  const conn = new GameConnection({
    files: new Map(), username: 'test', password: 'hidden', md5: 'md5', uuid: 'uuid',
    openSocket: (handlers) => {
      socketHandlers = handlers;
      return { send: (packet) => sent.push(packet), close: () => {} };
    },
    onUi: () => {}, onRequest: (request) => requests.push(request?.requestId ?? null),
  });
  conn.connect();
  conn['setStatus']({ kind: 'online' });
  conn.lua.receive = () => conn['handleLuaUi']('UpdateRequestUI', {
    _type: 'RoomScene', _prompt: 'Bước 1', _new: [
      { type: 'Interaction', data: { id: 'choice', enabled: true,
        spec: { type: 'optionbox', options: ['first'], direct_send: true } } },
      { type: 'Button', data: { id: 'OK', enabled: true } },
    ],
  });
  socketHandlers.onData(encodePacket({
    requestId: 902, command: 'PlayCard',
    type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
  }));
  const originalRequest = conn['pendingRequest'];
  assert.ok(originalRequest);

  const actions: unknown[][] = [];
  let okCount = 0;
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      if (args[0] === 'Button' && ++okCount === 1) {
        // The first OK advances Lua's internal interaction without finishing.
        conn['handleLuaUi']('UpdateRequestUI', {
          _type: 'RoomScene', _prompt: 'Bước 2',
          Interaction: [{ id: 'choice', spec: {
            type: 'optionbox', options: ['second'], direct_send: true,
          } }],
        });
      } else if (args[0] === 'Button' && okCount === 2) {
        conn['handleLuaUi']('ReplyToServer', 'done');
      }
    } else if (name === '__web_reply_hex') {
      return '44646f6e65' as T;
    } else if (name === '__web_reply') {
      conn['sendFromLua']('reply', '', '44646f6e65');
    }
    return undefined as T;
  };
  conn.updateRequestUI(902, 'Interaction', 'choice', 'finish', 'first');
  conn.updateRequestUI(902, 'Button', 'OK', 'click', null);
  assert.equal(conn['pendingRequest'], originalRequest, 'Lua has not finished this request');
  assert.equal(requests.at(-1), 902);
  assert.equal(conn['gameplayScene'].prompt, 'Bước 2');
  assert.equal(sent.length, 0);
  assert.throws(() => conn.updateRequestUI(902, 'Interaction', 'choice', 'finish', 'first'), /Lua cho phép/);

  conn.updateRequestUI(902, 'Interaction', 'choice', 'finish', 'second');
  assert.equal(conn['pendingRequest'], originalRequest);
  assert.equal(sent.length, 0);
  conn.updateRequestUI(902, 'Button', 'OK', 'click', null);
  assert.deepEqual(actions, [
    ['Interaction', 'choice', 'finish', 'first'],
    ['Button', 'OK', 'click', {}],
    ['Interaction', 'choice', 'finish', 'second'],
    ['Button', 'OK', 'click', {}],
  ]);
  assert.equal(sent.length, 1);
  assert.equal(new PacketStream().push(sent[0])[0].requestId, 902);
  assert.equal(requests.at(-1), null);
});

function directHarness(requestId: number) {
  const sent: Uint8Array[] = [];
  const requests: (number | null)[] = [];
  let socketHandlers!: SocketHandlers;
  const conn = new GameConnection({
    files: new Map(), username: 'test', password: 'hidden', md5: 'md5', uuid: 'uuid',
    openSocket: (handlers) => {
      socketHandlers = handlers;
      return { send: (packet) => sent.push(packet), close: () => {} };
    },
    onUi: () => {}, onRequest: (request) => requests.push(request?.requestId ?? null),
  });
  conn.connect();
  conn['setStatus']({ kind: 'online' });
  conn.lua.receive = () => conn['handleLuaUi']('UpdateRequestUI', {
    _type: 'RoomScene', _prompt: 'Bước 1', _new: [
      { type: 'Interaction', data: { id: 'choice', enabled: true,
        spec: { type: 'optionbox', options: ['first'], direct_send: true } } },
      { type: 'Button', data: { id: 'OK', enabled: true } },
    ],
  });
  const receive = (id: number) => socketHandlers.onData(encodePacket({
    requestId: id, command: 'PlayCard',
    type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
  }));
  receive(requestId);
  const original = conn['pendingRequest'];
  assert.ok(original);
  return { conn, sent, requests, receive, original, originalSocketHandlers: socketHandlers };
}

test('direct finish with immediate Lua ReplyToServer sends exactly once without pressing OK', () => {
  const { conn, sent, requests, original } = directHarness(903);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      conn['handleLuaUi']('ReplyToServer', 'done');
    } else if (name === '__web_reply_hex') {
      assert.equal(args[0], 'done');
      return '44646f6e65' as T;
    } else if (name === '__web_reply') {
      conn['sendFromLua']('reply', '', '44646f6e65');
    }
    return undefined as T;
  };

  conn.finishDirectInteraction(903, 'choice', 'first');
  assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']]);
  assert.notEqual(conn['pendingRequest'], original);
  assert.equal(conn['pendingRequest'], null);
  assert.equal(requests.at(-1), null);
  assert.equal(sent.length, 1);
  const packet = new PacketStream().push(sent[0])[0];
  assert.equal(packet.type, CLIENT_REPLY);
  assert.equal(packet.requestId, 903);
  assert.deepEqual([...packet.data], [0x44, 0x64, 0x6f, 0x6e, 0x65]);
  assert.throws(() => conn.finishDirectInteraction(903, 'choice', 'first'), /không còn hiệu lực/);
  assert.equal(sent.length, 1);
});

test('direct finish respects Lua disabling OK and leaves the request available for later choice', () => {
  const { conn, sent, requests, original } = directHarness(904);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      if (args[0] === 'Interaction') {
        conn['handleLuaUi']('UpdateRequestUI', {
          _type: 'RoomScene', _prompt: 'Chưa thể xác nhận',
          Button: [{ id: 'OK', enabled: false }],
          Interaction: [{ id: 'choice', enabled: false }],
        });
      }
    }
    return undefined as T;
  };

  conn.finishDirectInteraction(904, 'choice', 'first');
  assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']]);
  assert.equal(conn['pendingRequest'], original);
  assert.equal(requests.at(-1), 904);
  assert.equal(conn['gameplayScene'].prompt, 'Chưa thể xác nhận');
  assert.equal(conn['gameplayScene'].items.Button.OK.enabled, false);
  assert.equal(sent.length, 0);
  assert.throws(() => conn.updateRequestUI(904, 'Button', 'OK', 'click', null), /Lua cho phép/);
  assert.equal(conn['pendingRequest'], original);
  conn['handleLuaUi']('UpdateRequestUI', {
    _type: 'RoomScene', Button: [{ id: 'OK', enabled: true }],
  });
  conn.updateRequestUI(904, 'Button', 'OK', 'click', null);
  assert.deepEqual(actions.at(-1), ['Button', 'OK', 'click', {}]);
  assert.equal(conn['pendingRequest'], original, 'Lua has not replied yet');
  assert.equal(sent.length, 0);
});

test('direct finish waits for a replaced interaction before automatically pressing OK', () => {
  const { conn, sent, requests, original } = directHarness(905);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      if (args[0] === 'Interaction' && args[3] === 'first') {
        // Lua reuses the same item ID for a new interaction while OK stays enabled.
        conn['handleLuaUi']('UpdateRequestUI', {
          _type: 'RoomScene', _prompt: 'Bước 2',
          Interaction: [{ id: 'choice', spec: {
            type: 'optionbox', options: ['second'], direct_send: true,
          } }],
        });
      } else if (args[0] === 'Button') {
        conn['handleLuaUi']('ReplyToServer', 'done');
      }
    } else if (name === '__web_reply_hex') {
      return '44646f6e65' as T;
    } else if (name === '__web_reply') {
      conn['sendFromLua']('reply', '', '44646f6e65');
    }
    return undefined as T;
  };

  conn.finishDirectInteraction(905, 'choice', 'first');
  assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']]);
  assert.equal(conn['pendingRequest'], original);
  assert.equal(requests.at(-1), 905);
  assert.equal(conn['gameplayScene'].prompt, 'Bước 2');
  assert.equal(conn['gameplayScene'].items.Button.OK.enabled, true);
  assert.equal(sent.length, 0);
  assert.throws(() => conn.finishDirectInteraction(905, 'choice', 'first'), /Lua cho phép/);

  conn.finishDirectInteraction(905, 'choice', 'second');
  assert.deepEqual(actions, [
    ['Interaction', 'choice', 'finish', 'first'],
    ['Interaction', 'choice', 'finish', 'second'],
    ['Button', 'OK', 'click', {}],
  ]);
  assert.equal(conn['pendingRequest'], null);
  assert.equal(sent.length, 1);
  assert.equal(new PacketStream().push(sent[0])[0].requestId, 905);
});

test('direct finish cannot auto-confirm a new Lua step with an identical interaction spec', () => {
  const { conn, sent, requests, original } = directHarness(909);
  const actions: unknown[][] = [];
  let finishes = 0;
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      if (args[0] === 'Interaction' && ++finishes === 1) {
        // Lua advances its prompt but deliberately reuses all interaction data.
        conn['handleLuaUi']('UpdateRequestUI', {
          _type: 'RoomScene', _prompt: 'Bước 2, cùng một phương án',
          Interaction: [{ id: 'choice', enabled: true }],
        });
      } else if (args[0] === 'Button') {
        conn['handleLuaUi']('ReplyToServer', 'done');
      }
    } else if (name === '__web_reply_hex') return '44646f6e65' as T;
    else if (name === '__web_reply') conn['sendFromLua']('reply', '', '44646f6e65');
    return undefined as T;
  };

  conn.finishDirectInteraction(909, 'choice', 'first');
  assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']]);
  assert.equal(conn['pendingRequest'], original);
  assert.equal(requests.at(-1), 909);
  assert.equal(conn['gameplayScene'].prompt, 'Bước 2, cùng một phương án');
  assert.equal(sent.length, 0);

  conn.finishDirectInteraction(909, 'choice', 'first');
  assert.deepEqual(actions, [
    ['Interaction', 'choice', 'finish', 'first'],
    ['Interaction', 'choice', 'finish', 'first'],
    ['Button', 'OK', 'click', {}],
  ]);
  assert.equal(sent.length, 1);
  assert.equal(new PacketStream().push(sent[0])[0].requestId, 909);
});

test('direct finish confirms only after Lua disables the interaction and enables OK', () => {
  const { conn, sent } = directHarness(910);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    if (name === 'UpdateRequestUI') {
      actions.push(args);
      if (args[0] === 'Interaction') {
        conn['handleLuaUi']('UpdateRequestUI', {
          _type: 'RoomScene', _prompt: 'Sẵn sàng',
          Interaction: [{ id: 'choice', enabled: false }],
          Button: [{ id: 'OK', enabled: true }],
        });
      } else if (args[0] === 'Button') conn['handleLuaUi']('ReplyToServer', 'done');
    } else if (name === '__web_reply_hex') return '44646f6e65' as T;
    else if (name === '__web_reply') conn['sendFromLua']('reply', '', '44646f6e65');
    return undefined as T;
  };
  conn.finishDirectInteraction(910, 'choice', 'first');
  assert.deepEqual(actions, [
    ['Interaction', 'choice', 'finish', 'first'],
    ['Button', 'OK', 'click', {}],
  ]);
  assert.equal(sent.length, 1);
  assert.equal(conn['pendingRequest'], null);
});

test('direct finish never confirms after a reconnect or same-ID request replacement', () => {
  for (const mode of ['reconnect', 'same-id'] as const) {
    const { conn, sent, receive, original, originalSocketHandlers } = directHarness(911);
    const actions: unknown[][] = [];
    conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
      if (name === 'UpdateRequestUI') {
        actions.push(args);
        if (mode === 'reconnect') {
          conn.connect();
          conn['setStatus']({ kind: 'online' });
          originalSocketHandlers.onData(encodePacket({
            requestId: 911, command: 'PlayCard',
            type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
            data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
          })); // Deliberately from the stale socket handler.
        } else receive(911); // New request object with the same numeric ID.
      }
      return undefined as T;
    };
    conn.finishDirectInteraction(911, 'choice', 'first');
    assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']]);
    assert.equal(sent.length, 0);
    assert.notEqual(conn['pendingRequest'], original);
    assert.equal(conn['pendingRequest']?.requestId ?? null, mode === 'same-id' ? 911 : null);
  }
});

test('direct finish cannot confirm canceled or synchronously replaced requests', () => {
  for (const mode of ['canceled', 'replaced'] as const) {
    const { conn, sent, requests, receive, original } = directHarness(906);
    const actions: unknown[][] = [];
    conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
      if (name === 'UpdateRequestUI') {
        actions.push(args);
        if (actions.length === 1) {
          if (mode === 'canceled') conn['handleLuaUi']('CancelRequest', null);
          else receive(907);
        }
      }
      return undefined as T;
    };

    conn.finishDirectInteraction(906, 'choice', 'first');
    assert.deepEqual(actions, [['Interaction', 'choice', 'finish', 'first']], mode);
    assert.notEqual(conn['pendingRequest'], original, mode);
    assert.equal(conn['pendingRequest']?.requestId ?? null, mode === 'replaced' ? 907 : null, mode);
    assert.equal(requests.at(-1), mode === 'replaced' ? 907 : null, mode);
    assert.equal(sent.length, 0, mode);
    assert.throws(() => conn.finishDirectInteraction(906, 'choice', 'first'), /không còn hiệu lực/);
    if (mode === 'replaced') {
      // The replacement remains actionable despite the old finish unwinding.
      conn.finishDirectInteraction(907, 'choice', 'first');
      assert.equal(conn['pendingRequest']?.requestId, 907);
      assert.equal(sent.length, 0);
    }
  }
});

test('expired direct finish rejects before calling Lua or sending a packet', () => {
  const { conn, sent, requests, original } = directHarness(908);
  const actions: unknown[][] = [];
  conn.lua.call = <T>(name: string, ...args: unknown[]): T => {
    actions.push([name, ...args]);
    return undefined as T;
  };
  original.expiresAt = Date.now() - 1;

  assert.throws(() => conn.finishDirectInteraction(908, 'choice', 'first'), /hết thời gian/);
  assert.deepEqual(actions, []);
  assert.equal(conn['pendingRequest'], null);
  assert.equal(requests.at(-1), null);
  assert.equal(sent.length, 0);
  assert.throws(() => conn.finishDirectInteraction(908, 'choice', 'first'), /không còn hiệu lực/);
});
