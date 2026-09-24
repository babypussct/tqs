import { VercelRequest, VercelResponse } from '@vercel/node';
import { getAdminDb } from './_lib/firebaseAdmin.js';
import { authenticateActor } from './_lib/auth.js';

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

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const origin = process.env.APP_ORIGIN || (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : '');
  if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' });
  }

  let db: FirebaseFirestore.Firestore;
  try {
    db = getAdminDb();
  } catch (error: any) {
    console.error('Notification database initialization failed:', error?.message || error);
    return res.status(500).json({
      success: false,
      code: 'NOTIFICATION_INTERNAL_ERROR',
      message: 'Không thể xử lý thông báo lúc này.',
    });
  }

  const authResult = await authenticateActor(req, db);
  if ('errorCode' in authResult) {
    return res.status(authResult.status).json({
      success: false,
      code: authResult.errorCode,
      message: authResult.message,
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
  if (review.userId !== authResult.actor.uid) {
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
