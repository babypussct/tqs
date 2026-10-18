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

/** Prepare Firebase storage before the user presses the Google button. */
export async function prepareGameAuth(): Promise<void> {
  await ensurePersistence();
  await gameAuth.authStateReady();
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
  // Do not await storage setup here: iOS Home Screen PWAs can reject a
  // window.open when the click's transient user activation has expired.
  // LoginScreen enables its button only after prepareGameAuth succeeds.
  let result: Awaited<ReturnType<typeof signInWithPopup>>;
  try {
    result = await signInWithPopup(gameAuth, googleProvider);
  } catch (error) {
    const code = (error as { code?: string } | null)?.code;
    if (code === 'auth/popup-blocked' || code === 'auth/operation-not-supported-in-this-environment') {
      throw new GameAccessError('GOOGLE_POPUP_BLOCKED',
        'Không mở được cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên hoặc thử mở trang bằng Safari/Chrome.');
    }
    if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') {
      throw new GameAccessError('GOOGLE_POPUP_CLOSED',
        'Cửa sổ Google đã đóng trước khi đăng nhập hoàn tất. Hãy bấm Tiếp tục với Google để thử lại.');
    }
    if (code === 'auth/unauthorized-domain') {
      throw new GameAccessError('GOOGLE_DOMAIN_NOT_AUTHORIZED',
        'Tên miền game chưa được cấp quyền đăng nhập Google. Vui lòng liên hệ quản trị viên.');
    }
    if (code === 'auth/network-request-failed') {
      throw new GameAccessError('GOOGLE_NETWORK_ERROR',
        'Không kết nối được với dịch vụ đăng nhập Google. Kiểm tra mạng và thử lại.');
    }
    throw error;
  }
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
