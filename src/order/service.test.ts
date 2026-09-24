/**
 * Comprehensive Unit Tests for TQSShop Order Service (createOrder & transitionOrder).
 * Tests business policies, atomic invariants, idempotency, side effects, and error handling.
 */

import {
  createOrder,
  transitionOrder,
  OrderServiceDependencies,
  CreateOrderInput,
  AuthenticatedActor,
} from './orderService';
import { OrderDocument, OrderEvent, IdempotencyRecord } from './canonical';

// In-memory mock database store
class MockDb {
  public products = new Map<string, any>();
  public vouchers = new Map<string, any>();
  public users = new Map<string, any>();
  public orders = new Map<string, OrderDocument>();
  public events = new Map<string, OrderEvent[]>();
  public idempotency = new Map<string, IdempotencyRecord>();
  public shippingConfig: any = { defaultFee: 30000, freeshipThreshold: 500000 };

  public getDeps(): OrderServiceDependencies {
    return {
      getProduct: async (id: string) => {
        const p = this.products.get(id);
        return p ? JSON.parse(JSON.stringify(p)) : null;
      },
      updateProductStock: async (id: string, newStock: number) => {
        const p = this.products.get(id);
        if (p) {
          p.stock = newStock;
        }
      },
      getVoucher: async (code: string) => {
        const v = this.vouchers.get(code.toUpperCase());
        // Keep Firestore-like Timestamp objects intact so the service tests
        // exercise the same boundary as the Admin SDK adapter.
        return v ? { ...v } : null;
      },
      incrementVoucherUsage: async (voucherId: string) => {
        for (const v of this.vouchers.values()) {
          if (v.id === voucherId) {
            v.usedCount = (v.usedCount || 0) + 1;
          }
        }
      },
      decrementVoucherUsage: async (voucherId: string) => {
        for (const v of this.vouchers.values()) {
          if (v.id === voucherId) {
            v.usedCount = Math.max(0, (v.usedCount || 1) - 1);
          }
        }
      },
      getUserProfile: async (uid: string) => {
        const u = this.users.get(uid);
        return u ? JSON.parse(JSON.stringify(u)) : null;
      },
      updateUserPoints: async (uid: string, pointsDelta: number) => {
        const u = this.users.get(uid);
        if (u) {
          u.points = (u.points || 0) + pointsDelta;
        }
      },
      updateUserRewardStats: async (uid, update) => {
        const u = this.users.get(uid);
        if (!u) return;
        if (update.pointsDelta !== undefined) u.points = (u.points || 0) + update.pointsDelta;
        if (update.totalSpentDelta !== undefined) u.totalSpent = (u.totalSpent || 0) + update.totalSpentDelta;
        if (update.totalOrdersDelta !== undefined) u.totalOrders = (u.totalOrders || 0) + update.totalOrdersDelta;
        if (update.rewardReversalDebtDelta !== undefined) {
          u.rewardReversalDebt = Math.max(0, (u.rewardReversalDebt || 0) + update.rewardReversalDebtDelta);
        }
        if (update.tier !== undefined) u.tier = update.tier;
      },
      saveOrder: async (order: OrderDocument) => {
        this.orders.set(order.id, JSON.parse(JSON.stringify(order)));
      },
      getOrder: async (orderId: string) => {
        const o = this.orders.get(orderId);
        return o ? JSON.parse(JSON.stringify(o)) : null;
      },
      updateOrder: async (orderId: string, updates: Partial<OrderDocument>) => {
        const o = this.orders.get(orderId);
        if (o) {
          Object.assign(o, updates);
        }
      },
      saveEvent: async (orderId: string, event: OrderEvent) => {
        const existing = this.events.get(orderId) || [];
        existing.push(JSON.parse(JSON.stringify(event)));
        this.events.set(orderId, existing);
      },
      getIdempotencyRecord: async (id: string) => {
        const r = this.idempotency.get(id);
        return r ? JSON.parse(JSON.stringify(r)) : null;
      },
      saveIdempotencyRecord: async (record: IdempotencyRecord) => {
        this.idempotency.set(record.id, JSON.parse(JSON.stringify(record)));
      },
      getShippingConfig: async () => this.shippingConfig,
    };
  }
}

