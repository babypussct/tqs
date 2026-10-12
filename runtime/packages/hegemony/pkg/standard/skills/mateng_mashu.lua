
local mashu = fk.CreateSkill{
  name = "hs_mateng__mashu",
  tags = { Skill.Compulsory },
}
mashu:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(mashu.name) then
      return -1
    end
  end,
})

Fk:loadTranslationTable{
  ["hs_mateng__mashu"] = "马术",
  [":hs_mateng__mashu"] = "锁定技，你与其他角色的距离-1。",
}
return mashu