local kujian = fk.CreateSkill {
  name = "kujian",
}

Fk:loadTranslationTable{
  ["kujian"] = "苦谏",
  [":kujian"] = "出牌阶段限一次，你可将至多两张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，你与其各摸两张牌。" ..
  "当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。",

  ["#kujian-active"] = "你可发动“苦谏”，将至多两张手牌标记为“谏”并交给一名其他角色",
  ["#kujian-discard"] = "苦谏：请弃置一张牌",
  ["@@kujian-inhand"] = "谏",

  ["$kujian1"] = "吾之所言，皆为公之大业。",
  ["$kujian2"] = "公岂徒有纳谏之名乎！",
  ["$kujian3"] = "明公虽奕世克昌，未若有周之盛。",
}

kujian:addEffect("active", {
  prompt = "#kujian-active",
  mute = true,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 2
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = kujian.name
    local target = effect.tos[1]
    local player = effect.from
    room:notifySkillInvoked(player, skillName, "support", effect.tos)
    player:broadcastSkillInvoke(skillName, 1)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, skillName, nil, false, player, "@@kujian-inhand")
  end,
})

local kujianUseOrResponseRecordSpec = {
  can_refresh = function(self, event, target, player, data)
    return
      not (data.extra_data or {}).kujianIds and
      table.find(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@kujian-inhand") > 0
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.kujianIds = table.filter(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@kujian-inhand") > 0
    end)
  end,
}

kujian:addEffect(fk.PreCardUse, kujianUseOrResponseRecordSpec)

kujian:addEffect(fk.PreCardRespond, kujianUseOrResponseRecordSpec)

---@type TrigSkelSpec<UseCardFunc|RespondCardFunc>
local kujianUseOrResponseSpec = {
  mute = true,
  trigger_times = function(self, event, target, player, data)
    return
      type((data.extra_data or {}).kujianIds) == "table" and
      #table.filter(Card:getIdList(data.card), function(id)
        return table.contains(data.extra_data.kujianIds, id)
      end) or
      0
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kujian.name) and player ~= target
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = kujian.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "drawcard")
    player:broadcastSkillInvoke(skillName, 3)
    room:doIndicate(player, { target })

    local targets = { player, target }
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      p:drawCards(2, skillName)
    end
  end,
}

kujian:addEffect(fk.CardUsing, kujianUseOrResponseSpec)

kujian:addEffect(fk.CardResponding, kujianUseOrResponseSpec)

kujian:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
      not (data.extra_data or {}).kujianIds and
      table.find(data, function(move)
        return not not table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId):getMark("@@kujian-inhand") > 0
        end)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local kujianIds = {}
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId):getMark("@@kujian-inhand") > 0 then
          table.insert(kujianIds, info.cardId)
        end
      end
    end

    data.extra_data = data.extra_data or {}
    data.extra_data.kujianIds = kujianIds
  end,
})

kujian:addEffect(fk.AfterCardsMove, {
  mute = true,
  trigger_times = function(self, event, target, player, data)
    if type((data.extra_data or {}).kujianIds) ~= "table" then
      return 0
    end

    local kujianTargets = event:getSkillData(self, "kujian_" .. player.id)
    if kujianTargets then
      local unDoneTargets = table.simpleClone(kujianTargets.unDone)
      for _, to in ipairs(unDoneTargets) do
        if not to:isAlive() and not (player:isNude() and to:isNude()) then
          table.remove(kujianTargets.unDone, 1)
        else
          break
        end
      end

      return #kujianTargets.unDone + #kujianTargets.done
    end

    kujianTargets = { unDone = {}, done = {} }
    for _, move in ipairs(data) do
      if
        move.from and
        move.from ~= player and
        move.moveReason ~= fk.ReasonUse and
        move.moveReason ~= fk.ReasonResponse
      then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(data.extra_data.kujianIds, info.cardId) and info.fromArea == Card.PlayerHand then
            table.insert(kujianTargets.unDone, move.from)
          end
        end
      end
    end

    if #kujianTargets.unDone > 0 then
      player.room:sortByAction(kujianTargets.unDone)
      event:setSkillData(self, "kujian_" .. player.id, kujianTargets)
    end
    return #kujianTargets.unDone
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kujian.name)
  end,
  on_cost = function(self, event, target, player, data)
    local kujianTargets = event:getSkillData(self, "kujian_" .. player.id)
    local to = table.remove(kujianTargets.unDone, 1)
    table.insert(kujianTargets.done, to)
    event:setSkillData(self, "kujian_" .. player.id, kujianTargets)

    event:setCostData(self, to)
    return true
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = kujian.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "negative")
    player:broadcastSkillInvoke(skillName, 2)
    local to = event:getCostData(self)
    room:doIndicate(player, { to })

    local targets = { player, to }
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      room:askToDiscard(
        p,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
          prompt = "#kujian-discard",
        }
      )
    end
  end,
})

return kujian
