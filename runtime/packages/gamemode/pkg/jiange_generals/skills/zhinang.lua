local zhinang = fk.CreateSkill {
  name = "jiange__zhinang",
}

Fk:loadTranslationTable{
  ["jiange__zhinang"] = "智囊",
  [":jiange__zhinang"] = "准备阶段，你可以亮出牌堆顶三张牌，然后你可以将其中的非基本牌交给一名友方角色。",

  ["#jiange__zhinang-give"] = "智囊：你可以将其中的非基本牌交给一名友方角色",
}

zhinang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhinang.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, zhinang.name)
    room:delay(1000)
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards == 0 then return end
    if player.dead then
      room:cleanProcessingArea(cards)
      return
    end
    local get = table.filter(cards, function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    if #get > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = player:getFriends(),
        min_num = 1,
        max_num = 1,
        prompt = "#jiange__zhinang-give",
        skill_name = zhinang.name,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        room:moveCardTo(get, Card.PlayerHand, to, fk.ReasonGive, zhinang.name, nil, true, player)
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return zhinang
