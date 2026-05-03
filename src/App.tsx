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

export default function App() {
  useDeltaSync(); // Kích hoạt cảnh báo Delta Sync toàn hệ thống

  const { config: siteConfig } = useSiteConfig();

  // ――― Service Worker Update Notification ―――
  useEffect(() => {
    const handleSWUpdate = () => {
      toast('🚀 Có phiên bản mới!', {
        description: 'TQSShop đã được cập nhật. Tải lại để dùng phiên bản mới nhất.',
        action: {
          label: 'Cập nhật ngay',
          onClick: () => window.location.reload(),
        },
        duration: 10000,
        dismissible: true,
      });
    };

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
            <div className="bg-gray-50 dark:bg-zinc-950 text-gray-900 dark:text-zinc-50 font-sans selection:bg-red-500/30 transition-colors duration-200 flex flex-col min-h-screen pb-20 lg:pb-0" style={{ paddingBottom: 'calc(5rem + env(safe-area-inset-bottom))' }}>
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
