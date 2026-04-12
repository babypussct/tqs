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

export default function Profile() {
  const { user, logout } = useAuth();
  const { paymentConfig } = usePaymentConfig();
  const { config: rewardsConfig } = useRewardsConfig();
  const [orders, setOrders] = useState<Order[]>([]);
  const [appUser, setAppUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [expandedPaymentOrderId, setExpandedPaymentOrderId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'orders' | 'rewards' | 'vouchers' | 'settings'>('overview');
  const [orderFilter, setOrderFilter] = useState<'all' | 'pending' | 'shipping' | 'delivered'>('all');

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

  const filteredOrders = useMemo(() => {
    if (orderFilter === 'all') return orders;
    if (orderFilter === 'pending') return orders.filter(o => o.status === 'pending' || o.status === 'processing');
    if (orderFilter === 'shipping') return orders.filter(o => o.status === 'shipped');
    if (orderFilter === 'delivered') return orders.filter(o => o.status === 'delivered');
    return orders;
  }, [orders, orderFilter]);

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
              <img src={user.photoURL} alt="Avatar" className="w-32 h-32 md:w-40 md:h-40 rounded-full border-4 border-white dark:border-zinc-900 shadow-xl object-cover bg-white" referrerPolicy="no-referrer" />
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
                                  {order.items[0]?.image ? <img src={order.items[0].image} className="w-full h-full object-cover rounded" referrerPolicy="no-referrer"/> : <Package className="w-full h-full text-slate-400"/>}
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
          <div className="space-y-6 animate-fade-in transition-all">
             {/* Filter Bar */}
             <div className="flex gap-2 pb-2 overflow-x-auto custom-scrollbar">
                {(['all', 'pending', 'shipping', 'delivered'] as const).map(f => (
                   <button 
                     key={f}
                     onClick={() => setOrderFilter(f)}
                     className={`px-4 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-all ${orderFilter === f ? 'bg-gray-900 dark:bg-white text-white dark:text-zinc-900' : 'bg-white dark:bg-zinc-900 text-gray-600 dark:text-zinc-400 border border-gray-200 dark:border-zinc-800 hover:border-gray-400'}`}
                   >
                     {f === 'all' && 'Tất cả đơn'}
                     {f === 'pending' && 'Chờ xử lý'}
                     {f === 'shipping' && 'Đang giao'}
                     {f === 'delivered' && 'Hoàn thành'}
                   </button>
                ))}
             </div>

             {filteredOrders.length === 0 ? (
               <div className="text-center py-16 bg-white dark:bg-zinc-900 rounded-3xl border border-gray-200 dark:border-zinc-800 shadow-sm">
                 <ShoppingBag className="w-12 h-12 mx-auto text-gray-300 dark:text-zinc-700 mb-4" />
                 <p className="text-gray-500 dark:text-zinc-400 font-medium">Chưa có đơn hàng nào trong danh mục này.</p>
               </div>
             ) : (
               <div className="space-y-6">
                 {filteredOrders.map((order) => {
                   const statusConfig = getStatusConfig(order.status);
                   const StatusIcon = statusConfig.icon;
                   
                   const displayTrackingCode = order.trackingCode?.includes('spx.vn/track?') 
                     ? order.trackingCode.split('spx.vn/track?')[1].split('&')[0] 
                     : order.trackingCode?.startsWith('http') 
                       ? (order.trackingCode.match(/(SPX[A-Z0-9]+)/i)?.[1] || 'Link Vận Đơn') 
                       : order.trackingCode;

                   const trackingUrl = order.trackingCode?.startsWith('http') 
                     ? order.trackingCode 
                     : `https://spx.vn/track?${order.trackingCode}`;
                   
                   return (
                     <div key={order.id} className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl overflow-hidden shadow-sm hover:shadow-md transition-shadow">
                       <div className="bg-gray-50 dark:bg-zinc-950/50 p-4 sm:p-5 border-b border-gray-200 dark:border-zinc-800 flex flex-col sm:flex-row justify-between gap-4">
                         <div>
                           <p className="text-sm text-gray-500 dark:text-zinc-400 mb-1">
                             Mã đơn: <span className="font-mono text-gray-900 dark:text-white font-bold text-base">#{order.id.slice(-6).toUpperCase()}</span>
                           </p>
                           <p className="text-xs font-medium text-gray-500 dark:text-zinc-400">
                             Đặt lúc {order.createdAt?.toDate().toLocaleTimeString('vi-VN')} ngày {order.createdAt?.toDate().toLocaleDateString('vi-VN')}
                           </p>
                         </div>
                         <div className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-full border ${statusConfig.bg} ${statusConfig.border} ${statusConfig.color} text-xs font-bold w-fit`}>
                           <StatusIcon className="w-4 h-4" />
                           {statusConfig.label}
                         </div>
                       </div>
                       
                       <div className="p-4 sm:p-6">
                         {order.trackingCode && order.status !== 'cancelled' && (
                           <div className="bg-blue-50 dark:bg-blue-900/20 p-4 sm:p-5 rounded-2xl mb-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border border-blue-100 dark:border-blue-800/30">
                             <div>
                               <p className="text-sm text-blue-800 dark:text-blue-300 font-bold mb-1">Mã vận đơn SPX Express</p>
                               <div className="flex items-center gap-3">
                                 <span 
                                   className="font-mono font-black text-xl text-blue-900 dark:text-blue-100" 
                                   title={displayTrackingCode}
                                 >
                                   {displayTrackingCode}
                                 </span>
                               </div>
                             </div>
                             <div className="flex items-center gap-2 w-full sm:w-auto">
                               {displayTrackingCode && displayTrackingCode !== 'Link Vận Đơn' && (
                                   <button 
                                     onClick={() => { navigator.clipboard.writeText(displayTrackingCode); toast.success('Đã copy mã'); }}
                                     className="flex-1 sm:flex-none border border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-400 bg-white dark:bg-zinc-900 hover:bg-blue-100 dark:hover:bg-blue-900/50 px-4 py-2.5 rounded-xl font-bold text-sm transition-colors text-center"
                                   >
                                     Copy
                                   </button>
                               )}
                               <a 
                                 href={trackingUrl}
                                 target="_blank"
                                 rel="noopener noreferrer"
                                 className="flex-1 sm:flex-none bg-blue-600 hover:bg-blue-700 text-white px-6 py-2.5 rounded-xl font-bold text-sm transition-colors text-center shadow-lg shadow-blue-600/20"
                               >
                                 Tra cứu ngay
                               </a>
                             </div>
                           </div>
                         )}
                         
                         <div className="space-y-4 mb-6">
                           {order.items.map((item, index) => (
                             <div key={index} className="flex gap-4">
                               {item.image ? (
                                 <img src={item.image} alt={item.name} className="w-20 h-20 sm:w-24 sm:h-24 object-cover rounded-xl border border-gray-100 dark:border-zinc-800 shadow-sm" referrerPolicy="no-referrer" />
                               ) : (
                                 <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-xl border border-gray-100 dark:border-zinc-800 flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs shadow-sm bg-gray-50 dark:bg-zinc-950">Img</div>
                               )}
                               <div className="flex-1 min-w-0">
                                 <h4 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white line-clamp-2 mb-1 leading-snug">{item.name}</h4>
                                 <div className="text-xs text-gray-500 dark:text-zinc-400 space-y-0.5 font-medium">
                                   {item.selectedLang && <div>Ngôn ngữ: {item.selectedLang}</div>}
                                   {item.selectedBox && <div>Loại hộp: {item.selectedBox}</div>}
                                   {item.selectedVariants && Object.entries(item.selectedVariants).map(([k, v]) => (
                                     <div key={k}>{k}: {v}</div>
                                   ))}
                                   {item.quickAddAccessoryNames?.map(name => (
                                     <div key={name} className="text-emerald-600 dark:text-emerald-500">+ {name}</div>
                                   ))}
                                   {item.addSleeves && !item.quickAddAccessoryNames && <div className="text-emerald-600 dark:text-emerald-500">+ {(item as any).quickAddAccessoryName || '200 Sleeves'}</div>}
                                 </div>
                               </div>
                               <div className="text-right shrink-0">
                                 <p className="text-sm sm:text-base font-black text-gray-900 dark:text-white">{item.price.toLocaleString('vi-VN')}đ</p>
                                 <p className="text-xs font-bold text-red-500 dark:text-red-400 bg-red-50 dark:bg-red-500/10 px-2 py-0.5 rounded inline-block mt-1">x{item.quantity}</p>
                               </div>
                             </div>
                           ))}
                         </div>
                         
                         <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end pt-5 border-t border-gray-100 dark:border-zinc-800 gap-6">
                           <div className="text-sm text-gray-500 dark:text-zinc-400 bg-gray-50 dark:bg-zinc-950 p-4 rounded-2xl border border-gray-100 dark:border-zinc-800 w-full sm:w-auto">
                             <div className="mb-2">
                               <span className="font-bold text-gray-900 dark:text-white block mb-1 uppercase tracking-tight text-xs">Người nhận</span>
                               <span className="font-medium text-gray-800 dark:text-gray-200">{order.shippingInfo.fullName} • {order.shippingInfo.phone}</span>
                             </div>
                             <div className="mb-2">
                               <span className="font-bold text-gray-900 dark:text-white block mb-1 uppercase tracking-tight text-xs">Địa chỉ giao</span>
                               <span className="line-clamp-2" title={order.shippingInfo.address}>{order.shippingInfo.address}</span>
                             </div>
                             <div>
                               <span className="font-bold text-gray-900 dark:text-white block mb-1 uppercase tracking-tight text-xs">Thanh toán</span>
                               {order.paymentMethod === 'vietqr' ? (
                                 <span className="flex items-center gap-1.5 font-medium">
                                   Chuyển khoản VietQR
                                   {order.paymentStatus === 'pending' ? (
                                     <span className="px-2 py-0.5 bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-500 text-[10px] rounded font-bold uppercase tracking-wide">Chờ duyệt</span>
                                   ) : (
                                     <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 dark:bg-emerald-500/20 dark:text-emerald-500 text-[10px] rounded font-bold uppercase tracking-wide">Đã trả</span>
                                   )}
                                 </span>
                               ) : (
                                 <span className="font-medium">Thanh toán tiền mặt (COD)</span>
                               )}
                             </div>
                           </div>
                           
                           <div className="w-full sm:w-auto mt-auto">
                             <div className="space-y-2 mb-3">
                               <div className="flex justify-between sm:justify-end gap-6 text-sm text-gray-500 dark:text-zinc-400 font-medium">
                                 <span>Tạm tính:</span>
                                 <span>{order.totalAmount.toLocaleString('vi-VN')}đ</span>
                               </div>
                               {order.discountAmount ? (
                                 <div className="flex justify-between sm:justify-end gap-6 text-sm text-emerald-600 dark:text-emerald-500 font-bold">
                                   <span>Giảm giá:</span>
                                   <span>-{order.discountAmount.toLocaleString('vi-VN')}đ</span>
                                 </div>
                               ) : null}
                             </div>
                             <div className="flex justify-between sm:justify-end gap-6 items-center border-t border-gray-100 dark:border-zinc-800 pt-3">
                               <span className="font-bold text-gray-900 dark:text-white uppercase tracking-tight text-sm">Thành tiền</span>
                               <span className="text-2xl font-black text-red-600 dark:text-red-500">
                                 {(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')}đ
                               </span>
                             </div>
                           </div>
                         </div>

                         {/* Render Retry QR Payment Section */}
                         {order.paymentMethod === 'vietqr' && order.paymentStatus === 'pending' && paymentConfig && paymentConfig.isActive && order.status !== 'cancelled' && (
                           <div className="mt-6 border-2 border-emerald-500/30 rounded-2xl overflow-hidden shadow-sm">
                             <button 
                               onClick={() => setExpandedPaymentOrderId(expandedPaymentOrderId === order.id ? null : order.id)}
                               className="w-full bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:hover:bg-emerald-500/20 p-4 sm:p-5 transition-colors flex items-center justify-between"
                             >
                               <div className="flex items-center gap-3">
                                 <div className="p-2.5 bg-emerald-500 text-white shadow-md shadow-emerald-500/30 rounded-xl">
                                   <QrCode className="w-5 h-5" />
                                 </div>
                                 <div className="text-left">
                                   <h4 className="text-base font-black text-emerald-900 dark:text-emerald-400">Hoàn tất thanh toán đơn hàng</h4>
                                   <p className="text-xs sm:text-sm font-medium text-emerald-700 dark:text-emerald-600 mt-0.5">Nhấp vào đây để xem mã QR chuyển khoản</p>
                                 </div>
                               </div>
                               {expandedPaymentOrderId === order.id ? <ChevronUp className="w-5 h-5 text-emerald-600" /> : <ChevronDown className="w-5 h-5 text-emerald-600" />}
                             </button>
                             
                             {expandedPaymentOrderId === order.id && (
                               <div className="p-4 sm:p-6 bg-white dark:bg-zinc-900 border-t border-emerald-500/30 flex flex-col md:flex-row items-center gap-6 md:gap-8 animate-fade-in">
                                 <div className="bg-white p-3 rounded-2xl border border-gray-200 dark:border-zinc-800 shadow-sm shrink-0 mx-auto md:mx-0">
                                   <img 
                                     src={`https://img.vietqr.io/image/${paymentConfig.bankId}-${paymentConfig.accountNumber}-${paymentConfig.template}.png?amount=${order.finalAmount || order.totalAmount}&addInfo=${order.id}&accountName=${encodeURIComponent(paymentConfig.accountName)}`} 
                                     alt="VietQR" 
                                     className="w-48 h-48 sm:w-56 sm:h-56 object-contain rounded-xl"
                                   />
                                 </div>
                                 
                                 <div className="flex-1 w-full bg-gray-50 dark:bg-zinc-950 p-4 sm:p-6 rounded-2xl border border-gray-100 dark:border-zinc-800 space-y-4">
                                   <div className="flex items-center justify-between">
                                     <span className="text-sm font-medium text-gray-500 dark:text-zinc-400">Ngân hàng:</span>
                                     <span className="font-black text-gray-900 dark:text-white uppercase">{paymentConfig.bankId}</span>
                                   </div>
                                   <div className="flex items-center justify-between group">
                                     <span className="text-sm font-medium text-gray-500 dark:text-zinc-400">Số tài khoản:</span>
                                     <div className="flex items-center gap-2">
                                       <span className="font-mono font-black text-gray-900 dark:text-white text-lg lg:text-xl">{paymentConfig.accountNumber}</span>
                                       <button onClick={() => { navigator.clipboard.writeText(paymentConfig.accountNumber); toast.success('Đã copy số tài khoản'); }} className="p-1.5 text-gray-400 hover:text-emerald-600 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-lg shadow-sm transition-colors">
                                         <Copy className="w-4 h-4" />
                                       </button>
                                     </div>
                                   </div>
                                   <div className="flex items-center justify-between group">
                                     <span className="text-sm font-medium text-gray-500 dark:text-zinc-400">Mã đơn (Nội dung):</span>
                                     <div className="flex items-center gap-2">
                                       <span className="font-mono font-black text-blue-600 dark:text-blue-400">{order.id}</span>
                                       <button onClick={() => { navigator.clipboard.writeText(order.id); toast.success('Đã copy nội dung'); }} className="p-1.5 text-gray-400 hover:text-blue-600 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-lg shadow-sm transition-colors">
                                         <Copy className="w-4 h-4" />
                                       </button>
                                     </div>
                                   </div>
                                   <div className="flex items-center justify-between group">
                                     <span className="text-sm font-medium text-gray-500 dark:text-zinc-400">Số tiền:</span>
                                     <div className="flex items-center gap-2">
                                       <span className="font-black text-red-600 dark:text-red-500 text-lg lg:text-xl">{(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')} đ</span>
                                       <button onClick={() => { navigator.clipboard.writeText((order.finalAmount || order.totalAmount).toString()); toast.success('Đã copy số tiền'); }} className="p-1.5 text-gray-400 hover:text-red-600 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-lg shadow-sm transition-colors">
                                         <Copy className="w-4 h-4" />
                                       </button>
                                     </div>
                                   </div>
                                   <div className="mt-4 pt-4 border-t border-gray-200 dark:border-zinc-800">
                                      <p className="text-xs sm:text-sm text-gray-600 dark:text-zinc-400 leading-relaxed font-medium">
                                        {paymentConfig.paymentNote}
                                      </p>
                                   </div>
                                 </div>
                               </div>
                             )}
                           </div>
                         )}
                         {/* Render Receive confirmation if Shipped */}
                         {order.status === 'shipped' && (
                           <div className="mt-6 border border-emerald-200 dark:border-emerald-500/20 bg-emerald-50/50 dark:bg-emerald-500/5 rounded-2xl p-4 sm:p-5 flex flex-col sm:flex-row items-center justify-between gap-4">
                             <div>
                               <h4 className="font-bold text-gray-900 dark:text-white mb-1">Kiện hàng đã đến nơi?</h4>
                               <p className="text-xs sm:text-sm text-gray-600 dark:text-zinc-400">Vui lòng xác nhận khi bạn đã nhận đủ hàng để nhận ngay điểm thưởng.</p>
                             </div>
                             <button
                               onClick={() => handleConfirmReceived(order)}
                               disabled={isConfirming === order.id}
                               className={`w-full sm:w-auto px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold transition-all shadow-md shadow-emerald-500/20 whitespace-nowrap ${isConfirming === order.id ? 'opacity-70 cursor-not-allowed' : ''}`}
                             >
                               {isConfirming === order.id ? 'Đang xử lý...' : 'Xác nhận Đã nhận hàng'}
                             </button>
                           </div>
                         )}
                       </div>
                     </div>
                   );
                 })}
               </div>
             )}
          </div>
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
           <div className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl p-6 md:p-8 shadow-sm max-w-2xl animate-fade-in transition-all">
              <h2 className="text-2xl font-black text-gray-900 dark:text-white mb-6 border-b border-gray-200 dark:border-zinc-800 pb-4">Tài khoản & Thiết lập</h2>
              
              <div className="space-y-4">
                 <div className="p-4 border border-gray-200 dark:border-zinc-800 rounded-2xl flex items-center justify-between">
                    <div>
                       <h3 className="font-bold text-gray-900 dark:text-white">Email Đăng nhập</h3>
                       <p className="text-sm font-medium text-gray-500 dark:text-zinc-400 mt-1">{user.email}</p>
                    </div>
                    <div className="hidden sm:block text-xs font-bold bg-gray-100 dark:bg-zinc-800 text-gray-500 px-3 py-1 rounded-full uppercase tracking-wider">
                       Bảo mật qua Google
                    </div>
                 </div>
                 
                 <div className="pt-8">
                    <button 
                       onClick={() => {
                          if (window.confirm('Bạn có chắc chắn muốn đăng xuất?')) {
                             logout().then(() => {
                                toast.success('Đã đăng xuất thành công');
                             });
                          }
                       }}
                       className="w-full sm:w-auto flex items-center justify-center gap-2 bg-red-50 hover:bg-red-100 dark:bg-red-500/10 dark:hover:bg-red-500/20 text-red-600 dark:text-red-500 px-6 py-3.5 rounded-xl font-bold transition-colors border-2 border-red-100 dark:border-red-500/20"
                    >
                       <LogOut className="w-5 h-5" />
                       Đăng xuất khỏi thiết bị này
                    </button>
                    <p className="text-sm text-gray-500 dark:text-zinc-400 mt-4 font-medium text-center sm:text-left">Để bảo vệ thông tin cá nhân, vui lòng đăng xuất khi sử dụng thiết bị công cộng.</p>
                 </div>
              </div>
           </div>
        )}

      </div>
    </div>
  );
}
