local jueji = fk.CreateSkill {
  name = "jiange__jueji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__jueji"] = "绝汲",
  [":jiange__jueji"] = "锁定技，敌方角色摸牌阶段，若其已受伤，你令其少摸一张牌。",
}

jueji:addEffect(fk.DrawNCards, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jueji.name) and target:isEnemy(player) and
      target:isWounded() and data.n > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    data.n = data.n - 1
  end,
})

return jueji
