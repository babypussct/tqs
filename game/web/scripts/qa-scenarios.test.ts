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
    { id: 1, name: 'slash', trueName: 'slash', type: 'basic' },
    { id: 2, name: 'peach', trueName: 'peach', type: 'basic' },
    { id: 3, name: 'heg__nullification', trueName: 'nullification', type: 'trick' },
    { id: 4, name: 'blade', trueName: 'blade', type: 'equip' },
    { id: 5, name: 'jink', trueName: 'jink', type: 'basic' },
    { id: 6, name: 'duel', trueName: 'duel', type: 'trick' },
    { id: 7, name: 'fire_attack', trueName: 'fire_attack', type: 'trick' },
    { id: 8, name: 'wine', trueName: 'analeptic', type: 'basic' },
    ...[9, 10, 11].map((id) => ({ id, name: 'slash', trueName: 'slash', type: 'basic' })),
    { id: 12, name: 'peach', trueName: 'peach', type: 'basic' },
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
