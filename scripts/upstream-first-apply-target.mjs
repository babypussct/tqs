#!/usr/bin/env node

// Build an isolated runtime candidate by applying only the exact source delta
// from the pinned package commits. The preserved runtime tree is copied by
// the caller; this script never writes to the repository runtime or to a live
// install. Known overlay conflicts are intentionally left for manual hunk
// review instead of being overwritten wholesale.

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, cpSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const separator = arg.indexOf('=');
  if (!arg.startsWith('--') || separator < 3) throw new Error(`Expected --key=value, got ${arg}`);
  return [arg.slice(2, separator), arg.slice(separator + 1)];
}));
for (const key of ['base', 'candidate', 'runtime', 'out']) {
  if (!args[key]) throw new Error(`Missing --${key}=...`);
}

const roots = {
  base: path.resolve(args.base),
  candidate: path.resolve(args.candidate),
  runtime: path.resolve(args.runtime),
  out: path.resolve(args.out),
};
if (roots.runtime === path.resolve(process.cwd(), 'runtime')) {
  throw new Error('Refusing to write to the repository runtime; use an isolated candidate-runtime path');
}

const packages = {
  'freekill-core': { directory: 'freekill-core', base: 'ade837d74c616dbd2d169934b0bec4a5a5dc0a85', candidate: '3c40e0f8dc54608a3b862c0cfcad80e5e61f5e02' },
  hegemony: { directory: 'hegemony', base: 'd616978ad2a53055f5815f3ae19f2d2b239862e0', candidate: 'e8d93acd34a357f96b0105aef7d661708c211626' },
};

const conflicts = new Set([
  'freekill-core/ltk/server/room.lua',
  'freekill-core/ltk/server/serverplayer.lua',
  'freekill-core/lua/server/roombase.lua',
  'hegemony/pkg/overseas_heg/init.lua',
  'hegemony/util.lua',
]);

function git(cwd, args, encoding = 'utf8') {
  return execFileSync('git', ['-C', cwd, ...args], { encoding, maxBuffer: 32 * 1024 * 1024 });
}

function diffEntries(repo, base, candidate) {
  const raw = git(repo, ['diff', '--name-status', '-z', base, candidate]);
  const tokens = raw.split('\0').filter(Boolean);
  const entries = [];
  for (let index = 0; index < tokens.length;) {
    const status = tokens[index++];
    const first = tokens[index++];
    if (!first) throw new Error(`Malformed git diff entry in ${repo}`);
    if (status.startsWith('R') || status.startsWith('C')) {
      const second = tokens[index++];
      entries.push({ status: status[0], file: second });
    } else {
      entries.push({ status: status[0], file: first });
    }
  }
  return entries;
}

const applied = [];
const skipped = [];
const deleted = [];
for (const [packageName, spec] of Object.entries(packages)) {
  const baseRepo = path.join(roots.base, spec.directory);
  const candidateRepo = path.join(roots.candidate, spec.directory);
  if (git(baseRepo, ['rev-parse', 'HEAD']).trim() !== spec.base) throw new Error(`Unexpected base SHA for ${packageName}`);
  if (git(candidateRepo, ['rev-parse', 'HEAD']).trim() !== spec.candidate) throw new Error(`Unexpected candidate SHA for ${packageName}`);

  for (const entry of diffEntries(candidateRepo, spec.base, spec.candidate)) {
    const key = `${packageName}/${entry.file}`;
    if (conflicts.has(key)) {
      skipped.push(key);
      continue;
    }
    const destination = path.join(roots.runtime, packageName, entry.file);
    if (entry.status === 'D') {
      rmSync(destination, { recursive: true, force: true });
      deleted.push(key);
      continue;
    }
    const source = path.join(candidateRepo, entry.file);
    if (!existsSync(source)) throw new Error(`Candidate source path is not materialized: ${source}`);
    mkdirSync(path.dirname(destination), { recursive: true });
    cpSync(source, destination, { recursive: true, force: true });
    applied.push(key);
  }
}

mkdirSync(roots.out, { recursive: true });
const manifest = {
  schemaVersion: 1,
  base: roots.base,
  candidate: roots.candidate,
  runtimeCandidate: roots.runtime,
  appliedCount: applied.length,
  deletedCount: deleted.length,
  skippedConflictCount: skipped.length,
  applied,
  deleted,
  skippedConflicts: skipped,
  gate: skipped.length === conflicts.size
    ? 'SOURCE_DELTA_APPLIED; FIVE_OVERLAY_CONFLICTS_REMAIN_MANUAL'
    : 'SOURCE_DELTA_APPLIED; CONFLICT_INVENTORY_INCOMPLETE',
};
writeFileSync(path.join(roots.out, 'candidate-apply-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(JSON.stringify({
  out: roots.out,
  applied: applied.length,
  deleted: deleted.length,
  skippedConflicts: skipped.length,
  gate: manifest.gate,
}));
