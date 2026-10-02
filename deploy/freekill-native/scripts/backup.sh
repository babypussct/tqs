#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEPLOY_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$DEPLOY_DIR/versions.env"

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
BACKUP_DIR="${FREEKILL_BACKUP_DIR:-$FREEKILL_INSTALL_ROOT/backups}"
[[ -d "$RUNTIME_DIR" ]] || {
  printf 'Runtime is not installed: %s\n' "$RUNTIME_DIR" >&2
  exit 1
}

install -d -m 0700 "$BACKUP_DIR"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="$BACKUP_DIR/freekill-hegemony-$stamp.tar.gz"

backup_items=(
  freekill.server.config.json
  packages
  server
)
if [[ -f "$RUNTIME_DIR/freekill.log" ]]; then
  backup_items+=(freekill.log)
fi

tar -czf "$archive" -C "$RUNTIME_DIR" "${backup_items[@]}"

chmod 0600 "$archive"
printf 'Created backup: %s\n' "$archive"
