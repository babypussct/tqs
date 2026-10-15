import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
// Minimum package set shared by the native server and the mobile client. The
// gamemode pack is required because active skills use its virtual card
// definitions; newer snapshots may still add optional packs. packageRelease
// includes every directory present in the supplied runtime.
export const REQUIRED_PACKAGES = [
  'freekill-core', 'hegemony', 'utility', 'gamemode', 'standard_ex', 'shzl', 'yj',
  'mobile', 'sp', 'tenyear', 'overseas', 'ol',
];
export const SERVER_ONLY_PACKAGES = ['tqs_qa'];
const SENSITIVE_NAMES = new Set(['credentials.json', 'secrets.json']);

function isSensitive(name) {
  const lower = name.toLowerCase();
  return lower === '.env' || lower.startsWith('.env.') || lower.endsWith('.pem') ||
    lower.endsWith('.key') || SENSITIVE_NAMES.has(lower);
}

/**
 * The native server may keep a server-only package under packages/ so Lua can
 * load its QA director.  That package must not participate in the public
 * client identity: the browser bundle intentionally excludes it, and the
 * public flist must therefore exclude its entries as well.
 */
export function publicFlist(contents) {
  const entries = String(contents).split(';');
  const filtered = entries.filter((entry) => !SERVER_ONLY_PACKAGES.some((name) =>
    entry.startsWith(`packages/${name}/`)));
  return filtered.length === entries.length ? String(contents) : filtered.join(';');
}

function copyTree(src, dst, filter) {
  if (!fs.existsSync(src)) throw new Error(`Release source is missing: ${src}`);
  fs.mkdirSync(dst, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name === '.git' || entry.name === 'node_modules') continue;
    if (isSensitive(entry.name)) throw new Error(`Sensitive file excluded from release: ${entry.name}`);
    if (entry.isSymbolicLink()) throw new Error(`Symlink excluded from release: ${entry.name}`);
    if (!filter(entry.name, entry.isDirectory())) continue;
    const source = path.join(src, entry.name);
    const target = path.join(dst, entry.name);
    if (entry.isDirectory()) copyTree(source, target, filter);
    else if (entry.isFile()) fs.copyFileSync(source, target);
    else throw new Error(`Unsupported release entry: ${source}`);
  }
}

function inventory(root) {
  const files = {};
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const absolute = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`Release contains a symlink: ${path.relative(root, absolute)}`);
      if (entry.isDirectory()) walk(absolute);
      else if (entry.isFile()) {
        const relative = path.relative(root, absolute).split(path.sep).join('/');
        files[relative] = crypto.createHash('sha256').update(fs.readFileSync(absolute)).digest('hex');
      } else throw new Error(`Unsupported release entry: ${absolute}`);
    }
  };
  walk(root);
  return files;
}

export function packageRelease(runtimeArg, outputArg, options = {}) {
  if (!runtimeArg || !outputArg) throw new Error('Usage: node deploy/mobile/package-release.mjs /pinned/runtime /new/release-directory');
  const runtime = path.resolve(runtimeArg);
  const output = path.resolve(outputArg);
  if (!fs.existsSync(runtime) || !fs.statSync(runtime).isDirectory()) throw new Error(`Runtime directory is missing: ${runtime}`);
  if (fs.existsSync(output)) throw new Error('Release directory must be new; never overwrite an existing release');

  const flistPath = path.join(runtime, 'flist.txt');
  const packagesPath = path.join(runtime, 'packages');
  if (!fs.existsSync(flistPath) || !fs.statSync(flistPath).isFile()) throw new Error('Pinned runtime flist.txt is missing');
  if (!fs.existsSync(packagesPath) || !fs.statSync(packagesPath).isDirectory()) throw new Error('Pinned runtime packages/ is missing');
  const packageNames = fs.readdirSync(packagesPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
    .map((entry) => entry.name).sort();
  const serverOnly = packageNames.filter((name) => SERVER_ONLY_PACKAGES.includes(name));
  if (serverOnly.length) throw new Error(`Server-only packages cannot enter a mobile release: ${serverOnly.join(', ')}`);
  const missing = REQUIRED_PACKAGES.filter((name) => !packageNames.includes(name));
  if (missing.length) throw new Error(`Pinned runtime is missing required packages: ${missing.join(', ')}`);

  const dist = path.join(repo, 'game/web/dist');
  if (!fs.existsSync(path.join(dist, 'index.html'))) throw new Error('Build web first');
  fs.mkdirSync(output, { recursive: true });
  copyTree(dist, path.join(output, 'dist'), () => true);
  copyTree(packagesPath, path.join(output, 'runtime/packages'), (name) => name !== '.git' && name !== 'node_modules');
  fs.mkdirSync(path.join(output, 'runtime'), { recursive: true });
  fs.copyFileSync(flistPath, path.join(output, 'runtime/flist.txt'));

  fs.mkdirSync(path.join(output, 'gateway'), { recursive: true });
  for (const name of ['package.json', 'package-lock.json']) {
    fs.copyFileSync(path.join(repo, 'game/gateway', name), path.join(output, 'gateway', name));
  }
  copyTree(path.join(repo, 'game/gateway/src'), path.join(output, 'gateway/src'), () => true);
  for (const name of ['Dockerfile.gateway', 'Dockerfile.render', 'compose.yaml', 'Caddyfile', 'env.example', 'render.yaml']) {
    fs.copyFileSync(path.join(repo, 'deploy/mobile', name), path.join(output, name));
  }

  const publicFlistContents = publicFlist(fs.readFileSync(flistPath, 'utf8'));
  fs.writeFileSync(path.join(output, 'runtime/flist.txt'), publicFlistContents);

  const files = inventory(output);
  const createdAt = options.createdAt ?? new Date().toISOString();
  if (typeof createdAt !== 'string' || Number.isNaN(Date.parse(createdAt))) throw new Error('Invalid release createdAt');
  const prefixCount = (prefix) => Object.keys(files).filter((name) => name.startsWith(prefix)).length;
  const packageFileCounts = Object.fromEntries(packageNames.map((name) => [
    name, prefixCount(`runtime/packages/${name}/`),
  ]));
  const manifest = {
    schemaVersion: 2,
    createdAt,
    runtimeMD5: crypto.createHash('md5').update(publicFlistContents).digest('hex'),
    packages: packageNames,
    runtimeFileCount: prefixCount('runtime/'),
    webFileCount: prefixCount('dist/'),
    gatewayFileCount: prefixCount('gateway/'),
    packageFileCounts,
    files,
  };
  fs.writeFileSync(path.join(output, 'RELEASE.json'), JSON.stringify(manifest, null, 2) + '\n');
  return { output, manifest };
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const { manifest } = packageRelease(process.argv[2], process.argv[3]);
  console.log(`Packaged ${Object.keys(manifest.files).length} files; release manifest v${manifest.schemaVersion} created`);
}
