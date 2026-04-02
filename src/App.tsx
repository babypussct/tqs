/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { doc, getDocFromServer } from 'firebase/firestore';
import { db } from './firebase';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { Toaster, toast } from 'sonner';
import Header from './components/Header';
import Home from './components/Home';
import Shop from './components/Shop';
import ProductDetail from './components/ProductDetail';
import CartDrawer from './components/CartDrawer';
import Checkout from './components/Checkout';
import Profile from './components/Profile';
import Footer from './components/Footer';
import AdminDashboard from './components/AdminDashboard';
import { Product, CartItem } from './types';
import { useSiteConfig } from './hooks/useSiteConfig';

import AdminProductForm from './components/admin/AdminProductForm';

// Protected Route Component
const AdminRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAdmin, loading } = useAuth();
  if (loading) return <div>Đang tải...</div>;
  return isAdmin ? <>{children}</> : <Navigate to="/" />;
};

export default function App() {
  // Cart State
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [cartItems, setCartItems] = useState<CartItem[]>(() => {
    try {
      const savedCart = localStorage.getItem('tqs_cart');
      return savedCart ? JSON.parse(savedCart) : [];
    } catch (e) {
      console.error('Failed to parse cart from localStorage:', e);
      return [];
    }
  });

  const { config: siteConfig } = useSiteConfig();

  useEffect(() => {
    localStorage.setItem('tqs_cart', JSON.stringify(cartItems));
  }, [cartItems]);

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

  const handleAddToCart = (
    product: Product, 
    variants?: { 
      selectedBox?: string, 
      selectedLang?: string, 
      selectedVariants?: Record<string, string>,
      addSleeves?: boolean, 
      quickAddAccessoryNames?: string[],
      price: number 
    }
  ) => {
    if (product.stock !== undefined && product.stock <= 0) {
      toast.error('Sản phẩm đã hết hàng');
      return;
    }

    const price = variants?.price || product.price;
    const variantsStr = variants?.selectedVariants ? Object.values(variants.selectedVariants).join('-') : '';
    const quickAddStr = variants?.quickAddAccessoryNames ? variants.quickAddAccessoryNames.join('-') : '';
    const id = `${product.id}-${variants?.selectedBox || ''}-${variants?.selectedLang || ''}-${variantsStr}-${variants?.addSleeves ? 'sleeves' : ''}-${quickAddStr}`;
    
    // Check stock before updating state
    const totalProductQuantity = cartItems
      .filter(item => item.product.id === product.id)
      .reduce((sum, item) => sum + item.quantity, 0);

    if (product.stock !== undefined && totalProductQuantity >= product.stock) {
      toast.error(`Chỉ còn ${product.stock} sản phẩm trong kho`);
      return;
    }

    setCartItems(prev => {
      const existingInPrev = prev.find(item => item.id === id);
      if (existingInPrev) {
        return prev.map(item => item.id === id ? { ...item, quantity: item.quantity + 1 } : item);
      }
      return [...prev, {
        id,
        product,
        quantity: 1,
        selectedBox: variants?.selectedBox,
        selectedLang: variants?.selectedLang,
        selectedVariants: variants?.selectedVariants,
        addSleeves: variants?.addSleeves,
        quickAddAccessoryNames: variants?.quickAddAccessoryNames,
        price
      }];
    });
    
    toast.success(`Đã thêm ${product.name} vào giỏ hàng`);
    setIsCartOpen(true);
  };

  const handleUpdateQuantity = (id: string, deltaOrQuantity: number, isAbsolute: boolean = false) => {
    const itemToUpdate = cartItems.find(i => i.id === id);
    if (!itemToUpdate) return;

    let newQuantity = isAbsolute ? deltaOrQuantity : itemToUpdate.quantity + deltaOrQuantity;
    newQuantity = Math.max(1, newQuantity);
    
    // Only check stock if we are increasing quantity
    if (newQuantity > itemToUpdate.quantity && itemToUpdate.product.stock !== undefined) {
      const totalProductQuantity = cartItems
        .filter(item => item.product.id === itemToUpdate.product.id)
        .reduce((sum, item) => sum + (item.id === id ? newQuantity : item.quantity), 0);
        
      if (totalProductQuantity > itemToUpdate.product.stock) {
        toast.error(`Chỉ còn ${itemToUpdate.product.stock} sản phẩm trong kho`);
        if (isAbsolute) {
          // Fallback to maximum available for absolute input
          const currentTotalExceptThis = cartItems
            .filter(item => item.product.id === itemToUpdate.product.id && item.id !== id)
            .reduce((sum, item) => sum + item.quantity, 0);
          const maxAllowed = itemToUpdate.product.stock - currentTotalExceptThis;
          if (maxAllowed >= 1) newQuantity = maxAllowed;
          else return;
        } else {
          return;
        }
      }
    }

    setCartItems(prev => prev.map(item => item.id === id ? { ...item, quantity: newQuantity } : item));
  };

  const handleRemoveItem = (id: string) => {
    setCartItems(prev => prev.filter(item => item.id !== id));
    toast.success(`Đã xóa sản phẩm khỏi giỏ hàng`);
  };

  const clearCart = () => {
    setCartItems([]);
  };

  const cartCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <div className="bg-gray-50 dark:bg-zinc-950 text-gray-900 dark:text-zinc-50 font-sans selection:bg-red-500/30 transition-colors duration-200">
            <Header 
              cartCount={cartCount}
              onOpenCart={() => setIsCartOpen(true)}
            />
            
            <main className="flex-grow">
              <Routes>
                <Route path="/" element={<Home onAddToCart={handleAddToCart} />} />
                <Route path="/shop" element={<Shop onAddToCart={handleAddToCart} />} />
                <Route path="/product/:id" element={<ProductDetail onAddToCart={handleAddToCart} />} />
                <Route path="/checkout" element={<Checkout cartItems={cartItems} clearCart={clearCart} />} />
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
              </Routes>
            </main>

            <Footer />

            <Toaster richColors position="top-right" />
            <CartDrawer 
              isOpen={isCartOpen}
              onClose={() => setIsCartOpen(false)}
              items={cartItems}
              onUpdateQuantity={handleUpdateQuantity}
              onRemove={handleRemoveItem}
              clearCart={clearCart}
            />
          </div>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}
