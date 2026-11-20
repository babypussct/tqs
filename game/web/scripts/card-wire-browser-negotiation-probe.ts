// Browser-side candidate probe. It mounts the isolated candidate package
// trees in Wasmoon, boots the real Lua client through LuaRuntime, and feeds
// the negotiated envelope through the actual ClientCallback entrypoint.
// Native C++/browser UI/network acceptance remains a separate gate.
import assert from 'node:assert/strict';
import path from 'node:path';
import { loadUpstreamFiles } from './upstream-packages';
import { LuaRuntime } from '../src/engine/luaRuntime';

const upstreamRoot = process.argv[2];
if (!upstreamRoot) throw new Error('candidate package root required');

const files = loadUpstreamFiles(path.resolve(upstreamRoot), undefined, {
  // The candidate checkout already contains the reviewed declaration repair;
  // applying the browser harness repair a second time would be a false
  // source-drift failure.
  patchDeclarations: false,
});
// LuaRuntime mounts the package at the same root used by the browser harness,
// while this candidate's bootstrap also searches the legacy `lua/` prefix.
// Mirror the reviewed candidate-only modules under that prefix so the probe
// exercises their bytes through the real `require` path rather than relying on
// a test-only loader or a production-tree copy.
for (const name of [
  'card_wire_refs', 'card_wire_negotiation', 'card_wire_deck',
  'card_wire_area', 'card_wire_moves', 'card_wire_requests',
  'card_wire_snapshots', 'card_wire_public',
]) {
  const source = files.get(`packages/freekill-core/ltk/client/${name}.lua`);
  assert(source, `candidate client module missing: ${name}`);
  files.set(`ltk/client/${name}.lua`, source);
  files.set(`packages/freekill-core/lua/ltk/client/${name}.lua`, source);
  files.set(`lua/ltk/client/${name}.lua`, source);
}
const uiEvents: Array<{ command: string; data: unknown }> = [];
const luaErrors: string[] = [];
const sentPackets: Array<{ kind: string; command: string; hex: string }> = [];
const runtime = new LuaRuntime({
  files,
  callbacks: {
    send: (kind, command, hex) => sentPackets.push({ kind, command, hex }),
    ui: (command, data) => uiEvents.push({ command, data }),
    setup: () => {},
    log: (level, message) => { if (level === 'error') luaErrors.push(message); },
  },
});

