local skill = fk.CreateSkill {
  name = "#red_robe_skill",
  tags = { Skill.Compulsory },
  attached_equip = "red_robe",
}

Fk:loadTranslationTable{
  ["#red_robe_skill"] = "红棉百花袍",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

return skill
