local miesha = fk.CreateSkill {
  name = "miesha",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["miesha"] = "灭杀",
  [":miesha"] = "锁定技，当你对一名其他角色造成伤害时，若其体力值为1，你令伤害值+1。",
}

miesha:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(miesha.name) and
      data.to.hp == 1 and data.to ~= player
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return miesha
