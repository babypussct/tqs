local skill = fk.CreateSkill {
  name = "#fire_string_skill",
  tags = { Skill.Compulsory },
  attached_equip = "fire_string",
}

skill:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.name == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data:changeCard("fire__slash", data.card.suit, data.card.number, skill.name)
  end,
})

skill:addEffect(fk.PreDamage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data.damageType = fk.FireDamage
  end,
})

return skill
