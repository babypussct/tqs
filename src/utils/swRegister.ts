/**
 * Service Worker Registration Module
 * ====================================
 * Đăng ký SW, xử lý update lifecycle, và dispatch events cho App.
 */

const SW_PATH = '/sw.js';

export interface SWUpdateEvent {
  type: 'SW_UPDATED';
}

/**
 * Đăng ký Service Worker.
 * Gọi hàm này một lần sau khi app mount.
 */
export async function registerSW(): Promise<void> {
  if (!('serviceWorker' in navigator)) {
    console.log('[SW Register] Service Worker không được hỗ trợ trên trình duyệt này.');
    return;
  }

  // SW chỉ hoạt động trên HTTPS và localhost
  const isSecure =
    location.protocol === 'https:' ||
    location.hostname === 'localhost' ||
    location.hostname === '127.0.0.1';

  if (!isSecure) {
    console.log('[SW Register] SW chỉ chạy trên HTTPS hoặc localhost.');
    return;
  }

  try {
    const registration = await navigator.serviceWorker.register(SW_PATH, {
      scope: '/',
      // updateViaCache: 'none' — luôn fetch sw.js mới từ server (không cache)
      updateViaCache: 'none',
    });

    console.log('[SW Register] ✓ Service Worker đã đăng ký, scope:', registration.scope);

    // Lắng nghe khi có SW mới được tìm thấy
    registration.addEventListener('updatefound', () => {
      const newSW = registration.installing;
      if (!newSW) return;

      console.log('[SW Register] Phiên bản SW mới đang cài đặt...');

      newSW.addEventListener('statechange', () => {
        if (newSW.state === 'installed' && navigator.serviceWorker.controller) {
          // SW mới đã cài xong, đang chờ activate
          // skipWaiting trong sw.js sẽ tự activate ngay
          console.log('[SW Register] SW mới đã cài đặt, đang activate...');
        }
        if (newSW.state === 'activated') {
          console.log('[SW Register] ✓ SW mới đã activate');
        }
      });
    });

    // Lắng nghe message từ SW (SW_UPDATED event)
    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data?.type === 'SW_UPDATED') {
        console.log('[SW Register] SW mới đã activate → dispatch sw-updated');
        window.dispatchEvent(new CustomEvent('sw-updated'));
      }
    });

    // Kiểm tra update định kỳ mỗi 30 phút (khi tab đang mở)
    setInterval(() => {
      registration.update().catch(() => {
        // Bỏ qua lỗi update check khi offline
      });
    }, 30 * 60 * 1000);

  } catch (error) {
    console.error('[SW Register] Đăng ký Service Worker thất bại:', error);
  }
}

/**
 * Gỡ đăng ký tất cả SW (dùng để debug hoặc clear cache).
 */
export async function unregisterAllSW(): Promise<void> {
  if (!('serviceWorker' in navigator)) return;
  const registrations = await navigator.serviceWorker.getRegistrations();
  await Promise.all(registrations.map(r => r.unregister()));
  console.log('[SW Register] Đã gỡ tất cả Service Workers');
}

/**
 * Xóa toàn bộ cache của TQSShop (debug).
 */
export async function clearTQSCache(): Promise<void> {
  if (!('caches' in window)) return;
  const keys = await caches.keys();
  const tqsKeys = keys.filter(k => k.startsWith('tqs-'));
  await Promise.all(tqsKeys.map(k => caches.delete(k)));
  console.log('[SW Register] Đã xóa', tqsKeys.length, 'cache entries của TQSShop');
}
