local yilie = fk.CreateSkill{
  name = "yilie",
}

Fk:loadTranslationTable{
  ["yilie"] = "义烈",
  [":yilie"] = "你可以将两张颜色相同的手牌当一张本轮未以此法使用过的基本牌使用。",

  ["#yilie"] = "义烈：将两张颜色相同的手牌当一张基本牌使用",

  ["$yilie1"] = "从来天下义，只在青山中！",
  ["$yilie2"] = "沥血染征袍，英名万古存！",
}

yilie:addEffect("viewas", {
  prompt = "#yilie",
  pattern = ".|0|red,black|.|.|basic",
  handly_pile = true,
  filter_pattern = function(self, player, card_name, selected)
    local vs_pattern = {
      max_num = 2,
      min_num = 2,
      pattern = ".|.|^nocolor|^equip",
    }
    if selected and #selected > 0 then
      vs_pattern.pattern = ".|.|".. Fk:getCardById(selected[1]):getColorString() .."|^equip"
    end
    return vs_pattern
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(yilie.name, all_names, selected_cards, player:getTableMark("yilie-round"))
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, yilie.name, cards)
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "yilie-round", use.card.trueName)
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #player:getViewAsCardNames(yilie.name, Fk:getAllCardNames("b"), {}, player:getTableMark("yilie-round")) > 0
  end,
})

return yilie
