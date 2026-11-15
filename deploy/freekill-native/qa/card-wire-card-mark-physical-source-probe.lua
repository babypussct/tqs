-- Execute the actual candidate Lua SetCardMark and private-physical helper.
-- Synthetic sockets/CBOR/projector; full native/browser privacy is still open.
local root = assert(..., "isolated candidate core required")
local function read(relative)
  local f = assert(io.open(root .. "/" .. relative, "rb"))
  local body = assert(f:read("*a"))
  f:close()
  return body
end
local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for k, v in pairs(value) do result[k] = copy(v) end
  return result
end
local methods = {}
local failEncode = false
local env = setmetatable({
  Room = methods, ServerRoomBase = methods,
  Card = { DrawPile = 1, PlayerHand = 2, PlayerSpecial = 3, DiscardPile = 4 },
  fk = { Player_Robot = "robot" },
  cbor = { encode = function(data)
    if failEncode then error("synthetic CBOR failure") end
    return copy(data)
  end },
}, { __index = _G })
local function loadMethod(relative, signature)
  local source = read(relative)
  local begin = assert(source:find(signature, 1, true), "missing candidate " .. signature)
  local ending = assert(source:find("\nend\n", begin, true), "unterminated " .. signature)
  assert(load(source:sub(begin, ending + 4), "=candidate/" .. relative, "t", env))()
end
loadMethod("lua/server/roombase.lua", "function ServerRoomBase:notifyPrivatePhysical(seat, physical, command, data)")
loadMethod("ltk/server/room.lua", "function Room:setCardMark(card, mark, value)")

local packets = { owner = {}, opponent = {}, observer = {}, public = {} }
local function socket(name)
  local s = { name = name, state = "online" }
  function s:getState() return self.state end
  function s:doNotify(command, data)
    packets[self.name][#packets[self.name] + 1] = { command, copy(data) }
  end
  return s
end
local ownerPhysical = socket("owner")
local otherPhysical = socket("opponent")
local observerPhysical = socket("observer")
local owner = { id = 11, _splayer = ownerPhysical }
local other = { id = 12, _splayer = otherPhysical }
function owner:getPileNameOfId(id)
  if id == 851 then return "$secret" end
  if id == 853 then return "public" end
end
function other:getPileNameOfId(id)
  if id == 852 then return "$secret" end
end
local areas = { [811] = env.Card.DrawPile, [829] = env.Card.PlayerHand,
  [830] = env.Card.PlayerHand, [851] = env.Card.PlayerSpecial,
  [852] = env.Card.PlayerSpecial, [853] = env.Card.PlayerSpecial,
  [841] = env.Card.DiscardPile }
local owners = { [829] = 11, [830] = 12, [851] = 11,
  [852] = 12, [853] = 11 }
local room = setmetatable({ card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  commits = 0, aborts = 0, projections = 0 }, { __index = methods })
function room:getSettings(key) return self.settings[key] end
function room:getCardArea(id) return areas[id] end
function room:getCardOwner(id) return self:getPlayerById(owners[id]) end
function room:getPlayerById(id)
  return id == 11 and owner or id == 12 and other
end
function room:doBroadcastNotify(command, data)
  packets.public[#packets.public + 1] = { command, copy(data) }
end
function room:beginCardWireBatch()
  local batch = { committed = false, aborted = false }
  function batch:commit()
    assert(not self.aborted)
    self.committed = true
    room.commits = room.commits + 1
  end
  function batch:abort()
    assert(not self.committed)
    self.aborted = true
    room.aborts = room.aborts + 1
  end
  return batch
end
local failProject, nilProject = false, false
function room:projectCardWire(seat, physical, command, data, batch)
  assert(command == "SetCardMark" and seat._splayer == physical and
    type(batch.commit) == "function", "incorrect physical card-mark context")
  room.projections = room.projections + 1
  if failProject then error("synthetic projector failure") end
  if nilProject then return nil end
  local output = copy(data)
  -- Synthetic local numeric identity, independent for the two sockets.
  output[1] = physical == ownerPhysical and -2201 or -3301
  return output
end
local function card(id)
  local result = { id = id, marks = {} }
  function result:setMark(name, value) self.marks[name] = value end
  function result:isVirtual() return false end
  return result
end
local function mark(id, value)
  local current = card(id)
  room:setCardMark(current, "m", value)
  assert(current.marks.m == value, "canonical server mark must be updated")
end
mark(829, 1)
mark(851, 2)
mark(830, 3)
mark(852, 4)
assert(#packets.owner == 2 and #packets.opponent == 2 and
  #packets.observer == 0 and #packets.public == 0,
  "hidden marks must go only to their physical owner")
for _, p in ipairs(packets.owner) do
  assert(p[1] == "SetCardMark" and p[2][1] == -2201)
end
for _, p in ipairs(packets.opponent) do
  assert(p[1] == "SetCardMark" and p[2][1] == -3301)
end
assert(room.commits == 4 and room.aborts == 0 and room.projections == 4,
  "each private mark requires a committed projection")

mark(811, 5)
mark(841, 6)
mark(853, 7)
assert(#packets.public == 2 and packets.public[1][2][1] == 841
  and packets.public[2][2][1] == 853 and #packets.observer == 0,
  "deck marks must stay server-side; public marks retain dispatcher path")

local function denied(id)
  local o, x, commits, aborts = #packets.owner, #packets.opponent,
    room.commits, room.aborts
  local ok = pcall(function() mark(id, 9) end)
  assert(not ok and #packets.owner == o and #packets.opponent == x and
    room.commits == commits, "invalid v1 mark must never reach a socket")
  return room.aborts - aborts
end
failProject = true
assert(denied(829) == 1)
failProject = false
nilProject = true
assert(denied(829) == 1)
nilProject = false
failEncode = true
assert(denied(829) == 1)
failEncode = false
room.projectCardWire = false
assert(denied(829) == 0)
room.projectCardWire = nil
room.beginCardWireBatch = false
assert(denied(829) == 0)
room.beginCardWireBatch = nil
room.card_wire_version = 2
assert(denied(829) == 0)
room.card_wire_version = 1
room.settings.gameMode = "other_mode"
local beforeOther = #packets.owner
local otherOk = pcall(function()
  room:notifyPrivatePhysical(owner, ownerPhysical, "SetCardMark", { 829, "m", 9 })
end)
assert(not otherOk and #packets.owner == beforeOther,
  "private v1 helper must reject unsupported game mode")
room.settings.gameMode = "new_heg_mode"
ownerPhysical.state = "robot"
local before = #packets.owner
mark(829, 10)
assert(#packets.owner == before, "robot must receive no concealed mark")
ownerPhysical.state = "online"

room.card_wire_version = nil
mark(829, 11)
assert(#packets.owner == before + 1 and packets.owner[#packets.owner][2][1] == 829,
  "legacy owner notification must retain canonical numeric ID")
room.settings.gameMode = "other_mode"
mark(829, 12)
assert(#packets.public == 3 and packets.public[3][2][1] == 829,
  "other-mode card mark must retain legacy broadcast")
assert(#packets.observer == 0 and observerPhysical.name == "observer")

print("PASS candidate physical SetCardMark: owner/private-pile projection, " ..
  "other socket and observer isolation, deck/public separation, " ..
  "atomic projector/CBOR rollback, fail-closed opt-in, robot/legacy; " ..
  "synthetic-only; native/browser NOT RUN")
