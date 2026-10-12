local osWushen = fk.CreateSkill {
  name = "os__wushen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__wushen"] = "武神",
  [":os__wushen"] = "锁定技，你的<font color='red'>♥</font>手牌视为【杀】。你使用<font color='red'>♥</font>【杀】无距离和次数限制、不计入次数且" ..
  "额外选择所有有“梦魇”的角色为目标。你于每个阶段内使用的第一张【杀】不能被响应。",

  ["@os__nightmare"] = "梦魇",

  ["$os__wushen1"] = "生当啖汝之肉！",
  ["$os__wushen2"] = "死当追汝之魂！"
}

osWushen:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return
      player:hasSkill(osWushen.name) and
      card.suit == Card.Heart and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local slash = Fk:cloneCard("slash", Card.Heart, card.number)
    slash.skillName = osWushen.name
    return slash
  end,
})

osWushen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return
      player:hasSkill(osWushen.name) and
      card and
      card.trueName == "slash" and
      card.suit == Card.Heart and
      scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill, card)
    return
      player:hasSkill(osWushen.name) and
      card and
      card.trueName == "slash" and
      card.suit == Card.Heart
  end,
})

osWushen:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osWushen.name) and data.card.trueName == "slash" then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == player and use.card.trueName == "slash"
      end, Player.HistoryPhase)
      return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.players) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

osWushen:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osWushen.name) and data.card.trueName == "slash" and data.card.suit == Card.Heart then
      local availableTargets = data:getExtraTargets({ bypass_times = true })
      if #availableTargets > 0 then
        return table.find(availableTargets, function(p) return p:getMark("@os__nightmare") > 0 end)
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local targets = data:getExtraTargets({ bypass_times = true })
    if #targets == 0 then
      return false
    end

    for _, p in ipairs(targets) do
      if p:getMark("@os__nightmare") > 0 then
        data:addTarget(p)
      end
    end
  end,
})

osWushen:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(osWushen.name) and data.card.trueName == "slash" and data.card.suit == Card.Heart
  end,
  on_use = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

return osWushen
