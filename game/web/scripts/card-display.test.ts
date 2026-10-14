import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  getSuitInfo,
  formatRank,
  getCardCategory,
  resolveCardText,
  getNativeCardArtUrl,
  type CardData,
} from '../src/HandCardItem';

const rootDir = fileURLToPath(new URL('../', import.meta.url));

test('formatRank converts numbers 0..13 to card rank strings correctly', () => {
  assert.equal(formatRank(1), 'A');
  assert.equal(formatRank(2), '2');
  assert.equal(formatRank(7), '7');
  assert.equal(formatRank(10), '10');
  assert.equal(formatRank(11), 'J');
  assert.equal(formatRank(12), 'Q');
  assert.equal(formatRank(13), 'K');
  assert.equal(formatRank(0), 'X');
  assert.equal(formatRank(undefined), '');
  assert.equal(formatRank(-1), '');
  assert.equal(formatRank(14), '');
});

test('getSuitInfo maps suits 1..5 to symbol, name, and color classes correctly', () => {
  assert.deepEqual(getSuitInfo(1), { symbol: '♠', name: 'Bích', colorClass: 'suit-black' });
  assert.deepEqual(getSuitInfo(2), { symbol: '♣', name: 'Chuồn', colorClass: 'suit-black' });
  assert.deepEqual(getSuitInfo(3), { symbol: '♥', name: 'Cơ', colorClass: 'suit-red' });
  assert.deepEqual(getSuitInfo(4), { symbol: '♦', name: 'Rô', colorClass: 'suit-red' });
  // NoSuit / undefined / invalid
  assert.deepEqual(getSuitInfo(5), { symbol: '◇', name: 'Không chất', colorClass: 'suit-nosuit' });
  assert.deepEqual(getSuitInfo(undefined), { symbol: '◇', name: 'Không chất', colorClass: 'suit-nosuit' });
});

test('getCardCategory correctly identifies all 6 required card varieties and unknown fallback', () => {
  // 1. Sát (slash) -> Basic
  assert.equal(getCardCategory('slash').typeKey, 'basic');
  assert.equal(getCardCategory('thunder_slash').typeKey, 'basic');
  assert.equal(getCardCategory('standard__slash').typeKey, 'basic');

  // 2. Đào (peach) -> Basic
  assert.equal(getCardCategory('peach').typeKey, 'basic');

  // 3. Vô Trung Sinh Hữu (ex_nihilo) -> Trick
  assert.equal(getCardCategory('ex_nihilo').typeKey, 'trick');
  assert.equal(getCardCategory('ex_nihilo').badge, 'Cẩm Nang');

  // 4. Sấm Sét (lightning) -> Delayed Trick
  assert.equal(getCardCategory('lightning').typeKey, 'delayed');
  assert.equal(getCardCategory('lightning').badge, 'Trì Hoãn');

  // 5. Thanh Cương Kiếm (qinggang_sword) -> Weapon Equip
  assert.equal(getCardCategory('qinggang_sword').typeKey, 'equip');
  assert.equal(getCardCategory('qinggang_sword').badge, 'Vũ Khí');

  // 6. Bát Quái Trận (eight_diagram) -> Armor Equip
  assert.equal(getCardCategory('eight_diagram').typeKey, 'equip');
  assert.equal(getCardCategory('eight_diagram').badge, 'Phòng Cụ');

  // Fallback: Unknown card metadata never crashes
  const unknown = getCardCategory('unknown_custom_card_xyz');
  assert.equal(unknown.typeKey, 'unknown');
  assert.equal(unknown.className, 'type-unknown');

  const empty = getCardCategory(undefined);
  assert.equal(empty.typeKey, 'unknown');
});

