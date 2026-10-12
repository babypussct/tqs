local hongyan = fk.CreateSkill{
  name = "hs__hongyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hs__hongyan"] = "红颜",
  [":hs__hongyan"] = "锁定技，你的♠牌视为<font color='red'>♥</font>牌；若你的装备区内有<font color='red'>♥</font>牌，你的手牌上限+1。",
}

hongyan:addEffect("filter", {
  card_filter = function(self, to_select, player, is_judge)
    return to_select.suit == Card.Spade and player:hasSkill(hongyan.name) and
      (table.contains(player:getCardIds("he"), to_select.id) or is_judge)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
})

hongyan:addEffect("maxcards", {
  correct_func = function (self, player)
    if player:hasSkill(hongyan.name) and table.find(player:getCardIds("e"), function (id)
      return Fk:getCardById(id).suit == Card.Heart
    end) then
      return 1
    end
  end,
})

return hongyan
