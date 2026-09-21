/**
 * Firestore REST Client using Native Fetch and Firebase ID Token Bearer Auth
 * Compliant with Cloudflare Workers runtime
 * Reference: https://firebase.google.com/docs/firestore/use-rest-api
 */

import { UserProfile } from './types';

export interface FirestoreRestConfig {
  projectId: string;
  databaseId?: string;
}

export interface FirestoreField {
  stringValue?: string;
  booleanValue?: boolean;
  integerValue?: string;
  doubleValue?: number;
  timestampValue?: string;
  nullValue?: null;
  mapValue?: {
    fields?: Record<string, FirestoreField>;
  };
  arrayValue?: {
    values?: FirestoreField[];
  };
}

export interface FirestoreDocument {
  name: string;
  fields?: Record<string, FirestoreField>;
  createTime?: string;
  updateTime?: string;
}

/**
 * Decode Firestore REST Document Fields into plain JavaScript object
 */
export function decodeFirestoreFields(fields?: Record<string, FirestoreField>): Record<string, unknown> {
  if (!fields) return {};
  const result: Record<string, unknown> = {};

  for (const [key, field] of Object.entries(fields)) {
    result[key] = decodeFirestoreValue(field);
  }

  return result;
}

function decodeFirestoreValue(field: FirestoreField): unknown {
  if ('stringValue' in field) return field.stringValue;
  if ('booleanValue' in field) return field.booleanValue;
  if ('integerValue' in field) return parseInt(field.integerValue || '0', 10);
  if ('doubleValue' in field) return field.doubleValue;
  if ('timestampValue' in field) return field.timestampValue;
  if ('nullValue' in field) return null;
  if ('mapValue' in field) return decodeFirestoreFields(field.mapValue?.fields);
  if ('arrayValue' in field) {
    return (field.arrayValue?.values || []).map(decodeFirestoreValue);
  }
  return undefined;
}

export class FirestoreRestClient {
  public subrequestCount: number = 0;
  private readonly baseUrl: string;

  constructor(private readonly config: FirestoreRestConfig) {
    const databaseId = config.databaseId || '(default)';
    this.baseUrl = `https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/${databaseId}/documents`;
  }

  /**
   * Read user document from `users/{uid}` using client's Firebase ID token
   * Firestore enforces Security Rules because Authorization header is a Firebase ID token.
   */
  public async getUserProfile(uid: string, idToken: string): Promise<UserProfile | null> {
    const url = `${this.baseUrl}/users/${encodeURIComponent(uid)}`;
    this.subrequestCount++;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${idToken}`,
        Accept: 'application/json',
      },
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Firestore REST GET user failed (HTTP ${response.status}): ${errorText}`);
    }

    const doc = (await response.json()) as FirestoreDocument;
    const data = decodeFirestoreFields(doc.fields);

    return {
      uid,
      email: (data.email as string) || '',
      displayName: (data.displayName as string) || undefined,
      photoURL: (data.photoURL as string) || undefined,
      role: (data.role as 'admin' | 'customer') || 'customer',
      adminPermissions: (data.adminPermissions as UserProfile['adminPermissions']) || null,
      isBanned: Boolean(data.isBanned),
      tier: (data.tier as string) || 'bronze',
      points: typeof data.points === 'number' ? data.points : 0,
      totalOrders: typeof data.totalOrders === 'number' ? data.totalOrders : 0,
      totalSpent: typeof data.totalSpent === 'number' ? data.totalSpent : 0,
      createdAt: (data.createdAt as string) || doc.createTime,
      lastLoginAt: (data.lastLoginAt as string) || doc.updateTime,
    };
  }
}