test('resolveCardText resolves translations with layered fallback without leaking raw keys', () => {
  const mockTranslations: Record<string, string> = {
    slash: 'Sát',
    ':slash': 'Đánh 1 mục tiêu trong tầm.',
    ex_nihilo: 'Vô Trung Sinh Hữu',
    // :ex_nihilo is intentionally absent to test baseline fallback
  };
  const textResolver = (key: string) => mockTranslations[key] || key;

  // Case 1: Name and description present in dictionary
  const slashResult = resolveCardText({ name: 'slash' }, textResolver);
  assert.equal(slashResult.displayName, 'Sát');
  assert.equal(slashResult.description, 'Đánh 1 mục tiêu trong tầm.');

  // Case 2: Description absent from dictionary -> resolves from baseline without leaking ':ex_nihilo'
  const exNihiloResult = resolveCardText({ name: 'ex_nihilo' }, textResolver);
  assert.equal(exNihiloResult.displayName, 'Vô Trung Sinh Hữu');
  assert.match(exNihiloResult.description, /rút 2 lá bài/i);
  assert.ok(!exNihiloResult.description.startsWith(':'));

  // Case 3: Virtual card with trueName fallback
  const virtCardResult = resolveCardText(
    { name: 'converted_card', trueName: 'peach' },
    (k) => (k === 'converted_card' ? 'Hóa Đào' : k === ':peach' ? 'Hồi 1 máu.' : k)
  );
  assert.equal(virtCardResult.displayName, 'Hóa Đào');
  assert.equal(virtCardResult.description, 'Hồi 1 máu.');

  // Case 4: Completely unknown card without baseline -> safe message, never leaks raw ID
  const unknownResult = resolveCardText({ name: 'mysterious_relic' }, (k) => k);
  assert.equal(unknownResult.displayName, 'Lá bài chưa xác định');
  assert.equal(unknownResult.description, 'Chi tiết luật chưa được nạp.');

  // Case 5: Empty/undefined card -> safe default
  const emptyResult = resolveCardText(undefined, (k) => k);
  assert.equal(emptyResult.displayName, 'Lá bài chưa xác định');
  assert.equal(emptyResult.description, 'Chi tiết luật chưa được nạp.');
});

