local peixian = fk.CreateSkill {
  name = "peixiu_peixian",
}

Fk:loadTranslationTable {
  ["peixiu_peixian"] = "沛县",
  [":peixiu_peixian"] = "你的普通锦囊牌不能被响应。",
}

peixian:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(peixian.name) and
      data.card:isCommonTrick()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return peixian
