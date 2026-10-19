/** Browser-only fixture. Exercises the real React board, Zustand reducer,
 * GameConnection and CBOR transport with a deterministic simulated Lua callback.
 * No server, credentials or actual Lua VM is involved here. */
import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import GameBoardScreen from '../../src/GameBoardScreen';
import App from '../../src/App';
import { GameAdapter } from '../../src/engine/gameAdapter';
import { GameConnection, type SocketHandlers } from '../../src/engine/connection';
import { CLIENT_REPLY, PacketStream, PacketType, encodePacket } from '../../src/engine/packet';
import { emptyBoard } from '../../src/store/boardState';
import { useGameStore } from '../../src/store/gameStore';
import { emptyGameplay, GAMEPLAY_REQUESTS } from '../../src/store/gameplayState';
import './harness.css';

type Scenario = 'choices' | 'widgets' | 'direct-step' | 'direct-complete' |
  'direct-pending' | 'dynamic' | 'lua-error';
type MockSocket = { handlers: SocketHandlers; sent: Uint8Array[]; closed: boolean };
const sockets: MockSocket[] = [];
const actions: unknown[][] = [];
const appActions: string[] = [];
let scenarioSocketStart = 0;
const replyHex = '44646f6e65'; // CBOR byte string "done", as emitted by Lua.
let scenario: Scenario = 'choices';
let finishes = 0;
let okClicks = 0;
let nextId = 100;

const conn = new GameConnection({
  files: new Map(), username: 'local-fixture', password: '', md5: '', uuid: '',
  openSocket: (handlers) => {
    const socket = { handlers, sent: [] as Uint8Array[], closed: false };
    sockets.push(socket);
    return { send: (bytes) => socket.sent.push(bytes), close: () => { socket.closed = true; } };
  },
  onUi: (command, data) => useGameStore.getState().dispatch(command, data),
  onRequest: (request) => useGameStore.getState().update({
    pendingRequest: request,
    ...(!request ? { gameplay: emptyGameplay(), skillInvoke: null, initialGeneral: null } : {}),
  }),
  onStatus: (connection) => useGameStore.getState().update({ connection }),
});

function emit(command: string, value: unknown) {
  conn['handleLuaUi'](command, value);
}

const dialogSpec = { type: 'optionbox', options: ['first'], direct_send: true };
function item(type: string, data: Record<string, unknown>) { return { type, data }; }

function initialScene(mode: Scenario) {
  if (mode === 'choices' || mode === 'lua-error') {
    return { _type: 'RoomScene', _prompt: 'Chọn lá bài và mục tiêu', _new: [
      item('CardItem', { id: 7, enabled: true, selected: false, card: { name: 'slash' } }),
      item('Photo', { id: 2, enabled: true, selected: false }),
      item('SkillButton', { id: 'longdan', enabled: true, selected: false }),
      item('SpecialSkills', { id: 'special', enabled: true, skills: ['_normal_use', 'convert'] }),
      ...['OK', 'Cancel', 'End'].map((id) => item('Button', { id, enabled: true })),
    ] };
  }
  if (mode === 'widgets') {
    return { _type: 'RoomScene', _prompt: 'Tương tác widget', _new: [
      item('Interaction', { id: 'combo', enabled: true, spec: { type: 'combo', choices: ['a', 'b'] } }),
      item('Interaction', { id: 'spin', enabled: true, spec: { type: 'spin', from: 1, to: 5 } }),
      item('Interaction', { id: 'checkbox', enabled: true, spec: { type: 'checkbox', choices: ['x', 'y'] } }),
      item('Interaction', { id: 'expand', enabled: true, spec: { type: 'expandItems', ids: [9], card_names: ['sha'] } }),
      item('Interaction', { id: 'option', enabled: true, spec: { type: 'optionbox', options: ['left', 'right'] } }),
    ] };
  }
  if (mode === 'dynamic') {
    return { _type: 'RoomScene', _prompt: 'Lua dynamic', _new: [
      item('Interaction', { id: 'dialog', enabled: true, spec: { type: 'ToBeDecided' },
        refresh_data: { optionBox: { options: ['use'], direct_send: true, cancelable: true },
          expandItems: [{ cid: -7, name: 'virtual', prop: { name: 'Ảo' } }], enabled_ids: [-7] } }),
      item('Button', { id: 'OK', enabled: true }),
    ] };
  }
  return { _type: 'RoomScene', _prompt: 'Bước 1', _new: [
    item('Interaction', { id: 'dialog', enabled: true, spec: dialogSpec, refresh_data: { stable: true } }),
    item('Button', { id: 'OK', enabled: true }),
  ] };
}

