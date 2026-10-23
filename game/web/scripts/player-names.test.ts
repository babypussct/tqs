import assert from 'node:assert/strict';
import { test } from 'node:test';
import { localNameOverrideForTicket, localPlayerDisplayEvent } from '../src/engine/localPlayerName';
import { initialSnapshot, reduceUiEvent } from '../src/store/gameStore';

test('the authenticated display name appears on the local room and game seat', () => {
  let state = reduceUiEvent(initialSnapshot, 'SelfIdentity', 17);
  const own = localPlayerDisplayEvent('AddPlayer', [17, 'tqs_FirebaseUid', 'avatar', false],
    state.ownId, 'Tào Tháo');
  state = reduceUiEvent(state, 'AddPlayer', own);
  state = reduceUiEvent(state, 'AddPlayer',
    localPlayerDisplayEvent('AddPlayer', [23, 'Người khác', '', true], state.ownId, 'Tào Tháo'));
  assert.deepEqual(state.players.map((person) => person.name), ['Tào Tháo', 'Người khác']);
  state = reduceUiEvent(state, 'EnterRoom', localPlayerDisplayEvent('EnterRoom', [4, 30, {
    roomName: 'Quốc Chiến', _players: [[17, 'tqs_FirebaseUid', 'avatar', false, 0, true],
      [23, 'Người khác', 'avatar', true, 0, false]],
  }], state.ownId, 'Tào Tháo'));
  assert.equal(state.players[0].name, 'Tào Tháo');
  assert.equal(state.players[1].name, 'Người khác');
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'GameOver', '17');
  assert.equal(state.result?.winners[0].name, 'Tào Tháo');
});

test('observer and reconnect snapshots use the same identity without modifying others', () => {
  const source = [4, 30, { _observers: [[8, 'tqs_myUid', 'avatar'], [9, 'Other', 'avatar']],
    _players: [[10, 'tqs_someOtherUid', 'avatar']] }];
  const mapped = localPlayerDisplayEvent('EnterRoom', source, 8, 'Hoàng Nguyệt Anh') as typeof source;
  assert.deepEqual((mapped[2] as { _observers: unknown })._observers,
    [[8, 'Hoàng Nguyệt Anh', 'avatar'], [9, 'Other', 'avatar']]);
  assert.deepEqual((mapped[2] as { _players: unknown })._players,
    [[10, 'tqs_someOtherUid', 'avatar']]);
  assert.deepEqual(source[2], { _observers: [[8, 'tqs_myUid', 'avatar'], [9, 'Other', 'avatar']],
    _players: [[10, 'tqs_someOtherUid', 'avatar']] });
  assert.deepEqual(localPlayerDisplayEvent('AddObserver', [8, 'tqs_myUid', 'avatar'], 8, 'Hoàng Nguyệt Anh'),
    [8, 'Hoàng Nguyệt Anh', 'avatar']);
  assert.deepEqual(localPlayerDisplayEvent('AddPlayer', [8, 'raw', 'avatar'], null, 'Alice'),
    [8, 'raw', 'avatar']);
});

test('reconnect preserves the public name in the existing match across ticket updates', () => {
  const nativeName = 'tqs_FirebaseUid';
  const initial = 'Gia Cát Lượng';
  const edited = 'Lưu Bị';

  // A TQS1 connection keeps the same local fallback through a token refresh.
  const legacyOverride = localNameOverrideForTicket('TQS1|expiry|mac', initial);
  assert.equal(legacyOverride, initial);
  assert.deepEqual(localPlayerDisplayEvent('AddPlayer', [17, nativeName], 17, legacyOverride),
    [17, initial]);
  assert.deepEqual(localPlayerDisplayEvent('AddPlayer', [17, nativeName], 17, legacyOverride),
    [17, initial], 'refreshing the API session does not change the existing seat');

  // Under TQS2, the name broadcast by native is authoritative after reconnect.
  const nativeOverride = localNameOverrideForTicket('TQS2|expiry|alias|mac', edited);
  assert.equal(nativeOverride, undefined);
  assert.deepEqual(localPlayerDisplayEvent('AddPlayer', [17, initial], 17, nativeOverride),
    [17, initial], 'native keeps the old ServerPlayer name until the match ends');
});
