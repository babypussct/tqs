local youyan = fk.CreateSkill{
  name = "ty_heg__youyan",
}
youyan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youyan.name) and player:usedSkillTimes(youyan.name, Player.HistoryTurn) == 0 and player.room.current == player then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId, true):getSuitString())
                can_invoked = true
              end
            end
          end
        end
      end
      if can_invoked and #suits > 0 then
        event:setCostData(self, {suits = suits})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local suits = event:getCostData(self).suits
    local show_num = 4
    local cards = room:getNCards(show_num)
    room:turnOverCardsFromDrawPile(player, cards, youyan.name)
    local to_get = table.filter(cards, function(id)
      return table.contains(suits, Fk:getCardById(id, true):getSuitString())
    end)
    if #to_get > 0 then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove)
    end
    room:cleanProcessingArea(cards)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__youyan"] = "诱言",
  [":ty_heg__youyan"] = "每回合限一次，当你的牌于你回合内因弃置而置入弃牌堆后，你可亮出牌堆顶四张牌，获得其中与此置入弃牌堆花色均不相同的牌。",

  ["$ty_heg__youyan1"] = "诱言者，为人所不齿。",
  ["$ty_heg__youyan2"] = "诱言之弊，不可不慎。",
}

return youyan
