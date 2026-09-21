/**
 * Unit & Integration Tests for Worker AuthN & AuthZ Spike
 * Run with: npx tsx spikes/worker-auth/test.ts
 */

import { handleWorkerRequest } from './handler';
import { jwksCache } from './jwks';
import { FirestoreRestClient } from './firestoreRestClient';
import { FirebaseIdTokenPayload, UserProfile, WorkerEnv } from './types';
import { verifyFirebaseIdToken } from './verifyFirebaseToken';

// Helper to encode base64url
function toBase64Url(obj: object | string): string {
  const str = typeof obj === 'string' ? obj : JSON.stringify(obj);
  return Buffer.from(str)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

async function runTests() {
  console.log('🚀 Starting Worker AuthN / AuthZ Spike Tests...\n');
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

  // 1. Generate local RSA test keypair
  const keyPair = await crypto.subtle.generateKey(
    {
      name: 'RSASSA-PKCS1-v1_5',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true,
    ['sign', 'verify']
  );

  const testKid = 'test-worker-key-1';
  jwksCache.registerKey(testKid, keyPair.publicKey);

  const testEnv: WorkerEnv = {
    FIREBASE_PROJECT_ID: 'gen-lang-client-0845413094',
    FIREBASE_DATABASE_ID: 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b',
    SUPER_ADMIN_EMAILS: ['oneloveonepeopleforever@gmail.com'],
  };

  // Helper to create a signed test JWT
  async function createSignedToken(payloadOverrides: Partial<FirebaseIdTokenPayload> = {}): Promise<string> {
    const header = { alg: 'RS256', kid: testKid, typ: 'JWT' };
    const now = Math.floor(Date.now() / 1000);
    const payload: FirebaseIdTokenPayload = {
      iss: `https://securetoken.google.com/${testEnv.FIREBASE_PROJECT_ID}`,
      aud: testEnv.FIREBASE_PROJECT_ID,
      auth_time: now - 10,
      user_id: 'cust_123',
      sub: 'cust_123',
      iat: now - 10,
      exp: now + 3600,
      email: 'customer@test.com',
      email_verified: true,
      firebase: {
        identities: { email: ['customer@test.com'] },
        sign_in_provider: 'google.com',
      },
      ...payloadOverrides,
    };

    const headerB64 = toBase64Url(header);
    const payloadB64 = toBase64Url(payload);
    const dataToSign = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
    const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', keyPair.privateKey, dataToSign);
    const sigB64 = Buffer.from(signature)
      .toString('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    return `${headerB64}.${payloadB64}.${sigB64}`;
  }

  // --- Test Suite 1: Token Verification ---
  console.log('--- Test Suite 1: JWT Verification Logic ---');

  // Test 1.1: Valid token
  try {
    const validToken = await createSignedToken();
    const verified = await verifyFirebaseIdToken(validToken, { projectId: testEnv.FIREBASE_PROJECT_ID });
    assert(verified.sub === 'cust_123', 'Verify valid RS256 Firebase ID token');
  } catch (e: any) {
    assert(false, 'Verify valid RS256 token', e.message);
  }

  // Test 1.2: Expired token
  try {
    const expiredToken = await createSignedToken({ exp: Math.floor(Date.now() / 1000) - 100 });
    await verifyFirebaseIdToken(expiredToken, { projectId: testEnv.FIREBASE_PROJECT_ID, clockSkewSeconds: 0 });
    assert(false, 'Reject expired token', 'Did not throw');
  } catch (e: any) {
    assert(e.code === 'TOKEN_EXPIRED', 'Reject expired token');
  }

  // Test 1.3: Invalid Audience
  try {
    const wrongAudToken = await createSignedToken({ aud: 'wrong-project' });
    await verifyFirebaseIdToken(wrongAudToken, { projectId: testEnv.FIREBASE_PROJECT_ID });
    assert(false, 'Reject wrong audience', 'Did not throw');
  } catch (e: any) {
    assert(e.code === 'INVALID_AUDIENCE', 'Reject wrong audience');
  }

  // Test 1.4: Invalid Issuer
  try {
    const wrongIssToken = await createSignedToken({ iss: 'https://evil.com' });
    await verifyFirebaseIdToken(wrongIssToken, { projectId: testEnv.FIREBASE_PROJECT_ID });
    assert(false, 'Reject wrong issuer', 'Did not throw');
  } catch (e: any) {
    assert(e.code === 'INVALID_ISSUER', 'Reject wrong issuer');
  }

  // Test 1.5: Tampered payload
  try {
    const validToken = await createSignedToken();
    const parts = validToken.split('.');
    const tamperedPayload = toBase64Url({ ...JSON.parse(Buffer.from(parts[1], 'base64').toString()), sub: 'hacked' });
    const tamperedToken = `${parts[0]}.${tamperedPayload}.${parts[2]}`;
    await verifyFirebaseIdToken(tamperedToken, { projectId: testEnv.FIREBASE_PROJECT_ID });
    assert(false, 'Reject tampered payload signature', 'Did not throw');
  } catch (e: any) {
    assert(e.code === 'INVALID_SIGNATURE', 'Reject tampered payload signature');
  }

  // --- Test Suite 2: Worker Handlers & Authorization ---
  console.log('\n--- Test Suite 2: Worker Endpoints & Authorization ---');

  // Mock Firestore Database
  const mockDb = new Map<string, UserProfile>();

  const mockFirestore = {
    subrequestCount: 0,
    async getUserProfile(uid: string, _token: string): Promise<UserProfile | null> {
      this.subrequestCount++;
      return mockDb.get(uid) || null;
    },
  } as unknown as FirestoreRestClient;

  // Setup test users in mock DB
  mockDb.set('cust_123', {
    uid: 'cust_123',
    email: 'customer@test.com',
    role: 'customer',
    isBanned: false,
  });

  mockDb.set('admin_prod', {
    uid: 'admin_prod',
    email: 'admin_prod@test.com',
    role: 'admin',
    adminPermissions: { manageProducts: true, manageOrders: false },
    isBanned: false,
  });

  mockDb.set('banned_user', {
    uid: 'banned_user',
    email: 'bad@test.com',
    role: 'customer',
    isBanned: true,
  });

  // Test 2.1: Customer accessing /api/me (Customer Action)
  const custToken = await createSignedToken({ sub: 'cust_123', email: 'customer@test.com' });
  const res1 = await handleWorkerRequest(
    new Request('https://worker.local/api/me', { headers: { Authorization: `Bearer ${custToken}` } }),
    testEnv,
    mockFirestore
  );
  assert(res1.status === 200, 'Customer can access /api/me');
  const body1 = (await res1.json()) as any;
  assert(body1.data.role === 'customer', 'Customer role correctly returned');

  // Test 2.2: Customer creating order /api/orders (Customer Action)
  const res2 = await handleWorkerRequest(
    new Request('https://worker.local/api/orders', {
      method: 'POST',
      headers: { Authorization: `Bearer ${custToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ items: [{ id: 'p1', qty: 1 }] }),
    }),
    testEnv,
    mockFirestore
  );
  assert(res2.status === 200, 'Customer can create order on /api/orders');

  // Test 2.3: Customer attempting /api/admin/products (Must be 403)
  const res3 = await handleWorkerRequest(
    new Request('https://worker.local/api/admin/products', {
      method: 'POST',
      headers: { Authorization: `Bearer ${custToken}` },
    }),
    testEnv,
    mockFirestore
  );
  assert(res3.status === 403, 'Customer blocked from /api/admin/products (403)');
  const body3 = (await res3.json()) as any;
  assert(body3.code === 'ADMIN_ROLE_REQUIRED', 'Returns ADMIN_ROLE_REQUIRED code');

  // Test 2.4: Admin with manageProducts: true accessing /api/admin/products (200)
  const adminToken = await createSignedToken({ sub: 'admin_prod', email: 'admin_prod@test.com' });
  const res4 = await handleWorkerRequest(
    new Request('https://worker.local/api/admin/products', {
      method: 'POST',
      headers: { Authorization: `Bearer ${adminToken}` },
    }),
    testEnv,
    mockFirestore
  );
  assert(res4.status === 200, 'Admin with manageProducts: true succeeds on /api/admin/products');

  // Test 2.5: Admin without manageOrders attempting /api/admin/orders/123/status (403)
  const res5 = await handleWorkerRequest(
    new Request('https://worker.local/api/admin/orders/123/status', {
      method: 'POST',
      headers: { Authorization: `Bearer ${adminToken}` },
    }),
    testEnv,
    mockFirestore
  );
  assert(res5.status === 403, 'Admin without manageOrders blocked from /api/admin/orders (403)');
  const body5 = (await res5.json()) as any;
  assert(body5.code === 'INSUFFICIENT_PERMISSIONS', 'Returns INSUFFICIENT_PERMISSIONS code');

  // Test 2.6: Super Admin email bypasses all restrictions
  const superAdminToken = await createSignedToken({
    sub: 'super_1',
    email: 'oneloveonepeopleforever@gmail.com',
    email_verified: true,
  });
  const res6 = await handleWorkerRequest(
    new Request('https://worker.local/api/admin/orders/123/status', {
      method: 'POST',
      headers: { Authorization: `Bearer ${superAdminToken}` },
    }),
    testEnv,
    mockFirestore
  );
  assert(res6.status === 200, 'Super admin email has full authorization across endpoints');

  // Test 2.7: Banned user blocked on all endpoints
  const bannedToken = await createSignedToken({ sub: 'banned_user', email: 'bad@test.com' });
  const res7 = await handleWorkerRequest(
    new Request('https://worker.local/api/me', { headers: { Authorization: `Bearer ${bannedToken}` } }),
    testEnv,
    mockFirestore
  );
  assert(res7.status === 403, 'Banned user blocked from /api/me (403)');
  const body7 = (await res7.json()) as any;
  assert(body7.code === 'ACCOUNT_BANNED', 'Returns ACCOUNT_BANNED code');

  console.log(`\n========================================`);
  console.log(`Test Results: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
