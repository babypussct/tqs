local skill = fk.CreateSkill {
  name = "#bee_armor_skill",
  tags = { Skill.Compulsory },
  attached_equip = "bee_armor",
}

Fk:loadTranslationTable{
  ["#bee_armor_skill"] = "引蜂甲",
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

return skill
