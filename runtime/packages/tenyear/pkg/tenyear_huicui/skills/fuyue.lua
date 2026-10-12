local fuyue = fk.CreateSkill {
  name = "fuyue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuyue"] = "赋乐",
  [":fuyue"] = "锁定技，你的初始手牌增加“赋”标记且不计入手牌上限。“赋”随机获得另一种非装备牌牌名，使用“赋”时可以选择使用该牌所拥有的任意一种牌名。",

  ["@fuyue-inhand"] = "赋",
  ["#fuyue-viewas"] = "赋乐：按所记录的牌名来使用“赋”",

  ["$fuyue1"] = "曲终人不见，邺下风冷，落梅如坟。",
  ["$fuyue2"] = "人言江南丝竹好，偏我来时不逢春。",
}

fuyue:addEffect("viewas", {
  prompt = "#fuyue-viewas",
  pattern = ".",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|hand",
  },
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local name = Fk:getCardById(to_select, true):getMark("@fuyue-inhand")
    if name == 0 then return false end
    local card = Fk:cloneCard(name, nil, nil, fuyue.name, to_select)
    return card and player:canUseOrResponseInCurrent(card)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    return Fk:cloneCard(Fk:getCardById(cards[1], true):getMark("@fuyue-inhand"), nil, nil, fuyue.name, cards[1])
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
  enabled_at_nullification = function(self, player, data)
    return table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id, true):getMark("@fuyue-inhand") == "nullification"
    end) ~= nil
  end
})

fuyue:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuyue.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = Fk:getAllCardNames("btd", true)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id, true)
      local names2 = table.filter(names, function(n)
        return n ~= card.trueName
      end)
      if #names2 > 0 then
        room:setCardMark(card, "@fuyue-inhand", room:tableRandomPick(names2))
      end
    end
  end,
})

fuyue:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(fuyue.name) and card:getMark("@fuyue-inhand") ~= 0
  end,
})

fuyue:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id, true), "@fuyue-inhand", 0)
  end
end)

return fuyue
