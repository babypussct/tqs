import React, { useState, useRef, useEffect } from 'react';
import {
  Image as ImageIcon, Sparkles, Layers, Monitor,
  ChevronDown, ChevronUp, RefreshCw, Zap, ArrowUp, ArrowDown,
  Shuffle, Wind, Pause, Maximize2, Film, Loader, MoveHorizontal, X, Plus, Smartphone
} from 'lucide-react';
import { HomepageConfig, HeroEffects } from '../../types';
import { ImageUploader } from '../ui/ImageUploader';

const DEFAULT_EFFECTS: HeroEffects = {
  particleEnabled: true,
  particleCount: 100,
  particleColor: 'mixed',
  particleIntensity: 0.6,
  particleDirection: 'up',
  particleSizeMin: 1,
  particleSizeMax: 3,
  particleSpread: 1.0,
  animationLayer: 'particles',
  videoUrl: '',
  videoBlend: 'screen',
  videoOpacity: 0.8,
  videoLoop: true,
  overlayStrength: 55,
  overlayStyle: 'dark',
  glowEnabled: true,
  glowColor: 'gold',
  animationPreset: 'cinematic',
  objectPosition: 'center',
};

const PARTICLE_COLORS: Record<HeroEffects['particleColor'], { label: string; color: string }> = {
  gold:  { label: 'Vàng kim', color: '#FFD700' },
  red:   { label: 'Đỏ lửa',  color: '#FF4040' },
  white: { label: 'Trắng',   color: '#FFFFFF' },
  mixed: { label: 'Phối màu',color: 'conic-gradient(#FFD700,#FF4040,#FFF,#FFD700)' },
};

const OVERLAY_STYLES: Record<HeroEffects['overlayStyle'], { label: string; preview: string }> = {
  dark:   { label: 'Tối bí ẩn',      preview: 'rgba(0,0,0,0.6)' },
  gold:   { label: 'Vàng sử thi',    preview: 'rgba(100,60,0,0.4)' },
  red:    { label: 'Đỏ huyền thoại', preview: 'rgba(120,0,0,0.5)' },
  custom: { label: 'Tuỳ chỉnh',      preview: '#333' },
};

const ANIMATION_PRESETS: Record<HeroEffects['animationPreset'], { label: string; desc: string; icon: string }> = {
  cinematic: { label: 'Cinematic', desc: 'Trôi nhẹ, chuyên nghiệp', icon: '🎬' },
  epic:      { label: 'Epic',      desc: 'Nhanh, mạnh, ấn tượng',  icon: '⚡' },
  subtle:    { label: 'Tinh tế',   desc: 'Rất nhẹ, thanh lịch',    icon: '✨' },
  off:       { label: 'Tắt',       desc: 'Không có hiệu ứng',      icon: '🚫' },
};

const DIRECTIONS: { key: HeroEffects['particleDirection']; label: string; icon: React.ReactNode; desc: string }[] = [
  { key: 'up',     label: 'Lên',        icon: <ArrowUp className="w-4 h-4" />,        desc: 'Bay từ dưới lên' },
  { key: 'down',   label: 'Xuống',      icon: <ArrowDown className="w-4 h-4" />,      desc: 'Rơi từ trên xuống' },
  { key: 'float',  label: 'Lơ lửng',   icon: <Wind className="w-4 h-4" />,           desc: 'Trôi nhẹ 4 hướng' },
  { key: 'random', label: 'Hỗn loạn',  icon: <Shuffle className="w-4 h-4" />,        desc: 'Bay ngẫu nhiên' },
];

const GLOW_COLORS: Record<HeroEffects['glowColor'], { label: string; color: string }> = {
  gold:  { label: 'Vàng',  color: '#FFD700' },
  red:   { label: 'Đỏ',   color: '#FF4040' },
  white: { label: 'Trắng', color: '#FFFFFF' },
};

interface Props {
  homeConfig: HomepageConfig;
  setHomeConfig: (config: HomepageConfig) => void;
}

// Styled input
const Input = ({ label, value, onChange, placeholder, hint }: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string; hint?: string;
}) => (
  <div>
    <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-1.5 uppercase tracking-wider">{label}</label>
    <input
      type="text"
      value={value}
      onChange={e => onChange(e.target.value)}
      placeholder={placeholder}
      className="w-full bg-slate-50 dark:bg-zinc-800/60 border border-slate-300 dark:border-zinc-700/60 rounded-xl px-4 py-2.5 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500 focus:bg-white dark:focus:bg-zinc-800 transition-all placeholder-slate-400 dark:placeholder-zinc-600"
    />
    {hint && <p className="text-xs text-slate-400 dark:text-zinc-500 mt-1">{hint}</p>}
  </div>
);

// Slider
const Slider = ({ label, value, min, max, step = 1, unit = '', onChange, color = '#FFD700' }: {
  label: string; value: number; min: number; max: number; step?: number; unit?: string; onChange: (v: number) => void; color?: string;
}) => (
  <div>
    <div className="flex justify-between items-center mb-2">
      <label className="text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider">{label}</label>
      <span className="text-sm font-bold" style={{ color }}>{value}{unit}</span>
    </div>
    <input
      type="range" min={min} max={max} step={step} value={value}
      onChange={e => onChange(Number(e.target.value))}
      className="w-full h-2 rounded-full appearance-none cursor-pointer"
      style={{
        background: `linear-gradient(to right,${color} ${((value-min)/(max-min))*100}%,#3F3F46 ${((value-min)/(max-min))*100}%)`,
      }}
    />
    <div className="flex justify-between text-xs text-slate-400 dark:text-zinc-500 mt-1"><span>{min}{unit}</span><span>{max}{unit}</span></div>
  </div>
);

