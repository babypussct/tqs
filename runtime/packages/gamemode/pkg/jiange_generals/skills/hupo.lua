local hupo = fk.CreateSkill {
  name = "jiange__hupo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__hupo"] = "虎魄",
  [":jiange__hupo"] = "锁定技，你的锦囊牌均视为【杀】。",
}

hupo:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return player:hasSkill(hupo.name) and card.type == Card.TypeTrick and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

return hupo
