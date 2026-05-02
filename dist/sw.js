/**
 * TQSShop Service Worker — Powered by Workbox
 * =============================================
 * Strategies:
 *   - Cloudinary images  → CacheFirst (90 ngày, max 500 entries)
 *   - App shell (JS/CSS) → StaleWhileRevalidate (7 ngày)
 *   - Navigation (HTML)  → NetworkFirst → offline.html fallback
 *   - VietQR / API       → NetworkOnly (dynamic, không cache)
 *   - Google Fonts       → StaleWhileRevalidate (365 ngày)
 */

// ─── Workbox via CDN (không cần build step) ────────────────────────────────
importScripts('https://storage.googleapis.com/workbox-cdn/releases/7.3.0/workbox-sw.js');

const { core, routing, strategies, expiration, precaching, cacheableResponse } = workbox;
const { CacheFirst, NetworkFirst, StaleWhileRevalidate, NetworkOnly } = strategies;
const { ExpirationPlugin } = expiration;
const { CacheableResponsePlugin } = cacheableResponse;

// ─── Cấu hình chung ────────────────────────────────────────────────────────
core.setCacheNameDetails({
  prefix: 'tqs',
  suffix: 'v1',
  precache: 'precache',
  runtime: 'runtime',
});

// Kích hoạt SW mới ngay lập tức (không chờ tab đóng)
core.skipWaiting();
core.clientsClaim();

// ─── Precache: App shell files ──────────────────────────────────────────────
// offline.html được precache để luôn có sẵn khi mất mạng
precaching.precacheAndRoute([
  { url: '/offline.html', revision: 'v1' },
]);

// ─── Route 1: Cloudinary Images — CacheFirst ────────────────────────────────
// URL ảnh Cloudinary KHÔNG THAY ĐỔI khi đã có transform → an toàn 100% để cache lâu dài
routing.registerRoute(
  ({ url }) => url.hostname === 'res.cloudinary.com',
  new CacheFirst({
    cacheName: 'tqs-cloudinary-images-v1',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 500,           // Max 500 ảnh (LRU eviction)
        maxAgeSeconds: 90 * 24 * 60 * 60, // 90 ngày
        purgeOnQuotaError: true,   // Tự xóa khi storage đầy
      }),
    ],
  })
);

// ─── Route 2: App Shell (JS/CSS bundles) — StaleWhileRevalidate ─────────────
// Trả cached ngay → cập nhật ngầm → User không chờ, nhưng luôn có bản mới
routing.registerRoute(
  ({ request, url }) =>
    (request.destination === 'script' || request.destination === 'style') &&
    url.origin === self.location.origin,
  new StaleWhileRevalidate({
    cacheName: 'tqs-app-shell-v1',
    plugins: [
      new CacheableResponsePlugin({ statuses: [200] }),
      new ExpirationPlugin({
        maxEntries: 60,
        maxAgeSeconds: 7 * 24 * 60 * 60, // 7 ngày
      }),
    ],
  })
);

// ─── Route 3: Google Fonts — StaleWhileRevalidate ────────────────────────────
routing.registerRoute(
  ({ url }) =>
    url.hostname === 'fonts.googleapis.com' ||
    url.hostname === 'fonts.gstatic.com',
  new StaleWhileRevalidate({
    cacheName: 'tqs-fonts-v1',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 365 * 24 * 60 * 60, // 1 năm — fonts ổn định
      }),
    ],
  })
);

// ─── Route 4: VietQR Images — NetworkOnly ───────────────────────────────────
// QR code được generate động theo mã đơn + số tiền → KHÔNG được cache
routing.registerRoute(
  ({ url }) => url.hostname === 'img.vietqr.io',
  new NetworkOnly()
);

// ─── Route 5: Firebase / Firestore / Auth — NetworkOnly ──────────────────────
// Firebase SDK tự quản lý offline persistence. SW không can thiệp.
routing.registerRoute(
  ({ url }) =>
    url.hostname.includes('firebaseapp.com') ||
    url.hostname.includes('googleapis.com') ||
    url.hostname.includes('firestore.googleapis.com'),
  new NetworkOnly()
);

// ─── Route 6: API endpoints — NetworkOnly ────────────────────────────────────
routing.registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new NetworkOnly()
);

// ─── Route 7: Static assets (images from origin) — CacheFirst ───────────────
routing.registerRoute(
  ({ request, url }) =>
    request.destination === 'image' &&
    url.origin === self.location.origin,
  new CacheFirst({
    cacheName: 'tqs-static-images-v1',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 ngày
      }),
    ],
  })
);

// ─── Route 8: Navigation (HTML pages) — NetworkFirst + Offline Fallback ──────
// Ưu tiên lấy HTML mới nhất. Nếu offline → serve offline.html
routing.registerRoute(
  ({ request }) => request.mode === 'navigate',
  new NetworkFirst({
    cacheName: 'tqs-pages-v1',
    networkTimeoutSeconds: 3,    // Timeout 3s → fallback to cache
    plugins: [
      new CacheableResponsePlugin({ statuses: [200] }),
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 24 * 60 * 60, // 1 ngày
      }),
    ],
  })
);

// ─── Offline Fallback cho Navigation ─────────────────────────────────────────
routing.setCatchHandler(async ({ request }) => {
  if (request.mode === 'navigate') {
    // Serve offline.html từ precache khi mất mạng
    const offlinePage = await caches.match('/offline.html');
    return offlinePage || Response.error();
  }
  return Response.error();
});

// ─── SW Update Notification ──────────────────────────────────────────────────
// Khi SW mới activate → thông báo cho tất cả tabs để hiện toast
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Xóa cache cũ (version mismatch)
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter(name => name.startsWith('tqs-') && !name.endsWith('-v1'))
          .map(name => caches.delete(name))
      );

      // Thông báo clients về SW mới
      const clients = await self.clients.matchAll({ includeUncontrolled: true });
      clients.forEach(client => {
        client.postMessage({ type: 'SW_UPDATED' });
      });
    })()
  );
});

// ─── Background Sync: Order failover (future-proof) ──────────────────────────
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-pending-orders') {
    event.waitUntil(syncPendingOrders());
  }
});

async function syncPendingOrders() {
  try {
    const cache = await caches.open('tqs-pending-orders');
    const keys = await cache.keys();
    // Gửi lại các request order đang pending (nếu có)
    // Implementation sẽ được mở rộng khi có offline order queue
    console.log('[SW] Background sync: checking', keys.length, 'pending orders');
  } catch (err) {
    console.error('[SW] Background sync failed:', err);
  }
}

// ─── Push Notifications (future-proof) ───────────────────────────────────────
self.addEventListener('push', (event) => {
  if (!event.data) return;
  try {
    const data = event.data.json();
    event.waitUntil(
      self.registration.showNotification(data.title || 'TQSShop', {
        body: data.body || '',
        icon: '/icons/icon-192.png',
        badge: '/icons/icon-192.png',
        data: { url: data.url || '/' },
        vibrate: [100, 50, 100],
        tag: data.tag || 'tqs-notification',
      })
    );
  } catch (e) {
    console.warn('[SW] Push parse error:', e);
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window' }).then(clients => {
      const existingClient = clients.find(c => c.url.includes(url) && 'focus' in c);
      if (existingClient) return existingClient.focus();
      return self.clients.openWindow(url);
    })
  );
});

console.log('[TQSShop SW] Service Worker loaded — CacheFirst Cloudinary, NetworkFirst Navigation, Offline Ready ✓');
