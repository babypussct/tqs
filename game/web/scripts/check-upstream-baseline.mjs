#!/usr/bin/env node

// Verify that browser preparation and the native installer consume the same
// immutable upstream baseline and the same native patch inputs. This is a
// source/configuration gate; it does not contact upstream or mutate a checkout.

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  UPSTREAM_BASELINE_ID,
  UPSTREAM_BASELINE_PATH,
  UPSTREAM_PACKAGES,
  UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH,
  UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT,
  UPSTREAM_RUNTIME_OVERLAY_ID,
  UPSTREAM_RUNTIME_OVERLAY_SHA256,
  UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH,
  UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT,
  UPSTREAM_RUNTIME_SOURCE_PATCH_ID,
  UPSTREAM_RUNTIME_SOURCE_PATCH_PATH,
  UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256,
} from './upstream-packages.ts';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const deployDir = path.join(repo, 'deploy/freekill-native');
const versionsPath = path.join(deployDir, 'versions.env');
const baseline = fs.readFileSync(UPSTREAM_BASELINE_PATH, 'utf8');
const versions = fs.readFileSync(versionsPath, 'utf8');

assert.equal(UPSTREAM_BASELINE_ID, 'tqsvn-production-2026-11-15');
assert.equal(UPSTREAM_RUNTIME_OVERLAY_ID, 'tqsvn-production-bundle-2026-11-15');
assert.equal(UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH, `artifacts/${UPSTREAM_RUNTIME_OVERLAY_ID}.zip`);
assert.match(UPSTREAM_RUNTIME_OVERLAY_SHA256, /^[a-f0-9]{64}$/u);
assert.match(UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH, /^[a-f0-9]{16}$/u);
const overlayArchive = fs.readFileSync(path.join(deployDir, UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH));
assert.equal(createHash('sha256').update(overlayArchive).digest('hex'), UPSTREAM_RUNTIME_OVERLAY_SHA256,
  'bundled runtime overlay archive differs from the production pin');
assert.equal(createHash('sha1').update(overlayArchive).digest('hex').slice(0, 16), UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH,
  'bundled runtime overlay archive has a different gateway bundle hash');
assert.equal(UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT, '5338');
assert.equal(UPSTREAM_RUNTIME_SOURCE_PATCH_ID, 'tqsvn-production-native-qml-2026-11-15');
assert.equal(UPSTREAM_RUNTIME_SOURCE_PATCH_PATH, 'patches/upstream-runtime/tqsvn-production-2026-11-15-qml.patch');
assert.match(UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256, /^[a-f0-9]{64}$/u);
assert.equal(UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT, '25');
assert.match(versions, /source "\$VERSIONS_DIR\/upstream-baseline\.env"/u,
  'versions.env must source the canonical upstream baseline');
assert.equal(UPSTREAM_PACKAGES.length, 14, 'the production baseline must contain 14 packages');
assert.equal(new Set(UPSTREAM_PACKAGES.map(({ name }) => name)).size, 14,
  'upstream package names must be unique');
for (const spec of UPSTREAM_PACKAGES) {
  assert.match(spec.commit, /^[a-f0-9]{40}$/u, `${spec.name} must use a full commit SHA`);
  assert.match(spec.url, /^https:\/\//u, `${spec.name} must use an HTTPS source URL`);
}

const nativeValues = execFileSync('bash', [
  '-c',
  'set -Eeuo pipefail; source "$1"; printf "%s\\n" "$FREEKILL_ASIO_SOURCE_COMMIT" "$FREEKILL_CORE_COMMIT" "$UTILITY_COMMIT" "$HEGEMONY_COMMIT" "$GAMEMODE_COMMIT" "$STANDARD_EX_COMMIT" "$SHZL_COMMIT" "$YJ_COMMIT" "$MOBILE_COMMIT" "$SP_COMMIT" "$TENYEAR_COMMIT" "$OVERSEAS_COMMIT" "$MOUGONG_COMMIT" "$JSRG_COMMIT" "$OL_COMMIT" "$TQS_UPSTREAM_RUNTIME_OVERLAY_ID" "$TQS_UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH" "$TQS_UPSTREAM_RUNTIME_OVERLAY_SHA256" "$TQS_UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH" "$TQS_UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT" "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_ID" "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_PATH" "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256" "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT"',
  'check-upstream-baseline',
  versionsPath,
], { encoding: 'utf8' }).trim().split(/\r?\n/u);

assert.equal(nativeValues.length, 24, 'native versions.env must expose ASIO, 14 package commits, the production overlay identity and the native source patch identity');
assert.equal(nativeValues[0], 'b8a2ad48305aea7b55ccca325fcbeb100cb8a01a', 'native ASIO source drifted');
assert.deepEqual(nativeValues.slice(1, 15), UPSTREAM_PACKAGES.map(({ commit }) => commit),
  'native installer and browser preparation use different package pins');
assert.deepEqual(nativeValues.slice(15), [
  UPSTREAM_RUNTIME_OVERLAY_ID,
  UPSTREAM_RUNTIME_OVERLAY_ARCHIVE_PATH,
  UPSTREAM_RUNTIME_OVERLAY_SHA256,
  UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH,
  UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT,
  UPSTREAM_RUNTIME_SOURCE_PATCH_ID,
  UPSTREAM_RUNTIME_SOURCE_PATCH_PATH,
  UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256,
  UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT,
], 'native installer and browser preparation use different production overlay identity');

const patchInputs = [
  ['TQS_UPSTREAM_PATCH_RECONNECT_PATH', 'TQS_UPSTREAM_PATCH_RECONNECT_SHA256'],
  ['TQS_UPSTREAM_PATCH_COMPILER_PATH', 'TQS_UPSTREAM_PATCH_COMPILER_SHA256'],
  ['TQS_UPSTREAM_PATCH_GAME_ACCESS_PATH', 'TQS_UPSTREAM_PATCH_GAME_ACCESS_SHA256'],
  ['TQS_UPSTREAM_PATCH_CARD_WIRE_PATH', 'TQS_UPSTREAM_PATCH_CARD_WIRE_SHA256'],
  ['TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_PATH', 'TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_SHA256'],
  ['TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_PATH', 'TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_SHA256'],
  ['TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_PATH', 'TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_SHA256'],
  ['TQS_UPSTREAM_PATCH_PACKET_VALIDATION_PATH', 'TQS_UPSTREAM_PATCH_PACKET_VALIDATION_SHA256'],
  ['TQS_UPSTREAM_PATCH_ROUTER_REQUEST_PATH', 'TQS_UPSTREAM_PATCH_ROUTER_REQUEST_SHA256'],
  ['TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_PATH', 'TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256'],
];
const baselineValues = Object.fromEntries(
  [...baseline.matchAll(/^([A-Z0-9_]+)="([^"\\]*)"$/gmu)].map(([, key, value]) => [key, value]),
);
for (const [pathKey, digestKey] of patchInputs) {
  const patchPath = path.join(deployDir, baselineValues[pathKey]);
  assert.equal(fs.existsSync(patchPath), true, `missing native patch input: ${patchPath}`);
  const digest = createHash('sha256').update(fs.readFileSync(patchPath)).digest('hex');
  assert.equal(digest, baselineValues[digestKey], `${pathKey} digest drifted`);
}

console.log(`PASS upstream baseline ${UPSTREAM_BASELINE_ID}: 14/14 package pins, ${patchInputs.length - 1}/${patchInputs.length - 1} native patches and 1/1 native source patch digests are synchronized`);
