import { useEffect, useMemo, useState } from 'react';
import { createPortal } from 'react-dom';
import { BASELINE_NAMES, formatRank, getSuitInfo } from './HandCardItem';
import { useDisplayText } from './engine/displayText';
import type { GameplayItem } from './store/gameplayState';
import { isBoardFocusActive, type BoardEquipment, type BoardFocusState, type BoardPlayer } from './store/boardState';
import { generalArtCandidates } from './generalArt';
import type { RoomPlayer } from './store/gameStore';
import { EquipIcon, TargetCrosshairIcon } from './EquipIcons';
import type { AvatarReactionType, DamagePopEvent, SkillCalloutEvent } from './store/cardVfxState';
import NativeVfxAnim from './NativeVfxAnim';
import { GeneralInfoTrigger, type SkillGroup } from './SkillInfo';

export type Faction = 'wei' | 'shu' | 'wu' | 'qun' | 'neutral';

export function factionClass(kingdom: string | null | undefined): Faction {
  switch (kingdom?.toLowerCase()) {
    case 'wei': return 'wei';
    case 'shu': return 'shu';
    case 'wu': return 'wu';
    case 'qun': return 'qun';
    default: return 'neutral';
  }
}

export interface PlayerPhotoPanelProps {
  player: RoomPlayer;
  game: BoardPlayer | undefined;
  self: boolean;
  seat: number;
  active: boolean;
  target?: GameplayItem;
  busy?: boolean;
  onTarget?: () => void;
  compact?: boolean;
  style?: React.CSSProperties;
  isShaking?: boolean;
  avatarReaction?: AvatarReactionType | null;
  damagePop?: DamagePopEvent | null;
  equipmentPortalTarget?: HTMLElement | null;
  getGeneralSkills?: (name: string) => string[];
  focusState?: BoardFocusState | null;
  skillCallout?: SkillCalloutEvent | null;
}

type EquipmentSlotKey = 'treasure' | 'weapon' | 'armor' | 'defensive_ride' | 'offensive_ride';

function cardSlot(card: BoardEquipment): EquipmentSlotKey | null {
  switch (card.subtype) {
    case 'treasure': return 'treasure';
    case 'weapon': return 'weapon';
    case 'armor': return 'armor';
    case 'defensive_ride': return 'defensive_ride';
    case 'offensive_ride': return 'offensive_ride';
    default: return null;
  }
}

function suitInfo(card: BoardEquipment) {
  const suit = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  return { text: `${suit.symbol}${rank}`, colorClass: suit.colorClass };
}

function PortraitImage({
  name, extension, text, deputy, backLabel, kingdom, unrevealed = false,
}: {
  name: string | null;
  extension: string | null;
  text: (value: string) => string;
  deputy: boolean;
  backLabel: string;
  kingdom?: string | null;
  unrevealed?: boolean;
}) {
  const candidates = useMemo(() => generalArtCandidates({ name, extension }), [name, extension]);
  const [candidateIndex, setCandidateIndex] = useState(0);
  useEffect(() => setCandidateIndex(0), [name, extension]);
  const displayName = name ? text(name) : backLabel;

  const backSrc = kingdom && ['wei', 'shu', 'wu', 'qun', 'god'].includes(kingdom)
    ? `/photo-assets/back/${kingdom}.png`
    : '/photo-assets/back/qun.png';

  return <div className={`sg-portrait-slot native-general-slot ${deputy ? 'sg-portrait-deputy' : 'sg-portrait-main'} ${name ? '' : 'sg-portrait-hidden'} ${unrevealed ? 'is-unrevealed sg-general-unrevealed' : ''}`}
    aria-label={displayName}>
    <div className="sg-portrait-art">
      {name && candidateIndex < candidates.length
        ? <img src={candidates[candidateIndex]} alt={displayName}
          onError={() => setCandidateIndex((index) => index + 1)} />
        : <div className="sg-portrait-card-back native-hidden-back" title={displayName}>
            <img src={backSrc} alt="" className="sg-portrait-card-back-img" aria-hidden="true" />
          </div>}
      {name && <span className={`sg-portrait-name sg-calligraphy-name native-calligraphy-name ${deputy ? 'right' : 'left'}`} title={displayName}>{displayName}</span>}
      {unrevealed && <span className="sg-unrevealed-badge" aria-hidden="true">Chưa lật</span>}
    </div>
  </div>;
}

