
local ol_jinjiu = fk.CreateSkill {
  name = "ol_jinjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_jinjiu"] = "禁酒",
  [":ol_jinjiu"] = "锁定技，你的【酒】视为【杀】。",

  ["$ol_jinjiu1"] = "贬酒阙色，所以无污。",
  ["$ol_jinjiu2"] = "避嫌远疑，所以无误。",
}

ol_jinjiu:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(ol_jinjiu.name) and card.name == "analeptic" and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return ol_jinjiu
