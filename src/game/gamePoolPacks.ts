// Pinned new_heg_mode inventory. Keep this list aligned with the Lua
// __web_room_packs inventory when the installed game packages change.
export const GAME_POOL_PACKS = {
  generals: [
    { id: 'hegemony_standard', label: 'Quốc Chiến Tiêu Chuẩn' },
    { id: 'formation', label: 'Trận Pháp' },
    { id: 'momentum', label: 'Biến Cục' },
    { id: 'transformation', label: 'Biến Hóa' },
    { id: 'power', label: 'Quyền Lực' },
    { id: 'lord_ex', label: 'Quân Chủ Mở Rộng' },
    { id: 'zqdl', label: 'Tử Khí Đông Lai' },
    { id: 'jyzs', label: 'Kim Ấn Tử Thụ' },
    { id: 'zfxp', label: 'Tử Phượng Hàm Bội' },
    { id: 'online_heg', label: 'Bản Quyền OL' },
    { id: 'mobile_heg', label: 'Bản Quyền Mobile' },
    { id: 'tenyear_heg', label: 'Quốc Chiến Thập Niên' },
    { id: 'overseas_heg', label: 'Quốc Chiến Quốc Tế' },
    { id: 'offline_heg', label: 'Quốc Chiến Ngoại Tuyến' },
  ],
  cards: [
    { id: 'hegemony_cards', label: 'Bài Tiêu Chuẩn' },
    { id: 'strategic_advantage', label: 'Ưu Thế Chiến Lược' },
    { id: 'nine_variations', label: 'Quốc Chiến Cửu Biến' },
    { id: 'lord_cards', label: 'Quân Lâm Thiên Hạ' },
  ],
} as const;

export type GamePackKind = keyof typeof GAME_POOL_PACKS;
export type DisabledGamePacks = Record<GamePackKind, string[]>;

export const DEFAULT_INITIAL_GENERAL_COUNT = 5;
export const MAX_INITIAL_GENERAL_COUNT = 10;

/** Hegemony requires at least five choices per seat; fall back for legacy policies. */
export function normalizeInitialGeneralCount(value: unknown): number {
  return typeof value === 'number' && Number.isInteger(value) &&
    value >= DEFAULT_INITIAL_GENERAL_COUNT && value <= MAX_INITIAL_GENERAL_COUNT
    ? value : DEFAULT_INITIAL_GENERAL_COUNT;
}

const ALLOWED_PACKS: Record<GamePackKind, ReadonlySet<string>> = {
  generals: new Set(GAME_POOL_PACKS.generals.map((pack) => pack.id)),
  cards: new Set(GAME_POOL_PACKS.cards.map((pack) => pack.id)),
};

/** Drop stale, misplaced, malformed and duplicate policy entries at the boundary. */
export function sanitizeDisabledGamePacks(value: unknown): { disabledPacks: DisabledGamePacks; discardedCount: number } {
  const source = value && typeof value === 'object' ? value as Record<string, unknown> : {};
  let discardedCount = 0;
  const clean = (kind: GamePackKind): string[] => {
    const items = Array.isArray(source[kind]) ? source[kind] : [];
    const seen = new Set<string>();
    const valid: string[] = [];
    for (const item of items) {
      if (typeof item !== 'string' || !ALLOWED_PACKS[kind].has(item) || seen.has(item)) {
        discardedCount += 1;
        continue;
      }
      seen.add(item);
      valid.push(item);
    }
    return valid;
  };
  const disabledPacks = { generals: clean('generals'), cards: clean('cards') };
  return { disabledPacks, discardedCount };
}
