import { useEffect, useState } from 'react';
import type { GamePhase } from './store/gameStore';
import HeroSpotlight from './HeroSpotlight';
import { GUOZHAN_TIPS } from './guozhanTips';

interface BootScreenProps {
  phase: GamePhase;
  progress: string;
  error: string | null;
  retry: () => void;
}

function humanizeProgress(raw: string): string {
  if (!raw) return 'Đang chuẩn bị chiến trường…';
  const lower = raw.toLowerCase();
  if (lower.includes('manifest') || lower.includes('gateway')) return 'Đang kết nối cổng doanh trại…';
  if (lower.includes('package') || lower.includes('lua') || lower.includes('bundle')) return 'Đang tải dữ liệu chiến trường…';
  if (lower.includes('checksum') || lower.includes('xác minh')) return 'Đang kiểm tra tính toàn vẹn…';
  if (lower.includes('giải nén') || lower.includes('kiểm tra')) return 'Đang hoàn tất chuẩn bị…';
  if (lower.includes('wasm') || lower.includes('khởi tạo')) return 'Đang khởi tạo trận địa…';
  return raw;
}

function estimatePercent(progress: string): number {
  if (!progress) return 30;
  const lower = progress.toLowerCase();
  if (lower.includes('manifest') || lower.includes('gateway') || lower.includes('doanh trại')) return 25;
  if (lower.includes('package') || lower.includes('tải') || lower.includes('nạp dữ liệu')) return 55;
  if (lower.includes('checksum') || lower.includes('toàn vẹn') || lower.includes('xác minh')) return 80;
  if (lower.includes('giải nén') || lower.includes('hoàn tất') || lower.includes('chuẩn bị')) return 95;
  return 60;
}

export default function BootScreen({ phase, progress, error, retry }: BootScreenProps) {
  const booting = phase === 'boot';
  const [activeModal, setActiveModal] = useState<'guide' | 'support' | null>(null);
  const [audioMuted, setAudioMuted] = useState(false);
  const [tipIndex, setTipIndex] = useState(0);

  // Auto-rotate tips every 5 seconds
  useEffect(() => {
    const timer = setInterval(() => {
      setTipIndex((prev) => (prev + 1) % GUOZHAN_TIPS.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  const nextTip = () => {
    setTipIndex((prev) => (prev + 1) % GUOZHAN_TIPS.length);
  };

  // Login and in-game errors belong to their active screen; showing the boot
  // overlay as well would duplicate a notice and obscure the next action.
  if (!booting) return null;

  const currentTip = GUOZHAN_TIPS[tipIndex];
  const progressText = humanizeProgress(progress);
  const percent = estimatePercent(progress);

  return (
    <div className="sg-game-canvas theme-battlefield sg-boot-canvas">
      {/* TOP ACCESSORY BAR */}
      <div className="sg-top-bar">
        <button
          type="button"
          className="sg-icon-btn"
          title="Binh Thư (Sắp ra mắt)"
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
          title="Quân Sư Hỗ Trợ"
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

        {/* LOADING PROGRESS / MODERN DRAGON JADE BAR */}
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

          {/* TACTICAL TIP CARD (MODERN GUOZHAN TIP) */}
          <div
            className="sg-tip-card"
            role="button"
            tabIndex={0}
            onClick={nextTip}
            onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && nextTip()}
            title="Nhấp để đổi mẹo khác"
          >
            <div className="sg-tip-card-head">
              <span className="sg-tip-badge">MẸO QUỐC CHIẾN</span>
              <span className="sg-tip-title">{currentTip.title}</span>
              <span className="sg-tip-counter">{tipIndex + 1}/{GUOZHAN_TIPS.length}</span>
            </div>
            <p className="sg-tip-body">{currentTip.content}</p>
            <span className="sg-tip-footer-hint">Chạm để xem mẹo tiếp theo</span>
          </div>
        </div>

        {error && (
          <div className="notice error-notice sg-error-notice" role="alert">
            <span className="sg-error-copy">{error}</span>
            {booting && (
              <button className="button small-button sg-retry-btn" type="button" onClick={retry}>
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
            <div className="sg-dialog-desc">
              <p style={{ margin: '0 0 10px 0', color: '#ffe699', fontWeight: 600 }}>
                Thư viện tra cứu tướng & lá bài: <em>Đang biên tập (Sắp ra mắt)</em>
              </p>
              <p style={{ margin: '0 0 8px 0' }}>
                Tam Quốc Sát Quốc Chiến là chế độ chiến thuật đồng đội theo 4 thế lực: <strong>Nguỵ · Thục · Ngô · Quần</strong>.
              </p>
              <p style={{ margin: 0 }}>
                Mỗi chúa công xuất trận với 2 võ tướng cùng phe (Chủ tướng và Phó tướng). Hãy phối hợp cùng đồng minh để quét sạch các phe khác và thống nhất thiên hạ!
              </p>
            </div>
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
              Chúc chúa công có những trận xuất kích bách chiến bách thắng!
            </p>
            <div className="sg-dialog-actions">
              <button type="button" className="sg-dialog-btn-gold" onClick={() => setActiveModal(null)}>
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}


      <span className="sg-visually-hidden">Phiên bản: Thử nghiệm</span>
    </div>
  );
}
