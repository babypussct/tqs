local renshi = fk.CreateSkill {
  name = "renshih",
}

Fk:loadTranslationTable{
  ["renshih"] = "仁仕",
  [":renshih"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名其他角色。",

  ["#renshih"] = "仁仕：你可以将一张手牌交给一名其他角色",

  ["$renshih1"] = "吾既从大魏之仕，必当行君子之仁。",
  ["$renshih2"] = "君子之仕，无外乎行其仁也。",
}

renshi:addEffect("active", {
  anim_type = "support",
  prompt = "#renshih",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not table.contains(player:getTableMark("renshih-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "renshih-phase", target.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, renshi.name, nil, false, player)
  end,
})

return renshi
