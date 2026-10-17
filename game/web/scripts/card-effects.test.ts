import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  parseVfxFromGameLog,
  parseCardToken,
  resolveCardImpactKind,
  getSeatCenterCoordinates,
  PORTRAIT_SEAT_PERCENTAGES,
  LANDSCAPE_SEAT_PERCENTAGES,
} from '../src/store/cardVfxState';
import { calculateBezierCurve, TargetingArrowOverlay } from '../src/TargetingOverlay';
import { CardFlyOverlay } from '../src/CardVfxOverlay';
import { soundManager, SoundManager } from '../src/engine/webAudioSfx';
import { CATALOG_CARD_ART_NAMES } from '../src/catalogCardArt';
import { ANIM_FRAME_COUNTS, preloadAnimFrames } from '../src/NativeVfxAnim';
import fs from 'node:fs';
import path from 'node:path';

test('resolveCardImpactKind correctly maps card names to VFX categories', () => {
  // Sát thường
  assert.equal(resolveCardImpactKind('slash'), 'slash');
  assert.equal(resolveCardImpactKind('sa__blade'), 'slash');
  assert.equal(resolveCardImpactKind('duel'), 'slash');

  // Hỏa Sát / Hỏa Công / Hỏa Thiêu
  assert.equal(resolveCardImpactKind('fire__slash'), 'fire_slash');
  assert.equal(resolveCardImpactKind('burning_camps'), 'fire_slash');
  assert.equal(resolveCardImpactKind('fire_attack'), 'fire_slash');

  // Lôi Sát / Thiểm Điện
  assert.equal(resolveCardImpactKind('thunder__slash'), 'thunder_slash');
  assert.equal(resolveCardImpactKind('lightning'), 'thunder_slash');

  // Thiểm né đòn
  assert.equal(resolveCardImpactKind('jink'), 'jink');
  assert.equal(resolveCardImpactKind('rob__jink'), 'jink');

  // Đào hồi máu & Đào Viên Kết Nghĩa
  assert.equal(resolveCardImpactKind('peach'), 'peach');
  assert.equal(resolveCardImpactKind('god_salvation'), 'peach');

  // Tửu / Say rượu
  assert.equal(resolveCardImpactKind('analeptic'), 'analeptic');

  // Vô Giải Khả Kích
  assert.equal(resolveCardImpactKind('nullification'), 'nullification');
  assert.equal(resolveCardImpactKind('heg__nullification'), 'nullification');

  // Khác (mặc định)
  assert.equal(resolveCardImpactKind('dismantlement'), 'generic_impact');
});
test('parseCardToken extracts card name, suit, and rank', () => {
  assert.deepEqual(parseCardToken('slash'), { name: 'slash' });
  assert.deepEqual(parseCardToken('slash[spade:7]'), { name: 'slash', suit: 1, number: 7 });
  assert.deepEqual(parseCardToken('peach[heart:12]'), { name: 'peach', suit: 3, number: 12 });
  assert.deepEqual(parseCardToken('jink[diamond:2]'), { name: 'jink', suit: 4, number: 2 });
  assert.deepEqual(parseCardToken('thunder__slash[club:8]'), { name: 'thunder__slash', suit: 2, number: 8 });
  assert.deepEqual(parseCardToken(''), { name: '' });
});

