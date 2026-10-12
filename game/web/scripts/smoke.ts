// Smoke test: boot the FreeKill client Lua inside wasmoon under Node.
//
//   npm run smoke -- [upstream-dir]
//   FK_TEST_USERNAME=... FK_TEST_PASSWORD=... FK_MD5=... npm run smoke:live -- host:port [upstream-dir]
//
// <upstream-dir> must contain freekill-core/, utility/, hegemony/ checkouts.
// Live networking is opt-in. Use an existing test account: the upstream server
// automatically registers unknown usernames during authentication.
import fs from 'node:fs';
import path from 'node:path';
import net from 'node:net';
import assert from 'node:assert/strict';
import forge from 'node-forge';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { CLIENT_NOTIFY, CLIENT_REPLY, PacketStream, PacketType, encodePacket, encodeTextArray, fromHex, toHex } from '../src/engine/packet';
import { useGameStore } from '../src/store/gameStore';

const live = process.argv[2] === '--live';
const target = live ? process.argv[3] : undefined;
const upstream = live ? (process.argv[4] ?? '../../scratch/upstream') : (process.argv[2] ?? '../../scratch/upstream');
if (live && (!target || !process.env.FK_TEST_USERNAME || !process.env.FK_TEST_PASSWORD || !process.env.FK_MD5)) {
  throw new Error('Live test requires host:port and FK_TEST_USERNAME, FK_TEST_PASSWORD, FK_MD5 environment variables');
}

const files = new Map<string, Uint8Array>();
for (const pkg of ['freekill-core', 'utility', 'hegemony']) {
  const root = path.join(upstream, pkg);
  const walk = (d: string) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (e.name === '.git') continue;
      const f = path.join(d, e.name);
      if (e.isDirectory()) walk(f);
      else if (/\.(lua|json)$/i.test(e.name)) {
        files.set(`packages/${pkg}/${path.relative(root, f).split(path.sep).join('/')}`, fs.readFileSync(f));
      }
    }
  };
  walk(root);
}
console.log(`mounted ${files.size} files`);

const t0 = Date.now();

