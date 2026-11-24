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
  ca-certificates curl git patch make gcc-14 g++-14 cmake pkg-config python3 sqlite3 tmux unzip \
  libasio-dev libboost-system-dev libssl-dev libcbor-dev nlohmann-json3-dev \
  libsqlite3-dev libgit2-dev libreadline-dev libspdlog-dev \
  lua5.4 lua-socket lua-filesystem

"$SCRIPT_DIR/prepare-build-resources.sh"

ROOT="$FREEKILL_INSTALL_ROOT"
SOURCE_DIR="$ROOT/source/freekill-asio"
RELEASE_DIR="$ROOT/releases/freekill-asio-source-$FREEKILL_ASIO_RELEASE"
PATCH_FILE="$DEPLOY_DIR/patches/freekill-asio/reconnect-safe-tempban.patch"
COMPILER_COMPAT_PATCH_FILE="$DEPLOY_DIR/patches/freekill-asio/tqs-compiler-compat.patch"
GAME_ACCESS_PATCH_FILE="$DEPLOY_DIR/patches/freekill-asio/tqs-game-access.patch"
CARD_WIRE_BRIDGE_PATCH_FILE="$DEPLOY_DIR/patches/freekill-asio/tqs-card-wire-candidate-native-bridge.patch"
CARD_WIRE_SNAPSHOT_PATCH_FILE="$DEPLOY_DIR/$TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_PATH"
CLIENT_SOCKET_STREAM_PATCH_FILE="$DEPLOY_DIR/$TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_PATH"
SOCKET_LIFECYCLE_PATCH_FILE="$DEPLOY_DIR/$TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_PATH"
PACKET_VALIDATION_PATCH_FILE="$DEPLOY_DIR/$TQS_UPSTREAM_PATCH_PACKET_VALIDATION_PATH"
ROUTER_REQUEST_PATCH_FILE="$DEPLOY_DIR/$TQS_UPSTREAM_PATCH_ROUTER_REQUEST_PATH"
TOOL_ROOT="${FREEKILL_TOOL_ROOT:-/opt/tqs-toolchain}"
CMAKE_VERSION="4.1.1"
CMAKE_ARCHIVE="$TOOL_ROOT/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz"
CMAKE_DIR="$TOOL_ROOT/cmake-$CMAKE_VERSION-linux-x86_64"
CMAKE_URL="https://cmake.org/files/v4.1/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz"
CMAKE_SHA256="5a6c61cb62b38e153148a2c8d4af7b3d387f0c8c32b6dbceb5eb4af113efd65a"

[[ -f "$PATCH_FILE" ]] || die "Missing native reconnect/temp-ban patch: $PATCH_FILE"
[[ -f "$COMPILER_COMPAT_PATCH_FILE" ]] || die "Missing compiler compatibility patch: $COMPILER_COMPAT_PATCH_FILE"
[[ -f "$GAME_ACCESS_PATCH_FILE" ]] || die "Missing TQS game access patch: $GAME_ACCESS_PATCH_FILE"
[[ -f "$CARD_WIRE_BRIDGE_PATCH_FILE" ]] || die "Missing production card-wire bridge patch: $CARD_WIRE_BRIDGE_PATCH_FILE"
[[ -f "$CARD_WIRE_SNAPSHOT_PATCH_FILE" ]] || die "Missing card-wire snapshot compression patch: $CARD_WIRE_SNAPSHOT_PATCH_FILE"
[[ -f "$CLIENT_SOCKET_STREAM_PATCH_FILE" ]] || die "Missing client socket stream patch: $CLIENT_SOCKET_STREAM_PATCH_FILE"
[[ -f "$SOCKET_LIFECYCLE_PATCH_FILE" ]] || die "Missing native socket lifecycle patch: $SOCKET_LIFECYCLE_PATCH_FILE"
[[ -f "$PACKET_VALIDATION_PATCH_FILE" ]] || die "Missing native packet validation patch: $PACKET_VALIDATION_PATCH_FILE"
[[ -f "$ROUTER_REQUEST_PATCH_FILE" ]] || die "Missing native router request patch: $ROUTER_REQUEST_PATCH_FILE"
printf '%s  %s\n' "$TQS_UPSTREAM_PATCH_CARD_WIRE_SNAPSHOT_SHA256" "$CARD_WIRE_SNAPSHOT_PATCH_FILE" | sha256sum -c --status || die "Card-wire snapshot compression patch digest mismatch"
printf '%s  %s\n' "$TQS_UPSTREAM_PATCH_CLIENT_SOCKET_STREAM_SHA256" "$CLIENT_SOCKET_STREAM_PATCH_FILE" | sha256sum -c --status || die "Client socket stream patch digest mismatch"
printf '%s  %s\n' "$TQS_UPSTREAM_PATCH_SOCKET_LIFECYCLE_SHA256" "$SOCKET_LIFECYCLE_PATCH_FILE" | sha256sum -c --status || die "Native socket lifecycle patch digest mismatch"
printf '%s  %s\n' "$TQS_UPSTREAM_PATCH_PACKET_VALIDATION_SHA256" "$PACKET_VALIDATION_PATCH_FILE" | sha256sum -c --status || die "Native packet validation patch digest mismatch"
printf '%s  %s\n' "$TQS_UPSTREAM_PATCH_ROUTER_REQUEST_SHA256" "$ROUTER_REQUEST_PATCH_FILE" | sha256sum -c --status || die "Native router request patch digest mismatch"

