import { X, Plus, Minus, Trash2, ShoppingBag, Truck } from 'lucide-react';
import { useNavigate, Link } from 'react-router-dom';
import { CartItem } from '../types';
import { useShippingConfig } from '../hooks/useShippingConfig';

interface CartDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  items: CartItem[];
  onUpdateQuantity: (id: string, deltaOrQuantity: number, isAbsolute?: boolean) => void;
  onRemove: (id: string) => void;
  clearCart: () => void;
}

export default function CartDrawer({ isOpen, onClose, items, onUpdateQuantity, onRemove, clearCart }: CartDrawerProps) {
  const navigate = useNavigate();
  const { shippingConfig } = useShippingConfig();
  
  const totalPrice = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  
  // Calculate if cart has any freeship products
  const hasFreeshipProduct = items.some(item => 
    shippingConfig.freeshipProductIds.includes(item.product.id)
  );

  const threshold = shippingConfig.freeshipThreshold ?? 0;
  
  let progress = 100;
  let remainingForFreeship = 0;

  if (shippingConfig.isActive && !hasFreeshipProduct && threshold > 0) {
     progress = Math.min((totalPrice / threshold) * 100, 100);
     remainingForFreeship = Math.max(threshold - totalPrice, 0);
  }

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex justify-end">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
        onClick={onClose}
      />
      
      {/* Drawer */}
      <div className="relative w-full max-w-md bg-white dark:bg-zinc-950 h-full flex flex-col shadow-2xl border-l border-gray-200 dark:border-zinc-800 animate-in slide-in-from-right duration-300">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-100 dark:border-zinc-800 bg-gray-50 dark:bg-zinc-900">
          <div className="flex items-center gap-3">
            <ShoppingBag className="h-6 w-6 text-gray-900 dark:text-white" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white uppercase tracking-tight">Giỏ Hàng</h2>
            <span className="bg-red-600 text-white text-xs font-bold px-2 py-0.5 rounded-full">
              {items.reduce((sum, item) => sum + item.quantity, 0)}
            </span>
          </div>
          <div className="flex items-center gap-2">
            {items.length > 0 && (
              <button 
                onClick={() => {
                  if (window.confirm('Bạn có chắc chắn muốn xóa toàn bộ giỏ hàng?')) {
                    clearCart();
                  }
                }}
                className="text-xs font-medium text-red-600 dark:text-red-500 hover:text-red-700 dark:hover:text-red-400 px-2 py-1 bg-red-50 dark:bg-red-500/10 rounded-md transition-colors"
              >
                Xóa tất cả
              </button>
            )}
            <button 
              onClick={onClose}
              className="p-2 hover:bg-gray-200 dark:hover:bg-zinc-800 rounded-full text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Freeship Progress */}
        {shippingConfig.isActive && threshold > 0 && (
          <div className="p-6 bg-white dark:bg-zinc-950 border-b border-gray-100 dark:border-zinc-800">
            <div className="flex items-center gap-2 mb-3">
              <Truck className={`h-5 w-5 ${progress === 100 ? 'text-emerald-500' : 'text-gray-400 dark:text-zinc-500'}`} />
              <p className="text-sm font-medium text-gray-600 dark:text-zinc-300">
                {progress === 100 ? (
                  <span className="text-emerald-600 dark:text-emerald-500 font-bold">
                    {hasFreeshipProduct ? 'Đơn hàng có sản phẩm được Freeship!' : 'Chúc mừng! Bạn đã được Freeship.'}
                  </span>
                ) : (
                  <>Mua thêm <strong className="text-blue-600 dark:text-blue-500">{formatPrice(remainingForFreeship)}</strong> nữa để được Freeship</>
                )}
              </p>
            </div>
            <div className="h-2 w-full bg-gray-100 dark:bg-zinc-800 rounded-full overflow-hidden">
              <div 
                className={`h-full transition-all duration-500 rounded-full ${progress === 100 ? 'bg-emerald-500' : 'bg-blue-600'}`}
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}

        {/* Cart Items */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6 bg-gray-50/50 dark:bg-zinc-900/50">
          {items.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-gray-400 dark:text-zinc-500 space-y-4">
              <ShoppingBag className="h-16 w-16 opacity-20" />
              <p>Giỏ hàng của bạn đang trống</p>
              <button 
                onClick={() => { onClose(); navigate('/shop'); }}
                className="text-red-600 dark:text-red-500 font-bold uppercase text-sm hover:text-red-700 dark:hover:text-red-400"
              >
                Tiếp tục mua sắm
              </button>
            </div>
          ) : (
            items.map((item) => {
              const totalProductQuantity = items
                .filter(i => i.product.id === item.product.id)
                .reduce((sum, i) => sum + i.quantity, 0);
                
              return (
              <div key={item.id} className="flex gap-4 bg-white dark:bg-zinc-900 p-3 rounded-xl border border-gray-100 dark:border-zinc-800 shadow-sm">
                <Link to={`/product/${item.product.id}`} onClick={onClose} className="w-20 h-20 rounded-lg overflow-hidden bg-gray-50 dark:bg-zinc-800 shrink-0 border border-gray-100 dark:border-zinc-700 block transition-transform hover:scale-105">
                  {item.product.image ? (
                    <img src={item.product.image} alt={item.product.name} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                  )}
                </Link>
                <div className="flex-1 flex flex-col justify-between">
                  <div>
                    <Link to={`/product/${item.product.id}`} onClick={onClose} className="text-gray-900 dark:text-white font-medium text-sm line-clamp-2 leading-snug mb-1 hover:text-red-600 dark:hover:text-red-500 transition-colors">
                      {item.product.name}
                    </Link>
                    <div className="text-xs text-gray-500 dark:text-zinc-400 space-y-0.5">
                      {item.selectedLang && <div>Ngôn ngữ: {item.selectedLang}</div>}
                      {item.selectedBox && <div>Loại hộp: {item.selectedBox}</div>}
                      {item.selectedVariants && Object.entries(item.selectedVariants).map(([k, v]) => (
                        <div key={k}>{k}: {v}</div>
                      ))}
                      {item.quickAddAccessoryNames?.map(name => (
                        <div key={name} className="text-emerald-600 dark:text-emerald-500">+ {name}</div>
                      ))}
                      {item.addSleeves && !item.quickAddAccessoryNames && <div className="text-emerald-600 dark:text-emerald-500">+ {(item as any).quickAddAccessoryName || '200 Sleeves'}</div>}
                    </div>
                  </div>
                  <div className="flex items-end justify-between mt-2">
                    <span className="text-red-600 dark:text-red-500 font-bold">{formatPrice(item.price)}</span>
                    
                    <div className="flex items-center gap-3">
                      <div className="flex items-center bg-gray-50 dark:bg-zinc-800 rounded-lg border border-gray-200 dark:border-zinc-700">
                        <button 
                          onClick={() => onUpdateQuantity(item.id, -1)}
                          className="p-1.5 text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                        >
                          <Minus className="h-3.5 w-3.5" />
                        </button>
                        <input 
                          type="number"
                          min="1"
                          value={item.quantity}
                          onBlur={(e) => {
                            let val = parseInt(e.target.value);
                            if (isNaN(val) || val < 1) val = 1;
                            if (item.product.stock !== undefined && val > item.product.stock) val = item.product.stock;
                            onUpdateQuantity(item.id, val, true);
                          }}
                          onChange={(e) => {
                            const val = parseInt(e.target.value);
                            if (!isNaN(val)) onUpdateQuantity(item.id, val, true);
                          }}
                          className="w-10 text-center text-sm font-medium text-gray-900 dark:text-white bg-transparent border-none p-0 focus:ring-0 focus:outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                        />
                        <button 
                          onClick={() => onUpdateQuantity(item.id, 1)}
                          disabled={item.product.stock !== undefined && totalProductQuantity >= item.product.stock}
                          className={`p-1.5 transition-colors ${item.product.stock !== undefined && totalProductQuantity >= item.product.stock ? 'text-gray-300 dark:text-zinc-600 cursor-not-allowed' : 'text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white'}`}
                        >
                          <Plus className="h-3.5 w-3.5" />
                        </button>
                      </div>
                      <button 
                        onClick={() => onRemove(item.id)}
                        className="p-1.5 text-gray-400 dark:text-zinc-500 hover:text-red-600 dark:hover:text-red-500 transition-colors"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )})
          )}
        </div>

        {/* Footer */}
        {items.length > 0 && (
          <div className="p-6 bg-white dark:bg-zinc-950 border-t border-gray-200 dark:border-zinc-800 shadow-[0_-10px_20px_rgba(0,0,0,0.02)] dark:shadow-[0_-10px_20px_rgba(0,0,0,0.2)]">
            <div className="flex items-center justify-between mb-4">
              <span className="text-gray-500 dark:text-zinc-400 font-medium">Tổng tiền</span>
              <span className="text-2xl font-black text-red-600 dark:text-red-500">{formatPrice(totalPrice)}</span>
            </div>
            <button 
              onClick={() => {
                onClose();
                navigate('/checkout');
              }}
              className="w-full bg-red-600 hover:bg-red-700 text-white font-bold text-lg py-4 rounded-xl transition-all shadow-sm"
            >
              Thanh Toán Ngay
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
