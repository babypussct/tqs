local mashu = fk.CreateSkill{
  name = "os_heg_mayunlu__mashu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_heg_mayunlu__mashu"] = "马术",
  [":os_heg_mayunlu__mashu"] = "锁定技，你与其他角色的距离-1。",
}

mashu:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(mashu.name) then
      return -1
    end
  end,
})

return mashu
