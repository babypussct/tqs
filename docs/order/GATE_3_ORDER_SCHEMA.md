# Gate 3 — Order schema, events & idempotency

> **Status:** DRAFT FOR SIGN-OFF
>
> **Version:** `schemaVersion: 1`
>
> **Ngày soạn:** 2026-09-21
>
> **Phụ thuộc:** [Gate 2 business policy](./GATE_2_ORDER_BUSINESS_POLICY.md)

Tài liệu này là contract draft cho `orders`, order events và idempotency records. Sau khi sign-off, các enum và invariant dưới đây phải được dùng chung trong TypeScript, Worker/API, Firestore Rules, emulator tests và UI adapters.

## 1. Canonical enums

Các giá trị enum là wire values, không dịch sang tiếng Việt trong storage/API.

```ts
export const ORDER_STATUS = [
  'pending',
  'suspicious',
  'processing',
  'shipped',
  'failed_delivery',
  'delivered',
  'returned',
  'cancelled',
  'refunded',
] as const;
export type OrderStatus = typeof ORDER_STATUS[number];

export const PAYMENT_METHOD = ['cod', 'vietqr'] as const;
export type PaymentMethod = typeof PAYMENT_METHOD[number];

export const PAYMENT_STATUS = [
  'pending',
  'paid',
  'failed',
  'refund_pending',
  'refunded',
] as const;
export type PaymentStatus = typeof PAYMENT_STATUS[number];

export const DISCOUNT_TYPE = [
  'percentage',
  'fixed',
  'freeship_only',
] as const;
export type DiscountType = typeof DISCOUNT_TYPE[number];

export const ACTOR_TYPE = [
  'customer',
  'admin',
  'super_admin',
  'system',
  'payment_provider',
  'carrier',
  'telegram_internal',
  'migration',
] as const;
export type ActorType = typeof ACTOR_TYPE[number];

export const ACTION_TYPE = [
  'create_order',
  'review_risk',
  'confirm_payment',
  'fail_payment',
  'expire_payment',
  'start_processing',
  'ship_order',
  'mark_delivered',
  'mark_failed_delivery',
  'retry_delivery',
  'cancel_order',
  'accept_return',
  'request_refund',
  'complete_refund',
  'reconcile_side_effect',
] as const;
export type ActionType = typeof ACTION_TYPE[number];

export const EVENT_TYPE = [
  'order_created',
  'risk_reviewed',
  'status_changed',
  'payment_status_changed',
  'stock_reserved',
  'stock_restored',
  'voucher_reserved',
  'voucher_restored',
  'points_debited',
  'points_refunded',
  'reward_granted',
  'reward_reversed',
  'return_received',
  'refund_requested',
  'refund_completed',
  'operation_replayed',
  'operation_failed',
] as const;
export type EventType = typeof EVENT_TYPE[number];

export const IDEMPOTENCY_STATUS = [
  'processing',
  'succeeded',
  'failed_retryable',
  'failed_permanent',
] as const;
export type IdempotencyStatus = typeof IDEMPOTENCY_STATUS[number];

export const RETURN_REASON = [
  'defective',
  'wrong_item',
  'transit_damage',
  'change_of_mind',
  'other',
] as const;

export const STOCK_DISPOSITION = [
  'sellable',
  'damaged',
  'lost',
] as const;
```

### 1.1 Transition allowlist

```ts
export const ALLOWED_TRANSITIONS: Record<OrderStatus | 'none', readonly OrderStatus[]> = {
  none: ['pending', 'suspicious'],
  pending: ['suspicious', 'processing', 'cancelled'],
  suspicious: ['pending', 'processing', 'cancelled'],
  processing: ['shipped', 'cancelled'],
  shipped: ['delivered', 'failed_delivery'],
  failed_delivery: ['shipped', 'returned'],
  delivered: ['returned', 'refunded'], // refunded only emergency exception
  returned: ['refunded'],
  cancelled: [],
  refunded: [],
};
```

The service must apply actor/condition checks from Gate 2 in addition to this structural allowlist. An enum value appearing in the list does not grant permission to the caller.

## 2. `orders/{orderId}`

