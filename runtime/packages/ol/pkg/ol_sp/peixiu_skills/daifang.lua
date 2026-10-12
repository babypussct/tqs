local daifang = fk.CreateSkill {
  name = "peixiu_daifang",
}

Fk:loadTranslationTable {
  ["peixiu_daifang"] = "带方",
  [":peixiu_daifang"] = "你的属性【杀】不能被响应。",
}

daifang:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(daifang.name) and
      data.card.trueName == "slash" and data.card.damage_type ~= fk.NormalDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return daifang
