import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const pinnedNative = path.join(repo, 'scratch/upstream/freekill-asio');
const patches = path.join(repo, 'deploy/freekill-native/patches/freekill-asio');
const files = ['src/server/room/room.cpp', 'src/server/rpc-lua/rpc-lua.cpp', 'src/server/server.cpp',
  'src/server/server.h', 'src/server/user/auth.cpp', 'src/server/user/user_manager.h',
  'src/server/user/user_manager.cpp'];
const secret = 'test-secret-with-at-least-32-characters';
const identity = 'tqs_firebase_uid';

function sign(version, expiry, alias = '') {
  const payload = `${version}|${identity}|${expiry}${version === 'TQS2' ? `|${alias}` : ''}`;
  const hmac = createHmac('sha256', secret).update(payload).digest('hex');
  return `${version}|${expiry}${version === 'TQS2' ? `|${alias}` : ''}|${hmac}`;
}

test('pinned native verifies TQS1/TQS2 HMAC, names, expiry and malformed UTF-8', () => {
  const temp = mkdtempSync(path.join(tmpdir(), 'tqs-game-ticket-test-'));
  try {
    const source = path.join(temp, 'native');
    for (const filename of files) {
      mkdirSync(path.dirname(path.join(source, filename)), { recursive: true });
      writeFileSync(path.join(source, filename),
        execFileSync('git', ['-C', pinnedNative, 'show', `HEAD:${filename}`]));
    }
    for (const patch of ['reconnect-safe-tempban.patch', 'tqs-game-access.patch']) {
      execFileSync('patch', ['--batch', '--forward', '-p1', '-d', source,
        '-i', path.join(patches, patch)], { stdio: 'pipe' });
    }
    const auth = readFileSync(path.join(source, 'src/server/user/auth.cpp'), 'utf8');
    const begin = auth.indexOf('namespace {\n');
    const end = auth.indexOf('} // namespace', begin);
    assert.ok(begin >= 0 && end > begin, 'test the actual native patch implementation');
    assert.match(auth, /p_ptr->tqsScreenName\.empty\(\)/, 'names used at native player creation');
    const ticketCheck = auth.indexOf('tqs_ticket_valid =');
    const accountLookup = auth.indexOf('obj = queryUserInfo');
    const accountBanCheck = auth.indexOf('server.isAccountTempBanned(accountId)');
    assert.ok(ticketCheck >= 0 && accountLookup > ticketCheck && accountBanCheck > accountLookup,
      'account temp-ban must be checked only after TQS ticket authentication and account lookup');
    assert.doesNotMatch(auth, /server\.isTempBanned\(client->peerAddress\(\)\)/,
      'combined native patches must not reintroduce a pre-auth IP temp-ban check');
    assert.match(auth, /canResumeOfflineGame = player && player->insideGame\(\)[\s\S]*ServerPlayer::Offline/,
      'temp-ban reconnect exemption must be limited to an offline in-game player');
    assert.match(auth, /server\.isAccountTempBanned\(accountId\) &&[\s\S]*!canResumeOfflineGame/,
      'explicit abandonment state must not bypass a fresh-ticket temp-ban check');

    const cpp = `#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <iostream>
${auth.slice(begin, end + '} // namespace'.length)}
int main(int argc, char **argv) {
  if (argc != 4) return 2;
  std::string screenName;
  const bool ok = verifyTqsTicket(argv[1], argv[2], argv[3], screenName);
  std::cout << (ok ? "PASS:" : "FAIL:");
  if (ok) for (unsigned char c : screenName) {
    static constexpr char hex[] = "0123456789abcdef";
    std::cout << hex[c >> 4] << hex[c & 15];
  }
  return 0;
}
`;
    const src = path.join(temp, 'verify.cpp');
    const binary = path.join(temp, 'verify');
    writeFileSync(src, cpp);
    const flags = execFileSync('pkg-config', ['--cflags', '--libs', 'openssl'],
      { encoding: 'utf8' }).trim().split(/\s+/);
    execFileSync(process.env.CXX || 'c++', ['-std=c++20', '-Wall', '-Wextra', '-Werror',
      src, '-o', binary, ...flags], { stdio: 'pipe' });
    const check = (ticket, expected, as = identity) => {
      const run = spawnSync(binary, [as, ticket, secret], { encoding: 'utf8' });
      assert.equal(run.status, 0, run.stderr);
      assert.equal(run.stdout, expected === null ? 'FAIL:'
        : `PASS:${Buffer.from(expected, 'utf8').toString('hex')}`);
    };
    const now = Math.floor(Date.now() / 1000);
    const validAt = now + 300;
    const encode = (value) => Buffer.from(value).toString('base64url');
    check(sign('TQS1', validAt), '');
    check(sign('TQS2', validAt, encode('Gia Cát Lượng')), 'Gia Cát Lượng');
    check(sign('TQS2', validAt, encode('⚔️ Quốc Chiến')), '⚔️ Quốc Chiến');
    check(sign('TQS2', validAt, encode('Ă'.repeat(48))), 'Ă'.repeat(48));
    check(sign('TQS2', validAt, encode('An')), 'An');
    check(sign('TQS2', validAt, encode('Ă')), 'Ă');
    check(sign('TQS2', validAt, encode('Tên')), null, 'tqs_other_uid' /* wrong identity */);
    check(sign('TQS1', now - 1), null);
    check(sign('TQS2', now - 1, encode('An')), null);
    check(sign('TQS2', now + 3600, encode('An')), null);
    check(sign('TQS2', validAt, ''), null);
    check(sign('TQS2', validAt, 'a'), null);
    check(sign('TQS2', validAt, 'A'.repeat(129)), null);
    check(sign('TQS2', validAt, encode('A'.repeat(97))), null);
    check(sign('TQS2', validAt, encode('A\nB')), null);
    check(sign('TQS2', validAt, encode(Buffer.from([0xed, 0xa0, 0x80]))), null);
    check(sign('TQS2', validAt, encode(Buffer.from([0xc0, 0xaf]))), null);
    check(sign('TQS2', validAt, encode(Buffer.from([0xf4, 0x90, 0x80, 0x80]))), null);
    check(sign('TQS2', validAt, encode(Buffer.from([0xe2, 0x82]))), null);
    const tampered = sign('TQS2', validAt, encode('An'));
    check(tampered.slice(0, -1) + (tampered.endsWith('0') ? '1' : '0'), null);
    check(sign('TQS2', validAt, encode('An')) + '|extra', null);
  } finally {
    rmSync(temp, { recursive: true, force: true });
  }
});

