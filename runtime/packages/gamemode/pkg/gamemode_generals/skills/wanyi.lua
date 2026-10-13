local wanyi = fk.CreateSkill {
  name = "nos__wanyi",
}

Fk:loadTranslationTable{
  ["nos__wanyi"] = "婉嫕",
  [":nos__wanyi"] = "出牌阶段每种牌名限一次，你可以将一张带有应变效果的牌当【逐近弃远】、【出其不意】、【水淹七军】或【洞烛先机】使用。",

  ["#nos__wanyi"] = "婉嫕：你可以将一张带有应变效果的牌当一种应变篇锦囊使用",

  ["$nos__wanyi1"] = "婉嫕而淑慎，位居正室。",
  ["$nos__wanyi2"] = "为后需备贞静之德、婉嫕之操。",
}

wanyi:addEffect("viewas", {
  prompt = "#nos__wanyi",
  interaction = function(self, player)
    local all_names = {"chasing_near", "unexpectation", "drowning", "foresight"}
    local names = player:getViewAsCardNames(wanyi.name, all_names, nil, player:getTableMark("nos__wanyi-turn"))
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and
      table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark)
        return Fk:getCardById(to_select):getMark(mark) ~= 0
      end)
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, "nos__wanyi-turn", use.card.name)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = wanyi.name
    return card
  end,
})

return wanyi
