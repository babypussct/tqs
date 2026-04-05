import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, ShoppingCart, AlertTriangle, ShieldCheck, PackageOpen, Check } from 'lucide-react';
import { Product } from '../types';
import { useProducts } from '../hooks/useProducts';
import { useSiteConfig } from '../hooks/useSiteConfig';
import ProductReviews from './ProductReviews';
import ProductCard from './ProductCard';

interface ProductDetailProps {
  onAddToCart: (product: Product, variants: { selectedBox?: string, selectedLang?: string, selectedVariants?: Record<string, string>, addSleeves?: boolean, quickAddAccessoryNames?: string[], price: number }) => void;
}

export default function ProductDetail({ onAddToCart }: ProductDetailProps) {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { products, loading } = useProducts(true);
  const { config: siteConfig } = useSiteConfig();
  const product = products.find(p => p.id === id);

  const [selectedBox, setSelectedBox] = useState('');
  const [selectedLang, setSelectedLang] = useState('');
  const [selectedVariants, setSelectedVariants] = useState<Record<string, string>>({});
  const [selectedQuickAdds, setSelectedQuickAdds] = useState<string[]>([]);
  const [activeImage, setActiveImage] = useState('');
  const [selectedAddonIds, setSelectedAddonIds] = useState<string[]>([]);

  useEffect(() => {
    if (product) {
      setSelectedBox(product.variants?.boxType?.[0] || '');
      setSelectedLang(product.variants?.language?.[0] || '');
      
      const initialVariants: Record<string, string> = {};
      if (product.customVariants) {
        product.customVariants.forEach(v => {
          if (v.options && v.options.length > 0) {
            initialVariants[v.name] = v.options[0].name;
          }
        });
      }
      setSelectedVariants(initialVariants);
      
      setSelectedQuickAdds([]);
      setActiveImage(product.image);
      setSelectedAddonIds([]);
      window.scrollTo(0, 0);
    }
  }, [product]);

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-20 text-center">
        <h2 className="text-2xl font-bold text-gray-500 dark:text-zinc-400 mb-4">Đang tải thông tin sản phẩm...</h2>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-20 text-center">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Không tìm thấy sản phẩm</h2>
        <button onClick={() => navigate('/shop')} className="text-red-600 dark:text-red-500 hover:text-red-700 dark:hover:text-red-400">Quay lại cửa hàng</button>
      </div>
    );
  }
  
  const quickAdds = product.quickAddAccessories || ((product as any).quickAddAccessory ? [(product as any).quickAddAccessory] : []);
  if (quickAdds.length === 0 && product.size) {
    quickAdds.push({
      name: 'Mua kèm 200 Bọc bài (Sleeves)',
      price: 50000,
      description: `Size chuẩn ${product.size} vừa khít thẻ bài. Bảo vệ bài không trầy xước, chống nước.`
    });
  }

  const BOX_UPGRADE_PRICE = selectedBox.includes('Hộp Sắt') ? 50000 : 0;
  
  let customVariantsPrice = 0;
  if (product.customVariants) {
    product.customVariants.forEach(v => {
      const selectedOptName = selectedVariants[v.name];
      if (selectedOptName) {
        const opt = v.options.find(o => (typeof o === 'string' ? o : o.name) === selectedOptName);
        if (opt && typeof opt !== 'string' && opt.priceAdjustment) {
          customVariantsPrice += opt.priceAdjustment;
        }
      }
    });
  }

  const quickAddsPrice = quickAdds.filter(qa => selectedQuickAdds.includes(qa.name)).reduce((sum, qa) => sum + qa.price, 0);
  
  const addonProducts = products.filter(p => product.addonIds?.includes(p.id));
  const addonsTotal = addonProducts.filter(p => selectedAddonIds.includes(p.id)).reduce((sum, p) => sum + p.price, 0);
  
  const totalPrice = product.price + BOX_UPGRADE_PRICE + customVariantsPrice + quickAddsPrice;
  const finalTotalPrice = totalPrice + addonsTotal;

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
  };

  const relatedProducts = products
    .filter(p => p.type === product.type && p.id !== product.id)
    .slice(0, 4);

  const handleAddToCart = () => {
    // Add main product
    onAddToCart(product, {
      selectedBox: product.variants?.boxType ? selectedBox : undefined,
      selectedLang: product.variants?.language ? selectedLang : undefined,
      selectedVariants: Object.keys(selectedVariants).length > 0 ? selectedVariants : undefined,
      quickAddAccessoryNames: selectedQuickAdds.length > 0 ? selectedQuickAdds : undefined,
      price: totalPrice
    });
    
    // Add selected addons
    selectedAddonIds.forEach(addonId => {
      const addon = addonProducts.find(p => p.id === addonId);
      if (addon) {
        onAddToCart(addon, { price: addon.price });
      }
    });
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <button 
        onClick={() => navigate(-1)}
        className="flex items-center gap-2 text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors mb-8 font-medium"
      >
        <ArrowLeft className="h-4 w-4" />
        Quay lại
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
        {/* Left: Image Gallery */}
        <div className="space-y-4">
          <div className="rounded-2xl overflow-hidden border border-gray-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 relative flex items-center justify-center min-h-[300px]">
            {product.badge && (
              <div className="absolute top-4 left-4 z-10 bg-red-600 text-white text-sm font-bold px-4 py-1.5 rounded-full uppercase tracking-wider shadow-lg shadow-red-600/20">
                {product.badge}
              </div>
            )}
            {activeImage ? (
              <img 
                src={activeImage} 
                alt={product.name} 
                className="w-full h-auto max-h-[600px] object-contain"
                referrerPolicy="no-referrer"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500">No Image</div>
            )}
          </div>
          
          {/* Thumbnails */}
          {product.images && product.images.length > 0 && (
            <div className="flex gap-3 overflow-x-auto pb-2 custom-scrollbar">
              <button 
                onClick={() => setActiveImage(product.image)} 
                className={`w-20 h-20 shrink-0 rounded-xl border-2 overflow-hidden transition-all ${activeImage === product.image ? 'border-red-500 shadow-md' : 'border-transparent hover:border-gray-300 dark:hover:border-zinc-700'}`}
              >
                {product.image ? (
                  <img src={product.image} className="w-full h-full object-contain p-1" referrerPolicy="no-referrer" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                )}
              </button>
              {product.images.map((img, idx) => (
                <button 
                  key={idx} 
                  onClick={() => setActiveImage(img)} 
                  className={`w-20 h-20 shrink-0 rounded-xl border-2 overflow-hidden bg-white dark:bg-zinc-900 transition-all ${activeImage === img ? 'border-red-500 shadow-md' : 'border-transparent hover:border-gray-300 dark:hover:border-zinc-700'}`}
                >
                  {img ? (
                    <img src={img} className="w-full h-full object-contain p-1" referrerPolicy="no-referrer" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">No Image</div>
                  )}
                </button>
              ))}
            </div>
          )}

          {/* Trust Banner under image */}
          <div className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800 rounded-xl p-4 flex items-center justify-center gap-6">
            <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-zinc-300">
              <ShieldCheck className="h-5 w-5 text-emerald-600 dark:text-emerald-500" />
              <span>Chính hãng 100%</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-zinc-300">
              <PackageOpen className="h-5 w-5 text-amber-600 dark:text-amber-500" />
              <span>Đóng gói Anti-Móp</span>
            </div>
          </div>
        </div>

        {/* Right: Product Info & Actions */}
        <div className="flex flex-col">
          {/* Warning for Expansions */}
          {product.requiresBase && (
            <div className="flex items-start gap-3 bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 rounded-xl p-4 mb-6">
              <AlertTriangle className="h-6 w-6 text-amber-600 dark:text-amber-500 shrink-0 mt-0.5" />
              <div>
                <h4 className="text-amber-800 dark:text-amber-500 font-bold">Lưu ý quan trọng</h4>
                <p className="text-amber-700 dark:text-amber-500/80 text-sm mt-1">
                  Đây là bản mở rộng. Bạn bắt buộc phải có <strong>Bản Cơ Bản</strong> (Tiêu Chuẩn) mới có thể chơi được.
                </p>
              </div>
            </div>
          )}

          <h1 className="text-3xl sm:text-4xl font-black text-gray-900 dark:text-white leading-tight mb-3">
            {product.name}
          </h1>

          <div className="flex items-center gap-4 mb-6 text-sm text-gray-500 dark:text-zinc-400">
            {product.soldCount !== undefined && (
              <div className="flex items-center gap-1.5">
                <span className="text-amber-500">★</span>
                <span>Đã bán {product.soldCount >= 1000 ? `${(product.soldCount / 1000).toFixed(1)}k` : product.soldCount}</span>
              </div>
            )}
            {product.stock !== undefined && (
              <div className="flex items-center gap-1.5">
                <PackageOpen className="w-4 h-4" />
                <span>Kho: {product.stock}</span>
              </div>
            )}
          </div>

          <div className="flex items-end gap-3 mb-8 pb-8 border-b border-gray-200 dark:border-zinc-800">
            <span className="text-4xl font-bold text-red-600 dark:text-red-500">{formatPrice(totalPrice)}</span>
            {product.originalPrice && selectedQuickAdds.length === 0 && !BOX_UPGRADE_PRICE && (
              <span className="text-xl text-gray-400 dark:text-zinc-500 line-through mb-1">
                {formatPrice(product.originalPrice)}
              </span>
            )}
          </div>

          {/* Variants Selector */}
          {(product.variants || (product.customVariants && product.customVariants.length > 0)) && (
            <div className="space-y-6 mb-8">
              {product.variants?.language && (
                <div>
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white uppercase tracking-wider mb-3">Ngôn Ngữ</h3>
                  <div className="flex flex-wrap gap-3">
                    {product.variants.language.map(lang => (
                      <button
                        key={lang}
                        onClick={() => setSelectedLang(lang)}
                        className={`px-4 py-2 rounded-lg border text-sm font-medium transition-all ${
                          selectedLang === lang 
                            ? 'bg-red-50 dark:bg-red-600/10 border-red-600 text-red-600 dark:text-red-500' 
                            : 'bg-white dark:bg-zinc-900 border-gray-300 dark:border-zinc-700 text-gray-700 dark:text-zinc-300 hover:border-gray-400 dark:hover:border-zinc-500'
                        }`}
                      >
                        {lang}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {product.variants?.boxType && (
                <div>
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white uppercase tracking-wider mb-3">Loại Hộp</h3>
                  <div className="flex flex-wrap gap-3">
                    {product.variants.boxType.map(box => (
                      <button
                        key={box}
                        onClick={() => setSelectedBox(box)}
                        className={`px-4 py-2 rounded-lg border text-sm font-medium transition-all ${
                          selectedBox === box 
                            ? 'bg-red-50 dark:bg-red-600/10 border-red-600 text-red-600 dark:text-red-500' 
                            : 'bg-white dark:bg-zinc-900 border-gray-300 dark:border-zinc-700 text-gray-700 dark:text-zinc-300 hover:border-gray-400 dark:hover:border-zinc-500'
                        }`}
                      >
                        {box}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {product.customVariants && product.customVariants.map((variant, idx) => (
                <div key={idx}>
                  <h3 className="text-sm font-bold text-gray-900 dark:text-white uppercase tracking-wider mb-3">{variant.name}</h3>
                  <div className="flex flex-wrap gap-3">
                    {variant.options.map((opt, optIdx) => {
                      const optName = typeof opt === 'string' ? opt : opt.name;
                      const optPrice = typeof opt === 'string' ? 0 : (opt.priceAdjustment || 0);
                      
                      return (
                      <button
                        key={optIdx}
                        onClick={() => setSelectedVariants({...selectedVariants, [variant.name]: optName})}
                        className={`px-4 py-2 rounded-lg border text-sm font-medium transition-all ${
                          selectedVariants[variant.name] === optName 
                            ? 'bg-red-50 dark:bg-red-600/10 border-red-600 text-red-600 dark:text-red-500' 
                            : 'bg-white dark:bg-zinc-900 border-gray-300 dark:border-zinc-700 text-gray-700 dark:text-zinc-300 hover:border-gray-400 dark:hover:border-zinc-500'
                        }`}
                      >
                        {optName} {optPrice ? `(+${formatPrice(optPrice)})` : ''}
                      </button>
                    )})}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Quick Add Accessories */}
          {quickAdds.length > 0 && (
            <div className="space-y-3 mb-6">
              {quickAdds.map((qa, idx) => {
                const isSelected = selectedQuickAdds.includes(qa.name);
                return (
                  <div key={idx} className="bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-xl p-4 transition-colors hover:border-gray-300 dark:hover:border-zinc-600 cursor-pointer" onClick={() => {
                    if (isSelected) {
                      setSelectedQuickAdds(selectedQuickAdds.filter(name => name !== qa.name));
                    } else {
                      setSelectedQuickAdds([...selectedQuickAdds, qa.name]);
                    }
                  }}>
                    <label className="flex items-start gap-3 cursor-pointer">
                      <div className={`mt-0.5 w-5 h-5 rounded border flex items-center justify-center shrink-0 transition-colors ${isSelected ? 'bg-emerald-500 border-emerald-500' : 'border-gray-300 dark:border-zinc-500 bg-white dark:bg-zinc-950'}`}>
                        {isSelected && <Check className="h-3.5 w-3.5 text-white" />}
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <span className="text-gray-900 dark:text-white font-medium">{qa.name}</span>
                          <span className="text-emerald-600 dark:text-emerald-400 font-bold">+{formatPrice(qa.price)}</span>
                        </div>
                        {qa.description && (
                          <p className="text-gray-500 dark:text-zinc-400 text-sm mt-1">
                            {qa.description}
                          </p>
                        )}
                      </div>
                    </label>
                  </div>
                );
              })}
            </div>
          )}

          {/* Add-ons / Frequently Bought Together */}
          {addonProducts.length > 0 && (
            <div className="mb-8">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                <PackageOpen className="w-5 h-5 text-red-500" /> Thường được mua cùng
              </h3>
              <div className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800 rounded-2xl p-4 space-y-3">
                {addonProducts.map(addon => (
                  <label key={addon.id} className="flex items-center gap-4 p-3 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-700 rounded-xl cursor-pointer hover:border-red-300 dark:hover:border-red-500/50 transition-colors">
                    <input 
                      type="checkbox" 
                      checked={selectedAddonIds.includes(addon.id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedAddonIds([...selectedAddonIds, addon.id]);
                        } else {
                          setSelectedAddonIds(selectedAddonIds.filter(id => id !== addon.id));
                        }
                      }}
                      className="w-5 h-5 text-red-600 rounded border-gray-300 focus:ring-red-500"
                    />
                    {addon.image ? (
                      <img src={addon.image} alt={addon.name} className="w-12 h-12 rounded-lg object-cover border border-gray-100 dark:border-zinc-800" referrerPolicy="no-referrer" />
                    ) : (
                      <div className="w-12 h-12 rounded-lg border border-gray-100 dark:border-zinc-800 flex items-center justify-center text-gray-400 dark:text-zinc-500 text-xs">Img</div>
                    )}
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-medium text-gray-900 dark:text-white truncate">{addon.name}</h4>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-sm font-bold text-red-600 dark:text-red-500">{formatPrice(addon.price)}</span>
                        {addon.originalPrice && (
                          <span className="text-xs text-gray-400 line-through">{formatPrice(addon.originalPrice)}</span>
                        )}
                      </div>
                    </div>
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Add to Cart */}
          <button 
            onClick={handleAddToCart}
            disabled={product.stock !== undefined && product.stock <= 0}
            className={`w-full font-bold text-lg py-4 rounded-xl flex items-center justify-center gap-2 transition-all transform hover:scale-[1.02] active:scale-[0.98] shadow-lg mb-12 ${product.stock !== undefined && product.stock <= 0 ? 'bg-gray-300 dark:bg-zinc-700 text-gray-500 dark:text-zinc-400 cursor-not-allowed shadow-none' : 'bg-red-600 hover:bg-red-700 text-white shadow-red-600/20'}`}
          >
            <ShoppingCart className="h-5 w-5" />
            {product.stock !== undefined && product.stock <= 0 ? 'Hết hàng' : `Thêm Vào Giỏ Hàng - ${formatPrice(finalTotalPrice)}`}
          </button>

        </div>
      </div>

      {/* SEO Description & Specs (Full Width Section) */}
      <div className="mt-16 bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 lg:p-10 shadow-sm max-w-5xl mx-auto">
        <h2 className="text-2xl font-black text-gray-900 dark:text-white mb-8 border-b-2 border-red-500 inline-block pb-2">
          Thông tin sản phẩm
        </h2>
        
        <div className="prose prose-lg prose-red dark:prose-invert max-w-none">
          {product.description ? (
            <div 
              className="text-gray-800 dark:text-gray-200 leading-relaxed ck-content"
              dangerouslySetInnerHTML={{ __html: product.description }}
            />
          ) : (
            <p className="text-gray-700 dark:text-zinc-300 leading-relaxed mb-6">
              Sản phẩm boardgame Tam Quốc Sát chính hãng.
            </p>
          )}
        </div>

        {product.specifications && product.specifications.length > 0 ? (
          <div className="mt-10 bg-gray-50 dark:bg-zinc-900/50 rounded-xl p-6 border border-gray-200 dark:border-zinc-800">
            <h4 className="text-gray-900 dark:text-white font-bold mb-4 text-lg">Thông số kỹ thuật:</h4>
            <ul className="space-y-3 text-gray-700 dark:text-zinc-300">
              {product.specifications.map((spec, idx) => (
                <li key={idx} className="flex items-start gap-3">
                  <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">{spec.name}:</span>
                  <span className="font-semibold text-gray-900 dark:text-white">{spec.value}</span>
                </li>
              ))}
              {product.size && (
                <li className="flex items-start gap-3">
                  <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">Kích thước:</span>
                  <span className="font-semibold text-amber-600 dark:text-amber-400">{product.size} (Cần mua sleeves đúng size này)</span>
                </li>
              )}
            </ul>
          </div>
        ) : product.specs ? (
          <div className="mt-10 bg-gray-50 dark:bg-zinc-900/50 rounded-xl p-6 border border-gray-200 dark:border-zinc-800">
            <h4 className="text-gray-900 dark:text-white font-bold mb-4 text-lg">Thông số kỹ thuật:</h4>
            <ul className="space-y-3 text-gray-700 dark:text-zinc-300">
              <li className="flex items-start gap-3">
                <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">Số lượng thẻ:</span>
                <span className="font-semibold text-gray-900 dark:text-white">{product.specs.cardCount} lá</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">Kích thước:</span>
                <span className="font-semibold text-amber-600 dark:text-amber-400">{product.size} (Cần mua sleeves đúng size này)</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">Chất liệu:</span>
                <span className="font-semibold text-gray-900 dark:text-white">{product.specs.material}</span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-gray-500 dark:text-zinc-500 w-32 shrink-0 font-medium">Phe phái:</span>
                <span className="font-semibold text-gray-900 dark:text-white">{product.specs.factions?.join(', ')}</span>
              </li>
            </ul>
          </div>
        ) : null}

        <div className="mt-8 p-6 bg-emerald-50 dark:bg-emerald-950/20 rounded-xl border-l-4 border-emerald-500">
          <h4 className="text-emerald-700 dark:text-emerald-400 font-bold mb-2">Cam kết đóng gói chuẩn Sưu Tầm</h4>
          <p 
            className="text-emerald-800/80 dark:text-emerald-200/70 text-sm leading-relaxed ck-content"
            dangerouslySetInnerHTML={{ __html: siteConfig?.packagingCommitment || 'Chúng tôi hiểu hộp game nguyên vẹn quan trọng thế nào với người chơi. Mọi đơn hàng đều được bọc <strong>3 lớp xốp bóng khí chống sốc</strong> và đặt trong <strong>hộp carton cứng cáp</strong>. Hoàn tiền 100% nếu hộp game bị móp méo do vận chuyển!' }}
          />
        </div>
      </div>

      {/* Product Reviews Section */}
      <ProductReviews productId={product.id} />

      {/* Related Products Section */}
      {relatedProducts.length > 0 && (
        <div className="mt-16 border-t border-gray-200 dark:border-zinc-800 pt-16">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-8">Sản phẩm liên quan</h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-6">
            {relatedProducts.map(relatedProduct => (
              <ProductCard
                key={relatedProduct.id}
                product={relatedProduct}
                onAddToCart={(p) => onAddToCart(p, { price: p.price })}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
