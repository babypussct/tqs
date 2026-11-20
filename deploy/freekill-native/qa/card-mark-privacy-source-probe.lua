-- Execute actual candidate Lua methods with synthetic card identities. Tests
-- protect card-mark delivery/snapshot routing, not full card-ID wire privacy.
local root = assert(..., "candidate core root required")
local function read(relative)
  local file = assert(io.open(root .. "/" .. relative, "rb"))
  local contents = assert(file:read("*a"))
  file:close()
  return contents
end
local function copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for key, child in pairs(value) do out[key] = copy(child) end
  return out
end
local methods, snapshots = {}, {}
local fakeCard = { DrawPile = 1, PlayerHand = 2, DiscardPile = 3, PlayerSpecial = 4 }
local env = setmetatable({
  Room = methods, ServerRoomBase = snapshots, Card = fakeCard,
  cbor = { encode = copy, decode = copy },
  fk = { Player_Robot = "robot" },
  Fk = { generals = { anjiang = { gender = 0, kingdom = "unknown" } } },
}, { __index = _G })
local function define(relative, signature)
  local source = read(relative)
  local first = assert(source:find(signature, 1, true), "missing " .. signature)
  local last = assert(source:find("\nend\n", first, true), "missing end for " .. signature)
  assert(load(source:sub(first, last + 4), "=candidate/" .. relative, "t", env))()
end
define("ltk/server/room.lua", "function Room:setCardMark(card, mark, value)")
define("lua/server/roombase.lua", "function ServerRoomBase:notifyPrivatePhysical(seat, physical, command, data)")
if read("lua/server/roombase.lua"):find("function ServerRoomBase:publicHegemonyRole(role, shown)", 1, true) then
  define("lua/server/roombase.lua", "function ServerRoomBase:publicHegemonyRole(role, shown)")
end
define("lua/server/roombase.lua", "function ServerRoomBase:serialize(player, observer)")
-- Room includes ServerRoomBase in the candidate runtime; the legacy fixture
-- must preserve that inheritance when exercising the real SetCardMark body.
setmetatable(methods, { __index = snapshots })

