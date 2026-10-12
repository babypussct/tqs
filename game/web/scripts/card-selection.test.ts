import assert from 'node:assert/strict';
import { test } from 'node:test';
import { displayText } from '../src/engine/displayText';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import { parseCardSelection, selectionIds, visibleCardFace } from '../src/engine/cardSelection';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { PacketType, encodePacket } from '../src/engine/packet';

test('hidden cards never query face metadata or expose IDs, including native Poxi visibility 0', () => {
  assert.equal(displayText('#AskForChooseCards:-1::snatch:1:2', { ...VI_ADDITIONS, snatch: 'Thuận Thủ Khiên Dương' },
    [{ id: -1, name: 'Bot' }]), 'Thuận Thủ Khiên Dương: hãy chọn từ 1 đến 2 lá bài của Bot');
  const queried: number[] = [];
  const payload = { type: 'AskForCardsChosen', data: [['$Hand', [10, 11]], ['$Equip', [12]]],
    extra_data: { min: 1, max: 2, visible_data: { '10': false, '11': 0 } }, cancelable: false };
  let token = 0;
  const selection = parseCardSelection('AskForPoxi', payload, (id) => {
    queried.push(id); return { name: 'spear', suit: 1, number: 12 };
  }, () => `opaque-${++token}`)!;
  assert.deepEqual(queried, [12]);
  assert.equal(selection.publicPrompt.groups[0].cards.length, 2);
  for (const card of selection.publicPrompt.groups[0].cards)
    assert.deepEqual(Object.keys(card).sort(), ['hidden', 'token']);
  assert.deepEqual(selectionIds(selection, [selection.publicPrompt.groups[1].cards[0].token]), [12]);
  assert.equal(selectionIds(selection, ['forged']), null);
  assert.equal(selectionIds(selection, ['opaque-1', 'opaque-1']), null);
  assert.equal(parseCardSelection('AskForPoxi', { ...payload, data: [['$Hand', [10, 10]]] }, () => null), null);
  assert.equal(parseCardSelection('AskForPoxi', { ...payload, data: [['$Hand', [-1]]] }, () => null), null);
});

test('single/poxi views only expose whitelisted public fields and preserve per-request tokens', () => {
  const extra = { id: 99, privateMark: 'NEVER_RENDER', name: 'armor', suit: 4, number: 7 };
  assert.deepEqual(visibleCardFace(extra), { name: 'armor', suit: 4, number: 7 });
  assert.deepEqual(visibleCardFace({ name: 'armor', suit: 3, number: NaN }), { name: 'armor', suit: 3 });
  const calls: number[] = [];
  let serial = 0;
  const payload = { card_data: [['$Hand', [1, 2]], ['$Equip', [3]]],
    visible_data: { '1': false, '2': true }, prompt: 'snatch' };
  const parse = () => parseCardSelection('AskForCardChosen', payload,
    (id) => { calls.push(id); return { ...extra, id }; }, () => `token-${++serial}`)!;
  const first = parse();
  const second = parse();
  assert.deepEqual(calls, [2, 3, 2, 3], 'hidden hand may never query Lua face metadata');
  assert.deepEqual(first.publicPrompt.groups[0].cards[0], {
    token: 'token-1', hidden: false, name: 'armor', suit: 4, number: 7,
  });
  assert.deepEqual(Object.keys(first.publicPrompt.groups[0].cards[1]).sort(), ['hidden', 'token']);
  assert.equal(first.publicPrompt.groups[0].cards[1].hidden, true);
  assert.equal(selectionIds(first, [first.publicPrompt.groups[0].cards[1].token])?.[0], 1);
  assert.equal(selectionIds(second, [first.publicPrompt.groups[0].cards[1].token]), null);
  assert.equal('privateMark' in first.publicPrompt.groups[0].cards[0], false);
  assert.equal(parseCardSelection('AskForCardChosen', { ...payload, card_data: [['$Hand', [1, 1]]] }, () => null), null);
  assert.equal(parseCardSelection('AskForCardChosen', { ...payload, visible_data: [] }, () => null), null);
});

test('Poxi accepts omitted extra metadata but rejects oversized or cyclic private graphs', () => {
  const payload = { type: 'AskForCardsChosen', data: [['$Hand', [1]]], cancelable: true };
  assert.ok(parseCardSelection('AskForPoxi', payload, () => null), 'extra_data is optional upstream');
  assert.equal(parseCardSelection('AskForPoxi', {
    ...payload, extra_data: { blob: 'x'.repeat(70_000) },
  }, () => null), null);
  const cyclic: Record<string, unknown> = {};
  cyclic.self = cyclic;
  assert.equal(parseCardSelection('AskForPoxi', { ...payload, extra_data: cyclic }, () => null), null);
  assert.equal(parseCardSelection('AskForCardChosen', {
    card_data: [['$Hand', [1]]], visible_data: { blob: 'x'.repeat(70_000) },
  }, () => null), null);
});

test('card-chosen reply is blocked when cleanup replaces same request ID or disconnects', () => {
  for (const replacement of ['disconnect', 'same-id-request']) {
    let handlers!: SocketHandlers;
    const sent: Uint8Array[] = [];
    let mutate = false;
    const conn = new GameConnection({
      files: new Map(), username: 'test', password: 'test', md5: 'test', uuid: 'test',
      openSocket: (h) => { handlers = h; return { send: (p) => sent.push(p), close: () => {} }; },
      onUi: (command) => assert.notEqual(command, 'AskForCardChosen', 'raw payload must stay private'),
      onRequest: (request) => {
        if (request || !mutate) return;
        mutate = false;
        if (replacement === 'disconnect') handlers.onClose('test disconnect');
        else receive();
      },
    });
    conn.connect();
    conn['setStatus']({ kind: 'online' });
    conn.lua.receive = () => conn['handleLuaUi']('AskForCardChosen', {
      card_data: [['$Hand', [1]]], visible_data: { '1': false }, prompt: 'snatch',
    });
    conn.lua.call = <T>(name: string): T => {
      if (name === '__web_reply_hex') return '01' as T;
      if (name === '__web_reply') conn['sendFromLua']('reply', '', '01');
      return undefined as T;
    };
    const receive = () => handlers.onData(encodePacket({ requestId: 1,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForCardChosen', data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
    }));
    receive();
    const token = conn['pendingRequest']!.cardSelectionPrompt!.groups[0].cards[0].token;
    assert.throws(() => conn.respondToCardSelection(1, []), /Chưa đủ/);
    assert.throws(() => conn.respondToCardSelection(1, [token], true), /không hợp lệ/);
    mutate = true;
    assert.throws(() => conn.respondToCardSelection(1, [token]), /chưa đến máy chủ/);
    assert.equal(sent.length, 0);
    assert.equal(conn['pendingRequest']?.requestId ?? null, replacement === 'disconnect' ? null : 1);
    if (replacement !== 'disconnect') assert.throws(() => conn.respondToCardSelection(1, [token]), /không hợp lệ/);
  }
});
