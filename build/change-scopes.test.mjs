import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { changedPaths, classifyPath, classifyPaths, eventScopes, git } from './change-scopes.mjs';
import { shopBuildDecision, bootstrapIgnoreCommand } from './vercel-ignore.mjs';

function fixture(t) {
  const cwd = mkdtempSync(path.join(os.tmpdir(), 'tqs-scopes-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  git(['init', '-q', '-b', 'main'], cwd);
  git(['config', 'user.name', 'Pipeline fixture'], cwd);
  git(['config', 'user.email', 'fixture@example.invalid'], cwd);
  git(['config', 'commit.gpgsign', 'false'], cwd);
  git(['config', 'core.hooksPath', path.join(cwd, 'no-hooks')], cwd);
  const write = (file, value = file) => {
    mkdirSync(path.dirname(path.join(cwd, file)), { recursive: true });
    writeFileSync(path.join(cwd, file), value);
  };
  const commit = () => {
    git(['add', '-A'], cwd);
    git(['commit', '-qm', 'fixture change'], cwd);
    return git(['rev-parse', 'HEAD'], cwd).trim();
  };
  write('README.md');
  const base = commit();
  return { cwd, write, commit, base };
}

test('Shop files and dependencies select only Shop', () => {
  for (const name of ['src/components/Checkout.tsx', 'api/orders.ts', 'public/sw.js', 'package.json',
    'package-lock.json', 'vercel.json', 'tsconfig.json', '.vercelignore', 'scripts/shop-auth-e2e.mjs']) {
    const scopes = classifyPaths([name]);
    assert.equal(scopes.shop, true, name);
    assert.equal(scopes.game, false, name);
  }
});

test('TQSVN files, runtime, gateway and deployment inputs select only TQSVN', () => {
  for (const name of ['game/web/src/App.tsx', 'game/web/package-lock.json', 'game/web/functions/api/game/session.js',
    'runtime/packages/hegemony/init.lua', 'game/gateway/src/server.mjs', 'gateway/src/server.mjs',
    'deploy/mobile/render.yaml', 'Dockerfile.gateway', 'RELEASE.json', 'scripts/game-checkpoint.mjs']) {
    const scopes = classifyPaths([name]);
    assert.equal(scopes.shop, false, name);
    assert.equal(scopes.game, true, name);
  }
});

test('shared auth, permission, policy and pipeline changes select both', () => {
  for (const name of ['src/game/gamePoolPacks.ts', 'api/game/session.ts', 'api/_lib/auth.ts',
    'api/_lib/firebaseAdmin.ts', 'src/types.ts', 'src/components/admin/AdminGameControl.tsx',
    'src/components/admin/AdminPermissions.tsx', 'src/contexts/AuthContext.tsx', 'src/firebase.ts',
    'firestore.rules', 'tests/firestore.rules.test.ts', 'firebase.json', 'firebase-applet-config.json', 'build/change-scopes.mjs', '.github/workflows/build-safety.yml']) {
    const scopes = classifyPaths([name]);
    assert.equal(scopes.shop && scopes.game && scopes.shared, true, name);
  }
});

test('docs/legacy-only changes skip both application jobs; unknown paths check both', () => {
  const result = classifyPaths(['docs/CODEX_STATE.md', 'README.md', 'AGENTS.md', 'dist/index.html', 'scratch/file.ts']);
  assert.equal(result.shop || result.game, false);
  for (const name of ['new-tool.js', 'scripts/new-unknown.mjs', '../outside', '/absolute', 'game/../src/shop.ts', ''])
    assert.equal(classifyPath(name), 'shared', name);
});

test('deleted and renamed files across app boundaries select both old and new scopes', (t) => {
  const repo = fixture(t);
  repo.write('src/old.ts', 'unchanged contents');
  const base = repo.commit();
  mkdirSync(path.join(repo.cwd, 'game/web/src'), { recursive: true });
  git(['mv', 'src/old.ts', 'game/web/src/new.ts'], repo.cwd);
  const head = repo.commit();
  const files = changedPaths(base, head, { cwd: repo.cwd });
  assert.deepEqual(files.sort(), ['game/web/src/new.ts', 'src/old.ts']);
  assert.equal(classifyPaths(files).shop && classifyPaths(files).game, true);
});

test('push and Vercel compare the full range, including an earlier Shop commit', (t) => {
  const repo = fixture(t);
  repo.write('src/shop.ts');
  const shopCommit = repo.commit();
  repo.write('game/web/src/game.ts');
  const head = repo.commit();
  assert.equal(eventScopes('push', { before: repo.base, after: head }, repo.cwd).shop, true);
  assert.equal(shopBuildDecision({ VERCEL_GIT_PREVIOUS_SHA: repo.base, VERCEL_GIT_COMMIT_SHA: head }, repo.cwd).build, true);
  assert.equal(shopBuildDecision({ VERCEL_GIT_PREVIOUS_SHA: shopCommit, VERCEL_GIT_COMMIT_SHA: head }, repo.cwd).build, false);
});

test('PR uses merge-base and does not include changes only on the target branch', (t) => {
  const repo = fixture(t);
  git(['switch', '-qc', 'feature'], repo.cwd);
  repo.write('game/web/src/game.ts');
  const head = repo.commit();
  git(['switch', '-q', 'main'], repo.cwd);
  repo.write('src/shop.ts');
  const base = repo.commit();
  const result = eventScopes('pull_request', { pull_request: { base: { sha: base }, head: { sha: head } } }, repo.cwd);
  assert.equal(result.shop, false);
  assert.equal(result.game, true);
});

test('missing/shallow history, initial push, manual and unknown events check both', (t) => {
  const repo = fixture(t);
  for (const [event, payload] of [['push', { before: '0'.repeat(40), after: repo.base }],
    ['push', { before: 'f'.repeat(40), after: repo.base }], ['pull_request', {}], ['workflow_dispatch', {}], ['unknown', {}]]) {
    const result = eventScopes(event, payload, repo.cwd);
    assert.equal(result.shop && result.game, true);
  }
  for (const env of [{}, { VERCEL_GIT_PREVIOUS_SHA: repo.base },
    { VERCEL_GIT_PREVIOUS_SHA: 'f'.repeat(40), VERCEL_GIT_COMMIT_SHA: repo.base }])
    assert.equal(shopBuildDecision(env, repo.cwd).build, true);
});

test('NUL-delimited paths preserve whitespace, Unicode and newlines', (t) => {
  const repo = fixture(t);
  const name = 'game/web/src/tên có\nngắt dòng.ts';
  repo.write(name);
  const head = repo.commit();
  assert.deepEqual(changedPaths(repo.base, head, { cwd: repo.cwd }), [name]);
});

test('Vercel CLI convention is skip=0/build=1, and the dashboard bootstrap is usable before push', (t) => {
  const repo = fixture(t);
  for (const name of ['change-scopes.mjs', 'vercel-ignore.mjs'])
    repo.write(`build/${name}`, readFileSync(new URL(name, import.meta.url), 'utf8'));
  const base = repo.commit();
  repo.write('game/web/src/game.ts');
  const head = repo.commit();
  const env = { ...process.env, VERCEL_GIT_PREVIOUS_SHA: base, VERCEL_GIT_COMMIT_SHA: head };
  const script = path.join(repo.cwd, 'build/vercel-ignore.mjs');
  assert.equal(spawnSync(process.execPath, [script], { cwd: repo.cwd, env }).status, 0);
  assert.equal(spawnSync(process.execPath, [script], { cwd: repo.cwd, env: { ...env, VERCEL_GIT_PREVIOUS_SHA: '' } }).status, 1);
  assert.ok(bootstrapIgnoreCommand.length <= 256, 'Vercel limits ignoreCommand to 256 characters');
  assert.equal(spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env }).status, 0);
  repo.write('src/shop.ts');
  const shopHead = repo.commit();
  const nextEnv = { ...env, VERCEL_GIT_COMMIT_SHA: shopHead };
  assert.equal(spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env: nextEnv }).status, 1);
  const noBaseline = spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env: { ...env, VERCEL_GIT_PREVIOUS_SHA: '' } });
  assert.notEqual(noBaseline.status, 0);
});

