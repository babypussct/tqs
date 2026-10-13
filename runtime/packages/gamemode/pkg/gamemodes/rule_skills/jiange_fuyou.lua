local fuyou = fk.CreateSkill {
  name = "jiange__fuyou",
}

Fk:loadTranslationTable{
  ["jiange__fuyou"] = "福佑",
  [":jiange__fuyou"] = "每回合限一次，当你使用红色普通锦囊牌造成伤害后，你摸一张牌；你使用红色普通锦囊牌额外结算一次。",
}

fuyou:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyou.name) and
      data.card:isCommonTrick() and data.card.color == Card.Red and
      #data.tos > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

fuyou:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyou.name) and
      data.card and data.card:isCommonTrick() and data.card.color == Card.Red and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, fuyou.name)
  end,
})

return fuyou
