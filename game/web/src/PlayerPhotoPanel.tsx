import { useEffect, useMemo, useState } from 'react';
import { getNativeCardArtUrl, type CardData, formatRank, getSuitInfo } from './HandCardItem';
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
}

type EquipmentSlotKey = 'treasure' | 'weapon' | 'armor' | 'defensive_ride' | 'offensive_ride';

const EQUIPMENT_SLOTS: { key: EquipmentSlotKey; label: string; shortLabel: string }[] = [
  { key: 'treasure', label: 'Bảo vật', shortLabel: 'Bảo' },
  { key: 'weapon', label: 'Vũ khí', shortLabel: 'Vũ' },
  { key: 'armor', label: 'Phòng cụ', shortLabel: 'Giáp' },
  { key: 'defensive_ride', label: '+1 Mã', shortLabel: '+1' },
  { key: 'offensive_ride', label: '-1 Mã', shortLabel: '-1' },
];

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

function suitAndRank(card: BoardEquipment): string {
  const suit = getSuitInfo(card.suit).symbol;
  const rank = formatRank(card.number);
  return `${suit}${rank}`;
}

function PortraitImage({
  name, extension, text, deputy, backLabel,
}: {
  name: string | null;
  extension: string | null;
  text: (value: string) => string;
  deputy: boolean;
  backLabel: string;
}) {
  const candidates = useMemo(() => generalArtCandidates({ name, extension }), [name, extension]);
  const [candidateIndex, setCandidateIndex] = useState(0);
  useEffect(() => setCandidateIndex(0), [name, extension]);
  const displayName = name ? text(name) : backLabel;

  return <div className={`sg-portrait-slot ${deputy ? 'sg-portrait-deputy' : 'sg-portrait-main'} ${name ? '' : 'sg-portrait-hidden'}`}
    aria-label={displayName}>
    <div className="sg-portrait-art">
      {name && candidateIndex < candidates.length
        ? <img src={candidates[candidateIndex]} alt={displayName}
          onError={() => setCandidateIndex((index) => index + 1)} />
        : <span className="sg-portrait-back-sigil" aria-hidden="true">卍</span>}
      {name && <span className="sg-portrait-name" title={displayName}>{displayName}</span>}
    </div>
  </div>;
}

function HealthColumn({ game }: { game: BoardPlayer | undefined }) {
  const hp = game?.hp;
  const maxHp = game?.maxHp;
  const slots = maxHp != null && Number.isFinite(maxHp) ? Math.max(1, Math.min(12, Math.ceil(maxHp))) : 0;
  const filled = slots > 0 && hp != null && Number.isFinite(hp) ? Math.max(0, Math.min(slots, Math.ceil(hp))) : 0;
  const ratio = maxHp && hp != null ? hp / maxHp : 0;
  const magatama = ratio > 0.66 ? '3' : ratio > 0.33 ? '2' : ratio > 0 ? '1' : '0';
  const label = `Sinh lực: ${hp ?? '?'} trên ${maxHp ?? '?'}`;
  return <div className="sg-photo-health" aria-label={label} title={label}>
    {game?.shield != null && game.shield > 0 && <div className="sg-shield-readout">
      <img src="/photo-assets/magatama/shield.png" alt="" aria-hidden="true" />
      <span>{game.shield}</span>
    </div>}
    <div className="sg-magatama-column" aria-hidden="true">
      {Array.from({ length: slots }, (_, index) => <img key={index}
        className={index < filled ? 'sg-magatama-filled' : 'sg-magatama-empty'}
        src={`/photo-assets/magatama/${index < filled ? magatama : '0'}.png`} alt="" />)}
    </div>
    <div className="sg-hp-text"><strong>{hp ?? '?'}</strong><span>/{maxHp ?? '?'}</span></div>
    <span className="sg-health-compat">♥ {hp ?? '?'} / {maxHp ?? '?'}</span>
    <div className="sg-hand-count-badge" title={`${game?.handcardNum ?? '?'} lá trên tay`}>
      <img src="/photo-assets/handcard.png" alt="" aria-hidden="true" />
      <span>{game?.handcardNum ?? '?'}</span>
    </div>
    <span className="sg-hand-count-compat">{game?.handcardNum ?? '?'} lá trên tay</span>
  </div>;
}

function EquipmentArt({ card, label }: { card: BoardEquipment; label: string }) {
  const [failed, setFailed] = useState(false);
  const data: CardData = {
    name: card.name, extension: card.extension, picName: card.picName,
    suit: card.suit, number: card.number,
  };
  const art = getNativeCardArtUrl(data);
  return art && !failed
    ? <img className="sg-equipment-art" src={art} alt={label} onError={() => setFailed(true)} />
    : <span className="sg-equipment-sigil" aria-hidden="true">✦</span>;
}

function EquipmentSlot({ slot, card, text }: {
  slot: { key: EquipmentSlotKey; label: string; shortLabel: string };
  card?: BoardEquipment;
  text: (value: string) => string;
}) {
  const name = card ? text(card.name) : slot.label;
  const detail = card ? `${name} · ${suitAndRank(card)}${card.range != null ? ` · Tầm ${card.range}` : ''}` : `${slot.label} trống`;
  return <div className={`sg-equipment-slot sg-equipment-${slot.key} ${card ? 'has-card' : 'is-empty'}`}
    aria-label={detail} title={detail}>
    <span className="sg-equipment-type">{slot.shortLabel}</span>
    {card ? <EquipmentArt card={card} label={name} /> : <span className="sg-equipment-empty-icon" aria-hidden="true">·</span>}
    <span className="sg-equipment-name">{card ? name : '—'}</span>
    {card && <span className="sg-equipment-meta">{suitAndRank(card)}{card.range != null ? ` · ${card.range}` : ''}</span>}
  </div>;
}

