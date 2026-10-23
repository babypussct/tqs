import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import ts from 'typescript';
import { assertShopOutput, assertVercelContract, protectedOutputs, assertProtectedOutputs, shopOutputGuard } from './output-policy.mjs';

function fixture(t) {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-build-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const dir of ['dist', 'game/web/dist']) {
    mkdirSync(path.join(root, dir), { recursive: true });
    writeFileSync(path.join(root, dir, 'index.html'), dir);
  }
  writeFileSync(path.join(root, 'vercel.json'), JSON.stringify({ outputDirectory: 'dist-shop', buildCommand: 'npm run build', ignoreCommand: 'node build/vercel-ignore.mjs' }));
  return root;
}

test('rejects legacy, game, parent and nested output overrides before Vite empties them', (t) => {
  const root = fixture(t);
  const before = protectedOutputs(root);
  const guard = shopOutputGuard();
  for (const outDir of ['dist', 'game/web/dist', '.', '..', 'dist-shop/child', '/tmp/tqs-shop']) {
    assert.throws(() => guard.configResolved({ root, build: { outDir } }), /output must be dist-shop/);
  }
  guard.configResolved({ root, build: { outDir: 'dist-shop' } });
  assertProtectedOutputs(root, before);
});

test('rejects both existing and dangling output symlinks', (t) => {
  const root = fixture(t);
  for (const target of ['dist', 'missing']) {
    symlinkSync(target, path.join(root, 'dist-shop'));
    assert.throws(() => assertShopOutput(root, 'dist-shop'), /symlink/);
    rmSync(path.join(root, 'dist-shop'));
  }
});

test('rejects Vercel output and build-command drift', (t) => {
  const root = fixture(t);
  for (const config of [
    { outputDirectory: 'dist', buildCommand: 'npm run build' },
    { outputDirectory: 'dist-shop', buildCommand: 'vite build' },
    { outputDirectory: 'dist-shop', buildCommand: 'npm run build', ignoreCommand: 'exit 0' },
  ]) {
    writeFileSync(path.join(root, 'vercel.json'), JSON.stringify(config));
    assert.throws(() => assertVercelContract(root), /Vercel/);
  }
});

test('rejects tracked files in generated shop output', (t) => {
  const root = fixture(t);
  execFileSync('git', ['init', '-q', root]);
  mkdirSync(path.join(root, 'dist-shop'));
  writeFileSync(path.join(root, 'dist-shop/index.html'), 'tracked');
  execFileSync('git', ['add', 'dist-shop/index.html'], { cwd: root });
  assert.throws(() => assertShopOutput(root, 'dist-shop'), /Git-tracked/);
});

test('detects changed, deleted and added protected assets by content', (t) => {
  for (const mutation of ['overwrite', 'delete', 'add']) {
    const root = fixture(t);
    const before = protectedOutputs(root);
    const file = path.join(root, 'dist/index.html');
    if (mutation === 'delete') rmSync(file);
    else writeFileSync(mutation === 'add' ? path.join(root, 'game/web/dist/new.js') : file, 'mutation');
    assert.throws(() => assertProtectedOutputs(root, before), /changed protected game outputs/);
  }
});

test('repository typecheck scopes cover owned source and game tools without scratch copies', () => {
  const root = fileURLToPath(new URL('../', import.meta.url));
  const parse = (name) => {
    const filename = path.join(root, name);
    const source = ts.readConfigFile(filename, ts.sys.readFile);
    assert.equal(source.error, undefined);
    const config = ts.parseJsonConfigFileContent(source.config, ts.sys, path.dirname(filename));
    assert.deepEqual(config.errors, []);
    return config.fileNames.map((file) => path.relative(root, file).split(path.sep).join('/'));
  };
  const shop = parse('tsconfig.json');
  for (const name of ['src/App.tsx', 'api/game/session.ts', 'tests/firestore.rules.test.ts']) assert.ok(shop.includes(name));
  assert.ok(shop.every((name) => !/^(game|scratch|dist|dist-shop|spikes)\//.test(name)));
  const tools = parse('game/web/tsconfig.tools.json');
  for (const name of ['real-lua-e2e/harness.tsx', 'real-lua-e2e/run.ts', 'qa-scenarios.test.ts'])
    assert.ok(tools.includes(`game/web/scripts/${name}`));
  assert.ok(tools.every((name) => name.startsWith('game/web/scripts/')));
});

test('Vercel upload excludes legacy and local outputs while shipping the build guard', () => {
  const ignored = readFileSync(new URL('../.vercelignore', import.meta.url), 'utf8').split(/\r?\n/);
  for (const name of ['/dist/', '/dist-shop/', '/game/', '/scratch/']) assert.ok(ignored.includes(name));
  assert.ok(!ignored.includes('/build/'));
});
