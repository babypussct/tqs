import { VercelRequest, VercelResponse } from '@vercel/node';
import admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import {
  createOrder,
  transitionOrder,
  CreateOrderInput,
  TransitionOrderInput,
  AuthenticatedActor,
  OrderServiceDependencies,
  OrderServiceError,
} from '../src/order/orderService';
import { OrderDocument, IdempotencyRecord } from '../src/order/canonical';

// ─── 1. Initialize Firebase Admin safely ───
if (!admin.apps.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      let pk = process.env.FIREBASE_PRIVATE_KEY || '';
      if (pk.startsWith('"') && pk.endsWith('"')) pk = pk.slice(1, -1);
      pk = pk.replace(/\\n/g, '\n');

      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID || 'gen-lang-client-0845413094',
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: pk,
        }),
      });
    } else {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'gen-lang-client-0845413094',
      });
    }
  } catch (error) {
    console.error('Firebase Admin Initialization Error:', error);
  }
}

function getDb(): FirebaseFirestore.Firestore {
  const dbId = process.env.FIREBASE_DATABASE_ID || 'ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b';
  try {
    return getFirestore(admin.app(), dbId);
  } catch {
    return getFirestore(admin.app());
  }
}

// ─── 2. Telegram Notification Helper ───
async function notifyTelegramNewOrder(order: OrderDocument): Promise<void> {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  if (!botToken || !chatId) return;

  try {
    const isSuspicious = order.riskScore && order.riskScore >= 60;
    let message = isSuspicious
      ? `⚠️ <b>CẢNH BÁO: ĐƠN HÀNG RỦI RO CAO</b> ⚠️\nĐiểm rủi ro: <b>${order.riskScore}/100</b>\n─────────────────────\n`
      : `🚀 <b>ĐƠN HÀNG MỚI</b> 🚀\n`;

    message += `Mã đơn: <b>#${order.id}</b>\n`;
    message += `Người nhận: ${order.shippingInfo?.fullName || 'N/A'}\n`;
    message += `SĐT: <code>${order.shippingInfo?.phone || 'N/A'}</code>\n`;
    message += `Địa chỉ: ${order.shippingInfo?.address || 'N/A'}\n`;
    if (order.shippingInfo?.notes) message += `Ghi chú: <i>${order.shippingInfo.notes}</i>\n`;
    message += `─────────────────────\n`;

    if (order.items && order.items.length > 0) {
      order.items.forEach((item) => {
        message += `- ${item.quantity} x ${item.name} (${item.unitPrice?.toLocaleString('vi-VN')}đ)\n`;
      });
      message += `─────────────────────\n`;
    }

    message += `Tạm tính: ${order.totalAmount?.toLocaleString('vi-VN')} đ\n`;
    if (order.shippingFee > 0) message += `Phí ship: +${order.shippingFee.toLocaleString('vi-VN')} đ\n`;
    if (order.voucherDiscountAmount > 0) message += `Giảm voucher: -${order.voucherDiscountAmount.toLocaleString('vi-VN')} đ\n`;
    if (order.pointsDiscountAmount > 0) message += `Giảm điểm (${order.pointsApplied} pts): -${order.pointsDiscountAmount.toLocaleString('vi-VN')} đ\n`;
    message += `Số tiền cần thu: <b>${order.finalAmount?.toLocaleString('vi-VN')} đ</b>\n`;
    message += `Phương thức: <b>${order.paymentMethod === 'vietqr' ? 'Chuyển khoản (VietQR)' : 'Tiền mặt (COD)'}</b>\n`;

    const inlineButtons: any[][] = [];
    if (order.paymentMethod === 'vietqr') {
      inlineButtons.push([{ text: '✅ Đã nhận tiền', callback_data: `action:paid:${order.id}` }]);
    } else {
      inlineButtons.push([{ text: '💰 Đã thu COD', callback_data: `action:paid:${order.id}` }]);
    }
    inlineButtons.push([{ text: '🔧 Đang chuẩn bị', callback_data: `action:processing:${order.id}` }]);
    inlineButtons.push([{ text: '🚚 Chuyển Đang Giao', callback_data: `action:shipped:${order.id}` }]);
    inlineButtons.push([{ text: '✅ Đã giao thành công', callback_data: `action:delivered:${order.id}` }]);
    inlineButtons.push([{ text: '❌ Hủy đơn', callback_data: `action:cancelled:${order.id}` }]);

    await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML',
        reply_markup: { inline_keyboard: inlineButtons },
      }),
    });
  } catch (err) {
    console.error('Telegram dispatch error (non-fatal):', err);
  }
}

