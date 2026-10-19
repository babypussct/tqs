import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createHmac } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getAdminDb } from '../_lib/firebaseAdmin.js';
import { authenticateActor } from '../_lib/auth.js';
import type { GamePoolPolicy } from '../../src/types.js';
import { normalizeInitialGeneralCount, sanitizeDisabledGamePacks } from '../../src/game/gamePoolPacks.js';

const GAME_MODE = 'new_heg_mode' as const;
const TICKET_TTL_SECONDS = 5 * 60;

type NormalizedPoolPolicy = Pick<GamePoolPolicy, 'schemaVersion' | 'mode' | 'revision' | 'generalNum' | 'disabledPacks' | 'appliesTo'>;

function allowedOrigins(): Set<string> {
  return new Set(
    (process.env.GAME_ALLOWED_ORIGINS || process.env.APP_ORIGIN || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );
}

function setCorsHeaders(req: VercelRequest, res: VercelResponse): boolean {
  const requestOrigin = typeof req.headers.origin === 'string' ? req.headers.origin : '';
  const origins = allowedOrigins();

  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Cache-Control', 'no-store');

  // The endpoint accepts a bearer token and never uses cookies. A wildcard is
  // safe as the fallback for a separately hosted Pages game; production can
  // still pin the exact Pages origin with GAME_ALLOWED_ORIGINS.
  if (!requestOrigin) return true;
  if (origins.size > 0 && !origins.has(requestOrigin)) return false;
  res.setHeader('Access-Control-Allow-Origin', origins.size > 0 ? requestOrigin : '*');
  if (origins.size > 0) res.setHeader('Vary', 'Origin');
  return true;
}

function safeText(value: unknown, maxLength: number): string | undefined {
  if (typeof value !== 'string') return undefined;
  const text = value.trim().replace(/[\u0000-\u001f\u007f]/g, '').slice(0, maxLength);
  return text || undefined;
}

function nativeNameFor(uid: string): string {
  const suffix = uid.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 64);
  return `tqs_${suffix || 'player'}`.slice(0, 80);
}

function normalizePolicy(value: FirebaseFirestore.DocumentData | undefined): NormalizedPoolPolicy {
  const rawRevision = value?.revision;
  const revision = typeof rawRevision === 'number' && Number.isInteger(rawRevision) && rawRevision >= 0
    ? rawRevision
    : 0;
  return {
    schemaVersion: 1,
    mode: GAME_MODE,
    revision,
    generalNum: normalizeInitialGeneralCount(value?.generalNum),
    disabledPacks: sanitizeDisabledGamePacks(value?.disabledPacks).disabledPacks,
    appliesTo: 'new_rooms',
  };
}

function signTicket(nativeName: string, expiresAt: number, secret: string): string {
  const payload = `TQS1|${nativeName}|${expiresAt}`;
  const signature = createHmac('sha256', secret).update(payload).digest('hex');
  return `TQS1|${expiresAt}|${signature}`;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (!setCorsHeaders(req, res)) {
    return res.status(403).json({ success: false, code: 'ORIGIN_NOT_ALLOWED', message: 'Nguồn game không được phép.' });
  }
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' });

  const db = getAdminDb();
  const authResult = await authenticateActor(req, db);
  if ('errorCode' in authResult) {
    return res.status(authResult.status).json({ success: false, code: authResult.errorCode, message: authResult.message });
  }

  const actor = authResult.actor;
  const accessRef = db.collection('gameAccess').doc(actor.uid);
  const accessSnapshot = await accessRef.get();
  const existing = accessSnapshot.data() || {};

  if (!accessSnapshot.exists) {
    // The first game attempt is an access request, never a native account
    // registration. Admins approve this document from TQSShop.
    await accessRef.set({
      uid: actor.uid,
      status: 'pending',
      email: actor.email || null,
      displayName: actor.displayName || null,
      gameName: safeText(actor.displayName, 40) || safeText(actor.email?.split('@')[0], 40) || 'Chúa Công',
      nativeName: nativeNameFor(actor.uid),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return res.status(403).json({
      success: false,
      code: 'GAME_ACCESS_PENDING',
      status: 'pending',
      message: 'Đã gửi yêu cầu. Tài khoản game đang chờ quản trị viên duyệt.',
    });
  }

  const expectedNativeName = nativeNameFor(actor.uid);
  if (existing.nativeName !== expectedNativeName || 'nativeAccountId' in existing) {
    await accessRef.set({
      nativeName: expectedNativeName,
      nativeAccountId: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  const status = existing.status;
  if (status !== 'approved') {
    const pending = status === 'pending';
    return res.status(403).json({
      success: false,
      code: pending ? 'GAME_ACCESS_PENDING' : 'GAME_ACCESS_SUSPENDED',
      status: pending ? 'pending' : 'suspended',
      message: pending
        ? 'Tài khoản game đang chờ quản trị viên duyệt.'
        : 'Quyền truy cập game của tài khoản đang bị tạm dừng.',
    });
  }

  const secret = (process.env.TQS_GAME_TICKET_SECRET || '').trim();
  if (secret.length < 32) {
    console.error('TQS_GAME_TICKET_SECRET is missing or shorter than 32 characters.');
    return res.status(503).json({ success: false, code: 'GAME_AUTH_NOT_CONFIGURED', message: 'Máy chủ game chưa hoàn tất cấu hình xác thực.' });
  }

  // Existing legacy mappings are deliberately ignored. Every approved
  // Firebase identity gets a fresh deterministic native namespace, so an
  // admin cannot retain or migrate an old native account by editing Firestore.
  const nativeName = expectedNativeName;
  const gameName = safeText(existing.gameName, 80) || safeText(actor.displayName, 80) || nativeName;
  const expiresAt = Math.floor(Date.now() / 1000) + TICKET_TTL_SECONDS;
  const policySnapshot = await db.collection('gamePoolPolicies').doc(GAME_MODE).get();
  const policy = normalizePolicy(policySnapshot.data());

  if (existing.nativeName !== nativeName || existing.email !== actor.email || existing.displayName !== actor.displayName) {
    await accessRef.set({
      nativeName,
      email: actor.email || null,
      displayName: actor.displayName || null,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  return res.status(200).json({
    success: true,
    status: 'approved',
    uid: actor.uid,
    displayName: gameName,
    nativeName,
    ticket: signTicket(nativeName, expiresAt, secret),
    expiresAt,
    poolPolicy: policy,
  });
}
