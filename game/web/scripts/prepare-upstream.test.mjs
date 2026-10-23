import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { preparePackage } from './prepare-upstream.mjs';

function fixture(t) {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-upstream-test-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const upstream = path.join(root, 'upstream');
  mkdirSync(upstream);
  const git = (...args) => execFileSync('git', args, { cwd: upstream, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  git('init', '-q');
  git('config', 'user.name', 'Upstream fixture');
  git('config', 'user.email', 'fixture@example.invalid');
  git('config', 'commit.gpgsign', 'false');
  git('config', 'core.hooksPath', path.join(root, 'no-hooks'));
  for (const name of ['init.lua', 'skills/test.lua', 'readme.md', 'data.json', 'image/large.png']) {
    mkdirSync(path.dirname(path.join(upstream, name)), { recursive: true });
    writeFileSync(path.join(upstream, name), name);
  }
  git('add', '.');
  git('commit', '-qm', 'pin');
  return { root, spec: { name: 'fixture', sourceDirectory: 'fixture', url: upstream, commit: git('rev-parse', 'HEAD') } };
}

test('fresh source preparation checks out the exact pin and only runtime text', (t) => {
  const { root, spec } = fixture(t);
  const sources = path.join(root, 'sources');
  assert.equal(preparePackage(sources, spec), 'fetched');
  assert.equal(readFileSync(path.join(sources, 'fixture/skills/test.lua'), 'utf8'), 'skills/test.lua');
  assert.equal(existsSync(path.join(sources, 'fixture/image/large.png')), false);
  assert.equal(preparePackage(sources, spec, true), 'verified');
});

test('wrong revision and dirty existing source are rejected without overwriting', (t) => {
  const { root, spec } = fixture(t);
  const sources = path.join(root, 'sources');
  preparePackage(sources, spec);
  assert.throws(() => preparePackage(sources, { ...spec, commit: 'f'.repeat(40) }), /Wrong pinned commit/);
  const source = path.join(sources, 'fixture/init.lua');
  writeFileSync(source, 'local change');
  assert.throws(() => preparePackage(sources, spec), /Dirty upstream/);
  assert.equal(readFileSync(source, 'utf8'), 'local change');
});

test('check mode does not create a missing checkout', (t) => {
  const { root, spec } = fixture(t);
  const sources = path.join(root, 'missing');
  assert.throws(() => preparePackage(sources, spec, true), /Missing upstream/);
  assert.equal(existsSync(sources), false);
});
