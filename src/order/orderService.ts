/**
 * Core Order Service for TQSShop.
 * Handles server-authoritative order creation, inventory reservation,
 * discount & point deductions, idempotency lifecycle, state transitions, and audit events.
 *
 * Implements:
 * - Gate 2 Order Business Policy
 * - Gate 3 Order Schema & Invariants
 * - Firestore Transaction Compatibility (Strict Read-Before-Write)
 */

import type {
  ActionType,
  ActorType,
  IdempotencyRecord,
  OrderDocument,
  OrderEvent,
  OrderItem,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  ReturnReason,
  StockDisposition,
} from './canonical.js';
import {
  ACTION_TYPE,
  ORDER_STATUS,
  PAYMENT_STATUS,
  RETURN_REASON,
  STOCK_DISPOSITION,
} from './canonical.js';
import { generateRequestFingerprint } from './fingerprint.js';
import {
  calculateEarnedPoints,
  calculateOrderTotals,
  calculateRefundAmount,
  calculateRewardReversal,
  normalizeRewardsConfig,
} from './money.js';
import { planOrderTransition } from './transitions.js';
import type { TransitionRequest } from './transitions.js';
import { resolveProductUnitPrice } from './pricing.js';
import { toDate } from '../shared/data/date.js';

export interface OrderItemInput {
  productId: string;
  quantity: number;
  selectedBox?: string | null;
  selectedLang?: string | null;
  selectedVariants?: Record<string, string> | null;
  addSleeves?: boolean;
  quickAddAccessoryNames?: string[] | null;
}

export interface CreateOrderInput {
  items: OrderItemInput[];
  shippingInfo: {
    fullName: string;
    phone: string;
    address: string;
    notes?: string;
    city?: string;
    district?: string;
    ward?: string;
  };
  paymentMethod: PaymentMethod;
  discountCode?: string | null;
  pointsToUse?: number;
  idempotencyKey: string;
}

export interface TransitionOrderInput {
  orderId: string;
  /** Optional deduplication key for retried callbacks/webhook commands. */
  idempotencyKey?: string;
  targetStatus?: OrderStatus;
  paymentStatus?: PaymentStatus;
  cancelReason?: string;
  returnReason?: ReturnReason;
  stockDisposition?: StockDisposition;
  carrierDeliveryEvidence?: string;
  overrideWindow?: boolean;
  overridePaymentGate?: boolean;
  overrideReason?: string;
  actionType?: ActionType;
  metadata?: {
    trackingCode?: string | null;
    actualShippingCost?: number | null;
    baseCost?: number | null;
    packagingCost?: number | null;
    adminNotes?: string | null;
  };
}

export interface AuthenticatedActor {
  uid: string;
  email: string;
  displayName?: string;
  role: 'customer' | 'admin';
  isSuperAdmin?: boolean;
  permissions?: Record<string, boolean>;
}

export interface UserRewardStatsUpdate {
  pointsDelta?: number;
  totalSpentDelta?: number;
  totalOrdersDelta?: number;
  rewardReversalDebtDelta?: number;
  tier?: string;
}

export interface OrderServiceDependencies {
  getProduct: (id: string) => Promise<any | null>;
  updateProductStock: (id: string, newStock: number) => Promise<void>;
  getVoucher: (code: string) => Promise<any | null>;
  incrementVoucherUsage: (voucherId: string) => Promise<void>;
  decrementVoucherUsage?: (voucherId: string) => Promise<void>;
  getUserProfile: (uid: string) => Promise<any | null>;
  updateUserPoints: (uid: string, pointsDelta: number) => Promise<void>;
  saveOrder: (order: OrderDocument) => Promise<void>;
  getOrder: (orderId: string) => Promise<OrderDocument | null>;
  updateOrder: (orderId: string, updates: Partial<OrderDocument>) => Promise<void>;
  saveEvent: (orderId: string, event: OrderEvent) => Promise<void>;
  getIdempotencyRecord: (id: string) => Promise<IdempotencyRecord | null>;
  saveIdempotencyRecord: (record: IdempotencyRecord) => Promise<void>;
  updateUserRewardStats?: (uid: string, update: UserRewardStatsUpdate) => Promise<void>;
  getShippingConfig?: () => Promise<any | null>;
  getTiersConfig?: () => Promise<any | null>;
  getRewardsConfig?: () => Promise<any | null>;
  getPaymentConfig?: () => Promise<any | null>;
  getUserOrderCount?: (uid: string, discountCode?: string | null) => Promise<number>;
}

/**
 * Idempotency keys become part of a Firestore document id. Keep the accepted
 * alphabet deliberately narrow so user input cannot create nested paths or
 * invalid document references.
 */
export function isValidIdempotencyKey(value: unknown): value is string {
  return typeof value === 'string' &&
    value.length >= 1 &&
    value.length <= 200 &&
    /^[A-Za-z0-9._:-]+$/.test(value);
}

const TIER_RANK: Record<string, number> = {
  bronze: 0,
  silver: 1,
  gold: 2,
  diamond: 3,
};

function assertBoundedString(value: unknown, field: string, minLength: number, maxLength: number): void {
  if (typeof value !== 'string' || value.trim().length < minLength || value.length > maxLength) {
    throw new OrderServiceError(`${field} không hợp lệ.`, 'INVALID_ORDER_INPUT', 400);
  }
}

function assertOptionalBoundedString(value: unknown, field: string, maxLength: number): void {
  if (value !== undefined && value !== null && (typeof value !== 'string' || value.length > maxLength)) {
    throw new OrderServiceError(`${field} không hợp lệ.`, 'INVALID_ORDER_INPUT', 400);
  }
}

