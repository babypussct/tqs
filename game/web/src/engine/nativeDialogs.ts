import { boundedPrivateRecord, visibleCardFace, type CardChoice } from './cardSelection';

export interface NativeDialogPrompt {
  kind: 'ag' | 'arrange' | 'generals' | 'generalChoice' | 'boardMove' | 'skills' | 'generalsAndChoice' | 'cardNames'; title: string; cards: CardChoice[];
  rows: string[][]; names: string[]; cancelable: boolean; okOptions?: string[]; cancelOptions?: string[]; autoConfirm?: boolean;
}
export interface NativeDialog {
  prompt: NativeDialogPrompt; ids: Map<string, number>; rows: number[][];
  original: number[][]; capacities: number[]; limits: number[];
  free: boolean; pattern: string; poxi: string;
  skills?: { names: string[]; selected: string[]; min: number; max: number; disabled?: string[] };
  boardPositions?: Map<number, number>;
  general?: { names: string[]; selected: string[]; count: number; rule: string; extra: Record<string, unknown> };
}
const object = (x: unknown): Record<string, unknown> | null =>
  x !== null && typeof x === 'object' && !Array.isArray(x) ? x as Record<string, unknown> : null;
const ids = (x: unknown): x is number[] => Array.isArray(x) && x.length <= 1024 &&
  x.every(v => Number.isSafeInteger(v) && v >= 0) && new Set(x).size === x.length;
const numbers = (x: unknown): x is number[] => Array.isArray(x) && x.length <= 16 &&
  x.every(v => Number.isSafeInteger(v) && v >= 0 && v <= 1024);
