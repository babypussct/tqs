import React, { useState, useMemo, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useProducts } from '../hooks/useProducts';
import { useHomepage } from '../hooks/useHomepage';
import { useOrders } from '../utils/useOrders';
import { Product, HomepageConfig, Order } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Plus, Edit, Trash2, X, Save, Package, TrendingUp, ShoppingBag, Search, Tag, Image as ImageIcon, Box, AlertCircle, LayoutTemplate, Clock, CheckCircle, Truck, XCircle, Ticket, LayoutDashboard, Palette, Settings } from 'lucide-react';
import { toast } from 'sonner';
import AdminDiscountCodes from './admin/AdminDiscountCodes';
import AdminSettings from './AdminSettings';
import AdminHeroEditor from './admin/AdminHeroEditor';
import { useProductConfig } from '../hooks/useProductConfig';

export default function AdminDashboard() {
  const { products, loading: productsLoading } = useProducts(false); // Fetch all including inactive
  const { config: initialConfig, loading: configLoading } = useHomepage();
  const { config: productConfig } = useProductConfig();
  const { orders, loading: ordersLoading, updateOrderStatus } = useOrders();
  const navigate = useNavigate();
  
  const [activeTab, setActiveTab] = useState<'overview' | 'products' | 'orders' | 'homepage' | 'discounts' | 'settings'>('products');
  const [searchTerm, setSearchTerm] = useState('');
  const [trackingInputs, setTrackingInputs] = useState<Record<string, string>>({});
  const [editingTracking, setEditingTracking] = useState<Record<string, boolean>>({});
  
  const [homeConfig, setHomeConfig] = useState<HomepageConfig>(initialConfig);

  const handleTrackingSave = async (orderId: string) => {
    let code = trackingInputs[orderId]?.trim();
    if (!code) return;

    // Extract SPX tracking code if user pasted the full tracking URL
    if (code.includes('spx.vn/track?')) {
      code = code.split('spx.vn/track?')[1].split('&')[0];
    } else if (code.startsWith('http')) {
      // Fallback matching logic for other ways code might be in a URL
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

  useEffect(() => {
    setHomeConfig(initialConfig);
  }, [initialConfig]);

  const loading = productsLoading || configLoading || ordersLoading;

  // Stats calculation
  const stats = useMemo(() => {
    const total = products.length;
    const active = products.filter(p => p.isActive).length;
    const outOfStock = products.filter(p => p.stock === 0).length;
    return { total, active, outOfStock };
  }, [products]);

  const filteredProducts = useMemo(() => {
    return products.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()));
  }, [products, searchTerm]);

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa sản phẩm này? Hành động này không thể hoàn tác.')) {
      try {
        await deleteDoc(doc(db, 'products', id));
        toast.success('Đã xóa sản phẩm');
      } catch (error) {
        handleFirestoreError(error, OperationType.DELETE, `products/${id}`);
        toast.error('Có lỗi xảy ra khi xóa sản phẩm');
      }
    }
  };

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="text-gray-500 dark:text-zinc-400 flex items-center gap-3">
        <div className="w-5 h-5 border-2 border-red-600 border-t-transparent rounded-full animate-spin"></div>
        Đang tải dữ liệu quản trị...
      </div>
    </div>
  );

  return (
    <div className="flex flex-col md:flex-row min-h-[calc(100vh-73px)] bg-gray-50 dark:bg-zinc-950">
      {/* Sidebar */}
      <aside className="w-full md:w-64 bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-800 shrink-0">
        <div className="sticky top-[73px] p-6">
          <h2 className="text-xl font-black text-gray-900 dark:text-white tracking-tight mb-6">Quản trị</h2>
          <nav className="space-y-1.5">
            {[
              { id: 'overview', label: 'Tổng quan', icon: LayoutDashboard },
              { id: 'products', label: 'Sản phẩm', icon: Package },
              { id: 'orders', label: 'Đơn hàng', icon: ShoppingBag },
              { id: 'homepage', label: 'Giao diện', icon: Palette },
              { id: 'discounts', label: 'Mã giảm giá', icon: Ticket },
              { id: 'settings', label: 'Cấu hình', icon: Settings },
            ].map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-500'
                      : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 hover:text-gray-900 dark:hover:text-white'
                  }`}
                >
                  <Icon className="w-5 h-5" /> {tab.label}
                </button>
              );
            })}
          </nav>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6 md:p-10 overflow-x-hidden">
        <div className="max-w-6xl mx-auto">
          {/* Tab Content: Overview */}
      {activeTab === 'overview' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
              <div className="flex items-center gap-4 mb-4">
                <div className="p-3 bg-blue-500/10 text-blue-500 rounded-xl">
                  <Package className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500 dark:text-zinc-400">Tổng sản phẩm</p>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{stats.total}</h3>
                </div>
              </div>
            </div>
            <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
              <div className="flex items-center gap-4 mb-4">
                <div className="p-3 bg-emerald-500/10 text-emerald-500 rounded-xl">
                  <ShoppingBag className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500 dark:text-zinc-400">Đang mở bán</p>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{stats.active}</h3>
                </div>
              </div>
            </div>
            <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
              <div className="flex items-center gap-4 mb-4">
                <div className="p-3 bg-amber-500/10 text-amber-500 rounded-xl">
                  <AlertCircle className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500 dark:text-zinc-400">Hết hàng</p>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{stats.outOfStock}</h3>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-white dark:bg-zinc-900/30 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-12 text-center">
            <TrendingUp className="w-12 h-12 text-gray-300 dark:text-zinc-700 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-700 dark:text-zinc-300 mb-2">Biểu đồ doanh thu</h3>
            <p className="text-gray-500 dark:text-zinc-500">Tính năng thống kê doanh thu sẽ sớm được cập nhật khi có dữ liệu đơn hàng thực tế.</p>
          </div>
        </div>
      )}

      {/* Tab Content: Products */}
      {activeTab === 'products' && (
        <div className="space-y-6">
          {/* Toolbar */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div className="relative w-full sm:w-96">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500 dark:text-zinc-500" />
              <input 
                type="text" 
                placeholder="Tìm kiếm sản phẩm..." 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800 rounded-xl pl-10 pr-4 py-2.5 text-sm text-gray-900 dark:text-white focus:outline-none focus:border-red-500 transition-colors"
              />
            </div>
            <button 
              onClick={() => navigate('/admin/product/new')} 
              className="w-full sm:w-auto bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 rounded-xl flex items-center justify-center gap-2 font-medium transition-colors shadow-lg shadow-red-600/20"
            >
              <Plus className="w-5 h-5" /> Thêm Sản phẩm
            </button>
          </div>

          {/* Product List */}
          <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="bg-gray-50 dark:bg-zinc-900/80 text-gray-500 dark:text-zinc-400 border-b border-gray-200 dark:border-zinc-800/50">
                  <tr>
                    <th className="px-6 py-4 font-medium">Sản phẩm</th>
                    <th className="px-6 py-4 font-medium">Giá bán</th>
                    <th className="px-6 py-4 font-medium">Kho</th>
                    <th className="px-6 py-4 font-medium">Trạng thái</th>
                    <th className="px-6 py-4 font-medium text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-zinc-800/50">
                  {filteredProducts.map(p => (
                    <tr key={p.id} className="hover:bg-gray-50 dark:hover:bg-zinc-800/30 transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 rounded-lg bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 overflow-hidden shrink-0">
                            {p.image ? (
                              <img src={p.image} alt={p.name} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                            ) : (
                              <ImageIcon className="w-6 h-6 text-gray-400 dark:text-zinc-600 m-auto mt-3" />
                            )}
                          </div>
                          <div>
                            <p className="font-medium text-gray-900 dark:text-white line-clamp-1">{p.name}</p>
                            <div className="flex items-center gap-2 mt-1">
                              <span className="text-xs text-gray-500 dark:text-zinc-500 capitalize">{p.type}</span>
                              {p.badge && <span className="text-[10px] px-1.5 py-0.5 rounded bg-gray-100 dark:bg-zinc-800 text-gray-700 dark:text-zinc-300">{p.badge}</span>}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-medium text-gray-900 dark:text-white">{p.price.toLocaleString('vi-VN')}đ</div>
                        {p.originalPrice && <div className="text-xs text-gray-500 dark:text-zinc-500 line-through">{p.originalPrice.toLocaleString('vi-VN')}đ</div>}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`font-medium ${p.stock === 0 ? 'text-red-400' : 'text-gray-700 dark:text-zinc-300'}`}>
                          {p.stock !== undefined ? p.stock : '∞'}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                          p.isActive 
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' 
                            : 'bg-gray-100 dark:bg-zinc-800 text-gray-500 dark:text-zinc-400 border-gray-300 dark:border-zinc-700'
                        }`}>
                          {p.isActive ? 'Đang bán' : 'Đã ẩn'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button onClick={() => navigate('/admin/product/' + p.id)} className="p-2 text-gray-500 dark:text-zinc-400 hover:text-blue-400 hover:bg-blue-400/10 rounded-lg transition-colors" title="Sửa">
                            <Edit className="w-4 h-4" />
                          </button>
                          <button onClick={() => handleDelete(p.id)} className="p-2 text-gray-500 dark:text-zinc-400 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-colors" title="Xóa">
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                  {filteredProducts.length === 0 && (
                    <tr>
                      <td colSpan={5} className="px-6 py-12 text-center text-gray-500 dark:text-zinc-500">
                        <Package className="w-12 h-12 mx-auto mb-3 text-gray-300 dark:text-zinc-700" />
                        <p>Không tìm thấy sản phẩm nào.</p>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab Content: Orders */}
      {activeTab === 'orders' && (
        <div className="bg-white dark:bg-zinc-900/30 border border-gray-200 dark:border-zinc-800/50 rounded-2xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 dark:bg-zinc-900/80 border-b border-gray-200 dark:border-zinc-800/50 text-sm font-medium text-gray-500 dark:text-zinc-400">
                  <th className="px-6 py-4">Mã Đơn</th>
                  <th className="px-6 py-4">Khách hàng</th>
                  <th className="px-6 py-4">Sản phẩm</th>
                  <th className="px-6 py-4">Tổng tiền</th>
                  <th className="px-6 py-4">Trạng thái</th>
                  <th className="px-6 py-4">Ngày đặt</th>
                  <th className="px-6 py-4 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-zinc-800/50">
                {orders.map((order) => (
                  <tr key={order.id} className="hover:bg-gray-50 dark:hover:bg-zinc-800/30 transition-colors group">
                    <td className="px-6 py-4 text-sm font-mono text-gray-500 dark:text-zinc-400">
                      #{order.id.slice(-6).toUpperCase()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900 dark:text-white">{order.shippingInfo.fullName}</div>
                      <div className="text-xs text-gray-500 dark:text-zinc-400">{order.shippingInfo.phone}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900 dark:text-white">{order.items.length} sản phẩm</div>
                      <div className="text-xs text-gray-500 dark:text-zinc-400 truncate max-w-[200px]">
                        {order.items.map(item => item.name).join(', ')}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-red-600 dark:text-red-500">
                      {(order.finalAmount || order.totalAmount).toLocaleString('vi-VN')}đ
                      {order.discountCode && (
                        <div className="text-xs font-normal text-emerald-600 dark:text-emerald-500 mt-0.5">
                          Mã: {order.discountCode}
                        </div>
                      )}
                      {order.paymentMethod === 'vietqr' ? (
                        <div className="mt-2">
                          {order.paymentStatus === 'pending' ? (
                            <div className="flex flex-col gap-1">
                              <span className="inline-block px-2 py-1 bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-500 text-[10px] font-bold rounded-full w-fit">
                                Chờ chuyển khoản
                              </span>
                              <button
                                onClick={async () => {
                                  try {
                                    await updateDoc(doc(db, 'orders', order.id), { paymentStatus: 'paid' });
                                    toast.success('Đã xác nhận thanh toán');
                                  } catch (error) {
                                    handleFirestoreError(error, OperationType.UPDATE, `orders/${order.id}`);
                                    toast.error('Lỗi khi xác nhận thanh toán');
                                  }
                                }}
                                className="text-[10px] bg-emerald-500 hover:bg-emerald-600 text-white px-2 py-1 rounded transition-colors w-fit"
                              >
                                Xác nhận đã nhận
                              </button>
                            </div>
                          ) : (
                            <span className="inline-block px-2 py-1 bg-emerald-100 text-emerald-800 dark:bg-emerald-500/20 dark:text-emerald-500 text-[10px] font-bold rounded-full w-fit">
                              Đã thanh toán
                            </span>
                          )}
                        </div>
                      ) : (
                        <div className="mt-2">
                          <span className="inline-block px-2 py-1 bg-gray-100 text-gray-800 dark:bg-zinc-800 dark:text-zinc-400 text-[10px] font-bold rounded-full w-fit">
                            Thanh toán COD
                          </span>
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <select
                        value={order.status}
                        onChange={(e) => {
                          updateOrderStatus(order.id, e.target.value as Order['status']);
                        }}
                        className={`text-xs font-medium px-2.5 py-1 rounded-full border outline-none cursor-pointer ${
                          order.status === 'pending' ? 'bg-amber-50 text-amber-600 border-amber-200 dark:bg-amber-500/10 dark:text-amber-500 dark:border-amber-500/20' :
                          order.status === 'processing' ? 'bg-blue-50 text-blue-600 border-blue-200 dark:bg-blue-500/10 dark:text-blue-500 dark:border-blue-500/20' :
                          order.status === 'shipped' ? 'bg-purple-50 text-purple-600 border-purple-200 dark:bg-purple-500/10 dark:text-purple-500 dark:border-purple-500/20' :
                          order.status === 'delivered' ? 'bg-emerald-50 text-emerald-600 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-500 dark:border-emerald-500/20' :
                          'bg-gray-50 text-gray-600 border-gray-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700'
                        }`}
                      >
                        <option value="pending">Chờ xử lý</option>
                        <option value="processing">Đang chuẩn bị</option>
                        <option value="shipped">Đang giao</option>
                        <option value="delivered">Đã giao</option>
                        <option value="cancelled">Đã hủy</option>
                      </select>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500 dark:text-zinc-400">
                      {order.createdAt?.toDate().toLocaleDateString('vi-VN')}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button 
                        onClick={() => {
                          const discountInfo = order.discountCode ? `\nMã giảm giá: ${order.discountCode} (-${order.discountAmount?.toLocaleString('vi-VN')}đ)` : '';
                          const finalTotal = order.finalAmount || order.totalAmount;
                          const itemsList = order.items.map(i => {
                            let details = [];
                            if (i.selectedBox) details.push(`Hộp: ${i.selectedBox}`);
                            if (i.selectedLang) details.push(`Ngôn ngữ: ${i.selectedLang}`);
                            if (i.selectedVariants) {
                              Object.entries(i.selectedVariants).forEach(([k, v]) => details.push(`${k}: ${v}`));
                            }
                            if (i.quickAddAccessoryNames) {
                              i.quickAddAccessoryNames.forEach(name => details.push(`+ ${name}`));
                            }
                            if (i.addSleeves && !i.quickAddAccessoryNames) details.push(`+ ${(i as any).quickAddAccessoryName || 'Sleeves'}`);
                            const detailsStr = details.length > 0 ? ` (${details.join(', ')})` : '';
                            return `- ${i.name}${detailsStr} (x${i.quantity})`;
                          }).join('\n');
                          alert(`Chi tiết đơn hàng:\nKhách: ${order.shippingInfo.fullName}\nSĐT: ${order.shippingInfo.phone}\nĐịa chỉ: ${order.shippingInfo.address}\nGhi chú: ${order.shippingInfo.notes || 'Không có'}\n\nSản phẩm:\n${itemsList}\n\nTạm tính: ${order.totalAmount.toLocaleString('vi-VN')}đ${discountInfo}\nTổng cộng: ${finalTotal.toLocaleString('vi-VN')}đ`);
                        }}
                        className="text-sm text-blue-600 dark:text-blue-500 hover:underline block ml-auto mb-2"
                      >
                        Chi tiết
                      </button>

                      <div className="flex flex-col items-end gap-1 mt-2">
                        {order.trackingCode && !editingTracking[order.id] ? (
                          <div className="flex items-center gap-2">
                            <span 
                              className="text-xs font-mono bg-gray-100 dark:bg-zinc-800 px-2 py-1 rounded max-w-[150px] truncate"
                              title={order.trackingCode}
                            >
                              {order.trackingCode.includes('spx.vn/track?') ? order.trackingCode.split('spx.vn/track?')[1].split('&')[0] : order.trackingCode}
                            </span>
                            <button
                              onClick={() => {
                                handleTrackingDelete(order.id);
                              }}
                              className="text-gray-400 hover:text-red-500 transition-colors"
                              title="Xóa mã"
                            >
                              <X className="w-3 h-3" />
                            </button>
                            <button
                              onClick={() => {
                                setTrackingInputs(prev => ({ ...prev, [order.id]: order.trackingCode! }));
                                setEditingTracking(prev => ({ ...prev, [order.id]: true }));
                              }}
                              className="text-gray-400 hover:text-blue-500 transition-colors"
                              title="Sửa mã"
                            >
                              <Edit className="w-3 h-3" />
                            </button>
                          </div>
                        ) : (
                          <div className="flex items-center gap-1">
                            <input
                              type="text"
                              placeholder="Mã SPX hoặc Link..."
                              value={trackingInputs[order.id] || ''}
                              onChange={(e) => setTrackingInputs(prev => ({ ...prev, [order.id]: e.target.value }))}
                              className="border border-gray-300 dark:border-zinc-700 rounded px-2 py-1 text-xs w-24 bg-transparent text-gray-900 dark:text-white focus:border-blue-500 outline-none"
                            />
                            <button
                              onClick={() => handleTrackingSave(order.id)}
                              disabled={!trackingInputs[order.id]?.trim()}
                              className="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-300 disabled:dark:bg-zinc-700 text-white px-2 py-1 rounded text-xs transition-colors"
                            >
                              Lưu
                            </button>
                            {editingTracking[order.id] && (
                              <button
                                onClick={() => setEditingTracking(prev => ({ ...prev, [order.id]: false }))}
                                className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors ml-1"
                                title="Hủy"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            )}
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {orders.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-gray-500 dark:text-zinc-500">
                      <ShoppingBag className="w-12 h-12 mx-auto mb-3 text-gray-300 dark:text-zinc-700" />
                      <p>Chưa có đơn hàng nào.</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab Content: Homepage */}
      {activeTab === 'homepage' && (
        <div className="space-y-6">
          {/* Header */}
          <div
            className="rounded-2xl p-6 flex items-center justify-between"
            style={{
              background: 'linear-gradient(135deg, rgba(255,200,50,0.08) 0%, rgba(200,30,30,0.06) 100%)',
              border: '1px solid rgba(255,200,50,0.12)',
            }}
          >
            <div>
              <h2 className="text-xl font-black text-white flex items-center gap-2">
                <Palette className="w-5 h-5 text-amber-400" />
                Thiết kế Trang Chủ
              </h2>
              <p className="text-zinc-400 text-sm mt-1">Tuỳ chỉnh hình ảnh nền, hiệu ứng động và nội dung hero section.</p>
            </div>
            <button
              onClick={async () => {
                try {
                  await setDoc(doc(db, 'settings', 'homepage'), homeConfig);
                  toast.success('Đã lưu cấu hình trang chủ!');
                } catch (error) {
                  console.error(error);
                  toast.error('Lỗi khi lưu cấu hình.');
                }
              }}
              className="flex items-center gap-2 px-6 py-3 rounded-xl font-bold text-sm transition-all hover:scale-105 active:scale-95"
              style={{
                background: 'linear-gradient(135deg, #CC0000 0%, #FF3333 100%)',
                boxShadow: '0 4px 20px rgba(200,30,30,0.4)',
                color: '#fff',
              }}
            >
              <Save className="w-4 h-4" /> Lưu Thay Đổi
            </button>
          </div>

          {/* Two-column: Editor (left) + Sections/Badges (right) */}
          <div className="grid grid-cols-1 xl:grid-cols-5 gap-6">
            {/* Hero Editor — dark themed */}
            <div
              className="xl:col-span-3 rounded-2xl p-6"
              style={{
                background: 'rgba(10,5,0,0.6)',
                border: '1px solid rgba(255,200,50,0.1)',
              }}
            >
              <h3 className="text-sm font-bold text-amber-400 uppercase tracking-widest mb-5 flex items-center gap-2">
                <ImageIcon className="w-4 h-4" /> Hero Section
              </h3>
              <AdminHeroEditor homeConfig={homeConfig} setHomeConfig={setHomeConfig} />
            </div>

            {/* Right column: Sections + Trust Badges */}
            <div className="xl:col-span-2 space-y-5">



              {/* Sections */}
              <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-5 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                    <Box className="w-4 h-4 text-purple-500" /> Khối Sản Phẩm
                  </h3>
                  <button 
                    onClick={() => {
                      setHomeConfig({
                        ...homeConfig, 
                        sections: [...homeConfig.sections, { id: `section-${Date.now()}`, title: 'Khối mới', typeFilter: 'all', icon: 'Box', iconColorClass: 'text-gray-500 dark:text-zinc-500' }]
                      });
                    }}
                    className="text-xs bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-3 py-1.5 rounded-lg flex items-center gap-1 transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" /> Thêm
                  </button>
                </div>
                <div className="space-y-3">
                  {homeConfig.sections.map((section, index) => (
                    <div key={section.id} className="relative grid grid-cols-2 gap-2 p-3 bg-gray-50 dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-xl pr-9">
                      <button 
                        onClick={() => {
                          const newSections = [...homeConfig.sections];
                          newSections.splice(index, 1);
                          setHomeConfig({...homeConfig, sections: newSections});
                        }}
                        className="absolute top-2 right-2 p-1 text-gray-400 dark:text-zinc-600 hover:text-red-500 rounded transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                      <div className="col-span-2">
                        <input type="text" placeholder="Tiêu đề khối" value={section.title} onChange={e => {
                          const ns = [...homeConfig.sections]; ns[index].title = e.target.value; setHomeConfig({...homeConfig, sections: ns});
                        }} className="w-full bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                      </div>
                      <input type="text" placeholder="Icon (e.g. Flame)" value={section.icon} onChange={e => {
                        const ns = [...homeConfig.sections]; ns[index].icon = e.target.value; setHomeConfig({...homeConfig, sections: ns});
                      }} className="bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-xs text-gray-900 dark:text-white outline-none focus:border-red-500" />
                      <select value={section.typeFilter} onChange={e => {
                        const ns = [...homeConfig.sections]; ns[index].typeFilter = e.target.value; setHomeConfig({...homeConfig, sections: ns});
                      }} className="bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 rounded-lg px-2 py-1.5 text-xs text-gray-900 dark:text-white outline-none focus:border-red-500 appearance-none">
                        <option value="all">Tất cả</option>
                        <option value="base">Bản Cơ Bản</option>
                        <option value="expansion">Bản Mở Rộng</option>
                        <option value="accessory">Phụ Kiện</option>
                        <option value="combo">Combo</option>
                        {productConfig.types?.map(type => <option key={type} value={type}>{type}</option>)}
                      </select>
                    </div>
                  ))}
                </div>
              </div>

              {/* Trust Badges */}
              <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-5 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 text-pink-500" /> Cam Kết
                  </h3>
                  <button 
                    onClick={() => setHomeConfig({ ...homeConfig, trustBadges: [...homeConfig.trustBadges, { icon: 'Shield', title: 'Cam kết mới', desc: 'Mô tả cam kết', colorClass: 'text-emerald-500' }] })}
                    className="text-xs bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-3 py-1.5 rounded-lg flex items-center gap-1 transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" /> Thêm
                  </button>
                </div>
                <div className="space-y-3">
                  {homeConfig.trustBadges.map((badge, index) => (
                    <div key={index} className="relative p-3 bg-gray-50 dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-xl pr-9">
                      <button 
                        onClick={() => { const nb = [...homeConfig.trustBadges]; nb.splice(index, 1); setHomeConfig({...homeConfig, trustBadges: nb}); }}
                        className="absolute top-2 right-2 p-1 text-gray-400 dark:text-zinc-600 hover:text-red-500 rounded transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                      <input type="text" placeholder="Tiêu đề" value={badge.title} onChange={e => {
                        const nb = [...homeConfig.trustBadges]; nb[index].title = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb});
                      }} className="w-full mb-2 bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                      <input type="text" placeholder="Mô tả" value={badge.desc} onChange={e => {
                        const nb = [...homeConfig.trustBadges]; nb[index].desc = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb});
                      }} className="w-full bg-white dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-xs text-gray-900 dark:text-white outline-none focus:border-red-500" />
                    </div>
                  ))}
                </div>
              </div>
            </div> {/* end right col */}
          </div> {/* end 2-col grid */}
        </div>
      )}

      {/* Tab Content: Discounts */}
      {activeTab === 'discounts' && (
        <AdminDiscountCodes />
      )}

      {/* Tab Content: Settings */}
      {activeTab === 'settings' && (
        <AdminSettings />
      )}
        </div>
      </main>
    </div>
  );
}
