local zhenwei = fk.CreateSkill {
  name = "v33__zhenwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["v33__zhenwei"] = "镇卫",
  [":v33__zhenwei"] = "锁定技，对方角色计算与己方角色的距离+1。",
}

zhenwei:addEffect("distance", {
  correct_func = function(self, from, to)
    if table.contains(from:getEnemies(), to) then
      return #table.filter(from:getEnemies(), function (p)
        return p:hasSkill(zhenwei.name)
      end)
    end
  end,
})

return zhenwei
