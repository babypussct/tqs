local skill = fk.CreateSkill {
  name = "#inferior_horse_skill",
  tags = { Skill.Compulsory },
  attached_equip = "inferior_horse",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) then
      return -1
    end
  end,
  fixed_func = function (self, from, to)
    if to:hasSkill(skill.name) then
      return 1
    end
  end,
})

return skill
