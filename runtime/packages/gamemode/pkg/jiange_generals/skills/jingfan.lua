local jingfan = fk.CreateSkill {
  name = "jiange__jingfan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__jingfan"] = "惊帆",
  [":jiange__jingfan"] = "锁定技，其他友方角色计算与敌方角色距离-1。",
}

jingfan:addEffect("distance", {
  correct_func = function(self, from, to)
    return -#table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(jingfan.name) and p ~= from and from:isFriend(p) and to:isEnemy(p)
    end)
  end,
})

return jingfan
