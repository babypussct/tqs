import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseCardsAndChoice, cardsAndChoiceIds } from '../src/engine/cardsAndChoice';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { PacketType, encodePacket } from '../src/engine/packet';

test('native card-and-choice parser accepts empty views and guards allowed cards and options', () => {
  const empty = { cards: [], choices: ['OK'], min: 0, max: 0 };
  assert.ok(parseCardsAndChoice(empty, () => null));
  assert.ok(parseCardsAndChoice({ ...empty, choices: [], cancel_choices: ['cancel'], min: 1, max: 1 }, () => null));
  const payload = { cards: [11, 12], choices: ['default', 'other'], cancel_choices: ['cancel'],
    disabled: [12], min: 1, max: 2, filter_skel: 'fixture', extra_data: { flag: true } };
  let n = 0;
  const parsed = parseCardsAndChoice(payload, () => ({ name: 'slash' }), () => `token-${++n}`)!;
  assert.ok(parsed);
  assert.ok(!('id' in parsed.publicPrompt.cards[0]));
  assert.deepEqual(cardsAndChoiceIds(parsed, ['token-1']), [11]);
  for (const tokens of [['token-2'], ['token-1', 'token-1'], ['forged'], ['11'], null])
    assert.equal(cardsAndChoiceIds(parsed, tokens), null);
  for (const patch of [{ cards: [11, 11] }, { cards: [-1] }, { disabled: [13] },
    { choices: ['default', 'default'] }, { cancel_choices: ['default'] },
    { min: -1 }, { min: 3, max: 2 }, { max: 513 }, { filter_skel: {} },
    { extra_data: ['unexpected'] }, { extra_data: { blob: 'x'.repeat(70_000) } }, { prompt: 42 }])
    assert.equal(parseCardsAndChoice({ ...payload, ...patch }, () => null), null);
  assert.ok(parseCardsAndChoice({ ...payload, extra_data: [] }, () => null),
    'an empty Lua table may be CBOR-decoded as an empty array');
  assert.equal(parseCardsAndChoice({ ...empty, min: 1, max: 1 }, () => null), null);
});

test('card-and-choice public projection excludes private Lua face fields', () => {
  const faceCalls: number[] = [];
  const selection = parseCardsAndChoice({ cards: [10, 11], choices: ['take', 'discard'],
    disabled: [11], min: 0, max: 2, filter_skel: 'sample', extra_data: { privateId: 10 } },
  (id) => { faceCalls.push(id); return { name: 'peach', suit: 3, number: 9,
    cardId: id, privateFlag: 'DO_NOT_FORWARD' }; }, (() => {
    let i = 0; return () => `safe-token-${++i}`;
  })())!;
  assert.deepEqual(faceCalls, [10, 11], 'native CardsAndChoice explicitly reveals addressed cards');
  assert.deepEqual(selection.publicPrompt.cards[0], {
    token: 'safe-token-1', hidden: false, name: 'peach', suit: 3, number: 9,
  });
  assert.equal('extra' in selection.publicPrompt, false);
  assert.equal('disabled' in selection.publicPrompt, false);
  assert.equal('filter' in selection.publicPrompt, false);
  assert.deepEqual(cardsAndChoiceIds(selection, ['safe-token-1']), [10]);
  assert.equal(cardsAndChoiceIds(selection, ['safe-token-2']), null);
  assert.equal(cardsAndChoiceIds(selection, ['safe-token-1', 'safe-token-1']), null);
});

test('view confirmation cannot send after cleanup replaces the same request ID or disconnects', () => {
  for (const action of ['disconnect', 'replace']) {
    let handlers!: SocketHandlers;
    let mutate = false;
    const sent: Uint8Array[] = [];
    const conn = new GameConnection({
      files: new Map(), username: 'test', password: 'test', md5: 'test', uuid: 'test',
      openSocket: (h) => { handlers = h; return { send: (bytes) => sent.push(bytes), close: () => {} }; },
      onUi: (command) => assert.notEqual(command, 'AskForCardsAndChoice'),
      onRequest: (request) => {
        if (request || !mutate) return;
        mutate = false;
        if (action === 'disconnect') handlers.onClose('test disconnect');
        else receive();
      },
    });
    conn.connect();
    conn['setStatus']({ kind: 'online' });
    conn.lua.receive = () => conn['handleLuaUi']('AskForCardsAndChoice', {
      cards: [], choices: ['OK'], min: 0, max: 0,
    });
    conn.lua.call = <T>(name: string): T => {
      if (name === '__web_cards_and_choice_view') return [true] as T;
      if (name === '__web_reply_hex') return 'a0' as T;
      if (name === '__web_reply') conn['sendFromLua']('reply', '', 'a0');
      return undefined as T;
    };
    const receive = () => handlers.onData(encodePacket({ requestId: 1,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForCardsAndChoice', data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
    }));
    receive();
    assert.throws(() => conn.respondToCardsAndChoice(1, [], 'forged'), /không được/);
    mutate = true;
    assert.throws(() => conn.respondToCardsAndChoice(1, [], 'OK'), /chưa đến máy chủ/);
    assert.equal(sent.length, 0);
    assert.equal(conn['pendingRequest']?.requestId ?? null, action === 'disconnect' ? null : 1);
  }
});
