# Gate 2 — Order & after-sales business policy

> **Status:** SIGNED OFF / APPROVED
>
> **Version:** `1.0`
>
> **Ngày phê duyệt:** 2026-09-21
>
> **Decision Owners:** TQS Business Owner & Engineering Lead
>
> **Phạm vi:** Order Service v1, `schemaVersion: 1`

Tài liệu này chốt semantics nghiệp vụ trước khi viết transaction và transition service. Toàn bộ các quyết định nghiệp vụ D2.1–D2.15 đã được business owner và technical lead phê duyệt chính thức làm policy baseline bất biến cho V1.

## 1. Nguyên tắc bắt buộc

1. **Server là nguồn sự thật.** Giá, stock, discount, points, payment status, reward và transition không được lấy từ giá trị tính ở browser làm authoritative input.
2. **Một transition service duy nhất.** Checkout, Profile, Admin UI, Telegram và webhook thanh toán chỉ tạo command; không luân phiên tự sửa order, stock hoặc user stats.
3. **Mỗi mutation có idempotency.** Retry do double-click, refresh, network timeout hoặc callback lặp phải trả lại kết quả cũ hoặc no-op; không được nhân side effect.
4. **Order event là audit log append-only.** Event ghi actor, lý do, state trước/sau và side effects; không sửa/xóa event để “sửa lịch sử”.
5. **Không dùng trạng thái giao hàng để suy đoán thanh toán.** COD và VietQR có payment lifecycle riêng; chỉ những transition được policy cho phép mới đồng bộ hai lifecycle.
6. **Legacy fail closed.** Order cũ thiếu marker không được tự động hoàn kho, hoàn điểm hoặc hoàn tiền dựa trên suy đoán. Phải có reconciliation/override có audit.

## 2. Thuật ngữ và số tiền authoritative

Order Service tính lại toàn bộ số tiền từ product/config hiện tại tại thời điểm tạo order. Client chỉ gửi product IDs, lựa chọn variant, số lượng, shipping info, payment method, voucher code, số points muốn dùng và idempotency key.

| Tên | Semantics |
|---|---|
| `totalAmount` | Merchandise subtotal: tổng `unitPrice × quantity` sau khi resolve variant, trước shipping và discount. Giữ tên này để tương thích với model hiện tại. |
| `shippingFee` | Phí giao hàng được server tính. |
| `voucherDiscountAmount` | Giảm giá từ voucher, bao gồm freeship nếu policy của voucher cho phép. |
| `pointsDiscountAmount` | Giá trị tiền của points đã dùng. |
| `discountAmount` | Compatibility field = `voucherDiscountAmount + pointsDiscountAmount`. Không dùng field này làm input tin cậy. |
| `finalAmount` | Số tiền khách phải thanh toán bằng tiền: `max(0, totalAmount + shippingFee - voucherDiscountAmount - pointsDiscountAmount)`. |
| `rewardEligibleAmount` | Cơ sở tính tier/reward: `max(0, totalAmount - voucherDiscountAmount - pointsDiscountAmount)`, không gồm shipping và không tính phần thanh toán bằng points. |
| `paidAmount` | Số tiền thật đã thu. Có thể là `0` với COD chưa giao hoặc order bị hủy trước khi thu. |
| `refundAmount` | Số tiền thật sẽ/đã hoàn qua payment method; không phải số points được trả lại. |

V1 không hỗ trợ partial return/refund. Nếu sau này cần hoàn một phần, phải bổ sung item-level return allocation và tăng schema version hoặc có adapter tương thích.

## 3. Canonical lifecycle

### 3.1 Order status

