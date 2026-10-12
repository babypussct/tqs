import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { UPSTREAM_PACKAGE_NAMES, packageSpec } from '../upstream-packages';

// The native package database returns enabled packages by name. Keep the
// gateway snapshot in that same deterministic order, while packageSpec maps
// the runtime name to a checkout whose directory has a historical spelling
// such as SP or OL.
export const PACKAGES = [...UPSTREAM_PACKAGE_NAMES].sort();

/** Match freekill-asio core/util.cpp: sorted recursive traversal, then
 * concatenate Lua, QML, JS hashes, with CRLF normalized within each file. */
export function fileList(packagesRoot: string): string {
  const groups: Record<string, string[]> = { '.lua': [], '.qml': [], '.js': [] };
  function walk(dir: string) {
    const entries = readdirSync(dir, { withFileTypes: true })
      .sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
    for (const entry of entries) {
      if (entry.name === '.git') continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile() && groups[path.extname(entry.name)]) {
        const bytes = readFileSync(full);
        // latin1 keeps all original bytes intact, including standalone CR.
        const normalized = Buffer.from(bytes.toString('latin1').replace(/\r\n/g, '\n'), 'latin1');
        const hash = createHash('md5').update(normalized).digest('hex');
        const relative = path.relative(packagesRoot, full).split(path.sep).join('/');
        groups[path.extname(entry.name)].push(`packages/${relative}=${hash};`);
      }
    }
  }
  for (const pkg of PACKAGES) walk(path.join(packagesRoot, pkg));
  return [...groups['.lua'], ...groups['.qml'], ...groups['.js']].join('');
}

export function buildSnapshot(source: string, destination: string) {
  for (const pkg of PACKAGES) {
    const target = path.join(destination, 'packages', pkg);
    mkdirSync(target, { recursive: true });
    const cwd = path.join(source, packageSpec(pkg).sourceDirectory);
    // The development checkout may be sparse (e.g. omit QML). Export the
    // complete pinned Git tree, including files absent from its working tree.
    const entries = execFileSync('git', ['ls-tree', '-rz', 'HEAD'], { cwd })
      .toString('utf8').split('\0').filter(Boolean).map((line) => {
        const tab = line.indexOf('\t');
        const [mode, type, hash] = line.slice(0, tab).split(' ');
        return { mode, type, hash, name: line.slice(tab + 1) };
      }).filter((entry) => /\.(lua|json|qml|js)$/i.test(entry.name));
    // cat-file requests only these objects; archive can prefetch all media in
    // a partial clone. Fail explicitly if a required blob is missing offline.
    const blobs = execFileSync('git', ['cat-file', '--batch'], {
      cwd, env: { ...process.env, GIT_NO_LAZY_FETCH: '1' },
      input: entries.map((entry) => entry.hash).join('\n') + '\n', maxBuffer: 32 * 1024 * 1024,
    });
    let offset = 0;
    for (const entry of entries) {
      const end = blobs.indexOf(10, offset);
      const header = blobs.subarray(offset, end).toString('utf8');
      const match = /^([a-f0-9]{40}) blob (\d+)$/.exec(header);
      if (!match || match[1] !== entry.hash) throw new Error(`Missing pinned Git blob: ${pkg}/${entry.name}`);
      if (!/^100(644|755)$/.test(entry.mode) || entry.type !== 'blob' ||
          entry.name.split('/').some((part) => part === '..' || part === '') || path.isAbsolute(entry.name))
        throw new Error(`Unsafe pinned package file: ${pkg}/${entry.name}`);
      const size = Number(match[2]);
      offset = end + 1;
      const full = path.join(target, entry.name);
      mkdirSync(path.dirname(full), { recursive: true });
      writeFileSync(full, blobs.subarray(offset, offset + size));
      offset += size + 1;
    }
  }
  const flist = fileList(path.join(destination, 'packages'));
  writeFileSync(path.join(destination, 'flist.txt'), flist);
  return createHash('md5').update(flist).digest('hex');
}
