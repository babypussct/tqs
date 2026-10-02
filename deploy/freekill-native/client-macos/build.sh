#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_DIR="${FREEKILL_SOURCE_DIR:-$SCRIPT_DIR/FreeKill}"
BUILD_DIR="${FREEKILL_BUILD_DIR:-$SCRIPT_DIR/build}"
FREEKILL_REF="${FREEKILL_REF:-v0.5.25}"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --depth 1 --branch "$FREEKILL_REF" \
    https://github.com/Qsgs-Fans/FreeKill.git "$SOURCE_DIR"
fi

git -C "$SOURCE_DIR" submodule update --init --depth 1 include

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="$(uname -m)"
cmake --build "$BUILD_DIR" --target FreeKill --parallel

printf 'Built client: %s\n' "$BUILD_DIR/FreeKill"