/** Validate untrusted checkout input before any product/config reads. */
export function assertValidOrderInput(
  input: any,
  options: { requireIdempotencyKey?: boolean; requireShippingInfo?: boolean } = {},
): void {
  if (!input || typeof input !== 'object') {
    throw new OrderServiceError('Dữ liệu đơn hàng không hợp lệ.', 'INVALID_ORDER_INPUT', 400);
  }
  if (!Array.isArray(input.items) || input.items.length < 1) {
    throw new OrderServiceError('Giỏ hàng không được để trống.', 'EMPTY_CART', 400);
  }
  if (input.items.length > 50) {
    throw new OrderServiceError('Giỏ hàng có quá nhiều sản phẩm.', 'CART_TOO_LARGE', 400);
  }

  for (const item of input.items) {
    if (!item || typeof item !== 'object') {
      throw new OrderServiceError('Sản phẩm trong giỏ không hợp lệ.', 'INVALID_ORDER_INPUT', 400);
    }
    assertBoundedString(item.productId, 'productId', 1, 150);
    if (String(item.productId).includes('/')) {
      throw new OrderServiceError('productId không hợp lệ.', 'INVALID_ORDER_INPUT', 400);
    }
    if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 1000) {
      throw new OrderServiceError('Số lượng sản phẩm không hợp lệ.', 'INVALID_QUANTITY', 400);
    }
    assertOptionalBoundedString(item.selectedBox, 'selectedBox', 200);
    assertOptionalBoundedString(item.selectedLang, 'selectedLang', 100);
    if (item.selectedVariants !== undefined && item.selectedVariants !== null) {
      if (typeof item.selectedVariants !== 'object' || Array.isArray(item.selectedVariants)) {
        throw new OrderServiceError('Biến thể sản phẩm không hợp lệ.', 'INVALID_PRODUCT_OPTION', 400);
      }
      const variantEntries = Object.entries(item.selectedVariants);
      if (variantEntries.length > 20 || variantEntries.some(([key, value]) =>
        key.length > 100 || typeof value !== 'string' || value.length > 200
      )) {
        throw new OrderServiceError('Biến thể sản phẩm không hợp lệ.', 'INVALID_PRODUCT_OPTION', 400);
      }
    }
    if (item.quickAddAccessoryNames !== undefined && item.quickAddAccessoryNames !== null) {
      if (!Array.isArray(item.quickAddAccessoryNames) || item.quickAddAccessoryNames.length > 20 ||
          item.quickAddAccessoryNames.some((name: unknown) => typeof name !== 'string' || name.length > 200)) {
        throw new OrderServiceError('Phụ kiện mua kèm không hợp lệ.', 'INVALID_PRODUCT_OPTION', 400);
      }
    }
  }

  if (input.shippingInfo !== undefined && input.shippingInfo !== null) {
    if (typeof input.shippingInfo !== 'object' || Array.isArray(input.shippingInfo)) {
      throw new OrderServiceError('Thông tin giao hàng không hợp lệ.', 'INVALID_SHIPPING_INFO', 400);
    }
    for (const [field, maxLength] of Object.entries({
      fullName: 160,
      phone: 40,
      address: 300,
      notes: 1000,
      city: 120,
      district: 120,
      ward: 120,
    })) {
      const value = input.shippingInfo[field];
      if ((field === 'fullName' || field === 'phone' || field === 'address') && options.requireShippingInfo) {
        assertBoundedString(value, `shippingInfo.${field}`, 1, maxLength);
      } else {
        assertOptionalBoundedString(value, `shippingInfo.${field}`, maxLength);
      }
    }
  } else if (options.requireShippingInfo) {
    throw new OrderServiceError('Thông tin giao hàng không đầy đủ.', 'INVALID_SHIPPING_INFO', 400);
  }

  if (!['cod', 'vietqr'].includes(input.paymentMethod)) {
    throw new OrderServiceError('Phương thức thanh toán không hợp lệ.', 'INVALID_PAYMENT_METHOD', 400);
  }
  if (input.discountCode !== undefined && input.discountCode !== null &&
      (typeof input.discountCode !== 'string' || input.discountCode.length > 100)) {
    throw new OrderServiceError('Mã giảm giá không hợp lệ.', 'INVALID_DISCOUNT_CODE', 400);
  }
  if (input.pointsToUse !== undefined && input.pointsToUse !== null &&
      (!Number.isInteger(input.pointsToUse) || input.pointsToUse < 0 || input.pointsToUse > 1_000_000_000)) {
    throw new OrderServiceError('Số điểm sử dụng không hợp lệ.', 'INVALID_POINTS', 400);
  }
  if (options.requireIdempotencyKey) {
    if (!input.idempotencyKey) {
      throw new OrderServiceError('Thiếu idempotencyKey.', 'MISSING_IDEMPOTENCY_KEY', 400);
    }
    if (!isValidIdempotencyKey(input.idempotencyKey)) {
      throw new OrderServiceError('idempotencyKey không hợp lệ.', 'INVALID_IDEMPOTENCY_KEY', 400);
    }
  }
}

function assertTierEligible(product: any, userTier: string | undefined): void {
  const requiredTier = typeof product?.minTierRequired === 'string'
    ? product.minTierRequired.toLowerCase()
    : '';
  if (!requiredTier || TIER_RANK[requiredTier] === undefined) return;
  const currentTier = String(userTier || 'bronze').toLowerCase();
  if ((TIER_RANK[currentTier] ?? 0) < TIER_RANK[requiredTier]) {
    throw new OrderServiceError(
      `Sản phẩm yêu cầu hạng ${requiredTier} trở lên.`,
      'TIER_REQUIRED',
      403,
    );
  }
}

function safeNonNegativeNumber(value: unknown, fallback: number, maximum = Number.MAX_SAFE_INTEGER): number {
  const parsed = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(parsed) && parsed >= 0
    ? Math.min(maximum, parsed)
    : fallback;
}

export class OrderServiceError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly status: number = 400
  ) {
    super(message);
    this.name = 'OrderServiceError';
  }
}

export function generateOrderCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = 'TQS';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

function canManageOrders(actor: AuthenticatedActor): boolean {
  return actor.isSuperAdmin === true || (
    actor.role === 'admin' && actor.permissions?.manageOrders === true
  );
}

function assertCanManageOrders(actor: AuthenticatedActor): void {
  if (!canManageOrders(actor)) {
    throw new OrderServiceError(
      'Bạn không có quyền thực hiện thao tác quản trị đơn hàng.',
      'ORDER_PERMISSION_REQUIRED',
      403
    );
  }
}

