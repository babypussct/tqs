local yuxiang = fk.CreateSkill{
  name = "yuxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuxiang"] = "御象",
  [":yuxiang"] = "锁定技，若你有护甲：你计算与其他角色的距离-1；其他角色计算与你的距离+1；当你受到火焰伤害时，此伤害+1。",

  ["$yuxiang1"] = "额啊啊，好大的火光啊！",
}

yuxiang:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuxiang.name) and
      player.shield > 0 and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})
yuxiang:addEffect("distance", {
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(yuxiang.name) and from.shield > 0 then
      n = n - 1
    end
    if to:hasSkill(yuxiang.name) and to.shield > 0 then
      n = n + 1
    end
    return n
  end,
})

return yuxiang
