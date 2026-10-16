import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { localizedGameLog, useDisplayText } from './engine/displayText';
import type { BoardMoment } from './store/boardState';
import { useGameStore, type RoomPlayer } from './store/gameStore';
import { GameplayControls, GameplaySkillDock, type GameplayDispatch, type GameplayDirect } from './GameplayControls';
import { GAMEPLAY_REQUESTS } from './store/gameplayState';
import PlayerPhotoPanel from './PlayerPhotoPanel';
import { IdleHandCard, ResolvingCardView } from './HandCardItem';
import FakeSkillDock from './FakeSkillDock';
import RegularSkillDock from './RegularSkillDock';
import { ToolbarBotIcon, ToolbarExitIcon } from './EquipIcons';
import type { RegularSkill } from './store/gameStore';
import {
  deriveSeatViewModels,
  getDeterministicSeatPosition,
  getOpponentPosition,
} from './store/seatLayout';

function useIsMobile(query = '(max-width: 640px)'): boolean {
  const [isMobile, setIsMobile] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false
  );
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const mql = window.matchMedia(query);
    const onChange = () => setIsMobile(mql.matches);
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [query]);
  return isMobile;
}

export { getDeterministicSeatPosition, getOpponentPosition };

function momentText(moment: BoardMoment, players: Map<number, RoomPlayer>): string {
  if (moment.kind === 'log') return localizedGameLog(moment.text);
  const player = players.get(moment.playerId);
  const name = player?.name || (moment.playerId < 0 ? 'Máy' : `Người chơi ${moment.playerId}`);
  if (moment.kind === 'chain') return `${name} ${moment.chained ? 'bị xích' : 'đã tháo xích'}`;
  const difference = moment.after - moment.before;
  return `${name} ${difference > 0 ? `hồi ${difference}` : `mất ${-difference}`} HP (${moment.before} → ${moment.after})`;
}

