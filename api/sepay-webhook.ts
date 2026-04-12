import { VercelRequest, VercelResponse } from '@vercel/node';
import * as admin from 'firebase-admin';

// Khởi tạo Firebase Admin an toàn (Chỉ khởi tạo 1 lần trong môi trường serverless)
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        // Thay thế cặp newline cho chuỗi key từ biến môi trường của Vercel
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      })
    });
  } catch (error) {
    console.error('Firebase Admin Initialization Error:', error);
  }
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const data = req.body;
    
    // Webhook mẫu SePay: { "id": 123, "transferType": "in", "transferAmount": 500000, "content": "MB1234 DH1A2B3C" }
    if (data.transferType !== 'in') {
      return res.status(200).json({ success: true, message: 'Ignored out-bound transaction' });
    }

    const content = (data.content || '').toUpperCase();
    const amount = Number(data.transferAmount) || 0;
    
    // Truy vấn tất cả Order "pending" payment
    const db = admin.firestore();
    const ordersRef = db.collection('orders');
    
    // Do SePay gửi content dạng chuỗi (user tự gõ), ta cần quyét qua các mã đơn
    // Để an toàn, tìm các đơn đang pending trả vietqr
    const pendingOrdersSnapshot = await ordersRef
      .where('paymentMethod', '==', 'vietqr')
      .where('paymentStatus', '==', 'pending')
      .get();
      
    let matchedOrder = null;
    let matchedId = null;

    for (const doc of pendingOrdersSnapshot.docs) {
      const orderId = doc.id.toUpperCase();
      // Nếu Nội dung chuyển khoản của KH chứa mã ID của Order này
      if (content.includes(orderId)) {
        matchedOrder = doc.data();
        matchedId = doc.id;
        break;
      }
    }

    // Gửi Telegram (chỉ cố gắng gửi nếu có cấu hình)
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;

    // Không tìm thấy đơn hợp lệ mang mã đó
    if (!matchedOrder || !matchedId) {
      if (botToken && chatId) {
        await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            chat_id: chatId,
            text: `⚠️ <b>CÓ GIAO DỊCH LẠ!</b>\nNhận được: <b>${amount.toLocaleString('vi-VN')} đ</b>\nNội dung: ${data.content}\n\n<i>(Không tìm thấy mã đơn hàng trùng khớp đang chờ thanh toán)</i>`,
            parse_mode: 'HTML'
          })
        });
      }
      return res.status(200).json({ success: true, message: 'No matching order found' });
    }

    // Nếu tiền chuyển thiếu/thừa (để admin ktra), ở đây tạm cho qua hoặc ghi lại
    const finalAmount = matchedOrder.finalAmount || matchedOrder.totalAmount;
    let paymentNoteText = "";
    if (amount < finalAmount) {
      paymentNoteText = `(⚠️ Thiếu tiền: Yêu cầu ${finalAmount}, Thực nhận ${amount})`;
    } else {
      paymentNoteText = `(✅ Đủ tiền)`;
    }

    // Đánh dấu là đã thanh toán, nhưng nếu thiếu thì có thể xử lý manual sau
    await ordersRef.doc(matchedId).update({
      paymentStatus: 'paid',
      // Có thể cập nhật `status: 'processing'` tùy flow, ở đây mặc định sẽ là update paymentStatus
      status: matchedOrder.status === 'pending' ? 'processing' : matchedOrder.status
    });

    // Bắn tin báo Telegram
    if (botToken && chatId) {
      await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          text: `💸 <b>BAY TING TING!</b> 💸\n\nĐã nhận thanh toán cho đơn: <b>#${matchedId}</b>\nKhách: ${matchedOrder.shippingInfo?.fullName || 'N/A'}\nThực nhận: <b>${amount.toLocaleString('vi-VN')} đ</b> ${paymentNoteText}\nTrạng thái đơn: Đã lên thành Processing.`,
          parse_mode: 'HTML'
        })
      });
    }

    return res.status(200).json({ success: true, message: 'Order updated successfully' });

  } catch (error) {
    console.error('Sepay Webhook Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
