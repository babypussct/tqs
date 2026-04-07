import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc, arrayUnion, increment, getDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { DiscountCode, AppUser } from '../types';
import { Ticket, Clock, CheckCircle } from 'lucide-react';
import { toast } from 'sonner';

export default function VoucherCenter() {
  const { user, appUser } = useAuth();
  const [vouchers, setVouchers] = useState<DiscountCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [savingId, setSavingId] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, 'discountCodes'),
      where('isActive', '==', true),
      where('isPubliclyVisible', '==', true)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const now = new Date();
      const codes = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() } as DiscountCode))
        .filter(c => {
          // Filter out expired or fully used
          const isExpired = c.endDate?.toDate && c.endDate.toDate() < now;
          const isLimitReached = c.usageLimit && c.usedCount >= c.usageLimit;
          return !isExpired && !isLimitReached;
        });

      // Sort: Flash sale first, then free, then points
      codes.sort((a, b) => {
        if (a.isFlashSale && !b.isFlashSale) return -1;
        if (!a.isFlashSale && b.isFlashSale) return 1;
        const aCost = a.pointsCost || 0;
        const bCost = b.pointsCost || 0;
        return aCost - bCost;
      });

      setVouchers(codes);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user]);

  const handleSaveVoucher = async (voucher: DiscountCode) => {
    if (!user) {
      toast.error('Vui lòng đăng nhập để lưu mã');
      return;
    }
    if (!appUser) {
      toast.error('Chưa tải xong hồ sơ, vui lòng thử lại');
      return;
    }
    const cost = Number(voucher.pointsCost) || 0;

    if (appUser.savedVouchers?.includes(voucher.id)) {
      toast.error('Bạn đã lưu mã này rồi!');
      return;
    }

    if ((appUser.points || 0) < cost) {
      toast.error('Bạn không đủ điểm để đổi mã này!');
      return;
    }

    setSavingId(voucher.id);
    try {
      const userRef = doc(db, 'users', user.uid);
      
      const updateData: any = {
        savedVouchers: arrayUnion(voucher.id)
      };
      
      if (cost > 0) {
        updateData.points = increment(-cost);
      }
      
      await updateDoc(userRef, updateData);

      toast.success(cost > 0 ? `Đã đổi mã thành công (-${cost} điểm)` : 'Đã lưu mã thành công!');
    } catch (err: any) {
      console.error('Lỗi khi lưu mã:', err);
      toast.error('Lỗi khi lưu mã: ' + (err.message || 'Vui lòng kiểm tra lại kết nối'));
    } finally {
      setSavingId(null);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);
  };

  const formatDateTime = (dateObj: any) => {
    if (!dateObj?.toDate) return '';
    return dateObj.toDate().toLocaleString('vi-VN');
  };

  const TIER_ORDER = ['bronze', 'silver', 'gold', 'diamond'];
  const userTierIdx = appUser ? TIER_ORDER.indexOf(appUser.tier) : -1;

  if (loading) {
    return <div className="text-center py-10 scale-90"><div className="w-6 h-6 border-2 border-red-500 border-t-transparent flex rounded-full animate-spin mx-auto"></div></div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end mb-6">
        <div>
          <h2 className="text-2xl font-black text-slate-900 dark:text-white mb-1">Kho Voucher</h2>
          <p className="text-slate-500 font-medium">Khám phá và thu thập các mã giảm giá hấp dẫn</p>
        </div>
        <div className="text-right">
          <div className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-1">Điểm của bạn</div>
          <div className="text-2xl font-black text-indigo-600 drop-shadow-sm">{appUser?.points?.toLocaleString('vi-VN') || 0}</div>
        </div>
      </div>

      {vouchers.length === 0 ? (
        <div className="bg-slate-50 dark:bg-zinc-900 p-8 rounded-2xl text-center border border-slate-200 dark:border-zinc-800">
          <Ticket className="w-12 h-12 text-slate-300 mx-auto mb-3" />
          <h3 className="font-bold text-slate-700 dark:text-zinc-300">Không có mã giảm giá nào</h3>
          <p className="text-sm text-slate-500 mt-1">Vui lòng quay lại sau nhé!</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {vouchers.map(voucher => {
            const isSaved = appUser?.savedVouchers?.includes(voucher.id);
            const cost = voucher.pointsCost || 0;
            const notEnoughPoints = (appUser?.points || 0) < cost;
            
            // Check tier
            let lockedReason = '';
            const userTier = appUser?.tier || 'bronze';
            
            if (voucher.applicableTiers && voucher.applicableTiers.length > 0) {
              if (!voucher.applicableTiers.includes(userTier)) {
                // translate tiers to Vietnamese strings
                const tierNames: Record<string, string> = {
                   'bronze': 'Đồng',
                   'silver': 'Bạc',
                   'gold': 'Vàng',
                   'diamond': 'Kim Cương'
                };
                const allowedTiers = voucher.applicableTiers.map((t: string) => tierNames[t] || t).join(', ');
                lockedReason = `Hạng ${allowedTiers}`;
              }
            }
            
            // Check customer type
            if (!lockedReason && voucher.customerType === 'new' && (appUser?.totalOrders || 0) > 0) {
               lockedReason = 'Khách Mới';
            }
            if (!lockedReason && voucher.customerType === 'returning' && (appUser?.totalOrders || 0) === 0) {
               lockedReason = 'Khách Cũ';
            }

            const isLocked = !!lockedReason;

            return (
              <div key={voucher.id} className="relative bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl flex overflow-hidden shadow-sm hover:shadow-md transition-shadow">
                {/* Left ticket decor */}
                <div className={`w-24 sm:w-32 flex flex-col items-center justify-center p-3 shrink-0 relative ${voucher.isFlashSale ? 'bg-gradient-to-b from-red-500 to-rose-600' : 'bg-gradient-to-b from-indigo-500 to-blue-600'}`}>
                  <Ticket className="w-8 h-8 text-white/50 mb-2" />
                  <div className="font-black text-white text-center text-sm sm:text-lg leading-tight uppercase">
                    {voucher.discountType === 'freeship_only' ? 'Freeship' : voucher.discountType === 'percentage' ? `Giảm ${voucher.discountValue}%` : `Giảm ${formatCurrency(voucher.discountValue)}`}
                  </div>
                </div>

                {/* Right content */}
                <div className="p-4 flex-1 flex flex-col">
                  <div className="mb-auto">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <h4 className="font-bold text-slate-900 dark:text-white line-clamp-1">{voucher.code}</h4>
                      {voucher.isFlashSale && <span className="bg-red-100 text-red-600 text-[10px] font-black px-2 py-0.5 rounded-full uppercase shrink-0">Flash Sale</span>}
                    </div>
                    
                    <ul className="text-xs font-medium text-slate-500 space-y-1">
                      {voucher.minOrderValue ? <li>• Đơn từ {formatCurrency(voucher.minOrderValue)}</li> : <li>• Không yêu cầu tối thiểu</li>}
                      {voucher.maxDiscount ? <li>• Giảm tối đa {formatCurrency(voucher.maxDiscount)}</li> : null}
                      {voucher.usageLimitPerUser ? <li>• Giới hạn 1 người/ {voucher.usageLimitPerUser} lượt</li> : null}
                    </ul>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 dark:border-zinc-800 flex items-center justify-between gap-2">
                    <div className="text-[10px] font-medium text-slate-400 max-w-[50%]">
                      <Clock className="w-3 h-3 inline mr-1" />
                      HSD: {formatDateTime(voucher.endDate)}
                    </div>

                    {isSaved ? (
                      <button disabled className="bg-slate-100 dark:bg-zinc-800 text-slate-500 px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1 shrink-0">
                        <CheckCircle className="w-3 h-3" /> Đã lưu mã
                      </button>
                    ) : isLocked ? (
                      <button disabled className="bg-slate-100 dark:bg-zinc-800 text-slate-400 px-4 py-1.5 rounded-lg text-xs font-bold shrink-0">
                        Chỉ: {lockedReason}
                      </button>
                    ) : (
                      <button 
                        onClick={() => handleSaveVoucher(voucher)}
                        disabled={notEnoughPoints || savingId === voucher.id}
                        className={`px-4 py-1.5 rounded-lg text-xs font-bold shrink-0 transition-all ${
                          notEnoughPoints 
                            ? 'bg-slate-100 dark:bg-zinc-800 text-slate-400 cursor-not-allowed' 
                            : 'bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-500/10 dark:hover:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400'
                        }`}
                      >
                        {savingId === voucher.id ? 'Đang xử lý...' : cost > 0 ? `Đổi ${cost} điểm` : 'Lưu mã'}
                      </button>
                    )}
                  </div>
                </div>

                {/* Scallop edge */}
                <div className="absolute left-24 sm:left-32 top-0 bottom-0 w-2 flex flex-col justify-between -ml-1 py-1">
                  {[...Array(6)].map((_, i) => (
                    <div key={i} className="w-2 h-2 rounded-full bg-white dark:bg-zinc-900" />
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
