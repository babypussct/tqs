local yizhou = fk.CreateSkill {
  name = "peixiu_yizhou",
}

Fk:loadTranslationTable {
  ["peixiu_yizhou"] = "益州",
  [":peixiu_yizhou"] = "你不能成为延时锦囊牌的目标。",
}

yizhou:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if to:hasSkill(yizhou.name) and card and card.sub_type == Card.SubtypeDelayedTrick then
      return true
    end
  end
})

return yizhou
