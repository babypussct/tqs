import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import PlayerPhotoPanel, { getMagatamaState } from '../src/PlayerPhotoPanel';
import { initialSnapshot, reduceUiEvent, type GameSnapshot } from '../src/store/gameStore';

function assertPortraitHalves(markup: string, mainVisible: boolean, deputyVisible: boolean) {
  assert.match(markup, /sg-portrait-frame native-portrait-canvas has-deputy/);
  const mainStart = markup.indexOf('sg-portrait-slot native-general-slot sg-portrait-main');
  const deputyStart = markup.indexOf('sg-portrait-slot native-general-slot sg-portrait-deputy');
  const dividerStart = markup.indexOf('sg-deputy-split-line native-deputy-split-line');
  assert.ok(mainStart >= 0 && mainStart < deputyStart && deputyStart < dividerStart);
  const mainSlot = markup.slice(mainStart, deputyStart);
  const deputySlot = markup.slice(deputyStart, dividerStart);
  for (const [slot, visible] of [[mainSlot, mainVisible], [deputySlot, deputyVisible]] as const) {
    if (visible) {
      assert.match(slot, /sg-portrait-name/);
      assert.doesNotMatch(slot, /sg-portrait-card-back/);
    } else {
      assert.match(slot, /sg-portrait-hidden/);
      assert.match(slot, /sg-portrait-card-back/);
      assert.doesNotMatch(slot, /sg-portrait-name/);
    }
  }
}

test('single reveal always keeps two half-size slots and hides the opposite portrait', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Tôi', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'SelfGenerals', [17, 'caocao', 'guojia', 'hegemony', 'hegemony']);

  const renderPortrait = (self = true) => renderToStaticMarkup(createElement(PlayerPhotoPanel, {
    player: state.players.find((player) => player.id === 17)!,
    game: state.board.player[17],
    self,
    seat: 1,
    active: false,
    compact: true,
  }));

  const hiddenBoth = renderPortrait();
  assert.match(hiddenBoth, /sg-portrait-frame native-portrait-canvas has-deputy/);
  assert.match(hiddenBoth, /sg-portrait-slot native-general-slot sg-portrait-deputy/);

  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'caocao']);
  const mainOnly = renderPortrait();
  assertPortraitHalves(mainOnly, true, false);
  assert.match(mainOnly, /aria-label="caocao; Phó tướng ẩn"/);

  // The reverse reveal must leave the main half face-down too.
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'anjiang']);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'deputyGeneral', 'guojia']);
  const deputyOnly = renderPortrait();
  assertPortraitHalves(deputyOnly, false, true);
  assert.match(deputyOnly, /aria-label="Chủ tướng ẩn; guojia"/);

  // Opponents lack private names and still get both fixed slots.
  assertPortraitHalves(renderPortrait(false), false, true);

  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'general', 'caocao']);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'deputyGeneral', 'guojia']);
  const bothRevealed = renderPortrait();
  assertPortraitHalves(bothRevealed, true, true);

  const css = readFileSync(new URL('../src/styles.css', import.meta.url), 'utf8');
  assert.match(css, /\.sg-portrait-frame\.has-deputy \.sg-portrait-slot\.sg-portrait-main \{ width: 50%; \}/);
  assert.match(css, /\.sg-portrait-frame\.has-deputy \.sg-portrait-slot\.sg-portrait-deputy \{ width: 50%; \}/);
  assert.doesNotMatch(css, /\.sg-portrait-frame\.single \.sg-portrait-slot/);
});

test('FreeKill HP color state uses current HP and treats a full short bar as green', () => {
  for (const [hp, maxHp, expected] of [
    [0, 4, 0], [1, 4, 1], [2, 4, 2], [3, 4, 3], [4, 4, 3],
    [1, 2, 1], [2, 2, 3], [1, 1, 3],
    [1, 8, 1], [2, 8, 2], [3, 8, 3], [8, 8, 3],
  ]) {
    assert.equal(getMagatamaState(hp, maxHp), expected, `${hp}/${maxHp} should use upstream state ${expected}`);
  }
  assert.equal(getMagatamaState(null, 4), 0);
  assert.equal(getMagatamaState(3, null), 0);
  assert.equal(getMagatamaState(0, 0), 0);
});

