#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEPLOY_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$DEPLOY_DIR/versions.env"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lua-runtime.sh"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
PACKAGE_DB="$RUNTIME_DIR/packages/packages.db"

[[ -x "$RUNTIME_DIR/freekill-asio" ]] || die "Missing executable: $RUNTIME_DIR/freekill-asio"
[[ -f "$RUNTIME_DIR/freekill.server.config.json" ]] || die "Missing server config"
[[ -f "$PACKAGE_DB" ]] || die "Missing package database"
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"
command -v patch >/dev/null 2>&1 || die "patch is required"
lua54_prepare "$RUNTIME_DIR" || die 'Lua 5.4 runtime preflight failed'
printf '%s\n' "Lua runtime: $TQS_LUA54_BIN with LuaSocket/LuaFileSystem loaded"

verify_patch_input() {
  local relative_path="$1"
  local expected_sha256="$2"
  local patch_path="$DEPLOY_DIR/$relative_path"
  [[ -f "$patch_path" ]] || die "Missing pinned native patch input: $patch_path"
  local actual_sha256
  actual_sha256="$(sha256sum "$patch_path" | awk '{print $1}')"
  [[ "$actual_sha256" == "$expected_sha256" ]] ||
    die "Native patch digest mismatch for $relative_path: $actual_sha256 (expected $expected_sha256)"
}

verify_patch_input "$TQS_UPSTREAM_PATCH_RECONNECT_PATH" "$TQS_UPSTREAM_PATCH_RECONNECT_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_COMPILER_PATH" "$TQS_UPSTREAM_PATCH_COMPILER_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_GAME_ACCESS_PATH" "$TQS_UPSTREAM_PATCH_GAME_ACCESS_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_CARD_WIRE_PATH" "$TQS_UPSTREAM_PATCH_CARD_WIRE_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_PATH" "$TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_PATH" "$TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_PATH" "$TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_PACKET_VALIDATION_PATH" "$TQS_UPSTREAM_PATCH_PACKET_VALIDATION_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_ROUTER_REQUEST_PATH" "$TQS_UPSTREAM_PATCH_ROUTER_REQUEST_SHA256"
verify_patch_input "$TQS_UPSTREAM_PATCH_RPC_WIRE_PATH" "$TQS_UPSTREAM_PATCH_RPC_WIRE_SHA256"
verify_patch_input "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_PATH" "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256"
printf '%s\n' 'Upstream baseline patch inputs: 9/9 SHA-256 digests verified'

OVERLAY_MARKER="$RUNTIME_DIR/.tqs-upstream-runtime-overlay"
[[ -f "$OVERLAY_MARKER" ]] || die 'Production runtime overlay marker is missing'
grep -Fxq "overlay_id=$TQS_UPSTREAM_RUNTIME_OVERLAY_ID" "$OVERLAY_MARKER" ||
  die 'Production runtime overlay id does not match the pinned baseline'
grep -Fxq "archive_sha256=$TQS_UPSTREAM_RUNTIME_OVERLAY_SHA256" "$OVERLAY_MARKER" ||
  die 'Production runtime overlay archive digest does not match the pinned baseline'
grep -Fxq "bundle_hash=$TQS_UPSTREAM_RUNTIME_OVERLAY_BUNDLE_HASH" "$OVERLAY_MARKER" ||
  die 'Production runtime overlay bundle hash does not match the pinned baseline'
grep -Fxq "file_count=$TQS_UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT" "$OVERLAY_MARKER" ||
  die 'Production runtime overlay file count does not match the pinned baseline'
runtime_overlay_file_count="$(find "$RUNTIME_DIR/packages" -type d -name .git -prune -o -type f \( -iname '*.lua' -o -iname '*.json' -o -iname '*.md' \) -print | awk 'NF { count++ } END { print count + 0 }')"
[[ "$runtime_overlay_file_count" == "$TQS_UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT" ]] ||
  die "Runtime overlay contains $runtime_overlay_file_count public files; expected $TQS_UPSTREAM_RUNTIME_OVERLAY_FILE_COUNT"
if find "$RUNTIME_DIR/packages" -type f -name '._*' -print -quit | grep -q .; then
  die 'Runtime package tree contains AppleDouble metadata'
fi
printf '%s\n' "Production runtime overlay: $runtime_overlay_file_count files and pinned archive identity verified"
[[ -d "$RUNTIME_DIR/packages/maneuvering" && -d "$RUNTIME_DIR/packages/standard_cards" ]] ||
  die 'Runtime package inventory is missing the two public media package roots'

SOURCE_OVERLAY_MARKER="$RUNTIME_DIR/.tqs-upstream-runtime-source-overlay"
SOURCE_OVERLAY_PATCH="$DEPLOY_DIR/$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_PATH"
[[ -f "$SOURCE_OVERLAY_MARKER" ]] || die 'Native runtime source overlay marker is missing'
grep -Fxq "patch_id=$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_ID" "$SOURCE_OVERLAY_MARKER" ||
  die 'Native runtime source overlay id does not match the pinned baseline'
grep -Fxq "patch_sha256=$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_SHA256" "$SOURCE_OVERLAY_MARKER" ||
  die 'Native runtime source overlay digest does not match the pinned baseline'
grep -Fxq "file_count=$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT" "$SOURCE_OVERLAY_MARKER" ||
  die 'Native runtime source overlay file count does not match the pinned baseline'
source_overlay_file_count="$(grep -c '^diff --git ' "$SOURCE_OVERLAY_PATCH")"
[[ "$source_overlay_file_count" == "$TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT" ]] ||
  die "Native runtime source patch contains $source_overlay_file_count files; expected $TQS_UPSTREAM_RUNTIME_SOURCE_PATCH_FILE_COUNT"
