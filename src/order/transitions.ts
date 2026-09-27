/**
 * Transition validation and side-effect planner for TQSShop Order Service.
 * Implements the state machine and actor permissions defined in Gate 2 & Gate 3.
 */

import { ALLOWED_TRANSITIONS } from './canonical.js';
import type {
  ActionType,
  ActorType,
  OrderDocument,
  OrderStatus,
  PaymentStatus,
  ReturnReason,
  StockDisposition,
} from './canonical.js';

export class TransitionError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly status: number = 400
  ) {
    super(message);
    this.name = 'TransitionError';
  }
}

export interface TransitionRequest {
  targetStatus: OrderStatus;
  actorType: ActorType;
  actorId: string;
  actionType: ActionType;
  paymentStatus?: PaymentStatus;
  cancelReason?: string;
  returnReason?: ReturnReason;
  stockDisposition?: StockDisposition;
  carrierDeliveryEvidence?: string;
  overrideWindow?: boolean;
  overridePaymentGate?: boolean;
  overrideReason?: string;
}

export interface PlannedSideEffects {
  restoreStock: boolean;
  stockRestoreQuantityMap?: Record<string, number>;
  releaseVoucher: boolean;
  refundPoints: boolean;
  grantReward: boolean;
  reverseReward: boolean;
  setPaymentPaid: boolean;
  setRefundPending: boolean;
  setRefunded: boolean;
}

export interface TransitionPlan {
  allowed: boolean;
  fromStatus: OrderStatus;
  toStatus: OrderStatus;
  fromPaymentStatus: PaymentStatus;
  toPaymentStatus: PaymentStatus;
  sideEffects: PlannedSideEffects;
  reason?: string;
}

