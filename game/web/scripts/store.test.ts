import assert from 'node:assert/strict';
import { test } from 'node:test';
import { connectionProgress } from '../src/engine/connectionMessages';
import { parseInitialGeneralPrompt } from '../src/engine/generalSelection';
import { initialSnapshot, reduceUiEvent, useGameStore, type GameSnapshot } from '../src/store/gameStore';
import { MAX_BOARD_LOGS, relativeSeatOrder, serverSeatNumbers } from '../src/store/boardState';
import { displayText, localizedGameLog, plainText } from '../src/engine/displayText';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import { deriveRoomReadiness, roomPoolDisabledReason, roomStartDisabledReason } from '../src/store/roomReadiness';

test('temporary IP ban remains actionable and transport closed is not displayed as progress', () => {
  const state = reduceUiEvent(initialSnapshot, 'ErrorDlg', 'you have been temporarily banned!');
  assert.match(state.error!, /tạm chặn IP/);
  assert.match(state.error!, /không gửi thời điểm hết hạn/);
  assert.match(state.error!, /BOT chơi hộ/);
  assert.equal(connectionProgress({ kind: 'closed', reason: 'backend closed' }), '');
});

test('BOT control reflects only authoritative NetStateChanged and rejects malformed state', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [17, 'Bạn', '', true, 0]);
  state = reduceUiEvent(state, 'NetStateChanged', [17, 'trust']);
  assert.equal(state.players[0].netState, 'trust');
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', '', true, 0]);
  assert.equal(state.players[0].netState, 'trust');
  assert.equal(reduceUiEvent(state, 'NetStateChanged', [17, 'forged']), state);
  assert.equal(reduceUiEvent(state, 'NetStateChanged', [17, ['trust']]), state);
  state = reduceUiEvent(state, 'NetStateChanged', [17, 'online']);
  assert.equal(state.players[0].netState, 'online');
});

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
    _observers: [[21, 'Watcher', 'w', false, 0]],
  }]);
  assert.equal(state.roomIsObserver, true);
  assert.equal(state.players.length, 2);
  assert.equal(state.players[0].owner, true);
  assert.deepEqual(state.observers, [{ id: 21, name: 'Watcher', avatar: 'w' }]);
  state = reduceUiEvent(state, 'AddNpc', [-2, 'Bot phụ', 'c', false, 0]);
  assert.equal(state.players.find((p) => p.id === -2)?.name, 'Bot phụ');
  state = reduceUiEvent(state, 'AddPlayer', [-3, 'Bot thường', 'd', false, 0]);
  assert.equal(state.players.filter((p) => p.id < 0).length, 3);
});

test('observer transitions keep observers outside seats and preserve self mode', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [4, 30, {
    roomName: 'Watch', gameMode: 'new_heg_mode', isObserver: true,
    _players: [[17, 'A', 'a', true, 0, true]],
    _observers: [[21, 'Watcher', 'w', false, 0]],
  }]);
  state = reduceUiEvent(state, 'SelfIdentity', 21);
  state = reduceUiEvent(state, 'SwitchToPlayer', [21]);
  assert.equal(state.roomIsObserver, false);
  assert.equal(state.observers.some((observer) => observer.id === 21), false);
  assert.equal(state.players.find((player) => player.id === 21)?.ready, false);

  state = reduceUiEvent(state, 'SwitchToObserver', [21]);
  assert.equal(state.roomIsObserver, true);
  assert.equal(state.players.some((player) => player.id === 21), false);
  assert.deepEqual(state.observers.find((observer) => observer.id === 21), {
    id: 21, name: 'Watcher', avatar: 'w',
  });
  state = reduceUiEvent(state, 'AddObserver', [22, 'Another watcher', 'x', false, 0]);
  assert.equal(state.observers.length, 2);
  state = reduceUiEvent(state, 'RemoveObserver', [22]);
  assert.deepEqual(state.observers.map((observer) => observer.id), [21]);
  assert.equal(reduceUiEvent(state, 'EnterLobby', '').observers.length, 0);
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

test('native GameOver keeps winner names after bot removal and clears on the next game or lobby', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 3 };
  state = reduceUiEvent(state, 'AddPlayer', [3, 'Bạn', '', false, 0]);
  state = reduceUiEvent(state, 'AddPlayer', [-4, 'Bot Quốc Chiến', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  const won = reduceUiEvent(state, 'GameOver', '3'); // payload observed from the live server
  assert.deepEqual(won.result, { outcome: 'win', winners: [{ id: 3, name: 'Bạn' }] });
  const lost = reduceUiEvent(state, 'GameOver', '-4');
  const removed = reduceUiEvent(lost, 'RemovePlayer', [-4]);
  assert.deepEqual(removed.result, { outcome: 'loss', winners: [{ id: -4, name: 'Bot Quốc Chiến' }] });
  assert.deepEqual(reduceUiEvent(state, 'GameOver', '3+-4').result?.winners.map((p) => p.id), [3, -4]);
  for (const event of ['StartGame', 'EnterLobby']) assert.equal(reduceUiEvent(won, event, null).result, null);
  assert.equal(reduceUiEvent(won, 'EnterRoom', [2, 30, { gameMode: 'new_heg_mode' }]).result, null);
});

test('draw, unknown observer and malformed results never invent a winner', () => {
  const state = { ...initialSnapshot, ownId: 3 };
  assert.deepEqual(reduceUiEvent(state, 'GameOver', '').result, { outcome: 'draw', winners: [] });
  for (const payload of [null, {}, '3+', '0', '3x', 'Infinity', '9007199254740992'])
    assert.deepEqual(reduceUiEvent(state, 'GameOver', payload).result, { outcome: 'unknown', winners: [] });
  assert.equal(reduceUiEvent(initialSnapshot, 'GameOver', '3').result?.outcome, 'unknown');
});

