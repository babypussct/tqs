import assert from 'node:assert/strict';
import test from 'node:test';
import {
  QA_SCENARIO_IDS,
  QA_SCENARIOS,
  QaScenarioError,
  deterministicShuffle,
  resolveQaScenario,
  validateQaScenarioCatalog,
  type QaCardDescriptor,
} from './real-lua-e2e/qa-scenarios';

function fakeCards(): QaCardDescriptor[] {
  return [
    { id: 1, name: 'slash', trueName: 'slash', color: 'red', type: 'basic' },
    { id: 2, name: 'peach', trueName: 'peach', color: 'red', type: 'basic' },
    { id: 3, name: 'heg__nullification', trueName: 'nullification', color: 'black', type: 'trick' },
    { id: 4, name: 'blade', trueName: 'blade', color: 'red', type: 'equip', subtype: 'weapon' },
    { id: 5, name: 'jink', trueName: 'jink', color: 'red', type: 'basic' },
    { id: 6, name: 'duel', trueName: 'duel', color: 'black', type: 'trick' },
    { id: 7, name: 'fire_attack', trueName: 'fire_attack', color: 'red', type: 'trick' },
    { id: 8, name: 'wine', trueName: 'analeptic', color: 'red', type: 'basic' },
    ...[9, 10, 11].map((id) => ({ id, name: 'slash', trueName: 'slash', color: 'red', type: 'basic' })),
    { id: 12, name: 'peach', trueName: 'peach', color: 'red', type: 'basic' },
    { id: 13, name: 'snatch', trueName: 'snatch', color: 'black', type: 'trick' },
    { id: 14, name: 'indulgence', trueName: 'indulgence', color: 'black', type: 'trick' },
    { id: 15, name: 'kylin_bow', trueName: 'kylin_bow', color: 'red', type: 'equip', subtype: 'weapon' },
    { id: 16, name: 'slash', trueName: 'slash', color: 'red', suit: 'heart', type: 'basic' },
    { id: 17, name: 'eight_diagram', trueName: 'eight_diagram', color: 'black', type: 'equip', subtype: 'armor' },
    { id: 18, name: 'jink', trueName: 'jink', color: 'black', type: 'basic' },
    { id: 19, name: 'slash', trueName: 'slash', color: 'black', type: 'basic' },
    { id: 20, name: 'sa__halberd', trueName: 'sa__halberd', color: 'red', type: 'equip', subtype: 'weapon' },
  ];
}

test('QA scenario catalog is explicit and covers every required trigger', () => {
  validateQaScenarioCatalog();
  assert.deepEqual(new Set(QA_SCENARIO_IDS), new Set(Object.keys(QA_SCENARIOS)));
  assert.deepEqual(QA_SCENARIOS['card-chosen'].expectedCommand, 'AskForCardChosen');
  assert.deepEqual(QA_SCENARIOS.poxi.expectedCommand, 'AskForPoxi');
  assert.deepEqual(QA_SCENARIOS['cards-and-choice'].expectedCommand, 'AskForCardsAndChoice');
  assert.deepEqual(QA_SCENARIOS['rescue-battle'].expectedCommand, 'AskForUseCard');
  assert.deepEqual(QA_SCENARIOS.founding.expectedCommand, 'AskForChoices');
});

test('deterministic shuffle is stable and does not mutate the source', () => {
  const source = ['a', 'b', 'c', 'd', 'e'];
  const first = deterministicShuffle(source, 0x12345678);
  assert.deepEqual(first, deterministicShuffle(source, 0x12345678));
  assert.deepEqual(source, ['a', 'b', 'c', 'd', 'e']);
  assert.deepEqual([...first].sort(), source);
  assert.notDeepEqual(first, deterministicShuffle(source, 0x87654321));
});

test('resolver reserves required cards at the top and keeps a complete unique tail', () => {
  const cards = fakeCards();
  const resolved = resolveQaScenario(QA_SCENARIOS['cards-and-choice'], cards);
  assert.deepEqual(resolved.drawPile.slice(0, 3), [1, 4, 2]);
  assert.deepEqual(resolved.slotCards, { slash: 1, equip: 4, peach: 2 });
  assert.equal(new Set(resolved.drawPile).size, cards.length);
  assert.deepEqual([...resolved.drawPile].sort((a, b) => a - b), cards.map((card) => card.id));
  assert.deepEqual(resolved.drawPile, resolveQaScenario(QA_SCENARIOS['cards-and-choice'], cards).drawPile);
});

