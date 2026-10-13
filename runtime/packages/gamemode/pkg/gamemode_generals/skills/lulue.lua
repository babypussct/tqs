local lulue = fk.CreateSkill {
  name = "chaos__lulue",
}

Fk:loadTranslationTable{
  ["chaos__lulue"] = "掳掠",
  [":chaos__lulue"] = "出牌阶段限一次，你可以选择一名装备区里有牌的其他角色并弃置X张牌（X为其装备区里的牌数），对其造成1点伤害。",

  ["#chaos__lulue"] = "掳掠：选择一名角色，弃置其装备区牌数的牌，对其造成1点伤害",
}

lulue:addEffect("active", {
  anim_type = "offensive",
  prompt = "#chaos__lulue",
  min_card_num = 1,
  max_card_num = 10,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lulue.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards > 0 and to_select ~= player and
      #selected_cards == #to_select:getCardIds("e")
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, lulue.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = lulue.name,
      }
    end
  end,
})

return lulue