if (!target) {
  const sent: { kind: string; command: string; hex: string }[] = [];
  const uiEvents: { command: string; data: unknown }[] = [];
  const luaErrors: string[] = [];
  const rt = new LuaRuntime({
    files,
    callbacks: {
      send: (kind, command, hex) => sent.push({ kind, command, hex }),
      ui: (command, data) => uiEvents.push({ command, data }),
      setup: () => console.log('setup requested'),
      log: (level, msg) => {
        if (level === 'error') luaErrors.push(msg);
        else console.log(`[lua:${level}] ${msg}`);
      },
    },
  });
  await rt.start();
  console.log(`booted in ${Date.now() - t0} ms`);
  console.log('translate test:', rt.call('Translate', 'slash'), rt.call('Translate', 'caocao'));
  const fileChecks = rt.eval<Record<string, boolean>>(`return {
    utility = FileIO.isDir('packages/utility'),
    hegemony = FileIO.isDir('packages/hegemony'),
    hegemonyInit = FileIO.exists('packages/hegemony/init.lua'),
    initIsNotDir = not FileIO.isDir('packages/hegemony/init.lua'),
    missingIsNotDir = not FileIO.isDir('packages/missing-package'),
    missingDoesNotExist = not FileIO.exists('packages/missing-package'),
  }`);
  assert.deepEqual(fileChecks, {
    utility: true, hegemony: true, hegemonyInit: true,
    initIsNotDir: true, missingIsNotDir: true, missingDoesNotExist: true,
  }, 'FileIO must distinguish extensions, files and missing paths');

  const modes = rt.call<{ orig_name: string }[]>('GetGameModes');
  console.log('modes:', JSON.stringify(modes).slice(0, 400));
  if (!modes.some((mode) => mode.orig_name === 'new_heg_mode')) {
    console.error('Lua package diagnostic:', JSON.stringify(rt.eval(`
      local cwd = FileIO.pwd()
      local dirs = FileIO.ls('packages')
      local hasHegemony = FileIO.exists('packages/hegemony/init.lua')
      local hasUtility = FileIO.exists('packages/utility/init.lua')
      return { cwd = cwd, dirs = dirs, hasHegemony = hasHegemony, hasUtility = hasUtility,
        extensionNames = Fk.extension_names,
        utilityDir = FileIO.isDir('packages/utility'),
        hegemonyDir = FileIO.isDir('packages/hegemony'),
        utilityInit = FileIO.exists('packages/utility/init.lua'),
        hegemonyInit = FileIO.exists('packages/hegemony/init.lua') }
    `)));
    throw new Error('hegemony mode missing from Lua runtime');
  }

  // Exercise actual upstream ClientCallback -> CBOR -> UI and reply bridges.
  const setupHex = rt.eval<string>(`return __host_bin2hex(cbor.encode({17, 'web-smoke', 'liubei', 1000}))`);
  rt.receive('Setup', setupHex, false);
  assert.equal(rt.eval<number>('return Self.id'), 17, 'upstream Setup callback must create Self');

  rt.eval(`
    ClientInstance.callbacks['WebSmokeRequest'] = function(self, data)
      self.client:notifyUI('WebSmokeRequest', {
        action = data[1], length = #data[2], first = data[2]:byte(1), last = data[2]:byte(-1)
      })
      self.client:replyToServer('WebSmokeRequest', cbor.encode(data))
    end
    return true
  `);
  const requestHex = toHex(encodeTextArray(['play-card', Uint8Array.of(0, 255, 1)]));
  rt.receive('WebSmokeRequest', requestHex, true);
  assert.deepEqual(uiEvents.at(-1), {
    command: 'WebSmokeRequest', data: { action: 'play-card', length: 3, first: 0, last: 1 },
  }, 'Lua CBOR request must reach host UI with binary bytes intact');
  assert.equal(sent.at(-1)?.kind, 'reply');
  assert.equal(sent.at(-1)?.command, 'WebSmokeRequest');
  assert.ok(sent.at(-1)?.hex.includes('00ff01'), 'Lua reply must preserve binary data');
  assert.throws(() => rt.call('__missing_web_smoke_function__'), /no such Lua function/,
    'Lua adapter errors must propagate instead of being silently converted to null');
  assert.ok(luaErrors.some((msg) => msg.includes('__missing_web_smoke_function__')));
  console.log('filesystem and Lua CBOR request/reply smoke: PASS');

  // Exercise the browser's actual JSON -> Lua -> CBOR bridge. These packets
  // are consumed by native C++ parsers, which require CBOR text strings.
  const settings = {
    gameMode: 'new_heg_mode', roomName: 'Quốc Chiến thử', password: '',
    _game: {}, _mode: {}, disabledPack: [], disabledGenerals: [],
  };
  assert.equal(rt.call('__web_room_feasible', 'new_heg_mode', 4, 30), true);
  assert.equal(rt.call('__web_room_feasible', 'new_heg_mode', 11, 30), false);
  assert.equal(rt.call('__web_notify', 'CreateRoom', [settings.roomName, 4, 30, settings]), true);
  const created = sent.at(-1);
  assert.equal(created?.command, 'CreateRoom');
  assert.equal(created?.kind, 'notify');
  const parsed = rt.eval<{ name: string; capacity: number; timeout: number; mode: string; room: string }>(`
    local arr = cbor.decode(__host_hex2bin('${created?.hex}'))
    return { name = arr[1], capacity = arr[2], timeout = arr[3],
      mode = arr[4].gameMode, room = arr[4].roomName }
  `);
  assert.deepEqual(parsed, { name: settings.roomName, capacity: 4, timeout: 30,
    mode: 'new_heg_mode', room: settings.roomName });
  assert.equal(created.hex.slice(0, 2), '84', 'CreateRoom must be CBOR array of 4 items');
  assert.equal(parseInt(created.hex.slice(2, 4), 16) >> 5, 3,
    'Native CreateRoom parser only accepts CBOR text for the room name');
  for (const text of ['gameMode', 'new_heg_mode', 'password']) {
    const wire = Buffer.concat([Buffer.from([0x60 + Buffer.byteLength(text)]), Buffer.from(text)]).toString('hex');
    assert.ok(created.hex.includes(wire), `Native room settings must encode ${text} as CBOR text`);
  }
  assert.equal(rt.call<string>('__web_reply_hex', '1'), '4131',
    'Text notifications must restore the byte-string encoder used by gameplay replies');
  console.log('browser CreateRoom Lua bridge smoke: PASS');

  // Real Lua callback -> JS RSA Setup -> CBOR wire packet, without a server
  // account or any production network traffic.
  const keys = forge.pki.rsa.generateKeyPair({ bits: 2048, e: 0x10001 });
  const publicPem = forge.pki.publicKeyToRSAPublicKeyPem(keys.publicKey);
  const sentPackets: Uint8Array[] = [];
  const uiLobbyStatuses: string[] = [];
  const roomUiEvents: string[] = [];
  let socketHandlers!: SocketHandlers;
  let closed = false;
  const conn = new GameConnection({
    files, username: 'local-test', password: 'mật-khẩu-thử', md5: 'local-test-md5',
    uuid: 'local-test-uuid',
    openSocket: (handlers) => {
      socketHandlers = handlers;
      return { send: (bytes) => sentPackets.push(bytes), close: () => { closed = true; } };
    },
    onUi: (command, data) => {
      useGameStore.getState().dispatch(command, data);
      roomUiEvents.push(command);
      if (command === 'EnterLobby') uiLobbyStatuses.push(conn.getStatus().kind);
    },
    onRequest: (request) => useGameStore.getState().update({ pendingRequest: request,
      ...(!request ? { skillInvoke: null, initialGeneral: null } : {}) }),
    log: (level, message) => { if (level === 'error') console.error(`[connection Lua] ${message}`); },
  });
  await conn.start();
  const serverNotify = (command: string, data: Uint8Array) => socketHandlers.onData(encodePacket({
    requestId: -2,
    type: PacketType.NOTIFICATION | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command, data,
  }));
  // Scalar CBOR text value, as produced by FreeKill's NetworkDelayTest.
  serverNotify('NetworkDelayTest', encodeTextArray([publicPem]).subarray(1));
  assert.equal(conn.getStatus().kind, 'authenticating');
  assert.equal(sentPackets.length, 1, 'NetworkDelayTest must produce exactly one Setup');
  const setup = new PacketStream().push(sentPackets[0])[0];
  assert.equal(setup.command, 'Setup');
  assert.equal(setup.type, CLIENT_NOTIFY);
  const decoded = rt.eval<{ username: string; cipherHex: string; md5: string; version: string; uuid: string }>(`
    local p = cbor.decode(__host_hex2bin('${toHex(setup.data)}'))
    return { username = p[1], cipherHex = __host_bin2hex(p[2]), md5 = p[3], version = p[4], uuid = p[5] }
  `);
  assert.equal(decoded.username, 'local-test');
  assert.equal(decoded.md5, 'local-test-md5');
  assert.equal(decoded.version, '0.5.25');
  assert.equal(decoded.uuid, 'local-test-uuid');
  const ciphertext = fromHex(decoded.cipherHex);
  assert.equal(ciphertext.length, 256, 'RSA ciphertext must match 2048-bit server key');
  const decrypted = keys.privateKey.decrypt(String.fromCharCode(...ciphertext), 'RSAES-PKCS1-V1_5');
  assert.match(decrypted.slice(0, 32), /^[0-9a-f]{32}$/);
  assert.equal(forge.util.decodeUtf8(decrypted.slice(32)), 'mật-khẩu-thử');

  const serverSetup = rt.eval<string>(`return __host_bin2hex(cbor.encode({17, 'local-test', 'avatar', 1000}))`);
  serverNotify('Setup', fromHex(serverSetup));
  assert.equal(conn.lua.eval<number>('return Self.id'), 17);
  // Lobby::addPlayer passes "", but ServerPlayer::doNotify replaces it
  // with the single CBOR null byte (0xF6) before Router::notify sends it.
  serverNotify('EnterLobby', Uint8Array.of(0xf6));
  assert.deepEqual(uiLobbyStatuses, ['authenticating'], 'Lua must notify UI before online status is committed');
  assert.equal(conn.getStatus().kind, 'online');

  // Server fixture exercises real upstream ClientCallback, the room-specific
  // ClientInstance, and the same Zustand reducer used by the browser UI.
  const serverCbor = (expr: string) => fromHex(rt.eval<string>(
    `return __host_bin2hex(cbor.encode(${expr}))`,
  ));
  // The real C++ server does not echo the joining player's AddPlayer.
  // EnterRoom creates Self in Lua; the bridge must publish that occupant.
  serverNotify('EnterRoom', serverCbor("{4, 30, {gameMode='new_heg_mode', roomName='Browser room', disabledPack={}, disabledGenerals={}, _game={}, _mode={}}}"));
  assert.equal(useGameStore.getState().phase, 'room');
  assert.equal(useGameStore.getState().roomMode, 'new_heg_mode');
  assert.equal(useGameStore.getState().players.find((p) => p.id === 17)?.name, 'local-test');
  serverNotify('RoomOwner', serverCbor('{17}'));
  serverNotify('AddPlayer', serverCbor("{-1, 'Bot', 'avatar', false, 0}"));
  assert.equal(useGameStore.getState().players.length, 2);
  assert.equal(useGameStore.getState().players.find((p) => p.id === 17)?.owner, true);
  serverNotify('ReadyChanged', serverCbor('{17, true}'));
  assert.equal(useGameStore.getState().players.find((p) => p.id === 17)?.ready, true);
  serverNotify('StartGame', Uint8Array.of(0xf6));
  assert.equal(useGameStore.getState().phase, 'playing');
  serverNotify('GameOver', serverCbor("'17'"));
  assert.equal(useGameStore.getState().phase, 'room');
  serverNotify('EnterLobby', Uint8Array.of(0xf6));
  assert.equal(useGameStore.getState().phase, 'lobby');
  assert.equal(useGameStore.getState().players.length, 0);
  for (const event of ['EnterRoom', 'RoomOwner', 'AddPlayer', 'ReadyChanged', 'StartGame', 'GameOver']) {
    assert.ok(roomUiEvents.includes(event), `upstream Lua must emit ${event} to the web store`);
  }
  console.log('offline Lua room/bot/game lifecycle and Zustand smoke: PASS');

  // Native choice dialogs bypass RequestHandler and reach notifyUI directly.
  // Exercise their actual callback, request guards and Lua CBOR array reply.
  const choicePacket = (id: number, timeout = 30, timestamp = Date.now()) => socketHandlers.onData(encodePacket({
    requestId: id, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command: 'AskForChoices', timeout, timestamp,
    data: serverCbor("{{'main', 'deputy'}, {'main', 'deputy', 'disabled'}, {1, 2}, true, 'reveal', 'Choose generals', false, false}"),
  }));
  choicePacket(81);
  assert.deepEqual(useGameStore.getState().pendingRequest?.choicePrompt?.choices, ['main', 'deputy']);
  const beforeChoices = sentPackets.length;
  for (const invalid of [['disabled'], ['main', 'main'], ['main', 'deputy', 'disabled']])
    assert.throws(() => conn.respondToChoices(81, invalid), /không được máy chủ cho phép/);
  assert.equal(sentPackets.length, beforeChoices);
  conn.respondToChoices(81, ['main', 'deputy']);
  const choiceReply = new PacketStream().push(sentPackets.at(-1)!)[0];
  assert.equal(choiceReply.requestId, 81);
  assert.equal(choiceReply.type, CLIENT_REPLY);
  assert.deepEqual(rt.eval(`return cbor.decode(__host_hex2bin('${toHex(choiceReply.data)}'))`), ['main', 'deputy']);
  assert.throws(() => conn.respondToChoices(81, ['main']), /không còn hiệu lực/);
  choicePacket(82);
  choicePacket(83);
  assert.throws(() => conn.respondToChoices(82, ['main']), /không còn hiệu lực/);
  conn.respondToChoices(83, []);
  assert.equal(toHex(new PacketStream().push(sentPackets.at(-1)!)[0].data), '80', 'Cancel is an empty CBOR array');
  choicePacket(84, 1, Date.now() - 5000);
  const beforeExpiredChoice = sentPackets.length;
  assert.throws(() => conn.respondToChoices(84, ['main']), /hết thời gian/);
  assert.equal(sentPackets.length, beforeExpiredChoice);
  console.log('real Lua AskForChoices validation/array reply smoke: PASS');

  // Actual PlayCard handler: native room/draw/move events build the Lua hand,
  // then user actions select a real Slash and its target before replying.
  serverNotify('EnterRoom', serverCbor("{2, 30, {gameMode='new_heg_mode', roomName='Card fixture', disabledPack={}, disabledGenerals={}, _game={}, _mode={}}}"));
  serverNotify('AddPlayer', serverCbor("{-1, 'Bot', 'avatar', true, 0}"));
  serverNotify('StartGame', Uint8Array.of(0xf6));
  serverNotify('ArrangeSeats', serverCbor('{17, -1}'));
  for (const id of [17, -1]) {
    serverNotify('PropertyUpdate', serverCbor(`{${id}, 'hp', 4}`));
    serverNotify('PropertyUpdate', serverCbor(`{${id}, 'maxHp', 4}`));
  }
  serverNotify('PropertyUpdate', serverCbor("{17, 'phase', Player.Play}"));
  serverNotify('PrepareDrawPile', fromHex(conn.lua.eval<string>(
    'return __host_bin2hex(cbor.encode(Fk.game_modes.new_heg_mode:buildDrawPile()))',
  )));
  const slashId = conn.lua.eval<number>(`return table.find(ClientInstance.draw_pile, function(id)
    return Fk:getCardById(id).trueName == 'slash'
  end)`);
  assert.ok(Number.isInteger(slashId), 'The native Hegemony draw-pile list must contain a Slash');
  serverNotify('MoveCards', serverCbor(`{{{to=17, toArea=Card.PlayerHand, moveReason=fk.ReasonDraw,
    moveInfo={{cardId=${slashId}, fromArea=Card.DrawPile}}, moveVisible=true}}, 1}`));
  assert.deepEqual(conn.lua.eval('return Self:getCardIds("h")'), [slashId]);
  assert.equal(useGameStore.getState().board.player[17]?.handcardNum, 1);
  assert.equal(useGameStore.getState().board.player[-1]?.handcardNum, 0);
  socketHandlers.onData(encodePacket({
    requestId: 85, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command: 'PlayCard', data: serverCbor('{}'), timeout: 30, timestamp: Date.now(),
  }));
  assert.equal(conn['gameplayScene'].items.CardItem[String(slashId)]?.enabled, true);
  const beforeCard = sentPackets.length;
  conn.updateRequestUI(85, 'CardItem', slashId, 'click', { selected: true });
  assert.equal(conn['gameplayScene'].items.Photo['-1']?.enabled, true);
  assert.throws(() => conn.updateRequestUI(85, 'Button', 'OK', 'click', null), /Lua cho phép/);
  conn.updateRequestUI(85, 'Photo', -1, 'click', { selected: true });
  assert.equal(sentPackets.length, beforeCard, 'Selecting a card/target alone cannot reply');
  conn.updateRequestUI(85, 'Button', 'OK', 'click', null);
  const played = new PacketStream().push(sentPackets.at(-1)!)[0];
  assert.equal(played.requestId, 85);
  assert.equal(played.type, CLIENT_REPLY);
  assert.deepEqual(rt.eval(`return cbor.decode(__host_hex2bin('${toHex(played.data)}'))`),
    { card: slashId, targets: [-1] });
  assert.throws(() => conn.updateRequestUI(85, 'Button', 'OK', 'click', null), /không còn hiệu lực/);
  serverNotify('EnterLobby', Uint8Array.of(0xf6));
  console.log('real Lua PlayCard Slash/card/target/OK/CBOR reply smoke: PASS');

  // Run the actual FreeKill ReqInvoke handler inside Wasmoon: request packet
  // -> ClientCallback/CancelRequest -> handler -> button -> CBOR CLIENT_REPLY.
  const skillPacket = (requestId: number, timeout = 30, timestamp = Date.now()) => {
    socketHandlers.onData(encodePacket({
      requestId, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
      command: 'AskForSkillInvoke',
      data: serverCbor("{'web_test_skill', 'Kích hoạt kỹ năng thử?'}"), timeout, timestamp,
    }));
  };
  const assertSkillReply = (requestId: number, value: string) => {
    const bytes = sentPackets.at(-1);
    assert.ok(bytes);
    const packet = new PacketStream().push(bytes)[0];
    assert.equal(packet.type, PacketType.REPLY | PacketType.SRC_CLIENT | PacketType.DEST_SERVER);
    assert.equal(packet.command, '');
    assert.equal(packet.requestId, requestId);
    // Verify the exact bytes emitted by Lua cbor.encode(string): byte string,
    // not the text string representation used by many JS CBOR libraries.
    assert.deepEqual([...packet.data], [value.length === 1 ? 0x41 : 0x48,
      ...new TextEncoder().encode(value)]);
    assert.equal(rt.eval<string>(`return cbor.decode(__host_hex2bin('${toHex(packet.data)}'))`), value);
  };
  skillPacket(71);
  assert.equal(conn.getStatus().kind, 'online');
  assert.deepEqual(useGameStore.getState().skillInvoke,
    { skill: 'web_test_skill', prompt: 'Kích hoạt kỹ năng thử?' });
  assert.equal(useGameStore.getState().pendingRequest?.requestId, 71,
    'upstream CancelRequest must not clear the newly opened request');
  const beforeReply = sentPackets.length;
  conn.lua.eval(`ClientInstance:notifyUI('ReplyToServer', '1'); return true`);
  assert.equal(sentPackets.length, beforeReply, 'Lua event alone must not reply');
  conn.respondToSkillInvoke(71, 'OK');
  assert.equal(sentPackets.length, beforeReply + 1);
  assertSkillReply(71, '1');
  assert.equal(useGameStore.getState().pendingRequest, null);
  assert.equal(useGameStore.getState().skillInvoke, null);
  assert.throws(() => conn.respondToSkillInvoke(71, 'OK'), /không còn hiệu lực/);

  skillPacket(72);
  conn.respondToSkillInvoke(72, 'Cancel');
  assertSkillReply(72, '__cancel');

  skillPacket(73);
  const beforeReplacement = sentPackets.length;
  skillPacket(74);
  assert.equal(useGameStore.getState().pendingRequest?.requestId, 74);
  assert.throws(() => conn.respondToSkillInvoke(73, 'OK'), /không còn hiệu lực/);
  assert.equal(sentPackets.length, beforeReplacement, 'superseded request must never reply');
  conn.respondToSkillInvoke(74, 'OK');
  assertSkillReply(74, '1');

  skillPacket(75, 1, Date.now() - 5000);
  const beforeExpired = sentPackets.length;
  assert.throws(() => conn.respondToSkillInvoke(75, 'OK'), /hết thời gian/);
  assert.equal(sentPackets.length, beforeExpired);
  assert.equal(useGameStore.getState().pendingRequest, null);

  // Real Hegemony CustomDialog and the FreeKill engine's own pair/kingdom
  // validation, followed by the browser's authorized CBOR CLIENT_REPLY.
  const pair = rt.eval<{ main: string; deputy: string; kingdom: string }>(`
    local enabled = {'wei', 'shu', 'wu', 'qun', 'jin'}
    for main, g in pairs(Fk.generals) do
      if g.kingdom ~= 'wild' then
        for deputy in pairs(Fk.generals) do
          local kingdoms = __web_general_kingdoms(main, deputy, enabled)
          if #kingdoms == 1 then
            return {main = main, deputy = deputy, kingdom = kingdoms[1]}
          end
        end
      end
    end
    error('No real Hegemony pair with one valid kingdom')
  `);
  const enabledKingdoms = ['wei', 'shu', 'wu', 'qun', 'jin'];
  assert.deepEqual(rt.call('__web_general_kingdoms', pair.main, pair.deputy, enabledKingdoms),
    [pair.kingdom], 'the real Hegemony engine must validate the selected pair');
  assert.deepEqual(rt.call('__web_general_kingdoms', pair.main, pair.deputy, ['disabled']), [],
    'disabled kingdom must be rejected');
  assert.deepEqual(rt.call('__web_general_kingdoms', pair.main, pair.main, enabledKingdoms), [],
    'duplicate main and deputy must be rejected');
  const labels = rt.call<string[]>('__web_general_labels', [pair.main, pair.deputy]);
  assert.equal(labels.length, 2, 'Lua translations must serialize as a JS string array');

  const generalReplyHex = rt.call<string>('__web_general_reply_hex',
    pair.main, pair.deputy, pair.kingdom, enabledKingdoms);
  assert.deepEqual(rt.eval<string[]>(`
    return cbor.decode(__host_hex2bin('${generalReplyHex}'))
  `), [`${pair.main},${pair.deputy}`, `kingdom,${pair.kingdom}`],
  'the server must receive a CBOR array of two comma-delimited strings');
  assert.throws(() => rt.call('__web_general_reply_hex', pair.main, pair.main,
    pair.kingdom, enabledKingdoms), /invalid hegemony general pair/);

  // Discover special cases from the mounted upstream extensions, rather than
  // assuming every named expansion general is present in this runtime.
  type PairFixture = { main: string; deputy: string; kingdoms: string[] };
  const edge = rt.eval<{
    available: { wild: number; subkingdom: number; mouxusheng: boolean };
    wildMain?: PairFixture; wildDeputy?: PairFixture; subkingdom?: PairFixture;
    multiKingdom?: PairFixture; incompatible?: PairFixture; mouException?: PairFixture;
  }>(`
    local enabled = {'wei', 'shu', 'wu', 'qun', 'jin'}
    local out = { available = { wild = 0, subkingdom = 0,
      mouxusheng = Fk.generals['mouxusheng'] ~= nil } }
    for _, g in pairs(Fk.generals) do
      if g.kingdom == 'wild' then out.available.wild = out.available.wild + 1 end
      if g.subkingdom then out.available.subkingdom = out.available.subkingdom + 1 end
    end
    for main, g in pairs(Fk.generals) do
      for deputy, d in pairs(Fk.generals) do
        if main ~= deputy then
          local kingdoms = __web_general_kingdoms(main, deputy, enabled)
          local fixture = {main = main, deputy = deputy, kingdoms = kingdoms}
          if not out.wildMain and g.kingdom == 'wild' and #kingdoms > 0 then
            out.wildMain = fixture
          end
          if not out.wildDeputy and d.kingdom == 'wild' and g.kingdom ~= 'wild' then
            out.wildDeputy = fixture
          end
          if not out.subkingdom and #kingdoms > 0 and
             (g.subkingdom or d.subkingdom) then out.subkingdom = fixture end
          if not out.multiKingdom and #kingdoms > 1 then out.multiKingdom = fixture end
          if not out.incompatible and g.kingdom ~= 'wild' and d.kingdom ~= 'wild' and
             not Fk:canMatchInHegemony(main, deputy, enabled) then
            out.incompatible = fixture
          end
          if not out.mouException and (main == 'mouxusheng' or deputy == 'mouxusheng')
             and Fk:canMatchInHegemony(main, deputy, enabled) and #kingdoms == 0 then
            out.mouException = fixture
          end
        end
      end
    end
    return out
  `);
  assert.ok(edge.incompatible, 'the installed generals must include an incompatible pair');
  assert.deepEqual(rt.call('__web_general_kingdoms', edge.incompatible!.main,
    edge.incompatible!.deputy, enabledKingdoms), []);
  if (edge.available.wild) {
    assert.ok(edge.wildMain && edge.wildDeputy, 'wild main/deputy cases must be discoverable');
    assert.ok(edge.wildMain!.kingdoms.length > 0);
    assert.deepEqual(rt.call('__web_general_kingdoms', edge.wildDeputy!.main,
      edge.wildDeputy!.deputy, enabledKingdoms), [], 'wild deputy must be invalid');
    assert.deepEqual(rt.call('__web_general_kingdoms', edge.wildMain!.main,
      edge.wildMain!.deputy, ['disabled']), [], 'wild main must respect enabled kingdoms');
  }
  if (edge.available.subkingdom) {
    assert.ok(edge.subkingdom, 'mounted subkingdom generals must have a compatible pair');
    const special = edge.subkingdom!;
    assert.deepEqual(rt.call('__web_general_kingdoms', special.main, special.deputy,
      enabledKingdoms), special.kingdoms);
  }
  if (edge.multiKingdom) {
    const special = edge.multiKingdom;
    assert.ok(special.kingdoms.length > 1);
    assert.deepEqual(rt.call('__web_general_kingdoms', special.main, special.deputy,
      [special.kingdoms[0]]), [], 'Lua rejects a partial enabled-kingdom list');
    const extraHex = rt.call<string>('__web_general_reply_hex', special.main,
      special.deputy, special.kingdoms[1], enabledKingdoms);
    assert.deepEqual(rt.eval<string[]>(
      `return cbor.decode(__host_hex2bin('${extraHex}'))`,
    ), [`${special.main},${special.deputy}`, `kingdom,${special.kingdoms[1]}`]);
  }
  if (edge.mouException) {
    assert.deepEqual(rt.call('__web_general_kingdoms', edge.mouException.main,
      edge.mouException.deputy, enabledKingdoms), [],
    'mouxusheng nominal match without a shared kingdom must be rejected');
  }
  console.log('real Hegemony special-case fixtures: PASS', JSON.stringify({
    available: edge.available, wildMain: !!edge.wildMain,
    wildDeputy: !!edge.wildDeputy, subkingdom: !!edge.subkingdom,
    multipleKingdoms: !!edge.multiKingdom, mouException: !!edge.mouException,
  }));

  const dialogHex = rt.eval<string>(`
    return __host_bin2hex(cbor.encode({component = {
      name = 'ChooseInitialGeneralBox', model = {
        name = 'ChooseInitialGeneralModel', prop = {
          hegemony = true, choiceNum = 2,
          generals = {${JSON.stringify(pair.main)}, ${JSON.stringify(pair.deputy)}},
          enabledKingdoms = {'wei', 'shu', 'wu', 'qun', 'jin'}
        }
      }
    }}))
  `);
  const customPacket = (requestId: number) => socketHandlers.onData(encodePacket({
    requestId, type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command: 'CustomDialog', data: fromHex(dialogHex), timeout: 30, timestamp: Date.now(),
  }));
  customPacket(77);
  assert.equal(useGameStore.getState().pendingRequest?.requestId, 77);
  assert.deepEqual(useGameStore.getState().initialGeneral?.generals, [pair.main, pair.deputy],
    'upstream CustomDialog must populate the browser general selector');
  assert.deepEqual(conn.getInitialGeneralKingdoms(77, pair.main, pair.deputy), [pair.kingdom]);
  const beforeGeneralReply = sentPackets.length;
  assert.throws(() => conn.respondToInitialGeneral(77, pair.main, pair.deputy, 'disabled'),
    /không hợp lệ/);
  assert.equal(sentPackets.length, beforeGeneralReply);
  conn.respondToInitialGeneral(77, pair.main, pair.deputy, pair.kingdom);
  assert.equal(sentPackets.length, beforeGeneralReply + 1);
  const generalReply = new PacketStream().push(sentPackets.at(-1)!)[0];
  assert.equal(generalReply.requestId, 77);
  assert.equal(generalReply.type, PacketType.REPLY | PacketType.SRC_CLIENT | PacketType.DEST_SERVER);
  assert.equal(generalReply.command, '');
  assert.equal(toHex(generalReply.data), generalReplyHex);
  assert.equal(useGameStore.getState().initialGeneral, null);
  customPacket(78);
  customPacket(79);
  assert.throws(() => conn.respondToInitialGeneral(78, pair.main, pair.deputy, pair.kingdom),
    /không còn hiệu lực/);
  conn.lua.eval(`ClientInstance:notifyUI('CancelRequest'); return true`);
  assert.throws(() => conn.respondToInitialGeneral(79, pair.main, pair.deputy, pair.kingdom),
    /không còn hiệu lực/);
  assert.equal(sentPackets.length, beforeGeneralReply + 1);
  console.log(`actual Wasmoon CustomDialog Hegemony and CBOR general selection: PASS (${pair.main}/${pair.deputy})`);

  skillPacket(76);
  const beforeClose = sentPackets.length;
  conn.close();
  assert.throws(() => conn.respondToSkillInvoke(76, 'Cancel'), /không còn hiệu lực/);
  assert.equal(sentPackets.length, beforeClose);
  assert.equal(useGameStore.getState().pendingRequest, null);
  console.log('actual Wasmoon ReqInvoke OK/Cancel/request lifecycle and CBOR reply: PASS');

  assert.equal(closed, true);
  assert.equal(conn.getStatus().kind, 'closed');
  conn.lua.close();
  console.log('offline RSA handshake and Lua EnterLobby smoke: PASS');

  rt.close();
  process.exit(0);
}

