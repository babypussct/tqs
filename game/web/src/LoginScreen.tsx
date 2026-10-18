import { useEffect, useState } from 'react';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore } from './store/gameStore';
import HeroSpotlight from './HeroSpotlight';
import { createGameSessionForCurrentUser, GameAccessError, logoutGame, prepareGameAuth, signInAndCreateGameSession, watchGameUser } from './gameAuth';

interface LoginScreenProps {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}

export default function LoginScreen({ adapter, run, busy }: LoginScreenProps) {
  const [gameUser, setGameUser] = useState<import('firebase/auth').User | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [activeModal, setActiveModal] = useState<'guide' | 'support' | 'access' | null>(null);
  const [audioMuted, setAudioMuted] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [accessIssue, setAccessIssue] = useState<'pending' | 'suspended' | null>(null);

  const connection = useGameStore((s) => s.connection);
  const storeError = useGameStore((s) => s.error);

  useEffect(() => {
    let active = true;
    const unsubscribe = watchGameUser((user) => {
      if (active) setGameUser(user);
    });
    void prepareGameAuth().then(() => {
      if (active) setAuthLoading(false);
    }).catch(() => {
      if (active) {
        setLocalError('Không khởi tạo được phiên đăng nhập trên thiết bị này. Kiểm tra cài đặt lưu trữ của trình duyệt và tải lại trang.');
      }
    });
    return () => { active = false; unsubscribe(); };
  }, []);

  const connectToBattlefield = () => {
    setLocalError(null);
    setAccessIssue(null);
    run(async () => {
      try {
        const session = gameUser
          ? await createGameSessionForCurrentUser()
          : await signInAndCreateGameSession();
        await adapter.login(session);
      } catch (error) {
        if (error instanceof GameAccessError) {
          if (error.code === 'GAME_ACCESS_PENDING') {
            setAccessIssue('pending');
            return;
          }
          if (error.code === 'GAME_ACCESS_SUSPENDED') {
            setAccessIssue('suspended');
            return;
          }
          setLocalError(error.message);
          return;
        }
        throw error;
      }
    });
  };

  const pingStatusText =
    connection.kind === 'online'
      ? 'Tín hiệu: Sẵn sàng tham chiến'
      : connection.kind === 'authenticating'
      ? 'Tín hiệu: Đang kiểm tra lệnh bài…'
      : connection.kind === 'connecting'
      ? 'Tín hiệu: Đang kết nối chiến trường…'
      : 'Tín hiệu: Sẵn sàng';

  const isConnecting = connection.kind === 'connecting' || connection.kind === 'authenticating';

  return (
    <div className="sg-game-canvas theme-battlefield sg-login-canvas">
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

        {/* AUTH BOX */}
        <section className="panel sg-panel sg-auth-box" aria-labelledby="login-title">
          <h2 id="login-title" className="sg-auth-title">Cổng Doanh Trại</h2>
          <span className="sg-corner sg-corner-tl" />
          <span className="sg-corner sg-corner-tr" />
          <span className="sg-corner sg-corner-bl" />
          <span className="sg-corner sg-corner-br" />

          {/* ACCESS PENDING / SUSPENDED STATE CARD */}
          {accessIssue ? (
            <div className="sg-access-card" role="status">
              <div className="sg-access-icon">
                {accessIssue === 'pending' ? '📜' : '🛡️'}
              </div>
              <h3 className="sg-access-title">
                {accessIssue === 'pending' ? 'Chiến Thư Đang Chờ Phê Chuẩn' : 'Tạm Dừng Lệnh Bài'}
              </h3>
              <p className="sg-access-desc">
                {accessIssue === 'pending'
                  ? 'Chiến trường hiện đang mở thử nghiệm giới hạn. Doanh trại đã ghi nhận tài khoản của chúa công. Vui lòng liên hệ Quân Sư để nhận lệnh bài tham chiến sớm nhất.'
                  : 'Quyền vào chiến trường của tài khoản hiện đang tạm dừng. Chúa công vui lòng liên hệ Quân Sư để kiểm tra lại lệnh bài.'}
              </p>
              <div className="sg-form-stack" style={{ marginTop: 12 }}>
                <button
                  type="button"
                  className="button primary sg-btn-hero"
                  onClick={() => setActiveModal('support')}
                >
                  Gặp Quân Sư Hỗ Trợ
                </button>
                <button
                  type="button"
                  className="sg-dialog-btn-ghost"
                  onClick={() => {
                    setAccessIssue(null);
                    run(() => logoutGame());
                  }}
                >
                  Đổi tài khoản khác
                </button>
              </div>
            </div>
          ) : (
            <>
              {(localError || storeError) && (
                <div className="notice error-notice sg-error-notice" role="alert" style={{ marginBottom: 10 }}>
                  <span className="sg-error-copy">{localError || storeError}</span>
                </div>
              )}

              <div className="sg-form-stack">
                {gameUser ? (
                  <div className="sg-user-preview-card">
                    <span className="sg-user-badge">Chúa công sẵn sàng</span>
                    <span className="sg-user-name">{gameUser.displayName || gameUser.email || 'Chúa Công'}</span>
                    <span className="sg-user-email">{gameUser.email}</span>
                  </div>
                ) : (
                  <p className="sg-auth-welcome-note">
                    Phiên bản thử nghiệm giới hạn. Đăng nhập để nhận lệnh bài xuất quân vào chiến trường.
                  </p>
                )}

                <button
                  className="button primary sg-btn-hero"
                  disabled={busy || isConnecting || authLoading}
                  type="button"
                  onClick={connectToBattlefield}
                >
                  {busy && !isConnecting ? (
                    'Đang đăng nhập…'
                  ) : connection.kind === 'authenticating' ? (
                    'Đang kiểm tra lệnh bài…'
                  ) : connection.kind === 'connecting' ? (
                    'Đang vào chiến trường…'
                  ) : gameUser ? (
                    'Vào Chiến Trường'
                  ) : (
                    <>
                      <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" style={{ flexShrink: 0 }}>
                        <path
                          fill="#4285F4"
                          d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                        />
                        <path
                          fill="#34A853"
                          d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                        />
                        <path
                          fill="#FBBC05"
                          d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                        />
                        <path
                          fill="#EA4335"
                          d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                        />
                      </svg>
                      <span>Tiếp tục với Google</span>
                    </>
                  )}
                </button>

                {gameUser && (
                  <button
                    className="sg-dialog-btn-ghost"
                    disabled={busy || isConnecting}
                    type="button"
                    onClick={() => run(() => logoutGame())}
                  >
                    Đổi tài khoản khác
                  </button>
                )}

                <span
                  className="sg-forgot-link"
                  role="button"
                  tabIndex={0}
                  onClick={() => setActiveModal('access')}
                  onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && setActiveModal('access')}
                >
                  Cần hỗ trợ lệnh bài truy cập?
                </span>
              </div>
            </>
          )}

          <details className="install-help sg-install-accordion" style={{ marginTop: 14 }}>
            <summary className="sg-install-summary">Chơi mượt hơn từ Màn hình chính</summary>
            <div className="sg-install-content">
              <p>
                <strong>iPhone (Safari):</strong> Bấm nút <em>Chia sẻ</em> (biểu tượng ô vuông mũi tên lên) → Chọn <em>Thêm vào Màn hình chính</em>.
              </p>
              <p>
                <strong>Android (Chrome):</strong> Bấm biểu tượng <em>Ba chấm góc phải</em> → Chọn <em>Cài đặt ứng dụng</em> hoặc <em>Thêm vào Màn hình chính</em>.
              </p>
            </div>
          </details>
        </section>
      </div>

      {/* MODAL: ACCESS HELP */}
      {activeModal === 'access' && (
        <div className="sg-modal-backdrop open" onClick={() => setActiveModal(null)}>
          <div className="sg-dialog-card" onClick={(e) => e.stopPropagation()}>
            <h3 className="sg-dialog-title">Lệnh Bài Chiến Trường</h3>
            <div className="sg-dialog-desc">
              <p style={{ margin: '0 0 10px 0' }}>
                Trò chơi sử dụng tài khoản Google để bảo đảm tính thống nhất cho hồ sơ tướng lĩnh của chúa công.
              </p>
              <p style={{ margin: 0 }}>
                Chiến trường hiện đang mở thử nghiệm nội bộ. Nếu tài khoản của bạn đang chờ cấp quyền hoặc cần kích hoạt tham chiến, xin hãy liên hệ <strong>Quân Sư Hỗ Trợ</strong> để nhận lệnh bài vào chơi.
              </p>
            </div>
            <div className="sg-dialog-actions">
              <button
                type="button"
                className="sg-dialog-btn-gold"
                onClick={() => setActiveModal(null)}
              >
                Đã hiểu
              </button>
            </div>
          </div>
        </div>
      )}

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
                Mỗi chúa công xuất chinh với 2 võ tướng cùng phe (Chủ tướng và Phó tướng). Hãy phối hợp cùng đồng minh cùng thế lực để tiêu diệt các phe khác và thống nhất thiên hạ!
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
              Để nhận lệnh bài tham chiến hoặc khi gặp khó khăn về kết nối, quý chúa công hãy liên hệ với ban điều hành qua cộng đồng Tam Quốc Sát để được kích hoạt tài khoản nhanh nhất.
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
          <span className={`sg-ping-indicator-dot ${connection.kind === 'online' ? '' : 'yellow'}`} />
          <span className="sg-ping-text">{pingStatusText}</span>
        </div>
        <span>Phiên bản: Thử nghiệm</span>
      </div>
    </div>
  );
}
