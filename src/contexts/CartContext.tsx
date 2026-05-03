import React, { createContext, useContext, useState, useEffect, useCallback, useMemo } from 'react';
import { toast } from 'sonner';
import { Product, CartItem } from '../types';

interface CartContextType {
  cartItems: CartItem[];
  cartCount: number;
  isCartOpen: boolean;
  setIsCartOpen: (isOpen: boolean) => void;
  addToCart: (
    product: Product, 
    variants?: { 
      selectedBox?: string, 
      selectedLang?: string, 
      selectedVariants?: Record<string, string>,
      addSleeves?: boolean, 
      quickAddAccessoryNames?: string[],
      price: number 
    }
  ) => void;
  updateQuantity: (id: string, deltaOrQuantity: number, isAbsolute?: boolean) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
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

  useEffect(() => {
    localStorage.setItem('tqs_cart', JSON.stringify(cartItems));
  }, [cartItems]);

  const addToCart = useCallback((
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
    
    setCartItems(prev => {
      // Check stock before updating state
      const totalProductQuantity = prev
        .filter(item => item.product.id === product.id)
        .reduce((sum, item) => sum + item.quantity, 0);

      if (product.stock !== undefined && totalProductQuantity >= product.stock) {
        toast.error(`Chỉ còn ${product.stock} sản phẩm trong kho`);
        return prev;
      }

      const existingInPrev = prev.find(item => item.id === id);
      if (existingInPrev) {
        toast.success(`Đã thêm ${product.name} vào giỏ hàng`);
        setIsCartOpen(true);
        return prev.map(item => item.id === id ? { ...item, quantity: item.quantity + 1 } : item);
      }
      
      toast.success(`Đã thêm ${product.name} vào giỏ hàng`);
      setIsCartOpen(true);
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
  }, []);

  const updateQuantity = useCallback((id: string, deltaOrQuantity: number, isAbsolute: boolean = false) => {
    setCartItems(prev => {
      const itemToUpdate = prev.find(i => i.id === id);
      if (!itemToUpdate) return prev;

      let newQuantity = isAbsolute ? deltaOrQuantity : itemToUpdate.quantity + deltaOrQuantity;
      newQuantity = Math.max(1, newQuantity);
      
      // Only check stock if we are increasing quantity
      if (newQuantity > itemToUpdate.quantity && itemToUpdate.product.stock !== undefined) {
        const totalProductQuantity = prev
          .filter(item => item.product.id === itemToUpdate.product.id)
          .reduce((sum, item) => sum + (item.id === id ? newQuantity : item.quantity), 0);
          
        if (totalProductQuantity > itemToUpdate.product.stock) {
          toast.error(`Chỉ còn ${itemToUpdate.product.stock} sản phẩm trong kho`);
          if (isAbsolute) {
            // Fallback to maximum available for absolute input
            const currentTotalExceptThis = prev
              .filter(item => item.product.id === itemToUpdate.product.id && item.id !== id)
              .reduce((sum, item) => sum + item.quantity, 0);
            const maxAllowed = itemToUpdate.product.stock - currentTotalExceptThis;
            if (maxAllowed >= 1) newQuantity = maxAllowed;
            else return prev;
          } else {
            return prev;
          }
        }
      }

      return prev.map(item => item.id === id ? { ...item, quantity: newQuantity } : item);
    });
  }, []);

  const removeItem = useCallback((id: string) => {
    setCartItems(prev => prev.filter(item => item.id !== id));
    toast.success(`Đã xóa sản phẩm khỏi giỏ hàng`);
  }, []);

  const clearCart = useCallback(() => {
    setCartItems([]);
  }, []);

  const cartCount = useMemo(() => cartItems.reduce((sum, item) => sum + item.quantity, 0), [cartItems]);

  const value = useMemo(() => ({
    cartItems,
    cartCount,
    isCartOpen,
    setIsCartOpen,
    addToCart,
    updateQuantity,
    removeItem,
    clearCart
  }), [cartItems, cartCount, isCartOpen, addToCart, updateQuantity, removeItem, clearCart]);

  return (
    <CartContext.Provider value={value}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (context === undefined) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
}