const [host, port] = target.split(':');
let finished = false;
let receivedLobbyUi = false;
let timeout: ReturnType<typeof setTimeout>;
const finish = (passed: boolean, reason: string) => {
  if (finished) return;
  finished = true;
  clearTimeout(timeout);
  console.log(`live authentication smoke: ${passed ? 'PASS' : 'FAIL'} (${reason})`);
  conn.close();
  process.exitCode = passed ? 0 : 1;
};
const conn = new GameConnection({
  files,
  username: process.env.FK_TEST_USERNAME!,
  password: process.env.FK_TEST_PASSWORD!,
  md5: process.env.FK_MD5!,
  uuid: 'web-smoke-0001',
  openSocket: (h) => {
    const s = net.createConnection({ host, port: Number(port) });
    s.on('data', (b) => h.onData(new Uint8Array(b)));
    s.on('close', () => h.onClose('tcp closed'));
    s.on('error', (e) => h.onClose(e.message));
    return { send: (b) => s.write(b), close: () => s.destroy() };
  },
  onUi: (c) => {
    console.log('ui', c);
    if (c === 'EnterLobby') receivedLobbyUi = true;
  },
  onStatus: (s) => {
    console.log('status', s);
    if (s.kind === 'online' && receivedLobbyUi) finish(true, 'server EnterLobby processed by Lua');
    if (s.kind === 'closed') finish(false, s.reason);
  },
});
await conn.start();
if (!finished) timeout = setTimeout(() => finish(false, 'timed out before EnterLobby'), 15000);
