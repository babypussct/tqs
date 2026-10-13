#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/qa-package-common.sh"

usage() {
  cat >&2 <<'EOF'
Usage: verify-qa-package.sh --source DIR --runtime DIR [--expected-revision REV]
EOF
  exit 2
}

source_dir=""
runtime_dir=""
expected_revision=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_dir="${2:-}"; shift 2 ;;
    --runtime) runtime_dir="${2:-}"; shift 2 ;;
    --expected-revision) expected_revision="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -n "$source_dir" && -n "$runtime_dir" ]] || usage
source_dir="$(CDPATH= cd -- "$source_dir" && pwd -P)"
runtime_dir="$(CDPATH= cd -- "$runtime_dir" && pwd -P)"
destination="$runtime_dir/packages/tqs_qa"
config_path="$runtime_dir/freekill.server.config.json"
package_db="$runtime_dir/packages/packages.db"

assert_regular_tree "$source_dir"
assert_regular_tree "$destination"
[[ -f "$destination/init.lua" && -f "$destination/catalog.json" &&
  -f "$destination/package.manifest.json" ]] || die "incomplete tqs_qa package"
[[ -f "$config_path" ]] || die "missing native server config: $config_path"
[[ ! -e "$package_db" || "$(sqlite3 "$package_db" "SELECT COUNT(*) FROM packages WHERE name='tqs_qa';")" == "0" ]] ||
  die "server-only tqs_qa must not be present in packages.db"

revision="$(source_revision_for "$source_dir")"
if [[ -n "$expected_revision" && "$revision" != "$expected_revision" ]]; then
  die "source revision $revision does not match expected revision $expected_revision"
fi

tree_hash_input="$(mktemp)"
trap 'rm -f -- "$tree_hash_input"' EXIT
expected_package_hash="$(hash_package_tree "$source_dir" "$tree_hash_input")"
actual_package_hash="$(hash_package_tree "$destination" "$tree_hash_input")"
rm -f -- "$tree_hash_input"
[[ "$actual_package_hash" == "$expected_package_hash" ]] ||
  die "runtime package tree hash mismatch"

expected_catalog_hash="$(sha256_file "$source_dir/catalog.json")"
actual_catalog_hash="$(sha256_file "$destination/catalog.json")"
[[ "$actual_catalog_hash" == "$expected_catalog_hash" ]] || die "catalog hash mismatch"

manifest_status="$(read_json_field "$destination/package.manifest.json" status)" || die "invalid package manifest"
manifest_package="$(read_json_field "$destination/package.manifest.json" package)" || die "invalid package manifest"
manifest_revision="$(read_json_field "$destination/package.manifest.json" sourceRevision)" || die "invalid package manifest"
manifest_catalog="$(read_json_field "$destination/package.manifest.json" catalogSha256)" || die "invalid package manifest"
manifest_tree="$(read_json_field "$destination/package.manifest.json" packageSha256)" || die "invalid package manifest"
[[ "$manifest_status" == verified && "$manifest_package" == tqs_qa ]] || die "package manifest is not verified tqs_qa"
[[ "$manifest_revision" == "$revision" ]] || die "package manifest source revision mismatch"
[[ "$manifest_catalog" == "$expected_catalog_hash" ]] || die "package manifest catalog hash mismatch"
[[ "$manifest_tree" == "$expected_package_hash" ]] || die "package manifest tree hash mismatch"

qa_enabled="$(read_json_field "$config_path" tqsQa.enabled)" || die "native config has no tqsQa block"
allowlist="$(read_json_field "$config_path" tqsQa.allowedUsers)" || die "native config has no QA allowlist"
[[ "$qa_enabled" == true ]] || die "tqsQa.enabled is not true"
[[ "$allowlist" != "[]" ]] || die "QA allowlist is empty"

printf 'PASS tqs_qa runtime verification\n'
printf 'sourceRevision=%s\n' "$revision"
printf 'packageSha256=%s\n' "$actual_package_hash"
printf 'catalogSha256=%s\n' "$actual_catalog_hash"
printf 'serverOnly=true\n'
