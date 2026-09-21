/**
 * Types for Firebase Auth & Firestore REST Worker Authorization Spike
 */

export interface FirebaseIdTokenHeader {
  alg: string;
  kid: string;
  typ: string;
}

export interface FirebaseIdTokenPayload {
  name?: string;
  picture?: string;
  iss: string;
  aud: string;
  auth_time: number;
  user_id: string;
  sub: string;
  iat: number;
  exp: number;
  email?: string;
  email_verified?: boolean;
  firebase: {
    identities: Record<string, string[]>;
    sign_in_provider: string;
    [key: string]: unknown;
  };
  role?: string;
  [key: string]: unknown;
}

export interface AdminPermissions {
  manageProducts?: boolean;
  manageOrders?: boolean;
  manageHomepage?: boolean;
  manageDiscounts?: boolean;
  manageSettings?: boolean;
  manageRoles?: boolean;
}

export interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  role: 'admin' | 'customer';
  adminPermissions?: AdminPermissions | null;
  isBanned: boolean;
  tier?: string;
  points?: number;
  totalOrders?: number;
  totalSpent?: number;
  createdAt?: string;
  lastLoginAt?: string;
}

export interface AuthContext {
  uid: string;
  email: string;
  emailVerified: boolean;
  role: 'admin' | 'customer';
  isBanned: boolean;
  isSuperAdmin: boolean;
  permissions: AdminPermissions;
}

export type RequiredPermission = keyof AdminPermissions;

export interface WorkerEnv {
  FIREBASE_PROJECT_ID: string;
  FIREBASE_DATABASE_ID: string;
  SUPER_ADMIN_EMAILS?: string[];
}

export interface ExecutionMetrics {
  subrequests: number;
  cpuTimeMs: number;
  wallLatencyMs: number;
}
