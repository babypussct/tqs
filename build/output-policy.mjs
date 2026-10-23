import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, lstatSync, readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';

export const SHOP_OUTPUT = 'dist-shop';

// Run before Vite can empty its destination, including direct `vite build` calls.
export function assertShopOutput(root, outDir) {
  const destination = path.resolve(root, outDir);
  assert.equal(destination, path.join(root, SHOP_OUTPUT), 'Shop output must be dist-shop; legacy dist is protected');
  // lstat also detects a dangling symlink, which existsSync cannot detect.
  try { assert.ok(!lstatSync(destination).isSymbolicLink(), 'Shop output must not be a symlink'); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (existsSync(path.join(root, '.git'))) {
    const tracked = execFileSync('git', ['ls-files', '-z', '--', SHOP_OUTPUT], { cwd: root, encoding: 'utf8' });
    assert.equal(tracked, '', 'Generated shop output must not contain Git-tracked files');
  }
  return destination;
}

export function assertVercelContract(root) {
  const vercel = JSON.parse(readFileSync(path.join(root, 'vercel.json'), 'utf8'));
  assert.equal(vercel.outputDirectory, SHOP_OUTPUT, 'Vercel outputDirectory must match dist-shop');
  assert.equal(vercel.buildCommand, 'npm run build', 'Vercel must run the guarded shop build');
  assert.equal(vercel.ignoreCommand, 'node build/vercel-ignore.mjs', 'Vercel must use the scoped build decision');
}

/** @returns {import('vite').Plugin} */
export function shopOutputGuard() {
  return {
    name: 'tqs-shop-output-guard',
    apply: 'build',
    configResolved(config) {
      assertShopOutput(config.root, config.build.outDir);
      assertVercelContract(config.root);
    },
  };
}

export function directoryDigest(directory) {
  const digest = createHash('sha256');
  let files = 0;
  function walk(current, relative = '') {
    for (const entry of readdirSync(current, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const name = path.join(relative, entry.name);
      const full = path.join(current, entry.name);
      assert.ok(!entry.isSymbolicLink(), `Protected asset must not be a symlink: ${name}`);
      if (entry.isDirectory()) { digest.update(`dir:${name}\0`); walk(full, name); }
      else {
        assert.ok(entry.isFile(), `Unsupported protected asset: ${name}`);
        digest.update(`file:${name}\0`);
        digest.update(createHash('sha256').update(readFileSync(full)).digest());
        files++;
      }
    }
  }
  const present = existsSync(directory);
  if (present) walk(directory);
  return { present, files, sha256: digest.digest('hex') };
}

export function protectedOutputs(root) {
  return Object.fromEntries(['dist', 'game/web/dist'].map((name) => [name, directoryDigest(path.join(root, name))]));
}

export function assertProtectedOutputs(root, before) {
  assert.deepEqual(protectedOutputs(root), before, 'Shop operation changed protected game outputs; preserve changes and investigate');
}