install -d -m 0755 "$TOOL_ROOT"
if [[ ! -x "$CMAKE_DIR/bin/cmake" ]]; then
  curl --fail --location --retry 3 --output "$CMAKE_ARCHIVE.tmp" "$CMAKE_URL"
  printf '%s  %s\n' "$CMAKE_SHA256" "$CMAKE_ARCHIVE.tmp" | sha256sum -c -
  mv -f -- "$CMAKE_ARCHIVE.tmp" "$CMAKE_ARCHIVE"
  tar -xzf "$CMAKE_ARCHIVE" -C "$TOOL_ROOT"
fi
[[ -x "$CMAKE_DIR/bin/cmake" ]] || die "Pinned CMake $CMAKE_VERSION is unavailable"
"$CMAKE_DIR/bin/cmake" --version | grep -Fq "cmake version $CMAKE_VERSION" ||
  die "Unexpected CMake version in $CMAKE_DIR"

install -d -m 0755 "$ROOT/source" "$ROOT/releases"

if [[ -e "$SOURCE_DIR" && ! -d "$SOURCE_DIR/.git" ]]; then
  die "Source path exists but is not a Git checkout: $SOURCE_DIR"
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --no-tags "$FREEKILL_ASIO_SOURCE_URL" "$SOURCE_DIR"
fi

managed_patch_applied() {
  grep -Fq 'class AccountTempBanStore' \
    "$SOURCE_DIR/src/server/account_tempban.h" &&
  grep -Fq 'Temporary account bans are an anti-abandon safeguard' \
    "$SOURCE_DIR/src/server/user/auth.cpp" &&
    grep -Fq 'isAccountTempBanned(int accountId)' \
      "$SOURCE_DIR/src/server/server.h" &&
    grep -Fq 'account_temp_bans' \
      "$SOURCE_DIR/src/server/server.cpp" &&
    grep -Fq 'Capacity is enforced after authentication' \
      "$SOURCE_DIR/src/server/user/auth.cpp" &&
    ! grep -Fq 'server.isTempBanned(addr)' \
      "$SOURCE_DIR/src/server/user/user_manager.cpp" &&
    ! grep -Fq 'online_players_map.size() >= (size_t)server.config().capacity' \
      "$SOURCE_DIR/src/server/user/user_manager.cpp" &&
    grep -Fq 'p->isRunned() && p->getState() == ServerPlayer::Run' \
      "$SOURCE_DIR/src/server/room/room.cpp" &&
    grep -Fq 'match must never turn that involuntary disconnect into a ban' \
      "$SOURCE_DIR/src/server/room/room.cpp"
}

