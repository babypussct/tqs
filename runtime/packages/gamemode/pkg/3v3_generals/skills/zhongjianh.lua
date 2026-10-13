local zhongjianh = fk.CreateSkill {
  name = "zhongjianh"
}

Fk:loadTranslationTable{
  ["zhongjianh"] = "忠谏",
  [":zhongjianh"] = "出牌阶段限一次，你可以交给一名己方其他角色一张牌，然后你摸一张牌。",

  ["#zhongjianh"] = "忠谏：交给一名己方角色一张牌，然后你摸一张牌",

  ["$zhongjianh1"] = "锦上添花，不如雪中送炭。",
  ["$zhongjianh2"] = "密计交于将军，可解燃眉之困。",
}

zhongjianh:addEffect("active", {
  anim_type = "support",
  prompt = "#zhongjianh",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhongjianh.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isFriend(player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, zhongjianh.name, nil, false, player)
    if not player.dead then
      player:drawCards(1, zhongjianh.name)
    end
  end,
})

return zhongjianh