test('every catalog plan resolves against the native-shaped fixture registry', () => {
  const cards = fakeCards();
  for (const id of QA_SCENARIO_IDS) {
    const resolved = resolveQaScenario(QA_SCENARIOS[id], cards);
    assert.equal(resolved.drawPile.length, cards.length, id);
    assert.equal(new Set(resolved.drawPile).size, cards.length, id);
    for (const item of QA_SCENARIOS[id].slots) assert.ok(resolved.slotCards[item.key], `${id}:${item.key}`);
  }
});

test('resolver fails closed when a required native card is absent', () => {
  const cards = fakeCards().filter((card) => card.trueName !== 'peach');
  assert.throws(
    () => resolveQaScenario(QA_SCENARIOS['rescue-normal'], cards),
    (error: unknown) => error instanceof QaScenarioError && /cannot resolve/u.test(error.message),
  );
});

test('delta-xishe requires separate native weapon and armor subtype evidence', () => {
  const plan = QA_SCENARIOS['delta-xishe'];
  const cards = fakeCards();
  assert.deepEqual(resolveQaScenario(plan, cards).drawPile.slice(0, 2), [4, 17]);
  for (const invalid of [
    cards.map((card) => card.id === 17 ? { ...card, subtype: 'weapon' as const } : card),
    cards.map((card) => card.id === 17 ? { ...card, subtype: undefined } : card),
    cards.map((card) => card.id === 17 ? { ...card, type: 'other' } : card),
    cards.map((card) => card.id === 4 || card.id === 15 || card.id === 20 ? { ...card, subtype: 'armor' as const } : card),
  ]) {
    assert.throws(() => resolveQaScenario(plan, invalid),
      (error: unknown) => error instanceof QaScenarioError && /cannot resolve/u.test(error.message));
  }
});

test('delta-bawei reserves separate physical Slashes and both branch Jinks deterministically', () => {
  const plan = QA_SCENARIOS['delta-bawei'];
  assert.equal(plan.seed, 0x5d6e801a);
  assert.equal(plan.expectedCommand, 'AskForSkillInvoke');
  assert.deepEqual(plan.drawSequence.map((entry) => 'trueName' in entry ? entry.trueName : null),
    ['slash', 'slash', 'jink', 'jink']);
  assert.deepEqual(plan.slots.map(({ key, owner, area, drawIndex }) =>
    ({ key, owner, area, drawIndex })), [
    { key: 'bawei-damaged-slash', owner: 'self', area: 'hand', drawIndex: 0 },
    { key: 'bawei-control-slash', owner: 'self', area: 'hand', drawIndex: 1 },
    { key: 'bawei-damaged-jink', owner: 'opponent', area: 'hand', drawIndex: 2 },
    { key: 'bawei-control-jink', owner: 'opponent', area: 'hand', drawIndex: 3 },
  ]);
  const resolved = resolveQaScenario(plan, fakeCards());
  assert.deepEqual(resolved.drawPile.slice(0, 4), [1, 9, 5, 18]);
  assert.equal(new Set(Object.values(resolved.slotCards)).size, 4);
});

test('delta-fengshi variants reserve identical first physical Slash and bot Jink with distinct native seeds', () => {
  for (const [id, seed] of [
    ['delta-fengshi-siege', 0x5d6e801b],
    ['delta-fengshi-no-siege', 0x5d6e801c],
  ] as const) {
    const plan = QA_SCENARIOS[id];
    assert.equal(plan.id, id);
    assert.equal(plan.trigger, id);
    assert.equal(plan.seed, seed);
    assert.equal(plan.expectedCommand, 'AskForSkillInvoke');
    assert.deepEqual(plan.drawSequence.map((entry) =>
      ({ trueName: 'trueName' in entry ? entry.trueName : null })),
      [{ trueName: 'slash' }, { trueName: 'jink' }]);
    assert.deepEqual(plan.slots.map(({ key, owner, area, drawIndex }) =>
      ({ key, owner, area, drawIndex })), [
      { key: 'fengshi-first-slash', owner: 'self', area: 'hand', drawIndex: 0 },
      { key: 'fengshi-target-jink', owner: 'opponent', area: 'hand', drawIndex: 1 },
    ]);
    const resolved = resolveQaScenario(plan, fakeCards());
    assert.deepEqual(resolved.drawPile.slice(0, 2), [1, 5]);
    assert.equal(new Set(Object.values(resolved.slotCards)).size, 2);
  }
});
