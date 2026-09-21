# Order domain gates

Bộ tài liệu này là baseline nghiệp vụ và dữ liệu cho Order Service v1 của TQSShop.

| Tài liệu | Vai trò | Trạng thái |
|---|---|---|
| [Gate 2 — Order & after-sales business policy](./GATE_2_ORDER_BUSINESS_POLICY.md) | Chốt semantics của vòng đời đơn, thanh toán, kho, voucher, điểm và hậu mãi | **Signed off (2026-09-21)** |
| [Gate 3 — Order schema, events & idempotency](./GATE_3_ORDER_SCHEMA.md) | Schema `schemaVersion: 1`, canonical enums, event log và idempotency contract | **Signed off (2026-09-21)** |

## Cách sử dụng

1. Gate 2 và Gate 3 đã được business owner & architecture team chính thức phê duyệt (2026-09-21).
2. Các enum, invariant và transition matrix đã trở thành contract runtime bắt buộc cho API, TypeScript, Firestore Rules và test.
3. Mọi thay đổi sau sign-off phải đi qua một decision record mới và tăng `schemaVersion` nếu thay đổi shape hoặc semantics của order.

## Baseline đã được phê duyệt

- Stock được reserve/trừ atomically ngay khi order được tạo thành công.
- VietQR pending giữ stock trong 30 phút (`paymentDueAt = createdAt + 30m`).
- Điểm thưởng chỉ được cấp khi trusted service chuyển order sang `delivered`.
- VietQR chỉ được xác nhận `paid` bởi payment provider đã verify hoặc admin mutation có audit event; client không được tự xác nhận.
- Voucher usage và points đã dùng được hoàn lại một lần nếu order bị hủy trước khi shipment.
- Return window mặc định 7 ngày kể từ `deliveredAt`. Lỗi shop hoàn full ship, đổi ý khách chịu ship.
- V1 chỉ hỗ trợ full-order return/refund; partial return là phạm vi sau.
- COD giao thất bại đi qua `failed_delivery`, không hoàn stock ngay.
- Return/refund sau delivery sẽ đảo reward và customer statistics.
- Order cũ không có `schemaVersion` được đọc qua adapter legacy và không được tự động suy đoán các side-effect marker còn thiếu.
