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
import {
  cardAudioUrlCandidates,
  equipSkillAudioUrlCandidates,
  nativeSoundPathCandidates,
  soundManager,
  SoundManager,
} from '../src/engine/webAudioSfx';
import { getCardEquipAudioType } from '../src/HandCardItem';
import { CATALOG_CARD_ART_NAMES } from '../src/catalogCardArt';
import { projectNativeVfx } from '../src/store/nativeVfxEvents';
import { reduceUiEvent, initialSnapshot } from '../src/store/gameStore';
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
  assert.equal('activeTargetIndicator' in slashLog, false);

  // Thuận Thủ Khiên Dương chỉ định mục tiêu rõ ràng
  const snatchLog = parseVfxFromGameLog('#UseCardToTargets:1:3:snatch[diamond:3]');
  assert.ok(snatchLog);
  assert.equal('activeTargetIndicator' in snatchLog, false);

  // Quá Hà Triệt Kiều chỉ định mục tiêu rõ ràng
  const dismantlementLog = parseVfxFromGameLog('#UseCardToTargets:2:1:dismantlement[spade:Q]');
  assert.ok(dismantlementLog);
  assert.equal('activeTargetIndicator' in dismantlementLog, false);

  // Đa mục tiêu
  const fireSlashLog = parseVfxFromGameLog('#UseCardToTargets:1:2,3,4:fire__slash');
  assert.ok(fireSlashLog);
  assert.deepEqual(fireSlashLog.flyingCard, {
    fromPlayerId: 1,
    toPlayerIds: [2, 3, 4],
    cardName: 'fire__slash',
  });
  assert.equal('activeTargetIndicator' in fireSlashLog, false);

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

  // GameLog strings never trigger native damage VFX.
  assert.equal(parseVfxFromGameLog('#Damage:1:3:2:thunder:thunder__slash'), null);
  assert.equal(parseVfxFromGameLog('#Damage:1:4:1:fire:fire_attack'), null);

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

  // #UseCardToCard:from:to:card
  const cardToCardLog = parseVfxFromGameLog('#UseCardToCard:1:2:nullification[spade:11]');
  assert.deepEqual(cardToCardLog, {
    flyingCard: {
      fromPlayerId: 1,
      toPlayerIds: [2],
      cardName: 'nullification',
      suit: 1,
      number: 11,
    },
  });

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
    'ice_damage.mp3',
    'recast.mp3',
    'losemaxhp.mp3',
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

  // Kiểm tra 24 file voice Quốc Chiến
  const hegemonyCards = [
    'alliance_feast.mp3', 'await_exhausted.mp3', 'befriend_attacking.mp3', 'burning_camps.mp3',
    'fight_together.mp3', 'heg__nullification.mp3', 'imperial_order.mp3', 'known_both.mp3',
    'lure_tiger.mp3', 'rob__jink.mp3', 'sa__drowning.mp3', 'threaten_emperor.mp3',
  ];
  for (const c of hegemonyCards) {
    assert.ok(fs.existsSync(path.join(publicDir, 'packages/hegemony/audio/card/female', c)), `Missing female hegemony card: ${c}`);
    assert.ok(fs.existsSync(path.join(publicDir, 'packages/hegemony/audio/card/male', c)), `Missing male hegemony card: ${c}`);
  }

  // Kiểm tra 11 file hiệu ứng trang bị chuẩn
  const standardEquips = [
    'axe.mp3', 'blade.mp3', 'crossbow.mp3', 'double_swords.mp3', 'eight_diagram.mp3',
    'halberd.mp3', 'ice_sword.mp3', 'kylin_bow.mp3', 'nioh_shield.mp3', 'qinggang_sword.mp3', 'spear.mp3',
  ];
  for (const e of standardEquips) {
    assert.ok(fs.existsSync(path.join(publicDir, 'packages/standard_cards/audio/card', e)), `Missing standard equip sound: ${e}`);
  }

  // Kiểm tra 5 file hiệu ứng trang bị Quân Tranh
  const maneuveringEquips = ['fan.mp3', 'guding_blade.mp3', 'silver_lion.mp3', 'vine.mp3', 'vineburn.mp3'];
  for (const e of maneuveringEquips) {
    assert.ok(fs.existsSync(path.join(publicDir, 'packages/maneuvering/audio/card', e)), `Missing maneuvering equip sound: ${e}`);
  }

  // Kiểm tra animation frame folders
  const animFolders = ['slash', 'fire__slash', 'thunder__slash', 'jink', 'peach', 'analeptic', 'damage'];
  for (const folder of animFolders) {
    const dir = path.join(publicDir, 'anim', folder);
    assert.ok(fs.existsSync(dir), `Missing anim folder: ${folder}`);
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.png'));
    assert.ok(files.length >= 6, `Folder ${folder} must contain at least 6 frames, found ${files.length}`);
  }

  // Source package media remains available for exact extension/name lookup.
  const runtimeRoot = path.resolve(new URL('../../../runtime', import.meta.url).pathname);
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/gamemode/image/card/drowning.png')));
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/gamemode/audio/card/male/drowning.mp3')));
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/mobile/audio/card/ex_crossbow.mp3')));
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/hegemony/audio/card/male/known_both.mp3')));
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/standard_cards/audio/card/eight_diagram.mp3')));
  assert.ok(fs.existsSync(path.join(runtimeRoot, 'packages/maneuvering/audio/card/vine.mp3')));
});

