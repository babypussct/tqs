import { useDisplayText } from './engine/displayText';
import type { RegularSkill } from './store/gameStore';

/**
 * Mirrors native SkillArea while no request scene is active.  The buttons are
 * intentionally display-only here: native RoomModel disables regular skills
 * outside an active request, and the browser must not invent a
 * SkillButton/UpdateRequestUI action.
 */
export default function RegularSkillDock({ skills }: {
  skills: RegularSkill[];
}) {
  const text = useDisplayText();
  if (!skills.length) return null;

  return (
    <aside className="native-skill-dock regular-skill-dock" aria-label="Kỹ năng tướng đã mở">
      <div className="native-skill-header">
        <h3 className="native-skill-heading">Kỹ năng tướng</h3>
        <span className="native-skill-hint">Chờ Lua cho phép</span>
      </div>
      <div className="gameplay-options native-skill-options">
        {skills.map((skill) => (
          <button
            key={skill.name}
            type="button"
            className="sg-skill-button regular-skill-button"
            disabled
            aria-label={`${text(skill.name)}: chưa có yêu cầu kích hoạt`}
            title="Kỹ năng chỉ kích hoạt trong yêu cầu do máy chủ tạo"
          >
            {text(skill.name)}
          </button>
        ))}
      </div>
    </aside>
  );
}
