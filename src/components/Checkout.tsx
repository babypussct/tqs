import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, serverTimestamp, getDocs, query, where, updateDoc, doc, increment, runTransaction, Timestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { CartItem, DiscountCode } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { CheckCircle2, ShoppingBag, ArrowLeft, Ticket, X, Copy } from 'lucide-react';
import { toast } from 'sonner';
import { usePaymentConfig } from '../hooks/usePaymentConfig';
import { useShippingConfig } from '../hooks/useShippingConfig';
import { useRewardsConfig } from '../utils/useRewardsConfig';
import VietnamAddressSelector from './ui/VietnamAddressSelector';
import { AppUser } from '../types';
import { onSnapshot } from 'firebase/firestore';

interface CheckoutProps {
  cartItems: CartItem[];
  clearCart: () => void;
}

export default function Checkout({ cartItems, clearCart }: CheckoutProps) {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { paymentConfig, loading: paymentLoading } = usePaymentConfig();
  const { shippingConfig, loading: shippingLoading } = useShippingConfig();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'vietqr'>('cod');
  const [userProfile, setUserProfile] = useState<AppUser | null>(null);
  const { config: rewardsConfig } = useRewardsConfig();
  const [pointsToUseInput, setPointsToUseInput] = useState<string>('');
  const [appliedPoints, setAppliedPoints] = useState<number>(0);
  const [showVoucherModal, setShowVoucherModal] = useState(false);
  const [savedVouchersList, setSavedVouchersList] = useState<DiscountCode[]>([]);
  
  useEffect(() => {
    if (!user) return;
    const unsub = onSnapshot(doc(db, 'users', user.uid), (doc) => {
      if (doc.exists()) setUserProfile(doc.data() as AppUser);
    });
    return unsub;
  }, [user]);

  useEffect(() => {
    if (!userProfile?.savedVouchers || userProfile.savedVouchers.length === 0) {
      setSavedVouchersList([]);
      return;
    }
    const fetchVouchers = async () => {
      try {
        const q = query(collection(db, 'discountCodes'), where('isActive', '==', true));
        const snap = await getDocs(q);
        const allActive = snap.docs.map(doc => ({ id: doc.id, ...doc.data() } as DiscountCode));
        const userSaved = allActive.filter(v => userProfile.savedVouchers?.includes(v.id));
        setSavedVouchersList(userSaved);
      } catch (err) {}
    };
    if (showVoucherModal) fetchVouchers();
  }, [userProfile?.savedVouchers, showVoucherModal]);
  const [createdOrderId, setCreatedOrderId] = useState<string>('');
  const [orderFinalAmount, setOrderFinalAmount] = useState<number>(0);
  const [orderTotalAmount, setOrderTotalAmount] = useState<number>(0);
  // Honeypot - ẩn với người dùng, bot thường tự điền
  const [honeypot, setHoneypot] = useState('');

  // Check if any product restricts COD, or if there's a payment method clash
  const allowCOD = cartItems.every(item => 
    !item.product.allowedPaymentMethods || 
    item.product.allowedPaymentMethods.includes('cod')
  );

  useEffect(() => {
    if (!allowCOD && paymentConfig?.isActive) {
      setPaymentMethod('vietqr');
    } else if (paymentConfig && !paymentConfig.isActive && paymentMethod === 'vietqr') {
      setPaymentMethod('cod');
    }
  }, [paymentConfig, paymentMethod, allowCOD]);
  
  const [shippingInfo, setShippingInfo] = useState({
    fullName: user?.displayName || '',
    phone: '',
    address: '',
    notes: ''
  });

  const [discountCodeInput, setDiscountCodeInput] = useState('');
  const [appliedDiscount, setAppliedDiscount] = useState<DiscountCode | null>(null);
  const [isApplyingDiscount, setIsApplyingDiscount] = useState(false);

  const totalAmount = cartItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);

  // Calculate discount
  let discountAmount = 0;
  if (appliedDiscount && appliedDiscount.discountType !== 'freeship_only') {
    let baseAmountForDiscount = totalAmount;

    // Filter by products / categories if specified
    if (
      (appliedDiscount.applicableProducts && appliedDiscount.applicableProducts.length > 0) ||
      (appliedDiscount.applicableCategories && appliedDiscount.applicableCategories.length > 0)
    ) {
      baseAmountForDiscount = cartItems.reduce((acc, item) => {
        const matchesProduct = appliedDiscount.applicableProducts?.includes(item.product.id);
        const matchesCategory = appliedDiscount.applicableCategories?.includes(item.product.type);
        if (matchesProduct || matchesCategory) {
          return acc + (item.price * item.quantity);
        }
        return acc;
      }, 0);
    }

    if (appliedDiscount.discountType === 'percentage') {
      discountAmount = (baseAmountForDiscount * appliedDiscount.discountValue) / 100;
      if (appliedDiscount.maxDiscount && discountAmount > appliedDiscount.maxDiscount) {
        discountAmount = appliedDiscount.maxDiscount;
      }
    } else if (appliedDiscount.discountType === 'fixed') {
      // Fixed discount cannot exceed the eligible amount
      discountAmount = Math.min(appliedDiscount.discountValue, baseAmountForDiscount);
    }
  }

  // Ensure discount doesn't exceed total
  discountAmount = Math.min(discountAmount, totalAmount);
  
  // Calculate shipping
  let shippingFee = 0;
  const hasFreeshipProduct = cartItems.some(item => shippingConfig.freeshipProductIds.includes(item.product.id));
  const isCodeFreeship = appliedDiscount?.isFreeship || appliedDiscount?.discountType === 'freeship_only';
  const threshold = shippingConfig.freeshipThreshold ?? 0;
  const meetsThreshold = threshold > 0 && totalAmount >= threshold;
  
  if (shippingConfig.isActive && !hasFreeshipProduct && !isCodeFreeship && !meetsThreshold) {
    shippingFee = shippingConfig.defaultFee;
  }

  // Calculate Points Discount
  let pointsDiscountAmount = 0;
  if (rewardsConfig && rewardsConfig.isActive && appliedPoints > 0) {
    const pointsValueInVND = appliedPoints * rewardsConfig.pointValueVND;
    const maxDiscountVND = totalAmount * (rewardsConfig.maxDiscountPercentage / 100);
    pointsDiscountAmount = Math.min(pointsValueInVND, maxDiscountVND, totalAmount - discountAmount);
  }

  const finalAmount = Math.max(0, totalAmount + shippingFee - discountAmount - pointsDiscountAmount);

  const handleApplyDiscount = async (overrideCode?: string) => {
    const codeToApply = overrideCode || discountCodeInput.trim();
    if (!codeToApply) return;
    
    setIsApplyingDiscount(true);
    try {
      const q = query(
        collection(db, 'discountCodes'), 
        where('code', '==', codeToApply.toUpperCase()),
        where('isActive', '==', true)
      );
      
      const snapshot = await getDocs(q);
      
      if (snapshot.empty) {
        toast.error('Mã giảm giá không hợp lệ hoặc đã hết hạn');
        setAppliedDiscount(null);
        return;
      }

      const discountDoc = snapshot.docs[0];
      const discountData = { id: discountDoc.id, ...discountDoc.data() } as DiscountCode;

      // Validate dates
      const now = new Date();
      const startDate = discountData.startDate?.toDate ? discountData.startDate.toDate() : new Date(0);
      const endDate = discountData.endDate?.toDate ? discountData.endDate.toDate() : new Date(8640000000000000);

      if (now < startDate) {
        toast.error('Mã giảm giá chưa đến thời gian sử dụng');
        return;
      }

      if (now > endDate) {
        toast.error('Mã giảm giá đã hết hạn');
        return;
      }

      // Validate usage limit overall
      if (discountData.usageLimit && discountData.usedCount >= discountData.usageLimit) {
        toast.error('Mã giảm giá đã hết lượt sử dụng');
        return;
      }

      // Check usageLimitPerUser
      if (user) {
        const usageLimitPerUser = discountData.usageLimitPerUser || 1;
        const usageQ = query(
          collection(db, 'orders'), 
          where('userId', '==', user.uid), 
          where('discountCode', '==', discountData.code),
          where('status', '!=', 'cancelled')
        );
        const usageSnap = await getDocs(usageQ);
        if (usageSnap.size >= usageLimitPerUser) {
          toast.error(`Bạn đã hết lượt sử dụng mã này (Tối đa ${usageLimitPerUser} lượt/người)`);
          return;
        }
      }

      // Validate min order value
      if (discountData.minOrderValue && totalAmount < discountData.minOrderValue) {
        toast.error(`Đơn hàng phải từ ${discountData.minOrderValue.toLocaleString('vi-VN')}đ để sử dụng mã này`);
        return;
      }

      // Check customer type
      if (discountData.customerType === 'new') {
        if (!user) {
          toast.error('Vui lòng đăng nhập để kiểm tra điều kiện mã giảm giá');
          return;
        }
        const ordersQ = query(collection(db, 'orders'), where('userId', '==', user.uid), where('status', '!=', 'cancelled'));
        const ordersSnap = await getDocs(ordersQ);
        if (!ordersSnap.empty) {
          toast.error('Mã giảm giá này chỉ dành cho khách hàng mới (chưa có đơn hàng)');
          return;
        }
      }

      // Check applicable tiers
      if (discountData.applicableTiers && discountData.applicableTiers.length > 0) {
        if (!userProfile) {
          toast.error('Vui lòng đăng nhập để kiểm tra hạng thành viên');
          return;
        }
        if (!discountData.applicableTiers.includes((userProfile.tier as any) || 'bronze')) {
          toast.error('Mã giảm giá này không dành cho hạng thành viên của bạn');
          return;
        }
      }

      // Check applicable products
      if (
        (discountData.applicableProducts && discountData.applicableProducts.length > 0) ||
        (discountData.applicableCategories && discountData.applicableCategories.length > 0)
      ) {
        const hasApplicable = cartItems.some(item => 
          discountData.applicableProducts?.includes(item.product.id) ||
          discountData.applicableCategories?.includes(item.product.type)
        );
        if (!hasApplicable) {
          toast.error('Mã giảm giá này không áp dụng cho các sản phẩm trong giỏ hàng');
          return;
        }
      }

      setAppliedDiscount(discountData);
      toast.success('Áp dụng mã giảm giá thành công!');
    } catch (error) {
      console.error("Error applying discount:", error);
      toast.error('Có lỗi xảy ra khi kiểm tra mã giảm giá');
    } finally {
      setIsApplyingDiscount(false);
    }
  };

  const removeDiscount = () => {
    setAppliedDiscount(null);
    setDiscountCodeInput('');
  };

  const validateShippingInfo = () => {
    // --- Họ & Tên ---
    const trimmedName = shippingInfo.fullName.trim();
    const nameWords = trimmedName.split(/\s+/).filter(w => w.length >= 2);
    if (nameWords.length < 2) {
      toast.error('Vui lòng nhập đầy đủ họ và tên người nhận (ít nhất 2 từ, mỗi từ ít nhất 2 ký tự).');
      return false;
    }
    // Không được chứa số hoặc ký tự đặc biệt trong tên
    if (/[0-9!@#$%^&*()_+=\[\]{};':"\\|,.<>\/?`~]/.test(trimmedName)) {
      toast.error('Họ và tên không được chứa số hoặc ký tự đặc biệt.');
      return false;
    }
    // Không có ký tự lặp lại quá nhiều trong tên
    if (/(.)\1{2,}/.test(trimmedName.replace(/\s/g, ''))) {
      toast.error('Họ và tên không hợp lệ.');
      return false;
    }

    // --- Số điện thoại ---
    const cleanPhone = shippingInfo.phone.replace(/\s+/g, '');
    const phoneRegex = /^(0[3|5|7|8|9])+([0-9]{8})$/;
    if (!phoneRegex.test(cleanPhone)) {
      toast.error('Số điện thoại không hợp lệ. Vui lòng nhập đúng số điện thoại Việt Nam (10 số).');
      return false;
    }
    // Chặn SĐT test phổ biến
    const blockedPhones = ['0123456789', '0987654321', '0111111111', '0000000000', '0999999999', '0123123123', '0369369369'];
    if (blockedPhones.includes(cleanPhone)) {
      toast.error('Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại thực của bạn.');
      return false;
    }
    // Không chấp nhận số gồm toàn một chữ số (0333333333, 0555555555...)
    if (/^0(.)\1{8}$/.test(cleanPhone)) {
      toast.error('Số điện thoại không hợp lệ.');
      return false;
    }

    // --- Địa chỉ ---
    const trimmedAddr = shippingInfo.address.trim();
    if (trimmedAddr.length < 20) {
      toast.error('Địa chỉ giao hàng quá ngắn. Vui lòng nhập đầy đủ: Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố.');
      return false;
    }
    // Phải có ít nhất 1 chữ số (số nhà, ngõ, km...)
    if (!/\d/.test(trimmedAddr)) {
      toast.error('Địa chỉ phải có số nhà hoặc số đường. Ví dụ: 123 Nguyễn Trãi, Thanh Xuân, Hà Nội.');
      return false;
    }
    // Phải có dấu phẩy (phân cách đơn vị hành chính)
    if (!trimmedAddr.includes(',')) {
      toast.error('Địa chỉ phải có dấu phẩy phân cách. Ví dụ: 123 Nguyễn Trãi, Thanh Xuân, Hà Nội.');
      return false;
    }
    const repetitiveRegex = /(.)\1{4,}/;
    if (repetitiveRegex.test(trimmedAddr.replace(/\s+/g, ''))) {
      toast.error('Địa chỉ giao hàng không hợp lệ (nghi ngờ spam/đơn ảo).');
      return false;
    }
    // Địa chỉ không được toàn số
    if (/^[\d\s,]+$/.test(trimmedAddr)) {
      toast.error('Địa chỉ giao hàng không hợp lệ.');
      return false;
    }

    // --- Ghi chú ---
    if (shippingInfo.notes && repetitiveRegex.test(shippingInfo.notes.replace(/\s+/g, ''))) {
      toast.error('Ghi chú chứa ký tự lặp lại không hợp lệ.');
      return false;
    }

    return true;
  };

  // Tính điểm rủi ro đơn hàng (0-100)
  const calculateRiskScore = async (uid: string): Promise<number> => {
    let score = 0;

    // 1. Tuổi tài khoản
    const creationTime = user?.metadata?.creationTime;
    if (creationTime) {
      const ageDays = (Date.now() - new Date(creationTime).getTime()) / (1000 * 60 * 60 * 24);
      if (ageDays < 1) score += 30;
      else if (ageDays < 7) score += 15;
    } else {
      score += 20; // Không biết tuổi tài khoản
    }

    // 2. Lịch sử đơn hàng (tỷ lệ huỷ)
    try {
      const allOrdersSnap = await getDocs(
        query(collection(db, 'orders'), where('userId', '==', uid))
      );
      const total = allOrdersSnap.size;
      const cancelled = allOrdersSnap.docs.filter(d => d.data().status === 'cancelled').length;

      if (total === 0) score += 10; // Đơn đầu tiên
      if (total > 0) {
        const cancelRate = cancelled / total;
        if (cancelRate > 0.5) score += 35;
        else if (cancelRate > 0.3) score += 20;
      }
    } catch {
      // Bỏ qua nếu không đọc được lịch sử
    }

    return Math.min(score, 100);
  };

  const generateOrderCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 8; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (cartItems.length === 0) return;
    if (!user) {
      toast.error('Vui lòng đăng nhập để đặt hàng!');
      return;
    }

    // Honeypot check — bot detection
    if (honeypot !== '') {
      // Âm thầm giả vờ thành công để bot không biết
      setIsSuccess(true);
      return;
    }

    if (!validateShippingInfo()) return;

    // Rate limiting: tối đa 3 đơn trong 1 giờ
    try {
      const oneHourAgo = Timestamp.fromDate(new Date(Date.now() - 3600000));
      const recentSnap = await getDocs(
        query(
          collection(db, 'orders'),
          where('userId', '==', user.uid),
          where('createdAt', '>=', oneHourAgo)
        )
      );
      if (recentSnap.size >= 3) {
        toast.error('Bạn đã đặt quá nhiều đơn trong 1 giờ. Vui lòng thử lại sau.');
        return;
      }
    } catch {
      // Bỏ qua lỗi rate limit check, tiếp tục xử lý
    }

    setIsSubmitting(true);
    try {
      await runTransaction(db, async (transaction) => {
        // 1. Read all products to check stock
        const productRefs = cartItems.map(item => doc(db, 'products', item.product.id));
        const productDocs = await Promise.all(productRefs.map(ref => transaction.get(ref)));
        
        // 2. Map current stock
        const stockMap = new Map<string, number>();
        const existingProducts = new Set<string>();
        const inactiveProducts = new Set<string>();
        productDocs.forEach(docSnap => {
          if (docSnap.exists()) {
            const data = docSnap.data();
            if (data.isActive === false) {
              inactiveProducts.add(docSnap.id);
            } else {
              existingProducts.add(docSnap.id);
              if (data.stock !== undefined) {
                stockMap.set(docSnap.id, data.stock);
              }
            }
          }
        });

        // 3. Calculate total quantity needed per product
        const quantityNeeded = new Map<string, number>();
        cartItems.forEach(item => {
          const current = quantityNeeded.get(item.product.id) || 0;
          quantityNeeded.set(item.product.id, current + item.quantity);
        });

        // 4. Check if stock is sufficient and product exists/active
        for (const [productId, needed] of quantityNeeded.entries()) {
          if (inactiveProducts.has(productId)) {
            const product = cartItems.find(i => i.product.id === productId)?.product;
            throw new Error(`Sản phẩm "${product?.name}" hiện đang ngừng kinh doanh.`);
          }
          if (!existingProducts.has(productId)) {
            const product = cartItems.find(i => i.product.id === productId)?.product;
            throw new Error(`Sản phẩm "${product?.name}" không còn tồn tại.`);
          }
          const available = stockMap.get(productId);
          if (available !== undefined && available < needed) {
            const product = cartItems.find(i => i.product.id === productId)?.product;
            throw new Error(`Sản phẩm "${product?.name}" chỉ còn ${available} sản phẩm trong kho.`);
          }
        }

        // 5. Deduct stock
        for (const [productId, needed] of quantityNeeded.entries()) {
          const available = stockMap.get(productId);
          if (available !== undefined) {
            transaction.update(doc(db, 'products', productId), {
              stock: available - needed
            });
          }
        }

        // 6. Tính điểm rủi ro
        const riskScore = await calculateRiskScore(user.uid);
        const orderStatus = riskScore >= 60 ? 'suspicious' : 'pending';

        // 7. Create order
        const orderId = generateOrderCode();
        const orderRef = doc(db, 'orders', orderId);
        const orderData: any = {
          userId: user.uid,
          items: cartItems.map(item => {
            const itemData: any = {
              productId: item.product.id,
              name: item.product.name,
              price: item.price,
              quantity: item.quantity,
              image: item.product.image
            };
            if (item.selectedBox) itemData.selectedBox = item.selectedBox;
            if (item.selectedLang) itemData.selectedLang = item.selectedLang;
            if (item.selectedVariants) itemData.selectedVariants = item.selectedVariants;
            if (item.addSleeves) itemData.addSleeves = item.addSleeves;
            if (item.quickAddAccessoryNames) itemData.quickAddAccessoryNames = item.quickAddAccessoryNames;
            if ((item as any).quickAddAccessoryName) itemData.quickAddAccessoryName = (item as any).quickAddAccessoryName;
            return itemData;
          }),
          totalAmount,
          status: orderStatus,
          paymentMethod: paymentMethod,
          paymentStatus: paymentMethod === 'vietqr' ? 'pending' : 'paid',
          shippingInfo,
          riskScore,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        };
        
        if (appliedDiscount) {
          orderData.discountCode = appliedDiscount.code;
          orderData.discountAmount = discountAmount;
        }
        if (appliedPoints > 0) {
          orderData.discountCode = (orderData.discountCode ? orderData.discountCode + ', ' : '') + `Dùng ${appliedPoints} điểm`;
          orderData.discountAmount = (orderData.discountAmount || 0) + pointsDiscountAmount;
          // Deduct points from user
          transaction.update(doc(db, 'users', user.uid), {
            points: increment(-appliedPoints)
          });
        }
        orderData.shippingFee = shippingFee;
        orderData.finalAmount = finalAmount;

        transaction.set(orderRef, orderData);

        // 7. Update discount code usage
        if (appliedDiscount) {
          transaction.update(doc(db, 'discountCodes', appliedDiscount.id), {
            usedCount: increment(1)
          });
        }
        
        // 8. Update user stats
        transaction.update(doc(db, 'users', user.uid), {
          totalOrders: increment(1)
        });
        
        setCreatedOrderId(orderRef.id);
        setOrderFinalAmount(finalAmount);
        setOrderTotalAmount(totalAmount);
      });

      clearCart();
      setIsSuccess(true);
      toast.success('Đặt hàng thành công!');
    } catch (error: any) {
      if (error.message && (error.message.includes('chỉ còn') || error.message.includes('ngừng kinh doanh') || error.message.includes('không còn tồn tại'))) {
        toast.error(error.message);
      } else {
        handleFirestoreError(error, OperationType.CREATE, 'orders');
        toast.error('Đã có lỗi xảy ra khi đặt hàng. Vui lòng thử lại sau.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSuccess) {
    if (paymentMethod === 'vietqr') {
      return (
        <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-gray-200 dark:border-zinc-800 shadow-sm max-w-md mx-auto">
            <h1 className="text-2xl font-black text-gray-900 dark:text-white tracking-tight mb-2">Thanh toán đơn hàng</h1>
            <p className="text-gray-500 dark:text-zinc-400 mb-6 text-sm">
              Vui lòng quét mã QR bên dưới bằng ứng dụng ngân hàng của bạn để thanh toán.
            </p>
            <div className="bg-gray-50 dark:bg-zinc-950 p-4 rounded-xl border border-gray-200 dark:border-zinc-800 mb-6 flex flex-col items-center justify-center">
              <div className="bg-white dark:bg-white p-3 rounded-2xl shadow-sm border border-gray-100 dark:border-zinc-800 flex items-center justify-center w-full max-w-[320px] mx-auto">
                <img 
                  src={`https://img.vietqr.io/image/${paymentConfig.bankId}-${paymentConfig.accountNumber}-${paymentConfig.template}.png?amount=${orderFinalAmount || orderTotalAmount}&addInfo=${createdOrderId}&accountName=${encodeURIComponent(paymentConfig.accountName)}`} 
                  alt="VietQR" 
                  className="w-full h-auto aspect-square object-contain rounded-xl"
                />
              </div>
              
              <div className="w-full mt-6 space-y-3 bg-white dark:bg-zinc-900 p-4 rounded-lg border border-gray-200 dark:border-zinc-800">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500 dark:text-zinc-400">Ngân hàng:</span>
                  <span className="font-bold text-gray-900 dark:text-white">{paymentConfig.bankId}</span>
                </div>
                <div className="flex items-center justify-between text-sm group">
                  <span className="text-gray-500 dark:text-zinc-400">Mã đơn (Nội dung):</span>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-blue-600 dark:text-blue-400">{createdOrderId}</span>
                    <button onClick={() => { navigator.clipboard.writeText(createdOrderId); toast.success('Đã copy nội dung'); }} className="p-1.5 text-gray-400 hover:text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                      <Copy className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
                <div className="flex items-center justify-between text-sm group">
                  <span className="text-gray-500 dark:text-zinc-400">Số tài khoản:</span>
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-bold text-gray-900 dark:text-white">{paymentConfig.accountNumber}</span>
                    <button onClick={() => { navigator.clipboard.writeText(paymentConfig.accountNumber); toast.success('Đã copy số tài khoản'); }} className="p-1.5 text-gray-400 hover:text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                      <Copy className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
                <div className="flex items-center justify-between text-sm group">
                  <span className="text-gray-500 dark:text-zinc-400">Số tiền:</span>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-red-600 dark:text-red-500">{(orderFinalAmount || orderTotalAmount).toLocaleString('vi-VN')}</span>
                    <button onClick={() => { navigator.clipboard.writeText((orderFinalAmount || orderTotalAmount).toString()); toast.success('Đã copy số tiền'); }} className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                      <Copy className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>

              <p className="text-xs text-center text-gray-500 dark:text-zinc-400 mt-4 leading-relaxed font-medium">
                {paymentConfig.paymentNote}
              </p>
            </div>

            
            <div className="space-y-3">
              <button
                onClick={() => {
                  toast.success('Đang chờ xác nhận thanh toán');
                  navigate('/profile');
                }}
                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-3.5 rounded-xl font-bold transition-colors shadow-lg shadow-emerald-600/20 flex items-center justify-center gap-2"
              >
                <CheckCircle2 className="w-5 h-5" /> Tôi đã chuyển khoản
              </button>
              <button
                onClick={() => navigate('/profile')}
                className="w-full bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-8 py-3.5 rounded-xl font-bold transition-colors"
              >
                Thanh toán sau
              </button>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">
        <div className="w-20 h-20 bg-emerald-100 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-500 rounded-full flex items-center justify-center mx-auto mb-6">
          <CheckCircle2 className="w-10 h-10" />
        </div>
        <h1 className="text-3xl font-black text-gray-900 dark:text-white tracking-tight mb-4">Đặt hàng thành công!</h1>
        <p className="text-gray-500 dark:text-zinc-400 mb-8 max-w-md mx-auto">
          Cảm ơn bạn đã mua sắm tại cửa hàng. Đơn hàng của bạn đang được xử lý và sẽ sớm được giao đến bạn.
        </p>
        <button
          onClick={() => navigate('/shop')}
          className="bg-red-600 hover:bg-red-700 text-white px-8 py-3 rounded-xl font-bold transition-colors shadow-lg shadow-red-600/20"
        >
          Tiếp tục mua sắm
        </button>
      </div>
    );
  }

  if (cartItems.length === 0) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center">
        <ShoppingBag className="w-16 h-16 text-gray-300 dark:text-zinc-700 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Giỏ hàng trống</h2>
        <p className="text-gray-500 dark:text-zinc-400 mb-8">Bạn chưa có sản phẩm nào trong giỏ hàng để thanh toán.</p>
        <button
          onClick={() => navigate('/shop')}
          className="bg-red-600 hover:bg-red-700 text-white px-8 py-3 rounded-xl font-bold transition-colors shadow-lg shadow-red-600/20"
        >
          Đến cửa hàng
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <button 
        onClick={() => navigate(-1)}
        className="flex items-center gap-2 text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors mb-8 font-medium"
      >
        <ArrowLeft className="w-4 h-4" /> Quay lại
      </button>

      <h1 className="text-3xl font-black uppercase tracking-tight text-gray-900 dark:text-white mb-8">Thanh Toán</h1>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Form */}
        <div className="lg:col-span-7 space-y-6">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl p-6 sm:p-8 border border-gray-200 dark:border-zinc-800 shadow-sm">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">Thông tin giao hàng</h2>
            
            {/* Honeypot field - ẩn với người dùng thật, bot thường tự điền */}
            <input
              type="text"
              name="website"
              value={honeypot}
              onChange={e => setHoneypot(e.target.value)}
              style={{ display: 'none', position: 'absolute', left: '-9999px' }}
              tabIndex={-1}
              autoComplete="off"
              aria-hidden="true"
            />

            <form id="checkout-form" onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Họ và tên *</label>
                <input 
                  required 
                  type="text" 
                  value={shippingInfo.fullName}
                  onChange={e => setShippingInfo({...shippingInfo, fullName: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                  placeholder="Nhập họ và tên người nhận" 
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Số điện thoại *</label>
                <input 
                  required 
                  type="tel" 
                  value={shippingInfo.phone}
                  onChange={e => setShippingInfo({...shippingInfo, phone: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                  placeholder="Nhập số điện thoại liên hệ" 
                />
              </div>
              <div>
                <VietnamAddressSelector 
                  value={shippingInfo.address}
                  onChange={(val) => setShippingInfo({...shippingInfo, address: val})}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Ghi chú (Tùy chọn)</label>
                <textarea 
                  rows={3}
                  value={shippingInfo.notes}
                  onChange={e => setShippingInfo({...shippingInfo, notes: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all resize-y" 
                  placeholder="Ghi chú thêm về đơn hàng, thời gian giao hàng..." 
                />
              </div>

              <div className="pt-4 border-t border-gray-200 dark:border-zinc-800">
                <label className="block text-sm font-bold text-gray-900 dark:text-white mb-4">Phương thức thanh toán</label>
                {!allowCOD && paymentConfig?.isActive && (
                  <div className="mb-4 p-3 bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 rounded-xl text-sm text-amber-800 dark:text-amber-400">
                    ℹ️ Đơn hàng có sản phẩm yêu cầu thanh toán chuyển khoản trước (VietQR).
                  </div>
                )}
                <div className="space-y-3">
                  {allowCOD && (
                    <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${paymentMethod === 'cod' ? 'border-red-500 bg-red-50 dark:bg-red-500/10' : 'border-gray-200 dark:border-zinc-800 hover:border-red-300 dark:hover:border-red-500/50'}`}>
                      <input 
                        type="radio" 
                        name="paymentMethod" 
                        value="cod"
                        checked={paymentMethod === 'cod'}
                        onChange={() => setPaymentMethod('cod')}
                        className="w-4 h-4 text-red-600 border-gray-300 focus:ring-red-500"
                      />
                      <div className="ml-3">
                        <span className="block text-sm font-medium text-gray-900 dark:text-white">Thanh toán khi nhận hàng (COD)</span>
                        <span className="block text-xs text-gray-500 dark:text-zinc-400 mt-0.5">Thanh toán bằng tiền mặt khi giao hàng</span>
                      </div>
                    </label>
                  )}
                  
                  {paymentConfig.isActive && (
                    <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${paymentMethod === 'vietqr' ? 'border-red-500 bg-red-50 dark:bg-red-500/10' : 'border-gray-200 dark:border-zinc-800 hover:border-red-300 dark:hover:border-red-500/50'}`}>
                      <input 
                        type="radio" 
                        name="paymentMethod" 
                        value="vietqr"
                        checked={paymentMethod === 'vietqr'}
                        onChange={() => setPaymentMethod('vietqr')}
                        className="w-4 h-4 text-red-600 border-gray-300 focus:ring-red-500"
                      />
                      <div className="ml-3">
                        <span className="block text-sm font-medium text-gray-900 dark:text-white">Chuyển khoản qua VietQR</span>
                        <span className="block text-xs text-gray-500 dark:text-zinc-400 mt-0.5">Quét mã QR bằng ứng dụng ngân hàng</span>
                      </div>
                    </label>
                  )}
                </div>
              </div>
            </form>
          </div>
        </div>

        {/* Order Summary */}
        <div className="lg:col-span-5">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl p-6 sm:p-8 border border-gray-200 dark:border-zinc-800 shadow-sm sticky top-24">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">Đơn hàng của bạn</h2>
            
            <div className="space-y-4 mb-6 max-h-[40vh] overflow-y-auto pr-2 custom-scrollbar">
              {cartItems.map((item) => (
                <div key={item.id} className="flex gap-4">
                  <div className="w-16 h-16 rounded-lg bg-gray-100 dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 overflow-hidden shrink-0">
                    {item.product.image ? (
                      <img src={item.product.image} alt={item.product.name} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-medium text-gray-900 dark:text-white line-clamp-2 leading-snug">{item.product.name}</h4>
                    <div className="text-xs text-gray-500 dark:text-zinc-400 mt-1 space-y-0.5">
                      {item.selectedBox && <p>Hộp: {item.selectedBox}</p>}
                      {item.selectedLang && <p>Ngôn ngữ: {item.selectedLang}</p>}
                      {item.selectedVariants && Object.entries(item.selectedVariants).map(([k, v]) => (
                        <p key={k}>{k}: {v}</p>
                      ))}
                      {item.quickAddAccessoryNames?.map(name => (
                        <p key={name}>+ {name}</p>
                      ))}
                      {item.addSleeves && !item.quickAddAccessoryNames && <p>+ {(item as any).quickAddAccessoryName || 'Kèm Sleeves'}</p>}
                    </div>
                    <div className="flex items-center justify-between mt-2">
                      <span className="text-sm text-gray-500 dark:text-zinc-400">SL: {item.quantity}</span>
                      <span className="text-sm font-bold text-gray-900 dark:text-white">
                        {(item.price * item.quantity).toLocaleString('vi-VN')}đ
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Points Usage */}
            {rewardsConfig?.isActive && userProfile && userProfile.points > 0 && (
              <div className="border-t border-gray-200 dark:border-zinc-800 pt-6 mb-6">
                <h3 className="text-sm font-bold text-yellow-500 mb-3 flex items-center gap-2">
                  <Ticket className="w-4 h-4" /> Điểm thưởng: <span className="text-gray-900 dark:text-white font-mono">{userProfile.points.toLocaleString()}</span>
                </h3>
                
                { appliedPoints > 0 ? (
                  <div className="flex items-center justify-between bg-yellow-50 dark:bg-yellow-500/10 border border-yellow-200 dark:border-yellow-500/20 rounded-xl p-3">
                    <div className="flex items-center gap-2">
                       <CheckCircle2 className="w-5 h-5 text-yellow-500" />
                       <div>
                         <p className="text-sm font-bold text-yellow-700 dark:text-yellow-400">Đã dùng {appliedPoints} điểm</p>
                         <p className="text-xs text-yellow-600 dark:text-yellow-500">Giảm thêm {pointsDiscountAmount.toLocaleString('vi-VN')}đ</p>
                       </div>
                    </div>
                    <button 
                      onClick={() => setAppliedPoints(0)}
                      className="p-1.5 text-yellow-600 dark:text-yellow-500 hover:bg-yellow-100 dark:hover:bg-yellow-500/20 rounded-lg transition-colors"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  <div className="flex gap-2">
                    <input 
                      type="number"
                      value={pointsToUseInput}
                      onChange={(e) => setPointsToUseInput(e.target.value)}
                      placeholder={`Có thể dùng tới ${userProfile.points}`}
                      className="flex-1 bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-sm outline-none w-full text-gray-900 dark:text-white"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        const num = parseInt(pointsToUseInput);
                        if (isNaN(num) || num <= 0) {
                          toast.error('Số điểm không hợp lệ'); return;
                        }
                        if (num > userProfile.points) {
                          toast.error('Bạn không đủ điểm!'); return;
                        }
                        if (num < rewardsConfig.minPointsToUse) {
                          toast.error(`Điểm tối thiểu được dùng là ${rewardsConfig.minPointsToUse} điểm`); return;
                        }
                        setAppliedPoints(num);
                        setPointsToUseInput('');
                      }}
                      className="bg-yellow-500 text-black px-4 py-2.5 rounded-xl font-bold text-sm hover:bg-yellow-400"
                    >
                      Dùng Điểm
                    </button>
                  </div>
                )}
                <p className="text-xs text-gray-400 mt-2">1 điểm = {rewardsConfig.pointValueVND.toLocaleString('vi-VN')}đ. Giảm tối đa {rewardsConfig.maxDiscountPercentage}% giá trị đơn hàng.</p>
              </div>
            )}

            {/* Discount Code Input */}
            <div className="border-t border-gray-200 dark:border-zinc-800 pt-6 mb-6">
              <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-3 flex items-center gap-2">
                <Ticket className="w-4 h-4" /> Mã giảm giá
              </h3>
              
              {appliedDiscount ? (
                <div className="flex items-center justify-between bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 rounded-xl p-3">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                    <div>
                      <p className="text-sm font-bold text-emerald-700 dark:text-emerald-400">{appliedDiscount.code}</p>
                      <p className="text-xs text-emerald-600 dark:text-emerald-500">
                        Đã giảm {discountAmount.toLocaleString('vi-VN')}đ
                      </p>
                    </div>
                  </div>
                  <button 
                    onClick={removeDiscount}
                    className="p-1.5 text-emerald-600 dark:text-emerald-500 hover:bg-emerald-100 dark:hover:bg-emerald-500/20 rounded-lg transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              ) : (
                <div className="flex gap-2">
                  <input 
                    type="text" 
                    value={discountCodeInput}
                    onChange={(e) => setDiscountCodeInput(e.target.value.toUpperCase())}
                    placeholder="Nhập mã giảm giá" 
                    className="flex-1 bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all uppercase"
                  />
                  <button 
                    type="button"
                    onClick={() => handleApplyDiscount()}
                    disabled={isApplyingDiscount || !discountCodeInput.trim()}
                    className="bg-gray-900 dark:bg-white text-white dark:text-gray-900 px-4 py-2.5 rounded-xl text-sm font-bold hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors disabled:opacity-50"
                  >
                    {isApplyingDiscount ? 'Đang áp dụng...' : 'Áp dụng'}
                  </button>
                </div>
              )}

              {!appliedDiscount && (
                <button
                  type="button"
                  onClick={() => setShowVoucherModal(true)}
                  className="mt-3 text-sm text-indigo-600 dark:text-indigo-400 font-bold flex items-center gap-2 hover:underline w-full text-left"
                >
                  <Ticket className="w-4 h-4" /> Hoặc chọn từ Kho Voucher
                </button>
              )}
            </div>

            <div className="border-t border-gray-200 dark:border-zinc-800 pt-4 space-y-3 mb-6">
              <div className="flex justify-between text-gray-500 dark:text-zinc-400">
                <span>Tạm tính</span>
                <span>{totalAmount.toLocaleString('vi-VN')}đ</span>
              </div>
              <div className="flex justify-between text-gray-500 dark:text-zinc-400">
                <span>Phí vận chuyển</span>
                <span>{shippingFee === 0 ? 'Miễn phí' : `${shippingFee.toLocaleString('vi-VN')}đ`}</span>
              </div>
              {shippingFee > 0 && shippingConfig.isActive && threshold > 0 && (
                <div className="text-xs text-blue-600 dark:text-blue-500 text-right mt-1">
                  Mua thêm {(threshold - totalAmount).toLocaleString('vi-VN')}đ để được Freeship
                </div>
              )}
              {appliedDiscount && (
                <div className="flex justify-between text-emerald-600 dark:text-emerald-400 font-medium">
                  <span>Giảm giá ({appliedDiscount.code})</span>
                  <span>-{discountAmount.toLocaleString('vi-VN')}đ</span>
                </div>
              )}
              {appliedPoints > 0 && (
                <div className="flex justify-between text-yellow-600 dark:text-yellow-400 font-medium">
                  <span>Dùng điểm ({appliedPoints})</span>
                  <span>-{pointsDiscountAmount.toLocaleString('vi-VN')}đ</span>
                </div>
              )}
              <div className="flex justify-between text-lg font-bold text-gray-900 dark:text-white pt-3 border-t border-gray-200 dark:border-zinc-800">
                <span>Tổng cộng</span>
                <span className="text-red-600 dark:text-red-500">{finalAmount.toLocaleString('vi-VN')}đ</span>
              </div>
            </div>

            <button
              type="submit"
              form="checkout-form"
              disabled={isSubmitting}
              className="w-full bg-red-600 hover:bg-red-700 disabled:bg-gray-400 disabled:dark:bg-zinc-700 text-white py-3.5 rounded-xl font-bold text-lg transition-colors shadow-lg shadow-red-600/20 flex items-center justify-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Đang xử lý...
                </>
              ) : (
                'Đặt Hàng'
              )}
            </button>
          </div>
        </div>
      </div>

      {showVoucherModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white dark:bg-zinc-900 rounded-2xl w-full max-w-lg shadow-xl overflow-hidden flex flex-col max-h-[80vh]">
            <div className="p-4 sm:p-6 border-b border-gray-200 dark:border-zinc-800 flex items-center justify-between">
              <h3 className="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Ticket className="w-5 h-5 text-indigo-500" />
                Chọn Voucher Đã Lưu
              </h3>
              <button 
                onClick={() => setShowVoucherModal(false)}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-white"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="p-4 sm:p-6 overflow-y-auto custom-scrollbar flex-1 bg-gray-50 dark:bg-zinc-950">
              {savedVouchersList.length === 0 ? (
                <div className="text-center py-10">
                  <Ticket className="w-12 h-12 text-gray-300 dark:text-zinc-700 mx-auto mb-3" />
                  <p className="text-gray-500 dark:text-zinc-400 font-medium pb-2">Bạn chưa lưu mã giảm giá nào.</p>
                  <a href="/profile" className="text-indigo-500 hover:underline text-sm font-bold">Vào Kho Voucher</a> 
                </div>
              ) : (
                <div className="space-y-3">
                  {savedVouchersList.map(voucher => {
                    // Caculate if eligible
                    let isEligible = true;
                    let ineligibleReason = '';
                    
                    const now = new Date();
                    const endDate = voucher.endDate?.toDate ? voucher.endDate.toDate() : new Date(8640000000000000);
                    if (now > endDate) { isEligible = false; ineligibleReason = 'Đã hết hạn'; }
                    if (voucher.usageLimit && voucher.usedCount >= voucher.usageLimit) { isEligible = false; ineligibleReason = 'Hết lượt sử dụng chung'; }
                    if (voucher.minOrderValue && totalAmount < voucher.minOrderValue) { isEligible = false; ineligibleReason = `Cần mua thêm ${(voucher.minOrderValue - totalAmount).toLocaleString('vi-VN')}đ`; }
                    if (voucher.applicableTiers && voucher.applicableTiers.length > 0 && !voucher.applicableTiers.includes((userProfile?.tier as any) || 'bronze')) {
                      const tierNames: Record<string, string> = { bronze: 'Đồng', silver: 'Bạc', gold: 'Vàng', diamond: 'Kim Cương' };
                      const allowedTiers = voucher.applicableTiers.map((t: string) => tierNames[t] || t).join(', ');
                      isEligible = false; 
                      ineligibleReason = `Chỉ Hạng: ${allowedTiers}`; 
                    }
                    
                    if (
                      (voucher.applicableProducts && voucher.applicableProducts.length > 0) ||
                      (voucher.applicableCategories && voucher.applicableCategories.length > 0)
                    ) {
                      const hasApplicable = cartItems.some(item => 
                        voucher.applicableProducts?.includes(item.product.id) ||
                        voucher.applicableCategories?.includes(item.product.type)
                      );
                      if (!hasApplicable) { isEligible = false; ineligibleReason = 'Không áp dụng cho sp trong giỏ'; }
                    }

                    return (
                      <div key={voucher.id} className={`p-4 border rounded-xl flex items-center justify-between transition-all ${isEligible ? 'bg-white dark:bg-zinc-900 border-gray-200 dark:border-zinc-800 cursor-pointer hover:border-indigo-500 dark:hover:border-indigo-500' : 'bg-gray-100 dark:bg-zinc-900/50 border-gray-200 dark:border-zinc-800 opacity-60'}`} onClick={() => {
                        if (!isEligible) return;
                        setDiscountCodeInput(voucher.code);
                        setShowVoucherModal(false);
                        handleApplyDiscount(voucher.code);
                      }}>
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-bold text-gray-900 dark:text-white uppercase">{voucher.code}</span>
                            {voucher.isFlashSale && <span className="bg-red-100 text-red-600 text-[10px] font-black px-2 py-0.5 rounded-full uppercase">Flash Sale</span>}
                          </div>
                          <p className="text-sm font-medium text-emerald-600 dark:text-emerald-500 mb-1">
                            {voucher.discountType === 'freeship_only' ? 'Free-ship' : voucher.discountType === 'percentage' ? `Giảm ${voucher.discountValue}%` : `Giảm ${voucher.discountValue.toLocaleString('vi-VN')}đ`}
                          </p>
                          {voucher.minOrderValue ? <p className="text-xs text-gray-500">Đơn từ {voucher.minOrderValue.toLocaleString('vi-VN')}đ</p> : null}
                          {!isEligible && <p className="text-xs font-bold text-red-500 mt-1">{ineligibleReason}</p>}
                        </div>
                        {isEligible && (
                          <button className="bg-indigo-50 text-indigo-600 px-4 py-2 rounded-lg text-sm font-bold shrink-0">
                            Áp dụng
                          </button>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