/** FreeKill LunarLtk/Components/Photo/HpBar.qml: 0/1 red, 2 yellow,
 * 3+ or full HP green. These are absolute HP levels, not HP percentages. */
export function getMagatamaState(hp: number | null | undefined, maxHp: number | null | undefined): 0 | 1 | 2 | 3 {
  if (hp == null || maxHp == null || !Number.isFinite(hp) || !Number.isFinite(maxHp) || maxHp <= 0 || hp <= 0) return 0;
  if (hp >= 3 || hp >= maxHp) return 3;
  return hp >= 2 ? 2 : 1;
}

function HealthColumn({ game }: { game: BoardPlayer | undefined }) {
  const hp = game?.hp;
  const maxHp = game?.maxHp;
  const slots = maxHp != null && Number.isFinite(maxHp) && maxHp > 0 ? Math.min(12, Math.ceil(maxHp)) : 0;
  const filled = slots > 0 && hp != null && Number.isFinite(hp) ? Math.max(0, Math.min(slots, Math.ceil(hp))) : 0;
  const hpState = getMagatamaState(hp, maxHp);
  const showFraction = maxHp == null || maxHp > 4 ||
    (hp != null && hp > maxHp) || ((game?.shield ?? 0) > 0 && maxHp > 3);
  const label = `Sinh lực: ${hp ?? '?'} trên ${maxHp ?? '?'}`;

  return <div className="sg-hp-vertical-column native-hp-vertical-column" aria-label={label} title={label}>
    {game?.shield != null && game.shield > 0 && <div className="sg-shield-readout" title={`Khiên: ${game.shield}`}>
      <img src="/photo-assets/magatama/shield.png" alt="" aria-hidden="true" />
      <span>{game.shield}</span>
    </div>}
    {!showFraction ? (
      <div className="sg-magatama-column" aria-hidden="true">
        {Array.from({ length: slots }, (_, index) => {
          const active = index >= slots - filled;
          return <img key={index}
            className={`native-heg-hp-disc-v ${active ? 'sg-magatama-filled' : 'sg-magatama-empty'}`}
            src={`/photo-assets/magatama/${active ? hpState : 0}-heg.png`} alt="" />;
        })}
      </div>
    ) : (
      <>
        <img className="native-heg-hp-disc-v sg-magatama-filled"
          src={`/photo-assets/magatama/${hpState}-heg.png`} alt="" aria-hidden="true" />
        <div className={`sg-hp-vertical-fraction native-hp-vertical-fraction ${hpState <= 1 ? 'hp-danger' : hpState === 2 ? 'hp-warning' : ''}`}>
          <span>{hp ?? '?'}</span>
          <span className="hp-slash">/</span>
          <span>{maxHp ?? '?'}</span>
        </div>
      </>
    )}
    <span className="sg-health-compat sg-visually-hidden">♥ {hp ?? '?'} / {maxHp ?? '?'}</span>
  </div>;
}

function HandCardBadge({ count }: { count: number | null | undefined }) {
  const displayCount = count ?? '?';
  return <div className="sg-hand-count-badge native-handcard-badge" title={`${displayCount} lá trên tay`}>
    <span className="native-handcard-count-text">{displayCount}</span>
    <span className="sg-hand-count-compat sg-visually-hidden">{displayCount} lá trên tay</span>
  </div>;
}

function resolveEquipName(card: BoardEquipment | undefined, fallback: string, text: (v: string) => string): string {
  if (!card) return fallback;
  const t = text(card.name);
  if (t && t !== card.name) return t;
  const base = card.name.replace(/^.*__/, '');
  return BASELINE_NAMES[base] ?? BASELINE_NAMES[card.name] ?? t;
}

const EQUIP_ICON_ALIASES: Record<string, string> = {
  ex_crossbow: 'crossbow',
  real__crossbow: 'crossbow',
  sa__halberd: 'halberd',
  sa__blade: 'blade',
  guding_blade: 'guding_blade',
  ex_eight_diagram: 'eight_diagram',
  ex_nioh_shield: 'nioh_shield',
  ex_silver_lion: 'silver_lion',
  ex_vine: 'vine',
  sa__breastplate: 'breastplate',
  wooden_ox: 'role__wooden_ox',
  six_swords: 'double_swords',
  triblade: 'yajiao_spear',
  jade_seal: 'mobile_seal',
  dunjia_book: 'taigong_tactics',
  // FreeKill's built-in resource lookup falls back to unknown.png when a
  // package does not ship a dedicated equip silhouette. Keep that behavior
  // explicit so live gameplay never emits a 404 for those cards.
  jingfan: 'unknown',
  liulongcanjia: 'unknown',
  m_liuyi__liulongcanjia: 'm_liuyi__liulongcanjia',
};

