import { useMemo, useState, type FormEvent } from 'react';
import { GameAdapter, type RoomGeneral, type RoomPack } from './engine/gameAdapter';
import { useDisplayText } from './engine/displayText';
import { useGameStore, type LobbyRoom } from './store/gameStore';

const ROOM_MODE_LABELS: Record<string, string> = {
  new_heg_mode: 'Quốc Chiến',
  standard: 'Tiêu chuẩn',
  standard_mode: 'Tiêu chuẩn',
};

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
      <div className="room-item-header sg-room-card-header">
        <div className="sg-room-card-title">
          <h3 className="sg-room-name">{room.name}</h3>
          <p className="muted small sg-room-meta">
            <span className="sg-mode-tag">{modeLabel}</span>
            {room.outdated && <><span aria-hidden="true"> · </span><span>Phiên bản không phù hợp</span></>}
            {room.hasPassword && <><span aria-hidden="true"> · </span><span><span aria-hidden="true">🔒 </span>Có mật khẩu</span></>}
          </p>
        </div>
        <span className="room-count" aria-label={`${room.players} trên ${room.capacity} người`}>{room.players}/{room.capacity}</span>
      </div>
      <div className="sg-room-card-footer">
        <span className={`sg-room-status sg-room-status-${availability.tone}`}>
          <span aria-hidden="true">{availability.tone === 'open' ? '●' : availability.tone === 'full' ? '■' : '!'}</span>
          {availability.label}
        </span>
        <div className="inline-controls sg-room-controls">
          {room.hasPassword && <input aria-label={`Mật khẩu phòng ${room.name}`} type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Mật khẩu phòng" />}
          <button className="button secondary" type="button" disabled={busy || unavailable || (room.hasPassword && !password)} onClick={() => join(room.id, password)}>
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

/**
 * The live scenario runner can ask for a bounded native general pool via the
 * URL. This is intentionally not part of the normal lobby controls: it only
 * changes the native disabledGenerals setting when both bounded query
 * parameters are present, and never renders the internal IDs.
 */
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
    // Wild generals choose a Hegemony country after reveal and therefore do
    // not share the literal `wild` kingdom with ordinary generals in the
    // pre-game pool. For that QA shape, use the largest ordinary kingdom
    // group so the other real client still has a valid pair.
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
  const packGroup = (title: string, items: RoomPack[], type: string) => (
    <fieldset className="pool-group" aria-label={title}>
      <legend>{title} ({items.length})</legend>
      <div className="pool-options">
        {items.map((pack) => <label key={pack.id} className="pool-option">
          <input type="checkbox" data-pack-id={pack.id} data-pack-type={type}
            checked={!disabledPacks.includes(pack.id)} disabled={busy}
            onChange={() => togglePack(pack.id)} />
          <span>{text(pack.id) !== pack.id ? text(pack.id) : pack.label}<small>{pack.count} {type === 'generals' ? 'tướng' : 'lá'}</small></span>
        </label>)}
      </div>
    </fieldset>
  );
  const create = (event: FormEvent) => {
    event.preventDefault();
    run(() => adapter.createRoom(roomName, capacity, timeout, disabledPacks, disabledGenerals, qaScenario?.modeSettings));
  };
  return (
    <div className="sg-lobby-screen">
      <header className="sg-screen-heading">
        <span className="section-label sg-section-label">02 / Sảnh điều binh</span>
        <h2>Sảnh Quốc Chiến</h2>
        <p>Bố trí phòng đấu và điểm tướng xuất chinh.</p>
      </header>
      <div className="screen-stack sg-lobby-layout">
        <section className="panel sg-panel sg-metal-panel sg-create-panel" aria-labelledby="create-title">
          <span className="sg-panel-mark" aria-hidden="true">TQS</span>
          <span className="section-label sg-section-label">Khai lập trận địa</span>
          <h2 id="create-title">Tạo phòng mới</h2>
          <form onSubmit={create} className="form-stack sg-create-form">
            <div className="sg-create-basics">
              <label htmlFor="room-name">Tên phòng</label>
              <input id="room-name" maxLength={80} required value={roomName} onChange={(e) => setRoomName(e.target.value)} />
              <div className="field-pair">
                <div><label htmlFor="capacity">Số người</label><select id="capacity" value={capacity} onChange={(e) => setCapacity(Number(e.target.value))}>{Array.from({ length: 9 }, (_, i) => i + 2).map((n) => <option key={n} value={n}>{n} người</option>)}</select></div>
                <div><label htmlFor="timeout">Thời gian lượt</label><select id="timeout" value={timeout} onChange={(e) => setTimeoutSeconds(Number(e.target.value))}>{[10, 15, 20, 30, 45, 60].map((n) => <option key={n} value={n}>{n} giây</option>)}</select></div>
              </div>
            </div>
            <details className="pool-editor sg-accordion sg-create-pool" open>
              <summary><span>Chọn bể tướng và bể bài</span><span className="sg-accordion-caret" aria-hidden="true">⌄</span></summary>
              <p className="muted small">Bỏ chọn gói để loại toàn bộ tướng hoặc bài thuộc gói đó khỏi ván. Hệ thống sẽ tự động loại các lựa chọn không phù hợp với phòng này.</p>
              {packs ? <>
                {packGroup('Bể tướng', packs.generals, 'generals')}
                {packGroup('Bể bài', packs.cards, 'cards')}
                {qaScenario && qaPlan && !qaPlan.error && <p className="muted small">Đã chuẩn bị caller QA native và giữ {qaPlan.kept.length} tướng khác tên cho {qaScenario.capacity} ghế.</p>}
                {qaPlan?.error && <p className="notice error-notice">{qaPlan.error}</p>}
                <p className={`pool-summary ${validPool ? 'ok' : 'pool-warning'}`} role="status">
                  {pool ? `${pool.generals} tướng khác tên · ${pool.cards} lá bài. Cần tối thiểu ${capacity * 5} tướng và ${capacity * 4} lá cho ${capacity} người.` : 'Không thể kiểm tra bể tướng/bài.'}
                </p>
              </> : <p className="notice error-notice">Không tải được danh sách gói từ Lua.</p>}
            </details>
            <div className="sg-create-actions">
              <button className="button primary" type="submit" disabled={busy || !validPool}>Tạo phòng Quốc Chiến</button>
            </div>
          </form>
        </section>
        <section className="panel sg-panel sg-metal-panel sg-list-panel" aria-labelledby="list-title">
          <span className="sg-panel-mark" aria-hidden="true">TQS</span>
          <div className="row-between sg-panel-heading">
            <div><span className="section-label sg-section-label">Chiến trường khả dụng</span><h2 id="list-title">Danh sách phòng</h2></div>
            <button className="button small-button" disabled={busy} onClick={() => run(() => adapter.refreshRooms())}>Làm mới</button>
          </div>
          {rooms.length ? <ul className="room-list sg-room-list">{rooms.map((room) => <LobbyRoomRow room={room} key={room.id} busy={busy} join={(id, pw) => run(() => adapter.joinRoom(id, pw))} />)}</ul> : <p className="muted sg-empty-state" role="status"><span aria-hidden="true">◌ </span>Chưa có phòng khả dụng. Bạn có thể tạo phòng mới.</p>}
        </section>
      </div>
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
  return (
    <section className="panel sg-panel sg-metal-panel sg-waiting-room" aria-labelledby="waiting-title">
      <span className="sg-panel-mark" aria-hidden="true">TQS</span>
      <span className="section-label sg-section-label">03 / Trướng chỉ huy</span>
      <h2 id="waiting-title">{roomName || 'Phòng Quốc Chiến'}</h2>
      <p className="muted sg-room-summary"><span className="sg-mode-tag">{modeLabel}</span><span aria-hidden="true"> · </span>{players.length}/{capacity} người chơi</p>
      {roomMode === 'new_heg_mode' && packs && <details className="pool-editor waiting-pools">
        <summary><span>Cấu hình bể của phòng (máy chủ xác nhận)</span><span className="sg-accordion-caret" aria-hidden="true">⌄</span></summary>
        <p className="muted small">Bể tướng: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.generals.length} gói · Bể bài: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.cards.length} gói</p>
        <p className="small">Gói bài đang bật: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => text(p.id) !== p.id ? text(p.id) : p.label).join(' · ') || 'Không có'}</p>
        <p className="small">Gói tướng đang bật: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => text(p.id) !== p.id ? text(p.id) : p.label).join(' · ') || 'Không có'}</p>
        {!!roomDisabledGenerals.length && <p className="muted small">Phòng cũng cấm riêng {roomDisabledGenerals.length} tướng.</p>}
      </details>}
      <div className="sg-roster-heading"><h3 id="players-title">Danh sách người chơi</h3><span className="sg-roster-count">{players.length}/{capacity}</span></div>
      <ul className="player-list sg-player-list" aria-labelledby="players-title">
        {players.map((p, index) => {
          const isBot = p.id < 0 || p.netState === 'robot';
          const playerName = p.name || (isBot ? 'Bot' : `Người chơi ${p.id}`);
          return <li key={p.id} className="player-item sg-player-card">
            <div className="sg-player-identity">
              <span className="sg-seat-number" aria-hidden="true">{index + 1}</span>
              <div className="sg-player-copy">
                <div className="sg-player-name-row"><strong>{playerName}</strong>{p.id === ownId && <span className="you-tag">Bạn</span>}{p.owner && <span className="owner-tag">Chủ phòng</span>}{isBot && playerName !== 'Bot' && <span className="sg-bot-tag">Bot</span>}</div>
                {isBot && <span className="sg-player-meta">Binh sĩ máy</span>}
              </div>
            </div>
            <span className={`sg-ready-badge ${p.ready ? 'sg-ready' : 'sg-not-ready'} ${p.ready ? 'ok' : 'muted'}`}><span aria-hidden="true">{p.ready ? '✓' : '⏳'}</span> {p.ready ? 'Sẵn sàng' : 'Chưa sẵn sàng'}</span>
          </li>;
        })}
        {Array.from({ length: Math.max(0, capacity - players.length) }, (_, index) => <li key={`empty-${index}`} className="sg-player-card sg-empty-seat" aria-label={`Ghế trống ${players.length + index + 1}`}>
          <div className="sg-player-identity"><span className="sg-seat-number" aria-hidden="true">{players.length + index + 1}</span><div className="sg-player-copy"><strong>Ghế trống</strong><span className="sg-player-meta">Đang đợi người chơi vào…</span></div></div>
          <span className="sg-seat-status">Chờ kết nối</span>
        </li>)}
      </ul>
      <div className="room-actions sg-room-actions">
        <button className="button secondary" disabled={busy} onClick={() => run(() => adapter.ready())}>{self?.ready ? 'Bỏ sẵn sàng' : 'Sẵn sàng'}</button>
        {self?.owner && <><button className="button secondary" disabled={busy || players.length >= capacity} onClick={() => run(() => adapter.addBot())}>+ Thêm bot</button><button className="button primary" disabled={busy || players.length < 2} onClick={() => run(() => adapter.start())}>Bắt đầu</button></>}
        <button className="button ghost" disabled={busy} onClick={() => run(() => adapter.leaveRoom())}>Rời phòng</button>
      </div>
    </section>
  );
}

export default LobbyScreen;
