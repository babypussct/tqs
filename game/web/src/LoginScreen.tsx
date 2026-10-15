import { useState, type FormEvent } from 'react';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore } from './store/gameStore';
import HeroSpotlight from './HeroSpotlight';

interface LoginScreenProps {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}

export default function LoginScreen({ adapter, run, busy }: LoginScreenProps) {
  const [username, setUsername] = useState(() => {
    try {
      return localStorage.getItem('tqs_last_username') || '';
    } catch {
      return '';
    }
  });
  const [password, setPassword] = useState('');
  const [regUsername, setRegUsername] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regConfirmPassword, setRegConfirmPassword] = useState('');
  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [showForgotModal, setShowForgotModal] = useState(false);
  const [activeModal, setActiveModal] = useState<'guide' | 'support' | null>(null);
  const [audioMuted, setAudioMuted] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const connection = useGameStore((s) => s.connection);
  const storeError = useGameStore((s) => s.error);

  const submitLogin = (event: FormEvent) => {
    event.preventDefault();
    setLocalError(null);
    if (remember && username.trim()) {
      try {
        localStorage.setItem('tqs_last_username', username.trim());
      } catch {
        // ignore storage errors
      }
    } else {
      try {
        localStorage.removeItem('tqs_last_username');
      } catch {
        // ignore
      }
    }
    run(() => adapter.login(username, password));
  };

  const submitRegister = (event: FormEvent) => {
    event.preventDefault();
    if (!regUsername.trim()) {
      setLocalError('Vui lòng nhập tên tài khoản mới');
      return;
    }
    if (!regPassword) {
      setLocalError('Vui lòng nhập mật khẩu');
      return;
    }
    if (regPassword !== regConfirmPassword) {
      setLocalError('Mật khẩu xác nhận không khớp');
      return;
    }
    setLocalError(null);
    if (remember) {
      try {
        localStorage.setItem('tqs_last_username', regUsername.trim());
      } catch {
        // ignore
      }
    }
    // FreeKill server auto-registers new account upon authentication
    run(() => adapter.login(regUsername, regPassword));
  };

  const pingStatusText =
    connection.kind === 'online'
      ? 'Máy chủ: Đã kết nối'
      : connection.kind === 'authenticating'
      ? 'Máy chủ: Đang xác thực…'
      : connection.kind === 'connecting'
      ? 'Máy chủ: Đang kết nối…'
      : 'Máy chủ: Sẵn sàng kết nối';

  const isConnecting = connection.kind === 'connecting' || connection.kind === 'authenticating';

  return (
    <div className="sg-game-canvas theme-battlefield sg-login-canvas">
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
        {/* HERO SPOTLIGHT */}
        <HeroSpotlight />

        {/* AUTH BOX */}
        <section className="panel sg-panel sg-auth-box" aria-labelledby="login-title">
          <span className="section-label sg-section-label">01 / Kết nối</span>
          <h2 id="login-title" className="sg-auth-title">Đăng nhập Tam Quốc Sát</h2>
          <span className="sg-corner sg-corner-tl" />
          <span className="sg-corner sg-corner-tr" />
          <span className="sg-corner sg-corner-bl" />
          <span className="sg-corner sg-corner-br" />

          {/* TABS */}
          <div className="sg-auth-tabs">
            <button
              type="button"
              className={`sg-tab-btn ${activeTab === 'login' ? 'active' : ''}`}
              onClick={() => { setActiveTab('login'); setLocalError(null); }}
            >
              ĐĂNG NHẬP
            </button>
            <button
              type="button"
              className={`sg-tab-btn ${activeTab === 'register' ? 'active' : ''}`}
              onClick={() => { setActiveTab('register'); setLocalError(null); }}
            >
              ĐĂNG KÝ
            </button>
          </div>

          {(localError || storeError) && (
            <div className="notice error-notice sg-error-notice" role="alert" style={{ marginBottom: 10 }}>
              <span className="sg-error-copy">{localError || storeError}</span>
            </div>
          )}

          {activeTab === 'login' ? (
            <form onSubmit={submitLogin} className="sg-form-stack">
              <div className="sg-field">
                <label className="sg-label" htmlFor="username">Tên tài khoản</label>
                <div className="sg-input-wrap">
                  <input
                    id="username"
                    autoComplete="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    minLength={1}
                    required
                    maxLength={80}
                    placeholder="Nhập tên tài khoản chúa công…"
                  />
                </div>
              </div>

              <div className="sg-field">
                <label className="sg-label" htmlFor="password">Mật khẩu</label>
                <div className="sg-input-wrap">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    placeholder="Nhập mật khẩu…"
                  />
                  <button
                    type="button"
                    className="sg-eye-btn"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? 'Ẩn' : 'Hiện'}
                  </button>
                </div>
              </div>

              <div className="sg-meta-row">
                <label className="sg-remember-check">
                  <input
                    type="checkbox"
                    checked={remember}
                    onChange={(e) => setRemember(e.target.checked)}
                  />
                  <span>Ghi nhớ tài khoản</span>
                </label>
                <span
                  role="button"
                  tabIndex={0}
                  className="sg-forgot-link"
                  onClick={() => setShowForgotModal(true)}
                  onKeyDown={(e) => e.key === 'Enter' && setShowForgotModal(true)}
                >
                  Quên mật khẩu?
                </span>
              </div>

              <button
                className="button primary sg-btn-hero"
                disabled={busy || isConnecting}
                type="submit"
              >
                {connection.kind === 'authenticating'
                  ? 'Đang xác thực…'
                  : connection.kind === 'connecting'
                  ? 'Đang kết nối…'
                  : 'Vào sảnh'}
              </button>
            </form>
          ) : (
            <form onSubmit={submitRegister} className="sg-form-stack">
              <div className="sg-field">
                <label className="sg-label" htmlFor="reg_username">Tên tài khoản mới</label>
                <div className="sg-input-wrap">
                  <input
                    id="reg_username"
                    value={regUsername}
                    onChange={(e) => setRegUsername(e.target.value)}
                    minLength={2}
                    maxLength={20}
                    required
                    placeholder="Tên nhân vật (2-20 ký tự)…"
                  />
                </div>
              </div>

              <div className="sg-field">
                <label className="sg-label" htmlFor="reg_password">Mật khẩu mới</label>
                <div className="sg-input-wrap">
                  <input
                    id="reg_password"
                    type="password"
                    value={regPassword}
                    onChange={(e) => setRegPassword(e.target.value)}
                    minLength={3}
                    required
                    placeholder="Mật khẩu bảo vệ…"
                  />
                </div>
              </div>

              <div className="sg-field">
                <label className="sg-label" htmlFor="reg_confirm_password">Xác nhận lại mật khẩu</label>
                <div className="sg-input-wrap">
                  <input
                    id="reg_confirm_password"
                    type="password"
                    value={regConfirmPassword}
                    onChange={(e) => setRegConfirmPassword(e.target.value)}
                    minLength={3}
                    required
                    placeholder="Nhập lại mật khẩu vừa đặt…"
                  />
                </div>
              </div>

              <button
                className="button primary sg-btn-hero"
                disabled={busy || isConnecting}
                type="submit"
              >
                {isConnecting ? 'Đang tạo tài khoản…' : 'ĐĂNG KÝ TÀI KHOẢN'}
              </button>
            </form>
          )}

          <details className="install-help" style={{ marginTop: 12 }}>
            <summary style={{ fontSize: 11, color: '#cca250', cursor: 'pointer' }}>Chơi từ Màn hình chính</summary>
            <p style={{ fontSize: 11, color: '#d6c5ad', marginTop: 4 }}>
              <strong>iPhone:</strong> Mở Chia sẻ → Thêm vào Màn hình chính.
            </p>
            <p style={{ fontSize: 11, color: '#d6c5ad' }}>
              <strong>Android:</strong> Mở menu trình duyệt → Cài đặt ứng dụng hoặc Thêm vào màn hình chính.
            </p>
          </details>
        </section>
      </div>

      {/* MODAL: FORGOT PASSWORD */}
      {showForgotModal && (
        <div className="sg-modal-backdrop open" onClick={() => setShowForgotModal(false)}>
          <div className="sg-dialog-card" onClick={(e) => e.stopPropagation()}>
            <h3 className="sg-dialog-title">Khôi Phục Ấn Tín Tài Khoản</h3>
            <p className="sg-dialog-desc">
              Hệ thống Tam Quốc Sát hiện tại bảo mật danh tính trực tiếp trên máy chủ và không thu thập email hay số điện thoại cá nhân.
              <br /><br />
              Nếu quý chúa công quên mật khẩu, xin vui lòng liên hệ <strong>Quân Sư Quản Trị</strong> hoặc chuyển sang tab &quot;Đăng Ký&quot; để tạo nick mới tiếp tục xuất chinh.
            </p>
            <div className="sg-dialog-actions">
              <button
                type="button"
                className="sg-dialog-btn-gold"
                onClick={() => {
                  setShowForgotModal(false);
                  setActiveTab('register');
                }}
              >
                Tạo tài khoản mới
              </button>
              <button
                type="button"
                className="sg-dialog-btn-ghost"
                onClick={() => setShowForgotModal(false)}
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
              Nếu gặp khó khăn trong quá trình đăng nhập hoặc lỗi đường truyền, vui lòng kiểm tra kết nối mạng và đảm bảo nhập đúng thông tin tài khoản.
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
        <span>Phiên bản: BETA</span>
      </div>
    </div>
  );
}