patch --dry-run --reverse --batch -p1 -d "$RUNTIME_DIR/packages" < "$SOURCE_OVERLAY_PATCH" >/dev/null 2>&1 ||
  die 'Native runtime source overlay target drifted from the pinned production result'
printf '%s\n' "Native source overlay: $source_overlay_file_count QML files and pinned patch identity verified"

if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool "$RUNTIME_DIR/freekill.server.config.json" >/dev/null || die "Invalid server config JSON"
fi

verify_package() {
  local package="$1"
  local expected="$2"
  local package_dir="$RUNTIME_DIR/packages/$package"
  [[ -d "$package_dir/.git" ]] || die "Missing package checkout: $package_dir"

  local actual
  actual="$(git -C "$package_dir" rev-parse HEAD)"
  [[ "$actual" == "$expected" ]] || die "$package mismatch: $actual (expected $expected)"

  local db_hash db_enabled
  db_hash="$(sqlite3 "$PACKAGE_DB" "SELECT hash FROM packages WHERE name = '$package';")"
  db_enabled="$(sqlite3 "$PACKAGE_DB" "SELECT enabled FROM packages WHERE name = '$package';")"
  [[ "$db_hash" == "$expected" ]] || die "$package database hash mismatch: $db_hash (expected $expected)"
  [[ "$db_enabled" == "1" ]] || die "$package is not enabled in packages.db"
}

# Keep this list in lockstep with install-packages.sh and versions.env. A
# three-package check is insufficient: unresolved general/card skills can live
# in any extension package and the native server must mount the same pinned
# registry that the browser skill audit consumes.
verify_package freekill-core "$FREEKILL_CORE_COMMIT"
verify_package utility "$UTILITY_COMMIT"
verify_package hegemony "$HEGEMONY_COMMIT"
verify_package gamemode "$GAMEMODE_COMMIT"
verify_package standard_ex "$STANDARD_EX_COMMIT"
verify_package shzl "$SHZL_COMMIT"
verify_package yj "$YJ_COMMIT"
verify_package mobile "$MOBILE_COMMIT"
verify_package sp "$SP_COMMIT"
verify_package tenyear "$TENYEAR_COMMIT"
verify_package overseas "$OVERSEAS_COMMIT"
verify_package mougong "$MOUGONG_COMMIT"
verify_package jsrg "$JSRG_COMMIT"
verify_package ol "$OL_COMMIT"

printf '%s\n' 'Pinned package registry: 14/14 commits and enabled flags verified'

# Keep the server-side prelight projection aligned with the native client. The
# installer applies this exact source hardening after the pinned checkout; a
# clean-looking Git commit alone is insufficient evidence that the running
# server has the idempotent body.
CORE_SERVERPLAYER="$RUNTIME_DIR/packages/freekill-core/ltk/server/serverplayer.lua"
[[ -f "$CORE_SERVERPLAYER" ]] || die "Missing ServerPlayer source: $CORE_SERVERPLAYER"
prelight_source="$(sed -n '/^function ServerPlayer:prelightSkill(skill, isPrelight)/,/^---@param isDeputy?/p' "$CORE_SERVERPLAYER")"
grep -Fq 'table.insertIfNeed(self.prelighted_skills, skill)' <<<"$prelight_source" ||
  die 'ServerPlayer prelight skill projection is not idempotent'
grep -Fq 'table.insertIfNeed(self.prelighted_skills, s)' <<<"$prelight_source" ||
  die 'ServerPlayer related prelight projection is not idempotent'
if grep -Fq 'table.insert(self.prelighted_skills, ' <<<"$prelight_source"; then
  die 'ServerPlayer prelight function still contains duplicate-unsafe append'
fi
printf '%s\n' 'ServerPlayer prelight projection: idempotent source hardening verified'

fake_skill_source="$(sed -n '/^function ServerPlayer:addFakeSkill(skill)/,/^---@param skill string | Skill/p' "$CORE_SERVERPLAYER")"
if ! grep -Fq 'self:doNotify("PrelightSkill", { skill.name, true })' <<<"$fake_skill_source" &&
    ! grep -Fq 'self:notifyConcealedSkillOwner("PrelightSkill", { skill.name, true })' <<<"$fake_skill_source"; then
  die 'ServerPlayer fake-skill reattach does not resync retained prelight state'
fi
printf '%s\n' 'ServerPlayer fake-skill reattach: retained prelight state verified'

CORE_ROOM="$RUNTIME_DIR/packages/freekill-core/ltk/server/room.lua"
[[ -f "$CORE_ROOM" ]] || die "Missing Room source: $CORE_ROOM"
grep -Fq 'if not p:isFakeSkill(skill) then return end' "$CORE_ROOM" ||
  die 'Room prelight handler does not reject unattached fake skills'
grep -Fq 'elseif not table.contains(p.prelighted_skills, skill) then' "$CORE_ROOM" ||
  die 'Room prelight handler does not reject unknown false cleanup'
printf '%s\n' 'Room prelight ownership: fake-skill and stale-cleanup checks verified'

db_rows="$(sqlite3 "$PACKAGE_DB" "SELECT name || ' @ ' || hash || ' enabled=' || enabled FROM packages ORDER BY name;")"
printf '%s\n' 'FreeKill native deployment verification: PASS'
printf '%s\n' "Runtime: $RUNTIME_DIR"
printf '%s\n' "Game port: $FREEKILL_PORT"
printf '%s\n' "$db_rows"
