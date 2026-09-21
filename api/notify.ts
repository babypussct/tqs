import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';

if (!admin.apps.length) {
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
  }
}

function getDb(): FirebaseFirestore.Firestore {
  const databaseId = process.env.FIREBASE_DATABASE_ID;
  try {
    return databaseId ? getFirestore(admin.app(), databaseId) : getFirestore(admin.app());
  } catch {
    return getFirestore(admin.app());
  }
}

function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function boundedText(value: unknown, maxLength: number, fallback = 'N/A'): string {
  const text = String(value ?? '').trim();
  if (!text) return fallback;
  return text.length > maxLength ? `${text.slice(0, maxLength - 1)}…` : text;
}

function getBearerToken(req: VercelRequest): string | null {
  const authorization = req.headers.authorization;
  if (!authorization) return null;
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
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
    console.error('Notification ID token verification failed:', error?.message || error);
    return res.status(401).json({
      success: false,
      code: 'INVALID_TOKEN',
      message: 'Firebase ID token không hợp lệ hoặc đã hết hạn.',
    });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (body.type !== 'NEW_REVIEW') {
    return res.status(400).json({
      success: false,
      code: 'UNSUPPORTED_NOTIFICATION_TYPE',
      message: 'Chỉ hỗ trợ thông báo đánh giá mới.',
    });
  }

  const reviewId = typeof body.reviewId === 'string' ? body.reviewId.trim() : '';
  if (!reviewId || reviewId.length > 150 || reviewId.includes('/')) {
    return res.status(400).json({
      success: false,
      code: 'INVALID_REVIEW_ID',
      message: 'reviewId không hợp lệ.',
    });
  }

  let db: FirebaseFirestore.Firestore;
  try {
    db = getDb();
  } catch (error: any) {
    console.error('Notification database initialization failed:', error?.message || error);
    return res.status(500).json({
      success: false,
      code: 'NOTIFICATION_INTERNAL_ERROR',
      message: 'Không thể xử lý thông báo lúc này.',
    });
  }

  let reviewSnapshot: FirebaseFirestore.DocumentSnapshot;
  try {
    reviewSnapshot = await db.collection('reviews').doc(reviewId).get();
  } catch (error: any) {
    console.error('Review lookup failed:', error?.message || error);
    return res.status(500).json({
      success: false,
      code: 'NOTIFICATION_INTERNAL_ERROR',
      message: 'Không thể xử lý thông báo lúc này.',
    });
  }
  if (!reviewSnapshot.exists) {
    return res.status(404).json({
      success: false,
      code: 'REVIEW_NOT_FOUND',
      message: 'Không tìm thấy đánh giá.',
    });
  }

  const review = reviewSnapshot.data() || {};
  if (review.userId !== decodedToken.uid) {
    return res.status(403).json({
      success: false,
      code: 'REVIEW_OWNERSHIP_REQUIRED',
      message: 'Bạn không có quyền gửi thông báo cho đánh giá này.',
    });
  }

  if (review.rating === undefined || !Number.isInteger(Number(review.rating)) || Number(review.rating) < 1 || Number(review.rating) > 5) {
    return res.status(400).json({
      success: false,
      code: 'INVALID_REVIEW_RATING',
      message: 'Đánh giá có số sao không hợp lệ.',
    });
  }

  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  if (!botToken || !chatId) {
    return res.status(503).json({
      success: false,
      code: 'TELEGRAM_NOT_CONFIGURED',
      message: 'Kênh thông báo chưa được cấu hình.',
    });
  }

  let productName = boundedText(review.productId, 160);
  if (review.productId) {
    try {
      const productSnapshot = await db.collection('products').doc(String(review.productId)).get();
      if (productSnapshot.exists) {
        productName = boundedText(productSnapshot.data()?.name, 160, productName);
      }
    } catch (error: any) {
      // The review itself is authoritative for ownership; a missing product
      // lookup should not prevent a safe notification with the product ID.
      console.warn('Product lookup for review notification failed:', error?.message || error);
    }
  }

  const rating = Number(review.rating);
  const stars = '⭐'.repeat(rating) + '☆'.repeat(5 - rating);
  const userName = boundedText(review.userName, 120, 'Người dùng ẩn danh');
  const comment = boundedText(review.comment, 1200);
  const message = [
    '⭐ <b>ĐÁNH GIÁ SẢN PHẨM MỚI</b>',
    '─────────────────────',
    `🛍️ Sản phẩm: <b>${escapeHtml(productName)}</b>`,
    `👤 Khách hàng: ${escapeHtml(userName)}`,
    `🌟 Điểm: ${stars}`,
    `💬 Nội dung: <i>${escapeHtml(comment)}</i>`,
    `🆔 Review ID: <code>${escapeHtml(reviewId)}</code>`,
  ].join('\n');

  try {
    const telegramResponse = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text: message, parse_mode: 'HTML' }),
    });
    let telegramData: any = null;
    try {
      telegramData = await telegramResponse.json();
    } catch {
      // Treat an invalid response body as a failed dispatch below.
    }
    if (!telegramResponse.ok || telegramData?.ok !== true) {
      console.error('Telegram review notification failed:', telegramData);
      return res.status(502).json({
        success: false,
        code: 'TELEGRAM_DISPATCH_FAILED',
        message: 'Không thể gửi thông báo Telegram.',
      });
    }
  } catch (error: any) {
    console.error('Telegram review notification error:', error?.message || error);
    return res.status(502).json({
      success: false,
      code: 'TELEGRAM_DISPATCH_FAILED',
      message: 'Không thể gửi thông báo Telegram.',
    });
  }

  return res.status(200).json({ success: true, type: 'NEW_REVIEW', reviewId });
}
