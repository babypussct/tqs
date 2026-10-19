export function shouldUseShopAuthProxy(options: {
  hostname: string;
  enabled: boolean;
  authDomainOverridden: boolean;
  projectId: string;
  expectedProjectId: string;
}): boolean {
  return options.enabled && options.hostname === 'tqsshop.vercel.app' &&
    !options.authDomainOverridden && options.projectId === options.expectedProjectId;
}

export function googleLoginErrorMessage(error: unknown): string | null {
  const code = (error as { code?: string } | null)?.code;
  switch (code) {
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return null;
    case 'auth/operation-not-supported-in-this-environment':
      return 'Trình duyệt này không hỗ trợ đăng nhập Google. Hãy mở TQSShop bằng Safari hoặc Chrome để thử lại.';
    case 'auth/unauthorized-domain':
      return 'Tên miền TQSShop chưa được Firebase cấp quyền đăng nhập Google. Vui lòng báo quản trị viên.';
    case 'auth/network-request-failed':
      return 'Không kết nối được Google. Kiểm tra mạng rồi thử đăng nhập lại.';
    case 'auth/web-storage-unsupported':
      return 'Trình duyệt không cho lưu phiên đăng nhập. Hãy bật lưu trữ website hoặc mở TQSShop bằng Safari/Chrome.';
    case 'auth/account-exists-with-different-credential':
      return 'Email này đã được dùng với một cách đăng nhập khác. Vui lòng liên hệ quản trị viên.';
    default:
      return `Không thể đăng nhập Google${code ? ` (${code})` : ''}. Vui lòng thử lại hoặc báo quản trị viên.`;
  }
}
