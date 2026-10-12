#!/usr/bin/env bash
set -Eeuo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

ARCHIVE="${1:-}"
[[ -n "$ARCHIVE" ]] || die "Usage: $0 /absolute/freekill-backup.tar.gz"
[[ -f "$ARCHIVE" ]] || die "Backup archive does not exist: $ARCHIVE"
command -v tar >/dev/null 2>&1 || die "tar is required"

mode="$(stat -c '%a' "$ARCHIVE" 2>/dev/null || stat -f '%Lp' "$ARCHIVE")"
[[ "$mode" == "600" ]] || die "Backup archive must be owner-only (mode 0600), got $mode"

entries=()
while IFS= read -r entry; do
  entries[${#entries[@]}]="$entry"
done < <(tar -tzf "$ARCHIVE")
[[ "${#entries[@]}" -gt 0 ]] || die "Backup archive is empty"

for entry in "${entries[@]}"; do
  [[ "$entry" != /* && "$entry" != ../* && "$entry" != */../* && "$entry" != */.. ]] ||
    die "Backup contains an unsafe path: $entry"
done

has_root() {
  local root="$1"
  local entry
  for entry in "${entries[@]}"; do
    [[ "$entry" == "$root" || "$entry" == "$root/" || "$entry" == "$root/"* ]] && return 0
  done
  return 1
}

has_root 'freekill.server.config.json' || die 'Backup is missing freekill.server.config.json'
has_root 'packages' || die 'Backup is missing packages/'
has_root 'server' || die 'Backup is missing server/'

printf '%s\n' 'FreeKill backup verification: PASS'
printf '%s\n' "Archive: $ARCHIVE"
printf '%s\n' "Entries: ${#entries[@]}"
