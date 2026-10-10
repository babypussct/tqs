import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore, type LobbyRoom, type SkillInvokePrompt } from './store/gameStore';
import type { RequestInfo } from './engine/connection';
import type { InitialGeneralPrompt } from './engine/generalSelection';
import GameBoardScreen from './GameBoardScreen';
import { emptyBoard } from './store/boardState';

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

function LobbyScreen({ adapter, run, busy }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}) {
  const rooms = useGameStore((s) => s.rooms);
  const [roomName, setRoomName] = useState('Quốc Chiến Mobile');
  const [capacity, setCapacity] = useState(4);
  const [timeout, setTimeoutSeconds] = useState(30);
  const create = (event: FormEvent) => {
    event.preventDefault();
    run(() => adapter.createRoom(roomName, capacity, timeout));
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
          <button className="button primary" type="submit" disabled={busy}>Tạo phòng Quốc Chiến</button>
        </form>
      </section>
      <section className="panel" aria-labelledby="list-title">
        <div className="row-between"><h2 id="list-title">Danh sách phòng</h2><button className="button small-button" disabled={busy} onClick={() => run(() => adapter.refreshRooms())}>Làm mới</button></div>
        {rooms.length ? <ul className="room-list">{rooms.map((room) => <LobbyRoomRow room={room} key={room.id} busy={busy} join={(id, pw) => run(() => adapter.joinRoom(id, pw))} />)}</ul> : <p className="muted">Chưa có phòng khả dụng. Bạn có thể tạo phòng mới.</p>}
      </section>
    </div>
  );
}