test('GameplayControls uses the card presentation while preserving the gameplay button contract', () => {
  const source = readFileSync(path.join(rootDir, 'src/GameplayControls.tsx'), 'utf8');
  assert.match(source, /import[\s\S]*HandCardItem[\s\S]*from ['"]\.\/HandCardItem['"]/);
  assert.match(source, /<HandCardItem[\s\S]*dispatch\('CardItem'/);
  assert.match(source, /<SelectedCardSummary/);
  assert.match(source, /<CardDetailSheet/);
  assert.doesNotMatch(source, /<ItemButton[^>]*card\b/);
});

test('the Lua/browser card projection carries the authoritative native art hints', () => {
  const hostLua = readFileSync(path.join(rootDir, 'src/engine/hostLua.ts'), 'utf8');
  const gameplayState = readFileSync(path.join(rootDir, 'src/store/gameplayState.ts'), 'utf8');
  assert.match(hostLua, /value\.getPicName/);
  assert.match(hostLua, /card\.picName\s*=\s*pic_name/);
  assert.match(hostLua, /card\.extension\s*=\s*extension/);
  assert.match(hostLua, /local function project_card_item/);
  assert.match(hostLua, /project_card_item\(value\)/);
  assert.match(hostLua, /project_card_item\(entry\.data\)/);
  assert.match(gameplayState, /'extension', 'picName'/);
});

test('styles.css contains essential Sanguosha card styles and prefers-reduced-motion reset', () => {
  const cssPath = path.join(rootDir, 'src/styles.css');
  const css = readFileSync(cssPath, 'utf8');

  // Verify class definitions
  assert.ok(css.includes('.sg-card-button'), 'Missing .sg-card-button');
  assert.ok(css.includes('.sg-card-top-left'), 'Missing .sg-card-top-left');
  assert.ok(css.includes('.sg-card-art-frame'), 'Missing .sg-card-art-frame');
  assert.ok(css.includes('.sg-card-native-art'), 'Missing .sg-card-native-art');
  assert.ok(css.includes('.sg-card-banner'), 'Missing .sg-card-banner');
  assert.ok(css.includes('.sg-card-popover-tooltip'), 'Missing .sg-card-popover-tooltip');
  assert.ok(css.includes('.sg-card-detail-sheet'), 'Missing .sg-card-detail-sheet');

  // Verify category accents
  assert.ok(css.includes('.type-basic'), 'Missing .type-basic');
  assert.ok(css.includes('.type-trick'), 'Missing .type-trick');
  assert.ok(css.includes('.type-delayed'), 'Missing .type-delayed');
  assert.ok(css.includes('.type-equip'), 'Missing .type-equip');

  // Verify reduced-motion reset
  assert.ok(
    css.includes('@media (prefers-reduced-motion: reduce)'),
    'Missing prefers-reduced-motion media query'
  );
  assert.ok(
    css.includes('transform: none !important') || css.includes('transform: none;'),
    'Missing transform none under reduced-motion'
  );
  assert.ok(css.includes('--card-lift: -22px'), 'Missing hover/focus card lift');
  assert.ok(css.includes('--card-lift: -30px'), 'Missing selected card lift');
  assert.match(css, /transform:\s*translateY\(var\(--card-lift/,
    'Hand cards must stay at zero rotation and lift only on the Y axis');
  assert.doesNotMatch(css, /\.sg-hand-fan[^{}]*\.sg-card-button:nth-child\(3n/,
    'Hand cards must not use the old fan rotation selectors');
  assert.match(css, /\.sg-card-button:disabled::after[\s\S]*background:\s*rgba\(10,\s*8,\s*6,\s*0\.60\)/,
    'Disabled cards need the dark veil overlay');
  assert.ok(css.includes('overflow: visible'), 'Card popovers need a visible parent overflow');
  assert.match(css, /\.sg-hand-fan[\s\S]*overflow-x:\s*auto/);
  assert.match(css, /\.sg-hand-fan[\s\S]*flex-wrap:\s*nowrap/);
  assert.match(css, /\.gameplay-controls\s*\{[^}]*min-width:\s*0/);
  assert.ok(css.includes('--sg-gold-pale'), 'Missing pale gold design token');
});

test('getNativeCardArtUrl uses the focused catalogue before exact package fallbacks', () => {
  assert.equal(getNativeCardArtUrl({ extension: 'mobile', name: 'ex_eight_diagram' }), '/packages/mobile/image/card/ex_eight_diagram.png');
  assert.equal(getNativeCardArtUrl('ex_eight_diagram'), '/packages/mobile/image/card/ex_eight_diagram.png');
  assert.equal(getNativeCardArtUrl('v33__ex_nihilo'), '/packages/gamemode/image/card/v33__ex_nihilo.png');
  assert.equal(getNativeCardArtUrl('thunder_blade'), '/packages/tenyear/image/card/thunder_blade.png');
  assert.equal(getNativeCardArtUrl('ex_crossbow'), '/packages/mobile/image/card/ex_crossbow.png');
  assert.equal(getNativeCardArtUrl('role__wooden_ox'), '/packages/standard_ex/image/card/role__wooden_ox.png');

  // The focused Quốc Chiến catalogue supplies the exact generic faces.
  assert.equal(getNativeCardArtUrl('slash'), '/card-catalog-art/slash.png');
  assert.equal(getNativeCardArtUrl('peach'), '/card-catalog-art/peach.png');
  assert.equal(getNativeCardArtUrl('ex_nihilo'), '/card-catalog-art/ex_nihilo.png');
  assert.equal(getNativeCardArtUrl('eight_diagram'), '/card-catalog-art/eight_diagram.png');
  assert.equal(getNativeCardArtUrl('dismantlement'), '/card-catalog-art/dismantlement.png');
  assert.equal(getNativeCardArtUrl('thunder__slash'), '/card-catalog-art/thunder__slash.png');
  assert.equal(getNativeCardArtUrl({ name: 'thunder__slash', picName: 'slash' }),
    '/card-catalog-art/thunder__slash.png', 'variant names must win over picName hints');

  // Unknown cards strictly return null, never arbitrary external images
  assert.equal(getNativeCardArtUrl('custom_unknown_123'), null);
  assert.equal(getNativeCardArtUrl(undefined), null);
});

test('Vite emits the native card whitelist into production output as well as serving it in dev', () => {
  const source = readFileSync(path.join(rootDir, 'vite.config.ts'), 'utf8');
  assert.match(source, /generateBundle/);
  assert.match(source, /v33__ex_nihilo\.png/);
  assert.match(source, /quoc-chien-card-inventory\.json/);
  assert.match(source, /card-catalog-art/);
  assert.match(source, /emitFile/);
});
