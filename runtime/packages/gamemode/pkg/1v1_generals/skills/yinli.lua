local yinli = fk.CreateSkill {
  name = "v11__yinli",
}

Fk:loadTranslationTable{
  ["v11__yinli"] = "姻礼",
  [":v11__yinli"] = "对手的回合内，当该角色的装备牌置入弃牌堆时，你可以获得之。",

  ["$v11__yinli1"] = "这份大礼我收下啦！",
  ["$v11__yinli2"] = "小女子谢过将军。",
}

yinli:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yinli.name) and player.room.current ~= player then
      local ids = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from and move.from ~= player then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                Fk:getCardById(info.cardId).type == Card.TypeEquip and
                table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end
      ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, yinli.name, nil, true, player)
  end,
})

return yinli
