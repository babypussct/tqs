import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

// Keep the release gate compatible with the currently deployed native server.
// Optional upstream packs are still inventoried and included when present;
// this list only defines the minimum runtime needed by the web client.
const REQUIRED_PACKAGES = [
  'freekill-core', 'hegemony', 'utility', 'gamemode', 'standard_ex', 'shzl', 'yj',
  'mobile', 'sp', 'tenyear', 'overseas', 'ol',
];
const SERVER_ONLY_PACKAGES = new Set(['tqs_qa']);
const SERVER_ONLY_PATH_SEGMENTS = new Set(['qa_packages', 'tqs_qa']);
const REQUIRED_FILES = [
  'dist/index.html', 'runtime/flist.txt', 'gateway/package.json',
  'gateway/package-lock.json', 'gateway/src/server.mjs',
  'Dockerfile.gateway', 'Dockerfile.render', 'compose.yaml', 'Caddyfile', 'env.example', 'render.yaml',
];
const SENSITIVE_NAMES = new Set(['credentials.json', 'secrets.json']);

function isSensitive(name) {
  const lower = name.toLowerCase();
  return lower === '.env' || lower.startsWith('.env.') || lower.endsWith('.pem') ||
    lower.endsWith('.key') || SENSITIVE_NAMES.has(lower);
}

function isServerOnlyPath(name) {
  return String(name).split('/').filter(Boolean).some((part) => SERVER_ONLY_PATH_SEGMENTS.has(part));
}

function safeRelativePath(name) {
  return typeof name === 'string' && name.length > 0 && !name.includes('\\') &&
    !path.posix.isAbsolute(name) && !name.split('/').includes('..') &&
    !name.split('/').some((part) => part === '' || isSensitive(part));
}

function actualInventory(root) {
  const files = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const absolute = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`Release contains a symlink: ${path.relative(root, absolute)}`);
      if (entry.isDirectory()) walk(absolute);
      else if (entry.isFile()) {
        if (isSensitive(entry.name)) throw new Error(`Release contains a sensitive file: ${path.relative(root, absolute)}`);
        const relative = path.relative(root, absolute).split(path.sep).join('/');
        if (isServerOnlyPath(relative)) throw new Error(`Release contains a server-only QA path: ${relative}`);
        if (relative !== 'RELEASE.json') files.push(relative);
      } else throw new Error(`Unsupported release entry: ${absolute}`);
    }
  };
  walk(root);
  return files.sort();
}

export function verifyRelease(rootArg) {
  if (!rootArg) throw new Error('Usage: node deploy/mobile/verify-release.mjs /release');
  const root = path.resolve(rootArg);
  if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) throw new Error(`Release directory is missing: ${root}`);
  const manifestPath = path.join(root, 'RELEASE.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  if (manifest.schemaVersion !== 2) throw new Error('Unsupported or missing release manifest schemaVersion');
  if (!Array.isArray(manifest.packages) || manifest.packages.length === 0 ||
      [...manifest.packages].sort().join('\0') !== manifest.packages.join('\0') ||
      new Set(manifest.packages).size !== manifest.packages.length ||
      manifest.packages.some((name) => SERVER_ONLY_PACKAGES.has(name)) ||
      REQUIRED_PACKAGES.some((name) => !manifest.packages.includes(name)))
    throw new Error('Release package list is invalid');
  if (!manifest.files || typeof manifest.files !== 'object' || Array.isArray(manifest.files))
    throw new Error('Release file inventory is missing');

  const actual = actualInventory(root);
  const expected = Object.keys(manifest.files).sort();
  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error('Release inventory mismatch');
  for (const [name, hash] of Object.entries(manifest.files)) {
    if (!safeRelativePath(name) || !/^[a-f0-9]{64}$/i.test(String(hash))) throw new Error(`Invalid manifest entry: ${name}`);
    const file = path.resolve(root, name);
    if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) throw new Error(`Invalid manifest path: ${name}`);
    const actualHash = crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
    if (actualHash !== String(hash).toLowerCase()) throw new Error(`Hash mismatch: ${name}`);
  }

  for (const name of REQUIRED_FILES) if (!Object.prototype.hasOwnProperty.call(manifest.files, name))
    throw new Error(`Required release file is missing: ${name}`);
  const packageRoot = path.join(root, 'runtime/packages');
  const actualPackages = fs.readdirSync(packageRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
    .map((entry) => entry.name).sort();
  if (actualPackages.some((name) => SERVER_ONLY_PACKAGES.has(name)))
    throw new Error('Server-only package found in mobile release runtime');
  if (JSON.stringify(actualPackages) !== JSON.stringify(manifest.packages)) throw new Error('Runtime package inventory mismatch');
  const count = (prefix) => actual.filter((name) => name.startsWith(prefix)).length;
  if (manifest.runtimeFileCount !== count('runtime/') || manifest.webFileCount !== count('dist/') ||
      manifest.gatewayFileCount !== count('gateway/')) throw new Error('Release file counts mismatch');
  for (const name of manifest.packages) {
    if (manifest.packageFileCounts?.[name] !== count(`runtime/packages/${name}/`))
      throw new Error(`Runtime package count mismatch: ${name}`);
  }
  const flistContents = fs.readFileSync(path.join(root, 'runtime/flist.txt'), 'utf8');
  if (flistContents.split(';').some((entry) => isServerOnlyPath(entry.split('=', 1)[0])))
    throw new Error('Server-only package found in public runtime flist');
  const flistHash = crypto.createHash('md5').update(flistContents).digest('hex');
  if (!/^[a-f0-9]{32}$/i.test(String(manifest.runtimeMD5)) || flistHash !== manifest.runtimeMD5.toLowerCase())
    throw new Error('Runtime MD5 mismatch');
  return { root, manifest, fileCount: actual.length };
}

if (process.argv[2] && process.argv[1]?.endsWith('verify-release.mjs')) {
  const result = verifyRelease(process.argv[2]);
  console.log(`PASS release verification: ${result.fileCount} files, manifest v${result.manifest.schemaVersion}`);
}