test('display text formats native prompts and choices without changing IDs or injecting rich HTML', () => {
  const translations = { revealMain: 'Lật chủ tướng: %arg', m_heg__dianwei: 'Điển Vi',
    '#AskForPeaches': '%src đang hấp hối, hãy dùng %arg Đào',
    slash: '<b>Sát</b>', ':slash': 'Dòng 1<br/>Dòng 2' };
  assert.equal(displayText('revealMain:::m_heg__dianwei', translations), 'Lật chủ tướng: Điển Vi');
  assert.equal(displayText('#AskForPeaches:-4::1', translations, [{ id: -4, name: 'Bot' }]),
    'Bot đang hấp hối, hãy dùng 1 Đào');
  assert.equal(displayText('slash', translations), 'Sát');
  assert.equal(displayText(':slash', translations), 'Dòng 1\nDòng 2');
  assert.equal(displayText('unknown_fixture', translations), 'unknown_fixture');
  assert.equal(displayText('#iron_chain_skill', VI_ADDITIONS), 'Thiết Tỏa Liên Hoàn: Chọn 1-2 người để đổi trạng thái xích (hoặc chọn Trùng Chú để đổi lá)');
  assert.equal(displayText('recast', VI_ADDITIONS), 'Trùng Chú');
  assert.equal(displayText('reveal_skill&', VI_ADDITIONS), 'Mở tướng');
  assert.equal(displayText('#m_ex__fenji-invoke::-10', VI_ADDITIONS, [{ id: 10, name: 'Lữ Bố' }]), 'Phấn Kích: Bạn có muốn cho Lữ Bố rút 2 lá bài và bạn mất 1 máu không?');
  assert.equal(displayText('#m_ex__fenji-invoke::-10', VI_ADDITIONS), 'Phấn Kích: Bạn có muốn cho mục tiêu rút 2 lá bài và bạn mất 1 máu không?');
  assert.equal(localizedGameLog('Nhân vật đã phát động kỹ năng 祸水'), 'Nhân vật đã phát động kỹ năng Họa Thủy');
});

test('waiting-room readiness mirrors native owner/full/non-owner semantics', () => {
  const owner = { id: 17, name: 'Chủ phòng', avatar: '', ready: false, owner: true };
  const guest = { id: 21, name: 'Khách', avatar: '', ready: false, owner: false };
  const readyGuest = { ...guest, ready: true };

  assert.deepEqual(deriveRoomReadiness([owner], 2, 17, false), {
    isFull: false,
    isAllReady: false,
    canReady: false,
    canStart: false,
    canAddBot: true,
    missingReadyCount: 0,
  });
  assert.deepEqual(deriveRoomReadiness([owner, guest], 2, 17, false), {
    isFull: true,
    isAllReady: false,
    canReady: false,
    canStart: false,
    canAddBot: false,
    missingReadyCount: 1,
  });
  assert.deepEqual(deriveRoomReadiness([owner, readyGuest], 2, 17, false), {
    isFull: true,
    isAllReady: true,
    canReady: false,
    canStart: true,
    canAddBot: false,
    missingReadyCount: 0,
  });
  assert.equal(deriveRoomReadiness([owner, readyGuest], 2, 21, false).canReady, true);
  assert.equal(deriveRoomReadiness([owner, readyGuest], 2, 21, true).canReady, false);
  assert.equal(deriveRoomReadiness([owner, readyGuest], 2, 17, true).canStart, false);
  assert.equal(roomStartDisabledReason(deriveRoomReadiness([owner], 2, 17, false), false),
    'Cần đủ người chơi trong tất cả ghế trước khi bắt đầu.');
  assert.equal(roomStartDisabledReason(deriveRoomReadiness([owner, guest], 2, 17, false), false),
    'Còn 1 người chơi chưa sẵn sàng.');
  assert.equal(roomStartDisabledReason(deriveRoomReadiness([owner, readyGuest], 2, 17, false), false), null);
  assert.equal(roomStartDisabledReason(deriveRoomReadiness([owner, readyGuest], 2, 17, true), true),
    'Người quan sát không thể bắt đầu trận.');
  assert.equal(roomPoolDisabledReason(null, 4), 'Không thể kiểm tra bể tướng và bể bài từ Lua.');
  assert.equal(roomPoolDisabledReason({ generals: 19, cards: 16 }, 4),
    'Chưa thể tạo phòng: thiếu tướng (19/20).');
  assert.equal(roomPoolDisabledReason({ generals: 20, cards: 15 }, 4),
    'Chưa thể tạo phòng: thiếu bài (15/16).');
  assert.equal(roomPoolDisabledReason({ generals: 20, cards: 16 }, 4), null);
});

test('upstream Hegemony translations preserve distinct variants and interpolate all verified prompts', () => {
  assert.equal(VI_ADDITIONS['liulongcanjia'], VI_ADDITIONS['mobile__liulongcanjia']);
  assert.match(VI_ADDITIONS[':liulongcanjia'], /\+1/);
  assert.match(VI_ADDITIONS[':liulongcanjia'], /−1/);
  assert.match(VI_ADDITIONS[':mobile__liulongcanjia'], /−3/);
  assert.doesNotMatch(VI_ADDITIONS[':mobile__liulongcanjia'], /\+1/);
  assert.equal(displayText('#part_ways-give::17', VI_ADDITIONS, [{ id: 17, name: 'Đồng đội' }]),
    'Hãy giao cho Đồng đội 3 lá bài.');
  assert.equal(displayText('#hs__shuangxiong:::red', VI_ADDITIONS),
    'Song Hùng: bạn có thể dùng 1 lá trên tay màu Đỏ như Quyết Đấu.');
  assert.match(displayText('#hs__shuangxiong-discard:17', VI_ADDITIONS, [{ id: 17, name: 'Đồng đội' }]), /Đồng đội/);
  assert.match(VI_ADDITIONS['#vanguard_skill&'], /đủ 4 lá/);
  assert.match(VI_ADDITIONS['#burning_camps_skill'], /người chơi kế tiếp.*cùng đội hình/);
  assert.match(VI_ADDITIONS['#EnterBattleRoyalMode'], /Sát hay Thiểm/);
  assert.match(VI_ADDITIONS['#EnterNewBattleRoyalMode'], /như Rượu/);
  for (const key of ['#ChooseHegInitialKingdom', '#HegPrepareConvertLord', '#WildChooseKingdom']) {
    assert.notEqual(displayText(key, VI_ADDITIONS), key);
  }
});

