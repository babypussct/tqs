import React, { useState, useEffect } from 'react';
import { collection, query, where, orderBy, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { Order } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Package, Clock, CheckCircle, Truck, XCircle, ShoppingBag } from 'lucide-react';
import { toast } from 'sonner';

export default function Profile() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

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
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
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

    return () => unsubscribe();
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
        return { icon: XCircle, color: 'text-red-500', bg: 'bg-red-50 dark:bg-red-500/10', border: 'border-red-200 dark:border-red-500/20', label: 'Đã hủy' };
      default:
        return { icon: Clock, color: 'text-gray-500', bg: 'bg-gray-50 dark:bg-zinc-800', border: 'border-gray-200 dark:border-zinc-700', label: 'Không rõ' };
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
        <p className="text-gray-500 dark:text-zinc-400">Bạn cần đăng nhập để xem lịch sử đơn hàng.</p>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="flex items-center gap-4 mb-8">
        {user.photoURL ? (
          <img src={user.photoURL} alt="Avatar" className="w-16 h-16 rounded-full border-2 border-gray-200 dark:border-zinc-700" referrerPolicy="no-referrer" />
        ) : (
          <div className="w-16 h-16 rounded-full bg-gray-200 dark:bg-zinc-700 flex items-center justify-center text-gray-500 dark:text-zinc-400 text-2xl font-bold border-2 border-gray-200 dark:border-zinc-700">
            {user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}
          </div>
        )}
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{user.displayName}</h1>
          <p className="text-gray-500 dark:text-zinc-400">{user.email}</p>
        </div>
      </div>

      <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 md:p-8">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
          <ShoppingBag className="w-5 h-5 text-red-500" /> Lịch sử đơn hàng
        </h2>

        {orders.length === 0 ? (
          <div className="text-center py-12">
            <ShoppingBag className="w-12 h-12 mx-auto text-gray-300 dark:text-zinc-700 mb-4" />
            <p className="text-gray-500 dark:text-zinc-400">Bạn chưa có đơn hàng nào.</p>
          </div>
        ) : (
          <div className="space-y-6">
            {orders.map((order) => {
              const statusConfig = getStatusConfig(order.status);
              const StatusIcon = statusConfig.icon;
              
              return (
                <div key={order.id} className="border border-gray-200 dark:border-zinc-800 rounded-xl overflow-hidden">
                  <div className="bg-gray-50 dark:bg-zinc-900/80 p-4 sm:px-6 border-b border-gray-200 dark:border-zinc-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                      <p className="text-sm text-gray-500 dark:text-zinc-400 mb-1">
                        Mã đơn: <span className="font-mono text-gray-900 dark:text-white font-medium">#{order.id.slice(-6).toUpperCase()}</span>
                      </p>
                      <p className="text-sm text-gray-500 dark:text-zinc-400">
                        Ngày đặt: {order.createdAt?.toDate().toLocaleDateString('vi-VN')} {order.createdAt?.toDate().toLocaleTimeString('vi-VN')}
                      </p>
                    </div>
                    <div className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border ${statusConfig.bg} ${statusConfig.border} ${statusConfig.color} text-sm font-medium w-fit`}>
                      <StatusIcon className="w-4 h-4" />
                      {statusConfig.label}
                    </div>
                  </div>
                  
                  <div className="p-4 sm:p-6">
                    {order.trackingCode && (
                      <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-xl mb-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border border-blue-100 dark:border-blue-800/30">
                        <div>
                          <p className="text-sm text-blue-800 dark:text-blue-300 font-medium mb-1">Mã vận đơn SPX:</p>
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-lg font-bold text-blue-900 dark:text-blue-100">{order.trackingCode}</span>
                            <button 
                              onClick={() => {
                                navigator.clipboard.writeText(order.trackingCode!);
                                toast.success('Đã copy mã vận đơn');
                              }}
                              className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm underline"
                            >
                              Copy
                            </button>
                          </div>
                        </div>
                        <a 
                          href={`https://spx.vn/track?${order.trackingCode}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white px-6 py-2.5 rounded-lg font-medium transition-colors text-center shadow-sm shadow-blue-600/20"
                        >
                          Tra cứu hành trình
                        </a>
                      </div>
                    )}
                    
                    <div className="space-y-4 mb-6">
                      {order.items.map((item, index) => (
                        <div key={index} className="flex gap-4">
                          {item.image ? (
                            <img src={item.image} alt={item.name} className="w-16 h-16 object-cover rounded-lg border border-gray-100 dark:border-zinc-800" referrerPolicy="no-referrer" />
                          ) : (
                            <div className="w-16 h-16 rounded-lg border border-gray-100 dark:border-zinc-800 flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                          )}
                          <div className="flex-1">
                            <h4 className="text-sm font-medium text-gray-900 dark:text-white line-clamp-2 mb-1">{item.name}</h4>
                            <div className="text-xs text-gray-500 dark:text-zinc-400 space-y-0.5">
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
                          <div className="text-right">
                            <p className="text-sm font-medium text-gray-900 dark:text-white">{item.price.toLocaleString('vi-VN')}đ</p>
                            <p className="text-xs text-gray-500 dark:text-zinc-400">x{item.quantity}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                    
                    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center pt-4 border-t border-gray-100 dark:border-zinc-800 gap-4">
                      <div className="text-sm text-gray-500 dark:text-zinc-400">
                        <p><span className="font-medium text-gray-900 dark:text-white">Giao đến:</span> {order.shippingInfo.fullName} - {order.shippingInfo.phone}</p>
                        <p className="mt-0.5">{order.shippingInfo.address}</p>
                        <div className="mt-2 flex items-center gap-2">
                          <span className="font-medium text-gray-900 dark:text-white">Thanh toán:</span>
                          {order.paymentMethod === 'vietqr' ? (
                            <span className="flex items-center gap-1">
                              Chuyển khoản VietQR
                              {order.paymentStatus === 'pending' ? (
                                <span className="px-2 py-0.5 bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-500 text-[10px] rounded-full font-medium">Chờ xác nhận</span>
                              ) : (
                                <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 dark:bg-emerald-500/20 dark:text-emerald-500 text-[10px] rounded-full font-medium">Đã thanh toán</span>
                              )}
                            </span>
                          ) : (
                            <span>Thanh toán khi nhận hàng (COD)</span>
                          )}
                        </div>
                      </div>
                      <div className="text-right w-full sm:w-auto">
                        <div className="space-y-1 mb-2">
                          <div className="flex justify-between sm:justify-end gap-4 text-sm text-gray-500 dark:text-zinc-400">
                            <span>Tạm tính:</span>
                            <span>{order.totalAmount.toLocaleString('vi-VN')}đ</span>
                          </div>
                          {order.discountCode && (
                            <div className="flex justify-between sm:justify-end gap-4 text-sm text-emerald-600 dark:text-emerald-500 font-medium">
                              <span>Giảm giá ({order.discountCode}):</span>
                              <span>-{order.discountAmount?.toLocaleString('vi-VN')}đ</span>
                            </div>
                          )}
                        </div>
                        <div className="flex justify-between sm:justify-end gap-4 items-center border-t border-gray-100 dark:border-zinc-800 pt-2">
                          <span className="text-sm font-medium text-gray-900 dark:text-white">Tổng tiền:</span>
                          <span className="text-xl font-bold text-red-600 dark:text-red-500">
                            {(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')}đ
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
