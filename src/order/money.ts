/**
 * Pure monetary and point calculation functions for TQSShop Order Service.
 * Implements server-authoritative financial invariants defined in Gate 2.
 */

import type { OrderDocument, OrderMoneyBreakdown, ReturnReason } from './canonical.js';

export interface CalculateOrderTotalsInput {
  items: Array<{ unitPrice: number; quantity: number; productId?: string; category?: string }>;
  defaultShippingFee: number;
  shippingActive?: boolean;
  hasFreeshipProduct?: boolean;
  freeshipThreshold?: number | null;
  voucher?: {
    code: string;
    discountType: 'percentage' | 'fixed' | 'freeship_only';
    discountValue: number;
    maxDiscount?: number;
    minOrderValue?: number;
    isFreeship?: boolean;
    applicableProducts?: string[];
    applicableCategories?: string[];
    excludeCategories?: string[];
  } | null;
  pointsToUse?: number;
  userPointsBalance?: number;
  pointsRate?: number;            // Value in VND per 1 point (default: 1,000 VND)
  maxPointsDiscountPercent?: number; // Max % of merchandise total that can be paid with points (default: 50%)
}

export function calculateOrderTotals(input: CalculateOrderTotalsInput): OrderMoneyBreakdown {
  const {
    items,
    defaultShippingFee,
    shippingActive = true,
    hasFreeshipProduct = false,
    freeshipThreshold = null,
    voucher = null,
    pointsToUse = 0,
    userPointsBalance = 0,
    pointsRate = 1000,
    maxPointsDiscountPercent = 50,
  } = input;

  // 1. Calculate merchandise subtotal
  const totalAmount = items.reduce((sum, item) => {
    const itemTotal = Math.max(0, Math.round(item.unitPrice)) * Math.max(1, Math.round(item.quantity));
    return sum + itemTotal;
  }, 0);

  // 2. Calculate shipping fee
  let shippingFee = shippingActive ? Math.max(0, Math.round(defaultShippingFee)) : 0;
  const qualifiesForThresholdFreeship =
    freeshipThreshold !== null && freeshipThreshold !== undefined && totalAmount >= freeshipThreshold;

  if (qualifiesForThresholdFreeship || hasFreeshipProduct) {
    shippingFee = 0;
  }

  // 3. Calculate voucher discount
  let voucherDiscountAmount = 0;
  let voucherGrantsFreeship = false;

  if (voucher) {
    const hasProductScope = Boolean(voucher.applicableProducts?.length || voucher.applicableCategories?.length);
    const eligibleItems = items.filter((item) => {
      const category = item.category || '';
      const excluded = voucher.excludeCategories?.includes(category) === true;
      if (excluded) return false;
      if (!hasProductScope) return true;
      return Boolean(
        (item.productId && voucher.applicableProducts?.includes(item.productId)) ||
        (category && voucher.applicableCategories?.includes(category))
      );
    });
    const eligibleAmount = eligibleItems.reduce(
      (sum, item) => sum + Math.max(0, Math.round(item.unitPrice)) * Math.max(1, Math.round(item.quantity)),
      0
    );
    // Check minimum order value condition
    const meetsMinOrder = (!hasProductScope || eligibleItems.length > 0) &&
      (!voucher.minOrderValue || eligibleAmount >= voucher.minOrderValue);

    if (meetsMinOrder) {
      if (voucher.discountType === 'freeship_only') {
        voucherGrantsFreeship = true;
      } else if (voucher.discountType === 'percentage') {
        const rawDiscount = Math.round((eligibleAmount * voucher.discountValue) / 100);
        voucherDiscountAmount = voucher.maxDiscount
          ? Math.min(rawDiscount, voucher.maxDiscount)
          : rawDiscount;
        if (voucher.isFreeship) {
          voucherGrantsFreeship = true;
        }
      } else if (voucher.discountType === 'fixed') {
        voucherDiscountAmount = Math.min(eligibleAmount, Math.round(voucher.discountValue));
        if (voucher.isFreeship) {
          voucherGrantsFreeship = true;
        }
      }
    }
  }

  // Apply voucher freeship
  if (voucherGrantsFreeship) {
    voucherDiscountAmount += shippingFee;
    shippingFee = 0;
  }

  // 4. Calculate points discount
  // User cannot use more points than they have, and points are capped at max % of merchandise
  const availablePoints = Math.max(0, Math.min(Math.floor(pointsToUse), Math.floor(userPointsBalance)));
  const maxPointsDiscountValue = Math.round((totalAmount * maxPointsDiscountPercent) / 100);
  const requestedPointsValue = availablePoints * pointsRate;
  const pointsDiscountAmount = Math.min(requestedPointsValue, maxPointsDiscountValue);

  // 5. Total combined discount compatibility field
  const discountAmount = voucherDiscountAmount + pointsDiscountAmount;

  // 6. Final Amount to collect (minimum 0)
  const finalAmount = Math.max(0, totalAmount + shippingFee - voucherDiscountAmount - pointsDiscountAmount);

  // 7. Reward eligible amount: merchandise total minus voucher and points discounts (never negative)
  const rewardEligibleAmount = Math.max(0, totalAmount - voucherDiscountAmount - pointsDiscountAmount);

  return {
    totalAmount,
    shippingFee,
    voucherDiscountAmount,
    pointsDiscountAmount,
    discountAmount,
    finalAmount,
    rewardEligibleAmount,
    paidAmount: 0,
    refundAmount: 0,
  };
}

