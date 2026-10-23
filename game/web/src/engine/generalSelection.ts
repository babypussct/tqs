/** The two-general Hegemony dialog issued by Room:askToChooseIniticalGeneral. */
export interface InitialGeneralPrompt {
  generals: string[];
  choiceNum: 2;
  enabledKingdoms: string[];
}

/** Public, bounded registry data for one general already present in the offer. */
export interface InitialGeneralMetadata {
  name: string;
  label: string;
  trueName: string;
  prefix: string;
  kingdom: string;
  subkingdom: string;
  hp: number;
  maxHp: number;
  mainMaxHp: number;
  deputyMaxHp: number;
  shield: number;
  companionWithOffer: boolean;
}

export type InitialGeneralChoicePhase =
  | 'select-main'
  | 'select-deputy'
  | 'select-kingdom'
  | 'ready'
  | 'submitting'
  | 'done'
  | 'expired'
  | 'request-replaced'
  | 'disconnected';

export interface InitialGeneralChoiceState {
  requestId: number;
  offered: string[];
  chosen: string[];
  kingdoms: string[];
  selectedKingdom: string;
  phase: InitialGeneralChoicePhase;
  error: string;
}

export type InitialGeneralChoiceAction =
  | { type: 'select-main'; name: string }
  | { type: 'select-deputy'; name: string; kingdoms: readonly string[] }
  | { type: 'toggle-selected'; name: string }
  | { type: 'select-kingdom'; kingdom: string }
  | { type: 'reset' }
  | { type: 'begin-submit' }
  | { type: 'terminal'; phase: Extract<InitialGeneralChoicePhase, 'done' | 'expired' | 'request-replaced' | 'disconnected'>; error?: string };

const boundedText = (value: unknown, max: number): string | null =>
  typeof value === 'string' && value.length > 0 && value.length <= max && !value.includes(',') ? value : null;

const boundedInteger = (value: unknown, min: number, max: number): number | null =>
  typeof value === 'number' && Number.isSafeInteger(value) && value >= min && value <= max ? value : null;

function normalizedKingdoms(values: readonly string[]): string[] {
  const result: string[] = [];
  for (const value of values) {
    if (typeof value !== 'string' || value.length === 0 || value.length > 128 || value.includes(',') || result.includes(value)) continue;
    result.push(value);
  }
  return result;
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
      !generals.every((name) => typeof name === 'string' && name.length > 0 && name.length <= 256 && !name.includes(',')) ||
      new Set(generals).size !== generals.length ||
      !Array.isArray(enabledKingdoms) || enabledKingdoms.length === 0 ||
      enabledKingdoms.length > 64 ||
      !enabledKingdoms.every((k) => typeof k === 'string' && k.length > 0 && k.length <= 128 && !k.includes(',')) ||
      new Set(enabledKingdoms).size !== enabledKingdoms.length) return null;

  return { generals: [...generals], choiceNum: 2, enabledKingdoms: [...enabledKingdoms] };
}

/**
 * Parse only metadata for the offered identities.  The Lua bridge returns an
 * aligned array, so a missing/duplicated identity invalidates the whole
 * snapshot instead of allowing a card to display data from another general.
 */
export function parseInitialGeneralMetadata(data: unknown, offered: readonly string[]): InitialGeneralMetadata[] {
  if (!Array.isArray(data) || data.length !== offered.length || new Set(offered).size !== offered.length) return [];
  const allowed = new Set(offered);
  const seen = new Set<string>();
  const result: InitialGeneralMetadata[] = [];
  for (const item of data) {
    if (item === null || typeof item !== 'object' || Array.isArray(item)) return [];
    const row = item as Record<string, unknown>;
    const name = boundedText(row.name, 256);
    const label = boundedText(row.label, 512);
    const trueName = boundedText(row.trueName, 256);
    const prefix = row.prefix === '' ? '' : boundedText(row.prefix, 256);
    const kingdom = boundedText(row.kingdom, 128);
    const subkingdom = row.subkingdom === '' ? '' : boundedText(row.subkingdom, 128);
    const hp = boundedInteger(row.hp, 0, 99);
    const maxHp = boundedInteger(row.maxHp, 0, 99);
    const mainMaxHp = boundedInteger(row.mainMaxHp, -99, 99);
    const deputyMaxHp = boundedInteger(row.deputyMaxHp, -99, 99);
    const shield = boundedInteger(row.shield, 0, 99);
    if (!name || !label || !trueName || prefix === null || !kingdom || subkingdom === null ||
        hp === null || maxHp === null || mainMaxHp === null || deputyMaxHp === null || shield === null ||
        !allowed.has(name) || seen.has(name) || typeof row.companionWithOffer !== 'boolean') return [];
    seen.add(name);
    result.push({ name, label, trueName, prefix, kingdom, subkingdom, hp, maxHp,
      mainMaxHp, deputyMaxHp, shield, companionWithOffer: row.companionWithOffer });
  }
  return offered.every((name) => seen.has(name)) ? result : [];
}

