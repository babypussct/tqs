local kanpo = fk.CreateSkill {
  name = "m_ex__kanpo",
}

Fk:loadTranslationTable{
  ["m_ex__kanpo"] = "看破",
  [":m_ex__kanpo"] = "你可以将一张黑色牌当【无懈可击】使用。",

  ["#m_ex__kanpo"] = "看破：你可以将一张黑色牌当【无懈可击】使用",

  ["$m_ex__kanpo1"] = "雕虫小技。",
  ["$m_ex__kanpo2"] = "你的计谋被识破了。",
}

kanpo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#kanpo",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|black",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = kanpo.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response and #player:getHandlyIds() > 0
  end,
})

return kanpo
