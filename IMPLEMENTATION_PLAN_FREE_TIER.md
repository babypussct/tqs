# TQSShop — Kế hoạch review và triển khai theo mục tiêu Free Tier

> Ngày review: 2026-09-21
>
> Phạm vi review: repository `main` tại `/Users/otada/Documents/GitHub/tqs`
>
> Trạng thái: Architecture review: **PASS** | Implementation kickoff: **PASS** | Pha 0: **PASS** | Gate 1 (Worker Spike): **PASS** | Gate 2 (Policy): **SIGNED OFF** | Gate 3 (Schema): **SIGNED OFF** | Prototype/R&D: **READY** | Production deployment: **NOT YET**.

## 1. Kết luận điều hành và đánh giá readiness

TQSShop hiện đã có phần giao diện khá đầy đủ cho một storefront boardgame: trang chủ, cửa hàng, chi tiết sản phẩm, giỏ hàng, checkout, VietQR, tài khoản, voucher, đánh giá, blog và dashboard quản trị. Kế hoạch hiện tại đã hoàn tất toàn bộ các điều kiện của Pha 0 (reproducible build, Worker feasibility spike đạt chuẩn, Gate 2 policy và Gate 3 schema đã sign-off). Bước tiếp theo là khóa runtime contract & rules emulator tests trước khi xây dựng core `orderService` production.

### 1.1 Bảng đánh giá trạng thái hiện tại

| Hạng mục | Đánh giá | Trạng thái kỹ thuật |
|---|---|---|
| **Phân tích rủi ro** | Đủ | Đã nhận diện đầy đủ P0/P1/P2 |
| **Kiến trúc mục tiêu** | Đạt | Ranh giới client/server rõ ràng |
| **Roadmap** | Đủ, theo gate | Chia pha 0-7 kèm 4 gate bắt buộc |
| **Gate 1 (Worker AuthN/AuthZ)** | **PASS** | Spike hoàn tất: Web Crypto RS256, CPU 0.6ms, 1 subrequest |
| **Gate 2 (Order Policy)** | **SIGNED OFF** | Đã chốt chính sách D2.1–D2.15, after-sales, stock, refund |
| **Gate 3 (Schema & Idempotency)** | **SIGNED OFF** | Đã chốt canonical enums, schemaVersion: 1, event log, fingerprint |
| **Build Baseline** | **PASS** | `npm ci`, `lint`, `build` reproducible trên clean environment |
| **Firestore Rules** | Cần cập nhật | Sẽ triển khai cùng contract tests |
| **Production readiness** | **Chưa đạt** | Cần hoàn thành Gate 4 và production deployment theo 12 bước |

### 1.2 Bốn gate bắt buộc trước Production

1. **Gate 1: Build và Worker phải chạy được**
   - Không viết toàn bộ order service trước khi biết Worker có đáp ứng được runtime hay không.
   - Prototype cần chứng minh được luồng: `Firebase ID token → verify trong Worker → đọc Firestore → thực hiện authenticated operation → trả response`.
   - Cần đo: CPU time, memory, số subrequests, latency, thời gian timeout, cách ký hoặc xác thực Firestore REST, cách lưu credential, behavior khi Firebase token hết hạn.
   - Spike phải chứng minh luôn cách Worker lấy `role/adminPermissions` và enforce authorization cho từng endpoint/transition; đo thêm chi phí read/subrequest của bước authorization này.
   - *Lưu ý an ninh:* Nếu dùng server-side credential (service account) để Worker ghi Firestore, server-side credential sẽ bypass Firestore Rules. Khi đó lớp bảo vệ phải nằm ở: endpoint authentication, role check, input validation, transition service, secret management, audit log. Firestore Rules không phải là lớp bảo vệ duy nhất cho mutation từ Worker.

2. **Gate 2: Chốt business policy của order**
   - Tránh việc phải sửa lại schema và transaction sau này bằng cách chốt trước các policy:
     - Stock bị trừ lúc tạo order hay lúc xác nhận order.
     - Cancel ở trạng thái nào được phép.
     - Cancel có hoàn voucher không; có hoàn điểm đã dùng không.
     - Điểm thưởng được cộng khi admin chuyển delivered hay khi khách xác nhận đã nhận hàng.
     - VietQR paymentStatus chuyển sang `paid` bằng thao tác nào (webhook ngân hàng vs admin manual confirm).
     - Đơn COD giao thất bại xử lý thế nào.
     - Sau khi `shipped`, còn cho phép `cancelled` hay phải đi qua `failed_delivery`/`returned`.
     - Trạng thái `delivered` có thể chuyển sang `returned`/`refunded` không; nếu có thì stock, reward và `totalSpent` được đảo như thế nào.
     - Voucher usage tính tại create hay khi payment thành công.
   - **Không bắt đầu implementation core của `orderService` trước khi Gate 2 được đóng bằng policy viết thành văn bản.** Các quyết định này ảnh hưởng trực tiếp transaction boundaries, marker idempotency và rollback.
     - Order nào được tính vào `totalOrders` và `totalSpent`.

3. **Gate 3: Chốt schema idempotency và event**
   - Tối thiểu: `orders/{orderId}`, `orders/{orderId}/events/{eventId}`, `idempotency/{uid_hash_requestKey}`.
   - Chốt enum canonical dùng chung giữa TypeScript, API, Firestore Rules và test: `status`, `paymentStatus`, `discountType`, actor/action/event types.
   - Mỗi order có `schemaVersion`; mọi migration làm thay đổi shape/order semantics phải có chiến lược backward compatibility hoặc adapter đọc version cũ.
   - Order fields/markers: `createdAt`, `updatedAt`, `status`, `paymentStatus`, `stockReservedAt`, `stockRestoredAt`, `pointsDeductedAt`, `pointsRefundedAt`, `rewardGrantedAt`, `cancelledAt`, `deliveredAt` và các marker after-sales đã chốt ở Gate 2.
   - Idempotency document tối thiểu chứa: `uid/actor`, hash của request payload hoặc request fingerprint, operation type, lifecycle status (`processing/succeeded/failed-retryable`), `orderId/resultRef`, `createdAt`, `updatedAt`, `expiresAt`/retention policy. Cùng key nhưng payload khác phải bị reject.
   - Mỗi transition định nghĩa rõ: `allowed previous states`, `new state`, `actor type`, `event id`, `affected documents`, `side effects`, `retry behavior`.
   - Retry event đã xử lý phải trả kết quả thành công hoặc no-op mà không cộng điểm, hoàn stock hay tăng voucher usage lần nữa.

4. **Gate 4: Chốt migration và rollback**
   - Rollback frontend/API tương đối dễ, nhưng rollback dữ liệu order rất khó (side effects như trừ stock, ghi order, tăng voucher usage, trừ điểm, gửi Telegram đã chạy).
   - Trước canary cần có: migration dry-run, snapshot/export dữ liệu, test restore trên test project, event audit log để biết side effect nào đã chạy, kill-switch disable endpoint mới, quy tắc xử lý order tạo bởi service mới khi quay về bản cũ (không sửa thủ công stock/points hàng loạt).
   - Phải rehearsal khả năng release cũ **đọc an toàn** order/schema version mới hoặc có adapter/feature flag chặn code path không tương thích trước khi rollback.
   - Rollout phải có release/version gate để tab cũ hoặc service worker cũ không tiếp tục mutation trực tiếp sau khi API mới đã được bật. Client quá cũ phải fail closed và yêu cầu refresh/update trước checkout/admin mutation.

### 1.3 Đánh giá R2 & Cloudflare Images Transformations

