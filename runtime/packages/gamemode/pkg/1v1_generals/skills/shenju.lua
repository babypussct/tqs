local shenju = fk.CreateSkill {
  name = "v11__shenju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["v11__shenju"] = "慎拒",
  [":v11__shenju"] = "锁定技，你的手牌上限+X（X为对手的体力值）。",
}

shenju:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(shenju.name) then
      return player.next.hp
    end
  end,
})

return shenju
