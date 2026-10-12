local xiefang = fk.CreateSkill{
  name = "xiefang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
}

xiefang:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(xiefang.name) then
      return -#table.filter(Fk:currentRoom().alive_players, function (p)
        return p:isFemale()
      end)
    end
  end,
})

return xiefang
