local liangzhou = fk.CreateSkill {
  name = "peixiu_liangzhou",
}

Fk:loadTranslationTable {
  ["peixiu_liangzhou"] = "梁州",
  [":peixiu_liangzhou"] = "你成为【杀】的目标后，使用者弃置一张牌。",
}

liangzhou:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangzhou.name) and
      data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = liangzhou.name,
      cancelable = false,
    })
  end,
})

return liangzhou
