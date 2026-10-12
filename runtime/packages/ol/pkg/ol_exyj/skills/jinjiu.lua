local jinjiu = fk.CreateSkill {
  name = "ol_ex__jinjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol_ex__jinjiu"] = "禁酒",
  [":ol_ex__jinjiu"] = "锁定技，你的【酒】的视为点数为K的【杀】；其他角色不能于你的回合使用【酒】。",

  ["$ol_ex__jinjiu1"] = "耽此黄汤，岂不误事？",
  ["$ol_ex__jinjiu2"] = "陷阵营中，不可饮酒。",
}

jinjiu:addEffect("filter", {
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(jinjiu.name) and card.name == "analeptic" and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, 13)
  end,
})

jinjiu:addEffect("prohibit", {
  aniol_type = "offensive",
  prohibit_use = function(self, player, card)
    return card.name == "analeptic" and Fk:currentRoom():getCurrent() and
        Fk:currentRoom():getCurrent():hasSkill(jinjiu.name)
        and player ~= Fk:currentRoom():getCurrent()
  end,
})

return jinjiu
