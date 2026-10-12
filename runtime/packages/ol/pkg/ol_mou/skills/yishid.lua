local yishid = fk.CreateSkill {
  name = "yishid",
}

Fk:loadTranslationTable{
  ["yishid"] = "移势",
  [":yishid"] = "出牌阶段限一次，你可保留手牌中每个花色各一张牌并展示，将其余牌置入弃牌堆，然后移动场上的一张牌。"..
  "若你未因此失去手牌，直到你的下个回合开始，你不因使用失去与移动牌花色相同的牌后，摸一张牌。",

  ["#yishid"] = "移势：展示每种花色各一张手牌，其余置入弃牌堆，然后移动场上一张牌",
  ["#yishid-choose"] = "移势：请移动场上一张牌",
  ["@yishid"] = "移势",

  ["$yishid1"] = "迎天子驾万乘，都许，使天下有归心。",
  ["$yishid2"] = "兴义兵诛暴乱，势过五伯，魏公之议复何虑哉？",
}

yishid:addEffect("active", {
  anim_type = "control",
  prompt = "#yishid",
  max_phase_use_time = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yishid.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and
      Fk:getCardById(to_select).suit ~= Card.NoSuit and
      table.every(selected, function(id)
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
      end)
  end,
  feasible = function (self, player, selected, selected_cards, card)
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    return #selected_cards == #suits
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local ids = table.filter(player:getCardIds("h"), function (id)
      return not table.contains(effect.cards, id)
    end)
    local yes = not table.find(ids, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    player:showCards(effect.cards)
    if player.dead then return end
    ids = table.filter(ids, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #ids > 0 then
      room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonJustMove, yishid.name, nil, true, player)
    end
    if player.dead or #room:canMoveCardInBoard() == 0 then return end
    --不可取消，以卡牌在原区域的花色信息为准
    local tos = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#yishid-choose",
      skill_name = yishid.name,
      cancelable = false,
    })
    if #tos == 2 then
      local c = room:askToMoveCardInBoard(player, {
        target_one = tos[1],
        target_two = tos[2],
        skill_name = yishid.name,
      }).card
      if yes and not player.dead and c.suit ~= Card.NoSuit then
        room:addTableMarkIfNeed(player, "@yishid", c:getSuitString(true))
      end
    end
  end,
})

yishid:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yishid.name) and player:getMark("@yishid") ~= 0 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getTableMark("@yishid"), Fk:getCardById(info.cardId):getSuitString(true)) and
              (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, yishid.name)
  end,
})

yishid:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@yishid", 0)
  end,
})

yishid:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@yishid", 0)
end)

return yishid