async function runTests() {
  console.log('🧪 Running Order Service Unit Tests...\n');
  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, msg: string) {
    if (condition) {
      console.log(`  ✅ PASS: ${msg}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${msg}`);
      failed++;
    }
  }

  // =========================================================================
  // SCENARIO 1: Server Authoritative Pricing & Inventory Deduction
  // =========================================================================
  console.log('--- Test 1: Order Creation (Server Pricing & Stock Deduction) ---');
  const db1 = new MockDb();
  db1.products.set('prod_1', { id: 'prod_1', name: 'Board Game A', price: 200000, stock: 10, isActive: true });
  db1.users.set('user_1', { uid: 'user_1', email: 'cust1@test.com', points: 50, tier: 'silver', isBanned: false });

  const actor1: AuthenticatedActor = { uid: 'user_1', email: 'cust1@test.com', role: 'customer' };
  const input1: CreateOrderInput = {
    items: [{ productId: 'prod_1', quantity: 2 }],
    shippingInfo: {
      fullName: 'Nguyen Van A',
      phone: '0912345678',
      address: '123 Nguyen Trai, Ha Noi',
    },
    paymentMethod: 'cod',
    idempotencyKey: 'idem_key_001',
  };

  const result1 = await createOrder(actor1, input1, db1.getDeps());
  assert(!result1.isReplay, 'Order created as fresh (not replay)');
  assert(result1.order.totalAmount === 400000, 'Total calculated by server = 2 * 200k = 400,000 VND');
  assert(result1.order.shippingFee === 30000, 'Shipping fee applied = 30,000 VND');
  assert(result1.order.finalAmount === 430000, 'Final amount = 430,000 VND');
  assert(result1.order.status === 'pending', 'Order status initialized to pending');
  assert(result1.order.paymentStatus === 'pending', 'COD payment status initialized to pending');
  assert(db1.products.get('prod_1').stock === 8, 'Product stock deducted from 10 to 8');
  assert(db1.events.get(result1.order.id)?.length === 1, 'Audit event recorded');

  // =========================================================================
  // SCENARIO 2: Insufficient Stock Rejection
  // =========================================================================
  console.log('\n--- Test 2: Insufficient Stock Rejection ---');
  let stockErrorCaught = false;
  try {
    await createOrder(
      actor1,
      {
        ...input1,
        idempotencyKey: 'idem_key_overstock',
        items: [{ productId: 'prod_1', quantity: 20 }], // requests 20, but stock is 8
      },
      db1.getDeps()
    );
  } catch (err: any) {
    stockErrorCaught = true;
    assert(err.code === 'INSUFFICIENT_STOCK', `Rejected with INSUFFICIENT_STOCK error code (was: ${err.code})`);
  }
  assert(stockErrorCaught, 'Throws when requested quantity exceeds stock');
  assert(db1.products.get('prod_1').stock === 8, 'Stock remains unchanged at 8 after failed order');

  // =========================================================================
  // SCENARIO 3: Idempotency Replay vs Payload Mismatch
  // =========================================================================
  console.log('\n--- Test 3: Idempotency Replay & Fingerprint Protection ---');
  // Re-submit identical request with same idempotency key
  const replayResult = await createOrder(actor1, input1, db1.getDeps());
  assert(replayResult.isReplay === true, 'Duplicate request identified as replay');
  assert(replayResult.order.id === result1.order.id, 'Replays the exact same order document');
  assert(db1.products.get('prod_1').stock === 8, 'Stock is NOT deducted again on replay (remains 8)');

  // Submit different payload with the same key
  let mismatchCaught = false;
  try {
    await createOrder(
      actor1,
      {
        ...input1,
        paymentMethod: 'vietqr', // changed from cod to vietqr
      },
      db1.getDeps()
    );
  } catch (err: any) {
    mismatchCaught = true;
    assert(err.code === 'IDEMPOTENCY_PAYLOAD_MISMATCH', 'Throws 409 Conflict IDEMPOTENCY_PAYLOAD_MISMATCH');
  }
  assert(mismatchCaught, 'Reusing key with different payload is strictly blocked');

  // =========================================================================
  // SCENARIO 4: Voucher Usage & Points Deduction
  // =========================================================================
  console.log('\n--- Test 4: Voucher Usage Limit & Points Deduction ---');
  const db4 = new MockDb();
  db4.products.set('prod_1', { id: 'prod_1', name: 'Game', price: 500000, stock: 5, isActive: true });
  db4.vouchers.set('VOUCHER50K', {
    id: 'vouch_1',
    code: 'VOUCHER50K',
    discountType: 'fixed',
    discountValue: 50000,
    isActive: true,
    startDate: { toDate: () => new Date(Date.now() - 60_000) },
    endDate: { toDate: () => new Date(Date.now() + 60_000) },
    usageLimit: 10,
    usedCount: 2,
  });
  db4.users.set('user_4', { uid: 'user_4', email: 'cust4@test.com', points: 30, tier: 'bronze', isBanned: false });

  const actor4: AuthenticatedActor = { uid: 'user_4', email: 'cust4@test.com', role: 'customer' };
  const input4: CreateOrderInput = {
    items: [{ productId: 'prod_1', quantity: 1 }],
    shippingInfo: { fullName: 'Tran B', phone: '0988776655', address: '456 Le Loi, HCM' },
    paymentMethod: 'vietqr',
    discountCode: 'VOUCHER50K',
    pointsToUse: 20, // 20 points = 20,000 VND
    idempotencyKey: 'idem_voucher_points',
  };

  const order4Result = await createOrder(actor4, input4, db4.getDeps());
  assert(order4Result.order.voucherDiscountAmount === 50000, 'Voucher discount = 50,000 VND');
  assert(order4Result.order.pointsDiscountAmount === 20000, 'Points discount = 20,000 VND');
  assert(order4Result.order.pointsApplied === 20, 'Points applied recorded as 20');
  // Total: 500,000 (freeship triggered since total >= 500k) - 50,000 - 20,000 = 430,000
  assert(order4Result.order.finalAmount === 430000, 'Final amount = 430,000 VND');
  assert(db4.vouchers.get('VOUCHER50K').usedCount === 3, 'Voucher usedCount incremented from 2 to 3');
  assert(db4.users.get('user_4').points === 10, 'User points debited from 30 to 10');

  // =========================================================================
  // SCENARIO 5: Customer Cancellation with Stock & Point Restoration
  // =========================================================================
  console.log('\n--- Test 5: Order Cancellation Side-Effects ---');
  const cancelResult = await transitionOrder(
    actor4,
    {
      orderId: order4Result.order.id,
      targetStatus: 'cancelled',
      cancelReason: 'Customer changed mind before shipping',
    },
    db4.getDeps()
  );

  assert(cancelResult.order.status === 'cancelled', 'Order transitioned to cancelled');
  assert(Boolean(cancelResult.order.stockRestoredAt), 'stockRestoredAt timestamp recorded');
  assert(Boolean(cancelResult.order.pointsRefundedAt), 'pointsRefundedAt timestamp recorded');
  assert(Boolean(cancelResult.order.voucherRestoredAt), 'voucherRestoredAt timestamp recorded');
  assert(db4.products.get('prod_1').stock === 5, 'Inventory restored from 4 back to 5');
  assert(db4.users.get('user_4').points === 30, 'User points refunded from 10 back to 30');
  assert(db4.vouchers.get('VOUCHER50K').usedCount === 2, 'Voucher usedCount decremented back to 2');

  // Second cancel attempt must fail
  let duplicateCancelCaught = false;
  try {
    await transitionOrder(
      actor4,
      { orderId: order4Result.order.id, targetStatus: 'cancelled' },
      db4.getDeps()
    );
  } catch (err: any) {
    duplicateCancelCaught = true;
  }
  assert(duplicateCancelCaught, 'Cannot re-cancel an already cancelled order');

  // =========================================================================
  // SCENARIO 6: Order Delivery & Loyalty Points Award
  // =========================================================================
  console.log('\n--- Test 6: Order Delivery & Loyalty Points Grant ---');
  const db6 = new MockDb();
  db6.products.set('prod_6', { id: 'prod_6', name: 'Item', price: 100000, stock: 10, isActive: true });
  db6.users.set('user_6', { uid: 'user_6', email: 'c6@test.com', points: 0, tier: 'bronze', isBanned: false });

  const cust6: AuthenticatedActor = { uid: 'user_6', email: 'c6@test.com', role: 'customer' };
  const adminActor: AuthenticatedActor = {
    uid: 'admin_1',
    email: 'admin@tqs.vn',
    role: 'admin',
    permissions: { manageOrders: true },
  };

  const { order: order6 } = await createOrder(
    cust6,
    {
      items: [{ productId: 'prod_6', quantity: 1 }],
      shippingInfo: { fullName: 'Customer Six', phone: '0901234567', address: '12 Pho Hue, HN' },
      paymentMethod: 'cod',
      idempotencyKey: 'idem_delivery_test',
    },
    db6.getDeps()
  );

  // Transition: pending -> processing (admin)
  await transitionOrder(adminActor, { orderId: order6.id, targetStatus: 'processing' }, db6.getDeps());

  // Transition: processing -> shipped (admin)
  await transitionOrder(adminActor, { orderId: order6.id, targetStatus: 'shipped' }, db6.getDeps());

  // Transition: shipped -> delivered (admin)
  const deliveredRes = await transitionOrder(
    adminActor,
    { orderId: order6.id, targetStatus: 'delivered' },
    db6.getDeps()
  );

  assert(deliveredRes.order.status === 'delivered', 'Order transitioned to delivered');
  assert(deliveredRes.order.paymentStatus === 'paid', 'COD paymentStatus automatically set to paid upon delivery');
  assert(Boolean(deliveredRes.order.rewardGrantedAt), 'rewardGrantedAt recorded');
  assert(Boolean(deliveredRes.order.returnEligibleUntil), 'returnEligibleUntil 7-day window set');
  // Bronze tier = 1 pt per 10k VND of 100k = 10 pts
  assert(db6.users.get('user_6').points === 10, 'Loyalty reward point credited to user (10 pts for 100k VND)');
  assert(db6.users.get('user_6').totalOrders === 1, 'Delivered order increments totalOrders exactly once');
  assert(db6.users.get('user_6').totalSpent === 100000, 'Delivered order increments totalSpent from reward-eligible amount');

  const returnedRes = await transitionOrder(
    adminActor,
    {
      orderId: order6.id,
      targetStatus: 'returned',
      returnReason: 'defective',
      stockDisposition: 'sellable',
    },
    db6.getDeps()
  );
  assert(returnedRes.order.status === 'returned', 'Delivered order can enter the approved return path');
  assert(Boolean(returnedRes.order.rewardReversedAt), 'Reward reversal marker recorded on return');
  assert(db6.users.get('user_6').points === 0, 'Returned order reverses granted points once');
  assert(db6.users.get('user_6').totalOrders === 0, 'Returned order reverses totalOrders');
  assert(db6.users.get('user_6').totalSpent === 0, 'Returned order reverses reward-eligible spend');

  // =========================================================================
  // SCENARIO 7: Security Boundaries & Role Enforcement
  // =========================================================================
  console.log('\n--- Test 7: Security Boundaries & Role Enforcement ---');
  // Create an order in pending status to test customer forbidden transition
  const { order: pendingOrder } = await createOrder(
    cust6,
    {
      items: [{ productId: 'prod_6', quantity: 1 }],
      shippingInfo: { fullName: 'Customer Six', phone: '0901234567', address: '12 Pho Hue, HN' },
      paymentMethod: 'cod',
      idempotencyKey: 'idem_forbidden_test',
    },
    db6.getDeps()
  );

  // Customer attempts to self-transition to processing
  let custProcessingCaught = false;
  try {
    await transitionOrder(
      cust6,
      { orderId: pendingOrder.id, targetStatus: 'processing' },
      db6.getDeps()
    );
  } catch (err: any) {
    custProcessingCaught = true;
    assert(err.code === 'FORBIDDEN_TRANSITION', 'Customer cannot self-transition to processing (throws FORBIDDEN_TRANSITION)');
  }
  assert(custProcessingCaught, 'Customer forbidden from transitioning order to processing');

  // Direct shipped -> cancelled forbidden
  const { order: order7 } = await createOrder(
    cust6,
    {
      items: [{ productId: 'prod_6', quantity: 1 }],
      shippingInfo: { fullName: 'Customer Six', phone: '0901234567', address: '12 Pho Hue, HN' },
      paymentMethod: 'cod',
      idempotencyKey: 'idem_shipped_cancel_test',
    },
    db6.getDeps()
  );
  await transitionOrder(adminActor, { orderId: order7.id, targetStatus: 'processing' }, db6.getDeps());
  await transitionOrder(adminActor, { orderId: order7.id, targetStatus: 'shipped' }, db6.getDeps());

  let illegalCancelCaught = false;
  try {
    await transitionOrder(
      adminActor,
      { orderId: order7.id, targetStatus: 'cancelled' },
      db6.getDeps()
    );
  } catch (err: any) {
    illegalCancelCaught = true;
    assert(err.code === 'ILLEGAL_TRANSITION', 'Illegal transition from shipped to cancelled blocked');
  }
  assert(illegalCancelCaught, 'State machine rejects shipped -> cancelled transition');

  // =========================================================================
  // SCENARIO 8: Metadata & Payment Commands Stay Inside the Service
  // =========================================================================
  console.log('\n--- Test 8: Metadata & Payment Command Authorization ---');
  const paymentResult = await transitionOrder(
    adminActor,
    { orderId: pendingOrder.id, actionType: 'confirm_payment' },
    db6.getDeps()
  );
  assert(paymentResult.order.paymentStatus === 'paid', 'Admin payment command marks payment as paid');
  assert(paymentResult.event.actionType === 'confirm_payment', 'Payment confirmation records the canonical action');

  const paymentReplay = await transitionOrder(
    adminActor,
    { orderId: pendingOrder.id, actionType: 'confirm_payment' },
    db6.getDeps()
  );
  assert(paymentReplay.event.eventType === 'operation_replayed', 'Repeated payment command is idempotently replayed');

  const metadataResult = await transitionOrder(
    adminActor,
    {
      orderId: pendingOrder.id,
      actionType: 'update_order_metadata',
      metadata: { trackingCode: 'SPX123456', actualShippingCost: 18000 },
    },
    db6.getDeps()
  );
  assert(metadataResult.order.trackingCode === 'SPX123456', 'Admin metadata command updates tracking code');
  assert(metadataResult.order.actualShippingCost === 18000, 'Admin metadata command updates shipping cost');
  assert(metadataResult.event.eventType === 'order_metadata_updated', 'Metadata update records an audit event');

  let metadataPermissionCaught = false;
  try {
    await transitionOrder(
      cust6,
      {
        orderId: pendingOrder.id,
        actionType: 'update_order_metadata',
        metadata: { trackingCode: 'FORGED' },
      },
      db6.getDeps()
    );
  } catch (err: any) {
    metadataPermissionCaught = true;
    assert(err.code === 'ORDER_PERMISSION_REQUIRED', 'Customer cannot update order metadata');
  }
  assert(metadataPermissionCaught, 'Metadata command requires order-management permission');

  const telegramCallbackKey = 'tg_cq_unit_test_001';
  const callbackTransition = await transitionOrder(
    adminActor,
    { orderId: pendingOrder.id, targetStatus: 'processing', idempotencyKey: telegramCallbackKey },
    db6.getDeps()
  );
  const callbackReplay = await transitionOrder(
    adminActor,
    { orderId: pendingOrder.id, targetStatus: 'processing', idempotencyKey: telegramCallbackKey },
    db6.getDeps()
  );
  assert(callbackReplay.event.id === callbackTransition.event.id, 'Telegram callback retry replays the original transition event');
  assert(
    (db6.events.get(pendingOrder.id) || []).filter((event) => event.id === callbackTransition.event.id).length === 1,
    'Telegram callback retry does not append a duplicate event'
  );

  let missingPermissionCaught = false;
  try {
    await transitionOrder(
      { ...adminActor, permissions: {} },
      { orderId: pendingOrder.id, targetStatus: 'processing' },
      db6.getDeps()
    );
  } catch (err: any) {
    missingPermissionCaught = true;
    assert(err.code === 'ORDER_PERMISSION_REQUIRED', 'Admin without manageOrders permission is rejected');
  }
  assert(missingPermissionCaught, 'Status transition requires manageOrders permission');

  let cancelPermissionCaught = false;
  try {
    await transitionOrder(
      { ...adminActor, permissions: {} },
      { orderId: pendingOrder.id, targetStatus: 'cancelled', actionType: 'cancel_order' },
      db6.getDeps()
    );
  } catch (err: any) {
    cancelPermissionCaught = true;
    assert(err.code === 'ORDER_PERMISSION_REQUIRED', 'Admin without manageOrders cannot cancel orders');
  }
  assert(cancelPermissionCaught, 'Cancellation also requires manageOrders permission for admins');

  // Summary
  console.log('\n=============================================================');
  console.log(`Order Service Test Suite: ${passed} PASSED, ${failed} FAILED`);
  console.log('=============================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Fatal error in tests:', err);
  process.exit(1);
});