test('UI-01 live C++ audit: battle events, Chinese cards, English turns and skill identifiers are localized', () => {
  assert.equal(localizedGameLog('Tướng ẩn/Mi Trúc (bạn) đã phát động kỹ năng〖巨贾〗'),
    'Tướng ẩn / Mi Trúc (bạn) đã phát động kỹ năng〖Cự Cổ〗');
  assert.equal(localizedGameLog('巨贾 ngoài nhãn kỹ năng'), '巨贾 ngoài nhãn kỹ năng');
  assert.match(VI_ADDITIONS[':ofl_heg__jugu'], /khi lật tướng.*rút X.*giới hạn.*tăng X.*máu tối đa/);
  assert.match(VI_ADDITIONS[':ofl_heg__ziyuan'], /một lần.*tổng điểm bằng 13.*người chơi khác cùng thế lực.*hồi 1 máu/);
  assert.equal(VI_ADDITIONS['#TargetCancelled'], 'Mục tiêu %to đã bị hủy khỏi lá %arg do %from sử dụng.');
  assert.equal(VI_ADDITIONS['#new_battle_royal_event&'], 'Quyết chiến');
  assert.match(VI_ADDITIONS[':battle_royal_fuli'], /rút bài.*bỏ qua.*2 lá Kỳ Trân/);
  assert.match(VI_ADDITIONS[':battle_royal_shengzheweiwang'], /đến hết trận/);
  assert.match(VI_ADDITIONS[':battle_royal_bujinzetui'], /chưa gây sát thương/);
  assert.match(VI_ADDITIONS[':battle_royal_huoqi'], /tăng thêm 1/);
  assert.match(VI_ADDITIONS[':battle_royal_jili'], /không bị giới hạn/);
  assert.equal(localizedGameLog('本轮事件：: 赋礼'), 'Sự kiện vòng này: Phú Lễ');
  assert.equal(localizedGameLog('本轮事件为：祸起：本轮内：所有角色受到的伤害+1。'),
    'Sự kiện vòng này: Họa Khởi. Trong vòng này, sát thương mọi nhân vật phải chịu tăng thêm 1.');
  assert.equal(localizedGameLog('本轮事件为：落石：翻开此牌时，所有确定势力的角色依次变更副将。'),
    'Sự kiện vòng này: Lạc Thạch. Khi lật lá sự kiện này, tất cả nhân vật đã xác định thế lực lần lượt đổi phó tướng.');
  assert.equal(localizedGameLog('-------------- 2 th Round Start --------------'), 'Bắt đầu vòng 2');
  assert.equal(localizedGameLog('-------#1(you)\'s Turn Start -------'), 'Bắt đầu lượt của Ghế 1 (bạn)');
  assert.equal(localizedGameLog('------- Lý Phong/Trương Phi\'s Turn End -------'), 'Kết thúc lượt của Lý Phong / Trương Phi');
  assert.equal(localizedGameLog('Sắc Lệnh[♣3] is removed from the game'), 'Sắc Lệnh[♣3] bị loại khỏi trận.');
  assert.equal(localizedGameLog('Lý Phong đã sử dụng 鹦鹉杯[♥9], 咄咄逼人[♣K], Triblade[♦Q]'),
    'Lý Phong đã sử dụng Anh Vũ Bôi[♥9], Đốt Đốt Bức Nhân[♣K], Tam Tiêm Lưỡng Nhận Đao[♦Q]');
  assert.equal(localizedGameLog('Đã phát động kỹ năng〖#new_battle_royal_event&〗 và hồi 1 máu (酒)'),
    'Đã phát động kỹ năng〖Quyết chiến〗 và hồi 1 máu (Tửu)');
  assert.equal(localizedGameLog('Chúc Dung/Lý Vĩ (bạn) đã sử dụng 图穷匕见[♣2] nhắm vào Hoắc Tuấn/Mã Tắc'),
    'Chúc Dung / Lý Vĩ (bạn) đã sử dụng Đồ Cùng Chủy Hiện[♣2] nhắm vào Hoắc Tuấn / Mã Tắc');
  assert.equal(localizedGameLog('Tướng ẩn/Mã Tắc đã bỏ 巧取豪夺[♥A] và trang bị 九州鼎[♥K]'),
    'Tướng ẩn / Mã Tắc đã bỏ Xảo Thủ Hào Đoạt[♥A] và trang bị Cửu Châu Đỉnh[♥K]');
  assert.equal(localizedGameLog('Hoắc Tuấn/Mã Tắc 即将对 Chúc Dung/Lý Vĩ (bạn) 造成的 1 点 Thường 伤害变为 2 点'),
    'Sát thương Thường do Hoắc Tuấn / Mã Tắc gây ra cho Chúc Dung / Lý Vĩ (bạn) thay đổi từ 1 thành 2 điểm.');
  assert.equal(localizedGameLog('Thông báo khác: 即将对 nhân vật'), 'Thông báo khác: 即将对 nhân vật');
  assert.match(VI_ADDITIONS[':nine_tripod_cauldrons'], /4 lá Kỳ Trân/);
  assert.equal(localizedGameLog('Tào Thực/Tướng ẩn (bạn) 观看了 Tướng ẩn/Thành Tế 的 chủ tướng Nhạc Tiến'),
    'Tào Thực / Tướng ẩn (bạn) đã xem chủ tướng của Tướng ẩn / Thành Tế: Nhạc Tiến.');
  assert.equal(localizedGameLog('Tào Thực/Tướng ẩn (bạn) 观看了 Tướng ẩn/Thành Tế 的 chủ tướng'),
    'Tào Thực / Tướng ẩn (bạn) đã xem chủ tướng của Tướng ẩn / Thành Tế.');
  assert.equal(localizedGameLog('Vương Duyệt/Tướng ẩn 使用的 Hỏa Sát[♥4] 取消了目标 Tướng ẩn/Mã Đại (bạn)'),
    'Mục tiêu Tướng ẩn / Mã Đại (bạn) đã bị hủy khỏi lá Hỏa Sát[♥4] do Vương Duyệt / Tướng ẩn sử dụng.');
  assert.equal(localizedGameLog('Vương Duyệt/Lưu Phu Nhân 使用的 Hỏa Sát[♦4] 取消了目标 Phùng Tập/Mã Đại (bạn)'),
    'Mục tiêu Phùng Tập / Mã Đại (bạn) đã bị hủy khỏi lá Hỏa Sát[♦4] do Vương Duyệt / Lưu Phu Nhân sử dụng.');
  assert.equal(localizedGameLog('Thử nghiệm: 使用的 Hỏa Sát 取消了目标'),
    'Thử nghiệm: 使用的 Hỏa Sát 取消了目标', 'Only rewrite the exact upstream log shape');
  assert.equal(localizedGameLog('Nhạc Tiến đã sử dụng 狗尾续貂[♦2], Tào Thực đã rút 火浣衣[♦Q]'),
    'Nhạc Tiến đã sử dụng Cẩu Vĩ Tục Điêu[♦2], Tào Thực đã rút Hỏa Hoán Y[♦Q]');
  assert.match(VI_ADDITIONS[':amiantus_robe'], /sát thương có thuộc tính/);
  assert.equal(localizedGameLog('Nhật ký &#34;&lt;img src=x onerror=alert(1)&gt;'),
    'Nhật ký "<img src=x onerror=alert(1)>');
});

