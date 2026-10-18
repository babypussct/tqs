import { initializeApp } from 'firebase/app';
import {
  browserLocalPersistence,
  getAuth,
  GoogleAuthProvider,
  onAuthStateChanged,
  setPersistence,
  signInWithPopup,
  signOut,
  type User,
} from 'firebase/auth';
import firebaseConfig from '../../../firebase-applet-config.json';

const config = {
  ...firebaseConfig,
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || firebaseConfig.apiKey,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || firebaseConfig.authDomain,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || firebaseConfig.projectId,
  appId: import.meta.env.VITE_FIREBASE_APP_ID || firebaseConfig.appId,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || firebaseConfig.storageBucket,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || firebaseConfig.messagingSenderId,
};

const app = initializeApp(config, 'tqs-game');
export const gameAuth = getAuth(app);
const googleProvider = new GoogleAuthProvider();
const sessionUrl = import.meta.env.VITE_GAME_SESSION_URL || '/api/game/session';
let persistenceReady: Promise<void> | null = null;

export interface GamePoolPolicyPayload {
  schemaVersion: 1;
  mode: 'new_heg_mode';
  revision: number;
  disabledPacks: { generals: string[]; cards: string[] };
  appliesTo: 'new_rooms';
}

export interface GameSession {
  uid: string;
  displayName: string;
  nativeName: string;
  ticket: string;
  expiresAt: number;
  poolPolicy: GamePoolPolicyPayload;
}

export class GameAccessError extends Error {
  constructor(public readonly code: string, message: string) {
    super(message);
    this.name = 'GameAccessError';
  }
}

async function ensurePersistence(): Promise<void> {
  persistenceReady ??= setPersistence(gameAuth, browserLocalPersistence);
  await persistenceReady;
}

async function requestGameSession(user: User): Promise<GameSession> {
  const idToken = await user.getIdToken();
  const response = await fetch(sessionUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken}`, Accept: 'application/json' },
    cache: 'no-store',
  });
  const payload = await response.json().catch(() => ({})) as Record<string, unknown>;
  if (!response.ok || payload.success !== true) {
    throw new GameAccessError(
      typeof payload.code === 'string' ? payload.code : 'GAME_AUTH_FAILED',
      typeof payload.message === 'string' ? payload.message : 'Không thể tạo phiên game.',
    );
  }

  const policy = payload.poolPolicy as Partial<GamePoolPolicyPayload> | undefined;
  const disabledPacks = policy?.disabledPacks as Partial<GamePoolPolicyPayload['disabledPacks']> | undefined;
  if (typeof payload.uid !== 'string' || typeof payload.nativeName !== 'string' || typeof payload.ticket !== 'string' ||
      !Number.isInteger(payload.expiresAt) || !policy || policy.mode !== 'new_heg_mode' ||
      !disabledPacks || !Array.isArray(disabledPacks.generals) || !Array.isArray(disabledPacks.cards)) {
    throw new GameAccessError('GAME_AUTH_INVALID_RESPONSE', 'Máy chủ trả về phiên game không hợp lệ.');
  }
  return {
    uid: payload.uid,
    displayName: typeof payload.displayName === 'string' ? payload.displayName : user.displayName || payload.nativeName,
    nativeName: payload.nativeName,
    ticket: payload.ticket,
    expiresAt: Number(payload.expiresAt),
    poolPolicy: {
      schemaVersion: 1,
      mode: 'new_heg_mode',
      revision: Number.isInteger(policy.revision) ? Number(policy.revision) : 0,
      disabledPacks: {
        generals: disabledPacks.generals.filter((id): id is string => typeof id === 'string'),
        cards: disabledPacks.cards.filter((id): id is string => typeof id === 'string'),
      },
      appliesTo: 'new_rooms',
    },
  };
}

export async function signInAndCreateGameSession(): Promise<GameSession> {
  await ensurePersistence();
  const result = await signInWithPopup(gameAuth, googleProvider);
  return requestGameSession(result.user);
}

export async function createGameSessionForCurrentUser(): Promise<GameSession> {
  await ensurePersistence();
  if (!gameAuth.currentUser) throw new GameAccessError('LOGIN_REQUIRED', 'Hãy đăng nhập Google để vào game.');
  return requestGameSession(gameAuth.currentUser);
}

export function watchGameUser(callback: (user: User | null) => void): () => void {
  return onAuthStateChanged(gameAuth, callback);
}

export async function logoutGame(): Promise<void> {
  await signOut(gameAuth);
}
