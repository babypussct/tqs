import type { VercelRequest, VercelResponse } from '@vercel/node';
import { Timestamp } from 'firebase-admin/firestore';
import { getAdminDb } from './_lib/firebaseAdmin.js';
import { authenticateActor } from './_lib/auth.js';
import { createOrderTransactionDependencies, normalizeOrderDocument } from './_lib/orderTransaction.js';
import {
  createOrder,
  transitionOrder,
  OrderServiceError,
  isValidIdempotencyKey,
} from '../src/order/orderService.js';
import type {
  AuthenticatedActor,
  CreateOrderInput,
  TransitionOrderInput,
} from '../src/order/orderService.js';
import type { OrderDocument } from '../src/order/canonical.js';
import { quoteOrder } from '../src/order/quoteService.js';
import type { QuoteOrderInput } from '../src/order/quoteService.js';

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

// ─── 2. Telegram Notification Helper ───
async function notifyTelegramNewOrder(order: OrderDocument): Promise<void> {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  if (!botToken || !chatId) return;

  try {
    const isSuspicious = order.riskScore && order.riskScore >= 60;
    let message = isSuspicious
      ? `⚠️ <b>CẢNH BÁO: ĐƠN HÀNG RỦI RO CAO</b> ⚠️\nĐiểm rủi ro: <b>${order.riskScore}/100</b>\n─────────────────────\n`
      : `🚀 <b>ĐƠN HÀNG MỚI</b> 🚀\n`;

    message += `Mã đơn: <b>#${escapeHtml(order.id)}</b>\n`;
    message += `Người nhận: ${escapeHtml(boundedText(order.shippingInfo?.fullName, 160))}\n`;
    message += `SĐT: <code>${escapeHtml(boundedText(order.shippingInfo?.phone, 40))}</code>\n`;
    message += `Địa chỉ: ${escapeHtml(boundedText(order.shippingInfo?.address, 300))}\n`;
    if (order.shippingInfo?.notes) {
      message += `Ghi chú: <i>${escapeHtml(boundedText(order.shippingInfo.notes, 500))}</i>\n`;
    }
    message += `─────────────────────\n`;

    if (order.items && order.items.length > 0) {
      order.items.forEach((item) => {
        message += `- ${escapeHtml(item.quantity)} x ${escapeHtml(boundedText(item.name, 160))} (${Number(item.unitPrice || 0).toLocaleString('vi-VN')}đ)\n`;
      });
      message += `─────────────────────\n`;
    }

    message += `Tạm tính: ${Number(order.totalAmount || 0).toLocaleString('vi-VN')} đ\n`;
    if (order.shippingFee > 0) message += `Phí ship: +${Number(order.shippingFee).toLocaleString('vi-VN')} đ\n`;
    if (order.voucherDiscountAmount > 0) message += `Giảm voucher: -${Number(order.voucherDiscountAmount).toLocaleString('vi-VN')} đ\n`;
    if (order.pointsDiscountAmount > 0) message += `Giảm điểm (${escapeHtml(order.pointsApplied)} pts): -${Number(order.pointsDiscountAmount).toLocaleString('vi-VN')} đ\n`;
    message += `Số tiền cần thu: <b>${Number(order.finalAmount || 0).toLocaleString('vi-VN')} đ</b>\n`;
    message += `Phương thức: <b>${order.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;

    const inlineButtons: any[][] = [];
    if (order.paymentMethod === 'vietqr') {
      inlineButtons.push([{ text: '✅ Đã nhận tiền', callback_data: `action:paid:${order.id}` }]);
    } else {
      inlineButtons.push([{ text: '💰 Đã thu COD', callback_data: `action:paid:${order.id}` }]);
    }
    inlineButtons.push([{ text: '🔧 Đang chuẩn bị', callback_data: `action:processing:${order.id}` }]);
    inlineButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${order.id}` }]);
    inlineButtons.push([{ text: '✅ Đã giao thành công', callback_data: `action:delivered:${order.id}` }]);
    inlineButtons.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${order.id}` }]);

    await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML',
        reply_markup: { inline_keyboard: inlineButtons },
      }),
    });
  } catch (err) {
    console.error('Telegram dispatch error (non-fatal):', err);
  }
}

// ─── 3. Main Serverless Handler ───
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Same-origin by default. A separate trusted origin can be configured for
  // preview/admin clients without opening the order endpoint to every site.
  const allowedOrigin = process.env.APP_ORIGIN || (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : '');
  if (allowedOrigin) res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const db = getAdminDb();
  const authResult = await authenticateActor(req, db);
  if ('errorCode' in authResult) {
    return res.status(authResult.status).json({
      success: false,
      code: authResult.errorCode,
      message: authResult.message,
    });
  }
  const actor: AuthenticatedActor = authResult.actor;

  // ─── Route: GET /api/orders?orderId=... ───
  if (req.method === 'GET') {
    const orderId = req.query.orderId as string;
    if (!orderId) {
      return res.status(400).json({ success: false, code: 'MISSING_ORDER_ID', message: 'Thiếu orderId' });
    }

    try {
      const orderSnap = await db.collection('orders').doc(orderId).get();
      if (!orderSnap.exists) {
        return res.status(404).json({ success: false, code: 'ORDER_NOT_FOUND', message: 'Không tìm thấy đơn hàng.' });
      }

      const orderData = normalizeOrderDocument(orderSnap.data() || {}, orderSnap.id);
      // Ownership check: customer can only read their own order
      if (actor.role === 'customer' && orderData.userId !== actor.uid) {
        return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Bạn không có quyền xem đơn hàng này.' });
      }

      return res.status(200).json({ success: true, order: orderData });
    } catch (err: any) {
      return res.status(500).json({ success: false, code: 'INTERNAL_ERROR', message: err.message });
    }
  }

  // ─── Route: POST /api/orders (Create or Transition) ───
  if (req.method === 'POST') {
    const body = req.body || {};

    if (body.intent === 'quote' || req.query.action === 'quote') {
      const quoteInput: QuoteOrderInput = {
        items: body.items,
        shippingInfo: body.shippingInfo,
        paymentMethod: body.paymentMethod,
        discountCode: body.discountCode,
        pointsToUse: body.pointsToUse,
      };
      try {
        const quote = await db.runTransaction((transaction) =>
          quoteOrder(actor, quoteInput, createOrderTransactionDependencies(db, transaction)),
        );
        return res.status(200).json({ success: true, quote });
      } catch (error) {
        const code = error instanceof Error ? error.message : 'QUOTE_FAILED';
        const messages: Record<string, string> = {
          EMPTY_CART: 'Giỏ hàng không được để trống.',
          INVALID_SHIPPING_INFO: 'Thông tin giao hàng chưa đầy đủ.',
          INVALID_PAYMENT_METHOD: 'Phương thức thanh toán không hợp lệ.',
          INVALID_DISCOUNT_CODE: 'Mã giảm giá không hợp lệ.',
          DISCOUNT_NOT_STARTED: 'Mã giảm giá chưa đến thời gian sử dụng.',
          DISCOUNT_EXPIRED: 'Mã giảm giá đã hết hạn.',
          DISCOUNT_USAGE_EXHAUSTED: 'Mã giảm giá đã hết lượt sử dụng.',
          DISCOUNT_USAGE_PER_USER_EXHAUSTED: 'Bạn đã hết lượt sử dụng mã này.',
          DISCOUNT_CUSTOMER_TYPE_INVALID: 'Mã giảm giá không áp dụng cho loại khách hàng của bạn.',
          DISCOUNT_SCOPE_INVALID: 'Mã giảm giá không áp dụng cho sản phẩm trong giỏ hàng.',
          DISCOUNT_MIN_ORDER_NOT_MET: 'Giá trị sản phẩm chưa đạt điều kiện của mã giảm giá.',
          DISCOUNT_TIER_NOT_ELIGIBLE: 'Mã giảm giá không áp dụng cho hạng thành viên của bạn.',
          PRODUCT_NOT_FOUND: 'Một sản phẩm trong giỏ không còn tồn tại.',
          PRODUCT_INACTIVE: 'Một sản phẩm trong giỏ đã ngừng kinh doanh.',
          INSUFFICIENT_STOCK: 'Một sản phẩm trong giỏ không đủ tồn kho.',
          PRODUCT_PAYMENT_METHOD_NOT_ALLOWED: 'Phương thức thanh toán không phù hợp với sản phẩm trong giỏ.',
        };
        return res.status(400).json({ success: false, code, message: messages[code] || 'Không thể tính lại đơn hàng.' });
      }
    }

    const isTransition = Boolean(
      body.targetStatus ||
      body.actionType ||
      req.query.action === 'transition'
    );

    if (!isTransition) {
      const idempotencyKey = typeof body.idempotencyKey === 'string' ? body.idempotencyKey : '';
      const replay = isValidIdempotencyKey(idempotencyKey)
        ? await db.collection('idempotency').doc(`idem_${actor.uid}_create_${idempotencyKey}`).get()
        : null;
      if (!replay?.exists) {
        const recentOrders = await db.collection('orders')
          .where('userId', '==', actor.uid)
          .where('createdAt', '>=', Timestamp.fromMillis(Date.now() - 60 * 60 * 1000))
          .limit(4)
          .get();
        if (recentOrders.size >= 3) {
          return res.status(429).json({
            success: false,
            code: 'ORDER_RATE_LIMITED',
            message: 'Bạn đã đặt quá nhiều đơn trong 1 giờ. Vui lòng thử lại sau.',
          });
        }
      }
    }

    // ── Transition Flow ──
    if (isTransition) {
      const transitionInput: TransitionOrderInput = {
        orderId: body.orderId,
        targetStatus: body.targetStatus,
        paymentStatus: body.paymentStatus,
        cancelReason: body.cancelReason,
        returnReason: body.returnReason,
        stockDisposition: body.stockDisposition,
        carrierDeliveryEvidence: body.carrierDeliveryEvidence,
        overrideWindow: body.overrideWindow,
        actionType: body.actionType,
        metadata: body.metadata,
      };

      try {
        const transitionResult = await db.runTransaction(async (transaction) => {
          return transitionOrder(actor, transitionInput, createOrderTransactionDependencies(db, transaction));
        });

        return res.status(200).json({ success: true, order: transitionResult.order, event: transitionResult.event });
      } catch (err: any) {
        if (err instanceof OrderServiceError) {
          return res.status(err.status).json({ success: false, code: err.code, message: err.message });
        }
        console.error('Transition Error:', err);
        return res.status(400).json({ success: false, code: err.code || 'TRANSITION_FAILED', message: err.message });
      }
    }

    // ── Order Creation Flow ──
    const createInput: CreateOrderInput = {
      items: body.items,
      shippingInfo: body.shippingInfo,
      paymentMethod: body.paymentMethod,
      discountCode: body.discountCode,
      pointsToUse: body.pointsToUse,
      idempotencyKey: body.idempotencyKey,
    };

    try {
      const result = await db.runTransaction(async (transaction) => {
        return createOrder(actor, createInput, createOrderTransactionDependencies(db, transaction));
      });

      // Dispatch Telegram notification asynchronously on server side for fresh orders
      if (!result.isReplay) {
        notifyTelegramNewOrder(result.order).catch((err) =>
          console.error('Failed to notify telegram:', err)
        );
      }

      return res.status(201).json({
        success: true,
        order: result.order,
        isReplay: result.isReplay,
      });
    } catch (err: any) {
      if (err instanceof OrderServiceError) {
        return res.status(err.status).json({
          success: false,
          code: err.code,
          message: err.message,
        });
      }
      console.error('Order Creation Error:', err);
      return res.status(400).json({
        success: false,
        code: err.code || 'CREATION_FAILED',
        message: err.message || 'Không thể tạo đơn hàng.',
      });
    }
  }

  return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED', message: 'Method Not Allowed' });
}
