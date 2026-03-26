import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, serverTimestamp, getDocs, query, where, updateDoc, doc, increment } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { CartItem, DiscountCode } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { CheckCircle2, ShoppingBag, ArrowLeft, Ticket, X } from 'lucide-react';
import { toast } from 'sonner';

interface CheckoutProps {
  cartItems: CartItem[];
  clearCart: () => void;
}

export default function Checkout({ cartItems, clearCart }: CheckoutProps) {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  
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
      const orderData = {
        userId: user.uid,
        items: cartItems.map(item => ({
          productId: item.product.id,
          name: item.product.name,
          price: item.price,
          quantity: item.quantity,
          selectedBox: item.selectedBox || null,
          selectedLang: item.selectedLang || null,
          selectedVariants: item.selectedVariants || null,
          addSleeves: item.addSleeves || false,
          quickAddAccessoryNames: item.quickAddAccessoryNames || null,
          quickAddAccessoryName: (item as any).quickAddAccessoryName || null,
          image: item.product.image
        })),
        totalAmount,
        discountCode: appliedDiscount?.code || null,
        discountAmount: discountAmount || 0,
        finalAmount,
        status: 'pending',
        shippingInfo,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      };

      // Remove null values
      Object.keys(orderData).forEach(key => {
        if ((orderData as any)[key] === null) {
          delete (orderData as any)[key];
        }
      });

      await addDoc(collection(db, 'orders'), orderData);
      
      // Increment used count for discount code
      if (appliedDiscount) {
        await updateDoc(doc(db, 'discountCodes', appliedDiscount.id), {
          usedCount: increment(1)
        });
      }

      clearCart();
      setIsSuccess(true);
      toast.success('Đặt hàng thành công!');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'orders');
      toast.error('Đã có lỗi xảy ra khi đặt hàng. Vui lòng thử lại sau.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSuccess) {
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
