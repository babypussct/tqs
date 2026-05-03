/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { doc, getDocFromServer } from 'firebase/firestore';
import { db } from './firebase';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { CartProvider } from './contexts/CartContext';
import { Toaster, toast } from 'sonner';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import Footer from './components/Footer';
import CartDrawer from './components/CartDrawer';
import { Product, CartItem } from './types';
import { useSiteConfig } from './hooks/useSiteConfig';
import { PageLoader } from './components/ui/PageLoader';
import { useDeltaSync } from './hooks/useDeltaSync';

// Lazy load components
const Home = lazy(() => import('./components/Home'));
const Shop = lazy(() => import('./components/Shop'));
const ProductDetail = lazy(() => import('./components/ProductDetail'));
const Checkout = lazy(() => import('./components/Checkout'));
const Profile = lazy(() => import('./components/Profile'));
const AdminDashboard = lazy(() => import('./components/AdminDashboard'));
const AdminProductForm = lazy(() => import('./components/admin/AdminProductForm'));
const AdminPostForm = lazy(() => import('./components/admin/AdminPostForm'));
const Blog = lazy(() => import('./components/Blog'));
const BlogPostDetail = lazy(() => import('./components/BlogPostDetail'));

// Protected Route Component - Admin only
const AdminRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAdmin, loading } = useAuth();
  if (loading) return <div>Đang tải...</div>;
  return isAdmin ? <>{children}</> : <Navigate to="/" />;
};

// Protected Route Component - Requires login
const AuthRoute = ({ children }: { children: React.ReactNode }) => {
  const { user, loading } = useAuth();
  if (loading) return <div>Đang tải...</div>;
  return user ? <>{children}</> : <Navigate to="/" state={{ requireAuth: true }} />;
};

// ――― Force Update Overlay Component ―――
function ForceUpdateOverlay({ reason }: { reason: 'build' | 'data' }) {
  return (
    <div
      className="fixed inset-0 z-[99999] flex items-center justify-center"
      style={{ backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)', background: 'rgba(0,0,0,0.6)' }}
      onClick={(e) => e.stopPropagation()}
      onKeyDown={(e) => e.preventDefault()}
    >
      <div className="bg-white dark:bg-zinc-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-zinc-700 p-8 max-w-md mx-4 text-center animate-in fade-in zoom-in duration-300">
        <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-indigo-100 dark:bg-indigo-500/20 flex items-center justify-center text-3xl">
          {reason === 'build' ? '🚀' : '📢'}
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white mb-2">
          {reason === 'build' ? 'Phiên bản mới đã sẵn sàng!' : 'Dữ liệu cửa hàng đã cập nhật!'}
        </h2>
        <p className="text-slate-500 dark:text-zinc-400 text-sm mb-6 leading-relaxed">
          {reason === 'build'
            ? 'TQSShop đã được nâng cấp lên phiên bản mới. Vui lòng tải lại trang để trải nghiệm phiên bản mới nhất.'
            : 'Dữ liệu cửa hàng đã có sự thay đổi (giá mới, tồn kho,...). Vui lòng tải lại trang để cập nhật thông tin chính xác.'}
        </p>
        <button
          onClick={() => window.location.reload()}
          className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-6 rounded-xl transition-colors shadow-lg shadow-indigo-500/25 active:scale-95"
        >
          Tải lại trang ngay
        </button>
        <p className="text-xs text-slate-400 dark:text-zinc-500 mt-3">Bạn cần tải lại để tiếp tục sử dụng.</p>
      </div>
    </div>
  );
}

export default function App() {
  const [updateOverlay, setUpdateOverlay] = useState<'build' | 'data' | null>(null);

  // DeltaSync: khi data thay đổi → hiện overlay
  useDeltaSync({ onDataUpdate: () => setUpdateOverlay('data') });

  const { config: siteConfig } = useSiteConfig();

  // ――― Service Worker Update → hiện overlay ―――
  useEffect(() => {
    const handleSWUpdate = () => setUpdateOverlay('build');
    window.addEventListener('sw-updated', handleSWUpdate);
    return () => window.removeEventListener('sw-updated', handleSWUpdate);
  }, []);

  // Test Firebase Connection
  useEffect(() => {
    async function testConnection() {
      try {
        await getDocFromServer(doc(db, 'test', 'connection'));
        console.log('Firebase connection successful.');
      } catch (error) {
        if (error instanceof Error && error.message.includes('the client is offline')) {
          console.error("Please check your Firebase configuration. The client is offline.");
        }
      }
    }
    testConnection();
  }, []);

  // Update Site Title and Favicon
  useEffect(() => {
    if (siteConfig) {
      if (siteConfig.siteTitle) {
        document.title = siteConfig.siteTitle;
      }
      if (siteConfig.siteFavicon) {
        let link: HTMLLinkElement | null = document.querySelector("link[rel~='icon']");
        if (!link) {
          link = document.createElement('link');
          link.rel = 'icon';
          document.head.appendChild(link);
        }
        link.href = siteConfig.siteFavicon;
      }
    }
  }, [siteConfig]);

  return (
    <ThemeProvider>
      <AuthProvider>
        <CartProvider>
          <Router>
            <div className={`bg-gray-50 dark:bg-zinc-950 text-gray-900 dark:text-zinc-50 font-sans selection:bg-red-500/30 transition-colors duration-200 flex flex-col min-h-screen pb-20 lg:pb-0 ${updateOverlay ? 'pointer-events-none select-none' : ''}`} style={{ paddingBottom: 'calc(5rem + env(safe-area-inset-bottom))' }}>
              {updateOverlay && <ForceUpdateOverlay reason={updateOverlay} />}
              <Header />
              
              <main className="flex-grow">
                <Suspense fallback={<PageLoader />}>
                  <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/shop" element={<Shop />} />
                    <Route path="/blog" element={<Blog />} />
                    <Route path="/blog/:slug" element={<BlogPostDetail />} />
                    <Route path="/product/:id" element={<ProductDetail />} />
                    <Route path="/checkout" element={
                      <AuthRoute>
                        <Checkout />
                      </AuthRoute>
                    } />
                    <Route path="/profile" element={<Profile />} />
                    <Route path="/admin" element={
                      <AdminRoute>
                        <AdminDashboard />
                      </AdminRoute>
                    } />
                    <Route path="/admin/product/new" element={
                      <AdminRoute>
                        <AdminProductForm />
                      </AdminRoute>
                    } />
                    <Route path="/admin/product/:id" element={
                      <AdminRoute>
                        <AdminProductForm />
                      </AdminRoute>
                    } />
                    <Route path="/admin/post/new" element={
                      <AdminRoute>
                        <AdminPostForm />
                      </AdminRoute>
                    } />
                    <Route path="/admin/post/:id" element={
                      <AdminRoute>
                        <AdminPostForm />
                      </AdminRoute>
                    } />
                  </Routes>
                </Suspense>
              </main>

              <Footer />
              <Toaster richColors position="top-right" />
              <CartDrawer />
              <BottomNav />
            </div>
          </Router>
        </CartProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
