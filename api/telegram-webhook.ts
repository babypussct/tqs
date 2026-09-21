import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import {
  AuthenticatedActor,
  OrderServiceDependencies,
  OrderServiceError,
  TransitionOrderInput,
  transitionOrder,
} from '../src/order/orderService';
import { IdempotencyRecord, OrderDocument } from '../src/order/canonical';

// Khởi tạo Firebase Admin an toàn
if (!admin.apps.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    } else {
      let pk = process.env.FIREBASE_PRIVATE_KEY || '';
      if (pk.startsWith('"') && pk.endsWith('"')) pk = pk.slice(1, -1);
      pk = pk.replace(/\\n/g, '\n');

      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: pk,
        })
      });
    }
  } catch (error) {
    console.error('Firebase Admin Init Error:', error);
  }
}

// ─── Helper: Lấy Firestore instance ───
function getDb() {
  const dbId = process.env.FIREBASE_DATABASE_ID || 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b';
  return getFirestore(admin.app(), dbId);
}

const telegramActor: AuthenticatedActor = {
  uid: 'telegram:internal',
  email: 'telegram-internal',
  role: 'admin',
  permissions: { manageOrders: true },
};

/**
 * Execute an internal Telegram order command through the same domain service
 * and transaction boundary as the authenticated HTTP API.
 */
