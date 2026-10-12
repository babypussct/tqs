local xiahui = fk.CreateSkill {
  name = "ty__xiahui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__xiahui"] = "黠慧",
  [":ty__xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌后，这些牌标记为“黠慧”，其不能使用、打出、弃置“黠慧”牌"..
  "直到其体力值减少。其他角色回合结束时，若其本回合失去过“黠慧”牌且手牌中没有“黠慧”牌，其失去1点体力。",

  ["@@ty__xiahui-inhand"] = "黠慧",
}

xiahui:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(xiahui.name) and card.color == Card.Black
  end,
})

xiahui:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(xiahui.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Black and table.contains(move.to:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ty__xiahui-inhand", 1)
          end
        end
      end
    end
  end,
})

xiahui:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.num < 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@ty__xiahui-inhand", 0)
    end
  end,
})

xiahui:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiahui.name) and not target.dead and
      not table.find(target:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0
      end) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == target then
            for _, info in ipairs(move.moveInfo) do
              if info.beforeCard:getMark("@@ty__xiahui-inhand") > 0 and info.fromArea == Player.Hand then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, xiahui.name, player)
  end,
})

xiahui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0
    end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0
    end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@ty__xiahui-inhand") > 0
  end,
})

return xiahui