export function getNativeEquipIconUrl(slot: string, card?: BoardEquipment): string | null {
  if (!card) return null;
  // FreeKill EquipItem.qml: horses (both defensive and offensive) always use "horse.png"
  if (slot === 'defensive_ride' || slot === 'offensive_ride' || card.subtype === 'defensive_ride' || card.subtype === 'offensive_ride') {
    return '/photo-assets/equipIcon/horse.png';
  }

  const rawName = card.name.replace(/^(sa__|ex__|ty__|mobile__|m_liuyi__)/, '');
  const alias = EQUIP_ICON_ALIASES[card.name] || EQUIP_ICON_ALIASES[rawName] || rawName || card.name;
  return `/photo-assets/equipIcon/${alias}.png`;
}

function EquipSlotVisual({ slot, card }: { slot: EquipmentSlotKey; card?: BoardEquipment }) {
  const [imgFailed, setImgFailed] = useState(false);
  const iconUrl = card ? getNativeEquipIconUrl(slot, card) : null;

  if (card && iconUrl && !imgFailed) {
    return <img className="native-eq-thumb" src={iconUrl} alt="" onError={() => setImgFailed(true)} />;
  }
  return <EquipIcon slot={slot} />;
}

function equipNameClass(name: string): string {
  const len = name.length;
  if (len <= 6) return 'eq-name-short';
  if (len <= 11) return 'eq-name-medium';
  if (len <= 16) return 'eq-name-long';
  return 'eq-name-xlarge';
}

function EquipRow({
  slot, typeLabel, card, text,
}: {
  slot: EquipmentSlotKey;
  typeLabel: string;
  card?: BoardEquipment;
  text: (value: string) => string;
}) {
  const info = card ? suitInfo(card) : null;
  const name = resolveEquipName(card, typeLabel, text);
  const suitText = info ? info.text : '';
  const detail = card ? `${name} · ${suitText}${card.range != null ? ` · Tầm ${card.range}` : ''}` : `${typeLabel} trống`;
  const nameClass = equipNameClass(card ? name : typeLabel);

  return <div className={`native-equip-row ${card ? 'equipped' : 'empty'}`} title={detail} aria-label={detail}>
    <span className="native-eq-icon" aria-hidden="true"><EquipSlotVisual slot={slot} card={card} /></span>
    <span className={`native-eq-name ${nameClass}`}>{card ? name : typeLabel}</span>
    {card && <span className={`native-eq-suit card-suit-ink ${info?.colorClass}`}>{suitText}</span>}
  </div>;
}

function EquipRidesSplit({
  defCard, offCard, text,
}: {
  defCard?: BoardEquipment;
  offCard?: BoardEquipment;
  text: (value: string) => string;
}) {
  const defInfo = defCard ? suitInfo(defCard) : null;
  const offInfo = offCard ? suitInfo(offCard) : null;
  const defName = resolveEquipName(defCard, '+1', text);
  const offName = resolveEquipName(offCard, '-1', text);
  const defDetail = defCard ? `${defName} · ${defInfo?.text}` : '+1 Mã trống';
  const offDetail = offCard ? `${offName} · ${offInfo?.text}` : '-1 Mã trống';
  const defNameClass = equipNameClass(defCard ? defName : '+1');
  const offNameClass = equipNameClass(offCard ? offName : '-1');

  return <div className="native-equip-rides-split">
    <div className={`native-equip-half ${defCard ? 'equipped' : 'empty'}`} title={defDetail} aria-label={defDetail}>
      <span className="native-eq-icon" aria-hidden="true"><EquipSlotVisual slot="defensive_ride" card={defCard} /></span>
      <span className={`native-eq-name ${defNameClass}`}>{defCard ? defName : '+1'}</span>
      {defCard && <span className={`native-eq-suit card-suit-ink ${defInfo?.colorClass}`}>{defInfo?.text}</span>}
    </div>
    <div className={`native-equip-half ${offCard ? 'equipped' : 'empty'}`} title={offDetail} aria-label={offDetail}>
      <span className="native-eq-icon" aria-hidden="true"><EquipSlotVisual slot="offensive_ride" card={offCard} /></span>
      <span className={`native-eq-name ${offNameClass}`}>{offCard ? offName : '-1'}</span>
      {offCard && <span className={`native-eq-suit card-suit-ink ${offInfo?.colorClass}`}>{offInfo?.text}</span>}
    </div>
  </div>;
}

