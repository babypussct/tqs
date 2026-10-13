local zhenwei = fk.CreateSkill {
  name = "jiange__zhenwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__zhenwei"] = "镇卫",
  [":jiange__zhenwei"] = "锁定技，敌方角色计算与其他友方角色距离+1。",
}

zhenwei:addEffect("distance", {
  correct_func = function(self, from, to)
    return #table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(zhenwei.name) and from:isEnemy(p) and to:isFriend(p) and p ~= to
    end)
  end,
})

return zhenwei
