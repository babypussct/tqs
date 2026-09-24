import type { VercelRequest, VercelResponse } from '@vercel/node';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getAdminDb } from './_lib/firebaseAdmin.js';
import { authenticateActor } from './_lib/auth.js';
import { toDate } from '../src/shared/data/date.js';

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

  const voucherId = typeof req.body?.voucherId === 'string' ? req.body.voucherId.trim() : '';
  if (!voucherId || voucherId.includes('/') || voucherId.length > 150) {
    return res.status(400).json({ success: false, code: 'INVALID_VOUCHER_ID', message: 'Voucher không hợp lệ.' });
  }

  try {
    const result = await db.runTransaction(async (transaction) => {
      const userRef = db.collection('users').doc(authResult.actor.uid);
      const voucherRef = db.collection('discountCodes').doc(voucherId);
      const userSnapshot = await transaction.get(userRef);
      const voucherSnapshot = await transaction.get(voucherRef);

      if (!userSnapshot.exists) throw new Error('USER_NOT_FOUND');
      if (!voucherSnapshot.exists) throw new Error('VOUCHER_NOT_FOUND');

      const user = userSnapshot.data() || {};
      const voucher = voucherSnapshot.data() || {};
      const savedVouchers: string[] = Array.isArray(user.savedVouchers) ? user.savedVouchers : [];
      if (savedVouchers.includes(voucherId)) throw new Error('VOUCHER_ALREADY_SAVED');
      if (voucher.isActive !== true || voucher.isPubliclyVisible === false) throw new Error('VOUCHER_UNAVAILABLE');

      const now = Timestamp.now().toMillis();
      const start = toDate(voucher.startDate)?.getTime() ?? now;
      const end = toDate(voucher.endDate)?.getTime() ?? Number.MAX_SAFE_INTEGER;
      if (now < start) throw new Error('VOUCHER_NOT_STARTED');
      if (now > end) throw new Error('VOUCHER_EXPIRED');
      if (voucher.usageLimit && Number(voucher.usedCount || 0) >= Number(voucher.usageLimit)) {
        throw new Error('VOUCHER_USAGE_EXHAUSTED');
      }
      if (voucher.applicableTiers?.length && !voucher.applicableTiers.includes(user.tier || 'bronze')) {
        throw new Error('VOUCHER_TIER_NOT_ELIGIBLE');
      }
      if (voucher.customerType === 'new' && Number(user.totalOrders || 0) > 0) {
        throw new Error('VOUCHER_CUSTOMER_TYPE_NOT_ELIGIBLE');
      }
      if (voucher.customerType === 'returning' && Number(user.totalOrders || 0) === 0) {
        throw new Error('VOUCHER_CUSTOMER_TYPE_NOT_ELIGIBLE');
      }

      const cost = Math.max(0, Math.floor(Number(voucher.pointsCost) || 0));
      if (Number(user.points || 0) < cost) throw new Error('INSUFFICIENT_POINTS');

      const update: Record<string, unknown> = {
        savedVouchers: FieldValue.arrayUnion(voucherId),
      };
      if (cost > 0) update.points = FieldValue.increment(-cost);
      transaction.update(userRef, update as FirebaseFirestore.UpdateData<unknown>);

      return { cost };
    });

    return res.status(200).json({ success: true, ...result });
  } catch (error) {
    const code = error instanceof Error ? error.message : 'VOUCHER_CLAIM_FAILED';
    const messages: Record<string, string> = {
      USER_NOT_FOUND: 'Không tìm thấy hồ sơ người dùng.',
      VOUCHER_NOT_FOUND: 'Không tìm thấy voucher.',
      VOUCHER_ALREADY_SAVED: 'Bạn đã lưu voucher này rồi.',
      VOUCHER_UNAVAILABLE: 'Voucher hiện không khả dụng.',
      VOUCHER_NOT_STARTED: 'Voucher chưa đến thời gian sử dụng.',
      VOUCHER_EXPIRED: 'Voucher đã hết hạn.',
      VOUCHER_USAGE_EXHAUSTED: 'Voucher đã hết lượt sử dụng.',
      VOUCHER_TIER_NOT_ELIGIBLE: 'Voucher không áp dụng cho hạng thành viên của bạn.',
      VOUCHER_CUSTOMER_TYPE_NOT_ELIGIBLE: 'Voucher không áp dụng cho loại khách hàng của bạn.',
      INSUFFICIENT_POINTS: 'Bạn không đủ điểm để đổi voucher này.',
    };
    return res.status(code === 'VOUCHER_ALREADY_SAVED' ? 409 : 400).json({
      success: false,
      code,
      message: messages[code] || 'Không thể lưu voucher lúc này.',
    });
  }
}
