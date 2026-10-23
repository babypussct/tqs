import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync, realpathSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export const root = fileURLToPath(new URL('../', import.meta.url));

// Order matters: shared contracts live inside the Shop tree today.
const sharedFiles = new Set([
  'api/_lib/auth.ts', 'api/_lib/firebaseAdmin.ts', 'src/types.ts',
  'src/components/admin/AdminGameControl.tsx', 'src/components/admin/AdminPermissions.tsx',
  'src/contexts/AuthContext.tsx', 'src/firebase.ts', 'firebase-applet-config.json',
  'firebase.json', '.firebaserc', 'firestore.rules', 'firestore.indexes.json',
  '.gitignore', '.npmrc', '.nvmrc', '.node-version', '.env.example', 'env.example',
  'tests/firestore.rules.test.ts',
]);
const sharedPrefixes = ['src/game/', 'api/game/', 'build/', '.github/'];
const gamePrefixes = ['game/', 'runtime/', 'gateway/', 'deploy/'];
const gameFiles = new Set(['Dockerfile.gateway', 'Dockerfile.render', 'Caddyfile', 'compose.yaml', 'render.yaml', 'RELEASE.json']);
const gameScripts = new Set(['scripts/game-checkpoint.mjs', 'scripts/cp17-request-inventory.mjs',
  'scripts/capture-handcard-mockup.mjs', 'scripts/generate-handcard-mockup.mjs']);
const shopPrefixes = ['src/', 'api/', 'public/', 'tests/'];
const shopFiles = new Set(['package.json', 'package-lock.json', 'vite.config.ts', 'tsconfig.json', 'vercel.json', '.vercelignore', 'index.html', 'metadata.json']);
const ignoredPrefixes = ['docs/', 'scratch/', 'spikes/', 'dist/', 'dist-shop/', '.vscode/'];
const ignoredFiles = new Set(['AGENTS.md', 'README.md', 'LICENSE', 'LICENSE.md', '.DS_Store']);

export function classifyPath(filename) {
  if (typeof filename !== 'string' || !filename || filename.startsWith('/') ||
      filename.split('/').some((part) => part === '..' || part === '.') || filename.includes('\\')) return 'shared';
  if (sharedFiles.has(filename) || sharedPrefixes.some((prefix) => filename.startsWith(prefix))) return 'shared';
  if (gameFiles.has(filename) || gameScripts.has(filename) || gamePrefixes.some((prefix) => filename.startsWith(prefix))) return 'game';
  if (shopFiles.has(filename) || shopPrefixes.some((prefix) => filename.startsWith(prefix)) || filename.startsWith('scripts/shop-')) return 'shop';
  if (ignoredFiles.has(filename) || ignoredPrefixes.some((prefix) => filename.startsWith(prefix)) || filename.startsWith('scripts/codex-')) return 'none';
  // A new/unmapped path must be reviewed by both pipelines, never silently skipped.
  return 'shared';
}

export function classifyPaths(files) {
  const paths = [...new Set(files)].map((file) => ({ file, scope: classifyPath(file) }));
  const shared = paths.some((entry) => entry.scope === 'shared');
  return {
    shop: shared || paths.some((entry) => entry.scope === 'shop'),
    game: shared || paths.some((entry) => entry.scope === 'game'),
    shared,
    paths,
  };
}

export function git(args, cwd = root) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 16 * 1024 * 1024 });
}

export function changedPaths(base, head, { cwd = root, mergeBase = false } = {}) {
  for (const sha of [base, head]) {
    if (!/^[a-f0-9]{40}$/i.test(sha) || /^0+$/.test(sha)) throw new Error('A complete nonzero commit SHA is required');
    git(['cat-file', '-e', `${sha}^{commit}`], cwd);
  }
  const previous = mergeBase ? git(['merge-base', base, head], cwd).trim() : base;
  // Disable rename detection so a move across scopes includes both old and new paths.
  return git(['diff', '--no-ext-diff', '--no-renames', '--name-only', '-z', previous, head, '--'], cwd).split('\0').filter(Boolean);
}

export function allScopes(reason) {
  return { shop: true, game: true, shared: true, paths: [], reason };
}

export function eventScopes(eventName, event, cwd = root) {
  if (eventName === 'workflow_dispatch') return allScopes('Manual verification checks both scopes');
  try {
    if (eventName === 'pull_request') return classifyPaths(changedPaths(event.pull_request.base.sha, event.pull_request.head.sha, { cwd, mergeBase: true }));
    if (eventName === 'push') return classifyPaths(changedPaths(event.before, event.after, { cwd }));
    return allScopes('Unknown event; check both scopes');
  } catch {
    return allScopes('Missing/invalid Git history; check both scopes');
  }
}

function main() {
  const args = process.argv.slice(2);
  let result;
  if (!args.length) {
    const files = git(['diff', '--no-ext-diff', '--no-renames', '--name-only', '-z', 'HEAD', '--']).split('\0');
    files.push(...git(['ls-files', '--others', '--exclude-standard', '-z']).split('\0'));
    result = classifyPaths(files.filter(Boolean));
  } else if (args.length === 1 && args[0] === '--github') {
    const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
    result = eventScopes(process.env.GITHUB_EVENT_NAME, event);
    if (!process.env.GITHUB_OUTPUT) throw new Error('GITHUB_OUTPUT is required');
    appendFileSync(process.env.GITHUB_OUTPUT, ['shop', 'game', 'shared'].map((key) => `${key}=${result[key]}\n`).join(''));
  } else if (args.length === 2) {
    result = classifyPaths(changedPaths(args[0], args[1]));
  } else throw new Error('Usage: node build/change-scopes.mjs [BASE_SHA HEAD_SHA | --github]');
  console.log(JSON.stringify(result, null, 2));
}

if (process.argv[1] && existsSync(process.argv[1]) && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) main();
