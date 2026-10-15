import { useMemo, useState, type FormEvent } from 'react';
import { GameAdapter, type RoomGeneral, type RoomPack } from './engine/gameAdapter';
import { useDisplayText } from './engine/displayText';
import { useGameStore, type LobbyRoom } from './store/gameStore';

const ROOM_MODE_LABELS: Record<string, string> = {
  new_heg_mode: 'Quốc Chiến',
  standard: 'Tiêu chuẩn',
  standard_mode: 'Tiêu chuẩn',
};

const AVATAR_LIST = [
  '/photo-assets/generals/godzhaoyun.webp',
  '/photo-assets/generals/godzhouyu.webp',
  '/photo-assets/generals/godlvbu.webp',
  '/photo-assets/generals/godzhugeliang.webp',
];

export const PACK_NAME_LOCALIZATION: Record<string, string> = {
  hegemony_standard: 'Quốc Chiến Tiêu Chuẩn',
  hegemony_nos: 'Quốc Chiến Cổ Điển',
  formation: 'Trận Pháp',
  momentum: 'Biến Cục',
  transformation: 'Biến Hóa',
  power: 'Quyền Lực',
  lord_ex: 'Quân Chủ Mở Rộng',
  zqdl: 'Tử Khí Đông Lai (Tấn)',
  jyzs: 'Kim Ấn Tử Thụ (Tấn)',
  zfxp: 'Tử Phượng Hàm Bội (Tấn)',
  online_heg: 'Bản Quyền OL',
  mobile_heg: 'Bản Quyền Mobile',
  tenyear_heg: 'Quốc Chiến Thập Niên',
  overseas_heg: 'Quốc Chiến Quốc Tế',
  offline_heg: 'Quốc Chiến Ngoại Tuyến',
  hegemony_cards: 'Bài Tiêu Chuẩn',
  strategic_advantage: 'Ưu Thế Chiến Lược',
  nine_variations: 'Quốc Chiến Cửu Biến',
  lord_cards: 'Quân Lâm Thiên Hạ',
  m_lord_cards: 'Quân Lâm Thiên Hạ Mobile',
  '国战-紫气东来': 'Tử Khí Đông Lai (Tấn)',
  '国战-金印紫授': 'Kim Ấn Tử Thụ (Tấn)',
  '国战-紫凤衔佩': 'Tử Phượng Hàm Bội (Tấn)',
  '国战-OL专属': 'Bản Quyền OL',
  '国战-手杀专属': 'Bản Quyền Mobile',
  '国战-十周年专属': 'Quốc Chiến Thập Niên',
  '国战-国际服专属': 'Quốc Chiến Quốc Tế',
  '国战-线下': 'Quốc Chiến Ngoại Tuyến',
  '国战·九变篇': 'Quốc Chiến Cửu Biến',
  '君临天下卡牌': 'Quân Lâm Thiên Hạ',
  'Hegemony Standard': 'Quốc Chiến Tiêu Chuẩn',
  'Strategic Advantage': 'Ưu Thế Chiến Lược',
  'Tenyear Heg.': 'Quốc Chiến Thập Niên',
  'Overseas Heg.': 'Quốc Chiến Quốc Tế',
  'Lord EX': 'Quân Chủ Mở Rộng',
  'Power': 'Quyền Lực',
  'Transformation': 'Biến Hóa',
  'Momentum': 'Biến Cục',
};

export function getPackLabel(pack: RoomPack, text: (key: string) => string): string {
  if (PACK_NAME_LOCALIZATION[pack.id]) return PACK_NAME_LOCALIZATION[pack.id];
  if (PACK_NAME_LOCALIZATION[pack.label]) return PACK_NAME_LOCALIZATION[pack.label];
  const translated = text(pack.id);
  if (translated && translated !== pack.id && !PACK_NAME_LOCALIZATION[translated]) {
    if (!/[\u4e00-\u9fa5]/.test(translated)) return translated;
  }
  return PACK_NAME_LOCALIZATION[pack.label] ?? pack.label;
}

