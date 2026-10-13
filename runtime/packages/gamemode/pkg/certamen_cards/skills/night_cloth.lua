local skill = fk.CreateSkill {
  name = "#night_cloth_skill",
  tags = { Skill.Compulsory },
  attached_equip = "night_cloth",
}

Fk:loadTranslationTable{
  ["#night_cloth_skill"] = "夜行衣",
}

skill:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return to and to:hasSkill(skill.name) and card and card.type == Card.TypeTrick and card.color == Card.Black
  end,
})

return skill