test('parseVfxFromGameLog correctly parses single and multi-target card usages and avatar reactions', () => {
  // #UseCardToTargets:from:to:card
  const slashLog = parseVfxFromGameLog('#UseCardToTargets:1:2:slash[spade:7]');
  assert.ok(slashLog);
  assert.deepEqual(slashLog.flyingCard, {
    fromPlayerId: 1,
    toPlayerIds: [2],
    cardName: 'slash',
    suit: 1,
    number: 7,
  });

  // Đa mục tiêu
  const fireSlashLog = parseVfxFromGameLog('#UseCardToTargets:1:2,3,4:fire__slash');
  assert.ok(fireSlashLog);
  assert.deepEqual(fireSlashLog.flyingCard, {
    fromPlayerId: 1,
    toPlayerIds: [2, 3, 4],
    cardName: 'fire__slash',
  });

  // #UseCard:from:card (không có mục tiêu cụ thể, ví dụ Đào / Tửu)
  const peachLog = parseVfxFromGameLog('#UseCard:1:peach[heart:12]');
  assert.ok(peachLog);
  assert.deepEqual(peachLog.flyingCard, {
    fromPlayerId: 1,
    toPlayerIds: [],
    cardName: 'peach',
    suit: 3,
    number: 12,
  });

  // #ResponsePlayCard:from:card (đánh bài phản hồi, ví dụ Thiểm -> avatar reaction: dodge-slide)
  const jinkLog = parseVfxFromGameLog('#ResponsePlayCard:2:jink[diamond:2]');
  assert.ok(jinkLog);
  assert.equal(jinkLog.flyingCard?.fromPlayerId, 2);
  assert.equal(jinkLog.flyingCard?.cardName, 'jink');
  assert.equal(jinkLog.flyingCard?.suit, 4);
  assert.equal(jinkLog.flyingCard?.number, 2);
  assert.equal(jinkLog.impact?.targetPlayerId, 2);
  assert.equal(jinkLog.impact?.kind, 'jink');
  assert.deepEqual(jinkLog.avatarReaction, {
    playerId: 2,
    type: 'dodge-slide',
  });

  // #Damage:from:to:damage:nature:card -> avatar reaction: hit-shake
  const thunderDamageLog = parseVfxFromGameLog('#Damage:1:3:2:thunder:thunder__slash');
  assert.ok(thunderDamageLog);
  assert.equal(thunderDamageLog.impact?.targetPlayerId, 3);
  assert.equal(thunderDamageLog.impact?.kind, 'thunder_slash');
  assert.equal(thunderDamageLog.impact?.damageAmount, 2);
  assert.deepEqual(thunderDamageLog.avatarReaction, {
    playerId: 3,
    type: 'hit-shake',
  });

  const fireDamageLog = parseVfxFromGameLog('#Damage:1:4:1:fire:fire_attack');
  assert.ok(fireDamageLog);
  assert.equal(fireDamageLog.impact?.targetPlayerId, 4);
  assert.equal(fireDamageLog.impact?.kind, 'fire_slash');
  assert.deepEqual(fireDamageLog.avatarReaction, {
    playerId: 4,
    type: 'hit-shake',
  });

  // #HpRecover:player:num -> avatar reaction: heal-glow
  const healLog = parseVfxFromGameLog('#HpRecover:2:1');
  assert.ok(healLog);
  assert.equal(healLog.impact?.targetPlayerId, 2);
  assert.equal(healLog.impact?.kind, 'peach');
  assert.deepEqual(healLog.avatarReaction, {
    playerId: 2,
    type: 'heal-glow',
  });

  // #UseCardNullified:from:arg
  const nullifiedLog = parseVfxFromGameLog('#UseCardNullified:1:ex_nihilo');
  assert.ok(nullifiedLog);
  assert.equal(nullifiedLog.impact?.targetPlayerId, 1);
  assert.equal(nullifiedLog.impact?.kind, 'nullification');

  // Log không liên quan hoặc rỗng
  assert.equal(parseVfxFromGameLog(''), null);
  assert.equal(parseVfxFromGameLog('RoundStart:1'), null);
  assert.equal(parseVfxFromGameLog('DrawNCards:1:2'), null);
});

test('calculateBezierCurve generates smooth arc path between source and target points', () => {
  const from = { x: 100, y: 300 };
  const to = { x: 400, y: 100 };

  const { path, mid } = calculateBezierCurve(from, to, 0.25);

  assert.ok(path.startsWith('M 100.0 300.0 Q'));
  assert.ok(path.endsWith('400.0 100.0'));
  assert.ok(typeof mid.x === 'number' && Number.isFinite(mid.x));
  assert.ok(typeof mid.y === 'number' && Number.isFinite(mid.y));

  // Kiểm tra điểm giữa nằm ở khoảng giữa hai tọa độ
  assert.ok(mid.x > 100 && mid.x < 500);
});

test('getSeatCenterCoordinates calculates accurate spatial coordinates across orientations', () => {
  const containerWidth = 390;
  const containerHeight = 844;

  // Portrait self seat
  const selfPortrait = getSeatCenterCoordinates({
    isLandscape: false,
    isSelf: true,
    containerWidth,
    containerHeight,
  });
  assert.ok(selfPortrait.x > 30 && selfPortrait.x < 80);
  assert.ok(selfPortrait.y > 700);

  // Portrait 4-player opponent seat 0 (right)
  const oppPortrait4 = getSeatCenterCoordinates({
    isLandscape: false,
    seatIndex: 0,
    totalSeats: 4,
    containerWidth,
    containerHeight,
  });
  const expectedP0 = PORTRAIT_SEAT_PERCENTAGES[4][0];
  assert.equal(oppPortrait4.x, (expectedP0.left / 100) * containerWidth);
  assert.equal(oppPortrait4.y, (expectedP0.top / 100) * containerHeight);

  // Landscape 8-player elliptical arch
  const landscapeWidth = 844;
  const landscapeHeight = 390;

  const selfLandscape = getSeatCenterCoordinates({
    isLandscape: true,
    isSelf: true,
    containerWidth: landscapeWidth,
    containerHeight: landscapeHeight,
  });
  assert.equal(selfLandscape.x, 52); // Column 1 center
  assert.ok(selfLandscape.y > 300);

  // Landscape 8-player top center seat (index 3)
  const oppLandscape8 = getSeatCenterCoordinates({
    isLandscape: true,
    seatIndex: 3,
    totalSeats: 8,
    containerWidth: landscapeWidth,
    containerHeight: landscapeHeight,
  });
  const expectedL3 = LANDSCAPE_SEAT_PERCENTAGES[8][3];
  assert.equal(oppLandscape8.x, (expectedL3.left / 100) * landscapeWidth);
  assert.equal(oppLandscape8.y, (expectedL3.top / 100) * landscapeHeight);
});

