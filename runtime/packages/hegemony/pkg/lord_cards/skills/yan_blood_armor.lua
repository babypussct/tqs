
local skill = fk.CreateSkill{
  name = "#yan_blood_armor_skill",
  tags = { Skill.Compulsory },
  attached_equip = "yan_blood_armor",
}

skill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    if player:isKongcheng() then
      data:changeDamage(1)
    elseif #player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = skill.name,
        cancelable = false,
        prompt = "#yan_blood_armor-discard",
      }) > 0 then
      data:preventDamage()
    end
  end,
})

return skill
