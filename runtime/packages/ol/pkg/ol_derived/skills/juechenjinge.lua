local skill = fk.CreateSkill {
  name = "#juechenjinge_skill",
  tags = { Skill.Compulsory },
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    if table.contains(to:getEnemies(), from) then
      return #table.filter(to:getFriends(), function (p)
        return p:hasSkill(skill.name) and p ~= to
      end)
    end
  end,
})

return skill