export function formatRoomMode(mode: string): string {
  return ROOM_MODE_LABELS[mode] ?? (mode ? 'Chế độ chiến trường' : 'Quốc Chiến');
}

function roomAvailability(room: LobbyRoom): { label: string; tone: 'open' | 'full' | 'outdated' } {
  if (room.outdated) return { label: 'Không tương thích', tone: 'outdated' };
  if (room.players >= room.capacity) return { label: 'Đã đầy', tone: 'full' };
  return { label: `Còn ${room.capacity - room.players} chỗ`, tone: 'open' };
}

function LobbyRoomRow({ room, join, busy }: { room: LobbyRoom; join: (id: number, pw: string) => void; busy: boolean }) {
  const [password, setPassword] = useState('');
  const unavailable = room.outdated || room.players >= room.capacity;
  const availability = roomAvailability(room);
  const modeLabel = formatRoomMode(room.mode);
  const joinLabel = room.outdated ? 'Không tương thích' : room.players >= room.capacity ? 'Đã đầy' : 'Vào phòng';
  return (
    <li className={`room-item sg-room-card sg-room-card-${availability.tone}`}>
      <div className="sg-room-meta-left">
        <div className="sg-room-title-line">
          <h3 className="sg-room-name-text">{room.name}</h3>
          <span className="sg-room-badge-mode">{modeLabel}</span>
        </div>
        <div className="sg-room-subline">
          <span className={`sg-room-spot-tag ${availability.tone === 'open' ? 'sg-spot-open' : 'sg-spot-full'}`}>
            ● {availability.label}
          </span>
          <span className="sg-room-subline-sep">·</span>
          <span>Phòng #{room.id}</span>
          {room.outdated && (
            <>
              <span className="sg-room-subline-sep">·</span>
              <span className="sg-room-outdated-tag">Không tương thích</span>
            </>
          )}
          {room.hasPassword && (
            <>
              <span className="sg-room-subline-sep">·</span>
              <span className="sg-room-pwd-tag">Có khóa</span>
            </>
          )}
        </div>
      </div>
      <div className="sg-room-meta-right">
        <span className="sg-room-count-badge" aria-label={`${room.players} trên ${room.capacity} người`}>
          {room.players}/{room.capacity}
        </span>
        <div className="sg-room-join-cluster">
          {room.hasPassword && (
            <input
              aria-label={`Mật khẩu phòng ${room.name}`}
              type="password"
              className="sg-room-password-input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Mật khẩu"
            />
          )}
          <button
            className="sg-room-join-btn button secondary"
            type="button"
            disabled={busy || unavailable || (room.hasPassword && !password)}
            onClick={() => join(room.id, password)}
          >
            {joinLabel}
          </button>
        </div>
      </div>
    </li>
  );
}

export interface QaGeneralScenario {
  generalId: string;
  packId: string;
  sameKingdom: boolean;
  capacity: number;
  modeSettings: Record<string, boolean>;
}

export interface QaGeneralPlan {
  disabledGenerals: string[];
  kept: RoomGeneral[];
  error?: string;
}

export function readQaGeneralScenario(): QaGeneralScenario | null {
  const params = new URLSearchParams(window.location.search);
  const generalId = params.get('tqs-qa-general') ?? '';
  const packId = params.get('tqs-qa-pack') ?? '';
  if (!/^[A-Za-z0-9_:-]{1,160}$/.test(generalId) || !/^[A-Za-z0-9_:-]{1,160}$/.test(packId)) return null;
  const mode = params.get('tqs-qa-mode') ?? '';
  const sameKingdom = params.get('tqs-qa-kingdom') === 'same';
  const capacityValue = Number(params.get('tqs-qa-capacity') ?? '2');
  const capacity = capacityValue === 2 || capacityValue === 4 ? capacityValue : 0;
  if (!capacity) return null;
  if (mode && mode !== 'battle-royal-new' && mode !== 'battle-royal-old') return null;
  return { generalId, packId, sameKingdom,
    capacity,
    modeSettings: mode === 'battle-royal-new'
      ? { enterBattleRoyalOnFirstShuffle: true, old_battle_royal: false }
      : mode === 'battle-royal-old'
      ? { enterBattleRoyalOnFirstShuffle: true, old_battle_royal: true }
      : sameKingdom ? { revealAllOnStart: true } : {} };
}

