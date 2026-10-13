import fs from 'node:fs';
import path from 'node:path';

/**
 * Package contract used by the browser Lua fixtures and the native release
 * scripts.  Hegemony declarations refer to skills owned by these extension
 * repositories; mounting only freekill-core/utility/hegemony silently drops
 * those strings from General:getSkillNameList().
 *
 * The commits are the last revisions at or before the pinned Hegemony commit
 * (2026-09-16).  They are intentionally explicit: taking the moving master
 * branch here would make the skill inventory and native package MD5 unstable.
 */
export interface UpstreamPackageSpec {
  name: string;
  sourceDirectory: string;
  url: string;
  commit: string;
  role: 'core' | 'extension' | 'skill-dependency';
}

export const UPSTREAM_PACKAGES: readonly UpstreamPackageSpec[] = [
  {
    name: 'freekill-core', sourceDirectory: 'freekill-core',
    url: 'https://gitee.com/qsgs-fans/freekill-core.git',
    commit: 'ade837d74c616dbd2d169934b0bec4a5a5dc0a85', role: 'core',
  },
  {
    name: 'utility', sourceDirectory: 'utility',
    url: 'https://gitee.com/qsgs-fans/utility.git',
    commit: 'f86d3d05b5a6835584323e56ab85db1fd87ddacf', role: 'extension',
  },
  {
    name: 'hegemony', sourceDirectory: 'hegemony',
    url: 'https://gitee.com/qsgs-fans/hegemony.git',
    commit: 'd616978ad2a53055f5815f3ae19f2d2b239862e0', role: 'extension',
  },
  {
    name: 'gamemode', sourceDirectory: 'gamemode',
    url: 'https://gitee.com/qsgs-fans/gamemode.git',
    commit: 'cf168265c56dd262ae79497cf71d55285bca4bb8', role: 'skill-dependency',
  },
  {
    name: 'standard_ex', sourceDirectory: 'standard_ex',
    url: 'https://gitee.com/qsgs-fans/standard_ex.git',
    commit: 'b041d9d4151d436bb6c357f7b772fa2f1a040df0', role: 'skill-dependency',
  },
  {
    name: 'shzl', sourceDirectory: 'shzl',
    url: 'https://gitee.com/qsgs-fans/shzl.git',
    commit: 'a6743be11ac36db4efb57c5c2546102e2be805a0', role: 'skill-dependency',
  },
  {
    name: 'yj', sourceDirectory: 'yj',
    url: 'https://gitee.com/qsgs-fans/yj.git',
    commit: '10edd0f42f492eaeece5de14a6ef19aa14560cd0', role: 'skill-dependency',
  },
  {
    name: 'mobile', sourceDirectory: 'mobile',
    url: 'https://gitee.com/qsgs-fans/mobile.git',
    commit: 'dcd523cc887e5bd010b26b7450486ab26f54d5ac', role: 'skill-dependency',
  },
  {
    name: 'sp', sourceDirectory: 'SP',
    url: 'https://gitee.com/qsgs-fans/SP.git',
    commit: 'ab42a3fbba1e15e424b942e29ac8e0157c7086fc', role: 'skill-dependency',
  },
  {
    name: 'tenyear', sourceDirectory: 'tenyear',
    url: 'https://gitee.com/qsgs-fans/tenyear.git',
    commit: '91a769c87f48006cce3e1ded90e4a1beb028f7ad', role: 'skill-dependency',
  },
  {
    name: 'overseas', sourceDirectory: 'overseas',
    url: 'https://gitee.com/qsgs-fans/overseas.git',
    commit: '6780626a34f9fdafa25e15772b9f0609c62c7999', role: 'skill-dependency',
  },
  {
    name: 'mougong', sourceDirectory: 'mougong',
    url: 'https://gitee.com/qsgs-fans/mougong.git',
    commit: '2ce058ec5aaceda4ebe3517278612a3d41e26045', role: 'skill-dependency',
  },
  {
    name: 'jsrg', sourceDirectory: 'jsrg',
    url: 'https://gitee.com/qsgs-fans/jsrg.git',
    commit: '36201e75a6afc2a6f35a96bb07f4cd9a8a983193', role: 'skill-dependency',
  },
  {
    name: 'ol', sourceDirectory: 'OL',
    url: 'https://gitee.com/qsgs-fans/OL.git',
    commit: 'ceee01b97dfc0b01eae27e6d5f2fabf6ead46413', role: 'skill-dependency',
  },
];

