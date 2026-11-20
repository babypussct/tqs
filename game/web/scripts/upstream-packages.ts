import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
export const UPSTREAM_BASELINE_PATH = path.join(repositoryRoot, 'deploy/freekill-native/upstream-baseline.env');

function readBaselineEnv(file: string): Readonly<Record<string, string>> {
  const values: Record<string, string> = {};
  for (const rawLine of fs.readFileSync(file, 'utf8').split(/\r?\n/u)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const match = /^([A-Z0-9_]+)="([^"\\]*)"$/u.exec(line);
    if (!match) throw new Error(`Invalid upstream baseline assignment: ${line}`);
    values[match[1]] = match[2];
  }
  return values;
}

const baselineEnv = readBaselineEnv(UPSTREAM_BASELINE_PATH);

function baselineValue(key: string): string {
  const value = baselineEnv[key];
  if (!value) throw new Error(`Missing upstream baseline value: ${key}`);
  return value;
}

/**
 * Package contract used by the browser Lua fixtures and the native release
 * scripts. Hegemony declarations refer to skills owned by these extension
 * repositories; mounting only freekill-core/utility/hegemony silently drops
 * those strings from General:getSkillNameList().
 *
 * The exact revisions are loaded from the same checked-in manifest consumed
 * by deploy/freekill-native/versions.env. Keeping one source prevents CI's
 * sparse browser checkout and the native installer from drifting apart.
 */
export interface UpstreamPackageSpec {
  name: string;
  sourceDirectory: string;
  url: string;
  commit: string;
  role: 'core' | 'extension' | 'skill-dependency';
}

interface PackageManifestEntry {
  name: string;
  sourceDirectory: string;
  urlKey: string;
  commitKey: string;
  role: UpstreamPackageSpec['role'];
}

const PACKAGE_MANIFEST: readonly PackageManifestEntry[] = [
  { name: 'freekill-core', sourceDirectory: 'freekill-core', urlKey: 'TQS_UPSTREAM_FREEKILL_CORE_URL', commitKey: 'TQS_UPSTREAM_FREEKILL_CORE_COMMIT', role: 'core' },
  { name: 'utility', sourceDirectory: 'utility', urlKey: 'TQS_UPSTREAM_UTILITY_URL', commitKey: 'TQS_UPSTREAM_UTILITY_COMMIT', role: 'extension' },
  { name: 'hegemony', sourceDirectory: 'hegemony', urlKey: 'TQS_UPSTREAM_HEGEMONY_URL', commitKey: 'TQS_UPSTREAM_HEGEMONY_COMMIT', role: 'extension' },
  { name: 'gamemode', sourceDirectory: 'gamemode', urlKey: 'TQS_UPSTREAM_GAMEMODE_URL', commitKey: 'TQS_UPSTREAM_GAMEMODE_COMMIT', role: 'skill-dependency' },
  { name: 'standard_ex', sourceDirectory: 'standard_ex', urlKey: 'TQS_UPSTREAM_STANDARD_EX_URL', commitKey: 'TQS_UPSTREAM_STANDARD_EX_COMMIT', role: 'skill-dependency' },
  { name: 'shzl', sourceDirectory: 'shzl', urlKey: 'TQS_UPSTREAM_SHZL_URL', commitKey: 'TQS_UPSTREAM_SHZL_COMMIT', role: 'skill-dependency' },
  { name: 'yj', sourceDirectory: 'yj', urlKey: 'TQS_UPSTREAM_YJ_URL', commitKey: 'TQS_UPSTREAM_YJ_COMMIT', role: 'skill-dependency' },
  { name: 'mobile', sourceDirectory: 'mobile', urlKey: 'TQS_UPSTREAM_MOBILE_URL', commitKey: 'TQS_UPSTREAM_MOBILE_COMMIT', role: 'skill-dependency' },
  { name: 'sp', sourceDirectory: 'SP', urlKey: 'TQS_UPSTREAM_SP_URL', commitKey: 'TQS_UPSTREAM_SP_COMMIT', role: 'skill-dependency' },
  { name: 'tenyear', sourceDirectory: 'tenyear', urlKey: 'TQS_UPSTREAM_TENYEAR_URL', commitKey: 'TQS_UPSTREAM_TENYEAR_COMMIT', role: 'skill-dependency' },
  { name: 'overseas', sourceDirectory: 'overseas', urlKey: 'TQS_UPSTREAM_OVERSEAS_URL', commitKey: 'TQS_UPSTREAM_OVERSEAS_COMMIT', role: 'skill-dependency' },
  { name: 'mougong', sourceDirectory: 'mougong', urlKey: 'TQS_UPSTREAM_MOUGONG_URL', commitKey: 'TQS_UPSTREAM_MOUGONG_COMMIT', role: 'skill-dependency' },
  { name: 'jsrg', sourceDirectory: 'jsrg', urlKey: 'TQS_UPSTREAM_JSRG_URL', commitKey: 'TQS_UPSTREAM_JSRG_COMMIT', role: 'skill-dependency' },
  { name: 'ol', sourceDirectory: 'OL', urlKey: 'TQS_UPSTREAM_OL_URL', commitKey: 'TQS_UPSTREAM_OL_COMMIT', role: 'skill-dependency' },
];

export const UPSTREAM_BASELINE_ID = baselineValue('TQS_UPSTREAM_BASELINE_ID');
export const UPSTREAM_RUNTIME_OVERLAY_ID = baselineValue('TQS_UPSTREAM_RUNTIME_OVERLAY_ID');
export const UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH = baselineValue('TQS_UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH');
export const UPSTREAM_RUNTIME_OVERLAY_SHA256 = baselineValue('TQS_UPSTREAM_RUNTIME_OVERLAY_SHA256');
export const UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH = baselineValue('TQS_UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH');
export const UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT = baselineValue('TQS_UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT');
export const UPSTREAM_RUNTIME_SOURCE_PATCH_ID = baselineValue('TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_ID');
export const UPSTREAM_RUNTIME_SOURCE_PATCH_PATH = baselineValue('TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_PATH');
export const UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256 = baselineValue('TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256');
export const UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT = baselineValue('TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT');
export const UPSTREAM_PACKAGES: readonly UpstreamPackageSpec[] = PACKAGE_MANIFEST.map((entry) => ({
  name: entry.name,
  sourceDirectory: entry.sourceDirectory,
  url: baselineValue(entry.urlKey),
  commit: baselineValue(entry.commitKey),
  role: entry.role,
}));

/** Allow an isolated, caller-owned checkout to exercise the same audits. */
export function resolveUpstreamRoot(defaultRoot: string): string {
  return path.resolve(process.env.TQS_UPSTREAM_ROOT ?? defaultRoot);
}

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
  const stale = /General:new\(extension, "os_heg__duanwei", "qun", 4\):addSkills \{ "langmie" \}/u;
  const repairedDeclaration = 'General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "ty__langmie" }';
  // Prepared candidate runtimes may already contain this exact reviewed
  // declaration repair. Loading them must be idempotent; an unrelated or
  // partially edited declaration still fails closed below.
  if (source.includes(repairedDeclaration)) return bytes;
  const repaired = source.replace(stale, repairedDeclaration);
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
