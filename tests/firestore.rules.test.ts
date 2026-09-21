import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-tqs';
const RULES_PATH = new URL('../firestore.rules', import.meta.url);

type TestCase = {
  name: string;
  run: () => Promise<void>;
};

const now = Timestamp.fromMillis(Date.parse('2026-09-21T10:00:00.000Z'));

function baseUser(uid: string, role: 'customer' | 'admin' = 'customer') {
  const user = {
    uid,
    email: `${uid}@example.com`,
    displayName: uid,
    photoURL: null,
    role,
    isBanned: false,
    tier: 'bronze',
    points: 100,
    totalOrders: 0,
    totalSpent: 0,
    rewardReversalDebt: 0,
    createdAt: now,
    lastLoginAt: now,
  };

  return role === 'admin'
    ? {
        ...user,
        adminPermissions: {
          manageProducts: true,
          manageOrders: true,
          manageHomepage: true,
          manageDiscounts: true,
          manageSettings: true,
          manageRoles: true,
          manageRewards: true,
          managePosts: true,
        },
      }
    : user;
}

function baseOrder(orderUserId: string, status: 'pending' | 'processing' = 'pending') {
  return {
    schemaVersion: 1,
    revision: 1,
    userId: orderUserId,
    items: [
      {
        productId: 'product-active',
        name: 'Board game',
        unitPrice: 100000,
        quantity: 1,
        lineTotal: 100000,
        image: 'https://cdn.example.test/game.webp',
      },
    ],
    shippingInfo: {
      fullName: 'Test Customer',
      phone: '0900000000',
      address: '1 Test Street',
      notes: '',
    },
    status,
    paymentStatus: 'pending',
    paymentMethod: 'cod',
    currency: 'VND',
    totalAmount: 100000,
    shippingFee: 30000,
    voucherDiscountAmount: 0,
    pointsApplied: 0,
    pointsDiscountAmount: 0,
    discountAmount: 0,
    finalAmount: 130000,
    rewardEligibleAmount: 100000,
    paidAmount: 0,
    refundAmount: 0,
    stockReservedAt: now,
    stockRestoredAt: null,
    createdAt: now,
    updatedAt: now,
  };
}

function baseEvent(orderId: string) {
  return {
    schemaVersion: 1,
    sequence: 1,
    eventType: 'order_created',
    actionType: 'create_order',
    orderId,
    actorType: 'system',
    actorId: 'order-service',
    sideEffectsExecuted: ['stock_reserve'],
    createdAt: now,
  };
}

function baseIdempotencyRecord() {
  return {
    schemaVersion: 1,
    scope: 'order',
    actorType: 'customer',
    actorUid: 'alice',
    requestKeyHash: 'sha256:request-key',
    requestFingerprint: 'sha256:request-payload',
    operation: 'create_order',
    status: 'succeeded',
    orderId: 'order-alice',
    resultRef: 'orders/order-alice',
    resultCode: 'ORDER_CREATED',
    createdAt: now,
    updatedAt: now,
    expiresAt: Timestamp.fromMillis(Date.parse('2026-12-20T10:00:00.000Z')),
    lockExpiresAt: null,
  };
}

async function seedDatabase(testEnv: RulesTestEnvironment) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = writeBatch(db);

    batch.set(doc(db, 'users/alice'), baseUser('alice'));
    batch.set(doc(db, 'users/bob'), baseUser('bob'));
    batch.set(doc(db, 'users/admin'), baseUser('admin', 'admin'));
    batch.set(doc(db, 'users/banned'), { ...baseUser('banned'), isBanned: true });

    batch.set(doc(db, 'products/product-active'), {
      name: 'Active product',
      price: 100000,
      image: 'https://cdn.example.test/active.webp',
      type: 'base',
      isActive: true,
      stock: 5,
      createdAt: now,
    });
    batch.set(doc(db, 'products/product-inactive'), {
      name: 'Inactive product',
      price: 100000,
      image: 'https://cdn.example.test/inactive.webp',
      type: 'base',
      isActive: false,
      stock: 5,
      createdAt: now,
    });

    batch.set(doc(db, 'orders/order-alice'), baseOrder('alice'));
    batch.set(doc(db, 'orders/order-bob'), baseOrder('bob'));

    batch.set(doc(db, 'discountCodes/public-active'), {
      code: 'PUBLIC10',
      discountType: 'percentage',
      discountValue: 10,
      startDate: now,
      endDate: Timestamp.fromMillis(Date.parse('2026-12-31T23:59:59.000Z')),
      usedCount: 0,
      isActive: true,
      isPubliclyVisible: true,
      createdAt: now,
    });
    batch.set(doc(db, 'discountCodes/private-inactive'), {
      code: 'OLD10',
      discountType: 'percentage',
      discountValue: 10,
      startDate: now,
      endDate: now,
      usedCount: 0,
      isActive: false,
      isPubliclyVisible: false,
      createdAt: now,
    });

    batch.set(doc(db, 'posts/published-post'), {
      slug: 'published-post',
      title: 'Published post',
      status: 'published',
      createdAt: now,
    });
    batch.set(doc(db, 'posts/draft-post'), {
      slug: 'draft-post',
      title: 'Draft post',
      status: 'draft',
      createdAt: now,
    });

    batch.set(doc(db, 'notifications/alice-notification'), {
      userId: 'alice',
      title: 'Order update',
      message: 'Your order changed',
      type: 'order',
      isRead: false,
      createdAt: now,
    });
    batch.set(doc(db, 'notifications/bob-notification'), {
      userId: 'bob',
      title: 'Order update',
      message: 'Bob notification',
      type: 'order',
      isRead: false,
      createdAt: now,
    });

    batch.set(doc(db, 'settings/siteConfig'), { siteTitle: 'TQS', siteFavicon: '/favicon.ico' });
    batch.set(doc(db, 'settings/adminSecrets'), { telegramBotToken: 'redacted-test-value' });
    batch.set(doc(db, 'system/version'), { productsUpdated: 1 });
    batch.set(doc(db, 'system_settings/tiers_config'), { isActive: true, pointValueVND: 1000 });

    await batch.commit();
  });
}

