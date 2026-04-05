import React, { useState, useMemo, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Filter, X, ArrowUpDown } from 'lucide-react';
import ProductCard from './ProductCard';
import { useProducts } from '../hooks/useProducts';
import { useProductConfig } from '../hooks/useProductConfig';
import { Product } from '../types';

interface ShopProps {
  onAddToCart: (product: Product) => void;
}

export default function Shop({ onAddToCart }: ShopProps) {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const searchQuery = searchParams.get('q') || '';
  const typeQuery = searchParams.get('type');
  
  const { products, loading } = useProducts(true);
  const { config: productConfig } = useProductConfig();
  const [isMobileFilterOpen, setIsMobileFilterOpen] = useState(false);
  
  // Filter States
  const [selectedTypes, setSelectedTypes] = useState<string[]>(typeQuery ? [typeQuery] : []);
  const [selectedLangs, setSelectedLangs] = useState<string[]>([]);
  const [sortBy, setSortBy] = useState<string>('newest');
  
  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 12;

  useEffect(() => {
    if (typeQuery) {
      setSelectedTypes([typeQuery]);
    } else {
      setSelectedTypes([]);
    }
    setCurrentPage(1); // Reset page on type change
  }, [typeQuery]);

  const toggleFilter = (setState: React.Dispatch<React.SetStateAction<string[]>>, value: string) => {
    setState(prev => 
      prev.includes(value) ? prev.filter(item => item !== value) : [...prev, value]
    );
    setCurrentPage(1); // Reset page on filter change
  };

  const filteredProducts = useMemo(() => {
    let result = products.filter(product => {
      const matchType = selectedTypes.length === 0 || selectedTypes.includes(product.type);
      const matchLang = selectedLangs.length === 0 || (product.language && selectedLangs.includes(product.language));
      const matchSearch = searchQuery === '' || product.name.toLowerCase().includes(searchQuery.toLowerCase());
      return matchType && matchLang && matchSearch;
    });

    // Sorting
    if (sortBy === 'price-asc') {
      result.sort((a, b) => a.price - b.price);
    } else if (sortBy === 'price-desc') {
      result.sort((a, b) => b.price - a.price);
    } else if (sortBy === 'newest') {
      // Assuming products are already sorted by newest from useProducts, or we can sort by createdAt if available
      result.sort((a, b) => {
        const dateA = a.createdAt?.toMillis?.() || 0;
        const dateB = b.createdAt?.toMillis?.() || 0;
        return dateB - dateA;
      });
    }

    return result;
  }, [selectedTypes, selectedLangs, products, searchQuery, sortBy]);

  // Pagination Logic
  const totalPages = Math.ceil(filteredProducts.length / itemsPerPage);
  const paginatedProducts = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredProducts.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredProducts, currentPage]);

  // Reset page when search or sort changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, sortBy]);

  const FilterContent = () => (
    <div className="space-y-8">
      {/* Thể loại */}
      <div>
        <h3 className="text-gray-900 dark:text-white font-bold uppercase tracking-wider text-sm mb-4 border-b border-gray-200 dark:border-zinc-800 pb-2">Thể Loại</h3>
        <div className="space-y-3">
          {[
            { id: 'base', label: 'Bản Cơ Bản / Độc Lập' },
            { id: 'expansion', label: 'Bản Mở Rộng' },
            { id: 'accessory', label: 'Phụ Kiện & Sleeves' },
            { id: 'combo', label: 'Combo Tiết Kiệm' },
            ...(productConfig.types || []).map(t => ({ id: t, label: t }))
          ].map(type => (
            <label key={type.id} className="flex items-center gap-3 cursor-pointer group" onClick={(e) => { e.preventDefault(); toggleFilter(setSelectedTypes, type.id); }}>
              <div className={`w-5 h-5 rounded border flex items-center justify-center transition-colors ${selectedTypes.includes(type.id) ? 'bg-red-600 border-red-600' : 'border-gray-300 dark:border-zinc-600 group-hover:border-red-500'}`}>
                {selectedTypes.includes(type.id) && <div className="w-2.5 h-2.5 bg-white rounded-sm" />}
              </div>
              <span className={`text-sm ${selectedTypes.includes(type.id) ? 'text-gray-900 dark:text-white font-medium' : 'text-gray-500 dark:text-zinc-400 group-hover:text-gray-900 dark:group-hover:text-zinc-200'}`}>
                {type.label}
              </span>
            </label>
          ))}
        </div>
      </div>

      {/* Ngôn ngữ */}
      <div>
        <h3 className="text-gray-900 dark:text-white font-bold uppercase tracking-wider text-sm mb-4 border-b border-gray-200 dark:border-zinc-800 pb-2">Ngôn Ngữ</h3>
        <div className="space-y-3">
          {[
            { id: 'vi', label: 'Tiếng Việt (Bản Quyền)' },
            { id: 'zh', label: 'Tiếng Trung' }
          ].map(lang => (
            <label key={lang.id} className="flex items-center gap-3 cursor-pointer group" onClick={(e) => { e.preventDefault(); toggleFilter(setSelectedLangs, lang.id); }}>
              <div className={`w-5 h-5 rounded border flex items-center justify-center transition-colors ${selectedLangs.includes(lang.id) ? 'bg-red-600 border-red-600' : 'border-gray-300 dark:border-zinc-600 group-hover:border-red-500'}`}>
                {selectedLangs.includes(lang.id) && <div className="w-2.5 h-2.5 bg-white rounded-sm" />}
              </div>
              <span className={`text-sm ${selectedLangs.includes(lang.id) ? 'text-gray-900 dark:text-white font-medium' : 'text-gray-500 dark:text-zinc-400 group-hover:text-gray-900 dark:group-hover:text-zinc-200'}`}>
                {lang.label}
              </span>
            </label>
          ))}
        </div>
      </div>
    </div>
  );

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Header & Mobile Filter Toggle */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-black uppercase tracking-tight text-gray-900 dark:text-white mb-2">
            {searchQuery ? `Tìm kiếm: "${searchQuery}"` : 'Cửa Hàng'}
          </h1>
          <p className="text-gray-500 dark:text-zinc-400 text-sm">Hiển thị {filteredProducts.length} sản phẩm</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="appearance-none bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 px-4 py-2 pr-10 rounded-lg text-gray-900 dark:text-white font-medium hover:bg-gray-50 dark:hover:bg-zinc-800 transition-colors outline-none focus:border-red-500"
            >
              <option value="newest">Mới nhất</option>
              <option value="price-asc">Giá: Thấp đến Cao</option>
              <option value="price-desc">Giá: Cao đến Thấp</option>
            </select>
            <ArrowUpDown className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-500 pointer-events-none" />
          </div>
          <button 
            onClick={() => setIsMobileFilterOpen(true)}
            className="lg:hidden flex items-center gap-2 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 px-4 py-2 rounded-lg text-gray-900 dark:text-white font-medium hover:bg-gray-50 dark:hover:bg-zinc-800 transition-colors"
          >
            <Filter className="h-4 w-4" />
            Bộ Lọc
          </button>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-8">
        {/* Desktop Sidebar */}
        <aside className="hidden lg:block w-64 shrink-0">
          <div className="sticky top-24 bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm">
            <FilterContent />
          </div>
        </aside>

        {/* Mobile Filter Drawer */}
        {isMobileFilterOpen && (
          <div className="fixed inset-0 z-[60] lg:hidden flex">
            <div className="fixed inset-0 bg-black/80 backdrop-blur-sm" onClick={() => setIsMobileFilterOpen(false)} />
            <div className="relative w-4/5 max-w-sm bg-white dark:bg-zinc-950 h-full p-6 overflow-y-auto border-r border-gray-200 dark:border-zinc-800 shadow-2xl">
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white uppercase">Bộ Lọc</h2>
                <button onClick={() => setIsMobileFilterOpen(false)} className="p-2 hover:bg-gray-100 dark:hover:bg-zinc-900 rounded-full text-gray-500 dark:text-zinc-400 hover:text-gray-900 dark:hover:text-white transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <FilterContent />
              <div className="mt-8 pt-6 border-t border-gray-200 dark:border-zinc-800">
                <button 
                  onClick={() => setIsMobileFilterOpen(false)}
                  className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl transition-colors"
                >
                  Xem {filteredProducts.length} kết quả
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Product Grid */}
        <div className="flex-1">
          {loading ? (
            <div className="flex justify-center items-center py-20 text-gray-500 dark:text-zinc-400">
              Đang tải sản phẩm...
            </div>
          ) : filteredProducts.length > 0 ? (
            <>
              <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6">
                {paginatedProducts.map(product => (
                  <ProductCard key={product.id} product={product} onClick={(id) => navigate(`/product/${id}`)} onAddToCart={onAddToCart} />
                ))}
              </div>
              
              {/* Pagination Controls */}
              {totalPages > 1 && (
                <div className="flex justify-center items-center gap-2 mt-12">
                  <button
                    onClick={() => {
                      setCurrentPage(prev => Math.max(1, prev - 1));
                      window.scrollTo({ top: 0, behavior: 'smooth' });
                    }}
                    disabled={currentPage === 1}
                    className="px-4 py-2 rounded-lg border border-gray-200 dark:border-zinc-800 text-gray-700 dark:text-zinc-300 hover:bg-gray-50 dark:hover:bg-zinc-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    Trước
                  </button>
                  
                  <div className="flex items-center gap-1">
                    {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                      <button
                        key={page}
                        onClick={() => {
                          setCurrentPage(page);
                          window.scrollTo({ top: 0, behavior: 'smooth' });
                        }}
                        className={`w-10 h-10 rounded-lg flex items-center justify-center transition-colors ${
                          currentPage === page
                            ? 'bg-red-600 text-white font-bold'
                            : 'text-gray-700 dark:text-zinc-300 hover:bg-gray-50 dark:hover:bg-zinc-800'
                        }`}
                      >
                        {page}
                      </button>
                    ))}
                  </div>

                  <button
                    onClick={() => {
                      setCurrentPage(prev => Math.min(totalPages, prev + 1));
                      window.scrollTo({ top: 0, behavior: 'smooth' });
                    }}
                    disabled={currentPage === totalPages}
                    className="px-4 py-2 rounded-lg border border-gray-200 dark:border-zinc-800 text-gray-700 dark:text-zinc-300 hover:bg-gray-50 dark:hover:bg-zinc-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    Sau
                  </button>
                </div>
              )}
            </>
          ) : (
            <div className="flex flex-col items-center justify-center py-20 bg-gray-50 dark:bg-zinc-900/30 border border-gray-200 dark:border-zinc-800 border-dashed rounded-2xl">
              <Filter className="h-12 w-12 text-gray-400 dark:text-zinc-600 mb-4" />
              <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Không tìm thấy sản phẩm</h3>
              <p className="text-gray-500 dark:text-zinc-400 text-center max-w-md">
                Thử thay đổi bộ lọc hoặc xóa các tùy chọn để xem thêm sản phẩm.
              </p>
              <button 
                onClick={() => { setSelectedTypes([]); setSelectedLangs([]); }}
                className="mt-6 text-red-600 dark:text-red-500 hover:text-red-700 dark:hover:text-red-400 font-bold uppercase tracking-wider text-sm transition-colors"
              >
                Xóa bộ lọc
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
