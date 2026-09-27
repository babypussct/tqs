import type { VercelRequest, VercelResponse } from '@vercel/node';
import { Timestamp } from 'firebase-admin/firestore';
import { getAdminDb } from './_lib/firebaseAdmin.js';
import { authenticateActor } from './_lib/auth.js';

function sendCors(res: VercelResponse): void {
  const origin = process.env.APP_ORIGIN || (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : '');
  if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  sendCors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' });

  const db = getAdminDb();
  const authResult = await authenticateActor(req, db);
  if ('errorCode' in authResult) {
    return res.status(authResult.status).json({ success: false, code: authResult.errorCode, message: authResult.message });
  }

  const productId = typeof req.body?.productId === 'string' ? req.body.productId.trim() : '';
  const comment = typeof req.body?.comment === 'string' ? req.body.comment.trim() : '';
  const rating = Number(req.body?.rating);
  if (!productId || productId.includes('/') || productId.length > 150 || !Number.isInteger(rating) || rating < 1 || rating > 5 || !comment || comment.length > 1000) {
    return res.status(400).json({ success: false, code: 'INVALID_REVIEW', message: 'Nội dung đánh giá không hợp lệ.' });
  }

  const deliveredOrders = await db.collection('orders')
    .where('userId', '==', authResult.actor.uid)
    .where('status', '==', 'delivered')
    .get();
  const hasPurchased = deliveredOrders.docs.some((snapshot) => {
    const items = snapshot.data()?.items;
    return Array.isArray(items) && items.some((item: Record<string, unknown>) => item.productId === productId);
  });
  if (!hasPurchased) {
    return res.status(403).json({ success: false, code: 'PURCHASE_REQUIRED', message: 'Bạn cần mua và nhận sản phẩm trước khi đánh giá.' });
  }

  const reviewId = `review_${authResult.actor.uid}_${productId}`;
  const reviewRef = db.collection('reviews').doc(reviewId);
  const safeDisplayName = (authResult.actor.displayName || 'Người dùng ẩn danh').trim().slice(0, 120) || 'Người dùng ẩn danh';

  try {
    await db.runTransaction(async (transaction) => {
      // The deterministic key closes the check-then-create race for new
      // reviews. The query also protects against legacy random-ID reviews
      // created before this endpoint was hardened.
      const deterministicSnapshot = await transaction.get(reviewRef);
      const legacySnapshot = await transaction.get(
        db.collection('reviews')
          .where('userId', '==', authResult.actor.uid)
          .where('productId', '==', productId)
          .limit(1),
      );
      if (deterministicSnapshot.exists || !legacySnapshot.empty) {
        throw new Error('REVIEW_ALREADY_EXISTS');
      }

      transaction.create(reviewRef, {
        productId,
        userId: authResult.actor.uid,
        userName: safeDisplayName,
        userPhoto: '',
        rating,
        comment,
        createdAt: Timestamp.now(),
      });
    });
  } catch (error) {
    if (error instanceof Error && error.message === 'REVIEW_ALREADY_EXISTS') {
      return res.status(409).json({ success: false, code: 'REVIEW_ALREADY_EXISTS', message: 'Bạn đã đánh giá sản phẩm này.' });
    }
    console.error('Review creation failed:', error instanceof Error ? error.message : error);
    return res.status(500).json({ success: false, code: 'REVIEW_CREATE_FAILED', message: 'Không thể lưu đánh giá lúc này.' });
  }

  return res.status(201).json({ success: true, reviewId });
}
