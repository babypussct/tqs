local skill = fk.CreateSkill {
  name = "#ex_silver_lion_skill",
  tags = { Skill.Compulsory },
  attached_equip = "ex_silver_lion",
}

Fk:loadTranslationTable{
  ["#ex_silver_lion_skill"] = "照月狮子盔",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damage > 1
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1 - data.damage)
  end,
})
skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
    if not player.dead then
      player:drawCards(2, skill.name)
    end
  end,
})

return skill
