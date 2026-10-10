import { useState } from 'react';
import { relativeSeatOrder, type BoardPlayer } from './store/boardState';
import { useGameStore, type RoomPlayer } from './store/gameStore';

function visibleLog(text: string): string {
  // FreeKill formats translated log arguments with <font> and <b> tags.
  // Render only text through React; never inject upstream HTML into the DOM.
  return text.replace(/<\/?(?:font|b)\b[^>]*>/gi, '')
    .replace(/&(?:lt|gt|amp|quot|#39);/g, (entity) => ({
      '&lt;': '<', '&gt;': '>', '&amp;': '&', '&quot;': '"', '&#39;': "'",
    })[entity] ?? entity);
}

function PlayerPanel({ player, game, self, seat }: {
  player: RoomPlayer;
  game: BoardPlayer | undefined;
  self: boolean;
  seat: number;
}) {
  const active = game?.phase !== null && game?.phase !== undefined &&
    game.phase !== 'NotActive' && game.phase !== 0;
  const marks = Object.entries(game?.marks ?? {}).filter(([, v]) => v !== 0 && v !== false && v !== '');
  return (
    <article className={`board-player ${self ? 'board-self' : ''} ${active ? 'board-active' : ''} ${game?.died ? 'board-dead' : ''}`}
      aria-label={`${player.name || `Người chơi ${player.id}`}${self ? ' (bạn)' : ''}`}>
      <div className="board-player-top">
        <span className="board-seat">Ghế {seat}</span>
        {self && <span className="you-tag">Bạn</span>}
        {active && <span className="turn-badge">Đang lượt</span>}
        {game?.died && <span className="dead-badge">Đã loại</span>}
      </div>
      <strong className="board-player-name">{player.name || (player.id < 0 ? 'Máy' : `Người chơi ${player.id}`)}</strong>
      <div className="board-generals">
        <span title="Chủ tướng">{(self || game?.roleShown) && game?.general ? game.general : 'Chủ tướng ẩn'}</span>
        <span title="Phó tướng">{(self || game?.roleShown) && game?.deputyGeneral ? game.deputyGeneral : 'Phó tướng ẩn'}</span>
      </div>
      <div className="board-player-stats">
        <span>♥ {game?.hp ?? '?'} / {game?.maxHp ?? '?'}</span>
        {game?.shield != null && game.shield > 0 && <span>Giáp {game.shield}</span>}
        <span>{game?.handcardNum ?? '?'} lá trên tay</span>
      </div>
      <div className="board-player-meta">
        <span>Thế lực: {(self || game?.roleShown) && game?.kingdom ? game.kingdom : 'Chưa công khai'}</span>
        {game?.phase != null && <span>Giai đoạn: {String(game.phase)}</span>}
      </div>
      {marks.length > 0 && <div className="board-marks" aria-label="Dấu hiệu công khai">
        {marks.map(([name, value]) => <span key={name} className="board-mark">{name}: {String(value)}</span>)}
      </div>}
    </article>
  );
}

export default function GameBoardScreen({ leave, busy }: { leave: () => void; busy: boolean }) {
  const { players, board, ownId, roomName } = useGameStore((s) => s);
  const [showLogs, setShowLogs] = useState(false);
  const seatOrder = relativeSeatOrder(board.seats, players.map((p) => p.id), ownId);
  const byId = new Map(players.map((p) => [p.id, p]));
  const self = ownId == null ? null : byId.get(ownId);
  const others = seatOrder.filter((id) => id !== ownId);
  const seatNumbers = new Map(seatOrder.map((id, index) => [id, index + 1]));

  return (
    <section className="game-board" aria-labelledby="board-title">
      <header className="board-toolbar">
        <div><span className="section-label">04 / Bàn chơi Quốc Chiến</span><h2 id="board-title">{roomName || 'Trận đấu'}</h2></div>
        <button className="button secondary" type="button" disabled={busy} onClick={leave}>Rời trận</button>
      </header>
      <div className="board-table">
        <div className="board-opponents" aria-label="Các ghế khác">
          {others.map((id) => {
            const player = byId.get(id);
            return player && <PlayerPanel key={id} player={player} game={board.player[id]}
              seat={seatNumbers.get(id) ?? 0} self={false} />;
          })}
        </div>
        <div className="board-center" aria-label="Khu vực bàn chơi">
          <span className="board-center-symbol" aria-hidden="true">國 戰</span>
          <p>{board.seats.length ? `${board.seats.length} ghế đã xếp` : 'Đang chờ xếp ghế từ máy chủ'}</p>
          <div className="board-banners">
            {Object.entries(board.banners).filter(([, v]) => v !== 0 && v !== false && v !== '').map(([key, value]) =>
              <span className="board-mark" key={key}>{key}: {String(value)}</span>)}
          </div>
        </div>
        {self && <div className="board-local-seat"><PlayerPanel player={self} game={board.player[self.id]} self
          seat={seatNumbers.get(self.id) ?? 0} /></div>}
      </div>
      <div className="board-status" role="status">
        Thông tin ghế, máu, tướng đã lộ và dấu hiệu được cập nhật từ Lua. Điều khiển đánh bài và chọn mục tiêu đang được tích hợp.
      </div>
      <section className="board-log-panel" aria-label="Nhật ký trận đấu">
        <div className="board-log-heading">
          <strong>Nhật ký trận đấu ({board.logs.length})</strong>
          <button type="button" className="button small-button secondary" aria-expanded={showLogs}
            onClick={() => setShowLogs(!showLogs)}>{showLogs ? 'Thu gọn' : 'Xem nhật ký'}</button>
        </div>
        {showLogs && <ol className="board-logs" aria-live="polite">
          {board.logs.length ? board.logs.map((log, index) => <li key={index}>{visibleLog(log)}</li>) :
            <li>Chưa có thông báo từ trận đấu.</li>}
        </ol>}
      </section>
    </section>
  );
}
