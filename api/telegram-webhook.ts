import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';

// Khởi tạo Firebase Admin an toàn
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      })
    });
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
    
    // Nếu đây là sự kiện bấm nút Inline Button
    if (update.callback_query) {
      const callbackQuery = update.callback_query;
      const data = callbackQuery.data; // VD: action:paid:ABCXYZ
      
      if (data && data.startsWith('action:')) {
        const parts = data.split(':');
        const actionType = parts[1]; // 'paid', 'shipped', 'cancelled'
        const orderId = parts[2];
        
        const db = admin.firestore();
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
