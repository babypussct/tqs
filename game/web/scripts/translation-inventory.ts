/** Read-only inventory of the actual runtime and the translations exported to React.
 * Run from any cwd: npm --prefix game/web run audit:translations
 * No match, private game state, or network is used.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { displayText } from '../src/engine/displayText';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const files = new Map<string, Uint8Array>();
const locations = new Map<string, Set<string>>();
const stringsByFile = new Map<string, Set<string>>();
function visit(dir: string) {
  for (const item of fs.readdirSync(dir, { withFileTypes: true }).sort((a,b) => a.name.localeCompare(b.name))) {
    if (item.name === '.git') continue;
    const full = path.join(dir, item.name);
    if (item.isDirectory()) visit(full);
    else if (item.isFile() && /\.(lua|json|md|qml|js)$/i.test(item.name)) {
      const relative = path.relative(path.join(root, 'runtime'), full).split(path.sep).join('/');
      const bytes = fs.readFileSync(full);
      files.set(relative, bytes);
      if (!relative.endsWith('.lua')) continue;
      const tokens = new Set<string>();
      bytes.toString('utf8').split(/\r?\n/).forEach((line, index) => {
        for (const match of line.matchAll(/(["'])([^"'\r\n]{1,300})\1/g)) {
          const key = match[2];
          tokens.add(key);
          const places = locations.get(key) ?? new Set<string>();
          places.add(`runtime/${relative}:${index + 1}`);
          locations.set(key, places);
        }
      });
      stringsByFile.set(relative, tokens);
    }
  }
}
visit(path.join(root, 'runtime/packages'));
const fingerprint = createHash('sha256');
for (const [name, bytes] of files) fingerprint.update(name).update('\0').update(bytes).update('\0');
const exported: Record<string, string> = {};
const runtime = new LuaRuntime({ files, callbacks: {
  send: () => {}, setup: () => {},
  ui: (command, data) => { if (command === 'DisplayTranslations') Object.assign(exported, data); },
  log: (level, message) => { if (level === 'error') throw new Error(message); },
} });
type Row = {key: string; zh: string; en: string; lua: string};
type Registry = {keys: string[]; skills: string[]; generals: string[]; cards: string[]; hegSkills: string[]; hegGenerals: string[]};
await runtime.start();
try {
  runtime.eval(String.raw`
    local keys, skills, generals, cards, hs, hg = {}, {}, {}, {}, {}, {}
    local seen = {}
    for _, lang in ipairs({'zh_CN','vi_VN','en_US'}) do
      for key in pairs(Fk.translations[lang] or {}) do seen[key] = true end
    end
    for key in pairs(Fk.skills or {}) do
      skills[#skills+1] = key; seen[key] = true; seen[':'..key] = true
    end
    for key,g in pairs(Fk.generals or {}) do
      generals[#generals+1] = key
      if g.package and g.package.extensionName == 'hegemony' then
        hg[#hg+1] = key
        for _,s in ipairs(g.other_skills or {}) do if type(s)=='string' then hs[#hs+1]=s end end
      end
    end
    for _,c in pairs(Fk.cards or {}) do if c.name then cards[#cards+1] = c.name end end
    for key in pairs(seen) do keys[#keys+1] = key end
    table.sort(keys)
    __inventory = {keys=keys, skills=skills, generals=generals, cards=cards, hegSkills=hs, hegGenerals=hg}
    return true
  `);
  const registry = {} as Registry;
  for (const field of ['keys','skills','generals','cards','hegSkills','hegGenerals'] as const) {
    const length = runtime.eval<number>(`return #__inventory.${field}`);
    registry[field] = [];
    for (let i=1;i<=length;i+=500) registry[field].push(...runtime.eval<string[]>(
      `local r={} for i=${i},math.min(${i+499},#__inventory.${field}) do r[#r+1]=__inventory.${field}[i] end return r`));
  }
  // Conservative dependency closure: include exact literal references in Hegemony,
  // then the implementation files of skills it references/acquires. It is a planning
  // superset, not a claim that every string is reachable in new_heg_mode.
  const relevant = new Set([...registry.hegSkills, ...registry.hegGenerals]);
  const relevantFiles = new Set<string>();
  for (const [name, tokens] of stringsByFile) {
    if (name.startsWith('packages/hegemony/') || name.startsWith('packages/utility/') ||
        name.startsWith('packages/freekill-core/lua/client/') ||
        name.startsWith('packages/freekill-core/standard_cards/') ||
        name.startsWith('packages/freekill-core/maneuvering/') ||
        name.startsWith('packages/freekill-core/standard/aux_skills_dir/')) {
      relevantFiles.add(name); for (const key of tokens) relevant.add(key);
    }
  }
  let changed = true;
  while (changed) {
    changed = false;
    for (const [name, tokens] of stringsByFile) {
      if (relevantFiles.has(name) || !name.includes('/skills/')) continue;
      const text = Buffer.from(files.get(name)!).toString('utf8');
      const names = [...text.matchAll(/\bname\s*=\s*["']([^"']+)["']/g)].map(m => m[1]);
      if (!names.some(key => relevant.has(key))) continue;
      relevantFiles.add(name); for (const key of tokens) relevant.add(key); changed = true;
    }
  }
  const skills = new Set(registry.skills), generals = new Set(registry.generals), cards = new Set(registry.cards);
  const keys = new Set([...registry.keys, ...Object.keys(exported)]);
  // Include statically referenced prompts missing even from the source language table.
  for (const [key] of locations) if (/^#[\w][\w:.-]*$/.test(key)) keys.add(key.split(':')[0]);
  const values: Row[] = [];
  const sorted = [...keys].sort();
  for (let offset=0; offset<sorted.length; offset+=32) {
    const luaKeys = sorted.slice(offset,offset+32).map(key => JSON.stringify(key)).join(',');
    values.push(...runtime.eval<Row[]>(`
      local rows = {}
      for _,key in ipairs({${luaKeys}}) do
        rows[#rows+1] = {key=key, zh=(Fk.translations.zh_CN or {})[key] or '',
          en=(Fk.translations.en_US or {})[key] or '', lua=Fk:translate(key,'vi_VN')}
      end
      return rows
    `));
  }
  const classify = (key: string) => {
    const base = key.replace(/^[:#$~@]+/, '');
    if (key.startsWith('$') || key.startsWith('~')) return 'voice_death';
    if (cards.has(base)) return key.startsWith(':') ? 'card_description' : 'card_name_prompt';
    if (generals.has(base)) return 'general_name_title';
    if (key.startsWith(':')) return 'skill_description';
    if (skills.has(key)) return 'skill_name_generated';
    if (key.startsWith('#')) return /^[A-Z]/.test(base) ? 'log_event' : 'skill_prompt';
    if (key.startsWith('@')) return 'mark_counter';
    return 'choice_ui_other';
  };
  const rows = values.map(row => {
    const ui = displayText(row.key, exported);
    const status = row.lua === row.key || !row.lua.trim() ? 'missing_or_raw'
      : /[\u3400-\u9fff]/u.test(row.lua) ? 'contains_chinese'
      : row.en && row.lua === row.en && row.en !== row.key ? 'english_or_shared_text_review'
      : 'translated_or_neutral';
    const uiStatus = !Object.hasOwn(exported, row.key) && ui === row.key && row.lua !== row.key
      ? 'not_exported_to_react' : /[\u3400-\u9fff]/u.test(ui) ? 'contains_chinese'
      : ui === row.key ? 'raw_or_neutral' : 'rendered';
    return {...row, category: classify(row.key),
      scope: relevant.has(row.key) || relevant.has(row.key.replace(/^[:#$~@]+/, ''))
        ? 'hegemony_core_dependency' : 'other_installed_or_unresolved',
      status, uiStatus, react: ui, exported: Object.hasOwn(exported,row.key),
      sources: [...(locations.get(row.key) ?? [])].sort(),
      proposed_vi: '', review: ''};
  });
  const issues = rows.filter(row => row.status !== 'translated_or_neutral' || row.uiStatus === 'not_exported_to_react');
  const countBy = (input: typeof rows, field: 'scope'|'status'|'uiStatus'|'category') =>
    input.reduce<Record<string, number>>((out,row) => { out[row[field]]=(out[row[field]]??0)+1; return out; },{});
  const summary = {scanned: rows.length, exported: Object.keys(exported).length, issues: issues.length,
    byScope: countBy(issues,'scope'), byStatus: countBy(issues,'status'), byUiStatus: countBy(issues,'uiStatus'),
    byCategory: countBy(issues,'category'),
    hegemony: {count: issues.filter(r=>r.scope==='hegemony_core_dependency').length,
      byCategory: countBy(issues.filter(r=>r.scope==='hegemony_core_dependency'),'category')}};
  const out = path.join(root,'docs/translations'); fs.mkdirSync(out,{recursive:true});
  fs.writeFileSync(path.join(out,'VIETNAMESE_GAP_INVENTORY.json'), JSON.stringify({
    schemaVersion: 1, runtimeSha256: fingerprint.digest('hex'), summary,
    limitations: ['Static registry + literal dependency closure; dynamic constructed keys and live server-expanded logs need scenario capture.',
      'Unexported Lua text is a transport gap only on React paths using displayText; it may render correctly on Lua-translated paths.',
      'Internal skills, voice keys, credits, neutral labels and shared English/Vietnamese terms require relevance review, not automatic translation.',
      'Source locations are literal references, not necessarily translation definitions. No semantic translation-quality certification.'], rows,
  },null,2)+'\n');
  const escape = (text: string) => text.replace(/\|/g,'\\|').replace(/\r?\n/g,'<br>').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  let md = '# Kiểm kê nội dung Việt hoá còn thiếu — runtime hiện hành\n\n';
  md += 'Tái tạo: `npm --prefix game/web run audit:translations`. Dữ liệu đầy đủ, gồm cả mục đã có bản dịch, nằm trong [JSON](VIETNAMESE_GAP_INVENTORY.json).\n\n';
  md += `Đã đọc **${rows.length} key**, React nhận **${summary.exported} key**. Có **${issues.length} mục cần phân loại/duyệt**, trong đó **${summary.hegemony.count}** thuộc tập bảo thủ Quốc Chiến/core/dependency. Không coi mọi mục này là lỗi nhìn thấy trong trận.\n\n`;
  md += '## Cách dùng danh sách\n\n- `missing_or_raw`: chưa có chuỗi thay key; có thể là kỹ năng nội bộ không cần hiển thị.\n- `contains_chinese`: chuỗi Lua còn ký tự Trung.\n- `english_or_shared_text_review`: trùng tiếng Anh; cần duyệt tên riêng/thuật ngữ trung tính.\n- `not_exported_to_react`: Lua có nội dung nhưng React không nhận key và displayText trả mã. Cần sửa đường chuyển bảng dịch nếu UI dùng key đó.\n- Tập Quốc Chiến là closure literal bảo thủ; nhóm ngoài tập chỉ là tham khảo, không chặn nghiệm thu Quốc Chiến.\n- Chưa bao phủ tuyệt đối key ghép động, log đã expand trên server hay chất lượng nghĩa của bản dịch. Cần chạy scenario thực tế cho các trường hợp đó. Không tự điền bản dịch hoặc thay luật.\n\n';
  for (const scope of ['hegemony_core_dependency','other_installed_or_unresolved']) {
    md += `## ${scope}\n\n`;
    for (const category of [...new Set(issues.map(r=>r.category))].sort()) {
      const group = issues.filter(r=>r.scope===scope && r.category===category);
      if (!group.length) continue;
      md += `### ${category} (${group.length})\n\n| Key | Trạng thái Lua / React | Gốc Trung | Nội dung Lua hiện tại | Nguồn tham chiếu đầu tiên |\n| --- | --- | --- | --- | --- |\n`;
      for (const row of group) md += `| \`${row.key}\` | ${row.status} / ${row.uiStatus} | ${escape(row.zh)} | ${escape(row.lua)} | ${escape(row.sources[0]??'registry/runtime')} |\n`;
      md += '\n';
    }
  }
  fs.writeFileSync(path.join(out,'VIETNAMESE_GAP_INVENTORY.md'),md);
  // A compact, editable work queue for Quốc Chiến. Keep the full catalog above as
  // provenance, including false positives, so nothing is silently discarded.
  const hegemonyIssues = issues.filter(row => row.scope === 'hegemony_core_dependency');
  const workPriority = (row: typeof rows[number]) => {
    if (['card_description','skill_description','skill_prompt','skill_name_generated','card_name_prompt','log_event'].includes(row.category)) return 'P0_GAMEPLAY_REVIEW';
    if (['mark_counter','choice_ui_other'].includes(row.category)) return 'P1_DIALOG_REVIEW';
    return 'P2_NAMES_VOICE_REVIEW';
  };
  const isLiteral = (row: typeof rows[number]) => /^#[0-9]+$|^#[0-9a-fA-F]{3,8}$/.test(row.key);
  const priorityOrder = ['P0_GAMEPLAY_REVIEW','P1_DIALOG_REVIEW','P2_NAMES_VOICE_REVIEW'];
  const queue = [...hegemonyIssues].sort((a,b) =>
    priorityOrder.indexOf(workPriority(a)) - priorityOrder.indexOf(workPriority(b)) ||
    a.category.localeCompare(b.category) || a.key.localeCompare(b.key));
  const csvEscape = (value: string) => `"${value.replace(/"/g,'""')}"`;
  const csvColumns = ['priority','review_hint','category','key','status','ui_status','zh_CN','current_lua_vi','current_react','sources','proposed_vi','review'];
  const csv = [csvColumns.join(','),...queue.map(row => [
    workPriority(row), isLiteral(row) ? 'literal_not_translation_key' :
      row.category === 'voice_death' ? 'voice_optional' :
      row.uiStatus === 'not_exported_to_react' ? 'check_react_export_path' :
      row.status === 'missing_or_raw' ? 'check_internal_key_or_missing_translation' :
      'verify_reachable_ui_and_translate',
    row.category,row.key,row.status,row.uiStatus,row.zh,row.lua,row.react,
    row.sources.join('; '),row.proposed_vi,row.review,
  ].map(value => csvEscape(String(value))).join(','))].join('\r\n')+'\r\n';
  fs.writeFileSync(path.join(out,'HEGEMONY_VIETNAMESE_WORK_QUEUE.csv'),'\ufeff'+csv);
  const reviewByPriority = Object.fromEntries(priorityOrder.map(p =>
    [p, queue.filter(row => workPriority(row) === p).length]));
  const workSummary = [
    '# Kế hoạch rà soát Việt hóa Quốc Chiến — danh sách thao tác',
    '',
    'Sinh lại bằng `npm --prefix game/web run audit:translations`. Mở [CSV phân công](HEGEMONY_VIETNAMESE_WORK_QUEUE.csv) để lọc nhóm, điền `proposed_vi` và `review`; giữ nguyên `key`, placeholder `%...`, HTML và nguồn gốc. Bản [JSON đầy đủ](VIETNAMESE_GAP_INVENTORY.json) có cả các gói ngoài Quốc Chiến.',
    '',
    `Cơ sở: **${summary.scanned.toLocaleString('en-US')} key** scan, **${summary.issues.toLocaleString('en-US')}** mục cần rà trên toàn runtime; tập bảo thủ Quốc Chiến/core/dependency có **${queue.length.toLocaleString('en-US')}** dòng. Phân nhóm công việc: **P0 ${reviewByPriority.P0_GAMEPLAY_REVIEW}**, **P1 ${reviewByPriority.P1_DIALOG_REVIEW}**, **P2 ${reviewByPriority.P2_NAMES_VOICE_REVIEW}**. Đây là công việc cần *duyệt*, chưa phải số lỗi hiển thị được chứng minh.`,
    '',
    '| Nhóm | Số dòng | Công việc kiểm tra |', '| --- | ---: | --- |',
    ...[...new Set(queue.map(r=>r.category))].sort().map(category => {
      const group=queue.filter(r=>r.category===category);
      return `| ${category} | ${group.length} | ${workPriority(group[0])} |`;
    }),
    '',
    '## Quy trình kiểm tra trước khi dịch',
    '',
    '1. Ưu tiên mô tả lá bài (`card_description`), mô tả kỹ năng (`skill_description`), yêu cầu/chọn kỹ năng (`skill_prompt`) và tên kỹ năng phát sinh (`skill_name_generated`). Kiểm tra key có thực sự được React hoặc Lua UI gọi trong `new_heg_mode` hay không.',
    '2. `contains_chinese`: duyệt dịch theo ngữ nghĩa từ nguồn Trung; `missing_or_raw`: phân biệt key nội bộ/placeholder và yêu cầu thực. `not_exported_to_react` chỉ là *khả năng* thiếu đường xuất sang React; cần xem code render trước khi kết luận.',
    '3. `#1`, `#10`, `#0598BC` và các mã số/màu tương tự là literal, đã đánh dấu `literal_not_translation_key` trong CSV; tránh dịch thành văn bản. Các dấu `%arg`, `%from`, `<b>` hoặc tên key phát sinh giữ đúng cú pháp.',
    '4. `voice_death`/tên tướng có trong file để không bỏ sót nhưng là P2. Kết quả scan tĩnh bao gồm kỹ năng của gói phụ và các khóa không tới được từ một trận Quốc Chiến; phải đối chiếu browser/native scenario. Key ghép động và server log sau expand cần quan sát bổ sung.',
    '5. Khi duyệt bản dịch kỹ năng/tướng theo nguồn ngoài runtime, dùng Moegirl làm nguồn xác minh chính thống; không thay cơ chế hoặc luật C++/Lua.',
    '',
  ].join('\n');
  fs.writeFileSync(path.join(out,'HEGEMONY_VIETNAMESE_WORK_PLAN.md'),workSummary);
  console.log(JSON.stringify(summary,null,2));
} finally { runtime.close(); }