export default function GameBoardScreen({ leave, busy, dispatch, direct, toggleTrust, prelightSkill, regularSkills = [] }: {
  leave: () => void; busy: boolean; dispatch: GameplayDispatch; direct: GameplayDirect;
  toggleTrust?: () => void; prelightSkill: (skillName: string, prelight: boolean) => void;
  regularSkills?: RegularSkill[];
}) {
  const { players, board, ownId, roomName, gameplay, pendingRequest, fakeSkills } = useGameStore((s) => s);
  const text = useDisplayText();
  const isMobile = useIsMobile();
  const [showLogs, setShowLogs] = useState(() =>
    typeof window === 'undefined' || !window.matchMedia('(max-width: 899px)').matches
  );
  const [followLogs, setFollowLogs] = useState(true);
  const logList = useRef<HTMLOListElement>(null);
  const userScrollUntil = useRef(0);
  const lastMomentId = board.moments.at(-1)?.id;
  const latestMoment = board.moments.at(-1);
  const seatProfile = Math.min(10, Math.max(2, board.seats.length || 2));
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
  const byId = new Map(players.map((p) => [p.id, p]));
  const self = ownId == null ? null : byId.get(ownId);
  const trusting = self?.netState === 'trust';
  const gameplayActive = !trusting && pendingRequest !== null && GAMEPLAY_REQUESTS.has(pendingRequest.command);
  const requestExpired = pendingRequest?.expiresAt != null && Date.now() >= pendingRequest.expiresAt;
  const targetFor = (id: number) => gameplayActive ? gameplay.items.Photo[String(id)] : undefined;
  const chooseTarget = (id: number) => {
    const item = targetFor(id);
    if (item) dispatch('Photo', item.id, 'click', { selected: !item.selected });
  };

  const { selfSeat, opponentSeats } = deriveSeatViewModels({
    boardSeats: board.seats,
    playerIds: players.map((p) => p.id),
    ownId,
    boardPlayers: board.player,
    gameplayActive,
    targetItems: gameplay.items.Photo,
    isMobile,
  });

  return (
    <section className="game-board sg-game-board" aria-labelledby="board-title">
      <header className="board-toolbar">
        <div className="board-toolbar-title">
          <span className="section-label">04 / Bàn chơi Quốc Chiến</span>
          <h2 id="board-title">{roomName || 'Trận đấu'}</h2>
        </div>
        <div className="inline-controls">
          {toggleTrust && <button className="button secondary sg-toolbar-action" type="button" disabled={busy} onClick={toggleTrust}
            aria-label={trusting ? 'Tự chơi lại' : 'BOT chơi hộ'} title={trusting ? 'Tự chơi lại' : 'BOT chơi hộ'}
            aria-pressed={trusting}>
            <span className="sg-toolbar-action-icon"><ToolbarBotIcon /></span>
            <span className="sg-toolbar-action-label">{trusting ? 'Tự chơi lại' : 'BOT chơi hộ'}</span>
          </button>}
          <button className="button secondary sg-toolbar-action" type="button" disabled={busy} onClick={leave}
            aria-label="Rời trận" title="Rời trận">
            <span className="sg-toolbar-action-icon"><ToolbarExitIcon /></span>
            <span className="sg-toolbar-action-label">Rời trận</span>
          </button>
        </div>
      </header>
      {trusting && <p className="notice" role="status">Máy chủ đã bật BOT chơi hộ. Giữ trang mở để duy trì kết nối; bấm Tự chơi lại khi quay lại.</p>}
      <div className="board-moments board-ticker" aria-label="Diễn biến mới nhất" aria-live="polite">
        <strong>Diễn biến mới nhất</strong>
        {latestMoment ? (
          <p className={`board-moment moment-${latestMoment.kind}`} title={momentText(latestMoment, byId)}>
            {momentText(latestMoment, byId)}
          </p>
        ) : (
          <p className="board-moment">Đang chờ diễn biến từ máy chủ.</p>
        )}
        <button
          type="button"
          className="sg-ticker-log-toggle"
          aria-controls="board-log-panel"
          aria-expanded={showLogs}
          aria-label={showLogs ? 'Ẩn lịch sử' : 'Lịch sử'}
          title={showLogs ? 'Thu gọn nhật ký trận đấu' : 'Mở nhật ký trận đấu'}
          onClick={() => setShowLogs((open) => !open)}
        >
          <span aria-hidden="true">{showLogs ? '⌃' : '☷'}</span>
          <span className="sg-ticker-log-count">{board.logs.length}</span>
        </button>
      </div>
      <div className={`board-layout ${showLogs ? 'has-logs-open' : 'logs-collapsed'}`}>
        <section id="board-log-panel" className="board-log-panel sg-board-log-panel" aria-label="Nhật ký trận đấu">
          <div className="board-log-heading">
            <strong>Nhật ký trận đấu ({board.logs.length})</strong>
            <button type="button" className="button small-button secondary" aria-expanded={showLogs}
              aria-label={showLogs ? 'Thu gọn' : 'Xem nhật ký'}
              title={showLogs ? 'Thu gọn nhật ký trận đấu' : 'Mở nhật ký trận đấu'}
              onClick={() => setShowLogs(!showLogs)}>{showLogs ? 'Thu gọn' : 'Mở'}</button>
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
        <div className="board-main sg-board-main">
      <div className="board-table sg-board-table">
        <div className="board-opponents" aria-label="Các ghế khác">
          {opponentSeats.map((seat) => {
            const player = byId.get(seat.playerId);
            return player && <PlayerPhotoPanel key={seat.playerId} player={player} game={board.player[seat.playerId]}
              seat={seat.serverSeatNumber} self={false} active={seat.isActive} target={targetFor(seat.playerId)}
              busy={busy || requestExpired} onTarget={() => chooseTarget(seat.playerId)}
              style={seat.positionStyle} />;
          })}
        </div>
        <div className={`board-center board-center-seats-${seatProfile}`} aria-label="Khu vực bàn chơi">
          <div className="native-table-center" aria-label="Tâm bàn chơi">
            {/* Chồng bài rút */}
            <div className="native-deck-slot draw-pile" title="Chồng bài rút">
              <span className="native-deck-badge">{board.drawPileCount ?? 100}</span>
              <span className="native-deck-label">Rút</span>
            </div>

            {/* Vùng bài đang giải quyết hoặc watermark Quốc Chiến */}
            <div className="native-table-pile" id="nativeProcessingArea">
              {board.processingCards && board.processingCards.length > 0 ? (
                board.processingCards.map((c, i) => (
                  <ResolvingCardView key={i} card={c} />
                ))
              ) : null}
              <span
                className={`board-center-symbol${board.processingCards && board.processingCards.length > 0 ? ' sg-visually-hidden' : ''}`}
                aria-hidden="true"
              >
                Quốc Chiến
              </span>
            </div>

            {/* Chồng bài bỏ */}
            <div className="native-deck-slot discard-pile" title="Chồng bài bỏ">
              <span className="native-deck-badge">{board.discardPileCount ?? 0}</span>
              <span className="native-deck-label">Bỏ</span>
            </div>
          </div>

          <p className="board-center-seat-count">{board.seats.length ? `${board.seats.length} ghế đã xếp` : 'Đang chờ xếp ghế từ máy chủ'}</p>
          <div className="board-banners">
            {Object.entries(board.banners).filter(([, v]) => v !== 0 && v !== false && v !== '').map(([key, value]) =>
              <span className="board-mark" key={key}>{text(key)}: {typeof value === 'string' ? text(value) : String(value)}</span>)}
          </div>
        </div>
      </div>
      <div className="board-local-dashboard" aria-label="Bảng điều khiển người chơi">
        <div className="board-local-utility-row" aria-label="Thông tin và kỹ năng của bạn">
          {self && <div className="board-local-seat"><PlayerPhotoPanel player={self} game={board.player[self.id]} self
            seat={selfSeat?.serverSeatNumber ?? 0} active={selfSeat?.isActive ?? false} target={targetFor(self.id)}
            busy={busy || requestExpired} onTarget={() => chooseTarget(self.id)} compact={isMobile} /></div>}
          <div className="board-local-skill-rail" aria-label="Kỹ năng của bạn">
            {!trusting && <FakeSkillDock skills={fakeSkills} busy={busy} onToggle={prelightSkill}
              floating={pendingRequest?.command === 'AskForSkillInvoke'} />}
            {gameplayActive && <GameplaySkillDock scene={gameplay} request={pendingRequest!}
              regularSkills={regularSkills} busy={busy || requestExpired} dispatch={dispatch} />}
            {!gameplayActive && <RegularSkillDock skills={regularSkills} />}
          </div>
        </div>
        {gameplayActive && <GameplayControls key={`${pendingRequest.requestId}-${pendingRequest.receivedAt}`}
          scene={gameplay} request={pendingRequest} regularSkills={regularSkills}
          dispatch={dispatch} direct={direct} busy={busy} toggleTrust={toggleTrust} trusting={trusting} />}
        {!gameplayActive && (
          <div className="board-local-idle-area">
            <div className="sg-dashboard-left-tools" aria-label="Công cụ ngoài lượt">
              {toggleTrust && (
                <button
                  type="button"
                  className={`button small-button secondary sg-tool-btn${trusting ? ' active' : ''}`}
                  onClick={toggleTrust}
                  title={trusting ? 'Hủy BOT chơi hộ' : 'Bật BOT chơi hộ'}
                >
                  {trusting ? 'Hủy ủy thác' : 'Ủy thác'}
                </button>
              )}
            </div>
            {board.selfHandCards && board.selfHandCards.length > 0 && (
              <div className="gameplay-hand sg-hand-fan sg-hand-idle gameplay-options" aria-label="Bài trên tay (ngoài lượt)">
                {board.selfHandCards.map((card, index) => (
                  <IdleHandCard
                    key={card.id ?? index}
                    card={card}
                    index={index}
                    totalCards={board.selfHandCards.length}
                  />
                ))}
              </div>
            )}
            <div className="board-status" role="status">
              Đang chờ máy chủ và Lua xử lý giai đoạn tiếp theo.
            </div>
          </div>
        )}
      </div>
        </div>
      </div>
    </section>
  );
}
