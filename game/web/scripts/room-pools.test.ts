/** UI-02 regression: actual installed FreeKill Lua package/engine/mode logic,
 * plus the browser adapter's CreateRoom -> Lua -> CBOR bridge.
 * The server Room:makeGeneralPile method is evaluated unchanged with a small
 * room fixture; this is not a live C++ server integration test. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { GameAdapter, type RoomGeneral, type RoomPack, type RoomPacks, type PoolSummary } from '../src/engine/gameAdapter';
import { reduceUiEvent, initialSnapshot } from '../src/store/gameStore';
import { loadUpstreamFiles } from './upstream-packages';

const upstream = fileURLToPath(new URL('../../../scratch/upstream/', import.meta.url));
const files = loadUpstreamFiles(upstream);

const notifications: { kind: string; command: string; hex: string }[] = [];
const errors: string[] = [];
const rt = new LuaRuntime({ files, callbacks: {
  send: (kind, command, hex) => notifications.push({ kind, command, hex }),
  ui: () => {}, setup: () => {}, log: (level, message) => {
    if (level === 'error') errors.push(message);
  },
} });

type NativePool = {
  generals: string[];
  draw: number[];
  void: number[];
  generalPackages: string[];
  trueNames: string[];
  cardPackages: string[];
  usable: boolean;
};

// Use the real server method's source, not a reimplementation of its filter.
// ServerRoomBase/C++ are unavailable in the Wasmoon client fixture, so only
// Room:makeGeneralPile is bound to a tiny fake room containing its inputs.
const serverRoomSource = fs.readFileSync(path.join(upstream, 'freekill-core/ltk/server/room.lua'), 'utf8');
const makeGeneralPile = serverRoomSource.match(/^function Room:makeGeneralPile\(\)\n[\s\S]*?^end$/m)?.[0];
assert.ok(makeGeneralPile, 'Native Room:makeGeneralPile implementation not found');

async function main() {
  await rt.start();
  try {
    const packs = rt.call<RoomPacks>('__web_room_packs', 'new_heg_mode');
    assert.ok(packs.generals.length > 0, 'mode must advertise general packages');
    assert.ok(packs.cards.length > 0, 'mode must advertise card packages');
    const packageIds = [...packs.generals, ...packs.cards].map((p) => p.id);
    assert.equal(new Set(packageIds).size, packageIds.length, 'duplicate package IDs');
    assert.deepEqual(rt.eval(`
      local listed = __web_room_packs('new_heg_mode')
      local blocked = {}
      for _, name in ipairs(Fk.game_mode_disabled.new_heg_mode or {}) do blocked[name] = true end
      local result = {}
      for _, group in ipairs({'generals', 'cards'}) do
        for _, entry in ipairs(listed[group]) do
          local pkg = Fk.packages[entry.id]
          local count = 0
          if group == 'generals' then
            for _, g in ipairs(pkg.generals) do
              if not g.hidden and not g.total_hidden then count = count + 1 end
            end
          else
            for _, c in ipairs(pkg.cards) do if not c.is_derived then count = count + 1 end end
          end
          result[#result + 1] = {exists = pkg ~= nil,
            kind = group == 'generals' and pkg.type == Package.GeneralPack or pkg.type == Package.CardPack,
            enabled = not blocked[entry.id], count = count == entry.count}
        end
      end
      return result
    `), packageIds.map(() => ({ exists: true, kind: true, enabled: true, count: true })));
    assert.throws(() => rt.call('__web_room_packs', 'missing_mode'), /unknown game mode/);

    const baseline = rt.call<PoolSummary>('__web_room_pool_summary', 'new_heg_mode', []);
    assert.ok(baseline.generals >= 10 && baseline.cards >= 8);
    const testedPack = (group: RoomPack[], property: keyof PoolSummary) => {
      const found = group.find((p) => rt.call<PoolSummary>(
        '__web_room_pool_summary', 'new_heg_mode', [p.id],
      )[property] < baseline[property]);
      assert.ok(found, `No ${property} package changes the available pool`);
      return found;
    };
    const general = testedPack(packs.generals, 'generals');
    const card = testedPack(packs.cards, 'cards');
    const disabled = [general.id, card.id];
    const summary = rt.call<PoolSummary>('__web_room_pool_summary', 'new_heg_mode', disabled);
    assert.ok(summary.generals < baseline.generals, 'general toggle must change count');
    assert.ok(summary.cards < baseline.cards, 'card toggle must change count');
    assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', ['missing_pack']), /invalid or duplicate/);
    assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', [general.id, general.id]), /invalid or duplicate/);
    assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', [123]), /invalid or duplicate/);
    const excluded = rt.eval<string[]>(`return Fk.game_mode_disabled.new_heg_mode or {}`);
    if (excluded.length) assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', [excluded[0]]), /invalid or duplicate/);

    const roomGenerals = rt.call<RoomGeneral[]>('__web_room_generals', 'new_heg_mode', []);
    assert.ok(roomGenerals.length >= baseline.generals, 'general QA listing must cover the native visible pool');
    const keepNames = new Set<string>();
    const keepGenerals: RoomGeneral[] = [];
    for (const candidate of roomGenerals) {
      if (!keepNames.has(candidate.trueName)) {
        keepNames.add(candidate.trueName);
        keepGenerals.push(candidate);
      }
      if (keepGenerals.length === 10) break;
    }
    assert.equal(keepGenerals.length, 10, 'native runtime must provide ten distinct generals for a two-seat QA room');
    const qaDisabledGenerals = roomGenerals.filter((candidate) => !keepGenerals.some((kept) => kept.id === candidate.id)).map((candidate) => candidate.id);
    const qaSummary = rt.call<PoolSummary>('__web_room_pool_summary', 'new_heg_mode', [], qaDisabledGenerals);
    assert.deepEqual(qaSummary, { generals: 10, cards: baseline.cards }, 'disabledGenerals must leave the native ten-general QA pool');
    assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', [], ['missing_general']), /invalid or duplicate disabled general/);
    if (qaDisabledGenerals.length) assert.throws(() => rt.call('__web_room_pool_summary', 'new_heg_mode', [], [qaDisabledGenerals[0], qaDisabledGenerals[0]]), /invalid or duplicate disabled general/);

    // Evaluate the exact upstream makeGeneralPile body. In both cases, the
    // upstream Engine:canUseGeneral and Hegemony mode:build_draw_pile run live.
    const nativeCode = `local Room = {}\n${makeGeneralPile}\n`;
    const nativePool = (selected: string[]): NativePool => rt.eval<NativePool>(`${nativeCode}
      local savedRoom = RoomInstance
      local room = {disabled_packs = ${JSON.stringify(selected).replace(/\[/g, '{').replace(/\]/g, '}')},
        disabled_generals = {}, players = {}, game_started = false,
        filtered_cards = {}, printed_cards = {},
        getSettings = function(_, key) return key == 'disableSameConvert' and false or nil end,
        shuffleTable = function() end}
      -- Same mode-forced disabled packages as server Room:initialize.
      table.insertTableIfNeed(room.disabled_packs, Fk.game_mode_disabled['new_heg_mode'])
      setmetatable(room, {__index = Room})
      RoomInstance = room
      local ok, result = pcall(function()
        room:makeGeneralPile()
        local draw, void = Fk.game_modes['new_heg_mode']:buildDrawPile()
        local generalPackages, cardPackages, trueNames = {}, {}, {}
        for _, name in ipairs(room.general_pile) do
          generalPackages[#generalPackages + 1] = Fk.generals[name].package.name
          trueNames[#trueNames + 1] = Fk.generals[name].trueName
        end
        for _, id in ipairs(draw) do cardPackages[#cardPackages + 1] = Fk:getCardById(id).package.name end
        local possible = true
        for _, name in ipairs(room.general_pile) do if not Fk:canUseGeneral(name) then possible = false end end
        return {generals = room.general_pile, draw = draw, void = void,
          generalPackages = generalPackages, cardPackages = cardPackages, trueNames = trueNames, usable = possible}
      end)
      RoomInstance = savedRoom
      if not ok then error(result) end
      return result
    `);

    const all = nativePool([]);
    const filtered = nativePool(disabled);
    assert.equal(all.generals.length, baseline.generals, 'preview must match native general-pile count');
    assert.equal(filtered.generals.length, summary.generals, 'disabled preview must match native general-pile count');
    assert.equal(all.draw.length, baseline.cards, 'preview must match Hegemony draw pile');
    assert.equal(filtered.draw.length, summary.cards, 'disabled preview must match Hegemony draw pile');
    assert.ok(all.usable && filtered.usable, 'pile may contain only usable generals');
    assert.ok(all.generalPackages.includes(general.id), 'baseline includes a general from enabled package');
    assert.ok(all.cardPackages.includes(card.id), 'baseline includes cards from enabled package');
    assert.ok(!filtered.generalPackages.includes(general.id), 'disabled generals appear in pile');
    assert.ok(!filtered.cardPackages.includes(card.id), 'disabled cards appear in draw pile');
    const baseTrueNames = new Set(all.trueNames);
    const baseCards = new Set(all.draw);
    // Room:makeGeneralPile may substitute another variant of the same
    // trueName after disabling a pack, so compare unique identities.
    assert.ok(filtered.trueNames.every((name) => baseTrueNames.has(name)), 'disabled pool introduced unrelated generals');
    assert.ok(filtered.draw.every((id) => baseCards.has(id)), 'disabled pool introduced unrelated cards');

    // Call the actual production adapter, which validates room capacity,
    // obtains the Lua summary, and serializes through __web_notify (CBOR).
    const adapter = new GameAdapter('/test');
    (adapter as unknown as {connection: unknown}).connection = {
      getStatus: () => ({kind: 'online'}), lua: rt,
    };
    assert.throws(() => adapter.createRoom('Blocked', 2, 30, [...packs.generals.map((p) => p.id)]), /Bể tướng/);
    assert.throws(() => adapter.createRoom('Blocked', 2, 30, [...packs.cards.map((p) => p.id)]), /Bể bài/);
    assert.throws(() => adapter.createRoom('Blocked', 2, 30, ['fake']), /invalid or duplicate/);
    assert.equal(notifications.length, 0, 'invalid pools must never send CreateRoom');
    adapter.createRoom(' Gói chọn kiểm thử ', 2, 30, disabled);
    assert.equal(notifications.length, 1);
    const created = notifications[0];
    assert.equal(created.kind, 'notify');
    assert.equal(created.command, 'CreateRoom');
    const packet = rt.eval<{room: string; capacity: number; timeout: number; settings: Record<string, unknown>}>(`
      local data = cbor.decode(__host_hex2bin('${created.hex}'))
      return {room = data[1], capacity = data[2], timeout = data[3], settings = data[4]}
    `);
    assert.equal(packet.room, 'Gói chọn kiểm thử');
    assert.equal(packet.capacity, 2);
    assert.equal(packet.timeout, 30);
    assert.deepEqual(packet.settings.disabledPack, disabled, 'CBOR must preserve package IDs and order');
    assert.deepEqual(packet.settings.disabledGenerals, []);
    assert.equal(packet.settings.gameMode, 'new_heg_mode');
    assert.equal((packet.settings._game as Record<string, unknown>).generalNum, 5);

    adapter.createRoom(' Caller QA ', 2, 30, [], qaDisabledGenerals);
    assert.equal(notifications.length, 2);
    const qaCreated = rt.eval<{settings: Record<string, unknown>}>(`
      local data = cbor.decode(__host_hex2bin('${notifications[1].hex}'))
      return {settings = data[4]}
    `);
    assert.deepEqual(qaCreated.settings.disabledGenerals, qaDisabledGenerals, 'CBOR must preserve deterministic native caller exclusions');

    adapter.createRoom(' Battle Royal QA ', 2, 30, [], [], { enterBattleRoyalOnFirstShuffle: true, old_battle_royal: false, ignored: true });
    assert.equal(notifications.length, 3);
    const modeCreated = rt.eval<{settings: Record<string, unknown>}>(`
      local data = cbor.decode(__host_hex2bin('${notifications[2].hex}'))
      return {settings = data[4]}
    `);
    assert.deepEqual(modeCreated.settings._mode, { enterBattleRoyalOnFirstShuffle: true, old_battle_royal: false },
      'QA mode settings must preserve only the bounded native Battle Royal keys');

    // EnterRoom settings are server-owned. Verify client renders the echoed
    // package state and resets it when leaving / entering another room.
    let state = reduceUiEvent(initialSnapshot, 'EnterRoom', [2, 30, packet.settings]);
    assert.deepEqual(state.roomDisabledPacks, disabled);
    state = reduceUiEvent(state, 'EnterLobby', null);
    assert.deepEqual(state.roomDisabledPacks, []);
    state = reduceUiEvent(state, 'EnterRoom', [2, 30, { gameMode: 'new_heg_mode', disabledPack: [card.id] }]);
    assert.deepEqual(state.roomDisabledPacks, [card.id]);
    assert.ok(errors.every((message) => /unknown game mode|invalid or duplicate disabled package|invalid or duplicate disabled general/.test(message)),
      `unexpected Lua runtime errors: ${errors.join(' | ')}`);

    console.log(`PASS room packs: ${packs.generals.length} general + ${packs.cards.length} card packages`);
    console.log(`PASS native general pile: ${all.generals.length} -> ${filtered.generals.length} (disabled ${general.id})`);
    console.log(`PASS native Hegemony draw pile: ${all.draw.length} -> ${filtered.draw.length} (disabled ${card.id})`);
    console.log('PASS production adapter CreateRoom / Lua CBOR / EnterRoom state / invalid packs');
  } finally {
    rt.close();
  }
}

await main();
