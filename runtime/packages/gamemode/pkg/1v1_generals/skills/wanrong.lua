local wanrong = fk.CreateSkill {
  name = "v11__wanrong",
}

Fk:loadTranslationTable{
  ["v11__wanrong"] = "婉容",
  [":v11__wanrong"] = "当你成为【杀】的目标后，你可以摸一张牌。",

  ["$v11__wanrong1"] = "呵哼哼~",
  ["$v11__wanrong2"] = "看这里，看这里哦~",
}

wanrong:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanrong.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, wanrong.name)
  end,
})

return wanrong