await runtime.start();
try {
  const setupHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    17, 'card-wire-browser-probe', 'avatar', 1000
  }))`);
  runtime.receive('Setup', setupHex, false);
  const enterRoomHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    4, 30, {gameMode = 'new_heg_mode', roomName = 'TQS card-wire browser probe',
      disabledPack = {}, disabledGenerals = {}, _game = {}, _mode = {}}
  }))`);
  runtime.receive('EnterRoom', enterRoomHex, false);
  const startGameHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({}))`);
  runtime.receive('StartGame', startGameHex, false);
  const addPlayerHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    2, 'opponent', 'avatar', false, 0
  }))`);
  runtime.receive('AddPlayer', addPlayerHex, false);
  const arrangeSeatsHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({17, 2}))`);
  runtime.receive('ArrangeSeats', arrangeSeatsHex, false);
  const capabilityPacket = sentPackets.find((packet) =>
    packet.kind === 'notify' && packet.command === 'PushRequest');
  assert(capabilityPacket, 'candidate client did not advertise card-wire capability');
  assert.equal(runtime.eval<string>(
    `return cbor.decode(__host_hex2bin('${capabilityPacket.hex}'))`,
  ), 'card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode');
  const envelopeHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    protocol = 'TQS_HEG_CARD_WIRE', cardWireVersion = 1, mode = 'new_heg_mode'
  }))`);
  runtime.receive('CardWireNegotiated', envelopeHex, false);
  const activated = runtime.eval<{
    version: number;
    protocol: string;
    negotiated: boolean;
  }>(`return {
    version = ClientInstance.card_wire_version,
    protocol = ClientInstance.card_wire_protocol,
    negotiated = ClientInstance.card_wire_negotiated,
  }`);
  assert.deepEqual(activated, {
    version: 1,
    protocol: 'TQS_HEG_CARD_WIRE',
    negotiated: true,
  });
  assert.equal(uiEvents.some((event) => event.command === 'CardWireNegotiated'), false,
    'negotiation must not reach the browser UI callback');

  // A negotiated session may not silently switch protocol when a malformed,
  // unsupported or differently-modeled envelope arrives later.  Exercise the
  // real ClientCallback boundary with each negative variant and verify that
  // the already-negotiated session remains v1 after every rejection.
  const rejectedNegotiation = (expression: string, expected: RegExp) => {
    const packetHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode(${expression}))`);
    assert.throws(() => runtime.receive('CardWireNegotiated', packetHex, false), expected);
    assert.deepEqual(runtime.eval(`return {
      version = ClientInstance.card_wire_version,
      protocol = ClientInstance.card_wire_protocol,
      negotiated = ClientInstance.card_wire_negotiated,
    }`), {
      version: 1,
      protocol: 'TQS_HEG_CARD_WIRE',
      negotiated: true,
    });
  };
  rejectedNegotiation("{ protocol = 'TQS_HEG_CARD_WIRE', cardWireVersion = 2, mode = 'new_heg_mode' }",
    /unsupported card wire negotiation version/u);
  rejectedNegotiation("{ protocol = 'OTHER_CARD_WIRE', cardWireVersion = 1, mode = 'new_heg_mode' }",
    /unsupported card wire negotiation protocol/u);
  rejectedNegotiation("{ protocol = 'TQS_HEG_CARD_WIRE', cardWireVersion = 1, mode = 'classic_mode' }",
    /restricted to Hegemony/u);

  const malformedHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    protocol = 'TQS_HEG_CARD_WIRE', cardWireVersion = 1,
    mode = 'new_heg_mode', cardId = 101,
  }))`);
  assert.throws(() => runtime.receive('CardWireNegotiated', malformedHex, false),
    /unaudited field/u);

  const requestHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    protocol = 'TQS_HEG_CARD_WIRE', cardWireVersion = 1, mode = 'new_heg_mode'
  }))`);
  assert.throws(() => runtime.receive('CardWireNegotiated', requestHex, true),
    /must be a notification/u);

  const prepareHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({count = 3}))`);
  runtime.receive('PrepareDrawPile', prepareHex, false);
  const firstDeck = runtime.eval<{ ids: number[]; anonymous: boolean[] }>(`local ids = {}
    local anonymous = {}
    for i, id in ipairs(ClientInstance.draw_pile) do
      ids[i] = id
      anonymous[i] = ClientInstance.card_wire_refs:isAnonymous(id)
    end
    return {ids = ids, anonymous = anonymous}`);
  assert.equal(firstDeck.ids.length, 3);
  assert.deepEqual(firstDeck.anonymous, [true, true, true]);

  const syncHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({count = 2}))`);
  runtime.receive('SyncDrawPile', syncHex, false);
  const secondDeck = runtime.eval<{ ids: number[]; oldAnonymous: boolean[]; oldWireRejected: boolean[] }>(`local ids = {}
    local oldAnonymous = {}
    local oldWireRejected = {}
    for i, id in ipairs(ClientInstance.draw_pile) do
      ids[i] = id
      oldAnonymous[i] = ClientInstance.card_wire_refs:isAnonymous(${firstDeck.ids[0]})
      local ok = pcall(function() ClientInstance.card_wire_refs:toWire(${firstDeck.ids[0]}) end)
      oldWireRejected[i] = not ok
    end
    return {ids = ids, oldAnonymous = oldAnonymous, oldWireRejected = oldWireRejected}`);
  assert.equal(secondDeck.ids.length, 2);
  assert.notDeepEqual(secondDeck.ids, firstDeck.ids.slice(0, 2),
    'count-only sync must replace prior anonymous positions');
  assert.deepEqual(secondDeck.oldAnonymous, [false, false]);
  assert.deepEqual(secondDeck.oldWireRejected, [true, true]);

  const moveHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    {
      {
        toArea = 7, moveVisible = true, drawPilePosition = 1,
        moveInfo = {
          {cardId = 101, fromArea = 6},
        },
      },
    },
    9003,
  }))`);
  runtime.receive('MoveCards', moveHex, false);
  const moved = runtime.eval<{ drawCount: number; discard: number[]; area: number }>(`return {
    drawCount = #ClientInstance.draw_pile,
    discard = ClientInstance.discard_pile,
    area = ClientInstance.card_place[101],
  }`);
  assert.equal(moved.drawCount, 1);
  assert.deepEqual(moved.discard, [101]);
  assert.equal(moved.area, 7);

  const changeAreaHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    count = 1, area = 7, areaCount = 1, areaRefs = {101}
  }))`);
  runtime.receive('ChangeCardArea', changeAreaHex, false);
  const publicArea = runtime.eval<{ discard: number[]; area: number }>(`return {
    discard = ClientInstance.discard_pile,
    area = ClientInstance.card_place[101],
  }`);
  assert.deepEqual(publicArea.discard, [101]);
  assert.equal(publicArea.area, 7);

  const requestToken = 'h:browser_request_token_0001';
  const requestStanding = 'h:browser_request_standing_0001';
  runtime.eval(`ClientInstance.callbacks.AskForAG = function(_, data)
    ClientInstance.__browser_probe_ag = data
  end
  return true`);
  const requestEnvelopeHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    cardWireVersion = 1,
    payload = {{'${requestToken}'}, false, 'browser-request'},
    choices = {{token = '${requestToken}', standing = '${requestStanding}'}},
  }))`);
  runtime.receive('AskForAG', requestEnvelopeHex, false);
  const requestLocal = runtime.eval<number>(`return ClientInstance.__browser_probe_ag[1][1]`);
  assert.equal(typeof requestLocal, 'number');
  assert.equal(runtime.eval<boolean>(`return ClientInstance.card_wire_request ~= nil`), true);
  runtime.call('ReplyToServer', requestLocal);
  const requestReply = sentPackets.at(-1);
  assert(requestReply, 'request reply was not sent through the Lua transport');
  assert.equal(requestReply.kind, 'reply');
  assert.equal(requestReply.command, '');
  const requestReplyWire = runtime.eval<string>(
    `return cbor.decode(__host_hex2bin('${requestReply.hex}'))`,
  );
  assert.equal(requestReplyWire, requestToken);
  assert.equal(runtime.eval<boolean>(`return ClientInstance.card_wire_request == nil`), true);

  const reconnectHidden = 'h:browser_reconnect_hand_0001';
  const reconnectPile = 'h:browser_reconnect_pile_0001';
  const reconnectMark = 'h:browser_reconnect_mark_0001';
  runtime.eval(`ClientInstance.callbacks.Reconnect = function(_, data)
    ClientInstance.__browser_probe_reconnect = data
  end
  return true`);
  const reconnectHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    cardWireVersion = 1,
    payload = {
      settings = {gameMode = 'new_heg_mode'},
      card_manager = {
        draw_pile = {count = 2}, discard_pile = {101},
        processing_area = {}, void = {}, printed_cards = {},
        card_marks = cbor.encode({
          ['${reconnectMark}'] = {visible = true}, [101] = {public = 1},
        }),
      },
      players = {
        [2] = {
          player_cards = {[1] = {'${reconnectHidden}'}, [2] = {101}, [3] = {}},
          special_cards = {['$secret'] = {'${reconnectPile}'}, public = {101}},
          virtual_equips = {},
        },
      },
    },
  }))`);
  runtime.receive('Reconnect', reconnectHex, false);
  const reconnectState = runtime.eval<{
    drawCount: number;
    anonymous: boolean;
    discard: number[];
    hand: number;
    pile: number;
    publicMark: boolean;
  }>(`local data = ClientInstance.__browser_probe_reconnect
    local marks = cbor.decode(data.card_manager.card_marks)
    return {
      drawCount = #data.card_manager.draw_pile,
      anonymous = ClientInstance.card_wire_refs:isAnonymous(data.card_manager.draw_pile[1]),
      discard = data.card_manager.discard_pile,
      hand = data.players[2].player_cards[1][1],
      pile = data.players[2].special_cards['$secret'][1],
      publicMark = marks[101] ~= nil,
    }`);
  assert.equal(reconnectState.drawCount, 2);
  assert.equal(reconnectState.anonymous, true);
  assert.deepEqual(reconnectState.discard, [101]);
  assert.equal(runtime.eval<boolean>(
    `return ClientInstance.card_wire_refs:isHiddenLocal(${reconnectState.hand})`,
  ), true);
  assert.equal(runtime.eval<boolean>(`return ClientInstance.card_wire_refs:isHiddenLocal(${reconnectState.pile})`), true);
  assert.equal(reconnectState.publicMark, true);
  assert.throws(() => runtime.eval(`return ClientInstance.card_wire_refs:toWire(${requestLocal})`));

  const observeHidden = 'h:browser_observe_hand_0001';
  runtime.eval(`ClientInstance.callbacks.Observe = function(_, data)
    ClientInstance.__browser_probe_observe = data
  end
  return true`);
  const observeHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    cardWireVersion = 1,
    payload = {
      settings = {gameMode = 'new_heg_mode'},
      card_manager = {
        draw_pile = {count = 1}, discard_pile = {},
        processing_area = {}, void = {}, printed_cards = {},
      },
      players = {
        [2] = {
          player_cards = {[1] = {'${observeHidden}'}, [2] = {}, [3] = {}},
          special_cards = {['$secret'] = {}, public = {}},
          virtual_equips = {},
        },
      },
    },
  }))`);
  runtime.receive('Observe', observeHex, false);
  const observeState = runtime.eval<{ count: number; hidden: number }>(`local data = ClientInstance.__browser_probe_observe
    return {
      count = #data.card_manager.draw_pile,
      hidden = data.players[2].player_cards[1][1],
    }`);
  assert.equal(observeState.count, 1);
  assert.equal(runtime.eval<boolean>(`return ClientInstance.card_wire_refs:isHiddenLocal(${observeState.hidden})`), true);

  runtime.eval(`ClientInstance.callbacks.ShowVirtualCard = function(_, data)
    ClientInstance.__browser_probe_show_virtual = data
  end
  return true`);
  const showVirtualHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    cardWireVersion = 1,
    payload = {
      {{
        cardWireCard = 1, kind = 'real', ref = 101,
      }, {
        cardWireCard = 1, kind = 'virtual', name = 'slash', suit = 1,
        number = 7, color = 1, subcards = {101},
        skillNames = {'browser_probe_skill'}, virt_id = 9001,
        mark = {['@browser-probe'] = 1},
      }},
      2,
      {type = '#UseCard', from = 2,
        card = {{
          cardWireCard = 1, kind = 'real', ref = 101,
        }, {
          cardWireCard = 1, kind = 'virtual', name = 'slash', suit = 1,
          number = 7, color = 1, subcards = {101},
          skillNames = {'browser_probe_skill'}, virt_id = 9001,
          mark = {['@browser-probe'] = 1},
        }}, arg = 'browser-public', arg2 = {
          cardWireCard = 1, kind = 'real', ref = 101,
        }, toast = false},
      9004,
    },
  }))`);
  runtime.receive('ShowVirtualCard', showVirtualHex, false);
  const showVirtualState = runtime.eval<{
    realId: number;
    virtualName: string;
    subcard: number;
    virtId: number;
    mark: number;
    logRealId: number;
  }>(`local data = ClientInstance.__browser_probe_show_virtual
    return {
      realId = data[1][1].id,
      virtualName = data[1][2].name,
      subcard = data[1][2].subcards[1],
      virtId = data[1][2].virt_id,
      mark = data[1][2].mark['@browser-probe'],
      logRealId = data[3].card[1].id,
    }`);
  assert.equal(showVirtualState.realId, 101);
  assert.equal(showVirtualState.virtualName, 'slash');
  assert.equal(showVirtualState.subcard, 101);
  assert.equal(showVirtualState.virtId, 9001);
  assert.equal(showVirtualState.mark, 1);
  assert.equal(showVirtualState.logRealId, 101);

  runtime.eval(`ClientInstance.callbacks.GameLog = function(_, data)
    ClientInstance.__browser_probe_game_log = data
  end
  return true`);
  const gameLogHex = runtime.eval<string>(`return __host_bin2hex(cbor.encode({
    cardWireVersion = 1,
    payload = {
      type = '#ResponsePlayCard', from = 2, to = {3},
      card = {101, {
        cardWireCard = 1, kind = 'virtual', name = 'slash', suit = 1,
        number = 7, color = 1, subcards = {101},
        skillNames = {'browser_probe_skill'}, virt_id = 9002,
      }, -1},
      arg = 'browser-public', arg2 = {
        cardWireCard = 1, kind = 'real', ref = 101,
      }, toast = true,
    },
  }))`);
  runtime.receive('GameLog', gameLogHex, false);
  const gameLogState = runtime.eval<{
    type: string;
    realId: number;
    virtualName: string;
    unknown: number;
    arg2Id: number;
    toast: boolean;
  }>(`local data = ClientInstance.__browser_probe_game_log
    return {
      type = data.type,
      realId = data.card[1].id,
      virtualName = data.card[2].name,
      unknown = data.card[3],
      arg2Id = data.arg2.id,
      toast = data.toast,
    }`);
  assert.deepEqual(gameLogState, {
    type: '#ResponsePlayCard', realId: 101, virtualName: 'slash',
    unknown: -1, arg2Id: 101, toast: true,
  });

  // A native rematch constructs a fresh server room but reuses the same client
  // object. An earlier v1 negotiation must expire at GameOver so a legacy
  // fallback can accept its old numeric draw pile, and the next round can
  // advertise and negotiate v1 again on the same connection.
  const gameOverHex = runtime.eval<string>(
    `return __host_bin2hex(cbor.encode(''))`,
  );
  runtime.eval('ClientInstance.recording = false; return true');
  runtime.receive('GameOver', gameOverHex, false);
  assert.deepEqual(runtime.eval(`return {
    inactive = not ClientInstance.gameStarted,
    versionCleared = ClientInstance.card_wire_version == nil,
    protocolCleared = ClientInstance.card_wire_protocol == nil,
    negotiatedCleared = ClientInstance.card_wire_negotiated == nil,
    capabilityCleared = ClientInstance.card_wire_capability_sent == nil,
    requestCleared = ClientInstance.card_wire_request == nil,
    aliasRetired = ClientInstance.card_wire_refs.byLocal[${observeState.hidden}] == nil,
    aliasReserved = ClientInstance.card_wire_refs:isHiddenLocal(${observeState.hidden}),
  }`), {
    inactive: true, versionCleared: true, protocolCleared: true,
    negotiatedCleared: true, capabilityCleared: true,
    requestCleared: true, aliasRetired: true, aliasReserved: true,
  });
  assert.throws(() => runtime.eval(
    `return ClientInstance.card_wire_refs:toWire(${observeState.hidden})`,
  ), /expired or unrecognized local card identity/u);
  const capabilityCount = () => sentPackets.filter((packet) =>
    packet.kind === 'notify' && packet.command === 'PushRequest').length;
  assert.equal(capabilityCount(), 1);
  runtime.receive('StartGame', startGameHex, false);
  runtime.receive('ArrangeSeats', arrangeSeatsHex, false);
  assert.equal(capabilityCount(), 2, 'same-room rematch must advertise again');
  const legacyDeckHex = runtime.eval<string>(
    `return __host_bin2hex(cbor.encode({201, 202}))`,
  );
  runtime.receive('PrepareDrawPile', legacyDeckHex, false);
  assert.deepEqual(runtime.eval('return ClientInstance.draw_pile'), [201, 202],
    'a rematch without v1 negotiation must use the legacy deck path');

  runtime.eval('ClientInstance.recording = false; return true');
  runtime.receive('GameOver', gameOverHex, false);
  runtime.receive('StartGame', startGameHex, false);
  runtime.receive('ArrangeSeats', arrangeSeatsHex, false);
  assert.equal(capabilityCount(), 3, 'a third match must advertise separately');
  runtime.receive('CardWireNegotiated', envelopeHex, false);
  runtime.receive('PrepareDrawPile', prepareHex, false);
  assert.equal(runtime.eval<number>('return ClientInstance.card_wire_version'), 1);
  assert.equal(runtime.eval<number>('return #ClientInstance.draw_pile'), 3);
  assert.equal(runtime.eval<boolean>(
    'return ClientInstance.card_wire_refs:isAnonymous(ClientInstance.draw_pile[1])'), true);
  assert.throws(() => runtime.receive('PrepareDrawPile', legacyDeckHex, false),
    /unaudited field/u, 'v1 must still reject legacy deck IDs');

  // Exercise the real enterRoom constructor that the legacy summary path
  // invokes. A cold lobby has neither the incoming mode nor an alias tracker.
  runtime.eval(`ClientInstance.settings = {}
    ClientInstance.card_wire_refs = nil
    __browser_probe_old_client = ClientInstance
    ClientInstance.callbacks.Observe = function(self, data)
      self:enterRoom({2, 30, data.settings})
      ClientInstance.__browser_probe_cold_snapshot = data
    end
    return true`);
  runtime.receive('Observe', observeHex, false);
  assert.deepEqual(runtime.eval(`local current = ClientInstance
    local id = current.__browser_probe_cold_snapshot.players[2].player_cards[1][1]
    return {rebuilt = current ~= __browser_probe_old_client,
      version = current.card_wire_version,
      hidden = current.card_wire_refs:isHiddenLocal(id),
      temporaryCleared = __browser_probe_old_client._card_wire_snapshot == nil}`),
  { rebuilt: true, version: 1, hidden: true, temporaryCleared: true });
  runtime.eval(`ClientInstance:enterRoom({2, 30, {
    gameMode = 'new_heg_mode', disabledPack = {}, disabledGenerals = {},
    _game = {}, _mode = {},
  }})
  return true`);
  assert.equal(runtime.eval<boolean>('return ClientInstance.card_wire_version == nil'), true,
    'ordinary room entry must not carry the previous room snapshot capability');

  console.log(
    'PASS browser Lua card-wire candidate: Wasmoon boot, negotiation/UI isolation, wrong protocol/version/mode plus malformed/request fail-closed, count-only deck replacement, MoveCards, ChangeCardArea, request/reply, Reconnect/Observe snapshots, public card descriptors, same-room v1 GameOver to legacy and v1 rematches, and cold snapshot constructor preservation; 19 cases; native C++/browser network/two-account NOT RUN',
  );
} finally {
  runtime.close();
}

assert.equal(luaErrors.length, 8,
  'only the intentionally rejected packets may reach the Lua error log');
assert.ok(luaErrors.some((message) => message.includes('unsupported card wire negotiation version')));
assert.ok(luaErrors.some((message) => message.includes('unsupported card wire negotiation protocol')));
assert.ok(luaErrors.some((message) => message.includes('restricted to Hegemony')));
assert.ok(luaErrors.some((message) => message.includes('unaudited field')));
assert.ok(luaErrors.some((message) => message.includes('must be a notification')));
assert.ok(luaErrors.some((message) => message.includes('expired or unrecognized local card identity')));
