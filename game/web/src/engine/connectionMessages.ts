import type { ConnectionStatus } from './connection';

export function connectionProgress(status: ConnectionStatus): string {
  switch (status.kind) {
    case 'booting': return 'Đang khởi tạo trận địa…';
    case 'connecting': return 'Đang kết nối chiến trường…';
    case 'authenticating': return 'Đang kiểm tra lệnh bài tham chiến…';
    case 'online':
    case 'closed': return '';
  }
}

export type ErrorContext = 'boot' | 'auth' | 'connection' | 'gameplay' | 'action';

const messages: Record<string, string> = {
  'others logged in again with this name':
    'Tài khoản đã đăng nhập ở nơi khác. Một thiết bị hoặc cửa sổ khác vừa đăng nhập bằng tài khoản này, nên phiên chơi tại đây đã kết thúc. Để tiếp tục trên thiết bị này, hãy đóng phiên còn lại và đăng nhập lại.',
  'you have been temporarily banned!':
    'Tài khoản của bạn đang bị tạm khóa. Rời ván khi còn sống hoặc bị ngắt phiên sau khi hết giờ có thể dẫn đến hình phạt này. Hãy đợi thời hạn kết thúc rồi đăng nhập lại; máy chủ không gửi thời điểm hết hạn. Khi cần tạm nghỉ trong ván, hãy bật BOT chơi hộ và giữ trang mở.',
  'server is full!': 'Máy chủ hiện đã đủ số người chơi. Vui lòng thử đăng nhập lại sau ít phút.',
  'game account is not approved': 'Tài khoản chưa được cấp quyền tham gia. Vui lòng chờ phê duyệt hoặc liên hệ ban điều hành.',
  'cannot register more new users on this device': 'Thiết bị này đã đạt giới hạn đăng ký tài khoản mới. Vui lòng sử dụng tài khoản đã có hoặc liên hệ ban điều hành.',
  'username or password error': 'Thông tin xác thực không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại bằng Google.',
  'backend closed': 'Máy chủ đã ngắt kết nối. Hãy kiểm tra mạng và đăng nhập lại. Nếu đang trong ván, việc mất phiên có thể dẫn đến tạm khóa tài khoản.',
  'backend error': 'Không thể liên lạc với máy chủ trò chơi. Hãy kiểm tra mạng và thử lại sau ít phút.',
  'connect timeout': 'Kết nối tới máy chủ quá thời gian chờ. Hãy kiểm tra mạng và thử đăng nhập lại.',
  'recovery timeout': 'Không thể khôi phục kết nối trong thời gian cho phép. Hãy kiểm tra mạng và đăng nhập lại.',
  'invalid packet stream': 'Dữ liệu nhận từ máy chủ gặp sự cố. Vui lòng tải lại trang và đăng nhập lại.',
  'Lua runtime error': 'Trò chơi gặp sự cố khi xử lý dữ liệu. Vui lòng tải lại trang và đăng nhập lại.',
  'Dữ liệu chiến trường chưa được nạp xong. Vui lòng tải lại trang.': 'Trò chơi chưa tải xong dữ liệu. Vui lòng tải lại trang rồi đăng nhập lại.',
  'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại bằng Google.',
  'Chưa có phiên TQSShop để tạo phòng': 'Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại để tạo phòng.',
  'Danh tính TQSShop đã thay đổi. Hãy ngắt kết nối và đăng nhập lại.': 'Tài khoản đăng nhập đã thay đổi. Vui lòng ngắt kết nối và đăng nhập lại.',
  'Không thể khôi phục sau 5 lần thử. Hãy kiểm tra mạng và đăng nhập lại.': 'Không thể khôi phục kết nối sau nhiều lần thử. Hãy kiểm tra mạng và đăng nhập lại.',
  'Không thể cấp lại vé vào game.': 'Không thể làm mới phiên đăng nhập. Vui lòng đăng nhập lại.',
  'GAME_ACCESS_PENDING': 'Tài khoản đang chờ quản trị viên phê duyệt quyền tham gia. Vui lòng liên hệ ban điều hành nếu cần hỗ trợ.',
  'GAME_ACCESS_SUSPENDED': 'Quyền tham gia của tài khoản đang tạm dừng. Vui lòng liên hệ ban điều hành để kiểm tra.',
  'GAME_AUTH_INVALID_RESPONSE': 'Máy chủ trả về dữ liệu đăng nhập không hợp lệ. Vui lòng thử lại sau ít phút.',
  'GAME_AUTH_NOT_CONFIGURED': 'Dịch vụ đăng nhập trò chơi đang được cấu hình. Vui lòng thử lại sau hoặc liên hệ ban điều hành.',
  'GAME_AUTH_UNAVAILABLE': 'Dịch vụ đăng nhập hiện không khả dụng. Vui lòng thử lại sau ít phút.',
  'GAME_AUTH_FAILED': 'Không thể xác thực tài khoản lúc này. Hãy đăng nhập lại bằng Google; nếu vẫn gặp lỗi, liên hệ ban điều hành.',
  'UNAUTHORIZED': 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại bằng Google.',
  'INVALID_TOKEN': 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại bằng Google.',
  'ACCOUNT_BANNED': 'Tài khoản hiện đã bị khóa quyền truy cập. Vui lòng liên hệ ban điều hành để được hỗ trợ.',
  'LOGIN_REQUIRED': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại bằng Google.',
  'ORIGIN_NOT_ALLOWED': 'Địa chỉ truy cập hiện tại chưa được cho phép đăng nhập. Vui lòng mở trò chơi từ địa chỉ chính thức.',
  'METHOD_NOT_ALLOWED': 'Dịch vụ đăng nhập đang gặp sự cố. Vui lòng thử lại sau ít phút.',
  'auth/popup-blocked': 'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên hoặc mở trò chơi bằng Safari/Chrome rồi thử lại.',
  'auth/operation-not-supported-in-this-environment': 'Trình duyệt hiện không hỗ trợ đăng nhập Google qua cửa sổ bật lên. Hãy mở trò chơi bằng Safari hoặc Chrome.',
  'auth/popup-closed-by-user': 'Bạn đã đóng cửa sổ Google trước khi hoàn tất đăng nhập. Hãy chọn Tiếp tục với Google để thử lại.',
  'auth/cancelled-popup-request': 'Quá trình đăng nhập Google đã bị gián đoạn. Vui lòng thử lại.',
  'auth/unauthorized-domain': 'Địa chỉ trò chơi chưa được cấp quyền đăng nhập Google. Vui lòng liên hệ ban điều hành.',
  'auth/network-request-failed': 'Không kết nối được với dịch vụ đăng nhập Google. Hãy kiểm tra mạng và thử lại.',
  'auth/too-many-requests': 'Có quá nhiều lần thử đăng nhập trong thời gian ngắn. Vui lòng đợi ít phút trước khi thử lại.',
  'GOOGLE_POPUP_BLOCKED': 'Không mở được cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên hoặc mở trang bằng Safari/Chrome.',
  'GOOGLE_POPUP_CLOSED': 'Cửa sổ Google đã đóng trước khi hoàn tất đăng nhập. Hãy chọn Tiếp tục với Google để thử lại.',
  'GOOGLE_DOMAIN_NOT_AUTHORIZED': 'Địa chỉ trò chơi chưa được cấp quyền đăng nhập Google. Vui lòng liên hệ ban điều hành.',
  'GOOGLE_NETWORK_ERROR': 'Không kết nối được với dịch vụ đăng nhập Google. Hãy kiểm tra mạng và thử lại.',
  'GOOGLE_REDIRECT_INCOMPLETE': 'Google chưa hoàn tất đăng nhập. Hãy chọn Tiếp tục với Google để thử lại.',
  'GOOGLE_STORAGE_UNAVAILABLE': 'Trình duyệt đang chặn bộ nhớ cần cho đăng nhập Google. Hãy mở trò chơi bằng Safari và thử lại.',
  'GOOGLE_OPEN_IN_BROWSER': 'Đăng nhập Google từ ứng dụng đã cài trên iPhone chưa được hỗ trợ. Hãy mở tqsvn.pages.dev trong Safari.',
};

