import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { initializeFirestore, persistentLocalCache, persistentMultipleTabManager } from 'firebase/firestore';
import firebaseConfig from '../firebase-applet-config.json';
import { shouldUseShopAuthProxy } from './utils/googleAuthFlow';

type FirebaseWebConfig = typeof firebaseConfig;

// Keep the checked-in production config as the safe default, while allowing
// Preview/staging deployments to inject an isolated Firebase project through
// Vite environment variables. Firebase web config values are public by
// design; server credentials are never read by this module.
const baseConfig = firebaseConfig as FirebaseWebConfig;
// Safari limits cross-site storage needed by Firebase's redirect helper.
// The Vercel /__/auth/* proxy lets the helper run on the shop's own origin.
// Switch only after Google's OAuth client has this callback allowlisted.
const shopUsesSameOriginAuth = typeof window !== 'undefined' &&
  shouldUseShopAuthProxy({
    hostname: window.location.hostname,
    enabled: import.meta.env.VITE_TQS_SHOP_SAME_ORIGIN_GOOGLE_AUTH === 'true',
    authDomainOverridden: Boolean(import.meta.env.VITE_FIREBASE_AUTH_DOMAIN),
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || baseConfig.projectId,
    expectedProjectId: baseConfig.projectId,
  });
const runtimeConfig: FirebaseWebConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || baseConfig.apiKey,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ||
    (shopUsesSameOriginAuth ? window.location.hostname : baseConfig.authDomain),
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || baseConfig.projectId,
  appId: import.meta.env.VITE_FIREBASE_APP_ID || baseConfig.appId,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || baseConfig.storageBucket,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || baseConfig.messagingSenderId,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || baseConfig.measurementId,
  firestoreDatabaseId: import.meta.env.VITE_FIREBASE_DATABASE_ID || baseConfig.firestoreDatabaseId,
};

// Initialize Firebase SDK
const app = initializeApp(runtimeConfig);

// Initialize Firestore with local cache for offline capabilities and read reduction
export const db = initializeFirestore(
  app, 
  {
    localCache: persistentLocalCache({
      tabManager: persistentMultipleTabManager()
    })
  },
  runtimeConfig.firestoreDatabaseId
);

// Initialize Auth
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
