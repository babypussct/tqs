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
import { generateRequestFingerprint } from './fingerprint.js';
import {
  calculateEarnedPoints,
  calculateOrderTotals,
  calculateRefundAmount,
  calculateRewardReversal,
} from './money.js';
import { planOrderTransition } from './transitions.js';
import type { TransitionRequest } from './transitions.js';

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
  if (!input.items || !Array.isArray(input.items) || input.items.length === 0) {
    throw new OrderServiceError('Giỏ hàng không được để trống.', 'EMPTY_CART', 400);
  }
  if (!input.shippingInfo || !input.shippingInfo.fullName || !input.shippingInfo.phone || !input.shippingInfo.address) {
    throw new OrderServiceError('Thông tin giao hàng không đầy đủ.', 'INVALID_SHIPPING_INFO', 400);
  }
  if (!['cod', 'vietqr'].includes(input.paymentMethod)) {
    throw new OrderServiceError('Phương thức thanh toán không hợp lệ.', 'INVALID_PAYMENT_METHOD', 400);
  }
  if (!input.idempotencyKey || typeof input.idempotencyKey !== 'string') {
    throw new OrderServiceError('Thiếu idempotencyKey.', 'MISSING_IDEMPOTENCY_KEY', 400);
  }

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

  // 4. Read Products & Validate Stock
  const resolvedItems: OrderItem[] = [];
  const stockDeductionMap: Array<{ productId: string; currentStock: number; qtyNeeded: number }> = [];

  for (const itemInput of input.items) {
    const product = await deps.getProduct(itemInput.productId);
    if (!product) {
      throw new OrderServiceError(`Sản phẩm (ID: ${itemInput.productId}) không tồn tại.`, 'PRODUCT_NOT_FOUND', 404);
    }
    if (product.isActive === false) {
      throw new OrderServiceError(`Sản phẩm "${product.name}" hiện ngừng kinh doanh.`, 'PRODUCT_INACTIVE', 400);
    }

    const qty = Math.max(1, Math.floor(itemInput.quantity));
    const currentStock = typeof product.stock === 'number' ? product.stock : 0;
    if (currentStock < qty) {
      throw new OrderServiceError(
        `Sản phẩm "${product.name}" chỉ còn ${currentStock} món trong kho (yêu cầu: ${qty}).`,
        'INSUFFICIENT_STOCK',
        400
      );
    }

    // Authoritative item price calculation (base price + variants adjustments)
    let unitPrice = Math.max(0, product.price || 0);

    // Add custom variants price adjustment if applicable
    if (itemInput.selectedVariants && product.customVariants) {
      for (const [varName, optName] of Object.entries(itemInput.selectedVariants)) {
        const varDef = product.customVariants.find((cv: any) => cv.name === varName);
        if (varDef) {
          const optDef = varDef.options.find((opt: any) => opt.name === optName);
          if (optDef && optDef.priceAdjustment) {
            unitPrice += optDef.priceAdjustment;
          }
        }
      }
    }

    // Sleeves add-on price
    if (itemInput.addSleeves) {
      unitPrice += 20000;
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

    stockDeductionMap.push({
      productId: product.id,
      currentStock,
      qtyNeeded: qty,
    });
  }

  // 5. Read Shipping Config
  const shippingConfig = deps.getShippingConfig ? await deps.getShippingConfig() : null;
  const defaultShippingFee = shippingConfig?.defaultFee !== undefined ? shippingConfig.defaultFee : 30000;
  const freeshipThreshold = shippingConfig?.freeshipThreshold !== undefined ? shippingConfig.freeshipThreshold : 500000;

  // 6. Read Voucher
  let resolvedVoucher: any = null;
  if (input.discountCode) {
    const codeClean = input.discountCode.trim().toUpperCase();
    const voucher = await deps.getVoucher(codeClean);
    if (voucher && voucher.isActive !== false) {
      const nowMs = Date.now();
      const startMs = voucher.startDate ? new Date(voucher.startDate).getTime() : 0;
      const endMs = voucher.endDate ? new Date(voucher.endDate).getTime() : Infinity;

      if (nowMs >= startMs && nowMs <= endMs) {
        if (!voucher.usageLimit || (voucher.usedCount || 0) < voucher.usageLimit) {
          resolvedVoucher = voucher;
        }
      }
    }
  }

  // 7. Authoritative Calculation (In-memory, no I/O)
  const userPointsBalance = typeof userProfile?.points === 'number' ? userProfile.points : 0;
  const pointsRequested = Math.max(0, Math.floor(input.pointsToUse || 0));

  const moneyBreakdown = calculateOrderTotals({
    items: resolvedItems,
    defaultShippingFee,
    freeshipThreshold,
    voucher: resolvedVoucher,
    pointsToUse: pointsRequested,
    userPointsBalance,
  });

  const actualPointsApplied = Math.floor(moneyBreakdown.pointsDiscountAmount / 1000);
  const earnedPoints = calculateEarnedPoints({
    rewardEligibleAmount: moneyBreakdown.rewardEligibleAmount,
    tier: userProfile?.tier || 'bronze',
  });

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
    actorId: uid,
    operation: 'create_order',
    idempotencyKey: input.idempotencyKey,
    requestFingerprint,
    status: 'succeeded',
    resourceId: orderId,
    responseSnapshot: { success: true, order: newOrder },
    createdAt: now,
    updatedAt: now,
    expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString(),
  };

  // 8. Atomic Writes (Strictly after all reads)
  // A. Deduct stock for all items
  for (const item of stockDeductionMap) {
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
      actorId: actor.uid,
      operation: actionType,
      idempotencyKey: input.idempotencyKey,
      requestFingerprint: transitionRequestFingerprint,
      status: 'succeeded',
      resourceId: order.id,
      responseSnapshot: { success: true, order: updatedOrder, event },
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
      paymentConfirmedAt: now,
      revision: nextRevision,
      updatedAt: now,
    };
    await deps.updateOrder(order.id, orderUpdates);

    const event: OrderEvent = {
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

  // 7. Compute updated order document
  const nextRevision = (order.revision || 1) + 1;
  const orderUpdates: Partial<OrderDocument> = {
    status: plan.toStatus,
    paymentStatus: plan.toPaymentStatus,
    revision: nextRevision,
    updatedAt: now,
  };

  if (plan.toPaymentStatus === 'paid' && order.paymentStatus !== 'paid') {
    orderUpdates.paymentConfirmedAt = now;
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
    }
    orderUpdates.returnEligibleUntil = new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString();
  } else if (plan.toStatus === 'returned') {
    orderUpdates.returnReason = input.returnReason || 'other';
    orderUpdates.stockDisposition = input.stockDisposition || 'sellable';
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
    if (plan.sideEffects.reverseReward) {
      orderUpdates.rewardReversedAt = now;
      orderUpdates.rewardReversalDebt = reversalDebt;
    }
  }

  await deps.updateOrder(order.id, orderUpdates);

  // 8. Save Audit Event
  const event: OrderEvent = {
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
