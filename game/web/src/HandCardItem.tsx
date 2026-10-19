import { useId, useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import type { CSSProperties, KeyboardEvent as ReactKeyboardEvent, PointerEvent as ReactPointerEvent, ReactNode } from 'react';
import { useDisplayText } from './engine/displayText';
import { objectValue } from './engine/gameplayInteraction';
import type { GameplayItem } from './store/gameplayState';
import { CATALOG_CARD_ART_NAMES, catalogCardArtUrl } from './catalogCardArt';

/** Keep portal tooltips within the viewport even for long translated cards. */
function cardTooltipStyle(rect: DOMRect | null): CSSProperties | undefined {
  if (!rect || typeof window === 'undefined') return undefined;
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;
  const halfWidth = Math.min(130, Math.max(0, (viewportWidth - 16) / 2));
  const x = Math.max(8 + halfWidth, Math.min(viewportWidth - 8 - halfWidth, rect.left + rect.width / 2));
  const above = rect.top >= 104 || viewportHeight - rect.bottom < rect.top;
  const available = above ? rect.top - 16 : viewportHeight - rect.bottom - 16;
  return {
    position: 'fixed',
    left: x,
    top: above ? Math.max(8, rect.top - 8) : Math.min(viewportHeight - 8, rect.bottom + 8),
    transform: above ? 'translate(-50%, -100%)' : 'translateX(-50%)',
    maxHeight: Math.max(40, Math.min(180, available)),
    zIndex: 99999,
    pointerEvents: 'none',
  };
}

export interface CardData {
  name?: string;
  trueName?: string;
  known?: boolean;
  /** FreeKill package that owns the card definition (e.g. gamemode/mobile). */
  extension?: string;
  /** Optional FilterSkill-selected picture name, equivalent to native pic_name. */
  picName?: string;
  suit?: number;
  number?: number;
  /** Public FreeKill TablePile annotations; never supplied for concealed cards. */
  footnote?: string;
  virtName?: string;
}

export interface CardSuitInfo {
  symbol: string;
  name: string;
  colorClass: 'suit-red' | 'suit-black' | 'suit-nosuit';
}

export interface CardCategoryInfo {
  typeKey: 'basic' | 'trick' | 'delayed' | 'equip' | 'unknown';
  label: string;
  className: string;
  badge?: string;
}

/** 1: Spade ♠, 2: Club ♣, 3: Heart ♥, 4: Diamond ♦, 5/other: NoSuit ◇ */
export function getSuitInfo(suit: number | undefined): CardSuitInfo {
  if (suit === 1) return { symbol: '♠', name: 'Bích', colorClass: 'suit-black' };
  if (suit === 2) return { symbol: '♣', name: 'Chuồn', colorClass: 'suit-black' };
  if (suit === 3) return { symbol: '♥', name: 'Cơ', colorClass: 'suit-red' };
  if (suit === 4) return { symbol: '♦', name: 'Rô', colorClass: 'suit-red' };
  return { symbol: '◇', name: 'Không chất', colorClass: 'suit-nosuit' };
}

export function formatRank(number: number | undefined): string {
  if (typeof number !== 'number' || !Number.isInteger(number) || number < 0 || number > 13) return '';
  if (number === 1) return 'A';
  if (number === 11) return 'J';
  if (number === 12) return 'Q';
  if (number === 13) return 'K';
  if (number === 0) return 'X';
  return String(number);
}

/** Static whitelist of standard card classifications */
const BASIC_CARDS = new Set([
  'slash', 'fire_slash', 'fire__slash', 'thunder_slash', 'thunder__slash',
  'jink', 'peach', 'analeptic',
]);

const DELAYED_TRICKS = new Set([
  'indulgence', 'supply_shortage', 'lightning',
]);

const NORMAL_TRICKS = new Set([
  'duel', 'dismantlement', 'snatch', 'ex_nihilo', 'nullification',
  'god_salvation', 'amazing_grace', 'savage_assault', 'archery_attack', 'threaten_emperor',
  'iron_chain', 'collateral', 'fire_attack',
]);

const WEAPONS = new Set([
  'qinggang_sword', 'double_swords', 'blade', 'spear', 'axe', 'halberd',
  'kylin_bow', 'crossbow', 'ice_sword', 'guding_blade', 'fan', 'scaly_wings',
  'triblade', 'dragon_phoenix', 'yangsui_spear', 'serpent_slayer_sword',
]);

const ARMORS = new Set([
  'eight_diagram', 'nioh_shield', 'silver_lion', 'vine', 'breastplate',
  'iron_armor', 'amiantus_robe', 'peace_spell',
]);

const DEFENSIVE_RIDES = new Set([
  'jueying', 'dilu', 'zhuahuangfeidian', 'white_kylin', 'liulongcanjia',
]);

const OFFENSIVE_RIDES = new Set([
  'chitu', 'dayuan', 'zixing', 'jingfan', 'tianlu',
]);

const TREASURES = new Set([
  'wooden_ox', 'role__wooden_ox', 'jade_seal', 'luminous_pearl', 'dunjia_book',
  'nine_tripod_cauldrons', 'turban_shell_cup',
]);

export function getCardCategory(rawName: string | undefined): CardCategoryInfo {
  if (!rawName) return { typeKey: 'unknown', label: '', className: 'type-unknown' };
  const name = rawName.replace(/^.*__/, ''); // strip package prefix
  if (BASIC_CARDS.has(name) || BASIC_CARDS.has(rawName)) {
    return { typeKey: 'basic', label: 'Cơ Bản', className: 'type-basic' };
  }
  if (DELAYED_TRICKS.has(name) || DELAYED_TRICKS.has(rawName)) {
    return { typeKey: 'delayed', label: 'Trì Hoãn', className: 'type-delayed', badge: 'Trì Hoãn' };
  }
  if (NORMAL_TRICKS.has(name) || NORMAL_TRICKS.has(rawName)) {
    return { typeKey: 'trick', label: 'Cẩm Nang', className: 'type-trick', badge: 'Cẩm Nang' };
  }
  if (WEAPONS.has(name) || WEAPONS.has(rawName)) {
    return { typeKey: 'equip', label: 'Vũ Khí', className: 'type-equip', badge: 'Vũ Khí' };
  }
  if (ARMORS.has(name) || ARMORS.has(rawName)) {
    return { typeKey: 'equip', label: 'Phòng Cụ', className: 'type-equip', badge: 'Phòng Cụ' };
  }
  if (DEFENSIVE_RIDES.has(name) || DEFENSIVE_RIDES.has(rawName)) {
    return { typeKey: 'equip', label: 'Tọa Kỵ', className: 'type-equip', badge: '+1 Mã' };
  }
  if (OFFENSIVE_RIDES.has(name) || OFFENSIVE_RIDES.has(rawName)) {
    return { typeKey: 'equip', label: 'Tọa Kỵ', className: 'type-equip', badge: '-1 Mã' };
  }
  if (TREASURES.has(name) || TREASURES.has(rawName)) {
    return { typeKey: 'equip', label: 'Bảo Vật', className: 'type-equip', badge: 'Bảo Vật' };
  }
  return { typeKey: 'unknown', label: '', className: 'type-unknown' };
}

/** Resolve the common FreeKill equip sound subtype used by UseCardEvent. */
export function getCardEquipAudioType(rawName: string | undefined): 'weapon' | 'armor' | 'horse' | null {
  if (!rawName) return null;
  const name = rawName.replace(/^.*__/, '');
  if (WEAPONS.has(name) || WEAPONS.has(rawName)) return 'weapon';
  if (DEFENSIVE_RIDES.has(name) || DEFENSIVE_RIDES.has(rawName) ||
      OFFENSIVE_RIDES.has(name) || OFFENSIVE_RIDES.has(rawName)) return 'horse';
  if (ARMORS.has(name) || ARMORS.has(rawName) || TREASURES.has(name) || TREASURES.has(rawName)) return 'armor';
  return null;
}

/** Baseline standard card descriptions when Lua translation table is deferred */
const BASELINE_DESCRIPTIONS: Record<string, string> = {
  slash: 'Trong giai đoạn ra bài, sử dụng lên một mục tiêu trong phạm vi tấn công. Gây 1 sát thương nếu đối phương không đánh ra 【Thiểm】.',
  fire_slash: 'Gây 1 sát thương hỏa. Có thể kích hoạt sát thương liên hoàn nếu mục tiêu bị Thiết Tỏa Liên Hoàn.',
  thunder_slash: 'Gây 1 sát thương lôi. Bỏ qua Phòng Cụ mây tre (Đằng Giáp) và kích hoạt liên hoàn.',
  jink: 'Đánh ra trong giai đoạn phản hồi để hóa giải một lá 【Sát】 của đối phương.',
  peach: 'Hồi 1 điểm sinh lực trong giai đoạn ra bài, hoặc dùng để cứu một tướng đang hấp hối.',
  analeptic: 'Uống trong giai đoạn ra bài giúp đòn 【Sát】 tiếp theo gây thêm +1 sát thương, hoặc uống khi hấp hối để tự hồi 1 máu.',
  ex_nihilo: 'Sử dụng lên bản thân trong giai đoạn ra bài: Ngay lập tức rút 2 lá bài từ chồng bài rút.',
  snatch: 'Sử dụng lên một người chơi trong cự ly 1: Lấy 1 lá bài bất kỳ trên tay, vùng trang bị hoặc phán xét của mục tiêu.',
  dismantlement: 'Hủy 1 lá bài bất kỳ trên tay, vùng trang bị hoặc vùng phán xét của một người chơi khác.',
  duel: 'Chỉ định 1 người chơi khác quyết đấu: Lần lượt đánh ra 【Sát】. Ai không đánh ra được sẽ chịu 1 sát thương.',
  nullification: 'Vô hiệu hóa hoàn toàn tác dụng của một lá Cẩm Nang đang thi triển lên mục tiêu.',
  god_salvation: 'Hồi 1 máu cho tất cả nhân vật bị thương theo thứ tự lượt.',
  amazing_grace: 'Lật số lá bài bằng số người chơi còn sống, mỗi người lần lượt chọn lấy 1 lá.',
  savage_assault: 'Tất cả người chơi khác phải đánh ra 【Sát】, nếu không sẽ chịu 1 sát thương.',
  archery_attack: 'Tất cả người chơi khác phải đánh ra 【Thiểm】, nếu không sẽ chịu 1 sát thương.',
  iron_chain: 'Chọn tối đa 2 nhân vật để xích hoặc tháo xích, hoặc trùng chú để đổi lá mới.',
  collateral: 'Chỉ định một người chơi có vũ khí dùng 【Sát】 lên mục tiêu bạn chọn, nếu không bạn lấy vũ khí đó.',
  fire_attack: 'Mục tiêu công khai 1 lá bài trên tay; nếu bạn bỏ lá cùng chất thì mục tiêu chịu 1 sát thương Hỏa.',
  threaten_emperor: 'Cẩm nang. Khiến nhân vật thuộc thế lực lớn kết thúc giai đoạn hành động; người đó có thể bỏ 1 lá để nhận 1 lượt bổ sung.',
  lightning: 'Đặt vào vùng phán xét: Đầu lượt phán xét, nếu lật trúng Bích 2..9 thì chịu 3 sát thương sấm sét.',
  indulgence: 'Đặt vào vùng phán xét đối phương: Đầu lượt, nếu phán xét không phải Cơ thì bị bỏ qua giai đoạn Ra Bài.',
  supply_shortage: 'Đặt vào vùng phán xét đối phương: Đầu lượt, nếu phán xét không phải Chuồn thì bị bỏ qua giai đoạn Rút Bài.',

  // Weapons
  crossbow: 'Vũ khí tầm 1. Khóa định: Trong giai đoạn ra bài, không giới hạn số lần dùng 【Sát】.',
  zhuge_crossbow: 'Vũ khí tầm 1. Khóa định: Trong giai đoạn ra bài, không giới hạn số lần dùng 【Sát】.',
  qinggang_sword: 'Vũ khí tầm 2. Khóa định: Khi bạn dùng 【Sát】, bỏ qua hoàn toàn mọi phòng cụ của mục tiêu.',
  double_swords: 'Vũ khí tầm 2. Khi dùng 【Sát】 lên mục tiêu khác giới, họ chọn bỏ 1 lá trên tay hoặc bạn rút 1 lá.',
  blade: 'Vũ khí tầm 3. Khi 【Sát】 bị hóa giải, có thể ngay lập tức dùng thêm 1 lá 【Sát】 khác lên cùng mục tiêu.',
  spear: 'Vũ khí tầm 3. Có thể coi 2 lá bài bất kỳ trên tay như một lá 【Sát】.',
  axe: 'Vũ khí tầm 3. Khi 【Sát】 bị hóa giải, có thể bỏ 2 lá để ép đòn 【Sát】 trúng đích.',
  halberd: 'Vũ khí tầm 4. Nếu 【Sát】 là lá bài duy nhất trên tay, có thể chỉ định tối đa 3 mục tiêu.',
  kylin_bow: 'Vũ khí tầm 5. Khi 【Sát】 gây sát thương, bạn có thể bắn hạ một lá Tọa Kỵ của mục tiêu.',
  ice_sword: 'Vũ khí tầm 2. Khi 【Sát】 trúng mục tiêu, có thể bỏ 2 lá của họ thay vì gây sát thương.',
  guding_blade: 'Vũ khí tầm 2. Khi 【Sát】 gây sát thương lên mục tiêu không có bài trên tay, sát thương tăng thêm 1 điểm.',
  fan: 'Vũ khí tầm 4. Bạn có thể coi một lá 【Sát】 thường như 【Hỏa Sát】.',
  scaly_wings: 'Vũ khí có phạm vi bằng số máu đã mất. Sau khi dùng 【Sát】, những người trong phạm vi không phải mục tiêu không thể sử dụng bài cho đến khi 【Sát】 kết toán.',
  triblade: 'Vũ khí tầm 3. Sau khi gây sát thương bằng 【Sát】, bỏ 1 lá trên tay để gây 1 sát thương cho nhân vật trong cự ly 1.',
  six_swords: 'Vũ khí tầm 2. Khóa định: Khoảng cách từ người khác đến các tướng Ngô +1.',
  dragon_phoenix: 'Vũ khí tầm 2. Khi dùng 【Sát】 gây sát thương, có thể lấy 1 lá trang bị của mục tiêu.',
  yangsui_spear: 'Vũ khí tầm 3, Kỳ Trân. Khóa định: sau khi 【Sát】 gây sát thương, mục tiêu chịu thêm 1 sát thương Hỏa.',
  serpent_slayer_sword: 'Vũ khí tầm 2, Kỳ Trân. Sau khi 【Sát】 gây sát thương, hồi 1 máu; diệt Quân chủ/Dã tâm gia.',

  // Armors
  eight_diagram: 'Phòng cụ: Mỗi khi cần đánh ra 【Thiểm】, bạn có thể phán xét. Nếu bài phán xét màu đỏ, tính như đã ra 【Thiểm】.',
  nioh_shield: 'Phòng cụ: Khóa định: Mọi lá 【Sát】 màu đen sử dụng lên bạn đều hoàn toàn vô hiệu.',
  silver_lion: 'Phòng cụ: Khóa định: Chỉ chịu tối đa 1 sát thương mỗi lần nhận đòn. Khi mất giáp, hồi 1 máu.',
  vine: 'Phòng cụ: Khóa định: Miễn nhiễm Sát thường, Nam Man, Vạn Tiễn; nhưng chịu thêm 1 sát thương khi trúng Hỏa.',
  breastplate: 'Phòng cụ: Khi chịu sát thương dẫn đến hấp hối, có thể bỏ lá này để hồi về 1 máu.',
  iron_armor: 'Phòng cụ: Khóa định: Khi có bài trong vùng phán xét, miễn nhiễm sát thương từ Sát và Cẩm Nang.',
  amiantus_robe: 'Phòng cụ, Kỳ Trân: Miễn nhiễm sát thương thuộc tính; khi bị Sát nhắm tới có thể bỏ 1 bài gây 1 sát thương Hỏa.',

  // Rides
  jueying: 'Tọa kỵ phòng thủ (+1 Mã): Khoảng cách từ tất cả người chơi khác đến bạn tăng thêm 1.',
  dilu: 'Tọa kỵ phòng thủ (+1 Mã): Khoảng cách từ tất cả người chơi khác đến bạn tăng thêm 1.',
  zhuahuangfeidian: 'Tọa kỵ phòng thủ (+1 Mã): Khoảng cách từ tất cả người chơi khác đến bạn tăng thêm 1.',
  white_kylin: 'Tọa kỵ phòng thủ (+2 Mã), Kỳ Trân: Khoảng cách người khác đến bạn +2. Gây 1 Lôi cho tướng nhiều máu hơn.',
  chitu: 'Tọa kỵ tấn công (-1 Mã): Khoảng cách từ bạn đến tất cả người chơi khác giảm đi 1.',
  dayuan: 'Tọa kỵ tấn công (-1 Mã): Khoảng cách từ bạn đến tất cả người chơi khác giảm đi 1.',
  zixing: 'Tọa kỵ tấn công (-1 Mã): Khoảng cách từ bạn đến tất cả người chơi khác giảm đi 1.',
  jingfan: 'Tọa kỵ tấn công (-1 Mã): Khoảng cách từ bạn đến tất cả người chơi khác giảm đi 1.',
  tianlu: 'Tọa kỵ tấn công (-3 Mã), Kỳ Trân: Khoảng cách từ bạn đến người khác -3. Nhận kỹ năng Quân chủ phe mình.',
  liulongcanjia: 'Tọa kỵ đặc biệt: Khoảng cách người khác đến bạn +1; khoảng cách từ bạn đến người khác -1.',
  mobile__liulongcanjia: 'Tọa kỵ đặc biệt: Khoảng cách từ bạn đến tất cả người chơi khác -3.',

  // Treasures
  wooden_ox: 'Bảo vật: Giai đoạn ra bài có thể cất tối đa 5 lá vào Mộc Ngưu và chuyển sang cho người khác.',
  role__wooden_ox: 'Bảo vật: Giai đoạn ra bài có thể cất tối đa 5 lá vào Mộc Ngưu và chuyển sang cho người khác.',
  jade_seal: 'Bảo vật: Khóa định: Coi như có kỹ năng Quân chủ của phe mình. Đầu lượt rút bài được rút thêm 1 lá.',
  luminous_pearl: 'Bảo vật: Khóa định: Nhận hoặc bỏ giới hạn số lần của kỹ năng Chế Hành.',
  peace_spell: 'Phòng cụ, Kỳ Trân: Ngăn sát thương thuộc tính; tăng giới hạn bài trên tay theo số người cùng thế lực.',
  dunjia_book: 'Bảo vật, Kỳ Trân: Trong giai đoạn ra bài, tối đa 2 lần, bạn có thể đổi phó tướng.',
  nine_tripod_cauldrons: 'Bảo vật, Kỳ Trân: Khóa định: Nếu khu trang bị có ít nhất 4 lá Kỳ Trân, phe bạn thắng trận.',
  turban_shell_cup: 'Bảo vật: Có thể dùng lá trên cùng của chồng bài rút như một lá 【Tửu】.',
};

/** Safe Vietnamese names used while the Lua display dictionary is still loading. */
export const BASELINE_NAMES: Record<string, string> = {
  slash: 'Sát',
  fire_slash: 'Hỏa Sát',
  fire__slash: 'Hỏa Sát',
  thunder_slash: 'Lôi Sát',
  thunder__slash: 'Lôi Sát',
  jink: 'Thiểm',
  peach: 'Đào',
  analeptic: 'Rượu',
  ex_nihilo: 'Vô Trung Sinh Hữu',
  snatch: 'Thuận Thủ Khiên Dương',
  dismantlement: 'Quá Hà Đoạt Kiều',
  duel: 'Quyết Đấu',
  nullification: 'Vô Giải Khả Kích',
  god_salvation: 'Đào Viên Kết Nghĩa',
  amazing_grace: 'Ngũ Cốc Phong Đăng',
  savage_assault: 'Nam Man Xâm Nhập',
  archery_attack: 'Vạn Tiễn Tề Phát',
  iron_chain: 'Thiết Tỏa Liên Hoàn',
  collateral: 'Tá Đao Sát Nhân',
  fire_attack: 'Hỏa Công',
  threaten_emperor: 'Hiệp Thiên Tử Dĩ Lệnh Chư Hầu',
  lightning: 'Sấm Sét',
  indulgence: 'Lạc Bất Tư Thục',
  supply_shortage: 'Binh Lương Thốn Đoạn',
  befriend_attacking: 'Viễn Giao Cận Công',
  burning_camps: 'Hỏa Thiêu Liên Doanh',
  fight_together: 'Lục Lực Đồng Tâm',
  part_ways: 'Phân Đạo Dương Tiêu',
  alliance_feast: 'Liên Minh Thịnh Yến',
  threat: 'Hiệp Thiên Tử Dĩ Lệnh Chư Hầu',
  imperial_order: 'Sắc Lệnh',
  drowning: 'Thủy Yêm Thất Quân',
  lure_tiger: 'Điệu Hổ Ly Sơn',
  overbearing: 'Hổ Thị Đam Đam',
  reveal_intention: 'Đồ Cùng Thao Hiện',
  tricky_heist: 'Xảo Thủ Hào Đoạt',
  unworthy_continuation: 'Cẩu Vĩ Tục Điêu',
  rob__jink: 'Lược Thiểm',

  // Weapons
  crossbow: 'Chư Cát Liên Nỗ',
  zhuge_crossbow: 'Chư Cát Liên Nỗ',
  qinggang_sword: 'Thanh Cương Kiếm',
  double_swords: 'Thư Hùng Song Cổ Kiếm',
  blade: 'Thanh Long Yển Nguyệt Đao',
  spear: 'Trượng Bát Xà Mâu',
  axe: 'Quán Thạch Phủ',
  halberd: 'Phương Thiên Họa Kích',
  kylin_bow: 'Kỳ Lân Cung',
  ice_sword: 'Hàn Băng Kiếm',
  guding_blade: 'Cổ Đĩnh Đao',
  fan: 'Chu Tước Phiến',
  scaly_wings: 'Liễm Lân Tiềm Dực',
  triblade: 'Tam Tiêm Lưỡng Nhận Đao',
  six_swords: 'Ngô Lục Kiếm',
  dragon_phoenix: 'Phi Long Đoạt Phượng',
  yangsui_spear: 'Dương Toại Thương',
  serpent_slayer_sword: 'Trảm Xà Kiếm',

  // Armors
  eight_diagram: 'Bát Quái Trận',
  nioh_shield: 'Nhân Vương Thuẫn',
  silver_lion: 'Bạch Ngân Sư Tử',
  vine: 'Đằng Giáp',
  breastplate: 'Hộ Tâm Kính',
  iron_armor: 'Minh Quang Khải',
  amiantus_robe: 'Hỏa Hoán Y',

  // Defensive Rides (+1)
  jueying: 'Tuyệt Ảnh',
  dilu: 'Đích Lô',
  zhuahuangfeidian: 'Trảo Hoàng Phi Điện',
  white_kylin: 'Bạch Kỳ Lân',

  // Offensive Rides (-1)
  chitu: 'Xích Thố',
  dayuan: 'Đại Uyển',
  zixing: 'Tử Tinh',
  jingfan: 'Kinh Phàm',
  tianlu: 'Thiên Lộc',
  liulongcanjia: 'Lục Long Tham Giá',
  mobile__liulongcanjia: 'Lục Long Tham Giá',

  // Treasures
  wooden_ox: 'Mộc Ngưu Lưu Mã',
  role__wooden_ox: 'Mộc Ngưu Lưu Mã',
  jade_seal: 'Ngọc Tỷ',
  luminous_pearl: 'Định Lan Dạ Minh Châu',
  peace_spell: 'Thái Bình Yếu Thuật',
  dunjia_book: 'Độn Giáp Thiên Thư',
  nine_tripod_cauldrons: 'Cửu Châu Đỉnh',
  turban_shell_cup: 'Anh Vũ Bôi',
  rare_treasure: 'Kỳ Trân',
};

const UNKNOWN_CARD_NAME = 'Lá bài chưa xác định';
const UNKNOWN_CARD_DESCRIPTION = 'Chi tiết luật chưa được nạp.';

function cardKeys(card: CardData | undefined): string[] {
  return [...new Set([card?.name, card?.trueName].filter((value): value is string =>
    typeof value === 'string' && value.length > 0))];
}

function baseCardKey(value: string): string {
  return value.replace(/^.*__/, '');
}

/** A translation is usable only when it is not the unresolved wire key itself. */
function translatedValue(key: string, text: (value: string) => string): string | null {
  const value = text(key).trim();
  if (!value || value === key || value.startsWith(':')) return null;
  return value;
}

/** Fixtures and some upstream UI paths already provide a localized face name. */
function safeRawCardName(value: string): string | null {
  return /^[a-z0-9_-]+$/.test(value) ? null : value;
}

/**
 * The native Hegemony dictionary sometimes appends the mode name to a card
 * face (for example, "Vô Giải (Quốc Chiến)").  That suffix identifies the
 * package, not a different card for the player.  Strip it only at the display
 * boundary; card IDs, trueName, wire payloads and art lookup stay untouched.
 */
export function normalizeCardDisplayName(value: string): string {
  return value
    .replace(/\s*\(Quốc Chiến\)\s*$/iu, '')
    .replace(/\s*（国战）\s*$/u, '')
    .trim();
}

/** Resolver for card title and description conforming to user criteria */
export function resolveCardText(
  card: CardData | undefined,
  text: (key: string) => string
): { displayName: string; description: string } {
  const names = cardKeys(card);
  if (!names.length) return { displayName: UNKNOWN_CARD_NAME, description: UNKNOWN_CARD_DESCRIPTION };

  const translatedName = names.map((name) => translatedValue(name, text)).find(Boolean);
  const baselineName = names.map(baseCardKey).map((name) => BASELINE_NAMES[name]).find(Boolean);
  const providedName = names.map(safeRawCardName).find(Boolean);
  const displayName = normalizeCardDisplayName(
    translatedName || baselineName || providedName || UNKNOWN_CARD_NAME,
  );

  // Prefer the current view-as name, then the true card name, then the static baseline.
  const translatedDesc = names
    .map((name) => translatedValue(`:${name}`, text))
    .find(Boolean);
  if (translatedDesc) return { displayName, description: translatedDesc };

  const baseline = names.map(baseCardKey).map((name) => BASELINE_DESCRIPTIONS[name]).find(Boolean);
  return {
    displayName,
    description: baseline || UNKNOWN_CARD_DESCRIPTION,
  };
}

/**
 * Exact FreeKill package/name -> asset paths.
 *
 * These entries intentionally use the card's real definition name.  A
 * generic name such as `slash` or `eight_diagram` is not allowed to borrow a
 * variant image from another package: the native client resolves the image by
 * package + name, and a missing asset must remain a fallback rather than
 * becoming a visually false card.
 */
export const NATIVE_CARD_ASSETS: Record<string, string> = {
  'mobile/ex_eight_diagram': '/packages/mobile/image/card/ex_eight_diagram.png',
  'mobile/ex_crossbow': '/packages/mobile/image/card/ex_crossbow.png',
  'mobile/ex_nioh_shield': '/packages/mobile/image/card/ex_nioh_shield.png',
  'mobile/ex_silver_lion': '/packages/mobile/image/card/ex_silver_lion.png',
  'mobile/ex_vine': '/packages/mobile/image/card/ex_vine.png',
  'mobile/xuanjian_sword': '/packages/mobile/image/card/xuanjian_sword.png',

  'gamemode/v33__ex_nihilo': '/packages/gamemode/image/card/v33__ex_nihilo.png',
  'gamemode/v11__dismantlement': '/packages/gamemode/image/card/v11__dismantlement.png',
  'gamemode/ice__slash': '/packages/gamemode/image/card/ice__slash.png',
  'gamemode/stab__slash': '/packages/gamemode/image/card/stab__slash.png',
  'gamemode/yitian_sword': '/packages/gamemode/image/card/yitian_sword.png',
  'gamemode/five_elements_fan': '/packages/gamemode/image/card/five_elements_fan.png',
  'gamemode/seven_stars_sword': '/packages/gamemode/image/card/seven_stars_sword.png',
  'gamemode/crafty_escape': '/packages/gamemode/image/card/crafty_escape.png',
  'gamemode/honey_trap': '/packages/gamemode/image/card/honey_trap.png',
  'gamemode/drowning': '/packages/gamemode/image/card/drowning.png',

  'tenyear/thunder_blade': '/packages/tenyear/image/card/thunder_blade.png',
  'tenyear/quenched_blade': '/packages/tenyear/image/card/quenched_blade.png',
  'tenyear/real__crossbow': '/packages/tenyear/image/card/real__crossbow.png',
  'tenyear/red_spear': '/packages/tenyear/image/card/red_spear.png',
  'tenyear/water_sword': '/packages/tenyear/image/card/water_sword.png',
  'tenyear/poisonous_dagger': '/packages/tenyear/image/card/poisonous_dagger.png',

  'standard_ex/role__wooden_ox': '/packages/standard_ex/image/card/role__wooden_ox.png',
  'overseas/moon_spear': '/packages/overseas/image/card/moon_spear.png',
  'overseas/celestial_calabash': '/packages/overseas/image/card/celestial_calabash.png',
  'overseas/talisman': '/packages/overseas/image/card/talisman.png',
  'sp/yanxiao_trick': '/packages/sp/image/card/delayedTrick/yanxiao_trick.png',
};

const NATIVE_CARD_ASSETS_BY_NAME = new Map<string, string>();
const AMBIGUOUS_NATIVE_CARD_NAMES = new Set<string>();
for (const [key, url] of Object.entries(NATIVE_CARD_ASSETS)) {
  const name = key.slice(key.indexOf('/') + 1);
  if (NATIVE_CARD_ASSETS_BY_NAME.has(name)) {
    AMBIGUOUS_NATIVE_CARD_NAMES.add(name);
    NATIVE_CARD_ASSETS_BY_NAME.delete(name);
  } else if (!AMBIGUOUS_NATIVE_CARD_NAMES.has(name)) {
    NATIVE_CARD_ASSETS_BY_NAME.set(name, url);
  }
}

function safeNativeAssetName(value: string | undefined): string | null {
  return value && /^[A-Za-z0-9_-]+$/.test(value) ? value : null;
}

/**
 * Return the same ordered candidates as FreeKill's SkinBank:
 * package-local art first, then the focused catalogue/global fallback.
 *
 * The package candidate is deliberately generated from the safe extension and
 * card name as well as the small static map.  That keeps newly installed
 * upstream package art usable in development and production without making a
 * variant borrow another package's face when the exact file is available.
 */
export function getNativeCardArtCandidates(cardOrName: CardData | string | undefined): string[] {
  const card: CardData = typeof cardOrName === 'string' ? { name: cardOrName } : (cardOrName ?? {});
  const names = [card.picName, card.name].map(safeNativeAssetName).filter((name): name is string => !!name);
  const candidates: string[] = [];
  const add = (url: string | undefined) => {
    if (url && !candidates.includes(url)) candidates.push(url);
  };

  // Match the actual definition name first.  picName is only a rendering
  // hint and cannot override a package-local definition with the same name.
  const definitionName = safeNativeAssetName(card.name);
  if (card.extension && definitionName) {
    add(NATIVE_CARD_ASSETS[`${card.extension}/${definitionName}`]);
    add(`/packages/${card.extension}/image/card/${definitionName}.png`);
  }

  // The focused catalogue is the cross-package fallback used by the active
  // Quốc Chiến pool.  It is intentionally consulted after an exact package
  // asset so mobile/gamemode variants never silently use a generic face.
  if (definitionName && CATALOG_CARD_ART_NAMES.has(definitionName)) {
    add(catalogCardArtUrl(definitionName));
  }

  for (const name of names) {
    if (card.extension) {
      add(NATIVE_CARD_ASSETS[`${card.extension}/${name}`]);
    }
    // This fallback is still exact by card definition name; it is only used
    // when that name occurs in one package in the shipped native manifest.
    const unique = NATIVE_CARD_ASSETS_BY_NAME.get(name);
    add(unique);
  }
  return candidates;
}

export function getNativeCardArtUrl(cardOrName: CardData | string | undefined): string | null {
  return getNativeCardArtCandidates(cardOrName)[0] ?? null;
}

/** Native Card Art Renderer or Neutral Frame (Strict adherence to native assets) */
function CardArt({ card, alt = '', sheet = false }: {
  card?: CardData;
  alt?: string;
  sheet?: boolean;
}) {
  const [candidateIndex, setCandidateIndex] = useState(0);
  const candidates = getNativeCardArtCandidates(card);
  const artUrl = candidates[candidateIndex] ?? null;
  useEffect(() => setCandidateIndex(0), [card?.extension, card?.picName, card?.name]);
  if (artUrl) {
    return (
      <img
        className={sheet ? 'sg-sheet-native-art' : 'sg-card-native-art'}
        src={artUrl}
        alt={alt}
        aria-hidden={alt ? undefined : true}
        onError={() => setCandidateIndex((index) => index + 1)}
      />
    );
  }
  if (sheet) return <span className="sg-card-sigil-icon sigil-neutral" aria-hidden="true">✦</span>;
  return (
    <div className="sg-card-art-frame" aria-hidden="true">
      <span className="sg-card-sigil-icon sigil-neutral">✦</span>
    </div>
  );
}

export function CardSigil({ card }: { card?: CardData }): ReactNode {
  return <CardArt card={card} />;
}

/** Accessible Bottom Sheet Modal for Card Inspection */
export function CardDetailSheet({
  isOpen,
  onClose,
  displayName,
  category,
  suitInfo,
  rank,
  description,
  card,
  details = [],
}: {
  isOpen: boolean;
  onClose: () => void;
  displayName: string;
  category: CardCategoryInfo;
  suitInfo: CardSuitInfo;
  rank: string;
  description: string;
  card?: CardData;
  details?: { label: string; value: string }[];
}) {
  const dialogRef = useRef<HTMLDivElement>(null);
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return;
    previousFocusRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onCloseRef.current();
        return;
      }
      if (e.key !== 'Tab') return;
      const focusable = Array.from(dialogRef.current?.querySelectorAll<HTMLElement>(
        'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      ) ?? []);
      if (!focusable.length) {
        e.preventDefault();
        dialogRef.current?.focus();
        return;
      }
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    const focusTimer = window.setTimeout(() => closeButtonRef.current?.focus(), 0);
    return () => {
      window.clearTimeout(focusTimer);
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = previousOverflow;
      previousFocusRef.current?.focus();
      previousFocusRef.current = null;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      className="sg-card-modal-backdrop"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
      role="presentation"
    >
      <div
        className="sg-card-detail-sheet"
        role="dialog"
        aria-modal="true"
        aria-labelledby="card-sheet-title"
        aria-describedby={details.length ? 'card-sheet-description card-sheet-native-details' : 'card-sheet-description'}
        tabIndex={-1}
        ref={dialogRef}
      >
        <div className="sg-sheet-header">
          <div className="sg-sheet-badge-group">
            <span className={`sg-sheet-suit ${suitInfo.colorClass}`}>
              {suitInfo.symbol} {rank}
            </span>
            {category.label && (
              <span className={`sg-sheet-category ${category.className}`}>
                {category.label}
              </span>
            )}
          </div>
          <button
            type="button"
            className="sg-sheet-close-button"
            onClick={onClose}
            ref={closeButtonRef}
            aria-label="Đóng bảng chi tiết lá bài"
          >
            ✕
          </button>
        </div>

        <div className="sg-sheet-body">
          <div className="sg-sheet-art-preview">
            <CardArt card={card} alt={displayName} sheet />
          </div>
          <h3 id="card-sheet-title" className="sg-sheet-title">
            {displayName}
          </h3>
          <p id="card-sheet-description" className="sg-sheet-desc">{description}</p>
          {details.length > 0 && <dl className="sg-sheet-native-details" id="card-sheet-native-details">
            {details.map(({ label, value }) => <div key={label}>
              <dt>{label}</dt><dd>{value}</dd>
            </div>)}
          </dl>}
        </div>

        <div className="sg-sheet-footer">
          <button
            type="button"
            className="button primary sg-sheet-confirm-button"
            onClick={onClose}
          >
            Đóng
          </button>
        </div>
      </div>
    </div>
  );
}

/** Action bar card summary for mobile / selected state */
export function SelectedCardSummary({
  item,
  onInspect,
}: {
  item: GameplayItem;
  onInspect: () => void;
}) {
  const text = useDisplayText();
  const rawCard = objectValue(item.card) as CardData | null;
  const card: CardData | undefined = rawCard ? rawCard : undefined;
  const suitInfo = getSuitInfo(card?.suit);
  const rank = formatRank(card?.number);
  const { displayName, description } = resolveCardText(card, text);

  return (
    <div className="sg-selected-card-summary" role="status">
      <div className="sg-summary-text">
        <strong>
          Đang chọn: 【{displayName}】
          {rank ? ` (${suitInfo.symbol} ${rank})` : ''}
        </strong>
        <p className="sg-summary-desc">{description}</p>
      </div>
      <button
        type="button"
        className="button secondary small-button sg-inspect-action-btn"
        onClick={onInspect}
        aria-label={`Xem chi tiết ${displayName}`}
      >
        ? Chi tiết
      </button>
    </div>
  );
}

/**
 * HandCardItem with 4-Layer Presentation:
 * Directly renders a `<button>` with `.gameplay-choice.sg-card-button`
 * preserving 100% of DOM, accessibility and event contracts.
 */
export function HandCardItem({
  item,
  busy,
  onClick,
  onLongPress,
  index = 0,
  totalCards = 1,
}: {
  item: GameplayItem;
  busy: boolean;
  onClick: () => void;
  /** Mobile inspection gesture; must not change the Lua selection state. */
  onLongPress?: () => void;
  index?: number;
  totalCards?: number;
}) {
  const text = useDisplayText();
  const rawCard = objectValue(item.card) as CardData | null;
  const card: CardData | undefined = rawCard ? rawCard : undefined;

  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const longPressTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const longPressTriggeredRef = useRef(false);

  const suitInfo = getSuitInfo(card?.suit);
  const rank = formatRank(card?.number);
  const categoryFromName = getCardCategory(card?.name);
  const category = categoryFromName.typeKey === 'unknown'
    ? getCardCategory(card?.trueName)
    : categoryFromName;
  const { displayName, description } = resolveCardText(card, text);

  const disabled = busy || !item.enabled;
  const reactId = useId().replace(/:/g, '');
  const metadataId = `card-meta-${reactId}`;
  const cardMetadata = [suitInfo.name, rank, category.label].filter(Boolean).join(' · ');
  const overlapDesktop = index > 0 && totalCards > 7
    ? Math.min(36, 12 + (totalCards - 7) * 3)
    : 0;
  const overlapMobile = index > 0 && totalCards > 4
    ? Math.min(42, 14 + (totalCards - 4) * 4.5)
    : 0;
  const overlapLandscape = index > 0 && totalCards > 7
    ? Math.min(22, 10 + (totalCards - 7) * 2.5)
    : 0;
  const cardStyle = {
    zIndex: item.selected ? 200 : (hovered || focused) ? 100 : index + 1,
    '--card-overlap': `${overlapDesktop}px`,
    '--card-overlap-desktop': `${overlapDesktop}px`,
    '--card-overlap-mobile': `${overlapMobile}px`,
    '--card-overlap-landscape': `${overlapLandscape}px`,
  } as CSSProperties;

  const cancelLongPress = () => {
    if (longPressTimerRef.current !== null) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
  };

  useEffect(() => () => cancelLongPress(), []);

  const startLongPress = (event: ReactPointerEvent<HTMLButtonElement>) => {
    if (!onLongPress || disabled || (event.pointerType === 'mouse' && event.button !== 0)) return;
    cancelLongPress();
    longPressTriggeredRef.current = false;
    longPressTimerRef.current = setTimeout(() => {
      longPressTimerRef.current = null;
      longPressTriggeredRef.current = true;
      onLongPress();
    }, 550);
  };

  const finishLongPress = () => cancelLongPress();

  return (
    <button
      type="button"
      className={`gameplay-choice sg-card-button ${category.className} ${
        item.selected ? 'selected' : ''
      }`}
      style={cardStyle}
      data-card-id={typeof item.id === 'number' ? item.id : undefined}
      aria-pressed={item.selected}
      aria-label={displayName}
      aria-describedby={metadataId}
      disabled={disabled}
      onPointerDown={startLongPress}
      onPointerUp={finishLongPress}
      onPointerCancel={finishLongPress}
      onPointerLeave={finishLongPress}
      onContextMenu={(event) => {
        if (longPressTriggeredRef.current) event.preventDefault();
      }}
      onClick={(event) => {
        if (longPressTriggeredRef.current) {
          event.preventDefault();
          longPressTriggeredRef.current = false;
          return;
        }
        onClick();
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    >
      <span id={metadataId} className="sg-visually-hidden">
        {cardMetadata ? `${cardMetadata}. ` : ''}{description}
      </span>
      {/* Layer 1: Top-Left Suit & Rank */}
      <div className="sg-card-top-left" aria-hidden="true">
        <span className="sg-card-rank">{rank || ' '}</span>
        <span className={`sg-card-suit ${suitInfo.colorClass}`}>
          {suitInfo.symbol}
        </span>
      </div>

      {/* Layer 2: Top-Right Category Badge */}
      {category.badge && (
        <span className="sg-card-type-badge" aria-hidden="true">
          {category.badge}
        </span>
      )}

      {/* Layer 3: Central Illustration (Native Asset or Neutral Frame) */}
      <CardArt card={card} />

      {/* Layer 4: Card Name Banner */}
      <div className="sg-card-banner">
        <span className="sg-card-name">{displayName}</span>
      </div>

      {/* Selecting a playable card never opens a passive tooltip. Details are
          available through long press or the selected-card summary action. */}
    </button>
  );
}

/** Authentic Center In-Play Card Resolution (Table Pile / Processing Area) */
export function ResolvingCardView({ card, activity = 'processing' }: { card: { name: string; suit: number; number: number; known?: boolean; footnote?: string; virtName?: string; extension?: string; picName?: string }; activity?: 'processing' | 'discard' | 'reveal' }) {
  const [inspectOpen, setInspectOpen] = useState(false);
  const text = useDisplayText();
  const description = activity === 'discard' ? 'Vừa bỏ' : activity === 'reveal' ? 'Đang cho xem' : 'Đang xử lý';
  // Native PokerCard.qml uses its card back whenever CardModel.known is false.
  // Avoid even computing a translated title for a concealed table card.
  if (card.known === false) {
    return <div className="native-resolving-card native-resolving-hidden" aria-label={`${description}: bài úp`}>
      <span className="native-resolving-hidden-label">Bài úp</span>
    </div>;
  }
  const suitInfo = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  const category = getCardCategory(card.name);
  const { displayName, description: cardDescription } = resolveCardText(card, text);

  const virtualName = card.virtName && card.virtName !== card.name ? text(card.virtName) : '';
  const footnote = card.footnote ? text(card.footnote) : '';
  const label = `${description}: ${displayName} · ${suitInfo.name} ${rank}${virtualName ? ` · Dùng như ${virtualName}` : ''}${footnote ? ` · ${footnote}` : ''}`;
  return (
    <>
    <button type="button" className="native-resolving-card" aria-label={`Xem chi tiết ${label}`} title={label}
      onClick={() => setInspectOpen(true)}>
      <div className="native-resolving-topline">
        <div className="card-head">
          <span className={suitInfo.colorClass}>
            <span className="native-resolving-rank">{rank}</span>
            <span className="native-resolving-suit">{suitInfo.symbol}</span>
          </span>
          <span className="card-cat-badge">{category.label || 'Bài'}</span>
        </div>
        <div className="card-foot">{displayName}</div>
      </div>
      <div className="card-thumb">
        <CardArt card={card} alt={displayName} />
      </div>
      {virtualName && <span className="native-resolving-virtual-name">{virtualName}</span>}
      {footnote && <div className="native-resolving-footnote">{footnote}</div>}
    </button>
    {inspectOpen && createPortal(<CardDetailSheet isOpen onClose={() => setInspectOpen(false)}
      displayName={displayName} category={category} suitInfo={suitInfo} rank={rank}
      description={cardDescription} card={card} details={[
        { label: 'Trạng thái', value: description },
        ...(virtualName ? [{ label: 'Dùng như', value: virtualName }] : []),
        ...(footnote ? [{ label: 'Chú thích FreeKill', value: footnote }] : []),
      ]} />, document.body)}
    </>
  );
}

/** Compact public card preview used for the latest card in the discard pile. */
export function PublicPileCardPreview({
  card,
  label = 'Lá bỏ gần nhất',
}: {
  card: CardData;
  label?: string;
}) {
  const [inspectOpen, setInspectOpen] = useState(false);
  const text = useDisplayText();
  if (card.known === false) {
    return <div className="native-pile-card-preview native-pile-card-hidden"
      aria-label={`${label}: bài úp`} title={`${label}: bài úp`} />;
  }
  const suitInfo = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  const { displayName, description } = resolveCardText(card, text);
  const category = getCardCategory(card.name);
  const virtualName = card.virtName && card.virtName !== card.name ? text(card.virtName) : '';
  const footnote = card.footnote ? text(card.footnote) : '';
  const cardLabel = `${label}: ${displayName} · ${suitInfo.name} ${rank}`;

  return (
    <>
    <button type="button" className="native-pile-card-preview" aria-label={`Xem chi tiết ${cardLabel}`} title={cardLabel}
      onClick={() => setInspectOpen(true)}>
      <CardArt card={card} />
      <span className={`native-pile-card-rank ${suitInfo.colorClass}`} aria-hidden="true">
        {suitInfo.symbol} {rank}
      </span>
      <span className="native-pile-card-name" aria-hidden="true">{displayName}</span>
    </button>
    {inspectOpen && createPortal(<CardDetailSheet isOpen onClose={() => setInspectOpen(false)}
      displayName={displayName} category={category} suitInfo={suitInfo} rank={rank}
      description={description} card={card} details={[
        { label: 'Vị trí', value: label },
        ...(virtualName ? [{ label: 'Dùng như', value: virtualName }] : []),
        ...(footnote ? [{ label: 'Chú thích FreeKill', value: footnote }] : []),
      ]} />, document.body)}
    </>
  );
}

/** Idle Hand Card for Bottom Dashboard (renders cards outside active turns) */
export function IdleHandCard({
  card,
  index = 0,
  totalCards = 1,
}: {
  card: { name: string; suit: number; number: number; extension?: string; picName?: string };
  index?: number;
  totalCards?: number;
}) {
  const text = useDisplayText();
  const suitInfo = getSuitInfo(card.suit);
  const rank = formatRank(card.number);
  const categoryFromName = getCardCategory(card.name);
  const category = categoryFromName.typeKey === 'unknown' ? getCardCategory((card as any).trueName) : categoryFromName;
  const { displayName, description } = resolveCardText(card, text);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const [rect, setRect] = useState<DOMRect | null>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  const reactId = useId().replace(/:/g, '');
  const tooltipId = `card-tip-idle-${reactId}`;
  const metadataId = `card-meta-idle-${reactId}`;
  const cardMetadata = [suitInfo.name, rank, category.label].filter(Boolean).join(' · ');
  const showTooltip = hovered || focused;
  const [inspectOpen, setInspectOpen] = useState(false);

  const overlapDesktop = index > 0 && totalCards > 7 ? Math.min(36, 12 + (totalCards - 7) * 3) : 0;
  const overlapMobile = index > 0 && totalCards > 4 ? Math.min(42, 14 + (totalCards - 4) * 4.5) : 0;
  const overlapLandscape = index > 0 && totalCards > 7 ? Math.min(22, 10 + (totalCards - 7) * 2.5) : 0;
  const cardStyle = {
    zIndex: showTooltip ? 100 : index + 1,
    '--card-overlap': `${overlapDesktop}px`,
    '--card-overlap-desktop': `${overlapDesktop}px`,
    '--card-overlap-mobile': `${overlapMobile}px`,
    '--card-overlap-landscape': `${overlapLandscape}px`,
    opacity: 0.95,
    cursor: 'pointer',
  } as CSSProperties;

  const updateRect = () => {
    if (cardRef.current) {
      setRect(cardRef.current.getBoundingClientRect());
    }
  };

  const inspect = () => setInspectOpen(true);
  const handleKeyDown = (event: ReactKeyboardEvent<HTMLDivElement>) => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    event.preventDefault();
    inspect();
  };

  return (
    <>
      <div
        ref={cardRef}
        tabIndex={0}
        role="button"
        className={`gameplay-choice sg-card-button sg-card-idle ${category.className}`}
        style={cardStyle}
        aria-label={`${displayName} · ${suitInfo.name} ${rank}`}
        aria-describedby={showTooltip ? tooltipId : metadataId}
        title="Chạm để xem chi tiết lá bài"
        onClick={inspect}
        onKeyDown={handleKeyDown}
        onMouseEnter={() => { updateRect(); setHovered(true); }}
        onMouseLeave={() => setHovered(false)}
        onFocus={() => { updateRect(); setFocused(true); }}
        onBlur={() => setFocused(false)}
      >
        <span id={metadataId} className="sg-visually-hidden">
          {cardMetadata ? `${cardMetadata}. ` : ''}{description}
        </span>
        {/* Layer 1: Top-Left Suit & Rank */}
        <div className="sg-card-top-left" aria-hidden="true">
          <span className="sg-card-rank">{rank || ' '}</span>
          <span className={`sg-card-suit ${suitInfo.colorClass}`}>
            {suitInfo.symbol}
          </span>
        </div>

        {/* Layer 2: Top-Right Category Badge */}
        {category.badge && (
          <span className="sg-card-type-badge" aria-hidden="true">
            {category.badge}
          </span>
        )}

        {/* Layer 3: Central Illustration (Native Asset or Neutral Frame) */}
        <CardArt card={card} />

        {/* Layer 4: Card Name Banner */}
        <div className="sg-card-banner">
          <span className="sg-card-name">{displayName}</span>
        </div>
        {showTooltip && (
          typeof document !== 'undefined' ? createPortal(
            <div
              id={tooltipId}
              className="sg-card-popover-tooltip sg-card-popover-portal"
              role="tooltip"
              style={cardTooltipStyle(rect)}
            >
              <strong className="sg-tip-title">
                {displayName} {rank ? `(${suitInfo.symbol} ${rank})` : ''}
              </strong>
              {category.label && (
                <span className="sg-tip-category">[{category.label}]</span>
              )}
              <span className="sg-tip-desc">{description}</span>
            </div>,
            document.body
          ) : (
            <span id={tooltipId} className="sg-card-popover-tooltip" role="tooltip">
              <strong className="sg-tip-title">{displayName}</strong>
              <span className="sg-tip-desc">{description}</span>
            </span>
          )
        )}
      </div>
      <CardDetailSheet
        isOpen={inspectOpen}
        onClose={() => setInspectOpen(false)}
        displayName={displayName}
        category={category}
        suitInfo={suitInfo}
        rank={rank}
        description={description}
        card={card}
      />
    </>
  );
}
