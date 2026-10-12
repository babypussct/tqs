local madai_mashu = fk.CreateSkill{
  name = "heg_madai__mashu",
  tags = { Skill.Compulsory },
}
madai_mashu:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(madai_mashu.name) then
      return -1
    end
  end,
})

Fk:loadTranslationTable{
  ["heg_madai__mashu"] = "马术",
  [":heg_madai__mashu"] = "锁定技，你与其他角色的距离-1。",
}

return madai_mashu
