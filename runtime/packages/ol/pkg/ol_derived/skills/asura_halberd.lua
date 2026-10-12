local skill = fk.CreateSkill {
  name = "#asura_halberd_skill",
  tags = { Skill.Compulsory },
  attached_equip = "asura_halberd",
}

skill:addEffect("targetmod", {
  extra_target_func = function(self, player, s, card)
    if player:hasSkill(skill.name) and card and card.trueName == "slash" then
      return 10
    end
  end,
})

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and data.by_user
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
    data.extra_data = data.extra_data or {}
    data.extra_data.asura_halberd = (data.extra_data.asura_halberd or 0) + 1
  end,
})

skill:addEffect(fk.Damaged, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and
      data.extra_data and data.extra_data.asura_halberd
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover({
      who = player,
      skillName = skill.name,
      recoverBy = player,
      num = data.extra_data.asura_halberd,
    })
  end,
})

return skill
