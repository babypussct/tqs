local jizhi = fk.CreateSkill {
  name = "hs__jizhi",
}

Fk:loadTranslationTable {
  ["hs__jizhi"] = "集智",
  [":hs__jizhi"] = "当你使用非转化的普通锦囊牌时，你可以摸一张牌。",

  ["$hs__jizhi1"] = "哼哼～",
  ["$hs__jizhi2"] = "哼～",
}

jizhi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jizhi.name) and
    data.card:isCommonTrick() and not data.card:isConverted()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jizhi.name)
  end,
})

local AI = Fk.Ltk.AI
jizhi:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return jizhi
