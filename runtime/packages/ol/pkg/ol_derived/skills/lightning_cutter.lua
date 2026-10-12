local skill = fk.CreateSkill {
  name = "#lightning_cutter_skill",
  tags = { Skill.Compulsory },
  attached_equip = "lightning_cutter",
}

skill:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data:isUsingHandcard(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "lightning_cutter", 1)
    if player:getMark("lightning_cutter") > 2 then
      room:setPlayerMark(player, "lightning_cutter", 0)
      room:setPlayerMark(player, "@@lightning_cutter", 1)
    end
  end,
})

skill:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@lightning_cutter") > 0 and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@lightning_cutter", 0)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return skill
