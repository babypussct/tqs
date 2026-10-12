local chenliu = fk.CreateSkill {
  name = "peixiu_chenliu",
}

Fk:loadTranslationTable {
  ["peixiu_chenliu"] = "陈留",
  [":peixiu_chenliu"] = "你跳过弃牌阶段。",
}

chenliu:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenliu.name) and
      data.phase == Player.Discard and not data.skipped
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

return chenliu
