local skill = fk.CreateSkill {
  name = "#seven_stars_sword_skill",
  tags = { Skill.Compulsory },
  attached_equip = "seven_stars_sword",
}

Fk:loadTranslationTable{
  ["#seven_stars_sword_skill"] = "七宝刀",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card and data.card.trueName == "slash" and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
    if not data.to:isWounded() then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return skill
