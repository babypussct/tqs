import { LuaRuntime } from '../src/engine/luaRuntime';
import { UPSTREAM_PACKAGE_NAMES, loadUpstreamFiles } from './upstream-packages';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');

export interface TranslationEntry {
  category: 'System_UI' | 'GameLog_Event' | 'Card_Name' | 'Card_Description' | 'Card_Skill_Prompt' | 'General_Name' | 'General_Skill_Name' | 'General_Skill_Description' | 'General_Skill_Prompt' | 'Variant_Event';
  key: string;
  zh_CN: string;
  current_vi: string;
  notes?: string;
}

async function main() {
  console.log('Mounting Lua runtime with 14 upstream packages...');
  const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES, { patchDeclarations: true });
  const runtime = new LuaRuntime({
    files,
    callbacks: {
      send: () => {},
      setup: () => {},
      ui: () => {},
      log: () => {},
    },
  });

  await runtime.start();

  console.log('Extracting original Chinese translation keys from Lua...');

  // 1. Read keys directly from core client zh_CN.lua
  const coreClientPath = path.resolve(REPO_ROOT, 'runtime/packages/freekill-core/lua/client/i18n/zh_CN.lua');
  const coreContent = fs.readFileSync(coreClientPath, 'utf8');
  const coreKeySet = new Set<string>();
  for (const match of coreContent.matchAll(/\["([^"]+)"\]\s*=/g)) {
    const k = match[1];
    if (!k.startsWith('$$') && !k.startsWith('##') && !k.startsWith('help:') && !k.includes('Bulletin Info')) {
      coreKeySet.add(k);
    }
  }
  const coreRaw = [...coreKeySet];
  console.log(`Found ${coreRaw.length} core UI & Log keys from freekill-core/lua/client/i18n/zh_CN.lua`);

  // 2. Card keys (Standard cards + Hegemony weapons/armors/treasures)
  const cardNames = [
    'slash', 'jink', 'peach', 'analeptic', 'nullification',
    'fire_slash', 'fire__slash', 'thunder_slash', 'thunder__slash',
    'duel', 'snatch', 'dismantlement', 'indulgence', 'supply_shortage',
    'collateral', 'amazing_grace', 'ex_nihilo', 'god_salvation',
    'savage_assault', 'archery_attack', 'iron_chain', 'lightning', 'fire_attack',
    'crossbow', 'zhuge_crossbow', 'qinggang_sword', 'double_swords', 'blade', 'spear',
    'axe', 'halberd', 'kylin_bow', 'ice_sword', 'guding_blade', 'fan', 'triblade',
    'six_swords', 'dragon_phoenix', 'yangsui_spear', 'serpent_slayer_sword',
    'eight_diagram', 'nioh_shield', 'silver_lion', 'vine', 'breastplate', 'iron_armor', 'amiantus_robe',
    'jueying', 'dilu', 'zhuahuangfeidian', 'white_kylin',
    'chitu', 'dayuan', 'zixing', 'tianlu', 'liulongcanjia', 'mobile__liulongcanjia',
    'wooden_ox', 'role__wooden_ox', 'jade_seal', 'dunjia_book', 'nine_tripod_cauldrons', 'turban_shell_cup', 'rare_treasure'
  ];

  // 3. Visible Generals in batches
  const generalNames = runtime.eval<string[]>(`
    local list = {}
    for name, general in pairs(Fk.generals or {}) do
      if not general.hidden and not general.total_hidden then
        table.insert(list, name)
      end
    end
    table.sort(list)
    return list
  `);
  console.log(`Found ${generalNames.length} visible generals`);

  const generalsList: Array<{ name: string; skills: string[]; package: string; kingdom: string }> = [];
  for (let i = 0; i < generalNames.length; i += 32) {
    const chunk = generalNames.slice(i, i + 32);
    const luaChunk = `{${chunk.map((n) => JSON.stringify(n)).join(',')}}`;
    const batch = runtime.eval<Array<{ name: string; skills: string[]; package: string; kingdom: string }>>(`
      local res = {}
      for _, name in ipairs(${luaChunk}) do
        local general = Fk.generals[name]
        if general then
          local sks = {}
          local ok, sList = pcall(general.getSkillNameList, general)
          if ok and type(sList) == "table" then
            for _, s in ipairs(sList) do
              if type(s) == "string" then table.insert(sks, s) end
            end
          end
          table.insert(res, {
            name = name,
            skills = sks,
            package = general.package and general.package.name or "",
            kingdom = general.kingdom or ""
          })
        end
      end
      return res
    `);
    generalsList.push(...batch);
  }

  // Batch-fetch translations from Lua to avoid Wasmoon JSON budget limits
  async function fetchTranslations(keys: string[]): Promise<Record<string, string>> {
    const result: Record<string, string> = {};
    const chunkSize = 64;
    for (let i = 0; i < keys.length; i += chunkSize) {
      const chunk = keys.slice(i, i + chunkSize);
      const luaKeys = `{${chunk.map((k) => JSON.stringify(k)).join(',')}}`;
      const batch = runtime.eval<Record<string, string>>(`
        local res = {}
        for _, k in ipairs(${luaKeys}) do
          local v = Fk:translate(k, "zh_CN")
          if v ~= nil then res[k] = v end
        end
        return res
      `);
      Object.assign(result, batch);
    }
    return result;
  }

  // Collect all keys to query
  const allCardKeys: string[] = [];
  for (const c of cardNames) {
    allCardKeys.push(c);
    allCardKeys.push(':' + c);
    allCardKeys.push('#' + c);
    allCardKeys.push(c + '_skill');
    allCardKeys.push('#' + c + '_skill');
    allCardKeys.push(':' + c + '_skill');
    allCardKeys.push('#' + c + '-slash');
    allCardKeys.push('#' + c + '-jink');
    allCardKeys.push('#' + c + '-card');
  }

  const allGeneralKeys = generalsList.map((g) => g.name);
  const allSkillIds = [...new Set(generalsList.flatMap((g) => g.skills))].sort();
  console.log(`Found ${allSkillIds.length} unique skills across all visible generals`);

  const allSkillKeys: string[] = [];
  for (const s of allSkillIds) {
    allSkillKeys.push(s);
    allSkillKeys.push(':' + s);
    allSkillKeys.push('#' + s);
    allSkillKeys.push('#' + s + '-invoke');
  }

  const allVariantKeys = [
    'battle_royal_fuli', ':battle_royal_fuli',
    'battle_royal_shengzheweiwang', ':battle_royal_shengzheweiwang',
    'battle_royal_huoqi', ':battle_royal_huoqi',
    'battle_royal_luoshi', ':battle_royal_luoshi',
    'battle_royal_bujinzetui', ':battle_royal_bujinzetui',
    'battle_royal_jili', ':battle_royal_jili',
    '#new_battle_royal_event&',
    'ofl_heg__jugu', ':ofl_heg__jugu',
    'ofl_heg__ziyuan', ':ofl_heg__ziyuan',
    'recast', '#recast', ':recast',
    'reveal_skill&', '#reveal_skill&', ':reveal_skill&',
  ];

  console.log('Fetching translations from Lua runtime in safe batches...');
  const [coreTranslations, cardTranslations, generalTranslations, skillTranslations, variantTranslations] = await Promise.all([
    fetchTranslations(coreRaw),
    fetchTranslations(allCardKeys),
    fetchTranslations(allGeneralKeys),
    fetchTranslations(allSkillKeys),
    fetchTranslations(allVariantKeys),
  ]);

  const entries: TranslationEntry[] = [];
  const seenKeys = new Set<string>();

  const add = (entry: TranslationEntry) => {
    if (!entry.zh_CN || entry.zh_CN === entry.key) return; // Untranslated or missing
    if (seenKeys.has(entry.key)) return;
    seenKeys.add(entry.key);
    entries.push(entry);
  };

  // 1. Cards
  for (const c of cardNames) {
    if (cardTranslations[c]) {
      add({ category: 'Card_Name', key: c, zh_CN: cardTranslations[c], current_vi: VI_ADDITIONS[c] || '' });
    }
    if (cardTranslations[':' + c]) {
      add({ category: 'Card_Description', key: ':' + c, zh_CN: cardTranslations[':' + c], current_vi: VI_ADDITIONS[':' + c] || '' });
    }
    for (const sub of ['#' + c, c + '_skill', '#' + c + '_skill', ':' + c + '_skill', '#' + c + '-slash', '#' + c + '-jink', '#' + c + '-card']) {
      if (cardTranslations[sub]) {
        add({ category: 'Card_Skill_Prompt', key: sub, zh_CN: cardTranslations[sub], current_vi: VI_ADDITIONS[sub] || '' });
      }
    }
  }

  // 2. Core UI & GameLog
  for (const k of coreRaw) {
    const zh = coreTranslations[k];
    if (zh) {
      const isLog = k.startsWith('$') || k.startsWith('#');
      add({
        category: isLog ? 'GameLog_Event' : 'System_UI',
        key: k,
        zh_CN: zh,
        current_vi: VI_ADDITIONS[k] || '',
      });
    }
  }

  // 3. Variant Events
  for (const k of allVariantKeys) {
    const zh = variantTranslations[k];
    if (zh) {
      add({ category: 'Variant_Event', key: k, zh_CN: zh, current_vi: VI_ADDITIONS[k] || '' });
    }
  }

  // 4. Generals
  for (const g of generalsList) {
    const zh = generalTranslations[g.name];
    if (zh) {
      add({
        category: 'General_Name',
        key: g.name,
        zh_CN: zh,
        current_vi: VI_ADDITIONS[g.name] || '',
        notes: `Kingdom: ${g.kingdom}, Package: ${g.package}`,
      });
    }
  }

  // 5. Skills
  for (const s of allSkillIds) {
    const zhName = skillTranslations[s];
    const zhDesc = skillTranslations[':' + s];
    const zhPrompt = skillTranslations['#' + s];
    const zhInvoke = skillTranslations['#' + s + '-invoke'];

    if (zhName) {
      add({ category: 'General_Skill_Name', key: s, zh_CN: zhName, current_vi: VI_ADDITIONS[s] || '' });
    }
    if (zhDesc) {
      add({ category: 'General_Skill_Description', key: ':' + s, zh_CN: zhDesc, current_vi: VI_ADDITIONS[':' + s] || '' });
    }
    if (zhPrompt) {
      add({ category: 'General_Skill_Prompt', key: '#' + s, zh_CN: zhPrompt, current_vi: VI_ADDITIONS['#' + s] || '' });
    }
    if (zhInvoke) {
      add({ category: 'General_Skill_Prompt', key: '#' + s + '-invoke', zh_CN: zhInvoke, current_vi: VI_ADDITIONS['#' + s + '-invoke'] || '' });
    }
  }

  console.log(`Successfully extracted ${entries.length} display entries!`);

  // Write output files
  const outDir = path.resolve(REPO_ROOT, 'docs/translations');
  fs.mkdirSync(outDir, { recursive: true });

  // 1. JSON output
  const jsonPath = path.join(outDir, 'ZH_CN_ORIGINAL_CATALOG.json');
  fs.writeFileSync(jsonPath, JSON.stringify(entries, null, 2), 'utf8');
  console.log('Saved JSON catalog:', jsonPath);

  // 2. CSV output (with BOM for Excel / Google Sheets)
  const escapeCsv = (str: string) => {
    if (!str) return '""';
    return '"' + str.replace(/"/g, '""').replace(/\r\n/g, '\\n').replace(/\n/g, '\\n') + '"';
  };

  const csvRows = [
    ['Phân Loại (Category)', 'Mã Định Danh (Key)', 'Nguyên Văn Gốc Tiếng Trung (zh_CN)', 'Bản Dịch Việt Hiện Tại (Current VI)', 'Bản Dịch Chính Thức Mới (Official VI)', 'Ghi Chú (Notes)'].join(','),
    ...entries.map((e) => [
      escapeCsv(e.category),
      escapeCsv(e.key),
      escapeCsv(e.zh_CN),
      escapeCsv(e.current_vi),
      '""', // Empty cell for user to fill in
      escapeCsv(e.notes || ''),
    ].join(',')),
  ];

  const csvPath = path.join(outDir, 'ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv');
  fs.writeFileSync(csvPath, '\ufeff' + csvRows.join('\r\n'), 'utf8');
  console.log('Saved CSV sheet:', csvPath);

  // 3. Also generate a structured Markdown document broken down by sections for easy viewing/reading
  const mdPath = path.join(outDir, 'ZH_CN_ORIGINAL_CATALOG.md');
  const catNames: Record<TranslationEntry['category'], string> = {
    Card_Name: '1. Tên Thẻ Bài & Trang Bị (Cards & Equipments)',
    Card_Description: '2. Mô Tả Thẻ Bài & Trang Bị (Card Descriptions)',
    Card_Skill_Prompt: '3. Kỹ Năng & Lời Nhắc Thẻ Bài (Card Skills & Prompts)',
    System_UI: '4. Giao Diện, Nút Bấm & Trạng Thái Hệ Thống (System UI & Status)',
    GameLog_Event: '5. Mẫu Nhật Ký Trận Đấu & Sự Kiện (GameLog & Events)',
    Variant_Event: '6. Biến Thể Quốc Chiến & Sự Kiện Vòng (Hegemony Variants & Round Events)',
    General_Name: '7. Danh Sách Võ Tướng Quốc Chiến (Hegemony Generals)',
    General_Skill_Name: '8. Tên Kỹ Năng Võ Tướng (General Skill Names)',
    General_Skill_Description: '9. Mô Tả Kỹ Năng Võ Tướng (General Skill Descriptions)',
    General_Skill_Prompt: '10. Lời Nhắc Kích Hoạt Kỹ Năng (Skill Invoke Prompts)',
  };

  const mdSections: string[] = [
    '# Danh Mục Ngôn Ngữ Hiển Thị Gốc Tiếng Trung (zh_CN) - FreeKill Quốc Chiến',
    '',
    `> Được trích xuất trực tiếp từ runtime Lua và 14 packages gốc FreeKill vào ngày ${new Date().toLocaleDateString('vi-VN')}.`,
    `> Tổng cộng: **${entries.length} mục ngôn ngữ hiển thị gốc** (chia làm 10 nhóm).`,
    '',
    'Bạn có thể chỉnh sửa trực tiếp vào file CSV [`ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv`](./ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv) bằng Google Sheets hoặc Excel rồi gửi lại để cập nhật toàn diện vào game.',
    '',
  ];

  const grouped = new Map<TranslationEntry['category'], TranslationEntry[]>();
  for (const e of entries) {
    const list = grouped.get(e.category) || [];
    list.push(e);
    grouped.set(e.category, list);
  }

  for (const [cat, title] of Object.entries(catNames) as [TranslationEntry['category'], string][]) {
    const list = grouped.get(cat) || [];
    if (list.length === 0) continue;
    mdSections.push(`## ${title} (${list.length} mục)`);
    mdSections.push('');
    mdSections.push('| Key | Gốc tiếng Trung (zh_CN) | Bản dịch hiện tại | Bản dịch chính thức | Ghi chú |');
    mdSections.push('| --- | --- | --- | --- | --- |');
    for (const item of list) {
      const cleanZh = item.zh_CN.replace(/\|/g, '\\|').replace(/\r?\n/g, '<br/>');
      const cleanVi = item.current_vi.replace(/\|/g, '\\|').replace(/\r?\n/g, '<br/>');
      const cleanNote = (item.notes || '').replace(/\|/g, '\\|');
      mdSections.push(`| \`${item.key}\` | ${cleanZh} | ${cleanVi} | | ${cleanNote} |`);
    }
    mdSections.push('');
  }

  fs.writeFileSync(mdPath, mdSections.join('\n'), 'utf8');
  console.log('Saved Markdown catalog:', mdPath);

  runtime.close();
}

main().catch(console.error);
