/**
 * Cloudflare Worker Handler Prototype
 * Demonstrates:
 * 1. Bearer Token extraction & verification via Web Crypto
 * 2. Firestore REST call using client's Bearer token
 * 3. Authoritative role & permission enforcement
 * 4. Sample customer action and admin action
 * 5. Measurement of CPU time, subrequests, and wall-clock latency
 */

import { buildAuthContext, enforceAdminAction, enforceCustomerAction } from './authorization';
import { FirestoreRestClient } from './firestoreRestClient';
import { jwksCache } from './jwks';
import { ExecutionMetrics, WorkerEnv } from './types';
import { verifyFirebaseIdToken } from './verifyFirebaseToken';

export interface WorkerResponseData {
  success: boolean;
  action: string;
  data?: unknown;
  error?: string;
  code?: string;
  metrics: ExecutionMetrics;
}

export async function handleWorkerRequest(
  request: Request,
  env: WorkerEnv,
  mockFirestoreClient?: FirestoreRestClient
): Promise<Response> {
  const wallStart = performance.now();
  // Using process.cpuUsage if available (Node/Miniflare benchmark environment)
  const cpuStart = typeof process !== 'undefined' && process.cpuUsage ? process.cpuUsage() : null;

  let subrequests = 0;

  try {
    const url = new URL(request.url);
    const authHeader = request.headers.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing or invalid Authorization header. Expected Bearer token.',
          code: 'UNAUTHORIZED',
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const idToken = authHeader.substring(7).trim();

    // 1. Verify Token with Web Crypto (tracks subrequests if JWKS cache miss)
    const initialSubrequests = jwksCache.subrequestCount;
    const tokenPayload = await verifyFirebaseIdToken(idToken, {
      projectId: env.FIREBASE_PROJECT_ID,
    });
    const jwksSubrequests = jwksCache.subrequestCount - initialSubrequests;
    subrequests += jwksSubrequests;

    // 2. Fetch User Profile from Firestore REST using client ID token
    const firestore =
      mockFirestoreClient ||
      new FirestoreRestClient({
        projectId: env.FIREBASE_PROJECT_ID,
        databaseId: env.FIREBASE_DATABASE_ID,
      });

    const initialFirestoreSubrequests = firestore.subrequestCount;
    const userProfile = await firestore.getUserProfile(tokenPayload.sub, idToken);
    const firestoreSubrequests = firestore.subrequestCount - initialFirestoreSubrequests;
    subrequests += firestoreSubrequests;

    // 3. Build authoritative AuthContext
    const authContext = buildAuthContext(
      tokenPayload.sub,
      tokenPayload.email || '',
      Boolean(tokenPayload.email_verified),
      userProfile,
      env
    );

    // 4. Route & Enforce Authorization
    let action = 'unknown';
    let resultData: unknown = null;

    if (request.method === 'GET' && url.pathname === '/api/me') {
      action = 'customer.getProfile';
      enforceCustomerAction(authContext);
      resultData = {
        uid: authContext.uid,
        email: authContext.email,
        role: authContext.role,
        isSuperAdmin: authContext.isSuperAdmin,
        permissions: authContext.permissions,
      };
    } else if (request.method === 'POST' && url.pathname === '/api/orders') {
      action = 'customer.createOrder';
      enforceCustomerAction(authContext);
      resultData = {
        orderId: `ord_sim_${Date.now()}`,
        status: 'pending',
        creatorUid: authContext.uid,
      };
    } else if (request.method === 'POST' && url.pathname === '/api/admin/products') {
      action = 'admin.manageProducts';
      enforceAdminAction(authContext, 'manageProducts');
      resultData = {
        productId: `prod_sim_${Date.now()}`,
        status: 'created',
      };
    } else if (request.method === 'POST' && url.pathname.startsWith('/api/admin/orders/')) {
      action = 'admin.manageOrders';
      enforceAdminAction(authContext, 'manageOrders');
      resultData = {
        orderId: url.pathname.split('/')[4],
        transition: 'applied',
      };
    } else {
      return new Response(JSON.stringify({ success: false, error: 'Not Found', code: 'NOT_FOUND' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const wallEnd = performance.now();
    let cpuTimeMs = 0;
    if (cpuStart && process.cpuUsage) {
      const cpuDiff = process.cpuUsage(cpuStart);
      cpuTimeMs = (cpuDiff.user + cpuDiff.system) / 1000;
    } else {
      cpuTimeMs = wallEnd - wallStart; // fallback approximation
    }

    const metrics: ExecutionMetrics = {
      subrequests,
      cpuTimeMs: Number(cpuTimeMs.toFixed(3)),
      wallLatencyMs: Number((wallEnd - wallStart).toFixed(3)),
    };

    const responseBody: WorkerResponseData = {
      success: true,
      action,
      data: resultData,
      metrics,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'X-CPU-Time-Ms': metrics.cpuTimeMs.toString(),
        'X-Subrequests-Count': metrics.subrequests.toString(),
        'X-Latency-Ms': metrics.wallLatencyMs.toString(),
      },
    });
  } catch (err: unknown) {
    const wallEnd = performance.now();
    let cpuTimeMs = 0;
    if (cpuStart && process.cpuUsage) {
      const cpuDiff = process.cpuUsage(cpuStart);
      cpuTimeMs = (cpuDiff.user + cpuDiff.system) / 1000;
    } else {
      cpuTimeMs = wallEnd - wallStart;
    }

    const errorObj = err as { message?: string; status?: number; code?: string };
    const status = errorObj.status || 400;
    const code = errorObj.code || 'ERROR';

    return new Response(
      JSON.stringify({
        success: false,
        error: errorObj.message || 'Unknown error occurred',
        code,
        metrics: {
          subrequests,
          cpuTimeMs: Number(cpuTimeMs.toFixed(3)),
          wallLatencyMs: Number((wallEnd - wallStart).toFixed(3)),
        },
      }),
      {
        status,
        headers: {
          'Content-Type': 'application/json',
          'X-CPU-Time-Ms': cpuTimeMs.toFixed(3),
          'X-Subrequests-Count': subrequests.toString(),
        },
      }
    );
  }
}
