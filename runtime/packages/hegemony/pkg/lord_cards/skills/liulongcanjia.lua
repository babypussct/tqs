
local liulongcanjiaSkill = fk.CreateSkill{
  name = "#liulongcanjia_skill",
  attached_equip = "liulongcanjia",
}
liulongcanjiaSkill:addEffect("distance", {
  correct_func = function(self, from, to)
    local n = 0
    if from:hasSkill(liulongcanjiaSkill.name) then
      n = n -1
    end
    if to:hasSkill(liulongcanjiaSkill.name) then
      n = n + 1
    end
    return n
  end,
})
liulongcanjiaSkill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(liulongcanjiaSkill.name) and table.contains({Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide}, card.sub_type)
  end,
})

Fk:loadTranslationTable{
  ["#liulongcanjia_skill"] = "六龙骖驾",
  ["@@liulongcanjia"] = "六龙骖驾",
}

return liulongcanjiaSkill
