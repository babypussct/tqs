#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const mode = process.argv[2];
const root = process.argv[3] && path.resolve(process.argv[3]);
if (!['--apply', '--check'].includes(mode) || !root) {
  console.error('Usage: node scripts/upstream-first-xiongsuan-compat-guard.mjs --apply|--check <candidate-hegemony-root>');
  process.exit(2);
}

const normalized = root.replaceAll(path.sep, '/');
if (!/(?:\/candidate-runtime\/packages\/hegemony|\/candidate-source\/hegemony|\/tqs-cardwire-qa-20261103-[^/]+\/packages\/hegemony)$/.test(normalized)) {
  throw new Error('Refusing to write outside an isolated upstream-first candidate Hegemony root');
}

const file = path.join(root, 'pkg/transformation/skills/xiongsuan.lua');
const before = '    local skill = player:getMark("_xiongsuan-turn")[1]\n' +
  '    target = player:getMark("_xiongsuan-turn")[2]';
const after = '    local mark = player:getTableMark("xiongsuan-turn")\n' +
  '    local skill = mark[1]\n' +
  '    target = mark[2]';
const source = fs.readFileSync(file, 'utf8');

if (source.includes(after)) {
  if (source.includes(before)) throw new Error('Candidate xiongsuan compatibility hunk is duplicated');
  console.log(`PASS isolated xiongsuan compatibility guard ${mode}: already applied`);
  process.exit(0);
}

if (source.split(before).length !== 2) {
  throw new Error('Candidate xiongsuan source diverged or compatibility hunk is ambiguous');
}
if (mode !== '--apply') {
  throw new Error('Candidate xiongsuan compatibility hunk is missing; rerun with --apply');
}
fs.writeFileSync(file, source.replace(before, after));
console.log('PASS isolated xiongsuan compatibility guard --apply: getTableMark TurnEnd hunk installed');