export const UPSTREAM_PACKAGE_NAMES = UPSTREAM_PACKAGES.map(({ name }) => name);

/** The original three-package pin used for the CP19 baseline comparison. */
export const BASELINE_PACKAGE_NAMES = ['freekill-core', 'utility', 'hegemony'] as const;

export interface DeclarationRepair {
  packageName: string;
  file: string;
  fromSkill: string;
  toSkill: string;
  ownerPackage: string;
  ownerCommit: string;
}

/**
 * Corrections whose target is an exact, pinned implementation—not a copied
 * or guessed rule variant.  Keep this list small and evidence-backed so an
 * upstream declaration cannot be silently rewritten during a package update.
 */
export const DECLARATION_REPAIRS: readonly DeclarationRepair[] = [
  {
    packageName: 'hegemony', file: 'pkg/overseas_heg/init.lua',
    fromSkill: 'langmie', toSkill: 'ty__langmie',
    ownerPackage: 'tenyear', ownerCommit: '91a769c87f48006cce3e1ded90e4a1beb028f7ad',
  },
];

const RUNTIME_EXTENSIONS = /\.(lua|json|md|qml|js)$/i;

export interface UpstreamLoadOptions {
  /** Apply evidence-backed compatibility edits to stale upstream declarations. */
  patchDeclarations?: boolean;
}

function patchDeclaration(packageName: string, relative: string, bytes: Uint8Array, enabled: boolean): Uint8Array {
  const repair = DECLARATION_REPAIRS.find((item) => item.packageName === packageName && item.file === relative);
  if (!enabled || !repair) return bytes;
  const source = Buffer.from(bytes).toString('utf8');
  // Hegemony's pinned overseas declaration names the Tenyear implementation
  // without its required prefix. The exact source owner is
  // tenyear/pkg/tenyear_huicui/skills/langmie.lua (ty__langmie), so repair
  // only this one declaration rather than inventing a second ruleset.
  const repaired = source.replace(
    /General:new\(extension, "os_heg__duanwei", "qun", 4\):addSkills \{ "langmie" \}/u,
    'General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "ty__langmie" }',
  );
  if (repaired === source) throw new Error('Expected stale langmie declaration was not found in pinned hegemony/pkg/overseas_heg/init.lua');
  return Buffer.from(repaired, 'utf8');
}

function visit(root: string, dir: string, packageName: string, files: Map<string, Uint8Array>, options: UpstreamLoadOptions) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === '.git') continue;
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) visit(root, absolute, packageName, files, options);
    else if (entry.isFile() && RUNTIME_EXTENSIONS.test(entry.name)) {
      const relative = path.relative(root, absolute).split(path.sep).join('/');
      files.set(`packages/${packageName}/${relative}`, patchDeclaration(
        packageName, relative, fs.readFileSync(absolute), options.patchDeclarations !== false,
      ));
    }
  }
}

/**
 * Mount the text/runtime part of the pinned package trees for Wasmoon.
 * Markdown is included because the pinned OL package executes a readme as a
 * Lua chunk during package boot; binary media is deliberately left out of
 * the browser fixture because it is never read by the Lua client.
 */
export function loadUpstreamFiles(
  upstreamRoot: string,
  packageNames: readonly string[] = UPSTREAM_PACKAGE_NAMES,
  options: UpstreamLoadOptions = {},
) {
  const files = new Map<string, Uint8Array>();
  for (const name of packageNames) {
    const spec = UPSTREAM_PACKAGES.find((item) => item.name === name);
    if (!spec) throw new Error(`Unknown upstream package: ${name}`);
    const root = path.join(upstreamRoot, spec.sourceDirectory);
    if (!fs.existsSync(root)) throw new Error(`Missing pinned upstream checkout: ${root}`);
    visit(root, root, name, files, options);
  }
  return files;
}

export function packageSpec(name: string): UpstreamPackageSpec {
  const spec = UPSTREAM_PACKAGES.find((item) => item.name === name);
  if (!spec) throw new Error(`Unknown upstream package: ${name}`);
  return spec;
}
