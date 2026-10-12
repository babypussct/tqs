import type { ConnectionStatus } from './connection';

export function connectionProgress(status: ConnectionStatus): string {
  switch (status.kind) {
    case 'booting': return 'Đang khởi tạo Lua WASM…';
    case 'connecting': return 'Đang kết nối máy chủ…';
    case 'authenticating': return 'Đang xác thực…';
    case 'online':
    case 'closed': return '';
  }
}

export function connectionError(message: string): string {
  if (message === 'you have been temporarily banned!') {
    return 'Máy chủ đang tạm chặn IP kết nối. Rời ván khi còn sống hoặc bị ngắt phiên sau khi hết giờ có thể dẫn đến hình phạt này. Hãy đợi máy chủ hết chặn rồi đăng nhập lại; máy chủ không gửi thời điểm hết hạn. Khi cần tạm nghỉ trong ván, hãy bật BOT chơi hộ và giữ trang mở.';
  }
  if (message === 'backend closed') return 'Máy chủ đã đóng kết nối. Nếu ván chưa kết thúc, việc mất phiên có thể dẫn đến chặn IP tạm thời.';
  return message;
}