export function buildQaGeneralPlan(adapter: GameAdapter, scenario: QaGeneralScenario): QaGeneralPlan {
  const candidates = adapter.getRoomGenerals([]);
  const target = candidates.find((general) => general.id === scenario.generalId && general.package === scenario.packId);
  if (!target) return { disabledGenerals: [], kept: [], error: 'Caller QA không có trong package native đã cài.' };

  const requiredGenerals = scenario.capacity * 5;
  const kept: RoomGeneral[] = [target];
  const trueNames = new Set([target.trueName]);
  const targetKingdoms = new Set([target.kingdom, target.subkingdom].filter((value): value is string => !!value));
  const sharesTargetKingdom = (general: RoomGeneral) => targetKingdoms.has(general.kingdom ?? '') ||
    targetKingdoms.has(general.subkingdom ?? '');
  let kingdomCandidates = candidates;
  if (scenario.sameKingdom) {
    let fallbackKingdom = '';
    if (target.kingdom === 'wild') {
      const counts = new Map<string, number>();
      for (const general of candidates) {
        if (general.id === target.id || !general.kingdom || general.kingdom === 'wild') continue;
        counts.set(general.kingdom, (counts.get(general.kingdom) ?? 0) + 1);
      }
      fallbackKingdom = [...counts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? '';
    }
    kingdomCandidates = candidates.filter((general) => general.id === target.id ||
      (fallbackKingdom ? general.kingdom === fallbackKingdom : sharesTargetKingdom(general)));
  }
  const ordered = kingdomCandidates.filter((general) => general.id !== target.id).sort((a, b) => {
    const aSame = targetKingdoms.has(a.kingdom ?? '') || targetKingdoms.has(a.subkingdom ?? '');
    const bSame = targetKingdoms.has(b.kingdom ?? '') || targetKingdoms.has(b.subkingdom ?? '');
    return Number(bSame) - Number(aSame);
  });
  for (const general of ordered) {
    if (kept.length >= requiredGenerals) break;
    if (!trueNames.has(general.trueName)) {
      trueNames.add(general.trueName);
      kept.push(general);
    }
  }
  if (kept.length < requiredGenerals) return { disabledGenerals: [], kept, error: scenario.sameKingdom
    ? `Caller QA không tạo được bể ${requiredGenerals} tướng cùng thế lực khác tên.`
    : `Caller QA không tạo được bể ${requiredGenerals} tướng khác tên.` };
  const keptIds = new Set(kept.map((general) => general.id));
  return { disabledGenerals: candidates.filter((general) => !keptIds.has(general.id)).map((general) => general.id), kept };
}

export function LobbyScreen({ adapter, run, busy }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}) {
  const rooms = useGameStore((s) => s.rooms);
  const [roomName, setRoomName] = useState('Quốc Chiến Mobile');
  const [capacity, setCapacity] = useState(4);
  const [timeout, setTimeoutSeconds] = useState(30);
  const [disabledPacks, setDisabledPacks] = useState<string[]>([]);
  const qaScenario = useMemo(readQaGeneralScenario, []);
  const text = useDisplayText();
  const packs = useMemo(() => {
    try { return adapter.getRoomPacks(); } catch { return null; }
  }, [adapter]);
  const qaPlan = useMemo<QaGeneralPlan | null>(() => {
    if (!qaScenario) return null;
    try { return buildQaGeneralPlan(adapter, qaScenario); }
    catch { return { disabledGenerals: [], kept: [], error: 'Không đọc được bể caller QA từ Lua.' }; }
  }, [adapter, qaScenario]);
  const disabledGenerals = qaPlan?.disabledGenerals ?? [];
  const pool = useMemo(() => {
    if (!packs) return null;
    try { return adapter.getRoomPoolSummary(disabledPacks, disabledGenerals); } catch { return null; }
  }, [adapter, packs, disabledPacks, disabledGenerals]);
  const validPool = !qaPlan?.error && !!pool && pool.generals >= capacity * 5 && pool.cards >= capacity * 4;
  const togglePack = (name: string) => setDisabledPacks((previous) => previous.includes(name)
    ? previous.filter((id) => id !== name) : [...previous, name]);

  const savedUsername = typeof window !== 'undefined' ? localStorage.getItem('tqs_saved_username') : null;
  const username = savedUsername?.trim() || 'Chúa Công';

  const packGroup = (title: string, items: RoomPack[], type: string) => (
    <fieldset className="pool-group" aria-label={title}>
      <legend>{title} ({items.length})</legend>
      <div className="pool-options">
        {items.map((pack) => {
          const isChecked = !disabledPacks.includes(pack.id);
          const packLabel = getPackLabel(pack, text);
          return (
            <label key={pack.id} className={`pool-option sg-pool-chip ${isChecked ? 'active' : 'disabled'}`}>
              <input
                type="checkbox"
                data-pack-id={pack.id}
                data-pack-type={type}
                checked={isChecked}
                disabled={busy}
                onChange={() => togglePack(pack.id)}
              />
              <div className="sg-pool-option-content">
                <span className="sg-pool-pack-name">{packLabel}</span>
                <span className="sg-pool-pack-count">{pack.count} {type === 'generals' ? 'tướng' : 'lá'}</span>
              </div>
            </label>
          );
        })}
      </div>
    </fieldset>
  );

  const create = (event: FormEvent) => {
    event.preventDefault();
    run(() => adapter.createRoom(roomName, capacity, timeout, disabledPacks, disabledGenerals, qaScenario?.modeSettings));
  };

  return (
    <div className="sg-lobby-screen sg-game-canvas">
      {/* Top Lord Header Bar */}
      <header className="sg-lord-header">
        <div className="sg-lord-info">
          <div className="sg-lord-avatar-frame">
            <img src="/photo-assets/generals/godzhaoyun.webp" alt="Avatar" className="sg-lord-avatar-img" />
          </div>
          <div className="sg-lord-meta">
            <div className="sg-lord-name-row">
              <span className="sg-lord-name">{username}</span>
              <span className="sg-lord-seal-badge">THẦN</span>
            </div>
            <span className="sg-lord-rank-text">Đại Đô Đốc · Quân Giai Cấp 1</span>
          </div>
        </div>
        <div className="sg-top-controls">
          <span className="sg-top-tag-badge">Quốc Chiến</span>
        </div>
      </header>

      {/* Screen Heading Banner */}
      <div className="sg-screen-heading-banner">
        <h1 className="sg-screen-title">SẢNH QUỐC CHIẾN</h1>
        <p className="sg-screen-subtitle">Bố trí phòng đấu và điểm tướng xuất chinh</p>
      </div>

      {/* Main Content Area */}
      <div className="sg-main-content-scroll">
        <div className="sg-lobby-grid">
          {/* Panel 1: Tạo phòng mới */}
          <section className="sg-classical-panel sg-create-panel" aria-labelledby="create-title">
            <span className="sg-panel-corner sg-panel-corner-tl" />
            <span className="sg-panel-corner sg-panel-corner-tr" />
            <span className="sg-panel-corner sg-panel-corner-bl" />
            <span className="sg-panel-corner sg-panel-corner-br" />

            <div className="sg-panel-head">
              <div>
                <span className="sg-panel-kicker">Khai Lập Trận Địa</span>
                <h2 id="create-title" className="sg-panel-title">Tạo phòng mới</h2>
              </div>
            </div>

            <form onSubmit={create} className="sg-form-grid">
              <div className="sg-form-col">
                <label className="sg-field-label" htmlFor="room-name">Tên phòng</label>
                <input
                  id="room-name"
                  className="sg-text-input"
                  maxLength={80}
                  required
                  value={roomName}
                  onChange={(e) => setRoomName(e.target.value)}
                />
              </div>

              <div className="sg-form-row">
                <div className="sg-form-col">
                  <label className="sg-field-label" htmlFor="capacity">Số người</label>
                  <select
                    id="capacity"
                    className="sg-select-input"
                    value={capacity}
                    onChange={(e) => setCapacity(Number(e.target.value))}
                  >
                    {Array.from({ length: 9 }, (_, i) => i + 2).map((n) => (
                      <option key={n} value={n}>{n} người</option>
                    ))}
                  </select>
                </div>
                <div className="sg-form-col">
                  <label className="sg-field-label" htmlFor="timeout">Thời gian lượt</label>
                  <select
                    id="timeout"
                    className="sg-select-input"
                    value={timeout}
                    onChange={(e) => setTimeoutSeconds(Number(e.target.value))}
                  >
                    {[10, 15, 20, 30, 45, 60].map((n) => (
                      <option key={n} value={n}>{n} giây</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Tactical Wooden Toggles Pool Accordion */}
              <details className="sg-pool-details pool-editor sg-create-pool" open>
                <summary className="sg-pool-summary-line">
                  <span>Chọn bể tướng và bể bài</span>
                  <span className="sg-accordion-caret" aria-hidden="true">▾</span>
                </summary>
                <p className="sg-pool-help-text">
                  Bỏ chọn gói để loại toàn bộ tướng hoặc bài thuộc gói đó khỏi ván. Hệ thống sẽ tự động loại các lựa chọn không phù hợp với phòng này.
                </p>
                {packs ? (
                  <>
                    {packGroup('Bể tướng', packs.generals, 'generals')}
                    {packGroup('Bể bài', packs.cards, 'cards')}
                    {qaScenario && qaPlan && !qaPlan.error && (
                      <p className="muted small">
                        Đã chuẩn bị caller QA native và giữ {qaPlan.kept.length} tướng khác tên cho {qaScenario.capacity} ghế.
                      </p>
                    )}
                    {qaPlan?.error && <p className="notice error-notice">{qaPlan.error}</p>}
                    <p className={`pool-summary ${validPool ? 'ok' : 'pool-warning'}`} role="status">
                      {pool
                        ? `${pool.generals} tướng khác tên · ${pool.cards} lá bài. Cần tối thiểu ${capacity * 5} tướng và ${capacity * 4} lá cho ${capacity} người.`
                        : 'Không thể kiểm tra bể tướng/bài.'}
                    </p>
                  </>
                ) : (
                  <p className="notice error-notice">Không tải được danh sách gói từ Lua.</p>
                )}
              </details>

              <button
                className="sg-create-btn button primary"
                type="submit"
                disabled={busy || !validPool}
              >
                Tạo phòng Quốc Chiến
              </button>
            </form>
          </section>

          {/* Panel 2: Danh sách phòng */}
          <section className="sg-classical-panel sg-list-panel" aria-labelledby="list-title">
            <span className="sg-panel-corner sg-panel-corner-tl" />
            <span className="sg-panel-corner sg-panel-corner-tr" />
            <span className="sg-panel-corner sg-panel-corner-bl" />
            <span className="sg-panel-corner sg-panel-corner-br" />

            <div className="sg-panel-head">
              <div>
                <span className="sg-panel-kicker">Chiến Trường Khả Dụng</span>
                <h2 id="list-title" className="sg-panel-title">Danh sách phòng</h2>
              </div>
              <button
                className="sg-refresh-btn button small-button"
                type="button"
                disabled={busy}
                onClick={() => run(() => adapter.refreshRooms())}
              >
                Làm mới
              </button>
            </div>

            {rooms.length ? (
              <ul className="room-list sg-room-cards-list">
                {rooms.map((room) => (
                  <LobbyRoomRow
                    room={room}
                    key={room.id}
                    busy={busy}
                    join={(id, pw) => run(() => adapter.joinRoom(id, pw))}
                  />
                ))}
              </ul>
            ) : (
              <p className="sg-empty-state muted" role="status">
                <span aria-hidden="true">◌ </span>Chưa có phòng khả dụng. Bạn có thể tạo phòng mới.
              </p>
            )}
          </section>
        </div>
      </div>

      {/* Bottom Footer Bar */}
      <footer className="sg-bottom-footer-bar">
        <div className="sg-ping-cluster">
          <span className="sg-ping-green" />
          <span>Máy chủ: Hoạt động tốt</span>
        </div>
        <span>Quốc Chiến · Bản BETA</span>
      </footer>
    </div>
  );
}

export function WaitingRoomScreen({ adapter, run, busy }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}) {
  const { roomName, roomMode, roomDisabledPacks, roomDisabledGenerals, players, capacity, ownId } = useGameStore((s) => s);
  const text = useDisplayText();
  const packs = useMemo(() => {
    try { return adapter.getRoomPacks(); } catch { return null; }
  }, [adapter]);
  const self = players.find((p) => p.id === ownId);
  const modeLabel = formatRoomMode(roomMode);

  const savedUsername = typeof window !== 'undefined' ? localStorage.getItem('tqs_saved_username') : null;
  const username = savedUsername?.trim() || 'Chúa Công';

  return (
    <div className="sg-waiting-screen sg-game-canvas">
      {/* Top Lord Header Bar */}
      <header className="sg-lord-header">
        <div className="sg-lord-info">
          <div className="sg-lord-avatar-frame">
            <img src="/photo-assets/generals/godzhaoyun.webp" alt="Avatar" className="sg-lord-avatar-img" />
          </div>
          <div className="sg-lord-meta">
            <div className="sg-lord-name-row">
              <span className="sg-lord-name">{username}</span>
              <span className="sg-lord-seal-badge">THẦN</span>
            </div>
            <span className="sg-lord-rank-text">Đại Đô Đốc · Quân Giai Cấp 1</span>
          </div>
        </div>
        <div className="sg-top-controls">
          <span className="sg-top-tag-badge">Trướng Chỉ Huy</span>
        </div>
      </header>

      {/* Screen Heading Banner */}
      <div className="sg-screen-heading-banner">
        <h1 className="sg-screen-title">TRƯỚNG CHỈ HUY</h1>
        <p className="sg-screen-subtitle">
          {roomName || 'Phòng Quốc Chiến'} · Bố trí trận hình sẵn sàng xuất chiến
        </p>
      </div>

      <div className="sg-main-content-scroll">
        <section className="sg-classical-panel sg-waiting-room" aria-labelledby="waiting-title">
          <span className="sg-panel-corner sg-panel-corner-tl" />
          <span className="sg-panel-corner sg-panel-corner-tr" />
          <span className="sg-panel-corner sg-panel-corner-bl" />
          <span className="sg-panel-corner sg-panel-corner-br" />

          <div className="sg-panel-head">
            <div>
              <span className="sg-panel-kicker">Trường Chỉ Huy Chiến Trận</span>
              <h2 id="waiting-title" className="sg-panel-title">{roomName || 'Phòng Quốc Chiến'}</h2>
            </div>
            <span className="sg-room-badge-mode">{modeLabel} · {capacity} người</span>
          </div>

          {roomMode === 'new_heg_mode' && packs && (
            <details className="sg-pool-details pool-editor waiting-pools">
              <summary className="sg-pool-summary-line">
                <span>Cấu hình bể của phòng (máy chủ xác nhận)</span>
                <span className="sg-accordion-caret" aria-hidden="true">▾</span>
              </summary>
              <p className="muted small">
                Bể tướng: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.generals.length} gói · Bể bài: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.cards.length} gói
              </p>
              <p className="small">
                Gói bài đang bật: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => getPackLabel(p, text)).join(' · ') || 'Không có'}
              </p>
              <p className="small">
                Gói tướng đang bật: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => getPackLabel(p, text)).join(' · ') || 'Không có'}
              </p>
              {!!roomDisabledGenerals.length && (
                <p className="muted small">Phòng cũng cấm riêng {roomDisabledGenerals.length} tướng.</p>
              )}
            </details>
          )}

          <div className="sg-roster-head">
            <h3 id="players-title" className="sg-roster-title">Danh sách người chơi</h3>
            <span className="sg-roster-count">{players.length}/{capacity} tướng lĩnh</span>
          </div>

          <ul className="player-list sg-roster-grid" aria-labelledby="players-title">
            {players.map((p, index) => {
              const isBot = p.id < 0 || p.netState === 'robot';
              const playerName = p.name || (isBot ? 'Bot' : `Người chơi ${p.id}`);
              const avatarSrc = AVATAR_LIST[index % AVATAR_LIST.length];
              return (
                <li key={p.id} className="player-item sg-seat-card">
                  <div className="sg-seat-header-row">
                    <span className="sg-seat-index-badge">{index + 1}</span>
                    <div className="sg-seat-identity-tags">
                      {p.id === ownId && <span className="you-tag sg-tag-you">Bạn</span>}
                      {p.owner && <span className="owner-tag sg-tag-owner">Chủ phòng</span>}
                      {isBot && <span className="sg-bot-tag sg-tag-bot">Bot</span>}
                    </div>
                  </div>
                  <div className="sg-seat-player-body">
                    <div className="sg-seat-avatar">
                      <img src={avatarSrc} alt={playerName} />
                    </div>
                    <div className="sg-seat-player-names">
                      <strong className="sg-seat-player-name">{playerName}</strong>
                      <span className="sg-seat-player-sub">{isBot ? 'Tự động' : p.owner ? 'Chủ Tướng' : 'Đồng minh'}</span>
                    </div>
                  </div>
                  <span className={`sg-seat-seal-status ${p.ready ? 'sg-seal-ready ok' : 'sg-seal-not-ready muted'}`}>
                    {p.ready ? 'SẴN SÀNG' : 'CHƯA SẴN SÀNG'}
                  </span>
                </li>
              );
            })}
            {Array.from({ length: Math.max(0, capacity - players.length) }, (_, index) => (
              <li
                key={`empty-${index}`}
                className="player-item sg-seat-card sg-seat-empty"
                aria-label={`Ghế trống ${players.length + index + 1}`}
              >
                <div className="sg-seat-index-badge">{players.length + index + 1}</div>
                <strong className="sg-empty-seat-title">Ghế trống</strong>
                <span className="sg-empty-seat-desc">Đang chờ tướng lĩnh vào…</span>
              </li>
            ))}
          </ul>

          <div className="room-actions sg-waiting-actions-bar">
            <button
              className="button secondary sg-action-btn-secondary"
              disabled={busy}
              onClick={() => run(() => adapter.ready())}
            >
              {self?.ready ? 'Bỏ sẵn sàng' : 'Sẵn sàng'}
            </button>
            {self?.owner && (
              <>
                <button
                  className="button secondary sg-action-btn-secondary"
                  disabled={busy || players.length >= capacity}
                  onClick={() => run(() => adapter.addBot())}
                >
                  + Thêm bot
                </button>
                <button
                  className="button primary sg-action-btn-gold"
                  disabled={busy || players.length < 2}
                  onClick={() => run(() => adapter.start())}
                >
                  Bắt đầu
                </button>
              </>
            )}
            <button
              className="button ghost sg-action-btn-ghost"
              disabled={busy}
              onClick={() => run(() => adapter.leaveRoom())}
            >
              Rời phòng
            </button>
          </div>
        </section>
      </div>

      {/* Bottom Footer Bar */}
      <footer className="sg-bottom-footer-bar">
        <div className="sg-ping-cluster">
          <span className="sg-ping-green" />
          <span>Máy chủ: Hoạt động tốt</span>
        </div>
        <span>Quốc Chiến · Bản BETA</span>
      </footer>
    </div>
  );
}

export default LobbyScreen;
