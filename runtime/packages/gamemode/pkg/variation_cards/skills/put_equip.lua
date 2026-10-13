local skill = fk.CreateSkill {
  name = "#put_equip",
}

Fk:loadTranslationTable{
  ["#put_equip"] = "置入",
  ["#put_equip:"] = "你可以将此牌置入其他角色的装备区",
}

skill:addEffect("active", {
  mute = true,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and
      table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= player and
      to_select:hasEmptyEquipSlot(Fk:getCardById(cards[1]).sub_type)
  end,
  on_use = function(self, room, effect)
    room:moveCardIntoEquip(effect.tos[1], effect.cards, skill.name, false, effect.from)
  end,
})

return skill
