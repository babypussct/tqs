local sanchen = fk.CreateSkill {
  name = "mobile__sanchen",
  tags = { Skill.Wake },
  related_skills = { "miewu" },
}

Fk:loadTranslationTable{
  ["mobile__sanchen"] = "三陈",
  [":mobile__sanchen"] = "觉醒技，结束阶段，若你已有3个“武库”，你增加1点体力上限，回复1点体力，然后获得技能〖灭吴〗。",

  ["$mobile__sanchen1"] = "贼计已穷，陈兵吴地，可一鼓而下也。",
  ["$mobile__sanchen2"] = "伐吴此举，十有九利，惟陛下察之。",
}

sanchen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sanchen.name) and player.phase == Player.Finish and
      player:usedSkillTimes(sanchen.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@wuku") == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = sanchen.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "miewu")
  end,
})

return sanchen
