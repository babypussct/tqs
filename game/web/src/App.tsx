import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { GameAdapter, type RoomGeneral, type RoomPack } from './engine/gameAdapter';
import { useGameStore, type LobbyRoom } from './store/gameStore';
import type { RequestInfo } from './engine/connection';
import type { InitialGeneralPrompt } from './engine/generalSelection';
import GameBoardScreen from './GameBoardScreen';
import SkillInvokePanel from './SkillInvokePanel';
import ChoicePanel from './ChoicePanel';
import CardSelectionPanel from './CardSelectionPanel';
import CardsAndChoicePanel from './CardsAndChoicePanel';
import GameResultPanel from './GameResultPanel';
import { emptyBoard } from './store/boardState';
import { GAMEPLAY_REQUESTS } from './store/gameplayState';
import { useDisplayText, plainText } from './engine/displayText';
import RequestDeadline from './RequestDeadline';
import NativeDialogPanel from './NativeDialogPanel';

const gateway = (import.meta.env.VITE_GATEWAY_URL ?? '/gateway').replace(/\/$/, '');

function LoginScreen({ adapter, run, busy }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const connection = useGameStore((s) => s.connection);
  const submit = (event: FormEvent) => {
    event.preventDefault();
    run(() => adapter.login(username, password));
  };
  return (
    <section className="panel" aria-labelledby="login-title">
      <span className="section-label">01 / Kết nối</span>
      <h2 id="login-title">Đăng nhập FreeKill</h2>
      <p className="muted">Đăng nhập để xem sảnh và tạo phòng Quốc Chiến. Tên chưa tồn tại có thể được máy chủ đăng ký tự động.</p>
      <form onSubmit={submit} className="form-stack">
        <label htmlFor="username">Tên tài khoản</label>
        <input id="username" autoComplete="username" value={username} onChange={(e) => setUsername(e.target.value)} minLength={1} required maxLength={80} placeholder="Tên trong FreeKill" />
        <label htmlFor="password">Mật khẩu</label>
        <input id="password" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required placeholder="Mật khẩu FreeKill" />
        <button className="button primary" disabled={busy || connection.kind === 'connecting' || connection.kind === 'authenticating'} type="submit">
          {connection.kind === 'authenticating' ? 'Đang xác thực…' : connection.kind === 'connecting' ? 'Đang kết nối…' : 'Vào sảnh' }
        </button>
      </form>
      <small className="muted">Thông tin đăng nhập chỉ được dùng trong phiên kết nối hiện tại.</small>
      <details className="install-help">
        <summary>Chơi từ Màn hình chính</summary>
        <p><strong>iPhone:</strong> Trong Safari, mở Chia sẻ → Thêm vào Màn hình chính. Bật Mở dưới dạng ứng dụng web nếu có, rồi mở biểu tượng TQS để chơi trong cửa sổ riêng.</p>
        <p><strong>Android:</strong> Mở menu trình duyệt → Cài đặt ứng dụng hoặc Thêm vào màn hình chính, rồi mở biểu tượng TQS.</p>
        <p className="muted small">Đăng nhập và chơi cần kết nối mạng. Hãy kết thúc ván trước khi chuyển cách mở game.</p>
      </details>
    </section>
  );
}

