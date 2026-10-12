local jieyong = fk.CreateSkill {
  name = "jieyong",
}

Fk:loadTranslationTable{
  ["jieyong"] = "竭勇",
  [":jieyong"] = "你可以将手牌中最后一张红色牌当【杀】使用或打出。",

  ["#jieyong"] = "竭勇：将手牌中最后一张红色牌当【杀】使用或打出",

  ["$jieyong1"] = "杀！杀！杀！",
  ["$jieyong2"] = "退！退！退！",
}

jieyong:addEffect("viewas", {
  pattern = "slash",
  prompt = "#jieyong",
  filter_pattern = function (self, player, card_name, selected)
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Red
    end)
    if #cards == 1 then
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|hand",
        subcards = cards,
      }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Red
    end)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = jieyong.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Red
    end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Red
    end) == 1
  end,
})

return jieyong