let serial = 0;
export function parseNativeDialog(command: string, raw: unknown,
  face: (id: number) => { name?: string; suit?: string | number; number?: number } | null): NativeDialog | null {
  let kind: NativeDialogPrompt['kind']; let rows: number[][]; let names: string[] = [];
  let title = ''; let cancelable = false; let capacities: number[]; let limits: number[];
  let free = true; let pattern = '.'; let poxi = '';
  if (command === 'AskForGeneral') {
    const generalExtra = Array.isArray(raw) ? boundedPrivateRecord(raw[6]) : null;
    if (!Array.isArray(raw) || !Array.isArray(raw[0]) || !raw[0].length || raw[0].length > 1024 ||
      !raw[0].every(x => typeof x === 'string' && x.length > 0 && x.length <= 256) ||
      new Set(raw[0]).size !== raw[0].length || !Number.isInteger(raw[1]) || raw[1] < 1 || raw[1] > raw[0].length ||
      typeof raw[4] !== 'string' || raw[4].length > 256 || !generalExtra) return null;
    const names = [...raw[0]] as string[];
    const cards = names.map(name => ({token: `general-choice-${++serial}`, hidden: false, name}));
    return { prompt: {kind:'generalChoice',title:typeof raw[5] === 'string' && raw[5].length <= 10000 ? raw[5] : '',cards,
      rows:[cards.map(c=>c.token)],names:[],cancelable:false}, ids:new Map(),rows:[],original:[],
      capacities:[],limits:[],free:false,pattern:'.',poxi:'',
      general:{names,selected:[],count:raw[1],rule:raw[4],extra:generalExtra} };
  }
  let boardPositions: Map<number, number> | undefined;
  if (command === 'CustomDialog') {
    const component = object(object(raw)?.component); const model = object(component?.model);
    const prop = object(model?.prop);
    if (component?.url === 'packages/utility/qml/ChooseGeneralsAndChoiceBox.qml' &&
        model?.url === 'packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml') {
      const strings = (x: unknown): x is string[] => Array.isArray(x) && x.length <= 1024 &&
        x.every(v => typeof v === 'string' && v.length > 0 && v.length <= 256) && new Set(x).size === x.length;
      if (!prop || !strings(prop.cards) || !strings(prop.all_cards) || !strings(prop.disable_cards ?? []) ||
          !strings(prop.ok_options) || !strings(prop.cancel_options) ||
          !(prop.ok_options.length + prop.cancel_options.length) || !Number.isInteger(prop.min) || !Number.isInteger(prop.max) ||
          (prop.min as number) < 0 || (prop.max as number) < (prop.min as number) || (prop.max as number) > 1024) return null;
      const names = [...new Set([...prop.cards, ...prop.all_cards])];
      const options = [...prop.ok_options, ...prop.cancel_options];
      const disabledCards = prop.disable_cards as string[];
      if (options.length > 32 || new Set(options).size !== options.length ||
          !disabledCards.every((name: string) => names.includes(name))) return null;
      const cards = names.map(name => ({ token: `general-option-${++serial}`, hidden: false, name }));
      return { prompt: { kind: 'generalsAndChoice', title: typeof prop.prompt === 'string' && prop.prompt.length <= 10000 ? prop.prompt : '',
        cards, rows: [cards.map(c => c.token)], names: [], cancelable: prop.cancel_options.length > 0,
        okOptions: [...prop.ok_options], cancelOptions: [...prop.cancel_options] },
        ids: new Map(), rows: [], original: [], capacities: [], limits: [], free: false, pattern: '.', poxi: '',
        skills: { names, selected: [], min: prop.min as number, max: prop.max as number, disabled: disabledCards } };
    }
    const cardNames = component?.url === 'packages/utility/qml/ChooseCardNamesBox.qml' &&
      model?.url === 'packages/utility/qml/models/ChooseCardNamesModel.qml';
    if (cardNames || (component?.url === 'packages/utility/qml/ChooseSkillBox.qml' &&
        model?.url === 'packages/utility/qml/models/ChooseSkillModel.qml')) {
      const values = cardNames ? { ...prop, skills: prop?.choices, min: prop?.minNum, max: prop?.maxNum } : prop;
      if (cardNames && prop?.repeatable !== false) return null;
      if (!values || !Array.isArray(values.skills) || !values.skills.length || values.skills.length > 256 ||
          !values.skills.every(x => typeof x === 'string' && x.length > 0 && x.length <= 256) ||
          new Set(values.skills).size !== values.skills.length || !Number.isInteger(values.min) || !Number.isInteger(values.max) ||
          (values.min as number) < 0 || (values.max as number) < (values.min as number) || (values.max as number) > values.skills.length ||
          typeof values.cancelable !== 'boolean') return null;
      const names = values.skills as string[];
      const cards = names.map(name => ({ token: `skill-${++serial}`, hidden: false, name }));
      return { prompt: { kind: cardNames ? 'cardNames' : 'skills', autoConfirm: cardNames && values.min === 1 && values.max === 1 && !values.cancelable, title: typeof values.prompt === 'string' && values.prompt.length <= 10000 ? values.prompt : '',
        cards, rows: [cards.map(c => c.token)], names: [], cancelable: values.cancelable },
        ids: new Map(), rows: [], original: [], capacities: [], limits: [], free: false, pattern: '.', poxi: '',
        skills: { names: [...names], selected: [], min: values.min as number, max: values.max as number } };
    }
    // This component only authorizes viewing a pair; never treat arbitrary QML as executable UI.
    if (component?.url !== 'packages/hegemony/qml/KnownBothBox.qml' ||
      model?.url !== 'packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml' ||
      !prop || prop.min !== 0 || prop.max !== 0 || !Array.isArray(prop.cards) || prop.cards.length < 1 || prop.cards.length > 2 ||
      !prop.cards.every(x => typeof x === 'string' && x.length > 0 && x.length <= 256) ||
      new Set(prop.cards).size !== prop.cards.length ||
      !Array.isArray(prop.ok_options) || prop.ok_options.length !== 1 || prop.ok_options[0] !== 'OK' ||
      (prop.cancel_options !== undefined && (!Array.isArray(prop.cancel_options) || prop.cancel_options.length))) return null;
    return { prompt: { kind: 'generals', title: typeof prop.prompt === 'string' && prop.prompt.length <= 10000 ? prop.prompt : '',
      cards: prop.cards.map((name, i) => ({ token: `general-${++serial}-${i}`, hidden: false, name })),
      rows: [], names: [], cancelable: false }, ids: new Map(), rows: [], original: [],
      capacities: [], limits: [], free: false, pattern: '.', poxi: '' };
  }
  if (command === 'AskForMoveCardInBoard') {
    const data = object(raw);
    if (!data || !ids(data.cards) || !data.cards.length || !Array.isArray(data.cardsPosition) ||
      data.cardsPosition.length !== data.cards.length || !data.cardsPosition.every(x=>x===0 || x===1) ||
      !Array.isArray(data.playerIds) || data.playerIds.length !== 2 || !data.playerIds.every(Number.isSafeInteger)) return null;
    boardPositions = new Map(data.cards.map((id,i)=>[id,(data.cardsPosition as number[])[i]]));
    rows = [[...data.cards]]; capacities=[rows[0].length];limits=[1];kind='boardMove';title='Di chuyển một lá bài trên bàn';
  } else if (command === 'AskForAG') {
    const map = object(raw);
    const values = Array.isArray(raw) ? raw : map ? [map['1'], map['2'], map['3']] : null;
    if (!values || !ids(values[0]) || !values[0].length || (values[1] !== undefined && typeof values[1] !== 'boolean')) return null;
    kind = 'ag'; rows = [[...values[0]]]; cancelable = values[1] === true;
    title = typeof values[2] === 'string' && values[2].length <= 10000 ? values[2] : '';
    capacities = [rows[0].length]; limits = [1];
  } else if (command === 'AskForArrangeCards') {
    const data = object(raw);
    if (!data || !Array.isArray(data.cards) || data.cards.length < 1 || data.cards.length > 16 ||
      !data.cards.every(ids) || !numbers(data.capacities) || !numbers(data.limits) ||
      data.capacities.length < data.cards.length || data.limits.length > data.capacities.length ||
      typeof data.is_free !== 'boolean' || typeof data.cancelable !== 'boolean' ||
      typeof data.pattern !== 'string' || data.pattern.length > 256 ||
      typeof data.poxi_type !== 'string' || data.poxi_type.length > 128) return null;
    rows = data.cards.map(row => [...row as number[]]);
    while (rows.length < data.capacities.length) rows.push([]);
    if (new Set(rows.flat()).size !== rows.flat().length || rows.flat().length > 1024) return null;
    capacities = [...data.capacities]; limits = capacities.map((_, i) => (data.limits as number[])[i] ?? 0) as number[];
    if (limits.some((v, i) => v > capacities[i])) return null;
    kind = 'arrange'; free = data.is_free; pattern = data.pattern; poxi = data.poxi_type;
    title = typeof data.prompt === 'string' && data.prompt.length <= 10000 ? data.prompt : ''; cancelable = data.cancelable;
    if (Array.isArray(data.names) && data.names.length <= 1024 &&
        data.names.every(x => typeof x === 'string' && x.length <= 256)) names = [...data.names as string[]];
    else if (data.names !== undefined) return null;
  } else return null;
  const map = new Map<string, number>(); const tokens = new Map<number, string>();
  const safeFace = (id: number) => {
    try { return face(id); } catch { return null; }
  };
  const cards = rows.flat().map(id => {
    const token = `dialog-${++serial}`; map.set(token, id); tokens.set(id, token);
    return { token, hidden: false, ...visibleCardFace(safeFace(id)) };
  });
  return { prompt: { kind, title, cards, rows: rows.map(row => row.map(id => tokens.get(id)!)), names, cancelable },
    ids: map, boardPositions, rows, original: rows.map(row => [...row]), capacities, limits, free, pattern, poxi };
}

