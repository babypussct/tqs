import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { doc, setDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { useHomepage } from '../hooks/useHomepage';
import { HomepageConfig } from '../types';
import { Plus, Save, Package, ShoppingBag, LayoutTemplate, Ticket, Palette, Settings, Shield, Database, Star, FileText, ChevronRight, ImageIcon, FileBarChart, PanelBottom } from 'lucide-react';
import { toast } from 'sonner';

// Admin Sub-components
import AdminSettings from './AdminSettings';
import AdminHeroEditor from './admin/AdminHeroEditor';
import AdminNavigation from './admin/AdminNavigation';
import AdminPermissions from './admin/AdminPermissions';
import AdminDatabaseRules from './admin/AdminDatabaseRules';
import AdminRewardsConfig from './admin/AdminRewardsConfig';
import AdminPostList from './admin/AdminPostList';
import AdminDiscountCodes from './admin/AdminDiscountCodes';
import AdminProducts from './admin/AdminProducts';
import AdminOrders from './admin/AdminOrders';
import AdminHomepageLayout from './admin/AdminHomepageLayout';
import AdminRevenueStatistics from './admin/AdminRevenueStatistics';
import AdminFooterEditor from './admin/AdminFooterEditor';
import { useAuth } from '../contexts/AuthContext';

export default function AdminDashboard() {
  const { config: initialConfig, loading: configLoading } = useHomepage();
  const { adminUser } = useAuth();
  const navigate = useNavigate();
  
  const [activeTab, setActiveTab] = useState<'products' | 'orders' | 'revenue' | 'homepage' | 'navigation' | 'footer' | 'discounts' | 'settings' | 'rewards' | 'permissions' | 'rules' | 'posts'>('products');
  const [homeConfig, setHomeConfig] = useState<HomepageConfig>(initialConfig);

  useEffect(() => {
    setHomeConfig(initialConfig);
  }, [initialConfig]);

  if (configLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-slate-500 dark:text-zinc-400 flex items-center gap-3 font-medium">
          <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
          Đang đồng bộ dữ liệu quản trị...
        </div>
      </div>
    );
  }

  const tabs = [
    { id: 'products', label: 'Sản phẩm', icon: Package, requiredPermission: 'manageProducts' },
    { id: 'orders', label: 'Đơn hàng', icon: ShoppingBag, requiredPermission: 'manageOrders' },
    { id: 'revenue', label: 'Thống kê Doanh thu', icon: FileBarChart, requiredPermission: 'manageOrders' },
    { id: 'homepage', label: 'Giao diện', icon: Palette, requiredPermission: 'manageHomepage' },
    { id: 'navigation', label: 'Thanh điều hướng', icon: LayoutTemplate, requiredPermission: 'manageHomepage' },
    { id: 'footer', label: 'Chân trang (Footer)', icon: PanelBottom, requiredPermission: 'manageHomepage' },
    { id: 'discounts', label: 'Mã giảm giá', icon: Ticket, requiredPermission: 'manageDiscounts' },
    { id: 'settings', label: 'Cấu hình chung', icon: Settings, requiredPermission: 'manageSettings' },
    { id: 'rewards', label: 'Hạng & Điểm', icon: Star, requiredPermission: 'manageRewards' },
    { id: 'posts', label: 'Bài viết', icon: FileText, requiredPermission: 'managePosts' },
    { id: 'permissions', label: 'Phân quyền', icon: Shield, requiredPermission: 'manageRoles' },
    { id: 'rules', label: 'Bảo trì dữ liệu', icon: Database, requiredPermission: null },
  ];

  const activeTabInfo = tabs.find(t => t.id === activeTab);

  return (
    <div className="flex flex-col md:flex-row min-h-[calc(100vh-73px)] bg-slate-50 dark:bg-zinc-950 font-sans text-slate-900 dark:text-slate-100">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 bg-white dark:bg-zinc-900 border-b md:border-b-0 md:border-r border-slate-200 dark:border-zinc-800 shrink-0 sticky top-[64px] lg:top-[80px] md:top-[73px] md:h-[calc(100vh-73px)] overflow-x-auto md:overflow-y-auto z-20 custom-scrollbar shadow-sm md:shadow-none">
        <div className="hidden md:block p-6 pb-2">
          <h2 className="text-xs font-bold text-slate-400 dark:text-zinc-500 uppercase tracking-wider mb-4">Danh mục quản lý</h2>
        </div>
        <nav className="flex md:block px-2 py-2 md:px-3 md:pb-6 space-x-2 md:space-x-0 md:space-y-1 w-max md:w-auto">
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
                className={`flex items-center justify-between px-3 py-2 md:py-2.5 rounded-lg text-sm font-medium transition-all whitespace-nowrap shrink-0 ${
                  isActive
                    ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 shadow-sm ring-1 ring-inset ring-indigo-500/20'
                    : 'text-slate-600 dark:text-zinc-400 hover:bg-slate-100 dark:hover:bg-zinc-800/50 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <div className="flex items-center gap-2 md:gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-400 dark:text-zinc-500'}`} />
                  {tab.label}
                </div>
                {isActive && <ChevronRight className="hidden md:block w-4 h-4 opacity-50" />}
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
          
          {/* Sub-Components Routing */}
          <div className="space-y-6">
            {activeTab === 'products' && <AdminProducts />}
            {activeTab === 'orders' && <AdminOrders />}
            {activeTab === 'revenue' && <AdminRevenueStatistics />}
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
                <AdminHomepageLayout homeConfig={homeConfig} setHomeConfig={setHomeConfig} />
              </div>
            )}
            {activeTab === 'navigation' && <AdminNavigation />}
            {activeTab === 'footer' && <AdminFooterEditor />}
            {activeTab === 'discounts' && <AdminDiscountCodes />}
            {activeTab === 'posts' && <AdminPostList />}
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
