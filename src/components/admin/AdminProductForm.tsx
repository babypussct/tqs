import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { doc, getDoc, setDoc, addDoc, collection, serverTimestamp, updateDoc } from 'firebase/firestore';
import { db } from '../../firebase';
import { Product } from '../../types';
import { handleFirestoreError, OperationType } from '../../utils/firebaseError';
import { ArrowLeft, Save, Tag, Box, Image as ImageIcon, Plus, Trash2, X } from 'lucide-react';
import { toast } from 'sonner';
import { useProducts } from '../../hooks/useProducts';
import { useProductConfig } from '../../hooks/useProductConfig';
import { ImageUploader } from '../ui/ImageUploader';

export default function AdminProductForm() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { products } = useProducts(false); // For add-ons selection
  const { config: productConfig } = useProductConfig();
  
  const [editingProduct, setEditingProduct] = useState<Partial<Product>>({
    type: 'base',
    isActive: true,
    stock: 100,
    images: [],
    specifications: [],
    customVariants: [],
    addonIds: []
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchProduct = async () => {
      if (!id) return;
      setLoading(true);
      try {
        const docRef = doc(db, 'products', id);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          setEditingProduct({ id: docSnap.id, ...docSnap.data() } as Product);
        } else {
          toast.error('Không tìm thấy sản phẩm');
          navigate('/admin');
        }
      } catch (error) {
        handleFirestoreError(error, OperationType.GET, `products/${id}`);
        toast.error('Lỗi khi tải thông tin sản phẩm');
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [id, navigate]);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const productData: any = {
        name: editingProduct.name || '',
        price: Number(editingProduct.price) || 0,
        image: editingProduct.image || '',
        type: editingProduct.type || 'base',
        isActive: editingProduct.isActive ?? true,
      };

      if (editingProduct.originalPrice) productData.originalPrice = Number(editingProduct.originalPrice);
      if (editingProduct.stock !== undefined) productData.stock = Number(editingProduct.stock);
      if (editingProduct.badge) productData.badge = editingProduct.badge;
      if (editingProduct.description) productData.description = editingProduct.description;
      if (editingProduct.size) productData.size = editingProduct.size;
      
      if (editingProduct.images) productData.images = editingProduct.images;
      if (editingProduct.specifications) productData.specifications = editingProduct.specifications;
      if (editingProduct.addonIds) productData.addonIds = editingProduct.addonIds;
      if (editingProduct.soldCount !== undefined) productData.soldCount = Number(editingProduct.soldCount);
      if (editingProduct.customVariants) {
        productData.customVariants = editingProduct.customVariants.map(v => ({
          ...v,
          options: v.options.map(opt => typeof opt === 'string' ? { name: opt, priceAdjustment: 0 } : opt)
        }));
      }
      if ((editingProduct as any).quickAddAccessory) (productData as any).quickAddAccessory = (editingProduct as any).quickAddAccessory;
      if (editingProduct.quickAddAccessories) productData.quickAddAccessories = editingProduct.quickAddAccessories;

      if (id) {
        await updateDoc(doc(db, 'products', id), productData);
        toast.success('Cập nhật sản phẩm thành công');
      } else {
        await addDoc(collection(db, 'products'), {
          ...productData,
          createdAt: serverTimestamp()
        });
        toast.success('Thêm sản phẩm thành công');
      }
      navigate('/admin');
    } catch (error) {
      handleFirestoreError(error, id ? OperationType.UPDATE : OperationType.CREATE, 'products');
      toast.error('Có lỗi xảy ra khi lưu sản phẩm');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-gray-500 dark:text-zinc-400 flex items-center gap-3">
          <div className="w-5 h-5 border-2 border-red-600 border-t-transparent rounded-full animate-spin"></div>
          Đang tải dữ liệu...
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col md:flex-row min-h-[calc(100vh-73px)] bg-gray-50 dark:bg-zinc-950">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-800 shrink-0 hidden md:block">
        <div className="sticky top-[73px] p-6">
          <button 
            onClick={() => navigate('/admin')}
            className="mb-6 flex items-center gap-2 text-sm font-medium text-gray-500 hover:text-gray-900 dark:text-zinc-400 dark:hover:text-white transition-colors"
          >
            <ArrowLeft className="w-4 h-4" /> Quay lại
          </button>
          <h2 className="text-xl font-black text-gray-900 dark:text-white tracking-tight mb-6">
            {id ? 'Chỉnh sửa' : 'Thêm mới'}
          </h2>
          <nav className="space-y-1.5">
            <a href="#basic-info" className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 hover:text-gray-900 dark:hover:text-white">
              <Tag className="w-5 h-5" /> Thông tin cơ bản
            </a>
            <a href="#pricing" className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 hover:text-gray-900 dark:hover:text-white">
              <Box className="w-5 h-5" /> Giá & Kho hàng
            </a>
            <a href="#media" className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 hover:text-gray-900 dark:hover:text-white">
              <ImageIcon className="w-5 h-5" /> Hình ảnh & Thuộc tính
            </a>
            <a href="#variants" className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all text-gray-600 dark:text-zinc-400 hover:bg-gray-100 dark:hover:bg-zinc-800 hover:text-gray-900 dark:hover:text-white">
              <Plus className="w-5 h-5" /> Biến thể (Tùy chọn)
            </a>
          </nav>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6 md:p-10 overflow-x-hidden">
        <div className="max-w-4xl mx-auto">
          <div className="md:hidden mb-6 flex items-center gap-4">
            <button 
              onClick={() => navigate('/admin')}
              className="p-2 text-gray-500 hover:text-gray-900 dark:text-zinc-400 dark:hover:text-white bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-xl transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <h1 className="text-2xl font-black text-gray-900 dark:text-white tracking-tight">
              {id ? 'Chỉnh sửa Sản phẩm' : 'Thêm Sản phẩm mới'}
            </h1>
          </div>

          <form id="product-form" onSubmit={handleSave} className="space-y-8 pb-24">
            
            {/* Section: Basic Info */}
            <div id="basic-info" className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm scroll-mt-24">
              <h3 className="text-sm font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider mb-6 flex items-center gap-2">
                <Tag className="w-4 h-4" /> Thông tin cơ bản
              </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div className="sm:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Tên sản phẩm *</label>
              <input required type="text" value={editingProduct.name || ''} onChange={e => setEditingProduct({...editingProduct, name: e.target.value})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" placeholder="VD: Tam Quốc Sát Tiêu Chuẩn 2024" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Phân loại *</label>
              <select required value={editingProduct.type || 'base'} onChange={e => setEditingProduct({...editingProduct, type: e.target.value})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all appearance-none">
                <option value="base">Bản Cơ Bản</option>
                <option value="expansion">Bản Mở Rộng</option>
                <option value="accessory">Phụ Kiện</option>
                <option value="combo">Combo</option>
                {productConfig.types?.map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Nhãn (Badge)</label>
              <select value={editingProduct.badge || ''} onChange={e => setEditingProduct({...editingProduct, badge: e.target.value})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all appearance-none">
                <option value="">Không có nhãn</option>
                {productConfig.badges?.map(badge => (
                  <option key={badge} value={badge}>{badge}</option>
                ))}
              </select>
            </div>
            <div className="sm:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Mô tả chi tiết</label>
              <textarea rows={6} value={editingProduct.description || ''} onChange={e => setEditingProduct({...editingProduct, description: e.target.value})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all resize-y" placeholder="Mô tả chi tiết về sản phẩm, luật chơi cơ bản..." />
            </div>
          </div>
        </div>

        {/* Section: Pricing & Inventory */}
        <div id="pricing" className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm scroll-mt-24">
          <h3 className="text-sm font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider mb-6 flex items-center gap-2">
            <Box className="w-4 h-4" /> Giá & Kho hàng
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Giá bán (VNĐ) *</label>
              <input required type="number" min="0" value={editingProduct.price || ''} onChange={e => setEditingProduct({...editingProduct, price: Number(e.target.value)})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" placeholder="250000" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Giá gốc (VNĐ)</label>
              <input type="number" min="0" value={editingProduct.originalPrice || ''} onChange={e => setEditingProduct({...editingProduct, originalPrice: Number(e.target.value)})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" placeholder="300000" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Tồn kho</label>
              <input type="number" min="0" value={editingProduct.stock ?? ''} onChange={e => setEditingProduct({...editingProduct, stock: e.target.value === '' ? undefined : Number(e.target.value)})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" placeholder="100" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Đã bán</label>
              <input type="number" min="0" value={editingProduct.soldCount ?? ''} onChange={e => setEditingProduct({...editingProduct, soldCount: e.target.value === '' ? undefined : Number(e.target.value)})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" placeholder="0" />
            </div>
          </div>
        </div>

        {/* Section: Media & Specs */}
        <div id="media" className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm scroll-mt-24">
          <h3 className="text-sm font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider mb-6 flex items-center gap-2">
            <ImageIcon className="w-4 h-4" /> Hình ảnh & Thuộc tính
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div className="sm:col-span-2">
              <ImageUploader 
                label="URL Hình ảnh chính"
                required={true}
                value={editingProduct.image || ''} 
                onChange={(url) => setEditingProduct({...editingProduct, image: url})} 
                onClear={() => setEditingProduct({...editingProduct, image: ''})}
              />
            </div>
            
            {/* Additional Images */}
            <div className="sm:col-span-2">
              <div className="flex items-center justify-between mb-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300">Thư viện ảnh (Tùy chọn)</label>
                <button 
                  type="button"
                  onClick={() => {
                    const currentImages = editingProduct.images || [];
                    setEditingProduct({...editingProduct, images: [...currentImages, '']});
                  }}
                  className="text-sm font-medium text-blue-600 dark:text-blue-500 hover:underline flex items-center gap-1"
                >
                  <Plus className="w-4 h-4" /> Thêm ảnh
                </button>
              </div>
              <div className="space-y-3">
                {(editingProduct.images || []).map((img, idx) => (
                  <div key={idx} className="flex gap-4">
                    <ImageUploader 
                      value={img} 
                      onChange={(url) => {
                        const newImages = [...(editingProduct.images || [])];
                        newImages[idx] = url;
                        setEditingProduct({...editingProduct, images: newImages});
                      }} 
                      onClear={() => {
                        const newImages = [...(editingProduct.images || [])];
                        newImages.splice(idx, 1);
                        setEditingProduct({...editingProduct, images: newImages});
                      }}
                    />
                  </div>
                ))}
                {(!editingProduct.images || editingProduct.images.length === 0) && (
                  <div className="text-sm text-gray-500 dark:text-zinc-500 italic">Chưa có ảnh phụ nào.</div>
                )}
              </div>
            </div>

            <div className="sm:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Kích thước (Size sleeves)</label>
              <input type="text" placeholder="VD: 62x89mm" value={editingProduct.size || ''} onChange={e => setEditingProduct({...editingProduct, size: e.target.value})} className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" />
            </div>

            {/* Dynamic Specifications */}
            <div className="sm:col-span-2">
              <div className="flex items-center justify-between mb-2">
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300">Thông số kỹ thuật</label>
                <button 
                  type="button"
                  onClick={() => {
                    const currentSpecs = editingProduct.specifications || [];
                    setEditingProduct({...editingProduct, specifications: [...currentSpecs, { name: '', value: '' }]});
                  }}
                  className="text-sm font-medium text-blue-600 dark:text-blue-500 hover:underline flex items-center gap-1"
                >
                  <Plus className="w-4 h-4" /> Thêm thông số
                </button>
              </div>
              <div className="space-y-3">
                {(editingProduct.specifications || []).map((spec, idx) => (
                  <div key={idx} className="flex gap-3">
                    <input 
                      type="text" 
                      value={spec.name} 
                      onChange={e => {
                        const newSpecs = [...(editingProduct.specifications || [])];
                        newSpecs[idx].name = e.target.value;
                        setEditingProduct({...editingProduct, specifications: newSpecs});
                      }} 
                      className="w-1/3 bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                      placeholder="Tên (VD: Thương hiệu)" 
                    />
                    <input 
                      type="text" 
                      value={spec.value} 
                      onChange={e => {
                        const newSpecs = [...(editingProduct.specifications || [])];
                        newSpecs[idx].value = e.target.value;
                        setEditingProduct({...editingProduct, specifications: newSpecs});
                      }} 
                      className="flex-1 bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                      placeholder="Giá trị (VD: Yoka Games)" 
                    />
                    <button 
                      type="button"
                      onClick={() => {
                        const newSpecs = [...(editingProduct.specifications || [])];
                        newSpecs.splice(idx, 1);
                        setEditingProduct({...editingProduct, specifications: newSpecs});
                      }}
                      className="p-3 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors shrink-0"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
            
        {/* Custom Variants */}
        <div id="variants" className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm scroll-mt-24">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-sm font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider flex items-center gap-2">
              <Plus className="w-4 h-4" /> Biến thể sản phẩm (Tùy chọn)
            </h3>
            <button 
              type="button"
              onClick={() => {
                const currentVariants = editingProduct.customVariants || [];
                setEditingProduct({...editingProduct, customVariants: [...currentVariants, { name: '', options: [] }]});
              }}
              className="text-sm font-medium text-blue-600 dark:text-blue-500 hover:underline flex items-center gap-1"
            >
              <Plus className="w-4 h-4" /> Thêm biến thể
            </button>
          </div>
          <div className="space-y-4">
            {(editingProduct.customVariants || []).map((variant, idx) => (
              <div key={idx} className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-300 dark:border-zinc-700 rounded-xl p-4">
                    <div className="flex gap-3 mb-4">
                      <input 
                        type="text" 
                        value={variant.name} 
                        onChange={e => {
                          const newVariants = [...(editingProduct.customVariants || [])];
                          newVariants[idx].name = e.target.value;
                          setEditingProduct({...editingProduct, customVariants: newVariants});
                        }} 
                        className="flex-1 bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                        placeholder="Tên biến thể (VD: Màu sắc)" 
                      />
                      <button 
                        type="button"
                        onClick={() => {
                          const newVariants = [...(editingProduct.customVariants || [])];
                          newVariants.splice(idx, 1);
                          setEditingProduct({...editingProduct, customVariants: newVariants});
                        }}
                        className="p-3 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors shrink-0"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                    
                    <div className="space-y-2 pl-4 border-l-2 border-gray-200 dark:border-zinc-700">
                      <div className="flex items-center justify-between mb-2">
                        <label className="text-xs font-medium text-gray-500 dark:text-zinc-400">Các tùy chọn</label>
                        <button 
                          type="button"
                          onClick={() => {
                            const newVariants = [...(editingProduct.customVariants || [])];
                            // Handle migration from string[] to object[]
                            const currentOptions = newVariants[idx].options || [];
                            const mappedOptions = currentOptions.map(opt => typeof opt === 'string' ? { name: opt, priceAdjustment: 0 } : opt);
                            newVariants[idx].options = [...mappedOptions, { name: '', priceAdjustment: 0 }];
                            setEditingProduct({...editingProduct, customVariants: newVariants});
                          }}
                          className="text-xs font-medium text-blue-600 dark:text-blue-500 hover:underline flex items-center gap-1"
                        >
                          <Plus className="w-3 h-3" /> Thêm tùy chọn
                        </button>
                      </div>
                      {(variant.options || []).map((opt, optIdx) => {
                        const optionObj = typeof opt === 'string' ? { name: opt, priceAdjustment: 0 } : opt;
                        return (
                          <div key={optIdx} className="flex gap-2">
                            <input 
                              type="text" 
                              value={optionObj.name} 
                              onChange={e => {
                                const newVariants = [...(editingProduct.customVariants || [])];
                                const currentOptions = newVariants[idx].options.map(o => typeof o === 'string' ? { name: o, priceAdjustment: 0 } : o);
                                currentOptions[optIdx].name = e.target.value;
                                newVariants[idx].options = currentOptions;
                                setEditingProduct({...editingProduct, customVariants: newVariants});
                              }} 
                              className="flex-1 bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="Tên (VD: Đỏ)" 
                            />
                            <input 
                              type="number" 
                              value={optionObj.priceAdjustment || ''} 
                              onChange={e => {
                                const newVariants = [...(editingProduct.customVariants || [])];
                                const currentOptions = newVariants[idx].options.map(o => typeof o === 'string' ? { name: o, priceAdjustment: 0 } : o);
                                currentOptions[optIdx].priceAdjustment = Number(e.target.value);
                                newVariants[idx].options = currentOptions;
                                setEditingProduct({...editingProduct, customVariants: newVariants});
                              }} 
                              className="w-32 bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-lg px-3 py-2 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="Giá cộng thêm" 
                            />
                            <button 
                              type="button"
                              onClick={() => {
                                const newVariants = [...(editingProduct.customVariants || [])];
                                newVariants[idx].options.splice(optIdx, 1);
                                setEditingProduct({...editingProduct, customVariants: newVariants});
                              }}
                              className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors shrink-0"
                            >
                              <X className="w-4 h-4" />
                            </button>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Section: Related & Accessories */}
            <div id="related" className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 shadow-sm scroll-mt-24">
              <h3 className="text-sm font-bold text-gray-500 dark:text-zinc-400 uppercase tracking-wider mb-6 flex items-center gap-2">
                <Box className="w-4 h-4" /> Sản phẩm liên quan & Phụ kiện
              </h3>
              <div className="grid grid-cols-1 gap-8">
                {/* Add-ons / Combos */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">Sản phẩm mua kèm (Add-ons)</label>
                  <div className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-300 dark:border-zinc-700 rounded-xl p-4 max-h-60 overflow-y-auto custom-scrollbar">
                    {products.filter(p => p.id !== editingProduct.id).map(p => (
                      <label key={p.id} className="flex items-center gap-4 p-3 hover:bg-gray-100 dark:hover:bg-zinc-800 rounded-xl cursor-pointer transition-colors">
                        <input 
                          type="checkbox" 
                          checked={(editingProduct.addonIds || []).includes(p.id)}
                          onChange={(e) => {
                            const currentAddons = editingProduct.addonIds || [];
                            if (e.target.checked) {
                              setEditingProduct({...editingProduct, addonIds: [...currentAddons, p.id]});
                            } else {
                              setEditingProduct({...editingProduct, addonIds: currentAddons.filter(id => id !== p.id)});
                            }
                          }}
                          className="w-5 h-5 text-red-600 rounded border-gray-300 focus:ring-red-500"
                        />
                        {p.image ? (
                          <img src={p.image} alt={p.name} className="w-10 h-10 rounded-lg object-cover" />
                        ) : (
                          <div className="w-10 h-10 rounded-lg bg-gray-200 dark:bg-zinc-800 flex items-center justify-center">
                            <ImageIcon className="w-5 h-5 text-gray-400" />
                          </div>
                        )}
                        <span className="text-sm text-gray-900 dark:text-white flex-1 truncate font-medium">{p.name}</span>
                        <span className="text-sm font-bold text-red-600 dark:text-red-500">{p.price.toLocaleString('vi-VN')}đ</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Quick Add Accessories */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300">Phụ kiện mua nhanh (Quick Add)</label>
                    <button 
                      type="button"
                      onClick={() => {
                        const currentAccessories = editingProduct.quickAddAccessories || [];
                        // Handle migration from single quickAddAccessory
                        if ((editingProduct as any).quickAddAccessory && currentAccessories.length === 0) {
                          currentAccessories.push((editingProduct as any).quickAddAccessory);
                        }
                        setEditingProduct({...editingProduct, quickAddAccessories: [...currentAccessories, { name: '', price: 0, description: '' }]});
                      }}
                      className="text-sm font-medium text-blue-600 dark:text-blue-500 hover:underline flex items-center gap-1"
                    >
                      <Plus className="w-4 h-4" /> Thêm phụ kiện
                    </button>
                  </div>
                  
                  <div className="space-y-4">
                    {/* Migrate old single accessory if it exists and array is empty */}
                    {(editingProduct as any).quickAddAccessory && (!editingProduct.quickAddAccessories || editingProduct.quickAddAccessories.length === 0) && (
                      <div className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-300 dark:border-zinc-700 rounded-xl p-5 space-y-4 relative">
                        <button 
                          type="button"
                          onClick={() => setEditingProduct({...editingProduct, quickAddAccessory: undefined} as any)}
                          className="absolute top-4 right-4 p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pr-10">
                          <div>
                            <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Tên phụ kiện</label>
                            <input 
                              type="text" 
                              value={(editingProduct as any).quickAddAccessory.name} 
                              onChange={e => setEditingProduct({...editingProduct, quickAddAccessory: { ...(editingProduct as any).quickAddAccessory!, name: e.target.value }} as any)} 
                              className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="VD: Mua kèm 200 Bọc bài (Sleeves)" 
                            />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Giá cộng thêm (VNĐ)</label>
                            <input 
                              type="number" 
                              min="0"
                              value={(editingProduct as any).quickAddAccessory.price || ''} 
                              onChange={e => setEditingProduct({...editingProduct, quickAddAccessory: { ...(editingProduct as any).quickAddAccessory!, price: Number(e.target.value) }} as any)} 
                              className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="VD: 50000" 
                            />
                          </div>
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Mô tả ngắn (Tùy chọn)</label>
                          <input 
                            type="text" 
                            value={(editingProduct as any).quickAddAccessory.description || ''} 
                            onChange={e => setEditingProduct({...editingProduct, quickAddAccessory: { ...(editingProduct as any).quickAddAccessory!, description: e.target.value }} as any)} 
                            className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                            placeholder="VD: Bảo vệ bài không trầy xước, chống nước." 
                          />
                        </div>
                      </div>
                    )}

                    {(editingProduct.quickAddAccessories || []).map((accessory, idx) => (
                      <div key={idx} className="bg-gray-50 dark:bg-zinc-900/50 border border-gray-300 dark:border-zinc-700 rounded-xl p-5 space-y-4 relative">
                        <button 
                          type="button"
                          onClick={() => {
                            const newAccessories = [...(editingProduct.quickAddAccessories || [])];
                            newAccessories.splice(idx, 1);
                            setEditingProduct({...editingProduct, quickAddAccessories: newAccessories});
                          }}
                          className="absolute top-4 right-4 p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pr-10">
                          <div>
                            <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Tên phụ kiện</label>
                            <input 
                              type="text" 
                              value={accessory.name} 
                              onChange={e => {
                                const newAccessories = [...(editingProduct.quickAddAccessories || [])];
                                newAccessories[idx].name = e.target.value;
                                setEditingProduct({...editingProduct, quickAddAccessories: newAccessories});
                              }} 
                              className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="VD: Mua kèm 200 Bọc bài (Sleeves)" 
                            />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Giá cộng thêm (VNĐ)</label>
                            <input 
                              type="number" 
                              min="0"
                              value={accessory.price || ''} 
                              onChange={e => {
                                const newAccessories = [...(editingProduct.quickAddAccessories || [])];
                                newAccessories[idx].price = Number(e.target.value);
                                setEditingProduct({...editingProduct, quickAddAccessories: newAccessories});
                              }} 
                              className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                              placeholder="VD: 50000" 
                            />
                          </div>
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-500 dark:text-zinc-400 mb-2">Mô tả ngắn (Tùy chọn)</label>
                          <input 
                            type="text" 
                            value={accessory.description || ''} 
                            onChange={e => {
                              const newAccessories = [...(editingProduct.quickAddAccessories || [])];
                              newAccessories[idx].description = e.target.value;
                              setEditingProduct({...editingProduct, quickAddAccessories: newAccessories});
                            }} 
                            className="w-full bg-white dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 text-sm text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
                            placeholder="VD: Bảo vệ bài không trầy xước, chống nước." 
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Visibility Toggle */}
        <div className="bg-white dark:bg-zinc-950 border border-gray-200 dark:border-zinc-800 rounded-2xl p-6 flex items-center justify-between shadow-sm">
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold text-lg">Trạng thái hiển thị</h4>
            <p className="text-sm text-gray-500 dark:text-zinc-400 mt-1">Bật để hiển thị sản phẩm này trên cửa hàng</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" className="sr-only peer" checked={editingProduct.isActive ?? true} onChange={e => setEditingProduct({...editingProduct, isActive: e.target.checked})} />
            <div className="w-14 h-7 bg-gray-200 dark:bg-zinc-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-emerald-500"></div>
          </label>
        </div>

        {/* Footer Actions */}
        <div className="flex justify-end gap-4 pt-4">
          <button 
            type="button" 
            onClick={() => navigate('/admin')} 
            className="px-8 py-3 rounded-xl font-medium text-gray-700 dark:text-zinc-300 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 hover:bg-gray-50 dark:hover:bg-zinc-800 transition-colors"
          >
            Hủy bỏ
          </button>
          <button 
            type="submit" 
            disabled={loading}
            className="px-8 py-3 rounded-xl font-bold text-white bg-red-600 hover:bg-red-700 flex items-center gap-2 transition-colors shadow-lg shadow-red-600/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-5 h-5" /> {loading ? 'Đang lưu...' : 'Lưu Sản phẩm'}
          </button>
        </div>

      </form>
        </div>
      </main>
    </div>
  );
}
