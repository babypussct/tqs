
local skill = fk.CreateSkill{
  name = "#tianlu_skill",
  attached_equip = "tianlu",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) then
      return -3
    end
  end,
})

return skill
