import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getAdminDb, admin } from './_lib/firebaseAdmin.js';
import { createOrderTransactionDependencies } from './_lib/orderTransaction.js';
import { OrderServiceError, transitionOrder } from '../src/order/orderService.js';
import type {
  AuthenticatedActor,
  TransitionOrderInput,
} from '../src/order/orderService.js';

const telegramActor: AuthenticatedActor = {
  uid: 'telegram:internal',
  email: 'telegram-internal',
  role: 'admin',
  permissions: { manageOrders: true },
};

const MAX_TELEGRAM_INPUT_LENGTH = 2000;
const MAX_ADMIN_NOTE_LENGTH = 500;
const MAX_REVIEW_REPLY_LENGTH = 1000;
const MAX_TRACKING_CODE_LENGTH = 200;

/** Escape dynamic values before placing them in Telegram HTML messages. */
export function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function getHeaderValue(req: VercelRequest, name: string): string {
  const value = req.headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] || '' : value || '';
}

function getQueryValue(value: string | string[] | undefined): string {
  return Array.isArray(value) ? value[0] || '' : value || '';
}

function getTelegramChatId(update: any): string | null {
  const chatId = update?.message?.chat?.id ?? update?.callback_query?.message?.chat?.id;
  return chatId === undefined || chatId === null ? null : String(chatId);
}

function getTelegramSenderId(update: any): string | null {
  const senderId = update?.message?.from?.id ?? update?.callback_query?.from?.id;
  return senderId === undefined || senderId === null ? null : String(senderId);
}

