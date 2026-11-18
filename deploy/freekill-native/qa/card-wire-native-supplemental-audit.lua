-- Audit the v1 channels that are not covered by the deck/snapshot auditor.
--
-- This program is intentionally independent of the browser decoder.  The
-- runner gives it one complete outer CBOR packet captured before
-- PacketStream.  It decodes only the audited envelope/field shapes and emits
-- bounded channel metadata; it never prints payloads, card references,
-- account names, or decoder errors.
local core, mode, audience, physicalSeat, direction, replyCommand = ...
local supplementalCommands = {
  CardWireNegotiated = "negotiation",
  PropertyUpdate = "metadata", SetPlayerMark = "metadata", SetCardMark = "metadata",
  SetCardFootnote = "metadata", SetCardVirtName = "metadata", FilterCard = "metadata",
  FillAG = "metadata", TakeAG = "metadata", SetPlayerHandCards = "metadata",
  AddVirtualEquip = "metadata", RemoveVirtualEquip = "metadata",
  ShowVirtualCard = "public", GameLog = "public", ShowCard = "public", GameOver = "public",
  AskForCardChosen = "request", AskForPoxi = "request", AskForAG = "request",
  AskForCardsAndChoice = "request", AskForArrangeCards = "request",
  AskForMoveCardInBoard = "request", PlayCard = "request",
  AskForUseActiveSkill = "request", AskForUseCard = "request",
  AskForResponseCard = "request", AskForChoices = "request", AskForOptions = "request",
  AskForSkillInvoke = "request", CustomDialog = "request", EmptyRequest = "request",
}
local replyCommands = {
  AskForCardChosen = true, AskForPoxi = true, AskForAG = true,
  AskForCardsAndChoice = true, AskForArrangeCards = true,
  AskForMoveCardInBoard = true, PlayCard = true,
  AskForUseActiveSkill = true, AskForUseCard = true,
  AskForResponseCard = true, AskForChoices = true, AskForOptions = true,
  AskForSkillInvoke = true, CustomDialog = true, EmptyRequest = true,
}

local function fields(value, allowed)
  assert(type(value) == "table")
  for key in pairs(value) do
    assert(allowed[key] == true)
  end
end

local function integer(value)
  assert(type(value) == "number" and value == value and
    value ~= math.huge and value ~= -math.huge and value % 1 == 0)
  return value
end

-- The upstream Player:__tocbor contract emits a semantic Player reference,
-- not a serialized player table.  This standalone auditor intentionally does
-- not load the runtime's tagged decoder, so cbor.decode returns the exact
-- representation { tag = 33001, value = player id }.  Keep this schema exact:
-- accepting id/name/class fields here would allow an identity-bearing object
-- to cross the audit boundary unnoticed.
local CBOR_TAG_PLAYER = 33001
local function playerReference(value)
  fields(value, { tag = true, value = true })
  assert(value.tag == CBOR_TAG_PLAYER)
  integer(value.value)
  assert(value.value ~= 0)
end

local function scalar(value)
  local kind = type(value)
  assert(kind == "boolean" or kind == "string" or
    (kind == "number" and value == value and
      value ~= math.huge and value ~= -math.huge))
end

local function dense(value, maximum)
  assert(type(value) == "table")
  local count, max = 0, 0
  for key in pairs(value) do
    assert(type(key) == "number" and key % 1 == 0 and key >= 1)
    count = count + 1
    if key > max then max = key end
  end
  assert(count == max and count <= (maximum or 8192))
  return count
end

local function opaque(value)
  assert(type(value) == "string" and #value >= 18 and #value <= 128 and
    value:match("^h:[%w_-]+$") ~= nil)
end

local function wireRef(value, allowUnknown)
  if type(value) == "string" then
    opaque(value)
    return
  end
  integer(value)
  assert(value ~= 0 and (value >= 1 or value <= -2 or (allowUnknown and value == -1)))
end

local function refArray(value, allowUnknown)
  local count = dense(value)
  for i = 1, count do wireRef(value[i], allowUnknown) end
end

local function tokenArray(value)
  local count = dense(value)
  for i = 1, count do opaque(value[i]) end
end

local function stringArray(value)
  local count = dense(value)
  for i = 1, count do assert(type(value[i]) == "string") end
end

local function numberArray(value)
  local count = dense(value)
  for i = 1, count do integer(value[i]) end
end

