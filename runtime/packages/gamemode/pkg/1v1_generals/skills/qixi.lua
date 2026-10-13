local qixi = fk.CreateSkill {
  name = "v11__qixi",
}

Fk:loadTranslationTable{
  ["v11__qixi"] = "奇袭",
  ["#v11__qixi"] = "你可以将一张黑色牌当【过河拆桥】（1v1版）使用。",

  [":v11__qixi"] = "奇袭：你可以将一张黑色牌当【过河拆桥】（1v1版）使用。",
}

qixi:addEffect("viewas", {
  anim_type = "control",
  pattern = "dismantlement",
  prompt = "#v11__qixi",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("v11__dismantlement")
    c.skillName = qixi.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end
})

return qixi
