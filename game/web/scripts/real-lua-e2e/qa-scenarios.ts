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
  | 'hidden-rehide-yiji'
  | 'hidden-rehide-yiji-deputy'
  | 'hidden-jianxiong'
  | 'hidden-jianxiong-deputy'
  | 'hidden-fankui'
  | 'hidden-fankui-deputy'
  | 'hidden-reveal'
  | 'hidden-reveal-deputy'
  | 'hidden-active'
  | 'hidden-active-main'
  | 'ai-trace'
  | 'chooser-trace'
  | 'general-pair-trace'
  | 'general-pair-match-a'
  | 'general-pair-match-b'
  | 'general-pair-match-c'
  | 'general-pair-match-d'
  | 'general-pair-match-mixed-a'
  | 'general-pair-match-mixed-b'
  | 'general-pair-match-mixed-c'
  | 'general-pair-match-mixed-d'
  | 'hidden-fanjian'
  | 'hidden-fanjian-deputy'
  | 'hidden-view-as'
  | 'hidden-view-as-main'
  | 'hidden-dual'
  | 'hidden-luoshen'
  | 'hidden-luoshen-deputy'
  | 'hidden-tiandu'
  | 'hidden-tiandu-deputy'
  | 'hidden-jizhi'
  | 'hidden-jizhi-deputy'
  | 'hidden-mingshi'
  | 'hidden-mingshi-deputy'
  | 'hidden-qianxun'
  | 'hidden-qianxun-deputy'
  | 'hidden-qianxun-indulgence'
  | 'hidden-qianxun-indulgence-deputy'
  | 'hidden-kongcheng'
  | 'hidden-kongcheng-deputy'
  | 'hidden-weimu'
  | 'hidden-weimu-deputy'
  | 'hidden-weimu-indulgence'
  | 'hidden-weimu-indulgence-deputy'
  | 'hidden-xiaoji'
  | 'hidden-xiaoji-deputy'
  | 'hidden-guanxing'
  | 'hidden-guanxing-deputy'
  | 'hidden-yingzi'
  | 'hidden-yingzi-deputy'
  | 'hidden-tianxiang'
  | 'hidden-tianxiang-deputy'
  | 'hidden-duanchang'
  | 'hidden-duanchang-deputy'
  | 'hidden-liegong'
  | 'hidden-liegong-deputy'
  | 'hidden-jueqing'
  | 'hidden-jueqing-deputy'
  | 'hidden-ejue'
  | 'hidden-ejue-deputy'
  | 'hidden-dufu'
  | 'hidden-dufu-deputy'
  | 'hidden-jianzhi'
  | 'hidden-jianzhi-deputy'
  | 'hidden-zhiman'
  | 'hidden-zhiman-deputy'
  | 'hidden-jilix'
  | 'hidden-jilix-deputy'
  | 'hidden-kuanggu'
  | 'hidden-kuanggu-deputy'
  | 'hidden-gongqing'
  | 'hidden-gongqing-deputy'
  | 'hidden-enyuan'
  | 'hidden-enyuan-deputy'
  | 'hidden-fuyin'
  | 'hidden-fuyin-deputy';

export type QaCardMatcher =
  | { trueName: string; color?: 'red' | 'black' }
  | { name: string }
  | { type: 'equip' }
  | { suit: string };

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
  | 'hidden-rehide-yiji'
  | 'hidden-jianxiong'
  | 'hidden-fankui'
  | 'hidden-reveal'
  | 'hidden-active'
  | 'ai-trace'
  | 'chooser-trace'
  | 'general-pair-trace'
  | 'general-pair-match'
  | 'hidden-fanjian'
  | 'hidden-view-as'
  | 'hidden-dual'
  | 'hidden-luoshen'
  | 'hidden-tiandu'
  | 'hidden-jizhi'
  | 'hidden-mingshi'
  | 'hidden-qianxun'
  | 'hidden-kongcheng'
  | 'hidden-weimu'
  | 'hidden-xiaoji'
  | 'hidden-guanxing'
  | 'hidden-tianxiang'
  | 'hidden-yingzi'
  | 'hidden-duanchang'
  | 'hidden-liegong'
  | 'hidden-kuanggu'
  | 'hidden-jueqing'
  | 'hidden-ejue'
  | 'hidden-dufu'
  | 'hidden-jianzhi'
  | 'hidden-zhiman'
  | 'hidden-jilix'
  | 'hidden-gongqing'
  | 'hidden-enyuan'
  | 'hidden-fuyin';

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
  color: string;
  suit?: string;
  /** The fixture normalizes the native enum to keep this module package-agnostic. */
  type: string;
}

export interface ResolvedQaScenario {
  plan: QaScenarioPlan;
  drawPile: number[];
  slotCards: Record<string, number>;
}