test('UI-01 nine-variations equipment descriptions and prompts match pinned upstream rules', () => {
  assert.match(VI_ADDITIONS[':rob__jink'], /vô hiệu hóa Sát.*lấy một lá Kỳ Trân/);
  assert.match(VI_ADDITIONS[':yangsui_spear'], /tầm đánh 3.*1 sát thương Hỏa không có nguồn/);
  assert.match(VI_ADDITIONS[':white_kylin'], /\+2.*sát thương Lôi.*máu nhiều hơn bạn/);
  assert.match(VI_ADDITIONS[':tianlu'], /−3.*Quân chủ cùng thế lực/);
  assert.match(VI_ADDITIONS[':dunjia_book'], /tối đa hai lần.*đổi phó tướng/);
  assert.match(VI_ADDITIONS[':serpent_slayer_sword'], /tầm đánh 2.*hồi 1 máu.*Dã tâm gia/);
  assert.match(VI_ADDITIONS[':rare_treasure'], /Trảm Xà Kiếm.*Cửu Châu Đỉnh/);
  assert.equal(displayText('#rare_treasure-prey::17', VI_ADDITIONS, [{ id: 17, name: 'Đồng đội' }]),
    'Bạn có muốn lấy một lá Kỳ Trân trong khu trang bị của Đồng đội không?');
  for (const key of ['rob__jink', 'yangsui_spear', 'white_kylin', 'tianlu', 'dunjia_book']) {
    assert.ok(VI_ADDITIONS[`:${key}`]);
    assert.ok(VI_ADDITIONS[`#${key}_skill`] || VI_ADDITIONS[`${key}_skill&`]);
  }
});

