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

if [[ "$(id -u)" -ne 0 ]]; then
  die "Run as root, for example: sudo $0"
fi

case "$(uname -s)" in
  Linux) ;;
  *) die "The source build must run on Linux, not on macOS or Windows." ;;
esac

command -v apt-get >/dev/null 2>&1 || die "This bootstrap currently expects Debian/Ubuntu apt."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates git patch g++ cmake pkg-config sqlite3 tmux \
  libasio-dev libssl-dev libcbor-dev nlohmann-json3-dev \
  libsqlite3-dev libgit2-dev libreadline-dev libspdlog-dev \
  lua5.4 lua-socket lua-filesystem

ROOT="$FREEKILL_INSTALL_ROOT"
SOURCE_DIR="$ROOT/source/freekill-asio"
RELEASE_DIR="$ROOT/releases/freekill-asio-source-$FREEKILL_ASIO_RELEASE"
PATCH_FILE="$DEPLOY_DIR/patches/freekill-asio/reconnect-safe-tempban.patch"

[[ -f "$PATCH_FILE" ]] || die "Missing native reconnect/temp-ban patch: $PATCH_FILE"

install -d -m 0755 "$ROOT/source" "$ROOT/releases"

if [[ -e "$SOURCE_DIR" && ! -d "$SOURCE_DIR/.git" ]]; then
  die "Source path exists but is not a Git checkout: $SOURCE_DIR"
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --no-tags "$FREEKILL_ASIO_SOURCE_URL" "$SOURCE_DIR"
fi

managed_patch_applied() {
  grep -Fq 'Temporary IP bans are an anti-abandon safeguard' \
    "$SOURCE_DIR/src/server/user/auth.cpp" &&
    grep -Fq 'Capacity is enforced after authentication' \
      "$SOURCE_DIR/src/server/user/auth.cpp" &&
    ! grep -Fq 'server.isTempBanned(addr)' \
      "$SOURCE_DIR/src/server/user/user_manager.cpp" &&
    ! grep -Fq 'online_players_map.size() >= (size_t)server.config().capacity' \
      "$SOURCE_DIR/src/server/user/user_manager.cpp"
}

if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain)" ]] && ! managed_patch_applied; then
  die "Source checkout has uncommitted changes outside the managed reconnect patch: $SOURCE_DIR"
fi

git -C "$SOURCE_DIR" fetch --depth 1 origin "$FREEKILL_ASIO_SOURCE_COMMIT" >/dev/null 2>&1 || \
  git -C "$SOURCE_DIR" fetch origin "$FREEKILL_ASIO_SOURCE_COMMIT"
git -C "$SOURCE_DIR" checkout --detach "$FREEKILL_ASIO_SOURCE_COMMIT" >/dev/null

actual_source="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
[[ "$actual_source" == "$FREEKILL_ASIO_SOURCE_COMMIT" ]] || die "freekill-asio resolved to $actual_source"

if ! managed_patch_applied; then
  patch --dry-run --batch -p1 -d "$SOURCE_DIR" < "$PATCH_FILE" >/dev/null ||
    die "Native reconnect/temp-ban patch does not apply cleanly to $actual_source"
  patch --batch -p1 -d "$SOURCE_DIR" < "$PATCH_FILE" >/dev/null
fi
printf 'Native reconnect/temp-ban patch: %s\n' "$(basename "$PATCH_FILE")"

cmake -S "$SOURCE_DIR" -B "$SOURCE_DIR/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$SOURCE_DIR/build" --parallel "$(nproc)"
[[ -x "$SOURCE_DIR/build/freekill-asio" ]] || die "Source build did not produce freekill-asio"

if [[ -e "$RELEASE_DIR" ]]; then
  die "Source release directory already exists; choose a new version before rebuilding: $RELEASE_DIR"
fi
install -d -m 0755 "$RELEASE_DIR/packages" "$RELEASE_DIR/server"
install -m 0644 "$SOURCE_DIR/packages/init.sql" "$RELEASE_DIR/packages/init.sql"
install -m 0644 "$SOURCE_DIR/server/init.sql" "$RELEASE_DIR/server/init.sql"
install -m 0644 "$SOURCE_DIR/server/gamedb_init.sql" "$RELEASE_DIR/server/gamedb_init.sql"
ln -s "$SOURCE_DIR/build/freekill-asio" "$RELEASE_DIR/freekill-asio"

if [[ -e "$ROOT/current" && ! -L "$ROOT/current" ]]; then
  die "$ROOT/current exists and is not a symlink; refusing to replace it"
fi
ln -sfn "$RELEASE_DIR" "$ROOT/current"

FREEKILL_RUNTIME_DIR="$ROOT/current" "$SCRIPT_DIR/install-packages.sh"

printf '\nSource bootstrap complete.\n'
printf 'Runtime: %s\n' "$ROOT/current"
printf 'Built source commit: %s\n' "$actual_source"
printf 'Game TCP/UDP port: %s\n' "$FREEKILL_PORT"
printf 'Next: run verify-install.sh, then start the server inside tmux using run-server.sh.\n'
