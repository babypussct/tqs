import { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS setup if frontend domain is different, but not strictly needed if same origin on Vercel
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const data = req.body;
    
    // Telegram Env Vars
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;

    if (!botToken || !chatId) {
      console.warn('Telegram info is not configured in Vercel System Env.');
      return res.status(200).json({ success: false, message: 'Not configured' });
    }

    const { type, payload } = data;
    
    let message = '';
    
    if (type === 'NEW_ORDER') {
      message = `🚀 <b>ĐƠN HÀNG MỚI</b> 🚀\n`;
      message += `Mã đơn: <b>#${payload.orderId}</b>\n`;
      message += `Người nhận: ${payload.customerName}\n`;
      message += `Số tiền: <b>${payload.amount.toLocaleString('vi-VN')} đ</b>\n`;
      message += `Phương thức: ${payload.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}\n`;
      
      let replyMarkup = undefined;
      // Nếu phương thức là vietqr, thêm nút bấm kèm chứa data xác nhận đơn
      if (payload.paymentMethod === 'vietqr') {
        replyMarkup = {
          inline_keyboard: [[
            { text: '✅ Xác nhận Đã nhận đủ tiền', callback_data: `confirm_payment:${payload.orderId}` }
          ]]
        };
      }

      // Send to Telegram
      const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
      const response = await fetch(telegramUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          chat_id: chatId,
          text: message,
          parse_mode: 'HTML',
          reply_markup: replyMarkup
        })
      });

    if (!response.ok) {
      console.error('Telegram API Error:', await response.text());
      return res.status(500).json({ error: 'Failed to notify telegram' });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Notify Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}
