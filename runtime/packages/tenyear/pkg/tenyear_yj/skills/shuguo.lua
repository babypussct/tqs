local shuguo = fk.CreateSkill{
  name = "shuguo",
}

Fk:loadTranslationTable{
  ["shuguo"] = "戍国",
  [":shuguo"] = "每回合结束时，你可以依次使用本回合因弃置而置入弃牌堆的牌直到你使用了其他角色弃置的牌。若你的手牌数不为全场唯一最多，"..
  "每有一张本回合弃置的牌没有使用，你摸一张牌（至多摸五张）。",

  ["@@shuguo-other"] = "其他角色",
  ["#shuguo-use"] = "戍国：你可以使用其中一张牌",

  ["$shuguo1"] = "大丈夫处世，当为国家立功边境。",
  ["$shuguo2"] = "但教一息尚存，必横长槊于阴山！",
}

shuguo:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuguo.name) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_cards, others = {}, {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(all_cards, info.cardId)
              if move.from and move.from ~= player then
                table.insertIfNeed(others, info.cardId)
              end
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local cards = table.simpleClone(all_cards)
    while not player.dead do
      cards = table.filter(cards, function(id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards == 0 then break end
      for _, id in ipairs(cards) do
        if table.contains(others, id) then
          room:setCardMark(Fk:getCardById(id), "@@shuguo-other", 1)
        end
      end
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = shuguo.name,
        prompt = "#shuguo-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = cards,
        },
        skip = true,
      })

      for _, id in ipairs(cards) do
        if table.contains(others, id) then
          room:setCardMark(Fk:getCardById(id), "@@shuguo-other", 0)
        end
      end
      if use then
        table.removeOne(all_cards, use.card:getEffectiveId())
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
        if table.contains(others, use.card:getEffectiveId()) then
          break
        end
      else
        break
      end
    end
    if not player.dead and #all_cards > 0 and
      table.find(room:getOtherPlayers(player, false), function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) then
      player:drawCards(math.min(#all_cards, 5), shuguo.name)
    end
  end,
})

shuguo:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return shuguo
