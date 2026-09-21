/**
 * Canonical enums, types, and transition contracts for TQSShop Order Service (v1).
 * Single source of truth across TypeScript, Worker/API, Firestore Rules, and Test Harness.
 *
 * References:
 * - docs/order/GATE_2_ORDER_BUSINESS_POLICY.md
 * - docs/order/GATE_3_ORDER_SCHEMA.md
 */

// ============================================================================
// 1. CANONICAL ENUMS
// ============================================================================

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
  'update_order_metadata',
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
  'order_metadata_updated',
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
export type ReturnReason = typeof RETURN_REASON[number];

export const STOCK_DISPOSITION = [
  'sellable',
  'damaged',
  'lost',
] as const;
export type StockDisposition = typeof STOCK_DISPOSITION[number];

// ============================================================================
// 2. STRUCTURAL TRANSITION MATRIX
// ============================================================================

export const ALLOWED_TRANSITIONS: Record<OrderStatus | 'none', readonly OrderStatus[]> = {
  none: ['pending', 'suspicious'],
  pending: ['suspicious', 'processing', 'cancelled'],
  suspicious: ['pending', 'processing', 'cancelled'],
  processing: ['shipped', 'cancelled'],
  shipped: ['delivered', 'failed_delivery'],
  failed_delivery: ['shipped', 'returned'],
  delivered: ['returned', 'refunded'], // refunded directly only via emergency super_admin exception
  returned: ['refunded'],
  cancelled: [],
  refunded: [],
};

// ============================================================================
// 3. SCHEMA TYPES & INTERFACES (schemaVersion: 1)
// ============================================================================

export interface OrderItem {
  productId: string;
  name: string;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
  selectedBox?: string | null;
  selectedLang?: string | null;
  selectedVariants?: Record<string, string> | null;
  addSleeves?: boolean;
  quickAddAccessoryNames?: string[] | null;
  image: string;
}

export interface OrderShippingInfo {
  fullName: string;
  phone: string;
  address: string;
  notes?: string;
  city?: string;
  district?: string;
  ward?: string;
}

export interface OrderMoneyBreakdown {
  totalAmount: number;             // Merchandise subtotal: sum(unitPrice * quantity)
  shippingFee: number;             // Server-calculated shipping fee
  voucherDiscountAmount: number;   // Discount from promo code (including freeship)
  pointsDiscountAmount: number;    // Discount from user loyalty points
  discountAmount: number;          // Compatibility sum: voucherDiscount + pointsDiscount
  finalAmount: number;             // Amount to collect: max(0, total + shipping - discounts)
  rewardEligibleAmount: number;    // Basis for rewards: max(0, total - discounts)
  paidAmount: number;              // Actual collected money
  refundAmount: number;            // Actual refunded money
}

export interface OrderSideEffectMarkers {
  stockReservedAt?: string | null;
  stockRestoredAt?: string | null;
  stockRestoredReason?: string | null;
  voucherReservedAt?: string | null;
  voucherRestoredAt?: string | null;
  pointsDeductedAt?: string | null;
  pointsRefundedAt?: string | null;
  rewardGrantedAt?: string | null;
  rewardReversedAt?: string | null;
  rewardReversalDebt?: number | null;
  paymentConfirmedAt?: string | null;
  deliveredAt?: string | null;
  cancelledAt?: string | null;
  refundedAt?: string | null;
}

export interface OrderDocument extends OrderMoneyBreakdown, OrderSideEffectMarkers {
  id: string;
  schemaVersion: number;           // 1 for current production, 0 for legacy
  revision: number;                // Monotonically increasing optimistic lock counter
  userId: string;
  customerEmail: string;
  customerName?: string;
  items: OrderItem[];
  shippingInfo: OrderShippingInfo;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  paymentMethod: PaymentMethod;
  paymentDueAt?: string | null;    // Mandatory for VietQR pending: createdAt + 30 min
  returnEligibleUntil?: string | null; // deliveredAt + 7 days
  discountCode?: string | null;
  pointsApplied?: number;
  earnedPoints?: number;
  trackingCode?: string | null;
  carrierName?: string | null;
  actualShippingCost?: number | null;
  baseCost?: number | null;
  packagingCost?: number | null;
  adminNotes?: string | null;
  riskScore?: number;
  cancelReason?: string | null;
  returnReason?: ReturnReason | null;
  stockDisposition?: StockDisposition | null;
  createdAt: string;               // ISO 8601 string or Firestore Timestamp representation
  updatedAt: string;
}

export interface OrderEvent {
  id: string;
  sequence: number;
  orderId: string;
  eventType: EventType;
  actionType: ActionType;
  actorType: ActorType;
  actorId: string;
  fromStatus?: OrderStatus;
  toStatus?: OrderStatus;
  fromPaymentStatus?: PaymentStatus;
  toPaymentStatus?: PaymentStatus;
  payloadSnapshot?: Record<string, unknown>;
  sideEffectsExecuted: string[];
  reason?: string;
  idempotencyKey?: string;
  createdAt: string;
}

export interface IdempotencyRecord {
  id: string;                      // hash of (actorId + ':' + operation + ':' + idempotencyKey)
  actorId: string;
  operation: ActionType;
  idempotencyKey: string;
  requestFingerprint: string;     // SHA-256 hash of normalized payload
  status: IdempotencyStatus;
  resourceId?: string;            // e.g. orderId
  responseSnapshot?: Record<string, unknown>;
  errorMessage?: string;
  errorCode?: string;
  createdAt: string;
  updatedAt: string;
  expiresAt: string;               // Retention TTL (default: 24h - 7 days)
}
