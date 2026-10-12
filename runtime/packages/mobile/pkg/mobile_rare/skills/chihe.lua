local chihe = fk.CreateSkill {
  name = "changshi__chihe",
}

Fk:loadTranslationTable{
  ["changshi__chihe"] = "叱吓",
  [":changshi__chihe"] = "当你使用【杀】指定唯一目标后，你可以亮出牌堆顶两张牌，令其不能使用与亮出的牌花色相同的牌响应此【杀】，"..
  "且其中每有一张牌与此【杀】花色相同，此【杀】伤害基数便+1。",

  ["#changshi__chihe-invoke"] = "叱吓：是否令你对 %dest 使用的【杀】不能被响应且伤害增加？",

  ["$changshi__chihe1"] = "想见圣上？哼哼，你怕是没这个福分了！",
}

chihe:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chihe.name) and data.card.trueName == "slash" and #data.use.tos == 1
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = chihe.name,
      prompt = "#changshi__chihe-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardUseEvent = room.logic:getCurrentEvent().parent
    cardUseEvent.changshiChiheUsed = true

    local cards = room:getNCards(2)
    room:turnOverCardsFromDrawPile(player, cards, chihe.name)

    local idsMatched = table.filter(cards, function(id)
      local c = Fk:getCardById(id)
      return data.card.suit == c.suit
    end)

    room:setPlayerMark(data.to, chihe.name, table.map(cards, function (id)
      return Fk:getCardById(id).suit
    end))
    if #idsMatched > 0 then
      data.additionalDamage = (data.additionalDamage or 0) + #idsMatched
    end
    room:cleanProcessingArea(cards)
  end,
})
chihe:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room.logic:getCurrentEvent().changshiChiheUsed
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, chihe.name, 0)
    end
  end,
})
chihe:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    -- FIXME: 确保是因为【杀】而出闪，并且指明好事件id
    if Fk.currentResponsePattern ~= "jink" or card.name ~= "jink" or player:getMark("changshi__chihe") == 0 then
      return false
    end
    if table.contains(player:getMark("changshi__chihe"), card.suit) then
      return true
    end
  end,
})

return chihe
