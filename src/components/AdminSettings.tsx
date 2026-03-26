import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Save } from 'lucide-react';
import { toast } from 'sonner';
import { useProductConfig } from '../hooks/useProductConfig';

export default function AdminSettings() {
  const { config, loading, updateConfig } = useProductConfig();
  const [badges, setBadges] = useState<string[]>([]);
  const [types, setTypes] = useState<string[]>([]);
  const [newBadge, setNewBadge] = useState('');
  const [newType, setNewType] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!loading) {
      setBadges(config.badges || []);
      setTypes(config.types || []);
    }
  }, [config, loading]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await updateConfig({ badges, types });
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

  if (loading) return <div className="p-8 text-center text-gray-500">Đang tải cấu hình...</div>;

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Cấu hình hệ thống</h2>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-xl font-medium transition-colors disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          {isSaving ? 'Đang lưu...' : 'Lưu thay đổi'}
        </button>
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

          <div className="space-y-2">
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

          <div className="space-y-2">
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
