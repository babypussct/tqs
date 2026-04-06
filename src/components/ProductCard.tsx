import { Product } from '../types';
import { ShoppingCart, AlertTriangle, Lock } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

interface ProductCardProps {
  product: Product;
  onClick?: (id: string) => void;
  onAddToCart?: (product: Product) => void;
}

export default function ProductCard({ product, onClick, onAddToCart }: ProductCardProps) {
  const { appUser } = useAuth();
  
  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
  };

  const TIER_ORDER = ['bronze', 'silver', 'gold', 'diamond'];
  const userTierIdx = appUser ? TIER_ORDER.indexOf(appUser.tier) : -1;
  const reqTierIdx = product.minTierRequired ? TIER_ORDER.indexOf(product.minTierRequired) : -1;
  const isTierLocked = reqTierIdx !== -1 && userTierIdx < reqTierIdx;

  const TIER_COLORS: Record<string, string> = {
    bronze: 'bg-amber-700',
    silver: 'bg-slate-400',
    gold: 'bg-yellow-500',
    diamond: 'bg-blue-500',
  };

  return (
    <div 
      onClick={() => onClick && onClick(product.id)}
      className="group flex flex-col bg-white dark:bg-zinc-900 rounded-xl border border-gray-200 dark:border-zinc-800 overflow-hidden hover:border-red-500 dark:hover:border-red-500 hover:shadow-lg transition-all duration-300 cursor-pointer"
    >
      <div className="relative aspect-square overflow-hidden bg-gray-50 dark:bg-zinc-800">
        <div className="absolute top-3 left-3 z-10 flex flex-col gap-2">
          {product.badge && (
            <div className="bg-red-600 text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider w-fit shadow-sm">
              {product.badge}
            </div>
          )}
          {product.minTierRequired && (
            <div className={`text-white text-[10px] font-bold px-2 py-0.5 rounded flex items-center gap-1 uppercase tracking-wider shadow-sm w-fit ${isTierLocked ? 'bg-zinc-800' : TIER_COLORS[product.minTierRequired] || 'bg-indigo-600'}`}>
              {isTierLocked ? <Lock className="w-3 h-3" /> : null}
              {product.minTierRequired}
            </div>
          )}
        </div>
        {product.image ? (
          <img 
            src={product.image} 
            alt={product.name} 
            className="w-full h-full object-contain p-4 group-hover:scale-105 transition-transform duration-500"
            referrerPolicy="no-referrer"
          />
        ) : (
          <div className="w-full h-full bg-gray-200 dark:bg-zinc-700 flex items-center justify-center text-gray-500 dark:text-zinc-400">
            No Image
          </div>
        )}
        
        {/* Quick Add Overlay for Desktop */}
        <div className="hidden lg:block absolute inset-x-0 bottom-0 p-4 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-black/60 to-transparent">
          <button 
            onClick={(e) => {
              e.stopPropagation();
              if (isTierLocked) return;
              if (product.stock !== undefined && product.stock <= 0) return;
              if (onAddToCart) onAddToCart(product);
            }}
            disabled={isTierLocked || (product.stock !== undefined && product.stock <= 0)}
            className={`w-full font-bold py-2.5 rounded-lg flex items-center justify-center gap-2 transition-colors shadow-sm ${isTierLocked || (product.stock !== undefined && product.stock <= 0) ? 'bg-gray-300 dark:bg-zinc-700 text-gray-500 dark:text-zinc-400 cursor-not-allowed' : 'bg-white dark:bg-zinc-900 text-red-600 dark:text-red-500 hover:bg-red-50 dark:hover:bg-zinc-800'}`}
          >
            {isTierLocked ? <Lock className="h-4 w-4" /> : <ShoppingCart className="h-4 w-4" />}
            {isTierLocked ? 'Độc quyền Hạng ' + product.minTierRequired?.toUpperCase() : (product.stock !== undefined && product.stock <= 0 ? 'Hết hàng' : 'Thêm Nhanh')}
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 flex flex-col flex-grow">
        {/* Warning for Expansions */}
        {product.requiresBase && (
          <div className="flex items-center gap-1.5 text-amber-600 dark:text-amber-500 text-[11px] font-medium mb-2 bg-amber-50 dark:bg-amber-500/10 w-fit px-2 py-1 rounded border border-amber-100 dark:border-amber-500/20">
            <AlertTriangle className="h-3 w-3" />
            Cần Bản Cơ Bản
          </div>
        )}

        <h3 className="text-gray-900 dark:text-zinc-100 font-medium text-sm leading-snug mb-2 line-clamp-2 group-hover:text-red-600 dark:group-hover:text-red-400 transition-colors">
          {product.name}
        </h3>

        {/* Specs */}
        <div className="flex flex-wrap gap-1.5 mb-3 mt-auto">
          {product.size && (
            <span className="text-[10px] text-gray-500 dark:text-zinc-400 bg-gray-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded border border-gray-200 dark:border-zinc-700">
              Sleeves: {product.size}
            </span>
          )}
          {product.players && (
            <span className="text-[10px] text-gray-500 dark:text-zinc-400 bg-gray-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded border border-gray-200 dark:border-zinc-700">
              {product.players} người
            </span>
          )}
        </div>

        {/* Price and Mobile Add to Cart */}
        <div className="flex flex-wrap items-end justify-between gap-2 mt-auto pt-2">
          <div className="flex flex-col">
            <span className="text-base sm:text-lg font-bold text-red-600 dark:text-red-500">{formatPrice(product.price)}</span>
            {product.originalPrice && (
              <span className="text-[10px] sm:text-xs text-gray-400 dark:text-zinc-500 line-through">
                {formatPrice(product.originalPrice)}
              </span>
            )}
          </div>
          
          <button
            onClick={(e) => {
              e.stopPropagation();
              if (isTierLocked || (product.stock !== undefined && product.stock <= 0)) return;
              if (onAddToCart) onAddToCart(product);
            }}
            disabled={isTierLocked || (product.stock !== undefined && product.stock <= 0)}
            className={`lg:hidden p-2.5 rounded-full flex items-center justify-center transition-colors shadow-sm min-h-[44px] min-w-[44px] ${isTierLocked || (product.stock !== undefined && product.stock <= 0) ? 'bg-gray-100 dark:bg-zinc-800 text-gray-400 cursor-not-allowed' : 'bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-500 active:bg-red-100'}`}
          >
            {isTierLocked ? <Lock className="h-5 w-5" /> : <ShoppingCart className="h-5 w-5" />}
          </button>
        </div>
      </div>
    </div>
  );
}
