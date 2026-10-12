import { useLayoutEffect, useRef, useState } from 'react';
import { localizedGameLog, useDisplayText } from './engine/displayText';
import { relativeSeatOrder, type BoardMoment, type BoardPlayer } from './store/boardState';
import { useGameStore, type RoomPlayer } from './store/gameStore';
import { GameplayControls, type GameplayDispatch, type GameplayDirect } from './GameplayControls';
import { GAMEPLAY_REQUESTS, type GameplayItem } from './store/gameplayState';

const phaseLabels: Record<string, string> = {
  '1': 'Bắt đầu lượt', '2': 'Chuẩn bị', '3': 'Phán định', '4': 'Rút bài',
  '5': 'Đánh bài', '6': 'Bỏ bài', '7': 'Kết thúc lượt', '8': 'Ngoài lượt', '9': 'Chuyển giai đoạn',
  RoundStart: 'Bắt đầu lượt', Start: 'Chuẩn bị', Judge: 'Phán định', Draw: 'Rút bài',
  Play: 'Đánh bài', Discard: 'Bỏ bài', Finish: 'Kết thúc lượt', NotActive: 'Ngoài lượt', PhaseNone: 'Chuyển giai đoạn',
};

function momentText(moment: BoardMoment, players: Map<number, RoomPlayer>): string {
  if (moment.kind === 'log') return localizedGameLog(moment.text);
  const player = players.get(moment.playerId);
  const name = player?.name || (moment.playerId < 0 ? 'Máy' : `Người chơi ${moment.playerId}`);
  if (moment.kind === 'chain') return `${name} ${moment.chained ? 'bị xích' : 'đã tháo xích'}`;
  const difference = moment.after - moment.before;
  return `${name} ${difference > 0 ? `hồi ${difference}` : `mất ${-difference}`} HP (${moment.before} → ${moment.after})`;
}

function PlayerPanel({ player, game, self, seat, target, busy, onTarget }: {
  player: RoomPlayer;
  game: BoardPlayer | undefined;
  self: boolean;
  seat: number;
  target?: GameplayItem;
  busy?: boolean;
  onTarget?: () => void;
}) {
  const text = useDisplayText();
  const phase = game?.phase;
  const active = phase !== null && phase !== undefined &&
    ![0, 8, 9, 'NotActive', 'PhaseNone'].includes(phase);
  const marks = Object.entries(game?.marks ?? {}).filter(([, v]) => v !== 0 && v !== false && v !== '');
  const main = game?.general || (self ? game?.selfGeneral : null);
  const deputy = game?.deputyGeneral || (self ? game?.selfDeputyGeneral : null);
  const kingdom = game?.visibleKingdom || game?.kingdom;
  return (
    <article className={`board-player ${self ? 'board-self' : ''} ${active ? 'board-active' : ''} ${game?.died ? 'board-dead' : ''}`}
      aria-label={`${player.name || `Người chơi ${player.id}`}${self ? ' (bạn)' : ''}`}>
      <div className="board-player-top">
        <span className="board-seat">Ghế {seat}</span>
        {self && <span className="you-tag">Bạn</span>}
        {active && <span className="turn-badge">Đang lượt</span>}
        {game?.died && <span className="dead-badge">Đã loại</span>}
        {!game?.died && game?.hp != null && game.hp <= 0 && <span className="dead-badge">Hấp hối</span>}
      </div>
      <strong className="board-player-name">{player.name || (player.id < 0 ? 'Máy' : `Người chơi ${player.id}`)}</strong>
      <div className="board-generals">
        <span title="Chủ tướng">{main ? text(main) : 'Chủ tướng ẩn'}{self && main && !game?.general && <small> · Chưa lật</small>}</span>
        <span title="Phó tướng">{deputy ? text(deputy) : 'Phó tướng ẩn'}{self && deputy && !game?.deputyGeneral && <small> · Chưa lật</small>}</span>
      </div>
      <div className="board-player-stats">
        <span>♥ {game?.hp ?? '?'} / {game?.maxHp ?? '?'}</span>
        {game?.shield != null && game.shield > 0 && <span>Giáp {game.shield}</span>}
        <span>{game?.handcardNum ?? '?'} lá trên tay</span>
      </div>
      <div className="board-player-meta">
        <span>Thế lực: {(self || game?.roleShown) && kingdom ? text(kingdom) : 'Chưa công khai'}</span>
        {phase != null && <span>Giai đoạn: {phaseLabels[String(phase)] ?? String(phase)}</span>}
        {game?.chained && <span className="board-mark">Đang bị xích</span>}
        {game?.faceup === false && <span className="board-mark">Úp mặt</span>}
      </div>
      {!!game?.equipment.length && <div className="board-marks" aria-label="Trang bị công khai">
        {game.equipment.map((card, index) => <span className="board-mark" key={index}>{text(card.name)} · {['', '♠', '♣', '♥', '♦'][card.suit]}{card.number || ''}</span>)}
      </div>}
      {marks.length > 0 && <div className="board-marks" aria-label="Dấu hiệu công khai">
        {marks.map(([name, value]) => <span key={name} className="board-mark">{text(name)}: {typeof value === 'string' ? text(value) : String(value)}</span>)}
      </div>}
      {target && <button className={`gameplay-target ${target.selected ? 'selected' : ''}`} type="button"
        aria-pressed={target.selected} disabled={busy || !target.enabled} onClick={onTarget}>
        {target.selected ? 'Đã chọn mục tiêu' : 'Chọn mục tiêu'}
      </button>}
    </article>
  );
}

