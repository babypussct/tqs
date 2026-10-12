local huaibi = fk.CreateSkill {
  name = "huaibi",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huaibi"] = "怀璧",
  [":huaibi"] = "主公技，锁定技，你的手牌上限+X（X为你〖邀虎〗选择势力的角色数）。",

  ["$huaibi1"] = "哎！匹夫无罪，怀璧其罪啊。",
  ["$huaibi2"] = "粮草尽皆在此，宗兄可自取之。",
}

huaibi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(huaibi.name) and player:getMark("@yaohu") ~= 0 then
      return #table.filter(Fk:currentRoom().alive_players, function(p)
        return p.kingdom == player:getMark("@yaohu")
      end)
    end
  end,
})

return huaibi
