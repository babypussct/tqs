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

if grep -Eq '"tqsAuthRequired"[[:space:]]*:[[:space:]]*true' "$RUNTIME_DIR/freekill.server.config.json"; then
  game_ticket_secret="${TQS_GAME_TICKET_SECRET:-}"
  [[ "${#game_ticket_secret}" -ge 32 ]] || die 'TQS_GAME_TICKET_SECRET must contain at least 32 characters when tqsAuthRequired is enabled'
  export TQS_GAME_TICKET_SECRET="$game_ticket_secret"
fi

lua54_prepare "$RUNTIME_DIR" || die 'Lua 5.4 runtime preflight failed; server was not started'
printf 'Lua runtime: %s\n' "$TQS_LUA54_BIN"

# freekill-asio launches the Lua worker from packages/freekill-core.  When a
# verified QA tree is present, keep it outside public packages/ and expose it
# through a runtime-only symlink after freekill-asio has calculated its public
# flist MD5.  A broken symlink is deliberately present during native startup:
# filesystem traversal does not follow it, so the public MD5 remains identical
# to the mobile release.  Production releases omit the QA tree entirely and
# start without creating the link.
QA_LINK="$RUNTIME_DIR/packages/freekill-core/qa_packages"
QA_TARGET_REL="../../qa_packages"
QA_PENDING_REL="../../.tqs_qa-pending"
if [[ -f "$RUNTIME_DIR/qa_packages/tqs_qa/init.lua" ]]; then
  [[ -L "$QA_LINK" || ! -e "$QA_LINK" ]] || die "refusing to replace non-symlink QA path: $QA_LINK"
  rm -f -- "$QA_LINK"
  ln -s -- "$QA_PENDING_REL" "$QA_LINK"

  (
    for _ in {1..600}; do
      # $$ remains the native PID after exec below.  Stop quietly if startup
      # failed before the listener became ready.
      kill -0 "$$" 2>/dev/null || exit 0
      if command -v ss >/dev/null 2>&1 &&
        ss -lntH 2>/dev/null | awk -v port=":$FREEKILL_PORT" '$4 ~ port "$" || $4 ~ port "]$"' | grep -q .; then
        ready_link="${QA_LINK}.ready.$$"
        rm -f -- "$ready_link"
        ln -s -- "$QA_TARGET_REL" "$ready_link"
        mv -Tf -- "$ready_link" "$QA_LINK"
        exit 0
      fi
      sleep 0.1
    done
    printf 'ERROR: native listener did not become ready before QA link timeout\n' >&2
  ) &
else
  [[ ! -L "$QA_LINK" && ! -e "$QA_LINK" ]] || die "unexpected QA path in production runtime: $QA_LINK"
fi

# Keep the tmux pseudo-TTY attached: freekill-asio exposes an interactive CLI
# and exits when its stdin is detached.  Do not replace this with a pipeline or
# a detached supervisor.
exec "$RUNTIME_DIR/freekill-asio" --port "$FREEKILL_PORT"