test('soundManager handles native damage sounds, card voices, equip sounds, and toggle modes', () => {
  assert.doesNotThrow(() => {
    soundManager.playDamageSound('normal_damage', 1);
    soundManager.playDamageSound('fire_damage', 2);
    soundManager.playDamageSound('thunder_damage', 1);
    soundManager.playDamageSound('ice_damage', 1);
    soundManager.playCardVoice('slash', 'male');
    soundManager.playCardVoice('slash', 'female');
    soundManager.playCardVoice('alliance_feast', 'female');
    soundManager.playEquipSkillSound('eight_diagram');
    soundManager.playEquipSkillSound('vine');
    soundManager.playEquipSound('weapon');
    soundManager.playEquipSound('armor');
    soundManager.playEquipSound('horse');
    soundManager.playFlySound();
    soundManager.playDrawSound();
    soundManager.playChainSound();
    soundManager.playLoseHpSound();
    soundManager.playLoseMaxHpSound();
    soundManager.playRecastSound();
  });

  soundManager.setUseNativeAudio(false);
  assert.equal(soundManager.isUseNativeAudio(), false);
  soundManager.setUseNativeAudio(true);
  assert.equal(soundManager.isUseNativeAudio(), true);
});

test('card audio candidates follow package and gender fallback order', () => {
  const gamemodeFemale = cardAudioUrlCandidates('drowning', { extension: 'gamemode', gender: 'female' });
  assert.deepEqual(gamemodeFemale.slice(0, 3), [
    '/packages/gamemode/audio/card/female/drowning.mp3',
    '/audio/card/female/drowning.mp3',
    '/packages/hegemony/audio/card/female/drowning.mp3',
  ]);
  const mobileEquipSkill = cardAudioUrlCandidates('ex_crossbow', { extension: 'mobile', gender: 'male' });
  assert.equal(mobileEquipSkill[0], '/packages/mobile/audio/card/male/ex_crossbow.mp3');
  assert.ok(mobileEquipSkill.includes('/packages/mobile/audio/card/ex_crossbow.mp3'));
  const femaleFallback = cardAudioUrlCandidates('slash', { gender: 'female' });
  assert.deepEqual(femaleFallback.slice(0, 2), [
    '/audio/card/female/slash.mp3',
    '/packages/hegemony/audio/card/female/slash.mp3',
  ]);
  const prefixedCandidate = cardAudioUrlCandidates('heg__nullification', { gender: 'female' });
  assert.ok(prefixedCandidate.includes('/audio/card/female/heg__nullification.mp3'));
  assert.ok(prefixedCandidate.includes('/audio/card/female/nullification.mp3'));
});

test('native sound path candidates and equip skill candidates resolve authentic FreeKill paths', () => {
  assert.deepEqual(nativeSoundPathCandidates('./audio/system/recast'), ['/audio/system/recast.mp3']);
  assert.deepEqual(nativeSoundPathCandidates('./audio/card/common/weapon'), ['/audio/card/common/weapon.mp3']);
  assert.ok(nativeSoundPathCandidates('./packages/standard_cards/audio/card/axe').includes('/packages/standard_cards/audio/card/axe.mp3'));
  assert.ok(nativeSoundPathCandidates('./packages/hegemony/audio/card/male/known_both').includes('/packages/hegemony/audio/card/male/known_both.mp3'));
  assert.ok(nativeSoundPathCandidates('./packages/hegemony/audio/card/female/heg__nullification').includes('/packages/hegemony/audio/card/female/nullification.mp3'));
  assert.ok(equipSkillAudioUrlCandidates('eight_diagram').includes('/packages/standard_cards/audio/card/eight_diagram.mp3'));
  assert.ok(equipSkillAudioUrlCandidates('vine').includes('/packages/maneuvering/audio/card/vine.mp3'));

  assert.equal(getCardEquipAudioType('hualiu'), 'horse');
  assert.equal(getCardEquipAudioType('grand_ensign'), 'armor');
  assert.equal(getCardEquipAudioType('peace_spell'), 'armor');
  assert.equal(getCardEquipAudioType('blade'), 'weapon');
});

