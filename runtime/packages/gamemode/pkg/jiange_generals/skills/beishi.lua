local beishi = fk.CreateSkill {
  name = "jiange__beishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__beishi"] = "备矢",
  [":jiange__beishi"] = "锁定技，当其他友方角色对敌方造成伤害后，你摸一张牌。",
}

beishi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(beishi.name) and
      target and target ~= player and target:isFriend(player) and data.to:isEnemy(player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, beishi.name)
  end,
})

return beishi
