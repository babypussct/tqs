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
    assert.equal(config.tqsAuthRequired, true, 'QA installer must preserve TQS ticket authentication');
    assert.equal(config.tqsQa.enabled, true);
    assert.deepEqual(config.tqsQa.allowedUsers, ['qa-a', 'qa-b']);
    assert.equal(config.tempBanTime, 0, 'QA installer must disable effective temp-ban duration');
    const productionConfig = JSON.parse(readFileSync(defaultConfig, 'utf8'));
    assert.equal(productionConfig.tempBanTime, 5, 'production temp-ban policy must remain five minutes');
    const patchText = readFileSync(reconnectPatch, 'utf8');
    assert.match(patchText, /server\.isAccountTempBanned\(accountId\)/,
      'production source patch must check the authenticated account after authentication');
    assert.match(patchText, /class AccountTempBanStore/,
      'production source patch must provide a dedicated account temp-ban store');
    assert.match(patchText, /Temporary account bans are an anti-abandon safeguard/,
      'bootstrap must have a stable marker for an already-applied reconnect patch');
    assert.match(patchText, /std::unordered_map<int, time_point> bans/,
      'production source patch must store temporary bans by account id and monotonic expiry');
    assert.match(patchText, /duration <= std::chrono::minutes::zero\(\)/,
      'production source patch must make zero or negative duration a no-op');
    assert.match(patchText, /if \(it == bans\.end\(\) \|\| it->second < until\)/,
      'production source patch must renew only when the new expiry is later');
    assert.match(patchText, /removeIfExpired\(int accountId/,
      'production source patch must expose stale-timer-safe expiry cleanup');
    assert.doesNotMatch(patchText, /server\.isTempBanned\(client->peerAddress\(\)\)/,
      'production source patch must not use the connection address as the temporary-ban key');
    assert.match(patchText, /canResumeOfflineGame = player && player->insideGame\(\) &&[\s\S]*player->getState\(\) == ServerPlayer::Offline/,
      'production source patch must identify only an offline in-game player as reconnectable');
    assert.match(patchText, /const bool wasOnline = player && player->isOnline\(\)/,
      'production source patch must preserve online-session replacement before kicking the old socket');
    assert.match(patchText, /server\.isAccountTempBanned\(accountId\) &&[\s\S]*!canResumeOfflineGame/,
      'production source patch must reject a fresh ticket after explicit abandonment');
    assert.match(patchText, /if \(player->insideGame\(\) &&[\s\S]*player->getState\(\) == ServerPlayer::Offline \|\| wasOnline/,
      'production source patch must not reconnect an explicitly Run player through insideGame alone');
    assert.match(patchText, /Capacity is enforced after authentication/,
      'production source patch must keep reconnectable players ahead of capacity rejection');
    assert.match(patchText, /if \(!player && um\.getPlayers\(\)\.size\(\) >=/,
      'production source patch must defer capacity rejection until after account lookup');
    assert.match(patchText, /-  } else if \(server\.isTempBanned\(addr\)\)/,
      'production source patch must remove the pre-auth temp-ban rejection');
    if (existsSync(path.join(upstreamNativeSource, '.git'))) {
      const fixture = path.join(root, 'native-source-fixture');
      mkdirSync(path.join(fixture, 'src/server/user'), { recursive: true });
      cpSync(path.join(upstreamNativeSource, 'src/server/server.h'),
        path.join(fixture, 'src/server/server.h'));
      cpSync(path.join(upstreamNativeSource, 'src/server/server.cpp'),
        path.join(fixture, 'src/server/server.cpp'));
      cpSync(path.join(upstreamNativeSource, 'src/server/user/auth.cpp'),
        path.join(fixture, 'src/server/user/auth.cpp'));
      cpSync(path.join(upstreamNativeSource, 'src/server/user/user_manager.h'),
        path.join(fixture, 'src/server/user/user_manager.h'));
      cpSync(path.join(upstreamNativeSource, 'src/server/user/user_manager.cpp'),
        path.join(fixture, 'src/server/user/user_manager.cpp'));
      assert.doesNotThrow(() => runWithInput('patch', [
        '--batch', '-p1', '-d', fixture,
      ], patchText, repo), 'production reconnect patch must apply cleanly to the pinned native source');
      const patchedAuth = readFileSync(path.join(fixture, 'src/server/user/auth.cpp'), 'utf8');
      const passwordCheck = patchedAuth.indexOf('passed = (passwordHash == obj["password"]);');
      const tempBanCheck = patchedAuth.indexOf('server.isAccountTempBanned(accountId)');
      assert.ok(passwordCheck >= 0 && tempBanCheck > passwordCheck,
        'patched native auth must authenticate the account before applying the account temp-ban');
      assert.match(patchedAuth, /Temporary account bans are an anti-abandon safeguard/,
        'patched native auth must retain the bootstrap idempotency marker');
      assert.match(patchedAuth, /const bool canResumeOfflineGame = player && player->insideGame\(\) &&[\s\S]*player->getState\(\) == ServerPlayer::Offline/,
        'patched native auth must identify only an offline in-game player as reconnectable');
      assert.match(patchedAuth, /const bool wasOnline = player && player->isOnline\(\)/,
        'patched native auth must snapshot online status before disconnecting the old session');
      assert.match(patchedAuth, /if \(server\.isAccountTempBanned\(accountId\) &&[\s\S]*!canResumeOfflineGame\)/,
        'patched native auth must reject a fresh ticket after an explicit Run/abandon state');
      assert.match(patchedAuth, /if \(player->insideGame\(\) &&[\s\S]*player->getState\(\) == ServerPlayer::Offline \|\| wasOnline\)/,
        'patched native auth must keep Run outside the reconnect path');
      assert.doesNotMatch(patchedAuth, /server\.isTempBanned\(client->peerAddress\(\)\)/,
        'patched native auth must not apply an IP temporary-ban check');
      assert.match(patchedAuth, /if \(!player && um\.getPlayers\(\)\.size\(\) >=/,
        'patched native auth must defer capacity rejection until after account lookup');
      const patchedUserManager = readFileSync(path.join(fixture, 'src/server/user/user_manager.cpp'), 'utf8');
      const patchedUserManagerHeader = readFileSync(path.join(fixture, 'src/server/user/user_manager.h'), 'utf8');
      assert.match(patchedAuth, /um\.findPlayer\(accountId, true\)/,
        'patched native auth must prefer the in-game player for reconnect lookup');
      assert.doesNotMatch(patchedUserManager, /server\.isTempBanned\(addr\)/,
        'patched native connection setup must not reject temp-banned IPs before auth');
      assert.doesNotMatch(patchedUserManager, /online_players_map\.size\(\) >= \(size_t\)server\.config\(\)\.capacity/,
        'patched native connection setup must not reject reconnects before auth');
      assert.match(patchedUserManagerHeader, /findPlayer\(int id, bool preferInGame = false\) const/,
        'patched user manager must expose an explicit in-game reconnect lookup mode');
      assert.match(patchedUserManager, /if \(preferInGame\)[\s\S]*if \(!player \|\| player->getId\(\) != id \|\| !player->insideGame\(\)\) continue;/,
        'patched user manager must select an active in-game player before the online map entry');
      assert.match(patchedUserManager,
        /std::shared_ptr<ServerPlayer> offlinePlayer;[\s\S]*if \(player->getState\(\) != ServerPlayer::Offline\)\s*return player;[\s\S]*if \(offlinePlayer\)\s*return offlinePlayer;/,
        'patched user manager must prefer a Run player over an Offline duplicate before reconnect lookup');
      const patchedServerHeader = readFileSync(path.join(fixture, 'src/server/server.h'), 'utf8');
      assert.match(patchedServerHeader, /bool isAccountTempBanned\(int accountId\);/,
        'patched native server must expose account-scoped temp-ban lookup');
      const patchedServer = readFileSync(path.join(fixture, 'src/server/server.cpp'), 'utf8');
      assert.match(patchedServer, /account_temp_bans\.apply\(accountId, std::chrono::minutes\(time\)\)/,
        'patched native server must apply the account expiry by userinfo id');
      assert.match(patchedServer, /if \(ban_until\)/,
        'zero or negative temp-ban duration must not create an effective account lock');
      assert.match(patchedServer, /ec\.value\(\) != asio::error::operation_aborted/,
        'cancelled stale ban timers must not be reported as timer failures');
      assert.match(patchedServer, /account_temp_bans\.removeIfExpired\(accountId\)/,
        'patched native server must lazily expire stale account bans through the store');
      assert.doesNotMatch(patchedServer, /lastLoginIp|peerAddress\(\)/,
        'patched native temp-ban implementation must not read connection or last-login IP');
      const patchedTempBanStore = readFileSync(path.join(fixture, 'src/server/account_tempban.h'), 'utf8');
      assert.match(patchedTempBanStore, /std::unordered_map<int, time_point> bans/,
        'patched native source must include the account temp-ban store implementation');
      assert.match(patchedTempBanStore, /it->second <= now/,
        'patched native temp-ban store must lazily remove expired accounts');
    }

    writeFileSync(path.join(source, 'README.md'), `${readFileSync(path.join(source, 'README.md'), 'utf8')}\nchanged\n`);
    assert.throws(() => run('bash', [verifier, '--source', source, '--runtime', runtime], repo), /uncommitted changes/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