game_access_patch_applied() {
  grep -Fq 'verifyTqsTicket' "$SOURCE_DIR/src/server/user/auth.cpp" &&
    grep -Fq 'tqsAuthRequired' "$SOURCE_DIR/src/server/server.h" &&
    grep -Fq 'FK_TQS_LOCKED_PACKS' "$SOURCE_DIR/src/server/rpc-lua/rpc-lua.cpp"
}

card_wire_bridge_patch_applied() {
  grep -Fq 'cardWireCapability' "$SOURCE_DIR/src/server/room/lobby.cpp" &&
    grep -Fq 'addObserver(ServerPlayer &player, std::string_view cardWireCapability' \
      "$SOURCE_DIR/src/server/room/room.h" &&
    grep -Fq 'return ::kill(child_pid, 0) == 0 || errno == EPERM' \
      "$SOURCE_DIR/src/server/rpc-lua/rpc-lua.cpp"
}

compiler_compat_patch_applied() {
  grep -Fq '#include "api_help_embed.inc"' "$SOURCE_DIR/src/server/admin/admin_http.cpp"
}

source_status="$(git -C "$SOURCE_DIR" status --porcelain | grep -v -E '^\?\? (build/|src/server/admin/api_help_embed\.inc$)' || true)"
if [[ -n "$source_status" ]] && ! managed_patch_applied; then
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

API_HELP_SOURCE="$SOURCE_DIR/src/server/admin/api_help.html"
API_HELP_EMBED="$SOURCE_DIR/src/server/admin/api_help_embed.inc"
[[ -f "$API_HELP_SOURCE" ]] || die "Missing embedded admin API help source: $API_HELP_SOURCE"
command -v python3 >/dev/null 2>&1 || die 'python3 is required to generate the admin API help embed'
python3 - "$API_HELP_SOURCE" "$API_HELP_EMBED" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_bytes()
target = Path(sys.argv[2])
values = []
for offset in range(0, len(source), 16):
    values.append(', '.join(f'0x{byte:02x}' for byte in source[offset:offset + 16]))
target.write_text(',\n'.join(values) + '\n', encoding='ascii')
PY

if ! compiler_compat_patch_applied; then
  patch --dry-run --batch -p1 -d "$SOURCE_DIR" < "$COMPILER_COMPAT_PATCH_FILE" >/dev/null ||
    die "Compiler compatibility patch does not apply cleanly to $actual_source"
  patch --batch -p1 -d "$SOURCE_DIR" < "$COMPILER_COMPAT_PATCH_FILE" >/dev/null
fi
printf 'Compiler compatibility patch: %s\n' "$(basename "$COMPILER_COMPAT_PATCH_FILE")"

if ! game_access_patch_applied; then
  patch --dry-run --batch -p1 -d "$SOURCE_DIR" < "$GAME_ACCESS_PATCH_FILE" >/dev/null ||
    die "TQS game access patch does not apply cleanly to $actual_source"
  patch --batch -p1 -d "$SOURCE_DIR" < "$GAME_ACCESS_PATCH_FILE" >/dev/null
fi
printf 'TQS game access and forced-pack patch: %s\n' "$(basename "$GAME_ACCESS_PATCH_FILE")"

if ! card_wire_bridge_patch_applied; then
  patch --dry-run --batch -p1 -d "$SOURCE_DIR" < "$CARD_WIRE_BRIDGE_PATCH_FILE" >/dev/null ||
    die "Production card-wire bridge patch does not apply cleanly to $actual_source"
  patch --batch -p1 -d "$SOURCE_DIR" < "$CARD_WIRE_BRIDGE_PATCH_FILE" >/dev/null
fi
printf 'Production card-wire bridge patch: %s\n' "$(basename "$CARD_WIRE_BRIDGE_PATCH_FILE")"

