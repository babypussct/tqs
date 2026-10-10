import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseInitialGeneralPrompt } from '../src/engine/generalSelection';
import { initialSnapshot, reduceUiEvent, useGameStore } from '../src/store/gameStore';
import { relativeSeatOrder } from '../src/store/boardState';

const generalDialog = (overrides: Record<string, unknown> = {}) => ({
  component: { name: 'ChooseInitialGeneralBox', model: {
    name: 'ChooseInitialGeneralModel', prop: {
      hegemony: true, choiceNum: 2,
      generals: ['caocao', 'xiahoudun', 'liubei'], enabledKingdoms: ['wei', 'shu'],
      ...overrides,
    },
  } },
});

test('only a valid two-general Hegemony dialog becomes a selectable prompt', () => {
  assert.deepEqual(parseInitialGeneralPrompt(generalDialog()), {
    generals: ['caocao', 'xiahoudun', 'liubei'], choiceNum: 2,
    enabledKingdoms: ['wei', 'shu'],
  });
  assert.equal(parseInitialGeneralPrompt({ component: { name: 'OtherDialog' } }), null);
  assert.equal(parseInitialGeneralPrompt({ ...generalDialog(), component: { name: 'OtherDialog' } }), null);
  assert.equal(parseInitialGeneralPrompt({ component: { name: 'ChooseInitialGeneralBox', model: {
    name: 'OtherModel', prop: generalDialog().component.model.prop,
  } } }), null);
  for (const prop of [
    { hegemony: false }, { choiceNum: 1 }, { choiceNum: '2' },
    { generals: [] }, { generals: ['a', 'a'] }, { generals: ['a', 'b,c'] },
    { generals: ['a', null] }, { generals: Array.from({ length: 1025 }, (_, i) => `g${i}`) },
    { enabledKingdoms: [] }, { enabledKingdoms: ['wei', 'wei'] },
    { enabledKingdoms: ['wei,shu'] }, { enabledKingdoms: [null] },
  ]) {
    assert.equal(parseInitialGeneralPrompt(generalDialog(prop)), null,
      `must reject malformed properties: ${JSON.stringify(prop)}`);
  }
  assert.equal(parseInitialGeneralPrompt(null), null);
  assert.equal(parseInitialGeneralPrompt(generalDialog({
    generals: Array.from({ length: 201 }, (_, i) => `g${i}`),
  }))?.generals.length, 201, 'valid large server-generated choices remain selectable');
});

test('Hegemony prompt lifecycle clears on replacement, cancellation, game and lobby changes', () => {
  const prompt = generalDialog();
  let state = reduceUiEvent(initialSnapshot, 'CustomDialog', prompt);
  assert.deepEqual(state.initialGeneral?.generals, ['caocao', 'xiahoudun', 'liubei']);
  state = reduceUiEvent(state, 'CustomDialog', { component: { name: 'OtherDialog' } });
  assert.equal(state.initialGeneral, null);
  state = reduceUiEvent(state, 'CustomDialog', prompt);
  for (const event of ['CancelRequest', 'GameOver', 'EnterLobby', 'StartGame']) {
    const next = reduceUiEvent(state, event, null);
    assert.equal(next.initialGeneral, null, `${event} must clear stale choices`);
    assert.equal(next.pendingRequest, null);
    state = reduceUiEvent(next, 'CustomDialog', prompt);
  }
});

test('UpdateRoomList preserves the seven FreeKill server fields', () => {
  const state = reduceUiEvent(initialSnapshot, 'UpdateRoomList', [
    [7, 'Quốc Chiến', 'new_heg_mode', 2, 4, false, false],
    [8, 'Private', 'aaa_role_mode', 3, 6, true, true],
    ['bad', 'broken'],
  ]);
  assert.deepEqual(state.rooms, [
    { id: 7, name: 'Quốc Chiến', mode: 'new_heg_mode', players: 2, capacity: 4, hasPassword: false, outdated: false },
    { id: 8, name: 'Private', mode: 'aaa_role_mode', players: 3, capacity: 6, hasPassword: true, outdated: true },
  ]);
});

test('new owner receives AddPlayer before EnterRoom and then RoomOwner', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterLobby', null);
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', 'avatar', false, 0]);
  state = reduceUiEvent(state, 'EnterRoom', [4, 30, { roomName: 'QC', gameMode: 'new_heg_mode' }]);
  state = reduceUiEvent(state, 'RoomOwner', [17]);
  assert.equal(state.phase, 'room');
  assert.equal(state.capacity, 4);
  assert.deepEqual(state.players, [{ id: 17, name: 'Bạn', avatar: 'avatar', ready: false, owner: true }]);
  state = reduceUiEvent(state, 'ReadyChanged', [17, true]);
  assert.equal(state.players[0].ready, true);
});

test('joining an existing room receives other players after EnterRoom', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [4, 30, { roomName: 'QC', gameMode: 'new_heg_mode' }]);
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', 'a', false, 0]);
  state = reduceUiEvent(state, 'AddPlayer', [21, 'Người khác', 'b', true, 0]);
  state = reduceUiEvent(state, 'RoomOwner', [21]);
  state = reduceUiEvent(state, 'AddPlayer', [21, 'Người khác', 'b', true, 0]);
  assert.deepEqual(state.players.map((p) => p.id), [17, 21]);
  assert.equal(state.players.find((p) => p.id === 21)?.ready, true);
  assert.equal(state.players.find((p) => p.id === 21)?.owner, true,
    'repeated AddPlayer must preserve the existing room owner');
  state = reduceUiEvent(state, 'RemovePlayer', [21]);
  assert.deepEqual(state.players.map((p) => p.id), [17]);
});

