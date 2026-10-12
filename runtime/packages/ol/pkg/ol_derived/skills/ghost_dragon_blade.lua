local skill = fk.CreateSkill {
  name = "#ghost_dragon_blade_skill",
  tags = { Skill.Compulsory },
  attached_equip = "ghost_dragon_blade",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.firstTarget and
      data.card.trueName == "slash" and data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

return skill
