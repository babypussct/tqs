import fs from 'node:fs';
import path from 'node:path';

function parseCSV(content: string): string[][] {
  if (content.charCodeAt(0) === 0xFEFF) content = content.slice(1);
  const rows: string[][] = [];
  let currentRow: string[] = [];
  let currentField = '';
  let insideQuotes = false;
  let i = 0;
  while (i < content.length) {
    const char = content[i];
    if (insideQuotes) {
      if (char === '"') {
        if (i + 1 < content.length && content[i + 1] === '"') {
          currentField += '"';
          i += 2;
          continue;
        } else {
          insideQuotes = false;
          i++;
          continue;
        }
      } else {
        currentField += char;
        i++;
        continue;
      }
    } else {
      if (char === '"') {
        insideQuotes = true;
        i++;
        continue;
      } else if (char === ',') {
        currentRow.push(currentField);
        currentField = '';
        i++;
        continue;
      } else if (char === '\r') {
        if (i + 1 < content.length && content[i + 1] === '\n') i++;
        currentRow.push(currentField);
        rows.push(currentRow);
        currentRow = [];
        currentField = '';
        i++;
        continue;
      } else if (char === '\n') {
        currentRow.push(currentField);
        rows.push(currentRow);
        currentRow = [];
        currentField = '';
        i++;
        continue;
      } else {
        currentField += char;
        i++;
        continue;
      }
    }
  }
  if (currentField.length > 0 || currentRow.length > 0) {
    currentRow.push(currentField);
    rows.push(currentRow);
  }
  return rows;
}

const csvPath = path.resolve('docs/translations/ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv');
const catalogJsonPath = path.resolve('docs/translations/ZH_CN_ORIGINAL_CATALOG.json');
const catalogMdPath = path.resolve('docs/translations/ZH_CN_ORIGINAL_CATALOG.md');
const outJsonPath = path.resolve('game/web/src/engine/officialTranslations.json');

const content = fs.readFileSync(csvPath, 'utf8');
const rows = parseCSV(content);
const header = rows[0];
const dataRows = rows.slice(1);

const translationsMap: Record<string, string> = {};
const catalogEntries: Array<{
  category: string;
  key: string;
  zh_CN: string;
  current_vi: string;
  official_vi: string;
  notes?: string;
}> = [];

for (const row of dataRows) {
  const [cat, key, zh, curVi, officialVi, notes] = row;
  translationsMap[key] = officialVi;
  catalogEntries.push({
    category: cat,
    key,
    zh_CN: zh,
    current_vi: curVi,
    official_vi: officialVi,
    ...(notes ? { notes } : {}),
  });
}

console.log(`Loaded ${Object.keys(translationsMap).length} translations from CSV.`);

// 1. Write officialTranslations.json
fs.writeFileSync(outJsonPath, JSON.stringify(translationsMap, null, 2), 'utf8');
console.log(`Saved ${outJsonPath} (${fs.statSync(outJsonPath).size} bytes).`);

// 2. Write ZH_CN_ORIGINAL_CATALOG.json
fs.writeFileSync(catalogJsonPath, JSON.stringify(catalogEntries, null, 2), 'utf8');
console.log(`Saved ${catalogJsonPath} (${fs.statSync(catalogJsonPath).size} bytes).`);

// 3. Write ZH_CN_ORIGINAL_CATALOG.md
const categories = [
  { id: 'Card_Name', title: '1. Tên Thẻ Bài & Trang Bị (Cards & Equipments)' },
  { id: 'Card_Description', title: '2. Mô Tả Chi Tiết Thẻ Bài & Trang Bị (Card Descriptions)' },
  { id: 'Card_Skill_Prompt', title: '3. Câu Nhắc Kích Hoạt Kỹ Năng Thẻ Bài (Card Skill Prompts)' },
  { id: 'System_UI', title: '4. Thuật Ngữ Giao Diện, Nút Bấm & Giai Đoạn (System UI & Controls)' },
  { id: 'GameLog_Event', title: '5. Diễn Biến & Nhật Ký Trận Đấu (GameLog & Events)' },
  { id: 'Variant_Event', title: '6. Sự Kiện Chế Độ Quốc Chiến & Đấu Trường Sinh Tử (Variant Events)' },
  { id: 'General_Name', title: '7. Tên Toàn Bộ Võ Tướng Trong Game (All Generals)' },
  { id: 'General_Skill_Name', title: '8. Tên Toàn Bộ Kỹ Năng Tướng (General Skill Names)' },
  { id: 'General_Skill_Description', title: '9. Mô Tả Chi Tiết Kỹ Năng Tướng (General Skill Descriptions)' },
  { id: 'General_Skill_Prompt', title: '10. Câu Nhắc Kích Hoạt Kỹ Năng Tướng (General Skill Invoke Prompts)' },
];

let md = `# Danh Mục Ngôn Ngữ Hiển Thị Gốc Tiếng Trung (zh_CN) & Bản Dịch Chính Thức - FreeKill Quốc Chiến\n\n`;
md += `> Được trích xuất trực tiếp từ runtime Lua và 14 packages gốc FreeKill.\n`;
md += `> Tổng cộng: **${catalogEntries.length} mục ngôn ngữ hiển thị gốc** (chia làm 10 nhóm).\n`;
md += `> Đã cập nhật 100% bản dịch tiếng Việt chính thức.\n\n`;
md += `Bảng tính CSV đầy đủ: [\`ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv\`](./ZH_CN_ORIGINAL_TRANSLATION_SHEET.csv)\n\n`;

for (const cat of categories) {
  const catEntries = catalogEntries.filter(e => e.category === cat.id);
  md += `## ${cat.title} (${catEntries.length} mục)\n\n`;
  md += `| Key | Gốc tiếng Trung (zh_CN) | Bản dịch hiện tại | Bản dịch chính thức | Ghi chú |\n`;
  md += `| --- | --- | --- | --- | --- |\n`;
  for (const entry of catEntries) {
    const sanitize = (s: string) => (s || '').replace(/\|/g, '\\|').replace(/\n/g, '<br/>');
    md += `| \`${entry.key}\` | ${sanitize(entry.zh_CN)} | ${sanitize(entry.current_vi)} | ${sanitize(entry.official_vi)} | ${sanitize(entry.notes || '')} |\n`;
  }
  md += `\n`;
}

fs.writeFileSync(catalogMdPath, md.replace(/\n+$/, '\n'), 'utf8');
console.log(`Saved ${catalogMdPath} (${fs.statSync(catalogMdPath).size} bytes).`);