function EquipmentPlate({
  slotCards, text, count, self, compact,
}: {
  slotCards: Map<EquipmentSlotKey, BoardEquipment>;
  text: (value: string) => string;
  count: number;
  self: boolean;
  compact: boolean;
}) {
  const label = self ? 'Trang bị của bạn' : 'Trang bị công khai';
  const equippedNames = [...slotCards.values()]
    .map((card) => text(card.name) || card.name)
    .filter(Boolean)
    .join(', ');
  // Keep the existing public-panel contract: an opponent's empty equipment
  // plate is not exposed as a labelled landmark, while the local compact seat
  // keeps its stable label so the five slots remain discoverable. The detailed
  // summary remains available through the description/title attributes.
  const equipmentSummary = count > 0 && equippedNames ? equippedNames : 'chưa có';
  const ariaLabel = count > 0 || self ? label : undefined;

  return <div className={`sg-equip-plate native-equip-plate${compact ? ' native-equip-plate-compact' : ''}`}
    aria-label={ariaLabel} aria-description={`${label}: ${equipmentSummary}`} title={`${label}: ${equipmentSummary}`}
    data-equipped-count={slotCards.size} data-equipment-summary={equipmentSummary}>
    <EquipRow slot="treasure" typeLabel="Bảo vật" card={slotCards.get('treasure')} text={text} />
    <EquipRow slot="weapon" typeLabel="Vũ khí" card={slotCards.get('weapon')} text={text} />
    <EquipRow slot="armor" typeLabel="Phòng cụ" card={slotCards.get('armor')} text={text} />
    <EquipRidesSplit defCard={slotCards.get('defensive_ride')} offCard={slotCards.get('offensive_ride')} text={text} />
  </div>;
}

function DelayedTricksOverlay({
  delayedTricks, text,
}: {
  delayedTricks?: BoardEquipment[];
  text: (value: string) => string;
}) {
  if (!delayedTricks || delayedTricks.length === 0) return null;
  return <div className="native-delayed-trick-group sg-delayed-trick-group" aria-label="Vùng phán xét">
    {delayedTricks.map((card, idx) => {
      const lower = card.name.toLowerCase();
      let badgeClass = 'trick-indulgence';
      let glyph = 'Lạc';
      if (lower.includes('supply') || lower.includes('bingliang') || lower.includes('binh')) {
        badgeClass = 'trick-supply';
        glyph = 'Binh';
      } else if (lower.includes('lightning') || lower.includes('shandian') || lower.includes('sấm')) {
        badgeClass = 'trick-lightning';
        glyph = 'Sấm';
      } else if (lower.includes('indulgence') || lower.includes('lebusishu') || lower.includes('lạc')) {
        badgeClass = 'trick-indulgence';
        glyph = 'Lạc';
      } else {
        glyph = text(card.name).charAt(0);
      }
      return <span key={idx} className={`native-trick-badge sg-trick-badge ${badgeClass}`}
        title={`${text(card.name)} · ${suitInfo(card).text}`}>
        {glyph}
      </span>;
    })}
  </div>;
}

function PortraitOverlays({ game, self }: { game: BoardPlayer | undefined; self: boolean }) {
  const dying = !game?.died && game?.hp != null && game.hp <= 0;
  const dead = game?.died === true;
  const drunk = game?.drank != null && game.drank > 0;
  return <>
    {drunk && <span className="sg-drunk-overlay native-drunk-overlay" aria-label="Đang say" />}
    {game?.chained && <img className="sg-chain-overlay native-chain-overlay" src="/photo-assets/chain.png" alt="Đang bị xích" />}
    {game?.faceup === false && <img className="sg-face-overlay native-face-overlay" src="/photo-assets/faceturned-heg.png" alt="Đang úp mặt" />}
    {dying && <div className="sg-death-overlay sg-save-overlay native-dying-overlay">
      <img src="/photo-assets/death/saveme.png" alt="Đang hấp hối, cần cứu" />
    </div>}
    {dead && <div className="sg-death-stamp native-death-stamp" aria-label={game?.surrendered ? 'Đã đầu hàng' : 'Đã tử trận'}>
      {game?.surrendered ? 'ĐẦU HÀNG' : 'TRẬN VONG'}
    </div>}
    {self && !dead && <span className="sg-self-glint" aria-hidden="true" />}
  </>;
}

