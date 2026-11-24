#!/usr/bin/env bash
set -Eeuo pipefail

# Run with the native Linux build dependencies and an extracted source tree.
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE="$(CDPATH= cd -- "${1:?Usage: test-client-socket-stream.sh SOURCE_DIR}" && pwd)/src"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
"${CXX:-g++}" -std=c++23 -O1 -I"$SOURCE" -include "$SOURCE/pch.h" \
  "$SOURCE/network/client_socket.cpp" "$HERE/client-socket-stream.cpp" \
  -o "$WORK/client-socket-stream" -lcbor -lspdlog -lfmt -lboost_system -pthread
"$WORK/client-socket-stream"
