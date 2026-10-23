import { useEffect, useRef, useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { plainText, useDisplayText } from './engine/displayText';
import { useGameStore } from './store/gameStore';

export type SkillGroup = { general: string; role?: string; skills: string[] };

/** Resolve only a description actually supplied by the pinned Lua translation overlay. */
export function skillDescription(id: string, translations: Record<string, string>): string | null {
  if (!id || id.length > 256) return null;
  const base = id.endsWith('_skill') ? id.slice(0, -6) : id;
  const value = translations[`:${id}`] ?? (base !== id ? translations[`:${base}`] : undefined);
  if (!value || value === `:${id}` || value === `:${base}`) return null;
  return plainText(value).trim() || null;
}

export function SkillInfoSheet({ groups, onClose }: { groups: SkillGroup[]; onClose: () => void }) {
  const translations = useGameStore((state) => state.translations);
  const text = useDisplayText();
  const dialog = useRef<HTMLDivElement>(null);
  const close = useRef<HTMLButtonElement>(null);
  const lastFocus = useRef<HTMLElement | null>(null);
  const onCloseRef = useRef(onClose);
  useEffect(() => { onCloseRef.current = onClose; }, [onClose]);
  useEffect(() => {
    lastFocus.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const priorOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const timer = window.setTimeout(() => close.current?.focus(), 0);
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        onCloseRef.current();
      }
      if (event.key !== 'Tab') return;
      const targets = [...(dialog.current?.querySelectorAll<HTMLElement>('button:not(:disabled), [href], [tabindex]:not([tabindex="-1"])') ?? [])];
      if (!targets.length) { event.preventDefault(); dialog.current?.focus(); return; }
      if (event.shiftKey && document.activeElement === targets[0]) {
        event.preventDefault(); targets.at(-1)?.focus();
      } else if (!event.shiftKey && document.activeElement === targets.at(-1)) {
        event.preventDefault(); targets[0].focus();
      }
    };
    window.addEventListener('keydown', onKeyDown, true);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener('keydown', onKeyDown, true);
      document.body.style.overflow = priorOverflow;
      lastFocus.current?.focus();
    };
  }, []);

  return createPortal(<div className="sg-skill-info-backdrop" role="presentation"
    onClick={(event) => { event.stopPropagation(); if (event.target === event.currentTarget) onClose(); }}>
    <div ref={dialog} className="sg-skill-info-sheet" role="dialog" aria-modal="true"
      aria-label="Thông tin kỹ năng" tabIndex={-1} onKeyDown={(event) => event.stopPropagation()}>
      <div className="sg-skill-info-heading">
        <h2>Thông tin kỹ năng</h2>
        <button ref={close} className="sg-sheet-close-button" type="button" onClick={onClose} aria-label="Đóng thông tin kỹ năng">✕</button>
      </div>
      <div className="sg-skill-info-content">
        {!groups.length && <p className="sg-skill-info-empty">Không có thông tin kỹ năng có thể xem.</p>}
        {groups.map((group, index) => <section key={`${group.general}-${index}`} className="sg-skill-info-group">
          {group.general && <h3>{group.role ? `${group.role}: ` : ''}{text(group.general)}</h3>}
          {group.skills.length ? group.skills.map((id) => <div className="sg-skill-info-description" key={id}>
            <strong>{text(id)}</strong>
            <p>{skillDescription(id, translations) ?? 'Mô tả kỹ năng chưa được nạp.'}</p>
          </div>) : <p className="sg-skill-info-empty">Chưa có thông tin kỹ năng cho tướng này.</p>}
        </section>)}
      </div>
      <button type="button" className="button primary" onClick={onClose}>Đóng</button>
    </div>
  </div>, document.body);
}

/** Separate inspector: never sends a gameplay click, prelight or request reply. */
export function SkillInfoEntry({ name, children }: { name: string; children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const [hover, setHover] = useState(false);
  const [position, setPosition] = useState({ left: 0, top: 0 });
  const text = useDisplayText();
  const translations = useGameStore((state) => state.translations);
  const description = skillDescription(name, translations);
  const trigger = useRef<HTMLButtonElement>(null);
  const showPreview = () => {
    if (!window.matchMedia('(hover: hover) and (pointer: fine)').matches || !trigger.current) return;
    const rect = trigger.current.getBoundingClientRect();
    const width = Math.min(316, window.innerWidth - 16);
    setPosition({ left: Math.max(8, Math.min(window.innerWidth - width - 8, rect.left)),
      top: rect.bottom + 6 > window.innerHeight / 2 ? rect.top - 6 : rect.bottom + 6 });
    setHover(true);
  };
  return <div className="sg-skill-info-entry">
    {children}
    <button ref={trigger} type="button" className="sg-skill-info-trigger"
      aria-label={`Xem mô tả kỹ năng ${text(name)}`} title={`Xem mô tả ${text(name)}`}
      onMouseEnter={showPreview} onMouseLeave={() => setHover(false)}
      onFocus={showPreview} onBlur={() => setHover(false)}
      onClick={(event) => { event.stopPropagation(); setHover(false); setOpen(true); }}>ⓘ</button>
    {hover && !open && description && typeof document !== 'undefined' && createPortal(
      <div className={`sg-skill-info-tooltip${position.top < (trigger.current?.getBoundingClientRect().top ?? 0) ? ' above' : ''}`} style={position} role="tooltip">
        <strong>{text(name)}</strong><p>{description}</p>
      </div>, document.body)}
    {open && <SkillInfoSheet groups={[{ general: '', skills: [name] }]} onClose={() => setOpen(false)} />}
  </div>;
}

export function GeneralInfoTrigger({ getGroups, label = 'Xem kỹ năng tướng', className = '' }: {
  getGroups: () => SkillGroup[];
  label?: string;
  className?: string;
}) {
  const [groups, setGroups] = useState<SkillGroup[] | null>(null);
  return <>
    <button type="button" className={`sg-general-info-trigger ${className}`}
      aria-label={label} title={label}
      onClick={(event) => { event.stopPropagation(); try { setGroups(getGroups()); } catch { setGroups([]); } }}>ⓘ</button>
    {groups && <SkillInfoSheet groups={groups} onClose={() => setGroups(null)} />}
  </>;
}
