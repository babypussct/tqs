local biluan = fk.CreateSkill {
  name = "ld__biluan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__biluan"] = "避乱",
  [":ld__biluan"] = "锁定技，其他角色计算与你的距离+X（X为你装备区内的牌数）。",
}

biluan:addEffect("distance", {
  correct_func = function(self, from, to)
    if to:hasSkill(biluan.name) and to:hasShownSkill(biluan.name) then
      return math.max(#to.player_cards[Player.Equip], 0)
    end
  end,
})

return biluan
