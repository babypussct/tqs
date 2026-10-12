
local huanshim = fk.CreateSkill({
  name = "huanshim",
})

Fk:loadTranslationTable{
  ["huanshim"] = "幻视",
  [":huanshim"] = "出牌阶段每个花色限一次，你可以将一张牌当手牌中同花色的另一张基本牌或普通锦囊牌使用。",

  ["#huanshim"] = "幻视：将一张牌当手牌中同花色的另一张基本牌或普通锦囊牌使用",

  ["$huanshim1"] = "采蘑菇的小姑娘，背着一个大箩筐~♪",
  ["$huanshim2"] = "老话说得好，先菌……先君子后小人！",
}

huanshim:addEffect("viewas", {
  card_num = 1,
  prompt = "#huanshim",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("huanshim-phase"), Fk:getCardById(to_select).suit) and
      table.find(player:getCardIds("h"), function (id)
        local card = Fk:getCardById(id)
        return id ~= to_select and Fk:getCardById(to_select):compareSuitWith(card) and (card.type == Card.TypeBasic or card:isCommonTrick())
      end)
  end,
  interaction = function(self, player)
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.suit ~= Card.NoSuit and not table.contains(player:getTableMark("huanshim-phase"), Fk:getCardById(id).suit) and
        (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.CardNameBox { choices = names }
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil or #cards ~= 1 or
      not table.find(player:getCardIds("h"), function (id)
        local card = Fk:getCardById(id)
        return card.name == self.interaction.data and id ~= cards[1] and Fk:getCardById(cards[1]):compareSuitWith(card)
      end) then
      return
    end
    return Fk:cloneCard(self.interaction.data, nil, nil, huanshim.name, cards)
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, "huanshim-phase", use.card.suit)
  end,
})

return huanshim