test('card and equipment use audio plays once in either server/log arrival order', () => {
  const played: string[] = [];
  const previousAudio = globalThis.Audio;
  class FakeAudio {
    constructor(url: string) { played.push(url); }
    play() { return Promise.resolve(); }
  }
  globalThis.Audio = FakeAudio as unknown as typeof Audio;
  try {
    const serverFirst = new SoundManager();
    serverFirst.playNativeSoundPath('./packages/hegemony/audio/card/female/known_both');
    serverFirst.playCardUseSound('known_both', { gender: 'male' });
    assert.equal(played.length, 1);
    assert.equal(played[0], '/packages/hegemony/audio/card/female/known_both.mp3');

    played.length = 0;
    const logFirst = new SoundManager();
    logFirst.playCardUseSound('known_both', { gender: 'female' });
    logFirst.playNativeSoundPath('./packages/hegemony/audio/card/female/known_both');
    assert.equal(played.length, 1);

    played.length = 0;
    const equipment = new SoundManager();
    equipment.playCardUseSound('blade', { equipType: 'weapon' });
    equipment.playNativeSoundPath('./audio/card/common/weapon');
    assert.deepEqual(played, ['/audio/card/common/weapon.mp3']);
  } finally {
    globalThis.Audio = previousAudio;
  }
});

test('native Indicate fan-out and sequential target chains are handled exactly', () => {
  const data = { type: 'Indicate', from: 1, to: [[2], [3, 4, 5]] };
  assert.deepEqual(projectNativeVfx('Animate', data), [
    { kind: 'indicate', fromPlayerId: 1, toPlayerIds: [2] },
    { kind: 'indicate', fromPlayerId: 1, toPlayerIds: [3] },
    { kind: 'indicate', fromPlayerId: 3, toPlayerIds: [4, 5] },
  ]);
  assert.deepEqual(projectNativeVfx('Animate', { type: 'Emotion', from: 1, to: [[2]] }), []);
  assert.deepEqual(projectNativeVfx('Animate', { type: 'Indicate', from: 1, to: ['2', [], [0]] }), []);
  const logOnly = reduceUiEvent(initialSnapshot, 'GameLog', '#UseCardToTargets:1:2:slash');
  assert.equal(logOnly.nativeVfxSequence, 0);
  const next = reduceUiEvent(logOnly, 'Animate', data);
  assert.equal(next.nativeVfxSequence, 3);
  assert.deepEqual(next.nativeVfxEvents.map((event) => event.sequence), [1, 2, 3]);
});

test('LogEvent projects Damage, PlaySound, LoseHP, and ChangeMaxHp', () => {
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'Damage', to: -2, damageType: 'fire_damage', damageNum: 2 }),
    [{ kind: 'damage', targetPlayerId: -2, damageType: 'fire_damage', damageNum: 2 }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'Damage', to: 4, damageType: 'ice_damage' }),
    [{ kind: 'damage', targetPlayerId: 4, damageType: 'ice_damage', damageNum: 1 }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'Damage', to: 4 }),
    [{ kind: 'damage', targetPlayerId: 4, damageType: 'normal_damage', damageNum: 1 }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'PlaySound', name: './audio/system/recast' }),
    [{ kind: 'sound', path: './audio/system/recast' }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'LoseHP', to: -2 }),
    [{ kind: 'losehp', targetPlayerId: -2 }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'ChangeMaxHp', to: 3, num: -1 }),
    [{ kind: 'losemaxhp', targetPlayerId: 3 }]);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'ChangeMaxHp', to: 3, num: 1 }), []);
  assert.deepEqual(projectNativeVfx('LogEvent', { type: 'Damage', to: '2' }), []);
  assert.equal(parseVfxFromGameLog('#Damage:1:2:1:fire:fire_attack'), null);
  const next = reduceUiEvent(initialSnapshot, 'LogEvent', { type: 'Damage', to: -2, damageType: 'fire_damage', damageNum: 2 });
  assert.equal(next.nativeVfxSequence, 1);
  assert.equal(next.nativeVfxEvents[0].kind, 'damage');
});
