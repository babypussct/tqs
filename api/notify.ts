import { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
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
    const chatId = process.env.TELEGRAM_CHAT_ID; // Có thể là Group ID có biểu tượng (-) đằng trước (VD: -10012345678)

    if (!botToken || !chatId) {
      console.warn('Telegram info is not configured in Vercel System Env.');
      return res.status(200).json({ success: false, message: 'Not configured' });
    }

    const { type, payload } = data;
    
    let message = '';
    let replyMarkup = undefined;
    
    if (type === 'NEW_ORDER') {
      message = `🚀 <b>ĐƠN HÀNG MỚI</b> 🚀\n`;
      message += `Mã đơn: <b>#${payload.orderId}</b>\n`;
      message += `Người nhận: ${payload.customerName}\n`;
      message += `SĐT: <code>${payload.phone || 'N/A'}</code>\n`;
      message += `Địa chỉ: ${payload.address || 'N/A'}\n`;
      if (payload.notes) message += `Ghi chú: <i>${payload.notes}</i>\n`;
      message += `------------------\n`;
      message += `Số tiền: <b>${payload.amount?.toLocaleString('vi-VN')} đ</b>\n`;
      message += `Phương thức: <b>${payload.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;
      
      // Khởi tạo các nút bấm chi tiết
      const inlineButtons = [];
      
      if (payload.paymentMethod === 'vietqr') {
         inlineButtons.push([{ text: '✅ Đã nhận tiền', callback_data: `action:paid:${payload.orderId}` }]);
      }
      
      inlineButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${payload.orderId}` }]);
      inlineButtons.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${payload.orderId}` }]);
      
      replyMarkup = { inline_keyboard: inlineButtons };

    } else {
      message = `🔔 <b>THÔNG BÁO HỆ THỐNG</b>\n${JSON.stringify(payload, null, 2)}`;
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
