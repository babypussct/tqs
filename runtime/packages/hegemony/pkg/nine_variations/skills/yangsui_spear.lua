
local skill = fk.CreateSkill{
  name = "#yangsui_spear_skill",
  tags = { Skill.Compulsory },
  attached_equip = "yangsui_spear",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.room.logic:damageByCardEffect() and
      data.card and data.card.trueName == "slash" and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      to = data.to,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = skill.name,
    }
  end,
})

return skill
