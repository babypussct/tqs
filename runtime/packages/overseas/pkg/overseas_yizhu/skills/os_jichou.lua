local osJichou = fk.CreateSkill {
  name = "os__jichou"
}

Fk:loadTranslationTable{
  ["os__jichou"] = "急筹",
  [":os__jichou"] = "①每回合限一次，你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，" ..
  "且不可响应此牌名的牌。②出牌阶段限一次，你可将手牌中“急筹”使用过的其牌名的一张牌交给一名角色。",

  ["#os__jichou"] = "急筹：你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，且不可响应此牌名的牌",
  ["@$os__jichou"] = "急筹",

  ["$os__jichou1"] = "此危亡之时，当出此急谋。",
  ["$os__jichou2"] = "急筹布画，运策捭阖。",
}

osJichou:addEffect("viewas", {
  card_filter = Util.FalseFunc,
  card_num = 0,
  prompt = "#os__jichou",
  pattern = ".|.|.|.|.|trick",
  interaction = function(self, player)
    local allCardNames = Fk:getAllCardNames("t")
    local os__jichouRecord = player:getTableMark("@$os__jichou")
    local cardNames = table.filter(
      player:getViewAsCardNames(osJichou.name, allCardNames),
      function(name)
        return not table.contains(os__jichouRecord, name)
      end
    )

    return UI.ComboBox { choices = cardNames, all_choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = osJichou.name
    return c
  end,
  before_use = function(self, player, use)
    if player:hasSkill("os__jilun") then
      player.room:addTableMark(player, "@$os__jilun", use.card.name)
    end
  end,
  enabled_at_play = function(self, player)
    local os__jichouRecord = player:getTableMark("@$os__jichou")
    if player:usedSkillTimes(osJichou.name) > 0 then
      return false
    end

    local allCardNames = Fk:getAllCardNames("t")
    return table.find(
      player:getViewAsCardNames(osJichou.name, allCardNames),
      function(name)
        return not table.contains(os__jichouRecord, name)
      end
    )
  end,
  enabled_at_response = function(self, player)
    local os__jichouRecord = player:getTableMark("@$os__jichou")
    if player:usedSkillTimes(osJichou.name) > 0 then
      return false
    end

    local allCardNames = Fk:getAllCardNames("t")
    return table.find(
      player:getViewAsCardNames(osJichou.name, allCardNames),
      function(name)
        return not table.contains(os__jichouRecord, name)
      end
    )
  end,
})

osJichou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return
      table.contains(player:getCardIds("h"), card.id) and
      table.contains(player:getTableMark("@$os__jichou"), card.name)
  end,
})

osJichou:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@$os__jichou"), data.card.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player)
  end,
})

osJichou:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return player == target and table.contains(data.card.skillNames, "os__jichou")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@$os__jichou", data.card.name)
  end,
})

osJichou:addAcquireEffect(function(self, player)
  player.room:handleAddLoseSkills(player, "os__jichou_active&", nil, false, true)
end)

osJichou:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:handleAddLoseSkills(player, "-os__jichou_active&", nil, false, true)
  end
end)

return osJichou
