-- Candidate-only physical request projection for Hegemony card-wire v1.
--
-- A request is delivered as an envelope containing the upstream-shaped
-- payload plus one-shot opaque choice references.  The client maps those
-- references to the standing local aliases that it already uses for cards;
-- the reply bridge maps them back before the native transport is called.
-- This module is intentionally inert until the guarded candidate runtime
-- installs it and negotiates card_wire_version == 1.
local RequestWire = {}

local function dense(value, label)
  assert(type(value) == "table", label .. " must be a table")
  local count, maximum = 0, 0
  for key in pairs(value) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1,
      label .. " must be a dense array")
    count = count + 1
    if key > maximum then maximum = key end
  end
  assert(count == maximum, label .. " must be a dense array")
  return count
end

local function copy(value, seen)
  if type(value) ~= "table" then return value end
  -- Player objects are CBOR-tagged by their metatable.  Preserve them so the
  -- normal client decoder still turns them into ClientPlayer objects.
  if value.id ~= nil and (value.player ~= nil or value.serverplayer ~= nil) then
    return value
  end
  seen = seen or {}
  if seen[value] then error("cyclic request payload") end
  seen[value] = true
  local result = {}
  for key, item in pairs(value) do
    result[key] = copy(item, seen)
  end
  seen[value] = nil
  return result
end

local function fields(value, allowed, label)
  assert(type(value) == "table", label .. " must be a table")
  for key in pairs(value) do
    assert(allowed[key] == true, label .. " contains an unaudited field")
  end
end

local function cardId(value, label)
  label = label or "card ID"
  assert(type(value) == "number" and value % 1 == 0 and
    (value >= 1 or value <= -2), "invalid " .. label)
end

local function playerId(value, label)
  local id = type(value) == "table" and value.id or value
  assert(type(id) == "number" and id % 1 == 0, label .. " must be a player")
  return id
end

local function playerObject(room, value, label)
  local id = playerId(value, label)
  local player = room:getPlayerById(id)
  assert(player, label .. " player is missing")
  return player
end

local publicAreas = {
  PlayerEquip = true,
  PlayerJudge = true,
  Processing = true,
  DiscardPile = true,
  Void = true,
}

local function publicArea(area)
  for name in pairs(publicAreas) do
    if Card[name] ~= nil and Card[name] == area then return true end
  end
  return false
end