export function createInitialGeneralChoiceState(requestId: number, offered: readonly string[]): InitialGeneralChoiceState {
  return { requestId, offered: [...offered], chosen: [], kingdoms: [], selectedKingdom: '', phase: 'select-main', error: '' };
}

function offered(state: InitialGeneralChoiceState, name: string): boolean {
  return typeof name === 'string' && state.offered.includes(name);
}

function clearPair(state: InitialGeneralChoiceState, chosen: string[]): InitialGeneralChoiceState {
  return { ...state, chosen, kingdoms: [], selectedKingdom: '', phase: chosen.length ? 'select-deputy' : 'select-main', error: '' };
}

function pairState(state: InitialGeneralChoiceState, chosen: string[], kingdoms: readonly string[]): InitialGeneralChoiceState {
  const normalized = normalizedKingdoms(kingdoms);
  if (normalized.length === 0) {
    return { ...state, chosen: [chosen[0]], kingdoms: [], selectedKingdom: '', phase: 'select-deputy',
      error: 'Cặp tướng này không có thế lực hợp lệ.' };
  }
  const selectedKingdom = normalized.length === 1 ? normalized[0] : '';
  return { ...state, chosen: [...chosen], kingdoms: normalized, selectedKingdom,
    phase: normalized.length === 1 ? 'ready' : 'select-kingdom', error: '' };
}

/** Pure UI state machine. Lua validity is supplied as the `kingdoms` action payload. */
export function reduceInitialGeneralChoice(
  state: InitialGeneralChoiceState,
  action: InitialGeneralChoiceAction,
): InitialGeneralChoiceState {
  if (['submitting', 'done', 'expired', 'request-replaced', 'disconnected'].includes(state.phase) && action.type !== 'terminal') return state;
  switch (action.type) {
    case 'select-main':
      return state.chosen.length === 0 && offered(state, action.name)
        ? { ...state, chosen: [action.name], kingdoms: [], selectedKingdom: '', phase: 'select-deputy', error: '' }
        : state;
    case 'select-deputy':
      if (state.chosen.length !== 1 || !offered(state, action.name) || state.chosen[0] === action.name) return state;
      return pairState(state, [state.chosen[0], action.name], action.kingdoms);
    case 'toggle-selected': {
      const index = state.chosen.indexOf(action.name);
      if (index < 0) return state;
      // Native QML splices the selected card. Removing the main promotes the
      // deputy; removing the deputy leaves the main in place.
      return clearPair(state, index === 0 ? state.chosen.slice(1) : [state.chosen[0]]);
    }
    case 'select-kingdom':
      return state.chosen.length === 2 && state.kingdoms.includes(action.kingdom)
        ? { ...state, selectedKingdom: action.kingdom, phase: 'ready', error: '' }
        : { ...state, error: 'Thế lực đã chọn không được máy chủ cho phép.' };
    case 'reset':
      return { ...state, chosen: [], kingdoms: [], selectedKingdom: '', phase: 'select-main', error: '' };
    case 'begin-submit':
      return isInitialGeneralReady(state) ? { ...state, phase: 'submitting', error: '' } : state;
    case 'terminal':
      return { ...state, chosen: [], kingdoms: [], selectedKingdom: '', phase: action.phase, error: action.error ?? '' };
  }
}

export function isInitialGeneralReady(state: InitialGeneralChoiceState): boolean {
  return state.phase === 'ready' && state.chosen.length === 2 && state.kingdoms.includes(state.selectedKingdom);
}
