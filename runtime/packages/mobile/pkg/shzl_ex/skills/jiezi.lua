local jiezi = fk.CreateSkill{
  name = "m_ex__jiezi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__jiezi"] = "截辎",
  [":m_ex__jiezi"] = "锁定技，当一名其他角色跳过摸牌阶段后，你摸一张牌。",

  ["$m_ex__jiezi1"] = "因粮于敌，故军食可足也。",
  ["$m_ex__jiezi2"] = "食敌一钟，当吾二十钟。",
}

jiezi:addEffect(fk.EventPhaseSkipped, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiezi.name) and target ~= player and data.phase == Player.Draw and
      player:usedSkillTimes(jiezi.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jiezi.name)
  end,
})

return jiezi