function prepareLua() {
  conn.lua.receive = (command) => {
    if (GAMEPLAY_REQUESTS.has(command)) emit('UpdateRequestUI', initialScene(scenario));
  };
  conn.lua.call = <T,>(name: string, ...args: unknown[]): T => {
    if (name === '__web_reply_hex') {
      if (args[0] !== 'done') throw new Error('Invalid simulated Lua reply');
      return replyHex as T;
    }
    if (name === '__web_reply') {
      if (args[0] !== 'done') throw new Error('Invalid simulated Lua send');
      conn['sendFromLua']('reply', '', replyHex);
      return undefined as T;
    }
    if (name === '__web_notify') {
      if (args[0] !== 'PushRequest' || typeof args[1] !== 'string')
        throw new Error('Unexpected simulated native notification');
      const [kind, skillName, prelight] = args[1].split(',');
      if (kind !== 'prelight' || !skillName || !['true', 'false'].includes(prelight))
        throw new Error('Invalid simulated prelight payload');
      actions.push(['PushRequest', args[1]]);
      emit('PrelightSkill', [skillName, prelight === 'true']);
      return undefined as T;
    }
    if (name !== 'UpdateRequestUI') throw new Error(`Unexpected Lua call: ${name}`);
    actions.push(args);
    const [type, id, action, data] = args;
    if (scenario === 'lua-error') throw new Error('Lỗi Lua mô phỏng');
    if (type === 'CardItem' || type === 'Photo' || type === 'SkillButton') {
      emit('UpdateRequestUI', { _type: 'RoomScene', [String(type)]: [
        { id, selected: (data as { selected: boolean }).selected },
      ] });
    }
    if (type === 'Interaction' && action === 'finish') {
      ++finishes;
      if (scenario === 'direct-step' && finishes === 1) {
        // Same interaction ID, identical spec and refresh_data. Only the Lua
        // scene revision reveals that another user choice is required.
        emit('UpdateRequestUI', { _type: 'RoomScene', _prompt: 'Bước 2',
          Interaction: [{ id: 'dialog', enabled: true, spec: dialogSpec, refresh_data: { stable: true } }],
        });
      } else if (scenario === 'direct-complete' || scenario === 'dynamic' ||
                 (scenario === 'direct-step' && finishes === 2)) {
        emit('UpdateRequestUI', { _type: 'RoomScene',
          Interaction: [{ id: 'dialog', enabled: false }],
          Button: [{ id: 'OK', enabled: true }],
        });
      }
    }
    if (type === 'Button') {
      if (id === 'OK') ++okClicks;
      if (scenario !== 'direct-pending' || okClicks > 1) emit('ReplyToServer', 'done');
    }
    return undefined as T;
  };
}

function incoming(id: number, timestamp = Date.now(), timeout = 30, socket = sockets.at(-1)!) {
  socket.handlers.onData(encodePacket({ requestId: id, command: 'PlayCard',
    type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    data: new Uint8Array(), timestamp, timeout }));
}

function begin(mode: Scenario, expired = false) {
  // Preserve old sockets for reconnect checks, but never count packets from
  // previous scenarios as replies to the current request.
  scenarioSocketStart = sockets.length;
  scenario = mode;
  finishes = 0;
  okClicks = 0;
  actions.length = 0;
  useGameStore.getState().reset();
  conn.connect();
  conn['setStatus']({ kind: 'online' });
  useGameStore.getState().update({
    phase: 'playing', roomName: 'E2E cục bộ', ownId: 1,
    players: [
      { id: 1, name: 'Bạn thử nghiệm', avatar: '', ready: true, owner: true },
      { id: 2, name: 'Đối thủ', avatar: '', ready: true, owner: false },
    ],
    board: { ...emptyBoard(), seats: [1, 2] },
  });
  prepareLua();
  incoming(++nextId, expired ? Date.now() - 15_000 : Date.now(), expired ? 1 : 30);
  return nextId;
}

function sentPackets() {
  return sockets.slice(scenarioSocketStart).flatMap((socket) => socket.sent.flatMap((bytes) =>
    new PacketStream().push(bytes).map((packet) => ({
      requestId: packet.requestId, type: packet.type,
      hex: [...packet.data].map((b) => b.toString(16).padStart(2, '0')).join(''),
    }))));
}

