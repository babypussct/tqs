local dunhuang = fk.CreateSkill {
  name = "peixiu_dunhuang",
}

Fk:loadTranslationTable {
  ["peixiu_dunhuang"] = "敦煌",
  [":peixiu_dunhuang"] = "你的【杀】被抵消后，你摸一张牌。",
}

dunhuang:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dunhuang.name) and
      data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dunhuang.name)
  end,
})

return dunhuang
