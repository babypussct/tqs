-- Run the promoted room methods with a deterministic clock and native timer stub.
local root = assert(arg[1], "expected promoted native release root")
local file = assert(io.open(root .. "/packages/freekill-core/lua/server/roombase.lua"))
local source = file:read("*a")
file:close()

ServerRoomBase = {}
Util = { TrueFunc = function() return true end }
fk = { Player_Online = 1, Player_Trust = 2, Player_Run = 4, Player_Robot = 5, Player_Offline = 6 }
fk.qCritical = function(message) error(message) end
local now = 0
os.getms = function() return now end
for _, method in ipairs({ "resume", "checkNoHuman", "delay", "playerReconnect" }) do
  assert(load(assert(source:match("(function ServerRoomBase:" .. method .. ".-\nend)"))))()
end

local function room(mode)
  local state = fk.Player_Trust
  local events = {}
  local timers = {}
  local owner = {
    serverplayer = { getState = function() return state end },
    reconnect = function() table.insert(events, "snapshot") end,
  }
  local result = setmetatable({
    id = 1, game_started = true, players = { owner }, _resume_fn = Util.TrueFunc,
    room = { delay = function(_, ms) table.insert(timers, ms) end },
  }, { __index = ServerRoomBase })
  for _ = 1, 6 do
    table.insert(result.players, { serverplayer = { getState = function() return fk.Player_Robot end } })
  end
  function result:getSettings() return mode end
  function result:getPlayerById() return owner end
  function result:gameOver(winners)
    assert(winners == "")
    assert(not self.game_finished)
    self.game_finished = true
    table.insert(events, "over")
  end
  function result:yield(check)
    self._resume_fn = check or Util.TrueFunc
    coroutine.yield()
  end
  function result:run()
    while true do
      table.insert(events, "turn")
      self:yield()
    end
  end
  ResumeRoom = function(id, reason)
    assert(id == result.id)
    return result:resume(reason)
  end
  assert(result:resume() == false)
  return result, function(value) state = value end, events, timers
end

local game, setState, events, timers = room("new_heg_mode")
setState(fk.Player_Offline)
assert(game:resume("player_disconnect") == false)
assert(game:checkNoHuman() == false)
assert(#events == 1 and timers[1] == 30000)
now = 29999
assert(game:resume("request_timer") == false and #timers == 1 and #events == 1)
setState(fk.Player_Online)
game:playerReconnect(1)
assert(events[2] == "snapshot" and events[3] == "turn")
assert(game._tqsReconnectUntil == nil and not game.game_finished)

now = 0
game, setState, events = room("new_heg_mode")
setState(fk.Player_Offline)
assert(game:resume("player_disconnect") == false)
now = 30000
assert(game:resume("delay_done") == true and events[2] == "over")
assert(game:resume("delay_done") == true and #events == 2)

game, setState, events, timers = room("new_heg_mode")
setState(fk.Player_Run)
assert(game:resume("player_disconnect") == true and events[2] == "over" and #timers == 0)

game, setState, events, timers = room("role_mode")
setState(fk.Player_Offline)
assert(game:resume("player_disconnect") == true and events[2] == "over" and #timers == 0)

now = 0
game, setState, events, timers = room("new_heg_mode")
game.main_co = coroutine.create(function()
  game:delay(500)
  table.insert(events, "delay ended")
  game:yield()
end)
assert(game:resume() == false)
setState(fk.Player_Offline)
assert(game:resume("player_disconnect") == false)
now = 200
setState(fk.Player_Online)
game:playerReconnect(1)
assert(events[2] == "snapshot" and #events == 2)
assert(game:resume("delay_done") == false and timers[#timers] == 300 and #events == 2)
now = 500
assert(game:resume("delay_done") == false and events[3] == "delay ended")

print("PASS Hegemony reconnect grace: pause, snapshot-before-resume, exact expiry, explicit leave, other mode, and timer ordering")
