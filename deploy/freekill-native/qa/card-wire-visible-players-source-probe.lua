-- Execute the real candidate notifyMoveCards body with synthetic recipients.
-- Verifies viewer conversion before the physical card-wire projector receives it.
local root = assert(..., "isolated candidate core required")
local sourceFile = assert(io.open(root .. "/ltk/server/events/movecard.lua", "rb"))
local source = assert(sourceFile:read("*a"))
sourceFile:close()
local signature = "function MoveEventWrappers:notifyMoveCards(players, moveDatas, event_id)"
local begin = assert(source:find(signature, 1, true), "missing notifier")
local ending = assert(source:find("\nend\n", begin, true), "unterminated notifier")

local function clone(input)
  if type(input) ~= "table" then return input end
  local result = {}
  for key, value in pairs(input) do result[key] = value end
  return result
end
local converted = {}
local util = { IdMapper = function(player) return player.id end }
local tableApi = setmetatable({
  simpleClone = clone,
  map = function(array, transform)
    local result = {}
    for i, value in ipairs(array) do result[i] = transform(value) end
    return result
  end,
}, { __index = table })
local env = setmetatable({
  MoveEventWrappers = {}, Util = util, table = tableApi,
}, { __index = _G })
assert(load(source:sub(begin, ending + 4), "=candidate/movecard.lua", "t", env))()
local notifier = env.MoveEventWrappers.notifyMoveCards

local packets = {}
local physical = { id = 91 }
function physical:doNotify(command, data)
  assert(command == "MoveCards" and type(data) == "table")
  packets[#packets + 1] = data
end
local room = setmetatable({ players = { physical } }, { __index = env.MoveEventWrappers })
local function deliver(viewers)
  packets = {}
  local move = { toArea = 1, moveInfo = { { cardId = 201, fromArea = 2 } },
    from = { id = 11 }, to = { id = 12 }, proposer = { id = 11 },
    visiblePlayers = viewers }
  room:notifyMoveCards(nil, { move }, 17)
  assert(#packets == 1 and packets[1][2] == 17)
  local delivered = packets[1][1][1]
  assert(delivered.from == 11 and delivered.to == 12 and delivered.proposer == 11)
  assert(move.visiblePlayers == viewers, "notifier must preserve source state")
  return delivered.visiblePlayers
end

local ids = { 11, 12 }
local numeric = deliver(ids)
assert(type(numeric) == "table" and #numeric == 2 and
  numeric[1] == 11 and numeric[2] == 12 and numeric ~= ids,
  "numeric viewer arrays must survive unchanged but independently copied")
local objects = { { id = 11 }, { id = 12 } }
local normalized = deliver(objects)
assert(type(normalized) == "table" and normalized[1] == 11 and normalized[2] == 12,
  "player-object viewer arrays must still serialize to ID arrays")
assert(deliver({ id = 11 }) == 11, "single player-object viewer must still serialize")
assert(deliver(nil) == nil, "unset viewers must remain unset")
print("PASS candidate MoveCards viewer ID conversion: numeric arrays, player arrays, single player, absent; native/browser NOT RUN")
