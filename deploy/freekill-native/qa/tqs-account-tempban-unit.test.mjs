import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const reconnectPatch = path.join(repo, 'deploy/freekill-native/patches/freekill-asio/reconnect-safe-tempban.patch');
const upstreamNativeSource = path.join(repo, 'scratch/upstream/freekill-asio');

function run(command, args, options = {}) {
  return execFileSync(command, args, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'], ...options });
}

test('native account temp-ban store handles zero duration, renewal and stale expiry deterministically', () => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'tqs-account-tempban-unit-'));
  try {
    const fixture = path.join(root, 'native-source');
    mkdirSync(path.join(fixture, 'src/server/user'), { recursive: true });
    for (const relativePath of [
      'src/server/server.h',
      'src/server/server.cpp',
      'src/server/user/auth.cpp',
      'src/server/user/user_manager.h',
      'src/server/user/user_manager.cpp',
    ]) {
      const target = path.join(fixture, relativePath);
      cpSync(path.join(upstreamNativeSource, relativePath), target);
    }

    run('patch', ['--batch', '-p1', '-d', fixture], {
      cwd: repo,
      input: readFileSync(reconnectPatch),
    });

    writeFileSync(path.join(fixture, 'account_tempban_verify.cpp'), String.raw`
#include "server/account_tempban.h"

#include <cassert>
#include <chrono>

int main() {
  using Store = AccountTempBanStore;
  using namespace std::chrono_literals;

  const auto origin = Store::time_point{};
  Store store;

  assert(!store.apply(0, 5min, origin));
  assert(!store.apply(101, 0min, origin));
  assert(!store.apply(102, -1min, origin));
  assert(!store.contains(101, origin));

  const auto firstExpiry = store.apply(101, 5min, origin);
  assert(firstExpiry && *firstExpiry == origin + 5min);
  assert(store.contains(101, origin + 4min));

  const auto shorterRenewal = store.apply(101, 2min, origin + 1min);
  assert(shorterRenewal && *shorterRenewal == origin + 5min);

  const auto longerRenewal = store.apply(101, 5min, origin + 1min);
  assert(longerRenewal && *longerRenewal == origin + 6min);
  store.removeIfExpired(101, origin + 5min);
  assert(store.contains(101, origin + 5min + 1s));

  const auto independentAccount = store.apply(202, 1min, origin);
  assert(independentAccount && store.contains(202, origin + 59s));
  assert(store.contains(101, origin + 5min + 1s));

  store.removeIfExpired(202, origin + 1min);
  assert(!store.contains(202, origin + 1min));
  assert(!store.contains(101, origin + 6min));
  assert(!store.contains(101, origin + 6min));

  const auto lazyExpiry = store.apply(303, 1min, origin);
  assert(lazyExpiry && !store.contains(303, origin + 1min));
  return 0;
}
`);

    const binary = path.join(fixture, 'account_tempban_verify');
    run('g++', [
      '-std=c++20', '-Wall', '-Wextra', '-Werror',
      '-I', path.join(fixture, 'src'),
      path.join(fixture, 'account_tempban_verify.cpp'),
      '-o', binary,
    ], { cwd: fixture });
    run(binary, [], { cwd: fixture });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