export function planOrderTransition(
  order: OrderDocument,
  request: TransitionRequest
): TransitionPlan {
  const { targetStatus, actorType, actorId } = request;
  const currentStatus = order.status;

  // 1. Terminal State Check
  if (currentStatus === 'cancelled') {
    throw new TransitionError('Cannot transition an already cancelled order', 'ORDER_ALREADY_CANCELLED');
  }
  if (currentStatus === 'refunded') {
    throw new TransitionError('Cannot transition an already refunded order', 'ORDER_ALREADY_REFUNDED');
  }

  // 2. Structural State Transition Check
  const allowedNext = ALLOWED_TRANSITIONS[currentStatus] || [];
  if (!allowedNext.includes(targetStatus)) {
    throw new TransitionError(
      `Illegal transition from '${currentStatus}' to '${targetStatus}'. Allowed: [${allowedNext.join(', ')}]`,
      'ILLEGAL_TRANSITION'
    );
  }

  // 3. Actor Permission & Boundary Checks
  if (actorType === 'customer') {
    // Customers can only cancel pending or suspicious orders before shipment
    if (targetStatus === 'cancelled') {
      if (currentStatus !== 'pending' && currentStatus !== 'suspicious') {
        throw new TransitionError(
          `Customer cannot cancel order once in '${currentStatus}'. Only pending/suspicious can be cancelled.`,
          'CUSTOMER_CANNOT_CANCEL_PROCESSING'
        );
      }
      if (order.userId !== actorId) {
        throw new TransitionError('Customer cannot cancel another user\'s order', 'OWNERSHIP_REQUIRED', 403);
      }
    } else {
      // Customers cannot trigger any other status transition directly
      throw new TransitionError(
        `Customer actor is not permitted to transition order to '${targetStatus}'`,
        'FORBIDDEN_TRANSITION',
        403
      );
    }
  }

  // 4. Specific Path Validations
  if (targetStatus === 'cancelled') {
    if (currentStatus === 'shipped' || currentStatus === 'delivered') {
      throw new TransitionError(
        `Direct transition from '${currentStatus}' to 'cancelled' is forbidden. Must use failed_delivery or returned path.`,
        'FORBIDDEN_CANCEL_AFTER_SHIPMENT'
      );
    }
  }

  if (targetStatus === 'returned' && currentStatus === 'delivered') {
    // Check 7-day return window unless super_admin override
    if (order.returnEligibleUntil && !request.overrideWindow && actorType !== 'super_admin') {
      const returnDeadline = new Date(order.returnEligibleUntil).getTime();
      if (Date.now() > returnDeadline) {
        throw new TransitionError(
          'Return window has expired (7 days from delivery)',
          'RETURN_WINDOW_EXPIRED'
        );
      }
    }
  }

  // Direct delivered -> refunded is an emergency shortcut. It cannot be used
  // by a normal admin to skip the return/inspection workflow.
  if (targetStatus === 'refunded' && currentStatus === 'delivered') {
    if (actorType !== 'super_admin' || !request.overrideReason?.trim()) {
      throw new TransitionError(
        'Direct delivered to refunded requires a super-admin and an audit reason.',
        'SUPER_ADMIN_REFUND_REASON_REQUIRED',
        403,
      );
    }
  }

  // A payment status cannot be forged as part of an ordinary status update.
  // The verified payment command is the only normal path that may mark paid.
  if (
    request.paymentStatus === 'paid' &&
    !['confirm_payment'].includes(request.actionType) &&
    actorType !== 'payment_provider' &&
    actorType !== 'system'
  ) {
    throw new TransitionError(
      'Payment must be confirmed by the dedicated payment command.',
      'PAYMENT_CONFIRMATION_REQUIRED',
      403,
    );
  }

  const requestedPaymentStatus = request.paymentStatus || order.paymentStatus;
  const vietQrNeedsPaid = order.paymentMethod === 'vietqr' &&
    ['processing', 'shipped', 'delivered'].includes(targetStatus) &&
    requestedPaymentStatus !== 'paid';
  if (vietQrNeedsPaid && !(actorType === 'super_admin' && request.overridePaymentGate && request.overrideReason?.trim())) {
    throw new TransitionError(
      'Đơn VietQR phải được xác nhận đã thanh toán trước khi xử lý/giao hàng.',
      'VIETQR_PAYMENT_REQUIRED',
      409,
    );
  }

  if (targetStatus === 'returned') {
    if (!request.returnReason) {
      throw new TransitionError('Thiếu lý do hoàn hàng.', 'RETURN_REASON_REQUIRED', 400);
    }
    if (!request.stockDisposition) {
      throw new TransitionError('Thiếu kết quả kiểm hàng để quyết định hoàn kho.', 'STOCK_DISPOSITION_REQUIRED', 400);
    }
  }

  // 5. Plan Side Effects (Guarded against duplicate execution)
  const sideEffects: PlannedSideEffects = {
    restoreStock: false,
    releaseVoucher: false,
    refundPoints: false,
    grantReward: false,
    reverseReward: false,
    setPaymentPaid: false,
    setRefundPending: false,
    setRefunded: false,
  };

  let targetPaymentStatus = request.paymentStatus || order.paymentStatus;

  // A. Pre-shipment cancellation side effects
  if (targetStatus === 'cancelled') {
    // Restore stock if reserved and not yet restored
    if (order.stockReservedAt && !order.stockRestoredAt) {
      sideEffects.restoreStock = true;
    }
    // Release voucher usage if reserved and not yet restored
    if (order.voucherReservedAt && !order.voucherRestoredAt) {
      sideEffects.releaseVoucher = true;
    }
    // Refund points if deducted and not yet refunded
    if (order.pointsDeductedAt && !order.pointsRefundedAt) {
      sideEffects.refundPoints = true;
    }
    // If order was already paid, flag for refund
    if (order.paymentStatus === 'paid') {
      sideEffects.setRefundPending = true;
      targetPaymentStatus = 'refund_pending';
    }
  }

  // B. Delivery side effects
  if (targetStatus === 'delivered' && currentStatus === 'shipped') {
    // Delivery is the single trigger for reward and customer order stats.
    // The service also records the marker when the calculated reward is zero.
    if (!order.rewardGrantedAt) {
      sideEffects.grantReward = true;
    }
    // For COD, delivery triggers payment completion
    if (order.paymentMethod === 'cod' && order.paymentStatus === 'pending') {
      sideEffects.setPaymentPaid = true;
      targetPaymentStatus = 'paid';
    }
  }

  // C. Return / After-sales side effects
  if (targetStatus === 'returned') {
    // Reverse reward points and delivered-order stats exactly once.
    if (order.rewardGrantedAt && !order.rewardReversedAt) {
      sideEffects.reverseReward = true;
    }
    // Restore stock if sellable and not already restored
    if (request.stockDisposition === 'sellable' && !order.stockRestoredAt) {
      sideEffects.restoreStock = true;
    }
    // If order had paid money, flag for refund
    if (order.paidAmount > 0 && order.paymentStatus !== 'refunded') {
      sideEffects.setRefundPending = true;
      targetPaymentStatus = 'refund_pending';
    }
  }

  // D. Refund completion
  if (targetStatus === 'refunded') {
    // COD orders can be closed after a physical return even when no money was
    // collected. In that case status becomes refunded but payment remains
    // pending; `refunded` is reserved for an actual payment confirmation.
    if (order.paymentStatus === 'paid' || order.paidAmount > 0) {
      sideEffects.setRefunded = true;
      targetPaymentStatus = 'refunded';
    } else {
      targetPaymentStatus = order.paymentStatus;
    }
    // If returning directly from delivered (emergency exception)
    if (order.rewardGrantedAt && !order.rewardReversedAt) {
      sideEffects.reverseReward = true;
    }
  }

  return {
    allowed: true,
    fromStatus: currentStatus,
    toStatus: targetStatus,
    fromPaymentStatus: order.paymentStatus,
    toPaymentStatus: targetPaymentStatus,
    sideEffects,
    reason: request.cancelReason || request.returnReason,
  };
}
