local skill = fk.CreateSkill {
  name = "#m_liuyi__liulongcanjia_skill",
  attached_equip = "m_liuyi__liulongcanjia",
}

skill:addEffect("distance", {
  correct_func = function(self, from, to)
    local fromHasSkill = from:hasSkill(skill.name)
    local toHasSkill = to:hasSkill(skill.name)
    local distance = 0
    if fromHasSkill or toHasSkill then
      local kNum = 0
      table.forEach(Fk:currentRoom().alive_players, function(p)
        kNum = kNum + #table.filter(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id).number == 13
        end)
      end)

      if fromHasSkill then
        distance = distance - kNum
      end
      if toHasSkill then
        distance = distance + kNum
      end

      return distance
    end
  end,
})

return skill