| Status | Ý nghĩa | Có phải terminal không? |
|---|---|---:|
| `pending` | Order hợp lệ đã reserve stock, đang chờ xử lý. COD chưa thu tiền; VietQR thường đang chờ thanh toán. | Không |
| `suspicious` | Risk score vượt ngưỡng hoặc cần manual review. Stock vẫn được giữ. | Không |
| `processing` | Admin đã duyệt và kho đang chuẩn bị hàng. | Không |
| `shipped` | Hàng đã bàn giao cho đơn vị vận chuyển. | Không |
| `failed_delivery` | Đơn vị vận chuyển giao thất bại; hàng chưa được xác nhận về kho. | Không |
| `delivered` | Khách đã nhận hàng. Đây là điểm kích hoạt reward và thống kê order/spend. | Không, còn after-sales |
| `returned` | Hàng đã được nhận lại và kiểm tra; đang chờ/đã sẵn sàng cho bước hoàn tiền. | Không, nếu còn refund |
| `cancelled` | Order bị hủy trước khi hoàn tất giao hàng hoặc do unpaid timeout. | Có |
| `refunded` | After-sales đã đóng; hoàn tiền đã hoàn tất hoặc xác nhận không có khoản tiền cần hoàn. | Có |

`cancelled` không được dùng để biểu diễn return sau `shipped`. Sau khi đã bàn giao cho carrier phải đi qua `failed_delivery` hoặc after-sales path.

### 3.2 Payment status

| Status | Ý nghĩa |
|---|---|
| `pending` | Chưa xác nhận đã thu tiền. Đây là giá trị tạo mặc định cho cả COD và VietQR. |
| `paid` | Đã xác minh đã thu đủ `finalAmount` hoặc số tiền được chấp nhận theo exception policy. |
| `failed` | Payment attempt thất bại/không hợp lệ; không được coi là đã thu tiền. |
| `refund_pending` | Có khoản tiền cần hoàn nhưng provider/cash operation chưa hoàn tất. |
| `refunded` | Khoản tiền cần hoàn đã được xác nhận hoàn tất. Với COD chưa thu tiền, payment status có thể vẫn là `pending` khi order status đóng là `refunded`. |

## 4. Các quyết định nghiệp vụ

Các lựa chọn dưới đây là baseline an toàn cho V1. Mỗi dòng là một **Decision** cần business owner xác nhận.