// ─── 3. Main Serverless Handler ───
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const db = getDb();

  // Extract and verify Bearer token
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      code: 'UNAUTHORIZED',
      message: 'Thiếu hoặc sai định dạng Authorization Bearer token.',
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();
  let actor: AuthenticatedActor;

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;
    const email = decoded.email || '';

    // Fetch user profile from Firestore to determine role
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data() || {};
    const role: 'customer' | 'admin' = userData.role === 'admin' ? 'admin' : 'customer';
    const isSuperAdmin = Boolean(userData.isSuperAdmin || email === 'quyencute3@gmail.com');

    actor = {
      uid,
      email,
      role,
      isSuperAdmin,
    };
  } catch (authErr: any) {
    console.error('ID Token Verification Error:', authErr.message);
    return res.status(401).json({
      success: false,
      code: 'INVALID_TOKEN',
      message: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
    });
  }

  // ─── Route: GET /api/orders?orderId=... ───
  if (req.method === 'GET') {
    const orderId = req.query.orderId as string;
    if (!orderId) {
      return res.status(400).json({ success: false, code: 'MISSING_ORDER_ID', message: 'Thiếu orderId' });
    }

    try {
      const orderSnap = await db.collection('orders').doc(orderId).get();
      if (!orderSnap.exists) {
        return res.status(404).json({ success: false, code: 'ORDER_NOT_FOUND', message: 'Không tìm thấy đơn hàng.' });
      }

      const orderData = orderSnap.data() as OrderDocument;
      // Ownership check: customer can only read their own order
      if (actor.role === 'customer' && orderData.userId !== actor.uid) {
        return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Bạn không có quyền xem đơn hàng này.' });
      }

      return res.status(200).json({ success: true, order: orderData });
    } catch (err: any) {
      return res.status(500).json({ success: false, code: 'INTERNAL_ERROR', message: err.message });
    }
  }

  // ─── Route: POST /api/orders (Create or Transition) ───
  if (req.method === 'POST') {
    const body = req.body || {};
    const isTransition = Boolean(body.targetStatus || req.query.action === 'transition');

    // ── Transition Flow ──
    if (isTransition) {
      const transitionInput: TransitionOrderInput = {
        orderId: body.orderId,
        targetStatus: body.targetStatus,
        paymentStatus: body.paymentStatus,
        cancelReason: body.cancelReason,
        returnReason: body.returnReason,
        stockDisposition: body.stockDisposition,
        carrierDeliveryEvidence: body.carrierDeliveryEvidence,
        overrideWindow: body.overrideWindow,
        actionType: body.actionType,
      };

      try {
        const transitionResult = await db.runTransaction(async (transaction) => {
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
            getVoucher: async (code) => {
              const docSnap = await transaction.get(db.collection('discountCodes').doc(code));
              if (docSnap.exists) return { id: docSnap.id, ...docSnap.data() };
              const qSnap = await transaction.get(db.collection('discountCodes').where('code', '==', code).limit(1));
              return qSnap.empty ? null : { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
            },
            incrementVoucherUsage: async (id) => {
              transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(1) });
            },
            decrementVoucherUsage: async (id) => {
              transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(-1) });
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

          return await transitionOrder(actor, transitionInput, deps);
        });

        return res.status(200).json({ success: true, order: transitionResult.order, event: transitionResult.event });
      } catch (err: any) {
        if (err instanceof OrderServiceError) {
          return res.status(err.status).json({ success: false, code: err.code, message: err.message });
        }
        console.error('Transition Error:', err);
        return res.status(400).json({ success: false, code: err.code || 'TRANSITION_FAILED', message: err.message });
      }
    }

    // ── Order Creation Flow ──
    const createInput: CreateOrderInput = {
      items: body.items,
      shippingInfo: body.shippingInfo,
      paymentMethod: body.paymentMethod,
      discountCode: body.discountCode,
      pointsToUse: body.pointsToUse,
      idempotencyKey: body.idempotencyKey,
    };

    try {
      const result = await db.runTransaction(async (transaction) => {
        const deps: OrderServiceDependencies = {
          getIdempotencyRecord: async (id) => {
            const snap = await transaction.get(db.collection('idempotency').doc(id));
            return snap.exists ? (snap.data() as IdempotencyRecord) : null;
          },
          saveIdempotencyRecord: async (record) => {
            transaction.set(db.collection('idempotency').doc(record.id), record);
          },
          getUserProfile: async (uid) => {
            const snap = await transaction.get(db.collection('users').doc(uid));
            return snap.exists ? { id: snap.id, ...snap.data() } : null;
          },
          updateUserPoints: async (uid, delta) => {
            transaction.update(db.collection('users').doc(uid), {
              points: FieldValue.increment(delta),
              totalOrders: FieldValue.increment(1),
            });
          },
          getProduct: async (id) => {
            const snap = await transaction.get(db.collection('products').doc(id));
            return snap.exists ? { id: snap.id, ...snap.data() } : null;
          },
          updateProductStock: async (id, stock) => {
            transaction.update(db.collection('products').doc(id), { stock });
          },
          getShippingConfig: async () => {
            const snap = await transaction.get(db.collection('system_settings').doc('shipping_config'));
            return snap.exists ? snap.data() : null;
          },
          getVoucher: async (code) => {
            const docSnap = await transaction.get(db.collection('discountCodes').doc(code));
            if (docSnap.exists) return { id: docSnap.id, ...docSnap.data() };
            const qSnap = await transaction.get(db.collection('discountCodes').where('code', '==', code).limit(1));
            return qSnap.empty ? null : { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
          },
          incrementVoucherUsage: async (id) => {
            transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(1) });
          },
          decrementVoucherUsage: async (id) => {
            transaction.update(db.collection('discountCodes').doc(id), { usedCount: FieldValue.increment(-1) });
          },
          saveOrder: async (order) => {
            transaction.set(db.collection('orders').doc(order.id), order);
          },
          getOrder: async (id) => {
            const snap = await transaction.get(db.collection('orders').doc(id));
            return snap.exists ? (snap.data() as OrderDocument) : null;
          },
          updateOrder: async (id, updates) => {
            transaction.update(db.collection('orders').doc(id), updates);
          },
          saveEvent: async (orderId, event) => {
            transaction.set(db.collection('orders').doc(orderId).collection('events').doc(event.id), event);
          },
        };

        return await createOrder(actor, createInput, deps);
      });

      // Dispatch Telegram notification asynchronously on server side for fresh orders
      if (!result.isReplay) {
        notifyTelegramNewOrder(result.order).catch((err) =>
          console.error('Failed to notify telegram:', err)
        );
      }

      return res.status(201).json({
        success: true,
        order: result.order,
        isReplay: result.isReplay,
      });
    } catch (err: any) {
      if (err instanceof OrderServiceError) {
        return res.status(err.status).json({
          success: false,
          code: err.code,
          message: err.message,
        });
      }
      console.error('Order Creation Error:', err);
      return res.status(400).json({
        success: false,
        code: err.code || 'CREATION_FAILED',
        message: err.message || 'Không thể tạo đơn hàng.',
      });
    }
  }

  return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED', message: 'Method Not Allowed' });
}
