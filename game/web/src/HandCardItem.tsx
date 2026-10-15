import { useId, useState, useEffect, useRef } from 'react';
import type { CSSProperties, ReactNode } from 'react';
import { useDisplayText } from './engine/displayText';
import { objectValue } from './engine/gameplayInteraction';
import type { GameplayItem } from './store/gameplayState';
import { CATALOG_CARD_ART_NAMES, catalogCardArtUrl } from './catalogCardArt';

export interface CardData {
  name?: string;
  trueName?: string;
  /** FreeKill package that owns the card definition (e.g. gamemode/mobile). */
  extension?: string;
  /** Optional FilterSkill-selected picture name, equivalent to native pic_name. */
  picName?: string;
  suit?: number;
  number?: number;
}

export interface CardSuitInfo {
  symbol: string;
  name: string;
  colorClass: 'suit-red' | 'suit-black' | 'suit-nosuit';
}

export interface CardCategoryInfo {
  typeKey: 'basic' | 'trick' | 'delayed' | 'equip' | 'unknown';
  label: string;
  className: string;
  badge?: string;
}

/** 1: Spade ♠, 2: Club ♣, 3: Heart ♥, 4: Diamond ♦, 5/other: NoSuit ◇ */
export function getSuitInfo(suit: number | undefined): CardSuitInfo {
  if (suit === 1) return { symbol: '♠', name: 'Bích', colorClass: 'suit-black' };
  if (suit === 2) return { symbol: '♣', name: 'Chuồn', colorClass: 'suit-black' };
  if (suit === 3) return { symbol: '♥', name: 'Cơ', colorClass: 'suit-red' };
  if (suit === 4) return { symbol: '♦', name: 'Rô', colorClass: 'suit-red' };
  return { symbol: '◇', name: 'Không chất', colorClass: 'suit-nosuit' };
}

export function formatRank(number: number | undefined): string {
  if (typeof number !== 'number' || !Number.isInteger(number) || number < 0 || number > 13) return '';
  if (number === 1) return 'A';
  if (number === 11) return 'J';
  if (number === 12) return 'Q';
  if (number === 13) return 'K';
  if (number === 0) return 'X';
  return String(number);
}

/** Static whitelist of standard card classifications */
const BASIC_CARDS = new Set([
  'slash', 'fire_slash', 'fire__slash', 'thunder_slash', 'thunder__slash',
  'jink', 'peach', 'analeptic',
]);

const DELAYED_TRICKS = new Set([
  'indulgence', 'supply_shortage', 'lightning',
]);

const NORMAL_TRICKS = new Set([
  'duel', 'dismantlement', 'snatch', 'ex_nihilo', 'nullification',
  'god_salvation', 'amazing_grace', 'savage_assault', 'archery_attack',
  'iron_chain', 'collateral', 'fire_attack',
]);

const WEAPONS = new Set([
  'qinggang_sword', 'double_swords', 'blade', 'spear', 'axe', 'halberd',
  'kylin_bow', 'crossbow', 'ice_sword', 'guding_blade', 'fan',
]);

const ARMORS = new Set([
  'eight_diagram', 'nioh_shield', 'silver_lion', 'vine',
]);

const DEFENSIVE_RIDES = new Set([
  'jueying', 'dilu', 'zhuahuangfeidian',
]);

const OFFENSIVE_RIDES = new Set([
  'chitu', 'dayuan', 'zixing',
]);

const TREASURES = new Set([
  'wooden_ox', 'role__wooden_ox', 'jade_seal',
]);

