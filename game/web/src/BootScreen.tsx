import { useState } from 'react';
import type { GamePhase } from './store/gameStore';
import HeroSpotlight from './HeroSpotlight';

interface BootScreenProps {
  phase: GamePhase;
  progress: string;
  error: string | null;
  retry: () => void;
}

function estimatePercent(progress: string): number {
  if (!progress) return 30;
  if (progress.includes('manifest')) return 25;
  if (progress.includes('tải package') || progress.includes('package Lua')) return 50;
  if (progress.includes('checksum') || progress.includes('xác minh')) return 75;
  if (progress.includes('giải nén') || progress.includes('kiểm tra')) return 92;
  return 60;
}

export default function BootScreen({ phase, progress, error, retry }: BootScreenProps) {
  const booting = phase === 'boot';
  const [activeModal, setActiveModal] = useState<'guide' | 'support' | null>(null);
  const [audioMuted, setAudioMuted] = useState(false);

  if (!booting && !error) return null;

  const progressText = progress || 'Đang chuẩn bị tài nguyên…';
  const percent = estimatePercent(progress);

  return (
    <div className="sg-game-canvas theme-battlefield sg-boot-canvas">
      {/* TOP ACCESSORY BAR */}
      <div className="sg-top-bar">
        <button
          type="button"
          className="sg-icon-btn"
          title="Binh Thư (Hướng dẫn tân thủ)"
          onClick={() => setActiveModal('guide')}
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
          </svg>
        </button>

        <button
          type="button"
          className="sg-icon-btn"
          title={audioMuted ? 'Bật âm thanh' : 'Tắt âm thanh'}
          onClick={() => setAudioMuted(!audioMuted)}
        >
          {audioMuted ? (
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
              <line x1="23" y1="9" x2="17" y2="15"/>
              <line x1="17" y1="9" x2="23" y2="15"/>
            </svg>
          ) : (
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
              <path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>
            </svg>
          )}
        </button>

        <button
          type="button"
          className="sg-icon-btn"
          title="Hỗ Trợ Quân Sư"
          onClick={() => setActiveModal('support')}
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/>
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
            <line x1="12" y1="17" x2="12.01" y2="17"/>
          </svg>
        </button>
      </div>

      {/* LOGO AREA */}
      <div className="sg-logo-area">
        <h1 className="sg-logo-title">Tam Quốc Sát</h1>
        <div className="sg-logo-ribbon">
          <span className="sg-logo-ribbon-text">QUỐC CHIẾN DI ĐỘNG BẢN</span>
        </div>
      </div>

      {/* MAIN CONTENT AREA */}
      <div className="sg-main-content">
        <HeroSpotlight />

        {/* LOADING PROGRESS / DRAGON JADE BAR */}
        <div className="sg-loading-wrap" role="status">
          <div className="sg-dragon-bar-head">
            <span className="sg-loading-status-text">{progressText}</span>
            <span className="sg-loading-percent-number">{percent}%</span>
          </div>

          <div
            className="sg-dragon-bar-frame"
            role="progressbar"
            aria-label="Tiến trình chuẩn bị game"
            aria-valuenow={percent}
            aria-valuetext={progressText}
          >
            <div className="sg-dragon-bar-fill" style={{ width: `${percent}%` }} />
          </div>

          <div className="sg-loading-note">
            Vui lòng giữ kết nối mạng ổn định trong quá trình chuẩn bị chiến trường
          </div>
        </div>

        {error && (
          <div className="notice error-notice sg-error-notice" role="alert">
            <span className="sg-error-copy">{error}</span>
            {booting && (
              <button className="button small-button" type="button" onClick={retry}>
                Thử lại
              </button>
            )}
          </div>
        )}
      </div>

      {/* MODAL: GUIDE */}
      {activeModal === 'guide' && (
        <div className="sg-modal-backdrop open" onClick={() => setActiveModal(null)}>
          <div className="sg-dialog-card" onClick={(e) => e.stopPropagation()}>
            <h3 className="sg-dialog-title">Binh Thư Tân Thủ</h3>
            <p className="sg-dialog-desc">
              Tam Quốc Sát Quốc Chiến là chế độ chiến thuật đồng đội theo thế lực Nguỵ - Thục - Ngô - Quần.
              Mỗi chúa công xuất chinh với 2 võ tướng (Chủ tướng và Phó tướng).
              Hãy phối hợp cùng đồng minh cùng thế lực để tiêu diệt các phe khác và thống nhất thiên hạ!
            </p>
            <div className="sg-dialog-actions">
              <button type="button" className="sg-dialog-btn-gold" onClick={() => setActiveModal(null)}>
                Đã hiểu binh pháp
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: SUPPORT */}
      {activeModal === 'support' && (
        <div className="sg-modal-backdrop open" onClick={() => setActiveModal(null)}>
          <div className="sg-dialog-card" onClick={(e) => e.stopPropagation()}>
            <h3 className="sg-dialog-title">Quân Sư Hỗ Trợ</h3>
            <p className="sg-dialog-desc">
              Nếu gặp khó khăn khi tải tài nguyên hoặc kết nối máy chủ, quý chúa công hãy thử bấm nút &quot;Thử lại&quot; hoặc làm mới trang trình duyệt.
            </p>
            <div className="sg-dialog-actions">
              <button type="button" className="sg-dialog-btn-gold" onClick={() => setActiveModal(null)}>
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}

      {/* BOTTOM FOOTER */}
      <div className="sg-bottom-footer">
        <div className="sg-ping-box">
          <span className="sg-ping-indicator-dot" />
          <span className="sg-ping-text">Máy chủ: Chuẩn bị tài nguyên</span>
        </div>
        <span>Phiên bản: BETA</span>
      </div>
    </div>
  );
}