| Decision | Policy V1 |
|---|---|
| **D2.1 — Khi nào trừ stock?** | Reserve/trừ stock trong cùng transaction tạo order. Không chờ admin confirm hoặc payment thành công. Vì order đã chiếm hàng, hai checkout cạnh tranh không thể cùng lấy item cuối. |
| **D2.2 — Order VietQR chưa thanh toán giữ hàng bao lâu?** | Giữ trong `paymentDueAt = createdAt + 30 phút`. Khi có mutation/reconciliation sau deadline, service chạy `expire_payment` idempotently và chuyển `cancelled`; không yêu cầu cron để đảm bảo correctness. Scheduler nếu có chỉ là tối ưu. |
| **D2.3 — Khi nào khách được hủy?** | Customer chỉ được hủy `pending` hoặc `suspicious`, trước khi shipment. Không cho customer hủy `processing`, `shipped`, `delivered`, `failed_delivery`, `returned` hoặc order đã đóng. |
| **D2.4 — Khi nào admin được hủy?** | Admin được hủy `pending`, `suspicious`, `processing` với reason bắt buộc. Sau `shipped` phải dùng `failed_delivery`/return; không đổi ngược về `cancelled`. |
| **D2.5 — Voucher usage tính lúc nào?** | Reserve/increment usage trong transaction tạo order, sau khi validate toàn bộ điều kiện. Không đợi payment thành công vì order đã giữ quota voucher. Client không được tự increment. |
| **D2.6 — Hủy có hoàn voucher không?** | Có, đúng một lần nếu order bị cancel/payment timeout trước `shipped`. Voucher được trả lại quota và usage của user trở nên eligible lại. Sau `shipped` không hoàn voucher usage trong V1. |
| **D2.7 — Points dùng trong checkout xử lý thế nào?** | Deduct atomically khi tạo order. Nếu cancel/payment timeout trước `shipped`, hoàn đúng số points một lần. Sau `shipped`, points đã dùng không hoàn trong V1; giá trị tiền refund được tính riêng. |
| **D2.8 — Khi nào cộng reward?** | Chỉ khi trusted service chuyển `shipped → delivered`. Customer không được tự xác nhận delivered để tự cộng điểm. COD chỉ được coi là đã thu tiền khi giao thành công, trừ exception có audit. |
| **D2.9 — Return/refund có đảo reward không?** | Có. Khi order đã `delivered` rồi được chấp nhận return/refund, đảo `earnedPoints`, `totalSpent` và `totalOrders` đúng một lần. Nếu balance points hiện tại không đủ, ghi `rewardReversalDebt` để trừ vào các lần cộng sau; không cho balance âm. |
| **D2.10 — VietQR chuyển sang paid bằng gì?** | V1: verified payment webhook nếu đã tích hợp; nếu chưa, admin endpoint có auth + reason + audit event. Không chấp nhận field từ browser. Callback Telegram chỉ là adapter gọi cùng command service. |
| **D2.11 — COD giao thất bại xử lý thế nào?** | Chuyển `shipped → failed_delivery`; không cộng reward, không hoàn stock ngay. Admin có thể retry `failed_delivery → shipped`. Khi hàng thật sự về kho, chuyển `failed_delivery → returned` và kiểm kê trước khi hoàn stock. |
| **D2.12 — Sau shipped có được cancel không?** | Không. Đường chuẩn là `shipped → failed_delivery → returned → refunded` hoặc `shipped → delivered → returned → refunded`. |
| **D2.13 — Return window là bao lâu?** | Mặc định 7 ngày lịch kể từ `deliveredAt`, lưu trong `returnEligibleUntil`/decision snapshot của order. V1 chỉ full-order return; admin phải ghi reason và kết quả kiểm hàng. Đây là business default, không phải kết luận pháp lý. |
| **D2.14 — COD chưa thu nhưng return/refund?** | Không có tiền để hoàn: `refundAmount = 0`, không set `paymentStatus = refunded` chỉ để làm đẹp UI. Order vẫn có thể đóng `refunded` sau khi after-sales đã hoàn tất với payment status `pending`. |
| **D2.15 — Tính `totalOrders`/`totalSpent` khi nào?** | Chỉ order `delivered` chưa bị return/refund mới được tính. `totalSpent` cộng `rewardEligibleAmount`, không cộng shipping và không cộng phần points discount. Return/refund đảo đúng snapshot cũ, không tính lại theo config hiện tại. |

## 5. Payment policy

### 5.1 COD

- Tạo order: `paymentStatus = pending`, dù UI hiện phương thức COD.
- `shipped → delivered` có thể set `paymentStatus = paid`, `paidAmount = finalAmount` trong cùng transition transaction.
- Admin có thể xác nhận thu tiền sớm chỉ qua command được authorize; phải ghi `payment_confirmed` event và reason. Nếu order sau đó bị hủy, phải phát sinh refund workflow thay vì xóa marker.
- `failed_delivery` không tự biến thành `paid`.

### 5.2 VietQR

- Tạo order: `paymentStatus = pending`, `paymentDueAt` được set.
- Chỉ payment provider đã verify hoặc admin có permission mới được ghi `paid`.
- `processing`/`shipped` yêu cầu `paymentStatus = paid`, trừ exception super-admin có reason và event riêng.
- Sau `paymentDueAt`, service có thể chuyển `pending/suspicious → cancelled` bằng action `expire_payment`; stock, voucher usage và points đã dùng được hoàn một lần.
- Payment callback đến sau khi order đã cancelled không được mở lại order. Nếu provider xác nhận đã thu tiền, tạo `refund_pending`/manual refund task.

## 6. Stock, voucher và points side effects

### 6.1 Stock

1. Create order: giảm stock theo tổng quantity của từng product trong một transaction; set `stockReservedAt`.
2. Cancel trước shipment: tăng stock đúng quantity đã reserve; set `stockRestoredAt` và `stockRestoredReason`.
3. Failed delivery: không tăng stock vì hàng có thể vẫn đang trên đường.
4. Return: chỉ tăng stock cho item được kiểm tra là `sellable`. Item hỏng/mất ghi disposition riêng và không tự cộng lại.
5. Mỗi order chỉ có tối đa một logical stock restore. Retry nhìn marker/event cũ và no-op.

