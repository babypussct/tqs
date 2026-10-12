/**
 * Extract the original zh_CN skill labels/descriptions from the pinned Lua
 * runtime for every visible general skill reference.
 *
 * This is deliberately runtime-backed: translations in FreeKill are loaded
 * from many package files and may be concatenated or registered from init.lua.
 * A text regex alone cannot reliably reconstruct the final Chinese string.
 */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import {
  BASELINE_PACKAGE_NAMES,
  loadUpstreamFiles,
  packageSpec,
  UPSTREAM_PACKAGE_NAMES,
  type UpstreamPackageSpec,
} from './upstream-packages';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');

type Declaration = {
  general: string;
  trueName: string;
  package: string;
};

type SourceLocation = {
  upstreamPackage: string;
  commit: string;
  file: string;
  line: number;
};

type RuntimeSkill = {
  id: string;
  zhName: string;
  zhDescription: string;
  declarations: Declaration[];
  implementations: SourceLocation[];
  currentVietnameseName: string;
  currentVietnameseDescription: string;
  hasOriginalName: boolean;
  hasOriginalDescription: boolean;
};

type RuntimeResult = {
  generals: Array<Declaration & { refs: string[] }>;
  skills: Record<string, { zhName: string; zhDescription: string }>;
};

const LUA_GENERALS = String.raw`
local generals = {}
for generalName, general in pairs(Fk.generals) do
  if (not __web_skill_zh_allowed or __web_skill_zh_allowed[generalName]) and
      general.hidden ~= true and general.total_hidden ~= true then
    local refs = {}
    for _, id in ipairs(general.other_skills or {}) do
      if type(id) == "string" then
        refs[#refs + 1] = id
      end
    end
    generals[#generals + 1] = {
      general = generalName,
      trueName = general.trueName or "",
      package = general.package and general.package.name or "",
      refs = refs,
    }
  end
end
return { generals = generals }
`;

const LUA_TRANSLATIONS = String.raw`
local result = {}
for _, id in ipairs(__web_skill_zh_ids) do
  result[id] = {
    zhName = Fk:translate(id, "zh_CN"),
    zhDescription = Fk:translate(":" .. id, "zh_CN"),
  }
end
return result
`;

function ensureUpstream(): void {
  for (const name of UPSTREAM_PACKAGE_NAMES) {
    const spec = packageSpec(name);
    const root = path.join(UPSTREAM_ROOT, spec.sourceDirectory);
    assert.ok(fs.existsSync(root), `Missing pinned upstream checkout: ${root}`);
  }
}