test('dashboard fallback skips game-only history before the versioned script is available', (t) => {
  const repo = fixture(t);
  repo.write('game/web/src/game.ts');
  repo.commit();
  const env = { ...process.env, VERCEL_GIT_PREVIOUS_SHA: repo.base };
  assert.equal(spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env }).status, 0);
  repo.write('src/shop.ts');
  repo.commit();
  assert.equal(spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env }).status, 1);
  assert.notEqual(spawnSync('sh', ['-c', bootstrapIgnoreCommand], { cwd: repo.cwd, env: { ...env, VERCEL_GIT_PREVIOUS_SHA: '' } }).status, 0);
});

test('workflow scopes jobs individually and keeps an always-running aggregate status', () => {
  const source = readFileSync(new URL('../.github/workflows/build-safety.yml', import.meta.url), 'utf8');
  assert.match(source, /fetch-depth: 0/);
  assert.match(source, /if: needs.changes.outputs.shop == 'true'/);
  assert.match(source, /if: needs.changes.outputs.game == 'true'/);
  assert.match(source, /name: Pipeline gate[\s\S]*if: always\(\)/);
  assert.doesNotMatch(source, /pull_request_target:|paths-ignore:|\n\s+paths:/);
  const config = JSON.parse(readFileSync(new URL('../vercel.json', import.meta.url), 'utf8'));
  assert.equal(config.ignoreCommand, 'node build/vercel-ignore.mjs');
});

test('pipeline modules can be imported from stdin tools without executing a CLI', () => {
  const program = `await import(${JSON.stringify(new URL('./vercel-ignore.mjs', import.meta.url).href)}); console.log('import ok');`;
  const result = spawnSync(process.execPath, ['--input-type=module', '-'], { input: program, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout.trim(), 'import ok');
});

test('aggregate gate allows intentionally skipped apps and rejects failed, cancelled or missing required checks', () => {
  const yaml = readFileSync(new URL('../.github/workflows/build-safety.yml', import.meta.url), 'utf8');
  const body = yaml.slice(yaml.indexOf('          test "$CHANGE_RESULT"')).replace(/^          /gm, '');
  const valid = { CHANGE_RESULT: 'success', SHOP_REQUIRED: 'true', SHOP_RESULT: 'success', GAME_REQUIRED: 'false', GAME_RESULT: 'skipped' };
  const result = (extra) => spawnSync('bash', ['-e', '-c', body], { env: { ...process.env, ...valid, ...extra } }).status;
  assert.equal(result({}), 0);
  assert.equal(result({ SHOP_REQUIRED: 'false', SHOP_RESULT: 'skipped' }), 0);
  assert.equal(result({ GAME_REQUIRED: 'true', GAME_RESULT: 'success' }), 0);
  for (const overrides of [{ CHANGE_RESULT: 'failure' }, { SHOP_RESULT: 'failure' }, { SHOP_RESULT: 'cancelled' },
    { SHOP_RESULT: 'skipped' }, { GAME_REQUIRED: 'true' }, { SHOP_REQUIRED: '' }]) assert.notEqual(result(overrides), 0);
});
