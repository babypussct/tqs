
local mingshi = fk.CreateSkill{
  name = "mingshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mingshi"] = "名士",
  [":mingshi"] = "锁定技，当你受到伤害时，若来源有暗置的武将牌，你令伤害值-1。",

  ["$mingshi1"] = "孔门之后，忠孝为先。",
  ["$mingshi2"] = "名士之风，仁义高洁。",
}

mingshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingshi.name) and data.from and
      (data.from.general == "anjiang" or data.from.deputyGeneral == "anjiang")
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

return mingshi
