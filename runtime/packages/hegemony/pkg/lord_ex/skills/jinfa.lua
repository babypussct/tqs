local jinfa = fk.CreateSkill {
  name = "ld__jinfa",
}

Fk:loadTranslationTable {
  ["ld__jinfa"] = "矜伐",
  [":ld__jinfa"] = "出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，令其选择一项："..
  "1.令你获得其一张牌；2.交给你一张装备牌，若此装备牌为♠，其视为对你使用一张【杀】。",

  ["#ld__jinfa"] = "矜伐：弃置一张牌，令一名其他角色选择你获得其一张牌或其交给你一张牌",
  ["#ld__jinfa_give"] = "矜伐：交给 %src 一张装备牌，否则其获得你的一张牌",

  ["$ld__jinfa1"] = "居功者，当自矜，为将者，当善伐。",
  ["$ld__jinfa2"] = "此战伐敌所获，皆我之功。",
}

jinfa:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ld__jinfa",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jinfa.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not to_select:isNude() and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, jinfa.name, player, player)
    if player.dead or target:isNude() then return end
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jinfa.name,
      prompt = "#ld__jinfa_give:" .. player.id,
      pattern = ".|.|.|.|.|equip",
      cancelable = true,
    })
    if #card == 1 then
      local yes = Fk:getCardById(card[1]).suit == Card.Spade
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, jinfa.name, nil, true, target)
      if yes and not player.dead then
        room:useVirtualCard("slash", nil, target, player, jinfa.name, true)
      end
    else
      if target:isNude() then return end
      card = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = jinfa.name,
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, jinfa.name)
    end
  end,
})

return jinfa
