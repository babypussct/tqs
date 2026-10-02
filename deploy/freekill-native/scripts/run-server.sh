#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEPLOY_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$DEPLOY_DIR/versions.env"

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
[[ -x "$RUNTIME_DIR/freekill-asio" ]] || {
  printf 'Runtime is not installed: %s\n' "$RUNTIME_DIR" >&2
  exit 1
}

cd "$RUNTIME_DIR"

# The static release bundles LuaSocket beside its launcher. Source builds use
# the system Lua modules and keep the normal environment.
if [[ -d "$RUNTIME_DIR/luasocket" ]]; then
  export LUA_PATH=";;$RUNTIME_DIR/luasocket/"
fi

exec "$RUNTIME_DIR/freekill-asio" --port "$FREEKILL_PORT"
