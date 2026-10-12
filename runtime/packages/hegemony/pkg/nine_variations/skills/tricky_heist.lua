
local skill = fk.CreateSkill {
  name = "tricky_heist_skill",
}

skill:addEffect("cardskill", {
  prompt = "#tricky_heist_skill",
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target:isKongcheng() then return end
    local cards = target:getCardIds("h")
    target:showCards(cards)
    if not player.dead then
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).type == Card.TypeEquip and table.contains(target:getCardIds("h"), id)
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, skill.name, nil, true, player)
      end
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.5,
  use_value = 5.5,
  use_priority = 8.0,

  on_effect = function(self, logic, effect)
    local cards = table.filter(effect.to:getCardIds("h"), function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    logic:moveCardTo(cards, Card.PlayerHand, effect.from, fk.ReasonPrey, skill.name, nil, true, effect.from)
  end,
})

return skill