function WaitingRoomScreen({ adapter, run, busy }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}) {
  const { roomName, roomMode, players, capacity, ownId } = useGameStore((s) => s);
  const self = players.find((p) => p.id === ownId);
  return (
    <section className="panel" aria-labelledby="waiting-title">
      <span className="section-label">03 / Phòng chờ</span>
      <h2 id="waiting-title">{roomName || 'Phòng Quốc Chiến'}</h2>
      <p className="muted">{roomMode === 'new_heg_mode' ? 'Quốc Chiến' : roomMode} · {players.length}/{capacity} người chơi</p>
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

function SkillInvokePanel({ adapter, run, busy, request, prompt }: {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
  request: RequestInfo;
  prompt: SkillInvokePrompt | null;
}) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    setNow(Date.now());
    if (request.expiresAt === null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request.requestId, request.expiresAt]);

  const seconds = request.expiresAt === null ? null : Math.max(0, Math.ceil((request.expiresAt - now) / 1000));
  const expired = seconds === 0;
  const respond = (choice: 'OK' | 'Cancel') => run(() => adapter.sendUiAction(request.requestId, choice));
  return (
    <section className="panel request-panel" aria-labelledby="skill-request-title">
      <span className="section-label">Yêu cầu trong trận</span>
      <div className="row-between">
        <h2 id="skill-request-title">Kích hoạt kỹ năng?</h2>
        <span className={`countdown ${expired ? 'expired' : ''}`} role="timer">
          {seconds === null ? 'Không giới hạn' : expired ? 'Hết giờ' : `${seconds}s`}
        </span>
      </div>
      {prompt ? <>
        <p className="skill-name">{prompt.skill}</p>
        <p className="muted">{prompt.prompt || `Bạn có muốn kích hoạt ${prompt.skill}?`}</p>
      </> : <p className="muted">Đang tải thông tin kỹ năng từ Lua…</p>}
      <div className="request-actions">
        <button type="button" className="button primary" disabled={busy || expired || !prompt} onClick={() => respond('OK')}>Kích hoạt</button>
        <button type="button" className="button secondary" disabled={busy || expired || !prompt} onClick={() => respond('Cancel')}>Bỏ qua</button>
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
            <strong>{labels[index] || name}</strong><small>{name}</small>
            {pos !== -1 && <span className="general-position">{pos === 0 ? 'Chủ tướng' : 'Phó tướng'}</span>}
          </button>;
        })}
      </div>
      {warning && <p className="notice" role="status">{warning}</p>}
      {chosen.length === 2 && kingdoms.length === 0 && <p className="notice error-notice">Cặp tướng này không có thế lực hợp lệ.</p>}
      {kingdoms.length > 1 && <fieldset className="kingdom-picker">
        <legend>Chọn thế lực</legend>
        {kingdoms.map((k) => <label key={k}><input type="radio" name={`kingdom-${request.requestId}`} value={k}
          checked={kingdom === k} disabled={busy || expired} onChange={() => setKingdom(k)} />{k}</label>)}
      </fieldset>}
      {kingdoms.length === 1 && <p className="muted">Thế lực: <strong>{kingdoms[0]}</strong></p>}
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

  useEffect(() => {
    const controller = new AbortController();
    void adapter.boot(controller.signal);
    return () => { controller.abort(); adapter.disconnect(); };
  }, [adapter]);

  const run = (action: () => void | Promise<void>) => {
    if (busy) return;
    setBusy(true);
    useGameStore.getState().update({ error: null });
    void Promise.resolve().then(action).catch((error: unknown) => {
      useGameStore.getState().update({ error: error instanceof Error ? error.message : String(error) });
    }).finally(() => setBusy(false));
  };

  return (
    <main className={`shell ${snapshot.phase === 'playing' ? 'shell-playing' : ''}`}>
      <header className="app-header">
        <div><span className="eyebrow">TQS · Quốc Chiến</span><h1>Tam Quốc Sát <em>Mobile</em></h1><p className="intro">Trải nghiệm FreeKill trên trình duyệt.</p></div>
        <span className={`status ${snapshot.connection.kind === 'online' ? 'connected' : ''}`}>{snapshot.connection.kind === 'online' ? 'Đã kết nối' : snapshot.connection.kind === 'authenticating' ? 'Đang xác thực' : 'Chưa kết nối'}</span>
      </header>
      {snapshot.progress && <div className="notice" role="status">{snapshot.progress}</div>}
      {snapshot.error && <div className="notice error-notice" role="alert">{snapshot.error}{snapshot.phase === 'boot' && <button className="button small-button" onClick={() => run(() => adapter.boot())}>Thử lại</button>}</div>}
      {snapshot.phase === 'boot' && <section className="panel"><h2>Đang chuẩn bị tài nguyên…</h2><p className="muted">Tải và xác minh FreeKill, Utility, Hegemony trước khi đăng nhập.</p></section>}
      {snapshot.phase === 'login' && <LoginScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'lobby' && <LobbyScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'room' && <WaitingRoomScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'playing' && <GameBoardScreen busy={busy} leave={() => run(() => adapter.leaveRoom())} />}
      {snapshot.pendingRequest?.command === 'AskForSkillInvoke' && <SkillInvokePanel adapter={adapter} run={run} busy={busy} request={snapshot.pendingRequest} prompt={snapshot.skillInvoke} />}
      {snapshot.pendingRequest?.command === 'CustomDialog' && snapshot.initialGeneral &&
        <InitialGeneralPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`} adapter={adapter} run={run} busy={busy}
          request={snapshot.pendingRequest} prompt={snapshot.initialGeneral} />}
      {snapshot.pendingRequest && snapshot.pendingRequest.command !== 'AskForSkillInvoke' &&
        !(snapshot.pendingRequest.command === 'CustomDialog' && snapshot.initialGeneral) &&
        <div className="notice error-notice" role="alert">Máy chủ đang chờ phản hồi: {snapshot.pendingRequest.command}. Bộ điều khiển gameplay chưa hỗ trợ yêu cầu này.</div>}
      {snapshot.connection.kind === 'online' && <footer className="footer"><span>{snapshot.manifest?.fileCount ?? 0} tệp đã xác minh</span><button className="button ghost" onClick={() => { adapter.disconnect(); useGameStore.getState().update({ phase: 'login', connection: { kind: 'closed', reason: 'Đã ngắt kết nối' }, rooms: [], players: [], ownId: null, pendingRequest: null, skillInvoke: null, initialGeneral: null, board: emptyBoard(), progress: '', error: null }); }}>Ngắt kết nối</button></footer>}
    </main>
  );
}
