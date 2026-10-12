local junkui = fk.CreateSkill {
  name = "junkui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["junkui"] = "骏魁",
  [":junkui"] = "锁定技，游戏开始时，你将所有坐骑牌移出游戏；你使用【杀】的次数上限+1。",

  ["$junkui1"] = "凡驹，退场！",
  ["$junkui2"] = "肉骨凡胎，怎比我钢铁之躯！",
}

junkui:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junkui.name)
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
      room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, junkui.name, nil, true, player)
    end
  end,
})

junkui:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    return
      skill.trueName == "slash_skill" and
      scope == Player.HistoryPhase and
      player:hasSkill(junkui.name) and
      1 or
      0
  end,
})

return junkui
