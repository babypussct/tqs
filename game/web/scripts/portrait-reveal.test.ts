import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import PlayerPhotoPanel from '../src/PlayerPhotoPanel';
import { initialSnapshot, reduceUiEvent } from '../src/store/gameStore';

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
  let state = { ...initialSnapshot, ownId: 17 };
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