test('pinned native punishment triggers pass the authenticated player id, not a peer address', () => {
  const sourceRoom = execFileSync('git', ['-C', pinnedNative, 'show', 'HEAD:src/server/room/room.cpp'], { encoding: 'utf8' });
  const serverPlayer = execFileSync('git', ['-C', pinnedNative, 'show', 'HEAD:src/server/user/serverplayer.cpp'], { encoding: 'utf8' });
  const patchedDir = mkdtempSync(path.join(tmpdir(), 'tqs-game-room-patch-'));
  let room;
  try {
    for (const filename of files) {
      const target = path.join(patchedDir, filename);
      mkdirSync(path.dirname(target), { recursive: true });
      writeFileSync(target, execFileSync('git', ['-C', pinnedNative, 'show', `HEAD:${filename}`]));
    }
    execFileSync('patch', ['--batch', '-p1', '-d', patchedDir, '-i',
      path.join(patches, 'reconnect-safe-tempban.patch')], { stdio: 'pipe' });
    room = readFileSync(path.join(patchedDir, 'src/server/room/room.cpp'), 'utf8');
  } finally {
    rmSync(patchedDir, { recursive: true, force: true });
  }
  const punishmentCalls = room.match(/temporarilyBan\((?:runner|p)->getId\(\)\)/g) ?? [];
  assert.deepEqual(punishmentCalls, ['temporarilyBan(runner->getId())'],
    'only an explicit room leave should trigger account temp-ban');
  assert.match(room,
    /player\.setState\(Player::Run\);[\s\S]*?player\.setRunned\(true\);/,
    'explicit room removal must remain distinguishable as state Run');
  assert.match(serverPlayer,
    /m_router->setSocket\(nullptr\);\s*setState\(Player::Offline\);[\s\S]*?setRunned\(true\);/,
    'a transport disconnect must remain reconnectable as state Offline');
  assert.match(room,
    /if \(!isOutdated\(\) && !player\.isDied\(\)\)[\s\S]*?temporarilyBan\(runner->getId\(\)\)/,
    'disconnect replacement must apply the penalty to the runner userinfo id');
  assert.match(room, /if \(p->isRunned\(\) && p->getState\(\) == ServerPlayer::Run\)/,
    'GameOver run-rate must only count explicit player exits');
  assert.doesNotMatch(room, /temporarilyBan\(p->getId\(\)\)/,
    'GameOver must never temp-ban a player disconnected due to transport failure');
  assert.match(sourceRoom, /setRunned\(true\)/, 'baseline must still contain the original abandon flag');
  assert.doesNotMatch(room, /temporarilyBan\([^)]*peerAddress\(\)/,
    'native punishment triggers must not pass a connection address');
});

test('temp-ban E2E honors the configured offline-grace wait', () => {
  const harness = readFileSync(path.join(repo, 'deploy/freekill-native/qa/tqs-account-tempban-e2e.mjs'), 'utf8');
  assert.match(harness, /waitForTempBan\(beforeBan, tempBanEventWaitMs\)/,
    'the E2E harness must honor TQS_ACCOUNT_TEMPBAN_EVENT_WAIT_MS');
});
