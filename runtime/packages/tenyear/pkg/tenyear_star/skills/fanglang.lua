local fanglang = fk.CreateSkill {
  name = "fanglang",
}

Fk:loadTranslationTable{
  ["fanglang"] = "放浪",
  [":fanglang"] = "摸牌阶段，你可以展示一张此阶段摸到的牌，然后直到你的下回合开始，除展示的牌之外，你每回合使用或打出第一张牌时，"..
  "你摸X张牌（X为此牌与展示牌类别、花色、点数相同的项数）。<br>"..
  "结束阶段，你可以弃置一张牌，然后你获得弃牌堆中与此牌类别、点数、花色相同的牌各一张。",

  ["#fanglang-invoke"] = "放浪：你可以展示一张此阶段摸到的牌",
  ["@fanglang"] = "放浪",
  ["#fanglang-discard"] = "放浪：你可以弃置一张牌，获得弃牌堆中类别、点数、花色相同的牌各一张",

  ["$fanglang1"] = "吾当牵黄擎苍，猎尽天下伪君子面皮！",
  ["$fanglang2"] = "掷靴投铜鹤，呼尔莫上船！",
}

fanglang:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fanglang.name) and player.phase == Player.Draw and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.to == player and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryPhase)
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fanglang.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#fanglang-invoke",
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    card = Fk:getCardById(card[1])
    room:setPlayerMark(player, "@fanglang", { card:getTypeString(), card:getSuitString(true), card:getNumberStr() })
    room:setPlayerMark(player, fanglang.name, card.id)
    player:showCards(card)
  end,
})

fanglang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fanglang.name) and player.phase == Player.Finish and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fanglang.name,
      prompt = "#fanglang-discard",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    card = Fk:getCardById(card[1])
    room:throwCard(card, fanglang.name, player, player)
    if player.dead then return end
    local id, card2 = card.id, nil
    local cards = {}
    local cardMap = { {}, {}, {} }
    for _, id2 in ipairs(room.discard_pile) do
      card2 = Fk:getCardById(id2, true)
      if card2.type == card.type then
        table.insert(cardMap[1], id2)
      end
      if card2.number == card.number then
        table.insert(cardMap[2], id2)
      end
      if card2.suit == card.suit then
        table.insert(cardMap[3], id2)
      end
    end
    for _ = 1, 3, 1 do
      local x = #cardMap[1] + #cardMap[2] + #cardMap[3]
      if x == 0 then break end
      local index = math.random(x)
      for i = 1, 3, 1 do
        if index > #cardMap[i] then
          index = index - #cardMap[i]
        else
          id = cardMap[i][index]
          table.insert(cards, id)
          cardMap[i] = {}
          for _, v in ipairs(cardMap) do
            table.removeOne(v, id)
          end
          break
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, fanglang.name, nil, false, player)
    end
  end,
})

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fanglang.name) and
      player:getMark("@fanglang") ~= 0 and player:getMark(fanglang.name) ~= data.card.id then
      local mark = player:getMark("@fanglang")
      if data.card:getTypeString() == mark[1] or
        data.card:getSuitString(true) == mark[2] or
        data.card:getNumberStr() == mark[3] then
        local reason1, reason2 = GameEvent.UseCard, GameEvent.RespondCard
        if event == fk.CardUsing then
          reason1, reason2 = reason2, reason1
        end
        if #player.room.logic:getEventsOfScope(reason1, 1, function (e)
          return e.data.from == player
        end, Player.HistoryTurn) > 0 then return end
        local use_events = player.room.logic:getEventsOfScope(reason2, 1, function (e)
          return e.data.from == player
        end, Player.HistoryTurn)
        return #use_events == 1 and use_events[1].id == player.room.logic:getCurrentEvent().id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local n = 0
    local mark = player:getMark("@fanglang")
    if data.card:getTypeString() == mark[1] then
      n = n + 1
    end
    if data.card:getSuitString(true) == mark[2] then
      n = n + 1
    end
    if data.card:getNumberStr() == mark[3] then
      n = n + 1
    end
    player:drawCards(n, fanglang.name)
  end,
}
fanglang:addEffect(fk.CardUsing, spec)
fanglang:addEffect(fk.CardResponding, spec)

fanglang:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, fanglang.name, 0)
    player.room:setPlayerMark(player, "@fanglang", 0)
  end,
})

return fanglang
