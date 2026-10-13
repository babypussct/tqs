#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/qa-package-common.sh"

usage() {
  cat >&2 <<'EOF'
Usage: install-qa-package.sh --source DIR --runtime DIR --allow-user USER[,USER...] [options]

Options:
  --expected-revision REV     Require the checked-out Git revision to match REV.
  --room-prefix PREFIX        Default: TQSQA/
  --max-players N             Default: 4
  --max-active-rooms N        Default: 1
  --max-duration-seconds N    Default: 900
  --max-runs-per-process N    Default: 50
EOF
  exit 2
}

source_dir=""
runtime_dir=""
allow_users=""
expected_revision=""
room_prefix="TQSQA/"
max_players=4
max_active_rooms=1
max_duration_seconds=900
max_runs_per_process=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_dir="${2:-}"; shift 2 ;;
    --runtime) runtime_dir="${2:-}"; shift 2 ;;
    --allow-user) allow_users="${2:-}"; shift 2 ;;
    --expected-revision) expected_revision="${2:-}"; shift 2 ;;
    --room-prefix) room_prefix="${2:-}"; shift 2 ;;
    --max-players) max_players="${2:-}"; shift 2 ;;
    --max-active-rooms) max_active_rooms="${2:-}"; shift 2 ;;
    --max-duration-seconds) max_duration_seconds="${2:-}"; shift 2 ;;
    --max-runs-per-process) max_runs_per_process="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -n "$source_dir" && -n "$runtime_dir" && -n "$allow_users" ]] || usage
source_dir="$(CDPATH= cd -- "$source_dir" && pwd -P)"
runtime_dir="$(CDPATH= cd -- "$runtime_dir" && pwd -P)"
packages_dir="$runtime_dir/packages"
destination="$packages_dir/tqs_qa"
config_path="$runtime_dir/freekill.server.config.json"
package_db="$packages_dir/packages.db"

assert_regular_tree "$source_dir"
[[ -f "$source_dir/init.lua" && -f "$source_dir/catalog.json" ]] ||
  die "QA source must contain init.lua and catalog.json"
[[ -d "$packages_dir" ]] || die "missing runtime packages directory: $packages_dir"
[[ -f "$package_db" ]] || die "missing package database: $package_db"
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required"

if [[ "$(sqlite3 "$package_db" "SELECT COUNT(*) FROM packages WHERE name='tqs_qa';")" != "0" ]]; then
  die "packages.db already contains tqs_qa; remove the server-only row before installing"
fi

revision="$(source_revision_for "$source_dir")"
if [[ -n "$expected_revision" && "$revision" != "$expected_revision" ]]; then
  die "source revision $revision does not match expected revision $expected_revision"
fi

for value in "$max_players" "$max_active_rooms" "$max_duration_seconds" "$max_runs_per_process"; do
  [[ "$value" =~ ^[1-9][0-9]*$ ]] || die "quota values must be positive integers"
done
[[ "$room_prefix" == TQSQA/* ]] || die "room prefix must start with TQSQA/"

temp_dir="$packages_dir/.tqs_qa-staging.$$"
trap 'rm -rf -- "$temp_dir"' EXIT
[[ ! -e "$temp_dir" ]] || die "staging path already exists: $temp_dir"
mkdir -p "$temp_dir"
copy_package_tree "$source_dir" "$temp_dir"

catalog_hash="$(sha256_file "$temp_dir/catalog.json")"
tree_hash_input="$(mktemp)"
trap 'rm -rf -- "$temp_dir"; rm -f -- "$tree_hash_input"' EXIT
package_hash="$(hash_package_tree "$temp_dir" "$tree_hash_input")"
write_verified_manifest "$temp_dir" "$revision" "$catalog_hash" "$package_hash"
rm -f -- "$tree_hash_input"

if [[ -e "$destination" ]]; then
  [[ "$destination" == "$packages_dir/tqs_qa" ]] || die "refusing to replace unexpected package path"
  rm -rf -- "$destination"
fi
mv -- "$temp_dir" "$destination"

configure_qa_runtime "$config_path" "$allow_users" "$room_prefix" "$max_players" \
  "$max_active_rooms" "$max_duration_seconds" "$max_runs_per_process"

printf 'Installed verified tqs_qa package at %s\n' "$destination"
printf 'QA source revision: %s\n' "$revision"
printf 'QA server-only mode: enabled (not registered in packages.db)\n'
