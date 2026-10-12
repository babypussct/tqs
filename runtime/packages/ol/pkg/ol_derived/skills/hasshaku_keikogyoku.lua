local skill = fk.CreateSkill{
  name = "#hasshaku_keikogyoku_skill",
  tags = { Skill.Compulsory },
  attached_equip = "hasshaku_keikogyoku",
}

skill:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = skill.name,
    }
  end,
})

skill:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and not player:isWounded()
  end,
  on_use = function (self, event, target, player, data)
    data.n = data.n + 2
  end,
})

return skill
