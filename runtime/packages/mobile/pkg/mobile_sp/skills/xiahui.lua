
local xiahui = fk.CreateSkill{
  name = "mobile__xiahui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__xiahui"] = "黠慧",
  [":mobile__xiahui"] = "锁定技，你的黑色牌不计入手牌上限；其他角色获得“连诛”牌或你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少。",

  ["@@mobile__xiahui-inhand"] = "黠慧",
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
            if table.contains(move.to:getCardIds("h"), info.cardId) and
              (Fk:getCardById(info.cardId).color == Card.Black or info.cardId == player:getMark("mobile__lianzhu-phase")) then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
            if table.contains(move.to:getCardIds("h"), info.cardId) and
            (Fk:getCardById(info.cardId).color == Card.Black or info.cardId == player:getMark("mobile__lianzhu-phase")) then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@@mobile__xiahui-inhand", player.id)
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
      room:setCardMark(Fk:getCardById(id), "@@mobile__xiahui-inhand", 0)
    end
  end,
})

xiahui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return Fk:getCardById(id):getMark("@@mobile__xiahui-inhand") ~= 0 and
          Fk:getCardById(id):getMark("@@mobile__xiahui-inhand") ~= player.id
      end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return Fk:getCardById(id):getMark("@@mobile__xiahui-inhand") ~= 0 and
          Fk:getCardById(id):getMark("@@mobile__xiahui-inhand") ~= player.id
      end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@mobile__xiahui-inhand") ~= 0 and
      card:getMark("@@mobile__xiahui-inhand") ~= player.id
  end,
})

return xiahui
