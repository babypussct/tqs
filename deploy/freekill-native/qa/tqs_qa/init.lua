-- SPDX-License-Identifier: GPL-3.0-or-later
-- Server-only deterministic scenario director for TQS QA.

local config = ServerConfig and ServerConfig.tqsQa
if not config or config.enabled ~= true then
  return nil
end

local function fail(message)
  error("[tqs_qa] " .. message)
end

local function readJson(path)
  local file, err = io.open(path, "r")
  if not file then
    fail("cannot read " .. path .. ": " .. tostring(err))
  end
  local raw = file:read("*a")
  file:close()
  local ok, value = pcall(json.decode, raw)
  if not ok or type(value) ~= "table" then
    fail("invalid JSON: " .. path)
  end
  return value
end

local manifest = readJson("packages/tqs_qa/package.manifest.json")
if manifest.schemaVersion ~= 1 or manifest.package ~= "tqs_qa" or
    manifest.status ~= "verified" or type(manifest.sourceRevision) ~= "string" or
    manifest.sourceRevision == "" or manifest.sourceRevision == "UNRELEASED" or
    type(manifest.catalogSha256) ~= "string" or manifest.catalogSha256 == "" or
    type(manifest.packageSha256) ~= "string" or manifest.packageSha256 == "" then
  fail("refusing to load an unverified package manifest")
end

local catalog = readJson("packages/tqs_qa/catalog.json")
if catalog.schemaVersion ~= 1 or catalog.package ~= "tqs_qa" or
    type(catalog.scenarios) ~= "table" or #catalog.scenarios == 0 then
  fail("invalid scenario catalog")
end

local scenarioById = {}
for _, scenario in ipairs(catalog.scenarios) do
  if type(scenario.id) ~= "string" or scenario.id == "" or scenarioById[scenario.id] or
      type(scenario.seed) ~= "number" or type(scenario.expectedCommand) ~= "string" or
      type(scenario.trigger) ~= "string" or type(scenario.cards) ~= "table" then
    fail("invalid or duplicate scenario catalog entry")
  end
  scenarioById[scenario.id] = scenario
end

local allowedUsers = config.allowedUsers
if type(allowedUsers) ~= "table" or #allowedUsers == 0 then
  fail("tqsQa.allowedUsers must contain at least one QA account")
end

local roomPrefix = type(config.roomPrefix) == "string" and config.roomPrefix or "TQSQA/"
local maxPlayers = tonumber(config.maxPlayers) or 4
local maxActiveRooms = tonumber(config.maxActiveRooms) or 1
local maxDurationSeconds = tonumber(config.maxDurationSeconds) or 900
local maxRunsPerProcess = tonumber(config.maxRunsPerProcess) or 50

local extension = Package:new("tqs_qa", Package.SpecialPack)
extension.extensionName = "tqs_qa"

local activeRooms = {}
local totalRuns = 0

local function now()
  return os.time()
end

local function activeRoomCount()
  local count = 0
  for _, state in pairs(activeRooms) do
    if now() - state.startedAt <= maxDurationSeconds then
      count = count + 1
    end
  end
  return count
end

local function parseSeed(value)
  if type(value) ~= "string" or not value:match("^0[xX][0-9a-fA-F]+$") then
    return nil
  end
  return tonumber(value:sub(3), 16)
end

