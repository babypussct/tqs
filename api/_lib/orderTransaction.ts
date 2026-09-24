import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import type { IdempotencyRecord, OrderDocument, OrderEvent } from '../../src/order/canonical.js';
import type { OrderServiceDependencies } from '../../src/order/orderService.js';

const ORDER_TIMESTAMP_FIELDS = [
  'createdAt', 'updatedAt', 'paymentDueAt', 'returnEligibleUntil',
  'expiresAt', 'lockExpiresAt',
  'stockReservedAt', 'stockRestoredAt', 'voucherReservedAt', 'voucherRestoredAt',
  'pointsDeductedAt', 'pointsRefundedAt', 'rewardGrantedAt', 'rewardReversedAt',
  'paymentConfirmedAt', 'deliveredAt', 'cancelledAt', 'refundedAt',
] as const;

function toIso(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'object' && value !== null && typeof (value as { toDate?: unknown }).toDate === 'function') {
    return ((value as { toDate: () => Date }).toDate()).toISOString();
  }
  return value;
}

function toFirestoreTimestamp(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === 'object' && value !== null && typeof (value as { toDate?: unknown }).toDate === 'function') {
    return Timestamp.fromDate((value as { toDate: () => Date }).toDate());
  }
  if (typeof value === 'string') {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) return Timestamp.fromDate(date);
  }
  return value;
}

function normalizeTimestamps<T extends Record<string, unknown>>(value: T): T {
  const result = { ...value } as Record<string, unknown>;
  for (const field of ORDER_TIMESTAMP_FIELDS) {
    if (field in result) result[field] = toIso(result[field]);
  }
  return result as T;
}

function serializeTimestamps<T extends Record<string, unknown>>(value: T): T {
  const result = { ...value } as Record<string, unknown>;
  for (const field of ORDER_TIMESTAMP_FIELDS) {
    if (field in result) result[field] = toFirestoreTimestamp(result[field]);
  }
  return result as T;
}

export function normalizeOrderDocument(raw: Record<string, unknown>, id: string): OrderDocument {
  return normalizeTimestamps({
    ...raw,
    id,
    currency: raw.currency || 'VND',
  }) as unknown as OrderDocument;
}

export function serializeOrder(order: OrderDocument): Record<string, unknown> {
  return serializeTimestamps({ ...order } as unknown as Record<string, unknown>);
}

export function serializeOrderUpdates(updates: Partial<OrderDocument>): Record<string, unknown> {
  return serializeTimestamps({ ...updates } as unknown as Record<string, unknown>);
}

export function serializeOrderEvent(event: OrderEvent): Record<string, unknown> {
  return serializeTimestamps({ ...event } as unknown as Record<string, unknown>);
}

export function serializeIdempotencyRecord(record: IdempotencyRecord): Record<string, unknown> {
  return serializeTimestamps({ ...record } as unknown as Record<string, unknown>);
}

export function createOrderTransactionDependencies(
  db: Firestore,
  transaction: Transaction,
): OrderServiceDependencies {
  const orderRef = (id: string) => db.collection('orders').doc(id);

  return {
    getOrder: async (id) => {
      const snapshot = await transaction.get(orderRef(id));
      return snapshot.exists ? normalizeOrderDocument(snapshot.data() || {}, snapshot.id) : null;
    },
    updateOrder: async (id, updates) => {
      transaction.update(orderRef(id), serializeOrderUpdates(updates) as FirebaseFirestore.UpdateData<unknown>);
    },
    saveOrder: async (order) => {
      transaction.set(orderRef(order.id), serializeOrder(order));
    },
    getProduct: async (id) => {
      const snapshot = await transaction.get(db.collection('products').doc(id));
      return snapshot.exists ? { id: snapshot.id, ...snapshot.data() } : null;
    },
    updateProductStock: async (id, stock) => {
      transaction.update(db.collection('products').doc(id), { stock });
    },
    getUserProfile: async (uid) => {
      const snapshot = await transaction.get(db.collection('users').doc(uid));
      return snapshot.exists ? { id: snapshot.id, ...snapshot.data() } : null;
    },
    getUserOrderCount: async (uid, discountCode) => {
      let query = db.collection('orders').where('userId', '==', uid);
      if (discountCode) {
        query = query.where('discountCode', '==', discountCode).where('status', '!=', 'cancelled');
      }
      const snapshot = await transaction.get(query);
      return snapshot.docs.filter((order) => order.data().status !== 'cancelled').length;
    },
    updateUserPoints: async (uid, delta) => {
      transaction.update(db.collection('users').doc(uid), { points: FieldValue.increment(delta) });
    },
    updateUserRewardStats: async (uid, update) => {
      const statsUpdate: Record<string, unknown> = {};
      if (update.pointsDelta !== undefined) statsUpdate.points = FieldValue.increment(update.pointsDelta);
      if (update.totalSpentDelta !== undefined) statsUpdate.totalSpent = FieldValue.increment(update.totalSpentDelta);
      if (update.totalOrdersDelta !== undefined) statsUpdate.totalOrders = FieldValue.increment(update.totalOrdersDelta);
      if (update.rewardReversalDebtDelta !== undefined) {
        statsUpdate.rewardReversalDebt = FieldValue.increment(update.rewardReversalDebtDelta);
      }
      if (update.tier !== undefined) statsUpdate.tier = update.tier;
      if (Object.keys(statsUpdate).length > 0) {
        transaction.update(db.collection('users').doc(uid), statsUpdate as FirebaseFirestore.UpdateData<unknown>);
      }
    },
    getShippingConfig: async () => {
      const canonical = await transaction.get(db.collection('system_settings').doc('shipping_config'));
      if (canonical.exists) return canonical.data();
      const legacy = await transaction.get(db.collection('settings').doc('shipping'));
      return legacy.exists ? legacy.data() : null;
    },
    getTiersConfig: async () => {
      const snapshot = await transaction.get(db.collection('system_settings').doc('tiers_config'));
      return snapshot.exists ? snapshot.data() : null;
    },
    getVoucher: async (code) => {
      const direct = await transaction.get(db.collection('discountCodes').doc(code));
      if (direct.exists) return { id: direct.id, ...direct.data() };
      const querySnapshot = await transaction.get(
        db.collection('discountCodes').where('code', '==', code).limit(1),
      );
      return querySnapshot.empty
        ? null
        : { id: querySnapshot.docs[0].id, ...querySnapshot.docs[0].data() };
    },
    incrementVoucherUsage: async (id) => {
      transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(1) });
    },
    decrementVoucherUsage: async (id) => {
      transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(-1) });
    },
    saveEvent: async (orderId, event) => {
      transaction.set(orderRef(orderId).collection('events').doc(event.id), serializeOrderEvent(event));
    },
    getIdempotencyRecord: async (id) => {
      const snapshot = await transaction.get(db.collection('idempotency').doc(id));
      return snapshot.exists
        ? normalizeTimestamps(snapshot.data() || {}) as unknown as IdempotencyRecord
        : null;
    },
    saveIdempotencyRecord: async (record) => {
      transaction.set(db.collection('idempotency').doc(record.id), serializeIdempotencyRecord(record) as FirebaseFirestore.DocumentData);
    },
  };
}
