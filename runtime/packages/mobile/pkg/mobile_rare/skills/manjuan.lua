local manjuan = fk.CreateSkill {
  name = "friend__manjuan",
}

Fk:loadTranslationTable{
  ["friend__manjuan"] = "漫卷",
  [":friend__manjuan"] = "每轮限五次，当你不因本技能一次性获得至少两张牌后，你可以将其中任意张牌以任意顺序置于牌堆顶。若如此做，"..
  "你每放置一张牌，便从弃牌堆中随机获得一张与此牌类别不同的牌（每次至多获得五张）。",

  ["#friend__manjuan-invoke"] = "漫卷：你可以将其中的牌置于牌堆顶，获得等量类别不同的牌",

  ["$friend__manjuan1"] = "十行俱下犹觉浅，一朝闭门书五车。",
  ["$friend__manjuan2"] = "有此神目，何愁观之未遍。",
}

manjuan:addEffect(fk.AfterCardsMove, {
  times = function(self, player)
    return 5 - player:usedSkillTimes(manjuan.name, Player.HistoryRound)
  end,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(manjuan.name) and player:usedSkillTimes(manjuan.name, Player.HistoryRound) < 5 then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and (move.to and move.to == player and move.skillName ~= manjuan.name) then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local all_cards = {}
    for _, move in ipairs(data) do
      if #move.moveInfo > 1 and (move.to and move.to == player and move.skillName ~= manjuan.name) then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            table.insertIfNeed(all_cards, info.cardId)
          end
        end
      end
    end
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = manjuan.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = all_cards }),
      prompt = "#friend__manjuan-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    if #cards == 1 then
      room:moveCards({
        ids = cards,
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = manjuan.name,
        proposer = player,
      })
    else
      local result = room:askToGuanxing(player, {
        cards = cards,
        bottom_limit = { 0, 0 },
        skill_name = manjuan.name,
        skip = true,
      })
      room:moveCards({
        ids = table.reverse(result.top),
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = manjuan.name,
        proposer = player,
      })
    end
    if player.dead then return end
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    for _, id in ipairs(cards) do
      local type = Fk:getCardById(id).type
      local all_ids = table.filter(discard_pile, function (id2)
        return type ~= Fk:getCardById(id2).type
      end)
      if #all_ids > 0 then
        local c = room:tableRandomPick(all_ids)
        table.insert(ids, c)
        if #ids > 4 then break end
        table.removeOne(discard_pile, c)
      end
    end
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, manjuan.name, nil, true, player)
    end
  end,
})

return manjuan
