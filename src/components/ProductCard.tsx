import { Product } from '../types';
import { ShoppingCart, AlertTriangle } from 'lucide-react';

interface ProductCardProps {
  product: Product;
  onClick?: (id: string) => void;
  onAddToCart?: (product: Product) => void;
}

export default function ProductCard({ product, onClick, onAddToCart }: ProductCardProps) {
  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
  };

  return (
    <div 
      onClick={() => onClick && onClick(product.id)}
      className="group flex flex-col bg-white dark:bg-zinc-900 rounded-xl border border-gray-200 dark:border-zinc-800 overflow-hidden hover:border-red-500 dark:hover:border-red-500 hover:shadow-lg transition-all duration-300 cursor-pointer"
    >
      {/* Image Container */}
      <div className="relative aspect-square overflow-hidden bg-gray-50 dark:bg-zinc-800">
        {product.badge && (
          <div className="absolute top-3 left-3 z-10 bg-red-600 text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider">
            {product.badge}
          </div>
        )}
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
        
        {/* Quick Add Overlay */}
        <div className="absolute inset-x-0 bottom-0 p-4 translate-y-full group-hover:translate-y-0 transition-transform duration-300 bg-gradient-to-t from-black/60 to-transparent">
          <button 
            onClick={(e) => {
              e.stopPropagation();
              if (product.stock !== undefined && product.stock <= 0) return;
              if (onAddToCart) onAddToCart(product);
            }}
            disabled={product.stock !== undefined && product.stock <= 0}
            className={`w-full font-bold py-2.5 rounded-lg flex items-center justify-center gap-2 transition-colors shadow-sm ${product.stock !== undefined && product.stock <= 0 ? 'bg-gray-300 dark:bg-zinc-700 text-gray-500 dark:text-zinc-400 cursor-not-allowed' : 'bg-white dark:bg-zinc-900 text-red-600 dark:text-red-500 hover:bg-red-50 dark:hover:bg-zinc-800'}`}
          >
            <ShoppingCart className="h-4 w-4" />
            {product.stock !== undefined && product.stock <= 0 ? 'Hết hàng' : 'Thêm Nhanh'}
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

        {/* Price */}
        <div className="flex items-end gap-2 mt-auto">
          <span className="text-lg font-bold text-red-600 dark:text-red-500">{formatPrice(product.price)}</span>
          {product.originalPrice && (
            <span className="text-xs text-gray-400 dark:text-zinc-500 line-through mb-0.5">
              {formatPrice(product.originalPrice)}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
