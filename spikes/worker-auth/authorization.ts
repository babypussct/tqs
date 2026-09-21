/**
 * Authorization Policy & Enforcement for Worker
 * Resolves effective permissions from Role + adminPermissions
 */

import { AuthContext, RequiredPermission, UserProfile, WorkerEnv } from './types';

export class AuthorizationError extends Error {
  constructor(message: string, public readonly status: number = 403, public readonly code: string = 'FORBIDDEN') {
    super(message);
    this.name = 'AuthorizationError';
  }
}

/**
 * Build authoritative AuthContext from verified token and Firestore user profile
 */
export function buildAuthContext(
  uid: string,
  email: string,
  emailVerified: boolean,
  profile: UserProfile | null,
  env: WorkerEnv
): AuthContext {
  const superAdminEmails = (env.SUPER_ADMIN_EMAILS || ['oneloveonepeopleforever@gmail.com']).map((e) =>
    e.toLowerCase().trim()
  );

  const normalizedEmail = (email || '').toLowerCase().trim();
  const isSuperAdmin = emailVerified && superAdminEmails.includes(normalizedEmail);

  if (profile?.isBanned) {
    return {
      uid,
      email,
      emailVerified,
      role: 'customer',
      isBanned: true,
      isSuperAdmin: false,
      permissions: {},
    };
  }

  if (isSuperAdmin) {
    return {
      uid,
      email,
      emailVerified,
      role: 'admin',
      isBanned: false,
      isSuperAdmin: true,
      permissions: {
        manageProducts: true,
        manageOrders: true,
        manageHomepage: true,
        manageDiscounts: true,
        manageSettings: true,
        manageRoles: true,
      },
    };
  }

  const role = profile?.role === 'admin' ? 'admin' : 'customer';
  const permissions = profile?.adminPermissions || {};

  return {
    uid,
    email,
    emailVerified,
    role,
    isBanned: false,
    isSuperAdmin: false,
    permissions,
  };
}

/**
 * Enforce authorization for a Customer Action
 */
export function enforceCustomerAction(auth: AuthContext, resourceOwnerUid?: string): void {
  if (auth.isBanned) {
    throw new AuthorizationError('Account has been suspended', 403, 'ACCOUNT_BANNED');
  }

  if (resourceOwnerUid && auth.uid !== resourceOwnerUid && !auth.isSuperAdmin && auth.role !== 'admin') {
    throw new AuthorizationError('Cannot access another user\'s resources', 403, 'OWNERSHIP_REQUIRED');
  }
}

/**
 * Enforce authorization for an Admin Action
 */
export function enforceAdminAction(auth: AuthContext, requiredPermission?: RequiredPermission): void {
  if (auth.isBanned) {
    throw new AuthorizationError('Account has been suspended', 403, 'ACCOUNT_BANNED');
  }

  if (auth.isSuperAdmin) {
    return; // Super admin has full bypass
  }

  if (auth.role !== 'admin') {
    throw new AuthorizationError('Admin privileges required for this action', 403, 'ADMIN_ROLE_REQUIRED');
  }

  if (requiredPermission) {
    const hasPermission = Boolean(auth.permissions[requiredPermission]);
    if (!hasPermission) {
      throw new AuthorizationError(
        `Missing required admin permission: '${requiredPermission}'`,
        403,
        'INSUFFICIENT_PERMISSIONS'
      );
    }
  }
}
