import { useGameStore } from '../store/gameStore';
import { VI_ADDITIONS } from './vietnamese';

/** Render upstream rich text as plain text; React never receives raw HTML. */
export function plainText(text: string): string {
  const source = typeof text === 'string' ? text.slice(0, 20_000) : String(text).slice(0, 20_000);
  return source.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
    .replace(/<br\s*\/?\s*>/gi, '\n').replace(/<[^>]*>/g, '')
    .replace(/&(?:lt|gt|amp|quot|apos|nbsp|#(?:x[0-9a-f]{1,6}|[0-9]{1,7}));/gi, (entity) => {
      const numeric = entity.match(/^&#(x[0-9a-f]+|[0-9]+);$/i);
      if (numeric) {
        const hex = numeric[1][0].toLowerCase() === 'x';
        const codepoint = Number.parseInt(hex ? numeric[1].slice(1) : numeric[1], hex ? 16 : 10);
        return codepoint > 0 && codepoint <= 0x10ffff && !(codepoint >= 0xd800 && codepoint <= 0xdfff)
          ? String.fromCodePoint(codepoint) : entity;
      }
      const named: Record<string, string> = {
        '&lt;': '<', '&gt;': '>', '&amp;': '&', '&quot;': '"', '&apos;': "'", '&nbsp;': '\u00a0',
      };
      return named[entity.toLowerCase()] ?? entity;
    });
}

export function displayText(text: string, translations: Record<string, string>, players: { id: number; name: string }[] = []): string {
  const [key, src, dest, ...args] = text.split(':');
  const lookup = (k: string | undefined): string | undefined => {
    if (!k) return undefined;
    return translations[k] ?? VI_ADDITIONS[k];
  };

  const prefixMatch = key.match(/^([#:]?)[a-zA-Z0-9]+__(.+)$/);
  const baseKey = prefixMatch ? (prefixMatch[1] ?? '') + prefixMatch[2] : (key.includes('__') ? key.replace(/^.*__/, '') : key);
  const rawKey = prefixMatch ? prefixMatch[2] : undefined;
  const withoutHashKey = key.startsWith('#') ? key.slice(1) : undefined;
  const withoutHashBaseKey = baseKey.startsWith('#') ? baseKey.slice(1) : undefined;
  const baseText = text.includes('__') && !text.startsWith(':') ? text.replace(/^.*__/, '') : text;

  // A full key wins (e.g. descriptions beginning with ':').
  let translated = lookup(text)
    ?? lookup(key)
    ?? lookup(baseKey)
    ?? lookup(rawKey)
    ?? lookup(withoutHashKey)
    ?? lookup(withoutHashBaseKey)
    ?? lookup(baseText);

  // Fallback for skill invoke prompts like #m_ex__fenji-invoke or #fenji-invoke
  if (!translated && key.endsWith('-invoke')) {
    const skillToken = key.replace(/^[#:]/, '').replace(/-invoke$/, '');
    const skillBaseToken = skillToken.replace(/^[a-zA-Z0-9]+__/, '');
    const skillTitle = lookup(skillToken) ?? lookup(skillBaseToken) ?? skillBaseToken;
    if (dest) {
      translated = `${skillTitle}: Bạn có muốn kích hoạt lên %dest không?`;
    } else {
      translated = `Bạn có muốn kích hoạt kỹ năng ${skillTitle}?`;
    }
  }

  const playerName = (value: string | undefined) => {
    if (!value) return '';
    const num = Number(value);
    if (!Number.isNaN(num)) {
      const p = players.find((pl) => pl.id === num || (num < 0 && pl.id === Math.abs(num)));
      if (p) return p.name;
      return num < 0 ? 'mục tiêu' : `Người chơi ${num}`;
    }
    return players.find((p) => String(p.id) === value)?.name ?? value ?? '';
  };

  const name = (value: string | undefined) => {
    if (!value) return '';
    const base = value.includes('__') ? value.replace(/^.*__/, '') : value;
    const tr = lookup(value) ?? lookup(base) ?? value;
    return plainText(tr);
  };

  if (!translated) translated = text;
  if (translated === text && !lookup(key) && !lookup(baseKey)) return plainText(text);
  return plainText(translated).replace(/%(arg\d*|src|dest|from|to)\b/g, (_token, parameter: string) => {
    if (parameter.startsWith('arg')) {
      const index = parameter === 'arg' ? 0 : Number(parameter.slice(3)) - 1;
      return name(args[index]);
    }
    return playerName(parameter === 'src' || parameter === 'from' ? src : dest);
  });
}

// The C++ server has already expanded some GameLog arguments (including card
// names and seat labels) before the Lua/client translation table is loaded.
// These narrowly matched legacy phrases come from the pinned upstream package.
const legacyBattleEvents: [string, string, string][] = [
  ['赋礼', 'battle_royal_fuli', '本轮内：任意角色的摸牌阶段开始前，其可以跳过此阶段，改为获得弃牌堆中至多两张奇珍牌。'],
  ['胜者为王', 'battle_royal_shengzheweiwang', '本轮内：有角色死亡时，杀死其的角色本局游戏摸牌阶段多摸三张牌。'],
  ['祸起', 'battle_royal_huoqi', '本轮内：所有角色受到的伤害+1。'],
  ['落石', 'battle_royal_luoshi', '翻开此牌时，所有确定势力的角色依次变更副将。'],
  ['不进则退', 'battle_royal_bujinzetui', '本轮内：每名角色的回合结束时，若其本回合未造成过伤害，其失去1点体力。'],
  ['激励', 'battle_royal_jili', '本轮内：【杀】无次数距离限制。'],
];

/** Display only. Never rewrite GameLog events stored by the reducer or wire replies. */
export function localizedGameLog(raw: string): string {
  let result = plainText(raw).trim();
  const event = result.match(/^本轮事件为：([^：]+)：(.+)$/);
  if (event) {
    const known = legacyBattleEvents.find(([name, , description]) => event[1] === name && event[2] === description);
    if (known) result = `Sự kiện vòng này: ${VI_ADDITIONS[known[1]]}. ${VI_ADDITIONS[`:${known[1]}`]}`;
  }
  result = result.replace(/^本轮事件：:\s*/, 'Sự kiện vòng này: ');
  for (const [chinese, key] of legacyBattleEvents) {
    result = result.replaceAll(chinese, VI_ADDITIONS[key]);
  }
  result = result.replaceAll('鹦鹉杯', VI_ADDITIONS.turban_shell_cup)
    .replaceAll('咄咄逼人', VI_ADDITIONS.overbearing)
    .replaceAll('图穷匕见', VI_ADDITIONS.reveal_intention)
    .replaceAll('巧取豪夺', VI_ADDITIONS.tricky_heist)
    .replaceAll('狗尾续貂', VI_ADDITIONS.unworthy_continuation)
    .replaceAll('火浣衣', VI_ADDITIONS.amiantus_robe)
    .replaceAll('掠闪', VI_ADDITIONS.rob__jink)
    .replaceAll('阳燧枪', VI_ADDITIONS.yangsui_spear)
    .replaceAll('白麒麟', VI_ADDITIONS.white_kylin)
    .replaceAll('天禄', VI_ADDITIONS.tianlu)
    .replaceAll('遁甲天书', VI_ADDITIONS.dunjia_book)
    .replaceAll('九州鼎', VI_ADDITIONS.nine_tripod_cauldrons)
    .replaceAll('〖巨贾〗', `〖${VI_ADDITIONS.ofl_heg__jugu}〗`)
    .replaceAll('〖资援〗', `〖${VI_ADDITIONS.ofl_heg__ziyuan}〗`)
    // Already-expanded public C++ GameLog skill names from the pinned variants.
    // Match skill markers only; never translate unknown text or wire identifiers.
    .replaceAll('〖祸水〗', `〖${VI_ADDITIONS.huoshui}〗`)
    .replaceAll('〖礼下〗', `〖${VI_ADDITIONS.ld__lixia}〗`)
    .replaceAll('〖倾城〗', `〖${VI_ADDITIONS.qingcheng}〗`)
    .replaceAll('〖避乱〗', `〖${VI_ADDITIONS.ld__biluan}〗`)
    .replaceAll('#new_battle_royal_event&', VI_ADDITIONS['#new_battle_royal_event&'])
    .replaceAll('鏖战', VI_ADDITIONS['#new_battle_royal_event&'])
    .replaceAll('Triblade', VI_ADDITIONS.triblade)
    .replaceAll('(酒)', '(Tửu)')
    .replace(/(\d+) th Round (Start|End)/g, (_match, number: string, phase: string) =>
      `${phase === 'Start' ? 'Bắt đầu' : 'Kết thúc'} vòng ${number}`)
    .replace(/^-+\s*(.+?)'s Turn (Start|End)\s*-+$/, (_match, who: string, phase: string) =>
      `${phase === 'Start' ? 'Bắt đầu' : 'Kết thúc'} lượt của ${who}`)
    .replace(/^-+\s*(Bắt đầu|Kết thúc) vòng (\d+)\s*-+$/, '$1 vòng $2')
    .replace(/^(.+?) is removed from the game$/, '$1 bị loại khỏi trận.')
    .replace(/^(.+?) 即将对 (.+?) 造成的 (\d+) 点 (.+?) 伤害变为 (\d+) 点$/,
      (_match, source: string, target: string, original: string, type: string, changed: string) =>
        `Sát thương ${type} do ${source} gây ra cho ${target} thay đổi từ ${original} thành ${changed} điểm.`)
    .replace(/^(.+?) 观看了 (.+?) 的 (chủ tướng|phó tướng|bài trên tay)(?: (.+))?$/,
      (_match, viewer: string, target: string, part: string, general?: string) =>
        `${viewer} đã xem ${part} của ${target}${general ? `: ${general}` : ''}.`)
    .replace(/^(.+?) 使用的 (.+?) 取消了目标 (.+)$/,
      (_match, source: string, card: string, target: string) =>
        `Mục tiêu ${target} đã bị hủy khỏi lá ${card} do ${source} sử dụng.`)
    .replace(/#(\d+)(\(you\))?/g, (_match, seat: string, you?: string) => `Ghế ${seat}${you ? ' (bạn)' : ''}`)
    .replaceAll('(you)', ' (bạn)');
  // Some old C++ GameLog variants omit the skill marker but keep the phrase
  // "kỹ năng". Translate only that bounded context; arbitrary Chinese text
  // remains verbatim so an unknown identifier cannot be mistranslated.
  result = result.replace(/(kỹ năng\s*(?:〖|「|【)?)(祸水|礼下)(?:〗|」|】)?/gi,
    (_match, prefix: string, skill: string) => `${prefix}${skill === '祸水' ? VI_ADDITIONS.huoshui : VI_ADDITIONS.ld__lixia}`);
  return result;
}

export function useDisplayText() {
  const translations = useGameStore((s) => s.translations);
  const players = useGameStore((s) => s.players);
  return (text: string) => displayText(text, translations, players);
}
