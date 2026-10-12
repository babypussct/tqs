import type { GameResult } from './store/gameStore';

export default function GameResultPanel({ result, busy, leave }: {
  result: GameResult;
  busy: boolean;
  leave: () => void;
}) {
  const title = { win: 'Bạn đã thắng!', loss: 'Bạn đã thua', draw: 'Ván đấu hòa', unknown: 'Ván đấu đã kết thúc' }[result.outcome];
  return <section className="panel" aria-labelledby="result-title" role="status">
    <span className="section-label">Kết quả trận đấu</span>
    <h2 id="result-title">{title}</h2>
    {result.winners.length > 0 && <p>Người thắng: {result.winners.map((p) => p.name).join(', ')}</p>}
    <p className="muted">Bạn có thể chơi ván mới trong phòng này hoặc trở về sảnh.</p>
    <button className="button secondary" disabled={busy} onClick={leave}>Về sảnh</button>
  </section>;
}