- R2 phù hợp về kỹ thuật cho TQS với điều kiện **chấp nhận mô hình usage-based billing** của Cloudflare.
- R2 Standard có free allowance: 10 GB-month, 1 triệu Class A operations, 10 triệu Class B operations, egress Internet miễn phí. Tuy nhiên R2 yêu cầu subscription và không có hard spending cap (vượt allowance sẽ phát sinh phí).
- Nếu mục tiêu là “không dùng Firebase Blaze” thì R2 hoàn toàn phù hợp. Nếu mục tiêu là “tuyệt đối không thể phát sinh bất kỳ khoản phí nào” thì R2 chưa đáp ứng 100%. Nếu mục tiêu là “vận hành thực tế ở mức 0 đồng với giới hạn bảo vệ chặt” thì R2 là lựa chọn tối ưu hơn Cloudinary cho ảnh.
- Cloudflare Images Transformations: Tối ưu ảnh lưu ngoài Images (R2) với tối đa 5.000 unique transformations/tháng ở Free plan; khi vượt mức, transformation mới bị từ chối thay vì tự động tính phí. Do đó phải dùng các preset cố định (`hero`, `card`, `detail`, `avatar`).

Mục tiêu triển khai được chấp nhận trong kế hoạch này là:

- Không nâng Firebase lên Blaze và không dùng dịch vụ Firebase yêu cầu billing. R2 chỉ được bật nếu chấp nhận Cloudflare R2 subscription/usage-based billing và đã thiết lập policy kiểm soát chi phí phù hợp.
- Dùng Firebase Spark cho Authentication xã hội và Firestore trong quota miễn phí.
- Dùng Cloudflare R2 Standard cho ảnh với presigned upload, custom domain và guardrail quota; dùng Cloudflare Images Transformations cho một số preset resize/WebP/AVIF cố định. Không dựa vào video upload.
- Dùng Telegram Bot API cho thông báo nội bộ với lưu lượng nhỏ, không paid broadcast.
- Dùng Firebase Hosting Spark hoặc Cloudflare Pages/Workers Free cho frontend/API tối thiểu tùy điều kiện commercial của chủ dự án.
- Không để một phía client có thể tự sửa giá, stock, số tiền cuối, voucher hoặc cộng/trừ điểm.
- Có test rules, test race condition order, cost guardrails và rollback trước khi public.

## 2. Ranh giới “free” cần hiểu đúng

Free tier là quota có giới hạn, không phải tài nguyên vô hạn. Nếu vượt quota, dịch vụ có thể bị giới hạn hoặc tắt phần dịch vụ đó cho kỳ còn lại; vì vậy kế hoạch đặt ngưỡng vận hành thấp hơn quota công bố để có buffer.

### 2.1 Stack mục tiêu

| Thành phần | Vai trò | Lựa chọn mục tiêu | Ghi chú chi phí/rủi ro |
|---|---|---|---|
| Firebase Auth | Google login, session, ban state | Firebase Spark | Chỉ dùng social sign-in; không dùng phone/SMS Auth vì SMS có thể tính phí. |
| Cloud Firestore | products, users, orders, reviews, settings | Firebase Spark | Giữ dưới quota; bỏ listener không cần thiết và mọi truy vấn toàn collection. |
| Firebase Hosting | static SPA, HTTPS, custom domain nếu cần | Spark | Phù hợp để giữ cùng hệ Firebase; cần theo dõi data transfer. |
| Cloudflare R2 | ảnh sản phẩm, thumbnail, ảnh editor, banner, avatar | Usage-based với free allowance | 10 GB-month storage, 1 triệu Class A operations, 10 triệu Class B operations/tháng và Internet egress miễn phí; cần budget alert và hard guardrail ở ứng dụng vì không có hard spending cap. |
| Cloudflare Images Transformations | resize/format ảnh từ R2 | Free allowance | Dùng một số preset cố định; giới hạn unique transformations để tránh phát sinh usage ngoài dự kiến. |
| Telegram Bot API | thông báo admin và thao tác nội bộ ít lưu lượng | miễn phí ở lưu lượng nhỏ | Token chỉ nằm ở server/Worker; webhook phải có secret và allowlist. |
| API server | tạo order, chuyển trạng thái, thông báo | Cloudflare Pages Function/Worker Free cho use case public; Vercel Hobby chỉ cho project cá nhân | Không dùng Firebase Cloud Functions vì không phù hợp mục tiêu Spark-only. |
| CI/build | lint, build, rules test | local/GitHub Actions nếu repo phù hợp | Không phụ thuộc dịch vụ monitoring trả phí. |

### 2.2 Quota tham chiếu và ngân sách nội bộ

Các số dưới đây được kiểm tra ngày 2026-09-21 từ tài liệu chính thức; cần kiểm tra lại trước mỗi lần thay đổi nhà cung cấp:

