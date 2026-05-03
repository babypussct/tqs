import React, { useState, useEffect } from 'react';
import { Save, Plus, Trash2, ArrowUp, ArrowDown, CheckCircle, AlertCircle, RefreshCw, Link as LinkIcon, Mail, Phone, MapPin, Clock, CreditCard, Award } from 'lucide-react';
import { useFooterConfig, FooterConfig, FooterLink } from '../../hooks/useFooterConfig';

export default function AdminFooterEditor() {
  const { config, loading, updateConfig } = useFooterConfig();
  const [formData, setFormData] = useState<FooterConfig | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (config) setFormData(config);
  }, [config]);

  if (loading || !formData) {
    return (
      <div className="flex items-center justify-center p-8">
        <RefreshCw className="w-6 h-6 animate-spin text-slate-400" />
      </div>
    );
  }

  const handleSave = async () => {
    setIsSaving(true);
    setSaveSuccess(false);
    setError(null);
    try {
      await updateConfig(formData);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || 'Có lỗi xảy ra khi lưu cấu hình.');
    } finally {
      setIsSaving(false);
    }
  };

  // --- Link helpers ---
  const updateLink = (type: 'categoryLinks' | 'policyLinks', index: number, field: keyof FooterLink, value: any) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev[type]];
      newLinks[index] = { ...newLinks[index], [field]: value };
      return { ...prev, [type]: newLinks };
    });
  };

  const addLink = (type: 'categoryLinks' | 'policyLinks') => {
    setFormData(prev => {
      if (!prev) return prev;
      return { ...prev, [type]: [...prev[type], { label: 'Link mới', path: '/', special: false }] };
    });
  };

  const removeLink = (type: 'categoryLinks' | 'policyLinks', index: number) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev[type]];
      newLinks.splice(index, 1);
      return { ...prev, [type]: newLinks };
    });
  };

  const moveLink = (type: 'categoryLinks' | 'policyLinks', index: number, direction: 'up' | 'down') => {
    const links = formData[type];
    if (direction === 'up' && index === 0) return;
    if (direction === 'down' && index === links.length - 1) return;
    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev[type]];
      const target = direction === 'up' ? index - 1 : index + 1;
      [newLinks[index], newLinks[target]] = [newLinks[target], newLinks[index]];
      return { ...prev, [type]: newLinks };
    });
  };

  // --- Badge / Payment helpers ---
  const updateStringArray = (field: 'badges' | 'paymentMethods', index: number, value: string) => {
    setFormData(prev => {
      if (!prev) return prev;
      const arr = [...prev[field]];
      arr[index] = value;
      return { ...prev, [field]: arr };
    });
  };

  const addStringItem = (field: 'badges' | 'paymentMethods') => {
    setFormData(prev => {
      if (!prev) return prev;
      return { ...prev, [field]: [...prev[field], ''] };
    });
  };

  const removeStringItem = (field: 'badges' | 'paymentMethods', index: number) => {
    setFormData(prev => {
      if (!prev) return prev;
      const arr = [...prev[field]];
      arr.splice(index, 1);
      return { ...prev, [field]: arr };
    });
  };

  // --- Link list renderer ---
  const renderLinkList = (type: 'categoryLinks' | 'policyLinks', title: string) => (
    <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-xl font-bold text-slate-900 dark:text-white">{title}</h3>
        <button onClick={() => addLink(type)} className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 font-medium flex items-center space-x-2 bg-indigo-50 dark:bg-indigo-500/10 px-4 py-2 rounded-lg transition-colors">
          <Plus className="w-4 h-4" /><span>Thêm liên kết</span>
        </button>
      </div>
      <div className="space-y-4">
        {formData[type].map((link, index) => (
          <div key={index} className="group relative flex items-start space-x-4 bg-slate-50 dark:bg-zinc-900/50 border border-slate-200 dark:border-zinc-800/50 rounded-xl p-4 transition-all hover:border-indigo-500/30">
            <div className="flex flex-col space-y-1 mt-1">
              <button onClick={() => moveLink(type, index, 'up')} disabled={index === 0} className="p-1 text-slate-400 hover:text-indigo-500 disabled:opacity-30 transition-colors"><ArrowUp className="w-4 h-4" /></button>
              <button onClick={() => moveLink(type, index, 'down')} disabled={index === formData[type].length - 1} className="p-1 text-slate-400 hover:text-indigo-500 disabled:opacity-30 transition-colors"><ArrowDown className="w-4 h-4" /></button>
            </div>
            <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">Tên hiển thị</label>
                <input type="text" value={link.label} onChange={(e) => updateLink(type, index, 'label', e.target.value)} className="w-full bg-white dark:bg-zinc-900 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="VD: Chính sách bảo hành" />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">Đường dẫn</label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"><LinkIcon className="h-4 w-4 text-slate-400" /></div>
                  <input type="text" value={link.path} onChange={(e) => updateLink(type, index, 'path', e.target.value)} className="w-full bg-white dark:bg-zinc-900 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg pl-9 pr-3 py-2 text-sm focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="/shop" />
                </div>
              </div>
            </div>
            <div className="flex items-center space-x-4 mt-6">
              {type === 'categoryLinks' && (
                <label className="flex items-center space-x-2 cursor-pointer bg-slate-100 dark:bg-zinc-800 px-3 py-1.5 rounded-lg border border-transparent hover:border-slate-300 dark:hover:border-zinc-600 transition-all">
                  <div className="relative">
                    <input type="checkbox" className="sr-only" checked={link.special || false} onChange={(e) => updateLink(type, index, 'special', e.target.checked)} />
                    <div className={`block w-10 h-6 rounded-full transition-colors ${link.special ? 'bg-amber-500' : 'bg-slate-300 dark:bg-zinc-700'}`}></div>
                    <div className={`absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform ${link.special ? 'transform translate-x-4' : ''}`}></div>
                  </div>
                  <span className={`text-xs font-bold ${link.special ? 'text-amber-600 dark:text-amber-400' : 'text-slate-500 dark:text-slate-400'}`}>Nổi Bật</span>
                </label>
              )}
              <button onClick={() => removeLink(type, index)} className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors" title="Xóa"><Trash2 className="w-5 h-5" /></button>
            </div>
          </div>
        ))}
        {formData[type].length === 0 && (
          <div className="text-center py-12 border-2 border-dashed border-slate-200 dark:border-zinc-800 rounded-xl">
            <p className="text-slate-500 dark:text-slate-400">Chưa có liên kết nào.</p>
          </div>
        )}
      </div>
    </div>
  );

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Quản trị Footer (Chân trang)</h2>
          <p className="text-slate-400">Tùy chỉnh nội dung hiển thị ở chân trang và thanh bottom bar.</p>
        </div>
        <button onClick={handleSave} disabled={isSaving} className="flex items-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-xl font-medium transition-all disabled:opacity-50">
          {isSaving ? <RefreshCw className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
          <span>{isSaving ? 'Đang lưu...' : 'Lưu Cấu Hình'}</span>
        </button>
      </div>

      {error && (
        <div className="bg-red-500/10 text-red-500 p-4 rounded-lg flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" /><p>{error}</p>
        </div>
      )}
      {saveSuccess && (
        <div className="bg-green-500/10 text-green-500 p-4 rounded-lg flex items-center space-x-3">
          <CheckCircle className="w-5 h-5" /><p>Đã lưu cấu hình footer thành công!</p>
        </div>
      )}

      {/* 1. Brand Description */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-6">1. Mô Tả Thương Hiệu</h3>
        <div className="space-y-2">
          <label className="block text-sm text-slate-400">Mô tả ngắn hiển thị ở footer</label>
          <textarea value={formData.brandDescription} onChange={(e) => setFormData({ ...formData, brandDescription: e.target.value })} rows={3} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none resize-none" placeholder="Mô tả thương hiệu..." />
        </div>
      </div>

      {/* 2. Social Links */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-6">2. Liên Kết Mạng Xã Hội</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">Facebook URL</label>
            <input type="url" value={formData.socialLinks.facebook} onChange={(e) => setFormData({ ...formData, socialLinks: { ...formData.socialLinks, facebook: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">YouTube URL</label>
            <input type="url" value={formData.socialLinks.youtube} onChange={(e) => setFormData({ ...formData, socialLinks: { ...formData.socialLinks, youtube: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">Email liên hệ</label>
            <input type="email" value={formData.socialLinks.email} onChange={(e) => setFormData({ ...formData, socialLinks: { ...formData.socialLinks, email: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
        </div>
      </div>

      {/* 3. Contact Info */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-6">3. Thông Tin Liên Hệ</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <label className="block text-sm text-slate-400 flex items-center gap-1"><MapPin className="w-3.5 h-3.5" /> Địa chỉ</label>
            <input type="text" value={formData.contactInfo.address} onChange={(e) => setFormData({ ...formData, contactInfo: { ...formData.contactInfo, address: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400 flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> Giờ làm việc</label>
            <input type="text" value={formData.contactInfo.workingHours} onChange={(e) => setFormData({ ...formData, contactInfo: { ...formData.contactInfo, workingHours: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400 flex items-center gap-1"><Phone className="w-3.5 h-3.5" /> Số điện thoại</label>
            <input type="text" value={formData.contactInfo.phone} onChange={(e) => setFormData({ ...formData, contactInfo: { ...formData.contactInfo, phone: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400 flex items-center gap-1"><Mail className="w-3.5 h-3.5" /> Email</label>
            <input type="text" value={formData.contactInfo.email} onChange={(e) => setFormData({ ...formData, contactInfo: { ...formData.contactInfo, email: e.target.value } })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" />
          </div>
        </div>
      </div>

      {/* 4. Category Links */}
      {renderLinkList('categoryLinks', '4. Danh Mục Sản Phẩm (Footer)')}

      {/* 5. Policy Links */}
      {renderLinkList('policyLinks', '5. Chính Sách (Footer)')}

      {/* 6. Badges (Bottom Bar) */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2"><Award className="w-5 h-5 text-amber-500" /> 6. Badges (Thanh Bottom Bar)</h3>
            <p className="text-sm text-slate-400 mt-1">Các nhãn hiển thị trên thanh cuối trang (bottom nav).</p>
          </div>
          <button onClick={() => addStringItem('badges')} className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 font-medium flex items-center space-x-2 bg-indigo-50 dark:bg-indigo-500/10 px-4 py-2 rounded-lg transition-colors">
            <Plus className="w-4 h-4" /><span>Thêm badge</span>
          </button>
        </div>
        <div className="space-y-3">
          {formData.badges.map((badge, idx) => (
            <div key={idx} className="flex items-center space-x-2">
              <div className="w-2 h-2 rounded-full bg-amber-500 flex-shrink-0" />
              <input type="text" value={badge} onChange={(e) => updateStringArray('badges', idx, e.target.value)} className="flex-1 bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-1 focus:ring-indigo-500 outline-none text-sm" placeholder="Nội dung badge..." />
              <button onClick={() => removeStringItem('badges', idx)} className="p-1.5 text-slate-500 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-colors"><Trash2 className="w-4 h-4" /></button>
            </div>
          ))}
          {formData.badges.length === 0 && <p className="text-slate-500 text-sm italic">Chưa có badge nào.</p>}
        </div>
      </div>

      {/* 7. Payment Methods */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2"><CreditCard className="w-5 h-5 text-indigo-500" /> 7. Phương Thức Thanh Toán</h3>
          <button onClick={() => addStringItem('paymentMethods')} className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 font-medium flex items-center space-x-2 bg-indigo-50 dark:bg-indigo-500/10 px-4 py-2 rounded-lg transition-colors">
            <Plus className="w-4 h-4" /><span>Thêm</span>
          </button>
        </div>
        <div className="space-y-3">
          {formData.paymentMethods.map((method, idx) => (
            <div key={idx} className="flex items-center space-x-2">
              <div className="w-2 h-2 rounded-full bg-indigo-500 flex-shrink-0" />
              <input type="text" value={method} onChange={(e) => updateStringArray('paymentMethods', idx, e.target.value)} className="flex-1 bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-1 focus:ring-indigo-500 outline-none text-sm" placeholder="VD: COD, VNPay..." />
              <button onClick={() => removeStringItem('paymentMethods', idx)} className="p-1.5 text-slate-500 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-colors"><Trash2 className="w-4 h-4" /></button>
            </div>
          ))}
          {formData.paymentMethods.length === 0 && <p className="text-slate-500 text-sm italic">Chưa có phương thức nào.</p>}
        </div>
      </div>

      {/* 8. Bottom Text */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-6">8. Dòng Bản Quyền (Copyright)</h3>
        <input type="text" value={formData.bottomText} onChange={(e) => setFormData({ ...formData, bottomText: e.target.value })} className="w-full bg-slate-50 dark:bg-zinc-900/50 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-xl px-4 py-2 focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="© 2024 TQS Store..." />
      </div>
    </div>
  );
}