function sourceIndex(files: Map<string, Uint8Array>): Map<string, SourceLocation[]> {
  const index = new Map<string, SourceLocation[]>();
  for (const [relativePath, bytes] of files) {
    if (!relativePath.endsWith('.lua')) continue;
    const [, packageName, ...fileParts] = relativePath.split('/');
    const spec = packageSpec(packageName);
    const lines = Buffer.from(bytes).toString('utf8').split(/\r?\n/u);
    for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      for (const match of lines[lineIndex].matchAll(/\bname\s*=\s*(["'])([^"']+)\1/gu)) {
        const id = match[2];
        const locations = index.get(id) ?? [];
        locations.push({
          upstreamPackage: spec.name,
          commit: spec.commit,
          file: fileParts.join('/'),
          line: lineIndex + 1,
        });
        index.set(id, locations);
      }
    }
  }
  return index;
}

function validateString(value: unknown, fallback: string): string {
  return typeof value === 'string' ? value : fallback;
}

async function capture(files: Map<string, Uint8Array>, allowedNames?: Set<string>): Promise<RuntimeResult> {
  const runtime = new LuaRuntime({
    files,
    language: 'zh_CN',
    callbacks: {
      send: () => {},
      setup: () => {},
      ui: () => {},
      log: (level, message) => {
        if (level === 'error') throw new Error(`Lua boot error: ${message}`);
      },
    },
  });
  try {
    await runtime.start();
    const luaAllowed = allowedNames
      ? `{${[...allowedNames].map((name) => `[${JSON.stringify(name)}] = true`).join(',')}}`
      : 'nil';
    runtime.eval(`__web_skill_zh_allowed = ${luaAllowed}; return true`);
    const generals = runtime.eval<{ generals: Array<Declaration & { refs: string[] }> }>(LUA_GENERALS).generals;
    const ids = [...new Set(generals.flatMap((general) => general.refs))].sort((a, b) => a.localeCompare(b));
    const skills: RuntimeResult['skills'] = {};
    // Keep every __host_eval result comfortably below the 1 MiB Lua JSON
    // boundary; long descriptions are valid upstream data, not an error.
    for (let offset = 0; offset < ids.length; offset += 32) {
      const batch = ids.slice(offset, offset + 32);
      const luaIds = `{${batch.map((id) => JSON.stringify(id)).join(',')}}`;
      runtime.eval(`__web_skill_zh_ids = ${luaIds}; return true`);
      Object.assign(skills, runtime.eval<RuntimeResult['skills']>(LUA_TRANSLATIONS));
    }
    return { generals, skills };
  } finally {
    runtime.close();
  }
}

function uniqueDeclarations(declarations: Declaration[]): Declaration[] {
  const seen = new Set<string>();
  return declarations
    .filter((declaration) => {
      const key = `${declaration.package}/${declaration.general}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .sort((a, b) => `${a.package}/${a.general}`.localeCompare(`${b.package}/${b.general}`));
}

function collect(files: Map<string, Uint8Array>, result: RuntimeResult): RuntimeSkill[] {
  const locations = sourceIndex(files);
  const declarations = new Map<string, Declaration[]>();
  for (const general of result.generals) {
    for (const id of general.refs) {
      const list = declarations.get(id) ?? [];
      list.push({ general: general.general, trueName: general.trueName, package: general.package });
      declarations.set(id, list);
    }
  }
  return Object.entries(result.skills)
    .map(([id, row]) => ({
      id,
      zhName: validateString(row.zhName, id),
      zhDescription: validateString(row.zhDescription, `:${id}`),
      declarations: uniqueDeclarations(declarations.get(id) ?? []),
      implementations: locations.get(id) ?? [],
      currentVietnameseName: VI_ADDITIONS[id] ?? '',
      currentVietnameseDescription: VI_ADDITIONS[`:${id}`] ?? '',
      hasOriginalName: row.zhName !== id,
      hasOriginalDescription: row.zhDescription !== `:${id}`,
    }))
    .sort((a, b) => a.id.localeCompare(b.id));
}

function packages(): UpstreamPackageSpec[] {
  return UPSTREAM_PACKAGE_NAMES.map(packageSpec);
}

function jsonReport(skills: RuntimeSkill[]) {
  return {
    generatedAt: new Date().toISOString(),
    source: 'Fk:translate(key, "zh_CN") from the pinned runtime',
    packages: packages(),
    skillCount: skills.length,
    missingOriginalNames: skills.filter((skill) => !skill.hasOriginalName).map((skill) => skill.id),
    missingOriginalDescriptions: skills.filter((skill) => !skill.hasOriginalDescription).map((skill) => skill.id),
    skills,
  };
}

function markdownReport(skills: RuntimeSkill[]): string {
  const lines = [
    '# CP20 — nguyên văn zh_CN của skill visible',
    '',
    'Tệp này được sinh từ `Fk:translate(key, "zh_CN")` sau khi boot runtime Lua với 11 package pin. Văn bản tiếng Trung bên dưới là source upstream runtime, không phải bản dịch máy và không được dựng ngược từ tiếng Anh.',
    '',
    `- Visible direct skill IDs: **${skills.length}**.`,
    `- Missing original names: **${skills.filter((skill) => !skill.hasOriginalName).length}**.`,
    `- Missing original descriptions: **${skills.filter((skill) => !skill.hasOriginalDescription).length}**.`,
    '- For duplicate/variant declarations, review the declaration package and exact implementation locations before choosing the Vietnamese wording.',
    '',
    '| ID | Tên gốc zh_CN | Mô tả gốc zh_CN | Tên Việt hiện tại | Mô tả Việt hiện tại | Declared by | Exact implementation |',
    '| --- | --- | --- | --- | --- | --- | --- |',
  ];
  for (const skill of skills) {
    const declaration = skill.declarations
      .map((item) => `${item.package}/${item.general}`)
      .join('<br>');
    const implementation = skill.implementations
      .map((item) => `${item.upstreamPackage}@${item.commit.slice(0, 12)} ${item.file}:${item.line}`)
      .join('<br>') || 'not found';
    const cell = (value: string) => value
      .replaceAll('|', '\\|')
      .replaceAll('\r\n', '<br>')
      .replaceAll('\n', '<br>');
    lines.push(`| \`${skill.id}\` | ${cell(skill.zhName)} | ${cell(skill.zhDescription)} | ${cell(skill.currentVietnameseName)} | ${cell(skill.currentVietnameseDescription)} | ${declaration} | ${implementation} |`);
  }
  return `${lines.join('\n')}\n`;
}

function typescriptReport(skills: RuntimeSkill[]): string {
  const payload = Object.fromEntries(skills.map((skill) => [skill.id, {
    zhName: skill.zhName,
    zhDescription: skill.zhDescription,
    currentVietnameseName: skill.currentVietnameseName,
    currentVietnameseDescription: skill.currentVietnameseDescription,
    declarations: skill.declarations,
    implementations: skill.implementations,
    hasOriginalName: skill.hasOriginalName,
    hasOriginalDescription: skill.hasOriginalDescription,
  }]));
  return `/** Generated from the pinned FreeKill runtime's explicit zh_CN translation table. */\nexport const ZH_SKILL_SOURCES = ${JSON.stringify(payload, null, 2)} as const;\n`;
}

ensureUpstream();
const baselineFiles = loadUpstreamFiles(UPSTREAM_ROOT, BASELINE_PACKAGE_NAMES, { patchDeclarations: false });
const baseline = await capture(baselineFiles);
const baselineVisibleNames = new Set(baseline.generals
  .filter((general) => general.package && general.package !== '' )
  .map((general) => general.general));
const files = loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES, { patchDeclarations: true });
const skills = collect(files, await capture(files, baselineVisibleNames));
const mode = process.argv.find((arg) => arg === '--json' || arg === '--markdown' || arg === '--typescript') ?? '--json';
if (mode === '--markdown') process.stdout.write(markdownReport(skills));
else if (mode === '--typescript') process.stdout.write(typescriptReport(skills));
else process.stdout.write(`${JSON.stringify(jsonReport(skills), null, 2)}\n`);
