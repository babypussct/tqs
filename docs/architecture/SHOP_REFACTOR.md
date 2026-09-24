# TQSShop — kiến trúc sau refactor

Tài liệu này mô tả boundary runtime hiện tại sau đợt thống nhất mã nguồn. Mục tiêu
là để các thay đổi tiếp theo đi qua đúng lớp, không quay lại mô hình mỗi component
tự đọc/ghi Firestore và tự tính tiền.

## 1. Boundary chính

| Lớp | Trách nhiệm | Điểm vào chính |
|---|---|---|
| UI/route | Render, nhập liệu, optimistic preview; không quyết định giá cuối hoặc side effect tài chính | `src/components`, `src/App.tsx` |
| Shared UI data | Chuẩn hóa ngày, tiền, order legacy và cart key | `src/shared/` |
| Order domain | Giá server-authoritative, money breakdown, state machine, stock, voucher, points, idempotency và audit event | `src/order/` |
| API command | Xác thực Firebase ID token, rate-limit, transaction và gọi domain service | `api/orders.ts`, `api/vouchers.ts`, `api/reviews.ts`, `api/post-view.ts` |
| Firebase adapter | Một nơi khởi tạo Admin SDK và chuyển ISO/domain date ↔ Firestore Timestamp | `api/_lib/` |
| Firestore | Rules khóa direct mutation, indexes cho các query chuẩn và schema v1 | `firestore.rules`, `firestore.indexes.json` |

## 2. Luồng checkout chuẩn

```text
CartItem (client preview)
        │
        ├── POST /api/orders?action=quote ──┐
        │                                   │
        │                         quoteOrder + pricing + money
        │                                   │
        └── POST /api/orders ───────────────┘
                    │
          authenticateActor + rate limit
                    │
       Firestore transaction + createOrder
                    │
     canonical order + event + idempotency
```

Client chỉ gửi `productId`, số lượng và lựa chọn sản phẩm. `price`, stock,
shipping, voucher eligibility, points và `finalAmount` đều được tính lại ở
server. Cùng một `idempotencyKey` với payload khác bị từ chối; retry cùng payload
được replay mà không trừ stock/điểm/voucher lần hai.

## 3. Contract dữ liệu

- Order mới dùng `schemaVersion: 1`, `currency: 'VND'`, `unitPrice` và `lineTotal`.
- `createdAt`, `updatedAt`, các side-effect marker, event và idempotency expiry
  được ghi xuống Firestore dưới dạng `Timestamp`.
- Order cũ được đọc qua `normalizeLegacyOrder`; adapter không đoán các marker bị
  thiếu, nên không tự coi stock/reward đã chạy.
- Voucher date chấp nhận cả Firestore Timestamp, `Date` và chuỗi ISO ở boundary,
  nhưng create-order và quote dùng cùng quy tắc kiểm tra.
- Cart key sắp xếp variant/accessory trước khi encode để cùng một cấu hình không
  tạo hai dòng giỏ hàng khác nhau chỉ vì thứ tự object key.

## 4. Mutation và authorization

- Khách hàng tạo/quote order, lưu voucher và tạo review qua API có Firebase ID
  token.
- Admin/Telegram cũng đi qua `transitionOrder`; các transition có permission,
  state machine, audit event và idempotency.
- Firestore Rules vẫn là lớp fail-closed cho client; Admin SDK không được coi là
  authorization. API phải xác thực actor và kiểm tra quyền trước khi chạy domain.
- Public view tracking là endpoint riêng, chỉ chấp nhận post đã publish và không
  mở quyền update trực tiếp cho browser.
- Settings protected không còn được public read tự động seed bằng `setDoc`.

## 5. Rollout/migration bắt buộc

1. Deploy `firestore.rules` và `firestore.indexes.json` từ commit đã review.
2. Copy cấu hình cũ `settings/shipping` sang canonical
   `system_settings/shipping_config` trước khi bật checkout mới. API còn fallback
   đọc cấu hình cũ để giảm rủi ro trong giai đoạn chuyển tiếp; write mới chỉ ghi
   canonical path.
3. Giữ các order legacy trong read path; không backfill side-effect marker bằng
   suy đoán. Chỉ migration khi có dry-run, snapshot và rollback plan riêng.
4. Cấu hình server-only: Firebase Admin credential, `APP_ORIGIN`, Telegram
   webhook secret/chat allowlist và R2 variables. Không đưa các secret này vào
   biến Vite/client.
5. Chạy kiểm tra trước deploy:

   ```bash
   npm ci
   npm run lint
   npm run test:all
   npm run build
   ```

6. Smoke test trên staging: login, quote, tạo COD/VietQR, retry cùng key, stock
   thiếu, voucher expired/scope sai, review chưa mua hàng, callback Telegram và
   admin transition.

## 6. Hạng mục còn lại sau đợt refactor lõi

- Build vẫn cảnh báo chunk vendor lớn (`vendor-ui` khoảng 984 kB và
  `vendor-firebase` khoảng 551 kB); có thể tách tiếp theo route nếu cần tối ưu
  tải lần đầu.
- `AdminDashboard` và một số màn hình legacy vẫn là component lớn về mặt vật lý;
  đây là việc tách module UI tiếp theo, không còn là boundary dữ liệu/security.
- Chưa chạy deploy production, commit hoặc push từ workspace này. Cần chọn target
  hosting và cung cấp môi trường/secret tương ứng trước khi thực hiện bước đó.
