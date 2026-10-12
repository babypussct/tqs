local yinping = fk.CreateSkill {
  name = "peixiu_yinping",
}

Fk:loadTranslationTable {
  ["peixiu_yinping"] = "阴平",
  [":peixiu_yinping"] = "其他角色计算与你的距离+1。",
}

yinping:addEffect("distance", {
  correct_func = function(self, from, to)
    if to:hasSkill(yinping.name) and from ~= to then
      return 1
    end
    return 0
  end,
})

return yinping
