import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseChoicePrompt, validChoiceReply } from '../src/engine/choiceSelection';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { PacketType, encodePacket } from '../src/engine/packet';

const payload = [['main', 'deputy'], ['main', 'deputy', 'disabled'], [1, 2], false, 'reveal', 'Choose', false, false];

test('native choice limits reject disabled, duplicate, missing and excess selections', () => {
  const prompt = parseChoicePrompt(payload)!;
  assert.ok(prompt);
  assert.equal(validChoiceReply(prompt, ['main', 'deputy']), true);
  for (const invalid of [[], ['disabled'], ['main', 'main'], ['main', 'deputy', 'disabled'], 'main'])
    assert.equal(validChoiceReply(prompt, invalid), false);
  assert.equal(validChoiceReply({ ...prompt, cancelable: true }, []), true);
  assert.equal(parseChoicePrompt([['a'], ['a'], [2, 1], false, '', '', false, false]), null);
  assert.equal(parseChoicePrompt([['a', 'a'], ['a'], [1, 2], false, '', '', false, false]), null);
  assert.equal(parseChoicePrompt([['a'], ['b'], [1, 1], false, '', '', false, true]), null);
});

test('choice skill and prompt fields are bounded at the dialog boundary', () => {
  assert.equal(parseChoicePrompt([['ok'], ['ok'], [0, 1], false, 'x'.repeat(257), '', false, true]), null);
  assert.equal(parseChoicePrompt([['ok'], ['ok'], [0, 1], false, 'skill', 'x'.repeat(10_001), false, true]), null);
});

test('choice replies cannot send after reentrant cleanup disconnects or replaces a request', () => {
  for (const replacement of ['disconnect', 'same-id-request']) {
    let socketHandlers!: SocketHandlers;
    const sent: Uint8Array[] = [];
    let mutate = false;
    const conn = new GameConnection({
      files: new Map(), username: 'test', password: 'test', md5: 'test', uuid: 'test',
      openSocket: (handlers) => { socketHandlers = handlers; return { send: (p) => sent.push(p), close: () => {} }; },
      onUi: () => {}, onRequest: (request) => {
        if (request || !mutate) return;
        mutate = false;
        if (replacement === 'disconnect') conn.disconnect();
        else receive();
      },
    });
    conn.connect();
    conn['setStatus']({ kind: 'online' });
    conn.lua.receive = () => conn['handleLuaUi']('AskForChoices', payload);
    const receive = () => socketHandlers.onData(encodePacket({
      requestId: 1, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForChoices', data: new Uint8Array(), timeout: 30, timestamp: Date.now(),
    }));
    receive();
    conn.lua.call = <T>(name: string): T => {
      if (name === '__web_reply_hex') return '81446d61696e' as T;
      if (name === '__web_reply') conn['sendFromLua']('reply', '', '81446d61696e');
      return undefined as T;
    };
    mutate = true;
    assert.throws(() => conn.respondToChoices(1, ['main']), /chưa đến máy chủ/);
    assert.equal(sent.length, 0);
    assert.equal(conn['pendingRequest']?.requestId ?? null, replacement === 'disconnect' ? null : 1);
  }
});
