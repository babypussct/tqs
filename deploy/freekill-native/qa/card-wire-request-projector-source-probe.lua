-- Exercise the candidate-only physical request projector and reverse resolver
-- with the real card-handle protocol. Native sockets and QML remain separate
-- gates; this probe proves packet shapes, opaque choices and replay rejection.
local root, projectorFile, protocolFile = ...
assert(root and projectorFile and protocolFile, "candidate request projector inputs required")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3, PlayerSpecial = 4,
  Processing = 5, DiscardPile = 6, DrawPile = 7, Void = 8,
}
Player = { Hand = 1, Equip = 2, Judge = 3, Special = 4 }

table.contains = function(list, value)
  for _, item in ipairs(list) do if item == value then return true end end
  return false
end
table.insertTable = function(list, values)
  for _, value in ipairs(values) do table.insert(list, value) end
end
table.simpleClone = function(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = table.simpleClone(item) end
  return result
end

local Protocol = dofile(protocolFile)
local Projection = dofile(projectorFile)
local nonce = 0
local function mint()
  nonce = nonce + 1
  return "h:" .. string.format("%032x", nonce)
end
local protocol = Protocol.new(mint)

local physical = {}
local function player(id)
  local result = {
    id = id,
    player = {},
    serverplayer = id == 1 and physical or {},
    _splayer = id == 1 and physical or {},
    player_cards = { [Player.Hand] = {}, [Player.Equip] = {}, [Player.Judge] = {} },
    special_cards = {},
  }
  function result:getCardIds(areas, specialName)
    if areas == "he" then
      local cards = {}
      for _, id in ipairs(self.player_cards[Player.Hand]) do table.insert(cards, id) end
      for _, id in ipairs(self.player_cards[Player.Equip]) do table.insert(cards, id) end
      return cards
    end
    local ret = {}
    if type(areas) == "string" then
      if areas:find("h") then table.insertTable(ret, self.player_cards[Player.Hand]) end
      if areas:find("e") then table.insertTable(ret, self.player_cards[Player.Equip]) end
      if areas:find("j") then table.insertTable(ret, self.player_cards[Player.Judge]) end
    elseif areas == Player.Hand then
      table.insertTable(ret, self.player_cards[Player.Hand])
    elseif areas == Player.Equip then
      table.insertTable(ret, self.player_cards[Player.Equip])
    elseif areas == Player.Judge then
      table.insertTable(ret, self.player_cards[Player.Judge])
    end
    return ret
  end
  function result:getPile(name) return table.simpleClone(self.special_cards[name] or {}) end
  function result:getPileNameOfId(id)
    for name, cards in pairs(self.special_cards) do
      for _, card in ipairs(cards) do if card == id then return name end end
    end
  end
  return result
end

local owner = player(1)
local target = player(2)
target.serverplayer = {}
owner.player_cards[Player.Hand] = { 301 }
owner.player_cards[Player.Equip] = { 302 }
owner.special_cards["$secret"] = { 303 }
target.player_cards[Player.Hand] = { 101, 102 }
target.player_cards[Player.Equip] = { 201 }
target.special_cards["$public"] = { 202 }

local areas = {
  [101] = Card.PlayerHand, [102] = Card.PlayerHand, [201] = Card.PlayerEquip,
  [202] = Card.PlayerSpecial, [301] = Card.PlayerHand, [302] = Card.PlayerEquip,
  [303] = Card.PlayerSpecial,
  [401] = Card.DrawPile, [402] = Card.DrawPile, [403] = Card.DrawPile, [404] = Card.DrawPile,
}
Fk = { getCardById = function(_, id) return { name = "slash", suit = 1, number = id % 13 + 1 } end }
local owners = {
  [101] = target, [102] = target, [201] = target, [202] = target,
  [301] = owner, [302] = owner, [303] = owner,
}
local room = {
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  players = { owner, target },
  _cardWireProtocol = protocol,
  agRecord = { { { owner.id }, { 201, 202 }, nil, {} } },
}
function room:getSettings(key) return self.settings[key] end
function room:getPlayerById(id)
  for _, item in ipairs(self.players) do if item.id == id then return item end end
end
function room:cardWireAudience(socket)
  return socket == physical and "aud:physical-owner" or "aud:other-socket"
end
function room:getCardArea(id) return areas[id] end
function room:getCardOwner(id) return owners[id] end
function room:getTag(name)
  if name == "AGrecord" then return self.agRecord end
end

local cases = 0
local function commit(projected)
  assert(projected.cardWireVersion == 1 and type(projected.payload) == "table")
  assert(type(projected.choices) == "table")
  return projected
end
local function project(seat, command, data)
  local batch = protocol:beginBatch()
  local ok, projected = pcall(Projection.project, room, seat, physical, command, data,
    batch, "req/" .. (cases + 1))
  if not ok then batch:abort(); error(projected) end
  batch:commit()
  cases = cases + 1
  return commit(projected)
end
local function rejects(fn, text)
  local ok, err = pcall(fn)
  assert(not ok and (not text or tostring(err):find(text, 1, true)), tostring(err))
end

-- A target hand request carries no canonical card ID in the visible payload;
-- its request allowlist and standing references are opaque to the requester.
local chosen = project(owner, "AskForCardChosen", { target, "h", "prompt", "skill" })
assert(chosen.payload[1] == target and chosen.payload[2] == "h")
assert(#chosen.choices == 2 and chosen.choices[1].standing:sub(1, 2) == "h:")
local chosenToken = chosen.choices[1].token
local resolvedChosen = Projection.resolve(room, owner, physical, "AskForCardChosen",
  chosenToken, "req/1", { target, "h", "prompt", "skill" })
assert(resolvedChosen == 101)
rejects(function()
  Projection.resolve(room, owner, physical, "AskForCardChosen", chosenToken,
    "req/1", { target, "h", "prompt", "skill" })
end, "rejected")

local poxiData = {
  type = "AskForCardsChosen",
  data = { { "$Hand", { 101, 102 } }, { "$Equip", { 201 } } },
  extra_data = {
    to = target.id, min = 1, max = 2, skillName = "probe",
    prompt = "#probe", pattern = ".", visible_data = { ["101"] = false },
  },
  cancelable = true,
}
local poxi = project(owner, "AskForPoxi", poxiData)
assert(type(poxi.payload.data[1][2][1]) == "string" and
  poxi.payload.data[1][2][1]:sub(1, 2) == "h:")
assert(next(poxi.payload.extra_data.visible_data) ~= nil)
assert(poxi.choices[1].face == nil and poxi.choices[2].face.name == "slash",
  "Poxi must display only the unmasked face from the same hand")
local poxiReply = { poxi.choices[1].token, poxi.choices[2].token }
local poxiResolved = Projection.resolve(room, owner, physical, "AskForPoxi", poxiReply,
  "req/2", poxiData)
assert(poxiResolved[1] == 101 and poxiResolved[2] == 102)

local ag = project(owner, "AskForAG", { { 201, 202 }, false, "probe" })
assert(type(ag.payload[1][1]) == "string" and ag.payload[1][1]:sub(1, 2) == "h:" and
  type(ag.payload[1][2]) == "string" and ag.payload[1][2]:sub(1, 2) == "h:" and
  ag.choices[1].standing == 201 and ag.choices[2].standing == 202)
local agResolved = Projection.resolve(room, owner, physical, "AskForAG", ag.choices[1].token,
  "req/3", { { 201, 202 }, false, "probe" })
assert(agResolved == 201)

local activeData = {
  "probe_skill", "prompt", true,
  { skillName = "probe_skill", min = 1, visible_pile = { 301 },
    min_card_num = 1, max_card_num = 2,
    expand_pile = "$secret", targets = { target.id },
    fix_targets = { owner.id }, must_targets = { target.id },
    exclusive_targets = { owner.id }, include_targets = { target.id } },
}
local active = project(owner, "AskForUseActiveSkill", activeData)
assert(type(active.payload[4].visible_pile[1]) == "string" and
  active.payload[4].visible_pile[1]:sub(1, 2) == "h:")
assert(active.payload[4].targets[1] == target.id and
  active.payload[4].min_card_num == 1 and active.payload[4].max_card_num == 2 and
  active.payload[4].fix_targets[1] == owner.id and
  active.payload[4].must_targets[1] == target.id and
  active.payload[4].exclusive_targets[1] == owner.id and
  active.payload[4].include_targets[1] == target.id)
local activeToken
for _, entry in ipairs(active.choices) do
  if entry.standing == 301 then activeToken = entry.token end
end
assert(activeToken)
local activeResolved = Projection.resolve(room, owner, physical, "AskForUseActiveSkill", {
  card = { skill = "probe_skill", subcards = { activeToken } }, targets = {},
}, "req/4", activeData)
assert(activeResolved.card.subcards[1] == 301)

local choices = project(owner, "AskForChoices", {
  { "A" }, { "A", "B" }, { 1, 1 }, false, "probe", "", false, true,
})
assert(#choices.choices == 0)
local choiceResolved = Projection.resolve(room, owner, physical, "AskForChoices", { "A" },
  "req/5", { { "A" }, { "A", "B" }, { 1, 1 }, false, "probe", "", false, true })
assert(choiceResolved[1] == "A")
rejects(function()
  Projection.resolve(room, owner, physical, "AskForChoices", { "Z" },
    "req/5b", { { "A" }, { "A", "B" }, { 1, 1 }, false, "probe", "", false, true })
end, "unaudited")

for _, command in ipairs({"AskForChoices", "AskForOptions"}) do
  local optional = {{"A", "Cancel"}, {"A", "Cancel"}, {1, 1}, true, "probe", "", false, true}
  local mandatory = {{"A", "B"}, {"A", "B"}, {1, 1}, false, "probe", "", false, true}
  assert(#Projection.resolve(room, owner, physical, command, {}, "req/optional", optional) == 0)
  assert(Projection.resolve(room, owner, physical, command, {"Cancel"}, "req/cancel", optional)[1] == "Cancel")
  rejects(function()
    Projection.resolve(room, owner, physical, command, {}, "req/mandatory", mandatory)
  end, "cardinality")
end

local play = project(owner, "PlayCard", nil)
assert(next(play.payload) == nil and #play.choices >= 3)
local playResolved = Projection.resolve(room, owner, physical, "PlayCard", {
  card = play.choices[1].token, targets = {},
}, "req/6", nil)
assert(playResolved.card == 301)
assert(Projection.resolve(room, owner, physical, "PlayCard", "", "req/6b", nil) == "")

local initialData = {
  component = {
    name = "ChooseInitialGeneralBox",
    uri = "LunarLtk.Pages.Popups",
    model = {
      name = "ChooseInitialGeneralModel",
      uri = "LunarLtk.Models.Popups",
      prop = {
        generals = { "probe_a", "probe_b", "probe_c" },
        choiceNum = 2,
        hegemony = true,
        enabledKingdoms = { "wei", "shu" },
        selfRole = "",
        hideRole = true,
      },
    },
  },
}
local initial = project(owner, "CustomDialog", initialData)
assert(initial.payload.component.model.prop.generals[1] == "probe_a")
assert(initial.payload.component.model.prop.choiceNum == 2)
local initialResolved = Projection.resolve(room, owner, physical, "CustomDialog",
  { "probe_a,probe_b", "kingdom,wei" }, "req/7", initialData)
assert(initialResolved[1] == "probe_a,probe_b" and initialResolved[2] == "kingdom,wei")

local watchData = {
  component = {
    url = "packages/hegemony/qml/KnownBothBox.qml",
    model = {
      url = "packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml",
      prop = {
        cards = { "probe_a", "probe_b" },
        all_cards = { "probe_a", "probe_b" },
        disable_cards = {}, min = 0, max = 0,
        prompt = "#WatchNextPlayer::2",
        ok_options = { "OK" }, cancel_options = {},
      },
    },
  },
}
local watch = project(owner, "CustomDialog", watchData)
assert(watch.payload.component.model.prop.cards[2] == "probe_b")
local watchResolved = Projection.resolve(room, owner, physical, "CustomDialog",
  { cards = {}, choice = "OK" }, "req/8", watchData)
assert(watchResolved.choice == "OK" and #watchResolved.cards == 0)

local empty = project(owner, "EmptyRequest", nil)
assert(next(empty.payload) == nil and next(empty.choices) == nil)
rejects(function()
  project(owner, "EmptyRequest", {})
end, "must not carry a payload")

-- The actual upstream nullification request carries effectCardId=0 when the
-- effect is a virtual card. The sentinel must survive without a minted choice;
-- an actual physical effect card still requires an opaque reference.
local virtualEffect = project(owner, "AskForUseCard", {
  "nullification", "prompt", true, "nullification", { effectCardId = 0 },
})
assert(virtualEffect.payload[5].effectCardId == 0)
for _, choice in ipairs(virtualEffect.choices) do
  assert(choice.standing ~= 0)
end

local physicalEffect = project(owner, "AskForUseCard", {
  "nullification", "prompt", true, "nullification", { effectCardId = 201 },
})
assert(type(physicalEffect.payload[5].effectCardId) == "string" and
  physicalEffect.payload[5].effectCardId:sub(1, 2) == "h:")
local effectChoiceFound = false
for _, choice in ipairs(physicalEffect.choices) do
  if choice.standing == 201 then
    effectChoiceFound = choice.token == physicalEffect.payload[5].effectCardId
  end
end
assert(effectChoiceFound)
rejects(function()
  project(owner, "AskForUseCard", {
    "nullification", "prompt", true, "nullification", { effectCardId = -1 },
  })
end, "invalid effectCardId")
rejects(function()
  project(owner, "AskForUseCard", {
    "nullification", "prompt", true, "nullification", { cardId = 0 },
  })
end, "invalid cardId")

rejects(function()
  project(owner, "AskForCardChosen", { target, { card_data = { { "$Hand", { 101, 0 } } } }, "", "x" })
end, "invalid")
rejects(function()
  project(owner, "CustomDialog", { component = { url = "unreviewed", model = { prop = { cardId = 101 } } } })
end, "unaudited")
rejects(function()
  project(owner, "AskForUseActiveSkill", {
    "probe_skill", "prompt", true, { targets = { 999 } },
  })
end, "unknown player")
-- Halberd's extra-target dialog passes the original target IDs in orig_tos.
-- They are player identities and must never become opaque card handles.
local halberd = project(owner, "AskForUseActiveSkill", {
  "halberd_extra", "prompt", true,
  { orig_tos = { target.id }, targets = { owner.id, target.id } },
})
assert(halberd.payload[4].orig_tos[1] == target.id)
assert(halberd.payload[4].targets[1] == owner.id)
assert(halberd.payload[4].targets[2] == target.id)
-- Active-skill requests also offer the owner's existing hand, equip and
-- private special-pile cards.
-- orig_tos and targets must contribute no additional card choices.
assert(#halberd.choices == 3 and halberd.choices[1].standing == 301 and
  halberd.choices[2].standing == 302 and halberd.choices[3].standing == 303)
rejects(function()
  project(owner, "AskForUseActiveSkill", {
    "halberd_extra", "prompt", true, { orig_tos = { 999 } },
  })
end, "unknown player")
rejects(function()
  project(owner, "AskForUseActiveSkill", {
    "halberd_extra", "prompt", true, { orig_tos = { 101.5 } },
  })
end, "player IDs")
rejects(function()
  project(owner, "AskForUseActiveSkill", {
    "probe_skill", "prompt", true, { unknown_card_number = 101 },
  })
end, "unaudited numeric request field")

-- The native Hegemony Yiji path uses Room:askToChooseCardsAndPlayers,
-- which forwards distinct target/card bounds through ex__choose_skill.
-- Its extra draw-pile cards must be choice-scoped while its four bounds
-- remain numeric. Unknown numeric fields must still fail closed.
local yijiData = {
  "ex__choose_skill", "#yiji-give", true,
  { targets = { owner.id, target.id }, min_t_num = 1, max_t_num = 1,
    min_c_num = 1, max_c_num = 2, equal = false,
    pattern = ".|.|.|.|.|.|401,402",
    skillName = "hs__yiji", expand_pile = { 401, 402 } },
}
local yiji = project(owner, "AskForUseActiveSkill", yijiData)
assert(yiji.payload[4].min_t_num == 1 and yiji.payload[4].max_t_num == 1 and
  yiji.payload[4].min_c_num == 1 and yiji.payload[4].max_c_num == 2 and
  yiji.payload[4].targets[1] == owner.id and yiji.payload[4].targets[2] == target.id and
  type(yiji.payload[4].expand_pile[1]) == "string" and
  yiji.payload[4].expand_pile[1]:sub(1, 2) == "h:" and
  not yiji.payload[4].pattern:find("401", 1, true) and
  not yiji.payload[4].pattern:find("402", 1, true) and
  yiji.payload[4].pattern:find("h:", 1, true))

local function faceCount(request)
  local count = 0
  for _, choice in ipairs(request.choices) do
    if choice.face then
      assert(type(choice.standing) == "string" and choice.face.id == nil)
      assert(choice.face.name == "slash" and choice.face.suit == 1 and choice.face.number >= 1)
      count = count + 1
    end
  end
  return count
end
assert(faceCount(yiji) == 2, "Yiji must show its two draw-pile offers only")
local processingAlias = protocol:reference("aud:physical-owner", 403, false)
areas[403] = Card.Processing
local arrangeData = {
  cards = {{401, 402, 403, 404}, {}}, names = {"Bottom", "Top"},
  capacities = {4, 2}, limits = {0, 2}, is_free = true, pattern = ".", poxi_type = "", cancelable = false,
}
local arrange = project(owner, "AskForArrangeCards", arrangeData)
assert(faceCount(arrange) == 4, "Xunxun must show all four offered cards")
assert(arrange.choices[3].standing == processingAlias, "a private processing card keeps its standing alias")
local arrangeKey = "req/" .. cases
local tokens = arrange.payload.cards[1]
rejects(function()
  Projection.resolve(room, owner, physical, "AskForArrangeCards", {tokens, {}}, arrangeKey, arrangeData)
end, "row bounds")
local arranged = Projection.resolve(room, owner, physical, "AskForArrangeCards",
  {{tokens[3], tokens[4]}, {tokens[2], tokens[1]}}, arrangeKey, arrangeData)
assert(arranged[1][1] == 403 and arranged[2][1] == 402 and arranged[2][2] == 401)
local batch = protocol:beginBatch()
local outsider = Projection.project(room, owner, {}, "AskForUseActiveSkill", yijiData, batch, "other-socket")
assert(faceCount(outsider) == 0, "nonowner must never get request-only card faces")
batch:abort()

local response = project(owner, "AskForResponseCard", {
  "view_as", ".|.|.|.|.|.|401,404", "peek", true, { expand_pile = {401}, visible_pile = {402} }, {},
})
assert(not response.payload[2]:find("401", 1, true) and response.payload[2]:find("h:", 1, true))
assert(faceCount(response) == 2, "expanded and explicitly visible cards can be read; pattern-only IDs stay hidden")

local mixedData = {
  cards = {401, 201}, choices = {"OK"}, cancel_choices = {"Cancel"}, disabled = {201}, min = 1, max = 1,
  extra_data = {visible_data = {["201"] = 0}},
}
protocol:reference("aud:physical-owner", 201, true)
local mixed = project(owner, "AskForCardsAndChoice", mixedData)
local mixedKey = "req/" .. cases
assert(faceCount(mixed) == 1 and type(mixed.choices[2].standing) == "string")
assert(mixed.payload.extra_data.visible_data[mixed.choices[2].token] == false)
local standingBatch = protocol:beginBatch()
assert(standingBatch:currentReference("aud:physical-owner", 201) == 201, "mask must preserve the public board identity")
standingBatch:abort()
rejects(function()
  Projection.resolve(room, owner, physical, "AskForCardsAndChoice", { cards = {}, choice = "unoffered" }, mixedKey, mixedData)
end, "value is invalid")
rejects(function()
  Projection.resolve(room, owner, physical, "AskForCardsAndChoice",
    { cards = {mixed.choices[2].token}, choice = "OK" }, mixedKey, mixedData)
end, "disabled card")
local cancelledChoice = project(owner, "AskForCardsAndChoice", mixedData)
assert(#cancelledChoice.choices == 2)
assert(Projection.resolve(room, owner, physical, "AskForCardsAndChoice", { cards = {}, choice = "Cancel" },
  "req/" .. cases, mixedData).choice == "Cancel")

local general = { {"probe_a", "probe_b"}, 1, true, false, "askForGeneralsChosen", "", {n = 1} }
local generalRequest = project(owner, "AskForGeneral", general)
assert(generalRequest.payload[1][1] == "probe_a" and #generalRequest.choices == 0)
local generalKey = "req/" .. cases
assert(Projection.resolve(room, owner, physical, "AskForGeneral", {"probe_b"}, generalKey, general)[1] == "probe_b")
rejects(function()
  Projection.resolve(room, owner, physical, "AskForGeneral", {"unoffered"}, generalKey, general)
end, "unaudited value")

local function utilityDialog(name, prop)
  return { component = { url = "packages/utility/qml/Choose" .. name .. "Box.qml",
    model = { url = "packages/utility/qml/models/Choose" .. name .. "Model.qml", prop = prop } } }
end
for _, item in ipairs({
  {"Skill", {skills = {"inherited_skill"}, min = 1, max = 1, generals = {"probe_a"}}, "inherited_skill"},
  {"CardNames", {choices = {"jink"}, minNum = 1, maxNum = 1, allChoices = {{"jink"}}, repeatable = false}, "jink"},
}) do
  local data = utilityDialog(item[1], item[2])
  local request = project(owner, "CustomDialog", data)
  assert(request.payload.component.url == data.component.url and #request.choices == 0)
  local key = "req/" .. cases
  assert(Projection.resolve(room, owner, physical, "CustomDialog", {item[3]}, key, data)[1] == item[3])
  rejects(function()
    Projection.resolve(room, owner, physical, "CustomDialog", {"unoffered"}, key, data)
  end, "unaudited value")
end
local generalOptions = utilityDialog("GeneralsAndChoice", {
  cards = {"probe_a", "probe_b"}, all_cards = {"probe_a", "probe_b"}, disable_cards = {"probe_b"},
  min = 1, max = 1, ok_options = {"OK"}, cancel_options = {"Cancel"},
})
project(owner, "CustomDialog", generalOptions)
local generalOptionsKey = "req/" .. cases
assert(Projection.resolve(room, owner, physical, "CustomDialog", {cards = {}, choice = "Cancel"},
  generalOptionsKey, generalOptions).choice == "Cancel")
rejects(function()
  Projection.resolve(room, owner, physical, "CustomDialog", {cards = {"probe_b"}, choice = "OK"},
    generalOptionsKey, generalOptions)
end, "unoffered card")

-- Custom card groups are valid upstream without an explicit prompt. Preserve
-- the skill name, produce a dense wire payload, and retain opaque choices.
local customChoice = { target, { card_data = { { "$Hand", { 101 } } } }, nil, "probe" }
local customChosen = project(owner, "AskForCardChosen", customChoice)
assert(customChosen.payload[3] == "" and customChosen.payload[4] == "probe")
assert(#customChosen.payload == 4 and #customChosen.choices == 1)
assert(customChosen.payload[2].card_data[1][2][1] == customChosen.choices[1].token)
assert(customChoice[3] == nil)
assert(Projection.resolve(room, owner, physical, "AskForCardChosen",
  customChosen.choices[1].token, "req/" .. cases, customChoice) == 101)
rejects(function()
  project(owner, "AskForCardChosen", { target, customChoice[2], nil, "probe", [5] = 101 })
end, "unaudited")
rejects(function()
  project(owner, "AskForCardChosen", { target, customChoice[2], nil, [5] = "probe" })
end, "unaudited")
rejects(function()
  project(owner, "AskForCardChosen", { target, "h", nil, "probe" })
end, "dense array")

print(string.format("PASS candidate physical request projector: card-chosen opaque scope, Poxi/AG/PlayCard projection, active-skill reply resolution, CustomDialog exact schemas, scalar choices, malformed/unaudited fail-close; %d cases; synthetic-only; native/browser NOT RUN", cases))
