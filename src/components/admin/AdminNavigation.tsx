import React, { useState, useEffect } from 'react';
import { Save, Plus, Trash2, ArrowUp, ArrowDown, CheckCircle, AlertCircle, RefreshCw, Link as LinkIcon } from 'lucide-react';
import { useNavigationConfig, NavigationConfig, NavLink } from '../../hooks/useNavigationConfig';

export default function AdminNavigation() {
  const { config, updateConfig, loading } = useNavigationConfig();
  const [formData, setFormData] = useState<NavigationConfig | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (config) {
      setFormData(config);
    }
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

  const updateLink = (index: number, field: keyof NavLink, value: any) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev.links];
      newLinks[index] = { ...newLinks[index], [field]: value };
      return { ...prev, links: newLinks };
    });
  };

  const addLink = () => {
    setFormData(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        links: [
          ...prev.links,
          {
            id: `link-${Date.now()}`,
            label: 'Link mới',
            path: '/',
            highlight: false
          }
        ]
      };
    });
  };

  const removeLink = (index: number) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev.links];
      newLinks.splice(index, 1);
      return { ...prev, links: newLinks };
    });
  };

  const moveLink = (index: number, direction: 'up' | 'down') => {
    if (direction === 'up' && index === 0) return;
    if (direction === 'down' && index === formData.links.length - 1) return;

    setFormData(prev => {
      if (!prev) return prev;
      const newLinks = [...prev.links];
      const targetIndex = direction === 'up' ? index - 1 : index + 1;
      // Swap
      [newLinks[index], newLinks[targetIndex]] = [newLinks[targetIndex], newLinks[index]];
      return { ...prev, links: newLinks };
    });
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Quản trị Navigation (Menu)</h2>
          <p className="text-slate-400">Tùy chỉnh các liên kết trên thanh Topbar Header trực tiếp.</p>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-xl font-medium transition-all disabled:opacity-50"
        >
          {isSaving ? <RefreshCw className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
          <span>{isSaving ? 'Đang lưu...' : 'Lưu Cấu Hình'}</span>
        </button>
      </div>

      {error && (
        <div className="bg-red-500/10 text-red-500 p-4 rounded-lg flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />
          <p>{error}</p>
        </div>
      )}

      {saveSuccess && (
        <div className="bg-green-500/10 text-green-500 p-4 rounded-lg flex items-center space-x-3">
          <CheckCircle className="w-5 h-5" />
          <p>Đã lưu cấu hình menu thành công!</p>
        </div>
      )}

      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm p-6">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-xl font-bold text-slate-900 dark:text-white">Danh sách Liên Kết (Links)</h3>
          <button
            onClick={addLink}
            className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 font-medium flex items-center space-x-2 bg-indigo-50 dark:bg-indigo-500/10 px-4 py-2 rounded-lg transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>Thêm liên kết</span>
          </button>
        </div>

        <div className="space-y-4">
          {formData.links.map((link, index) => (
            <div key={link.id} className="group relative flex items-start space-x-4 bg-slate-50 dark:bg-zinc-900/50 border border-slate-200 dark:border-zinc-800/50 rounded-xl p-4 transition-all hover:border-indigo-500/30">
              {/* Controls */}
              <div className="flex flex-col space-y-1 mt-1">
                <button
                  onClick={() => moveLink(index, 'up')}
                  disabled={index === 0}
                  className="p-1 text-slate-400 hover:text-indigo-500 disabled:opacity-30 disabled:hover:text-slate-400 transition-colors"
                >
                  <ArrowUp className="w-4 h-4" />
                </button>
                <button
                  onClick={() => moveLink(index, 'down')}
                  disabled={index === formData.links.length - 1}
                  className="p-1 text-slate-400 hover:text-indigo-500 disabled:opacity-30 disabled:hover:text-slate-400 transition-colors"
                >
                  <ArrowDown className="w-4 h-4" />
                </button>
              </div>

              {/* Form Fields */}
              <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">Tên hiển thị (Label)</label>
                  <input
                    type="text"
                    value={link.label}
                    onChange={(e) => updateLink(index, 'label', e.target.value)}
                    className="w-full bg-white dark:bg-zinc-900 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-indigo-500 outline-none"
                    placeholder="VD: Tất Cả Sản Phẩm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">Đường dẫn (Path)</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <LinkIcon className="h-4 w-4 text-slate-400" />
                    </div>
                    <input
                      type="text"
                      value={link.path}
                      onChange={(e) => updateLink(index, 'path', e.target.value)}
                      className="w-full bg-white dark:bg-zinc-900 border border-slate-300 dark:border-zinc-700 text-slate-900 dark:text-white rounded-lg pl-9 pr-3 py-2 text-sm focus:ring-1 focus:ring-indigo-500 outline-none"
                      placeholder="VD: /shop"
                    />
                  </div>
                </div>
              </div>

              {/* Toggles and Actions */}
              <div className="flex items-center space-x-4 mt-6">
                <label className="flex items-center space-x-2 cursor-pointer bg-slate-100 dark:bg-zinc-800 px-3 py-1.5 rounded-lg border border-transparent hover:border-slate-300 dark:hover:border-zinc-600 transition-all">
                  <div className="relative">
                    <input
                      type="checkbox"
                      className="sr-only"
                      checked={link.highlight}
                      onChange={(e) => updateLink(index, 'highlight', e.target.checked)}
                    />
                    <div className={`block w-10 h-6 rounded-full transition-colors ${link.highlight ? 'bg-amber-500' : 'bg-slate-300 dark:bg-zinc-700'}`}></div>
                    <div className={`absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform ${link.highlight ? 'transform translate-x-4' : ''}`}></div>
                  </div>
                  <span className={`text-xs font-bold ${link.highlight ? 'text-amber-600 dark:text-amber-400' : 'text-slate-500 dark:text-slate-400'}`}>
                    Nổi Bật
                  </span>
                </label>

                <button
                  onClick={() => removeLink(index)}
                  className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                  title="Xóa liên kết"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            </div>
          ))}
          
          {formData.links.length === 0 && (
            <div className="text-center py-12 border-2 border-dashed border-slate-200 dark:border-zinc-800 rounded-xl">
              <p className="text-slate-500 dark:text-slate-400">Chưa có liên kết nào. Hãy thêm một liên kết hiển thị trên Header!</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
