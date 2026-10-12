/** Native AskForChoices payload: enabled, all, limits, cancelable, skill,
 * prompt, detailed, single. Replies are CBOR arrays of the selected strings. */
export interface ChoicePrompt {
  choices: string[];
  allChoices: string[];
  min: number;
  max: number;
  cancelable: boolean;
  skill: string;
  prompt: string;
  single: boolean;
}

export function parseChoicePrompt(data: unknown): ChoicePrompt | null {
  if (!Array.isArray(data)) return null;
  const [choices, allChoices, limits, cancelable, skill, prompt, , single] = data;
  const strings = (v: unknown): v is string[] => Array.isArray(v) && v.length <= 256 &&
    v.every((s) => typeof s === 'string' && s.length > 0 && s.length <= 1000) && new Set(v).size === v.length;
  if (!strings(choices) || !strings(allChoices) || !choices.every((s) => allChoices.includes(s)) ||
      !Array.isArray(limits) || limits.length !== 2 ||
      !limits.every((v) => Number.isInteger(v) && v >= 0 && v <= 256) ||
      limits[0] > limits[1] || limits[0] > choices.length ||
      typeof cancelable !== 'boolean' || typeof skill !== 'string' || skill.length > 256 ||
      typeof prompt !== 'string' || prompt.length > 10000 ||
      typeof single !== 'boolean') return null;
  return { choices: [...choices], allChoices: [...allChoices], min: limits[0], max: limits[1],
    cancelable, skill, prompt, single };
}

export function validChoiceReply(prompt: ChoicePrompt, selected: unknown): selected is string[] {
  return Array.isArray(selected) && selected.length <= prompt.max &&
    (selected.length >= prompt.min || (selected.length === 0 && prompt.cancelable)) &&
    selected.every((s) => typeof s === 'string' && prompt.choices.includes(s)) &&
    new Set(selected).size === selected.length;
}
