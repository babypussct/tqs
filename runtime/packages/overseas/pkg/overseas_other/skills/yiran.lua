local yiran = fk.CreateSkill {
  name = "os__yiran",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__yiran"] = "易燃",
  [":os__yiran"] = "锁定技，你受到的火焰伤害+1。",
}

yiran:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yiran.name) and
      data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return yiran