function validateOrderMetadata(metadata: NonNullable<TransitionOrderInput['metadata']>): void {
  if (metadata.trackingCode !== undefined && metadata.trackingCode !== null) {
    if (typeof metadata.trackingCode !== 'string' || metadata.trackingCode.length > 200) {
      throw new OrderServiceError('Mã vận đơn không hợp lệ.', 'INVALID_TRACKING_CODE', 400);
    }
  }

  for (const [field, value] of Object.entries(metadata)) {
    if (field === 'trackingCode' || field === 'adminNotes') continue;
    if (value !== null && (typeof value !== 'number' || !Number.isFinite(value) || value < 0)) {
      throw new OrderServiceError(`Giá trị ${field} không hợp lệ.`, 'INVALID_ORDER_METADATA', 400);
    }
  }

  if (metadata.adminNotes !== undefined && metadata.adminNotes !== null &&
      (typeof metadata.adminNotes !== 'string' || metadata.adminNotes.length > 500)) {
    throw new OrderServiceError('Ghi chú admin không hợp lệ.', 'INVALID_ADMIN_NOTES', 400);
  }
}

/** Validate transition fields before using untrusted API values in Firestore or the planner. */
function assertValidTransitionInput(input: any): void {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new OrderServiceError('Dữ liệu chuyển trạng thái không hợp lệ.', 'INVALID_TRANSITION_INPUT', 400);
  }

  assertBoundedString(input.orderId, 'orderId', 1, 150);
  if (input.orderId.includes('/')) {
    throw new OrderServiceError('orderId không hợp lệ.', 'INVALID_TRANSITION_INPUT', 400);
  }

  const enumFields: Array<[string, unknown, readonly string[]]> = [
    ['targetStatus', input.targetStatus, ORDER_STATUS],
    ['paymentStatus', input.paymentStatus, PAYMENT_STATUS],
    ['actionType', input.actionType, ACTION_TYPE],
    ['returnReason', input.returnReason, RETURN_REASON],
    ['stockDisposition', input.stockDisposition, STOCK_DISPOSITION],
  ];
  for (const [field, value, allowed] of enumFields) {
    if (value !== undefined && value !== null && !allowed.some((candidate) => candidate === value)) {
      throw new OrderServiceError(`${field} không hợp lệ.`, 'INVALID_TRANSITION_INPUT', 400);
    }
  }

  assertOptionalBoundedString(input.cancelReason, 'cancelReason', 500);
  assertOptionalBoundedString(input.carrierDeliveryEvidence, 'carrierDeliveryEvidence', 1000);
  assertOptionalBoundedString(input.overrideReason, 'overrideReason', 500);

  for (const field of ['overrideWindow', 'overridePaymentGate'] as const) {
    if (input[field] !== undefined && input[field] !== null && typeof input[field] !== 'boolean') {
      throw new OrderServiceError(`${field} không hợp lệ.`, 'INVALID_TRANSITION_INPUT', 400);
    }
  }

  if (input.idempotencyKey !== undefined && !isValidIdempotencyKey(input.idempotencyKey)) {
    throw new OrderServiceError('idempotencyKey không hợp lệ.', 'INVALID_IDEMPOTENCY_KEY', 400);
  }

  if (input.metadata !== undefined && input.metadata !== null &&
      (typeof input.metadata !== 'object' || Array.isArray(input.metadata))) {
    throw new OrderServiceError('Dữ liệu metadata đơn hàng không hợp lệ.', 'INVALID_ORDER_METADATA', 400);
  }
}

function resolveTierForSpend(userProfile: any, totalSpent: number, tiersConfig: any): string | undefined {
  const configuredTiers = tiersConfig?.tiers;
  if (!configuredTiers) return userProfile?.tier;

  const tierEntries = Array.isArray(configuredTiers)
    ? configuredTiers.map((tier: any) => [tier.tierId, tier] as const)
    : Object.entries(configuredTiers);

  const matchingTier = tierEntries
    .filter(([, tier]) => typeof (tier as any)?.minSpent === 'number')
    .sort(([, left], [, right]) => (right as any).minSpent - (left as any).minSpent)
    .find(([, tier]) => totalSpent >= (tier as any).minSpent);

  return matchingTier?.[0] || userProfile?.tier;
}

/**
 * Server-authoritative Order Creation with Idempotency & Atomic Reservations
 * All reads execute before all writes to ensure full compatibility with Firestore transactions.
 */
