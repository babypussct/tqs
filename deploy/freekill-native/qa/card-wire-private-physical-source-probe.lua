-- Exercise the actual candidate owner-only Lua notification methods.
-- Physical sockets and CBOR are synthetic; native/browser acceptance is separate.
local root = assert((...), "isolated candidate core required")
local file = assert(io.open(root .. "/lua/server/roombase.lua", "rb"))
local source = assert(file:read("*a"))
file:close()

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for k, v in pairs(value) do result[copy(k)] = copy(v) end
  return result
end

local encodeFail = false
local methods = {}
local env = setmetatable({
  ServerRoomBase = methods,
  fk = { Player_Robot = "robot" },
  cbor = { encode = function(data)
    if encodeFail then error("fixture CBOR failure") end
    return copy(data)
  end },
}, { __index = _G })
local function loadMethod(signature)
  local first = assert(source:find(signature, 1, true), "missing: " .. signature)
  local last = assert(source:find("\nend\n", first, true), "unterminated: " .. signature)
  assert(load(source:sub(first, last + 4), "=candidate/owner-notify", "t", env))()
end
loadMethod("function ServerRoomBase:notifyPrivatePhysical(seat, physical, command, data)")
loadMethod("function ServerRoomBase:publicHegemonyRole(role, shown)")
loadMethod("function ServerRoomBase:notifyProperty(p, player, property)")
loadMethod("function ServerRoomBase:setPlayerMark(player, mark, value)")

local function socket(name, state)
  local s = { name = name, state = state or "online", packets = {} }
  function s:getState() return self.state end
  function s:doNotify(command, data)
    self.packets[#self.packets + 1] = { command = command, data = copy(data) }
  end
  return s
end
local owner = socket("physical/owner")
local observer = socket("physical/observer")
local opponent = socket("physical/opponent")
local seat = {
  id = 1, role = "wei", general = "secret-general", deputyGeneral = "anjiang",
  gender = "male", kingdom = "wei", role_shown = false,
  _splayer = owner, marks = {}, packets = {},
}
function seat:doNotify(command, data)
  self.packets[#self.packets + 1] = { command = command, data = copy(data) }
end
function seat:setMark(mark, value) self.marks[mark] = copy(value) end
local otherSeat = { id = 2, packets = {} }
function otherSeat:doNotify(command, data)
  self.packets[#self.packets + 1] = { command = command, data = copy(data) }
end

local room = setmetatable({
  card_wire_version = 1, settings = { gameMode = "new_heg_mode" },
  public = {}, commits = 0, aborts = 0, projects = 0,
}, { __index = methods })
function room:getSettings(key) return self.settings[key] end
function room:doBroadcastNotify(command, data)
  self.public[#self.public + 1] = { command = command, data = copy(data) }
end
function room:beginCardWireBatch()
  local batch = { committed = false, aborted = false }
  function batch:commit()
    assert(not self.aborted, "cannot commit aborted owner-only transaction")
    self.committed = true
    room.commits = room.commits + 1
  end
  function batch:abort()
    assert(not self.committed, "cannot abort a committed owner-only transaction")
    self.aborted = true
    room.aborts = room.aborts + 1
  end
  return batch
end
local projectFail = false
local projectNil = false
function room:projectCardWire(sourceSeat, physical, command, data, batch)
  assert(sourceSeat == seat and physical == owner and
    (command == "PropertyUpdate" or command == "SetPlayerMark") and
    type(batch.commit) == "function", "incorrect private projection context")
  self.projects = self.projects + 1
  if projectFail then error("fixture projector failed") end
  if projectNil then return nil end
  local result = copy(data)
  if command == "PropertyUpdate" then
    result[3] = "projected-owner-value"
  else
    result[3] = "projected-owner-mark"
  end
  return result
end

local function denied(fn)
  local before = #owner.packets
  local ok = pcall(fn)
  assert(not ok and #owner.packets == before, "unsafe owner-only send was accepted")
end

-- Owner receives a projected packet over its physical socket. Attached
-- observers and other seats must receive no private notification.
room:notifyProperty(seat, seat, "role")
room:notifyProperty(seat, seat, "general")
room:setPlayerMark(seat, "InitialGeneral", { "secret-general", 829 })
assert(#owner.packets == 3 and #observer.packets == 0 and
  #opponent.packets == 0 and #seat.packets == 0 and #room.public == 0)
assert(owner.packets[1].data[3] == "projected-owner-value" and
  owner.packets[2].data[3] == "projected-owner-value" and
  owner.packets[3].data[3] == "projected-owner-mark" and
  seat.marks.InitialGeneral[2] == 829 and room.commits == 3 and room.projects == 3,
  "owner-only property and mark must use the projected physical transaction")

room:notifyProperty(otherSeat, seat, "role")
assert(#otherSeat.packets == 1 and otherSeat.packets[1].data[3] == "hidden" and
  #owner.packets == 3, "non-owner role must remain concealed")
room:setPlayerMark(seat, "public-mark", 5)
assert(#room.public == 1 and room.public[1].data[3] == 5,
  "public mark broadcast must retain existing path")

local function privateCall()
  room:notifyPrivatePhysical(seat, owner, "PropertyUpdate", { seat.id, "role", seat.role })
end
projectFail = true
denied(privateCall)
projectFail = false
projectNil = true
denied(privateCall)
projectNil = false
encodeFail = true
denied(privateCall)
encodeFail = false
assert(room.aborts == 3 and room.commits == 3,
  "failed projector / missing projection / CBOR must abort before delivery")

room.card_wire_version = 2
denied(privateCall)
room.card_wire_version = 1
room.settings.gameMode = "other_mode"
denied(privateCall)
room.settings.gameMode = "new_heg_mode"
denied(function() room:notifyPrivatePhysical(seat, observer, "PropertyUpdate", {}) end)
owner.state = "robot"
denied(privateCall)
owner.state = "online"
local beginBatch = room.beginCardWireBatch
room.beginCardWireBatch = nil
denied(privateCall)
room.beginCardWireBatch = beginBatch
local projector = room.projectCardWire
room.projectCardWire = nil
denied(privateCall)
room.projectCardWire = projector
assert(room.aborts == 3 and room.commits == 3,
  "preflight rejections must not start a transaction")

-- Opt-out still sends byte-compatible original owner CBOR, while other mode
-- notifications continue their existing public route.
room.card_wire_version = nil
privateCall()
assert(#owner.packets == 4 and owner.packets[4].data[3] == "wei" and
  room.commits == 3, "legacy physical packet must preserve raw payload")
room.settings.gameMode = "other_mode"
room:setPlayerMark(seat, "InitialGeneral", 7)
assert(#room.public == 2 and room.public[2].data[3] == 7,
  "other mode must keep public mark update")

print("PASS candidate direct owner-only physical: role/general/mark projected " ..
  "per socket, observer/opponent isolation, projector/CBOR abort, fail-closed " ..
  "opt-in, public and legacy paths; synthetic-only; native/browser NOT RUN")
