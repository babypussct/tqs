local yuhuo = fk.CreateSkill {
  name = "jiange__yuhuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__yuhuo"] = "浴火",
  [":jiange__yuhuo"] = "锁定技，防止你受到的火焰伤害。",
}

yuhuo:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuhuo.name) and data.damageType == fk.FireDamage
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

return yuhuo
