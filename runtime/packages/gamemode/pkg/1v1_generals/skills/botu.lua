local botu = fk.CreateSkill {
  name = "v11__botu",
}

Fk:loadTranslationTable{
  ["v11__botu"] = "博图",
  [":v11__botu"] = "回合结束时，若你于出牌阶段内使用过的牌中包含四种花色，你可以执行一个额外的回合。",

  ["@v11__botu-turn"] = "博图",

  ["$v11__botu1"] = "今日起兵，渡江攻敌！",
  ["$v11__botu2"] = "时机已到，全军出击！",
}

botu:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(botu.name) and #player:getTableMark("@v11__botu-turn") == 4
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn()
  end,
})

botu:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(botu.name, true) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit and
      #player:getTableMark("@v11__botu-turn") < 4
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@v11__botu-turn", data.card:getSuitString(true))
  end,
})

return botu