export interface CalculateRefundInput {
  order: Pick<OrderDocument, 'paidAmount' | 'finalAmount' | 'shippingFee' | 'status'>;
  reason?: ReturnReason | null;
  isPreShipmentCancel?: boolean;
}

export function calculateRefundAmount(input: CalculateRefundInput): number {
  const { order, reason, isPreShipmentCancel = false } = input;
  const paid = Math.max(0, order.paidAmount);

  if (paid === 0) {
    return 0; // If nothing was paid, refund is 0 (COD before delivery)
  }

  // Pre-shipment cancellation: full refund of whatever was paid
  if (isPreShipmentCancel || order.status === 'pending' || order.status === 'suspicious' || order.status === 'processing') {
    return paid;
  }

  // Return scenarios:
  const isMerchantFault = reason === 'defective' || reason === 'wrong_item' || reason === 'transit_damage';

  if (isMerchantFault) {
    // Merchant fault: full refund of paid amount including original shipping
    return paid;
  }

  if (reason === 'change_of_mind') {
    // Change of mind: customer absorbs original shipping fee
    const shippingFee = Math.max(0, order.shippingFee);
    return Math.max(0, paid - shippingFee);
  }

  // Default fallback: refund whatever was paid
  return paid;
}

export interface CalculateEarnedPointsInput {
  rewardEligibleAmount: number;
  tier?: 'bronze' | 'silver' | 'gold' | 'diamond';
  // Point earning rate: e.g. 1 point for every 10,000 VND (rate = 0.0001)
  baseEarnRate?: number;
  tierMultipliers?: Record<string, number>;
}

export function calculateEarnedPoints(input: CalculateEarnedPointsInput): number {
  const {
    rewardEligibleAmount,
    tier = 'bronze',
    baseEarnRate = 0.0001, // 1 pt per 10k VND
    tierMultipliers = { bronze: 1.0, silver: 1.2, gold: 1.5, diamond: 2.0 },
  } = input;

  const multiplier = tierMultipliers[tier] || 1.0;
  const rawPoints = rewardEligibleAmount * baseEarnRate * multiplier;
  return Math.max(0, Math.floor(rawPoints));
}

export interface CalculateRewardReversalInput {
  currentBalance: number;
  earnedPointsToReverse: number;
}

export interface RewardReversalResult {
  deductedPoints: number;
  newBalance: number;
  debtCreated: number;
}

/**
 * Reverses loyalty reward points safely without ever allowing points balance to become negative.
 * If user does not have enough points, records debtCreated to deduct from future grants.
 */
export function calculateRewardReversal(input: CalculateRewardReversalInput): RewardReversalResult {
  const current = Math.max(0, input.currentBalance);
  const toReverse = Math.max(0, input.earnedPointsToReverse);

  if (current >= toReverse) {
    return {
      deductedPoints: toReverse,
      newBalance: current - toReverse,
      debtCreated: 0,
    };
  }

  // Not enough balance: deduct all remaining points to 0 and record the deficit as debt
  return {
    deductedPoints: current,
    newBalance: 0,
    debtCreated: toReverse - current,
  };
}