test('upstream markup and decimal/hex entities become inert text without decoding markup into HTML', () => {
  assert.equal(plainText('<font color="red"><b>Song Hùng</b></font><br/>Đỏ &#34; &#x4E2D; &#39;'),
    'Song Hùng\nĐỏ " 中 \'');
  assert.equal(plainText('&lt;img src=x onerror=alert(1)&gt;'), '<img src=x onerror=alert(1)>');
  assert.equal(plainText('&#x110000; &#xD800; &#0;'), '&#x110000; &#xD800; &#0;');
  assert.equal(plainText('&amp;lt;script&amp;gt;'), '&lt;script&gt;');
  assert.equal(displayText('raw', { raw: '<b>&#x4E2D;&#34;&lt;script&gt;</b>' }), '中"<script>');
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

test('skill invoke accepts optional prompts and numeric-key Lua bridge records', () => {
  let state = reduceUiEvent(initialSnapshot, 'AskForSkillInvoke', ['luoshen', null]);
  assert.deepEqual(state.skillInvoke, { skill: 'luoshen', prompt: '' });
  state = reduceUiEvent(state, 'AskForSkillInvoke', { '1': 'ex__fankui', '2': '#ex__fankui-invoke::9' });
  assert.deepEqual(state.skillInvoke, { skill: 'ex__fankui', prompt: '#ex__fankui-invoke::9' });
  assert.equal(reduceUiEvent(state, 'AskForSkillInvoke', { prompt: 'broken' }).skillInvoke?.skill, 'ex__fankui');
});

test('Hegemony fake trigger skills stay private and survive damage until prelight confirmation', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__yiji', true]);
  assert.deepEqual(state.fakeSkills, [{ name: 'hs__yiji', prelighted: false, enabled: true }]);

  // A two-field AddSkill is a regular local dashboard entry. It is visible,
  // but remains disabled until the current Lua request creates SkillButton.
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__active']);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__active' }]);
  assert.equal(reduceUiEvent(state, 'AddSkill', [-1, 'hs__opponent-active']), state);

  // Fake-skill events for another seat must never expose that seat's hidden
  // trigger to this player's React dashboard.
  assert.equal(reduceUiEvent(state, 'AddSkill', [-1, 'hs__fankui', true]), state);

  // Taking damage changes public board state, but does not remove the local
  // prelight control. The server can therefore ask for Yiji immediately
  // after the damage event and reveal the general by skill name.
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'hp', 3]);
  assert.equal(state.fakeSkills[0].name, 'hs__yiji');
  state = reduceUiEvent(state, 'PrelightSkill', ['hs__yiji', true]);
  assert.equal(state.fakeSkills[0].prelighted, true);
  assert.equal(reduceUiEvent(state, 'PrelightSkill', ['unknown_skill', true]), state);

  // The native reconnect marker arrives after its fresh dashboard snapshot;
  // it must not erase the reconstructed projection.
  state = reduceUiEvent(state, 'Reconnect', null);
  assert.deepEqual(state.fakeSkills, [{ name: 'hs__yiji', prelighted: true, enabled: true }]);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__active' }]);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__yiji', true]);
  state = reduceUiEvent(state, 'LoseSkill', [17, 'hs__yiji', true]);
  assert.deepEqual(state.fakeSkills, []);

  // hide/transform/swap may attach the same fake skill again while native
  // Player:prelighted_skills still retains the previous choice. The server
  // now emits AddSkill(fake) followed by PrelightSkill=true; React must show
  // the restored state without requiring a second user click.
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__yiji', true]);
  state = reduceUiEvent(state, 'PrelightSkill', ['hs__yiji', true]);
  assert.deepEqual(state.fakeSkills, [{ name: 'hs__yiji', prelighted: true, enabled: true }]);
});

test('Reconnect keeps the native hidden-skill snapshot after room rebuild events', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'AddSkill', [17, 'stale_hidden_skill', true]);

  // This is the order emitted by ClientBase:reconnect/loadRoomSummary before
  // ClientPlayer:sendDataToUI() publishes the current skill dashboard.
  state = reduceUiEvent(state, 'EnterLobby', '');
  state = reduceUiEvent(state, 'EnterRoom', [2, 30, { roomName: 'QC', gameMode: 'new_heg_mode' }]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__yiji', true]);
  state = reduceUiEvent(state, 'PrelightSkill', ['hs__yiji', true]);
  // A fake ActiveSkill/ViewAsSkill is normalized by the host reconnect
  // boundary to the same two-field regular event native Client:addSkill()
  // emits during the live path.
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__zhiheng']);
  state = reduceUiEvent(state, 'Reconnect', '{}');

  assert.deepEqual(state.fakeSkills, [{ name: 'hs__yiji', prelighted: true, enabled: true }]);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__zhiheng' }]);
  assert.equal(state.fakeSkills.some((skill) => skill.name === 'stale_hidden_skill'), false);
});

test('ChangeSelf updates the privacy owner before rebuilding the skill dashboard', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__yiji', true]);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__zhiheng']);
  state = reduceUiEvent(state, 'ChangeSelf', 21);

  assert.equal(state.ownId, 21);
  assert.deepEqual(state.fakeSkills, []);
  assert.deepEqual(state.regularSkills, []);
  assert.equal(reduceUiEvent(state, 'AddSkill', [17, 'hs__leiji', true]), state);
  state = reduceUiEvent(state, 'AddSkill', [21, 'hs__longdan']);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__longdan' }]);
  assert.equal(reduceUiEvent(state, 'ChangeSelf', '21'), state);
});

test('ChangeSelf with the current identity keeps the native initial skill snapshot', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'AddSkill', [17, 'gongqing', true]);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__active']);
  state = reduceUiEvent(state, 'ChangeSelf', 17);

  assert.deepEqual(state.fakeSkills, [{ name: 'gongqing', prelighted: false, enabled: true }]);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__active' }]);
});

test('React preserves the native dual projection when one hidden skill has trigger and active effects', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__dual', true]);
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__dual']);
  assert.deepEqual(state.fakeSkills, [{ name: 'hs__dual', prelighted: false, enabled: true }]);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__dual' }]);

  state = reduceUiEvent(state, 'LoseSkill', [17, 'hs__dual', true]);
  assert.deepEqual(state.fakeSkills, []);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__dual' }]);
  state = reduceUiEvent(state, 'LoseSkill', [17, 'hs__dual']);
  assert.deepEqual(state.regularSkills, []);
});

