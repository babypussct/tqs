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

case "$(uname -m)" in
  x86_64|amd64) ;;
  *)
    die "This bootstrap uses the pinned amd64 static release. For Oracle A1/ARM64 use the source-build path described in $DEPLOY_DIR/README.md."
    ;;
esac

command -v apt-get >/dev/null 2>&1 || die "This bootstrap currently expects Debian/Ubuntu apt."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git sqlite3 tar tmux

ROOT="$FREEKILL_INSTALL_ROOT"
RELEASE_DIR="$ROOT/releases/freekill-asio-static-$FREEKILL_ASIO_RELEASE-amd64"
ARCHIVE="$ROOT/downloads/freekill-asio-static-$FREEKILL_ASIO_RELEASE-amd64.tar.gz"

install -d -m 0755 "$ROOT/downloads" "$ROOT/releases"

if [[ ! -f "$ARCHIVE" ]] || ! printf '%s  %s\n' "$FREEKILL_ASIO_STATIC_SHA256" "$ARCHIVE" | sha256sum -c - >/dev/null 2>&1; then
  curl --fail --location --retry 3 --output "$ARCHIVE.tmp" "$FREEKILL_ASIO_STATIC_URL"
  printf '%s  %s\n' "$FREEKILL_ASIO_STATIC_SHA256" "$ARCHIVE.tmp" | sha256sum -c -
  mv "$ARCHIVE.tmp" "$ARCHIVE"
fi

if [[ ! -x "$RELEASE_DIR/bin/freekill-asio" ]]; then
  extraction_dir="$(mktemp -d /tmp/freekill-asio.XXXXXX)"
  trap 'rm -rf "$extraction_dir"' EXIT
  tar -xzf "$ARCHIVE" -C "$extraction_dir"
  [[ -x "$extraction_dir/freekill-asio-static/bin/freekill-asio" ]] || die "Unexpected release layout"
  if [[ -e "$RELEASE_DIR" ]]; then
    die "Release directory exists but is incomplete: $RELEASE_DIR"
  fi
  mv "$extraction_dir/freekill-asio-static" "$RELEASE_DIR"
fi

if [[ -e "$ROOT/current" && ! -L "$ROOT/current" ]]; then
  die "$ROOT/current exists and is not a symlink; refusing to replace it"
fi
ln -sfn "$RELEASE_DIR" "$ROOT/current"

FREEKILL_RUNTIME_DIR="$ROOT/current" "$SCRIPT_DIR/install-packages.sh"

printf '\nBootstrap complete.\n'
printf 'Runtime: %s\n' "$ROOT/current"
printf 'Game TCP/UDP port: %s\n' "$FREEKILL_PORT"
printf 'Admin HTTP is bound by upstream freekill-asio on port 9000; do not expose port 9000 publicly.\n'
printf 'Next: run verify-install.sh, then start the server inside tmux using run-server.sh.\n'
