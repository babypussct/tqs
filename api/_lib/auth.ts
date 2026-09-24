import type { VercelRequest } from '@vercel/node';
import type { Firestore } from 'firebase-admin/firestore';
import { admin } from './firebaseAdmin.js';
import type { AuthenticatedActor } from '../../src/order/orderService.js';

export function getBearerToken(req: VercelRequest): string | null {
  const authorization = req.headers.authorization;
  if (!authorization) return null;
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}

export async function authenticateActor(
  req: VercelRequest,
  db: Firestore,
): Promise<{ actor: AuthenticatedActor } | { errorCode: string; status: number; message: string }> {
  const idToken = getBearerToken(req);
  if (!idToken) {
    return {
      errorCode: 'UNAUTHORIZED',
      status: 401,
      message: 'Thiếu hoặc sai định dạng Authorization Bearer token.',
    };
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const userSnapshot = await db.collection('users').doc(decoded.uid).get();
    const userData = userSnapshot.data() || {};
    if (userData.isBanned === true) {
      return { errorCode: 'ACCOUNT_BANNED', status: 403, message: 'Tài khoản của bạn đã bị khóa.' };
    }

    return {
      actor: {
        uid: decoded.uid,
        email: decoded.email || '',
        role: userData.role === 'admin' ? 'admin' : 'customer',
        isSuperAdmin: Boolean(decoded.super_admin === true || userData.isSuperAdmin === true),
        permissions: userData.adminPermissions && typeof userData.adminPermissions === 'object'
          ? userData.adminPermissions
          : undefined,
      },
    };
  } catch (error) {
    console.error('ID Token Verification Error:', error instanceof Error ? error.message : error);
    return {
      errorCode: 'INVALID_TOKEN',
      status: 401,
      message: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
    };
  }
}
