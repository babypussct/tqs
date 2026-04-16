import React, { useState } from 'react';
import { Order } from '../../types';
import { X, Phone, MessageCircle, Package, Truck, Receipt, CheckCircle, CreditCard, Box, AlertTriangle, Coins } from 'lucide-react';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { toast } from 'sonner';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';

interface AdminOrderDetailModalProps {
  order: Order;
  onClose: () => void;
  updateOrderStatus: (order: Order, status: Order['status']) => Promise<void>;
}

export default function AdminOrderDetailModal({ order, onClose, updateOrderStatus }: AdminOrderDetailModalProps) {
  const [trackingInput, setTrackingInput] = useState<string>(order.trackingCode || '');
  const [isSavingTracking, setIsSavingTracking] = useState(false);

  // Status mapping
  const statusColors = {
    suspicious: 'bg-red-50 text-red-700 border-red-200',
    pending: 'bg-amber-50 text-amber-700 border-amber-200',
    processing: 'bg-blue-50 text-blue-700 border-blue-200',
    shipped: 'bg-purple-50 text-purple-700 border-purple-200',
    delivered: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    failed_delivery: 'bg-rose-50 text-rose-700 border-rose-200',
    returned: 'bg-orange-50 text-orange-700 border-orange-200',
    refunded: 'bg-pink-50 text-pink-700 border-pink-200',
    cancelled: 'bg-slate-50 text-slate-700 border-slate-200'
  };

  const handleTrackingSave = async () => {
    let code = trackingInput.trim();
    if (!code) return;

    if (code.includes('spx.vn/track?')) {
      code = code.split('spx.vn/track?')[1].split('&')[0];
    } else if (code.startsWith('http')) {
      const match = code.match(/(SPX[A-Z0-9]+)/i);
      if (match) code = match[1];
    }

    setIsSavingTracking(true);
    try {
      await updateDoc(doc(db, 'orders', order.id), { trackingCode: code });
      // Cập nhật lại UI state (bằng cách order list ngoài kia sẽ tự fetch hoặc cập nhật local)
      toast.success('Đã lưu mã vận đơn');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `orders/${order.id}`);
      toast.error('Có lỗi xảy ra khi lưu mã vận đơn');
    } finally {
      setIsSavingTracking(false);
    }
  };

  const handlePaymentConfirm = async () => {
    try {
      await updateDoc(doc(db, 'orders', order.id), { paymentStatus: 'paid' });
      toast.success('Đã xác nhận lấy tiền vào tài khoản!');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `orders/${order.id}`);
      toast.error('Lỗi khi xác nhận thanh toán');
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div 
        className="bg-white dark:bg-zinc-900 rounded-2xl w-full max-w-5xl max-h-[90vh] overflow-y-auto flex flex-col shadow-2xl relative animate-in fade-in zoom-in-95 duration-200 border border-slate-200 dark:border-zinc-800"
        onClick={(e) => e.stopPropagation()}
      >
        {/* HEADER */}
        <div className="sticky top-0 z-10 bg-white/80 dark:bg-zinc-900/80 backdrop-blur-md px-6 py-4 border-b border-slate-100 dark:border-zinc-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-indigo-50 dark:bg-indigo-500/10 p-2 rounded-lg">
              <Receipt className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                Chi tiết đơn hàng {order.id.slice(-6).toUpperCase()}
                {(order as any).riskScore >= 40 && (
                  <span className={`text-[10px] uppercase font-bold px-1.5 py-0.5 rounded flex items-center gap-1 ${
                    (order as any).riskScore >= 60 ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-800'
                  }`}>
                    <AlertTriangle className="w-3 h-3" /> Risk {(order as any).riskScore}
                  </span>
                )}
              </h2>
              <div className="text-sm text-slate-500 dark:text-zinc-400">
                 {order.createdAt?.toDate().toLocaleString('vi-VN')}
              </div>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-zinc-800 dark:hover:text-zinc-300 rounded-full transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* CONTENT */}
        <div className="p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* COLUMN 1: Customer Info & Status Actions */}
          <div className="lg:col-span-1 space-y-6">
            
            {/* Action Center */}
            <div className="bg-slate-50 dark:bg-zinc-800/50 rounded-xl p-5 border border-slate-100 dark:border-zinc-700/50 space-y-4">
               <div>
                  <label className="block text-sm font-semibold text-slate-700 dark:text-zinc-300 mb-2 flex items-center gap-2">
                     <Package className="w-4 h-4" /> Trạng thái đơn hàng
                  </label>
                  <select
                    value={order.status}
                    onChange={(e) => updateOrderStatus(order, e.target.value as Order['status'])}
                    className={`w-full text-sm font-bold px-3 py-2.5 rounded-lg outline-none cursor-pointer appearance-none transition-colors border shadow-sm ${statusColors[order.status]}`}
                  >
                    <option value="suspicious">⚠ Nghi ngờ</option>
                    <option value="pending">Chờ xử lý</option>
                    <option value="processing">Đang chuẩn bị</option>
                    <option value="shipped">Đang giao</option>
                    <option value="delivered">Đã giao</option>
                    <option value="failed_delivery">Giao thất bại</option>
                    <option value="returned">Đã hoàn hàng</option>
                    <option value="refunded">Đã hoàn tiền</option>
                    <option value="cancelled">Đã hủy</option>
                  </select>
               </div>

               <div>
                 <label className="block text-sm font-semibold text-slate-700 dark:text-zinc-300 mb-2 flex items-center gap-2">
                     <Truck className="w-4 h-4" /> Mã vận đơn
                  </label>
                  <div className="flex gap-2">
                     <input 
                        type="text"
                        placeholder="VD: SPX..."
                        value={trackingInput}
                        onChange={(e) => setTrackingInput(e.target.value)}
                        className="flex-1 bg-white dark:bg-zinc-900 border border-slate-300 dark:border-zinc-600 rounded-lg px-3 py-2 text-sm text-slate-900 dark:text-white outline-none focus:ring-2 focus:ring-indigo-500"
                     />
                     <button
                        onClick={handleTrackingSave}
                        disabled={isSavingTracking || trackingInput.trim() === (order.trackingCode || '')}
                        className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 dark:disabled:bg-zinc-700 disabled:text-slate-500 dark:disabled:text-zinc-500 text-white px-3 py-2 rounded-lg text-sm font-medium transition-colors"
                     >
                        Lưu
                     </button>
                  </div>
               </div>
            </div>

            {/* Shipping Info */}
            <div className="bg-white dark:bg-zinc-800/30 rounded-xl p-5 border border-slate-200 dark:border-zinc-700/50">
               <h3 className="text-sm font-bold text-slate-900 dark:text-white uppercase tracking-wider mb-4 flex items-center gap-2">
                 Thông tin Khách hàng
               </h3>
               <div className="space-y-3">
                  <div>
                    <div className="text-[11px] text-slate-500 dark:text-zinc-400 font-medium uppercase mb-0.5">Họ và tên</div>
                    <div className="font-semibold text-slate-900 dark:text-slate-100">{order.shippingInfo.fullName}</div>
                  </div>
                  
                  <div className="flex flex-col gap-1.5 md:flex-row md:items-center justify-between">
                    <div>
                      <div className="text-[11px] text-slate-500 dark:text-zinc-400 font-medium uppercase mb-0.5">Số điện thoại</div>
                      <div className="font-semibold text-slate-900 dark:text-slate-100">{order.shippingInfo.phone}</div>
                    </div>
                    <div className="flex gap-2">
                        <a href={`tel:${order.shippingInfo.phone}`} className="bg-blue-50 hover:bg-blue-100 text-blue-600 dark:bg-blue-500/10 dark:hover:bg-blue-500/20 px-2 py-1.5 rounded-md flex items-center justify-center transition-colors">
                          <Phone className="w-4 h-4" />
                        </a>
                        <a href={`https://zalo.me/${order.shippingInfo.phone.replace(/[^0-9]/g, '')}`} target="_blank" rel="noopener noreferrer" className="bg-indigo-50 hover:bg-indigo-100 text-indigo-600 dark:bg-indigo-500/10 dark:hover:bg-indigo-500/20 px-2 py-1.5 rounded-md flex items-center justify-center transition-colors">
                          <MessageCircle className="w-4 h-4" />
                        </a>
                    </div>
                  </div>

                  <div>
                     <div className="text-[11px] text-slate-500 dark:text-zinc-400 font-medium uppercase mb-0.5">Địa chỉ giao hàng</div>
                     <div className="bg-slate-50 dark:bg-zinc-900/50 p-2.5 rounded-lg border border-slate-100 dark:border-zinc-800 text-sm text-slate-700 dark:text-zinc-300">
                        {order.shippingInfo.address}
                     </div>
                  </div>

                  {order.shippingInfo.notes && (
                    <div>
                       <div className="text-[11px] text-slate-500 dark:text-zinc-400 font-medium uppercase mb-0.5">Ghi chú của khách</div>
                       <div className="bg-amber-50 dark:bg-amber-500/10 p-2.5 rounded-lg border border-amber-100 dark:border-amber-500/20 text-sm italic text-amber-800 dark:text-amber-400">
                          "{order.shippingInfo.notes}"
                       </div>
                    </div>
                  )}
               </div>
            </div>

          </div>

          {/* COLUMN 2: Line Items & Summary */}
          <div className="lg:col-span-2 space-y-6">
            
            {/* Products List */}
            <div className="bg-white dark:bg-zinc-800/30 rounded-xl border border-slate-200 dark:border-zinc-700/50 overflow-hidden">
               <h3 className="bg-slate-50 dark:bg-zinc-900/50 px-5 py-3 text-sm font-bold text-slate-900 dark:text-white border-b border-slate-200 dark:border-zinc-800 flex items-center justify-between">
                 <span>Danh sách Sản phẩm</span>
                 <span className="bg-indigo-100 text-indigo-800 dark:bg-indigo-500/20 dark:text-indigo-300 px-2 py-0.5 rounded-full text-xs">{order.items.length} mặt hàng</span>
               </h3>
               
               <div className="divide-y divide-slate-100 dark:divide-zinc-800 max-h-[300px] overflow-y-auto">
                 {order.items.map((item, index) => (
                   <div key={index} className="px-5 py-4 flex items-start gap-4 hover:bg-slate-50/50 dark:hover:bg-zinc-800/50 transition-colors">
                     <div className="w-16 h-16 bg-slate-100 dark:bg-zinc-900 rounded-lg overflow-hidden flex-shrink-0 border border-slate-200 dark:border-zinc-700">
                        <img 
                          src={item.image || 'https://via.placeholder.com/150'} 
                          alt={item.name}
                          className="w-full h-full object-cover"
                          onError={(e) => { (e.target as HTMLImageElement).src = 'https://via.placeholder.com/150' }}
                        />
                     </div>
                     <div className="flex-1 min-w-0">
                       <h4 className="font-semibold text-slate-900 dark:text-white text-sm line-clamp-2">{item.name}</h4>
                       
                       {/* Variants Breakdown */}
                       <div className="mt-1 space-y-0.5">
                         {item.selectedBox && (
                           <div className="text-[11px] text-slate-500 dark:text-zinc-400 flex items-center gap-1">
                             <Box className="w-3 h-3" /> Loại: <span className="font-medium text-slate-700 dark:text-zinc-300">{item.selectedBox}</span>
                           </div>
                         )}
                         {item.selectedLang && (
                           <div className="text-[11px] text-slate-500 dark:text-zinc-400 flex items-center gap-1">
                             <span className="w-3 text-center">🌍</span> Ngôn ngữ: <span className="font-medium text-slate-700 dark:text-zinc-300">{item.selectedLang}</span>
                           </div>
                         )}
                         {item.selectedVariants && Object.entries(item.selectedVariants).map(([key, rawValue]) => {
                           const vName = rawValue.split(':')[0]; // remove price adjustment string if exists
                           return (
                             <div key={key} className="text-[11px] text-slate-500 dark:text-zinc-400 flex items-center gap-1">
                               <span className="w-3 text-center">•</span> {key}: <span className="font-medium text-slate-700 dark:text-zinc-300">{vName}</span>
                             </div>
                           );
                         })}
                         {item.addSleeves && (
                           <div className="text-[11px] text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                             <span className="w-3 text-center">+</span> Kèm Bọc Bài Bọt Biển (Sleeves)
                           </div>
                         )}
                         {item.quickAddAccessoryNames && item.quickAddAccessoryNames.length > 0 && (
                           <div className="text-[11px] text-indigo-600 dark:text-indigo-400 flex items-start gap-1">
                             <span className="w-3 text-center mt-0.5">+</span>
                             <div className="flex-1">
                               Mua kèm: {item.quickAddAccessoryNames.join(', ')}
                             </div>
                           </div>
                         )}
                       </div>

                     </div>
                     
                     <div className="text-right flex-shrink-0 ml-4">
                        <div className="font-bold text-slate-900 dark:text-white text-sm">{(item.price * item.quantity).toLocaleString('vi-VN')} đ</div>
                        <div className="text-[11px] text-slate-500">
                          {item.price.toLocaleString('vi-VN')} đ x {item.quantity}
                        </div>
                     </div>
                   </div>
                 ))}
               </div>
            </div>

            {/* Financial Summary */}
            <div className="bg-slate-50 dark:bg-zinc-800/50 rounded-xl p-5 border border-slate-200 dark:border-zinc-700/50">
               <h3 className="text-sm font-bold text-slate-900 dark:text-white mb-4 pb-2 border-b border-slate-200 dark:border-zinc-700">Tổng kết Tài chính</h3>
               
               <div className="space-y-2.5 text-sm">
                  <div className="flex justify-between items-center text-slate-600 dark:text-zinc-300">
                    <span>Tổng tiền hàng</span>
                    <span className="font-medium">{order.totalAmount.toLocaleString('vi-VN')} đ</span>
                  </div>
                  
                  {order.shippingFee !== undefined && (
                    <div className="flex justify-between items-center text-slate-600 dark:text-zinc-300">
                      <span>Phí vận chuyển</span>
                      <span className="font-medium">{order.shippingFee === 0 ? 'Miễn phí' : `${order.shippingFee.toLocaleString('vi-VN')} đ`}</span>
                    </div>
                  )}

                  {order.discountAmount !== undefined && order.discountAmount > 0 && (
                    <div className="flex justify-between items-center text-emerald-600 dark:text-emerald-400">
                       <span className="flex items-center gap-1">
                          Ưu đãi {order.discountCode && <span className="bg-emerald-100 text-emerald-800 dark:bg-emerald-500/20 dark:text-emerald-300 px-1.5 py-0.5 rounded text-[10px] uppercase font-bold">{order.discountCode}</span>}
                       </span>
                       <span className="font-medium">- {order.discountAmount.toLocaleString('vi-VN')} đ</span>
                    </div>
                  )}

                  <div className="pt-3 border-t border-slate-200 dark:border-zinc-700 flex justify-between items-center">
                    <span className="font-bold text-slate-900 dark:text-white">Thành tiền cần thanh toán</span>
                    <span className="font-black text-lg text-indigo-600 dark:text-indigo-400">
                      {((order.finalAmount !== undefined ? order.finalAmount : order.totalAmount) || 0).toLocaleString('vi-VN')} đ
                    </span>
                  </div>

                  {order.earnedPoints ? (
                    <div className="mt-2 text-[11px] flex justify-end text-slate-500 dark:text-zinc-400">
                      Khách được cộng +{order.earnedPoints} điểm
                    </div>
                  ) : null}
               </div>

               {/* Payment Method Badge */}
               <div className="mt-5 pt-4 border-t border-slate-200 dark:border-zinc-700">
                  <div className="flex items-center justify-between mb-3">
                     <span className="text-xs font-semibold text-slate-500 uppercase">Hình thức thanh toán</span>
                     {order.paymentMethod === 'vietqr' ? (
                       <span className="inline-flex items-center gap-1 bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 px-2 py-1 rounded text-xs font-bold border border-indigo-200 dark:border-indigo-500/20">
                         <CreditCard className="w-3.5 h-3.5" /> Chuyển khoản QR
                       </span>
                     ) : (
                       <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-slate-300 px-2 py-1 rounded text-xs font-bold border border-slate-200 dark:border-zinc-700">
                         <Receipt className="w-3.5 h-3.5" /> Thanh toán khi nhận hàng (COD)
                       </span>
                     )}
                  </div>
                  
                  {order.paymentMethod === 'vietqr' && (
                    <div className="flex flex-col sm:flex-row items-center justify-between p-3 rounded-lg bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 gap-3">
                       <div className="flex items-center gap-2 w-full sm:w-auto">
                         {order.paymentStatus === 'paid' ? (
                           <CheckCircle className="w-5 h-5 text-emerald-500" />
                         ) : (
                           <div className="w-5 h-5 rounded-full border-2 border-amber-500 border-t-transparent animate-spin"></div>
                         )}
                         <span className={`text-sm font-semibold ${order.paymentStatus === 'paid' ? 'text-emerald-700 dark:text-emerald-400' : 'text-amber-700 dark:text-amber-400'}`}>
                           {order.paymentStatus === 'paid' ? 'Khách đã thanh toán' : 'Đang chờ khách thanh toán QR'}
                         </span>
                       </div>
                       
                       {order.paymentStatus === 'pending' && (
                         <button 
                            onClick={handlePaymentConfirm}
                            className="w-full sm:w-auto bg-slate-900 hover:bg-slate-800 dark:bg-white dark:hover:bg-slate-100 text-white dark:text-slate-900 px-4 py-2 rounded-lg text-sm font-bold shadow-md transition-all"
                         >
                            ✅ Xác nhận Đã Nhận Tiền
                         </button>
                       )}
                    </div>
                  )}
               </div>

            </div>

          </div>

        </div>
      </div>
    </div>
  );
}
