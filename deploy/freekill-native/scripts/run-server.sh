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

# QA packages are loaded by the native Lua server but are deliberately absent
# from the public client bundle.  freekill-asio regenerates flist.txt from all
# packages during startup, so remove server-only entries after that generation
# and before any browser can use the public MD5 handshake.
publicize_flist() {
  local flist="$1"
  [[ -f "$flist" ]] || return 1
  local temporary
  temporary="$(mktemp "${flist}.public.XXXXXX")"
  awk -v prefix='packages/tqs_qa/' \
    'BEGIN { RS=";"; ORS=";" } length($0) > 0 && index($0, prefix) != 1 { print }' \
    "$flist" > "$temporary"
  if cmp -s "$flist" "$temporary"; then
    rm -f -- "$temporary"
    return 0
  fi
  chmod --reference="$flist" "$temporary" 2>/dev/null || true
  chown --reference="$flist" "$temporary" 2>/dev/null || true
  mv -- "$temporary" "$flist"
  printf 'Public flist: server-only QA entries removed\n'
}

wait_for_public_flist() {
  local flist="$1"
  local before=''
  if [[ -f "$flist" ]]; then
    before="$(stat -c '%s:%Y:%y' "$flist" 2>/dev/null || true)"
  fi
  for _ in $(seq 1 100); do
    [[ -f "$flist" ]] || { sleep 0.1; continue; }
    local first second
    first="$(stat -c '%s:%Y:%y' "$flist" 2>/dev/null || true)"
    sleep 0.1
    second="$(stat -c '%s:%Y:%y' "$flist" 2>/dev/null || true)"
    if [[ -n "$first" && "$first" == "$second" && "$first" != "$before" ]]; then
      publicize_flist "$flist"
      return 0
    fi
  done
  # A pre-existing public flist is still safe; a server that never produced a
  # flist is not, because clients cannot pass the MD5 handshake.
  publicize_flist "$flist"
}

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
[[ -x "$RUNTIME_DIR/freekill-asio" ]] || {
  printf 'Runtime is not installed: %s\n' "$RUNTIME_DIR" >&2
  exit 1
}

cd "$RUNTIME_DIR"

lua54_prepare "$RUNTIME_DIR" || die 'Lua 5.4 runtime preflight failed; server was not started'
printf 'Lua runtime: %s\n' "$TQS_LUA54_BIN"

if command -v setsid >/dev/null 2>&1; then
  setsid "$RUNTIME_DIR/freekill-asio" --port "$FREEKILL_PORT" &
else
  "$RUNTIME_DIR/freekill-asio" --port "$FREEKILL_PORT" &
fi
server_pid=$!

stop_server() {
  if kill -0 "$server_pid" 2>/dev/null; then
    kill -TERM -- "-$server_pid" 2>/dev/null || kill -TERM "$server_pid" 2>/dev/null || true
  fi
}
trap stop_server INT TERM HUP

wait_for_public_flist "$RUNTIME_DIR/flist.txt" || {
  stop_server
  wait "$server_pid" 2>/dev/null || true
  die 'native server did not produce a public flist.txt'
}

trap - INT TERM HUP
wait "$server_pid"