function PortraitOverlays({ game, self }: { game: BoardPlayer | undefined; self: boolean }) {
  const dying = !game?.died && game?.hp != null && game.hp <= 0;
  const dead = game?.died === true;
  const drunk = game?.drank != null && game.drank > 0;
  return <>
    {drunk && <span className="sg-drunk-overlay" aria-label="Đang say" />}
    {game?.chained && <img className="sg-chain-overlay" src="/photo-assets/chain.png" alt="Đang bị xích" />}
    {game?.faceup === false && <img className="sg-face-overlay" src="/photo-assets/faceturned-heg.png" alt="Đang úp mặt" />}
    {dying && <img className="sg-death-overlay sg-save-overlay" src="/photo-assets/death/saveme.png" alt="Đang hấp hối, cần cứu" />}
    {dead && <div className="sg-death-stamp" aria-label={game?.surrendered ? 'Đã đầu hàng' : 'Đã tử trận'}>
      {game?.surrendered ? 'ĐẦU HÀNG' : 'TRẬN VONG'}
    </div>}
    {self && !dead && <span className="sg-self-glint" aria-hidden="true" />}
  </>;
}

export default function PlayerPhotoPanel({
  player, game, self, seat, active, target, busy, onTarget,
}: PlayerPhotoPanelProps) {
  const text = useDisplayText();
  const main = (game?.general || (self ? game?.selfGeneral : null)) ?? null;
  const deputy = (game?.deputyGeneral || (self ? game?.selfDeputyGeneral : null)) ?? null;
  const mainExtension = game?.general ? game.generalExtension : self ? game?.selfGeneralExtension ?? null : null;
  const deputyExtension = game?.deputyGeneral ? game.deputyGeneralExtension : self ? game?.selfDeputyGeneralExtension ?? null : null;
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

  return <article className={`board-player sg-board-player sg-photo-panel faction-${faction} ${self ? 'board-self' : ''} ${active ? 'board-active' : ''} ${game?.died ? 'board-dead' : ''}`}
    data-faction={faction} data-seat={seat} data-player-id={player.id}
    aria-label={`${playerName}${self ? ' (bạn)' : ''}`}>
    <header className="sg-photo-header">
      <div className="sg-photo-identity">
        <span className="board-seat">Ghế {seat}</span>
        {self && <span className="you-tag">Bạn</span>}
        <strong className="board-player-name">{playerName}</strong>
      </div>
      <div className="sg-photo-header-status" aria-label="Trạng thái ghế">
        {active && <span className="turn-badge">Đang lượt</span>}
        {game?.died && <span className="dead-badge">Đã loại</span>}
        {!game?.died && game?.hp != null && game.hp <= 0 && <span className="dead-badge">Hấp hối</span>}
      </div>
    </header>

    <div className="sg-photo-faction-line">
      <span>Thế lực: {exposedKingdom && kingdom ? text(kingdom) : 'Chưa công khai'}</span>
      {phaseLabel && <span>Giai đoạn: {phaseLabel}</span>}
    </div>

    <div className="sg-general-compat" aria-label="Tướng đang hiển thị">
      {mainCompat && <span>{mainCompat}</span>}
      {deputyCompat && <span>{deputyCompat}</span>}
    </div>

    <div className="sg-photo-core">
      <div className={`sg-portrait-frame ${deputy ? 'has-deputy' : 'single'} ${game?.faceup === false ? 'is-face-turned' : ''}`}
        aria-label={`${faceLabel}; ${deputyLabel}`}>
        <PortraitImage name={main} extension={mainExtension} text={text} deputy={false} backLabel="Chủ tướng ẩn" />
        <PortraitImage name={deputy} extension={deputyExtension} text={text} deputy={true} backLabel="Phó tướng ẩn" />
        {deputy && <span className="sg-deputy-split-line" aria-hidden="true" />}
        <PortraitOverlays game={game} self={self} />
      </div>
      <HealthColumn game={game} />
    </div>

    <div className="sg-equipment-grid" aria-label={game?.equipment.length ? 'Trang bị công khai' : undefined}>
      {EQUIPMENT_SLOTS.map((slot) => <EquipmentSlot key={slot.key} slot={slot} card={slotCards.get(slot.key)} text={text} />)}
    </div>

    <div className="sg-photo-footer">
      {game?.delayedTricks.length ? <div className="sg-delayed-tricks" aria-label="Vùng phán xét">
        <span className="sg-zone-label">Phán định</span>
        {game.delayedTricks.map((card, index) => <span className="sg-delayed-card" key={`${card.name}-${index}`} title={text(card.name)}>
          <span>{text(card.name)}</span><small>{suitAndRank(card)}</small>
        </span>)}
      </div> : <span className="sg-zone-empty">Không có bài phán định</span>}
      {marks.length > 0 && <div className="sg-photo-marks" aria-label="Dấu hiệu công khai">
        {marks.map(([name, value]) => <span className="board-mark" key={name}>{text(name)}: {typeof value === 'string' ? text(value) : String(value)}</span>)}
      </div>}
      {(game?.chained || game?.faceup === false) && <div className="sg-state-summary">
        {game.chained && <span className="board-mark">Đang bị xích</span>}
        {game.faceup === false && <span className="board-mark">Úp mặt</span>}
      </div>}
    </div>

    {target && <button className={`gameplay-target ${target.selected ? 'selected' : ''}`} type="button"
      aria-pressed={target.selected} disabled={busy || !target.enabled} onClick={onTarget}>
      {target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}
    </button>}
  </article>;
}
