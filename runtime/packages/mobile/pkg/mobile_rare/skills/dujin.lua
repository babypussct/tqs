local dujin = fk.CreateSkill {
  name = "dujin",
}

Fk:loadTranslationTable{
  ["dujin"] = "独进",
  [":dujin"] = "摸牌阶段，你可以多摸X+1张牌（X为你装备区里的牌数的一半，向下取整）。",

  ["$dujin1"] = "带兵十万，不如老夫多甲一件！",
  ["$dujin2"] = "轻舟独进，破敌先锋！",
}

dujin:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1 + #player:getCardIds("e") // 2
  end,
})

dujin:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return dujin