export default function PlayerPhotoPanel({
  player, game, self, seat, active, target, busy, onTarget, compact = false, style, isShaking = false, avatarReaction, damagePop, equipmentPortalTarget, getGeneralSkills, focusState, skillCallout,
}: PlayerPhotoPanelProps) {
  const text = useDisplayText();
  const isMainRevealed = !!game?.general && game.general !== 'anjiang';
  const isDeputyRevealed = !!game?.deputyGeneral && game.deputyGeneral !== 'anjiang';
  const main = (isMainRevealed ? game.general : (self ? (game?.selfGeneral || (game?.general && game?.general !== 'anjiang' ? game?.general : null)) : null)) ?? null;
  const deputy = (isDeputyRevealed ? game.deputyGeneral : (self ? (game?.selfDeputyGeneral || (game?.deputyGeneral && game?.deputyGeneral !== 'anjiang' ? game?.deputyGeneral : null)) : null)) ?? null;
  // Keep both halves mounted. When exactly one general is revealed, the other
  // half shows its card back even if the local player knows its private name.
  const mainPortrait = isDeputyRevealed && !isMainRevealed ? null : main;
  const deputyPortrait = isMainRevealed && !isDeputyRevealed ? null : deputy;
  const mainExtension = isMainRevealed ? game.generalExtension : self ? (game?.selfGeneralExtension ?? game?.generalExtension) ?? null : null;
  const deputyExtension = isDeputyRevealed ? game.deputyGeneralExtension : self ? (game?.selfDeputyGeneralExtension ?? game?.deputyGeneralExtension) ?? null : null;
  const kingdom = game?.visibleKingdom || game?.kingdom;
  const exposedKingdom = (self || game?.roleShown) ? kingdom : null;
  const faction = factionClass(exposedKingdom);
  const marks = Object.entries(game?.marks ?? {}).filter(([, value]) => value !== 0 && value !== false && value !== '');
  const slotCards = new Map<EquipmentSlotKey, BoardEquipment>();
  for (const card of game?.equipment ?? []) {
    const slot = cardSlot(card);
    if (slot && !slotCards.has(slot)) slotCards.set(slot, card);
  }
  const playerName = player.name || (player.id < 0 ? 'Máy' : `Người chơi ${player.id}`);
  const phaseLabel = game?.phase == null ? null : ({
    '1': 'Bắt đầu lượt', '2': 'Chuẩn bị', '3': 'Phán định', '4': 'Rút bài',
    '5': 'Đánh bài', '6': 'Bỏ bài', '7': 'Kết thúc lượt', '8': 'Ngoài lượt', '9': 'Chuyển giai đoạn',
    RoundStart: 'Bắt đầu lượt', Start: 'Chuẩn bị', Judge: 'Phán định', Draw: 'Rút bài',
    Play: 'Đánh bài', Discard: 'Bỏ bài', Finish: 'Kết thúc lượt', NotActive: 'Ngoài lượt', PhaseNone: 'Chuyển giai đoạn',
  } as Record<string, string>)[String(game.phase)] ?? String(game.phase);
  const faceLabel = mainPortrait ? text(mainPortrait) : 'Chủ tướng ẩn';
  const deputyLabel = deputyPortrait ? text(deputyPortrait) : 'Phó tướng ẩn';
  const mainCompat = !main ? faceLabel : self && !game?.general ? `${text(main)} · Chưa lật` : null;
  const deputyCompat = !deputy ? deputyLabel : self && !game?.deputyGeneral ? `${text(deputy)} · Chưa lật` : null;

  const [focusNow, setFocusNow] = useState(() => Date.now());
  useEffect(() => {
    if (!focusState || !focusState.playerIds.includes(player.id)) return;
    const tick = () => {
      const now = Date.now();
      setFocusNow(now);
      if (now >= focusState.receivedAt + focusState.timeoutMs) window.clearInterval(interval);
    };
    const interval = window.setInterval(tick, 200);
    tick();
    return () => window.clearInterval(interval);
  }, [player.id, focusState]);
  const isThinking = isBoardFocusActive(focusState, player.id, focusNow) && !game?.died;
  const focusProgress = focusState && isThinking
    ? Math.max(0, Math.min(1, (focusState.receivedAt + focusState.timeoutMs - focusNow) / focusState.timeoutMs))
    : 0;

  const mainUnrevealed = self && !isMainRevealed && !!main;
  const deputyUnrevealed = self && !isDeputyRevealed && !!deputy;
  const bothUnrevealed = mainUnrevealed && deputyUnrevealed;
  const reactionClass = avatarReaction || (isShaking ? 'hit-shake' : '');
  // The private names are available only in our own board projection. Opponent
  // lookup must use the already-revealed public identity, never the card back.
  const inspectMain = isMainRevealed ? game?.general : self ? main : null;
  const inspectDeputy = isDeputyRevealed ? game?.deputyGeneral : self ? deputy : null;
  const getVisibleSkillGroups = (): SkillGroup[] => {
    if (!getGeneralSkills) return [];
    const groups: SkillGroup[] = [];
    const add = (role: string, general: string | null | undefined) => {
      if (!general || general === 'anjiang') return;
      try { groups.push({ role, general, skills: getGeneralSkills(general) }); }
      catch { groups.push({ role, general, skills: [] }); }
    };
    add('Chủ tướng', inspectMain);
    add('Phó tướng', inspectDeputy);
    return groups;
  };

  return <article className={`board-player sg-board-player sg-photo-panel native-photo-seat faction-${faction} ${self ? 'board-self' : ''} ${compact ? 'sg-photo-panel-compact' : ''} ${active ? 'board-active active-turn' : ''} ${isThinking ? 'is-thinking' : ''} ${game?.died ? 'board-dead' : ''} ${target?.selected ? 'targeted' : ''} ${reactionClass}`}
    data-faction={faction} data-seat={seat} data-player-id={player.id}
    style={style}
    aria-label={`${playerName}${self ? ' (bạn)' : ''}`}>

    {/* 1. TOP OVERLAY BAR: KINGDOM CREST, SEAT NUM, NAME, DELAYED TRICKS */}
    <div className="native-top-overlay sg-photo-top-overlay">
      <div className="native-top-left-identity sg-top-left-identity">
        <span className="native-kingdom-crest sg-kingdom-crest"
          title={`Thế lực: ${exposedKingdom && kingdom && kingdom !== 'unknown' ? text(kingdom) : 'Chưa công khai'}`}>
          {exposedKingdom && kingdom && kingdom !== 'unknown' ? text(kingdom).toUpperCase() : 'ẨN'}
        </span>
        <span className="board-seat native-seat-badge-circle sg-seat-badge-circle" title={`Ghế ${seat}`}>
          {seat}
        </span>
        <strong className="board-player-name native-seat-player-name" title={playerName}>
          {playerName}
        </strong>
      </div>
      <DelayedTricksOverlay delayedTricks={game?.delayedTricks} text={text} />
    </div>

    {/* 2. FULL-BLEED DUAL GENERAL PORTRAIT FRAME */}
    <div className={`sg-portrait-frame native-portrait-canvas has-deputy ${game?.faceup === false ? 'is-face-turned' : ''}`}
      aria-label={`${faceLabel}; ${deputyLabel}`}>
      <PortraitImage name={mainPortrait} extension={mainExtension} text={text} deputy={false} backLabel="Chủ tướng ẩn" kingdom={exposedKingdom ? kingdom : null} unrevealed={bothUnrevealed ? false : mainUnrevealed} />
      <PortraitImage name={deputyPortrait} extension={deputyExtension} text={text} deputy={true} backLabel="Phó tướng ẩn" kingdom={exposedKingdom ? kingdom : null} unrevealed={bothUnrevealed ? false : deputyUnrevealed} />
      <span className="sg-deputy-split-line native-deputy-split-line" aria-hidden="true" />
      {bothUnrevealed && <span className="sg-unrevealed-badge sg-unrevealed-badge-pair" aria-hidden="true">Chưa lật</span>}
      <PortraitOverlays game={game} self={self} />
      {avatarReaction === 'hit-shake' && (
        <NativeVfxAnim animName="damage" scale={1.1} intervalMs={45} className="sg-avatar-damage-overlay" />
      )}

      {/* Target button overlay (covers portrait frame per contract) */}
      {target && <button className={`gameplay-target sg-portrait-target-overlay native-target-btn ${target.selected ? 'selected' : ''}`}
        type="button" data-target-id={player.id}
        aria-label={target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}
        title={target.selected ? `Bỏ chọn ${playerName}` : `Chọn ${playerName} làm mục tiêu`}
        aria-pressed={target.selected} disabled={busy || !target.enabled} onClick={onTarget}>
        <TargetCrosshairIcon className="sg-target-crosshair-icon" />
        <span className="sg-visually-hidden">{target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}</span>
      </button>}
      {getGeneralSkills && (inspectMain || inspectDeputy) &&
        <GeneralInfoTrigger className="sg-portrait-info-trigger" label={`Xem kỹ năng tướng của ${playerName}`}
          getGroups={getVisibleSkillGroups} />}
    </div>

    {/* 3. VERTICAL MAGATAMA HP COLUMN */}
    <HealthColumn game={game} />

    {/* 4. HANDCARD COUNT BADGE */}
    <HandCardBadge count={game?.handcardNum} />

    {/* 5. AUTHENTIC 4-ROW / 5-SLOT EQUIPMENT PLATE */}
    {equipmentPortalTarget
      ? createPortal(<EquipmentPlate slotCards={slotCards} text={text} count={game?.equipment.length ?? 0} self={self} compact={compact} />, equipmentPortalTarget)
      : <EquipmentPlate slotCards={slotCards} text={text} count={game?.equipment.length ?? 0} self={self} compact={compact} />}

    {/* 6. MARKS AND DOM COMPATIBILITY HOOKS */}
    {marks.length > 0 && <div className="sg-photo-marks" aria-label="Dấu hiệu công khai">
      {marks.map(([name, value]) => <span className="board-mark" key={name} title={`${text(name)}: ${typeof value === 'string' ? text(value) : String(value)}`}>
        {text(name)}: {typeof value === 'string' ? text(value) : String(value)}
      </span>)}
    </div>}
    {game?.chained && <span className="board-mark sg-mark-chained sg-visually-hidden">Đang bị xích</span>}
    {game?.faceup === false && <span className="board-mark sg-mark-faceup sg-visually-hidden">Úp mặt</span>}
    <div className="sg-photo-faction-line sg-visually-hidden">
      <span>Thế lực: {exposedKingdom && kingdom ? text(kingdom) : 'Chưa công khai'}</span>
      {phaseLabel && <span className="sg-phase-compat">Giai đoạn: {phaseLabel}</span>}
    </div>
    <div className="sg-general-compat sg-visually-hidden" aria-label="Tướng đang hiển thị">
      {mainCompat && <span>{mainCompat}</span>}
      {deputyCompat && <span>{deputyCompat}</span>}
    </div>
    {active && <span className="turn-badge sg-visually-hidden">Đang lượt</span>}
    {game?.died && <span className="dead-badge sg-visually-hidden">Đã loại</span>}
    {!game?.died && game?.hp != null && game.hp <= 0 && <span className="dead-badge sg-visually-hidden">Hấp hối</span>}
    {self && <span className="you-tag sg-visually-hidden">Bạn</span>}

    {/* 7. REAL-TIME FOCUS, SKILL CALLOUT & DAMAGE OVERLAYS */}
    {isThinking && (
      <div className="sg-photo-thinking-bar" role="progressbar" aria-label="Đang suy nghĩ" aria-valuenow={Math.round(focusProgress * 100)}>
        <div
          className="sg-photo-thinking-progress"
          style={{ width: `${Math.round(focusProgress * 100)}%` }}
        />
        <span className="sg-photo-thinking-tip">
          {focusState?.command ? `${text(focusState.command)}...` : 'Đang suy nghĩ...'}
        </span>
      </div>
    )}
    {skillCallout && (
      <div className={`sg-photo-skill-callout${skillCallout.isUlt ? ' is-ult' : ''}`} aria-hidden="true">
        <span>【{text(skillCallout.skillName)}】</span>
      </div>
    )}
    {damagePop && (
      <span key={damagePop.id} className="sg-photo-damage-pop" aria-hidden="true">-{damagePop.amount}</span>
    )}

  </article>;
}
