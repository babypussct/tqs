import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';

let initialized = false;
const DEFAULT_FIREBASE_PROJECT_ID = 'gen-lang-client-0845413094';

type ServiceAccountEnv = {
  project_id?: unknown;
  projectId?: unknown;
  client_email?: unknown;
  clientEmail?: unknown;
  private_key?: unknown;
  privateKey?: unknown;
};

function firebaseProjectId(): string {
  return process.env.FIREBASE_PROJECT_ID?.trim()
    || process.env.GCLOUD_PROJECT?.trim()
    || DEFAULT_FIREBASE_PROJECT_ID;
}

function serviceAccountFromJson(raw: string, projectId: string): {
  projectId: string;
  clientEmail?: string;
  privateKey?: string;
} {
  const parsed = JSON.parse(raw) as ServiceAccountEnv;
  const credentialProjectId = typeof parsed.project_id === 'string'
    ? parsed.project_id
    : typeof parsed.projectId === 'string'
    ? parsed.projectId
    : undefined;

  // Firebase Admin derives the ID-token audience from the service-account
  // project when a cert is supplied. Fail closed if Vercel has a stale key
  // from another Firebase project instead of returning a misleading 401 for
  // every otherwise-valid browser token.
  if (credentialProjectId && credentialProjectId !== projectId) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON belongs to a different Firebase project.');
  }

  return {
    projectId,
    clientEmail: typeof parsed.client_email === 'string'
      ? parsed.client_email
      : typeof parsed.clientEmail === 'string'
      ? parsed.clientEmail
      : undefined,
    privateKey: typeof parsed.private_key === 'string'
      ? parsed.private_key
      : typeof parsed.privateKey === 'string'
      ? parsed.privateKey
      : undefined,
  };
}

function initializeFirebaseAdmin(): void {
  if (initialized || admin.apps.length > 0) {
    initialized = true;
    return;
  }

  try {
    const projectId = firebaseProjectId();
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = serviceAccountFromJson(process.env.FIREBASE_SERVICE_ACCOUNT_JSON, projectId);
      admin.initializeApp({ projectId, credential: admin.credential.cert(serviceAccount) });
    } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      let privateKey = process.env.FIREBASE_PRIVATE_KEY;
      if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
      }
      admin.initializeApp({
        projectId,
        credential: admin.credential.cert({
          projectId,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      admin.initializeApp({
        projectId,
      });
    }
  } catch (error) {
    console.error('Firebase Admin Initialization Error:', error);
    throw error;
  }

  initialized = true;
}

export function getAdminApp(): admin.app.App {
  initializeFirebaseAdmin();
  return admin.app();
}

export function getAdminDb(): FirebaseFirestore.Firestore {
  const app = getAdminApp();
  const databaseId = process.env.FIREBASE_DATABASE_ID;
  try {
    return databaseId ? getFirestore(app, databaseId) : getFirestore(app);
  } catch {
    return getFirestore(app);
  }
}

export { admin };
