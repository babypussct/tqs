import React, { useState, useMemo, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useProducts } from '../hooks/useProducts';
import { useHomepage } from '../hooks/useHomepage';
import { useOrders } from '../utils/useOrders';
import { Product, HomepageConfig, Order } from '../types';
import { handleFirestoreError, OperationType } from '../utils/firebaseError';
import { Plus, Edit, Trash2, X, Save, Package, ShoppingBag, Search, Tag, Image as ImageIcon, Box, AlertCircle, LayoutTemplate, Clock, CheckCircle, Truck, XCircle, Ticket, Palette, Settings, Shield, Database, Star, ChevronRight, MoreHorizontal } from 'lucide-react';
import { toast } from 'sonner';
import AdminDiscountCodes from './admin/AdminDiscountCodes';
import AdminSettings from './AdminSettings';
import AdminHeroEditor from './admin/AdminHeroEditor';
import AdminNavigation from './admin/AdminNavigation';
import AdminPermissions from './admin/AdminPermissions';
import AdminDatabaseRules from './admin/AdminDatabaseRules';
import AdminRewardsConfig from './admin/AdminRewardsConfig';
import { useProductConfig } from '../hooks/useProductConfig';
import { useAuth } from '../contexts/AuthContext';

export default function AdminDashboard() {
  const { products, loading: productsLoading } = useProducts(false);
  const { config: initialConfig, loading: configLoading } = useHomepage();
  const { config: productConfig } = useProductConfig();
  const { orders, loading: ordersLoading, updateOrderStatus, deleteOrder } = useOrders();
  const { adminUser } = useAuth();
  const navigate = useNavigate();
  
  const [activeTab, setActiveTab] = useState<'products' | 'orders' | 'homepage' | 'navigation' | 'discounts' | 'settings' | 'rewards' | 'permissions' | 'rules'>('products');
  const [searchTerm, setSearchTerm] = useState('');
  const [trackingInputs, setTrackingInputs] = useState<Record<string, string>>({});
  const [editingTracking, setEditingTracking] = useState<Record<string, boolean>>({});
  
  const [homeConfig, setHomeConfig] = useState<HomepageConfig>(initialConfig);

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

  useEffect(() => {
    setHomeConfig(initialConfig);
  }, [initialConfig]);

  const loading = productsLoading || configLoading || ordersLoading;

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
      <div className="text-slate-500 dark:text-zinc-400 flex items-center gap-3 font-medium">
        <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
        Đang đồng bộ dữ liệu quản trị...
      </div>
    </div>
  );

  const tabs = [
    { id: 'products', label: 'Sản phẩm', icon: Package, requiredPermission: 'manageProducts' },
    { id: 'orders', label: 'Đơn hàng', icon: ShoppingBag, requiredPermission: 'manageOrders' },
    { id: 'homepage', label: 'Giao diện', icon: Palette, requiredPermission: 'manageHomepage' },
    { id: 'navigation', label: 'Thanh điều hướng', icon: LayoutTemplate, requiredPermission: 'manageHomepage' },
    { id: 'discounts', label: 'Mã giảm giá', icon: Ticket, requiredPermission: 'manageDiscounts' },
    { id: 'settings', label: 'Cấu hình chung', icon: Settings, requiredPermission: 'manageSettings' },
    { id: 'rewards', label: 'Hạng & Điểm', icon: Star, requiredPermission: 'manageRewards' },
    { id: 'permissions', label: 'Phân quyền', icon: Shield, requiredPermission: 'manageRoles' },
    { id: 'rules', label: 'Bảo trì dữ liệu', icon: Database, requiredPermission: null },
  ];

  const activeTabInfo = tabs.find(t => t.id === activeTab);

  return (
    <div className="flex flex-col md:flex-row min-h-[calc(100vh-73px)] bg-slate-50 dark:bg-zinc-950 font-sans text-slate-900 dark:text-slate-100">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 bg-white dark:bg-zinc-900 border-r border-slate-200 dark:border-zinc-800 shrink-0 md:sticky md:top-[73px] md:h-[calc(100vh-73px)] overflow-y-auto">
        <div className="p-6 pb-2">
          <h2 className="text-xs font-bold text-slate-400 dark:text-zinc-500 uppercase tracking-wider mb-4">Danh mục quản lý</h2>
        </div>
        <nav className="px-3 space-y-1 pb-6">
          {tabs.map((tab) => {
            if (tab.requiredPermission && !adminUser?.isSuperAdmin && !(adminUser?.permissions as any)?.[tab.requiredPermission]) {
              return null;
            }
            const Icon = tab.icon as any;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 shadow-sm ring-1 ring-inset ring-indigo-500/20'
                    : 'text-slate-600 dark:text-zinc-400 hover:bg-slate-100 dark:hover:bg-zinc-800/50 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-400 dark:text-zinc-500'}`} />
                  {tab.label}
                </div>
                {isActive && <ChevronRight className="w-4 h-4 opacity-50" />}
              </button>
            );
          })}
        </nav>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 min-w-0 flex flex-col">
        {/* Top Header */}
        <header className="bg-white dark:bg-zinc-900 border-b border-slate-200 dark:border-zinc-800 px-6 py-4 flex items-center justify-between sticky top-[73px] z-10">
          <div>
            <h1 className="text-xl font-semibold text-slate-900 dark:text-white flex items-center gap-2">
              {activeTabInfo?.icon && <activeTabInfo.icon className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />}
              {activeTabInfo?.label}
            </h1>
            <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">
              Quản lý và thiết lập hệ thống TQS.
            </p>
          </div>
          <div className="flex items-center gap-3">
            {activeTab === 'products' && (
              <button 
                onClick={() => navigate('/admin/product/new')} 
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 text-sm font-medium transition-colors shadow-sm"
              >
                <Plus className="w-4 h-4" /> Thêm Gói/SP
              </button>
            )}
            {activeTab === 'homepage' && (
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
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 text-sm font-medium transition-colors shadow-sm"
              >
                <Save className="w-4 h-4" /> Lưu Giao Diện
              </button>
            )}
          </div>
        </header>

        {/* Content Body */}
        <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
          
          {/* Tab Content: Products */}
          {activeTab === 'products' && (
            <div className="space-y-6">
              {/* Filter Bar */}
              <div className="flex items-center gap-4 bg-white dark:bg-zinc-900 p-3 flex-wrap rounded-xl border border-slate-200 dark:border-zinc-800 shadow-sm">
                <div className="relative flex-1 min-w-[200px]">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                  <input 
                    type="text" 
                    placeholder="Tìm kiếm theo Tên..." 
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-800 rounded-lg pl-9 pr-4 py-1.5 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all"
                  />
                </div>
              </div>

              {/* Data Table */}
              <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-slate-200 dark:divide-zinc-800 text-sm text-left">
                    <thead className="bg-slate-50 dark:bg-zinc-900/50">
                      <tr>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Sản phẩm</th>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Phân loại</th>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Đơn giá</th>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Tồn kho</th>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Tình trạng</th>
                        <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-right">Tác vụ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200 dark:divide-zinc-800">
                      {filteredProducts.map(p => (
                        <tr key={p.id} className="hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-colors group">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 rounded-md bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 overflow-hidden shrink-0 flex items-center justify-center">
                                {p.image ? (
                                  <img src={p.image} alt={p.name} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                                ) : (
                                  <ImageIcon className="w-4 h-4 text-slate-400" />
                                )}
                              </div>
                              <div className="font-medium text-slate-900 dark:text-slate-100 max-w-[200px] truncate" title={p.name}>
                                {p.name}
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-slate-500 dark:text-zinc-400 capitalize">
                            {p.type} {p.badge && <span className="ml-1 inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-zinc-300">{p.badge}</span>}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-slate-900 dark:text-slate-100 font-medium">{p.price.toLocaleString('vi-VN')} đ</div>
                            {p.originalPrice && <div className="text-xs text-slate-400 line-through">{p.originalPrice.toLocaleString('vi-VN')} đ</div>}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-center">
                            <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full font-medium ${
                              p.stock === 0 ? 'bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-400' : 'bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-zinc-300'
                            }`}>
                              {p.stock !== undefined ? p.stock : '∞'}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-center">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium border ${
                              p.isActive 
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20' 
                                : 'bg-slate-100 text-slate-600 border-slate-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700'
                            }`}>
                              {p.isActive ? 'Đang bán' : 'Tạm ẩn'}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                            <div className="flex items-center justify-end gap-2">
                              <button onClick={() => navigate('/admin/product/' + p.id)} className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 dark:hover:text-indigo-400 rounded-md transition-colors tooltip-trigger" title="Sửa">
                                <Edit className="w-4 h-4" />
                              </button>
                              <button onClick={() => handleDelete(p.id)} className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 dark:hover:text-red-400 rounded-md transition-colors tooltip-trigger" title="Xóa">
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {filteredProducts.length === 0 && (
                        <tr>
                          <td colSpan={6} className="px-6 py-12 text-center text-slate-500 dark:text-zinc-400">
                            <Package className="w-10 h-10 mx-auto mb-3 text-slate-300 dark:text-zinc-600" />
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
          )}

          {/* Tab Content: Homepage Editor */}
          {activeTab === 'homepage' && (
            <div className="grid grid-cols-1 xl:grid-cols-5 gap-6">
              {/* Hero Editor */}
              <div className="xl:col-span-3 min-w-0 overflow-hidden bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
                <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 uppercase tracking-widest mb-5 flex items-center gap-2 border-b border-slate-100 dark:border-zinc-800 pb-3">
                  <ImageIcon className="w-4 h-4 text-indigo-500" /> Thiết kế Banner / Hero
                </h3>
                <AdminHeroEditor homeConfig={homeConfig} setHomeConfig={setHomeConfig} />
              </div>

              {/* Sections & Trust Badges */}
              <div className="xl:col-span-2 space-y-6 min-w-0">
                <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
                  <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-zinc-800 pb-3">
                    <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                      <Box className="w-4 h-4 text-indigo-500" /> Hệ thống Khối (Sections)
                    </h3>
                    <button 
                      onClick={() => setHomeConfig({ ...homeConfig, sections: [...homeConfig.sections, { id: `section-${Date.now()}`, title: 'Khối mới', typeFilter: 'all', icon: 'Box', iconColorClass: 'text-slate-500' }] })}
                      className="text-xs bg-indigo-50 text-indigo-600 hover:bg-indigo-100 px-3 py-1.5 rounded-md font-medium"
                    >
                      + Thêm Khối
                    </button>
                  </div>
                  <div className="space-y-3">
                    {homeConfig.sections.map((section, index) => (
                      <div key={section.id} className="relative grid grid-cols-2 gap-3 p-4 bg-slate-50 dark:bg-zinc-800/50 rounded-lg border border-slate-100 dark:border-zinc-700/50">
                        <button onClick={() => { const ns = [...homeConfig.sections]; ns.splice(index, 1); setHomeConfig({...homeConfig, sections: ns}); }} className="absolute -top-2 -right-2 bg-white shadow-sm border p-1 text-slate-400 hover:text-red-500 rounded-full w-6 h-6 flex items-center justify-center">
                          <X className="w-3 h-3" />
                        </button>
                        <div className="col-span-2">
                          <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Tiêu đề</label>
                          <input type="text" value={section.title} onChange={e => { const ns = [...homeConfig.sections]; ns[index].title = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-sm outline-none focus:border-indigo-500" />
                        </div>
                        <div>
                          <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Icon</label>
                          <input type="text" value={section.icon} onChange={e => { const ns = [...homeConfig.sections]; ns[index].icon = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-xs outline-none focus:border-indigo-500" />
                        </div>
                        <div>
                          <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Loại SP</label>
                          <select value={section.typeFilter} onChange={e => { const ns = [...homeConfig.sections]; ns[index].typeFilter = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-2 py-1.5 text-xs outline-none focus:border-indigo-500">
                            <option value="all">Tất cả</option>
                            <option value="base">Bản Cơ Bản</option>
                            <option value="expansion">Bản Mở Rộng</option>
                            <option value="accessory">Phụ Kiện</option>
                            <option value="combo">Combo</option>
                            {productConfig.types?.map(type => <option key={type} value={type}>{type}</option>)}
                          </select>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
                  <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-zinc-800 pb-3">
                    <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 text-indigo-500" /> Badge Cam Kết
                    </h3>
                    <button onClick={() => setHomeConfig({ ...homeConfig, trustBadges: [...homeConfig.trustBadges, { icon: 'Shield', title: 'Cam kết mới', desc: 'Mô tả', colorClass: 'text-indigo-500' }] })} className="text-xs bg-indigo-50 text-indigo-600 hover:bg-indigo-100 px-3 py-1.5 rounded-md font-medium">
                      + Thêm Badge
                    </button>
                  </div>
                  <div className="space-y-3">
                    {homeConfig.trustBadges.map((badge, index) => (
                      <div key={index} className="relative p-4 bg-slate-50 dark:bg-zinc-800/50 rounded-lg border border-slate-100 dark:border-zinc-700/50">
                        <button onClick={() => { const nb = [...homeConfig.trustBadges]; nb.splice(index, 1); setHomeConfig({...homeConfig, trustBadges: nb}); }} className="absolute -top-2 -right-2 bg-white shadow-sm border p-1 text-slate-400 hover:text-red-500 rounded-full w-6 h-6 flex items-center justify-center">
                          <X className="w-3 h-3" />
                        </button>
                        <input type="text" placeholder="Tiêu đề" value={badge.title} onChange={e => { const nb = [...homeConfig.trustBadges]; nb[index].title = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb}); }} className="w-full mb-2 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-sm font-medium outline-none focus:border-indigo-500" />
                        <input type="text" placeholder="Mô tả chi tiết" value={badge.desc} onChange={e => { const nb = [...homeConfig.trustBadges]; nb[index].desc = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb}); }} className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1 text-xs outline-none focus:border-indigo-500" />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Sub-Components Routing */}
          <div className="space-y-6">
            {activeTab === 'navigation' && <AdminNavigation />}
            {activeTab === 'discounts' && <AdminDiscountCodes />}
            {activeTab === 'settings' && <AdminSettings />}
            {activeTab === 'rewards' && <AdminRewardsConfig />}
            {activeTab === 'permissions' && <AdminPermissions />}
            {activeTab === 'rules' && <AdminDatabaseRules />}
          </div>
          
        </div>
      </main>
    </div>
  );
}
