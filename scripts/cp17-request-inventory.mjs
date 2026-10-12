#!/usr/bin/env node

// CP17 request inventory. This intentionally scans the exact Lua runtime
// snapshot used by the current mobile candidate instead of the upstream
// checkout, so the report is tied to the package revisions the server sees.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = fileURLToPath(new URL('../', import.meta.url));
const defaultRuntime = path.join(repoRoot, 'scratch/deployments/cp16-candidate/release/runtime');
const runtimeRoot = path.resolve(process.argv[2] ?? defaultRuntime);
const packagesRoot = path.join(runtimeRoot, 'packages');

const definitions = new Set([
  'freekill-core/ltk/server/room.lua',
  'freekill-core/ltk/client/client.lua',
]);

const inventory = [
  {
    key: 'askToChoice',
    pattern: /\baskToChoice\s*\(/g,
    command: 'AskForChoices',
    renderer: 'ChoicePanel',
    status: 'renderer + fixture PASS; hosted rule-specific live evidence still open',
    priority: 'P1',
  },
  {
    key: 'askToChoices',
    pattern: /\baskToChoices\s*\(/g,
    command: 'AskForChoices',
    renderer: 'ChoicePanel',
    status: 'renderer + fixture PASS; hosted rule-specific live evidence still open',
    priority: 'P1',
  },
  {
    key: 'askToChooseCard',
    pattern: /\baskToChooseCard\s*\(/g,
    command: 'AskForCardChosen',
    renderer: 'CardSelectionPanel · single',
    status: 'prior targeted hosted PASS: Bàng Đức/jianchu hidden-card; CP19 broad caller matrix remains open',
    priority: 'P0',
  },
  {
    key: 'askToChooseCards',
    pattern: /\baskToChooseCards\s*\(/g,
    command: 'AskForPoxi',
    renderer: 'CardSelectionPanel · multi',
    status: 'prior targeted hosted PASS: Đặng Chi/weimeng selected-2; CP19 broad caller matrix remains open',
    priority: 'P0',
  },
  {
    key: 'askToChooseCardsAndChoice',
    pattern: /\baskToChooseCardsAndChoice\s*\(/g,
    command: 'AskForCardsAndChoice',
    renderer: 'CardsAndChoicePanel',
    status: 'prior targeted hosted PASS: Tưởng Khâm/shangyi cards-0 + choice; CP19 broad caller matrix remains open',
    priority: 'P0',
  },
  {
    key: 'askToChooseCardsAndPlayers',
    pattern: /\baskToChooseCardsAndPlayers\s*\(/g,
    command: 'AskForUseActiveSkill',
    renderer: 'GameBoardScreen · GameplayControls · Lua scene',
    status: 'renderer + fixture PASS; rescue/duel/founding-kingdom live cases open',
    priority: 'P0',
  },
  {
    key: 'askToUseActiveSkill',
    pattern: /\baskToUseActiveSkill\s*\(/g,
    command: 'AskForUseActiveSkill',
    renderer: 'GameBoardScreen · GameplayControls · Lua scene',
    status: 'renderer + fixture PASS; view-as and rule-specific live cases open',
    priority: 'P0',
  },
  {
    key: 'askToUseCard',
    pattern: /\baskToUseCard\s*\(/g,
    command: 'AskForUseCard',
    renderer: 'GameBoardScreen · GameplayControls · Lua scene',
    status: 'renderer + fixture PASS; response-card live matrix open',
    priority: 'P1',
  },
  {
    key: 'askToChooseToMoveCardInBoard',
    pattern: /\baskToChooseToMoveCardInBoard\s*\(/g,
    command: 'AskForMoveCardInBoard',
    renderer: 'NativeDialogPanel · boardMove',
    status: 'renderer + fixture PASS; no current hosted evidence',
    priority: 'P0',
  },
  {
    key: 'askToArrangeCards',
    pattern: /\baskToArrangeCards\s*\(/g,
    command: 'AskForArrangeCards',
    renderer: 'NativeDialogPanel · arrange',
    status: 'renderer + fixture PASS; no current hosted evidence',
    priority: 'P0',
  },
  {
    key: 'askToAG',
    pattern: /\baskToAG\s*\(/g,
    command: 'AskForAG',
    renderer: 'NativeDialogPanel · ag',
    status: 'renderer + fixture PASS; enabled core callsite exists; no current hosted evidence',
    priority: 'P2',
  },
  {
    key: 'askToCustomDialog',
    pattern: /\baskToCustomDialog\s*\(/g,
    command: 'CustomDialog',
    renderer: 'NativeDialogPanel · whitelisted QML only',
    status: 'renderer + fixture PASS; live ChooseSkill/known-both/card-name cases open',
    priority: 'P0',
  },
  {
    key: 'askToChooseSkills',
    pattern: /\baskToChooseSkills\s*\(/g,
    command: 'CustomDialog',
    renderer: 'NativeDialogPanel · skills',
    status: 'renderer + fixture PASS; no current hosted evidence',
    priority: 'P0',
  },
  {
    key: 'askToChooseGeneralsAndChoice',
    pattern: /\baskToChooseGeneralsAndChoice\s*\(/g,
    command: 'CustomDialog',
    renderer: 'NativeDialogPanel · generalsAndChoice',
    status: 'renderer + fixture PASS; initial-general live is separate',
    priority: 'P0',
  },
  {
    key: 'askForChooseCardNames',
    pattern: /\baskForChooseCardNames\s*\(/g,
    command: 'CustomDialog',
    renderer: 'NativeDialogPanel · cardNames',
    status: 'renderer + fixture PASS; no current hosted evidence',
    priority: 'P0',
  },
  {
    key: 'askForSkillInvoke',
    pattern: /\baskForSkillInvoke\s*\(/g,
    command: 'AskForSkillInvoke',
    renderer: 'SkillInvokePanel',
    status: 'renderer + fixture PASS; direct package callsite is parser/client-defined',
    priority: 'P1',
  },
];

function walk(dir) {
  const files = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...walk(full));
    else if (entry.isFile() && entry.name.endsWith('.lua')) files.push(full);
  }
  return files;
}

function relative(file) {
  return path.relative(packagesRoot, file).split(path.sep).join('/');
}

function findMatches(file, def) {
  const source = readFileSync(file, 'utf8');
  const matches = [];
  for (const [index, line] of source.split(/\r?\n/).entries()) {
    def.pattern.lastIndex = 0;
    if (def.pattern.test(line)) matches.push({ file: relative(file), line: index + 1, text: line.trim() });
  }
  return matches;
}

function isNonInteractive(def, match) {
  if (def.key === 'askForSkillInvoke' && match.file.endsWith('freekill-core/lua/lib/fkparser.lua')) return true;
  if (def.key === 'askToChooseCards' &&
      (/\bSmartAI:askToChooseCards\b/.test(match.text) || /(?:\.ai|\bai):askToChooseCards\b/.test(match.text))) return true;
  return false;
}

if (!statSync(packagesRoot, { throwIfNoEntry: false })?.isDirectory()) {
  throw new Error(`Không tìm thấy packages trong runtime snapshot: ${packagesRoot}`);
}

const files = walk(packagesRoot).filter((file) => !definitions.has(relative(file)));
const rows = inventory.map((def) => {
  const matches = files.flatMap((file) => findMatches(file, def));
  return { ...def, matches, interactiveMatches: matches.filter((match) => !isNonInteractive(def, match)) };
});
const packageCounts = new Map();
for (const file of files) {
  const pkg = relative(file).split('/')[0];
  packageCounts.set(pkg, (packageCounts.get(pkg) ?? 0) + 1);
}

const output = [];
output.push('# CP17 request inventory');
output.push('');
output.push(`- Runtime snapshot: \`${path.relative(repoRoot, runtimeRoot) || '.'}\``);
output.push(`- Lua files scanned: ${files.length}`);
output.push(`- Package roots: ${[...packageCounts.entries()].map(([name, count]) => `\`${name}\` (${count})`).join(', ')}`);
output.push('- Method counts exclude the two FreeKill core definition files (`ltk/server/room.lua`, `ltk/client/client.lua`); helper and AI source callsites remain visible and are not silently treated as live human evidence.');
output.push('');
output.push('| Priority | Runtime method | Wire request | Renderer | Interactive callers | All matches | Current evidence |');
output.push('| --- | --- | --- | --- | ---: | --- |');
for (const row of rows) {
  output.push(`| ${row.priority} | \`${row.key}\` | \`${row.command}\` | ${row.renderer} | ${row.interactiveMatches.length} | ${row.matches.length} | ${row.status} |`);
}
output.push('');
output.push('## Callsite details');
output.push('');
for (const row of rows) {
  output.push(`### \`${row.key}\` → \`${row.command}\` (${row.interactiveMatches.length} interactive / ${row.matches.length} all)`);
  output.push('');
  if (!row.matches.length) {
    output.push('_Không tìm thấy callsite trong enabled-package snapshot._');
  } else {
    for (const match of row.matches) output.push(`- \`${match.file}:${match.line}\` — \`${match.text.replaceAll('`', "'")}\``);
  }
  output.push('');
}

output.push('## Interpretation');
output.push('');
output.push('- `AskForCardChosen` đã có một bằng chứng live cho lựa chọn trang bị công khai; chọn lá úp và `AskForPoxi` nhiều lá vẫn là P0 cần đóng trên server thật.');
output.push('- `AskForCardsAndChoice` có hai callsite gameplay thực tế (`zongpei`, `shangyi`) nhưng hiện chỉ có fixture/contract evidence; cần một ván live có cả phần xem/chọn bài và choice.');
output.push('- Cứu Đào, quyết chiến/lập quốc và view-as đi qua `AskForUseActiveSkill`/`AskForUseCard`, vì vậy phải kiểm tra Lua scene + reply CBOR của gameplay request chứ không chỉ thêm panel React.');
output.push('- ArrangeCards, MoveCardInBoard và các CustomDialog đã có renderer whitelisted, nhưng chưa có hosted evidence tương ứng; `AskForAG` có caller trong core standard nhưng vẫn xếp sau các request P0 đang có caller gameplay rõ ràng.');
output.push('- Bước triển khai kế tiếp theo thứ tự: Poxi/card-chosen hidden → CardsAndChoice → rescue/duel/founding-kingdom/view-as → native dialogs → raw Vietnamese strings → responsive prompt/log/result/reconnect/error audit.');

console.log(output.join('\n'));
