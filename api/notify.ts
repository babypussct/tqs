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

    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;

    if (!botToken || !chatId) {
      console.warn('Telegram info is not configured in Vercel System Env.');
      return res.status(200).json({ success: false, message: 'Not configured' });
    }

    const { type, payload } = data;

    let message = '';
    let replyMarkup = undefined;

    // ────────────────────────────────────────────────────────────
    // 1. ĐƠN HÀNG MỚI
    // ────────────────────────────────────────────────────────────
    if (type === 'NEW_ORDER') {
      const isSuspicious = payload.riskScore && payload.riskScore >= 60;

      if (isSuspicious) {
        message += `⚠️ <b>CẢNH BÁO: ĐƠN HÀNG RỦI RO CAO</b> ⚠️\n`;
        message += `Điểm rủi ro: <b>${payload.riskScore}/100</b> — Kiểm tra kỹ trước khi xử lý!\n`;
        message += `─────────────────────\n`;
      } else {
        message += `🚀 <b>ĐƠN HÀNG MỚI</b> 🚀\n`;
      }

      message += `Mã đơn: <b>#${payload.orderId}</b>\n`;
      message += `Người nhận: ${payload.customerName}\n`;
      message += `SĐT: <code>${payload.phone || 'N/A'}</code>\n`;
      message += `Địa chỉ: ${payload.address || 'N/A'}\n`;
      if (payload.notes) message += `Ghi chú: <i>${payload.notes}</i>\n`;
      message += `─────────────────────\n`;

      if (payload.items && payload.items.length > 0) {
        payload.items.forEach((item: any) => {
          message += `- ${item.quantity} x ${item.name} (${item.price?.toLocaleString('vi-VN')}đ)\n`;
        });
        message += `─────────────────────\n`;
      }

      message += `Số tiền: <b>${payload.amount?.toLocaleString('vi-VN')} đ</b>\n`;
      message += `Phương thức: <b>${payload.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;

      const inlineButtons = [];
      if (payload.paymentMethod === 'vietqr') {
        inlineButtons.push([{ text: '✅ Đã nhận tiền', callback_data: `action:paid:${payload.orderId}` }]);
      }
      inlineButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${payload.orderId}` }]);
      inlineButtons.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${payload.orderId}` }]);
      replyMarkup = { inline_keyboard: inlineButtons };

    // ────────────────────────────────────────────────────────────
    // 2. ĐÁNH GIÁ SẢN PHẨM MỚI
    // ────────────────────────────────────────────────────────────
    } else if (type === 'NEW_REVIEW') {
      const stars = '⭐'.repeat(payload.rating) + '☆'.repeat(5 - payload.rating);
      message += `💬 <b>ĐÁNH GIÁ SẢN PHẨM MỚI</b>\n`;
      message += `Sản phẩm: <b>${payload.productName}</b>\n`;
      message += `Khách hàng: ${payload.userName}\n`;
      message += `Đánh giá: ${stars} <b>(${payload.rating}/5)</b>\n`;
      message += `─────────────────────\n`;
      message += `<i>"${payload.comment}"</i>\n`;

    // ────────────────────────────────────────────────────────────
    // 3. KHÁCH XÁC NHẬN ĐÃ NHẬN HÀNG
    // ────────────────────────────────────────────────────────────
    } else if (type === 'ORDER_DELIVERED') {
      message += `✅ <b>KHÁCH XÁC NHẬN ĐÃ NHẬN HÀNG</b>\n`;
      message += `Mã đơn: <b>#${payload.orderId}</b>\n`;
      message += `Khách hàng: ${payload.customerName}\n`;
      message += `SĐT: <code>${payload.phone}</code>\n`;
      message += `─────────────────────\n`;
      message += `Thành tiền: <b>${payload.amount?.toLocaleString('vi-VN')} đ</b>\n`;
      message += `Điểm thưởng đã cộng: <b>+${payload.earnedPoints} điểm</b>\n`;
      message += `\n🎉 Đơn hàng hoàn tất! Hãy để lại đánh giá cho khách.`;

    // ────────────────────────────────────────────────────────────
    // 4. MẶC ĐỊNH (thông báo hệ thống)
    // ────────────────────────────────────────────────────────────
    } else {
      message = `🔔 <b>THÔNG BÁO HỆ THỐNG</b>\n${JSON.stringify(payload, null, 2)}`;
    }

    // Gửi Telegram
    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const response = await fetch(telegramUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
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
