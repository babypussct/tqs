local skill = fk.CreateSkill {
  name = "#bee_cloth_skill",
  tags = { Skill.Compulsory },
  attached_equip = "bee_cloth",
}

Fk:loadTranslationTable {
  ["#bee_cloth_skill"] = "引蜂衣",
}

skill:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
        data.card and data.card.type == Card.TypeTrick
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

skill:addEffect(fk.PreHpLost, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
        (data.skillName == "es__poison" or data.skillName == "poison")
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

return skill
