# Order domain gates

Bộ tài liệu này là baseline nghiệp vụ và dữ liệu cho Order Service v1 của TQSShop.

| Tài liệu | Vai trò | Trạng thái |
|---|---|---|
| [Gate 2 — Order & after-sales business policy](./GATE_2_ORDER_BUSINESS_POLICY.md) | Chốt semantics của vòng đời đơn, thanh toán, kho, voucher, điểm và hậu mãi | Draft for sign-off |
| [Gate 3 — Order schema, events & idempotency](./GATE_3_ORDER_SCHEMA.md) | Schema `schemaVersion: 1`, canonical enums, event log và idempotency contract | Draft for sign-off |

## Cách sử dụng

1. Business owner review các mục **Decision** trong Gate 2.
2. Chỉ khi Gate 2 được chấp thuận mới chuyển Gate 3 thành contract bắt buộc cho API, TypeScript, Firestore Rules và test.
3. Không triển khai `orderService` production dựa trên một branch chưa có sign-off cho hai tài liệu này.
4. Mọi thay đổi sau sign-off phải đi qua một decision record mới và tăng `schemaVersion` nếu thay đổi shape hoặc semantics của order.

## Baseline đang được giả định

- Stock được reserve/trừ atomically ngay khi order được tạo thành công.
- Điểm thưởng chỉ được cấp khi trusted service chuyển order sang `delivered`.
- VietQR chỉ được xác nhận `paid` bởi payment provider đã verify hoặc admin mutation có audit event; client không được tự xác nhận.
- Voucher usage và points đã dùng được hoàn lại một lần nếu order bị hủy trước khi shipment.
- V1 chỉ hỗ trợ full-order return/refund; partial return là phạm vi sau.
- Order cũ không có `schemaVersion` được đọc qua adapter legacy và không được tự động suy đoán các side-effect marker còn thiếu.