function isAllowedTelegramUpdate(update: any): boolean {
  const configuredChatId = process.env.TELEGRAM_CHAT_ID?.trim();
  const chatId = getTelegramChatId(update);
  if (!configuredChatId || !chatId || chatId !== configuredChatId) return false;

  const allowedUserIds = (process.env.TELEGRAM_ALLOWED_USER_IDS || '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
  if (allowedUserIds.length === 0) return true;

  const senderId = getTelegramSenderId(update);
  return Boolean(senderId && allowedUserIds.includes(senderId));
}

function isWebhookSecretValid(req: VercelRequest): boolean {
  const configuredSecret = process.env.TELEGRAM_WEBHOOK_SECRET?.trim();
  if (!configuredSecret) {
    // Keep local development usable, but never allow an unsecreted webhook in
    // a deployed production environment.
    return process.env.NODE_ENV !== 'production' && process.env.VERCEL_ENV !== 'production';
  }
  return getHeaderValue(req, 'x-telegram-bot-api-secret-token') === configuredSecret;
}

/**
 * Execute an internal Telegram order command through the same domain service
 * and transaction boundary as the authenticated HTTP API.
 */
async function runTelegramOrderCommand(
  db: FirebaseFirestore.Firestore,
  input: TransitionOrderInput
) {
  return db.runTransaction(async (transaction) => {
    return transitionOrder(telegramActor, input, createOrderTransactionDependencies(db, transaction));
  });
}

// ─── Helper: Gọi Telegram API ───
async function tg(method: string, body: any) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  return fetch(`https://api.telegram.org/bot${botToken}/${method}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

// ─── Helper: Build trạng thái VN ───
function statusVN(status: string) {
  const map: Record<string, string> = {
    pending: 'Chờ xử lý', suspicious: '⚠ Nghi ngờ', processing: 'Đang chuẩn bị',
    shipped: 'Đang giao', delivered: 'Hoàn tất', cancelled: 'Đã hủy',
    returned: 'Đã hoàn', refunded: 'Đã hoàn tiền', failed_delivery: 'Giao thất bại'
  };
  return map[status] || status;
}

// ─── Helper: Build inline buttons dựa trên trạng thái hiện tại ───
function buildOrderButtons(orderId: string, status: string, paymentStatus: string, paymentMethod: string) {
  const btns: any[][] = [];
  // Nút thanh toán
  if (paymentStatus !== 'paid') {
    btns.push([{ text: paymentMethod === 'vietqr' ? '✅ Đã nhận tiền' : '💰 Đã thu COD', callback_data: `action:paid:${orderId}` }]);
  }
  // Nút chuyển trạng thái (chỉ hiện nếu hợp lệ)
  if (['pending', 'suspicious'].includes(status)) {
    btns.push([{ text: '🔧 Đang chuẩn bị', callback_data: `action:processing:${orderId}` }]);
  }
  if (['pending', 'suspicious', 'processing'].includes(status)) {
    btns.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${orderId}` }]);
  }
  if (status === 'shipped') {
    btns.push([{ text: '✅ Đã giao thành công', callback_data: `action:delivered:${orderId}` }]);
  }
  if (!['cancelled', 'delivered', 'refunded'].includes(status)) {
    btns.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${orderId}` }]);
  }
  return btns;
}

// ─── Helper: Build chi tiết đơn hàng (dùng chung cho /don và tra cứu lại) ───
function buildOrderMessage(orderId: string, order: any, title: string) {
  let msg = `${title}\n`;
  msg += `Mã đơn: <b>#${escapeHtml(orderId)}</b>\n`;
  msg += `Trạng thái: <b>${escapeHtml(statusVN(order.status))}</b>\n`;
  msg += `Thanh toán: <b>${order.paymentStatus === 'paid' ? 'Đã thu tiền ✅' : 'Chờ gạch nợ ⏳'}</b>\n`;
  msg += `Người nhận: ${escapeHtml(order.shippingInfo?.fullName || 'N/A')}\n`;
  msg += `SĐT: <code>${escapeHtml(order.shippingInfo?.phone || 'N/A')}</code>\n`;
  msg += `Địa chỉ: ${escapeHtml(order.shippingInfo?.address || 'N/A')}\n`;
  if (order.shippingInfo?.notes) msg += `Ghi chú: <i>${escapeHtml(order.shippingInfo.notes)}</i>\n`;
  if (order.trackingCode) msg += `Mã vận đơn: <code>${escapeHtml(order.trackingCode)}</code>\n`;
  if (order.adminNotes) msg += `📝 Ghi chú Admin: <b>${escapeHtml(order.adminNotes)}</b>\n`;
  msg += `─────────────────────\n`;
  if (order.items?.length > 0) {
    order.items.forEach((item: any) => {
      const itemPrice = Number(item.price ?? item.unitPrice ?? 0).toLocaleString('vi-VN');
      msg += `- ${escapeHtml(item.quantity)} x ${escapeHtml(item.name)} (${itemPrice}đ)\n`;
    });
    msg += `─────────────────────\n`;
  }
  const finalAm = Number(order.finalAmount || order.totalAmount || 0);
  msg += `Số tiền: <b>${finalAm.toLocaleString('vi-VN')} đ</b>\n`;
  msg += `Phương thức: <b>${order.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;
  return msg;
}

// ═══════════════════════════════════════════════
// MAIN HANDLER
// ═══════════════════════════════════════════════
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;

  // ─── Setup Webhook (GET đặc biệt) ───
  if (req.method === 'GET' && req.query.setup === 'true') {
    const setupSecret = process.env.TELEGRAM_SETUP_SECRET?.trim() || process.env.TELEGRAM_WEBHOOK_SECRET?.trim();
    const suppliedSecret = getQueryValue(req.query.secret);
    const webhookSecret = process.env.TELEGRAM_WEBHOOK_SECRET?.trim();
    if (!setupSecret || suppliedSecret !== setupSecret) {
      return res.status(403).json({ error: 'Forbidden', code: 'TELEGRAM_SETUP_SECRET_REQUIRED' });
    }
    if (!botToken || !webhookSecret) {
      return res.status(503).json({ error: 'Telegram webhook secrets are not configured.' });
    }

    const url = `https://${req.headers.host}/api/telegram-webhook`;
    try {
      const response = await fetch(`https://api.telegram.org/bot${botToken}/setWebhook`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url, secret_token: webhookSecret }),
      });
      const data = await response.json();
      const telegramOk = response.ok && data?.ok === true;
      return res.status(telegramOk ? 200 : 502).json({
        success: telegramOk,
        message: telegramOk ? 'Đã kích hoạt chế độ bắt nút Telegram' : 'Telegram từ chối đăng ký webhook',
        data,
      });
    } catch (e: any) {
      return res.status(502).json({ error: 'Không thể đăng ký Telegram webhook.' });
    }
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  if (!botToken) {
    return res.status(503).json({ error: 'Telegram bot is not configured.' });
  }
  if (!isWebhookSecretValid(req)) {
    return res.status(403).json({ error: 'Forbidden', code: 'INVALID_TELEGRAM_WEBHOOK_SECRET' });
  }

  try {
    const update = req.body;
    if (!update || typeof update !== 'object') {
      return res.status(400).json({ error: 'Invalid Telegram update.' });
    }
    if (!isAllowedTelegramUpdate(update)) {
      return res.status(403).json({ error: 'Forbidden', code: 'TELEGRAM_ACTOR_NOT_ALLOWED' });
    }

    const db = getAdminDb();
    let callbackIdempotencyReplay = false;

    // ═══════════════════════════════════════════════
    // XỬ LÝ TIN NHẮN TEXT
    // ═══════════════════════════════════════════════
    if (update.message?.text) {
      const text = update.message.text.trim();
      const chatId = update.message.chat.id;
      if (text.length === 0 || text.length > MAX_TELEGRAM_INPUT_LENGTH) {
        return res.status(200).json({ success: false, code: 'TELEGRAM_INPUT_TOO_LONG' });
      }

      // ─── Reply tin nhắn để ghi chú Admin ───
      if (update.message.reply_to_message?.text) {
        const replyText = update.message.reply_to_message.text;
        const noteMatch = replyText.match(/Mã đơn:\s*#([A-Za-z0-9]+)/);
        if (noteMatch) {
          if (text.length > MAX_ADMIN_NOTE_LENGTH) {
            await tg('sendMessage', {
              chat_id: chatId,
              text: `❌ Ghi chú Admin tối đa ${MAX_ADMIN_NOTE_LENGTH} ký tự.`,
              reply_to_message_id: update.message.message_id,
            });
            return res.status(200).json({ success: false, code: 'ADMIN_NOTE_TOO_LONG' });
          }
          const orderId = noteMatch[1].toUpperCase();
          const orderRef = db.collection('orders').doc(orderId);
          try {
            const orderSnap = await orderRef.get();
            if (orderSnap.exists) {
              const prevNotes = orderSnap.data()?.adminNotes ? orderSnap.data()!.adminNotes + '\n' : '';
              const nextNotes = prevNotes + `- ${text}`;
              if (nextNotes.length > MAX_ADMIN_NOTE_LENGTH) {
                await tg('sendMessage', {
                  chat_id: chatId,
                  text: `❌ Tổng ghi chú Admin tối đa ${MAX_ADMIN_NOTE_LENGTH} ký tự.`,
                  reply_to_message_id: update.message.message_id,
                });
                return res.status(200).json({ success: false, code: 'ADMIN_NOTES_TOO_LONG' });
              }
              await runTelegramOrderCommand(db, {
                orderId,
                actionType: 'update_order_metadata',
                idempotencyKey: `tg_note_${chatId}_${update.message.message_id}`,
                metadata: { adminNotes: nextNotes },
              });
              await tg('sendMessage', {
                chat_id: chatId,
                text: `✅ Đã lưu ghi chú cho đơn <b>#${orderId}</b>`,
                reply_to_message_id: update.message.message_id,
                parse_mode: 'HTML'
              });
            }
          } catch (e) {
            console.error('Error saving admin note:', e);
          }
          return res.status(200).json({ success: true });
        }
      }

      // ─── Lệnh /don hoặc /order — Tra cứu đơn hàng ───
      const orderMatch = text.match(/^\/(?:don|order)(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]{1,64})$/i);
      if (orderMatch) {
        const orderId = orderMatch[1].toUpperCase();
        const orderSnap = await db.collection('orders').doc(orderId).get();

        if (!orderSnap.exists) {
          await tg('sendMessage', { chat_id: chatId, text: `❌ Không tìm thấy đơn hàng mã #${orderId}` });
        } else {
          const order = orderSnap.data()!;
          const msg = buildOrderMessage(orderId, order, '🔎 <b>TRA CỨU ĐƠN HÀNG</b> 🔎');
          const buttons = buildOrderButtons(orderId, order.status, order.paymentStatus || 'pending', order.paymentMethod || 'cod');
          await tg('sendMessage', {
            chat_id: chatId, text: msg, parse_mode: 'HTML',
            reply_markup: buttons.length > 0 ? { inline_keyboard: buttons } : undefined
          });
        }
        return res.status(200).json({ success: true });
      }

      // ─── Lệnh /tracking — Thêm mã vận đơn ───
      const trackingMatch = text.match(/^\/tracking(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]{1,64})\s+(.+)$/i);
      if (trackingMatch) {
        const orderId = trackingMatch[1].toUpperCase();
        let trackingCode = trackingMatch[2].trim();

        // Auto-parse SPX link
        if (trackingCode.includes('spx.vn/track?')) {
          trackingCode = trackingCode.split('spx.vn/track?')[1].split('&')[0];
        } else if (trackingCode.startsWith('http')) {
          const spxMatch = trackingCode.match(/(SPX[A-Z0-9]+)/i);
          if (spxMatch) trackingCode = spxMatch[1];
        }
        if (trackingCode.length === 0 || trackingCode.length > MAX_TRACKING_CODE_LENGTH) {
          await tg('sendMessage', {
            chat_id: chatId,
            text: `❌ Mã vận đơn tối đa ${MAX_TRACKING_CODE_LENGTH} ký tự.`,
          });
          return res.status(200).json({ success: false, code: 'TRACKING_CODE_TOO_LONG' });
        }

        const orderSnap = await db.collection('orders').doc(orderId).get();
        if (!orderSnap.exists) {
          await tg('sendMessage', { chat_id: chatId, text: `❌ Không tìm thấy đơn #${orderId}` });
        } else {
          await runTelegramOrderCommand(db, {
            orderId,
            actionType: 'update_order_metadata',
            idempotencyKey: `tg_tracking_${chatId}_${update.message.message_id}`,
            metadata: { trackingCode },
          });
          await tg('sendMessage', {
            chat_id: chatId, parse_mode: 'HTML',
            text: `✅ Đã lưu mã vận đơn cho <b>#${escapeHtml(orderId)}</b>\n📦 MVĐ: <code>${escapeHtml(trackingCode)}</code>`
          });
        }
        return res.status(200).json({ success: true });
      }

      // ─── Lệnh /thongke — Thống kê nhanh hôm nay ───
      const statsMatch = text.match(/^\/thongke(?:@[A-Za-z0-9_]+)?$/i);
      if (statsMatch) {
        const now = new Date();
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        const ordersSnap = await db.collection('orders')
          .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
          .get();

        let totalRevenue = 0;
        let pendingCount = 0;
        let shippedCount = 0;
        let deliveredCount = 0;
        let cancelledCount = 0;
        let codCount = 0;
        let qrCount = 0;
        let unpaidQR = 0;

        ordersSnap.docs.forEach(d => {
          const o = d.data();
          const amount = o.finalAmount || o.totalAmount || 0;
          if (!['cancelled', 'refunded'].includes(o.status)) totalRevenue += amount;
          if (['pending', 'suspicious', 'processing'].includes(o.status)) pendingCount++;
          if (o.status === 'shipped') shippedCount++;
          if (o.status === 'delivered') deliveredCount++;
          if (o.status === 'cancelled') cancelledCount++;
          if (o.paymentMethod === 'cod') codCount++;
          if (o.paymentMethod === 'vietqr') {
            qrCount++;
            if (o.paymentStatus !== 'paid') unpaidQR++;
          }
        });

        let msg = `📊 <b>THỐNG KÊ HÔM NAY</b> (${now.toLocaleDateString('vi-VN')})\n`;
        msg += `─────────────────────\n`;
        msg += `📦 Tổng đơn: <b>${ordersSnap.size}</b>\n`;
        msg += `💰 Doanh thu: <b>${totalRevenue.toLocaleString('vi-VN')} đ</b>\n`;
        msg += `─────────────────────\n`;
        msg += `⏳ Chờ xử lý: <b>${pendingCount}</b>\n`;
        msg += `🚚 Đang giao: <b>${shippedCount}</b>\n`;
        msg += `✅ Hoàn tất: <b>${deliveredCount}</b>\n`;
        msg += `❌ Đã hủy: <b>${cancelledCount}</b>\n`;
        msg += `─────────────────────\n`;
        msg += `💵 COD: ${codCount} | 📱 QR: ${qrCount}\n`;
        if (unpaidQR > 0) msg += `⚠️ QR chưa thanh toán: <b>${unpaidQR}</b>\n`;

        await tg('sendMessage', { chat_id: chatId, text: msg, parse_mode: 'HTML' });
        return res.status(200).json({ success: true });
      }

      // ─── Lệnh /reply — Phản hồi đánh giá sản phẩm ───
      const replyMatch = text.match(/^\/reply(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]{1,150})\s+(.+)$/is);
      if (replyMatch) {
        const reviewId = replyMatch[1];
        const replyContent = replyMatch[2].trim();
        if (replyContent.length > MAX_REVIEW_REPLY_LENGTH) {
          await tg('sendMessage', {
            chat_id: chatId,
            text: `❌ Phản hồi đánh giá tối đa ${MAX_REVIEW_REPLY_LENGTH} ký tự.`,
          });
          return res.status(200).json({ success: false, code: 'REVIEW_REPLY_TOO_LONG' });
        }
        const reviewRef = db.collection('reviews').doc(reviewId);
        const reviewSnap = await reviewRef.get();

        if (!reviewSnap.exists) {
          await tg('sendMessage', { chat_id: chatId, text: `❌ Không tìm thấy đánh giá ID: ${reviewId}` });
        } else {
          await reviewRef.update({
            adminReply: replyContent,
            adminReplyAt: admin.firestore.FieldValue.serverTimestamp()
          });
          const reviewData = reviewSnap.data()!;
          await tg('sendMessage', {
            chat_id: chatId, parse_mode: 'HTML',
            text: `✅ Đã phản hồi đánh giá!\n📝 SP: ${escapeHtml(reviewData.productId)}\n⭐ ${escapeHtml(reviewData.rating)}/5 — ${escapeHtml(reviewData.userName)}\n💬 Phản hồi: <i>"${escapeHtml(replyContent)}"</i>`
          });
        }
        return res.status(200).json({ success: true });
      }
    }

    // ═══════════════════════════════════════════════
    // XỬ LÝ CALLBACK QUERY (Bấm nút Inline)
    // ═══════════════════════════════════════════════
    if (update.callback_query) {
      const cq = update.callback_query;
      const data = cq.data;

      if (data?.startsWith('action:')) {
        const parts = data.split(':');
        if (parts.length !== 3 || !/^[A-Za-z0-9]{1,64}$/.test(parts[2])) {
          await tg('answerCallbackQuery', {
            callback_query_id: cq.id,
            text: 'Callback không hợp lệ.',
            show_alert: true,
          });
          return res.status(200).json({ success: false, code: 'INVALID_CALLBACK_DATA' });
        }
        const actionType = parts[1];
        const orderId = parts[2];

        const orderRef = db.collection('orders').doc(orderId);
        const callbackIdempotencyKey = `tg_cq_${cq.id}`;
        const callbackIdempotencyRecordId =
          `idem_${telegramActor.uid}_transition_${callbackIdempotencyKey}`;

        try {
          const orderSnap = await orderRef.get();

          if (!orderSnap.exists) {
            await tg('answerCallbackQuery', { callback_query_id: cq.id, text: 'Lỗi: Không tìm thấy đơn hàng!', show_alert: true });
            return res.status(200).json({ success: true });
          }

          const order = orderSnap.data()!;
          // Telegram may retry the same callback update after a timeout. Read
          // the completed command snapshot before building the command so a
          // sequential retry still reaches the domain idempotency guard even
          // after the order has already moved to its target state.
          const callbackIdempotencySnapshot = await db
            .collection('idempotency')
            .doc(callbackIdempotencyRecordId)
            .get();
          const isCompletedCallbackReplay =
            callbackIdempotencySnapshot.exists &&
            callbackIdempotencySnapshot.data()?.status === 'succeeded';
          let transitionInput: TransitionOrderInput | null = null;
          let actionLabel = '';
          let statusFootnote = '';

          // ─── Build a domain command; all order mutations happen in the service ───
          if (actionType === 'paid') {
            if (order.paymentStatus === 'paid' && !isCompletedCallbackReplay) {
              actionLabel = 'Tiền đã được nhận từ trước!';
            } else {
              transitionInput = {
                orderId,
                targetStatus: order.status === 'pending' ? 'processing' : order.status,
                actionType: 'confirm_payment',
                paymentStatus: 'paid',
              };
              actionLabel = '✅ Đã gạch nợ thành công!';
              statusFootnote = '✅ ĐÃ XÁC NHẬN NHẬN TIỀN';
            }

          } else if (actionType === 'processing') {
            if (order.status === 'processing' && !isCompletedCallbackReplay) {
              actionLabel = 'Đơn này đã ở trạng thái Đang chuẩn bị!';
            } else {
              transitionInput = { orderId, targetStatus: 'processing', actionType: 'start_processing' };
              actionLabel = '🔧 Cập nhật thành ĐANG CHUẨN BỊ!';
              statusFootnote = '🔧 ĐANG CHUẨN BỊ HÀNG';
            }

          } else if (actionType === 'shipped') {
            if (order.status === 'shipped' && !isCompletedCallbackReplay) {
              actionLabel = 'Đơn này vốn đã đang giao!';
            } else {
              transitionInput = { orderId, targetStatus: 'shipped', actionType: 'ship_order' };
              actionLabel = '🚚 Cập nhật thành ĐANG GIAO!';
              statusFootnote = '🚚 ĐANG GIAO HÀNG';
            }

          } else if (actionType === 'delivered') {
            if (order.status === 'delivered' && !isCompletedCallbackReplay) {
              actionLabel = 'Đơn này đã hoàn tất từ trước!';
            } else {
              transitionInput = {
                orderId,
                targetStatus: 'delivered',
                actionType: 'mark_delivered',
                paymentStatus: 'paid',
              };
              const points = order.earnedPoints || 0;
              actionLabel = `✅ Đã giao thành công! Cộng ${points} điểm cho khách.`;
              statusFootnote = `✅ ĐÃ GIAO THÀNH CÔNG (+${points} điểm)`;
            }

          } else if (actionType === 'cancelled') {
            if (order.status === 'cancelled' && !isCompletedCallbackReplay) {
              actionLabel = 'Đơn này đã được HỦY từ trước!';
            } else {
              transitionInput = {
                orderId,
                targetStatus: 'cancelled',
                actionType: 'cancel_order',
                cancelReason: 'telegram_admin',
              };
              actionLabel = '❌ Đã HỦY đơn + hoàn kho thành công!';
              statusFootnote = '❌ ĐÃ HỦY ĐƠN (Kho đã hoàn)';
            }
          } else {
            throw new OrderServiceError('Loại thao tác Telegram không hợp lệ.', 'UNKNOWN_TELEGRAM_ACTION', 400);
          }

          if (transitionInput) {
            transitionInput = {
              ...transitionInput,
              idempotencyKey: callbackIdempotencyKey,
            };
          }

          const transitionResult = transitionInput
            ? await runTelegramOrderCommand(db, transitionInput)
            : null;
          callbackIdempotencyReplay = Boolean(isCompletedCallbackReplay && transitionResult);
          const updatedOrder = transitionResult?.order || order;

          // Trả lời callback
          await tg('answerCallbackQuery', { callback_query_id: cq.id, text: actionLabel, show_alert: true });

          // Cập nhật tin nhắn — rebuild toàn bộ để giữ format HTML
          if (statusFootnote) {
            const newMsg = buildOrderMessage(orderId, updatedOrder, '🔔 <b>CẬP NHẬT ĐƠN HÀNG</b>');
            const newButtons = buildOrderButtons(orderId, updatedOrder.status, updatedOrder.paymentStatus || 'pending', updatedOrder.paymentMethod || 'cod');

            if (cq.message?.chat?.id === undefined || cq.message?.message_id === undefined) {
              throw new OrderServiceError('Callback không có message đích hợp lệ.', 'INVALID_CALLBACK_MESSAGE', 400);
            }
            await tg('editMessageText', {
              chat_id: cq.message.chat.id,
              message_id: cq.message.message_id,
              text: newMsg + '\n' + statusFootnote,
              parse_mode: 'HTML',
              reply_markup: newButtons.length > 0 ? { inline_keyboard: newButtons } : { inline_keyboard: [] }
            });
          }

        } catch (dbError) {
          console.error('Order command error:', dbError);
          const message = dbError instanceof OrderServiceError
            ? dbError.message
            : 'Lỗi: Không thể cập nhật đơn hàng';
          await tg('answerCallbackQuery', { callback_query_id: cq.id, text: message, show_alert: true });
        }
      }
    }

    return res.status(200).json({
      success: true,
      ...(update.callback_query ? { idempotencyReplay: callbackIdempotencyReplay } : {}),
    });

  } catch (error) {
    console.error('Telegram Webhook Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