async function runCase(testCase: TestCase) {
  await testCase.run();
  console.log(`  ✅ PASS: ${testCase.name}`);
}

async function main() {
  const rules = await readFile(RULES_PATH, 'utf8');
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  const guest = testEnv.unauthenticatedContext().firestore();
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' }).firestore();
  const bob = testEnv.authenticatedContext('bob', { email: 'bob@example.com' }).firestore();
  const admin = testEnv.authenticatedContext('admin', { email: 'admin@example.com' }).firestore();
  const banned = testEnv.authenticatedContext('banned', { email: 'banned@example.com' }).firestore();
  const newUser = testEnv.authenticatedContext('new-user', { email: 'new-user@example.com' }).firestore();
  const incompleteUser = testEnv.authenticatedContext('incomplete-user', { email: 'incomplete-user@example.com' }).firestore();
  const service = testEnv.authenticatedContext('order-service', {
    order_service: true,
  }).firestore();

  try {
    await testEnv.clearFirestore();
    await seedDatabase(testEnv);

    console.log('🔐 Running Firestore security rules tests...');

    const cases: TestCase[] = [
      {
        name: 'guest can list active products but cannot read inactive products',
        run: async () => {
          await assertSucceeds(getDocs(query(collection(guest, 'products'), where('isActive', '==', true))));
          await assertSucceeds(getDoc(doc(guest, 'products/product-active')));
          await assertFails(getDoc(doc(guest, 'products/product-inactive')));
        },
      },
      {
        name: 'guest cannot write products, orders or users',
        run: async () => {
          await assertFails(updateDoc(doc(guest, 'products/product-active'), { stock: 4 }));
          await assertFails(setDoc(doc(guest, 'orders/guest-order'), baseOrder('alice')));
          await assertFails(setDoc(doc(guest, 'users/guest'), baseUser('guest')));
        },
      },
      {
        name: 'new customer bootstrap requires the canonical role field',
        run: async () => {
          await assertSucceeds(setDoc(doc(newUser, 'users/new-user'), baseUser('new-user')));
          const { role: _role, ...withoutRole } = baseUser('incomplete-user');
          await assertFails(setDoc(doc(incompleteUser, 'users/incomplete-user'), withoutRole));
        },
      },
      {
        name: 'customer can read and edit only their profile fields',
        run: async () => {
          await assertSucceeds(getDoc(doc(alice, 'users/alice')));
          await assertSucceeds(updateDoc(doc(alice, 'users/alice'), { displayName: 'Alice Updated' }));
          await assertFails(getDoc(doc(alice, 'users/bob')));
          await assertFails(updateDoc(doc(alice, 'users/alice'), { points: 999999 }));
          await assertFails(updateDoc(doc(alice, 'users/alice'), { role: 'admin' }));
        },
      },
      {
        name: 'banned customer is denied even for their own profile and order',
        run: async () => {
          await assertFails(getDoc(doc(banned, 'users/banned')));
          await assertFails(getDoc(doc(banned, 'orders/order-alice')));
        },
      },
      {
        name: 'customer reads only their own order, including owner query',
        run: async () => {
          await assertSucceeds(getDoc(doc(alice, 'orders/order-alice')));
          await assertFails(getDoc(doc(alice, 'orders/order-bob')));
          const ownOrders = await assertSucceeds(
            getDocs(query(collection(alice, 'orders'), where('userId', '==', 'alice')))
          );
          assert.equal(ownOrders.size, 1);
        },
      },
      {
        name: 'customer cannot create or directly transition an order',
        run: async () => {
          await assertFails(setDoc(doc(alice, 'orders/customer-created'), baseOrder('alice')));
          await assertFails(updateDoc(doc(alice, 'orders/order-alice'), {
            status: 'cancelled',
            revision: 2,
          }));
          await assertFails(updateDoc(doc(alice, 'orders/order-alice'), {
            paymentStatus: 'paid',
            revision: 2,
          }));
        },
      },
      {
        name: 'admin can read orders but cannot bypass the order service for mutation',
        run: async () => {
          await assertSucceeds(getDoc(doc(admin, 'orders/order-alice')));
          await assertFails(updateDoc(doc(admin, 'orders/order-alice'), {
            status: 'cancelled',
            revision: 2,
          }));
        },
      },
      {
        name: 'server-like order service can create and transition a canonical order',
        run: async () => {
          await assertSucceeds(setDoc(doc(service, 'orders/order-service-created'), {
            ...baseOrder('alice'),
            revision: 1,
          }));
          await assertSucceeds(updateDoc(doc(service, 'orders/order-service-created'), {
            status: 'processing',
            revision: 2,
            updatedAt: Timestamp.fromMillis(Date.parse('2026-09-21T10:05:00.000Z')),
          }));
          await assertFails(updateDoc(doc(service, 'orders/order-service-created'), {
            status: 'shipped',
            revision: 4,
          }));
        },
      },
      {
        name: 'server-like service can append events and idempotency records; clients cannot',
        run: async () => {
          await assertSucceeds(setDoc(doc(service, 'orders/order-alice/events/event-1'), baseEvent('order-alice')));
          await assertSucceeds(setDoc(doc(service, 'idempotency/record-1'), baseIdempotencyRecord()));
          await assertSucceeds(getDoc(doc(service, 'idempotency/record-1')));
          await assertFails(getDoc(doc(alice, 'orders/order-alice/events/event-1')));
          await assertFails(getDoc(doc(alice, 'idempotency/record-1')));
          await assertFails(deleteDoc(doc(service, 'idempotency/record-1')));
        },
      },
      {
        name: 'admin permission controls product, role and settings mutations',
        run: async () => {
          await assertSucceeds(updateDoc(doc(admin, 'products/product-active'), { price: 110000 }));
          await assertSucceeds(updateDoc(doc(admin, 'users/bob'), { isBanned: true }));
          await assertSucceeds(updateDoc(doc(admin, 'settings/siteConfig'), { siteTitle: 'TQS Updated' }));
          await assertFails(updateDoc(doc(alice, 'products/product-active'), { price: 1 }));
          await assertFails(updateDoc(doc(alice, 'users/bob'), { isBanned: false }));
          await assertFails(updateDoc(doc(guest, 'settings/siteConfig'), { siteTitle: 'Guest write' }));
        },
      },
      {
        name: 'order service may adjust stock but not arbitrary product fields',
        run: async () => {
          await assertSucceeds(updateDoc(doc(service, 'products/product-active'), { stock: 4 }));
          await assertFails(updateDoc(doc(service, 'products/product-active'), { price: 1 }));
        },
      },
      {
        name: 'public content is readable only when published; public view increments are denied',
        run: async () => {
          await assertSucceeds(getDoc(doc(guest, 'posts/published-post')));
          await assertFails(getDoc(doc(guest, 'posts/draft-post')));
          await assertFails(updateDoc(doc(guest, 'posts/published-post'), { viewCount: 1 }));
          await assertSucceeds(updateDoc(doc(admin, 'posts/draft-post'), { status: 'published' }));
        },
      },
      {
        name: 'notifications are owner-readable and owner may only mark isRead',
        run: async () => {
          await assertSucceeds(getDocs(query(collection(alice, 'notifications'), where('userId', '==', 'alice'))));
          await assertSucceeds(updateDoc(doc(alice, 'notifications/alice-notification'), { isRead: true }));
          await assertFails(getDoc(doc(alice, 'notifications/bob-notification')));
          await assertFails(updateDoc(doc(alice, 'notifications/alice-notification'), { message: 'tampered' }));
        },
      },
      {
        name: 'public settings and active public discounts are readable without write access',
        run: async () => {
          await assertSucceeds(getDoc(doc(guest, 'settings/siteConfig')));
          await assertFails(getDoc(doc(guest, 'settings/adminSecrets')));
          await assertSucceeds(getDoc(doc(guest, 'discountCodes/public-active')));
          await assertFails(getDoc(doc(guest, 'discountCodes/private-inactive')));
          await assertFails(updateDoc(doc(alice, 'discountCodes/public-active'), { usedCount: 1 }));
          await assertSucceeds(updateDoc(doc(service, 'discountCodes/public-active'), { usedCount: 1 }));
        },
      },
      {
        name: 'system version is public but unlisted diagnostic collections are closed',
        run: async () => {
          await assertSucceeds(getDoc(doc(guest, 'system/version')));
          await assertFails(updateDoc(doc(guest, 'system/version'), { productsUpdated: 2 }));
          await assertFails(getDoc(doc(guest, 'test/connection')));
        },
      },
    ];

    for (const testCase of cases) {
      await runCase(testCase);
    }

    console.log(`\nRules test summary: ${cases.length} scenarios passed, 0 failed.`);
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error('\n❌ Firestore rules test suite failed');
  console.error(error);
  process.exitCode = 1;
});
