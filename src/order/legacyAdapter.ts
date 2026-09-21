/**
 * Legacy Order Adapter for TQSShop.
 * Safely normalizes orders without schemaVersion into canonical OrderDocument format.
 * Implements "Legacy Fail Closed" invariant: does NOT guess missing side-effect markers.
 */

import type { OrderDocument, OrderItem, OrderStatus, PaymentMethod, PaymentStatus } from './canonical.js';

export function normalizeLegacyOrder(raw: Record<string, unknown>): OrderDocument {
  const schemaVersion = typeof raw.schemaVersion === 'number' ? raw.schemaVersion : 0;
  const rawItems = Array.isArray(raw.items) ? raw.items : [];

  const items: OrderItem[] = rawItems.map((item: any) => ({
    productId: String(item.productId || item.id || ''),
    name: String(item.name || 'Unnamed Item'),
    unitPrice: typeof item.price === 'number' ? item.price : 0,
    quantity: typeof item.quantity === 'number' ? item.quantity : 1,
    lineTotal: (typeof item.price === 'number' ? item.price : 0) * (typeof item.quantity === 'number' ? item.quantity : 1),
    selectedBox: item.selectedBox || null,
    selectedLang: item.selectedLang || null,
    selectedVariants: item.selectedVariants || null,
    addSleeves: Boolean(item.addSleeves),
    quickAddAccessoryNames: item.quickAddAccessoryNames || null,
    image: String(item.image || ''),
  }));

  const totalAmount = typeof raw.totalAmount === 'number' ? raw.totalAmount : 0;
  const shippingFee = typeof raw.shippingFee === 'number' ? raw.shippingFee : 0;
  const discountAmount = typeof raw.discountAmount === 'number' ? raw.discountAmount : 0;
  const finalAmount = typeof raw.finalAmount === 'number' ? raw.finalAmount : Math.max(0, totalAmount + shippingFee - discountAmount);

  // In legacy orders, discount breakdown was not separated
  const voucherDiscountAmount = raw.discountCode ? discountAmount : 0;
  const pointsDiscountAmount = raw.discountCode ? 0 : discountAmount;
  const rewardEligibleAmount = Math.max(0, totalAmount - discountAmount);

  const rawStatus = String(raw.status || 'pending') as OrderStatus;
  const rawPaymentStatus = String(raw.paymentStatus || 'pending') as PaymentStatus;
  const rawPaymentMethod = (String(raw.paymentMethod || 'cod').toLowerCase() === 'vietqr' ? 'vietqr' : 'cod') as PaymentMethod;

  const shippingInfo = (raw.shippingInfo as Record<string, unknown>) || {};

  return {
    id: String(raw.id || ''),
    schemaVersion,
    revision: typeof raw.revision === 'number' ? raw.revision : 1,
    userId: String(raw.userId || ''),
    customerEmail: String(raw.customerEmail || shippingInfo.email || ''),
    customerName: String(raw.customerName || shippingInfo.fullName || ''),
    items,
    shippingInfo: {
      fullName: String(shippingInfo.fullName || ''),
      phone: String(shippingInfo.phone || ''),
      address: String(shippingInfo.address || ''),
      notes: String(shippingInfo.notes || ''),
      city: shippingInfo.city ? String(shippingInfo.city) : undefined,
      district: shippingInfo.district ? String(shippingInfo.district) : undefined,
      ward: shippingInfo.ward ? String(shippingInfo.ward) : undefined,
    },
    status: rawStatus,
    paymentStatus: rawPaymentStatus,
    paymentMethod: rawPaymentMethod,
    totalAmount,
    shippingFee,
    voucherDiscountAmount,
    pointsDiscountAmount,
    discountAmount,
    finalAmount,
    rewardEligibleAmount,
    paidAmount: rawPaymentStatus === 'paid' ? finalAmount : 0,
    refundAmount: 0,
    // Side effect markers are preserved if present, otherwise NULL (no guessing)
    stockReservedAt: (raw.stockReservedAt as string) || null,
    stockRestoredAt: (raw.stockRestoredAt as string) || null,
    stockRestoredReason: (raw.stockRestoredReason as string) || null,
    voucherReservedAt: (raw.voucherReservedAt as string) || null,
    voucherRestoredAt: (raw.voucherRestoredAt as string) || null,
    pointsDeductedAt: (raw.pointsDeductedAt as string) || null,
    pointsRefundedAt: (raw.pointsRefundedAt as string) || null,
    rewardGrantedAt: (raw.rewardGrantedAt as string) || null,
    rewardReversedAt: (raw.rewardReversedAt as string) || null,
    rewardReversalDebt: (raw.rewardReversalDebt as number) || null,
    paymentConfirmedAt: (raw.paymentConfirmedAt as string) || null,
    deliveredAt: (raw.deliveredAt as string) || null,
    cancelledAt: (raw.cancelledAt as string) || null,
    refundedAt: (raw.refundedAt as string) || null,
    paymentDueAt: (raw.paymentDueAt as string) || null,
    returnEligibleUntil: (raw.returnEligibleUntil as string) || null,
    discountCode: raw.discountCode ? String(raw.discountCode) : null,
    pointsApplied: typeof raw.pointsApplied === 'number' ? raw.pointsApplied : 0,
    earnedPoints: typeof raw.earnedPoints === 'number' ? raw.earnedPoints : 0,
    trackingCode: raw.trackingCode ? String(raw.trackingCode) : null,
    carrierName: raw.carrierName ? String(raw.carrierName) : null,
    riskScore: typeof raw.riskScore === 'number' ? raw.riskScore : 0,
    cancelReason: raw.cancelReason ? String(raw.cancelReason) : null,
    returnReason: (raw.returnReason as any) || null,
    stockDisposition: (raw.stockDisposition as any) || null,
    createdAt: String(raw.createdAt || new Date().toISOString()),
    updatedAt: String(raw.updatedAt || new Date().toISOString()),
  };
}
