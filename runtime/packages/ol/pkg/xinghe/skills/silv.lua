local silv = fk.CreateSkill{
  name = "silv",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["silv"] = "思闾",
  [":silv"] = "锁定技，一名角色因〖联句〗获得的牌称为“闾”；当你受到伤害后，你摸一张牌并称为“闾”。当一名角色的“闾”因弃置进入弃牌堆后，其获得之。",

  ["@@silv-inhand"] = "闾",

  ["$silv1"] = "大义同胶漆，匪石心不移。",
  ["$silv2"] = "人谁不虑终，日月有合离。",
}

silv:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    player:drawCards(1, silv.name, "top", "@@silv-inhand")
  end,
})
silv:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player.dead then
      local ids = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and info.beforeCard:getMark("@@silv-inhand") > 0 and
              room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      ids = room.logic:moveCardsHoldingAreaCheck(ids)
      if #ids > 0 then
        event:setCostData(self, { cards = ids })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, silv.name)
  end,
})

return silv
