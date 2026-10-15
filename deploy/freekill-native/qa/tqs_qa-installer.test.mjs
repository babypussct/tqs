import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, cpSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const packageDir = path.join(here, 'tqs_qa');
const installer = path.join(repo, 'deploy/freekill-native/scripts/install-qa-package.sh');
const verifier = path.join(repo, 'deploy/freekill-native/scripts/verify-qa-package.sh');
const defaultConfig = path.join(repo, 'deploy/freekill-native/server/freekill.server.config.json');

function run(command, args, cwd) {
  return execFileSync(command, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

test('QA installer creates a verified server-only runtime and rejects a dirty source', () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-qa-installer-test-'));
  try {
    const sourceRepo = path.join(root, 'repo');
    const source = path.join(sourceRepo, 'deploy/freekill-native/qa/tqs_qa');
    const runtime = path.join(root, 'runtime');
    mkdirSync(source, { recursive: true });
    cpSync(packageDir, source, { recursive: true });
    mkdirSync(path.join(runtime, 'packages'), { recursive: true });
    writeFileSync(path.join(runtime, 'freekill.server.config.json'), readFileSync(defaultConfig));
    run('git', ['init', '-q'], sourceRepo);
    run('git', ['config', 'user.email', 'qa@example.invalid'], sourceRepo);
    run('git', ['config', 'user.name', 'tqs-qa-test'], sourceRepo);
    run('git', ['add', '.'], sourceRepo);
    run('git', ['commit', '-qm', 'fixture tqs_qa'], sourceRepo);
    const revision = run('git', ['rev-parse', 'HEAD'], sourceRepo).trim();
    run('sqlite3', [path.join(runtime, 'packages/packages.db'),
      'CREATE TABLE packages (name TEXT PRIMARY KEY, url TEXT, hash TEXT, enabled INTEGER);'], runtime);

    run('bash', [installer, '--source', source, '--runtime', runtime, '--allow-user', 'qa-a,qa-b', '--expected-revision', revision], repo);
    run('bash', [verifier, '--source', source, '--runtime', runtime, '--expected-revision', revision], repo);
    const manifest = JSON.parse(readFileSync(path.join(runtime, 'qa_packages/tqs_qa/package.manifest.json'), 'utf8'));
    assert.equal(manifest.status, 'verified');
    assert.equal(manifest.sourceRevision, revision);
    const config = JSON.parse(readFileSync(path.join(runtime, 'freekill.server.config.json'), 'utf8'));
    assert.equal(config.tqsQa.enabled, true);
    assert.deepEqual(config.tqsQa.allowedUsers, ['qa-a', 'qa-b']);

    writeFileSync(path.join(source, 'README.md'), `${readFileSync(path.join(source, 'README.md'), 'utf8')}\nchanged\n`);
    assert.throws(() => run('bash', [verifier, '--source', source, '--runtime', runtime], repo), /uncommitted changes/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