export function getCardCategory(rawName: string | undefined): CardCategoryInfo {
  if (!rawName) return { typeKey: 'unknown', label: '', className: 'type-unknown' };
  const name = rawName.replace(/^.*__/, ''); // strip package prefix
  if (BASIC_CARDS.has(name) || BASIC_CARDS.has(rawName)) {
    return { typeKey: 'basic', label: 'Cơ Bản', className: 'type-basic' };
  }
  if (DELAYED_TRICKS.has(name) || DELAYED_TRICKS.has(rawName)) {
    return { typeKey: 'delayed', label: 'Trì Hoãn', className: 'type-delayed', badge: 'Trì Hoãn' };
  }
  if (NORMAL_TRICKS.has(name) || NORMAL_TRICKS.has(rawName)) {
    return { typeKey: 'trick', label: 'Cẩm Nang', className: 'type-trick', badge: 'Cẩm Nang' };
  }
  if (WEAPONS.has(name) || WEAPONS.has(rawName)) {
    return { typeKey: 'equip', label: 'Vũ Khí', className: 'type-equip', badge: 'Vũ Khí' };
  }
  if (ARMORS.has(name) || ARMORS.has(rawName)) {
    return { typeKey: 'equip', label: 'Phòng Cụ', className: 'type-equip', badge: 'Phòng Cụ' };
  }
  if (DEFENSIVE_RIDES.has(name) || DEFENSIVE_RIDES.has(rawName)) {
    return { typeKey: 'equip', label: 'Tọa Kỵ', className: 'type-equip', badge: '+1 Mã' };
  }
  if (OFFENSIVE_RIDES.has(name) || OFFENSIVE_RIDES.has(rawName)) {
    return { typeKey: 'equip', label: 'Tọa Kỵ', className: 'type-equip', badge: '-1 Mã' };
  }
  if (TREASURES.has(name) || TREASURES.has(rawName)) {
    return { typeKey: 'equip', label: 'Bảo Vật', className: 'type-equip', badge: 'Bảo Vật' };
  }
  return { typeKey: 'unknown', label: '', className: 'type-unknown' };
}

/** Baseline standard card descriptions when Lua translation table is deferred */
const BASELINE_DESCRIPTIONS: Record<string, string> = {
  slash: 'Trong giai đoạn ra bài, sử dụng lên một mục tiêu trong phạm vi tấn công. Gây 1 sát thương nếu đối phương không đánh ra 【Thiểm】.',
  fire_slash: 'Gây 1 sát thương hỏa. Có thể kích hoạt sát thương liên hoàn nếu mục tiêu bị Thiết Tỏa Liên Hoàn.',
  thunder_slash: 'Gây 1 sát thương lôi. Bỏ qua Phòng Cụ mây tre (Đằng Giáp) và kích hoạt liên hoàn.',
  jink: 'Đánh ra trong giai đoạn phản hồi để hóa giải một lá 【Sát】 của đối phương.',
  peach: 'Hồi 1 điểm sinh lực trong giai đoạn ra bài, hoặc dùng để cứu một tướng đang hấp hối.',
  analeptic: 'Uống trong giai đoạn ra bài giúp đòn 【Sát】 tiếp theo gây thêm +1 sát thương, hoặc uống khi hấp hối để tự hồi 1 máu.',
  ex_nihilo: 'Sử dụng lên bản thân trong giai đoạn ra bài: Ngay lập tức rút 2 lá bài từ chồng bài rút.',
  snatch: 'Sử dụng lên một người chơi trong cự ly 1: Lấy 1 lá bài bất kỳ trên tay, vùng trang bị hoặc phán xét của mục tiêu.',
  dismantlement: 'Hủy 1 lá bài bất kỳ trên tay, vùng trang bị hoặc vùng phán xét của một người chơi khác.',
  duel: 'Chỉ định 1 người chơi khác quyết đấu: Lần lượt đánh ra 【Sát】. Ai không đánh ra được sẽ chịu 1 sát thương.',
  nullification: 'Vô hiệu hóa hoàn toàn tác dụng của một lá Cẩm Nang đang thi triển lên mục tiêu.',
  lightning: 'Đặt vào vùng phán xét: Đầu lượt phán xét, nếu lật trúng Bích 2..9 thì chịu 3 sát thương sấm sét.',
  indulgence: 'Đặt vào vùng phán xét đối phương: Đầu lượt, nếu phán xét không phải Cơ thì bị bỏ qua giai đoạn Ra Bài.',
  supply_shortage: 'Đặt vào vùng phán xét đối phương: Đầu lượt, nếu phán xét không phải Chuồn thì bị bỏ qua giai đoạn Rút Bài.',
  qinggang_sword: 'Vũ khí tầm 2: Khi bạn dùng 【Sát】, bỏ qua hoàn toàn mọi phòng cụ của mục tiêu.',
  eight_diagram: 'Phòng cụ: Mỗi khi cần đánh ra 【Thiểm】, bạn có thể phán xét. Nếu bài phán xét màu đỏ, tính như đã ra 【Thiểm】.',
};

