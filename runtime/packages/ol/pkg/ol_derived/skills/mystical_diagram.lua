local skill = fk.CreateSkill {
  name = "#mystical_diagram_skill",
  tags = { Skill.Compulsory },
  attached_equip = "mystical_diagram",
}

skill:addEffect(fk.PreCardEffect, {
  can_trigger = function(self, event, target, player, data)
    return data.to == player and player:hasSkill(skill.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.nullified = true
  end,
})

return skill