function LobbyRoomRow({ room, join, busy }: { room: LobbyRoom; join: (id: number, pw: string) => void; busy: boolean }) {
  const [password, setPassword] = useState('');
  const unavailable = room.outdated || room.players >= room.capacity;
  return (
    <li className="room-item">
      <div className="room-item-header"><strong>{room.name}</strong><span className="room-count">{room.players}/{room.capacity}</span></div>
      <div className="muted small">{room.mode === 'new_heg_mode' ? 'Quốc Chiến' : room.mode}{room.outdated ? ' · Phiên bản cũ' : ''}{room.hasPassword ? ' · Có mật khẩu' : ''}</div>
      <div className="inline-controls">
        {room.hasPassword && <input aria-label={`Mật khẩu phòng ${room.name}`} type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Mật khẩu phòng" />}
        <button className="button secondary" type="button" disabled={busy || unavailable || (room.hasPassword && !password)} onClick={() => join(room.id, password)}>
          {unavailable ? 'Không thể vào' : 'Vào phòng'}
        </button>
      </div>
    </li>
  );
}

interface QaGeneralScenario {
  generalId: string;
  packId: string;
  sameKingdom: boolean;
  capacity: number;
  modeSettings: Record<string, boolean>;
}

interface QaGeneralPlan {
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
function readQaGeneralScenario(): QaGeneralScenario | null {
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

function buildQaGeneralPlan(adapter: GameAdapter, scenario: QaGeneralScenario): QaGeneralPlan {
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
    <div className="screen-stack">
      <section className="panel" aria-labelledby="create-title">
        <span className="section-label">02 / Quốc Chiến</span>
        <h2 id="create-title">Tạo phòng mới</h2>
        <form onSubmit={create} className="form-stack">
          <label htmlFor="room-name">Tên phòng</label>
          <input id="room-name" maxLength={80} required value={roomName} onChange={(e) => setRoomName(e.target.value)} />
          <div className="field-pair">
            <div><label htmlFor="capacity">Số người</label><select id="capacity" value={capacity} onChange={(e) => setCapacity(Number(e.target.value))}>{Array.from({ length: 9 }, (_, i) => i + 2).map((n) => <option key={n} value={n}>{n} người</option>)}</select></div>
            <div><label htmlFor="timeout">Thời gian lượt</label><select id="timeout" value={timeout} onChange={(e) => setTimeoutSeconds(Number(e.target.value))}>{[10, 15, 20, 30, 45, 60].map((n) => <option key={n} value={n}>{n} giây</option>)}</select></div>
          </div>
          <details className="pool-editor" open>
            <summary>Chọn bể tướng và bể bài</summary>
            <p className="muted small">Bỏ chọn gói để loại toàn bộ tướng hoặc bài thuộc gói đó khỏi ván. Các gói không hỗ trợ Quốc Chiến được FreeKill tự loại.</p>
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
          <button className="button primary" type="submit" disabled={busy || !validPool}>Tạo phòng Quốc Chiến</button>
        </form>
      </section>
      <section className="panel" aria-labelledby="list-title">
        <div className="row-between"><h2 id="list-title">Danh sách phòng</h2><button className="button small-button" disabled={busy} onClick={() => run(() => adapter.refreshRooms())}>Làm mới</button></div>
        {rooms.length ? <ul className="room-list">{rooms.map((room) => <LobbyRoomRow room={room} key={room.id} busy={busy} join={(id, pw) => run(() => adapter.joinRoom(id, pw))} />)}</ul> : <p className="muted">Chưa có phòng khả dụng. Bạn có thể tạo phòng mới.</p>}
      </section>
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
  return (
    <section className="panel" aria-labelledby="waiting-title">
      <span className="section-label">03 / Phòng chờ</span>
      <h2 id="waiting-title">{roomName || 'Phòng Quốc Chiến'}</h2>
      <p className="muted">{roomMode === 'new_heg_mode' ? 'Quốc Chiến' : roomMode} · {players.length}/{capacity} người chơi</p>
      {roomMode === 'new_heg_mode' && packs && <details className="pool-editor waiting-pools">
        <summary>Cấu hình bể của phòng (máy chủ xác nhận)</summary>
        <p className="muted small">Bể tướng: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.generals.length} gói · Bể bài: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).length}/{packs.cards.length} gói</p>
        <p className="small">Gói bài đang bật: {packs.cards.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => text(p.id) !== p.id ? text(p.id) : p.label).join(' · ') || 'Không có'}</p>
        <p className="small">Gói tướng đang bật: {packs.generals.filter((p) => !roomDisabledPacks.includes(p.id)).map((p) => text(p.id) !== p.id ? text(p.id) : p.label).join(' · ') || 'Không có'}</p>
        {!!roomDisabledGenerals.length && <p className="muted small">Phòng cũng cấm riêng {roomDisabledGenerals.length} tướng.</p>}
      </details>}
      <ul className="player-list">
        {players.map((p) => <li key={p.id} className="player-item"><div><strong>{p.name || (p.id < 0 ? 'Bot' : `Người chơi ${p.id}`)}</strong>{p.id === ownId && <span className="you-tag">Bạn</span>}{p.owner && <span className="owner-tag">Chủ phòng</span>}</div><span className={p.ready ? 'ok' : 'muted'}>{p.ready ? 'Sẵn sàng' : 'Chưa sẵn sàng'}</span></li>)}
      </ul>
      <div className="room-actions">
        <button className="button secondary" disabled={busy} onClick={() => run(() => adapter.ready())}>{self?.ready ? 'Bỏ sẵn sàng' : 'Sẵn sàng'}</button>
        {self?.owner && <><button className="button secondary" disabled={busy || players.length >= capacity} onClick={() => run(() => adapter.addBot())}>+ Thêm bot</button><button className="button primary" disabled={busy || players.length < 2} onClick={() => run(() => adapter.start())}>Bắt đầu</button></>}
        <button className="button ghost" disabled={busy} onClick={() => run(() => adapter.leaveRoom())}>Rời phòng</button>
      </div>
    </section>
  );
}

