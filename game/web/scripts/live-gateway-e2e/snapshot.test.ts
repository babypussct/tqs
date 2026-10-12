import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { buildSnapshot, fileList, PACKAGES } from './snapshot';

const md5 = (data: string) => createHash('md5').update(data).digest('hex');
test('Native flist orders packages/files by name, groups extensions and normalizes CRLF only', () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-flist-test-'));
  try {
    for (const pkg of PACKAGES) mkdirSync(path.join(root, pkg));
    const core = path.join(root, 'freekill-core');
    mkdirSync(path.join(core, 'a'));
    writeFileSync(path.join(core, 'a/init.lua'), 'line1\r\nline2\r');
    writeFileSync(path.join(core, 'z.lua'), 'last');
    writeFileSync(path.join(core, 'a.qml'), 'view');
    writeFileSync(path.join(root, 'utility/z.js'), 'script');
    writeFileSync(path.join(root, 'hegemony/init.lua'), 'heg');
    writeFileSync(path.join(root, 'hegemony/data.json'), '{}');
    assert.equal(fileList(root), [
      `packages/freekill-core/a/init.lua=${md5('line1\nline2\r')};`,
      `packages/freekill-core/z.lua=${md5('last')};`,
      `packages/hegemony/init.lua=${md5('heg')};`,
      `packages/freekill-core/a.qml=${md5('view')};`,
      `packages/utility/z.js=${md5('script')};`,
    ].join(''));
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('Pinned snapshot includes QML omitted by a clean sparse checkout', () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-sparse-test-'));
  const source = path.join(root, 'source');
  const destination = path.join(root, 'snapshot');
  try {
    for (const pkg of PACKAGES) {
      const cwd = path.join(source, pkg);
      mkdirSync(path.join(cwd, 'qml'), { recursive: true });
      writeFileSync(path.join(cwd, 'init.lua'), `return '${pkg}'\n`);
      writeFileSync(path.join(cwd, 'data.json'), '{}');
      writeFileSync(path.join(cwd, 'qml/box.qml'), `Item { /* ${pkg} */ }\n`);
      const git = (...args: string[]) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
      git('init');
      git('add', '.');
      git('-c', 'user.name=TQS fixture', '-c', 'user.email=fixture@localhost', 'commit', '-m', 'Fixture');
      git('sparse-checkout', 'set', '--no-cone', '*.lua', '*.json');
      assert.equal(existsSync(path.join(cwd, 'qml/box.qml')), false);
      assert.equal(git('status', '--porcelain').trim(), '');
    }
    const digest = buildSnapshot(source, destination);
    for (const pkg of PACKAGES) {
      assert.equal(readFileSync(path.join(destination, 'packages', pkg, 'qml/box.qml'), 'utf8'),
        `Item { /* ${pkg} */ }\n`);
      assert.equal(existsSync(path.join(destination, 'packages', pkg, '.git')), false);
      assert.equal(existsSync(path.join(source, pkg, 'qml/box.qml')), false, 'Preserve source sparse checkout');
    }
    const flist = readFileSync(path.join(destination, 'flist.txt'), 'utf8');
    assert.equal(digest, md5(flist));
    assert.ok(flist.includes('packages/hegemony/qml/box.qml='));
  } finally { rmSync(root, { recursive: true, force: true }); }
});
