import { useEffect, useMemo, useState } from 'react';
import { formatRank, getSuitInfo } from './HandCardItem';
import { useDisplayText } from './engine/displayText';
import type { GameplayItem } from './store/gameplayState';
import type { BoardEquipment, BoardPlayer } from './store/boardState';
import { generalArtCandidates } from './generalArt';
import type { RoomPlayer } from './store/gameStore';

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
  style?: React.CSSProperties;
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
  const isRed = suit.symbol === '♥' || suit.symbol === '♦';
  return { text: `${suit.symbol}${rank}`, isRed };
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

function HealthColumn({ game }: { game: BoardPlayer | undefined }) {
  const hp = game?.hp;
  const maxHp = game?.maxHp;
  const slots = maxHp != null && Number.isFinite(maxHp) ? Math.max(1, Math.min(12, Math.ceil(maxHp))) : 0;
  const filled = slots > 0 && hp != null && Number.isFinite(hp) ? Math.max(0, Math.min(slots, Math.ceil(hp))) : 0;
  const ratio = maxHp && hp != null ? hp / maxHp : 0;
  const magatama = ratio > 0.66 ? '3-heg' : ratio > 0.33 ? '2-heg' : ratio > 0 ? '1-heg' : '0-heg';
  const label = `Sinh lực: ${hp ?? '?'} trên ${maxHp ?? '?'}`;

  return <div className="sg-hp-vertical-column native-hp-vertical-column" aria-label={label} title={label}>
    {game?.shield != null && game.shield > 0 && <div className="sg-shield-readout" title={`Khiên: ${game.shield}`}>
      <img src="/photo-assets/magatama/shield.png" alt="" aria-hidden="true" />
      <span>{game.shield}</span>
    </div>}
    {maxHp != null && maxHp <= 4 ? (
      <div className="sg-magatama-column" aria-hidden="true">
        {Array.from({ length: slots }, (_, index) => <img key={index}
          className={`native-heg-hp-disc-v ${index < filled ? 'sg-magatama-filled' : 'sg-magatama-empty'}`}
          src={`/photo-assets/magatama/${index < filled ? magatama : '0-heg'}.png`} alt="" />)}
      </div>
    ) : (
      <>
        <img className="native-heg-hp-disc-v sg-magatama-filled"
          src={`/photo-assets/magatama/${magatama}.png`} alt="" aria-hidden="true" />
        <div className={`sg-hp-vertical-fraction native-hp-vertical-fraction ${ratio <= 0.33 ? 'hp-danger' : ratio <= 0.66 ? 'hp-warning' : ''}`}>
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

function EquipRow({
  icon, typeLabel, card, text,
}: {
  icon: string;
  typeLabel: string;
  card?: BoardEquipment;
  text: (value: string) => string;
}) {
  const info = card ? suitInfo(card) : null;
  const name = card ? text(card.name) : typeLabel;
  const suitText = info ? info.text : '';
  const detail = card ? `${name} · ${suitText}${card.range != null ? ` · Tầm ${card.range}` : ''}` : `${typeLabel} trống`;

  return <div className={`native-equip-row ${card ? 'equipped' : 'empty'}`} title={detail} aria-label={detail}>
    <span className="native-eq-icon" aria-hidden="true">{icon}</span>
    <span className="native-eq-name">{card ? name : '—'}</span>
    {card && <span className={`native-eq-suit ${info?.isRed ? 'suit-red' : 'suit-black'}`}>{suitText}</span>}
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
  const defName = defCard ? text(defCard.name) : '+1';
  const offName = offCard ? text(offCard.name) : '-1';
  const defDetail = defCard ? `${defName} · ${defInfo?.text}` : '+1 Mã trống';
  const offDetail = offCard ? `${offName} · ${offInfo?.text}` : '-1 Mã trống';

  return <div className="native-equip-rides-split">
    <div className={`native-equip-half ${defCard ? 'equipped' : 'empty'}`} title={defDetail} aria-label={defDetail}>
      <span className="native-eq-icon" aria-hidden="true">🐎</span>
      <span className="native-eq-name">{defCard ? defName : '+1'}</span>
      {defCard && <span className={`native-eq-suit ${defInfo?.isRed ? 'suit-red' : 'suit-black'}`}>{defInfo?.text}</span>}
    </div>
    <div className={`native-equip-half ${offCard ? 'equipped' : 'empty'}`} title={offDetail} aria-label={offDetail}>
      <span className="native-eq-icon" aria-hidden="true">🏹</span>
      <span className="native-eq-name">{offCard ? offName : '-1'}</span>
      {offCard && <span className={`native-eq-suit ${offInfo?.isRed ? 'suit-red' : 'suit-black'}`}>{offInfo?.text}</span>}
    </div>
  </div>;
}

function EquipmentPlate({
  slotCards, text, count,
}: {
  slotCards: Map<EquipmentSlotKey, BoardEquipment>;
  text: (value: string) => string;
  count: number;
}) {
  return <div className="sg-equip-plate native-equip-plate" aria-label={count > 0 ? 'Trang bị công khai' : undefined}>
    <EquipRow icon="📿" typeLabel="Bảo vật" card={slotCards.get('treasure')} text={text} />
    <EquipRow icon="⚔️" typeLabel="Vũ khí" card={slotCards.get('weapon')} text={text} />
    <EquipRow icon="🛡️" typeLabel="Phòng cụ" card={slotCards.get('armor')} text={text} />
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
  player, game, self, seat, active, target, busy, onTarget, style,
}: PlayerPhotoPanelProps) {
  const text = useDisplayText();
  const isMainRevealed = !!game?.general && game.general !== 'anjiang';
  const isDeputyRevealed = !!game?.deputyGeneral && game.deputyGeneral !== 'anjiang';
  const main = (isMainRevealed ? game.general : (self ? (game?.selfGeneral || (game?.general && game?.general !== 'anjiang' ? game?.general : null)) : null)) ?? null;
  const deputy = (isDeputyRevealed ? game.deputyGeneral : (self ? (game?.selfDeputyGeneral || (game?.deputyGeneral && game?.deputyGeneral !== 'anjiang' ? game?.deputyGeneral : null)) : null)) ?? null;
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
  const faceLabel = main ? text(main) : 'Chủ tướng ẩn';
  const deputyLabel = deputy ? text(deputy) : 'Phó tướng ẩn';
  const mainCompat = !main ? faceLabel : self && !game?.general ? `${faceLabel} · Chưa lật` : null;
  const deputyCompat = !deputy ? deputyLabel : self && !game?.deputyGeneral ? `${deputyLabel} · Chưa lật` : null;

  const mainUnrevealed = self && !isMainRevealed && !!main;
  const deputyUnrevealed = self && !isDeputyRevealed && !!deputy;

  return <article className={`board-player sg-board-player sg-photo-panel native-photo-seat faction-${faction} ${self ? 'board-self' : ''} ${active ? 'board-active active-turn' : ''} ${game?.died ? 'board-dead' : ''} ${target?.selected ? 'targeted' : ''}`}
    data-faction={faction} data-seat={seat} data-player-id={player.id}
    style={style}
    aria-label={`${playerName}${self ? ' (bạn)' : ''}`}>

    {/* 1. TOP OVERLAY BAR: KINGDOM CREST, SEAT NUM, NAME, DELAYED TRICKS */}
    <div className="native-top-overlay sg-photo-top-overlay">
      <div className="native-top-left-identity sg-top-left-identity">
        <span className="native-kingdom-crest sg-kingdom-crest"
          title={`Thế lực: ${exposedKingdom && kingdom ? text(kingdom) : 'Chưa công khai'}`}>
          {exposedKingdom && kingdom ? text(kingdom).toUpperCase() : 'ẨN'}
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
    <div className={`sg-portrait-frame native-portrait-canvas ${deputy ? 'has-deputy' : 'single'} ${game?.faceup === false ? 'is-face-turned' : ''}`}
      aria-label={`${faceLabel}; ${deputyLabel}`}>
      <PortraitImage name={main} extension={mainExtension} text={text} deputy={false} backLabel="Chủ tướng ẩn" kingdom={exposedKingdom ? kingdom : null} unrevealed={mainUnrevealed} />
      <PortraitImage name={deputy} extension={deputyExtension} text={text} deputy={true} backLabel="Phó tướng ẩn" kingdom={exposedKingdom ? kingdom : null} unrevealed={deputyUnrevealed} />
      {deputy && <span className="sg-deputy-split-line native-deputy-split-line" aria-hidden="true" />}
      <PortraitOverlays game={game} self={self} />

      {/* Target button overlay (covers portrait frame per contract) */}
      {target && <button className={`gameplay-target sg-portrait-target-overlay native-target-btn ${target.selected ? 'selected' : ''}`}
        type="button" data-target-id={player.id}
        aria-label={target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}
        title={target.selected ? `Bỏ chọn ${playerName}` : `Chọn ${playerName} làm mục tiêu`}
        aria-pressed={target.selected} disabled={busy || !target.enabled} onClick={onTarget}>
        <span aria-hidden="true">✛</span>
        <span className="sg-visually-hidden">{target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}</span>
      </button>}
    </div>

    {/* 3. VERTICAL MAGATAMA HP COLUMN */}
    <HealthColumn game={game} />

    {/* 4. HANDCARD COUNT BADGE */}
    <HandCardBadge count={game?.handcardNum} />

    {/* 5. AUTHENTIC 4-ROW / 5-SLOT EQUIPMENT PLATE */}
    <EquipmentPlate slotCards={slotCards} text={text} count={game?.equipment.length ?? 0} />

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

  </article>;
}
