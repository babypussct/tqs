local longyuan = fk.CreateSkill {
  name = "longyuan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["longyuan"] = "龙渊",
  [":longyuan"] = "觉醒技，准备阶段，若你本局游戏内发动过至少三次〖翊赞〗，你修改〖翊赞〗为只需一张牌。",

  ["$longyuan1"] = "金鳞岂是池中物，一遇风云便化龙。",
  ["$longyuan2"] = "忍时待机，今日终于可以建功立业。",
}

longyuan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(longyuan.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(longyuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("yizan", Player.HistoryGame) > 2
  end,
})

return longyuan
