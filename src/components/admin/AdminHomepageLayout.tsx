import React from 'react';
import { Box, X, AlertCircle } from 'lucide-react';
import { HomepageConfig } from '../../types';
import { useProductConfig } from '../../hooks/useProductConfig';

interface AdminHomepageLayoutProps {
  homeConfig: HomepageConfig;
  setHomeConfig: React.Dispatch<React.SetStateAction<HomepageConfig>>;
}

export default function AdminHomepageLayout({ homeConfig, setHomeConfig }: AdminHomepageLayoutProps) {
  const { config: productConfig } = useProductConfig();

  return (
    <div className="xl:col-span-2 space-y-6 min-w-0">
      {/* Sections Configuration */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-zinc-800 pb-3">
          <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
            <Box className="w-4 h-4 text-indigo-500" /> Hệ thống Khối (Sections)
          </h3>
          <button 
            onClick={() => setHomeConfig({ ...homeConfig, sections: [...homeConfig.sections, { id: `section-${Date.now()}`, title: 'Khối mới', typeFilter: 'all', icon: 'Box', iconColorClass: 'text-slate-500' }] })}
            className="text-xs bg-indigo-50 text-indigo-600 hover:bg-indigo-100 px-3 py-1.5 rounded-md font-medium"
          >
            + Thêm Khối
          </button>
        </div>
        <div className="space-y-3">
          {homeConfig.sections.map((section, index) => (
            <div key={section.id} className="relative grid grid-cols-2 gap-3 p-4 bg-slate-50 dark:bg-zinc-800/50 rounded-lg border border-slate-100 dark:border-zinc-700/50">
              <button 
                onClick={() => { const ns = [...homeConfig.sections]; ns.splice(index, 1); setHomeConfig({...homeConfig, sections: ns}); }} 
                className="absolute -top-2 -right-2 bg-white shadow-sm border p-1 text-slate-400 hover:text-red-500 rounded-full w-6 h-6 flex items-center justify-center"
              >
                <X className="w-3 h-3" />
              </button>
              <div className="col-span-2">
                <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Tiêu đề</label>
                <input 
                  type="text" 
                  value={section.title} 
                  onChange={e => { const ns = [...homeConfig.sections]; ns[index].title = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} 
                  className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-sm outline-none focus:border-indigo-500" 
                />
              </div>
              <div>
                <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Icon</label>
                <input 
                  type="text" 
                  value={section.icon} 
                  onChange={e => { const ns = [...homeConfig.sections]; ns[index].icon = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} 
                  className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-xs outline-none focus:border-indigo-500" 
                />
              </div>
              <div>
                <label className="text-[10px] font-semibold text-slate-500 mb-1 block uppercase">Loại SP</label>
                <select 
                  value={section.typeFilter} 
                  onChange={e => { const ns = [...homeConfig.sections]; ns[index].typeFilter = e.target.value; setHomeConfig({...homeConfig, sections: ns}); }} 
                  className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-2 py-1.5 text-xs outline-none focus:border-indigo-500"
                >
                  <option value="all">Tất cả</option>
                  <option value="base">Bản Cơ Bản</option>
                  <option value="expansion">Bản Mở Rộng</option>
                  <option value="accessory">Phụ Kiện</option>
                  <option value="combo">Combo</option>
                  {productConfig.types?.map(type => <option key={type} value={type}>{type}</option>)}
                </select>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Trust Badges */}
      <div className="bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-zinc-800 pb-3">
          <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-indigo-500" /> Badge Cam Kết
          </h3>
          <button 
            onClick={() => setHomeConfig({ ...homeConfig, trustBadges: [...homeConfig.trustBadges, { icon: 'Shield', title: 'Cam kết mới', desc: 'Mô tả', colorClass: 'text-indigo-500' }] })} 
            className="text-xs bg-indigo-50 text-indigo-600 hover:bg-indigo-100 px-3 py-1.5 rounded-md font-medium"
          >
            + Thêm Badge
          </button>
        </div>
        <div className="space-y-3">
          {homeConfig.trustBadges.map((badge, index) => (
            <div key={index} className="relative p-4 bg-slate-50 dark:bg-zinc-800/50 rounded-lg border border-slate-100 dark:border-zinc-700/50">
              <button 
                onClick={() => { const nb = [...homeConfig.trustBadges]; nb.splice(index, 1); setHomeConfig({...homeConfig, trustBadges: nb}); }} 
                className="absolute -top-2 -right-2 bg-white shadow-sm border p-1 text-slate-400 hover:text-red-500 rounded-full w-6 h-6 flex items-center justify-center"
              >
                <X className="w-3 h-3" />
              </button>
              <input 
                type="text" 
                placeholder="Tiêu đề" 
                value={badge.title} 
                onChange={e => { const nb = [...homeConfig.trustBadges]; nb[index].title = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb}); }} 
                className="w-full mb-2 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1.5 text-sm font-medium outline-none focus:border-indigo-500" 
              />
              <input 
                type="text" 
                placeholder="Mô tả chi tiết" 
                value={badge.desc} 
                onChange={e => { const nb = [...homeConfig.trustBadges]; nb[index].desc = e.target.value; setHomeConfig({...homeConfig, trustBadges: nb}); }} 
                className="w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-700 rounded px-3 py-1 text-xs outline-none focus:border-indigo-500" 
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
