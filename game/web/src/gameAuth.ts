import { initializeApp } from 'firebase/app';
import {
  browserLocalPersistence,
  getAuth,
  getRedirectResult,
  GoogleAuthProvider,
  onAuthStateChanged,
  setPersistence,
  signInWithPopup,
  signInWithRedirect,
  signOut,
  type User,
} from 'firebase/auth';
import firebaseConfig from '../../../firebase-applet-config.json';
import { userFacingError } from './engine/connectionMessages';
import { googleLoginMode } from './googleAuthRouting';
import { normalizeInitialGeneralCount } from '../../../src/game/gamePoolPacks';

const REDIRECT_ATTEMPT_KEY = 'tqs-game-google-redirect-attempt';
export const gameGoogleLoginMode = googleLoginMode({
  userAgent: navigator.userAgent,
  standalone: Boolean((navigator as Navigator & { standalone?: boolean }).standalone) ||
    window.matchMedia('(display-mode: standalone)').matches,
  maxTouchPoints: navigator.maxTouchPoints || 0,
  hostname: window.location.hostname,
  sameOriginEnabled: import.meta.env.VITE_TQS_GAME_SAME_ORIGIN_GOOGLE_AUTH === 'true',
  authDomainOverridden: Boolean(import.meta.env.VITE_FIREBASE_AUTH_DOMAIN),
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || firebaseConfig.projectId,
  expectedProjectId: firebaseConfig.projectId,
});

const config = {
  ...firebaseConfig,
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || firebaseConfig.apiKey,
  authDomain: gameGoogleLoginMode === 'same-origin-redirect'
    ? window.location.hostname
    : import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || firebaseConfig.authDomain,
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
  generalNum: number;
  disabledPacks: { generals: string[]; cards: string[] };
  appliesTo: 'new_rooms';
}

export interface GameSession {
  uid: string;
  displayName: string;
  nativeName: string;
  ticket: string;
  /** Optional signed gateway quota assertion, carried as a WS subprotocol. */
  gatewayAdmission?: string;
  expiresAt: number;
  poolPolicy: GamePoolPolicyPayload;
}

interface QaPreauthSession extends GameSession {}

declare global {
  interface Window {
    __tqsE2eGameSession?: unknown;
  }
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

function localQaPreauthSession(): QaPreauthSession | null {
  // This is deliberately unreachable from a hosted game. The multiplayer
  // runner serves a frozen build on loopback and opts in with the query
  // marker; no production hostname, Firebase account, or API route can use
  // this branch.
  if (!['127.0.0.1', 'localhost'].includes(window.location.hostname) ||
      new URLSearchParams(window.location.search).get('tqs-e2e-preauth') !== '1') return null;
  const value = window.__tqsE2eGameSession;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const candidate = value as Partial<QaPreauthSession>;
  const policy = candidate.poolPolicy;
  const expiresAt = candidate.expiresAt;
  if (typeof candidate.uid !== 'string' || !candidate.uid || candidate.uid.length > 128 ||
      typeof candidate.displayName !== 'string' || candidate.displayName.length > 128 ||
      typeof candidate.nativeName !== 'string' || !candidate.nativeName || candidate.nativeName.length > 96 ||
      typeof candidate.ticket !== 'string' || !candidate.ticket || candidate.ticket.length > 213 ||
      (candidate.gatewayAdmission !== undefined &&
        (typeof candidate.gatewayAdmission !== 'string' || !/^[A-Za-z0-9_-]{1,768}$/.test(candidate.gatewayAdmission))) ||
      typeof expiresAt !== 'number' || !Number.isInteger(expiresAt) || expiresAt <= Math.floor(Date.now() / 1000) ||
      !policy || policy.schemaVersion !== 1 || policy.mode !== 'new_heg_mode' ||
      !Number.isInteger(policy.revision) || !Number.isInteger(policy.generalNum) ||
      !Array.isArray(policy.disabledPacks?.generals) || !Array.isArray(policy.disabledPacks?.cards) ||
      policy.appliesTo !== 'new_rooms') return null;
  return candidate as QaPreauthSession;
}

/** Prepare Firebase storage before the user presses the Google button. */
export async function prepareGameAuth(): Promise<void> {
  if (localQaPreauthSession()) return;
  await ensurePersistence();
  await gameAuth.authStateReady();
}

/** Called once after returning from Google. Auth state can be restored even
 * when getRedirectResult is empty; never exchange a missing user for a ticket. */
export async function completeGameGoogleRedirect(): Promise<void> {
  if (localQaPreauthSession()) return;
  if (gameGoogleLoginMode !== 'same-origin-redirect') return;
  let pending = false;
  try {
    pending = sessionStorage.getItem(REDIRECT_ATTEMPT_KEY) === '1';
    sessionStorage.removeItem(REDIRECT_ATTEMPT_KEY);
  } catch {
    throw new GameAccessError('GOOGLE_STORAGE_UNAVAILABLE',
      'Trình duyệt không cho lưu trạng thái đăng nhập Google. Hãy mở trò chơi bằng Safari và thử lại.');
  }
  if (!pending) return;
  try {
    const result = await getRedirectResult(gameAuth);
    if (!result?.user && !gameAuth.currentUser) {
      throw new GameAccessError('GOOGLE_REDIRECT_INCOMPLETE',
        'Google chưa hoàn tất đăng nhập. Hãy chọn Tiếp tục với Google để thử lại.');
    }
  } catch (error) {
    throw googleLoginError(error);
  }
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
    // The API message may contain diagnostics. Display only known public codes.
    const code = typeof payload.code === 'string' ? payload.code
      : response.status >= 500 ? 'GAME_AUTH_UNAVAILABLE' : 'GAME_AUTH_FAILED';
    throw new GameAccessError(
      code,
      userFacingError({ code }, 'auth'),
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
    gatewayAdmission: typeof payload.gatewayAdmission === 'string' ? payload.gatewayAdmission : undefined,
    expiresAt: Number(payload.expiresAt),
    poolPolicy: {
      schemaVersion: 1,
      mode: 'new_heg_mode',
      revision: Number.isInteger(policy.revision) ? Number(policy.revision) : 0,
      generalNum: normalizeInitialGeneralCount(policy.generalNum),
      disabledPacks: {
        generals: disabledPacks.generals.filter((id): id is string => typeof id === 'string'),
        cards: disabledPacks.cards.filter((id): id is string => typeof id === 'string'),
      },
      appliesTo: 'new_rooms',
    },
  };
}

function googleLoginError(error: unknown): Error {
  if (error instanceof GameAccessError) return error;
  const code = (error as { code?: string } | null)?.code;
  if (code === 'auth/popup-blocked' || code === 'auth/operation-not-supported-in-this-environment') {
    return new GameAccessError('GOOGLE_POPUP_BLOCKED',
      'Không mở được cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên hoặc thử mở trang bằng Safari/Chrome.');
  }
  if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') {
    return new GameAccessError('GOOGLE_POPUP_CLOSED',
      'Cửa sổ Google đã đóng trước khi đăng nhập hoàn tất. Hãy bấm Tiếp tục với Google để thử lại.');
  }
  if (code === 'auth/unauthorized-domain') {
    return new GameAccessError('GOOGLE_DOMAIN_NOT_AUTHORIZED',
      'Tên miền game chưa được cấp quyền đăng nhập Google. Vui lòng liên hệ quản trị viên.');
  }
  if (code === 'auth/network-request-failed') {
    return new GameAccessError('GOOGLE_NETWORK_ERROR',
      'Không kết nối được với dịch vụ đăng nhập Google. Kiểm tra mạng và thử lại.');
  }
  return error instanceof Error ? error : new Error('Google login failed');
}

