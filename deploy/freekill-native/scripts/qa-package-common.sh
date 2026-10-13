#!/usr/bin/env bash
set -Eeuo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "$1" | awk '{print $1}'
  else
    die "sha256sum or shasum is required"
  fi
}

sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    die "sha256sum or shasum is required"
  fi
}

assert_regular_tree() {
  local root="$1"
  [[ -d "$root" ]] || die "missing directory: $root"
  if find "$root" -type l -print -quit | grep -q .; then
    die "symlinks are not allowed in QA package: $root"
  fi
}

hash_package_tree() {
  local root="$1"
  local list_file="$2"
  : > "$list_file"
  while IFS= read -r path; do
    local relative="${path#./}"
    printf '%s  %s\n' "$relative" "$(sha256_file "$root/$relative")" >> "$list_file"
  done < <(
    cd "$root"
    find . -type f ! -name package.manifest.json -print | LC_ALL=C sort
  )
  sha256_file "$list_file"
}

source_revision_for() {
  local source_dir="$1"
  command -v git >/dev/null 2>&1 || die "git is required"
  local repo_root
  repo_root="$(CDPATH= cd -- "$(git -C "$source_dir" rev-parse --show-toplevel 2>/dev/null)" && pwd -P)" ||
    die "QA source must be inside a Git checkout"
  local relative
  relative="${source_dir#"$repo_root"/}"
  [[ "$relative" != "$source_dir" && "$relative" != ..* ]] ||
    die "QA source is not inside the repository root"
  if git -C "$repo_root" status --porcelain -- "$relative" | grep -q .; then
    die "QA source has uncommitted changes; commit the package before installing"
  fi
  git -C "$repo_root" rev-parse HEAD
}

copy_package_tree() {
  local source_dir="$1"
  local destination="$2"
  mkdir -p "$destination"
  while IFS= read -r path; do
    local relative="${path#"$source_dir"/}"
    local parent="$destination/$(dirname "$relative")"
    mkdir -p "$parent"
    cp -p "$path" "$destination/$relative"
  done < <(find "$source_dir" -type f -print | LC_ALL=C sort)
}

write_verified_manifest() {
  local destination="$1"
  local revision="$2"
  local catalog_hash="$3"
  local package_hash="$4"
  local manifest="$destination/package.manifest.json"
  [[ ! -L "$manifest" ]] || die "manifest may not be a symlink"
  {
    printf '{\n'
    printf '  "schemaVersion": 1,\n'
    printf '  "package": "tqs_qa",\n'
    printf '  "status": "verified",\n'
    printf '  "sourceRevision": "%s",\n' "$revision"
    printf '  "catalogSha256": "%s",\n' "$catalog_hash"
    printf '  "packageSha256": "%s"\n' "$package_hash"
    printf '}\n'
  } > "$manifest"
}

configure_qa_runtime() {
  local config_path="$1"
  local users_csv="$2"
  local room_prefix="$3"
  local max_players="$4"
  local max_active_rooms="$5"
  local max_duration_seconds="$6"
  local max_runs_per_process="$7"
  [[ -f "$config_path" ]] || die "missing native server config: $config_path"
  [[ ! -L "$config_path" ]] || die "native server config may not be a symlink"
  command -v python3 >/dev/null 2>&1 || die "python3 is required to update native server config"
  python3 - "$config_path" "$users_csv" "$room_prefix" "$max_players" \
    "$max_active_rooms" "$max_duration_seconds" "$max_runs_per_process" <<'PY'
import json
import os
import sys

path, users_csv, prefix, max_players, max_active, max_duration, max_runs = sys.argv[1:]
users = [item.strip() for item in users_csv.split(",") if item.strip()]
if not users:
    raise SystemExit("allow-user must contain at least one non-empty account")

with open(path, "r", encoding="utf-8") as handle:
    config = json.load(handle)
if not isinstance(config, dict):
    raise SystemExit("native server config must be a JSON object")

config["tqsQa"] = {
    "enabled": True,
    "roomPrefix": prefix,
    "allowedUsers": users,
    "maxPlayers": int(max_players),
    "maxActiveRooms": int(max_active),
    "maxDurationSeconds": int(max_duration),
    "maxRunsPerProcess": int(max_runs),
}

temporary = f"{path}.tqs-qa-{os.getpid()}.tmp"
with open(temporary, "w", encoding="utf-8") as handle:
    json.dump(config, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
os.replace(temporary, path)
PY
}

read_json_field() {
  local path="$1"
  local field="$2"
  command -v python3 >/dev/null 2>&1 || die "python3 is required to verify QA JSON"
  python3 - "$path" "$field" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    value = json.load(handle)
for part in sys.argv[2].split("."):
    if not isinstance(value, dict) or part not in value:
        raise SystemExit(1)
    value = value[part]
if isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, (dict, list)):
    print(json.dumps(value, separators=(",", ":"), ensure_ascii=False))
else:
    print(value)
PY
}
