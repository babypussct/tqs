import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, renameSync, rmSync, realpathSync, lstatSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { UPSTREAM_PACKAGES } from './upstream-packages.ts';

function git(args, cwd, input) {
  return execFileSync('git', args, { cwd, input, encoding: 'utf8', timeout: 180_000,
    maxBuffer: 16 * 1024 * 1024, stdio: ['pipe', 'pipe', 'pipe'],
    env: { ...process.env, GIT_TERMINAL_PROMPT: '0' } });
}

export function verifyUpstream(directory, spec) {
  assert.ok(!lstatSync(directory).isSymbolicLink(), `Refusing symlink checkout: ${spec.name}`);
  assert.equal(git(['rev-parse', 'HEAD'], directory).trim(), spec.commit, `Wrong pinned commit: ${spec.name}; existing checkout was preserved`);
  assert.equal(git(['status', '--porcelain'], directory).trim(), '', `Dirty upstream checkout: ${spec.name}; existing changes were preserved`);
}

export function preparePackage(sourceRoot, spec, checkOnly = false) {
  assert.match(spec.commit, /^[a-f0-9]{40}$/);
  assert.match(spec.sourceDirectory, /^[A-Za-z0-9_-]+$/);
  const directory = path.join(sourceRoot, spec.sourceDirectory);
  if (existsSync(directory)) { verifyUpstream(directory, spec); return 'verified'; }
  // Detect dangling symlinks too; never replace an existing source path.
  try { lstatSync(directory); throw new Error(`Existing upstream path: ${spec.name}`); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  assert.ok(!checkOnly, `Missing upstream checkout: ${spec.name}; run prepare:upstream first`);
  mkdirSync(sourceRoot, { recursive: true });
  const temporary = mkdtempSync(path.join(sourceRoot, `.${spec.sourceDirectory}-`));
  try {
    git(['init', '-q'], temporary);
    git(['remote', 'add', 'origin', spec.url], temporary);
    git(['fetch', '--depth=1', '--filter=blob:none', 'origin', spec.commit], temporary);
    const files = git(['ls-tree', '-rz', '--name-only', spec.commit], temporary).split('\0')
      .filter((name) => /\.(lua|json|md|qml|js)$/i.test(name));
    assert.ok(files.length > 0, `No runtime source files: ${spec.name}`);
    // Exact sparse patterns avoid downloading card/audio binaries for Lua audits.
    const patterns = files.map((name) => '/' + name.replace(/[\\*?\[\]!#]/g, '\\$&'));
    git(['sparse-checkout', 'set', '--no-cone', '--stdin'], temporary, patterns.join('\n') + '\n');
    git(['checkout', '-q', '--detach', spec.commit], temporary);
    verifyUpstream(temporary, spec);
    renameSync(temporary, directory);
    return 'fetched';
  } finally {
    // Only the unique temporary directory created above may be removed.
    rmSync(temporary, { recursive: true, force: true });
  }
}

function main() {
  let sourceRoot = fileURLToPath(new URL('../../../scratch/upstream/', import.meta.url));
  let selected = UPSTREAM_PACKAGES;
  let checkOnly = false;
  for (let i = 2; i < process.argv.length; i++) {
    const arg = process.argv[i];
    if (arg === '--check') checkOnly = true;
    else if (arg === '--root' && process.argv[i + 1]) sourceRoot = path.resolve(process.argv[++i]);
    else if (arg === '--package' && process.argv[i + 1]) {
      const name = process.argv[++i];
      selected = UPSTREAM_PACKAGES.filter((spec) => spec.name === name);
      assert.equal(selected.length, 1, 'Unknown pinned package');
    } else throw new Error('Usage: prepare-upstream.mjs [--check] [--root DIRECTORY] [--package NAME]');
  }
  for (const spec of selected) console.log(`PASS ${preparePackage(sourceRoot, spec, checkOnly)} ${spec.name}@${spec.commit}`);
}

if (process.argv[1] && existsSync(process.argv[1]) && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) main();
