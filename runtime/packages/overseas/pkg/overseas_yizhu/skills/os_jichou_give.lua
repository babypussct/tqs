local osJichouGive = fk.CreateSkill {
  name = "os__jichou_active&",
}

Fk:loadTranslationTable{
  ["os__jichou_active&"] = "急筹",
  [":os__jichou_active&"] = "出牌阶段限一次，你可以将手牌中“急筹”使用过的牌交给一名角色。",

  ["#os__jichou_active&"] = "急筹：将手牌中“急筹”使用过的牌交给一名角色",
}

osJichouGive:addEffect("active", {
  anim_type = "support",
  prompt = "#os__jichou_active&",
  can_use = function(self, player)
    return player:usedSkillTimes(osJichouGive.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark("@$os__jichou"), Fk:getCardById(to_select).name) and #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCardTo(effect.cards[1], Player.Hand, effect.tos[1], fk.ReasonGive, osJichouGive.name, nil, false, effect.from)
  end,
})

return osJichouGive
