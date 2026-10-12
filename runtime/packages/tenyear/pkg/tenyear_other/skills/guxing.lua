local guxing = fk.CreateSkill {
  name = "guxing",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["guxing"] = "孤星",
  [":guxing"] = "限定技，回合开始时，你可依次执行X项，从牌堆和弃牌堆中：1.获得记录牌；2.获得与记录牌点数花色皆相同的牌；3.获得与记录牌同名牌，"..
  "每种牌名至多5张（X为当前轮数）。",

  ["@$guxing"] = "孤星",
}

guxing:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guxing.name) and
      player:usedSkillTimes(guxing.name, Player.HistoryGame) == 0 and
      #player:getTableMark("@$guxing") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = room:getBanner("RoundCount")
    local record = player:getTableMark("@$guxing")
    local cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
      return table.contains(record, id)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, guxing.name, nil, true, player)
      if player.dead then return end
    end
    if n > 1 then
      cards = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
        return table.find(record, function (id2)
          return Fk:getCardById(id).number == Fk:getCardById(id2).number and
            Fk:getCardById(id).suit == Fk:getCardById(id2).suit
        end)
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, guxing.name, nil, true, player)
        if player.dead then return end
      end
      if n > 2 then
        local names = {}
        for _, id in ipairs(record) do
          table.insertIfNeed(names, Fk:getCardById(id).trueName)
        end
        cards = {}
        for _, name in ipairs(names) do
          table.insertTable(cards, room:getCardsFromPileByRule(name, 5, "allPiles"))
        end
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, guxing.name, nil, true, player)
        end
      end
    end
  end,
})

return guxing
