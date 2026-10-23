-- SPDX-License-Identifier: GPL-3.0-or-later
-- Epistemic view for a SINGLE SmartAI seat in new_heg_mode.
-- Never use another seat's __heg_* marks, hidden generals, role, or cards.
-- A rule-level relation may depend on those fields internally; it is queried
-- only after the OTHER seat has publicly revealed its kingdom.
local FactionInference = {}
FactionInference.__index = FactionInference

local ATTACK = { slash = true, fire_slash = true, thunder_slash = true, duel = true }
local SUPPORT = { peach = true }
local MAX_OBSERVATIONS = 64

local function knownKingdom(ai, player)
  if not player then return nil end
  if type(player.kingdom) == "string" and player.kingdom ~= "unknown" and player.kingdom ~= "" then
    return player.kingdom
  end
  -- The BOT's own unrevealed kingdom is private information it is entitled to.
  if player == ai.player and type(player.getMark) == "function" then
    local kingdom = player:getMark("__heg_kingdom")
    if type(kingdom) == "string" and kingdom ~= "unknown" and kingdom ~= "" then
      return kingdom
    end
  end
  return nil
end

local function publicEvent(event)
  if type(event) ~= "table" or event.status ~= "dead" then return nil end
  local data = event.data
  if type(data) ~= "table" or data.noIndicate or data.toCard or
    type(data.tos) ~= "table" or type(data.card) ~= "table" then
    return nil
  end
  -- These targeted uses are announced by #UseCardToTargets. Never inspect
  -- subcards, hand zones, hidden skill fields or other event-private data.
  local card = data.card.trueName or data.card.name
  local kind = ATTACK[card] and "attack" or SUPPORT[card] and "support" or nil
  if not kind or type(data.from) ~= "table" or type(data.from.id) ~= "number" then return nil end
  local targets = {}
  for _, target in ipairs(data.tos) do
    if type(target) == "table" and type(target.id) == "number" and
      target.id ~= data.from.id then
      targets[#targets + 1] = target.id
    end
  end
  if #targets == 0 then return nil end
  return { actor = data.from.id, targets = targets, kind = kind }
end

function FactionInference.new(ai)
  return setmetatable({ ai = ai, cursor = 0, observations = {} }, FactionInference)
end

function FactionInference:sync()
  local logic = self.ai.room and self.ai.room.logic
  local events = logic and logic.event_recorder and GameEvent and
    GameEvent.UseCard and logic.event_recorder[GameEvent.UseCard]
  if type(events) ~= "table" then return end
  -- A still-running event may not yet have emitted its public log. Revisit it
  -- next time, rather than advancing the cursor past an unobserved action.
  for i = self.cursor + 1, #events do
    local event = events[i]
    if event.status ~= "dead" then break end
    self.cursor = i
    local observation = publicEvent(event)
    if observation then
      self.observations[#self.observations + 1] = observation
      if #self.observations > MAX_OBSERVATIONS then table.remove(self.observations, 1) end
    end
  end
end

local function lookup(room, id)
  if not room or type(room.getPlayerById) ~= "function" then return nil end
  return room:getPlayerById(id)
end

function FactionInference:relation(target)
  local ai = self.ai
  if not target or not ai.player then
    return { state = "unknown", confidence = 0, probabilities = {}, attitude = 0 }
  end
  if target == ai.player then
    return { state = "friend", confidence = 1, probabilities = {}, attitude = 1 }
  end
  -- Rule-level knowledge only when the other player's affiliation is public.
  -- In that case the core rule can account for gouni, wild and faction caps.
  if knownKingdom(ai, target) and type(ai.player.isFriend) == "function" then
    local friend = ai.player:isFriend(target)
    return { state = friend and "friend" or "enemy", confidence = 1,
      probabilities = {}, attitude = friend and 1 or -1 }
  end

  self:sync()
  local players = ai.room and ai.room.players or {}
  local kingdoms, scores = {}, { other = 0 }
  -- All available factions are announced at room setup. Including them
  -- avoids treating an as-yet-unrevealed faction as impossible.
  local allKingdoms = ai.room and type(ai.room.getBanner) == "function" and
    ai.room:getBanner("all_kingdoms")
  if type(allKingdoms) == "table" then
    for _, kingdom in ipairs(allKingdoms) do
      if type(kingdom) == "string" and kingdom ~= "" and kingdom ~= "unknown" then
        kingdoms[kingdom] = true
        scores[kingdom] = 0
      end
    end
  end
  for _, player in ipairs(players) do
    local kingdom = knownKingdom(ai, player)
    if kingdom and not kingdoms[kingdom] then
      kingdoms[kingdom] = true
      scores[kingdom] = 0
    end
  end
  local evidence = 0
  for _, observation in ipairs(self.observations) do
    local actor, affected = lookup(ai.room, observation.actor), nil
    for _, id in ipairs(observation.targets) do
      affected = lookup(ai.room, id)
      local reference
      if target.id == observation.actor then
        reference = affected
      elseif target.id == id then
        reference = actor
      end
      -- Reference must have a PUBLIC kingdom (or be the BOT itself).
      local kingdom = reference and knownKingdom(ai, reference)
      -- Public wild seats can belong to different independent kingdoms;
      -- seeing one helped must not imply allegiance to every other wild seat.
      if kingdom == "wild" then kingdom = nil end
      if kingdom and scores[kingdom] ~= nil and reference ~= target then
        local direction = observation.kind == "support" and 0.9 or -1.1
        scores[kingdom] = math.max(-3, math.min(3, scores[kingdom] + direction))
        evidence = evidence + 1
      end
    end
  end

  -- 'other' retains non-zero mass for unknown/unrepresented kingdoms; it also
  -- prevents public action evidence from ever turning into a certainty.
  local probabilities, total, candidates = {}, 0, 0
  for kingdom, score in pairs(scores) do
    local weight = math.exp(score)
    probabilities[kingdom] = weight
    total = total + weight
    candidates = candidates + 1
  end
  for kingdom, weight in pairs(probabilities) do
    probabilities[kingdom] = weight / total
  end
  local mine = knownKingdom(ai, ai.player)
  local confidence = evidence / (evidence + 2)
  local attitude = 0
  if confidence > 0 and mine and probabilities[mine] then
    -- Compare against the no-evidence prior, not an arbitrary 50% cutoff.
    -- With four public factions, one genuinely supportive action should not
    -- become hostile simply because P(same faction) is still below 1/2.
    local prior = 1 / candidates
    local delta = probabilities[mine] - prior
    attitude = confidence * (delta >= 0 and delta / (1 - prior) or delta / prior)
  end
  return { state = "unknown", confidence = confidence,
    probabilities = probabilities, attitude = attitude, evidence = evidence }
end

return FactionInference
