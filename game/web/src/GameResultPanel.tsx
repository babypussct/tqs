import { useLayoutEffect, useRef, useState } from 'react';
import { localizedGameLog, useDisplayText } from './engine/displayText';
import type { GameResult } from './store/gameStore';
import { GeneralPortrait } from './GeneralChoiceCard';

export default function GameResultPanel({ result, busy, leave, onDismiss }: {
  result: GameResult;
  busy: boolean;
  leave: () => void;
  onDismiss?: () => void;
}) {
  const text = useDisplayText();
  const [showLogs, setShowLogs] = useState(true);
  const logList = useRef<HTMLOListElement>(null);
  useLayoutEffect(() => {
    if (showLogs && logList.current) logList.current.scrollTop = logList.current.scrollHeight;
  }, [result, showLogs]);
  const outcomeClass = result.outcome === 'win' ? 'is-win' : result.outcome === 'loss' ? 'is-loss' : 'is-draw';
  const title = { win: 'Bạn đã thắng!', loss: 'Bạn đã thua', draw: 'Ván đấu hòa', unknown: 'Ván đấu đã kết thúc' }[result.outcome];
  const winnerIds = new Set(result.winners.map((w) => w.id));

  return (
    <section className={`panel sg-game-result-panel ${outcomeClass}`} aria-labelledby="result-title" role="status">
      <div className="sg-result-header">
        <span className="section-label">Kết quả trận đấu</span>
        <h2 id="result-title">{title}</h2>
        {result.winners.length > 0 && (
          <p className="sg-result-winner-banner">
            Người thắng: {result.winners.map((p) => p.name).join(', ')}
          </p>
        )}
      </div>

      {result.summary && (
        <>
          {result.summary.players.length > 0 && (
            <div className="result-players sg-result-players-grid" aria-label="Trạng thái cuối trận">
              {result.summary.players.map((player) => {
                const isWinner = winnerIds.has(player.id);
                return (
                  <article className={`board-player sg-result-player-card${isWinner ? ' is-winner' : ''}`} key={player.id}>
                    <div className="sg-result-player-header">
                      <strong className="board-player-name">{player.name}</strong>
                      {isWinner && <span className="sg-winner-badge" aria-hidden="true">🏆</span>}
                    </div>
                    <div className="board-generals sg-result-generals-row">
                      <div className="sg-result-general-slot">
                        {player.general ? (
                          <>
                            <span aria-hidden="true"><GeneralPortrait name={player.general} label="" compact /></span>
                            <span>{text(player.general)}</span>
                          </>
                        ) : (
                          <span className="sg-result-general-hidden">Chủ tướng ẩn</span>
                        )}
                      </div>
                      <div className="sg-result-general-slot">
                        {player.deputyGeneral ? (
                          <>
                            <span aria-hidden="true"><GeneralPortrait name={player.deputyGeneral} label="" compact /></span>
                            <span>{text(player.deputyGeneral)}</span>
                          </>
                        ) : (
                          <span className="sg-result-general-hidden">Phó tướng ẩn</span>
                        )}
                      </div>
                    </div>
                    <div className="board-player-stats sg-result-player-stats">
                      <span>♥ {player.hp ?? '?'} / {player.maxHp ?? '?'}</span>
                      <span>{player.handcardNum ?? '?'} lá trên tay</span>
                    </div>
                  </article>
                );
              })}
            </div>
          )}

          {result.summary.logs.length > 0 && (
            <div className="board-log-panel sg-result-log-section">
              <div className="sg-result-log-header">
                <h3>Nhật ký cuối trận</h3>
                <button
                  type="button"
                  className="button secondary button-compact sg-result-log-toggle"
                  aria-expanded={showLogs}
                  onClick={() => setShowLogs((prev) => !prev)}
                >
                  {showLogs ? 'Thu gọn' : `Xem chi tiết (${result.summary.logs.length})`}
                </button>
              </div>
              {showLogs && (
                <ol className="board-logs sg-result-logs" ref={logList} aria-label="Nhật ký cuối trận">
                  {result.summary.logs.map((log, index) => (
                    <li key={index}>{localizedGameLog(log)}</li>
                  ))}
                </ol>
              )}
            </div>
          )}
        </>
      )}

      <p className="muted">Bạn có thể tiếp tục sẵn sàng cho ván mới trong phòng hoặc trở về sảnh.</p>
      <div className="sg-result-actions inline-controls">
        {onDismiss && (
          <button className="button primary" disabled={busy} onClick={onDismiss}>
            Ở lại phòng chờ
          </button>
        )}
        <button className="button secondary" disabled={busy} onClick={leave}>
          Về sảnh
        </button>
      </div>
    </section>
  );
}
