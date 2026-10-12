local wuxie = fk.CreateSkill {
  name = "wuxie",
}

Fk:loadTranslationTable{
  ["wuxie"] = "无胁",
  [":wuxie"] = "回合结束时，你可以选择一名其他角色，与其交换手牌，然后你将手牌中的所有伤害牌置入牌堆底。",

  ["#wuxie-choose"] = "无胁：你可与一名其他角色交换手牌，然后你将手牌中所有伤害牌置入牌堆底",

  ["$wuxie1"] = "一个弱质女流，安能登辇拔剑？",
  ["$wuxie2"] = "主上既亡，我当为生者计。",
}

wuxie:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuxie.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#wuxie-choose",
      skill_name = wuxie.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:swapAllCards(player, { player, to }, wuxie.name, "h")

    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    if #cards > 0 then
      room:delay(2000)
      table.shuffle(cards)
      room:moveCards{
        ids = cards,
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = wuxie.name,
        drawPilePosition = -1,
        moveVisible = false,
      }
    end
  end,
})

return wuxie