test('React removes a regular fallback when native loses a delay-trigger fake skill', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  // client.lua currently adds a delay-trigger-only hidden skill as a regular
  // fallback, but its fake LoseSkill path is still tagged true. The reducer
  // must not leave that stale dashboard entry after the general is revealed.
  state = reduceUiEvent(state, 'AddSkill', [17, 'hs__delay-only']);
  assert.deepEqual(state.regularSkills, [{ name: 'hs__delay-only' }]);
  state = reduceUiEvent(state, 'LoseSkill', [17, 'hs__delay-only', true]);
  assert.deepEqual(state.fakeSkills, []);
  assert.deepEqual(state.regularSkills, []);
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

test('absolute seat labels stay aligned with ArrangeSeats after visual rotation', () => {
  const seats = [22, -1, 17, 21];
  const labels = serverSeatNumbers(seats, [17, -1, 21, 22]);
  assert.deepEqual([...labels.entries()], [[22, 1], [-1, 2], [17, 3], [21, 4]]);
  assert.deepEqual(relativeSeatOrder(seats, [17, -1, 21, 22], 17), [21, 22, -1, 17]);
  assert.equal(labels.get(17), 3, 'self remains server seat 3 even when rendered at the bottom');
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

test('Self snapshot rejects other seats and equipment strips extra data; negative HP is retained', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  for (const id of [17, -1]) state = reduceUiEvent(state, 'AddPlayer', [id, 'Player', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  const before = state.board;
  for (const data of [[-1, 'caocao', 'liubei'], [17, ['caocao'], 'liubei'], [99, 'caocao', 'liubei']])
    assert.equal(reduceUiEvent(state, 'SelfGenerals', data).board, before);
  state = reduceUiEvent(state, 'SelfGenerals', [17, 'caocao', 'liubei']);
  assert.equal(state.board.player[17].selfGeneral, 'caocao');
  assert.equal(state.board.player[17].general, null);
  state = reduceUiEvent(state, 'EquipmentUpdate', [-1, [{ name: 'spear', suit: 1, number: 12, id: 42, private: 'secret' }]]);
  assert.deepEqual(state.board.player[-1].equipment, [{ name: 'spear', suit: 1, number: 12 }]);
  for (const hp of [0, -1, -3]) {
    state = reduceUiEvent(state, 'PropertyUpdate', [17, 'hp', hp]);
    assert.equal(state.board.player[17].hp, hp);
  }
  assert.equal(reduceUiEvent(state, 'PropertyUpdate', [17, 'maxHp', -1]).board, state.board);
  assert.equal(reduceUiEvent(state, 'PropertyUpdate', [17, 'hp', NaN]).board, state.board);
  for (const property of ['chained', 'faceup'])
    assert.equal(reduceUiEvent(state, 'PropertyUpdate', [17, property, 'true']).board, state.board);
  assert.deepEqual(reduceUiEvent(state, 'EnterLobby', '').board.player, {});
});

test('photo projection keeps native art hints, equipment slots, delayed tricks and status overlays public-only', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  for (const id of [17, -1]) state = reduceUiEvent(state, 'AddPlayer', [id, 'Player', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'ld__bianfuren']);
  state = reduceUiEvent(state, 'SelfGenerals', [17, 'ld__bianfuren', 'm_heg__dianwei', 'hegemony', 'hegemony']);
  assert.equal(state.board.player[17].selfGeneralExtension, 'hegemony');
  assert.equal(state.board.player[17].selfDeputyGeneralExtension, 'hegemony');
  state = reduceUiEvent(state, 'GeneralArtUpdate', [17, 'general', 'ld__bianfuren', 'mobile']);
  assert.equal(state.board.player[17].generalExtension, 'mobile');
  state = reduceUiEvent(state, 'GeneralArtUpdate', [17, 'general', 'other_general', 'mobile']);
  assert.equal(state.board.player[17].generalExtension, 'mobile', 'art updates cannot retarget another general');
  state = reduceUiEvent(state, 'EquipmentUpdate', [-1, [{
    name: 'spear', suit: 1, number: 12, subtype: 'weapon', range: 3,
    extension: 'mobile', picName: 'spear', id: 42, private: 'must-drop',
  }], [{ name: 'indulgence', suit: 2, number: 6, subtype: 'delayed_trick', id: 99 }]]);
  assert.deepEqual(state.board.player[-1].equipment, [{
    name: 'spear', suit: 1, number: 12, subtype: 'weapon', range: 3,
    extension: 'mobile', picName: 'spear',
  }]);
  assert.deepEqual(state.board.player[-1].delayedTricks, [{
    name: 'indulgence', suit: 2, number: 6, subtype: 'delayed_trick',
  }]);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'surrendered', true]);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'drank', 1]);
  assert.equal(state.board.player[17].surrendered, true);
  assert.equal(state.board.player[17].drank, 1);
  assert.equal(reduceUiEvent(state, 'PropertyUpdate', [17, 'drank', 'private']).board, state.board);
  assert.equal(reduceUiEvent(state, 'EquipmentUpdate', [-1, [{ name: 'spear', suit: 'private', number: 12 }]]).board, state.board);
});

test('visible kingdom rejects hidden opponents, accepts public state and clears when hidden again', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  for (const id of [17, -1]) state = reduceUiEvent(state, 'AddPlayer', [id, 'Player', '', false, 0]);
  const before = state.board;
  for (const data of [[-1, 'heg_chu'], [99, 'heg_qin'], [17, 7]])
    assert.equal(reduceUiEvent(state, 'VisibleKingdom', data).board, before);
  state = reduceUiEvent(state, 'VisibleKingdom', [17, 'heg_qin']);
  assert.equal(state.board.player[17].visibleKingdom, 'heg_qin');
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'role_shown', true]);
  state = reduceUiEvent(state, 'VisibleKingdom', [-1, 'heg_chu']);
  assert.equal(state.board.player[-1].visibleKingdom, 'heg_chu');
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'role_shown', false]);
  assert.equal(state.board.player[-1].visibleKingdom, null);
  assert.equal(reduceUiEvent(state, 'VisibleKingdom', [-1, 'heg_chu']).board, state.board);
  state = reduceUiEvent(state, 'EnterLobby', null);
  assert.deepEqual(state.board.player, {});
});

test('Hegemony hidden opponent kingdom is never retained before role reveal', () => {
  let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [2, 30, { roomName: 'QC', gameMode: 'new_heg_mode' }]);
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  state = reduceUiEvent(state, 'AddPlayer', [-1, 'Máy', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);

  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'role_shown', false]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'kingdom', 'wei']);
  assert.equal(state.board.player[-1].kingdom, null);
  state = reduceUiEvent(state, 'VisibleKingdom', [-1, 'wei']);
  assert.equal(state.board.player[-1].visibleKingdom, null);

  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'role_shown', true]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'kingdom', 'wei']);
  assert.equal(state.board.player[-1].kingdom, 'wei');
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'role_shown', false]);
  assert.equal(state.board.player[-1].kingdom, null);
  assert.equal(state.board.player[-1].visibleKingdom, null);
});

