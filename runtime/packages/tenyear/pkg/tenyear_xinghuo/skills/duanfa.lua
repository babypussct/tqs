local duanfa = fk.CreateSkill {
  name = "duanfa",
}

Fk:loadTranslationTable{
  ["duanfa"] = "断发",
  [":duanfa"] = "出牌阶段，你可以弃置任意张黑色牌，然后摸等量的牌（你每阶段以此法弃置的牌数总和不能大于体力上限）。",

  ["#duanfa"] = "断发：弃置任意张黑色牌，摸等量的牌（还可以弃%arg张）",

  ["$duanfa1"] = "身体发肤，受之父母。",
  ["$duanfa2"] = "今断发以明志，尚不可证吾之心意？",
}

duanfa:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#duanfa:::"..(player.maxHp - player:getMark("duanfa-phase"))
  end,
  can_use = function(self, player)
    return player:getMark("duanfa-phase") < player.maxHp
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function(self, player)
    return player.maxHp - player:getMark("duanfa-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < (player.maxHp - player:getMark("duanfa-phase")) and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, duanfa.name, player, player)
    if player.dead then return end
    room:addPlayerMark(player, "duanfa-phase", #effect.cards)
    player:drawCards(#effect.cards, duanfa.name)
  end
})

-- Haircut is a bounded hand-quality conversion, not a reason to dump every
-- black card.  Evaluate low-keep-value prefixes and retain the best positive
-- exchange under the phase's public remaining-cap mark.
duanfa:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local cards = ai:getEnabledCards()
    local used = type(player.getMark) == "function" and player:getMark("duanfa-phase") or 0
    local limit = math.max(0, (player.maxHp or #cards) - (used or 0))
    if limit == 0 or #cards == 0 then return end

    table.sort(cards, function(a, b)
      local av = ai:getCardValue(a, "keep_value") or 0
      local bv = ai:getCardValue(b, "keep_value") or 0
      return av == bv and a < b or av < bv
    end)

    local best, best_value
    local chosen = {}
    for i = 1, math.min(limit, #cards) do
      table.insert(chosen, cards[i])
      local value = ai:getBenefitOfEvents(function(logic)
        logic:throwCard(chosen, self.skill_name, player, player)
        logic:drawCards(player, #chosen, self.skill_name)
      end)
      if not best_value or value > best_value then
        best, best_value = table.simpleClone(chosen), value
      end
    end
    if best and best_value > 0 then
      return { best }, best_value
    end
  end,
})

return duanfa
