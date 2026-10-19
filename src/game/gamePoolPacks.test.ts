import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  DEFAULT_INITIAL_GENERAL_COUNT,
  GAME_POOL_PACKS,
  MAX_INITIAL_GENERAL_COUNT,
  normalizeInitialGeneralCount,
  sanitizeDisabledGamePacks,
} from './gamePoolPacks';

test('initial general count accepts the supported range and defaults legacy values to five', () => {
  assert.equal(DEFAULT_INITIAL_GENERAL_COUNT, 5);
  assert.equal(MAX_INITIAL_GENERAL_COUNT, 10);
  for (const value of [5, 7, 10]) assert.equal(normalizeInitialGeneralCount(value), value);
  for (const value of [4, 11, 5.5, '7', null, undefined, Number.NaN]) {
    assert.equal(normalizeInitialGeneralCount(value), 5);
  }
});

test('the saved Quốc Chiến policy removes old, unknown, duplicate and misplaced packs', () => {
  const { disabledPacks, discardedCount } = sanitizeDisabledGamePacks({
    generals: ['hegemony_nos', 'hegemony_standard', 'hegemony_standard', 'lord_cards', null, 'formation'],
    cards: ['m_lord_cards', 'hegemony_cards', 'missing_pack', 'hegemony_cards', 'power', 'lord_cards'],
  });
  assert.deepEqual(disabledPacks, {
    generals: ['hegemony_standard', 'formation'],
    cards: ['hegemony_cards', 'lord_cards'],
  });
  assert.equal(discardedCount, 8);
});

test('a valid policy is preserved and invalid shapes fail closed', () => {
  const valid = {
    generals: GAME_POOL_PACKS.generals.map((pack) => pack.id),
    cards: GAME_POOL_PACKS.cards.map((pack) => pack.id),
  };
  assert.deepEqual(sanitizeDisabledGamePacks(valid), { disabledPacks: valid, discardedCount: 0 });
  assert.deepEqual(sanitizeDisabledGamePacks({ generals: 'invalid', cards: {} }).disabledPacks,
    { generals: [], cards: [] });
});
