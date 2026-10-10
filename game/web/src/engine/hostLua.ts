// SPDX-License-Identifier: GPL-3.0-or-later
//
// Lua side of the browser host. The original FreeKill client is a Qt/C++
// program that exposes a handful of native objects to Lua (fk.*, fk.Client,
// fk.Player). This file re-implements that surface in Lua on top of a small
// set of JS functions injected as the global table `__js`:
//
//   __js.cd(path) / __js.pwd() / __js.ls(path) -> "\n"-joined names
//   __js.exists(path) / __js.isDir(path)
//   __js.nowUs()                       microseconds since epoch
//   __js.log(level, msg)
//   __js.send(kind, command, hexData)  kind = "notify" | "reply"
//   __js.ui(command, json)             forward a UI event to React
//   __js.setup(pubkeyPem)              server asked for the login packet
//   __js.serverLag(serverMs)
//
// Binary strings never cross the JS<->Lua boundary directly (wasmoon converts
// strings as UTF-8), they are hex encoded instead.

export const HOST_LUA = String.raw`
local J = __js
fk = fk or {}

local function hex2bin(h)
  return (h:gsub("%x%x", function(c) return string.char(tonumber(c, 16)) end))
end
local function bin2hex(s)
  return (s:gsub(".", function(c) return string.format("%02x", c:byte()) end))
end
__host_hex2bin = hex2bin
__host_bin2hex = bin2hex

-- ----------------------------------------------------------- fk natives --

fk.FK_VER = "0.5.25"
fk.Player_Invalid = 0
fk.Player_Online = 1
fk.Player_Trust = 2
fk.Player_Run = 3
fk.Player_Leave = 4
fk.Player_Robot = 5
fk.Player_Offline = 6

local function fmt(msg, ...)
  if select("#", ...) == 0 then return tostring(msg) end
  local ok, s = pcall(string.format, msg, ...)
  return ok and s or tostring(msg)
end
fk.qDebug    = function(msg, ...) J.log("debug", fmt(msg, ...)) end
fk.qInfo     = function(msg, ...) J.log("info", fmt(msg, ...)) end
fk.qWarning  = function(msg, ...) J.log("warn", fmt(msg, ...)) end
fk.qCritical = function(msg, ...) J.log("error", fmt(msg, ...)) end
print = function(...)
  local t = {}
  for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
  J.log("info", table.concat(t, "\t"))
end

fk.GetMicroSecond = function() return J.nowUs() end
fk.GetDisabledPacks = function() return "[]" end

local function split_lines(s)
  local ret = {}
  if s == nil or s == "" then return ret end
  for line in (s .. "\n"):gmatch("(.-)\n") do
    if line ~= "" then ret[#ret + 1] = line end
  end
  return ret
end

fk.QmlBackend_cd = function(p) J.cd(p) end
fk.QmlBackend_pwd = function() return J.pwd() end
fk.QmlBackend_ls = function(p) return split_lines(J.ls(p or ".")) end
fk.QmlBackend_exists = function(p) return J.exists(p) end
fk.QmlBackend_isDir = function(p) return J.isDir(p) end
fk.Backend = {
  cd = fk.QmlBackend_cd, pwd = fk.QmlBackend_pwd, ls = fk.QmlBackend_ls,
  exists = fk.QmlBackend_exists, isDir = fk.QmlBackend_isDir,
}

local function QList(arr)
  return setmetatable(arr, {
    __index = {
      at = function(self, i) return self[i + 1] end,
      length = function(self) return #self end,
    }
  })
end
fk.QList = QList

-- ------------------------------------------------------------ fk.Player --

local FPlayer = {}
FPlayer.__index = FPlayer

local function newPlayer(id, name, avatar)
  return setmetatable({
    id = id, screenName = name or "", avatar = avatar or "",
    state = fk.Player_Online, died = false, totalGameTime = 0,
    gamedata = QList { 0, 0, 0 }, thinking = false, ready = false,
  }, FPlayer)
end

function FPlayer:getId() return self.id end
function FPlayer:setId(v) self.id = v end
function FPlayer:getScreenName() return self.screenName end
function FPlayer:setScreenName(v) self.screenName = v end
function FPlayer:getAvatar() return self.avatar end
function FPlayer:setAvatar(v) self.avatar = v end
function FPlayer:getTotalGameTime() return self.totalGameTime end
function FPlayer:addTotalGameTime(v) self.totalGameTime = self.totalGameTime + (v or 0) end
function FPlayer:getState() return self.state end
function FPlayer:setState(v) self.state = v end
function FPlayer:getGameData() return self.gamedata end
function FPlayer:setGameData(total, win, run) self.gamedata = QList { total, win, run } end
function FPlayer:isDied() return self.died end
function FPlayer:setDied(v) self.died = v end
function FPlayer:getThinking() return self.thinking end
function FPlayer:setThinking(v) self.thinking = v end
function FPlayer:isReady() return self.ready end
function FPlayer:setReady(v) self.ready = v end

-- ------------------------------------------------------------ fk.Client --

local FClient = { players = {}, _self = nil }
FClient.__index = FClient

-- Tolerant serializer for UI payloads (Lua tables -> JSON).
local function to_json(v, depth, seen)
  depth = depth or 0
  local t = type(v)
  if t == "nil" then return "null"
  elseif t == "boolean" then return v and "true" or "false"
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if math.type(v) == "integer" then return tostring(v) end
    return string.format("%.14g", v)
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      local m = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
      return m[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
  elseif t == "table" then
    if depth > 24 then return "null" end
    seen = seen or {}
    if seen[v] then return "null" end
    seen[v] = true
    local n = #v
    local count = 0
    for _ in pairs(v) do count = count + 1 end
    local out = {}
    if n > 0 and count == n then
      for i = 1, n do out[i] = to_json(v[i], depth + 1, seen) end
      seen[v] = nil
      return "[" .. table.concat(out, ",") .. "]"
    end
    if count == 0 then seen[v] = nil; return (getmetatable(v) == nil) and "[]" or "{}" end
    for k, val in pairs(v) do
      local tk = type(k)
      if (tk == "string" or tk == "number") and type(val) ~= "function" and type(val) ~= "userdata" and type(val) ~= "thread" then
        out[#out + 1] = to_json(tostring(k)) .. ":" .. to_json(val, depth + 1, seen)
      end
    end
    seen[v] = nil
    return "{" .. table.concat(out, ",") .. "}"
  end
  return "null"
end
__host_to_json = to_json

function FClient:sendSetupPacket(pubkey) J.setup(pubkey) end
function FClient:setupServerLag(t) J.serverLag(t) end
function FClient:replyToServer(command, data) J.send("reply", command, bin2hex(data or "")) end
function FClient:notifyServer(command, data) J.send("notify", command, bin2hex(data or "")) end
function FClient:addPlayer(id, name, avatar)
  local p = newPlayer(id, name, avatar)
  self.players[id] = p
  return p
end
function FClient:removePlayer(id) self.players[id] = nil end
function FClient:getSelf() return self._self end
function FClient:changeSelf(id) self._self = self.players[id] or self._self end
function FClient:saveRecord() end
function FClient:saveGameData() end
function FClient:installMyAESKey() end
function FClient:notifyUI(command, data)
  local ok, s = pcall(to_json, data)
  J.ui(command, ok and s or "null")
end

__host_client = setmetatable({ players = {} }, FClient)
__host_client._self = newPlayer(0, "", "")
fk.Client = FClient
fk.Player = FPlayer

-- -------------------------------------------------------- JS entrypoints --

local function report(err)
  local detail = debug.traceback(tostring(err), 2)
  J.log("error", detail)
  return detail
end

function __host_recv(command, hex, is_request)
  local ok, err = xpcall(ClientCallback, report, nil, command, hex2bin(hex), is_request)
  if not ok then error(tostring(err), 0) end
end

-- Evaluate a Lua chunk and return its result as JSON. Used by the UI for
-- read-only queries such as general/card/skill data.
function __host_eval(code)
  local fn, err = load(code, "=ui", "t")
  if not fn then error(report(err), 0) end
  local ok, ret = xpcall(fn, report)
  if not ok then error(tostring(ret), 0) end
  local ok2, s = pcall(to_json, ret)
  if not ok2 then error(report(s), 0) end
  return s
end

-- Call a global function by name with JSON-encoded argument array.
function __host_call(name, args_json)
  local f = _G[name]
  if type(f) ~= "function" then error(report("no such Lua function: " .. tostring(name)), 0) end
  local args = json.decode(args_json)
  local ok, ret = xpcall(f, report, table.unpack(args, 1, #args))
  if not ok then error(tostring(ret), 0) end
  local ok2, s = pcall(to_json, ret)
  if not ok2 then error(report(s), 0) end
  return s
end

-- Browser UI actions use the same native Lua CBOR encoder as the Qt client.
-- Arguments arrive as JSON through __host_call; no Lua source is interpolated
-- from user inputs such as room names or passwords.
function __web_notify(command, data)
  if type(command) ~= 'string' or command == '' then
    error('invalid command')
  end
  __host_client:notifyServer(command, cbor.encode(data))
  return true
end

-- QML sends its reply payload through the native client as CBOR bytes.
-- In particular, the skill-invoke handler returns the strings "1" or
-- "__cancel"; passing raw UTF-8 would be interpreted as invalid CBOR by
-- Request:_checkReply on the server.
function __web_reply(data)
  if type(data) ~= 'string' and type(data) ~= 'table' then error('invalid reply value') end
  __host_client:replyToServer('', cbor.encode(data))
  return true
end

-- The transport compares the wire representation independently before it
-- authorizes any reply. Both functions use the same Lua CBOR implementation.
function __web_reply_hex(data)
  if type(data) ~= 'string' and type(data) ~= 'table' then error('invalid reply value') end
  return bin2hex(cbor.encode(data))
end

-- Use FreeKill's actual Hegemony rules, including wild/subkingdom handling.
-- Reject pairs which match nominally but have no enabled common kingdom.
function __web_general_kingdoms(main, deputy, enabled)
  if type(main) ~= 'string' or type(deputy) ~= 'string' or main == deputy or
     type(enabled) ~= 'table' or not Fk.generals[main] or not Fk.generals[deputy] then
    return {}
  end
  if not Fk:canMatchInHegemony(main, deputy, enabled) then return {} end
  return Fk:getKingdomInHegemony(main, deputy, enabled)
end

function __web_general_labels(generals)
  local labels = {}
  for i, name in ipairs(generals) do labels[i] = Fk:translate(name) end
  return labels
end

local function general_reply_data(main, deputy, kingdom, enabled)
  if type(kingdom) ~= 'string' or kingdom == '' or kingdom:find(',', 1, true) then
    error('invalid kingdom')
  end
  local kingdoms = __web_general_kingdoms(main, deputy, enabled)
  if not table.contains(kingdoms, kingdom) then error('invalid hegemony general pair') end
  return {main .. ',' .. deputy, 'kingdom,' .. kingdom}
end

-- Pure expected-wire calculation, then the separately authorized send.
-- The server splits BOTH array elements on commas after CBOR decoding.
function __web_general_reply_hex(main, deputy, kingdom, enabled)
  return bin2hex(cbor.encode(general_reply_data(main, deputy, kingdom, enabled)))
end

function __web_general_reply(main, deputy, kingdom, enabled)
  __host_client:replyToServer('', cbor.encode(general_reply_data(main, deputy, kingdom, enabled)))
  return true
end

function __web_room_feasible(mode, player_num, timeout)
  local m = Fk.game_modes[mode]
  if not m then return false end
  local settings = { playerNum = player_num, timeout = timeout, gameMode = mode,
    _game = {}, _mode = {} }
  return m:feasible(settings)
end
`;
