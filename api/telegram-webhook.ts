import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

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

// ─── Helper: Gọi Telegram API ───
async function tg(method: string, body: any) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  return fetch(`https://api.telegram.org/bot${botToken}/${method}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
}

// ─── Helper: Hoàn stock khi hủy đơn ───
async function restoreStock(db: FirebaseFirestore.Firestore, items: any[]) {
  const batch = db.batch();
  for (const item of items) {
    if (item.productId && item.quantity) {
      const productRef = db.collection('products').doc(item.productId);
      batch.update(productRef, { stock: FieldValue.increment(item.quantity) });
    }
  }
  await batch.commit();
}

// ─── Helper: Cộng điểm thưởng khi giao thành công ───
async function awardPoints(db: FirebaseFirestore.Firestore, orderId: string, orderData: any) {
  const userId = orderData.userId;
  if (!userId) return 0;

  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return 0;

  const userData = userSnap.data()!;
  const amount = orderData.finalAmount || orderData.totalAmount || 0;
  const currentSpent = userData.totalSpent || 0;
  const currentOrders = userData.totalOrders || 0;
  const newSpent = currentSpent + amount;
  const newOrders = currentOrders + 1;

  // Đọc config tiers
  const configSnap = await db.collection('system_settings').doc('tiers_config').get();
  let pointsEarned = 0;
  let newTier = userData.tier || 'bronze';

  if (configSnap.exists) {
    const config = configSnap.data()!;
    if (config.isActive) {
      const currentTierKey = userData.tier || 'bronze';
      const currentTierConfig = config.tiers?.[currentTierKey] || config.tiers?.['bronze'];
      const multiplier = currentTierConfig?.pointMultiplier || 0.01;
      const pointValueVND = config.pointValueVND || 1000;
      pointsEarned = Math.floor((amount * multiplier) / pointValueVND);

      const sortedTiers = Object.values(config.tiers || {}).sort((a: any, b: any) => b.minSpent - a.minSpent);
      for (const tier of sortedTiers as any[]) {
        if (newSpent >= tier.minSpent) { newTier = tier.tierId; break; }
      }
    } else {
      pointsEarned = Math.floor(amount / 10000);
    }
  } else {
    pointsEarned = Math.floor(amount / 10000);
  }

  await userRef.update({
    totalSpent: newSpent,
    totalOrders: newOrders,
    tier: newTier,
    points: FieldValue.increment(pointsEarned)
  });

  await db.collection('orders').doc(orderId).update({ earnedPoints: pointsEarned });

  return pointsEarned;
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
              await orderRef.update({ adminNotes: prevNotes + `- ${text}` });
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
          await db.collection('orders').doc(orderId).update({ trackingCode });
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
          let newPaymentStatus = order.paymentStatus || 'pending';
          let newStatus = order.status;
          let actionLabel = '';
          let statusFootnote = '';

          // ─── Xử lý từng loại action ───
          if (actionType === 'paid') {
            if (order.paymentStatus === 'paid') {
              actionLabel = 'Tiền đã được nhận từ trước!';
            } else {
              newPaymentStatus = 'paid';
              if (order.status === 'pending') newStatus = 'processing';
              actionLabel = '✅ Đã gạch nợ thành công!';
              statusFootnote = '✅ ĐÃ XÁC NHẬN NHẬN TIỀN';
            }

          } else if (actionType === 'processing') {
            if (order.status === 'processing') {
              actionLabel = 'Đơn này đã ở trạng thái Đang chuẩn bị!';
            } else {
              newStatus = 'processing';
              actionLabel = '🔧 Cập nhật thành ĐANG CHUẨN BỊ!';
              statusFootnote = '🔧 ĐANG CHUẨN BỊ HÀNG';
            }

          } else if (actionType === 'shipped') {
            if (order.status === 'shipped') {
              actionLabel = 'Đơn này vốn đã đang giao!';
            } else {
              newStatus = 'shipped';
              actionLabel = '🚚 Cập nhật thành ĐANG GIAO!';
              statusFootnote = '🚚 ĐANG GIAO HÀNG';
            }

          } else if (actionType === 'delivered') {
            if (order.status === 'delivered') {
              actionLabel = 'Đơn này đã hoàn tất từ trước!';
            } else {
              newStatus = 'delivered';
              newPaymentStatus = 'paid'; // Giao thành công = đã thu tiền
              const points = await awardPoints(db, orderId, order);
              actionLabel = `✅ Đã giao thành công! Cộng ${points} điểm cho khách.`;
              statusFootnote = `✅ ĐÃ GIAO THÀNH CÔNG (+${points} điểm)`;
            }

          } else if (actionType === 'cancelled') {
            if (order.status === 'cancelled') {
              actionLabel = 'Đơn này đã được HỦY từ trước!';
            } else {
              newStatus = 'cancelled';
              // Hoàn lại stock sản phẩm
              if (order.items?.length > 0) {
                try { await restoreStock(db, order.items); } catch (e) { console.error('Restore stock error:', e); }
              }
              actionLabel = '❌ Đã HỦY đơn + hoàn kho thành công!';
              statusFootnote = '❌ ĐÃ HỦY ĐƠN (Kho đã hoàn)';
            }
          }

          // Cập nhật Firestore
          const updateData: any = { status: newStatus, paymentStatus: newPaymentStatus };
          // Không ghi đè earnedPoints nếu đã xử lý trong awardPoints
          if (actionType !== 'delivered') {
            await orderRef.update(updateData);
          } else {
            // awardPoints đã update earnedPoints, chỉ cần update status/payment
            await orderRef.update({ status: newStatus, paymentStatus: newPaymentStatus });
          }

          // Trả lời callback
          await tg('answerCallbackQuery', { callback_query_id: cq.id, text: actionLabel, show_alert: true });

          // Cập nhật tin nhắn — rebuild toàn bộ để giữ format HTML
          if (statusFootnote) {
            const updatedOrderSnap = await orderRef.get();
            const updatedOrder = updatedOrderSnap.data()!;
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
          console.error('DB Error:', dbError);
          await tg('answerCallbackQuery', { callback_query_id: cq.id, text: 'Lỗi: Mất kết nối CSDL', show_alert: true });
        }
      }
    }

    return res.status(200).json({ success: true });

  } catch (error) {
    console.error('Telegram Webhook Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
