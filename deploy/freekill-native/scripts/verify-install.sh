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
lua54_prepare "$RUNTIME_DIR" || die 'Lua 5.4 runtime preflight failed'
printf '%s\n' "Lua runtime: $TQS_LUA54_BIN with LuaSocket/LuaFileSystem loaded"

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
grep -Fq 'self:doNotify("PrelightSkill", { skill.name, true })' <<<"$fake_skill_source" ||
  die 'ServerPlayer fake-skill reattach does not resync retained prelight state'
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
