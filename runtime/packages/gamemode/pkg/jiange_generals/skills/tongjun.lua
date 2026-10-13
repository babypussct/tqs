local tongjun = fk.CreateSkill {
  name = "jiange__tongjun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__tongjun"] = "统军",
  [":jiange__tongjun"] = "锁定技，友方攻城器械攻击范围+1。",
}

tongjun:addEffect("atkrange", {
  correct_func = function (self, from)
    return #table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(tongjun.name) and Fk.generals[from.general].jiange_machine and p:isFriend(from)
    end)
  end,
})

return tongjun
