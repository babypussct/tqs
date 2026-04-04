import React, { useState, useEffect } from 'react';
import { Save, Plus, Trash2, Edit2, CheckCircle, AlertCircle, RefreshCw } from 'lucide-react';
import { useRewardsConfig, DEFAULT_REWARDS_CONFIG } from '../../utils/useRewardsConfig';
import { TierConfig, RewardsConfig } from '../../types';

export default function AdminRewardsConfig() {
  const { config, updateConfig, loading, error } = useRewardsConfig();
  const [formData, setFormData] = useState<RewardsConfig | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

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

  // Handle saving the configuration
  const handleSave = async () => {
    setIsSaving(true);
    setSaveSuccess(false);
    const success = await updateConfig(formData);
    setIsSaving(false);
    if (success) {
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    }
  };

  // Handle tier field changes
  const handleTierChange = (tierId: keyof RewardsConfig['tiers'], field: keyof TierConfig, value: any) => {
    setFormData(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        tiers: {
          ...prev.tiers,
          [tierId]: {
            ...prev.tiers[tierId],
            [field]: value
          }
        }
      };
    });
  };

  // Handle benefits
  const updateBenefit = (tierId: keyof RewardsConfig['tiers'], index: number, value: string) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newBenefits = [...prev.tiers[tierId].benefits];
      newBenefits[index] = value;
      return {
        ...prev,
        tiers: {
          ...prev.tiers,
          [tierId]: {
            ...prev.tiers[tierId],
            benefits: newBenefits
          }
        }
      };
    });
  };

  const addBenefit = (tierId: keyof RewardsConfig['tiers']) => {
    setFormData(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        tiers: {
          ...prev.tiers,
          [tierId]: {
            ...prev.tiers[tierId],
            benefits: [...prev.tiers[tierId].benefits, '']
          }
        }
      };
    });
  };

  const removeBenefit = (tierId: keyof RewardsConfig['tiers'], index: number) => {
    setFormData(prev => {
      if (!prev) return prev;
      const newBenefits = [...prev.tiers[tierId].benefits];
      newBenefits.splice(index, 1);
      return {
        ...prev,
        tiers: {
          ...prev.tiers,
          [tierId]: {
            ...prev.tiers[tierId],
            benefits: newBenefits
          }
        }
      };
    });
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold font-serif text-white mb-2">Hệ Thống Hạng & Điểm (Tiers & Points)</h2>
          <p className="text-slate-400">Cấu hình tự động chuyển hạng và tính điểm cho khách hàng sau khi hoàn thành đơn.</p>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center space-x-2 bg-gradient-to-r from-yellow-500 to-yellow-600 hover:from-yellow-400 hover:to-yellow-500 text-black px-6 py-2 rounded-lg font-medium transition-all disabled:opacity-50"
        >
          {isSaving ? <RefreshCw className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
          <span>{isSaving ? 'Đang lưu...' : 'Lưu Cấu Hình'}</span>
        </button>
      </div>

      {error && (
        <div className="bg-indigo-500/10 text-indigo-500 p-4 rounded-lg flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />
          <p>{error}</p>
        </div>
      )}

      {saveSuccess && (
        <div className="bg-green-500/10 text-green-500 p-4 rounded-lg flex items-center space-x-3">
          <CheckCircle className="w-5 h-5" />
          <p>Đã lưu cấu hình thành công!</p>
        </div>
      )}

      {/* Phần 1: Cấu hình hệ thống Điểm */}
      <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold font-serif text-yellow-500">1. Cấu Hình Điểm Thưởng (Points)</h3>
          <label className="flex items-center cursor-pointer">
            <div className="relative">
              <input 
                type="checkbox" 
                className="sr-only" 
                checked={formData.isActive}
                onChange={(e) => setFormData({...formData, isActive: e.target.checked})}
              />
              <div className={`block w-14 h-8 rounded-full transition-colors ${formData.isActive ? 'bg-yellow-500' : 'bg-zinc-700'}`}></div>
              <div className={`absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${formData.isActive ? 'transform translate-x-6' : ''}`}></div>
            </div>
            <span className="ml-3 text-white font-medium">Bật Tích/Tiêu Điểm</span>
          </label>
        </div>

        <div className={`grid grid-cols-1 md:grid-cols-3 gap-6 ${!formData.isActive ? 'opacity-50 pointer-events-none' : ''}`}>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">Giá trị quy đổi (1 Point = ? VNĐ)</label>
            <input
              type="number"
              value={formData.pointValueVND}
              onChange={(e) => setFormData({...formData, pointValueVND: Number(e.target.value)})}
              className="w-full bg-black border border-zinc-800 text-white rounded-lg px-4 py-2 focus:ring-1 focus:ring-yellow-500 outline-none"
            />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">Số điểm tối thiểu để dùng (Min Points)</label>
            <input
              type="number"
              value={formData.minPointsToUse}
              onChange={(e) => setFormData({...formData, minPointsToUse: Number(e.target.value)})}
              className="w-full bg-black border border-zinc-800 text-white rounded-lg px-4 py-2 focus:ring-1 focus:ring-yellow-500 outline-none"
            />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-slate-400">Giới hạn phần trăm giảm (% tối đa 1 đơn)</label>
            <input
              type="number"
              value={formData.maxDiscountPercentage}
              onChange={(e) => setFormData({...formData, maxDiscountPercentage: Number(e.target.value)})}
              className="w-full bg-black border border-zinc-800 text-white rounded-lg px-4 py-2 focus:ring-1 focus:ring-yellow-500 outline-none"
              max="100"
            />
          </div>
        </div>
      </div>

      {/* Phần 2: Cấu hình phân hạng */}
      <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6">
        <h3 className="text-xl font-bold font-serif text-yellow-500 mb-6">2. Cấu Hình Phân Hạng (Tiers)</h3>
        
        <div className="space-y-8">
          {(Object.entries(formData.tiers) as [keyof RewardsConfig['tiers'], TierConfig][]).map(([tierKey, tier]) => (
            <div key={tierKey} className="bg-black/50 border border-zinc-800 rounded-lg p-6">
              
              <div className="flex items-center space-x-4 mb-4">
                <div className={`p-3 rounded-xl bg-gradient-to-br flex items-center justify-center font-bold text-lg shadow-lg uppercase
                  ${tierKey === 'bronze' ? 'from-orange-400 to-amber-700 text-white' : 
                    tierKey === 'silver' ? 'from-slate-300 to-slate-500 text-white' : 
                    tierKey === 'gold' ? 'from-yellow-400 to-yellow-600 text-black' : 
                    'from-cyan-300 to-blue-600 text-white'
                  }`}>
                  {tierKey}
                </div>
                <div className="flex-1">
                  <input
                    type="text"
                    value={tier.name}
                    onChange={(e) => handleTierChange(tierKey, 'name', e.target.value)}
                    className="bg-transparent border-b border-zinc-700 text-white font-bold text-xl px-0 py-1 focus:border-yellow-500 outline-none w-full max-w-sm"
                    placeholder="Tên hạng (VD: Thành viên Vàng)"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-6">
                <div>
                  <label className="block text-sm text-slate-400 mb-2">Điều kiện Tổng Chi Tiêu tối thiểu (VNĐ)</label>
                  <input
                    type="number"
                    value={tier.minSpent}
                    onChange={(e) => handleTierChange(tierKey, 'minSpent', Number(e.target.value))}
                    className="w-full bg-zinc-900 border border-zinc-800 text-white rounded-lg px-4 py-2 focus:ring-1 focus:ring-yellow-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-sm text-slate-400 mb-2">Hệ số Tích Điểm (Ví dụ 0.05 = 5%)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={tier.pointMultiplier}
                    onChange={(e) => handleTierChange(tierKey, 'pointMultiplier', Number(e.target.value))}
                    className="w-full bg-zinc-900 border border-zinc-800 text-white rounded-lg px-4 py-2 focus:ring-1 focus:ring-yellow-500 outline-none"
                  />
                </div>
              </div>

              {/* Benefits */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <label className="block text-sm text-slate-400">Các Quyền Lợi Hiển Thị:</label>
                  <button 
                    onClick={() => addBenefit(tierKey)}
                    className="text-yellow-500 hover:text-yellow-400 text-sm flex items-center space-x-1"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Thêm quyền lợi</span>
                  </button>
                </div>
                <div className="space-y-3">
                  {tier.benefits.map((benefit, idx) => (
                    <div key={idx} className="flex items-center space-x-2">
                      <div className="w-2 h-2 rounded-full bg-yellow-500 flex-shrink-0" />
                      <input
                        type="text"
                        value={benefit}
                        onChange={(e) => updateBenefit(tierKey, idx, e.target.value)}
                        className="flex-1 bg-zinc-900 border border-zinc-800 text-white rounded-lg px-3 py-1.5 focus:ring-1 focus:ring-yellow-500 outline-none text-sm"
                        placeholder="Mô tả quyền lợi..."
                      />
                      <button 
                        onClick={() => removeBenefit(tierKey, idx)}
                        className="p-1.5 text-slate-500 hover:text-indigo-500 hover:bg-indigo-500/10 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                  {tier.benefits.length === 0 && (
                    <p className="text-slate-500 text-sm italic">Chưa có quyền lợi nào được thiết lập.</p>
                  )}
                </div>
              </div>

            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
