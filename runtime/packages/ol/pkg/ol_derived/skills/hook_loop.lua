local skill = fk.CreateSkill {
  name = "#hook_loop_skill",
  tags = { Skill.Compulsory },
  attached_equip = "hook_loop",
}

skill:addEffect(fk.CardEffectCancelledOut, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and data.to == player and not data.from:isKongcheng() and
      data.card.trueName == "slash" and not data.to.dead then
      for _, card in ipairs(data.cardsResponded) do
        if (card:compareSuitWith(data.card) or card.number == data.card.number) and card.name == "jink" then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = {data.from} })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(room:tableRandomPick(data.from:getCardIds("h")), Card.PlayerHand, player, fk.ReasonPrey, skill.name, nil, false, player)
  end,
})

return skill
