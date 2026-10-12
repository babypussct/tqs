local ningzhou = fk.CreateSkill {
  name = "peixiu_ningzhou",
}

Fk:loadTranslationTable {
  ["peixiu_ningzhou"] = "宁州",
  [":peixiu_ningzhou"] = "你使用的【杀】不能被抵消，且造成的伤害均视为体力流失。",
}

ningzhou:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ningzhou.name) and
      data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

ningzhou:addEffect(fk.PreDamage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ningzhou.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, ningzhou.name)
    data:preventDamage()
  end,
})

return ningzhou
