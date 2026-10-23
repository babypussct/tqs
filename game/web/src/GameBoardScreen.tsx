import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
import { localizedGameLog, useDisplayText } from './engine/displayText';
import type { BoardEquipment } from './store/boardState';
import { useGameStore } from './store/gameStore';
import { GameplayControls, GameplaySkillDock, type GameplayDispatch, type GameplayDirect } from './GameplayControls';
import { GAMEPLAY_REQUESTS } from './store/gameplayState';
import PlayerPhotoPanel from './PlayerPhotoPanel';
import { IdleHandCard, PublicPileCardPreview, ResolvingCardView } from './HandCardItem';
import FakeSkillDock from './FakeSkillDock';
import RegularSkillDock from './RegularSkillDock';
import { ToolbarBotIcon, ToolbarExitIcon } from './EquipIcons';
import type { RegularSkill } from './store/gameStore';
import {
  deriveSeatViewModels,
  getDeterministicSeatPosition,
  getOpponentPosition,
} from './store/seatLayout';
import TargetingOverlay from './TargetingOverlay';
import CardVfxOverlay from './CardVfxOverlay';
import BattleMusicControl from './BattleMusicControl';
import { useCardVfx, type CardAssetHint } from './store/cardVfxState';

function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false
  );
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const mql = window.matchMedia(query);
    const onChange = () => setMatches(mql.matches);
    mql.addEventListener('change', onChange);
    // A viewport can change between the render that initialized state and
    // this effect's subscription (notably during responsive navigation).
    // Read the current value once so we never strand desktop-only content.
    onChange();
    return () => mql.removeEventListener('change', onChange);
  }, [query]);
  return matches;
}

export { getDeterministicSeatPosition, getOpponentPosition };