local function parseRequest(room)
  local roomName = room:getSettings("roomName") or ""
  if roomName:sub(1, #roomPrefix) ~= roomPrefix then
    return nil
  end

  local id, seedText = roomName:sub(#roomPrefix + 1):match("^([%w%-]+)/(0[xX][0-9a-fA-F]+)$")
  if not id or not seedText then
    fail("QA room name must be " .. roomPrefix .. "<scenario-id>/<0xseed>")
  end
  local scenario = scenarioById[id]
  if not scenario then
    fail("unknown scenario: " .. id)
  end
  local seed = parseSeed(seedText)
  if not seed or seed ~= scenario.seed then
    fail("seed does not match catalog for scenario " .. id)
  end
  return scenario, seed
end

local function isAllowedUser(name)
  return type(name) == "string" and table.contains(allowedUsers, name)
end

local function assertRoomAllowed(room, scenario)
  if #room.players < 2 then
    fail("scenario " .. scenario.id .. " requires at least two players")
  end
  if #room.players > maxPlayers then
    fail("QA room exceeds maxPlayers")
  end
  for _, player in ipairs(room.players) do
    -- Negative ids are native bots. They inherit the room's QA authorization.
    if player.id > 0 then
      local screenName = player:getScreenName()
      if not isAllowedUser(screenName) then
        fail("non-allowlisted player attempted to enter a QA room")
      end
    end
  end
  if totalRuns >= maxRunsPerProcess then
    fail("process QA run quota exhausted")
  end
  if activeRoomCount() >= maxActiveRooms then
    fail("active QA room quota exhausted")
  end
end

local function cardMatches(card, matcher)
  if matcher.trueName and card.trueName ~= matcher.trueName then
    return false
  end
  if matcher.name and card.name ~= matcher.name then
    return false
  end
  if matcher.type == "equip" and card.type ~= Card.TypeEquip then
    return false
  end
  return true
end

local function takeCard(room, matcher, reserved)
  for _, id in ipairs(room.draw_pile) do
    if not reserved[id] and cardMatches(Fk:getCardById(id), matcher) then
      reserved[id] = true
      return id
    end
  end
  fail("catalog card is unavailable in the native draw pile")
end

local function playerForRole(state, owner)
  if owner == "actor" then return state.actor end
  if owner == "target" then return state.target end
  fail("unknown card owner: " .. tostring(owner))
end

local function attachGeneral(room, player, generalName)
  if room:getSettings("gameMode") ~= "new_heg_mode" then
    fail("catalog general injection currently requires new_heg_mode")
  end
  local general = Fk.generals[generalName]
  if not general then
    fail("catalog general is not installed: " .. generalName)
  end
  room:setPlayerMark(player, "__heg_general", generalName)
  -- Keep the deputy marker selected by the real Hegemony setup. Several
  -- downstream rules read it after GamePrepared; replacing it with numeric 0
  -- would make those rules index a non-existent general.
  room:setPlayerMark(player, "__heg_wild", general.kingdom == "wild" and 1 or 0)
  if general.kingdom == "wild" then
    room:setPlayerMark(player, "__heg_kingdom", "wild")
    room:setPlayerMark(player, "__heg_init_kingdom", "wild")
  end
  for _, skillName in ipairs(general:getSkillNameList(true)) do
    room:addFakeSkill(player, skillName)
  end
end

local function nextRandom(value)
  -- xorshift32, kept in the native Lua layer so the same seed produces the
  -- same deterministic tail order without touching the engine RNG globally.
  value = value ~ ((value << 13) & 0xffffffff)
  value = value ~ (value >> 17)
  value = value ~ ((value << 5) & 0xffffffff)
  return value & 0xffffffff
end

local function shuffleTail(room, seed)
  local value = seed & 0xffffffff
  for index = #room.draw_pile, 2, -1 do
    value = nextRandom(value)
    local swap = (value % index) + 1
    room.draw_pile[index], room.draw_pile[swap] = room.draw_pile[swap], room.draw_pile[index]
  end
  for _, id in ipairs(room.draw_pile) do
    room:setCardArea(id, Card.DrawPile, nil)
  end
  room:syncDrawPile()
end

local function setupCards(room, state, scenario)
  local reserved = {}
  state.fixedHands = {}
  for _, spec in ipairs(scenario.cards) do
    local owner = playerForRole(state, spec.owner)
    local id = takeCard(room, spec.match, reserved)
    if spec.area == "equip" then
      room:moveCardTo(id, Card.PlayerEquip, owner, fk.ReasonJustMove, "tqs_qa", nil, true, owner)
    elseif spec.area == "hand" then
      state.fixedHands[owner.id] = state.fixedHands[owner.id] or {}
      table.insert(state.fixedHands[owner.id], id)
    else
      fail("unsupported catalog card area: " .. tostring(spec.area))
    end
  end
end

local function setupState(room, scenario, seed)
  assertRoomAllowed(room, scenario)
  local actor = table.find(room.players, function(player)
    return player.id > 0 and player:getScreenName() == allowedUsers[1]
  end) or table.find(room.players, function(player) return player.id > 0 end) or room.players[1]
  local target = table.find(room.players, function(player) return player.id ~= actor.id end) or room.players[2]
  local state = {
    scenario = scenario.id,
    seed = seed,
    revision = manifest.sourceRevision,
    startedAt = now(),
    actor = actor,
    target = target,
  }
  if scenario.general then
    attachGeneral(room, state.actor, scenario.general)
    if scenario.trigger == "founding" then
      room:setPlayerProperty(state.actor, "kingdom", "wild")
      state.actor.role = "wild"
      room:broadcastProperty(state.actor, "kingdom")
      room:broadcastProperty(state.actor, "role")
    end
  end
  setupCards(room, state, scenario)
  totalRuns = totalRuns + 1
  activeRooms[tostring(room)] = state
  room:setTag("tqs_qa", state)
  fk.qInfo(string.format("[tqs_qa] scenario=%s seed=%u revision=%s players=%d",
    state.scenario, state.seed, state.revision, #room.players))
  return state
end

local function stateFor(room)
  return room:getTag("tqs_qa")
end

local function triggerRescue(room, state)
  local scenario = scenarioById[state.scenario]
  if scenario.trigger == "rescue-battle" then
    local hegUtil = require "packages.hegemony.util"
    hegUtil.enterBattleRoyalMode(room)
  end
  -- This is the native Dying -> AskForPeaches path. The actor's fixed peach
  -- is offered by game_rule to the same client/bot as in a normal match.
  if state.target.hp > 0 then
    room:changeHp(state.target, -state.target.hp, "loseHp", "tqs_qa")
  end
end

local function triggerFounding(room, state)
  -- The Hegemony GeneralShown rule owns the actual AskForChoice request.
  if state.actor:getMark("__heg_wild") == 1 then
    state.actor:revealGeneral(false)
  end
end

local director = fk.CreateSkill {
  name = "tqs_qa_director&",
}

director:addEffect(fk.GamePrepared, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return player == player.room.players[1] and not stateFor(player.room)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local scenario, seed = parseRequest(room)
    if not scenario then return false end
    setupState(room, scenario, seed)
  end,
})

director:addEffect(fk.DrawInitialCards, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and target == player and state.fixedHands[player.id] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local ids = stateFor(player.room).fixedHands[player.id]
    data.num = #ids
    data.fix_ids = table.simpleClone(ids)
  end,
})

director:addEffect(fk.GameStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and not state.gameStartDone
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local state = stateFor(room)
    state.gameStartDone = true
    shuffleTail(room, state.seed)
    local scenario = scenarioById[state.scenario]
    if scenario.trigger == "rescue" or scenario.trigger == "rescue-battle" then
      triggerRescue(room, state)
    elseif scenario.trigger == "founding" then
      triggerFounding(room, state)
    end
  end,
})

director:addEffect(fk.RoundStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and now() - state.startedAt > maxDurationSeconds
  end,
  on_use = function(self, event, target, player, data)
    fk.qWarning(string.format("[tqs_qa] timeout scenario=%s seed=%u revision=%s",
      stateFor(player.room).scenario, stateFor(player.room).seed, manifest.sourceRevision))
    player.room:gameOver("")
  end,
})

director:addEffect(fk.GameFinished, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return stateFor(player.room) ~= nil and player == player.room.players[1]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    activeRooms[tostring(room)] = nil
    room:removeTag("tqs_qa")
  end,
})

table.insert(extension.related_skills, director)

return extension