/** Safe Vietnamese names used while the Lua display dictionary is still loading. */
const BASELINE_NAMES: Record<string, string> = {
  slash: 'Sát',
  fire_slash: 'Hỏa Sát',
  thunder_slash: 'Lôi Sát',
  jink: 'Thiểm',
  peach: 'Đào',
  analeptic: 'Rượu',
  ex_nihilo: 'Vô Trung Sinh Hữu',
  snatch: 'Thuận Thủ Khiên Dương',
  dismantlement: 'Quá Hà Đoạt Kiều',
  duel: 'Quyết Đấu',
  nullification: 'Vô Giải Khả Kích',
  lightning: 'Sấm Sét',
  indulgence: 'Lạc Bất Tư Thục',
  supply_shortage: 'Binh Lương Thốn Đoạn',
  qinggang_sword: 'Thanh Cương Kiếm',
  eight_diagram: 'Bát Quái Trận',
};

const UNKNOWN_CARD_NAME = 'Lá bài chưa xác định';
const UNKNOWN_CARD_DESCRIPTION = 'Chi tiết luật chưa được nạp.';

function cardKeys(card: CardData | undefined): string[] {
  return [...new Set([card?.name, card?.trueName].filter((value): value is string =>
    typeof value === 'string' && value.length > 0))];
}

function baseCardKey(value: string): string {
  return value.replace(/^.*__/, '');
}

/** A translation is usable only when it is not the unresolved wire key itself. */
function translatedValue(key: string, text: (value: string) => string): string | null {
  const value = text(key).trim();
  if (!value || value === key || value.startsWith(':')) return null;
  return value;
}

/** Fixtures and some upstream UI paths already provide a localized face name. */
function safeRawCardName(value: string): string | null {
  return /^[a-z0-9_-]+$/.test(value) ? null : value;
}

/** Resolver for card title and description conforming to user criteria */
export function resolveCardText(
  card: CardData | undefined,
  text: (key: string) => string
): { displayName: string; description: string } {
  const names = cardKeys(card);
  if (!names.length) return { displayName: UNKNOWN_CARD_NAME, description: UNKNOWN_CARD_DESCRIPTION };

  const translatedName = names.map((name) => translatedValue(name, text)).find(Boolean);
  const baselineName = names.map(baseCardKey).map((name) => BASELINE_NAMES[name]).find(Boolean);
  const providedName = names.map(safeRawCardName).find(Boolean);
  const displayName = translatedName || baselineName || providedName || UNKNOWN_CARD_NAME;

  // Prefer the current view-as name, then the true card name, then the static baseline.
  const translatedDesc = names
    .map((name) => translatedValue(`:${name}`, text))
    .find(Boolean);
  if (translatedDesc) return { displayName, description: translatedDesc };

  const baseline = names.map(baseCardKey).map((name) => BASELINE_DESCRIPTIONS[name]).find(Boolean);
  return {
    displayName,
    description: baseline || UNKNOWN_CARD_DESCRIPTION,
  };
}

/**
 * Exact FreeKill package/name -> asset paths.
 *
 * These entries intentionally use the card's real definition name.  A
 * generic name such as `slash` or `eight_diagram` is not allowed to borrow a
 * variant image from another package: the native client resolves the image by
 * package + name, and a missing asset must remain a fallback rather than
 * becoming a visually false card.
 */