const trueName = (value: string, color?: 'red' | 'black'): QaCardMatcher => ({ trueName: value, color });
const named = (value: string): QaCardMatcher => ({ name: value });
const equip = (): QaCardMatcher => ({ type: 'equip' });
const suit = (value: string): QaCardMatcher => ({ suit: value });

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
  'hidden-rehide-yiji': {
    version: 1,
    id: 'hidden-rehide-yiji',
    title: 'Quách Gia úp lại sau Di Kế: fake skill vẫn giữ prelight',
    seed: 0x5d6e7fb0,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-rehide-yiji',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-rehide-yiji-deputy': {
    version: 1,
    id: 'hidden-rehide-yiji-deputy',
    title: 'Quách Gia phó tướng úp lại sau Di Kế: fake skill vẫn giữ prelight',
    seed: 0x5d6e7fb1,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-rehide-yiji',
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
  'ai-trace': {
    version: 1,
    id: 'ai-trace',
    title: 'Bốn ghế cố định để đối chiếu quyết định SmartAI và fallback',
    seed: 0x6a1f0e22,
    drawSequence: [],
    slots: [],
    trigger: 'ai-trace',
    expectedCommand: 'PlayCard',
  },
  'chooser-trace': {
    version: 1,
    id: 'chooser-trace',
    title: 'Đối chiếu native ba generic chooser với hand và request-state cố định',
    seed: 0x6a1f0e24,
    drawSequence: [],
    slots: [],
    trigger: 'chooser-trace',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'general-pair-trace': {
    version: 1,
    id: 'general-pair-trace',
    title: 'Bốn ghế cố định để đối chiếu lựa chọn cặp chủ/phó và fallback',
    seed: 0x6a1f0e23,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-trace',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-a': {
    version: 1,
    id: 'general-pair-match-a',
    title: 'Bốn ghế BOT chơi trọn ván với hoán vị roster A',
    seed: 0x6a1f0e24,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-b': {
    version: 1,
    id: 'general-pair-match-b',
    title: 'Bốn ghế BOT chơi trọn ván với hoán vị roster B',
    seed: 0x6a1f0e25,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-c': {
    version: 1,
    id: 'general-pair-match-c',
    title: 'Bốn ghế BOT chơi trọn ván với hoán vị roster C',
    seed: 0x6a1f0e26,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-d': {
    version: 1,
    id: 'general-pair-match-d',
    title: 'Bốn ghế BOT chơi trọn ván với hoán vị roster D',
    seed: 0x6a1f0e27,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-mixed-a': {
    version: 1,
    id: 'general-pair-match-mixed-a',
    title: 'Bốn ghế BOT chơi trọn ván đa phe với hoán vị roster A',
    seed: 0x6a1f0e28,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-mixed-b': {
    version: 1,
    id: 'general-pair-match-mixed-b',
    title: 'Bốn ghế BOT chơi trọn ván đa phe với hoán vị roster B',
    seed: 0x6a1f0e29,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-mixed-c': {
    version: 1,
    id: 'general-pair-match-mixed-c',
    title: 'Bốn ghế BOT chơi trọn ván đa phe với hoán vị roster C',
    seed: 0x6a1f0e2a,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'general-pair-match-mixed-d': {
    version: 1,
    id: 'general-pair-match-mixed-d',
    title: 'Bốn ghế BOT chơi trọn ván đa phe với hoán vị roster D',
    seed: 0x6a1f0e2b,
    drawSequence: [],
    slots: [],
    trigger: 'general-pair-match',
    expectedCommand: 'CustomDialog',
  },
  'hidden-fanjian': {
    version: 1,
    id: 'hidden-fanjian',
    title: 'Chu Du úp: Phản Gián mở đúng slot trước khi dùng PlayCard',
    seed: 0x5d6e7fb4,
    drawSequence: [trueName('peach'), trueName('jink')],
    slots: [
      slot('fanjian-card', trueName('peach'), 'self', 'hand', true, 0),
      slot('fanjian-target-card', trueName('jink'), 'opponent', 'hand', false, 1),
    ],
    trigger: 'hidden-fanjian',
    expectedCommand: 'PlayCard',
  },
  'hidden-fanjian-deputy': {
    version: 1,
    id: 'hidden-fanjian-deputy',
    title: 'Chu Du phó tướng úp: Phản Gián mở đúng slot trước khi dùng PlayCard',
    seed: 0x5d6e7fb5,
    drawSequence: [trueName('peach'), trueName('jink')],
    slots: [
      slot('fanjian-card', trueName('peach'), 'self', 'hand', true, 0),
      slot('fanjian-target-card', trueName('jink'), 'opponent', 'hand', false, 1),
    ],
    trigger: 'hidden-fanjian',
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
  'hidden-luoshen': {
    version: 1,
    id: 'hidden-luoshen',
    title: '甄姬 úp: prelight 洛神 ở đầu pha và nhận lá phán xét đen',
    seed: 0x5d6e7f98,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-luoshen',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-luoshen-deputy': {
    version: 1,
    id: 'hidden-luoshen-deputy',
    title: '甄姬 phó tướng úp: prelight 洛神 ở đầu pha và nhận lá phán xét đen',
    seed: 0x5d6e7f99,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-luoshen',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-tiandu': {
    version: 1,
    id: 'hidden-tiandu',
    title: 'Quách Gia úp: Thiên Đố mở đúng slot trước khi lấy lá phán xét',
    seed: 0x5d6e7fb6,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-tiandu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-tiandu-deputy': {
    version: 1,
    id: 'hidden-tiandu-deputy',
    title: 'Quách Gia phó tướng úp: Thiên Đố mở phó tướng trước khi lấy lá phán xét',
    seed: 0x5d6e7fb7,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-tiandu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jizhi': {
    version: 1,
    id: 'hidden-jizhi',
    title: 'Hoàng Nguyệt Anh úp: Tập Trí mở tướng trước CardUsing',
    seed: 0x5d6e7f9a,
    drawSequence: [trueName('duel')],
    slots: [slot('jizhi-card', trueName('duel'), 'self', 'hand', true, 0)],
    trigger: 'hidden-jizhi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jizhi-deputy': {
    version: 1,
    id: 'hidden-jizhi-deputy',
    title: 'Hoàng Nguyệt Anh phó tướng úp: Tập Trí mở tướng trước CardUsing',
    seed: 0x5d6e7f9b,
    drawSequence: [trueName('duel')],
    slots: [slot('jizhi-card', trueName('duel'), 'self', 'hand', true, 0)],
    trigger: 'hidden-jizhi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-mingshi': {
    version: 1,
    id: 'hidden-mingshi',
    title: 'Khổng Dung úp: Danh Sĩ giảm sát thương từ nguồn úp',
    seed: 0x5d6e7f9c,
    drawSequence: [trueName('slash')],
    slots: [slot('mingshi-damage', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-mingshi',
    expectedCommand: 'PlayCard',
  },
  'hidden-mingshi-deputy': {
    version: 1,
    id: 'hidden-mingshi-deputy',
    title: 'Khổng Dung phó tướng úp: Danh Sĩ giảm sát thương từ nguồn úp',
    seed: 0x5d6e7f9d,
    drawSequence: [trueName('slash')],
    slots: [slot('mingshi-damage', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-mingshi',
    expectedCommand: 'PlayCard',
  },
  'hidden-qianxun': {
    version: 1,
    id: 'hidden-qianxun',
    title: 'Lục Tốn úp: Khiêm Tốn hủy mục tiêu Thuận Thủ',
    seed: 0x5d6e7f9e,
    drawSequence: [trueName('snatch'), trueName('peach')],
    slots: [
      slot('qianxun-snatch', trueName('snatch'), 'opponent', 'hand', true, 0),
      slot('qianxun-victim', trueName('peach'), 'self', 'hand', true, 1),
    ],
    trigger: 'hidden-qianxun',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-qianxun-deputy': {
    version: 1,
    id: 'hidden-qianxun-deputy',
    title: 'Lục Tốn phó tướng úp: Khiêm Tốn hủy mục tiêu Thuận Thủ',
    seed: 0x5d6e7f9f,
    drawSequence: [trueName('snatch'), trueName('peach')],
    slots: [
      slot('qianxun-snatch', trueName('snatch'), 'opponent', 'hand', true, 0),
      slot('qianxun-victim', trueName('peach'), 'self', 'hand', true, 1),
    ],
    trigger: 'hidden-qianxun',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-qianxun-indulgence': {
    version: 1,
    id: 'hidden-qianxun-indulgence',
    title: 'Lục Tốn úp: Khiêm Tốn chặn Lạc Bất Tư Thục vào vùng phán xét',
    seed: 0x5d6e7fa0,
    drawSequence: [trueName('indulgence')],
    slots: [slot('qianxun-indulgence', trueName('indulgence'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-qianxun',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-qianxun-indulgence-deputy': {
    version: 1,
    id: 'hidden-qianxun-indulgence-deputy',
    title: 'Lục Tốn phó tướng úp: Khiêm Tốn chặn Lạc Bất Tư Thục vào vùng phán xét',
    seed: 0x5d6e7fa1,
    drawSequence: [trueName('indulgence')],
    slots: [slot('qianxun-indulgence', trueName('indulgence'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-qianxun',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-kongcheng': {
    version: 1,
    id: 'hidden-kongcheng',
    title: 'Gia Cát Lượng úp và hết bài: Không Thành hủy mục tiêu Quyết Đấu',
    seed: 0x5d6e7fa2,
    drawSequence: [trueName('duel')],
    slots: [slot('kongcheng-duel', trueName('duel'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-kongcheng',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-kongcheng-deputy': {
    version: 1,
    id: 'hidden-kongcheng-deputy',
    title: 'Gia Cát Lượng phó tướng úp và hết bài: Không Thành hủy mục tiêu Quyết Đấu',
    seed: 0x5d6e7fa3,
    drawSequence: [trueName('duel')],
    slots: [slot('kongcheng-duel', trueName('duel'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-kongcheng',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-weimu': {
    version: 1,
    id: 'hidden-weimu',
    title: 'Giả Hủ úp cùng Bàng Đức: 帷幕 hủy mục tiêu Quyết Đấu đen',
    seed: 0x5d6e7fa4,
    drawSequence: [trueName('duel', 'black')],
    slots: [slot('weimu-duel', trueName('duel', 'black'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-weimu',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-weimu-deputy': {
    version: 1,
    id: 'hidden-weimu-deputy',
    title: 'Giả Hủ phó tướng úp cùng Bàng Đức: 帷幕 hủy mục tiêu Quyết Đấu đen',
    seed: 0x5d6e7fa5,
    drawSequence: [trueName('duel', 'black')],
    slots: [slot('weimu-duel', trueName('duel', 'black'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-weimu',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-weimu-indulgence': {
    version: 1,
    id: 'hidden-weimu-indulgence',
    title: 'Giả Hủ úp cùng Bàng Đức: 帷幕 chặn Lạc Bất Tư Thục đen vào phán xét',
    seed: 0x5d6e7fa6,
    drawSequence: [trueName('indulgence', 'black')],
    slots: [slot('weimu-indulgence', trueName('indulgence', 'black'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-weimu',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-weimu-indulgence-deputy': {
    version: 1,
    id: 'hidden-weimu-indulgence-deputy',
    title: 'Giả Hủ phó tướng úp cùng Bàng Đức: 帷幕 chặn Lạc Bất Tư Thục đen vào phán xét',
    seed: 0x5d6e7fa7,
    drawSequence: [trueName('indulgence', 'black')],
    slots: [slot('weimu-indulgence', trueName('indulgence', 'black'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-weimu',
    expectedCommand: 'AskForUseActiveSkill',
  },
  'hidden-xiaoji': {
    version: 1,
    id: 'hidden-xiaoji',
    title: 'Tôn Thượng Hương úp: Kiêu Cơ bốc bài sau khi mất trang bị',
    seed: 0x5d6e7fa8,
    drawSequence: [equip()],
    slots: [slot('xiaoji-equip', equip(), 'self', 'equip', true, 0)],
    trigger: 'hidden-xiaoji',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-xiaoji-deputy': {
    version: 1,
    id: 'hidden-xiaoji-deputy',
    title: 'Tôn Thượng Hương phó tướng úp: Kiêu Cơ bốc bài sau khi mất trang bị',
    seed: 0x5d6e7fa9,
    drawSequence: [equip()],
    slots: [slot('xiaoji-equip', equip(), 'self', 'equip', true, 0)],
    trigger: 'hidden-xiaoji',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-guanxing': {
    version: 1,
    id: 'hidden-guanxing',
    title: '诸葛亮 úp: Quan Tinh mở đúng slot trước khi sắp xếp bài',
    seed: 0x5d6e7faa,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-guanxing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-guanxing-deputy': {
    version: 1,
    id: 'hidden-guanxing-deputy',
    title: '诸葛亮 phó tướng úp: Quan Tinh mở đúng slot trước khi sắp xếp bài',
    seed: 0x5d6e7fab,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-guanxing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-yingzi': {
    version: 1,
    id: 'hidden-yingzi',
    title: '周瑜 úp: Anh Tư tăng số bài của DrawNCards native',
    seed: 0x5d6e7fb2,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-yingzi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-yingzi-deputy': {
    version: 1,
    id: 'hidden-yingzi-deputy',
    title: '周瑜 phó tướng úp: Anh Tư tăng số bài của DrawNCards native',
    seed: 0x5d6e7fb3,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-yingzi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-tianxiang': {
    version: 1,
    id: 'hidden-tianxiang',
    title: '小乔 úp: Thiên Hương chuyển sát thương sau khi chọn bài tim',
    seed: 0x5d6e7fac,
    drawSequence: [suit('heart')],
    slots: [slot('tianxiang-heart', suit('heart'), 'self', 'hand', true, 0)],
    trigger: 'hidden-tianxiang',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-tianxiang-deputy': {
    version: 1,
    id: 'hidden-tianxiang-deputy',
    title: '小乔 phó tướng úp: Thiên Hương chuyển sát thương sau khi chọn bài tim',
    seed: 0x5d6e7fad,
    drawSequence: [suit('heart')],
    slots: [slot('tianxiang-heart', suit('heart'), 'self', 'hand', true, 0)],
    trigger: 'hidden-tianxiang',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-duanchang': {
    version: 1,
    id: 'hidden-duanchang',
    title: '蔡文姬 úp: Đoạn Trường kích hoạt khi chết và tước kỹ năng chủ tướng của killer',
    seed: 0x5d6e7fae,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-duanchang',
    expectedCommand: 'AskForChoices',
  },
  'hidden-duanchang-deputy': {
    version: 1,
    id: 'hidden-duanchang-deputy',
    title: '蔡文姬 phó tướng úp: Đoạn Trường kích hoạt khi chết và tước kỹ năng chủ tướng của killer',
    seed: 0x5d6e7faf,
    drawSequence: [],
    slots: [],
    trigger: 'hidden-duanchang',
    expectedCommand: 'AskForChoices',
  },
  'hidden-liegong': {
    version: 1,
    id: 'hidden-liegong',
    title: '黄忠 úp: Liệt Cung mở tướng trước lựa chọn tăng sát thương',
    seed: 0x5d6e7fb4,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      { key: 'liegong-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'liegong-target-card', match: { trueName: 'peach' }, drawIndex: 1, owner: 'opponent', area: 'hand', visible: true },
    ],
    trigger: 'hidden-liegong',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-liegong-deputy': {
    version: 1,
    id: 'hidden-liegong-deputy',
    title: '黄忠 phó tướng úp: Liệt Cung mở tướng trước lựa chọn tăng sát thương',
    seed: 0x5d6e7fb5,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      { key: 'liegong-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'liegong-target-card', match: { trueName: 'peach' }, drawIndex: 1, owner: 'opponent', area: 'hand', visible: true },
    ],
    trigger: 'hidden-liegong',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-kuanggu': {
    version: 1,
    id: 'hidden-kuanggu',
    title: '魏延 úp: Cuồng Cốt mở tướng trước lựa chọn sau sát thương',
    seed: 0x5d6e7fb8,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      { key: 'kuanggu-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'kuanggu-target-card', match: { trueName: 'peach' }, drawIndex: 1, owner: 'opponent', area: 'hand', visible: true },
    ],
    trigger: 'hidden-kuanggu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-kuanggu-deputy': {
    version: 1,
    id: 'hidden-kuanggu-deputy',
    title: '魏延 phó tướng úp: Cuồng Cốt mở tướng trước lựa chọn sau sát thương',
    seed: 0x5d6e7fb9,
    drawSequence: [trueName('slash'), trueName('peach')],
    slots: [
      { key: 'kuanggu-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'kuanggu-target-card', match: { trueName: 'peach' }, drawIndex: 1, owner: 'opponent', area: 'hand', visible: true },
    ],
    trigger: 'hidden-kuanggu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jueqing': {
    version: 1,
    id: 'hidden-jueqing',
    title: '张春华 úp: Tuyệt Tình chuyển PreDamage thành mất máu',
    seed: 0x5d6e7fbe,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'jueqing-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-jueqing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jueqing-deputy': {
    version: 1,
    id: 'hidden-jueqing-deputy',
    title: '张春华 phó tướng úp: Tuyệt Tình chuyển PreDamage thành mất máu',
    seed: 0x5d6e7fbf,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'jueqing-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-jueqing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-ejue': {
    version: 1,
    id: 'hidden-ejue',
    title: '张春华 úp: Ách Tuyệt tăng sát thương lên thế lực chưa xác định',
    seed: 0x5d6e7fc0,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'ejue-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-ejue',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-ejue-deputy': {
    version: 1,
    id: 'hidden-ejue-deputy',
    title: '张春华 phó tướng úp: Ách Tuyệt tăng sát thương lên thế lực chưa xác định',
    seed: 0x5d6e7fc1,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'ejue-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-ejue',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-dufu': {
    version: 1,
    id: 'hidden-dufu',
    title: '司马冏 úp: Độc Phu tăng sát thương khi không có đồng minh cùng thế lực',
    seed: 0x5d6e7fc4,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'dufu-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-dufu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-dufu-deputy': {
    version: 1,
    id: 'hidden-dufu-deputy',
    title: '司马冏 phó tướng úp: Độc Phu tăng sát thương khi không có đồng minh cùng thế lực',
    seed: 0x5d6e7fc5,
    drawSequence: [trueName('slash')],
    slots: [{ key: 'dufu-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true }],
    trigger: 'hidden-dufu',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jianzhi': {
    version: 1,
    id: 'hidden-jianzhi',
    title: '贾充 úp: Gian Chí bỏ bài khi gây sát thương chí mạng',
    seed: 0x5d6e7fc6,
    drawSequence: [trueName('slash'), trueName('jink')],
    slots: [
      { key: 'jianzhi-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'jianzhi-filler', match: { trueName: 'jink' }, drawIndex: 1, owner: 'self', area: 'hand', visible: true },
    ],
    trigger: 'hidden-jianzhi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jianzhi-deputy': {
    version: 1,
    id: 'hidden-jianzhi-deputy',
    title: '贾充 phó tướng úp: Gian Chí bỏ bài khi gây sát thương chí mạng',
    seed: 0x5d6e7fc7,
    drawSequence: [trueName('slash'), trueName('jink')],
    slots: [
      { key: 'jianzhi-card', match: { trueName: 'slash' }, drawIndex: 0, owner: 'self', area: 'hand', visible: true },
      { key: 'jianzhi-filler', match: { trueName: 'jink' }, drawIndex: 1, owner: 'self', area: 'hand', visible: true },
    ],
    trigger: 'hidden-jianzhi',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-zhiman': {
    version: 1,
    id: 'hidden-zhiman',
    title: '马谡 úp: Chế Man chặn sát thương và lấy trang bị',
    seed: 0x5d6e7fc8,
    drawSequence: [trueName('slash'), equip()],
    slots: [
      slot('zhiman-card', trueName('slash'), 'self', 'hand', true, 0),
      slot('zhiman-equip', equip(), 'opponent', 'equip', true, 1),
    ],
    trigger: 'hidden-zhiman',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-zhiman-deputy': {
    version: 1,
    id: 'hidden-zhiman-deputy',
    title: '马谡 phó tướng úp: Chế Man chặn sát thương và lấy trang bị',
    seed: 0x5d6e7fc9,
    drawSequence: [trueName('slash'), equip()],
    slots: [
      slot('zhiman-card', trueName('slash'), 'self', 'hand', true, 0),
      slot('zhiman-equip', equip(), 'opponent', 'equip', true, 1),
    ],
    trigger: 'hidden-zhiman',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-jilix': {
    version: 1,
    id: 'hidden-jilix',
    title: '严白虎 úp: Ký Ly lặp Sát đỏ rồi ngăn sát thương lần hai',
    seed: 0x5d6e7fca,
    drawSequence: [trueName('slash', 'red')],
    slots: [slot('jilix-slash', trueName('slash', 'red'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-jilix',
    expectedCommand: 'PlayCard',
  },
  'hidden-jilix-deputy': {
    version: 1,
    id: 'hidden-jilix-deputy',
    title: '严白虎 phó tướng úp: Ký Ly lặp Sát đỏ rồi ngăn sát thương lần hai',
    seed: 0x5d6e7fcb,
    drawSequence: [trueName('slash', 'red')],
    slots: [slot('jilix-slash', trueName('slash', 'red'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-jilix',
    expectedCommand: 'PlayCard',
  },
  'hidden-gongqing': {
    version: 1,
    id: 'hidden-gongqing',
    title: '潘濬 úp: Công Thanh kiểm tra cả hai nhánh tầm đánh',
    seed: 0x5d6e7fba,
    drawSequence: [named('kylin_bow')],
    slots: [{ key: 'gongqing-bow', match: { name: 'kylin_bow' }, drawIndex: 0, owner: 'opponent', area: 'hand', visible: true }],
    trigger: 'hidden-gongqing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-gongqing-deputy': {
    version: 1,
    id: 'hidden-gongqing-deputy',
    title: '潘濬 phó tướng úp: Công Thanh kiểm tra cả hai nhánh tầm đánh',
    seed: 0x5d6e7fbb,
    drawSequence: [named('kylin_bow')],
    slots: [{ key: 'gongqing-bow', match: { name: 'kylin_bow' }, drawIndex: 0, owner: 'opponent', area: 'hand', visible: true }],
    trigger: 'hidden-gongqing',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-enyuan': {
    version: 1,
    id: 'hidden-enyuan',
    title: 'Pháp Chính úp: Ân Oán mở tướng trước TargetConfirmed và rút Đào',
    seed: 0x5d6e7fc0,
    drawSequence: [trueName('peach')],
    slots: [slot('enyuan-peach', trueName('peach'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-enyuan',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-enyuan-deputy': {
    version: 1,
    id: 'hidden-enyuan-deputy',
    title: 'Pháp Chính phó tướng úp: Ân Oán mở tướng trước TargetConfirmed và rút Đào',
    seed: 0x5d6e7fc1,
    drawSequence: [trueName('peach')],
    slots: [slot('enyuan-peach', trueName('peach'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-enyuan',
    expectedCommand: 'AskForSkillInvoke',
  },
  'hidden-fuyin': {
    version: 1,
    id: 'hidden-fuyin',
    title: 'Gia Cát Chiêm úp: Phụ Âm mở tướng trước TargetConfirmed và vô hiệu Sát',
    seed: 0x5d6e7fc2,
    drawSequence: [trueName('slash')],
    slots: [slot('fuyin-slash', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-fuyin',
    expectedCommand: 'PlayCard',
  },
  'hidden-fuyin-deputy': {
    version: 1,
    id: 'hidden-fuyin-deputy',
    title: 'Gia Cát Chiêm phó tướng úp: Phụ Âm mở tướng trước TargetConfirmed và vô hiệu Sát',
    seed: 0x5d6e7fc3,
    drawSequence: [trueName('slash')],
    slots: [slot('fuyin-slash', trueName('slash'), 'opponent', 'hand', true, 0)],
    trigger: 'hidden-fuyin',
    expectedCommand: 'PlayCard',
  },
};

export const QA_SCENARIO_IDS: readonly QaScenarioId[] = [
  'draw-sequence', 'card-chosen', 'poxi', 'cards-and-choice',
  'rescue-normal', 'rescue-battle', 'founding', 'fazheng-enyuan',
  'hidden-yiji', 'hidden-jianxiong', 'hidden-reveal', 'hidden-active',
  'hidden-yiji-deputy', 'hidden-jianxiong-deputy', 'hidden-reveal-deputy', 'hidden-active-main', 'ai-trace', 'chooser-trace', 'general-pair-trace',
  'general-pair-match-a', 'general-pair-match-b', 'general-pair-match-c', 'general-pair-match-d',
  'general-pair-match-mixed-a', 'general-pair-match-mixed-b', 'general-pair-match-mixed-c', 'general-pair-match-mixed-d',
  'hidden-fanjian', 'hidden-fanjian-deputy',
  'hidden-rehide-yiji', 'hidden-rehide-yiji-deputy',
  'hidden-fankui', 'hidden-fankui-deputy',
  'hidden-view-as', 'hidden-view-as-main',
  'hidden-dual', 'hidden-luoshen', 'hidden-luoshen-deputy',
  'hidden-tiandu', 'hidden-tiandu-deputy',
  'hidden-jizhi', 'hidden-jizhi-deputy',
  'hidden-mingshi', 'hidden-mingshi-deputy',
  'hidden-qianxun', 'hidden-qianxun-deputy',
  'hidden-qianxun-indulgence', 'hidden-qianxun-indulgence-deputy',
  'hidden-kongcheng', 'hidden-kongcheng-deputy',
  'hidden-weimu', 'hidden-weimu-deputy',
  'hidden-weimu-indulgence', 'hidden-weimu-indulgence-deputy',
  'hidden-xiaoji', 'hidden-xiaoji-deputy',
  'hidden-guanxing', 'hidden-guanxing-deputy',
  'hidden-yingzi', 'hidden-yingzi-deputy',
  'hidden-tianxiang', 'hidden-tianxiang-deputy',
  'hidden-duanchang', 'hidden-duanchang-deputy',
  'hidden-liegong', 'hidden-liegong-deputy',
  'hidden-kuanggu', 'hidden-kuanggu-deputy',
  'hidden-jueqing', 'hidden-jueqing-deputy',
  'hidden-ejue', 'hidden-ejue-deputy',
  'hidden-dufu', 'hidden-dufu-deputy',
  'hidden-jianzhi', 'hidden-jianzhi-deputy',
  'hidden-zhiman', 'hidden-zhiman-deputy',
  'hidden-jilix', 'hidden-jilix-deputy',
  'hidden-gongqing', 'hidden-gongqing-deputy',
  'hidden-enyuan', 'hidden-enyuan-deputy',
  'hidden-fuyin', 'hidden-fuyin-deputy',
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
  if ('trueName' in requirement) {
    return card.trueName === requirement.trueName &&
      (requirement.color === undefined || card.color === requirement.color);
  }
  if ('name' in requirement) return card.name === requirement.name;
  if ('suit' in requirement) return card.suit === requirement.suit;
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
  if (plan.trigger === 'hidden-active') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'zhiheng-card' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Slash for Chế Hành`);
    }
  }
  if (plan.trigger === 'hidden-fanjian') {
    if (plan.slots.length !== 2 || plan.slots[0].key !== 'fanjian-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'peach' ||
        plan.slots[1].key !== 'fanjian-target-card' || plan.slots[1].owner !== 'opponent' ||
        plan.slots[1].area !== 'hand' || !('trueName' in plan.slots[1].match) ||
        plan.slots[1].match.trueName !== 'jink') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Peach and one hidden target Jink for Phản Gián`);
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
  if (plan.trigger === 'hidden-jizhi') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'jizhi-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'duel') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Duel for Tập Trí`);
    }
  }
  if (plan.trigger === 'hidden-mingshi') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'mingshi-damage' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one hidden-source Slash for Danh Sĩ`);
    }
  }
  if (plan.trigger === 'hidden-qianxun') {
    if (plan.id === 'hidden-qianxun-indulgence' || plan.id === 'hidden-qianxun-indulgence-deputy') {
      if (plan.slots.length !== 1 || plan.slots[0].key !== 'qianxun-indulgence' ||
          plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
          !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'indulgence') {
        throw new QaScenarioError(`${plan.id} must reserve one opponent Indulgence for Khiêm Tốn`);
      }
    } else if (plan.slots.length !== 2 || plan.slots[0].key !== 'qianxun-snatch' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'snatch' ||
        plan.slots[1].key !== 'qianxun-victim' || plan.slots[1].owner !== 'self' ||
        plan.slots[1].area !== 'hand' || !('trueName' in plan.slots[1].match) ||
        plan.slots[1].match.trueName !== 'peach') {
      throw new QaScenarioError(`${plan.id} must reserve an opponent Snatch and actor Peach for Khiêm Tốn`);
    }
  }
  if (plan.trigger === 'hidden-kongcheng') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'kongcheng-duel' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'duel') {
      throw new QaScenarioError(`${plan.id} must reserve one opponent Duel for Không Thành`);
    }
  }
  if (plan.trigger === 'hidden-weimu') {
    const indulgenceScenario = plan.id === 'hidden-weimu-indulgence' ||
      plan.id === 'hidden-weimu-indulgence-deputy';
    const expectedKey = indulgenceScenario ? 'weimu-indulgence' : 'weimu-duel';
    const expectedTrueName = indulgenceScenario ? 'indulgence' : 'duel';
    if (plan.slots.length !== 1 || plan.slots[0].key !== expectedKey ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== expectedTrueName ||
        plan.slots[0].match.color !== 'black') {
      throw new QaScenarioError(`${plan.id} must reserve one black opponent ${indulgenceScenario ? 'Indulgence' : 'Duel'} for 帷幕`);
    }
  }
  if (plan.trigger === 'hidden-xiaoji') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'xiaoji-equip' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'equip' ||
        !('type' in plan.slots[0].match) || plan.slots[0].match.type !== 'equip') {
      throw new QaScenarioError(`${plan.id} must reserve one actor equipment for 枭姬`);
    }
  }
  if (plan.trigger === 'hidden-guanxing' && plan.slots.length !== 0) {
    throw new QaScenarioError(`${plan.id} must not reserve cards; native 观星 owns the top-card selection`);
  }
  if (plan.trigger === 'hidden-yingzi' && plan.slots.length !== 0) {
    throw new QaScenarioError(`${plan.id} must not reserve cards; native 英姿 owns the DrawNCards count`);
  }
  if (plan.trigger === 'hidden-tianxiang') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'tianxiang-heart' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('suit' in plan.slots[0].match) || plan.slots[0].match.suit !== 'heart') {
      throw new QaScenarioError(`${plan.id} must reserve one actor heart hand card for 天香`);
    }
  }
  if (plan.trigger === 'hidden-duanchang' && plan.slots.length !== 0) {
    throw new QaScenarioError(`${plan.id} must not reserve cards; native 断肠 owns the death/choice path`);
  }
  if (plan.trigger === 'hidden-kuanggu') {
    if (plan.slots.length !== 2 || plan.slots[0].key !== 'kuanggu-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash' ||
        plan.slots[1].key !== 'kuanggu-target-card' || plan.slots[1].owner !== 'opponent' ||
        plan.slots[1].area !== 'hand' || !('trueName' in plan.slots[1].match) ||
        plan.slots[1].match.trueName !== 'peach') {
      throw new QaScenarioError(`${plan.id} must reserve an actor Slash and a target Peach for 狂骨`);
    }
  }
  if (plan.trigger === 'hidden-jueqing') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'jueqing-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Slash for 绝情`);
    }
  }
  if (plan.trigger === 'hidden-ejue') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'ejue-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Slash for 扼绝`);
    }
  }
  if (plan.trigger === 'hidden-dufu') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'dufu-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one actor Slash for 独夫`);
    }
  }
  if (plan.trigger === 'hidden-zhiman') {
    if (plan.slots.length !== 2 || plan.slots[0].key !== 'zhiman-card' ||
        plan.slots[0].owner !== 'self' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash' ||
        plan.slots[1].key !== 'zhiman-equip' || plan.slots[1].owner !== 'opponent' ||
        plan.slots[1].area !== 'equip' || !('type' in plan.slots[1].match) ||
        plan.slots[1].match.type !== 'equip') {
      throw new QaScenarioError(`${plan.id} must reserve an actor Slash and opponent equipment for Chế Man`);
    }
  }
  if (plan.trigger === 'hidden-jilix') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'jilix-slash' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash' ||
        plan.slots[0].match.color !== 'red') {
      throw new QaScenarioError(`${plan.id} must reserve one red opponent Slash for Ký Ly`);
    }
  }
  if (plan.trigger === 'hidden-gongqing') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'gongqing-bow' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('name' in plan.slots[0].match) || plan.slots[0].match.name !== 'kylin_bow') {
      throw new QaScenarioError(`${plan.id} must reserve one opponent Kylin Bow for 公清`);
    }
  }
  if (plan.trigger === 'hidden-enyuan') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'enyuan-peach' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'peach') {
      throw new QaScenarioError(`${plan.id} must reserve one opponent Peach for Ân Oán`);
    }
  }
  if (plan.trigger === 'hidden-fuyin') {
    if (plan.slots.length !== 1 || plan.slots[0].key !== 'fuyin-slash' ||
        plan.slots[0].owner !== 'opponent' || plan.slots[0].area !== 'hand' ||
        !('trueName' in plan.slots[0].match) || plan.slots[0].match.trueName !== 'slash') {
      throw new QaScenarioError(`${plan.id} must reserve one opponent Slash for Phụ Âm`);
    }
  }
  if (plan.trigger === 'hidden-rehide-yiji' && plan.slots.length !== 0) {
    throw new QaScenarioError(`${plan.id} must not reserve cards; native Di Kế owns the reveal/re-hide path`);
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