export async function createOrder(
  actor: AuthenticatedActor,
  input: CreateOrderInput,
  deps: OrderServiceDependencies
): Promise<{ order: OrderDocument; isReplay: boolean }> {
  const { uid, email } = actor;

  // 1. Basic validation
  assertValidOrderInput(input, { requireIdempotencyKey: true, requireShippingInfo: true });

  // 2. Read Idempotency Record
  const idempotencyRecordId = `idem_${uid}_create_${input.idempotencyKey}`;
  const requestFingerprint = await generateRequestFingerprint(input);

  const existingRecord = await deps.getIdempotencyRecord(idempotencyRecordId);
  if (existingRecord) {
    if (existingRecord.requestFingerprint !== requestFingerprint) {
      throw new OrderServiceError(
        'Idempotency key reused with different request payload.',
        'IDEMPOTENCY_PAYLOAD_MISMATCH',
        409
      );
    }
    if (existingRecord.status === 'succeeded' && existingRecord.responseSnapshot?.order) {
      return {
        order: existingRecord.responseSnapshot.order as OrderDocument,
        isReplay: true,
      };
    }
    if (existingRecord.status === 'processing') {
      throw new OrderServiceError(
        'Yêu cầu đang được xử lý. Vui lòng chờ trong giây lát.',
        'CONCURRENT_IDEMPOTENCY_REQUEST',
        409
      );
    }
  }

  // 3. Read User Profile & Ban Status
  const userProfile = await deps.getUserProfile(uid);
  if (userProfile?.isBanned) {
    throw new OrderServiceError('Tài khoản của bạn đã bị khóa.', 'ACCOUNT_BANNED', 403);
  }

  const paymentConfig = deps.getPaymentConfig ? await deps.getPaymentConfig() : null;
  if (input.paymentMethod === 'vietqr' && paymentConfig?.isActive === false) {
    throw new OrderServiceError('Thanh toán VietQR hiện đang tạm ngưng.', 'PAYMENT_METHOD_DISABLED', 400);
  }
  const rewardsConfig = normalizeRewardsConfig(
    deps.getRewardsConfig ? await deps.getRewardsConfig() : null,
  );
  if (input.pointsToUse && !rewardsConfig.isActive) {
    throw new OrderServiceError('Tính năng sử dụng điểm hiện đang tạm ngưng.', 'POINTS_DISABLED', 400);
  }
  if (input.pointsToUse && input.pointsToUse < rewardsConfig.minPointsToUse) {
    throw new OrderServiceError(
      `Cần sử dụng tối thiểu ${rewardsConfig.minPointsToUse} điểm.`,
      'MIN_POINTS_REQUIRED',
      400,
    );
  }

  // 4. Read Products & Validate Stock
  const resolvedItems: OrderItem[] = [];
  const productCategoryMap = new Map<string, string>();
  const stockDeductionMap = new Map<string, { productId: string; currentStock: number; qtyNeeded: number }>();

  for (const itemInput of input.items) {
    const product = await deps.getProduct(itemInput.productId);
    if (!product) {
      throw new OrderServiceError(`Sản phẩm (ID: ${itemInput.productId}) không tồn tại.`, 'PRODUCT_NOT_FOUND', 404);
    }
    if (product.isActive === false) {
      throw new OrderServiceError(`Sản phẩm "${product.name}" hiện ngừng kinh doanh.`, 'PRODUCT_INACTIVE', 400);
    }
    assertTierEligible(product, userProfile?.tier);
    if (Array.isArray(product.allowedPaymentMethods) && !product.allowedPaymentMethods.includes(input.paymentMethod)) {
      throw new OrderServiceError(
        `Sản phẩm "${product.name}" yêu cầu phương thức thanh toán khác.`,
        'PRODUCT_PAYMENT_METHOD_NOT_ALLOWED',
        400,
      );
    }

    const qty = Math.max(1, Math.floor(itemInput.quantity));
    const currentStock = typeof product.stock === 'number' ? product.stock : 0;
    const reservedBefore = stockDeductionMap.get(product.id)?.qtyNeeded || 0;
    const reservedAfter = reservedBefore + qty;
    if (currentStock < reservedAfter) {
      throw new OrderServiceError(
        `Sản phẩm "${product.name}" chỉ còn ${currentStock} món trong kho (yêu cầu: ${reservedAfter}).`,
        'INSUFFICIENT_STOCK',
        400
      );
    }

    productCategoryMap.set(product.id, String(product.type || ''));

    // Authoritative item price calculation. No client-calculated prices enter
    // the domain service.
    let unitPrice: number;
    try {
      unitPrice = resolveProductUnitPrice(product, itemInput);
    } catch (error) {
      const message = String(error instanceof Error ? error.message : error);
      const [code, ...details] = message.split(':');
      throw new OrderServiceError(
        code === 'INVALID_PRODUCT_VARIANT'
          ? `Lựa chọn biến thể "${details.join(':')}" không hợp lệ.`
          : `Phụ kiện mua kèm "${details.join(':')}" không còn khả dụng.`,
        code || 'INVALID_PRODUCT_OPTION',
        400,
      );
    }

    resolvedItems.push({
      productId: product.id,
      name: product.name,
      unitPrice,
      quantity: qty,
      lineTotal: unitPrice * qty,
      selectedBox: itemInput.selectedBox || null,
      selectedLang: itemInput.selectedLang || null,
      selectedVariants: itemInput.selectedVariants || null,
      addSleeves: Boolean(itemInput.addSleeves),
      quickAddAccessoryNames: itemInput.quickAddAccessoryNames || null,
      image: product.image || '',
    });

    stockDeductionMap.set(product.id, {
      productId: product.id,
      currentStock,
      qtyNeeded: reservedAfter,
    });
  }

  // 5. Read Shipping Config
  const shippingConfig = deps.getShippingConfig ? await deps.getShippingConfig() : null;
  const defaultShippingFee = safeNonNegativeNumber(shippingConfig?.defaultFee, 30000);
  const freeshipThreshold = shippingConfig?.freeshipThreshold === null
    ? null
    : safeNonNegativeNumber(shippingConfig?.freeshipThreshold, 500000);

  // 6. Read Voucher
  let resolvedVoucher: any = null;
  if (input.discountCode) {
    const codeClean = input.discountCode.trim().toUpperCase();
    const voucher = await deps.getVoucher(codeClean);
    if (!voucher || voucher.isActive === false) {
      throw new OrderServiceError('Mã giảm giá không hợp lệ.', 'INVALID_DISCOUNT_CODE', 400);
    }

    const nowMs = Date.now();
    const startMs = toDate(voucher.startDate)?.getTime() ?? 0;
    const endMs = toDate(voucher.endDate)?.getTime() ?? Infinity;
    if (nowMs < startMs) {
      throw new OrderServiceError('Mã giảm giá chưa đến thời gian sử dụng.', 'DISCOUNT_NOT_STARTED', 400);
    }
    if (nowMs > endMs) {
      throw new OrderServiceError('Mã giảm giá đã hết hạn.', 'DISCOUNT_EXPIRED', 400);
    }
    if (voucher.usageLimit && Number(voucher.usedCount || 0) >= Number(voucher.usageLimit)) {
      throw new OrderServiceError('Mã giảm giá đã hết lượt sử dụng.', 'DISCOUNT_USAGE_EXHAUSTED', 400);
    }
    resolvedVoucher = voucher;
  }

  if (resolvedVoucher) {
    if (resolvedVoucher.customerType && deps.getUserOrderCount) {
      const orderCount = await deps.getUserOrderCount(uid);
      if (resolvedVoucher.customerType === 'new' && orderCount > 0) {
        throw new OrderServiceError('Mã giảm giá chỉ dành cho khách hàng mới.', 'DISCOUNT_CUSTOMER_TYPE_INVALID', 400);
      }
      if (resolvedVoucher.customerType === 'returning' && orderCount === 0) {
        throw new OrderServiceError('Mã giảm giá chỉ dành cho khách hàng cũ.', 'DISCOUNT_CUSTOMER_TYPE_INVALID', 400);
      }
    }
    if (resolvedVoucher.usageLimitPerUser && deps.getUserOrderCount) {
      const usedByUser = await deps.getUserOrderCount(uid, resolvedVoucher.code);
      if (usedByUser >= Number(resolvedVoucher.usageLimitPerUser)) {
        throw new OrderServiceError('Bạn đã hết lượt sử dụng mã giảm giá này.', 'DISCOUNT_USAGE_PER_USER_EXHAUSTED', 400);
      }
    }
    const hasScope = Boolean(resolvedVoucher.applicableProducts?.length || resolvedVoucher.applicableCategories?.length);
    const eligibleItems = resolvedItems.filter((item) => {
      const category = productCategoryMap.get(item.productId) || '';
      if (resolvedVoucher.excludeCategories?.includes(category)) return false;
      if (!hasScope) return true;
      return Boolean(
        resolvedVoucher.applicableProducts?.includes(item.productId) ||
        resolvedVoucher.applicableCategories?.includes(category),
      );
    });
    const eligibleTotal = eligibleItems.reduce((sum, item) => sum + item.lineTotal, 0);
    if (hasScope && eligibleItems.length === 0) {
      throw new OrderServiceError('Mã giảm giá không áp dụng cho sản phẩm trong giỏ hàng.', 'DISCOUNT_SCOPE_INVALID', 400);
    }
    if (resolvedVoucher.minOrderValue && eligibleTotal < resolvedVoucher.minOrderValue) {
      throw new OrderServiceError('Giá trị đơn hàng chưa đạt điều kiện của mã giảm giá.', 'DISCOUNT_MIN_ORDER_NOT_MET', 400);
    }
    if (resolvedVoucher.applicableTiers?.length && !resolvedVoucher.applicableTiers.includes(userProfile?.tier || 'bronze')) {
      throw new OrderServiceError('Mã giảm giá không áp dụng cho hạng thành viên hiện tại.', 'DISCOUNT_TIER_NOT_ELIGIBLE', 400);
    }
  }

  // 7. Authoritative Calculation (In-memory, no I/O)
  const userPointsBalance = typeof userProfile?.points === 'number' ? userProfile.points : 0;
  const pointsRequested = Math.max(0, Math.floor(input.pointsToUse || 0));

  const moneyBreakdown = calculateOrderTotals({
    items: resolvedItems.map((item) => ({
      ...item,
      category: productCategoryMap.get(item.productId),
    })),
    defaultShippingFee,
    shippingActive: shippingConfig?.isActive !== false,
    hasFreeshipProduct: Array.isArray(shippingConfig?.freeshipProductIds) &&
      resolvedItems.some((item) => shippingConfig.freeshipProductIds.includes(item.productId)),
    freeshipThreshold,
    voucher: resolvedVoucher,
    pointsToUse: rewardsConfig.isActive ? pointsRequested : 0,
    userPointsBalance,
    pointsRate: rewardsConfig.pointValueVND,
    maxPointsDiscountPercent: rewardsConfig.maxDiscountPercentage,
  });

  const actualPointsApplied = Math.floor(moneyBreakdown.pointsDiscountAmount / rewardsConfig.pointValueVND);
  const earnedPoints = rewardsConfig.isActive
    ? calculateEarnedPoints({
        rewardEligibleAmount: moneyBreakdown.rewardEligibleAmount,
        tier: userProfile?.tier || 'bronze',
        tierMultipliers: rewardsConfig.tierMultipliers,
      })
    : 0;

  const orderId = generateOrderCode();
  const now = new Date().toISOString();
  const paymentDueAt =
    input.paymentMethod === 'vietqr'
      ? new Date(Date.now() + 30 * 60 * 1000).toISOString() // 30 mins timeout for VietQR
      : null;

  const newOrder: OrderDocument = {
    ...moneyBreakdown,
    id: orderId,
    schemaVersion: 1,
    revision: 1,
    userId: uid,
    currency: 'VND',
    customerEmail: email,
    customerName: input.shippingInfo.fullName,
    items: resolvedItems,
    shippingInfo: input.shippingInfo,
    status: 'pending',
    paymentStatus: 'pending', // Both COD and VietQR start as pending
    paymentMethod: input.paymentMethod,
    paymentDueAt,
    returnEligibleUntil: null,
    discountCode: resolvedVoucher ? resolvedVoucher.code : null,
    pointsApplied: actualPointsApplied,
    earnedPoints,
    trackingCode: null,
    carrierName: null,
    riskScore: 0,
    cancelReason: null,
    returnReason: null,
    stockDisposition: null,
    stockReservedAt: now,
    stockRestoredAt: null,
    stockRestoredReason: null,
    voucherReservedAt: resolvedVoucher ? now : null,
    voucherRestoredAt: null,
    pointsDeductedAt: actualPointsApplied > 0 ? now : null,
    pointsRefundedAt: null,
    rewardGrantedAt: null,
    rewardReversedAt: null,
    rewardReversalDebt: null,
    paymentConfirmedAt: null,
    deliveredAt: null,
    cancelledAt: null,
    refundedAt: null,
    createdAt: now,
    updatedAt: now,
  };

  const orderEvent: OrderEvent = {
    schemaVersion: 1,
    id: `evt_${orderId}_1`,
    sequence: 1,
    orderId,
    eventType: 'order_created',
    actionType: 'create_order',
    actorType: 'customer',
    actorId: uid,
    toStatus: 'pending',
    toPaymentStatus: 'pending',
    sideEffectsExecuted: [
      'stock_reserved',
      ...(actualPointsApplied > 0 ? ['points_debited'] : []),
      ...(resolvedVoucher ? ['voucher_reserved'] : []),
    ],
    idempotencyKey: input.idempotencyKey,
    createdAt: now,
  };

  const idempotencyRecord: IdempotencyRecord = {
    id: idempotencyRecordId,
    schemaVersion: 1,
    scope: 'orders:create',
    actorType: 'customer',
    actorUid: uid,
    requestKeyHash: await generateRequestFingerprint(input.idempotencyKey),
    actorId: uid,
    operation: 'create_order',
    idempotencyKey: input.idempotencyKey,
    requestFingerprint,
    status: 'succeeded',
    resourceId: orderId,
    responseSnapshot: { success: true, order: newOrder },
    orderId,
    resultRef: `orders/${orderId}`,
    resultCode: 'ORDER_CREATED',
    createdAt: now,
    updatedAt: now,
    expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString(),
  };

  // 8. Atomic Writes (Strictly after all reads)
  // A. Deduct stock for all items
  for (const item of stockDeductionMap.values()) {
    await deps.updateProductStock(item.productId, item.currentStock - item.qtyNeeded);
  }

  // B. Deduct points if applied
  if (actualPointsApplied > 0) {
    await deps.updateUserPoints(uid, -actualPointsApplied);
  }

  // C. Increment voucher usage
  if (resolvedVoucher) {
    await deps.incrementVoucherUsage(resolvedVoucher.id);
  }

  // D. Save order document
  await deps.saveOrder(newOrder);

  // E. Save order audit event
  await deps.saveEvent(orderId, orderEvent);

  // F. Save final idempotency record
  await deps.saveIdempotencyRecord(idempotencyRecord);

  return { order: newOrder, isReplay: false };
}

