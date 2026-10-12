import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';

export default function RequestDeadline({ request }: { request: RequestInfo | null }) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    if (request?.expiresAt == null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request]);
  if (request?.expiresAt == null) return null;
  const seconds = Math.max(0, Math.ceil((request.expiresAt - Math.max(now, Date.now())) / 1000));
  return <div className="notice" role="status">
    <span className={`countdown ${seconds === 0 ? 'expired' : ''}`} role="timer">Còn {seconds} giây để trả lời</span>
    <p>{seconds === 0 ? 'Yêu cầu đã hết thời gian. Hãy bật BOT chơi hộ nếu cần tạm nghỉ.' :
      'Hết giờ nhiều lần có thể khiến máy chủ ngắt phiên và tạm chặn IP. Bật BOT chơi hộ nếu không thể tiếp tục thao tác.'}</p>
  </div>;
}
