/**
 * Deterministic, test-only scenario descriptions for the real Lua browser
 * fixture.
 *
 * This module deliberately describes requirements ("a Peach", "an equip")
 * rather than card IDs. IDs are allocated by the installed native package
 * registry and can change when the package pin changes. The fixture resolves
 * the requirements against the native draw pile, puts the requested cards at
 * deterministic positions, and only then emits the server-side event that
 * the UI is expected to render.
 *
 * The plans are not imported by the production application and do not add a
 * client command, a cheat, or a server permission. A real C++ QA room would
 * need a separately installed, authenticated server-side scenario package;
 * the browser fixture remains the safe local implementation of this
 * contract.
 */

export type QaScenarioId =
  | 'draw-sequence'
  | 'card-chosen'
  | 'poxi'
  | 'cards-and-choice'
  | 'rescue-normal'
  | 'rescue-battle'
  | 'founding'
  | 'fazheng-enyuan'
  | 'hidden-yiji'
  | 'hidden-yiji-deputy'
  | 'hidden-jianxiong'
  | 'hidden-jianxiong-deputy'
  | 'hidden-fankui'
  | 'hidden-fankui-deputy'
  | 'hidden-reveal'
  | 'hidden-reveal-deputy'
  | 'hidden-active'
  | 'hidden-active-main'
  | 'hidden-view-as'
  | 'hidden-view-as-main'
  | 'hidden-dual';

export type QaCardMatcher =
  | { trueName: string }
  | { name: string }
  | { type: 'equip' };

export type QaCardArea = 'hand' | 'equip';
export type QaCardOwner = 'self' | 'opponent';

export interface QaCardSlot {
  key: string;
  match: QaCardMatcher;
  /** Index into drawSequence; a slot never consumes a second copy by accident. */
  drawIndex: number;
  owner: QaCardOwner;
  area: QaCardArea;
  /** Whether the MoveCards fixture notification may reveal the card face. */
  visible: boolean;
}

export type QaScenarioTrigger =
  | 'play-card'
  | 'card-chosen'
  | 'poxi'
  | 'cards-and-choice'
  | 'rescue-normal'
  | 'rescue-battle'
  | 'founding'
  | 'damage-exchange'
  | 'hidden-yiji'
  | 'hidden-jianxiong'
  | 'hidden-fankui'
  | 'hidden-reveal'
  | 'hidden-active'
  | 'hidden-view-as'
  | 'hidden-dual';

export interface QaScenarioPlan {
  version: 1;
  id: QaScenarioId;
  title: string;
  /** Unsigned 32-bit seed used only for the unreserved tail of the pile. */
  seed: number;
  /** Requirements are consumed from left to right and become the pile top. */
  drawSequence: readonly QaCardMatcher[];
  slots: readonly QaCardSlot[];
  trigger: QaScenarioTrigger;
  expectedCommand: string;
}

export interface QaCardDescriptor {
  id: number;
  name: string;
  trueName: string;
  /** The fixture normalizes the native enum to keep this module package-agnostic. */
  type: string;
}

export interface ResolvedQaScenario {
  plan: QaScenarioPlan;
  drawPile: number[];
  slotCards: Record<string, number>;
}

const trueName = (value: string): QaCardMatcher => ({ trueName: value });
const named = (value: string): QaCardMatcher => ({ name: value });
const equip = (): QaCardMatcher => ({ type: 'equip' });

const slot = (
  key: string,
  match: QaCardMatcher,
  owner: QaCardOwner,
  area: QaCardArea,
  visible: boolean,
  drawIndex: number,
): QaCardSlot => ({ key, match, drawIndex, owner, area, visible });

/**
 * The scenario matrix is intentionally small and explicit. Every required
 * caller gets one named entry, and every entry declares the native command
 * which proves that its precondition was actually reached.
 */
