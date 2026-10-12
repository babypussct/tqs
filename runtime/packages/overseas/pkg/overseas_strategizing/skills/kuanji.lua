local kuanji = fk.CreateSkill {
  name = "os__kuanji",
}

Fk:loadTranslationTable{
  ["os__kuanji"] = "宽济",
  [":os__kuanji"] = "每回合限一次，当你的牌非因使用而置入弃牌堆后，你可以令一名其他角色获得其中的任意张牌。",

  ["#os__kuanji-give"] = "宽济：你可以令一名其他角色获得其中任意张牌",

  ["$os__kuanji1"] = "功以才成，业由才广，弃才不用，非长计也。",
  ["$os__kuanji2"] = "舍此不任而防后患，是备风波而废舟楫也。",
}

kuanji:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kuanji.name) and #player.room:getOtherPlayers(player, false) > 0 and
      player:usedSkillTimes(kuanji.name, Player.HistoryTurn) == 0 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason ~= fk.ReasonUse and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
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
    local cards = event:getCostData(self).cards
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = #cards,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = kuanji.name,
        pattern = tostring(Exppattern{ id = cards }),
      prompt = "#os__kuanji-give",
      cancelable = true,
      expand_pile = cards,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, {tos = to, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, kuanji.name, nil, true, player)
  end,
})

return kuanji
