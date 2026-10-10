/** The two-general Hegemony dialog issued by Room:askToChooseIniticalGeneral. */
export interface InitialGeneralPrompt {
  generals: string[];
  choiceNum: 2;
  enabledKingdoms: string[];
}

const record = (v: unknown): Record<string, unknown> | null =>
  v !== null && typeof v === 'object' && !Array.isArray(v)
    ? v as Record<string, unknown> : null;

/** Other CustomDialog components must never be treated as general selection. */
export function parseInitialGeneralPrompt(data: unknown): InitialGeneralPrompt | null {
  const component = record(record(data)?.component);
  const model = record(component?.model);
  const prop = record(model?.prop);
  if (component?.name !== 'ChooseInitialGeneralBox' ||
      model?.name !== 'ChooseInitialGeneralModel' ||
      prop?.hegemony !== true || prop.choiceNum !== 2) return null;

  const { generals, enabledKingdoms } = prop;
  // The server sends player count * generalNum choices. Large valid room
  // settings can exceed 200; keep a generous input-safety limit instead.
  if (!Array.isArray(generals) || generals.length < 2 || generals.length > 1024 ||
      !generals.every((name) => typeof name === 'string' && name.length > 0 && !name.includes(',')) ||
      new Set(generals).size !== generals.length ||
      !Array.isArray(enabledKingdoms) || enabledKingdoms.length === 0 ||
      !enabledKingdoms.every((k) => typeof k === 'string' && k.length > 0 && !k.includes(',')) ||
      new Set(enabledKingdoms).size !== enabledKingdoms.length) return null;

  return { generals: [...generals], choiceNum: 2, enabledKingdoms: [...enabledKingdoms] };
}
