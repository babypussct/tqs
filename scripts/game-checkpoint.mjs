#!/usr/bin/env node
// Archive a reproducible web game checkpoint without committing dirty work.
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const snapshot = process.argv[2] && path.resolve(process.argv[2]);
const id = process.argv[3] ?? `web-${new Date().toISOString().replace(/[:.]/g, '-')}`;
if (!snapshot || !existsSync(path.join(snapshot, 'flist.txt')) || !/^[a-zA-Z0-9_-]+$/.test(id)) {
  throw new Error('Usage: node scripts/game-checkpoint.mjs /absolute/pinned-snapshot [release-id]');
}
const release = path.join(root, 'scratch/releases', id);
if (existsSync(release)) throw new Error('Checkpoint exists; choose a new release ID.');
if (!existsSync(path.join(root, 'game/web/dist/index.html'))) throw new Error('Build game/web first.');
const paths = ['game/web', 'game/gateway', 'scripts', 'AGENTS.md', '.gitignore',
  'package.json', 'deploy/mobile', 'docs/CODEX_STATE.md', 'docs/CODEX_PLAN.md', 'docs/web-client', 'deploy/freekill-native/versions.env'];
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
const files = [...new Set(git('ls-files', '-z', '--cached', '--others', '--exclude-standard', '--', ...paths)
  .split('\0').filter(Boolean))].filter((file) => existsSync(path.join(root, file)) &&
    !file.split('/').some((part) => /^\.env(?:\.|$)|^(?:secrets|node_modules|dist)$|\.(?:key|pem)$/i.test(part)));
mkdirSync(path.join(release, 'source'), { recursive: true });
const hashes = {};
for (const file of files) {
  const dest = path.join(release, 'source', file);
  mkdirSync(path.dirname(dest), { recursive: true });
  cpSync(path.join(root, file), dest);
  hashes[file] = createHash('sha256').update(readFileSync(dest)).digest('hex');
}
cpSync(path.join(root, 'game/web/dist'), path.join(release, 'dist'), { recursive: true });
// The generated snapshot contains only pinned package code and flist, no auth.
mkdirSync(path.join(release, 'runtime'), { recursive: true });
cpSync(path.join(snapshot, 'flist.txt'), path.join(release, 'runtime/flist.txt'));
cpSync(path.join(snapshot, 'packages'), path.join(release, 'runtime/packages'), { recursive: true,
  filter: (source) => !path.relative(snapshot, source).split(path.sep)
    .some((part) => /^\.env(?:\.|$)|^(?:\.git|secrets|node_modules)$|\.(?:key|pem)$/i.test(part)) });
const manifest = {
  id, createdAt: new Date().toISOString(), baseCommit: git('rev-parse', 'HEAD').trim(),
  sourceFiles: files.length, sourceSha256: hashes,
  md5: createHash('md5').update(readFileSync(path.join(snapshot, 'flist.txt'))).digest('hex'),
  backend: '168.110.36.224:9527',
  scope: 'Frozen web build, current game source and pinned Lua snapshot; excludes credentials and node_modules.',
};
writeFileSync(path.join(release, 'checkpoint.json'), JSON.stringify(manifest, null, 2) + '\n');
const archive = `${release}.tar.gz`;
execFileSync('tar', ['-czf', archive, '-C', path.dirname(release), id], {
  env: { ...process.env, COPYFILE_DISABLE: '1' },
});
const sha256 = createHash('sha256').update(readFileSync(archive)).digest('hex');
writeFileSync(`${archive}.sha256`, `${sha256}  ${path.basename(archive)}\n`);
console.log(JSON.stringify({ release, archive, sha256, sourceFiles: files.length, md5: manifest.md5 }));
