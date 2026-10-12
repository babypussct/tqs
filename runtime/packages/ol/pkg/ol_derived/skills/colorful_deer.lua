local skill = fk.CreateSkill {
  name = "#colorful_deer_skill",
  tags = { Skill.Compulsory },
  attached_equip = "colorful_deer",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) then
      return -1
    end
  end,
})

skill:addEffect(fk.DamageCaused, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return skill
