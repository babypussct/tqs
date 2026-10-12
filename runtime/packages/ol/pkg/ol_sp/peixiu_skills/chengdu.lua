local chengdu = fk.CreateSkill {
  name = "peixiu_chengdu",
}

Fk:loadTranslationTable {
  ["peixiu_chengdu"] = "成都",
  [":peixiu_chengdu"] = "你对自己使用牌后，你摸一张牌（每回合限一次）。",
}

chengdu:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengdu.name) and
      table.contains(data.tos, player) and
      player:usedSkillTimes(chengdu.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, chengdu.name)
  end,
})

return chengdu
