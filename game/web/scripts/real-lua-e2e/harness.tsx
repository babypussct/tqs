/** Chrome + actual FreeKill Lua/Wasmoon + production React SkillInvokePanel and
 * GameConnection. Only the local socket/server packets are test fixtures. */
import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import { unzipSync } from 'fflate';
import SkillInvokePanel from '../../src/SkillInvokePanel';
import ChoicePanel from '../../src/ChoicePanel';
import CardSelectionPanel from '../../src/CardSelectionPanel';
import CardsAndChoicePanel from '../../src/CardsAndChoicePanel';
import GameBoardScreen from '../../src/GameBoardScreen';
import InitialGeneralPanel from '../../src/InitialGeneralPanel';
import GameResultPanel from '../../src/GameResultPanel';
import NativeDialogPanel from '../../src/NativeDialogPanel';
import { LobbyScreen, WaitingRoomScreen } from '../../src/App';
import { GameAdapter, type RoomPacks } from '../../src/engine/gameAdapter';
import type { GameSession } from '../../src/gameAuth';
import { VI_ADDITIONS } from '../../src/engine/vietnamese';
import { GameConnection, type SocketHandlers } from '../../src/engine/connection';
import { CLIENT_REPLY, PacketStream, PacketType, encodePacket, encodeTextArray, fromHex, toHex } from '../../src/engine/packet';
import { useGameStore } from '../../src/store/gameStore';
import {
  getQaScenario,
  resolveQaScenario,
  type QaCardDescriptor,
  type QaScenarioId,
} from './qa-scenarios';
import './harness.css';

interface FixtureSocket { handlers: SocketHandlers; sent: Uint8Array[]; closed: boolean }
const sockets: FixtureSocket[] = [];
const uiEvents: string[] = [];
let reconnectUiPayloadBytes = 0;
const luaErrors: string[] = [];
let conn: GameConnection;
let nextId = 200;
let scenarioSocketStart = 0;
let publicKeyPem = '';
let ready = false;
let bootError: string | null = null;
const roomAdapter = new GameAdapter('/gateway');
// Native browser fixtures have no Firebase account. Stub only the SSO refresh;
// the real adapter still validates pools and creates the Lua CBOR packet.
(roomAdapter as unknown as { refreshGameSession: () => Promise<void> }).refreshGameSession = async () => {};

interface FixtureBeginPlayOptions {
  /** Optional explicit pile; used only by the QA scenario director. */
  drawPile?: number[];
  /** An empty list means "do not seed the regular PlayCard hand". */
  initialCards?: number[];
  playCardRequest?: boolean;
}

function currentSocket() {
  const socket = sockets.at(-1);
  if (!socket) throw new Error('Socket fixture not initialized');
  return socket;
}

function serverNotify(command: string, data: Uint8Array) {
  currentSocket().handlers.onData(encodePacket({ requestId: -2,
    type: PacketType.NOTIFICATION | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command, data }));
}

function serverCbor(source: string) {
  return fromHex(conn.lua.eval<string>(`return __host_bin2hex(cbor.encode(${source}))`));
}

function fixtureRequest(
  requestId: number,
  command: string,
  data: Uint8Array,
  timeout = 30,
  timestamp = Date.now(),
  socket = currentSocket(),
) {
  socket.handlers.onData(encodePacket({
    requestId, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command, data, timestamp, timeout,
  }));
}

function setUpSocket() {
  conn.lua.call('__web_init_display_translations', VI_ADDITIONS);
  conn.connect();
  // Upstream Lua processes the real auth/lobby callbacks. No real account,
  // remote network or gateway is involved in this fixture.
  serverNotify('NetworkDelayTest', encodeTextArray([publicKeyPem]).subarray(1));
  serverNotify('Setup', serverCbor("{17, 'browser-test', 'avatar', 1000}"));
  serverNotify('EnterLobby', Uint8Array.of(0xf6));
  if (conn.getStatus().kind !== 'online') throw new Error('Real Lua lobby setup did not complete');
  useGameStore.getState().update({ phase: 'playing', ownId: 17, roomName: 'Lua WASM cục bộ' });
}

function request(id: number, timeout = 30, timestamp = Date.now(), socket = currentSocket()) {
  fixtureRequest(id, 'AskForSkillInvoke', serverCbor("{'web_test_skill', 'Kích hoạt kỹ năng thử?'}"),
    timeout, timestamp, socket);
}

function begin(expired = false) {
  if (!ready) throw new Error(`Lua WASM chưa sẵn sàng: ${bootError ?? 'đang khởi tạo'}`);
  scenarioSocketStart = sockets.length;
  uiEvents.length = 0;
  reconnectUiPayloadBytes = 0;
  luaErrors.length = 0;
  useGameStore.getState().reset();
  setUpSocket();
  const id = ++nextId;
  request(id, expired ? 1 : 30, expired ? Date.now() - 5000 : Date.now());
  return id;
}

function sentPackets() {
  return sockets.slice(scenarioSocketStart).flatMap((socket, offset) => socket.sent.flatMap((bytes) =>
    new PacketStream().push(bytes).map((packet) => ({
      socket: scenarioSocketStart + offset,
      requestId: packet.requestId, command: packet.command, type: packet.type,
      hex: toHex(packet.data),
    }))));
}

