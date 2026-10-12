local skill = fk.CreateSkill {
  name = "luoyang_shovel_skill&",
  attached_equip = "luoyang_shovel",
}

Fk:loadTranslationTable {
  ["luoyang_shovel_skill&"] = "洛阳铲",
  [":luoyang_shovel_skill&"] = "出牌阶段限一次，你可以弃置一张黑色牌，将所有手牌置入弃牌堆，摸等量的牌。",
  ["#luoyang_shovel_skill&"] = "弃置一张黑色牌，重新刷一次手牌",
}

skill:addEffect("active", {
  anim_type = "control",
  prompt = "#luoyang_shovel_skill&",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and
      not player:prohibitDiscard(to_select) and Fk:getCardById(to_select).name ~= skill.attached_equip
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, skill.name, player, player)
    if player.dead or player:isKongcheng() then return end
    local cards = player:getCardIds("h")
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true, player)
    if not player.dead then
      player:drawCards(#cards, skill.name)
    end
  end,
})

return skill
