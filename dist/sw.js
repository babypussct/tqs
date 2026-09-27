/**
 * TQSShop Service Worker — Powered by Workbox
 * =============================================
 * Strategies:
 *   - Immutable media (R2 uploads + legacy Cloudinary) → CacheFirst (180 ngày)
 *   - App shell (JS/CSS) → NetworkFirst (4s timeout, 7 ngày fallback)
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
  suffix: 'v2',
  precache: 'precache',
  runtime: 'runtime',
});

// Bản SW mới tự activate để các tab đang chạy bundle cũ không bị kẹt trong
// overlay update của phiên bản trước. Bundle mới vẫn hiện overlay và chờ
// người dùng bấm reload; tab cũ không biết protocol mới sẽ được điều hướng
// một lần sau handshake timeout.
const UPDATE_PROTOCOL_VERSION = 2;
const updateClientAcks = new Set();
core.skipWaiting();
core.clientsClaim();

// ─── Precache: App shell files ──────────────────────────────────────────────
// offline.html được precache để luôn có sẵn khi mất mạng
precaching.precacheAndRoute([
  { url: '/offline.html', revision: 'v2' },
]);

// ─── Route 1: Immutable Media — CacheFirst ───────────────────────────────────
// R2 object keys are content-addressed-by-public-URL and receive immutable cache headers.
// Keep the legacy Cloudinary route so existing catalog data remains fast during migration.
routing.registerRoute(
  ({ url }) =>
    url.hostname === 'res.cloudinary.com' ||
    url.pathname.startsWith('/uploads/'),
  new CacheFirst({
    cacheName: 'tqs-media-v2',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 1000,
        maxAgeSeconds: 180 * 24 * 60 * 60,
        purgeOnQuotaError: true,   // Tự xóa khi storage đầy
      }),
    ],
  })
);

// ─── Route 2: App Shell (JS/CSS bundles) — NetworkFirst ─────────────────────
// Lấy bundle từ deploy mới trước; chỉ dùng cache khi mạng chậm/mất kết nối.
routing.registerRoute(
  ({ request, url }) =>
    (request.destination === 'script' || request.destination === 'style') &&
    url.origin === self.location.origin,
  new NetworkFirst({
    cacheName: 'tqs-app-shell-v2',
    networkTimeoutSeconds: 4,
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
    cacheName: 'tqs-fonts-v2',
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
    cacheName: 'tqs-static-images-v2',
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
    cacheName: 'tqs-pages-v2',
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

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
    return;
  }
  if (event.data?.type === 'SW_UPDATE_CLIENT_READY' && event.source?.id) {
    updateClientAcks.add(event.source.id);
  }
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
          .filter(name => name.startsWith('tqs-') && name.endsWith('-v1'))
          .map(name => caches.delete(name))
      );

      // Thông báo clients về SW mới
      const clients = await self.clients.matchAll({ includeUncontrolled: true, type: 'window' });
      clients.forEach(client => {
        client.postMessage({ type: 'SW_UPDATED', protocolVersion: UPDATE_PROTOCOL_VERSION });
      });

      // Các bundle mới sẽ gửi ACK để giữ overlay cho người dùng lựa chọn thời
      // điểm reload. Bundle cũ không biết ACK này; tự điều hướng giúp họ nhận
      // bundle đã sửa thay vì mắc kẹt với nút reload không thể click.
      await new Promise(resolve => setTimeout(resolve, 1000));
      const currentClients = await self.clients.matchAll({ includeUncontrolled: true, type: 'window' });
      await Promise.all(currentClients
        .filter(client => !updateClientAcks.has(client.id) && client.url)
        .map(client => client.navigate(client.url).catch(() => undefined)));
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

console.log('[TQSShop SW] Service Worker loaded — CacheFirst immutable media, NetworkFirst navigation, Offline Ready ✓');
