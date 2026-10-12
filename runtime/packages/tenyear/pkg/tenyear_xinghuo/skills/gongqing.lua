local gongqing = fk.CreateSkill {
  name = "gongqing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gongqing"] = "公清",
  [":gongqing"] = "锁定技，当你受到伤害时，若伤害来源的攻击范围小于3，将伤害值改为1；当你受到伤害时，若伤害来源的攻击范围大于3，你令此伤害值+1。",

  ["$gongqing1"] = "尔辈何故与降虏交善。",
  ["$gongqing2"] = "豪将在外，增兵必成祸患啊！",
}

gongqing:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(gongqing.name) and
      data.from and
      data.from:getAttackRange() > 3
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

gongqing:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(gongqing.name) and
      data.from and
      data.from:getAttackRange() < 3 and
      data.damage > 1
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1 - data.damage)
  end,
})

return gongqing