function InitialGeneralPanel({ adapter, run, busy, request, prompt }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
  request: RequestInfo;
  prompt: InitialGeneralPrompt;
}) {
  const text = useDisplayText();
  const [chosen, setChosen] = useState<string[]>([]);
  const [kingdom, setKingdom] = useState('');
  const [warning, setWarning] = useState('');
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    setNow(Date.now());
    if (request.expiresAt === null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request.requestId, request.expiresAt]);

  const labels = useMemo(() => {
    try { return adapter.getGeneralLabels(prompt.generals); }
    catch { return prompt.generals; }
  }, [adapter, prompt]);
  const kingdoms = useMemo(() => {
    if (chosen.length !== 2) return [];
    try { return adapter.getInitialGeneralKingdoms(request.requestId, chosen[0], chosen[1]); }
    catch { return []; }
  }, [adapter, request.requestId, chosen]);
  const seconds = request.expiresAt === null ? null : Math.max(0, Math.ceil((request.expiresAt - now) / 1000));
  const expired = seconds === 0;
  const selectedKingdom = kingdoms.length === 1 ? kingdoms[0] : kingdom;
  const choose = (name: string) => {
    if (busy || expired) return;
    setWarning('');
    setKingdom('');
    if (chosen.includes(name)) {
      setChosen(chosen[0] === name ? [] : [chosen[0]]);
    } else if (chosen.length === 0 || chosen.length === 2) {
      setChosen([name]);
    } else {
      try {
        const valid = adapter.getInitialGeneralKingdoms(request.requestId, chosen[0], name);
        if (!valid.length) {
          setWarning('Phó tướng không tương thích với chủ tướng hoặc thế lực đã bật.');
          return;
        }
        setChosen([chosen[0], name]);
      } catch (error) {
        setWarning(error instanceof Error ? error.message : 'Không thể kiểm tra cặp tướng bằng Lua.');
      }
    }
  };
  const confirm = () => run(() => adapter.chooseInitialGenerals(request.requestId, chosen[0], chosen[1], selectedKingdom));

  return (
    <section className="panel request-panel" aria-labelledby="initial-general-title">
      <span className="section-label">Quốc Chiến · Chọn tướng</span>
      <div className="row-between">
        <h2 id="initial-general-title">Chọn chủ tướng và phó tướng</h2>
        <span className={`countdown ${expired ? 'expired' : ''}`} role="timer">
          {seconds === null ? 'Không giới hạn' : expired ? 'Hết giờ' : `${seconds}s`}
        </span>
      </div>
      <p className="muted">Chọn chủ tướng trước, sau đó chọn phó tướng tương thích. Nhấn lại tướng đã chọn để bỏ chọn.</p>
      <div className="chosen-generals" aria-live="polite">
        <div><span className="section-label">Chủ tướng</span><strong>{chosen[0] ? labels[prompt.generals.indexOf(chosen[0])] : 'Chưa chọn'}</strong></div>
        <div><span className="section-label">Phó tướng</span><strong>{chosen[1] ? labels[prompt.generals.indexOf(chosen[1])] : 'Chưa chọn'}</strong></div>
      </div>
      <div className="general-grid" role="group" aria-label="Danh sách võ tướng">
        {prompt.generals.map((name, index) => {
          const pos = chosen.indexOf(name);
          return <button key={`${name}-${index}`} type="button" className={`general-choice ${pos !== -1 ? 'selected' : ''}`}
            aria-pressed={pos !== -1} disabled={busy || expired} onClick={() => choose(name)}>
            <strong>{plainText(labels[index] || text(name))}</strong>
            {pos !== -1 && <span className="general-position">{pos === 0 ? 'Chủ tướng' : 'Phó tướng'}</span>}
          </button>;
        })}
      </div>
      {warning && <p className="notice" role="status">{warning}</p>}
      {chosen.length === 2 && kingdoms.length === 0 && <p className="notice error-notice">Cặp tướng này không có thế lực hợp lệ.</p>}
      {kingdoms.length > 1 && <fieldset className="kingdom-picker">
        <legend>Chọn thế lực</legend>
        {kingdoms.map((k) => <label key={k}><input type="radio" name={`kingdom-${request.requestId}`} value={k}
          checked={kingdom === k} disabled={busy || expired} onChange={() => setKingdom(k)} />{text(k)}</label>)}
      </fieldset>}
      {kingdoms.length === 1 && <p className="muted">Thế lực: <strong>{text(kingdoms[0])}</strong></p>}
      <div className="request-actions">
        <button type="button" className="button secondary" disabled={busy || expired || !chosen.length}
          onClick={() => { setChosen([]); setKingdom(''); setWarning(''); }}>Chọn lại</button>
        <button type="button" className="button primary" disabled={busy || expired || chosen.length !== 2 ||
          kingdoms.length === 0 || !kingdoms.includes(selectedKingdom)} onClick={confirm}>Xác nhận tướng</button>
      </div>
    </section>
  );
}