export const NATIVE_CARD_ASSETS: Record<string, string> = {
  'mobile/ex_eight_diagram': '/packages/mobile/image/card/ex_eight_diagram.png',
  'mobile/ex_crossbow': '/packages/mobile/image/card/ex_crossbow.png',
  'mobile/ex_nioh_shield': '/packages/mobile/image/card/ex_nioh_shield.png',
  'mobile/ex_silver_lion': '/packages/mobile/image/card/ex_silver_lion.png',
  'mobile/ex_vine': '/packages/mobile/image/card/ex_vine.png',
  'mobile/xuanjian_sword': '/packages/mobile/image/card/xuanjian_sword.png',

  'gamemode/v33__ex_nihilo': '/packages/gamemode/image/card/v33__ex_nihilo.png',
  'gamemode/v11__dismantlement': '/packages/gamemode/image/card/v11__dismantlement.png',
  'gamemode/ice__slash': '/packages/gamemode/image/card/ice__slash.png',
  'gamemode/stab__slash': '/packages/gamemode/image/card/stab__slash.png',
  'gamemode/yitian_sword': '/packages/gamemode/image/card/yitian_sword.png',
  'gamemode/five_elements_fan': '/packages/gamemode/image/card/five_elements_fan.png',
  'gamemode/seven_stars_sword': '/packages/gamemode/image/card/seven_stars_sword.png',
  'gamemode/crafty_escape': '/packages/gamemode/image/card/crafty_escape.png',
  'gamemode/honey_trap': '/packages/gamemode/image/card/honey_trap.png',
  'gamemode/drowning': '/packages/gamemode/image/card/drowning.png',

  'tenyear/thunder_blade': '/packages/tenyear/image/card/thunder_blade.png',
  'tenyear/quenched_blade': '/packages/tenyear/image/card/quenched_blade.png',
  'tenyear/real__crossbow': '/packages/tenyear/image/card/real__crossbow.png',
  'tenyear/red_spear': '/packages/tenyear/image/card/red_spear.png',
  'tenyear/water_sword': '/packages/tenyear/image/card/water_sword.png',
  'tenyear/poisonous_dagger': '/packages/tenyear/image/card/poisonous_dagger.png',

  'standard_ex/role__wooden_ox': '/packages/standard_ex/image/card/role__wooden_ox.png',
  'overseas/moon_spear': '/packages/overseas/image/card/moon_spear.png',
  'overseas/celestial_calabash': '/packages/overseas/image/card/celestial_calabash.png',
  'overseas/talisman': '/packages/overseas/image/card/talisman.png',
  'sp/yanxiao_trick': '/packages/sp/image/card/delayedTrick/yanxiao_trick.png',
};

const NATIVE_CARD_ASSETS_BY_NAME = new Map<string, string>();
const AMBIGUOUS_NATIVE_CARD_NAMES = new Set<string>();
for (const [key, url] of Object.entries(NATIVE_CARD_ASSETS)) {
  const name = key.slice(key.indexOf('/') + 1);
  if (NATIVE_CARD_ASSETS_BY_NAME.has(name)) {
    AMBIGUOUS_NATIVE_CARD_NAMES.add(name);
    NATIVE_CARD_ASSETS_BY_NAME.delete(name);
  } else if (!AMBIGUOUS_NATIVE_CARD_NAMES.has(name)) {
    NATIVE_CARD_ASSETS_BY_NAME.set(name, url);
  }
}

function safeNativeAssetName(value: string | undefined): string | null {
  return value && /^[A-Za-z0-9_-]+$/.test(value) ? value : null;
}

