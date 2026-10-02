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
PACKAGES_DIR="$RUNTIME_DIR/packages"
PACKAGE_DB="$PACKAGES_DIR/packages.db"

[[ -d "$RUNTIME_DIR" ]] || die "Runtime directory does not exist: $RUNTIME_DIR"
[[ -f "$PACKAGES_DIR/init.sql" ]] || die "Missing package schema: $PACKAGES_DIR/init.sql"
command -v git >/dev/null 2>&1 || die "git is required"
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required"

mkdir -p "$PACKAGES_DIR"

clone_at_commit() {
  local name="$1"
  local url="$2"
  local commit="$3"
  local destination="$PACKAGES_DIR/$name"

  if [[ -e "$destination" && ! -d "$destination/.git" ]]; then
    die "Package path exists but is not a Git checkout: $destination"
  fi

  if [[ ! -d "$destination/.git" ]]; then
    git clone --no-tags "$url" "$destination"
  fi

  # Some Gitee repositories do not advertise older commit IDs through the
  # upload-pack endpoint. If a prior clone already resolved the exact pin,
  # avoid a redundant fetch that can fail even though the checkout is usable.
  if [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)" == "$commit" ]]; then
    return
  fi

  if [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
    die "Package checkout has uncommitted changes: $destination"
  fi

  git -C "$destination" fetch --depth 1 origin "$commit" >/dev/null 2>&1 || \
    git -C "$destination" fetch origin "$commit"
  git -C "$destination" checkout --detach "$commit" >/dev/null

  local actual
  actual="$(git -C "$destination" rev-parse HEAD)"
  [[ "$actual" == "$commit" ]] || die "$name resolved to $actual, expected $commit"
}

clone_at_commit "freekill-core" "$FREEKILL_CORE_URL" "$FREEKILL_CORE_COMMIT"
clone_at_commit "utility" "$UTILITY_URL" "$UTILITY_COMMIT"
clone_at_commit "hegemony" "$HEGEMONY_URL" "$HEGEMONY_COMMIT"

sqlite3 "$PACKAGE_DB" < "$PACKAGES_DIR/init.sql"
sqlite3 "$PACKAGE_DB" <<SQL
DELETE FROM packages WHERE name IN ('freekill-core', 'utility', 'hegemony');
INSERT INTO packages (name, url, hash, enabled)
VALUES ('freekill-core', '$FREEKILL_CORE_URL', '$FREEKILL_CORE_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('utility', '$UTILITY_URL', '$UTILITY_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('hegemony', '$HEGEMONY_URL', '$HEGEMONY_COMMIT', 1);
SQL

CONFIG_DEST="$RUNTIME_DIR/freekill.server.config.json"
if [[ ! -e "$CONFIG_DEST" || "${FORCE_CONFIG:-0}" == "1" ]]; then
  install -m 0644 "$DEPLOY_DIR/server/freekill.server.config.json" "$CONFIG_DEST"
fi

printf '%s\n' "Installed pinned packages into $RUNTIME_DIR"
sqlite3 "$PACKAGE_DB" "SELECT name || ' @ ' || substr(hash, 1, 12) || ' enabled=' || enabled FROM packages ORDER BY name;"