// The fixture API simulates server/Lua events; all user interactions are
// performed through the visible React DOM by the external Chrome test runner.
const api = {
  begin,
  emitUiError: (value: unknown) => emit('ErrorDlg', value),
  appActions: () => appActions.slice(),
  finishGame: () => emit('GameOver', '1'),
  seedRoundData: () => {
    emit('ArrangeSeats', [1, 2]);
    emit('GameLog', 'Thông báo ván trước');
    emit('LogEvent', { type: 'Damage', to: 2, damageType: 'fire_damage', damageNum: 1 });
  },
  startNextGame: () => emit('StartGame', ''),
  roundState: () => {
    const state = useGameStore.getState();
    return { phase: state.phase, boardLogs: state.board.logs, nativeVfxEvents: state.nativeVfxEvents };
  },
  replace: () => incoming(++nextId),
  addFakeSkill: () => emit('AddSkill', [1, 'hs__yiji', true]),
  addRegularSkill: () => emit('AddSkill', [1, 'hs__active']),
  seedHorseEquipment: (equipped: boolean) => {
    const horses = equipped ? [
      { name: 'zhuahuangfeidian', subtype: 'defensive_ride', suit: 2, number: 13 },
      { name: 'chitu', subtype: 'offensive_ride', suit: 3, number: 12 },
    ] : [];
    for (const id of [1, 2]) emit('EquipmentUpdate', [id, horses, []]);
  },
  damageSelf: () => emit('PropertyUpdate', [1, 'hp', 3]),
  cancel: () => emit('CancelRequest', null),
  disconnect: () => sockets.at(-1)!.handlers.onClose('Mất kết nối thử nghiệm'),
  reconnectSameId: () => {
    const id = nextId;
    conn.connect();
    conn['setStatus']({ kind: 'online' });
    prepareLua();
    incoming(id);
  },
  oldSocketRequest: () => incoming(++nextId, Date.now(), 30, sockets.at(-2)!),
  attempt: (requestId: number) => {
    try { conn.updateRequestUI(requestId, 'Button', 'OK', 'click', null); return null; }
    catch (error) { return (error as Error).message; }
  },
  attemptSkill: (requestId: number) => {
    try { conn.updateRequestUI(requestId, 'SkillButton', 'hs__active', 'click', { selected: true }); return null; }
    catch (error) { return (error as Error).message; }
  },
  snapshot: () => {
    const state = useGameStore.getState();
    return {
      requestId: state.pendingRequest?.requestId ?? null,
      prompt: state.gameplay.prompt,
      scene: state.gameplay,
      fakeSkills: state.fakeSkills,
      regularSkills: state.regularSkills,
      actions: actions.map((values) => [...values]),
      sent: sentPackets(),
      replyCount: sentPackets().filter((packet) => packet.type === CLIENT_REPLY).length,
      error: state.error,
      status: state.connection.kind,
      socketCount: sockets.length,
    };
  },
};

declare global { interface Window { __tqsE2e: typeof api } }
window.__tqsE2e = api;

function Fixture() {
  const [busy, setBusy] = useState(false);
  const error = useGameStore((s) => s.error);
  const pending = useGameStore((s) => s.pendingRequest);
  const regularSkills = useGameStore((s) => s.regularSkills);
  const run = (action: () => void) => {
    if (busy) return;
    setBusy(true);
    useGameStore.getState().update({ error: null });
    void Promise.resolve().then(action).catch((err: unknown) => {
      useGameStore.getState().update({ error: err instanceof Error ? err.message : String(err) });
    }).finally(() => setBusy(false));
  };
  return <main className="shell shell-playing">
    <h1>TQS browser E2E cục bộ</h1>
    {error && <div className="notice error-notice" role="alert">{error}</div>}
    <GameBoardScreen busy={busy} leave={() => {}}
      regularSkills={regularSkills}
      prelightSkill={(skillName, prelight) => run(() => conn.prelightSkill(skillName, prelight))}
      dispatch={(type, id, action, data) => {
        if (pending) run(() => conn.updateRequestUI(pending.requestId, type, id, action, data));
      }}
      direct={(id, data) => {
        if (pending) run(() => conn.finishDirectInteraction(pending.requestId, id, data));
      }} />
  </main>;
}

const appFixture = new URLSearchParams(location.search).has('app');
if (appFixture) {
  // Exercise the production App's exit guards without an external connection.
  GameAdapter.prototype.boot = async () => { useGameStore.getState().update({ phase: 'login' }); };
  GameAdapter.prototype.disconnect = () => { appActions.push('disconnect'); };
  GameAdapter.prototype.leaveRoom = () => { appActions.push('QuitRoom'); };
  GameAdapter.prototype.toggleTrust = () => { appActions.push('Trust'); };
}
createRoot(document.getElementById('root')!).render(appFixture ? <App /> : <Fixture />);