export default function GameBoardScreen({ leave, busy, dispatch, direct, toggleTrust }: {
  leave: () => void; busy: boolean; dispatch: GameplayDispatch; direct: GameplayDirect; toggleTrust?: () => void;
}) {
  const { players, board, ownId, roomName, gameplay, pendingRequest } = useGameStore((s) => s);
  const text = useDisplayText();
  const [showLogs, setShowLogs] = useState(true);
  const [followLogs, setFollowLogs] = useState(true);
  const logList = useRef<HTMLOListElement>(null);
  const userScrollUntil = useRef(0);
  const lastMomentId = board.moments.at(-1)?.id;
  useLayoutEffect(() => {
    if (showLogs && followLogs && logList.current) logList.current.scrollTop = logList.current.scrollHeight;
  }, [showLogs, followLogs, lastMomentId]);
  useLayoutEffect(() => {
    if (!showLogs || !followLogs || !logList.current) return;
    const element = logList.current;
    const follow = () => { element.scrollTop = element.scrollHeight; };
    let frame = 0;
    const followAfterLayout = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(follow);
    };
    const observer = new ResizeObserver(followAfterLayout);
    observer.observe(element);
    // Width changes can reflow every log line without changing this fixed-height list.
    // Schedule after the browser has applied the new layout, including orientation changes.
    window.addEventListener('resize', followAfterLayout);
    followAfterLayout();
    return () => {
      observer.disconnect();
      cancelAnimationFrame(frame);
      window.removeEventListener('resize', followAfterLayout);
    };
  }, [showLogs, followLogs]);
  const markUserScroll = () => { userScrollUntil.current = performance.now() + 1500; };
  const seatOrder = relativeSeatOrder(board.seats, players.map((p) => p.id), ownId);
  const byId = new Map(players.map((p) => [p.id, p]));
  const self = ownId == null ? null : byId.get(ownId);
  const trusting = self?.netState === 'trust';
  const others = seatOrder.filter((id) => id !== ownId);
  const seatNumbers = new Map(seatOrder.map((id, index) => [id, index + 1]));
  const gameplayActive = !trusting && pendingRequest !== null && GAMEPLAY_REQUESTS.has(pendingRequest.command);
  const requestExpired = pendingRequest?.expiresAt != null && Date.now() >= pendingRequest.expiresAt;
  const targetFor = (id: number) => gameplayActive ? gameplay.items.Photo[String(id)] : undefined;
  const chooseTarget = (id: number) => {
    const item = targetFor(id);
    if (item) dispatch('Photo', item.id, 'click', { selected: !item.selected });
  };

  return (
    <section className="game-board" aria-labelledby="board-title">
      <header className="board-toolbar">
        <div><span className="section-label">04 / Bàn chơi Quốc Chiến</span><h2 id="board-title">{roomName || 'Trận đấu'}</h2></div>
        <div className="inline-controls">
          {toggleTrust && <button className="button secondary" type="button" disabled={busy} onClick={toggleTrust}
            aria-pressed={trusting}>{trusting ? 'Tự chơi lại' : 'BOT chơi hộ'}</button>}
          <button className="button secondary" type="button" disabled={busy} onClick={leave}>Rời trận</button>
        </div>
      </header>
      {trusting && <p className="notice" role="status">Máy chủ đã bật BOT chơi hộ. Giữ trang mở để duy trì kết nối; bấm Tự chơi lại khi quay lại.</p>}
      <div className="board-layout">
        <section className="board-log-panel" aria-label="Nhật ký trận đấu">
          <div className="board-log-heading">
            <strong>Nhật ký trận đấu ({board.logs.length})</strong>
            <button type="button" className="button small-button secondary" aria-expanded={showLogs}
              onClick={() => setShowLogs(!showLogs)}>{showLogs ? 'Thu gọn' : 'Xem nhật ký'}</button>
          </div>
          {showLogs && <>
            <ol className="board-logs" ref={logList} aria-label="Các diễn biến trận đấu"
              onWheel={(event) => { if (event.deltaY < 0) markUserScroll(); }}
              onTouchMove={markUserScroll}
              onPointerDown={(event) => {
                const node = event.currentTarget;
                // Clicking or selecting text in the log is not a scrollbar drag.
                if (event.pointerType === 'mouse' && node.scrollHeight > node.clientHeight &&
                    event.clientX >= node.getBoundingClientRect().right - 18) markUserScroll();
              }}
              onKeyDown={(event) => {
                if (event.key === 'Home' || event.key === 'End') {
                  event.preventDefault();
                  userScrollUntil.current = 0;
                  const toLatest = event.key === 'End';
                  setFollowLogs(toLatest);
                  event.currentTarget.scrollTop = toLatest ? event.currentTarget.scrollHeight : 0;
                } else if (['ArrowUp', 'ArrowDown', 'PageUp', 'PageDown', ' '].includes(event.key)) {
                  markUserScroll();
                }
              }}
              tabIndex={0}
              onScroll={(event) => {
                const node = event.currentTarget;
                if (node.scrollHeight - node.scrollTop - node.clientHeight < 28) {
                  userScrollUntil.current = 0;
                  setFollowLogs(true);
                }
                else if (performance.now() <= userScrollUntil.current) setFollowLogs(false);
              }}>
              {board.logs.length ? board.logs.map((log, index) => <li key={index}>{localizedGameLog(log)}</li>) :
                <li>Chưa có thông báo từ trận đấu.</li>}
            </ol>
            {!followLogs && <button className="button small-button secondary log-follow" type="button"
              onClick={() => {
                userScrollUntil.current = 0;
                setFollowLogs(true);
                if (logList.current) logList.current.scrollTop = logList.current.scrollHeight;
              }}>
              Theo dõi dòng mới
            </button>}
          </>}
        </section>
        <div className="board-main">
      <div className="board-table">
        <div className="board-opponents" aria-label="Các ghế khác">
          {others.map((id) => {
            const player = byId.get(id);
            return player && <PlayerPanel key={id} player={player} game={board.player[id]}
              seat={seatNumbers.get(id) ?? 0} self={false} target={targetFor(id)}
              busy={busy || requestExpired} onTarget={() => chooseTarget(id)} />;
          })}
        </div>
        <div className="board-center" aria-label="Khu vực bàn chơi">
          <span className="board-center-symbol" aria-hidden="true">Quốc Chiến</span>
          <p>{board.seats.length ? `${board.seats.length} ghế đã xếp` : 'Đang chờ xếp ghế từ máy chủ'}</p>
          <div className="board-moments" aria-label="Diễn biến mới nhất" aria-live="off">
            <strong>Diễn biến mới nhất</strong>
            {board.moments.length ? board.moments.slice(-3).reverse().map((moment) =>
              <p className={`board-moment moment-${moment.kind}`} key={moment.id}>{momentText(moment, byId)}</p>) :
              <p className="board-moment">Đang chờ diễn biến từ máy chủ.</p>}
          </div>
          <div className="board-banners">
            {Object.entries(board.banners).filter(([, v]) => v !== 0 && v !== false && v !== '').map(([key, value]) =>
              <span className="board-mark" key={key}>{text(key)}: {typeof value === 'string' ? text(value) : String(value)}</span>)}
          </div>
        </div>
        {self && <div className="board-local-seat"><PlayerPanel player={self} game={board.player[self.id]} self
          seat={seatNumbers.get(self.id) ?? 0} target={targetFor(self.id)} busy={busy || requestExpired}
          onTarget={() => chooseTarget(self.id)} /></div>}
      </div>
      {gameplayActive && <GameplayControls key={`${pendingRequest.requestId}-${pendingRequest.receivedAt}`}
        scene={gameplay} request={pendingRequest} dispatch={dispatch} direct={direct} busy={busy} />}
      {!gameplayActive && <div className="board-status" role="status">
        Đang chờ máy chủ và Lua xử lý giai đoạn tiếp theo.
      </div>}
        </div>
      </div>
    </section>
  );
}