async function runTelegramOrderCommand(
  db: FirebaseFirestore.Firestore,
  input: TransitionOrderInput
) {
  return db.runTransaction(async (transaction) => {
    const deps: OrderServiceDependencies = {
      getOrder: async (id) => {
        const snap = await transaction.get(db.collection('orders').doc(id));
        return snap.exists ? (snap.data() as OrderDocument) : null;
      },
      updateOrder: async (id, updates) => {
        transaction.update(db.collection('orders').doc(id), updates);
      },
      saveOrder: async (order) => {
        transaction.set(db.collection('orders').doc(order.id), order);
      },
      getProduct: async (id) => {
        const snap = await transaction.get(db.collection('products').doc(id));
        return snap.exists ? { id: snap.id, ...snap.data() } : null;
      },
      updateProductStock: async (id, stock) => {
        transaction.update(db.collection('products').doc(id), { stock });
      },
      getUserProfile: async (uid) => {
        const snap = await transaction.get(db.collection('users').doc(uid));
        return snap.exists ? { id: snap.id, ...snap.data() } : null;
      },
      updateUserPoints: async (uid, delta) => {
        transaction.update(db.collection('users').doc(uid), { points: FieldValue.increment(delta) });
      },
      updateUserRewardStats: async (uid, update) => {
        const statsUpdate: Record<string, unknown> = {};
        if (update.pointsDelta !== undefined) statsUpdate.points = FieldValue.increment(update.pointsDelta);
        if (update.totalSpentDelta !== undefined) statsUpdate.totalSpent = FieldValue.increment(update.totalSpentDelta);
        if (update.totalOrdersDelta !== undefined) statsUpdate.totalOrders = FieldValue.increment(update.totalOrdersDelta);
        if (update.rewardReversalDebtDelta !== undefined) {
          statsUpdate.rewardReversalDebt = FieldValue.increment(update.rewardReversalDebtDelta);
        }
        if (update.tier !== undefined) statsUpdate.tier = update.tier;
        if (Object.keys(statsUpdate).length > 0) {
          transaction.update(db.collection('users').doc(uid), statsUpdate);
        }
      },
      getTiersConfig: async () => {
        const snap = await transaction.get(db.collection('system_settings').doc('tiers_config'));
        return snap.exists ? snap.data() : null;
      },
      getVoucher: async (code) => {
        const directSnap = await transaction.get(db.collection('discountCodes').doc(code));
        if (directSnap.exists) return { id: directSnap.id, ...directSnap.data() };
        const querySnap = await transaction.get(
          db.collection('discountCodes').where('code', '==', code).limit(1)
        );
        return querySnap.empty ? null : { id: querySnap.docs[0].id, ...querySnap.docs[0].data() };
      },
      incrementVoucherUsage: async (id) => {
        transaction.update(db.collection('discountCodes').doc(id), {
          usedCount: FieldValue.increment(1),
        });
      },
      decrementVoucherUsage: async (id) => {
        transaction.update(db.collection('discountCodes').doc(id), {
          usedCount: FieldValue.increment(-1),
        });
      },
      saveEvent: async (orderId, event) => {
        transaction.set(db.collection('orders').doc(orderId).collection('events').doc(event.id), event);
      },
      getIdempotencyRecord: async (id) => {
        const snap = await transaction.get(db.collection('idempotency').doc(id));
        return snap.exists ? (snap.data() as IdempotencyRecord) : null;
      },
      saveIdempotencyRecord: async (record) => {
        transaction.set(db.collection('idempotency').doc(record.id), record);
      },
    };

    return transitionOrder(telegramActor, input, deps);
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
  msg += `Mã đơn: <b>#${orderId}</b>\n`;
  msg += `Trạng thái: <b>${statusVN(order.status)}</b>\n`;
  msg += `Thanh toán: <b>${order.paymentStatus === 'paid' ? 'Đã thu tiền ✅' : 'Chờ gạch nợ ⏳'}</b>\n`;
  msg += `Người nhận: ${order.shippingInfo?.fullName || 'N/A'}\n`;
  msg += `SĐT: <code>${order.shippingInfo?.phone || 'N/A'}</code>\n`;
  msg += `Địa chỉ: ${order.shippingInfo?.address || 'N/A'}\n`;
  if (order.shippingInfo?.notes) msg += `Ghi chú: <i>${order.shippingInfo.notes}</i>\n`;
  if (order.trackingCode) msg += `Mã vận đơn: <code>${order.trackingCode}</code>\n`;
  if (order.adminNotes) msg += `📝 Ghi chú Admin: <b>${order.adminNotes}</b>\n`;
  msg += `─────────────────────\n`;
  if (order.items?.length > 0) {
    order.items.forEach((item: any) => {
      msg += `- ${item.quantity} x ${item.name} (${item.price?.toLocaleString('vi-VN')}đ)\n`;
    });
    msg += `─────────────────────\n`;
  }
  const finalAm = order.finalAmount || order.totalAmount || 0;
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
    const url = `https://${req.headers.host}/api/telegram-webhook`;
    try {
      const response = await fetch(`https://api.telegram.org/bot${botToken}/setWebhook?url=${url}`);
      const data = await response.json();
      return res.status(200).json({ success: true, message: 'Đã kích hoạt chế độ bắt nút Telegram', data });
    } catch (e: any) {
      return res.status(500).json({ error: e.message });
    }
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const update = req.body;
    const db = getDb();

    // ═══════════════════════════════════════════════
    // XỬ LÝ TIN NHẮN TEXT
    // ═══════════════════════════════════════════════
    if (update.message?.text) {
      const text = update.message.text.trim();
      const chatId = update.message.chat.id;

      // ─── Reply tin nhắn để ghi chú Admin ───
      if (update.message.reply_to_message?.text) {
        const replyText = update.message.reply_to_message.text;
        const noteMatch = replyText.match(/Mã đơn:\s*#([A-Za-z0-9]+)/);
        if (noteMatch) {
          const orderId = noteMatch[1].toUpperCase();
          const orderRef = db.collection('orders').doc(orderId);
          try {
            const orderSnap = await orderRef.get();
            if (orderSnap.exists) {
              const prevNotes = orderSnap.data()?.adminNotes ? orderSnap.data()!.adminNotes + '\n' : '';
              await runTelegramOrderCommand(db, {
                orderId,
                actionType: 'update_order_metadata',
                metadata: { adminNotes: prevNotes + `- ${text}` },
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
      const orderMatch = text.match(/^\/(?:don|order)(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]+)/i);
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
      const trackingMatch = text.match(/^\/tracking(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]+)\s+(.+)/i);
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

        const orderSnap = await db.collection('orders').doc(orderId).get();
        if (!orderSnap.exists) {
          await tg('sendMessage', { chat_id: chatId, text: `❌ Không tìm thấy đơn #${orderId}` });
        } else {
          await runTelegramOrderCommand(db, {
            orderId,
            actionType: 'update_order_metadata',
            metadata: { trackingCode },
          });
          await tg('sendMessage', {
            chat_id: chatId, parse_mode: 'HTML',
            text: `✅ Đã lưu mã vận đơn cho <b>#${orderId}</b>\n📦 MVĐ: <code>${trackingCode}</code>`
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
      const replyMatch = text.match(/^\/reply(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]+)\s+(.+)/is);
      if (replyMatch) {
        const reviewId = replyMatch[1];
        const replyContent = replyMatch[2].trim();
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
            text: `✅ Đã phản hồi đánh giá!\n📝 SP: ${reviewData.productId}\n⭐ ${reviewData.rating}/5 — ${reviewData.userName}\n💬 Phản hồi: <i>"${replyContent}"</i>`
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
        const actionType = parts[1];
        const orderId = parts[2];

        const orderRef = db.collection('orders').doc(orderId);

        try {
          const orderSnap = await orderRef.get();

          if (!orderSnap.exists) {
            await tg('answerCallbackQuery', { callback_query_id: cq.id, text: 'Lỗi: Không tìm thấy đơn hàng!', show_alert: true });
            return res.status(200).json({ success: true });
          }

          const order = orderSnap.data()!;
          let transitionInput: TransitionOrderInput | null = null;
          let actionLabel = '';
          let statusFootnote = '';

          // ─── Build a domain command; all order mutations happen in the service ───
          if (actionType === 'paid') {
            if (order.paymentStatus === 'paid') {
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
            if (order.status === 'processing') {
              actionLabel = 'Đơn này đã ở trạng thái Đang chuẩn bị!';
            } else {
              transitionInput = { orderId, targetStatus: 'processing', actionType: 'start_processing' };
              actionLabel = '🔧 Cập nhật thành ĐANG CHUẨN BỊ!';
              statusFootnote = '🔧 ĐANG CHUẨN BỊ HÀNG';
            }

          } else if (actionType === 'shipped') {
            if (order.status === 'shipped') {
              actionLabel = 'Đơn này vốn đã đang giao!';
            } else {
              transitionInput = { orderId, targetStatus: 'shipped', actionType: 'ship_order' };
              actionLabel = '🚚 Cập nhật thành ĐANG GIAO!';
              statusFootnote = '🚚 ĐANG GIAO HÀNG';
            }

          } else if (actionType === 'delivered') {
            if (order.status === 'delivered') {
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
            if (order.status === 'cancelled') {
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

          const transitionResult = transitionInput
            ? await runTelegramOrderCommand(db, transitionInput)
            : null;
          const updatedOrder = transitionResult?.order || order;

          // Trả lời callback
          await tg('answerCallbackQuery', { callback_query_id: cq.id, text: actionLabel, show_alert: true });

          // Cập nhật tin nhắn — rebuild toàn bộ để giữ format HTML
          if (statusFootnote) {
            const newMsg = buildOrderMessage(orderId, updatedOrder, '🔔 <b>CẬP NHẬT ĐƠN HÀNG</b>');
            const newButtons = buildOrderButtons(orderId, updatedOrder.status, updatedOrder.paymentStatus || 'pending', updatedOrder.paymentMethod || 'cod');

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

    return res.status(200).json({ success: true });

  } catch (error) {
    console.error('Telegram Webhook Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
