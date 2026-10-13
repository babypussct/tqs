local jixi = fk.CreateSkill {
  name = "jiange__jixi",
}

Fk:loadTranslationTable{
  ["jiange__jixi"] = "急袭",
  [":jiange__jixi"] = "你可以将一张锦囊牌当【顺手牵羊】使用。",

  ["#jiange__jixi"] = "急袭：你可以将一张锦囊牌当【顺手牵羊】使用",
}

jixi:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  prompt = "#jiange__jixi",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeTrick
  end,
  before_use = function (self, player)
    player:broadcastSkillInvoke("jixi")
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = jixi.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

return jixi
