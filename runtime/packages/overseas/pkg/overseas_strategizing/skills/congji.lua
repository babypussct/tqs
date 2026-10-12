local congji = fk.CreateSkill {
  name = "os__congji",
}

Fk:loadTranslationTable{
  ["os__congji"] = "从击",
  [":os__congji"] = "当你于回合外弃置牌后，你可将其中的所有红色牌交给一名其他角色。",

  ["#os__congji-choose"] = "从击：你可以将弃置的所有红色牌交给一名其他角色",
}

congji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(congji.name) and #player.room:getOtherPlayers(player, false) > 0 and
      player.room.current ~= player then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Red and
              (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = table.filter(cards, function(id)
        return table.contains(player.room.discard_pile, id)
      end)
      cards = player.room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = congji.name,
      prompt = "#os__congji-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, cards = event:getCostData(self).cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    player.room:obtainCard(to, cards, true, fk.ReasonGive, player, congji.name)
  end,
})

return congji
