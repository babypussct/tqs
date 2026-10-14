import { useState, type FormEvent } from 'react';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore } from './store/gameStore';

interface LoginScreenProps {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
}

export default function LoginScreen({ adapter, run, busy }: LoginScreenProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const connection = useGameStore((s) => s.connection);
  const submit = (event: FormEvent) => {
    event.preventDefault();
    run(() => adapter.login(username, password));
  };
  return (
    <section className="panel sg-panel sg-login-panel" aria-labelledby="login-title">
      <div className="sg-panel-mark" aria-hidden="true">TQS</div>
      <span className="section-label sg-section-label">01 / Kết nối</span>
      <h2 id="login-title">Đăng nhập Tam Quốc Sát</h2>
      <p className="muted">Đăng nhập để xem sảnh và tạo phòng Quốc Chiến. Nếu chưa có tài khoản, hệ thống có thể tự đăng ký tài khoản mới.</p>
      <form onSubmit={submit} className="form-stack">
        <label htmlFor="username">Tên tài khoản</label>
        <input id="username" autoComplete="username" value={username} onChange={(e) => setUsername(e.target.value)} minLength={1} required maxLength={80} placeholder="Nhập tên tài khoản…" />
        <label htmlFor="password">Mật khẩu</label>
        <input id="password" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required placeholder="Nhập mật khẩu…" />
        <button className="button primary" disabled={busy || connection.kind === 'connecting' || connection.kind === 'authenticating'} type="submit">
          {connection.kind === 'authenticating' ? 'Đang xác thực…' : connection.kind === 'connecting' ? 'Đang kết nối…' : 'Vào sảnh' }
        </button>
      </form>
      <small className="muted">Thông tin đăng nhập chỉ được dùng trong phiên kết nối hiện tại.</small>
      <details className="install-help">
        <summary>Chơi từ Màn hình chính</summary>
        <p><strong>iPhone:</strong> Trong Safari, mở Chia sẻ → Thêm vào Màn hình chính. Bật Mở dưới dạng ứng dụng web nếu có, rồi mở biểu tượng TQS để chơi trong cửa sổ riêng.</p>
        <p><strong>Android:</strong> Mở menu trình duyệt → Cài đặt ứng dụng hoặc Thêm vào màn hình chính, rồi mở biểu tượng TQS.</p>
        <p className="muted small">Đăng nhập và chơi cần kết nối mạng. Hãy kết thúc ván trước khi chuyển cách mở game.</p>
      </details>
    </section>
  );
}