test('private SelfGenerals survives reconnect ordering before public roster rebuild', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'SelfGenerals', [17, 'hs__guojia', 'hs__simayi', 'hegemony', 'hegemony']);

  // Reconnect can publish the private self pair before AddPlayer/ArrangeSeats.
  // The event is still safe because the reducer accepts only ownId.
  assert.equal(state.board.player[17].selfGeneral, 'hs__guojia');
  assert.equal(state.board.player[17].selfDeputyGeneral, 'hs__simayi');
  assert.equal(state.board.player[-1], undefined);

  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  assert.equal(state.board.player[17].selfGeneral, 'hs__guojia');
  assert.equal(state.board.player[17].selfDeputyGeneral, 'hs__simayi');
});

test('private self equipment survives reconnect ordering without exposing unknown opponents', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  state = reduceUiEvent(state, 'EquipmentUpdate', [17, [{
    name: 'spear', suit: 1, number: 12, subtype: 'weapon', range: 3, id: 42, private: 'must-drop',
  }], [{ name: 'indulgence', suit: 2, number: 6, subtype: 'delayed_trick', id: 99 }]]);

  // Reconnect can publish the self equipment snapshot before AddPlayer and
  // ArrangeSeats. Only ownId is accepted without a public roster entry.
  assert.deepEqual(state.board.player[17].equipment, [{
    name: 'spear', suit: 1, number: 12, subtype: 'weapon', range: 3,
  }]);
  assert.deepEqual(state.board.player[17].delayedTricks, [{
    name: 'indulgence', suit: 2, number: 6, subtype: 'delayed_trick',
  }]);
  state = reduceUiEvent(state, 'EquipmentUpdate', [22, [{ name: 'spear', suit: 1, number: 12 }]]);
  assert.equal(state.board.player[22], undefined);

  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  assert.deepEqual(state.board.player[17].equipment, [{
    name: 'spear', suit: 1, number: 12, subtype: 'weapon', range: 3,
  }]);
});

test('game logs retain a full match beyond 100 entries and board clears on lifecycle', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [1, 'Player', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'ArrangeSeats', [1]);
  for (let i = 0; i < 104; i++) state = reduceUiEvent(state, 'GameLog', `<b>Log ${i}</b>`);
  assert.equal(state.board.logs.length, 104);
  assert.equal(state.board.logs[0], '<b>Log 0</b>');
  const canceled = reduceUiEvent(state, 'CancelRequest', null);
  assert.deepEqual(canceled.board, state.board, 'request cancellation must not wipe board');
  const over = reduceUiEvent(state, 'GameOver', '1');
  assert.deepEqual(over.board.logs, []);
  assert.deepEqual(over.board.seats, []);
  const lobby = reduceUiEvent(state, 'EnterLobby', '');
  assert.deepEqual(lobby.board.player, {});
  assert.deepEqual(lobby.board.logs, []);
});

test('UI-03 records only valid public log moments with bounded and increasing IDs', () => {
  let state = reduceUiEvent(initialSnapshot, 'StartGame', null);
  for (const bad of ['', 42, null, { text: 'hidden' }, 'x'.repeat(10001)]) {
    assert.equal(reduceUiEvent(state, 'GameLog', bad).board, state.board);
  }
  for (let i = 0; i < 104; i++) {
    state = reduceUiEvent(state, 'GameLog', `<b>Thông báo ${i}</b>`);
  }
  assert.equal(state.board.logs.length, 104);
  assert.equal(state.board.moments.length, 12);
  assert.deepEqual(state.board.moments.map(({ id }) => id), Array.from({ length: 12 }, (_, i) => i + 93));
  assert.deepEqual(state.board.moments[0], { id: 93, kind: 'log', text: '<b>Thông báo 92</b>' });
  assert.deepEqual(state.board.moments.at(-1), { id: 104, kind: 'log', text: '<b>Thông báo 103</b>' });
});

test('public log history uses a generous safety cap instead of a 100-line cap', () => {
  let state = reduceUiEvent(initialSnapshot, 'StartGame', null);
  for (let i = 0; i < MAX_BOARD_LOGS + 17; i++) {
    state = reduceUiEvent(state, 'GameLog', `Thông báo ${i}`);
  }
  assert.equal(state.board.logs.length, MAX_BOARD_LOGS);
  assert.equal(state.board.logs[0], 'Thông báo 17');
  assert.equal(state.board.logs.at(-1), `Thông báo ${MAX_BOARD_LOGS + 16}`);
});

test('UI-03 public HP moments include damage/healing but ignore first and unchanged values', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [-1, 'Máy', '', true, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', 4]);
  assert.deepEqual(state.board.moments, [], 'initial HP is not a change');
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', 4]);
  assert.deepEqual(state.board.moments, []);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', 2]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', 3]);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'hp', -1]);
  assert.deepEqual(state.board.moments, [
    { id: 1, kind: 'hp', playerId: -1, before: 4, after: 2 },
    { id: 2, kind: 'hp', playerId: -1, before: 2, after: 3 },
    { id: 3, kind: 'hp', playerId: -1, before: 3, after: -1 },
  ]);
  assert.equal(reduceUiEvent(state, 'PropertyUpdate', [900, 'hp', 1]).board, state.board);
});

