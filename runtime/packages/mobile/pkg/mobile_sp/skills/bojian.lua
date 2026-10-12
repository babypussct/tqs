local bojian = fk.CreateSkill{
  name = "bojian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bojian"] = "博鉴",
  [":bojian"] = "锁定技，出牌阶段结束时，若你本阶段使用的牌数与花色数与你上个出牌阶段均不同，则你摸两张牌；否则你选择弃牌堆中你本阶段使用过"..
  "的一张牌，将之交给一名角色。",

  ["#bojian-give"] = "博鉴：请选择其中一张牌交给一名角色",

  ["$bojian1"] = "闻古者贤女，未有不学前世成败而以为己诫。",
  ["$bojian2"] = "视字辄识，方知何为礼义。",
}

bojian:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(bojian.name) and player.phase == Player.Play then
      local room = player.room
      local id, end_id = 1, 1
      room.logic:getEventsByRule(GameEvent.Phase, 1, function (e)
        if e.data.who == player and e.data.phase == Player.Play and e.id < room.logic:getCurrentEvent().id then
          id, end_id = e.id, e.end_id
          return true
        end
      end, 1)
      if id > 1 then
        local n1, suit1 = 0, {}
        room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          if e.id <= end_id then
            local use = e.data
            if use.from == player then
              n1 = n1 + 1
              table.insertIfNeed(suit1, use.card.suit)
            end
          end
        end, id)
        local n2, suit2 = 0, {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == player then
            n2 = n2 + 1
            table.insertIfNeed(suit2, use.card.suit)
          end
        end, Player.HistoryPhase)
        table.removeOne(suit1, Card.NoSuit)
        table.removeOne(suit2, Card.NoSuit)
        if n1 ~= n2 and #suit1 ~= #suit2 then
          event:setCostData(self, {choice = 1})
          return true
        else
          if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data
            return use.from == player and not (use.card:isVirtual() and #use.card.subcards ~= 1) and
              table.contains(room.discard_pile, use.card:getEffectiveId())
          end, Player.HistoryPhase) > 0 then
            event:setCostData(self, {choice = 2})
            return true
          end
        end
      else
        event:setCostData(self, {choice = 1})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).choice == 1 then
      player:drawCards(2, bojian.name)
    else
      local room = player.room
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player and not (use.card:isVirtual() and #use.card.subcards ~= 1) and
          table.contains(room.discard_pile, use.card:getEffectiveId()) then
          table.insertIfNeed(cards, use.card:getEffectiveId())
        end
      end, Player.HistoryPhase)
      local to, card = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        pattern = tostring(Exppattern{ id = cards }),
        skill_name = bojian.name,
        prompt = "#bojian-give",
        cancelable = false,
        expand_pile = cards,
      })
      room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, bojian.name, nil, true, player)
    end
  end,
})

return bojian
