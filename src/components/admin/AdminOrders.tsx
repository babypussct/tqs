import React, { useState } from 'react';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { ShoppingBag, ChevronRight, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { useOrders } from '../../utils/useOrders';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { Order } from '../../types';

export default function AdminOrders() {
  const { orders, loading, updateOrderStatus, deleteOrder } = useOrders();
  const [trackingInputs, setTrackingInputs] = useState<Record<string, string>>({});
  const [editingTracking, setEditingTracking] = useState<Record<string, boolean>>({});

  const handleTrackingSave = async (orderId: string) => {
    let code = trackingInputs[orderId]?.trim();
    if (!code) return;

    if (code.includes('spx.vn/track?')) {
      code = code.split('spx.vn/track?')[1].split('&')[0];
    } else if (code.startsWith('http')) {
      const match = code.match(/(SPX[A-Z0-9]+)/i);
      if (match) code = match[1];
    }

    try {
      await updateDoc(doc(db, 'orders', orderId), { trackingCode: code });
      setEditingTracking(prev => ({ ...prev, [orderId]: false }));
      toast.success('Đã lưu mã vận đơn');
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `orders/${orderId}`);
      toast.error('Có lỗi xảy ra khi lưu mã vận đơn');
    }
  };

  const handleTrackingDelete = async (orderId: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa mã vận đơn này?')) {
      try {
        await updateDoc(doc(db, 'orders', orderId), { trackingCode: null });
        toast.success('Đã xóa mã vận đơn');
      } catch (error) {
        handleFirestoreError(error, OperationType.UPDATE, `orders/${orderId}`);
        toast.error('Có lỗi xảy ra khi xóa mã vận đơn');
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[40vh]">
        <div className="text-slate-500 flex items-center gap-3 font-medium">
          <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
          Đang tải dữ liệu đơn hàng...
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-slate-200 dark:divide-zinc-800 text-sm text-left">
          <thead className="bg-slate-50 dark:bg-zinc-900/50">
            <tr>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Mã đơn</th>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Khách hàng</th>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Sản phẩm</th>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Thanh toán</th>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Trạng thái</th>
              <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-right">Tác vụ</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-zinc-800">
            {orders.map((order) => (
              <tr key={order.id} className="hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-colors align-top">
                <td className="px-6 py-4">
                  <div className="font-mono text-xs font-semibold text-slate-700 dark:text-zinc-300 bg-slate-100 dark:bg-zinc-800 px-2 py-1 rounded inline-block">
                    #{order.id.slice(-6).toUpperCase()}
                  </div>
                  <div className="text-xs text-slate-400 mt-2">
                    {order.createdAt?.toDate().toLocaleDateString('vi-VN')}
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="font-medium text-slate-900 dark:text-slate-100">{order.shippingInfo.fullName}</div>
                  <div className="text-xs text-slate-500 mt-1">{order.shippingInfo.phone}</div>
                  <button 
                    onClick={() => {
                      const alertStr = `Chi tiết:\nKhách: ${order.shippingInfo.fullName}\nSĐT: ${order.shippingInfo.phone}\nĐịa chỉ: ${order.shippingInfo.address}\nGhi chú: ${order.shippingInfo.notes || 'Không có'}`;
                      alert(alertStr);
                    }}
                    className="text-xs text-indigo-600 dark:text-indigo-400 mt-2 hover:underline inline-flex items-center gap-1"
                  >
                    Xem địa chỉ <ChevronRight className="w-3 h-3" />
                  </button>
                </td>
                <td className="px-6 py-4 max-w-[200px]">
                  <div className="text-slate-900 dark:text-slate-100 font-medium mb-1">{order.items.length} món</div>
                  {order.items.slice(0, 2).map((item, i) => (
                    <div key={i} className="text-xs text-slate-500 truncate">- {item.name} (x{item.quantity})</div>
                  ))}
                  {order.items.length > 2 && <div className="text-xs text-slate-400 italic">...và {order.items.length - 2} món khác</div>}
                </td>
                <td className="px-6 py-4">
                  <div className="font-semibold text-slate-900 dark:text-slate-100">
                    {(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')} đ
                  </div>
                  {order.paymentMethod === 'vietqr' ? (
                    <div className="mt-2">
                      {order.paymentStatus === 'pending' ? (
                        <div className="flex flex-col gap-1 items-start">
                          <span className="inline-flex items-center px-2 py-1 rounded bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/20 text-[10px] font-medium">Chờ CKQR</span>
                          <button
                            onClick={async () => {
                              try {
                                await updateDoc(doc(db, 'orders', order.id), { paymentStatus: 'paid' });
                                toast.success('Đã xác nhận thanh toán');
                              } catch (error) { toast.error('Lỗi khi xác nhận thanh toán'); }
                            }}
                            className="text-[10px] bg-slate-800 hover:bg-slate-900 dark:bg-slate-100 dark:hover:bg-white dark:text-slate-900 text-white px-2 py-1 rounded transition-colors"
                          >Xác nhận Đã Nhận Tiền</button>
                        </div>
                      ) : (
                        <span className="inline-flex items-center px-2 py-1 rounded bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20 text-[10px] font-medium">Đã thanh toán (QR)</span>
                      )}
                    </div>
                  ) : (
                    <div className="mt-2 text-[10px] text-slate-500 border border-slate-200 dark:border-zinc-700 rounded px-2 py-1 inline-block bg-slate-50 dark:bg-zinc-800">
                      Thanh toán COD
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  <select
                    value={order.status}
                    onChange={(e) => {
                      const newStatus = e.target.value as Order['status'];
                      updateOrderStatus(order, newStatus);
                    }}
                    className={`text-xs font-semibold px-2 py-1 rounded border outline-none cursor-pointer appearance-none ${
                        order.status === 'suspicious' ? 'bg-red-50 text-red-700 border-red-200' :
                        order.status === 'failed_delivery' ? 'bg-rose-50 text-rose-700 border-rose-200' :
                        order.status === 'returned' ? 'bg-orange-50 text-orange-700 border-orange-200' :
                        order.status === 'refunded' ? 'bg-pink-50 text-pink-700 border-pink-200' :
                        order.status === 'pending' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                        order.status === 'processing' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                        order.status === 'shipped' ? 'bg-purple-50 text-purple-700 border-purple-200' :
                        order.status === 'delivered' ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                      'bg-slate-50 text-slate-700 border-slate-200'
                    }`}
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
                  {(order as any).riskScore !== undefined && (order as any).riskScore >= 40 && (
                    <div className={`mt-2 text-[10px] font-semibold px-2 py-0.5 rounded inline-flex ${
                      (order as any).riskScore >= 60
                        ? 'bg-red-100 text-red-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}>
                      Risk: {(order as any).riskScore}/100
                    </div>
                  )}
                </td>
                <td className="px-6 py-4 text-right align-top">
                  <div className="flex flex-col h-full items-end gap-3">
                    <div className="w-full flex justify-end">
                      {order.trackingCode && !editingTracking[order.id] ? (
                        <div className="flex flex-col items-end gap-1">
                          <span className="text-xs font-mono bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 px-2 py-1 rounded max-w-[150px] truncate" title={order.trackingCode}>
                            {order.trackingCode.includes('spx.vn/track?') ? order.trackingCode.split('spx.vn/track?')[1].split('&')[0] : order.trackingCode}
                          </span>
                          <div className="flex items-center gap-2 mt-1">
                            <button onClick={() => { setTrackingInputs(prev => ({ ...prev, [order.id]: order.trackingCode! })); setEditingTracking(prev => ({ ...prev, [order.id]: true })); }} className="text-[10px] text-indigo-600 hover:text-indigo-700 font-medium">Sửa mã</button>
                            <button onClick={() => handleTrackingDelete(order.id)} className="text-[10px] text-red-600 hover:text-red-700 font-medium">Xóa</button>
                          </div>
                        </div>
                      ) : (
                        <div className="flex flex-col items-end gap-1">
                          <input
                            type="text"
                            placeholder="Mã vận đơn..."
                            value={trackingInputs[order.id] || ''}
                            onChange={(e) => setTrackingInputs(prev => ({ ...prev, [order.id]: e.target.value }))}
                            className="border border-slate-300 dark:border-zinc-700 rounded px-2 py-1 text-xs w-32 bg-white dark:bg-zinc-800 text-slate-900 dark:text-white focus:ring-1 focus:ring-indigo-500 outline-none"
                          />
                          <div className="flex gap-1 mt-1">
                            {editingTracking[order.id] && (
                              <button onClick={() => setEditingTracking(prev => ({ ...prev, [order.id]: false }))} className="bg-slate-200 dark:bg-zinc-700 hover:bg-slate-300 dark:hover:bg-zinc-600 text-slate-700 dark:text-slate-300 px-2 py-1 rounded text-[10px] font-medium">Hủy</button>
                            )}
                            <button onClick={() => handleTrackingSave(order.id)} disabled={!trackingInputs[order.id]?.trim()} className="bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white px-2 py-1 rounded text-[10px] font-medium">Lưu</button>
                          </div>
                        </div>
                      )}
                    </div>
                    
                    <button
                      onClick={() => {
                        if (window.confirm('CẢNH BÁO: Xoá đơn hàng này sẽ làm mất toàn bộ dữ liệu đơn hàng và thu hồi lại điểm nếu đã giao thành công. Bạn có chắc chắn muốn xoá vĩnh viễn?')) {
                          deleteOrder(order);
                        }
                      }}
                      className="mt-auto text-[10px] flex items-center gap-1 text-slate-400 hover:text-red-600 transition-colors bg-white dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 px-2 py-1 rounded shadow-sm opacity-50 hover:opacity-100"
                      title="Xoá vĩnh viễn đơn hàng"
                    >
                      <Trash2 className="w-3 h-3" /> Xoá Đơn
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {orders.length === 0 && (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-slate-500 dark:text-zinc-500">
                  <ShoppingBag className="w-10 h-10 mx-auto mb-3 text-slate-300 dark:text-zinc-700" />
                  <p>Chưa có đơn hàng nào.</p>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
