local skill = fk.CreateSkill {
  name = "carrier_pigeon_skill&",
  attached_equip = "carrier_pigeon",
}

Fk:loadTranslationTable{
  ["carrier_pigeon_skill&"] = "信鸽",
  [":carrier_pigeon_skill&"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色",

  ["#carrier_pigeon_skill"] = "信鸽：你可以将一张手牌交给一名其他角色",
}

skill:addEffect("active", {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#carrier_pigeon_skill",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, skill.name, nil, false, player)
  end,
})

return skill
