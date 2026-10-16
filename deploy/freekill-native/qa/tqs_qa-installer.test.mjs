import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, cpSync, existsSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
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
const reconnectPatch = path.join(repo, 'deploy/freekill-native/patches/freekill-asio/reconnect-safe-tempban.patch');
const upstreamNativeSource = path.join(repo, 'scratch/upstream/freekill-asio');

function run(command, args, cwd) {
  return execFileSync(command, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function runWithInput(command, args, input, cwd) {
  return execFileSync(command, args, {
    cwd, input, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'],
  });
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
    assert.equal(config.tempBanTime, 0, 'QA installer must disable effective temp-ban duration');
    const productionConfig = JSON.parse(readFileSync(defaultConfig, 'utf8'));
    assert.equal(productionConfig.tempBanTime, 5, 'production temp-ban policy must remain five minutes');
    const patchText = readFileSync(reconnectPatch, 'utf8');
    assert.match(patchText, /server\.isTempBanned\(client->peerAddress\(\)\)/,
      'production source patch must check temp-ban after authentication');
    assert.match(patchText, /!player\s*\|\|\s*!player->insideGame\(\)/,
      'production source patch must exempt only an authenticated player still inside a game');
    assert.match(patchText, /Capacity is enforced after authentication/,
      'production source patch must keep reconnectable players ahead of capacity rejection');
    assert.match(patchText, /if \(!player && um\.getPlayers\(\)\.size\(\) >=/,
      'production source patch must defer capacity rejection until after account lookup');
    assert.match(patchText, /-  } else if \(server\.isTempBanned\(addr\)\)/,
      'production source patch must remove the pre-auth temp-ban rejection');
    if (existsSync(path.join(upstreamNativeSource, '.git'))) {
      const fixture = path.join(root, 'native-source-fixture');
      mkdirSync(path.join(fixture, 'src/server/user'), { recursive: true });
      cpSync(path.join(upstreamNativeSource, 'src/server/user/auth.cpp'),
        path.join(fixture, 'src/server/user/auth.cpp'));
      cpSync(path.join(upstreamNativeSource, 'src/server/user/user_manager.cpp'),
        path.join(fixture, 'src/server/user/user_manager.cpp'));
      assert.doesNotThrow(() => runWithInput('patch', [
        '--batch', '-p1', '-d', fixture,
      ], patchText, repo), 'production reconnect patch must apply cleanly to the pinned native source');
      const patchedAuth = readFileSync(path.join(fixture, 'src/server/user/auth.cpp'), 'utf8');
      const passwordCheck = patchedAuth.indexOf('passed = (passwordHash == obj["password"]);');
      const tempBanCheck = patchedAuth.indexOf('server.isTempBanned(client->peerAddress())');
      assert.ok(passwordCheck >= 0 && tempBanCheck > passwordCheck,
        'patched native auth must authenticate the account before applying the IP temp-ban');
      assert.match(patchedAuth, /if \(server\.isTempBanned\(client->peerAddress\(\)\) &&[\s\S]*!player->insideGame\(\)\)/,
        'patched native auth must exempt only an authenticated player still inside a game');
      assert.match(patchedAuth, /if \(!player && um\.getPlayers\(\)\.size\(\) >=/,
        'patched native auth must defer capacity rejection until after account lookup');
      const patchedUserManager = readFileSync(path.join(fixture, 'src/server/user/user_manager.cpp'), 'utf8');
      assert.doesNotMatch(patchedUserManager, /server\.isTempBanned\(addr\)/,
        'patched native connection setup must not reject temp-banned IPs before auth');
      assert.doesNotMatch(patchedUserManager, /online_players_map\.size\(\) >= \(size_t\)server\.config\(\)\.capacity/,
        'patched native connection setup must not reject reconnects before auth');
    }

    writeFileSync(path.join(source, 'README.md'), `${readFileSync(path.join(source, 'README.md'), 'utf8')}\nchanged\n`);
    assert.throws(() => run('bash', [verifier, '--source', source, '--runtime', runtime], repo), /uncommitted changes/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
