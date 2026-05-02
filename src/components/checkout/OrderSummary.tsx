import React from 'react';
import { Ticket, CheckCircle2, X, Trash2, Minus, Plus } from 'lucide-react';
import { toast } from 'sonner';
import { CartItem, DiscountCode, AppUser } from '../../types';
import { cloudinaryUrl } from '../../utils/cloudinaryUrl';

interface OrderSummaryProps {
  cartItems: CartItem[];
  onUpdateQuantity: (id: string, deltaOrQuantity: number, isAbsolute?: boolean) => void;
  onRemoveItem: (id: string) => void;
  
  totalAmount: number;
  shippingFee: number;
  discountAmount: number;
  pointsDiscountAmount: number;
  finalAmount: number;
  
  shippingConfig: any;
  threshold: number;
  
  rewardsConfig: any;
  userProfile: AppUser | null;
  appliedPoints: number;
  pointsToUseInput: string;
  setPointsToUseInput: (val: string) => void;
  setAppliedPoints: (val: number) => void;
  
  appliedDiscount: DiscountCode | null;
  discountCodeInput: string;
  setDiscountCodeInput: (val: string) => void;
  handleApplyDiscount: (code?: string) => void;
  removeDiscount: () => void;
  isApplyingDiscount: boolean;
  setShowVoucherModal: (val: boolean) => void;
  
  isSubmitting: boolean;
}

export default function OrderSummary({
  cartItems,
  onUpdateQuantity,
  onRemoveItem,
  totalAmount,
  shippingFee,
  discountAmount,
  pointsDiscountAmount,
  finalAmount,
  shippingConfig,
  threshold,
  rewardsConfig,
  userProfile,
  appliedPoints,
  pointsToUseInput,
  setPointsToUseInput,
  setAppliedPoints,
  appliedDiscount,
  discountCodeInput,
  setDiscountCodeInput,
  handleApplyDiscount,
  removeDiscount,
  isApplyingDiscount,
  setShowVoucherModal,
  isSubmitting
}: OrderSummaryProps) {
  return (
    <div className="bg-white dark:bg-zinc-900 rounded-2xl p-6 sm:p-8 border border-gray-200 dark:border-zinc-800 shadow-sm sticky top-24">
      <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">Đơn hàng của bạn</h2>
      
      <div className="space-y-3 mb-6 max-h-[45vh] overflow-y-auto pr-1 custom-scrollbar">
        {cartItems.map((item) => {
          const totalProductQuantity = cartItems
            .filter(i => i.product.id === item.product.id)
            .reduce((sum, i) => sum + i.quantity, 0);
          return (
            <div key={item.id} className="flex gap-3 bg-gray-50 dark:bg-zinc-800/50 rounded-xl p-3 border border-gray-100 dark:border-zinc-700/50">
              <div className="w-14 h-14 rounded-lg bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 overflow-hidden shrink-0">
                {item.product.image ? (
                  <img src={cloudinaryUrl(item.product.image, { width: 80, quality: 'auto:low' })} alt={item.product.name} loading="lazy" decoding="async" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="text-xs font-semibold text-gray-900 dark:text-white line-clamp-2 leading-snug">{item.product.name}</h4>
                <div className="text-[11px] text-gray-400 dark:text-zinc-500 mt-0.5 space-y-0.5">
                  {item.selectedBox && <p>Hộp: {item.selectedBox}</p>}
                  {item.selectedLang && <p>NN: {item.selectedLang}</p>}
                  {item.selectedVariants && Object.entries(item.selectedVariants).map(([k, v]) => (
                    <p key={k}>{k}: {v}</p>
                  ))}
                  {item.quickAddAccessoryNames?.map(name => (
                    <p key={name} className="text-emerald-600 dark:text-emerald-500">+ {name}</p>
                  ))}
                  {item.addSleeves && !item.quickAddAccessoryNames && <p className="text-emerald-600 dark:text-emerald-500">+ {(item as any).quickAddAccessoryName || 'Kèm Sleeves'}</p>}
                </div>
                <div className="flex items-center justify-between mt-2">
                  <div className="flex items-center gap-2">
                    <div className="flex items-center bg-white dark:bg-zinc-900 rounded-lg border border-gray-200 dark:border-zinc-600">
                      <button
                        type="button"
                        onClick={() => {
                          if (item.quantity <= 1) {
                            onRemoveItem(item.id);
                          } else {
                            onUpdateQuantity(item.id, -1);
                          }
                        }}
                        className="p-1 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors rounded-l-lg"
                      >
                        {item.quantity <= 1 ? <Trash2 className="h-3 w-3" /> : <Minus className="h-3 w-3" />}
                      </button>
                      <span className="w-7 text-center text-xs font-bold text-gray-900 dark:text-white">{item.quantity}</span>
                      <button
                        type="button"
                        onClick={() => onUpdateQuantity(item.id, 1)}
                        disabled={item.product.stock !== undefined && totalProductQuantity >= item.product.stock}
                        className={`p-1 transition-colors rounded-r-lg ${
                          item.product.stock !== undefined && totalProductQuantity >= item.product.stock
                            ? 'text-gray-200 dark:text-zinc-700 cursor-not-allowed'
                            : 'text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400'
                        }`}
                      >
                        <Plus className="h-3 w-3" />
                      </button>
                    </div>
                    <button
                      type="button"
                      onClick={() => onRemoveItem(item.id)}
                      className="p-1 text-gray-300 dark:text-zinc-600 hover:text-red-500 dark:hover:text-red-400 transition-colors"
                      title="Xóa sản phẩm"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                  <span className="text-sm font-bold text-gray-900 dark:text-white">
                    {(item.price * item.quantity).toLocaleString('vi-VN')}đ
                  </span>
                </div>
              </div>
            </div>
          );
        })}
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
                type="button"
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
              type="button"
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
  );
}
