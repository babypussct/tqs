local zhijian = fk.CreateSkill{
  name = "m_ex__zhijian",
}

Fk:loadTranslationTable{
  ["m_ex__zhijian"] = "直谏",
  [":m_ex__zhijian"] = "出牌阶段，你可以将手牌中的一张装备牌置于其他角色的装备区里，然后摸一张牌。当你于出牌阶段使用装备牌时，你摸一张牌。",

  ["$m_ex__zhijian1"] = "为臣之道，在于直言无讳。",
  ["$m_ex__zhijian2"] = "谏言或逆耳，于国无一害。",
}

zhijian:addEffect("active", {
  anim_type = "support",
  prompt = "#zhijian",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and
      table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select ~= player and
      to_select:canMoveCardIntoEquip(selected_cards[1], false)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardIntoEquip(target, effect.cards[1], zhijian.name, true, player)
    if not player.dead then
      player:drawCards(1, zhijian.name)
    end
  end,
})
zhijian:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhijian.name) and
      data.card.type == Card.TypeEquip and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zhijian.name)
  end,
})

return zhijian
