local yuanbu = fk.CreateSkill {
  name = "yuanbu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuanbu"] = "远步",
  [":yuanbu"] = "锁定技，你的手牌上限+X；你与其他角色的距离+X；其他角色与你的距离+X（X为存活的其他角色数，且至多为4）。",
}

yuanbu:addEffect("maxcards", {
  correct_func = function(self, player)
    return
      player:hasSkill(yuanbu.name) and
      math.min(4, #table.filter(Fk:currentRoom().alive_players, function(p)
        return p ~= player
      end)) or
      0
  end,
})

yuanbu:addEffect("distance", {
  correct_func = function(self, player, to)
    return
      (
        player:hasSkill(yuanbu.name) or
        to:hasSkill(yuanbu.name)
      ) and
      math.min(4, #table.filter(Fk:currentRoom().alive_players, function(p)
        return p ~= player
      end)) or
      0
  end,
})

return yuanbu