test('UI-03 chain moments record true state changes and ignore initialization', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'chained', false]);
  assert.deepEqual(state.board.moments, []);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'chained', true]);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'chained', true]);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'chained', false]);
  assert.deepEqual(state.board.moments, [
    { id: 1, kind: 'chain', playerId: 17, chained: true },
    { id: 2, kind: 'chain', playerId: 17, chained: false },
  ]);
});

test('UI-03 never records private properties or opponent hidden data and resets per match', () => {
  let state = reduceUiEvent(initialSnapshot, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  state = reduceUiEvent(state, 'AddPlayer', [-1, 'Máy', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'GameLog', 'Thông báo công khai');
  const board = state.board;
  for (const [command, data] of [
    ['PropertyUpdate', [-1, 'handcards', 'private-card-id']],
    ['PropertyUpdate', [-1, 'privateGeneral', 'private-general-id']],
    ['SelfGenerals', [-1, 'private-general-id', 'private-deputy-id']],
    ['SetPlayerMark', [-1, '_private', 'private-mark-value']],
  ] as const) {
    state = reduceUiEvent(state, command, data);
    assert.equal(state.board, board);
  }
  assert.ok(!JSON.stringify(state.board).includes('private-'));
  assert.deepEqual(reduceUiEvent(state, 'CancelRequest', null).board, board);
  for (const event of ['GameOver', 'EnterLobby', 'StartGame']) {
    const reset = reduceUiEvent(state, event, event === 'GameOver' ? '17' : null);
    assert.deepEqual(reset.board.moments, [], `${event} must clear moments`);
    assert.deepEqual(reset.board.logs, [], `${event} must clear logs`);
    assert.deepEqual(reset.board.player, {}, `${event} must clear old player state`);
  }
});


test('GameOver retains public final stats and the last log, excludes private fields and clears on lobby', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Bạn', '', false, 0]);
  state = reduceUiEvent(state, 'AddPlayer', [-1, 'Đối thủ', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  for (const id of [17, -1]) {
    state = reduceUiEvent(state, 'PropertyUpdate', [id, 'hp', 1]);
    state = reduceUiEvent(state, 'PropertyUpdate', [id, 'maxHp', 3]);
    state = reduceUiEvent(state, 'PropertyUpdate', [id, 'handcardNum', id === 17 ? 3 : 1]);
  }
  state = reduceUiEvent(state, 'SelfGenerals', [17, 'private-main', 'private-deputy']);
  state = reduceUiEvent(state, 'PropertyUpdate', [-1, 'handcards', [101, 102]]);
  state = reduceUiEvent(state, 'GameLog', 'Kết quả cuối: Di Kế giữ hai lá, Phản Quỹ lấy một lá.');
  const over = reduceUiEvent(state, 'GameOver', '');
  assert.equal(over.result?.outcome, 'draw');
  assert.deepEqual(over.result?.summary?.logs, ['Kết quả cuối: Di Kế giữ hai lá, Phản Quỹ lấy một lá.']);
  assert.deepEqual(over.result?.summary?.players.map((p) => [p.hp, p.maxHp, p.handcardNum]), [[1, 3, 3], [1, 3, 1]]);
  assert.equal(JSON.stringify(over.result).includes('private-'), false);
  assert.equal(JSON.stringify(over.result).includes('handcards'), false);
  assert.deepEqual(over.board.logs, []);
  assert.equal(reduceUiEvent(over, 'EnterLobby', null).result, null);
});

test('damage prevention and reshuffle logs are localized in Vietnamese', () => {
  const log1 = '由于 Thiên Hương，Tào Phi/Hạ Hầu Đôn 即将对 Tiểu Kiều/Tướng ẩn (bạn) 造成的 1 点 Hỏa 伤害被防止了';
  assert.equal(
    localizedGameLog(log1),
    'Do Thiên Hương, 1 điểm sát thương Hỏa do Tào Phi / Hạ Hầu Đôn sắp gây ra cho Tiểu Kiều / Tướng ẩn (bạn) đã được ngăn chặn.',
  );

  const log2 = '由于 八卦阵，Enemy 即将受到的 2 点 雷 伤害被防止了';
  assert.equal(
    localizedGameLog(log2),
    'Do 八卦阵, 2 điểm sát thương 雷 mà Enemy sắp phải chịu đã được ngăn chặn.',
  );

  const log3 = '已重新洗牌，牌堆现有 91 张牌';
  assert.equal(localizedGameLog(log3), 'Đã xáo lại chồng bài, chồng bài hiện có 91 lá bài.');
});

test('card skill keys and prompts resolve to Vietnamese without leaking code tokens', () => {
  assert.equal(displayText('amazing_grace_skill', VI_ADDITIONS), 'Ngũ Cốc Phong Đăng');
  assert.match(displayText('#amazing_grace_skill', VI_ADDITIONS), /Lật ra số lá trên đỉnh chồng bài rút/);
  assert.equal(displayText('m_ex__amazing_grace_skill', VI_ADDITIONS), 'Ngũ Cốc Phong Đăng');
  assert.equal(displayText('god_salvation_skill', VI_ADDITIONS), 'Đào Viên Kết Nghĩa');
  assert.equal(displayText('recast', VI_ADDITIONS), 'Trùng Chú');
  assert.equal(displayText('#iron_chain_skill', VI_ADDITIONS), 'Thiết Tỏa Liên Hoàn: Chọn 1-2 người để đổi trạng thái xích (hoặc chọn Trùng Chú để đổi lá)');
  assert.equal(displayText('#m_ex__fenji-invoke::-10', VI_ADDITIONS), 'Phấn Kích: Bạn có muốn cho mục tiêu rút 2 lá bài và bạn mất 1 máu không?');
  assert.equal(displayText('#unlisted_skill-invoke::-10', VI_ADDITIONS), 'unlisted_skill: Bạn có muốn kích hoạt lên mục tiêu không?');
});
