local zhizhe = fk.CreateSkill {
  name = "zhizhe",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",

  ["#zhizhe"] = "智哲：获得一张手牌的复制！",
  ["@@zhizhe-inhand"] = "智哲",

  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
}


zhizhe:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#zhizhe",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(zhizhe.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local c = Fk:getCardById(effect.cards[1], true)
    local card = room:printCard(c.name, c.suit, c.number)
    room:obtainCard(player, card, false, fk.ReasonJustMove, player, zhizhe.name, "@@zhizhe-inhand")
  end
})

zhizhe:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhizhe.name) then
      local room = player.room
      local toObtain, toConfirm = {}, {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.from == nil then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and
              (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) and
              table.contains(room.discard_pile, info.cardId) then
              table.insert(toConfirm, info.cardId)
            end
          end
        end
      end
      if #toConfirm > 0 then
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
          local use = parent_event.data ---@type UseCardData|RespondCardData
          if use.from == player and use.subcardsFromInfo then
            for _, info in ipairs(use.subcardsFromInfo) do
              if table.removeOne(toConfirm, info.cardId) and info.from == player and
                (info.beforeCard:getMark("@@zhizhe-inhand") > 0) then
                table.insert(toObtain, info.cardId)
              end
            end
          end
        end
        toObtain = room.logic:moveCardsHoldingAreaCheck(toObtain)
        if #toObtain > 0 then
          event:setCostData(self, { cards = toObtain })
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, event:getCostData(self).cards, true, fk.ReasonJustMove, player,
      zhizhe.name, {"@@zhizhe-inhand", 1, "zhizhe-inhand-turn", 1})
  end,
})

zhizhe:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return table.find(Card:getIdList(card), function(id)
      return Fk:getCardById(id, true):getMark("zhizhe-inhand-turn") ~= 0
    end)
  end,
  prohibit_response = function(self, player, card)
    return table.find(Card:getIdList(card), function(id)
      return Fk:getCardById(id, true):getMark("zhizhe-inhand-turn") ~= 0
    end)
  end,
})

return zhizhe
