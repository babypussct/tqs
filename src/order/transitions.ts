/**
 * Transition validation and side-effect planner for TQSShop Order Service.
 * Implements the state machine and actor permissions defined in Gate 2 & Gate 3.
 */

import {
  ActionType,
  ActorType,
  ALLOWED_TRANSITIONS,
  OrderDocument,
  OrderStatus,
  PaymentStatus,
  ReturnReason,
  StockDisposition,
} from './canonical';

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
    // Grant loyalty points if not already granted
    if (!order.rewardGrantedAt && (order.earnedPoints || 0) > 0) {
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
    // Reverse reward points if previously granted
    if (order.rewardGrantedAt && !order.rewardReversedAt && (order.earnedPoints || 0) > 0) {
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
    sideEffects.setRefunded = true;
    targetPaymentStatus = 'refunded';
    // If returning directly from delivered (emergency exception)
    if (order.rewardGrantedAt && !order.rewardReversedAt && (order.earnedPoints || 0) > 0) {
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