test('HP portrait shows upstream-colored magatama vertically with empty slots above filled ones', () => {
  let state: GameSnapshot = { ...initialSnapshot, ownId: 17 };
  state = reduceUiEvent(state, 'AddPlayer', [17, 'Tôi', '', false, 0]);
  state = reduceUiEvent(state, 'StartGame', null);
  state = reduceUiEvent(state, 'PropertyUpdate', [17, 'hp', 4]);
  const player = state.players.find((entry) => entry.id === 17)!;
  const base = state.board.player[17];
  const renderHp = (hp: number, maxHp: number, shield = 0) =>
    renderToStaticMarkup(createElement(PlayerPhotoPanel, {
      player, game: { ...base, hp, maxHp, shield }, self: true, seat: 1, active: false, compact: true,
    }));
  const discs = (html: string) => [...html.matchAll(/class="native-heg-hp-disc-v (sg-magatama-\w+)" src="\/photo-assets\/magatama\/([0-3]-heg)\.png"/g)]
    .map((match) => [match[1], match[2]]);

  assert.deepEqual(discs(renderHp(1, 4)), [
    ['sg-magatama-empty', '0-heg'], ['sg-magatama-empty', '0-heg'],
    ['sg-magatama-empty', '0-heg'], ['sg-magatama-filled', '1-heg'],
  ]);
  assert.deepEqual(discs(renderHp(2, 4)), [
    ['sg-magatama-empty', '0-heg'], ['sg-magatama-empty', '0-heg'],
    ['sg-magatama-filled', '2-heg'], ['sg-magatama-filled', '2-heg'],
  ]);
  assert.deepEqual(discs(renderHp(3, 4)), [
    ['sg-magatama-empty', '0-heg'], ['sg-magatama-filled', '3-heg'],
    ['sg-magatama-filled', '3-heg'], ['sg-magatama-filled', '3-heg'],
  ]);
  assert.ok(discs(renderHp(4, 4)).every(([, asset]) => asset === '3-heg'));
  assert.ok(discs(renderHp(0, 4)).every(([, asset]) => asset === '0-heg'));
  assert.deepEqual(discs(renderHp(1, 2)), [['sg-magatama-empty', '0-heg'], ['sg-magatama-filled', '1-heg']]);
  assert.deepEqual(discs(renderHp(2, 2)), [['sg-magatama-filled', '3-heg'], ['sg-magatama-filled', '3-heg']]);

  for (const [hp, maxHp, shield, asset, tone] of [
    [1, 8, 0, '1-heg', 'hp-danger'],
    [2, 8, 0, '2-heg', 'hp-warning'],
    [3, 8, 0, '3-heg', ''],
    [0, 8, 0, '0-heg', 'hp-danger'],
    [2, 4, 1, '2-heg', 'hp-warning'],
  ] as const) {
    const html = renderHp(hp, maxHp, shield);
    assert.deepEqual(discs(html), [['sg-magatama-filled', asset]], `${hp}/${maxHp} shield ${shield}`);
    assert.match(html, new RegExp(`sg-hp-vertical-fraction native-hp-vertical-fraction ${tone}`));
    assert.doesNotMatch(html, /class="sg-magatama-column"/);
  }

  const css = readFileSync(new URL('../src/styles.css', import.meta.url), 'utf8');
  assert.match(css, /\.sg-magatama-column\s*\{[^}]*display:\s*flex;[^}]*flex-direction:\s*column;/);
  assert.match(css, /\.sg-magatama-column \.sg-magatama-empty\s*\{\s*opacity:\s*0;/);
  assert.match(css, /\.sg-hp-vertical-fraction\.hp-warning\s*\{\s*color:\s*#e3b006;/);
  assert.match(css, /\.sg-hp-vertical-fraction\.hp-danger\s*\{\s*color:\s*#f4180e;/);
});
