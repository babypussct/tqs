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
import GameResultPanel from '../../src/GameResultPanel';
import NativeDialogPanel from '../../src/NativeDialogPanel';
import { LobbyScreen, WaitingRoomScreen } from '../../src/App';
import { GameAdapter, type RoomPacks } from '../../src/engine/gameAdapter';
import { VI_ADDITIONS } from '../../src/engine/vietnamese';
import { GameConnection, type SocketHandlers } from '../../src/engine/connection';
import { CLIENT_REPLY, PacketStream, PacketType, encodePacket, encodeTextArray, fromHex, toHex } from '../../src/engine/packet';
import { useGameStore } from '../../src/store/gameStore';
import { GAMEPLAY_REQUESTS } from '../../src/store/gameplayState';
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
  socket.handlers.onData(encodePacket({
    requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command: 'AskForSkillInvoke',
    data: serverCbor("{'web_test_skill', 'Kích hoạt kỹ năng thử?'}"),
    timestamp, timeout,
  }));
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
  beginRoomPacks: () => {
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
      disabledPack: string[]; mode: string }>(`
      local data = cbor.decode(__host_hex2bin('${packet.hex}'))
      return {roomName = data[1], capacity = data[2], timeout = data[3],
        disabledPack = data[4].disabledPack, mode = data[4].gameMode}
    `);
    const enterRoom = conn.lua.eval<string>(`
      local data = cbor.decode(__host_hex2bin('${packet.hex}'))
      return __host_bin2hex(cbor.encode({data[2], data[3], data[4]}))
    `);
    serverNotify('EnterRoom', fromHex(enterRoom));
    return parsed;
  },
  boardState: () => useGameStore.getState().board,
  boardNotify: (command: string, source: string) => serverNotify(command, serverCbor(source)),
  equipBot: () => {
    const id = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=-1, toArea=Card.PlayerEquip, moveReason=fk.ReasonPut,
      moveInfo={{cardId=${id}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    return id;
  },
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
  beginPlay: (withSkill = false) => {
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
    serverNotify('PrepareDrawPile', serverCbor('Fk.game_modes.new_heg_mode:buildDrawPile()'));
    const cardId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
      return Fk:getCardById(id).trueName == 'slash'
    end)`);
    serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
      moveInfo={{cardId=${cardId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    if (withSkill) {
      const nullification = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
        return Fk:getCardById(id).name == 'heg__nullification'
      end)`);
      serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
        moveInfo={{cardId=${nullification}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
    }
    const id = ++nextId;
    currentSocket().handlers.onData(encodePacket({
      requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'PlayCard', data: serverCbor('{}'), timestamp: Date.now(), timeout: 30,
    }));
    return { id, cardId };
  },
  reconnectSummary: () => {
    api.beginPlay();
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_general', 'ld__bianfuren'}"));
    serverNotify('SetPlayerMark', serverCbor("{17, '__heg_deputy', 'm_heg__dianwei'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'general', 'anjiang'}"));
    serverNotify('PropertyUpdate', serverCbor("{17, 'deputyGeneral', 'anjiang'}"));
    const summary = conn.lua.eval<string>('return __host_bin2hex(cbor.encode(ClientInstance:serialize()))');
    useGameStore.getState().update({ ownId: null });
    conn.connect();
    serverNotify('NetworkDelayTest', encodeTextArray([publicKeyPem]).subarray(1));
    serverNotify('Setup', serverCbor("{17, 'browser-test', 'avatar', 1000}"));
    serverNotify('Reconnect', fromHex(summary));
    return { status: conn.getStatus().kind, phase: useGameStore.getState().phase,
      ownId: useGameStore.getState().ownId, players: useGameStore.getState().board.player,
      seats: useGameStore.getState().board.seats, request: useGameStore.getState().pendingRequest,
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
  finishGame: () => {
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
  const error = useGameStore((s) => s.error);
  const result = useGameStore((s) => s.result);
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
  const roomRun = (action: () => void | Promise<void>) => {
    if (busy) return;
    setBusy(true);
    void Promise.resolve().then(action)
      .catch((e: unknown) => useGameStore.getState().update({ error: String((e as Error).message) }))
      .finally(() => setBusy(false));
  };
  return <main className={`shell ${phase === 'playing' ? 'shell-playing' : ''}`}>
    <h1>TQS real Lua WASM E2E</h1>
    {error && <div className="notice error-notice" role="alert">{error}</div>}
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
    {(!request || GAMEPLAY_REQUESTS.has(request.command)) && <GameBoardScreen busy={busy} leave={() => {}}
      toggleTrust={() => gameAction(() => conn.toggleTrust())}
      dispatch={(kind, id, action, data) => gameAction(() => conn.updateRequestUI(request!.requestId, kind, id, action, data))}
      direct={(id, data) => gameAction(() => conn.finishDirectInteraction(request!.requestId, id, data))} />}
  </main>;
}

createRoot(document.getElementById('root')!).render(<Fixture />);
void boot();
