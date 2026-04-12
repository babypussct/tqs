import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';

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

  // URL GET đặc biệt để cài đặt Webhook nhanh
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

  // Chặn mọi method không phải POST (Do Telegram bắn Webhook bằng POST)
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const update = req.body;
    
    // Nếu đây là sự kiện bấm nút Inline Button
    if (update.callback_query) {
      const callbackQuery = update.callback_query;
      const data = callbackQuery.data; // VD: confirm_payment:ABCXYZ
      
      if (data && data.startsWith('confirm_payment:')) {
        const orderId = data.split(':')[1];
        
        // 1. Kết nối cơ sở dữ liệu
        const db = admin.firestore();
        const orderRef = db.collection('orders').doc(orderId);
        const orderSnap = await orderRef.get();
        
        if (orderSnap.exists) {
          const currentOrder = orderSnap.data();
          
          if (currentOrder?.paymentStatus === 'paid') {
             // Đã xác nhận rồi
             await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
               method: 'POST',
               headers: { 'Content-Type': 'application/json' },
               body: JSON.stringify({ callback_query_id: callbackQuery.id, text: 'Đơn này đã được xác nhận trước đó rồi!' })
             });
             return res.status(200).json({ success: true });
          }

          // Gạch nợ hóa đơn
          await orderRef.update({
            paymentStatus: 'paid',
            status: currentOrder?.status === 'pending' ? 'processing' : currentOrder?.status
          });

          // 2. Trả lời Callback để hết biểu tượng Loading trên nút bấm
          await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              callback_query_id: callbackQuery.id,
              text: 'Gạch nợ thành công!'
            })
          });

          // 3. Sửa tin nhắn cũ: Xóa nút đi và thêm dòng trạng thái
          const chatId = callbackQuery.message.chat.id;
          const messageId = callbackQuery.message.message_id;
          const originalText = callbackQuery.message.text; 
          
          await fetch(`https://api.telegram.org/bot${botToken}/editMessageText`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              chat_id: chatId,
              message_id: messageId,
              text: originalText + '\n\n✅ <b>ĐÃ XÁC NHẬN NHẬN TIỀN (Thủ công)</b>',
              parse_mode: 'HTML',
              reply_markup: { inline_keyboard: [] }
            })
          });
          
        } else {
           // Báo lỗi bằng popup alert
           await fetch(`https://api.telegram.org/bot${botToken}/answerCallbackQuery`, {
             method: 'POST',
             headers: { 'Content-Type': 'application/json' },
             body: JSON.stringify({
               callback_query_id: callbackQuery.id,
               text: 'Lỗi: Không tìm thấy hóa đơn mã này!',
               show_alert: true
             })
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
