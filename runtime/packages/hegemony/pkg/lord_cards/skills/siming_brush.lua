
local skill = fk.CreateSkill{
  name = "#siming_brush_skill",
  tags = { Skill.Compulsory },
  attached_equip = "siming_brush",
}

skill:addEffect(fk.CardUsing, {
  global = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and
      data.card.name == skill.attached_equip and
      not player.dead and
      (player:isWounded() or player:getHandcardNum() < 5)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = skill.name,
      }
    end
    if player:getHandcardNum() < 5 and not player.dead then
      player:drawCards(5 - player:getHandcardNum(), skill.name)
    end
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead or player.hp <= 0 or not Fk.skills[skill.name]:isEffectable(player) then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = info.beforeCard
          if info.fromArea == Card.PlayerEquip and card.name == skill.attached_equip then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, player.hp, skill.name)
  end,
})

return skill
