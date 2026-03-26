import React, { useState, useMemo, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useProducts } from '../hooks/useProducts';
import { useHomepage } from '../hooks/useHomepage';
import { useOrders } from '../utils/useOrders';
import { Product, HomepageConfig, Order } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Plus, Edit, Trash2, X, Save, Package, TrendingUp, ShoppingBag, Search, Tag, Image as ImageIcon, Box, AlertCircle, LayoutTemplate, Clock, CheckCircle, Truck, XCircle, Ticket } from 'lucide-react';
import { toast } from 'sonner';
import AdminDiscountCodes from './admin/AdminDiscountCodes';
import AdminSettings from './AdminSettings';
import { useProductConfig } from '../hooks/useProductConfig';

export default function AdminDashboard() {
  const { products, loading: productsLoading } = useProducts(false); // Fetch all including inactive
  const { config: initialConfig, loading: configLoading } = useHomepage();
  const { config: productConfig } = useProductConfig();
  const { orders, loading: ordersLoading, updateOrderStatus } = useOrders();
  const navigate = useNavigate();
  
  const [activeTab, setActiveTab] = useState<'overview' | 'products' | 'orders' | 'homepage' | 'discounts' | 'settings'>('products');
  const [searchTerm, setSearchTerm] = useState('');
  
  const [homeConfig, setHomeConfig] = useState<HomepageConfig>(initialConfig);

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
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header & Navigation */}
      <div className="mb-8">
        <h1 className="text-3xl font-black text-gray-900 dark:text-white tracking-tight mb-6">Quản trị Cửa hàng</h1>
        <div className="flex gap-8 border-b border-gray-200 dark:border-zinc-800">
          <button 
            onClick={() => setActiveTab('overview')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'overview' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Tổng quan
            {activeTab === 'overview' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
          <button 
            onClick={() => setActiveTab('products')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'products' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Sản phẩm
            {activeTab === 'products' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
          <button 
            onClick={() => setActiveTab('orders')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'orders' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Đơn hàng
            {activeTab === 'orders' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
          <button 
            onClick={() => setActiveTab('homepage')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'homepage' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Giao diện
            {activeTab === 'homepage' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
          <button 
            onClick={() => setActiveTab('discounts')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'discounts' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Mã giảm giá
            {activeTab === 'discounts' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
          <button 
            onClick={() => setActiveTab('settings')}
            className={`pb-4 text-sm font-medium transition-colors relative ${activeTab === 'settings' ? 'text-gray-900 dark:text-white' : 'text-gray-500 dark:text-zinc-500 hover:text-gray-700 dark:hover:text-zinc-300'}`}
          >
            Cấu hình
            {activeTab === 'settings' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-t-full" />}
          </button>
        </div>
      </div>

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
                        className="text-sm text-blue-600 dark:text-blue-500 hover:underline"
                      >
                        Chi tiết
                      </button>
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
        <div className="space-y-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-white">Tùy chỉnh Trang chủ</h2>
              <p className="text-gray-500 dark:text-zinc-400 text-sm mt-1">Thay đổi banner, danh mục và các thông tin nổi bật trên trang chủ.</p>
            </div>
            <button 
              onClick={async () => {
                try {
                  await setDoc(doc(db, 'settings', 'homepage'), homeConfig);
                  alert('Đã lưu cấu hình trang chủ thành công!');
                } catch (error) {
                  console.error(error);
                  alert('Lỗi khi lưu cấu hình.');
                }
              }}
              className="bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 rounded-xl flex items-center gap-2 font-medium transition-colors shadow-lg shadow-red-600/20"
            >
              <Save className="w-5 h-5" /> Lưu Thay Đổi
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Hero Main Banner */}
            <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 space-y-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2 mb-4">
                <LayoutTemplate className="w-5 h-5 text-blue-500" /> Banner Chính
              </h3>
              <div>
                <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">URL Hình ảnh</label>
                <input type="text" value={homeConfig.hero.main.image} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, main: {...homeConfig.hero.main, image: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Nhãn (Badge)</label>
                  <input type="text" value={homeConfig.hero.main.badge || ''} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, main: {...homeConfig.hero.main, badge: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Tiêu đề</label>
                  <input type="text" value={homeConfig.hero.main.title} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, main: {...homeConfig.hero.main, title: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Phụ đề (Màu đỏ)</label>
                <input type="text" value={homeConfig.hero.main.subtitle} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, main: {...homeConfig.hero.main, subtitle: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Mô tả</label>
                <textarea rows={2} value={homeConfig.hero.main.description || ''} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, main: {...homeConfig.hero.main, description: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
              </div>
            </div>

            {/* Hero Side Banners */}
            <div className="space-y-6">
              <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 space-y-4">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2 mb-4">
                  <ImageIcon className="w-5 h-5 text-emerald-500" /> Banner Phụ 1
                </h3>
                <div>
                  <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">URL Hình ảnh</label>
                  <input type="text" value={homeConfig.hero.side1.image} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side1: {...homeConfig.hero.side1, image: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Tiêu đề</label>
                    <input type="text" value={homeConfig.hero.side1.title} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side1: {...homeConfig.hero.side1, title: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Phụ đề</label>
                    <input type="text" value={homeConfig.hero.side1.subtitle} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side1: {...homeConfig.hero.side1, subtitle: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                </div>
              </div>

              <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 space-y-4">
                <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2 mb-4">
                  <ImageIcon className="w-5 h-5 text-amber-500" /> Banner Phụ 2
                </h3>
                <div>
                  <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">URL Hình ảnh</label>
                  <input type="text" value={homeConfig.hero.side2.image} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side2: {...homeConfig.hero.side2, image: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Tiêu đề</label>
                    <input type="text" value={homeConfig.hero.side2.title} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side2: {...homeConfig.hero.side2, title: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Phụ đề</label>
                    <input type="text" value={homeConfig.hero.side2.subtitle} onChange={e => setHomeConfig({...homeConfig, hero: {...homeConfig.hero, side2: {...homeConfig.hero.side2, subtitle: e.target.value}}})} className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Sections */}
          <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Box className="w-5 h-5 text-purple-500" /> Các Khối Sản Phẩm
              </h3>
              <button 
                onClick={() => {
                  setHomeConfig({
                    ...homeConfig, 
                    sections: [...homeConfig.sections, { id: `section-${Date.now()}`, title: 'Khối mới', typeFilter: 'all', icon: 'Box', iconColorClass: 'text-gray-500 dark:text-zinc-500' }]
                  });
                }}
                className="text-sm bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-3 py-1.5 rounded-lg flex items-center gap-1 transition-colors"
              >
                <Plus className="w-4 h-4" /> Thêm khối
              </button>
            </div>
            <div className="space-y-4">
              {homeConfig.sections.map((section, index) => (
                <div key={section.id} className="relative grid grid-cols-1 sm:grid-cols-4 gap-4 p-4 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-xl pr-10">
                  <button 
                    onClick={() => {
                      const newSections = [...homeConfig.sections];
                      newSections.splice(index, 1);
                      setHomeConfig({...homeConfig, sections: newSections});
                    }}
                    className="absolute top-2 right-2 p-1.5 text-gray-500 dark:text-zinc-500 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Tiêu đề khối</label>
                    <input type="text" value={section.title} onChange={e => {
                      const newSections = [...homeConfig.sections];
                      newSections[index].title = e.target.value;
                      setHomeConfig({...homeConfig, sections: newSections});
                    }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Icon (Lucide)</label>
                    <input type="text" value={section.icon} onChange={e => {
                      const newSections = [...homeConfig.sections];
                      newSections[index].icon = e.target.value;
                      setHomeConfig({...homeConfig, sections: newSections});
                    }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Màu Icon (Tailwind)</label>
                    <input type="text" value={section.iconColorClass} onChange={e => {
                      const newSections = [...homeConfig.sections];
                      newSections[index].iconColorClass = e.target.value;
                      setHomeConfig({...homeConfig, sections: newSections});
                    }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Lọc theo loại</label>
                    <select value={section.typeFilter} onChange={e => {
                      const newSections = [...homeConfig.sections];
                      newSections[index].typeFilter = e.target.value;
                      setHomeConfig({...homeConfig, sections: newSections});
                    }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500 appearance-none">
                      <option value="all">Tất cả</option>
                      <option value="base">Bản Cơ Bản</option>
                      <option value="expansion">Bản Mở Rộng</option>
                      <option value="accessory">Phụ Kiện</option>
                      <option value="combo">Combo</option>
                      {productConfig.types?.map(type => (
                        <option key={type} value={type}>{type}</option>
                      ))}
                    </select>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Trust Badges */}
          <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-pink-500" /> Cam Kết (Trust Badges)
              </h3>
              <button 
                onClick={() => {
                  setHomeConfig({
                    ...homeConfig, 
                    trustBadges: [...homeConfig.trustBadges, { icon: 'Shield', title: 'Cam kết mới', desc: 'Mô tả cam kết', colorClass: 'text-emerald-500' }]
                  });
                }}
                className="text-sm bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-3 py-1.5 rounded-lg flex items-center gap-1 transition-colors"
              >
                <Plus className="w-4 h-4" /> Thêm cam kết
              </button>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {homeConfig.trustBadges.map((badge, index) => (
                <div key={index} className="relative space-y-3 p-4 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-xl pr-10">
                  <button 
                    onClick={() => {
                      const newBadges = [...homeConfig.trustBadges];
                      newBadges.splice(index, 1);
                      setHomeConfig({...homeConfig, trustBadges: newBadges});
                    }}
                    className="absolute top-2 right-2 p-1.5 text-gray-500 dark:text-zinc-500 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Tiêu đề</label>
                      <input type="text" value={badge.title} onChange={e => {
                        const newBadges = [...homeConfig.trustBadges];
                        newBadges[index].title = e.target.value;
                        setHomeConfig({...homeConfig, trustBadges: newBadges});
                      }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Icon (Lucide)</label>
                      <input type="text" value={badge.icon} onChange={e => {
                        const newBadges = [...homeConfig.trustBadges];
                        newBadges[index].icon = e.target.value;
                        setHomeConfig({...homeConfig, trustBadges: newBadges});
                      }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 dark:text-zinc-400 mb-1.5">Mô tả</label>
                    <input type="text" value={badge.desc} onChange={e => {
                      const newBadges = [...homeConfig.trustBadges];
                      newBadges[index].desc = e.target.value;
                      setHomeConfig({...homeConfig, trustBadges: newBadges});
                    }} className="w-full bg-gray-100 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-white outline-none focus:border-red-500" />
                  </div>
                </div>
              ))}
            </div>
          </div>

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
  );
}