### 6.2 Voucher

- `usedCount` và usage-per-user được reserve cùng create order.
- Cancel/payment timeout trước shipment tạo một release event và hoàn đúng một usage.
- Return/refund sau shipment không hoàn usage trong V1.
- Nếu transaction tạo order fail, không có usage nào được ghi.
- Không cho phép một order dùng đồng thời hai voucher code; points là discount component riêng.

### 6.3 Points đã dùng và reward earned

- `pointsApplied` bị trừ atomically; server tự giới hạn theo balance và policy max discount.
- Pre-shipment cancel/payment timeout hoàn đúng `pointsApplied` một lần.
- `rewardEligibleAmount` snapshot tại lúc create để không bị thay đổi bởi config về sau.
- Khi delivered, tính `earnedPoints` từ snapshot reward config + `rewardEligibleAmount`; set `rewardGrantedAt` cùng user ledger update.
- Khi return/refund, tạo reversal với reference tới event cấp điểm ban đầu. Không dùng `increment(-earnedPoints)` mù quáng nếu balance không đủ; dùng debt/ledger rule để bảo toàn invariant balance không âm.

## 7. After-sales và refund

### 7.1 Chuỗi chuẩn

```text
shipped ──delivery failed──> failed_delivery ──physical return──> returned ──refund done──> refunded
   │
   └──delivered──> delivered ──approved return + received──> returned ──refund done──> refunded
```

`delivered → refunded` trực tiếp chỉ dành cho exception do super-admin, phải có reason; nếu exception này ảnh hưởng reward thì vẫn phải chạy reward reversal. Không được dùng đường tắt để bỏ qua audit.

### 7.2 Kiểm hàng và hoàn kho

V1 full-order return yêu cầu admin ghi:

- `returnReason`: `defective`, `wrong_item`, `transit_damage`, `change_of_mind`, `other`;
- `receivedAt` và actor nhận hàng;
- `stockDisposition`: `sellable`, `damaged`, `lost`, hoặc map theo item;
- ghi chú ngắn, không đưa dữ liệu nhạy cảm không cần thiết vào event.

Return do `defective`, `wrong_item` hoặc `transit_damage` được coi là merchant fault. `change_of_mind` không được tự suy ra là merchant fault.

### 7.3 Công thức refund V1

- Hủy trước shipment: hoàn toàn bộ `paidAmount` thực tế đã thu, bao gồm shipping đã trả; voucher/points được release theo D2.6/D2.7.
- Return do merchant fault: hoàn `finalAmount` đã thu; shipping gốc được hoàn nếu đã thu.
- Return do change of mind: hoàn `finalAmount - shippingFee`, không hoàn original shipping trong V1.
- `refundAmount` không vượt `paidAmount`; nếu COD chưa thu thì bằng `0`.
- `paymentStatus = refunded` chỉ sau khi operation hoàn tiền có confirmation. Trước đó là `refund_pending`.

## 8. Transition matrix

Đây là matrix nghiệp vụ tối thiểu; Gate 3 chuyển nó thành allowlist machine-readable.

