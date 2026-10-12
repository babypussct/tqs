local chongcha = fk.CreateSkill {
  name = "chongcha",
}

Fk:loadTranslationTable{
  ["chongcha"] = "重差",
  [":chongcha"] = "你的点数不小于10的牌不计入手牌上限，且使用时视为满足“割圆”中的点数0；出牌阶段限一次，" ..
  "若你拥有技能“割圆”，你可以弃置一张牌令“割圆”中的X调整为下一位的值。",

  ["#chongcha-active"] = "重差：你可弃置一张牌将“割圆”中的X调整为下一位的值",

  ["$chongcha1"] = "凡望极高、测绝深，必用重差。",
  ["$chongcha2"] = "重表、连索、累距，乃为重差之法。",
}

chongcha:addEffect("active", {
  prompt = "#chongcha-active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(chongcha.name, Player.HistoryPhase) == 0 and player:hasSkill("mobile__geyuan", true)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, chongcha.name, player, player)

    Fk.skill_skels["mobile__geyuan"].toNextPiNumber(player)
  end,
})

chongcha:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return
      player:hasSkill(chongcha.name) and
      card and
      card.number >= 10
  end,
})

return chongcha
