local kanpo = fk.CreateSkill{
  name = "ol_ex__kanpo",
}

Fk:loadTranslationTable {
  ["ol_ex__kanpo"] = "看破",
  [":ol_ex__kanpo"] = "你可以将一张黑色牌当【无懈可击】使用。你使用的【无懈可击】不能被响应。",

  ["#ol_ex__kanpo"] = "看破：你可以将一张黑色牌当【无懈可击】使用",

  ["$ol_ex__kanpo1"] = "此计奥妙，我已看破。",
  ["$ol_ex__kanpo2"] = "还有什么是我看不破的？",
}

kanpo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#ol_ex__kanpo",
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
  enabled_at_response = function(self, player, response)
    return not response
  end,
  enabled_at_nullification = function (self, player, data)
    return #player:getCardIds("he") > 0 or #player:getHandlyIds(false) > 0
  end
})

kanpo:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(kanpo.name) and data.card.trueName == "nullification"
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return kanpo
