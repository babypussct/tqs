import React, { useState, useEffect, useMemo } from 'react';
import { collection, query, where, orderBy, onSnapshot, doc, updateDoc, serverTimestamp, increment } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { Order, AppUser, TierConfig } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Package, Clock, CheckCircle, Truck, XCircle, ShoppingBag, QrCode, Copy, ChevronDown, ChevronUp, Trophy, Star, TrendingUp, Settings, LogOut, ShieldCheck, Ticket, User as UserIcon } from 'lucide-react';
import { toast } from 'sonner';
import { usePaymentConfig } from '../hooks/usePaymentConfig';
import { useRewardsConfig } from '../utils/useRewardsConfig';
import VoucherCenter from './VoucherCenter';
import OrderHistory from './profile/OrderHistory';
import UserSettings from './profile/UserSettings';
import { cloudinaryUrl } from '../utils/cloudinaryUrl';

export default function Profile() {
  const { user, logout } = useAuth();
  const { paymentConfig } = usePaymentConfig();
  const { config: rewardsConfig } = useRewardsConfig();
  const [orders, setOrders] = useState<Order[]>([]);
  const [appUser, setAppUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'orders' | 'rewards' | 'vouchers' | 'settings'>('overview');

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }

    const q = query(
      collection(db, 'orders'),
      where('userId', '==', user.uid),
      orderBy('createdAt', 'desc')
    );
    
    const unsubscribeOrders = onSnapshot(q, (snapshot) => {
      const ordersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Order[];
      
      setOrders(ordersData);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'orders');
      setLoading(false);
    });

    const unsubscribeUser = onSnapshot(doc(db, 'users', user.uid), (doc) => {
      if (doc.exists()) {
        setAppUser(doc.data() as AppUser);
      }
    });

    return () => {
      unsubscribeOrders();
      unsubscribeUser();
    };
  }, [user]);

  const getStatusConfig = (status: Order['status']) => {
    switch (status) {
      case 'pending':
        return { icon: Clock, color: 'text-amber-500', bg: 'bg-amber-50 dark:bg-amber-500/10', border: 'border-amber-200 dark:border-amber-500/20', label: 'Chờ xử lý' };
      case 'processing':
        return { icon: Package, color: 'text-blue-500', bg: 'bg-blue-50 dark:bg-blue-500/10', border: 'border-blue-200 dark:border-blue-500/20', label: 'Đang chuẩn bị' };
      case 'shipped':
        return { icon: Truck, color: 'text-purple-500', bg: 'bg-purple-50 dark:bg-purple-500/10', border: 'border-purple-200 dark:border-purple-500/20', label: 'Đang giao' };
      case 'delivered':
        return { icon: CheckCircle, color: 'text-emerald-500', bg: 'bg-emerald-50 dark:bg-emerald-500/10', border: 'border-emerald-200 dark:border-emerald-500/20', label: 'Đã giao' };
      case 'cancelled':
      case 'returned':
      case 'refunded':
      case 'failed_delivery':
        return { icon: XCircle, color: 'text-red-500', bg: 'bg-red-50 dark:bg-red-500/10', border: 'border-red-200 dark:border-red-500/20', label: 'Đã hủy/Hoàn' };
      default:
        return { icon: Clock, color: 'text-gray-500', bg: 'bg-gray-50 dark:bg-zinc-800', border: 'border-gray-200 dark:border-zinc-700', label: 'N/A' };
    }
  };


  // Tiến độ VIP
  const { nextTier, progressPercentage, missingAmount, activeTierConfig } = useMemo(() => {
    if (!appUser || !rewardsConfig?.tiers) return { nextTier: null, progressPercentage: 0, missingAmount: 0, activeTierConfig: null };
    
    // Sort tiers by minSpent
    const sortedTiers = Object.values(rewardsConfig.tiers).sort((a, b) => a.minSpent - b.minSpent);
    let activeTierConfig = rewardsConfig.tiers[appUser.tier] || null;
    
    // Safety check just in case appUser.tier is somehow invalid, find highest tier matched by minSpent
    const totalSpent = appUser.totalSpent || 0;
    if (!activeTierConfig) {
       for (let i = sortedTiers.length - 1; i >= 0; i--) {
          if (totalSpent >= sortedTiers[i].minSpent) {
             activeTierConfig = sortedTiers[i];
             break;
          }
       }
       if (!activeTierConfig) activeTierConfig = sortedTiers[0];
    }
    
    let nextTierConfig: TierConfig | null = null;
    for (const tier of sortedTiers) {
      if (tier.minSpent > totalSpent) {
        nextTierConfig = tier;
        break;
      }
    }
    
    let progressPercentage = 100;
    let missingAmount = 0;
    
    if (nextTierConfig) {
      const currentMin = activeTierConfig ? activeTierConfig.minSpent : 0;
      const range = nextTierConfig.minSpent - currentMin;
      const spentInRange = totalSpent - currentMin;
      progressPercentage = Math.max(0, Math.min(100, (spentInRange / range) * 100));
      missingAmount = nextTierConfig.minSpent - totalSpent;
    }
    
    return { nextTier: nextTierConfig, progressPercentage, missingAmount, activeTierConfig };
  }, [appUser, rewardsConfig]);

  const [isConfirming, setIsConfirming] = useState<string | null>(null);

  const handleConfirmReceived = async (order: Order) => {
    if (!window.confirm('Xác nhận bạn đã nhận được hàng và hàng hóa nguyên vẹn? Bằng việc xác nhận, bạn đồng ý kết thúc đơn hàng này.')) return;
    
    setIsConfirming(order.id);
    try {
      // 1. Cập nhật trạng thái
      await updateDoc(doc(db, 'orders', order.id), {
        status: 'delivered',
        updatedAt: serverTimestamp()
      });
      
      // 2. Thưởng điểm
      let earnedPoints = 0;
      if (activeTierConfig && rewardsConfig?.pointValueVND) {
        earnedPoints = Math.floor((order.finalAmount || order.totalAmount) / 1000) * (activeTierConfig.pointMultiplier || 1);
      } else {
        earnedPoints = Math.floor((order.finalAmount || order.totalAmount) / 1000); // Mặc định 1 điểm = 1k
      }
      
      await updateDoc(doc(db, 'users', user!.uid), {
        points: increment(earnedPoints),
        totalSpent: increment(order.finalAmount || order.totalAmount)
      });
      
      toast.success(`Cảm ơn bạn! Đã cộng ${earnedPoints} điểm thưởng vào tài khoản.`);

      // Thông báo Telegram
      fetch('/api/notify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'ORDER_DELIVERED',
          payload: {
            orderId: order.id,
            customerName: order.shippingInfo.fullName,
            phone: order.shippingInfo.phone,
            amount: order.finalAmount || order.totalAmount,
            earnedPoints
          }
        })
      }).catch(() => {});
    } catch (error) {
      toast.error('Có lỗi xảy ra khi cập nhật.');
      console.error(error);
    } finally {
      setIsConfirming(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-5 h-5 border-2 border-red-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-16 text-center">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Vui lòng đăng nhập</h1>
        <p className="text-gray-500 dark:text-zinc-400">Bạn cần đăng nhập để xem thông tin.</p>
      </div>
    );
  }

  const tabs = [
    { id: 'overview', label: 'Tổng quan', icon: UserIcon },
    { id: 'orders', label: 'Đơn hàng', icon: ShoppingBag },
    { id: 'vouchers', label: 'Kho Voucher', icon: Ticket },
    { id: 'rewards', label: 'Hạng & Điểm', icon: Trophy },
    { id: 'settings', label: 'Tài khoản', icon: Settings },
  ];

  return (
    <div className="bg-slate-50 dark:bg-zinc-950 min-h-screen pb-24 lg:pb-12">
      {/* Hero Section & Cover */}
      <div className="relative h-48 md:h-64 bg-gradient-to-r from-red-600 to-indigo-700 overflow-hidden">
        <div className="absolute inset-0 bg-black/20" />
        {/* Glow effect */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-white/10 rounded-full blur-3xl" />
      </div>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 -mt-20 relative z-10">
        <div className="flex flex-col md:flex-row md:items-end gap-4 mb-8">
          <div className="relative inline-block w-fit">
            {user.photoURL ? (
              <img src={cloudinaryUrl(user.photoURL, { width: 200, quality: 'auto' })} alt="Avatar" className="w-32 h-32 md:w-40 md:h-40 rounded-full border-4 border-white dark:border-zinc-900 shadow-xl object-cover bg-white" referrerPolicy="no-referrer" />
            ) : (
              <div className="w-32 h-32 md:w-40 md:h-40 rounded-full bg-slate-200 dark:bg-zinc-800 flex items-center justify-center text-slate-500 dark:text-zinc-400 text-4xl font-bold border-4 border-white dark:border-zinc-900 shadow-xl">
                {user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}
              </div>
            )}
            {appUser && activeTierConfig && (
              <div className="absolute bottom-2 right-2 md:bottom-4 md:right-4 bg-gradient-to-r from-amber-400 to-amber-600 text-white text-[10px] sm:text-xs font-black uppercase px-3 py-1 rounded-full shadow-lg border-2 border-white dark:border-zinc-900 flex items-center gap-1 z-10">
                <Star className="w-3 h-3 fill-current" />
                {activeTierConfig.name}
              </div>
            )}
          </div>
          
          <div className="flex-1 md:pb-4 md:pl-4">
            <h1 className="text-2xl md:text-3xl font-black text-gray-900 dark:text-white mb-1 drop-shadow-sm">{user.displayName}</h1>
            <p className="text-gray-600 dark:text-zinc-400 font-medium flex items-center gap-2">
              {user.email} 
              {appUser?.adminPermissions && <span className="inline-flex items-center gap-1 bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider"><ShieldCheck className="w-3 h-3" /> Admin</span>}
            </p>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-2 overflow-x-auto pb-4 mb-4 md:mb-8 custom-scrollbar border-b border-gray-200 dark:border-zinc-800">
          {tabs.map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-4 py-3 rounded-xl font-bold text-sm whitespace-nowrap transition-all ${
                  isActive 
                    ? 'bg-white dark:bg-zinc-900 text-red-600 dark:text-red-500 shadow-sm border border-gray-200 dark:border-zinc-800' 
                    : 'text-gray-500 dark:text-zinc-400 hover:bg-white/50 dark:hover:bg-zinc-900/50 hover:text-gray-900 dark:hover:text-white'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-red-500' : ''}`} /> {tab.label}
              </button>
            )
          })}
        </div>

        {/* Tab Content: OVERVIEW */}
        {activeTab === 'overview' && appUser && (
          <div className="space-y-6 animate-fade-in transition-all">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
              {/* VIP Progress Card */}
              <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl p-6 shadow-sm md:col-span-2 lg:col-span-2 relative overflow-hidden">
                <div className="absolute right-0 top-0 opacity-10 dark:opacity-5 pointer-events-none -mr-10 -mt-10">
                  <Trophy className="w-64 h-64" />
                </div>
                
                <h3 className="text-gray-500 dark:text-zinc-400 font-bold mb-4 flex items-center gap-2 uppercase tracking-tight text-sm">
                  <Trophy className="w-4 h-4 text-amber-500" /> Tiến độ thành viên
                </h3>
                
                <div className="flex items-center gap-4 mb-4">
                  <div className="w-16 h-16 rounded-2xl bg-amber-50 dark:bg-amber-500/10 flex items-center justify-center border border-amber-200 dark:border-amber-500/20 shrink-0">
                    <Star className="w-8 h-8 text-amber-500" />
                  </div>
                  <div>
                    <h2 className="text-2xl sm:text-3xl font-black text-gray-900 dark:text-white uppercase tracking-tight">Hạng {activeTierConfig?.name || appUser.tier}</h2>
                    <p className="text-sm text-gray-600 dark:text-zinc-400 mt-1">Đã tích lũy: <strong className="text-gray-900 dark:text-white font-bold">{(appUser.totalSpent || 0).toLocaleString('vi-VN')}đ</strong></p>
                  </div>
                </div>

                {nextTier ? (
                  <div className="mt-6 relative z-10">
                    <div className="flex justify-between text-xs sm:text-sm font-medium text-gray-600 dark:text-zinc-400 mb-2">
                       <span>Đang ở hạng {activeTierConfig?.name}</span>
                       <span>Cần {(missingAmount).toLocaleString('vi-VN')}đ để lên <strong className="text-amber-500 dark:text-amber-400 uppercase">{nextTier.name}</strong></span>
                    </div>
                    <div className="w-full bg-gray-100 dark:bg-zinc-800 rounded-full h-3 auto overflow-hidden border border-gray-200 dark:border-zinc-700/50">
                      <div 
                        className="bg-gradient-to-r from-amber-400 to-amber-600 h-full rounded-full transition-all duration-1000 ease-out" 
                        style={{ width: `${progressPercentage}%` }}
                      />
                    </div>
                  </div>
                ) : (
                  <div className="mt-6 p-3 bg-emerald-50 dark:bg-emerald-500/10 rounded-xl border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-400 font-medium text-sm">
                    🎉 Xin chúc mừng! Bạn đã đạt mức hạng cao nhất của chúng tôi.
                  </div>
                )}
              </div>

              {/* Points Card */}
              <div className="bg-gradient-to-br from-indigo-500 to-purple-600 rounded-3xl p-6 shadow-md text-white relative overflow-hidden flex flex-col justify-between">
                <div className="absolute right-0 top-0 opacity-20 pointer-events-none -mr-4 -mt-4">
                  <Ticket className="w-32 h-32" />
                </div>
                <div>
                  <h3 className="font-bold flex items-center gap-2 uppercase tracking-tight text-sm text-indigo-100 mb-6">
                    <Ticket className="w-4 h-4" /> Điểm thưởng hiện có
                  </h3>
                  <h2 className="text-4xl font-black drop-shadow-sm truncate">{appUser.points?.toLocaleString() || 0}</h2>
                </div>
                <div className="mt-6 pt-4 border-t border-white/20">
                  <p className="text-xs text-indigo-100">Giá trị quy đổi hiện tại: <span className="font-bold text-white">{(appUser.points * (rewardsConfig?.pointValueVND || 0)).toLocaleString('vi-VN')}đ</span></p>
                </div>
              </div>

              {/* Order Stats Card */}
              <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl p-6 shadow-sm md:col-span-2 lg:col-span-3">
                <h3 className="text-gray-500 dark:text-zinc-400 font-bold mb-6 flex items-center gap-2 uppercase tracking-tight text-sm">
                  <ShoppingBag className="w-4 h-4 text-blue-500" /> Hoạt động mua sắm
                </h3>
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                   <div className="flex items-center gap-4">
                     <div className="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-500/10 flex items-center justify-center border border-blue-200 dark:border-blue-500/20 shrink-0">
                       <TrendingUp className="w-6 h-6 text-blue-500" />
                     </div>
                     <div>
                       <h2 className="text-3xl font-black text-gray-900 dark:text-white uppercase tracking-tight">{appUser.totalOrders || 0}</h2>
                       <p className="text-sm text-gray-600 dark:text-zinc-400 mt-1 font-medium">Đơn hàng thành công</p>
                     </div>
                   </div>
                   {orders.length > 0 && (
                     <div className="w-full md:w-auto">
                       <button onClick={() => setActiveTab('orders')} className="w-full md:w-auto px-6 py-3 rounded-xl border-2 border-gray-100 dark:border-zinc-800 hover:border-gray-300 dark:hover:border-zinc-700 text-sm font-bold text-gray-700 dark:text-zinc-300 transition-colors">
                         Xem lịch sử {orders.length} đơn hàng
                       </button>
                     </div>
                   )}
                </div>
              </div>
            </div>
            
            {/* Recent Orders Sneak Peek */}
            {orders.length > 0 && (
              <div className="mt-8">
                 <div className="flex justify-between items-center mb-4">
                   <h2 className="text-lg font-bold text-gray-900 dark:text-white">Đơn hàng gần đây</h2>
                   <button onClick={() => setActiveTab('orders')} className="text-sm text-blue-500 font-medium hover:underline">Xem lịch sử chi tiết</button>
                 </div>
                 
                 <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-2xl shadow-sm overflow-hidden">
                    {orders.slice(0, 3).map((order) => {
                       const statusConfig = getStatusConfig(order.status);
                       return (
                         <div key={order.id} className="p-4 border-b border-gray-100 dark:border-zinc-800 last:border-0 flex flex-col sm:flex-row justify-between sm:items-center gap-3">
                            <div className="flex items-center gap-4">
                               <div className="w-12 h-12 bg-slate-100 dark:bg-zinc-800 rounded-xl border border-slate-200 dark:border-zinc-700 p-2 shrink-0">
                                  {order.items[0]?.image ? <img src={cloudinaryUrl(order.items[0].image, { width: 80, quality: 'auto:low' })} loading="lazy" decoding="async" className="w-full h-full object-cover rounded" referrerPolicy="no-referrer"/> : <Package className="w-full h-full text-slate-400"/>}
                               </div>
                               <div>
                                 <p className="font-bold text-gray-900 dark:text-white text-sm">#{order.id.slice(-6).toUpperCase()} <span className="font-normal text-gray-500 dark:text-zinc-500 ml-2">{(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')}đ</span></p>
                                 <p className="text-xs text-gray-500 dark:text-zinc-400 mt-1">{order.createdAt?.toDate().toLocaleDateString('vi-VN')} • {order.items.length} sản phẩm</p>
                               </div>
                            </div>
                            <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full border ${statusConfig.bg} ${statusConfig.border} ${statusConfig.color} text-[11px] font-bold w-fit`}>
                               {statusConfig.label}
                            </div>
                         </div>
                       )
                    })}
                 </div>
              </div>
            )}
          </div>
        )}

        {/* Tab Content: ORDERS */}
        {activeTab === 'orders' && (
           <OrderHistory 
             orders={orders}
             getStatusConfig={getStatusConfig}
             isConfirming={isConfirming}
             handleConfirmReceived={handleConfirmReceived}
             paymentConfig={paymentConfig}
           />
        )}

        {/* Tab Content: REWARDS */}
        {activeTab === 'rewards' && (
           <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl p-6 md:p-8 shadow-sm animate-fade-in transition-all">
              <h2 className="text-2xl font-black text-gray-900 dark:text-white mb-8 border-b-2 border-amber-500 pb-2 inline-block">Đặc quyền Thành Viên</h2>
              
              {rewardsConfig?.tiers && (
                 <div className="space-y-8">
                    {/* VIP Progress */}
                    {appUser && activeTierConfig && (
                       <div className="bg-gray-50 dark:bg-zinc-950 p-6 rounded-2xl border border-gray-200 dark:border-zinc-800 relative shadow-sm overflow-hidden mb-12">
                          <h3 className="font-bold text-gray-900 dark:text-white mb-6 uppercase tracking-tight flex items-center gap-2">
                            <Star className="w-5 h-5 text-amber-500"/> Thanh tiến trình
                          </h3>
                          <div className="relative pt-6">
                            <div className="absolute left-0 top-0 w-full flex justify-between px-2 text-xs font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider">
                               <span>{Object.values(rewardsConfig.tiers).sort((a,b)=>a.minSpent - b.minSpent)[0]?.name || 'Khởi điểm'}</span>
                               <span>{Object.values(rewardsConfig.tiers).sort((a,b)=>b.minSpent - a.minSpent)[0]?.name || 'Cao nhất'}</span>
                            </div>
                            <div className="w-full bg-gray-200 dark:bg-zinc-800 rounded-full h-4 overflow-hidden border border-gray-300 dark:border-zinc-700 shadow-inner">
                              <div 
                                className="bg-gradient-to-r from-amber-300 via-amber-500 to-amber-600 h-full rounded-full transition-all duration-1000 ease-out" 
                                style={{ width: `${appUser.totalSpent >= (Object.values(rewardsConfig.tiers).sort((a,b)=>b.minSpent - a.minSpent)[0]?.minSpent || 1) ? 100 : Math.min(100, Math.max(0, (appUser.totalSpent / (Object.values(rewardsConfig.tiers).sort((a,b)=>b.minSpent - a.minSpent)[0]?.minSpent || 1)) * 100)) }%` }}
                              />
                            </div>
                          </div>
                          {nextTier ? (
                             <p className="mt-4 text-center text-sm font-medium text-gray-600 dark:text-zinc-400 bg-white dark:bg-zinc-900 py-2 rounded-xl border border-gray-200 dark:border-zinc-800">
                               Cần mua sắm thêm <strong className="text-gray-900 dark:text-white">{(missingAmount).toLocaleString('vi-VN')}đ</strong> để mở khóa hạng <strong className="text-amber-500 uppercase">{nextTier.name}</strong>
                             </p>
                          ) : (
                             <p className="mt-4 text-center text-sm font-medium text-emerald-600 dark:text-emerald-500 bg-emerald-50 dark:bg-emerald-500/10 py-2 rounded-xl border border-emerald-200 dark:border-emerald-500/20">
                               🎉 Bạn đã mở khóa mức hạng cao nhất! Hãy tận hưởng các đặc quyền tối đa.
                             </p>
                          )}
                       </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                       {Object.values(rewardsConfig.tiers).sort((a, b) => a.minSpent - b.minSpent).map(tier => {
                          const isActive = appUser?.tier === tier.tierId;
                          return (
                             <div key={tier.tierId} className={`relative p-6 rounded-3xl border-2 transition-all ${isActive ? 'border-amber-500 bg-amber-50/50 dark:bg-amber-500/10 shadow-md transform md:-translate-y-2' : 'border-gray-200 dark:border-zinc-800 bg-white dark:bg-zinc-900'}`}>
                               {isActive && (
                                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-amber-500 text-white text-[10px] sm:text-xs font-black uppercase px-3 py-1 rounded-full shadow-sm">
                                     Hạng Của Bạn
                                  </div>
                               )}
                               <h3 className="text-center text-xl font-black text-gray-900 dark:text-white uppercase mb-2 mt-2">{tier.name}</h3>
                               <p className="text-center text-sm font-bold text-gray-500 dark:text-zinc-400 mb-6">Mốc: {tier.minSpent.toLocaleString('vi-VN')}đ</p>
                               
                               <div className="bg-gray-50 dark:bg-zinc-950 p-4 rounded-2xl border border-gray-100 dark:border-zinc-800 mb-6 text-center">
                                  <span className="block text-xs font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider mb-1">Tích lũy</span>
                                  <span className="text-2xl font-black text-emerald-600 dark:text-emerald-500">x{tier.pointMultiplier}</span>
                               </div>

                               <ul className="space-y-3">
                                  {tier.benefits?.map((b, i) => (
                                     <li key={i} className="flex gap-2 text-sm text-gray-700 dark:text-zinc-300 font-medium">
                                        <CheckCircle className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                                        <span className="leading-snug">{b}</span>
                                     </li>
                                  ))}
                               </ul>
                             </div>
                          );
                       })}
                    </div>
                 </div>
              )}
           </div>
        )}

        {/* Tab Content: VOUCHERS */}
        {activeTab === 'vouchers' && (
           <div className="animate-fade-in transition-all">
              <VoucherCenter />
           </div>
        )}
        {/* Tab Content: SETTINGS */}
        {activeTab === 'settings' && (
           <UserSettings user={user} logout={logout} />
        )}

      </div>
    </div>
  );
}