/** Match ArrangeCardsModel.moveCard, including swapping when a destination is full. */
export function movedRows(dialog: NativeDialog, token: string, toArea: number, toIndex: number): number[][] | null {
  const id = dialog.ids.get(token);
  if (id === undefined || dialog.prompt.kind !== 'arrange' || !Number.isInteger(toArea) ||
    toArea < 0 || toArea >= dialog.rows.length || !Number.isInteger(toIndex) || toIndex < 0 ||
    toIndex > dialog.rows[toArea].length || dialog.capacities[toArea] === 0) return null;
  const fromArea = dialog.rows.findIndex(row => row.includes(id));
  if (fromArea < 0 || (fromArea === toArea && toArea === 0 && !dialog.free)) return null;
  const rows = dialog.rows.map(row => [...row]); const from = rows[fromArea]; const to = rows[toArea];
  const fromIndex = from.indexOf(id); const swap = fromArea !== toArea && to.length >= dialog.capacities[toArea];
  from.splice(fromIndex, 1);
  if (fromArea === toArea && fromIndex < toIndex) toIndex--;
  toIndex = Math.max(0, Math.min(toIndex, to.length, dialog.capacities[toArea] - 1));
  to.splice(toIndex, 0, id);
  if (swap) from.splice(fromIndex, 0, to.splice(toIndex + 1, 1)[0]);
  return rows;
}
