local jichou = fk.CreateSkill {
  name = "jichou"
}

Fk:loadTranslationTable{
  ["jichou"] = "急筹",
  [":jichou"] = "每回合限一次，你可以视为使用一张未被记录的普通锦囊牌并记录此牌名；你不能使用已记录牌名的非虚拟牌，且不能响应已记录牌名的牌；" ..
  "出牌阶段限一次，你可将至少一张已记录牌名的牌交给一名其他角色。",

  ["#jichou"] = "急筹：你可视为使用一种普通锦囊牌，然后本局你无法使用此牌名的非虚拟牌，且不可响应此牌名的牌",
  ["@$jichou"] = "急筹",

  ["$jichou1"] = "事急从权，待吾稍作思量。",
  ["$jichou2"] = "此危亡之时，当出此急谋。",
}

jichou:addEffect("viewas", {
  card_filter = Util.FalseFunc,
  card_num = 0,
  prompt = "#jichou",
  pattern = ".|.|.|.|.|trick",
  interaction = function(self, player)
    local allCardNames = Fk:getAllCardNames("t")
    local jichouRecord = player:getTableMark("@$jichou")
    local cardNames = table.filter(
      player:getViewAsCardNames(jichou.name, allCardNames),
      function(name)
        return not table.contains(jichouRecord, name)
      end
    )

    return UI.CardNameBox { choices = cardNames, all_choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = jichou.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "@$jichou", use.card.name)
    room:addTableMark(player, "jilun_record", use.card.name)
  end,
  enabled_at_play = function(self, player)
    local jichouRecord = player:getTableMark("@$jichou")
    if player:usedSkillTimes(jichou.name) > 0 then
      return false
    end

    local allCardNames = Fk:getAllCardNames("t")
    return table.find(
      player:getViewAsCardNames(jichou.name, allCardNames),
      function(name)
        return not table.contains(jichouRecord, name)
      end
    )
  end,
  enabled_at_response = function(self, player)
    local jichouRecord = player:getTableMark("@$jichou")
    if player:usedSkillTimes(jichou.name) > 0 then
      return false
    end

    local allCardNames = Fk:getAllCardNames("t")
    return table.find(
      player:getViewAsCardNames(jichou.name, allCardNames),
      function(name)
        return not table.contains(jichouRecord, name)
      end
    )
  end,
})

jichou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return
      not card:isRuleVirtual() and
      table.contains(player:getTableMark("@$jichou"), card.name)
  end,
})

jichou:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@$jichou"), data.card.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if target == player and data.card.trueName == "duel" then
      data.unoffsetableList = data.unoffsetableList or {}
      table.insertIfNeed(data.unoffsetableList, player)
    else
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player)
    end
  end,
})

jichou:addAcquireEffect(function(self, player)
  player.room:handleAddLoseSkills(player, "jichou_give&", nil, false, true)
end)

jichou:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:handleAddLoseSkills(player, "-jichou_give&", nil, false, true)
  end
end)

return jichou
