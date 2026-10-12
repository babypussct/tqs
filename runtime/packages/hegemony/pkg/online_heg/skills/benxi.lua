local benxi = fk.CreateSkill {
  name = "ol_heg__benxi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_heg__benxi"] = "奔袭",
  [":ol_heg__benxi"] = "锁定技，当你于回合内使用牌时，本回合你计算与其他角色的距离-1。",
  ["@ol_heg__benxi-turn"] = "奔袭",

  ["$ol_heg__benxi1"] = "奔战万里，袭关斩将。",
  ["$ol_heg__benxi2"] = "袭敌千里，溃敌百步！",
}

benxi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benxi.name) and player.room.current == player
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ol_heg__benxi-turn", 1)
  end,
})

benxi:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@ol_heg__benxi-turn")
  end,
})

return benxi
