local weiwu = fk.CreateSkill {
  name = "weiwu",
}

Fk:loadTranslationTable{
  ["weiwu"] = "违忤",
  [":weiwu"] = "出牌阶段限一次，你可以将一张红色牌当无距离限制的【顺手牵羊】使用。",

  ["#weiwu"] = "违忤：你可以将一张红色牌当无距离限制的【顺手牵羊】使用",

  ["$weiwu1"] = "凉州寸土，不可拱手让人。",
  ["$weiwu2"] = "明遵旨，暗忤意。",
}

weiwu:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  prompt = "#weiwu",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|red",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = weiwu.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(weiwu.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

weiwu:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, weiwu.name)
  end,
})

return weiwu
