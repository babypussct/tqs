import { useLayoutEffect, useRef } from 'react';
import { localizedGameLog, useDisplayText } from './engine/displayText';
import type { GameResult } from './store/gameStore';

export default function GameResultPanel({ result, busy, leave }: {
  result: GameResult;
  busy: boolean;
  leave: () => void;
}) {
  const text = useDisplayText();
  const logList = useRef<HTMLOListElement>(null);
  useLayoutEffect(() => {
    if (logList.current) logList.current.scrollTop = logList.current.scrollHeight;
  }, [result]);
  const title = { win: 'Bạn đã thắng!', loss: 'Bạn đã thua', draw: 'Ván đấu hòa', unknown: 'Ván đấu đã kết thúc' }[result.outcome];
  return <section className="panel" aria-labelledby="result-title" role="status">
    <span className="section-label">Kết quả trận đấu</span>
    <h2 id="result-title">{title}</h2>
    {result.winners.length > 0 && <p>Người thắng: {result.winners.map((p) => p.name).join(', ')}</p>}
    {result.summary && <>
      {result.summary.players.length > 0 && <div className="result-players" aria-label="Trạng thái cuối trận">
        {result.summary.players.map((player) => <article className="board-player" key={player.id}>
          <strong className="board-player-name">{player.name}</strong>
          <div className="board-generals">
            <span>{player.general ? text(player.general) : 'Chủ tướng ẩn'}</span>
            <span>{player.deputyGeneral ? text(player.deputyGeneral) : 'Phó tướng ẩn'}</span>
          </div>
          <div className="board-player-stats">
            <span>♥ {player.hp ?? '?'} / {player.maxHp ?? '?'}</span>
            <span>{player.handcardNum ?? '?'} lá trên tay</span>
          </div>
        </article>)}
      </div>}
      {result.summary.logs.length > 0 && <div className="board-log-panel">
        <h3>Nhật ký cuối trận</h3>
        <ol className="board-logs" ref={logList} aria-label="Nhật ký cuối trận">
          {result.summary.logs.map((log, index) => <li key={index}>{localizedGameLog(log)}</li>)}
        </ol>
      </div>}
    </>}
    <p className="muted">Bạn có thể chơi ván mới trong phòng này hoặc trở về sảnh.</p>
    <button className="button secondary" disabled={busy} onClick={leave}>Về sảnh</button>
  </section>;
}
