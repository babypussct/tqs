
local skill = fk.CreateSkill{
  name = "#nemesis_slayer_skill",
  tags = { Skill.Compulsory },
  attached_equip = "nemesis_slayer",
}

skill:addEffect(fk.CardUsing, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and data:isOnlyTarget(data.tos[1])
  end,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.nemesis_slayer = { player, data.tos[1] }
  end,
})

skill:addEffect(fk.CardUseFinished, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and not data.damageDealt and
      data.extra_data and data.extra_data.nemesis_slayer and
      not data.extra_data.nemesis_slayer[2].dead
  end,
  on_use = function (self, event, target, player, data)
    local cards = table.filter(player:getEquipCards(Card.SubtypeWeapon), function (card)
      return card.name == skill.attached_equip
    end)
    if #cards > 0 then
      local to = data.extra_data.nemesis_slayer[2]
      player.room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonPrey, skill.name, nil, true, to)
    end
  end,
})

return skill
