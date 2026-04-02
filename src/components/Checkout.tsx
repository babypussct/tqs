import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, serverTimestamp, getDocs, query, where, updateDoc, doc, increment, runTransaction } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { CartItem, DiscountCode } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { CheckCircle2, ShoppingBag, ArrowLeft, Ticket, X, Copy } from 'lucide-react';
import { toast } from 'sonner';
import { usePaymentConfig } from '../hooks/usePaymentConfig';

interface CheckoutProps {
  cartItems: CartItem[];
  clearCart: () => void;
}

export default function Checkout({ cartItems, clearCart }: CheckoutProps) {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { paymentConfig, loading: paymentLoading } = usePaymentConfig();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'vietqr'>('cod');
  const [createdOrderId, setCreatedOrderId] = useState<string>('');

  useEffect(() => {
    if (paymentConfig && !paymentConfig.isActive && paymentMethod === 'vietqr') {
      setPaymentMethod('cod');
    }
  }, [paymentConfig, paymentMethod]);
  
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
  if (appliedDiscount) {
    if (appliedDiscount.discountType === 'percentage') {
      discountAmount = (totalAmount * appliedDiscount.discountValue) / 100;
      if (appliedDiscount.maxDiscount && discountAmount > appliedDiscount.maxDiscount) {
        discountAmount = appliedDiscount.maxDiscount;
      }
    } else {
      discountAmount = appliedDiscount.discountValue;
    }
  }

  // Ensure discount doesn't exceed total
  discountAmount = Math.min(discountAmount, totalAmount);
  const finalAmount = totalAmount - discountAmount;

  const handleApplyDiscount = async () => {
    if (!discountCodeInput.trim()) return;
    
    setIsApplyingDiscount(true);
    try {
      const q = query(
        collection(db, 'discountCodes'), 
        where('code', '==', discountCodeInput.trim().toUpperCase()),
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

      // Validate usage limit
      if (discountData.usageLimit && discountData.usedCount >= discountData.usageLimit) {
        toast.error('Mã giảm giá đã hết lượt sử dụng');
        return;
      }

      // Validate min order value
      if (discountData.minOrderValue && totalAmount < discountData.minOrderValue) {
        toast.error(`Đơn hàng phải từ ${discountData.minOrderValue.toLocaleString('vi-VN')}đ để sử dụng mã này`);
        return;
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (cartItems.length === 0) return;
    if (!user) {
      toast.error('Vui lòng đăng nhập để đặt hàng!');
      return;
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

        // 6. Create order
        const orderRef = doc(collection(db, 'orders'));
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
          status: 'pending',
          paymentMethod: paymentMethod,
          paymentStatus: paymentMethod === 'vietqr' ? 'pending' : 'paid',
          shippingInfo,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        };
        
        if (appliedDiscount) {
          orderData.discountCode = appliedDiscount.code;
          orderData.discountAmount = discountAmount;
        }
        orderData.finalAmount = finalAmount;

        transaction.set(orderRef, orderData);

        // 7. Update discount code usage
        if (appliedDiscount) {
          transaction.update(doc(db, 'discountCodes', appliedDiscount.id), {
            usedCount: increment(1)
          });
        }
        
        setCreatedOrderId(orderRef.id);
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
              <img 
                src={`https://img.vietqr.io/image/${paymentConfig.bankId}-${paymentConfig.accountNumber}-${paymentConfig.template}.png?amount=${finalAmount || totalAmount}&addInfo=${createdOrderId}&accountName=${encodeURIComponent(paymentConfig.accountName)}`} 
                alt="VietQR" 
                className="w-64 h-64 object-contain rounded-lg"
              />
              
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
                    <span className="font-bold text-red-600 dark:text-red-500">{(finalAmount || totalAmount).toLocaleString('vi-VN')}</span>
                    <button onClick={() => { navigator.clipboard.writeText((finalAmount || totalAmount).toString()); toast.success('Đã copy số tiền'); }} className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
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
            
            {!user && (
              <div className="mb-6 p-4 bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 rounded-xl text-amber-800 dark:text-amber-500 text-sm">
                Bạn cần đăng nhập để có thể đặt hàng. Vui lòng đăng nhập ở góc trên bên phải màn hình.
              </div>
            )}

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
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Địa chỉ giao hàng *</label>
                <input 
                  required 
                  type="text" 
                  value={shippingInfo.address}
                  onChange={e => setShippingInfo({...shippingInfo, address: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-950 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                  placeholder="Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố" 
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
                <div className="space-y-3">
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
                    onClick={handleApplyDiscount}
                    disabled={isApplyingDiscount || !discountCodeInput.trim()}
                    className="bg-gray-900 dark:bg-white text-white dark:text-gray-900 px-4 py-2.5 rounded-xl text-sm font-bold hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors disabled:opacity-50"
                  >
                    {isApplyingDiscount ? 'Đang áp dụng...' : 'Áp dụng'}
                  </button>
                </div>
              )}
            </div>

            <div className="border-t border-gray-200 dark:border-zinc-800 pt-4 space-y-3 mb-6">
              <div className="flex justify-between text-gray-500 dark:text-zinc-400">
                <span>Tạm tính</span>
                <span>{totalAmount.toLocaleString('vi-VN')}đ</span>
              </div>
              <div className="flex justify-between text-gray-500 dark:text-zinc-400">
                <span>Phí vận chuyển</span>
                <span>Miễn phí</span>
              </div>
              {appliedDiscount && (
                <div className="flex justify-between text-emerald-600 dark:text-emerald-400 font-medium">
                  <span>Giảm giá ({appliedDiscount.code})</span>
                  <span>-{discountAmount.toLocaleString('vi-VN')}đ</span>
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
              disabled={isSubmitting || !user}
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
    </div>
  );
}
