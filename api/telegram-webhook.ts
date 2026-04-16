import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';

// Khởi tạo Firebase Admin an toàn
if (!admin.apps.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      // Cách 1: Parse trực tiếp nguyên cụm JSON (Chống lỗi gãy dòng)
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    } else {
      // Cách 2: Parse từng dòng truyền thống
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

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;

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
    
    // Nếu tin nhắn là dạng chữ (Tra cứu /don hoặc reply)
    if (update.message && update.message.text) {
      const text = update.message.text.trim();

      // Xử lý reply tin nhắn để thêm note
      if (update.message.reply_to_message && update.message.reply_to_message.text) {
        const replyText = update.message.reply_to_message.text;
        const noteMatch = replyText.match(/Mã đơn:\s*#([A-Za-z0-9]+)/);
        if (noteMatch) {
          const orderId = noteMatch[1].toUpperCase();
          const dbId = process.env.FIREBASE_DATABASE_ID || 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b';
          const db = getFirestore(admin.app(), dbId);
          const orderRef = db.collection('orders').doc(orderId);
          
          try {
            const orderSnap = await orderRef.get();
            if (orderSnap.exists) {
              const currentOrder = orderSnap.data();
              const prevNotes = currentOrder?.adminNotes ? currentOrder.adminNotes + '\n' : '';
              await orderRef.update({
                adminNotes: prevNotes + `- ${text}`
              });
              
              await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  chat_id: update.message.chat.id,
                  text: `✅ Đã lưu ghi chú cho đơn <b>#${orderId}</b>`,
                  reply_to_message_id: update.message.message_id,
                  parse_mode: 'HTML'
                })
              });
            }
          } catch(e) {
            console.error('Error saving admin note:', e);
          }
          return res.status(200).json({ success: true });
        }
      }

      const match = text.match(/^\/(?:don|order)(?:@[A-Za-z0-9_]+)?\s+([A-Za-z0-9]+)/i);
      
      if (match) {
        const orderId = match[1].toUpperCase();
        if (orderId) {
          const dbId = process.env.FIREBASE_DATABASE_ID || 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b';
          const db = getFirestore(admin.app(), dbId);
          const orderSnap = await db.collection('orders').doc(orderId).get();
          
          if (!orderSnap.exists) {
            await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ chat_id: update.message.chat.id, text: `❌ Không tìm thấy đơn hàng mã #${orderId}` })
            });
          } else {
            const currentOrder = orderSnap.data();
            let msg = `🔎 <b>TRA CỨU LẠI ĐƠN HÀNG</b> 🔎\n`;
            msg += `Mã đơn: <b>#${orderId}</b>\n`;
            let statusVn = currentOrder?.status;
            if (statusVn === 'shipped') statusVn = 'Đang giao (Shipped)';
            else if (statusVn === 'processing') statusVn = 'Đang chuẩn bị (Processing)';
            else if (statusVn === 'pending') statusVn = 'Chờ xử lý (Pending)';
            else if (statusVn === 'cancelled') statusVn = 'Đã hủy (Cancelled)';
            else if (statusVn === 'delivered') statusVn = 'Hoàn tất (Delivered)';

            msg += `Trạng thái: <b>${statusVn}</b>\n`;
            msg += `Thanh toán: <b>${currentOrder?.paymentStatus === 'paid' ? 'Đã thu tiền' : 'Chờ gạch nợ'}</b>\n`;
            msg += `Người nhận: ${currentOrder?.shippingInfo?.fullName || 'N/A'}\n`;
            msg += `SĐT: <code>${currentOrder?.shippingInfo?.phone || 'N/A'}</code>\n`;
            msg += `Địa chỉ: ${currentOrder?.shippingInfo?.address || 'N/A'}\n`;
            if (currentOrder?.shippingInfo?.notes) msg += `Ghi chú: <i>${currentOrder?.shippingInfo?.notes}</i>\n`;
            if (currentOrder?.adminNotes) msg += `📝 Ghi chú Admin: <b>${currentOrder?.adminNotes}</b>\n`;
            msg += `------------------\n`;
            if (currentOrder?.items && currentOrder?.items.length > 0) {
              currentOrder.items.forEach((item: any) => {
                msg += `- ${item.quantity} x ${item.name} (${item.price?.toLocaleString('vi-VN')}đ)\n`;
              });
              msg += `------------------\n`;
            }
            
            const finalAm = currentOrder?.finalAmount || currentOrder?.totalAmount || 0;
            msg += `Số tiền: <b>${finalAm.toLocaleString('vi-VN')} đ</b>\n`;
            msg += `Phương thức: <b>${currentOrder?.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;

            const inlineButtons = [];
            // Nếu chưa thu tiền, vẫn hiện nút Gạch nợ
            if (currentOrder?.paymentMethod === 'vietqr' && currentOrder?.paymentStatus !== 'paid') {
               inlineButtons.push([{ text: '✅ Đã nhận tiền', callback_data: `action:paid:${orderId}` }]);
            }
            // Nếu chưa giao, chưa hủy, hiện nút Đang giao
            if (currentOrder?.status !== 'shipped' && currentOrder?.status !== 'cancelled' && currentOrder?.status !== 'delivered') {
               inlineButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${orderId}` }]);
            }
            if (currentOrder?.status !== 'cancelled') {
               inlineButtons.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${orderId}` }]);
            }
            
            await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                chat_id: update.message.chat.id,
                text: msg,
                parse_mode: 'HTML',
                reply_markup: inlineButtons.length > 0 ? { inline_keyboard: inlineButtons } : undefined
              })
            });
          }
          return res.status(200).json({ success: true });
        }
      }
    }
    
    // Nếu đây là sự kiện bấm nút Inline Button
    if (update.callback_query) {
      const callbackQuery = update.callback_query;
      const data = callbackQuery.data; // VD: action:paid:ABCXYZ
      
      if (data && data.startsWith('action:')) {
        const parts = data.split(':');
        const actionType = parts[1]; // 'paid', 'shipped', 'cancelled'
        const orderId = parts[2];
        
        const dbId = process.env.FIREBASE_DATABASE_ID || 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b';
        const db = getFirestore(admin.app(), dbId);
        const orderRef = db.collection('orders').doc(orderId);
        
        try {
          const orderSnap = await orderRef.get();
          
          if (!orderSnap.exists) {
             await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
               method: 'POST',
               headers: { 'Content-Type': 'application/json' },
               body: JSON.stringify({ callback_query_id: callbackQuery.id, text: 'Lỗi: Không tìm thấy hóa đơn mã này!', show_alert: true })
             });
             return res.status(200).json({ success: true });
          }

          const currentOrder = orderSnap.data();
          let newPaymentStatus = currentOrder?.paymentStatus;
          let newStatus = currentOrder?.status;
          let actionLabel = '';

          // Tính toán trạng thái tiếp theo
          if (actionType === 'paid') {
            if (currentOrder?.paymentStatus === 'paid') {
               actionLabel = 'Tiền đã được nhận từ trước!';
            } else {
               newPaymentStatus = 'paid';
               newStatus = currentOrder?.status === 'pending' ? 'processing' : currentOrder?.status;
               actionLabel = '✅ Đã gạch nợ thành công!';
            }
          } else if (actionType === 'shipped') {
             if (currentOrder?.status === 'shipped') {
               actionLabel = 'Đơn này vốn đã đang giao!';
             } else {
               newStatus = 'shipped';
               actionLabel = '🚚 Cập nhật thành ĐANG GIAO!';
             }
          } else if (actionType === 'cancelled') {
             if (currentOrder?.status === 'cancelled') {
               actionLabel = 'Hóa đơn này đã được HỦY từ trước!';
             } else {
               newStatus = 'cancelled';
               actionLabel = '❌ Đã HỦY hóa đơn này!';
             }
          }

          // Cập nhật Database
          await orderRef.update({
            paymentStatus: newPaymentStatus,
            status: newStatus
          });

          // Giải phóng nút bấm đang Load
          await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ callback_query_id: callbackQuery.id, text: actionLabel, show_alert: true })
          });

          // Cập nhật lại giao diện tin nhắn cũ (Xóa nút đó đi, giữ nguyên các nút còn hợp lý)
          const chatId = callbackQuery.message.chat.id;
          const messageId = callbackQuery.message.message_id;
          const originalText = callbackQuery.message.text; 
          
          let statusFootnote = '';
          const remainedButtons = [];

          if (actionType === 'paid') {
            statusFootnote = '✅ ĐÃ XÁC NHẬN NHẬN TIỀN';
            if (newStatus !== 'cancelled' && newStatus !== 'shipped') {
              remainedButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${orderId}` }]);
            }
          } else if (actionType === 'shipped') {
            statusFootnote = '🚚 ĐANG TRONG QUÁ TRÌNH GIAO HÀNG';
          } else if (actionType === 'cancelled') {
            statusFootnote = '❌ ĐÃ CHÍNH THỨC HỦY ĐƠN';
          }

          // Nếu còn nút nào chừa lại
          const nextMarkup = remainedButtons.length > 0 ? { inline_keyboard: remainedButtons } : { inline_keyboard: [] };

          await fetch(`https://api.telegram.org/bot${botToken}/editMessageText`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              chat_id: chatId,
              message_id: messageId,
              text: originalText + '\n\n' + statusFootnote,
              parse_mode: 'HTML',
              reply_markup: nextMarkup
            })
          });
          
        } catch (dbError) {
          console.error(dbError);
          await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
             method: 'POST',
             headers: { 'Content-Type': 'application/json' },
             body: JSON.stringify({ callback_query_id: callbackQuery.id, text: 'Lỗi: Mất kết nối CSDL (Kiểm tra biến Vercel)', show_alert: true })
          });
        }
      }
    }
    
    return res.status(200).json({ success: true });

  } catch (error) {
    console.error('Telegram Webhook Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