/**
 * Server-authoritative Order Transition with Side-Effect Execution
 * All reads happen before all writes for Firestore transaction compatibility.
 */
export async function transitionOrder(
  actor: AuthenticatedActor,
  input: TransitionOrderInput,
  deps: OrderServiceDependencies
): Promise<{ order: OrderDocument; event: OrderEvent }> {
  assertValidTransitionInput(input);
  const { orderId } = input;

  // 1. Read existing order
  const order = await deps.getOrder(orderId);
  if (!order) {
    throw new OrderServiceError(`Không tìm thấy đơn hàng #${orderId}`, 'ORDER_NOT_FOUND', 404);
  }

  // 2. Map actor role
  const actorType: ActorType = actor.isSuperAdmin
    ? 'super_admin'
    : actor.role === 'admin'
    ? 'admin'
    : 'customer';

  const targetStatus = input.targetStatus || order.status;

  // 3. Resolve action type
  const actionType: ActionType =
    input.actionType ||
    (targetStatus === 'cancelled'
      ? 'cancel_order'
      : targetStatus === 'delivered'
      ? 'mark_delivered'
      : targetStatus === 'shipped'
      ? 'ship_order'
      : targetStatus === 'processing'
      ? 'start_processing'
      : targetStatus === 'failed_delivery'
      ? 'mark_failed_delivery'
      : targetStatus === 'returned'
      ? 'accept_return'
      : targetStatus === 'refunded'
      ? 'complete_refund'
      : 'reconcile_side_effect');

  if (actorType === 'admin') {
    assertCanManageOrders(actor);
  }

  // Telegram callbacks can be delivered more than once. When a caller
  // supplies a key, persist the completed transition snapshot so a retry
  // returns the original result without executing any side effect again.
  const transitionIdempotencyRecordId = input.idempotencyKey
    ? `idem_${actor.uid}_transition_${input.idempotencyKey}`
    : null;
  if (input.idempotencyKey !== undefined && !isValidIdempotencyKey(input.idempotencyKey)) {
    throw new OrderServiceError('idempotencyKey không hợp lệ.', 'INVALID_IDEMPOTENCY_KEY', 400);
  }
  const transitionRequestFingerprint = input.idempotencyKey
    ? await generateRequestFingerprint({ ...input, actionType, targetStatus })
    : null;

  if (transitionIdempotencyRecordId && transitionRequestFingerprint) {
    const existingTransitionRecord = await deps.getIdempotencyRecord(transitionIdempotencyRecordId);
    if (existingTransitionRecord) {
      if (existingTransitionRecord.requestFingerprint !== transitionRequestFingerprint) {
        throw new OrderServiceError(
          'Idempotency key reused with different request payload.',
          'IDEMPOTENCY_PAYLOAD_MISMATCH',
          409
        );
      }
      if (existingTransitionRecord.status === 'succeeded') {
        const snapshot = existingTransitionRecord.responseSnapshot;
        if (snapshot?.order && snapshot.event) {
          return {
            order: snapshot.order as OrderDocument,
            event: snapshot.event as OrderEvent,
          };
        }
        throw new OrderServiceError(
          'Idempotency record không có response snapshot hợp lệ.',
          'CORRUPT_IDEMPOTENCY_RECORD',
          500
        );
      }
      if (existingTransitionRecord.status === 'processing') {
        throw new OrderServiceError(
          'Yêu cầu đang được xử lý. Vui lòng chờ trong giây lát.',
          'CONCURRENT_IDEMPOTENCY_REQUEST',
          409
        );
      }
    }
  }

  const saveTransitionIdempotencyRecord = async (updatedOrder: OrderDocument, event: OrderEvent) => {
    if (!transitionIdempotencyRecordId || !transitionRequestFingerprint || !input.idempotencyKey) return;
    const now = new Date().toISOString();
    await deps.saveIdempotencyRecord({
      id: transitionIdempotencyRecordId,
      schemaVersion: 1,
      scope: 'orders:transition',
      actorType,
      actorUid: actor.uid,
      requestKeyHash: await generateRequestFingerprint(input.idempotencyKey),
      actorId: actor.uid,
      operation: actionType,
      idempotencyKey: input.idempotencyKey,
      requestFingerprint: transitionRequestFingerprint,
      status: 'succeeded',
      resourceId: order.id,
      responseSnapshot: { success: true, order: updatedOrder, event },
      orderId: order.id,
      resultRef: `orders/${order.id}`,
      resultCode: 'ORDER_TRANSITIONED',
      createdAt: now,
      updatedAt: now,
      expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString(),
    });
  };

  if (actionType === 'update_order_metadata') {
    assertCanManageOrders(actor);
    if (!input.metadata || Object.keys(input.metadata).length === 0) {
      throw new OrderServiceError('Không có dữ liệu đơn hàng cần cập nhật.', 'EMPTY_ORDER_METADATA', 400);
    }
    validateOrderMetadata(input.metadata);

    const now = new Date().toISOString();
    const nextRevision = (order.revision || 1) + 1;
    const orderUpdates: Partial<OrderDocument> = {
      ...input.metadata,
      revision: nextRevision,
      updatedAt: now,
    };
    await deps.updateOrder(order.id, orderUpdates);

    const event: OrderEvent = {
      schemaVersion: 1,
      id: `evt_${order.id}_${nextRevision}`,
      sequence: nextRevision,
      orderId: order.id,
      eventType: 'order_metadata_updated',
      actionType: 'update_order_metadata',
      actorType,
      actorId: actor.uid,
      fromStatus: order.status,
      toStatus: order.status,
      fromPaymentStatus: order.paymentStatus,
      toPaymentStatus: order.paymentStatus,
      sideEffectsExecuted: [],
      idempotencyKey: input.idempotencyKey,
      createdAt: now,
    };
    const updatedOrder = { ...order, ...orderUpdates };
    await deps.saveEvent(order.id, event);
    await saveTransitionIdempotencyRecord(updatedOrder, event);

    return { order: updatedOrder, event };
  }

  // Payment confirmation is a valid admin command even when it does not
  // change the order status. It remains idempotent for repeated callbacks.
  if (actionType === 'confirm_payment' && targetStatus === order.status) {
    assertCanManageOrders(actor);
    if (order.paymentStatus === 'paid') {
      const replayEvent: OrderEvent = {
        schemaVersion: 1,
        id: `evt_${order.id}_${order.revision}_payment_replay`,
        sequence: order.revision,
        orderId: order.id,
        eventType: 'operation_replayed',
        actionType: 'confirm_payment',
        actorType,
        actorId: actor.uid,
        fromStatus: order.status,
        toStatus: order.status,
        fromPaymentStatus: order.paymentStatus,
        toPaymentStatus: order.paymentStatus,
        sideEffectsExecuted: ['payment_already_paid'],
        idempotencyKey: input.idempotencyKey,
        createdAt: new Date().toISOString(),
      };
      await saveTransitionIdempotencyRecord(order, replayEvent);
      return { order, event: replayEvent };
    }

    const now = new Date().toISOString();
    const nextRevision = (order.revision || 1) + 1;
    const orderUpdates: Partial<OrderDocument> = {
      paymentStatus: 'paid',
      paidAmount: Math.max(0, order.paidAmount || order.finalAmount || 0),
      paymentConfirmedAt: now,
      revision: nextRevision,
      updatedAt: now,
    };
    await deps.updateOrder(order.id, orderUpdates);

    const event: OrderEvent = {
      schemaVersion: 1,
      id: `evt_${order.id}_${nextRevision}`,
      sequence: nextRevision,
      orderId: order.id,
      eventType: 'payment_status_changed',
      actionType: 'confirm_payment',
      actorType,
      actorId: actor.uid,
      fromStatus: order.status,
      toStatus: order.status,
      fromPaymentStatus: order.paymentStatus,
      toPaymentStatus: 'paid',
      sideEffectsExecuted: ['payment_confirmed'],
      idempotencyKey: input.idempotencyKey,
      createdAt: now,
    };
    await deps.saveEvent(order.id, event);

    const updatedOrder = { ...order, ...orderUpdates };
    await saveTransitionIdempotencyRecord(updatedOrder, event);

    return { order: updatedOrder, event };
  }

  // 4. Plan transition & side effects
  const transitionReq: TransitionRequest = {
    targetStatus,
    actorType,
    actorId: actor.uid,
    actionType,
    paymentStatus: input.paymentStatus,
    cancelReason: input.cancelReason,
    returnReason: input.returnReason,
    stockDisposition: input.stockDisposition,
    carrierDeliveryEvidence: input.carrierDeliveryEvidence,
    overrideWindow: input.overrideWindow,
    overridePaymentGate: input.overridePaymentGate,
    overrideReason: input.overrideReason,
  };

  const plan = planOrderTransition(order, transitionReq);

  // 5. Read phase for side effects (all reads before writes)
  let userProfile: any = null;
  let tiersConfig: any = null;
  if (
    plan.sideEffects.grantReward ||
    plan.sideEffects.refundPoints ||
    plan.sideEffects.reverseReward
  ) {
    userProfile = await deps.getUserProfile(order.userId);
  }
  if (plan.sideEffects.grantReward && deps.getTiersConfig) {
    tiersConfig = await deps.getTiersConfig();
  }

  const stockRestoreMap: Array<{ productId: string; currentStock: number; qtyToRestore: number }> = [];
  if (plan.sideEffects.restoreStock && order.items) {
    for (const item of order.items) {
      const product = await deps.getProduct(item.productId);
      if (product) {
        stockRestoreMap.push({
          productId: item.productId,
          currentStock: typeof product.stock === 'number' ? product.stock : 0,
          qtyToRestore: item.quantity,
        });
      }
    }
  }

  let voucherToRelease: any = null;
  if (plan.sideEffects.releaseVoucher && order.discountCode && deps.decrementVoucherUsage) {
    voucherToRelease = await deps.getVoucher(order.discountCode);
  }

  // 6. Write phase (executed strictly after all reads)
  const now = new Date().toISOString();
  const sideEffectsExecuted: string[] = [];

  // A. Restore stock
  if (plan.sideEffects.restoreStock && stockRestoreMap.length > 0) {
    for (const restoreItem of stockRestoreMap) {
      await deps.updateProductStock(restoreItem.productId, restoreItem.currentStock + restoreItem.qtyToRestore);
    }
    sideEffectsExecuted.push('stock_restored');
  }

  // B. Refund used points
  if (plan.sideEffects.refundPoints && order.pointsApplied && order.pointsApplied > 0) {
    await deps.updateUserPoints(order.userId, order.pointsApplied);
    sideEffectsExecuted.push('points_refunded');
  }

  // C. Grant loyalty rewards and update the delivered-order customer stats.
  if (plan.sideEffects.grantReward) {
    const grossPoints = Math.max(0, order.earnedPoints || 0);
    const existingDebt = Math.max(0, userProfile?.rewardReversalDebt || 0);
    const debtApplied = Math.min(grossPoints, existingDebt);
    const pointsToGrant = grossPoints - debtApplied;
    const totalSpentDelta = Math.max(0, order.rewardEligibleAmount || 0);
    const nextTier = resolveTierForSpend(
      userProfile,
      Math.max(0, (userProfile?.totalSpent || 0) + totalSpentDelta),
      tiersConfig
    );

    if (deps.updateUserRewardStats) {
      await deps.updateUserRewardStats(order.userId, {
        pointsDelta: pointsToGrant,
        totalSpentDelta,
        totalOrdersDelta: 1,
        rewardReversalDebtDelta: -debtApplied,
        tier: nextTier,
      });
    } else if (pointsToGrant > 0) {
      await deps.updateUserPoints(order.userId, pointsToGrant);
    }

    if (debtApplied > 0) sideEffectsExecuted.push('reward_reversal_debt_applied');
    sideEffectsExecuted.push('reward_granted', 'customer_stats_updated');
  }

  // D. Reverse loyalty rewards
  let reversalDebt: number | null = null;
  if (plan.sideEffects.reverseReward) {
    const earnedPoints = Math.max(0, order.earnedPoints || 0);
    const reversal = calculateRewardReversal({
      currentBalance: userProfile?.points || 0,
      earnedPointsToReverse: earnedPoints,
    });
    if (deps.updateUserRewardStats) {
      await deps.updateUserRewardStats(order.userId, {
        pointsDelta: -reversal.deductedPoints,
        totalSpentDelta: -Math.max(0, order.rewardEligibleAmount || 0),
        totalOrdersDelta: -1,
        rewardReversalDebtDelta: reversal.debtCreated,
      });
    } else if (reversal.deductedPoints > 0) {
      await deps.updateUserPoints(order.userId, -reversal.deductedPoints);
    }
    reversalDebt = reversal.debtCreated;
    sideEffectsExecuted.push('reward_reversed', 'customer_stats_reversed');
  }

  // E. Release voucher usage
  if (voucherToRelease && deps.decrementVoucherUsage) {
    await deps.decrementVoucherUsage(voucherToRelease.id);
    sideEffectsExecuted.push('voucher_restored');
  }

  if (plan.sideEffects.setRefundPending) sideEffectsExecuted.push('refund_requested');
  if (plan.sideEffects.setRefunded) sideEffectsExecuted.push('refund_completed');

  // 7. Compute updated order document
  const nextRevision = (order.revision || 1) + 1;
  const orderUpdates: Partial<OrderDocument> = {
    status: plan.toStatus,
    paymentStatus: plan.toPaymentStatus,
    revision: nextRevision,
    updatedAt: now,
  };

  if (plan.toPaymentStatus === 'paid' && (order.paymentStatus !== 'paid' || !(order.paidAmount > 0))) {
    orderUpdates.paymentConfirmedAt = now;
    orderUpdates.paidAmount = Math.max(0, order.paidAmount || order.finalAmount || 0);
  }

  if (plan.toStatus === 'cancelled') {
    orderUpdates.cancelledAt = now;
    orderUpdates.cancelReason = input.cancelReason || `Hủy bởi ${actorType}`;
    if (plan.sideEffects.restoreStock) {
      orderUpdates.stockRestoredAt = now;
      orderUpdates.stockRestoredReason = 'order_cancelled';
    }
    if (plan.sideEffects.releaseVoucher) {
      orderUpdates.voucherRestoredAt = now;
    }
    if (plan.sideEffects.refundPoints) {
      orderUpdates.pointsRefundedAt = now;
    }
  } else if (plan.toStatus === 'delivered') {
    orderUpdates.deliveredAt = now;
    if (plan.sideEffects.grantReward) {
      orderUpdates.rewardGrantedAt = now;
    }
    if (plan.sideEffects.setPaymentPaid) {
      orderUpdates.paymentConfirmedAt = now;
      orderUpdates.paidAmount = Math.max(0, order.paidAmount || order.finalAmount || 0);
    }
    orderUpdates.returnEligibleUntil = new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString();
  } else if (plan.toStatus === 'returned') {
    orderUpdates.returnReason = input.returnReason;
    orderUpdates.stockDisposition = input.stockDisposition;
    if (plan.sideEffects.restoreStock) {
      orderUpdates.stockRestoredAt = now;
      orderUpdates.stockRestoredReason = 'customer_return';
    }
    if (plan.sideEffects.reverseReward) {
      orderUpdates.rewardReversedAt = now;
      orderUpdates.rewardReversalDebt = reversalDebt;
    }
  } else if (plan.toStatus === 'refunded') {
    orderUpdates.refundedAt = now;
    const paidAmount = Math.max(0, order.paidAmount || (order.paymentStatus === 'paid' ? order.finalAmount : 0));
    const refundAmount = calculateRefundAmount({
      order: {
        paidAmount,
        finalAmount: order.finalAmount,
        shippingFee: order.shippingFee,
        status: order.status,
      },
      reason: input.returnReason || order.returnReason,
      isPreShipmentCancel: order.status === 'pending' || order.status === 'suspicious' || order.status === 'processing',
    });
    orderUpdates.paidAmount = paidAmount;
    orderUpdates.refundAmount = Math.min(paidAmount, Math.max(0, refundAmount));
    if (plan.sideEffects.reverseReward) {
      orderUpdates.rewardReversedAt = now;
      orderUpdates.rewardReversalDebt = reversalDebt;
    }
  }

  await deps.updateOrder(order.id, orderUpdates);

  // 8. Save Audit Event
  const event: OrderEvent = {
    schemaVersion: 1,
    id: `evt_${order.id}_${nextRevision}`,
    sequence: nextRevision,
    orderId: order.id,
    eventType: plan.toStatus === 'cancelled'
      ? 'status_changed'
      : plan.toStatus === 'delivered'
      ? 'status_changed'
      : 'status_changed',
    actionType,
    actorType,
    actorId: actor.uid,
    fromStatus: plan.fromStatus,
    toStatus: plan.toStatus,
    fromPaymentStatus: plan.fromPaymentStatus,
    toPaymentStatus: plan.toPaymentStatus,
    sideEffectsExecuted,
    reason: input.overrideReason || plan.reason,
    idempotencyKey: input.idempotencyKey,
    createdAt: now,
  };

  await deps.saveEvent(order.id, event);

  const updatedOrder: OrderDocument = {
    ...order,
    ...orderUpdates,
  };

  await saveTransitionIdempotencyRecord(updatedOrder, event);

  return { order: updatedOrder, event };
}