export default function App() {
  const adapter = useMemo(() => new GameAdapter(gateway), []);
  const snapshot = useGameStore();
  const [busy, setBusy] = useState(false);
  const [networkOnline, setNetworkOnline] = useState(navigator.onLine);
  const [exitAction, setExitAction] = useState<'leave' | 'disconnect' | null>(null);
  useEffect(() => {
    const changed = () => setNetworkOnline(navigator.onLine);
    window.addEventListener('online', changed);
    window.addEventListener('offline', changed);
    return () => { window.removeEventListener('online', changed); window.removeEventListener('offline', changed); };
  }, []);
  const trusting = snapshot.players.find((player) => player.id === snapshot.ownId)?.netState === 'trust';

  useEffect(() => {
    const controller = new AbortController();
    void adapter.boot(controller.signal);
    return () => { controller.abort(); adapter.disconnect(); };
  }, [adapter]);

  useEffect(() => {
    if (snapshot.phase !== 'playing') {
      setExitAction(null);
      return;
    }
    const warnBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = '';
    };
    window.addEventListener('beforeunload', warnBeforeUnload);
    return () => window.removeEventListener('beforeunload', warnBeforeUnload);
  }, [snapshot.phase]);

  const run = (action: () => void | Promise<void>) => {
    if (busy) return;
    setBusy(true);
    useGameStore.getState().update({ error: null });
    void Promise.resolve().then(action).catch((error: unknown) => {
      useGameStore.getState().update({ error: error instanceof Error ? error.message : String(error) });
    }).finally(() => setBusy(false));
  };

  const disconnect = () => {
    adapter.disconnect();
    useGameStore.getState().update({ phase: 'login', connection: { kind: 'closed', reason: 'Đã ngắt kết nối' }, rooms: [], players: [], ownId: null, pendingRequest: null, skillInvoke: null, initialGeneral: null, result: null, board: emptyBoard(), progress: '', error: null });
  };

  return (
    <main className={`shell ${snapshot.phase === 'playing' ? 'shell-playing' : ''}`}>
      <header className="app-header">
        <div><span className="eyebrow">TQS · Quốc Chiến</span><h1>Tam Quốc Sát <em>Mobile</em></h1><p className="intro">Trải nghiệm FreeKill trên trình duyệt.</p></div>
        <span className={`status ${snapshot.connection.kind === 'online' ? 'connected' : ''}`}>{snapshot.connection.kind === 'online' ? 'Đã kết nối' : snapshot.connection.kind === 'authenticating' ? 'Đang xác thực' : 'Chưa kết nối'}</span>
      </header>
      {!networkOnline && <p className="notice" role="status">Bạn đang ngoại tuyến. Kết nối mạng để đăng nhập hoặc tiếp tục ván.</p>}
      {snapshot.progress && <div className="notice" role="status">{snapshot.progress}</div>}
      {snapshot.error && <div className="notice error-notice" role="alert">{snapshot.error}{snapshot.phase === 'boot' && <button className="button small-button" onClick={() => run(() => adapter.boot())}>Thử lại</button>}</div>}
      {exitAction && snapshot.phase === 'playing' && <section className="panel" role="alertdialog" aria-labelledby="exit-title" aria-describedby="exit-warning">
        <h2 id="exit-title">Ván vẫn đang chạy</h2>
        <p id="exit-warning">Rời trận hoặc ngắt kết nối khi còn sống có thể khiến máy chủ tạm chặn IP. Nếu cần tạm nghỉ, hãy bật BOT chơi hộ và giữ trang mở.</p>
        <div className="inline-controls">
          <button className="button primary" disabled={busy} onClick={() => setExitAction(null)}>Tiếp tục ván</button>
          {!trusting && <button className="button secondary" disabled={busy} onClick={() => { setExitAction(null); run(() => adapter.toggleTrust()); }}>BOT chơi hộ</button>}
          <button className="button ghost" disabled={busy} onClick={() => {
            const action = exitAction;
            setExitAction(null);
            run(() => action === 'leave' ? adapter.leaveRoom() : disconnect());
          }}>{exitAction === 'leave' ? 'Vẫn rời trận' : 'Vẫn ngắt kết nối'}</button>
        </div>
      </section>}
      {snapshot.phase === 'playing' && !trusting && <RequestDeadline request={snapshot.pendingRequest} />}
      {snapshot.phase === 'boot' && <section className="panel"><h2>Đang chuẩn bị tài nguyên…</h2><p className="muted">Tải và xác minh FreeKill, Utility, Hegemony trước khi đăng nhập.</p></section>}
      {snapshot.phase === 'login' && <LoginScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'lobby' && <LobbyScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'room' && snapshot.result && <GameResultPanel result={snapshot.result} busy={busy}
        leave={() => run(() => adapter.leaveRoom())} />}
      {snapshot.phase === 'room' && <WaitingRoomScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'playing' && <GameBoardScreen busy={busy} leave={() => setExitAction('leave')}
        toggleTrust={() => run(() => adapter.toggleTrust())}
        direct={(id, data) => {
          const request = snapshot.pendingRequest;
          if (request && GAMEPLAY_REQUESTS.has(request.command)) run(() => {
            adapter.finishDirectInteraction(request.requestId, id, data);
          });
        }}
        dispatch={(type, id, action, data) => {
          const request = snapshot.pendingRequest;
          if (request && GAMEPLAY_REQUESTS.has(request.command))
            run(() => adapter.updateRequestUI(request.requestId, type, id, action, data));
        }} />}
      {!trusting && snapshot.pendingRequest?.command === 'AskForSkillInvoke' && <SkillInvokePanel busy={busy} request={snapshot.pendingRequest} prompt={snapshot.skillInvoke}
        onRespond={(choice) => run(() => adapter.sendUiAction(snapshot.pendingRequest!.requestId, choice))} />}
      {!trusting && snapshot.pendingRequest && ['AskForChoices', 'AskForOptions'].includes(snapshot.pendingRequest.command) && snapshot.pendingRequest.choicePrompt &&
        <ChoicePanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          busy={busy} request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.choicePrompt}
          respond={(selected) => run(() => adapter.respondToChoices(snapshot.pendingRequest!.requestId, selected))} />}
      {!trusting && snapshot.pendingRequest?.cardSelectionPrompt &&
        <CardSelectionPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.cardSelectionPrompt} busy={busy}
          view={(selected) => adapter.getCardSelectionView(snapshot.pendingRequest!.requestId, selected)}
          respond={(selected, cancel) => run(() => adapter.respondToCardSelection(snapshot.pendingRequest!.requestId, selected, cancel))} />}
      {!trusting && snapshot.pendingRequest?.cardsAndChoicePrompt &&
        <CardsAndChoicePanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.cardsAndChoicePrompt} busy={busy}
          view={(selected) => adapter.getCardsAndChoiceView(snapshot.pendingRequest!.requestId, selected)}
          respond={(selected, choice, cancel) => run(() => adapter.respondToCardsAndChoice(snapshot.pendingRequest!.requestId, selected, choice, cancel))} />}
      {!trusting && snapshot.pendingRequest?.nativeDialogPrompt &&
        <NativeDialogPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.nativeDialogPrompt} busy={busy}
          chooseGeneral={(token) => run(() => adapter.selectNativeGeneral(snapshot.pendingRequest!.requestId, token))}
          view={() => adapter.getNativeDialogView(snapshot.pendingRequest!.requestId)}
          move={(token, area, index) => run(() => adapter.moveNativeDialogCard(snapshot.pendingRequest!.requestId, token, area, index))}
          respond={(token, cancel) => run(() => adapter.respondToNativeDialog(snapshot.pendingRequest!.requestId, token, cancel))} />}
      {!trusting && snapshot.pendingRequest?.command === 'CustomDialog' && snapshot.initialGeneral &&
        <InitialGeneralPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`} adapter={adapter} run={run} busy={busy}
          request={snapshot.pendingRequest} prompt={snapshot.initialGeneral} />}
      {!trusting && snapshot.pendingRequest && snapshot.pendingRequest.command !== 'AskForSkillInvoke' &&
        !GAMEPLAY_REQUESTS.has(snapshot.pendingRequest.command) &&
        !snapshot.pendingRequest.nativeDialogPrompt &&
        !snapshot.pendingRequest.cardSelectionPrompt &&
        !snapshot.pendingRequest.cardsAndChoicePrompt &&
        !(snapshot.pendingRequest.command === 'CustomDialog' && snapshot.initialGeneral) &&
        !(['AskForChoices', 'AskForOptions'].includes(snapshot.pendingRequest.command) && snapshot.pendingRequest.choicePrompt) &&
        <div className="notice error-notice" role="alert">Máy chủ đang chờ phản hồi: {snapshot.pendingRequest.command}. Bộ điều khiển gameplay chưa hỗ trợ yêu cầu này.</div>}
      {snapshot.connection.kind === 'online' && <footer className="footer"><span>{snapshot.manifest?.fileCount ?? 0} tệp đã xác minh</span><button className="button ghost" disabled={busy} onClick={() => snapshot.phase === 'playing' ? setExitAction('disconnect') : run(disconnect)}>Ngắt kết nối</button></footer>}
    </main>
  );
}
