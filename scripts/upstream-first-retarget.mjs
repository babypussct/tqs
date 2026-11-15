#!/usr/bin/env node

// Reproducible U1/U2 three-way inventory:
// pinned source -> candidate source -> preserved TQS runtime.
// This script only reads the three trees and writes sanitized metadata/evidence.

import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const separator = arg.indexOf('=');
  if (!arg.startsWith('--') || separator < 3) {
    throw new Error(`Expected --key=value, got ${arg}`);
  }
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
const runtimePackagesRoot = existsSync(path.join(roots.runtime, 'runtime', 'packages'))
  ? path.join(roots.runtime, 'runtime', 'packages')
  : path.join(roots.runtime, 'packages');

const packageDirectories = {
  'freekill-core': 'freekill-core',
  utility: 'utility',
  hegemony: 'hegemony',
  gamemode: 'gamemode',
  standard_ex: 'standard_ex',
  shzl: 'shzl',
  yj: 'yj',
  mobile: 'mobile',
  sp: 'SP',
  tenyear: 'tenyear',
  overseas: 'overseas',
  mougong: 'mougong',
  jsrg: 'jsrg',
  ol: 'OL',
};

const textFile = /\.(lua|json|md|qml|js)$/iu;
const sha256 = (bytes) => bytes == null ? null : createHash('sha256').update(bytes).digest('hex');
const readBytes = (file) => {
  if (!existsSync(file) || !statSync(file).isFile()) return null;
  return readFileSync(file);
};
const same = (left, right) => {
  if (left == null || right == null) return left == null && right == null;
  return left.equals(right);
};

function listTextFiles(root, relative = '') {
  const directory = path.join(root, relative);
  if (!existsSync(directory)) return [];
  const result = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const child = relative ? path.join(relative, entry.name) : entry.name;
    if (entry.isDirectory()) result.push(...listTextFiles(root, child));
    else if (entry.isFile() && textFile.test(entry.name)) result.push(child.split(path.sep).join('/'));
  }
  return result;
}

