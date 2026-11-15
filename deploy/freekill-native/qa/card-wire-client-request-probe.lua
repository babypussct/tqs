-- Exercise the candidate client request envelope and reply bridge with the
-- real local-reference allocator. No native transport or QML runtime here.
local root = assert(..., "candidate core root required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local Refs = dofile(root .. "/ltk/client/card_wire_refs.lua")
local Requests = dofile(root .. "/ltk/client/card_wire_requests.lua")

local function token(letter)
  return "h:" .. string.rep(letter, 32)
end

local room = {
  card_wire_version = 1,
  card_wire_refs = Refs.new(),
}
local target = { id = 2, class = "ClientPlayer", player = {} }

local function rejects(fn, text)
  local ok, err = pcall(fn)
  assert(not ok and (not text or tostring(err):find(text, 1, true)), tostring(err))
end

-- Hidden and public standing references are both rendered as local IDs, but
-- the reply bridge emits the one-shot prompt token rather than either raw ID.
local chosenToken = token("a")
local hiddenStanding = token("b")
local chosen = Requests.receive(room, "AskForCardChosen", {
  cardWireVersion = 1,
  payload = { target, "h", "prompt", "skill" },
  choices = {
    { token = chosenToken, standing = hiddenStanding },
    { token = token("c"), standing = 401 },
  },
})
assert(chosen[1] == target and chosen[2] == "h")
local hiddenLocal = room.card_wire_refs.byToken[hiddenStanding]
assert(hiddenLocal and room.card_wire_request.byLocal[hiddenLocal] == chosenToken)
assert(Requests.encodeReply(room, hiddenLocal) == chosenToken)
assert(room.card_wire_request == nil, "successful reply must consume local request context")

-- Poxi card groups and visible-data keys are localized consistently.
local poxiToken = token("d")
local poxiStanding = token("e")
local poxi = Requests.receive(room, "AskForPoxi", {
  cardWireVersion = 1,
  payload = {
    type = "AskForCardsChosen",
    data = { { "$Hand", { poxiToken } } },
    extra_data = { visible_data = { [poxiToken] = false }, min = 1, max = 1 },
    cancelable = true,
  },
  choices = { { token = poxiToken, standing = poxiStanding } },
})
local poxiLocal = poxi.data[1][2][1]
assert(type(poxiLocal) == "number" and poxi.extra_data.visible_data[tostring(poxiLocal)] == false)
assert(Requests.encodeReply(room, { poxiLocal })[1] == poxiToken)

-- Active-skill requests keep the upstream shape while projecting explicit
-- visible/expand card fields; selecting a standing alias still emits the
-- request-scoped token.
local activeToken = token("f")
local activeStanding = token("g")
local active = Requests.receive(room, "AskForUseActiveSkill", {
  cardWireVersion = 1,
  payload = { "skill", "prompt", true,
    { skillName = "skill", visible_pile = { activeToken }, expand_pile = "$secret" } },
  choices = { { token = activeToken, standing = activeStanding } },
})
local activeLocal = active[4].visible_pile[1]
assert(activeLocal == room.card_wire_refs.byToken[activeStanding])
local activeReply = Requests.encodeReply(room, {
  card = { skill = "skill", subcards = { activeLocal } }, targets = {},
})
assert(activeReply.card.subcards[1] == activeToken)

-- Yiji's Exppattern ID matcher must use the same localized standing aliases
-- as expand_pile. The native UI evaluates this matcher against local IDs.
local yijiFirst, yijiSecond = token("p"), token("q")
local yijiStandingFirst, yijiStandingSecond = token("r"), token("s")
local yiji = Requests.receive(room, "AskForUseActiveSkill", {
  cardWireVersion = 1,
  payload = { "ex__choose_skill", "prompt", true, {
    skillName = "hs__yiji", expand_pile = { yijiFirst, yijiSecond },
    pattern = ".|.|.|.|.|.|" .. yijiFirst .. "," .. yijiSecond,
    min_t_num = 1, max_t_num = 1, min_c_num = 1, max_c_num = 2,
  } },
  choices = {
    { token = yijiFirst, standing = yijiStandingFirst },
    { token = yijiSecond, standing = yijiStandingSecond },
  },
})
local firstLocal, secondLocal = yiji[4].expand_pile[1], yiji[4].expand_pile[2]
assert(type(firstLocal) == "number" and type(secondLocal) == "number")
assert(yiji[4].pattern == ".|.|.|.|.|.|" .. firstLocal .. "," .. secondLocal)
assert(Requests.encodeReply(room, {
  card = { skill = "ex__choose_skill", subcards = { firstLocal } }, targets = { target.id },
}).card.subcards[1] == yijiFirst)

rejects(function()
  Requests.receive(room, "AskForUseActiveSkill", {
    cardWireVersion = 1,
    payload = { "skill", "prompt", true, { pattern = ".|.|.|.|.|.|301" } },
    choices = {},
  })
end, "non-opaque card reference")
rejects(function()
  Requests.receive(room, "AskForUseActiveSkill", {
    cardWireVersion = 1,
    payload = { "skill", "prompt", true, { pattern = ".|.|.|.|.|.|" .. token("z") } },
    choices = {},
  })
end, "unknown request token")

local agToken = token("l")
local agStanding = token("m")
local ag = Requests.receive(room, "AskForAG", {
  cardWireVersion = 1,
  payload = { { agToken }, false, "probe" },
  choices = { { token = agToken, standing = agStanding } },
})
local agLocal = ag[1][1]
assert(type(agLocal) == "number")
assert(Requests.encodeReply(room, agLocal) == agToken)

local playToken = token("n")
local playStanding = token("o")
local play = Requests.receive(room, "PlayCard", {
  cardWireVersion = 1,
  payload = {},
  choices = { { token = playToken, standing = playStanding } },
})
assert(next(play) == nil)
local playLocal = room.card_wire_refs.byToken[playStanding]
local playPreview = Requests.encodeReply(room, { card = playLocal, targets = {} }, false)
assert(playPreview.card == playToken and room.card_wire_request ~= nil,
  "reply preview must translate without consuming the request context")
local playReply = Requests.encodeReply(room, { card = playLocal, targets = {} })
assert(playReply.card == playToken)

-- An unoffered hidden alias, an anonymous deck slot and a sparse card list
-- fail closed before any transport payload can be emitted.
local staleToken = token("h")
local staleStanding = token("i")
Requests.receive(room, "AskForPoxi", {
  cardWireVersion = 1,
  payload = { type = "x", data = { { "$Hand", { staleToken } } }, cancelable = true },
  choices = { { token = staleToken, standing = staleStanding } },
})
local staleLocal = room.card_wire_refs.byToken[staleStanding]
local anonymous = room.card_wire_refs:replaceAnonymousDeck(1, {})[1]
-- A malformed request context that advertises an anonymous slot must still
-- fail at the explicit anonymous-slot guard, not escape through the
-- request-allowlist check.
room.card_wire_request.byLocal[anonymous] = token("j")
rejects(function() Requests.encodeReply(room, { anonymous }) end, "anonymous")
room.card_wire_request.byLocal[anonymous] = nil
rejects(function() Requests.encodeReply(room, { [1] = staleLocal, [3] = staleLocal }) end, "dense")
rejects(function() Requests.encodeReply(room, { room.card_wire_refs:toLocal(token("k")) }) end,
  "not an offered")

-- Execute the actual upstream chooser callback against v1 request aliases.
-- Yiji's newly drawn cards have no entry in Fk.cards on the client.  The
-- callback must accept only the request-offered, ID-only aliases and keep
-- full-card matching for ordinary physical cards.
local oldFk, oldfk, oldClient = Fk, fk, ClientInstance
local oldContains, oldPattern = table.contains, Exppattern
table.contains = function(items, sought)
  for _, item in ipairs(items) do if item == sought then return true end end
  return false
end
local chooserEffect
fk = { CreateSkill = function()
  return {
    addEffect = function(_, kind, effect)
      assert(kind == "active")
      chooserEffect = effect
    end,
    addAI = function() end,
  }
end }
Fk = {
  getCardById = function(_, id)
    if id == 401 then return { id = id } end
    return nil
  end,
  Ltk = { AI = {
    newActiveStrategy = function(value) return value end,
    newChooseCardsAndPlayersStrategy = function(value) return value end,
  } },
}
Exppattern = { Parse = function(_, pattern)
  return { match = function(_, card)
    assert(card and card.id, "chooser tried to match unknown physical card")
    return pattern == ".|.|.|.|.|.|" .. card.id
  end }
end }
ClientInstance = room
local yijiAgain = Requests.receive(room, "AskForUseActiveSkill", {
  cardWireVersion = 1,
  payload = { "ex__choose_skill", "prompt", true, {
    skillName = "hs__yiji", expand_pile = { yijiFirst, yijiSecond },
    pattern = ".|.|.|.|.|.|" .. yijiFirst .. "," .. yijiSecond,
  } },
  choices = {
    { token = yijiFirst, standing = yijiStandingFirst },
    { token = yijiSecond, standing = yijiStandingSecond },
  },
})
dofile(root .. "/standard/aux_skills_dir/ex__choose_skill.lua")
assert(chooserEffect and type(chooserEffect.card_filter) == "function")
local currentIds = yijiAgain[4].expand_pile
local player = { getCardIds = function() return {} end }
local skill = {
  max_c_num = 2,
  will_throw = false,
  pattern = yijiAgain[4].pattern,
  getPile = function() return currentIds end,
}
local function selects(id)
  return chooserEffect.card_filter(skill, player, id, {})
end
assert(selects(firstLocal) and selects(secondLocal),
  "v1 Yiji ID-only aliases must be selectable in the real chooser")
assert(not selects(room.card_wire_refs:toLocal(token("z"))),
  "unknown client-local alias must not be selectable")
local unoffered = room.card_wire_refs:toLocal(token("v"))
currentIds[3] = unoffered
assert(not selects(unoffered), "non-offered expanded alias must fail closed")
skill.pattern = ".|.|heart|.|.|.|" .. firstLocal
assert(not selects(firstLocal), "suit matcher cannot be evaluated without physical metadata")
skill.pattern = ".|.|.|.|.|.|^" .. firstLocal
assert(not selects(firstLocal), "negative matcher cannot bypass physical metadata")
skill.pattern = ".|.|.|.|.|.|" .. firstLocal
skill.will_throw = true
assert(not selects(firstLocal), "discard checks require real card metadata")
skill.will_throw = false
room.card_wire_request.command = "PlayCard"
assert(not selects(firstLocal), "non-active request cannot authorize chooser aliases")
room.card_wire_request.command = "AskForUseActiveSkill"
room.card_wire_version = nil
rejects(function() selects(firstLocal) end, "unknown physical card")
skill.pattern = ".|.|.|.|.|.|401"
currentIds[4] = 401
assert(selects(401), "physical card matching must retain upstream behavior")
table.contains, Exppattern = oldContains, oldPattern
Fk, fk, ClientInstance = oldFk, oldfk, oldClient
room.card_wire_version = 1

-- Legacy mode and a non-request UI reply remain byte-for-byte at the Lua
-- value boundary; the QML bridge only changes transport ownership.
room.card_wire_version = nil
assert(Requests.encodeReply(room, { 701 })[1] == 701)
room.card_wire_version = 1
room.card_wire_request = nil
assert(Requests.encodeReply(room, "__cancel") == "__cancel")

print("PASS candidate client request bridge: standing/local alias localization, AG/Poxi/PlayCard/active payloads, preview/one-shot reply tokens, anonymous/stale/sparse fail-close and legacy; synthetic-only; native/browser NOT RUN")