local yiguiExtraDataPlayerArrays = {
  must_targets = true, include_targets = true, exclusive_targets = true,
  fix_targets = true,
}
local yiguiExtraDataBooleans = {
  bypass_distances = true, bypass_times = true, extraUse = true,
  not_passive = true, playing = true,
}

local function yiguiExtraData(value)
  fields(value, {
    must_targets = true, include_targets = true, exclusive_targets = true,
    fix_targets = true, fix_user = true, bypass_distances = true,
    bypass_times = true, extraUse = true, not_passive = true, playing = true,
  })
  for key, item in pairs(value) do
    if yiguiExtraDataPlayerArrays[key] then
      local count = dense(item)
      for i = 1, count do
        integer(item[i]); assert(item[i] > 0)
      end
    elseif key == "fix_user" then
      integer(item); assert(item > 0)
    else
      assert(yiguiExtraDataBooleans[key] and type(item) == "boolean")
    end
  end
end

local function envelope(value, choicesAllowed)
  assert(type(value) == "table")
  if choicesAllowed then
    fields(value, { cardWireVersion = true, payload = true, choices = true })
  else
    fields(value, { cardWireVersion = true, payload = true })
  end
  assert(value.cardWireVersion == 1)
  assert(value.payload ~= nil)
  return value.payload
end

local function cardDescriptor(value)
  assert(type(value) == "table")
  fields(value, { cardWireCard = true, kind = true, ref = true, name = true,
    suit = true, number = true, color = true, subcards = true,
    skillNames = true, virt_id = true, mark = true })
  assert(value.cardWireCard == 1 and (value.kind == "real" or value.kind == "virtual"))
  if value.kind == "real" then
    fields(value, { cardWireCard = true, kind = true, ref = true })
    wireRef(value.ref, false)
    return
  end
  assert(type(value.name) == "string" and value.name ~= "")
  integer(value.suit); integer(value.number); integer(value.color); integer(value.virt_id)
  refArray(value.subcards or {}, false)
  stringArray(value.skillNames or {})
  if value.mark ~= nil then
    assert(type(value.mark) == "table")
    for key, item in pairs(value.mark) do
      assert(type(key) == "string" and key:sub(1, 1) == "@")
      scalar(item)
    end
  end
end

local function cardValue(value)
  if type(value) == "table" then cardDescriptor(value)
  else wireRef(value, true) end
end

local function cardValueArray(value)
  local count = dense(value)
  for i = 1, count do cardValue(value[i]) end
end