function isGitRoot(root) {
  try {
    const top = execFileSync('git', ['-C', root, 'rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
    return path.resolve(top) === path.resolve(root);
  } catch {
    return false;
  }
}

function listTrackedTextFiles(root) {
  if (!isGitRoot(root)) return null;
  const output = execFileSync('git', ['-C', root, 'ls-tree', '-r', '-z', '--name-only', 'HEAD'], {
    encoding: 'utf8',
    maxBuffer: 16 * 1024 * 1024,
  });
  return output.split('\0').filter((file) => textFile.test(file));
}

function commit(root) {
  return execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
}

function packageTree(root, directory) {
  const treeRoot = path.join(root, directory);
  const files = listTextFiles(treeRoot);
  const result = new Map(files.map((relative) => [relative, readBytes(path.join(treeRoot, relative))]));
  const tracked = listTrackedTextFiles(treeRoot);
  if (tracked) {
    // Sparse source checkouts intentionally omit some files. Read only those
    // missing paths from the exact Git tree; materialized files are already
    // byte-identical to HEAD because source checkouts are verified clean.
    for (const relative of tracked) {
      if (!result.has(relative)) {
        result.set(relative, execFileSync(
          'git', ['-C', treeRoot, 'show', `HEAD:${relative}`], { maxBuffer: 16 * 1024 * 1024 },
        ));
      }
    }
  }
  return result;
}

function relation(base, candidate, runtime) {
  const targetChanged = !same(base, candidate);
  const runtimeChanged = !same(base, runtime);
  if (!targetChanged && !runtimeChanged) return 'unchanged';
  if (!targetChanged && runtime == null && base != null) return 'runtime_missing';
  if (!targetChanged && runtimeChanged) return 'carry_overlay';
  if (targetChanged && runtime == null) return 'target_only';
  if (targetChanged && same(runtime, candidate)) return 'absorbed_or_already_target';
  if (targetChanged && !runtimeChanged) return 'target_only';
  return 'overlay_conflict';
}

const packageRows = [];
for (const [packageName, directory] of Object.entries(packageDirectories)) {
  const baseTree = packageTree(roots.base, directory);
  const candidateTree = packageTree(roots.candidate, directory);
  const runtimeTree = packageTree(runtimePackagesRoot, packageName);
  const files = new Set([...baseTree.keys(), ...candidateTree.keys(), ...runtimeTree.keys()]);
  for (const file of [...files].sort()) {
    const base = baseTree.get(file) ?? null;
    const candidate = candidateTree.get(file) ?? null;
    const runtime = runtimeTree.get(file) ?? null;
    const state = relation(base, candidate, runtime);
    if (state === 'unchanged') continue;
    packageRows.push({
      package: packageName,
      file,
      state,
      baseSha256: sha256(base),
      candidateSha256: sha256(candidate),
      runtimeSha256: sha256(runtime),
      basePresent: base != null,
      candidatePresent: candidate != null,
      runtimePresent: runtime != null,
    });
  }
}

// A runtime package may intentionally omit README/QML source files. Missing
// runtime files are tracked separately; they are not TQS overlays merely
// because null differs from a source blob.
const overlayRows = packageRows.filter((row) => row.runtimePresent && row.runtimeSha256 !== row.baseSha256);
const runtimeMissingRows = packageRows.filter((row) => !row.runtimePresent && row.basePresent && row.candidatePresent);
const targetDeletionRows = packageRows.filter((row) => !row.runtimePresent && row.basePresent && !row.candidatePresent);
const candidateDeltaRows = packageRows.filter((row) => row.candidateSha256 !== row.baseSha256);
const counts = Object.fromEntries([...new Set(packageRows.map((row) => row.state))]
  .sort()
  .map((state) => [state, packageRows.filter((row) => row.state === state).length]));
const overlayStateCounts = Object.fromEntries([...new Set(overlayRows.map((row) => row.state))]
  .sort()
  .map((state) => [state, overlayRows.filter((row) => row.state === state).length]));

const inventoryRows = args.inventory
  ? JSON.parse(readFileSync(path.resolve(args.inventory), 'utf8')).rows
  : null;
const rowKey = (row) => `${row.package}\t${row.file}`;
const overlayKeySet = new Set(overlayRows.map(rowKey));
const inventoryKeySet = new Set((inventoryRows ?? []).map(rowKey));
const inventoryMissing = (inventoryRows ?? [])
  .filter((row) => !overlayKeySet.has(rowKey(row)))
  .map(rowKey)
  .sort();
const inventoryExtra = overlayRows
  .filter((row) => inventoryRows && !inventoryKeySet.has(rowKey(row)))
  .map(rowKey)
  .sort();
const inventorySummary = inventoryRows ? {
  path: path.resolve(args.inventory),
  rowCount: inventoryRows.length,
  matchedRows: inventoryRows.length - inventoryMissing.length,
  missingRows: inventoryMissing,
  extraCurrentRows: inventoryExtra,
  exact: inventoryMissing.length === 0 && inventoryExtra.length === 0,
} : null;

const manifest = {
  schemaVersion: 1,
  observedAt: new Date().toISOString(),
  roots,
  packageCommits: Object.fromEntries(Object.entries(packageDirectories).map(([name, directory]) => [name, {
    base: commit(path.join(roots.base, directory)),
    candidate: commit(path.join(roots.candidate, directory)),
  }])),
  expectedHistoricalOverlayCount: 43,
  inventory: inventorySummary,
  packageRows,
  overlayRows,
  candidateDeltaRows,
  summary: {
    changedRows: packageRows.length,
    overlayRows: overlayRows.length,
    candidateDeltaRows: candidateDeltaRows.length,
    runtimeMissingRows: runtimeMissingRows.length,
    targetDeletionRows: targetDeletionRows.length,
    relationCounts: counts,
    overlayStateCounts,
    currentTextOverlayRows: overlayRows.length,
    historicalInventoryRows: inventoryRows?.length ?? null,
    inventoryExact: inventorySummary?.exact ?? null,
    inventoryMissing: inventoryMissing.length,
    inventoryExtra: inventoryExtra.length,
    overlayConflicts: overlayRows.filter((row) => row.state === 'overlay_conflict').map((row) => `${row.package}/${row.file}`),
  },
  gate: 'RETARGET_PARTIAL; candidate target is source-locked but overlay conflicts and native/browser proof remain open',
};

mkdirSync(roots.out, { recursive: true });
writeFileSync(path.join(roots.out, 'retarget-report.json'), `${JSON.stringify(manifest, null, 2)}\n`);

const lines = [
  '# Upstream-first retarget report',
  '',
  `Observed: ${manifest.observedAt}`,
  `Base source: ${roots.base}`,
  `Candidate source: ${roots.candidate}`,
  `Preserved runtime: ${roots.runtime}`,
  '',
  `- Changed source/runtime rows: **${packageRows.length}**`,
  `- Current runtime text overlay rows: **${overlayRows.length}** (historical inventory: ${inventoryRows?.length ?? 'not supplied'})`,
  `- Candidate delta rows: **${candidateDeltaRows.length}**`,
  `- Source files absent from preserved runtime tree: **${runtimeMissingRows.length}** (tracked separately from overlays)`,
  `- Source files deleted by the candidate target: **${targetDeletionRows.length}**`,
  `- Overlay state counts: ${JSON.stringify(overlayStateCounts)}`,
  `- Overlay conflicts requiring hunk review: **${manifest.summary.overlayConflicts.length}**`,
  ...(inventorySummary ? [
    `- Historical inventory exact match: **${inventorySummary.exact}**; missing: ${inventoryMissing.length}; extra current rows: ${inventoryExtra.length}`,
  ] : []),
  '',
  '## Candidate package commits',
  '',
  '| Package | Base | Candidate |',
  '| --- | --- | --- |',
  ...Object.entries(manifest.packageCommits).map(([name, commits]) => `| ${name} | ${commits.base} | ${commits.candidate} |`),
  '',
  '## Overlay retarget rows',
  '',
  '| Package | File | State | Base → candidate | Runtime |',
  '| --- | --- | --- | --- | --- |',
  ...overlayRows.map((row) => `| ${row.package} | ${row.file} | ${row.state} | ${row.baseSha256?.slice(0, 12) ?? 'missing'} → ${row.candidateSha256?.slice(0, 12) ?? 'missing'} | ${row.runtimeSha256?.slice(0, 12) ?? 'missing'} |`),
  '',
  '## Gate',
  '',
  'This report is source/provenance evidence only. It does not prove native startup, rule correctness, privacy, reconnect, or browser parity. Do not promote or release this candidate until every overlay conflict has an owner and the native candidate passes the required Quốc Chiến scenarios.',
  '',
  ...(runtimeMissingRows.length ? [
    '## Runtime package omissions',
    '',
    ...runtimeMissingRows.map((row) => `- ${row.package}/${row.file} (base present: ${row.basePresent}; candidate present: ${row.candidatePresent})`),
    '',
  ] : []),
  ...(targetDeletionRows.length ? [
    '## Target deletions',
    '',
    ...targetDeletionRows.map((row) => `- ${row.package}/${row.file}`),
    '',
  ] : []),
  ...(inventorySummary ? [
    '## Historical inventory drift',
    '',
    ...(inventoryMissing.length ? ['Missing historical rows:', ...inventoryMissing.map((row) => `- ${row}`), ''] : []),
    ...(inventoryExtra.length ? ['Extra current text overlay rows:', ...inventoryExtra.map((row) => `- ${row}`), ''] : []),
    ...(inventoryMissing.length === 0 && inventoryExtra.length === 0 ? ['No drift against the supplied historical inventory.', ''] : []),
  ] : []),
].join('\n');
writeFileSync(path.join(roots.out, 'retarget-report.md'), lines);

console.log(JSON.stringify({
  out: roots.out,
  overlayRows: overlayRows.length,
  candidateDeltaRows: candidateDeltaRows.length,
  overlayStateCounts,
  overlayConflicts: manifest.summary.overlayConflicts.length,
  inventoryExact: inventorySummary?.exact ?? null,
  inventoryMissing: inventoryMissing.length,
  inventoryExtra: inventoryExtra.length,
  gate: manifest.gate,
}));