export function getNativeCardArtUrl(cardOrName: CardData | string | undefined): string | null {
  const card: CardData = typeof cardOrName === 'string' ? { name: cardOrName } : (cardOrName ?? {});
  // The focused catalogue is authoritative for the active Quốc Chiến pool.
  // Match the actual definition name only; a picName is a rendering hint and
  // must not make a variant borrow the generic card face.
  const catalogName = safeNativeAssetName(card.name);
  if (catalogName && CATALOG_CARD_ART_NAMES.has(catalogName)) return catalogCardArtUrl(catalogName);
  const names = [card.picName, card.name].map(safeNativeAssetName).filter((name): name is string => !!name);
  for (const name of names) {
    if (card.extension) {
      const exact = NATIVE_CARD_ASSETS[`${card.extension}/${name}`];
      if (exact) return exact;
    }
    // This fallback is still exact by card definition name; it is only used
    // when that name occurs in one package in the shipped native manifest.
    const unique = NATIVE_CARD_ASSETS_BY_NAME.get(name);
    if (unique) return unique;
  }
  return null;
}

/** Native Card Art Renderer or Neutral Frame (Strict adherence to native assets) */
function CardArt({ card, alt = '', sheet = false }: {
  card?: CardData;
  alt?: string;
  sheet?: boolean;
}) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [card?.extension, card?.picName, card?.name]);
  const artUrl = getNativeCardArtUrl(card);
  if (artUrl && !failed) {
    return (
      <img
        className={sheet ? 'sg-sheet-native-art' : 'sg-card-native-art'}
        src={artUrl}
        alt={alt}
        aria-hidden={alt ? undefined : true}
        onError={() => setFailed(true)}
      />
    );
  }
  if (sheet) return <span className="sg-card-sigil-icon sigil-neutral" aria-hidden="true">✦</span>;
  return (
    <div className="sg-card-art-frame" aria-hidden="true">
      <span className="sg-card-sigil-icon sigil-neutral">✦</span>
    </div>
  );
}

export function CardSigil({ card }: { card?: CardData }): ReactNode {
  return <CardArt card={card} />;
}