| From | To | Actor hợp lệ | Điều kiện bắt buộc | Side effects chính |
|---|---|---|---|---|
| `none` | `pending` | `customer`, `system` | Cart/config/product/stock/payment input hợp lệ | Reserve stock, reserve voucher, deduct points, create event |
| `none` | `suspicious` | `customer`, `system` | Create hợp lệ nhưng risk score vượt ngưỡng | Như create `pending`; giữ stock và chờ review |
| `suspicious` | `pending` | `admin`, `super_admin` | Review approve; reason bắt buộc | Event review; không thay đổi stock |
| `pending` | `suspicious` | `system`, `admin` | Risk review yêu cầu | Event; không nhân side effect |
| `pending`/`suspicious` | `processing` | `admin`, `super_admin` | COD hoặc VietQR đã `paid`; risk đã clear | Event; không reserve stock lần hai |
| `processing` | `shipped` | `admin`, `system` | Đã bàn giao carrier; payment gate pass | Set tracking/ship marker |
| `pending`/`suspicious`/`processing` | `cancelled` | `customer` (chỉ pending/suspicious), `admin`, `system` | Reason; chưa shipped | Restore stock, release voucher/points; tạo refund task nếu đã paid |
| `shipped` | `delivered` | `admin`, `system`, `carrier` | Delivery evidence; VietQR phải paid | COD mark paid, grant reward, update customer stats |
| `shipped` | `failed_delivery` | `admin`, `system`, `carrier` | Delivery failure reason | Không reward, không restore stock |
| `failed_delivery` | `shipped` | `admin` | Có lần giao lại; giữ reservation | Tăng delivery attempt; không reserve lại |
| `failed_delivery` | `returned` | `admin`, `system` | Hàng physical đã về và đã kiểm | Restore sellable stock; không reward |
| `delivered` | `returned` | `admin`, `super_admin` | Trong return window hoặc exception; hàng đã nhận | Reverse reward/stats; restore sellable stock |
| `returned` | `refunded` | `admin`, `system`, `payment_provider` | Refund confirmed hoặc `paidAmount = 0` | Set refund markers/payment status; event đóng |
| `delivered` | `refunded` | `super_admin` | Emergency exception, reason + audit | Reverse reward nếu cần; không tự restore stock |

Không có transition hợp lệ nào từ `cancelled` hoặc `refunded` sang state khác trong V1.

## 9. Retry, concurrency và failure handling

- Create/transition phải lock idempotency key trước khi thực hiện side effect.
- Firestore transaction retry không được tạo event/restore/reward lần hai; marker và event reference là guard thứ hai sau idempotency.
- Nếu side effect external (payment/refund/Telegram) timeout sau khi order transaction commit, giữ state `pending`/`refund_pending` và cho phép retry bằng cùng operation key.
- Nếu một phần after-sales không thể hoàn tất, không chuyển sang terminal state giả. Ghi `failed_retryable` operation/event và giữ order ở state trước đó hoặc state chờ xử lý được policy cho phép.
- Client nhận error code ổn định, không nhận raw Firestore/service-account error.

## 10. Guardrails bắt buộc cho implementation

1. Không còn `updateDoc(orders/{id})` trực tiếp từ customer/admin UI cho các field lifecycle hoặc payment.
2. Không cộng/trừ points, `totalOrders`, `totalSpent` ở Profile, `useOrders` và Telegram riêng rẽ.
3. Không gọi Telegram notification trước khi order transaction tạo/transition thành công; notification retry không được là nguồn sự thật.
4. Mọi action phải ghi `actorType`, `actorId` phù hợp và reason cho admin override.
5. Không log Firebase ID token, full payment payload, password hoặc shipping PII không cần thiết.
6. Các field `finalAmount`, `paymentStatus`, `earnedPoints`, stock marker và reward marker phải là server-only.

## 11. Acceptance checklist cho Gate 2

Toàn bộ các điều kiện nghiệm thu Gate 2 đã được ký duyệt chính thức:

- [x] D2.1–D2.15 được chấp thuận toàn bộ (Owner: TQS Business Owner & Engineering Lead, Date: 2026-09-21).
- [x] Return window (7 ngày) và rule refund shipping (lỗi shop hoàn full ship, đổi ý khách chịu ship) đã được xác nhận theo chính sách cửa hàng.
- [x] V1 full-order return/no partial return được chấp thuận.
- [x] Payment owner xác nhận manual VietQR confirmation là phương án chuẩn tạm thời trước khi kết nối webhook ngân hàng.
- [x] Các actor được phép dùng Telegram callback đã được coi là internal adapter gọi cùng command service, không phải một nguồn transition thứ hai.
- [x] Product/order reconciliation plan cho legacy orders đã có owner.
- [x] Test cases transition và side effects được map sang Gate 3 schema/event/idempotency.
