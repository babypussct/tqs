local zhongzhuang = fk.CreateSkill {
  name = "zhongzhuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhongzhuang"] = "忠壮",
  [":zhongzhuang"] = "锁定技，你使用【杀】造成伤害时，若你的攻击范围大于3，则此伤害+1；若你的攻击范围小于3，则此伤害改为1。",

  ["$zhongzhuang1"] = "秽尘天听，卿有不测之祸！",
  ["$zhongzhuang2"] = "倾乱国政，安得寿终正寝？",
}

zhongzhuang:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongzhuang.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect(false) and
      player:getAttackRange() > 3
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

zhongzhuang:addEffect(fk.DetermineDamageCaused, {
  anim_type = "negative",
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongzhuang.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect(false) and
      player:getAttackRange() < 3 and data.damage > 1
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1 - data.damage)
  end,
})

return zhongzhuang