// Collapsible section
const Section = ({ title, icon, children, defaultOpen = true, accent }: {
  title: string; icon: React.ReactNode; children: React.ReactNode; defaultOpen?: boolean; accent?: string;
}) => {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="rounded-2xl overflow-hidden border border-slate-200 dark:border-zinc-800/50 bg-slate-50 dark:bg-zinc-900/30">
      <button className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-slate-100 dark:hover:bg-zinc-800/50" onClick={() => setOpen(o => !o)}>
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-indigo-100 dark:bg-indigo-500/20">{icon}</div>
          <span className="font-bold text-slate-900 dark:text-white text-sm">{title}</span>
        </div>
        {open ? <ChevronUp className="w-4 h-4 text-slate-400 dark:text-zinc-500" /> : <ChevronDown className="w-4 h-4 text-slate-400 dark:text-zinc-500" />}
      </button>
      {open && <div className="px-5 pb-5 space-y-4 border-t border-slate-200 dark:border-zinc-800/30">{children}</div>}
    </div>
  );
};

// Toggle switch
const Toggle = ({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) => (
  <button
    onClick={() => onChange(!value)}
    className="relative w-12 h-6 rounded-full transition-all shrink-0"
    style={{ background: value ? '#4f46e5' : '#cbd5e1' }}
  >
    <div className="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-all duration-300" style={{ left: value ? '26px' : '2px' }} />
  </button>
);

function ImageField({ label, value, onChange, onClear, hint }: { label: string; value: string; onChange: (v: string) => void; onClear?: () => void; hint?: string }) {
  return (
    <div>
      <div className="mb-1.5">
        <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider">{label}</label>
      </div>
      <ImageUploader 
        value={value}
        onChange={onChange}
        onClear={onClear}
      />
      {hint && <p className="text-xs text-slate-400 dark:text-zinc-500 mt-2">{hint}</p>}
    </div>
  );
}

// ─── Image mini preview ────────────────────────────────────────
function ImageMiniPreview({ src, title, subtitle, effects }: { src: string; title: string; subtitle: string; effects: HeroEffects }) {
  const [imgStatus, setImgStatus] = useState<'loading' | 'ok' | 'error'>('loading');

  useEffect(() => { setImgStatus('loading'); }, [src]);

  const getOverlay = () => {
    const s = effects.overlayStrength / 100;
    switch (effects.overlayStyle) {
      case 'gold': return `rgba(80,40,0,${s * 0.75})`;
      case 'red':  return `rgba(100,0,0,${s * 0.75})`;
      case 'custom': return `${effects.overlayCustomColor || '#000'}${Math.round(s * 200).toString(16).padStart(2, '0')}`;
      default: return `rgba(0,0,0,${s * 0.85})`;
    }
  };

  const glowHex: Record<HeroEffects['glowColor'], string> = { gold: '#FFD700', red: '#FF4040', white: '#FFFFFF' };

  return (
    <div className="rounded-xl overflow-hidden relative border" style={{ borderColor: 'rgba(255,200,50,0.15)', height: '192px' }}>
      {/* Background image */}
      {src && (
        <img
          src={src}
          alt=""
          className="absolute inset-0 w-full h-full object-cover transition-all duration-700"
          style={{ objectPosition: effects.objectPosition, opacity: imgStatus === 'ok' ? 1 : 0 }}
          onLoad={() => setImgStatus('ok')}
          onError={() => setImgStatus('error')}
          referrerPolicy="no-referrer"
        />
      )}

      {/* Status overlay */}
      {imgStatus !== 'ok' && (
        <div className="absolute inset-0 flex items-center justify-center" style={{ background: '#0a0500' }}>
          {imgStatus === 'loading' && src ? (
            <div className="flex flex-col items-center gap-2">
              <Loader className="w-6 h-6 text-indigo-500/60 animate-spin" />
              <p className="text-xs text-slate-400 dark:text-zinc-500">Đang tải ảnh...</p>
            </div>
          ) : null}
        </div>
      )}

      {/* Overlay layers */}
      <div className="absolute inset-0 pointer-events-none" style={{ background: getOverlay() }} />
      <div className="absolute inset-0 bg-gradient-to-r from-black/70 to-black/10 pointer-events-none" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent pointer-events-none" />

      {/* Text preview */}
      <div className="absolute inset-0 flex flex-col justify-center px-6">
        <div className="text-2xl font-black text-white mb-1 leading-tight"
          style={{ textShadow: effects.glowEnabled ? `0 0 20px ${glowHex[effects.glowColor]}80` : 'none' }}
        >
          {title || 'Tiêu đề Hero'}
        </div>
        <div className="text-sm font-bold"
          style={{
            background: 'linear-gradient(135deg,#FFD700,#F97316)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            filter: effects.glowEnabled ? 'drop-shadow(0 0 8px rgba(255,180,0,0.8))' : 'none',
          }}
        >
          {subtitle || 'Subtitle'}
        </div>
      </div>

      {/* Badges */}
      <div className="absolute top-2 right-2 flex items-center gap-1.5">
        {effects.particleEnabled && effects.animationPreset !== 'off' && (
          <div className="text-[10px] px-2 py-0.5 rounded-full font-bold flex items-center gap-1"
            style={{ background: 'rgba(255,200,50,0.15)', color: '#FFD700', border: '1px solid rgba(255,200,50,0.3)' }}>
            <Sparkles className="w-2.5 h-2.5" /> Particle
          </div>
        )}
      </div>

      <div className="absolute bottom-1.5 left-2 text-[9px] px-1.5 py-0.5 rounded"
        style={{ background: 'rgba(0,0,0,0.6)', color: '#666' }}>
        Preview
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
export default function AdminHeroEditor({ homeConfig, setHomeConfig }: Props) {
  const [activeConceptId, setActiveConceptId] = useState<string>('default');

  // Fallback to legacy hero if heroConcepts is undefined
  const concepts = (homeConfig.heroConcepts && homeConfig.heroConcepts.length > 0)
    ? homeConfig.heroConcepts
    : [{
        id: 'default',
        name: 'Concept Mặc định',
        isActive: true,
        main: homeConfig.hero.main,
        side1: homeConfig.hero.side1,
        side2: homeConfig.hero.side2,
        effects: homeConfig.hero.effects
      }];

  const currentConcept = concepts.find(c => c.id === activeConceptId) || concepts[0];
  const effects: HeroEffects = { ...DEFAULT_EFFECTS, ...currentConcept.effects };

  const updateConcept = (patch: Partial<import('../../types').HeroConfig>) => {
    const updated = concepts.map(c => c.id === currentConcept.id ? { ...c, ...patch } : c);
    setHomeConfig({ ...homeConfig, heroConcepts: updated });
  };

  const addConcept = () => {
    const newId = Date.now().toString();
    const newConcept = { ...currentConcept, id: newId, name: 'Concept mới', isActive: false };
    setHomeConfig({ ...homeConfig, heroConcepts: [...concepts, newConcept] });
    setActiveConceptId(newId);
  };

  const removeConcept = (id: string) => {
    if (concepts.length <= 1) return;
    const updated = concepts.filter(c => c.id !== id);
    setHomeConfig({ ...homeConfig, heroConcepts: updated });
    if (activeConceptId === id) setActiveConceptId(updated[0].id);
  };

  const updateEffects = (patch: Partial<HeroEffects>) =>
    updateConcept({ effects: { ...effects, ...patch } });

  const updateMain = (patch: Partial<typeof currentConcept.main>) =>
    updateConcept({ main: { ...currentConcept.main, ...patch } });

  const updateSide = (side: 'side1' | 'side2', patch: Partial<typeof currentConcept.side1>) =>
    updateConcept({ [side]: { ...currentConcept[side], ...patch } });

  const resetEffects = () =>
    updateConcept({ effects: DEFAULT_EFFECTS });

  return (
    <div className="space-y-4">

      {/* Tabs */}
      <div className="bg-slate-50 dark:bg-zinc-800/40 border border-slate-200 dark:border-zinc-700/50 p-2 rounded-xl flex items-center gap-2 overflow-x-auto">
        {concepts.map(c => (
          <div key={c.id} className={`flex items-center gap-3 px-3 py-1.5 rounded-lg border transition-all ${c.id === currentConcept.id ? 'bg-indigo-50 dark:bg-indigo-500/20 border-indigo-200 dark:border-indigo-500/50' : 'bg-slate-50 dark:bg-zinc-800/60 border-transparent'}`}>
            <button onClick={() => setActiveConceptId(c.id)} className={`text-sm font-bold truncate max-w-[150px] ${c.id === currentConcept.id ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-500 dark:text-zinc-400 hover:text-zinc-200'}`}>
              {c.name}
            </button>
            <div className="flex items-center gap-1.5 border-l border-slate-200 dark:border-zinc-700/50 pl-2">
              <button 
                title="Bật/Tắt hiển thị"
                onClick={() => {
                  const updated = concepts.map(xc => xc.id === c.id ? { ...xc, isActive: !xc.isActive } : xc);
                  setHomeConfig({ ...homeConfig, heroConcepts: updated });
                }}
              >
                <div className={`w-2.5 h-2.5 rounded-full ${c.isActive ? 'bg-green-500 shadow-[0_0_8px_#22c55e]' : 'bg-red-500'}`} />
              </button>
              {concepts.length > 1 && (
                <button onClick={() => removeConcept(c.id)} className="text-slate-400 dark:text-zinc-500 hover:text-red-400 ml-1">✕</button>
              )}
            </div>
          </div>
        ))}
        <button onClick={addConcept} className="px-3 py-1.5 rounded-lg border border-dashed border-slate-300 dark:border-zinc-600 text-slate-500 dark:text-zinc-400 hover:text-zinc-200 text-sm flex items-center gap-1 shrink-0 ml-1">
          + Thêm Concept
        </button>
      </div>

      <div className="mb-4">
        <Input label="Tên Concept" value={currentConcept.name} onChange={v => updateConcept({ name: v })} />
      </div>

      {/* ── Live Preview ── */}
      <ImageMiniPreview
        src={currentConcept.main.image}
        title={currentConcept.main.title}
        subtitle={currentConcept.main.subtitle}
        effects={effects}
      />

      {/* ── 1. Hình ảnh nền ── */}
      <Section title="Hình Ảnh Nền" icon={<ImageIcon className="w-4 h-4 text-blue-400" />} accent="rgba(59,130,246,0.15)">
        <div className="pt-3 space-y-4">
          <ImageField
            label="URL ảnh nền chính"
            value={currentConcept.main.image}
            onChange={v => updateMain({ image: v })}
            onClear={() => updateMain({ image: '' })}
            hint="Tỷ lệ 16:9 hoặc rộng hơn trông đẹp nhất. Nhấn Test để kiểm tra URL."
          />

          {/* Vị trí ảnh */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Vị trí ảnh trong khung</label>
            <div className="grid grid-cols-5 gap-1.5">
              {(['center','top','bottom','left','right'] as const).map(pos => (
                <button key={pos} onClick={() => updateEffects({ objectPosition: pos })}
                  className="py-2 rounded-xl text-xs font-medium border transition-all"
                  style={{
                    background: effects.objectPosition === pos ? 'var(--tw-colors-indigo-500-15)' : 'transparent',
                    borderColor: effects.objectPosition === pos ? '#6366f1' : 'var(--tw-colors-slate-200)',
                    color: effects.objectPosition === pos ? '#4f46e5' : '#94a3b8',
                  }}>
                  {pos === 'center' ? 'Giữa' : pos === 'top' ? 'Trên' : pos === 'bottom' ? 'Dưới' : pos === 'left' ? 'Trái' : 'Phải'}
                </button>
              ))}
            </div>
          </div>
        </div>
      </Section>

      {/* ── 2. Overlay ── */}
      <Section title="Lớp Phủ Màu (Overlay)" icon={<Layers className="w-4 h-4 text-purple-400" />} accent="rgba(139,92,246,0.15)">
        <div className="pt-3">
          <Slider label="Độ mờ" value={effects.overlayStrength} min={0} max={100} unit="%" onChange={v => updateEffects({ overlayStrength: v })} color="#9F7AEA" />
        </div>
        <div>
          <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Màu lớp phủ</label>
          <div className="grid grid-cols-2 gap-2">
            {(Object.entries(OVERLAY_STYLES) as [HeroEffects['overlayStyle'], typeof OVERLAY_STYLES[keyof typeof OVERLAY_STYLES]][]).map(([key, { label, preview }]) => (
              <button key={key} onClick={() => updateEffects({ overlayStyle: key })}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl border text-sm font-medium transition-all text-left"
                style={{
                  background: effects.overlayStyle === key ? 'var(--tw-colors-indigo-500-15)' : 'transparent',
                  borderColor: effects.overlayStyle === key ? '#6366f1' : 'var(--tw-colors-slate-200)',
                  color: effects.overlayStyle === key ? '#FFD700' : '#888',
                }}>
                <div className="w-5 h-5 rounded-md shrink-0" style={{ background: preview }} />
                {label}
              </button>
            ))}
          </div>
        </div>
        {effects.overlayStyle === 'custom' && (
          <div className="flex items-center gap-3">
            <input type="color" value={effects.overlayCustomColor || '#000000'} onChange={e => updateEffects({ overlayCustomColor: e.target.value })}
              className="w-10 h-10 rounded-lg border-0 cursor-pointer bg-transparent" />
            <input type="text" value={effects.overlayCustomColor || '#000000'} onChange={e => updateEffects({ overlayCustomColor: e.target.value })}
              className="flex-1 bg-slate-50 dark:bg-zinc-800/60 border border-slate-300 dark:border-zinc-700/60 rounded-xl px-3 py-2 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500"
              placeholder="#000000" />
          </div>
        )}
      </Section>

      {/* ── 3. Lớp hiệu ứng động ── */}
      <Section title="Hiệu Ứng Động (Animation Layer)" icon={<Sparkles className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />} accent="rgba(245,158,11,0.15)">
        {/* ─ Mode selector ─ */}
        <div className="pt-3">
          <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Chọn loại hiệu ứng</label>
          <div className="grid grid-cols-3 gap-2">
            {([
              { key: 'particles', label: 'Đốm Sáng',   icon: <Sparkles className="w-4 h-4" />, desc: 'Particle tự vẽ' },
              { key: 'video',     label: 'Video',       icon: <Film className="w-4 h-4" />,     desc: 'Phủ video MP4' },
              { key: 'none',      label: 'Tắt',         icon: <Pause className="w-4 h-4" />,    desc: 'Không hiệu ứng' },
            ] as { key: HeroEffects['animationLayer']; label: string; icon: React.ReactNode; desc: string }[]).map(({ key, label, icon, desc }) => (
              <button key={key} onClick={() => updateEffects({ animationLayer: key })}
                className="flex flex-col items-center gap-1.5 px-3 py-3 rounded-xl border text-center transition-all"
                style={{
                  background: effects.animationLayer === key ? 'rgba(255,200,50,0.15)' : 'rgba(255,255,255,0.02)',
                  borderColor: effects.animationLayer === key ? 'rgba(255,200,50,0.5)' : 'rgba(255,255,255,0.07)',
                }}>
                <div style={{ color: effects.animationLayer === key ? '#FFD700' : '#666' }}>{icon}</div>
                <span className="text-xs font-bold" style={{ color: effects.animationLayer === key ? '#FFD700' : '#ccc' }}>{label}</span>
                <span className="text-[10px] text-slate-400 dark:text-zinc-500">{desc}</span>
              </button>
            ))}
          </div>
        </div>

        {effects.animationLayer !== 'none' && (
          <div className="space-y-4 mt-4 pt-4 border-t border-white/5">
            {/* Mobile visibility */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-slate-900 dark:text-white">Hiển thị trên Mobile</p>
                <p className="text-[10px] text-slate-400 dark:text-zinc-500">Tắt để giảm mượt nếu web nặng trên điện thoại</p>
              </div>
              <Toggle value={!effects.hideAnimationOnMobile} onChange={v => updateEffects({ hideAnimationOnMobile: !v })} />
            </div>
            
            {/* Vị trí và kích thước */}
            <div className="space-y-4">
              <div className="flex items-center gap-2 mb-2">
                <p className="text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider mr-2">Căn lề (Neo toạ độ 0)</p>
                <button onClick={() => updateEffects({ animAnchorX: 'left' })} className={`px-2.5 py-1 rounded text-[10px] font-bold transition-all ${effects.animAnchorX !== 'right' ? 'bg-indigo-50 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-500/40' : 'bg-transparent text-slate-400 dark:text-zinc-500 border border-slate-200 dark:border-zinc-700/50 hover:bg-slate-100 dark:hover:bg-zinc-800/50'}`}>Lề Trái</button>
                <button onClick={() => updateEffects({ animAnchorX: 'right' })} className={`px-2.5 py-1 rounded text-[10px] font-bold transition-all ${effects.animAnchorX === 'right' ? 'bg-indigo-50 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-500/40' : 'bg-transparent text-slate-400 dark:text-zinc-500 border border-slate-200 dark:border-zinc-700/50 hover:bg-slate-100 dark:hover:bg-zinc-800/50'}`}>Lề Phải</button>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Slider label={effects.animAnchorX === 'right' ? 'Toạ độ X (Từ phải)' : 'Toạ độ X (Từ trái)'} value={effects.animPositionX ?? 0} min={0} max={100} unit="%" onChange={v => updateEffects({ animPositionX: v })} color="#10B981" />
                <Slider label="Toạ độ Y (Từ trên)" value={effects.animPositionY ?? 0} min={0} max={100} unit="%" onChange={v => updateEffects({ animPositionY: v })} color="#10B981" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Slider label="Độ rộng phủ" value={effects.animWidth ?? 100} min={10} max={100} unit="%" onChange={v => updateEffects({ animWidth: v })} color="#3B82F6" />
                <Slider label="Độ cao phủ" value={effects.animHeight ?? 100} min={10} max={100} unit="%" onChange={v => updateEffects({ animHeight: v })} color="#3B82F6" />
              </div>
            </div>
          </div>
        )}

        {/* ─ VIDEO settings ─ */}
        {effects.animationLayer === 'video' && (
          <div className="space-y-4 mt-1">
            {/* URL + test */}
            <ImageField
              label="URL Video (MP4 / WebM)"
              value={effects.videoUrl || ''}
              onChange={v => updateEffects({ videoUrl: v })}
              onClear={() => updateEffects({ videoUrl: '' })}
              hint="Dùng video có nền tối với hiệu ứng sáng để blend đẹp nhất."
            />

            {/* Live video preview */}
            {effects.videoUrl && (
              <div className="rounded-xl overflow-hidden relative border border-white/5" style={{ height: '100px' }}>
                <video
                  key={effects.videoUrl}
                  src={effects.videoUrl}
                  autoPlay muted loop playsInline
                  className="absolute inset-0 w-full h-full object-cover"
                  style={{ mixBlendMode: (effects.videoBlend || 'screen') as React.CSSProperties['mixBlendMode'], opacity: effects.videoOpacity ?? 0.8, background: '#000' }}
                />
                <div className="absolute inset-0" style={{ background: 'rgba(0,0,0,0.4)', mixBlendMode: 'normal' as React.CSSProperties['mixBlendMode'] }} />
                <div className="absolute bottom-1.5 left-2 text-[9px] px-1.5 py-0.5 rounded" style={{ background: 'rgba(0,0,0,0.7)', color: '#888' }}>
                  Video Preview ({effects.videoBlend})
                </div>
              </div>
            )}

            {/* Blend mode */}
            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Chế độ hoà trộn (Blend Mode)</label>
              <div className="grid grid-cols-2 gap-2">
                {([
                  { key: 'screen',   label: 'Screen',   desc: 'Tốt nhất cho hiệu ứng sáng' },
                  { key: 'lighten',  label: 'Lighten',  desc: 'Nhẹ hơn Screen' },
                  { key: 'overlay',  label: 'Overlay',  desc: 'Tương phản cao' },
                  { key: 'normal',   label: 'Normal',   desc: 'Phủ đặc, toàn phần' },
                ] as { key: HeroEffects['videoBlend']; label: string; desc: string }[]).map(({ key, label, desc }) => (
                  <button key={key} onClick={() => updateEffects({ videoBlend: key })}
                    className="flex flex-col items-start px-3 py-2.5 rounded-xl border text-left transition-all"
                    style={{
                      background: effects.videoBlend === key ? 'rgba(255,200,50,0.12)' : 'rgba(255,255,255,0.02)',
                      borderColor: effects.videoBlend === key ? 'rgba(255,200,50,0.4)' : 'rgba(255,255,255,0.06)',
                    }}>
                    <span className="text-xs font-bold" style={{ color: effects.videoBlend === key ? '#FFD700' : '#ccc' }}>{label}</span>
                    <span className="text-[10px] text-slate-400 dark:text-zinc-500">{desc}</span>
                  </button>
                ))}
              </div>
              <p className="text-[10px] text-slate-400 dark:text-zinc-500 mt-2">
                💡 <span className="text-indigo-500">Screen</span> sẽ làm nền đen trong suốt, chỉ giữ lại phần sáng của video — lý tưởng cho video hiệu ứng lửa, hào quang, bụi sáng.
              </p>
            </div>

            {/* Opacity */}
            <Slider label="Độ mờ video" value={Math.round((effects.videoOpacity ?? 0.8) * 100)} min={10} max={100} unit="%" onChange={v => updateEffects({ videoOpacity: v / 100 })} color="#F59E0B" />

            {/* Loop toggle */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-slate-900 dark:text-white">Lặp lại (Loop)</p>
                <p className="text-xs text-slate-400 dark:text-zinc-500">Video phát lại khi kết thúc</p>
              </div>
              <Toggle value={effects.videoLoop !== false} onChange={v => updateEffects({ videoLoop: v })} />
            </div>
          </div>
        )}

        {/* ─ PARTICLE settings (unchanged) ─ */}
        {effects.animationLayer === 'particles' && (
          <>
            {/* Bật/tắt */}
            <div className="flex items-center justify-between pt-1">
              <div>
                <p className="text-sm font-semibold text-slate-900 dark:text-white">Bật đốm sáng</p>
                <p className="text-xs text-slate-400 dark:text-zinc-500">Các hạt phát sáng di chuyển trên màn hình</p>
              </div>
              <Toggle value={effects.particleEnabled} onChange={v => updateEffects({ particleEnabled: v })} />
            </div>

            {effects.particleEnabled && (
          <>
            {/* ─ Hướng di chuyển ─ */}
            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Hướng di chuyển</label>
              <div className="grid grid-cols-2 gap-2">
                {DIRECTIONS.map(({ key, label, icon, desc }) => (
                  <button key={key} onClick={() => updateEffects({ particleDirection: key })}
                    className="flex items-center gap-3 px-3 py-3 rounded-xl border text-sm transition-all text-left"
                    style={{
                      background: effects.particleDirection === key ? 'rgba(255,200,50,0.14)' : 'rgba(255,255,255,0.02)',
                      borderColor: effects.particleDirection === key ? 'rgba(255,200,50,0.45)' : 'rgba(255,255,255,0.06)',
                    }}>
                    <div className="w-7 h-7 rounded-lg flex items-center justify-center shrink-0"
                      style={{ background: effects.particleDirection === key ? 'rgba(255,200,50,0.2)' : 'rgba(255,255,255,0.05)', color: effects.particleDirection === key ? '#FFD700' : '#666' }}>
                      {icon}
                    </div>
                    <div>
                      <p className="font-bold text-xs" style={{ color: effects.particleDirection === key ? '#FFD700' : '#ccc' }}>{label}</p>
                      <p className="text-[10px] text-slate-400 dark:text-zinc-500">{desc}</p>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* ─ Tốc độ (preset) ─ */}
            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Tốc độ chuyển động</label>
              <div className="grid grid-cols-2 gap-2">
                {(Object.entries(ANIMATION_PRESETS) as [HeroEffects['animationPreset'], typeof ANIMATION_PRESETS[keyof typeof ANIMATION_PRESETS]][]).map(([key, { label, desc, icon }]) => (
                  <button key={key} onClick={() => updateEffects({ animationPreset: key })}
                    className="flex flex-col items-start px-3 py-2.5 rounded-xl border text-sm transition-all"
                    style={{
                      background: effects.animationPreset === key ? 'rgba(255,200,50,0.12)' : 'rgba(255,255,255,0.02)',
                      borderColor: effects.animationPreset === key ? 'rgba(255,200,50,0.4)' : 'rgba(255,255,255,0.06)',
                    }}>
                    <span className="text-sm mb-0.5">{icon}</span>
                    <span className="font-bold text-xs" style={{ color: effects.animationPreset === key ? '#FFD700' : '#ccc' }}>{label}</span>
                    <span className="text-[10px] text-slate-400 dark:text-zinc-500">{desc}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* ─ Màu hạt ─ */}
            <div>
              <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Màu đốm sáng</label>
              <div className="grid grid-cols-2 gap-2">
                {(Object.entries(PARTICLE_COLORS) as [HeroEffects['particleColor'], typeof PARTICLE_COLORS[keyof typeof PARTICLE_COLORS]][]).map(([key, { label, color }]) => (
                  <button key={key} onClick={() => updateEffects({ particleColor: key })}
                    className="flex items-center gap-3 px-3 py-2.5 rounded-xl border text-sm font-medium transition-all"
                    style={{
                      background: effects.particleColor === key ? 'rgba(255,200,50,0.12)' : 'rgba(255,255,255,0.02)',
                      borderColor: effects.particleColor === key ? 'rgba(255,200,50,0.4)' : 'rgba(255,255,255,0.06)',
                      color: effects.particleColor === key ? '#FFD700' : '#888',
                    }}>
                    <div className="w-5 h-5 rounded-full shrink-0"
                      style={{ background: color.includes('conic') ? 'conic-gradient(#FFD700,#FF4040,#FFF,#FFD700)' : color, boxShadow: `0 0 8px ${color.includes('conic') ? '#FFD700' : color}66` }} />
                    {label}
                  </button>
                ))}
              </div>
            </div>

            {/* ─ Sliders ─ */}
            <div className="space-y-4 pt-1">
              <Slider label="Số lượng hạt" value={effects.particleCount} min={10} max={300} step={5} onChange={v => updateEffects({ particleCount: v })} color="#F59E0B" />
              <Slider label="Độ sáng" value={Math.round(effects.particleIntensity * 100)} min={5} max={100} unit="%" onChange={v => updateEffects({ particleIntensity: v / 100 })} color="#F59E0B" />

              {/* Size range */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider flex items-center gap-1.5">
                    <Maximize2 className="w-3.5 h-3.5" /> Kích thước hạt
                  </label>
                  <span className="text-xs font-bold text-indigo-600 dark:text-indigo-400">{effects.particleSizeMin ?? 1} – {effects.particleSizeMax ?? 3} px</span>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <p className="text-[10px] text-slate-400 dark:text-zinc-500 mb-1">Nhỏ nhất</p>
                    <input type="range" min={0.5} max={5} step={0.5} value={effects.particleSizeMin ?? 1}
                      onChange={e => updateEffects({ particleSizeMin: Number(e.target.value) })}
                      className="w-full h-2 rounded-full appearance-none cursor-pointer"
                      style={{ background: `linear-gradient(to right,#F59E0B ${((( effects.particleSizeMin ?? 1) - 0.5) / 4.5) * 100}%,#3F3F46 ${(((effects.particleSizeMin ?? 1) - 0.5) / 4.5) * 100}%)` }} />
                  </div>
                  <div>
                    <p className="text-[10px] text-slate-400 dark:text-zinc-500 mb-1">Lớn nhất</p>
                    <input type="range" min={1} max={10} step={0.5} value={effects.particleSizeMax ?? 3}
                      onChange={e => updateEffects({ particleSizeMax: Number(e.target.value) })}
                      className="w-full h-2 rounded-full appearance-none cursor-pointer"
                      style={{ background: `linear-gradient(to right,#F59E0B ${(((effects.particleSizeMax ?? 3) - 1) / 9) * 100}%,#3F3F46 ${(((effects.particleSizeMax ?? 3) - 1) / 9) * 100}%)` }} />
                  </div>
                </div>
              </div>

              {/* Spread (horizontal drift) */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider flex items-center gap-1.5">
                    <MoveHorizontal className="w-3.5 h-3.5" /> Độ phân tán ngang
                  </label>
                  <span className="text-xs font-bold text-indigo-600 dark:text-indigo-400">{(effects.particleSpread ?? 1).toFixed(1)}x</span>
                </div>
                <input type="range" min={0} max={3} step={0.1} value={effects.particleSpread ?? 1}
                  onChange={e => updateEffects({ particleSpread: Number(e.target.value) })}
                  className="w-full h-2 rounded-full appearance-none cursor-pointer"
                  style={{ background: `linear-gradient(to right,#F59E0B ${((effects.particleSpread ?? 1) / 3) * 100}%,#3F3F46 ${((effects.particleSpread ?? 1) / 3) * 100}%)` }} />
                <div className="flex justify-between text-xs text-slate-400 dark:text-zinc-500 mt-1"><span>Thẳng</span><span>Lan rộng</span></div>
              </div>
            </div>
          </>
          )}
        </>
        )}
      </Section>

      <Section title="Phát Sáng Văn Bản (Glow)" icon={<Zap className="w-4 h-4 text-yellow-400" />} accent="rgba(252,211,77,0.12)">
        <div className="flex items-center justify-between pt-3">
          <div>
            <p className="text-sm font-semibold text-slate-900 dark:text-white">Bật glow cho chữ</p>
            <p className="text-xs text-slate-400 dark:text-zinc-500">Title và subtitle phát ánh sáng</p>
          </div>
          <Toggle value={effects.glowEnabled} onChange={v => updateEffects({ glowEnabled: v })} />
        </div>
        {effects.glowEnabled && (
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">Màu ánh sáng</label>
            <div className="flex gap-2">
              {(Object.entries(GLOW_COLORS) as [HeroEffects['glowColor'], typeof GLOW_COLORS[keyof typeof GLOW_COLORS]][]).map(([key, { label, color }]) => (
                <button key={key} onClick={() => updateEffects({ glowColor: key })}
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border text-sm font-medium transition-all"
                  style={{
                    background: effects.glowColor === key ? `${color}18` : 'rgba(255,255,255,0.02)',
                    borderColor: effects.glowColor === key ? `${color}66` : 'rgba(255,255,255,0.06)',
                    color: effects.glowColor === key ? color : '#888',
                  }}>
                  <div className="w-3 h-3 rounded-full" style={{ background: color, boxShadow: `0 0 6px ${color}` }} />
                  {label}
                </button>
              ))}
            </div>
          </div>
        )}
      </Section>

      {/* ── 5. Nội dung văn bản ── */}
      <Section title="Nội Dung Văn Bản" icon={<Monitor className="w-4 h-4 text-green-400" />} accent="rgba(34,197,94,0.12)" defaultOpen={false}>
        <div className="pt-3 grid grid-cols-2 gap-3">
          <Input label="Badge" value={currentConcept.main.badge || ''} onChange={v => updateMain({ badge: v })} placeholder="Hàng Mới Về" />
          <Input label="Tiêu đề" value={currentConcept.main.title} onChange={v => updateMain({ title: v })} placeholder="Tam Quốc Sát" />
        </div>
        <Input label="Phụ đề (gradient)" value={currentConcept.main.subtitle} onChange={v => updateMain({ subtitle: v })} placeholder="Tiêu Chuẩn 2024" />
        <div>
          <label className="block text-xs font-semibold text-slate-500 dark:text-zinc-400 mb-1.5 uppercase tracking-wider">Mô tả</label>
          <textarea rows={2} value={currentConcept.main.description || ''} onChange={e => updateMain({ description: e.target.value })}
            className="w-full bg-slate-50 dark:bg-zinc-800/60 border border-slate-300 dark:border-zinc-700/60 rounded-xl px-4 py-2.5 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500 transition-all resize-none placeholder-slate-400 dark:placeholder-zinc-600"
            placeholder="Mô tả ngắn..." />
        </div>
        <Input label="Nút CTA" value={currentConcept.main.buttonText || ''} onChange={v => updateMain({ buttonText: v })} placeholder="Mua Ngay" />

        {/* ─ Trust Chips ─ */}
        <div className="pt-2 border-t border-slate-200 dark:border-zinc-800/40">
          <div className="flex items-center justify-between mb-3">
            <div>
              <p className="text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider">Dòng cam kết (Trust Chips)</p>
              <p className="text-[10px] text-slate-400 dark:text-zinc-500 mt-0.5">Hiển thị bên dưới nút CTA trên Hero</p>
            </div>
            <button
              onClick={() => {
                const chips = currentConcept.trustChips || [
                  { label: 'Sản phẩm Việt hóa chuẩn 100%', icon: '✦' },
                  { label: 'Hỗ trợ giải đáp thắc mắc', icon: '✦' },
                  { label: 'Cộng đồng kết nối đông đảo', icon: '✦' },
                ];
                updateConcept({ trustChips: [...chips, { label: '', icon: '✦' }] });
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all"
              style={{ background: 'rgba(99,102,241,0.15)', color: '#818cf8', border: '1px solid rgba(99,102,241,0.3)' }}
            >
              <Plus className="w-3.5 h-3.5" /> Thêm dòng
            </button>
          </div>

          <div className="space-y-2">
            {(currentConcept.trustChips || [
              { label: 'Sản phẩm Việt hóa chuẩn 100%', icon: '✦' },
              { label: 'Hỗ trợ giải đáp thắc mắc', icon: '✦' },
              { label: 'Cộng đồng kết nối đông đảo', icon: '✦' },
            ]).map((chip, idx) => {
              const chips = currentConcept.trustChips || [
                { label: 'Sản phẩm Việt hóa chuẩn 100%', icon: '✦' },
                { label: 'Hỗ trợ giải đáp thắc mắc', icon: '✦' },
                { label: 'Cộng đồng kết nối đông đảo', icon: '✦' },
              ];
              return (
                <div key={idx} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={chip.icon}
                    onChange={e => {
                      const updated = chips.map((c, i) => i === idx ? { ...c, icon: e.target.value } : c);
                      updateConcept({ trustChips: updated });
                    }}
                    className="w-12 text-center bg-slate-50 dark:bg-zinc-800/60 border border-slate-300 dark:border-zinc-700/60 rounded-lg px-2 py-2 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500 transition-all"
                    placeholder="✦"
                    title="Icon/ký hiệu"
                  />
                  <input
                    type="text"
                    value={chip.label}
                    onChange={e => {
                      const updated = chips.map((c, i) => i === idx ? { ...c, label: e.target.value } : c);
                      updateConcept({ trustChips: updated });
                    }}
                    className="flex-1 bg-slate-50 dark:bg-zinc-800/60 border border-slate-300 dark:border-zinc-700/60 rounded-lg px-3 py-2 text-sm text-slate-900 dark:text-white outline-none focus:border-indigo-500 transition-all placeholder-slate-400 dark:placeholder-zinc-600"
                    placeholder="Nội dung cam kết..."
                  />
                  <button
                    onClick={() => {
                      const updated = chips.filter((_, i) => i !== idx);
                      updateConcept({ trustChips: updated });
                    }}
                    className="w-8 h-8 flex items-center justify-center rounded-lg transition-all hover:bg-red-500/20 text-slate-400 dark:text-zinc-500 hover:text-red-400 shrink-0"
                    title="Xóa dòng"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              );
            })}
          </div>
          {!currentConcept.trustChips && (
            <p className="text-[10px] text-slate-400 dark:text-zinc-500 mt-2">
              💡 Đang dùng nội dung mặc định. Chỉnh sửa để lưu tùy chỉnh riêng cho concept này.
            </p>
          )}
        </div>
      </Section>


      {/* ── 6. Banner phụ ── */}
      <Section title="Floating Cards (Banner Phụ)" icon={<ImageIcon className="w-4 h-4 text-rose-400" />} accent="rgba(244,63,94,0.12)" defaultOpen={false}>
        <div className="pt-3 space-y-5">
          {(['side1', 'side2'] as const).map((side, i) => (
            <div key={side}>
              <p className="text-xs font-bold text-slate-500 dark:text-zinc-400 uppercase tracking-wider mb-2">Card {i + 1}</p>
              <div className="space-y-3">
                <ImageField label="URL ảnh" value={currentConcept[side].image} onChange={v => updateSide(side, { image: v })} onClear={() => updateSide(side, { image: '' })} />
                <div className="grid grid-cols-2 gap-2">
                  <Input label="Tiêu đề" value={currentConcept[side].title} onChange={v => updateSide(side, { title: v })} />
                  <Input label="Phụ đề" value={currentConcept[side].subtitle} onChange={v => updateSide(side, { subtitle: v })} />
                </div>
                {/* mini preview */}
                <div className="h-16 rounded-xl overflow-hidden relative border border-white/5">
                  {currentConcept[side].image && <img src={currentConcept[side].image} alt="" className="absolute inset-0 w-full h-full object-cover" referrerPolicy="no-referrer" />}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent flex flex-col justify-end p-2.5">
                    <p className="text-white text-xs font-bold">{currentConcept[side].title}</p>
                    <p className="text-indigo-600 dark:text-indigo-400 text-[10px]">{currentConcept[side].subtitle}</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* Reset */}
      <button onClick={resetEffects}
        className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl border text-xs font-medium transition-all hover:bg-slate-100 dark:hover:bg-zinc-800/50"
        style={{ borderColor: 'rgba(255,255,255,0.07)', color: '#555' }}>
        <RefreshCw className="w-3.5 h-3.5" /> Đặt lại hiệu ứng về mặc định
      </button>
    </div>
  );
}
