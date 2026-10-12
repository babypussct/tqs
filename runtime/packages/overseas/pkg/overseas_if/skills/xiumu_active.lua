local xiumu_active = fk.CreateSkill {
  name = "os__xiumu_active",
}

Fk:loadTranslationTable{
  ["os__xiumu_active"] = "修睦",
}

xiumu_active:addEffect("active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  feasible = function(self, player, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num >= 13
  end,
})

return xiumu_active
