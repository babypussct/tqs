import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  createInitialGeneralChoiceState,
  isInitialGeneralReady,
  parseInitialGeneralMetadata,
  reduceInitialGeneralChoice,
} from '../src/engine/generalSelection';

const offered = ['main', 'deputy', 'third'];

test('initial-general reducer follows native selection order and removal semantics', () => {
  let state = createInitialGeneralChoiceState(41, offered);
  assert.deepEqual(state.chosen, []);
  assert.equal(state.phase, 'select-main');

  state = reduceInitialGeneralChoice(state, { type: 'select-main', name: 'main' });
  assert.deepEqual(state.chosen, ['main']);
  assert.equal(state.phase, 'select-deputy');

  state = reduceInitialGeneralChoice(state, { type: 'select-deputy', name: 'deputy', kingdoms: ['wei'] });
  assert.deepEqual(state.chosen, ['main', 'deputy']);
  assert.deepEqual(state.kingdoms, ['wei']);
  assert.equal(state.selectedKingdom, 'wei');
  assert.equal(state.phase, 'ready');
  assert.equal(isInitialGeneralReady(state), true);

  const locked = reduceInitialGeneralChoice(state, { type: 'select-main', name: 'third' });
  assert.deepEqual(locked.chosen, ['main', 'deputy'], 'a third general cannot replace a full pair');
  assert.deepEqual(locked, state);

  state = reduceInitialGeneralChoice(state, { type: 'toggle-selected', name: 'main' });
  assert.deepEqual(state.chosen, ['deputy'], 'removing the main promotes the deputy');
  assert.equal(state.phase, 'select-deputy');
  assert.deepEqual(state.kingdoms, []);

  state = reduceInitialGeneralChoice(state, { type: 'select-deputy', name: 'third', kingdoms: ['shu', 'wu', 'shu'] });
  assert.deepEqual(state.chosen, ['deputy', 'third']);
  assert.deepEqual(state.kingdoms, ['shu', 'wu']);
  assert.equal(state.phase, 'select-kingdom');
  assert.equal(isInitialGeneralReady(state), false);

  state = reduceInitialGeneralChoice(state, { type: 'select-kingdom', kingdom: 'wu' });
  assert.equal(isInitialGeneralReady(state), true);
  state = reduceInitialGeneralChoice(state, { type: 'toggle-selected', name: 'third' });
  assert.deepEqual(state.chosen, ['deputy']);
  assert.equal(state.selectedKingdom, '');
});

test('invalid deputy and kingdom choices never manufacture a ready state', () => {
  let state = createInitialGeneralChoiceState(42, offered);
  state = reduceInitialGeneralChoice(state, { type: 'select-main', name: 'main' });
  const rejected = reduceInitialGeneralChoice(state, { type: 'select-deputy', name: 'third', kingdoms: [] });
  assert.deepEqual(rejected.chosen, ['main']);
  assert.equal(rejected.phase, 'select-deputy');
  assert.equal(isInitialGeneralReady(rejected), false);
  assert.match(rejected.error, /không có thế lực/);
  const noKingdom = reduceInitialGeneralChoice(rejected, { type: 'select-kingdom', kingdom: 'wei' });
  assert.equal(isInitialGeneralReady(noKingdom), false);
  assert.match(noKingdom.error, /không được máy chủ/);
});

test('terminal request state rejects stale UI actions', () => {
  let state = createInitialGeneralChoiceState(43, offered);
  state = reduceInitialGeneralChoice(state, { type: 'select-main', name: 'main' });
  state = reduceInitialGeneralChoice(state, { type: 'terminal', phase: 'expired', error: 'expired' });
  assert.deepEqual(state.chosen, []);
  assert.equal(state.phase, 'expired');
  assert.deepEqual(reduceInitialGeneralChoice(state, { type: 'select-main', name: 'main' }), state);
});

test('metadata parser requires an aligned bounded public offer snapshot', () => {
  const rows = offered.map((name, index) => ({
    name, label: `Tướng ${name}`, trueName: name, prefix: '', kingdom: index === 0 ? 'wild' : 'wei', subkingdom: '',
    hp: 4, maxHp: 4, mainMaxHp: index === 1 ? 1 : 0, deputyMaxHp: index === 2 ? -1 : 0,
    shield: 0, companionWithOffer: index === 1,
  }));
  assert.deepEqual(parseInitialGeneralMetadata(rows, offered), rows);
  assert.deepEqual(parseInitialGeneralMetadata(rows.slice(1), offered), []);
  assert.deepEqual(parseInitialGeneralMetadata([{ ...rows[0], name: 'opponent-only' }, ...rows.slice(1)], offered), []);
  assert.deepEqual(parseInitialGeneralMetadata([{ ...rows[0], companionWithOffer: 'yes' }, ...rows.slice(1)], offered), []);
  assert.deepEqual(parseInitialGeneralMetadata([{ ...rows[0], kingdom: 'wei,shu' }, ...rows.slice(1)], offered), []);
});