test('observer room summaries and both bot events render occupants', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [4, 30, {
    roomName: 'Watch', gameMode: 'new_heg_mode', isObserver: true,
    _players: [[17, 'A', 'a', true, 0, true], [-1, 'Bot', 'b', false, 0, false]],
  }]);
  assert.equal(state.players.length, 2);
  assert.equal(state.players[0].owner, true);
  state = reduceUiEvent(state, 'AddNpc', [-2, 'Bot phụ', 'c', false, 0]);
  assert.equal(state.players.find((p) => p.id === -2)?.name, 'Bot phụ');
  state = reduceUiEvent(state, 'AddPlayer', [-3, 'Bot thường', 'd', false, 0]);
  assert.equal(state.players.filter((p) => p.id < 0).length, 3);
});

test('StartGame, GameOver, EnterLobby and reset clear lifecycle state', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [17, 'Bạn', '', true, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  assert.equal(state.phase, 'playing');
  state = reduceUiEvent(state, 'GameOver', '17');
  assert.equal(state.phase, 'room');
  state = reduceUiEvent(state, 'EnterLobby', '');
  assert.equal(state.phase, 'lobby');
  assert.deepEqual(state.players, []);
  useGameStore.getState().update({ ...state, ownId: 17 });
  useGameStore.getState().reset();
  assert.equal(useGameStore.getState().ownId, null);
  assert.equal(useGameStore.getState().phase, 'boot');
});

test('skill invoke prompt is visible during request and cleared by CancelRequest', () => {
  const initial = reduceUiEvent(initialSnapshot, 'StartGame', null);
  const prompt = reduceUiEvent(initial, 'AskForSkillInvoke', ['jizhi', 'Có dùng kỹ năng?']);
  assert.equal(prompt.phase, 'playing');
  assert.deepEqual(prompt.skillInvoke, { skill: 'jizhi', prompt: 'Có dùng kỹ năng?' });
  const cleared = reduceUiEvent(prompt, 'CancelRequest', null);
  assert.equal(cleared.skillInvoke, null);
  assert.equal(cleared.pendingRequest, null);
});

test('board follows Lua seat order, preserves relative self position, and updates public stats', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [4, 30, { roomName: 'QC', gameMode: 'new_heg_mode' }]);
  for (const id of [17, -1, 21, 22]) state = reduceUiEvent(state, 'AddNpc', [id, `P${id}`, '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', '');
  state = reduceUiEvent(state, 'ArrangeSeats', [22, -1, 17, 21]);
  assert.deepEqual(relativeSeatOrder(state.board.seats, state.players.map((p) => p.id), 17), [21, 22, -1, 17]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'maxHp', 4]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', 3]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'shield', 1]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'phase', 'Play']);
  assert.deepEqual([state.board.player[-1].hp, state.board.player[-1].maxHp, state.board.player[-1].shield], [3, 4, 1]);
  assert.equal(state.board.player[-1].phase, 'Play');
  state = reduceUiEvent(state, 'RemovePlayer', [-1]);
  assert.equal(state.board.player[-1], undefined);
  assert.deepEqual(state.board.seats, [22, 17, 21]);
});

test('board ignores private properties and unpublished marks while guarding hidden generals', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [17, 'Me', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'anjiang']);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'deputyGeneral', 'hidden']);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'kingdom', 'wei']);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'role_shown', false]);
  assert.equal(state.board.player[17].general, null);
  assert.equal(state.board.player[17].deputyGeneral, null);
  assert.equal(state.board.player[17].roleShown, false);
  assert.equal(state.board.player[17].kingdom, 'wei');
  const before = state.board;
  for (const input of [
    ['handcards', [51, 55]], ['__heg_general', 'caocao'], ['privateRole', 'wei'],
  ] as const) {
    state = reduceUiEvent(state, 'PropertyUpdate', [17, input[0], input[1]]);
    assert.equal(state.board, before);
  }
  state = reduceUiEvent(state, 'SetPlayerMark', [17, '__secret', 'hidden']);
  assert.equal(state.board, before);
  state = reduceUiEvent(state, 'SetPlayerMark', [17, '@public', 2]);
  state = reduceUiEvent(state, 'SetBanner', ['@round', 3]);
  state = reduceUiEvent(state, 'SetBanner', ['internal_banner', 'private']);
  assert.deepEqual(state.board.player[17].marks, { '@public': 2 });
  assert.deepEqual(state.board.banners, { '@round': 3 });
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'caocao']);
  assert.equal(state.board.player[17].general, 'caocao');
  state = reduceUiEvent(state, 'PropertyUpdate', [1001, 'hp', 4]);
  assert.equal(state.board.player[1001], undefined);
});

test('game logs are bounded and board clears on game/lobby/connection lifecycle', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [1, 'Player', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'ArrangeSeats', [1]);
  for (let i = 0; i < 104; i++) state = reduceUiEvent(state, 'GameLog', `<b>Log ${i}</b>`);
  assert.equal(state.board.logs.length, 100);
  assert.equal(state.board.logs[0], '<b>Log 4</b>');
  const canceled = reduceUiEvent(state, 'CancelRequest', null);
  assert.deepEqual(canceled.board, state.board, 'request cancellation must not wipe board');
  const over = reduceUiEvent(state, 'GameOver', '1');
  assert.deepEqual(over.board.logs, []);
  assert.deepEqual(over.board.seats, []);
  const lobby = reduceUiEvent(state, 'EnterLobby', '');
  assert.deepEqual(lobby.board.player, {});
  assert.deepEqual(lobby.board.logs, []);
});
