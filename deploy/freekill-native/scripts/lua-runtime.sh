#!/usr/bin/env bash

# Shared Lua runtime contract for freekill-asio.
#
# The native binary starts the room worker by executing the literal command
# `lua5.4`.  A generic `lua` on PATH is not sufficient: on developer
# machines it may resolve to Lua 5.5, while the package's native modules are
# built for 5.4.  Keep discovery and module-path setup in one place so the
# interactive launcher and the install verifier cannot drift apart.

lua54_prepare() {
  local runtime_dir="$1"
  local candidate_dir candidate version
  local -a candidate_dirs=()

  # Prefer a runtime-bundled interpreter, then explicit Lua 5.4 locations,
  # then every PATH directory.  We only accept a binary named lua5.4 or
  # lua-5.4; a generic `lua` is deliberately never promoted to the native
  # child command because it is the source of the recurring 5.5 mismatch.
  candidate_dirs+=("$runtime_dir/bin")
  candidate_dirs+=(
    "/usr/local/bin"
    "/usr/bin"
    "/opt/homebrew/opt/lua@5.4/bin"
    "/usr/local/opt/lua@5.4/bin"
  )
  while IFS=: read -r candidate_dir; do
    [[ -n "$candidate_dir" ]] && candidate_dirs+=("$candidate_dir")
  done <<< "${PATH:-}"

  TQS_LUA54_BIN=''
  for candidate_dir in "${candidate_dirs[@]}"; do
    for candidate in "$candidate_dir/lua5.4" "$candidate_dir/lua-5.4"; do
      [[ -x "$candidate" ]] || continue
      version="$($candidate -e 'io.write(_VERSION)' 2>/dev/null || true)"
      if [[ "$version" == 'Lua 5.4' ]]; then
        TQS_LUA54_BIN="$candidate"
        break 2
      fi
    done
  done

  if [[ -z "$TQS_LUA54_BIN" ]]; then
    printf '%s\n' \
      'ERROR: freekill-asio requires an executable named lua5.4 (Lua 5.4.x).' \
      '       A generic `lua`/Lua 5.5 was not accepted. Install Lua 5.4 and its socket/filesystem modules, then retry.' >&2
    return 1
  fi

  TQS_LUA54_DIR="$(CDPATH= cd -- "$(dirname -- "$TQS_LUA54_BIN")" && pwd -P)"
  export TQS_LUA54_BIN TQS_LUA54_DIR
  export PATH="$TQS_LUA54_DIR:$PATH"

  local lua_path_prefix=""
  local lua_cpath_prefix=""
  # Keep default Lua paths through `;;`, while making a runtime-local Lua
  # tree usable on macOS, source builds, and static bundles alike.
  if [[ -d "$runtime_dir/rocks54/share/lua/5.4" ]]; then
    lua_path_prefix+="$runtime_dir/rocks54/share/lua/5.4/?.lua;$runtime_dir/rocks54/share/lua/5.4/?/init.lua;"
  fi
  if [[ -d "$runtime_dir/rocks54/lib/lua/5.4" ]]; then
    lua_cpath_prefix+="$runtime_dir/rocks54/lib/lua/5.4/?.so;$runtime_dir/rocks54/lib/lua/5.4/?/core.so;"
  fi
  if [[ -d "$runtime_dir/luasocket" ]]; then
    lua_path_prefix+="$runtime_dir/luasocket/?.lua;$runtime_dir/luasocket/?/init.lua;"
    lua_cpath_prefix+="$runtime_dir/luasocket/?.so;$runtime_dir/luasocket/?/core.so;"
  fi

  export LUA_PATH="${lua_path_prefix}${LUA_PATH:-;;}"
  export LUA_CPATH="${lua_cpath_prefix}${LUA_CPATH:-;;}"

  # Fail before opening the server socket if the interpreter/module ABI is
  # incomplete.  Otherwise freekill-asio accepts logins and only reports a
  # vague "Lua is not working" after the first room starts.
  "$TQS_LUA54_BIN" -e 'assert(_VERSION == "Lua 5.4"); assert(require("socket")); assert(require("lfs"))' >/dev/null 2>&1 || {
    printf '%s\n' \
      'ERROR: Lua 5.4 was found, but LuaSocket or LuaFileSystem could not be loaded.' \
      '       Check the runtime-local rocks54 tree or install lua-socket and lua-filesystem for Lua 5.4.' >&2
    return 1
  }
}
