import React, { useState, useMemo } from 'react';
import { Package, Clock, CheckCircle, Truck, XCircle, Copy, ChevronDown, ChevronUp, QrCode } from 'lucide-react';
import { toast } from 'sonner';
import { Order, TierConfig } from '../../types';
import { cloudinaryUrl } from '../../utils/cloudinaryUrl';

interface OrderHistoryProps {
  orders: Order[];
  getStatusConfig: (status: Order['status']) => { icon: React.ElementType, color: string, bg: string, border: string, label: string };
  isConfirming: string | null;
  handleConfirmReceived: (order: Order) => void;
  paymentConfig: any;
}

export default function OrderHistory({
  orders,
  getStatusConfig,
  isConfirming,
  handleConfirmReceived,
  paymentConfig
}: OrderHistoryProps) {
  const [orderFilter, setOrderFilter] = useState<'all' | 'pending' | 'shipping' | 'delivered'>('all');
  const [expandedPaymentOrderId, setExpandedPaymentOrderId] = useState<string | null>(null);

  const filteredOrders = useMemo(() => {
    if (orderFilter === 'all') return orders;
    if (orderFilter === 'pending') return orders.filter(o => o.status === 'pending' || o.status === 'processing');
    if (orderFilter === 'shipping') return orders.filter(o => o.status === 'shipped');
    if (orderFilter === 'delivered') return orders.filter(o => o.status === 'delivered');
    return orders;
  }, [orders, orderFilter]);

  return (
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
           <Package className="w-12 h-12 mx-auto text-gray-300 dark:text-zinc-700 mb-4" />
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
               : `https://spx.vn/track?\${order.trackingCode}`;
             
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
                   <div className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-full border \${statusConfig.bg} \${statusConfig.border} \${statusConfig.color} text-xs font-bold w-fit`}>
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
                           <img src={cloudinaryUrl(item.image, { width: 100, quality: 'auto:low' })} alt={item.name} loading="lazy" decoding="async" className="w-20 h-20 sm:w-24 sm:h-24 object-cover rounded-xl border border-gray-100 dark:border-zinc-800 shadow-sm" referrerPolicy="no-referrer" />
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
                               src={`https://img.vietqr.io/image/\${paymentConfig.bankId}-\${paymentConfig.accountNumber}-\${paymentConfig.template}.png?amount=\${order.finalAmount || order.totalAmount}&addInfo=\${order.id}&accountName=\${encodeURIComponent(paymentConfig.accountName)}`} 
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
                         className={`w-full sm:w-auto px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold transition-all shadow-md shadow-emerald-500/20 whitespace-nowrap \${isConfirming === order.id ? 'opacity-70 cursor-not-allowed' : ''}`}
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
  );
}
