local mExShenxing = fk.CreateSkill {
  name = "m_ex__shenxing",
}

Fk:loadTranslationTable{
  ["m_ex__shenxing"] = "慎行",
  [":m_ex__shenxing"] = "出牌阶段限X次（X为你的体力值），你可以弃置两张牌，若弃置牌颜色不同，则你摸两张牌；否则你摸一张牌。",

  ["#m_ex__shenxing"] = "慎行：你可弃置两张牌，摸一张牌，若弃牌颜色不同则多摸一张",

  ["$m_ex__shenxing1"] = "上兵伐谋，三思而行。",
  ["$m_ex__shenxing2"] = "精益求精，慎之再慎。",
}

mExShenxing:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#m_ex__shenxing",
  card_num = 2,
  target_num = 0,
  times = function(self, player)
    return math.max(0, player.hp) - player:usedSkillTimes(mExShenxing.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(mExShenxing.name, Player.HistoryPhase) < player.hp
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and not player:prohibitDiscard(to_select)
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mExShenxing.name
    local player = effect.from
    local isDiff = #effect.cards > 1 and Fk:getCardById(effect.cards[1]):compareColorWith(Fk:getCardById(effect.cards[2]), true)

    room:throwCard(effect.cards, skillName, player, player)
    player:drawCards(isDiff and 2 or 1, skillName)
  end,
})

return mExShenxing