/** Accessible Bottom Sheet Modal for Card Inspection */
export function CardDetailSheet({
  isOpen,
  onClose,
  displayName,
  category,
  suitInfo,
  rank,
  description,
  card,
}: {
  isOpen: boolean;
  onClose: () => void;
  displayName: string;
  category: CardCategoryInfo;
  suitInfo: CardSuitInfo;
  rank: string;
  description: string;
  card?: CardData;
}) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return;
    previousFocusRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onCloseRef.current();
        return;
      }
      if (e.key !== 'Tab') return;
      const focusable = Array.from(dialogRef.current?.querySelectorAll<HTMLElement>(
        'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      ) ?? []);
      if (!focusable.length) {
        e.preventDefault();
        dialogRef.current?.focus();
        return;
      }
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    const focusTimer = window.setTimeout(() => closeButtonRef.current?.focus(), 0);
    return () => {
      window.clearTimeout(focusTimer);
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = previousOverflow;
      previousFocusRef.current?.focus();
      previousFocusRef.current = null;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      className="sg-card-modal-backdrop"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
      role="presentation"
    >
      <div
        className="sg-card-detail-sheet"
        role="dialog"
        aria-modal="true"
        aria-labelledby="card-sheet-title"
        aria-describedby="card-sheet-description"
        tabIndex={-1}
        ref={dialogRef}
      >
        <div className="sg-sheet-header">
          <div className="sg-sheet-badge-group">
            <span className={`sg-sheet-suit ${suitInfo.colorClass}`}>
              {suitInfo.symbol} {rank}
            </span>
            {category.label && (
              <span className={`sg-sheet-category ${category.className}`}>
                {category.label}
              </span>
            )}
          </div>
          <button
            type="button"
            className="sg-sheet-close-button"
            onClick={onClose}
            ref={closeButtonRef}
            aria-label="Đóng bảng chi tiết lá bài"
          >
            ✕
          </button>
        </div>

        <div className="sg-sheet-body">
          <div className="sg-sheet-art-preview">
            <CardArt card={card} alt={displayName} sheet />
          </div>
          <h3 id="card-sheet-title" className="sg-sheet-title">
            {displayName}
          </h3>
          <p id="card-sheet-description" className="sg-sheet-desc">{description}</p>
        </div>

        <div className="sg-sheet-footer">
          <button
            type="button"
            className="button primary sg-sheet-confirm-button"
            onClick={onClose}
          >
            Đóng
          </button>
        </div>
      </div>
    </div>
  );
}

/** Action bar card summary for mobile / selected state */
export function SelectedCardSummary({
  item,
  onInspect,
}: {
  item: GameplayItem;
  onInspect: () => void;
}) {
  const text = useDisplayText();
  const rawCard = objectValue(item.card) as CardData | null;
  const card: CardData | undefined = rawCard ? rawCard : undefined;
  const suitInfo = getSuitInfo(card?.suit);
  const rank = formatRank(card?.number);
  const { displayName, description } = resolveCardText(card, text);

  return (
    <div className="sg-selected-card-summary" role="status">
      <div className="sg-summary-text">
        <strong>
          Đang chọn: 【{displayName}】
          {rank ? ` (${suitInfo.symbol} ${rank})` : ''}
        </strong>
        <p className="sg-summary-desc">{description}</p>
      </div>
      <button
        type="button"
        className="button secondary small-button sg-inspect-action-btn"
        onClick={onInspect}
        aria-label={`Xem chi tiết ${displayName}`}
      >
        ? Chi tiết
      </button>
    </div>
  );
}

/**
 * HandCardItem with 4-Layer Presentation:
 * Directly renders a `<button>` with `.gameplay-choice.sg-card-button`
 * preserving 100% of DOM, accessibility and event contracts.
 */
export function HandCardItem({
  item,
  busy,
  onClick,
  index = 0,
  totalCards = 1,
}: {
  item: GameplayItem;
  busy: boolean;
  onClick: () => void;
  index?: number;
  totalCards?: number;
}) {
  const text = useDisplayText();
  const rawCard = objectValue(item.card) as CardData | null;
  const card: CardData | undefined = rawCard ? rawCard : undefined;

  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);

  const suitInfo = getSuitInfo(card?.suit);
  const rank = formatRank(card?.number);
  const categoryFromName = getCardCategory(card?.name);
  const category = categoryFromName.typeKey === 'unknown'
    ? getCardCategory(card?.trueName)
    : categoryFromName;
  const { displayName, description } = resolveCardText(card, text);

  const disabled = busy || !item.enabled;
  const showTooltip = (hovered || focused) && !disabled;
  const reactId = useId().replace(/:/g, '');
  const tooltipId = `card-tip-${reactId}`;
  const metadataId = `card-meta-${reactId}`;
  const cardMetadata = [suitInfo.name, rank, category.label].filter(Boolean).join(' · ');
  const describedBy = [metadataId, showTooltip ? tooltipId : ''].filter(Boolean).join(' ');
  const overlapDesktop = index > 0 && totalCards > 4
    ? Math.min(38, 16 + (totalCards - 4) * 3.5)
    : 0;
  const overlapMobile = index > 0 && totalCards > 4
    ? Math.min(42, 14 + (totalCards - 4) * 4.5)
    : 0;
  const cardStyle = {
    zIndex: item.selected ? 200 : (hovered || focused) ? 100 : index + 1,
    '--card-overlap': `${overlapDesktop}px`,
    '--card-overlap-desktop': `${overlapDesktop}px`,
    '--card-overlap-mobile': `${overlapMobile}px`,
  } as CSSProperties;
  return (
    <button
      type="button"
      className={`gameplay-choice sg-card-button ${category.className} ${
        item.selected ? 'selected' : ''
      }`}
      style={cardStyle}
      data-card-id={typeof item.id === 'number' ? item.id : undefined}
      aria-pressed={item.selected}
      aria-label={displayName}
      aria-describedby={describedBy}
      disabled={disabled}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    >
      <span id={metadataId} className="sg-visually-hidden">
        {cardMetadata ? `${cardMetadata}. ` : ''}{description}
      </span>
      {/* Layer 1: Top-Left Suit & Rank */}
      <div className="sg-card-top-left" aria-hidden="true">
        <span className="sg-card-rank">{rank || ' '}</span>
        <span className={`sg-card-suit ${suitInfo.colorClass}`}>
          {suitInfo.symbol}
        </span>
      </div>

      {/* Layer 2: Top-Right Category Badge */}
      {category.badge && (
        <span className="sg-card-type-badge" aria-hidden="true">
          {category.badge}
        </span>
      )}

      {/* Layer 3: Central Illustration (Native Asset or Neutral Frame) */}
      <CardArt card={card} />

      {/* Layer 4: Card Name Banner */}
      <div className="sg-card-banner">
        <span className="sg-card-name">{displayName}</span>
      </div>

      {/* Desktop Tooltip for Hover / Keyboard Focus */}
      {showTooltip && (
        <span
          id={tooltipId}
          className="sg-card-popover-tooltip"
          role="tooltip"
          aria-hidden={!showTooltip}
        >
          <strong className="sg-tip-title">
            {displayName} {rank ? `(${suitInfo.symbol} ${rank})` : ''}
          </strong>
          {category.label && (
            <span className="sg-tip-category">[{category.label}]</span>
          )}
          <span className="sg-tip-desc">{description}</span>
        </span>
      )}
    </button>
  );
}

