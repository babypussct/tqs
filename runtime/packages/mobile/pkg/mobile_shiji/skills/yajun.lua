local yajun = fk.CreateSkill {
  name = "yajun",
}

Fk:loadTranslationTable{
  ["yajun"] = "雅俊",
  [":yajun"] = "摸牌阶段，你多摸一张牌。出牌阶段开始时，你可以用一张本回合获得的牌与一名其他角色拼点，若你：赢，你可以将其中一张拼点牌"..
  "置于牌堆顶；没赢，你本回合的手牌上限-1。",

  ["#yajun-invoke"] = "雅俊：你可以用一张本回合获得的牌与一名其他角色拼点",
  ["yajun_top"] = "置于牌堆顶",
  ["#yajun-put"] = "雅俊：你可以将其中一张牌置于牌堆顶",

  ["$yajun1"] = "君子如珩，缨绂有容！",
  ["$yajun2"] = "仁声未闻，岂可先计后兵！",
}

yajun:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yajun.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.n = data.n + 1
  end,
})
yajun:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yajun.name) and player.phase == Player.Play and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end) and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.toArea == Card.PlayerHand then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = tostring(Exppattern{ id = ids }),
      skill_name = yajun.name,
      prompt = "#yajun-invoke",
      cancelable = true,
    })
    if #tos > 0 and #cards == 1 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({to}, yajun.name, Fk:getCardById(event:getCostData(self).cards[1]))
    if player.dead then return end
    if pindian.results[to].winner ~= player then
      room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
    end
  end,
})

yajun:addEffect(fk.PindianResultConfirmed, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    return
      data.reason == yajun.name and
      data.from == player and
      data.winner == player and
      (
        room:getCardArea(data.fromCard) == Card.Processing or
        room:getCardArea(data.toCard) == Card.Processing
      )
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local toPut = {}
    if room:getCardArea(data.fromCard) == Card.Processing then
      table.insert(toPut, data.fromCard:getEffectiveId())
    end
    if room:getCardArea(data.toCard) == Card.Processing then
      table.insertIfNeed(toPut, data.toCard:getEffectiveId())
    end

    local result = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yajun.name,
        pattern = tostring(Exppattern{ id = toPut }),
        prompt = "#yajun-put",
        cancelable = true,
        expand_pile = toPut,
      }
    )

    if #result == 1 then
      event:setCostData(self, { cards = result })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      ids = event:getCostData(self).cards,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = yajun.name,
    })
  end,
})

return yajun