test('soundManager and SoundManager support Web Audio API synthesis and custom audio fallback', () => {
  const customSound = new SoundManager();

  // Test custom audio registration
  customSound.registerCustomAudio('slash', '/custom-sfx/slash.mp3');
  assert.equal(customSound.getCustomAudio('slash'), '/custom-sfx/slash.mp3');
  assert.equal(customSound.getCustomAudio('jink'), undefined);

  customSound.clearCustomAudio('slash');
  assert.equal(customSound.getCustomAudio('slash'), undefined);

  // Synthesis does not throw in test environments
  assert.doesNotThrow(() => {
    soundManager.playCardPlaySound();
    soundManager.playSlashSound('normal');
    soundManager.playSlashSound('fire');
    soundManager.playSlashSound('thunder');
    soundManager.playJinkSound();
    soundManager.playPeachSound();
    soundManager.playAnalepticSound();
    soundManager.playThunderSound();
    soundManager.playNullifySound();
  });

  soundManager.setEnabled(false);
  assert.equal(soundManager.isEnabled(), false);
  soundManager.setEnabled(true);
  assert.equal(soundManager.isEnabled(), true);
});

test('overlay aliases and catalog card art are properly exported and populated', () => {
  assert.ok(TargetingArrowOverlay);
  assert.ok(CardFlyOverlay);
  assert.ok(CATALOG_CARD_ART_NAMES.has('slash'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('fire__slash'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('thunder__slash'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('jink'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('peach'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('analeptic'));
  assert.ok(CATALOG_CARD_ART_NAMES.has('nullification'));
});

test('NativeVfxAnim exports authentic FreeKill frame counts and preload helper', async () => {
  assert.equal(ANIM_FRAME_COUNTS.slash, 24);
  assert.equal(ANIM_FRAME_COUNTS.fire__slash, 24);
  assert.equal(ANIM_FRAME_COUNTS.thunder__slash, 24);
  assert.equal(ANIM_FRAME_COUNTS.jink, 23);
  assert.equal(ANIM_FRAME_COUNTS.peach, 17);
  assert.equal(ANIM_FRAME_COUNTS.analeptic, 17);
  assert.equal(ANIM_FRAME_COUNTS.damage, 6);

  await assert.doesNotReject(preloadAnimFrames('slash'));
});

test('authentic upstream FreeKill audio and animation assets exist on disk in web public', () => {
  const publicDir = path.resolve(new URL('.', import.meta.url).pathname, '../public');

  // Kiểm tra âm thanh hệ thống
  const requiredSfx = [
    'normal_damage.mp3',
    'fire_damage.mp3',
    'thunder_damage.mp3',
    'wine1.mp3',
    'fly1.mp3',
    'draw.mp3',
    'chain.mp3',
    'losehp.mp3',
  ];
  for (const sfx of requiredSfx) {
    const sfxPath = path.join(publicDir, 'audio/system', sfx);
    assert.ok(fs.existsSync(sfxPath), `Missing required SFX: ${sfx}`);
  }

  // Kiểm tra voice bài nam/nữ
  const requiredVoices = ['slash.mp3', 'jink.mp3', 'peach.mp3', 'nullification.mp3'];
  for (const v of requiredVoices) {
    assert.ok(fs.existsSync(path.join(publicDir, 'audio/card/male', v)), `Missing male voice: ${v}`);
    assert.ok(fs.existsSync(path.join(publicDir, 'audio/card/female', v)), `Missing female voice: ${v}`);
  }

  // Kiểm tra animation frame folders
  const animFolders = ['slash', 'fire__slash', 'thunder__slash', 'jink', 'peach', 'analeptic', 'damage'];
  for (const folder of animFolders) {
    const dir = path.join(publicDir, 'anim', folder);
    assert.ok(fs.existsSync(dir), `Missing anim folder: ${folder}`);
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.png'));
    assert.ok(files.length >= 6, `Folder ${folder} must contain at least 6 frames, found ${files.length}`);
  }
});

test('soundManager handles native damage sounds, card voices, equip sounds, and toggle modes', () => {
  assert.doesNotThrow(() => {
    soundManager.playDamageSound('normal_damage', 1);
    soundManager.playDamageSound('fire_damage', 2);
    soundManager.playDamageSound('thunder_damage', 1);
    soundManager.playDamageSound('losehp', 1);
    soundManager.playCardVoice('slash', 'male');
    soundManager.playCardVoice('slash', 'female');
    soundManager.playEquipSound('weapon');
    soundManager.playEquipSound('armor');
    soundManager.playEquipSound('horse');
    soundManager.playFlySound();
    soundManager.playDrawSound();
    soundManager.playChainSound();
    soundManager.playLoseHpSound();
  });

  soundManager.setUseNativeAudio(false);
  assert.equal(soundManager.isUseNativeAudio(), false);
  soundManager.setUseNativeAudio(true);
  assert.equal(soundManager.isUseNativeAudio(), true);
});