export default function GameBoardScreen({ leave, busy, dispatch, direct, toggleTrust, prelightSkill, regularSkills = [], getGeneralSkills }: {
  leave: () => void; busy: boolean; dispatch: GameplayDispatch; direct: GameplayDirect;
  toggleTrust?: () => void; prelightSkill: (skillName: string, prelight: boolean) => void;
  regularSkills?: RegularSkill[]; getGeneralSkills?: (name: string) => string[];
}) {
  const { players, board, ownId, roomName, gameplay, pendingRequest, fakeSkills, nativeVfxEvents } = useGameStore((s) => s);
  const text = useDisplayText();
  const isMobilePortrait = useMediaQuery('(max-width: 640px) and (orientation: portrait)');
  const isMobileLandscape = useMediaQuery('(orientation: landscape) and (max-height: 520px)');
  const isCompactWidth = useMediaQuery('(max-width: 640px)');
  const isPortrait = useMediaQuery('(orientation: portrait)');
  const isMobile = isMobilePortrait || isMobileLandscape || isCompactWidth;
  const isDesktopEquipment = useMediaQuery('(min-width: 900px) and (min-height: 521px)');
  const [desktopEquipmentHost, setDesktopEquipmentHost] = useState<HTMLDivElement | null>(null);
  const [showLogs, setShowLogs] = useState(() => {
    if (typeof window === 'undefined') return true;
    if (window.matchMedia('(orientation: landscape) and (max-height: 520px)').matches) return false;
    return !window.matchMedia('(max-width: 899px)').matches;
  });
  const [followLogs, setFollowLogs] = useState(true);
  const [temporaryTableCards, setTemporaryTableCards] = useState<
    { eventKey: string; index: number; card: BoardEquipment; kind: 'virtual' | 'discard' }[]
  >([]);
  const shownTableRevealKeys = useRef(new Set<string>());
  const tableCardsPendingVanish = useRef(new Set<string>());
  // TablePile.qml's triggeredOnStart timer immediately enters its first
  // 1500ms phase, then alternates capture / mark / vanish at each tick.
  const tableVanishPhase = useRef(true);
  const lastTableReveal = useRef(0);
  const lastDiscardReveal = useRef(0);
  const cardAssetHints = useMemo<Readonly<Record<string, CardAssetHint>>>(() => {
    const hints: Record<string, CardAssetHint | null> = {};
    const add = (card: { name?: string; extension?: string; picName?: string }) => {
      if (!card.name || (!card.extension && !card.picName)) return;
      const next: CardAssetHint = {
        extension: card.extension,
        picName: card.picName,
      };
      const current = hints[card.name];
      if (current === null) return;
      if (current && ((current.extension && next.extension && current.extension !== next.extension) ||
        (current.picName && next.picName && current.picName !== next.picName))) {
        hints[card.name] = null;
        return;
      }
      hints[card.name] = { ...current, ...next };
    };
    board.processingCards.forEach(add);
    board.virtualCards.forEach(add);
    if (board.topDiscardCard) add(board.topDiscardCard);
    board.selfHandCards.forEach(add);
    Object.values(board.player).forEach((player) => {
      player.equipment.forEach(add);
      player.delayedTricks.forEach(add);
    });
    return Object.fromEntries(Object.entries(hints).filter((entry): entry is [string, CardAssetHint] => entry[1] !== null));
  }, [board.processingCards, board.virtualCards, board.topDiscardCard, board.selfHandCards, board.player]);
  useEffect(() => {
    const interval = window.setInterval(() => {
      if (tableVanishPhase.current) {
        // This is TablePile's toVanish branch: retire the previous cohort,
        // then stage every newly shown card for the next full two-phase cycle.
        const retiring = tableCardsPendingVanish.current;
        if (retiring.size) {
          setTemporaryTableCards((old) => old.filter((item) => !retiring.has(item.eventKey)));
          for (const key of retiring) shownTableRevealKeys.current.delete(key);
        }
        tableCardsPendingVanish.current = new Set(shownTableRevealKeys.current);
      }
      tableVanishPhase.current = !tableVanishPhase.current;
    }, 1500);
    return () => window.clearInterval(interval);
  }, []);
  useEffect(() => {
    if (!board.virtualSequence && !board.discardSequence) {
      shownTableRevealKeys.current.clear();
      tableCardsPendingVanish.current.clear();
      tableVanishPhase.current = true;
      lastTableReveal.current = 0;
      lastDiscardReveal.current = 0;
      setTemporaryTableCards([]);
      return;
    }
    // TablePile.qml keeps discarded and virtual cards for a repeating 1500ms
    // two-phase vanish timer. Process *all* events since the previous render:
    // React may batch several native callbacks into a single commit.
    const incoming = [
      ...board.virtualReveals.filter((item) => item.sequence > lastTableReveal.current)
        .map((item) => ({ ...item, eventKey: `virtual-${item.sequence}`, kind: 'virtual' as const })),
      ...board.discardReveals.filter((item) => item.sequence > lastDiscardReveal.current)
        .map((item) => ({ ...item, eventKey: `discard-${item.sequence}`, kind: 'discard' as const })),
    ];
    lastTableReveal.current = board.virtualSequence;
    lastDiscardReveal.current = board.discardSequence;
    if (incoming.length === 0) return;
    for (const { eventKey } of incoming) shownTableRevealKeys.current.add(eventKey);
    setTemporaryTableCards((old) => [...old, ...incoming.flatMap(({ eventKey, kind, cards }) =>
      cards.map((card, index) => ({ eventKey, kind, index, card })))].slice(-200));
  }, [board.virtualSequence, board.virtualReveals, board.discardSequence, board.discardReveals]);
  const logList = useRef<HTMLOListElement>(null);
  const userScrollUntil = useRef(0);
  const seatProfile = Math.min(10, Math.max(2, board.seats.length || 2));
  useLayoutEffect(() => {
    if (showLogs && followLogs && logList.current) logList.current.scrollTop = logList.current.scrollHeight;
  }, [showLogs, followLogs, board.logs.length]);
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

  const boardMainRef = useRef<HTMLDivElement>(null);
  const {
    flyingCards,
    impacts,
    avatarReactions,
    activeTargetIndicators,
    onFlyingCardDone,
    onImpactDone,
    processGameLogs,
    processNativeEvents,
  } = useCardVfx();

  useEffect(() => {
    processGameLogs(board.logs, cardAssetHints);
  }, [board.logs, cardAssetHints, processGameLogs]);

  useEffect(() => {
    processNativeEvents(nativeVfxEvents);
  }, [nativeVfxEvents, processNativeEvents]);

  const { selfSeat, opponentSeats } = deriveSeatViewModels({
    boardSeats: board.seats,
    playerIds: players.map((p) => p.id),
    ownId,
    boardPlayers: board.player,
    gameplayActive,
    targetItems: gameplay.items.Photo,
    isMobile,
    isPortrait,
  });

  return (
    <section className="game-board sg-game-board" aria-labelledby="board-title">
      <header className="board-toolbar">
        <div className="board-toolbar-title">
          <h2 id="board-title">{roomName || 'Trận đấu'}</h2>
        </div>
        <div className="inline-controls">
          <BattleMusicControl />
          <button type="button" className="button secondary sg-toolbar-action sg-toolbar-log-toggle"
            aria-controls="board-log-panel" aria-expanded={showLogs}
            aria-label={showLogs ? 'Ẩn lịch sử' : 'Lịch sử'}
            title={showLogs ? 'Thu gọn nhật ký trận đấu' : 'Mở nhật ký trận đấu'}
            onClick={() => setShowLogs((open) => !open)}>
            <span className="sg-toolbar-action-icon" aria-hidden="true">☷</span>
            <span className="sg-toolbar-action-label">Nhật ký</span>
          </button>
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
        <div className="board-main sg-board-main" ref={boardMainRef} style={{ position: 'relative' }}>
          {/* Lớp hiển thị đường mũi tên ngắm mục tiêu (toàn màn hình bàn chơi và bài tay) */}
          <TargetingOverlay
            boardContainerRef={boardMainRef}
            activeIndicators={activeTargetIndicators}
          />

          {/* Lớp hiệu ứng lá bài bay và va chạm chiến đấu */}
          <CardVfxOverlay
            boardContainerRef={boardMainRef}
            flyingCards={flyingCards}
            impacts={impacts}
            onFlyingCardDone={onFlyingCardDone}
            onImpactDone={onImpactDone}
          />

          <div className={`board-table sg-board-table board-table-seats-${seatProfile}`}>
        {!gameplayActive && <div className="board-status board-table-status" role="status">
          Đang cập nhật diễn biến ván đấu…
        </div>}

        <div className="board-opponents" aria-label="Các ghế khác">
          {opponentSeats.map((seat) => {
            const player = byId.get(seat.playerId);
            return player && <PlayerPhotoPanel key={seat.playerId} player={player} game={board.player[seat.playerId]}
              seat={seat.serverSeatNumber} self={false} active={seat.isActive} target={targetFor(seat.playerId)}
              getGeneralSkills={getGeneralSkills}
              busy={busy || requestExpired} onTarget={() => chooseTarget(seat.playerId)}
              avatarReaction={avatarReactions[seat.playerId]}
              isShaking={avatarReactions[seat.playerId] === 'hit-shake'}
              style={seat.positionStyle} />;
          })}
        </div>
        <div className={`board-center board-center-seats-${seatProfile}`} aria-label="Khu vực bàn chơi">
          <div className="native-table-center" aria-label="Tâm bàn chơi">
            {/* Chồng bài rút */}
            <div className="native-deck-slot draw-pile" title="Chồng bài rút">
              <span className="native-deck-badge">{board.drawPileCount ?? '–'}</span>
              <span className="native-deck-label">Rút</span>
            </div>

            {/* Vùng bài đang giải quyết hoặc watermark Quốc Chiến */}
            <div className="native-table-pile" id="nativeProcessingArea" role="region"
              aria-label={`Bài đang xử lý: ${board.processingCards.length} lá${temporaryTableCards.length ? `, ${temporaryTableCards.length} lá vừa bỏ hoặc đang lật xem` : ''}`}
              tabIndex={board.processingCards.length + temporaryTableCards.length > 2 ? 0 : -1}>
              {board.processingCards.map((c, i) => (
                <ResolvingCardView key={`processing-${i}`} card={c} />
              ))}
              {temporaryTableCards.map(({ card, eventKey, kind, index }) => (
                <ResolvingCardView key={`${eventKey}-${index}`} card={card} activity={kind === 'discard' ? 'discard' : 'reveal'} />
              ))}
              <span
                className={`board-center-symbol${board.processingCards.length + temporaryTableCards.length > 0 ? ' sg-visually-hidden' : ''}`}
                aria-hidden="true"
              >
                Quốc Chiến
              </span>
            </div>

            {/* Chồng bài bỏ */}
            <div className={`native-deck-slot discard-pile${board.topDiscardCard ? ' has-top-card' : ''}`} title="Chồng bài bỏ">
              <span className="native-deck-badge">{board.discardPileCount ?? '–'}</span>
              {board.topDiscardCard && <PublicPileCardPreview card={board.topDiscardCard} />}
              <span className="native-deck-label">Bỏ</span>
            </div>
          </div>

          <p className="board-center-seat-count">{board.seats.length ? `${board.seats.length} ghế đã xếp` : 'Đang chờ xếp ghế từ máy chủ'}</p>
          <div className="board-banners">
            {Object.entries(board.banners).filter(([, v]) => v !== 0 && v !== false && v !== '').map(([key, value]) =>
              <span className="board-mark" key={key}
                title={`${text(key)}: ${typeof value === 'string' ? text(value) : String(value)}`}>
                {text(key)}: {typeof value === 'string' ? text(value) : String(value)}
              </span>)}
          </div>
        </div>
      </div>
      <div className="board-local-dashboard" aria-label="Bảng điều khiển người chơi">
        <div className="board-local-utility-row" aria-label="Thông tin và kỹ năng của bạn">
          {self && <div className="board-local-seat"><PlayerPhotoPanel player={self} game={board.player[self.id]} self
            getGeneralSkills={getGeneralSkills}
            seat={selfSeat?.serverSeatNumber ?? 0} active={selfSeat?.isActive ?? false} target={targetFor(self.id)}
            busy={busy || requestExpired} onTarget={() => chooseTarget(self.id)} compact
            equipmentPortalTarget={isDesktopEquipment ? desktopEquipmentHost : null}
            avatarReaction={avatarReactions[self.id]}
            isShaking={avatarReactions[self.id] === 'hit-shake'} /></div>}
          {isDesktopEquipment && <div className="board-local-self-equipment" ref={setDesktopEquipmentHost} />}
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
            <div
              className={`gameplay-hand sg-hand-fan sg-hand-idle gameplay-options${board.selfHandCards.length > 4 ? ' sg-hand-overlap' : ''}`}
              aria-label={`Bài trên tay, ${board.selfHandCards.length} lá. Chạm vào một lá để xem chi tiết.`}
            >
              {board.selfHandCards.length > 0 ? board.selfHandCards.map((card, index) => (
                <IdleHandCard
                  key={card.id ?? index}
                  card={card}
                  index={index}
                  totalCards={board.selfHandCards.length}
                />
              )) : (
                <span className="sg-hand-empty">Không có lá bài trên tay</span>
              )}
            </div>
          </div>
        )}
      </div>
        </div>
      </div>
    </section>
  );
}
