local skill = fk.CreateSkill {
  name = "#muramasa_blade_skill",
  tags = { Skill.Compulsory },
  attached_equip = "muramasa_blade",
}

skill:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.Black then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    local judge = {
      who = target,
      reason = skill.name,
      pattern = ".|.|black",
    }
    room:judge(judge)
    if judge:matchPattern() then
      local targets = data:getExtraTargets()
      if #targets > 0 then
        local new_tos = room:tableRandomPick(targets, #data.tos)
        room:doIndicate(player, new_tos)
        data.tos = new_tos
      end
    end
  end,
})

return skill