const fallback: Record<ErrorContext, string> = {
  boot: 'Không tải được dữ liệu trò chơi. Hãy kiểm tra kết nối mạng, sau đó chọn Thử lại hoặc tải lại trang.',
  auth: 'Không thể đăng nhập lúc này. Vui lòng thử lại; nếu lỗi tiếp diễn, liên hệ ban điều hành.',
  connection: 'Kết nối đến máy chủ bị gián đoạn. Hãy kiểm tra mạng và đăng nhập lại.',
  gameplay: 'Không xử lý được thao tác này. Vui lòng thử lại hoặc tải lại trang nếu lỗi tiếp diễn.',
  action: 'Không thể thực hiện yêu cầu. Vui lòng thử lại.',
};

function knownError(value: unknown): string | null {
  return typeof value === 'string' && Object.prototype.hasOwnProperty.call(messages, value)
    ? messages[value] : null;
}

/** Single display boundary for native, HTTP, Firebase and local errors.
 * Never show arbitrary exception text, stack traces, URLs or protocol payloads. */
export function userFacingError(value: unknown, context: ErrorContext = 'action'): string {
  let code: unknown;
  let raw: unknown = value;
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    code = (value as { code?: unknown }).code;
    raw = (value as { message?: unknown }).message;
  }
  const knownCode = knownError(code);
  if (knownCode) return knownCode;
  if (typeof raw === 'string' && raw.length <= 4096 && /^[\[{]/.test(raw.trim())) {
    try {
      const decoded: unknown = JSON.parse(raw);
      if (Array.isArray(decoded)) raw = decoded[0];
      else if (decoded && typeof decoded === 'object') {
        const obj = decoded as { code?: unknown; message?: unknown };
        const decodedCode = knownError(obj.code);
        if (decodedCode) return decodedCode;
        raw = obj.message;
      }
    } catch { /* Native text may start with a bracket without being JSON. */ }
  } else if (Array.isArray(raw)) raw = raw[0];
  if (typeof raw !== 'string') return fallback[context];

  const message = raw.trim().replace(/^(?:Error|TypeError):\s*/i, '');
  const knownMessage = knownError(message) ?? knownError(message.toLowerCase());
  if (knownMessage) return knownMessage;
  if (/^closed \(\d+\)$/.test(message) || /^WebSocket/i.test(message)) return fallback.connection;
  if (/^Manifest HTTP \d{3}$|^Bundle HTTP \d{3}$/.test(message)) {
    return /\b(?:502|503|504)$/.test(message)
      ? 'Máy chủ đang tạm thời không khả dụng. Vui lòng thử tải lại trò chơi sau ít phút.'
      : fallback.boot;
  }
  if (/checksum|bundleHash|manifest|package|gateway|giải nén|dung lượng|số tệp|tệp package|đường dẫn bundle|Lua entrypoint/i.test(message) && context === 'boot') {
    return 'Dữ liệu trò chơi chưa đồng bộ hoặc không hợp lệ. Vui lòng tải lại trang; nếu vẫn gặp lỗi, liên hệ ban điều hành.';
  }
  if (/Failed to fetch|NetworkError|Load failed|fetch failed|network request failed|ERR_INTERNET_DISCONNECTED/i.test(message)) {
    return 'Không thể kết nối đến dịch vụ. Hãy kiểm tra mạng và thử lại.';
  }
  if (/^Yêu cầu (?:gameplay|kỹ năng|lựa chọn|chọn bài|chọn tướng|xem và chọn bài).*?(?:hết thời gian|không còn hiệu lực)/i.test(message)) {
    return 'Thời gian thao tác đã kết thúc. Hãy chờ yêu cầu tiếp theo từ trò chơi.';
  }
  if (/^Chưa xác thực với máy chủ$/.test(message)) {
    return 'Bạn chưa kết nối với máy chủ. Vui lòng đăng nhập lại để tiếp tục.';
  }
  if (/^Đang xử lý câu trả lời$/.test(message)) return 'Trò chơi đang xử lý lựa chọn trước đó. Vui lòng đợi trong giây lát.';
  if (/^Lựa chọn không được Lua cho phép$|^Lá bài không được Lua cho phép$|^Tương tác không được Lua cho phép$/.test(message)) {
    return 'Lựa chọn này hiện không hợp lệ. Vui lòng chọn lại theo hướng dẫn trên màn hình.';
  }
  // Preserve useful local room/gameplay validation details. Remote auth and
  // connection messages must match a known code to avoid exposing diagnostics.
  if ((context === 'action' || context === 'gameplay') && message.length <= 240 &&
    /[À-ỹ]/.test(message) && !/[\r\n<>\[\]{}]|https?:\/\/|(?:\bLua\b|\bCBOR\b|\bJSON\b|\bHTTP\b|\bwasm\b|\b__\w+|\b(?:undefined|null|NaN)\b|\bat\s+\S+\s*\()/i.test(message)) {
    return message;
  }
  return fallback[context];
}

export function connectionError(message: unknown): string {
  return userFacingError(message, 'connection');
}
