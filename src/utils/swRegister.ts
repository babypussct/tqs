/**
 * Service Worker Registration Module
 * ====================================
 * Đăng ký SW, xử lý update lifecycle, và dispatch events cho App.
 */

const SW_PATH = '/sw.js';

let pendingUpdateRegistration: ServiceWorkerRegistration | null = null;
let reloadInProgress = false;

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
    // Cài đặt lần đầu không phải là một bản cập nhật. Ghi nhận trạng thái
    // trước khi register để tránh chặn người dùng bằng overlay ngay lần mở
    // website đầu tiên.
    const hadControllerBeforeRegistration = Boolean(navigator.serviceWorker.controller);
    const registration = await navigator.serviceWorker.register(SW_PATH, {
      scope: '/',
      // updateViaCache: 'none' — luôn fetch sw.js mới từ server (không cache)
      updateViaCache: 'none',
    });

    console.log('[SW Register] ✓ Service Worker đã đăng ký, scope:', registration.scope);

    const announceUpdateReady = (updatedRegistration: ServiceWorkerRegistration) => {
      // Không hiển thị overlay cho lần cài đặt đầu tiên trên một tab chưa có
      // controller. Đây chỉ là bootstrap, không phải bản deploy mới.
      if (!hadControllerBeforeRegistration) return;
      pendingUpdateRegistration = updatedRegistration;
      console.log('[SW Register] SW mới đã cài đặt và đang chờ người dùng tải lại.');
      window.dispatchEvent(new CustomEvent('sw-update-ready'));
    };

    // Lắng nghe khi có SW mới được tìm thấy
    registration.addEventListener('updatefound', () => {
      const newSW = registration.installing;
      if (!newSW) return;

      console.log('[SW Register] Phiên bản SW mới đang cài đặt...');

      newSW.addEventListener('statechange', () => {
        if (newSW.state === 'installed' && navigator.serviceWorker.controller) {
          // SW mới đã cài xong và chờ người dùng bấm reload.
          announceUpdateReady(registration);
        }
        if (newSW.state === 'activated') {
          console.log('[SW Register] ✓ SW mới đã activate');
        }
      });
    });

    // Lắng nghe message từ SW (SW_UPDATED event)
    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data?.type !== 'SW_UPDATED') return;

      // Acknowledge the update protocol so the new SW can distinguish this
      // bundle from an older client that still has the broken overlay.
      event.source?.postMessage({ type: 'SW_UPDATE_CLIENT_READY' });

      if (hadControllerBeforeRegistration) {
        console.log('[SW Register] SW mới đã activate → dispatch sw-updated');
        window.dispatchEvent(new CustomEvent('sw-updated'));
      }
    });

    // Một bản SW có thể đã ở trạng thái waiting trước khi listener updatefound
    // được gắn (ví dụ tab được mở lại sau khi deploy).
    if (registration.waiting && navigator.serviceWorker.controller) {
      announceUpdateReady(registration);
    }

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
 * Kích hoạt bản SW đang chờ, xóa app cache cũ rồi tải lại trang.
 *
 * `window.location.reload()` đơn thuần không đủ tin cậy khi SW cũ đang phục
 * vụ app-shell từ cache. Gửi SKIP_WAITING trước, chờ controllerchange, sau
 * đó xóa cache theo prefix để request đầu tiên chắc chắn lấy deploy mới.
 */
export async function applySWUpdateAndReload(): Promise<void> {
  if (reloadInProgress) return;
  reloadInProgress = true;

  try {
    const registration =
      pendingUpdateRegistration ||
      (await navigator.serviceWorker.getRegistration('/'));
    const waitingWorker = registration?.waiting;

    if (waitingWorker) {
      await new Promise<void>((resolve) => {
        let settled = false;
        let timeout: number | undefined;
        const onControllerChange = () => {
          if (settled) return;
          settled = true;
          if (timeout !== undefined) window.clearTimeout(timeout);
          navigator.serviceWorker.removeEventListener('controllerchange', onControllerChange);
          resolve();
        };

        // Không khóa người dùng vô hạn nếu trình duyệt không phát controllerchange
        // (một số WebView cũ có hành vi này).
        timeout = window.setTimeout(onControllerChange, 5000);
        navigator.serviceWorker.addEventListener('controllerchange', onControllerChange);
        waitingWorker.postMessage({ type: 'SKIP_WAITING' });
      });
    }

    await clearTQSCache();
    window.location.reload();
  } catch (error) {
    console.error('[SW Register] Không thể áp dụng bản cập nhật:', error);
    // Vẫn cho phép người dùng thoát khỏi overlay ngay cả khi browser không hỗ
    // trợ đầy đủ lifecycle API.
    window.location.reload();
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
