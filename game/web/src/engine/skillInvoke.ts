/** The bounded public shape of FreeKill's AskForSkillInvoke callback. */
export interface SkillInvokePrompt {
  skill: string;
  prompt: string;
}

const MAX_SKILL_ID = 256;
const MAX_PROMPT = 10_000;

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown> : null;
}

/**
 * Accept the native array, plus the numeric-key object shape produced by some
 * CBOR/Lua bridges. FreeKill's prompt is optional; an empty prompt is still
 * an actionable skill request and the panel supplies the generic fallback.
 */
export function parseSkillInvokePrompt(value: unknown): SkillInvokePrompt | null {
  const data = Array.isArray(value) ? value : record(value);
  if (!data) return null;
  const get = (index: 0 | 1) => Array.isArray(data)
    ? data[index]
    : (data[String(index + 1)] ?? (index === 0 ? data.skill ?? data.skill_name ?? data.name : data.prompt));
  const skill = get(0);
  const prompt = get(1);
  if (typeof skill !== 'string' || skill.length === 0 || skill.length > MAX_SKILL_ID) return null;
  if (prompt !== undefined && prompt !== null && (typeof prompt !== 'string' || prompt.length > MAX_PROMPT)) return null;
  return { skill, prompt: prompt == null ? '' : prompt };
}