- [Firebase pricing](https://firebase.google.com/pricing) và [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans): Spark không cần payment method; các sản phẩm có quota miễn phí vẫn có giới hạn. Cloud Functions và các Google Cloud product trả phí không phải nền tảng phù hợp cho Spark-only.
- [Firestore quotas](https://firebase.google.com/docs/firestore/quotas): 1 GiB stored data, 50.000 document reads/ngày, 20.000 writes/ngày, 20.000 deletes/ngày và 10 GiB outbound/tháng cho database miễn phí.
- [Cloudflare R2 pricing](https://developers.cloudflare.com/r2/pricing/): R2 Standard có free allowance hàng tháng gồm 10 GB-month storage, 1 triệu Class A operations, 10 triệu Class B operations và Internet egress miễn phí; phần vượt allowance có thể phát sinh phí.
- [Cloudflare R2 presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/), [public buckets/custom domains](https://developers.cloudflare.com/r2/buckets/public-buckets/) và [Images Transformations pricing](https://developers.cloudflare.com/images/pricing/): upload admin nên dùng presigned URL, production nên dùng custom domain thay vì `r2.dev`, và chỉ dùng preset transformation cố định.
- [Cloudflare Workers limits](https://developers.cloudflare.com/workers/platform/limits/) và [Pages Functions pricing](https://developers.cloudflare.com/pages/functions/pricing/): Workers Free có 100.000 requests/ngày, 10 ms CPU/request và 50 external subrequests/request; Pages Functions tính theo Workers.
- [Vercel Hobby](https://vercel.com/docs/plans/hobby) và [Vercel pricing](https://vercel.com/pricing): có quota function miễn phí nhưng Hobby được mô tả cho personal/non-commercial use. Một storefront bán hàng không được mặc nhiên coi là hợp lệ trên Hobby.

Ngân sách vận hành nội bộ, đặt ở mức khoảng 50% quota công bố:

| Chỉ số | Hard quota tham chiếu | Ngưỡng cảnh báo nội bộ | Hành động khi chạm ngưỡng |
|---|---:|---:|---|
| Firestore reads | 50.000/ngày | 25.000/ngày | Tạm tắt realtime public, rà soát query dashboard, kiểm tra listener trùng. |
| Firestore writes | 20.000/ngày | 8.000/ngày | Tắt auto-seed/default write, kiểm tra retry và thao tác Telegram lặp. |
| Firestore deletes | 20.000/ngày | 8.000/ngày | Không cho xóa hàng loạt từ UI; dùng soft-delete hoặc script có dry-run. |
| Firestore egress | 10 GiB/tháng | 5 GiB/tháng | Giảm payload, phân trang, dùng ảnh CDN và cache. |
| R2 storage | 10 GB-month | 5 GB | Dừng upload không cần thiết, kiểm tra object mồ côi và dọn asset qua script có dry-run; không cho video trong flow thường. |
| R2 Class A operations | 1.000.000/tháng | 400.000 | Kiểm tra upload/delete/retry, giới hạn presigned URL và chống abuse endpoint cấp URL. |
| R2 Class B operations | 10.000.000/tháng | 4.000.000 | Tăng CDN cache, giới hạn listing/head/read lặp và kiểm tra cache headers. |
| Images unique transformations | Theo allowance hiện hành | 50% allowance | Chỉ cho dùng preset hero/card/detail/avatar; không cho frontend sinh width/quality tùy ý. |
| Edge API requests | 100.000/ngày | 50.000/ngày | Rate-limit, bỏ endpoint public không cần thiết và kiểm tra bot abuse. |

## 3. Hiện trạng được phát hiện

### 3.1 Kiến trúc hiện tại

| Khu vực | Hiện trạng | Đánh giá |
|---|---|---|
| Frontend | React 19 + Vite + Tailwind, route lazy-load trong `src/App.tsx` | Tốt về mặt trải nghiệm; cần giảm dependency và chuẩn hóa build. |
| Auth | Firebase Auth Google popup; hồ sơ user lưu tại `users/{uid}` | Có bootstrap super-admin bằng email hard-code; role model lệch với rules. |
| Data | Firebase Web SDK + persistent local cache | Cache là điểm tốt nhưng không thay thế được giới hạn query/read. |
| Order | Client transaction đọc product, trừ stock, tạo order, tăng usage/points | Không đủ tin cậy cho giá trị thương mại nếu không chuyển phần quyết định sang server. |
| Admin | Đọc realtime toàn bộ orders/users/products/discounts tùy tab | Dễ tốn quota; một số action cập nhật dữ liệu nhạy cảm trực tiếp. |
| API | `api/notify.ts`, `api/telegram-webhook.ts` theo kiểu Vercel Function | Endpoint notify đang public; webhook chưa xác thực người gửi. |
| Media | Upload unsigned trực tiếp Cloudinary; transform URL theo từng component | Có tối ưu ảnh nhưng chưa có quota guardrail cho video/derivative; mục tiêu là migrate media mới sang R2. |
| PWA | Service worker dùng Workbox CDN, cache ảnh/app shell, offline fallback | Có ích cho bandwidth nhưng phụ thuộc CDN runtime và cache version hiện tại. |
| Deploy | Có `vercel.json`, có `dist/` commit | Chưa có cấu hình Firebase Hosting/Cloudflare; `dist/` stale, không nên là source deploy. |

### 3.2 Findings mức P0 — phải xử lý trước production

#### P0.1 Rules không bao phủ toàn bộ collection đang dùng

`firestore.rules` hiện có match cho `reviews`, `products`, `settings`, `users`, `discountCodes`, `orders`, nhưng source còn truy cập:

- `posts`: blog public/admin.
- `notifications`: notification drawer.
- `system/version`: delta sync.
- `system_settings/tiers_config`: rewards.
- `test/connection`: health check trong `App.tsx`.

Kết quả hiện tại có thể là blog/rewards/notifications/delta sync bị `permission-denied`, hoặc team sẽ bị cám dỗ dán rules mở toàn quyền để “sửa lỗi”. Phải bổ sung rules tối thiểu theo collection và xóa đường hướng dẫn nguy hiểm trong `src/components/admin/AdminDatabaseRules.tsx:8-20`, nơi đang tạo rules `allow read, write: if true`.

#### P0.2 Checkout tin dữ liệu từ client

`src/components/Checkout.tsx:426-545` cho phép browser quyết định hoặc gửi lên:

- `item.price`, `totalAmount`, `discountAmount`, `finalAmount`.
- `shippingFee`, `paymentMethod`, `paymentStatus`, `riskScore`.
- việc tăng `usedCount`, trừ điểm và tăng `totalOrders`.

Rules hiện kiểm tra type/required fields nhưng chưa chứng minh tổng tiền bằng giá thật trong `products`, chưa khóa các field thanh toán và chưa bảo vệ idempotency. Người dùng có thể sửa request bằng DevTools. Đây là rủi ro dữ liệu và thất thoát, không chỉ là rủi ro quota.

#### P0.3 Có nhiều nơi cùng xử lý chuyển trạng thái và thưởng điểm

Luồng delivered/points hiện xuất hiện ở:

- `src/components/Profile.tsx:127-174` — khách tự xác nhận delivered và tự increment điểm.
- `src/utils/useOrders.ts:30-239` — admin đổi trạng thái và cộng/trừ điểm.
- `api/telegram-webhook.ts:59-110, 409-443` — Telegram cũng cộng điểm/đổi trạng thái.

Các luồng này không dùng một state machine/idempotency key chung. Cùng một click/retry/callback có thể cộng điểm hai lần, hoàn stock hai lần hoặc làm `totalOrders` sai. Cần một service chuyển trạng thái duy nhất.

#### P0.4 Mô hình role của Auth và Rules không khớp

`firestore.rules:isValidUser()` yêu cầu `role`, nhưng `src/contexts/AuthContext.tsx:56-70` tạo user mới không có `role`. Đồng thời UI admin dựa trên `adminPermissions` ở `AuthContext.tsx:90-132`, trong khi `isAdmin()` trong rules chủ yếu kiểm tra `users/{uid}.role == 'admin'` hoặc email super-admin. Vì vậy một user được cấp `adminPermissions` có thể thấy giao diện admin nhưng vẫn bị Firestore từ chối.

Kế hoạch chuẩn hóa:

- user mới luôn có `role: 'customer'` và `adminPermissions: null`.
- chỉ super-admin/role admin hợp lệ mới được cấp quyền.
- rules bảo vệ `uid`, `email` tùy chính sách, `role`, `createdAt` khỏi owner tự sửa.
- quyền UI chỉ là UX; quyền thật luôn do rules/backend quyết định.

#### P0.5 API notify và Telegram webhook chưa được bảo vệ

`api/notify.ts:13-125` nhận payload bất kỳ từ internet rồi gửi Telegram. Điều này cho phép spam bot, giả mạo đơn/review, và chèn HTML vào message. Endpoint không xác thực Firebase ID token, không rate-limit và không tự đọc order từ Firestore.

`api/telegram-webhook.ts:173-186` có `?setup=true` không yêu cầu secret; toàn bộ command/callback ở `:197-470` chưa kiểm tra chat ID hoặc Telegram user ID. Bất kỳ ai gọi được URL hoặc nhắn bot đều có thể thử cập nhật đơn. Cần:

- xóa `setup=true` public; set webhook bằng lệnh deploy có secret hoặc một endpoint admin có secret riêng.
- kiểm tra `X-Telegram-Bot-Api-Secret-Token`, `chat.id`, `from.id` trước khi xử lý.
- `escapeHtml()` cho mọi dữ liệu khách hàng trước khi gửi `parse_mode: HTML`.
- không nhận `amount/items/customerName` từ client để gửi; chỉ nhận `orderId`, sau đó server đọc order thật.
- callback phải dùng transaction/điều kiện trạng thái để không chạy lặp.

#### P0.6 Nội dung HTML được render trực tiếp

`src/components/BlogPostDetail.tsx:150`, `src/components/ProductDetail.tsx:498,553` dùng `dangerouslySetInnerHTML`. Nội dung do admin nhập nên vẫn cần sanitize/allowlist tag, attribute và URL trước khi lưu hoặc trước khi render. Đặc biệt phải chặn `javascript:` trong link, event handler và iframe ngoài allowlist.

### 3.3 Findings mức P1 — ảnh hưởng quota, độ ổn định và chi phí

#### P1.1 Listener trùng và listener mount quá rộng

- `Header.tsx:20` gọi `useNotifications()`.
- `NotificationDrawer.tsx:15` cũng gọi `useNotifications()` dù drawer đang đóng.
- `App.tsx:88` gọi `useSiteConfig()`, trong khi `ProductDetail` và `AdminSettings` có thể gọi lại cùng hook.
- `CartDrawer` và `Checkout` đều gọi `useShippingConfig()`.
- `Profile` gọi riêng `usePaymentConfig()`/`useRewardsConfig()` ngoài các hook đã mount ở vùng khác.

Kết quả là cùng một user có thể mở nhiều listener tới cùng document/query. Cần đưa dữ liệu dùng chung vào provider/cache cấp ứng dụng; notification chỉ subscribe khi user đã đăng nhập và drawer thật sự mở, hoặc dùng một listener duy nhất.

#### P1.2 Query toàn collection hoặc không có giới hạn

Các điểm đáng chú ý:

- `useProducts(false)` và `usePosts(true)` mở realtime listener toàn collection cho admin.
- `useOrders()` query toàn bộ `orders` để vừa hiển thị danh sách vừa tính revenue.
- `AdminPermissions` đọc toàn bộ users, toàn bộ delivered orders và có thể ghi hàng loạt trong một lần.
- `VoucherCenter` subscribe toàn bộ voucher public/active.
- `ProductReviews` đọc toàn bộ delivered orders của user để kiểm tra đã mua.
- checkout đọc toàn bộ lịch sử order trong check usage, customer type và risk score.

Phải thêm `limit`, cursor pagination, date/status filter và bỏ realtime ở các màn hình không cần. Doanh thu nên dùng aggregate/summary document hoặc truy vấn theo kỳ, không tải toàn bộ lịch sử mỗi lần mở tab.

#### P1.3 Client auto-seed default settings gây write thừa và lỗi quyền

`useSiteConfig`, `useNavigationConfig`, `useFooterConfig`, `usePaymentConfig`, `useProductConfig` đều có xu hướng `setDoc()` default khi document chưa tồn tại. Public visitor không phải admin sẽ bị từ chối write; nếu mở quyền để tránh lỗi thì visitor có thể ghi dữ liệu. Seed settings phải là bước migrate/deploy một lần, không nằm trong read hook.

#### P1.4 Health check Firestore trên mọi app load

`src/App.tsx:98-113` gọi `getDocFromServer(doc(db, 'test', 'connection'))` mỗi lần app mount. Collection `test` không có rules match và request không tạo giá trị nghiệp vụ. Xóa trong production hoặc chuyển thành nút diagnostic chỉ bật ở development.

#### P1.5 Checkout có read thừa và đọc ngoài transaction

Trước transaction, checkout đã đọc rate limit; khi áp voucher có thể đọc discount, order usage và lịch sử customer. Bên trong callback `runTransaction`, `calculateRiskScore()` lại gọi `getDocs()` ngoài `transaction.get()`. Điều này vừa tốn reads, vừa làm callback retry khó đoán. Risk score nên tính từ các field summary có sẵn hoặc xử lý trong order service trước/đúng transaction.

#### P1.6 Build hiện không tái lập được

Tại thời điểm review:

- `npm run lint` thất bại vì `tsc` chưa được cài.
- `npm run build` thất bại vì `vite` chưa được cài.
- `npm ci` thất bại vì lockfile thiếu `@floating-ui/dom@1.8.0` và các version `@floating-ui/core/utils` không khớp.
- `dist/` đang được commit, build gần nhất của `dist/index.html` ở commit `d784257` và không nên được coi là output tin cậy của source hiện tại.

Phải sửa lockfile bằng một lần `npm install` có review diff, sau đó bắt buộc `npm ci && npm run lint && npm run build` chạy được trong môi trường sạch.

#### P1.7 Media storage cần đổi khỏi Cloudinary unsigned upload

Cloudinary unsigned upload làm lộ upload preset trong frontend và có thể bị dùng để ăn quota ngoài ứng dụng. Với mục tiêu gom hạ tầng về Cloudflare, media mới nên chuyển sang R2:

- chỉ nhận ảnh raster cần thiết; chặn video trong flow production.
- Worker xác thực admin rồi cấp presigned `PUT` URL ngắn hạn; browser upload trực tiếp vào R2, không giữ R2 secret trong bundle.
- object key phải do server sinh, không dùng nguyên filename người dùng; lưu `objectKey`, MIME, kích thước và metadata cần thiết vào Firestore.
- production đọc ảnh qua custom domain có cache, không dùng `r2.dev`.
- chuẩn hóa các preset `hero`, `card`, `detail`, `avatar`; không cho frontend sinh width/quality tùy ý.
- nếu dùng Images Transformations, giới hạn số preset và unique transformations; không tạo biến thể theo từng DPR/width tự do.
- đặt giới hạn file, MIME thật, tổng storage và số lần cấp upload URL; có job/script dọn object mồ côi với dry-run.

R2 có free allowance lớn cho storefront nhỏ nhưng là dịch vụ usage-based. Budget alert chỉ thông báo, không phải hard cap; vì vậy guardrail phải nằm ở endpoint cấp URL, loại file, kích thước và quy trình kiểm tra usage. Nếu yêu cầu tuyệt đối không thể phát sinh billing, cần đánh giá lại R2 trước khi bật production.

#### P1.8 `dist/` và service worker có thể phục vụ bản cũ

`public/sw.js` dùng `tqs-*-v1` cố định và import Workbox từ CDN runtime. Có thể xảy ra stale cache hoặc không cài được SW khi CDN không truy cập được. Sau khi chốt deploy, version cache phải lấy từ build/release; không commit output cũ; cần test update trên browser thật.

### 3.4 Findings mức P2 — maintainability và dữ liệu

- `README.md` hướng dẫn `GEMINI_API_KEY`, nhưng source không import `@google/genai`; `vite.config.ts` vẫn expose biến build cũ.
- `package.json` có dependency có vẻ không dùng trực tiếp (`@google/genai`, `express`, `dotenv`, có thể `quill`); cần xác nhận bằng build trace rồi loại bỏ để giảm attack surface/bundle.
- `test-run.ts` là một webhook/test implementation khác, dễ bị nhầm với `api/telegram-webhook.ts`; tách hẳn vào `scripts/` hoặc loại khỏi production tree.
- `firebase-blueprint.json` chỉ mô tả Product/User/Order cũ, chưa mô tả posts, reviews, notifications, settings, rewards và các field hiện dùng.
- `DiscountCode` cho phép `freeship_only`, `Order` có các status `returned/refunded/failed_delivery`, nhưng `firestore.rules` chưa đồng bộ đầy đủ với type/UI.
- `AdminDatabaseRules` khuyến khích dán rules mở toàn quyền; phải biến thành trang kiểm tra phiên bản rules/deploy checklist, không hiển thị insecure snippet.
- Chưa thấy test rules, test order service, `firestore.indexes.json`, `.env.example` hoặc quy trình seed/migrate có kiểm soát.

## 4. Kiến trúc mục tiêu

### 4.1 Luồng dữ liệu đề xuất

```text
Browser
  ├─ Firebase Auth (Google)
  ├─ Firestore client: public catalog / own profile / own orders / public reviews
  ├─ POST /api/media/upload-url + Firebase ID token (admin only)
  ├─ presigned PUT trực tiếp vào Cloudflare R2
  ├─ đọc ảnh qua media custom domain + CDN cache
  └─ POST /api/orders + Firebase ID token
          │
          ├─ API/Worker xác thực token và idempotency key
          ├─ Đọc product/config thật
          ├─ Tính lại line items, discount, shipping, points
          ├─ Transaction: kiểm stock → trừ stock → tạo order → ghi usage
          └─ Gửi Telegram bằng order vừa đọc từ Firestore

Admin browser
  ├─ Đọc các trang order/user có phân trang
  ├─ Gọi order transition service duy nhất
  └─ Không tự cộng điểm, hoàn stock hoặc tự sửa payment status tùy ý
```

### 4.2 Lựa chọn hosting/API

#### Lựa chọn được khuyến nghị cho mục tiêu cửa hàng

- Frontend: Cloudflare static assets/Pages static nếu dùng cùng Worker; Firebase Hosting Spark vẫn là phương án thay thế.
- API: Cloudflare Worker/Pages Function Free, giữ API nhỏ và stateless; cần feasibility spike cho xác thực Firebase + Firestore REST trong giới hạn CPU.
- Media: Cloudflare R2 Standard cho object storage, presigned upload và custom domain; Cloudflare Images Transformations chỉ dùng với preset cố định.
- Firestore: Firebase Spark.
- Telegram: chỉ gửi message đơn lẻ tới chat admin, không broadcast.

Nếu dùng Cloudflare Worker, không đưa `firebase-admin` Node SDK/gRPC trực tiếp vào Worker. Tạo adapter dùng Firestore REST API và cơ chế service-account/JWT phù hợp runtime, hoặc giới hạn Worker ở các thao tác cần ID token/user rules và bỏ server-side admin mutation khỏi Worker. Credential phải được lưu bằng secret manager của platform, không commit JSON service account.

Trước Pha 3 phải có spike đo được: verify Firebase ID token, thực hiện một Firestore REST call và ghi nhận CPU time. Nếu flow này sát hoặc vượt giới hạn Worker Free, phải điều chỉnh adapter/runtime trước khi triển khai order service. Không đưa R2 secret xuống browser; endpoint upload chỉ cấp URL sau khi xác thực admin và áp dụng allowlist MIME/kích thước.

#### Lựa chọn tạm thời cho project cá nhân

Có thể giữ `api/*.ts` trên Vercel Hobby vì code hiện tại đang theo `VercelRequest/VercelResponse` và đã có `vercel.json`. Tuy nhiên, do Vercel ghi rõ Hobby dành cho personal/non-commercial use, lựa chọn này **không được đánh dấu đạt** nếu TQSShop là cửa hàng đang bán hàng thật. Không gắn billing để “lách” giới hạn; phải xác nhận điều khoản hoặc chuyển API sang lựa chọn phù hợp.

### 4.3 Collection/access matrix mục tiêu

| Collection | Public/guest | Customer | Admin/server | Ghi chú |
|---|---|---|---|---|
| `products` | Read active, chỉ field cần render | Như guest | Full CRUD; stock/order chỉ server hoặc admin action có kiểm tra | Không cho guest ghi stock. |
| `users/{uid}` | Không đọc | Owner đọc/sửa field profile được phép | Admin đọc; role/ban/permission qua transition có kiểm tra | Seed `role: customer`. |
| `orders` | Không đọc | Owner đọc; chỉ cancel order pending theo rule | Tạo/transition/stock/points qua order service | Không tin totals từ browser. |
| `discountCodes` | Chỉ read code public/active cần dùng | Read public; không tự tăng usage | CRUD và usage transaction | Không expose note/internal fields cho public. |
| `reviews` | Read published/public | Create nếu đã mua; owner sửa/xóa giới hạn | Reply/moderate | Purchase check nên dùng summary/endpoint, không quét toàn orders. |
| `posts` | Chỉ `published` | Như guest | CRUD | Không cho public tăng viewCount vô hạn. |
| `notifications` | Không | Đọc notification của chính mình, update `isRead` | Server/admin create | Bắt buộc `userId == request.auth.uid` cho read. |
| `settings/public` | Read | Read | Admin write | Gộp site/nav/footer/shipping/payment-safe để giảm reads/listener. |
| `settings/admin` | Không | Không | Admin read/write | Không đặt credential/payment secret ở đây. |
| `system/version` | Read hoặc bỏ hẳn | Read | Chỉ deploy/admin write | Không dùng làm trigger bắt buộc cho mọi client. |
| `system_settings/tiers_config` | Chỉ đọc các field cần render | Read | Admin write; order service đọc khi tính điểm | Tách config public nếu cần. |

### 4.4 State machine order mục tiêu

> [!IMPORTANT]
> Đây là state machine **draft** để triển khai schema/test. Gate 2 phải chốt chính sách after-sales trước khi implementation core của `orderService` bắt đầu. Không tự suy diễn transition chưa được policy cho phép.

```text
                  ┌──────────────► cancelled
pending ──────────┤
                  └──► processing ───► shipped ───► delivered ───► returned ───► refunded
                           │               │
                           └──► cancelled   └──► failed_delivery

suspicious ───► processing / cancelled
```

Quy tắc:

- `shipped → cancelled` không được mặc định cho phép. Gate 2 phải quyết định đơn đã giao vận đi qua `failed_delivery`, `returned` hoặc flow khác.
- `returned/refunded/failed_delivery` chỉ được bật khi policy hoàn stock, voucher, điểm, `totalOrders`, `totalSpent` và payment đã được chốt và có test.
- `cancelled`, `delivered`, reward, refund và stock restore phải idempotent; mọi side effect có marker/event tương ứng.
- Chỉ transition service được sửa `status`, `paymentStatus`, stock, voucher usage và reward totals.
- `totalOrders`/`totalSpent` chỉ thay đổi theo định nghĩa thống nhất ở Gate 2; không tăng/giảm ở nhiều caller.
- COD lúc tạo order là `paymentStatus: pending`; VietQR cũng pending cho tới khi nguồn xác nhận payment được Gate 2 chốt.
- Callback Telegram dùng `orderId + action + eventId`; nếu event đã xử lý thì trả success/no-op mà không chạy lại side effect.
- Canonical enum và `schemaVersion` của order phải dùng chung giữa TypeScript, API, Firestore Rules, migration và test.

## 5. Kế hoạch triển khai theo pha

### Pha 0 — Baseline, khóa phạm vi và làm build tái lập

**Mục tiêu:** Có baseline sạch trước khi đổi logic.

Thay đổi dự kiến:

- Đồng bộ `package.json`/`package-lock.json`; xác nhận Node/npm version.
- Thêm `.env.example` chỉ chứa tên biến, không chứa token.
- Cập nhật `README.md` theo Firebase/R2/Cloudflare Images/Telegram/hosting thật; bỏ hướng dẫn Gemini nếu không dùng.
- Xác nhận dependency bằng `rg` và build trace; loại package không dùng sau khi kiểm tra.
- Không coi `dist/` là source of truth; chọn rõ `dist` là build output và thêm ignore/CI deploy tương ứng.
- Thêm `firestore.indexes.json`, test command và script seed/migrate riêng.
- Tạo Worker feasibility spike: verify Firebase ID token, đọc một Firestore document qua adapter phù hợp runtime và ghi CPU time; xác nhận có thể chạy trong giới hạn Free trước khi xây order service.
- Chốt billing/usage policy của R2: bật budget alert, xác định ngưỡng storage/operations, giới hạn upload endpoint và ghi rõ R2 là usage-based chứ không phải hard cap.

Tiêu chí qua pha:

```text
npm ci
npm run lint
npm run build
```

đều pass trong thư mục sạch; `git diff` không có lockfile thay đổi ngoài phần đã review. Ngoài ra:

- Worker spike đã hoàn tất: xác thực Web Crypto RS256, authorize `role + adminPermissions`, đo CPU ~0.6ms, 1 subrequest (đạt Gate 1).
- Gate 2 đã có business policy được ký duyệt chính thức (2026-09-21).
- Gate 3 đã có runtime schema, event log, idempotency contract được ký duyệt (2026-09-21).
- `IMPLEMENTATION_PLAN_FREE_TIER.md` đã được commit vào Git; baseline `npm ci`, `lint`, `build` reproducible.
- **Pha 0 chính thức hoàn tất và đạt: Pha 0: PASS.**

### Pha 1 — Khóa security rules và chuẩn hóa Auth

**Mục tiêu:** Không có collection dùng trong code bị bỏ mặc; không còn `allow read, write: if true`.

Thay đổi dự kiến:

- Viết lại `firestore.rules` theo access matrix ở trên.
- Bổ sung match cho `posts`, `notifications`, `system`, `system_settings` hoặc xóa các luồng không cần.
- Sửa `AuthContext.tsx` tạo user có `role: 'customer'`, default arrays/numeric fields hợp lệ.
- Đồng bộ `role` và `adminPermissions`; cấp admin phải set cả role theo policy, không chỉ set field UI.
- Tách `settings/public` khỏi settings nội bộ; không public toàn bộ discount/internal settings.
- Xóa insecure rules snippet khỏi `AdminDatabaseRules.tsx`; thay bằng checklist, version hash và link tài liệu nội bộ.
- Thêm Firebase Emulator rules tests cho guest/customer/admin/server-like flows.

Tiêu chí qua pha:

- Guest không ghi được bất kỳ collection nào.
- Customer không đọc user/order khác, không sửa role/points/stock/order total.
- Non-admin không mở được admin data dù sửa UI state.
- Admin hợp lệ mở được đúng tab/quyền.
- Blog, notifications, rewards hoạt động không cần mở toàn quyền.

### Pha 2 — Giảm reads/writes để bảo vệ Spark quota

**Mục tiêu:** First load và navigation bình thường không tạo listener/query dư.

Thay đổi dự kiến:

- Tạo `PublicDataProvider` hoặc cache module cho một lần đọc `settings/public`.
- Tạo `ProductsProvider`/query layer dùng cache trước, server refresh theo TTL; thêm `limit`/cursor khi danh mục lớn.
- `usePosts()` public dùng published + `limit`, admin dùng pagination/manual refresh thay vì onSnapshot toàn collection.
- Chỉ có một `useNotifications` listener; chỉ activate khi đã login và drawer mở; giới hạn số notification gần đây.
- Bỏ auto-seed settings trong các hook read; seed bằng script một lần.
- Bỏ `getDocFromServer(test/connection)` khỏi `App.tsx` production path.
- `AdminOrders` và `AdminRevenueStatistics` dùng query layer có date/status/limit; không tải toàn bộ orders.
- `AdminPermissions` thay thao tác quét toàn DB bằng script dry-run/paginated batch, có hiển thị số lượng và confirm.
- `ProductReviews` không quét toàn bộ order ở mỗi product detail; tạo purchase summary hoặc endpoint kiểm tra tối thiểu.
- Checkout không scan toàn bộ lịch sử để tính risk/voucher; dùng field summary và backend validation.

Tiêu chí qua pha:

- Guest Home: tối đa 1 query catalog + 1 document public settings; không có public realtime listener nếu không cần.
- Guest Shop: query có giới hạn/cursor; không tải toàn bộ catalog không giới hạn.
- Customer Profile: tối đa một user listener và một order page query.
- Admin Orders: chỉ đọc page hiện tại; Revenue không query lại toàn collection cho mỗi lần đổi filter.
- Không có default write phát sinh từ anonymous page load.

### Pha 3 — Chuyển order/stock/voucher/reward sang service tin cậy

**Mục tiêu:** Browser không còn là nguồn sự thật về giá trị đơn hàng.

Thay đổi dự kiến:

- Tạo `orderService` có adapter cho platform API.
- API `POST /api/orders` nhận tối thiểu: cart item IDs, variant selections, shipping info, payment method, discount code, points requested, idempotency key.
- Server đọc product/config thật, validate product active, stock, variant, tier, voucher, usage limit, customer type và payment method.
- Server tính lại line total, discount, shipping, points discount, final amount.
- Dùng Firestore transaction/commit atomic cho stock, order, voucher usage, point deduction; event retry không nhân side effect.
- API trả order snapshot đã tính, không nhận `finalAmount` làm authoritative input.
- Chuyển status/paid/delivered/cancelled vào cùng service; xóa/disable logic trùng ở Profile, `useOrders` và webhook.
- Nếu vẫn cần direct client trong giai đoạn chuyển tiếp, rules phải khóa các field nhạy cảm và release phải được đánh dấu beta; không coi đó là production security.

Tiêu chí qua pha:

- Sửa request ở DevTools không thể giảm giá hoặc tăng điểm.
- Hai request cùng idempotency key tạo đúng một order.
- Hai khách mua item cuối cùng không làm stock âm.
- Voucher usage không vượt limit khi concurrent checkout.
- Cancel chỉ hoàn stock một lần.
- Delivered chỉ cộng điểm một lần; chuyển ngược trạng thái có policy rõ và test riêng.

### Pha 4 — Làm API và Telegram private, idempotent và không spam

**Mục tiêu:** Telegram là kênh nội bộ, không phải bề mặt tấn công.

Thay đổi dự kiến:

- Loại bỏ `api/notify.ts` nếu không còn caller bắt buộc; thông báo order phải được tạo từ order/transition service sau khi đọc dữ liệu thật. Nếu cần giữ endpoint cho review, chỉ nhận ID, xác thực token và server tự đọc dữ liệu.
- Xóa payload customer/items/amount tin cậy từ browser.
- Thêm secret token cho Telegram webhook và allowlist `chatId`/`userId`.
- Bỏ `?setup=true` hoặc bảo vệ bằng deploy secret; set webhook một lần ngoài public route.
- Tạo `escapeHtml` và giới hạn độ dài message/note/review.
- Dùng transition event id để callback trả success nhưng không lặp update/reward/restore stock.
- Rate-limit API notify và trả lỗi generic; không leak service-account/Firebase error.

Tiêu chí qua pha:

- Nếu còn giữ `/api/notify`, gọi endpoint không có auth không gửi message; nếu không còn caller thì file/route phải bị loại khỏi production.
- Webhook từ chat/user ngoài allowlist không thể đổi order.
- Dữ liệu có `<`, `>`, `&` không phá format Telegram.
- Retry Telegram không tạo duplicate reward/stock mutation.

### Pha 5 — Media, PWA và static hosting

**Mục tiêu:** dùng media storage có kiểm soát, giảm bandwidth và không để upload public ăn quota.

Thay đổi dự kiến:

- Tạo `/api/media/upload-url`: xác thực Firebase ID token + admin role, kiểm MIME/kích thước, sinh object key và cấp presigned R2 `PUT` URL với thời hạn ngắn.
- Browser upload trực tiếp vào R2; không đưa R2 access key/secret hoặc service credential vào frontend.
- Chỉ cho upload ảnh raster cần thiết; reject video/GIF/SVG nếu không có policy riêng; giới hạn file sau nén và tổng số upload.
- Đọc ảnh qua custom domain R2 có cache; không dùng `r2.dev` cho production.
- Dùng tối đa vài preset Images Transformations cố định (`hero`, `card`, `detail`, `avatar`); không sinh URL width/quality tùy ý.
- Không dùng `allowBase64: true` trong rich editor nếu có thể lưu base64 vào Firestore; lưu object URL/metadata sau upload, hoặc từ chối.
- Thêm script liệt kê object mồ côi và dọn có dry-run; không cho UI tự xóa hàng loạt.
- Cân nhắc bundle Workbox thay vì import CDN runtime; tăng cache version theo release.
- Chọn một static host: Firebase Hosting Spark nếu muốn cùng hệ Firebase; Cloudflare Pages nếu dùng Worker API.
- Thêm SPA fallback, security headers, cache headers cho immutable assets; không cache `/api`, Firestore và VietQR động.
- Xóa `dist/` commit sau khi CI/deploy đã lấy build mới, hoặc giữ lại có chủ đích nhưng phải có kiểm tra hash.

Tiêu chí qua pha:

- Ảnh product/card/detail hiển thị đúng preset R2/Images và cache hit ở lần truy cập sau.
- Không có R2 credential, presigned signing secret hoặc service account trong bundle frontend.
- Người không phải admin không thể cấp upload URL; file sai MIME/quá kích thước bị reject trước khi ghi vào R2.
- Usage guardrail chặn upload mới khi vượt ngưỡng nội bộ; object mồ côi có báo cáo và quy trình dọn an toàn.
- Tạo release mới làm client nhận asset mới và hiện update overlay đúng một lần.
- Offline fallback không làm checkout/QR dùng dữ liệu stale.

### Pha 6 — Observability không trả phí và cost guardrails

**Mục tiêu:** phát hiện gần quota trước khi dịch vụ bị ngắt.

Thay đổi dự kiến:

- Dashboard định kỳ: Firestore Usage, Firebase Auth, Hosting, R2 storage/Class A/Class B usage, Images transformations, Worker requests/CPU, Telegram errors.
- Log server chỉ chứa request ID, order ID, action và timing; không log token, password, service account, full address/phone nếu không cần.
- Thêm `health` endpoint không đọc Firestore; diagnostic Firestore chỉ chạy manual/admin.
- Thêm client error boundary và thông báo graceful khi quota/offline.
- CI chạy lint/build/rules tests; có smoke test deploy preview nếu platform cho phép.
- Đặt alert thủ công theo ngưỡng nội bộ ở mục 2.2; không tạo cron/monitor tốn phí khi chưa cần.

### Pha 7 — Migrate, rollout và rollback

**Mục tiêu:** chuyển dữ liệu hiện tại mà không mất order/user.

Trình tự:

1. Tạo branch `codex/free-tier-hardening` hoặc branch release tương đương.
2. Snapshot/export dữ liệu bằng script local có credential ngoài repo; không bật backup/PITR trả phí.
3. Dry-run migrate users: bổ sung `role`, `adminPermissions`, defaults; báo cáo record lỗi trước khi ghi.
4. Seed `settings/public`, `system_settings/tiers_config`, indexes và rules bằng quy trình có review.
5. Chạy rules tests và API order tests với emulator/test project, không dùng production để thử spam.
6. Deploy frontend/API bản canary; test guest, customer, admin, order COD, VietQR, voucher, cancel, delivered và Telegram.
7. Theo dõi quota/đơn lỗi trong 24–48 giờ; chỉ sau đó mới xóa code path cũ.
8. Rollback bằng release trước và disable endpoint mới; không dùng `git reset --hard` trên working tree người dùng.

## 6. Ma trận thay đổi theo file

`Severity` mô tả mức rủi ro nếu chưa xử lý; `Phase` mô tả thời điểm triển khai. Hai khái niệm này không được dùng thay thế cho nhau.

| File/khu vực | Việc phải làm | Severity | Phase |
|---|---|---:|---:|
| `package.json`, `package-lock.json`, `README.md`, `.env.example` | Baseline reproducible, dependency cleanup, docs/env/build commands | P0 | 0 |
| Worker spike/config thử nghiệm | Verify Firebase ID token, role/permission authorization, Firestore REST, đo CPU/subrequests/latency | P0 | 0 |
| `firestore.rules` | Bổ sung collection, khóa field, bỏ customer mutation stock/voucher/order sensitive fields, bỏ authorization bằng email hard-code sau migration | P0 | 1 |
| `src/contexts/AuthContext.tsx` | Seed user schema đầy đủ; đồng bộ `role/adminPermissions`; giảm duplicate user reads | P0 | 1 |
| `src/components/admin/AdminDatabaseRules.tsx` | Xóa snippet `allow read, write: if true`, thay bằng rules status/checklist | P0 | 1 |
| `src/components/Checkout.tsx` | Chuyển create order sang API; bỏ client-authoritative totals/risk/points/usage | P0 | 3 |
| `src/utils/useOrders.ts` | Chỉ gọi transition service; bỏ reward/stock side effects trực tiếp | P0 | 3 |
| `src/components/Profile.tsx` | Bỏ client tự delivered/cộng điểm; gọi transition endpoint duy nhất | P0 | 3 |
| `api/notify.ts` | Xóa nếu không còn caller; nếu giữ thì authenticated/internal only, nhận ID, tự đọc Firestore, escape/rate-limit | P0 | 4 |
| `api/telegram-webhook.ts` | Secret header, allowlist, idempotency, state machine, bỏ setup public | P0 | 4 |
| `src/components/BlogPostDetail.tsx`, `ProductDetail.tsx` | Sanitize HTML/URL trước khi render nội dung động | P0 | 1 |
| `src/hooks/useNotifications.ts` + `Header.tsx` + `NotificationDrawer.tsx` | Một listener, lazy subscribe, limit và owner rule | P1 | 2 |
| `src/hooks/use*Config.ts` | Gom public settings/cache; bỏ auto-seed writes; admin update explicit | P1 | 2 |
| `src/hooks/useProducts.ts`, `usePosts.ts` | limit/cursor/cache/refresh; admin không onSnapshot toàn collection | P1 | 2 |
| `src/utils/useOrders.ts`, `AdminRevenueStatistics.tsx` | query theo trang/kỳ hoặc summary docs; không tải toàn lịch sử | P1 | 2 |
| `src/components/AdminPermissions.tsx` | bỏ bulk scan/write mặc định; migrate script có dry-run/batch | P1 | 2/7 |
| `src/components/ProductReviews.tsx` | purchase summary/endpoint, limit reviews, tránh scan orders mỗi product | P1 | 2 |
| `src/App.tsx` | bỏ production Firestore test read; settings provider; update handling rõ | P1 | 2 |
| `public/sw.js`, `src/utils/swRegister.ts` | version cache/release gate, stale-client refresh, test offline/update | P0/P1 | 5/7 |
| `api/media/*`, media upload components | presigned R2 upload, admin auth, MIME/size/object-key validation, metadata và orphan cleanup | P1 | 5 |
| `wrangler.toml` hoặc Cloudflare config | R2 binding, static assets, Worker routes và secrets; không commit credential | P1 | 0/5 |
| `firebase-blueprint.json` | cập nhật hoặc thay bằng schema/access documentation hiện tại | P2 | 3 |
| `dist/` | bỏ khỏi source/deploy path hoặc tạo policy commit rõ ràng | P1 | 0/5 |
| `firestore.indexes.json` | index cho posts, orders, reviews, discount queries đã chốt | P1 | 0/2 |
| `tests/` hoặc `scripts/` | rules tests, order tests, migration/seed dry-run, quota smoke test | P0/P1 | 0-7 |
| `firebase.json`, `wrangler.toml` hoặc config hosting tương ứng | cấu hình deploy duy nhất, không deploy nhầm artifact stale | P1 | 5/7 |

## 7. Test plan và tiêu chí nghiệm thu cuối

### 7.1 Security/rules tests

- Guest: read active products/public settings/published posts/public reviews; không read users/orders/notifications/internal settings.
- Customer A: không read order/user/notification của B.
- Customer: không sửa `role`, `points`, `totalSpent`, `totalOrders`, `stock`, `finalAmount`, `paymentStatus` hoặc `status` trái transition.
- Admin: chỉ có quyền theo `role + adminPermissions`; mất quyền thì request bị deny dù UI vẫn bị sửa.
- Không collection nào cần mở `allow read, write: if true`.
- Rules query phải test cả allow và deny, không chỉ get một document.

### 7.2 Order/integrity tests

- Client sửa giá trong request → server từ chối hoặc server tính lại đúng.
- Client gửi discount amount/final amount giả → không ảnh hưởng order.
- Product inactive/stock thiếu/variant sai → transaction fail, stock không đổi.
- Hai checkout đồng thời cho stock cuối → tối đa một order thành công.
- Retry cùng idempotency key → một order, một usage, một lần trừ điểm.
- Cancel callback lặp → stock chỉ hoàn một lần.
- Delivered callback từ UI và Telegram đồng thời → điểm chỉ cộng một lần.
- COD/VietQR payment status đúng policy; khách không tự mark paid.

### 7.3 Free-tier/read budget tests

- Home/Shop không mở duplicate listener khi route remount.
- Header + NotificationDrawer chỉ tạo một notification subscription.
- Public settings không auto-write khi guest mở site.
- Orders/admin có limit/cursor/date filter.
- Voucher query không tải toàn bộ internal/inactive codes.
- Test bằng Firebase Emulator hoặc test project để đo số request trước/sau refactor.

### 7.4 Deploy/smoke tests

- `npm ci`, `npm run lint`, `npm run build` trên máy sạch.
- SPA refresh trực tiếp tại `/shop`, `/product/:id`, `/blog/:slug`, `/admin` không 404.
- SW update không giữ JS cũ sau release.
- R2 missing binding/config hiển thị lỗi thân thiện; không crash admin.
- Media upload dùng presigned URL, không lộ credential; custom domain trả ảnh với cache headers đúng.
- Telegram webhook với secret sai/actor ngoài allowlist bị reject.
- Không có token, service account JSON, Firebase private key hoặc credential trong bundle/log/git.

### 7.5 Definition of Done

Chỉ đánh dấu hoàn thành khi tất cả điều kiện sau đúng:

1. Build sạch và lockfile reproducible.
2. Rules tests pass, không còn wildcard allow toàn quyền.
3. Order create/transition/reward/stock có một nguồn xử lý và idempotency.
4. Anonymous/customer/admin flows đều qua smoke test.
5. Read/write budget đạt ngưỡng nội bộ trong kịch bản tải thử.
6. Firestore/hosting/API nằm trong free quota; R2/Images usage nằm dưới ngưỡng nội bộ, có budget alert và đã ghi nhận rõ rằng R2 là usage-based, không có hard spending cap.
7. Có README vận hành: deploy, seed, rollback, quota check, secret rotation.
8. Có quyết định bằng văn bản về hosting: Vercel Hobby chỉ cho personal, còn storefront public dùng lựa chọn không vướng giới hạn commercial đã nêu.

## 8. Thứ tự triển khai và deploy thực tế (12 bước)

> [!IMPORTANT]
> **Quy tắc triển khai an toàn:** Rules restrictive được viết và test sớm trên Emulator, nhưng chỉ deploy Production sau khi API mới và frontend mới đã smoke test thành công. Rollout đồng thời phải chặn client/service worker quá cũ tiếp tục mutation; không để một cửa sổ mà client cũ vẫn có thể checkout hoặc đổi trạng thái bằng đường legacy.

Thứ tự 12 bước chuẩn:

1. **Build baseline:** Sửa lockfile, xác nhận Node/npm version, loại dependency dư thừa đã kiểm chứng, pass `npm ci`, `npm run lint`, `npm run build`. Chỉ sau bước này mới được đánh dấu Pha 0 baseline pass.
2. **Worker feasibility + authorization spike:** Verify Firebase ID token, đọc/ghi Firestore REST, resolve `role/adminPermissions`, enforce một action customer và một action admin; đo CPU/subrequests/latency và ghi kết quả.
3. **Đóng Gate 2 + Gate 3:** Chốt business policy; canonical enums; `schemaVersion`; schema `orders/{orderId}/events/{eventId}` và `idempotency`; viết Rules/API contract tests trước implementation core.
4. **Order service:** Xây core transition logic, server-authoritative totals, atomic transaction, authorization, request fingerprint và idempotency. Không viết business branch chưa được Gate 2 định nghĩa.
5. **Migrate callers sang service:** Chuyển Checkout, Profile, Admin, Telegram webhook sang API/service mới; legacy direct mutation được đặt sau feature flag/kill-switch.
6. **Integration test:** Chạy Emulator/test project cho guest/customer/admin, COD, VietQR, voucher, points, concurrency, duplicate callback, after-sales đã bật và rollback compatibility.
7. **Deploy API mới:** Deploy Worker/API; bật logging tối thiểu và kill-switch; giữ legacy path tạm thời chỉ để rollback có kiểm soát, không public thêm capability mới.
8. **Deploy frontend + release gate:** Frontend mới gọi API mới; publish `minimumClientVersion`/release marker hoặc cơ chế tương đương. Tab/service worker quá cũ phải reload hoặc bị chặn checkout/admin mutation. Smoke test API mới trước khi sang bước 9.
9. **Deploy Rules restrictive ngay sau smoke test:** Khóa client-side mutation stock, voucher usage, totals, payment/status/reward và các field nhạy cảm. Kiểm tra stale client fail closed; xác nhận frontend/API hiện tại vẫn pass smoke test.
10. **Disable/remove legacy mutation:** Gỡ code path direct mutation và endpoint public cũ như `api/notify.ts`; xác nhận không còn caller bằng source search + smoke test.
11. **Canary + rollback rehearsal:** Bật nhóm nhỏ, theo dõi quota/error/Telegram; thử kill-switch và xác nhận release cũ có thể đọc an toàn `schemaVersion` mới hoặc adapter xử lý được. Không đảo side effect dữ liệu bằng thao tác tay hàng loạt.
12. **Production rollout:** Mở toàn diện sau khi Gate 4 pass; theo dõi quota/usage, giữ event audit, budget alert và runbook deploy/rollback/secret rotation.

## 9. Quyết định cần chốt trước khi viết business logic production

1. TQSShop là project cá nhân/demo hay cửa hàng thương mại thật? Nếu là thương mại thật, không lấy Vercel Hobby làm phương án production mặc định.
2. Có chấp nhận bỏ Telegram inline actions ở phiên bản free đầu tiên để giảm backend complexity không, hay bắt buộc giữ đủ `/don`, `/tracking`, `/thongke`, callback status?
3. Số lượng product/order dự kiến trong 30 ngày đầu là bao nhiêu? Con số này quyết định có cần summary docs ngay từ P1 hay chỉ cần pagination.
4. Có cần upload video/hero animation không? Với R2 free allowance, khuyến nghị tắt video upload và chỉ dùng ảnh/YouTube embed.
5. Chính sách điểm: cộng khi admin chuyển delivered hay khi khách xác nhận? Chỉ được chọn một nguồn sự thật.
6. Chính sách after-sales: `shipped`, `failed_delivery`, `delivered`, `returned`, `refunded` được chuyển thế nào; mỗi transition đảo stock/voucher/points/payment/`totalSpent` ra sao.
7. Cơ chế release gate cho client cũ: chọn `minimumClientVersion`, config/version document, API header version hoặc cơ chế tương đương để stale tab/service worker fail closed.

Nếu chưa có câu trả lời khác, mặc định triển khai theo lựa chọn an toàn hơn: **Firebase Spark + Cloudflare static + Cloudflare Worker API tối thiểu + R2 ảnh-only qua presigned upload + Cloudflare Images preset cố định + Telegram admin allowlist**, với client không còn quyền tự quyết định tiền và reward. Firebase Hosting Spark vẫn là phương án thay thế cho static hosting. R2 chỉ được bật production sau khi đã xác nhận policy billing/alert và guardrail usage phù hợp với yêu cầu chi phí.
