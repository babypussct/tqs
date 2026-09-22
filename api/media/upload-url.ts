import type { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'node:crypto';
import {
  MEDIA_CACHE_CONTROL,
  buildMediaObjectKey,
  hasMediaUploadPermission,
  normalizePublicBaseUrl,
  validateMediaUploadRequest,
  type MediaCategory,
} from '../../src/media/mediaPolicy.js';

const PRESIGNED_URL_TTL_SECONDS = 15 * 60;

function initializeFirebaseAdmin(): void {
  if (admin.apps.length > 0) return;

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      return;
    }

    if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
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
      return;
    }

    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'gen-lang-client-0845413094',
    });
  } catch (error) {
    console.error('Firebase Admin initialization failed for media upload:', error);
  }
}

initializeFirebaseAdmin();

function getDb(): FirebaseFirestore.Firestore {
  const databaseId = process.env.FIREBASE_DATABASE_ID;
  try {
    return databaseId ? getFirestore(admin.app(), databaseId) : getFirestore(admin.app());
  } catch {
    return getFirestore(admin.app());
  }
}

function getBearerToken(req: VercelRequest): string | null {
  const authorization = req.headers.authorization;
  if (!authorization) return null;
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}

function getAllowedOrigins(): Set<string> {
  return new Set(
    (process.env.MEDIA_ALLOWED_ORIGINS || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );
}

function setCorsHeaders(req: VercelRequest, res: VercelResponse): boolean {
  const requestOrigin = typeof req.headers.origin === 'string' ? req.headers.origin : '';
  const allowedOrigins = getAllowedOrigins();

  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (!requestOrigin) return true;
  if (allowedOrigins.size > 0 && !allowedOrigins.has(requestOrigin)) return false;

  if (allowedOrigins.has(requestOrigin)) {
    res.setHeader('Access-Control-Allow-Origin', requestOrigin);
    res.setHeader('Vary', 'Origin');
  }
  return true;
}

function getRequestBody(req: VercelRequest): Record<string, unknown> {
  if (req.body && typeof req.body === 'object') return req.body as Record<string, unknown>;
  if (typeof req.body === 'string') {
    try {
      const parsed = JSON.parse(req.body);
      return parsed && typeof parsed === 'object' ? parsed as Record<string, unknown> : {};
    } catch {
      return {};
    }
  }
  return {};
}

interface R2Config {
  bucketName: string;
  publicBaseUrl: string;
  client: S3Client;
}

function getR2Config(): R2Config | null {
  const accountId = (process.env.R2_ACCOUNT_ID || process.env.CLOUDFLARE_ACCOUNT_ID || '').trim();
  const accessKeyId = (process.env.R2_ACCESS_KEY_ID || '').trim();
  const secretAccessKey = (process.env.R2_SECRET_ACCESS_KEY || '').trim();
  const bucketName = (process.env.R2_BUCKET_NAME || '').trim();
  const publicBaseUrl = normalizePublicBaseUrl(
    process.env.R2_PUBLIC_BASE_URL || process.env.R2_CUSTOM_DOMAIN,
  );

  if (!accountId || !accessKeyId || !secretAccessKey || !bucketName || !publicBaseUrl) return null;

  return {
    bucketName,
    publicBaseUrl,
    client: new S3Client({
      region: 'auto',
      endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId, secretAccessKey },
    }),
  };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const originAllowed = setCorsHeaders(req, res);
  if (!originAllowed) {
    return res.status(403).json({
      success: false,
      code: 'ORIGIN_NOT_ALLOWED',
      message: 'Origin không được phép tải media.',
    });
  }

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' });
  }

  const idToken = getBearerToken(req);
  if (!idToken) {
    return res.status(401).json({
      success: false,
      code: 'UNAUTHORIZED',
      message: 'Thiếu Firebase ID token.',
    });
  }

  let decodedToken: admin.auth.DecodedIdToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error: any) {
    console.error('Media upload token verification failed:', error?.message || error);
    return res.status(401).json({
      success: false,
      code: 'INVALID_TOKEN',
      message: 'Firebase ID token không hợp lệ hoặc đã hết hạn.',
    });
  }

  const body = getRequestBody(req);
  const validation = validateMediaUploadRequest({
    filename: body.filename,
    contentType: body.contentType,
    size: body.size,
    category: body.category,
  });
  if (validation.ok === false) {
    return res.status(400).json({
      success: false,
      code: validation.error.code,
      message: validation.error.message,
    });
  }

  let profile: Record<string, unknown>;
  try {
    const userSnapshot = await getDb().collection('users').doc(decodedToken.uid).get();
    profile = (userSnapshot.data() || {}) as Record<string, unknown>;
  } catch (error: any) {
    console.error('Media upload user lookup failed:', error?.message || error);
    return res.status(500).json({
      success: false,
      code: 'MEDIA_AUTHORITY_LOOKUP_FAILED',
      message: 'Không thể kiểm tra quyền tải media lúc này.',
    });
  }

  if (profile.isBanned === true) {
    return res.status(403).json({
      success: false,
      code: 'ACCOUNT_BANNED',
      message: 'Tài khoản của bạn đã bị khóa.',
    });
  }

  if (!hasMediaUploadPermission(
    validation.value.category,
    {
      role: profile.role,
      isSuperAdmin: profile.isSuperAdmin,
      adminPermissions: profile.adminPermissions as Record<string, unknown> | null | undefined,
    },
    { super_admin: decodedToken.super_admin },
  )) {
    return res.status(403).json({
      success: false,
      code: 'MEDIA_UPLOAD_PERMISSION_REQUIRED',
      message: 'Bạn không có quyền tải loại media này.',
    });
  }

  const r2 = getR2Config();
  if (!r2) {
    return res.status(503).json({
      success: false,
      code: 'R2_NOT_CONFIGURED',
      message: 'Kho media chưa được cấu hình trên server.',
    });
  }

  const objectKey = buildMediaObjectKey(
    validation.value.category as MediaCategory,
    validation.value.extension,
    new Date(),
    randomUUID(),
  );

  try {
    const command = new PutObjectCommand({
      Bucket: r2.bucketName,
      Key: objectKey,
      ContentType: validation.value.contentType,
      CacheControl: MEDIA_CACHE_CONTROL,
    });
    const uploadUrl = await getSignedUrl(r2.client, command, { expiresIn: PRESIGNED_URL_TTL_SECONDS });
    const publicUrl = `${r2.publicBaseUrl}/${objectKey.split('/').map(encodeURIComponent).join('/')}`;

    return res.status(200).json({
      success: true,
      uploadUrl,
      publicUrl,
      key: objectKey,
      expiresIn: PRESIGNED_URL_TTL_SECONDS,
      uploadHeaders: {
        'Content-Type': validation.value.contentType,
        'Cache-Control': MEDIA_CACHE_CONTROL,
      },
    });
  } catch (error: any) {
    console.error('R2 presigned URL creation failed:', error?.message || error);
    return res.status(500).json({
      success: false,
      code: 'MEDIA_UPLOAD_URL_FAILED',
      message: 'Không thể tạo URL tải media lúc này.',
    });
  }
}
