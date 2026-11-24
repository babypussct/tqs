#!/usr/bin/env bash
set -Eeuo pipefail

# Run with the native Linux build dependencies and the patched source tree.
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE="$(CDPATH= cd -- "${1:?Usage: test-native-socket-lifecycle.sh SOURCE_DIR}" && pwd)/src"
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
CXX_FLAGS=(-std=c++23 -O1 -I"$SOURCE" -include "$SOURCE/pch.h")
LIBS=(-lcbor -lspdlog -lfmt -lboost_system -pthread)
"${CXX:-g++}" "${CXX_FLAGS[@]}" -c "$SOURCE/network/client_socket.cpp" -o "$WORK/client.o"
for test in client-socket-lifecycle client-socket-stream client-socket-packet-validation; do
  "${CXX:-g++}" "${CXX_FLAGS[@]}" "$WORK/client.o" "$HERE/$test.cpp" -o "$WORK/$test" "${LIBS[@]}"
  "$WORK/$test"
done
"${CXX:-g++}" "${CXX_FLAGS[@]}" "$WORK/client.o" "$SOURCE/network/server_socket.cpp" \
  "$HERE/server-socket-lifecycle.cpp" -o "$WORK/server-socket-lifecycle" "${LIBS[@]}"
"$WORK/server-socket-lifecycle"
