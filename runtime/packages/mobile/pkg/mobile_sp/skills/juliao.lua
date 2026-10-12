local juliao = fk.CreateSkill {
  name = "juliao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juliao"] = "据辽",
  [":juliao"] = "锁定技，其他角色计算与你的距离+X（X为场上势力数-1）。"
}

juliao:addEffect("distance", {
  correct_func = function(self, from, to)
    if to:hasSkill(juliao.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    end
    return 0
  end,
})

return juliao
