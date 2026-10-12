
local skill = fk.CreateSkill{
  name = "#mobile__liulongcanjia_skill",
  attached_equip = "mobile__liulongcanjia",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) then
      return - 3
    end
  end,
})

return skill
