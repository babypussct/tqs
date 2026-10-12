local yicong = fk.CreateSkill{
  name = "m_ex__yicong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__yicong"] = "义从",
  [":m_ex__yicong"] = "锁定技，你至其他角色的距离-X（X为你的体力值-1）；其他角色至你的距离+Y（Y为你已损失的体力值-1）。",
}

yicong:addEffect("distance", {
  correct_func = function(self, from, to)
    local x = 0
    if to:hasSkill(yicong.name) then
      x = math.max(0, to:getLostHp() - 1)
    end
    if from:hasSkill(yicong.name) then
      x = x - math.max(0, from.hp - 1)
    end
    return x
  end,
})

return yicong
