local lingfeng = fk.CreateSkill {
  name = "jiange__lingfeng",
}

Fk:loadTranslationTable{
  ["jiange__lingfeng"] = "灵锋",
  [":jiange__lingfeng"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶两张牌并获得之，若颜色不同，你可以令一名敌方角色失去1点体力。",

  ["#jiange__lingfeng-choose"] = "灵锋：你可以令一名敌方角色失去1点体力",
}

lingfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingfeng.name) and player.phase == Player.Draw and
      not data.phase_end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local cards = room:getNCards(2)
    room:turnOverCardsFromDrawPile(player, cards, lingfeng.name)
    room:delay(1000)
    local yes = #cards == 2 and Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, lingfeng.name, nil, true, player)
    end
    if yes and not player.dead and #player:getEnemies() > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = player:getEnemies(),
        min_num = 1,
        max_num = 1,
        prompt = "#jiange__lingfeng-choose",
        skill_name = lingfeng.name,
        cancelable = true
      })
      if #to > 0 then
        room:loseHp(to[1], 1, lingfeng.name)
      end
    end
  end,
})

return lingfeng
