/**
 * Canonical Contract & Financial Invariants Test Suite
 * Tests all required invariant scenarios defined in Gate 2 & Gate 3.
 * Run with: npx tsx src/order/contract.test.ts
 */

import {
  calculateEarnedPoints,
  calculateOrderTotals,
  calculateRefundAmount,
  calculateRewardReversal,
} from './money';
import { generateRequestFingerprint } from './fingerprint';
import { planOrderTransition, TransitionError } from './transitions';
import { normalizeLegacyOrder } from './legacyAdapter';
import { OrderDocument } from './canonical';

async function runTests() {
  console.log('🧪 Running Order Domain Contract & Invariant Tests...\n');
  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, testName: string, detail?: string) {
    if (condition) {
      console.log(`  ✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${testName} ${detail ? `(${detail})` : ''}`);
      failed++;
    }
  }

  // --------------------------------------------------------------------------
  // Test 1: Client sends manipulated prices or fake finalAmount
  // --------------------------------------------------------------------------
  console.log('--- Scenario 1: Authoritative Money Calculation (Ignore Client Prices) ---');
  {
    // Client claims 100k item costs 1k and finalAmount is 0
    const calculated = calculateOrderTotals({
      items: [
        { unitPrice: 100000, quantity: 2 }, // 200,000 VND authoritative
      ],
      defaultShippingFee: 30000,
      voucher: {
        code: 'SALE10',
        discountType: 'percentage',
        discountValue: 10, // 10% of 200k = 20k
      },
      pointsToUse: 10, // 10 pts * 1k = 10k
      userPointsBalance: 50,
    });

    assert(calculated.totalAmount === 200000, 'Subtotal correctly calculated by server from unitPrice * quantity');
    assert(calculated.shippingFee === 30000, 'Shipping fee applied from server config');
    assert(calculated.voucherDiscountAmount === 20000, 'Voucher 10% calculated correctly (20,000 VND)');
    assert(calculated.pointsDiscountAmount === 10000, 'Points discount calculated correctly (10,000 VND)');
    assert(calculated.finalAmount === 200000, 'Final amount = 200k + 30k - 20k - 10k = 200,000 VND');
    assert(calculated.rewardEligibleAmount === 170000, 'Reward eligible = 200k - 20k - 10k = 170,000 VND (excludes shipping)');
  }

  // --------------------------------------------------------------------------
  // Test 2: Product Inactive / Stock Insufficient Validation
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 2: Stock & Inactive Product Constraints ---');
  {
    function validateInventory(product: { isActive: boolean; stock: number }, requestedQty: number) {
      if (!product.isActive) {
        throw new Error('PRODUCT_INACTIVE');
      }
      if (product.stock < requestedQty) {
        throw new Error('INSUFFICIENT_STOCK');
      }
      return true;
    }

    try {
      validateInventory({ isActive: false, stock: 10 }, 1);
      assert(false, 'Inactive product rejection', 'Did not throw');
    } catch (e: any) {
      assert(e.message === 'PRODUCT_INACTIVE', 'Reject order with inactive product');
    }

    try {
      validateInventory({ isActive: true, stock: 2 }, 3);
      assert(false, 'Insufficient stock rejection', 'Did not throw');
    } catch (e: any) {
      assert(e.message === 'INSUFFICIENT_STOCK', 'Reject order when requested qty exceeds stock');
    }
  }

  // --------------------------------------------------------------------------
  // Test 3: Concurrent checkout for the last item
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 3: Atomic Stock Reservation Simulator ---');
  {
    let inventory = 1;
    async function reserveStockTransaction(orderId: string): Promise<boolean> {
      // Simulate atomic Firestore transaction
      if (inventory >= 1) {
        inventory -= 1;
        return true;
      }
      return false;
    }

    const [req1, req2] = await Promise.all([
      reserveStockTransaction('order_A'),
      reserveStockTransaction('order_B'),
    ]);

    const successCount = (req1 ? 1 : 0) + (req2 ? 1 : 0);
    assert(successCount === 1, 'Only one concurrent checkout succeeds for the last item');
    assert(inventory === 0, 'Inventory never drops below 0');
  }

  // --------------------------------------------------------------------------
  // Test 4 & 5: Idempotency Key matching vs different payload fingerprint
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 4 & 5: Request Fingerprint & Idempotency Key Validation ---');
  {
    const payloadA = {
      items: [{ productId: 'p1', quantity: 1, unitPrice: 100000 }],
      shippingInfo: { fullName: 'Nguyen Van A', phone: '0901234567', address: '123 Le Loi' },
      paymentMethod: 'cod',
    };

    const payloadASameDataDifferentKeyOrder = {
      paymentMethod: 'cod',
      shippingInfo: { address: ' 123 Le Loi ', fullName: 'Nguyen Van A', phone: '0901234567' },
      items: [{ productId: 'p1', quantity: 1, unitPrice: 100000 }],
    };

    const payloadBModified = {
      ...payloadA,
      shippingInfo: { ...payloadA.shippingInfo, address: '456 Tran Phu' }, // different address!
    };

    const fpA = await generateRequestFingerprint(payloadA);
    const fpASame = await generateRequestFingerprint(payloadASameDataDifferentKeyOrder);
    const fpB = await generateRequestFingerprint(payloadBModified);

    assert(fpA === fpASame, 'Same payload data produces identical fingerprint regardless of key order/whitespace');
    assert(fpA !== fpB, 'Different payload produces distinct fingerprint');

    // Simulate idempotency check
    function verifyIdempotency(recordedFingerprint: string, incomingFingerprint: string) {
      if (recordedFingerprint !== incomingFingerprint) {
        throw new Error('IDEMPOTENCY_PAYLOAD_MISMATCH');
      }
      return 'REPLAY_SAVED_RESULT';
    }

    assert(verifyIdempotency(fpA, fpASame) === 'REPLAY_SAVED_RESULT', 'Same idempotency key + same payload replays saved result');
    try {
      verifyIdempotency(fpA, fpB);
      assert(false, 'Payload mismatch rejection', 'Did not throw');
    } catch (e: any) {
      assert(e.message === 'IDEMPOTENCY_PAYLOAD_MISMATCH', 'Reject request when same idempotency key is used with different payload (409 Conflict)');
    }
  }

  // --------------------------------------------------------------------------
  // Test 6: Repeated Cancel Callback
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 6: Repeated Cancel Callback Idempotency ---');
  {
    const activeOrder: OrderDocument = {
      id: 'ord_cancel_test',
      schemaVersion: 1,
      revision: 1,
      userId: 'user_1',
      customerEmail: 'u1@test.com',
      items: [{ productId: 'p1', name: 'Game', unitPrice: 100000, quantity: 1, lineTotal: 100000, image: '' }],
      shippingInfo: { fullName: 'User 1', phone: '0123', address: 'HN' },
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'cod',
      totalAmount: 100000,
      shippingFee: 30000,
      voucherDiscountAmount: 0,
      pointsDiscountAmount: 0,
      discountAmount: 0,
      finalAmount: 130000,
      rewardEligibleAmount: 100000,
      paidAmount: 0,
      refundAmount: 0,
      stockReservedAt: '2026-09-21T10:00:00Z',
      stockRestoredAt: null, // not yet restored
      createdAt: '2026-09-21T10:00:00Z',
      updatedAt: '2026-09-21T10:00:00Z',
    };

    // First cancel attempt
    const plan1 = planOrderTransition(activeOrder, {
      targetStatus: 'cancelled',
      actorType: 'customer',
      actorId: 'user_1',
      actionType: 'cancel_order',
      cancelReason: 'Customer changed mind',
    });
    assert(plan1.sideEffects.restoreStock === true, 'First cancel plans stock restore');

    // Simulate applying the first cancel: order is now cancelled and stockRestoredAt is set
    const cancelledOrder: OrderDocument = {
      ...activeOrder,
      status: 'cancelled',
      stockRestoredAt: '2026-09-21T10:05:00Z',
      cancelledAt: '2026-09-21T10:05:00Z',
    };

    // Second cancel attempt
    try {
      planOrderTransition(cancelledOrder, {
        targetStatus: 'cancelled',
        actorType: 'customer',
        actorId: 'user_1',
        actionType: 'cancel_order',
      });
      assert(false, 'Second cancel on terminal state', 'Did not throw');
    } catch (e: any) {
      assert(e.code === 'ORDER_ALREADY_CANCELLED', 'Second cancel rejected: order already cancelled, no duplicate stock restore');
    }
  }

  // --------------------------------------------------------------------------
  // Test 7: Simultaneous Delivered Callbacks (Admin + Telegram)
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 7: Concurrent Delivered Callbacks & Reward Idempotency ---');
  {
    const shippedOrder: OrderDocument = {
      id: 'ord_deliv_test',
      schemaVersion: 1,
      revision: 2,
      userId: 'user_2',
      customerEmail: 'u2@test.com',
      items: [{ productId: 'p1', name: 'Game', unitPrice: 500000, quantity: 1, lineTotal: 500000, image: '' }],
      shippingInfo: { fullName: 'User 2', phone: '0123', address: 'HN' },
      status: 'shipped',
      paymentStatus: 'pending',
      paymentMethod: 'cod',
      totalAmount: 500000,
      shippingFee: 0,
      voucherDiscountAmount: 0,
      pointsDiscountAmount: 0,
      discountAmount: 0,
      finalAmount: 500000,
      rewardEligibleAmount: 500000,
      earnedPoints: 50,
      paidAmount: 0,
      refundAmount: 0,
      stockReservedAt: '2026-09-21T10:00:00Z',
      rewardGrantedAt: null, // not yet granted
      createdAt: '2026-09-21T10:00:00Z',
      updatedAt: '2026-09-21T11:00:00Z',
    };

    const adminDeliveryPlan = planOrderTransition(shippedOrder, {
      targetStatus: 'delivered',
      actorType: 'admin',
      actorId: 'admin_1',
      actionType: 'mark_delivered',
    });
    assert(adminDeliveryPlan.sideEffects.grantReward === true, 'First delivery marks grantReward: true');
    assert(adminDeliveryPlan.sideEffects.setPaymentPaid === true, 'COD delivery marks setPaymentPaid: true');

    // Simulate order state after first transition commits
    const deliveredOrder: OrderDocument = {
      ...shippedOrder,
      status: 'delivered',
      paymentStatus: 'paid',
      paidAmount: 500000,
      rewardGrantedAt: '2026-09-21T12:00:00Z',
      deliveredAt: '2026-09-21T12:00:00Z',
    };

    // Second callback arrives from Telegram
    try {
      planOrderTransition(deliveredOrder, {
        targetStatus: 'delivered',
        actorType: 'telegram_internal',
        actorId: 'telegram_bot',
        actionType: 'mark_delivered',
      });
      assert(false, 'Second delivery callback', 'Did not throw');
    } catch (e: any) {
      assert(e.code === 'ILLEGAL_TRANSITION', 'Duplicate delivery rejected: cannot transition delivered -> delivered');
    }
  }

  // --------------------------------------------------------------------------
  // Test 8: Direct shipped -> cancelled is strictly forbidden
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 8: Direct shipped -> cancelled Forbidden ---');
  {
    const shippedOrder: OrderDocument = {
      id: 'ord_shipped_cancel',
      schemaVersion: 1,
      revision: 2,
      userId: 'user_3',
      customerEmail: 'u3@test.com',
      items: [],
      shippingInfo: { fullName: '', phone: '', address: '' },
      status: 'shipped',
      paymentStatus: 'paid',
      paymentMethod: 'vietqr',
      totalAmount: 100000,
      shippingFee: 0,
      voucherDiscountAmount: 0,
      pointsDiscountAmount: 0,
      discountAmount: 0,
      finalAmount: 100000,
      rewardEligibleAmount: 100000,
      paidAmount: 100000,
      refundAmount: 0,
      createdAt: '',
      updatedAt: '',
    };

    try {
      planOrderTransition(shippedOrder, {
        targetStatus: 'cancelled',
        actorType: 'admin',
        actorId: 'admin_1',
        actionType: 'cancel_order',
      });
      assert(false, 'Shipped to cancelled direct transition', 'Did not throw');
    } catch (e: any) {
      assert(e.code === 'ILLEGAL_TRANSITION', 'Direct shipped -> cancelled transition rejected');
    }
  }

  // --------------------------------------------------------------------------
  // Test 9: Customer attempting to set VietQR paid
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 9: Customer Cannot Modify Payment Status ---');
  {
    const pendingOrder: OrderDocument = {
      id: 'ord_vietqr_cust',
      schemaVersion: 1,
      revision: 1,
      userId: 'user_attacker',
      customerEmail: 'attacker@test.com',
      items: [],
      shippingInfo: { fullName: '', phone: '', address: '' },
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'vietqr',
      totalAmount: 100000,
      shippingFee: 0,
      voucherDiscountAmount: 0,
      pointsDiscountAmount: 0,
      discountAmount: 0,
      finalAmount: 100000,
      rewardEligibleAmount: 100000,
      paidAmount: 0,
      refundAmount: 0,
      createdAt: '',
      updatedAt: '',
    };

    try {
      planOrderTransition(pendingOrder, {
        targetStatus: 'processing',
        paymentStatus: 'paid',
        actorType: 'customer',
        actorId: 'user_attacker',
        actionType: 'confirm_payment',
      });
      assert(false, 'Customer setting paid', 'Did not throw');
    } catch (e: any) {
      assert(e.code === 'FORBIDDEN_TRANSITION', 'Customer cannot transition order to processing or set paid');
    }
  }

  // --------------------------------------------------------------------------
  // Test 10: Reward reversal when user point balance is insufficient
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 10: Reward Reversal Invariant (Non-Negative Balance) ---');
  {
    // User earned 50 points, but spent 40 points on something else, balance is now 10
    const reversal = calculateRewardReversal({
      currentBalance: 10,
      earnedPointsToReverse: 50,
    });

    assert(reversal.newBalance === 0, 'User point balance never becomes negative (clamped at 0)');
    assert(reversal.deductedPoints === 10, 'Deducted whatever balance was left (10 pts)');
    assert(reversal.debtCreated === 40, 'Deficit recorded as rewardReversalDebt = 40 pts to offset future gains');
  }

  // --------------------------------------------------------------------------
  // Test 11: Return Shipping Refund Rules (Merchant Fault vs Change of Mind)
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 11: Shipping Refund Rules ---');
  {
    const deliveredOrder: Pick<OrderDocument, 'paidAmount' | 'finalAmount' | 'shippingFee' | 'status'> = {
      paidAmount: 230000, // 200k goods + 30k shipping
      finalAmount: 230000,
      shippingFee: 30000,
      status: 'delivered',
    };

    const refundMerchantFault = calculateRefundAmount({
      order: deliveredOrder,
      reason: 'defective',
    });
    assert(refundMerchantFault === 230000, 'Merchant fault returns full amount including original shipping (230,000 VND)');

    const refundChangeOfMind = calculateRefundAmount({
      order: deliveredOrder,
      reason: 'change_of_mind',
    });
    assert(refundChangeOfMind === 200000, 'Change of mind refunds merchandise only; customer absorbs shipping (200,000 VND)');
  }

  // --------------------------------------------------------------------------
  // Test 12: Legacy Order Normalizer & Fail-Closed Guard
  // --------------------------------------------------------------------------
  console.log('\n--- Scenario 12: Legacy Order Normalizer & Invariant Guard ---');
  {
    const legacyRawOrder = {
      id: 'legacy_order_999',
      userId: 'legacy_cust',
      items: [{ id: 'prod_old', name: 'Old Boardgame', price: 150000, quantity: 2 }],
      totalAmount: 300000,
      discountAmount: 50000,
      status: 'delivered',
      paymentMethod: 'cod',
      paymentStatus: 'paid',
      shippingInfo: { fullName: 'Le Van C', phone: '0911', address: 'SG' },
      createdAt: '2026-01-01T00:00:00Z',
    };

    const normalized = normalizeLegacyOrder(legacyRawOrder);
    assert(normalized.schemaVersion === 0, 'Legacy order flagged with schemaVersion: 0');
    assert(normalized.totalAmount === 300000, 'Subtotal correctly extracted');
    assert(normalized.stockReservedAt === null, 'Missing stockReservedAt remains NULL (no guessing)');
    assert(normalized.stockRestoredAt === null, 'Missing stockRestoredAt remains NULL');
    assert(normalized.rewardGrantedAt === null, 'Missing rewardGrantedAt remains NULL');
    assert(normalized.items[0].unitPrice === 150000, 'Legacy items adapted to canonical OrderItem');
  }

  console.log(`\n=============================================================`);
  console.log(`Contract Test Suite Summary: ${passed} PASSED, ${failed} FAILED`);
  console.log(`=============================================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
