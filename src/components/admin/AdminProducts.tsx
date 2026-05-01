import React, { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { doc, deleteDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { Package, Edit, Trash2, Search, Image as ImageIcon } from 'lucide-react';
import { toast } from 'sonner';
import { useProducts } from '../../hooks/useProducts';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { cloudinaryUrl } from '../../utils/cloudinaryUrl';

export default function AdminProducts() {
  const { products, loading } = useProducts(false);
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');

  const filteredProducts = useMemo(() => {
    return products.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()));
  }, [products, searchTerm]);

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa sản phẩm này? Hành động này không thể hoàn tác.')) {
      try {
        await deleteDoc(doc(db, 'products', id));
        toast.success('Đã xóa sản phẩm');
      } catch (error) {
        handleFirestoreError(error, OperationType.DELETE, `products/${id}`);
        toast.error('Có lỗi xảy ra khi xóa sản phẩm');
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[40vh]">
        <div className="text-slate-500 flex items-center gap-3 font-medium">
          <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
          Đang tải dữ liệu sản phẩm...
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Filter Bar */}
      <div className="flex items-center gap-4 bg-white dark:bg-zinc-900 p-3 flex-wrap rounded-xl border border-slate-200 dark:border-zinc-800 shadow-sm">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input 
            type="text" 
            placeholder="Tìm kiếm theo Tên..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-slate-50 dark:bg-zinc-950 border border-slate-200 dark:border-zinc-800 rounded-lg pl-9 pr-4 py-1.5 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all"
          />
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 dark:divide-zinc-800 text-sm text-left">
            <thead className="bg-slate-50 dark:bg-zinc-900/50">
              <tr>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Sản phẩm</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Phân loại</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs">Đơn giá</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Tồn kho</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-center">Tình trạng</th>
                <th className="px-6 py-3 font-semibold text-slate-600 dark:text-zinc-400 uppercase tracking-wider text-xs text-right">Tác vụ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-zinc-800">
              {filteredProducts.map(p => (
                <tr key={p.id} className="hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-colors group">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-md bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 overflow-hidden shrink-0 flex items-center justify-center">
                        {p.image ? (
                          <img src={cloudinaryUrl(p.image, { width: 80, quality: 'auto:low' })} alt={p.name} loading="lazy" decoding="async" className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                        ) : (
                          <ImageIcon className="w-4 h-4 text-slate-400" />
                        )}
                      </div>
                      <div className="font-medium text-slate-900 dark:text-slate-100 max-w-[200px] truncate" title={p.name}>
                        {p.name}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-500 dark:text-zinc-400 capitalize">
                    {p.type} {p.badge && <span className="ml-1 inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-zinc-300">{p.badge}</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-slate-900 dark:text-slate-100 font-medium">{p.price.toLocaleString('vi-VN')} đ</div>
                    {p.originalPrice && <div className="text-xs text-slate-400 line-through">{p.originalPrice.toLocaleString('vi-VN')} đ</div>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full font-medium ${
                      p.stock === 0 ? 'bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-400' : 'bg-slate-100 text-slate-700 dark:bg-zinc-800 dark:text-zinc-300'
                    }`}>
                      {p.stock !== undefined ? p.stock : '∞'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium border ${
                      p.isActive 
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20' 
                        : 'bg-slate-100 text-slate-600 border-slate-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700'
                    }`}>
                      {p.isActive ? 'Đang bán' : 'Tạm ẩn'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                    <div className="flex items-center justify-end gap-2">
                      <button onClick={() => navigate('/admin/product/' + p.id)} className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 dark:hover:text-indigo-400 rounded-md transition-colors tooltip-trigger" title="Sửa">
                        <Edit className="w-4 h-4" />
                      </button>
                      <button onClick={() => handleDelete(p.id)} className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 dark:hover:text-red-400 rounded-md transition-colors tooltip-trigger" title="Xóa">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredProducts.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500 dark:text-zinc-400">
                    <Package className="w-10 h-10 mx-auto mb-3 text-slate-300 dark:text-zinc-600" />
                    <p>Không tìm thấy sản phẩm nào.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
