-- Diagnose secret card identifiers on the actual isolated candidate Lua wire.
-- Uses synthetic card IDs only. An OPEN result is a failing release gate, even
-- though the source diagnostic itself can pass by reproducing the exposure.
local root, strict = ...
assert(root, "candidate core root required")

local function read(relative)
  local f = assert(io.open(root .. "/" .. relative, "rb"))
  local s = assert(f:read("*a"))
  f:close()
  return s
end

local function clone(t)
  if type(t) ~= "table" then return t end
  local result = {}
  for k, v in pairs(t) do result[k] = clone(v) end
  return result
end

local nativeTable = setmetatable({
  insertTable = function(dst, src)
    for _, v in ipairs(src) do table.insert(dst, v) end
  end,
  simpleClone = function(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
  end,
}, { __index = table })

local roomMethods, serverMethods, logicMethods, moveMethods, playerMethods = {}, {}, {}, {}, {}
local env = setmetatable({
  Room = roomMethods, ServerRoomBase = serverMethods,
  GameLogic = logicMethods, MoveEventWrappers = moveMethods,
  ServerPlayerBase = playerMethods,
  AbstractRoom = {
    shuffleDrawPile = function(room, ids)
      room.draw_pile = ids
      room.discard_pile = {}
    end,
    changeCardArea = function(_, _, _, areaCards) return areaCards end,
  },
  Card = { DrawPile = 1, DiscardPile = 2, Void = 3,
    getIdList = function(_, ids) return ids end },
  table = nativeTable,
  cbor = { encode = clone, decode = clone },
  Fk = { generals = { anjiang = { gender = 0, kingdom = "unknown" } } },
  fk = { AfterDrawPileShuffle = "afterShuffle", Player_Robot = "robot" },
}, { __index = _G })

local function define(relative, signature)
  local source = read(relative)
  local start = assert(source:find(signature, 1, true), "missing Lua definition: " .. signature)
  local finish = assert(source:find("\nend\n", start, true), "missing Lua end: " .. signature)
  assert(load(source:sub(start, finish + 4), "=candidate/" .. relative, "t", env))()
end

define("ltk/server/gamelogic.lua", "function GameLogic:prepareDrawPile()")
define("ltk/server/room.lua", "function Room:shuffleDrawPile()")
define("ltk/server/room.lua", "function Room:syncDrawPile()")
define("ltk/server/room.lua", "function Room:changeCardArea (cards, area, areaCards)")
define("ltk/server/room.lua", "function Room:setPlayerPile(player, pile, ids)")
define("ltk/server/events/movecard.lua", "function MoveEventWrappers:notifyMoveCards(players, moveDatas, event_id)")
if read("lua/server/roombase.lua"):find("function ServerRoomBase:publicHegemonyRole(role, shown)", 1, true) then
  define("lua/server/roombase.lua", "function ServerRoomBase:publicHegemonyRole(role, shown)")
end
define("lua/server/roombase.lua", "function ServerRoomBase:serialize(player, observer)")
define("lua/server/serverplayer_base.lua", "function ServerPlayerBase:doNotify(command, data)")

local sourceCardManager = read("ltk/core/room/card_manager.lua")
local sourcePlayer = read("ltk/core/player.lua")
assert(sourceCardManager:find("draw_pile = self.draw_pile", 1, true),
  "snapshot deck source changed: review fixture serialization")
assert(sourcePlayer:find("o.player_cards = self.player_cards", 1, true),
  "snapshot hand source changed: review fixture serialization")

local exposures = {}
local function check(label, condition)
  if condition then exposures[#exposures + 1] = label end
end
local function equalIds(a, b)
  if type(a) ~= "table" or #a ~= #b then return false end
  for k, v in ipairs(a) do if v ~= b[k] then return false end end
  return true
end

-- The IDs below are deliberately fictitious; none are taken from a match.
local deck = { 811, 827, 803 }
local broadcasts = {}
local room = setmetatable({
  draw_pile = clone(deck), discard_pile = {}, void = {},
  logic = { trigger = function() end },
}, { __index = roomMethods })
function room:prepareDrawPile() self.draw_pile = clone(deck) end
function room:shuffleTable() end -- Preserve a known fixture sequence.
function room:doBroadcastNotify(cmd, payload)
  broadcasts[#broadcasts + 1] = { command = cmd, payload = clone(payload) }
end

local gameLogic = setmetatable({ room = room }, { __index = logicMethods })
gameLogic:prepareDrawPile()
check("prepare_order", broadcasts[#broadcasts].command == "PrepareDrawPile"
  and equalIds(broadcasts[#broadcasts].payload, deck))
room:shuffleDrawPile()
check("shuffle_order", broadcasts[#broadcasts].command == "ShuffleDrawPile"
  and equalIds(broadcasts[#broadcasts].payload, deck))
room:syncDrawPile()
check("sync_order", broadcasts[#broadcasts].command == "SyncDrawPile"
  and equalIds(broadcasts[#broadcasts].payload, deck))
room:changeCardArea({ 821 }, env.Card.DrawPile, clone(deck))
check("change_area_order", broadcasts[#broadcasts].command == "ChangeCardArea"
  and equalIds(broadcasts[#broadcasts].payload[3], deck))

-- Explicitly hidden movement still carries the physical card ID to peers.
local function peer()
  local result = { received = {} }
  function result:getState() return "connected" end
  function result:doNotify(cmd, payload)
    self.received[#self.received + 1] = { command = cmd, payload = clone(payload) }
  end
  return result
end
local physical, spectator = peer(), peer()
local opponent = setmetatable({ id = 2, _observers = { physical }, room = room },
  { __index = playerMethods })
room.notify_count, room.notify_max = 0, 100
room.observers = { { 2, spectator } }
room.room = { hasObserver = function() return true end }
local moved = { moveVisible = false, from = { id = 1 }, to = { id = 1 },
  toArea = 2, moveInfo = { { cardId = 829, fromArea = 1 } } }
room.players = { opponent }
moveMethods.notifyMoveCards(room, { opponent }, { moved }, 3)
local last = physical.received[#physical.received]
check("hidden_move_id", last and last.command == "MoveCards"
  and last.payload[1][1].moveInfo[1].cardId == 829)
local watched = spectator.received[#spectator.received]
check("observe_hidden_move_id", watched and watched.command == "MoveCards"
  and watched.payload[1][1].moveInfo[1].cardId == 829)

room:setPlayerPile({ id = 1, special_cards = {} }, "hidden", { 829 })
check("special_pile_id", broadcasts[#broadcasts].command == "SetPlayerPile"
  and broadcasts[#broadcasts].payload[3][1] == 829)

local owner = { id = 1 }
local snapshotSeat = function(seat)
  return { mark = {}, fake_skills = {}, prelighted_skills = {},
    properties = { role = "hidden", role_shown = true, general = "anjiang" },
    player_cards = { [1] = clone({ 829 }) }, special_cards = { hidden = { 829 } },
  }
end
room.players = { owner, opponent }
room.settings = { gameMode = "new_heg_mode" }
room.class = { super = { serialize = function()
  return { players = { [1] = snapshotSeat(owner), [2] = snapshotSeat(opponent) },
    card_manager = { draw_pile = clone(deck), discard_pile = {},
      processing_area = {}, void = {}, printed_cards = {} } }
end } }
function room:getSettings(key) return self.settings[key] end
env.os = setmetatable({ time = function() return 42 end }, { __index = os })

local nonowner = serverMethods.serialize(room, opponent, false)
check("reconnect_deck", equalIds(nonowner.card_manager.draw_pile, deck))
check("reconnect_hand", nonowner.players[1].player_cards[1][1] == 829)
check("reconnect_special", nonowner.players[1].special_cards.hidden[1] == 829)
local observerSnapshot = serverMethods.serialize(room, owner, true)
check("observe_deck", equalIds(observerSnapshot.card_manager.draw_pile, deck))
check("observe_hand", observerSnapshot.players[1].player_cards[1][1] == 829)

local categories = table.concat(exposures, ",")
if #exposures == 0 then
  print("CARD_WIRE_PRIVACY=PASS; candidate Lua source diagnostic; native/browser NOT RUN")
else
  print("CARD_WIRE_PRIVACY=OPEN; exposure_categories=" .. categories ..
    "; synthetic-only; native/browser NOT RUN")
end
if strict == "--strict" and #exposures > 0 then os.exit(2) end