if ! grep -Fq 'bool isCardWireV1Snapshot' "$SOURCE_DIR/src/network/router.cpp"; then
  patch --dry-run --batch -p1 -d "$SOURCE_DIR" < "$CARD_WIRE_SNAPSHOT_PATCH_FILE" >/dev/null ||
    die "Card-wire snapshot compression patch does not apply cleanly to $actual_source"
  patch --batch -p1 -d "$SOURCE_DIR" < "$CARD_WIRE_SNAPSHOT_PATCH_FILE" >/dev/null
fi
printf 'Card-wire snapshot compression patch: %s\n' "$(basename "$CARD_WIRE_SNAPSHOT_PATCH_FILE")"

# The packet validation patch overlaps the earlier stream and lifecycle hunks.
# Recognize a fully prepared source tree before attempting those older patches.
if ! patch --dry-run --force --reverse -p1 -d "$SOURCE_DIR" < "$PACKET_VALIDATION_PATCH_FILE" >/dev/null; then
  if ! patch --dry-run --force --reverse -p1 -d "$SOURCE_DIR" < "$CLIENT_SOCKET_STREAM_PATCH_FILE" >/dev/null; then
    patch --dry-run --batch --forward -p1 -d "$SOURCE_DIR" < "$CLIENT_SOCKET_STREAM_PATCH_FILE" >/dev/null ||
      die "Client socket stream patch does not apply cleanly to $actual_source"
    patch --batch --forward -p1 -d "$SOURCE_DIR" < "$CLIENT_SOCKET_STREAM_PATCH_FILE" >/dev/null
  fi
  printf 'Client socket stream patch: %s\n' "$(basename "$CLIENT_SOCKET_STREAM_PATCH_FILE")"

  if ! patch --dry-run --force --reverse -p1 -d "$SOURCE_DIR" < "$SOCKET_LIFECYCLE_PATCH_FILE" >/dev/null; then
    patch --dry-run --batch --forward -p1 -d "$SOURCE_DIR" < "$SOCKET_LIFECYCLE_PATCH_FILE" >/dev/null ||
      die "Native socket lifecycle patch does not apply cleanly to $actual_source"
    patch --batch --forward -p1 -d "$SOURCE_DIR" < "$SOCKET_LIFECYCLE_PATCH_FILE" >/dev/null
  fi
  printf 'Native socket lifecycle patch: %s\n' "$(basename "$SOCKET_LIFECYCLE_PATCH_FILE")"
  patch --dry-run --batch --forward -p1 -d "$SOURCE_DIR" < "$PACKET_VALIDATION_PATCH_FILE" >/dev/null ||
    die "Native packet validation patch does not apply cleanly to $actual_source"
  patch --batch --forward -p1 -d "$SOURCE_DIR" < "$PACKET_VALIDATION_PATCH_FILE" >/dev/null
fi
printf 'Native packet validation patch: %s\n' "$(basename "$PACKET_VALIDATION_PATCH_FILE")"

if ! patch --dry-run --force --reverse -p1 -d "$SOURCE_DIR" < "$ROUTER_REQUEST_PATCH_FILE" >/dev/null; then
  patch --dry-run --batch --forward -p1 -d "$SOURCE_DIR" < "$ROUTER_REQUEST_PATCH_FILE" >/dev/null ||
    die "Native router request patch does not apply cleanly to $actual_source"
  patch --batch --forward -p1 -d "$SOURCE_DIR" < "$ROUTER_REQUEST_PATCH_FILE" >/dev/null
fi
printf 'Native router request patch: %s\n' "$(basename "$ROUTER_REQUEST_PATCH_FILE")"

export CC="${CC:-gcc-14}"
export CXX="${CXX:-g++-14}"
BUILD_JOBS="${FREEKILL_BUILD_JOBS:-1}"
[[ "$BUILD_JOBS" =~ ^[1-9][0-9]*$ ]] || die "FREEKILL_BUILD_JOBS must be a positive integer"
"$CMAKE_DIR/bin/cmake" -S "$SOURCE_DIR" -B "$SOURCE_DIR/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX"
"$CMAKE_DIR/bin/cmake" --build "$SOURCE_DIR/build" --parallel "$BUILD_JOBS"
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
