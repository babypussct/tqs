local yuanyuk = fk.CreateSkill{
  name = "yuanyuk",
  tags = {Skill.Compulsory},
}
yuanyuk:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanyuk.name)
      and data.from and not data.from:inMyAttackRange(target)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end
})

Fk:loadTranslationTable{
  ["yuanyuk"] = "远域",
  [":yuanyuk"] = "锁定技，当你受到伤害时，若有伤害来源且你不在伤害来源的攻击范围内，此伤害-1。",

  ["$yuanyuk1"] = "是你，在召唤我吗？",
  ["$yuanyuk2"] = "这片土地的人，真是太有趣了。",
}

return yuanyuk