local jiguan = fk.CreateSkill {
  name = "jiguan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiguan"] = "骥冠",
  [":jiguan"] = "锁定技，游戏开始时，你将所有坐骑牌移出游戏；你的手牌上限+2。",

  ["$jiguan1"] = "凡间之马，怎能翱翔于天际战场？",
  ["$jiguan2"] = "全力启动，必为主公拿下胜利！",
}

jiguan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiguan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if
        table.contains(
          { Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide },
          Fk:getCardById(id, true).sub_type
        )
      then
        table.insert(cards, id)
      end
    end
    for _, id in ipairs(room.discard_pile) do
      if
        table.contains(
          { Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide },
          Fk:getCardById(id, true).sub_type
        )
      then
        table.insert(cards, id)
      end
    end

    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("hej")) do
        if
          table.contains(
            { Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide },
            Fk:getCardById(id, true).sub_type
          )
        then
          table.insert(cards, id)
        end
      end
    end

    if #cards > 0 then
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, jiguan.name, nil, true, player)
    end
  end,
})

jiguan:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:hasSkill(jiguan.name) and 2 or 0
  end,
})

return jiguan