export const QA_SCENARIOS: Readonly<Record<QaScenarioId, QaScenarioPlan>> = {
  'draw-sequence': {
    version: 1,
    id: 'draw-sequence',
    title: 'Bốc bài theo thứ tự cố định',
    seed: 0x51a7e2d1,
    drawSequence: [trueName('slash'), trueName('peach'), named('heg__nullification')],
    slots: [
      slot('slash', trueName('slash'), 'self', 'hand', true, 0),
      slot('peach', trueName('peach'), 'self', 'hand', true, 1),
      slot('nullification', named('heg__nullification'), 'self', 'hand', true, 2),
    ],
    trigger: 'play-card',
    expectedCommand: 'PlayCard',
  },
  'card-chosen': {
    version: 1,
    id: 'card-chosen',
    title: 'Chọn một lá bài đối thủ, gồm lá úp',
    seed: 0x2c9f4a17,
    drawSequence: [trueName('peach'), equip()],
    slots: [
      slot('hidden-hand', trueName('peach'), 'opponent', 'hand', false, 0),
      slot('public-equip', equip(), 'opponent', 'equip', true, 1),
    ],
    trigger: 'card-chosen',
    expectedCommand: 'AskForCardChosen',
  },
  poxi: {
    version: 1,
    id: 'poxi',
    title: 'Poxi nhiều lá với giới hạn native',
    seed: 0x7b31d9e4,
    drawSequence: [trueName('peach'), equip()],
    slots: [
      slot('hidden-hand', trueName('peach'), 'opponent', 'hand', false, 0),
      slot('public-equip', equip(), 'opponent', 'equip', true, 1),
    ],
    trigger: 'poxi',
    expectedCommand: 'AskForPoxi',
  },
  'cards-and-choice': {
    version: 1,
    id: 'cards-and-choice',
    title: 'Xem bài và chọn phương án',
    seed: 0x1eafc0de,
    drawSequence: [trueName('slash'), equip(), trueName('peach')],
    slots: [
      slot('slash', trueName('slash'), 'self', 'hand', true, 0),
      slot('equip', equip(), 'self', 'hand', true, 1),
      slot('peach', trueName('peach'), 'self', 'hand', true, 2),
    ],
    trigger: 'cards-and-choice',
    expectedCommand: 'AskForCardsAndChoice',
  },
  'rescue-normal': {
    version: 1,
    id: 'rescue-normal',
    title: 'Cứu đồng đội bằng Đào ngoài Quyết chiến',
    seed: 0x42badd11,
    drawSequence: [trueName('peach')],
    slots: [slot('peach', trueName('peach'), 'self', 'hand', true, 0)],
    trigger: 'rescue-normal',
    expectedCommand: 'AskForUseCard',
  },
  'rescue-battle': {
    version: 1,
    id: 'rescue-battle',
    title: 'Quyết chiến: chuyển Đào thành Rượu để tự cứu',
    seed: 0x99c0ffee,
    drawSequence: [trueName('peach')],
    slots: [slot('peach', trueName('peach'), 'self', 'hand', true, 0)],
    trigger: 'rescue-battle',
    expectedCommand: 'AskForUseCard',
  },
  founding: {
    version: 1,
    id: 'founding',
    title: 'Dã tâm gia lập quốc',
    seed: 0x0f0ad001,
    drawSequence: [],
    slots: [],
    trigger: 'founding',
    expectedCommand: 'AskForChoices',
  },
  'fazheng-enyuan': {
    version: 1,
    id: 'fazheng-enyuan',
    title: 'Long Đảm, hai nhánh Ân Oán và tùy chọn Di Kế/Phản Quỹ',
    seed: 0x6e9a2026,
    // Three real attacks consume the Wei Slashes. The spare Peach is given
    // after attack 2, leaving no hand card after attack 3. Shu keeps a Slash
    // for Longdan defense, a Jink for the counterattack and a card to steal.
    drawSequence: [trueName('slash'), trueName('slash'), trueName('slash'), trueName('peach'),
      trueName('slash'), trueName('jink'), trueName('peach')],
    slots: [
      slot('actor-slash-1', trueName('slash'), 'self', 'hand', true, 0),
      slot('actor-slash-2', trueName('slash'), 'self', 'hand', true, 1),
      slot('actor-slash-3', trueName('slash'), 'self', 'hand', true, 2),
      slot('actor-gift', trueName('peach'), 'self', 'hand', true, 3),
      slot('target-dodge', trueName('slash'), 'opponent', 'hand', false, 4),
      slot('target-counter', trueName('jink'), 'opponent', 'hand', false, 5),
      slot('target-loot', trueName('peach'), 'opponent', 'hand', false, 6),
    ],
    trigger: 'damage-exchange',
    // The native QA director replaces the selected pair with:
    // Wei: Quách Gia + Tư Mã Ý; Shu: Triệu Vân + Pháp Chính.
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-yiji': {
    version: 1,
    id: 'hidden-yiji',
    title: 'Quách Gia úp: prelight Di Kế trước sát thương',
    seed: 0x74d1c0de,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-yiji',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-yiji-deputy': {
    version: 1,
    id: 'hidden-yiji-deputy',
    title: 'Quách Gia úp ở phó tướng: prelight Di Kế trước sát thương',
    seed: 0x74d1c0df,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-yiji',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jianxiong': {
    version: 1,
    id: 'hidden-jianxiong',
    title: 'Cao Cao úp: prelight Gian Hùng, nhận sát thương và lấy lá Sát',
    seed: 0x5d6e7f87,
    drawSequence: [trueName('slash')],
    slots: [slot('jianxiong-card', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-jianxiong',
    expectedCommand: 'AskForChoices',
  },
  'hidden-jianxiong-deputy': {
    version: 1,
    id: 'hidden-jianxiong-deputy',
    title: 'Cao Cao úp ở phó tướng: prelight Gian Hùng và lấy lá Sát',
    seed: 0x5d6e7f88,
    drawSequence: [trueName('slash')],
    slots: [slot('jianxiong-card', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-jianxiong',
    expectedCommand: 'AskForChoices',
  },
  'hidden-fankui': {
    version: 1,
    id: 'hidden-fankui',
    title: 'Tư Mã Ý úp: prelight Phản Quỹ trước sát thương',
    seed: 0x5d6e7f96,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      slot('fankui-damage', trueName('slash'), 'opponent', 'hand', false, 0),
      slot('fankui-loot', trueName('peach'), 'opponent', 'hand', false, 1),
    ],
    trigger: 'hidden-fankui',
    expectedCommand: 'AskForCardChosen',
  },
  'hidden-fankui-deputy': {
    version: 1,
    id: 'hidden-fankui-deputy',
    title: 'Tư Mã Ý úp ở phó tướng: prelight Phản Quỹ trước sát thương',
    seed: 0x5d6e7f97,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      slot('fankui-damage', trueName('slash'), 'opponent', 'hand', false, 0),
      slot('fankui-loot', trueName('peach'), 'opponent', 'hand', false, 1),
    ],
    trigger: 'hidden-fankui',
    expectedCommand: 'AskForCardChosen',
  },
  'hidden-reveal': {
    version: 1,
    id: 'hidden-reveal',
    title: 'Tướng úp: dùng Mở tướng cho kỹ năng Tỏa định',
    seed: 0x5d6e7f81,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-reveal',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-reveal-deputy': {
    version: 1,
    id: 'hidden-reveal-deputy',
    title: 'Tướng phó úp: dùng Mở tướng cho kỹ năng Tỏa định',
    seed: 0x5d6e7f83,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-reveal',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-active': {
    version: 1,
    id: 'hidden-active',
    title: 'Tôn Quyền úp: Chế Hành mở tướng trước khi dùng',
    seed: 0x5d6e7f82,
    drawSequence: [trueName('slash')],
    slots: [slot('zhiheng-card', trueName('slash'), 'self', 'hand', true, 0)],
    trigger: 'hidden-active',
    expectedCommand: 'PlayCard',
  },
  'hidden-active-main': {
    version: 1,
    id: 'hidden-active-main',
    title: 'Tôn Quyền úp ở chủ tướng: Chế Hành mở tướng trước khi dùng',
    seed: 0x5d6e7f84,
    drawSequence: [trueName('slash')],
    slots: [slot('zhiheng-card', trueName('slash'), 'self', 'hand', true, 0)],
    trigger: 'hidden-active',
    expectedCommand: 'PlayCard',
  },
  'hidden-view-as': {
    version: 1,
    id: 'hidden-view-as',
    title: 'Triệu Vân phó tướng úp: Long Đảm đổi Thiểm thành Sát',
    seed: 0x5d6e7f85,
    drawSequence: [trueName('jink')],
    slots: [slot('longdan-card', trueName('jink'), 'self', 'hand', true, 0)],
    trigger: 'hidden-view-as',
    expectedCommand: 'PlayCard',
  },
  'hidden-view-as-main': {
    version: 1,
    id: 'hidden-view-as-main',
    title: 'Triệu Vân chủ tướng úp: Long Đảm đổi Thiểm thành Sát',
    seed: 0x5d6e7f86,
    drawSequence: [trueName('jink')],
    slots: [slot('longdan-card', trueName('jink'), 'self', 'hand', true, 0)],
    trigger: 'hidden-view-as',
    expectedCommand: 'PlayCard',
  },
  'hidden-dual': {
    version: 1,
    id: 'hidden-dual',
    title: '颜良文丑 úp: Song Hùng trigger và Duel khác màu',
    seed: 0x5d6e7f95,
    drawSequence: [trueName('slash'), trueName('jink')],
    slots: [
      slot('shuangxiong-card', trueName('slash'), 'self', 'hand', true, 0),
      slot('shuangxiong-discard', trueName('jink'), 'opponent', 'hand', false, 1),
    ],
    trigger: 'hidden-dual',
    expectedCommand: 'AskForSkillInvoke',
  },
};

export const QA_SCENARIO_IDS: readonly QaScenarioId[] = [
  'draw-sequence', 'card-chosen', 'poxi', 'cards-and-choice',
  'rescue-normal', 'rescue-battle', 'founding', 'fazheng-enyuan',
  'hidden-yiji', 'hidden-jianxiong', 'hidden-reveal', 'hidden-active',
  'hidden-yiji-deputy', 'hidden-jianxiong-deputy', 'hidden-reveal-deputy', 'hidden-active-main',
  'hidden-fankui', 'hidden-fankui-deputy',
  'hidden-view-as', 'hidden-view-as-main',
  'hidden-dual',
];

export class QaScenarioError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'QaScenarioError';
  }
}

export function getQaScenario(id: QaScenarioId): QaScenarioPlan {
  return QA_SCENARIOS[id];
}

function matches(card: QaCardDescriptor, requirement: QaCardMatcher): boolean {
  if ('trueName' in requirement) return card.trueName === requirement.trueName;
  if ('name' in requirement) return card.name === requirement.name;
  return requirement.type === 'equip' && card.type === 'equip';
}

function nextRandom(state: number): number {
  let next = state >>> 0;
  next ^= next << 13;
  next ^= next >>> 17;
  next ^= next << 5;
  return next >>> 0;
}

/** A reproducible Fisher–Yates shuffle with no dependency on host locale/time. */
export function deterministicShuffle<T>(values: readonly T[], seed: number): T[] {
  const result = [...values];
  let state = (seed >>> 0) || 0x6d2b79f5;
  for (let index = result.length - 1; index > 0; index--) {
    state = nextRandom(state);
    const swap = state % (index + 1);
    [result[index], result[swap]] = [result[swap], result[index]];
  }
  return result;
}

function validatePlan(plan: QaScenarioPlan): void {
  if (plan.version !== 1 || !Number.isSafeInteger(plan.seed) || plan.seed < 0) {
    throw new QaScenarioError(`Invalid QA scenario metadata: ${plan.id}`);
  }
  if (!plan.expectedCommand || !plan.trigger) {
    throw new QaScenarioError(`QA scenario ${plan.id} has no trigger contract`);
  }
  const keys = new Set<string>();
  const drawIndexes = new Set<number>();
  for (const item of plan.slots) {
    if (!/^[a-z][a-z0-9-]{0,48}$/u.test(item.key) || keys.has(item.key)) {
      throw new QaScenarioError(`QA scenario ${plan.id} has duplicate/invalid slot key`);
    }
    if (!Number.isSafeInteger(item.drawIndex) || item.drawIndex < 0 || item.drawIndex >= plan.drawSequence.length) {
      throw new QaScenarioError(`QA scenario ${plan.id} has an invalid drawIndex for ${item.key}`);
    }
    if (drawIndexes.has(item.drawIndex)) {
      throw new QaScenarioError(`QA scenario ${plan.id} reuses drawIndex ${item.drawIndex}`);
    }
    drawIndexes.add(item.drawIndex);
    keys.add(item.key);
  }
  if (plan.trigger === 'card-chosen' || plan.trigger === 'poxi') {
    if (!keys.has('hidden-hand') || !keys.has('public-equip')) {
      throw new QaScenarioError(`${plan.id} must expose the hand/equip selection contract`);
    }
  }
  if (plan.trigger === 'damage-exchange') {
    for (const key of ['actor-slash-1', 'actor-slash-2', 'actor-slash-3', 'actor-gift',
      'target-dodge', 'target-counter', 'target-loot']) {
      if (!keys.has(key)) throw new QaScenarioError(`${plan.id} must reserve ${key} for the four attacks`);
    }
  }
  if (plan.trigger === 'hidden-active' || plan.trigger === 'hidden-active-main') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'zhiheng-card' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Slash for Chế Hành`);
    }
  }
  if (plan.trigger === 'hidden-jianxiong') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'jianxiong-card' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one opponent Slash for Jianxiong`);
    }
  }
  if (plan.trigger === 'hidden-fankui') {
    if (plan.slots.length !== 2 || plan.slots[0].key !== 'fankui-damage' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash' ||
        plan.slots[1].key !== 'fankui-loot' || plan.slots[1].owner !== 'opponent' ||
        plan.slots[1].area !== 'hand' || !('trueName' in plan.slots[1].match) ||
        plan.slots[1].match.trueName !== 'peach') {
      throw new QaScenarioError(`${plan.id} must reserve opponent Slash and Peach for Phản Quỹ`);
    }
  }
  if (plan.trigger === 'hidden-view-as') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'longdan-card' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'jink') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Jink for Long Đảm`);
    }
  }
  if (plan.trigger === 'hidden-dual') {
    if (plan.slots.length !== 2 || plan.slots[0].key !== 'shuangxiong-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash' ||
        plan.slots[1].key !== 'shuangxiong-discard' || plan.slots[1].owner !== 'opponent' ||
        plan.slots[1].area !== 'hand' || !('trueName' in plan.slots[1].match) ||
        plan.slots[1].match.trueName !== 'jink') {
      throw new QaScenarioError(`${plan.id} must reserve actor Slash and opponent Jink for Song Hùng`);
    }
  }
}

/**
 * Resolve a plan against the real native card registry.
 *
 * The first matching ID for each requirement is reserved in declaration
 * order. The rest of the native pile is shuffled deterministically, so a
 * plan can assert both "the first draw is X" and "the remaining pile is
 * still a complete unique pile".
 */
export function resolveQaScenario(
  plan: QaScenarioPlan,
  cards: readonly QaCardDescriptor[],
): ResolvedQaScenario {
  validatePlan(plan);
  const availableIds = new Set<number>();
  for (const card of cards) {
    if (!Number.isSafeInteger(card.id) || card.id <= 0 || availableIds.has(card.id)) {
      throw new QaScenarioError(`Native card registry contains an invalid/duplicate ID in ${plan.id}`);
    }
    availableIds.add(card.id);
  }

  const reserved = new Set<number>();
  const selected: QaCardDescriptor[] = [];
  const findCard = (requirement: QaCardMatcher, label: string): QaCardDescriptor => {
    const card = cards.find((candidate) => !reserved.has(candidate.id) && matches(candidate, requirement));
    if (!card) throw new QaScenarioError(`QA scenario ${plan.id} cannot resolve ${label}`);
    reserved.add(card.id);
    selected.push(card);
    return card;
  };

  for (let index = 0; index < plan.drawSequence.length; index++) {
    findCard(plan.drawSequence[index], `drawSequence[${index}]`);
  }

  const slotCards: Record<string, number> = {};
  for (const item of plan.slots) {
    const card = selected[item.drawIndex];
    if (!card || !matches(card, item.match)) {
      throw new QaScenarioError(`QA scenario ${plan.id} slot ${item.key} does not match drawIndex ${item.drawIndex}`);
    }
    slotCards[item.key] = card.id;
  }

  const tail = cards.filter((card) => !reserved.has(card.id)).map((card) => card.id);
  return { plan, drawPile: [...selected.map((card) => card.id), ...deterministicShuffle(tail, plan.seed)], slotCards };
}

/** A small structural check used by tests and future CI tooling. */
export function validateQaScenarioCatalog(): void {
  const ids = new Set(QA_SCENARIO_IDS);
  if (ids.size !== QA_SCENARIO_IDS.length || ids.size !== Object.keys(QA_SCENARIOS).length) {
    throw new QaScenarioError('QA scenario catalog IDs are not one-to-one');
  }
  for (const id of QA_SCENARIO_IDS) {
    const plan = QA_SCENARIOS[id];
    if (plan.id !== id) throw new QaScenarioError(`QA scenario key mismatch: ${id}`);
    validatePlan(plan);
  }
}

validateQaScenarioCatalog();
