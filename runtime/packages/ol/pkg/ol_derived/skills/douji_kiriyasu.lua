local skill = fk.CreateSkill {
  name = "#douji_kiriyasu_skill",
  attached_equip = "douji_kiriyasu",
}

skill:addEffect(fk.DetermineDamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.to:isWounded() and not data.to.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#douji_kiriyasu-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:changeMaxHp(data.to, -1)
  end,
})

return skill
