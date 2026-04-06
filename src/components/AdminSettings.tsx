import React, { useState, useEffect, useRef } from 'react';
import { Plus, Trash2, Save, QrCode, Truck, Check, X, Search } from 'lucide-react';
import { toast } from 'sonner';
import { useProductConfig } from '../hooks/useProductConfig';
import { usePaymentConfig, PaymentConfig } from '../hooks/usePaymentConfig';
import { useShippingConfig } from '../hooks/useShippingConfig';
import { useProducts } from '../hooks/useProducts';
import { useSiteConfig, SiteConfig } from '../hooks/useSiteConfig';
import { useFooterConfig, FooterConfig } from '../hooks/useFooterConfig';
import { ImageUploader } from './ui/ImageUploader';

export default function AdminSettings() {
  const { config, loading: configLoading, updateConfig } = useProductConfig();
  const { paymentConfig, loading: paymentLoading, updatePaymentConfig } = usePaymentConfig();
  const { config: siteConfig, loading: siteLoading, updateConfig: updateSiteConfig } = useSiteConfig();
  const { config: footerConfig, loading: footerLoading, updateConfig: updateFooterConfig } = useFooterConfig();
  
  const [badges, setBadges] = useState<string[]>([]);
  const [types, setTypes] = useState<string[]>([]);
  const [newBadge, setNewBadge] = useState('');
  const [newType, setNewType] = useState('');
  
  const { shippingConfig, loading: shippingLoading, updateShippingConfig } = useShippingConfig();

  const [localPaymentConfig, setLocalPaymentConfig] = useState<PaymentConfig | null>(null);
  const [localShippingConfig, setLocalShippingConfig] = useState<any>(null);
  const [localSiteConfig, setLocalSiteConfig] = useState<SiteConfig | null>(null);
  const [localFooterConfig, setLocalFooterConfig] = useState<FooterConfig | null>(null);

  const [isSaving, setIsSaving] = useState(false);

  const { products } = useProducts(false);
  const [freeshipSearchTerm, setFreeshipSearchTerm] = useState('');
  const [showFreeshipDropdown, setShowFreeshipDropdown] = useState(false);
  const freeshipSearchRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (freeshipSearchRef.current && !freeshipSearchRef.current.contains(event.target as Node)) {
        setShowFreeshipDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (!configLoading) {
      setBadges(config.badges || []);
      setTypes(config.types || []);
    }
  }, [config, configLoading]);

  useEffect(() => {
    if (!paymentLoading && paymentConfig) {
      setLocalPaymentConfig(paymentConfig);
    }
  }, [paymentConfig, paymentLoading]);

  useEffect(() => {
    if (!shippingLoading && shippingConfig) {
      setLocalShippingConfig(shippingConfig);
    }
  }, [shippingConfig, shippingLoading]);

  useEffect(() => {
    if (!siteLoading && siteConfig) {
      setLocalSiteConfig(siteConfig);
    }
  }, [siteConfig, siteLoading]);

  useEffect(() => {
    if (!footerLoading && footerConfig) {
      setLocalFooterConfig(footerConfig);
    }
  }, [footerConfig, footerLoading]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await updateConfig({ badges, types });
      if (localPaymentConfig) {
        await updatePaymentConfig(localPaymentConfig);
      }
      if (localShippingConfig) {
        await updateShippingConfig(localShippingConfig);
      }
      if (localSiteConfig) {
        await updateSiteConfig(localSiteConfig);
      }
      if (localFooterConfig) {
        await updateFooterConfig(localFooterConfig);
      }
      toast.success('Đã lưu cấu hình thành công');
    } catch (error) {
      toast.error('Lỗi khi lưu cấu hình');
    } finally {
      setIsSaving(false);
    }
  };

  const handleAddBadge = () => {
    if (!newBadge.trim()) return;
    if (badges.includes(newBadge.trim())) {
      toast.error('Nhãn này đã tồn tại');
      return;
    }
    setBadges([...badges, newBadge.trim()]);
    setNewBadge('');
  };

  const handleRemoveBadge = (index: number) => {
    setBadges(badges.filter((_, i) => i !== index));
  };

  const handleAddType = () => {
    if (!newType.trim()) return;
    if (types.includes(newType.trim())) {
      toast.error('Phân loại này đã tồn tại');
      return;
    }
    setTypes([...types, newType.trim()]);
    setNewType('');
  };

  const handleRemoveType = (index: number) => {
    setTypes(types.filter((_, i) => i !== index));
  };

  if (configLoading || paymentLoading || shippingLoading || siteLoading || footerLoading || !localPaymentConfig || !localShippingConfig || !localSiteConfig || !localFooterConfig) return <div className="p-8 text-center text-slate-500">Đang tải cấu hình...</div>;

  return (
    <div className="space-y-8 pb-12">
      <div className="flex justify-between items-center bg-white dark:bg-zinc-900/50 p-6 rounded-xl border border-slate-200 dark:border-zinc-800/50">
        <div>
          <h2 className="text-xl font-black text-slate-900 dark:text-white pb-1">Cấu hình hệ thống</h2>
          <p className="text-sm text-slate-500 dark:text-zinc-400">Quản lý nhãn, phân loại và thông tin thanh toán</p>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-xl font-bold transition-colors shadow-sm disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          {isSaving ? 'Đang lưu...' : 'Lưu thay đổi'}
        </button>
      </div>

      {/* Site Configuration */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Thông tin Hiển thị (Thẻ & Mạng xã hội)</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Tiêu đề Trang web (Web Title)</label>
            <input
              type="text"
              value={localSiteConfig.siteTitle}
              onChange={e => setLocalSiteConfig({...localSiteConfig, siteTitle: e.target.value})}
              placeholder="VD: My Shop App"
              className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500"
            />
            <p className="text-xs text-slate-500 dark:text-zinc-400 mt-2">Hiển thị trên tab trình duyệt và kết quả tìm kiếm.</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Favicon / Icon đại diện</label>
            <ImageUploader
              value={localSiteConfig.siteFavicon}
              onChange={url => setLocalSiteConfig({...localSiteConfig, siteFavicon: url})}
              onClear={() => setLocalSiteConfig({...localSiteConfig, siteFavicon: ''})}
              label="Chọn hình cho Favicon"
            />
            <p className="text-xs text-slate-500 dark:text-zinc-400 mt-2">Nên là hình vuông, kích thước nhỏ gọn. Hiển thị ở góc tab trình duyệt.</p>
          </div>
        </div>
        
        <div className="mt-8 border-t border-slate-100 dark:border-zinc-800 pt-6">
          <h4 className="text-base font-bold text-slate-900 dark:text-white mb-4">Nội dung hiển thị mặc định</h4>
          <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Cam kết đóng gói (Trang chi tiết sản phẩm)</label>
          <textarea
            value={localSiteConfig.packagingCommitment || ''}
            onChange={e => setLocalSiteConfig({...localSiteConfig, packagingCommitment: e.target.value})}
            placeholder="Cập nhật nội dung cam kết đóng gói chuẩn cho sản phẩm..."
            rows={4}
            className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 resize-y"
          />
          <p className="text-xs text-slate-500 dark:text-zinc-400 mt-2">Nội dung này hiển thị phía dưới phần thông tin tại tất cả các trang chi tiết sản phẩm. Có thể sử dụng thẻ HTML cơ bản như &lt;strong&gt;Nội dung in đậm&lt;/strong&gt;.</p>
        </div>
      </div>

      {/* Footer Configuration */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6">Cấu hình Footer (Chân trang)</h3>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div className="space-y-4">
            <h4 className="font-bold text-slate-800 dark:text-slate-200">1. Thương hiệu & Mô tả</h4>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Mô tả ngắn</label>
              <textarea
                value={localFooterConfig.brandDescription}
                onChange={e => setLocalFooterConfig({...localFooterConfig, brandDescription: e.target.value})}
                className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500"
                rows={3}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Facebook URL</label>
              <input type="text" value={localFooterConfig.socialLinks.facebook} onChange={e => setLocalFooterConfig({...localFooterConfig, socialLinks: {...localFooterConfig.socialLinks, facebook: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Youtube URL</label>
              <input type="text" value={localFooterConfig.socialLinks.youtube} onChange={e => setLocalFooterConfig({...localFooterConfig, socialLinks: {...localFooterConfig.socialLinks, youtube: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Liên kết khác (Email/Tiktok...)</label>
              <input type="text" value={localFooterConfig.socialLinks.email} onChange={e => setLocalFooterConfig({...localFooterConfig, socialLinks: {...localFooterConfig.socialLinks, email: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
          </div>

          <div className="space-y-4">
            <h4 className="font-bold text-slate-800 dark:text-slate-200">2. Thông tin Liên hệ</h4>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Địa chỉ</label>
              <input type="text" value={localFooterConfig.contactInfo.address} onChange={e => setLocalFooterConfig({...localFooterConfig, contactInfo: {...localFooterConfig.contactInfo, address: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Giờ làm việc</label>
              <input type="text" value={localFooterConfig.contactInfo.workingHours} onChange={e => setLocalFooterConfig({...localFooterConfig, contactInfo: {...localFooterConfig.contactInfo, workingHours: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Hotline</label>
              <input type="text" value={localFooterConfig.contactInfo.phone} onChange={e => setLocalFooterConfig({...localFooterConfig, contactInfo: {...localFooterConfig.contactInfo, phone: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Email hỗ trợ</label>
              <input type="text" value={localFooterConfig.contactInfo.email} onChange={e => setLocalFooterConfig({...localFooterConfig, contactInfo: {...localFooterConfig.contactInfo, email: e.target.value}})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
            </div>
          </div>
        </div>

        <div className="mt-8 pt-6 border-t border-slate-200 dark:border-zinc-800">
          <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Dòng chữ Bản quyền dưới cùng (Copyright)</label>
          <input type="text" value={localFooterConfig.bottomText} onChange={e => setLocalFooterConfig({...localFooterConfig, bottomText: e.target.value})} className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none" />
        </div>
      </div>

      {/* Shipping Configuration */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
        <div className="flex items-center justify-between mb-6 border-b border-slate-100 dark:border-zinc-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 dark:bg-blue-500/10 text-blue-600 dark:text-blue-500 rounded-lg">
              <Truck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Vận chuyển & Freeship</h3>
              <p className="text-xs text-slate-500 dark:text-zinc-400">Cấu hình phí giao hàng mặc định và chính sách miễn phí</p>
            </div>
          </div>
          <label className="flex items-center cursor-pointer">
            <div className="relative">
              <input 
                type="checkbox" 
                className="sr-only" 
                checked={localShippingConfig.isActive}
                onChange={e => setLocalShippingConfig({...localShippingConfig, isActive: e.target.checked})}
              />
              <div className={`block w-14 h-8 rounded-full transition-colors ${localShippingConfig.isActive ? 'bg-blue-500' : 'bg-slate-300 dark:bg-zinc-700'}`}></div>
              <div className={`absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${localShippingConfig.isActive ? 'translate-x-6' : ''}`}></div>
            </div>
            <span className="ml-3 text-sm font-medium text-slate-700 dark:text-zinc-300">
              {localShippingConfig.isActive ? 'Đang bật' : 'Đã tắt'}
            </span>
          </label>
        </div>

        <div className={`grid grid-cols-1 md:grid-cols-2 gap-8 transition-opacity ${localShippingConfig.isActive ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Phí vận chuyển mặc định (VNĐ)</label>
            <input
              type="number"
              value={localShippingConfig.defaultFee}
              onChange={e => setLocalShippingConfig({...localShippingConfig, defaultFee: parseInt(e.target.value) || 0})}
              placeholder="Ví dụ: 30000"
              className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 font-mono"
            />
            <p className="text-xs text-slate-500 dark:text-zinc-400 mt-2">Áp dụng cho các đơn hàng không đạt điều kiện Freeship.</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Hạn mức Freeship (VNĐ)</label>
            <input
              type="number"
              value={localShippingConfig.freeshipThreshold ?? ''}
              onChange={e => setLocalShippingConfig({...localShippingConfig, freeshipThreshold: e.target.value ? parseInt(e.target.value) : null})}
              placeholder="Ví dụ: 500000"
              className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 font-mono"
            />
            <p className="text-xs text-slate-500 dark:text-zinc-400 mt-2">Đơn hàng đạt mức giá này sẽ được miễn phí vận chuyển. Xóa trống nếu không áp dụng.</p>
          </div>
          <div className="md:col-span-2" ref={freeshipSearchRef}>
            <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Sản phẩm đặc quyền Freeship</label>
            
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-slate-400" />
              </div>
              <input
                type="text"
                value={freeshipSearchTerm}
                onChange={e => {
                  setFreeshipSearchTerm(e.target.value);
                  setShowFreeshipDropdown(true);
                }}
                onFocus={() => setShowFreeshipDropdown(true)}
                placeholder="Tìm kiếm và chọn sản phẩm..."
                className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl pl-10 pr-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500"
              />
              
              {showFreeshipDropdown && (
                <div className="absolute z-10 w-full mt-2 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded-xl shadow-lg max-h-60 overflow-y-auto overflow-x-hidden">
                  {products
                    .filter(p => p.name.toLowerCase().includes(freeshipSearchTerm.toLowerCase()) || p.id.includes(freeshipSearchTerm))
                    .map(product => {
                      const isSelected = localShippingConfig.freeshipProductIds?.includes(product.id);
                      return (
                        <div 
                          key={product.id}
                          onClick={() => {
                            let newIds = [...(localShippingConfig.freeshipProductIds || [])];
                            if (isSelected) {
                              newIds = newIds.filter(id => id !== product.id);
                            } else {
                              newIds.push(product.id);
                            }
                            setLocalShippingConfig({
                              ...localShippingConfig,
                              freeshipProductIds: newIds
                            });
                          }}
                          className={`flex items-center gap-3 p-3 cursor-pointer hover:bg-slate-50 dark:hover:bg-zinc-800 transition-colors border-b border-slate-100 dark:border-zinc-800/50 last:border-0 ${isSelected ? 'bg-indigo-50 dark:bg-indigo-500/10' : ''}`}
                        >
                          <div className="w-10 h-10 rounded-lg overflow-hidden shrink-0 bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700">
                            {product.image ? (
                              <img src={product.image} alt={product.name} className="w-full h-full object-cover" />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center text-slate-400 text-xs">Ảnh</div>
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <h4 className="text-sm font-medium text-slate-900 dark:text-white truncate">{product.name}</h4>
                            <p className="text-xs text-slate-500 dark:text-zinc-400 font-mono truncate">{product.id}</p>
                          </div>
                          <div className="shrink-0 w-5 h-5 flex flex-col justify-center">
                            {isSelected && <Check className="w-5 h-5 text-indigo-600" />}
                          </div>
                        </div>
                      );
                  })}
                  {products.filter(p => p.name.toLowerCase().includes(freeshipSearchTerm.toLowerCase()) || p.id.includes(freeshipSearchTerm)).length === 0 && (
                    <div className="p-4 text-center text-sm text-slate-500">Không tìm thấy sản phẩm nào</div>
                  )}
                </div>
              )}
            </div>

            {/* Selected Products Badges */}
            {localShippingConfig.freeshipProductIds?.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-2">
                {localShippingConfig.freeshipProductIds.map((id: string) => {
                  const product = products.find(p => p.id === id);
                  return (
                    <div key={id} className="flex items-center gap-2 bg-indigo-50 dark:bg-indigo-500/10 border border-indigo-200 dark:border-indigo-500/20 rounded-lg px-3 py-1.5 group">
                      {product?.image && <img src={product.image} className="w-5 h-5 rounded object-cover" alt="" />}
                      <span className="text-sm font-medium text-indigo-700 dark:text-indigo-400 max-w-[200px] truncate">
                        {product ? product.name : id}
                      </span>
                      <button
                        onClick={() => {
                          setLocalShippingConfig({
                            ...localShippingConfig,
                            freeshipProductIds: localShippingConfig.freeshipProductIds.filter((pid: string) => pid !== id)
                          });
                        }}
                        className="text-indigo-400 hover:text-indigo-600 ml-1 p-0.5 rounded-full hover:bg-indigo-100 dark:hover:bg-indigo-500/20 transition-colors"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
            
            <p className="text-xs text-slate-500 dark:text-zinc-400 mt-3">Nếu khách hàng mua ít nhất 1 sản phẩm nằm trong danh sách này, toàn bộ đơn hàng sẽ được Freeship.</p>
          </div>
        </div>
      </div>

      {/* Payment Configuration */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
        <div className="flex items-center justify-between mb-6 border-b border-slate-100 dark:border-zinc-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-100 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-500 rounded-lg">
              <QrCode className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Thanh toán QR (VietQR)</h3>
              <p className="text-xs text-slate-500 dark:text-zinc-400">Cấu hình thông tin nhận chuyển khoản</p>
            </div>
          </div>
          <label className="flex items-center cursor-pointer">
            <div className="relative">
              <input 
                type="checkbox" 
                className="sr-only" 
                checked={localPaymentConfig.isActive}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, isActive: e.target.checked})}
              />
              <div className={`block w-14 h-8 rounded-full transition-colors ${localPaymentConfig.isActive ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-zinc-700'}`}></div>
              <div className={`absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${localPaymentConfig.isActive ? 'translate-x-6' : ''}`}></div>
            </div>
            <span className="ml-3 text-sm font-medium text-slate-700 dark:text-zinc-300">
              {localPaymentConfig.isActive ? 'Đang bật' : 'Đã tắt'}
            </span>
          </label>
        </div>

        <div className={`grid grid-cols-1 lg:grid-cols-3 gap-8 transition-opacity ${localPaymentConfig.isActive ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
          <div className="lg:col-span-2 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Ngân hàng</label>
                <select
                  value={localPaymentConfig.bankId}
                  onChange={e => setLocalPaymentConfig({...localPaymentConfig, bankId: e.target.value})}
                  className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500"
                >
                  <option value="MB">MBBank - Ngân hàng Quân Đội</option>
                  <option value="VCB">Vietcombank</option>
                  <option value="TCB">Techcombank</option>
                  <option value="VPB">VPBank</option>
                  <option value="BIDV">BIDV</option>
                  <option value="CTG">VietinBank</option>
                  <option value="ACB">ACB</option>
                  <option value="TPB">TPBank</option>
                  <option value="VIB">VIB</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Mẫu QR (Template)</label>
                <select
                  value={localPaymentConfig.template}
                  onChange={e => setLocalPaymentConfig({...localPaymentConfig, template: e.target.value})}
                  className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500"
                >
                  <option value="compact">Gọn nhẹ (compact)</option>
                  <option value="compact2">Gọn nhẹ 2 (compact2)</option>
                  <option value="qr_only">Chỉ mã QR (qr_only)</option>
                  <option value="print">In ấn (print)</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Số tài khoản</label>
              <input
                type="text"
                value={localPaymentConfig.accountNumber}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, accountNumber: e.target.value})}
                placeholder="VD: 0123456789"
                className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 font-mono"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Tên chủ tài khoản</label>
              <input
                type="text"
                value={localPaymentConfig.accountName}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, accountName: e.target.value.toUpperCase()})}
                placeholder="VD: NGUYEN VAN A"
                className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 font-medium uppercase"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">Ghi chú cho khách hàng</label>
              <textarea
                value={localPaymentConfig.paymentNote}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, paymentNote: e.target.value})}
                placeholder="Ghi chú hiển thị dưới mã QR lúc thanh toán..."
                rows={2}
                className="w-full bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-slate-900 dark:text-white outline-none focus:border-indigo-500 resize-none text-sm"
              />
            </div>
          </div>

          <div className="flex flex-col items-center justify-center bg-slate-50 dark:bg-zinc-950 rounded-xl p-4 border border-slate-200 dark:border-zinc-800">
            <span className="text-xs font-bold text-slate-500 dark:text-zinc-500 mb-2 uppercase tracking-wide">Demo giao diện Checkout</span>
            {localPaymentConfig.bankId && localPaymentConfig.accountNumber ? (
              <img 
                src={`https://img.vietqr.io/image/${localPaymentConfig.bankId}-${localPaymentConfig.accountNumber}-${localPaymentConfig.template}.png?amount=100000&addInfo=DEMOORDER123&accountName=${encodeURIComponent(localPaymentConfig.accountName)}`} 
                alt="VietQR Demo" 
                className="w-full max-w-[200px] object-contain rounded-lg shadow-sm bg-white"
              />
            ) : (
              <div className="w-full max-w-[200px] aspect-square bg-slate-200 dark:bg-zinc-800 rounded-lg flex items-center justify-center text-slate-400 dark:text-zinc-500 text-sm">
                Vui lòng nhập Bank ID & STK
              </div>
            )}
            <p className="text-xs text-center text-slate-500 dark:text-zinc-400 mt-4 leading-relaxed">
              {localPaymentConfig.paymentNote || 'Vui lòng giữ nguyên nội dung chuyển khoản để hệ thống đối soát tự động.'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Badges */}
        <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4">Nhãn sản phẩm (Badges)</h3>
          
          <div className="flex gap-2 mb-6">
            <input
              type="text"
              value={newBadge}
              onChange={(e) => setNewBadge(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddBadge()}
              placeholder="VD: Mới, Bán chạy..."
              className="flex-1 bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            />
            <button
              onClick={handleAddBadge}
              className="bg-slate-900 dark:bg-white text-white dark:text-zinc-900 px-4 py-2 rounded-xl font-medium hover:bg-slate-800 dark:hover:bg-slate-100 transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-2 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
            {badges.map((badge, index) => (
              <div key={index} className="flex items-center justify-between bg-slate-50 dark:bg-zinc-800/50 border border-slate-200 dark:border-zinc-700/50 rounded-lg px-4 py-3">
                <span className="text-slate-900 dark:text-white font-medium">{badge}</span>
                <button
                  onClick={() => handleRemoveBadge(index)}
                  className="text-slate-400 hover:text-indigo-500 transition-colors p-1"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            {badges.length === 0 && (
              <p className="text-slate-500 dark:text-zinc-500 text-center py-4 text-sm">Chưa có nhãn nào</p>
            )}
          </div>
        </div>

        {/* Types */}
        <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 shadow-sm rounded-xl p-6">
          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4">Phân loại sản phẩm (Types)</h3>
          
          <div className="flex gap-2 mb-6">
            <input
              type="text"
              value={newType}
              onChange={(e) => setNewType(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddType()}
              placeholder="VD: Boardgame, Phụ kiện..."
              className="flex-1 bg-slate-50 dark:bg-zinc-800 border border-slate-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-slate-900 dark:text-white outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            />
            <button
              onClick={handleAddType}
              className="bg-slate-900 dark:bg-white text-white dark:text-zinc-900 px-4 py-2 rounded-xl font-medium hover:bg-slate-800 dark:hover:bg-slate-100 transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-2 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
            {types.map((type, index) => (
              <div key={index} className="flex items-center justify-between bg-slate-50 dark:bg-zinc-800/50 border border-slate-200 dark:border-zinc-700/50 rounded-lg px-4 py-3">
                <span className="text-slate-900 dark:text-white font-medium">{type}</span>
                <button
                  onClick={() => handleRemoveType(index)}
                  className="text-slate-400 hover:text-indigo-500 transition-colors p-1"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            {types.length === 0 && (
              <p className="text-slate-500 dark:text-zinc-500 text-center py-4 text-sm">Chưa có phân loại nào</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

