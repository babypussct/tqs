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

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lua-runtime.sh"

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
[[ -x "$RUNTIME_DIR/freekill-asio" ]] || {
  printf 'Runtime is not installed: %s\n' "$RUNTIME_DIR" >&2
  exit 1
}

cd "$RUNTIME_DIR"

lua54_prepare "$RUNTIME_DIR" || die 'Lua 5.4 runtime preflight failed; server was not started'
printf 'Lua runtime: %s\n' "$TQS_LUA54_BIN"

exec "$RUNTIME_DIR/freekill-asio" --port "$FREEKILL_PORT"
