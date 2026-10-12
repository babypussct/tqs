
local yingzi = fk.CreateSkill{
  name = "heg_sunce__yingzi",
  tags = { Skill.Compulsory },
}

yingzi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

yingzi:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(yingzi.name) then
      return player.maxHp
    end
  end
})

Fk:loadTranslationTable{
  ["heg_sunce__yingzi"] = "英姿",
  [":heg_sunce__yingzi"] = "锁定技，摸牌阶段，你多摸一张牌；你的手牌上限等于你的体力上限。",

  ["$heg_sunce__yingzi1"] = "公瑾，助我决一死战。",
  ["$heg_sunce__yingzi2"] = "尔等看好了！",
}

return yingzi
