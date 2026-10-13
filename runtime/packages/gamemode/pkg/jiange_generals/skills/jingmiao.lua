local jingmiao = fk.CreateSkill {
  name = "jiange__jingmiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__jingmiao"] = "精妙",
  [":jiange__jingmiao"] = "锁定技，当敌方角色使用【无懈可击】结算后，其失去1点体力。",
}

jingmiao:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jingmiao.name) and data.card.trueName == "nullification" and
      target:isEnemy(player) and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, jingmiao.name)
  end,
})

return jingmiao
