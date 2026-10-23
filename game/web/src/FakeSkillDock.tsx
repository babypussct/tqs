import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { useDisplayText } from './engine/displayText';
import type { FakeSkill } from './store/gameStore';
import { SkillInfoEntry } from './SkillInfo';

interface FakeSkillDockProps {
  skills: FakeSkill[];
  busy: boolean;
  onToggle: (skillName: string, prelight: boolean) => void;
  floating?: boolean;
}

/**
 * Hegemony's prelight controls are separate from the current request scene.
 * They are available while a hidden general is still face-down, so they must
 * remain visible even when the rest of the dashboard is idle.
 */
export default function FakeSkillDock({ skills, busy, onToggle, floating = false }: FakeSkillDockProps) {
  const text = useDisplayText();
  const [pending, setPending] = useState<Record<string, boolean>>({});
  const timers = useRef(new Map<string, ReturnType<typeof setTimeout>>());

  useEffect(() => {
    const live = new Map(skills.map((skill) => [skill.name, skill]));
    setPending((current) => {
      let changed = false;
      const next: Record<string, boolean> = {};
      for (const [name, expected] of Object.entries(current)) {
        const skill = live.get(name);
        if (!skill || skill.prelighted === expected) {
          changed = true;
          const timer = timers.current.get(name);
          if (timer) clearTimeout(timer);
          timers.current.delete(name);
        } else {
          next[name] = expected;
        }
      }
      return changed ? next : current;
    });
  }, [skills]);

  useEffect(() => () => {
    for (const timer of timers.current.values()) clearTimeout(timer);
    timers.current.clear();
  }, []);

  if (!skills.length) return null;

  const toggle = (skill: FakeSkill) => {
    if (busy || skill.enabled === false || pending[skill.name] !== undefined) return;
    const nextPrelight = !skill.prelighted;
    setPending((current) => ({ ...current, [skill.name]: nextPrelight }));
    const previous = timers.current.get(skill.name);
    if (previous) clearTimeout(previous);
    timers.current.set(skill.name, setTimeout(() => {
      setPending((current) => {
        if (current[skill.name] !== nextPrelight) return current;
        const next = { ...current };
        delete next[skill.name];
        return next;
      });
      timers.current.delete(skill.name);
    }, 5000));
    onToggle(skill.name, nextPrelight);
  };

  const dock = (
    <aside className="native-skill-dock fake-skill-dock" aria-label="Kỹ năng tướng úp">
      <div className="native-skill-header">
        <h3 className="native-skill-heading">Kỹ năng tướng úp</h3>
        <span className="native-skill-hint">Bấm để prelight</span>
      </div>
      <div className="gameplay-options native-skill-options">
        {skills.map((skill) => {
          const translated = text(skill.name);
          const waiting = pending[skill.name] !== undefined;
          const active = skill.prelighted;
          return (
            <SkillInfoEntry key={skill.name} name={skill.name}><button
              type="button"
              className={`sg-skill-button fake-skill-button${active ? ' selected' : ''}`}
              disabled={busy || !skill.enabled || waiting}
              aria-pressed={active}
              aria-label={`${translated}: ${waiting ? 'đang cập nhật' : active ? 'đang prelight' : 'chưa prelight'}`}
              onClick={() => toggle(skill)}
            >
              <span>{translated}</span>
              <small className="fake-skill-state">
                {waiting ? 'Đang cập nhật…' : active ? 'Đang sáng' : 'Chưa sáng'}
              </small>
            </button></SkillInfoEntry>
          );
        })}
      </div>
    </aside>
  );

  // AskForSkillInvoke is a modal request, but Hegemony's prelight controls
  // remain actionable while that request is open.  Portal the dock above the
  // modal only for that short-lived state so the overlay cannot swallow the
  // native prelight click.
  if (floating && typeof document !== 'undefined') {
    return createPortal(<div className="sg-fake-skill-portal">{dock}</div>, document.body);
  }
  return dock;
}
