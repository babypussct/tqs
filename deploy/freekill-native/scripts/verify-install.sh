#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEPLOY_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$DEPLOY_DIR/versions.env"

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

if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool "$RUNTIME_DIR/freekill.server.config.json" >/dev/null || die "Invalid server config JSON"
fi

for package in freekill-core utility hegemony; do
  package_dir="$RUNTIME_DIR/packages/$package"
  [[ -d "$package_dir/.git" ]] || die "Missing package checkout: $package_dir"
done

actual_core="$(git -C "$RUNTIME_DIR/packages/freekill-core" rev-parse HEAD)"
actual_utility="$(git -C "$RUNTIME_DIR/packages/utility" rev-parse HEAD)"
actual_hegemony="$(git -C "$RUNTIME_DIR/packages/hegemony" rev-parse HEAD)"
[[ "$actual_core" == "$FREEKILL_CORE_COMMIT" ]] || die "freekill-core mismatch: $actual_core"
[[ "$actual_utility" == "$UTILITY_COMMIT" ]] || die "utility mismatch: $actual_utility"
[[ "$actual_hegemony" == "$HEGEMONY_COMMIT" ]] || die "hegemony mismatch: $actual_hegemony"

db_rows="$(sqlite3 "$PACKAGE_DB" "SELECT name || ' @ ' || hash || ' enabled=' || enabled FROM packages ORDER BY name;")"
printf '%s\n' 'FreeKill native deployment verification: PASS'
printf '%s\n' "Runtime: $RUNTIME_DIR"
printf '%s\n' "Game port: $FREEKILL_PORT"
printf '%s\n' "$db_rows"
