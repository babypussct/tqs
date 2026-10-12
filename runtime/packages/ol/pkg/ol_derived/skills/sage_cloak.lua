local skill = fk.CreateSkill {
  name = "#sage_cloak_skill",
  tags = { Skill.Compulsory },
  attached_equip = "sage_cloak",
}

Fk:loadTranslationTable{
  ["#sage_cloak_skill"] = "国风玉袍",
}

skill:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from ~= to and to:hasSkill(skill.name) and card and card:isCommonTrick()
  end,
})

return skill