local events = { owner = {}, opponent = {}, watcher = {}, broadcast = {} }
local function physical(label)
  return { getState = function() return "connected" end,
    doNotify = function(_, command, payload)
      events[label][#events[label] + 1] = { command, copy(payload) }
    end }
end
local function pileNameOfId(self, id)
  for name, ids in pairs(self.special_cards) do
    for _, storedId in ipairs(ids) do
      if id == storedId then return name end
    end
  end
end
local owner = { id = 11, _splayer = physical("owner"),
  special_cards = { ["$hidden"] = { 851 }, public = { 853 } },
  getPileNameOfId = pileNameOfId }
local opponent = { id = 12, _splayer = physical("opponent"),
  special_cards = { ["$hidden"] = { 852 } },
  getPileNameOfId = pileNameOfId }
local areas = { [811] = fakeCard.DrawPile, [829] = fakeCard.PlayerHand,
  [830] = fakeCard.PlayerHand, [841] = fakeCard.DiscardPile,
  [851] = fakeCard.PlayerSpecial, [852] = fakeCard.PlayerSpecial,
  [853] = fakeCard.PlayerSpecial }
local owners = { [829] = 11, [830] = 12,
  [851] = 11, [852] = 12, [853] = 11 }
local serverMarks = { [811] = { secret = 1 }, [829] = { private = 2 },
  [830] = { private = 3 }, [841] = { public = 4 },
  [851] = { concealed = 5 }, [852] = { concealed = 6 },
  [853] = { public = 7 } }
local function playerSnapshot()
  return { mark = {}, fake_skills = {}, prelighted_skills = {},
    properties = { role = "hidden", role_shown = true, general = "anjiang" } }
end
local room = setmetatable({
  players = { owner, opponent }, settings = { gameMode = "new_heg_mode" },
  class = { super = { serialize = function()
    return { players = { [11] = playerSnapshot(), [12] = playerSnapshot() },
      card_manager = { draw_pile = { 811 }, card_marks = copy(serverMarks) } }
  end } },
}, { __index = methods })
function room:getSettings(key) return self.settings[key] end
function room:getCardArea(id) return areas[id] end
function room:getCardOwner(id) return self:getPlayerById(owners[id]) end
function room:getPlayerById(id) return id == 11 and owner or id == 12 and opponent end
function room:doBroadcastNotify(command, payload)
  events.broadcast[#events.broadcast + 1] = { command, copy(payload) }
  -- Broadcast in the real room travels via each player and their observers.
  for _, label in ipairs({ "owner", "opponent", "watcher" }) do
    events[label][#events[label] + 1] = { command, copy(payload) }
  end
end
local function card(id, virtual)
  return { id = id, mark = {}, isVirtual = function() return virtual end,
    setMark = function(self, name, value) self.mark[name] = value end }
end

local owned = card(829)
room:setCardMark(owned, "private", 7)
assert(owned.mark.private == 7 and #events.owner == 1,
  "physical owner must receive card mark and retain state")
assert(events.owner[1][1] == "SetCardMark" and events.owner[1][2][1] == 829,
  "owner must receive physical card id")
assert(#events.opponent == 0 and #events.watcher == 0 and #events.broadcast == 0,
  "hand card mark leaked to opponent/attached observer")
room:setCardMark(card(851), "concealed", 12)
assert(#events.owner == 2 and events.owner[2][2][1] == 851
  and #events.opponent == 0 and #events.watcher == 0,
  "private special-pile mark must reach only physical owner")
room:setCardMark(card(852), "concealed", 13)
assert(#events.opponent == 1 and events.opponent[1][2][1] == 852
  and #events.owner == 2 and #events.watcher == 0,
  "opponent private special-pile mark must not reach other clients")
room:setCardMark(card(811), "secret", 5)
assert(#events.owner == 2 and #events.opponent == 1, "deck mark leaked")
room:setCardMark(card(841), "public", 9)
assert(#events.broadcast == 1 and #events.opponent == 2
  and events.broadcast[1][2][1] == 841, "public mark not broadcast")
room:setCardMark(card(853), "public", 10)
assert(#events.broadcast == 2 and #events.watcher == 2
  and events.broadcast[2][2][1] == 853,
  "public special-pile marks must remain visible to all recipients")
room:setCardMark(card(-1, true), "virtual", 1)
assert(#events.broadcast == 2, "virtual card sent on wire")
local ownerMark, outsiderMark = #events.owner, #events.opponent
owner._splayer = { getState = function() return "robot" end,
  doNotify = function() error("robot should not be notified") end }
room:setCardMark(card(829), "private", 8)
room:setCardMark(card(851), "concealed", 14)
assert(#events.owner == ownerMark and #events.opponent == outsiderMark,
  "robot hand or hidden special-pile mark leaked")
owner._splayer = physical("owner")
assert(#events.watcher == 2, "watcher received a private mark")

local own = snapshots.serialize(room, owner, false)
assert(own.card_manager.card_marks[829] and own.card_manager.card_marks[841]
  and own.card_manager.card_marks[851] and own.card_manager.card_marks[853]
  and not own.card_manager.card_marks[830] and not own.card_manager.card_marks[811]
  and not own.card_manager.card_marks[852],
  "owner snapshot leaked deck or opponent concealed card marks")
local opposing = snapshots.serialize(room, opponent, false)
assert(opposing.card_manager.card_marks[830] and opposing.card_manager.card_marks[841]
  and opposing.card_manager.card_marks[852] and opposing.card_manager.card_marks[853]
  and not opposing.card_manager.card_marks[829] and not opposing.card_manager.card_marks[811]
  and not opposing.card_manager.card_marks[851],
  "opponent snapshot leaked deck or other concealed card marks")
local watched = snapshots.serialize(room, owner, true)
assert(watched.card_manager.card_marks[841] and watched.card_manager.card_marks[853]
  and not watched.card_manager.card_marks[811] and not watched.card_manager.card_marks[829]
  and not watched.card_manager.card_marks[830] and not watched.card_manager.card_marks[851]
  and not watched.card_manager.card_marks[852],
  "observer snapshot leaked concealed marks")
assert(serverMarks[811] and serverMarks[829] and serverMarks[830]
  and serverMarks[841] and serverMarks[851] and serverMarks[852]
  and serverMarks[853], "snapshot projection mutated server card mark state")

room.settings.gameMode = "other_mode"
local otherCount = #events.broadcast
room:setCardMark(card(829), "private", 6)
room:setCardMark(card(851), "concealed", 15)
assert(#events.broadcast == otherCount + 2 and #events.watcher == 4,
  "legacy mode should broadcast card marks")
local other = snapshots.serialize(room, opponent, false)
assert(other.card_manager.card_marks[829] and other.card_manager.card_marks[811]
  and other.card_manager.card_marks[851],
  "legacy mode snapshot must retain original card marks")
print("PASS candidate real card-mark source: incremental 9; snapshots 4; other-mode 3; native/browser NOT RUN")