local function cardGroups(value)
  local count = dense(value)
  for i = 1, count do
    assert(type(value[i]) == "table" and #value[i] == 2 and type(value[i][1]) == "string")
    tokenArray(value[i][2])
  end
end

local function logValue(value, allowCards)
  if type(value) == "table" then
    assert(allowCards == true)
    cardDescriptor(value)
  else scalar(value) end
end

local function logPayload(value, allowCards)
  fields(value, { type = true, from = true, to = true, card = true, toast = true,
    arg = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true,
    arg6 = true, arg7 = true, arg8 = true, arg9 = true })
  assert(type(value.type) == "string" and value.type ~= "")
  if value.from ~= nil then integer(value.from) end
  if value.to ~= nil then numberArray(value.to) end
  if value.card ~= nil then assert(allowCards == true); cardValueArray(value.card) end
  if value.toast ~= nil then assert(type(value.toast) == "boolean") end
  for _, key in ipairs({ "arg", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9" }) do
    if value[key] ~= nil then logValue(value[key], allowCards) end
  end
end

local function metadata(command, value)
  if command == "PropertyUpdate" then
    local count = dense(value); assert(count == 2 or count == 3)
    integer(value[1]); assert(type(value[2]) == "string")
    local key, item = value[2], value[3]
    assert(item ~= nil or key == "state" or key == "MaxCards")
    local scalarKeys = {
      hp = true, maxHp = true, shield = true, MaxCards = true, dying = true,
      dead = true, drank = true, rest = true, chained = true, faceup = true,
      phase = true, state = true, surrendered = true, role_shown = true,
      role = true, general = true, deputyGeneral = true, kingdom = true, gender = true,
    }
    assert(scalarKeys[key] or key == "sealedSlots" or key == "equipSlots")
    if key == "sealedSlots" or key == "equipSlots" then numberArray(item)
    else scalar(item) end
  elseif command == "SetPlayerMark" then
    assert(dense(value) == 3); integer(value[1]); assert(type(value[2]) == "string")
    local item = value[3]
    if type(item) == "table" then
      -- Only the explicit player/general/skill mark families are allowed to
      -- be compound.  No arbitrary numeric card list is accepted here.
      local mark = value[2]
      if mark == "ld__yigui_extra_data" then
        yiguiExtraData(item)
        goto set_player_mark_done
      end
      assert(mark == "InitialGeneral" or mark == "ExtraAttachedSkills" or
        mark == "@hs__luanji-turn" or mark == "xiongsuan-turn" or
        mark == "@jilei-turn" or
        mark:sub(1, 13) == "InvalidSkills" or mark:sub(1, 2) == "@&" or
        mark == "RevealProhibited" or mark:sub(1, 16) == "RevealProhibited-" or
        mark == "reveal_intention-turn" or mark == "gouni" or
        mark == "@@heg__fengguo" or mark == "@@ld__congcha" or
        mark == "ld__jinxian_targets-turn" or mark == "ofl_heg__xionghuo-turn" or
        mark == "ofl_heg__xionghuo_prohibit-turn" or mark == "@@nos_heg__zhidao-turn" or
        mark == "m_heg__fenxun-turn" or mark == "fenxun-turn" or
        mark == "sanchen-turn" or mark == "@@ofl_heg__dianhu" or mark == "ofl_heg__dianhu")
      local count = dense(item)
      for i = 1, count do
        assert(type(item[i]) == "string" or type(item[i]) == "number" or type(item[i]) == "table")
        if type(item[i]) == "table" then
          playerReference(item[i])
        end
      end
    else scalar(item) end
    ::set_player_mark_done::
  elseif command == "SetCardMark" then
    assert(dense(value) == 3); wireRef(value[1], false)
    assert(type(value[2]) == "string" and value[2] ~= ""); scalar(value[3])
  elseif command == "SetCardFootnote" or command == "SetCardVirtName" then
    local count = dense(value); assert(count == 3); refArray(value[1], false)
    if command == "SetCardFootnote" then logPayload(value[2])
    else assert(type(value[2]) == "string" and value[2] ~= "") end
    assert(type(value[3]) == "boolean")
  elseif command == "FilterCard" then
    assert(dense(value) >= 1 and dense(value) <= 3); wireRef(value[1], true)
    if value[2] ~= nil then integer(value[2]) end
    if value[3] ~= nil then assert(type(value[3]) == "boolean") end
  elseif command == "FillAG" then
    local count = dense(value); assert(count == 1 or count == 2); refArray(value[1], false)
    if value[2] ~= nil then refArray(value[2], false) end
  elseif command == "TakeAG" then
    assert(dense(value) == 2); integer(value[1]); wireRef(value[2], false)
  elseif command == "SetPlayerHandCards" then
    assert(dense(value) == 2); integer(value[1]); refArray(value[2], false)
  elseif command == "AddVirtualEquip" then
    fields(value, { player = true, name = true, subcards = true }); integer(value.player)
    assert(type(value.name) == "string" and value.name ~= ""); refArray(value.subcards, false)
  elseif command == "RemoveVirtualEquip" then
    fields(value, { player = true, id = true }); integer(value.player); wireRef(value.id, false)
  else error("unknown metadata channel") end
end

local function public(command, value)
  if command == "ShowVirtualCard" then
    assert(type(value) == "table" and value.cardWireVersion == 1)
    local payload = envelope(value, false)
    assert(type(payload) == "table"); local count = dense(payload[1]); assert(count > 0)
    for i = 1, count do cardDescriptor(payload[1][i]) end
    if payload[2] ~= nil then integer(payload[2]) end
    if payload[3] ~= nil then logPayload(payload[3], true) end
    integer(payload[4])
  elseif command == "GameLog" then
    local hasEnvelope = type(value) == "table" and value.cardWireVersion == 1
    logPayload(hasEnvelope and envelope(value, false) or value, hasEnvelope)
  elseif command == "ShowCard" then
    assert(dense(value) == 3); refArray(value[1], false)
    if value[2] ~= nil then integer(value[2]) end; integer(value[3])
  elseif command == "GameOver" then
    assert(type(value) == "string")
    if value ~= "" then
      for id in value:gmatch("[^+]+") do assert(id:match("^[1-9][0-9]*$") ~= nil) end
    end
  else error("unknown public channel") end
end

local function choices(value)
  local count = dense(value or {})
  for i = 1, count do
    local entry = value[i]
    fields(entry, { token = true, standing = true })
    opaque(entry.token); wireRef(entry.standing, false)
  end
end

local cardArrayKeys = { cards = true, card_ids = true, subcards = true,
  visible_pile = true, expand_pile = true, disabled = true }
local playerArrayKeys = {
  players = true, targets = true, fix_targets = true, must_targets = true,
  exclusive_targets = true, include_targets = true,
}
local cardScalarKeys = { card = true, cardId = true, card_id = true, effectCardId = true }
local safeNumberKeys = {
  to = true, from = true, target = true, source = true, effectFrom = true,
  effectTo = true, fix_user = true, useEventId = true, eventId = true, event = true,
  min = true, max = true, min_num = true, max_num = true, min_card_num = true,
  max_card_num = true, min_t_num = true, max_t_num = true,
  min_c_num = true, max_c_num = true, num = true,
  damage = true, times = true, n = true, choiceNum = true, generalNum = true,
  index = true, size = true, capacity = true, total = true,
}

local function pattern(value)
  assert(type(value) == "string")
  for matcher in (value .. ";"):gmatch("(.-);") do
    local index = 0
    for part in (matcher .. "|"):gmatch("(.-)|") do
      index = index + 1
      if index == 7 and part ~= "." and part ~= "" then
        for item in (part .. ","):gmatch("(.-),") do
          item = item:gsub("^[%^]?%(", ""):gsub("%)$", "")
          opaque(item)
        end
      end
    end
    assert(index <= 7)
  end
end

local function requestExtra(value, key, seen)
  local kind = type(value)
  if value == nil or kind == "boolean" then return end
  if kind == "string" then
    if key == "pattern" then pattern(value)
    elseif cardScalarKeys[key] then opaque(value) end
    return
  end
  if kind == "number" then
    if cardScalarKeys[key] then assert(key == "effectCardId" and value == 0) else
      assert(safeNumberKeys[key]) end
    return
  end
  assert(kind == "table")
  if key == "visible_data" then
    for entry, visible in pairs(value) do opaque(entry); assert(type(visible) == "boolean") end
    return
  end
  if playerArrayKeys[key] then
    local count = dense(value)
    for i = 1, count do integer(value[i]) end
    return
  end
  if cardArrayKeys[key] then
    local count = dense(value)
    for i = 1, count do assert(type(value[i]) == "string"); opaque(value[i]) end
    return
  end
  seen = seen or {}; assert(not seen[value]); seen[value] = true
  for childKey, child in pairs(value) do
    assert(type(childKey) == "string" or type(childKey) == "number")
    requestExtra(child, type(childKey) == "string" and childKey or key, seen)
  end
  seen[value] = nil
end

-- CustomDialog is an explicitly public UI channel.  Its two admitted
-- Hegemony schemas carry general names in fields named `cards`; those are
-- not card-wire references and must not be passed through the generic card
-- token walker above.  Keep this exact mirror of the server projector so the
-- raw-packet audit remains fail-closed without confusing public general IDs
-- with hidden card IDs.
local function customDialog(value)
  assert(type(value) == "table")
  fields(value, { component = true })
  local component = value.component
  assert(type(component) == "table")
  if component.name == "ChooseInitialGeneralBox" then
    fields(component, { name = true, uri = true, model = true })
    assert(component.uri == "LunarLtk.Pages.Popups" and type(component.model) == "table")
    local model = component.model
    fields(model, { name = true, uri = true, prop = true })
    assert(model.name == "ChooseInitialGeneralModel" and
      model.uri == "LunarLtk.Models.Popups" and type(model.prop) == "table")
    local prop = model.prop
    fields(prop, {
      generals = true, choiceNum = true, hegemony = true,
      enabledKingdoms = true, lordGeneral = true, lordDeputy = true,
      selfRole = true, lordRole = true, hideRole = true, convertDisabled = true,
    })
    assert(prop.hegemony == true)
    integer(prop.choiceNum); assert(prop.choiceNum == 2)
    stringArray(prop.generals); stringArray(prop.enabledKingdoms)
    for _, key in ipairs({ "lordGeneral", "lordDeputy", "selfRole", "lordRole" }) do
      if prop[key] ~= nil then assert(type(prop[key]) == "string") end
    end
    for _, key in ipairs({ "hideRole", "convertDisabled" }) do
      if prop[key] ~= nil then assert(type(prop[key]) == "boolean") end
    end
    return
  end
  if component.url == "packages/hegemony/qml/KnownBothBox.qml" then
    fields(component, { url = true, model = true })
    assert(type(component.model) == "table")
    local model = component.model
    fields(model, { url = true, prop = true })
    assert(model.url == "packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml" and
      type(model.prop) == "table")
    local prop = model.prop
    fields(prop, {
      cards = true, all_cards = true, disable_cards = true, min = true, max = true,
      prompt = true, ok_options = true, cancel_options = true,
    })
    stringArray(prop.cards); stringArray(prop.all_cards); stringArray(prop.disable_cards)
    integer(prop.min); integer(prop.max); assert(prop.min >= 0 and prop.max >= prop.min)
    assert(type(prop.prompt) == "string")
    stringArray(prop.ok_options); stringArray(prop.cancel_options)
    return
  end
  error("unaudited CustomDialog component")
end

local function customDialogReply(value)
  assert(type(value) == "table")
  if value[1] ~= nil then
    assert(dense(value) == 2)
    assert(type(value[1]) == "string" and type(value[2]) == "string")
    return
  end
  fields(value, { cards = true, choice = true })
  stringArray(value.cards)
  assert(type(value.choice) == "string")
end

local function choiceRequest(command, value)
  local count = dense(value)
  if command == "AskForChoices" then
    assert(count == 8)
    stringArray(value[1]); stringArray(value[2])
    assert(dense(value[3]) == 2); integer(value[3][1]); integer(value[3][2])
    assert(value[3][1] >= 0 and value[3][2] >= value[3][1])
    assert(type(value[4]) == "boolean" and type(value[5]) == "string" and
      type(value[6]) == "string" and type(value[7]) == "boolean" and
      type(value[8]) == "boolean")
  elseif command == "AskForOptions" then
    assert(count == 7)
    stringArray(value[1]); stringArray(value[2])
    assert(dense(value[3]) == 2); integer(value[3][1]); integer(value[3][2])
    assert(value[3][1] >= 0 and value[3][2] >= value[3][1])
    assert(type(value[4]) == "boolean" and type(value[5]) == "string" and
      type(value[6]) == "string" and type(value[7]) == "boolean")
  else
    assert(command == "AskForSkillInvoke" and (count == 1 or count == 2))
    assert(type(value[1]) == "string")
    if value[2] ~= nil then assert(type(value[2]) == "string") end
  end
end

local function request(command, value)
  local payload = value
  local hasEnvelope = type(value) == "table" and value.cardWireVersion ~= nil
  if hasEnvelope then
    payload = envelope(value, true)
    choices(value.choices)
  else
    assert(command == "AskForChoices" or command == "AskForOptions" or
      command == "AskForSkillInvoke" or command == "CustomDialog" or command == "EmptyRequest")
  end
  assert(type(payload) == "table")
  if command == "AskForCardChosen" then
    if payload[2] ~= nil then
      if type(payload[2]) == "string" then
        assert(payload[2] ~= "")
      else
        fields(payload[2], { card_data = true, visible_data = true })
        if payload[2].card_data ~= nil then
          cardGroups(payload[2].card_data)
          for i = 1, dense(payload[2].card_data) do
            for j = 1, dense(payload[2].card_data[i][2]) do opaque(payload[2].card_data[i][2][j]) end
          end
        end
        if payload[2].visible_data ~= nil then
          for ref, visible in pairs(payload[2].visible_data) do opaque(ref); assert(type(visible) == "boolean") end
        end
      end
    end
  elseif command == "AskForAG" then
    tokenArray(payload[1])
  elseif command == "AskForPoxi" then
    cardGroups(payload.data)
    requestExtra(payload.extra_data, "extra_data")
  elseif command == "AskForCardsAndChoice" then
    tokenArray(payload.cards); if payload.disabled ~= nil then tokenArray(payload.disabled) end
    requestExtra(payload.extra_data, "extra_data")
  elseif command == "AskForArrangeCards" then
    local n = dense(payload.cards)
    for i = 1, n do tokenArray(payload.cards[i]) end
    if payload.pattern then pattern(payload.pattern) end
  elseif command == "AskForMoveCardInBoard" then
    tokenArray(payload.cards)
  elseif command == "PlayCard" or command == "AskForUseActiveSkill" or
      command == "AskForUseCard" or command == "AskForResponseCard" then
    local index = command == "AskForUseActiveSkill" and 4 or 5
    requestExtra(payload[index], "extra_data")
  elseif command == "AskForChoices" or command == "AskForOptions" or
      command == "AskForSkillInvoke" or command == "CustomDialog" or command == "EmptyRequest" then
    if command == "AskForChoices" or command == "AskForOptions" or
        command == "AskForSkillInvoke" then
      choiceRequest(command, payload)
    elseif command == "CustomDialog" then
      customDialog(payload)
    else
      requestExtra(payload, "payload")
    end
  else error("unknown request channel") end
end

local function reply(command, value)
  if value == "" or value == "__cancel" then return end
  if command == "AskForCardChosen" or command == "AskForAG" then
    assert(value == -1 or type(value) == "string"); if type(value) == "string" then opaque(value) end
  elseif command == "AskForPoxi" then
    local n = dense(value); for i = 1, n do assert(value[i] == -1 or type(value[i]) == "string"); if value[i] ~= -1 then opaque(value[i]) end end
  elseif command == "AskForCardsAndChoice" then
    fields(value, { cards = true, choice = true }); tokenArray(value.cards); assert(type(value.choice) == "string")
  elseif command == "AskForArrangeCards" then
    local n = dense(value); for i = 1, n do tokenArray(value[i]) end
  elseif command == "AskForMoveCardInBoard" then
    fields(value, { cardId = true }); assert(type(value.cardId) == "string"); opaque(value.cardId)
  elseif command == "PlayCard" or command == "AskForUseActiveSkill" or
      command == "AskForUseCard" or command == "AskForResponseCard" then
    assert(type(value) == "table"); assert(value.card_objs == nil)
    if value.card ~= nil then
      if type(value.card) == "string" then opaque(value.card)
      else
        assert(type(value.card) == "table"); assert(value.card.id == nil and value.card.card_objs == nil)
        if value.card.subcards ~= nil then tokenArray(value.card.subcards) end
      end
    end
  else
    assert(command == "AskForChoices" or command == "AskForOptions" or
      command == "AskForSkillInvoke" or command == "CustomDialog" or command == "EmptyRequest")
    if command == "CustomDialog" then customDialogReply(value)
    else requestExtra(value, "reply") end
  end
end

local function rawPacket(cbor, hex)
  assert(type(hex) == "string" and #hex <= 16 * 1024 * 1024 and #hex % 2 == 0 and
    not hex:find("[^a-f0-9]"))
  local raw = hex:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end)
  local packet = cbor.decode(raw)
  assert(type(packet) == "table" and (#packet == 4 or #packet == 6))
  assert(type(packet[1]) == "number" and type(packet[2]) == "number")
  assert(math.floor(packet[2] / 4096) % 2 == 0)
  assert(type(packet[3]) == "string" and #packet[3] <= 256 and type(packet[4]) == "string")
  if direction == "outgoing" then
    assert(packet[3] == "" and math.floor(packet[2] / 512) % 2 == 1)
    assert(replyCommands[replyCommand])
    return replyCommand, packet[4]
  end
  assert(packet[3] ~= "")
  assert(supplementalCommands[packet[3]] ~= nil)
  return packet[3], packet[4]
end

if core == "--self-test" then return supplementalCommands end
local ok, channel = pcall(function()
  assert(core and mode == "--raw-packet" and
    (audience == "player" or audience == "observer") and
    (direction == "incoming" or direction == "outgoing"))
  local cbor = assert(dofile(core .. "/lua/server/rpc/cbor.lua"))
  local command, encoded = rawPacket(cbor, io.read("*a"))
  local decoded = cbor.decode(encoded)
  if direction == "outgoing" then reply(command, decoded)
  elseif command == "CardWireNegotiated" then
    fields(decoded, { protocol = true, cardWireVersion = true, mode = true })
    assert(decoded.protocol == "TQS_HEG_CARD_WIRE" and decoded.cardWireVersion == 1 and decoded.mode == "new_heg_mode")
  elseif supplementalCommands[command] == "metadata" then
    local metadataEnvelopeCommands = {
      SetCardFootnote = true, SetCardVirtName = true, FilterCard = true,
      FillAG = true, TakeAG = true, SetPlayerHandCards = true,
      AddVirtualEquip = true, RemoveVirtualEquip = true,
    }
    metadata(command, metadataEnvelopeCommands[command] and envelope(decoded, false) or decoded)
  elseif supplementalCommands[command] == "public" then public(command, decoded)
  elseif supplementalCommands[command] == "request" then request(command, decoded)
  else error("unsupported supplemental channel") end
  return direction == "outgoing" and "reply" or supplementalCommands[command]
end)
if not ok or not channel then
  local failureLine = type(channel) == "string" and channel:match(":(%d+):") or nil
  io.stderr:write("native supplemental privacy audit rejected packet; failureLine=" ..
    (failureLine or "unknown") .. "\n"); os.exit(2)
end
print("PASS;channel=" .. channel .. ";observed=1")
