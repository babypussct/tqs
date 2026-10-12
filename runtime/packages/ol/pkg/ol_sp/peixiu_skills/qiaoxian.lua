local qiaoxian = fk.CreateSkill {
  name = "peixiu_qiaoxian",
}

Fk:loadTranslationTable {
  ["peixiu_qiaoxian"] = "谯县",
  [":peixiu_qiaoxian"] = "你受到伤害后，可以摸一张牌。",
}

qiaoxian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qiaoxian.name)
  end,
})

return qiaoxian
