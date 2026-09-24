import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';

let initialized = false;

function initializeFirebaseAdmin(): void {
  if (initialized || admin.apps.length > 0) {
    initialized = true;
    return;
  }

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      let privateKey = process.env.FIREBASE_PRIVATE_KEY;
      if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
      }
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'gen-lang-client-0845413094',
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'gen-lang-client-0845413094',
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
