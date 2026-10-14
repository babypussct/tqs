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
local function to_json(v, depth, seen, budget)
  depth = depth or 0
  budget = budget or {nodes = 0, bytes = 0}
  budget.nodes = budget.nodes + 1
  if budget.nodes > 25000 then error("UI JSON exceeds node limit", 0) end
  local function emit(s)
    budget.bytes = budget.bytes + #s
    if budget.bytes > 1024 * 1024 then error("UI JSON exceeds byte limit", 0) end
    return s
  end
  local t = type(v)
  if t == "nil" then return emit("null")
  elseif t == "boolean" then return emit(v and "true" or "false")
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return emit("null") end
    if math.type(v) == "integer" then return emit(tostring(v)) end
    return emit(string.format("%.14g", v))
  elseif t == "string" then
    if #v > 1024 * 1024 then error("UI JSON string exceeds byte limit", 0) end
    return emit('"' .. v:gsub('[%c"\\]', function(c)
      local m = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
      return m[c] or string.format("\\u%04x", c:byte())
    end) .. '"')
  elseif t == "table" then
    if depth > 24 then return emit("null") end
    seen = seen or {}
    if seen[v] then return emit("null") end
    seen[v] = true
    local n = #v
    local count = 0
    for _ in pairs(v) do count = count + 1 end
    local out = {}
    if n > 0 and count == n then
      for i = 1, n do out[i] = to_json(v[i], depth + 1, seen, budget) end
      seen[v] = nil
      return emit("[" .. table.concat(out, ",") .. "]")
    end
    if count == 0 then seen[v] = nil; return emit((getmetatable(v) == nil) and "[]" or "{}") end
    for k, val in pairs(v) do
      local tk = type(k)
      if (tk == "string" or tk == "number") and type(val) ~= "function" and type(val) ~= "userdata" and type(val) ~= "thread" then
        out[#out + 1] = to_json(tostring(k), depth + 1, seen, budget) .. ":" .. to_json(val, depth + 1, seen, budget)
      end
    end
    seen[v] = nil
    return emit("{" .. table.concat(out, ",") .. "}")
  end
  return emit("null")
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
-- Explain only a prohibition actually returned by an installed native skill.
-- This metadata never changes card/target validity or the reply payload.
local function annotate_card_reason(value)
  value.disabledReason = ''
  if value.enabled ~= false or not Self or type(value.id) ~= 'number' then return end
  local card = Fk:getCardById(value.id)
  if not card or card.trueName ~= 'peach' then return end
  for _, skill in ipairs(Fk:currentRoom().status_skills[ProhibitSkill] or {}) do
    local name = skill.skeleton and skill.skeleton.name or skill.name
    if (name == 'new_battle_royal&' or name == 'battle_royal&') and skill:prohibitUse(Self, card) then
      value.disabledReason = name == 'new_battle_royal&' and '#web-peach-battle-new' or '#web-peach-battle-old'
      return
    end
  end
end

local public_properties = {
  hp = true, maxHp = true, shield = true, handcardNum = true,
  dead = true, died = true, surrendered = true, drank = true, phase = true,
  general = true, deputyGeneral = true, kingdom = true,
  role_shown = true, chained = true, faceup = true,
}

local function finite_number(value)
  return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

local function public_scalar(value, max_string)
  if finite_number(value) or type(value) == 'boolean' then return value end
  if type(value) == 'string' and #value <= (max_string or 160) then return value end
  return nil
end

local function hidden_hegemony_kingdom(id)
  local client = rawget(_G, 'ClientInstance')
  if not client or type(client.getSettings) ~= 'function' or type(client.getPlayerById) ~= 'function' then return false end
  local ok_mode, mode = pcall(client.getSettings, client, 'gameMode')
  if not ok_mode or mode ~= 'new_heg_mode' then return false end
  local ok_player, player = pcall(client.getPlayerById, client, id)
  return ok_player and player ~= nil and player ~= Self and player.role_shown ~= true
end

-- Resolve the same package-level general art identity used by the native
-- SkinBank.  The browser receives only a safe package name; it never receives
-- a Lua General object or private marks.  Missing media is intentionally left
-- to the browser fallback instead of borrowing another variant's portrait.
local function general_extension(name)
  if type(name) ~= 'string' or name == '' or name == 'anjiang' or name == 'hidden' then return '' end
  local generals = rawget(Fk, 'generals')
  local general = generals and generals[name]
  local package = general and general.package
  local extension = package and package.extensionName
  return type(extension) == 'string' and #extension <= 120 and extension ~= '' and extension or ''
end

local function emit_general_art(id, slot, name)
  local extension = general_extension(name)
  if extension ~= '' then
    J.ui('GeneralArtUpdate', to_json({id, slot, name, extension}))
  end
end

-- ClientPlayer:sendDataToUI() iterates every native property, including private
-- seat/role/general state. Keep the browser-facing shape explicit and copy the
-- scalar before serialization so private tables/userdata cannot leak through a
-- future property addition.
local function project_property(data)
  if type(data) ~= 'table' or math.type(data[1]) ~= 'integer' or
      type(data[2]) ~= 'string' or not public_properties[data[2]] then return nil end
  local id, name, value = data[1], data[2], data[3]
  if name == 'general' or name == 'deputyGeneral' then
    if type(value) ~= 'string' or #value > 120 then return nil end
    if value == 'anjiang' or value == 'hidden' then value = '' end
  elseif name == 'kingdom' then
    if type(value) ~= 'string' or #value > 120 then return nil end
    if hidden_hegemony_kingdom(id) then value = '' end
  elseif name == 'phase' then
    if type(value) ~= 'string' and not finite_number(value) then return nil end
  elseif name == 'dead' or name == 'died' or name == 'role_shown' or
      name == 'surrendered' or name == 'chained' or name == 'faceup' then
    if type(value) ~= 'boolean' then return nil end
  else
    if not finite_number(value) then return nil end
  end
  return {id, name, value}
end

local function project_public_mark(data, banner)
  if type(data) ~= 'table' then return nil end
  local name, value = data[1], data[2]
  local id = data[1]
  if not banner then id, name, value = data[1], data[2], data[3] end
  if (not banner and math.type(id) ~= 'integer') or type(name) ~= 'string' or
      #name > 120 or not name:startsWith('@') then return nil end
  value = public_scalar(value)
  if value == nil then return nil end
  return banner and {name, value} or {id, name, value}
end

local function project_card(value)
  if type(value) ~= 'table' then return nil end
  local card = {}
  for _, key in ipairs({'name', 'trueName', 'suit', 'number'}) do
    local field = value[key]
    if key == 'name' or key == 'trueName' then
      if type(field) == 'string' and #field <= 120 then card[key] = field end
    elseif finite_number(field) then
      card[key] = field
    end
  end
  -- The native QML client resolves card art from the card's package/name and
  -- lets an active FilterSkill override the picture through getPicName().
  -- Keep those two public display hints so the web client can make the same
  -- exact lookup instead of guessing that (for example) every "slash" is the
  -- espionage "stab__slash" artwork.
  local package = value.package
  local extension = package and package.extensionName
  if type(extension) == 'string' and #extension <= 120 and extension ~= '' then
    card.extension = extension
  end
  if type(value.getPicName) == 'function' then
    local ok, pic_name = pcall(value.getPicName, value)
    if ok and type(pic_name) == 'string' and #pic_name <= 120 and pic_name ~= '' then
      card.picName = pic_name
    end
  end
  return next(card) and card or nil
end

-- CardItem:toData() is used both when a request scene is created (_new) and
-- when an existing item changes (CardItem).  Keep both paths identical: the
-- native QML client always has the CardModel/cardId available for artwork,
-- while React otherwise receives only the selectable item's id and falls back
-- to a neutral card frame.  The public projection is deliberately tiny and
-- never crosses the native Card object itself.
local function project_card_item(value)
  if type(value) ~= 'table' then return end
  local card = project_card(value.card)
  if not card and math.type(value.id) == 'integer' then
    local ok, native_card = pcall(Fk.getCardById, Fk, value.id)
    if ok then card = project_card(native_card) end
  end
  value.card = card
end

function FClient:notifyUI(command, data)
  -- ClientBase:reconnect() has already consumed this complete room snapshot
  -- to rebuild the native/Lua state and then emits the same event for QML.
  -- React does not use that private snapshot (the individual EnterRoom,
  -- StartGame, ArrangeSeats, MoveCards and PropertyUpdate events are the web
  -- projection), so do not serialize and cross the whole object a second
  -- time. ShowVirtualCard can likewise contain a native Card object with a
  -- large graph of derived fields; the current web reducer ignores it. Keep
  -- both event boundaries with a tiny marker instead of creating a peak-sized
  -- CBOR/JSON copy in the browser or failing the whole Lua dispatch at the
  -- serializer budget.
  if command == 'Reconnect' or command == 'ShowVirtualCard' then
    J.ui(command, '{}')
    return
  end
  -- MoveCards contains raw card IDs and visibility maps. The web projection
  -- gets hand counts/equipment from __host_recv instead, so preserve only the
  -- event boundary and never cross the private move graph.
  if command == 'MoveCards' then
    J.ui(command, '{}')
    return
  end
  if command == 'PropertyUpdate' then
    data = project_property(data)
    if not data then return end
  elseif command == 'SetPlayerMark' then
    data = project_public_mark(data, false)
    if not data then return end
  elseif command == 'SetBanner' then
    data = project_public_mark(data, true)
    if not data then return end
  elseif command == 'GameLog' and (type(data) ~= 'string' or #data > 10000) then
    return
  end
  if command == 'UpdateRequestUI' and type(data) == 'table' then
    -- RoomModel.qml keeps the native fallback prompt when a card request
    -- arrives without an explicit prompt. The browser reducer receives the
    -- scene delta instead of the QML callback, so project that fallback on
    -- every delta (including the first selection update) to avoid replacing
    -- it with an empty/raw request key.
    local current_handler = ClientInstance and ClientInstance.current_request_handler
    local fallback_prompt = current_handler and current_handler._web_prompt_fallback
    if (data._prompt == nil or data._prompt == '') and type(fallback_prompt) == 'string' then
      data._prompt = fallback_prompt
    end
    for _, value in ipairs(data.CardItem or {}) do
      project_card_item(value)
      local h = ClientInstance and ClientInstance.current_request_handler
      local item = h and h.scene and h.scene:getAllItems('CardItem')[value.id]
      -- Deltas can omit enabled. Read the current native scene before explaining.
      local state = {id = value.id, enabled = item and item.enabled}
      annotate_card_reason(state)
      value.disabledReason = state.disabledReason
    end
    for _, entry in ipairs(data._new or {}) do
      if entry.type == 'CardItem' then
        project_card_item(entry.data)
        annotate_card_reason(entry.data)
      end
    end
  end
  local ok, s = pcall(to_json, data)
  if not ok then error("UI serialization failed for " .. tostring(command) .. ": " .. tostring(s), 0) end
  J.ui(command, s)
  if command == 'PropertyUpdate' and (data[2] == 'general' or data[2] == 'deputyGeneral') and data[3] ~= '' then
    emit_general_art(data[1], data[2], data[3])
  end
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
  -- The native RoomModel.qml derives these prompts from the first request
  -- field when the server sends nil/empty prompt. Preserve that behavior in
  -- the browser projection; otherwise the scene reaches React with an empty
  -- prompt and later deltas can expose the raw #AskFor* identifier.
  if is_request and (command == 'AskForUseActiveSkill' or command == 'AskForUseCard'
      or command == 'AskForResponseCard') then
    local decoded_ok, request_data = pcall(cbor.decode, hex2bin(hex))
    local handler = ClientInstance and ClientInstance.current_request_handler
    if decoded_ok and type(request_data) == 'table' and handler and
        (handler.prompt == nil or handler.prompt == '') then
      local prefix = command == 'AskForUseActiveSkill' and '#AskForUseActiveSkill'
        or (command == 'AskForUseCard' and '#AskForUseCard' or '#AskForResponseCard')
      local name = request_data[1]
      if type(name) == 'string' and name ~= '' then
        handler._web_prompt_fallback = prefix .. ':::' .. name
      end
    end
  end
  -- Lua tracks all hand sizes while MoveCards only forwards visibility data
  -- to QML. Publish counts for the board without forwarding any card IDs.
  if command == 'MoveCards' or command == 'Reconnect' then
    local function project_public_card(card, owner)
      if not card then return nil end
      local result = {name = card.name, suit = card.suit, number = card.number}
      local subtype_ok, subtype = pcall(card.getSubtypeString, card)
      if subtype_ok and type(subtype) == 'string' and #subtype <= 40 then result.subtype = subtype end
      local package = card.package
      local extension = package and package.extensionName
      if type(extension) == 'string' and #extension <= 120 and extension ~= '' then result.extension = extension end
      if type(card.getPicName) == 'function' then
        local pic_ok, pic_name = pcall(card.getPicName, card)
        if pic_ok and type(pic_name) == 'string' and #pic_name <= 120 and pic_name ~= '' then
          result.picName = pic_name
        end
      end
      if result.subtype == 'weapon' and type(card.getAttackRange) == 'function' then
        local range_ok, range = pcall(card.getAttackRange, card, owner)
        if range_ok and finite_number(range) then result.range = range end
      end
      return result
    end
    for _, player in ipairs(ClientInstance.players) do
      J.ui('PropertyUpdate', to_json({player.id, 'handcardNum', player:getHandcardNum()}))
      local equipment = {}
      for _, id in ipairs(player:getCardIds('e')) do
        local card = Fk:getCardById(id)
        local projected = project_public_card(card, player)
        if projected then table.insert(equipment, projected) end
      end
      local delayed_tricks = {}
      for _, id in ipairs(player:getCardIds('j')) do
        local card = Fk:getCardById(id)
        local projected = project_public_card(card, player)
        if projected then table.insert(delayed_tricks, projected) end
      end
      J.ui('EquipmentUpdate', to_json({player.id, equipment, delayed_tricks}))
    end
  end
  -- Hegemony uses anjiang publicly and private marks for the actual pair.
  -- Read only Self's two marks, never enumerate another player's marks.
  if command == 'SetPlayerMark' or command == 'PropertyUpdate' or command == 'ChangeSelf' or command == 'Reconnect' then
    if Self and ClientInstance and table.contains(ClientInstance.players, Self) then
      local function own_general(property, mark)
        local name = Self[property]
        if name == 'anjiang' then name = Self:getMark(mark) end
        return type(name) == 'string' and name or ''
      end
      local main = own_general('general', '__heg_general')
      local deputy = own_general('deputyGeneral', '__heg_deputy')
      J.ui('SelfGenerals', to_json({Self.id, main, deputy,
        general_extension(main), general_extension(deputy)}))
    end
    if command ~= 'SetPlayerMark' and ClientInstance:getSettings('gameMode') == 'new_heg_mode' then
      local H = require 'packages.hegemony.util'
      for _, player in ipairs(ClientInstance.players) do
        local kingdom = ''
        if player == Self or player.role_shown then kingdom = H.getKingdom(player) end
        J.ui('VisibleKingdom', to_json({player.id, type(kingdom) == 'string' and kingdom or ''}))
      end
    end
  end
  -- Native QML already owns hand cards, photos and action buttons. Lua's
  -- handler constructor creates these before h.change is initialized, so
  -- its first delta contains updates without _new. Seed React from the
  -- actual Lua scene once per supported request; later deltas stay incremental.
  if is_request and (command == 'PlayCard' or command == 'AskForUseActiveSkill'
      or command == 'AskForUseCard' or command == 'AskForResponseCard') then
    local h = ClientInstance and ClientInstance.current_request_handler
    local scene = h and h.scene
    if scene then
      local snapshot_prompt = h.prompt
      if snapshot_prompt == nil or snapshot_prompt == '' then
        snapshot_prompt = h._web_prompt_fallback or ''
      end
      local snapshot = { _type = scene.scene_name, _prompt = snapshot_prompt, _new = {} }
      for _, kind in ipairs({'CardItem', 'Photo', 'Button', 'SkillButton', 'SpecialSkills', 'Interaction'}) do
        for _, item in pairs(scene:getAllItems(kind)) do
          local value = item:toData()
          if kind == 'CardItem' then
            -- Project the native Card object for both real and virtual cards.
            -- This is the same path used by incremental _new/CardItem deltas.
            project_card_item(value)
          end
          if kind == 'CardItem' then annotate_card_reason(value) end
          table.insert(snapshot._new, {type = kind, data = value})
        end
      end
      local encoded, payload = pcall(to_json, snapshot)
      if not encoded then error(report(payload), 0) end
      J.ui('UpdateRequestUI', payload)
    end
  end
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
  -- Native lobby/room parsers require CBOR text for names, passwords and
  -- settings keys/values. Keep the upstream byte-string default for gameplay
  -- replies; scope this override to this synchronous notification only.
  local encoders = cbor.type_encoders
  local previous = encoders.string
  encoders.string = encoders.utf8string
  local ok, payload = pcall(cbor.encode, data)
  encoders.string = previous
  if not ok then error(payload) end
  __host_client:notifyServer(command, payload)
  return true
end

-- QML sends its reply payload through the native client as CBOR bytes.
-- In particular, the skill-invoke handler returns the strings "1" or
-- "__cancel"; passing raw UTF-8 would be interpreted as invalid CBOR by
-- Request:_checkReply on the server.
function __web_reply(data)
  if type(data) ~= 'string' and type(data) ~= 'table' and
     not (type(data) == 'number' and math.type(data) == 'integer' and data >= 0) then
    error('invalid reply value')
  end
  __host_client:replyToServer('', cbor.encode(data))
  return true
end

-- The transport compares the wire representation independently before it
-- authorizes any reply. Both functions use the same Lua CBOR implementation.
function __web_reply_hex(data)
  if type(data) ~= 'string' and type(data) ~= 'table' and
     not (type(data) == 'number' and math.type(data) == 'integer' and data >= 0) then
    error('invalid reply value')
  end
  return bin2hex(cbor.encode(data))
end

-- Query public card faces only for IDs which the bridge has already checked
-- against the request's visible_data. Hidden cards never cross to React.
function __web_visible_card(id)
  if type(id) ~= 'number' or math.type(id) ~= 'integer' or id < 0 then return nil end
  local card = Fk:getCardById(id)
  if not card then return nil end
  return { name = card.name, suit = card.suit, number = card.number }
end

-- Dispatch against the installed upstream Poxi rules (including expansion
-- methods); do not reimplement card_filter / feasible in JavaScript.
function __web_poxi_view(kind, data, extra, selected, candidates)
  local rule = type(kind) == 'string' and Fk.poxi_methods[kind]
  if not rule or type(data) ~= 'table' or type(extra) ~= 'table' or
     type(selected) ~= 'table' or type(candidates) ~= 'table' then
    error('invalid Poxi rule or arguments')
  end
  local allowed = {}
  for i, id in ipairs(candidates) do
    allowed[i] = rule.card_filter(id, selected, data, extra) and true or false
  end
  local prompt = rule.prompt
  if type(prompt) == 'function' then prompt = prompt(data, extra, selected) end
  return { allowed = allowed, feasible = rule.feasible(selected, data, extra) and true or false,
    prompt = type(prompt) == 'string' and prompt or '' }
end

-- Match ChooseCardsAndChoiceModel: count limits apply first; the first
-- regular choice always works, and only later choices use choiceFilter.
-- Same rule inputs as the pinned ArrangeCardsModel / ArrangeCardsBox.
function __web_choose_general_view(rule_name, selected, names, extra, count)
  local rule = Fk.choose_general_rule[rule_name]
  if not rule then error('unknown general selection rule') end
  local allowed = {}
  for i, name in ipairs(names) do
    allowed[i] = #selected < count and rule.card_filter(name, selected, names, extra) and true or false
  end
  return {allowed=allowed,feasible=#selected == count and rule.feasible(selected, names, extra) and true or false}
end

function __web_arrange_feasible(rows, original, limits, capacities, poxi)
  for i, row in ipairs(rows) do
    if #row < (limits[i] or 0) or #row > capacities[i] then return false end
  end
  if poxi ~= '' then
    local rule = Fk.poxi_methods[poxi]
    return rule and rule.feasible({}, rows, original) and true or false
  end
  return true
end
function __web_arrange_allowed(id, rows, original, pattern, poxi)
  if poxi ~= '' then
    local rule = Fk.poxi_methods[poxi]
    return rule and rule.card_filter(id, {id}, rows, original) and true or false
  end
  return pattern == '.' or Fk:getCardById(id):matchPattern(pattern)
end

function __web_cards_and_choice_view(filter, selected, choices, min, max, extra)
  local allowed = {}
  local enough = #selected >= min and #selected <= max
  for i, choice in ipairs(choices) do
    if not enough then
      allowed[i] = false
    elseif i == 1 or filter == '' then
      allowed[i] = true
    else
      local skel = Fk.skill_skels[filter]
      local fn = skel and skel.extra and skel.extra.choiceFilter
      allowed[i] = type(fn) == 'function' and fn(selected, choice, extra) and true or false
    end
  end
  return allowed
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

function __web_init_display_translations(extra)
  local vi = Fk.translations.vi_VN or {}
  local zh = Fk.translations.zh_CN or {}
  local en = Fk.translations.en_US or {}
  local by_chinese = {}
  for key, value in pairs(vi) do
    if zh[key] and key:sub(1, 1) ~= ':' then by_chinese[zh[key]] = value end
  end
  local labels = {}
  for key, value in pairs(zh) do
    labels[key] = vi[key] or by_chinese[value] or en[key] or value
    -- Variant names can share the base name, but their rule descriptions
    -- and prompts must remain specific to that variant.
    local base = key:match('__([^:]+)$')
    if base and not key:match('^[:#$~]') then
      labels[key] = vi[key] or extra[key] or extra[base] or vi[base] or labels[key]
    end
  end
  for key, value in pairs(vi) do labels[key] = value end
  for key, value in pairs(extra) do labels[key] = value end

  -- Keep the complete table in Lua so Translate()/game rules still see every
  -- upstream key, but do not serialize every installed expansion to React.
  -- The dependency-complete runtime has substantially more translations than
  -- the original three-package snapshot and would otherwise hit the bounded
  -- UI JSON node budget during boot.  The browser only needs names/descriptions
  -- belonging to visible generals and their declared skills, plus the small
  -- application-owned additions passed in by the host.
  Fk:loadTranslationTable(labels, 'vi_VN')
  local visible = {}
  local included = {}
  local visible_count = 0
  local visible_bytes = 0
  local function flush()
    if next(visible) ~= nil then J.ui('DisplayTranslations', to_json(visible)) end
    visible = {}
    visible_count = 0
    visible_bytes = 0
  end
  local function keep(key)
    if type(key) ~= 'string' or included[key] then return end
    local value = labels[key]
    if type(value) ~= 'string' then
      local ok, translated = pcall(Fk.translate, Fk, key)
      if ok and type(translated) == 'string' then value = translated end
    end
    if type(value) ~= 'string' or #value > 30000 then return end
    -- Flush before the generic serializer budget is reached. The reducer
    -- merges DisplayTranslations chunks, so a large dependency-complete
    -- runtime never drops a valid label merely because it came later in a
    -- Lua table iteration.
    if visible_count >= 1800 or visible_bytes + 2 * (#key + #value) > 180000 then flush() end
    included[key] = true
    visible[key] = value
    visible_count = visible_count + 1
    visible_bytes = visible_bytes + #key + #value
  end
  -- Keep common card names and all visible general identities before the
  -- overlay. The overlay owns the baseline skill descriptions, while these
  -- keys cover card-name dialogs and prefixed general identities such as
  -- ld__bianfuren. Lua table iteration order is unspecified, so neither set
  -- may depend on where an expansion happens to appear in Fk.generals.
  for _, key in ipairs({'slash', 'jink', 'peach', 'analeptic', 'nullification',
      'fire_slash', 'fire__slash', 'thunder_slash', 'thunder__slash', 'duel', 'snatch', 'dismantlement',
      'indulgence', 'supply_shortage', 'collateral', 'amazing_grace',
      'ex_nihilo', 'god_salvation', 'savage_assault', 'archery_attack',
      'iron_chain', 'lightning'}) do
    keep(key); keep(':' .. key); keep('#' .. key)
  end
  for name, general in pairs(Fk.generals or {}) do
    if not general.hidden then keep(name) end
  end
  for key in pairs(extra) do keep(key) end
  for name, general in pairs(Fk.generals or {}) do
    if not general.hidden then
      keep(name); keep('#' .. name); keep('~' .. name); keep('illustrator:' .. name)
      local ok, skills = pcall(general.getSkillNameList, general)
      if ok and type(skills) == 'table' then
        for _, skill in ipairs(skills) do
          if type(skill) == 'string' then
            keep(skill); keep(':' .. skill); keep('#' .. skill)
            keep('$' .. skill .. '1'); keep('$' .. skill .. '2')
          end
        end
      end
    end
  end
  flush()
  return true
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

-- Enumerate installed native packages and apply the mode's own whitelist.
-- The ids are small package names used by Room.disabled_packs, not extension
-- directory names such as "hegemony".
function __web_room_packs(mode)
  if not Fk.game_modes[mode] then error('unknown game mode') end
  local locked = {}
  for _, name in ipairs(Fk.game_mode_disabled[mode] or {}) do locked[name] = true end
  local packs = { generals = {}, cards = {} }
  for _, name in ipairs(Fk.package_names) do
    local pkg = Fk.packages[name]
    local kind = pkg.type == Package.GeneralPack and 'generals' or
      (pkg.type == Package.CardPack and 'cards' or nil)
    if kind and not locked[name] then
      local count = 0
      if kind == 'generals' then
        for _, general in ipairs(pkg.generals) do
          if not general.hidden and not general.total_hidden then count = count + 1 end
        end
      else
        for _, card in ipairs(pkg.cards) do
          if not card.is_derived then count = count + 1 end
        end
      end
      if count > 0 then
        table.insert(packs[kind], {id = name, label = Fk:translate(name), count = count})
      end
    end
  end
  return packs
end

-- Enumerate the visible general identities which the native room can use.
-- This is consumed only by the browser's explicit QA-room setup; normal lobby
-- rendering continues to show package labels, not internal general IDs.
function __web_room_generals(mode, disabled)
  if type(disabled) ~= 'table' then error('invalid disabled packs') end
  local available = __web_room_packs(mode)
  local known, chosen = {}, {}
  for _, pkg in ipairs(available.generals) do known[pkg.id] = true end
  for _, name in ipairs(disabled) do
    if type(name) ~= 'string' or not known[name] or chosen[name] then
      error('invalid or duplicate disabled package')
    end
    chosen[name] = true
  end
  local result = {}
  for _, packageName in ipairs(Fk.package_names) do
    local pkg = Fk.packages[packageName]
    if pkg and pkg.generals and known[packageName] and not chosen[packageName] then
      for _, general in ipairs(pkg.generals) do
        if not general.hidden and not general.total_hidden and type(general.name) == 'string' then
          result[#result + 1] = {id = general.name, trueName = general.trueName,
            kingdom = general.kingdom, subkingdom = general.subkingdom,
            package = packageName, label = Fk:translate(general.name)}
        end
      end
    end
  end
  return result
end

-- Count generals like Room:makeGeneralPile and cards through the actual mode's
-- buildDrawPile. Hegemony removes some converted cards after getAllCardIds;
-- simply summing package sizes overstates the playable deck.
function __web_room_pool_summary(mode, disabled, disabled_generals)
  if type(disabled) ~= 'table' then error('invalid disabled packs') end
  if disabled_generals == nil then disabled_generals = {} end
  if type(disabled_generals) ~= 'table' then error('invalid disabled generals') end
  local available = __web_room_packs(mode)
  local known, chosen = {}, {}
  for _, kind in ipairs({'generals', 'cards'}) do
    for _, pkg in ipairs(available[kind]) do known[pkg.id] = true end
  end
  for _, name in ipairs(disabled) do
    if type(name) ~= 'string' or not known[name] or chosen[name] then
      error('invalid or duplicate disabled package')
    end
    chosen[name] = true
  end
  local allGenerals = __web_room_generals(mode, {})
  local generalKnown, generalChosen = {}, {}
  for _, general in ipairs(allGenerals) do generalKnown[general.id] = true end
  for _, name in ipairs(disabled_generals) do
    if type(name) ~= 'string' or not generalKnown[name] or generalChosen[name] then
      error('invalid or duplicate disabled general')
    end
    generalChosen[name] = true
  end
  local distinct, generalCount = {}, 0
  for _, pkg in ipairs(available.generals) do
    if not chosen[pkg.id] then
      for _, general in ipairs(Fk.packages[pkg.id].generals) do
        if not general.hidden and not general.total_hidden and not generalChosen[general.name] and
            not distinct[general.trueName] then
          distinct[general.trueName] = true
          generalCount = generalCount + 1
        end
      end
    end
  end
  -- Scoped stand-in for server Room:initialize, which adds mode-locked packs.
  -- Restore RoomInstance even if the upstream mode rejects the configuration.
  -- This synchronous calculation does not mutate the active ClientInstance.
  local disabledPacks = {}
  table.insertTableIfNeed(disabledPacks, Fk.game_mode_disabled[mode] or {})
  table.insertTableIfNeed(disabledPacks, disabled)
  local oldRoom = RoomInstance
  RoomInstance = {disabled_packs = disabledPacks, filtered_cards = {}, printed_cards = {}}
  local ok, cardsOrError = pcall(function()
    local draw = Fk.game_modes[mode]:buildDrawPile()
    return #draw
  end)
  RoomInstance = oldRoom
  if not ok then error(cardsOrError) end
  return {generals = generalCount, cards = cardsOrError}
end
`;