/** Returns null when a full-page Google redirect has started. */
export async function signInAndCreateGameSession(): Promise<GameSession | null> {
  const qaSession = localQaPreauthSession();
  if (qaSession) return qaSession;
  if (gameGoogleLoginMode === 'open-in-browser') {
    throw new GameAccessError('GOOGLE_OPEN_IN_BROWSER',
      'Đăng nhập Google từ ứng dụng đã cài trên iPhone chưa được hỗ trợ. Hãy mở tqsvn.pages.dev trong Safari.');
  }
  if (gameGoogleLoginMode === 'same-origin-redirect') {
    try {
      sessionStorage.setItem(REDIRECT_ATTEMPT_KEY, '1');
    } catch {
      throw new GameAccessError('GOOGLE_STORAGE_UNAVAILABLE',
        'Trình duyệt không cho lưu trạng thái đăng nhập Google. Hãy mở trò chơi bằng Safari.');
    }
    try {
      await signInWithRedirect(gameAuth, googleProvider);
      return null;
    } catch (error) {
      try { sessionStorage.removeItem(REDIRECT_ATTEMPT_KEY); } catch { /* Already blocked. */ }
      throw googleLoginError(error);
    }
  }
  // Do not await storage setup here: iOS Home Screen PWAs can reject a
  // window.open when the click's transient user activation has expired.
  // LoginScreen enables its button only after prepareGameAuth succeeds.
  let result: Awaited<ReturnType<typeof signInWithPopup>>;
  try {
    result = await signInWithPopup(gameAuth, googleProvider);
  } catch (error) {
    throw googleLoginError(error);
  }
  return requestGameSession(result.user);
}

export async function createGameSessionForCurrentUser(): Promise<GameSession> {
  const qaSession = localQaPreauthSession();
  if (qaSession) return qaSession;
  await ensurePersistence();
  if (!gameAuth.currentUser) throw new GameAccessError('LOGIN_REQUIRED', 'Hãy đăng nhập Google để vào game.');
  return requestGameSession(gameAuth.currentUser);
}

export function watchGameUser(callback: (user: User | null) => void): () => void {
  if (localQaPreauthSession()) {
    callback(null);
    return () => undefined;
  }
  return onAuthStateChanged(gameAuth, callback);
}

export async function logoutGame(): Promise<void> {
  await signOut(gameAuth);
}
