import type { GamePhase } from './store/gameStore';

interface BootScreenProps {
  phase: GamePhase;
  progress: string;
  error: string | null;
  retry: () => void;
}

/**
 * Shared boot/status surface. Progress and connection errors are kept here so
 * the shell can remain responsible only for choosing the active screen.
 */
export default function BootScreen({ phase, progress, error, retry }: BootScreenProps) {
  const booting = phase === 'boot';
  const progressText = progress || 'Đang chuẩn bị tài nguyên…';
  return <div className="sg-boot-screen">
    {progress && <div className="notice sg-progress-notice" role="status">
      <div className="sg-progress-copy">
        <span className="sg-progress-kicker">Binh thư đang được chuẩn bị</span>
        <span>{progress}</span>
      </div>
      <div className="sg-progress-track" role="progressbar" aria-label="Tiến trình chuẩn bị game" aria-valuetext={progress}>
        <span className="sg-progress-fill" />
      </div>
    </div>}
    {error && <div className="notice error-notice sg-error-notice" role="alert">
      <span className="sg-error-copy">{error}</span>
      {booting && <button className="button small-button" onClick={retry}>Thử lại</button>}
    </div>}
    {booting && <section className="panel sg-panel sg-boot-panel" aria-labelledby="boot-title">
      <div className="sg-panel-mark" aria-hidden="true">TQS</div>
      <span className="section-label sg-section-label">TQS · Quốc Chiến</span>
      <h2 id="boot-title">Đang chuẩn bị tài nguyên…</h2>
      <p className="muted">Tải và chuẩn bị dữ liệu võ tướng, thẻ bài trước khi vào trận.</p>
      {!progress && <div className="sg-progress-track" role="progressbar" aria-label="Tiến trình chuẩn bị game" aria-valuetext={progressText}>
        <span className="sg-progress-fill" />
      </div>}
    </section>}
  </div>;
}
