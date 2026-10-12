local huaizi = fk.CreateSkill {
  name = "huaizi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["huaizi"] = "怀子",
  [":huaizi"] = "锁定技，你的手牌上限等于体力上限。",
}

huaizi:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(huaizi.name) then
      return player.maxHp
    end
  end,
})

return huaizi
