local skill = fk.CreateSkill {
  name = "#bronze_sparrow_skill",
  tags = { Skill.Compulsory },
  attached_equip = "bronze_sparrow",
}

Fk:loadTranslationTable{
  ["#bronze_sparrow_skill"] = "铜雀",
}

skill:addEffect(fk.PreCardUse, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0 and
      (data.card.extra_data or {}).variation
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.variation_type = { "@fujia", "@kongchao", "@canqu", "@zhuzhan" }
  end,
})

return skill
