local shicai = fk.CreateSkill {
  name = "shicai",
}

Fk:loadTranslationTable{
  ["shicai"] = "恃才",
  [":shicai"] = "当你每回合首次使用一种类别的牌结算结束后，你可以将之置于牌堆顶，然后摸一张牌。",

  ["#shicai-invoke"] = "恃才：是否将%arg置于牌堆顶，然后摸一张牌？",
  ["@shicai-turn"] = "恃才",

  ["$shicai1"] = "吾才满腹，袁本初竟不从之。",
  ["$shicai2"] = "阿瞒有我良计，取冀州便是易如反掌。",
}

shicai:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shicai.name) and
      table.contains({ Card.PlayerEquip, Card.Processing }, player.room:getCardArea(data.card)) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player and e.data.card.type == data.card.type
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shicai.name,
      prompt = "#shicai-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toPut = Card:getIdList(data.card)

    if #toPut > 1 then
      toPut = room:askToGuanxing(player, {
        cards = toPut,
        top_limit = { #toPut, #toPut },
        bottom_limit = { 0, 0 },
        skill_name = shicai.name,
        skip = true,
      }).top
      toPut = table.reverse(toPut)
    end

    room:moveCardTo(toPut, Card.DrawPile, nil, fk.ReasonPut, shicai.name, nil, true)
    player:drawCards(1, shicai.name)
  end,
})

shicai:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(shicai.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@shicai-turn", data.card:getTypeString().."_char")
  end,
})

shicai:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    return ai:getBenefitOfEvents(function(logic)
      logic:moveCardTo(data.card, Card.DrawPile, nil, fk.ReasonPut)
      logic:drawCards(ai.player, 1)
    end) >= 0
  end,
})

return shicai