### 2.1 Example document

The following is illustrative Firestore data. `Timestamp` means a Firestore timestamp, not an ISO string stored by the browser.

```ts
{
  schemaVersion: 1,
  revision: 4,
  userId: 'uid_customer_123',

  status: 'pending',
  statusReason: 'customer_created',
  paymentMethod: 'vietqr',
  paymentStatus: 'pending',
  currency: 'VND',

  items: [
    {
      productId: 'product_abc',
      name: 'Board game snapshot name',
      image: 'https://cdn.example.invalid/product_abc.webp',
      unitPrice: 850000,
      quantity: 1,
      selectedBox: null,
      selectedLang: 'vi',
      selectedVariants: {},
      addSleeves: false,
      quickAddAccessoryNames: [],
      lineSubtotal: 850000,
    },
  ],

  totalAmount: 850000,
  shippingFee: 30000,
  voucherDiscountAmount: 50000,
  pointsApplied: 100,
  pointsDiscountAmount: 100000,
  discountAmount: 150000,
  finalAmount: 730000,
  rewardEligibleAmount: 700000,
  paidAmount: 0,
  refundAmount: 0,

  voucher: {
    discountCodeId: 'discount_abc',
    code: 'WELCOME50',
    discountType: 'fixed',
    discountAmount: 50000,
  },

  shippingInfo: {
    fullName: 'Customer name snapshot',
    phone: '0900000000',
    address: 'Shipping address snapshot',
    notes: '',
  },

  riskScore: 0,
  paymentDueAt: Timestamp,
  paymentConfirmedAt: null,
  trackingCode: null,
  deliveryAttempt: 0,

  stockReservedAt: Timestamp,
  stockRestoredAt: null,
  stockRestoredReason: null,
  pointsDeductedAt: Timestamp,
  pointsRefundedAt: null,
  voucherUsageReservedAt: Timestamp,
  voucherUsageRestoredAt: null,
  rewardGrantedAt: null,
  rewardReversedAt: null,
  earnedPoints: 0,

  cancelledAt: null,
  deliveredAt: null,
  returnEligibleUntil: null,
  failedDeliveryAt: null,
  returnedAt: null,
  returnRequestedAt: null,
  refundRequestedAt: null,
  refundedAt: null,

  returnCase: null,
  refund: null,

  createIdempotencyKeyHash: 'sha256:...',
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

### 2.2 Field contract

| Field | Type | Required | Writable by client? | Rule |
|---|---|---:|---:|---|
| `schemaVersion` | integer | yes | no | Exactly `1` for new orders. |
| `revision` | integer | yes | no | Starts at `1`; increments on every successful order mutation. |
| `userId` | string | yes | create only, server validates | Must equal authenticated Firebase UID. Immutable. |
| `status` | `OrderStatus` | yes | no | Must follow allowlist + actor policy. |
| `statusReason` | string | yes after first transition | no | Stable machine reason; admin override requires human-readable reason too. |
| `paymentMethod` | `PaymentMethod` | yes | create input, server resolves | Immutable after create. |
| `paymentStatus` | `PaymentStatus` | yes | no | Independent payment lifecycle. |
| `currency` | literal `VND` | yes | no | V1 does not support multi-currency. |
| `items` | array, 1–50 | yes | create selections only | Server snapshots product name/image/price/variant and recomputes quantities/prices. Immutable after create. |
| `totalAmount` | non-negative integer | yes | no | Merchandise subtotal; VND has no fractional unit in this model. |
| `shippingFee` | non-negative integer | yes | no | Server-derived. |
| `voucherDiscountAmount` | non-negative integer | yes | no | Server-derived from voucher snapshot. |
| `pointsApplied` | non-negative integer | yes | create request only | Server clamps/validates against balance and config. |
| `pointsDiscountAmount` | non-negative integer | yes | no | Server-derived. |
| `discountAmount` | non-negative integer | yes | no | Compatibility sum of voucher + points discount. |
| `finalAmount` | non-negative integer | yes | no | Server-derived payable amount. |
| `rewardEligibleAmount` | non-negative integer | yes | no | Snapshot used for reward/tier calculation. |
| `paidAmount` | non-negative integer | yes | no | Amount confirmed as collected. Starts at `0`. |
| `refundAmount` | non-negative integer | yes | no | Cumulative actual refund; never exceeds `paidAmount`. |
| `voucher` | map or null | optional | create code only | Contains immutable code/config snapshot; never trust current config to rewrite history. |
| `shippingInfo` | map | yes | create input, controlled edit only if policy permits | Snapshot. Address changes after shipment are forbidden. |
| `riskScore` | integer `0..100` | server-only | no | Input to review policy, not client authority. |
| `paymentDueAt` | timestamp or null | conditional | no | Required for VietQR pending flow. |
| `paymentConfirmedAt` | timestamp or null | conditional | no | Set only by verified provider/admin payment command. |
| `trackingCode` | string or null | optional | no | Written by authorized shipping transition. |
| `deliveryAttempt` | non-negative integer | yes | no | Starts at `0`, increases only on retry/shipped event. |
| `stockReservedAt` | timestamp or null | yes | no | Set in create transaction. |
| `stockRestoredAt` | timestamp or null | yes | no | Set once when restore completes; may remain null for delivered/sellable flow. |
| `stockRestoredReason` | enum/string or null | conditional | no | Required when `stockRestoredAt` is set. |
| `pointsDeductedAt` | timestamp or null | yes | no | Null when `pointsApplied = 0`; otherwise create transaction marker. |
| `pointsRefundedAt` | timestamp or null | yes | no | Set once for eligible pre-shipment cancel. |
| `voucherUsageReservedAt` | timestamp or null | yes | no | Null when no voucher; otherwise create transaction marker. |
| `voucherUsageRestoredAt` | timestamp or null | yes | no | Set once for eligible pre-shipment cancel. |
| `rewardGrantedAt` | timestamp or null | yes | no | Set once on trusted `delivered` transition; zero-point reward still records the event. |
| `rewardReversedAt` | timestamp or null | yes | no | Set once on approved post-delivery return/refund. |
| `earnedPoints` | integer `>= 0` | yes | no | Snapshot of reward grant, not recalculated during rollback. |
| `cancelledAt`, `deliveredAt`, `returnEligibleUntil`, `failedDeliveryAt`, `returnRequestedAt`, `returnedAt`, `refundRequestedAt`, `refundedAt` | timestamp or null | conditional | no | State-specific and after-sales markers; server only. |
| `returnCase` | map or null | conditional | no | Required for `returned`/after-sales; see section 2.3. |
| `refund` | map or null | conditional | no | Required when refund is requested/completed; see section 2.4. |
| `createIdempotencyKeyHash` | string | yes | no | Hash only; raw key is never stored in the order. |
| `createdAt`, `updatedAt` | timestamp | yes | no | Server timestamps. |

Existing operational fields `actualShippingCost`, `baseCost`, `packagingCost`, `adminNotes` and `legacySource` may remain optional server/admin fields. They do not alter customer pricing or reward calculation.

### 2.3 `returnCase` map

```ts
type ReturnCase = {
  reason: 'defective' | 'wrong_item' | 'transit_damage' | 'change_of_mind' | 'other';
  requestedAt?: Timestamp;
  approvedAt?: Timestamp;
  receivedAt: Timestamp;
  approvedBy: { type: ActorType; id: string };
  stockDisposition: 'sellable' | 'damaged' | 'lost';
  restockQuantityByProduct?: Record<string, number>;
  inspectionNote?: string;
};
```

V1 chỉ có một `returnCase` cho full-order return. `restockQuantityByProduct` cho phép ghi rõ item nào không thể nhập lại kho mà không làm sai stock.

### 2.4 `refund` map

```ts
type Refund = {
  reason: string;
  requestedAt: Timestamp;
  completedAt?: Timestamp;
  amount: number;
  method: 'original_payment' | 'bank_transfer' | 'cash' | 'none';
  providerReference?: string;
  confirmedBy?: { type: ActorType; id: string };
};
```

`providerReference` không chứa secret/token. Refund command và provider callback phải có idempotency key riêng.

### 2.5 Invariants của order

1. `finalAmount = max(0, totalAmount + shippingFee - voucherDiscountAmount - pointsDiscountAmount)`.
2. `discountAmount = voucherDiscountAmount + pointsDiscountAmount`.
3. `finalAmount >= 0`, `paidAmount >= 0`, `refundAmount >= 0`, và `refundAmount <= paidAmount`.
4. `pointsDiscountAmount = 0` khi `pointsApplied = 0`; nếu points được dùng thì `pointsDeductedAt != null`.
5. `status = delivered` yêu cầu `deliveredAt != null`, `returnEligibleUntil != null` và `rewardGrantedAt != null`.
6. `status = cancelled` yêu cầu `cancelledAt != null`; `status = returned` yêu cầu `returnCase != null` và `returnedAt != null`.
7. `status = refunded` yêu cầu `refundedAt != null`; nếu `paidAmount > 0` thì `paymentStatus = refunded`.
8. Không set `stockRestoredAt` hai lần. Nếu return chỉ restock một phần, event phải ghi đủ quantity theo product.
9. `userId`, line-item price, `totalAmount`, `finalAmount`, payment markers và reward markers không được sửa bằng client write.
10. `revision` tăng tuần tự trong cùng transaction với state mutation.

## 3. `orders/{orderId}/events/{eventId}`

### 3.1 Event document

```ts
{
  schemaVersion: 1,
  sequence: 4,
  eventType: 'status_changed',
  action: 'mark_delivered',
  orderId: 'ORDER123',

  actor: {
    type: 'admin',
    id: 'uid_admin_123',
  },
  from: {
    status: 'shipped',
    paymentStatus: 'pending',
    revision: 3,
  },
  to: {
    status: 'delivered',
    paymentStatus: 'paid',
    revision: 4,
  },

  reasonCode: 'carrier_confirmed',
  reasonNote: null,
  idempotencyKeyHash: 'sha256:...',
  requestId: 'req_...',

  sideEffects: [
    {
      kind: 'payment_mark_paid',
      state: 'applied',
      marker: 'paymentConfirmedAt',
    },
    {
      kind: 'reward_grant',
      state: 'applied',
      marker: 'rewardGrantedAt',
      points: 8,
    },
  ],

  payload: {
    rewardEligibleAmount: 700000,
    earnedPoints: 8,
  },
  occurredAt: Timestamp,
  createdAt: Timestamp,
}
```

### 3.2 Event contract

| Field | Type | Rule |
|---|---|---|
| `schemaVersion` | integer | Version của event shape, hiện là `1`. |
| `sequence` | integer | Bằng order revision sau transition; unique tăng dần trong một order. |
| `eventType` | `EventType` | Canonical enum ở section 1. |
| `action` | `ActionType` | Command đã tạo ra event. |
| `orderId` | string | Phải khớp parent document ID. |
| `actor` | map | `type` + stable `id`; không lưu token/password. |
| `from`, `to` | state snapshots | Tối thiểu status/paymentStatus/revision; giúp audit mà không phải suy diễn từ order hiện tại. |
| `reasonCode` | string | Machine-readable; bắt buộc cho admin/super-admin override. |
| `reasonNote` | string/null | Bị giới hạn độ dài; không lưu PII không cần thiết. |
| `idempotencyKeyHash` | string | Liên kết tới idempotency record, không lưu raw key. |
| `requestId` | string | Correlation ID để trace log. |
| `sideEffects` | array | Mỗi effect có kind/state/marker; retry phải đọc lại trước khi apply. |
| `payload` | map | Dữ liệu audit tối thiểu, redacted; không copy full shipping/payment payload. |
| `occurredAt` | timestamp | Thời điểm nghiệp vụ xảy ra theo service/provider. |
| `createdAt` | timestamp | Thời điểm event được ghi. |

Event subcollection là append-only. Client không được create/update/delete; chỉ service identity được ghi.

### 3.3 Side-effect kinds

Canonical `sideEffects[].kind` gồm tối thiểu:

```text
stock_reserve
stock_restore
voucher_reserve
voucher_restore
points_debit
points_refund
reward_grant
reward_reverse
payment_mark_paid
refund_request
refund_complete
notification_enqueue
```

`notification_enqueue` chỉ là delivery side effect; event/order transition đã commit vẫn là nguồn sự thật nếu Telegram thất bại.

## 4. `idempotency/{scopeHash}`

### 4.1 Document ID và key scope

Document ID:

```text
sha256(scope + "|" + actorPrincipal + "|" + rawRequestKey)
```

`rawRequestKey` chỉ tồn tại trong request memory. Không lưu raw key vào Firestore/log. `actorPrincipal` là Firebase UID cho customer/admin hoặc provider identity cho webhook; `scope` phân biệt `order`, `payment`, `refund` nếu cùng actor tái sử dụng key.

### 4.2 Example document

```ts
{
  schemaVersion: 1,
  scope: 'order',
  actorType: 'customer',
  actorUid: 'uid_customer_123',
  requestKeyHash: 'sha256:...',
  requestFingerprint: 'sha256:canonical-json-without-key',
  operation: 'create_order',
  status: 'succeeded',

  orderId: 'ORDER123',
  resultRef: 'orders/ORDER123',
  resultCode: 'ORDER_CREATED',

  attemptCount: 1,
  lockExpiresAt: null,
  errorCode: null,
  errorMessageSafe: null,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  expiresAt: Timestamp,
}
```

### 4.3 Idempotency rules

1. `status` bắt đầu là `processing` trong atomic claim/lease.
2. Key đang `processing` và `lockExpiresAt` chưa hết hạn trả `OPERATION_IN_PROGRESS`, không chạy side effect song song.
3. Key `succeeded` trả lại `resultRef/resultCode` cũ; không tạo order/event/usage mới.
4. Key `failed_retryable` được retry sau khi lease cũ hết hạn hoặc theo backoff; phải giữ nguyên `requestFingerprint`.
5. Key `failed_permanent` trả lỗi ổn định; request mới phải dùng key khác sau khi sửa input.
6. Cùng actor + raw key nhưng fingerprint khác trả `IDEMPOTENCY_PAYLOAD_MISMATCH`; không overwrite record.
7. `resultRef` có thể trỏ tới `orders/{orderId}` hoặc event/refund operation, nhưng phải là server-generated reference.
8. Retention mặc định là 90 ngày từ `createdAt`; order events giữ lâu hơn theo retention/audit policy. Client không được reuse key sau expiry.
9. Provider callbacks phải dùng provider event ID đã hash; Telegram callback phải derive một key ổn định từ callback/message ID và action.

## 5. Request contract và server-only boundary

### 5.1 Create order input tối thiểu

```ts
type CreateOrderInput = {
  items: Array<{
    productId: string;
    quantity: number;
    selectedBox?: string | null;
    selectedLang?: string | null;
    selectedVariants?: Record<string, string>;
    addSleeves?: boolean;
    quickAddAccessoryNames?: string[];
  }>;
  shippingInfo: {
    fullName: string;
    phone: string;
    address: string;
    notes?: string;
  };
  paymentMethod: 'cod' | 'vietqr';
  discountCode?: string | null;
  pointsToUse?: number;
  idempotencyKey: string;
};
```

Input không được nhận authoritative `price`, `totalAmount`, `discountAmount`, `finalAmount`, `shippingFee`, `paymentStatus`, `status`, `riskScore`, `earnedPoints`, `usedCount`, `totalOrders` hoặc stock.

### 5.2 Server-only field groups

Các field sau chỉ được service identity ghi:

```text
schemaVersion, revision, status, statusReason, paymentStatus,
all monetary totals, riskScore, paidAmount, refundAmount,
all *_At side-effect markers, earnedPoints,
stockReservedAt, stockRestoredAt, stockRestoredReason,
pointsDeductedAt, pointsRefundedAt,
voucherUsageReservedAt, voucherUsageRestoredAt,
rewardGrantedAt, rewardReversedAt,
createdAt, updatedAt, createIdempotencyKeyHash,
events/*, idempotency/*
```

## 6. Compatibility và migration

### 6.1 Legacy `schemaVersion` 0

Order hiện tại không có `schemaVersion` được coi là version `0`:

- Adapter map các status đã biết; không tự thêm side-effect markers với giá trị “đoán”.
- `paymentStatus` thiếu được đọc là `pending` trong service contract; không suy ra `paid` chỉ vì `paymentMethod = cod`.
- `totalAmount`, `discountAmount`, `finalAmount` được giữ để hiển thị/read compatibility; không coi client snapshot cũ là bằng chứng server-authoritative.
- Nếu thiếu `stockReservedAt`, `pointsDeductedAt`, `rewardGrantedAt` hoặc event history thì destructive after-sales mutation bị chặn hoặc phải đi qua `reconcile_side_effect` của admin.
- Legacy order có thể read-only trong giai đoạn đầu; không bulk backfill marker bằng `update all` không có dry-run.

### 6.2 Quy tắc tăng version

Tăng `schemaVersion` khi thay đổi:

1. field shape hoặc meaning;
2. status/payment enum hoặc transition semantics;
3. cách tính monetary/reward;
4. marker/event/idempotency contract.

Mỗi version mới phải có adapter đọc version cũ, migration dry-run, test rollback/read compatibility và quyết định cách xử lý order đang ở giữa transition.

## 7. Invariants và test vectors

Gate 3 test contract tối thiểu phải bao phủ:

| Case | Expected result |
|---|---|
| Client thay `price`/`finalAmount` | Server ignore/recompute; không giảm giá được. |
| Product inactive hoặc stock không đủ | Create fail atomic; không order, không voucher usage, không points debit. |
| Hai create cùng product cuối | Tối đa một transaction thành công; stock không âm. |
| Cùng idempotency key + cùng payload | Trả cùng order/result; không side effect lần hai. |
| Cùng idempotency key + payload khác | `IDEMPOTENCY_PAYLOAD_MISMATCH`; dữ liệu cũ không bị overwrite. |
| Cancel callback lặp | Một stock restore, một voucher/points release; retry là no-op/success. |
| Delivered từ UI và Telegram đồng thời | Một reward grant, một `rewardGrantedAt`, một stats update. |
| `shipped → cancelled` trực tiếp | Reject; yêu cầu failed-delivery/return path. |
| VietQR client tự set `paid` | Rules/API reject. |
| COD delivered retry | Không cộng paid/reward/stats lần hai. |
| Return không có inspection/actor | Reject; không restore stock. |
| Reward reversal khi balance thiếu | Balance không âm; tạo debt/ledger marker để xử lý sau. |
| Legacy order thiếu marker | Không tự động restore/reverse; yêu cầu reconcile. |
| Refund lớn hơn paid amount | Reject invariant. |

## 8. Firestore access contract dự kiến

Đây là boundary để viết Rules sau khi API/service đã có; không phải lệnh mở quyền production:

- Customer chỉ read order của chính mình.
- Customer không direct write order fields sau create; create order đi qua API/service.
- Admin chỉ mutation qua transition endpoint/Worker với `role = admin` + `adminPermissions` phù hợp.
- Event và idempotency collections không được client read/write tùy ý; nếu cần support read thì tạo endpoint đã redact.
- Product stock, voucher usage, user points/stats và payment markers không có customer direct mutation.
- Rules/API phải test cả `get` và query/list, không chỉ happy-path document read.

## 9. Acceptance checklist cho Gate 3

- [ ] Business owner đã sign-off Gate 2.
- [ ] Canonical enums trong section 1 được chấp thuận và có single source trong code.
- [ ] Transition allowlist và actor/condition matrix được test.
- [ ] `orders/{orderId}` schema có `schemaVersion`, `revision`, money breakdown và side-effect markers.
- [ ] Event subcollection append-only, có sequence, actor, before/after state và side-effects.
- [ ] Idempotency document có fingerprint, operation, lifecycle status, result ref, timestamps và expiry.
- [ ] Payload mismatch, concurrent claim và retry behavior có test.
- [ ] Legacy adapter/version 0 và migration dry-run có owner trước khi backfill production.
- [ ] Firestore Rules/API boundary đã được map thành test cases; không có wildcard write.
- [ ] Không bắt đầu core `orderService` cho tới khi tất cả checklist trên được review.
