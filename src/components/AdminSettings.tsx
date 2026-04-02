import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Save, QrCode, Truck } from 'lucide-react';
import { toast } from 'sonner';
import { useProductConfig } from '../hooks/useProductConfig';
import { usePaymentConfig, PaymentConfig } from '../hooks/usePaymentConfig';
import { useShippingConfig } from '../hooks/useShippingConfig';

export default function AdminSettings() {
  const { config, loading: configLoading, updateConfig } = useProductConfig();
  const { paymentConfig, loading: paymentLoading, updatePaymentConfig } = usePaymentConfig();
  
  const [badges, setBadges] = useState<string[]>([]);
  const [types, setTypes] = useState<string[]>([]);
  const [newBadge, setNewBadge] = useState('');
  const [newType, setNewType] = useState('');
  
  const { shippingConfig, loading: shippingLoading, updateShippingConfig } = useShippingConfig();

  const [localPaymentConfig, setLocalPaymentConfig] = useState<PaymentConfig | null>(null);
  const [localShippingConfig, setLocalShippingConfig] = useState<any>(null);

  const [isSaving, setIsSaving] = useState(false);

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

  if (configLoading || paymentLoading || shippingLoading || !localPaymentConfig || !localShippingConfig) return <div className="p-8 text-center text-gray-500">Đang tải cấu hình...</div>;

  return (
    <div className="space-y-8 pb-12">
      <div className="flex justify-between items-center bg-white dark:bg-zinc-900/50 p-6 rounded-2xl border border-gray-200 dark:border-zinc-800/50">
        <div>
          <h2 className="text-xl font-black text-gray-900 dark:text-white pb-1">Cấu hình hệ thống</h2>
          <p className="text-sm text-gray-500 dark:text-zinc-400">Quản lý nhãn, phân loại và thông tin thanh toán</p>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-6 py-2.5 rounded-xl font-bold transition-colors shadow-lg shadow-red-600/20 disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          {isSaving ? 'Đang lưu...' : 'Lưu thay đổi'}
        </button>
      </div>

      {/* Shipping Configuration */}
      <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
        <div className="flex items-center justify-between mb-6 border-b border-gray-100 dark:border-zinc-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 dark:bg-blue-500/10 text-blue-600 dark:text-blue-500 rounded-lg">
              <Truck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Vận chuyển & Freeship</h3>
              <p className="text-xs text-gray-500 dark:text-zinc-400">Cấu hình phí giao hàng mặc định và chính sách miễn phí</p>
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
              <div className={`block w-14 h-8 rounded-full transition-colors ${localShippingConfig.isActive ? 'bg-blue-500' : 'bg-gray-300 dark:bg-zinc-700'}`}></div>
              <div className={`absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${localShippingConfig.isActive ? 'translate-x-6' : ''}`}></div>
            </div>
            <span className="ml-3 text-sm font-medium text-gray-700 dark:text-zinc-300">
              {localShippingConfig.isActive ? 'Đang bật' : 'Đã tắt'}
            </span>
          </label>
        </div>

        <div className={`grid grid-cols-1 md:grid-cols-2 gap-8 transition-opacity ${localShippingConfig.isActive ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Phí vận chuyển mặc định (VNĐ)</label>
            <input
              type="number"
              value={localShippingConfig.defaultFee}
              onChange={e => setLocalShippingConfig({...localShippingConfig, defaultFee: parseInt(e.target.value) || 0})}
              placeholder="Ví dụ: 30000"
              className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 font-mono"
            />
            <p className="text-xs text-gray-500 dark:text-zinc-400 mt-2">Áp dụng cho các đơn hàng không đạt điều kiện Freeship.</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Hạn mức Freeship (VNĐ)</label>
            <input
              type="number"
              value={localShippingConfig.freeshipThreshold ?? ''}
              onChange={e => setLocalShippingConfig({...localShippingConfig, freeshipThreshold: e.target.value ? parseInt(e.target.value) : null})}
              placeholder="Ví dụ: 500000"
              className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 font-mono"
            />
            <p className="text-xs text-gray-500 dark:text-zinc-400 mt-2">Đơn hàng đạt mức giá này sẽ được miễn phí vận chuyển. Xóa trống nếu không áp dụng.</p>
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Sản phẩm đặc quyền Freeship</label>
            <input
              type="text"
              value={localShippingConfig.freeshipProductIds?.join(', ') || ''}
              onChange={e => setLocalShippingConfig({
                ...localShippingConfig, 
                freeshipProductIds: e.target.value.split(',').map(id => id.trim()).filter(id => id)
              })}
              placeholder="Nhập các Product ID cách nhau bởi dấu phẩy..."
              className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 font-mono"
            />
            <p className="text-xs text-gray-500 dark:text-zinc-400 mt-2">Nếu khách hàng mua ít nhất 1 sản phẩm có ID nằm trong danh sách này, toàn bộ đơn hàng sẽ được Freeship.</p>
          </div>
        </div>
      </div>

      {/* Payment Configuration */}
      <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
        <div className="flex items-center justify-between mb-6 border-b border-gray-100 dark:border-zinc-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-100 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-500 rounded-lg">
              <QrCode className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Thanh toán QR (VietQR)</h3>
              <p className="text-xs text-gray-500 dark:text-zinc-400">Cấu hình thông tin nhận chuyển khoản</p>
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
              <div className={`block w-14 h-8 rounded-full transition-colors ${localPaymentConfig.isActive ? 'bg-emerald-500' : 'bg-gray-300 dark:bg-zinc-700'}`}></div>
              <div className={`absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${localPaymentConfig.isActive ? 'translate-x-6' : ''}`}></div>
            </div>
            <span className="ml-3 text-sm font-medium text-gray-700 dark:text-zinc-300">
              {localPaymentConfig.isActive ? 'Đang bật' : 'Đã tắt'}
            </span>
          </label>
        </div>

        <div className={`grid grid-cols-1 lg:grid-cols-3 gap-8 transition-opacity ${localPaymentConfig.isActive ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
          <div className="lg:col-span-2 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Ngân hàng</label>
                <select
                  value={localPaymentConfig.bankId}
                  onChange={e => setLocalPaymentConfig({...localPaymentConfig, bankId: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500"
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
                <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Mẫu QR (Template)</label>
                <select
                  value={localPaymentConfig.template}
                  onChange={e => setLocalPaymentConfig({...localPaymentConfig, template: e.target.value})}
                  className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500"
                >
                  <option value="compact">Gọn nhẹ (compact)</option>
                  <option value="compact2">Gọn nhẹ 2 (compact2)</option>
                  <option value="qr_only">Chỉ mã QR (qr_only)</option>
                  <option value="print">In ấn (print)</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Số tài khoản</label>
              <input
                type="text"
                value={localPaymentConfig.accountNumber}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, accountNumber: e.target.value})}
                placeholder="VD: 0123456789"
                className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 font-mono"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Tên chủ tài khoản</label>
              <input
                type="text"
                value={localPaymentConfig.accountName}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, accountName: e.target.value.toUpperCase()})}
                placeholder="VD: NGUYEN VAN A"
                className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 font-medium uppercase"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-1.5">Ghi chú cho khách hàng</label>
              <textarea
                value={localPaymentConfig.paymentNote}
                onChange={e => setLocalPaymentConfig({...localPaymentConfig, paymentNote: e.target.value})}
                placeholder="Ghi chú hiển thị dưới mã QR lúc thanh toán..."
                rows={2}
                className="w-full bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2.5 text-gray-900 dark:text-white outline-none focus:border-red-500 resize-none text-sm"
              />
            </div>
          </div>

          <div className="flex flex-col items-center justify-center bg-gray-50 dark:bg-zinc-950 rounded-xl p-4 border border-gray-200 dark:border-zinc-800">
            <span className="text-xs font-bold text-gray-500 dark:text-zinc-500 mb-2 uppercase tracking-wide">Demo giao diện Checkout</span>
            {localPaymentConfig.bankId && localPaymentConfig.accountNumber ? (
              <img 
                src={`https://img.vietqr.io/image/${localPaymentConfig.bankId}-${localPaymentConfig.accountNumber}-${localPaymentConfig.template}.png?amount=100000&addInfo=DEMOORDER123&accountName=${encodeURIComponent(localPaymentConfig.accountName)}`} 
                alt="VietQR Demo" 
                className="w-full max-w-[200px] object-contain rounded-lg shadow-sm bg-white"
              />
            ) : (
              <div className="w-full max-w-[200px] aspect-square bg-gray-200 dark:bg-zinc-800 rounded-lg flex items-center justify-center text-gray-400 dark:text-zinc-500 text-sm">
                Vui lòng nhập Bank ID & STK
              </div>
            )}
            <p className="text-xs text-center text-gray-500 dark:text-zinc-400 mt-4 leading-relaxed">
              {localPaymentConfig.paymentNote || 'Vui lòng giữ nguyên nội dung chuyển khoản để hệ thống đối soát tự động.'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Badges */}
        <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Nhãn sản phẩm (Badges)</h3>
          
          <div className="flex gap-2 mb-6">
            <input
              type="text"
              value={newBadge}
              onChange={(e) => setNewBadge(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddBadge()}
              placeholder="VD: Mới, Bán chạy..."
              className="flex-1 bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500 focus:ring-1 focus:ring-red-500"
            />
            <button
              onClick={handleAddBadge}
              className="bg-gray-900 dark:bg-white text-white dark:text-zinc-900 px-4 py-2 rounded-xl font-medium hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-2 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
            {badges.map((badge, index) => (
              <div key={index} className="flex items-center justify-between bg-gray-50 dark:bg-zinc-800/50 border border-gray-200 dark:border-zinc-700/50 rounded-lg px-4 py-3">
                <span className="text-gray-900 dark:text-white font-medium">{badge}</span>
                <button
                  onClick={() => handleRemoveBadge(index)}
                  className="text-gray-400 hover:text-red-500 transition-colors p-1"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            {badges.length === 0 && (
              <p className="text-gray-500 dark:text-zinc-500 text-center py-4 text-sm">Chưa có nhãn nào</p>
            )}
          </div>
        </div>

        {/* Types */}
        <div className="bg-white dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-800/50 rounded-2xl p-6">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">Phân loại sản phẩm (Types)</h3>
          
          <div className="flex gap-2 mb-6">
            <input
              type="text"
              value={newType}
              onChange={(e) => setNewType(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddType()}
              placeholder="VD: Boardgame, Phụ kiện..."
              className="flex-1 bg-gray-50 dark:bg-zinc-800 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-2 text-gray-900 dark:text-white outline-none focus:border-red-500 focus:ring-1 focus:ring-red-500"
            />
            <button
              onClick={handleAddType}
              className="bg-gray-900 dark:bg-white text-white dark:text-zinc-900 px-4 py-2 rounded-xl font-medium hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-2 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
            {types.map((type, index) => (
              <div key={index} className="flex items-center justify-between bg-gray-50 dark:bg-zinc-800/50 border border-gray-200 dark:border-zinc-700/50 rounded-lg px-4 py-3">
                <span className="text-gray-900 dark:text-white font-medium">{type}</span>
                <button
                  onClick={() => handleRemoveType(index)}
                  className="text-gray-400 hover:text-red-500 transition-colors p-1"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
            {types.length === 0 && (
              <p className="text-gray-500 dark:text-zinc-500 text-center py-4 text-sm">Chưa có phân loại nào</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