const api = {
  get ready() { return ready; },
  get bootError() { return bootError; },
  beginRoomPacks: (disabledPacks: GameSession['poolPolicy']['disabledPacks'] = { generals: [], cards: [] }) => {
    (roomAdapter as unknown as { gameSession: GameSession }).gameSession = {
      uid: 'browser-test', displayName: 'Browser test', nativeName: 'tqs_browser_test',
      ticket: 'local-fixture', expiresAt: 9999999999,
      poolPolicy: { schemaVersion: 1, mode: 'new_heg_mode', revision: 1, generalNum: 5,
        disabledPacks, appliesTo: 'new_rooms' },
    };
    begin();
    serverNotify('EnterLobby', Uint8Array.of(0xf6));
    const packs = roomAdapter.getRoomPacks();
    const baseline = roomAdapter.getRoomPoolSummary([]);
    const general = packs.generals.find((p) => roomAdapter.getRoomPoolSummary([p.id]).generals < baseline.generals);
    const card = packs.cards.find((p) => roomAdapter.getRoomPoolSummary([p.id]).cards < baseline.cards);
    if (!general || !card) throw new Error('Lua fixture has no togglable general/card package');
    return { general: general.id, card: card.id, baseline };
  },
  roomPool: (disabled: string[]) => roomAdapter.getRoomPoolSummary(disabled),
  roomPacks: (): RoomPacks => roomAdapter.getRoomPacks(),
  acknowledgeCreatedRoom: () => {
    const packet = sentPackets().find((p) => p.command === 'CreateRoom');
    if (!packet) throw new Error('No CreateRoom packet was sent');
    const parsed = conn.lua.eval<{ roomName: string; capacity: number; timeout: number;
      disabledPack: string[]; disabledGenerals: string[]; mode: string }>(`
      local data = cbor.decode(__host_hex2bin('${packet.hex}'))
      return {roomName = data[1], capacity = data[2], timeout = data[3],
        disabledPack = data[4].disabledPack, disabledGenerals = data[4].disabledGenerals,
        mode = data[4].gameMode}
    `);
    const enterRoom = conn.lua.eval<string>(`
      local data = cbor.decode(__host_hex2bin('${packet.hex}'))
      return __host_bin2hex(cbor.encode({data[2], data[3], data[4]}))
    `);
    serverNotify('EnterRoom', fromHex(enterRoom));
    // A native room owner receives RoomOwner after EnterRoom. Keep the local
    // fixture in the same state so waiting-room screenshots and controls test
    // the owner path instead of silently rendering a regular player.
    serverNotify('RoomOwner', serverCbor('{17}'));
    return parsed;
  },
  boardState: () => useGameStore.getState().board,
  store: useGameStore,
  getConn: () => conn,
  generalSkills: (name: string) => conn.lua.call<string[]>('__web_general_skill_names', name),
  generalMetadata: (names: string[]) => conn.lua.call<unknown[]>('__web_general_metadata', names),
  beginInitialGeneralChoice: (generals = [
    'ld__bianfuren', 'm_heg__dianwei', 'm_heg__ganning',
  ]) => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const id = ++nextId;
    const encodedGenerals = generals.map((name) => `'${name}'`).join(', ');
    fixtureRequest(id, 'CustomDialog', serverCbor(`{component = {
      name = 'ChooseInitialGeneralBox', model = {
        name = 'ChooseInitialGeneralModel', prop = {
          hegemony = true, choiceNum = 2,
          generals = {${encodedGenerals}},
          enabledKingdoms = {'wei', 'shu', 'wu', 'qun', 'jin'}
        }
      }
    }}`));
    return id;
  },
  boardNotify: (command: string, source: string) => serverNotify(command, serverCbor(source)),
  beginTablePile: (count = 3) => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const cards = conn.lua.eval<{ id: number; name: string }[]>(`return table.map({table.unpack(ClientInstance.draw_pile, 1, ${count})}, function(id)
      return {id=id, name=Fk:getCardById(id).name} end)`);
    if (cards.length !== count) throw new Error('Native draw pile has too few cards');
    const moves = cards.map((card, i) => `{toArea=Card.Processing, moveReason=fk.ReasonPut,
      moveInfo={{cardId=${card.id}, fromArea=Card.DrawPile}}, moveVisible=${i === 1 ? 'false' : 'true'}}`);
    serverNotify('MoveCards', serverCbor(`{{${moves.join(',')}}, 1}`));
    // These are the same parsed UI commands RoomModel.qml receives from
    // Client:setCardNote() and room:setCardVirtualName().
    conn.lua.eval(`ClientInstance:notifyUI('SetCardFootnote', {${cards[0].id}, 'Đang giải quyết kỹ năng', false})
      ClientInstance:notifyUI('SetCardVirtName', {{${cards[0].id}}, 'fire__slash', false})`);
    return { cards, initialDraw: useGameStore.getState().board.drawPileCount };
  },
  tablePileMoveToDiscard: (ids: number[]) => {
    const moves = ids.map((id) => `{toArea=Card.DiscardPile, moveReason=fk.ReasonDiscard,
      moveInfo={{cardId=${id}, fromArea=Card.Processing}}, moveVisible=false}`);
    serverNotify('MoveCards', serverCbor(`{{${moves.join(',')}}, 2}`));
    return useGameStore.getState().board;
  },
  tablePileLongNote: (id: number) => {
    // A literal FreeKill UI notification tests that native footnotes can be
    // inspected in full even when the small painted card truncates them.
    const note = 'Kỹ năng đang xử lý: giữ nguyên thứ tự các lá; đối chiếu mọi người chơi liên quan trước khi kết toán; chú thích đầy đủ không bị rút gọn trên điện thoại. '.repeat(8);
    conn.lua.eval(`ClientInstance:notifyUI('SetCardFootnote', {${id}, '${note}', false})`);
    return note;
  },
  tablePileVirtualAlias: (id: number, knownAlias = true) => {
    // Match the server's virtual=true variant of sendCardVirtName/sendFootnote.
    // Use a temporary native virt_id on a card already in the table, so raw
    // identifiers never cross the web UI boundary.
    conn.lua.eval(`local card = Fk:getCardById(${id})
      local saved = card.virt_id
      card.virt_id = ${knownAlias ? '798321' : '798322'}
      ClientInstance:notifyUI('SetCardVirtName', {{card.virt_id}, 'thunder__slash', true})
      ClientInstance:notifyUI('SetCardFootnote', {card.virt_id, 'Bài ảo đang xử lý', true})
      card.virt_id = saved`);
    return useGameStore.getState().board.processingCards;
  },
  tablePileSharedVirtualAlias: (first: number, second: number) => {
    conn.lua.eval(`local first = Fk:getCardById(${first})
      local second = Fk:getCardById(${second})
      local old_first, old_second = first.virt_id, second.virt_id
      first.virt_id, second.virt_id = 798323, 798323
      ClientInstance:notifyUI('SetCardFootnote', {798323, 'Chỉ lá đầu tiên có mã ảo trùng', true})
      first.virt_id, second.virt_id = old_first, old_second`);
    return useGameStore.getState().board.processingCards;
  },
  tablePileRevealParsedNote: (id: number) => {
    const note = conn.lua.eval<string>("return ClientInstance:parseMsg({type='##ShowCard', from=17}, true)");
    conn.lua.eval(`ClientInstance:showVirtualCard({{Fk:getCardById(${id})}, 17, {type='##ShowCard', from=17}, 3})`);
    return note;
  },
  tablePileReveal: (id: number, footnote: string) => {
    // Exercise actual FreeKill Client:showVirtualCard -> notifyUI, separate
    // from the physical processing/discard list.
    if (footnote) {
      conn.lua.eval(`ClientInstance:notifyUI('ShowVirtualCard', {{Fk:getCardById(${id})}, 17, '${footnote}', 3})`);
    } else {
      conn.lua.eval(`ClientInstance:showVirtualCard({{Fk:getCardById(${id})}, 17, nil, 3})`);
    }
    return useGameStore.getState().board.virtualSequence;
  },
  tablePileRevealBurst: (ids: number[]) => {
    for (const id of ids) conn.lua.eval(`ClientInstance:showVirtualCard({{Fk:getCardById(${id})}, 17, nil, 3})`);
    return useGameStore.getState().board.virtualSequence;
  },
  equipBot: () => {
    const id = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=-1, toArea=Card.PlayerEquip, moveReason=fk.ReasonPut,
      moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    return id;
  },
  beginTransformationSkill: (kind: 'qice' | 'yongjin' | 'yongjin-targets' | 'yongjin-board') => {
    api.beginPlay(false, { playCardRequest: false });
    const skill = kind === 'qice' ? 'ld__qice' : 'yongjin';
    serverNotify('PropertyUpdate', serverCbor(`{17, 'general', '${kind === 'qice' ? 'ld__xunyou' : 'ld__lingtong'}'}`));
    serverNotify('AddSkill', serverCbor(`{17, '${skill}'}`));
    const equipment = kind !== 'qice' ? api.equipBot() : null;
    const id = ++nextId;
    if (kind === 'yongjin-board') {
      fixtureRequest(id, 'AskForMoveCardInBoard', serverCbor(`{cards={${equipment}}, cardsPosition={1}, playerIds={17,-1}}`));
    } else {
      fixtureRequest(id, kind === 'yongjin-targets' ? 'AskForUseActiveSkill' : 'PlayCard',
        serverCbor(kind === 'yongjin-targets'
          ? "{'choose_players_to_move_card_in_board', '#yongjin-choose', true, {flag='e', skillName='yongjin', excludeIds={}, froms={ClientInstance:getPlayerById(17), ClientInstance:getPlayerById(-1)}, tos={ClientInstance:getPlayerById(17), ClientInstance:getPlayerById(-1)}}}"
          : '{}'));
    }
    return { id, skill };
  },
  transformationChoice: () => conn.lua.eval<string | null>(
    'return Fk.skills.ld__qice.interaction.data'),
  begin,
  netState: (state: 'trust' | 'online') => {
    serverNotify('NetStateChanged', serverCbor(`{17, '${state}'}`));
    return conn.lua.eval<number>('return Self.player:getState()');
  },
  beginChoices: (single = false, expired = false) => {
    begin();
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({
      requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForChoices', timeout: expired ? 1 : 30,
      timestamp: expired ? Date.now() - 5000 : Date.now(),
      data: serverCbor(`{{'main', 'deputy'}, {'main', 'deputy', 'disabled'}, {1, ${single ? 1 : 2}}, true, 'm_heg__qiangxi', 'Chọn tướng để lật', false, ${single}}`),
    }));
    return id;
  },
  beginPlay: (withSkill = false, options: FixtureBeginPlayOptions = {}) => {
    begin();
    serverNotify('EnterRoom', serverCbor("{2, 30, {gameMode='new_heg_mode', roomName='Lua card fixture', disabledPack={}, disabledGenerals={}, _game={}, _mode={}}}"));
    serverNotify('AddPlayer', serverCbor("{-1, 'Bot fixture', 'avatar', true, 0}"));
    serverNotify('StartGame', Uint8Array.of(0xf6));
    serverNotify('ArrangeSeats', serverCbor('{17, -1}'));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'ld__bianfuren'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'm_heg__dianwei'}"));
    serverNotify('PropertyUpdate', serverCbor("{-1, 'general', 'anjiang'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'kingdom', 'wei'}"));
    if (withSkill) {
      serverNotify('PropertyUpdate', serverCbor("{17, 'role_shown', true}"));
      serverNotify('AddSkill', serverCbor("{17, 'm_heg__qiangxi'}"));
    }
    for (const id of [17, -1]) {
      serverNotify('PropertyUpdate', serverCbor(`{${id}, 'hp', 4}`));
      serverNotify('PropertyUpdate', serverCbor(`{${id}, 'maxHp', 4}`));
    }
    serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.Play}"));
    serverNotify('PropertyUpdate', serverCbor("{-1, 'phase', Player.NotActive}"));
    serverNotify('PrepareDrawPile', options.drawPile
      ? serverCbor(`{${options.drawPile.join(',')}}`)
      : serverCbor('Fk.game_modes.new_heg_mode:buildDrawPile()'));
    const cardId = options.initialCards === undefined
      ? conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
        return Fk:getCardById(id).trueName == 'slash'
      end)`)
      : (options.initialCards[0] ?? -1);
    if (cardId > 0) {
      serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
        moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    }
    if (withSkill) {
      const nullification = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
        return Fk:getCardById(id).name == 'heg__nullification'
      end)`);
      serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
        moveInfo={{cardId=${nullification}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    }
    const id = ++nextId;
    if (options.playCardRequest !== false) {
      currentSocket().handlers.onData(encodePacket({
        requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
        command: 'PlayCard', data: serverCbor('{}'), timestamp: Date.now(), timeout: 30,
      }));
    }
    return { id, cardId };
  },
  beginFakePrelight: () => {
    const result = api.beginPlay(false, { initialCards: [], playCardRequest: false });
    serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
    return result.id;
  },
  beginHiddenYijiDamage: () => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    // Model Quách Gia as the private main general while the public board keeps
    // both slots face-down.  The private marks are consumed by native Lua;
    // hostLua deliberately never forwards them to React.
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'hs__guojia'}"));
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'hs__simayi'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
    serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
  },
  triggerHiddenYijiDamage: () => {
    // Damage is a public state change. The native server opens
    // AskForSkillInvoke only when the fake trigger is prelighted; mirror that
    // gate here so the local regression covers both the negative and positive
    // branches without fabricating a request for an unlit hidden skill.
    const prelighted = conn.lua.eval<boolean>(`return table.find(Self.prelighted_skills or {}, function(skill)
      return skill.name == 'hs__yiji'
    end) ~= nil`);
    serverNotify('PropertyUpdate', serverCbor("{17, 'hp', 3}"));
    if (!prelighted) return null;
    const id = ++nextId;
    fixtureRequest(id, 'AskForSkillInvoke', serverCbor(
      "{'hs__yiji', 'Quách Gia bị thương: có muốn kích hoạt Di Kế không?'}",
    ));
    return id;
  },
  revealHiddenYiji: () => {
    // revealBySkillName() makes the hidden projection disappear and the
    // revealed skill become a regular skill before the Yiji effect continues.
    serverNotify('LoseSkill', serverCbor("{17, 'hs__yiji', true}"));
    serverNotify('AddSkill', serverCbor("{17, 'hs__yiji'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'hs__guojia'}"));
  },
  beginHiddenReveal: () => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    // Keep the client-side pair hidden while retaining the private general
    // marks that reveal_skill& uses to build its interaction choices.  These
    // private marks are consumed by Lua but are intentionally not projected to
    // React by hostLua.
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'hs__luxun'}"));
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'hs__simayi'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
    // This is the exact native-client split for a hidden pair: the trigger
    // stays in fakeSkills, while the active reveal helper is a regular skill.
    serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
    serverNotify('AddSkill', serverCbor("{17, 'hs__qianxun', true}"));
    serverNotify('AddSkill', serverCbor("{17, 'reveal_skill&', true}"));
    const id = ++nextId;
    fixtureRequest(id, 'PlayCard', serverCbor('{}'));
    return id;
  },
  acknowledgePrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__yiji', ${prelight}}`));
  },
  acknowledgeYingziPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'ex__yingzi', ${prelight}}`));
  },
  rehideHiddenYiji: (isDeputy: boolean) => {
    // Native hideGeneral first removes the revealed regular skill, reattaches
    // it as fake and re-emits retained PrelightSkill=true. Keep that order in
    // the bridge fixture so the reducer regression is explicit.
    if (isDeputy) {
      serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'hs__guojia'}"));
      serverNotify('LoseSkill', serverCbor("{17, 'hs__yiji', true}"));
      serverNotify('AddSkill', serverCbor("{17, 'hs__yiji'}"));
      serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
    } else {
      serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'hs__guojia'}"));
      serverNotify('LoseSkill', serverCbor("{17, 'hs__yiji', true}"));
      serverNotify('AddSkill', serverCbor("{17, 'hs__yiji'}"));
      serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
    }
    serverNotify('LoseSkill', serverCbor("{17, 'hs__yiji'}"));
    serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
    serverNotify('PrelightSkill', serverCbor("{'hs__yiji', true}"));
  },
  continueHiddenJianxiong: () => {
    const id = ++nextId;
    fixtureRequest(id, 'AskForChoices', serverCbor(
      "{{'hs__jianxiong-obtain', 'draw1'}, {'hs__jianxiong-obtain', 'draw1'}, {1, 1}, true, 'hs__jianxiong', '#hs__jianxiong', false, true}",
    ));
    return id;
  },
  acknowledgeJianxiongPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__jianxiong', ${prelight}}`));
  },
  acknowledgeFankuiPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'fankui', ${prelight}}`));
  },
  acknowledgeLuoshenPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__luoshen', ${prelight}}`));
  },
  acknowledgeTianduPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'tiandu', ${prelight}}`));
  },
  acknowledgeJizhiPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__jizhi', ${prelight}}`));
  },
  acknowledgeMingshiPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'mingshi', ${prelight}}`));
  },
  acknowledgeFuyinPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'fuyin', ${prelight}}`));
  },
  acknowledgeGongqingPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'gongqing', ${prelight}}`));
  },
  acknowledgeQianxunPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__qianxun', ${prelight}}`));
  },
  acknowledgeKongchengPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__kongcheng', ${prelight}}`));
  },
  acknowledgeWeimuPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__weimu', ${prelight}}`));
  },
  acknowledgeTianxiangPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__tianxiang', ${prelight}}`));
  },
  acknowledgeDuanchangPrelight: (prelight: boolean) => {
    serverNotify('PrelightSkill', serverCbor(`{'hs__duanchang', ${prelight}}`));
  },
  prelightWireHex: () => conn.lua.eval<string>(`local encoders = cbor.type_encoders
    local previous = encoders.string
    encoders.string = encoders.utf8string
    local payload = cbor.encode('prelight,hs__yiji,true')
    encoders.string = previous
    return __host_bin2hex(payload)`),
  /** Put a real native hand large enough to exercise the gameplay art and
   * horizontal hand viewport in one deterministic browser fixture. */
  beginVisualHand: (count = 12) => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const requestedCount = Math.max(1, Math.floor(count));
    const cardIds = conn.lua.eval<number[]>(`local ret = {}
      for _, id in ipairs(ClientInstance.draw_pile) do
        if #ret >= ${requestedCount} then break end
        ret[#ret + 1] = id
      end
      return ret`);
    if (cardIds.length < requestedCount) throw new Error('Lua fixture has too few cards for hand viewport test');
    const moves = cardIds.map((id) => `{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}`).join(',');
    serverNotify('MoveCards', serverCbor(`{{${moves}}, 1}`));
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'PlayCard', data: serverCbor('{}'), timestamp: Date.now(), timeout: 30,
    }));
    return { id, cardIds };
  },
  /** Keep a large hand after the request closes so the idle portrait layout
   * is exercised separately from the active gameplay-controls layout. */
  beginVisualIdleHand: (count = 12) => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const requestedCount = Math.max(1, Math.floor(count));
    const cardIds = conn.lua.eval<number[]>(`local ret = {}
      for _, id in ipairs(ClientInstance.draw_pile) do
        if #ret >= ${requestedCount} then break end
        ret[#ret + 1] = id
      end
      return ret`);
    if (cardIds.length < requestedCount) throw new Error('Lua fixture has too few cards for idle hand viewport test');
    const moves = cardIds.map((id) => `{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}`).join(',');
    serverNotify('MoveCards', serverCbor(`{{${moves}}, 1}`));
    return { cardIds };
  },
  /** Exercise the native response-card request separately from normal play. */
  beginResponseCard: () => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const cardId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'jink' end)`);
    if (!Number.isInteger(cardId) || cardId <= 0) throw new Error('Lua fixture has no Jink response card');
    serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForResponseCard', data: serverCbor("{'jink', 'jink', nil, true, {}, {}}"),
      timestamp: Date.now(), timeout: 30,
    }));
    return { id, cardId };
  },
  /**
   * Start one named QA scenario against the same production React/Lua bridge
   * used by the rest of this fixture. The first native pile is inspected only
   * to resolve requirements; the second PrepareDrawPile notification is the
   * deterministic server fixture that makes the selected cards reproducible.
   */
  beginQaScenario: (scenarioId: QaScenarioId) => {
    const plan = getQaScenario(scenarioId);
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const nativeCards = conn.lua.eval<QaCardDescriptor[]>(`return table.map(ClientInstance.draw_pile, function(id)
      local card = Fk:getCardById(id)
      return {id=id, name=card.name, trueName=card.trueName,
        color=card:getColorString(), suit=card:getSuitString(),
        type=card.type == Card.TypeEquip and 'equip' or 'other'}
    end)`);
    const resolved = resolveQaScenario(plan, nativeCards);
    serverNotify('PrepareDrawPile', serverCbor(`{${resolved.drawPile.join(',')}}`));

    const moves = plan.slots.map((item) => {
      const cardId = resolved.slotCards[item.key];
      const owner = item.owner === 'self' ? 17 : -1;
      const area = item.area === 'hand' ? 'Card.PlayerHand' : 'Card.PlayerEquip';
      const reason = item.area === 'hand' ? 'fk.ReasonDraw' : 'fk.ReasonPut';
      return `{to=${owner}, toArea=${area}, moveReason=${reason},
        moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=${item.visible ? 'true' : 'false'}}`;
    });
    if (moves.length) serverNotify('MoveCards', serverCbor(`{{${moves.join(',')}}, 1}`));

    const sendRequest = (command: string, data: string) => {
      const requestId = ++nextId;
      currentSocket().handlers.onData(encodePacket({ requestId,
        type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
        command, data: serverCbor(data), timestamp: Date.now(), timeout: 30,
      }));
      return requestId;
    };

    let requestId: number;
    switch (plan.trigger) {
      case 'play-card':
        requestId = sendRequest('PlayCard', '{}');
        break;
      case 'card-chosen': {
        requestId = sendRequest('AskForCardChosen',
          `{ClientInstance:getPlayerById(-1), 'he', '#AskForChooseCard:-1::snatch'}`);
        break;
      }
      case 'poxi': {
        const handId = resolved.slotCards['hidden-hand'];
        const equipId = resolved.slotCards['public-equip'];
        requestId = sendRequest('AskForPoxi',
          `{type='AskForCardsChosen', data={{'$Hand', {${handId}}}, {'$Equip', {${equipId}}}},
            extra_data={min=1, max=2, to=-1, skillName='snatch',
              visible_data={['${handId}']=false}}, cancelable=true}`);
        break;
      }
      case 'cards-and-choice': {
        const slashId = resolved.slotCards.slash;
        const equipId = resolved.slotCards.equip;
        const peachId = resolved.slotCards.peach;
        useGameStore.getState().update({ translations: { ...useGameStore.getState().translations,
          default: 'Giữ bài', use: 'Dùng Sát', cancel: 'Bỏ qua' } });
        conn.lua.eval(`Fk.skill_skels.web_choice_fixture = {extra={choiceFilter=function(cards, choice, extra)
          return #cards == 1 and Fk:getCardById(cards[1]).trueName == 'slash' and extra.allowSlash
            and choice == 'use' end}}; return true`);
        requestId = sendRequest('AskForCardsAndChoice',
          `{cards={${slashId},${equipId},${peachId}}, choices={'default','use'},
            prompt='$ViewCards', cancel_choices={'cancel'}, min=1, max=1,
            disabled={${peachId}}, filter_skel='web_choice_fixture', extra_data={allowSlash=true}}`);
        break;
      }
      case 'rescue-normal': {
        serverNotify('PropertyUpdate', serverCbor("{-1, 'hp', 0}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.NotActive}"));
        requestId = api.requestRescue(-1, 0);
        break;
      }
      case 'rescue-battle': {
        serverNotify('PropertyUpdate', serverCbor("{17, 'hp', 0}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.NotActive}"));
        serverNotify('SetBanner', serverCbor("{'@[:]BattleRoyalDummy', 'NewBattleRoyalMode'}"));
        serverNotify('AddSkill', serverCbor("{17, 'new_battle_royal&'}"));
        requestId = api.requestRescue(17, 0);
        break;
      }
      case 'founding':
        serverNotify('PropertyUpdate', serverCbor("{17, 'kingdom', 'wild'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'role_shown', true}"));
        requestId = sendRequest('AskForChoices',
          `{table.filter(require('packages.hegemony.util').wildKingdoms,
            function(k) return k ~= 'heg_han' end), require('packages.hegemony.util').wildKingdoms,
            {1,1}, false, 'game_rule', '#wild-choose', false, true}`);
        break;
      case 'damage-exchange':
        // Mirror the first real-card attack request. Only the native director
        // resolves Slash/Jink, damage and Damaged reactions on the server.
        requestId = sendRequest('AskForUseActiveSkill',
          `{'userealcard_skill', 'Sát lần 1: tấn công đối thủ', true,
            {cardIds={${resolved.slotCards['actor-slash-1']}}, bypass_times=true,
             extraUse=true, bypass_distances=true, exclusive_targets={-1}, must_targets={-1}}}`);
        break;
      case 'hidden-yiji':
        // The native QA package uses the same request as a bounded pause while
        // the real client may send PushRequest("prelight,..."). The local
        // fixture does not execute native damage, but it keeps this scenario
        // in the catalog so native/browser command contracts cannot drift.
        serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_yiji_gate', 'TQS QA: prelight Di Kế nếu muốn, rồi bấm Kích hoạt để tiếp tục.'}");
        break;
      case 'hidden-rehide-yiji': {
        // The local fixture mirrors the native readiness gate. The explicit
        // re-hide transition is applied only after the gate reply so the
        // final fake+prelight projection can be asserted separately.
        const deputy = scenarioId === 'hidden-rehide-yiji-deputy';
        const main = deputy ? 'hs__simayi' : 'hs__guojia';
        const deputyGeneral = deputy ? 'hs__guojia' : 'hs__simayi';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__yiji', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_rehide_yiji_gate', 'TQS QA: prelight Di Kế, kích hoạt rồi kiểm tra úp lại.'}");
        break;
      }
      case 'hidden-jianxiong': {
        // Mirror the native prelight gate and the later AskForChoices request;
        // the local fixture checks the React/Lua request chain, while native
        // C++ remains the authority for the real damage/card movement effect.
        const main = scenarioId === 'hidden-jianxiong-deputy' ? 'hs__simayi' : 'hs__caocao';
        const deputy = scenarioId === 'hidden-jianxiong-deputy' ? 'hs__caocao' : 'hs__simayi';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__jianxiong', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_jianxiong_gate', 'TQS QA: prelight Gian Hùng, rồi xác nhận để đối thủ dùng Sát.'}");
        break;
      }
      case 'hidden-fankui': {
        // Fankui is a compulsory fk.Damaged trigger in the native source. The
        // fixture only mirrors the hidden fake-skill/prelight gate; native C++
        // remains authoritative for the later AskForCardChosen obtain path.
        const main = scenarioId === 'hidden-fankui-deputy' ? 'hs__guojia' : 'hs__simayi';
        const deputy = scenarioId === 'hidden-fankui-deputy' ? 'hs__simayi' : 'hs__guojia';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'fankui', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_fankui_gate', 'TQS QA: prelight Phản Quỹ, rồi xác nhận để tiếp tục.'}");
        break;
      }
      case 'hidden-luoshen': {
        // Luoshen is an EventPhaseStart trigger. The local fixture mirrors the
        // hidden fake-skill/prelight gate and phase-start invoke; native C++
        // remains authoritative for judge, reveal and card obtain.
        const main = scenarioId === 'hidden-luoshen-deputy' ? 'hs__simayi' : 'hs__zhenji';
        const deputy = scenarioId === 'hidden-luoshen-deputy' ? 'hs__zhenji' : 'hs__simayi';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__luoshen', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_luoshen_gate', 'TQS QA: prelight 洛神, rồi xác nhận để bắt đầu pha chuẩn bị.'}");
        break;
      }
      case 'hidden-tiandu': {
        // Tiandu is compulsory on FinishJudge. The local fixture mirrors the
        // hidden fake-skill/prelight gate; native C++ remains authoritative
        // for the real judge, reveal-before-SkillEffect and obtain path.
        const main = scenarioId === 'hidden-tiandu-deputy' ? 'hs__simayi' : 'hs__guojia';
        const deputy = scenarioId === 'hidden-tiandu-deputy' ? 'hs__guojia' : 'hs__simayi';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'tiandu', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_tiandu_gate', 'TQS QA: prelight Thiên Đố, rồi xác nhận để bắt đầu phán xét.'}");
        break;
      }
      case 'hidden-jizhi': {
        // Jizhi is a hidden optional CardUsing trigger.  The local browser
        // fixture only mirrors the private fake-skill/prelight readiness
        // gate; native QA owns the real Duel -> CardUsing -> draw path.
        const main = scenarioId === 'hidden-jizhi-deputy' ? 'hs__zhaoyun' : 'hs__huangyueying';
        const deputy = scenarioId === 'hidden-jizhi-deputy' ? 'hs__huangyueying' : 'hs__zhaoyun';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__jizhi', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_jizhi_gate', 'TQS QA: prelight Tập Trí, rồi xác nhận để dùng Lạc Hồn.'}");
        break;
      }
      case 'hidden-mingshi': {
        // Mingshi is compulsory on DamageInflicted.  Keep the browser fixture
        // limited to the fake-skill/prelight gate; native QA verifies the
        // hidden source predicate and zero-damage effect on a real Slash.
        const main = scenarioId === 'hidden-mingshi-deputy' ? 'hs__jiling' : 'hs__kongrong';
        const deputy = scenarioId === 'hidden-mingshi-deputy' ? 'hs__kongrong' : 'hs__jiling';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'mingshi', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_mingshi_gate', 'TQS QA: prelight Danh Sĩ, rồi xác nhận để nguồn úp dùng Sát.'}");
        break;
      }
      case 'hidden-fuyin': {
        // Fuyin is compulsory on TargetConfirmed. Keep the pair face-down and
        // expose only the fake/prelight gate here; native QA owns the real
        // source Slash, TargetConfirmed cancellation and slot reveal.
        const deputy = scenarioId === 'hidden-fuyin-deputy';
        const main = deputy ? 'hs__zhaoyun' : 'zhugezhan';
        const deputyGeneral = deputy ? 'zhugezhan' : 'hs__zhaoyun';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'fuyin', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_fuyin_gate', 'TQS QA: prelight Phụ Âm, rồi xác nhận để nguồn úp dùng Sát.'}");
        break;
      }
      case 'hidden-gongqing': {
        // Gongqing has two native damage-range branches. The local fixture
        // mirrors only the hidden fake-skill/prelight gate; native C++ owns
        // the low-range reduction, high-range increase and slot reveal.
        const deputy = scenarioId === 'hidden-gongqing-deputy';
        const main = deputy ? 'hs__sunquan' : 'panjun';
        const deputyGeneral = deputy ? 'panjun' : 'hs__sunquan';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'gongqing', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_gongqing_gate', 'TQS QA: prelight Công Thanh, rồi xác nhận để kiểm tra hai nhánh tầm đánh.'}");
        break;
      }
      case 'hidden-qianxun': {
        // Qianxun is compulsory on both TargetConfirming and BeforeCardsMove.
        // The local fixture mirrors only the private fake-skill/prelight gate;
        // native QA owns the real Snatch/Indulgence outcome and card-area
        // assertion.
        const deputy = scenarioId === 'hidden-qianxun-deputy' || scenarioId === 'hidden-qianxun-indulgence-deputy';
        const main = deputy ? 'hs__sunquan' : 'hs__luxun';
        const deputyGeneral = deputy ? 'hs__luxun' : 'hs__sunquan';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__qianxun', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          `{\'tqs_qa_hidden_qianxun_gate\', \'TQS QA: prelight Khiêm Tốn, rồi xác nhận để đối thủ dùng ${scenarioId.includes('indulgence') ? 'Lạc Bất Tư Thục' : 'Thuận Thủ'}.\'}`);
        break;
      }
      case 'hidden-kongcheng': {
        // Kongcheng is compulsory on TargetConfirming only after the actor's
        // hand is empty. The local fixture mirrors the hidden pair and its
        // prelight gate; native QA owns the real empty-hand Duel outcome.
        const deputy = scenarioId === 'hidden-kongcheng-deputy';
        const main = deputy ? 'hs__zhaoyun' : 'hs__zhugeliang';
        const deputyGeneral = deputy ? 'hs__zhugeliang' : 'hs__zhaoyun';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__kongcheng', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_kongcheng_gate', 'TQS QA: prelight Không Thành, rồi xác nhận để đối thủ dùng Quyết Đấu.'}");
        break;
      }
      case 'hidden-weimu': {
        // Weimu is a compulsory TargetConfirming branch for black Trick
        // cards. The local fixture mirrors only the hidden fake-skill/prelight
        // gate; native QA owns the real black Duel/Indulgence branch and reveal.
        const deputy = scenarioId === 'hidden-weimu-deputy' || scenarioId === 'hidden-weimu-indulgence-deputy';
        const main = deputy ? 'hs__pangde' : 'hs__jiaxu';
        const deputyGeneral = deputy ? 'hs__jiaxu' : 'hs__pangde';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__weimu', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          `{\'tqs_qa_hidden_weimu_gate\', \'TQS QA: prelight 帷幕, rồi xác nhận để đối thủ dùng ${scenarioId.includes('indulgence') ? 'Lạc Bất Tư Thục đen' : 'Quyết Đấu đen'}.\'}`);
        break;
      }
      case 'hidden-xiaoji': {
        // Xiaoji is an AfterCardsMove trigger. The local fixture only mirrors
        // the hidden fake-skill/prelight readiness gate; native QA owns the
        // real equipment-loss, reveal and draw outcome.
        const deputy = scenarioId === 'hidden-xiaoji-deputy';
        const main = deputy ? 'hs__sunquan' : 'hs__sunshangxiang';
        const deputyGeneral = deputy ? 'hs__sunshangxiang' : 'hs__sunquan';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__xiaoji', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_xiaoji_gate', 'TQS QA: prelight 枭姬, rồi xác nhận để mất trang bị thật.'}");
        break;
      }
      case 'hidden-yingzi': {
        // Yingzi is compulsory on fk.DrawNCards. The local fixture mirrors
        // only the hidden fake-skill/prelight gate; native C++ owns the real
        // DrawNCards mutation, draw count and slot reveal.
        const deputy = scenarioId === 'hidden-yingzi-deputy';
        const main = deputy ? 'hs__daqiao' : 'hs__zhouyu';
        const deputyGeneral = deputy ? 'hs__zhouyu' : 'hs__daqiao';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'ex__yingzi', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_yingzi_gate', 'TQS QA: prelight 英姿, rồi xác nhận để bắt đầu pha rút bài.'}");
        break;
      }
      case 'hidden-tianxiang': {
        // Tianxiang owns a real DetermineDamageInflicted interaction. The
        // fixture mirrors only the hidden fake-skill/prelight gate; native C++
        // owns the heart-card/target selection, choice branch and redirect.
        const deputy = scenarioId === 'hidden-tianxiang-deputy';
        const main = deputy ? 'hs__sunquan' : 'hs__xiaoqiao';
        const deputyGeneral = deputy ? 'hs__xiaoqiao' : 'hs__sunquan';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__tianxiang', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_tianxiang_gate', 'TQS QA: prelight Thiên Hương, rồi xác nhận để nhận sát thương.'}");
        break;
      }
      case 'hidden-duanchang': {
        // Duanchang is a compulsory fk.Death trigger.  The fixture mirrors
        // only the hidden fake-skill/prelight readiness gate; native C++ owns
        // the real death event, killer choice and slot-skill loss.
        const deputy = scenarioId === 'hidden-duanchang-deputy';
        const main = deputy ? 'hs__yuanshao' : 'hs__caiwenji';
        const deputyGeneral = deputy ? 'hs__caiwenji' : 'hs__yuanshao';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__duanchang', true}"));
        requestId = sendRequest('AskForSkillInvoke',
          "{'tqs_qa_hidden_duanchang_gate', 'TQS QA: prelight Đoạn Trường, rồi xác nhận để xử lý khi chết.'}");
        break;
      }
      case 'hidden-reveal':
        // The active helper must remain a regular skill while the compulsory
        // Qianxun trigger stays in the fake/prelight dock.
        serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'hs__luxun'}"));
        serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'hs__sunquan'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__qianxun', true}"));
        serverNotify('AddSkill', serverCbor("{17, 'reveal_skill&', true}"));
        requestId = sendRequest('AskForUseActiveSkill',
          "{'reveal_skill&', 'TQS QA: mở Lục Tốn bằng kỹ năng Tỏa định.', true, {skillName='reveal_skill&'}}");
        break;
      case 'hidden-active':
        // The native server sends fake active skills with the fake marker, but
        // upstream client.lua projects an ActiveSkill as a regular SkillButton
        // so PlayCard can validate it. Keep both generals hidden here and
        // exercise the same client-side request scene with one real Slash.
        serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'hs__luxun'}"));
        serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'hs__sunquan'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__qianxun', true}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__zhiheng', true}"));
        requestId = sendRequest('PlayCard', '{}');
        break;
      case 'hidden-fanjian': {
        // Phản Gián is an ordinary native ActiveSkill.  The hidden pair stays
        // face-down while the projected fake skill is selected in PlayCard;
        // the native server-side scenario separately proves revealBySkillName
        // and the target's follow-up choice.
        const deputy = scenarioId === 'hidden-fanjian-deputy';
        const main = deputy ? 'hs__daqiao' : 'hs__zhouyu';
        const deputyGeneral = deputy ? 'hs__zhouyu' : 'hs__daqiao';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputyGeneral}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'ex__fanjian', true}"));
        requestId = sendRequest('PlayCard', '{}');
        break;
      }
      case 'hidden-view-as': {
        // A hidden ViewAsSkill is projected as a regular PlayCard skill on
        // the owner client.  Keep both general slots hidden and reserve one
        // Jink so the real Lua card-selection path can prove Longdan's
        // Jink-to-Slash conversion instead of merely clicking a fake button.
        const main = scenarioId === 'hidden-view-as-main' ? 'hs__zhaoyun' : 'hs__guanyu';
        const deputy = scenarioId === 'hidden-view-as-main' ? 'hs__guanyu' : 'hs__zhaoyun';
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_general', '${main}'}`));
        serverNotify('SetPlayerMark', serverCbor(`{17, '__heg_deputy', '${deputy}'}`));
        serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
        serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
        serverNotify('AddSkill', serverCbor("{17, 'hs__longdan', true}"));
        requestId = sendRequest('PlayCard', '{}');
        break;
      }
      // These catalog triggers require native QA and have no local socket director.
      case 'hidden-dual':
      case 'hidden-guanxing':
      case 'hidden-liegong':
      case 'hidden-jueqing':
      case 'hidden-ejue':
      case 'hidden-dufu':
      case 'hidden-jianzhi':
      case 'hidden-zhiman':
      case 'hidden-jilix':
      case 'hidden-kuanggu':
      case 'hidden-enyuan':
      case 'ai-trace':
      case 'chooser-trace':
      case 'general-pair-trace':
      case 'general-pair-match':
        throw new Error(`Unsupported QA trigger: ${plan.trigger}`);
      default: {
        const unreachable: never = plan.trigger;
        throw new Error(`Unsupported QA trigger: ${unreachable}`);
      }
    }
    return { scenario: scenarioId, expectedCommand: plan.expectedCommand, requestId,
      drawPile: resolved.drawPile, slotCards: resolved.slotCards };
  },
  reconnectSummary: () => {
    api.beginPlay();
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'ld__bianfuren'}"));
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'm_heg__dianwei'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
    // Build the same client-side serialized shape that a native reconnect
    // receives for a hidden trigger and a hidden active skill: fake skills are
    // restored from fake_skills, while player_skills remains the public list.
    // The reconnect path must classify the direct snapshot exactly like the
    // live Client:addSkill() callbacks and restore the prelight decision.
    const summary = conn.lua.eval<string>(`local yiji = Fk.skills.hs__yiji
      local zhiheng = Fk.skills.hs__zhiheng
      Self.player_skills, Self.derivative_skills = {}, {}
      Self._fake_skills, Self._manually_fake_skills = { yiji, zhiheng }, { yiji, zhiheng }
      Self.prelighted_skills = { yiji }
      return __host_bin2hex(cbor.encode(ClientInstance:serialize()))`);
    useGameStore.getState().update({ ownId: null });
    conn.connect();
    serverNotify('NetworkDelayTest', encodeTextArray([publicKeyPem]).subarray(1));
    serverNotify('Setup', serverCbor("{17, 'browser-test', 'avatar', 1000}"));
    serverNotify('Reconnect', fromHex(summary));
    return { status: conn.getStatus().kind, phase: useGameStore.getState().phase,
      ownId: useGameStore.getState().ownId, players: useGameStore.getState().board.player,
      seats: useGameStore.getState().board.seats, request: useGameStore.getState().pendingRequest,
      fakeSkills: useGameStore.getState().fakeSkills,
      regularSkills: useGameStore.getState().regularSkills,
      errors: [...luaErrors], reconnectUiPayloadBytes };
  },
  beginNative: (kind: 'ag' | 'arrange' | 'generals' | 'options' | 'generalChoice' | 'boardMove' | 'skills' | 'generalOptions' | 'cardNames', expired = false) => {
    api.beginPlay();
    const cardIds = conn.lua.eval<number[]>('return {ClientInstance.draw_pile[1], ClientInstance.draw_pile[2], ClientInstance.draw_pile[3]}');
    const command = kind === 'generalChoice' ? 'AskForGeneral' : kind === 'boardMove' ? 'AskForMoveCardInBoard' : kind === 'options' ? 'AskForOptions' : kind === 'ag' ? 'AskForAG' : kind === 'arrange' ? 'AskForArrangeCards' : 'CustomDialog';
    const sources = {
      cardNames: "{component={url='packages/utility/qml/ChooseCardNamesBox.qml',model={url='packages/utility/qml/models/ChooseCardNamesModel.qml',prop={choices={'slash','peach'},allChoices={{'slash','peach','jink'}},minNum=1,maxNum=1,prompt='',cancelable=false,repeatable=false}}}}",
      generalOptions: "{component={url='packages/utility/qml/ChooseGeneralsAndChoiceBox.qml',model={url='packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml',prop={cards={'hs__zoushi','ld__shixie'},all_cards={'hs__zoushi','ld__shixie'},disable_cards={'ld__shixie'},min=1,max=1,prompt='',ok_options={'OK','general'},cancel_options={'Cancel'}}}}}",
      skills: "{component={url='packages/utility/qml/ChooseSkillBox.qml',model={url='packages/utility/qml/models/ChooseSkillModel.qml',prop={skills={'huoshui','qingcheng'},min=1,max=1,prompt='',cancelable=true}}}}",
      generalChoice: "{{'hs__zoushi','ld__shixie'},1,true,false,'askForGeneralsChosen','',{n=1}}",
      boardMove: `{cards={${cardIds.join(',')}},cardsPosition={0,1,0},playerIds={17,-1}}`,
      options: "{{'OK','Cancel'},{'OK','Cancel'},{1,1},false,'trigger','',true}",
      ag: `{ {${cardIds.join(',')}}, true, 'amazing_grace' }`,
      arrange: `{cards={{${cardIds.join(',')}},{}}, names={'Top','Bottom'}, prompt='', capacities={3,3}, limits={2,1}, is_free=true, pattern='.', poxi_type='', cancelable=false}`,
      generals: `{component={url='packages/hegemony/qml/KnownBothBox.qml',model={url='packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml',prop={cards={'hs__zoushi','ld__shixie'},all_cards={'hs__zoushi','ld__shixie'},min=0,max=0,prompt='',ok_options={'OK'},cancel_options={}}}}}`,
    };
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command, data: serverCbor(sources[kind]), timestamp: expired ? Date.now()-5000 : Date.now(), timeout: expired ? 1 : 30 }));
    if (kind !== 'options' && !conn['pendingRequest']?.nativeDialogPrompt) throw new Error(`No parsed ${kind} dialog; raw ${JSON.stringify(conn['nativeDialogPayload'])}`);
    return { id, cardIds, tokens: conn['pendingRequest']?.nativeDialogPrompt?.cards.map(card => card.token) };
  },
  attemptNative: (id: number, token?: string) => {
    try { conn.respondToNativeDialog(id, token); return null; } catch (e) { return (e as Error).message; }
  },
  beginRescue: (mode: 'normal' | 'new' | 'old' | 'ignore' | 'self' | 'companion' = 'normal', hp = 0) => {
    api.beginPlay();
    const peachId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'peach' end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${peachId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    const dyingId = mode === 'self' ? 17 : -1;
    serverNotify('PropertyUpdate', serverCbor(`{${dyingId}, 'hp', ${hp}}`));
    serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.NotActive}"));
    if (mode !== 'normal') {
      serverNotify('SetBanner', serverCbor(`{'@[:]BattleRoyalDummy', '${mode === 'old' ? 'BattleRoyalMode' : 'NewBattleRoyalMode'}'}`));
      serverNotify('AddSkill', serverCbor(`{17, '${mode === 'old' ? 'battle_royal&' : 'new_battle_royal&'}'}`));
      if (mode === 'ignore') serverNotify('SetPlayerMark', serverCbor("{17, '_heg__BattleRoyalMode_ignore', 1}"));
      if (mode === 'companion') {
        serverNotify('AddSkill', serverCbor("{17, 'companion_skill&'}"));
        serverNotify('SetPlayerMark', serverCbor("{17, '@!!companion', 1}"));
      }
    }
    const id = api.requestRescue(dyingId, hp);
    return { id, peachId, dyingId };
  },
  requestRescue: (dyingId: number, hp: number) => {
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForUseCard', timestamp: Date.now(), timeout: 30,
      data: serverCbor(`{'peach', '${dyingId === 17 ? 'peach,analeptic' : 'peach'}',
        '${dyingId === 17 ? '#AskForPeachesSelf:::' : '#AskForPeaches:-1::'}${1 - hp}', true,
        {analepticRecover=true, must_targets={${dyingId}}, fix_targets={${dyingId}}}, {}}`),
    }));
    return id;
  },
  gameplay: () => useGameStore.getState().gameplay,
  rescueTargets: () => conn.lua.eval<number[]>(`local h = ClientInstance.current_request_handler
    return table.map(h:getUsingCard():getFixedTargets(Self, h.extra_data), function(p) return p.id end)`),
  applyRescue: (cardId: number, targetId: number, hp: number) => {
    serverNotify('MoveCards', serverCbor(`{{{from=17, toArea=Card.DiscardPile, moveReason=fk.ReasonUse,
      moveInfo={{cardId=${cardId}, fromArea=Card.PlayerHand}}, moveVisible=true}}, 1}`));
    serverNotify('PropertyUpdate', serverCbor(`{${targetId}, 'hp', ${hp}}`));
  },
  drawPeach: () => {
    const id = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'peach' end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    return id;
  },
  beginWildChoice: () => {
    api.beginPlay();
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForChoices', timestamp: Date.now(), timeout: 30,
      data: serverCbor(`{table.filter(require('packages.hegemony.util').wildKingdoms,
        function(k) return k ~= 'heg_han' end), require('packages.hegemony.util').wildKingdoms,
        {1,1}, false, 'game_rule', '#wild-choose', false, true}`),
    }));
    return id;
  },
  beginCardSelection: (poxi = false, expired = false, pattern = false, max = 2) => {
    api.beginPlay();
    const handId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'peach' end)`);
    const equipId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=-1, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${handId}, fromArea=Card.DrawPile}}, moveVisible=false}}, 1}`));
    serverNotify('MoveCards', serverCbor(`{{{to=-1, toArea=Card.PlayerEquip, moveReason=fk.ReasonPut,
      moveInfo={{cardId=${equipId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({
      requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: poxi ? 'AskForPoxi' : 'AskForCardChosen', timeout: expired ? 1 : 30,
      timestamp: expired ? Date.now() - 5000 : Date.now(),
      data: serverCbor(poxi ? `{type='AskForCardsChosen', data={{'$Hand', {${handId}}}, {'$Equip', {${equipId}}}},
        extra_data={min=1, max=${max}, to=-1, skillName='snatch', ${pattern ? "pattern='.|.|.|equip'," : ''}
          visible_data={['${handId}']=false}}, cancelable=true}` :
        `{ClientInstance:getPlayerById(-1), 'he', '#AskForChooseCard:-1::snatch'}`),
    }));
    return { id, handId, equipId };
  },
  beginFankui: (skill: 'ex__fankui' | 'fankui' | 'hs__yiji' = 'ex__fankui') => {
    // This follows the native ex__fankui request shape: the prompt is
    // optional in FreeKill and the next request asks for one card from the
    // damage source. The card remains hidden to the client just like a real
    // opponent hand card.
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const cardId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'peach' end)`);
    if (!Number.isSafeInteger(cardId) || cardId <= 0) throw new Error('Lua fixture has no card for ex__fankui');
    serverNotify('MoveCards', serverCbor(`{{{to=-1, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=false}}, 1}`));
    const id = ++nextId;
    // The native Client:askForSkillInvoke accepts {skill_name, nil}; this is
    // the exact case that previously left the web button waiting for Lua.
    fixtureRequest(id, 'AskForSkillInvoke', serverCbor(`{'${skill}', nil}`));
    return { id, cardId };
  },
  continueFankui: () => {
    const id = ++nextId;
    fixtureRequest(id, 'AskForCardChosen', serverCbor(
      `{ClientInstance:getPlayerById(-1), 'he', '#ex__fankui-invoke::-1'}`,
    ));
    return id;
  },
  beginLongdan: (direction: 'defend' | 'attack') => {
    api.beginPlay(false, { initialCards: [], playCardRequest: false });
    const material = direction === 'defend' ? 'slash' : 'jink';
    const cardId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == '${material}' end)`);
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'hs__zhaoyun'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'ld__fazheng'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'kingdom', 'shu'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'role_shown', true}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.NotActive}"));
    serverNotify('AddSkill', serverCbor("{17, 'hs__longdan'}"));
    serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    const id = ++nextId;
    const pattern = direction === 'defend' ? 'jink' : 'slash';
    fixtureRequest(id, 'AskForUseCard', serverCbor(`{'tqs_qa', '${pattern}',
      'Long Đảm: ${direction === 'defend' ? 'dùng Sát như Thiểm để né Sát' : 'dùng Thiểm như Sát để phản công'}', true,
      {bypass_times=true, bypass_distances=true${direction === 'attack' ? ', exclusive_targets={-1}, must_targets={-1}' : ''}}, {}}`));
    return { id, cardId };
  },
  continueYiji: () => {
    const cards = conn.lua.eval<number[]>('return {ClientInstance.draw_pile[1], ClientInstance.draw_pile[2]}');
    const id = ++nextId;
    fixtureRequest(id, 'AskForUseActiveSkill', serverCbor(`{'ex__choose_skill', '#yiji-give', true,
      {max_t_num=1, min_t_num=1, min_c_num=1, max_c_num=2,
       targets={17,-1}, pattern=tostring(Exppattern{id={${cards.join(',')}}}),
       skillName='hs__yiji', expand_pile={${cards.join(',')}}}}`));
    return { id, cards };
  },
  beginCardsAndChoice: (mode: 'view' | 'empty' | 'select' | 'cancel-only' | 'missing-filter' = 'view', expired = false) => {
    const { cardId } = api.beginPlay();
    const equipId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip end)`);
    const peachId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'peach' end)`);
    useGameStore.getState().update({ translations: { ...useGameStore.getState().translations,
      default: 'Giữ bài', use: 'Dùng Sát', cancel: 'Bỏ qua' } });
    // Fixture-only rule proves the bridge calls the installed Lua skeleton.
    conn.lua.eval(`Fk.skill_skels.web_choice_fixture = {extra={choiceFilter=function(cards, choice, extra)
      return #cards == 1 and Fk:getCardById(cards[1]).trueName == 'slash' and extra.allowSlash
        and choice == 'use' end}}; return true`);
    const view = mode === 'view' || mode === 'empty';
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({ requestId: id,
      type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForCardsAndChoice', timeout: expired ? 1 : 30,
      timestamp: expired ? Date.now() - 5000 : Date.now(),
      data: serverCbor(`{cards=${mode === 'empty' ? '{}' : `{${cardId},${equipId},${peachId}}`},
        choices=${view ? "{'OK'}" : mode === 'cancel-only' ? '{}' : "{'default','use'}"},
        prompt='$ViewCards', cancel_choices=${view ? '{}' : "{'cancel'}"},
        min=${view ? 0 : 1}, max=${view ? 0 : 1}, disabled=${view ? '{}' : `{${peachId}}`},
        filter_skel='${view ? '' : mode === 'missing-filter' ? 'no_such_rule' : 'web_choice_fixture'}',
        extra_data={allowSlash=true}}`),
    }));
    return { id, cardId, equipId, peachId };
  },
  cardsAndChoicePrompt: () => useGameStore.getState().pendingRequest?.cardsAndChoicePrompt,
  cardsAndChoiceAttempt: (id: number, tokens: string[], choice: string, cancel = false) => {
    try { conn.respondToCardsAndChoice(id, tokens, choice, cancel); return null; }
    catch (e) { return (e as Error).message; }
  },
  applyChosenMove: (discard = false) => {
    const id = api.decodedReply();
    if (typeof id !== 'number') throw new Error('Expected a single card-chosen reply');
    const area = conn.lua.eval<number>(`return ClientInstance:getPlayerById(-1):getCardIds('e')[1] == ${id}
      and Card.PlayerEquip or Card.PlayerHand`);
    serverNotify('MoveCards', serverCbor(`{{{from=-1, ${discard ? '' : 'to=17,'}
      toArea=${discard ? 'Card.DiscardPile' : 'Card.PlayerHand'}, moveReason=${discard ? 'fk.ReasonDiscard' : 'fk.ReasonPrey'},
      moveInfo={{cardId=${id}, fromArea=${area}}}, moveVisible=true}}, 1}`));
    return { selfHand: conn.lua.eval<number>('return Self:getHandcardNum()'),
      otherHand: conn.lua.eval<number>('return ClientInstance:getPlayerById(-1):getHandcardNum()'),
      otherEquip: conn.lua.eval<number>('return #ClientInstance:getPlayerById(-1):getCardIds("e")') };
  },
  cardPrompt: () => useGameStore.getState().pendingRequest?.cardSelectionPrompt,
  cardAttempt: (id: number, tokens: string[], cancel = false) => {
    try { conn.respondToCardSelection(id, tokens, cancel); return null; }
    catch (e) { return (e as Error).message; }
  },
  decodedReply: () => {
    const packet = sentPackets().filter((p) => p.type === CLIENT_REPLY).at(-1);
    return packet ? conn.lua.eval(`return cbor.decode(__host_hex2bin('${packet.hex}'))`) : null;
  },
  displayLabels: () => conn.lua.call('__web_general_labels', ['ld__bianfuren', 'm_heg__dianwei', 'm_heg__qiangxi', 'heg__nullification', 'slash', 'thunder__slash']),
  localizedLabels: (keys: string[]) => conn.lua.call<string[]>('__web_general_labels', keys),
  emitLocalizedLogs: () => conn.lua.eval(`
    ClientInstance:appendLog({type='#hs__shuangxiong', arg='red'})
    ClientInstance:appendLog({type='#WildChooseKingdom', from=17, arg='heg_qin', arg2='wild'})
    ClientInstance:appendLog({type='#EnterBattleRoyalModeLog'})
    ClientInstance:appendLog({type='new_battle_royal_event-log', arg='battle_royal_huoqi', arg2=':battle_royal_huoqi'})
    ClientInstance:appendLog({type='new_battle_royal_event-log', arg='battle_royal_luoshi', arg2=':battle_royal_luoshi'})
    ClientInstance:appendLog({type='#new_battle_royal_event&'})
    ClientInstance:appendLog({type='Vương Duyệt/Tướng ẩn 使用的 Hỏa Sát[♥4] 取消了目标 Tướng ẩn/Mã Đại (bạn)'})
    ClientInstance:appendLog({type='Vương Duyệt/Lưu Phu Nhân 使用的 Hỏa Sát[♦4] 取消了目标 Phùng Tập/Mã Đại (bạn)'})
    ClientInstance:appendLog({type='Tướng ẩn/Mi Trúc (bạn) đã phát động kỹ năng〖巨贾〗'})
    ClientInstance:appendLog({type='Nhật ký &#34;&lt;img src=x onerror=alert(1)&gt; &#x4E2D;'})
    return true
  `),
  finishGame: (withFinalLog = false) => {
    if (withFinalLog) serverNotify('GameLog', serverCbor("{type='Thông báo cuối trận thử nghiệm'}"));
    serverNotify('GameOver', serverCbor("'17'"));
    serverNotify('RemovePlayer', serverCbor('{-1}'));
  },
  enterLobby: () => serverNotify('EnterLobby', Uint8Array.of(0xf6)),
  replace: () => { const id = ++nextId; request(id); return id; },
  reconnectSameId: () => {
    const old = currentSocket();
    const id = nextId;
    setUpSocket();
    request(id);
    return sockets.indexOf(old);
  },
  oldSocketRequest: (index: number) => request(++nextId, 30, Date.now(), sockets[index]),
  disconnect: () => currentSocket().handlers.onClose('Fixture disconnect'),
  unsolicited: (payload: string) => conn.lua.eval(`ClientInstance:notifyUI('ReplyToServer', '${payload}'); return true`),
  attempt: (id: number) => {
    try { conn.respondToSkillInvoke(id, 'OK'); return null; }
    catch (error) { return (error as Error).message; }
  },
  snapshot: () => {
    const store = useGameStore.getState();
    const packets = sentPackets();
    return {
      status: conn?.getStatus().kind ?? 'booting',
      requestId: store.pendingRequest?.requestId ?? null,
      skill: store.skillInvoke,
      fakeSkills: store.fakeSkills,
      regularSkills: store.regularSkills,
      error: store.error,
      luaErrors: luaErrors.slice(),
      uiEvents: uiEvents.slice(),
      sent: packets,
      replies: packets.filter((p) => p.type === CLIENT_REPLY),
    };
  },
};
declare global { interface Window { __tqsRealLuaE2e: typeof api } }
window.__tqsRealLuaE2e = api;

async function boot() {
  try {
    const [bundleResponse, keyResponse] = await Promise.all([
      fetch('/__tqs_fixture_lua.zip'), fetch('/__tqs_fixture_key.txt'),
    ]);
    if (!bundleResponse.ok || !keyResponse.ok) throw new Error('Fixture assets unavailable');
    publicKeyPem = await keyResponse.text();
    const files = new Map(Object.entries(unzipSync(new Uint8Array(await bundleResponse.arrayBuffer()))));
    conn = new GameConnection({
      files, username: 'browser-test', password: 'local-fixture', md5: 'local-fixture', uuid: 'local-fixture',
      wasmUrl: '/glue.wasm',
      openSocket: (handlers) => {
        const socket: FixtureSocket = { handlers, sent: [], closed: false };
        sockets.push(socket);
        return { send: (bytes) => socket.sent.push(bytes), close: () => { socket.closed = true; } };
      },
      onUi: (command, data) => {
        uiEvents.push(command);
        if (command === 'Reconnect') reconnectUiPayloadBytes = JSON.stringify(data).length;
        useGameStore.getState().dispatch(command, data);
      },
      onRequest: (pendingRequest) => useGameStore.getState().update({ pendingRequest,
        ...(!pendingRequest ? { skillInvoke: null, initialGeneral: null } : {}),
      }),
      onStatus: (connection) => useGameStore.getState().update({ connection }),
      log: (level, message) => { if (level === 'error') luaErrors.push(message); },
    });
    await conn.start();
    (roomAdapter as unknown as { connection: GameConnection }).connection = conn;
    ready = true;
    useGameStore.getState().update({ progress: 'Lua WASM sẵn sàng' });
  } catch (error) {
    bootError = String(error instanceof Error ? error.stack ?? error.message : error);
    useGameStore.getState().update({ error: bootError });
  }
}

function Fixture() {
  const [busy, setBusy] = useState(false);
  const phase = useGameStore((s) => s.phase);
  const request = useGameStore((s) => s.pendingRequest);
  const prompt = useGameStore((s) => s.skillInvoke);
  const regularSkills = useGameStore((s) => s.regularSkills);
  const initialGeneral = useGameStore((s) => s.initialGeneral);
  const error = useGameStore((s) => s.error);
  const result = useGameStore((s) => s.result);
  const visualEvidence = typeof window !== 'undefined' && new URLSearchParams(window.location.search).has('visual');
  const act = (choice: 'OK' | 'Cancel') => {
    if (busy || !request) return;
    setBusy(true);
    void Promise.resolve().then(() => conn.respondToSkillInvoke(request.requestId, choice))
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  const choose = (selected: string[]) => {
    if (busy || !request) return;
    setBusy(true);
    void Promise.resolve().then(() => conn.respondToChoices(request.requestId, selected))
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  const gameAction = (action: () => void) => {
    if (busy || !request) return;
    setBusy(true);
    void Promise.resolve().then(action)
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  const prelightAction = (action: () => void) => {
    if (busy) return;
    setBusy(true);
    void Promise.resolve().then(action)
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  const roomRun = (action: () => void | Promise<void>) => {
    if (busy) return;
    setBusy(true);
    void Promise.resolve().then(action)
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  return <main className={`shell ${phase === 'playing' ? 'shell-playing' : phase === 'lobby' ? 'sg-app-shell sg-lobby-shell' : phase === 'room' ? 'sg-app-shell sg-room-shell' : ''}${visualEvidence ? ' visual-evidence-shell' : ''}`}>
    {!visualEvidence && <h1>TQS real Lua WASM E2E</h1>}
    {error && <div className="notice error-notice" role="alert">{error}</div>}
    {!visualEvidence && phase !== 'playing' && <section className="panel" aria-label="Bắt đầu ván test tương tác">
      <h2>Ván test tương tác</h2>
      <p>Lua FreeKill thật chạy trong Wasmoon, còn máy chủ là socket fixture cục bộ để bạn thử trọn luồng chọn bài.</p>
      <div className="inline-controls">
        <button className="button primary" disabled={busy || !ready}
          onClick={() => roomRun(() => { api.beginPlay(); })}>
          Bắt đầu ván test
        </button>
        <button className="button secondary" disabled={busy || !ready}
          onClick={() => roomRun(() => { api.beginVisualHand(10); })}>
          Bắt đầu với 10 lá
        </button>
      </div>
      {!ready && <p role="status">Đang khởi tạo Lua WASM…</p>}
    </section>}
    {phase === 'lobby' && <LobbyScreen adapter={roomAdapter} run={roomRun} busy={busy} />}
    {phase === 'room' && <WaitingRoomScreen adapter={roomAdapter} run={roomRun} busy={busy} />}
    {result && <GameResultPanel result={result} busy={busy} leave={() => conn.lua.call('__web_notify', 'QuitRoom', '')} />}
    {request?.command === 'AskForSkillInvoke' && <SkillInvokePanel key={`${request.requestId}-${request.receivedAt}`}
      request={request} prompt={prompt} busy={busy} onRespond={act} />}
    {request?.nativeDialogPrompt && <NativeDialogPanel request={request} prompt={request.nativeDialogPrompt} busy={busy}
      chooseGeneral={(token) => gameAction(() => conn.selectNativeGeneral(request.requestId, token))}
      view={() => conn.getNativeDialogView(request.requestId)}
      move={(token, area, index) => gameAction(() => conn.moveNativeDialogCard(request.requestId, token, area, index))}
      respond={(token, cancel) => gameAction(() => conn.respondToNativeDialog(request.requestId, token, cancel))} />}
    {request && ['AskForChoices', 'AskForOptions'].includes(request.command) && request.choicePrompt &&
      <ChoicePanel key={`${request.requestId}-${request.receivedAt}`} request={request}
        prompt={request.choicePrompt} busy={busy} respond={choose} />}
    {request?.cardSelectionPrompt && <CardSelectionPanel
      key={`${request.requestId}-${request.receivedAt}`} request={request} prompt={request.cardSelectionPrompt}
      busy={busy} view={(selected) => conn.getCardSelectionView(request.requestId, selected)}
      respond={(selected, cancel) => gameAction(() => conn.respondToCardSelection(request.requestId, selected, cancel))} />}
    {request?.cardsAndChoicePrompt && <CardsAndChoicePanel
      key={`${request.requestId}-${request.receivedAt}`} request={request} prompt={request.cardsAndChoicePrompt}
      busy={busy} view={(selected) => conn.getCardsAndChoiceView(request.requestId, selected)}
      respond={(selected, choice, cancel) => gameAction(() => conn.respondToCardsAndChoice(request.requestId, selected, choice, cancel))} />}
    {request?.command === 'CustomDialog' && initialGeneral &&
      <InitialGeneralPanel key={`${request.requestId}-${request.receivedAt}`} adapter={roomAdapter}
        run={roomRun} busy={busy} request={request} prompt={initialGeneral} />}
    {/* The native dashboard keeps fake-skill/prelight controls visible while
        AskForSkillInvoke is pending; the request panel is a separate layer. */}
    {phase === 'playing' && <GameBoardScreen busy={busy} leave={() => {}}
      getGeneralSkills={(name) => conn.lua.call<string[]>('__web_general_skill_names', name)}
      toggleTrust={() => gameAction(() => conn.toggleTrust())}
      regularSkills={regularSkills}
      prelightSkill={(skillName, prelight) => prelightAction(() => conn.prelightSkill(skillName, prelight))}
      dispatch={(kind, id, action, data) => gameAction(() => conn.updateRequestUI(request!.requestId, kind, id, action, data))}
      direct={(id, data) => gameAction(() => conn.finishDirectInteraction(request!.requestId, id, data))} />}
  </main>;
}

createRoot(document.getElementById('root')!).render(<Fixture />);
void boot();