local function isAmazingGraceCard(room, id)
  if type(room.getTag) ~= "function" then return false end
  local record = room:getTag("AGrecord")
  if type(record) ~= "table" or #record == 0 then return false end
  local current = record[#record]
  if type(current) ~= "table" or type(current[2]) ~= "table" then return false end
  for _, card in ipairs(current[2]) do
    if card == id then return true end
  end
  return false
end

local function isPublic(room, seat, physical, id)
  -- FillAG deliberately reveals these cards before AskForAG runs. Preserve
  -- the public canonical reference so the AG model and request payload share
  -- one local identity even while the card is still in draw_pile.
  if isAmazingGraceCard(room, id) then return true end
  local area = room:getCardArea(id)
  if publicArea(area) then return true end
  if area == Card.PlayerHand then
    return physical == seat._splayer and room:getCardOwner(id) == seat
  end
  if area == Card.PlayerSpecial then
    local owner = room:getCardOwner(id)
    assert(owner and type(owner.getPileNameOfId) == "function",
      "private card owner is missing")
    local pile = owner:getPileNameOfId(id)
    assert(type(pile) == "string", "private card pile is missing")
    if pile:sub(1, 1) == "$" then
      return physical == seat._splayer and owner == seat
    end
    return true
  end
  -- The draw pile and any unknown area are never treated as public by a
  -- request projector.  A public request can still explicitly expose a card
  -- through a later audited MoveCards/ChangeCardArea notification.
  return false
end

local function addCard(ids, seen, id, label)
  cardId(id, label)
  if not seen[id] then
    seen[id] = true
    ids[#ids + 1] = id
  end
end

local function addCards(ids, seen, values, label)
  local count = dense(values, label)
  for i = 1, count do addCard(ids, seen, values[i], label .. " ID") end
end

local function allSeatCards(seat, ids, seen)
  addCards(ids, seen, seat:getCardIds("he"), "seat hand/equip")
  for _, pile in pairs(seat.special_cards or {}) do
    addCards(ids, seen, pile, "seat special pile")
  end
end

local function issue(room, seat, physical, batch, audience, requestKey, ids)
  local choices, standing = {}, {}
  for i, id in ipairs(ids) do
    local public = isPublic(room, seat, physical, id)
    standing[i] = batch:reference(audience, id, public)
    choices[i] = { id = id, public = public }
  end
  local tokens = batch:issueChoice(audience, requestKey, choices, 0, #ids)
  local byId, metadata = {}, {}
  for i, id in ipairs(ids) do
    local token = tokens[i]
    assert(type(token) == "string" and token:sub(1, 2) == "h:",
      "request choice token must be opaque")
    byId[id] = token
    metadata[i] = { token = token, standing = standing[i] }
  end
  return byId, metadata
end

local function projectCardArray(values, byId, label)
  local count = dense(values, label)
  local result = {}
  for i = 1, count do
    cardId(values[i], label .. " ID")
    assert(byId[values[i]], label .. " contains a card outside the request allowlist")
    result[i] = byId[values[i]]
  end
  return result
end

local function projectGroups(groups, byId, label)
  local count = dense(groups, label)
  local result = {}
  for i = 1, count do
    local group = groups[i]
    assert(type(group) == "table" and #group == 2 and
      type(group[1]) == "string", label .. " group is invalid")
    result[i] = { group[1], projectCardArray(group[2], byId, label .. " group") }
  end
  return result
end

local function projectVisible(value, byId, label)
  if value == nil then return nil end
  assert(type(value) == "table", label .. " must be a map")
  local result = {}
  for key, visible in pairs(value) do
    assert(type(key) == "string" and type(visible) == "boolean",
      label .. " has an invalid entry")
    local id = tonumber(key)
    assert(id and id % 1 == 0 and byId[id],
      label .. " references a card outside the request allowlist")
    result[tostring(byId[id])] = visible
  end
  return result
end

local cardArrayKeys = {
  cards = true,
  card_ids = true,
  subcards = true,
  visible_pile = true,
  expand_pile = true,
}

-- These fields are player-ID lists, not card-ID lists. Keep them as public
-- numeric identifiers in the request payload; treating them as card
-- references would either reject valid player-targeting skills or mint a
-- misleading card choice for the client.
local playerArrayKeys = {
  players = true,
  targets = true,
  fix_targets = true,
  must_targets = true,
  exclusive_targets = true,
  include_targets = true,
}

local cardScalarKeys = {
  card = true,
  cardId = true,
  card_id = true,
  effectCardId = true,
}

local safeNumberKeys = {
  to = true, from = true, target = true, source = true,
  effectFrom = true, effectTo = true, fix_user = true,
  useEventId = true, eventId = true, event = true,
  min = true, max = true, min_num = true, max_num = true,
  min_card_num = true, max_card_num = true,
  min_t_num = true, max_t_num = true,
  min_c_num = true, max_c_num = true,
  num = true, damage = true, times = true, n = true,
}

-- Exppattern's seventh pipe-separated matcher field is a list of physical
-- card IDs. Treat it as card data even though the outer request is a string.
-- Preserve all other matcher fields and grouping/negation syntax.
local function mapPatternIds(pattern, translate)
  assert(type(pattern) == "string", "request pattern must be a string")
  local matchers = {}
  for matcher in (pattern .. ";"):gmatch("(.-);") do
    local parts = {}
    for part in (matcher .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
    assert(#parts <= 7, "request pattern has unaudited matcher fields")
    if #parts == 7 and parts[7] ~= "." and parts[7] ~= "" then
      local mapped, groupDepth = {}, 0
      for rawPart in (parts[7] .. ","):gmatch("(.-),") do
        local part = rawPart
        local prefix, suffix = "", ""
        if part:sub(1, 2) == "^(" then
          prefix, part = "^(" , part:sub(3)
          groupDepth = groupDepth + 1
        elseif part:sub(1, 1) == "^" then
          prefix, part = "^", part:sub(2)
        end
        if part:sub(-1) == ")" then
          suffix, part = ")", part:sub(1, -2)
          groupDepth = groupDepth - 1
        end
        assert(groupDepth >= 0 and part:match("^%-?%d+$"),
          "request pattern contains an unaudited card ID")
        local id = tonumber(part)
        cardId(id, "request pattern card ID")
        mapped[#mapped + 1] = prefix .. translate(id) .. suffix
      end
      assert(groupDepth == 0, "request pattern has an unterminated ID group")
      parts[7] = table.concat(mapped, ",")
    end
    matchers[#matchers + 1] = table.concat(parts, "|")
  end
  return table.concat(matchers, ";")
end

local function isPlayerObject(value)
  return type(value) == "table" and type(value.id) == "number" and
    (value.player ~= nil or value.serverplayer ~= nil)
end

local function playerArray(value, key, room)
  local count = dense(value, key)
  local result = {}
  for i = 1, count do
    local item = value[i]
    local id = isPlayerObject(item) and item.id or item
    assert(type(id) == "number" and id % 1 == 0,
      key .. " must contain player IDs")
    if room and type(room.getPlayerById) == "function" then
      assert(room:getPlayerById(id), key .. " references an unknown player")
    end
    result[i] = item
  end
  return result
end

-- Extra data is skill-defined.  Admit the known non-card scalars and player
-- lists, project explicitly card-shaped fields, and reject unknown numeric
-- leaves.  A rejected request is preferable to guessing whether a number is
-- a hidden physical card ID.
local function collectExtra(value, key, ids, seen, room)
  if key == "pattern" and type(value) == "string" then
    mapPatternIds(value, function(id)
      addCard(ids, seen, id, "request pattern")
      return tostring(id)
    end)
    return
  end
  if value == nil or type(value) == "string" or type(value) == "boolean" then return end
  if type(value) == "number" then
    -- Upstream sets effectCardId to zero for a virtual effect card. Only
    -- physical card identities need choice tokens; zero carries no identity.
    if key == "effectCardId" and value == 0 then return end
    if cardScalarKeys[key] then addCard(ids, seen, value, key) return end
    assert(safeNumberKeys[key], "unaudited numeric request field: " .. tostring(key))
    return
  end
  if isPlayerObject(value) then return end
  assert(type(value) == "table", "unaudited request value: " .. tostring(key))
  if key == "visible_data" then
    for id in pairs(value) do
      local numeric = tonumber(id)
      assert(numeric and numeric % 1 == 0, "visible_data key must be a card ID")
      addCard(ids, seen, numeric, "visible_data")
    end
    return
  end
  if cardArrayKeys[key] then
    if type(value) == "table" then
      for index, item in ipairs(value) do
        if type(item) == "number" then
          addCard(ids, seen, item, key)
        elseif key == "expand_pile" or key == "visible_pile" then
          assert(type(item) == "string", key .. " contains an invalid value")
        else
          error(key .. " must contain card IDs")
        end
      end
    end
    return
  end
  if playerArrayKeys[key] then
    playerArray(value, key, room)
    return
  end
  for childKey, child in pairs(value) do
    assert(type(childKey) == "string" or type(childKey) == "number",
      "request map key must be scalar")
    collectExtra(child, type(childKey) == "string" and childKey or key,
      ids, seen, room)
  end
end

local function rewriteExtra(value, key, byId, seen, room)
  if key == "pattern" and type(value) == "string" then
    return mapPatternIds(value, function(id)
      assert(byId[id], "request pattern card is outside the request allowlist")
      return byId[id]
    end)
  end
  if value == nil or type(value) == "string" or type(value) == "boolean" then
    return value
  end
  if type(value) == "number" then
    if key == "effectCardId" and value == 0 then return 0 end
    if cardScalarKeys[key] then
      assert(byId[value], key .. " is outside the request allowlist")
      return byId[value]
    end
    return value
  end
  if isPlayerObject(value) then return value end
  assert(type(value) == "table", "unaudited request value: " .. tostring(key))
  if key == "visible_data" then return projectVisible(value, byId, key) end
  if playerArrayKeys[key] then return playerArray(value, key, room) end
  if cardArrayKeys[key] then
    if type(value) == "table" then
      local result = {}
      for i, item in ipairs(value) do
        if type(item) == "number" then
          assert(byId[item], key .. " is outside the request allowlist")
          result[i] = byId[item]
        else
          result[i] = item
        end
      end
      return result
    end
    return value
  end
  seen = seen or {}
  assert(not seen[value], "cyclic request payload")
  seen[value] = true
  local result = {}
  for childKey, child in pairs(value) do
    local childName = type(childKey) == "string" and childKey or key
    result[childKey] = rewriteExtra(child, childName, byId, seen, room)
  end
  seen[value] = nil
  return result
end

local function cloneAndRewrite(data, byId, room)
  local result = {}
  for key, value in pairs(data) do
    if key == 4 or key == 5 or key == "extra_data" then
      result[key] = rewriteExtra(value, "extra_data", byId, nil, room)
    else
      result[key] = copy(value)
    end
  end
  return result
end

local function envelope(payload, metadata)
  return { cardWireVersion = 1, payload = payload, choices = metadata }
end

local function simplePayload(data, label)
  assert(type(data) == "table", label .. " payload must be a table")
  return copy(data)
end

local function integer(value, label)
  assert(type(value) == "number" and value % 1 == 0,
    label .. " must be an integer")
  return value
end

local function stringArray(value, label)
  local count = dense(value, label)
  local result = {}
  for i = 1, count do
    assert(type(value[i]) == "string", label .. " must contain strings")
    result[i] = value[i]
  end
  return result
end

local function optionalString(value, label)
  if value == nil then return nil end
  assert(type(value) == "string", label .. " must be a string")
  return value
end

local function optionalBoolean(value, label)
  if value == nil then return nil end
  assert(type(value) == "boolean", label .. " must be a boolean")
  return value
end

local function projectCustomDialog(data)
  fields(data, { component = true }, "CustomDialog")
  local component = data.component
  assert(type(component) == "table", "CustomDialog component is required")

  -- This is the only initial-dialog schema that the upstream Hegemony AI and
  -- server validation understand. General names and kingdom names are public
  -- strings; arbitrary QML components remain fail-closed.
  if component.name == "ChooseInitialGeneralBox" then
    fields(component, { name = true, uri = true, model = true },
      "ChooseInitialGeneralBox component")
    assert(component.uri == "LunarLtk.Pages.Popups" and
      type(component.model) == "table", "initial-general component is invalid")
    local model = component.model
    fields(model, { name = true, uri = true, prop = true },
      "ChooseInitialGeneralBox model")
    assert(model.name == "ChooseInitialGeneralModel" and
      model.uri == "LunarLtk.Models.Popups" and type(model.prop) == "table",
      "initial-general model is invalid")
    local prop = model.prop
    fields(prop, {
      generals = true, choiceNum = true, lordGeneral = true,
      lordDeputy = true, selfRole = true, lordRole = true, hegemony = true,
      hideRole = true, convertDisabled = true, enabledKingdoms = true,
    }, "ChooseInitialGeneralBox properties")
    assert(prop.hegemony == true and integer(prop.choiceNum, "choiceNum") == 2,
      "only Hegemony initial-general choices are audited")
    local result = {
      generals = stringArray(prop.generals, "initial generals"),
      choiceNum = prop.choiceNum,
      hegemony = true,
    }
    result.enabledKingdoms = stringArray(prop.enabledKingdoms,
      "enabled kingdoms")
    for _, key in ipairs({ "lordGeneral", "lordDeputy", "selfRole", "lordRole" }) do
      local value = optionalString(prop[key], key)
      if value ~= nil then result[key] = value end
    end
    for _, key in ipairs({ "hideRole", "convertDisabled" }) do
      local value = optionalBoolean(prop[key], key)
      if value ~= nil then result[key] = value end
    end
    return {
      component = {
        name = component.name,
        uri = component.uri,
        model = {
          name = model.name,
          uri = model.uri,
          prop = result,
        },
      },
    }
  end

  -- The Hegemony watch-next-deputy dialog is a second exact schema. It only
  -- contains public general names and scalar UI controls; arbitrary custom
  -- dialogs are intentionally not admitted by the v1 projector.
  if component.url == "packages/hegemony/qml/KnownBothBox.qml" then
    fields(component, { url = true, model = true }, "KnownBothBox component")
    assert(type(component.model) == "table", "KnownBothBox model is required")
    local model = component.model
    fields(model, { url = true, prop = true }, "KnownBothBox model")
    assert(model.url == "packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml" and
      type(model.prop) == "table", "KnownBothBox model is invalid")
    local prop = model.prop
    fields(prop, {
      cards = true, all_cards = true, disable_cards = true, min = true,
      max = true, prompt = true, ok_options = true, cancel_options = true,
    }, "KnownBothBox properties")
    local minimum = integer(prop.min, "KnownBothBox min")
    local maximum = integer(prop.max, "KnownBothBox max")
    assert(minimum >= 0 and maximum >= minimum, "KnownBothBox limits are invalid")
    return {
      component = {
        url = component.url,
        model = {
          url = model.url,
          prop = {
            cards = stringArray(prop.cards, "KnownBothBox cards"),
            all_cards = stringArray(prop.all_cards, "KnownBothBox all_cards"),
            disable_cards = stringArray(prop.disable_cards, "KnownBothBox disabled cards"),
            min = minimum,
            max = maximum,
            prompt = optionalString(prop.prompt, "KnownBothBox prompt") or "",
            ok_options = stringArray(prop.ok_options, "KnownBothBox OK options"),
            cancel_options = stringArray(prop.cancel_options,
              "KnownBothBox cancel options"),
          },
        },
      },
    }
  end

  error("unaudited CustomDialog component")
end

local function splitComma(value, label)
  assert(type(value) == "string" and value ~= "", label .. " must be a string")
  local result = {}
  local start = 1
  while true do
    local comma = value:find(",", start, true)
    if not comma then
      result[#result + 1] = value:sub(start)
      break
    end
    result[#result + 1] = value:sub(start, comma - 1)
    start = comma + 1
  end
  for _, item in ipairs(result) do
    assert(item ~= "", label .. " contains an empty item")
  end
  return result
end

local function containsString(values, value)
  for _, item in ipairs(values) do
    if item == value then return true end
  end
  return false
end

local function resolveInitialGeneralDialog(originalData, reply)
  local projected = projectCustomDialog(originalData)
  local prop = projected.component.model.prop
  assert(type(reply) == "table" and dense(reply, "initial-general reply") == 2,
    "initial-general reply must contain two strings")
  local generals = splitComma(reply[1], "initial-general pair")
  assert(#generals == prop.choiceNum and generals[1] ~= generals[2],
    "initial-general pair cardinality is invalid")
  for _, general in ipairs(generals) do
    assert(containsString(prop.generals, general),
      "initial-general reply contains an unoffered general")
  end
  local kingdom = splitComma(reply[2], "initial kingdom choice")
  assert(#kingdom == 2 and kingdom[1] == "kingdom" and
    containsString(prop.enabledKingdoms, kingdom[2]),
    "initial kingdom choice is invalid")
  return { reply[1], reply[2] }
end

local function resolveKnownBothDialog(originalData, reply)
  local projected = projectCustomDialog(originalData)
  local prop = projected.component.model.prop
  assert(type(reply) == "table", "KnownBothBox reply must be a table")
  fields(reply, { cards = true, choice = true }, "KnownBothBox reply")
  local cards = stringArray(reply.cards, "KnownBothBox selected cards")
  assert(#cards >= prop.min and #cards <= prop.max,
    "KnownBothBox reply cardinality is invalid")
  local seen = {}
  for _, card in ipairs(cards) do
    assert(containsString(prop.cards, card) and not seen[card],
      "KnownBothBox reply contains an unoffered card")
    seen[card] = true
  end
  assert(type(reply.choice) == "string", "KnownBothBox choice is invalid")
  assert(containsString(prop.ok_options, reply.choice) or
    containsString(prop.cancel_options, reply.choice),
    "KnownBothBox choice is invalid")
  return { cards = cards, choice = reply.choice }
end

local function prepare(room, seat, physical, command, data, batch, requestKey)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "request projection requires negotiated Hegemony v1")
  assert(type(requestKey) == "string" and requestKey ~= "",
    "request key required")
  local audience = room:cardWireAudience(physical)

  -- Request is the upstream animation-delay marker. It has no user reply
  -- and no card-bearing payload, but still travels through the negotiated v1
  -- envelope so the client never has to decode a raw legacy packet.
  if command == "EmptyRequest" then
    assert(data == nil, "EmptyRequest must not carry a payload")
    return envelope({}, {})
  end

  local ids, seen = {}, {}
  local payload, kind

  if command == "AskForCardChosen" then
    assert(dense(data, command) == 4, command .. " expects four fields")
    local target = playerObject(room, data[1], "card-choice target")
    local flag = data[2]
    if type(flag) == "string" then
      for _, id in ipairs(target:getCardIds(flag)) do addCard(ids, seen, id, command) end
    else
      fields(flag, { card_data = true, visible_data = true }, command .. " flag")
      assert(type(flag.card_data) == "table", command .. " card_data required")
      for _, group in ipairs(flag.card_data) do addCards(ids, seen, group[2], command) end
    end
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    local projectedFlag
    if type(flag) == "string" then
      projectedFlag = flag
    else
      projectedFlag = {
        card_data = projectGroups(flag.card_data, byId, command),
        visible_data = projectVisible(flag.visible_data, byId, command),
      }
    end
    payload = { target, projectedFlag, data[3], data[4] }
    return envelope(payload, metadata)
  elseif command == "AskForPoxi" then
    fields(data, { type = true, data = true, extra_data = true, cancelable = true }, command)
    assert(type(data.type) == "string" and type(data.data) == "table",
      command .. " type/data required")
    for _, group in ipairs(data.data) do addCards(ids, seen, group[2], command) end
    collectExtra(data.extra_data, "extra_data", ids, seen, room)
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    local extra = data.extra_data and rewriteExtra(data.extra_data, "extra_data", byId, nil, room) or nil
    payload = {
      type = data.type,
      data = projectGroups(data.data, byId, command),
      extra_data = extra,
      cancelable = data.cancelable,
    }
    return envelope(payload, metadata)
  elseif command == "AskForAG" then
    assert(dense(data, command) == 3, command .. " expects three fields")
    addCards(ids, seen, data[1], command)
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    payload = copy(data)
    payload[1] = projectCardArray(data[1], byId, command)
    return envelope(payload, metadata)
  elseif command == "AskForCardsAndChoice" then
    fields(data, { cards = true, choices = true, prompt = true, cancel_choices = true,
      min = true, max = true, filter_skel = true, disabled = true, extra_data = true }, command)
    addCards(ids, seen, data.cards, command)
    if data.disabled then addCards(ids, seen, data.disabled, command) end
    collectExtra(data.extra_data, "extra_data", ids, seen, room)
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    payload = copy(data)
    payload.cards = projectCardArray(data.cards, byId, command)
    if data.disabled then payload.disabled = projectCardArray(data.disabled, byId, command) end
    payload.extra_data = data.extra_data and rewriteExtra(data.extra_data, "extra_data", byId, nil, room) or nil
    return envelope(payload, metadata)
  elseif command == "AskForArrangeCards" then
    fields(data, { cards = true, names = true, prompt = true, size = true,
      capacities = true, limits = true, is_free = true, pattern = true,
      poxi_type = true, cancelable = true }, command)
    local cardRows = dense(data.cards, command .. " rows")
    for i = 1, cardRows do addCards(ids, seen, data.cards[i], command) end
    if data.pattern then collectExtra(data.pattern, "pattern", ids, seen, room) end
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    payload = copy(data)
    if data.pattern then payload.pattern = rewriteExtra(data.pattern, "pattern", byId, nil, room) end
    payload.cards = {}
    for i = 1, cardRows do payload.cards[i] = projectCardArray(data.cards[i], byId, command) end
    return envelope(payload, metadata)
  elseif command == "AskForMoveCardInBoard" then
    fields(data, { cards = true, cardsPosition = true, playerIds = true }, command)
    addCards(ids, seen, data.cards, command)
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    payload = copy(data)
    payload.cards = projectCardArray(data.cards, byId, command)
    return envelope(payload, metadata)
  elseif command == "PlayCard" then
    -- The upstream PlayCard request has no payload.  The client already has
    -- the seat's local card aliases from MoveCards; only the request-scoped
    -- allowlist needs to be sent here.
    assert(data == nil, command .. " must not carry an unaudited payload")
    allSeatCards(seat, ids, seen)
    local _, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    return envelope({}, metadata)
  elseif command == "AskForUseActiveSkill" or command == "AskForUseCard" or
      command == "AskForResponseCard" then
    assert(dense(data, command) >= 4, command .. " payload is malformed")
    local extraIndex = command == "AskForUseActiveSkill" and 4 or 5
    collectExtra(data[extraIndex], "extra_data", ids, seen, room)
    allSeatCards(seat, ids, seen)
    local byId, metadata = issue(room, seat, physical, batch, audience, requestKey, ids)
    payload = cloneAndRewrite(data, byId, room)
    return envelope(payload, metadata)
  elseif command == "AskForChoices" or command == "AskForOptions" or
      command == "AskForSkillInvoke" then
    -- These requests carry no card identity. Keep their upstream payload but
    -- still pass through the v1 envelope so every Request has a known reply
    -- context and cannot silently fall back to a raw card ID.
    payload = simplePayload(data, command)
    return envelope(payload, {})
  elseif command == "CustomDialog" then
    return envelope(projectCustomDialog(data), {})
  end

  error("unaudited Hegemony v1 request: " .. tostring(command))
end

local function wireToken(value, label)
  assert(type(value) == "string" and value:sub(1, 2) == "h:" and
    value:sub(3):match("^[%w_-]+$") ~= nil, label .. " must be an opaque choice token")
  return value
end

local function resolveList(protocol, audience, requestKey, values, allowMinusOne)
  local count = dense(values, "reply card list")
  local tokens, positions = {}, {}
  for i = 1, count do
    if allowMinusOne and values[i] == -1 then
      positions[i] = -1
    else
      positions[i] = #tokens + 1
      tokens[#tokens + 1] = wireToken(values[i], "reply card reference")
    end
  end
  local resolved = protocol:resolveChoice(audience, requestKey, tokens, function() return true end)
  assert(resolved, "card-wire request reply was rejected")
  local result = {}
  for i = 1, count do
    result[i] = positions[i] == -1 and -1 or resolved[positions[i]]
  end
  return result
end

local function resolveUse(protocol, audience, requestKey, reply)
  assert(type(reply) == "table", "card-use reply must be a table")
  local result = copy(reply)
  local refs = {}
  local slots = {}
  if result.card ~= nil then
    if type(result.card) == "string" then
      refs[#refs + 1] = wireToken(result.card, "card-use reply")
      slots[#slots + 1] = { result, "card" }
    elseif type(result.card) == "table" then
      assert(result.card.card_objs == nil and result.card.id == nil,
        "card-use reply contains unaudited card metadata")
      if result.card.subcards ~= nil then
        local subcards = result.card.subcards
        local count = dense(subcards, "card-use subcards")
        for i = 1, count do
          refs[#refs + 1] = wireToken(subcards[i], "card-use subcard")
          slots[#slots + 1] = { subcards, i }
        end
      end
    else
      error("card-use reply card is malformed")
    end
  end
  assert(result.card_objs == nil, "card-use reply card objects are not audited")
  local resolved = protocol:resolveChoice(audience, requestKey, refs, function() return true end)
  assert(resolved, "card-use request reply was rejected")
  for i, slot in ipairs(slots) do slot[1][slot[2]] = resolved[i] end
  return result
end

local function allowedStringReply(data, reply, choicesIndex, limitsIndex)
  if reply == "" then return reply end
  assert(type(reply) == "table", "choice reply must be an array")
  local count = dense(reply, "choice reply")
  local choices = data[choicesIndex]
  assert(type(choices) == "table", "choice allowlist missing")
  local minimum, maximum = data[limitsIndex][1], data[limitsIndex][2]
  assert(count >= minimum and count <= maximum, "choice reply cardinality invalid")
  local seen = {}
  for i = 1, count do
    assert(type(reply[i]) == "string" and table.contains(choices, reply[i]),
      "choice reply contains an unaudited value")
    assert(not seen[reply[i]], "choice reply contains a duplicate value")
    seen[reply[i]] = true
  end
  return copy(reply)
end

function RequestWire.project(room, seat, physical, command, data, batch, requestKey)
  return prepare(room, seat, physical, command, data, batch, requestKey)
end

function RequestWire.resolve(room, seat, physical, command, reply, requestKey, originalData)
  assert(room.card_wire_version == 1 and
    room:getSettings("gameMode") == "new_heg_mode",
    "request resolution requires negotiated Hegemony v1")
  local audience = room:cardWireAudience(physical)
  local protocol = room._cardWireProtocol
  assert(protocol, "card-wire request protocol is missing")
  if reply == "" then return reply end
  if command == "AskForCardChosen" then
    local value = reply
    if value == "" then return value end
    local result = resolveList(protocol, audience, requestKey, { value }, false)
    return result[1]
  elseif command == "AskForPoxi" then
    return resolveList(protocol, audience, requestKey, reply, true)
  elseif command == "AskForAG" then
    return resolveList(protocol, audience, requestKey, { reply }, true)[1]
  elseif command == "AskForCardsAndChoice" then
    assert(type(reply) == "table", "cards-and-choice reply must be a table")
    local result = copy(reply)
    result.cards = resolveList(protocol, audience, requestKey, result.cards or {}, false)
    assert(type(result.choice) == "string", "cards-and-choice value is invalid")
    return result
  elseif command == "AskForArrangeCards" then
    assert(type(reply) == "table", "arrange reply must be an array")
    local flat, slots = {}, {}
    for row, values in ipairs(reply) do
      local count = dense(values, "arrange reply row")
      slots[row] = {}
      for column = 1, count do
        flat[#flat + 1] = wireToken(values[column], "arrange reply card")
        slots[row][column] = #flat
      end
    end
    local resolved = protocol:resolveChoice(audience, requestKey, flat, function() return true end)
    assert(resolved, "arrange request reply was rejected")
    local result = {}
    for row, values in ipairs(slots) do
      result[row] = {}
      for column, index in ipairs(values) do result[row][column] = resolved[index] end
    end
    return result
  elseif command == "AskForMoveCardInBoard" then
    assert(type(reply) == "table" and type(reply.cardId) ~= "nil" and
      type(reply.pos) == "number", "move-board reply is malformed")
    local result = copy(reply)
    result.cardId = resolveList(protocol, audience, requestKey, { result.cardId }, false)[1]
    return result
  elseif command == "PlayCard" or command == "AskForUseActiveSkill" or command == "AskForUseCard" or
      command == "AskForResponseCard" then
    return resolveUse(protocol, audience, requestKey, reply)
  elseif command == "AskForChoices" then
    return allowedStringReply(originalData, reply, 1, 3)
  elseif command == "AskForOptions" then
    return allowedStringReply(originalData, reply, 1, 3)
  elseif command == "AskForSkillInvoke" then
    assert(reply == "1" or reply == "__cancel", "skill invoke reply is invalid")
    return reply
  elseif command == "CustomDialog" then
    local component = originalData and originalData.component
    assert(type(component) == "table", "CustomDialog original payload is missing")
    if component.name == "ChooseInitialGeneralBox" then
      return resolveInitialGeneralDialog(originalData, reply)
    elseif component.url == "packages/hegemony/qml/KnownBothBox.qml" then
      return resolveKnownBothDialog(originalData, reply)
    end
    error("unaudited CustomDialog reply")
  end
  error("unaudited Hegemony v1 reply: " .. tostring(command))
end

return RequestWire
