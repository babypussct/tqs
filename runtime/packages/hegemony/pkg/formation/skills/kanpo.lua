local kanpo = fk.CreateSkill {
  name = "ld__kanpo",
}

Fk:loadTranslationTable{
  ["ld__kanpo"] = "看破",
  [":ld__kanpo"] = "你可以将一张黑色手牌当【无懈可击】使用。",

  ["$ld__kanpo1"] = "丞相已教我识得此计。",
  ["$ld__kanpo2"] = "哼！有破绽！",
}

kanpo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#kanpo",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and table.contains(player:getHandlyIds(), to_select)
  end,
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