/** Authentic Center In-Play Card Resolution (Table Pile / Processing Area) */
export function ResolvingCardView({ card }: { card: { name: string; suit: number; number: number; extension?: string; picName?: string } }) {
  const text = useDisplayText();
  const suitInfo = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  const category = getCardCategory(card.name);
  const { displayName } = resolveCardText(card, text);

  return (
    <div className="native-resolving-card" aria-label={`Đang xử lý: ${displayName} · ${suitInfo.name} ${rank}`}>
      <div className="card-head">
        <span className={suitInfo.colorClass}>{suitInfo.symbol} {rank}</span>
        <span className="card-cat-badge">{category.label || 'Bài'}</span>
      </div>
      <div className="card-thumb">
        <CardArt card={card} alt={displayName} />
      </div>
      <div className="card-foot">【 {displayName.toUpperCase()} 】</div>
    </div>
  );
}

/** Idle Hand Card for Bottom Dashboard (renders cards outside active turns) */
export function IdleHandCard({
  card,
  index = 0,
  totalCards = 1,
}: {
  card: { name: string; suit: number; number: number; extension?: string; picName?: string };
  index?: number;
  totalCards?: number;
}) {
  const text = useDisplayText();
  const suitInfo = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  const categoryFromName = getCardCategory(card.name);
  const category = categoryFromName.typeKey === 'unknown' ? getCardCategory((card as any).trueName) : categoryFromName;
  const { displayName } = resolveCardText(card, text);

  const overlapDesktop = index > 0 && totalCards > 4 ? Math.min(38, 16 + (totalCards - 4) * 3.5) : 0;
  const overlapMobile = index > 0 && totalCards > 4 ? Math.min(42, 14 + (totalCards - 4) * 4.5) : 0;
  const cardStyle = {
    zIndex: index + 1,
    '--card-overlap': `${overlapDesktop}px`,
    '--card-overlap-desktop': `${overlapDesktop}px`,
    '--card-overlap-mobile': `${overlapMobile}px`,
    opacity: 0.88,
    cursor: 'default',
  } as CSSProperties;

  return (
    <div
      className={`gameplay-choice sg-card-button sg-card-idle ${category.className}`}
      style={cardStyle}
      aria-label={`${displayName} · ${suitInfo.name} ${rank}`}
    >
      <div className="sg-card-badge-cluster">
        <span className={`sg-card-suit ${suitInfo.colorClass}`} aria-hidden="true">
          {suitInfo.symbol}
        </span>
        <span className={`sg-card-rank ${suitInfo.colorClass}`} aria-hidden="true">
          {rank}
        </span>
        {category.label && (
          <span className="sg-card-category" aria-hidden="true">
            {category.label}
          </span>
        )}
      </div>
      <div className="sg-card-art-box">
        <CardArt card={card} alt={displayName} />
      </div>
      <div className="sg-card-banner">
        <span className="sg-card-name">{displayName}</span>
      </div>
    </div>
  );
}
